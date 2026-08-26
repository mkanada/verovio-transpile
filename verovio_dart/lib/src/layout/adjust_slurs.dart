/// Port of `adjustslursfunctor.h/cpp` — AdjustSlursFunctor.
///
/// Adjusts the position of the slurs (and phrases): spanned elements are
/// avoided through endpoint shifts, control point shifts and control point
/// offsets, following the steps of `AdjustSlursFunctor::AdjustSlur`.
///
/// Deviations from the C++:
/// - `AdjustSlurFromBulge` (slurs with @bulge) is deferred until the bulge
///   attribute plumbing arrives; such slurs keep their initial curve.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/slur_positioning.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show CurvatureCurvedir;
import 'package:verovio_dart/src/model/basic_elements.dart' show Staff;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

/// Mutable holder for the left / right endpoint shifts standing in for the
/// C++ `int &` output parameters.
class EndPointShifts {
  int left = 0;
  int right = 0;
}

// ---------------------------------------------------------------------------
// AdjustSlursFunctor
// ---------------------------------------------------------------------------

/// Adjusts the position of the slurs staff by staff (mirrors
/// `vrv::AdjustSlursFunctor`).
class AdjustSlursFunctor extends DocFunctor {
  AdjustSlursFunctor(super.doc) {
    crossStaffSlurs = false;
    resetCurrent();
  }

  /// True when at least one slur was cross-staff (mirrors
  /// `m_crossStaffSlurs`).
  bool crossStaffSlurs = false;

  /// The current curve positioner (mirrors `m_currentCurve`).
  FloatingCurvePositioner? currentCurve;

  /// The current slur object (mirrors `m_currentSlur`); the slur behaviour
  /// comes from the [SlurPositioning] extension.
  Object? currentSlur;

  void resetCurrent() {
    currentCurve = null;
    currentSlur = null;
  }

  @override
  FunctorCode visitStaffAlignment(StaffAlignment staffAlignment) {
    final Staff? staff = staffAlignment.getStaff();
    if (staff == null) return FunctorCode.continue_;
    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);

    // Adjust each slur such that spanned elements are avoided
    final List<FloatingCurvePositioner> positioners =
        <FloatingCurvePositioner>[];
    for (final FloatingPositioner positioner
        in staffAlignment.getFloatingPositioners()) {
      assert(positioner.getObject() != null);
      if (!positioner
          .getObject()!
          .isAny(const {ClassId.phrase, ClassId.slur})) {
        continue;
      }
      currentSlur = positioner.getObject();

      assert(positioner is FloatingCurvePositioner);
      final FloatingCurvePositioner curve =
          positioner as FloatingCurvePositioner;
      currentCurve = curve;

      // Skip if no content bounding box is available
      if (!curve.hasContentBB()) continue;
      positioners.add(curve);

      adjustSlur(unit);

      if (curve.isCrossStaff()) {
        crossStaffSlurs = true;
      }
    }

    resetCurrent();

    // Detection of inner slurs
    final Map<FloatingCurvePositioner, List<FloatingCurvePositioner>>
        innerCurveMap = {};
    for (int i = 0; i < positioners.length; ++i) {
      final Object firstSlur = positioners[i].getObject()!;
      final List<FloatingCurvePositioner> innerCurves =
          <FloatingCurvePositioner>[];
      for (int j = 0; j < positioners.length; ++j) {
        if (i == j) continue;
        final Object secondSlur = positioners[j].getObject()!;
        // Check if second slur is inner slur of first
        if (positioners[j].getSpanningType() == spanningStartEnd) {
          if (firstSlur.hasInnerSlurFor(secondSlur)) {
            innerCurves.add(positioners[j]);
            continue;
          }
        }
        // Adjust positioning of slurs with common start / end
        final List<Point> points1 = positioners[i].getPoints();
        final List<Point> points2 = positioners[j].getPoints();
        if ((identical(firstSlur.slurEnd, secondSlur.slurStart)) &&
            BoundingBox.arePointsClose(points1[3], points2[0], unit)) {
          positioners[i].moveBackHorizontal(-unit ~/ 2);
          positioners[j].moveFrontHorizontal(unit ~/ 2);
        }
        if ((identical(firstSlur.slurStart, secondSlur.slurStart)) &&
            BoundingBox.arePointsClose(points1[0], points2[0], unit) &&
            (points1[3].x > points2[3].x)) {
          int diff = points2[0].y - points1[0].y;
          diff += ((positioners[i].getDir() == CurvatureCurvedir.below)
              ? -unit
              : unit);
          positioners[i].moveFrontVertical(diff);
        }
        if ((identical(firstSlur.slurEnd, secondSlur.slurEnd)) &&
            BoundingBox.arePointsClose(points1[3], points2[3], unit) &&
            (points1[0].x < points2[0].x)) {
          int diff = points2[3].y - points1[3].y;
          diff += ((positioners[i].getDir() == CurvatureCurvedir.below)
              ? -unit
              : unit);
          positioners[i].moveBackVertical(diff);
        }
      }
      if (innerCurves.isNotEmpty) {
        innerCurveMap[positioners[i]] = innerCurves;
      }
    }

    // Adjust outer slurs w.r.t. inner slurs
    innerCurveMap.forEach((curve, innerCurves) {
      currentCurve = curve;
      currentSlur = curve.getObject();

      adjustOuterSlur(innerCurves, unit);
    });

    resetCurrent();

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    system.systemAligner.process(this);

    return FunctorCode.siblings;
  }

  // -------------------------------------------------------------------------
  // Adjustment steps
  // -------------------------------------------------------------------------

  /// Mirrors `AdjustSlursFunctor::AdjustSlur`.
  void adjustSlur(int unit) {
    assert(currentCurve != null);
    assert(currentSlur != null);

    final FloatingCurvePositioner curve = currentCurve!;
    final Object slur = currentSlur!;

    List<Point> points = curve.getPoints();
    BezierCurve bezier = BezierCurve.of(points[0], points[1], points[2], points[3]);
    slur.initBezierControlSidesFor(bezier, curve.getDir());
    bezier.updateControlPointParams();

    final int margin = (doc.getOptions().slurMargin.value * unit).toInt();
    final double flexibility = doc.getOptions().slurEndpointFlexibility.value;
    final double symmetry = doc.getOptions().slurSymmetry.value;

    // STEP 1: Filter spanned elements and discard certain bounding boxes even
    // though they collide
    filterSpannedElements(bezier, margin);

    // STEP 2: Detect collisions near the endpoints and switch to secondary
    // endpoints if necessary
    final NearEndCollision nearEndCollision =
        detectCollisionsNearEnd(bezier, margin);
    slur.calcInitialCurveFor(doc, curve, nearEndCollision);
    if (nearEndCollision.endPointsAdjusted) {
      points = curve.getPoints();
      bezier = BezierCurve.of(points[0], points[1], points[2], points[3]);
      bezier.updateControlPointParams();
      slur.calcSpannedElementsFor(doc, curve);
      filterSpannedElements(bezier, margin);
    } else {
      curve.updatePoints(bezier);
    }

    // STEP 3: Calculate the vertical adjustment of endpoints. This shifts
    // the slur vertically. Only collisions near the endpoints are taken into
    // account.
    final (int endPointShiftLeft, int endPointShiftRight) =
        calcEndPointShift(bezier, flexibility, margin);
    applyEndPointShift(bezier, endPointShiftLeft, endPointShiftRight);

    // Special handling if bulge is prescribed from here on.
    // Deviation: AdjustSlurFromBulge is deferred; see the library header.

    // STEP 4: Calculate the horizontal offset of the control points.
    // The idea is to shift control points to the outside if there is an
    // obstacle in the vicinity of the corresponding endpoint.
    if (allowControlOffsetAdjustment(bezier, symmetry, unit)) {
      final (bool ok, int controlPointOffsetLeft, int controlPointOffsetRight) =
          calcControlPointOffset(bezier, margin);
      if (ok) {
        bezier.setLeftControlOffset(controlPointOffsetLeft);
        bezier.setRightControlOffset(controlPointOffsetRight);
        bezier.updateControlPoints();
        curve.updatePoints(bezier);
      }
    }

    // STEP 5: Calculate the vertical shift of the control points.
    // For each colliding bounding box we formulate a constraint ax + by >= c
    // where x, y denote the vertical adjustments of the control points and c
    // is the size of the collision. After collecting all constraints we
    // calculate a solution.
    final ControlPointAdjustment adjustment =
        calcControlPointVerticalShift(bezier, symmetry, margin);
    final int leftSign =
        (bezier.isLeftControlAbove == adjustment.moveUpwards) ? 1 : -1;
    bezier
        .setLeftControlHeight(bezier.leftControlHeight + leftSign * adjustment.leftShift);
    final int rightSign =
        (bezier.isRightControlAbove == adjustment.moveUpwards) ? 1 : -1;
    bezier.setRightControlHeight(
        bezier.rightControlHeight + rightSign * adjustment.rightShift);
    bezier.updateControlPoints();
    curve.updatePoints(bezier);
    curve.setRequestedStaffSpace(adjustment.requestedStaffSpace);

    // STEP 6: Adjust the slur shape
    if (curve.getDir() != CurvatureCurvedir.mixed) {
      adjustSlurShape(bezier, curve.getDir(), unit);
      curve.updatePoints(bezier);
    }

    // Since we are going to redraw it, reset its bounding box
    curve.resetBoundingBox();
  }

  /// Mirrors `AdjustSlursFunctor::AdjustOuterSlur`.
  void adjustOuterSlur(List<FloatingCurvePositioner> innerCurves, int unit) {
    assert(currentCurve != null);
    assert(currentSlur != null);

    final FloatingCurvePositioner curve = currentCurve!;
    final Object slur = currentSlur!;

    final List<Point> points = curve.getPoints();
    final BezierCurve bezier =
        BezierCurve.of(points[0], points[1], points[2], points[3]);
    slur.initBezierControlSidesFor(bezier, curve.getDir());
    bezier.updateControlPointParams();

    final int margin = (doc.getOptions().slurMargin.value * unit).toInt();
    final double flexibility = doc.getOptions().slurEndpointFlexibility.value;
    final double symmetry = doc.getOptions().slurSymmetry.value;

    // STEP 1: Calculate the vertical adjustment of endpoints. This shifts
    // the slur vertically. Only collisions near the endpoints are taken into
    // account.
    final (int endPointShiftLeft, int endPointShiftRight) =
        calcEndPointShiftWithInner(bezier, innerCurves, flexibility, margin);
    applyEndPointShift(bezier, endPointShiftLeft, endPointShiftRight);

    // STEP 2: Calculate the vertical shift of the control points.
    final ControlPointAdjustment adjustment =
        calcControlPointShift(bezier, innerCurves, symmetry, margin);
    bezier.setLeftControlHeight(bezier.leftControlHeight + adjustment.leftShift);
    bezier.setRightControlHeight(
        bezier.rightControlHeight + adjustment.rightShift);
    bezier.updateControlPoints();
    curve.updatePoints(bezier);

    // STEP 3: Adjust the slur shape
    if (curve.getDir() != CurvatureCurvedir.mixed) {
      adjustSlurShape(bezier, curve.getDir(), unit);
      curve.updatePoints(bezier);
    }

    // Since we are going to redraw it, reset its bounding box
    curve.resetBoundingBox();
  }

  /// Mirrors `FilterSpannedElements`.
  void filterSpannedElements(BezierCurve bezierCurve, int margin) {
    final FloatingCurvePositioner curve = currentCurve!;
    final Object slur = currentSlur!;
    if (bezierCurve.p1.x >= bezierCurve.p2.x) return;

    final int dist = bezierCurve.p2.x - bezierCurve.p1.x;

    for (final CurveSpannedElement spannedElement
        in curve.getSpannedElements()) {
      if (spannedElement.discarded) {
        continue;
      }
      final BoundingBox? bbox = spannedElement.boundingBox;
      if (bbox == null || !bbox.hasSelfBB()) continue;

      final Discard discard = Discard();
      final int intersection = curve.calcDirectionalAdjustment(
          bbox, spannedElement.isBelow, discard,
          margin: margin);
      final int xMiddle = (bbox.getSelfLeft() + bbox.getSelfRight()) ~/ 2;
      final double distanceRatio = (xMiddle - bezierCurve.p1.x) / dist;

      // Check if obstacles completely lie on the other side of the slur
      final int elementHeight = (bbox.getSelfTop() - bbox.getSelfBottom()).abs();
      if (intersection > elementHeight + 4 * margin) {
        // Ignore elements in a different layer near the endpoints
        if (distanceRatio < 0.05) {
          spannedElement.discarded =
              bbox is LayerElement &&
                  _originalLayerN(bbox) !=
                      _boundaryOriginalLayerN(slur.slurStart);
        } else if (distanceRatio > 0.95) {
          spannedElement.discarded =
              bbox is LayerElement &&
                  _originalLayerN(bbox) !=
                      _boundaryOriginalLayerN(slur.slurEnd);
        } else {
          spannedElement.discarded = false;
        }
        // Ignore tuplet numbers
        if (bbox.isClass(ClassId.tupletNum)) {
          spannedElement.discarded = true;
        }
      }
    }
  }

  /// Mirrors `DetectCollisionsNearEnd`.
  NearEndCollision detectCollisionsNearEnd(
      BezierCurve bezierCurve, int margin) {
    final FloatingCurvePositioner curve = currentCurve!;
    final NearEndCollision nearEndCollision = NearEndCollision.initial();
    if (bezierCurve.p1.x >= bezierCurve.p2.x) return nearEndCollision;

    final List<Point> bezierPoints = [
      bezierCurve.p1,
      bezierCurve.c1,
      bezierCurve.c2,
      bezierCurve.p2,
    ];

    for (final CurveSpannedElement spannedElement
        in curve.getSpannedElements()) {
      if (spannedElement.discarded) {
        continue;
      }
      final BoundingBox? bbox = spannedElement.boundingBox;
      if (bbox == null || !bbox.hasSelfBB()) continue;

      final Discard discard = Discard();
      final (int intersectionLeft, int intersectionRight) =
          curve.calcDirectionalLeftRightAdjustment(
              bbox, spannedElement.isBelow, discard,
              margin: margin);

      if ((intersectionLeft > 0) || (intersectionRight > 0)) {
        // Adjust the collision metrics
        final int xLeft = math.max(bezierCurve.p1.x, bbox.getSelfLeft());
        final Point pLeft = Point(
            xLeft, BoundingBox.calcBezierAtPosition(bezierPoints, xLeft));
        double distStart =
            math.max(BoundingBox.calcDistance(bezierCurve.p1, pLeft), 1.0);
        double distEnd =
            math.max(BoundingBox.calcDistance(bezierCurve.p2, pLeft), 1.0);
        nearEndCollision.metricAtStart = math.max(
            intersectionLeft / distStart, nearEndCollision.metricAtStart);
        nearEndCollision.metricAtEnd = math.max(
            intersectionLeft / distEnd, nearEndCollision.metricAtEnd);

        final int xRight = math.min(bezierCurve.p2.x, bbox.getSelfRight());
        final Point pRight = Point(
            xRight, BoundingBox.calcBezierAtPosition(bezierPoints, xRight));
        distStart =
            math.max(BoundingBox.calcDistance(bezierCurve.p1, pRight), 1.0);
        distEnd =
            math.max(BoundingBox.calcDistance(bezierCurve.p2, pRight), 1.0);
        nearEndCollision.metricAtStart = math.max(
            intersectionRight / distStart, nearEndCollision.metricAtStart);
        nearEndCollision.metricAtEnd = math.max(
            intersectionRight / distEnd, nearEndCollision.metricAtEnd);
      }
    }

    return nearEndCollision;
  }

  /// Mirrors `CalcEndPointShift(BezierCurve, double, int)`.
  (int, int) calcEndPointShift(
      BezierCurve bezierCurve, double flexibility, int margin) {
    final FloatingCurvePositioner curve = currentCurve!;
    if (bezierCurve.p1.x >= bezierCurve.p2.x) return (0, 0);

    final EndPointShifts shifts = EndPointShifts();

    final int dist = bezierCurve.p2.x - bezierCurve.p1.x;

    for (final CurveSpannedElement spannedElement
        in curve.getSpannedElements()) {
      if (spannedElement.discarded) {
        continue;
      }
      final BoundingBox? bbox = spannedElement.boundingBox;
      if (bbox == null || !bbox.hasSelfBB()) continue;

      final Discard discard = Discard();
      final (int intersectionLeft, int intersectionRight) =
          curve.calcDirectionalLeftRightAdjustment(
              bbox, spannedElement.isBelow, discard,
              margin: margin);

      if (discard.value) {
        spannedElement.discarded = true;
        continue;
      }

      if ((intersectionLeft > 0) || (intersectionRight > 0)) {
        // Now apply the intersections on the left and right hand side of the
        // bounding box
        final int xLeft = math.max(bezierCurve.p1.x, bbox.getSelfLeft());
        final double distanceRatioLeft = (xLeft - bezierCurve.p1.x) / dist;
        shiftEndPoints(shifts, flexibility, curve, distanceRatioLeft,
            intersectionLeft, spannedElement.isBelow);

        final int xRight = math.min(bezierCurve.p2.x, bbox.getSelfRight());
        final double distanceRatioRight = (xRight - bezierCurve.p1.x) / dist;
        shiftEndPoints(shifts, flexibility, curve, distanceRatioRight,
            intersectionRight, spannedElement.isBelow);
      }
    }

    return (shifts.left, shifts.right);
  }

  /// Mirrors `ApplyEndPointShift`.
  void applyEndPointShift(
      BezierCurve bezierCurve, int endPointShiftLeft, int endPointShiftRight) {
    final FloatingCurvePositioner curve = currentCurve!;
    if ((endPointShiftLeft != 0) || (endPointShiftRight != 0)) {
      final int signLeft = bezierCurve.isLeftControlAbove ? 1 : -1;
      final int signRight = bezierCurve.isRightControlAbove ? 1 : -1;
      bezierCurve.p1.y += signLeft * endPointShiftLeft;
      bezierCurve.p2.y += signRight * endPointShiftRight;
      if (bezierCurve.p1.x != bezierCurve.p2.x) {
        final (double lambda1, double lambda2) =
            bezierCurve.estimateCurveParamForControlPoints();
        bezierCurve.c1.y +=
            signLeft * ((1.0 - lambda1) * endPointShiftLeft).round() +
                signRight * (lambda1 * endPointShiftRight).round();
        bezierCurve.c2.y +=
            signLeft * ((1.0 - lambda2) * endPointShiftLeft).round() +
                signRight * (lambda2 * endPointShiftRight).round();
      }
      bezierCurve.updateControlPointParams();
      curve.updatePoints(bezierCurve);
    }
  }

  /// Mirrors `AllowControlOffsetAdjustment`.
  bool allowControlOffsetAdjustment(
      BezierCurve bezierCurve, double symmetry, int unit) {
    final double distance =
        BoundingBox.calcDistance(bezierCurve.p1, bezierCurve.p2);

    return (distance > symmetry * 40 * unit);
  }

  /// Mirrors `CalcControlPointOffset`.
  (bool, int, int) calcControlPointOffset(BezierCurve bezierCurve, int margin) {
    final FloatingCurvePositioner curve = currentCurve!;
    if (bezierCurve.p1.x >= bezierCurve.p2.x) return (false, 0, 0);

    // Initially we start with the slopes of the lines P1-C1 and P2-C2
    double leftSlopeMax =
        BoundingBox.calcSlope(bezierCurve.p1, bezierCurve.c1).abs();
    double rightSlopeMax =
        BoundingBox.calcSlope(bezierCurve.p2, bezierCurve.c2).abs();
    for (final CurveSpannedElement spannedElement
        in curve.getSpannedElements()) {
      if (spannedElement.discarded) {
        continue;
      }
      final BoundingBox? bbox = spannedElement.boundingBox;
      if (bbox == null || !bbox.hasSelfBB()) continue;

      final int bbY =
          spannedElement.isBelow ? bbox.getSelfTop() : bbox.getSelfBottom();
      final Point pLeft = Point(bbox.getSelfLeft(), bbY);
      final Point pRight = Point(bbox.getSelfRight(), bbY);

      // Prefer the (increased) slope of P1-B1, if larger
      // B1 is the upper left bounding box corner of a colliding obstacle
      if ((pLeft.x > bezierCurve.p1.x + margin) &&
          (bezierCurve.isLeftControlAbove == spannedElement.isBelow)) {
        final double slope = BoundingBox.calcSlope(bezierCurve.p1, pLeft);
        if ((slope > 0.0) && bezierCurve.isLeftControlAbove) {
          final double adjustedSlope = rotateSlope(slope, 10.0, 2.5, true);
          leftSlopeMax = math.max(leftSlopeMax, adjustedSlope);
        }
        if ((slope < 0.0) && !bezierCurve.isLeftControlAbove) {
          final double adjustedSlope = rotateSlope(-slope, 10.0, 2.5, true);
          leftSlopeMax = math.max(leftSlopeMax, adjustedSlope);
        }
      }

      // Prefer the (increased) slope of P2-B2, if larger
      // B2 is the upper right bounding box corner of a colliding obstacle
      if ((pRight.x < bezierCurve.p2.x - margin) &&
          (bezierCurve.isRightControlAbove == spannedElement.isBelow)) {
        final double slope = BoundingBox.calcSlope(bezierCurve.p2, pRight);
        if ((slope < 0.0) && bezierCurve.isRightControlAbove) {
          final double adjustedSlope = rotateSlope(-slope, 10.0, 2.5, true);
          rightSlopeMax = math.max(rightSlopeMax, adjustedSlope);
        }
        if ((slope > 0.0) && !bezierCurve.isRightControlAbove) {
          final double adjustedSlope = rotateSlope(slope, 10.0, 2.5, true);
          rightSlopeMax = math.max(rightSlopeMax, adjustedSlope);
        }
      }
    }

    if ((leftSlopeMax == 0.0) || (rightSlopeMax == 0.0)) return (false, 0, 0);

    // Calculate offset from extreme slope, but use 1/20 of horizontal
    // distance as minimum
    final int minOffset = (bezierCurve.p2.x - bezierCurve.p1.x) ~/ 20;
    int leftOffset = minOffset;
    if (bezierCurve.leftControlOffset > 0) {
      leftOffset = math.max(leftOffset,
          (bezierCurve.leftControlHeight.abs() / leftSlopeMax).toInt());
    }
    int rightOffset = minOffset;
    if (bezierCurve.rightControlOffset > 0) {
      rightOffset = math.max(rightOffset,
          (bezierCurve.rightControlHeight.abs() / rightSlopeMax).toInt());
    }

    return (true, leftOffset, rightOffset);
  }

  /// Mirrors `CalcControlPointVerticalShift`.
  ControlPointAdjustment calcControlPointVerticalShift(
      BezierCurve bezierCurve, double symmetry, int margin) {
    final FloatingCurvePositioner curve = currentCurve!;
    final ControlPointAdjustment adjustment = ControlPointAdjustment();
    if (bezierCurve.p1.x >= bezierCurve.p2.x) return adjustment;

    final List<ControlPointConstraint> aboveConstraints = [];
    final List<ControlPointConstraint> belowConstraints = [];
    int maxIntersectionAbove = 0;
    int maxIntersectionBelow = 0;

    final int dist = bezierCurve.p2.x - bezierCurve.p1.x;

    final List<Point> bezierPoints = [
      bezierCurve.p1,
      bezierCurve.c1,
      bezierCurve.c2,
      bezierCurve.p2,
    ];

    for (final CurveSpannedElement spannedElement
        in curve.getSpannedElements()) {
      if (spannedElement.discarded) {
        continue;
      }
      final BoundingBox? bbox = spannedElement.boundingBox;
      if (bbox == null || !bbox.hasSelfBB()) continue;

      final Discard discard = Discard();
      final (int intersectionLeft, int intersectionRight) =
          curve.calcDirectionalLeftRightAdjustment(
              bbox, spannedElement.isBelow, discard,
              margin: margin);

      if (discard.value) {
        spannedElement.discarded = true;
        continue;
      }

      final List<ControlPointConstraint> constraints =
          spannedElement.isBelow ? belowConstraints : aboveConstraints;

      if ((intersectionLeft > 0) || (intersectionRight > 0)) {
        // Add constraint for the left boundary of the colliding bounding box
        final int xLeft = math.max(bezierCurve.p1.x, bbox.getSelfLeft());
        double distanceRatio = (xLeft - bezierCurve.p1.x) / dist;
        // Ignore obstacles close to the endpoints, because this would result
        // in very large shifts
        if (((0.5 - distanceRatio).abs() < 0.45) && (intersectionLeft > 0)) {
          final double t =
              BoundingBox.calcBezierParamAtPosition(bezierPoints, xLeft);
          constraints.add(ControlPointConstraint(
              3.0 * math.pow(1.0 - t, 2.0) * t,
              3.0 * (1.0 - t) * math.pow(t, 2.0),
              intersectionLeft.toDouble()));
          if (spannedElement.isBelow) {
            maxIntersectionBelow =
                math.max(maxIntersectionBelow, intersectionLeft);
          } else {
            maxIntersectionAbove =
                math.max(maxIntersectionAbove, intersectionLeft);
          }
        }

        // Add constraint for the right boundary of the colliding bounding box
        final int xRight = math.min(bezierCurve.p2.x, bbox.getSelfRight());
        distanceRatio = (xRight - bezierCurve.p1.x) / dist;
        if (((0.5 - distanceRatio).abs() < 0.45) && (intersectionRight > 0)) {
          final double t =
              BoundingBox.calcBezierParamAtPosition(bezierPoints, xRight);
          constraints.add(ControlPointConstraint(
              3.0 * math.pow(1.0 - t, 2.0) * t,
              3.0 * (1.0 - t) * math.pow(t, 2.0),
              intersectionRight.toDouble()));
          if (spannedElement.isBelow) {
            maxIntersectionBelow =
                math.max(maxIntersectionBelow, intersectionRight);
          } else {
            maxIntersectionAbove =
                math.max(maxIntersectionAbove, intersectionRight);
          }
        }
      }
    }


    // Solve the constraints and calculate the adjustment
    if (maxIntersectionAbove > maxIntersectionBelow) {
      final (int leftShift, int rightShift) =
          solveControlPointConstraints(aboveConstraints, symmetry);
      adjustment.leftShift = leftShift;
      adjustment.rightShift = rightShift;
      adjustment.moveUpwards = false;
    } else {
      final (int leftShift, int rightShift) =
          solveControlPointConstraints(belowConstraints, symmetry);
      adjustment.leftShift = leftShift;
      adjustment.rightShift = rightShift;
      adjustment.moveUpwards = true;
    }

    // Determine the requested staff space
    if (bezierCurve.isLeftControlAbove && !bezierCurve.isRightControlAbove) {
      adjustment.requestedStaffSpace =
          math.max(bezierCurve.p1.y - bezierCurve.p2.y + 6 * margin, 0);
    } else if (!bezierCurve.isLeftControlAbove &&
        bezierCurve.isRightControlAbove) {
      adjustment.requestedStaffSpace =
          math.max(bezierCurve.p2.y - bezierCurve.p1.y + 6 * margin, 0);
    }
    if ((maxIntersectionAbove > 0) && (maxIntersectionBelow > 0)) {
      adjustment.requestedStaffSpace = math.max(
          adjustment.requestedStaffSpace,
          maxIntersectionAbove + maxIntersectionBelow);
    }

    return adjustment;
  }

  /// Mirrors `SolveControlPointConstraints`.
  (int, int) solveControlPointConstraints(
      List<ControlPointConstraint> constraints, double symmetry) {
    if (constraints.isEmpty) return (0, 0);

    // Each constraint corresponds to a halfplane in the upper right quadrant.
    // We consider the line through the origin orthogonal to the halfplane's
    // boundary and average the slopes of these orthogonal lines.
    double weightSum = 0.0;
    double weightedAngleSum = 0.0;
    for (final ControlPointConstraint constraint in constraints) {
      // Use the distance of the halfplane's boundary to the origin as weight
      final double weight = constraint.c /
          math.sqrt(constraint.a * constraint.a + constraint.b * constraint.b);
      weightedAngleSum += weight * math.atan(constraint.b / constraint.a);
      weightSum += weight;
    }
    // Depending on symmetry we want the angle to be near PI/4
    double angle = weightedAngleSum / weightSum;
    angle = math.max(symmetry * math.pi / 4.0, angle);
    angle = math.min((2.0 - symmetry) * math.pi / 4.0, angle);
    final double slope = math.tan(angle);

    // Now follow the line with the averaged slope until we have hit all
    // halfplanes. For each constraint we must solve: slope * x = c/b - a/b*x
    double xMax = 0.0;
    for (final ControlPointConstraint constraint in constraints) {
      final double x = constraint.c / (constraint.a + slope * constraint.b);
      xMax = math.max(xMax, x);
    }

    // The point which hits the last halfplane is the desired solution.
    return (xMax.toInt(), (slope * xMax).toInt());
  }

  /// Mirrors `AdjustSlurShape`.
  void adjustSlurShape(
      BezierCurve bezierCurve, CurvatureCurvedir dir, int unit) {
    if (bezierCurve.p1.x >= bezierCurve.p2.x) return;

    // Normalize the slur via rotation (such that p1-p2 is horizontal)
    final double angle = math.atan2(
        bezierCurve.p2.y - bezierCurve.p1.y.toDouble(),
        bezierCurve.p2.x - bezierCurve.p1.x.toDouble());
    bezierCurve.rotate(-angle, bezierCurve.p1);
    bezierCurve.updateControlPointParams();

    // *** STEP 1: Ensure MINIMAL HEIGHT ***
    // <)C1P1P2 should be at least 30 degrees, but allow smaller angles if the
    // midpoint would be lifted more than 6 MEI units. Similar for <)P1P2C2.
    final int sign = (dir == CurvatureCurvedir.above) ? 1 : -1;
    final Point shiftedMidpoint = Point(
        (bezierCurve.p1.x + bezierCurve.p2.x) ~/ 2,
        (bezierCurve.p1.y + bezierCurve.p2.y) ~/ 2 + sign * 6 * unit);
    final double minAngle =
        getMinControlPointAngle(bezierCurve, angle / math.pi * 180.0, unit);
    final bool ignoreLeft = (bezierCurve.c1.x <= bezierCurve.p1.x);
    final bool ignoreRight = (bezierCurve.c2.x >= bezierCurve.p2.x);
    double slopeLeft = BoundingBox.calcSlope(bezierCurve.p1, bezierCurve.c1);
    double slopeRight = BoundingBox.calcSlope(bezierCurve.p2, bezierCurve.c2);
    final double slopeBase = BoundingBox.calcSlope(bezierCurve.p1, bezierCurve.p2);

    if (dir == CurvatureCurvedir.above) {
      double minSlopeLeft = rotateSlope(slopeBase, minAngle, 1.0, true);
      minSlopeLeft = math.min(
          minSlopeLeft, BoundingBox.calcSlope(bezierCurve.p1, shiftedMidpoint));
      slopeLeft = math.max(slopeLeft, minSlopeLeft);
      double minSlopeRight = rotateSlope(slopeBase, minAngle, 1.0, false);
      minSlopeRight = math.max(
          minSlopeRight, BoundingBox.calcSlope(bezierCurve.p2, shiftedMidpoint));
      slopeRight = math.min(slopeRight, minSlopeRight);
    } else if (dir == CurvatureCurvedir.below) {
      double minSlopeLeft = rotateSlope(slopeBase, minAngle, 1.0, false);
      minSlopeLeft = math.max(
          minSlopeLeft, BoundingBox.calcSlope(bezierCurve.p1, shiftedMidpoint));
      slopeLeft = math.min(slopeLeft, minSlopeLeft);
      double minSlopeRight = rotateSlope(slopeBase, minAngle, 1.0, true);
      minSlopeRight = math.min(
          minSlopeRight, BoundingBox.calcSlope(bezierCurve.p2, shiftedMidpoint));
      slopeRight = math.max(slopeRight, minSlopeRight);
    }

    // Update control points
    if (!ignoreLeft) {
      bezierCurve.setLeftControlHeight(
          (slopeLeft * sign * bezierCurve.leftControlOffset).toInt());
    }
    if (!ignoreRight) {
      bezierCurve.setRightControlHeight(
          (slopeRight * -sign * bezierCurve.rightControlOffset).toInt());
    }
    bezierCurve.updateControlPoints();

    // *** STEP 2: Ensure CONVEXITY ***
    // <)C1P1C2 and <)C1P2C2 should be at least 3 degrees
    if (dir == CurvatureCurvedir.above) {
      final double minSlopeLeft = rotateSlope(
          BoundingBox.calcSlope(bezierCurve.p1, bezierCurve.c2), 3.0, 10.0, true);
      slopeLeft = math.max(slopeLeft, minSlopeLeft);
      final double minSlopeRight = rotateSlope(
          BoundingBox.calcSlope(bezierCurve.p2, bezierCurve.c1), 3.0, 10.0, false);
      slopeRight = math.min(slopeRight, minSlopeRight);
    } else if (dir == CurvatureCurvedir.below) {
      final double minSlopeLeft = rotateSlope(
          BoundingBox.calcSlope(bezierCurve.p1, bezierCurve.c2), 3.0, 10.0, false);
      slopeLeft = math.min(slopeLeft, minSlopeLeft);
      final double minSlopeRight = rotateSlope(
          BoundingBox.calcSlope(bezierCurve.p2, bezierCurve.c1), 3.0, 10.0, true);
      slopeRight = math.max(slopeRight, minSlopeRight);
    }

    // Update control points
    if (!ignoreLeft) {
      bezierCurve.setLeftControlHeight(
          (slopeLeft * sign * bezierCurve.leftControlOffset).toInt());
    }
    if (!ignoreRight) {
      bezierCurve.setRightControlHeight(
          (slopeRight * -sign * bezierCurve.rightControlOffset).toInt());
    }
    bezierCurve.updateControlPoints();

    // Rotate back
    bezierCurve.rotate(angle, bezierCurve.p1);

    // Enforce p1.x <= c1.x <= c2.x <= p2.x
    bezierCurve.c1.x = math.max(bezierCurve.p1.x, bezierCurve.c1.x);
    bezierCurve.c2.x = math.max(bezierCurve.c1.x, bezierCurve.c2.x);
    bezierCurve.c2.x = math.min(bezierCurve.p2.x, bezierCurve.c2.x);
    bezierCurve.c1.x = math.min(bezierCurve.c2.x, bezierCurve.c1.x);

    bezierCurve.updateControlPointParams();
  }

  /// Mirrors `CalcControlPointShift` (outer slurs w.r.t. inner curves).
  ControlPointAdjustment calcControlPointShift(BezierCurve bezierCurve,
      List<FloatingCurvePositioner> innerCurves, double symmetry, int margin) {
    final ControlPointAdjustment adjustment = ControlPointAdjustment();
    if (bezierCurve.p1.x >= bezierCurve.p2.x) return adjustment;

    final int dist = bezierCurve.p2.x - bezierCurve.p1.x;
    final bool isBelow = (currentCurve!.getDir() == CurvatureCurvedir.above);
    final int sign = isBelow ? 1 : -1;
    final List<Point> points = [
      bezierCurve.p1,
      bezierCurve.c1,
      bezierCurve.c2,
      bezierCurve.p2,
    ];

    final List<ControlPointConstraint> constraints = [];
    for (final FloatingCurvePositioner innerCurve in innerCurves) {
      final List<Point> innerPoints = innerCurve.getPoints();

      // Create five constraints for each inner slur
      for (int step = 0; step <= 4; ++step) {
        final Point innerPoint =
            BoundingBox.calcPointAtBezier(innerPoints, 0.25 * step);
        if ((bezierCurve.p1.x <= innerPoint.x) &&
            (innerPoint.x <= bezierCurve.p2.x)) {
          final int y = BoundingBox.calcBezierAtPosition(points, innerPoint.x);
          final int intersection = (innerPoint.y - y) * sign + margin;
          final double distanceRatio =
              (innerPoint.x - bezierCurve.p1.x) / dist;

          // Ignore obstacles close to the endpoints, because this would
          // result in very large shifts
          if (((0.5 - distanceRatio).abs() < 0.45) && (intersection > 0)) {
            final double t =
                BoundingBox.calcBezierParamAtPosition(points, innerPoint.x);
            constraints.add(ControlPointConstraint(
                3.0 * math.pow(1.0 - t, 2.0) * t,
                3.0 * (1.0 - t) * math.pow(t, 2.0),
                intersection.toDouble()));
          }
        }
      }
    }

    // Solve the constraints and calculate the adjustment
    final (int leftShift, int rightShift) =
        solveControlPointConstraints(constraints, symmetry);
    adjustment.leftShift = leftShift;
    adjustment.rightShift = rightShift;

    return adjustment;
  }

  /// Mirrors `CalcEndPointShift(BezierCurve,
  /// ArrayOfFloatingCurvePositioners, …)` (outer slurs w.r.t. inner curves).
  (int, int) calcEndPointShiftWithInner(BezierCurve bezierCurve,
      List<FloatingCurvePositioner> innerCurves, double flexibility, int margin) {
    if (bezierCurve.p1.x >= bezierCurve.p2.x) return (0, 0);

    final FloatingCurvePositioner curve = currentCurve!;

    final EndPointShifts shifts = EndPointShifts();

    final int dist = bezierCurve.p2.x - bezierCurve.p1.x;
    final bool isBelow = (curve.getDir() == CurvatureCurvedir.above);
    final int sign = isBelow ? 1 : -1;
    final List<Point> points = [
      bezierCurve.p1,
      bezierCurve.c1,
      bezierCurve.c2,
      bezierCurve.p2,
    ];

    for (final FloatingCurvePositioner innerCurve in innerCurves) {
      final List<Point> innerPoints = innerCurve.getPoints();

      // Adjustment for start point of inner slur
      final int xInnerStart = innerPoints[0].x;
      if ((bezierCurve.p1.x <= xInnerStart) &&
          (xInnerStart <= bezierCurve.p2.x)) {
        final int yStart =
            BoundingBox.calcBezierAtPosition(points, xInnerStart);
        final int intersectionStart =
            (innerPoints[0].y - yStart) * sign + (1.5 * margin).toInt();
        if (intersectionStart > 0) {
          final double distanceRatioStart =
              (xInnerStart - bezierCurve.p1.x) / dist;
          shiftEndPoints(shifts, flexibility, curve, distanceRatioStart,
              intersectionStart, isBelow);
        }
      }

      // Adjustment for midpoint of inner slur
      final Point innerMidPoint =
          BoundingBox.calcPointAtBezier(innerPoints, 0.5);
      if ((bezierCurve.p1.x <= innerMidPoint.x) &&
          (innerMidPoint.x <= bezierCurve.p2.x)) {
        final int yMid =
            BoundingBox.calcBezierAtPosition(points, innerMidPoint.x);
        final int intersectionMid =
            (innerMidPoint.y - yMid) * sign + (1.5 * margin).toInt();
        if (intersectionMid > 0) {
          final double distanceRatioMid =
              (innerMidPoint.x - bezierCurve.p1.x) / dist;
          shiftEndPoints(shifts, flexibility, curve, distanceRatioMid,
              intersectionMid, isBelow);
        }
      }

      // Adjustment for end point of inner slur
      final int xInnerEnd = innerPoints[3].x;
      if ((bezierCurve.p1.x <= xInnerEnd) &&
          (xInnerEnd <= bezierCurve.p2.x)) {
        final int yEnd = BoundingBox.calcBezierAtPosition(points, xInnerEnd);
        final int intersectionEnd =
            (innerPoints[3].y - yEnd) * sign + (1.5 * margin).toInt();
        if (intersectionEnd > 0) {
          final double distanceRatioEnd =
              (xInnerEnd - bezierCurve.p1.x) / dist;
          shiftEndPoints(shifts, flexibility, curve, distanceRatioEnd,
              intersectionEnd, isBelow);
        }
      }
    }

    return (shifts.left, shifts.right);
  }

  /// Mirrors `GetMinControlPointAngle`.
  double getMinControlPointAngle(BezierCurve bezierCurve, double angle, int unit) {
    angle = angle.abs();
    final double distance =
        (bezierCurve.p2.x - bezierCurve.p1.x).toDouble() / unit;

    // Increase min angle for short and angled slurs
    double angleIncrement = math.min(angle / 4.0, 15.0); // [0.0, 15.0]
    double factor = 1.0 - (distance - 8.0) / 8.0;
    factor = math.min(factor, 1.0);
    factor = math.max(factor, 0.0); // [0.0, 1.0]

    // not if control points are horizontally in a degenerated position
    if ((bezierCurve.c1.x < bezierCurve.p1.x) ||
        (2.0 * bezierCurve.c1.x > bezierCurve.p1.x + bezierCurve.p2.x)) {
      angleIncrement = 0.0;
    }
    if ((bezierCurve.c2.x > bezierCurve.p2.x) ||
        (2.0 * bezierCurve.c2.x < bezierCurve.p1.x + bezierCurve.p2.x)) {
      angleIncrement = 0.0;
    }

    return 30.0 + angleIncrement * factor;
  }

  /// Mirrors `ShiftEndPoints(int &shiftLeft, int &shiftRight, …)`.
  void shiftEndPoints(EndPointShifts shifts, double flexibility,
      FloatingCurvePositioner curve, double ratio, int intersection,
      bool isBelow) {
    final Object? slur = currentSlur;

    // Filter collisions near the endpoints
    // Collisions with ratio beyond the partialShiftRadius do not contribute
    // to shifts. They are compensated later by shifting the control points.
    double fullShiftRadius = 0.0;
    double partialShiftRadius = 0.0;
    (fullShiftRadius, partialShiftRadius) =
        calcShiftRadii(flexibility, curve.getSpanningType(), true);

    if ((ratio < partialShiftRadius) &&
        ((slur?.hasEndpointAboveStart ?? false) == isBelow)) {
      int contribution = intersection;
      if (ratio > fullShiftRadius) {
        // Collisions here only partially contribute to shifts.
        // We multiply with a function that interpolates between 1 and 0.
        contribution = (intersection *
                calcQuadraticInterpolation(
                    partialShiftRadius, fullShiftRadius, ratio))
            .round();
      }
      shifts.left = math.max(shifts.left, contribution);
    }

    (fullShiftRadius, partialShiftRadius) =
        calcShiftRadii(flexibility, curve.getSpanningType(), false);

    if ((ratio > 1.0 - partialShiftRadius) &&
        ((slur?.hasEndpointAboveEnd ?? false) == isBelow)) {
      int contribution = intersection;
      if (ratio < 1.0 - fullShiftRadius) {
        contribution = (intersection *
                calcQuadraticInterpolation(
                    1.0 - partialShiftRadius, 1.0 - fullShiftRadius, ratio))
            .round();
      }
      shifts.right = math.max(shifts.right, contribution);
    }
  }

  /// Mirrors `CalcShiftRadii`.
  (double, double) calcShiftRadii(double flexibility, int spanningType, bool forShiftLeft) {
    // Use full flexibility for broken slur endpoints
    if (forShiftLeft) {
      if ((spanningType == spanningMiddle) || (spanningType == spanningEnd)) {
        flexibility = 1.0;
      }
    } else {
      if ((spanningType == spanningStart) || (spanningType == spanningMiddle)) {
        flexibility = 1.0;
      }
    }

    final double fullShiftRadius = 0.05 + flexibility * 0.15;
    final double partialShiftRadius = fullShiftRadius * 3.0;

    return (fullShiftRadius, partialShiftRadius);
  }

  /// Mirrors `CalcQuadraticInterpolation`.
  double calcQuadraticInterpolation(double zeroAt, double oneAt, double arg) {
    assert(zeroAt != oneAt);
    final double a = 1.0 / (oneAt - zeroAt);
    final double b = zeroAt / (zeroAt - oneAt);
    return math.pow(a * arg + b, 2.0).toDouble();
  }

  /// Mirrors `RotateSlope`.
  double rotateSlope(double slope, double degrees, double doublingBound, bool upwards) {
    assert(degrees >= 0.0);
    assert(doublingBound >= 0.0);

    if (upwards && (slope >= doublingBound)) return slope * 2.0;
    if (!upwards && (slope <= -doublingBound)) return slope * 2.0;
    final int sign = upwards ? 1 : -1;
    return math.tan(math.atan(slope) + sign * math.pi * degrees / 180.0);
  }

  /// The original layer n of a bounding box when it is a layer element
  /// (mirrors LayerElement::GetOriginalLayerN reduced to the alignment
  /// layer).
  static int _originalLayerN(BoundingBox bbox) =>
      bbox is LayerElement ? bbox.getAlignmentLayerN().abs() : -1;

  static int _boundaryOriginalLayerN(Object? boundary) =>
      boundary is LayerElement ? boundary.getAlignmentLayerN().abs() : -1;
}
