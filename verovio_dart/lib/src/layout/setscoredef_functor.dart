/// Port of `setscoredeffunctor.h/cpp` — the functors that propagate the
/// encoded scoreDefs into the current drawing values used by the layout.
///
/// This library contains:
/// - [ScoreDefUnsetCurrentFunctor]: clears the current drawing scoreDef
///   state (run when the preparation has to be re-done).
/// - [ScoreDefSetCurrentPageFunctor]: sets `Page::m_score` / `m_scoreEnd`.
/// - [ScoreDefSetCurrentFunctor]: the main propagation functor, including
///   clef/keySig/mensur/meterSig changes within the score and the layer
///   drawing staffDef values (staffDef clef / keySig objects).
/// - [SetCautionaryScoreDefFunctor]: sets cautionary values on the last
///   measure before a scoreDef change or a system break.
/// - [ScoreDefSetGrpSymFunctor]: resolves the staffGrp group symbols.
/// - [ScoreDefOptimizeFunctor]: hides empty staves for the `condense` option.
/// - [ScoreDefSetOssiaFunctor]: prepares the ossia staffDefs for drawing.
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/utils.dart' show extractIDFragment;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show MetersiggrplogFunc, Notationtype;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/comparison.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show KeySig, MeterSigGrp, Proport;
import 'package:verovio_dart/src/model/mensur.dart' show Mensur;
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';

// ---------------------------------------------------------------------------
// ScoreDefUnsetCurrentFunctor
// ---------------------------------------------------------------------------

/// Unset all the current scoreDef (mirrors `vrv::ScoreDefUnsetCurrentFunctor`).
class ScoreDefUnsetCurrentFunctor extends Functor {
  @override
  FunctorCode visitAlignmentReference(AlignmentReference alignmentReference) {
    final Alignment? alignment = alignmentReference.parent is Alignment
        ? alignmentReference.parent as Alignment
        : null;
    assert(alignment != null);

    switch (alignment!.getType()) {
      case AlignmentType.scoreDefOssiaClef:
      case AlignmentType.scoreDefOssiaKeySig:
      case AlignmentType.scoreDefClef:
      case AlignmentType.scoreDefKeySig:
      case AlignmentType.scoreDefMensur:
      case AlignmentType.scoreDefMeterSig:
      case AlignmentType.scoreDefCautionClef:
      case AlignmentType.scoreDefCautionKeySig:
      case AlignmentType.scoreDefCautionMensur:
      case AlignmentType.scoreDefCautionMeterSig:
        alignmentReference.deleteChildrenByComparison((Object child) => true);
        break;
      default:
        break;
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitKeySig(KeySig keySig) {
    keySig.resetDrawingClef();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayer(Layer layer) {
    layer.resetStaffDefObjects();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    measure.resetDrawingScoreDef();

    // We also need to remove scoreDef elements in the AlignmentReference
    // objects.
    measure.measureAligner.process(this);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitOssia(Ossia ossia) {
    ossia.resetDrawingStaffGrp();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitPage(Page page) {
    page.score = null;
    page.scoreEnd = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    staff.drawingStaffDef = null;
    staff.drawingTuning = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    system.resetDrawingScoreDef();
    system.drawingIsOptimized = false;

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// ScoreDefSetCurrentPageFunctor
// ---------------------------------------------------------------------------

/// Set the Page::m_score and Page::m_scoreEnd pointers (mirrors
/// `vrv::ScoreDefSetCurrentPageFunctor`). The C++ processes the doc with
/// deepness 3 so only pages and their direct children are visited; here the
/// functor is run by Doc.scoreDefSetCurrentDoc with the same deepness.
class ScoreDefSetCurrentPageFunctor extends DocFunctor {
  ScoreDefSetCurrentPageFunctor(super.doc);

  /// The scores seen so far (mirrors `m_scores`).
  final List<Score> scores = [];

  @override
  FunctorCode visitPageEnd(Page page) {
    final Object? firstSystem = page.getFirst(ClassId.system);
    Object reference = firstSystem ?? page;
    page.score = doc.getCorrespondingScore(reference, scores);

    final Object? lastSystem = page.getLast(ClassId.system);
    reference = lastSystem ?? page;
    page.scoreEnd = doc.getCorrespondingScore(reference, scores);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScore(Score score) {
    scores.add(score);

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// SetCautionaryScoreDefFunctor
// ---------------------------------------------------------------------------

/// Set the cautionary scoreDef values of the layers of each staff (mirrors
/// `vrv::SetCautionaryScoreDefFunctor`).
class SetCautionaryScoreDefFunctor extends Functor {
  SetCautionaryScoreDefFunctor(this.currentScoreDef);

  /// The scoreDef holding the cautionary values (mirrors `m_currentScoreDef`).
  final ScoreDef currentScoreDef;

  /// The staffDef of the staff being visited (mirrors `m_currentStaffDef`).
  StaffDef? currentStaffDef;

  @override
  FunctorCode visitLayer(Layer layer) {
    layer.setDrawingCautionValues(currentStaffDef);
    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    if (staff.isOssia()) return FunctorCode.siblings;

    currentStaffDef = currentScoreDef.getStaffDef(staff.n ?? 0);
    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// ScoreDefSetCurrentFunctor
// ---------------------------------------------------------------------------

/// Propagate the current scoreDef into the drawing values (mirrors
/// `vrv::ScoreDefSetCurrentFunctor`).
class ScoreDefSetCurrentFunctor extends DocFunctor {
  ScoreDefSetCurrentFunctor(super.doc) {
    upcomingScoreDef.reset();
  }

  /// The score currently processed (mirrors `m_currentScore`).
  Score? currentScore;

  /// The current scoreDef of the measure being drawn (mirrors
  /// `m_currentScoreDef`).
  ScoreDef? currentScoreDef;

  /// The staffDef corresponding to the staff being processed (mirrors
  /// `m_currentStaffDef`).
  StaffDef? currentStaffDef;

  /// The upcoming scoreDef (mirrors `m_upcomingScoreDef`).
  final ScoreDef upcomingScoreDef = ScoreDef();

  /// The previous measure (mirrors `m_previousMeasure`).
  Measure? previousMeasure;

  /// The system being processed (mirrors `m_currentSystem`).
  System? currentSystem;

  /// Whether labels need to be drawn (mirrors `m_drawLabels`).
  bool drawLabels = false;

  /// Whether we are right after a section@restart (mirrors `m_restart`).
  bool restart = false;

  /// Whether a measure was already seen in the system (mirrors
  /// `m_hasMeasure`).
  bool hasMeasure = false;

  /// Whether an ossia is present (mirrors `m_hasOssia`).
  bool hasOssia = false;

  /// The ossia staves above / below each original staff `@n`, collected in
  /// the current system and consolidated onto the drawing scoreDef at
  /// `visitSystemEnd` (mirrors `m_ossiasAbove` / `m_ossiasBelow`,
  /// `MapOfOssiaStaffNs`).
  final Map<int, List<int>> ossiasAbove = {};
  final Map<int, List<int>> ossiasBelow = {};

  @override
  FunctorCode visitClef(Clef clef) {
    final LayerElement? elementOrLink = _thisOrSameasLink(clef);
    if (elementOrLink is! Clef) return FunctorCode.continue_;
    if (elementOrLink.isScoreDefElement) return FunctorCode.continue_;
    final int n = elementOrLink.crossStaff is Staff
        ? ((elementOrLink.crossStaff as Staff).n ?? 0)
        : (currentStaffDef?.n ?? 0);
    final StaffDef? upcomingStaffDef = upcomingScoreDef.getStaffDef(n);
    assert(upcomingStaffDef != null);
    upcomingStaffDef?.setCurrentClef(elementOrLink);
    logDebug(
        'DBG visitClef shape=${clef.shape} -> upcoming staffDef $n curShape=${upcomingStaffDef?.getCurrentClef().shape}');
    upcomingScoreDef.setAsDrawing = true;
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitKeySig(KeySig keySig) {
    if (keySig.isScoreDefElement) return FunctorCode.continue_;
    assert(currentStaffDef != null);
    final StaffDef? upcomingStaffDef =
        upcomingScoreDef.getStaffDef(currentStaffDef?.n ?? 0);
    assert(upcomingStaffDef != null);
    upcomingStaffDef?.setCurrentKeySig(keySig);
    upcomingScoreDef.setAsDrawing = true;
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayer(Layer layer) {
    if (doc.getType() != DocType.transcription) {
      layer.setDrawingStaffDefValues(currentStaffDef);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    // If we have a restart scoreDef before, for redrawing of everything on
    // the measure.
    if (restart) {
      upcomingScoreDef.setRedrawFlags(StaffDefRedrawFlags.redrawAll);
    }

    int drawingFlags = 0;
    // This is the first measure of the system - more to do...
    if (currentSystem != null) {
      drawingFlags |= Measure.barlineSystemBreak;
      // We had a scoreDef so we need to put cautionary values. The
      // cautionary scoreDef for restart is already done when hitting the
      // scoreDef.
      if (upcomingScoreDef.setAsDrawing &&
          previousMeasure != null &&
          !restart) {
        final ScoreDef cautionaryScoreDef = ScoreDef();
        cautionaryScoreDef.replaceWithCopyOf(upcomingScoreDef);
        final setCautionaryScoreDef =
            SetCautionaryScoreDefFunctor(cautionaryScoreDef);
        previousMeasure!.process(setCautionaryScoreDef);
      }
      // Set the flags we want to have. This also sets m_setAsDrawing to true
      // so the next measure will keep it.
      upcomingScoreDef.setRedrawFlags(
          StaffDefRedrawFlags.redrawClef | StaffDefRedrawFlags.redrawKeySig);
      // Set it to the current system (used e.g. for endings).
      currentSystem!.setDrawingScoreDef(upcomingScoreDef);
      currentSystem!.drawingScoreDef?.setDrawLabels(drawLabels);
      currentSystem = null;
      drawLabels = false;
    }
    logDebug(
        'DBG visitMeasure ${measure.n} setAsDrawing=${upcomingScoreDef.setAsDrawing}');
    if (upcomingScoreDef.setAsDrawing) {
      measure.setDrawingScoreDef(upcomingScoreDef);
      currentScoreDef = measure.getDrawingScoreDef();
      logDebug(
          'DBG copy made: same=${identical(currentScoreDef, upcomingScoreDef)} childSame=${identical(currentScoreDef?.getFirst(), upcomingScoreDef.getFirst())}');
      upcomingScoreDef.setRedrawFlags(StaffDefRedrawFlags.forceRedraw);
      upcomingScoreDef.setAsDrawing = false;
    }
    drawLabels = false;

    // Set other flags based on score def change.
    if (upcomingScoreDef.insertScoreDef) {
      drawingFlags |= Measure.barlineScoreDefInsert;
      upcomingScoreDef.insertScoreDef = false;
    }

    // Check if we need to draw barlines for current/previous measures (in
    // cases when all staves are invisible in them).
    final List<Object> currentObjects = measure.findAllDescendantsMatching(
        AttVisibilityComparison(ClassId.staff, false));
    if (currentObjects.length == _getStaffCount(measure)) {
      drawingFlags |= Measure.barlineInvisibleMeasureCurrent;
    }
    List<Object> previousObjects = [];
    if (previousMeasure != null) {
      previousObjects = previousMeasure!.findAllDescendantsMatching(
          AttVisibilityComparison(ClassId.staff, false));
      if (previousObjects.length == _getStaffCount(previousMeasure!)) {
        drawingFlags |= Measure.barlineInvisibleMeasurePrevious;
      }
    }

    measure.setInvisibleStaffBarlines(
        previousMeasure, currentObjects, previousObjects, drawingFlags);
    measure.setDrawingBarLines(previousMeasure, drawingFlags);

    previousMeasure = measure;
    restart = false;
    hasMeasure = true;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMensur(Mensur mensur) {
    if (mensur.isScoreDefElement) return FunctorCode.continue_;
    assert(currentStaffDef != null);
    final StaffDef? upcomingStaffDef =
        upcomingScoreDef.getStaffDef(currentStaffDef?.n ?? 0);
    assert(upcomingStaffDef != null);
    upcomingStaffDef?.setCurrentMensur(mensur);
    upcomingScoreDef.setAsDrawing = true;
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitOssia(Ossia ossia) {
    ossia.getStavesAbove(ossiasAbove);
    ossia.getStavesBelow(ossiasBelow);
    hasOssia = true;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitPage(Page page) {
    // This will be reached before we reach the beginning of a first Score.
    // However, page->m_score has already been set by
    // ScoreDefSetCurrentPageFunctor. This must be the first page or a new
    // score is starting on this page.
    assert(page.score != null);
    final Score pageScore = page.score as Score;
    assert(pageScore.getScoreDef() != null);
    if (currentScore == null || !identical(currentScore, pageScore)) {
      upcomingScoreDef
        ..reset()
        ..replaceWithCopyOf(pageScore.getScoreDef() as ScoreDef);
      upcomingScoreDef.process(this);
    }
    page.drawingScoreDef.replaceWithCopyOf(upcomingScoreDef);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitProport(Proport proport) {
    if (proport.type == 'cmme_tempo_change') return FunctorCode.siblings;
    assert(currentStaffDef != null);
    final StaffDef? upcomingStaffDef =
        upcomingScoreDef.getStaffDef(currentStaffDef?.n ?? 0);
    assert(upcomingStaffDef != null);
    upcomingStaffDef?.setCurrentProport(proport);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScore(Score score) {
    currentScore = score;
    upcomingScoreDef
      ..reset()
      ..replaceWithCopyOf(score.getScoreDef() as ScoreDef);
    upcomingScoreDef.process(this);
    // Trigger the redraw of everything.
    upcomingScoreDef.setRedrawFlags(StaffDefRedrawFlags.redrawAll);
    drawLabels = true;
    currentScoreDef = null;
    currentStaffDef = null;
    previousMeasure = null;
    currentSystem = null;
    restart = false;
    hasMeasure = false;
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    // Replace the current scoreDef with the new one, including its content
    // (staffDef) - this also sets m_setAsDrawing to true so it will then be
    // taken into account at the next measure.
    if (scoreDef.hasClefInfo(unlimitedDepth) ||
        scoreDef.hasKeySigInfo(unlimitedDepth) ||
        scoreDef.hasMensurInfo(unlimitedDepth) ||
        scoreDef.hasMeterSigGrpInfo(unlimitedDepth) ||
        scoreDef.hasMeterSigInfo(unlimitedDepth)) {
      upcomingScoreDef.replaceDrawingValues(scoreDef);
      upcomingScoreDef.insertScoreDef = true;
    }
    if (scoreDef.isSectionRestart()) {
      drawLabels = true;
      restart = true;
      // Redraw the labels only if we already have a measure in the system.
      // Otherwise this will be done through the system scoreDef.
      scoreDef.setDrawLabels(hasMeasure);
      // If we have a previous measure, we need to set the cautionary
      // scoreDef independently from the presence of a system break.
      if (previousMeasure != null) {
        final ScoreDef cautionaryScoreDef = ScoreDef();
        cautionaryScoreDef.replaceWithCopyOf(upcomingScoreDef);
        final setCautionaryScoreDef =
            SetCautionaryScoreDefFunctor(cautionaryScoreDef);
        previousMeasure!.process(setCautionaryScoreDef);
      }
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    if (staff.isOssia()) return FunctorCode.siblings;
    currentStaffDef = currentScoreDef?.getStaffDef(staff.n ?? 0);
    assert(currentStaffDef != null);
    assert(staff.drawingStaffDef == null);
    staff.drawingStaffDef = currentStaffDef;
    assert(staff.drawingTuning == null);
    staff.drawingTuning = currentStaffDef?.findDescendantByType(ClassId.tuning);
    staff.drawingLines = currentStaffDef?.lines ?? 5;
    staff.drawingNotationtype = currentStaffDef!.notationtype;
    staff.drawingStaffSize = 100;
    if (currentStaffDef!.hasScale) {
      staff.drawingStaffSize = currentStaffDef!.scale!.toInt();
    }
    if (_isTablatureStaff(staff)) {
      staff.drawingStaffSize =
          (staff.drawingStaffSize * tablatureStaffRatio).toInt();
    }
    // Port of `ScoreDefSetCurrentFunctor::VisitStaff` alternating MeterSigGrp
    // (setscoredeffunctor.cpp:340-344, metersiggrp.cpp:67).
    final MeterSigGrp? meterSigGrp = currentStaffDef?.getCurrentMeterSigGrp();
    if (meterSigGrp != null &&
        meterSigGrp.func == MetersiggrplogFunc.alternating) {
      final Object? parentMeasure = staff.getFirstAncestor(ClassId.measure);
      if (parentMeasure != null) {
        meterSigGrp.addAlternatingMeasure(parentMeasure);
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaffDef(StaffDef staffDef) {
    upcomingScoreDef.replaceDrawingValuesFromStaffDef(staffDef);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaffGrp(StaffGrp staffGrp) {
    // For now replace labels only if we have a section@restart.
    if (restart) {
      upcomingScoreDef.replaceDrawingLabels(staffGrp);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    // This is the only thing we do for now - we need to wait until we reach
    // the first measure.
    currentSystem = system;
    hasMeasure = false;

    ossiasAbove.clear();
    ossiasBelow.clear();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemEnd(System system) {
    final ScoreDef? scoreDef = system.drawingScoreDef;
    if (scoreDef != null) {
      for (final MapEntry<int, List<int>> entry in ossiasAbove.entries) {
        scoreDef.addOssias(entry.key, entry.value, true);
      }
      for (final MapEntry<int, List<int>> entry in ossiasBelow.entries) {
        scoreDef.addOssias(entry.key, entry.value, false);
      }
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `LayerElement::ThisOrSameasLink` restricted to clefs.
  LayerElement? _thisOrSameasLink(Clef clef) {
    if (clef.hasSameasLink) {
      final Object? link = clef.sameasLink;
      return link is LayerElement ? link : null;
    }
    return clef;
  }

  static int _getStaffCount(Measure measure) =>
      measure.findAllDescendantsByType(ClassId.staff, deepness: 1).length;

  static bool _isTablatureStaff(Staff staff) {
    final StaffDef? staffDef = staff.drawingStaffDef is StaffDef
        ? staff.drawingStaffDef as StaffDef
        : null;
    final Notationtype? notationtype = staffDef?.notationtype;
    return notationtype == Notationtype.tab ||
        notationtype == Notationtype.tabStaffLike ||
        notationtype == Notationtype.tabGuitar;
  }
}

// ---------------------------------------------------------------------------
// ScoreDefSetGrpSymFunctor
// ---------------------------------------------------------------------------

/// Resolve the grpSym start / end staffDefs (mirrors
/// `vrv::ScoreDefSetGrpSymFunctor`).
class ScoreDefSetGrpSymFunctor extends Functor {
  @override
  FunctorCode visitGrpSym(GrpSym grpSym) {
    // For the grpSym that is encoded in the scope of the staffGrp just get
    // first and last staffDefs and set them as starting and ending points.
    if (grpSym.parent is StaffGrp) {
      final StaffGrp staffGrp = grpSym.parent as StaffGrp;
      final (StaffDef?, StaffDef?) firstLast = staffGrp.getFirstLastStaffDef();
      if (firstLast.$1 != null && firstLast.$2 != null) {
        grpSym.setStartDef(firstLast.$1);
        grpSym.setEndDef(firstLast.$2);
        staffGrp.setGroupSymbol(grpSym);
      }
    }
    // For the grpSym that is encoded in the scope of the scoreDef we need to
    // find corresponding staffDefs with matching @startid and @endid.
    else if (grpSym.parent is ScoreDef) {
      final ScoreDef scoreDef = grpSym.parent as ScoreDef;

      final String startId = extractIDFragment(grpSym.startid ?? '');
      final String endId = extractIDFragment(grpSym.endid ?? '');
      final int level = (grpSym.level ?? meiUnset) == meiUnset
          ? unlimitedDepth
          : grpSym.level!;

      IDComparison compare = IDComparison(ClassId.staffDef, startId);
      final Object? start =
          scoreDef.findDescendantByComparison(compare, deepness: level);
      compare = IDComparison(ClassId.staffDef, endId);
      final Object? end =
          scoreDef.findDescendantByComparison(compare, deepness: level);

      if (start == null || end == null) {
        logWarning(
            "Could not find startid/endid on level $level for '${grpSym.id}'");
        return FunctorCode.continue_;
      }

      if (!identical(start.parent, end.parent)) {
        logWarning(
            "'${grpSym.id}' has mismatching parents for startid:$startId "
            'and endid:$endId');
        return FunctorCode.continue_;
      }

      grpSym.setStartDef(start);
      grpSym.setEndDef(end);
      final StaffGrp staffGrp = start.parent as StaffGrp;
      staffGrp.setGroupSymbol(grpSym);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    final ScoreDef? drawingScoreDef = system.drawingScoreDef;
    drawingScoreDef?.process(this);

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// ScoreDefOptimizeFunctor
// ---------------------------------------------------------------------------

/// Optimize the scoreDef for each system: for automatic breaks, look for
/// staves with only mRests and hide them (mirrors
/// `vrv::ScoreDefOptimizeFunctor`).
class ScoreDefOptimizeFunctor extends DocFunctor {
  ScoreDefOptimizeFunctor(super.doc);

  /// The current scoreDef (mirrors `m_currentScoreDef`).
  ScoreDef? currentScoreDef;

  /// Flag indicating if we are optimizing encoded layout (mirrors
  /// `m_encoded`).
  bool encoded = false;

  /// Flag indicating if we consider the first scoreDef (mirrors
  /// `m_firstScoreDef`).
  bool firstScoreDef = true;

  /// Flag indicating if a Fermata element is present (mirrors
  /// `m_hasFermata`).
  bool hasFermata = false;

  /// Flag indicating if a Tempo element is present (mirrors `m_hasTempo`).
  bool hasTempo = false;

  @override
  FunctorCode visitMeasure(Measure measure) {
    if (!doc.getOptions().condenseTempoPages.value) {
      return FunctorCode.continue_;
    }

    hasFermata = measure.findDescendantByType(ClassId.fermata) != null;
    hasTempo = measure.findDescendantByType(ClassId.tempo) != null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScore(Score score) {
    currentScoreDef = null;
    encoded = false;
    firstScoreDef = true;
    hasFermata = false;
    hasTempo = false;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    assert(currentScoreDef != null);
    final StaffDef? staffDef = currentScoreDef!.getStaffDef(staff.n ?? 0);

    if (staffDef == null) {
      logDebug('Could not find staffDef for staff (${staff.n}) when '
          'optimizing scoreDef');
      return FunctorCode.siblings;
    }

    // Always show staves with a clef change.
    if (staff.findDescendantByType(ClassId.clef) != null) {
      staffDef.setDrawingVisibility(VisibilityOptimization.show);
    }

    // Always show all staves when there is a fermata or a tempo (without
    // checking if the fermata is actually on that staff).
    if (hasFermata || hasTempo) {
      staffDef.setDrawingVisibility(VisibilityOptimization.show);
    }

    if (staffDef.getDrawingVisibility() == VisibilityOptimization.show) {
      return FunctorCode.siblings;
    }

    staffDef.setDrawingVisibility(VisibilityOptimization.hidden);

    // Show the staff only if there are any notes.
    if (staff.findDescendantByType(ClassId.note) != null) {
      staffDef.setDrawingVisibility(VisibilityOptimization.show);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitStaffGrpEnd(StaffGrp staffGrp) {
    staffGrp.drawingVisibility = VisibilityOptimization.hidden;

    final Object? instrDef =
        staffGrp.findDescendantByType(ClassId.instrDef, deepness: 1);
    if (instrDef != null) {
      final visibleStaves = VisibleStaffDefOrGrpObject();
      final Object? firstVisible =
          staffGrp.findDescendantByComparison(visibleStaves, deepness: 1);
      if (firstVisible != null) {
        staffGrp.setEverythingVisible();
      }

      return FunctorCode.continue_;
    }

    for (final Object child in staffGrp.children) {
      if (child is StaffDef) {
        if (child.getDrawingVisibility() != VisibilityOptimization.hidden) {
          staffGrp.drawingVisibility = VisibilityOptimization.show;
          break;
        }
      } else if (child is StaffGrp) {
        if (child.drawingVisibility != VisibilityOptimization.hidden) {
          staffGrp.drawingVisibility = VisibilityOptimization.show;
          break;
        }
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    system.drawingIsOptimized = true;

    if (firstScoreDef) {
      firstScoreDef = false;
      if (!doc.getOptions().condenseFirstPage.value) {
        return FunctorCode.siblings;
      }
    }

    if (system.isLastOfMdiv()) {
      if (doc.getOptions().condenseNotLastSystem.value) {
        return FunctorCode.siblings;
      }
    }

    currentScoreDef = system.drawingScoreDef;

    if (currentScoreDef == null) return FunctorCode.siblings;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemEnd(System system) {
    currentScoreDef!.process(this);
    system.systemAligner.setSpacing(currentScoreDef);

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// ScoreDefSetOssiaFunctor
// ---------------------------------------------------------------------------

/// Prepare the ossia staffDefs for drawing (mirrors
/// `vrv::ScoreDefSetOssiaFunctor`).
class ScoreDefSetOssiaFunctor extends DocFunctor {
  ScoreDefSetOssiaFunctor(super.doc);

  /// The current ossias, i.e. in the current measure (mirrors
  /// `m_currentOssias`, a `std::list<CurrentOssia>` used as a stack via
  /// `push_front` / `front`; index 0 here is the C++ `front()`).
  final List<_CurrentOssia> _currentOssias = [];

  /// The ossias in the previous measure (mirrors `m_previousOssias`).
  List<_CurrentOssia> _previousOssias = [];

  /// The upcoming staffDef (mirrors `m_upcomingStaffDef`).
  StaffDef upcomingStaffDef = StaffDef();

  /// The current scoreDef (mirrors `m_currentScoreDef`).
  ScoreDef? currentScoreDef;

  /// The current staffDef (mirrors `m_currentStaffDef`).
  StaffDef? currentStaffDef;

  /// A flag indicating the layer ossia staffDef will have to be drawn
  /// (mirrors `m_layerOssiaStaffDef`).
  bool layerOssiaStaffDef = false;

  /// Flag for the first measure in the system (mirrors `m_isFirstMeasure`).
  bool isFirstMeasure = true;

  @override
  FunctorCode visitClef(Clef clef) {
    final LayerElement? elementOrLink = _thisOrSameasLink(clef);
    if (elementOrLink is! Clef) return FunctorCode.continue_;
    if (elementOrLink.isScoreDefElement) return FunctorCode.continue_;
    // Set the clef to the upcoming ossia - stored in visitStaffEnd.
    upcomingStaffDef.setCurrentClef(elementOrLink);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayer(Layer layer) {
    layer.setDrawingStaffDefValues(currentStaffDef);
    if (layerOssiaStaffDef) {
      layer.drawOssiaStaffDef = true;
    }
    // Do not set it on the next layer.
    layerOssiaStaffDef = false;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    _currentOssias.clear();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    _previousOssias = List.of(_currentOssias);
    isFirstMeasure = false;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitOssia(Ossia ossia) {
    _currentOssias.insert(0, _CurrentOssia(ossia));

    final List<int> current = ossia.getOStaffNs();

    // Check if we have a previous ossia.
    final _CurrentOssia? previous = _findPreviousOssia(current);
    if (previous != null && !isFirstMeasure) {
      previous.ossia.setLast(false);
      ossia.setFirst(false);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    if (!staff.isOssia() || staff.isHidden) return FunctorCode.siblings;

    assert(_currentOssias.isNotEmpty);
    final _CurrentOssia currentOssia = _currentOssias.first;
    final Staff? originalStaff =
        currentOssia.ossia.getOriginalStaffForOssia(staff);
    assert(originalStaff != null);

    // Get the `@bar.thru` from the system scoreDef.
    if (currentOssia.ossia.hasMultipleOStaves()) {
      assert(currentScoreDef != null);
      final StaffDef? originalStaffDef =
          currentScoreDef!.getStaffDef(originalStaff!.n ?? 0);
      final StaffGrp? staffGrp = originalStaffDef != null
          ? originalStaffDef.parent as StaffGrp?
          : null;
      if (staffGrp != null && staffGrp.barThru == true) {
        currentOssia.ossia.getDrawingStaffGrp().barThru = true;
      }
    }

    currentStaffDef = StaffDef();

    // Check if we had the same ossia staffDef in the previous measure.
    final StaffDef? previousStaffDef =
        _getPreviousStaffDef(currentOssia.ossia, staff.n ?? 0);
    if (previousStaffDef != null) {
      currentStaffDef!.copyFrom(previousStaffDef);
    } else {
      // Otherwise use the one of the original staff.
      currentStaffDef!.copyFrom(originalStaff!.drawingStaffDef as StaffDef);
      currentStaffDef!.n = staff.n;
    }
    upcomingStaffDef = StaffDef()..copyFrom(currentStaffDef!);

    // Takes ownership of the staffDef (add it to the drawing staffGrp).
    currentOssia.ossia.addDrawingStaffDef(currentStaffDef!);

    // True by default for multi staves, false by default for single staff.
    final bool showScoreDef =
        currentOssia.ossia.drawScoreDef() && currentOssia.ossia.isFirst();
    if (showScoreDef) {
      bool hasValues = false;
      final Layer? firstLayer =
          originalStaff!.findDescendantByType(ClassId.layer) as Layer?;
      // Retrieve the drawing values (scoreDef start or change) from the
      // first layer of the original staff (if any).
      if (firstLayer != null) {
        hasValues = firstLayer.getDrawingStaffDefValues(currentStaffDef!);
      }
      // If we don't have values, draw an ossia scoreDef (clef and key
      // signature).
      if (!hasValues) {
        layerOssiaStaffDef = true;
        currentStaffDef!.setDrawClef(true);
        currentStaffDef!.setDrawKeySig(true);
      }
    }

    assert(staff.drawingStaffDef == null);
    staff.drawingStaffDef = currentStaffDef;
    assert(staff.drawingTuning == null);
    staff.drawingTuning = currentStaffDef!.findDescendantByType(ClassId.tuning);
    staff.drawingLines = currentStaffDef!.lines ?? 5;
    staff.drawingNotationtype = currentStaffDef!.notationtype;
    staff.drawingStaffSize = 100;
    if (currentStaffDef!.hasScale) {
      staff.drawingStaffSize = currentStaffDef!.scale!.toInt();
    }
    staff.drawingStaffSize =
        (staff.drawingStaffSize * doc.getOptions().ossiaStaffSize.value)
            .toInt();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaffEnd(Staff staff) {
    if (!staff.isOssia()) return FunctorCode.siblings;

    assert(_currentOssias.isNotEmpty);
    final _CurrentOssia currentOssia = _currentOssias.first;
    currentOssia.staffDefs[staff.n ?? 0] = upcomingStaffDef;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    currentScoreDef = system.drawingScoreDef;
    layerOssiaStaffDef = false;
    isFirstMeasure = true;

    return FunctorCode.continue_;
  }

  /// Retrieve the upcoming staffDef from a previous ossia, if any (mirrors
  /// `GetPreviousStaffDef`).
  StaffDef? _getPreviousStaffDef(Ossia ossia, int staffN) {
    final _CurrentOssia? previous = _findPreviousOssia(ossia.getOStaffNs());
    return previous?.staffDefs[staffN];
  }

  _CurrentOssia? _findPreviousOssia(List<int> oStaffNs) {
    for (final _CurrentOssia previous in _previousOssias) {
      if (_intListEquals(previous.ossia.getOStaffNs(), oStaffNs)) {
        return previous;
      }
    }
    return null;
  }

  /// Mirrors `LayerElement::ThisOrSameasLink` restricted to clefs.
  LayerElement? _thisOrSameasLink(Clef clef) {
    if (clef.hasSameasLink) {
      final Object? link = clef.sameasLink;
      return link is LayerElement ? link : null;
    }
    return clef;
  }
}

/// The ossias currently open (i.e. in the current or previous measure), with
/// their upcoming staffDefs (mirrors `ScoreDefSetOssiaFunctor::CurrentOssia`).
class _CurrentOssia {
  _CurrentOssia(this.ossia);

  final Ossia ossia;

  /// The upcoming staffDef per ossia staff `@n` (mirrors `m_staffDefs`, a
  /// `std::map<int, StaffDef>`).
  final Map<int, StaffDef> staffDefs = {};
}

/// Mirrors `std::vector<int>::operator==` for the `GetOStaffNs()` comparison.
bool _intListEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
