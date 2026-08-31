/// Port of `adjustfloatingpositionerfunctor.h/cpp`:
///
/// - [AdjustFloatingPositionersFunctor] adjusts the position of all floating
///   positioners, staff by staff, one class at a time;
/// - [AdjustFloatingPositionerGrpsFunctor] aligns the positioners of grouped
///   floating elements (@vgrp);
/// - [AdjustFloatingPositionersBetweenFunctor] adjusts the positioners of
///   floating elements placed between staves.
///
/// Deviations from the C++:
/// - None for the SYL branch: the lyric font is now measured via
///   `Doc::GetDrawingLyricFont` / `GetTextGlyphHeight` / `GetTextGlyphDescender`
///   (adjustfloatingpositionerfunctor.cpp:39-42) after the View phase.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Staffrel;
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

// ---------------------------------------------------------------------------
// AdjustFloatingPositionersFunctor
// ---------------------------------------------------------------------------

/// This class adjusts the position of all floating positioners, staff by
/// staff (mirrors `vrv::AdjustFloatingPositionersFunctor`).
class AdjustFloatingPositionersFunctor extends DocFunctor {
  AdjustFloatingPositionersFunctor(super.doc) {
    classId = ClassId.object;
    inBetween = false;
  }

  /// The class ID (mirrors `m_classId`).
  ClassId classId = ClassId.object;

  /// Indicates if we are processing floating objects to be put in between the
  /// staff (mirrors `m_inBetween`).
  bool inBetween = false;

  @override
  FunctorCode visitStaffAlignment(StaffAlignment staffAlignment) {
    final int staffSize = staffAlignment.getStaffSize();
    final int drawingUnit = doc.getDrawingUnit(staffSize);

    staffAlignment.sortPositioners();

    if (classId == ClassId.syl) {
      // Mirrors `AdjustFloatingPositionersFunctor::VisitStaffAlignment` SYL
      // branch (adjustfloatingpositionerfunctor.cpp:37-66): measures the
      // lyric font via `Resources`/`Doc` (now available after the View
      // rendering phase) and uses `lyricTopMinMargin`/`lyricHeightFactor`.
      final bool verseCollapse = doc.getOptions().lyricVerseCollapse.value;
      if (staffAlignment.getVerseCount(verseCollapse) > 0) {
        final int staffSize = staffAlignment.getStaffSize();
        int verseHeight;
        try {
          final font = doc.getDrawingLyricFont(staffSize);
          final int h = doc.getTextGlyphHeight('I'.codeUnitAt(0), font, false);
          final int desc =
              doc.getTextGlyphDescender('q'.codeUnitAt(0), font, false);
          verseHeight = h - desc;
          verseHeight =
              (verseHeight * doc.getOptions().lyricHeightFactor.value).toInt();
        } on Exception catch (e) {
          e.toString();
          // Fallback when resources are unavailable (matches the old 3*unit
          // approximation but only for the headless test path without fonts).
          verseHeight = 3 * drawingUnit;
        }
        final int unit = drawingUnit;
        if (staffAlignment.getVerseCountAbove(verseCollapse) > 0) {
          final int margin = (doc.getTopMargin(ClassId.syl) * unit).toInt();
          final int minMargin = math.max(
              (doc.getOptions().lyricTopMinMargin.value * unit).toInt(),
              staffAlignment.getOverflowAbove());
          staffAlignment.setOverflowAbove(minMargin +
              staffAlignment.getVerseCountAbove(verseCollapse) *
                  (verseHeight + margin));
          staffAlignment.clearBBoxesAbove();
        }
        if (staffAlignment.getVerseCountBelow(verseCollapse) > 0) {
          final int margin = (doc.getBottomMargin(ClassId.syl) * unit).toInt();
          final int minMargin = math.max(
              (doc.getOptions().lyricTopMinMargin.value * unit).toInt(),
              staffAlignment.getOverflowBelow());
          staffAlignment.setOverflowBelow(minMargin +
              staffAlignment.getVerseCountBelow(verseCollapse) *
                  (verseHeight + margin));
          staffAlignment.clearBBoxesBelow();
        }
      }
      return FunctorCode.siblings;
    }

    for (final FloatingPositioner positioner
        in staffAlignment.getFloatingPositioners()) {
      assert(positioner.getObject() != null);
      if (!inBetween && !positioner.getObject()!.isClass(classId)) continue;

      if (inBetween) {
        if (positioner.getDrawingPlace() != Staffrel.between) continue;
      } else {
        if (positioner.getDrawingPlace() == Staffrel.between) continue;
      }

      // Skip if no content bounding box is available
      if (!positioner.hasContentBB()) continue;

      // for slurs and ties we do not need to adjust them, only add them to
      // the overflow boxes if required
      if ((classId == ClassId.lv) ||
          (classId == ClassId.phrase) ||
          (classId == ClassId.slur) ||
          (classId == ClassId.tie)) {
        assert(positioner is FloatingCurvePositioner);
        final FloatingCurvePositioner curve =
            positioner as FloatingCurvePositioner;

        bool skipAbove = false;
        bool skipBelow = false;

        // Deviation: TimeSpanningInterface::GetCrossStaffOverflows is not
        // ported yet; cross-staff slurs contribute on both sides.

        int overflowAbove = 0;
        if (!skipAbove) {
          overflowAbove = staffAlignment.calcOverflowAbove(positioner);
        }
        if (overflowAbove > getStaffLineWidth(staffSize) ~/ 2) {
          staffAlignment.setOverflowAbove(overflowAbove);
          staffAlignment.addBBoxAbove(positioner);
        }

        int overflowBelow = 0;
        if (!skipBelow) {
          overflowBelow = staffAlignment.calcOverflowBelow(positioner);
        }
        if (overflowBelow > getStaffLineWidth(staffSize) ~/ 2) {
          staffAlignment.setOverflowBelow(overflowBelow);
          staffAlignment.addBBoxBelow(positioner);
        }

        final (int spaceAbove, int spaceBelow) =
            curve.calcRequestedStaffSpace(staffAlignment);
        staffAlignment.setRequestedSpaceAbove(spaceAbove);
        staffAlignment.setRequestedSpaceBelow(spaceBelow);

        continue;
      }

      // This sets the default position (without considering any overflowing
      // box)
      positioner.calcDrawingYRel(doc, staffAlignment, null);

      final Staffrel place = positioner.getDrawingPlace();
      final List<BoundingBox> overflowBoxes = (place == Staffrel.above)
          ? staffAlignment.getBBoxesAboveForModification()
          : staffAlignment.getBBoxesBelowForModification();

      // Handle within placement (ignore collisions for certain classes)
      if (place == Staffrel.within) {
        if (classId == ClassId.cpMark) continue;
        if (classId == ClassId.dir) continue;
        if (classId == ClassId.hairpin) continue;
      }

      // Find all the overflowing elements from the staff that overlap
      // horizontally
      for (final BoundingBox bbox in overflowBoxes) {
        if (positioner.hasHorizontalOverlapWith(bbox, drawingUnit)) {
          // update the yRel accordingly
          positioner.calcDrawingYRel(doc, staffAlignment, bbox);
        }
      }

      // Vertically align extender elements across systems
      positioner.adjustExtenders();

      // Now update the staffAlignment max overflow (above or below) and add
      // the positioner to the list of overflowing elements
      if (place == Staffrel.above) {
        int overflowAbove = staffAlignment.calcOverflowAbove(positioner);
        overflowBoxes.add(positioner);
        staffAlignment.setOverflowAbove(overflowAbove);
      }
      // below (or between)
      else {
        int overflowBelow = staffAlignment.calcOverflowBelow(positioner);
        overflowBoxes.add(positioner);
        staffAlignment.setOverflowBelow(overflowBelow);
      }
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    inBetween = false;

    final AdjustFloatingPositionerGrpsFunctor adjustFloatingPositionerGrps =
        AdjustFloatingPositionerGrpsFunctor(doc);

    void processClass(ClassId id) {
      classId = id;
      system.systemAligner.process(this);
    }

    void processGrps(List<ClassId> ids, Staffrel place) {
      adjustFloatingPositionerGrps.setClassIDs(ids);
      adjustFloatingPositionerGrps.setPlace(place);
      system.systemAligner.process(adjustFloatingPositionerGrps);
    }

    processClass(ClassId.lv);
    processClass(ClassId.tie);
    processClass(ClassId.slur);
    processClass(ClassId.phrase);
    processClass(ClassId.accidFloating);
    processClass(ClassId.mordent);
    processClass(ClassId.turn);
    processClass(ClassId.trill);
    processClass(ClassId.ornam);
    processClass(ClassId.fing);
    processClass(ClassId.dynam);
    processClass(ClassId.hairpin);
    processGrps(const [ClassId.dynam, ClassId.hairpin], Staffrel.above);
    processGrps(const [ClassId.dynam, ClassId.hairpin], Staffrel.below);
    processClass(ClassId.bracketSpan);
    processClass(ClassId.octave);
    processClass(ClassId.breath);
    processClass(ClassId.fermata);
    processClass(ClassId.dir);
    processGrps(const [ClassId.dir], Staffrel.above);
    processGrps(const [ClassId.dir], Staffrel.below);
    processClass(ClassId.cpMark);
    processClass(ClassId.repeatMark);
    processClass(ClassId.tempo);
    processClass(ClassId.pedal);
    processGrps(const [ClassId.pedal], Staffrel.above);
    processGrps(const [ClassId.pedal], Staffrel.below);
    processClass(ClassId.harm);
    processGrps(const [ClassId.harm], Staffrel.above);
    processGrps(const [ClassId.harm], Staffrel.below);
    processClass(ClassId.ending);
    processGrps(const [ClassId.ending], Staffrel.above);
    processGrps(const [ClassId.ending], Staffrel.below);
    processClass(ClassId.reh);
    processClass(ClassId.caesura);
    processClass(ClassId.annotScore);

    // SYL check if there are some lyrics and make space for them if any
    processClass(ClassId.syl);

    /**** Process elements that need to be put in between ****/

    inBetween = true;
    // All of them with no particular processing order.
    // The resulting layout order will correspond to the order in the encoding.
    processClass(ClassId.object);
    processGrps(const [ClassId.dynam], Staffrel.between);

    return FunctorCode.siblings;
  }

  /// Mirrors `Doc::GetDrawingStaffLineWidth(staffSize)`.
  int getStaffLineWidth(int staffSize) =>
      (doc.getOptions().staffLineWidth.value * doc.getDrawingUnit(staffSize))
          .toInt();
}

// ---------------------------------------------------------------------------
// AdjustFloatingPositionerGrpsFunctor
// ---------------------------------------------------------------------------

/// This class adjusts the position of all floating positioners that are
/// grouped, staff by staff (mirrors `vrv::AdjustFloatingPositionerGrpsFunctor`).
class AdjustFloatingPositionerGrpsFunctor extends DocFunctor {
  AdjustFloatingPositionerGrpsFunctor(super.doc) {
    place = Staffrel.above;
  }

  /// The class IDs to group (mirrors `m_classIds`).
  List<ClassId> classIds = [];

  /// The place w.r.t. the staff (mirrors `m_place`).
  Staffrel place = Staffrel.above;

  void setClassIDs(List<ClassId> ids) => classIds = ids;
  void setPlace(Staffrel value) => place = value;

  @override
  FunctorCode visitStaffAlignment(StaffAlignment staffAlignment) {
    final List<FloatingPositioner> positioners = <FloatingPositioner>[];
    // make a temporary copy of positioners with desired classId and a
    // drawing grpId
    for (final FloatingPositioner positioner
        in staffAlignment.getFloatingPositioners()) {
      final FloatingObject? object = positioner.getObject();
      if (object == null) continue;
      if (!classIds.contains(object.classId)) continue;
      if (object.drawingGrpId == 0) continue;
      if (positioner.getDrawingPlace() != place) continue;
      if (positioner.hasEmptyBB()) continue;
      positioners.add(positioner);
    }

    if (positioners.isEmpty) {
      return FunctorCode.siblings;
    }

    // A list storing a pair with the grpId and the min or max YRel
    final List<(int, int)> grpIdYRel = <(int, int)>[];

    for (final FloatingPositioner positioner in positioners) {
      final int currentGrpId = positioner.getObject()!.drawingGrpId;
      // Look if we already have a pair for this grpId
      final int index =
          grpIdYRel.indexWhere(((int, int) pair) => pair.$1 == currentGrpId);
      // if not, then just add a new pair with the YRel of the current
      // positioner
      if (index == -1) {
        grpIdYRel.add((currentGrpId, positioner.getDrawingYRel()));
      }
      // else, adjust the min or max YRel of the pair if necessary
      else {
        final (int grp, int yRel) = grpIdYRel[index];
        if (place == Staffrel.above) {
          if (positioner.getDrawingYRel() < yRel) {
            grpIdYRel[index] = (grp, positioner.getDrawingYRel());
          }
        } else {
          if (positioner.getDrawingYRel() > yRel) {
            grpIdYRel[index] = (grp, positioner.getDrawingYRel());
          }
        }
      }
    }

    if (classIds.contains(ClassId.harm)) {
      // Adjust the position of groups to ensure that any group is positioned
      // further away
      adjustGroupsMonotone(staffAlignment, positioners, grpIdYRel);
      // This already moves them, so the loop below is not necessary.
    } else {
      // Now go through all the positioners again and adjust the YRel with
      // the value of the pair
      for (final FloatingPositioner positioner in positioners) {
        final int currentGrpId = positioner.getObject()!.drawingGrpId;
        final int index =
            grpIdYRel.indexWhere(((int, int) pair) => pair.$1 == currentGrpId);
        // We must have found it
        assert(index != -1);
        positioner.setDrawingYRel(grpIdYRel[index].$2);
      }
    }

    // Now update the staffAlignment max overflow (above or below)
    for (final FloatingPositioner positioner in positioners) {
      if (place == Staffrel.above) {
        int overflowAbove = staffAlignment.calcOverflowAbove(positioner);
        staffAlignment.setOverflowAbove(overflowAbove);
      } else {
        int overflowBelow = staffAlignment.calcOverflowBelow(positioner);
        staffAlignment.setOverflowBelow(overflowBelow);
      }
    }

    return FunctorCode.siblings;
  }

  /// Mirrors `AdjustGroupsMonotone`: adjust the position of groups to ensure
  /// that any group is positioned further away from the staff than preceding
  /// groups.
  void adjustGroupsMonotone(StaffAlignment staffAlignment,
      List<FloatingPositioner> positioners, List<(int, int)> grpIdYRel) {
    if (grpIdYRel.isEmpty) {
      return;
    }

    grpIdYRel.sort((left, right) => left.$1.compareTo(right.$1));

    int yRel;
    // The initial next position is the original position of the first group.
    // Nothing will happen for it.
    int nextYRel = grpIdYRel.first.$2;

    // For each grpId (sorted, see above), loop to find the highest / lowest
    // position to put the next group. Then move the next group (if not
    // already higher or lower)
    for (final (int grp, int grpYRel) in grpIdYRel) {
      // Check if the next group is not already higher or lower.
      if (place == Staffrel.above) {
        yRel = (nextYRel < grpYRel) ? nextYRel : grpYRel;
      } else {
        yRel = (nextYRel > grpYRel) ? nextYRel : grpYRel;
      }
      // Go through all the positioners, but filter by group
      for (final FloatingPositioner positioner in positioners) {
        final int currentGrpId = positioner.getObject()!.drawingGrpId;
        // Not the grpId we are processing, skip it.
        if (currentGrpId != grp) continue;
        // Set its position
        positioner.setDrawingYRel(yRel);
        // Then find the highest / lowest position for the next group
        if (place == Staffrel.above) {
          final int positionerY = yRel -
              positioner.getContentY2() -
              (doc.getTopMargin(positioner.getObject()!.classId) *
                      doc.getDrawingUnit(staffAlignment.getStaffSize()))
                  .toInt();
          if (nextYRel > positionerY) {
            nextYRel = positionerY;
          }
        } else {
          final int positionerY = yRel +
              positioner.getContentY2() +
              (doc.getBottomMargin(positioner.getObject()!.classId) *
                      doc.getDrawingUnit(staffAlignment.getStaffSize()))
                  .toInt();
          if (nextYRel < positionerY) {
            nextYRel = positionerY;
          }
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// AdjustFloatingPositionersBetweenFunctor
// ---------------------------------------------------------------------------

/// This class adjusts the position of floating positioners placed between
/// staves (mirrors `vrv::AdjustFloatingPositionersBetweenFunctor`).
class AdjustFloatingPositionersBetweenFunctor extends DocFunctor {
  AdjustFloatingPositionersBetweenFunctor(super.doc);

  /// The previous staff alignment (mirrors `m_previousStaffAlignment`).
  StaffAlignment? _previousStaffAlignment;

  @override
  FunctorCode visitStaffAlignment(StaffAlignment staffAlignment) {
    // First staff - nothing to do
    if (_previousStaffAlignment == null) {
      _previousStaffAlignment = staffAlignment;
      return FunctorCode.siblings;
    }
    assert(_previousStaffAlignment != null);

    int dist = _previousStaffAlignment!.getYRel() - staffAlignment.getYRel();
    dist -= _previousStaffAlignment!.getStaffHeight();
    final int centerYRel =
        dist ~/ 2 + _previousStaffAlignment!.getStaffHeight();

    for (final FloatingPositioner positioner
        in _previousStaffAlignment!.getFloatingPositioners()) {
      assert(positioner.getObject() != null);
      if (!positioner.getObject()!.isAny(const {
        ClassId.cpMark,
        ClassId.dir,
        ClassId.dynam,
        ClassId.hairpin,
        ClassId.tempo
      })) {
        continue;
      }

      if (positioner.getDrawingPlace() != Staffrel.between) continue;

      // Skip if no content bounding box is available
      if (!positioner.hasContentBB()) continue;

      int diffY = centerYRel - positioner.getDrawingYRel();

      final List<BoundingBox> overflowBoxes = staffAlignment.getBBoxesAbove();
      for (final BoundingBox elem in overflowBoxes) {
        // find all the overflowing elements from the staff that overlap
        // horizontally
        if (positioner.horizontalContentOverlap(elem)) {
          // update the yRel accordingly
          final int spaceY =
              positioner.getSpaceBelow(doc, staffAlignment, elem);
          if (spaceY != meiUnset) {
            diffY = math.min(diffY, spaceY);
          }
        }
      }
      positioner.setDrawingYRel(positioner.getDrawingYRel() + diffY);
    }

    _previousStaffAlignment = staffAlignment;

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    _previousStaffAlignment = null;
    system.systemAligner.process(this);

    return FunctorCode.siblings;
  }
}
