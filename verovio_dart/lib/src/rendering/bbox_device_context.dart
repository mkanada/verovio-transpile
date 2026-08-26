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
  BBoxDeviceContext(
      {required LogicalTransform toLogicalX,
      required LogicalTransform toLogicalY,
      int width = 0,
      int height = 0,
      int update = 0})
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
      double tx = (bezier[0].x - bezier[1].x) /
          (bezier[0].x - 2.0 * bezier[1].x + bezier[2].x);
      tx = tx.clamp(0.0, 1.0);
      double ty = (bezier[0].y - bezier[1].y) /
          (bezier[0].y - 2.0 * bezier[1].y + bezier[2].y);
      ty = ty.clamp(0.0, 1.0);
      // vec2 s = 1.0 - t;
      final double sx = 1.0 - tx;
      final double sy = 1.0 - ty;
      // vec2 q = s*s*p0 + 2.0*s*t*p1 + t*t*p2;
      final int qx =
          (sx * sx * bezier[0].x + 2.0 * sx * tx * bezier[1].x + tx * tx * bezier[2].x)
              .toInt();
      final int qy =
          (sy * sy * bezier[0].y + 2.0 * sy * ty * bezier[1].y + ty * ty * bezier[2].y)
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
    final (int overlapFirst, int overlapSecond) = penWidthOverlap;

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

    final (int overlapFirst, int overlapSecond) = penWidthOverlap;

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

    final (int overlapFirst, int overlapSecond) = penWidthOverlap;

    updateBB(
        x1 - overlapFirst, y1 - overlapSecond, x2 + overlapSecond, y2 + overlapFirst);
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

    final (int overlapFirst, int overlapSecond) = penWidthOverlap;

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
      updateBB(textX, textY + textDescent, textX + textWidth, textY - textAscent);
    }
  }

  @override
  void drawRotatedText(String text, int x, int y, double angle) {
    // TODO: port when needed by rotated text elements.
  }

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

  void updateBB(int x1, int y1, int x2, int y2, [int glyph = 0]) {
    if (isDeactivatedX && isDeactivatedY) return;

    if (!_approximatelyEqual(rotationAngle, 0.0)) {
      final double alpha = degToRad(rotationAngle);
      final Point p1 =
          BoundingBox.calcPositionAfterRotation(Point(x1, y1), alpha, rotationOrigin);
      final Point p2 =
          BoundingBox.calcPositionAfterRotation(Point(x2, y2), alpha, rotationOrigin);
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

  /// Returns `(p1, p2)` pen-width overlaps.
  (int, int) get penWidthOverlap {
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

bool _approximatelyEqual(double a, double b) => (a - b).abs() < 1e-9;
