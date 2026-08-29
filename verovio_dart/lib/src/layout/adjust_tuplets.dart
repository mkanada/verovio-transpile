/// Port of the tuplet adjustment functors of `adjusttupletsx/yfunctor.h/cpp`
/// plus the model helpers they need from `tuplet.cpp` and `elementpart.cpp`:
///
/// - [AdjustTupletsXFunctor]: X position of the bracket and the num
///   (`AdjustTupletsXFunctor::VisitTuplet`, adjusttupletsxfunctor.cpp:25).
/// - [AdjustTupletsYFunctor]: Y position of both against notes / staff /
///   beams (`VisitTuplet` at adjusttupletsyfunctor.cpp:30 and its private
///   helpers down to `CalcBracketShift`, :311).
/// - [AdjustTupletNumOverlapFunctor]: finds a free Y position for a tuplet
///   num among the surrounding elements (:338). It is **not** wired in the
///   pipeline: it is instantiated inside [AdjustTupletsYFunctor], mirroring
///   the C++.
/// - [AdjustTupletWithSlursFunctor]: shifts tuplets with inner slurs
///   (:376).
///
/// Deviations from the C++:
/// - The beam segment geometry (`BeamSegment::CalcBeam`, beam.cpp:89) is now
///   available headlessly via `BeamSegment.calcBeam` in the model (task
///   05-31), so `m_beamSegment.GetStartingY()`, `m_beamSlope` and
///   `GetElementCoordRefs` are read directly; `FTrem::m_yBeam` likewise.
/// - `Tuplet::CalcDrawingBracketAndNumPos` runs from `view_tuplet.cpp:64`
///   during rendering; headlessly it runs inline here before each use
///   (idempotent, same inputs, option default `tupletNumHead=false`).
/// - `LayerElement::GetDrawingRadius` relies on real glyph metrics
///   (`Doc::GetGlyphWidth`); the headless approximation of `doc.dart` may
///   differ by a few units from Bravura.
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/smufl.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/rendering/glyph.dart' show Glyph;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show StemmedDrawingInterface;
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';

// ---------------------------------------------------------------------------
// AdjustTupletsXFunctor
// ---------------------------------------------------------------------------

/// This functor calculates the X position of tuplet brackets and nums
/// (mirrors `vrv::AdjustTupletsXFunctor`).
class AdjustTupletsXFunctor extends DocFunctor {
  AdjustTupletsXFunctor(super.doc);

  @override
  FunctorCode visitTuplet(Tuplet tuplet) {
    // Nothing to do if there is no number.
    if (!tuplet.hasNum) return FunctorCode.siblings;

    // Nothing to do if the bracket and the num are not visible.
    if ((tuplet.bracketVisible == false) && (tuplet.numVisible == false)) {
      return FunctorCode.siblings;
    }

    // Nothing we can do if the pointers to the left and right are not set.
    if (tuplet.drawingLeft == null || tuplet.drawingRight == null) {
      return FunctorCode.siblings;
    }

    // Headless stand-in for the render-pass call of
    // `CalcDrawingBracketAndNumPos` (see the library deviation note).
    if (tuplet.drawingBracketPos == StaffrelBasic.none ||
        tuplet.drawingNumPos == StaffrelBasic.none) {
      _calcDrawingBracketAndNumPos(
          tuplet, doc.getOptions().tupletNumHead.value);
    }

    assert(tuplet.drawingBracketPos != StaffrelBasic.none);

    // Careful: this will not work if the tuplet has editorial markup (one
    // child) and then notes + one beam.
    final Beam? beamParent =
        tuplet.getFirstAncestor(ClassId.beam, maxBeamDepth) as Beam?;
    // Is the tuplet contained in a beam?
    if (beamParent != null) {
      tuplet.bracketAlignedBeam = beamParent;
    }
    final Beam? beamChild = tuplet.findDescendantByType(ClassId.beam) as Beam?;
    // Do we contain a beam?
    if (beamChild != null) {
      if ((tuplet.getChildCount(ClassId.note) == 0) &&
          (tuplet.getChildCount(ClassId.chord) == 0) &&
          (tuplet.getChildCount(ClassId.beam) == 1)) {
        tuplet.bracketAlignedBeam = beamChild;
      }
    }

    tuplet.numAlignedBeam = tuplet.bracketAlignedBeam;

    dynamic bracketAlignedBeam = tuplet.bracketAlignedBeam;
    dynamic numAlignedBeam = tuplet.numAlignedBeam;

    // Cancel alignment of the bracket with the beam if position and stem
    // direction are not concordant.
    if (bracketAlignedBeam != null &&
        bracketAlignedBeam.drawingPlace == Beamplace.above &&
        tuplet.drawingBracketPos == StaffrelBasic.below) {
      tuplet.bracketAlignedBeam = null;
    } else if (bracketAlignedBeam != null &&
        (bracketAlignedBeam.drawingPlace == Beamplace.below) &&
        (tuplet.drawingBracketPos == StaffrelBasic.above)) {
      tuplet.bracketAlignedBeam = null;
    }

    // Cancel alignment of the num with the beam if position and stem
    // direction are not concordant.
    if (numAlignedBeam != null &&
        numAlignedBeam.drawingPlace == Beamplace.above &&
        tuplet.drawingNumPos == StaffrelBasic.below) {
      tuplet.numAlignedBeam = null;
    } else if (numAlignedBeam != null &&
        (numAlignedBeam.drawingPlace == Beamplace.below) &&
        (tuplet.drawingNumPos == StaffrelBasic.above)) {
      tuplet.numAlignedBeam = null;
    }

    final TupletsXRel xRel = _getDrawingLeftRightXRel(tuplet, doc);

    final TupletBracket? tupletBracket =
        tuplet.getFirst(ClassId.tupletBracket) as TupletBracket?;
    if (tupletBracket != null && (tuplet.bracketVisible != false)) {
      tupletBracket.drawingXRelLeft = xRel.left;
      tupletBracket.drawingXRelRight = xRel.right;
    }

    final TupletNum? tupletNum =
        tuplet.getFirst(ClassId.tupletNum) as TupletNum?;
    if (tupletNum != null && (tuplet.numVisible != false)) {
      // We have a bracket and the num is not on its opposite side.
      if (tupletBracket != null &&
          (tuplet.drawingNumPos == tuplet.drawingBracketPos)) {
        tupletNum.alignedBracket = tupletBracket;
      } else {
        tupletNum.alignedBracket = null;
      }
    }

    return FunctorCode.siblings;
  }
}

// ---------------------------------------------------------------------------
// AdjustTupletsYFunctor
// ---------------------------------------------------------------------------

/// This functor calculates the Y position of tuplet brackets and nums
/// (mirrors `vrv::AdjustTupletsYFunctor`).
class AdjustTupletsYFunctor extends DocFunctor {
  AdjustTupletsYFunctor(super.doc);

  @override
  FunctorCode visitTuplet(Tuplet tuplet) {
    // Nothing to do if there is no number.
    if (!tuplet.hasNum) return FunctorCode.siblings;

    // Nothing to do if the bracket and the num are not visible.
    if ((tuplet.bracketVisible == false) && (tuplet.numVisible == false)) {
      return FunctorCode.siblings;
    }

    if (tuplet.drawingLeft == null || tuplet.drawingRight == null) {
      return FunctorCode.siblings;
    }

    // Headless stand-in for the render-pass call of
    // `CalcDrawingBracketAndNumPos` (see the library deviation note).
    if (tuplet.drawingBracketPos == StaffrelBasic.none ||
        tuplet.drawingNumPos == StaffrelBasic.none) {
      _calcDrawingBracketAndNumPos(
          tuplet, doc.getOptions().tupletNumHead.value);
    }

    assert(tuplet.drawingBracketPos != StaffrelBasic.none);

    final Staff staff = tuplet.getAncestorStaffLayout();

    final Staff relevantStaff =
        tuplet.crossStaff is Staff ? tuplet.crossStaff as Staff : staff;

    _adjustTupletBracketY(tuplet, relevantStaff);

    _adjustTupletNumY(tuplet, relevantStaff);

    return FunctorCode.siblings;
  }

  /// Mirrors `AdjustTupletsYFunctor::AdjustTupletBracketY`
  /// (adjusttupletsyfunctor.cpp:59).
  void _adjustTupletBracketY(Tuplet tuplet, Staff staff) {
    final TupletBracket? tupletBracket =
        tuplet.getFirst(ClassId.tupletBracket) as TupletBracket?;
    if (tupletBracket == null || (tuplet.bracketVisible == false)) return;

    // If bracket is used for beam elements - process that part separately.
    if (tuplet.bracketAlignedBeam != null) {
      _adjustTupletBracketBeamY(
          tuplet, tupletBracket, tuplet.bracketAlignedBeam as Beam, staff);
      return;
    }

    final int staffSize = staff.drawingStaffSize;
    final StaffrelBasic bracketPos = tuplet.drawingBracketPos;

    // Default position is above or below the staff.
    final int staffBoundary = (bracketPos == StaffrelBasic.above)
        ? 0
        : -doc.getDrawingStaffSize(staffSize);
    final int bracketMidX = (_bracketDrawingXLeft(tuplet, tupletBracket) +
            _bracketDrawingXRight(tuplet, tupletBracket)) ~/
        2;
    final Point referencePoint =
        Point(bracketMidX, staff.getDrawingY() + staffBoundary);

    // Check for overlap with content.
    final List<Object> descendants =
        tuplet.findAllDescendantsByClassIdPredicate((ClassId classId) =>
            classId == ClassId.artic ||
            classId == ClassId.accid ||
            classId == ClassId.dot ||
            classId == ClassId.flag ||
            classId == ClassId.note ||
            classId == ClassId.rest ||
            classId == ClassId.stem);
    final List<Point> obstacles = <Point>[];
    for (final Object descendant in descendants) {
      if (!(descendant as LayerElement).hasSelfBB()) continue;
      if (descendant.crossStaff != null) continue;
      final int obstacleY = (bracketPos == StaffrelBasic.above)
          ? descendant.getSelfTop()
          : descendant.getSelfBottom();
      obstacles.add(Point(descendant.getDrawingX(), obstacleY));
    }

    // Calculate the horizontal bracket first.
    final int unit = doc.getDrawingUnit(staffSize);
    final int sign = (bracketPos == StaffrelBasic.above) ? 1 : -1;
    final int horizontalBracketShift =
        calcBracketShift(referencePoint, 0.0, sign, obstacles);
    int optimalTilt = 0;
    int optimalShift = horizontalBracketShift;

    if (!doc.getOptions().tupletAngledOnBeams.value) {
      // Now try different angles and possibly find a better position.
      final int bracketWidth = _bracketDrawingXRight(tuplet, tupletBracket) -
          _bracketDrawingXLeft(tuplet, tupletBracket);
      final MelodicDirection direction = tuplet.getMelodicDirection();
      for (final int tilt in const [-4, -2, 2, 4]) {
        if (bracketWidth == 0) continue;
        // Drop if angle does not fit to the melodic direction.
        if ((direction == MelodicDirection.up) && (tilt < 0)) continue;
        if ((direction == MelodicDirection.down) && (tilt > 0)) continue;
        // Calculate the shift for the angle.
        final double slope = tilt * unit / bracketWidth;
        final int shift =
            calcBracketShift(referencePoint, slope, sign, obstacles);
        // Drop angled brackets that would go into the staff.
        if (shift < tilt.abs() * unit ~/ 2) continue;
        // Drop angled brackets where the midpoint is moved only slightly
        // closer to the staff.
        if (shift > horizontalBracketShift - tilt.abs() * unit ~/ 4) continue;
        // Update the optimal tilt.
        if (shift < optimalShift) {
          optimalShift = shift;
          optimalTilt = tilt;
        }
      }
    }

    const int verticalMarginFactor = 2;
    final int verticalMargin = verticalMarginFactor * unit;
    tupletBracket
        .setDrawingYRel(staffBoundary + sign * (optimalShift + verticalMargin));
    tupletBracket.drawingYRelLeft = -optimalTilt * unit ~/ 2;
    tupletBracket.drawingYRelRight = optimalTilt * unit ~/ 2;
  }

  /// Mirrors `AdjustTupletsYFunctor::AdjustTupletNumY` (:127).
  void _adjustTupletNumY(Tuplet tuplet, Staff staff) {
    final TupletNum? tupletNum =
        tuplet.getFirst(ClassId.tupletNum) as TupletNum?;
    if (tupletNum == null || (tuplet.numVisible == false)) return;

    // The num is within a bracket.
    if (tupletNum.alignedBracket != null) {
      // yRel is not used for drawing but we need to adjust it for the
      // bounding box to follow the changes.
      tupletNum.setDrawingYRel(
          (tupletNum.alignedBracket as TupletBracket).drawingYRel);
      return;
    }

    final bool hasNumAlignedBeam = tuplet.numAlignedBeam != null;
    calculateTupletNumCrossStaff(tuplet, tupletNum);
    // Additional checks are required if tuplet is fully cross-staff and is
    // part of the cross-staff beam (mirrors adjusttupletsyfunctor.cpp:144-158).
    bool isPartialBeamTuplet = false;
    if (hasNumAlignedBeam && tuplet.crossStaff != null) {
      final dynamic beamForPartial = tuplet.numAlignedBeam;
      try {
        final List<dynamic> coords =
            (beamForPartial.beamSegment.getElementCoordRefs() as List);
        final List<Object> descendants =
            tuplet.findAllDescendantsByClassIdPredicate((ClassId classId) =>
                classId == ClassId.chord ||
                classId == ClassId.note ||
                classId == ClassId.rest);
        final int nbNotesOrChords =
            (beamForPartial.beamSegment.nbNotesOrChords as int?) ??
                coords.length;
        final bool anyNonCrossStaff = coords.any((coord) {
          try {
            final elem = (coord as dynamic).element;
            if (elem == null) return false;
            return (elem as dynamic).crossStaff == null;
          } catch (_) {
            return false;
          }
        });
        if (nbNotesOrChords > descendants.length && anyNonCrossStaff) {
          // Mirrors HasValidTupletNumPosition check (tuplet.cpp:192).
          final Staff? beamStaff = (() {
            try {
              return (beamForPartial as dynamic).beamStaff as Staff?;
            } catch (_) {
              return null;
            }
          })();
          final Staff? tupletCrossStaff = tupletNum.crossStaff is Staff
              ? tupletNum.crossStaff as Staff
              : null;
          if (tupletCrossStaff != null && beamStaff != null) {
            if (!hasValidTupletNumPosition(
                tuplet, tupletCrossStaff, beamStaff)) {
              tupletNum.crossStaff = beamStaff;
              // crossLayer would follow but not needed for positioning here.
            }
          }
          isPartialBeamTuplet = true;
        }
      } catch (_) {
        isPartialBeamTuplet = false;
      }
    }

    final Staff tupletNumStaff =
        tupletNum.crossStaff is Staff ? tupletNum.crossStaff as Staff : staff;
    final int staffSize = staff.drawingStaffSize;
    final int yReference = tupletNumStaff.getDrawingY();
    final int doubleUnit = doc.getDrawingDoubleUnit(staffSize);

    // The num is on its own.
    final StaffrelBasic numPos = tuplet.drawingNumPos;
    final int numVerticalMargin =
        (numPos == StaffrelBasic.above) ? doubleUnit : -doubleUnit;
    final int staffHeight = doc.getDrawingStaffSize(staffSize);
    final int adjustedPosition =
        (numPos == StaffrelBasic.above) ? 0 : -staffHeight;
    if (!hasNumAlignedBeam) {
      tupletNum.setDrawingYRel(adjustedPosition);
    }

    // Calculate relative Y for the tupletNum.
    final int margin = 2 * doc.getDrawingUnit(staffSize);
    final AdjustTupletNumOverlapFunctor adjustTupletNumOverlap =
        AdjustTupletNumOverlapFunctor(
            tupletNum, tupletNumStaff, numPos, tupletNum.getDrawingY());
    adjustTupletNumOverlap.setHorizontalMargin(margin);
    tuplet.process(adjustTupletNumOverlap);
    int yRel = adjustTupletNumOverlap.getDrawingY() - yReference;

    // If we have a beam, see if we can move it to more appropriate position
    // (mirrors adjusttupletsyfunctor.cpp:182-194, now possible after 05-31).
    if (hasNumAlignedBeam &&
        (tuplet.crossStaff == null || isPartialBeamTuplet) &&
        tuplet.findDescendantByType(ClassId.artic) == null) {
      final dynamic beam = tuplet.numAlignedBeam;
      int xMid;
      try {
        xMid = _tupletNumXMid(tuplet, tupletNum, doc);
      } catch (_) {
        xMid = tupletNum.getDrawingX();
      }
      int startingY = 0;
      int startingX = 0;
      double beamSlope = 0.0;
      try {
        startingY = beam.beamSegment.getStartingY() as int;
        startingX = beam.beamSegment.getStartingX() as int;
        beamSlope = beam.beamSegment.beamSlope as double;
      } catch (_) {}
      final int yMid = startingY + (beamSlope * (xMid - startingX)).toInt();
      final int beamYRel = yMid - yReference + numVerticalMargin;
      if (((numPos == StaffrelBasic.above) && (beamYRel > 0)) ||
          ((numPos == StaffrelBasic.below) && (beamYRel < -staffHeight))) {
        yRel = beamYRel;
      } else {
        yRel += numVerticalMargin;
      }
    } else {
      yRel += numVerticalMargin;
    }

    // If yRel turns out to be too far from the tuplet - try to adjust it
    // accordingly, aligning with the staff top/bottom sides, unless doing so
    // will make the tuplet number overlap.
    if (((numPos == StaffrelBasic.below) && (yRel > adjustedPosition)) ||
        ((numPos == StaffrelBasic.above) && (yRel < adjustedPosition))) {
      yRel = adjustedPosition;
    }

    // Mirrors the FTrem correction (adjusttupletsyfunctor.cpp:203-217) — now
    // reachable after the beam phase (m_yBeam is populated).
    final Object? fTremObj = tuplet.findDescendantByType(ClassId.fTrem);
    if (fTremObj != null) {
      try {
        final dynamic fTrem = fTremObj;
        final List<dynamic> coords =
            fTrem.beamSegment.getElementCoordRefs() as List<dynamic>;
        if (coords.length >= 2) {
          final int y1 = (coords[0] as dynamic).yBeam as int;
          final int y2 = (coords[1] as dynamic).yBeam as int;
          final int currentPosition = tuplet.getDrawingY() + yRel;
          if ((numPos == StaffrelBasic.above) &&
              (currentPosition < (y1 + y2) ~/ 2)) {
            yRel += (y1 + y2) ~/ 2 - currentPosition;
          } else if ((numPos == StaffrelBasic.below) &&
              (currentPosition + margin > (y1 + y2) ~/ 2)) {
            yRel += (y1 + y2) ~/ 2 - (currentPosition + margin);
          }
        }
      } catch (_) {}
    }

    tupletNum.setDrawingYRel(yRel);
  }

  /// Mirrors `AdjustTupletsYFunctor::AdjustTupletBracketBeamY` (:223). Only
  /// reachable once the beam segment geometry exists (Phase 5); it is ported
  /// verbatim so the future phase only has to provide
  /// [_beamStartingYFor] / [_beamSlopeFor].
  void _adjustTupletBracketBeamY(
      Tuplet tuplet, TupletBracket bracket, Beam beam, Staff staff) {
    final int staffSize = staff.drawingStaffSize;
    final int doubleUnit = doc.getDrawingDoubleUnit(staffSize);
    final StaffrelBasic bracketPos = tuplet.drawingBracketPos;
    final int sign = (bracketPos == StaffrelBasic.above) ? 1 : -1;
    int bracketVerticalMargin = sign * doubleUnit;

    final int startingY = _beamStartingYFor(beam);
    final int startingX = _beamStartingXFor(beam);
    final double beamSlope = _beamSlopeFor(beam);

    // Check for possible articulations.
    final List<Object> artics = tuplet.findAllDescendantsByType(ClassId.artic);

    int articPadding = 0;
    for (final Object artic in artics) {
      if (!(artic as LayerElement).hasSelfBB()) continue;
      if (bracketPos == StaffrelBasic.above) {
        // Left point when slope is going up and right when going down.
        final int relevantX =
            (beamSlope > 0) ? artic.getSelfLeft() : artic.getSelfRight();
        final int currentYRel =
            (startingY + beamSlope * (relevantX - startingX)).toInt();
        final int articYRel = artic.getSelfTop();
        articPadding = _minInt(currentYRel - articYRel, articPadding);
      } else {
        // Right point when slope is going up and left when going down.
        final int relevantX =
            (beamSlope > 0) ? artic.getSelfRight() : artic.getSelfLeft();
        final int currentYRel =
            (startingY + beamSlope * (relevantX - startingX)).toInt();
        final int articYRel = artic.getSelfBottom();
        articPadding = _maxInt(currentYRel - articYRel, articPadding);
      }
    }

    // Check for overlap with rest elements. This might happen when tuplet has
    // rest and beam children that are on the same level in encoding - there
    // might be overlap of bracket with rest in that case.
    final List<Object> restDescendants =
        tuplet.findAllDescendantsByType(ClassId.rest);

    int restAdjust = 0;
    final int bracketRel =
        bracket.drawingYRel - articPadding + bracketVerticalMargin;
    final int bracketPosition =
        (bracket.getSelfTop() + bracket.getSelfBottom() + bracketRel) ~/ 2;
    for (final Object descendant in restDescendants) {
      if ((descendant as LayerElement).getFirstAncestor(ClassId.beam) != null ||
          !descendant.hasSelfBB()) {
        continue;
      }
      if (bracketPos == StaffrelBasic.above) {
        if (bracketPosition < descendant.getSelfTop()) {
          final int verticalShift = descendant.getSelfTop() - bracketPosition;
          if ((restAdjust == 0) || (restAdjust < verticalShift)) {
            restAdjust = verticalShift;
          }
        }
      } else {
        if (bracketPosition > descendant.getSelfBottom()) {
          final int verticalShift =
              descendant.getSelfBottom() - bracketPosition;
          if ((restAdjust == 0) || (restAdjust > verticalShift)) {
            restAdjust = verticalShift;
          }
        }
      }
    }
    if (restAdjust != 0) bracketVerticalMargin += restAdjust;

    final int yReference = staff.getDrawingY();
    bracket.setDrawingYRel(
        bracket.drawingYRel - articPadding + bracketVerticalMargin);

    // Make sure that there are no overlaps with staff lines.
    final int staffMargin = (bracketPos == StaffrelBasic.above)
        ? yReference + doubleUnit
        : yReference - doc.getDrawingStaffSize(staffSize) - doubleUnit;

    final int leftMargin =
        sign * (staffMargin - _bracketDrawingYLeft(tuplet, bracket));
    final int rightMargin =
        sign * (staffMargin - _bracketDrawingYRight(tuplet, bracket));
    final int maxMargin = _maxInt(leftMargin, rightMargin);

    if (maxMargin > 0) {
      int bracketAdjust = 0;
      if ((leftMargin > 0) && (rightMargin > 0)) {
        bracketAdjust = _minInt(leftMargin, rightMargin);
      }

      if (bracketAdjust > 0) {
        bracket.setDrawingYRel(bracket.drawingYRel + sign * bracketAdjust);
      }
      if (leftMargin > 0) {
        bracket.drawingYRelLeft = sign * (leftMargin - bracketAdjust);
      }
      if (rightMargin > 0) {
        bracket.drawingYRelRight = sign * (rightMargin - bracketAdjust);
      }
    }

    if (beam.crossStaffContent != null) {
      final dynamic crossContent = beam.crossStaffContent;
      if ((bracketPos == StaffrelBasic.below) &&
          ((crossContent.n ?? 0) > (staff.n ?? 0))) {
        bracket.drawingYRelLeft -= doubleUnit ~/ 4;
        bracket.drawingYRelRight -= doubleUnit ~/ 4;
      }
    }
  }

  /// Mirrors `AdjustTupletsYFunctor::CalcBracketShift` (:311).
  int calcBracketShift(
      Point referencePoint, double slope, int sign, List<Point> obstacles) {
    int shift = 0;
    for (final Point obstacle in obstacles) {
      final double lineShift = obstacle.y - slope * obstacle.x;
      final int dist =
          (slope * referencePoint.x + lineShift - referencePoint.y).toInt();
      shift = _maxInt(dist * sign, shift);
    }
    return shift;
  }
}

// ---------------------------------------------------------------------------
// AdjustTupletNumOverlapFunctor
// ---------------------------------------------------------------------------

/// Calculates the Y relative position of a tupletNum based on overlaps with
/// other elements (mirrors `vrv::AdjustTupletNumOverlapFunctor`). Not part of
/// the pipeline: instantiated inside [AdjustTupletsYFunctor], exactly like in
/// the C++.
class AdjustTupletNumOverlapFunctor extends Functor {
  /// The tupletNum for which the relative position is calculated (mirrors
  /// `m_tupletNum`).
  final TupletNum tupletNum;

  /// The drawing position of the tupletNum (mirrors `m_drawingNumPos`).
  final StaffrelBasic drawingNumPos;

  /// The margins for the tupletNum overlap (mirrors `m_horizontalMargin` /
  /// `m_verticalMargin`).
  int horizontalMargin = 0;
  int verticalMargin = 0;

  /// The staff relevant for positioning the tuplet (mirrors `m_staff`).
  final Staff staff;

  /// The drawing Y position (mirrors `m_drawingY`).
  int drawingY;

  AdjustTupletNumOverlapFunctor(
      this.tupletNum, this.staff, this.drawingNumPos, this.drawingY);

  void setHorizontalMargin(int margin) => horizontalMargin = margin;
  void setVerticalMargin(int margin) => verticalMargin = margin;
  int getDrawingY() => drawingY;

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (!layerElement.isAny(const {
          ClassId.accid,
          ClassId.artic,
          ClassId.chord,
          ClassId.dot,
          ClassId.flag,
          ClassId.note,
          ClassId.rest,
          ClassId.stem,
        }) ||
        !layerElement.hasSelfBB()) {
      return FunctorCode.continue_;
    }

    if (layerElement.isAny(const {ClassId.chord, ClassId.note, ClassId.rest}) &&
        (((layerElement.crossStaff != null ||
                layerElement.getFirstAncestor(ClassId.staff) != staff) &&
            layerElement.crossStaff != staff))) {
      return FunctorCode.siblings;
    }

    if (!tupletNum.horizontalSelfOverlap(layerElement, horizontalMargin) &&
        !tupletNum.verticalSelfOverlap(layerElement, verticalMargin)) {
      return FunctorCode.continue_;
    }

    int stemAdjust = 0;
    if (layerElement.classId == ClassId.stem) {
      stemAdjust = (layerElement as Stem).drawingStemAdjust;
    }
    if (drawingNumPos == StaffrelBasic.above) {
      final int dist = layerElement.getSelfTop();
      if (drawingY < dist) drawingY = dist + stemAdjust;
    } else {
      final int dist = layerElement.getSelfBottom();
      if (drawingY > dist) drawingY = dist + stemAdjust;
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// AdjustTupletWithSlursFunctor
// ---------------------------------------------------------------------------

/// Adjusts the Y position of tuplets with inner slurs (mirrors
/// `vrv::AdjustTupletWithSlursFunctor`). Runs after the slurs pass, so their
/// positions are final.
class AdjustTupletWithSlursFunctor extends DocFunctor {
  AdjustTupletWithSlursFunctor(super.doc);

  @override
  FunctorCode visitTuplet(Tuplet tuplet) {
    final TupletBracket? tupletBracket =
        tuplet.getFirst(ClassId.tupletBracket) as TupletBracket?;
    if (tupletBracket == null || tuplet.innerSlurs.isEmpty) {
      return FunctorCode.siblings;
    }
    final TupletNum? tupletNum =
        tuplet.getFirst(ClassId.tupletNum) as TupletNum?;

    final Staff? staffOrCross = tuplet.getAncestorStaffResolveCrossStaff();
    final Staff staff = staffOrCross ?? tuplet.getAncestorStaffLayout();
    final int margin = doc.getDrawingUnit(staff.drawingStaffSize) ~/ 2;
    final StaffrelBasic bracketPos = tuplet.drawingBracketPos;
    final int sign = (bracketPos == StaffrelBasic.above) ? 1 : -1;

    final int xLeft =
        tuplet.drawingLeft!.getDrawingX() + tupletBracket.drawingXRelLeft;
    final int xRight =
        tuplet.drawingRight!.getDrawingX() + tupletBracket.drawingXRelRight;
    final int yLeft = _bracketDrawingYLeft(tuplet, tupletBracket);
    final int yRight = _bracketDrawingYRight(tuplet, tupletBracket);
    final double tupletSlope = (yRight - yLeft) / (xRight - xLeft);
    int tupletShift = 0;

    for (final dynamic curve in tuplet.innerSlurs) {
      final FloatingCurvePositioner positioner =
          curve as FloatingCurvePositioner;
      final int shift =
          tupletBracket.intersectsCurve(positioner, Accessor.content, margin) *
              sign;
      if (shift > 0) {
        // The shift is calculated from the entire bounding box of the tuplet
        // bracket. If the bracket is angled and the slur is short, then this
        // might be too coarse. We reduce the shift by the height of the
        // subbox that cannot be hit.
        final List<Point> points = positioner.getPoints();
        final int curveXLeft = _maxInt(points[0].x, xLeft);
        final int curveXRight = _minInt(points[3].x, xRight);
        final int curveYLeft =
            (tupletSlope * (curveXLeft - xLeft)).toInt() + yLeft;
        final int curveYRight =
            (tupletSlope * (curveXRight - xLeft)).toInt() + yLeft;

        int reduction = 0;
        if (bracketPos == StaffrelBasic.above) {
          reduction = _minInt(curveYLeft, curveYRight) - _minInt(yLeft, yRight);
        } else {
          reduction = _maxInt(yLeft, yRight) - _maxInt(curveYLeft, curveYRight);
        }
        tupletShift = _maxInt(shift - reduction, tupletShift);
      }
    }

    // Apply the tuplet shift from slurs.
    if (tupletShift != 0) {
      tupletBracket
          .setDrawingYRel(tupletBracket.drawingYRel + sign * tupletShift);
      if (tupletNum != null) {
        tupletNum.setDrawingYRel(tupletNum.drawingYRel + sign * tupletShift);
      }
    }

    return FunctorCode.siblings;
  }
}

int _minInt(int a, int b) => a < b ? a : b;
int _maxInt(int a, int b) => a > b ? a : b;

// ---------------------------------------------------------------------------
// Model helpers (ports of the tuplet.cpp / elementpart.cpp fragments used by
// the functors above)
// ---------------------------------------------------------------------------

/// Mirrors `Doc::GetGlyphWidth(code, staffSize, graceSize)` (resources
/// backed); falls back to the tabulated approximation of
/// `Doc.getGlyphWidth` when the fonts are unavailable. The point size is
/// `CalcMusicFontSize` (unit * 8 scaled by staffSize), cue-sized when asked —
/// exactly like `Doc::GetDrawingSmuflFont` feeding the C++ formula.
int _docGetGlyphWidth(Doc doc, int code, int staffSize, bool graceSize) {
  _TupletGlyphMetrics.ensure();
  final Resources resources = _TupletGlyphMetrics.resources;
  final Glyph? glyph =
      _TupletGlyphMetrics.ok ? resources.getGlyphByCode(code) : null;
  if (glyph == null) {
    return doc.getGlyphWidth(code, staffSize, graceSize);
  }
  int pointSize = (doc.options.unit.value * 8 * staffSize / 100).toInt();
  if (graceSize) pointSize = doc.getCueSize(pointSize);
  return (glyph.horizAdvX * pointSize) ~/ glyph.unitsPerEm;
}

class _TupletGlyphMetrics {
  static bool _done = false;
  static late final Resources resources;

  static void ensure() {
    if (_done) return;
    _done = true;
    // Repo convention (00-MESTRE §4.6): consumers must point the resources
    // at the package assets folder; the static default ('data') is wrong for
    // this layout.
    final Resources res = Resources();
    res.path = 'assets/data';
    if (!res.ok) res.initFonts();
    resources = res;
  }

  static bool get ok => resources.ok;
}

/// The left/right `drawingXRel` values computed by
/// `Tuplet::GetDrawingLeftRightXRel` (tuplet.cpp:272).
class TupletsXRel {
  TupletsXRel(this.left, this.right);
  final int left;
  final int right;
}

/// Mirrors `Tuplet::GetDrawingLeftRightXRel` (tuplet.cpp:272-310).
TupletsXRel _getDrawingLeftRightXRel(Tuplet tuplet, Doc doc) {
  assert(tuplet.drawingLeft != null);
  assert(tuplet.drawingRight != null);

  int xRelLeft = 0;

  if (tuplet.drawingLeft!.classId == ClassId.note) {
    //
  } else if (tuplet.drawingLeft!.classId == ClassId.rest) {
    //
  } else if (tuplet.drawingLeft!.classId == ClassId.chord) {
    final Chord chord = tuplet.drawingLeft! as Chord;
    xRelLeft = chord.getXMin() - chord.getDrawingX();
  }

  int xRelRight = 0;

  if (tuplet.drawingRight!.classId == ClassId.note) {
    xRelRight += 2 * _getDrawingRadius(tuplet.drawingRight!, doc);
  } else if (tuplet.drawingRight!.classId == ClassId.rest) {
    xRelRight += (tuplet.drawingRight!).getSelfX2();
  } else if (tuplet.drawingRight!.classId == ClassId.chord) {
    final Chord chord = tuplet.drawingRight! as Chord;
    xRelRight = chord.getXMax() -
        chord.getDrawingX() +
        2 * _getDrawingRadius(chord, doc);
  }

  return TupletsXRel(xRelLeft, xRelRight);
}

/// Mirrors `LayerElement::GetDrawingRadius` (layerelement.cpp) reduced to
/// NOTE / CHORD / REST (the only callers within this file). The glyph width
/// mirror reads the SMuFL resources directly (same pattern as
/// `View+BBoxDeviceContext.glyphWidth`) so values match the C++ when the fonts are
/// available, falling back to the tabulated approximation otherwise.
int _getDrawingRadius(LayerElement element, Doc doc) {
  if (!element.isAny(const {ClassId.chord, ClassId.note, ClassId.rest})) {
    return 0;
  }

  int code = 0;
  MeiDuration dur = MeiDuration.dur4;
  final Staff staff = element.getAncestorStaffLayout();
  bool isMensuralDur = false;
  if (element.classId == ClassId.note) {
    final Note note = element as Note;
    final DurationInterface duration = note;
    dur = note.getDrawingDur();
    isMensuralDur = duration.isMensuralDur;
    code = _noteheadGlyphForDur(dur);
  } else if (element.classId == ClassId.chord) {
    final Chord chord = element as Chord;
    final DurationInterface duration = chord;
    dur = duration.getActualDur();
    isMensuralDur = duration.isMensuralDur;
    code = _noteheadGlyphForDur(dur);
  } else if (element.classId == ClassId.rest) {
    code = smuflE0A4NoteheadBlack;
  }

  // Mensural note shorter than DURATION_breve (not exercised by the CMN
  // corpus; guard through the mensural-notetype reading).
  if (isMensuralDur && dur.value <= MeiDuration.breve.value) {
    return doc.getDrawingBrevisWidth(staff.drawingStaffSize);
  }

  if (code == 0) return 0;

  return _docGetGlyphWidth(
          doc, code, staff.drawingStaffSize, element.drawingCueSize) ~/
      2;
}

/// Mirrors `Note::GetNoteheadGlyph` duration mapping (note.cpp).
int _noteheadGlyphForDur(MeiDuration dur) {
  if (dur == MeiDuration.breve) return smuflE0A1NoteheadDoubleWholeSquare;
  if (dur == MeiDuration.longa) return smuflE0A1NoteheadDoubleWholeSquare;
  if (dur == MeiDuration.dur1) return smuflE0A2NoteheadWhole;
  if (dur == MeiDuration.dur2) return smuflE0A3NoteheadHalf;
  return smuflE0A4NoteheadBlack;
}

/// Mirrors `TupletBracket::GetDrawingXLeft` (elementpart.cpp:153).
int _bracketDrawingXLeft(Tuplet tuplet, TupletBracket bracket) =>
    tuplet.drawingLeft!.getDrawingX() + bracket.drawingXRelLeft;

/// Mirrors `TupletBracket::GetDrawingXRight` (:161).
int _bracketDrawingXRight(Tuplet tuplet, TupletBracket bracket) =>
    tuplet.drawingRight!.getDrawingX() + bracket.drawingXRelRight;

/// Mirrors `TupletBracket::GetDrawingYLeft` (:169): aligned to the beam when
/// the bracket has one, otherwise `GetDrawingY() + m_drawingYRelLeft`. The
/// beam branch requires the segment data (deviation: absent headlessly, falls
/// back to the plain value).
int _bracketDrawingYLeft(Tuplet tuplet, TupletBracket bracket) {
  final int plain = bracket.getDrawingY() + bracket.drawingYRelLeft;
  final dynamic beam = tuplet.bracketAlignedBeam;
  if (beam == null) return plain;
  final int? startingY = _segmentStartYOrNull(beam);
  if (startingY == null) return plain;
  final int xLeft = tuplet.drawingLeft!.getDrawingX() + bracket.drawingXRelLeft;
  return startingY +
      (_beamSlope(beam) * (xLeft - _segmentStartX(beam))).toInt() +
      bracket.drawingYRel +
      bracket.drawingYRelLeft;
}

/// Mirrors `TupletBracket::GetDrawingYRight` (:181); same beam caveat.
int _bracketDrawingYRight(Tuplet tuplet, TupletBracket bracket) {
  final int plain = bracket.getDrawingY() + bracket.drawingYRelRight;
  final dynamic beam = tuplet.bracketAlignedBeam;
  if (beam == null) return plain;
  final int? startingY = _segmentStartYOrNull(beam);
  if (startingY == null) return plain;
  final int xRight =
      tuplet.drawingRight!.getDrawingX() + bracket.drawingXRelRight;
  return startingY +
      (_beamSlope(beam) * (xRight - _segmentStartX(beam))).toInt() +
      bracket.drawingYRel +
      bracket.drawingYRelRight;
}

/// Mirrors `Tuplet::CalculateTupletNumCrossStaff` (tuplet.cpp:146).
void calculateTupletNumCrossStaff(Tuplet tuplet, LayerElement layerElement) {
  // If tuplet is fully cross-staff, just return it - it's enough.
  if (tuplet.crossStaff != null) {
    layerElement.crossStaff = tuplet.crossStaff;
    layerElement.crossLayer = tuplet.crossLayer;
    return;
  }

  final Staff staff = tuplet.getAncestorStaffLayout();
  // Find if there is a mix of cross-staff and non-cross-staff elements in
  // the tuplet.
  final List<Object> descendants = tuplet.findAllDescendantsByClassIdPredicate(
      (ClassId classId) =>
          classId == ClassId.chord ||
          classId == ClassId.note ||
          classId == ClassId.rest);

  Staff? crossStaff;
  dynamic crossLayer;
  int crossStaffCount = 0;
  for (final Object object in descendants) {
    final LayerElement durElement = object as LayerElement;
    if (crossStaff != null &&
        durElement.crossStaff != null &&
        durElement.crossStaff != crossStaff) {
      crossStaff = null;
      // We can stop here.
      break;
    } else if (durElement.crossStaff != null) {
      ++crossStaffCount;
      crossStaff = durElement.crossStaff as Staff;
      crossLayer = durElement.crossLayer;
    }
  }
  if (crossStaff == null) return;

  // In case most elements of the tuplet are cross-staff we need to make sure
  // there is proper positioning of the tuplet number.
  final int descendantCount = descendants.length;
  final bool isMostlyCrossStaff = crossStaffCount > descendantCount ~/ 2;
  if ((isMostlyCrossStaff &&
          hasValidTupletNumPosition(tuplet, crossStaff, staff)) ||
      (!isMostlyCrossStaff &&
          !hasValidTupletNumPosition(tuplet, staff, crossStaff))) {
    layerElement.crossStaff = crossStaff;
    layerElement.crossLayer = crossLayer;
  }
}

/// Mirrors `Tuplet::HasValidTupletNumPosition` (tuplet.cpp:192).
bool hasValidTupletNumPosition(
    Tuplet tuplet, Staff preferredStaff, Staff otherStaff) {
  final dynamic beam = tuplet.numAlignedBeam;
  if (beam == null) return true;
  if (beam.drawingPlace == Beamplace.mixed) return false;

  if ((preferredStaff.n ?? 0) < (otherStaff.n ?? 0)) {
    if ((beam.drawingPlace == Beamplace.below) &&
        (tuplet.drawingNumPos == StaffrelBasic.below)) {
      return false;
    }
  } else {
    if ((beam.drawingPlace == Beamplace.above) &&
        (tuplet.drawingNumPos == StaffrelBasic.above)) {
      return false;
    }
  }

  return true;
}

/// Reads the drawing stem direction through the managed stem (mirrors
/// `StemmedDrawingInterface::GetDrawingStemDir`, drawinginterface.h).
Stemdirection _stemDirOf(LayerElement element) {
  if (element is StemmedDrawingInterface) {
    final dynamic stem = (element as dynamic).getDrawingStem();
    if (stem != null) return stem.getDrawingStemDir() as Stemdirection;
  }
  return Stemdirection.none;
}

/// Mirrors `Tuplet::CalcDrawingBracketAndNumPos` (tuplet.cpp:208).
void _calcDrawingBracketAndNumPos(Tuplet tuplet, bool tupletNumHead) {
  tuplet.drawingBracketPos = StaffrelBasic.none;

  if (tuplet.hasBracketPlace) {
    tuplet.drawingBracketPos = tuplet.bracketPlace!;
  }

  if (tuplet.hasNumPlace) {
    tuplet.drawingNumPos = tuplet.numPlace!;
  } else {
    tuplet.drawingNumPos = tuplet.drawingBracketPos;
  }

  // If both are given we are all good (num is set in any case if bracket is).
  if (tuplet.drawingBracketPos != StaffrelBasic.none) {
    return;
  }

  // There are unbeamed notes of two different beams: treat all the notes as
  // unbeamed. The first step is to calculate all the stem directions.
  int ups = 0, downs = 0;
  for (final Object child in tuplet.getList()) {
    if (child is Chord) {
      if (_stemDirOf(child) == Stemdirection.up) {
        ++ups;
      } else {
        ++downs;
      }
    } else if (child is Note) {
      if (child.isChordTone() == null &&
          _stemDirOf(child) == Stemdirection.up) {
        ++ups;
      }
      if (child.isChordTone() == null &&
          _stemDirOf(child) == Stemdirection.down) {
        ++downs;
      }
    }
  }
  // True means up.
  tuplet.drawingBracketPos =
      (ups > downs) ? StaffrelBasic.above : StaffrelBasic.below;

  if (tupletNumHead) {
    tuplet.drawingBracketPos = (tuplet.drawingBracketPos == StaffrelBasic.below)
        ? StaffrelBasic.above
        : StaffrelBasic.below;
  }

  // Also use it for the num unless it is already set.
  if (tuplet.drawingNumPos == StaffrelBasic.none) {
    tuplet.drawingNumPos = tuplet.drawingBracketPos;
  }
}

// ---------------------------------------------------------------------------
// Beam segment accessors — now backed by BeamSegment (task 05-31) so the
// tuplet Y functors can read the beam geometry headlessly.
// ---------------------------------------------------------------------------

int? _segmentStartYOrNull(dynamic beam) {
  try {
    final seg = (beam as dynamic).beamSegment;
    if (seg == null) return null;
    final refs = seg.getElementCoordRefs() as List;
    if (refs.isEmpty) return null;
    return seg.getStartingY() as int?;
  } catch (_) {
    return null;
  }
}

int _segmentStartX(dynamic beam) {
  try {
    return (beam as dynamic).beamSegment.getStartingX() as int;
  } catch (_) {
    return 0;
  }
}

double _beamSlope(dynamic beam) {
  try {
    return (beam as dynamic).beamSegment.beamSlope as double;
  } catch (_) {
    return 0.0;
  }
}

int _beamStartingYFor(dynamic beam) {
  try {
    return (beam as dynamic).beamSegment.getStartingY() as int;
  } catch (_) {
    return 0;
  }
}

int _beamStartingXFor(dynamic beam) {
  try {
    return (beam as dynamic).beamSegment.getStartingX() as int;
  } catch (_) {
    return 0;
  }
}

double _beamSlopeFor(dynamic beam) {
  try {
    return (beam as dynamic).beamSegment.beamSlope as double;
  } catch (_) {
    return 0.0;
  }
}

/// Mirrors `TupletNum::GetDrawingXMid` (elementpart.cpp:240).
int _tupletNumXMid(Tuplet tuplet, TupletNum tupletNum, Doc doc) {
  if (tupletNum.alignedBracket != null) {
    final bracket = tupletNum.alignedBracket as TupletBracket;
    final int xLeft = _bracketDrawingXLeft(tuplet, bracket);
    final int xRight = _bracketDrawingXRight(tuplet, bracket);
    return xLeft + ((xRight - xLeft) ~/ 2);
  } else {
    final LayerElement? left = tuplet.drawingLeft;
    final LayerElement? right = tuplet.drawingRight;
    assert(left != null && right != null);
    int xLeft = left!.getDrawingX();
    int xRight = right!.getDrawingX();
    // Add drawing radius of the right element when doc is available.
    xRight += 2 * _getDrawingRadius(right, doc);
    final dynamic beam = tuplet.numAlignedBeam;
    if (beam != null) {
      try {
        final Beamplace place = beam.drawingPlace as Beamplace;
        if (place == Beamplace.above) {
          xLeft += _getDrawingRadius(left, doc);
        } else if (place == Beamplace.below) {
          xRight -= _getDrawingRadius(right, doc);
        }
      } catch (_) {}
    }
    return xLeft + ((xRight - xLeft) ~/ 2);
  }
}
