import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  group('AppConfig.fromEnvironment API base URL', () {
    test('release build with no API URL throws instead of using staging', () {
      dotenv.loadFromString(envString: '', isOptional: true);

      expect(
        () => AppConfig.fromEnvironment(isRelease: true),
        throwsA(isA<StateError>()),
      );
    });

    test('debug build with no API URL falls back to staging', () {
      dotenv.loadFromString(envString: '', isOptional: true);

      final config = AppConfig.fromEnvironment(isRelease: false);

      expect(config.apiBaseUrl, 'https://api.staging.zedu.chat/api/v1/');
    });

    test('release build rejects an API URL that came from .env.example', () {
      dotenv.loadFromString(
        envString: 'API_BASE_URL=https://api.staging.zedu.chat/api/v1/',
      );

      expect(
        () => AppConfig.fromEnvironment(isRelease: true, envFromTemplate: true),
        throwsA(isA<StateError>()),
      );
    });

    test('debug build still accepts the API URL from .env.example', () {
      dotenv.loadFromString(
        envString: 'API_BASE_URL=https://api.staging.zedu.chat/api/v1/',
      );

      final config = AppConfig.fromEnvironment(
        isRelease: false,
        envFromTemplate: true,
      );

      expect(config.apiBaseUrl, 'https://api.staging.zedu.chat/api/v1/');
    });

    test(
      'release build uses an API URL from .env and adds a trailing slash',
      () {
        dotenv.loadFromString(
          envString: 'API_BASE_URL=https://api.example.test/v1',
        );

        final config = AppConfig.fromEnvironment(isRelease: true);

        expect(config.apiBaseUrl, 'https://api.example.test/v1/');
      },
    );
  });
}
