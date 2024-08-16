

import '../../../application/utils/app_preferences.dart';
import '../../app_data/app_exports.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

class AppTheme with CustomLightTheme, CustomDarkTheme {
  AppTheme._();

  static AppTheme instance = AppTheme._();

  factory AppTheme() => instance;
  ValueNotifier<ThemeMode> currentTheme = ValueNotifier(ThemeMode.light);

  toggleTheme() {
    currentTheme.value = currentTheme.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    currentTheme.notifyListeners();
    SharedPrefs.setCustomTheme();
  }

  setTheme(ThemeMode themeMode) {
    currentTheme.value = themeMode;
    currentTheme.notifyListeners();
  }
}
