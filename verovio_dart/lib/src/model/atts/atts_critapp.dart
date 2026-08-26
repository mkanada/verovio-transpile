// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_critapp.h/.cpp
library;

import 'package:xml/xml.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.Crit` (mirrors `vrv::AttCrit`).
mixin AttCrit {
  /// `cause` — std::string.
  String? cause;
  bool get hasCause => cause != null;

  /// Mirrors `AttCrit::ReadCrit`.
  bool readCrit(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final causeRaw = element.get('cause');
    if (causeRaw != null) {
      cause = identityStr(causeRaw);
      if (removeAttr) element.remove('cause');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCrit::WriteCrit`.
  void writeCrit(XmlBuilder element) {
    if (hasCause) {
      element.attribute('cause', identityStr(cause!));
    }
  }

  /// Copies the `AttCrit` members from [other].
  void copyAttCrit(covariant AttCrit other) {
    cause = other.cause;
  }
}
