import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  group('AuthNotifier session restore', () {
    late MockAuthRepository repository;
    late MockSecureStorageService storage;
    late ProviderContainer container;

    setUp(() {
      repository = MockAuthRepository();
      storage = MockSecureStorageService();
      locator
        ..registerSingleton<SecureStorageService>(storage)
        ..registerSingleton<AuthInterceptor>(AuthInterceptor(storage: storage));
      container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
    });

    tearDown(() async {
      container.dispose();
      await locator.reset();
    });

    test('shows the login screen when the keyring cannot be read', () async {
      when(() => storage.getAccessToken()).thenAnswer(
        (_) => Future.error(
          PlatformException(code: 'KeyringLocked', message: 'KeyringLocked'),
        ),
      );

      expect(container.read(authNotifierProvider).status, AuthStatus.unknown);
      await pumpEventQueue();

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(
        state.error,
        'Couldn\'t access your saved login. Please log in again.',
      );
      verifyNever(() => repository.getCurrentUser());
    });
  });
}
