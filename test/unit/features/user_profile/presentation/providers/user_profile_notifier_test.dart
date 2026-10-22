import 'dart:async';
import 'dart:convert';

import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class _WorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    selectedWorkspace: Workspace(id: 'org-1', name: 'Test org', avatar: ''),
  );
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
    });

    // The profile load started in build() still fails with the
    // uninitialized-provider error tracked in #51, so it's ignored here; the
    // account is then the placeholder the edit form opens with.
    Future<void> ignoringProfileLoadError(Future<void> Function() body) {
      final done = Completer<void>();
      runZonedGuarded(
        () => body().then(done.complete, onError: done.completeError),
        (error, stack) {
          if (error is! StateError) done.completeError(error, stack);
        },
      );
      return done.future;
    }

    test('sends only the edited fields and shows only what was saved', () {
      return ignoringProfileLoadError(() async {
        final container = ProviderContainer(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
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
      });
    });
  });

  group('UserProfileNotifier.load team members', () {
    late MockUserProfileRepository repository;
    late MockSecureStorageService storage;

    const apiMember = TeamMember(
      id: 'api-1',
      email: 'real@zedu.app',
      role: 'Administrator',
      dateJoined: '2026-01-01',
      status: TeamMemberStatus.active,
      name: 'Real Member',
    );

    final cachedMockMembers = jsonEncode([
      {
        'id': 'member-1',
        'email': 'teammate1@zedu.app',
        'role': 'Manager',
        'name': 'Teammate 1',
        'avatar_url': null,
        'date_joined': 'May 2, 2026',
        'status': 'active',
      },
    ]);

    void registerConfig({required bool usesMockData}) {
      locator.registerSingleton<AppConfig>(
        AppConfig(apiBaseUrl: 'https://api.example.com', usesMockData: usesMockData),
      );
    }

    Future<List<TeamMember>> loadMembers() {
      final done = Completer<List<TeamMember>>();
      // build() starts a load while the notifier is still being built, which
      // Riverpod rejects with a StateError (tracked in #51). That failed
      // future is not awaited anywhere, so keep it out of the test.
      runZonedGuarded(
        () async {
          try {
            final container = ProviderContainer(
              overrides: [
                userProfileRepositoryProvider.overrideWithValue(repository),
                workspaceProvider.overrideWith(_WorkspaceNotifier.new),
              ],
            );
            addTearDown(container.dispose);

            final notifier = container.read(
              userProfileNotifierProvider.notifier,
            );
            await notifier.load();
            // Let the load started by build() settle before the container is
            // disposed at the end of the test.
            await Future<void>.delayed(Duration.zero);

            done.complete(
              container.read(userProfileNotifierProvider).teamMembers,
            );
          } catch (error, stack) {
            done.completeError(error, stack);
          }
        },
        (error, stack) {
          if (error is! StateError) done.completeError(error, stack);
        },
      );
      return done.future;
    }

    setUp(() {
      repository = MockUserProfileRepository();
      storage = MockSecureStorageService();
      locator.registerSingleton<SecureStorageService>(storage);

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
        () => repository.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success([apiMember]));
      when(
        () => repository.getRolesAndPermissions(),
      ).thenAnswer((_) async => const Success(<RolePermission>[]));
      when(
        () => repository.getBillingInfo(),
      ).thenAnswer((_) async => Success(BillingInfo.empty()));

      when(
        () => storage.readData(any()),
      ).thenAnswer((_) async => cachedMockMembers);
      when(() => storage.deleteData(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await locator.reset();
    });

    test('ignores cached mock members when mock data is disabled', () async {
      registerConfig(usesMockData: false);

      final members = await loadMembers();

      expect(members.map((member) => member.id), ['api-1']);
      verifyNever(() => storage.readData(any()));
    });

    test('clears stale mock members when mock data is disabled', () async {
      registerConfig(usesMockData: false);

      await loadMembers();

      verify(
        () => storage.deleteData('mock_team_members_org-1'),
      ).called(greaterThanOrEqualTo(1));
    });

    test('applies cached mock members while mock data is enabled', () async {
      registerConfig(usesMockData: true);

      final members = await loadMembers();

      expect(members.map((member) => member.id), ['member-1']);
      verifyNever(() => storage.deleteData(any()));
    });
  });
}
