import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl.updateAccount', () {
    test('sends country and restores it from the response', () async {
      final api = MockApiBaseService();
      const account = ProfileAccount(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        timezone: 'Africa/Lagos',
        country: 'Nigeria',
      );
      when(
        () => api.patch<Map<String, dynamic>>(
          path: '/profile/account',
          data: {
            'name': 'Ada Lovelace',
            'email': 'ada@example.com',
            'timezone': 'Africa/Lagos',
            'avatar_url': null,
            'country': 'Nigeria',
          },
        ),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: {
            'data': {
              'name': 'Ada Lovelace',
              'email': 'ada@example.com',
              'timezone': 'Africa/Lagos',
              'country': 'Nigeria',
            },
          },
          statusCode: 200,
        ),
      );

      final datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(
          apiBaseUrl: 'https://api.example.com',
          usesMockData: false,
        ),
        apiBaseService: api,
      );

      final result = await datasource.updateAccount(account);

      expect(result.country, 'Nigeria');
      verify(
        () => api.patch<Map<String, dynamic>>(
          path: '/profile/account',
          data: {
            'name': 'Ada Lovelace',
            'email': 'ada@example.com',
            'timezone': 'Africa/Lagos',
            'avatar_url': null,
            'country': 'Nigeria',
          },
        ),
      ).called(1);
    });
  });
}
