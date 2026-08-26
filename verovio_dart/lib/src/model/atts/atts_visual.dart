// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_visual.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.AnnotVis` (mirrors `vrv::AttAnnotVis`).
mixin AttAnnotVis {
  /// `place` — data_PLACEMENT.
  Placement? place;
  bool get hasPlace => place != null;

  /// Mirrors `AttAnnotVis::ReadAnnotVis`.
  bool readAnnotVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final placeRaw = element.get('place');
    if (placeRaw != null) {
      place = strToPlacement(placeRaw);
      if (removeAttr) element.remove('place');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAnnotVis::WriteAnnotVis`.
  void writeAnnotVis(XmlBuilder element) {
    if (hasPlace) {
      element.attribute('place', placementToStr(place!));
    }
  }

  /// Copies the `AttAnnotVis` members from [other].
  void copyAttAnnotVis(covariant AttAnnotVis other) {
    place = other.place;
  }
}

/// MEI attribute class for `att.ArpegVis` (mirrors `vrv::AttArpegVis`).
mixin AttArpegVis {
  /// `arrow` — data_BOOLEAN.
  bool? arrow;
  bool get hasArrow => arrow != null;

  /// `arrow.shape` — data_LINESTARTENDSYMBOL.
  Linestartendsymbol? arrowShape;
  bool get hasArrowShape => arrowShape != null;

  /// `arrow.size` — int.
  int? arrowSize;
  bool get hasArrowSize => arrowSize != null;

  /// `arrow.color` — std::string.
  String? arrowColor;
  bool get hasArrowColor => arrowColor != null;

  /// `arrow.fillcolor` — std::string.
  String? arrowFillcolor;
  bool get hasArrowFillcolor => arrowFillcolor != null;

  /// Mirrors `AttArpegVis::ReadArpegVis`.
  bool readArpegVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final arrowRaw = element.get('arrow');
    if (arrowRaw != null) {
      arrow = strToBoolean(arrowRaw);
      if (removeAttr) element.remove('arrow');
      hasAttribute = true;
    }
    final arrowShapeRaw = element.get('arrow.shape');
    if (arrowShapeRaw != null) {
      arrowShape = strToLinestartendsymbol(arrowShapeRaw);
      if (removeAttr) element.remove('arrow.shape');
      hasAttribute = true;
    }
    final arrowSizeRaw = element.get('arrow.size');
    if (arrowSizeRaw != null) {
      arrowSize = strToInt(arrowSizeRaw);
      if (removeAttr) element.remove('arrow.size');
      hasAttribute = true;
    }
    final arrowColorRaw = element.get('arrow.color');
    if (arrowColorRaw != null) {
      arrowColor = identityStr(arrowColorRaw);
      if (removeAttr) element.remove('arrow.color');
      hasAttribute = true;
    }
    final arrowFillcolorRaw = element.get('arrow.fillcolor');
    if (arrowFillcolorRaw != null) {
      arrowFillcolor = identityStr(arrowFillcolorRaw);
      if (removeAttr) element.remove('arrow.fillcolor');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttArpegVis::WriteArpegVis`.
  void writeArpegVis(XmlBuilder element) {
    if (hasArrow) {
      element.attribute('arrow', booleanToStr(arrow!));
    }
    if (hasArrowShape) {
      element.attribute('arrow.shape', linestartendsymbolToStr(arrowShape!));
    }
    if (hasArrowSize) {
      element.attribute('arrow.size', intToStr(arrowSize!));
    }
    if (hasArrowColor) {
      element.attribute('arrow.color', identityStr(arrowColor!));
    }
    if (hasArrowFillcolor) {
      element.attribute('arrow.fillcolor', identityStr(arrowFillcolor!));
    }
  }

  /// Copies the `AttArpegVis` members from [other].
  void copyAttArpegVis(covariant AttArpegVis other) {
    arrow = other.arrow;
    arrowShape = other.arrowShape;
    arrowSize = other.arrowSize;
    arrowColor = other.arrowColor;
    arrowFillcolor = other.arrowFillcolor;
  }
}

/// MEI attribute class for `att.BarLineVis` (mirrors `vrv::AttBarLineVis`).
mixin AttBarLineVis {
  /// `len` — double.
  double? len;
  bool get hasLen => len != null;

  /// `method` — data_BARMETHOD.
  Barmethod? method;
  bool get hasMethod => method != null;

  /// `place` — int.
  int? place;
  bool get hasPlace => place != null;

  /// Mirrors `AttBarLineVis::ReadBarLineVis`.
  bool readBarLineVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final lenRaw = element.get('len');
    if (lenRaw != null) {
      len = strToDbl(lenRaw);
      if (removeAttr) element.remove('len');
      hasAttribute = true;
    }
    final methodRaw = element.get('method');
    if (methodRaw != null) {
      method = strToBarmethod(methodRaw);
      if (removeAttr) element.remove('method');
      hasAttribute = true;
    }
    final placeRaw = element.get('place');
    if (placeRaw != null) {
      place = strToInt(placeRaw);
      if (removeAttr) element.remove('place');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBarLineVis::WriteBarLineVis`.
  void writeBarLineVis(XmlBuilder element) {
    if (hasLen) {
      element.attribute('len', dblToStr(len!));
    }
    if (hasMethod) {
      element.attribute('method', barmethodToStr(method!));
    }
    if (hasPlace) {
      element.attribute('place', intToStr(place!));
    }
  }

  /// Copies the `AttBarLineVis` members from [other].
  void copyAttBarLineVis(covariant AttBarLineVis other) {
    len = other.len;
    method = other.method;
    place = other.place;
  }
}

/// MEI attribute class for `att.BeamingVis` (mirrors `vrv::AttBeamingVis`).
mixin AttBeamingVis {
  /// `beam.color` — std::string.
  String? beamColor;
  bool get hasBeamColor => beamColor != null;

  /// `beam.rend` — beamingVis_BEAMREND.
  BeamingvisBeamrend? beamRend;
  bool get hasBeamRend => beamRend != null;

  /// `beam.slope` — double.
  double? beamSlope;
  bool get hasBeamSlope => beamSlope != null;

  /// Mirrors `AttBeamingVis::ReadBeamingVis`.
  bool readBeamingVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final beamColorRaw = element.get('beam.color');
    if (beamColorRaw != null) {
      beamColor = identityStr(beamColorRaw);
      if (removeAttr) element.remove('beam.color');
      hasAttribute = true;
    }
    final beamRendRaw = element.get('beam.rend');
    if (beamRendRaw != null) {
      beamRend = strToBeamingvisBeamrend(beamRendRaw);
      if (removeAttr) element.remove('beam.rend');
      hasAttribute = true;
    }
    final beamSlopeRaw = element.get('beam.slope');
    if (beamSlopeRaw != null) {
      beamSlope = strToDbl(beamSlopeRaw);
      if (removeAttr) element.remove('beam.slope');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBeamingVis::WriteBeamingVis`.
  void writeBeamingVis(XmlBuilder element) {
    if (hasBeamColor) {
      element.attribute('beam.color', identityStr(beamColor!));
    }
    if (hasBeamRend) {
      element.attribute('beam.rend', beamingvisBeamrendToStr(beamRend!));
    }
    if (hasBeamSlope) {
      element.attribute('beam.slope', dblToStr(beamSlope!));
    }
  }

  /// Copies the `AttBeamingVis` members from [other].
  void copyAttBeamingVis(covariant AttBeamingVis other) {
    beamColor = other.beamColor;
    beamRend = other.beamRend;
    beamSlope = other.beamSlope;
  }
}

/// MEI attribute class for `att.BeatRptVis` (mirrors `vrv::AttBeatRptVis`).
mixin AttBeatRptVis {
  /// `slash` — data_BEATRPT_REND.
  BeatrptRend? slash;
  bool get hasSlash => slash != null;

  /// Mirrors `AttBeatRptVis::ReadBeatRptVis`.
  bool readBeatRptVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final slashRaw = element.get('slash');
    if (slashRaw != null) {
      slash = strToBeatrptRend(slashRaw);
      if (removeAttr) element.remove('slash');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBeatRptVis::WriteBeatRptVis`.
  void writeBeatRptVis(XmlBuilder element) {
    if (hasSlash) {
      element.attribute('slash', beatrptRendToStr(slash!));
    }
  }

  /// Copies the `AttBeatRptVis` members from [other].
  void copyAttBeatRptVis(covariant AttBeatRptVis other) {
    slash = other.slash;
  }
}

/// MEI attribute class for `att.ChordVis` (mirrors `vrv::AttChordVis`).
mixin AttChordVis {
  /// `cluster` — data_CLUSTER.
  Cluster? cluster;
  bool get hasCluster => cluster != null;

  /// Mirrors `AttChordVis::ReadChordVis`.
  bool readChordVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final clusterRaw = element.get('cluster');
    if (clusterRaw != null) {
      cluster = strToCluster(clusterRaw);
      if (removeAttr) element.remove('cluster');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttChordVis::WriteChordVis`.
  void writeChordVis(XmlBuilder element) {
    if (hasCluster) {
      element.attribute('cluster', clusterToStr(cluster!));
    }
  }

  /// Copies the `AttChordVis` members from [other].
  void copyAttChordVis(covariant AttChordVis other) {
    cluster = other.cluster;
  }
}

/// MEI attribute class for `att.CleffingVis` (mirrors `vrv::AttCleffingVis`).
mixin AttCleffingVis {
  /// `clef.color` — std::string.
  String? clefColor;
  bool get hasClefColor => clefColor != null;

  /// `clef.visible` — data_BOOLEAN.
  bool? clefVisible;
  bool get hasClefVisible => clefVisible != null;

  /// Mirrors `AttCleffingVis::ReadCleffingVis`.
  bool readCleffingVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final clefColorRaw = element.get('clef.color');
    if (clefColorRaw != null) {
      clefColor = identityStr(clefColorRaw);
      if (removeAttr) element.remove('clef.color');
      hasAttribute = true;
    }
    final clefVisibleRaw = element.get('clef.visible');
    if (clefVisibleRaw != null) {
      clefVisible = strToBoolean(clefVisibleRaw);
      if (removeAttr) element.remove('clef.visible');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCleffingVis::WriteCleffingVis`.
  void writeCleffingVis(XmlBuilder element) {
    if (hasClefColor) {
      element.attribute('clef.color', identityStr(clefColor!));
    }
    if (hasClefVisible) {
      element.attribute('clef.visible', booleanToStr(clefVisible!));
    }
  }

  /// Copies the `AttCleffingVis` members from [other].
  void copyAttCleffingVis(covariant AttCleffingVis other) {
    clefColor = other.clefColor;
    clefVisible = other.clefVisible;
  }
}

/// MEI attribute class for `att.CurvatureDirection` (mirrors `vrv::AttCurvatureDirection`).
mixin AttCurvatureDirection {
  /// `curve` — curvatureDirection_CURVE.
  CurvaturedirectionCurve? curve;
  bool get hasCurve => curve != null;

  /// Mirrors `AttCurvatureDirection::ReadCurvatureDirection`.
  bool readCurvatureDirection(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final curveRaw = element.get('curve');
    if (curveRaw != null) {
      curve = strToCurvaturedirectionCurve(curveRaw);
      if (removeAttr) element.remove('curve');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttCurvatureDirection::WriteCurvatureDirection`.
  void writeCurvatureDirection(XmlBuilder element) {
    if (hasCurve) {
      element.attribute('curve', curvaturedirectionCurveToStr(curve!));
    }
  }

  /// Copies the `AttCurvatureDirection` members from [other].
  void copyAttCurvatureDirection(covariant AttCurvatureDirection other) {
    curve = other.curve;
  }
}

/// MEI attribute class for `att.EpisemaVis` (mirrors `vrv::AttEpisemaVis`).
mixin AttEpisemaVis {
  /// `form` — episemaVis_FORM.
  EpisemavisForm? form;
  bool get hasForm => form != null;

  /// `place` — data_EVENTREL.
  Eventrel? place;
  bool get hasPlace => place != null;

  /// Mirrors `AttEpisemaVis::ReadEpisemaVis`.
  bool readEpisemaVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToEpisemavisForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    final placeRaw = element.get('place');
    if (placeRaw != null) {
      place = strToEventrel(placeRaw);
      if (removeAttr) element.remove('place');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttEpisemaVis::WriteEpisemaVis`.
  void writeEpisemaVis(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', episemavisFormToStr(form!));
    }
    if (hasPlace) {
      element.attribute('place', eventrelToStr(place!));
    }
  }

  /// Copies the `AttEpisemaVis` members from [other].
  void copyAttEpisemaVis(covariant AttEpisemaVis other) {
    form = other.form;
    place = other.place;
  }
}

/// MEI attribute class for `att.FTremVis` (mirrors `vrv::AttFTremVis`).
mixin AttFTremVis {
  /// `beams` — int.
  int? beams;
  bool get hasBeams => beams != null;

  /// `beams.float` — int.
  int? beamsFloat;
  bool get hasBeamsFloat => beamsFloat != null;

  /// `float.gap` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? floatGap;
  bool get hasFloatGap => floatGap != null;

  /// Mirrors `AttFTremVis::ReadFTremVis`.
  bool readFTremVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final beamsRaw = element.get('beams');
    if (beamsRaw != null) {
      beams = strToInt(beamsRaw);
      if (removeAttr) element.remove('beams');
      hasAttribute = true;
    }
    final beamsFloatRaw = element.get('beams.float');
    if (beamsFloatRaw != null) {
      beamsFloat = strToInt(beamsFloatRaw);
      if (removeAttr) element.remove('beams.float');
      hasAttribute = true;
    }
    final floatGapRaw = element.get('float.gap');
    if (floatGapRaw != null) {
      floatGap = strToMeasurementunsigned(floatGapRaw);
      if (removeAttr) element.remove('float.gap');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttFTremVis::WriteFTremVis`.
  void writeFTremVis(XmlBuilder element) {
    if (hasBeams) {
      element.attribute('beams', intToStr(beams!));
    }
    if (hasBeamsFloat) {
      element.attribute('beams.float', intToStr(beamsFloat!));
    }
    if (hasFloatGap) {
      element.attribute('float.gap', measurementunsignedToStr(floatGap!));
    }
  }

  /// Copies the `AttFTremVis` members from [other].
  void copyAttFTremVis(covariant AttFTremVis other) {
    beams = other.beams;
    beamsFloat = other.beamsFloat;
    floatGap = other.floatGap;
  }
}

/// MEI attribute class for `att.FermataVis` (mirrors `vrv::AttFermataVis`).
mixin AttFermataVis {
  /// `form` — fermataVis_FORM.
  FermatavisForm? form;
  bool get hasForm => form != null;

  /// `shape` — fermataVis_SHAPE.
  FermatavisShape? shape;
  bool get hasShape => shape != null;

  /// Mirrors `AttFermataVis::ReadFermataVis`.
  bool readFermataVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToFermatavisForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    final shapeRaw = element.get('shape');
    if (shapeRaw != null) {
      shape = strToFermatavisShape(shapeRaw);
      if (removeAttr) element.remove('shape');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttFermataVis::WriteFermataVis`.
  void writeFermataVis(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', fermatavisFormToStr(form!));
    }
    if (hasShape) {
      element.attribute('shape', fermatavisShapeToStr(shape!));
    }
  }

  /// Copies the `AttFermataVis` members from [other].
  void copyAttFermataVis(covariant AttFermataVis other) {
    form = other.form;
    shape = other.shape;
  }
}

/// MEI attribute class for `att.FingGrpVis` (mirrors `vrv::AttFingGrpVis`).
mixin AttFingGrpVis {
  /// `orient` — fingGrpVis_ORIENT.
  FinggrpvisOrient? orient;
  bool get hasOrient => orient != null;

  /// Mirrors `AttFingGrpVis::ReadFingGrpVis`.
  bool readFingGrpVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final orientRaw = element.get('orient');
    if (orientRaw != null) {
      orient = strToFinggrpvisOrient(orientRaw);
      if (removeAttr) element.remove('orient');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttFingGrpVis::WriteFingGrpVis`.
  void writeFingGrpVis(XmlBuilder element) {
    if (hasOrient) {
      element.attribute('orient', finggrpvisOrientToStr(orient!));
    }
  }

  /// Copies the `AttFingGrpVis` members from [other].
  void copyAttFingGrpVis(covariant AttFingGrpVis other) {
    orient = other.orient;
  }
}

/// MEI attribute class for `att.GuitarGridVis` (mirrors `vrv::AttGuitarGridVis`).
mixin AttGuitarGridVis {
  /// `grid.show` — data_BOOLEAN.
  bool? gridShow;
  bool get hasGridShow => gridShow != null;

  /// Mirrors `AttGuitarGridVis::ReadGuitarGridVis`.
  bool readGuitarGridVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final gridShowRaw = element.get('grid.show');
    if (gridShowRaw != null) {
      gridShow = strToBoolean(gridShowRaw);
      if (removeAttr) element.remove('grid.show');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttGuitarGridVis::WriteGuitarGridVis`.
  void writeGuitarGridVis(XmlBuilder element) {
    if (hasGridShow) {
      element.attribute('grid.show', booleanToStr(gridShow!));
    }
  }

  /// Copies the `AttGuitarGridVis` members from [other].
  void copyAttGuitarGridVis(covariant AttGuitarGridVis other) {
    gridShow = other.gridShow;
  }
}

/// MEI attribute class for `att.HairpinVis` (mirrors `vrv::AttHairpinVis`).
mixin AttHairpinVis {
  /// `opening` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? opening;
  bool get hasOpening => opening != null;

  /// `closed` — data_BOOLEAN.
  bool? closed;
  bool get hasClosed => closed != null;

  /// `opening.vertical` — data_BOOLEAN.
  bool? openingVertical;
  bool get hasOpeningVertical => openingVertical != null;

  /// `angle.optimize` — data_BOOLEAN.
  bool? angleOptimize;
  bool get hasAngleOptimize => angleOptimize != null;

  /// Mirrors `AttHairpinVis::ReadHairpinVis`.
  bool readHairpinVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final openingRaw = element.get('opening');
    if (openingRaw != null) {
      opening = strToMeasurementunsigned(openingRaw);
      if (removeAttr) element.remove('opening');
      hasAttribute = true;
    }
    final closedRaw = element.get('closed');
    if (closedRaw != null) {
      closed = strToBoolean(closedRaw);
      if (removeAttr) element.remove('closed');
      hasAttribute = true;
    }
    final openingVerticalRaw = element.get('opening.vertical');
    if (openingVerticalRaw != null) {
      openingVertical = strToBoolean(openingVerticalRaw);
      if (removeAttr) element.remove('opening.vertical');
      hasAttribute = true;
    }
    final angleOptimizeRaw = element.get('angle.optimize');
    if (angleOptimizeRaw != null) {
      angleOptimize = strToBoolean(angleOptimizeRaw);
      if (removeAttr) element.remove('angle.optimize');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHairpinVis::WriteHairpinVis`.
  void writeHairpinVis(XmlBuilder element) {
    if (hasOpening) {
      element.attribute('opening', measurementunsignedToStr(opening!));
    }
    if (hasClosed) {
      element.attribute('closed', booleanToStr(closed!));
    }
    if (hasOpeningVertical) {
      element.attribute('opening.vertical', booleanToStr(openingVertical!));
    }
    if (hasAngleOptimize) {
      element.attribute('angle.optimize', booleanToStr(angleOptimize!));
    }
  }

  /// Copies the `AttHairpinVis` members from [other].
  void copyAttHairpinVis(covariant AttHairpinVis other) {
    opening = other.opening;
    closed = other.closed;
    openingVertical = other.openingVertical;
    angleOptimize = other.angleOptimize;
  }
}

/// MEI attribute class for `att.HarmVis` (mirrors `vrv::AttHarmVis`).
mixin AttHarmVis {
  /// `rendgrid` — harmVis_RENDGRID.
  HarmvisRendgrid? rendgrid;
  bool get hasRendgrid => rendgrid != null;

  /// Mirrors `AttHarmVis::ReadHarmVis`.
  bool readHarmVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final rendgridRaw = element.get('rendgrid');
    if (rendgridRaw != null) {
      rendgrid = strToHarmvisRendgrid(rendgridRaw);
      if (removeAttr) element.remove('rendgrid');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHarmVis::WriteHarmVis`.
  void writeHarmVis(XmlBuilder element) {
    if (hasRendgrid) {
      element.attribute('rendgrid', harmvisRendgridToStr(rendgrid!));
    }
  }

  /// Copies the `AttHarmVis` members from [other].
  void copyAttHarmVis(covariant AttHarmVis other) {
    rendgrid = other.rendgrid;
  }
}

/// MEI attribute class for `att.HispanTickVis` (mirrors `vrv::AttHispanTickVis`).
mixin AttHispanTickVis {
  /// `place` — data_EVENTREL.
  Eventrel? place;
  bool get hasPlace => place != null;

  /// `tilt` — data_COMPASSDIRECTION.
  Compassdirection? tilt;
  bool get hasTilt => tilt != null;

  /// Mirrors `AttHispanTickVis::ReadHispanTickVis`.
  bool readHispanTickVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final placeRaw = element.get('place');
    if (placeRaw != null) {
      place = strToEventrel(placeRaw);
      if (removeAttr) element.remove('place');
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

  /// Mirrors `AttHispanTickVis::WriteHispanTickVis`.
  void writeHispanTickVis(XmlBuilder element) {
    if (hasPlace) {
      element.attribute('place', eventrelToStr(place!));
    }
    if (hasTilt) {
      element.attribute('tilt', compassdirectionToStr(tilt!));
    }
  }

  /// Copies the `AttHispanTickVis` members from [other].
  void copyAttHispanTickVis(covariant AttHispanTickVis other) {
    place = other.place;
    tilt = other.tilt;
  }
}

/// MEI attribute class for `att.KeySigVis` (mirrors `vrv::AttKeySigVis`).
mixin AttKeySigVis {
  /// `cancelaccid` — data_CANCELACCID.
  Cancelaccid? cancelaccid;
  bool get hasCancelaccid => cancelaccid != null;

  /// Mirrors `AttKeySigVis::ReadKeySigVis`.
  bool readKeySigVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final cancelaccidRaw = element.get('cancelaccid');
    if (cancelaccidRaw != null) {
      cancelaccid = strToCancelaccid(cancelaccidRaw);
      if (removeAttr) element.remove('cancelaccid');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttKeySigVis::WriteKeySigVis`.
  void writeKeySigVis(XmlBuilder element) {
    if (hasCancelaccid) {
      element.attribute('cancelaccid', cancelaccidToStr(cancelaccid!));
    }
  }

  /// Copies the `AttKeySigVis` members from [other].
  void copyAttKeySigVis(covariant AttKeySigVis other) {
    cancelaccid = other.cancelaccid;
  }
}

/// MEI attribute class for `att.KeySigDefaultVis` (mirrors `vrv::AttKeySigDefaultVis`).
mixin AttKeySigDefaultVis {
  /// `keysig.cancelaccid` — data_CANCELACCID.
  Cancelaccid? keysigCancelaccid;
  bool get hasKeysigCancelaccid => keysigCancelaccid != null;

  /// `keysig.visible` — data_BOOLEAN.
  bool? keysigVisible;
  bool get hasKeysigVisible => keysigVisible != null;

  /// Mirrors `AttKeySigDefaultVis::ReadKeySigDefaultVis`.
  bool readKeySigDefaultVis(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final keysigCancelaccidRaw = element.get('keysig.cancelaccid');
    if (keysigCancelaccidRaw != null) {
      keysigCancelaccid = strToCancelaccid(keysigCancelaccidRaw);
      if (removeAttr) element.remove('keysig.cancelaccid');
      hasAttribute = true;
    }
    final keysigVisibleRaw = element.get('keysig.visible');
    if (keysigVisibleRaw != null) {
      keysigVisible = strToBoolean(keysigVisibleRaw);
      if (removeAttr) element.remove('keysig.visible');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttKeySigDefaultVis::WriteKeySigDefaultVis`.
  void writeKeySigDefaultVis(XmlBuilder element) {
    if (hasKeysigCancelaccid) {
      element.attribute(
          'keysig.cancelaccid', cancelaccidToStr(keysigCancelaccid!));
    }
    if (hasKeysigVisible) {
      element.attribute('keysig.visible', booleanToStr(keysigVisible!));
    }
  }

  /// Copies the `AttKeySigDefaultVis` members from [other].
  void copyAttKeySigDefaultVis(covariant AttKeySigDefaultVis other) {
    keysigCancelaccid = other.keysigCancelaccid;
    keysigVisible = other.keysigVisible;
  }
}

/// MEI attribute class for `att.LigatureVis` (mirrors `vrv::AttLigatureVis`).
mixin AttLigatureVis {
  /// `form` — data_LIGATUREFORM.
  Ligatureform? form;
  bool get hasForm => form != null;

  /// Mirrors `AttLigatureVis::ReadLigatureVis`.
  bool readLigatureVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToLigatureform(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLigatureVis::WriteLigatureVis`.
  void writeLigatureVis(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', ligatureformToStr(form!));
    }
  }

  /// Copies the `AttLigatureVis` members from [other].
  void copyAttLigatureVis(covariant AttLigatureVis other) {
    form = other.form;
  }
}

/// MEI attribute class for `att.LineVis` (mirrors `vrv::AttLineVis`).
mixin AttLineVis {
  /// `form` — data_LINEFORM.
  Lineform? form;
  bool get hasForm => form != null;

  /// `width` — data_LINEWIDTH.
  LineWidth? width;
  bool get hasWidth => width != null;

  /// `endsym` — data_LINESTARTENDSYMBOL.
  Linestartendsymbol? endsym;
  bool get hasEndsym => endsym != null;

  /// `endsym.size` — int.
  int? endsymSize;
  bool get hasEndsymSize => endsymSize != null;

  /// `startsym` — data_LINESTARTENDSYMBOL.
  Linestartendsymbol? startsym;
  bool get hasStartsym => startsym != null;

  /// `startsym.size` — int.
  int? startsymSize;
  bool get hasStartsymSize => startsymSize != null;

  /// Mirrors `AttLineVis::ReadLineVis`.
  bool readLineVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToLineform(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    final widthRaw = element.get('width');
    if (widthRaw != null) {
      width = strToLinewidth(widthRaw);
      if (removeAttr) element.remove('width');
      hasAttribute = true;
    }
    final endsymRaw = element.get('endsym');
    if (endsymRaw != null) {
      endsym = strToLinestartendsymbol(endsymRaw);
      if (removeAttr) element.remove('endsym');
      hasAttribute = true;
    }
    final endsymSizeRaw = element.get('endsym.size');
    if (endsymSizeRaw != null) {
      endsymSize = strToInt(endsymSizeRaw);
      if (removeAttr) element.remove('endsym.size');
      hasAttribute = true;
    }
    final startsymRaw = element.get('startsym');
    if (startsymRaw != null) {
      startsym = strToLinestartendsymbol(startsymRaw);
      if (removeAttr) element.remove('startsym');
      hasAttribute = true;
    }
    final startsymSizeRaw = element.get('startsym.size');
    if (startsymSizeRaw != null) {
      startsymSize = strToInt(startsymSizeRaw);
      if (removeAttr) element.remove('startsym.size');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLineVis::WriteLineVis`.
  void writeLineVis(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', lineformToStr(form!));
    }
    if (hasWidth) {
      element.attribute('width', linewidthToStr(width!));
    }
    if (hasEndsym) {
      element.attribute('endsym', linestartendsymbolToStr(endsym!));
    }
    if (hasEndsymSize) {
      element.attribute('endsym.size', intToStr(endsymSize!));
    }
    if (hasStartsym) {
      element.attribute('startsym', linestartendsymbolToStr(startsym!));
    }
    if (hasStartsymSize) {
      element.attribute('startsym.size', intToStr(startsymSize!));
    }
  }

  /// Copies the `AttLineVis` members from [other].
  void copyAttLineVis(covariant AttLineVis other) {
    form = other.form;
    width = other.width;
    endsym = other.endsym;
    endsymSize = other.endsymSize;
    startsym = other.startsym;
    startsymSize = other.startsymSize;
  }
}

/// MEI attribute class for `att.LiquescentVis` (mirrors `vrv::AttLiquescentVis`).
mixin AttLiquescentVis {
  /// `looped` — data_BOOLEAN.
  bool? looped;
  bool get hasLooped => looped != null;

  /// Mirrors `AttLiquescentVis::ReadLiquescentVis`.
  bool readLiquescentVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final loopedRaw = element.get('looped');
    if (loopedRaw != null) {
      looped = strToBoolean(loopedRaw);
      if (removeAttr) element.remove('looped');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttLiquescentVis::WriteLiquescentVis`.
  void writeLiquescentVis(XmlBuilder element) {
    if (hasLooped) {
      element.attribute('looped', booleanToStr(looped!));
    }
  }

  /// Copies the `AttLiquescentVis` members from [other].
  void copyAttLiquescentVis(covariant AttLiquescentVis other) {
    looped = other.looped;
  }
}

/// MEI attribute class for `att.MensurVis` (mirrors `vrv::AttMensurVis`).
mixin AttMensurVis {
  /// `dot` — data_BOOLEAN.
  bool? dot;
  bool get hasDot => dot != null;

  /// `form` — mensurVis_FORM.
  MensurvisForm? form;
  bool get hasForm => form != null;

  /// `orient` — data_ORIENTATION.
  Orientation? orient;
  bool get hasOrient => orient != null;

  /// `sign` — data_MENSURATIONSIGN.
  Mensurationsign? sign;
  bool get hasSign => sign != null;

  /// Mirrors `AttMensurVis::ReadMensurVis`.
  bool readMensurVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final dotRaw = element.get('dot');
    if (dotRaw != null) {
      dot = strToBoolean(dotRaw);
      if (removeAttr) element.remove('dot');
      hasAttribute = true;
    }
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToMensurvisForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    final orientRaw = element.get('orient');
    if (orientRaw != null) {
      orient = strToOrientation(orientRaw);
      if (removeAttr) element.remove('orient');
      hasAttribute = true;
    }
    final signRaw = element.get('sign');
    if (signRaw != null) {
      sign = strToMensurationsign(signRaw);
      if (removeAttr) element.remove('sign');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMensurVis::WriteMensurVis`.
  void writeMensurVis(XmlBuilder element) {
    if (hasDot) {
      element.attribute('dot', booleanToStr(dot!));
    }
    if (hasForm) {
      element.attribute('form', mensurvisFormToStr(form!));
    }
    if (hasOrient) {
      element.attribute('orient', orientationToStr(orient!));
    }
    if (hasSign) {
      element.attribute('sign', mensurationsignToStr(sign!));
    }
  }

  /// Copies the `AttMensurVis` members from [other].
  void copyAttMensurVis(covariant AttMensurVis other) {
    dot = other.dot;
    form = other.form;
    orient = other.orient;
    sign = other.sign;
  }
}

/// MEI attribute class for `att.MensuralVis` (mirrors `vrv::AttMensuralVis`).
mixin AttMensuralVis {
  /// `mensur.color` — std::string.
  String? mensurColor;
  bool get hasMensurColor => mensurColor != null;

  /// `mensur.dot` — data_BOOLEAN.
  bool? mensurDot;
  bool get hasMensurDot => mensurDot != null;

  /// `mensur.form` — mensuralVis_MENSURFORM.
  MensuralvisMensurform? mensurForm;
  bool get hasMensurForm => mensurForm != null;

  /// `mensur.loc` — int.
  int? mensurLoc;
  bool get hasMensurLoc => mensurLoc != null;

  /// `mensur.orient` — data_ORIENTATION.
  Orientation? mensurOrient;
  bool get hasMensurOrient => mensurOrient != null;

  /// `mensur.sign` — data_MENSURATIONSIGN.
  Mensurationsign? mensurSign;
  bool get hasMensurSign => mensurSign != null;

  /// `mensur.size` — data_FONTSIZE.
  FontSize? mensurSize;
  bool get hasMensurSize => mensurSize != null;

  /// `mensur.slash` — char.
  int? mensurSlash;
  bool get hasMensurSlash => mensurSlash != null;

  /// Mirrors `AttMensuralVis::ReadMensuralVis`.
  bool readMensuralVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final mensurColorRaw = element.get('mensur.color');
    if (mensurColorRaw != null) {
      mensurColor = identityStr(mensurColorRaw);
      if (removeAttr) element.remove('mensur.color');
      hasAttribute = true;
    }
    final mensurDotRaw = element.get('mensur.dot');
    if (mensurDotRaw != null) {
      mensurDot = strToBoolean(mensurDotRaw);
      if (removeAttr) element.remove('mensur.dot');
      hasAttribute = true;
    }
    final mensurFormRaw = element.get('mensur.form');
    if (mensurFormRaw != null) {
      mensurForm = strToMensuralvisMensurform(mensurFormRaw);
      if (removeAttr) element.remove('mensur.form');
      hasAttribute = true;
    }
    final mensurLocRaw = element.get('mensur.loc');
    if (mensurLocRaw != null) {
      mensurLoc = strToInt(mensurLocRaw);
      if (removeAttr) element.remove('mensur.loc');
      hasAttribute = true;
    }
    final mensurOrientRaw = element.get('mensur.orient');
    if (mensurOrientRaw != null) {
      mensurOrient = strToOrientation(mensurOrientRaw);
      if (removeAttr) element.remove('mensur.orient');
      hasAttribute = true;
    }
    final mensurSignRaw = element.get('mensur.sign');
    if (mensurSignRaw != null) {
      mensurSign = strToMensurationsign(mensurSignRaw);
      if (removeAttr) element.remove('mensur.sign');
      hasAttribute = true;
    }
    final mensurSizeRaw = element.get('mensur.size');
    if (mensurSizeRaw != null) {
      mensurSize = strToFontsize(mensurSizeRaw);
      if (removeAttr) element.remove('mensur.size');
      hasAttribute = true;
    }
    final mensurSlashRaw = element.get('mensur.slash');
    if (mensurSlashRaw != null) {
      mensurSlash = strToInt(mensurSlashRaw);
      if (removeAttr) element.remove('mensur.slash');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMensuralVis::WriteMensuralVis`.
  void writeMensuralVis(XmlBuilder element) {
    if (hasMensurColor) {
      element.attribute('mensur.color', identityStr(mensurColor!));
    }
    if (hasMensurDot) {
      element.attribute('mensur.dot', booleanToStr(mensurDot!));
    }
    if (hasMensurForm) {
      element.attribute('mensur.form', mensuralvisMensurformToStr(mensurForm!));
    }
    if (hasMensurLoc) {
      element.attribute('mensur.loc', intToStr(mensurLoc!));
    }
    if (hasMensurOrient) {
      element.attribute('mensur.orient', orientationToStr(mensurOrient!));
    }
    if (hasMensurSign) {
      element.attribute('mensur.sign', mensurationsignToStr(mensurSign!));
    }
    if (hasMensurSize) {
      element.attribute('mensur.size', fontsizeToStr(mensurSize!));
    }
    if (hasMensurSlash) {
      element.attribute('mensur.slash', intToStr(mensurSlash!));
    }
  }

  /// Copies the `AttMensuralVis` members from [other].
  void copyAttMensuralVis(covariant AttMensuralVis other) {
    mensurColor = other.mensurColor;
    mensurDot = other.mensurDot;
    mensurForm = other.mensurForm;
    mensurLoc = other.mensurLoc;
    mensurOrient = other.mensurOrient;
    mensurSign = other.mensurSign;
    mensurSize = other.mensurSize;
    mensurSlash = other.mensurSlash;
  }
}

/// MEI attribute class for `att.MeterSigVis` (mirrors `vrv::AttMeterSigVis`).
mixin AttMeterSigVis {
  /// `form` — data_METERFORM.
  Meterform? form;
  bool get hasForm => form != null;

  /// Mirrors `AttMeterSigVis::ReadMeterSigVis`.
  bool readMeterSigVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToMeterform(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeterSigVis::WriteMeterSigVis`.
  void writeMeterSigVis(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', meterformToStr(form!));
    }
  }

  /// Copies the `AttMeterSigVis` members from [other].
  void copyAttMeterSigVis(covariant AttMeterSigVis other) {
    form = other.form;
  }
}

/// MEI attribute class for `att.MeterSigDefaultVis` (mirrors `vrv::AttMeterSigDefaultVis`).
mixin AttMeterSigDefaultVis {
  /// `meter.form` — data_METERFORM.
  Meterform? meterForm;
  bool get hasMeterForm => meterForm != null;

  /// `meter.showchange` — data_BOOLEAN.
  bool? meterShowchange;
  bool get hasMeterShowchange => meterShowchange != null;

  /// `meter.visible` — data_BOOLEAN.
  bool? meterVisible;
  bool get hasMeterVisible => meterVisible != null;

  /// Mirrors `AttMeterSigDefaultVis::ReadMeterSigDefaultVis`.
  bool readMeterSigDefaultVis(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final meterFormRaw = element.get('meter.form');
    if (meterFormRaw != null) {
      meterForm = strToMeterform(meterFormRaw);
      if (removeAttr) element.remove('meter.form');
      hasAttribute = true;
    }
    final meterShowchangeRaw = element.get('meter.showchange');
    if (meterShowchangeRaw != null) {
      meterShowchange = strToBoolean(meterShowchangeRaw);
      if (removeAttr) element.remove('meter.showchange');
      hasAttribute = true;
    }
    final meterVisibleRaw = element.get('meter.visible');
    if (meterVisibleRaw != null) {
      meterVisible = strToBoolean(meterVisibleRaw);
      if (removeAttr) element.remove('meter.visible');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMeterSigDefaultVis::WriteMeterSigDefaultVis`.
  void writeMeterSigDefaultVis(XmlBuilder element) {
    if (hasMeterForm) {
      element.attribute('meter.form', meterformToStr(meterForm!));
    }
    if (hasMeterShowchange) {
      element.attribute('meter.showchange', booleanToStr(meterShowchange!));
    }
    if (hasMeterVisible) {
      element.attribute('meter.visible', booleanToStr(meterVisible!));
    }
  }

  /// Copies the `AttMeterSigDefaultVis` members from [other].
  void copyAttMeterSigDefaultVis(covariant AttMeterSigDefaultVis other) {
    meterForm = other.meterForm;
    meterShowchange = other.meterShowchange;
    meterVisible = other.meterVisible;
  }
}

/// MEI attribute class for `att.MultiRestVis` (mirrors `vrv::AttMultiRestVis`).
mixin AttMultiRestVis {
  /// `block` — data_BOOLEAN.
  bool? block;
  bool get hasBlock => block != null;

  /// Mirrors `AttMultiRestVis::ReadMultiRestVis`.
  bool readMultiRestVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final blockRaw = element.get('block');
    if (blockRaw != null) {
      block = strToBoolean(blockRaw);
      if (removeAttr) element.remove('block');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMultiRestVis::WriteMultiRestVis`.
  void writeMultiRestVis(XmlBuilder element) {
    if (hasBlock) {
      element.attribute('block', booleanToStr(block!));
    }
  }

  /// Copies the `AttMultiRestVis` members from [other].
  void copyAttMultiRestVis(covariant AttMultiRestVis other) {
    block = other.block;
  }
}

/// MEI attribute class for `att.PbVis` (mirrors `vrv::AttPbVis`).
mixin AttPbVis {
  /// `folium` — pbVis_FOLIUM.
  PbvisFolium? folium;
  bool get hasFolium => folium != null;

  /// Mirrors `AttPbVis::ReadPbVis`.
  bool readPbVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final foliumRaw = element.get('folium');
    if (foliumRaw != null) {
      folium = strToPbvisFolium(foliumRaw);
      if (removeAttr) element.remove('folium');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPbVis::WritePbVis`.
  void writePbVis(XmlBuilder element) {
    if (hasFolium) {
      element.attribute('folium', pbvisFoliumToStr(folium!));
    }
  }

  /// Copies the `AttPbVis` members from [other].
  void copyAttPbVis(covariant AttPbVis other) {
    folium = other.folium;
  }
}

/// MEI attribute class for `att.PedalVis` (mirrors `vrv::AttPedalVis`).
mixin AttPedalVis {
  /// `form` — data_PEDALSTYLE.
  Pedalstyle? form;
  bool get hasForm => form != null;

  /// Mirrors `AttPedalVis::ReadPedalVis`.
  bool readPedalVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToPedalstyle(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPedalVis::WritePedalVis`.
  void writePedalVis(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', pedalstyleToStr(form!));
    }
  }

  /// Copies the `AttPedalVis` members from [other].
  void copyAttPedalVis(covariant AttPedalVis other) {
    form = other.form;
  }
}

/// MEI attribute class for `att.PlicaVis` (mirrors `vrv::AttPlicaVis`).
mixin AttPlicaVis {
  /// `dir` — data_STEMDIRECTION_basic.
  StemdirectionBasic? dir;
  bool get hasDir => dir != null;

  /// `len` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? len;
  bool get hasLen => len != null;

  /// Mirrors `AttPlicaVis::ReadPlicaVis`.
  bool readPlicaVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final dirRaw = element.get('dir');
    if (dirRaw != null) {
      dir = strToStemdirectionBasic(dirRaw);
      if (removeAttr) element.remove('dir');
      hasAttribute = true;
    }
    final lenRaw = element.get('len');
    if (lenRaw != null) {
      len = strToMeasurementunsigned(lenRaw);
      if (removeAttr) element.remove('len');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPlicaVis::WritePlicaVis`.
  void writePlicaVis(XmlBuilder element) {
    if (hasDir) {
      element.attribute('dir', stemdirectionBasicToStr(dir!));
    }
    if (hasLen) {
      element.attribute('len', measurementunsignedToStr(len!));
    }
  }

  /// Copies the `AttPlicaVis` members from [other].
  void copyAttPlicaVis(covariant AttPlicaVis other) {
    dir = other.dir;
    len = other.len;
  }
}

/// MEI attribute class for `att.QuilismaVis` (mirrors `vrv::AttQuilismaVis`).
mixin AttQuilismaVis {
  /// `waves` — int.
  int? waves;
  bool get hasWaves => waves != null;

  /// Mirrors `AttQuilismaVis::ReadQuilismaVis`.
  bool readQuilismaVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final wavesRaw = element.get('waves');
    if (wavesRaw != null) {
      waves = strToInt(wavesRaw);
      if (removeAttr) element.remove('waves');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttQuilismaVis::WriteQuilismaVis`.
  void writeQuilismaVis(XmlBuilder element) {
    if (hasWaves) {
      element.attribute('waves', intToStr(waves!));
    }
  }

  /// Copies the `AttQuilismaVis` members from [other].
  void copyAttQuilismaVis(covariant AttQuilismaVis other) {
    waves = other.waves;
  }
}

/// MEI attribute class for `att.SbVis` (mirrors `vrv::AttSbVis`).
mixin AttSbVis {
  /// `form` — sbVis_FORM.
  SbvisForm? form;
  bool get hasForm => form != null;

  /// Mirrors `AttSbVis::ReadSbVis`.
  bool readSbVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToSbvisForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSbVis::WriteSbVis`.
  void writeSbVis(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', sbvisFormToStr(form!));
    }
  }

  /// Copies the `AttSbVis` members from [other].
  void copyAttSbVis(covariant AttSbVis other) {
    form = other.form;
  }
}

/// MEI attribute class for `att.ScoreDefVis` (mirrors `vrv::AttScoreDefVis`).
mixin AttScoreDefVis {
  /// `vu.height` — std::string.
  String? vuHeight;
  bool get hasVuHeight => vuHeight != null;

  /// Mirrors `AttScoreDefVis::ReadScoreDefVis`.
  bool readScoreDefVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final vuHeightRaw = element.get('vu.height');
    if (vuHeightRaw != null) {
      vuHeight = identityStr(vuHeightRaw);
      if (removeAttr) element.remove('vu.height');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttScoreDefVis::WriteScoreDefVis`.
  void writeScoreDefVis(XmlBuilder element) {
    if (hasVuHeight) {
      element.attribute('vu.height', identityStr(vuHeight!));
    }
  }

  /// Copies the `AttScoreDefVis` members from [other].
  void copyAttScoreDefVis(covariant AttScoreDefVis other) {
    vuHeight = other.vuHeight;
  }
}

/// MEI attribute class for `att.SectionVis` (mirrors `vrv::AttSectionVis`).
mixin AttSectionVis {
  /// `restart` — data_BOOLEAN.
  bool? restart;
  bool get hasRestart => restart != null;

  /// Mirrors `AttSectionVis::ReadSectionVis`.
  bool readSectionVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final restartRaw = element.get('restart');
    if (restartRaw != null) {
      restart = strToBoolean(restartRaw);
      if (removeAttr) element.remove('restart');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSectionVis::WriteSectionVis`.
  void writeSectionVis(XmlBuilder element) {
    if (hasRestart) {
      element.attribute('restart', booleanToStr(restart!));
    }
  }

  /// Copies the `AttSectionVis` members from [other].
  void copyAttSectionVis(covariant AttSectionVis other) {
    restart = other.restart;
  }
}

/// MEI attribute class for `att.SignifLetVis` (mirrors `vrv::AttSignifLetVis`).
mixin AttSignifLetVis {
  /// `place` — data_EVENTREL.
  Eventrel? place;
  bool get hasPlace => place != null;

  /// Mirrors `AttSignifLetVis::ReadSignifLetVis`.
  bool readSignifLetVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final placeRaw = element.get('place');
    if (placeRaw != null) {
      place = strToEventrel(placeRaw);
      if (removeAttr) element.remove('place');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSignifLetVis::WriteSignifLetVis`.
  void writeSignifLetVis(XmlBuilder element) {
    if (hasPlace) {
      element.attribute('place', eventrelToStr(place!));
    }
  }

  /// Copies the `AttSignifLetVis` members from [other].
  void copyAttSignifLetVis(covariant AttSignifLetVis other) {
    place = other.place;
  }
}

/// MEI attribute class for `att.SpaceVis` (mirrors `vrv::AttSpaceVis`).
mixin AttSpaceVis {
  /// `compressable` — data_BOOLEAN.
  bool? compressable;
  bool get hasCompressable => compressable != null;

  /// Mirrors `AttSpaceVis::ReadSpaceVis`.
  bool readSpaceVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final compressableRaw = element.get('compressable');
    if (compressableRaw != null) {
      compressable = strToBoolean(compressableRaw);
      if (removeAttr) element.remove('compressable');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSpaceVis::WriteSpaceVis`.
  void writeSpaceVis(XmlBuilder element) {
    if (hasCompressable) {
      element.attribute('compressable', booleanToStr(compressable!));
    }
  }

  /// Copies the `AttSpaceVis` members from [other].
  void copyAttSpaceVis(covariant AttSpaceVis other) {
    compressable = other.compressable;
  }
}

/// MEI attribute class for `att.StaffDefVis` (mirrors `vrv::AttStaffDefVis`).
mixin AttStaffDefVis {
  /// `layerscheme` — data_LAYERSCHEME.
  Layerscheme? layerscheme;
  bool get hasLayerscheme => layerscheme != null;

  /// `lines.color` — std::string.
  String? linesColor;
  bool get hasLinesColor => linesColor != null;

  /// `lines.visible` — data_BOOLEAN.
  bool? linesVisible;
  bool get hasLinesVisible => linesVisible != null;

  /// `spacing` — data_MEASUREMENTSIGNED.
  MeasurementSigned? spacing;
  bool get hasSpacing => spacing != null;

  /// Mirrors `AttStaffDefVis::ReadStaffDefVis`.
  bool readStaffDefVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final layerschemeRaw = element.get('layerscheme');
    if (layerschemeRaw != null) {
      layerscheme = strToLayerscheme(layerschemeRaw);
      if (removeAttr) element.remove('layerscheme');
      hasAttribute = true;
    }
    final linesColorRaw = element.get('lines.color');
    if (linesColorRaw != null) {
      linesColor = identityStr(linesColorRaw);
      if (removeAttr) element.remove('lines.color');
      hasAttribute = true;
    }
    final linesVisibleRaw = element.get('lines.visible');
    if (linesVisibleRaw != null) {
      linesVisible = strToBoolean(linesVisibleRaw);
      if (removeAttr) element.remove('lines.visible');
      hasAttribute = true;
    }
    final spacingRaw = element.get('spacing');
    if (spacingRaw != null) {
      spacing = strToMeasurementsigned(spacingRaw);
      if (removeAttr) element.remove('spacing');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffDefVis::WriteStaffDefVis`.
  void writeStaffDefVis(XmlBuilder element) {
    if (hasLayerscheme) {
      element.attribute('layerscheme', layerschemeToStr(layerscheme!));
    }
    if (hasLinesColor) {
      element.attribute('lines.color', identityStr(linesColor!));
    }
    if (hasLinesVisible) {
      element.attribute('lines.visible', booleanToStr(linesVisible!));
    }
    if (hasSpacing) {
      element.attribute('spacing', measurementsignedToStr(spacing!));
    }
  }

  /// Copies the `AttStaffDefVis` members from [other].
  void copyAttStaffDefVis(covariant AttStaffDefVis other) {
    layerscheme = other.layerscheme;
    linesColor = other.linesColor;
    linesVisible = other.linesVisible;
    spacing = other.spacing;
  }
}

/// MEI attribute class for `att.StaffGrpVis` (mirrors `vrv::AttStaffGrpVis`).
mixin AttStaffGrpVis {
  /// `bar.thru` — data_BOOLEAN.
  bool? barThru;
  bool get hasBarThru => barThru != null;

  /// Mirrors `AttStaffGrpVis::ReadStaffGrpVis`.
  bool readStaffGrpVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final barThruRaw = element.get('bar.thru');
    if (barThruRaw != null) {
      barThru = strToBoolean(barThruRaw);
      if (removeAttr) element.remove('bar.thru');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStaffGrpVis::WriteStaffGrpVis`.
  void writeStaffGrpVis(XmlBuilder element) {
    if (hasBarThru) {
      element.attribute('bar.thru', booleanToStr(barThru!));
    }
  }

  /// Copies the `AttStaffGrpVis` members from [other].
  void copyAttStaffGrpVis(covariant AttStaffGrpVis other) {
    barThru = other.barThru;
  }
}

/// MEI attribute class for `att.StemVis` (mirrors `vrv::AttStemVis`).
mixin AttStemVis {
  /// `pos` — data_STEMPOSITION.
  Stemposition? pos;
  bool get hasPos => pos != null;

  /// `len` — data_MEASUREMENTUNSIGNED.
  MeasurementUnsigned? len;
  bool get hasLen => len != null;

  /// `form` — data_STEMFORM_mensural.
  StemformMensural? form;
  bool get hasForm => form != null;

  /// `dir` — data_STEMDIRECTION.
  Stemdirection? dir;
  bool get hasDir => dir != null;

  /// `flag.pos` — data_FLAGPOS_mensural.
  FlagposMensural? flagPos;
  bool get hasFlagPos => flagPos != null;

  /// `flag.form` — data_FLAGFORM_mensural.
  FlagformMensural? flagForm;
  bool get hasFlagForm => flagForm != null;

  /// Mirrors `AttStemVis::ReadStemVis`.
  bool readStemVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final posRaw = element.get('pos');
    if (posRaw != null) {
      pos = strToStemposition(posRaw);
      if (removeAttr) element.remove('pos');
      hasAttribute = true;
    }
    final lenRaw = element.get('len');
    if (lenRaw != null) {
      len = strToMeasurementunsigned(lenRaw);
      if (removeAttr) element.remove('len');
      hasAttribute = true;
    }
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToStemformMensural(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    final dirRaw = element.get('dir');
    if (dirRaw != null) {
      dir = strToStemdirection(dirRaw);
      if (removeAttr) element.remove('dir');
      hasAttribute = true;
    }
    final flagPosRaw = element.get('flag.pos');
    if (flagPosRaw != null) {
      flagPos = strToFlagposMensural(flagPosRaw);
      if (removeAttr) element.remove('flag.pos');
      hasAttribute = true;
    }
    final flagFormRaw = element.get('flag.form');
    if (flagFormRaw != null) {
      flagForm = strToFlagformMensural(flagFormRaw);
      if (removeAttr) element.remove('flag.form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStemVis::WriteStemVis`.
  void writeStemVis(XmlBuilder element) {
    if (hasPos) {
      element.attribute('pos', stempositionToStr(pos!));
    }
    if (hasLen) {
      element.attribute('len', measurementunsignedToStr(len!));
    }
    if (hasForm) {
      element.attribute('form', stemformMensuralToStr(form!));
    }
    if (hasDir) {
      element.attribute('dir', stemdirectionToStr(dir!));
    }
    if (hasFlagPos) {
      element.attribute('flag.pos', flagposMensuralToStr(flagPos!));
    }
    if (hasFlagForm) {
      element.attribute('flag.form', flagformMensuralToStr(flagForm!));
    }
  }

  /// Copies the `AttStemVis` members from [other].
  void copyAttStemVis(covariant AttStemVis other) {
    pos = other.pos;
    len = other.len;
    form = other.form;
    dir = other.dir;
    flagPos = other.flagPos;
    flagForm = other.flagForm;
  }
}

/// MEI attribute class for `att.TupletVis` (mirrors `vrv::AttTupletVis`).
mixin AttTupletVis {
  /// `bracket.place` — data_STAFFREL_basic.
  StaffrelBasic? bracketPlace;
  bool get hasBracketPlace => bracketPlace != null;

  /// `bracket.visible` — data_BOOLEAN.
  bool? bracketVisible;
  bool get hasBracketVisible => bracketVisible != null;

  /// `num.format` — tupletVis_NUMFORMAT.
  TupletvisNumformat? numFormat;
  bool get hasNumFormat => numFormat != null;

  /// Mirrors `AttTupletVis::ReadTupletVis`.
  bool readTupletVis(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final bracketPlaceRaw = element.get('bracket.place');
    if (bracketPlaceRaw != null) {
      bracketPlace = strToStaffrelBasic(bracketPlaceRaw);
      if (removeAttr) element.remove('bracket.place');
      hasAttribute = true;
    }
    final bracketVisibleRaw = element.get('bracket.visible');
    if (bracketVisibleRaw != null) {
      bracketVisible = strToBoolean(bracketVisibleRaw);
      if (removeAttr) element.remove('bracket.visible');
      hasAttribute = true;
    }
    final numFormatRaw = element.get('num.format');
    if (numFormatRaw != null) {
      numFormat = strToTupletvisNumformat(numFormatRaw);
      if (removeAttr) element.remove('num.format');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTupletVis::WriteTupletVis`.
  void writeTupletVis(XmlBuilder element) {
    if (hasBracketPlace) {
      element.attribute('bracket.place', staffrelBasicToStr(bracketPlace!));
    }
    if (hasBracketVisible) {
      element.attribute('bracket.visible', booleanToStr(bracketVisible!));
    }
    if (hasNumFormat) {
      element.attribute('num.format', tupletvisNumformatToStr(numFormat!));
    }
  }

  /// Copies the `AttTupletVis` members from [other].
  void copyAttTupletVis(covariant AttTupletVis other) {
    bracketPlace = other.bracketPlace;
    bracketVisible = other.bracketVisible;
    numFormat = other.numFormat;
  }
}
