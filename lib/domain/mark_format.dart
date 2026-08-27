String formatMarkValue(double value) {
  final rounded = value.round();
  final difference = value - rounded;
  if ((difference - 0.2).abs() < 0.001) return '$rounded+';
  if ((difference + 0.2).abs() < 0.001) return '$rounded-';
  if (difference.abs() < 0.001) return '$rounded';
  return _compact(value);
}

String formatWeight(double value) => _compact(value);

String formatAverage(double? value) =>
    value == null ? '—' : value.toStringAsFixed(2);

String _compact(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
