/// Port of `bboxdevicecontext.h/cpp` — a device context that only computes
/// bounding boxes (no drawing).
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/rendering/device_context.dart';
import 'package:verovio_dart/src/rendering/glyph.dart';
import 'package:verovio_dart/src/rendering/resources.dart';

/// Signature of the logical-coordinate transforms usually provided by the
/// `View` in the C++ code (`View::ToLogicalX/Y`). The View class itself is
/// ported with the rendering phase.
typedef LogicalTransform = int Function(int x);

/// This class computes bounding boxes instead of drawing
/// (mirrors `vrv::BBoxDeviceContext`).
class BBoxDeviceContext extends DeviceContext {
  /// Mirrors the `BBoxDeviceContext(View *view, int width, int height,
  /// unsigned char update = BBOX_BOTH)` constructor (bboxdevicecontext.cpp:27).
  ///
  /// Deviations from the C++:
  /// - the `View*` parameter is replaced by the [LogicalTransform] functions
  ///   the View will provide (`ToLogicalX`/`ToLogicalY`); the `View` class is
  ///   ported with the rendering phase (task 05-06).
  BBoxDeviceContext(
      {required LogicalTransform toLogicalX,
      required LogicalTransform toLogicalY,
      int width = 0,
      int height = 0,
      this.update = BBOX_BOTH})
      : _toLogicalX = toLogicalX,
        _toLogicalY = toLogicalY {
    this.width = width;
    this.height = height;

    userScaleX = 1.0;
    userScaleY = 1.0;

    drawingText = false;
    textAlignment = HorizontalAlignment.left;

    resetGraphicRotation();
  }

  final LogicalTransform _toLogicalX;
  final LogicalTransform _toLogicalY;

  @override
  ClassId get classId => ClassId.bboxDeviceContext;

  /// The update mode passed at construction (mirrors `m_update`,
  /// bboxdevicecontext.h:182; private in the C++, exposed here because the
  /// layout passes construct the context with the `BBOX_*` mode and
  /// [updateHorizontalValues]/[updateVerticalValues] consume it).
  int update;

  /// Mirrors `UpdateHorizontalValues()` (bboxdevicecontext.h:147).
  bool updateHorizontalValues() => update != BBOX_VERTICAL_ONLY;

  /// Mirrors `UpdateVerticalValues()` (bboxdevicecontext.h:148).
  bool updateVerticalValues() => update != BBOX_HORIZONTAL_ONLY;

  /// The stack of objects being drawn.
  final List<BoundingBox> objects = [];

  double rotationAngle = 0.0;
  Point rotationOrigin = Point(0, 0);

  bool drawingText = false;
  int textX = 0;
  int textY = 0;
  int textWidth = 0;
  int textHeight = 0;
  int textAscent = 0;
  int textDescent = 0;
  HorizontalAlignment textAlignment = HorizontalAlignment.left;

  void resetGraphicRotation() {
    rotationAngle = 0.0;
    rotationOrigin.x = 0;
    rotationOrigin.y = 0;
  }

  // -------------------------------------------------------------------------
  // Graphic lifecycle
  // -------------------------------------------------------------------------

  @override
  void startGraphic(BoundingBox object, String gClass, String gId,
      {GraphicID graphicID = GraphicID.primary, bool prepend = false}) {
    object.resetBoundingBox();
    objects.add(object);

    resetGraphicRotation();
  }

  @override
  void resumeGraphic(BoundingBox object, String gId) {
    objects.add(object);
  }

  @override
  void endGraphic(BoundingBox object) {
    assert(identical(objects.last, object));
    objects.removeLast();

    resetGraphicRotation();
  }

  @override
  void endResumedGraphic(BoundingBox object) {
    assert(identical(objects.last, object));
    objects.removeLast();

    resetGraphicRotation();
  }

  @override
  void rotateGraphic(Point orig, double angle) {
    assert(_approximatelyEqual(rotationAngle, 0.0));

    rotationAngle = angle;
    rotationOrigin = orig;
  }

  @override
  void startPage() {}

  @override
  void endPage() {}

  @override
  void drawBackgroundImage([int x = 0, int y = 0]) {
    // Nothing to do — we do not handle background images.
  }

  // -------------------------------------------------------------------------
  // Background / origin
  // -------------------------------------------------------------------------

  @override
  void setBackground(int color, [int style = 0]) {
    // Nothing to do — we do not handle background.
  }

  @override
  void setBackgroundMode(int mode) {
    // Nothing to do — we do not handle background mode.
  }

  @override
  void setTextForeground(int color) {}

  @override
  void setTextBackground(int color) {
    // Nothing to do — we do not handle text background.
  }

  @override
  void setLogicalOrigin(int x, int y) {}

  /// Mirrors `BBoxDeviceContext::SetUserScale` (bboxdevicecontext.cpp:111):
  /// the C++ hides the non-virtual base setter with an identical body
  /// ("no idea how to handle this with the BB").
  @override
  void setUserScale(double xScale, double yScale) {
    userScaleX = xScale;
    userScaleY = yScale;
  }

  @override
  void setBackgroundImage(Object? image, [double opacity = 1.0]) {}

  @override
  Point getLogicalOrigin() => Point(0, 0);

  // -------------------------------------------------------------------------
  // Drawing methods (bounding box updates only)
  // -------------------------------------------------------------------------

  /// Calculated analytically (mirrors `DrawQuadBezierPath`).
  @override
  void drawQuadBezierPath(List<Point> bezier) {
    Point pMin = Point.min(bezier[0], bezier[2]);
    Point pMax = Point.max(bezier[0], bezier[2]);

    // From https://iquilezles.org/www/articles/bezierbbox/bezierbbox.htm
    if ((bezier[1].x < pMin.x) ||
        (bezier[1].x > pMax.x) ||
        (bezier[1].y < pMin.y) ||
        (bezier[1].y > pMax.y)) {
      // The C++ assigns the clamped t to an `int`
      // (bboxdevicecontext.cpp:132-133), truncating it to 0 or 1 — copy the
      // arithmetic, not the intention.
      final int tx = ((bezier[0].x - bezier[1].x) /
              (bezier[0].x - 2.0 * bezier[1].x + bezier[2].x))
          .clamp(0.0, 1.0)
          .toInt();
      final int ty = ((bezier[0].y - bezier[1].y) /
              (bezier[0].y - 2.0 * bezier[1].y + bezier[2].y))
          .clamp(0.0, 1.0)
          .toInt();
      // vec2 s = 1.0 - t;
      final int sx = (1.0 - tx).toInt();
      final int sy = (1.0 - ty).toInt();
      // vec2 q = s*s*p0 + 2.0*s*t*p1 + t*t*p2;
      final int qx = (sx * sx * bezier[0].x +
              2.0 * sx * tx * bezier[1].x +
              tx * tx * bezier[2].x)
          .toInt();
      final int qy = (sy * sy * bezier[0].y +
              2.0 * sy * ty * bezier[1].y +
              ty * ty * bezier[2].y)
          .toInt();
      pMin = Point.min(pMin, Point(qx, qy));
      pMax = Point.max(pMax, Point(qx, qy));
    }

    updateBB(pMin.x, pMin.y, pMax.x, pMax.y);
  }

  @override
  void drawCubicBezierPath(List<Point> bezier) {
    final (pos, width, height, minYPos, maxYPos) =
        BoundingBox.approximateBezierBoundingBox(bezier);
    updateBB(pos.x, pos.y, pos.x + width, pos.y + height);
  }

  @override
  void drawCubicBezierPathFilled(List<Point> bezier1, List<Point> bezier2) {
    var (pos, width, height, _, _) =
        BoundingBox.approximateBezierBoundingBox(bezier1);
    updateBB(pos.x, pos.y, pos.x + width, pos.y + height);
    (pos, width, height, _, _) =
        BoundingBox.approximateBezierBoundingBox(bezier2);
    updateBB(pos.x, pos.y, pos.x + width, pos.y + height);
  }

  @override
  void drawBentParallelogramFilled(List<Point> side, int height) {
    updateBB(side[0].x, side[0].y, side[3].x, side[3].y + height);
  }

  @override
  void drawCircle(int x, int y, int radius) {
    drawEllipse(x - radius, y - radius, 2 * radius, 2 * radius);
  }

  @override
  void drawEllipse(int x, int y, int width, int height) {
    updateBB(x, y, x + width, y + height);
  }

  @override
  void drawEllipticArc(
      int x, int y, int width, int height, double start, double end) {
    final (int overlapFirst, int overlapSecond) = getPenWidthOverlap();

    // Needs to be fixed — for now uses the entire rectangle.
    updateBB(x - overlapFirst, y - overlapSecond, x + width + overlapSecond,
        y + height + overlapFirst);
  }

  @override
  void drawLine(int x1, int y1, int x2, int y2) {
    if (x1 > x2) {
      final int tmp = x1;
      x1 = x2;
      x2 = tmp;
    }
    if (y1 > y2) {
      final int tmp = y1;
      y1 = y2;
      y2 = tmp;
    }

    final (int overlapFirst, int overlapSecond) = getPenWidthOverlap();

    updateBB(x1 - overlapFirst, y1 - overlapSecond, x2 + overlapSecond,
        y2 + overlapFirst);
  }

  @override
  void drawPolyline(List<Point> points, {bool close = false}) {
    // Same bounding box as the corresponding polygon.
    drawPolygon(points);
  }

  @override
  void drawPolygon(List<Point> points) {
    if (points.isEmpty) return;

    int x1 = points[0].x;
    int x2 = x1;
    int y1 = points[0].y;
    int y2 = y1;

    for (final Point p in points) {
      x1 = math.min(x1, p.x);
      x2 = math.max(x2, p.x);
      y1 = math.min(y1, p.y);
      y2 = math.max(y2, p.y);
    }

    final (int overlapFirst, int overlapSecond) = getPenWidthOverlap();

    updateBB(x1 - overlapFirst, y1 - overlapSecond, x2 + overlapSecond,
        y2 + overlapFirst);
  }

  @override
  void drawRectangle(int x, int y, int width, int height) {
    drawRoundedRectangle(x, y, width, height, 0);
  }

  @override
  void drawRoundedRectangle(int x, int y, int width, int height, int radius) {
    // Avoid negative heights or widths.
    if (height < 0) {
      height = -height;
      y -= height;
    }
    if (width < 0) {
      width = -width;
      x -= width;
    }

    final (int overlapFirst, int overlapSecond) = getPenWidthOverlap();

    updateBB(x - overlapFirst, y - overlapSecond, x + width + overlapSecond,
        y + height + overlapFirst);
  }

  @override
  void drawPlaceholder(int x, int y) {
    updateBB(x, y, x, y);
  }

  // -------------------------------------------------------------------------
  // Text
  // -------------------------------------------------------------------------

  @override
  void startText(int x, int y,
      [HorizontalAlignment alignment = HorizontalAlignment.left]) {
    assert(!drawingText);
    drawingText = true;
    textX = x;
    textY = y;
    textWidth = 0;
    textHeight = 0;
    textAscent = 0;
    textDescent = 0;
    textAlignment = alignment;
  }

  @override
  void endText() {
    drawingText = false;
  }

  @override
  void moveTextTo(int x, int y, HorizontalAlignment alignment) {
    assert(drawingText);
    textX = x;
    textY = y;
    textWidth = 0;
    textHeight = 0;
    textAscent = 0;
    textDescent = 0;
    if (alignment != HorizontalAlignment.none_) {
      textAlignment = alignment;
    }
  }

  @override
  void moveTextVerticallyTo(int y) {
    assert(drawingText);
    // Because this is used only for smaller subscript / superscript it seems
    // better not to change the y position for the BBoxDeviceContext because
    // otherwise it moves the full bounding box — to be improved / double
    // checked.
    // textY = y;
  }

  @override
  void drawText(String text,
      {String? wtext,
      int x = meiUnset,
      int y = meiUnset,
      int width = meiUnset,
      int height = meiUnset}) {
    assert(hasFont);
    final List<int> runes = (wtext ?? text).runes.toList();

    if ((x != 0) &&
        (y != 0) &&
        (x != meiUnset) &&
        (y != meiUnset) &&
        (width != 0) &&
        (height != 0) &&
        (width != meiUnset) &&
        (height != meiUnset)) {
      textX = x;
      textY = y;
      textWidth = width;
      textHeight = height;
      textAscent = 0;
      textDescent = 0;
      updateBB(textX, textY, textX + textWidth, textY + textHeight);
    } else {
      if ((x != meiUnset) && (y != meiUnset)) {
        textX = x;
        textY = y;
        textWidth = 0;
        textHeight = 0;
        textAscent = 0;
        textDescent = 0;
      }

      final TextExtend extend = TextExtend();
      if (font.smuflFont != SmuflTextFont.none) {
        getSmuflTextExtentUtf32(runes, extend);
      } else {
        getTextExtentUtf32(runes, extend, typeSize: true);
      }
      textWidth += extend.width;
      // Keep the maximum values for ascent and descent.
      textAscent = math.max(textAscent, extend.ascent);
      textDescent = math.max(textDescent, extend.descent);
      textHeight = textAscent + textDescent;
      if (textAlignment == HorizontalAlignment.right) {
        textX -= extend.width;
      } else if (textAlignment == HorizontalAlignment.center) {
        textX -= extend.width ~/ 2;
      }
      updateBB(
          textX, textY + textDescent, textX + textWidth, textY - textAscent);
    }
  }

  /// Mirrors `BBoxDeviceContext::DrawRotatedText` (bboxdevicecontext.cpp:349):
  /// the C++ body is empty (left unimplemented there), so rotated text does
  /// not contribute to the bounding boxes in this device context either.
  @override
  void drawRotatedText(String text, int x, int y, double angle) {}

  @override
  void drawMusicText(String text, int x, int y, {bool setSmuflGlyph = false}) {
    assert(hasFont);

    final Resources? res = getResources();
    assert(res != null);

    int lastCharWidth = 0;

    final List<int> runes = text.runes.toList();
    int smuflGlyph = 0;
    if (setSmuflGlyph && runes.length == 1) smuflGlyph = runes[0];

    for (final int c in runes) {
      final Glyph? glyph = res!.getGlyphByCode(c);
      if (glyph == null) continue;
      final (int gX, int gY, int gW, int gH) = glyph.getBoundingBox();
      final int advX = glyph.horizAdvX;

      final int xOff = x + (gX * font.pointSize) ~/ glyph.unitsPerEm;
      // Because we are in the drawing context, the y position is already
      // flipped.
      final int yOff = y - (gY * font.pointSize) ~/ glyph.unitsPerEm;

      updateBB(
          xOff,
          yOff,
          xOff + (gW * font.pointSize) ~/ glyph.unitsPerEm,
          // Idem, the y position is flipped.
          yOff - (gH * font.pointSize) ~/ glyph.unitsPerEm,
          smuflGlyph);

      lastCharWidth = (advX * font.pointSize) ~/ glyph.unitsPerEm;
      x += lastCharWidth; // Move x to the next char.
    }
  }

  @override
  void drawSpline(List<Point> points) {}

  @override
  void drawGraphicUri(int x, int y, int width, int height, String uri) {
    drawRoundedRectangle(x, y, width, height, 0);
  }

  @override
  void drawSvgShape(
      int x, int y, int width, int height, double scale, String svg) {
    drawRoundedRectangle(x, y, width, height, 0);
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  /// Mirrors `BBoxDeviceContext::UpdateBB` (bboxdevicecontext.cpp:400):
  /// accumulates the device coordinates into the self bounding box of the
  /// object being drawn (the top of the stack) and into the content bounding
  /// box of every object on the stack. The rotation set by [rotateGraphic] is
  /// applied first; the `update` mode is **not** consulted here (the C++
  /// filtering happens in the `View`, which checks `UpdateVerticalValues`).
  ///
  /// Deviations from the C++:
  /// - `m_view->ToLogicalX/Y` becomes the [LogicalTransform] functions given
  ///   at construction.
  void updateBB(int x1, int y1, int x2, int y2, [int glyph = 0]) {
    if (isDeactivatedX && isDeactivatedY) return;

    if (!_approximatelyEqual(rotationAngle, 0.0)) {
      final double alpha = degToRad(rotationAngle);
      final Point p1 = BoundingBox.calcPositionAfterRotation(
          Point(x1, y1), alpha, rotationOrigin);
      final Point p2 = BoundingBox.calcPositionAfterRotation(
          Point(x2, y2), alpha, rotationOrigin);
      x1 = p1.x;
      y1 = p1.y;
      x2 = p2.x;
      y2 = p2.y;
    }

    // The array may not be empty.
    assert(objects.isNotEmpty);

    // We need to store logical coordinates in the objects, so we need to
    // convert them back (this is why we need a View object in the C++).
    if (!isDeactivatedX) {
      objects.last.updateSelfBBoxX(_toLogicalX(x1), _toLogicalX(x2));
      if (glyph != 0) {
        objects.last.setBoundingBoxGlyph(glyph, font.pointSize);
      }
    }
    if (!isDeactivatedY) {
      objects.last.updateSelfBBoxY(_toLogicalY(y1), _toLogicalY(y2));
      if (glyph != 0) {
        objects.last.setBoundingBoxGlyph(glyph, font.pointSize);
      }
    }

    // Stretch the content BB of the other objects.
    for (final BoundingBox object in objects) {
      if (!isDeactivatedX) {
        object.updateContentBBoxX(_toLogicalX(x1), _toLogicalX(x2));
      }
      if (!isDeactivatedY) {
        object.updateContentBBoxY(_toLogicalY(y1), _toLogicalY(y2));
      }
    }
  }

  /// Returns the overlap due to the pen width on the left/right as `(p1, p2)`
  /// (mirrors `BBoxDeviceContext::GetPenWidthOverlap`,
  /// bboxdevicecontext.cpp:443).
  ///
  /// Deviations from the C++:
  /// - private in the C++; public here so the tests can exercise the
  ///   arithmetic directly (production code goes through the primitives).
  (int, int) getPenWidthOverlap() {
    final int penWidth = pen.width;
    int p1 = penWidth ~/ 2;
    int p2 = p1;

    // How odd line width is handled might depend on the implementation of
    // the device context. However, we expect the actual width to be shifted
    // on the left/top — e.g., with 7, 4 on the left and 3 on the right.
    if (penWidth % 2 != 0) ++p1;

    return (p1, p2);
  }
}

/// Mirrors `vrv::ApproximatelyEqual` (vrv.cpp:224: `fabs(a - b) < 1E-3`).
bool _approximatelyEqual(double a, double b) => (a - b).abs() < 1E-3;
