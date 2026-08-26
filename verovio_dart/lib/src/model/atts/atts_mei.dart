// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_mei.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.NotationType` (mirrors `vrv::AttNotationType`).
mixin AttNotationType {
  /// `notationtype` — data_NOTATIONTYPE.
  Notationtype? notationtype;
  bool get hasNotationtype => notationtype != null;

  /// `notationsubtype` — std::string.
  String? notationsubtype;
  bool get hasNotationsubtype => notationsubtype != null;

  /// Mirrors `AttNotationType::ReadNotationType`.
  bool readNotationType(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final notationtypeRaw = element.get('notationtype');
    if (notationtypeRaw != null) {
      notationtype = strToNotationtype(notationtypeRaw);
      if (removeAttr) element.remove('notationtype');
      hasAttribute = true;
    }
    final notationsubtypeRaw = element.get('notationsubtype');
    if (notationsubtypeRaw != null) {
      notationsubtype = identityStr(notationsubtypeRaw);
      if (removeAttr) element.remove('notationsubtype');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNotationType::WriteNotationType`.
  void writeNotationType(XmlBuilder element) {
    if (hasNotationtype) {
      element.attribute('notationtype', notationtypeToStr(notationtype!));
    }
    if (hasNotationsubtype) {
      element.attribute('notationsubtype', identityStr(notationsubtype!));
    }
  }

  /// Copies the `AttNotationType` members from [other].
  void copyAttNotationType(covariant AttNotationType other) {
    notationtype = other.notationtype;
    notationsubtype = other.notationsubtype;
  }
}
