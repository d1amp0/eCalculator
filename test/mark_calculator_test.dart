import 'package:ecalculator/domain/mark_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarkCalculator.parse', () {
    test('parses regular marks', () {
      expect(MarkCalculator.parse('5'), 5);
      expect(MarkCalculator.parse(' 3 '), 3);
    });

    test('supports plus and minus modifiers', () {
      expect(MarkCalculator.parse('4+'), closeTo(4.2, 0.0001));
      expect(MarkCalculator.parse('4-'), closeTo(3.8, 0.0001));
    });

    test('rejects empty and unsupported values', () {
      expect(MarkCalculator.parse(''), isNull);
      expect(MarkCalculator.parse('Н'), isNull);
      expect(MarkCalculator.parse('6'), isNull);
      expect(MarkCalculator.parse('4++'), isNull);
    });
  });

  group('MarkCalculator.weightedAverage', () {
    test('calculates a simple average', () {
      final average = MarkCalculator.weightedAverage(const [
        WeightedMark(3),
        WeightedMark(4),
        WeightedMark(5),
      ]);
      expect(average, 4);
    });

    test('applies mark weights', () {
      final average = MarkCalculator.weightedAverage(const [
        WeightedMark(5, 2),
        WeightedMark(2, 1),
      ]);
      expect(average, 4);
    });

    test('returns null for no usable marks', () {
      expect(MarkCalculator.weightedAverage(const []), isNull);
      expect(
        MarkCalculator.weightedAverage(const [WeightedMark(5, 0)]),
        isNull,
      );
    });

    test('ignores invalid weights and values', () {
      final average = MarkCalculator.weightedAverage(const [
        WeightedMark(5, double.nan),
        WeightedMark(double.infinity),
        WeightedMark(4),
      ]);
      expect(average, 4);
    });
  });
}
