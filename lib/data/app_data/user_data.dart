mixin UserData {
  static String? userToken;
  set token(String? token) => userToken = token;
  String? get token => userToken;
}
