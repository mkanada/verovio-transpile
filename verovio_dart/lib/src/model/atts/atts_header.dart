// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_header.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.Adlibitum` (mirrors `vrv::AttAdlibitum`).
mixin AttAdlibitum {
  /// `adlib` — data_BOOLEAN.
  bool? adlib;
  bool get hasAdlib => adlib != null;

  /// Mirrors `AttAdlibitum::ReadAdlibitum`.
  bool readAdlibitum(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final adlibRaw = element.get('adlib');
    if (adlibRaw != null) {
      adlib = strToBoolean(adlibRaw);
      if (removeAttr) element.remove('adlib');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAdlibitum::WriteAdlibitum`.
  void writeAdlibitum(XmlBuilder element) {
    if (hasAdlib) {
      element.attribute('adlib', booleanToStr(adlib!));
    }
  }

  /// Copies the `AttAdlibitum` members from [other].
  void copyAttAdlibitum(covariant AttAdlibitum other) {
    adlib = other.adlib;
  }
}

/// MEI attribute class for `att.BifoliumSurfaces` (mirrors `vrv::AttBifoliumSurfaces`).
mixin AttBifoliumSurfaces {
  /// `outer.recto` — std::string.
  String? outerRecto;
  bool get hasOuterRecto => outerRecto != null;

  /// `inner.verso` — std::string.
  String? innerVerso;
  bool get hasInnerVerso => innerVerso != null;

  /// `inner.recto` — std::string.
  String? innerRecto;
  bool get hasInnerRecto => innerRecto != null;

  /// `outer.verso` — std::string.
  String? outerVerso;
  bool get hasOuterVerso => outerVerso != null;

  /// Mirrors `AttBifoliumSurfaces::ReadBifoliumSurfaces`.
  bool readBifoliumSurfaces(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final outerRectoRaw = element.get('outer.recto');
    if (outerRectoRaw != null) {
      outerRecto = identityStr(outerRectoRaw);
      if (removeAttr) element.remove('outer.recto');
      hasAttribute = true;
    }
    final innerVersoRaw = element.get('inner.verso');
    if (innerVersoRaw != null) {
      innerVerso = identityStr(innerVersoRaw);
      if (removeAttr) element.remove('inner.verso');
      hasAttribute = true;
    }
    final innerRectoRaw = element.get('inner.recto');
    if (innerRectoRaw != null) {
      innerRecto = identityStr(innerRectoRaw);
      if (removeAttr) element.remove('inner.recto');
      hasAttribute = true;
    }
    final outerVersoRaw = element.get('outer.verso');
    if (outerVersoRaw != null) {
      outerVerso = identityStr(outerVersoRaw);
      if (removeAttr) element.remove('outer.verso');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBifoliumSurfaces::WriteBifoliumSurfaces`.
  void writeBifoliumSurfaces(XmlBuilder element) {
    if (hasOuterRecto) {
      element.attribute('outer.recto', identityStr(outerRecto!));
    }
    if (hasInnerVerso) {
      element.attribute('inner.verso', identityStr(innerVerso!));
    }
    if (hasInnerRecto) {
      element.attribute('inner.recto', identityStr(innerRecto!));
    }
    if (hasOuterVerso) {
      element.attribute('outer.verso', identityStr(outerVerso!));
    }
  }

  /// Copies the `AttBifoliumSurfaces` members from [other].
  void copyAttBifoliumSurfaces(covariant AttBifoliumSurfaces other) {
    outerRecto = other.outerRecto;
    innerVerso = other.innerVerso;
    innerRecto = other.innerRecto;
    outerVerso = other.outerVerso;
  }
}

/// MEI attribute class for `att.FoliumSurfaces` (mirrors `vrv::AttFoliumSurfaces`).
mixin AttFoliumSurfaces {
  /// `recto` — std::string.
  String? recto;
  bool get hasRecto => recto != null;

  /// `verso` — std::string.
  String? verso;
  bool get hasVerso => verso != null;

  /// Mirrors `AttFoliumSurfaces::ReadFoliumSurfaces`.
  bool readFoliumSurfaces(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final rectoRaw = element.get('recto');
    if (rectoRaw != null) {
      recto = identityStr(rectoRaw);
      if (removeAttr) element.remove('recto');
      hasAttribute = true;
    }
    final versoRaw = element.get('verso');
    if (versoRaw != null) {
      verso = identityStr(versoRaw);
      if (removeAttr) element.remove('verso');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttFoliumSurfaces::WriteFoliumSurfaces`.
  void writeFoliumSurfaces(XmlBuilder element) {
    if (hasRecto) {
      element.attribute('recto', identityStr(recto!));
    }
    if (hasVerso) {
      element.attribute('verso', identityStr(verso!));
    }
  }

  /// Copies the `AttFoliumSurfaces` members from [other].
  void copyAttFoliumSurfaces(covariant AttFoliumSurfaces other) {
    recto = other.recto;
    verso = other.verso;
  }
}

/// MEI attribute class for `att.PerfRes` (mirrors `vrv::AttPerfRes`).
mixin AttPerfRes {
  /// `solo` — data_BOOLEAN.
  bool? solo;
  bool get hasSolo => solo != null;

  /// Mirrors `AttPerfRes::ReadPerfRes`.
  bool readPerfRes(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final soloRaw = element.get('solo');
    if (soloRaw != null) {
      solo = strToBoolean(soloRaw);
      if (removeAttr) element.remove('solo');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPerfRes::WritePerfRes`.
  void writePerfRes(XmlBuilder element) {
    if (hasSolo) {
      element.attribute('solo', booleanToStr(solo!));
    }
  }

  /// Copies the `AttPerfRes` members from [other].
  void copyAttPerfRes(covariant AttPerfRes other) {
    solo = other.solo;
  }
}

/// MEI attribute class for `att.PerfResBasic` (mirrors `vrv::AttPerfResBasic`).
mixin AttPerfResBasic {
  /// `count` — int.
  int? count;
  bool get hasCount => count != null;

  /// Mirrors `AttPerfResBasic::ReadPerfResBasic`.
  bool readPerfResBasic(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final countRaw = element.get('count');
    if (countRaw != null) {
      count = strToInt(countRaw);
      if (removeAttr) element.remove('count');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPerfResBasic::WritePerfResBasic`.
  void writePerfResBasic(XmlBuilder element) {
    if (hasCount) {
      element.attribute('count', intToStr(count!));
    }
  }

  /// Copies the `AttPerfResBasic` members from [other].
  void copyAttPerfResBasic(covariant AttPerfResBasic other) {
    count = other.count;
  }
}

/// MEI attribute class for `att.RecordType` (mirrors `vrv::AttRecordType`).
mixin AttRecordType {
  /// `recordtype` — recordType_RECORDTYPE.
  RecordtypeRecordtype? recordtype;
  bool get hasRecordtype => recordtype != null;

  /// Mirrors `AttRecordType::ReadRecordType`.
  bool readRecordType(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final recordtypeRaw = element.get('recordtype');
    if (recordtypeRaw != null) {
      recordtype = strToRecordtypeRecordtype(recordtypeRaw);
      if (removeAttr) element.remove('recordtype');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttRecordType::WriteRecordType`.
  void writeRecordType(XmlBuilder element) {
    if (hasRecordtype) {
      element.attribute('recordtype', recordtypeRecordtypeToStr(recordtype!));
    }
  }

  /// Copies the `AttRecordType` members from [other].
  void copyAttRecordType(covariant AttRecordType other) {
    recordtype = other.recordtype;
  }
}

/// MEI attribute class for `att.RegularMethod` (mirrors `vrv::AttRegularMethod`).
mixin AttRegularMethod {
  /// `method` — regularMethod_METHOD.
  RegularmethodMethod? method;
  bool get hasMethod => method != null;

  /// Mirrors `AttRegularMethod::ReadRegularMethod`.
  bool readRegularMethod(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final methodRaw = element.get('method');
    if (methodRaw != null) {
      method = strToRegularmethodMethod(methodRaw);
      if (removeAttr) element.remove('method');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttRegularMethod::WriteRegularMethod`.
  void writeRegularMethod(XmlBuilder element) {
    if (hasMethod) {
      element.attribute('method', regularmethodMethodToStr(method!));
    }
  }

  /// Copies the `AttRegularMethod` members from [other].
  void copyAttRegularMethod(covariant AttRegularMethod other) {
    method = other.method;
  }
}
