import 'package:ecalculator/components/error_message.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/components/popover_button.dart';
import 'package:ecalculator/domain/academic_calendar.dart';
import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/pages/mark_page.dart';
import 'package:ecalculator/other/app_theme_colors.dart';
import 'package:ecalculator/server/functions.dart';
import 'package:ecalculator/storage/settings_storage.dart';
import 'package:flutter/material.dart';

class MarksPage extends StatefulWidget {
  const MarksPage({
    super.key,
    this.initialYear,
    this.initialPeriod,
    this.yearOptionsLoader,
    this.periodOptionsLoader,
    this.periodIdLoader,
    this.marksLoader,
  }) : assert((initialYear == null) == (initialPeriod == null));

  final String? initialYear;
  final String? initialPeriod;
  final Future<List<String>> Function()? yearOptionsLoader;
  final Future<List<String>> Function()? periodOptionsLoader;
  final Future<String> Function(String selection)? periodIdLoader;
  final Future<SubjectMarks> Function(String periodId)? marksLoader;

  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final yearController = TextEditingController();
  final periodController = TextEditingController();
  final settings = SettingsStorage();
  bool isLoading = false;
  Map<String, double> averages = {};
  SubjectMarks marksMap = {};
  int _loadGeneration = 0;

  bool _isCurrent(int generation) => mounted && generation == _loadGeneration;

  Future<void> _openTime(int generation) async {
    if (widget.initialYear != null && widget.initialPeriod != null) {
      yearController.text = widget.initialYear!;
      periodController.text = widget.initialPeriod!;
      return;
    }
    final year =
        await settings.readString('year') ?? AcademicCalendar.currentYear();
    if (!_isCurrent(generation)) return;
    final period = await settings.readString('period') ??
        AcademicCalendar.currentQuarter() ??
        '';
    if (!_isCurrent(generation)) return;
    yearController.text = year;
    periodController.text = period;
  }

  Future<void> _load({required bool initial}) async {
    final generation = ++_loadGeneration;
    try {
      if (initial) await _openTime(generation);
      if (!_isCurrent(generation)) return;
      final year = yearController.text;
      final periodName = periodController.text;
      if (year.isEmpty || periodName.isEmpty) {
        setState(() => isLoading = false);
        return;
      }
      setState(() => isLoading = true);

      final resolvePeriod = widget.periodIdLoader ?? eild;
      final loadMarks = widget.marksLoader ?? getMarksMap;
      final period = await resolvePeriod(year + periodName);
      if (!_isCurrent(generation)) return;
      if (period == '400') {
        setState(() => isLoading = false);
        if (!mounted) return;
        showErrorPeriod(context);
        return;
      }
      final loaded = await loadMarks(period);
      if (!_isCurrent(generation)) return;
      setState(() {
        marksMap = loaded;
        averages = changeMarks(loaded);
        isLoading = false;
      });
      await settings.writeString('year', year);
      if (!_isCurrent(generation)) return;
      await settings.writeString('period', periodName);
      if (!_isCurrent(generation)) return;
    } on Object {
      if (!_isCurrent(generation)) return;
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить оценки.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  @override
  void dispose() {
    yearController.dispose();
    periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор'),
        actions: const [MoreMenu(canLeave: true)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: PopoverButton(
                    startText: 'Учебный год',
                    controller: yearController,
                    checkControllers: (_) => _load(initial: false),
                    optionsLoader: widget.yearOptionsLoader,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PopoverButton(
                    startText: 'Учебный период',
                    controller: periodController,
                    checkControllers: (_) => _load(initial: false),
                    optionsLoader: widget.periodOptionsLoader,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isLoading
                  ? Center(
                      key: const ValueKey('marks-loading'),
                      child: CircularProgressIndicator(
                        color: AppThemeColors.scaffoldText(context),
                      ),
                    )
                  : averages.isEmpty
                      ? Center(
                          key: const ValueKey('marks-empty'),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Нет оценок за выбранный период.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppThemeColors.scaffoldText(context),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          key: const ValueKey('subjects-list'),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: averages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final entry = averages.entries.elementAt(index);
                            return Material(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => MarkPage(
                                      name: entry.key,
                                      markList: marksMap[entry.key] ?? const [],
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        entry.value.toStringAsFixed(2),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
