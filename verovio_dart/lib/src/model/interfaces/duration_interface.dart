/// Port of `durationinterface.h/cpp` — interface for elements with duration,
/// such as notes and rests.
library;

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_cmn.dart';
import 'package:verovio_dart/src/model/atts/atts_gestural.dart';
import 'package:verovio_dart/src/model/atts/atts_mensural.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/atts/mei_values.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';

/// Lightweight view of the current mensur values needed by the mensural
/// duration calculations. The full `Mensur` element class implements this.
///
/// The getters are nullable: an unset attribute behaves like the C++
/// `NONE` enumerator value (0) in the arithmetic below.
abstract class MensurValues {
  Modusmaior? get modusmaior;
  Modusminor? get modusminor;
  Tempus? get tempus;
  Prolatio? get prolatio;
}

/// Mirrors `vrv::DurationInterface`.
///
/// Apply together with [AttAugmentDots], [AttBeamSecondary],
/// [AttDurationGes], [AttDurationLog], [AttDurationQuality],
/// [AttDurationRatio], [AttFermataPresent] and [AttStaffIdent].
mixin DurationInterface
    on
        AttAugmentDots,
        AttBeamSecondary,
        AttDurationGes,
        AttDurationLog,
        AttDurationQuality,
        AttDurationRatio,
        AttFermataPresent,
        AttStaffIdent
    implements Interface {
  /// The score-time onset of the note in the measure (from the start of the
  /// measure in quarter notes).
  Fraction scoreTimeOnset = Fraction(0);

  /// The score-time off-time of the printed note in the measure. If the note
  /// starts a tied group, the tied group ends at this value plus
  /// [scoreTimeTiedDuration]. For secondary notes of a tied group this is
  /// the printed end and [scoreTimeTiedDuration] is -1 (not exported to MIDI).
  Fraction scoreTimeOffset = Fraction(0);

  /// Time in milliseconds since the start of the containing measure.
  double realTimeOnsetMilliseconds = 0;

  /// Real time to the end of the printed note.
  double realTimeOffsetMilliseconds = 0;

  /// If first in a tied group: the score-time duration of all following tied
  /// notes; if secondary: -1.
  Fraction scoreTimeTiedDuration = Fraction(0);

  /// The default duration: extracted from scoreDef/staffDef and used when no
  /// duration attribute is given.
  MeiDuration durDefault = MeiDuration.none;

  @override
  InterfaceId get interfaceId => InterfaceId.duration;

  @override
  void reset() {
    dots = null;
    breaksec = null;
    durGes = null;
    dotsGes = null;
    durMetrical = null;
    durPpq = null;
    durReal = null;
    dur = null;
    durQuality = null;
    this.num = null;
    numbase = null;
    fermata = null;
    staff = null;

    durDefault = MeiDuration.none;

    scoreTimeOnset = Fraction(0);
    scoreTimeOffset = Fraction(0);
    realTimeOnsetMilliseconds = 0;
    realTimeOffsetMilliseconds = 0;
    scoreTimeTiedDuration = Fraction(0);
  }

  void setDurDefault(MeiDuration dur) => durDefault = dur;

  /// Copies the interface state (atts + MIDI timing) from [other].
  void copyDurationFrom(covariant DurationInterface other) {
    dots = other.dots;
    breaksec = other.breaksec;
    durGes = other.durGes;
    dotsGes = other.dotsGes;
    durMetrical = other.durMetrical;
    durPpq = other.durPpq;
    durReal = other.durReal;
    dur = other.dur;
    durQuality = other.durQuality;
    this.num = other.num;
    numbase = other.numbase;
    fermata = other.fermata;
    staff = other.staff == null ? null : [...other.staff!];
    durDefault = other.durDefault;

    scoreTimeOnset = other.scoreTimeOnset;
    scoreTimeOffset = other.scoreTimeOffset;
    realTimeOnsetMilliseconds = other.realTimeOnsetMilliseconds;
    realTimeOffsetMilliseconds = other.realTimeOffsetMilliseconds;
    scoreTimeTiedDuration = other.scoreTimeTiedDuration;
  }

  /// Returns the duration (in Fraction) for the element. Returns 1/1 for
  /// grace notes handling done elsewhere; here [num]/[numBase] are the
  /// current mensural scaling factors (mirrors
  /// `GetInterfaceAlignmentDuration`).
  Fraction getInterfaceAlignmentDuration(int num, int numBase) {
    MeiDuration noteDur = (durGes != null && durGes != MeiDuration.none)
        ? getActualDurGes()
        : getActualDur();
    if (noteDur == MeiDuration.none) noteDur = MeiDuration.dur4;

    int n = num;
    int nb = numBase;
    if (hasNum) n *= this.num!;
    if (hasNumbase) nb *= numbase!;

    Fraction duration = Fraction.fromDuration(noteDur);
    duration = duration * Fraction(nb) / Fraction(n);

    final int? noteDots = (hasDotsGes) ? dotsGes : dots;
    if (noteDots != null) {
      final Fraction reduction =
          Fraction(duration.numerator, duration.denominator * pow2(noteDots));
      duration = duration * Fraction(2) - reduction;
    }
    return duration;
  }

  /// Returns the duration (in Fraction) for mensural notation with the given
  /// level of equivalence (brevis, semibrevis or minima).
  Fraction getInterfaceAlignmentMensuralDuration(int num, int numBase,
      MensurValues? currentMensur, MeiDuration equivalence) {
    MeiDuration noteDur = (durGes != null && durGes != MeiDuration.none)
        ? getActualDurGes()
        : getActualDur();
    if (noteDur == MeiDuration.none) noteDur = MeiDuration.dur4;

    if (currentMensur == null) {
      logWarning('No current mensur for calculating duration');
      return Fraction(1);
    }

    int n = num;
    int nb = numBase;
    // perfecta in imperfect mensuration
    if (hasNum || hasNumbase) {
      if (this.num != null) n *= this.num!;
      if (numbase != null) nb *= numbase!;
    } else if (durQuality == DurqualityMensural.perfecta) {
      if ((dur == MeiDuration.longa &&
              currentMensur.modusminor == Modusminor.n2) ||
          (dur == MeiDuration.brevis && currentMensur.tempus == Tempus.n2) ||
          (dur == MeiDuration.semibrevis &&
              currentMensur.prolatio == Prolatio.n2) ||
          dur == MeiDuration.minima ||
          dur == MeiDuration.semiminima ||
          dur == MeiDuration.fusa ||
          dur == MeiDuration.semifusa) {
        n *= 2;
        nb *= 3;
      }
    }
    // imperfecta in perfect mensuration
    else if (durQuality == DurqualityMensural.imperfecta) {
      if ((dur == MeiDuration.longa &&
              currentMensur.modusminor != Modusminor.n2) ||
          (dur == MeiDuration.brevis && currentMensur.tempus != Tempus.n2) ||
          (dur == MeiDuration.semibrevis &&
              currentMensur.prolatio != Prolatio.n2)) {
        n *= 3;
        nb *= 2;
      }
    }
    // altera, maior, or duplex
    else if (hasDurQuality &&
        (durQuality == DurqualityMensural.altera ||
            durQuality == DurqualityMensural.maior ||
            durQuality == DurqualityMensural.duplex)) {
      nb *= 2;
    }
    // Any other case follows the mensuration.

    Fraction duration;
    if (equivalence == MeiDuration.minima) {
      duration = durationWithMinimaEquivalence(currentMensur, noteDur);
    } else if (equivalence == MeiDuration.semibrevis) {
      duration = durationWithSemibrevisEquivalence(currentMensur, noteDur);
    } else {
      duration = durationWithBrevisEquivalence(currentMensur, noteDur);
    }
    return duration * Fraction(nb) / Fraction(n);
  }

  /// Return the duration for the brevis level of equivalence.
  Fraction durationWithBrevisEquivalence(
      MensurValues currentMensur, MeiDuration noteDur) {
    Fraction duration = Fraction.fromDuration(MeiDuration.breve);
    switch (noteDur.value) {
      case -1: // maxima
        duration = duration *
            Fraction(_abs(currentMensur.modusminor)) *
            Fraction(_abs(currentMensur.modusmaior));
        break;
      case 0: // long
        duration = duration * Fraction(_abs(currentMensur.modusminor));
        break;
      case 1: // breve
        break;
      case 2: // whole
        duration = duration / Fraction(_abs(currentMensur.tempus));
        break;
      default:
        final ratio = pow2(noteDur.value - MeiDuration.dur2.value);
        assert(ratio != 0);
        duration = duration /
            Fraction(_abs(currentMensur.tempus)) /
            Fraction(_abs(currentMensur.prolatio)) /
            Fraction(ratio);
        break;
    }
    return duration;
  }

  /// Return the duration for the semibrevis level of equivalence.
  Fraction durationWithSemibrevisEquivalence(
      MensurValues currentMensur, MeiDuration noteDur) {
    Fraction duration = Fraction.fromDuration(MeiDuration.dur1);
    switch (noteDur.value) {
      case -1: // maxima (falls through in C++)
        duration = duration * Fraction(_abs(currentMensur.modusmaior));
        continue fallthroughLong;
      fallthroughLong:
      case 0: // long (falls through)
        duration = duration * Fraction(_abs(currentMensur.modusminor));
        continue fallthroughBreve;
      fallthroughBreve:
      case 1: // breve (falls through)
        duration = duration * Fraction(_abs(currentMensur.tempus));
        break;
      case 2: // whole
        break;
      default:
        final ratio = pow2(noteDur.value - MeiDuration.dur2.value);
        assert(ratio != 0);
        duration =
            duration / Fraction(_abs(currentMensur.prolatio)) / Fraction(ratio);
        break;
    }
    return duration;
  }

  /// Return the duration for the minima level of equivalence.
  Fraction durationWithMinimaEquivalence(
      MensurValues currentMensur, MeiDuration noteDur) {
    Fraction duration = Fraction.fromDuration(MeiDuration.dur2);
    switch (noteDur.value) {
      case -1: // maxima (falls through in C++)
        duration = duration * Fraction(_abs(currentMensur.modusmaior));
        continue fallthroughLong;
      fallthroughLong:
      case 0: // long (falls through)
        duration = duration * Fraction(_abs(currentMensur.modusminor));
        continue fallthroughBreve;
      fallthroughBreve:
      case 1: // breve (falls through)
        duration = duration * Fraction(_abs(currentMensur.tempus));
        continue fallthroughWhole;
      fallthroughWhole:
      case 2: // whole
        duration = duration * Fraction(_abs(currentMensur.prolatio));
        break;
      default:
        final ratio = pow2(noteDur.value - MeiDuration.dur2.value);
        assert(ratio != 0);
        duration = duration / Fraction(ratio);
        break;
    }
    return duration;
  }

  /// Return the actual (gestural) duration of the note, for both CMN and
  /// mensural durations (mirrors `GetActualDur`).
  MeiDuration getActualDur() =>
      calcActualDur(hasDur && dur != null ? dur! : durDefault);

  MeiDuration getActualDurGes() =>
      calcActualDur(hasDurGes && durGes != null ? durGes! : MeiDuration.none);

  /// Translate mensural values to their CMN counterparts.
  MeiDuration calcActualDur(MeiDuration dur) {
    // No mapping needed for values below, including maxima and none.
    if (dur.value < MeiDuration.longa.value) return dur;
    switch (dur) {
      case MeiDuration.longa:
        return MeiDuration.long;
      case MeiDuration.brevis:
        return MeiDuration.breve;
      case MeiDuration.semibrevis:
        return MeiDuration.dur1;
      case MeiDuration.minima:
        return MeiDuration.dur2;
      case MeiDuration.semiminima:
        return MeiDuration.dur4;
      case MeiDuration.fusa:
        return MeiDuration.dur8;
      case MeiDuration.semifusa:
        return MeiDuration.dur16;
      default:
        return MeiDuration.none;
    }
  }

  /// Return true if the value is a mensural (longa, brevis, etc.).
  bool get isMensuralDur {
    // maxima (-1) is a mensural only value.
    if (dur == MeiDuration.maxima) return true;
    return (dur?.value ?? -2) >= MeiDuration.longa.value;
  }

  /// MIDI timing information.
  void setScoreTimeOnset(Fraction scoreTime) => scoreTimeOnset = scoreTime;
  void setRealTimeOnsetSeconds(double timeInSeconds) =>
      realTimeOnsetMilliseconds = timeInSeconds * 1000.0;
  void setScoreTimeOffset(Fraction scoreTime) => scoreTimeOffset = scoreTime;
  void setRealTimeOffsetSeconds(double timeInSeconds) =>
      realTimeOffsetMilliseconds = timeInSeconds * 1000.0;
  void setScoreTimeTiedDuration(Fraction scoreTime) =>
      scoreTimeTiedDuration = scoreTime;

  double getRealTimeOnsetMilliseconds() => realTimeOnsetMilliseconds;
  double getRealTimeOffsetMilliseconds() => realTimeOffsetMilliseconds;

  Fraction getScoreTimeDuration() => scoreTimeOffset - scoreTimeOnset;
}

/// Mirrors `abs(currentMensur->GetModusminor())` etc. from the C++: an unset
/// mensuration value is `*_NONE = -3`, whose absolute value is 3.
int _abs(dynamic enumValue) => enumValue == null
    ? 3
    : enumValue is MeiDuration
        ? enumValue.value.abs()
        : (enumValue.value as int).abs();

int pow2(int exp) => exp <= 0 ? 1 : 1 << exp;
