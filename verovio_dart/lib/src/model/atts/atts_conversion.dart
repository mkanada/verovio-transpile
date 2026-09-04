// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/attconverter.cpp + addons/att.cpp
library;

import '../../core/logging.dart';
import 'mei_enums.dart';

const String _unknownValue = "";

/// `accidLog_FUNC` -> string.
String accidlogFuncToStr(AccidlogFunc data) {
  switch (data.value) {
    case 1:
      return 'caution';
    case 2:
      return 'edit';
  }
  logWarning("Unknown value '${data.value}' for accidLog_FUNC");
  return _unknownValue;
}

/// string -> `accidLog_FUNC`.
AccidlogFunc strToAccidlogFunc(String value) {
  if (value == 'caution') return AccidlogFunc.caution;
  if (value == 'edit') return AccidlogFunc.edit;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for accidLog_FUNC");
  }
  return AccidlogFunc.none;
}

/// `anchoredTextLog_FUNC` -> string.
String anchoredtextlogFuncToStr(AnchoredtextlogFunc data) {
  switch (data.value) {
    case 1:
      return 'unknown';
  }
  logWarning("Unknown value '${data.value}' for anchoredTextLog_FUNC");
  return _unknownValue;
}

/// string -> `anchoredTextLog_FUNC`.
AnchoredtextlogFunc strToAnchoredtextlogFunc(String value) {
  if (value == 'unknown') return AnchoredtextlogFunc.unknown;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for anchoredTextLog_FUNC");
  }
  return AnchoredtextlogFunc.none;
}

/// `annotLog_FUNC` -> string.
String annotlogFuncToStr(AnnotlogFunc data) {
  switch (data.value) {
    case 1:
      return 'display';
  }
  logWarning("Unknown value '${data.value}' for annotLog_FUNC");
  return _unknownValue;
}

/// string -> `annotLog_FUNC`.
AnnotlogFunc strToAnnotlogFunc(String value) {
  if (value == 'display') return AnnotlogFunc.display;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for annotLog_FUNC");
  }
  return AnnotlogFunc.none;
}

/// `arpegLog_ORDER` -> string.
String arpeglogOrderToStr(ArpeglogOrder data) {
  switch (data.value) {
    case 1:
      return 'up';
    case 2:
      return 'down';
    case 3:
      return 'nonarp';
  }
  logWarning("Unknown value '${data.value}' for arpegLog_ORDER");
  return _unknownValue;
}

/// string -> `arpegLog_ORDER`.
ArpeglogOrder strToArpeglogOrder(String value) {
  if (value == 'up') return ArpeglogOrder.up;
  if (value == 'down') return ArpeglogOrder.down;
  if (value == 'nonarp') return ArpeglogOrder.nonarp;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for arpegLog_ORDER");
  }
  return ArpeglogOrder.none;
}

/// `audience_AUDIENCE` -> string.
String audienceAudienceToStr(AudienceAudience data) {
  switch (data.value) {
    case 1:
      return 'private';
    case 2:
      return 'public';
  }
  logWarning("Unknown value '${data.value}' for audience_AUDIENCE");
  return _unknownValue;
}

/// string -> `audience_AUDIENCE`.
AudienceAudience strToAudienceAudience(String value) {
  if (value == 'private') return AudienceAudience.private;
  if (value == 'public') return AudienceAudience.public;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for audience_AUDIENCE");
  }
  return AudienceAudience.none;
}

/// `beamRend_FORM` -> string.
String beamrendFormToStr(BeamrendForm data) {
  switch (data.value) {
    case 1:
      return 'acc';
    case 2:
      return 'mixed';
    case 3:
      return 'rit';
    case 4:
      return 'norm';
  }
  logWarning("Unknown value '${data.value}' for beamRend_FORM");
  return _unknownValue;
}

/// string -> `beamRend_FORM`.
BeamrendForm strToBeamrendForm(String value) {
  if (value == 'acc') return BeamrendForm.acc;
  if (value == 'mixed') return BeamrendForm.mixed;
  if (value == 'rit') return BeamrendForm.rit;
  if (value == 'norm') return BeamrendForm.norm;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for beamRend_FORM");
  }
  return BeamrendForm.none;
}

/// `beamingVis_BEAMREND` -> string.
String beamingvisBeamrendToStr(BeamingvisBeamrend data) {
  switch (data.value) {
    case 1:
      return 'acc';
    case 2:
      return 'rit';
    case 3:
      return 'norm';
  }
  logWarning("Unknown value '${data.value}' for beamingVis_BEAMREND");
  return _unknownValue;
}

/// string -> `beamingVis_BEAMREND`.
BeamingvisBeamrend strToBeamingvisBeamrend(String value) {
  if (value == 'acc') return BeamingvisBeamrend.acc;
  if (value == 'rit') return BeamingvisBeamrend.rit;
  if (value == 'norm') return BeamingvisBeamrend.norm;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for beamingVis_BEAMREND");
  }
  return BeamingvisBeamrend.none;
}

/// `bracketSpanLog_FUNC` -> string.
String bracketspanlogFuncToStr(BracketspanlogFunc data) {
  switch (data.value) {
    case 1:
      return 'coloration';
    case 2:
      return 'cross-rhythm';
    case 3:
      return 'ligature';
    case 4:
      return 'analytical';
    case 5:
      return 'phrase';
    case 6:
      return 'uspecified';
  }
  logWarning("Unknown value '${data.value}' for bracketSpanLog_FUNC");
  return _unknownValue;
}

/// string -> `bracketSpanLog_FUNC`.
BracketspanlogFunc strToBracketspanlogFunc(String value) {
  if (value == 'coloration') return BracketspanlogFunc.coloration;
  if (value == 'cross-rhythm') return BracketspanlogFunc.crossRhythm;
  if (value == 'ligature') return BracketspanlogFunc.ligature;
  if (value == 'analytical') return BracketspanlogFunc.analytical;
  if (value == 'phrase') return BracketspanlogFunc.phrase;
  if (value == 'uspecified') return BracketspanlogFunc.uspecified;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for bracketSpanLog_FUNC");
  }
  return BracketspanlogFunc.none;
}

/// `curvatureDirection_CURVE` -> string.
String curvaturedirectionCurveToStr(CurvaturedirectionCurve data) {
  switch (data.value) {
    case 1:
      return 'a';
    case 2:
      return 'c';
  }
  logWarning("Unknown value '${data.value}' for curvatureDirection_CURVE");
  return _unknownValue;
}

/// string -> `curvatureDirection_CURVE`.
CurvaturedirectionCurve strToCurvaturedirectionCurve(String value) {
  if (value == 'a') return CurvaturedirectionCurve.a;
  if (value == 'c') return CurvaturedirectionCurve.c;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for curvatureDirection_CURVE");
  }
  return CurvaturedirectionCurve.none;
}

/// `curvature_CURVEDIR` -> string.
String curvatureCurvedirToStr(CurvatureCurvedir data) {
  switch (data.value) {
    case 1:
      return 'above';
    case 2:
      return 'below';
    case 3:
      return 'mixed';
  }
  logWarning("Unknown value '${data.value}' for curvature_CURVEDIR");
  return _unknownValue;
}

/// string -> `curvature_CURVEDIR`.
CurvatureCurvedir strToCurvatureCurvedir(String value) {
  if (value == 'above') return CurvatureCurvedir.above;
  if (value == 'below') return CurvatureCurvedir.below;
  if (value == 'mixed') return CurvatureCurvedir.mixed;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for curvature_CURVEDIR");
  }
  return CurvatureCurvedir.none;
}

/// `curveLog_FUNC` -> string.
String curvelogFuncToStr(CurvelogFunc data) {
  switch (data.value) {
    case 1:
      return 'unknown';
  }
  logWarning("Unknown value '${data.value}' for curveLog_FUNC");
  return _unknownValue;
}

/// string -> `curveLog_FUNC`.
CurvelogFunc strToCurvelogFunc(String value) {
  if (value == 'unknown') return CurvelogFunc.unknown;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for curveLog_FUNC");
  }
  return CurvelogFunc.none;
}

/// `cutout_CUTOUT` -> string.
String cutoutCutoutToStr(CutoutCutout data) {
  switch (data.value) {
    case 1:
      return 'cutout';
  }
  logWarning("Unknown value '${data.value}' for cutout_CUTOUT");
  return _unknownValue;
}

/// string -> `cutout_CUTOUT`.
CutoutCutout strToCutoutCutout(String value) {
  if (value == 'cutout') return CutoutCutout.cutout;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for cutout_CUTOUT");
  }
  return CutoutCutout.none;
}

/// `data_ACCIDENTAL_GESTURAL` -> string.
String accidentalGesturalToStr(AccidentalGestural data) {
  switch (data.value) {
    case 1:
      return 's';
    case 2:
      return 'f';
    case 3:
      return 'ss';
    case 4:
      return 'ff';
    case 5:
      return 'ts';
    case 6:
      return 'tf';
    case 7:
      return 'n';
    case 8:
      return 'su';
    case 9:
      return 'sd';
    case 10:
      return 'fu';
    case 11:
      return 'fd';
    case 12:
      return 'xu';
    case 13:
      return 'ffd';
    case 14:
      return 'bms';
    case 15:
      return 'kms';
    case 16:
      return 'bs';
    case 17:
      return 'ks';
    case 18:
      return 'kf';
    case 19:
      return 'bf';
    case 20:
      return 'kmf';
    case 21:
      return 'bmf';
    case 22:
      return 'koron';
    case 23:
      return 'sori';
  }
  logWarning("Unknown value '${data.value}' for data_ACCIDENTAL_GESTURAL");
  return _unknownValue;
}

/// string -> `data_ACCIDENTAL_GESTURAL`.
AccidentalGestural strToAccidentalGestural(String value) {
  if (value == 's') return AccidentalGestural.s;
  if (value == 'f') return AccidentalGestural.f;
  if (value == 'ss') return AccidentalGestural.ss;
  if (value == 'ff') return AccidentalGestural.ff;
  if (value == 'ts') return AccidentalGestural.ts;
  if (value == 'tf') return AccidentalGestural.tf;
  if (value == 'n') return AccidentalGestural.n;
  if (value == 'su') return AccidentalGestural.su;
  if (value == 'sd') return AccidentalGestural.sd;
  if (value == 'fu') return AccidentalGestural.fu;
  if (value == 'fd') return AccidentalGestural.fd;
  if (value == 'xu') return AccidentalGestural.xu;
  if (value == 'ffd') return AccidentalGestural.ffd;
  if (value == 'bms') return AccidentalGestural.bms;
  if (value == 'kms') return AccidentalGestural.kms;
  if (value == 'bs') return AccidentalGestural.bs;
  if (value == 'ks') return AccidentalGestural.ks;
  if (value == 'kf') return AccidentalGestural.kf;
  if (value == 'bf') return AccidentalGestural.bf;
  if (value == 'kmf') return AccidentalGestural.kmf;
  if (value == 'bmf') return AccidentalGestural.bmf;
  if (value == 'koron') return AccidentalGestural.koron;
  if (value == 'sori') return AccidentalGestural.sori;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ACCIDENTAL_GESTURAL");
  }
  return AccidentalGestural.none;
}

/// `data_ACCIDENTAL_GESTURAL_basic` -> string.
String accidentalGesturalBasicToStr(AccidentalGesturalBasic data) {
  switch (data.value) {
    case 1:
      return 's';
    case 2:
      return 'f';
    case 3:
      return 'ss';
    case 4:
      return 'ff';
    case 5:
      return 'ts';
    case 6:
      return 'tf';
    case 7:
      return 'n';
  }
  logWarning(
      "Unknown value '${data.value}' for data_ACCIDENTAL_GESTURAL_basic");
  return _unknownValue;
}

/// string -> `data_ACCIDENTAL_GESTURAL_basic`.
AccidentalGesturalBasic strToAccidentalGesturalBasic(String value) {
  if (value == 's') return AccidentalGesturalBasic.s;
  if (value == 'f') return AccidentalGesturalBasic.f;
  if (value == 'ss') return AccidentalGesturalBasic.ss;
  if (value == 'ff') return AccidentalGesturalBasic.ff;
  if (value == 'ts') return AccidentalGesturalBasic.ts;
  if (value == 'tf') return AccidentalGesturalBasic.tf;
  if (value == 'n') return AccidentalGesturalBasic.n;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ACCIDENTAL_GESTURAL_basic");
  }
  return AccidentalGesturalBasic.none;
}

/// `data_ACCIDENTAL_GESTURAL_extended` -> string.
String accidentalGesturalExtendedToStr(AccidentalGesturalExtended data) {
  switch (data.value) {
    case 1:
      return 'su';
    case 2:
      return 'sd';
    case 3:
      return 'fu';
    case 4:
      return 'fd';
    case 5:
      return 'xu';
    case 6:
      return 'ffd';
  }
  logWarning(
      "Unknown value '${data.value}' for data_ACCIDENTAL_GESTURAL_extended");
  return _unknownValue;
}

/// string -> `data_ACCIDENTAL_GESTURAL_extended`.
AccidentalGesturalExtended strToAccidentalGesturalExtended(String value) {
  if (value == 'su') return AccidentalGesturalExtended.su;
  if (value == 'sd') return AccidentalGesturalExtended.sd;
  if (value == 'fu') return AccidentalGesturalExtended.fu;
  if (value == 'fd') return AccidentalGesturalExtended.fd;
  if (value == 'xu') return AccidentalGesturalExtended.xu;
  if (value == 'ffd') return AccidentalGesturalExtended.ffd;
  if (value.isNotEmpty) {
    logWarning(
        "Unsupported value '$value' for data_ACCIDENTAL_GESTURAL_extended");
  }
  return AccidentalGesturalExtended.none;
}

/// `data_ACCIDENTAL_WRITTEN` -> string.
String accidentalWrittenToStr(AccidentalWritten data) {
  switch (data.value) {
    case 1:
      return 's';
    case 2:
      return 'f';
    case 3:
      return 'ss';
    case 4:
      return 'x';
    case 5:
      return 'ff';
    case 6:
      return 'xs';
    case 7:
      return 'sx';
    case 8:
      return 'ts';
    case 9:
      return 'tf';
    case 10:
      return 'n';
    case 11:
      return 'nf';
    case 12:
      return 'ns';
    case 13:
      return 'su';
    case 14:
      return 'sd';
    case 15:
      return 'fu';
    case 16:
      return 'fd';
    case 17:
      return 'nu';
    case 18:
      return 'nd';
    case 19:
      return 'xu';
    case 20:
      return 'xd';
    case 21:
      return 'ffu';
    case 22:
      return 'ffd';
    case 23:
      return '1qf';
    case 24:
      return '3qf';
    case 25:
      return '1qs';
    case 26:
      return '3qs';
    case 27:
      return 'bms';
    case 28:
      return 'kms';
    case 29:
      return 'bs';
    case 30:
      return 'ks';
    case 31:
      return 'kf';
    case 32:
      return 'bf';
    case 33:
      return 'kmf';
    case 34:
      return 'bmf';
    case 35:
      return 'koron';
    case 36:
      return 'sori';
  }
  logWarning("Unknown value '${data.value}' for data_ACCIDENTAL_WRITTEN");
  return _unknownValue;
}

/// string -> `data_ACCIDENTAL_WRITTEN`.
AccidentalWritten strToAccidentalWritten(String value) {
  if (value == 's') return AccidentalWritten.s;
  if (value == 'f') return AccidentalWritten.f;
  if (value == 'ss') return AccidentalWritten.ss;
  if (value == 'x') return AccidentalWritten.x;
  if (value == 'ff') return AccidentalWritten.ff;
  if (value == 'xs') return AccidentalWritten.xs;
  if (value == 'sx') return AccidentalWritten.sx;
  if (value == 'ts') return AccidentalWritten.ts;
  if (value == 'tf') return AccidentalWritten.tf;
  if (value == 'n') return AccidentalWritten.n;
  if (value == 'nf') return AccidentalWritten.nf;
  if (value == 'ns') return AccidentalWritten.ns;
  if (value == 'su') return AccidentalWritten.su;
  if (value == 'sd') return AccidentalWritten.sd;
  if (value == 'fu') return AccidentalWritten.fu;
  if (value == 'fd') return AccidentalWritten.fd;
  if (value == 'nu') return AccidentalWritten.nu;
  if (value == 'nd') return AccidentalWritten.nd;
  if (value == 'xu') return AccidentalWritten.xu;
  if (value == 'xd') return AccidentalWritten.xd;
  if (value == 'ffu') return AccidentalWritten.ffu;
  if (value == 'ffd') return AccidentalWritten.ffd;
  if (value == '1qf') return AccidentalWritten.n1qf;
  if (value == '3qf') return AccidentalWritten.n3qf;
  if (value == '1qs') return AccidentalWritten.n1qs;
  if (value == '3qs') return AccidentalWritten.n3qs;
  if (value == 'bms') return AccidentalWritten.bms;
  if (value == 'kms') return AccidentalWritten.kms;
  if (value == 'bs') return AccidentalWritten.bs;
  if (value == 'ks') return AccidentalWritten.ks;
  if (value == 'kf') return AccidentalWritten.kf;
  if (value == 'bf') return AccidentalWritten.bf;
  if (value == 'kmf') return AccidentalWritten.kmf;
  if (value == 'bmf') return AccidentalWritten.bmf;
  if (value == 'koron') return AccidentalWritten.koron;
  if (value == 'sori') return AccidentalWritten.sori;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ACCIDENTAL_WRITTEN");
  }
  return AccidentalWritten.none;
}

/// `data_ACCIDENTAL_WRITTEN_basic` -> string.
String accidentalWrittenBasicToStr(AccidentalWrittenBasic data) {
  switch (data.value) {
    case 1:
      return 's';
    case 2:
      return 'f';
    case 3:
      return 'ss';
    case 4:
      return 'x';
    case 5:
      return 'ff';
    case 6:
      return 'xs';
    case 7:
      return 'sx';
    case 8:
      return 'ts';
    case 9:
      return 'tf';
    case 10:
      return 'n';
    case 11:
      return 'nf';
    case 12:
      return 'ns';
  }
  logWarning("Unknown value '${data.value}' for data_ACCIDENTAL_WRITTEN_basic");
  return _unknownValue;
}

/// string -> `data_ACCIDENTAL_WRITTEN_basic`.
AccidentalWrittenBasic strToAccidentalWrittenBasic(String value) {
  if (value == 's') return AccidentalWrittenBasic.s;
  if (value == 'f') return AccidentalWrittenBasic.f;
  if (value == 'ss') return AccidentalWrittenBasic.ss;
  if (value == 'x') return AccidentalWrittenBasic.x;
  if (value == 'ff') return AccidentalWrittenBasic.ff;
  if (value == 'xs') return AccidentalWrittenBasic.xs;
  if (value == 'sx') return AccidentalWrittenBasic.sx;
  if (value == 'ts') return AccidentalWrittenBasic.ts;
  if (value == 'tf') return AccidentalWrittenBasic.tf;
  if (value == 'n') return AccidentalWrittenBasic.n;
  if (value == 'nf') return AccidentalWrittenBasic.nf;
  if (value == 'ns') return AccidentalWrittenBasic.ns;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ACCIDENTAL_WRITTEN_basic");
  }
  return AccidentalWrittenBasic.none;
}

/// `data_ACCIDENTAL_WRITTEN_extended` -> string.
String accidentalWrittenExtendedToStr(AccidentalWrittenExtended data) {
  switch (data.value) {
    case 1:
      return 'su';
    case 2:
      return 'sd';
    case 3:
      return 'fu';
    case 4:
      return 'fd';
    case 5:
      return 'nu';
    case 6:
      return 'nd';
    case 7:
      return 'xu';
    case 8:
      return 'xd';
    case 9:
      return 'ffu';
    case 10:
      return 'ffd';
    case 11:
      return '1qf';
    case 12:
      return '3qf';
    case 13:
      return '1qs';
    case 14:
      return '3qs';
  }
  logWarning(
      "Unknown value '${data.value}' for data_ACCIDENTAL_WRITTEN_extended");
  return _unknownValue;
}

/// string -> `data_ACCIDENTAL_WRITTEN_extended`.
AccidentalWrittenExtended strToAccidentalWrittenExtended(String value) {
  if (value == 'su') return AccidentalWrittenExtended.su;
  if (value == 'sd') return AccidentalWrittenExtended.sd;
  if (value == 'fu') return AccidentalWrittenExtended.fu;
  if (value == 'fd') return AccidentalWrittenExtended.fd;
  if (value == 'nu') return AccidentalWrittenExtended.nu;
  if (value == 'nd') return AccidentalWrittenExtended.nd;
  if (value == 'xu') return AccidentalWrittenExtended.xu;
  if (value == 'xd') return AccidentalWrittenExtended.xd;
  if (value == 'ffu') return AccidentalWrittenExtended.ffu;
  if (value == 'ffd') return AccidentalWrittenExtended.ffd;
  if (value == '1qf') return AccidentalWrittenExtended.n1qf;
  if (value == '3qf') return AccidentalWrittenExtended.n3qf;
  if (value == '1qs') return AccidentalWrittenExtended.n1qs;
  if (value == '3qs') return AccidentalWrittenExtended.n3qs;
  if (value.isNotEmpty) {
    logWarning(
        "Unsupported value '$value' for data_ACCIDENTAL_WRITTEN_extended");
  }
  return AccidentalWrittenExtended.none;
}

/// `data_ACCIDENTAL_aeu` -> string.
String accidentalAeuToStr(AccidentalAeu data) {
  switch (data.value) {
    case 1:
      return 'bms';
    case 2:
      return 'kms';
    case 3:
      return 'bs';
    case 4:
      return 'ks';
    case 5:
      return 'kf';
    case 6:
      return 'bf';
    case 7:
      return 'kmf';
    case 8:
      return 'bmf';
  }
  logWarning("Unknown value '${data.value}' for data_ACCIDENTAL_aeu");
  return _unknownValue;
}

/// string -> `data_ACCIDENTAL_aeu`.
AccidentalAeu strToAccidentalAeu(String value) {
  if (value == 'bms') return AccidentalAeu.bms;
  if (value == 'kms') return AccidentalAeu.kms;
  if (value == 'bs') return AccidentalAeu.bs;
  if (value == 'ks') return AccidentalAeu.ks;
  if (value == 'kf') return AccidentalAeu.kf;
  if (value == 'bf') return AccidentalAeu.bf;
  if (value == 'kmf') return AccidentalAeu.kmf;
  if (value == 'bmf') return AccidentalAeu.bmf;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ACCIDENTAL_aeu");
  }
  return AccidentalAeu.none;
}

/// `data_ACCIDENTAL_persian` -> string.
String accidentalPersianToStr(AccidentalPersian data) {
  switch (data.value) {
    case 1:
      return 'koron';
    case 2:
      return 'sori';
  }
  logWarning("Unknown value '${data.value}' for data_ACCIDENTAL_persian");
  return _unknownValue;
}

/// string -> `data_ACCIDENTAL_persian`.
AccidentalPersian strToAccidentalPersian(String value) {
  if (value == 'koron') return AccidentalPersian.koron;
  if (value == 'sori') return AccidentalPersian.sori;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ACCIDENTAL_persian");
  }
  return AccidentalPersian.none;
}

/// `data_ARTICULATION` -> string.
String articulationToStr(Articulation data) {
  switch (data.value) {
    case 1:
      return 'acc';
    case 2:
      return 'acc-inv';
    case 3:
      return 'acc-long';
    case 4:
      return 'acc-soft';
    case 5:
      return 'stacc';
    case 6:
      return 'ten';
    case 7:
      return 'stacciss';
    case 8:
      return 'marc';
    case 9:
      return 'spicc';
    case 10:
      return 'stress';
    case 11:
      return 'unstress';
    case 12:
      return 'doit';
    case 13:
      return 'scoop';
    case 14:
      return 'rip';
    case 15:
      return 'plop';
    case 16:
      return 'fall';
    case 17:
      return 'longfall';
    case 18:
      return 'bend';
    case 19:
      return 'flip';
    case 20:
      return 'smear';
    case 21:
      return 'shake';
    case 22:
      return 'dnbow';
    case 23:
      return 'upbow';
    case 24:
      return 'harm';
    case 25:
      return 'snap';
    case 26:
      return 'fingernail';
    case 27:
      return 'damp';
    case 28:
      return 'dampall';
    case 29:
      return 'open';
    case 30:
      return 'stop';
    case 31:
      return 'dbltongue';
    case 32:
      return 'trpltongue';
    case 33:
      return 'heel';
    case 34:
      return 'toe';
    case 35:
      return 'tap';
    case 36:
      return 'lhpizz';
    case 37:
      return 'dot';
    case 38:
      return 'stroke';
  }
  logWarning("Unknown value '${data.value}' for data_ARTICULATION");
  return _unknownValue;
}

/// string -> `data_ARTICULATION`.
Articulation strToArticulation(String value) {
  if (value == 'acc') return Articulation.acc;
  if (value == 'acc-inv') return Articulation.accInv;
  if (value == 'acc-long') return Articulation.accLong;
  if (value == 'acc-soft') return Articulation.accSoft;
  if (value == 'stacc') return Articulation.stacc;
  if (value == 'ten') return Articulation.ten;
  if (value == 'stacciss') return Articulation.stacciss;
  if (value == 'marc') return Articulation.marc;
  if (value == 'spicc') return Articulation.spicc;
  if (value == 'stress') return Articulation.stress;
  if (value == 'unstress') return Articulation.unstress;
  if (value == 'doit') return Articulation.doit;
  if (value == 'scoop') return Articulation.scoop;
  if (value == 'rip') return Articulation.rip;
  if (value == 'plop') return Articulation.plop;
  if (value == 'fall') return Articulation.fall;
  if (value == 'longfall') return Articulation.longfall;
  if (value == 'bend') return Articulation.bend;
  if (value == 'flip') return Articulation.flip;
  if (value == 'smear') return Articulation.smear;
  if (value == 'shake') return Articulation.shake;
  if (value == 'dnbow') return Articulation.dnbow;
  if (value == 'upbow') return Articulation.upbow;
  if (value == 'harm') return Articulation.harm;
  if (value == 'snap') return Articulation.snap;
  if (value == 'fingernail') return Articulation.fingernail;
  if (value == 'damp') return Articulation.damp;
  if (value == 'dampall') return Articulation.dampall;
  if (value == 'open') return Articulation.open;
  if (value == 'stop') return Articulation.stop;
  if (value == 'dbltongue') return Articulation.dbltongue;
  if (value == 'trpltongue') return Articulation.trpltongue;
  if (value == 'heel') return Articulation.heel;
  if (value == 'toe') return Articulation.toe;
  if (value == 'tap') return Articulation.tap;
  if (value == 'lhpizz') return Articulation.lhpizz;
  if (value == 'dot') return Articulation.dot;
  if (value == 'stroke') return Articulation.stroke;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ARTICULATION");
  }
  return Articulation.none;
}

/// `data_BARMETHOD` -> string.
String barmethodToStr(Barmethod data) {
  switch (data.value) {
    case 1:
      return 'mensur';
    case 2:
      return 'staff';
    case 3:
      return 'takt';
  }
  logWarning("Unknown value '${data.value}' for data_BARMETHOD");
  return _unknownValue;
}

/// string -> `data_BARMETHOD`.
Barmethod strToBarmethod(String value) {
  if (value == 'mensur') return Barmethod.mensur;
  if (value == 'staff') return Barmethod.staff;
  if (value == 'takt') return Barmethod.takt;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_BARMETHOD");
  }
  return Barmethod.none;
}

/// `data_BARRENDITION` -> string.
String barrenditionToStr(Barrendition data) {
  switch (data.value) {
    case 1:
      return 'dashed';
    case 2:
      return 'dotted';
    case 3:
      return 'dbl';
    case 4:
      return 'dbldashed';
    case 5:
      return 'dbldotted';
    case 6:
      return 'dblheavy';
    case 7:
      return 'dblsegno';
    case 8:
      return 'end';
    case 9:
      return 'heavy';
    case 10:
      return 'invis';
    case 11:
      return 'rptstart';
    case 12:
      return 'rptboth';
    case 13:
      return 'rptend';
    case 14:
      return 'segno';
    case 15:
      return 'single';
  }
  logWarning("Unknown value '${data.value}' for data_BARRENDITION");
  return _unknownValue;
}

/// string -> `data_BARRENDITION`.
Barrendition strToBarrendition(String value) {
  if (value == 'dashed') return Barrendition.dashed;
  if (value == 'dotted') return Barrendition.dotted;
  if (value == 'dbl') return Barrendition.dbl;
  if (value == 'dbldashed') return Barrendition.dbldashed;
  if (value == 'dbldotted') return Barrendition.dbldotted;
  if (value == 'dblheavy') return Barrendition.dblheavy;
  if (value == 'dblsegno') return Barrendition.dblsegno;
  if (value == 'end') return Barrendition.end;
  if (value == 'heavy') return Barrendition.heavy;
  if (value == 'invis') return Barrendition.invis;
  if (value == 'rptstart') return Barrendition.rptstart;
  if (value == 'rptboth') return Barrendition.rptboth;
  if (value == 'rptend') return Barrendition.rptend;
  if (value == 'segno') return Barrendition.segno;
  if (value == 'single') return Barrendition.single;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_BARRENDITION");
  }
  return Barrendition.none;
}

/// `data_BEAMPLACE` -> string.
String beamplaceToStr(Beamplace data) {
  switch (data.value) {
    case 1:
      return 'above';
    case 2:
      return 'below';
    case 3:
      return 'mixed';
  }
  logWarning("Unknown value '${data.value}' for data_BEAMPLACE");
  return _unknownValue;
}

/// string -> `data_BEAMPLACE`.
Beamplace strToBeamplace(String value) {
  if (value == 'above') return Beamplace.above;
  if (value == 'below') return Beamplace.below;
  if (value == 'mixed') return Beamplace.mixed;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_BEAMPLACE");
  }
  return Beamplace.none;
}

/// `data_BEATRPT_REND` -> string.
String beatrptRendToStr(BeatrptRend data) {
  switch (data.value) {
    case 1:
      return '1';
    case 2:
      return '2';
    case 3:
      return '3';
    case 4:
      return '4';
    case 5:
      return '5';
    case 6:
      return 'mixed';
  }
  logWarning("Unknown value '${data.value}' for data_BEATRPT_REND");
  return _unknownValue;
}

/// string -> `data_BEATRPT_REND`.
BeatrptRend strToBeatrptRend(String value) {
  if (value == '1') return BeatrptRend.n1;
  if (value == '2') return BeatrptRend.n2;
  if (value == '3') return BeatrptRend.n3;
  if (value == '4') return BeatrptRend.n4;
  if (value == '5') return BeatrptRend.n5;
  if (value == 'mixed') return BeatrptRend.mixed;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_BEATRPT_REND");
  }
  return BeatrptRend.none;
}

/// `data_BETYPE` -> string.
String betypeToStr(Betype data) {
  switch (data.value) {
    case 1:
      return 'byte';
    case 2:
      return 'smil';
    case 3:
      return 'midi';
    case 4:
      return 'mmc';
    case 5:
      return 'mtc';
    case 6:
      return 'smpte-25';
    case 7:
      return 'smpte-24';
    case 8:
      return 'smpte-df30';
    case 9:
      return 'smpte-ndf30';
    case 10:
      return 'smpte-df29.97';
    case 11:
      return 'smpte-ndf29.97';
    case 12:
      return 'tcf';
    case 13:
      return 'time';
  }
  logWarning("Unknown value '${data.value}' for data_BETYPE");
  return _unknownValue;
}

/// string -> `data_BETYPE`.
Betype strToBetype(String value) {
  if (value == 'byte') return Betype.byte;
  if (value == 'smil') return Betype.smil;
  if (value == 'midi') return Betype.midi;
  if (value == 'mmc') return Betype.mmc;
  if (value == 'mtc') return Betype.mtc;
  if (value == 'smpte-25') return Betype.smpte25;
  if (value == 'smpte-24') return Betype.smpte24;
  if (value == 'smpte-df30') return Betype.smpteDf30;
  if (value == 'smpte-ndf30') return Betype.smpteNdf30;
  if (value == 'smpte-df29.97') return Betype.smpteDf2997;
  if (value == 'smpte-ndf29.97') return Betype.smpteNdf2997;
  if (value == 'tcf') return Betype.tcf;
  if (value == 'time') return Betype.time;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_BETYPE");
  }
  return Betype.none;
}

/// `data_CANCELACCID` -> string.
String cancelaccidToStr(Cancelaccid data) {
  switch (data.value) {
    case 1:
      return 'none';
    case 2:
      return 'before';
    case 3:
      return 'after';
    case 4:
      return 'before-bar';
  }
  logWarning("Unknown value '${data.value}' for data_CANCELACCID");
  return _unknownValue;
}

/// string -> `data_CANCELACCID`.
Cancelaccid strToCancelaccid(String value) {
  if (value == 'none') return Cancelaccid.none0;
  if (value == 'before') return Cancelaccid.before;
  if (value == 'after') return Cancelaccid.after;
  if (value == 'before-bar') return Cancelaccid.beforeBar;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_CANCELACCID");
  }
  return Cancelaccid.none;
}

/// `data_CERTAINTY` -> string.
String certaintyToStr(Certainty data) {
  switch (data.value) {
    case 1:
      return 'high';
    case 2:
      return 'medium';
    case 3:
      return 'low';
    case 4:
      return 'unknown';
  }
  logWarning("Unknown value '${data.value}' for data_CERTAINTY");
  return _unknownValue;
}

/// string -> `data_CERTAINTY`.
Certainty strToCertainty(String value) {
  if (value == 'high') return Certainty.high;
  if (value == 'medium') return Certainty.medium;
  if (value == 'low') return Certainty.low;
  if (value == 'unknown') return Certainty.unknown;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_CERTAINTY");
  }
  return Certainty.none;
}

/// `data_CLEFSHAPE` -> string.
String clefshapeToStr(Clefshape data) {
  switch (data.value) {
    case 1:
      return 'G';
    case 2:
      return 'GG';
    case 3:
      return 'F';
    case 4:
      return 'C';
    case 5:
      return 'perc';
    case 6:
      return 'TAB';
  }
  logWarning("Unknown value '${data.value}' for data_CLEFSHAPE");
  return _unknownValue;
}

/// string -> `data_CLEFSHAPE`.
Clefshape strToClefshape(String value) {
  if (value == 'G') return Clefshape.g;
  if (value == 'GG') return Clefshape.gg;
  if (value == 'F') return Clefshape.f;
  if (value == 'C') return Clefshape.c;
  if (value == 'perc') return Clefshape.perc;
  if (value == 'TAB') return Clefshape.tab;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_CLEFSHAPE");
  }
  return Clefshape.none;
}

/// `data_CLUSTER` -> string.
String clusterToStr(Cluster data) {
  switch (data.value) {
    case 1:
      return 'white';
    case 2:
      return 'black';
    case 3:
      return 'chromatic';
  }
  logWarning("Unknown value '${data.value}' for data_CLUSTER");
  return _unknownValue;
}

/// string -> `data_CLUSTER`.
Cluster strToCluster(String value) {
  if (value == 'white') return Cluster.white;
  if (value == 'black') return Cluster.black;
  if (value == 'chromatic') return Cluster.chromatic;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_CLUSTER");
  }
  return Cluster.none;
}

/// `data_COLORNAMES` -> string.
String colornamesToStr(Colornames data) {
  switch (data.value) {
    case 1:
      return 'aliceblue';
    case 2:
      return 'antiquewhite';
    case 3:
      return 'aqua';
    case 4:
      return 'aquamarine';
    case 5:
      return 'azure';
    case 6:
      return 'beige';
    case 7:
      return 'bisque';
    case 8:
      return 'black';
    case 9:
      return 'blanchedalmond';
    case 10:
      return 'blue';
    case 11:
      return 'blueviolet';
    case 12:
      return 'brown';
    case 13:
      return 'burlywood';
    case 14:
      return 'cadetblue';
    case 15:
      return 'chartreuse';
    case 16:
      return 'chocolate';
    case 17:
      return 'coral';
    case 18:
      return 'cornflowerblue';
    case 19:
      return 'cornsilk';
    case 20:
      return 'crimson';
    case 21:
      return 'cyan';
    case 22:
      return 'darkblue';
    case 23:
      return 'darkcyan';
    case 24:
      return 'darkgoldenrod';
    case 25:
      return 'darkgray';
    case 26:
      return 'darkgreen';
    case 27:
      return 'darkgrey';
    case 28:
      return 'darkkhaki';
    case 29:
      return 'darkmagenta';
    case 30:
      return 'darkolivegreen';
    case 31:
      return 'darkorange';
    case 32:
      return 'darkorchid';
    case 33:
      return 'darkred';
    case 34:
      return 'darksalmon';
    case 35:
      return 'darkseagreen';
    case 36:
      return 'darkslateblue';
    case 37:
      return 'darkslategray';
    case 38:
      return 'darkslategrey';
    case 39:
      return 'darkturquoise';
    case 40:
      return 'darkviolet';
    case 41:
      return 'deeppink';
    case 42:
      return 'deepskyblue';
    case 43:
      return 'dimgray';
    case 44:
      return 'dimgrey';
    case 45:
      return 'dodgerblue';
    case 46:
      return 'firebrick';
    case 47:
      return 'floralwhite';
    case 48:
      return 'forestgreen';
    case 49:
      return 'fuchsia';
    case 50:
      return 'gainsboro';
    case 51:
      return 'ghostwhite';
    case 52:
      return 'gold';
    case 53:
      return 'goldenrod';
    case 54:
      return 'gray';
    case 55:
      return 'green';
    case 56:
      return 'greenyellow';
    case 57:
      return 'grey';
    case 58:
      return 'honeydew';
    case 59:
      return 'hotpink';
    case 60:
      return 'indianred';
    case 61:
      return 'indigo';
    case 62:
      return 'ivory';
    case 63:
      return 'khaki';
    case 64:
      return 'lavender';
    case 65:
      return 'lavenderblush';
    case 66:
      return 'lawngreen';
    case 67:
      return 'lemonchiffon';
    case 68:
      return 'lightblue';
    case 69:
      return 'lightcoral';
    case 70:
      return 'lightcyan';
    case 71:
      return 'lightgoldenrodyellow';
    case 72:
      return 'lightgray';
    case 73:
      return 'lightgreen';
    case 74:
      return 'lightgrey';
    case 75:
      return 'lightpink';
    case 76:
      return 'lightsalmon';
    case 77:
      return 'lightseagreen';
    case 78:
      return 'lightskyblue';
    case 79:
      return 'lightslategray';
    case 80:
      return 'lightslategrey';
    case 81:
      return 'lightsteelblue';
    case 82:
      return 'lightyellow';
    case 83:
      return 'lime';
    case 84:
      return 'limegreen';
    case 85:
      return 'linen';
    case 86:
      return 'magenta';
    case 87:
      return 'maroon';
    case 88:
      return 'mediumaquamarine';
    case 89:
      return 'mediumblue';
    case 90:
      return 'mediumorchid';
    case 91:
      return 'mediumpurple';
    case 92:
      return 'mediumseagreen';
    case 93:
      return 'mediumslateblue';
    case 94:
      return 'mediumspringgreen';
    case 95:
      return 'mediumturquoise';
    case 96:
      return 'mediumvioletred';
    case 97:
      return 'midnightblue';
    case 98:
      return 'mintcream';
    case 99:
      return 'mistyrose';
    case 100:
      return 'moccasin';
    case 101:
      return 'navajowhite';
    case 102:
      return 'navy';
    case 103:
      return 'oldlace';
    case 104:
      return 'olive';
    case 105:
      return 'olivedrab';
    case 106:
      return 'orange';
    case 107:
      return 'orangered';
    case 108:
      return 'orchid';
    case 109:
      return 'palegoldenrod';
    case 110:
      return 'palegreen';
    case 111:
      return 'paleturquoise';
    case 112:
      return 'palevioletred';
    case 113:
      return 'papayawhip';
    case 114:
      return 'peachpuff';
    case 115:
      return 'peru';
    case 116:
      return 'pink';
    case 117:
      return 'plum';
    case 118:
      return 'powderblue';
    case 119:
      return 'purple';
    case 120:
      return 'rebeccapurple';
    case 121:
      return 'red';
    case 122:
      return 'rosybrown';
    case 123:
      return 'royalblue';
    case 124:
      return 'saddlebrown';
    case 125:
      return 'salmon';
    case 126:
      return 'sandybrown';
    case 127:
      return 'seagreen';
    case 128:
      return 'seashell';
    case 129:
      return 'sienna';
    case 130:
      return 'silver';
    case 131:
      return 'skyblue';
    case 132:
      return 'slateblue';
    case 133:
      return 'slategray';
    case 134:
      return 'slategrey';
    case 135:
      return 'snow';
    case 136:
      return 'springgreen';
    case 137:
      return 'steelblue';
    case 138:
      return 'tan';
    case 139:
      return 'teal';
    case 140:
      return 'thistle';
    case 141:
      return 'tomato';
    case 142:
      return 'turquoise';
    case 143:
      return 'violet';
    case 144:
      return 'wheat';
    case 145:
      return 'white';
    case 146:
      return 'whitesmoke';
    case 147:
      return 'yellow';
    case 148:
      return 'yellowgreen';
  }
  logWarning("Unknown value '${data.value}' for data_COLORNAMES");
  return _unknownValue;
}

/// string -> `data_COLORNAMES`.
Colornames strToColornames(String value) {
  if (value == 'aliceblue') return Colornames.aliceblue;
  if (value == 'antiquewhite') return Colornames.antiquewhite;
  if (value == 'aqua') return Colornames.aqua;
  if (value == 'aquamarine') return Colornames.aquamarine;
  if (value == 'azure') return Colornames.azure;
  if (value == 'beige') return Colornames.beige;
  if (value == 'bisque') return Colornames.bisque;
  if (value == 'black') return Colornames.black;
  if (value == 'blanchedalmond') return Colornames.blanchedalmond;
  if (value == 'blue') return Colornames.blue;
  if (value == 'blueviolet') return Colornames.blueviolet;
  if (value == 'brown') return Colornames.brown;
  if (value == 'burlywood') return Colornames.burlywood;
  if (value == 'cadetblue') return Colornames.cadetblue;
  if (value == 'chartreuse') return Colornames.chartreuse;
  if (value == 'chocolate') return Colornames.chocolate;
  if (value == 'coral') return Colornames.coral;
  if (value == 'cornflowerblue') return Colornames.cornflowerblue;
  if (value == 'cornsilk') return Colornames.cornsilk;
  if (value == 'crimson') return Colornames.crimson;
  if (value == 'cyan') return Colornames.cyan;
  if (value == 'darkblue') return Colornames.darkblue;
  if (value == 'darkcyan') return Colornames.darkcyan;
  if (value == 'darkgoldenrod') return Colornames.darkgoldenrod;
  if (value == 'darkgray') return Colornames.darkgray;
  if (value == 'darkgreen') return Colornames.darkgreen;
  if (value == 'darkgrey') return Colornames.darkgrey;
  if (value == 'darkkhaki') return Colornames.darkkhaki;
  if (value == 'darkmagenta') return Colornames.darkmagenta;
  if (value == 'darkolivegreen') return Colornames.darkolivegreen;
  if (value == 'darkorange') return Colornames.darkorange;
  if (value == 'darkorchid') return Colornames.darkorchid;
  if (value == 'darkred') return Colornames.darkred;
  if (value == 'darksalmon') return Colornames.darksalmon;
  if (value == 'darkseagreen') return Colornames.darkseagreen;
  if (value == 'darkslateblue') return Colornames.darkslateblue;
  if (value == 'darkslategray') return Colornames.darkslategray;
  if (value == 'darkslategrey') return Colornames.darkslategrey;
  if (value == 'darkturquoise') return Colornames.darkturquoise;
  if (value == 'darkviolet') return Colornames.darkviolet;
  if (value == 'deeppink') return Colornames.deeppink;
  if (value == 'deepskyblue') return Colornames.deepskyblue;
  if (value == 'dimgray') return Colornames.dimgray;
  if (value == 'dimgrey') return Colornames.dimgrey;
  if (value == 'dodgerblue') return Colornames.dodgerblue;
  if (value == 'firebrick') return Colornames.firebrick;
  if (value == 'floralwhite') return Colornames.floralwhite;
  if (value == 'forestgreen') return Colornames.forestgreen;
  if (value == 'fuchsia') return Colornames.fuchsia;
  if (value == 'gainsboro') return Colornames.gainsboro;
  if (value == 'ghostwhite') return Colornames.ghostwhite;
  if (value == 'gold') return Colornames.gold;
  if (value == 'goldenrod') return Colornames.goldenrod;
  if (value == 'gray') return Colornames.gray;
  if (value == 'green') return Colornames.green;
  if (value == 'greenyellow') return Colornames.greenyellow;
  if (value == 'grey') return Colornames.grey;
  if (value == 'honeydew') return Colornames.honeydew;
  if (value == 'hotpink') return Colornames.hotpink;
  if (value == 'indianred') return Colornames.indianred;
  if (value == 'indigo') return Colornames.indigo;
  if (value == 'ivory') return Colornames.ivory;
  if (value == 'khaki') return Colornames.khaki;
  if (value == 'lavender') return Colornames.lavender;
  if (value == 'lavenderblush') return Colornames.lavenderblush;
  if (value == 'lawngreen') return Colornames.lawngreen;
  if (value == 'lemonchiffon') return Colornames.lemonchiffon;
  if (value == 'lightblue') return Colornames.lightblue;
  if (value == 'lightcoral') return Colornames.lightcoral;
  if (value == 'lightcyan') return Colornames.lightcyan;
  if (value == 'lightgoldenrodyellow') return Colornames.lightgoldenrodyellow;
  if (value == 'lightgray') return Colornames.lightgray;
  if (value == 'lightgreen') return Colornames.lightgreen;
  if (value == 'lightgrey') return Colornames.lightgrey;
  if (value == 'lightpink') return Colornames.lightpink;
  if (value == 'lightsalmon') return Colornames.lightsalmon;
  if (value == 'lightseagreen') return Colornames.lightseagreen;
  if (value == 'lightskyblue') return Colornames.lightskyblue;
  if (value == 'lightslategray') return Colornames.lightslategray;
  if (value == 'lightslategrey') return Colornames.lightslategrey;
  if (value == 'lightsteelblue') return Colornames.lightsteelblue;
  if (value == 'lightyellow') return Colornames.lightyellow;
  if (value == 'lime') return Colornames.lime;
  if (value == 'limegreen') return Colornames.limegreen;
  if (value == 'linen') return Colornames.linen;
  if (value == 'magenta') return Colornames.magenta;
  if (value == 'maroon') return Colornames.maroon;
  if (value == 'mediumaquamarine') return Colornames.mediumaquamarine;
  if (value == 'mediumblue') return Colornames.mediumblue;
  if (value == 'mediumorchid') return Colornames.mediumorchid;
  if (value == 'mediumpurple') return Colornames.mediumpurple;
  if (value == 'mediumseagreen') return Colornames.mediumseagreen;
  if (value == 'mediumslateblue') return Colornames.mediumslateblue;
  if (value == 'mediumspringgreen') return Colornames.mediumspringgreen;
  if (value == 'mediumturquoise') return Colornames.mediumturquoise;
  if (value == 'mediumvioletred') return Colornames.mediumvioletred;
  if (value == 'midnightblue') return Colornames.midnightblue;
  if (value == 'mintcream') return Colornames.mintcream;
  if (value == 'mistyrose') return Colornames.mistyrose;
  if (value == 'moccasin') return Colornames.moccasin;
  if (value == 'navajowhite') return Colornames.navajowhite;
  if (value == 'navy') return Colornames.navy;
  if (value == 'oldlace') return Colornames.oldlace;
  if (value == 'olive') return Colornames.olive;
  if (value == 'olivedrab') return Colornames.olivedrab;
  if (value == 'orange') return Colornames.orange;
  if (value == 'orangered') return Colornames.orangered;
  if (value == 'orchid') return Colornames.orchid;
  if (value == 'palegoldenrod') return Colornames.palegoldenrod;
  if (value == 'palegreen') return Colornames.palegreen;
  if (value == 'paleturquoise') return Colornames.paleturquoise;
  if (value == 'palevioletred') return Colornames.palevioletred;
  if (value == 'papayawhip') return Colornames.papayawhip;
  if (value == 'peachpuff') return Colornames.peachpuff;
  if (value == 'peru') return Colornames.peru;
  if (value == 'pink') return Colornames.pink;
  if (value == 'plum') return Colornames.plum;
  if (value == 'powderblue') return Colornames.powderblue;
  if (value == 'purple') return Colornames.purple;
  if (value == 'rebeccapurple') return Colornames.rebeccapurple;
  if (value == 'red') return Colornames.red;
  if (value == 'rosybrown') return Colornames.rosybrown;
  if (value == 'royalblue') return Colornames.royalblue;
  if (value == 'saddlebrown') return Colornames.saddlebrown;
  if (value == 'salmon') return Colornames.salmon;
  if (value == 'sandybrown') return Colornames.sandybrown;
  if (value == 'seagreen') return Colornames.seagreen;
  if (value == 'seashell') return Colornames.seashell;
  if (value == 'sienna') return Colornames.sienna;
  if (value == 'silver') return Colornames.silver;
  if (value == 'skyblue') return Colornames.skyblue;
  if (value == 'slateblue') return Colornames.slateblue;
  if (value == 'slategray') return Colornames.slategray;
  if (value == 'slategrey') return Colornames.slategrey;
  if (value == 'snow') return Colornames.snow;
  if (value == 'springgreen') return Colornames.springgreen;
  if (value == 'steelblue') return Colornames.steelblue;
  if (value == 'tan') return Colornames.tan;
  if (value == 'teal') return Colornames.teal;
  if (value == 'thistle') return Colornames.thistle;
  if (value == 'tomato') return Colornames.tomato;
  if (value == 'turquoise') return Colornames.turquoise;
  if (value == 'violet') return Colornames.violet;
  if (value == 'wheat') return Colornames.wheat;
  if (value == 'white') return Colornames.white;
  if (value == 'whitesmoke') return Colornames.whitesmoke;
  if (value == 'yellow') return Colornames.yellow;
  if (value == 'yellowgreen') return Colornames.yellowgreen;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_COLORNAMES");
  }
  return Colornames.none;
}

/// `data_COMPASSDIRECTION` -> string.
String compassdirectionToStr(Compassdirection data) {
  switch (data.value) {
    case 1:
      return 'n';
    case 2:
      return 'e';
    case 3:
      return 's';
    case 4:
      return 'w';
    case 5:
      return 'ne';
    case 6:
      return 'nw';
    case 7:
      return 'se';
    case 8:
      return 'sw';
  }
  logWarning("Unknown value '${data.value}' for data_COMPASSDIRECTION");
  return _unknownValue;
}

/// string -> `data_COMPASSDIRECTION`.
Compassdirection strToCompassdirection(String value) {
  if (value == 'n') return Compassdirection.n;
  if (value == 'e') return Compassdirection.e;
  if (value == 's') return Compassdirection.s;
  if (value == 'w') return Compassdirection.w;
  if (value == 'ne') return Compassdirection.ne;
  if (value == 'nw') return Compassdirection.nw;
  if (value == 'se') return Compassdirection.se;
  if (value == 'sw') return Compassdirection.sw;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_COMPASSDIRECTION");
  }
  return Compassdirection.none;
}

/// `data_COMPASSDIRECTION_basic` -> string.
String compassdirectionBasicToStr(CompassdirectionBasic data) {
  switch (data.value) {
    case 1:
      return 'n';
    case 2:
      return 'e';
    case 3:
      return 's';
    case 4:
      return 'w';
  }
  logWarning("Unknown value '${data.value}' for data_COMPASSDIRECTION_basic");
  return _unknownValue;
}

/// string -> `data_COMPASSDIRECTION_basic`.
CompassdirectionBasic strToCompassdirectionBasic(String value) {
  if (value == 'n') return CompassdirectionBasic.n;
  if (value == 'e') return CompassdirectionBasic.e;
  if (value == 's') return CompassdirectionBasic.s;
  if (value == 'w') return CompassdirectionBasic.w;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_COMPASSDIRECTION_basic");
  }
  return CompassdirectionBasic.none;
}

/// `data_COMPASSDIRECTION_extended` -> string.
String compassdirectionExtendedToStr(CompassdirectionExtended data) {
  switch (data.value) {
    case 1:
      return 'ne';
    case 2:
      return 'nw';
    case 3:
      return 'se';
    case 4:
      return 'sw';
  }
  logWarning(
      "Unknown value '${data.value}' for data_COMPASSDIRECTION_extended");
  return _unknownValue;
}

/// string -> `data_COMPASSDIRECTION_extended`.
CompassdirectionExtended strToCompassdirectionExtended(String value) {
  if (value == 'ne') return CompassdirectionExtended.ne;
  if (value == 'nw') return CompassdirectionExtended.nw;
  if (value == 'se') return CompassdirectionExtended.se;
  if (value == 'sw') return CompassdirectionExtended.sw;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_COMPASSDIRECTION_extended");
  }
  return CompassdirectionExtended.none;
}

/// `data_COURSETUNING` -> string.
String coursetuningToStr(Coursetuning data) {
  switch (data.value) {
    case 1:
      return 'guitar.standard';
    case 2:
      return 'guitar.drop.D';
    case 3:
      return 'guitar.open.D';
    case 4:
      return 'guitar.open.G';
    case 5:
      return 'guitar.open.A';
    case 6:
      return 'lute.renaissance.6';
    case 7:
      return 'lute.baroque.d.major';
    case 8:
      return 'lute.baroque.d.minor';
  }
  logWarning("Unknown value '${data.value}' for data_COURSETUNING");
  return _unknownValue;
}

/// string -> `data_COURSETUNING`.
Coursetuning strToCoursetuning(String value) {
  if (value == 'guitar.standard') return Coursetuning.guitarStandard;
  if (value == 'guitar.drop.D') return Coursetuning.guitarDropD;
  if (value == 'guitar.open.D') return Coursetuning.guitarOpenD;
  if (value == 'guitar.open.G') return Coursetuning.guitarOpenG;
  if (value == 'guitar.open.A') return Coursetuning.guitarOpenA;
  if (value == 'lute.renaissance.6') return Coursetuning.luteRenaissance6;
  if (value == 'lute.baroque.d.major') return Coursetuning.luteBaroqueDMajor;
  if (value == 'lute.baroque.d.minor') return Coursetuning.luteBaroqueDMinor;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_COURSETUNING");
  }
  return Coursetuning.none;
}

/// `data_DIVISIO` -> string.
String divisioToStr(Divisio data) {
  switch (data.value) {
    case 1:
      return 'ternaria';
    case 2:
      return 'quaternaria';
    case 3:
      return 'senariaimperf';
    case 4:
      return 'senariaperf';
    case 5:
      return 'octonaria';
    case 6:
      return 'novenaria';
    case 7:
      return 'duodenaria';
  }
  logWarning("Unknown value '${data.value}' for data_DIVISIO");
  return _unknownValue;
}

/// string -> `data_DIVISIO`.
Divisio strToDivisio(String value) {
  if (value == 'ternaria') return Divisio.ternaria;
  if (value == 'quaternaria') return Divisio.quaternaria;
  if (value == 'senariaimperf') return Divisio.senariaimperf;
  if (value == 'senariaperf') return Divisio.senariaperf;
  if (value == 'octonaria') return Divisio.octonaria;
  if (value == 'novenaria') return Divisio.novenaria;
  if (value == 'duodenaria') return Divisio.duodenaria;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_DIVISIO");
  }
  return Divisio.none;
}

/// `data_DURATIONRESTS_mensural` -> string.
String durationrestsMensuralToStr(DurationrestsMensural data) {
  switch (data.value) {
    case 1:
      return '2B';
    case 2:
      return '3B';
    case 3:
      return 'maxima';
    case 4:
      return 'longa';
    case 5:
      return 'brevis';
    case 6:
      return 'semibrevis';
    case 7:
      return 'minima';
    case 8:
      return 'semiminima';
    case 9:
      return 'fusa';
    case 10:
      return 'semifusa';
  }
  logWarning("Unknown value '${data.value}' for data_DURATIONRESTS_mensural");
  return _unknownValue;
}

/// string -> `data_DURATIONRESTS_mensural`.
DurationrestsMensural strToDurationrestsMensural(String value) {
  if (value == '2B') return DurationrestsMensural.n2b;
  if (value == '3B') return DurationrestsMensural.n3b;
  if (value == 'maxima') return DurationrestsMensural.maxima;
  if (value == 'longa') return DurationrestsMensural.longa;
  if (value == 'brevis') return DurationrestsMensural.brevis;
  if (value == 'semibrevis') return DurationrestsMensural.semibrevis;
  if (value == 'minima') return DurationrestsMensural.minima;
  if (value == 'semiminima') return DurationrestsMensural.semiminima;
  if (value == 'fusa') return DurationrestsMensural.fusa;
  if (value == 'semifusa') return DurationrestsMensural.semifusa;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_DURATIONRESTS_mensural");
  }
  return DurationrestsMensural.none;
}

/// `data_DURQUALITY_mensural` -> string.
String durqualityMensuralToStr(DurqualityMensural data) {
  switch (data.value) {
    case 1:
      return 'perfecta';
    case 2:
      return 'imperfecta';
    case 3:
      return 'altera';
    case 4:
      return 'minor';
    case 5:
      return 'maior';
    case 6:
      return 'duplex';
  }
  logWarning("Unknown value '${data.value}' for data_DURQUALITY_mensural");
  return _unknownValue;
}

/// string -> `data_DURQUALITY_mensural`.
DurqualityMensural strToDurqualityMensural(String value) {
  if (value == 'perfecta') return DurqualityMensural.perfecta;
  if (value == 'imperfecta') return DurqualityMensural.imperfecta;
  if (value == 'altera') return DurqualityMensural.altera;
  if (value == 'minor') return DurqualityMensural.minor;
  if (value == 'maior') return DurqualityMensural.maior;
  if (value == 'duplex') return DurqualityMensural.duplex;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_DURQUALITY_mensural");
  }
  return DurqualityMensural.none;
}

/// `data_ENCLOSURE` -> string.
String enclosureToStr(Enclosure data) {
  switch (data.value) {
    case 1:
      return 'paren';
    case 2:
      return 'brack';
    case 3:
      return 'box';
    case 4:
      return 'none';
  }
  logWarning("Unknown value '${data.value}' for data_ENCLOSURE");
  return _unknownValue;
}

/// string -> `data_ENCLOSURE`.
Enclosure strToEnclosure(String value) {
  if (value == 'paren') return Enclosure.paren;
  if (value == 'brack') return Enclosure.brack;
  if (value == 'box') return Enclosure.box;
  if (value == 'none') return Enclosure.none0;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ENCLOSURE");
  }
  return Enclosure.none;
}

/// `data_EVENTREL` -> string.
String eventrelToStr(Eventrel data) {
  switch (data.value) {
    case 1:
      return 'above';
    case 2:
      return 'below';
    case 3:
      return 'left';
    case 4:
      return 'right';
    case 5:
      return 'above-left';
    case 6:
      return 'above-right';
    case 7:
      return 'below-left';
    case 8:
      return 'below-right';
  }
  logWarning("Unknown value '${data.value}' for data_EVENTREL");
  return _unknownValue;
}

/// string -> `data_EVENTREL`.
Eventrel strToEventrel(String value) {
  if (value == 'above') return Eventrel.above;
  if (value == 'below') return Eventrel.below;
  if (value == 'left') return Eventrel.left;
  if (value == 'right') return Eventrel.right;
  if (value == 'above-left') return Eventrel.aboveLeft;
  if (value == 'above-right') return Eventrel.aboveRight;
  if (value == 'below-left') return Eventrel.belowLeft;
  if (value == 'below-right') return Eventrel.belowRight;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_EVENTREL");
  }
  return Eventrel.none;
}

/// `data_EVENTREL_basic` -> string.
String eventrelBasicToStr(EventrelBasic data) {
  switch (data.value) {
    case 1:
      return 'above';
    case 2:
      return 'below';
    case 3:
      return 'left';
    case 4:
      return 'right';
  }
  logWarning("Unknown value '${data.value}' for data_EVENTREL_basic");
  return _unknownValue;
}

/// string -> `data_EVENTREL_basic`.
EventrelBasic strToEventrelBasic(String value) {
  if (value == 'above') return EventrelBasic.above;
  if (value == 'below') return EventrelBasic.below;
  if (value == 'left') return EventrelBasic.left;
  if (value == 'right') return EventrelBasic.right;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_EVENTREL_basic");
  }
  return EventrelBasic.none;
}

/// `data_EVENTREL_extended` -> string.
String eventrelExtendedToStr(EventrelExtended data) {
  switch (data.value) {
    case 1:
      return 'above-left';
    case 2:
      return 'above-right';
    case 3:
      return 'below-left';
    case 4:
      return 'below-right';
  }
  logWarning("Unknown value '${data.value}' for data_EVENTREL_extended");
  return _unknownValue;
}

/// string -> `data_EVENTREL_extended`.
EventrelExtended strToEventrelExtended(String value) {
  if (value == 'above-left') return EventrelExtended.aboveLeft;
  if (value == 'above-right') return EventrelExtended.aboveRight;
  if (value == 'below-left') return EventrelExtended.belowLeft;
  if (value == 'below-right') return EventrelExtended.belowRight;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_EVENTREL_extended");
  }
  return EventrelExtended.none;
}

/// `data_FILL` -> string.
String fillToStr(Fill data) {
  switch (data.value) {
    case 1:
      return 'void';
    case 2:
      return 'solid';
    case 3:
      return 'top';
    case 4:
      return 'bottom';
    case 5:
      return 'left';
    case 6:
      return 'right';
  }
  logWarning("Unknown value '${data.value}' for data_FILL");
  return _unknownValue;
}

/// string -> `data_FILL`.
Fill strToFill(String value) {
  if (value == 'void') return Fill.voidValue;
  if (value == 'solid') return Fill.solid;
  if (value == 'top') return Fill.top;
  if (value == 'bottom') return Fill.bottom;
  if (value == 'left') return Fill.left;
  if (value == 'right') return Fill.right;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_FILL");
  }
  return Fill.none;
}

/// `data_FLAGFORM_mensural` -> string.
String flagformMensuralToStr(FlagformMensural data) {
  switch (data.value) {
    case 1:
      return 'straight';
    case 2:
      return 'angled';
    case 3:
      return 'curled';
    case 4:
      return 'flared';
    case 5:
      return 'extended';
    case 6:
      return 'hooked';
  }
  logWarning("Unknown value '${data.value}' for data_FLAGFORM_mensural");
  return _unknownValue;
}

/// string -> `data_FLAGFORM_mensural`.
FlagformMensural strToFlagformMensural(String value) {
  if (value == 'straight') return FlagformMensural.straight;
  if (value == 'angled') return FlagformMensural.angled;
  if (value == 'curled') return FlagformMensural.curled;
  if (value == 'flared') return FlagformMensural.flared;
  if (value == 'extended') return FlagformMensural.extended;
  if (value == 'hooked') return FlagformMensural.hooked;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_FLAGFORM_mensural");
  }
  return FlagformMensural.none;
}

/// `data_FLAGPOS_mensural` -> string.
String flagposMensuralToStr(FlagposMensural data) {
  switch (data.value) {
    case 1:
      return 'left';
    case 2:
      return 'right';
    case 3:
      return 'center';
  }
  logWarning("Unknown value '${data.value}' for data_FLAGPOS_mensural");
  return _unknownValue;
}

/// string -> `data_FLAGPOS_mensural`.
FlagposMensural strToFlagposMensural(String value) {
  if (value == 'left') return FlagposMensural.left;
  if (value == 'right') return FlagposMensural.right;
  if (value == 'center') return FlagposMensural.center;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_FLAGPOS_mensural");
  }
  return FlagposMensural.none;
}

/// `data_FONTSIZETERM` -> string.
String fontsizetermToStr(Fontsizeterm data) {
  switch (data.value) {
    case 1:
      return 'xx-small';
    case 2:
      return 'x-small';
    case 3:
      return 'small';
    case 4:
      return 'normal';
    case 5:
      return 'large';
    case 6:
      return 'x-large';
    case 7:
      return 'xx-large';
    case 8:
      return 'smaller';
    case 9:
      return 'larger';
  }
  logWarning("Unknown value '${data.value}' for data_FONTSIZETERM");
  return _unknownValue;
}

/// string -> `data_FONTSIZETERM`.
Fontsizeterm strToFontsizeterm(String value) {
  if (value == 'xx-small') return Fontsizeterm.xxSmall;
  if (value == 'x-small') return Fontsizeterm.xSmall;
  if (value == 'small') return Fontsizeterm.small;
  if (value == 'normal') return Fontsizeterm.normal;
  if (value == 'large') return Fontsizeterm.large;
  if (value == 'x-large') return Fontsizeterm.xLarge;
  if (value == 'xx-large') return Fontsizeterm.xxLarge;
  if (value == 'smaller') return Fontsizeterm.smaller;
  if (value == 'larger') return Fontsizeterm.larger;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_FONTSIZETERM");
  }
  return Fontsizeterm.none;
}

/// `data_FONTSTYLE` -> string.
String fontstyleToStr(Fontstyle data) {
  switch (data.value) {
    case 1:
      return 'italic';
    case 2:
      return 'normal';
    case 3:
      return 'oblique';
  }
  logWarning("Unknown value '${data.value}' for data_FONTSTYLE");
  return _unknownValue;
}

/// string -> `data_FONTSTYLE`.
Fontstyle strToFontstyle(String value) {
  if (value == 'italic') return Fontstyle.italic;
  if (value == 'normal') return Fontstyle.normal;
  if (value == 'oblique') return Fontstyle.oblique;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_FONTSTYLE");
  }
  return Fontstyle.none;
}

/// `data_FONTWEIGHT` -> string.
String fontweightToStr(Fontweight data) {
  switch (data.value) {
    case 1:
      return 'bold';
    case 2:
      return 'normal';
  }
  logWarning("Unknown value '${data.value}' for data_FONTWEIGHT");
  return _unknownValue;
}

/// string -> `data_FONTWEIGHT`.
Fontweight strToFontweight(String value) {
  if (value == 'bold') return Fontweight.bold;
  if (value == 'normal') return Fontweight.normal;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_FONTWEIGHT");
  }
  return Fontweight.none;
}

/// `data_FRBRRELATIONSHIP` -> string.
String frbrrelationshipToStr(Frbrrelationship data) {
  switch (data.value) {
    case 1:
      return 'hasAbridgement';
    case 2:
      return 'isAbridgementOf';
    case 3:
      return 'hasAdaptation';
    case 4:
      return 'isAdaptationOf';
    case 5:
      return 'hasAlternate';
    case 6:
      return 'isAlternateOf';
    case 7:
      return 'hasArrangement';
    case 8:
      return 'isArrangementOf';
    case 9:
      return 'hasComplement';
    case 10:
      return 'isComplementOf';
    case 11:
      return 'hasEmbodiment';
    case 12:
      return 'isEmbodimentOf';
    case 13:
      return 'hasExemplar';
    case 14:
      return 'isExemplarOf';
    case 15:
      return 'hasImitation';
    case 16:
      return 'isImitationOf';
    case 17:
      return 'hasPart';
    case 18:
      return 'isPartOf';
    case 19:
      return 'hasRealization';
    case 20:
      return 'isRealizationOf';
    case 21:
      return 'hasReconfiguration';
    case 22:
      return 'isReconfigurationOf';
    case 23:
      return 'hasReproduction';
    case 24:
      return 'isReproductionOf';
    case 25:
      return 'hasRevision';
    case 26:
      return 'isRevisionOf';
    case 27:
      return 'hasSuccessor';
    case 28:
      return 'isSuccessorOf';
    case 29:
      return 'hasSummarization';
    case 30:
      return 'isSummarizationOf';
    case 31:
      return 'hasSupplement';
    case 32:
      return 'isSupplementOf';
    case 33:
      return 'hasTransformation';
    case 34:
      return 'isTransformationOf';
    case 35:
      return 'hasTranslation';
    case 36:
      return 'isTranslationOf';
  }
  logWarning("Unknown value '${data.value}' for data_FRBRRELATIONSHIP");
  return _unknownValue;
}

/// string -> `data_FRBRRELATIONSHIP`.
Frbrrelationship strToFrbrrelationship(String value) {
  if (value == 'hasAbridgement') return Frbrrelationship.hasabridgement;
  if (value == 'isAbridgementOf') return Frbrrelationship.isabridgementof;
  if (value == 'hasAdaptation') return Frbrrelationship.hasadaptation;
  if (value == 'isAdaptationOf') return Frbrrelationship.isadaptationof;
  if (value == 'hasAlternate') return Frbrrelationship.hasalternate;
  if (value == 'isAlternateOf') return Frbrrelationship.isalternateof;
  if (value == 'hasArrangement') return Frbrrelationship.hasarrangement;
  if (value == 'isArrangementOf') return Frbrrelationship.isarrangementof;
  if (value == 'hasComplement') return Frbrrelationship.hascomplement;
  if (value == 'isComplementOf') return Frbrrelationship.iscomplementof;
  if (value == 'hasEmbodiment') return Frbrrelationship.hasembodiment;
  if (value == 'isEmbodimentOf') return Frbrrelationship.isembodimentof;
  if (value == 'hasExemplar') return Frbrrelationship.hasexemplar;
  if (value == 'isExemplarOf') return Frbrrelationship.isexemplarof;
  if (value == 'hasImitation') return Frbrrelationship.hasimitation;
  if (value == 'isImitationOf') return Frbrrelationship.isimitationof;
  if (value == 'hasPart') return Frbrrelationship.haspart;
  if (value == 'isPartOf') return Frbrrelationship.ispartof;
  if (value == 'hasRealization') return Frbrrelationship.hasrealization;
  if (value == 'isRealizationOf') return Frbrrelationship.isrealizationof;
  if (value == 'hasReconfiguration') return Frbrrelationship.hasreconfiguration;
  if (value == 'isReconfigurationOf')
    return Frbrrelationship.isreconfigurationof;
  if (value == 'hasReproduction') return Frbrrelationship.hasreproduction;
  if (value == 'isReproductionOf') return Frbrrelationship.isreproductionof;
  if (value == 'hasRevision') return Frbrrelationship.hasrevision;
  if (value == 'isRevisionOf') return Frbrrelationship.isrevisionof;
  if (value == 'hasSuccessor') return Frbrrelationship.hassuccessor;
  if (value == 'isSuccessorOf') return Frbrrelationship.issuccessorof;
  if (value == 'hasSummarization') return Frbrrelationship.hassummarization;
  if (value == 'isSummarizationOf') return Frbrrelationship.issummarizationof;
  if (value == 'hasSupplement') return Frbrrelationship.hassupplement;
  if (value == 'isSupplementOf') return Frbrrelationship.issupplementof;
  if (value == 'hasTransformation') return Frbrrelationship.hastransformation;
  if (value == 'isTransformationOf') return Frbrrelationship.istransformationof;
  if (value == 'hasTranslation') return Frbrrelationship.hastranslation;
  if (value == 'isTranslationOf') return Frbrrelationship.istranslationof;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_FRBRRELATIONSHIP");
  }
  return Frbrrelationship.none;
}

/// `data_GLISSANDO` -> string.
String glissandoToStr(Glissando data) {
  switch (data.value) {
    case 1:
      return 'i';
    case 2:
      return 'm';
    case 3:
      return 't';
  }
  logWarning("Unknown value '${data.value}' for data_GLISSANDO");
  return _unknownValue;
}

/// string -> `data_GLISSANDO`.
Glissando strToGlissando(String value) {
  if (value == 'i') return Glissando.i;
  if (value == 'm') return Glissando.m;
  if (value == 't') return Glissando.t;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_GLISSANDO");
  }
  return Glissando.none;
}

/// `data_GRACE` -> string.
String graceToStr(Grace data) {
  switch (data.value) {
    case 1:
      return 'acc';
    case 2:
      return 'unacc';
    case 3:
      return 'unknown';
  }
  logWarning("Unknown value '${data.value}' for data_GRACE");
  return _unknownValue;
}

/// string -> `data_GRACE`.
Grace strToGrace(String value) {
  if (value == 'acc') return Grace.acc;
  if (value == 'unacc') return Grace.unacc;
  if (value == 'unknown') return Grace.unknown;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_GRACE");
  }
  return Grace.none;
}

/// `data_HARPPEDALPOSITION` -> string.
String harppedalpositionToStr(Harppedalposition data) {
  switch (data.value) {
    case 1:
      return 'f';
    case 2:
      return 'n';
    case 3:
      return 's';
  }
  logWarning("Unknown value '${data.value}' for data_HARPPEDALPOSITION");
  return _unknownValue;
}

/// string -> `data_HARPPEDALPOSITION`.
Harppedalposition strToHarppedalposition(String value) {
  if (value == 'f') return Harppedalposition.f;
  if (value == 'n') return Harppedalposition.n;
  if (value == 's') return Harppedalposition.s;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_HARPPEDALPOSITION");
  }
  return Harppedalposition.none;
}

/// `data_HEADSHAPE_list` -> string.
String headshapeListToStr(HeadshapeList data) {
  switch (data.value) {
    case 1:
      return 'quarter';
    case 2:
      return 'half';
    case 3:
      return 'whole';
    case 4:
      return 'backslash';
    case 5:
      return 'circle';
    case 6:
      return '+';
    case 7:
      return 'diamond';
    case 8:
      return 'isotriangle';
    case 9:
      return 'oval';
    case 10:
      return 'piewedge';
    case 11:
      return 'rectangle';
    case 12:
      return 'rtriangle';
    case 13:
      return 'semicircle';
    case 14:
      return 'slash';
    case 15:
      return 'square';
    case 16:
      return 'x';
  }
  logWarning("Unknown value '${data.value}' for data_HEADSHAPE_list");
  return _unknownValue;
}

/// string -> `data_HEADSHAPE_list`.
HeadshapeList strToHeadshapeList(String value) {
  if (value == 'quarter') return HeadshapeList.quarter;
  if (value == 'half') return HeadshapeList.half;
  if (value == 'whole') return HeadshapeList.whole;
  if (value == 'backslash') return HeadshapeList.backslash;
  if (value == 'circle') return HeadshapeList.circle;
  if (value == '+') return HeadshapeList.plus;
  if (value == 'diamond') return HeadshapeList.diamond;
  if (value == 'isotriangle') return HeadshapeList.isotriangle;
  if (value == 'oval') return HeadshapeList.oval;
  if (value == 'piewedge') return HeadshapeList.piewedge;
  if (value == 'rectangle') return HeadshapeList.rectangle;
  if (value == 'rtriangle') return HeadshapeList.rtriangle;
  if (value == 'semicircle') return HeadshapeList.semicircle;
  if (value == 'slash') return HeadshapeList.slash;
  if (value == 'square') return HeadshapeList.square;
  if (value == 'x') return HeadshapeList.x;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_HEADSHAPE_list");
  }
  return HeadshapeList.none;
}

/// `data_HORIZONTALALIGNMENT` -> string.
String horizontalalignmentToStr(Horizontalalignment data) {
  switch (data.value) {
    case 1:
      return 'left';
    case 2:
      return 'right';
    case 3:
      return 'center';
    case 4:
      return 'justify';
  }
  logWarning("Unknown value '${data.value}' for data_HORIZONTALALIGNMENT");
  return _unknownValue;
}

/// string -> `data_HORIZONTALALIGNMENT`.
Horizontalalignment strToHorizontalalignment(String value) {
  if (value == 'left') return Horizontalalignment.left;
  if (value == 'right') return Horizontalalignment.right;
  if (value == 'center') return Horizontalalignment.center;
  if (value == 'justify') return Horizontalalignment.justify;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_HORIZONTALALIGNMENT");
  }
  return Horizontalalignment.none;
}

/// `data_LAYERSCHEME` -> string.
String layerschemeToStr(Layerscheme data) {
  switch (data.value) {
    case 1:
      return '1';
    case 2:
      return '2o';
    case 3:
      return '2f';
    case 4:
      return '3o';
    case 5:
      return '3f';
  }
  logWarning("Unknown value '${data.value}' for data_LAYERSCHEME");
  return _unknownValue;
}

/// string -> `data_LAYERSCHEME`.
Layerscheme strToLayerscheme(String value) {
  if (value == '1') return Layerscheme.n1;
  if (value == '2o') return Layerscheme.n2o;
  if (value == '2f') return Layerscheme.n2f;
  if (value == '3o') return Layerscheme.n3o;
  if (value == '3f') return Layerscheme.n3f;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_LAYERSCHEME");
  }
  return Layerscheme.none;
}

/// `data_LIGATUREFORM` -> string.
String ligatureformToStr(Ligatureform data) {
  switch (data.value) {
    case 1:
      return 'recta';
    case 2:
      return 'obliqua';
  }
  logWarning("Unknown value '${data.value}' for data_LIGATUREFORM");
  return _unknownValue;
}

/// string -> `data_LIGATUREFORM`.
Ligatureform strToLigatureform(String value) {
  if (value == 'recta') return Ligatureform.recta;
  if (value == 'obliqua') return Ligatureform.obliqua;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_LIGATUREFORM");
  }
  return Ligatureform.none;
}

/// `data_LINEFORM` -> string.
String lineformToStr(Lineform data) {
  switch (data.value) {
    case 1:
      return 'dashed';
    case 2:
      return 'dotted';
    case 3:
      return 'solid';
    case 4:
      return 'wavy';
  }
  logWarning("Unknown value '${data.value}' for data_LINEFORM");
  return _unknownValue;
}

/// string -> `data_LINEFORM`.
Lineform strToLineform(String value) {
  if (value == 'dashed') return Lineform.dashed;
  if (value == 'dotted') return Lineform.dotted;
  if (value == 'solid') return Lineform.solid;
  if (value == 'wavy') return Lineform.wavy;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_LINEFORM");
  }
  return Lineform.none;
}

/// `data_LINESTARTENDSYMBOL` -> string.
String linestartendsymbolToStr(Linestartendsymbol data) {
  switch (data.value) {
    case 1:
      return 'angledown';
    case 2:
      return 'angleup';
    case 3:
      return 'angleright';
    case 4:
      return 'angleleft';
    case 5:
      return 'arrow';
    case 6:
      return 'arrowopen';
    case 7:
      return 'arrowwhite';
    case 8:
      return 'harpoonleft';
    case 9:
      return 'harpoonright';
    case 10:
      return 'H';
    case 11:
      return 'N';
    case 12:
      return 'Th';
    case 13:
      return 'ThRetro';
    case 14:
      return 'ThRetroInv';
    case 15:
      return 'ThInv';
    case 16:
      return 'T';
    case 17:
      return 'TInv';
    case 18:
      return 'CH';
    case 19:
      return 'RH';
    case 20:
      return 'none';
  }
  logWarning("Unknown value '${data.value}' for data_LINESTARTENDSYMBOL");
  return _unknownValue;
}

/// string -> `data_LINESTARTENDSYMBOL`.
Linestartendsymbol strToLinestartendsymbol(String value) {
  if (value == 'angledown') return Linestartendsymbol.angledown;
  if (value == 'angleup') return Linestartendsymbol.angleup;
  if (value == 'angleright') return Linestartendsymbol.angleright;
  if (value == 'angleleft') return Linestartendsymbol.angleleft;
  if (value == 'arrow') return Linestartendsymbol.arrow;
  if (value == 'arrowopen') return Linestartendsymbol.arrowopen;
  if (value == 'arrowwhite') return Linestartendsymbol.arrowwhite;
  if (value == 'harpoonleft') return Linestartendsymbol.harpoonleft;
  if (value == 'harpoonright') return Linestartendsymbol.harpoonright;
  if (value == 'H') return Linestartendsymbol.h;
  if (value == 'N') return Linestartendsymbol.n;
  if (value == 'Th') return Linestartendsymbol.th;
  if (value == 'ThRetro') return Linestartendsymbol.thretro;
  if (value == 'ThRetroInv') return Linestartendsymbol.thretroinv;
  if (value == 'ThInv') return Linestartendsymbol.thinv;
  if (value == 'T') return Linestartendsymbol.t;
  if (value == 'TInv') return Linestartendsymbol.tinv;
  if (value == 'CH') return Linestartendsymbol.ch;
  if (value == 'RH') return Linestartendsymbol.rh;
  if (value == 'none') return Linestartendsymbol.none0;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_LINESTARTENDSYMBOL");
  }
  return Linestartendsymbol.none;
}

/// `data_LINEWIDTHTERM` -> string.
String linewidthtermToStr(Linewidthterm data) {
  switch (data.value) {
    case 1:
      return 'narrow';
    case 2:
      return 'medium';
    case 3:
      return 'wide';
  }
  logWarning("Unknown value '${data.value}' for data_LINEWIDTHTERM");
  return _unknownValue;
}

/// string -> `data_LINEWIDTHTERM`.
Linewidthterm strToLinewidthterm(String value) {
  if (value == 'narrow') return Linewidthterm.narrow;
  if (value == 'medium') return Linewidthterm.medium;
  if (value == 'wide') return Linewidthterm.wide;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_LINEWIDTHTERM");
  }
  return Linewidthterm.none;
}

/// `data_MARCRELATORS_basic` -> string.
String marcrelatorsBasicToStr(MarcrelatorsBasic data) {
  switch (data.value) {
    case 1:
      return 'arr';
    case 2:
      return 'aut';
    case 3:
      return 'cmp';
    case 4:
      return 'dte';
    case 5:
      return 'edt';
    case 6:
      return 'lbt';
    case 7:
      return 'lyr';
  }
  logWarning("Unknown value '${data.value}' for data_MARCRELATORS_basic");
  return _unknownValue;
}

/// string -> `data_MARCRELATORS_basic`.
MarcrelatorsBasic strToMarcrelatorsBasic(String value) {
  if (value == 'arr') return MarcrelatorsBasic.arr;
  if (value == 'aut') return MarcrelatorsBasic.aut;
  if (value == 'cmp') return MarcrelatorsBasic.cmp;
  if (value == 'dte') return MarcrelatorsBasic.dte;
  if (value == 'edt') return MarcrelatorsBasic.edt;
  if (value == 'lbt') return MarcrelatorsBasic.lbt;
  if (value == 'lyr') return MarcrelatorsBasic.lyr;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MARCRELATORS_basic");
  }
  return MarcrelatorsBasic.none;
}

/// `data_MARCRELATORS_extended` -> string.
String marcrelatorsExtendedToStr(MarcrelatorsExtended data) {
  switch (data.value) {
    case 1:
      return 'act';
    case 2:
      return 'ard';
    case 3:
      return 'art';
    case 4:
      return 'aus';
    case 5:
      return 'chr';
    case 6:
      return 'cnd';
    case 7:
      return 'crp';
    case 8:
      return 'cst';
    case 9:
      return 'drt';
    case 10:
      return 'egr';
    case 11:
      return 'flm';
    case 12:
      return 'fmd';
    case 13:
      return 'fmp';
    case 14:
      return 'itr';
    case 15:
      return 'mcp';
    case 16:
      return 'mus';
    case 17:
      return 'msd';
    case 18:
      return 'pdr';
    case 19:
      return 'pmn';
    case 20:
      return 'prn';
    case 21:
      return 'pro';
    case 22:
      return 'rce';
    case 23:
      return 'scr';
    case 24:
      return 'sng';
    case 25:
      return 'std';
    case 26:
      return 'trc';
    case 27:
      return 'trl';
  }
  logWarning("Unknown value '${data.value}' for data_MARCRELATORS_extended");
  return _unknownValue;
}

/// string -> `data_MARCRELATORS_extended`.
MarcrelatorsExtended strToMarcrelatorsExtended(String value) {
  if (value == 'act') return MarcrelatorsExtended.act;
  if (value == 'ard') return MarcrelatorsExtended.ard;
  if (value == 'art') return MarcrelatorsExtended.art;
  if (value == 'aus') return MarcrelatorsExtended.aus;
  if (value == 'chr') return MarcrelatorsExtended.chr;
  if (value == 'cnd') return MarcrelatorsExtended.cnd;
  if (value == 'crp') return MarcrelatorsExtended.crp;
  if (value == 'cst') return MarcrelatorsExtended.cst;
  if (value == 'drt') return MarcrelatorsExtended.drt;
  if (value == 'egr') return MarcrelatorsExtended.egr;
  if (value == 'flm') return MarcrelatorsExtended.flm;
  if (value == 'fmd') return MarcrelatorsExtended.fmd;
  if (value == 'fmp') return MarcrelatorsExtended.fmp;
  if (value == 'itr') return MarcrelatorsExtended.itr;
  if (value == 'mcp') return MarcrelatorsExtended.mcp;
  if (value == 'mus') return MarcrelatorsExtended.mus;
  if (value == 'msd') return MarcrelatorsExtended.msd;
  if (value == 'pdr') return MarcrelatorsExtended.pdr;
  if (value == 'pmn') return MarcrelatorsExtended.pmn;
  if (value == 'prn') return MarcrelatorsExtended.prn;
  if (value == 'pro') return MarcrelatorsExtended.pro;
  if (value == 'rce') return MarcrelatorsExtended.rce;
  if (value == 'scr') return MarcrelatorsExtended.scr;
  if (value == 'sng') return MarcrelatorsExtended.sng;
  if (value == 'std') return MarcrelatorsExtended.std;
  if (value == 'trc') return MarcrelatorsExtended.trc;
  if (value == 'trl') return MarcrelatorsExtended.trl;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MARCRELATORS_extended");
  }
  return MarcrelatorsExtended.none;
}

/// `data_MELODICFUNCTION` -> string.
String melodicfunctionToStr(Melodicfunction data) {
  switch (data.value) {
    case 1:
      return 'aln';
    case 2:
      return 'ant';
    case 3:
      return 'app';
    case 4:
      return 'apt';
    case 5:
      return 'arp';
    case 6:
      return 'arp7';
    case 7:
      return 'aun';
    case 8:
      return 'chg';
    case 9:
      return 'cln';
    case 10:
      return 'ct';
    case 11:
      return 'ct7';
    case 12:
      return 'cun';
    case 13:
      return 'cup';
    case 14:
      return 'et';
    case 15:
      return 'ln';
    case 16:
      return 'ped';
    case 17:
      return 'rep';
    case 18:
      return 'ret';
    case 19:
      return '23ret';
    case 20:
      return '78ret';
    case 21:
      return 'sus';
    case 22:
      return '43sus';
    case 23:
      return '98sus';
    case 24:
      return '76sus';
    case 25:
      return 'un';
    case 26:
      return 'un7';
    case 27:
      return 'upt';
    case 28:
      return 'upt7';
  }
  logWarning("Unknown value '${data.value}' for data_MELODICFUNCTION");
  return _unknownValue;
}

/// string -> `data_MELODICFUNCTION`.
Melodicfunction strToMelodicfunction(String value) {
  if (value == 'aln') return Melodicfunction.aln;
  if (value == 'ant') return Melodicfunction.ant;
  if (value == 'app') return Melodicfunction.app;
  if (value == 'apt') return Melodicfunction.apt;
  if (value == 'arp') return Melodicfunction.arp;
  if (value == 'arp7') return Melodicfunction.arp7;
  if (value == 'aun') return Melodicfunction.aun;
  if (value == 'chg') return Melodicfunction.chg;
  if (value == 'cln') return Melodicfunction.cln;
  if (value == 'ct') return Melodicfunction.ct;
  if (value == 'ct7') return Melodicfunction.ct7;
  if (value == 'cun') return Melodicfunction.cun;
  if (value == 'cup') return Melodicfunction.cup;
  if (value == 'et') return Melodicfunction.et;
  if (value == 'ln') return Melodicfunction.ln;
  if (value == 'ped') return Melodicfunction.ped;
  if (value == 'rep') return Melodicfunction.rep;
  if (value == 'ret') return Melodicfunction.ret;
  if (value == '23ret') return Melodicfunction.n23ret;
  if (value == '78ret') return Melodicfunction.n78ret;
  if (value == 'sus') return Melodicfunction.sus;
  if (value == '43sus') return Melodicfunction.n43sus;
  if (value == '98sus') return Melodicfunction.n98sus;
  if (value == '76sus') return Melodicfunction.n76sus;
  if (value == 'un') return Melodicfunction.un;
  if (value == 'un7') return Melodicfunction.un7;
  if (value == 'upt') return Melodicfunction.upt;
  if (value == 'upt7') return Melodicfunction.upt7;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MELODICFUNCTION");
  }
  return Melodicfunction.none;
}

/// `data_MENSURATIONSIGN` -> string.
String mensurationsignToStr(Mensurationsign data) {
  switch (data.value) {
    case 1:
      return 'C';
    case 2:
      return 'O';
    case 3:
      return 't';
    case 4:
      return 'q';
    case 5:
      return 'si';
    case 6:
      return 'i';
    case 7:
      return 'sg';
    case 8:
      return 'g';
    case 9:
      return 'sp';
    case 10:
      return 'p';
    case 11:
      return 'sy';
    case 12:
      return 'y';
    case 13:
      return 'n';
    case 14:
      return 'oc';
    case 15:
      return 'd';
  }
  logWarning("Unknown value '${data.value}' for data_MENSURATIONSIGN");
  return _unknownValue;
}

/// string -> `data_MENSURATIONSIGN`.
Mensurationsign strToMensurationsign(String value) {
  if (value == 'C') return Mensurationsign.c;
  if (value == 'O') return Mensurationsign.o;
  if (value == 't') return Mensurationsign.t;
  if (value == 'q') return Mensurationsign.q;
  if (value == 'si') return Mensurationsign.si;
  if (value == 'i') return Mensurationsign.i;
  if (value == 'sg') return Mensurationsign.sg;
  if (value == 'g') return Mensurationsign.g;
  if (value == 'sp') return Mensurationsign.sp;
  if (value == 'p') return Mensurationsign.p;
  if (value == 'sy') return Mensurationsign.sy;
  if (value == 'y') return Mensurationsign.y;
  if (value == 'n') return Mensurationsign.n;
  if (value == 'oc') return Mensurationsign.oc;
  if (value == 'd') return Mensurationsign.d;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MENSURATIONSIGN");
  }
  return Mensurationsign.none;
}

/// `data_METERFORM` -> string.
String meterformToStr(Meterform data) {
  switch (data.value) {
    case 1:
      return 'num';
    case 2:
      return 'denomsym';
    case 3:
      return 'norm';
    case 4:
      return 'sym+norm';
  }
  logWarning("Unknown value '${data.value}' for data_METERFORM");
  return _unknownValue;
}

/// string -> `data_METERFORM`.
Meterform strToMeterform(String value) {
  if (value == 'num') return Meterform.num;
  if (value == 'denomsym') return Meterform.denomsym;
  if (value == 'norm') return Meterform.norm;
  if (value == 'sym+norm') return Meterform.symplusnorm;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_METERFORM");
  }
  return Meterform.none;
}

/// `data_METERSIGN` -> string.
String metersignToStr(Metersign data) {
  switch (data.value) {
    case 1:
      return 'common';
    case 2:
      return 'cut';
    case 3:
      return 'open';
  }
  logWarning("Unknown value '${data.value}' for data_METERSIGN");
  return _unknownValue;
}

/// string -> `data_METERSIGN`.
Metersign strToMetersign(String value) {
  if (value == 'common') return Metersign.common;
  if (value == 'cut') return Metersign.cut;
  if (value == 'open') return Metersign.open;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_METERSIGN");
  }
  return Metersign.none;
}

/// `data_MIDINAMES` -> string.
String midinamesToStr(Midinames data) {
  switch (data.value) {
    case 1:
      return 'Acoustic_Grand_Piano';
    case 2:
      return 'Bright_Acoustic_Piano';
    case 3:
      return 'Electric_Grand_Piano';
    case 4:
      return 'Honky-tonk_Piano';
    case 5:
      return 'Electric_Piano_1';
    case 6:
      return 'Electric_Piano_2';
    case 7:
      return 'Harpsichord';
    case 8:
      return 'Clavi';
    case 9:
      return 'Celesta';
    case 10:
      return 'Glockenspiel';
    case 11:
      return 'Music_Box';
    case 12:
      return 'Vibraphone';
    case 13:
      return 'Marimba';
    case 14:
      return 'Xylophone';
    case 15:
      return 'Tubular_Bells';
    case 16:
      return 'Dulcimer';
    case 17:
      return 'Drawbar_Organ';
    case 18:
      return 'Percussive_Organ';
    case 19:
      return 'Rock_Organ';
    case 20:
      return 'Church_Organ';
    case 21:
      return 'Reed_Organ';
    case 22:
      return 'Accordion';
    case 23:
      return 'Harmonica';
    case 24:
      return 'Tango_Accordion';
    case 25:
      return 'Acoustic_Guitar_nylon';
    case 26:
      return 'Acoustic_Guitar_steel';
    case 27:
      return 'Electric_Guitar_jazz';
    case 28:
      return 'Electric_Guitar_clean';
    case 29:
      return 'Electric_Guitar_muted';
    case 30:
      return 'Overdriven_Guitar';
    case 31:
      return 'Distortion_Guitar';
    case 32:
      return 'Guitar_harmonics';
    case 33:
      return 'Acoustic_Bass';
    case 34:
      return 'Electric_Bass_finger';
    case 35:
      return 'Electric_Bass_pick';
    case 36:
      return 'Fretless_Bass';
    case 37:
      return 'Slap_Bass_1';
    case 38:
      return 'Slap_Bass_2';
    case 39:
      return 'Synth_Bass_1';
    case 40:
      return 'Synth_Bass_2';
    case 41:
      return 'Violin';
    case 42:
      return 'Viola';
    case 43:
      return 'Cello';
    case 44:
      return 'Contrabass';
    case 45:
      return 'Tremolo_Strings';
    case 46:
      return 'Pizzicato_Strings';
    case 47:
      return 'Orchestral_Harp';
    case 48:
      return 'Timpani';
    case 49:
      return 'String_Ensemble_1';
    case 50:
      return 'String_Ensemble_2';
    case 51:
      return 'SynthStrings_1';
    case 52:
      return 'SynthStrings_2';
    case 53:
      return 'Choir_Aahs';
    case 54:
      return 'Voice_Oohs';
    case 55:
      return 'Synth_Voice';
    case 56:
      return 'Orchestra_Hit';
    case 57:
      return 'Trumpet';
    case 58:
      return 'Trombone';
    case 59:
      return 'Tuba';
    case 60:
      return 'Muted_Trumpet';
    case 61:
      return 'French_Horn';
    case 62:
      return 'Brass_Section';
    case 63:
      return 'SynthBrass_1';
    case 64:
      return 'SynthBrass_2';
    case 65:
      return 'Soprano_Sax';
    case 66:
      return 'Alto_Sax';
    case 67:
      return 'Tenor_Sax';
    case 68:
      return 'Baritone_Sax';
    case 69:
      return 'Oboe';
    case 70:
      return 'English_Horn';
    case 71:
      return 'Bassoon';
    case 72:
      return 'Clarinet';
    case 73:
      return 'Piccolo';
    case 74:
      return 'Flute';
    case 75:
      return 'Recorder';
    case 76:
      return 'Pan_Flute';
    case 77:
      return 'Blown_Bottle';
    case 78:
      return 'Shakuhachi';
    case 79:
      return 'Whistle';
    case 80:
      return 'Ocarina';
    case 81:
      return 'Lead_1_square';
    case 82:
      return 'Lead_2_sawtooth';
    case 83:
      return 'Lead_3_calliope';
    case 84:
      return 'Lead_4_chiff';
    case 85:
      return 'Lead_5_charang';
    case 86:
      return 'Lead_6_voice';
    case 87:
      return 'Lead_7_fifths';
    case 88:
      return 'Lead_8_bass_and_lead';
    case 89:
      return 'Pad_1_new_age';
    case 90:
      return 'Pad_2_warm';
    case 91:
      return 'Pad_3_polysynth';
    case 92:
      return 'Pad_4_choir';
    case 93:
      return 'Pad_5_bowed';
    case 94:
      return 'Pad_6_metallic';
    case 95:
      return 'Pad_7_halo';
    case 96:
      return 'Pad_8_sweep';
    case 97:
      return 'FX_1_rain';
    case 98:
      return 'FX_2_soundtrack';
    case 99:
      return 'FX_3_crystal';
    case 100:
      return 'FX_4_atmosphere';
    case 101:
      return 'FX_5_brightness';
    case 102:
      return 'FX_6_goblins';
    case 103:
      return 'FX_7_echoes';
    case 104:
      return 'FX_8_sci-fi';
    case 105:
      return 'Sitar';
    case 106:
      return 'Banjo';
    case 107:
      return 'Shamisen';
    case 108:
      return 'Koto';
    case 109:
      return 'Kalimba';
    case 110:
      return 'Bag_pipe';
    case 111:
      return 'Fiddle';
    case 112:
      return 'Shanai';
    case 113:
      return 'Tinkle_Bell';
    case 114:
      return 'Agogo';
    case 115:
      return 'Steel_Drums';
    case 116:
      return 'Woodblock';
    case 117:
      return 'Taiko_Drum';
    case 118:
      return 'Melodic_Tom';
    case 119:
      return 'Synth_Drum';
    case 120:
      return 'Reverse_Cymbal';
    case 121:
      return 'Guitar_Fret_Noise';
    case 122:
      return 'Breath_Noise';
    case 123:
      return 'Seashore';
    case 124:
      return 'Bird_Tweet';
    case 125:
      return 'Telephone_Ring';
    case 126:
      return 'Helicopter';
    case 127:
      return 'Applause';
    case 128:
      return 'Gunshot';
    case 129:
      return 'Acoustic_Bass_Drum';
    case 130:
      return 'Bass_Drum_1';
    case 131:
      return 'Side_Stick';
    case 132:
      return 'Acoustic_Snare';
    case 133:
      return 'Hand_Clap';
    case 134:
      return 'Electric_Snare';
    case 135:
      return 'Low_Floor_Tom';
    case 136:
      return 'Closed_Hi_Hat';
    case 137:
      return 'High_Floor_Tom';
    case 138:
      return 'Pedal_Hi-Hat';
    case 139:
      return 'Low_Tom';
    case 140:
      return 'Open_Hi-Hat';
    case 141:
      return 'Low-Mid_Tom';
    case 142:
      return 'Hi-Mid_Tom';
    case 143:
      return 'Crash_Cymbal_1';
    case 144:
      return 'High_Tom';
    case 145:
      return 'Ride_Cymbal_1';
    case 146:
      return 'Chinese_Cymbal';
    case 147:
      return 'Ride_Bell';
    case 148:
      return 'Tambourine';
    case 149:
      return 'Splash_Cymbal';
    case 150:
      return 'Cowbell';
    case 151:
      return 'Crash_Cymbal_2';
    case 152:
      return 'Vibraslap';
    case 153:
      return 'Ride_Cymbal_2';
    case 154:
      return 'Hi_Bongo';
    case 155:
      return 'Low_Bongo';
    case 156:
      return 'Mute_Hi_Conga';
    case 157:
      return 'Open_Hi_Conga';
    case 158:
      return 'Low_Conga';
    case 159:
      return 'High_Timbale';
    case 160:
      return 'Low_Timbale';
    case 161:
      return 'High_Agogo';
    case 162:
      return 'Low_Agogo';
    case 163:
      return 'Cabasa';
    case 164:
      return 'Maracas';
    case 165:
      return 'Short_Whistle';
    case 166:
      return 'Long_Whistle';
    case 167:
      return 'Short_Guiro';
    case 168:
      return 'Long_Guiro';
    case 169:
      return 'Claves';
    case 170:
      return 'Hi_Wood_Block';
    case 171:
      return 'Low_Wood_Block';
    case 172:
      return 'Mute_Cuica';
    case 173:
      return 'Open_Cuica';
    case 174:
      return 'Mute_Triangle';
    case 175:
      return 'Open_Triangle';
  }
  logWarning("Unknown value '${data.value}' for data_MIDINAMES");
  return _unknownValue;
}

/// string -> `data_MIDINAMES`.
Midinames strToMidinames(String value) {
  if (value == 'Acoustic_Grand_Piano') return Midinames.acousticGrandPiano;
  if (value == 'Bright_Acoustic_Piano') return Midinames.brightAcousticPiano;
  if (value == 'Electric_Grand_Piano') return Midinames.electricGrandPiano;
  if (value == 'Honky-tonk_Piano') return Midinames.honkyTonkPiano;
  if (value == 'Electric_Piano_1') return Midinames.electricPiano1;
  if (value == 'Electric_Piano_2') return Midinames.electricPiano2;
  if (value == 'Harpsichord') return Midinames.harpsichord;
  if (value == 'Clavi') return Midinames.clavi;
  if (value == 'Celesta') return Midinames.celesta;
  if (value == 'Glockenspiel') return Midinames.glockenspiel;
  if (value == 'Music_Box') return Midinames.musicBox;
  if (value == 'Vibraphone') return Midinames.vibraphone;
  if (value == 'Marimba') return Midinames.marimba;
  if (value == 'Xylophone') return Midinames.xylophone;
  if (value == 'Tubular_Bells') return Midinames.tubularBells;
  if (value == 'Dulcimer') return Midinames.dulcimer;
  if (value == 'Drawbar_Organ') return Midinames.drawbarOrgan;
  if (value == 'Percussive_Organ') return Midinames.percussiveOrgan;
  if (value == 'Rock_Organ') return Midinames.rockOrgan;
  if (value == 'Church_Organ') return Midinames.churchOrgan;
  if (value == 'Reed_Organ') return Midinames.reedOrgan;
  if (value == 'Accordion') return Midinames.accordion;
  if (value == 'Harmonica') return Midinames.harmonica;
  if (value == 'Tango_Accordion') return Midinames.tangoAccordion;
  if (value == 'Acoustic_Guitar_nylon') return Midinames.acousticGuitarNylon;
  if (value == 'Acoustic_Guitar_steel') return Midinames.acousticGuitarSteel;
  if (value == 'Electric_Guitar_jazz') return Midinames.electricGuitarJazz;
  if (value == 'Electric_Guitar_clean') return Midinames.electricGuitarClean;
  if (value == 'Electric_Guitar_muted') return Midinames.electricGuitarMuted;
  if (value == 'Overdriven_Guitar') return Midinames.overdrivenGuitar;
  if (value == 'Distortion_Guitar') return Midinames.distortionGuitar;
  if (value == 'Guitar_harmonics') return Midinames.guitarHarmonics;
  if (value == 'Acoustic_Bass') return Midinames.acousticBass;
  if (value == 'Electric_Bass_finger') return Midinames.electricBassFinger;
  if (value == 'Electric_Bass_pick') return Midinames.electricBassPick;
  if (value == 'Fretless_Bass') return Midinames.fretlessBass;
  if (value == 'Slap_Bass_1') return Midinames.slapBass1;
  if (value == 'Slap_Bass_2') return Midinames.slapBass2;
  if (value == 'Synth_Bass_1') return Midinames.synthBass1;
  if (value == 'Synth_Bass_2') return Midinames.synthBass2;
  if (value == 'Violin') return Midinames.violin;
  if (value == 'Viola') return Midinames.viola;
  if (value == 'Cello') return Midinames.cello;
  if (value == 'Contrabass') return Midinames.contrabass;
  if (value == 'Tremolo_Strings') return Midinames.tremoloStrings;
  if (value == 'Pizzicato_Strings') return Midinames.pizzicatoStrings;
  if (value == 'Orchestral_Harp') return Midinames.orchestralHarp;
  if (value == 'Timpani') return Midinames.timpani;
  if (value == 'String_Ensemble_1') return Midinames.stringEnsemble1;
  if (value == 'String_Ensemble_2') return Midinames.stringEnsemble2;
  if (value == 'SynthStrings_1') return Midinames.synthstrings1;
  if (value == 'SynthStrings_2') return Midinames.synthstrings2;
  if (value == 'Choir_Aahs') return Midinames.choirAahs;
  if (value == 'Voice_Oohs') return Midinames.voiceOohs;
  if (value == 'Synth_Voice') return Midinames.synthVoice;
  if (value == 'Orchestra_Hit') return Midinames.orchestraHit;
  if (value == 'Trumpet') return Midinames.trumpet;
  if (value == 'Trombone') return Midinames.trombone;
  if (value == 'Tuba') return Midinames.tuba;
  if (value == 'Muted_Trumpet') return Midinames.mutedTrumpet;
  if (value == 'French_Horn') return Midinames.frenchHorn;
  if (value == 'Brass_Section') return Midinames.brassSection;
  if (value == 'SynthBrass_1') return Midinames.synthbrass1;
  if (value == 'SynthBrass_2') return Midinames.synthbrass2;
  if (value == 'Soprano_Sax') return Midinames.sopranoSax;
  if (value == 'Alto_Sax') return Midinames.altoSax;
  if (value == 'Tenor_Sax') return Midinames.tenorSax;
  if (value == 'Baritone_Sax') return Midinames.baritoneSax;
  if (value == 'Oboe') return Midinames.oboe;
  if (value == 'English_Horn') return Midinames.englishHorn;
  if (value == 'Bassoon') return Midinames.bassoon;
  if (value == 'Clarinet') return Midinames.clarinet;
  if (value == 'Piccolo') return Midinames.piccolo;
  if (value == 'Flute') return Midinames.flute;
  if (value == 'Recorder') return Midinames.recorder;
  if (value == 'Pan_Flute') return Midinames.panFlute;
  if (value == 'Blown_Bottle') return Midinames.blownBottle;
  if (value == 'Shakuhachi') return Midinames.shakuhachi;
  if (value == 'Whistle') return Midinames.whistle;
  if (value == 'Ocarina') return Midinames.ocarina;
  if (value == 'Lead_1_square') return Midinames.lead1Square;
  if (value == 'Lead_2_sawtooth') return Midinames.lead2Sawtooth;
  if (value == 'Lead_3_calliope') return Midinames.lead3Calliope;
  if (value == 'Lead_4_chiff') return Midinames.lead4Chiff;
  if (value == 'Lead_5_charang') return Midinames.lead5Charang;
  if (value == 'Lead_6_voice') return Midinames.lead6Voice;
  if (value == 'Lead_7_fifths') return Midinames.lead7Fifths;
  if (value == 'Lead_8_bass_and_lead') return Midinames.lead8BassAndLead;
  if (value == 'Pad_1_new_age') return Midinames.pad1NewAge;
  if (value == 'Pad_2_warm') return Midinames.pad2Warm;
  if (value == 'Pad_3_polysynth') return Midinames.pad3Polysynth;
  if (value == 'Pad_4_choir') return Midinames.pad4Choir;
  if (value == 'Pad_5_bowed') return Midinames.pad5Bowed;
  if (value == 'Pad_6_metallic') return Midinames.pad6Metallic;
  if (value == 'Pad_7_halo') return Midinames.pad7Halo;
  if (value == 'Pad_8_sweep') return Midinames.pad8Sweep;
  if (value == 'FX_1_rain') return Midinames.fx1Rain;
  if (value == 'FX_2_soundtrack') return Midinames.fx2Soundtrack;
  if (value == 'FX_3_crystal') return Midinames.fx3Crystal;
  if (value == 'FX_4_atmosphere') return Midinames.fx4Atmosphere;
  if (value == 'FX_5_brightness') return Midinames.fx5Brightness;
  if (value == 'FX_6_goblins') return Midinames.fx6Goblins;
  if (value == 'FX_7_echoes') return Midinames.fx7Echoes;
  if (value == 'FX_8_sci-fi') return Midinames.fx8SciFi;
  if (value == 'Sitar') return Midinames.sitar;
  if (value == 'Banjo') return Midinames.banjo;
  if (value == 'Shamisen') return Midinames.shamisen;
  if (value == 'Koto') return Midinames.koto;
  if (value == 'Kalimba') return Midinames.kalimba;
  if (value == 'Bag_pipe') return Midinames.bagPipe;
  if (value == 'Fiddle') return Midinames.fiddle;
  if (value == 'Shanai') return Midinames.shanai;
  if (value == 'Tinkle_Bell') return Midinames.tinkleBell;
  if (value == 'Agogo') return Midinames.agogo;
  if (value == 'Steel_Drums') return Midinames.steelDrums;
  if (value == 'Woodblock') return Midinames.woodblock;
  if (value == 'Taiko_Drum') return Midinames.taikoDrum;
  if (value == 'Melodic_Tom') return Midinames.melodicTom;
  if (value == 'Synth_Drum') return Midinames.synthDrum;
  if (value == 'Reverse_Cymbal') return Midinames.reverseCymbal;
  if (value == 'Guitar_Fret_Noise') return Midinames.guitarFretNoise;
  if (value == 'Breath_Noise') return Midinames.breathNoise;
  if (value == 'Seashore') return Midinames.seashore;
  if (value == 'Bird_Tweet') return Midinames.birdTweet;
  if (value == 'Telephone_Ring') return Midinames.telephoneRing;
  if (value == 'Helicopter') return Midinames.helicopter;
  if (value == 'Applause') return Midinames.applause;
  if (value == 'Gunshot') return Midinames.gunshot;
  if (value == 'Acoustic_Bass_Drum') return Midinames.acousticBassDrum;
  if (value == 'Bass_Drum_1') return Midinames.bassDrum1;
  if (value == 'Side_Stick') return Midinames.sideStick;
  if (value == 'Acoustic_Snare') return Midinames.acousticSnare;
  if (value == 'Hand_Clap') return Midinames.handClap;
  if (value == 'Electric_Snare') return Midinames.electricSnare;
  if (value == 'Low_Floor_Tom') return Midinames.lowFloorTom;
  if (value == 'Closed_Hi_Hat') return Midinames.closedHiHat;
  if (value == 'High_Floor_Tom') return Midinames.highFloorTom;
  if (value == 'Pedal_Hi-Hat') return Midinames.pedalHiHat;
  if (value == 'Low_Tom') return Midinames.lowTom;
  if (value == 'Open_Hi-Hat') return Midinames.openHiHat;
  if (value == 'Low-Mid_Tom') return Midinames.lowMidTom;
  if (value == 'Hi-Mid_Tom') return Midinames.hiMidTom;
  if (value == 'Crash_Cymbal_1') return Midinames.crashCymbal1;
  if (value == 'High_Tom') return Midinames.highTom;
  if (value == 'Ride_Cymbal_1') return Midinames.rideCymbal1;
  if (value == 'Chinese_Cymbal') return Midinames.chineseCymbal;
  if (value == 'Ride_Bell') return Midinames.rideBell;
  if (value == 'Tambourine') return Midinames.tambourine;
  if (value == 'Splash_Cymbal') return Midinames.splashCymbal;
  if (value == 'Cowbell') return Midinames.cowbell;
  if (value == 'Crash_Cymbal_2') return Midinames.crashCymbal2;
  if (value == 'Vibraslap') return Midinames.vibraslap;
  if (value == 'Ride_Cymbal_2') return Midinames.rideCymbal2;
  if (value == 'Hi_Bongo') return Midinames.hiBongo;
  if (value == 'Low_Bongo') return Midinames.lowBongo;
  if (value == 'Mute_Hi_Conga') return Midinames.muteHiConga;
  if (value == 'Open_Hi_Conga') return Midinames.openHiConga;
  if (value == 'Low_Conga') return Midinames.lowConga;
  if (value == 'High_Timbale') return Midinames.highTimbale;
  if (value == 'Low_Timbale') return Midinames.lowTimbale;
  if (value == 'High_Agogo') return Midinames.highAgogo;
  if (value == 'Low_Agogo') return Midinames.lowAgogo;
  if (value == 'Cabasa') return Midinames.cabasa;
  if (value == 'Maracas') return Midinames.maracas;
  if (value == 'Short_Whistle') return Midinames.shortWhistle;
  if (value == 'Long_Whistle') return Midinames.longWhistle;
  if (value == 'Short_Guiro') return Midinames.shortGuiro;
  if (value == 'Long_Guiro') return Midinames.longGuiro;
  if (value == 'Claves') return Midinames.claves;
  if (value == 'Hi_Wood_Block') return Midinames.hiWoodBlock;
  if (value == 'Low_Wood_Block') return Midinames.lowWoodBlock;
  if (value == 'Mute_Cuica') return Midinames.muteCuica;
  if (value == 'Open_Cuica') return Midinames.openCuica;
  if (value == 'Mute_Triangle') return Midinames.muteTriangle;
  if (value == 'Open_Triangle') return Midinames.openTriangle;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MIDINAMES");
  }
  return Midinames.none;
}

/// `data_MODE` -> string.
String modeToStr(Mode data) {
  switch (data.value) {
    case 1:
      return 'major';
    case 2:
      return 'minor';
    case 3:
      return 'dorian';
    case 4:
      return 'hypodorian';
    case 5:
      return 'phrygian';
    case 6:
      return 'hypophrygian';
    case 7:
      return 'lydian';
    case 8:
      return 'hypolydian';
    case 9:
      return 'mixolydian';
    case 10:
      return 'hypomixolydian';
    case 11:
      return 'peregrinus';
    case 12:
      return 'ionian';
    case 13:
      return 'hypoionian';
    case 14:
      return 'aeolian';
    case 15:
      return 'hypoaeolian';
    case 16:
      return 'locrian';
    case 17:
      return 'hypolocrian';
  }
  logWarning("Unknown value '${data.value}' for data_MODE");
  return _unknownValue;
}

/// string -> `data_MODE`.
Mode strToMode(String value) {
  if (value == 'major') return Mode.major;
  if (value == 'minor') return Mode.minor;
  if (value == 'dorian') return Mode.dorian;
  if (value == 'hypodorian') return Mode.hypodorian;
  if (value == 'phrygian') return Mode.phrygian;
  if (value == 'hypophrygian') return Mode.hypophrygian;
  if (value == 'lydian') return Mode.lydian;
  if (value == 'hypolydian') return Mode.hypolydian;
  if (value == 'mixolydian') return Mode.mixolydian;
  if (value == 'hypomixolydian') return Mode.hypomixolydian;
  if (value == 'peregrinus') return Mode.peregrinus;
  if (value == 'ionian') return Mode.ionian;
  if (value == 'hypoionian') return Mode.hypoionian;
  if (value == 'aeolian') return Mode.aeolian;
  if (value == 'hypoaeolian') return Mode.hypoaeolian;
  if (value == 'locrian') return Mode.locrian;
  if (value == 'hypolocrian') return Mode.hypolocrian;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MODE");
  }
  return Mode.none;
}

/// `data_MODE_cmn` -> string.
String modeCmnToStr(ModeCmn data) {
  switch (data.value) {
    case 1:
      return 'major';
    case 2:
      return 'minor';
  }
  logWarning("Unknown value '${data.value}' for data_MODE_cmn");
  return _unknownValue;
}

/// string -> `data_MODE_cmn`.
ModeCmn strToModeCmn(String value) {
  if (value == 'major') return ModeCmn.major;
  if (value == 'minor') return ModeCmn.minor;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MODE_cmn");
  }
  return ModeCmn.none;
}

/// `data_MODE_extended` -> string.
String modeExtendedToStr(ModeExtended data) {
  switch (data.value) {
    case 1:
      return 'ionian';
    case 2:
      return 'hypoionian';
    case 3:
      return 'aeolian';
    case 4:
      return 'hypoaeolian';
    case 5:
      return 'locrian';
    case 6:
      return 'hypolocrian';
  }
  logWarning("Unknown value '${data.value}' for data_MODE_extended");
  return _unknownValue;
}

/// string -> `data_MODE_extended`.
ModeExtended strToModeExtended(String value) {
  if (value == 'ionian') return ModeExtended.ionian;
  if (value == 'hypoionian') return ModeExtended.hypoionian;
  if (value == 'aeolian') return ModeExtended.aeolian;
  if (value == 'hypoaeolian') return ModeExtended.hypoaeolian;
  if (value == 'locrian') return ModeExtended.locrian;
  if (value == 'hypolocrian') return ModeExtended.hypolocrian;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MODE_extended");
  }
  return ModeExtended.none;
}

/// `data_MODE_gregorian` -> string.
String modeGregorianToStr(ModeGregorian data) {
  switch (data.value) {
    case 1:
      return 'dorian';
    case 2:
      return 'hypodorian';
    case 3:
      return 'phrygian';
    case 4:
      return 'hypophrygian';
    case 5:
      return 'lydian';
    case 6:
      return 'hypolydian';
    case 7:
      return 'mixolydian';
    case 8:
      return 'hypomixolydian';
    case 9:
      return 'peregrinus';
  }
  logWarning("Unknown value '${data.value}' for data_MODE_gregorian");
  return _unknownValue;
}

/// string -> `data_MODE_gregorian`.
ModeGregorian strToModeGregorian(String value) {
  if (value == 'dorian') return ModeGregorian.dorian;
  if (value == 'hypodorian') return ModeGregorian.hypodorian;
  if (value == 'phrygian') return ModeGregorian.phrygian;
  if (value == 'hypophrygian') return ModeGregorian.hypophrygian;
  if (value == 'lydian') return ModeGregorian.lydian;
  if (value == 'hypolydian') return ModeGregorian.hypolydian;
  if (value == 'mixolydian') return ModeGregorian.mixolydian;
  if (value == 'hypomixolydian') return ModeGregorian.hypomixolydian;
  if (value == 'peregrinus') return ModeGregorian.peregrinus;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MODE_gregorian");
  }
  return ModeGregorian.none;
}

/// `data_MODSRELATIONSHIP` -> string.
String modsrelationshipToStr(Modsrelationship data) {
  switch (data.value) {
    case 1:
      return 'preceding';
    case 2:
      return 'succeeding';
    case 3:
      return 'original';
    case 4:
      return 'host';
    case 5:
      return 'constituent';
    case 6:
      return 'otherVersion';
    case 7:
      return 'otherFormat';
    case 8:
      return 'isReferencedBy';
    case 9:
      return 'references';
  }
  logWarning("Unknown value '${data.value}' for data_MODSRELATIONSHIP");
  return _unknownValue;
}

/// string -> `data_MODSRELATIONSHIP`.
Modsrelationship strToModsrelationship(String value) {
  if (value == 'preceding') return Modsrelationship.preceding;
  if (value == 'succeeding') return Modsrelationship.succeeding;
  if (value == 'original') return Modsrelationship.original;
  if (value == 'host') return Modsrelationship.host;
  if (value == 'constituent') return Modsrelationship.constituent;
  if (value == 'otherVersion') return Modsrelationship.otherversion;
  if (value == 'otherFormat') return Modsrelationship.otherformat;
  if (value == 'isReferencedBy') return Modsrelationship.isreferencedby;
  if (value == 'references') return Modsrelationship.references;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MODSRELATIONSHIP");
  }
  return Modsrelationship.none;
}

/// `data_MODUSMAIOR` -> string.
String modusmaiorToStr(Modusmaior data) {
  switch (data.value) {
    case 2:
      return '2';
    case 3:
      return '3';
  }
  logWarning("Unknown value '${data.value}' for data_MODUSMAIOR");
  return _unknownValue;
}

/// string -> `data_MODUSMAIOR`.
Modusmaior strToModusmaior(String value) {
  if (value == '2') return Modusmaior.n2;
  if (value == '3') return Modusmaior.n3;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MODUSMAIOR");
  }
  return Modusmaior.none;
}

/// `data_MODUSMINOR` -> string.
String modusminorToStr(Modusminor data) {
  switch (data.value) {
    case 2:
      return '2';
    case 3:
      return '3';
  }
  logWarning("Unknown value '${data.value}' for data_MODUSMINOR");
  return _unknownValue;
}

/// string -> `data_MODUSMINOR`.
Modusminor strToModusminor(String value) {
  if (value == '2') return Modusminor.n2;
  if (value == '3') return Modusminor.n3;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MODUSMINOR");
  }
  return Modusminor.none;
}

/// `data_MULTIBREVERESTS_mensural` -> string.
String multibreverestsMensuralToStr(MultibreverestsMensural data) {
  switch (data.value) {
    case 1:
      return '2B';
    case 2:
      return '3B';
  }
  logWarning("Unknown value '${data.value}' for data_MULTIBREVERESTS_mensural");
  return _unknownValue;
}

/// string -> `data_MULTIBREVERESTS_mensural`.
MultibreverestsMensural strToMultibreverestsMensural(String value) {
  if (value == '2B') return MultibreverestsMensural.n2b;
  if (value == '3B') return MultibreverestsMensural.n3b;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_MULTIBREVERESTS_mensural");
  }
  return MultibreverestsMensural.none;
}

/// `data_NEIGHBORINGLAYER` -> string.
String neighboringlayerToStr(Neighboringlayer data) {
  switch (data.value) {
    case 1:
      return 'above';
    case 2:
      return 'below';
  }
  logWarning("Unknown value '${data.value}' for data_NEIGHBORINGLAYER");
  return _unknownValue;
}

/// string -> `data_NEIGHBORINGLAYER`.
Neighboringlayer strToNeighboringlayer(String value) {
  if (value == 'above') return Neighboringlayer.above;
  if (value == 'below') return Neighboringlayer.below;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_NEIGHBORINGLAYER");
  }
  return Neighboringlayer.none;
}

/// `data_NONSTAFFPLACE` -> string.
String nonstaffplaceToStr(Nonstaffplace data) {
  switch (data.value) {
    case 1:
      return 'botmar';
    case 2:
      return 'topmar';
    case 3:
      return 'leftmar';
    case 4:
      return 'rightmar';
    case 5:
      return 'facing';
    case 6:
      return 'overleaf';
    case 7:
      return 'end';
    case 8:
      return 'inter';
    case 9:
      return 'intra';
    case 10:
      return 'super';
    case 11:
      return 'sub';
    case 12:
      return 'inspace';
    case 13:
      return 'superimposed';
  }
  logWarning("Unknown value '${data.value}' for data_NONSTAFFPLACE");
  return _unknownValue;
}

/// string -> `data_NONSTAFFPLACE`.
Nonstaffplace strToNonstaffplace(String value) {
  if (value == 'botmar') return Nonstaffplace.botmar;
  if (value == 'topmar') return Nonstaffplace.topmar;
  if (value == 'leftmar') return Nonstaffplace.leftmar;
  if (value == 'rightmar') return Nonstaffplace.rightmar;
  if (value == 'facing') return Nonstaffplace.facing;
  if (value == 'overleaf') return Nonstaffplace.overleaf;
  if (value == 'end') return Nonstaffplace.end;
  if (value == 'inter') return Nonstaffplace.inter;
  if (value == 'intra') return Nonstaffplace.intra;
  if (value == 'super') return Nonstaffplace.superValue;
  if (value == 'sub') return Nonstaffplace.sub;
  if (value == 'inspace') return Nonstaffplace.inspace;
  if (value == 'superimposed') return Nonstaffplace.superimposed;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_NONSTAFFPLACE");
  }
  return Nonstaffplace.none;
}

/// `data_NOTATIONTYPE` -> string.
String notationtypeToStr(Notationtype data) {
  switch (data.value) {
    case 1:
      return 'cmn';
    case 2:
      return 'mensural';
    case 3:
      return 'mensural.black';
    case 4:
      return 'mensural.white';
    case 5:
      return 'neume';
    case 6:
      return 'tab';
    case 7:
      return 'tab.staff-like';
    case 8:
      return 'tab.guitar';
    case 9:
      return 'tab.lute.french';
    case 10:
      return 'tab.lute.italian';
    case 11:
      return 'tab.lute.german';
  }
  logWarning("Unknown value '${data.value}' for data_NOTATIONTYPE");
  return _unknownValue;
}

/// string -> `data_NOTATIONTYPE`.
Notationtype strToNotationtype(String value) {
  if (value == 'cmn') return Notationtype.cmn;
  if (value == 'mensural') return Notationtype.mensural;
  if (value == 'mensural.black') return Notationtype.mensuralBlack;
  if (value == 'mensural.white') return Notationtype.mensuralWhite;
  if (value == 'neume') return Notationtype.neume;
  if (value == 'tab') return Notationtype.tab;
  if (value == 'tab.staff-like') return Notationtype.tabStaffLike;
  if (value == 'tab.guitar') return Notationtype.tabGuitar;
  if (value == 'tab.lute.french') return Notationtype.tabLuteFrench;
  if (value == 'tab.lute.italian') return Notationtype.tabLuteItalian;
  if (value == 'tab.lute.german') return Notationtype.tabLuteGerman;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_NOTATIONTYPE");
  }
  return Notationtype.none;
}

/// `data_NOTEHEADMODIFIER` -> string.
String noteheadmodifierToStr(Noteheadmodifier data) {
  switch (data.value) {
    case 1:
      return 'slash';
    case 2:
      return 'backslash';
    case 3:
      return 'vline';
    case 4:
      return 'hline';
    case 5:
      return 'centerdot';
    case 6:
      return 'paren';
    case 7:
      return 'brack';
    case 8:
      return 'box';
    case 9:
      return 'circle';
    case 10:
      return 'fences';
  }
  logWarning("Unknown value '${data.value}' for data_NOTEHEADMODIFIER");
  return _unknownValue;
}

/// string -> `data_NOTEHEADMODIFIER`.
Noteheadmodifier strToNoteheadmodifier(String value) {
  if (value == 'slash') return Noteheadmodifier.slash;
  if (value == 'backslash') return Noteheadmodifier.backslash;
  if (value == 'vline') return Noteheadmodifier.vline;
  if (value == 'hline') return Noteheadmodifier.hline;
  if (value == 'centerdot') return Noteheadmodifier.centerdot;
  if (value == 'paren') return Noteheadmodifier.paren;
  if (value == 'brack') return Noteheadmodifier.brack;
  if (value == 'box') return Noteheadmodifier.box;
  if (value == 'circle') return Noteheadmodifier.circle;
  if (value == 'fences') return Noteheadmodifier.fences;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_NOTEHEADMODIFIER");
  }
  return Noteheadmodifier.none;
}

/// `data_NOTEHEADMODIFIER_list` -> string.
String noteheadmodifierListToStr(NoteheadmodifierList data) {
  switch (data.value) {
    case 1:
      return 'slash';
    case 2:
      return 'backslash';
    case 3:
      return 'vline';
    case 4:
      return 'hline';
    case 5:
      return 'centerdot';
    case 6:
      return 'paren';
    case 7:
      return 'brack';
    case 8:
      return 'box';
    case 9:
      return 'circle';
    case 10:
      return 'fences';
  }
  logWarning("Unknown value '${data.value}' for data_NOTEHEADMODIFIER_list");
  return _unknownValue;
}

/// string -> `data_NOTEHEADMODIFIER_list`.
NoteheadmodifierList strToNoteheadmodifierList(String value) {
  if (value == 'slash') return NoteheadmodifierList.slash;
  if (value == 'backslash') return NoteheadmodifierList.backslash;
  if (value == 'vline') return NoteheadmodifierList.vline;
  if (value == 'hline') return NoteheadmodifierList.hline;
  if (value == 'centerdot') return NoteheadmodifierList.centerdot;
  if (value == 'paren') return NoteheadmodifierList.paren;
  if (value == 'brack') return NoteheadmodifierList.brack;
  if (value == 'box') return NoteheadmodifierList.box;
  if (value == 'circle') return NoteheadmodifierList.circle;
  if (value == 'fences') return NoteheadmodifierList.fences;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_NOTEHEADMODIFIER_list");
  }
  return NoteheadmodifierList.none;
}

/// `data_OCTAVE_DIS` -> string.
String octaveDisToStr(OctaveDis data) {
  switch (data.value) {
    case 8:
      return '8';
    case 15:
      return '15';
    case 22:
      return '22';
  }
  logWarning("Unknown value '${data.value}' for data_OCTAVE_DIS");
  return _unknownValue;
}

/// string -> `data_OCTAVE_DIS`.
OctaveDis strToOctaveDis(String value) {
  if (value == '8') return OctaveDis.n8;
  if (value == '15') return OctaveDis.n15;
  if (value == '22') return OctaveDis.n22;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_OCTAVE_DIS");
  }
  return OctaveDis.none;
}

/// `data_ORIENTATION` -> string.
String orientationToStr(Orientation data) {
  switch (data.value) {
    case 1:
      return 'reversed';
    case 2:
      return '90CW';
    case 3:
      return '90CCW';
  }
  logWarning("Unknown value '${data.value}' for data_ORIENTATION");
  return _unknownValue;
}

/// string -> `data_ORIENTATION`.
Orientation strToOrientation(String value) {
  if (value == 'reversed') return Orientation.reversed;
  if (value == '90CW') return Orientation.n90cw;
  if (value == '90CCW') return Orientation.n90ccw;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ORIENTATION");
  }
  return Orientation.none;
}

/// `data_PEDALSTYLE` -> string.
String pedalstyleToStr(Pedalstyle data) {
  switch (data.value) {
    case 1:
      return 'line';
    case 2:
      return 'pedline';
    case 3:
      return 'pedstar';
    case 4:
      return 'altpedstar';
  }
  logWarning("Unknown value '${data.value}' for data_PEDALSTYLE");
  return _unknownValue;
}

/// string -> `data_PEDALSTYLE`.
Pedalstyle strToPedalstyle(String value) {
  if (value == 'line') return Pedalstyle.line;
  if (value == 'pedline') return Pedalstyle.pedline;
  if (value == 'pedstar') return Pedalstyle.pedstar;
  if (value == 'altpedstar') return Pedalstyle.altpedstar;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_PEDALSTYLE");
  }
  return Pedalstyle.none;
}

/// `data_PGFUNC` -> string.
String pgfuncToStr(Pgfunc data) {
  switch (data.value) {
    case 1:
      return 'all';
    case 2:
      return 'first';
    case 3:
      return 'last';
    case 4:
      return 'alt1';
    case 5:
      return 'alt2';
  }
  logWarning("Unknown value '${data.value}' for data_PGFUNC");
  return _unknownValue;
}

/// string -> `data_PGFUNC`.
Pgfunc strToPgfunc(String value) {
  if (value == 'all') return Pgfunc.all;
  if (value == 'first') return Pgfunc.first;
  if (value == 'last') return Pgfunc.last;
  if (value == 'alt1') return Pgfunc.alt1;
  if (value == 'alt2') return Pgfunc.alt2;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_PGFUNC");
  }
  return Pgfunc.none;
}

/// `data_PITCHNAME` -> string.
String pitchnameToStr(Pitchname data) {
  switch (data.value) {
    case 1:
      return 'c';
    case 2:
      return 'd';
    case 3:
      return 'e';
    case 4:
      return 'f';
    case 5:
      return 'g';
    case 6:
      return 'a';
    case 7:
      return 'b';
  }
  logWarning("Unknown value '${data.value}' for data_PITCHNAME");
  return _unknownValue;
}

/// string -> `data_PITCHNAME`.
Pitchname strToPitchname(String value) {
  if (value == 'c') return Pitchname.c;
  if (value == 'd') return Pitchname.d;
  if (value == 'e') return Pitchname.e;
  if (value == 'f') return Pitchname.f;
  if (value == 'g') return Pitchname.g;
  if (value == 'a') return Pitchname.a;
  if (value == 'b') return Pitchname.b;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_PITCHNAME");
  }
  return Pitchname.none;
}

/// `data_PROLATIO` -> string.
String prolatioToStr(Prolatio data) {
  switch (data.value) {
    case 2:
      return '2';
    case 3:
      return '3';
  }
  logWarning("Unknown value '${data.value}' for data_PROLATIO");
  return _unknownValue;
}

/// string -> `data_PROLATIO`.
Prolatio strToProlatio(String value) {
  if (value == '2') return Prolatio.n2;
  if (value == '3') return Prolatio.n3;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_PROLATIO");
  }
  return Prolatio.none;
}

/// `data_RELATIONSHIP` -> string.
String relationshipToStr(Relationship data) {
  switch (data.value) {
    case 1:
      return 'hasAbridgement';
    case 2:
      return 'isAbridgementOf';
    case 3:
      return 'hasAdaptation';
    case 4:
      return 'isAdaptationOf';
    case 5:
      return 'hasAlternate';
    case 6:
      return 'isAlternateOf';
    case 7:
      return 'hasArrangement';
    case 8:
      return 'isArrangementOf';
    case 9:
      return 'hasComplement';
    case 10:
      return 'isComplementOf';
    case 11:
      return 'hasEmbodiment';
    case 12:
      return 'isEmbodimentOf';
    case 13:
      return 'hasExemplar';
    case 14:
      return 'isExemplarOf';
    case 15:
      return 'hasImitation';
    case 16:
      return 'isImitationOf';
    case 17:
      return 'hasPart';
    case 18:
      return 'isPartOf';
    case 19:
      return 'hasRealization';
    case 20:
      return 'isRealizationOf';
    case 21:
      return 'hasReconfiguration';
    case 22:
      return 'isReconfigurationOf';
    case 23:
      return 'hasReproduction';
    case 24:
      return 'isReproductionOf';
    case 25:
      return 'hasRevision';
    case 26:
      return 'isRevisionOf';
    case 27:
      return 'hasSuccessor';
    case 28:
      return 'isSuccessorOf';
    case 29:
      return 'hasSummarization';
    case 30:
      return 'isSummarizationOf';
    case 31:
      return 'hasSupplement';
    case 32:
      return 'isSupplementOf';
    case 33:
      return 'hasTransformation';
    case 34:
      return 'isTransformationOf';
    case 35:
      return 'hasTranslation';
    case 36:
      return 'isTranslationOf';
    case 37:
      return 'preceding';
    case 38:
      return 'succeeding';
    case 39:
      return 'original';
    case 40:
      return 'host';
    case 41:
      return 'constituent';
    case 42:
      return 'otherVersion';
    case 43:
      return 'otherFormat';
    case 44:
      return 'isReferencedBy';
    case 45:
      return 'references';
  }
  logWarning("Unknown value '${data.value}' for data_RELATIONSHIP");
  return _unknownValue;
}

/// string -> `data_RELATIONSHIP`.
Relationship strToRelationship(String value) {
  if (value == 'hasAbridgement') return Relationship.hasabridgement;
  if (value == 'isAbridgementOf') return Relationship.isabridgementof;
  if (value == 'hasAdaptation') return Relationship.hasadaptation;
  if (value == 'isAdaptationOf') return Relationship.isadaptationof;
  if (value == 'hasAlternate') return Relationship.hasalternate;
  if (value == 'isAlternateOf') return Relationship.isalternateof;
  if (value == 'hasArrangement') return Relationship.hasarrangement;
  if (value == 'isArrangementOf') return Relationship.isarrangementof;
  if (value == 'hasComplement') return Relationship.hascomplement;
  if (value == 'isComplementOf') return Relationship.iscomplementof;
  if (value == 'hasEmbodiment') return Relationship.hasembodiment;
  if (value == 'isEmbodimentOf') return Relationship.isembodimentof;
  if (value == 'hasExemplar') return Relationship.hasexemplar;
  if (value == 'isExemplarOf') return Relationship.isexemplarof;
  if (value == 'hasImitation') return Relationship.hasimitation;
  if (value == 'isImitationOf') return Relationship.isimitationof;
  if (value == 'hasPart') return Relationship.haspart;
  if (value == 'isPartOf') return Relationship.ispartof;
  if (value == 'hasRealization') return Relationship.hasrealization;
  if (value == 'isRealizationOf') return Relationship.isrealizationof;
  if (value == 'hasReconfiguration') return Relationship.hasreconfiguration;
  if (value == 'isReconfigurationOf') return Relationship.isreconfigurationof;
  if (value == 'hasReproduction') return Relationship.hasreproduction;
  if (value == 'isReproductionOf') return Relationship.isreproductionof;
  if (value == 'hasRevision') return Relationship.hasrevision;
  if (value == 'isRevisionOf') return Relationship.isrevisionof;
  if (value == 'hasSuccessor') return Relationship.hassuccessor;
  if (value == 'isSuccessorOf') return Relationship.issuccessorof;
  if (value == 'hasSummarization') return Relationship.hassummarization;
  if (value == 'isSummarizationOf') return Relationship.issummarizationof;
  if (value == 'hasSupplement') return Relationship.hassupplement;
  if (value == 'isSupplementOf') return Relationship.issupplementof;
  if (value == 'hasTransformation') return Relationship.hastransformation;
  if (value == 'isTransformationOf') return Relationship.istransformationof;
  if (value == 'hasTranslation') return Relationship.hastranslation;
  if (value == 'isTranslationOf') return Relationship.istranslationof;
  if (value == 'preceding') return Relationship.preceding;
  if (value == 'succeeding') return Relationship.succeeding;
  if (value == 'original') return Relationship.original;
  if (value == 'host') return Relationship.host;
  if (value == 'constituent') return Relationship.constituent;
  if (value == 'otherVersion') return Relationship.otherversion;
  if (value == 'otherFormat') return Relationship.otherformat;
  if (value == 'isReferencedBy') return Relationship.isreferencedby;
  if (value == 'references') return Relationship.references;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_RELATIONSHIP");
  }
  return Relationship.none;
}

/// `data_RELATORS` -> string.
String relatorsToStr(Relators data) {
  switch (data.value) {
    case 1:
      return 'arr';
    case 2:
      return 'aut';
    case 3:
      return 'cmp';
    case 4:
      return 'dte';
    case 5:
      return 'edt';
    case 6:
      return 'lbt';
    case 7:
      return 'lyr';
    case 8:
      return 'act';
    case 9:
      return 'ard';
    case 10:
      return 'art';
    case 11:
      return 'aus';
    case 12:
      return 'chr';
    case 13:
      return 'cnd';
    case 14:
      return 'crp';
    case 15:
      return 'cst';
    case 16:
      return 'drt';
    case 17:
      return 'egr';
    case 18:
      return 'flm';
    case 19:
      return 'fmd';
    case 20:
      return 'fmp';
    case 21:
      return 'itr';
    case 22:
      return 'mcp';
    case 23:
      return 'mus';
    case 24:
      return 'msd';
    case 25:
      return 'pdr';
    case 26:
      return 'pmn';
    case 27:
      return 'prn';
    case 28:
      return 'pro';
    case 29:
      return 'rce';
    case 30:
      return 'scr';
    case 31:
      return 'sng';
    case 32:
      return 'std';
    case 33:
      return 'trc';
    case 34:
      return 'trl';
  }
  logWarning("Unknown value '${data.value}' for data_RELATORS");
  return _unknownValue;
}

/// string -> `data_RELATORS`.
Relators strToRelators(String value) {
  if (value == 'arr') return Relators.arr;
  if (value == 'aut') return Relators.aut;
  if (value == 'cmp') return Relators.cmp;
  if (value == 'dte') return Relators.dte;
  if (value == 'edt') return Relators.edt;
  if (value == 'lbt') return Relators.lbt;
  if (value == 'lyr') return Relators.lyr;
  if (value == 'act') return Relators.act;
  if (value == 'ard') return Relators.ard;
  if (value == 'art') return Relators.art;
  if (value == 'aus') return Relators.aus;
  if (value == 'chr') return Relators.chr;
  if (value == 'cnd') return Relators.cnd;
  if (value == 'crp') return Relators.crp;
  if (value == 'cst') return Relators.cst;
  if (value == 'drt') return Relators.drt;
  if (value == 'egr') return Relators.egr;
  if (value == 'flm') return Relators.flm;
  if (value == 'fmd') return Relators.fmd;
  if (value == 'fmp') return Relators.fmp;
  if (value == 'itr') return Relators.itr;
  if (value == 'mcp') return Relators.mcp;
  if (value == 'mus') return Relators.mus;
  if (value == 'msd') return Relators.msd;
  if (value == 'pdr') return Relators.pdr;
  if (value == 'pmn') return Relators.pmn;
  if (value == 'prn') return Relators.prn;
  if (value == 'pro') return Relators.pro;
  if (value == 'rce') return Relators.rce;
  if (value == 'scr') return Relators.scr;
  if (value == 'sng') return Relators.sng;
  if (value == 'std') return Relators.std;
  if (value == 'trc') return Relators.trc;
  if (value == 'trl') return Relators.trl;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_RELATORS");
  }
  return Relators.none;
}

/// `data_ROTATION` -> string.
String rotationToStr(Rotation data) {
  switch (data.value) {
    case 1:
      return 'none';
    case 2:
      return 'down';
    case 3:
      return 'left';
    case 4:
      return 'ne';
    case 5:
      return 'nw';
    case 6:
      return 'se';
    case 7:
      return 'sw';
  }
  logWarning("Unknown value '${data.value}' for data_ROTATION");
  return _unknownValue;
}

/// string -> `data_ROTATION`.
Rotation strToRotation(String value) {
  if (value == 'none') return Rotation.none0;
  if (value == 'down') return Rotation.down;
  if (value == 'left') return Rotation.left;
  if (value == 'ne') return Rotation.ne;
  if (value == 'nw') return Rotation.nw;
  if (value == 'se') return Rotation.se;
  if (value == 'sw') return Rotation.sw;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ROTATION");
  }
  return Rotation.none;
}

/// `data_ROTATIONDIRECTION` -> string.
String rotationdirectionToStr(Rotationdirection data) {
  switch (data.value) {
    case 1:
      return 'none';
    case 2:
      return 'down';
    case 3:
      return 'left';
    case 4:
      return 'ne';
    case 5:
      return 'nw';
    case 6:
      return 'se';
    case 7:
      return 'sw';
  }
  logWarning("Unknown value '${data.value}' for data_ROTATIONDIRECTION");
  return _unknownValue;
}

/// string -> `data_ROTATIONDIRECTION`.
Rotationdirection strToRotationdirection(String value) {
  if (value == 'none') return Rotationdirection.none0;
  if (value == 'down') return Rotationdirection.down;
  if (value == 'left') return Rotationdirection.left;
  if (value == 'ne') return Rotationdirection.ne;
  if (value == 'nw') return Rotationdirection.nw;
  if (value == 'se') return Rotationdirection.se;
  if (value == 'sw') return Rotationdirection.sw;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_ROTATIONDIRECTION");
  }
  return Rotationdirection.none;
}

/// `data_STAFFITEM` -> string.
String staffitemToStr(Staffitem data) {
  switch (data.value) {
    case 1:
      return 'accid';
    case 2:
      return 'annot';
    case 3:
      return 'artic';
    case 4:
      return 'dir';
    case 5:
      return 'dynam';
    case 6:
      return 'harm';
    case 7:
      return 'ornam';
    case 8:
      return 'sp';
    case 9:
      return 'stageDir';
    case 10:
      return 'tempo';
    case 11:
      return 'beam';
    case 12:
      return 'bend';
    case 13:
      return 'bracketSpan';
    case 14:
      return 'breath';
    case 15:
      return 'cpMark';
    case 16:
      return 'fermata';
    case 17:
      return 'fing';
    case 18:
      return 'hairpin';
    case 19:
      return 'harpPedal';
    case 20:
      return 'lv';
    case 21:
      return 'mordent';
    case 22:
      return 'octave';
    case 23:
      return 'pedal';
    case 24:
      return 'reh';
    case 25:
      return 'tie';
    case 26:
      return 'trill';
    case 27:
      return 'tuplet';
    case 28:
      return 'turn';
    case 29:
      return 'ligature';
  }
  logWarning("Unknown value '${data.value}' for data_STAFFITEM");
  return _unknownValue;
}

/// string -> `data_STAFFITEM`.
Staffitem strToStaffitem(String value) {
  if (value == 'accid') return Staffitem.accid;
  if (value == 'annot') return Staffitem.annot;
  if (value == 'artic') return Staffitem.artic;
  if (value == 'dir') return Staffitem.dir;
  if (value == 'dynam') return Staffitem.dynam;
  if (value == 'harm') return Staffitem.harm;
  if (value == 'ornam') return Staffitem.ornam;
  if (value == 'sp') return Staffitem.sp;
  if (value == 'stageDir') return Staffitem.stagedir;
  if (value == 'tempo') return Staffitem.tempo;
  if (value == 'beam') return Staffitem.beam;
  if (value == 'bend') return Staffitem.bend;
  if (value == 'bracketSpan') return Staffitem.bracketspan;
  if (value == 'breath') return Staffitem.breath;
  if (value == 'cpMark') return Staffitem.cpmark;
  if (value == 'fermata') return Staffitem.fermata;
  if (value == 'fing') return Staffitem.fing;
  if (value == 'hairpin') return Staffitem.hairpin;
  if (value == 'harpPedal') return Staffitem.harppedal;
  if (value == 'lv') return Staffitem.lv;
  if (value == 'mordent') return Staffitem.mordent;
  if (value == 'octave') return Staffitem.octave;
  if (value == 'pedal') return Staffitem.pedal;
  if (value == 'reh') return Staffitem.reh;
  if (value == 'tie') return Staffitem.tie;
  if (value == 'trill') return Staffitem.trill;
  if (value == 'tuplet') return Staffitem.tuplet;
  if (value == 'turn') return Staffitem.turn;
  if (value == 'ligature') return Staffitem.ligature;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STAFFITEM");
  }
  return Staffitem.none;
}

/// `data_STAFFITEM_basic` -> string.
String staffitemBasicToStr(StaffitemBasic data) {
  switch (data.value) {
    case 1:
      return 'accid';
    case 2:
      return 'annot';
    case 3:
      return 'artic';
    case 4:
      return 'dir';
    case 5:
      return 'dynam';
    case 6:
      return 'harm';
    case 7:
      return 'ornam';
    case 8:
      return 'sp';
    case 9:
      return 'stageDir';
    case 10:
      return 'tempo';
  }
  logWarning("Unknown value '${data.value}' for data_STAFFITEM_basic");
  return _unknownValue;
}

/// string -> `data_STAFFITEM_basic`.
StaffitemBasic strToStaffitemBasic(String value) {
  if (value == 'accid') return StaffitemBasic.accid;
  if (value == 'annot') return StaffitemBasic.annot;
  if (value == 'artic') return StaffitemBasic.artic;
  if (value == 'dir') return StaffitemBasic.dir;
  if (value == 'dynam') return StaffitemBasic.dynam;
  if (value == 'harm') return StaffitemBasic.harm;
  if (value == 'ornam') return StaffitemBasic.ornam;
  if (value == 'sp') return StaffitemBasic.sp;
  if (value == 'stageDir') return StaffitemBasic.stagedir;
  if (value == 'tempo') return StaffitemBasic.tempo;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STAFFITEM_basic");
  }
  return StaffitemBasic.none;
}

/// `data_STAFFITEM_cmn` -> string.
String staffitemCmnToStr(StaffitemCmn data) {
  switch (data.value) {
    case 1:
      return 'beam';
    case 2:
      return 'bend';
    case 3:
      return 'bracketSpan';
    case 4:
      return 'breath';
    case 5:
      return 'cpMark';
    case 6:
      return 'fermata';
    case 7:
      return 'fing';
    case 8:
      return 'hairpin';
    case 9:
      return 'harpPedal';
    case 10:
      return 'lv';
    case 11:
      return 'mordent';
    case 12:
      return 'octave';
    case 13:
      return 'pedal';
    case 14:
      return 'reh';
    case 15:
      return 'tie';
    case 16:
      return 'trill';
    case 17:
      return 'tuplet';
    case 18:
      return 'turn';
  }
  logWarning("Unknown value '${data.value}' for data_STAFFITEM_cmn");
  return _unknownValue;
}

/// string -> `data_STAFFITEM_cmn`.
StaffitemCmn strToStaffitemCmn(String value) {
  if (value == 'beam') return StaffitemCmn.beam;
  if (value == 'bend') return StaffitemCmn.bend;
  if (value == 'bracketSpan') return StaffitemCmn.bracketspan;
  if (value == 'breath') return StaffitemCmn.breath;
  if (value == 'cpMark') return StaffitemCmn.cpmark;
  if (value == 'fermata') return StaffitemCmn.fermata;
  if (value == 'fing') return StaffitemCmn.fing;
  if (value == 'hairpin') return StaffitemCmn.hairpin;
  if (value == 'harpPedal') return StaffitemCmn.harppedal;
  if (value == 'lv') return StaffitemCmn.lv;
  if (value == 'mordent') return StaffitemCmn.mordent;
  if (value == 'octave') return StaffitemCmn.octave;
  if (value == 'pedal') return StaffitemCmn.pedal;
  if (value == 'reh') return StaffitemCmn.reh;
  if (value == 'tie') return StaffitemCmn.tie;
  if (value == 'trill') return StaffitemCmn.trill;
  if (value == 'tuplet') return StaffitemCmn.tuplet;
  if (value == 'turn') return StaffitemCmn.turn;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STAFFITEM_cmn");
  }
  return StaffitemCmn.none;
}

/// `data_STAFFITEM_mensural` -> string.
String staffitemMensuralToStr(StaffitemMensural data) {
  switch (data.value) {
    case 1:
      return 'ligature';
  }
  logWarning("Unknown value '${data.value}' for data_STAFFITEM_mensural");
  return _unknownValue;
}

/// string -> `data_STAFFITEM_mensural`.
StaffitemMensural strToStaffitemMensural(String value) {
  if (value == 'ligature') return StaffitemMensural.ligature;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STAFFITEM_mensural");
  }
  return StaffitemMensural.none;
}

/// `data_STAFFREL` -> string.
String staffrelToStr(Staffrel data) {
  switch (data.value) {
    case 1:
      return 'above';
    case 2:
      return 'below';
    case 3:
      return 'between';
    case 4:
      return 'within';
  }
  logWarning("Unknown value '${data.value}' for data_STAFFREL");
  return _unknownValue;
}

/// string -> `data_STAFFREL`.
Staffrel strToStaffrel(String value) {
  if (value == 'above') return Staffrel.above;
  if (value == 'below') return Staffrel.below;
  if (value == 'between') return Staffrel.between;
  if (value == 'within') return Staffrel.within;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STAFFREL");
  }
  return Staffrel.none;
}

/// `data_STAFFREL_basic` -> string.
String staffrelBasicToStr(StaffrelBasic data) {
  switch (data.value) {
    case 1:
      return 'above';
    case 2:
      return 'below';
  }
  logWarning("Unknown value '${data.value}' for data_STAFFREL_basic");
  return _unknownValue;
}

/// string -> `data_STAFFREL_basic`.
StaffrelBasic strToStaffrelBasic(String value) {
  if (value == 'above') return StaffrelBasic.above;
  if (value == 'below') return StaffrelBasic.below;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STAFFREL_basic");
  }
  return StaffrelBasic.none;
}

/// `data_STAFFREL_extended` -> string.
String staffrelExtendedToStr(StaffrelExtended data) {
  switch (data.value) {
    case 1:
      return 'between';
    case 2:
      return 'within';
  }
  logWarning("Unknown value '${data.value}' for data_STAFFREL_extended");
  return _unknownValue;
}

/// string -> `data_STAFFREL_extended`.
StaffrelExtended strToStaffrelExtended(String value) {
  if (value == 'between') return StaffrelExtended.between;
  if (value == 'within') return StaffrelExtended.within;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STAFFREL_extended");
  }
  return StaffrelExtended.none;
}

/// `data_STEMDIRECTION` -> string.
String stemdirectionToStr(Stemdirection data) {
  switch (data.value) {
    case 1:
      return 'up';
    case 2:
      return 'down';
    case 3:
      return 'left';
    case 4:
      return 'right';
    case 5:
      return 'ne';
    case 6:
      return 'se';
    case 7:
      return 'nw';
    case 8:
      return 'sw';
  }
  logWarning("Unknown value '${data.value}' for data_STEMDIRECTION");
  return _unknownValue;
}

/// string -> `data_STEMDIRECTION`.
Stemdirection strToStemdirection(String value) {
  if (value == 'up') return Stemdirection.up;
  if (value == 'down') return Stemdirection.down;
  if (value == 'left') return Stemdirection.left;
  if (value == 'right') return Stemdirection.right;
  if (value == 'ne') return Stemdirection.ne;
  if (value == 'se') return Stemdirection.se;
  if (value == 'nw') return Stemdirection.nw;
  if (value == 'sw') return Stemdirection.sw;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STEMDIRECTION");
  }
  return Stemdirection.none;
}

/// `data_STEMDIRECTION_basic` -> string.
String stemdirectionBasicToStr(StemdirectionBasic data) {
  switch (data.value) {
    case 1:
      return 'up';
    case 2:
      return 'down';
  }
  logWarning("Unknown value '${data.value}' for data_STEMDIRECTION_basic");
  return _unknownValue;
}

/// string -> `data_STEMDIRECTION_basic`.
StemdirectionBasic strToStemdirectionBasic(String value) {
  if (value == 'up') return StemdirectionBasic.up;
  if (value == 'down') return StemdirectionBasic.down;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STEMDIRECTION_basic");
  }
  return StemdirectionBasic.none;
}

/// `data_STEMDIRECTION_extended` -> string.
String stemdirectionExtendedToStr(StemdirectionExtended data) {
  switch (data.value) {
    case 1:
      return 'left';
    case 2:
      return 'right';
    case 3:
      return 'ne';
    case 4:
      return 'se';
    case 5:
      return 'nw';
    case 6:
      return 'sw';
  }
  logWarning("Unknown value '${data.value}' for data_STEMDIRECTION_extended");
  return _unknownValue;
}

/// string -> `data_STEMDIRECTION_extended`.
StemdirectionExtended strToStemdirectionExtended(String value) {
  if (value == 'left') return StemdirectionExtended.left;
  if (value == 'right') return StemdirectionExtended.right;
  if (value == 'ne') return StemdirectionExtended.ne;
  if (value == 'se') return StemdirectionExtended.se;
  if (value == 'nw') return StemdirectionExtended.nw;
  if (value == 'sw') return StemdirectionExtended.sw;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STEMDIRECTION_extended");
  }
  return StemdirectionExtended.none;
}

/// `data_STEMFORM_mensural` -> string.
String stemformMensuralToStr(StemformMensural data) {
  switch (data.value) {
    case 1:
      return 'circle';
    case 2:
      return 'oblique';
    case 3:
      return 'swallowtail';
    case 4:
      return 'virgula';
  }
  logWarning("Unknown value '${data.value}' for data_STEMFORM_mensural");
  return _unknownValue;
}

/// string -> `data_STEMFORM_mensural`.
StemformMensural strToStemformMensural(String value) {
  if (value == 'circle') return StemformMensural.circle;
  if (value == 'oblique') return StemformMensural.oblique;
  if (value == 'swallowtail') return StemformMensural.swallowtail;
  if (value == 'virgula') return StemformMensural.virgula;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STEMFORM_mensural");
  }
  return StemformMensural.none;
}

/// `data_STEMMODIFIER` -> string.
String stemmodifierToStr(Stemmodifier data) {
  switch (data.value) {
    case 1:
      return 'none';
    case 2:
      return '1slash';
    case 3:
      return '2slash';
    case 4:
      return '3slash';
    case 5:
      return '4slash';
    case 6:
      return '5slash';
    case 7:
      return '6slash';
    case 8:
      return 'sprech';
    case 9:
      return 'z';
  }
  logWarning("Unknown value '${data.value}' for data_STEMMODIFIER");
  return _unknownValue;
}

/// string -> `data_STEMMODIFIER`.
Stemmodifier strToStemmodifier(String value) {
  if (value == 'none') return Stemmodifier.none0;
  if (value == '1slash') return Stemmodifier.n1slash;
  if (value == '2slash') return Stemmodifier.n2slash;
  if (value == '3slash') return Stemmodifier.n3slash;
  if (value == '4slash') return Stemmodifier.n4slash;
  if (value == '5slash') return Stemmodifier.n5slash;
  if (value == '6slash') return Stemmodifier.n6slash;
  if (value == 'sprech') return Stemmodifier.sprech;
  if (value == 'z') return Stemmodifier.z;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STEMMODIFIER");
  }
  return Stemmodifier.none;
}

/// `data_STEMPOSITION` -> string.
String stempositionToStr(Stemposition data) {
  switch (data.value) {
    case 1:
      return 'left';
    case 2:
      return 'right';
    case 3:
      return 'center';
  }
  logWarning("Unknown value '${data.value}' for data_STEMPOSITION");
  return _unknownValue;
}

/// string -> `data_STEMPOSITION`.
Stemposition strToStemposition(String value) {
  if (value == 'left') return Stemposition.left;
  if (value == 'right') return Stemposition.right;
  if (value == 'center') return Stemposition.center;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_STEMPOSITION");
  }
  return Stemposition.none;
}

/// `data_TEMPERAMENT` -> string.
String temperamentToStr(Temperament data) {
  switch (data.value) {
    case 1:
      return 'equal';
    case 2:
      return 'just';
    case 3:
      return 'mean';
    case 4:
      return 'pythagorean';
  }
  logWarning("Unknown value '${data.value}' for data_TEMPERAMENT");
  return _unknownValue;
}

/// string -> `data_TEMPERAMENT`.
Temperament strToTemperament(String value) {
  if (value == 'equal') return Temperament.equal;
  if (value == 'just') return Temperament.just;
  if (value == 'mean') return Temperament.mean;
  if (value == 'pythagorean') return Temperament.pythagorean;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_TEMPERAMENT");
  }
  return Temperament.none;
}

/// `data_TEMPUS` -> string.
String tempusToStr(Tempus data) {
  switch (data.value) {
    case 2:
      return '2';
    case 3:
      return '3';
  }
  logWarning("Unknown value '${data.value}' for data_TEMPUS");
  return _unknownValue;
}

/// string -> `data_TEMPUS`.
Tempus strToTempus(String value) {
  if (value == '2') return Tempus.n2;
  if (value == '3') return Tempus.n3;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_TEMPUS");
  }
  return Tempus.none;
}

/// `data_TEXTRENDITION` -> string.
String textrenditionToStr(Textrendition data) {
  switch (data.value) {
    case 1:
      return 'quote';
    case 2:
      return 'quotedbl';
    case 3:
      return 'italic';
    case 4:
      return 'oblique';
    case 5:
      return 'smcaps';
    case 6:
      return 'bold';
    case 7:
      return 'bolder';
    case 8:
      return 'lighter';
    case 9:
      return 'box';
    case 10:
      return 'circle';
    case 11:
      return 'dbox';
    case 12:
      return 'tbox';
    case 13:
      return 'bslash';
    case 14:
      return 'fslash';
    case 15:
      return 'line-through';
    case 16:
      return 'none';
    case 17:
      return 'overline';
    case 18:
      return 'overstrike';
    case 19:
      return 'strike';
    case 20:
      return 'sub';
    case 21:
      return 'sup';
    case 22:
      return 'superimpose';
    case 23:
      return 'underline';
    case 24:
      return 'x-through';
    case 25:
      return 'ltr';
    case 26:
      return 'rtl';
    case 27:
      return 'lro';
    case 28:
      return 'rlo';
  }
  logWarning("Unknown value '${data.value}' for data_TEXTRENDITION");
  return _unknownValue;
}

/// string -> `data_TEXTRENDITION`.
Textrendition strToTextrendition(String value) {
  if (value == 'quote') return Textrendition.quote;
  if (value == 'quotedbl') return Textrendition.quotedbl;
  if (value == 'italic') return Textrendition.italic;
  if (value == 'oblique') return Textrendition.oblique;
  if (value == 'smcaps') return Textrendition.smcaps;
  if (value == 'bold') return Textrendition.bold;
  if (value == 'bolder') return Textrendition.bolder;
  if (value == 'lighter') return Textrendition.lighter;
  if (value == 'box') return Textrendition.box;
  if (value == 'circle') return Textrendition.circle;
  if (value == 'dbox') return Textrendition.dbox;
  if (value == 'tbox') return Textrendition.tbox;
  if (value == 'bslash') return Textrendition.bslash;
  if (value == 'fslash') return Textrendition.fslash;
  if (value == 'line-through') return Textrendition.lineThrough;
  if (value == 'none') return Textrendition.none0;
  if (value == 'overline') return Textrendition.overline;
  if (value == 'overstrike') return Textrendition.overstrike;
  if (value == 'strike') return Textrendition.strike;
  if (value == 'sub') return Textrendition.sub;
  if (value == 'sup') return Textrendition.sup;
  if (value == 'superimpose') return Textrendition.superimpose;
  if (value == 'underline') return Textrendition.underline;
  if (value == 'x-through') return Textrendition.xThrough;
  if (value == 'ltr') return Textrendition.ltr;
  if (value == 'rtl') return Textrendition.rtl;
  if (value == 'lro') return Textrendition.lro;
  if (value == 'rlo') return Textrendition.rlo;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_TEXTRENDITION");
  }
  return Textrendition.none;
}

/// `data_TEXTRENDITIONLIST` -> string.
String textrenditionlistToStr(Textrenditionlist data) {
  switch (data.value) {
    case 1:
      return 'quote';
    case 2:
      return 'quotedbl';
    case 3:
      return 'italic';
    case 4:
      return 'oblique';
    case 5:
      return 'smcaps';
    case 6:
      return 'bold';
    case 7:
      return 'bolder';
    case 8:
      return 'lighter';
    case 9:
      return 'box';
    case 10:
      return 'circle';
    case 11:
      return 'dbox';
    case 12:
      return 'tbox';
    case 13:
      return 'bslash';
    case 14:
      return 'fslash';
    case 15:
      return 'line-through';
    case 16:
      return 'none';
    case 17:
      return 'overline';
    case 18:
      return 'overstrike';
    case 19:
      return 'strike';
    case 20:
      return 'sub';
    case 21:
      return 'sup';
    case 22:
      return 'superimpose';
    case 23:
      return 'underline';
    case 24:
      return 'x-through';
    case 25:
      return 'ltr';
    case 26:
      return 'rtl';
    case 27:
      return 'lro';
    case 28:
      return 'rlo';
  }
  logWarning("Unknown value '${data.value}' for data_TEXTRENDITIONLIST");
  return _unknownValue;
}

/// string -> `data_TEXTRENDITIONLIST`.
Textrenditionlist strToTextrenditionlist(String value) {
  if (value == 'quote') return Textrenditionlist.quote;
  if (value == 'quotedbl') return Textrenditionlist.quotedbl;
  if (value == 'italic') return Textrenditionlist.italic;
  if (value == 'oblique') return Textrenditionlist.oblique;
  if (value == 'smcaps') return Textrenditionlist.smcaps;
  if (value == 'bold') return Textrenditionlist.bold;
  if (value == 'bolder') return Textrenditionlist.bolder;
  if (value == 'lighter') return Textrenditionlist.lighter;
  if (value == 'box') return Textrenditionlist.box;
  if (value == 'circle') return Textrenditionlist.circle;
  if (value == 'dbox') return Textrenditionlist.dbox;
  if (value == 'tbox') return Textrenditionlist.tbox;
  if (value == 'bslash') return Textrenditionlist.bslash;
  if (value == 'fslash') return Textrenditionlist.fslash;
  if (value == 'line-through') return Textrenditionlist.lineThrough;
  if (value == 'none') return Textrenditionlist.none0;
  if (value == 'overline') return Textrenditionlist.overline;
  if (value == 'overstrike') return Textrenditionlist.overstrike;
  if (value == 'strike') return Textrenditionlist.strike;
  if (value == 'sub') return Textrenditionlist.sub;
  if (value == 'sup') return Textrenditionlist.sup;
  if (value == 'superimpose') return Textrenditionlist.superimpose;
  if (value == 'underline') return Textrenditionlist.underline;
  if (value == 'x-through') return Textrenditionlist.xThrough;
  if (value == 'ltr') return Textrenditionlist.ltr;
  if (value == 'rtl') return Textrenditionlist.rtl;
  if (value == 'lro') return Textrenditionlist.lro;
  if (value == 'rlo') return Textrenditionlist.rlo;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_TEXTRENDITIONLIST");
  }
  return Textrenditionlist.none;
}

/// `data_TIE` -> string.
String tieToStr(Tie data) {
  switch (data.value) {
    case 1:
      return 'i';
    case 2:
      return 'm';
    case 3:
      return 't';
  }
  logWarning("Unknown value '${data.value}' for data_TIE");
  return _unknownValue;
}

/// string -> `data_TIE`.
Tie strToTie(String value) {
  if (value == 'i') return Tie.i;
  if (value == 'm') return Tie.m;
  if (value == 't') return Tie.t;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_TIE");
  }
  return Tie.none;
}

/// `data_VERTICALALIGNMENT` -> string.
String verticalalignmentToStr(Verticalalignment data) {
  switch (data.value) {
    case 1:
      return 'top';
    case 2:
      return 'middle';
    case 3:
      return 'bottom';
    case 4:
      return 'baseline';
  }
  logWarning("Unknown value '${data.value}' for data_VERTICALALIGNMENT");
  return _unknownValue;
}

/// string -> `data_VERTICALALIGNMENT`.
Verticalalignment strToVerticalalignment(String value) {
  if (value == 'top') return Verticalalignment.top;
  if (value == 'middle') return Verticalalignment.middle;
  if (value == 'bottom') return Verticalalignment.bottom;
  if (value == 'baseline') return Verticalalignment.baseline;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data_VERTICALALIGNMENT");
  }
  return Verticalalignment.none;
}

/// `divLineLog_FORM` -> string.
String divlinelogFormToStr(DivlinelogForm data) {
  switch (data.value) {
    case 1:
      return 'caesura';
    case 2:
      return 'finalis';
    case 3:
      return 'maior';
    case 4:
      return 'maxima';
    case 5:
      return 'minima';
    case 6:
      return 'virgula';
  }
  logWarning("Unknown value '${data.value}' for divLineLog_FORM");
  return _unknownValue;
}

/// string -> `divLineLog_FORM`.
DivlinelogForm strToDivlinelogForm(String value) {
  if (value == 'caesura') return DivlinelogForm.caesura;
  if (value == 'finalis') return DivlinelogForm.finalis;
  if (value == 'maior') return DivlinelogForm.maior;
  if (value == 'maxima') return DivlinelogForm.maxima;
  if (value == 'minima') return DivlinelogForm.minima;
  if (value == 'virgula') return DivlinelogForm.virgula;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for divLineLog_FORM");
  }
  return DivlinelogForm.none;
}

/// `docStatus_STATUS` -> string.
String docstatusStatusToStr(DocstatusStatus data) {
  switch (data.value) {
    case 1:
      return 'draft';
    case 2:
      return 'in-process';
    case 3:
      return 'candidate';
    case 4:
      return 'approved';
    case 5:
      return 'published';
    case 6:
      return 'withdrawn';
    case 7:
      return 'embargoed';
  }
  logWarning("Unknown value '${data.value}' for docStatus_STATUS");
  return _unknownValue;
}

/// string -> `docStatus_STATUS`.
DocstatusStatus strToDocstatusStatus(String value) {
  if (value == 'draft') return DocstatusStatus.draft;
  if (value == 'in-process') return DocstatusStatus.inProcess;
  if (value == 'candidate') return DocstatusStatus.candidate;
  if (value == 'approved') return DocstatusStatus.approved;
  if (value == 'published') return DocstatusStatus.published;
  if (value == 'withdrawn') return DocstatusStatus.withdrawn;
  if (value == 'embargoed') return DocstatusStatus.embargoed;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for docStatus_STATUS");
  }
  return DocstatusStatus.none;
}

/// `dotLog_FORM` -> string.
String dotlogFormToStr(DotlogForm data) {
  switch (data.value) {
    case 1:
      return 'aug';
    case 2:
      return 'div';
  }
  logWarning("Unknown value '${data.value}' for dotLog_FORM");
  return _unknownValue;
}

/// string -> `dotLog_FORM`.
DotlogForm strToDotlogForm(String value) {
  if (value == 'aug') return DotlogForm.aug;
  if (value == 'div') return DotlogForm.div;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for dotLog_FORM");
  }
  return DotlogForm.none;
}

/// `endings_ENDINGREND` -> string.
String endingsEndingrendToStr(EndingsEndingrend data) {
  switch (data.value) {
    case 1:
      return 'top';
    case 2:
      return 'barred';
    case 3:
      return 'grouped';
  }
  logWarning("Unknown value '${data.value}' for endings_ENDINGREND");
  return _unknownValue;
}

/// string -> `endings_ENDINGREND`.
EndingsEndingrend strToEndingsEndingrend(String value) {
  if (value == 'top') return EndingsEndingrend.top;
  if (value == 'barred') return EndingsEndingrend.barred;
  if (value == 'grouped') return EndingsEndingrend.grouped;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for endings_ENDINGREND");
  }
  return EndingsEndingrend.none;
}

/// `episemaVis_FORM` -> string.
String episemavisFormToStr(EpisemavisForm data) {
  switch (data.value) {
    case 1:
      return 'h';
    case 2:
      return 'v';
  }
  logWarning("Unknown value '${data.value}' for episemaVis_FORM");
  return _unknownValue;
}

/// string -> `episemaVis_FORM`.
EpisemavisForm strToEpisemavisForm(String value) {
  if (value == 'h') return EpisemavisForm.h;
  if (value == 'v') return EpisemavisForm.v;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for episemaVis_FORM");
  }
  return EpisemavisForm.none;
}

/// `evidence_EVIDENCE` -> string.
String evidenceEvidenceToStr(EvidenceEvidence data) {
  switch (data.value) {
    case 1:
      return 'internal';
    case 2:
      return 'external';
    case 3:
      return 'conjecture';
  }
  logWarning("Unknown value '${data.value}' for evidence_EVIDENCE");
  return _unknownValue;
}

/// string -> `evidence_EVIDENCE`.
EvidenceEvidence strToEvidenceEvidence(String value) {
  if (value == 'internal') return EvidenceEvidence.internal;
  if (value == 'external') return EvidenceEvidence.external;
  if (value == 'conjecture') return EvidenceEvidence.conjecture;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for evidence_EVIDENCE");
  }
  return EvidenceEvidence.none;
}

/// `extSymAuth_GLYPHAUTH` -> string.
String extsymauthGlyphauthToStr(ExtsymauthGlyphauth data) {
  switch (data.value) {
    case 1:
      return 'smufl';
  }
  logWarning("Unknown value '${data.value}' for extSymAuth_GLYPHAUTH");
  return _unknownValue;
}

/// string -> `extSymAuth_GLYPHAUTH`.
ExtsymauthGlyphauth strToExtsymauthGlyphauth(String value) {
  if (value == 'smufl') return ExtsymauthGlyphauth.smufl;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for extSymAuth_GLYPHAUTH");
  }
  return ExtsymauthGlyphauth.none;
}

/// `fermataVis_FORM` -> string.
String fermatavisFormToStr(FermatavisForm data) {
  switch (data.value) {
    case 1:
      return 'inv';
    case 2:
      return 'norm';
  }
  logWarning("Unknown value '${data.value}' for fermataVis_FORM");
  return _unknownValue;
}

/// string -> `fermataVis_FORM`.
FermatavisForm strToFermatavisForm(String value) {
  if (value == 'inv') return FermatavisForm.inv;
  if (value == 'norm') return FermatavisForm.norm;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for fermataVis_FORM");
  }
  return FermatavisForm.none;
}

/// `fermataVis_SHAPE` -> string.
String fermatavisShapeToStr(FermatavisShape data) {
  switch (data.value) {
    case 1:
      return 'curved';
    case 2:
      return 'square';
    case 3:
      return 'angular';
  }
  logWarning("Unknown value '${data.value}' for fermataVis_SHAPE");
  return _unknownValue;
}

/// string -> `fermataVis_SHAPE`.
FermatavisShape strToFermatavisShape(String value) {
  if (value == 'curved') return FermatavisShape.curved;
  if (value == 'square') return FermatavisShape.square;
  if (value == 'angular') return FermatavisShape.angular;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for fermataVis_SHAPE");
  }
  return FermatavisShape.none;
}

/// `fingGrpLog_FORM` -> string.
String finggrplogFormToStr(FinggrplogForm data) {
  switch (data.value) {
    case 1:
      return 'alter';
    case 2:
      return 'combi';
    case 3:
      return 'subst';
  }
  logWarning("Unknown value '${data.value}' for fingGrpLog_FORM");
  return _unknownValue;
}

/// string -> `fingGrpLog_FORM`.
FinggrplogForm strToFinggrplogForm(String value) {
  if (value == 'alter') return FinggrplogForm.alter;
  if (value == 'combi') return FinggrplogForm.combi;
  if (value == 'subst') return FinggrplogForm.subst;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for fingGrpLog_FORM");
  }
  return FinggrplogForm.none;
}

/// `fingGrpVis_ORIENT` -> string.
String finggrpvisOrientToStr(FinggrpvisOrient data) {
  switch (data.value) {
    case 1:
      return 'horiz';
    case 2:
      return 'vert';
  }
  logWarning("Unknown value '${data.value}' for fingGrpVis_ORIENT");
  return _unknownValue;
}

/// string -> `fingGrpVis_ORIENT`.
FinggrpvisOrient strToFinggrpvisOrient(String value) {
  if (value == 'horiz') return FinggrpvisOrient.horiz;
  if (value == 'vert') return FinggrpvisOrient.vert;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for fingGrpVis_ORIENT");
  }
  return FinggrpvisOrient.none;
}

/// `graceGrpLog_ATTACH` -> string.
String gracegrplogAttachToStr(GracegrplogAttach data) {
  switch (data.value) {
    case 1:
      return 'pre';
    case 2:
      return 'post';
    case 3:
      return 'unknown';
  }
  logWarning("Unknown value '${data.value}' for graceGrpLog_ATTACH");
  return _unknownValue;
}

/// string -> `graceGrpLog_ATTACH`.
GracegrplogAttach strToGracegrplogAttach(String value) {
  if (value == 'pre') return GracegrplogAttach.pre;
  if (value == 'post') return GracegrplogAttach.post;
  if (value == 'unknown') return GracegrplogAttach.unknown;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for graceGrpLog_ATTACH");
  }
  return GracegrplogAttach.none;
}

/// `hairpinLog_FORM` -> string.
String hairpinlogFormToStr(HairpinlogForm data) {
  switch (data.value) {
    case 1:
      return 'cres';
    case 2:
      return 'dim';
  }
  logWarning("Unknown value '${data.value}' for hairpinLog_FORM");
  return _unknownValue;
}

/// string -> `hairpinLog_FORM`.
HairpinlogForm strToHairpinlogForm(String value) {
  if (value == 'cres') return HairpinlogForm.cres;
  if (value == 'dim') return HairpinlogForm.dim;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for hairpinLog_FORM");
  }
  return HairpinlogForm.none;
}

/// `harmAnl_FORM` -> string.
String harmanlFormToStr(HarmanlForm data) {
  switch (data.value) {
    case 1:
      return 'explicit';
    case 2:
      return 'implied';
  }
  logWarning("Unknown value '${data.value}' for harmAnl_FORM");
  return _unknownValue;
}

/// string -> `harmAnl_FORM`.
HarmanlForm strToHarmanlForm(String value) {
  if (value == 'explicit') return HarmanlForm.explicit;
  if (value == 'implied') return HarmanlForm.implied;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for harmAnl_FORM");
  }
  return HarmanlForm.none;
}

/// `harmVis_RENDGRID` -> string.
String harmvisRendgridToStr(HarmvisRendgrid data) {
  switch (data.value) {
    case 1:
      return 'grid';
    case 2:
      return 'gridtext';
    case 3:
      return 'text';
  }
  logWarning("Unknown value '${data.value}' for harmVis_RENDGRID");
  return _unknownValue;
}

/// string -> `harmVis_RENDGRID`.
HarmvisRendgrid strToHarmvisRendgrid(String value) {
  if (value == 'grid') return HarmvisRendgrid.grid;
  if (value == 'gridtext') return HarmvisRendgrid.gridtext;
  if (value == 'text') return HarmvisRendgrid.text;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for harmVis_RENDGRID");
  }
  return HarmvisRendgrid.none;
}

/// `lineLog_FUNC` -> string.
String linelogFuncToStr(LinelogFunc data) {
  switch (data.value) {
    case 1:
      return 'coloration';
    case 2:
      return 'ligature';
    case 3:
      return 'unknown';
  }
  logWarning("Unknown value '${data.value}' for lineLog_FUNC");
  return _unknownValue;
}

/// string -> `lineLog_FUNC`.
LinelogFunc strToLinelogFunc(String value) {
  if (value == 'coloration') return LinelogFunc.coloration;
  if (value == 'ligature') return LinelogFunc.ligature;
  if (value == 'unknown') return LinelogFunc.unknown;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for lineLog_FUNC");
  }
  return LinelogFunc.none;
}

/// `measurement_UNIT` -> string.
String measurementUnitToStr(MeasurementUnit data) {
  switch (data.value) {
    case 1:
      return 'byte';
    case 2:
      return 'char';
    case 3:
      return 'cm';
    case 4:
      return 'deg';
    case 5:
      return 'in';
    case 6:
      return 'issue';
    case 7:
      return 'ft';
    case 8:
      return 'm';
    case 9:
      return 'mm';
    case 10:
      return 'page';
    case 11:
      return 'pc';
    case 12:
      return 'pt';
    case 13:
      return 'px';
    case 14:
      return 'rad';
    case 15:
      return 'record';
    case 16:
      return 'vol';
    case 17:
      return 'vu';
  }
  logWarning("Unknown value '${data.value}' for measurement_UNIT");
  return _unknownValue;
}

/// string -> `measurement_UNIT`.
MeasurementUnit strToMeasurementUnit(String value) {
  if (value == 'byte') return MeasurementUnit.byte;
  if (value == 'char') return MeasurementUnit.char;
  if (value == 'cm') return MeasurementUnit.cm;
  if (value == 'deg') return MeasurementUnit.deg;
  if (value == 'in') return MeasurementUnit.inValue;
  if (value == 'issue') return MeasurementUnit.issue;
  if (value == 'ft') return MeasurementUnit.ft;
  if (value == 'm') return MeasurementUnit.m;
  if (value == 'mm') return MeasurementUnit.mm;
  if (value == 'page') return MeasurementUnit.page;
  if (value == 'pc') return MeasurementUnit.pc;
  if (value == 'pt') return MeasurementUnit.pt;
  if (value == 'px') return MeasurementUnit.px;
  if (value == 'rad') return MeasurementUnit.rad;
  if (value == 'record') return MeasurementUnit.record;
  if (value == 'vol') return MeasurementUnit.vol;
  if (value == 'vu') return MeasurementUnit.vu;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for measurement_UNIT");
  }
  return MeasurementUnit.none;
}

/// `meiVersion_MEIVERSION` -> string.
String meiversionMeiversionToStr(MeiversionMeiversion data) {
  switch (data.value) {
    case 1:
      return '2013';
    case 2:
      return '3.0.0';
    case 3:
      return '4.0.0';
    case 4:
      return '4.0.1';
    case 5:
      return '5.0';
    case 6:
      return '5.1';
    case 7:
      return '5.0+basic';
    case 8:
      return '5.0+CMN';
    case 9:
      return '5.0+Mensural';
    case 10:
      return '5.0+Neumes';
    case 11:
      return '5.1+basic';
    case 12:
      return '5.1+CMN';
    case 13:
      return '5.1+Mensural';
    case 14:
      return '5.1+Neumes';
    case 15:
      return '6.0-dev';
    case 16:
      return '6.0-dev+basic';
  }
  logWarning("Unknown value '${data.value}' for meiVersion_MEIVERSION");
  return _unknownValue;
}

/// string -> `meiVersion_MEIVERSION`.
MeiversionMeiversion strToMeiversionMeiversion(String value) {
  if (value == '2013') return MeiversionMeiversion.n2013;
  if (value == '3.0.0') return MeiversionMeiversion.n300;
  if (value == '4.0.0') return MeiversionMeiversion.n400;
  if (value == '4.0.1') return MeiversionMeiversion.n401;
  if (value == '5.0') return MeiversionMeiversion.n50;
  if (value == '5.1') return MeiversionMeiversion.n51;
  if (value == '5.0+basic') return MeiversionMeiversion.n50plusbasic;
  if (value == '5.0+CMN') return MeiversionMeiversion.n50pluscmn;
  if (value == '5.0+Mensural') return MeiversionMeiversion.n50plusmensural;
  if (value == '5.0+Neumes') return MeiversionMeiversion.n50plusneumes;
  if (value == '5.1+basic') return MeiversionMeiversion.n51plusbasic;
  if (value == '5.1+CMN') return MeiversionMeiversion.n51pluscmn;
  if (value == '5.1+Mensural') return MeiversionMeiversion.n51plusmensural;
  if (value == '5.1+Neumes') return MeiversionMeiversion.n51plusneumes;
  if (value == '6.0-dev') return MeiversionMeiversion.n60Dev;
  if (value == '6.0-dev+basic') return MeiversionMeiversion.n60Devplusbasic;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for meiVersion_MEIVERSION");
  }
  return MeiversionMeiversion.none;
}

/// `mensurVis_FORM` -> string.
String mensurvisFormToStr(MensurvisForm data) {
  switch (data.value) {
    case 1:
      return 'horizontal';
    case 2:
      return 'vertical';
  }
  logWarning("Unknown value '${data.value}' for mensurVis_FORM");
  return _unknownValue;
}

/// string -> `mensurVis_FORM`.
MensurvisForm strToMensurvisForm(String value) {
  if (value == 'horizontal') return MensurvisForm.horizontal;
  if (value == 'vertical') return MensurvisForm.vertical;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for mensurVis_FORM");
  }
  return MensurvisForm.none;
}

/// `mensuralVis_MENSURFORM` -> string.
String mensuralvisMensurformToStr(MensuralvisMensurform data) {
  switch (data.value) {
    case 1:
      return 'horizontal';
    case 2:
      return 'vertical';
  }
  logWarning("Unknown value '${data.value}' for mensuralVis_MENSURFORM");
  return _unknownValue;
}

/// string -> `mensuralVis_MENSURFORM`.
MensuralvisMensurform strToMensuralvisMensurform(String value) {
  if (value == 'horizontal') return MensuralvisMensurform.horizontal;
  if (value == 'vertical') return MensuralvisMensurform.vertical;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for mensuralVis_MENSURFORM");
  }
  return MensuralvisMensurform.none;
}

/// `meterConformance_METCON` -> string.
String meterconformanceMetconToStr(MeterconformanceMetcon data) {
  switch (data.value) {
    case 1:
      return 'c';
    case 2:
      return 'i';
    case 3:
      return 'o';
  }
  logWarning("Unknown value '${data.value}' for meterConformance_METCON");
  return _unknownValue;
}

/// string -> `meterConformance_METCON`.
MeterconformanceMetcon strToMeterconformanceMetcon(String value) {
  if (value == 'c') return MeterconformanceMetcon.c;
  if (value == 'i') return MeterconformanceMetcon.i;
  if (value == 'o') return MeterconformanceMetcon.o;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for meterConformance_METCON");
  }
  return MeterconformanceMetcon.none;
}

/// `meterSigGrpLog_FUNC` -> string.
String metersiggrplogFuncToStr(MetersiggrplogFunc data) {
  switch (data.value) {
    case 1:
      return 'alternating';
    case 2:
      return 'interchanging';
    case 3:
      return 'mixed';
    case 4:
      return 'other';
  }
  logWarning("Unknown value '${data.value}' for meterSigGrpLog_FUNC");
  return _unknownValue;
}

/// string -> `meterSigGrpLog_FUNC`.
MetersiggrplogFunc strToMetersiggrplogFunc(String value) {
  if (value == 'alternating') return MetersiggrplogFunc.alternating;
  if (value == 'interchanging') return MetersiggrplogFunc.interchanging;
  if (value == 'mixed') return MetersiggrplogFunc.mixed;
  if (value == 'other') return MetersiggrplogFunc.other;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for meterSigGrpLog_FUNC");
  }
  return MetersiggrplogFunc.none;
}

/// `mordentLog_FORM` -> string.
String mordentlogFormToStr(MordentlogForm data) {
  switch (data.value) {
    case 1:
      return 'lower';
    case 2:
      return 'upper';
  }
  logWarning("Unknown value '${data.value}' for mordentLog_FORM");
  return _unknownValue;
}

/// string -> `mordentLog_FORM`.
MordentlogForm strToMordentlogForm(String value) {
  if (value == 'lower') return MordentlogForm.lower;
  if (value == 'upper') return MordentlogForm.upper;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for mordentLog_FORM");
  }
  return MordentlogForm.none;
}

/// `ncForm_CON` -> string.
String ncformConToStr(NcformCon data) {
  switch (data.value) {
    case 1:
      return 'g';
    case 2:
      return 'l';
    case 3:
      return 'e';
  }
  logWarning("Unknown value '${data.value}' for ncForm_CON");
  return _unknownValue;
}

/// string -> `ncForm_CON`.
NcformCon strToNcformCon(String value) {
  if (value == 'g') return NcformCon.g;
  if (value == 'l') return NcformCon.l;
  if (value == 'e') return NcformCon.e;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for ncForm_CON");
  }
  return NcformCon.none;
}

/// `ncForm_RELLEN` -> string.
String ncformRellenToStr(NcformRellen data) {
  switch (data.value) {
    case 1:
      return 'l';
    case 2:
      return 's';
  }
  logWarning("Unknown value '${data.value}' for ncForm_RELLEN");
  return _unknownValue;
}

/// string -> `ncForm_RELLEN`.
NcformRellen strToNcformRellen(String value) {
  if (value == 'l') return NcformRellen.l;
  if (value == 's') return NcformRellen.s;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for ncForm_RELLEN");
  }
  return NcformRellen.none;
}

/// `neumeType_TYPE` -> string.
String neumetypeTypeToStr(NeumetypeType data) {
  switch (data.value) {
    case 1:
      return 'apostropha';
    case 2:
      return 'bistropha';
    case 3:
      return 'cephalicus';
    case 4:
      return 'climacus';
    case 5:
      return 'clivis';
    case 6:
      return 'epiphonus';
    case 7:
      return 'oriscus';
    case 8:
      return 'pes';
    case 9:
      return 'pessubpunctis';
    case 10:
      return 'porrectus';
    case 11:
      return 'porrectusflexus';
    case 12:
      return 'pressusmaior';
    case 13:
      return 'pressusminor';
    case 14:
      return 'punctum';
    case 15:
      return 'quilisma';
    case 16:
      return 'scandicus';
    case 17:
      return 'strophicus';
    case 18:
      return 'torculus';
    case 19:
      return 'torculusresupinus';
    case 20:
      return 'tristropha';
    case 21:
      return 'virga';
    case 22:
      return 'virgastrata';
  }
  logWarning("Unknown value '${data.value}' for neumeType_TYPE");
  return _unknownValue;
}

/// string -> `neumeType_TYPE`.
NeumetypeType strToNeumetypeType(String value) {
  if (value == 'apostropha') return NeumetypeType.apostropha;
  if (value == 'bistropha') return NeumetypeType.bistropha;
  if (value == 'cephalicus') return NeumetypeType.cephalicus;
  if (value == 'climacus') return NeumetypeType.climacus;
  if (value == 'clivis') return NeumetypeType.clivis;
  if (value == 'epiphonus') return NeumetypeType.epiphonus;
  if (value == 'oriscus') return NeumetypeType.oriscus;
  if (value == 'pes') return NeumetypeType.pes;
  if (value == 'pessubpunctis') return NeumetypeType.pessubpunctis;
  if (value == 'porrectus') return NeumetypeType.porrectus;
  if (value == 'porrectusflexus') return NeumetypeType.porrectusflexus;
  if (value == 'pressusmaior') return NeumetypeType.pressusmaior;
  if (value == 'pressusminor') return NeumetypeType.pressusminor;
  if (value == 'punctum') return NeumetypeType.punctum;
  if (value == 'quilisma') return NeumetypeType.quilisma;
  if (value == 'scandicus') return NeumetypeType.scandicus;
  if (value == 'strophicus') return NeumetypeType.strophicus;
  if (value == 'torculus') return NeumetypeType.torculus;
  if (value == 'torculusresupinus') return NeumetypeType.torculusresupinus;
  if (value == 'tristropha') return NeumetypeType.tristropha;
  if (value == 'virga') return NeumetypeType.virga;
  if (value == 'virgastrata') return NeumetypeType.virgastrata;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for neumeType_TYPE");
  }
  return NeumetypeType.none;
}

/// `noteGes_EXTREMIS` -> string.
String notegesExtremisToStr(NotegesExtremis data) {
  switch (data.value) {
    case 1:
      return 'highest';
    case 2:
      return 'lowest';
  }
  logWarning("Unknown value '${data.value}' for noteGes_EXTREMIS");
  return _unknownValue;
}

/// string -> `noteGes_EXTREMIS`.
NotegesExtremis strToNotegesExtremis(String value) {
  if (value == 'highest') return NotegesExtremis.highest;
  if (value == 'lowest') return NotegesExtremis.lowest;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for noteGes_EXTREMIS");
  }
  return NotegesExtremis.none;
}

/// `noteHeads_HEADAUTH` -> string.
String noteheadsHeadauthToStr(NoteheadsHeadauth data) {
  switch (data.value) {
    case 1:
      return 'smufl';
  }
  logWarning("Unknown value '${data.value}' for noteHeads_HEADAUTH");
  return _unknownValue;
}

/// string -> `noteHeads_HEADAUTH`.
NoteheadsHeadauth strToNoteheadsHeadauth(String value) {
  if (value == 'smufl') return NoteheadsHeadauth.smufl;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for noteHeads_HEADAUTH");
  }
  return NoteheadsHeadauth.none;
}

/// `octaveLog_COLL` -> string.
String octavelogCollToStr(OctavelogColl data) {
  switch (data.value) {
    case 1:
      return 'coll';
  }
  logWarning("Unknown value '${data.value}' for octaveLog_COLL");
  return _unknownValue;
}

/// string -> `octaveLog_COLL`.
OctavelogColl strToOctavelogColl(String value) {
  if (value == 'coll') return OctavelogColl.coll;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for octaveLog_COLL");
  }
  return OctavelogColl.none;
}

/// `pbVis_FOLIUM` -> string.
String pbvisFoliumToStr(PbvisFolium data) {
  switch (data.value) {
    case 1:
      return 'verso';
    case 2:
      return 'recto';
  }
  logWarning("Unknown value '${data.value}' for pbVis_FOLIUM");
  return _unknownValue;
}

/// string -> `pbVis_FOLIUM`.
PbvisFolium strToPbvisFolium(String value) {
  if (value == 'verso') return PbvisFolium.verso;
  if (value == 'recto') return PbvisFolium.recto;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for pbVis_FOLIUM");
  }
  return PbvisFolium.none;
}

/// `pedalLog_DIR` -> string.
String pedallogDirToStr(PedallogDir data) {
  switch (data.value) {
    case 1:
      return 'down';
    case 2:
      return 'up';
    case 3:
      return 'half';
    case 4:
      return 'bounce';
  }
  logWarning("Unknown value '${data.value}' for pedalLog_DIR");
  return _unknownValue;
}

/// string -> `pedalLog_DIR`.
PedallogDir strToPedallogDir(String value) {
  if (value == 'down') return PedallogDir.down;
  if (value == 'up') return PedallogDir.up;
  if (value == 'half') return PedallogDir.half;
  if (value == 'bounce') return PedallogDir.bounce;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for pedalLog_DIR");
  }
  return PedallogDir.none;
}

/// `pedalLog_FUNC` -> string.
String pedallogFuncToStr(PedallogFunc data) {
  switch (data.value) {
    case 1:
      return 'sustain';
    case 2:
      return 'soft';
    case 3:
      return 'sostenuto';
    case 4:
      return 'silent';
  }
  logWarning("Unknown value '${data.value}' for pedalLog_FUNC");
  return _unknownValue;
}

/// string -> `pedalLog_FUNC`.
PedallogFunc strToPedallogFunc(String value) {
  if (value == 'sustain') return PedallogFunc.sustain;
  if (value == 'soft') return PedallogFunc.soft;
  if (value == 'sostenuto') return PedallogFunc.sostenuto;
  if (value == 'silent') return PedallogFunc.silent;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for pedalLog_FUNC");
  }
  return PedallogFunc.none;
}

/// `pointing_XLINKACTUATE` -> string.
String pointingXlinkactuateToStr(PointingXlinkactuate data) {
  switch (data.value) {
    case 1:
      return 'onLoad';
    case 2:
      return 'onRequest';
    case 3:
      return 'none';
    case 4:
      return 'other';
  }
  logWarning("Unknown value '${data.value}' for pointing_XLINKACTUATE");
  return _unknownValue;
}

/// string -> `pointing_XLINKACTUATE`.
PointingXlinkactuate strToPointingXlinkactuate(String value) {
  if (value == 'onLoad') return PointingXlinkactuate.onload;
  if (value == 'onRequest') return PointingXlinkactuate.onrequest;
  if (value == 'none') return PointingXlinkactuate.none0;
  if (value == 'other') return PointingXlinkactuate.other;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for pointing_XLINKACTUATE");
  }
  return PointingXlinkactuate.none;
}

/// `pointing_XLINKSHOW` -> string.
String pointingXlinkshowToStr(PointingXlinkshow data) {
  switch (data.value) {
    case 1:
      return 'new';
    case 2:
      return 'replace';
    case 3:
      return 'embed';
    case 4:
      return 'none';
    case 5:
      return 'other';
  }
  logWarning("Unknown value '${data.value}' for pointing_XLINKSHOW");
  return _unknownValue;
}

/// string -> `pointing_XLINKSHOW`.
PointingXlinkshow strToPointingXlinkshow(String value) {
  if (value == 'new') return PointingXlinkshow.newValue;
  if (value == 'replace') return PointingXlinkshow.replace;
  if (value == 'embed') return PointingXlinkshow.embed;
  if (value == 'none') return PointingXlinkshow.none0;
  if (value == 'other') return PointingXlinkshow.other;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for pointing_XLINKSHOW");
  }
  return PointingXlinkshow.none;
}

/// `recordType_RECORDTYPE` -> string.
String recordtypeRecordtypeToStr(RecordtypeRecordtype data) {
  switch (data.value) {
    case 1:
      return 'a';
    case 2:
      return 'c';
    case 3:
      return 'd';
    case 4:
      return 'e';
    case 5:
      return 'f';
    case 6:
      return 'g';
    case 7:
      return 'i';
    case 8:
      return 'j';
    case 9:
      return 'k';
    case 10:
      return 'm';
    case 11:
      return 'o';
    case 12:
      return 'p';
    case 13:
      return 'r';
    case 14:
      return 't';
  }
  logWarning("Unknown value '${data.value}' for recordType_RECORDTYPE");
  return _unknownValue;
}

/// string -> `recordType_RECORDTYPE`.
RecordtypeRecordtype strToRecordtypeRecordtype(String value) {
  if (value == 'a') return RecordtypeRecordtype.a;
  if (value == 'c') return RecordtypeRecordtype.c;
  if (value == 'd') return RecordtypeRecordtype.d;
  if (value == 'e') return RecordtypeRecordtype.e;
  if (value == 'f') return RecordtypeRecordtype.f;
  if (value == 'g') return RecordtypeRecordtype.g;
  if (value == 'i') return RecordtypeRecordtype.i;
  if (value == 'j') return RecordtypeRecordtype.j;
  if (value == 'k') return RecordtypeRecordtype.k;
  if (value == 'm') return RecordtypeRecordtype.m;
  if (value == 'o') return RecordtypeRecordtype.o;
  if (value == 'p') return RecordtypeRecordtype.p;
  if (value == 'r') return RecordtypeRecordtype.r;
  if (value == 't') return RecordtypeRecordtype.t;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for recordType_RECORDTYPE");
  }
  return RecordtypeRecordtype.none;
}

/// `regularMethod_METHOD` -> string.
String regularmethodMethodToStr(RegularmethodMethod data) {
  switch (data.value) {
    case 1:
      return 'silent';
    case 2:
      return 'markup';
  }
  logWarning("Unknown value '${data.value}' for regularMethod_METHOD");
  return _unknownValue;
}

/// string -> `regularMethod_METHOD`.
RegularmethodMethod strToRegularmethodMethod(String value) {
  if (value == 'silent') return RegularmethodMethod.silent;
  if (value == 'markup') return RegularmethodMethod.markup;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for regularMethod_METHOD");
  }
  return RegularmethodMethod.none;
}

/// `rehearsal_REHENCLOSE` -> string.
String rehearsalRehencloseToStr(RehearsalRehenclose data) {
  switch (data.value) {
    case 1:
      return 'box';
    case 2:
      return 'circle';
    case 3:
      return 'none';
  }
  logWarning("Unknown value '${data.value}' for rehearsal_REHENCLOSE");
  return _unknownValue;
}

/// string -> `rehearsal_REHENCLOSE`.
RehearsalRehenclose strToRehearsalRehenclose(String value) {
  if (value == 'box') return RehearsalRehenclose.box;
  if (value == 'circle') return RehearsalRehenclose.circle;
  if (value == 'none') return RehearsalRehenclose.none0;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for rehearsal_REHENCLOSE");
  }
  return RehearsalRehenclose.none;
}

/// `repeatMarkLog_FUNC` -> string.
String repeatmarklogFuncToStr(RepeatmarklogFunc data) {
  switch (data.value) {
    case 1:
      return 'coda';
    case 2:
      return 'segno';
    case 3:
      return 'dalSegno';
    case 4:
      return 'daCapo';
    case 5:
      return 'fine';
    case 6:
      return 'daCapoAlFine';
    case 7:
      return 'dalSegnoAlFine';
    case 8:
      return 'daCapoAlCoda';
    case 9:
      return 'dalSegnoAlCoda';
    case 10:
      return 'repeatLeft';
    case 11:
      return 'repeatRight';
    case 12:
      return 'repeatRightLeft';
  }
  logWarning("Unknown value '${data.value}' for repeatMarkLog_FUNC");
  return _unknownValue;
}

/// string -> `repeatMarkLog_FUNC`.
RepeatmarklogFunc strToRepeatmarklogFunc(String value) {
  if (value == 'coda') return RepeatmarklogFunc.coda;
  if (value == 'segno') return RepeatmarklogFunc.segno;
  if (value == 'dalSegno') return RepeatmarklogFunc.dalsegno;
  if (value == 'daCapo') return RepeatmarklogFunc.dacapo;
  if (value == 'fine') return RepeatmarklogFunc.fine;
  if (value == 'daCapoAlFine') return RepeatmarklogFunc.dacapoalfine;
  if (value == 'dalSegnoAlFine') return RepeatmarklogFunc.dalsegnoalfine;
  if (value == 'daCapoAlCoda') return RepeatmarklogFunc.dacapoalcoda;
  if (value == 'dalSegnoAlCoda') return RepeatmarklogFunc.dalsegnoalcoda;
  if (value == 'repeatLeft') return RepeatmarklogFunc.repeatleft;
  if (value == 'repeatRight') return RepeatmarklogFunc.repeatright;
  if (value == 'repeatRightLeft') return RepeatmarklogFunc.repeatrightleft;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for repeatMarkLog_FUNC");
  }
  return RepeatmarklogFunc.none;
}

/// `sbVis_FORM` -> string.
String sbvisFormToStr(SbvisForm data) {
  switch (data.value) {
    case 1:
      return 'hash';
  }
  logWarning("Unknown value '${data.value}' for sbVis_FORM");
  return _unknownValue;
}

/// string -> `sbVis_FORM`.
SbvisForm strToSbvisForm(String value) {
  if (value == 'hash') return SbvisForm.hash;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for sbVis_FORM");
  }
  return SbvisForm.none;
}

/// `staffGroupingSym_SYMBOL` -> string.
String staffgroupingsymSymbolToStr(StaffgroupingsymSymbol data) {
  switch (data.value) {
    case 1:
      return 'brace';
    case 2:
      return 'bracket';
    case 3:
      return 'bracketsq';
    case 4:
      return 'line';
    case 5:
      return 'none';
  }
  logWarning("Unknown value '${data.value}' for staffGroupingSym_SYMBOL");
  return _unknownValue;
}

/// string -> `staffGroupingSym_SYMBOL`.
StaffgroupingsymSymbol strToStaffgroupingsymSymbol(String value) {
  if (value == 'brace') return StaffgroupingsymSymbol.brace;
  if (value == 'bracket') return StaffgroupingsymSymbol.bracket;
  if (value == 'bracketsq') return StaffgroupingsymSymbol.bracketsq;
  if (value == 'line') return StaffgroupingsymSymbol.line;
  if (value == 'none') return StaffgroupingsymSymbol.none0;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for staffGroupingSym_SYMBOL");
  }
  return StaffgroupingsymSymbol.none;
}

/// `sylLog_CON` -> string.
String syllogConToStr(SyllogCon data) {
  switch (data.value) {
    case 1:
      return 's';
    case 2:
      return 'd';
    case 3:
      return 'u';
    case 4:
      return 't';
    case 5:
      return 'c';
    case 6:
      return 'v';
    case 7:
      return 'i';
    case 8:
      return 'b';
  }
  logWarning("Unknown value '${data.value}' for sylLog_CON");
  return _unknownValue;
}

/// string -> `sylLog_CON`.
SyllogCon strToSyllogCon(String value) {
  if (value == 's') return SyllogCon.s;
  if (value == 'd') return SyllogCon.d;
  if (value == 'u') return SyllogCon.u;
  if (value == 't') return SyllogCon.t;
  if (value == 'c') return SyllogCon.c;
  if (value == 'v') return SyllogCon.v;
  if (value == 'i') return SyllogCon.i;
  if (value == 'b') return SyllogCon.b;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for sylLog_CON");
  }
  return SyllogCon.none;
}

/// `sylLog_WORDPOS` -> string.
String syllogWordposToStr(SyllogWordpos data) {
  switch (data.value) {
    case 1:
      return 'i';
    case 2:
      return 'm';
    case 3:
      return 's';
    case 4:
      return 't';
  }
  logWarning("Unknown value '${data.value}' for sylLog_WORDPOS");
  return _unknownValue;
}

/// string -> `sylLog_WORDPOS`.
SyllogWordpos strToSyllogWordpos(String value) {
  if (value == 'i') return SyllogWordpos.i;
  if (value == 'm') return SyllogWordpos.m;
  if (value == 's') return SyllogWordpos.s;
  if (value == 't') return SyllogWordpos.t;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for sylLog_WORDPOS");
  }
  return SyllogWordpos.none;
}

/// `targetEval_EVALUATE` -> string.
String targetevalEvaluateToStr(TargetevalEvaluate data) {
  switch (data.value) {
    case 1:
      return 'all';
    case 2:
      return 'one';
    case 3:
      return 'none';
  }
  logWarning("Unknown value '${data.value}' for targetEval_EVALUATE");
  return _unknownValue;
}

/// string -> `targetEval_EVALUATE`.
TargetevalEvaluate strToTargetevalEvaluate(String value) {
  if (value == 'all') return TargetevalEvaluate.all;
  if (value == 'one') return TargetevalEvaluate.one;
  if (value == 'none') return TargetevalEvaluate.none0;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for targetEval_EVALUATE");
  }
  return TargetevalEvaluate.none;
}

/// `tempoLog_FUNC` -> string.
String tempologFuncToStr(TempologFunc data) {
  switch (data.value) {
    case 1:
      return 'continuous';
    case 2:
      return 'instantaneous';
    case 3:
      return 'metricmod';
    case 4:
      return 'precedente';
  }
  logWarning("Unknown value '${data.value}' for tempoLog_FUNC");
  return _unknownValue;
}

/// string -> `tempoLog_FUNC`.
TempologFunc strToTempologFunc(String value) {
  if (value == 'continuous') return TempologFunc.continuous;
  if (value == 'instantaneous') return TempologFunc.instantaneous;
  if (value == 'metricmod') return TempologFunc.metricmod;
  if (value == 'precedente') return TempologFunc.precedente;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for tempoLog_FUNC");
  }
  return TempologFunc.none;
}

/// `tremForm_FORM` -> string.
String tremformFormToStr(TremformForm data) {
  switch (data.value) {
    case 1:
      return 'meas';
    case 2:
      return 'unmeas';
  }
  logWarning("Unknown value '${data.value}' for tremForm_FORM");
  return _unknownValue;
}

/// string -> `tremForm_FORM`.
TremformForm strToTremformForm(String value) {
  if (value == 'meas') return TremformForm.meas;
  if (value == 'unmeas') return TremformForm.unmeas;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for tremForm_FORM");
  }
  return TremformForm.none;
}

/// `tupletVis_NUMFORMAT` -> string.
String tupletvisNumformatToStr(TupletvisNumformat data) {
  switch (data.value) {
    case 1:
      return 'count';
    case 2:
      return 'ratio';
  }
  logWarning("Unknown value '${data.value}' for tupletVis_NUMFORMAT");
  return _unknownValue;
}

/// string -> `tupletVis_NUMFORMAT`.
TupletvisNumformat strToTupletvisNumformat(String value) {
  if (value == 'count') return TupletvisNumformat.count;
  if (value == 'ratio') return TupletvisNumformat.ratio;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for tupletVis_NUMFORMAT");
  }
  return TupletvisNumformat.none;
}

/// `turnLog_FORM` -> string.
String turnlogFormToStr(TurnlogForm data) {
  switch (data.value) {
    case 1:
      return 'lower';
    case 2:
      return 'upper';
  }
  logWarning("Unknown value '${data.value}' for turnLog_FORM");
  return _unknownValue;
}

/// string -> `turnLog_FORM`.
TurnlogForm strToTurnlogForm(String value) {
  if (value == 'lower') return TurnlogForm.lower;
  if (value == 'upper') return TurnlogForm.upper;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for turnLog_FORM");
  }
  return TurnlogForm.none;
}

/// `voltaGroupingSym_VOLTASYM` -> string.
String voltagroupingsymVoltasymToStr(VoltagroupingsymVoltasym data) {
  switch (data.value) {
    case 1:
      return 'brace';
    case 2:
      return 'bracket';
    case 3:
      return 'bracketsq';
    case 4:
      return 'line';
    case 5:
      return 'none';
  }
  logWarning("Unknown value '${data.value}' for voltaGroupingSym_VOLTASYM");
  return _unknownValue;
}

/// string -> `voltaGroupingSym_VOLTASYM`.
VoltagroupingsymVoltasym strToVoltagroupingsymVoltasym(String value) {
  if (value == 'brace') return VoltagroupingsymVoltasym.brace;
  if (value == 'bracket') return VoltagroupingsymVoltasym.bracket;
  if (value == 'bracketsq') return VoltagroupingsymVoltasym.bracketsq;
  if (value == 'line') return VoltagroupingsymVoltasym.line;
  if (value == 'none') return VoltagroupingsymVoltasym.none0;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for voltaGroupingSym_VOLTASYM");
  }
  return VoltagroupingsymVoltasym.none;
}

/// `whitespace_XMLSPACE` -> string.
String whitespaceXmlspaceToStr(WhitespaceXmlspace data) {
  switch (data.value) {
    case 1:
      return 'default';
    case 2:
      return 'preserve';
  }
  logWarning("Unknown value '${data.value}' for whitespace_XMLSPACE");
  return _unknownValue;
}

/// string -> `whitespace_XMLSPACE`.
WhitespaceXmlspace strToWhitespaceXmlspace(String value) {
  if (value == 'default') return WhitespaceXmlspace.defaultValue;
  if (value == 'preserve') return WhitespaceXmlspace.preserve;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for whitespace_XMLSPACE");
  }
  return WhitespaceXmlspace.none;
}
