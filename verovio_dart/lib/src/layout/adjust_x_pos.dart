/// Port of the x position adjustment functors invoked at the end of
/// `Page::LayOutHorizontally`:
///
/// - [AdjustXPosFunctor] mirrors `adjustxposfunctor.h/cpp`
/// - [AdjustGraceXPosFunctor] mirrors `adjustgracexposfunctor.h/cpp`
/// - [AdjustClefChangesFunctor] mirrors `adjustclefchangesfunctor.h/cpp`
///
/// Deviations from the C++ (all caused by the missing render pass that fills
/// the element bounding boxes):
/// - Elements without a rendered bounding box fall back to their alignment
///   position, exactly like the C++ does for empty bounding boxes; the
///   overlap based nesting is therefore inactive until the resources phase.
/// - The tie endpoint adjustments (`Measure::GetInternalTieEndpoints`) are
///   not ported; they require the tie drawing geometry.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset, MeiDuration;
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/smufl.dart' show smuflE220Tremolo1;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, AlignmentReference, GraceAligner, MeasureAligner;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/comparison.dart'
    show
        AttNIntegerAnyComparison,
        CrossAlignmentReferenceComparison,
        Filters,
        FiltersType,
        MeasureAlignerTypeComparison;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Notationtype, Stemdirection, Stemmodifier;
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show MeasurementType;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show MultiRest;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;

// ---------------------------------------------------------------------------
// AdjustXPosFunctor
// ---------------------------------------------------------------------------

/// Holds information about an alignment, a possible offset and an overlapping
/// bounding box (mirrors the public struct `vrv::AdjustXPosAlignmentOffset`).
class AdjustXPosAlignmentOffset {
  Alignment? alignment;
  int offset = 0;
  BoundingBox? overlappingBB;

  void reset() {
    alignment = null;
    offset = 0;
    overlappingBB = null;
  }
}

/// This class adjusts the X positions of the staff content by looking at the
/// bounding boxes (mirrors `vrv::AdjustXPosFunctor`).
///
/// The functor processes by aligned-staff content, that is from a redirection
/// in the MeasureAligner and then staff by staff but taking into account
/// cross-staff elements.
class AdjustXPosFunctor extends DocFunctor {
  AdjustXPosFunctor(super.doc) {
    rightBarLinesOnly = false;
  }

  /// The minimum position, i.e., the width of the previous element (mirrors
  /// `m_minPos`).
  int minPos = 0;

  /// The upcoming minimum position for the next element (mirrors
  /// `m_upcomingMinPos`).
  int upcomingMinPos = meiUnset;

  /// The cumulated shift on the previous aligners (mirrors
  /// `m_cumulatedXShift`).
  int cumulatedXShift = 0;

  /// The current staff @n (mirrors `m_staffN`).
  int staffN = 0;

  /// The current staff size (mirrors `m_staffSize`).
  int staffSize = 100;

  /// Whether the current staff is neume (mirrors `m_isNeumeStaff`).
  bool isNeumeStaff = false;

  /// The list of staffN in the top-level scoreDef (mirrors `m_staffNs`).
  List<int> staffNs = [];

  /// The bounding boxes in the previous aligner (mirrors
  /// `m_boundingBoxes`).
  final List<BoundingBox> boundingBoxes = [];

  /// The upcoming bounding boxes, to be used in the next aligner (mirrors
  /// `m_upcomingBoundingBoxes`).
  final List<BoundingBox> upcomingBoundingBoxes = [];

  /// The list of types to include / exclude (mirrors `m_includes` /
  /// `m_excludes`).
  List<ClassId> includes = [];
  List<ClassId> excludes = [];

  /// Only handle right positioned barlines (mirrors
  /// `m_rightBarLinesOnly`).
  bool rightBarLinesOnly = false;

  /// The current measure (mirrors `m_measure`).
  Measure? measure;

  /// The current and previous alignment offsets (mirrors
  /// `m_currentAlignment` / `m_previousAlignment`).
  final AdjustXPosAlignmentOffset currentAlignment =
      AdjustXPosAlignmentOffset();
  final AdjustXPosAlignmentOffset previousAlignment =
      AdjustXPosAlignmentOffset();

  // Deviation: m_measureTieEndpoints is not ported (requires tie geometry).

  void setIncluded(List<ClassId> classIds) => includes = classIds;
  void clearIncluded() => includes = [];
  void setExcluded(List<ClassId> classIds) => excludes = classIds;
  void clearExcluded() => excludes = [];
  void setRightBarLinesOnly(bool value) => rightBarLinesOnly = value;

  @override
  FunctorCode visitAlignment(Alignment alignment) {
    // Ossia scoreDef should not be aligned because that is taken care of in
    // the dedicated functor
    if (alignment.getType().value < AlignmentType.measureStart.value) {
      return FunctorCode.siblings;
    }

    alignment.setXRel(alignment.getXRel() + cumulatedXShift);

    if ((alignment.getType() == AlignmentType.measureEnd) &&
        (alignment.getXRel() < minPos)) {
      alignment.setXRel(minPos);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitAlignmentEnd(Alignment alignment) {
    if (upcomingMinPos != meiUnset) {
      minPos = upcomingMinPos;
      // We reset it for the next aligner
      upcomingMinPos = meiUnset;
    }

    // No upcoming bounding boxes, we keep the previous ones (e.g., the
    // alignment has nothing for this staff). Eventually we might want to have
    // a more sophisticated pruning algorithm.
    if (upcomingBoundingBoxes.isEmpty) return FunctorCode.continue_;

    // Handle additional offsets that can happen when we have overlapping
    // dots/flags. This should happen only for default alignments, so other
    // ones should be ignored. If there is at least one bounding box that
    // overlaps with dot/flag from the previous alignment - we need to consider
    // an additional offset for those elements. In such case, all current
    // elements should have their XRel adjusted (as they would normally have)
    // and increase minXPosition by the dot/flag offset.
    final BoundingBox? overlappingBB = previousAlignment.overlappingBB;
    if (overlappingBB != null &&
        previousAlignment.alignment != null &&
        (previousAlignment.alignment!.getType() == AlignmentType.default_)) {
      final bool hasOverlap = upcomingBoundingBoxes.any((BoundingBox bb) {
        if (identical(overlappingBB, bb)) return false;
        // check if elements actually overlap
        return bb.horizontalSelfOverlap(overlappingBB) &&
            bb.verticalSelfOverlap(overlappingBB);
      });
      if (hasOverlap) {
        currentAlignment.alignment!.setXRel(
            currentAlignment.alignment!.getXRel() + previousAlignment.offset);
        minPos += previousAlignment.offset;
        cumulatedXShift += previousAlignment.offset;
      }
    }
    previousAlignment.alignment = currentAlignment.alignment;
    previousAlignment.offset = currentAlignment.offset;
    previousAlignment.overlappingBB = currentAlignment.overlappingBB;
    // Reset current alignment
    currentAlignment.reset();

    boundingBoxes.clear();
    boundingBoxes.addAll(upcomingBoundingBoxes);
    upcomingBoundingBoxes.clear();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    // we should have processed aligned before
    assert(layerElement.getAlignment() != null);

    if (!layerElement.hasToBeAligned) {
      // if nothing to do with this type of element
      // this happens for example with Artic where only ArticPart children
      // are aligned
      return FunctorCode.siblings;
    }

    // If we have a list of types to exclude and it is one of them, stop it
    if (excludes.isNotEmpty && layerElement.isAny(excludes.toSet())) {
      return FunctorCode.continue_;
    }

    // If we have a list of types to include and it is not one of them,
    // stop it
    if (includes.isNotEmpty && !layerElement.isAny(includes.toSet())) {
      return FunctorCode.continue_;
    }

    // If desired only handle barlines which are right positioned
    if (rightBarLinesOnly && layerElement.classId == ClassId.barLine) {
      final BarLine barLine = layerElement as BarLine;
      if (barLine.getPosition() != BarlinePosition.right) {
        return FunctorCode.continue_;
      }
    }

    if (layerElement.hasSameasLink) {
      // nothing to do when the element has a @sameas attribute
      return FunctorCode.siblings;
    }

    if ((layerElement.getAlignment()!.getType() == AlignmentType.clef) &&
        !isNeumeStaff) {
      return FunctorCode.continue_;
    }

    int offset = 0;
    int selfLeft;
    final int drawingUnit = doc.getDrawingUnit(staffSize);
    final (int calculatedOffset, int calculatedSelfLeft) =
        calculateXPosOffset(layerElement);
    offset = calculatedOffset;
    selfLeft = calculatedSelfLeft;

    offset = math.min(offset, selfLeft - minPos);
    if (offset < 0) {
      layerElement
          .getAlignment()!
          .setXRel(layerElement.getAlignment()!.getXRel() - offset);
      // Also move the accumulated x shift and the minimum position for the
      // next alignment accordingly
      cumulatedXShift += -offset;
      upcomingMinPos += -offset;
    }

    int selfRight;
    if (!layerElement.hasSelfBB() || layerElement.hasEmptyBB()) {
      selfRight = layerElement.getAlignment()!.getXRel();
      // Still add the right margin for the barlines but not with non measure
      // music
      if (layerElement.classId == ClassId.barLine &&
          measure!.isMeasuredMusic()) {
        selfRight += doc.getRightMarginOf(layerElement).toInt() * drawingUnit;
      }
    } else {
      selfRight = layerElement.getSelfRight() +
          doc.getRightMarginOf(layerElement).toInt() * drawingUnit;
    }

    // In case of dots/flags we need to hold off adjusting the upcoming min
    // position right away - if it happens that these elements do not overlap
    // with other elements we can draw them as is and save space
    final AlignmentReference? currentReference = layerElement
        .getAlignment()!
        .getReferenceWithElement(layerElement, staffN);
    final Object? parent = layerElement.getAlignment()!.parent;
    final Alignment? nextAlignment = parent?.getNextSibling(
        layerElement.getAlignment()!, ClassId.alignment) as Alignment?;
    final AlignmentType next =
        nextAlignment?.getType() ?? AlignmentType.default_;

    if (layerElement.isAny({ClassId.dots, ClassId.flag}) &&
        (currentReference?.hasMultipleLayer() ?? false) &&
        (next != AlignmentType.measureRightBarline)) {
      final int additionalOffset = selfRight - upcomingMinPos;
      if (additionalOffset > currentAlignment.offset) {
        currentAlignment.offset = additionalOffset;
        currentAlignment.overlappingBB = layerElement;
      }
    } else if (layerElement.classId == ClassId.note &&
        next == AlignmentType.measureRightBarline) {
      final Note note = layerElement as Note;
      if (note.hasStemMod &&
          (note.stemMod!.index < Stemmodifier.values.length) &&
          (note.getDrawingStemDir() == Stemdirection.up)) {
        final int adjust = drawingUnit;
        cumulatedXShift += adjust;
        upcomingMinPos += adjust;
      } else {
        upcomingMinPos = math.max(selfRight, upcomingMinPos);
      }
    } else {
      upcomingMinPos = math.max(selfRight, upcomingMinPos);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    minPos = 0;
    upcomingMinPos = meiUnset;
    cumulatedXShift = 0;

    this.measure = measure;

    final System? system = measure.getFirstAncestor(ClassId.system) as System?;
    assert(system != null);

    final bool hasSystemStartLine = measure.isFirstInSystem() &&
        (system?.drawingScoreDef?.hasSystemStartLine() ?? false);

    final Filters filters = Filters();
    final Filters? previousFilters = setFilters(filters);

    for (final int staffN in staffNs) {
      minPos = 0;
      upcomingMinPos = meiUnset;
      cumulatedXShift = 0;
      this.staffN = staffN;
      boundingBoxes.clear();
      previousAlignment.reset();
      currentAlignment.reset();
      final StaffAlignment? staffAlignment =
          system!.systemAligner.getStaffAlignmentForStaffN(staffN);
      staffSize = staffAlignment?.getStaffSize() ?? 100;
      isNeumeStaff = _staffIsNeume(staffAlignment);

      // Prevent collisions of scoredef clefs with thick barlines
      if (hasSystemStartLine) {
        upcomingMinPos = doc.getDrawingBarLineWidth(staffSize);
      }

      filters.clear();
      filters.setType(FiltersType.anyOf);
      // Create ad comparison object for each type / @n
      // -1 for barline attributes that need to be taken into account each time
      filters.add(
          AttNIntegerAnyComparison(ClassId.alignmentReference, [-1, staffN]));
      filters.add(CrossAlignmentReferenceComparison());

      measure.measureAligner.process(this);
    }

    setFilters(previousFilters);

    // There is no reason to adjust a minimum width with mensural music
    if (!measure.isMeasuredMusic()) return FunctorCode.siblings;

    int minMeasureWidth =
        (doc.getOptions().unit.value * doc.getOptions().measureMinWidth.value)
            .toInt();

    // First try to see if we have a double measure length element
    final alignmentComparison =
        MeasureAlignerTypeComparison(AlignmentType.fullMeasure2);
    final Alignment? fullMeasure2 = measure.measureAligner
            .findDescendantByComparison(alignmentComparison, deepness: 1)
        as Alignment?;

    // With a double measure with element (mRpt2, multiRpt)
    if (fullMeasure2 != null) {
      minMeasureWidth *= 2;
    }
    // Nothing if the measure has at least one note or @metcon="false"
    else if ((measure.findDescendantByType(ClassId.note) != null) ||
        (measure.metcon == false)) {
      minMeasureWidth = 0;
    }
    // Adjust min width based on multirest attributes (@num and @width), but
    // only if these values are larger than current min width
    else if (measure.findDescendantByType(ClassId.multiRest) != null) {
      final int unit = doc.getDrawingUnit(staffSize);
      final multiRest =
          measure.findDescendantByType(ClassId.multiRest) as MultiRest?;
      final int num = multiRest?.num ?? 0;
      if (multiRest != null && multiRest.hasWidth) {
        final width = multiRest.width!;
        if (width.type == MeasurementType.vu) {
          final int fixedWidth = (width.vu * (unit + 4)).toInt();
          if (minMeasureWidth < fixedWidth) minMeasureWidth = fixedWidth;
        } else if (num > 10) {
          minMeasureWidth = (minMeasureWidth * _log1p(num) / 2).toInt();
        }
      } else if (num > 10) {
        minMeasureWidth = (minMeasureWidth * _log1p(num) / 2).toInt();
      }
      // Deviation: the clef width adjustment after a multirest requires the
      // rendered clef content bounding box and is skipped.
    }

    final int currentMeasureWidth =
        measure.getRightBarLineLeft() - measure.getLeftBarLineRight();
    if (currentMeasureWidth < minMeasureWidth) {
      measure.measureAligner.adjustProportionally([
        (
          measure.getLeftBarLine().getAlignment()!,
          measure.getRightBarLine().getAlignment()!,
          minMeasureWidth - currentMeasureWidth
        )
      ]);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    if (system.drawingScoreDef != null) {
      staffNs = system.drawingScoreDef!.getStaffNs();
    }

    return FunctorCode.continue_;
  }

  /// Calculate offset and left position of [layerElement] (mirrors
  /// `CalculateXPosOffset`).
  (int, int) calculateXPosOffset(LayerElement layerElement) {
    int selfLeft = 0;
    final int drawingUnit = doc.getDrawingUnit(staffSize);

    // Nested alignment of bounding boxes is performed only when both the
    // previous alignment and the current one allow it. For example, when one
    // of them is a barline, we do not look how bounding boxes can be nested
    // but instead only look at the horizontal position
    final bool performBoundingBoxAlignment =
        (previousAlignment.alignment != null &&
            previousAlignment.alignment!.performBoundingBoxAlignment() &&
            layerElement.getAlignment()!.performBoundingBoxAlignment());

    if (!layerElement.hasSelfBB() || layerElement.hasEmptyBB()) {
      // If nothing was drawn, do not take it into account. This should happen
      // for barline position none but also chords in beam. Otherwise the BB
      // should be set to empty with Object::SetEmptyBB()
      selfLeft = layerElement.getAlignment()!.getXRel();
      return (0, selfLeft);
    }

    // We add it to the upcoming bounding boxes
    upcomingBoundingBoxes.add(layerElement);
    currentAlignment.alignment = layerElement.getAlignment();

    // only look at the horizontal position
    if (!performBoundingBoxAlignment) {
      selfLeft = layerElement.getSelfLeft();
      selfLeft -= doc.getLeftMarginOf(layerElement).toInt() * drawingUnit;
      return (0, selfLeft);
    }

    // Here we look how bounding boxes overlap and adjust the position only
    // when necessary
    selfLeft = layerElement.getAlignment()!.getXRel();
    final double selfLeftMargin = doc.getLeftMarginOf(layerElement);
    int overlap = 0;
    for (final BoundingBox boundingBox in boundingBoxes) {
      final LayerElement bboxElement = boundingBox as LayerElement;
      int margin =
          ((doc.getRightMarginOf(bboxElement) + selfLeftMargin) * drawingUnit)
              .toInt();
      if (bboxElement.classId == ClassId.note) {
        final Note note = bboxElement as Note;
        if (note.hasStemMod &&
            note.stemMod!.index < Stemmodifier.values.length) {
          final int tremWidth =
              doc.getGlyphWidth(smuflE220Tremolo1, staffSize, false);
          margin = math.max(margin, drawingUnit ~/ 3 + tremWidth ~/ 2);
        }
      }
      final bool hasOverlap =
          layerElement.horizontalContentOverlap(boundingBox, margin);
      if (!hasOverlap) continue;

      // For note to note alignment, make sure there is a standard spacing
      // even if they do not overlap vertically
      if (layerElement.classId == ClassId.note &&
          bboxElement.classId == ClassId.note) {
        overlap = math.max(overlap,
            bboxElement.getSelfRight() - layerElement.getSelfLeft() + margin);
      } else if (layerElement.classId == ClassId.accid &&
          bboxElement.classId == ClassId.note) {
        // Mirrors `AdjustXPosFunctor::CalculateXPosOffset`
        // (adjustxposfunctor.cpp:369-379): give the accid <-> note pair extra
        // horizontal room proportional to how far apart they sit vertically,
        // but only when the accid clears the staff by more than 2 units on
        // that side (otherwise verticalMargin stays 0, same as before).
        final Staff staff = layerElement.getAncestorStaffLayout();
        final int staffTop = staff.getDrawingY();
        final int staffBottom = staffTop - doc.getDrawingStaffSize(staffSize);
        int verticalMargin = 0;
        if (layerElement.getContentTop() > staffTop + 2 * drawingUnit &&
            bboxElement.getDrawingY() > staffTop &&
            bboxElement.getDrawingY() > layerElement.getDrawingY()) {
          verticalMargin = bboxElement.getDrawingY() - layerElement.getDrawingY();
        } else if (layerElement.getContentBottom() < staffBottom - 2 * drawingUnit &&
            bboxElement.getDrawingY() < staffBottom &&
            bboxElement.getDrawingY() < layerElement.getDrawingY()) {
          verticalMargin = layerElement.getDrawingY() - bboxElement.getDrawingY();
        }
        overlap = math.max(overlap,
            bboxElement.horizontalRightOverlap(layerElement, margin, verticalMargin));
      } else if (layerElement.classId == ClassId.accid &&
          bboxElement.classId == ClassId.rest) {
        overlap = math.max(
            overlap, bboxElement.horizontalRightOverlap(layerElement, margin));
      } else {
        overlap = math.max(
            overlap, bboxElement.horizontalRightOverlap(layerElement, margin));
      }
      // if there is no overlap between elements, make additional checks for
      // some of the edge cases (rest at the end of tuplets); these rely on
      // durations only.
      if (overlap == 0) {
        if (layerElement.isAny({ClassId.note, ClassId.chord}) &&
            layerElement.getFirstAncestor(ClassId.tuplet) == null &&
            bboxElement.classId == ClassId.rest &&
            bboxElement.getFirstAncestor(ClassId.tuplet) != null) {
          final Rest rest = bboxElement as Rest;
          if ((rest.dur?.value ?? 0) > MeiDuration.dur8.value) {
            overlap = (1.5 *
                    ((rest.dur!.value - MeiDuration.dur8.value) * drawingUnit))
                .toInt();
          }
        }
      }
    }

    return (-overlap, selfLeft);
  }

  static bool _staffIsNeume(StaffAlignment? alignment) {
    final Staff? staff = alignment?.getStaff();
    if (staff == null) return false;
    return staff.drawingNotationtype == Notationtype.neume;
  }

  /// Mirrors `std::log1p(num)`.
  static double _log1p(int num) => math.log(1.0 + num);
}

// ---------------------------------------------------------------------------
// AdjustGraceXPosFunctor
// ---------------------------------------------------------------------------

/// Adjust the grace note spacing looking at the bounding boxes (mirrors
/// `vrv::AdjustGraceXPosFunctor`).
///
/// Without rendered bounding boxes the per-element adjustments are inactive;
/// the functor still performs the `PushAlignmentsRight` step and calls
/// `MeasureAligner::AdjustGraceNoteSpacing`.
class AdjustGraceXPosFunctor extends DocFunctor {
  AdjustGraceXPosFunctor(super.doc);

  /// The maximum position of the grace notes (mirrors `m_graceMaxPos`).
  int graceMaxPos = 0;

  /// The upcoming maximum position (mirrors `m_graceUpcomingMaxPos`).
  int graceUpcomingMaxPos = -meiUnset;

  /// The cumulated shift (mirrors `m_graceCumulatedXShift`); [meiUnset]
  /// means "not started".
  int graceCumulatedXShift = 0;

  /// Indicates whether the processed alignment belongs to a GraceAligner
  /// (mirrors `m_isGraceAlignment`).
  bool isGraceAlignment = false;

  /// The last non grace alignment seen so far (mirrors
  /// `m_rightDefaultAlignment`).
  Alignment? rightDefaultAlignment;

  /// The list of staffN in the top-level scoreDef (mirrors `m_staffNs`).
  List<int> staffNs = [];

  @override
  FunctorCode visitAlignment(Alignment alignment) {
    // We are in a Measure aligner - redirect to the GraceAligner when it is a
    // ALIGNMENT_GRACENOTE
    if (!isGraceAlignment) {
      // Do not process AlignmentReference children if no GraceAligner
      if (alignment.getGraceAligners().isEmpty) {
        // We store the default alignment before we hit the grace alignment
        if (alignment.getType() == AlignmentType.default_) {
          rightDefaultAlignment = alignment;
        }
        return FunctorCode.siblings;
      }
      assert(alignment.getType() == AlignmentType.graceNote);

      // Change the flag for indicating that the alignment is child of a
      // GraceAligner
      isGraceAlignment = true;

      // Get the parent measure aligner
      final MeasureAligner? measureAligner =
          alignment.getFirstAncestor(ClassId.measureAligner) as MeasureAligner?;
      assert(measureAligner != null);

      final bool previousDirection = setDirection(backward);
      final Filters filters = Filters();
      final Filters? previousFilters = setFilters(filters);

      for (final int n in staffNs) {
        final int graceAlignerId =
            doc.getOptions().graceRhythmAlign.value ? 0 : n;

        // If there is no overlap with accidentals, exclude them when getting
        // left-right margins of the alignment.
        final List<ClassId> exclude = <ClassId>[];
        if (alignment.hasGraceAligner(graceAlignerId) &&
            rightDefaultAlignment != null) {
          final graceAligner = alignment.getGraceAligner(graceAlignerId);
          // last alignment of GraceAligner is rightmost one, so get it
          final Alignment? last =
              graceAligner.getLast(ClassId.alignment) as Alignment?;
          // if there is no overlap with accidentals, exclude them
          if (last != null &&
              !last.hasAccidVerticalOverlap(rightDefaultAlignment, n)) {
            exclude.add(ClassId.accid);
          }
        }

        if (alignment.hasGraceAligner(graceAlignerId)) {
          // Rescue value, used at the end of a measure without a barline
          int graceMaxPos = alignment.getXRel() - doc.getDrawingUnit(100);
          // If we have a rightDefault, then this is (quite likely) the next
          // note / chord. Get its minimum left and make it the max right
          // position of the grace group.
          if (rightDefaultAlignment != null) {
            final (int minLeft, _) =
                rightDefaultAlignment!.getLeftRight(n, excludes: exclude);
            if (minLeft != -meiUnset) {
              graceMaxPos = minLeft -
                  doc.getLeftMargin(ClassId.note).toInt() *
                      doc.getDrawingUnit(75);
            }
          }
          // This happens when grace notes are at the end of a measure before
          // a barline
          else {
            assert(measureAligner != null);
            final Alignment? rightBarLineAlignment =
                measureAligner?.getRightBarLineAlignment();
            // staffN -1 is barline
            final (int minLeft, int maxRight) =
                rightBarLineAlignment?.getLeftRight(-1 /* BARLINE_REFERENCES */,
                        excludes: exclude) ??
                    (-meiUnset, meiUnset);
            if (minLeft != -meiUnset) {
              graceMaxPos = minLeft -
                  doc.getLeftMargin(ClassId.note).toInt() *
                      doc.getDrawingUnit(75);
            }
          }

          this.graceMaxPos = graceMaxPos;
          graceUpcomingMaxPos = -meiUnset;
          graceCumulatedXShift = meiUnset;

          filters.clear();
          filters.setType(FiltersType.allOf);
          // Create ad comparison object for each type / @n
          filters
              .add(AttNIntegerAnyComparison(ClassId.alignmentReference, [n]));

          // Process backwards with filters on grace aligner
          alignment.getGraceAligner(graceAlignerId).process(this);

          // There were no grace notes for the staff
          if (graceCumulatedXShift == meiUnset) continue;

          // Now we need to adjust the space for the grace note group
          measureAligner!.adjustGraceNoteSpacing(doc, alignment, n);
        }
      }

      setDirection(previousDirection);
      setFilters(previousFilters);

      // Change the flag back
      isGraceAlignment = false;

      return FunctorCode.continue_;
    }

    if (graceCumulatedXShift != meiUnset) {
      // This is happening when aligning the grace aligner itself
      alignment.setXRel(alignment.getXRel() + graceCumulatedXShift);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitAlignmentEnd(Alignment alignment) {
    if (graceUpcomingMaxPos != -meiUnset) {
      graceMaxPos = graceUpcomingMaxPos;
      // We reset it for the next aligner
      graceUpcomingMaxPos = -meiUnset;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitAlignmentReference(AlignmentReference alignmentReference) {
    // Because we are processing grace notes alignment backward (see
    // visitAlignment) we need to process the children (LayerElement) "by
    // hand" in FORWARD manner (filters can be NULL because filtering was
    // already applied in the parent)
    final bool previousDirection = setDirection(forward);
    final Filters? previousFilters = setFilters(null);

    for (final Object child in alignmentReference.children) {
      child.process(this);
    }

    setDirection(previousDirection);
    setFilters(previousFilters);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    if (graceCumulatedXShift == meiUnset) graceCumulatedXShift = 0;

    // With non grace alignment we do not need to do this
    layerElement.resetCachedDrawingX();

    if (!layerElement.hasGraceAlignment()) return FunctorCode.siblings;

    if (!layerElement.hasSelfBB() || layerElement.hasEmptyBB()) {
      // if nothing was drawn, do not take it into account
      return FunctorCode.siblings;
    }

    final int selfRight = layerElement.getSelfRight();
    final int offset = selfRight - graceMaxPos;
    if (offset > 0) {
      layerElement
          .getGraceAlignment()!
          .setXRel(layerElement.getGraceAlignment()!.getXRel() - offset);
      // Also move the accumulated x shift and the minimum position for the
      // next alignment accordingly
      graceCumulatedXShift += -offset;
      graceUpcomingMaxPos += -offset;
    }

    final int selfLeft = layerElement.getSelfLeft() -
        (doc.getLeftMarginOf(layerElement).toInt() *
            doc.getDrawingUnit(doc.getCueSize(100)));

    graceUpcomingMaxPos = math.min(selfLeft, graceUpcomingMaxPos);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    measure.measureAligner.pushAlignmentsRight();
    rightDefaultAlignment = null;

    // We process it backward because we want to get the
    // rightDefaultAlignment
    final bool previousDirection = setDirection(backward);
    measure.measureAligner.process(this);

    // We need to process the staves in the reverse order
    final List<int> originalStaffNs = staffNs;
    final List<int> staffNsReversed = originalStaffNs.reversed.toList();

    measure.measureAligner.pushAlignmentsRight();
    rightDefaultAlignment = null;

    staffNs = staffNsReversed;
    measure.measureAligner.process(this);
    setDirection(previousDirection);

    // Put params back
    staffNs = originalStaffNs;

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    if (system.drawingScoreDef != null) {
      staffNs = system.drawingScoreDef!.getStaffNs();
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// AdjustClefChangesFunctor
// ---------------------------------------------------------------------------

/// Adjust the spacing of the clef changes since they are skipped in
/// AdjustXPos (mirrors `vrv::AdjustClefChangesFunctor`).
///
/// Without rendered content bounding boxes the functor returns early like the
/// C++ does for invisible clefs; the structure is kept for the resources
/// phase.
class AdjustClefChangesFunctor extends DocFunctor {
  AdjustClefChangesFunctor(super.doc);

  /// The measure aligner currently processed (mirrors `m_aligner`).
  MeasureAligner? aligner;

  @override
  FunctorCode visitClef(Clef clef) {
    if (clef.isScoreDefElement) return FunctorCode.siblings;

    assert(clef.getAlignment() != null);
    if (clef.getAlignment()!.getType() != AlignmentType.clef) {
      return FunctorCode.continue_;
    }

    // Without a rendered content bounding box there is nothing to adjust.
    if (!clef.hasContentBB()) return FunctorCode.continue_;

    assert(aligner != null);

    final Staff staff = clef.getAncestorStaffLayout();

    // Look if we have a grace aligner just after the clef. Limitation: clef
    // changes are always aligned before grace notes, even if appearing after
    // in the encoding. The lookup is kept for the resources phase where the
    // grace group left position becomes relevant.
    GraceAligner? graceAligner;
    final Alignment? nextAlignment = aligner!
        .getNextSibling(clef.getAlignment()!, ClassId.alignment) as Alignment?;
    if (nextAlignment != null &&
        nextAlignment.getType() == AlignmentType.graceNote) {
      // If we have one, then check if we have one for our staff (or all
      // staves with --grace-rhythm-align)
      final int graceAlignerId =
          doc.getOptions().graceRhythmAlign.value ? 0 : (staff.n ?? 0);
      if (nextAlignment.hasGraceAligner(graceAlignerId)) {
        graceAligner = nextAlignment.getGraceAligner(graceAlignerId);
      }
    }
    if (graceAligner != null) {
      logDebug('AdjustClefChangesFunctor: grace aligner spacing requires the '
          'glyph metrics of the resources phase');
    }

    logDebug('AdjustClefChangesFunctor: full behaviour requires the glyph '
        'metrics of the resources phase');

    // Deviation: FindNextChild / FindPreviousChild over the alignment
    // references arrive together with the rendering phase; the remaining part
    // of the adjustment depends on them.
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    aligner = measure.measureAligner;

    return FunctorCode.continue_;
  }
}
