import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

// Avoids the network call that the real WorkspaceNotifier starts in build().
class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

void main() {
  const failure = ApiFailure(message: 'offline', kind: ApiFailureKind.network);

  late MockUserProfileRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockUserProfileRepository();
    when(
      () => repository.getAccount(),
    ).thenAnswer((_) async => const Failure<ProfileAccount>(failure));
    when(
      () => repository.getNotificationPreferences(),
    ).thenAnswer((_) async => const Failure<NotificationPreferences>(failure));
    when(
      () => repository.getSecuritySessions(),
    ).thenAnswer((_) async => const Failure<List<SecuritySession>>(failure));
    when(
      () => repository.getOrganization(),
    ).thenAnswer((_) async => const Failure<OrganizationProfile>(failure));
    when(
      () => repository.getTeamMembers(orgId: any(named: 'orgId')),
    ).thenAnswer((_) async => const Failure<List<TeamMember>>(failure));
    when(
      () => repository.getRolesAndPermissions(),
    ).thenAnswer((_) async => const Failure<List<RolePermission>>(failure));
    when(
      () => repository.getBillingInfo(),
    ).thenAnswer((_) async => const Failure<BillingInfo>(failure));

    container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(repository),
        workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
      ],
    );
    addTearDown(container.dispose);
  });

  group('UserProfileNotifier', () {
    test(
      'creating the notifier does not throw and starts in loading state',
      () {
        expect(
          () => container.read(userProfileNotifierProvider),
          returnsNormally,
        );
        expect(container.read(userProfileNotifierProvider).isLoading, isTrue);
      },
    );

    test('loads the profile data after the initial state is set', () async {
      container.read(userProfileNotifierProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      verify(() => repository.getAccount()).called(1);
      verify(() => repository.getNotificationPreferences()).called(1);
      verify(() => repository.getSecuritySessions()).called(1);
      verify(() => repository.getOrganization()).called(1);

      final state = container.read(userProfileNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });
  });
}
