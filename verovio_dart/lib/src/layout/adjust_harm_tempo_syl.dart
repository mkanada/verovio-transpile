/// Port of `adjustharmgrpsspacingfunctor.h/cpp`, `adjusttempofunctor.h/cpp`
/// and `adjustsylspacingfunctor.h/cpp`, plus the small helper methods of
/// `verse.cpp` (`Verse::AdjustPosition`) and `syl.cpp`
/// (`Syl::CalcConnectorSpacing`, `Syl::CalcHyphenLength`,
/// `Syl::AdjustToLyricSize`) that only these functors need. The helpers are
/// free functions here — not methods on [Verse] / [Syl] in
/// `layer_elements_gen.dart` — because they need [Doc], and `model/` must not
/// import `doc.dart` (import cycle); this mirrors the existing
/// `LayoutElementHelpers` extension in `preparedata_functor.dart`.
///
/// Deviations from the C++:
/// - [AdjustHarmGrpsSpacingFunctor] and [AdjustSylSpacingFunctor] depend
///   entirely on the *rendered* content bounding box of `Harm`/`Tempo`
///   positioners and `Syl` text runs. This port's headless text-extent
///   approximation (`headless_extents.dart`) gives `Harm`/`Tempo` a
///   zero-width box (`_processPointControlEvent`'s `x1 == x2`) and never
///   fills `Syl`'s content box at all, so the numeric overlaps this port
///   computes diverge from the C++ (real glyph widths) until the text
///   measurement of the rendering phase (task 05-12) lands. The branch
///   structure and the timing of every adjustment (immediate cross-measure
///   apply vs. queued for `VisitMeasureEnd`/`VisitSystemEnd`) are ported
///   faithfully and verified against synthetic content boxes reproducing the
///   fixture's recorded values — see `test/adjust_harm_tempo_syl_test.dart`.
/// - `Syl::CalcHyphenLength` (word-connector spacing) and the elision
///   `GetGlyphAdvX` branch of `Syl::CalcConnectorSpacing` need text-font /
///   SMuFL advance-width metrics beyond what this phase ports; they are
///   approximated from the drawing unit (see [calcHyphenLength]). Neither
///   branch is exercised by `lyric-001.mei` / `lyric-004.mei` (no
///   `@wordpos="i"/"m"`, no elisions), so the approximation does not affect
///   this task's fixtures.
///
/// Two more gaps surfaced while comparing production runs against the
/// fixtures, both pre-existing and out of scope for this task (see
/// `prompts/reports/04e.md` for the full analysis):
/// - [Page.adjustSylSpacingByVerse]'s per-`(staff,layer,verse)` `Filters`
///   never match a `<verse>` without `@n` (the common case — both
///   `lyric-001.mei` and `lyric-004.mei` are affected): the verse tree keys
///   an absent `@n` as `0`, but `AttNIntegerComparison` compares against the
///   raw (nullable) attribute, and an absent `@n` reads back as `null`, never
///   `0`. So [AdjustSylSpacingFunctor] never visits a real `Verse` in
///   production today, on top of the content-box gap above.
/// - `harm/harm-001.mei`'s eleven `@tstamp`-anchored harms land at
///   X positions offset from the C++ reference by a measure-constant delta
///   (relative spacing between harms in the same measure matches exactly);
///   `tempo/tempo-001.mei`'s tempo sits in an upbeat measure whose `@tstamp`
///   point-resolution logs "time pointing element(s) could not be matched"
///   and lands at the wrong position. Neither is new: both predate this
///   task's functors and live in earlier-phase alignment/tstamp code.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/logging.dart' show logDebug;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart' show SystemAligner;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show SyllogCon, SyllogWordpos;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Measure, Staff;
import 'package:verovio_dart/src/model/comparison.dart'
    show MeasureAlignerTypeComparison;
import 'package:verovio_dart/src/model/control_elements_gen.dart'
    show Harm, Tempo;
import 'package:verovio_dart/src/model/doc.dart' show Doc;
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Syl, Verse;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

// ---------------------------------------------------------------------------
// AdjustHarmGrpsSpacingFunctor
// ---------------------------------------------------------------------------

/// This class adjusts the horizontal position of harms by groups in order to
/// avoid overlapping (mirrors `vrv::AdjustHarmGrpsSpacingFunctor`).
class AdjustHarmGrpsSpacingFunctor extends DocFunctor {
  AdjustHarmGrpsSpacingFunctor(super.doc);

  /// The grpIds of harms in the system (mirrors `m_grpIds`).
  final List<int> grpIds = [];

  /// The current grp id, 0 for the first (collection) pass (mirrors
  /// `m_currentGrp`).
  int currentGrp = 0;

  /// The adjustment tuples (start alignment, end alignment, distance)
  /// (mirrors `m_overlappingHarm`).
  List<(Alignment, Alignment, int)> overlappingHarm = [];

  /// The previous harm positioner, if any (mirrors `m_previousHarmPositioner`).
  FloatingPositioner? previousHarmPositioner;

  /// The previous harm start, if any (mirrors `m_previousHarmStart`).
  LayerElement? previousHarmStart;

  /// The previous measure, if any (mirrors `m_previousMeasure`).
  Measure? previousMeasure;

  /// The current system (mirrors `m_currentSystem`).
  System? currentSystem;

  @override
  FunctorCode visitHarm(Harm harm) {
    final int currentGrpId = harm.drawingGrpId;

    // No group ID, nothing to do - should probably never happen
    if (currentGrpId == 0) {
      return FunctorCode.siblings;
    }

    // We are filling the array of grp ids for the system
    if (currentGrp == 0) {
      if (!grpIds.contains(currentGrpId)) {
        grpIds.add(currentGrpId);
      }
      // This is it for this pass
      return FunctorCode.siblings;
    }
    // We are processing harm for a grp Id which is not the current one, skip it
    else if (currentGrpId != currentGrp) {
      return FunctorCode.siblings;
    }

    /************** Find the widest positioner **************/

    // Get all the positioners for this object - all of them (all staves)
    // because we can have different staff sizes
    final List<FloatingPositioner> positioners = [];
    currentSystem!.systemAligner
        .findAllPositionerPointingTo(positioners, harm);

    FloatingPositioner? harmPositioner;
    // Something is probably not right if nothing found - maybe no @staff
    if (positioners.isEmpty) {
      logDebug(
          "Something was wrong when searching positioners for ${harm.className} '${harm.id}'");
      return FunctorCode.siblings;
    }

    // Keep the one with the lowest left position (this will also be the widest)
    for (final FloatingPositioner positioner in positioners) {
      if (harmPositioner == null ||
          harmPositioner.getContentLeft() > positioner.getContentLeft()) {
        harmPositioner = positioner;
      }
    }

    // If the harm positioner is missing or is empty, do not adjust spacing
    if (harmPositioner == null || !harmPositioner.hasContentBB()) {
      return FunctorCode.siblings;
    }

    final LayerElement harmStart = harm.getStart() as LayerElement;

    // If we have more than one harm at the same position, do not adjust them
    // This situation makes sense when the first of them is right aligned
    if (previousHarmStart != null && identical(previousHarmStart, harmStart)) {
      previousHarmPositioner = harmPositioner;
      return FunctorCode.siblings;
    }

    /************** Calculate the adjustment **************/

    // First harm in the system
    if (previousMeasure == null && previousHarmPositioner == null) {
      // Check that is it not overflowing the beginning of the measure
      final int overflow =
          harmStart.getDrawingX() + harmPositioner.getContentX1();
      final Measure? measure =
          harm.getFirstAncestor(ClassId.measure) as Measure?;
      if (overflow < 0 && measure != null) {
        overlappingHarm.add((
          measure.getLeftBarLine().getAlignment()!,
          harmStart.getAlignment()!,
          -overflow
        ));
      }
    }

    // Not much to do when we hit the first harm of the system
    if (previousHarmPositioner == null) {
      previousHarmStart = harmStart;
      previousHarmPositioner = harmPositioner;
      previousMeasure = null;
      return FunctorCode.siblings;
    }

    int xShift = 0;

    // We have a previous harm from the previous measure - we need to add the
    // measure width because the measures are not aligned yet
    if (previousMeasure != null) {
      xShift = previousMeasure!.getWidth();
    }

    int overlap = previousHarmPositioner!.getContentRight() -
        (harmPositioner.getContentLeft() + xShift);
    // Two units as default spacing
    int wordSpace = 2 * doc.getDrawingUnit(100);
    wordSpace = adjustToLyricSize(doc, wordSpace);
    overlap += wordSpace;

    if (overlap > 0) {
      // We are adjusting harms in two different measures - move only the
      // right barline of the first measure
      if (previousMeasure != null) {
        overlappingHarm.add((
          previousHarmStart!.getAlignment()!,
          previousMeasure!.getRightBarLine().getAlignment()!,
          overlap
        ));
        // Do it now
        previousMeasure!.measureAligner.adjustProportionally(overlappingHarm);
        overlappingHarm = [];
      } else {
        // Normal case, both in the same measure
        overlappingHarm.add((
          previousHarmStart!.getAlignment()!,
          harmStart.getAlignment()!,
          overlap
        ));
      }
    }

    previousHarmStart = harmStart;
    previousHarmPositioner = harmPositioner;
    previousMeasure = null;

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    // At the end of the measure - pass it along for overlapping verses
    previousMeasure = measure;

    // Adjust the position of the alignment according to what we have
    // collected for this harm grp
    measure.measureAligner.adjustProportionally(overlappingHarm);
    overlappingHarm = [];

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    // reset it, but not the current grpId!
    currentSystem = system;
    overlappingHarm = [];
    previousHarmPositioner = null;
    previousHarmStart = null;
    previousMeasure = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemEnd(System system) {
    // End of the first pass - loop over for each group id
    if (currentGrp == 0) {
      for (final int grpId in grpIds) {
        currentGrp = grpId;
        system.process(this);
      }
      // Make sure we reset it for the next system
      currentGrp = 0;
      return FunctorCode.continue_;
    }

    /************** End of a system when actually adjusting **************/

    if (previousMeasure == null) {
      return FunctorCode.continue_;
    }

    // Here we also need to handle the last harm of the measure - we check
    // the alignment with the right barline
    if (previousHarmPositioner != null) {
      final Object? positionerObject = previousHarmPositioner!.getObject();
      // We do this only if the harm is in the last measure
      if (identical(
          previousMeasure, positionerObject?.getFirstAncestor(ClassId.measure))) {
        final int overlap = previousHarmPositioner!.getContentRight() -
            previousMeasure!.getRightBarLine().getAlignment()!.getXRel();

        if (overlap > 0) {
          overlappingHarm.add((
            previousHarmStart!.getAlignment()!,
            previousMeasure!.getRightBarLine().getAlignment()!,
            overlap
          ));
        }
      }
    }

    // Adjust the position of the alignment according to what we have
    // collected for this harm group id
    previousMeasure!.measureAligner.adjustProportionally(overlappingHarm);
    overlappingHarm = [];

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// AdjustTempoFunctor
// ---------------------------------------------------------------------------

/// This class adjusts the X position of tempi (mirrors
/// `vrv::AdjustTempoFunctor`).
class AdjustTempoFunctor extends DocFunctor {
  AdjustTempoFunctor(super.doc);

  /// The systemAligner (mirrors `m_systemAligner`).
  SystemAligner? systemAligner;

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitSystem(System system) {
    systemAligner = system.systemAligner;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTempo(Tempo tempo) {
    // Get all the positioners for this object - all of them (all staves)
    // because we can have different staff sizes
    final List<FloatingPositioner> positioners = [];
    systemAligner!.findAllPositionerPointingTo(positioners, tempo);

    if (positioners.isEmpty) {
      return FunctorCode.siblings;
    }

    final Measure measure =
        tempo.getFirstAncestor(ClassId.measure) as Measure;
    final MeasureAlignerTypeComparison alignmentComparison =
        MeasureAlignerTypeComparison(AlignmentType.scoreDefMeterSig);
    final Alignment? pos = measure.measureAligner
        .findDescendantByComparison(alignmentComparison, deepness: 1)
        as Alignment?;

    for (final FloatingPositioner positioner in positioners) {
      final int start = (tempo.getStart() as LayerElement).getDrawingX();
      final int staffN =
          positioner.getStaffAlignment()!.getStaff()!.n ?? meiUnset;
      int left;
      if (!tempo.hasStartid && (tempo.tstamp ?? -1.0) <= 1 && pos != null) {
        left = measure.getDrawingX() + pos.getXRel();
      } else {
        final Alignment align = (tempo.getStart() as LayerElement).getAlignment()!;
        final (int minLeft, _) = align.getLeftRight(staffN);
        left = minLeft;
      }

      if (left.abs() != meiUnset.abs()) {
        tempo.setDrawingXRelative(staffN, left - start);
      }
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// AdjustSylSpacingFunctor
// ---------------------------------------------------------------------------

/// This class adjusts the spacing of the syl processing verse by verse
/// (mirrors `vrv::AdjustSylSpacingFunctor`).
class AdjustSylSpacingFunctor extends DocFunctor {
  AdjustSylSpacingFunctor(super.doc);

  /// List of adjustment tuples (start alignment, end alignment, distance)
  /// (mirrors `m_overlappingSyl`).
  List<(Alignment, Alignment, int)> overlappingSyl = [];

  /// The previous verse (mirrors `m_previousVerse`).
  Verse? previousVerse;

  /// The previous syl (mirrors `m_lastSyl`).
  Syl? lastSyl;

  /// The previous measure (mirrors `m_previousMeasure`).
  Measure? previousMeasure;

  /// The current LabelAbbr (mirrors `m_currentLabelAbbr`).
  Object? currentLabelAbbr;

  /// Amount of free space (mirrors `m_freeSpace`).
  int freeSpace = 0;

  /// The staff size (mirrors `m_staffSize`).
  int staffSize = 100;

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    // At the end of the measure - pass it along for overlapping verses
    previousMeasure = measure;

    // Adjust the position of the alignment according to what we have
    // collected for this verse
    measure.measureAligner.adjustProportionally(overlappingSyl);
    overlappingSyl = [];

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    // Set the staff size for this pass
    staffSize = staff.drawingStaffSize;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    // reset it
    overlappingSyl = [];
    previousVerse = null;
    previousMeasure = null;
    freeSpace = 0;
    staffSize = 100;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemEnd(System system) {
    if (previousMeasure == null) {
      return FunctorCode.continue_;
    }

    // Here we also need to handle the last syl of the measure - we check the
    // alignment with the right barline
    if (previousVerse != null && lastSyl != null) {
      final int overlapIn = lastSyl!.getContentRight() -
          previousMeasure!.getRightBarLine().getAlignment()!.getXRel();
      // The C++ discards AdjustPosition's returned `nextFreeSpace` here; only
      // the by-reference mutation of `overlap` is used below.
      final int overlap =
          adjustVersePosition(previousVerse!, overlapIn, freeSpace, doc).overlap;

      // If the previous verse was not in the previous measure (but before),
      // ignore the overlap because it is not likely to go over the whole
      // following measure
      if (identical(previousMeasure,
              previousVerse!.getFirstAncestor(ClassId.measure)) &&
          overlap > 0) {
        overlappingSyl.add((
          previousVerse!.getAlignment()!,
          previousMeasure!.getRightBarLine().getAlignment()!,
          overlap
        ));
      }
    }

    // Adjust the position of the alignment according to what we have
    // collected for this verse
    previousMeasure!.measureAligner.adjustProportionally(overlappingSyl);
    overlappingSyl = [];

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitVerse(Verse verse) {
    /****** find label / labelAbbr */

    // If we have a <label>, reset the previous abbreviation
    if (verse.findDescendantByType(ClassId.label) != null) {
      currentLabelAbbr = null;
    }

    bool newLabelAbbr = false;
    verse.drawingLabelAbbr = null;
    // Find the labelAbbr (if none previously given)
    if (currentLabelAbbr == null) {
      currentLabelAbbr = verse.findDescendantByType(ClassId.labelAbbr);
      // Keep indication that this is a new abbreviation and that it should
      // not be displayed on this verse
      newLabelAbbr = true;
    }

    /*******/

    final List<Object> allSyls =
        verse.findAllDescendantsByType(ClassId.syl);

    int shift = doc.getDrawingUnit(staffSize);
    shift = adjustToLyricSize(doc, shift);

    int previousSylShift = 0;

    verse.setDrawingXRel(-1 * shift);

    final List<Syl> syls = [];
    for (final Object object in allSyls) {
      if (object.hasContentHorizontalBB()) {
        final Syl syl = object as Syl;
        syl.setDrawingXRel(previousSylShift);
        previousSylShift +=
            syl.getContentX2() + calcSylConnectorSpacing(syl, doc, staffSize);
        syls.add(syl);
      }
    }

    if (syls.isEmpty) return FunctorCode.continue_;

    final Syl firstSyl = syls.first;
    // We keep a pointer to the last syl because we move it (when more than
    // one) and the verse content bounding box is not updated
    final Syl lastSylOfVerse = syls.last;

    // Not much to do when we hit the first syllable of the system
    if (previousVerse == null) {
      previousVerse = verse;
      lastSyl = lastSylOfVerse;

      if (!newLabelAbbr && currentLabelAbbr != null) {
        verse.drawingLabelAbbr = currentLabelAbbr;
      }

      // No free space because we never move the first one back
      freeSpace = 0;
      previousMeasure = null;
      return FunctorCode.continue_;
    }

    int xShift = 0;

    // We have a previous syllable from the previous measure - we need to add
    // the measure width because the measures are not aligned yet
    if (previousMeasure != null) {
      xShift = previousMeasure!.getWidth();
    }

    // Use the syl because the content bounding box of the verse might be
    // invalid at this stage
    int overlap = lastSyl!.getContentRight() - (firstSyl.getContentLeft() + xShift);
    overlap += calcSylConnectorSpacing(lastSyl!, doc, staffSize);

    // Check that we also include the space for the label if the verse has a
    // new label
    final Object? label = verse.findDescendantByType(ClassId.label);
    if (label != null) {
      overlap += (label.getContentX2() - label.getContentX1()) +
          doc.getDrawingDoubleUnit(staffSize);
    }

    final ({int nextFreeSpace, int overlap}) adjustResult =
        adjustVersePosition(previousVerse!, overlap, freeSpace, doc);
    final int nextFreeSpace = adjustResult.nextFreeSpace;
    overlap = adjustResult.overlap;

    if (overlap > 0) {
      // We are adjusting syl in two different measures - move only the
      // right barline of the first measure
      if (previousMeasure != null) {
        overlappingSyl.add((
          previousVerse!.getAlignment()!,
          previousMeasure!.getRightBarLine().getAlignment()!,
          overlap
        ));
        // Do it now
        previousMeasure!.measureAligner.adjustProportionally(overlappingSyl);
        overlappingSyl = [];
      } else {
        // Normal case, both in the same measure
        overlappingSyl.add(
            (previousVerse!.getAlignment()!, verse.getAlignment()!, overlap));
      }
    }

    previousVerse = verse;
    lastSyl = lastSylOfVerse;
    freeSpace = nextFreeSpace;
    previousMeasure = null;

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// Shared helpers (mirrors small methods of `verse.cpp` / `syl.cpp`)
// ---------------------------------------------------------------------------

/// Mirrors `Verse::AdjustPosition`.
///
/// The C++ signature takes `overlap` by reference and returns
/// `nextFreeSpace`; Dart cannot express the by-reference mutation, so both
/// outputs are returned as a record.
({int nextFreeSpace, int overlap}) adjustVersePosition(
    Verse verse, int overlap, int freeSpace, Doc doc) {
  int nextFreeSpace = 0;

  if (overlap > 0) {
    // We have enough space to absorb the overlay completely
    if (freeSpace > overlap) {
      verse.setDrawingXRel(verse.drawingXRel - overlap);
      // The space is set to 0. This means that consecutive overlaps will not
      // be recursively absorbed. Only the first preceding syl will be moved.
      overlap = 0;
    } else if (freeSpace > 0) {
      verse.setDrawingXRel(verse.drawingXRel - freeSpace);
      overlap -= freeSpace;
    }
  } else {
    nextFreeSpace = math.min(-overlap, 3 * doc.getDrawingUnit(100));
  }

  return (nextFreeSpace: nextFreeSpace, overlap: overlap);
}

/// Mirrors `Syl::CalcConnectorSpacing`.
int calcSylConnectorSpacing(Syl syl, Doc doc, int staffSize) {
  final SyllogWordpos pos = syl.wordpos ?? SyllogWordpos.none;
  final SyllogCon con = syl.con ?? SyllogCon.none;

  int spacing = 0;

  // We have a word connector - the space have to be wide enough
  if (pos == SyllogWordpos.i || pos == SyllogWordpos.m) {
    spacing = 2 * calcHyphenLength(doc, staffSize);
  }
  // Elision
  else if (con == SyllogCon.b) {
    if (doc.getOptions().lyricElision.value == unicodeUndertie) {
      // Equivalent spacing with 0x230F
      spacing = (doc.getDrawingUnit(staffSize) * 2.2).toInt();
    } else {
      // Calculate the elision space with the current music font
      spacing =
          doc.getGlyphAdvX(doc.getOptions().lyricElision.value, staffSize, false);
      spacing = adjustToLyricSize(doc, spacing);
    }
  }
  // Spacing of words as set in the staff according to the staff and font sizes
  else {
    spacing = (doc.getDrawingUnit(staffSize) *
            doc.getOptions().lyricWordSpace.value)
        .toInt();
    spacing = adjustToLyricSize(doc, spacing);
  }

  return spacing;
}

/// Mirrors `Syl::CalcHyphenLength`.
///
/// Deviation: `Doc::GetTextGlyphWidth` (the real lyric-font hyphen width)
/// needs text-font glyph metrics not ported by this phase; the hyphen width
/// is approximated from the drawing unit. Not exercised by the 04e corpus.
int calcHyphenLength(Doc doc, int staffSize) {
  int dashLength = doc.getDrawingUnit(staffSize) ~/ 2;
  dashLength = adjustToLyricSize(doc, dashLength);
  return dashLength;
}

/// Mirrors `Syl::AdjustToLyricSize`.
int adjustToLyricSize(Doc doc, int value) {
  final lyricSize = doc.getOptions().lyricSize;
  return (value * lyricSize.value / lyricSize.defaultValue).toInt();
}
