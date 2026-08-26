// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_usersymbols.h/.cpp
library;

import 'package:xml/xml.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.AltSym` (mirrors `vrv::AttAltSym`).
mixin AttAltSym {
  /// `altsym` — std::string.
  String? altsym;
  bool get hasAltsym => altsym != null;

  /// Mirrors `AttAltSym::ReadAltSym`.
  bool readAltSym(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final altsymRaw = element.get('altsym');
    if (altsymRaw != null) {
      altsym = identityStr(altsymRaw);
      if (removeAttr) element.remove('altsym');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAltSym::WriteAltSym`.
  void writeAltSym(XmlBuilder element) {
    if (hasAltsym) {
      element.attribute('altsym', identityStr(altsym!));
    }
  }

  /// Copies the `AttAltSym` members from [other].
  void copyAttAltSym(covariant AttAltSym other) {
    altsym = other.altsym;
  }
}

/// MEI attribute class for `att.AnchoredTextLog` (mirrors `vrv::AttAnchoredTextLog`).
mixin AttAnchoredTextLog {
  /// `func` — std::string.
  String? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttAnchoredTextLog::ReadAnchoredTextLog`.
  bool readAnchoredTextLog(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = identityStr(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAnchoredTextLog::WriteAnchoredTextLog`.
  void writeAnchoredTextLog(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', identityStr(func!));
    }
  }

  /// Copies the `AttAnchoredTextLog` members from [other].
  void copyAttAnchoredTextLog(covariant AttAnchoredTextLog other) {
    func = other.func;
  }
}

/// MEI attribute class for `att.CurveLog` (mirrors `vrv::AttCurveLog`).
mixin AttCurveLog {
  /// `func` — std::string.
  String? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttCurveLog::ReadCurveLog`.
  bool readCurveLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = identityStr(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCurveLog::WriteCurveLog`.
  void writeCurveLog(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', identityStr(func!));
    }
  }

  /// Copies the `AttCurveLog` members from [other].
  void copyAttCurveLog(covariant AttCurveLog other) {
    func = other.func;
  }
}

/// MEI attribute class for `att.LineLog` (mirrors `vrv::AttLineLog`).
mixin AttLineLog {
  /// `func` — std::string.
  String? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttLineLog::ReadLineLog`.
  bool readLineLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = identityStr(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLineLog::WriteLineLog`.
  void writeLineLog(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', identityStr(func!));
    }
  }

  /// Copies the `AttLineLog` members from [other].
  void copyAttLineLog(covariant AttLineLog other) {
    func = other.func;
  }
}
