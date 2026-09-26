import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('AuthRemoteDataSourceImpl', () {
    late MockApiBaseService mockApi;

    setUp(() {
      mockApi = MockApiBaseService();
    });

    group('login', () {
      test('returns mock response when usesMockData is true', () async {
        final datasource = AuthRemoteDataSourceImpl(
          config: const AppConfig(
            apiBaseUrl: 'https://api.example.com',
            usesMockData: true,
          ),
          apiBaseService: mockApi,
        );

        final result = await datasource.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isA<LoginResponseModel>());
        expect(result.accessToken, isNotEmpty);
        expect(result.user.email, isNotEmpty);
        verifyNever(
          () => mockApi.post<Map<String, dynamic>>(
            path: any(named: 'path'),
            data: any(named: 'data'),
          ),
        );
      });

      test('calls POST /auth/login with correct credentials', () async {
        when(
          () => mockApi.post<Map<String, dynamic>>(
            path: '/auth/login',
            data: {'email': 'user@example.com', 'password': 'Secret123'},
          ),
        ).thenAnswer(
          (_) async => ApiResponseModel<Map<String, dynamic>>(
            data: {'data': LoginResponseModel.mockLoginResponse},
            statusCode: 200,
          ),
        );

        final datasource = AuthRemoteDataSourceImpl(
          config: const AppConfig(
            apiBaseUrl: 'https://api.example.com',
            usesMockData: false,
          ),
          apiBaseService: mockApi,
        );

        await datasource.login(
          email: 'user@example.com',
          password: 'Secret123',
        );

        verify(
          () => mockApi.post<Map<String, dynamic>>(
            path: '/auth/login',
            data: {'email': 'user@example.com', 'password': 'Secret123'},
          ),
        ).called(1);
      });

      test('rethrows ApiFailure from the API', () async {
        final failure = ApiFailure.unknown(Exception('network error'));

        when(
          () => mockApi.post<Map<String, dynamic>>(
            path: '/auth/login',
            data: any(named: 'data'),
          ),
        ).thenThrow(failure);

        final datasource = AuthRemoteDataSourceImpl(
          config: const AppConfig(
            apiBaseUrl: 'https://api.example.com',
            usesMockData: false,
          ),
          apiBaseService: mockApi,
        );

        expect(
          () => datasource.login(email: 'test@example.com', password: 'pass'),
          throwsA(isA<ApiFailure>()),
        );
      });
    });

    group('me', () {
      test('returns user from mock data when usesMockData is true', () async {
        final datasource = AuthRemoteDataSourceImpl(
          config: const AppConfig(
            apiBaseUrl: 'https://api.example.com',
            usesMockData: true,
          ),
          apiBaseService: mockApi,
        );

        final user = await datasource.me();

        expect(user.email, isNotEmpty);
        verifyNever(
          () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
        );
      });

      test('calls GET /auth/me and returns user', () async {
        final rawUserData =
            LoginResponseModel.mockLoginResponse['user']
                as Map<String, dynamic>;

        when(
          () => mockApi.get<Map<String, dynamic>>(path: '/auth/me'),
        ).thenAnswer(
          (_) async => ApiResponseModel<Map<String, dynamic>>(
            data: {'data': rawUserData},
            statusCode: 200,
          ),
        );

        final datasource = AuthRemoteDataSourceImpl(
          config: const AppConfig(
            apiBaseUrl: 'https://api.example.com',
            usesMockData: false,
          ),
          apiBaseService: mockApi,
        );

        final user = await datasource.me();

        expect(user.email, rawUserData['email'] as String);
        verify(
          () => mockApi.get<Map<String, dynamic>>(path: '/auth/me'),
        ).called(1);
      });
    });

    group('sendMagicLink', () {
      test('calls POST /auth/magick-link with email payload', () async {
        when(
          () => mockApi.post<Map<String, dynamic>>(
            path: '/auth/magick-link',
            data: {'email': 'magic@example.com'},
          ),
        ).thenAnswer(
          (_) async => ApiResponseModel<Map<String, dynamic>>(
            data: {'status': 'success'},
            statusCode: 200,
          ),
        );

        final datasource = AuthRemoteDataSourceImpl(
          config: const AppConfig(
            apiBaseUrl: 'https://api.example.com',
            usesMockData: false,
          ),
          apiBaseService: mockApi,
        );

        await datasource.sendMagicLink(email: 'magic@example.com');

        verify(
          () => mockApi.post<Map<String, dynamic>>(
            path: '/auth/magick-link',
            data: {'email': 'magic@example.com'},
          ),
        ).called(1);
      });
    });

    group('verifyMagicLink', () {
      test('calls POST /auth/magick-link/verify with token', () async {
        when(
          () => mockApi.post<Map<String, dynamic>>(
            path: '/auth/magick-link/verify',
            data: {'token': 'token-123'},
          ),
        ).thenAnswer(
          (_) async => ApiResponseModel<Map<String, dynamic>>(
            data: {'data': LoginResponseModel.mockLoginResponse},
            statusCode: 200,
          ),
        );

        final datasource = AuthRemoteDataSourceImpl(
          config: const AppConfig(
            apiBaseUrl: 'https://api.example.com',
            usesMockData: false,
          ),
          apiBaseService: mockApi,
        );

        final result = await datasource.verifyMagicLink(token: 'token-123');

        expect(result, isA<LoginResponseModel>());
        verify(
          () => mockApi.post<Map<String, dynamic>>(
            path: '/auth/magick-link/verify',
            data: {'token': 'token-123'},
          ),
        ).called(1);
      });
    });
  });
}
