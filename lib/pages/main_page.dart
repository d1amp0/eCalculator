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
  static const List<Widget> pageList = [
    MarksPage(),
    HomeworkPage(),
    SettingsPage(),
  ];
  int _pageIndex = 0;
  final PageController _controller = PageController();

  void _onNavTap(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _pageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: _onPageChanged,
        children: pageList,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
            backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
        child: NavigationBar(
          onDestinationSelected: _onNavTap,
          height: 50,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          indicatorColor: Theme.of(context).colorScheme.primary,
          selectedIndex: _pageIndex,
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
