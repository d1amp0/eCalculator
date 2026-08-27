import 'package:ecalculator/other/colors.dart' as colors;
import 'package:ecalculator/other/app_theme_colors.dart';
import 'package:flutter/material.dart';

ThemeData defaultMode = _buildTheme(
  brightness: Brightness.light,
  scaffold: colors.defaultPrimary,
  primary: colors.defaultPrimary,
  surface: Colors.white,
  disabled: colors.defaultVanish,
  headerForeground: Colors.white,
  primaryForeground: Colors.white,
);

ThemeData lightMode = _buildTheme(
  brightness: Brightness.light,
  scaffold: colors.lightPrimary,
  primary: colors.lightPrimary,
  surface: Colors.white,
  disabled: colors.lightVanish,
  headerForeground: Colors.black,
  primaryForeground: Colors.black,
);

ThemeData darkMode = _buildTheme(
  brightness: Brightness.dark,
  scaffold: colors.blackPrimary,
  primary: colors.defaultPrimary,
  surface: colors.blackSecondary,
  disabled: colors.blackVanish,
  headerForeground: Colors.white,
  primaryForeground: Colors.white,
);

ThemeData _buildTheme({
  required Brightness brightness,
  required Color scaffold,
  required Color primary,
  required Color surface,
  required Color disabled,
  required Color headerForeground,
  required Color primaryForeground,
}) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  ).copyWith(
    primary: primary,
    onPrimary: primaryForeground,
    secondary: surface,
    onSecondary: isDark ? Colors.white : Colors.black,
    surface: surface,
    onSurface: isDark ? Colors.white : Colors.black,
  );
  final baseText = ThemeData(brightness: brightness).textTheme;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: scaffold,
    disabledColor: disabled,
    colorScheme: scheme,
    textTheme: baseText.copyWith(
      displaySmall: TextStyle(color: headerForeground),
      displayMedium: TextStyle(color: isDark ? Colors.white : Colors.black),
      displayLarge: TextStyle(color: isDark ? Colors.white : Colors.black),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scaffold,
      foregroundColor: headerForeground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    extensions: [
      AppThemeColors(scaffoldForeground: headerForeground),
    ],
  );
}
