/// Port of `floatingobject.h/cpp` — FloatingPositioner and
/// FloatingCurvePositioner (the layout-domain representation of control
/// events attached to a StaffAlignment), plus the supporting structs
/// (`CurveSpannedElement`, `ControlPointConstraint`,
/// `ControlPointAdjustment`, `NearEndCollision`) and the curve / rectangle
/// intersection helpers of `boundingbox.cpp`.
///
/// The classes were introduced as shells in Phase 2 (vertical_aligner.dart)
/// and are completed here; vertical_aligner.dart re-exports them.
///
/// Deviations from the C++:
/// - `FloatingPositioner::GetDrawingPlace` for ornaments that consult
///   `GetLayerPlace` (mordent, ornam, trill, turn, repeatMark) defaults to
///   the encoded @place or above without the layer based refinement (the
///   layer place requires the rendered stem directions).
/// - `BoundingBox::Intersects(BeamDrawingInterface…)` is reduced to a plain
///   rectangle intersection (`intersectsRectangle`): beam geometry (pos /
///   heightRatio based cut-outs) arrives with the beam rendering phase.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show CurvatureCurvedir, Staffrel, StaffrelBasic;
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show MeasurementSigned, MeasurementType;
import 'package:verovio_dart/src/model/basic_elements.dart' show Staff;
import 'package:verovio_dart/src/model/control_elements_gen.dart'
    show Turn;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;

// ---------------------------------------------------------------------------
// Supporting structs
// ---------------------------------------------------------------------------

/// Mirrors `vrv::CurveSpannedElement`: a layer element (or positioner) spanned
/// by a slur / tie used for collision avoidance.
class CurveSpannedElement {
  /// The bounding box of the element (mirrors `m_boundingBox`).
  BoundingBox? boundingBox;

  /// Whether the element already fits on its side (mirrors `m_discarded`).
  bool discarded = false;

  /// Whether the element has to lie below the slur (mirrors `m_isBelow`).
  bool isBelow = true;
}

/// Mutable boolean holder standing in for the C++ `bool &discard` output
/// parameter.
class Discard {
  bool value = false;
}

/// Mirrors the private struct `vrv::ControlPointConstraint`: a constraint
/// `a * x + b * y >= c` on the vertical adjustments of the control points.
class ControlPointConstraint {
  ControlPointConstraint(this.a, this.b, this.c);

  final double a;
  final double b;
  final double c;
}

/// Mirrors the private struct `vrv::ControlPointAdjustment`.
class ControlPointAdjustment {
  int leftShift = 0;
  int rightShift = 0;
  bool moveUpwards = false;
  int requestedStaffSpace = 0;
}

/// Mirrors the struct `vrv::NearEndCollision` (slur.h): measures collisions
/// near the end points.
class NearEndCollision {
  NearEndCollision(
      this.metricAtStart, this.metricAtEnd, this.endPointsAdjusted);

  double metricAtStart;
  double metricAtEnd;
  bool endPointsAdjusted;

  factory NearEndCollision.initial() => NearEndCollision(0.0, 0.0, false);
}

// ---------------------------------------------------------------------------
// FloatingPositioner
// ---------------------------------------------------------------------------

/// This class is used for storing positioners of floating objects (mirrors
/// `vrv::FloatingPositioner`, owned by a StaffAlignment).
class FloatingPositioner extends BoundingBox {
  /// Creates a positioner pointing to [object] on [staffAlignment]
  /// (mirrors `FloatingPositioner(FloatingObject*, StaffAlignment*, char)`),
  /// including the per-class default drawing place.
  FloatingPositioner(this._object, this._staffAlignment, this.spanningType) {
    assert(_object != null);
    assert(_staffAlignment != null);
    _place = _resolvePlace(_object!);
    resetPositioner();
  }

  /// The floating object the positioner refers to (mirrors `m_object`).
  final FloatingObject? _object;

  /// The staff alignment the positioner belongs to (mirrors `m_alignment`).
  final StaffAlignment? _staffAlignment;

  /// The spanning type of the positioner (`SPANNING_*`; mirrors
  /// `m_spanningType`).
  int spanningType;

  /// The X and Y objects the positioner points to (mirrors `m_objectX` /
  /// `m_objectY`).
  Object? _objectX;
  Object? _objectY;

  /// The X drawing relative position of the object (mirrors
  /// `m_drawingXRel`; currently used only for Arpeg).
  int _drawingXRel = 0;

  /// The Y drawing relative position of the object (mirrors
  /// `m_drawingYRel`). It is re-computed every time the object is drawn.
  int _drawingYRel = 0;

  /// The horizontal width of the extender line whenever it is not included
  /// in the bounding box (mirrors `m_drawingExtenderWidth`).
  int _drawingExtenderWidth = 0;

  /// The placement w.r.t. the staff (mirrors `m_place`).
  Staffrel _place = Staffrel.none;

  @override
  ClassId get classId => ClassId.floatingPositioner;

  /// Mirrors `GetObject`.
  FloatingObject? getObject() => _object;

  /// Mirrors `GetAlignment`.
  StaffAlignment? getStaffAlignment() => _staffAlignment;

  /// Mirrors `GetSpanningType`.
  int getSpanningType() => spanningType;

  /// Mirrors `GetDrawingPlace`.
  Staffrel getDrawingPlace() => _place;

  /// Helper reading the encoded @place for objects having
  /// AttPlacementRelStaff (STAFFREL_NONE when absent).
  static Staffrel _encodedPlace(FloatingObject object) {
    final dynamic place = (object as dynamic).place;
    return place is Staffrel ? place : Staffrel.none;
  }

  /// Resolve the default drawing place from the class of the object
  /// (mirrors the constructor if-chain in `floatingobject.cpp`).
  static Staffrel _resolvePlace(FloatingObject object) {
    if (object.isClass(ClassId.accidFloating)) {
      // accid above by default (the parent Accid @place).
      final Object? parent = object.parent;
      final dynamic accidPlace = parent != null && parent.isClass(ClassId.accid)
          ? (parent as dynamic).place
          : null;
      return (accidPlace is Staffrel && accidPlace != Staffrel.none)
          ? accidPlace
          : Staffrel.above;
    } else if (object.isAny(const {
      ClassId.annotScore,
      ClassId.bracketSpan,
      ClassId.ending,
      ClassId.pitchInflection,
    })) {
      // always above
      return Staffrel.above;
    } else if (object.isClass(ClassId.breath)) {
      // breath above by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.above;
    } else if (object.isClass(ClassId.caesura)) {
      // caesura within by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.within;
    } else if (object.isClass(ClassId.cpMark)) {
      // cpMark above by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.above;
    } else if (object.isClass(ClassId.dir)) {
      // dir below by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.below;
    } else if (object.isClass(ClassId.dynam)) {
      // dynam below by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.below;
    } else if (object.isClass(ClassId.fermata)) {
      // fermata above by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.above;
    } else if (object.isClass(ClassId.fing)) {
      // fing above by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.above;
    } else if (object.isClass(ClassId.hairpin)) {
      // hairpin below by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.below;
    } else if (object.isClass(ClassId.harm)) {
      // harm above by default; fb below by default
      final Staffrel place = _encodedPlace(object);
      if (place != Staffrel.none) return place;
      final Object? firstChild = object.getFirst();
      return (firstChild != null && firstChild.isClass(ClassId.fb))
          ? Staffrel.below
          : Staffrel.above;
    } else if (object.isAny(const {
      ClassId.mordent,
      ClassId.ornam,
      ClassId.trill,
      ClassId.turn,
      ClassId.repeatMark,
    })) {
      // above by default; see the library deviations note for GetLayerPlace.
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.above;
    } else if (object.isClass(ClassId.octave)) {
      // octave below by default (won't draw without @dis.place anyway)
      final dynamic disPlace = (object as dynamic).disPlace;
      return (disPlace == StaffrelBasic.above)
          ? Staffrel.above
          : Staffrel.below;
    } else if (object.isClass(ClassId.pedal)) {
      // pedal below by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.below;
    } else if (object.isAny(const {ClassId.reh, ClassId.tempo})) {
      // reh / tempo above by default
      final Staffrel place = _encodedPlace(object);
      return place != Staffrel.none ? place : Staffrel.above;
    }
    // slurs, ties, etc. have no place.
    return Staffrel.none;
  }

  /// Mirrors `ResetPositioner`.
  void resetPositioner() {
    resetBoundingBox();
    resetCachedDrawingX();
    resetCachedDrawingY();

    _objectX = null;
    _objectY = null;

    _drawingYRel = 0;
    _drawingXRel = 0;

    _drawingExtenderWidth = 0;
  }

  /// Mirrors `GetDrawingX`.
  @override
  int getDrawingX() {
    assert(_objectX != null);
    if (_objectX == null) return 0;
    return _objectX!.getDrawingX() + getDrawingXRel();
  }

  /// Mirrors `GetDrawingY`.
  @override
  int getDrawingY() {
    assert(_objectY != null);
    if (_objectY == null) return -_drawingYRel;
    return _objectY!.getDrawingY() - _drawingYRel;
  }

  @override
  void resetCachedDrawingX() {
    cachedDrawingX = meiUnset;
  }

  @override
  void resetCachedDrawingY() {
    cachedDrawingY = meiUnset;
  }

  /// Mirrors `SetObjectXY`.
  void setObjectXY(Object objectX, Object objectY) {
    _objectX = objectX;
    _objectY = objectY;
  }

  /// Mirrors `GetObjectX`.
  Object? getObjectX() => _objectX;

  /// Mirrors `GetObjectY`.
  Object? getObjectY() => _objectY;

  /// Mirrors `GetDrawingYRel`.
  int getDrawingYRel() => _drawingYRel;

  /// Mirrors `SetDrawingYRel(int, bool)`: only moves away from the staff
  /// unless forced.
  void setDrawingYRel(int drawingYRel, {bool force = false}) {
    bool setValue = force;
    if (_place == Staffrel.above) {
      if (drawingYRel < _drawingYRel) setValue = true;
    } else {
      if (drawingYRel > _drawingYRel) setValue = true;
    }

    if (setValue) {
      resetCachedDrawingY();
      _drawingYRel = drawingYRel;
    }
  }

  /// Mirrors `GetDrawingXRel`.
  int getDrawingXRel() => _drawingXRel;

  /// Mirrors `SetDrawingXRel`.
  void setDrawingXRel(int drawingXRel) {
    resetCachedDrawingX();
    _drawingXRel = drawingXRel;
  }

  /// Mirrors `GetDrawingExtenderWidth`.
  int getDrawingExtenderWidth() => _drawingExtenderWidth;

  /// Mirrors `SetDrawingExtenderWidth`.
  void setDrawingExtenderWidth(int extenderWidth) =>
      _drawingExtenderWidth = extenderWidth;

  /// True when the overlapping box is a layer element (mirrors the
  /// `dynamic_cast<const Object*>` + IsLayerElement checks).
  static bool _isLayerElementBox(BoundingBox bbox) =>
      bbox is Object && bbox.isLayerElement;

  /// Mirrors `HasHorizontalOverlapWith`: check for horizontal overlap with
  /// special consideration for extender lines.
  bool hasHorizontalOverlapWith(BoundingBox bbox, int unit) {
    int bboxExtenderWidth = 0;
    if (bbox is FloatingPositioner) {
      bboxExtenderWidth = bbox.getDrawingExtenderWidth();
    }

    final int margin = getAdmissibleHorizOverlapMargin(bbox, unit);

    if (!hasContentBB() || !bbox.hasContentBB()) return false;
    if (getContentRight() + _drawingExtenderWidth <=
        bbox.getContentLeft() - margin) {
      return false;
    }
    if (getContentLeft() >=
        bbox.getContentRight() + bboxExtenderWidth + margin) {
      return false;
    }

    return true;
  }

  /// Mirrors `GetAdmissibleHorizOverlapMargin`: the horizontal margin for
  /// overlap with another element (can be negative when elements are allowed
  /// to slightly overlap).
  int getAdmissibleHorizOverlapMargin(BoundingBox bbox, int unit) {
    if (_isLayerElementBox(bbox)) {
      if (getObject()!.isExtenderElement) return 8 * unit;
      if (getObject()!.isClass(ClassId.dynam) &&
          (bbox as Object).getFirstAncestor(ClassId.beam) != null) {
        return 2 * unit;
      }
    }
    return 0;
  }

  /// Mirrors `CalcDrawingYRel`: update the Y drawing relative position based
  /// on collision detection with the overlapping bounding box.
  void calcDrawingYRel(Doc doc, StaffAlignment staffAlignment,
      BoundingBox? horizOverlappingBBox) {
    assert(_object != null);

    final int staffSize = staffAlignment.getStaffSize();
    int yRel = 0;

    final int unit = doc.getDrawingUnit(staffSize);
    if (horizOverlappingBBox == null) {
      // Apply element margin and enforce minimal staff distance
      final Staff? staff = staffAlignment.getStaff();

      int minStaffDistance = 0;
      final MeasurementSigned? distanceMeasurement =
          doc.getStaffDistance(_object!, staff?.n ?? 0, _place);
      if (distanceMeasurement != null && distanceMeasurement.hasValue()) {
        minStaffDistance = distanceMeasurement.type == MeasurementType.px
            ? distanceMeasurement.px
            : (distanceMeasurement.vu * unit).round();
      }

      if (staff != null && staff.drawingLines == 1) {
        minStaffDistance += (2.5 * unit).round();
      }

      if (_place == Staffrel.above) {
        yRel = getContentY1();
        yRel -= (doc.getBottomMargin(_object!.classId) * unit).toInt();
        setDrawingYRel(yRel);
        setDrawingYRel(-minStaffDistance);
      } else if (_place == Staffrel.within) {
        yRel = staffAlignment.getStaffHeight() ~/ 2;
        // Mirrors `floatingobject.cpp:498-508`: Turn uses GetTurnHeight, other
        // cpMark/dir/hairpin have no offset, remaining cases use content height.
        if (_object!.isClass(ClassId.turn)) {
          yRel += (_object! as Turn).getTurnHeight(doc, staffSize) ~/ 2;
        } else if (!_object!
            .isAny(const {ClassId.cpMark, ClassId.dir, ClassId.hairpin})) {
          yRel += (getContentY2() - getContentY1()) ~/ 2;
        }
        setDrawingYRel(yRel);
      } else {
        yRel = staffAlignment.getStaffHeight() + getContentY2();
        yRel += (doc.getTopMargin(_object!.classId) * unit).toInt();
        setDrawingYRel(yRel);
        setDrawingYRel(minStaffDistance + staffAlignment.getStaffHeight());
      }
    } else {
      final FloatingCurvePositioner? curve =
          horizOverlappingBBox is FloatingCurvePositioner
              ? horizOverlappingBBox
              : null;

      final int margin = (doc.getBottomMargin(_object!.classId) * unit).toInt();

      final (int staffSideContentBoundary, bool hasRefinedContentBoundary) =
          getVerticalContentBoundaryRel(
              doc, horizOverlappingBBox, _place != Staffrel.above);

      if (!hasRefinedContentBoundary) {
        // Employ special collision detection for beams and slurs/ties
        if (curve != null &&
            curve.getObject()!.isAny(const {
              ClassId.lv,
              ClassId.phrase,
              ClassId.slur,
              ClassId.tie
            })) {
          final int shift = intersectsCurve(curve, Accessor.content, margin);
          if (shift != 0) {
            setDrawingYRel(getDrawingYRel() - shift);
          }
          return;
        } else if (horizOverlappingBBox.isClass(ClassId.beam)) {
          // Beam collision uses rectangle overlap until beam geometry lands
          // (mirrors floatingobject.cpp:538-543, Intersects(Beam)).
          final int shift = intersectsRectangle(horizOverlappingBBox, margin);
          if (shift != 0) {
            setDrawingYRel(getDrawingYRel() - shift);
          }
          return;
        }
      }

      if (_place == Staffrel.above) {
        yRel = -staffAlignment.calcOverflowAbove(horizOverlappingBBox) +
            staffSideContentBoundary -
            margin;

        if (_isLayerElementBox(horizOverlappingBBox)) {
          if (yRel < 0) setDrawingYRel(yRel);
        }
        // Otherwise only if there is a vertical overlap
        else if (hasVerticalContentOverlap(doc, horizOverlappingBBox, margin)) {
          setDrawingYRel(yRel);
        }
      } else {
        yRel = staffAlignment.calcOverflowBelow(horizOverlappingBBox) +
            staffAlignment.getStaffHeight() +
            staffSideContentBoundary +
            margin;

        if (_isLayerElementBox(horizOverlappingBBox)) {
          if (yRel > 0) setDrawingYRel(yRel);
        }
        // Otherwise only if there is a vertical overlap
        else if (hasVerticalContentOverlap(doc, horizOverlappingBBox, margin)) {
          setDrawingYRel(yRel);
        }
      }
    }
  }

  /// Mirrors `AdjustExtenders`: align extender elements across systems.
  void adjustExtenders() {
    final bool isExtender =
        _object!.isAny(const {ClassId.dir, ClassId.dynam, ClassId.tempo}) &&
            _object!.isExtenderElement;
    if (!isExtender) return;

    _object!.setMaxDrawingYRel(_drawingYRel, _place);
    setDrawingYRel(_object!.maxDrawingYRel, force: true);
  }

  /// Mirrors `GetSpaceBelow`: calculate the vertical space below the element
  /// and above the bounding box.
  int getSpaceBelow(Doc doc, StaffAlignment staffAlignment,
      BoundingBox horizOverlappingBBox) {
    if (_place != Staffrel.between) return meiUnset;

    final int staffSize = staffAlignment.getStaffSize();
    final int margin =
        (doc.getBottomMargin(_object!.classId) * doc.getDrawingUnit(staffSize))
            .toInt();

    return getContentBottom() - horizOverlappingBBox.getSelfTop() - margin;
  }

  /// Mirrors `GetVerticalContentBoundaryRel` (delegates to the object; the
  /// base implementation only consults the positioner itself).
  (int, bool) getVerticalContentBoundaryRel(
      Doc doc, BoundingBox horizOverlappingBBox, bool contentTop) {
    assert(_object != null);
    return _object!.getVerticalContentBoundaryRel(doc, this, contentTop);
  }

  /// Mirrors `GetVerticalContentBoundary`.
  int getVerticalContentBoundary(
      Doc doc, BoundingBox horizOverlappingBBox, bool contentTop) {
    return getDrawingY() +
        getVerticalContentBoundaryRel(doc, horizOverlappingBBox, contentTop).$1;
  }

  /// Mirrors `HasVerticalContentOverlap`: version of
  /// `BoundingBox::VerticalContentOverlap` taking refined boundaries into
  /// account.
  bool hasVerticalContentOverlap(
      Doc doc, BoundingBox horizOverlappingBBox, int margin) {
    if (!hasContentBB() || !horizOverlappingBBox.hasContentBB()) return false;

    // Determine top/bottom for current object
    final int top = getVerticalContentBoundary(doc, horizOverlappingBBox, true);
    final int bottom =
        getVerticalContentBoundary(doc, horizOverlappingBBox, false);

    // Determine top/bottom for other (bbox) object
    int otherTop;
    int otherBottom;
    if (horizOverlappingBBox is FloatingPositioner) {
      otherTop =
          horizOverlappingBBox.getVerticalContentBoundary(doc, this, true);
      otherBottom =
          horizOverlappingBBox.getVerticalContentBoundary(doc, this, false);
    } else {
      otherTop = horizOverlappingBBox.getContentTop();
      otherBottom = horizOverlappingBBox.getContentBottom();
    }

    // Check for vertical overlap
    if (top <= otherBottom - margin) return false;
    if (bottom >= otherTop + margin) return false;
    return true;
  }
}

// ---------------------------------------------------------------------------
// FloatingCurvePositioner
// ---------------------------------------------------------------------------

/// This class is used for storing curve positioners — slurs and ties
/// (mirrors `vrv::FloatingCurvePositioner`).
class FloatingCurvePositioner extends FloatingPositioner {
  FloatingCurvePositioner(
      super.object, super.staffAlignment, super.spanningType) {
    resetCurveParams();
  }

  /// Current parameters (mirrors `m_points`, `m_thickness` and `m_dir`).
  /// Points are relative to the curve current drawingY.
  final List<Point> _points = [Point(), Point(), Point(), Point()];
  int _thickness = 0;
  CurvatureCurvedir _dir = CurvatureCurvedir.none;

  /// The cross-staff of the slur (mirrors `m_crossStaff`).
  Object? crossStaff;

  /// The spanned elements (mirrors `m_spannedElements`).
  final List<CurveSpannedElement> _spannedElements = [];

  /// The cached min or max value depending on the curvature (mirrors
  /// `m_cachedMinMaxY`).
  int _cachedMinMaxY = meiUnset;

  /// The cached values for x1 and x2 (mirrors `m_cachedX12`).
  int _cachedX1 = meiUnset;
  int _cachedX2 = meiUnset;

  /// Some curves (S-shaped slurs) can request staff space to prevent
  /// collisions from two sides (mirrors `m_requestedStaffSpace`).
  int _requestedStaffSpace = 0;

  @override
  ClassId get classId => ClassId.floatingCurvePositioner;

  @override
  void resetPositioner() {
    super.resetPositioner();
    resetCurveParams();
  }

  /// Mirrors `HasCachedX12`.
  bool hasCachedX12() => _cachedX1 != meiUnset && _cachedX2 != meiUnset;

  /// Mirrors `GetCachedX12`.
  (int, int) getCachedX12() => (_cachedX1, _cachedX2);

  /// Mirrors `SetCachedX12`.
  void setCachedX12((int, int) cachedX12) {
    _cachedX1 = cachedX12.$1;
    _cachedX2 = cachedX12.$2;
  }

  /// Mirrors `ClearSpannedElements`.
  void clearSpannedElements() {
    _spannedElements.clear();
  }

  /// Mirrors `AddSpannedElement`.
  void addSpannedElement(CurveSpannedElement spannedElement) {
    _spannedElements.add(spannedElement);
  }

  /// Mirrors `GetSpannedElements`.
  List<CurveSpannedElement> getSpannedElements() => _spannedElements;

  /// Mirrors `IsCrossStaff`.
  bool isCrossStaff() => crossStaff != null;

  /// Mirrors `SetCrossStaff`.
  void setCrossStaff(Object? crossStaff) => this.crossStaff = crossStaff;

  /// Mirrors `GetRequestedStaffSpace` / `SetRequestedStaffSpace`.
  int getRequestedStaffSpace() => _requestedStaffSpace;
  void setRequestedStaffSpace(int space) => _requestedStaffSpace = space;

  /// Mirrors `ResetCurveParams`.
  void resetCurveParams() {
    for (int i = 0; i < 4; ++i) {
      _points[i] = Point(0, 0);
    }
    _thickness = 0;
    _dir = CurvatureCurvedir.none;
    crossStaff = null;
    _cachedMinMaxY = meiUnset;
    _cachedX1 = meiUnset;
    _cachedX2 = meiUnset;
    _requestedStaffSpace = 0;
    clearSpannedElements();
  }

  /// Mirrors `UpdateCurveParams`. Stored points are made relative to the
  /// curve drawingY.
  void updateCurveParams(
      List<Point> points, int thickness, CurvatureCurvedir curveDir) {
    assert(points.length == 4);
    final int currentY = getDrawingY();
    for (int i = 0; i < 4; ++i) {
      _points[i] = Point(points[i].x, points[i].y - currentY);
    }
    _thickness = thickness;
    _dir = curveDir;
    _cachedMinMaxY = meiUnset;
  }

  /// Mirrors `UpdatePoints`.
  void updatePoints(BezierCurve bezier) {
    final List<Point> points = [bezier.p1, bezier.c1, bezier.c2, bezier.p2];
    updateCurveParams(points, _thickness, _dir);
  }

  /// Mirrors `MoveFrontHorizontal`.
  void moveFrontHorizontal(int distance) {
    _points[0].x += distance;
    _points[1].x += distance;
  }

  /// Mirrors `MoveBackHorizontal`.
  void moveBackHorizontal(int distance) {
    _points[2].x += distance;
    _points[3].x += distance;
  }

  /// Mirrors `MoveFrontVertical`.
  void moveFrontVertical(int distance) {
    _points[0].y += distance;
    _points[1].y += distance;
  }

  /// Mirrors `MoveBackVertical`.
  void moveBackVertical(int distance) {
    _points[2].y += distance;
    _points[3].y += distance;
  }

  /// Mirrors `GetPoints`: absolute points (the stored ones are relative to
  /// the curve drawingY).
  List<Point> getPoints() {
    final int currentY = getDrawingY();
    return [
      Point(_points[0].x, _points[0].y + currentY),
      Point(_points[1].x, _points[1].y + currentY),
      Point(_points[2].x, _points[2].y + currentY),
      Point(_points[3].x, _points[3].y + currentY),
    ];
  }

  /// Mirrors `GetThickness`.
  int getThickness() => _thickness;

  /// Mirrors `GetDir`.
  CurvatureCurvedir getDir() => _dir;

  /// Mirrors `CalcMinMaxY`: calculate the min or max Y for a set of points.
  int calcMinMaxY(List<Point> points) {
    assert(getObject() != null);
    assert(getObject()!.isAny(const {
      ClassId.lv,
      ClassId.phrase,
      ClassId.slur,
      ClassId.tie,
    }));
    assert(_dir != CurvatureCurvedir.none);

    if (_cachedMinMaxY != meiUnset) return _cachedMinMaxY;
    final (_, _, _, int minYPos, int maxYPos) =
        BoundingBox.approximateBezierBoundingBox(points);
    _cachedMinMaxY = (_dir == CurvatureCurvedir.above) ? maxYPos : minYPos;

    return _cachedMinMaxY;
  }

  /// Mirrors `CalcAdjustment`: calculate the adjustment needed for an element
  /// so the curve avoids it. [discard] will hold true if the element already
  /// fits.
  int calcAdjustment(BoundingBox boundingBox, Discard discard,
      {int margin = 0, bool horizontalOverlap = true}) {
    final (int leftAdjustment, int rightAdjustment) = calcLeftRightAdjustment(
        boundingBox, discard,
        margin: margin, horizontalOverlap: horizontalOverlap);
    return math.max(leftAdjustment, rightAdjustment);
  }

  /// Mirrors `CalcDirectionalAdjustment`.
  int calcDirectionalAdjustment(
      BoundingBox boundingBox, bool isCurveAbove, Discard discard,
      {int margin = 0, bool horizontalOverlap = true}) {
    final (int leftAdjustment, int rightAdjustment) =
        calcDirectionalLeftRightAdjustment(boundingBox, isCurveAbove, discard,
            margin: margin, horizontalOverlap: horizontalOverlap);
    return math.max(leftAdjustment, rightAdjustment);
  }

  /// Mirrors `CalcLeftRightAdjustment`.
  (int, int) calcLeftRightAdjustment(BoundingBox boundingBox, Discard discard,
      {int margin = 0, bool horizontalOverlap = true}) {
    return calcDirectionalLeftRightAdjustment(
        boundingBox, getDir() == CurvatureCurvedir.above, discard,
        margin: margin, horizontalOverlap: horizontalOverlap);
  }

  /// Mirrors `CalcDirectionalLeftRightAdjustment`: returns the adjustments on
  /// the left and right hand side of the bounding box.
  (int, int) calcDirectionalLeftRightAdjustment(
      BoundingBox boundingBox, bool isCurveAbove, Discard discard,
      {int margin = 0, bool horizontalOverlap = true}) {
    assert(boundingBox.hasSelfBB());

    final List<Point> points = getPoints();

    // for lisability
    final Point p1 = points[0];
    final Point p2 = points[3];

    const Accessor type = Accessor.self;
    discard.value = false;

    // first check if they overlap at all
    if (horizontalOverlap) {
      if (p2.x < boundingBox.getLeftBy(type) - margin) return (0, 0);
      if (p1.x > boundingBox.getRightBy(type) + margin) return (0, 0);
    }

    final List<Point> topBezier = [Point(), Point(), Point(), Point()];
    final List<Point> bottomBezier = [Point(), Point(), Point(), Point()];
    BoundingBox.calcThickBezier(
        points, getThickness(), topBezier, bottomBezier);

    // Now calculate the left and right adjustments
    int leftAdjustment = 0;
    int rightAdjustment = 0;

    if (isCurveAbove) {
      int leftY = 0;
      int rightY = 0;
      // The curve overflows on both sides
      if ((p1.x < boundingBox.getLeftBy(type)) &&
          p2.x > boundingBox.getRightBy(type)) {
        // calculate the y positions
        leftY = BoundingBox.calcBezierAtPosition(
                bottomBezier, boundingBox.getLeftBy(type)) -
            margin;
        rightY = BoundingBox.calcBezierAtPosition(
                bottomBezier, boundingBox.getRightBy(type)) -
            margin;
      }
      // The curve overflows on the left
      else if ((p1.x < boundingBox.getLeftBy(type)) &&
          p2.x <= boundingBox.getRightBy(type)) {
        leftY = BoundingBox.calcBezierAtPosition(
                bottomBezier, boundingBox.getLeftBy(type)) -
            margin;
        rightY = p2.y - margin;
      }
      // The curve overflows on the right
      else if ((p1.x >= boundingBox.getLeftBy(type)) &&
          p2.x > boundingBox.getRightBy(type)) {
        leftY = p1.y - margin;
        rightY = BoundingBox.calcBezierAtPosition(
                bottomBezier, boundingBox.getRightBy(type)) -
            margin;
      }
      // The curve is inside the left and right side of the content
      else {
        leftY = p1.y - margin;
        rightY = p2.y - margin;
      }

      // For selected types use the cut out boundary
      // Deviation: the SMuFL cut-out anchors arrive with the resources
      // phase; the plain top is used for accidentals as well.
      final int boxTopY = boundingBox.getTopBy(type);

      leftAdjustment = math.max(boxTopY - leftY, 0);
      rightAdjustment = math.max(boxTopY - rightY, 0);
    } else {
      int leftY = 0;
      int rightY = 0;
      // The curve overflows on both sides
      if ((p1.x < boundingBox.getLeftBy(type)) &&
          p2.x > boundingBox.getRightBy(type)) {
        // calculate the y positions
        leftY = BoundingBox.calcBezierAtPosition(
                topBezier, boundingBox.getLeftBy(type)) +
            margin;
        rightY = BoundingBox.calcBezierAtPosition(
                topBezier, boundingBox.getRightBy(type)) +
            margin;
      }
      // The curve overflows on the left
      else if ((p1.x < boundingBox.getLeftBy(type)) &&
          p2.x <= boundingBox.getRightBy(type)) {
        leftY = BoundingBox.calcBezierAtPosition(
                topBezier, boundingBox.getLeftBy(type)) +
            margin;
        rightY = p2.y + margin;
      }
      // The curve overflows on the right
      else if ((p1.x >= boundingBox.getLeftBy(type)) &&
          p2.x > boundingBox.getRightBy(type)) {
        leftY = p1.y + margin;
        rightY = BoundingBox.calcBezierAtPosition(
                topBezier, boundingBox.getRightBy(type)) +
            margin;
      }
      // The curve is inside the left and right side of the content
      else {
        leftY = p1.y + margin;
        rightY = p2.y + margin;
      }

      // For selected types use the cut out boundary (see above deviation).
      final int boxBottomY = boundingBox.getBottomBy(type);

      leftAdjustment = math.max(leftY - boxBottomY, 0);
      rightAdjustment = math.max(rightY - boxBottomY, 0);
    }

    if ((leftAdjustment == 0) && (rightAdjustment == 0)) {
      // Everything is above or below - we can discard the element
      discard.value = true;
    }

    return (leftAdjustment, rightAdjustment);
  }

  /// Mirrors `CalcRequestedStaffSpace`: calculate the requested staff space
  /// above and below for cross-staff curves.
  (int, int) calcRequestedStaffSpace(StaffAlignment alignment) {
    // Dynamic access to the TimeSpanningInterface of the object (slur, tie…).
    final dynamic spanning = getObject() as dynamic;
    final Object? start = spanning.getStart() as Object?;
    final Object? end = spanning.getEnd() as Object?;
    final Staff? startStaff = _resolveCrossStaff(start);
    final Staff? endStaff = _resolveCrossStaff(end);

    if (startStaff != null && endStaff != null) {
      final int startStaffN = startStaff.n ?? meiUnset;
      final int endStaffN = endStaff.n ?? meiUnset;
      if (startStaffN != endStaffN) {
        final int alignmentStaffN = alignment.getStaff()?.n ?? meiUnset;
        if (alignmentStaffN == math.min(startStaffN, endStaffN)) {
          return (0, _requestedStaffSpace);
        }
        if (alignmentStaffN == math.max(startStaffN, endStaffN)) {
          return (_requestedStaffSpace, 0);
        }
      }
    }

    return (0, 0);
  }

  /// Resolve the ancestor staff of a boundary element taking the cross-staff
  /// into account (mirrors `GetAncestorStaff(RESOLVE_CROSS_STAFF, false)`).
  static Staff? _resolveCrossStaff(Object? element) {
    if (element == null) return null;
    final dynamic cross = (element as dynamic).crossStaff;
    if (cross is Staff) return cross;
    final Object? staff = element.getFirstAncestor(ClassId.staff);
    return staff is Staff ? staff : null;
  }
}

// ---------------------------------------------------------------------------
// Curve / rectangle intersections (boundingbox.cpp fragments)
// ---------------------------------------------------------------------------

extension CurveIntersection on BoundingBox {
  /// Mirrors `BoundingBox::Intersects(const FloatingCurvePositioner *, …)`:
  /// calculate the vertical shift needed so that `this` bounding box avoids
  /// the curve.
  int intersectsCurve(
      FloatingCurvePositioner curve, Accessor type, int margin) {
    assert(curve.getObject() != null);
    assert(curve
        .getObject()!
        .isAny(const {ClassId.lv, ClassId.phrase, ClassId.slur, ClassId.tie}));

    // for readability
    final List<Point> points = curve.getPoints();
    final Point p1 = points[0];
    final Point p2 = points[3];

    // first check if they overlap at all
    if (p2.x < getLeftBy(type)) return 0;
    if (p1.x > getRightBy(type)) return 0;

    final List<Point> topBezier = [Point(), Point(), Point(), Point()];
    final List<Point> bottomBezier = [Point(), Point(), Point(), Point()];
    BoundingBox.calcThickBezier(
        points, curve.getThickness(), topBezier, bottomBezier);

    // The curve overflows on both sides
    if ((p1.x < getLeftBy(type)) && p2.x > getRightBy(type)) {
      if (curve.getDir() == CurvatureCurvedir.above) {
        // The curve is already below the content
        if ((curve.getTopBy(type) + margin) < getBottomBy(type)) return 0;
        final int xMaxY = curve.calcMinMaxY(topBezier);
        int leftY =
            BoundingBox.calcBezierAtPosition(bottomBezier, getLeftBy(type)) +
                margin;
        int rightY =
            BoundingBox.calcBezierAtPosition(bottomBezier, getRightBy(type)) +
                margin;
        // Everything is underneath
        if ((leftY >= getTopBy(type)) && (rightY >= getTopBy(type))) return 0;
        // Recalculate for above
        leftY = BoundingBox.calcBezierAtPosition(topBezier, getLeftBy(type)) +
            margin;
        rightY = BoundingBox.calcBezierAtPosition(topBezier, getRightBy(type)) +
            margin;
        // The box is above the summit of the curve
        if ((getLeftBy(type) < (p1.x + xMaxY)) &&
            (getRightBy(type) > (p1.x + xMaxY))) {
          return (curve.getTopBy(type) - getBottomBy(type) + margin);
        }
        // The content is on the left
        return (getRightBy(type) < (p1.x + xMaxY))
            ? (rightY - getBottomBy(type))
            : (leftY - getBottomBy(type));
      } else {
        // The curve is already above the content
        if ((curve.getBottomBy(type) - margin) > getTopBy(type)) return 0;
        final int xMinY = curve.calcMinMaxY(bottomBezier);
        // Check if the box is above
        int leftY =
            BoundingBox.calcBezierAtPosition(topBezier, getLeftBy(type)) -
                margin;
        int rightY =
            BoundingBox.calcBezierAtPosition(topBezier, getRightBy(type)) -
                margin;
        if ((leftY <= getBottomBy(type)) && (rightY <= getBottomBy(type))) {
          return 0;
        }
        // Recalculate for below
        leftY =
            BoundingBox.calcBezierAtPosition(bottomBezier, getLeftBy(type)) -
                margin;
        rightY =
            BoundingBox.calcBezierAtPosition(bottomBezier, getRightBy(type)) -
                margin;
        // The box is above the summit of the curve
        if ((getLeftBy(type) < (p1.x + xMinY)) &&
            (getRightBy(type) > (p1.x + xMinY))) {
          return (curve.getBottomBy(type) - getTopBy(type) - margin);
        }
        // The content is on the left
        return (getRightBy(type) < (p1.x + xMinY))
            ? (rightY - getTopBy(type))
            : (leftY - getTopBy(type));
      }
    }
    // The curve overflows on the left
    else if ((p1.x < getLeftBy(type)) && p2.x <= getRightBy(type)) {
      if (curve.getDir() == CurvatureCurvedir.above) {
        final int xMaxY = curve.calcMinMaxY(topBezier);
        // The starting point is above the top
        if (p2.y > getTopBy(type) + margin) return 0;
        // The left point is beyond (before) the summit of the curve
        if (getLeftBy(type) < (p1.x + xMaxY)) {
          return (curve.getTopBy(type) - getBottomBy(type) + margin);
        }
        // Calculate the Y position of the curve on the left
        final int leftY =
            BoundingBox.calcBezierAtPosition(topBezier, getLeftBy(type)) +
                margin;
        // The content left is below the bottom
        if (leftY < getBottomBy(type)) return 0;
        // Else return the shift needed
        return (leftY - getBottomBy(type));
      } else {
        final int xMinY = curve.calcMinMaxY(topBezier);
        // The starting point is below the bottom
        if (p2.y < getBottomBy(type) + margin) return 0;
        // The left point is beyond (before) the summit of the curve
        if (getLeftBy(type) < (p1.x + xMinY)) {
          return (curve.getBottomBy(type) - getTopBy(type) - margin);
        }
        // Calculate the Y position of the curve on the left
        final int leftY =
            BoundingBox.calcBezierAtPosition(bottomBezier, getLeftBy(type)) -
                margin;
        // The content left is above the top
        if (leftY > getTopBy(type)) return 0;
        // Else return the shift needed
        return (leftY - getTopBy(type));
      }
    }
    // The curve overflows on the right
    else if ((p1.x >= getLeftBy(type)) && p2.x > getRightBy(type)) {
      if (curve.getDir() == CurvatureCurvedir.above) {
        final int xMaxY = curve.calcMinMaxY(topBezier);
        // The starting point is above the top
        if (p1.y > getTopBy(type) + margin) return 0;
        // The right point is beyond the summit of the curve
        if (getRightBy(type) > (p1.x + xMaxY)) {
          return (curve.getTopBy(type) - getBottomBy(type) + margin);
        }
        // Calculate the Y position of the curve on the right
        final int rightY =
            BoundingBox.calcBezierAtPosition(topBezier, getRightBy(type)) +
                margin;
        // The content right is below the bottom
        if (rightY < getBottomBy(type)) return 0;
        // Return the shift needed
        return (rightY - getBottomBy(type));
      } else {
        final int xMinY = curve.calcMinMaxY(bottomBezier);
        // The starting point is below the bottom
        if (p1.y < getBottomBy(type) + margin) return 0;
        // The right point is beyond the summit of the curve
        if (getRightBy(type) > (p1.x + xMinY)) {
          return (curve.getBottomBy(type) - getTopBy(type) - margin);
        }
        // Calculate the Y position of the curve on the right
        final int rightY =
            BoundingBox.calcBezierAtPosition(bottomBezier, getRightBy(type)) -
                margin;
        // The content right is above the top
        if (rightY > getTopBy(type)) return 0;
        // Return the shift needed
        return (rightY - getTopBy(type));
      }
    }
    // The curve is inside the left and right side of the content
    else if ((p1.x >= getLeftBy(type)) && p2.x <= getRightBy(type)) {
      if (curve.getDir() == CurvatureCurvedir.above) {
        return (curve.getTopBy(type) - getBottomBy(type) + margin);
      } else {
        return (curve.getBottomBy(type) - getTopBy(type) - margin);
      }
    }

    return 0;
  }

  /// Plain rectangle based vertical overlap (used for the beam special case;
  /// see the library deviations note). Returns the shift needed to avoid the
  /// rectangle, preferring the smaller displacement.
  int intersectsRectangle(BoundingBox other, int margin) {
    if (!hasContentBB() || !other.hasSelfBB()) return 0;
    if (!horizontalContentOverlap(other)) return 0;
    final int top = getContentTop();
    final int bottom = getContentBottom();
    if (top <= other.getSelfBottom() - margin) return 0;
    if (bottom >= other.getSelfTop() + margin) return 0;
    // Shift upwards when the box sits above the obstacle, downwards otherwise
    final int upShift = top - other.getSelfBottom() + margin;
    final int downShift = other.getSelfTop() - bottom + margin;
    return (upShift.abs() <= downShift.abs()) ? upShift : downShift;
  }
}
