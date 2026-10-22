import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _kToken = 'auth_token';
  static const _kUserId = 'user_id';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';
  static const _kUserRole = 'user_role';

  Future<void> save({
    required String token,
    required String userId,
    required String name,
    required String email,
    String role = 'user',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kUserEmail, email);
    await prefs.setString(_kUserRole, role);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kUserId);
    final email = prefs.getString(_kUserEmail);
    if (id == null || email == null) return null;

    return {
      'id': id,
      'name': prefs.getString(_kUserName) ?? '',
      'email': email,
      'role': prefs.getString(_kUserRole) ?? 'user',
    };
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserEmail);
    await prefs.remove(_kUserRole);
  }
}