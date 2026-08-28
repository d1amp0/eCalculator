import 'dart:async';

import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/pages/marks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('latest marks request wins when an older request finishes last',
      (tester) async {
    final a = Completer<SubjectMarks>();
    final b = Completer<SubjectMarks>();
    final requested = <String>[];

    await tester.pumpWidget(
      _raceApp(
        marksLoader: (periodId) {
          requested.add(periodId);
          return periodId == 'A' ? a.future : b.future;
        },
      ),
    );
    await tester.pump();
    expect(requested, ['A']);

    await _selectYearB(tester);
    expect(requested, ['A', 'B']);

    b.complete(_marks('B subject', 'b'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('B subject'), findsOneWidget);

    a.complete(_marks('A subject', 'a'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('B subject'), findsOneWidget);
    expect(find.text('A subject'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale marks failure cannot replace newer successful data',
      (tester) async {
    final a = Completer<SubjectMarks>();
    final b = Completer<SubjectMarks>();

    await tester.pumpWidget(
      _raceApp(
        marksLoader: (periodId) => periodId == 'A' ? a.future : b.future,
      ),
    );
    await tester.pump();
    await _selectYearB(tester);

    b.complete(_marks('B subject', 'b'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('B subject'), findsOneWidget);

    a.completeError(StateError('stale A failure'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('B subject'), findsOneWidget);
    expect(find.text('Не удалось загрузить оценки.'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _selectYearB(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('year-selector')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.byKey(const ValueKey('year-selector-option-B')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Widget _raceApp({
  required Future<SubjectMarks> Function(String periodId) marksLoader,
}) {
  return MaterialApp(
    home: MarksPage(
      initialYear: 'A',
      initialPeriod: 'P',
      yearOptionsLoader: () async => const ['A', 'B'],
      periodOptionsLoader: () async => const ['P'],
      periodIdLoader: (selection) async =>
          selection.startsWith('A') ? 'A' : 'B',
      marksLoader: marksLoader,
    ),
  );
}

SubjectMarks _marks(String subject, String id) => {
      subject: [
        StudentMark(
          id: id,
          value: 5,
          weight: 1,
          date: '2026-01-01',
        ),
      ],
    };
