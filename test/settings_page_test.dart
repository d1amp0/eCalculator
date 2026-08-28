import 'package:ecalculator/components/theme_provider.dart';
import 'package:ecalculator/other/themes.dart';
import 'package:ecalculator/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows and persists Material theme and period choices', (
    tester,
  ) async {
    await tester.pumpWidget(_settingsApp());
    await tester.pumpAndSettle();

    expect(find.text('Стандартная'), findsOneWidget);
    expect(find.text('Светлая'), findsOneWidget);
    expect(find.text('Тёмная'), findsOneWidget);
    expect(find.text('Четверти'), findsOneWidget);
    expect(find.text('Полугодия'), findsOneWidget);
    expect(find.text('Семестры'), findsOneWidget);

    await tester.tap(find.text('Светлая'));
    await tester.pumpAndSettle();
    var preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('theme'), 1);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage)))
          .scaffoldBackgroundColor,
      lightMode.scaffoldBackgroundColor,
    );

    await tester.tap(find.text('Полугодия'));
    await tester.pumpAndSettle();
    preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('period_type'), 1);

    await tester.tap(find.text('Семестры'));
    await tester.pumpAndSettle();
    expect(preferences.getInt('period_type'), 2);
    await tester.tap(find.text('Четверти'));
    await tester.pumpAndSettle();
    expect(preferences.getInt('period_type'), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plus minus row is fully tappable and persists', (tester) async {
    await tester.pumpWidget(_settingsApp());
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('plus-minus-setting'));
    await tester.tapAt(tester.getRect(row).centerLeft + const Offset(12, 0));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('mark_type'), isTrue);
    expect(tester.widget<SwitchListTile>(row).value, isTrue);
  });

  testWidgets('short settings page scrolls, keeps logout, and drops contacts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_settingsApp(logout: () async {}));
    await tester.pumpAndSettle();

    expect(find.text('Связаться с разработчиком'), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
    final logout = find.byKey(const ValueKey('settings-logout'));
    await tester.scrollUntilVisible(logout, 120);
    await tester.tap(logout);
    await tester.pumpAndSettle();
    expect(find.text('Выйти из аккаунта?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings render on a short screen in all three themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (var index = 0; index < 3; index++) {
      SharedPreferences.setMockInitialValues({
        'theme': index,
        'period_type': index,
        'mark_type': index.isOdd,
      });
      await tester.pumpWidget(
        _settingsApp(themeIndex: index, textScale: 1.3),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('settings-list')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _settingsApp({
  int themeIndex = 0,
  Future<void> Function()? logout,
  double textScale = 1,
}) {
  return ChangeNotifierProvider(
    create: (_) => ThemeProvider(themeIndex),
    child: Consumer<ThemeProvider>(
      builder: (_, provider, __) => MaterialApp(
        theme: provider.themeData,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru')],
        home: SettingsPage(logout: logout),
      ),
    ),
  );
}
