import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/models/homework_item.dart';
import 'package:ecalculator/other/app_theme_colors.dart';
import 'package:ecalculator/other/database_helper.dart';
import 'package:ecalculator/other/task.dart';
import 'package:ecalculator/pages/add_task_page.dart';
import 'package:ecalculator/pages/task_page.dart';
import 'package:ecalculator/server/functions.dart';
import 'package:ecalculator/services/app_session.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef HomeworkItemsLoader = Future<List<HomeworkItem>> Function();

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({
    super.key,
    this.itemsLoader,
    this.localItemsLoader,
    this.remoteItemsLoader,
    this.databaseHelper,
    this.deleteTask,
    this.onItemTap,
    this.now,
  });

  final HomeworkItemsLoader? itemsLoader;
  final HomeworkItemsLoader? localItemsLoader;
  final HomeworkItemsLoader? remoteItemsLoader;
  final DatabaseHelper? databaseHelper;
  final TaskDelete? deleteTask;
  final ValueChanged<HomeworkItem>? onItemTap;
  final DateTime Function()? now;

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  var _localItems = <HomeworkItem>[];
  var _remoteItems = <HomeworkItem>[];
  var _items = <HomeworkItem>[];
  var _isLoading = true;
  var _isRetryingLocal = false;
  var _isRetryingRemote = false;
  Object? _localError;
  Object? _remoteError;

  DatabaseHelper get _databaseHelper =>
      widget.databaseHelper ?? DatabaseHelper.instance;

  Future<List<HomeworkItem>> _loadProductionLocalItems() async {
    final items = <HomeworkItem>[];
    if (appSession.isDemo) return items;

    final tasks = await _databaseHelper.getTasks();
    final oldestAllowed = DateTime.now().millisecondsSinceEpoch -
        const Duration(days: 7).inMilliseconds;
    for (final task in tasks) {
      final id = task.id;
      if (id == null) {
        throw StateError('Persisted local homework has no database id');
      }
      if (task.time < oldestAllowed) {
        await _databaseHelper.removeById(id);
      } else {
        items.add(HomeworkItem.fromTask(task));
      }
    }
    return items;
  }

  Future<List<HomeworkItem>> _loadProductionRemoteItems() async {
    final rawItems = await homeworkServer();
    return rawItems
        .map((raw) => HomeworkItem.fromRaw(raw as List<dynamic>))
        .toList();
  }

  HomeworkItemsLoader get _localLoader {
    if (widget.localItemsLoader case final loader?) return loader;
    if (widget.itemsLoader != null) return () async => <HomeworkItem>[];
    return _loadProductionLocalItems;
  }

  HomeworkItemsLoader get _remoteLoader =>
      widget.remoteItemsLoader ??
      widget.itemsLoader ??
      _loadProductionRemoteItems;

  Future<_HomeworkLoadResult> _attempt(HomeworkItemsLoader loader) async {
    try {
      return _HomeworkLoadResult.success(await loader());
    } on Object catch (error) {
      return _HomeworkLoadResult.failure(error);
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _localError = null;
      _remoteError = null;
    });

    final results = await Future.wait([
      _attempt(_localLoader),
      _attempt(_remoteLoader),
    ]);
    if (!mounted) return;
    setState(() {
      _localItems = results[0].items ?? <HomeworkItem>[];
      _remoteItems = results[1].items ?? <HomeworkItem>[];
      _localError = results[0].error;
      _remoteError = results[1].error;
      _rebuildItems();
      _isLoading = false;
    });
  }

  Future<void> _retryRemote() async {
    if (_isRetryingRemote) return;
    setState(() => _isRetryingRemote = true);
    final result = await _attempt(_remoteLoader);
    if (!mounted) return;
    setState(() {
      if (result.items case final items?) _remoteItems = items;
      _remoteError = result.error;
      _rebuildItems();
      _isRetryingRemote = false;
    });
  }

  Future<void> _retryLocal() async {
    if (_isRetryingLocal) return;
    setState(() => _isRetryingLocal = true);
    final result = await _attempt(_localLoader);
    if (!mounted) return;
    setState(() {
      if (result.items case final items?) _localItems = items;
      _localError = result.error;
      _rebuildItems();
      _isRetryingLocal = false;
    });
  }

  void _rebuildItems() {
    final indexed = [..._localItems, ..._remoteItems].asMap().entries.toList();
    indexed.sort((a, b) {
      final byDate = a.value.date.compareTo(b.value.date);
      return byDate != 0 ? byDate : a.key.compareTo(b.key);
    });
    _items = indexed.map((entry) => entry.value).toList();
  }

  void _addItem(Task task) {
    final item = HomeworkItem.fromTask(task);
    setState(() {
      _localItems = [..._localItems, item];
      _rebuildItems();
    });
  }

  void _removeItem(HomeworkItem item) {
    setState(() {
      _localItems =
          _localItems.where((value) => !identical(value, item)).toList();
      _remoteItems =
          _remoteItems.where((value) => !identical(value, item)).toList();
      _rebuildItems();
    });
  }

  void _openItem(HomeworkItem item) {
    if (widget.onItemTap case final onItemTap?) {
      onItemTap(item);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TaskPage(
          item: item,
          onDeleted: _removeItem,
          databaseHelper: _databaseHelper,
          deleteTask: widget.deleteTask,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задания'),
        actions: const [MoreMenu(canLeave: true)],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('add-task-fab'),
        tooltip: 'Добавить задание',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => AddTaskPage(
              function: _addItem,
              saveTask:
                  appSession.isDemo ? (_) async => null : _databaseHelper.add,
            ),
          ),
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          key: const ValueKey('homework-loading'),
          color: AppThemeColors.scaffoldText(context),
        ),
      );
    }
    if (_remoteError != null && _localItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Не удалось загрузить задания',
              style: TextStyle(color: AppThemeColors.scaffoldText(context)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(
                foregroundColor: AppThemeColors.scaffoldText(context),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    final warnings = _buildDegradedWarnings();
    if (_items.isEmpty) {
      return Column(
        children: [
          ...warnings,
          Expanded(
            child: Center(
              child: Text(
                'Нет заданий',
                key: const ValueKey('homework-empty'),
                style: TextStyle(color: AppThemeColors.scaffoldText(context)),
              ),
            ),
          ),
        ],
      );
    }

    final groups = <DateTime, List<HomeworkItem>>{};
    for (final item in _items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      groups.putIfAbsent(date, () => []).add(item);
    }
    final rows = <Widget>[...warnings];
    var itemIndex = 0;
    for (final entry in groups.entries) {
      rows.add(_DateHeader(date: entry.key, now: widget.now?.call()));
      for (final item in entry.value) {
        rows.add(
          _TaskTile(
            key: ValueKey('homework-task-${itemIndex++}'),
            item: item,
            onTap: () => _openItem(item),
          ),
        );
      }
    }

    return ListView(
      key: const ValueKey('homework-list'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      children: rows,
    );
  }

  List<Widget> _buildDegradedWarnings() {
    return [
      if (_remoteError != null && _localItems.isNotEmpty)
        _DegradedWarning(
          key: const ValueKey('remote-homework-warning'),
          message: 'Задания eSchool временно недоступны',
          retryKey: const ValueKey('remote-homework-retry'),
          isRetrying: _isRetryingRemote,
          onRetry: _retryRemote,
        ),
      if (_localError != null && _remoteError == null)
        _DegradedWarning(
          key: const ValueKey('local-homework-warning'),
          message: 'Локальные задания временно недоступны',
          retryKey: const ValueKey('local-homework-retry'),
          isRetrying: _isRetryingLocal,
          onRetry: _retryLocal,
        ),
    ];
  }
}

class _DegradedWarning extends StatelessWidget {
  const _DegradedWarning({
    super.key,
    required this.message,
    required this.retryKey,
    required this.isRetrying,
    required this.onRetry,
  });

  final String message;
  final Key retryKey;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 2),
      color: scheme.surfaceContainerLow,
      child: ListTile(
        dense: true,
        leading: Icon(Icons.cloud_off_outlined, color: scheme.onSurfaceVariant),
        title: Text(message),
        trailing: TextButton(
          key: retryKey,
          onPressed: isRetrying ? null : onRetry,
          child: isRetrying
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Повторить'),
        ),
      ),
    );
  }
}

class _HomeworkLoadResult {
  const _HomeworkLoadResult.success(this.items) : error = null;

  const _HomeworkLoadResult.failure(this.error) : items = null;

  final List<HomeworkItem>? items;
  final Object? error;
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, DateTime? now}) : _now = now;

  final DateTime date;
  final DateTime? _now;

  String _label() {
    final now = _now ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'Сегодня';
    if (date == today.add(const Duration(days: 1))) return 'Завтра';
    return DateFormat(
      date.year == today.year ? 'd MMMM' : 'd MMMM y',
      'ru',
    ).format(date);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
        child: Text(
          _label(),
          key: ValueKey('homework-date-${date.millisecondsSinceEpoch}'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppThemeColors.scaffoldText(
                  context,
                ).withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({super.key, required this.item, required this.onTap});

  final HomeworkItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final source = item.isLocal ? 'Добавлено вручную' : 'eSchool';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: '${item.subject}. $source',
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: Tooltip(
              message: source,
              child: Icon(
                item.isLocal ? Icons.edit_note_outlined : Icons.school_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
            title: Text(
              item.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: item.preview.trim().isEmpty
                ? null
                : Text(
                    item.preview.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      ),
    );
  }
}
