// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_shared.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.AccidLog` (mirrors `vrv::AttAccidLog`).
mixin AttAccidLog {
  /// `func` — accidLog_FUNC.
  AccidlogFunc? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttAccidLog::ReadAccidLog`.
  bool readAccidLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = strToAccidlogFunc(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAccidLog::WriteAccidLog`.
  void writeAccidLog(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', accidlogFuncToStr(func!));
    }
  }

  /// Copies the `AttAccidLog` members from [other].
  void copyAttAccidLog(covariant AttAccidLog other) {
    func = other.func;
  }
}

/// MEI attribute class for `att.Accidental` (mirrors `vrv::AttAccidental`).
mixin AttAccidental {
  /// `accid` — data_ACCIDENTAL_WRITTEN.
  AccidentalWritten? accid;
  bool get hasAccid => accid != null;

  /// Mirrors `AttAccidental::ReadAccidental`.
  bool readAccidental(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final accidRaw = element.get('accid');
    if (accidRaw != null) {
      accid = strToAccidentalWritten(accidRaw);
      if (removeAttr) element.remove('accid');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAccidental::WriteAccidental`.
  void writeAccidental(XmlBuilder element) {
    if (hasAccid) {
      element.attribute('accid', accidentalWrittenToStr(accid!));
    }
  }

  /// Copies the `AttAccidental` members from [other].
  void copyAttAccidental(covariant AttAccidental other) {
    accid = other.accid;
  }
}

/// MEI attribute class for `att.AnnotLog` (mirrors `vrv::AttAnnotLog`).
mixin AttAnnotLog {
  /// `func` — std::string.
  String? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttAnnotLog::ReadAnnotLog`.
  bool readAnnotLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = identityStr(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAnnotLog::WriteAnnotLog`.
  void writeAnnotLog(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', identityStr(func!));
    }
  }

  /// Copies the `AttAnnotLog` members from [other].
  void copyAttAnnotLog(covariant AttAnnotLog other) {
    func = other.func;
  }
}

/// MEI attribute class for `att.Articulation` (mirrors `vrv::AttArticulation`).
mixin AttArticulation {
  /// `artic` — data_ARTICULATION_List.
  List<Articulation>? artic;
  bool get hasArtic => artic != null;

  /// Mirrors `AttArticulation::ReadArticulation`.
  bool readArticulation(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final articRaw = element.get('artic');
    if (articRaw != null) {
      artic = strToArticulationList(articRaw);
      if (removeAttr) element.remove('artic');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttArticulation::WriteArticulation`.
  void writeArticulation(XmlBuilder element) {
    if (hasArtic) {
      element.attribute('artic', articulationListToStr(artic!));
    }
  }

  /// Copies the `AttArticulation` members from [other].
  void copyAttArticulation(covariant AttArticulation other) {
    artic = other.artic;
  }
}

/// MEI attribute class for `att.AttaccaLog` (mirrors `vrv::AttAttaccaLog`).
mixin AttAttaccaLog {
  /// `target` — std::string.
  String? target;
  bool get hasTarget => target != null;

  /// Mirrors `AttAttaccaLog::ReadAttaccaLog`.
  bool readAttaccaLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final targetRaw = element.get('target');
    if (targetRaw != null) {
      target = identityStr(targetRaw);
      if (removeAttr) element.remove('target');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAttaccaLog::WriteAttaccaLog`.
  void writeAttaccaLog(XmlBuilder element) {
    if (hasTarget) {
      element.attribute('target', identityStr(target!));
    }
  }

  /// Copies the `AttAttaccaLog` members from [other].
  void copyAttAttaccaLog(covariant AttAttaccaLog other) {
    target = other.target;
  }
}

/// MEI attribute class for `att.Audience` (mirrors `vrv::AttAudience`).
mixin AttAudience {
  /// `audience` — audience_AUDIENCE.
  AudienceAudience? audience;
  bool get hasAudience => audience != null;

  /// Mirrors `AttAudience::ReadAudience`.
  bool readAudience(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final audienceRaw = element.get('audience');
    if (audienceRaw != null) {
      audience = strToAudienceAudience(audienceRaw);
      if (removeAttr) element.remove('audience');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAudience::WriteAudience`.
  void writeAudience(XmlBuilder element) {
    if (hasAudience) {
      element.attribute('audience', audienceAudienceToStr(audience!));
    }
  }

  /// Copies the `AttAudience` members from [other].
  void copyAttAudience(covariant AttAudience other) {
    audience = other.audience;
  }
}

/// MEI attribute class for `att.AugmentDots` (mirrors `vrv::AttAugmentDots`).
mixin AttAugmentDots {
  /// `dots` — int.
  int? dots;
  bool get hasDots => dots != null;

  /// Mirrors `AttAugmentDots::ReadAugmentDots`.
  bool readAugmentDots(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final dotsRaw = element.get('dots');
    if (dotsRaw != null) {
      dots = strToInt(dotsRaw);
      if (removeAttr) element.remove('dots');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAugmentDots::WriteAugmentDots`.
  void writeAugmentDots(XmlBuilder element) {
    if (hasDots) {
      element.attribute('dots', intToStr(dots!));
    }
  }

  /// Copies the `AttAugmentDots` members from [other].
  void copyAttAugmentDots(covariant AttAugmentDots other) {
    dots = other.dots;
  }
}

/// MEI attribute class for `att.Authorized` (mirrors `vrv::AttAuthorized`).
mixin AttAuthorized {
  /// `auth` — std::string.
  String? auth;
  bool get hasAuth => auth != null;

  /// `auth.uri` — std::string.
  String? authUri;
  bool get hasAuthUri => authUri != null;

  /// Mirrors `AttAuthorized::ReadAuthorized`.
  bool readAuthorized(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final authRaw = element.get('auth');
    if (authRaw != null) {
      auth = identityStr(authRaw);
      if (removeAttr) element.remove('auth');
      hasAttribute = true;
    }
    final authUriRaw = element.get('auth.uri');
    if (authUriRaw != null) {
      authUri = identityStr(authUriRaw);
      if (removeAttr) element.remove('auth.uri');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAuthorized::WriteAuthorized`.
  void writeAuthorized(XmlBuilder element) {
    if (hasAuth) {
      element.attribute('auth', identityStr(auth!));
    }
    if (hasAuthUri) {
      element.attribute('auth.uri', identityStr(authUri!));
    }
  }

  /// Copies the `AttAuthorized` members from [other].
  void copyAttAuthorized(covariant AttAuthorized other) {
    auth = other.auth;
    authUri = other.authUri;
  }
}

/// MEI attribute class for `att.BarLineLog` (mirrors `vrv::AttBarLineLog`).
mixin AttBarLineLog {
  /// `form` — data_BARRENDITION.
  Barrendition? form;
  bool get hasForm => form != null;

  /// Mirrors `AttBarLineLog::ReadBarLineLog`.
  bool readBarLineLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToBarrendition(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBarLineLog::WriteBarLineLog`.
  void writeBarLineLog(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', barrenditionToStr(form!));
    }
  }

  /// Copies the `AttBarLineLog` members from [other].
  void copyAttBarLineLog(covariant AttBarLineLog other) {
    form = other.form;
  }
}

/// MEI attribute class for `att.Barring` (mirrors `vrv::AttBarring`).
mixin AttBarring {
  /// `bar.len` — double.
  double? barLen;
  bool get hasBarLen => barLen != null;

  /// `bar.method` — data_BARMETHOD.
  Barmethod? barMethod;
  bool get hasBarMethod => barMethod != null;

  /// `bar.place` — int.
  int? barPlace;
  bool get hasBarPlace => barPlace != null;

  /// Mirrors `AttBarring::ReadBarring`.
  bool readBarring(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final barLenRaw = element.get('bar.len');
    if (barLenRaw != null) {
      barLen = strToDbl(barLenRaw);
      if (removeAttr) element.remove('bar.len');
      hasAttribute = true;
    }
    final barMethodRaw = element.get('bar.method');
    if (barMethodRaw != null) {
      barMethod = strToBarmethod(barMethodRaw);
      if (removeAttr) element.remove('bar.method');
      hasAttribute = true;
    }
    final barPlaceRaw = element.get('bar.place');
    if (barPlaceRaw != null) {
      barPlace = strToInt(barPlaceRaw);
      if (removeAttr) element.remove('bar.place');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBarring::WriteBarring`.
  void writeBarring(XmlBuilder element) {
    if (hasBarLen) {
      element.attribute('bar.len', dblToStr(barLen!));
    }
    if (hasBarMethod) {
      element.attribute('bar.method', barmethodToStr(barMethod!));
    }
    if (hasBarPlace) {
      element.attribute('bar.place', intToStr(barPlace!));
    }
  }

  /// Copies the `AttBarring` members from [other].
  void copyAttBarring(covariant AttBarring other) {
    barLen = other.barLen;
    barMethod = other.barMethod;
    barPlace = other.barPlace;
  }
}

/// MEI attribute class for `att.Basic` (mirrors `vrv::AttBasic`).
mixin AttBasic {
  /// `xml:base` — std::string.
  String? base;
  bool get hasBase => base != null;

  /// Mirrors `AttBasic::ReadBasic`.
  bool readBasic(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final baseRaw = element.get('xml:base');
    if (baseRaw != null) {
      base = identityStr(baseRaw);
      if (removeAttr) element.remove('xml:base');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBasic::WriteBasic`.
  void writeBasic(XmlBuilder element) {
    if (hasBase) {
      element.attribute('xml:base', identityStr(base!));
    }
  }

  /// Copies the `AttBasic` members from [other].
  void copyAttBasic(covariant AttBasic other) {
    base = other.base;
  }
}

/// MEI attribute class for `att.Bibl` (mirrors `vrv::AttBibl`).
mixin AttBibl {
  /// `analog` — std::string.
  String? analog;
  bool get hasAnalog => analog != null;

  /// Mirrors `AttBibl::ReadBibl`.
  bool readBibl(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final analogRaw = element.get('analog');
    if (analogRaw != null) {
      analog = identityStr(analogRaw);
      if (removeAttr) element.remove('analog');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBibl::WriteBibl`.
  void writeBibl(XmlBuilder element) {
    if (hasAnalog) {
      element.attribute('analog', identityStr(analog!));
    }
  }

  /// Copies the `AttBibl` members from [other].
  void copyAttBibl(covariant AttBibl other) {
    analog = other.analog;
  }
}

/// MEI attribute class for `att.Calendared` (mirrors `vrv::AttCalendared`).
mixin AttCalendared {
  /// `calendar` — std::string.
  String? calendar;
  bool get hasCalendar => calendar != null;

  /// Mirrors `AttCalendared::ReadCalendared`.
  bool readCalendared(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final calendarRaw = element.get('calendar');
    if (calendarRaw != null) {
      calendar = identityStr(calendarRaw);
      if (removeAttr) element.remove('calendar');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCalendared::WriteCalendared`.
  void writeCalendared(XmlBuilder element) {
    if (hasCalendar) {
      element.attribute('calendar', identityStr(calendar!));
    }
  }

  /// Copies the `AttCalendared` members from [other].
  void copyAttCalendared(covariant AttCalendared other) {
    calendar = other.calendar;
  }
}

/// MEI attribute class for `att.Canonical` (mirrors `vrv::AttCanonical`).
mixin AttCanonical {
  /// `codedval` — std::string.
  String? codedval;
  bool get hasCodedval => codedval != null;

  /// Mirrors `AttCanonical::ReadCanonical`.
  bool readCanonical(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final codedvalRaw = element.get('codedval');
    if (codedvalRaw != null) {
      codedval = identityStr(codedvalRaw);
      if (removeAttr) element.remove('codedval');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCanonical::WriteCanonical`.
  void writeCanonical(XmlBuilder element) {
    if (hasCodedval) {
      element.attribute('codedval', identityStr(codedval!));
    }
  }

  /// Copies the `AttCanonical` members from [other].
  void copyAttCanonical(covariant AttCanonical other) {
    codedval = other.codedval;
  }
}

/// MEI attribute class for `att.Classed` (mirrors `vrv::AttClassed`).
mixin AttClassed {
  /// `class` — std::string.
  String? classValue;
  bool get hasClassValue => classValue != null;

  /// Mirrors `AttClassed::ReadClassed`.
  bool readClassed(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final classValueRaw = element.get('class');
    if (classValueRaw != null) {
      classValue = identityStr(classValueRaw);
      if (removeAttr) element.remove('class');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttClassed::WriteClassed`.
  void writeClassed(XmlBuilder element) {
    if (hasClassValue) {
      element.attribute('class', identityStr(classValue!));
    }
  }

  /// Copies the `AttClassed` members from [other].
  void copyAttClassed(covariant AttClassed other) {
    classValue = other.classValue;
  }
}

/// MEI attribute class for `att.ClefLog` (mirrors `vrv::AttClefLog`).
mixin AttClefLog {
  /// `cautionary` — data_BOOLEAN.
  bool? cautionary;
  bool get hasCautionary => cautionary != null;

  /// Mirrors `AttClefLog::ReadClefLog`.
  bool readClefLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final cautionaryRaw = element.get('cautionary');
    if (cautionaryRaw != null) {
      cautionary = strToBoolean(cautionaryRaw);
      if (removeAttr) element.remove('cautionary');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttClefLog::WriteClefLog`.
  void writeClefLog(XmlBuilder element) {
    if (hasCautionary) {
      element.attribute('cautionary', booleanToStr(cautionary!));
    }
  }

  /// Copies the `AttClefLog` members from [other].
  void copyAttClefLog(covariant AttClefLog other) {
    cautionary = other.cautionary;
  }
}

/// MEI attribute class for `att.ClefShape` (mirrors `vrv::AttClefShape`).
mixin AttClefShape {
  /// `shape` — data_CLEFSHAPE.
  Clefshape? shape;
  bool get hasShape => shape != null;

  /// Mirrors `AttClefShape::ReadClefShape`.
  bool readClefShape(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final shapeRaw = element.get('shape');
    if (shapeRaw != null) {
      shape = strToClefshape(shapeRaw);
      if (removeAttr) element.remove('shape');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttClefShape::WriteClefShape`.
  void writeClefShape(XmlBuilder element) {
    if (hasShape) {
      element.attribute('shape', clefshapeToStr(shape!));
    }
  }

  /// Copies the `AttClefShape` members from [other].
  void copyAttClefShape(covariant AttClefShape other) {
    shape = other.shape;
  }
}

/// MEI attribute class for `att.CleffingLog` (mirrors `vrv::AttCleffingLog`).
mixin AttCleffingLog {
  /// `clef.shape` — data_CLEFSHAPE.
  Clefshape? clefShape;
  bool get hasClefShape => clefShape != null;

  /// `clef.line` — char.
  int? clefLine;
  bool get hasClefLine => clefLine != null;

  /// `clef.dis` — data_OCTAVE_DIS.
  OctaveDis? clefDis;
  bool get hasClefDis => clefDis != null;

  /// `clef.dis.place` — data_STAFFREL_basic.
  StaffrelBasic? clefDisPlace;
  bool get hasClefDisPlace => clefDisPlace != null;

  /// Mirrors `AttCleffingLog::ReadCleffingLog`.
  bool readCleffingLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final clefShapeRaw = element.get('clef.shape');
    if (clefShapeRaw != null) {
      clefShape = strToClefshape(clefShapeRaw);
      if (removeAttr) element.remove('clef.shape');
      hasAttribute = true;
    }
    final clefLineRaw = element.get('clef.line');
    if (clefLineRaw != null) {
      clefLine = strToInt(clefLineRaw);
      if (removeAttr) element.remove('clef.line');
      hasAttribute = true;
    }
    final clefDisRaw = element.get('clef.dis');
    if (clefDisRaw != null) {
      clefDis = strToOctaveDis(clefDisRaw);
      if (removeAttr) element.remove('clef.dis');
      hasAttribute = true;
    }
    final clefDisPlaceRaw = element.get('clef.dis.place');
    if (clefDisPlaceRaw != null) {
      clefDisPlace = strToStaffrelBasic(clefDisPlaceRaw);
      if (removeAttr) element.remove('clef.dis.place');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCleffingLog::WriteCleffingLog`.
  void writeCleffingLog(XmlBuilder element) {
    if (hasClefShape) {
      element.attribute('clef.shape', clefshapeToStr(clefShape!));
    }
    if (hasClefLine) {
      element.attribute('clef.line', intToStr(clefLine!));
    }
    if (hasClefDis) {
      element.attribute('clef.dis', octaveDisToStr(clefDis!));
    }
    if (hasClefDisPlace) {
      element.attribute('clef.dis.place', staffrelBasicToStr(clefDisPlace!));
    }
  }

  /// Copies the `AttCleffingLog` members from [other].
  void copyAttCleffingLog(covariant AttCleffingLog other) {
    clefShape = other.clefShape;
    clefLine = other.clefLine;
    clefDis = other.clefDis;
    clefDisPlace = other.clefDisPlace;
  }
}

/// MEI attribute class for `att.Color` (mirrors `vrv::AttColor`).
mixin AttColor {
  /// `color` — std::string.
  String? color;
  bool get hasColor => color != null;

  /// Mirrors `AttColor::ReadColor`.
  bool readColor(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final colorRaw = element.get('color');
    if (colorRaw != null) {
      color = identityStr(colorRaw);
      if (removeAttr) element.remove('color');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttColor::WriteColor`.
  void writeColor(XmlBuilder element) {
    if (hasColor) {
      element.attribute('color', identityStr(color!));
    }
  }

  /// Copies the `AttColor` members from [other].
  void copyAttColor(covariant AttColor other) {
    color = other.color;
  }
}

/// MEI attribute class for `att.Coloration` (mirrors `vrv::AttColoration`).
mixin AttColoration {
  /// `colored` — data_BOOLEAN.
  bool? colored;
  bool get hasColored => colored != null;

  /// Mirrors `AttColoration::ReadColoration`.
  bool readColoration(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final coloredRaw = element.get('colored');
    if (coloredRaw != null) {
      colored = strToBoolean(coloredRaw);
      if (removeAttr) element.remove('colored');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttColoration::WriteColoration`.
  void writeColoration(XmlBuilder element) {
    if (hasColored) {
      element.attribute('colored', booleanToStr(colored!));
    }
  }

  /// Copies the `AttColoration` members from [other].
  void copyAttColoration(covariant AttColoration other) {
    colored = other.colored;
  }
}

/// MEI attribute class for `att.CoordX1` (mirrors `vrv::AttCoordX1`).
mixin AttCoordX1 {
  /// `coord.x1` — double.
  double? coordX1;
  bool get hasCoordX1 => coordX1 != null;

  /// Mirrors `AttCoordX1::ReadCoordX1`.
  bool readCoordX1(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final coordX1Raw = element.get('coord.x1');
    if (coordX1Raw != null) {
      coordX1 = strToDbl(coordX1Raw);
      if (removeAttr) element.remove('coord.x1');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCoordX1::WriteCoordX1`.
  void writeCoordX1(XmlBuilder element) {
    if (hasCoordX1) {
      element.attribute('coord.x1', dblToStr(coordX1!));
    }
  }

  /// Copies the `AttCoordX1` members from [other].
  void copyAttCoordX1(covariant AttCoordX1 other) {
    coordX1 = other.coordX1;
  }
}

/// MEI attribute class for `att.CoordX2` (mirrors `vrv::AttCoordX2`).
mixin AttCoordX2 {
  /// `coord.x2` — double.
  double? coordX2;
  bool get hasCoordX2 => coordX2 != null;

  /// Mirrors `AttCoordX2::ReadCoordX2`.
  bool readCoordX2(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final coordX2Raw = element.get('coord.x2');
    if (coordX2Raw != null) {
      coordX2 = strToDbl(coordX2Raw);
      if (removeAttr) element.remove('coord.x2');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCoordX2::WriteCoordX2`.
  void writeCoordX2(XmlBuilder element) {
    if (hasCoordX2) {
      element.attribute('coord.x2', dblToStr(coordX2!));
    }
  }

  /// Copies the `AttCoordX2` members from [other].
  void copyAttCoordX2(covariant AttCoordX2 other) {
    coordX2 = other.coordX2;
  }
}

/// MEI attribute class for `att.CoordY1` (mirrors `vrv::AttCoordY1`).
mixin AttCoordY1 {
  /// `coord.y1` — double.
  double? coordY1;
  bool get hasCoordY1 => coordY1 != null;

  /// Mirrors `AttCoordY1::ReadCoordY1`.
  bool readCoordY1(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final coordY1Raw = element.get('coord.y1');
    if (coordY1Raw != null) {
      coordY1 = strToDbl(coordY1Raw);
      if (removeAttr) element.remove('coord.y1');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCoordY1::WriteCoordY1`.
  void writeCoordY1(XmlBuilder element) {
    if (hasCoordY1) {
      element.attribute('coord.y1', dblToStr(coordY1!));
    }
  }

  /// Copies the `AttCoordY1` members from [other].
  void copyAttCoordY1(covariant AttCoordY1 other) {
    coordY1 = other.coordY1;
  }
}

/// MEI attribute class for `att.Coordinated` (mirrors `vrv::AttCoordinated`).
mixin AttCoordinated {
  /// `lrx` — int.
  int? lrx;
  bool get hasLrx => lrx != null;

  /// `lry` — int.
  int? lry;
  bool get hasLry => lry != null;

  /// `rotate` — data_DEGREES.
  double? rotate;
  bool get hasRotate => rotate != null;

  /// Mirrors `AttCoordinated::ReadCoordinated`.
  bool readCoordinated(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final lrxRaw = element.get('lrx');
    if (lrxRaw != null) {
      lrx = strToInt(lrxRaw);
      if (removeAttr) element.remove('lrx');
      hasAttribute = true;
    }
    final lryRaw = element.get('lry');
    if (lryRaw != null) {
      lry = strToInt(lryRaw);
      if (removeAttr) element.remove('lry');
      hasAttribute = true;
    }
    final rotateRaw = element.get('rotate');
    if (rotateRaw != null) {
      rotate = strToDbl(rotateRaw);
      if (removeAttr) element.remove('rotate');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCoordinated::WriteCoordinated`.
  void writeCoordinated(XmlBuilder element) {
    if (hasLrx) {
      element.attribute('lrx', intToStr(lrx!));
    }
    if (hasLry) {
      element.attribute('lry', intToStr(lry!));
    }
    if (hasRotate) {
      element.attribute('rotate', degreesToStr(rotate!));
    }
  }

  /// Copies the `AttCoordinated` members from [other].
  void copyAttCoordinated(covariant AttCoordinated other) {
    lrx = other.lrx;
    lry = other.lry;
    rotate = other.rotate;
  }
}

/// MEI attribute class for `att.CoordinatedUl` (mirrors `vrv::AttCoordinatedUl`).
mixin AttCoordinatedUl {
  /// `ulx` — int.
  int? ulx;
  bool get hasUlx => ulx != null;

  /// `uly` — int.
  int? uly;
  bool get hasUly => uly != null;

  /// Mirrors `AttCoordinatedUl::ReadCoordinatedUl`.
  bool readCoordinatedUl(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final ulxRaw = element.get('ulx');
    if (ulxRaw != null) {
      ulx = strToInt(ulxRaw);
      if (removeAttr) element.remove('ulx');
      hasAttribute = true;
    }
    final ulyRaw = element.get('uly');
    if (ulyRaw != null) {
      uly = strToInt(ulyRaw);
      if (removeAttr) element.remove('uly');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCoordinatedUl::WriteCoordinatedUl`.
  void writeCoordinatedUl(XmlBuilder element) {
    if (hasUlx) {
      element.attribute('ulx', intToStr(ulx!));
    }
    if (hasUly) {
      element.attribute('uly', intToStr(uly!));
    }
  }

  /// Copies the `AttCoordinatedUl` members from [other].
  void copyAttCoordinatedUl(covariant AttCoordinatedUl other) {
    ulx = other.ulx;
    uly = other.uly;
  }
}

/// MEI attribute class for `att.Cue` (mirrors `vrv::AttCue`).
mixin AttCue {
  /// `cue` — data_BOOLEAN.
  bool? cue;
  bool get hasCue => cue != null;

  /// Mirrors `AttCue::ReadCue`.
  bool readCue(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final cueRaw = element.get('cue');
    if (cueRaw != null) {
      cue = strToBoolean(cueRaw);
      if (removeAttr) element.remove('cue');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCue::WriteCue`.
  void writeCue(XmlBuilder element) {
    if (hasCue) {
      element.attribute('cue', booleanToStr(cue!));
    }
  }

  /// Copies the `AttCue` members from [other].
  void copyAttCue(covariant AttCue other) {
    cue = other.cue;
  }
}

/// MEI attribute class for `att.Curvature` (mirrors `vrv::AttCurvature`).
mixin AttCurvature {
  /// `bezier` — std::string.
  String? bezier;
  bool get hasBezier => bezier != null;

  /// `bulge` — data_BULGE.
  List<BulgePair>? bulge;
  bool get hasBulge => bulge != null;

  /// `curvedir` — curvature_CURVEDIR.
  CurvatureCurvedir? curvedir;
  bool get hasCurvedir => curvedir != null;

  /// Mirrors `AttCurvature::ReadCurvature`.
  bool readCurvature(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final bezierRaw = element.get('bezier');
    if (bezierRaw != null) {
      bezier = identityStr(bezierRaw);
      if (removeAttr) element.remove('bezier');
      hasAttribute = true;
    }
    final bulgeRaw = element.get('bulge');
    if (bulgeRaw != null) {
      bulge = strToBulge(bulgeRaw);
      if (removeAttr) element.remove('bulge');
      hasAttribute = true;
    }
    final curvedirRaw = element.get('curvedir');
    if (curvedirRaw != null) {
      curvedir = strToCurvatureCurvedir(curvedirRaw);
      if (removeAttr) element.remove('curvedir');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCurvature::WriteCurvature`.
  void writeCurvature(XmlBuilder element) {
    if (hasBezier) {
      element.attribute('bezier', identityStr(bezier!));
    }
    if (hasBulge) {
      element.attribute('bulge', bulgeToStr(bulge!));
    }
    if (hasCurvedir) {
      element.attribute('curvedir', curvatureCurvedirToStr(curvedir!));
    }
  }

  /// Copies the `AttCurvature` members from [other].
  void copyAttCurvature(covariant AttCurvature other) {
    bezier = other.bezier;
    bulge = other.bulge;
    curvedir = other.curvedir;
  }
}

/// MEI attribute class for `att.CustosLog` (mirrors `vrv::AttCustosLog`).
mixin AttCustosLog {
  /// `target` — std::string.
  String? target;
  bool get hasTarget => target != null;

  /// Mirrors `AttCustosLog::ReadCustosLog`.
  bool readCustosLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final targetRaw = element.get('target');
    if (targetRaw != null) {
      target = identityStr(targetRaw);
      if (removeAttr) element.remove('target');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCustosLog::WriteCustosLog`.
  void writeCustosLog(XmlBuilder element) {
    if (hasTarget) {
      element.attribute('target', identityStr(target!));
    }
  }

  /// Copies the `AttCustosLog` members from [other].
  void copyAttCustosLog(covariant AttCustosLog other) {
    target = other.target;
  }
}

/// MEI attribute class for `att.DataPointing` (mirrors `vrv::AttDataPointing`).
mixin AttDataPointing {
  /// `data` — std::string.
  String? data;
  bool get hasData => data != null;

  /// Mirrors `AttDataPointing::ReadDataPointing`.
  bool readDataPointing(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final dataRaw = element.get('data');
    if (dataRaw != null) {
      data = identityStr(dataRaw);
      if (removeAttr) element.remove('data');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDataPointing::WriteDataPointing`.
  void writeDataPointing(XmlBuilder element) {
    if (hasData) {
      element.attribute('data', identityStr(data!));
    }
  }

  /// Copies the `AttDataPointing` members from [other].
  void copyAttDataPointing(covariant AttDataPointing other) {
    data = other.data;
  }
}

/// MEI attribute class for `att.DataSelecting` (mirrors `vrv::AttDataSelecting`).
mixin AttDataSelecting {
  /// `select` — std::string.
  String? select;
  bool get hasSelect => select != null;

  /// Mirrors `AttDataSelecting::ReadDataSelecting`.
  bool readDataSelecting(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final selectRaw = element.get('select');
    if (selectRaw != null) {
      select = identityStr(selectRaw);
      if (removeAttr) element.remove('select');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDataSelecting::WriteDataSelecting`.
  void writeDataSelecting(XmlBuilder element) {
    if (hasSelect) {
      element.attribute('select', identityStr(select!));
    }
  }

  /// Copies the `AttDataSelecting` members from [other].
  void copyAttDataSelecting(covariant AttDataSelecting other) {
    select = other.select;
  }
}

/// MEI attribute class for `att.Datable` (mirrors `vrv::AttDatable`).
mixin AttDatable {
  /// `enddate` — std::string.
  String? enddate;
  bool get hasEnddate => enddate != null;

  /// `isodate` — std::string.
  String? isodate;
  bool get hasIsodate => isodate != null;

  /// `notafter` — std::string.
  String? notafter;
  bool get hasNotafter => notafter != null;

  /// `notbefore` — std::string.
  String? notbefore;
  bool get hasNotbefore => notbefore != null;

  /// `startdate` — std::string.
  String? startdate;
  bool get hasStartdate => startdate != null;

  /// Mirrors `AttDatable::ReadDatable`.
  bool readDatable(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final enddateRaw = element.get('enddate');
    if (enddateRaw != null) {
      enddate = identityStr(enddateRaw);
      if (removeAttr) element.remove('enddate');
      hasAttribute = true;
    }
    final isodateRaw = element.get('isodate');
    if (isodateRaw != null) {
      isodate = identityStr(isodateRaw);
      if (removeAttr) element.remove('isodate');
      hasAttribute = true;
    }
    final notafterRaw = element.get('notafter');
    if (notafterRaw != null) {
      notafter = identityStr(notafterRaw);
      if (removeAttr) element.remove('notafter');
      hasAttribute = true;
    }
    final notbeforeRaw = element.get('notbefore');
    if (notbeforeRaw != null) {
      notbefore = identityStr(notbeforeRaw);
      if (removeAttr) element.remove('notbefore');
      hasAttribute = true;
    }
    final startdateRaw = element.get('startdate');
    if (startdateRaw != null) {
      startdate = identityStr(startdateRaw);
      if (removeAttr) element.remove('startdate');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDatable::WriteDatable`.
  void writeDatable(XmlBuilder element) {
    if (hasEnddate) {
      element.attribute('enddate', identityStr(enddate!));
    }
    if (hasIsodate) {
      element.attribute('isodate', identityStr(isodate!));
    }
    if (hasNotafter) {
      element.attribute('notafter', identityStr(notafter!));
    }
    if (hasNotbefore) {
      element.attribute('notbefore', identityStr(notbefore!));
    }
    if (hasStartdate) {
      element.attribute('startdate', identityStr(startdate!));
    }
  }

  /// Copies the `AttDatable` members from [other].
  void copyAttDatable(covariant AttDatable other) {
    enddate = other.enddate;
    isodate = other.isodate;
    notafter = other.notafter;
    notbefore = other.notbefore;
    startdate = other.startdate;
  }
}

/// MEI attribute class for `att.Distances` (mirrors `vrv::AttDistances`).
mixin AttDistances {
  /// `dir.dist` — data_MEASUREMENTSIGNED.
  MeasurementSigned? dirDist;
  bool get hasDirDist => dirDist != null;

  /// `dynam.dist` — data_MEASUREMENTSIGNED.
  MeasurementSigned? dynamDist;
  bool get hasDynamDist => dynamDist != null;

  /// `harm.dist` — data_MEASUREMENTSIGNED.
  MeasurementSigned? harmDist;
  bool get hasHarmDist => harmDist != null;

  /// `reh.dist` — data_MEASUREMENTSIGNED.
  MeasurementSigned? rehDist;
  bool get hasRehDist => rehDist != null;

  /// `tempo.dist` — data_MEASUREMENTSIGNED.
  MeasurementSigned? tempoDist;
  bool get hasTempoDist => tempoDist != null;

  /// Mirrors `AttDistances::ReadDistances`.
  bool readDistances(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final dirDistRaw = element.get('dir.dist');
    if (dirDistRaw != null) {
      dirDist = strToMeasurementsigned(dirDistRaw);
      if (removeAttr) element.remove('dir.dist');
      hasAttribute = true;
    }
    final dynamDistRaw = element.get('dynam.dist');
    if (dynamDistRaw != null) {
      dynamDist = strToMeasurementsigned(dynamDistRaw);
      if (removeAttr) element.remove('dynam.dist');
      hasAttribute = true;
    }
    final harmDistRaw = element.get('harm.dist');
    if (harmDistRaw != null) {
      harmDist = strToMeasurementsigned(harmDistRaw);
      if (removeAttr) element.remove('harm.dist');
      hasAttribute = true;
    }
    final rehDistRaw = element.get('reh.dist');
    if (rehDistRaw != null) {
      rehDist = strToMeasurementsigned(rehDistRaw);
      if (removeAttr) element.remove('reh.dist');
      hasAttribute = true;
    }
    final tempoDistRaw = element.get('tempo.dist');
    if (tempoDistRaw != null) {
      tempoDist = strToMeasurementsigned(tempoDistRaw);
      if (removeAttr) element.remove('tempo.dist');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDistances::WriteDistances`.
  void writeDistances(XmlBuilder element) {
    if (hasDirDist) {
      element.attribute('dir.dist', measurementsignedToStr(dirDist!));
    }
    if (hasDynamDist) {
      element.attribute('dynam.dist', measurementsignedToStr(dynamDist!));
    }
    if (hasHarmDist) {
      element.attribute('harm.dist', measurementsignedToStr(harmDist!));
    }
    if (hasRehDist) {
      element.attribute('reh.dist', measurementsignedToStr(rehDist!));
    }
    if (hasTempoDist) {
      element.attribute('tempo.dist', measurementsignedToStr(tempoDist!));
    }
  }

  /// Copies the `AttDistances` members from [other].
  void copyAttDistances(covariant AttDistances other) {
    dirDist = other.dirDist;
    dynamDist = other.dynamDist;
    harmDist = other.harmDist;
    rehDist = other.rehDist;
    tempoDist = other.tempoDist;
  }
}

/// MEI attribute class for `att.DocStatus` (mirrors `vrv::AttDocStatus`).
mixin AttDocStatus {
  /// `status` — std::string.
  String? status;
  bool get hasStatus => status != null;

  /// Mirrors `AttDocStatus::ReadDocStatus`.
  bool readDocStatus(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final statusRaw = element.get('status');
    if (statusRaw != null) {
      status = identityStr(statusRaw);
      if (removeAttr) element.remove('status');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDocStatus::WriteDocStatus`.
  void writeDocStatus(XmlBuilder element) {
    if (hasStatus) {
      element.attribute('status', identityStr(status!));
    }
  }

  /// Copies the `AttDocStatus` members from [other].
  void copyAttDocStatus(covariant AttDocStatus other) {
    status = other.status;
  }
}

/// MEI attribute class for `att.DotLog` (mirrors `vrv::AttDotLog`).
mixin AttDotLog {
  /// `form` — dotLog_FORM.
  DotlogForm? form;
  bool get hasForm => form != null;

  /// Mirrors `AttDotLog::ReadDotLog`.
  bool readDotLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToDotlogForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDotLog::WriteDotLog`.
  void writeDotLog(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', dotlogFormToStr(form!));
    }
  }

  /// Copies the `AttDotLog` members from [other].
  void copyAttDotLog(covariant AttDotLog other) {
    form = other.form;
  }
}

/// MEI attribute class for `att.DurationAdditive` (mirrors `vrv::AttDurationAdditive`).
mixin AttDurationAdditive {
  /// `dur` — data_DURATION.
  MeiDuration? dur;
  bool get hasDur => dur != null;

  /// Mirrors `AttDurationAdditive::ReadDurationAdditive`.
  bool readDurationAdditive(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final durRaw = element.get('dur');
    if (durRaw != null) {
      dur = strToDuration(durRaw);
      if (removeAttr) element.remove('dur');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDurationAdditive::WriteDurationAdditive`.
  void writeDurationAdditive(XmlBuilder element) {
    if (hasDur) {
      element.attribute('dur', durationToStr(dur!));
    }
  }

  /// Copies the `AttDurationAdditive` members from [other].
  void copyAttDurationAdditive(covariant AttDurationAdditive other) {
    dur = other.dur;
  }
}

/// MEI attribute class for `att.DurationDefault` (mirrors `vrv::AttDurationDefault`).
mixin AttDurationDefault {
  /// `dur.default` — data_DURATION.
  MeiDuration? durDefault;
  bool get hasDurDefault => durDefault != null;

  /// `num.default` — int.
  int? numDefault;
  bool get hasNumDefault => numDefault != null;

  /// `numbase.default` — int.
  int? numbaseDefault;
  bool get hasNumbaseDefault => numbaseDefault != null;

  /// Mirrors `AttDurationDefault::ReadDurationDefault`.
  bool readDurationDefault(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final durDefaultRaw = element.get('dur.default');
    if (durDefaultRaw != null) {
      durDefault = strToDuration(durDefaultRaw);
      if (removeAttr) element.remove('dur.default');
      hasAttribute = true;
    }
    final numDefaultRaw = element.get('num.default');
    if (numDefaultRaw != null) {
      numDefault = strToInt(numDefaultRaw);
      if (removeAttr) element.remove('num.default');
      hasAttribute = true;
    }
    final numbaseDefaultRaw = element.get('numbase.default');
    if (numbaseDefaultRaw != null) {
      numbaseDefault = strToInt(numbaseDefaultRaw);
      if (removeAttr) element.remove('numbase.default');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDurationDefault::WriteDurationDefault`.
  void writeDurationDefault(XmlBuilder element) {
    if (hasDurDefault) {
      element.attribute('dur.default', durationToStr(durDefault!));
    }
    if (hasNumDefault) {
      element.attribute('num.default', intToStr(numDefault!));
    }
    if (hasNumbaseDefault) {
      element.attribute('numbase.default', intToStr(numbaseDefault!));
    }
  }

  /// Copies the `AttDurationDefault` members from [other].
  void copyAttDurationDefault(covariant AttDurationDefault other) {
    durDefault = other.durDefault;
    numDefault = other.numDefault;
    numbaseDefault = other.numbaseDefault;
  }
}

/// MEI attribute class for `att.DurationLog` (mirrors `vrv::AttDurationLog`).
mixin AttDurationLog {
  /// `dur` — data_DURATION.
  MeiDuration? dur;
  bool get hasDur => dur != null;

  /// Mirrors `AttDurationLog::ReadDurationLog`.
  bool readDurationLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final durRaw = element.get('dur');
    if (durRaw != null) {
      dur = strToDuration(durRaw);
      if (removeAttr) element.remove('dur');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDurationLog::WriteDurationLog`.
  void writeDurationLog(XmlBuilder element) {
    if (hasDur) {
      element.attribute('dur', durationToStr(dur!));
    }
  }

  /// Copies the `AttDurationLog` members from [other].
  void copyAttDurationLog(covariant AttDurationLog other) {
    dur = other.dur;
  }
}

/// MEI attribute class for `att.DurationRatio` (mirrors `vrv::AttDurationRatio`).
mixin AttDurationRatio {
  /// `num` — int.
  int? num;
  bool get hasNum => num != null;

  /// `numbase` — int.
  int? numbase;
  bool get hasNumbase => numbase != null;

  /// Mirrors `AttDurationRatio::ReadDurationRatio`.
  bool readDurationRatio(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final numRaw = element.get('num');
    if (numRaw != null) {
      num = strToInt(numRaw);
      if (removeAttr) element.remove('num');
      hasAttribute = true;
    }
    final numbaseRaw = element.get('numbase');
    if (numbaseRaw != null) {
      numbase = strToInt(numbaseRaw);
      if (removeAttr) element.remove('numbase');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDurationRatio::WriteDurationRatio`.
  void writeDurationRatio(XmlBuilder element) {
    if (hasNum) {
      element.attribute('num', intToStr(num!));
    }
    if (hasNumbase) {
      element.attribute('numbase', intToStr(numbase!));
    }
  }

  /// Copies the `AttDurationRatio` members from [other].
  void copyAttDurationRatio(covariant AttDurationRatio other) {
    num = other.num;
    numbase = other.numbase;
  }
}

/// MEI attribute class for `att.EnclosingChars` (mirrors `vrv::AttEnclosingChars`).
mixin AttEnclosingChars {
  /// `enclose` — data_ENCLOSURE.
  Enclosure? enclose;
  bool get hasEnclose => enclose != null;

  /// Mirrors `AttEnclosingChars::ReadEnclosingChars`.
  bool readEnclosingChars(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final encloseRaw = element.get('enclose');
    if (encloseRaw != null) {
      enclose = strToEnclosure(encloseRaw);
      if (removeAttr) element.remove('enclose');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttEnclosingChars::WriteEnclosingChars`.
  void writeEnclosingChars(XmlBuilder element) {
    if (hasEnclose) {
      element.attribute('enclose', enclosureToStr(enclose!));
    }
  }

  /// Copies the `AttEnclosingChars` members from [other].
  void copyAttEnclosingChars(covariant AttEnclosingChars other) {
    enclose = other.enclose;
  }
}

/// MEI attribute class for `att.Endings` (mirrors `vrv::AttEndings`).
mixin AttEndings {
  /// `ending.rend` — endings_ENDINGREND.
  EndingsEndingrend? endingRend;
  bool get hasEndingRend => endingRend != null;

  /// Mirrors `AttEndings::ReadEndings`.
  bool readEndings(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final endingRendRaw = element.get('ending.rend');
    if (endingRendRaw != null) {
      endingRend = strToEndingsEndingrend(endingRendRaw);
      if (removeAttr) element.remove('ending.rend');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttEndings::WriteEndings`.
  void writeEndings(XmlBuilder element) {
    if (hasEndingRend) {
      element.attribute('ending.rend', endingsEndingrendToStr(endingRend!));
    }
  }

  /// Copies the `AttEndings` members from [other].
  void copyAttEndings(covariant AttEndings other) {
    endingRend = other.endingRend;
  }
}

/// MEI attribute class for `att.Evidence` (mirrors `vrv::AttEvidence`).
mixin AttEvidence {
  /// `cert` — data_CERTAINTY.
  Certainty? cert;
  bool get hasCert => cert != null;

  /// `evidence` — std::string.
  String? evidence;
  bool get hasEvidence => evidence != null;

  /// Mirrors `AttEvidence::ReadEvidence`.
  bool readEvidence(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final certRaw = element.get('cert');
    if (certRaw != null) {
      cert = strToCertainty(certRaw);
      if (removeAttr) element.remove('cert');
      hasAttribute = true;
    }
    final evidenceRaw = element.get('evidence');
    if (evidenceRaw != null) {
      evidence = identityStr(evidenceRaw);
      if (removeAttr) element.remove('evidence');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttEvidence::WriteEvidence`.
  void writeEvidence(XmlBuilder element) {
    if (hasCert) {
      element.attribute('cert', certaintyToStr(cert!));
    }
    if (hasEvidence) {
      element.attribute('evidence', identityStr(evidence!));
    }
  }

  /// Copies the `AttEvidence` members from [other].
  void copyAttEvidence(covariant AttEvidence other) {
    cert = other.cert;
    evidence = other.evidence;
  }
}

/// MEI attribute class for `att.Extender` (mirrors `vrv::AttExtender`).
mixin AttExtender {
  /// `extender` — data_BOOLEAN.
  bool? extender;
  bool get hasExtender => extender != null;

  /// Mirrors `AttExtender::ReadExtender`.
  bool readExtender(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final extenderRaw = element.get('extender');
    if (extenderRaw != null) {
      extender = strToBoolean(extenderRaw);
      if (removeAttr) element.remove('extender');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttExtender::WriteExtender`.
  void writeExtender(XmlBuilder element) {
    if (hasExtender) {
      element.attribute('extender', booleanToStr(extender!));
    }
  }

  /// Copies the `AttExtender` members from [other].
  void copyAttExtender(covariant AttExtender other) {
    extender = other.extender;
  }
}

/// MEI attribute class for `att.Extent` (mirrors `vrv::AttExtent`).
mixin AttExtent {
  /// `extent` — std::string.
  String? extent;
  bool get hasExtent => extent != null;

  /// Mirrors `AttExtent::ReadExtent`.
  bool readExtent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final extentRaw = element.get('extent');
    if (extentRaw != null) {
      extent = identityStr(extentRaw);
      if (removeAttr) element.remove('extent');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttExtent::WriteExtent`.
  void writeExtent(XmlBuilder element) {
    if (hasExtent) {
      element.attribute('extent', identityStr(extent!));
    }
  }

  /// Copies the `AttExtent` members from [other].
  void copyAttExtent(covariant AttExtent other) {
    extent = other.extent;
  }
}

/// MEI attribute class for `att.FermataPresent` (mirrors `vrv::AttFermataPresent`).
mixin AttFermataPresent {
  /// `fermata` — data_STAFFREL_basic.
  StaffrelBasic? fermata;
  bool get hasFermata => fermata != null;

  /// Mirrors `AttFermataPresent::ReadFermataPresent`.
  bool readFermataPresent(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final fermataRaw = element.get('fermata');
    if (fermataRaw != null) {
      fermata = strToStaffrelBasic(fermataRaw);
      if (removeAttr) element.remove('fermata');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttFermataPresent::WriteFermataPresent`.
  void writeFermataPresent(XmlBuilder element) {
    if (hasFermata) {
      element.attribute('fermata', staffrelBasicToStr(fermata!));
    }
  }

  /// Copies the `AttFermataPresent` members from [other].
  void copyAttFermataPresent(covariant AttFermataPresent other) {
    fermata = other.fermata;
  }
}

/// MEI attribute class for `att.Filing` (mirrors `vrv::AttFiling`).
mixin AttFiling {
  /// `nonfiling` — int.
  int? nonfiling;
  bool get hasNonfiling => nonfiling != null;

  /// Mirrors `AttFiling::ReadFiling`.
  bool readFiling(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final nonfilingRaw = element.get('nonfiling');
    if (nonfilingRaw != null) {
      nonfiling = strToInt(nonfilingRaw);
      if (removeAttr) element.remove('nonfiling');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttFiling::WriteFiling`.
  void writeFiling(XmlBuilder element) {
    if (hasNonfiling) {
      element.attribute('nonfiling', intToStr(nonfiling!));
    }
  }

  /// Copies the `AttFiling` members from [other].
  void copyAttFiling(covariant AttFiling other) {
    nonfiling = other.nonfiling;
  }
}

/// MEI attribute class for `att.Formework` (mirrors `vrv::AttFormework`).
mixin AttFormework {
  /// `func` — data_PGFUNC.
  Pgfunc? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttFormework::ReadFormework`.
  bool readFormework(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = strToPgfunc(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttFormework::WriteFormework`.
  void writeFormework(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', pgfuncToStr(func!));
    }
  }

  /// Copies the `AttFormework` members from [other].
  void copyAttFormework(covariant AttFormework other) {
    func = other.func;
  }
}

/// MEI attribute class for `att.GrpSymLog` (mirrors `vrv::AttGrpSymLog`).
mixin AttGrpSymLog {
  /// `level` — int.
  int? level;
  bool get hasLevel => level != null;

  /// Mirrors `AttGrpSymLog::ReadGrpSymLog`.
  bool readGrpSymLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final levelRaw = element.get('level');
    if (levelRaw != null) {
      level = strToInt(levelRaw);
      if (removeAttr) element.remove('level');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttGrpSymLog::WriteGrpSymLog`.
  void writeGrpSymLog(XmlBuilder element) {
    if (hasLevel) {
      element.attribute('level', intToStr(level!));
    }
  }

  /// Copies the `AttGrpSymLog` members from [other].
  void copyAttGrpSymLog(covariant AttGrpSymLog other) {
    level = other.level;
  }
}

/// MEI attribute class for `att.HandIdent` (mirrors `vrv::AttHandIdent`).
mixin AttHandIdent {
  /// `hand` — std::string.
  String? hand;
  bool get hasHand => hand != null;

  /// Mirrors `AttHandIdent::ReadHandIdent`.
  bool readHandIdent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final handRaw = element.get('hand');
    if (handRaw != null) {
      hand = identityStr(handRaw);
      if (removeAttr) element.remove('hand');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHandIdent::WriteHandIdent`.
  void writeHandIdent(XmlBuilder element) {
    if (hasHand) {
      element.attribute('hand', identityStr(hand!));
    }
  }

  /// Copies the `AttHandIdent` members from [other].
  void copyAttHandIdent(covariant AttHandIdent other) {
    hand = other.hand;
  }
}

/// MEI attribute class for `att.Height` (mirrors `vrv::AttHeight`).
mixin AttHeight {
  /// `height` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? height;
  bool get hasHeight => height != null;

  /// Mirrors `AttHeight::ReadHeight`.
  bool readHeight(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final heightRaw = element.get('height');
    if (heightRaw != null) {
      height = strToMeasurementunsigned(heightRaw);
      if (removeAttr) element.remove('height');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHeight::WriteHeight`.
  void writeHeight(XmlBuilder element) {
    if (hasHeight) {
      element.attribute('height', measurementunsignedToStr(height!));
    }
  }

  /// Copies the `AttHeight` members from [other].
  void copyAttHeight(covariant AttHeight other) {
    height = other.height;
  }
}

/// MEI attribute class for `att.HorizontalAlign` (mirrors `vrv::AttHorizontalAlign`).
mixin AttHorizontalAlign {
  /// `halign` — data_HORIZONTALALIGNMENT.
  Horizontalalignment? halign;
  bool get hasHalign => halign != null;

  /// Mirrors `AttHorizontalAlign::ReadHorizontalAlign`.
  bool readHorizontalAlign(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final halignRaw = element.get('halign');
    if (halignRaw != null) {
      halign = strToHorizontalalignment(halignRaw);
      if (removeAttr) element.remove('halign');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHorizontalAlign::WriteHorizontalAlign`.
  void writeHorizontalAlign(XmlBuilder element) {
    if (hasHalign) {
      element.attribute('halign', horizontalalignmentToStr(halign!));
    }
  }

  /// Copies the `AttHorizontalAlign` members from [other].
  void copyAttHorizontalAlign(covariant AttHorizontalAlign other) {
    halign = other.halign;
  }
}

/// MEI attribute class for `att.InternetMedia` (mirrors `vrv::AttInternetMedia`).
mixin AttInternetMedia {
  /// `mimetype` — std::string.
  String? mimetype;
  bool get hasMimetype => mimetype != null;

  /// Mirrors `AttInternetMedia::ReadInternetMedia`.
  bool readInternetMedia(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final mimetypeRaw = element.get('mimetype');
    if (mimetypeRaw != null) {
      mimetype = identityStr(mimetypeRaw);
      if (removeAttr) element.remove('mimetype');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttInternetMedia::WriteInternetMedia`.
  void writeInternetMedia(XmlBuilder element) {
    if (hasMimetype) {
      element.attribute('mimetype', identityStr(mimetype!));
    }
  }

  /// Copies the `AttInternetMedia` members from [other].
  void copyAttInternetMedia(covariant AttInternetMedia other) {
    mimetype = other.mimetype;
  }
}

/// MEI attribute class for `att.Joined` (mirrors `vrv::AttJoined`).
mixin AttJoined {
  /// `join` — std::string.
  String? join;
  bool get hasJoin => join != null;

  /// Mirrors `AttJoined::ReadJoined`.
  bool readJoined(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final joinRaw = element.get('join');
    if (joinRaw != null) {
      join = identityStr(joinRaw);
      if (removeAttr) element.remove('join');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttJoined::WriteJoined`.
  void writeJoined(XmlBuilder element) {
    if (hasJoin) {
      element.attribute('join', identityStr(join!));
    }
  }

  /// Copies the `AttJoined` members from [other].
  void copyAttJoined(covariant AttJoined other) {
    join = other.join;
  }
}

/// MEI attribute class for `att.KeySigLog` (mirrors `vrv::AttKeySigLog`).
mixin AttKeySigLog {
  /// `sig` — data_KEYSIGNATURE.
  KeySignature? sig;
  bool get hasSig => sig != null;

  /// Mirrors `AttKeySigLog::ReadKeySigLog`.
  bool readKeySigLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final sigRaw = element.get('sig');
    if (sigRaw != null) {
      sig = strToKeysignature(sigRaw);
      if (removeAttr) element.remove('sig');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttKeySigLog::WriteKeySigLog`.
  void writeKeySigLog(XmlBuilder element) {
    if (hasSig) {
      element.attribute('sig', keysignatureToStr(sig!));
    }
  }

  /// Copies the `AttKeySigLog` members from [other].
  void copyAttKeySigLog(covariant AttKeySigLog other) {
    sig = other.sig;
  }
}

/// MEI attribute class for `att.KeySigDefaultLog` (mirrors `vrv::AttKeySigDefaultLog`).
mixin AttKeySigDefaultLog {
  /// `keysig` — data_KEYSIGNATURE.
  KeySignature? keysig;
  bool get hasKeysig => keysig != null;

  /// Mirrors `AttKeySigDefaultLog::ReadKeySigDefaultLog`.
  bool readKeySigDefaultLog(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final keysigRaw = element.get('keysig');
    if (keysigRaw != null) {
      keysig = strToKeysignature(keysigRaw);
      if (removeAttr) element.remove('keysig');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttKeySigDefaultLog::WriteKeySigDefaultLog`.
  void writeKeySigDefaultLog(XmlBuilder element) {
    if (hasKeysig) {
      element.attribute('keysig', keysignatureToStr(keysig!));
    }
  }

  /// Copies the `AttKeySigDefaultLog` members from [other].
  void copyAttKeySigDefaultLog(covariant AttKeySigDefaultLog other) {
    keysig = other.keysig;
  }
}

/// MEI attribute class for `att.Labelled` (mirrors `vrv::AttLabelled`).
mixin AttLabelled {
  /// `label` — std::string.
  String? label;
  bool get hasLabel => label != null;

  /// Mirrors `AttLabelled::ReadLabelled`.
  bool readLabelled(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final labelRaw = element.get('label');
    if (labelRaw != null) {
      label = identityStr(labelRaw);
      if (removeAttr) element.remove('label');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLabelled::WriteLabelled`.
  void writeLabelled(XmlBuilder element) {
    if (hasLabel) {
      element.attribute('label', identityStr(label!));
    }
  }

  /// Copies the `AttLabelled` members from [other].
  void copyAttLabelled(covariant AttLabelled other) {
    label = other.label;
  }
}

/// MEI attribute class for `att.Lang` (mirrors `vrv::AttLang`).
mixin AttLang {
  /// `xml:lang` — std::string.
  String? lang;
  bool get hasLang => lang != null;

  /// `translit` — std::string.
  String? translit;
  bool get hasTranslit => translit != null;

  /// Mirrors `AttLang::ReadLang`.
  bool readLang(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final langRaw = element.get('xml:lang');
    if (langRaw != null) {
      lang = identityStr(langRaw);
      if (removeAttr) element.remove('xml:lang');
      hasAttribute = true;
    }
    final translitRaw = element.get('translit');
    if (translitRaw != null) {
      translit = identityStr(translitRaw);
      if (removeAttr) element.remove('translit');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLang::WriteLang`.
  void writeLang(XmlBuilder element) {
    if (hasLang) {
      element.attribute('xml:lang', identityStr(lang!));
    }
    if (hasTranslit) {
      element.attribute('translit', identityStr(translit!));
    }
  }

  /// Copies the `AttLang` members from [other].
  void copyAttLang(covariant AttLang other) {
    lang = other.lang;
    translit = other.translit;
  }
}

/// MEI attribute class for `att.LayerLog` (mirrors `vrv::AttLayerLog`).
mixin AttLayerLog {
  /// `def` — std::string.
  String? def;
  bool get hasDef => def != null;

  /// Mirrors `AttLayerLog::ReadLayerLog`.
  bool readLayerLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final defRaw = element.get('def');
    if (defRaw != null) {
      def = identityStr(defRaw);
      if (removeAttr) element.remove('def');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLayerLog::WriteLayerLog`.
  void writeLayerLog(XmlBuilder element) {
    if (hasDef) {
      element.attribute('def', identityStr(def!));
    }
  }

  /// Copies the `AttLayerLog` members from [other].
  void copyAttLayerLog(covariant AttLayerLog other) {
    def = other.def;
  }
}

/// MEI attribute class for `att.LayerIdent` (mirrors `vrv::AttLayerIdent`).
mixin AttLayerIdent {
  /// `layer` — int.
  int? layer;
  bool get hasLayer => layer != null;

  /// Mirrors `AttLayerIdent::ReadLayerIdent`.
  bool readLayerIdent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final layerRaw = element.get('layer');
    if (layerRaw != null) {
      layer = strToInt(layerRaw);
      if (removeAttr) element.remove('layer');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLayerIdent::WriteLayerIdent`.
  void writeLayerIdent(XmlBuilder element) {
    if (hasLayer) {
      element.attribute('layer', intToStr(layer!));
    }
  }

  /// Copies the `AttLayerIdent` members from [other].
  void copyAttLayerIdent(covariant AttLayerIdent other) {
    layer = other.layer;
  }
}

/// MEI attribute class for `att.LineLoc` (mirrors `vrv::AttLineLoc`).
mixin AttLineLoc {
  /// `line` — char.
  int? line;
  bool get hasLine => line != null;

  /// Mirrors `AttLineLoc::ReadLineLoc`.
  bool readLineLoc(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final lineRaw = element.get('line');
    if (lineRaw != null) {
      line = strToInt(lineRaw);
      if (removeAttr) element.remove('line');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLineLoc::WriteLineLoc`.
  void writeLineLoc(XmlBuilder element) {
    if (hasLine) {
      element.attribute('line', intToStr(line!));
    }
  }

  /// Copies the `AttLineLoc` members from [other].
  void copyAttLineLoc(covariant AttLineLoc other) {
    line = other.line;
  }
}

/// MEI attribute class for `att.LineRend` (mirrors `vrv::AttLineRend`).
mixin AttLineRend {
  /// `lendsym` — data_LINESTARTENDSYMBOL.
  Linestartendsymbol? lendsym;
  bool get hasLendsym => lendsym != null;

  /// `lendsym.size` — int.
  int? lendsymSize;
  bool get hasLendsymSize => lendsymSize != null;

  /// `lstartsym` — data_LINESTARTENDSYMBOL.
  Linestartendsymbol? lstartsym;
  bool get hasLstartsym => lstartsym != null;

  /// `lstartsym.size` — int.
  int? lstartsymSize;
  bool get hasLstartsymSize => lstartsymSize != null;

  /// Mirrors `AttLineRend::ReadLineRend`.
  bool readLineRend(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final lendsymRaw = element.get('lendsym');
    if (lendsymRaw != null) {
      lendsym = strToLinestartendsymbol(lendsymRaw);
      if (removeAttr) element.remove('lendsym');
      hasAttribute = true;
    }
    final lendsymSizeRaw = element.get('lendsym.size');
    if (lendsymSizeRaw != null) {
      lendsymSize = strToInt(lendsymSizeRaw);
      if (removeAttr) element.remove('lendsym.size');
      hasAttribute = true;
    }
    final lstartsymRaw = element.get('lstartsym');
    if (lstartsymRaw != null) {
      lstartsym = strToLinestartendsymbol(lstartsymRaw);
      if (removeAttr) element.remove('lstartsym');
      hasAttribute = true;
    }
    final lstartsymSizeRaw = element.get('lstartsym.size');
    if (lstartsymSizeRaw != null) {
      lstartsymSize = strToInt(lstartsymSizeRaw);
      if (removeAttr) element.remove('lstartsym.size');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLineRend::WriteLineRend`.
  void writeLineRend(XmlBuilder element) {
    if (hasLendsym) {
      element.attribute('lendsym', linestartendsymbolToStr(lendsym!));
    }
    if (hasLendsymSize) {
      element.attribute('lendsym.size', intToStr(lendsymSize!));
    }
    if (hasLstartsym) {
      element.attribute('lstartsym', linestartendsymbolToStr(lstartsym!));
    }
    if (hasLstartsymSize) {
      element.attribute('lstartsym.size', intToStr(lstartsymSize!));
    }
  }

  /// Copies the `AttLineRend` members from [other].
  void copyAttLineRend(covariant AttLineRend other) {
    lendsym = other.lendsym;
    lendsymSize = other.lendsymSize;
    lstartsym = other.lstartsym;
    lstartsymSize = other.lstartsymSize;
  }
}

/// MEI attribute class for `att.LineRendBase` (mirrors `vrv::AttLineRendBase`).
mixin AttLineRendBase {
  /// `lform` — data_LINEFORM.
  Lineform? lform;
  bool get hasLform => lform != null;

  /// `lwidth` — data_LINEWIDTH.
  LineWidth? lwidth;
  bool get hasLwidth => lwidth != null;

  /// `lsegs` — int.
  int? lsegs;
  bool get hasLsegs => lsegs != null;

  /// Mirrors `AttLineRendBase::ReadLineRendBase`.
  bool readLineRendBase(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final lformRaw = element.get('lform');
    if (lformRaw != null) {
      lform = strToLineform(lformRaw);
      if (removeAttr) element.remove('lform');
      hasAttribute = true;
    }
    final lwidthRaw = element.get('lwidth');
    if (lwidthRaw != null) {
      lwidth = strToLinewidth(lwidthRaw);
      if (removeAttr) element.remove('lwidth');
      hasAttribute = true;
    }
    final lsegsRaw = element.get('lsegs');
    if (lsegsRaw != null) {
      lsegs = strToInt(lsegsRaw);
      if (removeAttr) element.remove('lsegs');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLineRendBase::WriteLineRendBase`.
  void writeLineRendBase(XmlBuilder element) {
    if (hasLform) {
      element.attribute('lform', lineformToStr(lform!));
    }
    if (hasLwidth) {
      element.attribute('lwidth', linewidthToStr(lwidth!));
    }
    if (hasLsegs) {
      element.attribute('lsegs', intToStr(lsegs!));
    }
  }

  /// Copies the `AttLineRendBase` members from [other].
  void copyAttLineRendBase(covariant AttLineRendBase other) {
    lform = other.lform;
    lwidth = other.lwidth;
    lsegs = other.lsegs;
  }
}

/// MEI attribute class for `att.Linking` (mirrors `vrv::AttLinking`).
mixin AttLinking {
  /// `copyof` — std::string.
  String? copyof;
  bool get hasCopyof => copyof != null;

  /// `corresp` — std::string.
  String? corresp;
  bool get hasCorresp => corresp != null;

  /// `follows` — std::string.
  String? follows;
  bool get hasFollows => follows != null;

  /// `next` — std::string.
  String? next;
  bool get hasNext => next != null;

  /// `precedes` — std::string.
  String? precedes;
  bool get hasPrecedes => precedes != null;

  /// `prev` — std::string.
  String? prev;
  bool get hasPrev => prev != null;

  /// `sameas` — std::string.
  String? sameas;
  bool get hasSameas => sameas != null;

  /// `synch` — std::string.
  String? synch;
  bool get hasSynch => synch != null;

  /// Mirrors `AttLinking::ReadLinking`.
  bool readLinking(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final copyofRaw = element.get('copyof');
    if (copyofRaw != null) {
      copyof = identityStr(copyofRaw);
      if (removeAttr) element.remove('copyof');
      hasAttribute = true;
    }
    final correspRaw = element.get('corresp');
    if (correspRaw != null) {
      corresp = identityStr(correspRaw);
      if (removeAttr) element.remove('corresp');
      hasAttribute = true;
    }
    final followsRaw = element.get('follows');
    if (followsRaw != null) {
      follows = identityStr(followsRaw);
      if (removeAttr) element.remove('follows');
      hasAttribute = true;
    }
    final nextRaw = element.get('next');
    if (nextRaw != null) {
      next = identityStr(nextRaw);
      if (removeAttr) element.remove('next');
      hasAttribute = true;
    }
    final precedesRaw = element.get('precedes');
    if (precedesRaw != null) {
      precedes = identityStr(precedesRaw);
      if (removeAttr) element.remove('precedes');
      hasAttribute = true;
    }
    final prevRaw = element.get('prev');
    if (prevRaw != null) {
      prev = identityStr(prevRaw);
      if (removeAttr) element.remove('prev');
      hasAttribute = true;
    }
    final sameasRaw = element.get('sameas');
    if (sameasRaw != null) {
      sameas = identityStr(sameasRaw);
      if (removeAttr) element.remove('sameas');
      hasAttribute = true;
    }
    final synchRaw = element.get('synch');
    if (synchRaw != null) {
      synch = identityStr(synchRaw);
      if (removeAttr) element.remove('synch');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLinking::WriteLinking`.
  void writeLinking(XmlBuilder element) {
    if (hasCopyof) {
      element.attribute('copyof', identityStr(copyof!));
    }
    if (hasCorresp) {
      element.attribute('corresp', identityStr(corresp!));
    }
    if (hasFollows) {
      element.attribute('follows', identityStr(follows!));
    }
    if (hasNext) {
      element.attribute('next', identityStr(next!));
    }
    if (hasPrecedes) {
      element.attribute('precedes', identityStr(precedes!));
    }
    if (hasPrev) {
      element.attribute('prev', identityStr(prev!));
    }
    if (hasSameas) {
      element.attribute('sameas', identityStr(sameas!));
    }
    if (hasSynch) {
      element.attribute('synch', identityStr(synch!));
    }
  }

  /// Copies the `AttLinking` members from [other].
  void copyAttLinking(covariant AttLinking other) {
    copyof = other.copyof;
    corresp = other.corresp;
    follows = other.follows;
    next = other.next;
    precedes = other.precedes;
    prev = other.prev;
    sameas = other.sameas;
    synch = other.synch;
  }
}

/// MEI attribute class for `att.LyricStyle` (mirrors `vrv::AttLyricStyle`).
mixin AttLyricStyle {
  /// `lyric.align` — data_MEASUREMENTSIGNED.
  MeasurementSigned? lyricAlign;
  bool get hasLyricAlign => lyricAlign != null;

  /// `lyric.fam` — std::string.
  String? lyricFam;
  bool get hasLyricFam => lyricFam != null;

  /// `lyric.name` — std::string.
  String? lyricName;
  bool get hasLyricName => lyricName != null;

  /// `lyric.size` — data_FONTSIZE.
  FontSize? lyricSize;
  bool get hasLyricSize => lyricSize != null;

  /// `lyric.style` — data_FONTSTYLE.
  Fontstyle? lyricStyle;
  bool get hasLyricStyle => lyricStyle != null;

  /// `lyric.weight` — data_FONTWEIGHT.
  Fontweight? lyricWeight;
  bool get hasLyricWeight => lyricWeight != null;

  /// Mirrors `AttLyricStyle::ReadLyricStyle`.
  bool readLyricStyle(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final lyricAlignRaw = element.get('lyric.align');
    if (lyricAlignRaw != null) {
      lyricAlign = strToMeasurementsigned(lyricAlignRaw);
      if (removeAttr) element.remove('lyric.align');
      hasAttribute = true;
    }
    final lyricFamRaw = element.get('lyric.fam');
    if (lyricFamRaw != null) {
      lyricFam = identityStr(lyricFamRaw);
      if (removeAttr) element.remove('lyric.fam');
      hasAttribute = true;
    }
    final lyricNameRaw = element.get('lyric.name');
    if (lyricNameRaw != null) {
      lyricName = identityStr(lyricNameRaw);
      if (removeAttr) element.remove('lyric.name');
      hasAttribute = true;
    }
    final lyricSizeRaw = element.get('lyric.size');
    if (lyricSizeRaw != null) {
      lyricSize = strToFontsize(lyricSizeRaw);
      if (removeAttr) element.remove('lyric.size');
      hasAttribute = true;
    }
    final lyricStyleRaw = element.get('lyric.style');
    if (lyricStyleRaw != null) {
      lyricStyle = strToFontstyle(lyricStyleRaw);
      if (removeAttr) element.remove('lyric.style');
      hasAttribute = true;
    }
    final lyricWeightRaw = element.get('lyric.weight');
    if (lyricWeightRaw != null) {
      lyricWeight = strToFontweight(lyricWeightRaw);
      if (removeAttr) element.remove('lyric.weight');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLyricStyle::WriteLyricStyle`.
  void writeLyricStyle(XmlBuilder element) {
    if (hasLyricAlign) {
      element.attribute('lyric.align', measurementsignedToStr(lyricAlign!));
    }
    if (hasLyricFam) {
      element.attribute('lyric.fam', identityStr(lyricFam!));
    }
    if (hasLyricName) {
      element.attribute('lyric.name', identityStr(lyricName!));
    }
    if (hasLyricSize) {
      element.attribute('lyric.size', fontsizeToStr(lyricSize!));
    }
    if (hasLyricStyle) {
      element.attribute('lyric.style', fontstyleToStr(lyricStyle!));
    }
    if (hasLyricWeight) {
      element.attribute('lyric.weight', fontweightToStr(lyricWeight!));
    }
  }

  /// Copies the `AttLyricStyle` members from [other].
  void copyAttLyricStyle(covariant AttLyricStyle other) {
    lyricAlign = other.lyricAlign;
    lyricFam = other.lyricFam;
    lyricName = other.lyricName;
    lyricSize = other.lyricSize;
    lyricStyle = other.lyricStyle;
    lyricWeight = other.lyricWeight;
  }
}

/// MEI attribute class for `att.MeasureNumbers` (mirrors `vrv::AttMeasureNumbers`).
mixin AttMeasureNumbers {
  /// `mnum.visible` — data_BOOLEAN.
  bool? mnumVisible;
  bool get hasMnumVisible => mnumVisible != null;

  /// Mirrors `AttMeasureNumbers::ReadMeasureNumbers`.
  bool readMeasureNumbers(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final mnumVisibleRaw = element.get('mnum.visible');
    if (mnumVisibleRaw != null) {
      mnumVisible = strToBoolean(mnumVisibleRaw);
      if (removeAttr) element.remove('mnum.visible');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeasureNumbers::WriteMeasureNumbers`.
  void writeMeasureNumbers(XmlBuilder element) {
    if (hasMnumVisible) {
      element.attribute('mnum.visible', booleanToStr(mnumVisible!));
    }
  }

  /// Copies the `AttMeasureNumbers` members from [other].
  void copyAttMeasureNumbers(covariant AttMeasureNumbers other) {
    mnumVisible = other.mnumVisible;
  }
}

/// MEI attribute class for `att.Measurement` (mirrors `vrv::AttMeasurement`).
mixin AttMeasurement {
  /// `unit` — std::string.
  String? unit;
  bool get hasUnit => unit != null;

  /// Mirrors `AttMeasurement::ReadMeasurement`.
  bool readMeasurement(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final unitRaw = element.get('unit');
    if (unitRaw != null) {
      unit = identityStr(unitRaw);
      if (removeAttr) element.remove('unit');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeasurement::WriteMeasurement`.
  void writeMeasurement(XmlBuilder element) {
    if (hasUnit) {
      element.attribute('unit', identityStr(unit!));
    }
  }

  /// Copies the `AttMeasurement` members from [other].
  void copyAttMeasurement(covariant AttMeasurement other) {
    unit = other.unit;
  }
}

/// MEI attribute class for `att.MediaBounds` (mirrors `vrv::AttMediaBounds`).
mixin AttMediaBounds {
  /// `begin` — std::string.
  String? begin;
  bool get hasBegin => begin != null;

  /// `end` — std::string.
  String? end;
  bool get hasEnd => end != null;

  /// `betype` — data_BETYPE.
  Betype? betype;
  bool get hasBetype => betype != null;

  /// Mirrors `AttMediaBounds::ReadMediaBounds`.
  bool readMediaBounds(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final beginRaw = element.get('begin');
    if (beginRaw != null) {
      begin = identityStr(beginRaw);
      if (removeAttr) element.remove('begin');
      hasAttribute = true;
    }
    final endRaw = element.get('end');
    if (endRaw != null) {
      end = identityStr(endRaw);
      if (removeAttr) element.remove('end');
      hasAttribute = true;
    }
    final betypeRaw = element.get('betype');
    if (betypeRaw != null) {
      betype = strToBetype(betypeRaw);
      if (removeAttr) element.remove('betype');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMediaBounds::WriteMediaBounds`.
  void writeMediaBounds(XmlBuilder element) {
    if (hasBegin) {
      element.attribute('begin', identityStr(begin!));
    }
    if (hasEnd) {
      element.attribute('end', identityStr(end!));
    }
    if (hasBetype) {
      element.attribute('betype', betypeToStr(betype!));
    }
  }

  /// Copies the `AttMediaBounds` members from [other].
  void copyAttMediaBounds(covariant AttMediaBounds other) {
    begin = other.begin;
    end = other.end;
    betype = other.betype;
  }
}

/// MEI attribute class for `att.Medium` (mirrors `vrv::AttMedium`).
mixin AttMedium {
  /// `medium` — std::string.
  String? medium;
  bool get hasMedium => medium != null;

  /// Mirrors `AttMedium::ReadMedium`.
  bool readMedium(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final mediumRaw = element.get('medium');
    if (mediumRaw != null) {
      medium = identityStr(mediumRaw);
      if (removeAttr) element.remove('medium');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMedium::WriteMedium`.
  void writeMedium(XmlBuilder element) {
    if (hasMedium) {
      element.attribute('medium', identityStr(medium!));
    }
  }

  /// Copies the `AttMedium` members from [other].
  void copyAttMedium(covariant AttMedium other) {
    medium = other.medium;
  }
}

/// MEI attribute class for `att.MeiVersion` (mirrors `vrv::AttMeiVersion`).
mixin AttMeiVersion {
  /// `meiversion` — meiVersion_MEIVERSION.
  MeiversionMeiversion? meiversion;
  bool get hasMeiversion => meiversion != null;

  /// Mirrors `AttMeiVersion::ReadMeiVersion`.
  bool readMeiVersion(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final meiversionRaw = element.get('meiversion');
    if (meiversionRaw != null) {
      meiversion = strToMeiversionMeiversion(meiversionRaw);
      if (removeAttr) element.remove('meiversion');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeiVersion::WriteMeiVersion`.
  void writeMeiVersion(XmlBuilder element) {
    if (hasMeiversion) {
      element.attribute('meiversion', meiversionMeiversionToStr(meiversion!));
    }
  }

  /// Copies the `AttMeiVersion` members from [other].
  void copyAttMeiVersion(covariant AttMeiVersion other) {
    meiversion = other.meiversion;
  }
}

/// MEI attribute class for `att.MensurLog` (mirrors `vrv::AttMensurLog`).
mixin AttMensurLog {
  /// `level` — data_DURATION.
  MeiDuration? level;
  bool get hasLevel => level != null;

  /// Mirrors `AttMensurLog::ReadMensurLog`.
  bool readMensurLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final levelRaw = element.get('level');
    if (levelRaw != null) {
      level = strToDuration(levelRaw);
      if (removeAttr) element.remove('level');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMensurLog::WriteMensurLog`.
  void writeMensurLog(XmlBuilder element) {
    if (hasLevel) {
      element.attribute('level', durationToStr(level!));
    }
  }

  /// Copies the `AttMensurLog` members from [other].
  void copyAttMensurLog(covariant AttMensurLog other) {
    level = other.level;
  }
}

/// MEI attribute class for `att.MetadataPointing` (mirrors `vrv::AttMetadataPointing`).
mixin AttMetadataPointing {
  /// `decls` — std::string.
  String? decls;
  bool get hasDecls => decls != null;

  /// Mirrors `AttMetadataPointing::ReadMetadataPointing`.
  bool readMetadataPointing(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final declsRaw = element.get('decls');
    if (declsRaw != null) {
      decls = identityStr(declsRaw);
      if (removeAttr) element.remove('decls');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMetadataPointing::WriteMetadataPointing`.
  void writeMetadataPointing(XmlBuilder element) {
    if (hasDecls) {
      element.attribute('decls', identityStr(decls!));
    }
  }

  /// Copies the `AttMetadataPointing` members from [other].
  void copyAttMetadataPointing(covariant AttMetadataPointing other) {
    decls = other.decls;
  }
}

/// MEI attribute class for `att.MeterConformance` (mirrors `vrv::AttMeterConformance`).
mixin AttMeterConformance {
  /// `metcon` — meterConformance_METCON.
  MeterconformanceMetcon? metcon;
  bool get hasMetcon => metcon != null;

  /// Mirrors `AttMeterConformance::ReadMeterConformance`.
  bool readMeterConformance(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final metconRaw = element.get('metcon');
    if (metconRaw != null) {
      metcon = strToMeterconformanceMetcon(metconRaw);
      if (removeAttr) element.remove('metcon');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeterConformance::WriteMeterConformance`.
  void writeMeterConformance(XmlBuilder element) {
    if (hasMetcon) {
      element.attribute('metcon', meterconformanceMetconToStr(metcon!));
    }
  }

  /// Copies the `AttMeterConformance` members from [other].
  void copyAttMeterConformance(covariant AttMeterConformance other) {
    metcon = other.metcon;
  }
}

/// MEI attribute class for `att.MeterConformanceBar` (mirrors `vrv::AttMeterConformanceBar`).
mixin AttMeterConformanceBar {
  /// `metcon` — data_BOOLEAN.
  bool? metcon;
  bool get hasMetcon => metcon != null;

  /// `control` — data_BOOLEAN.
  bool? control;
  bool get hasControl => control != null;

  /// Mirrors `AttMeterConformanceBar::ReadMeterConformanceBar`.
  bool readMeterConformanceBar(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final metconRaw = element.get('metcon');
    if (metconRaw != null) {
      metcon = strToBoolean(metconRaw);
      if (removeAttr) element.remove('metcon');
      hasAttribute = true;
    }
    final controlRaw = element.get('control');
    if (controlRaw != null) {
      control = strToBoolean(controlRaw);
      if (removeAttr) element.remove('control');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeterConformanceBar::WriteMeterConformanceBar`.
  void writeMeterConformanceBar(XmlBuilder element) {
    if (hasMetcon) {
      element.attribute('metcon', booleanToStr(metcon!));
    }
    if (hasControl) {
      element.attribute('control', booleanToStr(control!));
    }
  }

  /// Copies the `AttMeterConformanceBar` members from [other].
  void copyAttMeterConformanceBar(covariant AttMeterConformanceBar other) {
    metcon = other.metcon;
    control = other.control;
  }
}

/// MEI attribute class for `att.MeterSigLog` (mirrors `vrv::AttMeterSigLog`).
mixin AttMeterSigLog {
  /// `count` — data_METERCOUNT_pair.
  MeterCountPair? count;
  bool get hasCount => count != null;

  /// `sym` — data_METERSIGN.
  Metersign? sym;
  bool get hasSym => sym != null;

  /// `unit` — int.
  int? unit;
  bool get hasUnit => unit != null;

  /// Mirrors `AttMeterSigLog::ReadMeterSigLog`.
  bool readMeterSigLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final countRaw = element.get('count');
    if (countRaw != null) {
      count = strToMetercountPair(countRaw);
      if (removeAttr) element.remove('count');
      hasAttribute = true;
    }
    final symRaw = element.get('sym');
    if (symRaw != null) {
      sym = strToMetersign(symRaw);
      if (removeAttr) element.remove('sym');
      hasAttribute = true;
    }
    final unitRaw = element.get('unit');
    if (unitRaw != null) {
      unit = strToInt(unitRaw);
      if (removeAttr) element.remove('unit');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeterSigLog::WriteMeterSigLog`.
  void writeMeterSigLog(XmlBuilder element) {
    if (hasCount) {
      element.attribute('count', metercountPairToStr(count!));
    }
    if (hasSym) {
      element.attribute('sym', metersignToStr(sym!));
    }
    if (hasUnit) {
      element.attribute('unit', intToStr(unit!));
    }
  }

  /// Copies the `AttMeterSigLog` members from [other].
  void copyAttMeterSigLog(covariant AttMeterSigLog other) {
    count = other.count;
    sym = other.sym;
    unit = other.unit;
  }
}

/// MEI attribute class for `att.MeterSigDefaultLog` (mirrors `vrv::AttMeterSigDefaultLog`).
mixin AttMeterSigDefaultLog {
  /// `meter.count` — data_METERCOUNT_pair.
  MeterCountPair? meterCount;
  bool get hasMeterCount => meterCount != null;

  /// `meter.unit` — int.
  int? meterUnit;
  bool get hasMeterUnit => meterUnit != null;

  /// `meter.sym` — data_METERSIGN.
  Metersign? meterSym;
  bool get hasMeterSym => meterSym != null;

  /// Mirrors `AttMeterSigDefaultLog::ReadMeterSigDefaultLog`.
  bool readMeterSigDefaultLog(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final meterCountRaw = element.get('meter.count');
    if (meterCountRaw != null) {
      meterCount = strToMetercountPair(meterCountRaw);
      if (removeAttr) element.remove('meter.count');
      hasAttribute = true;
    }
    final meterUnitRaw = element.get('meter.unit');
    if (meterUnitRaw != null) {
      meterUnit = strToInt(meterUnitRaw);
      if (removeAttr) element.remove('meter.unit');
      hasAttribute = true;
    }
    final meterSymRaw = element.get('meter.sym');
    if (meterSymRaw != null) {
      meterSym = strToMetersign(meterSymRaw);
      if (removeAttr) element.remove('meter.sym');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeterSigDefaultLog::WriteMeterSigDefaultLog`.
  void writeMeterSigDefaultLog(XmlBuilder element) {
    if (hasMeterCount) {
      element.attribute('meter.count', metercountPairToStr(meterCount!));
    }
    if (hasMeterUnit) {
      element.attribute('meter.unit', intToStr(meterUnit!));
    }
    if (hasMeterSym) {
      element.attribute('meter.sym', metersignToStr(meterSym!));
    }
  }

  /// Copies the `AttMeterSigDefaultLog` members from [other].
  void copyAttMeterSigDefaultLog(covariant AttMeterSigDefaultLog other) {
    meterCount = other.meterCount;
    meterUnit = other.meterUnit;
    meterSym = other.meterSym;
  }
}

/// MEI attribute class for `att.MmTempo` (mirrors `vrv::AttMmTempo`).
mixin AttMmTempo {
  /// `mm` — double.
  double? mm;
  bool get hasMm => mm != null;

  /// `mm.unit` — data_DURATION.
  MeiDuration? mmUnit;
  bool get hasMmUnit => mmUnit != null;

  /// `mm.dots` — int.
  int? mmDots;
  bool get hasMmDots => mmDots != null;

  /// Mirrors `AttMmTempo::ReadMmTempo`.
  bool readMmTempo(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final mmRaw = element.get('mm');
    if (mmRaw != null) {
      mm = strToDbl(mmRaw);
      if (removeAttr) element.remove('mm');
      hasAttribute = true;
    }
    final mmUnitRaw = element.get('mm.unit');
    if (mmUnitRaw != null) {
      mmUnit = strToDuration(mmUnitRaw);
      if (removeAttr) element.remove('mm.unit');
      hasAttribute = true;
    }
    final mmDotsRaw = element.get('mm.dots');
    if (mmDotsRaw != null) {
      mmDots = strToInt(mmDotsRaw);
      if (removeAttr) element.remove('mm.dots');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMmTempo::WriteMmTempo`.
  void writeMmTempo(XmlBuilder element) {
    if (hasMm) {
      element.attribute('mm', dblToStr(mm!));
    }
    if (hasMmUnit) {
      element.attribute('mm.unit', durationToStr(mmUnit!));
    }
    if (hasMmDots) {
      element.attribute('mm.dots', intToStr(mmDots!));
    }
  }

  /// Copies the `AttMmTempo` members from [other].
  void copyAttMmTempo(covariant AttMmTempo other) {
    mm = other.mm;
    mmUnit = other.mmUnit;
    mmDots = other.mmDots;
  }
}

/// MEI attribute class for `att.MultinumMeasures` (mirrors `vrv::AttMultinumMeasures`).
mixin AttMultinumMeasures {
  /// `multi.number` — data_BOOLEAN.
  bool? multiNumber;
  bool get hasMultiNumber => multiNumber != null;

  /// Mirrors `AttMultinumMeasures::ReadMultinumMeasures`.
  bool readMultinumMeasures(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final multiNumberRaw = element.get('multi.number');
    if (multiNumberRaw != null) {
      multiNumber = strToBoolean(multiNumberRaw);
      if (removeAttr) element.remove('multi.number');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMultinumMeasures::WriteMultinumMeasures`.
  void writeMultinumMeasures(XmlBuilder element) {
    if (hasMultiNumber) {
      element.attribute('multi.number', booleanToStr(multiNumber!));
    }
  }

  /// Copies the `AttMultinumMeasures` members from [other].
  void copyAttMultinumMeasures(covariant AttMultinumMeasures other) {
    multiNumber = other.multiNumber;
  }
}

/// MEI attribute class for `att.NInteger` (mirrors `vrv::AttNInteger`).
mixin AttNInteger {
  /// `n` — int.
  int? n;
  bool get hasN => n != null;

  /// Mirrors `AttNInteger::ReadNInteger`.
  bool readNInteger(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final nRaw = element.get('n');
    if (nRaw != null) {
      n = strToInt(nRaw);
      if (removeAttr) element.remove('n');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNInteger::WriteNInteger`.
  void writeNInteger(XmlBuilder element) {
    if (hasN) {
      element.attribute('n', intToStr(n!));
    }
  }

  /// Copies the `AttNInteger` members from [other].
  void copyAttNInteger(covariant AttNInteger other) {
    n = other.n;
  }
}

/// MEI attribute class for `att.NNumberLike` (mirrors `vrv::AttNNumberLike`).
mixin AttNNumberLike {
  /// `n` — std::string.
  String? n;
  bool get hasN => n != null;

  /// Mirrors `AttNNumberLike::ReadNNumberLike`.
  bool readNNumberLike(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final nRaw = element.get('n');
    if (nRaw != null) {
      n = identityStr(nRaw);
      if (removeAttr) element.remove('n');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNNumberLike::WriteNNumberLike`.
  void writeNNumberLike(XmlBuilder element) {
    if (hasN) {
      element.attribute('n', identityStr(n!));
    }
  }

  /// Copies the `AttNNumberLike` members from [other].
  void copyAttNNumberLike(covariant AttNNumberLike other) {
    n = other.n;
  }
}

/// MEI attribute class for `att.Name` (mirrors `vrv::AttName`).
mixin AttName {
  /// `nymref` — std::string.
  String? nymref;
  bool get hasNymref => nymref != null;

  /// `role` — data_RELATORS.
  Relators? role;
  bool get hasRole => role != null;

  /// Mirrors `AttName::ReadName`.
  bool readName(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final nymrefRaw = element.get('nymref');
    if (nymrefRaw != null) {
      nymref = identityStr(nymrefRaw);
      if (removeAttr) element.remove('nymref');
      hasAttribute = true;
    }
    final roleRaw = element.get('role');
    if (roleRaw != null) {
      role = strToRelators(roleRaw);
      if (removeAttr) element.remove('role');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttName::WriteName`.
  void writeName(XmlBuilder element) {
    if (hasNymref) {
      element.attribute('nymref', identityStr(nymref!));
    }
    if (hasRole) {
      element.attribute('role', relatorsToStr(role!));
    }
  }

  /// Copies the `AttName` members from [other].
  void copyAttName(covariant AttName other) {
    nymref = other.nymref;
    role = other.role;
  }
}

/// MEI attribute class for `att.NotationStyle` (mirrors `vrv::AttNotationStyle`).
mixin AttNotationStyle {
  /// `music.name` — std::string.
  String? musicName;
  bool get hasMusicName => musicName != null;

  /// `music.size` — data_FONTSIZE.
  FontSize? musicSize;
  bool get hasMusicSize => musicSize != null;

  /// Mirrors `AttNotationStyle::ReadNotationStyle`.
  bool readNotationStyle(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final musicNameRaw = element.get('music.name');
    if (musicNameRaw != null) {
      musicName = identityStr(musicNameRaw);
      if (removeAttr) element.remove('music.name');
      hasAttribute = true;
    }
    final musicSizeRaw = element.get('music.size');
    if (musicSizeRaw != null) {
      musicSize = strToFontsize(musicSizeRaw);
      if (removeAttr) element.remove('music.size');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNotationStyle::WriteNotationStyle`.
  void writeNotationStyle(XmlBuilder element) {
    if (hasMusicName) {
      element.attribute('music.name', identityStr(musicName!));
    }
    if (hasMusicSize) {
      element.attribute('music.size', fontsizeToStr(musicSize!));
    }
  }

  /// Copies the `AttNotationStyle` members from [other].
  void copyAttNotationStyle(covariant AttNotationStyle other) {
    musicName = other.musicName;
    musicSize = other.musicSize;
  }
}

/// MEI attribute class for `att.NoteHeads` (mirrors `vrv::AttNoteHeads`).
mixin AttNoteHeads {
  /// `head.altsym` — std::string.
  String? headAltsym;
  bool get hasHeadAltsym => headAltsym != null;

  /// `head.auth` — std::string.
  String? headAuth;
  bool get hasHeadAuth => headAuth != null;

  /// `head.color` — std::string.
  String? headColor;
  bool get hasHeadColor => headColor != null;

  /// `head.fill` — data_FILL.
  Fill? headFill;
  bool get hasHeadFill => headFill != null;

  /// `head.fillcolor` — std::string.
  String? headFillcolor;
  bool get hasHeadFillcolor => headFillcolor != null;

  /// `head.mod` — data_NOTEHEADMODIFIER.
  Noteheadmodifier? headMod;
  bool get hasHeadMod => headMod != null;

  /// `head.rotation` — data_ROTATION.
  Rotation? headRotation;
  bool get hasHeadRotation => headRotation != null;

  /// `head.shape` — data_HEADSHAPE.
  HeadShape? headShape;
  bool get hasHeadShape => headShape != null;

  /// `head.visible` — data_BOOLEAN.
  bool? headVisible;
  bool get hasHeadVisible => headVisible != null;

  /// Mirrors `AttNoteHeads::ReadNoteHeads`.
  bool readNoteHeads(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final headAltsymRaw = element.get('head.altsym');
    if (headAltsymRaw != null) {
      headAltsym = identityStr(headAltsymRaw);
      if (removeAttr) element.remove('head.altsym');
      hasAttribute = true;
    }
    final headAuthRaw = element.get('head.auth');
    if (headAuthRaw != null) {
      headAuth = identityStr(headAuthRaw);
      if (removeAttr) element.remove('head.auth');
      hasAttribute = true;
    }
    final headColorRaw = element.get('head.color');
    if (headColorRaw != null) {
      headColor = identityStr(headColorRaw);
      if (removeAttr) element.remove('head.color');
      hasAttribute = true;
    }
    final headFillRaw = element.get('head.fill');
    if (headFillRaw != null) {
      headFill = strToFill(headFillRaw);
      if (removeAttr) element.remove('head.fill');
      hasAttribute = true;
    }
    final headFillcolorRaw = element.get('head.fillcolor');
    if (headFillcolorRaw != null) {
      headFillcolor = identityStr(headFillcolorRaw);
      if (removeAttr) element.remove('head.fillcolor');
      hasAttribute = true;
    }
    final headModRaw = element.get('head.mod');
    if (headModRaw != null) {
      headMod = strToNoteheadmodifier(headModRaw);
      if (removeAttr) element.remove('head.mod');
      hasAttribute = true;
    }
    final headRotationRaw = element.get('head.rotation');
    if (headRotationRaw != null) {
      headRotation = strToRotation(headRotationRaw);
      if (removeAttr) element.remove('head.rotation');
      hasAttribute = true;
    }
    final headShapeRaw = element.get('head.shape');
    if (headShapeRaw != null) {
      headShape = strToHeadshape(headShapeRaw);
      if (removeAttr) element.remove('head.shape');
      hasAttribute = true;
    }
    final headVisibleRaw = element.get('head.visible');
    if (headVisibleRaw != null) {
      headVisible = strToBoolean(headVisibleRaw);
      if (removeAttr) element.remove('head.visible');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNoteHeads::WriteNoteHeads`.
  void writeNoteHeads(XmlBuilder element) {
    if (hasHeadAltsym) {
      element.attribute('head.altsym', identityStr(headAltsym!));
    }
    if (hasHeadAuth) {
      element.attribute('head.auth', identityStr(headAuth!));
    }
    if (hasHeadColor) {
      element.attribute('head.color', identityStr(headColor!));
    }
    if (hasHeadFill) {
      element.attribute('head.fill', fillToStr(headFill!));
    }
    if (hasHeadFillcolor) {
      element.attribute('head.fillcolor', identityStr(headFillcolor!));
    }
    if (hasHeadMod) {
      element.attribute('head.mod', noteheadmodifierToStr(headMod!));
    }
    if (hasHeadRotation) {
      element.attribute('head.rotation', rotationToStr(headRotation!));
    }
    if (hasHeadShape) {
      element.attribute('head.shape', headshapeToStr(headShape!));
    }
    if (hasHeadVisible) {
      element.attribute('head.visible', booleanToStr(headVisible!));
    }
  }

  /// Copies the `AttNoteHeads` members from [other].
  void copyAttNoteHeads(covariant AttNoteHeads other) {
    headAltsym = other.headAltsym;
    headAuth = other.headAuth;
    headColor = other.headColor;
    headFill = other.headFill;
    headFillcolor = other.headFillcolor;
    headMod = other.headMod;
    headRotation = other.headRotation;
    headShape = other.headShape;
    headVisible = other.headVisible;
  }
}

/// MEI attribute class for `att.Octave` (mirrors `vrv::AttOctave`).
mixin AttOctave {
  /// `oct` — data_OCTAVE.
  int? oct;
  bool get hasOct => oct != null;

  /// Mirrors `AttOctave::ReadOctave`.
  bool readOctave(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final octRaw = element.get('oct');
    if (octRaw != null) {
      oct = strToInt(octRaw);
      if (removeAttr) element.remove('oct');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOctave::WriteOctave`.
  void writeOctave(XmlBuilder element) {
    if (hasOct) {
      element.attribute('oct', octaveToStr(oct!));
    }
  }

  /// Copies the `AttOctave` members from [other].
  void copyAttOctave(covariant AttOctave other) {
    oct = other.oct;
  }
}

/// MEI attribute class for `att.OctaveDefault` (mirrors `vrv::AttOctaveDefault`).
mixin AttOctaveDefault {
  /// `oct.default` — data_OCTAVE.
  int? octDefault;
  bool get hasOctDefault => octDefault != null;

  /// Mirrors `AttOctaveDefault::ReadOctaveDefault`.
  bool readOctaveDefault(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final octDefaultRaw = element.get('oct.default');
    if (octDefaultRaw != null) {
      octDefault = strToInt(octDefaultRaw);
      if (removeAttr) element.remove('oct.default');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOctaveDefault::WriteOctaveDefault`.
  void writeOctaveDefault(XmlBuilder element) {
    if (hasOctDefault) {
      element.attribute('oct.default', octaveToStr(octDefault!));
    }
  }

  /// Copies the `AttOctaveDefault` members from [other].
  void copyAttOctaveDefault(covariant AttOctaveDefault other) {
    octDefault = other.octDefault;
  }
}

/// MEI attribute class for `att.OctaveDisplacement` (mirrors `vrv::AttOctaveDisplacement`).
mixin AttOctaveDisplacement {
  /// `dis` — data_OCTAVE_DIS.
  OctaveDis? dis;
  bool get hasDis => dis != null;

  /// `dis.place` — data_STAFFREL_basic.
  StaffrelBasic? disPlace;
  bool get hasDisPlace => disPlace != null;

  /// Mirrors `AttOctaveDisplacement::ReadOctaveDisplacement`.
  bool readOctaveDisplacement(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final disRaw = element.get('dis');
    if (disRaw != null) {
      dis = strToOctaveDis(disRaw);
      if (removeAttr) element.remove('dis');
      hasAttribute = true;
    }
    final disPlaceRaw = element.get('dis.place');
    if (disPlaceRaw != null) {
      disPlace = strToStaffrelBasic(disPlaceRaw);
      if (removeAttr) element.remove('dis.place');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOctaveDisplacement::WriteOctaveDisplacement`.
  void writeOctaveDisplacement(XmlBuilder element) {
    if (hasDis) {
      element.attribute('dis', octaveDisToStr(dis!));
    }
    if (hasDisPlace) {
      element.attribute('dis.place', staffrelBasicToStr(disPlace!));
    }
  }

  /// Copies the `AttOctaveDisplacement` members from [other].
  void copyAttOctaveDisplacement(covariant AttOctaveDisplacement other) {
    dis = other.dis;
    disPlace = other.disPlace;
  }
}

/// MEI attribute class for `att.OneLineStaff` (mirrors `vrv::AttOneLineStaff`).
mixin AttOneLineStaff {
  /// `ontheline` — data_BOOLEAN.
  bool? ontheline;
  bool get hasOntheline => ontheline != null;

  /// Mirrors `AttOneLineStaff::ReadOneLineStaff`.
  bool readOneLineStaff(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final onthelineRaw = element.get('ontheline');
    if (onthelineRaw != null) {
      ontheline = strToBoolean(onthelineRaw);
      if (removeAttr) element.remove('ontheline');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOneLineStaff::WriteOneLineStaff`.
  void writeOneLineStaff(XmlBuilder element) {
    if (hasOntheline) {
      element.attribute('ontheline', booleanToStr(ontheline!));
    }
  }

  /// Copies the `AttOneLineStaff` members from [other].
  void copyAttOneLineStaff(covariant AttOneLineStaff other) {
    ontheline = other.ontheline;
  }
}

/// MEI attribute class for `att.Optimization` (mirrors `vrv::AttOptimization`).
mixin AttOptimization {
  /// `optimize` — data_BOOLEAN.
  bool? optimize;
  bool get hasOptimize => optimize != null;

  /// Mirrors `AttOptimization::ReadOptimization`.
  bool readOptimization(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final optimizeRaw = element.get('optimize');
    if (optimizeRaw != null) {
      optimize = strToBoolean(optimizeRaw);
      if (removeAttr) element.remove('optimize');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOptimization::WriteOptimization`.
  void writeOptimization(XmlBuilder element) {
    if (hasOptimize) {
      element.attribute('optimize', booleanToStr(optimize!));
    }
  }

  /// Copies the `AttOptimization` members from [other].
  void copyAttOptimization(covariant AttOptimization other) {
    optimize = other.optimize;
  }
}

/// MEI attribute class for `att.OriginLayerIdent` (mirrors `vrv::AttOriginLayerIdent`).
mixin AttOriginLayerIdent {
  /// `origin.layer` — std::string.
  String? originLayer;
  bool get hasOriginLayer => originLayer != null;

  /// Mirrors `AttOriginLayerIdent::ReadOriginLayerIdent`.
  bool readOriginLayerIdent(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final originLayerRaw = element.get('origin.layer');
    if (originLayerRaw != null) {
      originLayer = identityStr(originLayerRaw);
      if (removeAttr) element.remove('origin.layer');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOriginLayerIdent::WriteOriginLayerIdent`.
  void writeOriginLayerIdent(XmlBuilder element) {
    if (hasOriginLayer) {
      element.attribute('origin.layer', identityStr(originLayer!));
    }
  }

  /// Copies the `AttOriginLayerIdent` members from [other].
  void copyAttOriginLayerIdent(covariant AttOriginLayerIdent other) {
    originLayer = other.originLayer;
  }
}

/// MEI attribute class for `att.OriginStaffIdent` (mirrors `vrv::AttOriginStaffIdent`).
mixin AttOriginStaffIdent {
  /// `origin.staff` — std::string.
  String? originStaff;
  bool get hasOriginStaff => originStaff != null;

  /// Mirrors `AttOriginStaffIdent::ReadOriginStaffIdent`.
  bool readOriginStaffIdent(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final originStaffRaw = element.get('origin.staff');
    if (originStaffRaw != null) {
      originStaff = identityStr(originStaffRaw);
      if (removeAttr) element.remove('origin.staff');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOriginStaffIdent::WriteOriginStaffIdent`.
  void writeOriginStaffIdent(XmlBuilder element) {
    if (hasOriginStaff) {
      element.attribute('origin.staff', identityStr(originStaff!));
    }
  }

  /// Copies the `AttOriginStaffIdent` members from [other].
  void copyAttOriginStaffIdent(covariant AttOriginStaffIdent other) {
    originStaff = other.originStaff;
  }
}

/// MEI attribute class for `att.OriginStartEndId` (mirrors `vrv::AttOriginStartEndId`).
mixin AttOriginStartEndId {
  /// `origin.startid` — std::string.
  String? originStartid;
  bool get hasOriginStartid => originStartid != null;

  /// `origin.endid` — std::string.
  String? originEndid;
  bool get hasOriginEndid => originEndid != null;

  /// Mirrors `AttOriginStartEndId::ReadOriginStartEndId`.
  bool readOriginStartEndId(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final originStartidRaw = element.get('origin.startid');
    if (originStartidRaw != null) {
      originStartid = identityStr(originStartidRaw);
      if (removeAttr) element.remove('origin.startid');
      hasAttribute = true;
    }
    final originEndidRaw = element.get('origin.endid');
    if (originEndidRaw != null) {
      originEndid = identityStr(originEndidRaw);
      if (removeAttr) element.remove('origin.endid');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOriginStartEndId::WriteOriginStartEndId`.
  void writeOriginStartEndId(XmlBuilder element) {
    if (hasOriginStartid) {
      element.attribute('origin.startid', identityStr(originStartid!));
    }
    if (hasOriginEndid) {
      element.attribute('origin.endid', identityStr(originEndid!));
    }
  }

  /// Copies the `AttOriginStartEndId` members from [other].
  void copyAttOriginStartEndId(covariant AttOriginStartEndId other) {
    originStartid = other.originStartid;
    originEndid = other.originEndid;
  }
}

/// MEI attribute class for `att.OriginTimestampLog` (mirrors `vrv::AttOriginTimestampLog`).
mixin AttOriginTimestampLog {
  /// `origin.tstamp` — data_MEASUREBEAT.
  MeasureBeat? originTstamp;
  bool get hasOriginTstamp => originTstamp != null;

  /// `origin.tstamp2` — data_MEASUREBEAT.
  MeasureBeat? originTstamp2;
  bool get hasOriginTstamp2 => originTstamp2 != null;

  /// Mirrors `AttOriginTimestampLog::ReadOriginTimestampLog`.
  bool readOriginTimestampLog(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final originTstampRaw = element.get('origin.tstamp');
    if (originTstampRaw != null) {
      originTstamp = strToMeasurebeat(originTstampRaw);
      if (removeAttr) element.remove('origin.tstamp');
      hasAttribute = true;
    }
    final originTstamp2Raw = element.get('origin.tstamp2');
    if (originTstamp2Raw != null) {
      originTstamp2 = strToMeasurebeat(originTstamp2Raw);
      if (removeAttr) element.remove('origin.tstamp2');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOriginTimestampLog::WriteOriginTimestampLog`.
  void writeOriginTimestampLog(XmlBuilder element) {
    if (hasOriginTstamp) {
      element.attribute('origin.tstamp', measurebeatToStr(originTstamp!));
    }
    if (hasOriginTstamp2) {
      element.attribute('origin.tstamp2', measurebeatToStr(originTstamp2!));
    }
  }

  /// Copies the `AttOriginTimestampLog` members from [other].
  void copyAttOriginTimestampLog(covariant AttOriginTimestampLog other) {
    originTstamp = other.originTstamp;
    originTstamp2 = other.originTstamp2;
  }
}

/// MEI attribute class for `att.Pages` (mirrors `vrv::AttPages`).
mixin AttPages {
  /// `page.height` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? pageHeight;
  bool get hasPageHeight => pageHeight != null;

  /// `page.width` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? pageWidth;
  bool get hasPageWidth => pageWidth != null;

  /// `page.topmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? pageTopmar;
  bool get hasPageTopmar => pageTopmar != null;

  /// `page.botmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? pageBotmar;
  bool get hasPageBotmar => pageBotmar != null;

  /// `page.leftmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? pageLeftmar;
  bool get hasPageLeftmar => pageLeftmar != null;

  /// `page.rightmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? pageRightmar;
  bool get hasPageRightmar => pageRightmar != null;

  /// `page.panels` — std::string.
  String? pagePanels;
  bool get hasPagePanels => pagePanels != null;

  /// `page.scale` — std::string.
  String? pageScale;
  bool get hasPageScale => pageScale != null;

  /// Mirrors `AttPages::ReadPages`.
  bool readPages(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final pageHeightRaw = element.get('page.height');
    if (pageHeightRaw != null) {
      pageHeight = strToMeasurementunsigned(pageHeightRaw);
      if (removeAttr) element.remove('page.height');
      hasAttribute = true;
    }
    final pageWidthRaw = element.get('page.width');
    if (pageWidthRaw != null) {
      pageWidth = strToMeasurementunsigned(pageWidthRaw);
      if (removeAttr) element.remove('page.width');
      hasAttribute = true;
    }
    final pageTopmarRaw = element.get('page.topmar');
    if (pageTopmarRaw != null) {
      pageTopmar = strToMeasurementunsigned(pageTopmarRaw);
      if (removeAttr) element.remove('page.topmar');
      hasAttribute = true;
    }
    final pageBotmarRaw = element.get('page.botmar');
    if (pageBotmarRaw != null) {
      pageBotmar = strToMeasurementunsigned(pageBotmarRaw);
      if (removeAttr) element.remove('page.botmar');
      hasAttribute = true;
    }
    final pageLeftmarRaw = element.get('page.leftmar');
    if (pageLeftmarRaw != null) {
      pageLeftmar = strToMeasurementunsigned(pageLeftmarRaw);
      if (removeAttr) element.remove('page.leftmar');
      hasAttribute = true;
    }
    final pageRightmarRaw = element.get('page.rightmar');
    if (pageRightmarRaw != null) {
      pageRightmar = strToMeasurementunsigned(pageRightmarRaw);
      if (removeAttr) element.remove('page.rightmar');
      hasAttribute = true;
    }
    final pagePanelsRaw = element.get('page.panels');
    if (pagePanelsRaw != null) {
      pagePanels = identityStr(pagePanelsRaw);
      if (removeAttr) element.remove('page.panels');
      hasAttribute = true;
    }
    final pageScaleRaw = element.get('page.scale');
    if (pageScaleRaw != null) {
      pageScale = identityStr(pageScaleRaw);
      if (removeAttr) element.remove('page.scale');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPages::WritePages`.
  void writePages(XmlBuilder element) {
    if (hasPageHeight) {
      element.attribute('page.height', measurementunsignedToStr(pageHeight!));
    }
    if (hasPageWidth) {
      element.attribute('page.width', measurementunsignedToStr(pageWidth!));
    }
    if (hasPageTopmar) {
      element.attribute('page.topmar', measurementunsignedToStr(pageTopmar!));
    }
    if (hasPageBotmar) {
      element.attribute('page.botmar', measurementunsignedToStr(pageBotmar!));
    }
    if (hasPageLeftmar) {
      element.attribute('page.leftmar', measurementunsignedToStr(pageLeftmar!));
    }
    if (hasPageRightmar) {
      element.attribute(
          'page.rightmar', measurementunsignedToStr(pageRightmar!));
    }
    if (hasPagePanels) {
      element.attribute('page.panels', identityStr(pagePanels!));
    }
    if (hasPageScale) {
      element.attribute('page.scale', identityStr(pageScale!));
    }
  }

  /// Copies the `AttPages` members from [other].
  void copyAttPages(covariant AttPages other) {
    pageHeight = other.pageHeight;
    pageWidth = other.pageWidth;
    pageTopmar = other.pageTopmar;
    pageBotmar = other.pageBotmar;
    pageLeftmar = other.pageLeftmar;
    pageRightmar = other.pageRightmar;
    pagePanels = other.pagePanels;
    pageScale = other.pageScale;
  }
}

/// MEI attribute class for `att.PartIdent` (mirrors `vrv::AttPartIdent`).
mixin AttPartIdent {
  /// `part` — std::string.
  String? part;
  bool get hasPart => part != null;

  /// `partstaff` — std::string.
  String? partstaff;
  bool get hasPartstaff => partstaff != null;

  /// Mirrors `AttPartIdent::ReadPartIdent`.
  bool readPartIdent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final partRaw = element.get('part');
    if (partRaw != null) {
      part = identityStr(partRaw);
      if (removeAttr) element.remove('part');
      hasAttribute = true;
    }
    final partstaffRaw = element.get('partstaff');
    if (partstaffRaw != null) {
      partstaff = identityStr(partstaffRaw);
      if (removeAttr) element.remove('partstaff');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPartIdent::WritePartIdent`.
  void writePartIdent(XmlBuilder element) {
    if (hasPart) {
      element.attribute('part', identityStr(part!));
    }
    if (hasPartstaff) {
      element.attribute('partstaff', identityStr(partstaff!));
    }
  }

  /// Copies the `AttPartIdent` members from [other].
  void copyAttPartIdent(covariant AttPartIdent other) {
    part = other.part;
    partstaff = other.partstaff;
  }
}

/// MEI attribute class for `att.Pitch` (mirrors `vrv::AttPitch`).
mixin AttPitch {
  /// `pname` — data_PITCHNAME.
  Pitchname? pname;
  bool get hasPname => pname != null;

  /// Mirrors `AttPitch::ReadPitch`.
  bool readPitch(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final pnameRaw = element.get('pname');
    if (pnameRaw != null) {
      pname = strToPitchname(pnameRaw);
      if (removeAttr) element.remove('pname');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPitch::WritePitch`.
  void writePitch(XmlBuilder element) {
    if (hasPname) {
      element.attribute('pname', pitchnameToStr(pname!));
    }
  }

  /// Copies the `AttPitch` members from [other].
  void copyAttPitch(covariant AttPitch other) {
    pname = other.pname;
  }
}

/// MEI attribute class for `att.PlacementOnStaff` (mirrors `vrv::AttPlacementOnStaff`).
mixin AttPlacementOnStaff {
  /// `onstaff` — data_BOOLEAN.
  bool? onstaff;
  bool get hasOnstaff => onstaff != null;

  /// Mirrors `AttPlacementOnStaff::ReadPlacementOnStaff`.
  bool readPlacementOnStaff(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final onstaffRaw = element.get('onstaff');
    if (onstaffRaw != null) {
      onstaff = strToBoolean(onstaffRaw);
      if (removeAttr) element.remove('onstaff');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPlacementOnStaff::WritePlacementOnStaff`.
  void writePlacementOnStaff(XmlBuilder element) {
    if (hasOnstaff) {
      element.attribute('onstaff', booleanToStr(onstaff!));
    }
  }

  /// Copies the `AttPlacementOnStaff` members from [other].
  void copyAttPlacementOnStaff(covariant AttPlacementOnStaff other) {
    onstaff = other.onstaff;
  }
}

/// MEI attribute class for `att.PlacementRelEvent` (mirrors `vrv::AttPlacementRelEvent`).
mixin AttPlacementRelEvent {
  /// `place` — data_STAFFREL.
  Staffrel? place;
  bool get hasPlace => place != null;

  /// Mirrors `AttPlacementRelEvent::ReadPlacementRelEvent`.
  bool readPlacementRelEvent(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final placeRaw = element.get('place');
    if (placeRaw != null) {
      place = strToStaffrel(placeRaw);
      if (removeAttr) element.remove('place');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPlacementRelEvent::WritePlacementRelEvent`.
  void writePlacementRelEvent(XmlBuilder element) {
    if (hasPlace) {
      element.attribute('place', staffrelToStr(place!));
    }
  }

  /// Copies the `AttPlacementRelEvent` members from [other].
  void copyAttPlacementRelEvent(covariant AttPlacementRelEvent other) {
    place = other.place;
  }
}

/// MEI attribute class for `att.PlacementRelStaff` (mirrors `vrv::AttPlacementRelStaff`).
mixin AttPlacementRelStaff {
  /// `place` — data_STAFFREL.
  Staffrel? place;
  bool get hasPlace => place != null;

  /// Mirrors `AttPlacementRelStaff::ReadPlacementRelStaff`.
  bool readPlacementRelStaff(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final placeRaw = element.get('place');
    if (placeRaw != null) {
      place = strToStaffrel(placeRaw);
      if (removeAttr) element.remove('place');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPlacementRelStaff::WritePlacementRelStaff`.
  void writePlacementRelStaff(XmlBuilder element) {
    if (hasPlace) {
      element.attribute('place', staffrelToStr(place!));
    }
  }

  /// Copies the `AttPlacementRelStaff` members from [other].
  void copyAttPlacementRelStaff(covariant AttPlacementRelStaff other) {
    place = other.place;
  }
}

/// MEI attribute class for `att.Plist` (mirrors `vrv::AttPlist`).
mixin AttPlist {
  /// `plist` — xsdAnyURI_List.
  List<String>? plist;
  bool get hasPlist => plist != null;

  /// Mirrors `AttPlist::ReadPlist`.
  bool readPlist(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final plistRaw = element.get('plist');
    if (plistRaw != null) {
      plist = strToXsdAnyURIList(plistRaw);
      if (removeAttr) element.remove('plist');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPlist::WritePlist`.
  void writePlist(XmlBuilder element) {
    if (hasPlist) {
      element.attribute('plist', xsdAnyURIListToStr(plist!));
    }
  }

  /// Copies the `AttPlist` members from [other].
  void copyAttPlist(covariant AttPlist other) {
    plist = other.plist;
  }
}

/// MEI attribute class for `att.Pointing` (mirrors `vrv::AttPointing`).
mixin AttPointing {
  /// `xlink:actuate` — std::string.
  String? actuate;
  bool get hasActuate => actuate != null;

  /// `xlink:role` — std::string.
  String? role;
  bool get hasRole => role != null;

  /// `xlink:show` — std::string.
  String? show;
  bool get hasShow => show != null;

  /// `target` — std::string.
  String? target;
  bool get hasTarget => target != null;

  /// `targettype` — std::string.
  String? targettype;
  bool get hasTargettype => targettype != null;

  /// Mirrors `AttPointing::ReadPointing`.
  bool readPointing(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final actuateRaw = element.get('xlink:actuate');
    if (actuateRaw != null) {
      actuate = identityStr(actuateRaw);
      if (removeAttr) element.remove('xlink:actuate');
      hasAttribute = true;
    }
    final roleRaw = element.get('xlink:role');
    if (roleRaw != null) {
      role = identityStr(roleRaw);
      if (removeAttr) element.remove('xlink:role');
      hasAttribute = true;
    }
    final showRaw = element.get('xlink:show');
    if (showRaw != null) {
      show = identityStr(showRaw);
      if (removeAttr) element.remove('xlink:show');
      hasAttribute = true;
    }
    final targetRaw = element.get('target');
    if (targetRaw != null) {
      target = identityStr(targetRaw);
      if (removeAttr) element.remove('target');
      hasAttribute = true;
    }
    final targettypeRaw = element.get('targettype');
    if (targettypeRaw != null) {
      targettype = identityStr(targettypeRaw);
      if (removeAttr) element.remove('targettype');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPointing::WritePointing`.
  void writePointing(XmlBuilder element) {
    if (hasActuate) {
      element.attribute('xlink:actuate', identityStr(actuate!));
    }
    if (hasRole) {
      element.attribute('xlink:role', identityStr(role!));
    }
    if (hasShow) {
      element.attribute('xlink:show', identityStr(show!));
    }
    if (hasTarget) {
      element.attribute('target', identityStr(target!));
    }
    if (hasTargettype) {
      element.attribute('targettype', identityStr(targettype!));
    }
  }

  /// Copies the `AttPointing` members from [other].
  void copyAttPointing(covariant AttPointing other) {
    actuate = other.actuate;
    role = other.role;
    show = other.show;
    target = other.target;
    targettype = other.targettype;
  }
}

/// MEI attribute class for `att.Quantity` (mirrors `vrv::AttQuantity`).
mixin AttQuantity {
  /// `quantity` — double.
  double? quantity;
  bool get hasQuantity => quantity != null;

  /// Mirrors `AttQuantity::ReadQuantity`.
  bool readQuantity(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final quantityRaw = element.get('quantity');
    if (quantityRaw != null) {
      quantity = strToDbl(quantityRaw);
      if (removeAttr) element.remove('quantity');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttQuantity::WriteQuantity`.
  void writeQuantity(XmlBuilder element) {
    if (hasQuantity) {
      element.attribute('quantity', dblToStr(quantity!));
    }
  }

  /// Copies the `AttQuantity` members from [other].
  void copyAttQuantity(covariant AttQuantity other) {
    quantity = other.quantity;
  }
}

/// MEI attribute class for `att.Ranging` (mirrors `vrv::AttRanging`).
mixin AttRanging {
  /// `atleast` — double.
  double? atleast;
  bool get hasAtleast => atleast != null;

  /// `atmost` — double.
  double? atmost;
  bool get hasAtmost => atmost != null;

  /// `min` — double.
  double? min;
  bool get hasMin => min != null;

  /// `max` — double.
  double? max;
  bool get hasMax => max != null;

  /// `confidence` — double.
  double? confidence;
  bool get hasConfidence => confidence != null;

  /// Mirrors `AttRanging::ReadRanging`.
  bool readRanging(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final atleastRaw = element.get('atleast');
    if (atleastRaw != null) {
      atleast = strToDbl(atleastRaw);
      if (removeAttr) element.remove('atleast');
      hasAttribute = true;
    }
    final atmostRaw = element.get('atmost');
    if (atmostRaw != null) {
      atmost = strToDbl(atmostRaw);
      if (removeAttr) element.remove('atmost');
      hasAttribute = true;
    }
    final minRaw = element.get('min');
    if (minRaw != null) {
      min = strToDbl(minRaw);
      if (removeAttr) element.remove('min');
      hasAttribute = true;
    }
    final maxRaw = element.get('max');
    if (maxRaw != null) {
      max = strToDbl(maxRaw);
      if (removeAttr) element.remove('max');
      hasAttribute = true;
    }
    final confidenceRaw = element.get('confidence');
    if (confidenceRaw != null) {
      confidence = strToDbl(confidenceRaw);
      if (removeAttr) element.remove('confidence');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttRanging::WriteRanging`.
  void writeRanging(XmlBuilder element) {
    if (hasAtleast) {
      element.attribute('atleast', dblToStr(atleast!));
    }
    if (hasAtmost) {
      element.attribute('atmost', dblToStr(atmost!));
    }
    if (hasMin) {
      element.attribute('min', dblToStr(min!));
    }
    if (hasMax) {
      element.attribute('max', dblToStr(max!));
    }
    if (hasConfidence) {
      element.attribute('confidence', dblToStr(confidence!));
    }
  }

  /// Copies the `AttRanging` members from [other].
  void copyAttRanging(covariant AttRanging other) {
    atleast = other.atleast;
    atmost = other.atmost;
    min = other.min;
    max = other.max;
    confidence = other.confidence;
  }
}

/// MEI attribute class for `att.RepeatMarkLog` (mirrors `vrv::AttRepeatMarkLog`).
mixin AttRepeatMarkLog {
  /// `func` — repeatMarkLog_FUNC.
  RepeatmarklogFunc? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttRepeatMarkLog::ReadRepeatMarkLog`.
  bool readRepeatMarkLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = strToRepeatmarklogFunc(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttRepeatMarkLog::WriteRepeatMarkLog`.
  void writeRepeatMarkLog(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', repeatmarklogFuncToStr(func!));
    }
  }

  /// Copies the `AttRepeatMarkLog` members from [other].
  void copyAttRepeatMarkLog(covariant AttRepeatMarkLog other) {
    func = other.func;
  }
}

/// MEI attribute class for `att.Responsibility` (mirrors `vrv::AttResponsibility`).
mixin AttResponsibility {
  /// `resp` — std::string.
  String? resp;
  bool get hasResp => resp != null;

  /// Mirrors `AttResponsibility::ReadResponsibility`.
  bool readResponsibility(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final respRaw = element.get('resp');
    if (respRaw != null) {
      resp = identityStr(respRaw);
      if (removeAttr) element.remove('resp');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttResponsibility::WriteResponsibility`.
  void writeResponsibility(XmlBuilder element) {
    if (hasResp) {
      element.attribute('resp', identityStr(resp!));
    }
  }

  /// Copies the `AttResponsibility` members from [other].
  void copyAttResponsibility(covariant AttResponsibility other) {
    resp = other.resp;
  }
}

/// MEI attribute class for `att.RestdurationLog` (mirrors `vrv::AttRestdurationLog`).
mixin AttRestdurationLog {
  /// `dur` — data_DURATION.
  MeiDuration? dur;
  bool get hasDur => dur != null;

  /// Mirrors `AttRestdurationLog::ReadRestdurationLog`.
  bool readRestdurationLog(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final durRaw = element.get('dur');
    if (durRaw != null) {
      dur = strToDuration(durRaw);
      if (removeAttr) element.remove('dur');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttRestdurationLog::WriteRestdurationLog`.
  void writeRestdurationLog(XmlBuilder element) {
    if (hasDur) {
      element.attribute('dur', durationToStr(dur!));
    }
  }

  /// Copies the `AttRestdurationLog` members from [other].
  void copyAttRestdurationLog(covariant AttRestdurationLog other) {
    dur = other.dur;
  }
}

/// MEI attribute class for `att.Scalable` (mirrors `vrv::AttScalable`).
mixin AttScalable {
  /// `scale` — data_PERCENT.
  double? scale;
  bool get hasScale => scale != null;

  /// Mirrors `AttScalable::ReadScalable`.
  bool readScalable(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final scaleRaw = element.get('scale');
    if (scaleRaw != null) {
      scale = strToDbl(scaleRaw);
      if (removeAttr) element.remove('scale');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttScalable::WriteScalable`.
  void writeScalable(XmlBuilder element) {
    if (hasScale) {
      element.attribute('scale', percentToStr(scale!));
    }
  }

  /// Copies the `AttScalable` members from [other].
  void copyAttScalable(covariant AttScalable other) {
    scale = other.scale;
  }
}

/// MEI attribute class for `att.Sequence` (mirrors `vrv::AttSequence`).
mixin AttSequence {
  /// `seq` — int.
  int? seq;
  bool get hasSeq => seq != null;

  /// Mirrors `AttSequence::ReadSequence`.
  bool readSequence(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final seqRaw = element.get('seq');
    if (seqRaw != null) {
      seq = strToInt(seqRaw);
      if (removeAttr) element.remove('seq');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSequence::WriteSequence`.
  void writeSequence(XmlBuilder element) {
    if (hasSeq) {
      element.attribute('seq', intToStr(seq!));
    }
  }

  /// Copies the `AttSequence` members from [other].
  void copyAttSequence(covariant AttSequence other) {
    seq = other.seq;
  }
}

/// MEI attribute class for `att.SlashCount` (mirrors `vrv::AttSlashCount`).
mixin AttSlashCount {
  /// `slash` — char.
  int? slash;
  bool get hasSlash => slash != null;

  /// Mirrors `AttSlashCount::ReadSlashCount`.
  bool readSlashCount(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final slashRaw = element.get('slash');
    if (slashRaw != null) {
      slash = strToInt(slashRaw);
      if (removeAttr) element.remove('slash');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSlashCount::WriteSlashCount`.
  void writeSlashCount(XmlBuilder element) {
    if (hasSlash) {
      element.attribute('slash', intToStr(slash!));
    }
  }

  /// Copies the `AttSlashCount` members from [other].
  void copyAttSlashCount(covariant AttSlashCount other) {
    slash = other.slash;
  }
}

/// MEI attribute class for `att.SlurPresent` (mirrors `vrv::AttSlurPresent`).
mixin AttSlurPresent {
  /// `slur` — std::string.
  String? slur;
  bool get hasSlur => slur != null;

  /// Mirrors `AttSlurPresent::ReadSlurPresent`.
  bool readSlurPresent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final slurRaw = element.get('slur');
    if (slurRaw != null) {
      slur = identityStr(slurRaw);
      if (removeAttr) element.remove('slur');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSlurPresent::WriteSlurPresent`.
  void writeSlurPresent(XmlBuilder element) {
    if (hasSlur) {
      element.attribute('slur', identityStr(slur!));
    }
  }

  /// Copies the `AttSlurPresent` members from [other].
  void copyAttSlurPresent(covariant AttSlurPresent other) {
    slur = other.slur;
  }
}

/// MEI attribute class for `att.Source` (mirrors `vrv::AttSource`).
mixin AttSource {
  /// `source` — std::string.
  String? source;
  bool get hasSource => source != null;

  /// Mirrors `AttSource::ReadSource`.
  bool readSource(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final sourceRaw = element.get('source');
    if (sourceRaw != null) {
      source = identityStr(sourceRaw);
      if (removeAttr) element.remove('source');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSource::WriteSource`.
  void writeSource(XmlBuilder element) {
    if (hasSource) {
      element.attribute('source', identityStr(source!));
    }
  }

  /// Copies the `AttSource` members from [other].
  void copyAttSource(covariant AttSource other) {
    source = other.source;
  }
}

/// MEI attribute class for `att.Spacing` (mirrors `vrv::AttSpacing`).
mixin AttSpacing {
  /// `spacing.packexp` — double.
  double? spacingPackexp;
  bool get hasSpacingPackexp => spacingPackexp != null;

  /// `spacing.packfact` — double.
  double? spacingPackfact;
  bool get hasSpacingPackfact => spacingPackfact != null;

  /// `spacing.staff` — data_MEASUREMENTSIGNED.
  MeasurementSigned? spacingStaff;
  bool get hasSpacingStaff => spacingStaff != null;

  /// `spacing.system` — data_MEASUREMENTSIGNED.
  MeasurementSigned? spacingSystem;
  bool get hasSpacingSystem => spacingSystem != null;

  /// Mirrors `AttSpacing::ReadSpacing`.
  bool readSpacing(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final spacingPackexpRaw = element.get('spacing.packexp');
    if (spacingPackexpRaw != null) {
      spacingPackexp = strToDbl(spacingPackexpRaw);
      if (removeAttr) element.remove('spacing.packexp');
      hasAttribute = true;
    }
    final spacingPackfactRaw = element.get('spacing.packfact');
    if (spacingPackfactRaw != null) {
      spacingPackfact = strToDbl(spacingPackfactRaw);
      if (removeAttr) element.remove('spacing.packfact');
      hasAttribute = true;
    }
    final spacingStaffRaw = element.get('spacing.staff');
    if (spacingStaffRaw != null) {
      spacingStaff = strToMeasurementsigned(spacingStaffRaw);
      if (removeAttr) element.remove('spacing.staff');
      hasAttribute = true;
    }
    final spacingSystemRaw = element.get('spacing.system');
    if (spacingSystemRaw != null) {
      spacingSystem = strToMeasurementsigned(spacingSystemRaw);
      if (removeAttr) element.remove('spacing.system');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSpacing::WriteSpacing`.
  void writeSpacing(XmlBuilder element) {
    if (hasSpacingPackexp) {
      element.attribute('spacing.packexp', dblToStr(spacingPackexp!));
    }
    if (hasSpacingPackfact) {
      element.attribute('spacing.packfact', dblToStr(spacingPackfact!));
    }
    if (hasSpacingStaff) {
      element.attribute('spacing.staff', measurementsignedToStr(spacingStaff!));
    }
    if (hasSpacingSystem) {
      element.attribute(
          'spacing.system', measurementsignedToStr(spacingSystem!));
    }
  }

  /// Copies the `AttSpacing` members from [other].
  void copyAttSpacing(covariant AttSpacing other) {
    spacingPackexp = other.spacingPackexp;
    spacingPackfact = other.spacingPackfact;
    spacingStaff = other.spacingStaff;
    spacingSystem = other.spacingSystem;
  }
}

/// MEI attribute class for `att.StaffLog` (mirrors `vrv::AttStaffLog`).
mixin AttStaffLog {
  /// `def` — std::string.
  String? def;
  bool get hasDef => def != null;

  /// Mirrors `AttStaffLog::ReadStaffLog`.
  bool readStaffLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final defRaw = element.get('def');
    if (defRaw != null) {
      def = identityStr(defRaw);
      if (removeAttr) element.remove('def');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffLog::WriteStaffLog`.
  void writeStaffLog(XmlBuilder element) {
    if (hasDef) {
      element.attribute('def', identityStr(def!));
    }
  }

  /// Copies the `AttStaffLog` members from [other].
  void copyAttStaffLog(covariant AttStaffLog other) {
    def = other.def;
  }
}

/// MEI attribute class for `att.StaffDefLog` (mirrors `vrv::AttStaffDefLog`).
mixin AttStaffDefLog {
  /// `lines` — int.
  int? lines;
  bool get hasLines => lines != null;

  /// Mirrors `AttStaffDefLog::ReadStaffDefLog`.
  bool readStaffDefLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final linesRaw = element.get('lines');
    if (linesRaw != null) {
      lines = strToInt(linesRaw);
      if (removeAttr) element.remove('lines');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffDefLog::WriteStaffDefLog`.
  void writeStaffDefLog(XmlBuilder element) {
    if (hasLines) {
      element.attribute('lines', intToStr(lines!));
    }
  }

  /// Copies the `AttStaffDefLog` members from [other].
  void copyAttStaffDefLog(covariant AttStaffDefLog other) {
    lines = other.lines;
  }
}

/// MEI attribute class for `att.StaffGroupingSym` (mirrors `vrv::AttStaffGroupingSym`).
mixin AttStaffGroupingSym {
  /// `symbol` — staffGroupingSym_SYMBOL.
  StaffgroupingsymSymbol? symbol;
  bool get hasSymbol => symbol != null;

  /// Mirrors `AttStaffGroupingSym::ReadStaffGroupingSym`.
  bool readStaffGroupingSym(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final symbolRaw = element.get('symbol');
    if (symbolRaw != null) {
      symbol = strToStaffgroupingsymSymbol(symbolRaw);
      if (removeAttr) element.remove('symbol');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffGroupingSym::WriteStaffGroupingSym`.
  void writeStaffGroupingSym(XmlBuilder element) {
    if (hasSymbol) {
      element.attribute('symbol', staffgroupingsymSymbolToStr(symbol!));
    }
  }

  /// Copies the `AttStaffGroupingSym` members from [other].
  void copyAttStaffGroupingSym(covariant AttStaffGroupingSym other) {
    symbol = other.symbol;
  }
}

/// MEI attribute class for `att.StaffIdent` (mirrors `vrv::AttStaffIdent`).
mixin AttStaffIdent {
  /// `staff` — xsdPositiveInteger_List.
  List<int>? staff;
  bool get hasStaff => staff != null;

  /// Mirrors `AttStaffIdent::ReadStaffIdent`.
  bool readStaffIdent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final staffRaw = element.get('staff');
    if (staffRaw != null) {
      staff = strToXsdPositiveIntegerList(staffRaw);
      if (removeAttr) element.remove('staff');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffIdent::WriteStaffIdent`.
  void writeStaffIdent(XmlBuilder element) {
    if (hasStaff) {
      element.attribute('staff', xsdPositiveIntegerListToStr(staff!));
    }
  }

  /// Copies the `AttStaffIdent` members from [other].
  void copyAttStaffIdent(covariant AttStaffIdent other) {
    staff = other.staff;
  }
}

/// MEI attribute class for `att.StaffItems` (mirrors `vrv::AttStaffItems`).
mixin AttStaffItems {
  /// `aboveorder` — data_STAFFITEM.
  Staffitem? aboveorder;
  bool get hasAboveorder => aboveorder != null;

  /// `beloworder` — data_STAFFITEM.
  Staffitem? beloworder;
  bool get hasBeloworder => beloworder != null;

  /// `betweenorder` — data_STAFFITEM.
  Staffitem? betweenorder;
  bool get hasBetweenorder => betweenorder != null;

  /// Mirrors `AttStaffItems::ReadStaffItems`.
  bool readStaffItems(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final aboveorderRaw = element.get('aboveorder');
    if (aboveorderRaw != null) {
      aboveorder = strToStaffitem(aboveorderRaw);
      if (removeAttr) element.remove('aboveorder');
      hasAttribute = true;
    }
    final beloworderRaw = element.get('beloworder');
    if (beloworderRaw != null) {
      beloworder = strToStaffitem(beloworderRaw);
      if (removeAttr) element.remove('beloworder');
      hasAttribute = true;
    }
    final betweenorderRaw = element.get('betweenorder');
    if (betweenorderRaw != null) {
      betweenorder = strToStaffitem(betweenorderRaw);
      if (removeAttr) element.remove('betweenorder');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffItems::WriteStaffItems`.
  void writeStaffItems(XmlBuilder element) {
    if (hasAboveorder) {
      element.attribute('aboveorder', staffitemToStr(aboveorder!));
    }
    if (hasBeloworder) {
      element.attribute('beloworder', staffitemToStr(beloworder!));
    }
    if (hasBetweenorder) {
      element.attribute('betweenorder', staffitemToStr(betweenorder!));
    }
  }

  /// Copies the `AttStaffItems` members from [other].
  void copyAttStaffItems(covariant AttStaffItems other) {
    aboveorder = other.aboveorder;
    beloworder = other.beloworder;
    betweenorder = other.betweenorder;
  }
}

/// MEI attribute class for `att.StaffLoc` (mirrors `vrv::AttStaffLoc`).
mixin AttStaffLoc {
  /// `loc` — int.
  int? loc;
  bool get hasLoc => loc != null;

  /// Mirrors `AttStaffLoc::ReadStaffLoc`.
  bool readStaffLoc(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final locRaw = element.get('loc');
    if (locRaw != null) {
      loc = strToInt(locRaw);
      if (removeAttr) element.remove('loc');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffLoc::WriteStaffLoc`.
  void writeStaffLoc(XmlBuilder element) {
    if (hasLoc) {
      element.attribute('loc', intToStr(loc!));
    }
  }

  /// Copies the `AttStaffLoc` members from [other].
  void copyAttStaffLoc(covariant AttStaffLoc other) {
    loc = other.loc;
  }
}

/// MEI attribute class for `att.StaffLocPitched` (mirrors `vrv::AttStaffLocPitched`).
mixin AttStaffLocPitched {
  /// `ploc` — data_PITCHNAME.
  Pitchname? ploc;
  bool get hasPloc => ploc != null;

  /// `oloc` — data_OCTAVE.
  int? oloc;
  bool get hasOloc => oloc != null;

  /// Mirrors `AttStaffLocPitched::ReadStaffLocPitched`.
  bool readStaffLocPitched(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final plocRaw = element.get('ploc');
    if (plocRaw != null) {
      ploc = strToPitchname(plocRaw);
      if (removeAttr) element.remove('ploc');
      hasAttribute = true;
    }
    final olocRaw = element.get('oloc');
    if (olocRaw != null) {
      oloc = strToInt(olocRaw);
      if (removeAttr) element.remove('oloc');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffLocPitched::WriteStaffLocPitched`.
  void writeStaffLocPitched(XmlBuilder element) {
    if (hasPloc) {
      element.attribute('ploc', pitchnameToStr(ploc!));
    }
    if (hasOloc) {
      element.attribute('oloc', octaveToStr(oloc!));
    }
  }

  /// Copies the `AttStaffLocPitched` members from [other].
  void copyAttStaffLocPitched(covariant AttStaffLocPitched other) {
    ploc = other.ploc;
    oloc = other.oloc;
  }
}

/// MEI attribute class for `att.StartEndId` (mirrors `vrv::AttStartEndId`).
mixin AttStartEndId {
  /// `endid` — std::string.
  String? endid;
  bool get hasEndid => endid != null;

  /// Mirrors `AttStartEndId::ReadStartEndId`.
  bool readStartEndId(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final endidRaw = element.get('endid');
    if (endidRaw != null) {
      endid = identityStr(endidRaw);
      if (removeAttr) element.remove('endid');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStartEndId::WriteStartEndId`.
  void writeStartEndId(XmlBuilder element) {
    if (hasEndid) {
      element.attribute('endid', identityStr(endid!));
    }
  }

  /// Copies the `AttStartEndId` members from [other].
  void copyAttStartEndId(covariant AttStartEndId other) {
    endid = other.endid;
  }
}

/// MEI attribute class for `att.StartId` (mirrors `vrv::AttStartId`).
mixin AttStartId {
  /// `startid` — std::string.
  String? startid;
  bool get hasStartid => startid != null;

  /// Mirrors `AttStartId::ReadStartId`.
  bool readStartId(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final startidRaw = element.get('startid');
    if (startidRaw != null) {
      startid = identityStr(startidRaw);
      if (removeAttr) element.remove('startid');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStartId::WriteStartId`.
  void writeStartId(XmlBuilder element) {
    if (hasStartid) {
      element.attribute('startid', identityStr(startid!));
    }
  }

  /// Copies the `AttStartId` members from [other].
  void copyAttStartId(covariant AttStartId other) {
    startid = other.startid;
  }
}

/// MEI attribute class for `att.Stems` (mirrors `vrv::AttStems`).
mixin AttStems {
  /// `stem.dir` — data_STEMDIRECTION.
  Stemdirection? stemDir;
  bool get hasStemDir => stemDir != null;

  /// `stem.len` — double.
  double? stemLen;
  bool get hasStemLen => stemLen != null;

  /// `stem.mod` — data_STEMMODIFIER.
  Stemmodifier? stemMod;
  bool get hasStemMod => stemMod != null;

  /// `stem.pos` — data_STEMPOSITION.
  Stemposition? stemPos;
  bool get hasStemPos => stemPos != null;

  /// `stem.sameas` — std::string.
  String? stemSameas;
  bool get hasStemSameas => stemSameas != null;

  /// `stem.visible` — data_BOOLEAN.
  bool? stemVisible;
  bool get hasStemVisible => stemVisible != null;

  /// `stem.x` — double.
  double? stemX;
  bool get hasStemX => stemX != null;

  /// `stem.y` — double.
  double? stemY;
  bool get hasStemY => stemY != null;

  /// Mirrors `AttStems::ReadStems`.
  bool readStems(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final stemDirRaw = element.get('stem.dir');
    if (stemDirRaw != null) {
      stemDir = strToStemdirection(stemDirRaw);
      if (removeAttr) element.remove('stem.dir');
      hasAttribute = true;
    }
    final stemLenRaw = element.get('stem.len');
    if (stemLenRaw != null) {
      stemLen = strToDbl(stemLenRaw);
      if (removeAttr) element.remove('stem.len');
      hasAttribute = true;
    }
    final stemModRaw = element.get('stem.mod');
    if (stemModRaw != null) {
      stemMod = strToStemmodifier(stemModRaw);
      if (removeAttr) element.remove('stem.mod');
      hasAttribute = true;
    }
    final stemPosRaw = element.get('stem.pos');
    if (stemPosRaw != null) {
      stemPos = strToStemposition(stemPosRaw);
      if (removeAttr) element.remove('stem.pos');
      hasAttribute = true;
    }
    final stemSameasRaw = element.get('stem.sameas');
    if (stemSameasRaw != null) {
      stemSameas = identityStr(stemSameasRaw);
      if (removeAttr) element.remove('stem.sameas');
      hasAttribute = true;
    }
    final stemVisibleRaw = element.get('stem.visible');
    if (stemVisibleRaw != null) {
      stemVisible = strToBoolean(stemVisibleRaw);
      if (removeAttr) element.remove('stem.visible');
      hasAttribute = true;
    }
    final stemXRaw = element.get('stem.x');
    if (stemXRaw != null) {
      stemX = strToDbl(stemXRaw);
      if (removeAttr) element.remove('stem.x');
      hasAttribute = true;
    }
    final stemYRaw = element.get('stem.y');
    if (stemYRaw != null) {
      stemY = strToDbl(stemYRaw);
      if (removeAttr) element.remove('stem.y');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStems::WriteStems`.
  void writeStems(XmlBuilder element) {
    if (hasStemDir) {
      element.attribute('stem.dir', stemdirectionToStr(stemDir!));
    }
    if (hasStemLen) {
      element.attribute('stem.len', dblToStr(stemLen!));
    }
    if (hasStemMod) {
      element.attribute('stem.mod', stemmodifierToStr(stemMod!));
    }
    if (hasStemPos) {
      element.attribute('stem.pos', stempositionToStr(stemPos!));
    }
    if (hasStemSameas) {
      element.attribute('stem.sameas', identityStr(stemSameas!));
    }
    if (hasStemVisible) {
      element.attribute('stem.visible', booleanToStr(stemVisible!));
    }
    if (hasStemX) {
      element.attribute('stem.x', dblToStr(stemX!));
    }
    if (hasStemY) {
      element.attribute('stem.y', dblToStr(stemY!));
    }
  }

  /// Copies the `AttStems` members from [other].
  void copyAttStems(covariant AttStems other) {
    stemDir = other.stemDir;
    stemLen = other.stemLen;
    stemMod = other.stemMod;
    stemPos = other.stemPos;
    stemSameas = other.stemSameas;
    stemVisible = other.stemVisible;
    stemX = other.stemX;
    stemY = other.stemY;
  }
}

/// MEI attribute class for `att.SylLog` (mirrors `vrv::AttSylLog`).
mixin AttSylLog {
  /// `con` — sylLog_CON.
  SyllogCon? con;
  bool get hasCon => con != null;

  /// `wordpos` — sylLog_WORDPOS.
  SyllogWordpos? wordpos;
  bool get hasWordpos => wordpos != null;

  /// Mirrors `AttSylLog::ReadSylLog`.
  bool readSylLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final conRaw = element.get('con');
    if (conRaw != null) {
      con = strToSyllogCon(conRaw);
      if (removeAttr) element.remove('con');
      hasAttribute = true;
    }
    final wordposRaw = element.get('wordpos');
    if (wordposRaw != null) {
      wordpos = strToSyllogWordpos(wordposRaw);
      if (removeAttr) element.remove('wordpos');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSylLog::WriteSylLog`.
  void writeSylLog(XmlBuilder element) {
    if (hasCon) {
      element.attribute('con', syllogConToStr(con!));
    }
    if (hasWordpos) {
      element.attribute('wordpos', syllogWordposToStr(wordpos!));
    }
  }

  /// Copies the `AttSylLog` members from [other].
  void copyAttSylLog(covariant AttSylLog other) {
    con = other.con;
    wordpos = other.wordpos;
  }
}

/// MEI attribute class for `att.SylText` (mirrors `vrv::AttSylText`).
mixin AttSylText {
  /// `syl` — std::string.
  String? syl;
  bool get hasSyl => syl != null;

  /// Mirrors `AttSylText::ReadSylText`.
  bool readSylText(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final sylRaw = element.get('syl');
    if (sylRaw != null) {
      syl = identityStr(sylRaw);
      if (removeAttr) element.remove('syl');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSylText::WriteSylText`.
  void writeSylText(XmlBuilder element) {
    if (hasSyl) {
      element.attribute('syl', identityStr(syl!));
    }
  }

  /// Copies the `AttSylText` members from [other].
  void copyAttSylText(covariant AttSylText other) {
    syl = other.syl;
  }
}

/// MEI attribute class for `att.Systems` (mirrors `vrv::AttSystems`).
mixin AttSystems {
  /// `system.leftline` — data_BOOLEAN.
  bool? systemLeftline;
  bool get hasSystemLeftline => systemLeftline != null;

  /// `system.leftmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? systemLeftmar;
  bool get hasSystemLeftmar => systemLeftmar != null;

  /// `system.rightmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? systemRightmar;
  bool get hasSystemRightmar => systemRightmar != null;

  /// `system.topmar` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? systemTopmar;
  bool get hasSystemTopmar => systemTopmar != null;

  /// Mirrors `AttSystems::ReadSystems`.
  bool readSystems(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final systemLeftlineRaw = element.get('system.leftline');
    if (systemLeftlineRaw != null) {
      systemLeftline = strToBoolean(systemLeftlineRaw);
      if (removeAttr) element.remove('system.leftline');
      hasAttribute = true;
    }
    final systemLeftmarRaw = element.get('system.leftmar');
    if (systemLeftmarRaw != null) {
      systemLeftmar = strToMeasurementunsigned(systemLeftmarRaw);
      if (removeAttr) element.remove('system.leftmar');
      hasAttribute = true;
    }
    final systemRightmarRaw = element.get('system.rightmar');
    if (systemRightmarRaw != null) {
      systemRightmar = strToMeasurementunsigned(systemRightmarRaw);
      if (removeAttr) element.remove('system.rightmar');
      hasAttribute = true;
    }
    final systemTopmarRaw = element.get('system.topmar');
    if (systemTopmarRaw != null) {
      systemTopmar = strToMeasurementunsigned(systemTopmarRaw);
      if (removeAttr) element.remove('system.topmar');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSystems::WriteSystems`.
  void writeSystems(XmlBuilder element) {
    if (hasSystemLeftline) {
      element.attribute('system.leftline', booleanToStr(systemLeftline!));
    }
    if (hasSystemLeftmar) {
      element.attribute(
          'system.leftmar', measurementunsignedToStr(systemLeftmar!));
    }
    if (hasSystemRightmar) {
      element.attribute(
          'system.rightmar', measurementunsignedToStr(systemRightmar!));
    }
    if (hasSystemTopmar) {
      element.attribute(
          'system.topmar', measurementunsignedToStr(systemTopmar!));
    }
  }

  /// Copies the `AttSystems` members from [other].
  void copyAttSystems(covariant AttSystems other) {
    systemLeftline = other.systemLeftline;
    systemLeftmar = other.systemLeftmar;
    systemRightmar = other.systemRightmar;
    systemTopmar = other.systemTopmar;
  }
}

/// MEI attribute class for `att.TargetEval` (mirrors `vrv::AttTargetEval`).
mixin AttTargetEval {
  /// `evaluate` — targetEval_EVALUATE.
  TargetevalEvaluate? evaluate;
  bool get hasEvaluate => evaluate != null;

  /// Mirrors `AttTargetEval::ReadTargetEval`.
  bool readTargetEval(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final evaluateRaw = element.get('evaluate');
    if (evaluateRaw != null) {
      evaluate = strToTargetevalEvaluate(evaluateRaw);
      if (removeAttr) element.remove('evaluate');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTargetEval::WriteTargetEval`.
  void writeTargetEval(XmlBuilder element) {
    if (hasEvaluate) {
      element.attribute('evaluate', targetevalEvaluateToStr(evaluate!));
    }
  }

  /// Copies the `AttTargetEval` members from [other].
  void copyAttTargetEval(covariant AttTargetEval other) {
    evaluate = other.evaluate;
  }
}

/// MEI attribute class for `att.TempoLog` (mirrors `vrv::AttTempoLog`).
mixin AttTempoLog {
  /// `func` — tempoLog_FUNC.
  TempologFunc? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttTempoLog::ReadTempoLog`.
  bool readTempoLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = strToTempologFunc(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTempoLog::WriteTempoLog`.
  void writeTempoLog(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', tempologFuncToStr(func!));
    }
  }

  /// Copies the `AttTempoLog` members from [other].
  void copyAttTempoLog(covariant AttTempoLog other) {
    func = other.func;
  }
}

/// MEI attribute class for `att.TextRendition` (mirrors `vrv::AttTextRendition`).
mixin AttTextRendition {
  /// `altrend` — std::string.
  String? altrend;
  bool get hasAltrend => altrend != null;

  /// `rend` — data_TEXTRENDITION.
  Textrendition? rend;
  bool get hasRend => rend != null;

  /// Mirrors `AttTextRendition::ReadTextRendition`.
  bool readTextRendition(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final altrendRaw = element.get('altrend');
    if (altrendRaw != null) {
      altrend = identityStr(altrendRaw);
      if (removeAttr) element.remove('altrend');
      hasAttribute = true;
    }
    final rendRaw = element.get('rend');
    if (rendRaw != null) {
      rend = strToTextrendition(rendRaw);
      if (removeAttr) element.remove('rend');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTextRendition::WriteTextRendition`.
  void writeTextRendition(XmlBuilder element) {
    if (hasAltrend) {
      element.attribute('altrend', identityStr(altrend!));
    }
    if (hasRend) {
      element.attribute('rend', textrenditionToStr(rend!));
    }
  }

  /// Copies the `AttTextRendition` members from [other].
  void copyAttTextRendition(covariant AttTextRendition other) {
    altrend = other.altrend;
    rend = other.rend;
  }
}

/// MEI attribute class for `att.TextStyle` (mirrors `vrv::AttTextStyle`).
mixin AttTextStyle {
  /// `text.fam` — std::string.
  String? textFam;
  bool get hasTextFam => textFam != null;

  /// `text.name` — std::string.
  String? textName;
  bool get hasTextName => textName != null;

  /// `text.size` — data_FONTSIZE.
  FontSize? textSize;
  bool get hasTextSize => textSize != null;

  /// `text.style` — data_FONTSTYLE.
  Fontstyle? textStyle;
  bool get hasTextStyle => textStyle != null;

  /// `text.weight` — data_FONTWEIGHT.
  Fontweight? textWeight;
  bool get hasTextWeight => textWeight != null;

  /// Mirrors `AttTextStyle::ReadTextStyle`.
  bool readTextStyle(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final textFamRaw = element.get('text.fam');
    if (textFamRaw != null) {
      textFam = identityStr(textFamRaw);
      if (removeAttr) element.remove('text.fam');
      hasAttribute = true;
    }
    final textNameRaw = element.get('text.name');
    if (textNameRaw != null) {
      textName = identityStr(textNameRaw);
      if (removeAttr) element.remove('text.name');
      hasAttribute = true;
    }
    final textSizeRaw = element.get('text.size');
    if (textSizeRaw != null) {
      textSize = strToFontsize(textSizeRaw);
      if (removeAttr) element.remove('text.size');
      hasAttribute = true;
    }
    final textStyleRaw = element.get('text.style');
    if (textStyleRaw != null) {
      textStyle = strToFontstyle(textStyleRaw);
      if (removeAttr) element.remove('text.style');
      hasAttribute = true;
    }
    final textWeightRaw = element.get('text.weight');
    if (textWeightRaw != null) {
      textWeight = strToFontweight(textWeightRaw);
      if (removeAttr) element.remove('text.weight');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTextStyle::WriteTextStyle`.
  void writeTextStyle(XmlBuilder element) {
    if (hasTextFam) {
      element.attribute('text.fam', identityStr(textFam!));
    }
    if (hasTextName) {
      element.attribute('text.name', identityStr(textName!));
    }
    if (hasTextSize) {
      element.attribute('text.size', fontsizeToStr(textSize!));
    }
    if (hasTextStyle) {
      element.attribute('text.style', fontstyleToStr(textStyle!));
    }
    if (hasTextWeight) {
      element.attribute('text.weight', fontweightToStr(textWeight!));
    }
  }

  /// Copies the `AttTextStyle` members from [other].
  void copyAttTextStyle(covariant AttTextStyle other) {
    textFam = other.textFam;
    textName = other.textName;
    textSize = other.textSize;
    textStyle = other.textStyle;
    textWeight = other.textWeight;
  }
}

/// MEI attribute class for `att.TiePresent` (mirrors `vrv::AttTiePresent`).
mixin AttTiePresent {
  /// `tie` — data_TIE.
  Tie? tie;
  bool get hasTie => tie != null;

  /// Mirrors `AttTiePresent::ReadTiePresent`.
  bool readTiePresent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tieRaw = element.get('tie');
    if (tieRaw != null) {
      tie = strToTie(tieRaw);
      if (removeAttr) element.remove('tie');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTiePresent::WriteTiePresent`.
  void writeTiePresent(XmlBuilder element) {
    if (hasTie) {
      element.attribute('tie', tieToStr(tie!));
    }
  }

  /// Copies the `AttTiePresent` members from [other].
  void copyAttTiePresent(covariant AttTiePresent other) {
    tie = other.tie;
  }
}

/// MEI attribute class for `att.TimestampLog` (mirrors `vrv::AttTimestampLog`).
mixin AttTimestampLog {
  /// `tstamp` — double.
  double? tstamp;
  bool get hasTstamp => tstamp != null;

  /// Mirrors `AttTimestampLog::ReadTimestampLog`.
  bool readTimestampLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tstampRaw = element.get('tstamp');
    if (tstampRaw != null) {
      tstamp = strToDbl(tstampRaw);
      if (removeAttr) element.remove('tstamp');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTimestampLog::WriteTimestampLog`.
  void writeTimestampLog(XmlBuilder element) {
    if (hasTstamp) {
      element.attribute('tstamp', dblToStr(tstamp!));
    }
  }

  /// Copies the `AttTimestampLog` members from [other].
  void copyAttTimestampLog(covariant AttTimestampLog other) {
    tstamp = other.tstamp;
  }
}

/// MEI attribute class for `att.Timestamp2Log` (mirrors `vrv::AttTimestamp2Log`).
mixin AttTimestamp2Log {
  /// `tstamp2` — data_MEASUREBEAT.
  MeasureBeat? tstamp2;
  bool get hasTstamp2 => tstamp2 != null;

  /// Mirrors `AttTimestamp2Log::ReadTimestamp2Log`.
  bool readTimestamp2Log(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tstamp2Raw = element.get('tstamp2');
    if (tstamp2Raw != null) {
      tstamp2 = strToMeasurebeat(tstamp2Raw);
      if (removeAttr) element.remove('tstamp2');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTimestamp2Log::WriteTimestamp2Log`.
  void writeTimestamp2Log(XmlBuilder element) {
    if (hasTstamp2) {
      element.attribute('tstamp2', measurebeatToStr(tstamp2!));
    }
  }

  /// Copies the `AttTimestamp2Log` members from [other].
  void copyAttTimestamp2Log(covariant AttTimestamp2Log other) {
    tstamp2 = other.tstamp2;
  }
}

/// MEI attribute class for `att.Transposition` (mirrors `vrv::AttTransposition`).
mixin AttTransposition {
  /// `trans.diat` — int.
  int? transDiat;
  bool get hasTransDiat => transDiat != null;

  /// `trans.semi` — int.
  int? transSemi;
  bool get hasTransSemi => transSemi != null;

  /// Mirrors `AttTransposition::ReadTransposition`.
  bool readTransposition(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final transDiatRaw = element.get('trans.diat');
    if (transDiatRaw != null) {
      transDiat = strToInt(transDiatRaw);
      if (removeAttr) element.remove('trans.diat');
      hasAttribute = true;
    }
    final transSemiRaw = element.get('trans.semi');
    if (transSemiRaw != null) {
      transSemi = strToInt(transSemiRaw);
      if (removeAttr) element.remove('trans.semi');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTransposition::WriteTransposition`.
  void writeTransposition(XmlBuilder element) {
    if (hasTransDiat) {
      element.attribute('trans.diat', intToStr(transDiat!));
    }
    if (hasTransSemi) {
      element.attribute('trans.semi', intToStr(transSemi!));
    }
  }

  /// Copies the `AttTransposition` members from [other].
  void copyAttTransposition(covariant AttTransposition other) {
    transDiat = other.transDiat;
    transSemi = other.transSemi;
  }
}

/// MEI attribute class for `att.Tuning` (mirrors `vrv::AttTuning`).
mixin AttTuning {
  /// `tune.Hz` — double.
  double? tuneHz;
  bool get hasTuneHz => tuneHz != null;

  /// `tune.pname` — data_PITCHNAME.
  Pitchname? tunePname;
  bool get hasTunePname => tunePname != null;

  /// `tune.temper` — data_TEMPERAMENT.
  Temperament? tuneTemper;
  bool get hasTuneTemper => tuneTemper != null;

  /// Mirrors `AttTuning::ReadTuning`.
  bool readTuning(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tuneHzRaw = element.get('tune.Hz');
    if (tuneHzRaw != null) {
      tuneHz = strToDbl(tuneHzRaw);
      if (removeAttr) element.remove('tune.Hz');
      hasAttribute = true;
    }
    final tunePnameRaw = element.get('tune.pname');
    if (tunePnameRaw != null) {
      tunePname = strToPitchname(tunePnameRaw);
      if (removeAttr) element.remove('tune.pname');
      hasAttribute = true;
    }
    final tuneTemperRaw = element.get('tune.temper');
    if (tuneTemperRaw != null) {
      tuneTemper = strToTemperament(tuneTemperRaw);
      if (removeAttr) element.remove('tune.temper');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTuning::WriteTuning`.
  void writeTuning(XmlBuilder element) {
    if (hasTuneHz) {
      element.attribute('tune.Hz', dblToStr(tuneHz!));
    }
    if (hasTunePname) {
      element.attribute('tune.pname', pitchnameToStr(tunePname!));
    }
    if (hasTuneTemper) {
      element.attribute('tune.temper', temperamentToStr(tuneTemper!));
    }
  }

  /// Copies the `AttTuning` members from [other].
  void copyAttTuning(covariant AttTuning other) {
    tuneHz = other.tuneHz;
    tunePname = other.tunePname;
    tuneTemper = other.tuneTemper;
  }
}

/// MEI attribute class for `att.TuningLog` (mirrors `vrv::AttTuningLog`).
mixin AttTuningLog {
  /// `tuning.standard` — data_COURSETUNING.
  Coursetuning? tuningStandard;
  bool get hasTuningStandard => tuningStandard != null;

  /// Mirrors `AttTuningLog::ReadTuningLog`.
  bool readTuningLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tuningStandardRaw = element.get('tuning.standard');
    if (tuningStandardRaw != null) {
      tuningStandard = strToCoursetuning(tuningStandardRaw);
      if (removeAttr) element.remove('tuning.standard');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTuningLog::WriteTuningLog`.
  void writeTuningLog(XmlBuilder element) {
    if (hasTuningStandard) {
      element.attribute('tuning.standard', coursetuningToStr(tuningStandard!));
    }
  }

  /// Copies the `AttTuningLog` members from [other].
  void copyAttTuningLog(covariant AttTuningLog other) {
    tuningStandard = other.tuningStandard;
  }
}

/// MEI attribute class for `att.TupletPresent` (mirrors `vrv::AttTupletPresent`).
mixin AttTupletPresent {
  /// `tuplet` — std::string.
  String? tuplet;
  bool get hasTuplet => tuplet != null;

  /// Mirrors `AttTupletPresent::ReadTupletPresent`.
  bool readTupletPresent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tupletRaw = element.get('tuplet');
    if (tupletRaw != null) {
      tuplet = identityStr(tupletRaw);
      if (removeAttr) element.remove('tuplet');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTupletPresent::WriteTupletPresent`.
  void writeTupletPresent(XmlBuilder element) {
    if (hasTuplet) {
      element.attribute('tuplet', identityStr(tuplet!));
    }
  }

  /// Copies the `AttTupletPresent` members from [other].
  void copyAttTupletPresent(covariant AttTupletPresent other) {
    tuplet = other.tuplet;
  }
}

/// MEI attribute class for `att.Typed` (mirrors `vrv::AttTyped`).
mixin AttTyped {
  /// `type` — std::string.
  String? type;
  bool get hasType => type != null;

  /// Mirrors `AttTyped::ReadTyped`.
  bool readTyped(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final typeRaw = element.get('type');
    if (typeRaw != null) {
      type = identityStr(typeRaw);
      if (removeAttr) element.remove('type');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTyped::WriteTyped`.
  void writeTyped(XmlBuilder element) {
    if (hasType) {
      element.attribute('type', identityStr(type!));
    }
  }

  /// Copies the `AttTyped` members from [other].
  void copyAttTyped(covariant AttTyped other) {
    type = other.type;
  }
}

/// MEI attribute class for `att.Typography` (mirrors `vrv::AttTypography`).
mixin AttTypography {
  /// `fontfam` — std::string.
  String? fontfam;
  bool get hasFontfam => fontfam != null;

  /// `fontname` — std::string.
  String? fontname;
  bool get hasFontname => fontname != null;

  /// `fontsize` — data_FONTSIZE.
  FontSize? fontsize;
  bool get hasFontsize => fontsize != null;

  /// `fontstyle` — data_FONTSTYLE.
  Fontstyle? fontstyle;
  bool get hasFontstyle => fontstyle != null;

  /// `fontweight` — data_FONTWEIGHT.
  Fontweight? fontweight;
  bool get hasFontweight => fontweight != null;

  /// `letterspacing` — double.
  double? letterspacing;
  bool get hasLetterspacing => letterspacing != null;

  /// `lineheight` — std::string.
  String? lineheight;
  bool get hasLineheight => lineheight != null;

  /// Mirrors `AttTypography::ReadTypography`.
  bool readTypography(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final fontfamRaw = element.get('fontfam');
    if (fontfamRaw != null) {
      fontfam = identityStr(fontfamRaw);
      if (removeAttr) element.remove('fontfam');
      hasAttribute = true;
    }
    final fontnameRaw = element.get('fontname');
    if (fontnameRaw != null) {
      fontname = identityStr(fontnameRaw);
      if (removeAttr) element.remove('fontname');
      hasAttribute = true;
    }
    final fontsizeRaw = element.get('fontsize');
    if (fontsizeRaw != null) {
      fontsize = strToFontsize(fontsizeRaw);
      if (removeAttr) element.remove('fontsize');
      hasAttribute = true;
    }
    final fontstyleRaw = element.get('fontstyle');
    if (fontstyleRaw != null) {
      fontstyle = strToFontstyle(fontstyleRaw);
      if (removeAttr) element.remove('fontstyle');
      hasAttribute = true;
    }
    final fontweightRaw = element.get('fontweight');
    if (fontweightRaw != null) {
      fontweight = strToFontweight(fontweightRaw);
      if (removeAttr) element.remove('fontweight');
      hasAttribute = true;
    }
    final letterspacingRaw = element.get('letterspacing');
    if (letterspacingRaw != null) {
      letterspacing = strToDbl(letterspacingRaw);
      if (removeAttr) element.remove('letterspacing');
      hasAttribute = true;
    }
    final lineheightRaw = element.get('lineheight');
    if (lineheightRaw != null) {
      lineheight = identityStr(lineheightRaw);
      if (removeAttr) element.remove('lineheight');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTypography::WriteTypography`.
  void writeTypography(XmlBuilder element) {
    if (hasFontfam) {
      element.attribute('fontfam', identityStr(fontfam!));
    }
    if (hasFontname) {
      element.attribute('fontname', identityStr(fontname!));
    }
    if (hasFontsize) {
      element.attribute('fontsize', fontsizeToStr(fontsize!));
    }
    if (hasFontstyle) {
      element.attribute('fontstyle', fontstyleToStr(fontstyle!));
    }
    if (hasFontweight) {
      element.attribute('fontweight', fontweightToStr(fontweight!));
    }
    if (hasLetterspacing) {
      element.attribute('letterspacing', dblToStr(letterspacing!));
    }
    if (hasLineheight) {
      element.attribute('lineheight', identityStr(lineheight!));
    }
  }

  /// Copies the `AttTypography` members from [other].
  void copyAttTypography(covariant AttTypography other) {
    fontfam = other.fontfam;
    fontname = other.fontname;
    fontsize = other.fontsize;
    fontstyle = other.fontstyle;
    fontweight = other.fontweight;
    letterspacing = other.letterspacing;
    lineheight = other.lineheight;
  }
}

/// MEI attribute class for `att.VerticalAlign` (mirrors `vrv::AttVerticalAlign`).
mixin AttVerticalAlign {
  /// `valign` — data_VERTICALALIGNMENT.
  Verticalalignment? valign;
  bool get hasValign => valign != null;

  /// Mirrors `AttVerticalAlign::ReadVerticalAlign`.
  bool readVerticalAlign(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final valignRaw = element.get('valign');
    if (valignRaw != null) {
      valign = strToVerticalalignment(valignRaw);
      if (removeAttr) element.remove('valign');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVerticalAlign::WriteVerticalAlign`.
  void writeVerticalAlign(XmlBuilder element) {
    if (hasValign) {
      element.attribute('valign', verticalalignmentToStr(valign!));
    }
  }

  /// Copies the `AttVerticalAlign` members from [other].
  void copyAttVerticalAlign(covariant AttVerticalAlign other) {
    valign = other.valign;
  }
}

/// MEI attribute class for `att.VerticalGroup` (mirrors `vrv::AttVerticalGroup`).
mixin AttVerticalGroup {
  /// `vgrp` — int.
  int? vgrp;
  bool get hasVgrp => vgrp != null;

  /// Mirrors `AttVerticalGroup::ReadVerticalGroup`.
  bool readVerticalGroup(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final vgrpRaw = element.get('vgrp');
    if (vgrpRaw != null) {
      vgrp = strToInt(vgrpRaw);
      if (removeAttr) element.remove('vgrp');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVerticalGroup::WriteVerticalGroup`.
  void writeVerticalGroup(XmlBuilder element) {
    if (hasVgrp) {
      element.attribute('vgrp', intToStr(vgrp!));
    }
  }

  /// Copies the `AttVerticalGroup` members from [other].
  void copyAttVerticalGroup(covariant AttVerticalGroup other) {
    vgrp = other.vgrp;
  }
}

/// MEI attribute class for `att.Visibility` (mirrors `vrv::AttVisibility`).
mixin AttVisibility {
  /// `visible` — data_BOOLEAN.
  bool? visible;
  bool get hasVisible => visible != null;

  /// Mirrors `AttVisibility::ReadVisibility`.
  bool readVisibility(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final visibleRaw = element.get('visible');
    if (visibleRaw != null) {
      visible = strToBoolean(visibleRaw);
      if (removeAttr) element.remove('visible');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVisibility::WriteVisibility`.
  void writeVisibility(XmlBuilder element) {
    if (hasVisible) {
      element.attribute('visible', booleanToStr(visible!));
    }
  }

  /// Copies the `AttVisibility` members from [other].
  void copyAttVisibility(covariant AttVisibility other) {
    visible = other.visible;
  }
}

/// MEI attribute class for `att.VisualOffsetHo` (mirrors `vrv::AttVisualOffsetHo`).
mixin AttVisualOffsetHo {
  /// `ho` — data_MEASUREMENTSIGNED.
  MeasurementSigned? ho;
  bool get hasHo => ho != null;

  /// Mirrors `AttVisualOffsetHo::ReadVisualOffsetHo`.
  bool readVisualOffsetHo(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final hoRaw = element.get('ho');
    if (hoRaw != null) {
      ho = strToMeasurementsigned(hoRaw);
      if (removeAttr) element.remove('ho');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVisualOffsetHo::WriteVisualOffsetHo`.
  void writeVisualOffsetHo(XmlBuilder element) {
    if (hasHo) {
      element.attribute('ho', measurementsignedToStr(ho!));
    }
  }

  /// Copies the `AttVisualOffsetHo` members from [other].
  void copyAttVisualOffsetHo(covariant AttVisualOffsetHo other) {
    ho = other.ho;
  }
}

/// MEI attribute class for `att.VisualOffsetTo` (mirrors `vrv::AttVisualOffsetTo`).
mixin AttVisualOffsetTo {
  /// `to` — double.
  double? to;
  bool get hasTo => to != null;

  /// Mirrors `AttVisualOffsetTo::ReadVisualOffsetTo`.
  bool readVisualOffsetTo(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final toRaw = element.get('to');
    if (toRaw != null) {
      to = strToDbl(toRaw);
      if (removeAttr) element.remove('to');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVisualOffsetTo::WriteVisualOffsetTo`.
  void writeVisualOffsetTo(XmlBuilder element) {
    if (hasTo) {
      element.attribute('to', dblToStr(to!));
    }
  }

  /// Copies the `AttVisualOffsetTo` members from [other].
  void copyAttVisualOffsetTo(covariant AttVisualOffsetTo other) {
    to = other.to;
  }
}

/// MEI attribute class for `att.VisualOffsetVo` (mirrors `vrv::AttVisualOffsetVo`).
mixin AttVisualOffsetVo {
  /// `vo` — data_MEASUREMENTSIGNED.
  MeasurementSigned? vo;
  bool get hasVo => vo != null;

  /// Mirrors `AttVisualOffsetVo::ReadVisualOffsetVo`.
  bool readVisualOffsetVo(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final voRaw = element.get('vo');
    if (voRaw != null) {
      vo = strToMeasurementsigned(voRaw);
      if (removeAttr) element.remove('vo');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVisualOffsetVo::WriteVisualOffsetVo`.
  void writeVisualOffsetVo(XmlBuilder element) {
    if (hasVo) {
      element.attribute('vo', measurementsignedToStr(vo!));
    }
  }

  /// Copies the `AttVisualOffsetVo` members from [other].
  void copyAttVisualOffsetVo(covariant AttVisualOffsetVo other) {
    vo = other.vo;
  }
}

/// MEI attribute class for `att.VisualOffset2Ho` (mirrors `vrv::AttVisualOffset2Ho`).
mixin AttVisualOffset2Ho {
  /// `startho` — data_MEASUREMENTSIGNED.
  MeasurementSigned? startho;
  bool get hasStartho => startho != null;

  /// `endho` — data_MEASUREMENTSIGNED.
  MeasurementSigned? endho;
  bool get hasEndho => endho != null;

  /// Mirrors `AttVisualOffset2Ho::ReadVisualOffset2Ho`.
  bool readVisualOffset2Ho(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final starthoRaw = element.get('startho');
    if (starthoRaw != null) {
      startho = strToMeasurementsigned(starthoRaw);
      if (removeAttr) element.remove('startho');
      hasAttribute = true;
    }
    final endhoRaw = element.get('endho');
    if (endhoRaw != null) {
      endho = strToMeasurementsigned(endhoRaw);
      if (removeAttr) element.remove('endho');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVisualOffset2Ho::WriteVisualOffset2Ho`.
  void writeVisualOffset2Ho(XmlBuilder element) {
    if (hasStartho) {
      element.attribute('startho', measurementsignedToStr(startho!));
    }
    if (hasEndho) {
      element.attribute('endho', measurementsignedToStr(endho!));
    }
  }

  /// Copies the `AttVisualOffset2Ho` members from [other].
  void copyAttVisualOffset2Ho(covariant AttVisualOffset2Ho other) {
    startho = other.startho;
    endho = other.endho;
  }
}

/// MEI attribute class for `att.VisualOffset2To` (mirrors `vrv::AttVisualOffset2To`).
mixin AttVisualOffset2To {
  /// `startto` — double.
  double? startto;
  bool get hasStartto => startto != null;

  /// `endto` — double.
  double? endto;
  bool get hasEndto => endto != null;

  /// Mirrors `AttVisualOffset2To::ReadVisualOffset2To`.
  bool readVisualOffset2To(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final starttoRaw = element.get('startto');
    if (starttoRaw != null) {
      startto = strToDbl(starttoRaw);
      if (removeAttr) element.remove('startto');
      hasAttribute = true;
    }
    final endtoRaw = element.get('endto');
    if (endtoRaw != null) {
      endto = strToDbl(endtoRaw);
      if (removeAttr) element.remove('endto');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVisualOffset2To::WriteVisualOffset2To`.
  void writeVisualOffset2To(XmlBuilder element) {
    if (hasStartto) {
      element.attribute('startto', dblToStr(startto!));
    }
    if (hasEndto) {
      element.attribute('endto', dblToStr(endto!));
    }
  }

  /// Copies the `AttVisualOffset2To` members from [other].
  void copyAttVisualOffset2To(covariant AttVisualOffset2To other) {
    startto = other.startto;
    endto = other.endto;
  }
}

/// MEI attribute class for `att.VisualOffset2Vo` (mirrors `vrv::AttVisualOffset2Vo`).
mixin AttVisualOffset2Vo {
  /// `startvo` — data_MEASUREMENTSIGNED.
  MeasurementSigned? startvo;
  bool get hasStartvo => startvo != null;

  /// `endvo` — data_MEASUREMENTSIGNED.
  MeasurementSigned? endvo;
  bool get hasEndvo => endvo != null;

  /// Mirrors `AttVisualOffset2Vo::ReadVisualOffset2Vo`.
  bool readVisualOffset2Vo(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final startvoRaw = element.get('startvo');
    if (startvoRaw != null) {
      startvo = strToMeasurementsigned(startvoRaw);
      if (removeAttr) element.remove('startvo');
      hasAttribute = true;
    }
    final endvoRaw = element.get('endvo');
    if (endvoRaw != null) {
      endvo = strToMeasurementsigned(endvoRaw);
      if (removeAttr) element.remove('endvo');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVisualOffset2Vo::WriteVisualOffset2Vo`.
  void writeVisualOffset2Vo(XmlBuilder element) {
    if (hasStartvo) {
      element.attribute('startvo', measurementsignedToStr(startvo!));
    }
    if (hasEndvo) {
      element.attribute('endvo', measurementsignedToStr(endvo!));
    }
  }

  /// Copies the `AttVisualOffset2Vo` members from [other].
  void copyAttVisualOffset2Vo(covariant AttVisualOffset2Vo other) {
    startvo = other.startvo;
    endvo = other.endvo;
  }
}

/// MEI attribute class for `att.VoltaGroupingSym` (mirrors `vrv::AttVoltaGroupingSym`).
mixin AttVoltaGroupingSym {
  /// `voltasym` — voltaGroupingSym_VOLTASYM.
  VoltagroupingsymVoltasym? voltasym;
  bool get hasVoltasym => voltasym != null;

  /// Mirrors `AttVoltaGroupingSym::ReadVoltaGroupingSym`.
  bool readVoltaGroupingSym(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final voltasymRaw = element.get('voltasym');
    if (voltasymRaw != null) {
      voltasym = strToVoltagroupingsymVoltasym(voltasymRaw);
      if (removeAttr) element.remove('voltasym');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttVoltaGroupingSym::WriteVoltaGroupingSym`.
  void writeVoltaGroupingSym(XmlBuilder element) {
    if (hasVoltasym) {
      element.attribute('voltasym', voltagroupingsymVoltasymToStr(voltasym!));
    }
  }

  /// Copies the `AttVoltaGroupingSym` members from [other].
  void copyAttVoltaGroupingSym(covariant AttVoltaGroupingSym other) {
    voltasym = other.voltasym;
  }
}

/// MEI attribute class for `att.Whitespace` (mirrors `vrv::AttWhitespace`).
mixin AttWhitespace {
  /// `xml:space` — std::string.
  String? space;
  bool get hasSpace => space != null;

  /// Mirrors `AttWhitespace::ReadWhitespace`.
  bool readWhitespace(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final spaceRaw = element.get('xml:space');
    if (spaceRaw != null) {
      space = identityStr(spaceRaw);
      if (removeAttr) element.remove('xml:space');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttWhitespace::WriteWhitespace`.
  void writeWhitespace(XmlBuilder element) {
    if (hasSpace) {
      element.attribute('xml:space', identityStr(space!));
    }
  }

  /// Copies the `AttWhitespace` members from [other].
  void copyAttWhitespace(covariant AttWhitespace other) {
    space = other.space;
  }
}

/// MEI attribute class for `att.Width` (mirrors `vrv::AttWidth`).
mixin AttWidth {
  /// `width` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? width;
  bool get hasWidth => width != null;

  /// Mirrors `AttWidth::ReadWidth`.
  bool readWidth(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final widthRaw = element.get('width');
    if (widthRaw != null) {
      width = strToMeasurementunsigned(widthRaw);
      if (removeAttr) element.remove('width');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttWidth::WriteWidth`.
  void writeWidth(XmlBuilder element) {
    if (hasWidth) {
      element.attribute('width', measurementunsignedToStr(width!));
    }
  }

  /// Copies the `AttWidth` members from [other].
  void copyAttWidth(covariant AttWidth other) {
    width = other.width;
  }
}

/// MEI attribute class for `att.Xy` (mirrors `vrv::AttXy`).
mixin AttXy {
  /// `x` — double.
  double? x;
  bool get hasX => x != null;

  /// `y` — double.
  double? y;
  bool get hasY => y != null;

  /// Mirrors `AttXy::ReadXy`.
  bool readXy(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final xRaw = element.get('x');
    if (xRaw != null) {
      x = strToDbl(xRaw);
      if (removeAttr) element.remove('x');
      hasAttribute = true;
    }
    final yRaw = element.get('y');
    if (yRaw != null) {
      y = strToDbl(yRaw);
      if (removeAttr) element.remove('y');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttXy::WriteXy`.
  void writeXy(XmlBuilder element) {
    if (hasX) {
      element.attribute('x', dblToStr(x!));
    }
    if (hasY) {
      element.attribute('y', dblToStr(y!));
    }
  }

  /// Copies the `AttXy` members from [other].
  void copyAttXy(covariant AttXy other) {
    x = other.x;
    y = other.y;
  }
}

/// MEI attribute class for `att.Xy2` (mirrors `vrv::AttXy2`).
mixin AttXy2 {
  /// `x2` — double.
  double? x2;
  bool get hasX2 => x2 != null;

  /// `y2` — double.
  double? y2;
  bool get hasY2 => y2 != null;

  /// Mirrors `AttXy2::ReadXy2`.
  bool readXy2(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final x2Raw = element.get('x2');
    if (x2Raw != null) {
      x2 = strToDbl(x2Raw);
      if (removeAttr) element.remove('x2');
      hasAttribute = true;
    }
    final y2Raw = element.get('y2');
    if (y2Raw != null) {
      y2 = strToDbl(y2Raw);
      if (removeAttr) element.remove('y2');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttXy2::WriteXy2`.
  void writeXy2(XmlBuilder element) {
    if (hasX2) {
      element.attribute('x2', dblToStr(x2!));
    }
    if (hasY2) {
      element.attribute('y2', dblToStr(y2!));
    }
  }

  /// Copies the `AttXy2` members from [other].
  void copyAttXy2(covariant AttXy2 other) {
    x2 = other.x2;
    y2 = other.y2;
  }
}
