import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/components/popover_button.dart';
import 'package:ecalculator/other/themes.dart';
import 'package:ecalculator/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom navigation shows three labels and changes selection',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final theme in [defaultMode, lightMode, darkMode]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: MainPage(
            key: ValueKey(theme.scaffoldBackgroundColor),
            pages: const [
              Center(child: Text('Marks page')),
              Center(child: Text('Homework page')),
              Center(child: Text('Settings page')),
            ],
          ),
        ),
      );

      expect(find.text('Калькулятор'), findsOneWidget);
      expect(find.text('Оценки'), findsNothing);
      expect(find.text('Задания'), findsOneWidget);
      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Marks page'), findsOneWidget);
      var navigation = tester.widget<NavigationBar>(
        find.byKey(const ValueKey('main-navigation')),
      );
      expect(navigation.selectedIndex, 0);
      expect(
        navigation.labelBehavior,
        NavigationDestinationLabelBehavior.alwaysShow,
      );
      final navigationTheme = NavigationBarTheme.of(
        tester.element(find.byKey(const ValueKey('main-navigation'))),
      );
      final effectiveScheme = Theme.of(
        tester.element(find.byKey(const ValueKey('main-navigation'))),
      ).colorScheme;
      expect(
        navigationTheme.indicatorColor,
        effectiveScheme.secondaryContainer,
      );
      expect(
        navigationTheme.iconTheme!.resolve({WidgetState.selected})!.color,
        effectiveScheme.onSecondaryContainer,
      );

      await tester.tap(find.text('Задания'));
      await tester.pumpAndSettle();
      navigation = tester.widget<NavigationBar>(
        find.byKey(const ValueKey('main-navigation')),
      );
      expect(navigation.selectedIndex, 1);
      expect(find.text('Homework page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('entire year and period selector surfaces are tappable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final year = TextEditingController(text: '2026/2027');
    final period = TextEditingController(text: 'Очень длинный учебный период');
    addTearDown(year.dispose);
    addTearDown(period.dispose);
    var selections = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: lightMode,
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: PopoverButton(
                  startText: 'Учебный год',
                  controller: year,
                  checkControllers: (_) => selections++,
                  optionsLoader: () async => ['2025/2026', '2026/2027'],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PopoverButton(
                  startText: 'Учебный период',
                  controller: period,
                  checkControllers: (_) => selections++,
                  optionsLoader: () async => [
                    '1 четверть',
                    'Очень длинный учебный период',
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    Future<void> expectSurfaceOpens(String selector) async {
      final finder = find.byKey(ValueKey('$selector-selector'));
      final rect = tester.getRect(finder);
      final points = [
        Offset(rect.left + 2, rect.center.dy),
        rect.center,
        Offset(rect.right - 2, rect.center.dy),
      ];
      for (final point in points) {
        await tester.tapAt(point);
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('$selector-selector-sheet')),
          findsOneWidget,
        );
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
      }

      await tester.tapAt(Offset(rect.center.dx, rect.bottom + 4));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('$selector-selector-sheet')),
        findsNothing,
      );
    }

    await expectSurfaceOpens('year');
    await expectSurfaceOpens('period');
    expect(selections, 0);

    await tester.tapAt(
      tester.getRect(find.byKey(const ValueKey('year-selector'))).center,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
      const ValueKey('year-selector-option-2025/2026'),
    ));
    await tester.pumpAndSettle();
    expect(year.text, '2025/2026');
    expect(selections, 1);

    await tester.tapAt(
      tester.getRect(find.byKey(const ValueKey('period-selector'))).center,
    );
    await tester.pumpAndSettle();
    expect(find.text('1 четверть'), findsOneWidget);
    await tester.tap(find.byKey(
      const ValueKey('period-selector-option-1 четверть'),
    ));
    await tester.pumpAndSettle();

    expect(period.text, '1 четверть');
    expect(selections, 2);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('period-selector-value')),
          )
          .overflow,
      TextOverflow.ellipsis,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('overflow menu opens About and keeps logout wired',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: darkMode,
        home: Scaffold(
          appBar: AppBar(actions: const [MoreMenu(canLeave: true)]),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('more-menu-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('about-menu-item')), findsOneWidget);
    expect(find.byKey(const ValueKey('logout-menu-item')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('about-menu-item')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('about-dialog')), findsOneWidget);
    expect(find.text('eCalculator'), findsOneWidget);
    expect(find.textContaining('Неофициальное приложение'), findsOneWidget);
    expect(find.textContaining('защищённом хранилище ОС'), findsOneWidget);
    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('about-logo')),
    );
    expect((logo.image as AssetImage).assetName, 'lib/images/icon_black.png');
    expect((logo.image as AssetImage).assetName, isNot(contains('new_year')));

    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightMode,
        home: Scaffold(
          appBar: AppBar(actions: const [MoreMenu(canLeave: true)]),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('more-menu-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('about-menu-item')));
    await tester.pumpAndSettle();
    final lightLogo = tester.widget<Image>(
      find.byKey(const ValueKey('about-logo')),
    );
    expect(
      (lightLogo.image as AssetImage).assetName,
      'lib/images/icon_new.png',
    );
    expect(
      (lightLogo.image as AssetImage).assetName,
      isNot(contains('new_year')),
    );
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('more-menu-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('logout-menu-item')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Выйти из'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
