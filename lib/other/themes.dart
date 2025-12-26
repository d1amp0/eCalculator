import 'package:flutter/material.dart';
import 'package:eCalculator/other/colors.dart' as colors;

ThemeData defaultMode = ThemeData(
    scaffoldBackgroundColor: colors.defaultPrimary,
    disabledColor: colors.defaultVanish,
    colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: colors.defaultPrimary,
        onPrimary: Colors.white,
        secondary: Colors.white,
        onSecondary: Colors.black,
        error: Colors.white,
        onError: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black),
    textTheme: const TextTheme(
        displaySmall: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.black),
        displayLarge: TextStyle(color: Colors.black),));

ThemeData lightMode = ThemeData(
    scaffoldBackgroundColor: colors.lightPrimary,
    disabledColor: colors.lightVanish,
    colorScheme: ColorScheme.light(
      primary: colors.lightPrimary,
      onPrimary: Colors.black,
      secondary: Colors.white,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(color: Colors.black),
      displayMedium: TextStyle(color: Colors.white),
      displayLarge: TextStyle(color: Colors.black),));

ThemeData darkMode = ThemeData(
    scaffoldBackgroundColor: colors.blackPrimary,
    disabledColor: colors.blackVanish,
    colorScheme: ColorScheme.light(
      primary: colors.blackPrimary,
      onPrimary: Colors.black,
      secondary: colors.blackSecondary,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(color: Colors.white),
      displayMedium: TextStyle(color: Colors.white),
      displayLarge: TextStyle(color: Colors.white),));
