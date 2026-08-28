import 'package:ecalculator/domain/academic_calendar.dart';
import 'package:ecalculator/server/functions.dart';
import 'package:ecalculator/services/app_session.dart';
import 'package:ecalculator/storage/settings_storage.dart';
import 'package:flutter/material.dart';

class PopoverButton extends StatelessWidget {
  const PopoverButton({
    super.key,
    required this.startText,
    required this.controller,
    required this.checkControllers,
    this.optionsLoader,
  });

  final String startText;
  final TextEditingController controller;
  final ValueChanged<bool> checkControllers;
  final Future<List<String>> Function()? optionsLoader;

  bool get _isPeriod => startText == 'Учебный период';

  String get _keyName => _isPeriod ? 'period-selector' : 'year-selector';

  Future<List<String>> _defaultOptions() async {
    if (_isPeriod) {
      if (appSession.isDemo) return _quarterOptions;
      final period = await SettingsStorage().readInt('period_type');
      return switch (period) {
        1 => const ['1 полугодие', '2 полугодие', 'Учебный год'],
        2 => const ['1 семестр', '2 семестр', 'Учебный год'],
        _ => _quarterOptions,
      };
    }

    try {
      final years = await academicYears();
      return years.isEmpty ? AcademicCalendar.recentYears() : years;
    } on Object {
      return AcademicCalendar.recentYears();
    }
  }

  static const _quarterOptions = [
    '1 четверть',
    '2 четверть',
    '3 четверть',
    '4 четверть',
    'Учебный год',
  ];

  Future<void> _openOptions(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => _SelectorOptionsSheet(
        keyName: _keyName,
        title: startText,
        selected: controller.text,
        optionsLoader: optionsLoader ?? _defaultOptions,
      ),
    );
    if (selected == null || !context.mounted) return;
    controller.text = selected;
    checkControllers(false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.text;
        return Semantics(
          button: true,
          label: '$startText: ${selected.isEmpty ? 'не выбран' : selected}',
          child: Material(
            key: ValueKey(_keyName),
            color: scheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('$_keyName-tap-target'),
              onTap: () => _openOptions(context),
              child: SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        _isPeriod
                            ? Icons.calendar_view_month_outlined
                            : Icons.calendar_today_outlined,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selected.isEmpty ? startText : selected,
                          key: ValueKey('$_keyName-value'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectorOptionsSheet extends StatefulWidget {
  const _SelectorOptionsSheet({
    required this.keyName,
    required this.title,
    required this.selected,
    required this.optionsLoader,
  });

  final String keyName;
  final String title;
  final String selected;
  final Future<List<String>> Function() optionsLoader;

  @override
  State<_SelectorOptionsSheet> createState() => _SelectorOptionsSheetState();
}

class _SelectorOptionsSheetState extends State<_SelectorOptionsSheet> {
  late final Future<List<String>> _options;

  @override
  void initState() {
    super.initState();
    _options = Future.sync(widget.optionsLoader);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      key: ValueKey('${widget.keyName}-sheet'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FutureBuilder<List<String>>(
                future: _options,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _SelectorSheetMessage(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return const _SelectorSheetMessage(
                      child: Text('Не удалось загрузить'),
                    );
                  }
                  final options = snapshot.data ?? const [];
                  if (options.isEmpty) {
                    return const _SelectorSheetMessage(
                      child: Text('Нет вариантов'),
                    );
                  }
                  return ListView.builder(
                    key: ValueKey('${widget.keyName}-options-list'),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = widget.selected == option;
                      return ListTile(
                        key: ValueKey('${widget.keyName}-option-$option'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        selected: isSelected,
                        selectedTileColor: scheme.secondaryContainer,
                        textColor: scheme.onSurface,
                        selectedColor: scheme.onSecondaryContainer,
                        title: Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelected ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.pop(context, option),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorSheetMessage extends StatelessWidget {
  const _SelectorSheetMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: child),
      ),
    );
  }
}
