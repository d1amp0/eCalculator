import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:eCalculator/components/more_menu.dart';
import 'package:eCalculator/other/database_helper.dart';

class TaskPage extends StatefulWidget {
  final List task;
  final Function function;

  const TaskPage({super.key, required this.task, required this.function});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {

  void deleteFromDB() async {
    await DatabaseHelper.instance.remove(widget.task[1]);
    widget.function(widget.task[1]);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
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
              SizedBox(
                width: MediaQuery.of(context)
                    .size
                    .width -
                    130,
                child: Text(
                  widget.task[0],
                  style: TextStyle(
                    color: Theme.of(context).textTheme.displaySmall?.color,
                    fontSize: 32,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            padding: const EdgeInsets.only(right: 10, left: 10),
            child: HtmlWidget(
              widget.task[1][0] == '<' ? widget.task[1] : "<p>${widget.task[1]}</p>",
              textStyle: TextStyle(
                  color: Theme.of(context).textTheme.displaySmall?.color,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  fontSize: 18),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: deleteFromDB,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 75, right: 75, bottom: 20),
              child: widget.task[3] ? Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Center(
                    child: Text(
                      'Удалить',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  )) : null,
            ),
          ),
        ],
      )),
    );
  }
}
