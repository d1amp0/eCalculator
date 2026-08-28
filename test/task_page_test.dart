import 'package:ecalculator/models/homework_item.dart';
import 'package:ecalculator/other/themes.dart';
import 'package:ecalculator/pages/task_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('eSchool task scrolls and has no delete action', (tester) async {
    tester.view.physicalSize = const Size(320, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final item = _item(
      subject: 'Очень длинное название предмета углублённого уровня',
      content: List.generate(
        35,
        (index) => '<p>Длинная строка задания номер $index</p>',
      ).join(),
    );

    await tester.pumpWidget(
      _app(TaskPage(item: item, onDeleted: (_) {})),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.byKey(const ValueKey('task-page-title')),
    );
    expect(title.maxLines, 1);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(find.byKey(const ValueKey('delete-task')), findsNothing);
    await tester.drag(
      find.byKey(const ValueKey('task-details-list')),
      const Offset(0, -300),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('local delete executes storage and callback once', (
    tester,
  ) async {
    final item = _item(local: true);
    var deletes = 0;
    var callbacks = 0;
    await tester.pumpWidget(
      _app(
        TaskPage(
          item: item,
          onDeleted: (value) {
            expect(value, same(item));
            callbacks++;
          },
          deleteTask: (value) async {
            expect(value, same(item));
            deletes++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delete-task')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('delete-task')));
    await tester.pumpAndSettle();
    expect(deletes, 1);
    expect(callbacks, 1);
  });

  testWidgets('task details render without exception in all three themes', (
    tester,
  ) async {
    for (final theme in [defaultMode, lightMode, darkMode]) {
      await tester.pumpWidget(
        _app(
          TaskPage(
            key: ValueKey(theme.scaffoldBackgroundColor),
            item: _item(local: true),
            onDeleted: (_) {},
            deleteTask: (_) async {},
          ),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('task-html-content')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

HomeworkItem _item({
  String subject = 'Алгебра',
  String content = 'Решить №412',
  bool local = false,
}) {
  return HomeworkItem(
    subject: subject,
    content: content,
    preview: content,
    date: DateTime(2026, 8, 28),
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
