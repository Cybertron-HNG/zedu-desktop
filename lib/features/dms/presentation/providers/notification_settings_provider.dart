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

  /// Where this user's Do Not Disturb end time is remembered (null while
  /// signed out).
  String? _dndKey;

  /// Set once Do Not Disturb is turned on or off in this session, so a saved
  /// value that finishes loading later doesn't undo it.
  bool _dndChangedHere = false;

  @override
  NotificationSettings build() {
    ref.onDispose(() => _dndExpiry?.cancel());
    // Rebuilt for each signed-in user, so one account never sees another's
    // mutes or Do Not Disturb.
    final userId = dmPreferencesUserId(ref);
    final signedIn = userId != null && userId.isNotEmpty;
    _mutedKey = signedIn ? DmPreferencesStore.mutedKey(userId) : null;
    _dndKey = signedIn ? DmPreferencesStore.dndUntilKey(userId) : null;
    _dndChangedHere = false;
    final mutedKey = _mutedKey;
    if (mutedKey != null) _restoreMuted(mutedKey);
    final dndKey = _dndKey;
    if (dndKey != null) _restoreDnd(dndKey);
    return const NotificationSettings();
  }

  /// Puts back a pause that was still running when the app closed, and drops
  /// one that ran out meanwhile.
  Future<void> _restoreDnd(String key) async {
    final store = ref.read(dmPreferencesStoreProvider);
    final until = await store.readDndUntil(key);
    if (!ref.mounted || _dndKey != key || _dndChangedHere || until == null) {
      return;
    }
    final remaining = until.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      unawaited(store.writeDndUntil(key, null));
      return;
    }
    state = state.copyWith(dndUntil: until);
    _dndExpiry?.cancel();
    _dndExpiry = Timer(remaining, clearDndMode);
  }

  void _saveDnd() {
    _dndChangedHere = true;
    final key = _dndKey;
    if (key == null) return;
    unawaited(
      ref.read(dmPreferencesStoreProvider).writeDndUntil(key, state.dndUntil),
    );
  }

  Future<void> _restoreMuted(String key) async {
    final saved = await ref.read(dmPreferencesStoreProvider).read(key);
    if (!ref.mounted || _mutedKey != key || saved.isEmpty) return;
    // Keep anything muted while the saved list was loading.
    state = state.copyWith(
      mutedParticipantIds: {...saved, ...state.mutedParticipantIds},
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
    _saveDnd();
  }

  void clearDndMode() {
    _dndExpiry?.cancel();
    _dndExpiry = null;
    state = NotificationSettings(
      dndUntil: null,
      mutedParticipantIds: state.mutedParticipantIds,
    );
    _saveDnd();
  }

  void muteParticipant(String participantId) {
    final newMuted = Set<String>.from(state.mutedParticipantIds)
      ..add(participantId);
    state = state.copyWith(mutedParticipantIds: newMuted);
    _saveMuted();
  }

  void unmuteParticipant(String participantId) {
    final newMuted = Set<String>.from(state.mutedParticipantIds)
      ..remove(participantId);
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
