import '../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  test('fails the request when the keyring cannot be read', () async {
    final storage = MockSecureStorageService();
    when(() => storage.getAccessToken()).thenAnswer(
      (_) => Future.error(
        PlatformException(code: 'KeyringLocked', message: 'KeyringLocked'),
      ),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
      ..interceptors.add(AuthInterceptor(storage: storage));

    await expectLater(
      dio.get<void>('/auth/me').timeout(const Duration(seconds: 5)),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<PlatformException>(),
        ),
      ),
    );
  });
}
