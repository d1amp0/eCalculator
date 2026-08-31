import 'dart:convert';

import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/models/homework_item.dart';
import 'package:ecalculator/other/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

typedef TaskDelete = Future<void> Function(HomeworkItem item);

class TaskPage extends StatefulWidget {
  const TaskPage({
    super.key,
    required this.item,
    required this.onDeleted,
    this.deleteTask,
    this.databaseHelper,
  });

  final HomeworkItem item;
  final ValueChanged<HomeworkItem> onDeleted;
  final TaskDelete? deleteTask;
  final DatabaseHelper? databaseHelper;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  var _isDeleting = false;

  Future<void> _delete() async {
    if (_isDeleting || !widget.item.isLocal) return;
    setState(() => _isDeleting = true);
    try {
      if (widget.deleteTask case final deleteTask?) {
        await deleteTask(widget.item);
      } else {
        final id = widget.item.localId;
        if (id == null) {
          throw StateError('Persisted local homework has no database id');
        }
        await (widget.databaseHelper ?? DatabaseHelper.instance).removeById(id);
      }
      if (!mounted) return;
      widget.onDeleted(widget.item);
      Navigator.pop(context);
    } on Object {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить задание')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = widget.item.content.trimLeft();
    final html = trimmed.startsWith('<')
        ? widget.item.content
        : '<p>${const HtmlEscape().convert(widget.item.content)}</p>';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item.subject,
          key: const ValueKey('task-page-title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [MoreMenu(canLeave: true)],
      ),
      body: ListView(
        key: const ValueKey('task-details-list'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Material(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HtmlWidget(
                html,
                key: const ValueKey('task-html-content'),
                textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurface,
                      height: 1.45,
                    ),
              ),
            ),
          ),
          if (widget.item.isLocal) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const ValueKey('delete-task'),
              onPressed: _isDeleting ? null : _delete,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
              ),
              icon: _isDeleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              label: const Text('Удалить'),
            ),
          ],
        ],
      ),
    );
  }
}
