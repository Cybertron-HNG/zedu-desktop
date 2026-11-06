/// Returns the first user-perceived character of [value] for use as an
/// avatar initial.
///
/// Uses runes rather than [String.substring] so a leading emoji (a surrogate
/// pair) is returned whole instead of being split into an invalid glyph.
/// Returns [fallback] when [value] is null, empty, or whitespace.
String initialOf(String? value, {String fallback = '?'}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return fallback;
  final runes = text.runes;
  if (runes.isEmpty) return fallback;
  return String.fromCharCode(runes.first).toUpperCase();
}
