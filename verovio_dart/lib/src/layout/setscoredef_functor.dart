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
///
/// Deviations: `ScoreDefOptimizeFunctor` and `ScoreDefSetOssiaFunctor` are
/// deferred to the optimization / ossia phases; ossia handling inside
/// [ScoreDefSetCurrentFunctor] logs instead of collecting ossia staves.
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/utils.dart' show extractIDFragment;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Notationtype;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/comparison.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show KeySig, Proport;
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

  /// Whether an ossia is present (mirrors `m_hasOssia`); ossia support is
  /// deferred so this stays false for now.
  bool get hasOssia => false;

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
  FunctorCode visitOssia(Object ossia) {
    // Ossia support is deferred (mirrors VisitOssia collecting the ossia
    // staves above/below and setting m_hasOssia).
    logDebug('ScoreDefSetCurrentFunctor: ossia handling is deferred');
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
    // Alternating meter groups are deferred (AddAlternatingMeasureToVector
    // arrives with the rendering phase).

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

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemEnd(System system) {
    // Ossia scoreDef additions are deferred together with the ossia support.
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
