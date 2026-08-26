import 'package:flutter/material.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/other/database_helper.dart';
import 'package:ecalculator/other/task.dart';
import 'package:intl/intl.dart';

class AddTaskPage extends StatefulWidget {
  final Function function;
  const AddTaskPage({super.key, required this.function});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  TextEditingController subjectController = TextEditingController(),
      taskController = TextEditingController();
  String subject = '', dateText = '', task = '';
  int dateInt = 0;
  bool isDisabled = true;

  void checkFields(String? value) {
    bool condition = subjectController.text.isNotEmpty &&
        taskController.text.isNotEmpty &&
        dateInt != 0;
    setState(() {
      if (condition) {
        isDisabled = false;
      } else {
        isDisabled = true;
      }
    });
  }

  Future<void> selectDate() async {
    DateTime? selected = await showDatePicker(
      context: context,
      locale: const Locale('ru'),
      initialDate: DateTime.now(),
      firstDate: DateTime.now().add(const Duration(days: -7)),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (selected != null) {
      setState(() {
        dateText = DateFormat('dd.MM.yyyy').format(selected);
        dateInt = selected.toUtc().millisecondsSinceEpoch;
      });
    }
  }

  void goDatabase() async {
    await DatabaseHelper.instance.add(Task(
        subject: subjectController.text,
        info: taskController.text,
        time: dateInt));
    widget.function([dateInt, subjectController.text, taskController.text]);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Column(children: [
        Row(
          children: [
            const SizedBox(
              width: 10,
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(
                Icons.arrow_back_sharp,
                color: Theme.of(context).textTheme.displaySmall?.color,
                size: 30,
              ),
            ),
            const Spacer(),
            Text(
              "Добавить д/з",
              style: TextStyle(
                color: Theme.of(context).textTheme.displaySmall?.color,
                fontSize: 32,
              ),
            ),
            const Spacer(),
            const MoreMenu(canLeave: true)
          ],
        ),
        Divider(
          height: 5,
          thickness: 1,
          color: Theme.of(context).textTheme.displaySmall?.color,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0),
          child: TextField(
            onChanged: (value) => checkFields(value),
            controller: subjectController,
            style: TextStyle(
                color: Theme.of(context).textTheme.displayLarge?.color),
            decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary),
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.school,
                    color: Theme.of(context).textTheme.displayLarge?.color),
                hintText: "Предмет",
                hintStyle: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w400),
                fillColor: Theme.of(context).colorScheme.secondary,
                filled: true),
          ),
        ),
        GestureDetector(
          onTap: selectDate,
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10.0)),
              child: Row(
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  Icon(
                    Icons.date_range,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(dateText.isEmpty ? "Выберите дату" : dateText,
                      style: TextStyle(
                          fontSize: 18,
                          color:
                              Theme.of(context).textTheme.displayLarge?.color)),
                  const Spacer(),
                  Icon(
                    dateText.isEmpty ? Icons.close : Icons.check,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 20.0, right: 20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height - 300),
            child: TextField(
              onChanged: (value) => checkFields(value),
              controller: taskController,
              style: TextStyle(
                  color: Theme.of(context).textTheme.displayLarge?.color),
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.short_text,
                      color: Theme.of(context).textTheme.displayLarge?.color),
                  hintText: "Текст задания",
                  hintStyle: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w400),
                  fillColor: Theme.of(context).colorScheme.secondary,
                  filled: true),
              maxLines: null,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: goDatabase,
          child: Padding(
            padding:
                const EdgeInsets.only(top: 20, left: 75, right: 75, bottom: 20),
            child: isDisabled
                ? null
                : Container(
                    height: 48,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(10.0)),
                    child: Center(
                      child: Text(
                        'Готово',
                        style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    )),
          ),
        ),
      ]),
    ));
  }
}
