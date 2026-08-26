/// Port of small utilities from `vrv.h/cpp` (StringFormat, BaseEncodeInt…).
library;

const String base62Chars =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

/// Encode [value] in the given [base] (must be >10 and <63).
/// Mirrors `BaseEncodeInt`.
String baseEncodeInt(int value, int base) {
  assert(base > 10);
  assert(base < 63);

  String result = '';
  if (value < base) return base62Chars[value];

  while (value != 0) {
    result += base62Chars[value % base];
    value ~/= base;
  }

  return String.fromCharCodes(result.codeUnits.reversed);
}

/// Formats [message] replacing `{}` occurrences in order — a thin equivalent
/// of `StringFormat` used by the logging calls.
String formatMessage(String message, Iterable<Object?> args) {
  final StringBuffer result = StringBuffer();
  int argIndex = 0;
  for (int i = 0; i < message.length;) {
    if (i + 1 < message.length && message[i] == '{' && message[i + 1] == '}') {
      if (argIndex < args.length) {
        result.write(args.elementAt(argIndex));
        ++argIndex;
      }
      i += 2;
    } else {
      result.write(message[i]);
      ++i;
    }
  }
  return result.toString();
}

/// Extract the fragment of an ID reference ("#note-1" -> "note-1").
/// Mirrors `ExtractIDFragment`.
String extractIDFragment(String refID) {
  final pos = refID.lastIndexOf('#');
  if (pos >= 0 && pos < refID.length - 1) {
    refID = refID.substring(pos + 1);
  }
  return refID;
}
