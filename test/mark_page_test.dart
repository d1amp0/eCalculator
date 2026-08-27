import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/pages/mark_page.dart';
import 'package:ecalculator/other/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const marks = [
    StudentMark(
      id: 'real-1',
      value: 3,
      weight: 1,
      date: '2026-01-01',
    ),
  ];

  setUp(() => SharedPreferences.setMockInitialValues({'mark_type': true}));

  testWidgets('tapping a real mark opens edit and exclude actions',
      (tester) async {
    await tester
        .pumpWidget(_app(const MarkPage(name: 'Алгебра', markList: marks)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mark-real-1')));
    await tester.pumpAndSettle();

    expect(find.text('Изменить оценку'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-mark-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('exclude-mark-button')), findsOneWidget);
  });

  testWidgets('adding a mark updates preview and reset restores the original',
      (tester) async {
    await tester
        .pumpWidget(_app(const MarkPage(name: 'Алгебра', markList: marks)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-mark-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-mark-button')));
    await tester.pumpAndSettle();

    expect(find.text('3.00'), findsOneWidget);
    expect(find.text('4.00'), findsOneWidget);
    expect(find.byKey(const ValueKey('scenario-area')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reset-scenario-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('scenario-area')), findsNothing);
    expect(find.text('3.00'), findsOneWidget);
  });

  testWidgets('calculator remains usable on a narrow screen in every theme',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final theme in [defaultMode, lightMode, darkMode]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const MarkPage(
            name: 'Английский язык (углублённый уровень)',
            markList: marks,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('add-mark-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _app(Widget home) => MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: home,
    );
