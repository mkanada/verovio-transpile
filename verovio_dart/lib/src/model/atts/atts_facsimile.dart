// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_facsimile.h/.cpp
library;

import 'package:xml/xml.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.Facsimile` (mirrors `vrv::AttFacsimile`).
mixin AttFacsimile {
  /// `facs` — std::string.
  String? facs;
  bool get hasFacs => facs != null;

  /// Mirrors `AttFacsimile::ReadFacsimile`.
  bool readFacsimile(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final facsRaw = element.get('facs');
    if (facsRaw != null) {
      facs = identityStr(facsRaw);
      if (removeAttr) element.remove('facs');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttFacsimile::WriteFacsimile`.
  void writeFacsimile(XmlBuilder element) {
    if (hasFacs) {
      element.attribute('facs', identityStr(facs!));
    }
  }

  /// Copies the `AttFacsimile` members from [other].
  void copyAttFacsimile(covariant AttFacsimile other) {
    facs = other.facs;
  }
}
