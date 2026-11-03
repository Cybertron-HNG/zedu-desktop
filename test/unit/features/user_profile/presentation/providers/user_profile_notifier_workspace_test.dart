import 'dart:async';

import '../../../../../helpers/helpers.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

Workspace _workspace(String id) {
  return Workspace(id: id, name: 'Workspace $id', avatar: '');
}

/// A workspace notifier that starts on workspace "A" and never calls the API.
class _TestWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() {
    return WorkspaceState(selectedWorkspace: _workspace('A'));
  }

  void select(String id) {
    state = state.copyWith(selectedWorkspace: _workspace(id));
  }
}

/// A workspace notifier listing workspaces "A" and "B", with [selected]
/// chosen.
class _ListedWorkspaceNotifier extends WorkspaceNotifier {
  _ListedWorkspaceNotifier(this.selected);

  final String? selected;

  @override
  WorkspaceState build() {
    return WorkspaceState(
      workspaces: [_workspace('A'), _workspace('B')],
      selectedWorkspace: selected == null ? null : _workspace(selected!),
    );
  }
}

Future<Result<T>> _failed<T>() async {
  return Failure<T>(const ApiFailure(message: 'unavailable'));
}

void main() {
  group('UserProfileNotifier.load', () {
    late MockUserProfileRepository repo;
    late MockSecureStorageService storage;
    late int organizationCalls;

    // Each organisation request gets its own name, so a test can tell which
    // load wrote the state.
    Future<Result<OrganizationProfile>> answerOrganization(Invocation call) {
      organizationCalls++;
      final orgId = call.namedArguments[#orgId] as String?;
      final organization = OrganizationProfile(
        id: orgId ?? '',
        name: 'load $organizationCalls',
        natureOfBusiness: 'Technology',
        country: 'Nigeria',
      );
      return Future.value(Success<OrganizationProfile>(organization));
    }

    setUp(() {
      repo = MockUserProfileRepository();
      storage = MockSecureStorageService();
      organizationCalls = 0;
      locator.registerSingleton<SecureStorageService>(storage);

      when(() => repo.getAccount()).thenAnswer((_) => _failed());
      when(() => repo.getSecuritySessions()).thenAnswer((_) => _failed());
      when(() => repo.getRolesAndPermissions()).thenAnswer((_) => _failed());
      when(() => repo.getBillingInfo()).thenAnswer((_) => _failed());
      when(
        () => repo.getNotificationPreferences(orgId: any(named: 'orgId')),
      ).thenAnswer((_) => _failed());
      when(
        () => repo.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) => _failed());
      when(
        () => repo.getOrganization(orgId: any(named: 'orgId')),
      ).thenAnswer(answerOrganization);
    });

    tearDown(() async {
      await locator.reset();
    });

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    ProviderContainer buildContainer() {
      final container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repo),
          workspaceProvider.overrideWith(_TestWorkspaceNotifier.new),
        ],
      );
      addTearDown(container.dispose);
      container.listen(userProfileNotifierProvider, (_, _) {});
      return container;
    }

    test('drops an older load for the same workspace after A, B, A', () async {
      // The first load (workspace A) is held up in secure storage.
      final slowRead = Completer<String?>();
      var storageReads = 0;
      when(() => storage.readData(any())).thenAnswer((_) {
        storageReads++;
        return storageReads == 1 ? slowRead.future : Future.value(null);
      });

      final container = buildContainer();
      await settle();

      final notifier = container.read(workspaceProvider.notifier);
      final workspaces = notifier as _TestWorkspaceNotifier;
      workspaces.select('B');
      await settle();
      workspaces.select('A');
      await settle();

      final before = container.read(userProfileNotifierProvider);
      expect(before.organization?.name, 'load 3');

      // The first load wakes up late. It is for workspace A, like the latest
      // load, but it is no longer the latest, so it must not overwrite it.
      slowRead.complete(null);
      await settle();

      final after = container.read(userProfileNotifierProvider);
      expect(after.organization?.name, 'load 3');
      expect(after.isLoading, isFalse);
    });

    test('applies the result of a load that is still the latest', () async {
      when(() => storage.readData(any())).thenAnswer((_) async => null);

      final container = buildContainer();
      await settle();

      final state = container.read(userProfileNotifierProvider);
      expect(state.organization?.name, 'load 1');
      expect(state.isLoading, isFalse);
    });
  });

  group('UserProfileNotifier.deleteOrganization', () {
    late MockUserProfileRepository repo;
    late MockSecureStorageService storage;

    setUp(() {
      repo = MockUserProfileRepository();
      storage = MockSecureStorageService();
      locator.registerSingleton<SecureStorageService>(storage);

      when(() => storage.readData(any())).thenAnswer((_) async => null);
      when(() => repo.getAccount()).thenAnswer((_) => _failed());
      when(() => repo.getSecuritySessions()).thenAnswer((_) => _failed());
      when(() => repo.getRolesAndPermissions()).thenAnswer((_) => _failed());
      when(() => repo.getBillingInfo()).thenAnswer((_) => _failed());
      when(
        () => repo.getNotificationPreferences(orgId: any(named: 'orgId')),
      ).thenAnswer((_) => _failed());
      when(
        () => repo.getTeamMembers(orgId: any(named: 'orgId')),
      ).thenAnswer((_) => _failed());
      when(
        () => repo.getOrganization(orgId: any(named: 'orgId')),
      ).thenAnswer((_) => _failed());
      when(
        () => repo.deleteOrganization(orgId: any(named: 'orgId')),
      ).thenAnswer((_) async => const Success<void>(null));
    });

    tearDown(() async {
      await locator.reset();
    });

    ProviderContainer buildContainer({required String? selected}) {
      final container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repo),
          workspaceProvider.overrideWith(
            () => _ListedWorkspaceNotifier(selected),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(userProfileNotifierProvider, (_, _) {});
      return container;
    }

    test('removes the deleted workspace from the switcher', () async {
      final container = buildContainer(selected: 'A');
      // Let the initial profile load finish first.
      await Future<void>.delayed(Duration.zero);

      await container
          .read(userProfileNotifierProvider.notifier)
          .deleteOrganization();

      verify(() => repo.deleteOrganization(orgId: 'A')).called(1);
      final workspaces = container.read(workspaceProvider);
      expect(workspaces.workspaces.map((w) => w.id), ['B']);
      expect(workspaces.selectedWorkspace?.id, 'B');
      expect(
        container.read(userProfileNotifierProvider).successMessage,
        'Organization deleted successfully.',
      );
    });

    test('makes no request when no workspace is selected', () async {
      final container = buildContainer(selected: null);
      // Let the initial profile load finish first.
      await Future<void>.delayed(Duration.zero);

      await container
          .read(userProfileNotifierProvider.notifier)
          .deleteOrganization();

      verifyNever(() => repo.deleteOrganization(orgId: any(named: 'orgId')));
      expect(
        container.read(userProfileNotifierProvider).error,
        'No organisation is selected.',
      );
    });
  });
}
