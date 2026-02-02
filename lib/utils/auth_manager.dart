import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  // --------------------------------------------------------------------------
  // User Login State Management
  // --------------------------------------------------------------------------

  /// Set the login state of the user (logged in or not).
  static Future<void> setUserLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isUserLoggedIn', isLoggedIn);
    print('AuthManager: setUserLoggedIn() called. State: $isLoggedIn');
  }

  /// Check if the user is logged in.
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final bool state = prefs.getBool('isUserLoggedIn') ?? false;
    print('AuthManager: isUserLoggedIn() called. State: $state');
    return state;
  }

  // --------------------------------------------------------------------------
  // User ID Management
  // --------------------------------------------------------------------------

  /// Store the user ID.
  static Future<void> setUserId(int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove('userId');
      print('AuthManager: userId cleared.');
    } else {
      await prefs.setInt('userId', userId);
      print('AuthManager: setUserId() called. ID: $userId');
    }
  }

  /// Retrieve the stored user ID.
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');
    print('AuthManager: getUserId() called. ID: $userId');
    return userId;
  }

  // --------------------------------------------------------------------------
  // First-Time User Management
  // --------------------------------------------------------------------------

  /// Check if the app is being launched for the first time.
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool state = prefs.getBool('isFirstTime') ?? true;
    print('AuthManager: isFirstTime() called. State: $state');
    return state;
  }

  /// Set the first-time flag (true = first time, false = not first time).
  static Future<void> setFirstTime(bool isFirstTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', isFirstTime);
    print('AuthManager: setFirstTime() called. State: $isFirstTime');
  }
}
