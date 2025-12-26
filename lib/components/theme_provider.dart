import 'package:flutter/material.dart';
import 'package:eCalculator/other/themes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData themeDataCurrent = defaultMode;
  bool isBlack = false;

  ThemeProvider(int? index) {
    if (index == null) {
      toggleTheme(0);
    } else {
      toggleTheme(index);
    }
  }

  ThemeData get themeData => themeDataCurrent;


  set themeData(ThemeData themeData) {
    themeDataCurrent = themeData;
    notifyListeners();
  }

  void toggleTheme(int index) {
    if (index == 0) {
      themeData = defaultMode;
      isBlack = false;
    }
    if (index == 1) {
      themeData = lightMode;
      isBlack = false;
    }
    if (index == 2) {
      themeData = darkMode;
      isBlack = true;
    }
  }
}
