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

  group('UserProfileRemoteDataSourceImpl.getRolesAndPermissions', () {
    late MockApiBaseService mockApi;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      mockApi = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: mockApi,
      );
    });

    test('loads the roles of the selected organisation', () async {
      when(
        () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {
            'data': [
              {
                'id': 'role-1',
                'name': 'Administrator',
                'description': 'Full access, control',
                'permissions': {
                  'permission_list': {
                    'can_create_channels': true,
                    'can_view_billing': false,
                  },
                },
              },
            ],
          },
          statusCode: 200,
        ),
      );

      final roles = await datasource.getRolesAndPermissions(orgId: 'org-1');

      verify(
        () => mockApi.get<Map<String, dynamic>>(
          path: '/organisations/org-1/roles',
        ),
      ).called(1);
      final role = roles.single;
      expect(role.id, 'role-1');
      expect(role.role, 'Administrator');
      expect(role.description, 'Full access, control');
      expect(role.permissions, ['can_create_channels']);
    });

    test('returns no roles when no organisation is selected', () async {
      final roles = await datasource.getRolesAndPermissions();

      expect(roles, isEmpty);
      verifyNever(
        () => mockApi.get<Map<String, dynamic>>(
          path: any(named: 'path'),
        ),
      );
    });
  });
}
