import 'package:flutter/material.dart';
import 'package:ecalculator/components/error_message.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/components/popover_button.dart';
import 'package:ecalculator/pages/mark_page.dart';
import 'package:ecalculator/server/functions.dart';
import 'package:ecalculator/domain/academic_calendar.dart';
import 'package:ecalculator/storage/settings_storage.dart';

class MarksPage extends StatefulWidget {
  const MarksPage({super.key});

  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final yearController = TextEditingController(),
      periodController = TextEditingController();
  bool isTable = false, isDownloading = false;
  Map<String, double> changeMarksMap = {};
  Map<String, List<List<dynamic>>> marksMap = {};
  late PopoverButton periodPopoverButton;
  final settings = SettingsStorage();

  Color getColor(double value) {
    switch (value) {
      case >= 4.00:
        return const Color.fromARGB(255, 3, 192, 60);
      case >= 3.00:
        return const Color.fromARGB(255, 255, 213, 0);
      case >= 2.00:
        return const Color.fromARGB(255, 246, 166, 0);
      default:
        return const Color.fromARGB(255, 220, 20, 60);
    }
  }

  void saveTime() async {
    await settings.writeString("year", yearController.text);
    await settings.writeString("period", periodController.text);
  }

  Future<bool> openTime() async {
    yearController.text =
        await settings.readString("year") ?? AcademicCalendar.currentYear();
    periodController.text = await settings.readString("period") ??
        AcademicCalendar.currentQuarter() ??
        '';
    return true;
  }

  void checkControllers(bool justOpened) async {
    if (justOpened) await openTime();
    if (yearController.text.isNotEmpty && periodController.text.isNotEmpty) {
      setState(() {
        isDownloading = true;
        isTable = false;
      });
      String period = await eild(yearController.text + periodController.text);
      if (!mounted) return;
      if (period != "400") {
        marksMap = await getMarksMap(period);
        if (!mounted) return;
        changeMarksMap = changeMarks(marksMap);
        setState(() {
          isTable = true;
          isDownloading = false;
        });
        saveTime();
      } else {
        setState(() {
          isDownloading = false;
        });
        showErrorPeriod(context);
      }
    }
  }

  @override
  void initState() {
    checkControllers(true);
    periodPopoverButton = PopoverButton(
      startText: 'Учебный период',
      controller: periodController,
      checkControllers: checkControllers,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 10),
                SizedBox(
                  width: 158,
                  height: 48,
                  child: PopoverButton(
                    startText: 'Учебный год',
                    controller: yearController,
                    checkControllers: checkControllers,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 158, height: 48, child: periodPopoverButton),
                const Spacer(),
                MoreMenu(canLeave: true, popoverButton: periodPopoverButton),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: isTable ? MediaQuery.of(context).size.height - 180 : 0,
              child: isTable
                  ? ListView(
                      children: [
                        DataTable(
                          columns: const [
                            DataColumn(label: Text('Предмет')),
                            DataColumn(label: Text('Балл')),
                            DataColumn(label: Text('Перейти')),
                          ],
                          rows: isTable
                              ? [
                                  for (var elem in changeMarksMap.entries)
                                    DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            elem.key,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .displayLarge
                                                  ?.color,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            elem.value.toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: getColor(elem.value),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            onPressed: () => {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      MarkPage(
                                                    name: elem.key,
                                                    markList:
                                                        marksMap[elem.key],
                                                  ),
                                                ),
                                              ),
                                            },
                                            icon: Icon(
                                              Icons.arrow_right_alt,
                                              size: 35,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .displayLarge
                                                  ?.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ]
                              : [],
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            shape: BoxShape.rectangle,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          headingTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.displayLarge?.color,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            SizedBox(height: isDownloading ? 300 : 0),
            Center(
              child: isDownloading
                  ? CircularProgressIndicator(
                      backgroundColor: Colors.blue,
                      color: Theme.of(context).colorScheme.secondary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
