import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ecalculator/components/icon_button.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/components/popover_button.dart';
import 'package:ecalculator/components/theme_provider.dart';
import 'package:ecalculator/pages/login_page.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';
import 'package:ecalculator/storage/settings_storage.dart';
import 'package:provider/provider.dart';

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
  final settings = SettingsStorage();

  void saveTheme() async {
    await settings.writeInt("theme", themeSliding!);
  }

  void getTheme() async {
    int? theme = await settings.readInt("theme");
    theme != null ? themeSliding = theme : themeSliding = 0;
    if (mounted) setState(() {});
  }

  void savePeriod() async {
    await settings.writeInt("period_type", periodSliding!);
  }

  void getPeriod() async {
    int? period = await settings.readInt("period_type");
    period != null ? periodSliding = period : periodSliding = 0;
    if (mounted) setState(() {});
  }

  void savePM(bool? value) async {
    setState(() {
      withPM = !withPM;
    });
    await settings.writeBool("mark_type", withPM);
  }

  void getPM() async {
    bool? mark = await settings.readBool("mark_type");
    mark != null ? withPM = mark : withPM = false;
    if (mounted) setState(() {});
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
    void leave() {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              content: SizedBox(
                height: 90,
                child: Column(
                  children: [
                    Text(
                      'Вы уверены, что хотите выйти из аккаунта?',
                      style: TextStyle(
                          fontSize: 16,
                          color:
                              Theme.of(context).textTheme.displayLarge?.color),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            try {
                              await eschoolSession.logout();
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            } on Object {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Не удалось очистить безопасное хранилище. Повторите выход.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text('Да',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.color)),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Text('Отмена',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.color))),
                      ],
                    )
                  ],
                ),
              ),
            );
          });
    }

    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Row(
            children: [
              const Spacer(
                flex: 3,
              ),
              Text(
                "Настройки",
                style: TextStyle(
                  color: Theme.of(context).textTheme.displaySmall?.color,
                  fontSize: 32,
                ),
              ),
              const Spacer(
                flex: 2,
              ),
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
                    fontSize: 18),
              ),
              const Spacer()
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          GestureDetector(
            onTap: leave,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 100.0),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10.0)),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: const Center(
                  child: Text(
                    'Сбросить настройки',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                )),
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
