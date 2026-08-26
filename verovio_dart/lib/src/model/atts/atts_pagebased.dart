// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_pagebased.h/.cpp
library;

import 'package:xml/xml.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.Margins` (mirrors `vrv::AttMargins`).
mixin AttMargins {
  /// `topmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? topmar;
  bool get hasTopmar => topmar != null;

  /// `botmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? botmar;
  bool get hasBotmar => botmar != null;

  /// `leftmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? leftmar;
  bool get hasLeftmar => leftmar != null;

  /// `rightmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? rightmar;
  bool get hasRightmar => rightmar != null;

  /// Mirrors `AttMargins::ReadMargins`.
  bool readMargins(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final topmarRaw = element.get('topmar');
    if (topmarRaw != null) {
      topmar = strToMeasurementunsigned(topmarRaw);
      if (removeAttr) element.remove('topmar');
      hasAttribute = true;
    }
    final botmarRaw = element.get('botmar');
    if (botmarRaw != null) {
      botmar = strToMeasurementunsigned(botmarRaw);
      if (removeAttr) element.remove('botmar');
      hasAttribute = true;
    }
    final leftmarRaw = element.get('leftmar');
    if (leftmarRaw != null) {
      leftmar = strToMeasurementunsigned(leftmarRaw);
      if (removeAttr) element.remove('leftmar');
      hasAttribute = true;
    }
    final rightmarRaw = element.get('rightmar');
    if (rightmarRaw != null) {
      rightmar = strToMeasurementunsigned(rightmarRaw);
      if (removeAttr) element.remove('rightmar');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMargins::WriteMargins`.
  void writeMargins(XmlBuilder element) {
    if (hasTopmar) {
      element.attribute('topmar', measurementunsignedToStr(topmar!));
    }
    if (hasBotmar) {
      element.attribute('botmar', measurementunsignedToStr(botmar!));
    }
    if (hasLeftmar) {
      element.attribute('leftmar', measurementunsignedToStr(leftmar!));
    }
    if (hasRightmar) {
      element.attribute('rightmar', measurementunsignedToStr(rightmar!));
    }
  }

  /// Copies the `AttMargins` members from [other].
  void copyAttMargins(covariant AttMargins other) {
    topmar = other.topmar;
    botmar = other.botmar;
    leftmar = other.leftmar;
    rightmar = other.rightmar;
  }
}
