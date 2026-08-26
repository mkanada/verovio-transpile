// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_stringtab.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.StaffDefVisTablature` (mirrors `vrv::AttStaffDefVisTablature`).
mixin AttStaffDefVisTablature {
  /// `tab.align` — data_VERTICALALIGNMENT.
  Verticalalignment? tabAlign;
  bool get hasTabAlign => tabAlign != null;

  /// `tab.anchorline` — char.
  int? tabAnchorline;
  bool get hasTabAnchorline => tabAnchorline != null;

  /// Mirrors `AttStaffDefVisTablature::ReadStaffDefVisTablature`.
  bool readStaffDefVisTablature(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tabAlignRaw = element.get('tab.align');
    if (tabAlignRaw != null) {
      tabAlign = strToVerticalalignment(tabAlignRaw);
      if (removeAttr) element.remove('tab.align');
      hasAttribute = true;
    }
    final tabAnchorlineRaw = element.get('tab.anchorline');
    if (tabAnchorlineRaw != null) {
      tabAnchorline = strToInt(tabAnchorlineRaw);
      if (removeAttr) element.remove('tab.anchorline');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffDefVisTablature::WriteStaffDefVisTablature`.
  void writeStaffDefVisTablature(XmlBuilder element) {
    if (hasTabAlign) {
      element.attribute('tab.align', verticalalignmentToStr(tabAlign!));
    }
    if (hasTabAnchorline) {
      element.attribute('tab.anchorline', intToStr(tabAnchorline!));
    }
  }

  /// Copies the `AttStaffDefVisTablature` members from [other].
  void copyAttStaffDefVisTablature(covariant AttStaffDefVisTablature other) {
    tabAlign = other.tabAlign;
    tabAnchorline = other.tabAnchorline;
  }
}

/// MEI attribute class for `att.Stringtab` (mirrors `vrv::AttStringtab`).
mixin AttStringtab {
  /// `tab.fing` — std::string.
  String? tabFing;
  bool get hasTabFing => tabFing != null;

  /// `tab.fret` — int.
  int? tabFret;
  bool get hasTabFret => tabFret != null;

  /// `tab.line` — char.
  int? tabLine;
  bool get hasTabLine => tabLine != null;

  /// `tab.string` — std::string.
  String? tabString;
  bool get hasTabString => tabString != null;

  /// `tab.course` — int.
  int? tabCourse;
  bool get hasTabCourse => tabCourse != null;

  /// Mirrors `AttStringtab::ReadStringtab`.
  bool readStringtab(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tabFingRaw = element.get('tab.fing');
    if (tabFingRaw != null) {
      tabFing = identityStr(tabFingRaw);
      if (removeAttr) element.remove('tab.fing');
      hasAttribute = true;
    }
    final tabFretRaw = element.get('tab.fret');
    if (tabFretRaw != null) {
      tabFret = strToInt(tabFretRaw);
      if (removeAttr) element.remove('tab.fret');
      hasAttribute = true;
    }
    final tabLineRaw = element.get('tab.line');
    if (tabLineRaw != null) {
      tabLine = strToInt(tabLineRaw);
      if (removeAttr) element.remove('tab.line');
      hasAttribute = true;
    }
    final tabStringRaw = element.get('tab.string');
    if (tabStringRaw != null) {
      tabString = identityStr(tabStringRaw);
      if (removeAttr) element.remove('tab.string');
      hasAttribute = true;
    }
    final tabCourseRaw = element.get('tab.course');
    if (tabCourseRaw != null) {
      tabCourse = strToInt(tabCourseRaw);
      if (removeAttr) element.remove('tab.course');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStringtab::WriteStringtab`.
  void writeStringtab(XmlBuilder element) {
    if (hasTabFing) {
      element.attribute('tab.fing', identityStr(tabFing!));
    }
    if (hasTabFret) {
      element.attribute('tab.fret', intToStr(tabFret!));
    }
    if (hasTabLine) {
      element.attribute('tab.line', intToStr(tabLine!));
    }
    if (hasTabString) {
      element.attribute('tab.string', identityStr(tabString!));
    }
    if (hasTabCourse) {
      element.attribute('tab.course', intToStr(tabCourse!));
    }
  }

  /// Copies the `AttStringtab` members from [other].
  void copyAttStringtab(covariant AttStringtab other) {
    tabFing = other.tabFing;
    tabFret = other.tabFret;
    tabLine = other.tabLine;
    tabString = other.tabString;
    tabCourse = other.tabCourse;
  }
}

/// MEI attribute class for `att.StringtabPosition` (mirrors `vrv::AttStringtabPosition`).
mixin AttStringtabPosition {
  /// `tab.pos` — int.
  int? tabPos;
  bool get hasTabPos => tabPos != null;

  /// Mirrors `AttStringtabPosition::ReadStringtabPosition`.
  bool readStringtabPosition(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tabPosRaw = element.get('tab.pos');
    if (tabPosRaw != null) {
      tabPos = strToInt(tabPosRaw);
      if (removeAttr) element.remove('tab.pos');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStringtabPosition::WriteStringtabPosition`.
  void writeStringtabPosition(XmlBuilder element) {
    if (hasTabPos) {
      element.attribute('tab.pos', intToStr(tabPos!));
    }
  }

  /// Copies the `AttStringtabPosition` members from [other].
  void copyAttStringtabPosition(covariant AttStringtabPosition other) {
    tabPos = other.tabPos;
  }
}

/// MEI attribute class for `att.StringtabTuning` (mirrors `vrv::AttStringtabTuning`).
mixin AttStringtabTuning {
  /// `tab.strings` — std::string.
  String? tabStrings;
  bool get hasTabStrings => tabStrings != null;

  /// `tab.courses` — std::string.
  String? tabCourses;
  bool get hasTabCourses => tabCourses != null;

  /// Mirrors `AttStringtabTuning::ReadStringtabTuning`.
  bool readStringtabTuning(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tabStringsRaw = element.get('tab.strings');
    if (tabStringsRaw != null) {
      tabStrings = identityStr(tabStringsRaw);
      if (removeAttr) element.remove('tab.strings');
      hasAttribute = true;
    }
    final tabCoursesRaw = element.get('tab.courses');
    if (tabCoursesRaw != null) {
      tabCourses = identityStr(tabCoursesRaw);
      if (removeAttr) element.remove('tab.courses');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStringtabTuning::WriteStringtabTuning`.
  void writeStringtabTuning(XmlBuilder element) {
    if (hasTabStrings) {
      element.attribute('tab.strings', identityStr(tabStrings!));
    }
    if (hasTabCourses) {
      element.attribute('tab.courses', identityStr(tabCourses!));
    }
  }

  /// Copies the `AttStringtabTuning` members from [other].
  void copyAttStringtabTuning(covariant AttStringtabTuning other) {
    tabStrings = other.tabStrings;
    tabCourses = other.tabCourses;
  }
}
