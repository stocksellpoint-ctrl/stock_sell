/// Placeholder — will use Dio when backend is ready.
///
/// When backend arrives:
///   1. Uncomment dio in pubspec.yaml
///   2. Implement this class with a Dio instance
///   3. Set baseUrl + auth interceptor
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_endpoints.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio = _buildDio();

  Dio get dio => _dio;

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    dio.interceptors.add(AuthInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    return dio;
  }

  /// Convert DioException into a friendly ApiException.
  ApiException handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response;

      if (response != null && response.data is Map) {
        final data = response.data as Map;

        List<String>? parsedErrors;
        final rawErrors = data['errors'];
        if (rawErrors is List) {
          parsedErrors = rawErrors
              .map((e) => e is Map
                  ? (e['message']?.toString() ?? '')
                  : e.toString())
              .where((s) => s.isNotEmpty)
              .toList();
        } else if (rawErrors is String && rawErrors.isNotEmpty) {
          parsedErrors = [rawErrors];
        }

        return ApiException(
          message: data['message']?.toString() ?? 'Request failed',
          statusCode: response.statusCode,
          code: data['code']?.toString(),
          errors: parsedErrors,
        );
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return ApiException(
            message: 'Connection timed out. Check your internet.',
            code: 'TIMEOUT',
          );
        case DioExceptionType.connectionError:
          return ApiException(
            message: 'Cannot reach the server. Is the backend running?',
            code: 'CONNECTION_ERROR',
          );
        case DioExceptionType.cancel:
          return ApiException(
            message: 'Request was cancelled.',
            code: 'CANCELLED',
          );
        default:
          return ApiException(
            message: error.message ?? 'Something went wrong.',
            code: 'UNKNOWN',
          );
      }
    }

    if (error is ApiException) return error;
    return ApiException(message: error.toString(), code: 'UNKNOWN');
  }
}
