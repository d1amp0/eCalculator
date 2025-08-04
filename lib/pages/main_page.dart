import 'package:flutter/material.dart';
import 'package:hello/pages/marks_page.dart';
import 'package:hello/pages/settings_page.dart';
import 'package:hello/pages/homework_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Widget> pageList = const [
    MarksPage(),
    HomeworkPage(),
    SettingsPage(),
  ];
  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: pageIndex,
        children: pageList,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            labelTextStyle: MaterialStateProperty.all(TextStyle(
                color: Theme.of(context).textTheme.displayLarge?.color),
            )
        ),
        child: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              pageIndex = index;
            });
          },
          height: 50,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          indicatorColor: Theme.of(context).colorScheme.primary,
          selectedIndex: pageIndex,
          destinations: <Widget>[
            NavigationDestination(
              icon: Icon(Icons.calculate, color: Theme.of(context).textTheme.displayLarge?.color, size: 20,),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.school, color: Theme.of(context).textTheme.displayLarge?.color, size: 20,),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings, color: Theme.of(context).textTheme.displayLarge?.color, size: 20,),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
