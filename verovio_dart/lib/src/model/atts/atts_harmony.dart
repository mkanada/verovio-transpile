// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_harmony.h/.cpp
library;

import 'package:xml/xml.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.HarmLog` (mirrors `vrv::AttHarmLog`).
mixin AttHarmLog {
  /// `chordref` — std::string.
  String? chordref;
  bool get hasChordref => chordref != null;

  /// Mirrors `AttHarmLog::ReadHarmLog`.
  bool readHarmLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final chordrefRaw = element.get('chordref');
    if (chordrefRaw != null) {
      chordref = identityStr(chordrefRaw);
      if (removeAttr) element.remove('chordref');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHarmLog::WriteHarmLog`.
  void writeHarmLog(XmlBuilder element) {
    if (hasChordref) {
      element.attribute('chordref', identityStr(chordref!));
    }
  }

  /// Copies the `AttHarmLog` members from [other].
  void copyAttHarmLog(covariant AttHarmLog other) {
    chordref = other.chordref;
  }
}
