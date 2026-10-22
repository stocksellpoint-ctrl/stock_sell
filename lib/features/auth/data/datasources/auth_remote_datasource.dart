import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/local/token_storage.dart';

class AuthRemoteDataSource {
  final Dio _dio = ApiClient.instance.dio;
  final TokenStorage _storage = TokenStorage.instance;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        final data =
            (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        await _saveSession(data);
        return data;
      }
      throw ApiClient.instance.handleError(
        DioException(requestOptions: res.requestOptions, response: res),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (res.statusCode == 200) {
        final data =
            (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        await _saveSession(data);
        return data;
      }
      throw ApiClient.instance.handleError(
        DioException(requestOptions: res.requestOptions, response: res),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiClient.instance.handleError(e);
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await _storage.getToken();
    if (token == null) return null;

    try {
      final res = await _dio.get(ApiEndpoints.me);
      if (res.statusCode == 200) {
        return ((res.data as Map<String, dynamic>)['data']['user']
            as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // ignore — we're clearing local state anyway
    } finally {
      await _storage.clear();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final user = data['user'] as Map<String, dynamic>;
    await _storage.save(
      token: data['token'] as String,
      userId: user['id'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
      role: user['role'] as String? ?? 'user',
    );
  }
}
