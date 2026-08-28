/// Port of `devicecontext.h/cpp` — the abstract device context.
///
/// It enables different types of concrete classes to be implemented
/// (SVGDeviceContext, BBoxDeviceContext, and later a Canvas adapter).
/// The class uses int-based color encoding and [FontInfo] for fonts.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/rendering/glyph.dart';
import 'package:verovio_dart/src/rendering/resources.dart';

/// The abstract device context (mirrors `vrv::DeviceContext`).
///
/// Note: graphic start/end methods currently take [BoundingBox]; they will be
/// tightened to the model `Object` class once Phase 2 lands.
abstract class DeviceContext {
  DeviceContext({ClassId classId = ClassId.deviceContext}) {
    _classId = classId;
    resources = null;
    isDeactivatedX = false;
    isDeactivatedY = false;
    width = 0;
    height = 0;
    contentHeight = 0;
    userScaleX = 1.0;
    userScaleY = 1.0;
    baseWidth = 0;
    baseHeight = 0;
    pushBack = false;
    viewBoxFactor = definitionFactor.toDouble();
    setBrush(-1.0);
    setPen(1, PenStyle.solid);
  }

  final List<Pen> _penStack = [];
  final List<Brush> _brushStack = [];
  final List<FontInfo> _fontStack = [];

  /// Flag for indicating if the graphic is deactivated.
  bool isDeactivatedX = false;
  bool isDeactivatedY = false;

  /// Push back mode.
  bool pushBack = false;

  /// The resources (not owned by the device context).
  Resources? resources;

  /// The class id representing the actual (derived) class.
  ClassId _classId = ClassId.deviceContext;

  /// Stores the width and height of the device context.
  int width = 0;
  int height = 0;

  /// Stores base width and height of the device context before scale.
  int baseWidth = 0;
  int baseHeight = 0;

  /// Stores the height of the graphic content.
  int contentHeight = 0;

  /// Stores the scale as requested by the user.
  double userScaleX = 1.0;
  double userScaleY = 1.0;

  /// Stores the viewbox factor taking into account DEFINITION_FACTOR and PPU.
  double viewBoxFactor = definitionFactor.toDouble();

  ClassId get classId => _classId;
  bool isA(ClassId classId) => _classId == classId;

  /// Resources must be set before drawing.
  Resources? getResources({bool showWarning = false}) {
    if (resources == null && showWarning) {
      logWarning('Requested resources unavailable.');
    }
    return resources;
  }

  bool get hasResources => resources != null;

  /// Set the resources (mirrors `SetResources`).
  void setResources(Resources? resources) {
    this.resources = resources;
  }

  /// Reset the resources (mirrors `ResetResources`).
  void resetResources() {
    resources = null;
  }

  // -------------------------------------------------------------------------
  // Getters and setters for common attributes (non-virtual)
  // -------------------------------------------------------------------------

  void setUserScale(double scaleX, double scaleY) {
    userScaleX = scaleX;
    userScaleY = scaleY;
  }

  void setBaseSize(int width, int height) {
    baseWidth = width;
    baseHeight = height;
  }

  (int, int) get baseSize => (baseWidth, baseHeight);

  /// Mirrors `SetViewBoxFactor(ppuFactor)`.
  void setViewBoxFactor(double ppuFactor) {
    viewBoxFactor = definitionFactor / ppuFactor;
  }

  // -------------------------------------------------------------------------
  // Pen / Brush / Font stacks (non-virtual)
  // -------------------------------------------------------------------------

  void setBrush(double opacity, [int color = colorNone]) {
    _brushStack.add(Brush(opacity: opacity, color: color));
  }

  void setPen(int width, PenStyle style,
      {int dashLength = 0,
      int gapLength = 0,
      LineCapStyle lineCap = LineCapStyle.default_,
      LineJoinStyle lineJoin = LineJoinStyle.default_,
      double opacity = -1.0,
      int color = colorNone}) {
    switch (style) {
      case PenStyle.solid:
        break;
      case PenStyle.dot:
        dashLength = dashLength != 0 ? dashLength : 1;
        gapLength = gapLength != 0 ? gapLength : width * 3;
        break;
      case PenStyle.longDash:
        dashLength = dashLength != 0 ? dashLength : width * 4;
        gapLength = gapLength != 0 ? gapLength : width * 3;
        break;
      case PenStyle.shortDash:
        dashLength = dashLength != 0 ? dashLength : width * 2;
        gapLength = gapLength != 0 ? gapLength : width * 3;
        break;
      default:
        break; // solid brush by default
    }

    _penStack.add(Pen(
      width: width,
      style: style,
      dashLength: dashLength,
      gapLength: gapLength,
      lineCap: lineCap,
      lineJoin: lineJoin,
      opacity: opacity,
      color: color,
    ));
  }

  void setFont(FontInfo font) {
    // If we have a previous font on the stack and the new font has no size,
    // pass it because we need a font size in all cases.
    if (_fontStack.isNotEmpty && font.pointSize == 0) {
      font.pointSize = _fontStack.last.pointSize;
    }
    _fontStack.add(font);
  }

  FontInfo get font {
    assert(_fontStack.isNotEmpty);
    return _fontStack.last;
  }

  bool get hasFont => _fontStack.isNotEmpty;

  Pen get pen => _penStack.last;
  Brush get brush => _brushStack.last;

  void resetPen() => _penStack.removeLast();
  void resetBrush() => _brushStack.removeLast();
  void resetFont() => _fontStack.removeLast();

  void setPushBack() => pushBack = true;
  void resetPushBack() => pushBack = false;

  /// Temporarily deactivate a graphic (non-virtual; only changes flags).
  ///
  /// Used for not taking into account the bounding box of parts of the
  /// graphic — e.g., connectors in lyrics. Should not be called twice in a
  /// row. X or Y axis can be deactivated separately; reactivate does both.
  void deactivateGraphic() {
    assert(!isDeactivatedX && !isDeactivatedY);
    isDeactivatedX = true;
    isDeactivatedY = true;
  }

  void deactivateGraphicX() {
    assert(!isDeactivatedX && !isDeactivatedY);
    isDeactivatedX = true;
  }

  void deactivateGraphicY() {
    assert(!isDeactivatedX && !isDeactivatedY);
    isDeactivatedY = true;
  }

  void reactivateGraphic() {
    assert(isDeactivatedX || isDeactivatedY);
    isDeactivatedY = false;
    isDeactivatedX = false;
  }

  // -------------------------------------------------------------------------
  // Text extends (non-virtual)
  // -------------------------------------------------------------------------

  void getTextExtent(String text, TextExtend extend, {bool typeSize = false}) {
    getTextExtentUtf32(text.runes.toList(), extend, typeSize: typeSize);
  }

  void getTextExtentUtf32(List<int> text, TextExtend extend,
      {bool typeSize = false}) {
    final Resources? res = getResources();
    assert(res != null);

    extend.width = 0;
    extend.height = 0;

    if (typeSize) {
      addGlyphToTextExtend(res!.getTextGlyph(0x70 /* p */)!, extend);
      addGlyphToTextExtend(res.getTextGlyph(0x4D /* M */)!, extend);
      extend.width = 0;
    }

    final Glyph? unknown = res!.getTextGlyph(0x6F /* o */);

    for (final int c in text) {
      Glyph? glyph = res.getTextGlyph(c);
      glyph ??= res.getGlyphByCode(c);
      if (glyph == null) {
        // There is no glyph for space, and we would use 'o' to increase the
        // extend width. However 'o' is wider than space, which led to
        // incorrect rendering. For the time being, set width to that of '.'
        // instead.
        if (c == 0x20 /* space */) {
          glyph = res.getTextGlyph(0x2E /* . */);
        } else {
          glyph = unknown;
        }
      }
      if (glyph != null) addGlyphToTextExtend(glyph, extend);
    }
  }

  void getSmuflTextExtent(String text, TextExtend extend) =>
      getSmuflTextExtentUtf32(text.runes.toList(), extend);

  void getSmuflTextExtentUtf32(List<int> text, TextExtend extend) {
    final Resources? res = getResources();
    assert(res != null);

    extend.width = 0;
    extend.height = 0;

    for (final int c in text) {
      final Glyph? glyph = res!.getGlyphByCode(c);
      if (glyph == null) continue;
      addGlyphToTextExtend(glyph, extend);
    }
  }

  void addGlyphToTextExtend(Glyph glyph, TextExtend extend) {
    var (x, y, partialWidth, partialHeight) = glyph.getBoundingBox();

    double tmp = (partialWidth * font.pointSize).toDouble();
    partialWidth = (tmp / glyph.unitsPerEm).ceil();
    tmp = (partialHeight * font.pointSize).toDouble();
    partialHeight = (tmp / glyph.unitsPerEm).ceil();
    tmp = (y * font.pointSize).toDouble();
    y = (tmp / glyph.unitsPerEm).ceil();

    int advX = glyph.horizAdvX;
    tmp = (advX * font.pointSize).toDouble();
    advX = (tmp / glyph.unitsPerEm).ceil();

    final int letterSpacing = font.letterSpacing;
    // Not the first letter — add a letter spacing.
    if (letterSpacing != 0 && extend.width > 0) {
      extend.width += letterSpacing;
    }

    extend.width += (advX == 0) ? partialWidth : advX;
    extend.height = math.max(partialHeight, extend.height);
    extend.ascent = math.max(partialHeight + y, extend.ascent);
    extend.descent = math.max(-y, extend.descent);
  }

  // -------------------------------------------------------------------------
  // Virtual interface to be implemented by concrete device contexts
  // -------------------------------------------------------------------------

  void setBackground(int color, [int style = 0]);
  void setBackgroundImage(Object? image, [double opacity = 1.0]);
  void setBackgroundMode(int mode);
  void setTextForeground(int color);
  void setTextBackground(int color);
  void setLogicalOrigin(int x, int y);

  Point getLogicalOrigin();

  void drawQuadBezierPath(List<Point> bezier);
  void drawCubicBezierPath(List<Point> bezier);
  void drawCubicBezierPathFilled(List<Point> bezier1, List<Point> bezier2);
  void drawBentParallelogramFilled(List<Point> side, int height);
  void drawCircle(int x, int y, int radius);
  void drawEllipse(int x, int y, int width, int height);
  void drawEllipticArc(
      int x, int y, int width, int height, double start, double end);
  void drawLine(int x1, int y1, int x2, int y2);
  void drawPolyline(List<Point> points, {bool close = false});
  void drawPolygon(List<Point> points);
  void drawRectangle(int x, int y, int width, int height);
  void drawRotatedText(String text, int x, int y, double angle);
  void drawRoundedRectangle(int x, int y, int width, int height, int radius);
  void drawText(String text,
      {String? wtext,
      int x = meiUnset,
      int y = meiUnset,
      int width = meiUnset,
      int height = meiUnset});
  void drawMusicText(String text, int x, int y, {bool setSmuflGlyph = false});
  void drawSpline(List<Point> points);
  void drawGraphicUri(int x, int y, int width, int height, String uri);
  void drawSvgShape(
      int x, int y, int width, int height, double scale, String svg);
  void drawBackgroundImage([int x = 0, int y = 0]);

  /// Special method for forcing bounding boxes to be updated. Used for
  /// invisible elements (e.g., `<space>`) that need to be taken into account
  /// in spacing.
  void drawPlaceholder(int x, int y) {}

  /// Method for starting and ending a text. Once started, [drawText] should
  /// be called for actually drawing the text; the font can be changed between
  /// calls.
  void startText(int x, int y,
      [HorizontalAlignment alignment = HorizontalAlignment.left]);

  void endText();

  /// Move a text to the specified position, e.g., when starting a new line.
  /// These methods must be called between [startText] and [endText].
  void moveTextTo(int x, int y, HorizontalAlignment alignment);
  void moveTextVerticallyTo(int y);

  /// Indicate if offsets should be applied.
  bool applyOffset() => false;

  /// Method for starting and ending a graphic — e.g., grouping shapes in
  /// `<g></g>` in SVG.
  void startGraphic(BoundingBox object, String gClass, String gId,
      {GraphicID graphicID = GraphicID.primary, bool prepend = false});
  void endGraphic(BoundingBox object);

  /// Method for starting/ending a custom graphic that does not correspond to
  /// an Object.
  void startCustomGraphic(String name, [String gClass = '', String gId = '']) {}
  void endCustomGraphic() {}

  /// Method for changing the color of a custom graphic.
  void setCustomGraphicColor(String color) {}

  /// Method for adding custom graphic data-* attributes.
  void setCustomGraphicAttributes(String data, String value) {}

  /// Methods for re-starting/ending a graphic for objects drawn in separate
  /// steps (can be used to group the output together, e.g., for a Beam).
  void resumeGraphic(BoundingBox object, String gId);
  void endResumedGraphic(BoundingBox object);

  /// Method for starting/ending a text graphic when it needs to be different
  /// from a normal graphic (in SVG, a text graphic is a `<tspan>`).
  void startTextGraphic(BoundingBox object, String gClass, String gId) {
    startGraphic(object, gClass, gId);
  }

  void endTextGraphic(BoundingBox object) {
    endGraphic(object);
  }

  /// Method for rotating a graphic (clockwise). Should be called only once
  /// per graphic and before drawing anything in it.
  void rotateGraphic(Point orig, double angle);

  /// Method for starting/ending a page.
  void startPage();
  void endPage();

  /// Method for adding a description element.
  void addDescription(String text) {}

  /// Method indicating whether default global styling is used (typically SVG
  /// with CSS). When used, some elements do not set corresponding styles.
  bool useGlobalStyling() => false;

  //----------------//
  // Static methods //
  //----------------//

  /// Color conversion method.
  static int rgb2Int(int red, int green, int blue) =>
      red << 16 | green << 8 | blue;
}
