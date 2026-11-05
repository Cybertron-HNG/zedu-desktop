import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class TypingUser {
  final String userId;
  final String username;
  final DateTime timestamp;

  const TypingUser({
    required this.userId,
    required this.username,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}

class TypingState {
  final List<TypingUser> users;

  const TypingState({this.users = const []});

  bool get isEmpty => users.isEmpty;
  bool get isNotEmpty => users.isNotEmpty;

  /// Formatted indicator text matching web client parity:
  /// - 1 user: "X is typing…"
  /// - 2 users: "X and Y are typing…"
  /// - 3+ users: "Several people are typing…"
  String get label {
    final names =
        users.map((u) => u.username.trim()).where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return '';
    if (names.length == 1) {
      return '${names[0]} is typing…';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing…';
    } else {
      return 'Several people are typing…';
    }
  }
}

class TypingNotifier extends ChangeNotifier {
  final String channelId;
  final Ref ref;

  TypingState _state = const TypingState();
  TypingState get state => _state;

  List<TypingUser> get users => _state.users;
  bool get isEmpty => _state.isEmpty;
  bool get isNotEmpty => _state.isNotEmpty;
  String get label => _state.label;

  Timer? _expireTimer;
  static const int expireMs = 4000;

  TypingNotifier(this.channelId, this.ref);

  @override
  void dispose() {
    _expireTimer?.cancel();
    super.dispose();
  }

  void setUserTyping({
    required String userId,
    required String username,
    required bool isTyping,
  }) {
    String? currentUserId;
    try {
      currentUserId = ref.read(authNotifierProvider).user?.id;
    } catch (_) {
      currentUserId = null;
    }
    if (currentUserId != null && userId == currentUserId) return;

    final currentUsers = List<TypingUser>.from(_state.users);
    currentUsers.removeWhere((u) => u.userId == userId);

    if (isTyping) {
      currentUsers.add(TypingUser(
        userId: userId,
        username: username,
        timestamp: DateTime.now(),
      ));
    }

    _state = TypingState(users: currentUsers);
    notifyListeners();
    _restartExpiryTimer();
  }

  void _restartExpiryTimer() {
    _expireTimer?.cancel();
    if (_state.isEmpty) return;

    _expireTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final fresh = _state.users.where((u) {
        return now.difference(u.timestamp).inMilliseconds < expireMs;
      }).toList();

      if (fresh.length != _state.users.length) {
        _state = TypingState(users: fresh);
        notifyListeners();
      }

      if (_state.isEmpty) {
        timer.cancel();
      }
    });
  }

  void clear() {
    _expireTimer?.cancel();
    _state = const TypingState();
    notifyListeners();
  }
}

final typingProvider = ChangeNotifierProvider.autoDispose
    .family<TypingNotifier, String>(
      (ref, channelId) => TypingNotifier(channelId, ref),
    );
