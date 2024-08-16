

import '../../application/services/notification_services/notification_services.dart';
import '../../application/utils/app_preferences.dart';

mixin AppInitializer {
  Future init() async {
    await NotificationServices().initNotification();
    _user();
  }

  static Future _user() async {
    await SharedPrefs.init().whenComplete(() async {
      SharedPrefs.setGetTheme();
      SharedPrefs.setGetLocale();
    });
  }
}
