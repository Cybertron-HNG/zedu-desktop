import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'DUMMY=');
  });

  tearDown(() {
    dotenv.loadFromString(envString: 'DUMMY=');
  });

  group('AppConfig defaults', () {
    test('resolves default configuration when environment is empty', () {
      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, 'https://api.staging.zedu.chat/api/v1/');
      expect(config.usesMockData, isFalse);
      expect(config.googleClientId, kDefaultDesktopGoogleClientId);
      expect(config.googleClientSecret, isEmpty);
      expect(config.contactSalesUrl, kDefaultContactSalesUrl);
      expect(config.realtimeUrl, kDefaultRealtimeUrl);
    });

    test('ensures trailing slash is appended to apiBaseUrl', () {
      dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.com/v1');
      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, 'https://api.example.com/v1/');
    });
  });

  group('AppConfig .env parsing', () {
    test('reads custom api, mock, google, and realtime config from .env', () {
      dotenv.loadFromString(
        envString: '''
API_BASE_URL=https://custom.backend.zedu.test/api/
USE_MOCK_DATA=true
REALTIME_URL=wss://realtime.custom.zedu.test/connection
GOOGLE_CLIENT_ID=custom-google-client.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=custom-secret-key
''',
      );

      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, 'https://custom.backend.zedu.test/api/');
      expect(config.usesMockData, isTrue);
      expect(config.realtimeUrl, 'wss://realtime.custom.zedu.test/connection');
      expect(
        config.googleClientId,
        'custom-google-client.apps.googleusercontent.com',
      );
      expect(config.googleClientSecret, 'custom-secret-key');
    });
  });

  group('AppConfig USE_MOCK_DATA boolean parsing', () {
    test('parses truthy values correctly', () {
      for (final value in ['true', 'TRUE', '1', 'yes', 'YES']) {
        dotenv.loadFromString(envString: 'USE_MOCK_DATA=$value');
        final config = AppConfig.fromEnvironment();
        expect(
          config.usesMockData,
          isTrue,
          reason: '$value should parse to true',
        );
      }
    });

    test('parses falsy and invalid values to false', () {
      for (final value in ['false', '0', 'no', 'invalid']) {
        dotenv.loadFromString(envString: 'USE_MOCK_DATA=$value');
        final config = AppConfig.fromEnvironment();
        expect(
          config.usesMockData,
          isFalse,
          reason: '$value should parse to false',
        );
      }
    });
  });
}
