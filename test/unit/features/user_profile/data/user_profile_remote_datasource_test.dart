import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl.updateAccount', () {
    late MockApiBaseService mockApi;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: mockApi,
      );
      when(
        () => mockApi.patch<Map<String, dynamic>>(
          path: any(named: 'path'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {'status': 'success'},
          statusCode: 200,
        ),
      );
    });

    test('sends the phone number to PATCH /profile as form data', () async {
      const account = ProfileAccount(
        name: 'Odofin Moronke',
        email: '',
        timezone: '',
        phoneNumber: '+2348012345678',
      );

      final saved = await datasource.updateAccount(account);

      final data =
          verify(
                () => mockApi.patch<Map<String, dynamic>>(
                  path: '/profile',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as FormData;
      expect(Map.fromEntries(data.fields), {
        'full_name': 'Odofin Moronke',
        'phone': '+2348012345678',
      });
      expect(saved.phoneNumber, '+2348012345678');
    });
  });

  group('UserProfileRemoteDataSourceImpl.getTeamMembers', () {
    late MockApiBaseService mockApi;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: mockApi,
      );
    });

    test('lists the members of the selected organisation', () async {
      when(
        () => mockApi.get<Map<String, dynamic>>(
          path: any(named: 'path'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {
            'data': [
              {'id': 'user-1', 'email': 'a@zedu.app', 'name': 'A'},
            ],
          },
          statusCode: 200,
        ),
      );

      final members = await datasource.getTeamMembers(orgId: 'org-1');

      verify(
        () => mockApi.get<Map<String, dynamic>>(
          path: '/organisations/org-1/users',
        ),
      ).called(1);
      expect(members.single.id, 'user-1');
      expect(members.single.name, 'A');
    });

    test('returns no members when no organisation is selected', () async {
      final members = await datasource.getTeamMembers();

      expect(members, isEmpty);
      verifyNever(
        () => mockApi.get<Map<String, dynamic>>(
          path: any(named: 'path'),
        ),
      );
    });

    test('returns no members for an empty organisation id', () async {
      final members = await datasource.getTeamMembers(orgId: '');

      expect(members, isEmpty);
      verifyNever(
        () => mockApi.get<Map<String, dynamic>>(
          path: any(named: 'path'),
        ),
      );
    });

    test('never asks for a hard-coded organisation', () async {
      await datasource.getTeamMembers();

      verifyNever(
        () => mockApi.get<Map<String, dynamic>>(
          path: '/organisations/019700db-4e22-7f90-a20e-f9116291ef24/users',
        ),
      );
    });
  });
}
