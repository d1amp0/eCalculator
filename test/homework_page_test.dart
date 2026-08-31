import 'dart:async';

import 'package:ecalculator/models/homework_item.dart';
import 'package:ecalculator/other/database_helper.dart';
import 'package:ecalculator/other/task.dart';
import 'package:ecalculator/other/themes.dart';
import 'package:ecalculator/pages/homework_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  testWidgets('shows local and remote homework when both sources succeed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          localItemsLoader: () async => [_item('Алгебра', today, local: true)],
          remoteItemsLoader: () async => [_item('Физика', today)],
          now: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Алгебра'), findsOneWidget);
    expect(find.text('Физика'), findsOneWidget);
  });

  testWidgets('shows local homework while eSchool is still loading', (
    tester,
  ) async {
    final local = Completer<List<HomeworkItem>>();
    final remote = Completer<List<HomeworkItem>>();
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          localItemsLoader: () => local.future,
          remoteItemsLoader: () => remote.future,
          now: () => today,
        ),
      ),
    );

    local.complete([_item('Алгебра', today, local: true, localId: 1)]);
    await tester.pump();

    expect(find.text('Алгебра'), findsOneWidget);
    expect(find.byKey(const ValueKey('homework-loading')), findsNothing);

    remote.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('keeps a task added while initial eSchool load is pending', (
    tester,
  ) async {
    final local = Completer<List<HomeworkItem>>();
    final remote = Completer<List<HomeworkItem>>();
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          localItemsLoader: () => local.future,
          remoteItemsLoader: () => remote.future,
          saveTask: (_) async => 42,
          taskDatePicker: (_) async => today,
          now: () => today,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('add-task-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('task-subject-field')),
      'Физика',
    );
    await tester.enterText(
      find.byKey(const ValueKey('task-text-field')),
      'Решить задачу',
    );
    await tester.tap(find.byKey(const ValueKey('task-date-control')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-task-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Физика'), findsOneWidget);

    local.complete([_item('Алгебра', today, local: true, localId: 41)]);
    await tester.pumpAndSettle();

    expect(find.text('Алгебра'), findsOneWidget);
    expect(find.text('Физика'), findsOneWidget);

    remote.complete([]);
    await tester.pumpAndSettle();

    expect(find.text('Алгебра'), findsOneWidget);
    expect(find.text('Физика'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not resurrect a task deleted while eSchool is loading', (
    tester,
  ) async {
    final local = Completer<List<HomeworkItem>>();
    final remote = Completer<List<HomeworkItem>>();
    final algebra = _item('Алгебра', today, local: true, localId: 1);
    final physics = _item('Физика', today, local: true, localId: 2);
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          localItemsLoader: () => local.future,
          remoteItemsLoader: () => remote.future,
          deleteTask: (_) async {},
          now: () => today,
        ),
      ),
    );

    local.complete([algebra, physics]);
    await tester.pump();
    expect(find.text('Алгебра'), findsOneWidget);
    expect(find.text('Физика'), findsOneWidget);

    await tester.tap(find.text('Алгебра'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-task')));
    await tester.pumpAndSettle();

    remote.complete([]);
    await tester.pumpAndSettle();

    expect(find.text('Алгебра'), findsNothing);
    expect(find.text('Физика'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps local homework visible when eSchool loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          localItemsLoader: () async => [_item('Алгебра', today, local: true)],
          remoteItemsLoader: () async => throw StateError('offline'),
          now: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Алгебра'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('remote-homework-warning')),
      findsOneWidget,
    );
    expect(find.text('Не удалось загрузить задания'), findsNothing);
  });

  testWidgets('shows the full error when no local homework can be shown', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          localItemsLoader: () async => [],
          remoteItemsLoader: () async => throw StateError('offline'),
          now: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить задания'), findsOneWidget);
  });

  testWidgets('keeps remote homework visible when local loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          localItemsLoader: () async => throw StateError('database offline'),
          remoteItemsLoader: () async => [_item('Физика', today)],
          now: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Физика'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('local-homework-warning')),
      findsOneWidget,
    );
    expect(find.text('Не удалось загрузить задания'), findsNothing);
  });

  testWidgets('remote retry adds remote homework once and preserves local', (
    tester,
  ) async {
    var remoteAttempts = 0;
    await tester.pumpWidget(
      _app(
        HomeworkPage(
          localItemsLoader: () async => [_item('Алгебра', today, local: true)],
          remoteItemsLoader: () async {
            remoteAttempts++;
            if (remoteAttempts == 1) throw StateError('offline');
            return [_item('Физика', today)];
          },
          now: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('remote-homework-retry')));
    await tester.pumpAndSettle();

    expect(remoteAttempts, 2);
    expect(find.text('Алгебра'), findsOneWidget);
    expect(find.text('Физика'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Алгебра')).dy,
      lessThan(tester.getTopLeft(find.text('Физика')).dy),
    );
    expect(
      find.byKey(const ValueKey('remote-homework-warning')),
      findsNothing,
    );
  });

  testWidgets('deletes one duplicate-text local task by its SQLite id', (
    tester,
  ) async {
    final storedIds = <int>{1, 2};
    final algebra = _item(
      'Алгебра',
      today,
      local: true,
      localId: 1,
      content: 'Read §12',
    );
    final physics = _item(
      'Физика',
      today,
      local: true,
      localId: 2,
      content: 'Read §12',
    );

    await tester.pumpWidget(
      _app(
        HomeworkPage(
          localItemsLoader: () async => [algebra, physics],
          remoteItemsLoader: () async => [],
          deleteTask: (item) async => storedIds.remove(item.localId),
          now: () => today,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Алгебра'), findsOneWidget);
    expect(find.text('Физика'), findsOneWidget);

    await tester.tap(find.text('Алгебра'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-task')));
    await tester.pumpAndSettle();

    expect(storedIds, {2});
    expect(find.text('Алгебра'), findsNothing);
    expect(find.text('Физика'), findsOneWidget);
  });

  testWidgets(
    'production cleanup removes only the expired duplicate-text SQLite row',
    (tester) async {
      sqfliteFfiInit();
      late Database database;
      late DatabaseHelper helper;
      await tester.runAsync(() async {
        database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
        await database.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY,
            subject TEXT,
            info TEXT,
            time INTEGER
          )
        ''');
        helper = DatabaseHelper.withDatabase(database);
        const duplicateInfo = 'Read synthetic chapter';
        await helper.add(
          Task(
            id: 101,
            subject: 'Expired subject',
            info: duplicateInfo,
            time:
                today.subtract(const Duration(days: 8)).millisecondsSinceEpoch,
          ),
        );
        await helper.add(
          Task(
            id: 202,
            subject: 'Current subject',
            info: duplicateInfo,
            time: today.millisecondsSinceEpoch,
          ),
        );
      });
      addTearDown(database.close);
      const duplicateInfo = 'Read synthetic chapter';

      await tester.pumpWidget(
        _app(
          HomeworkPage(
            databaseHelper: helper,
            remoteItemsLoader: () async => [],
            now: () => today,
          ),
        ),
      );
      final remaining = await tester.runAsync<List<Task>>(() async {
        await (() async {
          while ((await helper.getTasks()).length != 1) {
            await Future<void>.delayed(const Duration(milliseconds: 1));
          }
        })()
            .timeout(const Duration(seconds: 5));
        return helper.getTasks();
      });
      await tester.pumpAndSettle();

      expect(remaining, hasLength(1));
      expect(remaining!.single.id, 202);
      expect(remaining.single.info, duplicateInfo);
      expect(find.text('Expired subject'), findsNothing);
      expect(find.text('Current subject'), findsOneWidget);
    },
  );
}

HomeworkItem _item(
  String subject,
  DateTime date, {
  bool local = false,
  int? localId,
  String content = '№412, 414, повторить правила',
}) {
  return HomeworkItem(
    subject: subject,
    content: content,
    preview: content,
    date: date,
    isLocal: local,
    localId: localId,
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
