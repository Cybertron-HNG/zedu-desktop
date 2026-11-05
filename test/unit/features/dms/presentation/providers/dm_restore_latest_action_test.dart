import 'dart:async';

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
  // While set, reads wait for it, like a slow keychain at launch.
  Completer<void>? slowRead;

  setUp(() {
    disk = {};
    slowRead = null;
    final storage = MockSecureStorageService();
    when(() => storage.readData(any())).thenAnswer((i) async {
      final value = disk[i.positionalArguments.first as String];
      await slowRead?.future;
      return value;
    });
    when(() => storage.writeData(any(), any())).thenAnswer((i) async {
      disk[i.positionalArguments[0] as String] =
          i.positionalArguments[1] as String;
    });
    locator.registerSingleton<SecureStorageService>(storage);
  });

  tearDown(() => locator.reset());

  ProviderContainer launch() {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => _FakeAuthNotifier('u1')),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settle() => pumpEventQueue();

  test('unpinning before the saved pins load keeps it unpinned', () async {
    final first = launch();
    first.read(dmConversationActionsProvider.notifier)
      ..togglePinned('channel-a')
      ..togglePinned('channel-b');
    await settle();
    first.dispose();

    slowRead = Completer<void>();
    final second = launch();
    final pins = second.read(dmConversationActionsProvider.notifier);
    pins
      ..togglePinned('channel-a') // pinned now, so the saved restore is pending
      ..togglePinned('channel-a'); // and unpinned again before it lands
    slowRead!.complete();
    await settle();

    expect(second.read(dmConversationActionsProvider).pinnedIds, {'channel-b'});
  });

  test('unmuting before the saved mutes load keeps it unmuted', () async {
    final first = launch();
    first.read(notificationSettingsProvider.notifier)
      ..muteParticipant('ada')
      ..muteParticipant('grace');
    await settle();
    first.dispose();

    slowRead = Completer<void>();
    final second = launch();
    second.read(notificationSettingsProvider.notifier).unmuteParticipant('ada');
    slowRead!.complete();
    await settle();

    expect(second.read(notificationSettingsProvider).mutedParticipantIds, {
      'grace',
    });
  });

  test('pinning before the saved pins load keeps both', () async {
    final first = launch();
    first
        .read(dmConversationActionsProvider.notifier)
        .togglePinned('channel-a');
    await settle();
    first.dispose();

    slowRead = Completer<void>();
    final second = launch();
    second
        .read(dmConversationActionsProvider.notifier)
        .togglePinned('channel-c');
    slowRead!.complete();
    await settle();

    expect(second.read(dmConversationActionsProvider).pinnedIds, {
      'channel-a',
      'channel-c',
    });
  });
}
