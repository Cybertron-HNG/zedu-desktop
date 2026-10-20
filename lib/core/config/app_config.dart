import 'package:zedu/core/core.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.usesMockData,
    // Web Client ID: '764182056638-bi8bet0rdoabaeq24bqsdnb5iukn7ko4.apps.googleusercontent.com'
    // Desktop Client ID:
    this.googleClientId =
        '764182056638-qtmk2mattvq035th78hjgpe5docu0oh1.apps.googleusercontent.com',
    this.googleClientSecret = '',
  });

  /// Resolves config after [loadAppEnv] has run in [main] (root `.env` /
  /// `.env.example`, bundled as assets).
  ///
  /// Precedence: `--dart-define` wins, then dotenv keys from those files, then
  /// defaults. See [String.fromEnvironment](https://api.flutter.dev/flutter/dart-ui/String/String.fromEnvironment.html).
  ///
  /// When no API URL is configured, debug builds default to Zedu staging but
  /// release builds (`isRelease`) throw a [StateError], so a release can never
  /// silently talk to staging. In release builds an `API_BASE_URL` that came
  /// from the bundled `.env.example` template (`envFromTemplate`) does not
  /// count as configured, because the template holds the staging URL.
  factory AppConfig.fromEnvironment({
    bool isRelease = kReleaseMode,
    bool? envFromTemplate,
  }) {
    final fromTemplate = envFromTemplate ?? envLoadedFromTemplate;
    const defineApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const defineUsesMock = String.fromEnvironment('USE_MOCK_DATA');
    const defineClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    const defineClientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');

    final envApiBaseUrl = isRelease && fromTemplate
        ? null
        : dotenv.maybeGet('API_BASE_URL')?.trim();
    final envUsesMock = dotenv.maybeGet('USE_MOCK_DATA')?.trim();
    final envClientId = dotenv.maybeGet('GOOGLE_CLIENT_ID')?.trim();
    final envClientSecret = dotenv.maybeGet('GOOGLE_CLIENT_SECRET')?.trim();

    // Teams point the app at their own backend via --dart-define or .env.
    final configuredApiBaseUrl = defineApiBaseUrl.isNotEmpty
        ? defineApiBaseUrl
        : (envApiBaseUrl?.isNotEmpty ?? false)
        ? envApiBaseUrl
        : null;

    if (configuredApiBaseUrl == null && isRelease) {
      throw StateError(
        'API_BASE_URL is not set. Release builds must pass '
        '--dart-define=API_BASE_URL=<url> or set it in .env '
        '(the bundled .env.example template is not accepted).',
      );
    }

    // Debug builds fall back to Zedu staging.
    String apiBaseUrl =
        configuredApiBaseUrl ?? 'https://api.staging.zedu.chat/api/v1/';

    apiBaseUrl = apiBaseUrl.replaceAll('"', '').replaceAll("'", "");

    if (!apiBaseUrl.endsWith('/')) {
      apiBaseUrl += '/';
    }

    final usesMockData = defineUsesMock.isNotEmpty
        ? _parseBool(defineUsesMock, defaultValue: false)
        : envUsesMock != null && envUsesMock.isNotEmpty
        ? _parseBool(envUsesMock, defaultValue: false)
        : false; // Changed to false so real backend is used by default

    final googleClientId = defineClientId.isNotEmpty
        ? defineClientId
        : (envClientId?.isNotEmpty ?? false)
        ? envClientId!
        // Web Client ID: '764182056638-bi8bet0rdoabaeq24bqsdnb5iukn7ko4.apps.googleusercontent.com'
        // Desktop Client ID:
        : '764182056638-08g88e196e643mhpa2tuv5dpr7iumd1j.apps.googleusercontent.com';

    final googleClientSecret = defineClientSecret.isNotEmpty
        ? defineClientSecret
        : (envClientSecret?.isNotEmpty ?? false)
        ? envClientSecret!
        : '';

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      usesMockData: usesMockData,
      googleClientId: googleClientId,
      googleClientSecret: googleClientSecret,
    );
  }

  final String apiBaseUrl;
  final bool usesMockData;
  final String googleClientId;
  final String googleClientSecret;
}

bool _parseBool(String raw, {required bool defaultValue}) {
  final normalized = raw.trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return defaultValue;
}
