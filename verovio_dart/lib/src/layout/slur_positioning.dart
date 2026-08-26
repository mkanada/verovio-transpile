/// Port of the slur / tie curve geometry from `slur.cpp` (CalcInitialCurve,
/// CalcSpannedElements, InitBezierControlSides, HasInnerSlur and the
/// endpoint helpers), used by the headless extents pass and by
/// AdjustSlursFunctor.
///
/// In the C++ these are members of Slur, with Tie inheriting them; here they
/// are provided as an extension on ControlElement so that Slur, Phrase, Tie
/// and Lv share the implementation (the boundary elements are accessed
/// through TimeSpanningInterface).
///
/// Deviations (all documented inline as "Approximation:" where applied):
/// - `Slur::CalcEndPoints` is reduced to the main stem-direction cases: the
///   grace-note, portato, bulge-adjacent, s-shaped secondary endpoints and
///   the near-end collision repositioning arrive with their phases. The
///   broken-slur (SPANNING_START / END / MIDDLE) staff positions are ported.
/// - `CollectSpannedElements` does not implement the outside-layers pitch
///   filtering nor the tie positioner collection; all layer elements with a
///   bounding box in the x range on the boundary staves are collected.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset, MeiDuration;
import 'package:verovio_dart/src/core/smufl.dart' show smuflE0A4NoteheadBlack;
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show CurveSpannedElement, FloatingCurvePositioner, NearEndCollision;
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show CurvatureCurvedir, Stemdirection;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Measure, Note, Staff;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show StemmedDrawingInterface;
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart'
    show DurationInterface;
import 'package:verovio_dart/src/model/interfaces/time_interface.dart'
    show TimeSpanningInterface;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show Chord;
import 'package:verovio_dart/src/model/object.dart';

/// The slur / tie geometry helpers.
extension SlurPositioning on Object {
  // -------------------------------------------------------------------------
  // Boundary accessors
  // -------------------------------------------------------------------------

  /// The start boundary element (mirrors TimeSpanningInterface::GetStart).
  Object? get slurStart => (this as TimeSpanningInterface).getStart();

  /// The end boundary element (mirrors GetEnd).
  Object? get slurEnd => (this as TimeSpanningInterface).getEnd();

  /// Mirrors `Slur::GetDrawingCurveDir`.
  CurvatureCurvedir calcDrawingCurveDirFor(int spanningType) {
    final dynamic slur = this as dynamic;
    switch (slur.drawingCurveDir) {
      case SlurCurveDirection.above:
        return CurvatureCurvedir.above;
      case SlurCurveDirection.below:
        return CurvatureCurvedir.below;
      case SlurCurveDirection.aboveBelow:
        switch (spanningType) {
          case spanningStartEnd:
            return CurvatureCurvedir.mixed;
          case spanningStart:
            return CurvatureCurvedir.above;
          default:
            return CurvatureCurvedir.below;
        }
      case SlurCurveDirection.belowAbove:
        switch (spanningType) {
          case spanningStartEnd:
            return CurvatureCurvedir.mixed;
          case spanningStart:
            return CurvatureCurvedir.below;
          default:
            return CurvatureCurvedir.above;
        }
      default:
        return CurvatureCurvedir.none;
    }
  }

  /// Mirrors `HasMixedCurveDir`.
  bool get hasMixedCurveDir {
    final dynamic dir = (this as dynamic).drawingCurveDir;
    return dir == SlurCurveDirection.aboveBelow ||
        dir == SlurCurveDirection.belowAbove;
  }

  /// Mirrors `HasEndpointAboveStart`.
  bool get hasEndpointAboveStart {
    final dynamic dir = (this as dynamic).drawingCurveDir;
    return dir == SlurCurveDirection.above ||
        dir == SlurCurveDirection.aboveBelow;
  }

  /// Mirrors `HasEndpointBelowStart`.
  bool get hasEndpointBelowStart {
    final dynamic dir = (this as dynamic).drawingCurveDir;
    return dir == SlurCurveDirection.below ||
        dir == SlurCurveDirection.belowAbove;
  }

  /// Mirrors `HasEndpointAboveEnd`.
  bool get hasEndpointAboveEnd {
    final dynamic dir = (this as dynamic).drawingCurveDir;
    return dir == SlurCurveDirection.above ||
        dir == SlurCurveDirection.belowAbove;
  }

  /// Mirrors `HasEndpointBelowEnd`.
  bool get hasEndpointBelowEnd {
    final dynamic dir = (this as dynamic).drawingCurveDir;
    return dir == SlurCurveDirection.below ||
        dir == SlurCurveDirection.aboveBelow;
  }

  /// Mirrors `TimeSpanningInterface::IsOrdered(start, end)`: true when
  /// [start] precedes [end] in the document flow.
  bool isSlurOrdered(Object? start, Object? end) {
    if (start == null || end == null) return true;
    final Measure? startMeasure =
        start.getFirstAncestor(ClassId.measure) as Measure?;
    final Measure? endMeasure =
        end.getFirstAncestor(ClassId.measure) as Measure?;

    if (identical(startMeasure, endMeasure)) {
      final Alignment? startAlignment =
          start is LayerElement ? start.getAlignment() : null;
      final Alignment? endAlignment =
          end is LayerElement ? end.getAlignment() : null;
      if (startAlignment == null || endAlignment == null) return true;
      return Object.isPreOrdered(startAlignment, endAlignment);
    } else {
      return (startMeasure?.index ?? 0) < (endMeasure?.index ?? 0);
    }
  }

  /// Mirrors `Slur::HasInnerSlur`: [innerSlur] is fully inside this slur.
  bool hasInnerSlurFor(Object innerSlurObject) {
    final dynamic innerSlur = innerSlurObject;
    final dynamic self = this;

    if (self.drawingCurveDir != innerSlur.drawingCurveDir) return false;
    if (hasMixedCurveDir) return false;

    final Object? start = slurStart;
    final Object? end = slurEnd;
    if (start is! LayerElement || end is! LayerElement) return false;
    final Object? innerStart = innerSlur.getStart();
    final Object? innerEnd = innerSlur.getEnd();
    if (innerStart is! LayerElement || innerEnd is! LayerElement) return false;

    // Check the layer
    final Set<int> admissibleLayers = {
      start.getAlignmentLayerN().abs(),
      end.getAlignmentLayerN().abs(),
    };
    final Set<int> innerLayers = {
      innerStart.getAlignmentLayerN().abs(),
      innerEnd.getAlignmentLayerN().abs(),
    };
    if (!admissibleLayers.containsAll(innerLayers)) return false;

    // Check the alignment
    if (_slurIsBefore(innerStart, start) || _slurIsBefore(end, innerEnd)) return false;
    return _slurIsBefore(start, innerStart) || _slurIsBefore(innerEnd, end);
  }


  // -------------------------------------------------------------------------
  // Initial curve
  // -------------------------------------------------------------------------

  /// Mirrors `Slur::InitBezierControlSides`.
  void initBezierControlSidesFor(BezierCurve bezier, CurvatureCurvedir curveDir) {
    switch (curveDir) {
      case CurvatureCurvedir.above:
        bezier.setControlSides(true, true);
        break;
      case CurvatureCurvedir.below:
        bezier.setControlSides(false, false);
        break;
      case CurvatureCurvedir.mixed:
        bezier.setControlSides(hasEndpointAboveStart, hasEndpointAboveEnd);
        break;
      default:
        break;
    }
  }

  /// Reduced port of `Slur::CalcInitialCurve`; stores the initial bezier in
  /// [curve]. See the library deviations for the reduced CalcEndPoints.
  void calcInitialCurveFor(
      Doc doc, FloatingCurvePositioner curve, NearEndCollision? nearEndCollision) {
    final Object? start = slurStart;
    final Object? end = slurEnd;
    if (start is! LayerElement || end is! LayerElement) return;

    final Staff? staff = curve.getObjectY() is Staff
        ? curve.getObjectY() as Staff
        : null;
    if (staff == null) return;

    final int spanningType = curve.getSpanningType();
    final CurvatureCurvedir curveDir = calcDrawingCurveDirFor(spanningType);

    // Calculate endpoints
    assert(curve.hasCachedX12());
    final (int cachedX1, int cachedX2) = curve.getCachedX12();
    final (Point endPoint1, Point endPoint2) = calcEndPointsReduced(
        doc, staff, nearEndCollision, cachedX1, cachedX2, curveDir, spanningType);

    // For now we pick C1 = P1 and C2 = P2
    final BezierCurve bezier =
        BezierCurve.of(endPoint1, endPoint1, endPoint2, endPoint2);
    initBezierControlSidesFor(bezier, curveDir);

    // Angle adjustment
    final bool dontAdjustAngle = curve.isCrossStaff() || start.isGraceNote();
    double nonAdjustedAngle = 0;
    if (bezier.p2 != bezier.p1) {
      nonAdjustedAngle =
          math.atan2(bezier.p2.y - bezier.p1.y, bezier.p2.x - bezier.p1.x);
    }
    final double slurAngle = dontAdjustAngle
        ? nonAdjustedAngle
        : getAdjustedSlurAngle(doc, bezier.p1, bezier.p2, curveDir);
    if (curveDir != CurvatureCurvedir.mixed) {
      bezier.p2 =
          BoundingBox.calcPositionAfterRotation(bezier.p2, -slurAngle, bezier.p1);
    }

    // Calculate control points
    bezier.calcInitialControlPointParamsWithDoc(
      doc.getDrawingUnit,
      (int staffSize) =>
          (doc.getOptions().unit.value * 7 * staffSize / 100).toInt(),
      doc.getOptions().slurCurveFactor.value,
      slurAngle,
      staff.drawingStaffSize,
    );
    bezier.updateControlPoints();
    if (curveDir != CurvatureCurvedir.mixed) {
      bezier.rotate(slurAngle, bezier.p1);
    }

    final List<Point> points = [bezier.p1, bezier.c1, bezier.c2, bezier.p2];

    // Calculate thickness
    final int thickness = (doc.getDrawingUnit(staff.drawingStaffSize) *
            doc.getOptions().slurMidpointThickness.value)
        .toInt();

    // Store everything in floating curve positioner
    curve.updateCurveParams(points, thickness, curveDir);
  }

  /// Mirrors `Slur::GetAdjustedSlurAngle` ([p1] / [p2] are adjusted in
  /// place).
  double getAdjustedSlurAngle(
      Doc doc, Point p1, Point p2, CurvatureCurvedir curveDir) {
    double slurAngle = (p1 == p2)
        ? 0
        : math.atan2(p2.y - p1.y.toDouble(), p2.x - p1.x.toDouble());
    final double maxAngle =
        doc.getOptions().slurMaxSlope.value * math.pi / 180.0;

    // the slope of the slur is high and needs to be corrected
    if (slurAngle.abs() > maxAngle) {
      final int side = ((p2.x - p1.x) * math.tan(maxAngle)).toInt();
      if (p2.y > p1.y) {
        if (curveDir == CurvatureCurvedir.above) {
          p1.y = p2.y - side;
        } else {
          p2.y = p1.y + side;
        }
        slurAngle = maxAngle;
      } else {
        if (curveDir == CurvatureCurvedir.above) {
          p2.y = p1.y - side;
        } else {
          p1.y = p2.y + side;
        }
        slurAngle = -maxAngle;
      }
    }

    return slurAngle;
  }

  /// Reduced port of `Slur::CalcEndPoints`. Returns `(p1, p2)`.
  (Point, Point) calcEndPointsReduced(
      Doc doc,
      Staff staff,
      NearEndCollision? nearEndCollision,
      int x1,
      int x2,
      CurvatureCurvedir drawingCurveDir,
      int spanningType) {
    final Object? start = slurStart;
    final Object? end = slurEnd;
    if (start is! LayerElement || end is! LayerElement) {
      return (Point(x1, staff.getDrawingY()), Point(x2, staff.getDrawingY()));
    }

    final Stemdirection startStemDir = start.getDrawingStemDirHeadless();
    final int startStemLen = _slurStemLenOf(start);
    final Stemdirection endStemDir = end.getDrawingStemDirHeadless();
    final int endStemLen = _slurStemLenOf(end);

    final bool isSshaped = hasMixedCurveDir;

    int y1 = staff.getDrawingY();
    int y2 = y1;

    final int staffSize = staff.drawingStaffSize;
    final int unit = doc.getDrawingUnit(staffSize);
    final bool isShortSlur = x2 - x1 < doc.getDrawingDoubleUnit(staffSize);

    Chord? startChord;
    Note? startNote;
    if (start.isClass(ClassId.note)) {
      startNote = start as Note;
      startChord = startNote.isChordTone() as Chord?;
    } else if (start.isClass(ClassId.chord)) {
      startChord = start as Chord;
    }
    Chord? endChord;
    Note? endNote;
    if (end.isClass(ClassId.note)) {
      endNote = end as Note;
      endChord = endNote.isChordTone() as Chord?;
    } else if (end.isClass(ClassId.chord)) {
      endChord = end as Chord;
    }

    int yChordMax = 0;
    int yChordMin = 0;
    if (((spanningType == spanningStartEnd) || (spanningType == spanningStart)) &&
        !start.isClass(ClassId.timestampAttr)) {
      final int startRadius = _slurRadiusOf(doc, start, staffSize);
      if (startChord != null) {
        final (int chordMax, int chordMin) = startChord.getYExtremesAbs(doc, staffSize);
        yChordMax = chordMax;
        yChordMin = chordMin;
      }
      // slur is up
      if (hasEndpointAboveStart) {
        // P(^): stem down or no stem
        if ((startStemDir == Stemdirection.down) || (startStemLen == 0)) {
          y1 = drawingTopOf(doc, start, staffSize);
        }
        // d(^)d short slur
        else if (isShortSlur) {
          y1 = drawingTopOf(doc, start, staffSize);
        }
        // s-shaped slurs
        else if (isSshaped) {
          y1 = drawingTopOf(doc, start, staffSize);
          x1 += startRadius - doc.getDrawingStemWidth(staffSize);
        }
        // d(^): primary endpoint on the side
        else {
          // Approximation: the near-end collision repositioning (secondary
          // endpoint on top) arrives with its phase.
          x1 += unit * 2;
          y1 = (startChord != null)
              ? yChordMax + unit * 3
              : start.getDrawingY() + unit * 3;
        }
      }
      // slur is down
      else {
        if ((startStemDir == Stemdirection.up) || (startStemLen == 0)) {
          y1 = drawingBottomOf(doc, start, staffSize);
        } else if (isShortSlur) {
          y1 = drawingBottomOf(doc, start, staffSize);
        } else if (isSshaped) {
          y1 = drawingBottomOf(doc, start, staffSize);
          x1 -= startRadius - doc.getDrawingStemWidth(staffSize);
        } else {
          if (startChord != null) {
            y1 = yChordMin - unit * 3;
          } else {
            y1 = start.getDrawingY() - unit * 3;
          }
        }
      }
    }
    if (((spanningType == spanningStartEnd) || (spanningType == spanningEnd)) &&
        !end.isClass(ClassId.timestampAttr)) {
      final int endRadius = _slurRadiusOf(doc, end, staffSize);
      if (endChord != null) {
        final (int chordMax, int chordMin) = endChord.getYExtremesAbs(doc, staffSize);
        yChordMax = chordMax;
        yChordMin = chordMin;
      }
      // slur is up
      if (hasEndpointAboveEnd) {
        // (^)P
        if ((endStemDir == Stemdirection.down) || (endStemLen == 0)) {
          y2 = drawingTopOf(doc, end, staffSize);
        } else if (isShortSlur) {
          y2 = drawingTopOf(doc, end, staffSize);
        } else if (isSshaped) {
          y2 = drawingTopOf(doc, end, staffSize);
          x2 += endRadius - doc.getDrawingStemWidth(staffSize);
        } else {
          // (^)d: primary endpoint on the side
          if (endChord != null) {
            y2 = yChordMax + unit * 3;
          } else {
            y2 = end.getDrawingY() + unit * 3;
          }
        }
      } else {
        if ((endStemDir == Stemdirection.up) || (endStemLen == 0)) {
          y2 = drawingBottomOf(doc, end, staffSize);
        } else if (isShortSlur) {
          y2 = drawingBottomOf(doc, end, staffSize);
        } else if (isSshaped) {
          y2 = drawingBottomOf(doc, end, staffSize);
          x2 -= endRadius - doc.getDrawingStemWidth(staffSize);
        } else {
          // (_)P: primary endpoint on the side, moved left
          x2 -= unit * 2;
          if (endChord != null) {
            y2 = yChordMin - unit * 3;
          } else {
            y2 = end.getDrawingY() - unit * 3;
          }
        }
      }
    }

    // Positions not attached to a note (broken slurs)
    final (int startLoc, int endLoc) = _slurStartEndLocs(
        hasEndpointAboveStart, hasEndpointAboveEnd, startNote, startChord, endNote, endChord);
    final int musicStaffSize = doc.getDrawingStaffSize(staffSize);
    final int staffTop = staff.getDrawingY();
    final int staffBottom = staffTop - musicStaffSize;

    final int pitchDiff =
        _slurPitchDifference(hasEndpointAboveStart, hasEndpointAboveEnd, staff, startLoc, endLoc);
    if (spanningType == spanningStart) {
      if (hasEndpointAboveStart) {
        y2 = staffTop + unit;
        if (considerMelodicDirection(start, end)) {
          y2 = math.max(staffTop, y1) + (pitchDiff * unit ~/ 2).toInt();
          y2 = math.max(staffTop, y2);
        }
      } else {
        y2 = staffBottom - unit;
        if (considerMelodicDirection(start, end)) {
          y2 = math.min(staffBottom, y1) + (pitchDiff * unit ~/ 2).toInt();
          y2 = math.min(staffBottom, y2);
        }
      }
      // Make sure that broken slurs do not look like ties
      if (((y1 - y2).abs() < 2 * unit) && ((x1 - x2).abs() < 2 * musicStaffSize)) {
        final int sign = hasEndpointAboveStart ? 1 : -1;
        y2 = y1 + 2 * sign * unit;
      }
      // At the end of a system, the slur finishes just short of the last barline
      x2 -= (doc.getDrawingBarLineWidth(staffSize) + unit) ~/ 2;
    }
    if (end.isClass(ClassId.timestampAttr)) {
      if (hasEndpointAboveStart) {
        y2 = math.max(staffTop, y1);
      } else {
        y2 = math.min(staffBottom, y1);
      }
    }
    if (spanningType == spanningEnd) {
      if (isSshaped != hasEndpointAboveEnd) {
        y1 = staffTop + unit;
        if (considerMelodicDirection(start, end)) {
          y1 = math.max(staffTop, y2) - (pitchDiff * unit ~/ 2).toInt();
          y1 = math.max(staffTop, y1);
        }
      } else {
        y1 = staffBottom - unit;
        if (considerMelodicDirection(start, end)) {
          y1 = math.min(staffBottom, y2) - (pitchDiff * unit ~/ 2).toInt();
          y1 = math.min(staffBottom, y1);
        }
      }
      // Make sure that broken slurs do not look like ties
      if (((y1 - y2).abs() < 2 * unit) && ((x1 - x2).abs() < 2 * musicStaffSize)) {
        final int sign = hasEndpointAboveEnd ? 1 : -1;
        y1 = y2 + 2 * sign * unit;
      }
    }
    if (start.isClass(ClassId.timestampAttr)) {
      if (hasEndpointAboveEnd) {
        y1 = math.max(staffTop, y2);
      } else {
        y1 = math.min(staffBottom, y2);
      }
    } else if (spanningType == spanningMiddle) {
      // slur across an entire system; use the staff position
      y1 = (drawingCurveDir == CurvatureCurvedir.above) ? staffTop + unit : staffBottom - unit;
      y2 = y1;
    }

    // Final vertical adjustment based on drawing curve direction
    int sign = (drawingCurveDir == CurvatureCurvedir.above) ? 1 : -1;
    if (drawingCurveDir == CurvatureCurvedir.mixed) {
      sign = hasEndpointAboveStart ? 1 : -1;
    }
    y1 += (1.25 * sign * unit).toInt();
    if (drawingCurveDir == CurvatureCurvedir.mixed) {
      sign = hasEndpointAboveEnd ? 1 : -1;
    }
    y2 += (1.25 * sign * unit).toInt();

    return (Point(x1, y1), Point(x2, y2));
  }

  /// Mirrors `Slur::ConsiderMelodicDirection` reduced to the measure index
  /// check (the IsLastInSystem check arrives with the system helpers).
  ///
  /// Approximation: returns false (no melodic direction adjustment); the C++
  /// only applies it across system breaks which cannot yet be detected
  /// reliably headlessly.
  bool considerMelodicDirection(Object? start, Object? end) => false;

  // -------------------------------------------------------------------------
  // Spanned elements
  // -------------------------------------------------------------------------

  /// Reduced port of `Slur::CalcSpannedElements`; collects the layer
  /// elements with a bounding box overlapping the curve x range.
  void calcSpannedElementsFor(Doc doc, FloatingCurvePositioner curve) {
    final Staff? staff =
        curve.getObjectY() is Staff ? curve.getObjectY() as Staff : null;
    if (staff == null) return;

    final List<Point> points = curve.getPoints();
    final int x1 = points[0].x;
    final int x2 = points[3].x;

    final Object? start = slurStart;
    final Object? end = slurEnd;
    if (start is! LayerElement || end is! LayerElement) return;

    final Object? container = (this as TimeSpanningInterface).isSpanningMeasures()
        ? start.getFirstAncestor(ClassId.system)
        : start.getFirstAncestor(ClassId.measure);
    if (container == null) return;

    const List<ClassId> spannedClasses = [
      ClassId.accid,
      ClassId.artic,
      ClassId.chord,
      ClassId.clef,
      ClassId.dot,
      ClassId.dots,
      ClassId.flag,
      ClassId.note,
      ClassId.stem,
      ClassId.tupletBracket,
      ClassId.tupletNum,
    ];

    // Deviation: the outside-layer pitch filtering and the tie positioner
    // collection are not ported; all matching elements on the boundary staves
    // are considered.

    final Staff? startStaff = resolveCrossStaffOf(start);
    final Staff? endStaff = resolveCrossStaffOf(end);
    if (startStaff != null && endStaff != null && startStaff.n != endStaff.n) {
      curve.setCrossStaff(endStaff);
    }

    curve.clearSpannedElements();

    for (final Object object
        in container.findAllDescendantsByClassIdPredicate(
            (ClassId id) => spannedClasses.contains(id))) {
      final LayerElement element = object as LayerElement;
      if (!element.hasSelfBB()) continue;

      final Staff? elementStaff = resolveCrossStaffOf(element);
      final int elementStaffN = elementStaff?.n ?? meiUnset;
      if ((elementStaffN != staff.n) &&
          (elementStaffN != startStaff?.n) &&
          (elementStaffN != endStaff?.n)) {
        continue;
      }

      final int xLeft = element.getSelfLeft();
      final int xRight = element.getSelfRight();
      final bool isOverlapping =
          ((xLeft > x1) && (xLeft < x2)) || ((xRight > x1) && (xRight < x2));

      if (isOverlapping || element.isClass(ClassId.tupletBracket)) {
        final CurveSpannedElement spannedElement = CurveSpannedElement();
        spannedElement.boundingBox = element;
        spannedElement.isBelow = isElementBelowFor(element, startStaff, endStaff);
        curve.addSpannedElement(spannedElement);
      }

      if (!curve.isCrossStaff()) {
        final dynamic cross = element.crossStaff;
        if (cross != null) curve.setCrossStaff(cross);
      }
    }
  }

  /// Mirrors `Slur::IsElementBelow(LayerElement*, …)` reduced to the plain
  /// direction cases plus the mixed-direction staff comparison.
  bool isElementBelowFor(
      LayerElement element, Staff? startStaff, Staff? endStaff) {
    final dynamic dir = (this as dynamic).drawingCurveDir;
    if (dir == SlurCurveDirection.above) return true;
    if (dir == SlurCurveDirection.below) return false;
    if (dir == SlurCurveDirection.aboveBelow) {
      return resolveCrossStaffOf(element)?.n == startStaff?.n;
    }
    if (dir == SlurCurveDirection.belowAbove) {
      return resolveCrossStaffOf(element)?.n == endStaff?.n;
    }
    return false;
  }

  /// Resolve the ancestor staff taking the cross-staff into account (mirrors
  /// `GetAncestorStaff(RESOLVE_CROSS_STAFF)`).
  static Staff? resolveCrossStaffOf(Object element) {
    final dynamic cross = (element as dynamic).crossStaff;
    if (cross is Staff) return cross;
    final Object? staff = element.getFirstAncestor(ClassId.staff);
    return staff is Staff ? staff : null;
  }
}

// ---------------------------------------------------------------------------
// Drawing top / bottom helpers (reduced ports of LayerElement::GetDrawingTop /
// GetDrawingBottom)
// ---------------------------------------------------------------------------

/// Mirrors `LayerElement::GetDrawingTop(doc, staffSize)` without artic.
int drawingTopOf(Doc doc, LayerElement element, int staffSize) {
  Note? note;
  if (element.isClass(ClassId.chord)) {
    note = (element as Chord).getTopNote();
  } else if (element.isClass(ClassId.note)) {
    note = element as Note;
  }

  if (note != null) {
    final DurationInterface duration = element as DurationInterface;
    if (duration.getActualDur().value < MeiDuration.dur2.value) {
      return note.getDrawingY() + doc.getDrawingUnit(staffSize);
    }
    final Stemdirection stemDir = element.getDrawingStemDirHeadless();
    if (stemDir == Stemdirection.up) {
      return stemEndYOf(element);
    } else {
      // this does not take into account the glyph's actual size
      return note.getDrawingY() + doc.getDrawingUnit(staffSize);
    }
  }
  return element.getDrawingY();
}

/// Mirrors `LayerElement::GetDrawingBottom(doc, staffSize)` without artic.
int drawingBottomOf(Doc doc, LayerElement element, int staffSize) {
  Note? note;
  if (element.isClass(ClassId.chord)) {
    note = (element as Chord).getBottomNote();
  } else if (element.isClass(ClassId.note)) {
    note = element as Note;
  }

  if (note != null) {
    final DurationInterface duration = element as DurationInterface;
    if (duration.getActualDur().value < MeiDuration.dur2.value) {
      return note.getDrawingY() - doc.getDrawingUnit(staffSize);
    }
    final Stemdirection stemDir = element.getDrawingStemDirHeadless();
    if (stemDir == Stemdirection.down) {
      return stemEndYOf(element);
    } else {
      return note.getDrawingY() - doc.getDrawingUnit(staffSize);
    }
  }
  return element.getDrawingY();
}

/// The y position of the stem end (mirrors
/// StemmedDrawingInterface::GetDrawingStemEnd).
int stemEndYOf(LayerElement element) {
  final dynamic stem = (element as dynamic).getDrawingStem();
  if (stem == null) return element.getDrawingY();
  return stem.getDrawingY() - stem.getDrawingStemLen();
}

/// The chord y extremes in absolute coordinates (headless variant of
/// `Chord::GetYExtremes` working through the note locations).
extension ChordYExtremes on Chord {
  (int, int) getYExtremesAbs(Doc doc, int staffSize) {
    final List<Object> childList = getList();
    if (childList.isEmpty) return (getDrawingY(), getDrawingY());
    final Note bottomNote = childList.first as Note;
    final Note topNote = childList.last as Note;
    final int unit = doc.getDrawingDoubleUnit(staffSize);
    final int span = (_locValue(topNote) - _locValue(bottomNote)) * unit ~/ 2;
    return (topNote.getDrawingY(), topNote.getDrawingY() - span);
  }

  static int _locValue(Note note) {
    return (note as dynamic).drawingLoc as int;
  }
}

// ---------------------------------------------------------------------------
// Top level helpers (private)
// ---------------------------------------------------------------------------

/// Strict ordering between two layer elements based on their alignment
/// positions (mirrors Object::IsOrdered semantics of IsPreOrdered on the
/// alignments).
bool _slurIsBefore(LayerElement left, LayerElement right) {
  final Alignment? leftAlignment = left.getAlignment();
  final Alignment? rightAlignment = right.getAlignment();
  if (leftAlignment == null || rightAlignment == null) return false;
  if (!Object.isPreOrdered(leftAlignment, rightAlignment)) return false;
  return !identical(leftAlignment, rightAlignment);
}

/// Mirrors `Slur::GetStartEndLocs`.
(int, int) _slurStartEndLocs(bool aboveStart, bool aboveEnd, Note? startNote,
    Chord? startChord, Note? endNote, Chord? endChord) {
  int startLoc = startNote != null ? _slurLocOf(startNote) : 0;
  if (startChord != null) {
    if (aboveStart) {
      startLoc = _slurLocOf(startChord.getTopNote()!);
    } else {
      startLoc = _slurLocOf(startChord.getBottomNote()!);
    }
  }

  int endLoc = endNote != null ? _slurLocOf(endNote) : 0;
  if (endChord != null) {
    if (aboveEnd) {
      endLoc = _slurLocOf(endChord.getTopNote()!);
    } else {
      endLoc = _slurLocOf(endChord.getBottomNote()!);
    }
  }

  return (startLoc, endLoc);
}

/// Mirrors `Slur::CalcPitchDifference`.
int _slurPitchDifference(bool aboveStart, bool aboveEnd, Staff staff,
    int startLoc, int endLoc) {
  final int staffTopLoc = 2 * (staff.drawingLines - 1);
  final int loc1 = aboveStart
      ? math.max(startLoc, staffTopLoc - 1)
      : math.min(startLoc, 1);
  final int loc2 = aboveEnd
      ? math.max(endLoc, staffTopLoc - 1)
      : math.min(endLoc, 1);

  return loc2 - loc1;
}

/// The drawing loc of a note (mirrors Note::GetDrawingLoc).
int _slurLocOf(Note note) => (note as dynamic).drawingLoc as int;

/// The stem length of an element (0 without a stem).
int _slurStemLenOf(LayerElement element) {
  if (element is StemmedDrawingInterface) {
    return (element as StemmedDrawingInterface).getDrawingStemLen();
  }
  return 0;
}

/// Mirrors `LayerElement::GetDrawingRadius` reduced to the notehead glyph
/// width (mensural glyphs deferred).
int _slurRadiusOf(Doc doc, LayerElement element, int staffSize) {
  return doc.getGlyphWidth(smuflE0A4NoteheadBlack, staffSize,
          element.drawingCueSize) ~/
      2;
}
