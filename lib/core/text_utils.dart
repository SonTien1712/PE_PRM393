const _from =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
final _to = '${'a' * 17}${'e' * 11}${'i' * 5}${'o' * 17}${'u' * 11}${'y' * 5}d';

/// Lowercases and removes Vietnamese diacritics for search, including NFD marks.
String normalizeVi(String input) {
  final result = StringBuffer();
  for (final rune in input.toLowerCase().trim().runes) {
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final character = String.fromCharCode(rune);
    final index = _from.indexOf(character);
    result.write(index >= 0 ? _to[index] : character);
  }
  return result.toString();
}

String csvEscape(String value) {
  var escaped = value;
  if (escaped.isNotEmpty && '=+-@'.contains(escaped[0])) escaped = "'$escaped";
  if (escaped.contains(RegExp(r'[",\n\r]'))) {
    escaped = '"${escaped.replaceAll('"', '""')}"';
  }
  return escaped;
}
