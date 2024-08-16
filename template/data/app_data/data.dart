
import 'app_initializer.dart';
import 'user_data.dart';

class Data with AppInitializer, UserData {
  Data._();

  // Static instance variable
  static final Data app = Data._();

  // Getter to access the instance
  factory Data() {
    return app;
  }

  static const String test = '';
}
