/// Voice notes sent from the home composer are a text marker, optionally with
/// the recording's length in whole seconds: `[Voice Note Attached:12]`.
/// Older messages carry the bare `[Voice Note Attached]` with no length.
final RegExp _voiceNoteMarker = RegExp(r'\[Voice Note Attached(?::(\d+))?\]');

/// The marker to send for a recording of [length].
String voiceNoteMarker(Duration length) =>
    '[Voice Note Attached:${length.inSeconds}]';

/// Whether [text] contains a voice-note marker, with or without a length.
bool hasVoiceNoteMarker(String text) => _voiceNoteMarker.hasMatch(text);

/// The recording length stored in [text]'s voice-note marker, or null when
/// there is no marker or it predates lengths being recorded.
Duration? voiceNoteLength(String text) {
  final seconds = _voiceNoteMarker.firstMatch(text)?.group(1);
  if (seconds == null) return null;
  final value = int.tryParse(seconds);
  return value == null ? null : Duration(seconds: value);
}

/// A clock-style length: `0:05`, `2:05`, `1:02:03`.
String formatClockDuration(Duration length) {
  final total = length.isNegative ? 0 : length.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = (total % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}
