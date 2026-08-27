import 'package:flutter/material.dart';
import 'package:ecalculator/pages/homework_page.dart';
import 'package:ecalculator/pages/marks_page.dart';
import 'package:ecalculator/pages/settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const List<Widget> pageList = [
    MarksPage(),
    HomeworkPage(),
    SettingsPage(),
  ];
  int _pageIndex = 0;

  void _onNavTap(int index) {
    setState(() => _pageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: IndexedStack(index: _pageIndex, children: pageList),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          // indicatorShape: const CircleBorder(),
          indicatorColor: Colors.transparent,
          overlayColor: WidgetStateProperty.resolveWith<Color>(
            (_) => Colors.transparent,
          ),
        ),
        child: NavigationBar(
          onDestinationSelected: _onNavTap,
          height: 50,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          indicatorColor: Colors.transparent,
          selectedIndex: _pageIndex,
          destinations: <Widget>[
            NavigationDestination(
              icon: Icon(
                Icons.calculate,
                color: Theme.of(context).textTheme.displayLarge?.color,
                size: 24,
              ),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.school,
                color: Theme.of(context).textTheme.displayLarge?.color,
                size: 24,
              ),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).textTheme.displayLarge?.color,
                size: 24,
              ),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
