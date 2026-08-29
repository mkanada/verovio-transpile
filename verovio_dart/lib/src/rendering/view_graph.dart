/// Port of `view_graph.cpp` — the graphic primitives of the `View`: lines,
/// rectangles, ellipses, polygons, dots, brackets, and the `DrawSmufl*`
/// family through which every musical glyph reaches the SVG.
///
/// This file is a `part` of the `view.dart` library (the task 05-06
/// partitioning decision: one `part` per `view_*.cpp`). The C++ continues
/// the `View` class here; Dart cannot split a class body across files, so
/// the methods are declared as members of the [ViewGraph] extension below —
/// same library, therefore the same privacy scope as the class members
/// (like the C++ member visibility from every `view_*.cpp`).
///
/// Deviations from the C++:
/// - the `DeviceContext *dc` pointers become non-nullable [DeviceContext]
///   references (the `assert(dc)` of the C++ is subsumed).
/// - `char32_t code` becomes a Unicode code point `int`; the
///   `std::u32string` becomes a Dart `String` (UTF-16 — the SMuFL code
///   points used here are all in the BMP, so one code unit per glyph).
/// - `data_HORIZONTALALIGNMENT` maps to the [HorizontalAlignment] enum of
///   `core/attdef.dart` and `PEN_SOLID` to [PenStyle.solid].
part of 'view.dart';

/// The `view_graph.cpp` methods of [View] (plus the two `view_text.cpp`
/// helpers `DrawSymbolDef` needs, [drawGraphic] and [drawSvg]).
extension ViewGraph on View {
  /// Mirrors `View::DrawVerticalLine` (view_graph.cpp:27).
  void drawVerticalLine(DeviceContext dc, int y1, int y2, int x1, int width,
      [int dashLength = 0, int gapLength = 0]) {
    dc.setPen(math.max(1, toDeviceContextX(width)), PenStyle.solid,
        dashLength: dashLength, gapLength: gapLength);

    dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
        toDeviceContextX(x1), toDeviceContextY(y2));

    dc.resetPen();
  }

  /// Mirrors `View::DrawHorizontalLine` (view_graph.cpp:40).
  void drawHorizontalLine(DeviceContext dc, int x1, int x2, int y1, int width,
      [int dashLength = 0, int gapLength = 0]) {
    dc.setPen(math.max(1, toDeviceContextX(width)), PenStyle.solid,
        dashLength: dashLength, gapLength: gapLength);

    dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
        toDeviceContextX(x2), toDeviceContextY(y1));

    dc.resetPen();
  }

  /// Mirrors `View::DrawObliqueLine` (view_graph.cpp:53).
  void drawObliqueLine(
      DeviceContext dc, int x1, int x2, int y1, int y2, int width,
      [int dashLength = 0, int gapLength = 0]) {
    dc.setPen(math.max(1, toDeviceContextX(width)), PenStyle.solid,
        dashLength: dashLength, gapLength: gapLength);

    dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
        toDeviceContextX(x2), toDeviceContextY(y2));

    dc.resetPen();
  }

  /// Mirrors `View::DrawVerticalSegmentedLine` (view_graph.cpp:66) — draws
  /// the dashed line as **separate segments**, not with `stroke-dasharray`.
  void drawVerticalSegmentedLine(
      DeviceContext dc, int x1, SegmentedLine line, int width,
      [int dashLength = 0, int gapLength = 0]) {
    for (int i = 0; i < line.segmentCount; ++i) {
      final (int start, int end) = line.getStartEnd(i);
      drawVerticalLine(dc, start, end, x1, width, dashLength, gapLength);
    }
  }

  /// Mirrors `View::DrawHorizontalSegmentedLine` (view_graph.cpp:76) —
  /// draws the dashed line as **separate segments**, not with
  /// `stroke-dasharray`.
  void drawHorizontalSegmentedLine(
      DeviceContext dc, int y1, SegmentedLine line, int width,
      [int dashLength = 0, int gapLength = 0]) {
    for (int i = 0; i < line.segmentCount; ++i) {
      final (int start, int end) = line.getStartEnd(i);
      drawHorizontalLine(dc, start, end, y1, width, dashLength, gapLength);
    }
  }

  /// Mirrors `View::DrawNotFilledEllipse` (view_graph.cpp:86).
  void drawNotFilledEllipse(
      DeviceContext dc, int x1, int y1, int x2, int y2, int lineThickness) {
    // std::swap(y1, y2)
    final int tmp = y1;
    y1 = y2;
    y2 = tmp;

    dc.setPen(lineThickness, PenStyle.solid);
    dc.setBrush(0.0);

    final int width = x2 - x1;
    final int height = y1 - y2;

    dc.drawEllipse(toDeviceContextX(x1), toDeviceContextY(y1), width, height);

    dc.resetPen();
    dc.resetBrush();
  }

  /// Mirrors `View::DrawNotFilledRectangle` (view_graph.cpp:104).
  ///
  /// The C++ quirk is preserved: the height is also converted with
  /// `ToDeviceContextX` (`ToDeviceContextX(y1 - y2)`), not with
  /// `ToDeviceContextY`.
  void drawNotFilledRectangle(
      DeviceContext dc, int x1, int y1, int x2, int y2, int lineThickness,
      [int radius = 0]) {
    // std::swap(y1, y2)
    final int tmp = y1;
    y1 = y2;
    y2 = tmp;

    final int penWidth = lineThickness;
    dc.setPen(penWidth, PenStyle.solid);
    dc.setBrush(0.0);

    dc.drawRoundedRectangle(toDeviceContextX(x1), toDeviceContextY(y1),
        toDeviceContextX(x2 - x1), toDeviceContextX(y1 - y2), radius);

    dc.resetPen();
    dc.resetBrush();
  }

  /// Draw a filled rectangle with horizontal and vertical sides
  /// (mirrors `View::DrawFilledRectangle`, view_graph.cpp:124).
  void drawFilledRectangle(DeviceContext dc, int x1, int y1, int x2, int y2) {
    drawFilledRoundedRectangle(dc, x1, y1, x2, y2, 0);
  }

  /// Mirrors `View::DrawFilledRoundedRectangle` (view_graph.cpp:133).
  void drawFilledRoundedRectangle(
      DeviceContext dc, int x1, int y1, int x2, int y2, int radius) {
    // std::swap(y1, y2)
    final int tmp = y1;
    y1 = y2;
    y2 = tmp;

    dc.setPen(0, PenStyle.solid);

    dc.drawRoundedRectangle(toDeviceContextX(x1), toDeviceContextY(y1),
        toDeviceContextX(x2 - x1), toDeviceContextX(y1 - y2), radius);

    dc.resetPen();
  }

  /// Draw an oblique quadrilateral: specifically, a parallelogram with
  /// vertical left and right sides, and with opposite vertices at (x1,y1)
  /// and (x2,y2) (mirrors `View::DrawObliquePolygon`, view_graph.cpp:151).
  ///
  /// Used by mensural ligatures and beams; the vertex order defines the
  /// filling direction.
  void drawObliquePolygon(
      DeviceContext dc, int x1, int y1, int x2, int y2, int height) {
    dc.setPen(0, PenStyle.solid);

    height = toDeviceContextX(height);
    final Point p0 = Point(toDeviceContextX(x1), toDeviceContextY(y1));
    final Point p1 = Point(toDeviceContextX(x2), toDeviceContextY(y2));
    final Point p2 = Point(p1.x, p1.y - height);
    final Point p3 = Point(p0.x, p0.y - height);

    dc.drawPolygon([p0, p1, p2, p3]);

    dc.resetPen();
  }

  /// Draw an empty ("void") diamond with its top lefthand point at (x1, y1)
  /// (mirrors `View::DrawDiamond`, view_graph.cpp:174). Both the [fill] flag
  /// and the [linewidth] change the output.
  void drawDiamond(DeviceContext dc, int x1, int y1, int height, int width,
      bool fill, int linewidth) {
    dc.setPen(linewidth, PenStyle.solid);
    if (fill) {
      dc.setBrush(1.0);
    } else {
      dc.setBrush(0.0);
    }

    final int dHeight = toDeviceContextX(height);
    final int dWidth = toDeviceContextX(width);
    final Point p0 = Point(toDeviceContextX(x1), toDeviceContextY(y1));
    final Point p1 = Point(toDeviceContextX(x1 + dWidth ~/ 2),
        toDeviceContextY(y1 + dHeight ~/ 2));
    final Point p2 = Point(p0.x + dWidth, p0.y);
    final Point p3 = Point(toDeviceContextX(x1 + dWidth ~/ 2),
        toDeviceContextY(y1 - dHeight ~/ 2));

    dc.drawPolygon([p0, p1, p2, p3]);

    dc.resetPen();
    dc.resetBrush();
  }

  /// Mirrors `View::DrawDot` (view_graph.cpp:203).
  void drawDot(DeviceContext dc, int x, int y, int staffSize,
      [bool dimin = false]) {
    int r = math.max(
        toDeviceContextX(doc!.getDrawingDoubleUnit(staffSize) ~/ 5), 2);
    if (dimin) r = (r * doc!.getOptions().graceFactor.value).toInt();

    dc.setPen(0, PenStyle.solid);

    dc.drawCircle(toDeviceContextX(x), toDeviceContextY(y), r);

    dc.resetPen();
  }

  /// Mirrors `View::DrawVerticalDots` (view_graph.cpp:215) — the dotted
  /// barline dots between [top] and [bottom] of the single-segment [line],
  /// spaced [interval] apart.
  void drawVerticalDots(DeviceContext dc, int x, SegmentedLine line,
      int barlineWidth, int interval) {
    if (line.segmentCount > 1) return;

    final (int top, int bottom) = line.getStartEnd(0);
    final int radius = math.max(barlineWidth, 2);
    int drawingPosition = top - interval ~/ 2;

    dc.setPen(0, PenStyle.solid);

    while (drawingPosition > bottom) {
      dc.drawCircle(
          toDeviceContextX(x), toDeviceContextY(drawingPosition), radius);
      drawingPosition -= interval;
    }

    dc.resetPen();
  }

  /// Mirrors `View::DrawSquareBracket` (view_graph.cpp:233).
  void drawSquareBracket(DeviceContext dc, bool leftBracket, int x, int y,
      int height, int width, int horizontalThickness, int verticalThickness) {
    final int sign = leftBracket ? 1 : -1;

    drawFilledRectangle(
        dc,
        x,
        y - horizontalThickness ~/ 2,
        x + sign * verticalThickness,
        y + height + horizontalThickness ~/ 2); // vertical
    drawFilledRectangle(dc, x, y - horizontalThickness ~/ 2, x + sign * width,
        y + horizontalThickness ~/ 2); // horizontal bottom
    drawFilledRectangle(
        dc,
        x,
        y + height - horizontalThickness ~/ 2,
        x + sign * width,
        y + height + horizontalThickness ~/ 2); // horizontal top
  }

  /// Mirrors `View::DrawEnclosingBrackets` (view_graph.cpp:248).
  void drawEnclosingBrackets(
      DeviceContext dc,
      int x,
      int y,
      int height,
      int width,
      int offset,
      int bracketWidth,
      int horizontalThickness,
      int verticalThickness) {
    drawSquareBracket(dc, true, x - offset, y - offset, height + 2 * offset,
        bracketWidth, horizontalThickness, verticalThickness);
    drawSquareBracket(
        dc,
        false,
        x + width + offset,
        y - offset,
        height + 2 * offset,
        bracketWidth,
        horizontalThickness,
        verticalThickness);
  }

  /// Mirrors `View::DrawSmuflCodeWithCustomFont` (view_graph.cpp:260-276).
  ///
  /// Deviations from the C++:
  /// - the C++ has this function commented out (view_graph.cpp:259-277 and
  ///   view.h:561-562); it is ported as live code because its body is
  ///   complete and the task's function table lists it. As in the C++ call
  ///   of `SetCurrentFont` without `allowLoading`, the custom font must
  ///   already be loaded for the swap to take effect.
  void drawSmuflCodeWithCustomFont(DeviceContext dc, String customFont, int x,
      int y, int code, int staffSize, bool dimin,
      [bool setBBGlyph = false]) {
    if (customFont.isEmpty) {
      drawSmuflCode(dc, x, y, code, staffSize, dimin, setBBGlyph);
      return;
    }

    final Resources resources = doc!.getResourcesForModification();
    final String prevFont = resources.currentFont;

    resources.setCurrentFont(customFont);

    drawSmuflCode(dc, x, y, code, staffSize, dimin, setBBGlyph);

    resources.setCurrentFont(prevFont);
  }

  /// Mirrors `View::DrawSmuflCode` (view_graph.cpp:279).
  ///
  /// Deviations from the C++:
  /// - the last parameter keeps the C++ name [setBBGlyph]; the
  ///   [DeviceContext.drawMusicText] parameter it is forwarded to is named
  ///   `setSmuflGlyph` in the port (task 05-04).
  void drawSmuflCode(
      DeviceContext dc, int x, int y, int code, int staffSize, bool dimin,
      [bool setBBGlyph = false]) {
    if (code == 0) return;

    dc.setFont(doc!.getDrawingSmuflFont(staffSize, dimin));

    dc.drawMusicText(
        String.fromCharCode(code), toDeviceContextX(x), toDeviceContextY(y),
        setSmuflGlyph: setBBGlyph);

    dc.resetFont();
  }

  /// Mirrors `View::DrawSmuflLine` (view_graph.cpp:297) — draws a line by
  /// repeating the [fill] glyph between the optional [start] / [end] glyphs
  /// (trill and pedal extenders, ...).
  ///
  /// The count of fill glyphs comes from an integer division with the
  /// explicit half-fill correction — `~/`, not `round()`.
  void drawSmuflLine(DeviceContext dc, Point orig, int length, int staffSize,
      bool dimin, int fill,
      [int start = 0, int end = 0]) {
    if (length <= 0) return;

    final int startWidth =
        (start == 0) ? 0 : doc!.getGlyphAdvX(start, staffSize, dimin);
    final int endWidth =
        (end == 0) ? 0 : doc!.getGlyphAdvX(end, staffSize, dimin);
    int fillWidth = doc!.getGlyphAdvX(fill, staffSize, dimin);

    if (fillWidth == 0) fillWidth = doc!.getGlyphWidth(fill, staffSize, dimin);

    // We add half a fill length for an average shorter / longer line result
    final int count =
        (length + fillWidth ~/ 2 - startWidth - endWidth) ~/ fillWidth;

    dc.setFont(doc!.getDrawingSmuflFont(staffSize, dimin));

    final List<int> chars = <int>[];

    if (start != 0) {
      chars.add(start);
    }

    for (int i = 0; i < count; ++i) {
      chars.add(fill);
    }

    if (end != 0) {
      chars.add(end);
    }

    dc.drawMusicText(String.fromCharCodes(chars), toDeviceContextX(orig.x),
        toDeviceContextY(orig.y));

    dc.resetFont();
  }

  /// Mirrors `View::DrawSmuflString` (view_graph.cpp:334).
  void drawSmuflString(
      DeviceContext dc, int x, int y, String s, HorizontalAlignment alignment,
      [int staffSize = 100, bool dimin = false, bool setBBGlyph = false]) {
    int xDC = toDeviceContextX(x);

    dc.setFont(doc!.getDrawingSmuflFont(staffSize, dimin));

    if (alignment == HorizontalAlignment.center) {
      final TextExtend extend = TextExtend();
      dc.getSmuflTextExtent(s, extend);
      xDC -= extend.width ~/ 2;
    } else if (alignment == HorizontalAlignment.right) {
      final TextExtend extend = TextExtend();
      dc.getSmuflTextExtent(s, extend);
      xDC -= extend.width;
    }

    dc.drawMusicText(s, xDC, toDeviceContextY(y), setSmuflGlyph: setBBGlyph);

    dc.resetFont();
  }

  /// Mirrors `View::DrawThickBezierCurve` (view_graph.cpp:359).
  ///
  /// Deviations from the C++:
  /// - `Point bezier[4]` becomes a [List] of four points.
  void drawThickBezierCurve(DeviceContext dc, List<Point> bezier, int thickness,
      int staffSize, int penWidth,
      [PenStyle penStyle = PenStyle.solid]) {
    final List<Point> bez1 = List<Point>.filled(
        4, Point()); // filled array with control points and end point
    final List<Point> bez2 = List<Point>.filled(4, Point());

    BoundingBox.calcThickBezier(bezier, thickness, bez1, bez2);

    bez1[0] = toDeviceContext(bez1[0]);
    bez1[1] = toDeviceContext(bez1[1]);
    bez1[2] = toDeviceContext(bez1[2]);
    bez1[3] = toDeviceContext(bez1[3]);

    bez2[0] = toDeviceContext(bez2[0]);
    bez2[1] = toDeviceContext(bez2[1]);
    bez2[2] = toDeviceContext(bez2[2]);
    bez2[3] = toDeviceContext(bez2[3]);

    // Actually draw it
    if (penStyle == PenStyle.solid) {
      // Solid Thick Bezier Curves are made of two beziers, filled in.
      dc.setPen(
          math.max(1, doc!.getDrawingStemWidth(staffSize) ~/ 2), penStyle);
      dc.drawCubicBezierPathFilled(bez1, bez2);
    } else {
      // Dashed or Dotted Thick Bezier Curves have a uniform line width.
      dc.setPen(thickness, penStyle);
      dc.drawCubicBezierPath(bez1);
    }
    dc.resetPen();
  }

  /// Mirrors `View::DrawSymbolDef` (view_graph.cpp:392) — draws a
  /// `<symbolDef>` of the MEI (its `<graphic>` and `<svg>` children).
  void drawSymbolDef(DeviceContext dc, Object parent, SymbolDef symbolDef,
      int x, int y, int staffSize, bool dimin,
      [HorizontalAlignment alignment = HorizontalAlignment.left]) {
    final TextDrawingParams params = TextDrawingParams();
    params.x = x;
    params.y = y;

    // Because image y coordinates are inverted we need to adjust the y position
    params.y += symbolDef.getSymbolHeight(doc!, staffSize, dimin);

    if (alignment != HorizontalAlignment.left) {
      final int width = symbolDef.getSymbolWidth(doc!, staffSize, dimin);
      params.x -=
          (alignment == HorizontalAlignment.center) ? (width ~/ 2) : width;
    }

    // Because thg Svg is a child of symbolDef we need to temporarily change
    // the parent for the bounding boxes to be properly propagated in the
    // device context ("thg" is the C++ comment's own typo)
    symbolDef.setTemporaryParent(parent);

    for (final Object current in symbolDef.children) {
      if (current.classId == ClassId.graphic) {
        final Graphic graphic = current as Graphic;
        drawGraphic(dc, graphic, params, staffSize, dimin);
      }
      if (current.classId == ClassId.svg) {
        final Svg svg = current as Svg;
        drawSvg(dc, svg, params, staffSize, dimin);
      }
    }

    symbolDef.resetTemporaryParent();
  }

  // `DrawGraphic` / `DrawSvg` (view_text.cpp:536-583) have moved to
  // `view_text.dart` (task 05-19). `DrawSymbolDef` still calls them; the call
  // resolves through the `ViewText` extension in the same library.
}
