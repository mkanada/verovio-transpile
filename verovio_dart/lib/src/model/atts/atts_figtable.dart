// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_figtable.h/.cpp
library;

import 'package:xml/xml.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.Tabular` (mirrors `vrv::AttTabular`).
mixin AttTabular {
  /// `colspan` — int.
  int? colspan;
  bool get hasColspan => colspan != null;

  /// `rowspan` — int.
  int? rowspan;
  bool get hasRowspan => rowspan != null;

  /// Mirrors `AttTabular::ReadTabular`.
  bool readTabular(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final colspanRaw = element.get('colspan');
    if (colspanRaw != null) {
      colspan = strToInt(colspanRaw);
      if (removeAttr) element.remove('colspan');
      hasAttribute = true;
    }
    final rowspanRaw = element.get('rowspan');
    if (rowspanRaw != null) {
      rowspan = strToInt(rowspanRaw);
      if (removeAttr) element.remove('rowspan');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTabular::WriteTabular`.
  void writeTabular(XmlBuilder element) {
    if (hasColspan) {
      element.attribute('colspan', intToStr(colspan!));
    }
    if (hasRowspan) {
      element.attribute('rowspan', intToStr(rowspan!));
    }
  }

  /// Copies the `AttTabular` members from [other].
  void copyAttTabular(covariant AttTabular other) {
    colspan = other.colspan;
    rowspan = other.rowspan;
  }
}
