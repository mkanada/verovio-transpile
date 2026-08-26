// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_cmnornaments.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.MordentLog` (mirrors `vrv::AttMordentLog`).
mixin AttMordentLog {
  /// `form` — mordentLog_FORM.
  MordentlogForm? form;
  bool get hasForm => form != null;

  /// `long` — data_BOOLEAN.
  bool? long;
  bool get hasLong => long != null;

  /// Mirrors `AttMordentLog::ReadMordentLog`.
  bool readMordentLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToMordentlogForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    final longRaw = element.get('long');
    if (longRaw != null) {
      long = strToBoolean(longRaw);
      if (removeAttr) element.remove('long');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMordentLog::WriteMordentLog`.
  void writeMordentLog(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', mordentlogFormToStr(form!));
    }
    if (hasLong) {
      element.attribute('long', booleanToStr(long!));
    }
  }

  /// Copies the `AttMordentLog` members from [other].
  void copyAttMordentLog(covariant AttMordentLog other) {
    form = other.form;
    long = other.long;
  }
}

/// MEI attribute class for `att.OrnamPresent` (mirrors `vrv::AttOrnamPresent`).
mixin AttOrnamPresent {
  /// `ornam` — std::string.
  String? ornam;
  bool get hasOrnam => ornam != null;

  /// Mirrors `AttOrnamPresent::ReadOrnamPresent`.
  bool readOrnamPresent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final ornamRaw = element.get('ornam');
    if (ornamRaw != null) {
      ornam = identityStr(ornamRaw);
      if (removeAttr) element.remove('ornam');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOrnamPresent::WriteOrnamPresent`.
  void writeOrnamPresent(XmlBuilder element) {
    if (hasOrnam) {
      element.attribute('ornam', identityStr(ornam!));
    }
  }

  /// Copies the `AttOrnamPresent` members from [other].
  void copyAttOrnamPresent(covariant AttOrnamPresent other) {
    ornam = other.ornam;
  }
}

/// MEI attribute class for `att.OrnamentAccid` (mirrors `vrv::AttOrnamentAccid`).
mixin AttOrnamentAccid {
  /// `accidupper` — data_ACCIDENTAL_WRITTEN.
  AccidentalWritten? accidupper;
  bool get hasAccidupper => accidupper != null;

  /// `accidlower` — data_ACCIDENTAL_WRITTEN.
  AccidentalWritten? accidlower;
  bool get hasAccidlower => accidlower != null;

  /// Mirrors `AttOrnamentAccid::ReadOrnamentAccid`.
  bool readOrnamentAccid(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final accidupperRaw = element.get('accidupper');
    if (accidupperRaw != null) {
      accidupper = strToAccidentalWritten(accidupperRaw);
      if (removeAttr) element.remove('accidupper');
      hasAttribute = true;
    }
    final accidlowerRaw = element.get('accidlower');
    if (accidlowerRaw != null) {
      accidlower = strToAccidentalWritten(accidlowerRaw);
      if (removeAttr) element.remove('accidlower');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOrnamentAccid::WriteOrnamentAccid`.
  void writeOrnamentAccid(XmlBuilder element) {
    if (hasAccidupper) {
      element.attribute('accidupper', accidentalWrittenToStr(accidupper!));
    }
    if (hasAccidlower) {
      element.attribute('accidlower', accidentalWrittenToStr(accidlower!));
    }
  }

  /// Copies the `AttOrnamentAccid` members from [other].
  void copyAttOrnamentAccid(covariant AttOrnamentAccid other) {
    accidupper = other.accidupper;
    accidlower = other.accidlower;
  }
}

/// MEI attribute class for `att.TurnLog` (mirrors `vrv::AttTurnLog`).
mixin AttTurnLog {
  /// `delayed` — data_BOOLEAN.
  bool? delayed;
  bool get hasDelayed => delayed != null;

  /// `form` — turnLog_FORM.
  TurnlogForm? form;
  bool get hasForm => form != null;

  /// Mirrors `AttTurnLog::ReadTurnLog`.
  bool readTurnLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final delayedRaw = element.get('delayed');
    if (delayedRaw != null) {
      delayed = strToBoolean(delayedRaw);
      if (removeAttr) element.remove('delayed');
      hasAttribute = true;
    }
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToTurnlogForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTurnLog::WriteTurnLog`.
  void writeTurnLog(XmlBuilder element) {
    if (hasDelayed) {
      element.attribute('delayed', booleanToStr(delayed!));
    }
    if (hasForm) {
      element.attribute('form', turnlogFormToStr(form!));
    }
  }

  /// Copies the `AttTurnLog` members from [other].
  void copyAttTurnLog(covariant AttTurnLog other) {
    delayed = other.delayed;
    form = other.form;
  }
}
