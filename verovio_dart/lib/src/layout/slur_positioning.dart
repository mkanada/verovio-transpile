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
/// Deviations:
/// - `Slur::CalcEndPoints` (slur.cpp:598) is now a full port: the
///   stem-direction, grace-note, portato (`IsPortatoSlur`), beam-adjacent
///   (`HasBoundaryOnBeam`), s-shaped and near-end-collision branches, the
///   flipped-notehead X correction, and the broken-slur
///   (SPANNING_START / END / MIDDLE) staff positions are all ported. Only
///   `AdjustSlurFromBulge` (`@bulge`, `adjustslursfunctor.cpp`) remains
///   deferred — such slurs keep their initial curve (see `adjust_slurs.dart`).
///   `(this as Slur)` casts are used for the two Slur-only helpers
///   (`isPortatoSlur`/`hasBoundaryOnBeam`): safe because `calcEndPoints` is
///   only ever reached through `AdjustSlursFunctor` and `View.drawSlur`,
///   both restricted to `Slur`/`Phrase` (`Phrase extends Slur`) — never `Tie`
///   or `Lv`, despite the class doc above.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset, MeiDuration;
import 'package:verovio_dart/src/core/smufl.dart' show smuflE0A4NoteheadBlack;
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show CurveSpannedElement, FloatingCurvePositioner, FloatingPositioner,
        NearEndCollision;
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show CurvatureCurvedir, Staffrel, Stemdirection;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Measure, Note, Staff;
import 'package:verovio_dart/src/model/control_elements_gen.dart'
    show PortatoSlurType, Slur, Tie;
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Artic, Stem, Tuplet, TupletBracket;
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

SlurCurveDirection _slurCurveDir(Object obj) {
  if (obj is Slur) return obj.drawingCurveDir;
  if (obj is Tie) return obj.drawingCurveDir;
  return SlurCurveDirection.none;
}

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
    final SlurCurveDirection slurDir = _slurCurveDir(this);
    switch (slurDir) {
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
    final SlurCurveDirection dir = _slurCurveDir(this);
    return dir == SlurCurveDirection.aboveBelow ||
        dir == SlurCurveDirection.belowAbove;
  }

  /// Mirrors `HasEndpointAboveStart`.
  bool get hasEndpointAboveStart {
    final SlurCurveDirection dir = _slurCurveDir(this);
    return dir == SlurCurveDirection.above ||
        dir == SlurCurveDirection.aboveBelow;
  }

  /// Mirrors `HasEndpointBelowStart`.
  bool get hasEndpointBelowStart {
    final SlurCurveDirection dir = _slurCurveDir(this);
    return dir == SlurCurveDirection.below ||
        dir == SlurCurveDirection.belowAbove;
  }

  /// Mirrors `HasEndpointAboveEnd`.
  bool get hasEndpointAboveEnd {
    final SlurCurveDirection dir = _slurCurveDir(this);
    return dir == SlurCurveDirection.above ||
        dir == SlurCurveDirection.belowAbove;
  }

  /// Mirrors `HasEndpointBelowEnd`.
  bool get hasEndpointBelowEnd {
    final SlurCurveDirection dir = _slurCurveDir(this);
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
    final SlurCurveDirection selfDir = _slurCurveDir(this);
    final SlurCurveDirection innerDir = _slurCurveDir(innerSlurObject);
    if (selfDir != innerDir) return false;
    if (hasMixedCurveDir) return false;

    final Object? start = slurStart;
    final Object? end = slurEnd;
    if (start is! LayerElement || end is! LayerElement) return false;
    final Object? innerStart =
        (innerSlurObject as TimeSpanningInterface).getStart();
    final Object? innerEnd =
        (innerSlurObject as TimeSpanningInterface).getEnd();
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
  /// [curve]. `CalcEndPoints` itself (called below) is a full port — see the
  /// library deviations.
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
    final (Point endPoint1, Point endPoint2) = calcEndPoints(
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

  /// Mirrors `Slur::CalcEndPoints` (slur.cpp:598). Returns `(p1, p2)`.
  (Point, Point) calcEndPoints(
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

    // Mirrors `hasStartFlag` (slur.cpp:625/629) and `isGraceToNoteSlur`
    // (slur.cpp:646).
    final bool hasStartFlag = start.findDescendantByType(ClassId.flag) != null;
    final bool isGraceToNoteSlur = !start.isClass(ClassId.timestampAttr) &&
        !end.isClass(ClassId.timestampAttr) &&
        start.isGraceNote() &&
        !end.isGraceNote();
    final PortatoSlurType portatoSlurType =
        (this as Slur).isPortatoSlur(doc, startNote, startChord);

    int yChordMax = 0;
    int yChordMin = 0;
    if (((spanningType == spanningStartEnd) || (spanningType == spanningStart)) &&
        !start.isClass(ClassId.timestampAttr)) {
      final int startRadius = _slurRadiusOf(doc, start, staffSize);
      if (startChord != null) {
        final (int chordMax, int chordMin) = startChord.getYExtremesAbs(doc, staffSize);
        yChordMax = chordMax;
        yChordMin = chordMin;
        if (startNote != null && startNote.flippedNotehead) {
          final Note? refNote = (startStemDir == Stemdirection.down)
              ? startChord.getTopNote()
              : startChord.getBottomNote();
          if (refNote != null) x1 += refNote.getDrawingX() - startNote.getDrawingX();
        }
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
        // portato slurs
        else if (portatoSlurType != PortatoSlurType.none) {
          y1 = drawingTopOf(doc, start, staffSize);
          final Note? refNote = startChord != null ? startChord.getBottomNote() : startNote;
          if (refNote != null) x1 = refNote.getDrawingX() + startRadius;
          if (portatoSlurType == PortatoSlurType.stemSide) x1 += startRadius;
        }
        // same but in beam - adjust the x too
        else if ((this as Slur).hasBoundaryOnBeam(true) || isGraceToNoteSlur || hasStartFlag) {
          y1 = drawingTopOf(doc, start, staffSize);
          // Secondary endpoint for grace notes is further left
          double weight = 1.0;
          if (nearEndCollision != null &&
              nearEndCollision.metricAtStart > 1.0 &&
              isGraceToNoteSlur) {
            weight = -0.5;
            nearEndCollision.endPointsAdjusted = true;
          }
          x1 += (weight * (startRadius - doc.getDrawingStemWidth(staffSize))).toInt();
        }
        // d(^): primary endpoint on the side
        else {
          if (nearEndCollision != null && nearEndCollision.metricAtStart > 0.3) {
            // Secondary endpoint on top
            y1 = drawingTopOf(doc, start, staffSize);
            x1 += startRadius - doc.getDrawingStemWidth(staffSize);
            nearEndCollision.endPointsAdjusted = true;
          } else {
            // Primary endpoint on the side, move it right
            x1 += unit * 2;
            y1 = (startChord != null)
                ? yChordMax + unit * 3
                : start.getDrawingY() + unit * 3;
          }
        }
      }
      // slur is down
      else {
        // grace note
        if (isGraceToNoteSlur) {
          y1 = drawingBottomOf(doc, start, staffSize);
          if (startStemDir != Stemdirection.up) {
            x1 -= startRadius + doc.getDrawingStemWidth(staffSize);
          } else {
            y1 += unit ~/ 2;
          }
        } else if ((startStemDir == Stemdirection.up) || (startStemLen == 0)) {
          y1 = drawingBottomOf(doc, start, staffSize);
        } else if (isShortSlur) {
          y1 = drawingBottomOf(doc, start, staffSize);
        } else if (isSshaped) {
          y1 = drawingBottomOf(doc, start, staffSize);
          x1 -= startRadius - doc.getDrawingStemWidth(staffSize);
        } else if (portatoSlurType != PortatoSlurType.none) {
          y1 = drawingBottomOf(doc, start, staffSize);
          final Note? refNote = startChord != null ? startChord.getTopNote() : startNote;
          if (refNote != null) x1 = refNote.getDrawingX();
          if (portatoSlurType == PortatoSlurType.centered) x1 += startRadius;
        } else if ((this as Slur).hasBoundaryOnBeam(true) || hasStartFlag) {
          y1 = drawingBottomOf(doc, start, staffSize);
          x1 -= startRadius - doc.getDrawingStemWidth(staffSize);
        } else {
          if (nearEndCollision != null && nearEndCollision.metricAtStart > 0.3) {
            // Secondary endpoint on bottom
            y1 = drawingBottomOf(doc, start, staffSize);
            x1 -= startRadius - doc.getDrawingStemWidth(staffSize);
            nearEndCollision.endPointsAdjusted = true;
          } else {
            if (startChord != null) {
              y1 = yChordMin - unit * 3;
            } else {
              y1 = start.getDrawingY() - unit * 3;
            }
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
        if (endNote != null && endNote.flippedNotehead) {
          final Note? refNote = (endStemDir == Stemdirection.down)
              ? endChord.getTopNote()
              : endChord.getBottomNote();
          if (refNote != null) x2 += refNote.getDrawingX() - endNote.getDrawingX();
        }
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
        }
        // grace note
        else if (isGraceToNoteSlur) {
          final int yMin = y1 - unit * 4;
          final int yTop = drawingTopOf(doc, end, staffSize);
          y2 = math.max(end.getDrawingY() + unit * 2, yMin);
          if (y2 > yTop - unit * 2) {
            y2 = yTop;
            x2 += endRadius - doc.getDrawingStemWidth(staffSize);
          }
        }
        // portato slurs
        else if (portatoSlurType != PortatoSlurType.none) {
          y2 = drawingTopOf(doc, end, staffSize);
          final Note? refNote = endChord != null ? endChord.getBottomNote() : endNote;
          if (refNote != null) x2 = refNote.getDrawingX() + endRadius;
          if (portatoSlurType == PortatoSlurType.stemSide) x2 += endRadius;
        }
        // same but in beam - adjust the x too
        else if ((this as Slur).hasBoundaryOnBeam(false)) {
          y2 = drawingTopOf(doc, end, staffSize);
          x2 += endRadius - doc.getDrawingStemWidth(staffSize);
        } else {
          if (nearEndCollision != null && nearEndCollision.metricAtEnd > 0.3) {
            // Secondary endpoint on top
            y2 = drawingTopOf(doc, end, staffSize);
            x2 += endRadius - doc.getDrawingStemWidth(staffSize);
            nearEndCollision.endPointsAdjusted = true;
          } else {
            // (^)d: primary endpoint on the side
            if (endChord != null) {
              y2 = yChordMax + unit * 3;
            } else {
              y2 = end.getDrawingY() + unit * 3;
            }
          }
        }
      } else {
        // (_)d
        if ((endStemDir == Stemdirection.up) || (endStemLen == 0)) {
          y2 = drawingBottomOf(doc, end, staffSize);
        }
        // P(_)P
        else if (isGraceToNoteSlur) {
          final int yMax = y1 + unit;
          final int yBottom = drawingBottomOf(doc, end, staffSize);
          y2 = math.min(end.getDrawingY(), yMax);
          if (y2 < yBottom + unit) {
            y2 = yBottom + unit * 2;
          } else {
            x2 -= endRadius + 2 * doc.getDrawingStemWidth(staffSize);
          }
        } else if (isShortSlur) {
          y2 = drawingBottomOf(doc, end, staffSize);
        } else if (isSshaped) {
          y2 = drawingBottomOf(doc, end, staffSize);
          x2 -= endRadius - doc.getDrawingStemWidth(staffSize);
        } else if (portatoSlurType != PortatoSlurType.none) {
          y2 = drawingBottomOf(doc, end, staffSize);
          final Note? refNote = endChord != null ? endChord.getTopNote() : endNote;
          if (refNote != null) x2 = refNote.getDrawingX();
          if (portatoSlurType == PortatoSlurType.centered) x2 += endRadius;
        } else if ((this as Slur).hasBoundaryOnBeam(false)) {
          y2 = drawingBottomOf(doc, end, staffSize);
          x2 -= endRadius - doc.getDrawingStemWidth(staffSize);
        } else {
          if (nearEndCollision != null && nearEndCollision.metricAtEnd > 0.3) {
            // Secondary endpoint on bottom
            y2 = drawingBottomOf(doc, end, staffSize);
            x2 -= endRadius - doc.getDrawingStemWidth(staffSize);
            nearEndCollision.endPointsAdjusted = true;
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
  /// Returns false (no melodic direction adjustment) until system break
  /// detection lands; the C++ only applies it across system breaks
  /// (slur.cpp).
  bool considerMelodicDirection(Object? start, Object? end) => false;

  // -------------------------------------------------------------------------
  // Spanned elements
  // -------------------------------------------------------------------------

  /// Port of `Slur::AddPositionerToArticulations` (slur.cpp:429): registers
  /// [curve] on every outside articulation of the boundary notes/chords that
  /// sits on the same side as the curve's own direction, so
  /// `AdjustArticWithSlursFunctor` later pushes it clear of the curve.
  void addPositionerToArticulationsFor(FloatingCurvePositioner curve) {
    final Object? start = slurStart;
    final Object? end = slurEnd;
    if (start is! LayerElement || end is! LayerElement) return;

    final int spanningType = curve.getSpanningType();
    final CurvatureCurvedir curveDir = calcDrawingCurveDirFor(spanningType);

    void addTo(LayerElement boundary, bool isStart) {
      for (final Object object in boundary
          .findAllDescendantsByClassIdPredicate(
              (ClassId id) => id == ClassId.artic)) {
        final Artic artic = object as Artic;
        if (!artic.isOutsideArtic()) continue;
        if ((artic.drawingPlace == Staffrel.above) &&
            (curveDir == CurvatureCurvedir.above)) {
          artic.addSlurPositioner(curve, isStart);
        } else if ((artic.drawingPlace == Staffrel.below) &&
            (curveDir == CurvatureCurvedir.below)) {
          artic.addSlurPositioner(curve, isStart);
        }
      }
    }

    // The normal case or start.
    if (spanningType == spanningStartEnd || spanningType == spanningStart) {
      addTo(start, true);
    }
    // Normal case or end.
    if (spanningType == spanningStartEnd || spanningType == spanningEnd) {
      addTo(end, false);
    }
  }

  /// Port of `Slur::CalcSpannedElements` (slur.cpp:188): collects, filters
  /// and stores the layer elements (and colliding ties) spanned by the
  /// curve.
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

    final ({List<LayerElement> elements, Set<int> layersN}) spanned =
        _collectSpannedElements(start, end, staff, x1, x2);

    _addSpannedElements(curve, spanned, staff, start, end, x1, x2);
  }

  /// Port of `Slur::CollectSpannedElements` (slur.cpp:203): mirrors
  /// `FindSpannedLayerElementsFunctor` plus the two-pass outside-layers
  /// pitch filtering (slur.cpp:227-305) that reruns the search bounded to
  /// `[minLayerN, maxLayerN]` when the unbounded search picked up elements
  /// from voices that turn out to be pitch-separated from the slur's own
  /// layers (or when the slur prescribes `@layer` explicitly).
  ({List<LayerElement> elements, Set<int> layersN}) _collectSpannedElements(
      LayerElement start, LayerElement end, Staff staff, int xMin, int xMax) {
    final bool spanningMeasures =
        (this as TimeSpanningInterface).isSpanningMeasures();
    final Object? container = spanningMeasures
        ? start.getFirstAncestor(ClassId.system)
        : (this as TimeSpanningInterface).getStartMeasure();
    if (container == null) {
      return (elements: <LayerElement>[], layersN: <int>{});
    }

    final Measure? startMeasure =
        (this as TimeSpanningInterface).getStartMeasure();
    final Measure? endMeasure =
        (this as TimeSpanningInterface).getEndMeasure();

    final Set<int> staffNumbers = {staff.n ?? meiUnset};
    final Staff? startStaff = start.getAncestorStaffResolveCrossStaff();
    final Staff? endStaff = end.getAncestorStaffResolveCrossStaff();
    if (startStaff != null && startStaff.n != staff.n) {
      staffNumbers.add(startStaff.n ?? meiUnset);
    } else if (endStaff != null && endStaff.n != staff.n) {
      staffNumbers.add(endStaff.n ?? meiUnset);
    }

    const List<ClassId> spannedClasses = [
      ClassId.accid,
      ClassId.artic,
      ClassId.chord,
      ClassId.clef,
      ClassId.dot,
      ClassId.dots,
      ClassId.flag,
      ClassId.gliss,
      ClassId.note,
      ClassId.stem,
      ClassId.tupletBracket,
      ClassId.tupletNum,
    ];

    List<LayerElement> runSearch({int? minLayerN, int? maxLayerN}) {
      final List<LayerElement> result = [];
      for (final Object object
          in container.findAllDescendantsByClassIdPredicate(
              (ClassId id) => spannedClasses.contains(id))) {
        if (object.isScoreDefElement) continue;
        final LayerElement element = object as LayerElement;
        if (_matchesSpannedElement(
            element,
            start,
            end,
            xMin,
            xMax,
            staffNumbers,
            minLayerN,
            maxLayerN,
            spanningMeasures,
            startMeasure,
            endMeasure)) {
          result.add(element);
        }
      }
      return result;
    }

    List<LayerElement> spannedElements = runSearch();

    final Slur slurSelf = this as Slur;
    final Set<int> layersN = slurSelf.hasLayer
        ? {slurSelf.layer!}
        : {start.getOriginalLayerN(), end.getOriginalLayerN()};
    final int minLayerN = layersN.reduce((a, b) => a < b ? a : b);
    final int maxLayerN = layersN.reduce((a, b) => a > b ? a : b);

    final bool hasOutsideLayers = spannedElements.any((LayerElement element) {
      final int layerN = element.getOriginalLayerN();
      return (layerN < minLayerN) || (layerN > maxLayerN);
    });

    if (hasOutsideLayers) {
      // Filter all notes, also including the notes of the start and end of
      // the slur.
      final List<Note> notes = [
        for (final LayerElement element in spannedElements)
          if (element is Note) element,
      ];
      for (final LayerElement boundary in [start, end]) {
        if (boundary is Note) {
          notes.add(boundary);
        } else {
          notes.addAll(boundary
              .findAllDescendantsByClassIdPredicate(
                  (ClassId id) => id == ClassId.note,
                  deepness: 1)
              .cast<Note>());
        }
      }

      // Determine the minimal and maximal diatonic pitch.
      int minPitch = 1000;
      int maxPitch = 0;
      for (final Note note in notes) {
        final int layerN = note.getOriginalLayerN();
        if (layerN == maxLayerN) {
          minPitch = minPitch < note.getDiatonicPitch()
              ? minPitch
              : note.getDiatonicPitch();
        }
        if (layerN == minLayerN) {
          maxPitch = maxPitch > note.getDiatonicPitch()
              ? maxPitch
              : note.getDiatonicPitch();
        }
      }

      // Check if voices are separated.
      final bool layersAreSeparated = notes.every((Note note) {
        final int layerN = note.getOriginalLayerN();
        if (layerN < minLayerN) return note.getDiatonicPitch() > maxPitch;
        if (layerN > maxLayerN) return note.getDiatonicPitch() < minPitch;
        return true;
      });

      // For separated voices or prescribed layers rerun the search with
      // layer bounds.
      if (layersAreSeparated || slurSelf.hasLayer) {
        spannedElements =
            runSearch(minLayerN: minLayerN, maxLayerN: maxLayerN);
      }
    }

    // Collect the layers used for collision avoidance.
    for (final LayerElement element in spannedElements) {
      layersN.add(element.getOriginalLayerN());
    }

    return (elements: spannedElements, layersN: layersN);
  }

  /// Port of `FindSpannedLayerElementsFunctor::VisitLayerElement`
  /// (findlayerelementsfunctor.cpp:175): the content-bbox / staff / layer /
  /// aligned-boundary filters applied to each candidate.
  bool _matchesSpannedElement(
      LayerElement element,
      LayerElement start,
      LayerElement end,
      int minPos,
      int maxPos,
      Set<int> staffNs,
      int? minLayerN,
      int? maxLayerN,
      bool spanningMeasures,
      Measure? startMeasure,
      Measure? endMeasure) {
    if (!element.hasContentBB() || element.hasEmptyBB()) return false;
    final int contentLeft = element.getContentLeft();
    final int contentRight = element.getContentRight();
    if (!((contentRight > minPos) && (contentLeft < maxPos))) return false;

    // We skip the start or end of the slur.
    if (identical(element, start) || identical(element, end)) return false;

    // Skip elements from measures outside [startMeasure, endMeasure] when
    // the search runs over the whole system (mirrors
    // `FindSpannedLayerElementsFunctor::VisitMeasure`).
    if (spanningMeasures) {
      final Object? measure = element.getFirstAncestor(ClassId.measure);
      if (measure == null) return false;
      if (startMeasure != null && Object.isPreOrdered(measure, startMeasure)) {
        return false;
      }
      if (endMeasure != null && Object.isPreOrdered(endMeasure, measure)) {
        return false;
      }
    }

    // Skip if neither parent staff nor cross staff matches the given staff
    // numbers.
    if (staffNs.isNotEmpty) {
      Staff? matchStaff = element.getAncestorStaffLayoutOrNull();
      if (matchStaff == null || !staffNs.contains(matchStaff.n)) {
        matchStaff = element.getCrossStaff().$1;
        if (matchStaff == null || !staffNs.contains(matchStaff.n)) {
          return false;
        }
      }
    }

    // Skip if layer number is outside given bounds.
    final int layerN = element.getOriginalLayerN();
    if (minLayerN != null && minLayerN > layerN) return false;
    if (maxLayerN != null && maxLayerN < layerN) return false;

    // Skip elements aligned at start/end, but on a different staff.
    if (identical(element.getAlignment(), start.getAlignment()) &&
        !start.isClass(ClassId.timestampAttr)) {
      final Staff? elementStaff = element.getAncestorStaffResolveCrossStaff();
      final Staff? startStaff = start.getAncestorStaffResolveCrossStaff();
      if (elementStaff?.n != startStaff?.n) return false;
    }
    if (identical(element.getAlignment(), end.getAlignment()) &&
        !end.isClass(ClassId.timestampAttr)) {
      final Staff? elementStaff = element.getAncestorStaffResolveCrossStaff();
      final Staff? endStaff = end.getAncestorStaffResolveCrossStaff();
      if (elementStaff?.n != endStaff?.n) return false;
    }

    return true;
  }

  /// Port of `Slur::AddSpannedElements` (slur.cpp:315): filters the
  /// collected elements by curve overlap, discards tuplets that should be
  /// drawn outside the slur, then adds colliding ties from the boundary
  /// staff alignments.
  void _addSpannedElements(
      FloatingCurvePositioner curve,
      ({List<LayerElement> elements, Set<int> layersN}) spanned,
      Staff staff,
      LayerElement start,
      LayerElement end,
      int xMin,
      int xMax) {
    final Staff? startStaff = start.getAncestorStaffResolveCrossStaff();
    final Staff? endStaff = end.getAncestorStaffResolveCrossStaff();
    if (startStaff != null && endStaff != null && startStaff.n != endStaff.n) {
      curve.setCrossStaff(endStaff);
    }

    curve.clearSpannedElements();
    for (final LayerElement element in spanned.elements) {
      final int xLeft = element.getSelfLeft();
      final int xRight = element.getSelfRight();
      final bool isOverlapping =
          ((xLeft > xMin) && (xLeft < xMax)) ||
              ((xRight > xMin) && (xRight < xMax));

      if (isOverlapping || element.isClass(ClassId.tupletBracket)) {
        final CurveSpannedElement spannedElement = CurveSpannedElement();
        spannedElement.boundingBox = element;
        spannedElement.isBelow =
            isElementBelowFor(element, startStaff, endStaff);
        curve.addSpannedElement(spannedElement);
      }

      if (!curve.isCrossStaff() && element.crossStaff != null) {
        curve.setCrossStaff(element.crossStaff);
      }
    }

    // Some tuplet elements are discarded immediately, if they should be
    // rendered outside the slur => flexible layout priority (mirrors
    // `Slur::DiscardTupletElements`, slur.cpp:344).
    discardTupletElements(curve, xMin, xMax);

    // Ties can be broken across systems, so we have to look for all floating
    // curve positioners that represent them (slur.cpp:346-358; coarse
    // bounding-box collision avoidance with slurs).
    final List<FloatingPositioner> tiePositioners = [
      ...?staff.staffAlignment?.findAllFloatingPositioners(ClassId.tie),
    ];
    if (startStaff != null &&
        !identical(startStaff, staff) &&
        startStaff.staffAlignment != null) {
      tiePositioners.addAll(
          startStaff.staffAlignment!.findAllFloatingPositioners(ClassId.tie));
    } else if (endStaff != null &&
        !identical(endStaff, staff) &&
        endStaff.staffAlignment != null) {
      tiePositioners.addAll(
          endStaff.staffAlignment!.findAllFloatingPositioners(ClassId.tie));
    }

    // Only consider ties in collision layers (slur.cpp:361).
    tiePositioners.removeWhere((FloatingPositioner positioner) {
      final TimeSpanningInterface? iface =
          positioner.getObject()?.getTimeSpanningInterface();
      if (iface == null) return true;
      if (iface.getStart() == null || iface.getEnd() == null) return true;
      final bool startsInCollisionLayer =
          spanned.layersN.contains(iface.getStart()!.getOriginalLayerN());
      final bool endsInCollisionLayer =
          spanned.layersN.contains(iface.getEnd()!.getOriginalLayerN());
      return !startsInCollisionLayer && !endsInCollisionLayer;
    });

    // Add ties to spanning elements (slur.cpp:375).
    for (final FloatingPositioner positioner in tiePositioners) {
      if (identical(positioner.getStaffAlignment()?.getParentSystem(),
          curve.getStaffAlignment()?.getParentSystem())) {
        if (positioner.hasContentBB() &&
            (positioner.getContentRight() > xMin) &&
            (positioner.getContentLeft() < xMax)) {
          final CurveSpannedElement spannedElement = CurveSpannedElement();
          spannedElement.boundingBox = positioner;
          spannedElement.isBelow =
              isPositionerBelowFor(positioner, startStaff, endStaff);
          curve.addSpannedElement(spannedElement);
        }
      }
    }
  }

  /// Mirrors `Slur::IsElementBelow(const FloatingPositioner *, const Staff *,
  /// const Staff *)` (slur.cpp:536).
  bool isPositionerBelowFor(
      FloatingPositioner positioner, Staff? startStaff, Staff? endStaff) {
    final SlurCurveDirection dir = _slurCurveDir(this);
    if (dir == SlurCurveDirection.above) return true;
    if (dir == SlurCurveDirection.below) return false;
    if (dir == SlurCurveDirection.aboveBelow) {
      return positioner.getStaffAlignment()?.getStaff()?.n == startStaff?.n;
    }
    if (dir == SlurCurveDirection.belowAbove) {
      return positioner.getStaffAlignment()?.getStaff()?.n == endStaff?.n;
    }
    return false;
  }

  /// Mirrors `Slur::DiscardTupletElements` (slur.cpp:388-425): tuplet
  /// brackets that overlap this slur are discarded from its spanned elements
  /// and registered on the tuplet for the AdjustTupletWithSlurs pass.
  void discardTupletElements(
      FloatingCurvePositioner curve, int xMin, int xMax) {
    for (final CurveSpannedElement spannedElement
        in curve.getSpannedElements()) {
      final BoundingBox? bbox = spannedElement.boundingBox;
      if (bbox == null || !bbox.isClass(ClassId.tupletBracket)) continue;

      final TupletBracket tupletBracket = bbox as TupletBracket;
      final Object? parent = tupletBracket.parent;
      final Tuplet? tuplet =
          parent is Tuplet ? parent : parent?.getFirstAncestor(ClassId.tuplet) as Tuplet?;
      if (tuplet == null) continue;

      final int xLeft = tupletBracket.getSelfLeft();
      final int xRight = tupletBracket.getSelfRight();
      final bool isContained = (xLeft > xMin) && (xRight < xMax);
      final bool isOverlapping = ((xLeft > xMin) && (xLeft < xMax)) ||
          ((xRight > xMin) && (xRight < xMax));

      // Slurs avoid inner tuplets.
      if (isContained) continue;

      // Slurs avoid overlapping tuplets which are beam aligned or not
      // significantly longer.
      if (isOverlapping) {
        if (tuplet.bracketAlignedBeam != null) continue;
        if (xRight - xLeft < 2 * (xMax - xMin)) continue;
      }

      // Discard the tuplet bracket and register the slur for tuplet
      // adjustment.
      spannedElement.discarded = true;
      // Exceptional case where the slur actually modifies a spanned element.
      tuplet.addInnerSlur(curve);

      // Discard any associated tuplet number as well.
      final Object? tupletNum = tupletBracket.alignedNum;
      for (final CurveSpannedElement other in curve.getSpannedElements()) {
        if (identical(other.boundingBox, tupletNum)) {
          other.discarded = true;
        }
      }
    }
  }

  /// Mirrors `Slur::IsElementBelow(LayerElement*, …)` reduced to the plain
  /// direction cases plus the mixed-direction staff comparison.
  bool isElementBelowFor(
      LayerElement element, Staff? startStaff, Staff? endStaff) {
    final SlurCurveDirection dir = _slurCurveDir(this);
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
    if (element is LayerElement) {
      final Staff? cross = element.crossStaff;
      if (cross != null) return cross;
    }
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
  final Stem? stem = element is StemmedDrawingInterface
      ? (element as StemmedDrawingInterface).getDrawingStem()
      : null;
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
    return note.drawingLoc;
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
int _slurLocOf(Note note) => note.drawingLoc;

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
