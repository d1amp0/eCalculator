import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/other/database_helper.dart';
import 'package:ecalculator/other/task.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef TaskSaver = Future<int?> Function(Task task);
typedef TaskDatePicker = Future<DateTime?> Function(BuildContext context);

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({
    super.key,
    required this.function,
    this.saveTask,
    this.datePicker,
  });

  final ValueChanged<Task> function;
  final TaskSaver? saveTask;
  final TaskDatePicker? datePicker;

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _subjectController = TextEditingController();
  final _taskController = TextEditingController();
  DateTime? _selectedDate;
  var _isSaving = false;

  bool get _isValid =>
      _subjectController.text.trim().isNotEmpty &&
      _taskController.text.trim().isNotEmpty &&
      _selectedDate != null;

  void _fieldsChanged() => setState(() {});

  Future<DateTime?> _defaultDatePicker(BuildContext context) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      locale: const Locale('ru'),
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 14)),
    );
  }

  Future<void> _selectDate() async {
    final selected = await (widget.datePicker ?? _defaultDatePicker)(context);
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = selected);
  }

  Future<void> _submit() async {
    if (!_isValid || _isSaving) return;
    setState(() => _isSaving = true);
    final task = Task(
      subject: _subjectController.text.trim(),
      info: _taskController.text.trim(),
      time: _selectedDate!.toUtc().millisecondsSinceEpoch,
    );
    try {
      final saveTask = widget.saveTask;
      final id = saveTask != null
          ? await saveTask(task)
          : await DatabaseHelper.instance.add(task);
      if (!mounted) return;
      widget.function(
        Task(id: id, subject: task.subject, info: task.info, time: task.time),
      );
      Navigator.pop(context);
    } on Object {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось добавить задание')),
      );
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить задание'),
        actions: const [MoreMenu(canLeave: true)],
      ),
      body: ListView(
        key: const ValueKey('add-task-form'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TextField(
            key: const ValueKey('task-subject-field'),
            controller: _subjectController,
            onChanged: (_) => _fieldsChanged(),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Предмет',
              prefixIcon: Icon(Icons.school_outlined),
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('task-date-control'),
              onTap: _isSaving ? null : _selectDate,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Дата',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            Text(
                              _selectedDate == null
                                  ? 'Выбрать дату'
                                  : DateFormat(
                                      'd MMMM y',
                                      'ru',
                                    ).format(_selectedDate!),
                              key: const ValueKey('task-selected-date'),
                              style: TextStyle(color: scheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('task-text-field'),
            controller: _taskController,
            onChanged: (_) => _fieldsChanged(),
            minLines: 5,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Задание',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 96),
                child: Icon(Icons.edit_note_outlined),
              ),
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('add-task-submit'),
            onPressed: _isValid && !_isSaving ? _submit : null,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
