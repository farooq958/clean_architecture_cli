import 'dart:convert';



import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/app_data/app_locale.dart';
import '../../data/app_data/prefs_keys.dart';
import '../../data/resources/theme/app_theme.dart';

class SharedPrefs  {
  // SharedPrefs._();

  /// reference of Shared Preferences
  static SharedPreferences? _preferences;

  /// Initialization of Shared Preferences
  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  ///survey

  ///UserData stored in json
  ///userRawData will be in map<String,dynamic>
  static Future setUserLoginData({required userRawData}) async =>
      await _preferences?.setString(
          PrefsKeys.USER_KEY, jsonEncode(userRawData));

  static Future setLoginToken(String token) async =>
      await _preferences!.setString(PrefsKeys.TOKEN_KEY, token);

  //

  static String? getUserToken() {
    String? token;
    token = _preferences!.getString(PrefsKeys.TOKEN_KEY);

    if (token != null) {
     // Data.app.token = token;
    }
    return token;
  }

  ///get user data future
  //
  // static Future<UserModel>? getUserLoginData() {
  //   String? userJson;
  //   if (_preferences!.containsKey('user')) {
  //     userJson = _preferences!.getString("user");
  //
  //     print(userJson.toString());
  //
  //     if (userJson != null) {
  //       Data.app.user = UserModel.fromRawJson(userJson);
  //
  //       print("Data.app.user");
  //       print(Data.app.user?.email);
  //     }
  //   }
  //   return Future.value(Data.app.user);
  // }

  static Future clearUserData() async {
    bool? stat = await _preferences!.clear();
  //  Data.app.token = null;
    //  Data.app.user=null;
    print(stat);
    return stat;
  }

  static Future<void> setGetTheme() async {
    String? themeMode = _preferences?.getString(PrefsKeys.THEME_KEY);

    if (themeMode != null) {
      if (themeMode == 'darkTheme') {
        AppTheme.instance.setTheme(ThemeMode.dark);
      } else {
        AppTheme.instance.setTheme(ThemeMode.light);
      }
    } else {
      await _preferences?.setString(PrefsKeys.THEME_KEY, 'lightTheme');
    }

    //  return themeMode;
  }

  static Future<void> setGetLocale() async {
    String? localeMode = _preferences?.getString(PrefsKeys.LOCALE_KEY);

    if (localeMode != null) {
      AppLocale.appLocale.value = Locale(localeMode.toString());
      AppLocale.appLocale.notifyListeners();
    } else {
      await _preferences?.setString(PrefsKeys.LOCALE_KEY, 'ur');
    }

    //  return themeMode;
  }

  static setLocale(localeVal) async {
    await _preferences?.setString(PrefsKeys.LOCALE_KEY, localeVal);
  }

  static Future<void> setCustomTheme() async {
    if (AppTheme.instance.currentTheme.value == ThemeMode.light) {
      await _preferences?.setString(PrefsKeys.THEME_KEY, 'lightTheme');
    } else {
      await _preferences?.setString(PrefsKeys.THEME_KEY, 'darkTheme');
    }
  }


}
