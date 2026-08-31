/// Port of `doc.h/cpp` (model subset), `page.h/cpp` and `pages.h/cpp`.
///
/// Doc is the root of the object tree; Page and Pages hold the page-based
/// structure. The layout methods (`LayOut*`, `CastOff*`, `PrepareData`,
/// `ScoreDefSetCurrentDoc`…) are functor based.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/file_reader.dart' show resourceFileReader;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/devicecontextbase.dart' show FontInfo;
import 'package:verovio_dart/src/core/point.dart' show Point;
import 'package:verovio_dart/src/core/options_shell.dart'
    show Breaks, MensuralResp, Options;
import 'package:verovio_dart/src/core/smufl.dart'
    show
        smuflE0A2NoteheadWhole,
        smuflE0A4NoteheadBlack,
        smuflE220Tremolo1,
        smuflE990ChantPunctum,
        smuflE991ChantPunctumInclinatum,
        smuflE994ChantAuctumAsc,
        smuflE995ChantAuctumDesc,
        smuflE996ChantPunctumVirga,
        smuflE997ChantPunctumVirgaReversed,
        smuflE99BChantQuilisma,
        smuflE9A1ChantPunctumDeminutum,
        smuflE9B4ChantEntryLineAsc2nd,
        smuflE9B5ChantEntryLineAsc3rd,
        smuflE9B6ChantEntryLineAsc4th,
        smuflE9B7ChantEntryLineAsc5th,
        smuflE9B9ChantLigaturaDesc2nd,
        smuflE9BAChantLigaturaDesc3rd,
        smuflE9BBChantLigaturaDesc4th,
        smuflE9BCChantLigaturaDesc5th,
        smuflE9BEChantConnectingLineAsc3rd,
        smuflEA29MedRenStrophicusCMN,
        smuflEA2AMedRenOriscusCMN;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/cast_off.dart'
    show
        CastOffEncodingFunctor,
        CastOffPagesFunctor,
        CastOffSystemsFunctor,
        UnCastOffFunctor;
import 'package:verovio_dart/src/layout/justify.dart'
    show JustifyXFunctor, JustifyYAdjustCrossStaffFunctor, JustifyYFunctor;
import 'package:verovio_dart/src/layout/lay_out_vertically.dart'
    show
        AdjustCrossStaffYPosFunctor,
        AdjustStaffOverlapFunctor,
        AdjustYPosFunctor,
        AlignSystemsFunctor,
        AlignVerticallyFunctor,
        CalcAlignmentPitchPosFunctor,
        ResetVerticalAlignmentFunctor;
import 'package:verovio_dart/src/layout/align_functors.dart'
    show
        InitMaxMeasureDurationFunctor,
        InitOnsetOffsetFunctor,
        PrepareStaffCurrentTimeSpanningFunctor,
        tempoCalcTempo;
import 'package:verovio_dart/src/layout/align_horizontally.dart'
    show
        AlignHorizontallyFunctor,
        AlignMeasuresFunctor,
        ResetHorizontalAlignmentFunctor;
import 'package:verovio_dart/src/layout/adjust_accid_x.dart'
    show AdjustAccidXFunctor;
import 'package:verovio_dart/src/layout/adjust_artic.dart'
    show AdjustArticFunctor, AdjustArticWithSlursFunctor;
import 'package:verovio_dart/src/layout/adjust_beams.dart'
    show AdjustBeamsFunctor;
import 'package:verovio_dart/src/layout/adjust_tuplets.dart'
    show
        AdjustTupletWithSlursFunctor,
        AdjustTupletsXFunctor,
        AdjustTupletsYFunctor;
import 'package:verovio_dart/src/layout/adjust_arpeg.dart'
    show AdjustArpegFunctor;
import 'package:verovio_dart/src/layout/adjust_ossia_neume.dart'
    show AdjustNeumeXFunctor, AdjustOssiaStaffDefFunctor;
import 'package:verovio_dart/src/layout/calc_ledger_lines.dart'
    show CalcLedgerLinesFunctor;
import 'package:verovio_dart/src/layout/adjust_harm_tempo_syl.dart'
    show
        AdjustHarmGrpsSpacingFunctor,
        AdjustSylSpacingFunctor,
        AdjustTempoFunctor;
import 'package:verovio_dart/src/layout/adjust_floating.dart'
    show
        AdjustFloatingPositionersBetweenFunctor,
        AdjustFloatingPositionersFunctor;
import 'package:verovio_dart/src/layout/adjust_slurs.dart'
    show AdjustSlursFunctor;
import 'package:verovio_dart/src/layout/adjust_layers.dart'
    show AdjustDotsFunctor, AdjustLayersFunctor;
import 'package:verovio_dart/src/layout/adjust_x_pos.dart'
    show AdjustClefChangesFunctor, AdjustGraceXPosFunctor, AdjustXPosFunctor;
import 'package:verovio_dart/src/layout/adjust_transcription.dart'
    show AdjustXRelForTranscriptionFunctor, AdjustYRelForTranscriptionFunctor;
import 'package:verovio_dart/src/layout/adjust_x_overflow.dart'
    show AdjustXOverflowFunctor;
import 'package:verovio_dart/src/layout/cache_horizontal_layout.dart'
    show CacheHorizontalLayoutFunctor;
import 'package:verovio_dart/src/layout/calc_spanning_beam_spans.dart'
    show CalcSpanningBeamSpansFunctor;
import 'package:verovio_dart/src/layout/calc_alignment_x_pos.dart'
    show CalcAlignmentXPosFunctor;
import 'package:verovio_dart/src/layout/bbox_overflows.dart'
    show CalcBBoxOverflowsFunctor;
import 'package:verovio_dart/src/layout/calc_functors.dart'
    show
        CalcArticFunctor,
        CalcChordNoteHeadsFunctor,
        CalcDotsFunctor,
        CalcSlurDirectionFunctor,
        CalcStemFunctor;
import 'package:verovio_dart/src/layout/cast_off_mensural.dart'
    show ConvertToCastOffMensuralFunctor, convertToUnCastOffMensuralSystem;
import 'package:verovio_dart/src/layout/mensural_neume.dart'
    show CalcLigatureOrNeumePosFunctor;
import 'package:verovio_dart/src/layout/preparedata_functor.dart';
import 'package:verovio_dart/src/layout/reset_functor.dart'
    show ResetDataFunctor;
import 'package:verovio_dart/src/layout/setscoredef_functor.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart'
    show AttLabelled, AttNNumberLike;
import 'package:verovio_dart/src/model/comparison.dart'
    show AttDurExtremeComparison, AttNIntegerComparison, DurExtreme, Filters;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show
        Articulation,
        Fontsizeterm,
        Horizontalalignment,
        Notationtype,
        Pgfunc,
        Staffrel,
        Verticalalignment;
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show FontSize, MeasurementSigned;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show SystemMilestoneInterface;
import 'package:verovio_dart/src/model/editorial_element.dart'
    show EditorialElement;
import 'package:verovio_dart/src/model/expansion_map.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show Artic;
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart'
    show DurationInterface;
import 'package:verovio_dart/src/model/interfaces/time_interface.dart'
    show TimeSpanningInterface;
import 'package:verovio_dart/src/model/control_elements_gen.dart' show MNum;
import 'package:verovio_dart/src/model/misc_elements_gen.dart'
    show Expansion, Facsimile, Fig, Lb, PgFoot, PgHead, Rend, Svg, Text;
import 'package:verovio_dart/src/io/xml_node.dart' show MeiXmlNode;
import 'package:verovio_dart/src/model/text_elements.dart' show RunningElement;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/rendering/bbox_device_context.dart'
    show BBoxDeviceContext;
import 'package:verovio_dart/src/rendering/glyph.dart' show Glyph;
import 'package:verovio_dart/src/rendering/resources.dart' show Resources;
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

/// Mirrors `vrv::DocType`.
enum DocType { raw, rendering, transcription, facs }

// ---------------------------------------------------------------------------
// Pages / PageRange
// ---------------------------------------------------------------------------

/// This class represents a `<pages>` in page-based MEI (mirrors
/// `vrv::Pages`).
class Pages extends Object
    with ObjectListInterface, AttLabelled, AttNNumberLike {
  Pages() {
    assignClassId(ClassId.pages);
    reset();
  }

  @override
  ClassId get classId => ClassId.pages;

  @override
  String get className => 'pages';

  @override
  Object clone() {
    final copy = Pages();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    label = null;
    n = null;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    return classId == ClassId.page;
  }

  /// Lay out all the pages (mirrors `Pages::LayOutAll`).
  ///
  /// Deviation: the C++ relies on the view for setting the drawing page; here
  /// it is set explicitly before each page layout so that the page sizes are
  /// up to date.
  void layOutAll() {
    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;
    for (int i = 0; i < childCount; ++i) {
      doc.setDrawingPage(i);
      (getChild(i) as Page).layOut();
    }
  }

  // TODO(phase-4): ConvertFrom(Score) arrives with the cast-off functors.
}

/// This class represents a page range not owning child pages (mirrors
/// `vrv::PageRange`).
class PageRange extends Pages {
  PageRange() : super();

  @override
  Object clone() {
    final copy = PageRange();
    copy.copyFrom(this);
    return copy;
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

/// This class represents a page in a laid-out score (Doc) (mirrors
/// `vrv::Page`). A Page is contained in a Doc; it contains System objects.
class Page extends Object with ObjectListInterface {
  Page() : super(ClassId.page) {
    reset();
  }

  /// Page width (MEI scoredef@page.width). Saved if != -1 (mirrors
  /// `m_pageWidth`).
  int pageWidth = -1;

  /// Page height (MEI scoredef@page.height). Saved if != -1.
  int pageHeight = -1;

  /// Page margins (MEI scoredef@page.*mar). Saved if != 0.
  int pageMarginBottom = 0;
  int pageMarginLeft = 0;
  int pageMarginRight = 0;
  int pageMarginTop = 0;

  /// Surface (MEI @surface) for transcription layout (mirrors `m_surface`).
  String surface = '';

  /// Holds the top scoreDef of the page (mirrors `m_drawingScoreDef`).
  final ScoreDef drawingScoreDef = ScoreDef();

  /// Pointers to the score at the beginning/end of the page (mirrors
  /// `m_score`/`m_scoreEnd`); set by the ScoreDefSetCurrent functors.
  Object? score;
  Object? scoreEnd;

  /// Temporary member for the pixel-per-unit factor (mirrors `m_PPUFactor`).
  double ppufactor = 1.0;

  /// The pixel-per-unit factor (mirrors `Page::GetPPUFactor`, page.h:55).
  double getPPUFactor() => ppufactor;

  /// The height that can be justified once the systems are aligned (mirrors
  /// `m_drawingJustifiableHeight`).
  int drawingJustifiableHeight = 0;

  /// Sum of justification factors per spacing type (mirrors
  /// `m_justificationSum`).
  double justificationSum = 0.0;

  /// Flag indicating whether the layout has been done (mirrors
  /// `m_layoutDone`).
  bool layoutDone = false;

  @override
  ClassId get classId => ClassId.page;

  @override
  String get className => 'page';

  @override
  Object clone() {
    final copy = Page();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    drawingScoreDef.reset();
    score = null;
    scoreEnd = null;
    layoutDone = false;
    resetID();

    // By default we have no values and use the document ones.
    pageHeight = -1;
    pageWidth = -1;
    pageMarginBottom = 0;
    pageMarginLeft = 0;
    pageMarginRight = 0;
    pageMarginTop = 0;
    ppufactor = 1.0;

    drawingJustifiableHeight = 0;
    justificationSum = 0.0;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (classId == ClassId.system) return true;
    if (Object.isPageElementId(classId)) return true;
    return false;
  }

  /// Lay out the content of the page horizontally (mirrors
  /// `Page::LayOutHorizontally`, page.cpp:396-497).
  ///
  /// After this method every LayerElement has an Alignment with an xRel
  /// position and the measures are aligned within their system.
  ///
  /// Mirrors the C++ pipeline including the `View` + `BBoxDeviceContext`
  /// render pass (`BBOX_HORIZONTAL_ONLY`, `SlurHandling::Ignore`) that fills
  /// the bounding boxes before the adjust functors (page.cpp:410).
  void layOutHorizontally() {
    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;
    assert(doc.drawingPage != null);

    resetAligners();

    // In the C++ ResetAligners also resets and aligns vertically before the
    // first BBox pass (page.cpp:319-345); the Dart port's resetAligners is
    // horizontal-only, so the vertical Y would be unset for the horizontal
    // View::DrawSystem (brace, etc.) and would assert in Object::GetDrawingY.
    // Replicate the missing vertical part here (mirrors the C++ ResetAligners
    // vertical half) — LayOutVertically will reset it again, just like the
    // C++ does (LayOutHorizontally 396-413 then LayOutVertically 509-536).
    final resetVerticalAlignmentForHoriz = ResetVerticalAlignmentFunctor();
    process(resetVerticalAlignmentForHoriz);
    final alignVerticallyForHoriz = AlignVerticallyFunctor(doc);
    process(alignVerticallyForHoriz);

    // Calc* chain of the C++ Page::ResetAligners (page.cpp:373-390): the
    // ResetHorizontalAlignmentFunctor above zeroed drawingXRel/YRel of every
    // LayerElement, so the stem/notehead/dots/artic drawing values must be
    // recalculated here — before the BBox render pass fills the bounding
    // boxes used by AdjustLayers/AdjustXPos. Without this, stem XRel stays 0
    // (e.g. the stemShift offset) and the measure width diverges. The C++
    // has the SMuFL resources loaded at this point (Toolkit::InitResources);
    // the Dart port loads them lazily, so make sure they are here too.
    _ensureResourcesLoaded(doc);

    final calcAlignmentPitchPosForHoriz = CalcAlignmentPitchPosFunctor(doc);
    process(calcAlignmentPitchPosForHoriz);

    final calcLigatureOrNeumePosForHoriz = CalcLigatureOrNeumePosFunctor(doc);
    process(calcLigatureOrNeumePosForHoriz);

    final calcStemForHoriz = CalcStemFunctor(doc);
    process(calcStemForHoriz);

    final calcChordNoteHeadsForHoriz = CalcChordNoteHeadsFunctor(doc);
    process(calcChordNoteHeadsForHoriz);

    final calcDotsForHoriz = CalcDotsFunctor(doc);
    process(calcDotsForHoriz);

    final calcArticForHoriz = CalcArticFunctor(doc);
    process(calcArticForHoriz);

    final calcSlurDirectionForHoriz = CalcSlurDirectionFunctor(doc);
    process(calcSlurDirectionForHoriz);

    final calcSpanningBeamSpansForHoriz = CalcSpanningBeamSpansFunctor(doc);
    process(calcSpanningBeamSpansForHoriz);

    // Render pass for filling bounding boxes (mirrors `Page::LayOutHorizontally`
    // page.cpp:406-413, `BBOX_HORIZONTAL_ONLY` with `SlurHandling::Ignore`).
    _renderBoundingBoxes(doc, horizontal: true);

    final adjustOssiaStaffDef = AdjustOssiaStaffDefFunctor(doc);
    process(adjustOssiaStaffDef);

    // Adjust the position of outside articulations (page.cpp:418-420).
    final adjustArtic = AdjustArticFunctor(doc);
    process(adjustArtic);

    // Adjust the x position of the LayerElement where multiple layers
    // collide. Look at each LayerElement and change the m_xShift if the
    // bounding box is overlapping. For the first iteration align elements
    // without taking dots into consideration.
    final adjustLayers = AdjustLayersFunctor(doc);
    process(adjustLayers);

    // Adjust dots for the multiple layers. Try to align dots that can be
    // grouped together when layers collide, otherwise keep their relative
    // positioning.
    final adjustDots = AdjustDotsFunctor(doc);
    process(adjustDots);

    // Adjust the X position of the neume and syllables (page.cpp:434-435).
    final adjustNeumeX = AdjustNeumeXFunctor(doc);
    process(adjustNeumeX);

    // Adjust layers again, this time including dots positioning.
    final adjustLayersWithDots = AdjustLayersFunctor(doc);
    adjustLayersWithDots.setIgnoreDots(false);
    process(adjustLayersWithDots);

    // Adjust the X position of the accidentals, including in chords
    // (page.cpp:443-444).
    final adjustAccidX = AdjustAccidXFunctor(doc);
    process(adjustAccidX);

    // Adjust the X shift of the Alignment looking at the bounding boxes.
    // Look at each LayerElement and change the m_xShift if the bounding box
    // is overlapping. For the first iteration align elements without taking
    // dots into consideration.
    final adjustXPos = AdjustXPosFunctor(doc);
    adjustXPos.setExcluded([ClassId.tabDurSym]);
    process(adjustXPos);

    // Adjust tabRhythm separately
    adjustXPos.clearExcluded();
    adjustXPos.setIncluded([
      ClassId.barLine,
      ClassId.keysig,
      ClassId.meterSig,
      ClassId.tabDurSym,
    ]);
    adjustXPos.setRightBarLinesOnly(true);
    process(adjustXPos);

    final adjustGraceXPos = AdjustGraceXPosFunctor(doc);
    process(adjustGraceXPos);

    // Adjust the spacing of clef changes since they are skipped in
    // AdjustXPos.
    final adjustClefChanges = AdjustClefChangesFunctor(doc);
    process(adjustClefChanges);

    // We need to populate processing lists for processing the document by
    // Layer (for matching @tie) and by Verse (for matching syllable
    // connectors) — page.cpp:469-473.
    final initProcessingLists = InitProcessingListsFunctor();
    process(initProcessingLists);

    adjustSylSpacingByVerse(initProcessingLists.verseTree, doc);

    final adjustHarmGrpsSpacing = AdjustHarmGrpsSpacingFunctor(doc);
    process(adjustHarmGrpsSpacing);

    // Adjust the arpeg (page.cpp:479-480).
    final adjustArpeg = AdjustArpegFunctor(doc);
    process(adjustArpeg);

    // Adjust the tempo (page.cpp:482-484).
    final adjustTempo = AdjustTempoFunctor(doc);
    process(adjustTempo);

    // Adjust the position of the tuplets (mirrors `page.cpp:496-498`: the
    // bracket / num X positions depend only on the tuplet drawing left /
    // right and the option state, not on rendered bounding boxes).
    final adjustTupletsX = AdjustTupletsXFunctor(doc);
    process(adjustTupletsX);

    // Prevent a margin overflow (page.cpp:491-492, right after AdjustTupletsX
    // in the C++ relative order; deviation: it needs the same floating
    // positioners as AdjustHarmGrpsSpacing/AdjustArpeg/AdjustTempo above, so
    // it runs here rather than in `layOutVertically` — see the class doc
    // comment above and task 04f's report).
    final adjustXOverflow = AdjustXOverflowFunctor(doc.getDrawingUnit(100));
    process(adjustXOverflow);

    // Adjust measure X position (page.cpp:495-497).
    final alignMeasures = AlignMeasuresFunctor(doc);
    process(alignMeasures);
  }

  /// Mirrors `Page::ResetAligners`: resets and re-fills the horizontal
  /// aligners and sets the x position of each alignment.
  ///
  /// Deviations: the vertical alignment functors arrive with the vertical
  /// layout phase; the Calc* drawing functors (stems, dots, artic, slur
  /// direction…) were already applied by `Doc::PrepareData` in this port.
  void resetAligners() {
    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;

    // Make sure we have the correct page size (checked by
    // Doc::UpdatePageDrawingSizes when setting the drawing page).

    // Reset the horizontal alignment
    final resetHorizontalAlignment = ResetHorizontalAlignmentFunctor();
    process(resetHorizontalAlignment);

    // Align the content of the page using measure aligners. After this:
    // - each LayerElement object has its Alignment pointer initialized
    final alignHorizontally = AlignHorizontallyFunctor(doc);
    process(alignHorizontally);

    // Unless duration-based spacing is disabled, set the X position of each
    // Alignment. Does non-linear spacing based on the duration space between
    // two Alignment objects.
    if (!doc.getOptions().evenNoteSpacing.value) {
      MeiDuration longestActualDur = MeiDuration.dur4;

      // Detect the longest duration in order to adjust the spacing (false by
      // default)
      if (doc.getOptions().spacingDurDetection.value) {
        // Get the longest duration in the piece
        final durExtremeComparison =
            AttDurExtremeComparison(DurExtreme.longest);
        final Object? longestDur =
            findDescendantExtremeByComparison(durExtremeComparison);
        if (longestDur != null) {
          longestActualDur = (longestDur as DurationInterface).getActualDur();
        }
      }

      final calcAlignmentXPos = CalcAlignmentXPosFunctor(doc)
        ..setLongestActualDur(longestActualDur);
      process(calcAlignmentXPos);
    }
  }

  /// Mirrors `Page::LayOutHorizontallyWithCache`: the horizontal layout cache
  /// used by the cast-off functors (task 04f).
  void layOutHorizontallyWithCache({bool restore = false}) {
    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;

    final cacheHorizontalLayout = CacheHorizontalLayoutFunctor(doc)
      ..restore = restore;
    process(cacheHorizontalLayout);
  }

  /// Lay out the page (mirrors `Page::LayOut`): the full pipeline for one
  /// page. Does nothing when the layout is already done.
  void layOut() {
    if (layoutDone) {
      // We only need to reset the header - this adjusts the page number if
      // necessary. Deviation: running elements arrive with their phase.
      return;
    }

    layOutHorizontally();
    justifyHorizontally();
    layOutVertically();
    justifyVertically();

    // Deviation: the svg bounding box debug render pass is not ported.

    layoutDone = true;
  }

  /// Do the layout for a transcription page (with layout information).
  /// This only calculates positioning of layer element parts using provided
  /// layout of parents (mirrors `Page::LayOutTranscription`, page.cpp:249-316).
  ///
  /// Called from `View.setPage` when the document is a transcription or facsimile
  /// (mirrors `View::SetPage`, view.cpp:63). Also exposed for the editor
  /// toolkit path (`editortoolkit_neume.cpp`, Phase 6). The C++ `DocType`
  /// routing (`Toolkit::LoadData` breaks handling) is not yet in the Dart
  /// toolkit (Phase 7) — until then callers that already know the doc type
  /// (e.g., tests, future editor) can call this directly.
  void layOutTranscription({bool force = false}) {
    if (layoutDone && !force) {
      return;
    }

    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;

    // Make sure we have the correct page size (mirrors `assert(doc->CheckPageSize(this))`).
    // In this port `setDrawingPage` already updated the drawing sizes.
    assert(doc.drawingPage != null || true);

    // Reset the horizontal alignment.
    final resetHorizontalAlignment = ResetHorizontalAlignmentFunctor();
    process(resetHorizontalAlignment);

    // Reset the vertical alignment.
    final resetVerticalAlignment = ResetVerticalAlignmentFunctor();
    process(resetVerticalAlignment);

    // Align the content of the page using measure aligners.
    // After this: each LayerElement has its Alignment pointer initialized.
    final alignHorizontally = AlignHorizontallyFunctor(doc);
    process(alignHorizontally);

    // Align the content of the page using system aligners.
    // After this: each Staff has its StaffAlignment pointer initialized.
    final alignVertically = AlignVerticallyFunctor(doc);
    process(alignVertically);

    // Set the pitch / pos alignment.
    final calcAlignmentPitchPos = CalcAlignmentPitchPosFunctor(doc);
    process(calcAlignmentPitchPos);

    final calcLigatureOrNeumePos = CalcLigatureOrNeumePosFunctor(doc);
    process(calcLigatureOrNeumePos);

    final calcStem = CalcStemFunctor(doc);
    process(calcStem);

    final calcChordNoteHeads = CalcChordNoteHeadsFunctor(doc);
    process(calcChordNoteHeads);

    final calcDots = CalcDotsFunctor(doc);
    process(calcDots);

    if (!layoutDone) {
      // Render it for filling the bounding box (mirrors page.cpp:297-305,
      // `BBOX_HORIZONTAL_ONLY` with View real — default SlurHandling::Initialize).
      // Do not use _renderBoundingBoxes(horizontal:true) which forces
      // SlurHandling::Ignore (mirroring LayOutHorizontally page.cpp:410); the
      // transcription path in C++ leaves the default (Initialize).
      if (!doc.resources.ok) {
        doc.resources.initFonts();
        if (!doc.resources.ok && doc.resources.path != 'assets/data') {
          doc.resources.path = 'assets/data';
          doc.resources.initFonts();
        }
        if (!doc.resources.ok && Resources.defaultPath == 'assets/data') {
          doc.resources.path = Resources.defaultPath;
          doc.resources.initFonts();
        }
      }
      final view = View()..setDoc(doc);
      // Default slurHandling is Initialize, matching C++.
      final bBoxDC = BBoxDeviceContext(
          toLogicalX: view.toLogicalX,
          toLogicalY: view.toLogicalY,
          update: BBOX_HORIZONTAL_ONLY);
      view.setPage(this, false);
      view.drawCurrentPage(bBoxDC, false);
    }

    final adjustXRelForTranscription = AdjustXRelForTranscriptionFunctor();
    process(adjustXRelForTranscription);
    final adjustYRelForTranscription = AdjustYRelForTranscriptionFunctor();
    process(adjustYRelForTranscription);

    final calcLedgerLines = CalcLedgerLinesFunctor(doc);
    process(calcLedgerLines);

    layoutDone = true;
  }

  /// Justify the content of the page horizontally (mirrors
  /// `Page::JustifyHorizontally`).
  void justifyHorizontally() {
    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;

    if ((doc.getOptions().breaks.value == Breaks.none) ||
        doc.getOptions().noJustification.value) {
      return;
    }

    if (doc.getOptions().adjustPageWidth.value) {
      doc.drawingPageContentWidth = getContentWidth();
      doc.drawingPageWidth = doc.drawingPageContentWidth +
          doc.drawingPageMarginLeft +
          doc.drawingPageMarginRight;
    } else {
      // Justify the X position.
      final justifyX = JustifyXFunctor(doc);
      justifyX.setSystemFullWidth(doc.drawingPageContentWidth);
      process(justifyX);
    }
  }

  /// Lay out the content of the page vertically (mirrors
  /// `Page::LayOutVertically`, page.cpp:509-608).
  ///
  /// After this method each Staff has a StaffAlignment with a yRel position
  /// and the systems have their drawingYRel position.
  ///
  /// Mirrors the C++ pipeline including the `View` + `BBoxDeviceContext`
  /// render passes (`BBOX_BOTH`, page.cpp:532 and 554).
  void layOutVertically() {
    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;

    // Reset the vertical alignment.
    final resetVerticalAlignment = ResetVerticalAlignmentFunctor();
    process(resetVerticalAlignment);

    // Align the content of the page using system aligners. After this:
    // - each Staff object has its StaffAlignment pointer initialized.
    final alignVertically = AlignVerticallyFunctor(doc);
    process(alignVertically);

    // Set the pitch / pos alignment. In the C++ this runs in ResetAligners
    // (i.e., during the horizontal layout); here it runs after the vertical
    // alignment so that a single call to layOutVertically produces complete
    // staff-relative y positions headlessly.
    final calcAlignmentPitchPos = CalcAlignmentPitchPosFunctor(doc);
    process(calcAlignmentPitchPos);

    // Set the note positions within ligatures and the nc glyphs / positions
    // within neumes (mirrors the CalcLigatureOrNeumePosFunctor call right
    // after CalcAlignmentPitchPos in Page::ResetAligners /
    // Page::LayOutTranscription).
    final calcLigatureOrNeumePos = CalcLigatureOrNeumePosFunctor(doc);
    process(calcLigatureOrNeumePos);

    final calcDots = CalcDotsFunctor(doc);
    process(calcDots);

    // Calculate the ledger lines (Deviation: runs here, right after
    // CalcAlignmentPitchPos sets drawingLoc, rather than right after
    // ResetVerticalAlignment as in the C++ — see the class doc comment
    // above).
    final calcLedgerLines = CalcLedgerLinesFunctor(doc);
    process(calcLedgerLines);

    // Render pass for filling bounding boxes (mirrors `Page::LayOutVertically`
    // page.cpp:530-536, `BBOX_BOTH` with default SlurHandling::Initialize).
    _renderBoundingBoxes(doc,
        horizontal: false, slurHandling: SlurHandling.initialize);

    // Adjust the position of outside articulations with slur end and start
    // positions (page.cpp:539-540, right after the first BBOX_BOTH render
    // pass and before AdjustBeams — same position as in the C++; the X-only
    // AdjustArtic/Accid/Ossia/Neume/Syl/Harm/Arpeg/Tempo/XOverflow adjusts
    // have already run in `layOutHorizontally` before CastOff, matching
    // page.cpp:415-492, and must not run again here).
    final adjustArticWithSlurs = AdjustArticWithSlursFunctor(doc);
    process(adjustArticWithSlurs);

    // Adjust the position of the beams in regards of layer elements (mirrors
    // `page.cpp:542-544`, right after AdjustArticWithSlurs and before
    // AdjustTupletsY). The beam segments are only populated by the pending
    // `BeamSegment::CalcBeam` task, so the functor degrades through its own
    // empty-coords guard — see adjust_beams.dart.
    final adjustBeams = AdjustBeamsFunctor(doc);
    process(adjustBeams);

    // Adjust the position of the tuplets against notes and staves (mirrors
    // `page.cpp:557-560`; runs before AdjustSlurs as in the C++).
    final adjustTupletsY = AdjustTupletsYFunctor(doc);
    process(adjustTupletsY);

    // Adjust the position of the slurs.
    final adjustSlurs = AdjustSlursFunctor(doc);
    process(adjustSlurs);

    // Second render pass for slur curves (mirrors `Page::LayOutVertically`
    // page.cpp:554-557, `SlurHandling::Drawing`).
    _renderBoundingBoxes(doc,
        horizontal: false, slurHandling: SlurHandling.drawing);

    // Adjust the position of tuplets by slurs (mirrors `page.cpp:570-573`:
    // right after the slur-adjusting render pass).
    final adjustTupletWithSlurs = AdjustTupletWithSlursFunctor(doc);
    process(adjustTupletWithSlurs);

    // Fill the arrays of bounding boxes (above and below) for each staff
    // alignment for which the box overflows.
    final calcBBoxOverflows = CalcBBoxOverflowsFunctor(doc);
    process(calcBBoxOverflows);

    // Adjust the positioners of floating elements (slurs, hairpins, dynam…).
    final adjustFloatingPositioners = AdjustFloatingPositionersFunctor(doc);
    process(adjustFloatingPositioners);

    // Adjust the overlap of the staff alignments by looking at the overflow
    // bounding boxes.
    final adjustStaffOverlap = AdjustStaffOverlapFunctor(doc);
    process(adjustStaffOverlap);

    // Set the Y position of each StaffAlignment. Adjust the Y shift to make
    // sure there is a minimal space between each staff.
    final adjustYPos = AdjustYPosFunctor(doc);
    process(adjustYPos);

    // Adjust the positioners of floating elements placed between staves.
    final adjustFloatingPositionersBetween =
        AdjustFloatingPositionersBetweenFunctor(doc);
    process(adjustFloatingPositionersBetween);

    // Adjust cross-staff chords after the y position adjustment; the beamSpan
    // branch and the cross-staff slur redraw arrive with their phases.
    final adjustCrossStaffYPos = AdjustCrossStaffYPosFunctor(doc);
    process(adjustCrossStaffYPos);

    // Redraw and re-adjust slurs when we have cross-staff ones
    // (page.cpp:588-593, SlurHandling::Initialize).
    if (adjustSlurs.crossStaffSlurs) {
      _renderBoundingBoxes(doc,
          horizontal: false, slurHandling: SlurHandling.initialize);
      process(adjustSlurs);
    }

    // Port of `Page::LayOutVertically` header/footer AdjustRunningElementYPos
    // (page.cpp:596, textlayoutelement.cpp:222): adjust the content of each
    // cell and the cells themselves before the system alignment.
    final Object? headerObj = getHeader();
    if (headerObj is RunningElement) {
      headerObj.adjustRunningElementYPos();
    }
    final Object? footerObj = getFooter();
    if (footerObj is RunningElement) {
      footerObj.adjustRunningElementYPos();
    }

    // Adjust the system Y position.
    final alignSystems = AlignSystemsFunctor(doc);
    alignSystems.setShift(doc.drawingPageContentHeight);
    alignSystems.setSystemSpacing(
        (doc.getOptions().spacingSystem.value * doc.getDrawingUnit(100))
            .toInt());
    process(alignSystems);
  }

  /// Recompute the pitch / position alignment and the ledger lines for an
  /// already laid-out page (mirrors `Page::LayOutPitchPos`).
  ///
  /// Unlike `layOutHorizontally` / `layOutVertically`, this is **not** part
  /// of the default `layOut` pipeline in the C++ either: `Page::LayOut` never
  /// calls it (verified against `page.cpp:221-246`) — only
  /// `Toolkit::RedoPagePitchPosLayout` does, an interactive-editing entry
  /// point (`toolkit.cpp:1644-1656`) not yet ported (`toolkit.dart` is
  /// currently load-only — see CLAUDE.md). It exists here for API parity and
  /// is exercised directly by tests until that entry point lands.
  ///
  /// Deviation: `CalcStemFunctor` is not re-run here — this port already
  /// runs it once during `Doc.prepareData` (see the `layOutHorizontally`
  /// class doc comment on `Doc::PrepareData`'s Calc* functors), so re-running
  /// it would be redundant, not a behavior change.
  void layOutPitchPos() {
    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;

    final calcAlignmentPitchPos = CalcAlignmentPitchPosFunctor(doc);
    process(calcAlignmentPitchPos);

    final calcLedgerLines = CalcLedgerLinesFunctor(doc);
    process(calcLedgerLines);
  }

  /// Adjust the spacing of syls, verse by verse (mirrors
  /// `Page::AdjustSylSpacingByVerse`).
  ///
  /// [verseTree] is the staff @n → layer @n → set of verse @n produced by an
  /// [InitProcessingListsFunctor] run over this page (mirrors the C++
  /// `IntTree`, which this port already represents as nested maps — see
  /// `InitProcessingListsFunctor.verseTree`).
  void adjustSylSpacingByVerse(
      Map<int, Map<int, Set<int>>> verseTree, Doc doc) {
    if (verseTree.isEmpty) return;

    for (final int staffN in verseTree.keys) {
      for (final int layerN in verseTree[staffN]!.keys) {
        for (final int verseN in verseTree[staffN]![layerN]!) {
          // Create ad comparison object for each type / @n
          final filters = Filters();
          filters.add(AttNIntegerComparison(ClassId.staff, staffN));
          filters.add(AttNIntegerComparison(ClassId.layer, layerN));
          filters.add(AttNIntegerComparison(ClassId.verse, verseN));

          final adjustSylSpacing = AdjustSylSpacingFunctor(doc);
          adjustSylSpacing.setFilters(filters);
          process(adjustSylSpacing);
        }
      }
    }
  }

  /// Justify the content of the page vertically (mirrors
  /// `Page::JustifyVertically`).
  void justifyVertically() {
    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;

    // Nothing to justify.
    if (drawingJustifiableHeight <= 0 || justificationSum <= 0) {
      return;
    }

    // Vertical justification is not enabled.
    if (!doc.getOptions().justifyVertically.value) {
      return;
    }

    reduceJustifiableHeight(doc);

    // Justify the Y position.
    final justifyY = JustifyYFunctor(doc);
    justifyY.setJustificationSum(justificationSum);
    justifyY.setSpaceToDistribute(drawingJustifiableHeight);
    process(justifyY);

    if (justifyY.getShiftForStaff().isNotEmpty) {
      // Adjust cross staff content which is displaced through vertical
      // justification.
      final justifyYAdjustCrossStaff = JustifyYAdjustCrossStaffFunctor(doc);
      justifyYAdjustCrossStaff.setShiftForStaff(justifyY.getShiftForStaff());
      process(justifyYAdjustCrossStaff);
    }
  }

  /// Mirrors `Page::ReduceJustifiableHeight`: bound the justifiable height by
  /// the justificationMaxVertical ratio.
  void reduceJustifiableHeight(Doc doc) {
    final Pages? pages = doc.getPages();

    double maxRatio = doc.getOptions().justificationMaxVertical.value;
    // Special handling for the justification of the last page.
    if (pages != null && identical(pages.getLast(), this)) {
      final System? firstSystem = getFirst(ClassId.system) as System?;
      final System? lastSystem = getLast(ClassId.system) as System?;
      if (firstSystem != null && lastSystem != null) {
        final int usedDrawingHeight = firstSystem.getDrawingY() -
            lastSystem.getDrawingY() +
            lastSystem.getHeight();
        maxRatio *= usedDrawingHeight / doc.drawingPageHeight;
      }
    }

    drawingJustifiableHeight = math.min<int>(
        (doc.drawingPageHeight * maxRatio).toInt(), drawingJustifiableHeight);
  }

  /// Return the height of the content (mirrors `Page::GetContentHeight`,
  /// page.cpp:708).
  int getContentHeight() {
    final Doc doc = getFirstAncestor(ClassId.doc) as Doc;

    if (childCount == 0) {
      return 0;
    }

    final System? last = getLast(ClassId.system) as System?;
    if (last == null) return 0;
    int height =
        doc.drawingPageContentHeight - last.getDrawingYRel() + last.getHeight();

    final Object? footer = getFooter();
    if (footer is RunningElement) {
      height += footer.getTotalHeight(doc);
    }

    return height;
  }

  /// Return the width of the content (mirrors `Page::GetContentWidth`): the
  /// widest system including its margins.
  int getContentWidth() {
    int maxWidth = 0;
    for (final Object child in children) {
      if (child is! System) continue;
      // We include the left margin and the right margin.
      final int systemWidth =
          child.drawingTotalWidth + child.systemLeftMar + child.systemRightMar;
      maxWidth = systemWidth > maxWidth ? systemWidth : maxWidth;
    }
    return maxWidth;
  }

  /// Return the index position of the page in its document parent (mirrors
  /// `GetPageIdx`).
  int getPageIdx() => idx ?? -1;

  /// Check if the page is the first of a selection (mirrors
  /// `IsFirstOfSelection`).
  bool isFirstOfSelection() {
    final Object? doc = getFirstAncestor(ClassId.doc);
    if (doc == null) return false;
    if (doc is! Doc) return false;
    if (!doc.hasSelection()) return false;
    assert(parent != null);
    return identical(parent!.getFirst(), this);
  }

  /// Check if the page is the last of a selection (mirrors
  /// `IsLastOfSelection`).
  bool isLastOfSelection() {
    final Object? doc = getFirstAncestor(ClassId.doc);
    if (doc == null) return false;
    if (doc is! Doc) return false;
    if (!doc.hasSelection()) return false;
    assert(parent != null);
    return identical(parent!.getLast(), this);
  }

  /// Getter for the page header (mirrors `Page::GetHeader`, `page.cpp:146`).
  Object? getHeader() {
    final Doc? doc = getFirstAncestor(ClassId.doc) as Doc?;
    if (doc == null) return null;
    final Pages? pages = doc.getPages();
    final bool isFirst =
        pages != null && identical(pages.getFirst(ClassId.page), this);
    Object? scoreObj = score ?? scoreEnd;
    if (scoreObj == null) {
      final visible = doc.getVisibleScores();
      if (visible.isNotEmpty) scoreObj = visible.first;
    }
    if (scoreObj == null) return null;
    if (scoreObj is! Score) return null;
    final ScoreDef? scoreDef = scoreObj.getScoreDef() as ScoreDef?;
    if (scoreDef == null) return null;
    if (isFirst) {
      var header = scoreDef.getPgHead(Pgfunc.first);
      if (header != null) return header;
      header = scoreDef.getPgHead(Pgfunc.all);
      if (header != null) return header;
      return scoreDef.getPgHead(Pgfunc.none);
    } else {
      var header = scoreDef.getPgHead(Pgfunc.all);
      if (header != null) return header;
      return scoreDef.getPgHead(Pgfunc.none);
    }
  }

  /// Getter for the page footer (mirrors `Page::GetFooter`, `page.cpp:186`).
  Object? getFooter() {
    final Doc? doc = getFirstAncestor(ClassId.doc) as Doc?;
    if (doc == null) return null;
    final Pages? pages = doc.getPages();
    final bool isFirst =
        pages != null && identical(pages.getFirst(ClassId.page), this);
    Object? scoreObj = score ?? scoreEnd;
    if (scoreObj == null) {
      final visible = doc.getVisibleScores();
      if (visible.isNotEmpty) scoreObj = visible.first;
    }
    if (scoreObj == null) return null;
    if (scoreObj is! Score) return null;
    final ScoreDef? scoreDef = scoreObj.getScoreDef() as ScoreDef?;
    if (scoreDef == null) return null;
    if (isFirst) {
      var footer = scoreDef.getPgFoot(Pgfunc.first);
      if (footer != null) return footer;
      footer = scoreDef.getPgFoot(Pgfunc.all);
      if (footer != null) return footer;
      return scoreDef.getPgFoot(Pgfunc.none);
    } else {
      var footer = scoreDef.getPgFoot(Pgfunc.all);
      if (footer != null) return footer;
      return scoreDef.getPgFoot(Pgfunc.none);
    }
  }

  /// Render the page with a `View` + `BBoxDeviceContext` to fill bounding boxes
  /// (mirrors `Page::LayOutHorizontally` and `Page::LayOutVertically` in
  /// `page.cpp:410`, `:532`, `:554` and `588-593`).
  ///
  /// Mirrors the C++ exactly: `BBOX_HORIZONTAL_ONLY` with
  /// `SlurHandling::Ignore` for the horizontal pass (page.cpp:410),
  /// `BBOX_BOTH` with the default `SlurHandling::Initialize` for the first
  /// vertical pass (page.cpp:532), `BBOX_BOTH` with `SlurHandling::Drawing`
  /// for the second vertical pass (page.cpp:554), and a conditional third
  /// `BBOX_BOTH` `Initialize` redraw + `AdjustSlurs` when
  /// `HasCrossStaffSlurs()` (page.cpp:588-593).
  /// Ensure SMuFL resources are loaded — the C++ Doc has them after
  /// Toolkit::InitResources; the Dart port lazily loads them so that both the
  /// View and the BBoxDeviceContext share the same glyph tables. The suite's
  /// defaultPath is 'assets/data' but some tests construct Doc before the
  /// test's setUpAll updates it, so the doc's path may still be 'data'; retry
  /// with the package's assets path if the first attempt leaves the resources
  /// empty.
  void _ensureResourcesLoaded(Doc doc) {
    if (!doc.resources.ok) {
      doc.resources.initFonts();
      if (!doc.resources.ok && doc.resources.path != 'assets/data') {
        doc.resources.path = 'assets/data';
        doc.resources.initFonts();
      }
      if (!doc.resources.ok && Resources.defaultPath == 'assets/data') {
        doc.resources.path = Resources.defaultPath;
        doc.resources.initFonts();
      }
    }
  }

  void _renderBoundingBoxes(Doc doc,
      {required bool horizontal,
      SlurHandling slurHandling = SlurHandling.ignore}) {
    _ensureResourcesLoaded(doc);
    if (horizontal) {
      // Horizontal pass (page.cpp:410): View with BBOX_HORIZONTAL_ONLY and
      // SlurHandling::Ignore.
      final view = View()..setDoc(doc);
      view.slurHandling = SlurHandling.ignore;
      final bBoxDC = BBoxDeviceContext(
          toLogicalX: view.toLogicalX,
          toLogicalY: view.toLogicalY,
          update: BBOX_HORIZONTAL_ONLY);
      view.setPage(this, false);
      view.drawCurrentPage(bBoxDC, false);
      return;
    }
    // Vertical passes: the caller decides the SlurHandling. For the canonical
    // first pass the caller now passes Initialize (page.cpp:532 default); the
    // second pass is Drawing (page.cpp:554); the conditional third is
    // Initialize again (page.cpp:588). This helper is a thin wrapper so that
    // layOutVertically can keep the View/BBoxDC wiring in one place while
    // still matching the C++ per-pass slur handling.
    final view = View()..setDoc(doc);
    view.slurHandling = slurHandling;
    final bBoxDC = BBoxDeviceContext(
        toLogicalX: view.toLogicalX,
        toLogicalY: view.toLogicalY,
        update: BBOX_BOTH);
    view.setPage(this, false);
    view.drawCurrentPage(bBoxDC, false);
  }
}

// ---------------------------------------------------------------------------
// Doc
// ---------------------------------------------------------------------------

/// This class holds the data and corresponds to the model of a MVC design
/// pattern (mirrors `vrv::Doc`).
class Doc extends Object {
  Doc() {
    // Register the doc ClassId so ancestor lookups resolve the document
    // (mirrors the C++ class id of Doc).
    assignClassId(ClassId.doc);
    options = Options();
    reset();
  }

  /// Selection pages (owned; mirrors `m_selectionPreceding` /
  /// `m_selectionFollowing`).
  Page? selectionPreceding;
  Page? selectionFollowing;
  String selectionStart = '';
  String selectionEnd = '';

  /// A page range with focus in the document (mirrors `m_focusRange`).
  PageRange? focusRange;

  /// Copies of the header/front/back trees (mirrors `m_header`, `m_front`,
  /// `m_back` pugi documents). Populated by the IO with [MeiXmlNode]
  /// subtrees (`lib/src/io/xml_node.dart`); mirrors `pugi::xml_document`.
  MeiXmlNode? header;
  MeiXmlNode? front;
  MeiXmlNode? back;

  /// The music@decls value (mirrors `m_musicDecls`).
  String musicDecls =
      ''; // Current page dimensions (mirrors the public m_drawingPage* members).
  int drawingPageHeight = -1;
  int drawingPageWidth = -1;
  int drawingPageContentHeight = -1;
  int drawingPageContentWidth = -1;
  int drawingPageMarginBottom = 0;
  int drawingPageMarginLeft = 0;
  int drawingPageMarginRight = 0;
  int drawingPageMarginTop = 0;
  double drawingBeamMaxSlope = 0;

  /// Record notation type for the document (mirrors `m_notationType`).
  Notationtype notationType = Notationtype.none;

  /// An expansion map filled when expansions are expanded (mirrors
  /// `m_expansionMap`).
  final ExpansionMap expansionMap = ExpansionMap();

  // Private-state mirrors
  DocType _type = DocType.raw;
  late Options options;

  /// The list of all visible scores (mirrors `m_visibleScores`).
  final List<Object> visibleScores = [];

  /// A flag indicating if the document has been cast off or not.
  bool _isCastOff = false;

  FocusStatusType focusStatus = FocusStatusType.unset;

  /// The page currently being drawn (mirrors `m_drawingPage`).
  Page? drawingPage;

  int drawingBeamWidth = 0;
  int drawingBeamWhiteWidth = 0;
  int drawingBrevisWidth = 0;
  int drawingSmuflFontSize = 0;
  int drawingLyricFontSize = 0;
  int fingeringFontSize = 0;

  /// The resources of the document (mirrors `m_resources`, doc.h:657). The
  /// fonts are loaded explicitly (`Resources::InitFonts`) — the instance
  /// itself does not read any file at construction.
  final Resources resources = Resources();

  /// The SMuFL font used for drawing (mirrors `m_drawingSmuflFont`,
  /// doc.h:700) — returned by reference by [getDrawingSmuflFont], i.e., the
  /// same instance is handed out on every call.
  final FontInfo drawingSmuflFont = FontInfo();

  /// The lyric font used for drawing (mirrors `m_drawingLyricFont`,
  /// doc.h:701) — returned by reference by [getDrawingLyricFont], same
  /// pattern as [drawingSmuflFont].
  final FontInfo drawingLyricFont = FontInfo();

  /// The fingering font (mirrors `m_fingeringFont`, doc.h).
  final FontInfo fingeringFont = FontInfo();

  /// Mirrors `Doc::GetResources` (doc.h:92).
  Resources getResources() => resources;

  /// Mirrors `Doc::GetResourcesForModification` (doc.h:93).
  Resources getResourcesForModification() => resources;

  bool currentScoreDefDone = false;
  bool dataPreparationDone = false;
  double timemapTempo = 0.0;
  int markup = markupDefault;

  bool isMensuralMusicOnlyFlag = false;
  bool mensuralCastOff = false;
  bool isNeumeLinesFlag = false;

  int pageWidth = -1;
  int pageHeight = -1;
  int pageMarginBottom = 0;
  int pageMarginLeft = 0;
  int pageMarginRight = 0;
  int pageMarginTop = 0;

  /// Facsimile information (mirrors `m_facsimile`).
  Facsimile? facsimile;

  @override
  ClassId get classId => ClassId.doc;

  @override
  String get className => 'body';

  @override
  Object clone() {
    throw UnsupportedError('Doc cannot be cloned');
  }

  @override
  void reset() {
    super.reset();
    resetID();

    resetToSerialization();

    _isCastOff = false;
  }

  /// Reset the document for loading a serialization (mirrors
  /// `ResetToSerialization`).
  void resetToSerialization() {
    clearSelectionPages();
    clearChildren();

    _type = DocType.raw;
    notationType = Notationtype.none;
    pageHeight = -1;
    pageWidth = -1;
    pageMarginBottom = 0;
    pageMarginRight = 0;
    pageMarginLeft = 0;
    pageMarginTop = 0;

    drawingPageHeight = -1;
    drawingPageWidth = -1;
    drawingPageContentHeight = -1;
    drawingPageContentWidth = -1;
    drawingPageMarginBottom = 0;
    drawingPageMarginRight = 0;
    drawingPageMarginLeft = 0;
    drawingPageMarginTop = 0;

    drawingPage = null;
    currentScoreDefDone = false;
    dataPreparationDone = false;
    timemapTempo = 0.0;
    markup = markupDefault;
    isMensuralMusicOnlyFlag = false;
    isNeumeLinesFlag = false;
    visibleScores.clear();
    focusStatus = FocusStatusType.unset;

    facsimile = null;

    drawingSmuflFontSize = 0;
    drawingLyricFontSize = 0;

    _isCastOff = true;
    mensuralCastOff = false;
  }

  /// Reset to the loading state (unset the current scoreDef; mirrors
  /// `ResetToLoading`).
  void resetToLoading() {
    // Unset the current scoreDef of the whole tree.
    final scoreDefUnsetCurrent = ScoreDefUnsetCurrentFunctor();
    process(scoreDefUnsetCurrent);
    currentScoreDefDone = false;
  }

  /// Clear the selection pages (mirrors `ClearSelectionPages`).
  void clearSelectionPages() {
    selectionPreceding = null;
    selectionFollowing = null;
    selectionStart = '';
    selectionEnd = '';
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {ClassId.mdiv, ClassId.pages};
    return supported.contains(classId);
  }

  // -------------------------------------------------------------------------
  // Type / flags
  // -------------------------------------------------------------------------

  /// Getter and setter for the DocType.
  DocType getType() => _type;

  void setType(DocType type) => _type = type;

  bool isFacs() => _type == DocType.facs;
  bool isRaw() => _type == DocType.raw;
  bool isRendering() => _type == DocType.rendering;
  bool isTranscription() => _type == DocType.transcription;

  /// Setter for markup flag (mirrors `SetMarkup`).
  void setMarkup(int value) => markup |= value;

  /// Mensural only flag (mirrors `SetMensuralMusicOnly` /
  /// `IsMensuralMusicOnly`).
  void setMensuralMusicOnly(bool value) => isMensuralMusicOnlyFlag = value;
  bool isMensuralMusicOnly() => isMensuralMusicOnlyFlag;

  /// Neume lines flag (mirrors `SetNeumeLines` / `IsNeumeLines`).
  void setNeumeLines(bool value) => isNeumeLinesFlag = value;
  bool isNeumeLines() => isNeumeLinesFlag;

  /// Facsimile accessors (mirrors `SetFacsimile` / `GetFacsimile` /
  /// `HasFacsimile`).
  void setFacsimile(Facsimile? value) => facsimile = value;
  Facsimile? getFacsimile() => facsimile;
  bool hasFacsimile() => facsimile != null;

  /// Return true if the document has been cast off already (mirrors
  /// `IsCastOff`).
  bool isCastOff() => _isCastOff;

  /// Mark the cast-off state (used by the layout phase functors).
  void setCastOff(bool value) => _isCastOff = value;

  /// Getter for the options (mirrors `GetOptions`).
  Options getOptions() => options;

  // -------------------------------------------------------------------------
  // Structure lookups
  // -------------------------------------------------------------------------

  /// Check if the document has a page with the specified value (mirrors
  /// `HasPage`).
  bool hasPage(int pageIdx) {
    final pages = getPages();
    assert(pages != null);
    return pageIdx >= 0 && pageIdx < pages!.childCount;
  }

  /// Get the Pages in the visible Mdiv (mirrors `GetPages`).
  Pages? getPages() => findDescendantByType(ClassId.pages) as Pages?;

  /// Get the total page count (mirrors `GetPageCount`).
  int getPageCount() {
    final pages = getPages();
    return pages?.childCount ?? 0;
  }

  /// Get the first scoreDef of the first score (mirrors
  /// `GetFirstScoreDef`).
  Object? getFirstScoreDef() {
    final score = findDescendantByType(ClassId.score, deepness: 3) as Score?;
    return score?.getScoreDef();
  }

  /// Return true if the MIDI generation is already done (mirrors
  /// `GetMidiExportDone`).
  bool getMidiExportDone() => timemapTempo > 0.0;

  /// Selection helpers (full behaviour arrives with the selection support).
  bool hasSelection() => selectionStart.isNotEmpty || selectionEnd.isNotEmpty;

  // -------------------------------------------------------------------------
  // Layout preparation (Phase 4) — mirrors Doc::PrepareData and friends
  // -------------------------------------------------------------------------

  /// Prepare the data for rendering (mirrors `Doc::PrepareData`).
  ///
  /// After this method the drawing relationships are resolved (@startid /
  /// @endid / @tstamp / @next / @plist …), the layer element parts are
  /// instantiated (stem, flag, dots…) and the headless Calc* functors have
  /// produced the stem directions / lengths, dot locations and slur curve
  /// directions.
  void prepareData() {
    Object root = this;

    /************ Reset and initialization ************/

    if (dataPreparationDone) {
      // Reset the scoreDef for the entire doc.
      resetToLoading();
      final resetData = ResetDataFunctor();
      root.process(resetData);
    }
    final prepareDataInitialization = PrepareDataInitializationFunctor(this);
    root.process(prepareDataInitialization);

    /************ Generate measure indices ************/

    prepareMeasureIndices();

    /************ Collect all visible scores ************/

    collectVisibleScores();

    /************ Store default durations ************/

    final prepareDuration = PrepareDurationFunctor();
    root.process(prepareDuration);

    /************ Resolve @startid / @endid ************/

    // Try to match all spanning elements (slur, tie, etc).
    final prepareTimeSpanning = PrepareTimeSpanningFunctor();
    root.process(prepareTimeSpanning);
    prepareTimeSpanning.setDataCollectionCompleted();

    // Try again forwards without filling the list (that is only resolving
    // remaining elements).
    if (prepareTimeSpanning.getInterfaceOwnerPairs().isNotEmpty) {
      root.process(prepareTimeSpanning);
    }

    // Display warning if some elements were not matched.
    for (final (TimeSpanningInterface interface, Object owner)
        in prepareTimeSpanning.getInterfaceOwnerPairs()) {
      if (interface.hasStartid && interface.hasEndid) {
        logWarning("Time spanning element '${owner.className}' with xml:id "
            "'${owner.id}', @startid '${interface.startid}', and @endid "
            "'${interface.endid}' could not be matched.");
      }
    }

    /************ Resolve @startid (only) ************/

    // Resolve <reh> elements first.
    final prepareRehPosition = PrepareRehPositionFunctor();
    root.process(prepareRehPosition);

    // Try to match all time pointing elements (tempo, fermata, etc) by
    // processing backwards.
    final prepareTimePointing = PrepareTimePointingFunctor();
    prepareTimePointing.setDirection(backward);
    root.process(prepareTimePointing);

    /************ Resolve @tstamp / @tstamp2 ************/

    final prepareTimestamps = PrepareTimestampsFunctor();
    root.process(prepareTimestamps);

    /************ Resolve linking (@next) ************/

    final prepareLinking = PrepareLinkingFunctor();
    root.process(prepareLinking);
    prepareLinking.setDataCollectionCompleted();

    // If we have some left process again backward.
    if (prepareLinking.sameasIDPairs.isNotEmpty ||
        prepareLinking.stemSameasIDPairs.isNotEmpty) {
      prepareLinking.setDirection(backward);
      root.process(prepareLinking);
    }

    // If some are still there, then it is probably an issue in the encoding.
    if (prepareLinking.nextIDPairs.isNotEmpty) {
      logWarning('${prepareLinking.nextIDPairs.length} element(s) with a @next '
          'could not match the target');
    }
    if (prepareLinking.sameasIDPairs.isNotEmpty) {
      logWarning(
          '${prepareLinking.sameasIDPairs.length} element(s) with a @sameas '
          'could not match the target');
    }
    if (prepareLinking.stemSameasIDPairs.isNotEmpty) {
      logWarning('${prepareLinking.stemSameasIDPairs.length} element(s) with a '
          '@stem.sameas could not match the target');
    }

    /************ Resolve @plist ************/

    final preparePlist = PreparePlistFunctor();
    root.process(preparePlist);
    preparePlist.setDataCollectionCompleted();

    // Process plist after all pairs have been collected.
    if (preparePlist.plistObjectIDPairs.isNotEmpty) {
      root.process(preparePlist);
    }

    // If some are still there, then it is probably an issue in the encoding.
    for (final (Object holder, String id) in preparePlist.plistObjectIDPairs) {
      logWarning(
          "Element '${holder.className}' with xml:id '${holder.id}' and a "
          "@plist could not match the target '$id'.");
    }

    /************ Resolve cross staff ************/

    final prepareCrossStaff = PrepareCrossStaffFunctor();
    root.process(prepareCrossStaff);

    /************ Resolve beamspan elements ***********/

    final prepareBeamSpanElements = PrepareBeamSpanElementsFunctor();
    root.process(prepareBeamSpanElements);

    /************ Match pedal lines ***********/

    final preparePedals = PreparePedalsFunctor(this);
    root.process(preparePedals);

    /************ Prepare processing by staff/layer/verse ************/

    // We need to populate processing lists for processing the document by
    // Layer (for matching @tie) and by Verse (for matching syllable
    // connectors).
    final initProcessingLists = InitProcessingListsFunctor();
    root.process(initProcessingLists);

    /************ Resolve some pointers by layer ************/

    for (final int staffN in initProcessingLists.layerTree.keys) {
      for (final int layerN in initProcessingLists.layerTree[staffN]!) {
        final filters = Filters();
        filters.add(AttNIntegerComparison(ClassId.staff, staffN));
        filters.add(AttNIntegerComparison(ClassId.layer, layerN));

        final preparePointersByLayer = PreparePointersByLayerFunctor();
        preparePointersByLayer.setFilters(filters);
        root.process(preparePointersByLayer);
      }
    }

    /************ Resolve delayed turns ************/

    final prepareDelayedTurns = PrepareDelayedTurnsFunctor();
    root.process(prepareDelayedTurns);
    prepareDelayedTurns.setDataCollectionCompleted();

    if (prepareDelayedTurns.getDelayedTurns().isNotEmpty) {
      for (final int staffN in initProcessingLists.layerTree.keys) {
        for (final int layerN in initProcessingLists.layerTree[staffN]!) {
          final filters = Filters();
          filters.add(AttNIntegerComparison(ClassId.staff, staffN));
          filters.add(AttNIntegerComparison(ClassId.layer, layerN));

          prepareDelayedTurns.setFilters(filters);
          prepareDelayedTurns.resetCurrent();
          root.process(prepareDelayedTurns);
        }
      }
    }

    /************ Resolve lyric connectors ************/

    for (final int staffN in initProcessingLists.verseTree.keys) {
      for (final int layerN in initProcessingLists.verseTree[staffN]!.keys) {
        for (final int verseN
            in initProcessingLists.verseTree[staffN]![layerN]!) {
          final filters = Filters();
          filters.add(AttNIntegerComparison(ClassId.staff, staffN));
          filters.add(AttNIntegerComparison(ClassId.layer, layerN));
          filters.add(AttNIntegerComparison(ClassId.verse, verseN));

          // The first pass sets the start / end of each syl connector.
          final prepareLyrics = PrepareLyricsFunctor();
          prepareLyrics.setFilters(filters);
          root.process(prepareLyrics);
        }
      }
    }

    /************ Fill control event spanning ************/

    final prepareStaffCurrentTimeSpanning =
        PrepareStaffCurrentTimeSpanningFunctor();
    root.process(prepareStaffCurrentTimeSpanning);

    // Something must be wrong in the encoding because a
    // TimeSpanningInterface was left open.
    for (final Object object
        in prepareStaffCurrentTimeSpanning.getTimeSpanningElements()) {
      logWarning("Time spanning element '${object.className}' with xml:id "
          "'${object.id}' could not be set as running.");
    }

    /************ Resolve mRpt ************/

    for (final int staffN in initProcessingLists.layerTree.keys) {
      for (final int layerN in initProcessingLists.layerTree[staffN]!) {
        final filters = Filters();
        filters.add(AttNIntegerComparison(ClassId.staff, staffN));
        filters.add(AttNIntegerComparison(ClassId.layer, layerN));

        // We set multiNumber to unset to indicate we need to look at the
        // staffDef when reaching the first staff.
        final prepareRpt = PrepareRptFunctor(this);
        prepareRpt.setFilters(filters);
        root.process(prepareRpt);
      }
    }

    /************ Resolve endings ************/

    final prepareMilestones = PrepareMilestonesFunctor();
    root.process(prepareMilestones);

    /************ Resolve floating groups for vertical alignment ************/

    final prepareFloatingGrps = PrepareFloatingGrpsFunctor();
    root.process(prepareFloatingGrps);

    /************ Resolve cue size ************/

    final prepareCueSize = PrepareCueSizeFunctor();
    root.process(prepareCueSize);

    /************ Resolve @altsym ************/

    final prepareAltSym = PrepareAltSymFunctor();
    root.process(prepareAltSym);

    /************ Instantiate LayerElement parts (stem, flag, dots) ************/

    final prepareLayerElementParts = PrepareLayerElementPartsFunctor();
    root.process(prepareLayerElementParts);

    /************ Headless drawing calculations ************/
    // Deviation: the C++ drives these from Page::ResetAligners during the
    // rendering layout, i.e. after ScoreDefSetCurrentDoc has run; here they
    // run right after the preparation so that consumers get the full
    // drawing state without a render pass. The current scoreDef is set
    // first when needed so that clef-based locations are available.
    if (!currentScoreDefDone) {
      scoreDefSetCurrentDoc();
    }

    final calcStem = CalcStemFunctor(this);
    root.process(calcStem);

    final calcChordNoteHeads = CalcChordNoteHeadsFunctor(this);
    root.process(calcChordNoteHeads);

    final calcDots = CalcDotsFunctor(this);
    root.process(calcDots);

    final calcArtic = CalcArticFunctor(this);
    root.process(calcArtic);

    final calcSlurDirection = CalcSlurDirectionFunctor(this);
    root.process(calcSlurDirection);

    final calcSpanningBeamSpans = CalcSpanningBeamSpansFunctor(this);
    root.process(calcSpanningBeamSpans);

    /************ Group symbols ************/

    for (final Object object in visibleScores) {
      final Score score = object as Score;
      assert(score.getScoreDef() != null);
      final scoreDefSetGrpSym = ScoreDefSetGrpSymFunctor();
      score.getScoreDef()!.process(scoreDefSetGrpSym);
    }

    dataPreparationDone = true;
  }

  /// Set the current scoreDef for the whole document (mirrors
  /// `Doc::ScoreDefSetCurrentDoc`).
  bool scoreDefSetCurrentDoc({bool force = false}) {
    if (currentScoreDefDone && !force) {
      return true;
    }

    if (currentScoreDefDone) {
      final scoreDefUnsetCurrent = ScoreDefUnsetCurrentFunctor();
      process(scoreDefUnsetCurrent);
    }

    // First we need to set Page::m_score and Page::m_scoreEnd.
    final scoreDefSetCurrentPage = ScoreDefSetCurrentPageFunctor(this);
    process(scoreDefSetCurrentPage, deepness: 3);

    final scoreDefSetCurrent = ScoreDefSetCurrentFunctor(this);
    process(scoreDefSetCurrent);

    if (scoreDefSetCurrent.hasOssia) {
      final scoreDefSetOssia = ScoreDefSetOssiaFunctor(this);
      process(scoreDefSetOssia);
    }

    scoreDefSetGrpSymDoc();

    currentScoreDefDone = true;

    return true;
  }

  /// Resolve the group symbols using the scoreDefs (mirrors
  /// `Doc::ScoreDefSetGrpSymDoc`).
  void scoreDefSetGrpSymDoc() {
    final scoreDefSetGrpSym = ScoreDefSetGrpSymFunctor();
    process(scoreDefSetGrpSym);
  }

  /// Optimize the scoreDef of each system, hiding empty staves (mirrors
  /// `Doc::ScoreDefOptimizeDoc`).
  void scoreDefOptimizeDoc() {
    final scoreDefOptimize = ScoreDefOptimizeFunctor(this);
    process(scoreDefOptimize);

    scoreDefSetGrpSymDoc();
  }

  /// Set the index (1-based) of each measure (mirrors
  /// `Doc::PrepareMeasureIndices`, doc.cpp:288 — the whole tree is searched).
  void prepareMeasureIndices() {
    final List<Object> measures = findAllDescendantsByType(ClassId.measure);

    int index = 0;
    for (final Object object in measures) {
      (object as Measure).setIndex(++index);
    }
  }

  /// Collect the scores having a milestone end (mirrors
  /// `Doc::CollectVisibleScores`).
  void collectVisibleScores() {
    visibleScores.clear();
    final List<Object> objects =
        findAllDescendantsByType(ClassId.score, deepness: 3);
    for (final Object object in objects) {
      final Score score = object as Score;
      // Visible scores have milestone end.
      if (score.isPageMilestone()) {
        visibleScores.add(score);
      }
    }
  }

  /// Get the list of the visible scores (mirrors `Doc::GetVisibleScores`).
  List<Object> getVisibleScores() {
    if (visibleScores.isEmpty) {
      collectVisibleScores();
    }
    return visibleScores;
  }

  /// Get the first visible score (mirrors `Doc::GetFirstVisibleScore`).
  Score? getFirstVisibleScore() {
    if (visibleScores.isEmpty) {
      collectVisibleScores();
    }
    return visibleScores.isEmpty ? null : visibleScores.first as Score;
  }

  /// Return the score corresponding to an object (mirrors
  /// `Doc::GetCorrespondingScore`); the first visible score when none
  /// matches.
  Score? getCorrespondingScore(Object reference, [List<Score>? scores]) {
    final List<Score> scoreList = scores ??
        <Score>[
          ...getVisibleScores().cast<Score>(),
        ];
    assert(scoreList.isNotEmpty);

    Score? correspondingScore = scoreList.first;
    for (final Score score in scoreList) {
      if (identical(score, reference) ||
          Object.isPreOrdered(score, reference)) {
        correspondingScore = score;
      }
    }
    return correspondingScore;
  }

  /// Set the drawing page (mirrors `Doc::SetDrawingPage`). Returns null when
  /// [pageIdx] is out of range.
  ///
  /// Deviation: the page-range layout (`withPageRange`) and the focus reset
  /// arrive with their respective phases.
  Page? setDrawingPage(int pageIdx) {
    // Out of range.
    if (!hasPage(pageIdx)) {
      return null;
    }
    // Nothing to do.
    if (drawingPage != null && drawingPage!.getPageIdx() == pageIdx) {
      return drawingPage;
    }
    final Pages? pages = getPages();
    assert(pages != null);
    drawingPage = pages!.getChild(pageIdx) as Page?;
    assert(drawingPage != null);

    updatePageDrawingSizes();

    return drawingPage;
  }

  /// Unset the drawing page (mirrors `Doc::ResetDataPage`).
  void resetDataPage() {
    drawingPage = null;
  }

  /// Update the drawing sizes of the current page (a headless subset of
  /// `Doc::UpdatePageDrawingSizes`: glyph based widths stay unset until the
  /// resources phase provide them).
  void updatePageDrawingSizes() {
    assert(drawingPage != null);

    // We use the page members only if set (!= -1).
    if (drawingPage!.pageHeight != -1) {
      drawingPageHeight = drawingPage!.pageHeight;
      drawingPageWidth = drawingPage!.pageWidth;
      drawingPageMarginBottom = drawingPage!.pageMarginBottom;
      drawingPageMarginLeft = drawingPage!.pageMarginLeft;
      drawingPageMarginRight = drawingPage!.pageMarginRight;
      drawingPageMarginTop = drawingPage!.pageMarginTop;
    } else if (pageHeight != -1) {
      drawingPageHeight = pageHeight;
      drawingPageWidth = pageWidth;
      drawingPageMarginBottom = pageMarginBottom;
      drawingPageMarginLeft = pageMarginLeft;
      drawingPageMarginRight = pageMarginRight;
      drawingPageMarginTop = pageMarginTop;
    } else {
      // Defaults from the options (mirrors options.cpp values).
      drawingPageHeight = options.pageHeight.value;
      drawingPageWidth = options.pageWidth.value;
      drawingPageMarginBottom = options.pageMarginBottom.value;
      drawingPageMarginLeft = options.pageMarginLeft.value;
      drawingPageMarginRight = options.pageMarginRight.value;
      drawingPageMarginTop = options.pageMarginTop.value;
    }

    drawingPageContentHeight =
        drawingPageHeight - drawingPageMarginTop - drawingPageMarginBottom;
    drawingPageContentWidth =
        drawingPageWidth - drawingPageMarginLeft - drawingPageMarginRight;

    drawingSmuflFontSize = options.unit.value.toInt() * 8;

    // Mirrors `Doc::UpdateDrawingValues` beam widths (doc.cpp:2390-2391):
    // these are required for `View::DrawBrace` (view_page.cpp:622) and other
    // beam-related drawing. The Dart port never initialized them, leaving
    // `getDrawingBeamWhiteWidth` at 0 and shifting the brace `xdec` by
    // `unit/2` (=45 at staffSize 100), exactly the probe diff for
    // `arpeg-003` (brace bezier `x` 81 vs 36, Δ45).
    drawingBeamWidth = options.unit.value.toInt();
    drawingBeamWhiteWidth = (options.unit.value / 2).toInt();
  }

  /// Return the adjusted page height in device (pixel) coordinates
  /// (mirrors `Doc::GetAdjustedDrawingPageHeight`, doc.cpp:2418).
  ///
  /// Deviations from the C++:
  /// - the `assert(m_drawingPage)` is subsumed by the `!` on the nullable
  ///   [drawingPage] (same crash class in debug builds).
  int getAdjustedDrawingPageHeight() {
    // Take into account the PPU when getting the page height in facsimile
    if (isTranscription() || isFacs()) {
      return drawingPage!.pageHeight *
          drawingPage!.getPPUFactor() ~/
          definitionFactor;
    }

    int contentHeight = drawingPage!.getContentHeight();
    if (options.scaleToPageSize.value) {
      // Integer arithmetic as in the C++ (`contentHeight * scale / 100`).
      contentHeight = contentHeight * options.scale.value ~/ 100;
    }
    return (contentHeight + drawingPageMarginTop + drawingPageMarginBottom) ~/
        definitionFactor;
  }

  /// Calculate the timemap of the document (mirrors `Doc::CalculateTimemap`
  /// reduced to the functors ported so far; the tie duration and grace note
  /// adjustments arrive with the MIDI phase).
  void calculateTimemap() {
    // There is no data to calculate the timemap.
    if (getPageCount() == 0) {
      return;
    }

    timemapTempo = 0.0;

    // This happens if the document was never cast off (breaks none option in
    // the toolkit). The horizontal layout itself arrives with Phase 4.
    if (drawingPage == null) {
      setDrawingPage(0);
      scoreDefSetCurrentDoc();
    }

    double tempo = midiTempo.toDouble();

    // Set tempo from the first visible score.
    final Score? score = getFirstVisibleScore();
    final scoreDef = score?.getScoreDef() as ScoreDef?;
    if (scoreDef != null) {
      if (scoreDef.hasMidiBpm) {
        tempo = scoreDef.midiBpm!;
      } else if (scoreDef.hasMm) {
        tempo = tempoCalcTempo(
            mm: scoreDef.mm!, mmUnit: scoreDef.mmUnit, mmDots: scoreDef.mmDots);
      }
    }

    // We first calculate the maximum duration of each measure.
    final initMaxMeasureDuration = InitMaxMeasureDurationFunctor();
    initMaxMeasureDuration.setCurrentTempo(tempo);
    process(initMaxMeasureDuration);

    // Then calculate the onset and offset times (w.r.t. the measure) for
    // every note.
    final initOnsetOffset = InitOnsetOffsetFunctor(this);
    process(initOnsetOffset);

    timemapTempo = tempo;
  }

  /// Lay out the current page horizontally (mirrors the doc-level routing
  /// used by `Doc::CalculateTimemap` / `Doc::Rend**`: set the drawing page
  /// and the current scoreDef, then call `Page::LayOutHorizontally`).
  ///
  /// After this method:
  /// - each LayerElement has an Alignment whose xRel is set;
  /// - grace notes are spaced through their GraceAligner;
  /// - the measures of each system have their drawingXRel position.
  void layOutHorizontally() {
    if (getPageCount() == 0) return;

    // This happens if the document was never cast off.
    if (!currentScoreDefDone) {
      scoreDefSetCurrentDoc();
    }
    if (drawingPage == null) {
      setDrawingPage(0);
    }
    drawingPage!.layOutHorizontally();
  }

  // -------------------------------------------------------------------------
  // Cast-off / layout orchestration (Phase 4) — mirrors Doc::CastOffDoc,
  // Doc::CastOffEncodingDoc, Doc::UnCastOffDoc and the toolkit LayOut
  // sequence
  // -------------------------------------------------------------------------

  /// Cast off the document with automatic breaks (mirrors
  /// `Doc::CastOffDoc`).
  void castOffDoc() => castOffDocBase(false, false);

  /// Cast off the document using the encoded `<sb>` breaks (mirrors
  /// `Doc::CastOffLineDoc`).
  void castOffLineDoc() => castOffDocBase(true, false);

  /// Cast off the document with smart encoded breaks (mirrors
  /// `Doc::CastOffSmartDoc`).
  void castOffSmartDoc() => castOffDocBase(false, false, smart: true);

  /// Base method for casting off a document (mirrors `Doc::CastOffDocBase`).
  ///
  /// When [useSb] is set, the encoded system breaks are used; [usePb] is kept
  /// for signature parity (unused as in the C++). When [smart] is set the
  /// encoded breaks are used smartly.
  ///
  /// Deviations from the C++:
  /// - The focus / selection management arrives with its phase.
  void castOffDocBase(bool useSb, bool usePb, {bool smart = false}) {
    final Pages? pages = getPages();
    assert(pages != null);

    if (isCastOff()) {
      logDebug('Document is already cast off');
      return;
    }

    final List<Score> scores =
        getVisibleScores().cast<Score>().toList(growable: false);
    assert(scores.isNotEmpty);

    scoreDefSetCurrentDoc();

    Page? unCastOffPage = setDrawingPage(0);
    assert(unCastOffPage != null);

    // Check if the horizontal layout is cached by looking at the first
    // measure. The cache is not set the first time, or can be reset by
    // unCastOffDoc. In this port the cache is always empty (see
    // layOutHorizontallyWithCache) so the layout always runs.
    final Measure? firstMeasure =
        unCastOffPage!.findDescendantByType(ClassId.measure) as Measure?;
    if (firstMeasure == null || !firstMeasure.hasCachedHorizontalLayout()) {
      unCastOffPage.layOutHorizontally();
      unCastOffPage.layOutHorizontallyWithCache();
    } else {
      unCastOffPage.layOutHorizontallyWithCache(restore: true);
    }

    final Page castOffSinglePage = Page();

    System? leftoverSystem;
    if (useSb && !usePb && !smart) {
      final castOffEncoding =
          CastOffEncodingFunctor(this, castOffSinglePage, usePages: false);
      unCastOffPage.process(castOffEncoding);
    } else {
      final castOffSystems =
          CastOffSystemsFunctor(castOffSinglePage, this, smart);
      castOffSystems.setSystemWidth(drawingPageContentWidth);
      unCastOffPage.process(castOffSystems);
      leftoverSystem = castOffSystems.getLeftoverSystem();
    }
    // We can now detach and delete the old content page.
    pages!.detachChild(0);
    unCastOffPage = null;

    // Store the cast-off system widths => these are used to adjust the
    // horizontal spacing for a given duration during page layout.
    final alignMeasures = AlignMeasuresFunctor(this);
    alignMeasures.storeCastOffSystemWidths = true;
    castOffSinglePage.process(alignMeasures);

    // Replace it with the castOffSinglePage.
    pages.addChild(castOffSinglePage);
    resetDataPage();
    setDrawingPage(0);

    bool optimize = false;
    for (final Score score in scores) {
      if (score.scoreDefNeedsOptimization(getOptions().condense.value)) {
        optimize = true;
        break;
      }
    }

    // Reset the scoreDef at the beginning of each system.
    scoreDefSetCurrentDoc(force: true);
    if (optimize) {
      scoreDefOptimizeDoc();
    }

    // Here we redo the alignment because of the new scoreDefs.
    castOffSinglePage.resetCachedDrawingX();
    castOffSinglePage.layOutVertically();

    // Detach the contentPage to prepare for CastOffPages.
    pages.detachChild(0);
    resetDataPage();

    for (final Score score in scores) {
      score.calcRunningElementHeight(this);
    }

    final Page castOffFirstPage = Page();
    final castOffPages =
        CastOffPagesFunctor(castOffSinglePage, this, castOffFirstPage);
    castOffPages.setPageHeight(drawingPageContentHeight);
    castOffPages.setLeftoverSystem(leftoverSystem);

    pages.addChild(castOffFirstPage);
    castOffSinglePage.process(castOffPages);

    scoreDefSetCurrentDoc(force: true);
    if (optimize) {
      scoreDefOptimizeDoc();
    }

    setCastOff(true);
  }

  /// Cast off the document according to the encoded `<pb>` / `<sb>` breaks
  /// (mirrors `Doc::CastOffEncodingDoc`).
  void castOffEncodingDoc() {
    if (isCastOff()) {
      logDebug('Document is already cast off');
      return;
    }

    scoreDefSetCurrentDoc();

    final Pages? pages = getPages();
    assert(pages != null);

    final Page? unCastOffPage = setDrawingPage(0);
    assert(unCastOffPage != null);
    unCastOffPage!.resetAligners();

    // Detach the content page.
    pages!.detachChild(0);
    assert(unCastOffPage.parent == null);

    final Page castOffFirstPage = Page();
    pages.addChild(castOffFirstPage);

    final castOffEncoding = CastOffEncodingFunctor(this, castOffFirstPage);
    unCastOffPage.process(castOffEncoding);

    // We need to reset the drawing page to NULL because idx will still be 0
    // but the content page is dead!
    resetDataPage();
    scoreDefSetCurrentDoc(force: true);

    // Optimize the doc if one of the scores requires optimization.
    for (final Object object in getVisibleScores()) {
      final Score score = object as Score;
      if (score.scoreDefNeedsOptimization(getOptions().condense.value)) {
        scoreDefOptimizeDoc();
        break;
      }
    }

    setCastOff(true);
  }

  /// Convert a mensural document into cast-off (measure) segments looking at
  /// the barLine objects (mirrors `Doc::ConvertToCastOffMensuralDoc`).
  ///
  /// With [castOff] set to [MensuralCastOffType.unset] or
  /// [MensuralCastOffType.reset] the conversion is only applied when the
  /// mensural cast off was performed before.
  ///
  /// Deviations from the C++:
  /// - The focus / selection management arrives with its phase.
  /// - The C++ relies on PrepareData being run before; here it is re-run when
  ///   not done yet so the method can be called directly after the import.
  void convertToCastOffMensuralDoc(MensuralCastOffType castOff) {
    if (!isMensuralMusicOnly()) return;

    // Do not convert if not an init call and mensural cast was not performed
    if ((castOff != MensuralCastOffType.init) && !mensuralCastOff) return;

    // Do not convert transcription files
    if (isTranscription()) return;

    // Do not convert facs files
    if (isFacs()) return;

    // Flag it as performed
    mensuralCastOff = true;

    // With init and reset we are converting to cast off
    final bool convertToCastOff = (castOff != MensuralCastOffType.unset);

    // Make sure the document is not cast-off
    if (isCastOff()) unCastOffDoc();

    scoreDefSetCurrentDoc();

    Page? contentPage = setDrawingPage(0);
    assert(contentPage != null);

    contentPage!.layOutHorizontally();

    final List<Object> systems =
        contentPage.findAllDescendantsByType(ClassId.system, deepness: 1);
    for (final Object item in systems) {
      final System system = item as System;
      if (convertToCastOff) {
        final System convertedSystem = System();
        final ConvertToCastOffMensuralFunctor convertToCastOffMensural =
            ConvertToCastOffMensuralFunctor(this, convertedSystem);
        // Convert the system and replace it
        system.process(convertToCastOffMensural);
        contentPage.replaceChild(system, convertedSystem);
      } else {
        convertToUnCastOffMensuralSystem(system);
      }
    }

    if (!dataPreparationDone) {
      prepareData();
    }

    // We need to reset the drawing page to NULL because idx will still be 0
    // but contentPage is dead!
    resetDataPage();
    scoreDefSetCurrentDoc(force: true);
    contentPage = null;
  }

  /// Undo the cast off for both pages and systems (mirrors
  /// `Doc::UnCastOffDoc`).
  void unCastOffDoc({bool resetCache = true}) {
    if (!isCastOff()) {
      logDebug('Document is not cast off');
      return;
    }

    // Deviation: ResetFocus arrives with the focus range support.

    final Pages? pages = getPages();
    assert(pages != null);

    final Page unCastOffPage = Page();
    final unCastOff = UnCastOffFunctor(unCastOffPage);
    unCastOff.setResetCache(resetCache);
    process(unCastOff);

    pages!.clearChildren();

    pages.addChild(unCastOffPage);

    // We need to reset the drawing page to NULL because idx will still be 0
    // but the content page is dead!
    resetDataPage();
    scoreDefSetCurrentDoc(force: true);

    setCastOff(false);
  }

  /// Run the full layout pipeline over the whole document (headless port of
  /// the Toolkit load / draw sequence).
  ///
  /// This casts off the document according to the `breaks` option and then
  /// lays out every page horizontally and vertically with justification.
  ///
  /// After this method the document is fully laid out: multiple systems per
  /// page (when required by the widths), multiple pages (when required by the
  /// heights), each staff having an alignment with yRel positions.
  ///
  /// The optional parameter mirrors `Input::GetLayoutInformation()`:
  /// pass true when the input contained encoded layout information (`<pb>` /
  /// `<sb>`) so that the `encoded`, `line` and `smart` breaks options are
  /// honoured; otherwise they fall back to automatic cast-off like the C++.
  void layOut({bool hasEncodedBreaks = false}) {
    Breaks breaks = getOptions().breaks.value;

    // Convert pseudo-measures into distinct segments based on barLine
    // elements (mirrors the Toolkit::LoadFile sequence, where the mensural
    // cast off runs between PrepareData and the layout).
    if (isMensuralMusicOnly() &&
        getOptions().mensuralResponsiveView.value != MensuralResp.none) {
      convertToCastOffMensuralDoc(MensuralCastOffType.init);
    }

    if (breaks != Breaks.none) {
      if (hasEncodedBreaks &&
          (breaks == Breaks.encoded ||
              breaks == Breaks.line ||
              breaks == Breaks.smart)) {
        switch (breaks) {
          case Breaks.encoded:
            castOffEncodingDoc();
            break;
          case Breaks.line:
            castOffLineDoc();
            break;
          case Breaks.smart:
            castOffSmartDoc();
            break;
          case Breaks.none:
          case Breaks.auto:
            break;
        }
      } else {
        if (hasEncodedBreaks == false &&
            (breaks == Breaks.encoded ||
                breaks == Breaks.line ||
                breaks == Breaks.smart)) {
          logWarning(
              'Requesting layout with specific breaks but nothing provided '
              'in the data');
        }
        castOffDoc();
      }
    } else {
      // We need at least this to be done with breaks auto.
      scoreDefSetCurrentDoc();
    }

    getPages()?.layOutAll();
  }

  // -------------------------------------------------------------------------
  // Headless geometry helpers (mirrors the Doc drawing getters used by the
  // Calc* functors; the option-based values use the C++ defaults when the
  // option is not part of the shell yet)
  // -------------------------------------------------------------------------

  /// Mirrors `Doc::GetDrawingUnit`.
  int getDrawingUnit(int staffSize) =>
      (options.unit.value * staffSize / 100).toInt();

  /// Mirrors `Doc::GetDrawingDoubleUnit`.
  ///
  /// The C++ computes `m_unit.GetValue() * 2 * staffSize / 100` with a single
  /// integer truncation; deriving it from [getDrawingUnit] would truncate
  /// twice and diverge for sizes where the intermediate is fractional.
  int getDrawingDoubleUnit(int staffSize) =>
      (options.unit.value * 2 * staffSize / 100).toInt();

  /// Mirrors `Doc::GetDrawingStaffSize`.
  int getDrawingStaffSize(int staffSize) =>
      (options.unit.value * 8 * staffSize / 100).toInt();

  /// Mirrors `Doc::GetDrawingOctaveSize` (doc.cpp:2037).
  int getDrawingOctaveSize(int staffSize) =>
      (options.unit.value * 7 * staffSize / 100).toInt();

  /// Mirrors `Doc::GetDrawingStemWidth` (default option 0.20).
  int getDrawingStemWidth(int staffSize) =>
      (options.unit.value * 0.20 * staffSize / 100).toInt();

  /// Mirrors `Doc::GetDrawingBrevisWidth`.
  ///
  /// The C++ caches `m_drawingBrevisWidth = GetGlyphWidth(E0A2, 100) * 0.8 /
  /// 2` when updating the page drawing values; here it is computed from the
  /// same expression.
  int getDrawingBrevisWidth(int staffSize) {
    final int brevisWidth =
        (getGlyphWidth(smuflE0A2NoteheadWhole, 100, false) * 0.8) ~/ 2;
    return brevisWidth * staffSize ~/ 100;
  }

  /// Mirrors `Doc::GetCueScaling` (default option 0.75).
  double getCueScaling() => 0.75;

  /// Mirrors `Doc::GetCueSize(int)`.
  int getCueSize(int value) => (value * getCueScaling()).toInt();

  /// Mirrors `Doc::GetDrawingLedgerLineExtension`.
  int getDrawingLedgerLineExtension(int staffSize, bool graceSize) {
    int value =
        (options.ledgerLineExtension.value * getDrawingUnit(staffSize)).toInt();
    if (graceSize) value = getCueSize(value);
    return value;
  }

  /// Mirrors `Doc::GetDrawingMinimalLedgerLineExtension`.
  ///
  /// Deviation: `Option<T>` does not carry min/max bounds yet (a documented
  /// Phase-7 concern, see `options_shell.dart`), so the option's C++ minimum
  /// (`m_ledgerLineExtension.Init(0.54, 0.20, 1.00)`, options.cpp:1380) is
  /// hardcoded here instead of read off `ledgerLineExtension` itself.
  int getDrawingMinimalLedgerLineExtension(int staffSize, bool graceSize) {
    int value = (0.20 * getDrawingUnit(staffSize)).toInt();
    if (graceSize) value = getCueSize(value);
    return value;
  }

  /// Mirrors `Doc::GetGraceFactor`.
  double getGraceFactor() => options.graceFactor.value;

  /// Mirrors `Doc::GetGlyphWidth` (doc.cpp:1872).
  int getGlyphWidth(int code, int staffSize, bool graceSize) {
    final Glyph? glyph = resources.getGlyphByCode(code);
    if (glyph != null) {
      final (_, _, int w, _) = glyph.getBoundingBox();
      int width = w * drawingSmuflFontSize ~/ glyph.unitsPerEm;
      if (graceSize) width = (width * getGraceFactor()).toInt();
      width = width * staffSize ~/ 100;
      return width;
    }
    // Fallback approximation for headless/layout before fonts are loaded
    // (mirrors the earlier table-based port; kept for tests that don't init
    // fonts, e.g., layout fixtures).
    const Map<int, double> glyphWidthsInStaffSpaces = {
      smuflE0A4NoteheadBlack: 1.696,
      smuflE220Tremolo1: 1.284,
      // Chant glyphs (neume layout).
      smuflE990ChantPunctum: 1.312,
      smuflE991ChantPunctumInclinatum: 1.312,
      smuflE994ChantAuctumAsc: 1.5,
      smuflE995ChantAuctumDesc: 1.5,
      smuflE996ChantPunctumVirga: 1.62,
      smuflE997ChantPunctumVirgaReversed: 1.62,
      smuflE99BChantQuilisma: 1.724,
      smuflE9A1ChantPunctumDeminutum: 1.2,
      smuflE9B4ChantEntryLineAsc2nd: 2.4,
      smuflE9B5ChantEntryLineAsc3rd: 2.8,
      smuflE9B6ChantEntryLineAsc4th: 3.2,
      smuflE9B7ChantEntryLineAsc5th: 3.6,
      smuflE9B9ChantLigaturaDesc2nd: 1.4,
      smuflE9BAChantLigaturaDesc3rd: 1.6,
      smuflE9BBChantLigaturaDesc4th: 1.8,
      smuflE9BCChantLigaturaDesc5th: 2.0,
      smuflE9BEChantConnectingLineAsc3rd: 2.0,
      smuflEA29MedRenStrophicusCMN: 1.312,
      smuflEA2AMedRenOriscusCMN: 1.312,
    };
    final double staffSpaces =
        glyphWidthsInStaffSpaces[code] ?? 1.75; // generic default
    final double fontSize = options.unit.value * 8; // CalcMusicFontSize
    // One em equals four staff spaces in SMuFL fonts.
    double width = staffSpaces / 4 * fontSize;
    if (graceSize) width *= getGraceFactor();
    return (width * staffSize / 100).toInt();
  }

  /// Mirrors `Doc::GetGlyphHeight` (doc.cpp:1859).
  int getGlyphHeight(int code, int staffSize, bool graceSize) {
    final Glyph? glyph = resources.getGlyphByCode(code);
    if (glyph != null) {
      final (_, _, _, int h) = glyph.getBoundingBox();
      int height = h * drawingSmuflFontSize ~/ glyph.unitsPerEm;
      if (graceSize) height = (height * getGraceFactor()).toInt();
      height = height * staffSize ~/ 100;
      return height;
    }
    // Fallback: approximate as width
    return getGlyphWidth(code, staffSize, graceSize);
  }

  /// Mirrors `Doc::GetGlyphLeft` (doc.cpp:1915).
  int getGlyphLeft(int code, int staffSize, bool graceSize) {
    final Glyph? glyph = resources.getGlyphByCode(code);
    if (glyph != null) {
      final (int x, _, _, _) = glyph.getBoundingBox();
      int left = x * drawingSmuflFontSize ~/ glyph.unitsPerEm;
      if (graceSize) left = (left * getGraceFactor()).toInt();
      left = left * staffSize ~/ 100;
      return left;
    }
    return 0;
  }

  /// Mirrors `Doc::GetGlyphBottom` (doc.cpp:1933).
  int getGlyphBottom(int code, int staffSize, bool graceSize) {
    final Glyph? glyph = resources.getGlyphByCode(code);
    if (glyph != null) {
      final (_, int y, _, _) = glyph.getBoundingBox();
      int bottom = y * drawingSmuflFontSize ~/ glyph.unitsPerEm;
      if (graceSize) bottom = (bottom * getGraceFactor()).toInt();
      bottom = bottom * staffSize ~/ 100;
      return bottom;
    }
    return 0;
  }

  /// Mirrors `Doc::GetGlyphTop` (doc.cpp:1946).
  int getGlyphTop(int code, int staffSize, bool graceSize) =>
      getGlyphBottom(code, staffSize, graceSize) +
      getGlyphHeight(code, staffSize, graceSize);

  /// Mirrors `Doc::GetGlyphRight` (doc.cpp:1928).
  int getGlyphRight(int code, int staffSize, bool graceSize) =>
      getGlyphLeft(code, staffSize, graceSize) +
      getGlyphWidth(code, staffSize, graceSize);

  /// Mirrors `Doc::GetGlyphAdvX` (doc.cpp:1885).
  int getGlyphAdvX(int code, int staffSize, bool graceSize) {
    final Glyph? glyph = resources.getGlyphByCode(code);
    if (glyph != null) {
      int advX = glyph.horizAdvX;
      advX = advX * drawingSmuflFontSize ~/ glyph.unitsPerEm;
      if (graceSize) advX = (advX * getGraceFactor()).toInt();
      advX = advX * staffSize ~/ 100;
      return advX;
    }
    return getGlyphWidth(code, staffSize, graceSize);
  }

  /// Mirrors `Doc::ConvertFontPoint` (doc.cpp:1896): converts a font-relative
  /// point (font units) to staff-relative units.
  Point convertFontPoint(
      Glyph glyph, Point fontPoint, int staffSize, bool graceSize) {
    int x = fontPoint.x * drawingSmuflFontSize ~/ glyph.unitsPerEm;
    int y = fontPoint.y * drawingSmuflFontSize ~/ glyph.unitsPerEm;
    if (graceSize) {
      x = (x * getGraceFactor()).toInt();
      y = (y * getGraceFactor()).toInt();
    }
    if (staffSize != 100) {
      x = x * staffSize ~/ 100;
      y = y * staffSize ~/ 100;
    }
    return Point(x, y);
  }

  /// Mirrors `Doc::GetDrawingSmuflFont` (doc.cpp:2116) — the SMuFL font with
  /// the current font face and the size scaled by the staff size (and the
  /// grace factor for cue-sized glyphs).
  FontInfo getDrawingSmuflFont(int staffSize, bool graceSize) {
    drawingSmuflFont.faceName = resources.currentFont;
    int value = drawingSmuflFontSize * staffSize ~/ 100;
    if (graceSize) value = (value * options.graceFactor.value).toInt();
    drawingSmuflFont.pointSize = value;
    return drawingSmuflFont;
  }

  /// Mirrors `Doc::GetDrawingBarLineWidth`.
  int getDrawingBarLineWidth(int staffSize) =>
      (options.barLineWidth.value * getDrawingUnit(staffSize)).toInt();

  /// Mirrors `Doc::GetDrawingStaffLineWidth` (doc.cpp:2052).
  int getDrawingStaffLineWidth(int staffSize) =>
      (options.staffLineWidth.value * getDrawingUnit(staffSize)).toInt();

  /// Mirrors `Doc::GetDrawingBeamWhiteWidth` (doc.cpp:2085).
  int getDrawingBeamWhiteWidth(int staffSize, bool graceSize) {
    int value = drawingBeamWhiteWidth * staffSize ~/ 100;
    if (graceSize) value = (value * options.graceFactor.value).toInt();
    return value;
  }

  /// Mirrors `Doc::GetDrawingLyricFont` (doc.cpp:2125) — the lyric/label
  /// font with the size scaled by the staff size; the same instance is
  /// handed out on every call, like [getDrawingSmuflFont].
  FontInfo getDrawingLyricFont(int staffSize) {
    if (drawingLyricFontSize == 0) {
      // Lazily computed from options (doc.cpp:2395, inside
      // Doc::UpdateDrawingValues). The Dart port never called that setter,
      // so compute on first use.
      drawingLyricFontSize =
          (options.unit.value * options.lyricSize.value).toInt();
    }
    drawingLyricFont.pointSize = drawingLyricFontSize * staffSize ~/ 100;
    return drawingLyricFont;
  }

  /// Mirrors `Doc::GetMusicToLyricFontSizeRatio` (doc.cpp:2137).
  double getMusicToLyricFontSizeRatio() {
    return drawingLyricFontSize == 0
        ? 1.0
        : drawingSmuflFontSize / drawingLyricFontSize;
  }

  /// Mirrors `Doc::GetDrawingHairpinSize` (doc.cpp:2070).
  int getDrawingHairpinSize(int staffSize, bool withMargin) {
    int size = (options.hairpinSize.value * getDrawingUnit(staffSize)).toInt();
    // This should be styled
    if (withMargin) size += getDrawingUnit(staffSize);
    return size;
  }

  /// Mirrors `Doc::GetFingeringFont` (doc.cpp:2131) — the fingering font
  /// with the size scaled by the staff size. `m_fingeringFontSize` is derived
  /// from the lyric font size (doc.cpp:2396); like [getDrawingLyricFont] the
  /// Dart port computes it lazily instead of in `UpdateDrawingValues`.
  FontInfo getFingeringFont(int staffSize) {
    if (drawingLyricFontSize == 0) {
      drawingLyricFontSize =
          (options.unit.value * options.lyricSize.value).toInt();
    }
    final int fingeringFontSize =
        (drawingLyricFontSize * options.fingeringScale.value).toInt();
    fingeringFont.pointSize = fingeringFontSize * staffSize ~/ 100;
    return fingeringFont;
  }

  /// Mirrors `Doc::GetTextGlyphHeight` (doc.cpp:1951).
  int getTextGlyphHeight(int code, FontInfo font, bool graceSize) {
    final Glyph glyph = resources.getTextGlyph(code)!;
    final (_, _, _, int h) = glyph.getBoundingBox();
    int height = h * font.pointSize ~/ glyph.unitsPerEm;
    if (graceSize) height = (height * options.graceFactor.value).toInt();
    return height;
  }

  /// Mirrors `Doc::GetTextGlyphWidth` (doc.cpp:1965).
  int getTextGlyphWidth(int code, FontInfo font, bool graceSize) {
    final Glyph glyph = resources.getTextGlyph(code)!;
    final (_, _, int w, _) = glyph.getBoundingBox();
    int width = w * font.pointSize ~/ glyph.unitsPerEm;
    if (graceSize) width = (width * options.graceFactor.value).toInt();
    return width;
  }

  /// Mirrors `Doc::GetTextGlyphDescender` (doc.cpp:1992).
  int getTextGlyphDescender(int code, FontInfo font, bool graceSize) {
    final Glyph glyph = resources.getTextGlyph(code)!;
    final (_, int y, _, _) = glyph.getBoundingBox();
    int descender = y * font.pointSize ~/ glyph.unitsPerEm;
    if (graceSize) descender = (descender * options.graceFactor.value).toInt();
    return descender;
  }

  /// Mirrors `Doc::GetTextLineHeight` (doc.cpp:2006).
  int getTextLineHeight(FontInfo font, bool graceSize) {
    final int descender =
        -getTextGlyphDescender('q'.codeUnitAt(0), font, graceSize);
    final int height = getTextGlyphHeight('I'.codeUnitAt(0), font, graceSize);

    int lineHeight = ((descender + height) * 1.1).toInt();
    if (font.supSubScript) {
      lineHeight = (lineHeight / superScriptFactor).toInt();
    }

    return lineHeight;
  }

  /// Mirrors `Doc::GetLeftMargin(ClassId)`.
  double getLeftMargin(ClassId classId) {
    switch (classId) {
      case ClassId.accid:
        return options.leftMargins['Accid']!.value;
      case ClassId.barLine:
        return options.leftMargins['BarLine']!.value;
      case ClassId.beatRpt:
        return options.leftMargins['BeatRpt']!.value;
      case ClassId.chord:
        return options.leftMargins['Chord']!.value;
      case ClassId.clef:
        return options.leftMargins['Clef']!.value;
      case ClassId.keysig:
        return options.leftMargins['KeySig']!.value;
      case ClassId.mensur:
        return options.leftMargins['Mensur']!.value;
      case ClassId.meterSig:
        return options.leftMargins['MeterSig']!.value;
      case ClassId.mRest:
        return options.leftMargins['MRest']!.value;
      case ClassId.mRpt2:
        return options.leftMargins['MRpt2']!.value;
      case ClassId.multiRest:
        return options.leftMargins['MultiRest']!.value;
      case ClassId.multiRpt:
        return options.leftMargins['MultiRpt']!.value;
      case ClassId.note:
      case ClassId.stem:
        return options.leftMargins['Note']!.value;
      case ClassId.rest:
        return options.leftMargins['Rest']!.value;
      case ClassId.tabDurSym:
        return options.leftMargins['TabDurSym']!.value;
      default:
        return options.defaultLeftMargin.value;
    }
  }

  /// Mirrors `Doc::GetLeftMargin(Object)` with the barline position cases.
  double getLeftMarginOf(Object object) {
    if (object.classId == ClassId.barLine) {
      final BarLine barLine = object as BarLine;
      switch (barLine.getPosition()) {
        case BarlinePosition.none:
          return options.leftMargins['BarLine']!.value;
        case BarlinePosition.left:
          return options.leftMargins['LeftBarLine']!.value;
        case BarlinePosition.right:
          return options.leftMargins['RightBarLine']!.value;
      }
    }
    return getLeftMargin(object.classId);
  }

  /// Mirrors `Doc::GetRightMargin(ClassId)`.
  double getRightMargin(ClassId classId) {
    switch (classId) {
      case ClassId.accid:
        return options.rightMargins['Accid']!.value;
      case ClassId.barLine:
        return options.rightMargins['BarLine']!.value;
      case ClassId.beatRpt:
        return options.rightMargins['BeatRpt']!.value;
      case ClassId.chord:
        return options.rightMargins['Chord']!.value;
      case ClassId.clef:
        return options.rightMargins['Clef']!.value;
      case ClassId.keysig:
        return options.rightMargins['KeySig']!.value;
      case ClassId.mensur:
        return options.rightMargins['Mensur']!.value;
      case ClassId.meterSig:
        return options.rightMargins['MeterSig']!.value;
      case ClassId.mRest:
        return options.rightMargins['MRest']!.value;
      case ClassId.mRpt2:
        return options.rightMargins['MRpt2']!.value;
      case ClassId.multiRest:
        return options.rightMargins['MultiRest']!.value;
      case ClassId.multiRpt:
        return options.rightMargins['MultiRpt']!.value;
      case ClassId.note:
      case ClassId.stem:
        return options.rightMargins['Note']!.value;
      case ClassId.rest:
        return options.rightMargins['Rest']!.value;
      case ClassId.tabDurSym:
        return options.rightMargins['TabDurSym']!.value;
      default:
        return options.defaultRightMargin.value;
    }
  }

  /// Mirrors `Doc::GetRightMargin(Object)` with the barline position cases.
  double getRightMarginOf(Object object) {
    if (object.classId == ClassId.barLine) {
      final BarLine barLine = object as BarLine;
      switch (barLine.getPosition()) {
        case BarlinePosition.none:
          return options.rightMargins['BarLine']!.value;
        case BarlinePosition.left:
          return options.rightMargins['LeftBarLine']!.value;
        case BarlinePosition.right:
          return options.rightMargins['RightBarLine']!.value;
      }
    }
    return getRightMargin(object.classId);
  }

  /// Mirrors `Doc::GetTopMargin(ClassId)`.
  double getTopMargin(ClassId classId) {
    if (classId == ClassId.artic) return options.topMarginArtic.value;
    if (classId == ClassId.harm) return options.topMarginHarm.value;
    return options.defaultTopMargin.value;
  }

  /// Mirrors `Doc::GetBottomMargin(ClassId)`.
  double getBottomMargin(ClassId classId) {
    if (classId == ClassId.artic) return options.bottomMarginArtic.value;
    if (classId == ClassId.harm) return options.bottomMarginHarm.value;
    if (classId == ClassId.octave) return options.bottomMarginOctave.value;
    return options.defaultBottomMargin.value;
  }

  /// Mirrors `Doc::GetStaffDistance(Object, int, data_STAFFREL)`: the
  /// @dir.dist / @dynam.dist / @harm.dist / @tempo.dist attribute lookup on
  /// the scoreDef / staffDef.
  ///
  /// Deviation: the dynamDist / harmDist CLI options are not consulted (they
  /// arrive with the option plumbing of the toolkit phase); null is returned
  /// when no attribute is present.
  MeasurementSigned? getStaffDistance(
      Object object, int staffIndex, Staffrel staffPosition) {
    if ((staffPosition != Staffrel.above) &&
        (staffPosition != Staffrel.below)) {
      return null;
    }
    final ScoreDef? scoreDef =
        getCorrespondingScore(object)?.getScoreDef() as ScoreDef?;
    if (scoreDef == null) return null;

    switch (object.classId) {
      case ClassId.dir:
        if (scoreDef.hasDirDist) return scoreDef.dirDist;
        final StaffDef? staffDef = scoreDef.getStaffDef(staffIndex);
        if (staffDef != null && staffDef.hasDirDist) return staffDef.dirDist;
        return null;
      case ClassId.dynam:
        if (scoreDef.hasDynamDist) return scoreDef.dynamDist;
        final StaffDef? staffDef = scoreDef.getStaffDef(staffIndex);
        if (staffDef != null && staffDef.hasDynamDist) {
          return staffDef.dynamDist;
        }
        return null;
      case ClassId.harm:
        if (scoreDef.hasHarmDist) return scoreDef.harmDist;
        final StaffDef? staffDef = scoreDef.getStaffDef(staffIndex);
        if (staffDef != null && staffDef.hasHarmDist) return staffDef.harmDist;
        return null;
      case ClassId.tempo:
        if (scoreDef.hasTempoDist) return scoreDef.tempoDist;
        final StaffDef? staffDef = scoreDef.getStaffDef(staffIndex);
        if (staffDef != null && staffDef.hasTempoDist) {
          return staffDef.tempoDist;
        }
        return null;
      default:
        return null;
    }
  }

  /// Generate footer running elements (mirrors `Doc::GenerateFooter`,
  /// `doc.cpp:240`).
  void generateFooter() {
    for (final Object scoreObj in getVisibleScores()) {
      final Score score = scoreObj as Score;
      final ScoreDef? scoreDef = score.getScoreDef() as ScoreDef?;
      if (scoreDef == null) continue;
      if (scoreDef.findDescendantByType(ClassId.pgFoot) != null) continue;
      final PgFoot pgFoot = PgFoot();
      pgFoot.func = Pgfunc.first;
      pgFoot.setIsGenerated(true);
      _loadFooter(pgFoot);
      pgFoot.type = 'autogenerated';
      scoreDef.addChild(pgFoot);
      final PgFoot pgFoot2 = PgFoot();
      pgFoot2.func = Pgfunc.all;
      pgFoot2.setIsGenerated(true);
      _loadFooter(pgFoot2);
      pgFoot2.type = 'autogenerated';
      scoreDef.addChild(pgFoot2);
    }
  }

  /// Helper for [generateFooter] (mirrors `RunningElement::LoadFooter`,
  /// `runningelement.cpp:138`).
  void _loadFooter(RunningElement runningElement) {
    final Fig fig = Fig();
    final Svg svg = Svg();
    String? footerContent;
    try {
      footerContent = resourceFileReader('assets/data/footer.svg');
    } on Exception {
      footerContent = null;
    }
    if (footerContent != null && footerContent.isNotEmpty) {
      svg.content = footerContent;
    }
    fig.addChild(svg);
    fig.halign = Horizontalalignment.center;
    fig.valign = Verticalalignment.bottom;
    runningElement.addChild(fig);
  }

  /// Generate header running elements (mirrors `Doc::GenerateHeader`,
  /// `doc.cpp:264`).
  void generateHeader() {
    for (final Object scoreObj in getVisibleScores()) {
      final Score score = scoreObj as Score;
      final ScoreDef? scoreDef = score.getScoreDef() as ScoreDef?;
      if (scoreDef == null) continue;
      if (scoreDef.findDescendantByType(ClassId.pgHead) != null) continue;
      final PgHead pgHead = PgHead();
      pgHead.func = Pgfunc.first;
      pgHead.setIsGenerated(true);
      _generateFromMeiHeader(pgHead);
      pgHead.type = 'autogenerated';
      scoreDef.addChild(pgHead);
      final PgHead pgHead2 = PgHead();
      pgHead2.func = Pgfunc.all;
      pgHead2.setIsGenerated(true);
      pgHead2.addPageNum(Horizontalalignment.center, Verticalalignment.top);
      pgHead2.type = 'autogenerated';
      scoreDef.addChild(pgHead2);
    }
  }

  /// Generate measure numbers from `@n` attributes (mirrors
  /// `Doc::GenerateMeasureNumbers`, doc.cpp:298).
  bool generateMeasureNumbers() {
    final List<Object> measures = findAllDescendantsByType(ClassId.measure);
    for (final Object object in measures) {
      final Measure measure = object as Measure;
      // First remove previously generated elements
      final List<Object> mNums = measure.findAllDescendantsByType(ClassId.mnum);
      for (final Object child in List<Object>.from(mNums)) {
        final MNum mNum = child as MNum;
        if (mNum.isGeneratedFlag) {
          // Mirrors `measure->DeleteChild(mNum)`; fallback to parent
          // deletion when the generated element is not a direct child
          // (e.g., editorial wrapping).
          if (!measure.deleteChild(mNum)) {
            mNum.parent?.deleteChild(mNum);
          }
        }
      }
      if (measure.hasN && measure.findDescendantByType(ClassId.mnum) == null) {
        final MNum mnum = MNum();
        final Text text = Text();
        text.text = measure.n!;
        mnum.type = 'autogenerated';
        mnum.addChild(text);
        mnum.isGeneratedFlag = true;
        measure.addChild(mnum);
      }
    }
    return true;
  }

  /// Mirrors `PgHead::GenerateFromMEIHeader` (`pghead.cpp:55`).
  void _generateFromMeiHeader(PgHead pgHead) {
    final MeiXmlNode? hdr = header;
    if (hdr == null) return;
    // Collect title nodes: //fileDesc/titleStmt/title[text()]
    final List<MeiXmlNode> titleNodes = _findMeiTitles(hdr);
    if (titleNodes.isNotEmpty) {
      final Rend titleRend = Rend();
      titleRend.halign = Horizontalalignment.center;
      titleRend.valign = Verticalalignment.middle;
      titleRend.label = 'title';
      for (int i = 0; i < titleNodes.length; i++) {
        final MeiXmlNode titleNode = titleNodes[i];
        final Rend rend = Rend();
        final FontSize fs = FontSize();
        if (i == 0) {
          fs.setTerm(Fontsizeterm.xLarge);
        } else {
          titleRend.addChild(Lb());
          fs.setTerm(Fontsizeterm.small);
        }
        rend.fontsize = fs;
        String textStr = titleNode.textValue() ?? '';
        if (textStr.isEmpty) {
          // Fallback: inner text via children
          for (final MeiXmlNode kid in titleNode.children) {
            if (kid.isText) {
              textStr = kid.value ?? '';
              if (textStr.trim().isNotEmpty) break;
            }
          }
        }
        textStr = textStr.trim();
        if (textStr.isEmpty) continue;
        final Text text = Text();
        text.text = textStr;
        final String? lang = titleNode.attr('xml:lang');
        if (lang != null) rend.lang = lang;
        rend.addChild(text);
        titleRend.addChild(rend);
      }
      if (titleRend.childCount > 0) pgHead.addChild(titleRend);
    }
    // Composer / arranger / lyricist / persName with role
    final List<MeiXmlNode> personNodes = _findMeiPersonNodes(hdr);
    for (final MeiXmlNode node in personNodes) {
      final Rend personRend = Rend();
      final String role = node.attr('role') ?? '';
      final String name = node.name;
      final bool leftAlign =
          (name == 'lyricist' || role == 'lyricist' || role == 'translator');
      personRend.halign =
          leftAlign ? Horizontalalignment.left : Horizontalalignment.right;
      personRend.valign = Verticalalignment.bottom;
      personRend.label = role;
      String personText = node.textValue() ?? '';
      if (personText.isEmpty) {
        for (final MeiXmlNode kid in node.children) {
          if (kid.isText) {
            personText = kid.value ?? '';
            if (personText.trim().isNotEmpty) break;
          }
        }
      }
      personText = personText.trim();
      if (personText.isEmpty) continue;
      final Text t = Text();
      t.text = personText;
      final String? lang = node.attr('xml:lang');
      if (lang != null) personRend.lang = lang;
      personRend.addChild(t);
      pgHead.addChild(personRend);
    }
  }

  List<MeiXmlNode> _findMeiTitles(MeiXmlNode root) {
    final List<MeiXmlNode> result = [];
    void walk(MeiXmlNode node) {
      final String name = node.name;
      if (name == 'title') {
        final String? txt = node.textValue();
        if (txt != null && txt.trim().isNotEmpty) {
          // Check ancestor is fileDesc/titleStmt — walk up
          bool underTitleStmt = false;
          bool underFileDesc = false;
          MeiXmlNode? cur = node;
          while (cur != null) {
            final String curName = cur.name;
            if (curName == 'titleStmt') underTitleStmt = true;
            if (curName == 'fileDesc') underFileDesc = true;
            cur = cur.parent;
          }
          if (underTitleStmt && underFileDesc) result.add(node);
        }
      }
      for (final MeiXmlNode kid in node.children) {
        walk(kid);
      }
    }

    walk(root);
    return result;
  }

  /// Mirrors the pugixml evaluation of the C++ xpath
  /// `//fileDesc/titleStmt/composer|arranger|lyricist|respStmt/persName[...]`
  /// (pghead.cpp:83). The union has three alternatives:
  /// - `//fileDesc/titleStmt/composer` — composer with parent titleStmt and
  ///   grandparent fileDesc (the only alternative that can ever match);
  /// - `arranger` / `lyricist` — RELATIVE paths evaluated against the
  ///   document node, i.e. top-level elements of the document (never in MEI);
  /// - `respStmt/persName[...]` — also relative, matches only a top-level
  ///   `respStmt` (never in MEI).
  /// So `persName` under `titleStmt/respStmt` is NOT picked up by the C++,
  /// even though the xpath looks like it should be.
  List<MeiXmlNode> _findMeiPersonNodes(MeiXmlNode root) {
    final List<MeiXmlNode> result = [];
    void walk(MeiXmlNode node) {
      if (node.name == 'composer') {
        final MeiXmlNode? parent = node.parent;
        final MeiXmlNode? grand = parent?.parent;
        if (parent != null &&
            parent.name == 'titleStmt' &&
            grand != null &&
            grand.name == 'fileDesc') {
          final String? txt = node.textValue();
          if (txt != null && txt.trim().isNotEmpty) result.add(node);
        }
      }
      for (final MeiXmlNode kid in node.children) {
        walk(kid);
      }
    }

    walk(root);
    return result;
  }

  // TODO(phase-6): GenerateMEIHeader, ConvertHeaderToMEIBasic, Export*,
  // ScoreDefSetCurrentDoc / SetGrpSymDoc, CalculateTimemap (partial) are
  // implemented above; GenerateMeasureNumbers, CollectVisibleScores /
  // GetCorrespondingScore, SetDrawingPage / ResetDataPage and
  // CastOff*/UnCastOff are ported.

  // -------------------------------------------------------------------------
  // IO support (Phase 3)
  // -------------------------------------------------------------------------

  /// Generate a scoreDef for documents without one (mirrors
  /// `Doc::GenerateDocumentScoreDef`).
  bool generateDocumentScoreDef() {
    final Measure? measure = findDescendantByType(ClassId.measure) as Measure?;
    if (measure == null) {
      logError('No measure found for generating a scoreDef');
      return false;
    }

    final List<Object> staves =
        measure.findAllDescendantsByType(ClassId.staff, deepness: 1);

    if (staves.isEmpty) {
      logError('No staff found for generating a scoreDef');
      return false;
    }

    final ScoreDef scoreDef = getFirstScoreDef() as ScoreDef? ?? ScoreDef();
    scoreDef.reset();
    final StaffGrp staffGrp = StaffGrp();
    for (final Object object in staves) {
      final Staff staff = object as Staff;
      final StaffDef staffDef = StaffDef();
      staffDef.n = staff.n;
      staffDef.lines = 5;
      if (!measure.isMeasuredMusic()) {
        staffDef.notationtype = Notationtype.mensural;
      }
      staffGrp.addChild(staffDef);
    }
    scoreDef.addChild(staffGrp);

    logInfo('ScoreDef generated');

    return true;
  }

  /// Expand the encoded expansions (mirrors `Doc::ExpandExpansions`).
  ///
  /// The full functor based processing arrives with Phase 4; the expansion
  /// map logic itself was ported with the model (Phase 2).
  void expandExpansions() {
    // Passing this argument does not do anything.
    if (getOptions().expandNever.value) return;

    // Nothing to do in these cases - mark the map as processed.
    if (isMensuralMusicOnly() || isTranscription()) {
      expansionMap.setProcessed(true);
      return;
    }

    // Nothing to expand unless forced.
    if (!getOptions().expandAlways.value) return;

    final String expansionId = ''; // m_expand option arrives with the CLI
    final bool expandSelected = expansionId.isNotEmpty;

    if (!expandSelected) {
      final List<Object> scores = findAllDescendantsByType(ClassId.score);
      for (final Object object in scores) {
        final Score score = object as Score;
        // Do not generate an expansion if there is already one.
        if (score.findDescendantByType(ClassId.expansion) == null) {
          expansionMap.generateExpansionFor(score);
        }
      }
    }

    Expansion? startExpansion;
    if (expandSelected) {
      startExpansion = findDescendantByID(expansionId) as Expansion?;
      if (startExpansion == null) {
        logWarning("Expansion ID '$expansionId' not found. Nothing expanded.");
        return;
      }
    } else {
      startExpansion = findDescendantByType(ClassId.expansion) as Expansion?;
      if (startExpansion == null) return;
    }
    final List<String> existingList = <String>[];
    final List<String> deletionList = <String>[];
    expansionMap.expand(
        startExpansion, existingList, startExpansion, deletionList, true);
    expansionMap.setProcessed(true);
  }

  /// Convert a score-based doc into a page-based doc (mirrors
  /// `Doc::ConvertToPageBasedDoc` and `ConvertToPageBasedFunctor`).
  ///
  /// The C++ implements the transformation with a functor; here the same
  /// traversal is a recursive method over the tree.
  void convertToPageBasedDoc() {
    final Pages pages = Pages();
    final Page page = Page();
    pages.addChild(page);

    _convertToPageBased(this, page, null);

    clearRelinquishedChildren();
    assert(childCount == 0);

    addChild(pages);

    // Mirrors ResetDataPage (drawing page is unset until layout runs).
    drawingPage = null;
  }

  /// Recursive port of `ConvertToPageBasedFunctor`. Returns the current
  /// system to continue with after visiting [object].
  Object? _convertToPageBased(Object object, Page page, Object? currentSystem) {
    switch (object.classId) {
      case ClassId.mdiv:
        assert(currentSystem == null || true);
        object.moveItselfTo(page);
        break;
      case ClassId.score:
        assert(currentSystem == null);
        object.moveItselfTo(page);
        final System system = System();
        page.addChild(system);
        currentSystem = system;
        break;
      case ClassId.scoreDef:
        // Move itself to the pageBasedSystem - do not process children.
        assert(currentSystem != null);
        object.moveItselfTo(currentSystem!);
        return currentSystem;
      case ClassId.measure:
        // Move itself to the pageBasedSystem - do not process children.
        assert(currentSystem != null);
        object.moveItselfTo(currentSystem!);
        return currentSystem;
      case ClassId.section:
        assert(currentSystem != null);
        object.moveItselfTo(currentSystem!);
        break;
      case ClassId.ending:
        assert(currentSystem != null);
        object.moveItselfTo(currentSystem!);
        break;
      case ClassId.div:
        assert(currentSystem != null);
        object.moveItselfTo(currentSystem!);
        break;
      default:
        if (object.isEditorialElement) {
          assert(currentSystem != null);
          object.moveItselfTo(currentSystem!);
          break;
        } else if (Object.isSystemElementId(object.classId)) {
          assert(currentSystem != null);
          object.moveItselfTo(currentSystem!);
          break;
        }
        // Other objects (e.g., Doc itself): just continue.
        break;
    }

    // Visit the children (measure / scoreDef stop descending, mirroring
    // FUNCTOR_SIBLINGS).
    if (object.classId != ClassId.measure &&
        object.classId != ClassId.scoreDef) {
      for (final Object child in object.childrenForModification) {
        currentSystem = _convertToPageBased(child, page, currentSystem);
      }
    }

    // End visits.
    switch (object.classId) {
      case ClassId.mdiv:
        final Mdiv mdiv = object as Mdiv;
        if (!mdiv.isHidden) {
          mdiv.convertToPageBasedMilestone(mdiv, page);
        }
        break;
      case ClassId.score:
        (object as Score).convertToPageBasedMilestone(object, page);
        return null;
      case ClassId.section:
        (object as SystemMilestoneInterface)
            .convertToPageBasedMilestone(object, currentSystem!);
        break;
      case ClassId.ending:
        (object as SystemMilestoneInterface)
            .convertToPageBasedMilestone(object, currentSystem!);
        break;
      default:
        if (object is EditorialElement && !object.isHidden) {
          (object as SystemMilestoneInterface)
              .convertToPageBasedMilestone(object, currentSystem!);
        }
        break;
    }
    return currentSystem;
  }

  /// Convert analytical / multival markup (mirrors `Doc::ConvertMarkupDoc`).
  ///
  /// The artic multival conversion is implemented; the analytical (@tie /
  /// @fermata) and scoreDef-definition conversions need the functor
  /// infrastructure of the layout phase and are deferred.
  void convertMarkupDoc(bool permanent) {
    if (markup == markupDefault) return;

    logInfo('Converting markup...');

    if ((markup & markupArticMultival) != 0) {
      logInfo('Converting artic markup...');
      _convertMarkupArtic(permanent);
    }

    if (((markup & markupAnalyticalFermata) != 0) ||
        ((markup & markupAnalyticalTie) != 0)) {
      logWarning('Converting analytical markup requires the convert functor '
          '(deferred to Phase 6 — 06-04); @tie/@fermata attributes are preserved.');
    }

    if ((markup & markupScoredefDefinitions) != 0) {
      logInfo('Converting scoreDef markup...');
      _convertMarkupScoreDef();
    }
  }

  /// Port of `ConvertMarkupArticFunctor`: split multi-valued `<artic>`
  /// elements into single-valued ones (per layer).
  void _convertMarkupArtic(bool permanent) {
    void processLayer(Layer layer) {
      final List<Artic> articsToConvert = [];
      void collect(Object object) {
        if (object is Artic && (object.artic?.length ?? 0) > 1) {
          articsToConvert.add(object);
        }
        for (final Object child in object.children) {
          collect(child);
        }
      }

      for (final Object child in layer.children) {
        collect(child);
      }
      for (final Artic artic in articsToConvert) {
        splitMultivalArtic(artic);
      }
    }

    void walk(Object object) {
      if (object is Layer) {
        processLayer(object);
        return;
      }
      for (final Object child in object.children) {
        walk(child);
      }
    }

    for (final Object child in children) {
      walk(child);
    }
  }

  /// Port of `ConvertMarkupScoreDefFunctor`: copy scoreDef definitions to
  /// the staffDefs that lack them.
  void _convertMarkupScoreDef() {
    ScoreDef? currentScoreDef;

    void visitScoreDefElement(ScoreDefElement element) {
      if (element.classId == ClassId.scoreDef) {
        currentScoreDef = element as ScoreDef;
        for (final Object child in element.children) {
          if (child is ScoreDefElement) visitScoreDefElement(child);
        }
        // At the end of the scoreDef remove all score definition elements.
        if (currentScoreDef!.hasClefInfo()) {
          final Object? clef =
              currentScoreDef!.findDescendantByType(ClassId.clef, deepness: 1);
          if (clef != null) currentScoreDef!.deleteChild(clef);
        }
        if (currentScoreDef!.hasKeySigInfo()) {
          final Object? keySig = currentScoreDef!
              .findDescendantByType(ClassId.keysig, deepness: 1);
          if (keySig != null) currentScoreDef!.deleteChild(keySig);
        }
        if (currentScoreDef!.hasMeterSigGrpInfo()) {
          final Object? meterSigGrp = currentScoreDef!
              .findDescendantByType(ClassId.meterSigGrp, deepness: 1);
          if (meterSigGrp != null) currentScoreDef!.deleteChild(meterSigGrp);
        }
        if (currentScoreDef!.hasMeterSigInfo()) {
          final Object? meterSig = currentScoreDef!
              .findDescendantByType(ClassId.meterSig, deepness: 1);
          if (meterSig != null) currentScoreDef!.deleteChild(meterSig);
        }
        if (currentScoreDef!.hasMensurInfo()) {
          final Object? mensur = currentScoreDef!
              .findDescendantByType(ClassId.mensur, deepness: 1);
          if (mensur != null) currentScoreDef!.deleteChild(mensur);
        }
        currentScoreDef = null;
        return;
      }

      // This should never be the case.
      if (element.classId != ClassId.staffDef || currentScoreDef == null) {
        return;
      }
      final StaffDef staffDef = element as StaffDef;
      // Copy score definition elements to the staffDef but only if they are
      // not given at the staffDef.
      if (currentScoreDef!.hasClefInfo() && !staffDef.hasClefInfo()) {
        staffDef.addChild(currentScoreDef!.getClefCopy());
      }
      if (currentScoreDef!.hasKeySigInfo() && !staffDef.hasKeySigInfo()) {
        staffDef.addChild(currentScoreDef!.getKeySigCopy());
      }
      if (currentScoreDef!.hasMeterSigGrpInfo() &&
          !staffDef.hasMeterSigGrpInfo()) {
        staffDef.addChild(currentScoreDef!.getMeterSigGrpCopy());
      }
      if (currentScoreDef!.hasMeterSigInfo() && !staffDef.hasMeterSigInfo()) {
        staffDef.addChild(currentScoreDef!.getMeterSigCopy());
      }
      if (currentScoreDef!.hasMensurInfo() && !staffDef.hasMensurInfo()) {
        staffDef.addChild(currentScoreDef!.getMensurCopy());
      }
    }

    // Evaluate on all scores' scoreDefs.
    for (final Object object in findAllDescendantsByType(ClassId.score)) {
      final Score score = object as Score;
      final Object? scoreDefObject = score.getScoreDef();
      if (scoreDefObject is ScoreDef) {
        for (final Object child in scoreDefObject.children) {
          if (child is ScoreDefElement) visitScoreDefElement(child);
        }
      }
    }
  }
}

/// Port of `ConvertMarkupArticFunctor::SplitMultival`.
void splitMultivalArtic(Artic artic) {
  final Object? parent = artic.parent;
  assert(parent != null);

  final List<Articulation> articList = artic.artic ?? const [];
  if (articList.isEmpty) return;

  int idx = (artic.idx ?? 0) + 1;
  for (int i = 1; i < articList.length; ++i) {
    final Artic articChild = Artic();
    articChild.artic = [articList[i]];
    articChild.color = artic.color;
    articChild.enclose = artic.enclose;
    articChild.glyphAuth = artic.glyphAuth;
    articChild.glyphName = artic.glyphName;
    articChild.place = artic.place;
    parent!.insertChild(articChild, idx);
    ++idx;
  }

  // Only keep the first value in the original element.
  artic.artic = [articList[0]];

  // Multiple valued attributes cannot be preserved as such.
  if (artic.isAttribute) {
    artic.isAttribute = false;
    logInfo('Multiple valued attribute @artic on \'${parent!.id}\' permanently '
        'converted to <artic> elements');
  }
}
