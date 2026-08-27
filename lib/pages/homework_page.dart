import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/other/database_helper.dart';
import 'package:ecalculator/pages/add_task_page.dart';
import 'package:ecalculator/pages/task_page.dart';
import 'package:ecalculator/server/functions.dart';
import 'package:intl/intl.dart';
import 'package:ecalculator/services/app_session.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  Map<int, List> homeworks = {};
  List<int> dates = [];
  List rawHomeworks = [];
  bool readyToBuild = false;

  Future<Map<int, List>> homework() async {
    Map<int, List> homeworksDate = {};
    List waiting = await homeworkServer();
    for (var elem in waiting) {
      rawHomeworks.add(elem);
    }
    for (var elem in rawHomeworks) {
      if (homeworksDate.containsKey(elem[2])) {
        if (elem[4]) {
          homeworksDate[elem[2]]?.add([elem[1], elem[3], elem[3], true]);
        } else {
          homeworksDate[elem[2]]?.add([
            utf8.decode(latin1.encode(elem[1])),
            elem[3] != null
                ? deleteColors(utf8.decode(latin1.encode(elem[3])))
                : '',
            elem[3] != null
                ? extractText(utf8.decode(latin1.encode(elem[3])))
                : '',
            false,
          ]);
        }
      } else {
        if (elem[4]) {
          homeworksDate.addAll({
            elem[2]: [
              [elem[1], elem[3], elem[3], true],
            ],
          });
        } else {
          homeworksDate.addAll({
            elem[2]: [
              [
                utf8.decode(latin1.encode(elem[1])),
                elem[3] != null
                    ? deleteColors(utf8.decode(latin1.encode(elem[3])))
                    : '',
                elem[3] != null
                    ? extractText(utf8.decode(latin1.encode(elem[3])))
                    : '',
                false,
              ],
            ],
          });
        }
      }
    }
    return homeworksDate;
  }

  Future<void> fillHomeworks() async {
    homeworks = await homework();
    dates = homeworks.keys.toList();
    dates.sort();
    setState(() {
      readyToBuild = true;
    });
  }

  void addToHomeworks(List list) {
    if (homeworks.containsKey(list[0])) {
      setState(() {
        homeworks[list[0]]?.add([list[1], list[2], list[2], true]);
        refreshDates();
      });
    } else {
      setState(() {
        homeworks.addAll({
          list[0]: [
            [list[1], list[2], list[2], true],
          ],
        });
        refreshDates();
      });
    }
  }

  void deleteFromHomeworks(String text) {
    setState(() {
      int keyDelete = 0;
      List listDelete = [];
      for (var key in homeworks.keys) {
        for (var elem in homeworks[key]!) {
          if (elem.contains(text)) {
            keyDelete = key;
            listDelete = elem;
            break;
          }
        }
      }
      homeworks[keyDelete]?.remove(listDelete);
      if (homeworks[keyDelete]!.isEmpty) {
        homeworks.remove(keyDelete);
      }
      refreshDates();
    });
  }

  void refreshDates() {
    setState(() {
      dates = homeworks.keys.toList();
      dates.sort();
    });
  }

  Future<void> openDB() async {
    if (appSession.isDemo) return;
    List tasks = await DatabaseHelper.instance.getTasks();
    for (var task in tasks) {
      if (task.time <
          DateTime.now().millisecondsSinceEpoch - 7 * 24 * 60 * 60 * 1000) {
        await DatabaseHelper.instance.remove(task.info);
      } else {
        rawHomeworks.add([0000000, task.subject, task.time, task.info, true]);
      }
    }
  }

  Future<void> homeworkStuff() async {
    await openDB();
    fillHomeworks();
  }

  @override
  void initState() {
    homeworkStuff();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskPage(function: addToHomeworks),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).textTheme.displayLarge?.color,
        child: const Icon(Icons.add_task, size: 30),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(flex: 3),
                Text(
                  "Задания",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.displaySmall?.color,
                    fontSize: 32,
                  ),
                ),
                const Spacer(flex: 2),
                const MoreMenu(canLeave: true),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: MediaQuery.of(context).size.height - 180,
              child: readyToBuild
                  ? ListView.builder(
                      itemCount: dates.length,
                      itemBuilder: (context, indexDate) {
                        return Column(
                          children: [
                            Center(
                              child: Container(
                                height: 25,
                                width: 85,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  shape: BoxShape.rectangle,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                child: Center(
                                  child: Text(
                                    DateFormat('dd.MM.yyyy')
                                        .format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                            dates[indexDate],
                                          ),
                                        )
                                        .toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: homeworks[dates[indexDate]]!
                                      .length
                                      .toDouble() *
                                  110,
                              child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: homeworks[dates[indexDate]]?.length,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      GestureDetector(
                                        child: Center(
                                          child: Container(
                                            height: 100,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                30,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              shape: BoxShape.rectangle,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 3),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    right: 10,
                                                    left: 10,
                                                  ),
                                                  child: Text(
                                                    homeworks[dates[
                                                                indexDate]]![
                                                            index][0]
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .displayLarge
                                                          ?.color,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    right: 10,
                                                    left: 10,
                                                  ),
                                                  child: SizedBox(
                                                    height: 54,
                                                    child: HtmlWidget(
                                                      homeworks[dates[
                                                              indexDate]]![
                                                          index][2],
                                                      textStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .displayLarge
                                                            ?.color,
                                                        overflow:
                                                            TextOverflow.fade,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TaskPage(
                                                task: homeworks[
                                                    dates[indexDate]]![index],
                                                function: deleteFromHomeworks,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
