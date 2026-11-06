import '../../../../helpers/helpers.dart';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group(
    'UserProfileRemoteDataSourceImpl.getTeamMembers errors (Ziki #2918)',
    () {
      const orgId = '01970000-0000-7000-8000-000000000001';
      late MockApiBaseService api;
      late UserProfileRemoteDataSourceImpl dataSource;

      setUp(() {
        api = MockApiBaseService();
        dataSource = UserProfileRemoteDataSourceImpl(
          config: const AppConfig(
            apiBaseUrl: 'https://api.example.com',
            usesMockData: false,
          ),
          apiBaseService: api,
        );
      });

      void answer(Future<ApiResponseModel<Map<String, dynamic>>> Function() f) {
        when(
          () => api.get<Map<String, dynamic>>(
            path: '/organisations/$orgId/users',
          ),
        ).thenAnswer((_) => f());
      }

      test('a failed request throws instead of returning no members', () async {
        answer(() async => throw const ApiFailure(message: 'Network down'));

        await expectLater(
          dataSource.getTeamMembers(orgId: orgId),
          throwsA(isA<ApiFailure>()),
        );
      });

      test('a response it cannot read throws an ApiFailure', () async {
        answer(
          () async => const ApiResponseModel(
            data: <String, dynamic>{'data': 'not a list'},
            statusCode: 200,
          ),
        );

        await expectLater(
          dataSource.getTeamMembers(orgId: orgId),
          throwsA(isA<ApiFailure>()),
        );
      });

      test('an organisation with no members is still an empty list', () async {
        answer(
          () async => const ApiResponseModel(
            data: <String, dynamic>{'data': <dynamic>[]},
            statusCode: 200,
          ),
        );

        expect(await dataSource.getTeamMembers(orgId: orgId), isEmpty);
      });
    },
  );
}
