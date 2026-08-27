import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({required this.scaffoldForeground});

  final Color scaffoldForeground;

  static Color scaffoldText(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppThemeColors>()?.scaffoldForeground ??
        theme.colorScheme.onSurface;
  }

  @override
  AppThemeColors copyWith({Color? scaffoldForeground}) {
    return AppThemeColors(
      scaffoldForeground: scaffoldForeground ?? this.scaffoldForeground,
    );
  }

  @override
  AppThemeColors lerp(covariant AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      scaffoldForeground: Color.lerp(
        scaffoldForeground,
        other.scaffoldForeground,
        t,
      )!,
    );
  }
}
