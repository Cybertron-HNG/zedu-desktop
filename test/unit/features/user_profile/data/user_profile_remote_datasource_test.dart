import '../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

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

  group('UserProfileRemoteDataSourceImpl.getTeamMembers (mock data)', () {
    late MockSecureStorageService storage;
    late UserProfileRemoteDataSourceImpl datasource;
    late List<({String message, String? tag})> warnings;

    setUp(() {
      storage = MockSecureStorageService();
      warnings = [];
      if (locator.isRegistered<SecureStorageService>()) {
        locator.unregister<SecureStorageService>();
      }
      locator.registerSingleton<SecureStorageService>(storage);
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: true),
        apiBaseService: MockApiBaseService(),
        warningLogger: (message, {tag}) {
          warnings.add((message: message, tag: tag));
        },
      );
    });

    tearDown(() => locator.unregister<SecureStorageService>());

    test(
      'falls back to the default members when saved data is corrupted',
      () async {
        when(
          () => storage.readData('mock_team_members_org-1'),
        ).thenAnswer((_) async => 'not valid json');

        final members = await datasource.getTeamMembers(orgId: 'org-1');

        expect(members, isNotEmpty);
        expect(warnings, [
          (
            message: 'Could not read saved team members',
            tag: 'UserProfileRemoteDataSource',
          ),
        ]);
        expect(warnings.single.message, isNot(contains('not valid json')));
        expect(warnings.single.message, isNot(contains('org-1')));
      },
    );
  });
}
