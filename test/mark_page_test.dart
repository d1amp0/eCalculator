import 'package:ecalculator/components/mark_button.dart';
import 'package:ecalculator/domain/calculator_scenario.dart';
import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/other/app_theme_colors.dart';
import 'package:ecalculator/other/themes.dart';
import 'package:ecalculator/pages/mark_page.dart';
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
  const geometryMarks = [
    StudentMark(
      id: 'left',
      value: 5,
      weight: 1,
      date: '2026-01-01',
    ),
    StudentMark(
      id: 'middle',
      value: 3,
      weight: 2,
      date: '2026-01-02',
    ),
    StudentMark(
      id: 'right',
      value: 4.2,
      weight: 1.5,
      date: '2026-01-03',
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

  testWidgets('saving editor disposes its controller after sheet teardown',
      (tester) async {
    await tester
        .pumpWidget(_app(const MarkPage(name: 'Алгебра', markList: marks)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('mark-real-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('mark-weight-field')),
      '1.5',
    );
    await tester.tap(find.byKey(const ValueKey('save-mark-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('mark-weight-field')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling editor disposes its controller without exceptions',
      (tester) async {
    await tester
        .pumpWidget(_app(const MarkPage(name: 'Алгебра', markList: marks)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-mark-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('mark-weight-field')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('cancel-mark-editor-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const ValueKey('mark-weight-field')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all scenario states use identical tile geometry',
      (tester) async {
    const source = StudentMark(
      id: 'source',
      value: 3,
      weight: 2,
      date: '2026-01-01',
    );
    const edited = StudentMark(
      id: 'edited',
      value: 4,
      weight: 2,
      date: '2026-01-01',
    );
    const added = StudentMark(
      id: 'added',
      value: 5,
      weight: 1.5,
      date: 'Сценарий',
    );
    const excluded = StudentMark(
      id: 'excluded',
      value: 2,
      weight: 1,
      date: '2026-01-03',
    );

    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Wrap(
            children: [
              MarkButton(
                item: const ScenarioMark(mark: source),
                onPressed: () {},
              ),
              MarkButton(
                item: const ScenarioMark(mark: edited, original: source),
                onPressed: () {},
              ),
              MarkButton(
                item: const ScenarioMark(mark: added, isAdded: true),
                onPressed: () {},
              ),
              MarkButton(
                item: const ScenarioMark(mark: excluded, isExcluded: true),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    for (final id in ['source', 'edited', 'added', 'excluded']) {
      expect(
        tester.getSize(find.byKey(ValueKey('mark-tile-$id'))),
        MarkButton.tileSize,
      );
    }
  });

  testWidgets('edit exclude and add do not reflow existing mark tiles',
      (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(const MarkPage(name: 'Алгебра', markList: geometryMarks)),
    );
    await tester.pumpAndSettle();

    final initialLeftSize = _tileRect(tester, 'left').size;
    final initialMiddleOffset = _relativeTileOffset(tester, 'middle', 'left');
    final initialRightOffset = _relativeTileOffset(tester, 'right', 'left');

    await tester.tap(find.byKey(const ValueKey('mark-middle')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '4'));
    await tester.tap(find.byKey(const ValueKey('save-mark-button')));
    await tester.pumpAndSettle();

    expect(_tileRect(tester, 'left').size, initialLeftSize);
    expect(_relativeTileOffset(tester, 'middle', 'left'), initialMiddleOffset);
    expect(_relativeTileOffset(tester, 'right', 'left'), initialRightOffset);

    await tester.tap(find.byKey(const ValueKey('mark-middle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exclude-mark-button')));
    await tester.pumpAndSettle();

    expect(_tileRect(tester, 'left').size, initialLeftSize);
    expect(_relativeTileOffset(tester, 'middle', 'left'), initialMiddleOffset);
    expect(_relativeTileOffset(tester, 'right', 'left'), initialRightOffset);

    await tester.tap(find.byKey(const ValueKey('add-mark-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-mark-button')));
    await tester.pumpAndSettle();

    expect(_tileRect(tester, 'left').size, initialLeftSize);
    expect(_relativeTileOffset(tester, 'middle', 'left'), initialMiddleOffset);
    expect(_relativeTileOffset(tester, 'right', 'left'), initialRightOffset);
    expect(
      tester.getSize(find.byKey(const ValueKey('mark-tile-scenario-1'))),
      MarkButton.tileSize,
    );
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
          home: MarkPage(
            key: ValueKey(theme.scaffoldBackgroundColor),
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

  testWidgets('calculator surfaces use semantic foregrounds in every theme',
      (tester) async {
    for (final theme in [defaultMode, lightMode, darkMode]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: MarkPage(
            key: ValueKey(theme.scaffoldBackgroundColor),
            name: 'Алгебра',
            markList: marks,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldForeground =
          theme.extension<AppThemeColors>()!.scaffoldForeground;
      expect(_text(tester, 'marks-heading').style!.color, scaffoldForeground);
      expect(
        _text(tester, 'result-label').style!.color,
        theme.colorScheme.onSecondaryContainer,
      );
      expect(
        _text(tester, 'original-average').style!.color,
        theme.colorScheme.onSecondaryContainer,
      );
      expect(
        _text(tester, 'result-caption').style!.color,
        theme.colorScheme.onSecondaryContainer,
      );
      expect(
        _text(tester, 'mark-weight-real-1').style!.color,
        theme.colorScheme.onSurface,
      );

      await tester.tap(find.byKey(const ValueKey('add-mark-button')));
      await tester.pumpAndSettle();
      expect(
        _text(tester, 'mark-editor-title').style!.color,
        theme.colorScheme.onSurface,
      );
      await tester.tap(find.byKey(const ValueKey('save-mark-button')));
      await tester.pumpAndSettle();

      expect(
        _text(tester, 'scenario-heading').style!.color,
        theme.colorScheme.onSurface,
      );
      expect(
        _text(tester, 'average-delta').style!.color,
        theme.colorScheme.onSecondaryContainer,
      );
      final arrow = find.byIcon(Icons.arrow_forward);
      expect(IconTheme.of(tester.element(arrow)).color,
          theme.colorScheme.onSecondaryContainer);
      expect(tester.takeException(), isNull);
    }
  });
}

Rect _tileRect(WidgetTester tester, String id) =>
    tester.getRect(find.byKey(ValueKey('mark-tile-$id')));

Offset _relativeTileOffset(
  WidgetTester tester,
  String id,
  String originId,
) =>
    _tileRect(tester, id).topLeft - _tileRect(tester, originId).topLeft;

Text _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key)));

Widget _app(Widget home) => MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: home,
    );
