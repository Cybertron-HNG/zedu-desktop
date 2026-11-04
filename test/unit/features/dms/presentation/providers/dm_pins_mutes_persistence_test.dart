import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

/// A signed-in user, without the real session restore.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this.userId);
  final String userId;

  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: userId,
      firstName: 'Test',
      lastName: 'User',
      email: '$userId@example.com',
      phone: '',
      username: userId,
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'org',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

void main() {
  // What the app keeps on disk between launches.
  late Map<String, String> disk;

  setUp(() {
    disk = {};
    final storage = MockSecureStorageService();
    when(
      () => storage.readData(any()),
    ).thenAnswer((i) async => disk[i.positionalArguments.first as String]);
    when(() => storage.writeData(any(), any())).thenAnswer((i) async {
      disk[i.positionalArguments[0] as String] =
          i.positionalArguments[1] as String;
    });
    when(() => storage.deleteValue(any())).thenAnswer((i) async {
      disk.remove(i.positionalArguments.first as String);
    });
    locator.registerSingleton<SecureStorageService>(storage);
  });

  tearDown(() => locator.reset());

  /// One app launch for [userId].
  ProviderContainer launch(String userId) {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => _FakeAuthNotifier(userId)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settle() => pumpEventQueue();

  test('a pinned DM is still pinned after a restart', () async {
    final first = launch('u1');
    first
        .read(dmConversationActionsProvider.notifier)
        .togglePinned('channel-a');
    await settle();
    first.dispose();

    final second = launch('u1');
    second.read(dmConversationActionsProvider);
    await settle();

    expect(second.read(dmConversationActionsProvider).pinnedIds, {'channel-a'});
  });

  test('an unpinned DM stays unpinned after a restart', () async {
    final first = launch('u1');
    final actions = first.read(dmConversationActionsProvider.notifier);
    actions.togglePinned('channel-a');
    actions.togglePinned('channel-a');
    await settle();
    first.dispose();

    final second = launch('u1');
    second.read(dmConversationActionsProvider);
    await settle();

    expect(second.read(dmConversationActionsProvider).pinnedIds, isEmpty);
  });

  test(
    'a muted person is still muted after a restart, and unmuting sticks',
    () async {
      final first = launch('u1');
      final settings = first.read(notificationSettingsProvider.notifier);
      settings.muteParticipant('person-1');
      settings.muteParticipant('person-2');
      settings.unmuteParticipant('person-2');
      await settle();
      first.dispose();

      final second = launch('u1');
      second.read(notificationSettingsProvider);
      await settle();

      final restored = second.read(notificationSettingsProvider);
      expect(restored.isMuted('person-1'), isTrue);
      expect(restored.isMuted('person-2'), isFalse);
    },
  );

  test("another account on the same computer doesn't get them", () async {
    final first = launch('u1');
    first
        .read(dmConversationActionsProvider.notifier)
        .togglePinned('channel-a');
    first
        .read(notificationSettingsProvider.notifier)
        .muteParticipant('person-1');
    await settle();
    first.dispose();

    final other = launch('u2');
    other.read(dmConversationActionsProvider);
    other.read(notificationSettingsProvider);
    await settle();

    expect(other.read(dmConversationActionsProvider).pinnedIds, isEmpty);
    expect(
      other.read(notificationSettingsProvider).isMuted('person-1'),
      isFalse,
    );
  });

  group('Do Not Disturb', () {
    test(
      'a running pause is still on after a restart, with the same end',
      () async {
        final first = launch('u1');
        first
            .read(notificationSettingsProvider.notifier)
            .setDndMode(const Duration(hours: 2));
        final end = first.read(notificationSettingsProvider).dndUntil!;
        await settle();
        first.dispose();

        final second = launch('u1');
        second.read(notificationSettingsProvider);
        await settle();

        final restored = second.read(notificationSettingsProvider);
        expect(restored.isDndActive, isTrue);
        expect(
          restored.dndUntil!.difference(end).inSeconds.abs(),
          lessThanOrEqualTo(1),
        );
      },
    );

    test('turning it off sticks after a restart', () async {
      final first = launch('u1');
      final settings = first.read(notificationSettingsProvider.notifier);
      settings.setDndMode(const Duration(hours: 2));
      settings.clearDndMode();
      await settle();
      first.dispose();

      final second = launch('u1');
      second.read(notificationSettingsProvider);
      await settle();

      expect(second.read(notificationSettingsProvider).isDndActive, isFalse);
      expect(disk.containsKey(DmPreferencesStore.dndUntilKey('u1')), isFalse);
    });

    test('a pause that ended while the app was closed is dropped', () async {
      disk[DmPreferencesStore.dndUntilKey('u1')] = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toUtc()
          .toIso8601String();

      final container = launch('u1');
      container.read(notificationSettingsProvider);
      await settle();

      expect(container.read(notificationSettingsProvider).isDndActive, isFalse);
      expect(disk.containsKey(DmPreferencesStore.dndUntilKey('u1')), isFalse);
    });

    test(
      'a pause set right after launch is not undone by the saved one',
      () async {
        disk[DmPreferencesStore.dndUntilKey('u1')] = DateTime.now()
            .add(const Duration(hours: 8))
            .toUtc()
            .toIso8601String();

        final container = launch('u1');
        container
            .read(notificationSettingsProvider.notifier)
            .setDndMode(const Duration(minutes: 30));
        await settle();

        final until = container.read(notificationSettingsProvider).dndUntil!;
        expect(
          until.difference(DateTime.now()).inMinutes,
          lessThanOrEqualTo(30),
        );
      },
    );

    test("another account on the same computer doesn't get it", () async {
      final first = launch('u1');
      first
          .read(notificationSettingsProvider.notifier)
          .setDndMode(const Duration(hours: 2));
      await settle();
      first.dispose();

      final other = launch('u2');
      other.read(notificationSettingsProvider);
      await settle();

      expect(other.read(notificationSettingsProvider).isDndActive, isFalse);
    });
  });
}
