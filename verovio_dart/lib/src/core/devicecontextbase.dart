/// Port of `devicecontextbase.h` — drawing style parameters shared by all
/// device contexts (Pen, Brush, FontInfo, TextExtend, BezierCurve).
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------

const int colorNone = -1;
const int colorWhite = 255 << 16 | 255 << 8 | 255;
const int colorBlack = 0;
const int colorRed = 255 << 16;
const int colorBlue = 255;
const int colorGreen = 255 << 8;
const int colorCyan = 255 << 8 | 255;
const int colorLightGrey = 127 << 16 | 127 << 8 | 127;

// ---------------------------------------------------------------------------
// Pen / line styles
// ---------------------------------------------------------------------------

enum PenStyle {
  solid,
  dot,
  longDash,
  shortDash,
  dotDash,
}

enum LineCapStyle {
  default_,
  butt,
  round,
  square,
}

enum LineJoinStyle {
  default_,
  arcs,
  bevel,
  miter,
  miterClip,
  round,
}

/// Used for storing drawing style parameters during SVG and bounding box
/// engraving (mirrors `vrv::Pen`).
class Pen {
  Pen({
    this.width = 0,
    this.style = PenStyle.solid,
    this.dashLength = 0,
    this.gapLength = 0,
    this.lineCap = LineCapStyle.default_,
    this.lineJoin = LineJoinStyle.default_,
    this.opacity = -1.0,
    this.color = colorNone,
  });

  int width;
  PenStyle style;
  int dashLength, gapLength;
  LineCapStyle lineCap;
  LineJoinStyle lineJoin;
  double opacity;
  int color;

  bool get hasColor => color != colorNone;
  bool get hasOpacity => opacity != -1.0;
}

/// Mirrors `vrv::Brush`.
class Brush {
  Brush({this.opacity = -1.0, this.color = colorNone});

  double opacity;
  int color;

  bool get hasColor => color != colorNone;
  bool get hasOpacity => opacity != -1.0;
}

// ---------------------------------------------------------------------------
// FontInfo
// ---------------------------------------------------------------------------

/// Stores font properties (mirrors `vrv::FontInfo`).
class FontInfo {
  int pointSize = 0;
  int letterSpacing = 0;
  int family = 0; // was wxFONTFAMILY_DEFAULT
  FontStyle fontStyle = FontStyle.none_;
  FontWeight fontWeight = FontWeight.none_;
  bool underlined = false;
  bool supSubScript = false;
  String faceName = '';
  int encoding = 0; // was wxFONTENCODING_DEFAULT
  double widthToHeightRatio = 1.0;
  SmuflTextFont smuflFont = SmuflTextFont.none;

  /// Mirrors `SetSmuflWithFallback`.
  void setSmuflWithFallback(bool fallback) => smuflFont =
      fallback ? SmuflTextFont.fontFallback : SmuflTextFont.fontSelected;
}

// ---------------------------------------------------------------------------
// BezierCurve
// ---------------------------------------------------------------------------

/// Simple class for representing a bezier curve (mirrors `vrv::BezierCurve`).
class BezierCurve {
  Point p1 = Point(0, 0); // start point
  Point c1 = Point(0, 0); // control points
  Point c2 = Point(0, 0);
  Point p2 = Point(0, 0); // end point

  BezierCurve();

  /// Mirrors `BezierCurve(Point, Point, Point, Point)`; the C++ stores the
  /// points by value, so the points are copied here to avoid aliasing (e.g.,
  /// `CalcInitialCurve` builds a curve with C1 = P1).
  BezierCurve.of(Point p1, Point c1, Point c2, Point p2) {
    this.p1 = Point(p1.x, p1.y);
    this.c1 = Point(c1.x, c1.y);
    this.c2 = Point(c2.x, c2.y);
    this.p2 = Point(p2.x, p2.y);
  }

  // Control point X-axis offset for both start/end points
  int _leftControlOffset = 0;
  int _rightControlOffset = 0;
  int _leftControlHeight = 0;
  int _rightControlHeight = 0;
  bool _leftControlAbove = true;
  bool _rightControlAbove = true;

  /// Helper to rotate all points within the bezier curve around [rotationPoint]
  /// by [angle] radians.
  void rotate(double angle, Point rotationPoint) {
    p1 = BoundingBox.calcPositionAfterRotation(p1, angle, rotationPoint);
    p2 = BoundingBox.calcPositionAfterRotation(p2, angle, rotationPoint);
    c1 = BoundingBox.calcPositionAfterRotation(c1, angle, rotationPoint);
    c2 = BoundingBox.calcPositionAfterRotation(c2, angle, rotationPoint);
  }

  /// Getter/setter for control point offset.
  void setControlOffset(int offset) {
    _leftControlOffset = _rightControlOffset = offset;
  }

  void setLeftControlOffset(int offset) => _leftControlOffset = offset;
  void setRightControlOffset(int offset) => _rightControlOffset = offset;
  int get leftControlOffset => _leftControlOffset;
  int get rightControlOffset => _rightControlOffset;

  /// Getter/setter for the height of control points (left and right).
  void setControlHeight(int height) {
    _leftControlHeight = _rightControlHeight = height;
  }

  void setLeftControlHeight(int height) => _leftControlHeight = height;
  void setRightControlHeight(int height) => _rightControlHeight = height;
  int get leftControlHeight => _leftControlHeight;
  int get rightControlHeight => _rightControlHeight;

  /// Getter/setter for the side of the control points (left and right).
  void setControlSides(bool leftAbove, bool rightAbove) {
    _leftControlAbove = leftAbove;
    _rightControlAbove = rightAbove;
  }

  bool get isLeftControlAbove => _leftControlAbove;
  bool get isRightControlAbove => _rightControlAbove;

  /// Initialize control point offset and height from end point positions
  /// (mirrors `CalcInitialControlPointParams()` without Doc — the Doc-aware
  /// overload arrives with the layout phase).
  void calcInitialControlPointParams() {
    final int dist = (p2.x - p1.x).abs();
    setControlOffset(dist ~/ 3.0);
    setControlHeight(0);
  }

  /// Mirrors `BezierCurve::CalcInitialControlPointParams(const Doc*, float,
  /// int)` (devicecontext.cpp). [getDrawingUnit] / [getOctaveSize] /
  /// [slurCurveFactor] are passed in by the caller to keep this core class
  /// free of the Doc import.
  void calcInitialControlPointParamsWithDoc(
      int Function(int staffSize) getDrawingUnit,
      int Function(int staffSize) getOctaveSize,
      double slurCurveFactor,
      double angle,
      int staffSize) {
    // Note: For convex curves (both control points on the same side) we
    // assume that the curve is rotated such that p1.y == p2.y, but for
    // curves with mixed curvature we assume that the curve is unrotated.
    final int dist = (p2.x - p1.x).abs();
    final int unit = getDrawingUnit(staffSize);

    // Initialize offset
    int offset = 0;
    if (_leftControlAbove == _rightControlAbove) {
      final double ratio = dist / unit;
      double baseVal = (ratio > 4.0) ? 3.0 : 6.0;
      if ((ratio > 4.0) && (ratio < 32.0)) {
        // interpolate baseVal between 6.0 and 3.0
        baseVal = 8.0 - (math.log(ratio) / math.ln2);
      }
      offset = dist ~/ baseVal;
    } else {
      offset = dist ~/ 12.0;
      offset = math.min(offset, 4 * unit);
    }

    setLeftControlOffset(offset);
    setRightControlOffset(offset);

    // Initialize height
    int height = 0;
    if (_leftControlAbove == _rightControlAbove) {
      height = math.max(dist ~/ 5, (1.2 * unit).toInt());
      height = math.min(3 * unit, height);
      final double scaled = height * slurCurveFactor;
      height = scaled.toInt();
      height = math.min(height, 2 * getOctaveSize(staffSize));
      height =
          math.min(height, (2 * offset * math.cos(angle)).toInt());
    } else {
      height = math.max((p2.y - p1.y).abs(), 4 * unit);
      height = (height * slurCurveFactor).toInt();
    }
    setControlHeight(height);
  }

  /// Calculate control point offset and height from points or vice versa.
  void updateControlPointParams() {
    _leftControlOffset = c1.x - p1.x;
    _rightControlOffset = p2.x - c2.x;
    int sign = _leftControlAbove ? 1 : -1;
    _leftControlHeight = sign * (c1.y - p1.y);
    sign = _rightControlAbove ? 1 : -1;
    _rightControlHeight = sign * (c2.y - p2.y);
  }

  void updateControlPoints() {
    c1.x = p1.x + _leftControlOffset;
    c2.x = p2.x - _rightControlOffset;
    int sign = _leftControlAbove ? 1 : -1;
    c1.y = p1.y + sign * _leftControlHeight;
    sign = _rightControlAbove ? 1 : -1;
    c2.y = p2.y + sign * _rightControlHeight;
  }

  /// Estimate the curve parameter corresponding to the control points.
  ///
  /// Based on the polyline P1-C1-C2-P2. Returns a record `(t1, t2)`.
  (double, double) estimateCurveParamForControlPoints() {
    final double dist1 = BoundingBox.calcDistance(p1, c1);
    final double dist2 = BoundingBox.calcDistance(c1, c2);
    final double dist3 = BoundingBox.calcDistance(c2, p2);
    final double distSum = dist1 + dist2 + dist3;
    if (distSum > 0.0) {
      return (dist1 / distSum, (dist1 + dist2) / distSum);
    } else {
      return (0.0, 1.0);
    }
  }
}

// ---------------------------------------------------------------------------
// TextExtend
// ---------------------------------------------------------------------------

/// Simple class for representing text extends (mirrors `vrv::TextExtend`).
class TextExtend {
  int width = 0;
  int height = 0;
  int leftBearing = 0;
  int ascent = 0;
  int descent = 0;
  int advX = 0;
}

// ---------------------------------------------------------------------------
// Angle helpers
// ---------------------------------------------------------------------------

double degToRad(double deg) => deg * math.pi / 180.0;

double radToDeg(double deg) => deg * 180.0 / math.pi;
