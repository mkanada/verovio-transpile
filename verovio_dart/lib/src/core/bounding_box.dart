/// Port of `boundingbox.h/cpp` — BoundingBox and SegmentedLine.
///
/// Methods depending on Glyph/Resources/Doc (anchor cut-outs, curve and beam
/// intersections) are completed in the rendering phase.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';

/// Approximation steps for bezier bounding box calculation
/// (`BEZIER_APPROXIMATION`).
const double bezierApproximation = 50.0;

/// This class represents a basic object in the layout domain.
abstract class BoundingBox {
  BoundingBox() {
    resetBoundingBox();
  }

  /// Mirrors `GetClassId()`.
  ClassId get classId;

  bool isClass(ClassId id) => classId == id;

  bool isAny(Set<ClassId> classIds) => classIds.contains(classId);

  /// Methods for updating the bounding boxes.
  void updateContentBBoxX(int x1, int x2) {
    int minX = math.min(x1, x2);
    int maxX = math.max(x1, x2);

    final int drawingX = getDrawingX();

    minX -= drawingX;
    maxX -= drawingX;

    if (_contentBBx1 > minX) _contentBBx1 = minX;
    if (_contentBBx2 < maxX) _contentBBx2 = maxX;
  }

  void updateContentBBoxY(int y1, int y2) {
    int minY = math.min(y1, y2);
    int maxY = math.max(y1, y2);

    final int drawingY = getDrawingY();

    minY -= drawingY;
    maxY -= drawingY;

    if (_contentBBy1 > minY) _contentBBy1 = minY;
    if (_contentBBy2 < maxY) _contentBBy2 = maxY;
  }

  void updateSelfBBoxX(int x1, int x2) {
    int minX = math.min(x1, x2);
    int maxX = math.max(x1, x2);

    final int drawingX = getDrawingX();

    minX -= drawingX;
    maxX -= drawingX;

    if (_selfBBx1 > minX) _selfBBx1 = minX;
    if (_selfBBx2 < maxX) _selfBBx2 = maxX;
  }

  void updateSelfBBoxY(int y1, int y2) {
    int minY = math.min(y1, y2);
    int maxY = math.max(y1, y2);

    final int drawingY = getDrawingY();

    minY -= drawingY;
    maxY -= drawingY;

    if (_selfBBy1 > minY) _selfBBy1 = minY;
    if (_selfBBy2 < maxY) _selfBBy2 = maxY;
  }

  void setEmptyBB() {
    _contentBBx1 = 0;
    _contentBBy1 = 0;
    _contentBBx2 = 0;
    _contentBBy2 = 0;
    _selfBBx1 = 0;
    _selfBBy1 = 0;
    _selfBBx2 = 0;
    _selfBBy2 = 0;
  }

  bool hasSelfBB() => hasSelfHorizontalBB() && hasSelfVerticalBB();

  bool hasSelfHorizontalBB() =>
      (_selfBBx1 != -meiUnset) && (_selfBBx2 != meiUnset);

  bool hasSelfVerticalBB() =>
      (_selfBBy1 != -meiUnset) && (_selfBBy2 != meiUnset);

  bool hasContentBB() => hasContentHorizontalBB() && hasContentVerticalBB();

  bool hasContentHorizontalBB() =>
      (_contentBBx1 != -meiUnset) && (_contentBBx2 != meiUnset);

  bool hasContentVerticalBB() =>
      (_contentBBy1 != -meiUnset) && (_contentBBy2 != meiUnset);

  bool hasEmptyBB() {
    // We are checking only the content bounding box - this should be OK.
    return _contentBBx1 == 0 &&
        _contentBBy1 == 0 &&
        _contentBBx2 == 0 &&
        _contentBBy2 == 0;
  }

  /// Set the SMuFL glyph / fontsize for a bounding box that is the one of a
  /// single SMuFL glyph.
  void setBoundingBoxGlyph(int smuflGlyph, int fontSize) {
    assert(smuflGlyph != 0);
    _smuflGlyph = smuflGlyph;
    _smuflGlyphFontSize = fontSize;
  }

  int get boundingBoxGlyph => _smuflGlyph;
  int get boundingBoxGlyphFontSize => _smuflGlyphFontSize;

  /// Reset the bounding box values.
  void resetBoundingBox() {
    _contentBBx1 = -meiUnset;
    _contentBBy1 = -meiUnset;
    _contentBBx2 = meiUnset;
    _contentBBy2 = meiUnset;
    _selfBBx1 = -meiUnset;
    _selfBBy1 = -meiUnset;
    _selfBBx2 = meiUnset;
    _selfBBy2 = meiUnset;

    cachedDrawingX = meiUnset;
    cachedDrawingY = meiUnset;

    _smuflGlyph = 0;
    _smuflGlyphFontSize = 100;
  }

  /// The cached version of the drawingX/drawingY values.
  int cachedDrawingX = meiUnset;
  int cachedDrawingY = meiUnset;

  /// Get the X and Y drawing position (pure virtual in C++).
  int getDrawingX();
  int getDrawingY();

  /// Reset the cached values of the drawingX and Y values (pure virtual).
  void resetCachedDrawingX();
  void resetCachedDrawingY();

  // Get positions for self and content.

  int getSelfBottom() => getDrawingY() + _selfBBy1;
  int getSelfTop() => getDrawingY() + _selfBBy2;
  int getSelfLeft() => getDrawingX() + _selfBBx1;
  int getSelfRight() => getDrawingX() + _selfBBx2;
  int getContentBottom() => getDrawingY() + _contentBBy1;
  int getContentTop() => getDrawingY() + _contentBBy2;
  int getContentLeft() => getDrawingX() + _contentBBx1;
  int getContentRight() => getDrawingX() + _contentBBx2;

  int getSelfX1() => _selfBBx1;
  int getSelfX2() => _selfBBx2;
  int getSelfY1() => _selfBBy1;
  int getSelfY2() => _selfBBy2;
  int getContentX1() => _contentBBx1;
  int getContentX2() => _contentBBx2;
  int getContentY1() => _contentBBy1;
  int getContentY2() => _contentBBy2;

  // Get wrappers.

  int getBottomBy(Accessor type) =>
      type == Accessor.self ? getSelfBottom() : getContentBottom();
  int getTopBy(Accessor type) =>
      type == Accessor.self ? getSelfTop() : getContentTop();
  int getLeftBy(Accessor type) =>
      type == Accessor.self ? getSelfLeft() : getContentLeft();
  int getRightBy(Accessor type) =>
      type == Accessor.self ? getSelfRight() : getContentRight();
  int getX1By(Accessor type) =>
      type == Accessor.self ? getSelfX1() : getContentX1();
  int getX2By(Accessor type) =>
      type == Accessor.self ? getSelfX2() : getContentX2();
  int getY1By(Accessor type) =>
      type == Accessor.self ? getSelfY1() : getContentY1();
  int getY2By(Accessor type) =>
      type == Accessor.self ? getSelfY2() : getContentY2();

  /// Return true if the bounding box has a horizontal overlap with [other].
  bool horizontalContentOverlap(BoundingBox other, [int margin = 0]) {
    if (!hasContentBB() || !other.hasContentBB()) return false;
    if (getContentRight() <= other.getContentLeft() - margin) return false;
    if (getContentLeft() >= other.getContentRight() + margin) return false;
    return true;
  }

  bool verticalContentOverlap(BoundingBox other, [int margin = 0]) {
    if (!hasContentBB() || !other.hasContentBB()) return false;
    if (getContentTop() <= other.getContentBottom() - margin) return false;
    if (getContentBottom() >= other.getContentTop() + margin) return false;
    return true;
  }

  bool horizontalSelfOverlap(BoundingBox other, [int margin = 0]) {
    if (!hasSelfBB() || !other.hasSelfBB()) return false;
    if (getSelfRight() <= other.getSelfLeft() - margin) return false;
    if (getSelfLeft() >= other.getSelfRight() + margin) return false;
    return true;
  }

  bool verticalSelfOverlap(BoundingBox other, [int margin = 0]) {
    if (!hasSelfBB() || !other.hasSelfBB()) return false;
    if (getSelfTop() <= other.getSelfBottom() - margin) return false;
    if (getSelfBottom() >= other.getSelfTop() + margin) return false;
    return true;
  }

  /// Return the overlap of the right edge of this box over [other] (mirrors
  /// `BoundingBox::HorizontalRightOverlap`).
  ///
  /// Deviation: the SMuFL glyph cut-out anchors arrive with the resources
  /// phase; a single plain rectangle is used for each box.
  int horizontalRightOverlap(BoundingBox other,
      [int margin = 0, int vMargin = 0]) {
    // rect[0] is the top-left corner, rect[1] the bottom-right one — mirrors
    // `BoundingBox::GetRectangles`' single-rect fallback:
    // `rect[0] = (GetSelfLeft(), GetSelfTop())`, `rect[1] = (GetSelfRight(),
    // GetSelfBottom())`. Getting this swapped previously made the vertical
    // no-overlap test ("top1 < bottom2" / "bottom1 > top2") into a near-tautology
    // ("bottom1 < top2"), which spuriously reported "no overlap" for boxes that
    // plainly overlapped (e.g. two unison noteheads at the same position before
    // being shifted apart — see unison-003).
    final Point rect1a = Point(getSelfLeft(), getSelfTop());
    final Point rect1b = Point(getSelfRight(), getSelfBottom());
    return _rectRightOverlap(
        rect1a,
        rect1b,
        other.getSelfLeft(),
        other.getSelfTop(),
        other.getSelfRight(),
        other.getSelfBottom(),
        margin,
        vMargin);
  }

  /// Mirrors `BoundingBox::RectRightOverlap`.
  static int _rectRightOverlap(Point rect1a, Point rect1b, int x2a, int y2a,
      int x2b, int y2b, int margin, int vMargin) {
    if ((rect1a.y < y2b - vMargin) || (rect1b.y > y2a + vMargin)) return 0;
    final int overlap = rect1b.x - x2a + margin;
    return math.max(0, overlap);
  }

  /// Return the overlap of the left edge of this box under [other] (mirrors
  /// `BoundingBox::HorizontalLeftOverlap`).
  ///
  /// Deviation: the SMuFL glyph cut-out anchors arrive with the resources
  /// phase; a single plain rectangle is used for each box.
  int horizontalLeftOverlap(BoundingBox other,
      [int margin = 0, int vMargin = 0]) {
    // rect[0] is the top-left corner, rect[1] the bottom-right one — see the
    // matching comment in `horizontalRightOverlap` above.
    final Point rect1a = Point(getSelfLeft(), getSelfTop());
    final Point rect1b = Point(getSelfRight(), getSelfBottom());
    return _rectLeftOverlap(
        rect1a,
        rect1b,
        other.getSelfLeft(),
        other.getSelfTop(),
        other.getSelfRight(),
        other.getSelfBottom(),
        margin,
        vMargin);
  }

  /// Mirrors `BoundingBox::RectLeftOverlap`.
  static int _rectLeftOverlap(Point rect1a, Point rect1b, int x2a, int y2a,
      int x2b, int y2b, int margin, int vMargin) {
    if ((rect1a.y < y2b - vMargin) || (rect1b.y > y2a + vMargin)) return 0;
    final int overlap = x2b - rect1a.x + margin;
    return math.max(0, overlap);
  }

  /// Return the right cut-out anchor of the glyph, from the top or bottom
  /// edge (mirrors `BoundingBox::GetCutOutRight(const Resources&, bool)`).
  ///
  /// Deviation: the SMuFL glyph cut-out anchors arrive with the resources
  /// phase (see the file header); falls back to the plain self-right edge.
  int getCutOutRight([bool fromTop = true]) => getSelfRight();

  /// Return true if the bounding box encloses the point.
  bool encloses(Point point) {
    if (getContentRight() < point.x) return false;
    if (getContentLeft() > point.x) return false;
    if (getContentTop() < point.y) return false;
    if (getContentBottom() > point.y) return false;
    return true;
  }

  //----------------//
  // Static methods //
  //----------------//

  static Point calcPositionAfterRotation(
      Point point, double alpha, Point center) {
    if (point == center) return point;

    final double s = math.sin(alpha);
    final double c = math.cos(alpha);

    // Translate point back to origin.
    point.x -= center.x;
    point.y -= center.y;

    // Rotate point.
    final double xnew = point.x * c - point.y * s;
    final double ynew = point.x * s + point.y * c;

    // Translate point back.
    point.x = (xnew + center.x).round();
    point.y = (ynew + center.y).round();
    return point;
  }

  /// Calculate the euclidean distance between two points.
  static double calcDistance(Point p1, Point p2) =>
      math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2));

  /// True if the distance between the points does not exceed [margin].
  static bool arePointsClose(Point p1, Point p2, int margin) =>
      calcDistance(p1, p2) <= margin;

  /// Calculate the slope represented by two points.
  static double calcSlope(Point p1, Point p2) {
    if ((p1.y == p2.y) || (p1.x == p2.x)) return 0.0;
    return (p2.y - p1.y) / (p2.x - p1.x);
  }

  /// Calculate the t parameter of a bezier at position x.
  static double calcBezierParamAtPosition(List<Point> bezier, int x) {
    assert(bezier.length == 4);

    // Coefficients of the cubic polynomial.
    final double a =
        -bezier[0].x + 3.0 * bezier[1].x - 3.0 * bezier[2].x + bezier[3].x;
    final double b = 3.0 * bezier[0].x - 6.0 * bezier[1].x + 3.0 * bezier[2].x;
    final double c = -3.0 * bezier[0].x + 3.0 * bezier[1].x;
    final double d = bezier[0].x.toDouble() - x;

    // Solve the polynomial.
    final roots = solveCubicPolynomial(a, b, c, d);

    // Return the first root in [0,1].
    const eps = 1e-6; // Numerical freedom
    double root = 0.0;
    for (final value in roots) {
      if (value >= -eps && value <= 1.0 + eps) {
        root = value.clamp(0.0, 1.0);
        break;
      }
    }
    return root;
  }

  /// Calculate the y position of a bezier at position x.
  static int calcBezierAtPosition(List<Point> bezier, int x) {
    final t = calcBezierParamAtPosition(bezier, x);
    final p = calcDeCasteljau(bezier, t);
    return p.y;
  }

  /// Linear interpolation between two points at time t.
  static Point calcLinearInterpolation(Point a, Point b, double t) =>
      Point((a.x + (b.x - a.x) * t).round(), (a.y + (b.y - a.y) * t).round());

  /// Calculate point (X,Y) coordinates on the bezier curve.
  static Point calcPointAtBezier(List<Point> bezier, double t) {
    assert(bezier.length == 4);
    final p1 = calcLinearInterpolation(bezier[0], bezier[1], t);
    final p2 = calcLinearInterpolation(bezier[1], bezier[2], t);
    final p3 = calcLinearInterpolation(bezier[2], bezier[3], t);
    final p4 = calcLinearInterpolation(p1, p2, t);
    final p5 = calcLinearInterpolation(p2, p3, t);
    // Middle point on the bezier-curve.
    return calcLinearInterpolation(p4, p5, t);
  }

  /// Calculate thickness coefficient for a bezier curve to fit MEI units
  /// thickness.
  static double getBezierThicknessCoefficient(
      List<Point> bezier, int currentThickness, int penWidth) {
    final top = List<Point>.filled(4, Point());
    final bottom = List<Point>.filled(4, Point());
    calcThickBezier(bezier, currentThickness, top, bottom);

    final topMidpoint = calcPointAtBezier(top, 0.5);
    final bottomMidpoint = calcPointAtBezier(bottom, 0.5);

    final actualThickness = math
        .sqrt(math.pow(topMidpoint.x - bottomMidpoint.x, 2) +
            math.pow(topMidpoint.y - bottomMidpoint.y, 2))
        .toInt();
    double adjustedThickness = (currentThickness - penWidth).toDouble();
    if (adjustedThickness < 0) adjustedThickness = 0;
    return adjustedThickness / actualThickness;
  }

  /// Calculate the point bezier position for a t between 0.0 and 1.0.
  static Point calcDeCasteljau(List<Point> bezier, double t) {
    assert(bezier.length == 4);
    final x = math.pow(1 - t, 3) * bezier[0].x +
        3 * t * math.pow(1 - t, 2) * bezier[1].x +
        3 * (1 - t) * math.pow(t, 2) * bezier[2].x +
        math.pow(t, 3) * bezier[3].x;
    final y = math.pow(1 - t, 3) * bezier[0].y +
        3 * t * math.pow(1 - t, 2) * bezier[1].y +
        3 * (1 - t) * math.pow(t, 2) * bezier[2].y +
        math.pow(t, 3) * bezier[3].y;
    return Point(x.round(), y.round());
  }

  /// Calculate the position of the bezier above and below for a thick bezier.
  static void calcThickBezier(List<Point> bezier, int thickness,
      List<Point> topBezier, List<Point> bottomBezier) {
    assert(bezier.length == 4 &&
        topBezier.length == 4 &&
        bottomBezier.length == 4);

    // We shift the control point outwards/inwards in the direction of the
    // angle bisector of the polygon P1-C1-C2-P2 at C1 or C2.
    double slope1 = calcSlope(bezier[0], bezier[1]);
    if (bezier[0].x > bezier[1].x) slope1 *= -1.0;
    double slope2 = calcSlope(bezier[1], bezier[2]);
    if (bezier[1].x > bezier[2].x) slope2 *= -1.0;
    double slope3 = calcSlope(bezier[2], bezier[3]);
    if (bezier[2].x > bezier[3].x) slope3 *= -1.0;
    final double angle1 = (math.atan(slope1) + math.atan(slope2)) / 2.0;
    final double angle2 = (math.atan(slope2) + math.atan(slope3)) / 2.0;

    // Calculate top bezier.
    Point c1Rotated =
        Point(bezier[1].x, bezier[1].y + (thickness * 0.5).round());
    Point c2Rotated =
        Point(bezier[2].x, bezier[2].y + (thickness * 0.5).round());
    c1Rotated = calcPositionAfterRotation(c1Rotated, angle1, bezier[1]);
    c2Rotated = calcPositionAfterRotation(c2Rotated, angle2, bezier[2]);

    topBezier[0] = bezier[0];
    topBezier[1] = c1Rotated;
    topBezier[2] = c2Rotated;
    topBezier[3] = bezier[3];

    // Calculate bottom bezier.
    c1Rotated = Point(bezier[1].x, bezier[1].y - (thickness * 0.5).round());
    c2Rotated = Point(bezier[2].x, bezier[2].y - (thickness * 0.5).round());
    c1Rotated = calcPositionAfterRotation(c1Rotated, angle1, bezier[1]);
    c2Rotated = calcPositionAfterRotation(c2Rotated, angle2, bezier[2]);

    bottomBezier[0] = bezier[0];
    bottomBezier[1] = c1Rotated;
    bottomBezier[2] = c2Rotated;
    bottomBezier[3] = bezier[3];
  }

  /// Approximate the bounding box of a bezier.
  ///
  /// Returns (pos, width, height, minYPos, maxYPos).
  static (Point pos, int width, int height, int minYPos, int maxYPos)
      approximateBezierBoundingBox(List<Point> bezier) {
    assert(bezier.length == 4);

    final int ax = bezier[0].x, ay = bezier[0].y;
    final int bx = bezier[1].x, by = bezier[1].y;
    final int cx = bezier[2].x, cy = bezier[2].y;
    final int dx = bezier[3].x, dy = bezier[3].y;

    int minx = -meiUnset, miny = -meiUnset;
    int maxx = meiUnset, maxy = meiUnset;
    int minYPos = 0, maxYPos = 0;

    final double tobx = (bx - ax).toDouble(), toby = (by - ay).toDouble();
    final double tocx = (cx - bx).toDouble(), tocy = (cy - by).toDouble();
    final double todx = (dx - cx).toDouble(), tody = (dy - cy).toDouble();

    final double step = 1.0 / bezierApproximation;
    final int nSteps = bezierApproximation.toInt();
    for (int i = 0; i < nSteps + 1; ++i) {
      final double d = i * step;
      final px = ax + d * tobx, py = ay + d * toby;
      final qx = bx + d * tocx, qy = by + d * tocy;
      final rx = cx + d * todx, ry = cy + d * tody;
      final toqx = qx - px, toqy = qy - py;
      final torx = rx - qx, tory = ry - qy;

      final sx = px + d * toqx, sy = py + d * toqy;
      final tx = qx + d * torx, ty = qy + d * tory;
      final totx = tx - sx, toty = ty - sy;

      final int x = (sx + d * totx).round();
      final int y = (sy + d * toty).round();
      minx = math.min(minx, x);
      if (miny > y) {
        miny = y;
        minYPos = ((bezier[3].x - bezier[0].x) * d).round();
      }
      maxx = math.max(maxx, x);
      if (maxy < y) {
        maxy = y;
        maxYPos = ((bezier[3].x - bezier[0].x) * d).round();
      }
    }
    return (Point(minx, miny), maxx - minx, maxy - miny, minYPos, maxYPos);
  }

  /// Approximate extremum (t, y) on the bezier curve.
  static (double, int) approximateBezierExtrema(List<Point> bezier,
      {bool isMaxExtrema = true, int approximationSteps = 50}) {
    // These time points can be approximated simply by calculating the Y point
    // for T time with a certain step.
    double bestT = 0;
    int bestY = 0;
    bool first = true;
    final double step = 1.0 / approximationSteps;
    for (int i = 0; i < approximationSteps + 1; ++i) {
      final double currentTime = i * step;
      final int y = calcPointAtBezier(bezier, currentTime).y;
      if (first ||
          (isMaxExtrema && y > bestY) ||
          (!isMaxExtrema && y < bestY)) {
        bestT = currentTime;
        bestY = y;
        first = false;
      }
    }
    return (bestT, bestY);
  }

  /// Calculate the left/right/top/bottom overlap of two rectangles taking
  /// into account the margin / v-h-Margins.
  static int rectLeftOverlap(
      List<Point> rect1, List<Point> rect2, int margin, int vMargin) {
    if ((rect1[0].y < rect2[1].y - vMargin) ||
        (rect1[1].y > rect2[0].y + vMargin)) {
      return 0;
    }
    return math.max(0, rect2[1].x - rect1[0].x + margin);
  }

  static int rectRightOverlap(
      List<Point> rect1, List<Point> rect2, int margin, int vMargin) {
    if ((rect1[0].y < rect2[1].y - vMargin) ||
        (rect1[1].y > rect2[0].y + vMargin)) {
      return 0;
    }
    return math.max(0, rect1[1].x - rect2[0].x + margin);
  }

  static int rectTopOverlap(
      List<Point> rect1, List<Point> rect2, int margin, int hMargin) {
    if ((rect1[0].x > rect2[1].x + hMargin) ||
        (rect1[1].x < rect2[0].x - hMargin)) {
      return 0;
    }
    return math.max(0, rect1[1].y - rect2[0].y + margin);
  }

  static int rectBottomOverlap(
      List<Point> rect1, List<Point> rect2, int margin, int hMargin) {
    if ((rect1[0].x > rect2[1].x + hMargin) ||
        (rect1[1].x < rect2[0].x - hMargin)) {
      return 0;
    }
    return math.max(0, rect2[1].y - rect1[0].y + margin);
  }

  /// Solve the cubic equation ax^3 + bx^2 + cx + d = 0.
  /// Returns up to three real roots (sorted ascending like std::set).
  static Set<double> solveCubicPolynomial(
      double a, double b, double c, double d) {
    // Implementation of Cardano's algorithm.
    // See https://pomax.github.io/bezierinfo/#extremities

    // Check whether we need cubic solving.
    if (a.abs() < 10e-10) {
      // This is not a cubic curve.
      if (b.abs() < 10e-10) {
        // This is not a quadratic curve either.
        if (c.abs() < 10e-10) {
          return {};
        }
        // Linear solution.
        return {-d / c};
      }
      // Quadratic solution.
      final double q = math.sqrt(c * c - 4.0 * b * d);
      return {(q - c) / (2.0 * b), (-c - q) / (2.0 * b)};
    }

    // We know that we need a cubic solution.
    b /= a;
    c /= a;
    d /= a;

    final double p = (3.0 * c - b * b) / 3.0;
    final double p3 = p / 3.0;
    final double q = (2.0 * b * b * b - 9.0 * b * c + 27.0 * d) / 27.0;
    final double q2 = q / 2.0;
    final double discriminant = q2 * q2 + p3 * p3 * p3;

    if (discriminant < 0.0) {
      // Three possible real roots.
      final double mp3 = -p / 3.0;
      final double r = math.sqrt(mp3 * mp3 * mp3);
      final double t = -q / (2.0 * r);
      final double cosphi = t.clamp(-1.0, 1.0);
      final double phi = math.acos(cosphi);
      final double u = 2.0 * _cbrt(r);
      final double root1 = u * math.cos(phi / 3.0) - b / 3.0;
      final double root2 = u * math.cos((phi + 2.0 * math.pi) / 3.0) - b / 3.0;
      final double root3 = u * math.cos((phi + 4.0 * math.pi) / 3.0) - b / 3.0;
      return {root1, root2, root3};
    }

    if (discriminant == 0.0) {
      // Three real roots, but two of them equal.
      final double u = -_cbrt(q2);
      final double root1 = 2.0 * u - b / 3.0;
      final double root2 = -u - b / 3.0;
      return {root1, root2};
    }

    // One real root, two complex roots.
    final double sd = math.sqrt(discriminant);
    final double u = _cbrt(sd - q2);
    final double v = _cbrt(sd + q2);
    return {u - v - b / 3.0};
  }

  static double _cbrt(double x) =>
      x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

  // Bounding box positions.
  int _contentBBx1 = 0, _contentBBy1 = 0, _contentBBx2 = 0, _contentBBy2 = 0;
  int _selfBBx1 = 0, _selfBBy1 = 0, _selfBBx2 = 0, _selfBBy2 = 0;

  /// The SMuFL glyph when anchor bounding box calculation is desired.
  int _smuflGlyph = 0;

  /// The font size for the SMuFL glyph used for calculating rectangles.
  int _smuflGlyphFontSize = 100;
}

/// Port of `SegmentedLine`.
class SegmentedLine {
  /// Creates a segmented line from [start] to [end].
  SegmentedLine(int start, int end) {
    increasing = start <= end;
    if (!increasing) {
      final tmp = start;
      start = end;
      end = tmp;
    }
    segments.add((start, end));
  }

  /// An ordered list of line segments; always increasing order/orientation.
  final List<(int, int)> segments = [];

  /// Flag indicating the orientation of the original line.
  late bool increasing;

  bool isEmpty() => segments.isEmpty;

  bool isUnsegmented() => segments.length == 1;

  int get segmentCount => segments.length;

  /// Get the start and end of a segment.
  (int, int) getStartEnd(int idx) {
    assert(idx >= 0);
    assert(idx < segmentCount);

    if (increasing) {
      return segments[idx];
    } else {
      // Read the segment array "backwards".
      final j = segmentCount - 1 - idx;
      return (segments[j].$2, segments[j].$1);
    }
  }

  /// Add a gap in the line.
  void addGap(int start, int end) {
    assert(start != end);

    // Internally segments always have increasing order and orientation.
    if (start > end) {
      final tmp = start;
      start = end;
      end = tmp;
    }

    // Nothing to do.
    if (segments.isEmpty) return;

    // Insert the gap.
    int i = 0;
    while (i < segments.length) {
      final seg = segments[i];
      // Drop the segment because the gap encompasses it.
      if (start <= seg.$1 && end >= seg.$2) {
        segments.removeAt(i);
        continue;
      }
      // Cut the segment because the gap is within it.
      if (seg.$1 <= start && seg.$2 >= end) {
        segments.replaceRange(i, i + 1, [(seg.$1, start), (end, seg.$2)]);
        break;
      }
      // Move the start of the segment.
      if (start < seg.$1 && end >= seg.$1) {
        segments[i] = (end, seg.$2);
      }
      // Move the end of the segment.
      if (end > seg.$2 && start <= seg.$2) {
        segments[i] = (seg.$1, start);
      }
      ++i;
    }
  }
}
