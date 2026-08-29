import 'package:ecalculator/components/mark_button.dart';
import 'package:ecalculator/domain/calculator_scenario.dart';
import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/other/mark_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plus and minus marks stay in their base grade family', () {
    expect(markGradeFamily(5), 5);
    expect(markGradeFamily(4.8), 5);
    expect(markGradeFamily(4), 4);
    expect(markGradeFamily(4.2), 4);
    expect(markGradeFamily(3.8), 4);
    expect(markGradeFamily(3.2), 3);
  });

  test('grade colors are consistent in light and dark schemes', () {
    final light = ColorScheme.fromSeed(seedColor: Colors.purple);
    final dark = ColorScheme.fromSeed(
      seedColor: Colors.purple,
      brightness: Brightness.dark,
    );

    expect(markValueColor(light, 5), markValueColor(light, 4.8));
    expect(markValueColor(light, 4), markValueColor(light, 4.2));
    expect(markValueColor(dark, 5), markValueColor(dark, 4.8));
    expect(markValueColor(dark, 4), markValueColor(dark, 3.8));
    expect(markValueColor(light, 5), isNot(markValueColor(light, 3)));
  });

  testWidgets('scenario state preserves the mark value color', (tester) async {
    const original = StudentMark(
      id: 'original',
      value: 4,
      weight: 1,
      date: '2026-01-01',
    );
    const real = StudentMark(
      id: 'real',
      value: 4.2,
      weight: 1,
      date: '2026-01-01',
    );
    const edited = StudentMark(
      id: 'edited',
      value: 4.2,
      weight: 1,
      date: '2026-01-01',
    );
    const added = StudentMark(
      id: 'added',
      value: 4.2,
      weight: 1,
      date: 'Сценарий',
    );
    const excluded = StudentMark(
      id: 'excluded',
      value: 4.2,
      weight: 1,
      date: '2026-01-02',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.purple),
        home: Scaffold(
          body: Row(
            children: [
              MarkButton(
                item: const ScenarioMark(mark: real),
                onPressed: () {},
              ),
              MarkButton(
                item: const ScenarioMark(mark: edited, original: original),
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

    final colors = ['real', 'edited', 'added', 'excluded']
        .map(
          (id) => tester
              .widget<Text>(find.byKey(ValueKey('mark-value-$id')))
              .style!
              .color,
        )
        .toList();
    expect(colors.toSet(), hasLength(1));
  });
}
