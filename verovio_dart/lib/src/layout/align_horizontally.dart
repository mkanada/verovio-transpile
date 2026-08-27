/// Port of the horizontal alignment functors of `alignfunctor.h/cpp` and of
/// the horizontal part of `resetfunctor.cpp`:
///
/// - [ResetHorizontalAlignmentFunctor]: resets the x positions and alignment
///   pointers before a new layout pass (the C++ lives in resetfunctor.cpp).
/// - [AlignHorizontallyFunctor]: instantiates the Alignment of every
///   LayerElement and fills the measure aligners.
/// - [AlignMeasuresFunctor]: aligns the measures by adjusting their
///   m_drawingXRel position looking at the MeasureAligner.
///
/// Deviations from the C++:
/// - Ossia handling is not ported (`DrawOssiaStaffDef`, ossia alignments);
///   ossia support is deferred to a later phase.
/// - `StaffDef::AlternateCurrentMeterSig` (alternating meterSigGrp) is not
///   available in the drawing interface yet and is skipped.
/// - The beam / beamSpan segment resets are deferred with the beam segment
///   phase; tuplet bracket state resets arrive with the tuplet functors.
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration, meiUnset;
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show
        AlignMeterParams,
        Alignment,
        LayerElementAlignmentDuration,
        MeasureAligner;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Notationtype;
import 'package:verovio_dart/src/model/atts/atts_shared.dart'
    show AttVisibility;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/comparison.dart' show ClassIdsComparison;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show
        Accid,
        Chord,
        Custos,
        Dot,
        Dots,
        Ligature,
        MeterSigGrp,
        MRest,
        Proport,
        TabGrp,
        Tuplet,
        TupletBracket,
        TupletNum;
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Arpeg;
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show Div;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

// ---------------------------------------------------------------------------
// ResetHorizontalAlignmentFunctor (mirrors resetfunctor.cpp)
// ---------------------------------------------------------------------------

/// Reset the horizontal alignment: clears the drawing x positions and the
/// alignment pointers of all layer elements (mirrors
/// `vrv::ResetHorizontalAlignmentFunctor`).
class ResetHorizontalAlignmentFunctor extends Functor {
  @override
  FunctorCode visitAccid(Accid accid) {
    visitLayerElement(accid);
    _resetPositionInterface(accid);
    accid.setDrawingUnisonAccid(null);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitArpeg(Arpeg arpeg) {
    arpeg.drawingXRel = 0;
    return visitControlElement(arpeg);
  }

  @override
  FunctorCode visitCustos(Custos custos) {
    visitLayerElement(custos);
    _resetPositionInterface(custos);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitDiv(Div div) {
    visitTextLayoutElement(div);
    div.setDrawingXRel(0);
    div.setDrawingYRel(0);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitDot(Dot dot) {
    visitLayerElement(dot);
    _resetPositionInterface(dot);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitDots(Dots dots) {
    visitLayerElement(dots);
    dots.resetMapOfDotLocs();
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayer(Layer layer) {
    // The staffDef objects owned by the layer are aligned as part of the
    // layer content; reset them as well (mirrors VisitLayer).
    if (layer.staffDefClef != null) visitLayerElement(layer.staffDefClef!);
    if (layer.staffDefKeySig != null) visitLayerElement(layer.staffDefKeySig!);
    if (layer.staffDefMensur != null) visitLayerElement(layer.staffDefMensur!);
    if (layer.staffDefMeterSig != null) {
      visitLayerElement(layer.staffDefMeterSig!);
    }
    if (layer.staffDefMeterSigGrp != null) {
      layer.staffDefMeterSigGrp!.process(this);
    }
    if (layer.cautionStaffDefClef != null) {
      visitLayerElement(layer.cautionStaffDefClef!);
    }
    if (layer.cautionStaffDefKeySig != null) {
      visitLayerElement(layer.cautionStaffDefKeySig!);
    }
    if (layer.cautionStaffDefMensur != null) {
      visitLayerElement(layer.cautionStaffDefMensur!);
    }
    if (layer.cautionStaffDefMeterSig != null) {
      visitLayerElement(layer.cautionStaffDefMeterSig!);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    layerElement.setDrawingXRel(0);
    // Exception here: the drawingYRel position is already set for horizontal
    // alignment, so it is reset here and not by the vertical reset.
    layerElement.setDrawingYRel(0);

    layerElement.resetAlignment();
    layerElement.resetGraceAlignment();
    layerElement.setAlignmentLayerN(meiUnset);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    measure.setDrawingXRel(0);
    measure.measureAligner.getLeftAlignment()?.setXRel(0);
    measure.measureAligner.getRightAlignment()?.setXRel(0);

    measure.timestampAligner.process(this);

    measure.setHasAlignmentRefWithMultipleLayers(false);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMRest(MRest mRest) {
    visitLayerElement(mRest);
    _resetPositionInterface(mRest);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    visitLayerElement(note);
    _resetPositionInterface(note);

    note.drawingLoc = 0;
    note.flippedNotehead = false;
    // Re-mark the role as unused if we have a shared stem.
    if (note.hasStemSameasNote()) {
      note.stemSameasRole = StemSameasDrawingRole.unset;
    }

    return FunctorCode.continue_;
  }

  // TODO(phase-4/5): ossia alignments and beamSpan segments arrive with
  // their respective features.

  @override
  FunctorCode visitProport(Proport proport) {
    visitLayerElement(proport);
    proport.resetCumulate();
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitRest(Rest rest) {
    visitLayerElement(rest);
    _resetPositionInterface(rest);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    scoreDef.resetDrawingLabelsWidth();
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    system.setDrawingXRel(0);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTuplet(Tuplet tuplet) {
    visitLayerElement(tuplet);
    // TODO(phase-5): bracket / num aligned beam resets arrive with the
    // vertical layout phase.
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTupletBracket(TupletBracket tupletBracket) {
    visitLayerElement(tupletBracket);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTupletNum(TupletNum tupletNum) {
    visitLayerElement(tupletNum);
    return FunctorCode.continue_;
  }

  /// Mirrors `PositionInterface::InterfaceResetHorizontalAlignment`.
  void _resetPositionInterface(LayerElement element) {
    if (element.hasInterface(InterfaceId.position)) {
      final dynamic position = element;
      position.drawingLoc = 0;
    }
  }
}

// ---------------------------------------------------------------------------
// AlignHorizontallyFunctor
// ---------------------------------------------------------------------------

/// This class aligns horizontally the content of a page (mirrors
/// `vrv::AlignHorizontallyFunctor`).
///
/// For each LayerElement, instantiate its Alignment. It creates it if no
/// other note or event occurs at its position. At the end, for each Layer,
/// align the grace notes stacked in the GraceAligner.
class AlignHorizontallyFunctor extends DocFunctor {
  AlignHorizontallyFunctor(super.doc) {
    meterParams.equivalence = doc.getOptions().durationEquivalence.value;
  }

  /// The measureAligner (mirrors `m_measureAligner`).
  MeasureAligner? _measureAligner;

  /// The time (mirrors `m_time`).
  Fraction _time = Fraction(0);

  /// The current value of the cursor (`m_time`).
  ///
  /// Auxiliary read accessor of the port: the C++ instrumentation
  /// (`cpp_probe/patches/04-00.patch`) prints this exact member in
  /// `AlignHorizontallyFunctor::VisitLayerElement`, so the parity tests wrap
  /// the functor and snapshot it around each visit.
  Fraction get timeCursor => _time;

  /// The current meterSig, mensur and proport (mirrors `m_currentParams`).
  final AlignMeterParams meterParams = AlignMeterParams();

  /// The current notation type (mirrors `m_notationType`).
  Notationtype notationType = Notationtype.cmn;

  /// Indicates the state in processing the caution scoreDef (mirrors
  /// `m_scoreDefRole`).
  ElementScoreDefRole scoreDefRole = ElementScoreDefRole.none;

  /// Indicates if we are in the first measure (for the scoreDef role)
  /// (mirrors `m_isFirstMeasure`).
  bool isFirstMeasure = false;

  /// Indicates if we have multiple layer alignment references in the measure
  /// (mirrors `m_hasMultipleLayer`).
  bool hasMultipleLayer = false;

  /// Indicates if we are starting a new section with restart (mirrors
  /// `m_sectionRestart`).
  bool sectionRestart = false;

  @override
  FunctorCode visitLayer(Layer layer) {
    // Mirrors Layer::GetCurrentMensur etc.: resolve through the drawing
    // staffDef of the parent staff.
    final Staff? staff = layer.getFirstAncestor(ClassId.staff) as Staff?;
    final dynamic staffDef = staff?.drawingStaffDef;
    if (staffDef != null) {
      meterParams.mensur = staffDef.getCurrentMensur() as Object?;
      meterParams.meterSig = staffDef.getCurrentMeterSig() as Object?;
      meterParams.proport = staffDef.getCurrentProport() as Object?;
    }

    // We are starting a new layer, reset the time. We set it to -1.0 for the
    // scoreDef attributes since they have to be aligned before any timestamp
    // event (-1.0).
    _time = Fraction(-1);

    scoreDefRole = (isFirstMeasure || sectionRestart)
        ? ElementScoreDefRole.system
        : ElementScoreDefRole.intermediate;

    // Now we have to set it to 0.0 since we will start aligning musical
    // content (after having visited the staffDef objects below).
    _visitLayerStaffDefObjects(layer);

    scoreDefRole = ElementScoreDefRole.none;

    _time = Fraction(0);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerEnd(Layer layer) {
    scoreDefRole = ElementScoreDefRole.cautionary;
    _time = _measureAligner!.getMaxTime();

    if (layer.cautionStaffDefClef != null &&
        !_isInvisible(layer.cautionStaffDefClef)) {
      visitLayerElement(layer.cautionStaffDefClef!);
    }
    if (layer.cautionStaffDefKeySig != null &&
        !_isInvisible(layer.cautionStaffDefKeySig)) {
      visitLayerElement(layer.cautionStaffDefKeySig!);
    }
    if (layer.cautionStaffDefMensur != null) {
      visitLayerElement(layer.cautionStaffDefMensur!);
    }
    if (layer.cautionStaffDefMeterSig != null &&
        !_isInvisible(layer.cautionStaffDefMeterSig)) {
      visitLayerElement(layer.cautionStaffDefMeterSig!);
    }

    scoreDefRole = ElementScoreDefRole.none;

    final Staff? staff = layer.getFirstAncestor(ClassId.staff) as Staff?;
    assert(staff != null);
    final int graceAlignerId =
        doc.getOptions().graceRhythmAlign.value ? 0 : (staff!.n ?? 0);

    for (int i = 0; i < _measureAligner!.getAlignmentCount(); ++i) {
      final Alignment alignment = _measureAligner!.getChild(i) as Alignment;
      if (alignment.hasGraceAligner(graceAlignerId)) {
        alignment.getGraceAligner(graceAlignerId).alignStack();
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    assert(layerElement.getAlignment() == null);

    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    layerElement.setScoreDefRole(scoreDefRole);

    AlignmentType type = AlignmentType.default_;

    final Chord? chordParent =
        layerElement.getFirstAncestor(ClassId.chord) as Chord?;
    final Ligature? ligatureParent =
        layerElement.getFirstAncestor(ClassId.ligature) as Ligature?;
    final Note? noteParent =
        layerElement.getFirstAncestor(ClassId.note) as Note?;
    final Rest? restParent =
        layerElement.getFirstAncestor(ClassId.rest) as Rest?;
    final TabGrp? tabGrpParent =
        layerElement.getFirstAncestor(ClassId.tabGrp) as TabGrp?;
    final bool ligatureAsBracket = doc.getOptions().ligatureAsBracket.value;
    final bool neumeAsNote = doc.getOptions().neumeAsNote.value;

    if (chordParent != null) {
      layerElement.setAlignment(chordParent.getAlignment());
    } else if (noteParent != null) {
      layerElement.setAlignment(noteParent.getAlignment());
    } else if (restParent != null) {
      layerElement.setAlignment(restParent.getAlignment());
    } else if (tabGrpParent != null) {
      layerElement.setAlignment(tabGrpParent.getAlignment());
    } else if (layerElement.isAny({ClassId.dots, ClassId.flag, ClassId.stem})) {
      // This should never happen because dots / flags / stems always belong
      // to a note or chord. Unlike the C++ (assert), keep processing and let
      // the element fall back to its own alignment below.
      logDebug('AlignHorizontallyFunctor: element part '
          '${layerElement.className} without an aligned parent');
    } else if (ligatureParent != null &&
        layerElement.classId == ClassId.note &&
        !ligatureAsBracket) {
      // Ligature notes are all aligned with the first note.
      final Note note = layerElement as Note;
      // Deviation: ObjectListInterface.getList includes the holder itself in
      // this port; look for the first direct note child instead of
      // GetListFront.
      final List<Object> ligatureNotes =
          ligatureParent.findAllDescendantsByType(ClassId.note, deepness: 1);
      final Note? firstNote =
          ligatureNotes.isEmpty ? null : ligatureNotes.first as Note;
      if (firstNote != null && !identical(firstNote, note)) {
        final Alignment? alignment = firstNote.getAlignment();
        layerElement.setAlignment(alignment);
        alignment?.addLayerElementRef(layerElement);
        final Fraction duration =
            layerElement.getAlignmentDuration(meterParams, true, notationType);
        _time = _time + duration;
        return FunctorCode.continue_;
      }
    } else if (layerElement.classId == ClassId.ligature) {
      // A ligature gets a default alignment in order to allow mensural
      // cast-off (nothing to do here, the generic path applies).
    } else if (layerElement
        .isAny({ClassId.beam, ClassId.fTrem, ClassId.tuplet})) {
      // We do not align these (container). Any other?
      final Fraction duration = layerElement.getSameAsContentAlignmentDuration(
          meterParams, true, notationType);
      _time = _time + duration;
      return FunctorCode.continue_;
    } else if (layerElement.classId == ClassId.barLine) {
      type = AlignmentType.barline;
    } else if (layerElement.classId == ClassId.clef) {
      if ((scoreDefRole == ElementScoreDefRole.system) ||
          (scoreDefRole == ElementScoreDefRole.intermediate)) {
        type = AlignmentType.scoreDefClef;
      } else if (scoreDefRole == ElementScoreDefRole.cautionary) {
        type = AlignmentType.scoreDefCautionClef;
      } else if (scoreDefRole == ElementScoreDefRole.ossia) {
        type = AlignmentType.scoreDefOssiaClef;
      } else {
        type = AlignmentType.clef;
      }
    } else if (layerElement.classId == ClassId.keysig) {
      if ((scoreDefRole == ElementScoreDefRole.system) ||
          (scoreDefRole == ElementScoreDefRole.intermediate)) {
        type = AlignmentType.scoreDefKeySig;
      } else if (scoreDefRole == ElementScoreDefRole.cautionary) {
        type = AlignmentType.scoreDefCautionKeySig;
      } else if (scoreDefRole == ElementScoreDefRole.ossia) {
        type = AlignmentType.scoreDefOssiaKeySig;
      } else {
        type = AlignmentType.keySig;
      }
    } else if (layerElement.classId == ClassId.mensur) {
      if ((scoreDefRole == ElementScoreDefRole.system) ||
          (scoreDefRole == ElementScoreDefRole.intermediate)) {
        type = AlignmentType.scoreDefMensur;
      } else if (scoreDefRole == ElementScoreDefRole.cautionary) {
        type = AlignmentType.scoreDefCautionMensur;
      } else {
        // replace the current mensur
        meterParams.mensur = layerElement;
        type = AlignmentType.mensur;
      }
    } else if (layerElement.classId == ClassId.meterSig) {
      if ((scoreDefRole == ElementScoreDefRole.system) ||
          (scoreDefRole == ElementScoreDefRole.intermediate)) {
        type = AlignmentType.scoreDefMeterSig;
      } else if (scoreDefRole == ElementScoreDefRole.cautionary) {
        type = AlignmentType.scoreDefCautionMeterSig;
      } else if (layerElement.parent != null &&
          layerElement.parent!.classId == ClassId.meterSigGrp) {
        type = AlignmentType.scoreDefMeterSig;
      } else {
        // Replace the current meter signature. We force the scoreDef type
        // because they should appear only at the beginning of a measure and
        // should be non-justifiable (also required by the PAE importer).
        meterParams.meterSig = layerElement;
        type = AlignmentType.scoreDefMeterSig;
      }
    } else if (layerElement.classId == ClassId.proport) {
      if (layerElement.type == 'cmme_tempo_change') {
        return FunctorCode.siblings;
      }
      // replace the current proport
      final Object? previous = meterParams.proport;
      meterParams.proport = layerElement;
      if (previous != null) {
        (meterParams.proport as dynamic).cumulate(previous);
      }
      type = AlignmentType.proport;
    } else if (layerElement
        .isAny({ClassId.multiRest, ClassId.mRest, ClassId.mRpt})) {
      type = AlignmentType.fullMeasure;
    } else if (layerElement.isAny({ClassId.mRpt2, ClassId.multiRpt})) {
      type = AlignmentType.fullMeasure2;
    } else if (layerElement.classId == ClassId.dot) {
      final Dot dot = layerElement as Dot;
      if (dot.drawingPreviousElement is LayerElement) {
        layerElement.setAlignment(
            (dot.drawingPreviousElement as LayerElement).getAlignment());
      } else {
        // Create an alignment only if the dot has no resolved preceding note
        type = AlignmentType.dot;
      }
    } else if (layerElement.classId == ClassId.custos) {
      type = AlignmentType.custos;
    } else if (layerElement.classId == ClassId.accid) {
      // accid within note was already taken into account by noteParent
      type = AlignmentType.accid;
    } else if (layerElement.classId == ClassId.artic) {
      // Refer to the note parent
      final Note? note = layerElement.getFirstAncestor(ClassId.note) as Note?;
      assert(note != null);
      layerElement.setAlignment(note!.getAlignment());
    } else if (layerElement.classId == ClassId.syl) {
      final Note? note = layerElement.getFirstAncestor(ClassId.note) as Note?;
      if (note != null) {
        layerElement.setAlignment(note.getAlignment());
      } else {
        final syllable = layerElement.getFirstAncestor(ClassId.syllable);
        if (syllable is LayerElement) {
          layerElement.setAlignment(syllable.getAlignment());
        }
      }
      // Else add a default
    } else if (layerElement.classId == ClassId.verse) {
      // Idem
      final Note? note = layerElement.getFirstAncestor(ClassId.note) as Note?;
      assert(note != null);
      layerElement.setAlignment(note?.getAlignment());
    } else if (layerElement.classId == ClassId.nc) {
      // Align with the neume
      if (!neumeAsNote) {
        final neume = layerElement.getFirstAncestor(ClassId.neume);
        assert(neume != null);
        if (neume is LayerElement) {
          layerElement.setAlignment(neume.getAlignment());
        }
      }
      // Otherwise each nc has its own aligner
    } else if (layerElement.classId == ClassId.neume) {
      // Align with the syllable
      if (neumeAsNote) {
        final syllable = layerElement.getFirstAncestor(ClassId.syllable);
        assert(syllable != null);
        if (syllable is LayerElement) {
          layerElement.setAlignment(syllable.getAlignment());
        }
        return FunctorCode.continue_;
      }
      // Otherwise each neume has its own aligner
    } else if (layerElement.classId == ClassId.graceGrp) {
      return FunctorCode.continue_;
    } else if (layerElement.isGraceNote()) {
      type = AlignmentType.graceNote;
    }

    Fraction duration = Fraction(0);
    // We have already an alignment with grace note children - skip this
    if (layerElement.getAlignment() == null) {
      // get the duration of the event
      duration =
          layerElement.getAlignmentDuration(meterParams, true, notationType);

      // For timestamp, what we get from GetAlignmentDuration is actually the
      // position of the timestamp. So use it as current time - we can do this
      // because the timestamp loop is redirected from the measure. The time
      // will be reset to 0.0 when starting a new layer anyway.
      if (layerElement.classId == ClassId.timestampAttr) {
        _time = duration;
        // When a tstamp is pointing to the end of a measure, then use the
        // right barline alignment
        if (_time ==
            (_measureAligner!.getRightAlignment()?.getTime() ?? Fraction(0))) {
          type = AlignmentType.measureRightBarline;
        }
      } else {
        _measureAligner!.setMaxTime(_time + duration);
      }

      layerElement
          .setAlignment(_measureAligner!.getAlignmentAtTime(_time, type));
      assert(layerElement.getAlignment() != null);
    }

    final Alignment alignment = layerElement.getAlignment()!;
    if (alignment.getType() != AlignmentType.graceNote) {
      if (alignment.addLayerElementRef(layerElement)) hasMultipleLayer = true;
    }
    // For grace note aligner do not add them to the reference list because
    // they will be processed by their original hierarchy from the
    // GraceAligner
    else {
      assert(layerElement.isGraceNote());
      if (layerElement.classId == ClassId.chord ||
          (layerElement.classId == ClassId.note && chordParent == null)) {
        final Staff staff = layerElement.getAncestorStaffLayout();
        final int graceAlignerId =
            doc.getOptions().graceRhythmAlign.value ? 0 : (staff.n ?? 0);
        final graceAligner = alignment.getGraceAligner(graceAlignerId);
        // We know that this is a note or a chord - we stack them and they
        // will be added at the end of the layer. This will also see it for
        // all their children.
        graceAligner.stackGraceElement(layerElement);
      }
    }

    if (layerElement.classId != ClassId.timestampAttr) {
      // increase the time position, but only when not a timestamp (it would
      // actually do nothing)
      _time = _time + duration;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    // clear the content of the measureAligner
    final MeasureAligner measureAligner = measure.measureAligner;
    measureAligner.reset();

    // point to it
    _measureAligner = measureAligner;
    hasMultipleLayer = false;
    meterParams.metcon = measure.metcon != false;

    if (_setBarLineAlignment(
        measure.getLeftBarLine(), measureAligner.getLeftBarLineAlignment())) {
      hasMultipleLayer = true;
    }
    if (_setBarLineAlignment(
        measure.getRightBarLine(), measureAligner.getRightBarLineAlignment())) {
      hasMultipleLayer = true;
    }

    assert(_measureAligner != null);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    final MeiDuration meterUnit = meterParams.meterSigHasUnit
        ? meterParams.meterSigUnitAsDur
        : MeiDuration.dur4;
    measure.measureAligner.setInitialTstamp(meterUnit);

    // We also need to align the timestamps - we do it at the end since we
    // need the *meterSig to be initialized by a Layer. Obviously this will
    // not work with different time signature. However, I am not sure how
    // this would work in MEI anyway.
    measure.timestampAligner.process(this);

    // Next scoreDef will be INTERMEDIATE_SCOREDEF (see visitLayer)
    isFirstMeasure = false;

    sectionRestart = false;

    if (hasMultipleLayer) measure.setHasAlignmentRefWithMultipleLayers(true);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeterSigGrp(MeterSigGrp meterSigGrp) {
    return meterSigGrp.isScoreDefElement
        ? FunctorCode.stop
        : FunctorCode.continue_;
  }

  // TODO(phase-5+): ossia support (VisitOssia).

  @override
  FunctorCode visitSection(Section section) {
    if (section.restart == true) {
      sectionRestart = true;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    final dynamic drawingStaffDef = staff.drawingStaffDef;
    assert(drawingStaffDef != null);
    if (drawingStaffDef == null) return FunctorCode.continue_;

    final bool hasNotationtype =
        drawingStaffDef.hasNotationtype as bool? ?? false;
    notationType = hasNotationtype
        ? drawingStaffDef.notationtype as Notationtype
        : Notationtype.cmn;

    // Deviation: StaffDef::AlternateCurrentMeterSig (alternating
    // meterSigGrp) is not ported yet.

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    // since we are starting a new system its first scoreDef will need to be
    // a SYSTEM_SCOREDEF
    isFirstMeasure = true;

    return FunctorCode.continue_;
  }

  /// Visit the current staffDef drawing objects of the layer (mirrors the
  /// direct `VisitClef` / `VisitKeySig` / ... calls of `VisitLayer`). The
  /// effective behaviour of those calls is the generic layer element visit.
  void _visitLayerStaffDefObjects(Layer layer) {
    if (layer.staffDefClef != null && !_isInvisible(layer.staffDefClef)) {
      visitLayerElement(layer.staffDefClef!);
    }
    if (layer.staffDefKeySig != null && !_isInvisible(layer.staffDefKeySig)) {
      visitLayerElement(layer.staffDefKeySig!);
    }
    if (layer.staffDefMensur != null) {
      visitLayerElement(layer.staffDefMensur!);
    }
    if (layer.staffDefMeterSigGrp != null) {
      layer.staffDefMeterSigGrp!.process(this);
      // Inner process may stop, still continue the outer process
      resetCode();
    } else if (layer.staffDefMeterSig != null &&
        !_isInvisible(layer.staffDefMeterSig)) {
      visitLayerElement(layer.staffDefMeterSig!);
    }
  }

  /// Mirrors `BarLine::SetAlignment`: sets the alignment pointer and adds the
  /// barline to the alignment references. Returns true when the reference
  /// holds more than one layer.
  bool _setBarLineAlignment(BarLine barLine, Alignment? alignment) {
    barLine.setAlignment(alignment);
    return alignment!.addLayerElementRef(barLine);
  }

  static bool _isInvisible(Object? object) {
    if (object is AttVisibility) {
      final AttVisibility visibility = object as AttVisibility;
      return visibility.visible == false;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// AlignMeasuresFunctor
// ---------------------------------------------------------------------------

/// This class aligns the measures by adjusting the m_drawingXRel position
/// looking at the MeasureAligner (mirrors `vrv::AlignMeasuresFunctor`).
///
/// At the end, store the width of the system in the SystemAligner for
/// justification.
class AlignMeasuresFunctor extends DocFunctor {
  AlignMeasuresFunctor(super.doc);

  /// The cumulated shift (mirrors `m_shift`).
  int shift = 0;

  /// The cumulated justifiable width (mirrors `m_justifiableWidth`).
  int justifiableWidth = 0;

  /// Shift next measure due to section restart? (mirrors
  /// `m_applySectionRestartShift`).
  bool applySectionRestartShift = false;

  /// Store castoff system widths if true (mirrors
  /// `m_storeCastOffSystemWidths`).
  bool storeCastOffSystemWidths = false;

  @override
  FunctorCode visitDiv(Div div) {
    if (div.getDrawingInline()) div.setDrawingXRel(shift);

    // Deviation: Div::GetContentWidth requires the text measurement of the
    // rendering phase; the width is not added for now.
    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    if (applySectionRestartShift) {
      shift += _sectionRestartShift(measure);
      applySectionRestartShift = false;
    }

    measure.setDrawingXRel(shift);

    shift += measure.getWidth();
    justifiableWidth +=
        measure.getRightBarLineXRel() - measure.getLeftBarLineXRel();

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    shift += scoreDef.drawingLabelsWidth;

    if (applySectionRestartShift) {
      final labels = ClassIdsComparison([ClassId.label, ClassId.labelAbbr]);
      if (scoreDef.findDescendantByComparison(labels) != null) {
        applySectionRestartShift = false;
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSection(Section section) {
    if (section.restart == true) {
      applySectionRestartShift = true;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    system
        .setDrawingXRel(system.systemLeftMar + system.getDrawingLabelsWidth());
    shift = 0;
    justifiableWidth = 0;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemEnd(System system) {
    if (storeCastOffSystemWidths) {
      // Store the cast-off widths; these are used by the justification to
      // estimate the ratio before the systems are re-aligned.
      system.castOffTotalWidth = shift + system.getDrawingLabelsWidth();
      system.castOffJustifiableWidth = justifiableWidth;
    } else {
      system.drawingTotalWidth = shift + system.getDrawingLabelsWidth();
      system.drawingJustifiableWidth = justifiableWidth;
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `Measure::GetSectionRestartShift`.
  int _sectionRestartShift(Measure measure) {
    if (measure.isFirstInSystem()) return 0;
    return 5 * doc.getDrawingDoubleUnit(100);
  }
}
