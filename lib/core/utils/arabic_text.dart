import 'package:arabic_reshaper/arabic_reshaper.dart';

/// FFmpeg's drawtext does NOT shape Arabic. We reshape connected letters
/// with arabic_reshaper, and for a mostly-Arabic run we reverse it into
/// visual order so drawtext (an LTR renderer) displays it correctly.
///
/// NOTE: mixed Arabic+Latin/digits captions need full bidi (e.g. python-bidi
/// logic) — for captions we recommend pure-Arabic or pure-Latin strings.
String shapeArabic(String input) {
  if (input.trim().isEmpty) return input;
  try {
    var reshaped = ArabicReshaper().reshape(input);
    if (_mostlyArabic(input)) {
      reshaped = String.fromCharCodes(reshaped.runes.toList().reversed);
    }
    return reshaped;
  } catch (_) {
    return input;
  }
}

bool _mostlyArabic(String s) {
  final total = s.replaceAll(RegExp(r'\s'), '').length;
  if (total == 0) return false;
  final arabic = RegExp(r'[\u0600-\u06FF]').allMatches(s).length;
  return arabic / total > 0.5;
}

/// Escape characters that break the drawtext filter argument.
String escapeDrawtext(String s) => s
    .replaceAll('\\', '\\\\')
    .replaceAll("'", "\\'")
    .replaceAll(':', '\\:')
    .replaceAll(',', '\\,')
    .replaceAll('%', '\\%')
    .replaceAll('[', '\\[')
    .replaceAll(']', '\\]');
