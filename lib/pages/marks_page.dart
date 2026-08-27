import 'package:ecalculator/components/error_message.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/components/popover_button.dart';
import 'package:ecalculator/domain/academic_calendar.dart';
import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/pages/mark_page.dart';
import 'package:ecalculator/other/app_theme_colors.dart';
import 'package:ecalculator/server/functions.dart';
import 'package:ecalculator/services/app_session.dart';
import 'package:ecalculator/services/demo/demo_data_source.dart';
import 'package:ecalculator/storage/settings_storage.dart';
import 'package:flutter/material.dart';

class MarksPage extends StatefulWidget {
  const MarksPage({super.key});

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
  late final PopoverButton periodPopoverButton;

  Future<void> _openTime() async {
    if (appSession.isDemo) {
      yearController.text = DemoDataSource.demoYear;
      periodController.text = DemoDataSource.demoPeriod;
      return;
    }
    yearController.text =
        await settings.readString('year') ?? AcademicCalendar.currentYear();
    periodController.text = await settings.readString('period') ??
        AcademicCalendar.currentQuarter() ??
        '';
  }

  Future<void> _load({required bool initial}) async {
    if (initial) await _openTime();
    if (yearController.text.isEmpty || periodController.text.isEmpty) return;
    setState(() => isLoading = true);

    try {
      final period = await eild(yearController.text + periodController.text);
      if (!mounted) return;
      if (period == '400') {
        setState(() => isLoading = false);
        showErrorPeriod(context);
        return;
      }
      final loaded = await getMarksMap(period);
      if (!mounted) return;
      setState(() {
        marksMap = loaded;
        averages = changeMarks(loaded);
        isLoading = false;
      });
      if (!appSession.isDemo) {
        await settings.writeString('year', yearController.text);
        await settings.writeString('period', periodController.text);
      }
    } on Object {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить оценки.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    periodPopoverButton = PopoverButton(
      startText: 'Учебный период',
      controller: periodController,
      checkControllers: (_) => _load(initial: false),
    );
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
        actions: [MoreMenu(canLeave: true, popoverButton: periodPopoverButton)],
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
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: periodPopoverButton),
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
