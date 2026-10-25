import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Test org', avatar: ''),
  );
}

class EmptyWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

void main() {
  group('UserProfileNotifier.updateAccount', () {
    late MockUserProfileRepository repository;

    setUpAll(() => registerFallbackValue(ProfileAccount.empty()));

    setUp(() {
      repository = MockUserProfileRepository();
      when(
        () => repository.updateAccount(any()),
      ).thenAnswer((_) async => Success(ProfileAccount.empty()));
      when(
        () => repository.getAccount(),
      ).thenAnswer((_) async => Success(ProfileAccount.empty()));
      when(
        () => repository.getNotificationPreferences(),
      ).thenAnswer((_) async => Success(NotificationPreferences.empty()));
      when(
        () => repository.getSecuritySessions(),
      ).thenAnswer((_) async => const Success(<SecuritySession>[]));
      when(
        () => repository.getOrganization(),
      ).thenAnswer((_) async => Success(OrganizationProfile.empty()));
      when(
        () => repository.getTeamMembers(orgId: null),
      ).thenAnswer((_) async => const Success(<TeamMember>[]));
      when(
        () => repository.getRolesAndPermissions(),
      ).thenAnswer((_) async => const Success(<RolePermission>[]));
      when(
        () => repository.getBillingInfo(),
      ).thenAnswer((_) async => Success(BillingInfo.empty()));
    });

    test(
      'sends only the edited fields and shows only what was saved',
      () async {
        final container = ProviderContainer(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
            workspaceProvider.overrideWith(EmptyWorkspaceNotifier.new),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(userProfileNotifierProvider.notifier);
        final placeholder = ProfileAccount.empty();

        await notifier.updateAccount(
          placeholder.copyWith(
            phoneNumber: '+2348012345678',
            email: 'me@zedu.chat',
          ),
        );

        final sent =
            verify(() => repository.updateAccount(captureAny())).captured.single
                as ProfileAccount;
        expect(sent.name, '');
        expect(sent.phoneNumber, '+2348012345678');

        final shown = container.read(userProfileNotifierProvider).account!;
        expect(shown.phoneNumber, '+2348012345678');
        expect(shown.name, placeholder.name);
        expect(shown.email, placeholder.email);
        await pumpEventQueue();
      },
    );
  });

  group('UserProfileNotifier.load', () {
    late MockUserProfileRepository repository;
    late MockSecureStorageService storage;
    late List<({String message, String? tag})> warnings;

    setUp(() {
      repository = MockUserProfileRepository();
      storage = MockSecureStorageService();
      warnings = [];

      if (locator.isRegistered<SecureStorageService>()) {
        locator.unregister<SecureStorageService>();
      }
      locator.registerSingleton<SecureStorageService>(storage);

      when(
        () => storage.readData('mock_team_members_org-1'),
      ).thenAnswer((_) async => 'private member data is not valid json');
      when(
        () => repository.getAccount(),
      ).thenAnswer((_) async => Success(ProfileAccount.empty()));
      when(
        () => repository.getNotificationPreferences(),
      ).thenAnswer((_) async => Success(NotificationPreferences.empty()));
      when(
        () => repository.getSecuritySessions(),
      ).thenAnswer((_) async => const Success(<SecuritySession>[]));
      when(
        () => repository.getOrganization(),
      ).thenAnswer((_) async => Success(OrganizationProfile.empty()));
      when(() => repository.getTeamMembers(orgId: 'org-1')).thenAnswer(
        (_) async => const Success([
          TeamMember(
            id: 'fallback-member',
            email: 'fallback@example.com',
            role: 'User',
            dateJoined: 'May 1, 2026',
            status: TeamMemberStatus.active,
          ),
        ]),
      );
      when(
        () => repository.getRolesAndPermissions(),
      ).thenAnswer((_) async => const Success(<RolePermission>[]));
      when(
        () => repository.getBillingInfo(),
      ).thenAnswer((_) async => Success(BillingInfo.empty()));
    });

    tearDown(() => locator.unregister<SecureStorageService>());

    test(
      'initialization warns safely and keeps repository members for malformed data',
      () async {
        final container = ProviderContainer(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
            workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
            userProfileNotifierProvider.overrideWith(
              () => UserProfileNotifier(
                warningLogger: (message, {tag}) {
                  warnings.add((message: message, tag: tag));
                },
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(userProfileNotifierProvider);
        await pumpEventQueue();

        final state = container.read(userProfileNotifierProvider);
        expect(state.teamMembers.single.id, 'fallback-member');
        expect(state.isLoading, isFalse);
        expect(warnings, [
          (
            message: 'Could not read saved team members',
            tag: 'UserProfileNotifier',
          ),
        ]);
        expect(
          warnings.single.message,
          isNot(contains('private member data is not valid json')),
        );
        expect(warnings.single.message, isNot(contains('org-1')));
      },
    );
  });
}
