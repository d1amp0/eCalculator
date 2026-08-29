import 'package:flutter/material.dart';
import 'package:ecalculator/pages/homework_page.dart';
import 'package:ecalculator/pages/marks_page.dart';
import 'package:ecalculator/pages/settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.pages});

  final List<Widget>? pages;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const List<Widget> defaultPages = [
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _pageIndex,
        children: widget.pages ?? defaultPages,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: scheme.surface,
          indicatorColor: scheme.secondaryContainer,
          surfaceTintColor: Colors.transparent,
          elevation: 3,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: states.contains(WidgetState.selected)
                      ? scheme.onSecondaryContainer
                      : scheme.onSurfaceVariant,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
              size: 24,
            ),
          ),
        ),
        child: NavigationBar(
          key: const ValueKey('main-navigation'),
          onDestinationSelected: _onNavTap,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _pageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              selectedIcon: Icon(Icons.calculate),
              label: 'Калькулятор',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist_rounded),
              label: 'Задания',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }
}
