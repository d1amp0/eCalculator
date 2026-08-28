import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/models/homework_item.dart';
import 'package:ecalculator/other/app_theme_colors.dart';
import 'package:ecalculator/other/database_helper.dart';
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
    this.onItemTap,
    this.now,
  });

  final HomeworkItemsLoader? itemsLoader;
  final ValueChanged<HomeworkItem>? onItemTap;
  final DateTime Function()? now;

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  var _items = <HomeworkItem>[];
  var _isLoading = true;
  Object? _loadError;

  Future<List<HomeworkItem>> _loadProductionItems() async {
    final items = <HomeworkItem>[];
    if (!appSession.isDemo) {
      final tasks = await DatabaseHelper.instance.getTasks();
      final oldestAllowed = DateTime.now().millisecondsSinceEpoch -
          const Duration(days: 7).inMilliseconds;
      for (final task in tasks) {
        if (task.time < oldestAllowed) {
          await DatabaseHelper.instance.remove(task.info);
        } else {
          items.add(
            HomeworkItem(
              subject: task.subject,
              content: task.info,
              preview: task.info,
              date: DateTime.fromMillisecondsSinceEpoch(task.time),
              isLocal: true,
            ),
          );
        }
      }
    }

    final rawItems = await homeworkServer();
    items.addAll(
      rawItems.map((raw) => HomeworkItem.fromRaw(raw as List<dynamic>)),
    );
    return items;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final loadedItems = await (widget.itemsLoader ?? _loadProductionItems)();
      if (!mounted) return;
      final items = [...loadedItems];
      items.sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  void _addItem(List<dynamic> values) {
    final item = HomeworkItem(
      date: DateTime.fromMillisecondsSinceEpoch(values[0] as int),
      subject: values[1].toString(),
      content: values[2].toString(),
      preview: values[2].toString(),
      isLocal: true,
    );
    setState(() {
      _items = [..._items, item]..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  void _removeItem(HomeworkItem item) {
    setState(
      () => _items = _items.where((value) => !identical(value, item)).toList(),
    );
  }

  void _openItem(HomeworkItem item) {
    if (widget.onItemTap case final onItemTap?) {
      onItemTap(item);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TaskPage(item: item, onDeleted: _removeItem),
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
              saveTask: appSession.isDemo ? (_) async {} : null,
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
    if (_loadError != null) {
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
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Нет заданий',
          key: const ValueKey('homework-empty'),
          style: TextStyle(color: AppThemeColors.scaffoldText(context)),
        ),
      );
    }

    final groups = <DateTime, List<HomeworkItem>>{};
    for (final item in _items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      groups.putIfAbsent(date, () => []).add(item);
    }
    final rows = <Widget>[];
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
