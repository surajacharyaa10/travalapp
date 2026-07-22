class SessionManager {
  static String? token;
  static Map<String, dynamic>? user;

  static bool get isLoggedIn => token != null;

  static void login(String jwtToken, Map<String, dynamic> userData) {
    token = jwtToken;
    user = userData;
  }

  static void logout() {
    token = null;
    user = null;
  }
}
