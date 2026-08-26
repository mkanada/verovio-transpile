// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_neumes.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.DivLineLog` (mirrors `vrv::AttDivLineLog`).
mixin AttDivLineLog {
  /// `form` — divLineLog_FORM.
  DivlinelogForm? form;
  bool get hasForm => form != null;

  /// Mirrors `AttDivLineLog::ReadDivLineLog`.
  bool readDivLineLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToDivlinelogForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDivLineLog::WriteDivLineLog`.
  void writeDivLineLog(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', divlinelogFormToStr(form!));
    }
  }

  /// Copies the `AttDivLineLog` members from [other].
  void copyAttDivLineLog(covariant AttDivLineLog other) {
    form = other.form;
  }
}

/// MEI attribute class for `att.NcLog` (mirrors `vrv::AttNcLog`).
mixin AttNcLog {
  /// `oct` — std::string.
  String? oct;
  bool get hasOct => oct != null;

  /// `pname` — std::string.
  String? pname;
  bool get hasPname => pname != null;

  /// Mirrors `AttNcLog::ReadNcLog`.
  bool readNcLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final octRaw = element.get('oct');
    if (octRaw != null) {
      oct = identityStr(octRaw);
      if (removeAttr) element.remove('oct');
      hasAttribute = true;
    }
    final pnameRaw = element.get('pname');
    if (pnameRaw != null) {
      pname = identityStr(pnameRaw);
      if (removeAttr) element.remove('pname');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNcLog::WriteNcLog`.
  void writeNcLog(XmlBuilder element) {
    if (hasOct) {
      element.attribute('oct', identityStr(oct!));
    }
    if (hasPname) {
      element.attribute('pname', identityStr(pname!));
    }
  }

  /// Copies the `AttNcLog` members from [other].
  void copyAttNcLog(covariant AttNcLog other) {
    oct = other.oct;
    pname = other.pname;
  }
}

/// MEI attribute class for `att.NcForm` (mirrors `vrv::AttNcForm`).
mixin AttNcForm {
  /// `angled` — data_BOOLEAN.
  bool? angled;
  bool get hasAngled => angled != null;

  /// `con` — ncForm_CON.
  NcformCon? con;
  bool get hasCon => con != null;

  /// `hooked` — data_BOOLEAN.
  bool? hooked;
  bool get hasHooked => hooked != null;

  /// `ligated` — data_BOOLEAN.
  bool? ligated;
  bool get hasLigated => ligated != null;

  /// `rellen` — ncForm_RELLEN.
  NcformRellen? rellen;
  bool get hasRellen => rellen != null;

  /// `sShape` — std::string.
  String? sShape;
  bool get hasSShape => sShape != null;

  /// `tilt` — data_COMPASSDIRECTION.
  Compassdirection? tilt;
  bool get hasTilt => tilt != null;

  /// Mirrors `AttNcForm::ReadNcForm`.
  bool readNcForm(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final angledRaw = element.get('angled');
    if (angledRaw != null) {
      angled = strToBoolean(angledRaw);
      if (removeAttr) element.remove('angled');
      hasAttribute = true;
    }
    final conRaw = element.get('con');
    if (conRaw != null) {
      con = strToNcformCon(conRaw);
      if (removeAttr) element.remove('con');
      hasAttribute = true;
    }
    final hookedRaw = element.get('hooked');
    if (hookedRaw != null) {
      hooked = strToBoolean(hookedRaw);
      if (removeAttr) element.remove('hooked');
      hasAttribute = true;
    }
    final ligatedRaw = element.get('ligated');
    if (ligatedRaw != null) {
      ligated = strToBoolean(ligatedRaw);
      if (removeAttr) element.remove('ligated');
      hasAttribute = true;
    }
    final rellenRaw = element.get('rellen');
    if (rellenRaw != null) {
      rellen = strToNcformRellen(rellenRaw);
      if (removeAttr) element.remove('rellen');
      hasAttribute = true;
    }
    final sShapeRaw = element.get('sShape');
    if (sShapeRaw != null) {
      sShape = identityStr(sShapeRaw);
      if (removeAttr) element.remove('sShape');
      hasAttribute = true;
    }
    final tiltRaw = element.get('tilt');
    if (tiltRaw != null) {
      tilt = strToCompassdirection(tiltRaw);
      if (removeAttr) element.remove('tilt');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNcForm::WriteNcForm`.
  void writeNcForm(XmlBuilder element) {
    if (hasAngled) {
      element.attribute('angled', booleanToStr(angled!));
    }
    if (hasCon) {
      element.attribute('con', ncformConToStr(con!));
    }
    if (hasHooked) {
      element.attribute('hooked', booleanToStr(hooked!));
    }
    if (hasLigated) {
      element.attribute('ligated', booleanToStr(ligated!));
    }
    if (hasRellen) {
      element.attribute('rellen', ncformRellenToStr(rellen!));
    }
    if (hasSShape) {
      element.attribute('sShape', identityStr(sShape!));
    }
    if (hasTilt) {
      element.attribute('tilt', compassdirectionToStr(tilt!));
    }
  }

  /// Copies the `AttNcForm` members from [other].
  void copyAttNcForm(covariant AttNcForm other) {
    angled = other.angled;
    con = other.con;
    hooked = other.hooked;
    ligated = other.ligated;
    rellen = other.rellen;
    sShape = other.sShape;
    tilt = other.tilt;
  }
}

/// MEI attribute class for `att.NeumeType` (mirrors `vrv::AttNeumeType`).
mixin AttNeumeType {
  /// `type` — std::string.
  String? type;
  bool get hasType => type != null;

  /// Mirrors `AttNeumeType::ReadNeumeType`.
  bool readNeumeType(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final typeRaw = element.get('type');
    if (typeRaw != null) {
      type = identityStr(typeRaw);
      if (removeAttr) element.remove('type');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNeumeType::WriteNeumeType`.
  void writeNeumeType(XmlBuilder element) {
    if (hasType) {
      element.attribute('type', identityStr(type!));
    }
  }

  /// Copies the `AttNeumeType` members from [other].
  void copyAttNeumeType(covariant AttNeumeType other) {
    type = other.type;
  }
}
