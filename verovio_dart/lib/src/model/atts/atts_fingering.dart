// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_fingering.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.FingGrpLog` (mirrors `vrv::AttFingGrpLog`).
mixin AttFingGrpLog {
  /// `form` — fingGrpLog_FORM.
  FinggrplogForm? form;
  bool get hasForm => form != null;

  /// Mirrors `AttFingGrpLog::ReadFingGrpLog`.
  bool readFingGrpLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToFinggrplogForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttFingGrpLog::WriteFingGrpLog`.
  void writeFingGrpLog(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', finggrplogFormToStr(form!));
    }
  }

  /// Copies the `AttFingGrpLog` members from [other].
  void copyAttFingGrpLog(covariant AttFingGrpLog other) {
    form = other.form;
  }
}
