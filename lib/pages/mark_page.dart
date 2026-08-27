import 'package:ecalculator/components/mark_button.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/components/plus_button.dart';
import 'package:ecalculator/domain/calculator_scenario.dart';
import 'package:ecalculator/domain/mark_format.dart';
import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/storage/settings_storage.dart';
import 'package:flutter/material.dart';

class MarkPage extends StatefulWidget {
  const MarkPage({
    super.key,
    required this.name,
    required this.markList,
  });

  final String name;
  final List<StudentMark> markList;

  @override
  State<MarkPage> createState() => _MarkPageState();
}

class _MarkPageState extends State<MarkPage> {
  late final CalculatorScenario scenario;
  bool withPlusMinus = false;

  @override
  void initState() {
    super.initState();
    scenario = CalculatorScenario(widget.markList);
    _loadMarkType();
  }

  Future<void> _loadMarkType() async {
    withPlusMinus = await SettingsStorage().readBool('mark_type') ?? false;
    if (mounted) setState(() {});
  }

  void _change(VoidCallback operation) => setState(operation);

  Future<void> _addMark() async {
    final result = await _showMarkEditor(context, withPlusMinus: withPlusMinus);
    if (result == null) return;
    _change(() => scenario.add(value: result.value, weight: result.weight));
  }

  Future<void> _openMark(ScenarioMark item) async {
    if (item.isExcluded) {
      final restore = await _showRestoreSheet(
        context,
        title: 'Оценка исключена',
        subtitle:
            '${formatMarkValue(item.mark.value)} ×${formatWeight(item.mark.weight)}',
      );
      if (restore) _change(() => scenario.restore(item.mark.id));
      return;
    }

    if (item.isAdded) {
      final remove = await _showRestoreSheet(
        context,
        title: 'Новая оценка',
        subtitle: 'Добавлена только в текущий сценарий',
        actionLabel: 'Удалить из сценария',
        actionIcon: Icons.delete_outline,
      );
      if (remove) _change(() => scenario.restore(item.mark.id));
      return;
    }

    final result = await _showMarkEditor(
      context,
      initial: item.mark,
      withPlusMinus: withPlusMinus,
      allowExclude: true,
      allowRestore: item.isEdited,
    );
    if (result == null) return;
    switch (result.action) {
      case _EditorAction.save:
        _change(
          () => scenario.edit(
            item.mark.id,
            value: result.value,
            weight: result.weight,
          ),
        );
      case _EditorAction.exclude:
        _change(() => scenario.exclude(item.mark.id));
      case _EditorAction.restore:
        _change(() => scenario.restore(item.mark.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: const [MoreMenu(canLeave: true)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _ResultArea(scenario: scenario),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Оценки', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              PlusButton(onPressed: _addMark),
            ],
          ),
          const SizedBox(height: 12),
          if (scenario.marks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('За этот период пока нет оценок.'),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in scenario.marks)
                  MarkButton(item: item, onPressed: () => _openMark(item)),
              ],
            ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: scenario.hasChanges
                ? _ScenarioArea(
                    key: const ValueKey('scenario-area'),
                    scenario: scenario,
                    onRestore: (id) => _change(() => scenario.restore(id)),
                    onReset: () => _change(scenario.reset),
                  )
                : const SizedBox.shrink(key: ValueKey('empty-scenario')),
          ),
        ],
      ),
    );
  }
}

class _ResultArea extends StatelessWidget {
  const _ResultArea({required this.scenario});

  final CalculatorScenario scenario;

  @override
  Widget build(BuildContext context) {
    final original = scenario.originalAverage;
    final predicted = scenario.predictedAverage;
    final delta =
        original == null || predicted == null ? null : predicted - original;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Средний балл', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: scenario.hasChanges
                  ? Row(
                      key: ValueKey(formatAverage(predicted)),
                      children: [
                        Text(
                          formatAverage(original),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_forward),
                        ),
                        Flexible(
                          child: Text(
                            formatAverage(predicted),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      formatAverage(original),
                      key: const ValueKey('original-average'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
            if (scenario.hasChanges) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    delta != null && delta < 0
                        ? Icons.trending_down
                        : Icons.trending_up,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    delta == null
                        ? 'После изменений оценок нет'
                        : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}',
                    key: const ValueKey('average-delta'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              scenario.hasChanges
                  ? 'Предварительный результат · изменения только на этом экране'
                  : 'Текущие данные из журнала',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioArea extends StatelessWidget {
  const _ScenarioArea({
    super.key,
    required this.scenario,
    required this.onRestore,
    required this.onReset,
  });

  final CalculatorScenario scenario;
  final ValueChanged<String> onRestore;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Изменения',
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  key: const ValueKey('reset-scenario-button'),
                  onPressed: onReset,
                  child: const Text('Сбросить всё'),
                ),
              ],
            ),
            for (final operation in scenario.operations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_operationIcon(operation.type)),
                title: Text(_operationLabel(operation)),
                subtitle: Text(_operationSubtitle(operation)),
                trailing: IconButton(
                  tooltip: 'Отменить изменение',
                  onPressed: () => onRestore(operation.mark.id),
                  icon: const Icon(Icons.undo),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

IconData _operationIcon(ScenarioOperationType type) => switch (type) {
      ScenarioOperationType.add => Icons.add_circle_outline,
      ScenarioOperationType.edit => Icons.edit_outlined,
      ScenarioOperationType.exclude => Icons.remove_circle_outline,
    };

String _operationLabel(ScenarioOperation operation) => switch (operation.type) {
      ScenarioOperationType.add =>
        '+ ${formatMarkValue(operation.mark.value)} ×${formatWeight(operation.mark.weight)}',
      ScenarioOperationType.edit =>
        '${formatMarkValue(operation.original!.value)} → ${formatMarkValue(operation.mark.value)}',
      ScenarioOperationType.exclude =>
        '− ${formatMarkValue(operation.mark.value)} ×${formatWeight(operation.mark.weight)}',
    };

String _operationSubtitle(ScenarioOperation operation) =>
    switch (operation.type) {
      ScenarioOperationType.add => 'Новая оценка',
      ScenarioOperationType.edit =>
        'Коэффициент ${formatWeight(operation.original!.weight)} → ${formatWeight(operation.mark.weight)}',
      ScenarioOperationType.exclude => 'Исключена из расчёта',
    };

enum _EditorAction { save, exclude, restore }

class _MarkEditorResult {
  const _MarkEditorResult(this.action, this.value, this.weight);

  final _EditorAction action;
  final double value;
  final double weight;
}

Future<_MarkEditorResult?> _showMarkEditor(
  BuildContext context, {
  StudentMark? initial,
  required bool withPlusMinus,
  bool allowExclude = false,
  bool allowRestore = false,
}) {
  var baseValue = initial?.value.round().clamp(1, 5) ?? 5;
  var modifier = initial == null ? 0.0 : _modifierFor(initial.value);
  final weightController = TextEditingController(
    text: formatWeight(initial?.weight ?? 1),
  );

  return showModalBottomSheet<_MarkEditorResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final weight =
            double.tryParse(weightController.text.replaceAll(',', '.'));
        final valid = weight != null && weight > 0;
        final value = baseValue + modifier;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  initial == null ? 'Добавить оценку' : 'Изменить оценку',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (initial != null) ...[
                  const SizedBox(height: 4),
                  Text('Дата: ${initial.date} · только для сценария'),
                ],
                const SizedBox(height: 20),
                Text('Оценка', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var mark = 1; mark <= 5; mark++)
                      ChoiceChip(
                        label: Text('$mark'),
                        selected: baseValue == mark,
                        onSelected: (_) =>
                            setSheetState(() => baseValue = mark),
                      ),
                  ],
                ),
                if (withPlusMinus) ...[
                  const SizedBox(height: 12),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: -0.2, label: Text('−')),
                      ButtonSegment(value: 0, label: Text('Без знака')),
                      ButtonSegment(value: 0.2, label: Text('+')),
                    ],
                    selected: {modifier},
                    onSelectionChanged: (selection) =>
                        setSheetState(() => modifier = selection.first),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Коэффициент',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final quickWeight in const [1.0, 1.5, 2.0]) ...[
                      ActionChip(
                        label: Text(formatWeight(quickWeight)),
                        onPressed: () {
                          weightController.text = formatWeight(quickWeight);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextField(
                        key: const ValueKey('mark-weight-field'),
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setSheetState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Другой',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('save-mark-button'),
                  onPressed: valid
                      ? () => Navigator.pop(
                            sheetContext,
                            _MarkEditorResult(
                              _EditorAction.save,
                              value,
                              weight,
                            ),
                          )
                      : null,
                  child: Text(initial == null ? 'Добавить' : 'Сохранить'),
                ),
                if (allowExclude)
                  TextButton.icon(
                    key: const ValueKey('exclude-mark-button'),
                    onPressed: () => Navigator.pop(
                      sheetContext,
                      _MarkEditorResult(
                        _EditorAction.exclude,
                        value,
                        weight ?? 1,
                      ),
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                    label: const Text('Исключить из расчёта'),
                  ),
                if (allowRestore)
                  TextButton.icon(
                    onPressed: () => Navigator.pop(
                      sheetContext,
                      _MarkEditorResult(
                        _EditorAction.restore,
                        value,
                        weight ?? 1,
                      ),
                    ),
                    icon: const Icon(Icons.undo),
                    label: const Text('Вернуть исходную оценку'),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  ).whenComplete(weightController.dispose);
}

double _modifierFor(double value) {
  final difference = value - value.round();
  if ((difference - 0.2).abs() < 0.001) return 0.2;
  if ((difference + 0.2).abs() < 0.001) return -0.2;
  return 0;
}

Future<bool> _showRestoreSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  String actionLabel = 'Вернуть в расчёт',
  IconData actionIcon = Icons.restore,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(subtitle),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  icon: Icon(actionIcon),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;
}
