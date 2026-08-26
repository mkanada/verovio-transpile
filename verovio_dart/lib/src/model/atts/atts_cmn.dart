// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_cmn.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.ArpegLog` (mirrors `vrv::AttArpegLog`).
mixin AttArpegLog {
  /// `order` — arpegLog_ORDER.
  ArpeglogOrder? order;
  bool get hasOrder => order != null;

  /// Mirrors `AttArpegLog::ReadArpegLog`.
  bool readArpegLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final orderRaw = element.get('order');
    if (orderRaw != null) {
      order = strToArpeglogOrder(orderRaw);
      if (removeAttr) element.remove('order');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttArpegLog::WriteArpegLog`.
  void writeArpegLog(XmlBuilder element) {
    if (hasOrder) {
      element.attribute('order', arpeglogOrderToStr(order!));
    }
  }

  /// Copies the `AttArpegLog` members from [other].
  void copyAttArpegLog(covariant AttArpegLog other) {
    order = other.order;
  }
}

/// MEI attribute class for `att.BeamPresent` (mirrors `vrv::AttBeamPresent`).
mixin AttBeamPresent {
  /// `beam` — std::string.
  String? beam;
  bool get hasBeam => beam != null;

  /// Mirrors `AttBeamPresent::ReadBeamPresent`.
  bool readBeamPresent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final beamRaw = element.get('beam');
    if (beamRaw != null) {
      beam = identityStr(beamRaw);
      if (removeAttr) element.remove('beam');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBeamPresent::WriteBeamPresent`.
  void writeBeamPresent(XmlBuilder element) {
    if (hasBeam) {
      element.attribute('beam', identityStr(beam!));
    }
  }

  /// Copies the `AttBeamPresent` members from [other].
  void copyAttBeamPresent(covariant AttBeamPresent other) {
    beam = other.beam;
  }
}

/// MEI attribute class for `att.BeamRend` (mirrors `vrv::AttBeamRend`).
mixin AttBeamRend {
  /// `form` — beamRend_FORM.
  BeamrendForm? form;
  bool get hasForm => form != null;

  /// `place` — data_BEAMPLACE.
  Beamplace? place;
  bool get hasPlace => place != null;

  /// `slash` — data_BOOLEAN.
  bool? slash;
  bool get hasSlash => slash != null;

  /// `slope` — double.
  double? slope;
  bool get hasSlope => slope != null;

  /// Mirrors `AttBeamRend::ReadBeamRend`.
  bool readBeamRend(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToBeamrendForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    final placeRaw = element.get('place');
    if (placeRaw != null) {
      place = strToBeamplace(placeRaw);
      if (removeAttr) element.remove('place');
      hasAttribute = true;
    }
    final slashRaw = element.get('slash');
    if (slashRaw != null) {
      slash = strToBoolean(slashRaw);
      if (removeAttr) element.remove('slash');
      hasAttribute = true;
    }
    final slopeRaw = element.get('slope');
    if (slopeRaw != null) {
      slope = strToDbl(slopeRaw);
      if (removeAttr) element.remove('slope');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBeamRend::WriteBeamRend`.
  void writeBeamRend(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', beamrendFormToStr(form!));
    }
    if (hasPlace) {
      element.attribute('place', beamplaceToStr(place!));
    }
    if (hasSlash) {
      element.attribute('slash', booleanToStr(slash!));
    }
    if (hasSlope) {
      element.attribute('slope', dblToStr(slope!));
    }
  }

  /// Copies the `AttBeamRend` members from [other].
  void copyAttBeamRend(covariant AttBeamRend other) {
    form = other.form;
    place = other.place;
    slash = other.slash;
    slope = other.slope;
  }
}

/// MEI attribute class for `att.BeamSecondary` (mirrors `vrv::AttBeamSecondary`).
mixin AttBeamSecondary {
  /// `breaksec` — int.
  int? breaksec;
  bool get hasBreaksec => breaksec != null;

  /// Mirrors `AttBeamSecondary::ReadBeamSecondary`.
  bool readBeamSecondary(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final breaksecRaw = element.get('breaksec');
    if (breaksecRaw != null) {
      breaksec = strToInt(breaksecRaw);
      if (removeAttr) element.remove('breaksec');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBeamSecondary::WriteBeamSecondary`.
  void writeBeamSecondary(XmlBuilder element) {
    if (hasBreaksec) {
      element.attribute('breaksec', intToStr(breaksec!));
    }
  }

  /// Copies the `AttBeamSecondary` members from [other].
  void copyAttBeamSecondary(covariant AttBeamSecondary other) {
    breaksec = other.breaksec;
  }
}

/// MEI attribute class for `att.BeamedWith` (mirrors `vrv::AttBeamedWith`).
mixin AttBeamedWith {
  /// `beam.with` — data_NEIGHBORINGLAYER.
  Neighboringlayer? beamWith;
  bool get hasBeamWith => beamWith != null;

  /// Mirrors `AttBeamedWith::ReadBeamedWith`.
  bool readBeamedWith(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final beamWithRaw = element.get('beam.with');
    if (beamWithRaw != null) {
      beamWith = strToNeighboringlayer(beamWithRaw);
      if (removeAttr) element.remove('beam.with');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBeamedWith::WriteBeamedWith`.
  void writeBeamedWith(XmlBuilder element) {
    if (hasBeamWith) {
      element.attribute('beam.with', neighboringlayerToStr(beamWith!));
    }
  }

  /// Copies the `AttBeamedWith` members from [other].
  void copyAttBeamedWith(covariant AttBeamedWith other) {
    beamWith = other.beamWith;
  }
}

/// MEI attribute class for `att.BeamingLog` (mirrors `vrv::AttBeamingLog`).
mixin AttBeamingLog {
  /// `beam.group` — std::string.
  String? beamGroup;
  bool get hasBeamGroup => beamGroup != null;

  /// `beam.rests` — data_BOOLEAN.
  bool? beamRests;
  bool get hasBeamRests => beamRests != null;

  /// Mirrors `AttBeamingLog::ReadBeamingLog`.
  bool readBeamingLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final beamGroupRaw = element.get('beam.group');
    if (beamGroupRaw != null) {
      beamGroup = identityStr(beamGroupRaw);
      if (removeAttr) element.remove('beam.group');
      hasAttribute = true;
    }
    final beamRestsRaw = element.get('beam.rests');
    if (beamRestsRaw != null) {
      beamRests = strToBoolean(beamRestsRaw);
      if (removeAttr) element.remove('beam.rests');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBeamingLog::WriteBeamingLog`.
  void writeBeamingLog(XmlBuilder element) {
    if (hasBeamGroup) {
      element.attribute('beam.group', identityStr(beamGroup!));
    }
    if (hasBeamRests) {
      element.attribute('beam.rests', booleanToStr(beamRests!));
    }
  }

  /// Copies the `AttBeamingLog` members from [other].
  void copyAttBeamingLog(covariant AttBeamingLog other) {
    beamGroup = other.beamGroup;
    beamRests = other.beamRests;
  }
}

/// MEI attribute class for `att.BeatRptLog` (mirrors `vrv::AttBeatRptLog`).
mixin AttBeatRptLog {
  /// `beatdef` — double.
  double? beatdef;
  bool get hasBeatdef => beatdef != null;

  /// Mirrors `AttBeatRptLog::ReadBeatRptLog`.
  bool readBeatRptLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final beatdefRaw = element.get('beatdef');
    if (beatdefRaw != null) {
      beatdef = strToDbl(beatdefRaw);
      if (removeAttr) element.remove('beatdef');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBeatRptLog::WriteBeatRptLog`.
  void writeBeatRptLog(XmlBuilder element) {
    if (hasBeatdef) {
      element.attribute('beatdef', dblToStr(beatdef!));
    }
  }

  /// Copies the `AttBeatRptLog` members from [other].
  void copyAttBeatRptLog(covariant AttBeatRptLog other) {
    beatdef = other.beatdef;
  }
}

/// MEI attribute class for `att.BracketSpanLog` (mirrors `vrv::AttBracketSpanLog`).
mixin AttBracketSpanLog {
  /// `func` — bracketSpanLog_FUNC.
  BracketspanlogFunc? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttBracketSpanLog::ReadBracketSpanLog`.
  bool readBracketSpanLog(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = strToBracketspanlogFunc(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBracketSpanLog::WriteBracketSpanLog`.
  void writeBracketSpanLog(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', bracketspanlogFuncToStr(func!));
    }
  }

  /// Copies the `AttBracketSpanLog` members from [other].
  void copyAttBracketSpanLog(covariant AttBracketSpanLog other) {
    func = other.func;
  }
}

/// MEI attribute class for `att.Cutout` (mirrors `vrv::AttCutout`).
mixin AttCutout {
  /// `cutout` — cutout_CUTOUT.
  CutoutCutout? cutout;
  bool get hasCutout => cutout != null;

  /// Mirrors `AttCutout::ReadCutout`.
  bool readCutout(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final cutoutRaw = element.get('cutout');
    if (cutoutRaw != null) {
      cutout = strToCutoutCutout(cutoutRaw);
      if (removeAttr) element.remove('cutout');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCutout::WriteCutout`.
  void writeCutout(XmlBuilder element) {
    if (hasCutout) {
      element.attribute('cutout', cutoutCutoutToStr(cutout!));
    }
  }

  /// Copies the `AttCutout` members from [other].
  void copyAttCutout(covariant AttCutout other) {
    cutout = other.cutout;
  }
}

/// MEI attribute class for `att.Expandable` (mirrors `vrv::AttExpandable`).
mixin AttExpandable {
  /// `expand` — data_BOOLEAN.
  bool? expand;
  bool get hasExpand => expand != null;

  /// Mirrors `AttExpandable::ReadExpandable`.
  bool readExpandable(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final expandRaw = element.get('expand');
    if (expandRaw != null) {
      expand = strToBoolean(expandRaw);
      if (removeAttr) element.remove('expand');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttExpandable::WriteExpandable`.
  void writeExpandable(XmlBuilder element) {
    if (hasExpand) {
      element.attribute('expand', booleanToStr(expand!));
    }
  }

  /// Copies the `AttExpandable` members from [other].
  void copyAttExpandable(covariant AttExpandable other) {
    expand = other.expand;
  }
}

/// MEI attribute class for `att.GlissPresent` (mirrors `vrv::AttGlissPresent`).
mixin AttGlissPresent {
  /// `gliss` — data_GLISSANDO.
  Glissando? gliss;
  bool get hasGliss => gliss != null;

  /// Mirrors `AttGlissPresent::ReadGlissPresent`.
  bool readGlissPresent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final glissRaw = element.get('gliss');
    if (glissRaw != null) {
      gliss = strToGlissando(glissRaw);
      if (removeAttr) element.remove('gliss');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttGlissPresent::WriteGlissPresent`.
  void writeGlissPresent(XmlBuilder element) {
    if (hasGliss) {
      element.attribute('gliss', glissandoToStr(gliss!));
    }
  }

  /// Copies the `AttGlissPresent` members from [other].
  void copyAttGlissPresent(covariant AttGlissPresent other) {
    gliss = other.gliss;
  }
}

/// MEI attribute class for `att.GraceGrpLog` (mirrors `vrv::AttGraceGrpLog`).
mixin AttGraceGrpLog {
  /// `attach` — graceGrpLog_ATTACH.
  GracegrplogAttach? attach;
  bool get hasAttach => attach != null;

  /// Mirrors `AttGraceGrpLog::ReadGraceGrpLog`.
  bool readGraceGrpLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final attachRaw = element.get('attach');
    if (attachRaw != null) {
      attach = strToGracegrplogAttach(attachRaw);
      if (removeAttr) element.remove('attach');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttGraceGrpLog::WriteGraceGrpLog`.
  void writeGraceGrpLog(XmlBuilder element) {
    if (hasAttach) {
      element.attribute('attach', gracegrplogAttachToStr(attach!));
    }
  }

  /// Copies the `AttGraceGrpLog` members from [other].
  void copyAttGraceGrpLog(covariant AttGraceGrpLog other) {
    attach = other.attach;
  }
}

/// MEI attribute class for `att.Graced` (mirrors `vrv::AttGraced`).
mixin AttGraced {
  /// `grace` — data_GRACE.
  Grace? grace;
  bool get hasGrace => grace != null;

  /// `grace.time` — data_PERCENT.
  double? graceTime;
  bool get hasGraceTime => graceTime != null;

  /// Mirrors `AttGraced::ReadGraced`.
  bool readGraced(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final graceRaw = element.get('grace');
    if (graceRaw != null) {
      grace = strToGrace(graceRaw);
      if (removeAttr) element.remove('grace');
      hasAttribute = true;
    }
    final graceTimeRaw = element.get('grace.time');
    if (graceTimeRaw != null) {
      graceTime = strToDbl(graceTimeRaw);
      if (removeAttr) element.remove('grace.time');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttGraced::WriteGraced`.
  void writeGraced(XmlBuilder element) {
    if (hasGrace) {
      element.attribute('grace', graceToStr(grace!));
    }
    if (hasGraceTime) {
      element.attribute('grace.time', percentToStr(graceTime!));
    }
  }

  /// Copies the `AttGraced` members from [other].
  void copyAttGraced(covariant AttGraced other) {
    grace = other.grace;
    graceTime = other.graceTime;
  }
}

/// MEI attribute class for `att.HairpinLog` (mirrors `vrv::AttHairpinLog`).
mixin AttHairpinLog {
  /// `form` — hairpinLog_FORM.
  HairpinlogForm? form;
  bool get hasForm => form != null;

  /// `niente` — data_BOOLEAN.
  bool? niente;
  bool get hasNiente => niente != null;

  /// Mirrors `AttHairpinLog::ReadHairpinLog`.
  bool readHairpinLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToHairpinlogForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    final nienteRaw = element.get('niente');
    if (nienteRaw != null) {
      niente = strToBoolean(nienteRaw);
      if (removeAttr) element.remove('niente');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHairpinLog::WriteHairpinLog`.
  void writeHairpinLog(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', hairpinlogFormToStr(form!));
    }
    if (hasNiente) {
      element.attribute('niente', booleanToStr(niente!));
    }
  }

  /// Copies the `AttHairpinLog` members from [other].
  void copyAttHairpinLog(covariant AttHairpinLog other) {
    form = other.form;
    niente = other.niente;
  }
}

/// MEI attribute class for `att.HarpPedalLog` (mirrors `vrv::AttHarpPedalLog`).
mixin AttHarpPedalLog {
  /// `c` — data_HARPPEDALPOSITION.
  Harppedalposition? c;
  bool get hasC => c != null;

  /// `d` — data_HARPPEDALPOSITION.
  Harppedalposition? d;
  bool get hasD => d != null;

  /// `e` — data_HARPPEDALPOSITION.
  Harppedalposition? e;
  bool get hasE => e != null;

  /// `f` — data_HARPPEDALPOSITION.
  Harppedalposition? f;
  bool get hasF => f != null;

  /// `g` — data_HARPPEDALPOSITION.
  Harppedalposition? g;
  bool get hasG => g != null;

  /// `a` — data_HARPPEDALPOSITION.
  Harppedalposition? a;
  bool get hasA => a != null;

  /// `b` — data_HARPPEDALPOSITION.
  Harppedalposition? b;
  bool get hasB => b != null;

  /// Mirrors `AttHarpPedalLog::ReadHarpPedalLog`.
  bool readHarpPedalLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final cRaw = element.get('c');
    if (cRaw != null) {
      c = strToHarppedalposition(cRaw);
      if (removeAttr) element.remove('c');
      hasAttribute = true;
    }
    final dRaw = element.get('d');
    if (dRaw != null) {
      d = strToHarppedalposition(dRaw);
      if (removeAttr) element.remove('d');
      hasAttribute = true;
    }
    final eRaw = element.get('e');
    if (eRaw != null) {
      e = strToHarppedalposition(eRaw);
      if (removeAttr) element.remove('e');
      hasAttribute = true;
    }
    final fRaw = element.get('f');
    if (fRaw != null) {
      f = strToHarppedalposition(fRaw);
      if (removeAttr) element.remove('f');
      hasAttribute = true;
    }
    final gRaw = element.get('g');
    if (gRaw != null) {
      g = strToHarppedalposition(gRaw);
      if (removeAttr) element.remove('g');
      hasAttribute = true;
    }
    final aRaw = element.get('a');
    if (aRaw != null) {
      a = strToHarppedalposition(aRaw);
      if (removeAttr) element.remove('a');
      hasAttribute = true;
    }
    final bRaw = element.get('b');
    if (bRaw != null) {
      b = strToHarppedalposition(bRaw);
      if (removeAttr) element.remove('b');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHarpPedalLog::WriteHarpPedalLog`.
  void writeHarpPedalLog(XmlBuilder element) {
    if (hasC) {
      element.attribute('c', harppedalpositionToStr(c!));
    }
    if (hasD) {
      element.attribute('d', harppedalpositionToStr(d!));
    }
    if (hasE) {
      element.attribute('e', harppedalpositionToStr(e!));
    }
    if (hasF) {
      element.attribute('f', harppedalpositionToStr(f!));
    }
    if (hasG) {
      element.attribute('g', harppedalpositionToStr(g!));
    }
    if (hasA) {
      element.attribute('a', harppedalpositionToStr(a!));
    }
    if (hasB) {
      element.attribute('b', harppedalpositionToStr(b!));
    }
  }

  /// Copies the `AttHarpPedalLog` members from [other].
  void copyAttHarpPedalLog(covariant AttHarpPedalLog other) {
    c = other.c;
    d = other.d;
    e = other.e;
    f = other.f;
    g = other.g;
    a = other.a;
    b = other.b;
  }
}

/// MEI attribute class for `att.LvPresent` (mirrors `vrv::AttLvPresent`).
mixin AttLvPresent {
  /// `lv` — data_BOOLEAN.
  bool? lv;
  bool get hasLv => lv != null;

  /// Mirrors `AttLvPresent::ReadLvPresent`.
  bool readLvPresent(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final lvRaw = element.get('lv');
    if (lvRaw != null) {
      lv = strToBoolean(lvRaw);
      if (removeAttr) element.remove('lv');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLvPresent::WriteLvPresent`.
  void writeLvPresent(XmlBuilder element) {
    if (hasLv) {
      element.attribute('lv', booleanToStr(lv!));
    }
  }

  /// Copies the `AttLvPresent` members from [other].
  void copyAttLvPresent(covariant AttLvPresent other) {
    lv = other.lv;
  }
}

/// MEI attribute class for `att.MeasureLog` (mirrors `vrv::AttMeasureLog`).
mixin AttMeasureLog {
  /// `left` — data_BARRENDITION.
  Barrendition? left;
  bool get hasLeft => left != null;

  /// `right` — data_BARRENDITION.
  Barrendition? right;
  bool get hasRight => right != null;

  /// Mirrors `AttMeasureLog::ReadMeasureLog`.
  bool readMeasureLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final leftRaw = element.get('left');
    if (leftRaw != null) {
      left = strToBarrendition(leftRaw);
      if (removeAttr) element.remove('left');
      hasAttribute = true;
    }
    final rightRaw = element.get('right');
    if (rightRaw != null) {
      right = strToBarrendition(rightRaw);
      if (removeAttr) element.remove('right');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeasureLog::WriteMeasureLog`.
  void writeMeasureLog(XmlBuilder element) {
    if (hasLeft) {
      element.attribute('left', barrenditionToStr(left!));
    }
    if (hasRight) {
      element.attribute('right', barrenditionToStr(right!));
    }
  }

  /// Copies the `AttMeasureLog` members from [other].
  void copyAttMeasureLog(covariant AttMeasureLog other) {
    left = other.left;
    right = other.right;
  }
}

/// MEI attribute class for `att.MeterSigGrpLog` (mirrors `vrv::AttMeterSigGrpLog`).
mixin AttMeterSigGrpLog {
  /// `func` — meterSigGrpLog_FUNC.
  MetersiggrplogFunc? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttMeterSigGrpLog::ReadMeterSigGrpLog`.
  bool readMeterSigGrpLog(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = strToMetersiggrplogFunc(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeterSigGrpLog::WriteMeterSigGrpLog`.
  void writeMeterSigGrpLog(XmlBuilder element) {
    if (hasFunc) {
      element.attribute('func', metersiggrplogFuncToStr(func!));
    }
  }

  /// Copies the `AttMeterSigGrpLog` members from [other].
  void copyAttMeterSigGrpLog(covariant AttMeterSigGrpLog other) {
    func = other.func;
  }
}

/// MEI attribute class for `att.NumberPlacement` (mirrors `vrv::AttNumberPlacement`).
mixin AttNumberPlacement {
  /// `num.place` — data_STAFFREL_basic.
  StaffrelBasic? numPlace;
  bool get hasNumPlace => numPlace != null;

  /// `num.visible` — data_BOOLEAN.
  bool? numVisible;
  bool get hasNumVisible => numVisible != null;

  /// Mirrors `AttNumberPlacement::ReadNumberPlacement`.
  bool readNumberPlacement(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final numPlaceRaw = element.get('num.place');
    if (numPlaceRaw != null) {
      numPlace = strToStaffrelBasic(numPlaceRaw);
      if (removeAttr) element.remove('num.place');
      hasAttribute = true;
    }
    final numVisibleRaw = element.get('num.visible');
    if (numVisibleRaw != null) {
      numVisible = strToBoolean(numVisibleRaw);
      if (removeAttr) element.remove('num.visible');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNumberPlacement::WriteNumberPlacement`.
  void writeNumberPlacement(XmlBuilder element) {
    if (hasNumPlace) {
      element.attribute('num.place', staffrelBasicToStr(numPlace!));
    }
    if (hasNumVisible) {
      element.attribute('num.visible', booleanToStr(numVisible!));
    }
  }

  /// Copies the `AttNumberPlacement` members from [other].
  void copyAttNumberPlacement(covariant AttNumberPlacement other) {
    numPlace = other.numPlace;
    numVisible = other.numVisible;
  }
}

/// MEI attribute class for `att.Numbered` (mirrors `vrv::AttNumbered`).
mixin AttNumbered {
  /// `num` — int.
  int? num;
  bool get hasNum => num != null;

  /// Mirrors `AttNumbered::ReadNumbered`.
  bool readNumbered(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final numRaw = element.get('num');
    if (numRaw != null) {
      num = strToInt(numRaw);
      if (removeAttr) element.remove('num');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNumbered::WriteNumbered`.
  void writeNumbered(XmlBuilder element) {
    if (hasNum) {
      element.attribute('num', intToStr(num!));
    }
  }

  /// Copies the `AttNumbered` members from [other].
  void copyAttNumbered(covariant AttNumbered other) {
    num = other.num;
  }
}

/// MEI attribute class for `att.OctaveLog` (mirrors `vrv::AttOctaveLog`).
mixin AttOctaveLog {
  /// `coll` — octaveLog_COLL.
  OctavelogColl? coll;
  bool get hasColl => coll != null;

  /// Mirrors `AttOctaveLog::ReadOctaveLog`.
  bool readOctaveLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final collRaw = element.get('coll');
    if (collRaw != null) {
      coll = strToOctavelogColl(collRaw);
      if (removeAttr) element.remove('coll');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOctaveLog::WriteOctaveLog`.
  void writeOctaveLog(XmlBuilder element) {
    if (hasColl) {
      element.attribute('coll', octavelogCollToStr(coll!));
    }
  }

  /// Copies the `AttOctaveLog` members from [other].
  void copyAttOctaveLog(covariant AttOctaveLog other) {
    coll = other.coll;
  }
}

/// MEI attribute class for `att.PedalLog` (mirrors `vrv::AttPedalLog`).
mixin AttPedalLog {
  /// `dir` — pedalLog_DIR.
  PedallogDir? dir;
  bool get hasDir => dir != null;

  /// `func` — std::string.
  String? func;
  bool get hasFunc => func != null;

  /// Mirrors `AttPedalLog::ReadPedalLog`.
  bool readPedalLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final dirRaw = element.get('dir');
    if (dirRaw != null) {
      dir = strToPedallogDir(dirRaw);
      if (removeAttr) element.remove('dir');
      hasAttribute = true;
    }
    final funcRaw = element.get('func');
    if (funcRaw != null) {
      func = identityStr(funcRaw);
      if (removeAttr) element.remove('func');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPedalLog::WritePedalLog`.
  void writePedalLog(XmlBuilder element) {
    if (hasDir) {
      element.attribute('dir', pedallogDirToStr(dir!));
    }
    if (hasFunc) {
      element.attribute('func', identityStr(func!));
    }
  }

  /// Copies the `AttPedalLog` members from [other].
  void copyAttPedalLog(covariant AttPedalLog other) {
    dir = other.dir;
    func = other.func;
  }
}

/// MEI attribute class for `att.PianoPedals` (mirrors `vrv::AttPianoPedals`).
mixin AttPianoPedals {
  /// `pedal.style` — data_PEDALSTYLE.
  Pedalstyle? pedalStyle;
  bool get hasPedalStyle => pedalStyle != null;

  /// Mirrors `AttPianoPedals::ReadPianoPedals`.
  bool readPianoPedals(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final pedalStyleRaw = element.get('pedal.style');
    if (pedalStyleRaw != null) {
      pedalStyle = strToPedalstyle(pedalStyleRaw);
      if (removeAttr) element.remove('pedal.style');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPianoPedals::WritePianoPedals`.
  void writePianoPedals(XmlBuilder element) {
    if (hasPedalStyle) {
      element.attribute('pedal.style', pedalstyleToStr(pedalStyle!));
    }
  }

  /// Copies the `AttPianoPedals` members from [other].
  void copyAttPianoPedals(covariant AttPianoPedals other) {
    pedalStyle = other.pedalStyle;
  }
}

/// MEI attribute class for `att.Rehearsal` (mirrors `vrv::AttRehearsal`).
mixin AttRehearsal {
  /// `reh.enclose` — rehearsal_REHENCLOSE.
  RehearsalRehenclose? rehEnclose;
  bool get hasRehEnclose => rehEnclose != null;

  /// Mirrors `AttRehearsal::ReadRehearsal`.
  bool readRehearsal(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final rehEncloseRaw = element.get('reh.enclose');
    if (rehEncloseRaw != null) {
      rehEnclose = strToRehearsalRehenclose(rehEncloseRaw);
      if (removeAttr) element.remove('reh.enclose');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttRehearsal::WriteRehearsal`.
  void writeRehearsal(XmlBuilder element) {
    if (hasRehEnclose) {
      element.attribute('reh.enclose', rehearsalRehencloseToStr(rehEnclose!));
    }
  }

  /// Copies the `AttRehearsal` members from [other].
  void copyAttRehearsal(covariant AttRehearsal other) {
    rehEnclose = other.rehEnclose;
  }
}

/// MEI attribute class for `att.SlurRend` (mirrors `vrv::AttSlurRend`).
mixin AttSlurRend {
  /// `slur.lform` — data_LINEFORM.
  Lineform? slurLform;
  bool get hasSlurLform => slurLform != null;

  /// `slur.lwidth` — data_LINEWIDTH.
  LineWidth? slurLwidth;
  bool get hasSlurLwidth => slurLwidth != null;

  /// Mirrors `AttSlurRend::ReadSlurRend`.
  bool readSlurRend(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final slurLformRaw = element.get('slur.lform');
    if (slurLformRaw != null) {
      slurLform = strToLineform(slurLformRaw);
      if (removeAttr) element.remove('slur.lform');
      hasAttribute = true;
    }
    final slurLwidthRaw = element.get('slur.lwidth');
    if (slurLwidthRaw != null) {
      slurLwidth = strToLinewidth(slurLwidthRaw);
      if (removeAttr) element.remove('slur.lwidth');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSlurRend::WriteSlurRend`.
  void writeSlurRend(XmlBuilder element) {
    if (hasSlurLform) {
      element.attribute('slur.lform', lineformToStr(slurLform!));
    }
    if (hasSlurLwidth) {
      element.attribute('slur.lwidth', linewidthToStr(slurLwidth!));
    }
  }

  /// Copies the `AttSlurRend` members from [other].
  void copyAttSlurRend(covariant AttSlurRend other) {
    slurLform = other.slurLform;
    slurLwidth = other.slurLwidth;
  }
}

/// MEI attribute class for `att.StemsCmn` (mirrors `vrv::AttStemsCmn`).
mixin AttStemsCmn {
  /// `stem.with` — data_NEIGHBORINGLAYER.
  Neighboringlayer? stemWith;
  bool get hasStemWith => stemWith != null;

  /// Mirrors `AttStemsCmn::ReadStemsCmn`.
  bool readStemsCmn(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final stemWithRaw = element.get('stem.with');
    if (stemWithRaw != null) {
      stemWith = strToNeighboringlayer(stemWithRaw);
      if (removeAttr) element.remove('stem.with');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStemsCmn::WriteStemsCmn`.
  void writeStemsCmn(XmlBuilder element) {
    if (hasStemWith) {
      element.attribute('stem.with', neighboringlayerToStr(stemWith!));
    }
  }

  /// Copies the `AttStemsCmn` members from [other].
  void copyAttStemsCmn(covariant AttStemsCmn other) {
    stemWith = other.stemWith;
  }
}

/// MEI attribute class for `att.TieRend` (mirrors `vrv::AttTieRend`).
mixin AttTieRend {
  /// `tie.lform` — data_LINEFORM.
  Lineform? tieLform;
  bool get hasTieLform => tieLform != null;

  /// `tie.lwidth` — data_LINEWIDTH.
  LineWidth? tieLwidth;
  bool get hasTieLwidth => tieLwidth != null;

  /// Mirrors `AttTieRend::ReadTieRend`.
  bool readTieRend(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tieLformRaw = element.get('tie.lform');
    if (tieLformRaw != null) {
      tieLform = strToLineform(tieLformRaw);
      if (removeAttr) element.remove('tie.lform');
      hasAttribute = true;
    }
    final tieLwidthRaw = element.get('tie.lwidth');
    if (tieLwidthRaw != null) {
      tieLwidth = strToLinewidth(tieLwidthRaw);
      if (removeAttr) element.remove('tie.lwidth');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTieRend::WriteTieRend`.
  void writeTieRend(XmlBuilder element) {
    if (hasTieLform) {
      element.attribute('tie.lform', lineformToStr(tieLform!));
    }
    if (hasTieLwidth) {
      element.attribute('tie.lwidth', linewidthToStr(tieLwidth!));
    }
  }

  /// Copies the `AttTieRend` members from [other].
  void copyAttTieRend(covariant AttTieRend other) {
    tieLform = other.tieLform;
    tieLwidth = other.tieLwidth;
  }
}

/// MEI attribute class for `att.TremForm` (mirrors `vrv::AttTremForm`).
mixin AttTremForm {
  /// `form` — tremForm_FORM.
  TremformForm? form;
  bool get hasForm => form != null;

  /// Mirrors `AttTremForm::ReadTremForm`.
  bool readTremForm(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToTremformForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTremForm::WriteTremForm`.
  void writeTremForm(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', tremformFormToStr(form!));
    }
  }

  /// Copies the `AttTremForm` members from [other].
  void copyAttTremForm(covariant AttTremForm other) {
    form = other.form;
  }
}

/// MEI attribute class for `att.TremMeasured` (mirrors `vrv::AttTremMeasured`).
mixin AttTremMeasured {
  /// `unitdur` — data_DURATION.
  MeiDuration? unitdur;
  bool get hasUnitdur => unitdur != null;

  /// Mirrors `AttTremMeasured::ReadTremMeasured`.
  bool readTremMeasured(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final unitdurRaw = element.get('unitdur');
    if (unitdurRaw != null) {
      unitdur = strToDuration(unitdurRaw);
      if (removeAttr) element.remove('unitdur');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTremMeasured::WriteTremMeasured`.
  void writeTremMeasured(XmlBuilder element) {
    if (hasUnitdur) {
      element.attribute('unitdur', durationToStr(unitdur!));
    }
  }

  /// Copies the `AttTremMeasured` members from [other].
  void copyAttTremMeasured(covariant AttTremMeasured other) {
    unitdur = other.unitdur;
  }
}
