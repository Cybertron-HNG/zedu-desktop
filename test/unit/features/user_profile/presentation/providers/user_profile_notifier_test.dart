import 'dart:async';

import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockApiBaseService extends Mock implements ApiBaseService {}

class _FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    workspaces: [Workspace(id: 'org-1', name: 'Cybertron', avatar: '')],
    selectedWorkspace: Workspace(id: 'org-1', name: 'Cybertron', avatar: ''),
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

  group('UserProfileNotifier.inviteMember', () {
    late MockUserProfileRepository repository;
    late MockApiBaseService mockApi;

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

    setUp(() async {
      await locator.reset();
      repository = MockUserProfileRepository();
      mockApi = MockApiBaseService();
      locator.registerSingleton<ApiBaseService>(mockApi);
      locator.registerSingleton<AppConfig>(
        const AppConfig(
          apiBaseUrl: 'https://api.example.com',
          usesMockData: false,
        ),
      );
      when(
        () => mockApi.get<Map<String, dynamic>>(
          path: '/organisations/org-1/roles',
        ),
      ).thenAnswer(
        (_) async => ApiResponseModel(
          data: {
            'data': [
              {'id': 'role-admin-id', 'name': 'Administrator'},
              {'id': 'role-manager-id', 'name': 'Manager'},
              {'id': 'role-user-id', 'name': 'User'},
            ],
          },
          statusCode: 200,
        ),
      );
      when(
        () => repository.inviteMember(
          email: any(named: 'email'),
          role: any(named: 'role'),
          orgId: any(named: 'orgId'),
        ),
      ).thenAnswer(
        (invocation) async => Success(
          TeamMember(
            id: 'tm-1',
            email: invocation.namedArguments[#email] as String,
            role: invocation.namedArguments[#role] as String,
            dateJoined: 'Pending',
            status: TeamMemberStatus.pending,
          ),
        ),
      );
    });

    tearDown(() async {
      await locator.reset();
    });

    test('resolves matching role ID for Administrator, Manager, and User', () {
      return ignoringProfileLoadError(() async {
        final container = ProviderContainer(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
            workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(userProfileNotifierProvider.notifier);

        await notifier.inviteMember(
          email: 'admin@zedu.chat',
          role: 'Administrator',
        );
        await notifier.inviteMember(
          email: 'manager@zedu.chat',
          role: 'Manager',
        );
        await notifier.inviteMember(email: 'member@zedu.chat', role: 'User');

        verify(
          () => repository.inviteMember(
            email: 'admin@zedu.chat',
            role: 'role-admin-id',
            orgId: 'org-1',
          ),
        ).called(1);
        verify(
          () => repository.inviteMember(
            email: 'manager@zedu.chat',
            role: 'role-manager-id',
            orgId: 'org-1',
          ),
        ).called(1);
        verify(
          () => repository.inviteMember(
            email: 'member@zedu.chat',
            role: 'role-user-id',
            orgId: 'org-1',
          ),
        ).called(1);
      });
    });

    test('falls back to last role ID when selected role is not found', () {
      return ignoringProfileLoadError(() async {
        final container = ProviderContainer(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(repository),
            workspaceProvider.overrideWith(_FakeWorkspaceNotifier.new),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(userProfileNotifierProvider.notifier);

        await notifier.inviteMember(
          email: 'custom@zedu.chat',
          role: 'UnknownRole',
        );

        verify(
          () => repository.inviteMember(
            email: 'custom@zedu.chat',
            role: 'role-user-id',
            orgId: 'org-1',
          ),
        ).called(1);
      });
    });
  });
}
