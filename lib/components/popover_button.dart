import 'package:ecalculator/domain/academic_calendar.dart';
import 'package:ecalculator/server/functions.dart';
import 'package:ecalculator/services/app_session.dart';
import 'package:ecalculator/storage/settings_storage.dart';
import 'package:flutter/material.dart';

class PopoverButton extends StatefulWidget {
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

  @override
  State<PopoverButton> createState() => _PopoverButtonState();
}

class _PopoverButtonState extends State<PopoverButton> {
  List<String> _options = const [];

  bool get _isPeriod => widget.startText == 'Учебный период';

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

  Future<void> _loadOptions() async {
    final options = await (widget.optionsLoader?.call() ?? _defaultOptions());
    if (mounted) setState(() => _options = options);
  }

  Future<void> _openOptions() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;
        return SafeArea(
          key: ValueKey('$_keyName-sheet'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.startText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (_options.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final isSelected = widget.controller.text == option;
                        return ListTile(
                          key: ValueKey('$_keyName-option-$option'),
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
                          onTap: () => Navigator.pop(sheetContext, option),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    widget.controller.text = selected;
    widget.checkControllers(false);
  }

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final selected = widget.controller.text;
        return Semantics(
          button: true,
          label:
              '${widget.startText}: ${selected.isEmpty ? 'не выбран' : selected}',
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
              onTap: _openOptions,
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
                          selected.isEmpty ? widget.startText : selected,
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
