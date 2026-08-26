// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_gestural.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.AccidentalGes` (mirrors `vrv::AttAccidentalGes`).
mixin AttAccidentalGes {
  /// `accid.ges` — data_ACCIDENTAL_GESTURAL.
  AccidentalGestural? accidGes;
  bool get hasAccidGes => accidGes != null;

  /// Mirrors `AttAccidentalGes::ReadAccidentalGes`.
  bool readAccidentalGes(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final accidGesRaw = element.get('accid.ges');
    if (accidGesRaw != null) {
      accidGes = strToAccidentalGestural(accidGesRaw);
      if (removeAttr) element.remove('accid.ges');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAccidentalGes::WriteAccidentalGes`.
  void writeAccidentalGes(XmlBuilder element) {
    if (hasAccidGes) {
      element.attribute('accid.ges', accidentalGesturalToStr(accidGes!));
    }
  }

  /// Copies the `AttAccidentalGes` members from [other].
  void copyAttAccidentalGes(covariant AttAccidentalGes other) {
    accidGes = other.accidGes;
  }
}

/// MEI attribute class for `att.ArticulationGes` (mirrors `vrv::AttArticulationGes`).
mixin AttArticulationGes {
  /// `artic.ges` — data_ARTICULATION_List.
  List<Articulation>? articGes;
  bool get hasArticGes => articGes != null;

  /// Mirrors `AttArticulationGes::ReadArticulationGes`.
  bool readArticulationGes(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final articGesRaw = element.get('artic.ges');
    if (articGesRaw != null) {
      articGes = strToArticulationList(articGesRaw);
      if (removeAttr) element.remove('artic.ges');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttArticulationGes::WriteArticulationGes`.
  void writeArticulationGes(XmlBuilder element) {
    if (hasArticGes) {
      element.attribute('artic.ges', articulationListToStr(articGes!));
    }
  }

  /// Copies the `AttArticulationGes` members from [other].
  void copyAttArticulationGes(covariant AttArticulationGes other) {
    articGes = other.articGes;
  }
}

/// MEI attribute class for `att.Attacking` (mirrors `vrv::AttAttacking`).
mixin AttAttacking {
  /// `attacca` — data_BOOLEAN.
  bool? attacca;
  bool get hasAttacca => attacca != null;

  /// Mirrors `AttAttacking::ReadAttacking`.
  bool readAttacking(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final attaccaRaw = element.get('attacca');
    if (attaccaRaw != null) {
      attacca = strToBoolean(attaccaRaw);
      if (removeAttr) element.remove('attacca');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttAttacking::WriteAttacking`.
  void writeAttacking(XmlBuilder element) {
    if (hasAttacca) {
      element.attribute('attacca', booleanToStr(attacca!));
    }
  }

  /// Copies the `AttAttacking` members from [other].
  void copyAttAttacking(covariant AttAttacking other) {
    attacca = other.attacca;
  }
}

/// MEI attribute class for `att.BendGes` (mirrors `vrv::AttBendGes`).
mixin AttBendGes {
  /// `amount` — double.
  double? amount;
  bool get hasAmount => amount != null;

  /// Mirrors `AttBendGes::ReadBendGes`.
  bool readBendGes(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final amountRaw = element.get('amount');
    if (amountRaw != null) {
      amount = strToDbl(amountRaw);
      if (removeAttr) element.remove('amount');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttBendGes::WriteBendGes`.
  void writeBendGes(XmlBuilder element) {
    if (hasAmount) {
      element.attribute('amount', dblToStr(amount!));
    }
  }

  /// Copies the `AttBendGes` members from [other].
  void copyAttBendGes(covariant AttBendGes other) {
    amount = other.amount;
  }
}

/// MEI attribute class for `att.DurationGes` (mirrors `vrv::AttDurationGes`).
mixin AttDurationGes {
  /// `dur.ges` — data_DURATION.
  MeiDuration? durGes;
  bool get hasDurGes => durGes != null;

  /// `dots.ges` — int.
  int? dotsGes;
  bool get hasDotsGes => dotsGes != null;

  /// `dur.metrical` — double.
  double? durMetrical;
  bool get hasDurMetrical => durMetrical != null;

  /// `dur.ppq` — int.
  int? durPpq;
  bool get hasDurPpq => durPpq != null;

  /// `dur.real` — double.
  double? durReal;
  bool get hasDurReal => durReal != null;

  /// `dur.recip` — std::string.
  String? durRecip;
  bool get hasDurRecip => durRecip != null;

  /// Mirrors `AttDurationGes::ReadDurationGes`.
  bool readDurationGes(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final durGesRaw = element.get('dur.ges');
    if (durGesRaw != null) {
      durGes = strToDuration(durGesRaw);
      if (removeAttr) element.remove('dur.ges');
      hasAttribute = true;
    }
    final dotsGesRaw = element.get('dots.ges');
    if (dotsGesRaw != null) {
      dotsGes = strToInt(dotsGesRaw);
      if (removeAttr) element.remove('dots.ges');
      hasAttribute = true;
    }
    final durMetricalRaw = element.get('dur.metrical');
    if (durMetricalRaw != null) {
      durMetrical = strToDbl(durMetricalRaw);
      if (removeAttr) element.remove('dur.metrical');
      hasAttribute = true;
    }
    final durPpqRaw = element.get('dur.ppq');
    if (durPpqRaw != null) {
      durPpq = strToInt(durPpqRaw);
      if (removeAttr) element.remove('dur.ppq');
      hasAttribute = true;
    }
    final durRealRaw = element.get('dur.real');
    if (durRealRaw != null) {
      durReal = strToDbl(durRealRaw);
      if (removeAttr) element.remove('dur.real');
      hasAttribute = true;
    }
    final durRecipRaw = element.get('dur.recip');
    if (durRecipRaw != null) {
      durRecip = identityStr(durRecipRaw);
      if (removeAttr) element.remove('dur.recip');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDurationGes::WriteDurationGes`.
  void writeDurationGes(XmlBuilder element) {
    if (hasDurGes) {
      element.attribute('dur.ges', durationToStr(durGes!));
    }
    if (hasDotsGes) {
      element.attribute('dots.ges', intToStr(dotsGes!));
    }
    if (hasDurMetrical) {
      element.attribute('dur.metrical', dblToStr(durMetrical!));
    }
    if (hasDurPpq) {
      element.attribute('dur.ppq', intToStr(durPpq!));
    }
    if (hasDurReal) {
      element.attribute('dur.real', dblToStr(durReal!));
    }
    if (hasDurRecip) {
      element.attribute('dur.recip', identityStr(durRecip!));
    }
  }

  /// Copies the `AttDurationGes` members from [other].
  void copyAttDurationGes(covariant AttDurationGes other) {
    durGes = other.durGes;
    dotsGes = other.dotsGes;
    durMetrical = other.durMetrical;
    durPpq = other.durPpq;
    durReal = other.durReal;
    durRecip = other.durRecip;
  }
}

/// MEI attribute class for `att.NoteGes` (mirrors `vrv::AttNoteGes`).
mixin AttNoteGes {
  /// `extremis` — noteGes_EXTREMIS.
  NotegesExtremis? extremis;
  bool get hasExtremis => extremis != null;

  /// Mirrors `AttNoteGes::ReadNoteGes`.
  bool readNoteGes(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final extremisRaw = element.get('extremis');
    if (extremisRaw != null) {
      extremis = strToNotegesExtremis(extremisRaw);
      if (removeAttr) element.remove('extremis');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNoteGes::WriteNoteGes`.
  void writeNoteGes(XmlBuilder element) {
    if (hasExtremis) {
      element.attribute('extremis', notegesExtremisToStr(extremis!));
    }
  }

  /// Copies the `AttNoteGes` members from [other].
  void copyAttNoteGes(covariant AttNoteGes other) {
    extremis = other.extremis;
  }
}

/// MEI attribute class for `att.OrnamentAccidGes` (mirrors `vrv::AttOrnamentAccidGes`).
mixin AttOrnamentAccidGes {
  /// `accidupper.ges` — data_ACCIDENTAL_GESTURAL.
  AccidentalGestural? accidupperGes;
  bool get hasAccidupperGes => accidupperGes != null;

  /// `accidlower.ges` — data_ACCIDENTAL_GESTURAL.
  AccidentalGestural? accidlowerGes;
  bool get hasAccidlowerGes => accidlowerGes != null;

  /// Mirrors `AttOrnamentAccidGes::ReadOrnamentAccidGes`.
  bool readOrnamentAccidGes(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final accidupperGesRaw = element.get('accidupper.ges');
    if (accidupperGesRaw != null) {
      accidupperGes = strToAccidentalGestural(accidupperGesRaw);
      if (removeAttr) element.remove('accidupper.ges');
      hasAttribute = true;
    }
    final accidlowerGesRaw = element.get('accidlower.ges');
    if (accidlowerGesRaw != null) {
      accidlowerGes = strToAccidentalGestural(accidlowerGesRaw);
      if (removeAttr) element.remove('accidlower.ges');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttOrnamentAccidGes::WriteOrnamentAccidGes`.
  void writeOrnamentAccidGes(XmlBuilder element) {
    if (hasAccidupperGes) {
      element.attribute(
          'accidupper.ges', accidentalGesturalToStr(accidupperGes!));
    }
    if (hasAccidlowerGes) {
      element.attribute(
          'accidlower.ges', accidentalGesturalToStr(accidlowerGes!));
    }
  }

  /// Copies the `AttOrnamentAccidGes` members from [other].
  void copyAttOrnamentAccidGes(covariant AttOrnamentAccidGes other) {
    accidupperGes = other.accidupperGes;
    accidlowerGes = other.accidlowerGes;
  }
}

/// MEI attribute class for `att.PitchGes` (mirrors `vrv::AttPitchGes`).
mixin AttPitchGes {
  /// `oct.ges` — data_OCTAVE.
  int? octGes;
  bool get hasOctGes => octGes != null;

  /// `pname.ges` — data_PITCHNAME.
  Pitchname? pnameGes;
  bool get hasPnameGes => pnameGes != null;

  /// `pnum` — int.
  int? pnum;
  bool get hasPnum => pnum != null;

  /// Mirrors `AttPitchGes::ReadPitchGes`.
  bool readPitchGes(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final octGesRaw = element.get('oct.ges');
    if (octGesRaw != null) {
      octGes = strToInt(octGesRaw);
      if (removeAttr) element.remove('oct.ges');
      hasAttribute = true;
    }
    final pnameGesRaw = element.get('pname.ges');
    if (pnameGesRaw != null) {
      pnameGes = strToPitchname(pnameGesRaw);
      if (removeAttr) element.remove('pname.ges');
      hasAttribute = true;
    }
    final pnumRaw = element.get('pnum');
    if (pnumRaw != null) {
      pnum = strToInt(pnumRaw);
      if (removeAttr) element.remove('pnum');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPitchGes::WritePitchGes`.
  void writePitchGes(XmlBuilder element) {
    if (hasOctGes) {
      element.attribute('oct.ges', octaveToStr(octGes!));
    }
    if (hasPnameGes) {
      element.attribute('pname.ges', pitchnameToStr(pnameGes!));
    }
    if (hasPnum) {
      element.attribute('pnum', intToStr(pnum!));
    }
  }

  /// Copies the `AttPitchGes` members from [other].
  void copyAttPitchGes(covariant AttPitchGes other) {
    octGes = other.octGes;
    pnameGes = other.pnameGes;
    pnum = other.pnum;
  }
}

/// MEI attribute class for `att.SoundLocation` (mirrors `vrv::AttSoundLocation`).
mixin AttSoundLocation {
  /// `azimuth` — data_DEGREES.
  double? azimuth;
  bool get hasAzimuth => azimuth != null;

  /// `elevation` — data_DEGREES.
  double? elevation;
  bool get hasElevation => elevation != null;

  /// Mirrors `AttSoundLocation::ReadSoundLocation`.
  bool readSoundLocation(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final azimuthRaw = element.get('azimuth');
    if (azimuthRaw != null) {
      azimuth = strToDbl(azimuthRaw);
      if (removeAttr) element.remove('azimuth');
      hasAttribute = true;
    }
    final elevationRaw = element.get('elevation');
    if (elevationRaw != null) {
      elevation = strToDbl(elevationRaw);
      if (removeAttr) element.remove('elevation');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSoundLocation::WriteSoundLocation`.
  void writeSoundLocation(XmlBuilder element) {
    if (hasAzimuth) {
      element.attribute('azimuth', degreesToStr(azimuth!));
    }
    if (hasElevation) {
      element.attribute('elevation', degreesToStr(elevation!));
    }
  }

  /// Copies the `AttSoundLocation` members from [other].
  void copyAttSoundLocation(covariant AttSoundLocation other) {
    azimuth = other.azimuth;
    elevation = other.elevation;
  }
}

/// MEI attribute class for `att.TimestampGes` (mirrors `vrv::AttTimestampGes`).
mixin AttTimestampGes {
  /// `tstamp.ges` — double.
  double? tstampGes;
  bool get hasTstampGes => tstampGes != null;

  /// `tstamp.real` — std::string.
  String? tstampReal;
  bool get hasTstampReal => tstampReal != null;

  /// Mirrors `AttTimestampGes::ReadTimestampGes`.
  bool readTimestampGes(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tstampGesRaw = element.get('tstamp.ges');
    if (tstampGesRaw != null) {
      tstampGes = strToDbl(tstampGesRaw);
      if (removeAttr) element.remove('tstamp.ges');
      hasAttribute = true;
    }
    final tstampRealRaw = element.get('tstamp.real');
    if (tstampRealRaw != null) {
      tstampReal = identityStr(tstampRealRaw);
      if (removeAttr) element.remove('tstamp.real');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTimestampGes::WriteTimestampGes`.
  void writeTimestampGes(XmlBuilder element) {
    if (hasTstampGes) {
      element.attribute('tstamp.ges', dblToStr(tstampGes!));
    }
    if (hasTstampReal) {
      element.attribute('tstamp.real', identityStr(tstampReal!));
    }
  }

  /// Copies the `AttTimestampGes` members from [other].
  void copyAttTimestampGes(covariant AttTimestampGes other) {
    tstampGes = other.tstampGes;
    tstampReal = other.tstampReal;
  }
}

/// MEI attribute class for `att.Timestamp2Ges` (mirrors `vrv::AttTimestamp2Ges`).
mixin AttTimestamp2Ges {
  /// `tstamp2.ges` — data_MEASUREBEAT.
  MeasureBeat? tstamp2Ges;
  bool get hasTstamp2Ges => tstamp2Ges != null;

  /// `tstamp2.real` — std::string.
  String? tstamp2Real;
  bool get hasTstamp2Real => tstamp2Real != null;

  /// Mirrors `AttTimestamp2Ges::ReadTimestamp2Ges`.
  bool readTimestamp2Ges(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final tstamp2GesRaw = element.get('tstamp2.ges');
    if (tstamp2GesRaw != null) {
      tstamp2Ges = strToMeasurebeat(tstamp2GesRaw);
      if (removeAttr) element.remove('tstamp2.ges');
      hasAttribute = true;
    }
    final tstamp2RealRaw = element.get('tstamp2.real');
    if (tstamp2RealRaw != null) {
      tstamp2Real = identityStr(tstamp2RealRaw);
      if (removeAttr) element.remove('tstamp2.real');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTimestamp2Ges::WriteTimestamp2Ges`.
  void writeTimestamp2Ges(XmlBuilder element) {
    if (hasTstamp2Ges) {
      element.attribute('tstamp2.ges', measurebeatToStr(tstamp2Ges!));
    }
    if (hasTstamp2Real) {
      element.attribute('tstamp2.real', identityStr(tstamp2Real!));
    }
  }

  /// Copies the `AttTimestamp2Ges` members from [other].
  void copyAttTimestamp2Ges(covariant AttTimestamp2Ges other) {
    tstamp2Ges = other.tstamp2Ges;
    tstamp2Real = other.tstamp2Real;
  }
}
