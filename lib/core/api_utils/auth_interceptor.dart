import 'package:zedu/core/core.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required SecureStorageService storage}) : _storage = storage;

  final SecureStorageService _storage;
  VoidCallback? onUnauthorized;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token;
    try {
      token = await _storage.getAccessToken();
    } catch (error) {
      // Fail the request instead of leaving it hanging.
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          message: 'Couldn\'t access your saved login.',
        ),
      );
      return;
    }
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _storage.deleteAccessToken();
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
