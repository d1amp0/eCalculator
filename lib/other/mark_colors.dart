import 'package:flutter/material.dart';

int markGradeFamily(double value) => value.round().clamp(1, 5);

Color markValueColor(ColorScheme scheme, double value) {
  final dark = scheme.brightness == Brightness.dark;
  return switch (markGradeFamily(value)) {
    5 => dark ? const Color(0xFF81C784) : const Color(0xFF1B5E20),
    4 => dark ? const Color(0xFF80CBC4) : const Color(0xFF00695C),
    3 => dark ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
    2 => dark ? const Color(0xFFFF8A80) : const Color(0xFFB71C1C),
    _ => dark ? const Color(0xFFFF5252) : const Color(0xFF8E0000),
  };
}

Color markTileColor(ColorScheme scheme, double value) {
  return Color.alphaBlend(
    markValueColor(scheme, value).withValues(alpha: 0.08),
    scheme.surface,
  );
}
