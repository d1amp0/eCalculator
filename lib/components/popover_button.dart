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
        return PopupMenuButton<String>(
          key: ValueKey(_keyName),
          tooltip: widget.startText,
          position: PopupMenuPosition.under,
          color: scheme.surfaceContainer,
          surfaceTintColor: Colors.transparent,
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 300),
          onSelected: (value) {
            widget.controller.text = value;
            widget.checkControllers(false);
          },
          itemBuilder: (context) {
            if (_options.isEmpty) {
              return const [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text('Загрузка…'),
                ),
              ];
            }
            return [
              for (final option in _options)
                PopupMenuItem<String>(
                  key: ValueKey('$_keyName-option-$option'),
                  value: option,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurface),
                        ),
                      ),
                      if (selected == option) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.check, size: 20, color: scheme.primary),
                      ],
                    ],
                  ),
                ),
            ];
          },
          child: Semantics(
            button: true,
            label:
                '${widget.startText}: ${selected.isEmpty ? 'не выбран' : selected}',
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
        );
      },
    );
  }
}
