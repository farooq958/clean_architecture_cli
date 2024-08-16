
import '../../application/utils/app_preferences.dart';
import 'app_exports.dart';

class AppLocale {
  static ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

  static changeLocale(String localeMode) async {
    if (localeMode == 'en') {
      AppLocale.appLocale.value = const Locale('ar');
      await SharedPrefs.setLocale("ar");
      // await _preferences?.setString(PrefsKeys.LOCALE_KEY, 'en');
    } else {
      AppLocale.appLocale.value = const Locale('en');

      await SharedPrefs.setLocale("en");
    }
    AppLocale.appLocale.notifyListeners();
  }
}
