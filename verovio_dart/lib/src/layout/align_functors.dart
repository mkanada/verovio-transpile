/// Port of the functors that fill / read the aligners when traversing a
/// loaded document:
///
/// - [InitOnsetOffsetFunctor] and [InitMaxMeasureDurationFunctor] mirror
///   midifunctor.h/cpp (used by `Doc::CalculateTimemap` right after the
///   horizontal layout has filled the measure aligners).
/// - [PrepareStaffCurrentTimeSpanningFunctor] mirrors preparedatafunctor.h/cpp.
/// - [tempoCalcTempo] mirrors `Tempo::CalcTempo`.
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration, meiUnset;
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart' show AttExtender;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Notationtype;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Layer, Measure, Note, Staff;
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Tempo;
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/interfaces/linking_interface.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show BeatRpt, Chord, MultiRest, Proport, Syl, TabGrp;
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show F;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef, StaffDef;

// ---------------------------------------------------------------------------
// Tempo::CalcTempo (mirrors tempo.cpp)
// ---------------------------------------------------------------------------

/// Calculate the tempo from the @mm attributes (mirrors `Tempo::CalcTempo`).
double tempoCalcTempo({required double mm, MeiDuration? mmUnit, int? mmDots}) {
  double tempo = midiTempo.toDouble();

  double unit = 4;
  if (mmUnit != null && mmUnit.value > MeiDuration.breve.value) {
    unit = _pow2Int(mmUnit.value - 2).toDouble();
  }
  if (mmDots != null) {
    double dotsUnit = 0.0;
    for (int d = 0; d < mmDots; d++) {
      dotsUnit += unit / 4.0 / _pow2Double(d);
    }
    unit -= dotsUnit;
  }
  if (unit > 0) tempo = mm * 4.0 / unit;

  return tempo;
}

int _pow2Int(int exp) => exp <= 0 ? 1 : 1 << exp;

double _pow2Double(int exp) {
  var result = 1.0;
  for (var i = 0; i < exp; i++) {
    result *= 2.0;
  }
  return result;
}

// ---------------------------------------------------------------------------
// InitOnsetOffsetFunctor
// ---------------------------------------------------------------------------

/// This class prepares Note onsets (mirrors `vrv::InitOnsetOffsetFunctor`).
class InitOnsetOffsetFunctor extends DocFunctor {
  InitOnsetOffsetFunctor(super.doc) {
    meterParams.equivalence = doc.getOptions().durationEquivalence.value;
  }

  /// The current score time in the measure (incremented by each element)
  /// (mirrors `m_currentScoreTime`).
  Fraction currentScoreTime = Fraction(0);

  /// The current real time in seconds in the measure (mirrors
  /// `m_currentRealTimeSeconds`).
  double currentRealTimeSeconds = 0.0;

  /// The current time alignment parameters (mirrors `m_meterParams`).
  final AlignMeterParams meterParams = AlignMeterParams();

  /// The current notation type (mirrors `m_notationType`).
  Notationtype notationType = Notationtype.cmn;

  /// The current tempo (mirrors `m_currentTempo`).
  double currentTempo = midiTempo.toDouble();

  @override
  FunctorCode visitChordEnd(Chord chord) {
    final LayerElement element = _thisOrSameasLink(chord);

    final incrementScoreTime =
        element.getAlignmentDuration(meterParams, true, notationType) *
            Fraction(scoreTimeUnit);
    final realTimeIncrementSeconds =
        incrementScoreTime.toDouble() * 60.0 / currentTempo;

    currentScoreTime = currentScoreTime + incrementScoreTime;
    currentRealTimeSeconds += realTimeIncrementSeconds;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTabGrpEnd(TabGrp tabGrp) {
    final LayerElement element = _thisOrSameasLink(tabGrp);

    final incrementScoreTime =
        element.getAlignmentDuration(meterParams, true, notationType) *
            Fraction(scoreTimeUnit);
    final realTimeIncrementSeconds =
        incrementScoreTime.toDouble() * 60.0 / currentTempo;

    currentScoreTime = currentScoreTime + incrementScoreTime;
    currentRealTimeSeconds += realTimeIncrementSeconds;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayer(Layer layer) {
    currentScoreTime = Fraction(0);
    currentRealTimeSeconds = 0.0;

    // Mirrors Layer::GetCurrentMensur etc.: resolve through the drawing
    // staffDef of the parent staff (null until the scoreDef phase ran; in
    // that case the default parameters are used).
    final staff = layer.getFirstAncestor(ClassId.staff) as Staff?;
    final staffDef = staff?.drawingStaffDef as StaffDef?;
    if (staffDef != null) {
      meterParams.mensur = staffDef.getCurrentMensur();
      meterParams.meterSig = staffDef.getCurrentMeterSig();
      meterParams.proport = staffDef.getCurrentProport();
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    final LayerElement element = _thisOrSameasLink(layerElement);

    Fraction incrementScoreTime;

    if (element.isAny({ClassId.rest, ClassId.space})) {
      final durationInterface = element as DurationInterface;
      incrementScoreTime =
          element.getAlignmentDuration(meterParams, true, notationType) *
              Fraction(scoreTimeUnit);
      // For rests to be possibly added to the timemap
      if (element.classId == ClassId.rest) {
        final realTimeIncrementSeconds =
            incrementScoreTime.toDouble() * 60.0 / currentTempo;
        durationInterface.setScoreTimeOnset(currentScoreTime);
        durationInterface.setRealTimeOnsetSeconds(currentRealTimeSeconds);
        durationInterface
            .setScoreTimeOffset(currentScoreTime + incrementScoreTime);
        durationInterface.setRealTimeOffsetSeconds(
            currentRealTimeSeconds + realTimeIncrementSeconds);
      }
      currentScoreTime = currentScoreTime + incrementScoreTime;
      currentRealTimeSeconds +=
          incrementScoreTime.toDouble() * 60.0 / currentTempo;
    } else if (element.classId == ClassId.note) {
      final note = element as Note;
      final noteTiming = element as DurationInterface;

      if (note.isGraceNote()) {
        // Just store the current onset - only used for grace notes at the end
        // of the layer
        noteTiming.setScoreTimeOnset(currentScoreTime);
        noteTiming.setRealTimeOnsetSeconds(currentRealTimeSeconds);
        return FunctorCode.continue_;
      }

      final chord = note.isChordTone();
      final tabGrp = note.getFirstAncestor(ClassId.tabGrp);

      // If the note has a @dur or a @dur.ges, take it into account. This
      // means that overwriting only @dots or @dots.ges will not be taken into
      // account.
      final bool hasOwnDur = note.hasDur || note.hasDurGes;
      if (chord != null && !hasOwnDur) {
        incrementScoreTime = (chord as LayerElement)
                .getAlignmentDuration(meterParams, true, notationType) *
            Fraction(scoreTimeUnit);
      } else if (tabGrp != null && !hasOwnDur) {
        incrementScoreTime = (tabGrp as LayerElement)
                .getAlignmentDuration(meterParams, true, notationType) *
            Fraction(scoreTimeUnit);
      } else {
        incrementScoreTime =
            element.getAlignmentDuration(meterParams, true, notationType) *
                Fraction(scoreTimeUnit);
      }
      final realTimeIncrementSeconds =
          incrementScoreTime.toDouble() * 60.0 / currentTempo;

      // When we have a @sameas, do store the onset / offset values of the
      // pointed note in the pointing note
      final bool isSameasTarget = !identical(layerElement, element);
      if (!isSameasTarget || layerElement is Note) {
        final storeNote =
            isSameasTarget ? layerElement as DurationInterface : noteTiming;
        storeNote.setScoreTimeOnset(currentScoreTime);
        storeNote.setRealTimeOnsetSeconds(currentRealTimeSeconds);
        storeNote.setScoreTimeOffset(currentScoreTime + incrementScoreTime);
        storeNote.setRealTimeOffsetSeconds(
            currentRealTimeSeconds + realTimeIncrementSeconds);
      }

      // increase the currentTime accordingly, but only if not in a chord or
      // tabGrp
      if (chord == null && !_isTabGrpNote(element)) {
        currentScoreTime = currentScoreTime + incrementScoreTime;
        currentRealTimeSeconds += realTimeIncrementSeconds;
      }
    } else if (element.classId == ClassId.beatRpt) {
      final rpt = element as BeatRpt;

      incrementScoreTime =
          element.getAlignmentDuration(meterParams, true, notationType) *
              Fraction(scoreTimeUnit);
      rpt.setScoreTimeOnset(currentScoreTime);
      currentScoreTime = currentScoreTime + incrementScoreTime;
      currentRealTimeSeconds +=
          incrementScoreTime.toDouble() * 60.0 / currentTempo;
    } else if (element.isAny({
          ClassId.beam,
          ClassId.ligature,
          ClassId.fTrem,
          ClassId.tuplet,
        }) &&
        _hasSameasLink(layerElement)) {
      incrementScoreTime = layerElement.getSameAsContentAlignmentDuration(
              meterParams, true, notationType) *
          Fraction(scoreTimeUnit);
      currentScoreTime = currentScoreTime + incrementScoreTime;
      currentRealTimeSeconds +=
          incrementScoreTime.toDouble() * 60.0 / currentTempo;
    } else if (element.classId == ClassId.mensur) {
      meterParams.mensur = element;
    } else if (element.classId == ClassId.meterSig) {
      meterParams.meterSig = element;
    } else if (element.classId == ClassId.proport) {
      if (layerElement.type == 'cmme_tempo_change') return FunctorCode.siblings;
      // replace the current proport
      final Proport? previous = meterParams.proport as Proport?;
      meterParams.proport = element as Proport;
      if (previous != null) {
        (meterParams.proport as Proport).cumulate(previous);
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    currentTempo = measure.getCurrentTempo();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    final drawingStaffDef = staff.drawingStaffDef as StaffDef?;

    // Deviation: the C++ asserts the drawing staffDef; before the scoreDef
    // preparation runs it is not set yet, so fall back to CMN.
    if (drawingStaffDef == null) {
      logDebug('InitOnsetOffsetFunctor: no drawing staffDef on staff '
          '${staff.id}, using CMN notation type');
      notationType = Notationtype.cmn;
      return FunctorCode.continue_;
    }

    notationType = drawingStaffDef.hasNotationtype
        ? (drawingStaffDef.notationtype ?? Notationtype.cmn)
        : Notationtype.cmn;

    return FunctorCode.continue_;
  }

  /// Mirrors `LayerElement::ThisOrSameasLink`.
  LayerElement _thisOrSameasLink(Object object) {
    final LinkingInterface? linking =
        object is LinkingInterface ? object as LinkingInterface : null;
    if (linking != null && linking.hasSameasLink) {
      return linking.sameasLink as LayerElement;
    }
    return object as LayerElement;
  }

  /// Return true when the element has a @sameas link.
  bool _hasSameasLink(Object object) {
    final LinkingInterface? linking =
        object is LinkingInterface ? object as LinkingInterface : null;
    return linking?.hasSameasLink ?? false;
  }

  /// Mirrors `Note::IsTabGrpNote`: notes are tabGrp notes when within a
  /// TabGrp.
  ///
  /// Deviation: chord tones are handled by [Note.isChordTone]; here we only
  /// check the tabGrp ancestor like the C++ does for the time increment.
  bool _isTabGrpNote(LayerElement element) =>
      element.getFirstAncestor(ClassId.tabGrp) != null;
}

// ---------------------------------------------------------------------------
// InitMaxMeasureDurationFunctor
// ---------------------------------------------------------------------------

/// This class calculates the maximum duration of each measure (mirrors
/// `vrv::InitMaxMeasureDurationFunctor`).
class InitMaxMeasureDurationFunctor extends Functor {
  /// The current score time (mirrors `m_currentScoreTime`).
  Fraction currentScoreTime = Fraction(0);

  /// The current time in seconds (mirrors `m_currentRealTimeSeconds`).
  double currentRealTimeSeconds = 0.0;

  /// The current tempo (mirrors `m_currentTempo`).
  double currentTempo = midiTempo.toDouble();

  /// The tempo adjustment (mirrors `m_tempoAdjustment`).
  double tempoAdjustment = 1.0;

  /// The factor for multibar rests (mirrors `m_multiRestFactor`).
  int multiRestFactor = 1;

  /// Returns the current tempo with adjustment (mirrors `GetAdjustedTempo`).
  double getAdjustedTempo() => currentTempo * tempoAdjustment;

  /// Set the tempo (mirrors `SetCurrentTempo`).
  void setCurrentTempo(double tempo) => currentTempo = tempo;

  /// Set the tempo adjustment (mirrors `SetTempoAdjustment`).
  void setTempoAdjustment(double adjustment) => tempoAdjustment = adjustment;

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.classId == ClassId.multiRest) {
      multiRestFactor = (layerElement as MultiRest).num ?? 2;
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    measure.clearScoreTimeOnset();
    measure.addScoreTimeOnset(currentScoreTime);

    measure.clearRealTimeOnsetMilliseconds();
    measure.addRealTimeOnsetMilliseconds(currentRealTimeSeconds * 1000.0);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    final tempo = getAdjustedTempo();
    measure.setCurrentTempo(tempo);

    final scoreTimeIncrement =
        (measure.measureAligner.getRightAlignment()?.getTime() ?? Fraction(0)) *
            Fraction(multiRestFactor) *
            Fraction(scoreTimeUnit);
    currentScoreTime = currentScoreTime + scoreTimeIncrement;
    currentRealTimeSeconds += scoreTimeIncrement.toDouble() * 60.0 / tempo;

    measure.clearScoreTimeOffset();
    measure.addScoreTimeOffset(currentScoreTime);

    measure.clearRealTimeOffsetMilliseconds();
    measure.addRealTimeOffsetMilliseconds(currentRealTimeSeconds * 1000.0);

    multiRestFactor = 1;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    if (scoreDef.hasMidiBpm) {
      currentTempo = scoreDef.midiBpm!;
    } else if (scoreDef.hasMm) {
      currentTempo = tempoCalcTempo(
        mm: scoreDef.mm!,
        mmUnit: scoreDef.mmUnit,
        mmDots: scoreDef.mmDots,
      );
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTempo(Tempo tempo) {
    if (tempo.hasMidiBpm) {
      currentTempo = tempo.midiBpm!;
    } else if (tempo.hasMm) {
      currentTempo = tempoCalcTempo(
        mm: tempo.mm!,
        mmUnit: tempo.mmUnit,
        mmDots: tempo.mmDots,
      );
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// PrepareStaffCurrentTimeSpanningFunctor
// ---------------------------------------------------------------------------

/// This class goes through all the TimeSpanningInterface elements and sets
/// them for each staff that is covered.
///
/// At the end, it removes the TimeSpanningInterface element from the list
/// when the last measure is reached (mirrors
/// `vrv::PrepareStaffCurrentTimeSpanningFunctor`).
class PrepareStaffCurrentTimeSpanningFunctor extends Functor {
  /// The currently running TimeSpanningInterface elements (mirrors
  /// `m_timeSpanningElements`).
  final List<Object> timeSpanningElements = [];

  /// Getter for the interface list (mirrors `GetTimeSpanningElements`).
  List<Object> getTimeSpanningElements() => timeSpanningElements;

  /// Mirrors `InsertTimeSpanningElement`.
  void insertTimeSpanningElement(Object element) {
    timeSpanningElements.add(element);
  }

  @override
  FunctorCode visitF(F f) {
    // Pass it to the pseudo functor of the interface.
    final interface = f as TimeSpanningInterface;
    _interfacePrepareStaffCurrentTimeSpanning(interface, f);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitFloatingObject(FloatingObject floatingObject) {
    // Pass it to the pseudo functor of the interface.
    if (floatingObject.hasInterface(InterfaceId.timeSpanning)) {
      final interface = floatingObject as TimeSpanningInterface;
      _interfacePrepareStaffCurrentTimeSpanning(interface, floatingObject);
    }
    if (floatingObject.hasInterface(InterfaceId.linking)) {
      _interfacePrepareLinkingStaffCurrentTimeSpanning(
          floatingObject as LinkingInterface, floatingObject);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    for (int i = timeSpanningElements.length - 1; i >= 0; --i) {
      final Object element = timeSpanningElements[i];
      Object? endParent;
      if (element.hasInterface(InterfaceId.timeSpanning)) {
        final interface = element as TimeSpanningInterface;
        if (interface.end != null) {
          endParent = interface.end!.getFirstAncestor(ClassId.measure);
        }
      }
      if (endParent == null && element.hasInterface(InterfaceId.linking)) {
        final interface = element as LinkingInterface;
        if (interface.nextLink != null) {
          // We should have one because we allow only control events (dir and
          // dynam) to be linked as target
          final nextInterface = interface.nextLink as TimePointInterface;
          if (nextInterface.start != null) {
            endParent = nextInterface.start!.getFirstAncestor(ClassId.measure);
          }
        }
      }
      if (endParent == null) {
        // ignore: avoid_print
        print('DBG nullEndParent elem=${element.className} id=${element.id}');
      }
      if (identical(endParent, measure)) {
        timeSpanningElements.removeAt(i);
      }
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    for (final Object element in List<Object>.of(timeSpanningElements)) {
      final interface = element as TimeSpanningInterface;
      final currentMeasure = staff.getFirstAncestor(ClassId.measure);
      assert(currentMeasure != null);
      // Special case for harm/fb/f where we are likely not to have a @staff
      // on /f. Use the parent harm to get the staff (necessary when calling
      // IsOnStaff with timestamps). (C++ `Is(FIGURE)` — FIGURE ↔ Dart
      // ClassId.f)
      var effectiveInterface = interface;
      if (element.classId == ClassId.f && !interface.hasStaff) {
        final harm = element.getFirstAncestor(ClassId.harm);
        if (harm != null) {
          effectiveInterface = harm as TimeSpanningInterface;
        }
      }
      // We need to make sure we are in the next measure (and not just a staff
      // below because of some cross staff notation)
      if (!identical(effectiveInterface.getStartMeasure(), currentMeasure) &&
          effectiveInterface.isOnStaff(staff.n ?? meiUnset)) {
        staff.timeSpanningElements.add(element);
      }
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSyl(Syl syl) {
    // Pass it to the pseudo functor of the interface.
    final interface = syl as TimeSpanningInterface;
    _interfacePrepareStaffCurrentTimeSpanning(interface, syl);
    return FunctorCode.continue_;
  }

  /// Mirrors
  /// `TimeSpanningInterface::InterfacePrepareStaffCurrentTimeSpanning`.
  void _interfacePrepareStaffCurrentTimeSpanning(
      TimeSpanningInterface interface, Object object) {
    if (interface.isSpanningMeasures()) {
      insertTimeSpanningElement(object);
    }
  }

  /// Mirrors
  /// `LinkingInterface::InterfacePrepareStaffCurrentTimeSpanning`.
  void _interfacePrepareLinkingStaffCurrentTimeSpanning(
      LinkingInterface interface, Object object) {
    // Only dir and dynam can be spanning with @next (extender)
    if (!object.isAny({ClassId.dir, ClassId.dynam})) return;

    // Only target control events are supported
    if (!interface.hasNextLink || !(interface.nextLink!.isControlElement)) {
      return;
    }

    // if @extender is available, the explicit "true" is required
    final AttExtender? extender =
        object is AttExtender ? object as AttExtender : null;
    if (extender != null && extender.extender != true) return;

    insertTimeSpanningElement(object);
  }
}
