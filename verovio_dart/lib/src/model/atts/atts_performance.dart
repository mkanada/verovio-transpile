// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_performance.h/.cpp
library;

import 'package:xml/xml.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.Alignment` (mirrors `vrv::AttAlignment`).
mixin AttAlignment {
  /// `when` — std::string.
  String? when;
  bool get hasWhen => when != null;

  /// Mirrors `AttAlignment::ReadAlignment`.
  bool readAlignment(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final whenRaw = element.get('when');
    if (whenRaw != null) {
      when = identityStr(whenRaw);
      if (removeAttr) element.remove('when');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAlignment::WriteAlignment`.
  void writeAlignment(XmlBuilder element) {
    if (hasWhen) {
      element.attribute('when', identityStr(when!));
    }
  }

  /// Copies the `AttAlignment` members from [other].
  void copyAttAlignment(covariant AttAlignment other) {
    when = other.when;
  }
}
