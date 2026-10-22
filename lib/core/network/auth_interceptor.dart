import 'package:dio/dio.dart';

import '../../data/local/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _storage = TokenStorage.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    handler.next(options);
  }
}