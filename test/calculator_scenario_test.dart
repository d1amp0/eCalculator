import 'package:ecalculator/domain/calculator_scenario.dart';
import 'package:ecalculator/domain/student_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const first = StudentMark(
    id: 'first',
    value: 3,
    weight: 2,
    date: '2026-01-01',
  );
  const second = StudentMark(
    id: 'second',
    value: 5,
    weight: 1,
    date: '2026-01-02',
  );

  test('has no changes and preserves the original weighted average', () {
    final scenario = CalculatorScenario(const [first, second]);

    expect(scenario.hasChanges, isFalse);
    expect(scenario.originalAverage, closeTo(11 / 3, 0.0001));
    expect(scenario.predictedAverage, closeTo(11 / 3, 0.0001));
  });

  test('adds a weighted mark', () {
    final scenario = CalculatorScenario(const [first, second]);

    scenario.add(value: 5, weight: 2);

    expect(scenario.predictedAverage, closeTo(21 / 5, 0.0001));
    expect(scenario.operations.single.type, ScenarioOperationType.add);
  });

  test('edits both value and weight without mutating the source mark', () {
    final scenario = CalculatorScenario(const [first, second]);

    scenario.edit('first', value: 4, weight: 1.5);

    expect(first.value, 3);
    expect(first.weight, 2);
    expect(scenario.predictedAverage, closeTo(11 / 2.5, 0.0001));
    expect(scenario.marks.first.isEdited, isTrue);
  });

  test('saving unchanged source values creates no edit operation', () {
    final scenario = CalculatorScenario(const [first, second]);

    scenario.edit('first', value: first.value, weight: first.weight);

    expect(scenario.hasChanges, isFalse);
    expect(scenario.operations, isEmpty);
  });

  test('edits an added mark in place without creating another mark', () {
    final scenario = CalculatorScenario(const [first]);
    scenario.add(value: 5, weight: 2);
    final id = scenario.marks.last.mark.id;

    scenario.edit(id, value: 4, weight: 0.5);

    expect(scenario.marks, hasLength(2));
    expect(scenario.marks.last.mark.id, id);
    expect(scenario.marks.last.mark.value, 4);
    expect(scenario.marks.last.mark.weight, 0.5);
    expect(scenario.operations, hasLength(1));
    expect(scenario.operations.single.type, ScenarioOperationType.add);
  });

  test('excludes and restores a source mark', () {
    final scenario = CalculatorScenario(const [first, second]);

    scenario.exclude('second');
    expect(scenario.predictedAverage, 3);
    expect(scenario.marks.last.isExcluded, isTrue);

    scenario.restore('second');
    expect(scenario.predictedAverage, closeTo(11 / 3, 0.0001));
    expect(scenario.hasChanges, isFalse);
  });

  test('combines add, edit, and exclude operations', () {
    const third = StudentMark(
      id: 'third',
      value: 4,
      weight: 1,
      date: '2026-01-03',
    );
    final scenario = CalculatorScenario(const [first, second, third]);

    scenario.edit('first', value: 4.2, weight: 1.5);
    scenario.exclude('second');
    scenario.add(value: 3.8, weight: 2);

    expect(scenario.operations, hasLength(3));
    expect(scenario.predictedAverage, closeTo(17.9 / 4.5, 0.0001));
  });

  test('reset clears every temporary operation', () {
    final scenario = CalculatorScenario(const [first, second]);
    scenario.edit('first', value: 4, weight: 1);
    scenario.exclude('second');
    scenario.add(value: 5, weight: 2);

    scenario.reset();

    expect(scenario.hasChanges, isFalse);
    expect(scenario.marks, hasLength(2));
    expect(scenario.predictedAverage, scenario.originalAverage);
  });

  test('supports plus/minus values and an empty source list', () {
    final empty = CalculatorScenario(const []);
    expect(empty.originalAverage, isNull);

    empty.add(value: 4.2, weight: 1.5);
    empty.add(value: 3.8, weight: 0.5);

    expect(empty.predictedAverage, closeTo(4.1, 0.0001));
  });
}
