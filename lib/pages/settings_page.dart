import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hello/components/icon_button.dart';
import 'package:hello/components/more_menu.dart';
import 'package:hello/components/popover_button.dart';
import 'package:hello/components/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final PopoverButton? popoverButton;
  const SettingsPage({super.key, this.popoverButton});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<bool> isSelected = [false, false, false];
  int? themeSliding, periodSliding, markSliding;
  bool withPM = false;
  final prefs = SharedPreferences.getInstance();

  void saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("theme", themeSliding!);
  }

  void getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? theme = prefs.getInt("theme");
    theme != null ? themeSliding = theme : themeSliding = 0;
    setState(() {
      themeSliding;
    });
  }

  void savePeriod() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("period_type", periodSliding!);
  }

  void getPeriod() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? period = prefs.getInt("period_type");
    period != null ? periodSliding = period : periodSliding = 0;
    setState(() {
      periodSliding;
    });
  }

  void savePM(bool? value) async {
    setState(() {
      withPM = !withPM;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("mark_type", withPM);
  }

  void getPM() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? mark = prefs.getBool("mark_type");
    mark != null ? withPM = mark : withPM = false;
    setState(() {
      withPM;
    });
  }

  @override
  void initState() {
    super.initState();
    getPM();
    getTheme();
    getPeriod();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Row(
            children: [
              // const SizedBox(
              //   width: 10,
              // ),
              // GestureDetector(
              //   onTap: () {
              //     Navigator.pop(context);
              //   },
              //   child: Icon(
              //     Icons.arrow_back_sharp,
              //     color: Theme.of(context).textTheme.displaySmall?.color,
              //     size: 30,
              //   ),
              // ),
              const Spacer(flex: 3,),
              Text(
                "Настройки",
                style: TextStyle(
                  color: Theme.of(context).textTheme.displaySmall?.color,
                  fontSize: 32,
                ),
              ),
              const Spacer(flex: 2,),
              const MoreMenu(canLeave: true)
            ],
          ),
          const SizedBox(
            height: 25,
          ),
          Center(
            child: CupertinoSlidingSegmentedControl(
              children: {
                0: Text("Стандартная\nтема",
                    style: TextStyle(
                        color: themeSliding == 0
                            ? Theme.of(context).textTheme.displaySmall?.color
                            : Theme.of(context).textTheme.displayLarge?.color,
                        fontSize: 16)),
                1: Text("Светлая\nтема",
                    style: TextStyle(
                        color: themeSliding == 1
                            ? Theme.of(context).textTheme.displaySmall?.color
                            : Theme.of(context).textTheme.displayLarge?.color,
                        fontSize: 16)),
                2: Text("Тёмная\nтема",
                    style: TextStyle(
                        color: themeSliding == 2
                            ? Theme.of(context).textTheme.displaySmall?.color
                            : Theme.of(context).textTheme.displayLarge?.color,
                        fontSize: 16)),
              },
              groupValue: themeSliding,
              onValueChanged: (int? index) {
                setState(() {
                  themeSliding = index;
                  saveTheme();
                });
                Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme(index!);
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              thumbColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          Center(
            child: CupertinoSlidingSegmentedControl(
              children: {
                0: Text("  Четверти ",
                    style: TextStyle(
                        color: periodSliding == 0
                            ? Theme.of(context).textTheme.displaySmall?.color
                            : Theme.of(context).textTheme.displayLarge?.color,
                        fontSize: 16)),
                1: Text("  Полугодия  ",
                    style: TextStyle(
                        color: periodSliding == 1
                            ? Theme.of(context).textTheme.displaySmall?.color
                            : Theme.of(context).textTheme.displayLarge?.color,
                        fontSize: 16)),
                2: Text("  Семестры ",
                    style: TextStyle(
                        color: periodSliding == 2
                            ? Theme.of(context).textTheme.displaySmall?.color
                            : Theme.of(context).textTheme.displayLarge?.color,
                        fontSize: 16)),
              },
              groupValue: periodSliding,
              onValueChanged: (int? index) {
                setState(() {
                  periodSliding = index;
                  savePeriod();
                  widget.popoverButton;
                });
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              thumbColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          Row(
            children: [
              const Spacer(),
              Checkbox(
                  activeColor: Theme.of(context).colorScheme.secondary,
                  side: const BorderSide(color: Colors.grey),
                  value: withPM,
                  onChanged: (value) => savePM(value)),
              Text(
                'Использовать + и - для оценок',
                style: TextStyle(
                    color: Theme.of(context).textTheme.displaySmall?.color,
                    fontSize: 16),
              ),
              const Spacer()
            ],
          ),
          const Spacer(),
          Text(
            'Связаться с разработчиком',
            style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.displaySmall?.color),
          ),
          const SizedBox(height: 15),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyIconButton(path: 'lib/images/telegram_icon.png', type: 0),
              SizedBox(width: 100),
              MyIconButton(path: 'lib/images/mail_icon.png', type: 1)
            ],
          ),
          const SizedBox(height: 15),
        ],
      )),
    );
  }
}
