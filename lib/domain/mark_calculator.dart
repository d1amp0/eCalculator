class MarkCalculator {
  const MarkCalculator._();

  static double? parse(String value, {double modifier = 0.2}) {
    final match = RegExp(r'^([1-5])([+-])?$').firstMatch(value.trim());
    if (match == null) return null;

    final mark = double.parse(match.group(1)!);
    return switch (match.group(2)) {
      '+' => mark + modifier,
      '-' => mark - modifier,
      _ => mark,
    };
  }

  static double? weightedAverage(Iterable<WeightedMark> marks) {
    var weightedTotal = 0.0;
    var weightTotal = 0.0;

    for (final mark in marks) {
      if (!mark.value.isFinite || !mark.weight.isFinite || mark.weight <= 0) {
        continue;
      }
      weightedTotal += mark.value * mark.weight;
      weightTotal += mark.weight;
    }

    if (weightTotal == 0) return null;
    return weightedTotal / weightTotal;
  }
}

class WeightedMark {
  const WeightedMark(this.value, [this.weight = 1]);

  final double value;
  final double weight;
}
