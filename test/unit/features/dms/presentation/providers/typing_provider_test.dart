import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('TypingState', () {
    test('empty state returns empty label', () {
      const state = TypingState();
      expect(state.isEmpty, isTrue);
      expect(state.isNotEmpty, isFalse);
      expect(state.label, '');
    });

    test('single user formats label correctly', () {
      final state = TypingState(
        users: [
          TypingUser(
            userId: '1',
            username: 'Ada Lovelace',
            timestamp: DateTime.now(),
          ),
        ],
      );
      expect(state.label, 'Ada Lovelace is typing…');
    });

    test('two users formats label with "and"', () {
      final state = TypingState(
        users: [
          TypingUser(
            userId: '1',
            username: 'Ada',
            timestamp: DateTime.now(),
          ),
          TypingUser(
            userId: '2',
            username: 'Bob',
            timestamp: DateTime.now(),
          ),
        ],
      );
      expect(state.label, 'Ada and Bob are typing…');
    });

    test('three or more users formats as "Several people are typing…"', () {
      final state = TypingState(
        users: [
          TypingUser(
            userId: '1',
            username: 'Ada',
            timestamp: DateTime.now(),
          ),
          TypingUser(
            userId: '2',
            username: 'Bob',
            timestamp: DateTime.now(),
          ),
          TypingUser(
            userId: '3',
            username: 'Charlie',
            timestamp: DateTime.now(),
          ),
        ],
      );
      expect(state.label, 'Several people are typing…');
    });
  });

  group('TypingNotifier', () {
    test('updates state on setUserTyping', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(typingProvider('chan-1'));
      expect(notifier.isEmpty, isTrue);

      notifier.setUserTyping(
        userId: 'u1',
        username: 'Alice',
        isTyping: true,
      );

      expect(notifier.users.length, 1);
      expect(notifier.label, 'Alice is typing…');

      notifier.setUserTyping(
        userId: 'u1',
        username: 'Alice',
        isTyping: false,
      );

      expect(notifier.isEmpty, isTrue);
      expect(notifier.label, '');
    });

    test('ignores self typing if matches auth current user', () {
      final fakeUser = User(
        id: 'self-id',
        firstName: 'My',
        lastName: 'Self',
        email: 'me@test.com',
        phone: '1234567890',
        username: 'myself',
        isVerified: true,
        isOnboarded: true,
        createdAt: DateTime.now(),
        currentOrg: 'org-1',
        currentOrganisationSlug: 'org-slug',
        avatarUrl: '',
        defaultAvatarUrl: '',
      );

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(AuthState(user: fakeUser)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(typingProvider('chan-1'));
      notifier.setUserTyping(
        userId: 'self-id',
        username: 'myself',
        isTyping: true,
      );

      expect(notifier.isEmpty, isTrue);
    });

    test('clear resets state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(typingProvider('chan-1'));
      notifier.setUserTyping(
        userId: 'u1',
        username: 'Alice',
        isTyping: true,
      );
      expect(notifier.isNotEmpty, isTrue);

      notifier.clear();
      expect(notifier.isEmpty, isTrue);
    });
  });
}

class _FakeAuthNotifier extends AuthNotifier {
  final AuthState _initial;
  _FakeAuthNotifier(this._initial);

  @override
  AuthState build() => _initial;
}
