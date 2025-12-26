import 'package:flutter/material.dart';
import 'package:hello/components/error_message.dart';
import 'package:hello/components/more_menu.dart';
import 'package:hello/components/popover_button.dart';
import 'package:hello/pages/mark_page.dart';
import 'package:hello/server/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarksPage extends StatefulWidget {
  const MarksPage({super.key});

  @override
  State<MarksPage> createState() => _MarksPageState();
}

class _MarksPageState extends State<MarksPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final yearController = TextEditingController(),
      periodController = TextEditingController();
  bool isTable = false,
      isDownloading = false;
  Map<String, double> changeMarksMap = {};
  Map<String, List<List<dynamic>>> marksMap = {};
  late PopoverButton periodPopoverButton;

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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("year", yearController.text);
    prefs.setString("period", periodController.text);
  }

  Future<bool> openTime() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      yearController.text = prefs.getString("year")!;
    } on Exception {}
    try {
      periodController.text = prefs.getString("period")!;
    } on Exception {}
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
      if (period != "400") {
        marksMap = await getMarksMap(period);
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
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  const SizedBox(
                    width: 10,
                  ),
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
                  SizedBox(
                    width: 158,
                    height: 48,
                    child: periodPopoverButton,
                  ),
                  const Spacer(),
                  MoreMenu(
                      canLeave: true,
                      popoverButton: periodPopoverButton,
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                height: isTable ? MediaQuery.of(context).size.height - 180 : 0,
                child: isTable ? ListView(
                    children: [DataTable(
                      columns: const [
                        DataColumn(label: Text('Предмет')),
                        DataColumn(label: Text('Балл')),
                        DataColumn(label: Text('Перейти'))
                      ],
                      rows: isTable
                          ? [
                        for (var elem in changeMarksMap.entries)
                          DataRow(cells: [
                            DataCell(Text(
                              elem.key,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme
                                      .of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.color),
                            )),
                            DataCell(Text(
                              elem.value.toString(),
                              style: TextStyle(
                                  fontSize: 16, color: getColor(elem.value)),
                            )),
                            DataCell(IconButton(
                                onPressed: () =>
                                {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MarkPage(
                                            name: elem.key,
                                            markList: marksMap[elem.key],
                                          ),
                                    ),
                                  )
                                },
                                icon: Icon(
                                  Icons.arrow_right_alt,
                                  size: 35,
                                  color: Theme
                                      .of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.color,
                                ))),
                          ])
                      ]
                          : [],
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        shape: BoxShape.rectangle,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .secondary,
                      ),
                      headingTextStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme
                              .of(context)
                              .textTheme
                              .displayLarge
                              ?.color),
                    ),]
                ) : null,
              ),
              SizedBox(height: isDownloading ? 300 : 0,),
              Center(
                child: isDownloading ? CircularProgressIndicator(
                  backgroundColor: Colors.blue,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .secondary,
                ) : null,
              ),
            ],
          )),
    );
  }
}
