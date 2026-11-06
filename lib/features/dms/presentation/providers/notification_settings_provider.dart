import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class NotificationSettings {
  final DateTime? dndUntil;
  final Set<String> mutedParticipantIds;

  const NotificationSettings({
    this.dndUntil,
    this.mutedParticipantIds = const {},
  });

  bool get isDndActive => dndUntil != null && dndUntil!.isAfter(DateTime.now());
  bool isMuted(String participantId) =>
      mutedParticipantIds.contains(participantId);

  NotificationSettings copyWith({
    DateTime? dndUntil,
    Set<String>? mutedParticipantIds,
  }) {
    return NotificationSettings(
      dndUntil: dndUntil ?? this.dndUntil,
      mutedParticipantIds: mutedParticipantIds ?? this.mutedParticipantIds,
    );
  }
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  Timer? _dndExpiry;

  /// Where this user's mutes are remembered (null while signed out).
  String? _mutedKey;

  /// Unmuted while the saved mutes were still loading, so the restore must
  /// not bring them back.
  final Set<String> _unmutedWhileRestoring = {};

  @override
  NotificationSettings build() {
    ref.onDispose(() => _dndExpiry?.cancel());
    // Rebuilt for each signed-in user, so one account never sees another's mutes.
    final userId = dmPreferencesUserId(ref);
    _mutedKey = userId == null || userId.isEmpty
        ? null
        : DmPreferencesStore.mutedKey(userId);
    final key = _mutedKey;
    _unmutedWhileRestoring.clear();
    if (key != null) _restoreMuted(key);
    return const NotificationSettings();
  }

  Future<void> _restoreMuted(String key) async {
    final saved = await ref.read(dmPreferencesStoreProvider).read(key);
    if (!ref.mounted || _mutedKey != key) return;
    final unmuted = Set<String>.of(_unmutedWhileRestoring);
    _unmutedWhileRestoring.clear();
    if (saved.isEmpty) return;
    // Keep anything muted while the saved list was loading, and leave out
    // anything unmuted meanwhile: the latest action wins.
    state = state.copyWith(
      mutedParticipantIds: {
        ...saved.difference(unmuted),
        ...state.mutedParticipantIds,
      },
    );
  }

  void _saveMuted() {
    final key = _mutedKey;
    if (key == null) return;
    unawaited(
      ref
          .read(dmPreferencesStoreProvider)
          .write(key, state.mutedParticipantIds),
    );
  }

  /// Pauses notifications; the pause ends by itself when it runs out.
  void setDndMode(Duration duration) {
    state = state.copyWith(dndUntil: DateTime.now().add(duration));
    _dndExpiry?.cancel();
    _dndExpiry = Timer(duration, clearDndMode);
  }

  void clearDndMode() {
    _dndExpiry?.cancel();
    _dndExpiry = null;
    state = NotificationSettings(
      dndUntil: null,
      mutedParticipantIds: state.mutedParticipantIds,
    );
  }

  void muteParticipant(String participantId) {
    final newMuted = Set<String>.from(state.mutedParticipantIds)
      ..add(participantId);
    _unmutedWhileRestoring.remove(participantId);
    state = state.copyWith(mutedParticipantIds: newMuted);
    _saveMuted();
  }

  void unmuteParticipant(String participantId) {
    final newMuted = Set<String>.from(state.mutedParticipantIds)
      ..remove(participantId);
    _unmutedWhileRestoring.add(participantId);
    state = state.copyWith(mutedParticipantIds: newMuted);
    _saveMuted();
  }

  bool isMuted(String participantId) {
    return state.mutedParticipantIds.contains(participantId);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );
