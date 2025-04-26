import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/user_response.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _userTypeKey = 'usertype';
  static const _isFirstLoginKey = 'isFirstLogin';

  // Check if user is logged in and validate token
  static Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token == null) return false;

      // Validate token with API
      final response = await ApiService.get(
        endpoint: ApiConfig.userProfile,
        token: token,
      );

      final userResponse = UserResponse.fromJson(response);
      if (userResponse.status == 200 && userResponse.payload.isNotEmpty) {
        // Save user type
        await _storage.write(
          key: _userTypeKey,
          value: userResponse.payload[0].userType,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Save authentication data
  static Future<void> saveAuthData({
    required String accessToken,
    required String userType,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _userTypeKey, value: userType);
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Get user type
  static Future<String?> getUserType() async {
    return await _storage.read(key: _userTypeKey);
  }

  // Check if it's first login
  static Future<bool> isFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLoginKey) ?? true;
  }

  // Set first login status
  static Future<void> setFirstLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLoginKey, value);
  }

  // Clear all auth data
  static Future<void> clearAuthData() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isFirstLoginKey);
  }
}
