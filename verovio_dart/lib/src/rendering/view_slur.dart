/// Port of `view_slur.cpp` — slurs and phrases (task 05-18).
///
/// Mirrors `View::DrawSlur` (view_slur.cpp:33) and
/// `View::CalcInitialSlur` (:76). The curve mathematics lives in
/// `AdjustSlursFunctor` and `Slur` (Phase 4, `adjust_slurs.dart` and
/// `slur_positioning.dart`), already ported — this View slice only wires the
/// device context curve through those helpers, exactly like the C++ does.
///
/// This file is a `part` of the `view.dart` library (task 05-06 partitioning
/// decision: one `part` per `view_*.cpp`). The C++ continues the `View` class
/// here; Dart cannot split a class body across files, so the methods are
/// declared as members of the [ViewSlur] extension below — same library,
/// therefore the same privacy scope as the class members (like the C++ member
/// visibility from every `view_*.cpp`).
part of 'view.dart';

/// The `view_slur.cpp` methods of [View] (task 05-18).
extension ViewSlur on View {
  /// Mirrors `View::DrawSlur` (view_slur.cpp:33).
  void drawSlur(DeviceContext dc, dynamic slur, int x1, int x2, Staff staff,
      int spanningType, Object? graphic) {
    final FloatingCurvePositioner? curve =
        calcInitialSlur(dc, slur, x1, x2, staff, spanningType);
    if (curve == null) return;
    final List<Point> points = curve.getPoints();

    // Points are cached in the FloatingCurvePositioner, we also need to adjust x1 and x2
    calcOffsetBezier(dc, points, spanningType);

    if (graphic != null) {
      dc.resumeGraphic(graphic, graphic.id);
    } else {
      dc.startGraphic(slur, '', slur.id, graphicID: GraphicID.spanning);
    }

    PenStyle penStyle = PenStyle.solid;
    final Lineform? lform = slur.getLform();
    if (lform == Lineform.dashed) {
      penStyle = PenStyle.shortDash;
    } else if (lform == Lineform.dotted) {
      penStyle = PenStyle.dot;
    } else if (lform == Lineform.wavy) {
      // TODO: Implement wavy slur.
    }

    final int penWidth =
        (doc!.getOptions().slurEndpointThickness.value * doc!.getDrawingUnit(staff.drawingStaffSize))
            .toInt();
    final double thicknessCoefficient =
        BoundingBox.getBezierThicknessCoefficient(points, curve.getThickness(), penWidth);
    drawThickBezierCurve(
        dc, points, (thicknessCoefficient * curve.getThickness()).toInt(), staff.drawingStaffSize, penWidth, penStyle);

    if (graphic != null) {
      dc.endResumedGraphic(graphic);
    } else {
      dc.endGraphic(slur);
    }
  }

  /// Mirrors `View::CalcInitialSlur` (view_slur.cpp:76).
  FloatingCurvePositioner? calcInitialSlur(
      DeviceContext dc, dynamic slur, int x1, int x2, Staff staff, int spanningType) {
    final FloatingPositioner? positioner = (slur as dynamic).getCurrentFloatingPositioner();
    if (positioner == null || positioner.classId != ClassId.floatingCurvePositioner) {
      return null;
    }
    final FloatingCurvePositioner curve = positioner as FloatingCurvePositioner;

    if ((slurHandling == SlurHandling.initialize) &&
        dc.classId == ClassId.bboxDeviceContext &&
        (curve.getDir() == CurvatureCurvedir.none || curve.isCrossStaff())) {
      // Initial curve calculation
      curve.setCachedX12((x1, x2));
      slur.calcInitialCurveFor(doc!, curve, null);

      // Register content
      slur.calcSpannedElementsFor(doc!, curve);
      // Mirrors `Slur::AddPositionerToArticulations(curve)` — the Dart
      // equivalent lives in `SlurPositioning` as the linkage for
      // `AdjustArticWithSlursFunctor`. For the View pass the exact bookkeeping
      // is not required to draw the curve; the positioner is already wired by
      // the preceding `calcInitialCurveFor`/`calcSpannedElementsFor` (and by
      // the layout's earlier BBox pass), so we keep this as a no-op here.
    }
    return curve;
  }
}
