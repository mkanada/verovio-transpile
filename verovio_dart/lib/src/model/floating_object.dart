/// Port of `floatingobject.h/cpp` — base class for floating objects
/// (control elements and system elements drawn between staves).
library;

import 'package:verovio_dart/src/core/bounding_box.dart' show BoundingBox;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show FloatingPositioner;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Staffrel;
import 'package:verovio_dart/src/model/object.dart';

/// Mirrors `vrv::FloatingObject`.
class FloatingObject extends Object {
  FloatingObject([ClassId classId = ClassId.floatingObject]) {
    _init(classId);
  }

  void _init(ClassId classId) {
    assignClassId(classId);
    reset();
  }

  @override
  String get className => '[MISSING]';

  /// The drawing group id for linking floating elements horizontally.
  int drawingGrpId = 0;

  /// The object used as group reference when no numeric id is available
  /// (mirrors `m_drawingGrpObject`).
  Object? drawingGrpObject;

  /// Maximum drawing yRel persistent across the object's floating
  /// positioners (VRV_UNSET when unset).
  int maxDrawingYRel = -0x7FFFFFFF;

  /// The current positioner while the object is drawn or adjusted
  /// (mirrors `m_currentPositioner`).
  FloatingPositioner? currentPositioner;

  @override
  void reset() {
    super.reset();
    resetDrawing();
  }

  /// Reset the drawing values only (mirrors `ResetDrawing`).
  void resetDrawing() {
    drawingGrpId = 0;
    drawingGrpObject = null;
    maxDrawingYRel = -0x7FFFFFFF;
    drawingXRel = 0;
    drawingYRel = 0;
    currentPositioner = null;
  }

  /// Mirrors `SetDrawingGrpObject` / `GetDrawingGrpObject`.
  void setDrawingGrpObject(Object object) => drawingGrpObject = object;
  Object? getDrawingGrpObject() => drawingGrpObject;

  // -------------------------------------------------------------------------
  // Current positioner wiring (mirrors floatingobject.cpp)
  // -------------------------------------------------------------------------

  /// Mirrors `SetCurrentFloatingPositioner`.
  void setCurrentFloatingPositioner(FloatingPositioner? boundingBox) {
    currentPositioner = boundingBox;
  }

  /// Mirrors `GetCurrentFloatingPositioner`.
  FloatingPositioner? getCurrentFloatingPositioner() => currentPositioner;

  /// Mirrors `GetCorrespFloatingPositioner`: look for the positioner of
  /// [object] on the same staff alignment as the current one; null when
  /// there is no current positioner or nothing is found.
  FloatingPositioner? getCorrespFloatingPositioner(FloatingObject? object) {
    if (object == null || currentPositioner == null) return null;
    return currentPositioner!
        .getStaffAlignment()!
        .getCorrespFloatingPositioner(object);
  }

  /// Mirrors `SetMaxDrawingYRel`: above keeps the minimum, below the maximum.
  void setMaxDrawingYRel(int maxDrawingYRel, Staffrel place) {
    if (place == Staffrel.above) {
      if ((this.maxDrawingYRel == -0x7FFFFFFF) ||
          (this.maxDrawingYRel > maxDrawingYRel)) {
        this.maxDrawingYRel = maxDrawingYRel;
      }
    } else {
      if ((this.maxDrawingYRel == -0x7FFFFFFF) ||
          (this.maxDrawingYRel < maxDrawingYRel)) {
        this.maxDrawingYRel = maxDrawingYRel;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Bounding box forwarding to the current positioner
  // -------------------------------------------------------------------------

  @override
  void updateContentBBoxX(int x1, int x2) {
    final positioner = currentPositioner;
    if (positioner == null) return;
    positioner.updateContentBBoxX(x1, x2);
  }

  @override
  void updateContentBBoxY(int y1, int y2) {
    final positioner = currentPositioner;
    if (positioner == null) return;
    positioner.updateContentBBoxY(y1, y2);
  }

  @override
  void updateSelfBBoxX(int x1, int x2) {
    final positioner = currentPositioner;
    if (positioner == null) return;
    positioner.updateSelfBBoxX(x1, x2);
  }

  @override
  void updateSelfBBoxY(int y1, int y2) {
    final positioner = currentPositioner;
    if (positioner == null) return;
    positioner.updateSelfBBoxY(y1, y2);
  }

  /// Mirrors `GetVerticalContentBoundaryRel` (the base implementation from
  /// floatingobject.cpp): the plain content boundary of the positioner.
  ///
  /// [doc] stays untyped to avoid an import cycle with the Doc class.
  (int, bool) getVerticalContentBoundaryRel(
      dynamic doc, BoundingBox positionerAsBox, bool contentTop) {
    final FloatingPositioner positioner = positionerAsBox as FloatingPositioner;
    final int boundary =
        contentTop ? positioner.getContentY2() : positioner.getContentY1();
    return (boundary, false);
  }

  // -------------------------------------------------------------------------
  // Drawing positions
  // -------------------------------------------------------------------------

  /// The drawing X/Y relative offsets (kept for objects without a positioner;
  /// mirrors the C++ behaviour where the values are only used through the
  /// current positioner once it exists).
  int drawingXRel = 0;
  int drawingYRel = 0;

  /// Mirrors `FloatingObject::GetDrawingX`: the positioner x; 0 without one.
  @override
  int getDrawingX() {
    final positioner = currentPositioner;
    if (positioner == null) return 0;
    return positioner.getDrawingX();
  }

  /// Mirrors `FloatingObject::GetDrawingY`: the positioner y; 0 without one.
  @override
  int getDrawingY() {
    final positioner = currentPositioner;
    if (positioner == null) return 0;
    return positioner.getDrawingY();
  }

  /// Check whether the current object represents extender lines.
  bool get isExtenderElement => false;

  /// Determine whether this object must be positioned closer to the staff
  /// than [other] for the given place.
  bool isCloserToStaffThan(FloatingObject other, dynamic place) => false;

  @override
  void copyFrom(covariant FloatingObject other) {
    super.copyFrom(other);
    // Drawing values (mirrors the C++ implicit copy constructor); the
    // current positioner is not copied.
    drawingGrpId = other.drawingGrpId;
    maxDrawingYRel = other.maxDrawingYRel;
    drawingXRel = other.drawingXRel;
    drawingYRel = other.drawingYRel;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    logDebug('Method for adding $classId to $className should be overridden');
    return false;
  }
}
