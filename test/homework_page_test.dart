import 'dart:async';

import 'package:ecalculator/models/homework_item.dart';
import 'package:ecalculator/other/themes.dart';
import 'package:ecalculator/pages/homework_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 8, 28);

  testWidgets('shows explicit loading and empty states', (tester) async {
    final completer = Completer<List<HomeworkItem>>();
    await tester.pumpWidget(
      _app(
        HomeworkPage(itemsLoader: () => completer.future, now: () => today),
      ),
    );
    expect(find.byKey(const ValueKey('homework-loading')), findsOneWidget);

    completer.complete([]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('homework-empty')), findsOneWidget);
    expect(find.text('Нет заданий'), findsOneWidget);
  });

  testWidgets('uses one list for many tasks and human date headers', (
    tester,
  ) async {
    final items = [
      for (var index = 0; index < 14; index++)
        _item('Алгебра $index', today, local: index.isEven),
      _item('История', today.add(const Duration(days: 1))),
      _item('Физика', DateTime(2026, 8, 30)),
    ];
    await tester.pumpWidget(
      _app(HomeworkPage(itemsLoader: () async => items, now: () => today)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Завтра'), 300);
    expect(find.text('Завтра'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('30 августа'), 300);
    expect(find.text('30 августа'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('homework-task-13')),
      -300,
    );
    expect(find.byKey(const ValueKey('homework-task-13')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long tile content ellipsizes and full tile is tappable', (
    tester,
  ) async {
    HomeworkItem? tapped;
    final item = HomeworkItem(
      subject: 'Очень длинное название предмета углублённого уровня',
      content: 'Длинное задание',
      preview: List.filled(40, 'повторить').join(' '),
      date: today,
      isLocal: true,
    );
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          itemsLoader: () async => [item],
          onItemTap: (value) => tapped = value,
          now: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final texts = tester.widgetList<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('homework-task-0')),
        matching: find.byType(Text),
      ),
    );
    expect(texts.any((text) => text.maxLines == 1), isTrue);
    expect(texts.any((text) => text.maxLines == 2), isTrue);
    await tester.tap(find.byKey(const ValueKey('homework-task-0')));
    expect(tapped, same(item));
  });

  testWidgets('local and eSchool tasks have distinct semantic icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          itemsLoader: () async => [
            _item('Локальное', today, local: true),
            _item('eSchool', today),
          ],
          now: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    expect(find.text('ЛОКАЛЬНОЕ'), findsNothing);
    expect(find.text('ESCHOOL'), findsNothing);
  });

  testWidgets('narrow short homework renders in all three themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final theme in [defaultMode, lightMode, darkMode]) {
      await tester.pumpWidget(
        _app(
          HomeworkPage(
            key: ValueKey(theme.scaffoldBackgroundColor),
            itemsLoader: () async => [
              _item('Очень длинный предмет', today, local: true),
            ],
            now: () => today,
          ),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

HomeworkItem _item(String subject, DateTime date, {bool local = false}) {
  return HomeworkItem(
    subject: subject,
    content: '№412, 414, повторить правила',
    preview: '№412, 414, повторить правила',
    date: date,
    isLocal: local,
  );
}

Widget _app(Widget home, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? lightMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru')],
      home: home,
    );
