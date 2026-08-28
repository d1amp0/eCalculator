import 'dart:async';

import 'package:ecalculator/other/task.dart';
import 'package:ecalculator/other/themes.dart';
import 'package:ecalculator/pages/add_task_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final selectedDate = DateTime(2026, 8, 30);

  testWidgets('submit stays visible and enables only with all fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        AddTaskPage(
          function: (_) {},
          saveTask: (_) async => null,
          datePicker: (_) async => selectedDate,
        ),
      ),
    );

    FilledButton button() => tester.widget(
          find.byKey(const ValueKey('add-task-submit')),
        );
    expect(button().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('task-subject-field')),
      'Алгебра',
    );
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('task-text-field')),
      'Решить №412',
    );
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('task-date-control')));
    await tester.pumpAndSettle();
    expect(find.text('30 августа 2026'), findsOneWidget);
    expect(button().onPressed, isNotNull);
  });

  testWidgets('successful creation saves and invokes callback only once', (
    tester,
  ) async {
    final saving = Completer<int?>();
    var saves = 0;
    var callbacks = 0;
    Task? savedTask;
    Task? createdTask;
    await tester.pumpWidget(
      _app(
        AddTaskPage(
          function: (task) {
            createdTask = task;
            callbacks++;
          },
          saveTask: (task) {
            saves++;
            savedTask = task;
            return saving.future;
          },
          datePicker: (_) async => selectedDate,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('task-subject-field')),
      'Алгебра',
    );
    await tester.enterText(
      find.byKey(const ValueKey('task-text-field')),
      'Решить №412',
    );
    await tester.tap(find.byKey(const ValueKey('task-date-control')));
    await tester.pumpAndSettle();

    final submit = find.byKey(const ValueKey('add-task-submit'));
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();
    expect(saves, 1);
    expect(callbacks, 0);

    saving.complete(27);
    await tester.pumpAndSettle();
    expect(callbacks, 1);
    expect(savedTask?.subject, 'Алгебра');
    expect(savedTask?.info, 'Решить №412');
    expect(createdTask?.id, 27);
  });

  testWidgets('long multiline input and keyboard do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        AddTaskPage(
          function: (_) {},
          saveTask: (_) async => null,
          datePicker: (_) async => selectedDate,
        ),
        theme: darkMode,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('task-text-field')));
    await tester.enterText(
      find.byKey(const ValueKey('task-text-field')),
      List.generate(20, (index) => 'Строка задания $index').join('\n'),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('add-task-form')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('add-task-form')),
      const Offset(0, -1000),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('add-task-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owned controllers dispose without exception', (tester) async {
    await tester.pumpWidget(
      _app(
        AddTaskPage(
          function: (_) {},
          saveTask: (_) async => null,
          datePicker: (_) async => selectedDate,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('task-subject-field')),
      'Физика',
    );
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('submit uses the default FilledButton colors in every theme', (
    tester,
  ) async {
    for (final theme in [defaultMode, lightMode, darkMode]) {
      await tester.pumpWidget(
        _app(
          AddTaskPage(
            key: ValueKey(theme.scaffoldBackgroundColor),
            function: (_) {},
            saveTask: (_) async => null,
            datePicker: (_) async => selectedDate,
          ),
          theme: theme,
        ),
      );

      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('add-task-submit')),
      );
      expect(button.style, isNull);
      expect(button.onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('task-subject-field')),
        'Алгебра',
      );
      await tester.enterText(
        find.byKey(const ValueKey('task-text-field')),
        'Решить №412',
      );
      await tester.tap(find.byKey(const ValueKey('task-date-control')));
      await tester.pumpAndSettle();

      final enabledButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('add-task-submit')),
      );
      expect(enabledButton.style, isNull);
      expect(enabledButton.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    }
  });
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
