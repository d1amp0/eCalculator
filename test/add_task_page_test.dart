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

  testWidgets('submit resolves to distinct semantic colors in every theme', (
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
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(_submitFinder);
      expect(button.onPressed, isNull);
      final disabledColors = _renderedSubmitColors(tester);
      expect(disabledColors.background.a, closeTo(0.12, 0.01));
      expect(disabledColors.foreground.a, closeTo(0.38, 0.01));
      expect(
        disabledColors.background.withValues(alpha: 1),
        theme.colorScheme.onSurface.withValues(alpha: 1),
      );
      expect(
        disabledColors.foreground.withValues(alpha: 1),
        theme.colorScheme.onSurface.withValues(alpha: 1),
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

      final enabledButton = tester.widget<FilledButton>(_submitFinder);
      expect(enabledButton.onPressed, isNotNull);
      final enabledColors = _renderedSubmitColors(tester);
      expect(enabledColors.background, theme.colorScheme.secondaryContainer);
      expect(enabledColors.foreground, theme.colorScheme.onSecondaryContainer);
      expect(
        _contrastRatio(enabledColors.background, enabledColors.foreground),
        greaterThanOrEqualTo(4.5),
      );
      expect(enabledColors.background, isNot(theme.scaffoldBackgroundColor));
      expect(enabledColors.background, isNot(disabledColors.background));
      expect(tester.takeException(), isNull);
    }
  });
}

Finder get _submitFinder => find.byKey(const ValueKey('add-task-submit'));

({Color background, Color foreground}) _renderedSubmitColors(
  WidgetTester tester,
) {
  final material = tester.widget<Material>(
    find.descendant(of: _submitFinder, matching: find.byType(Material)),
  );
  final foreground = DefaultTextStyle.of(
    tester.element(find.text('Добавить')),
  ).style.color;
  return (background: material.color!, foreground: foreground!);
}

double _contrastRatio(Color first, Color second) {
  final lighter =
      first.computeLuminance() > second.computeLuminance() ? first : second;
  final darker = identical(lighter, first) ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
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
