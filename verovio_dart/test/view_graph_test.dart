/// Tests for `lib/src/rendering/view_graph.dart` (task 05-07) — the `View`
/// graphic primitives ported from `origin/src/src/view_graph.cpp` (430
/// lines): lines, rectangles, ellipses, polygons, dots, brackets, the
/// `DrawSmufl*` family and `DrawSymbolDef` (plus the two `view_text.cpp`
/// helpers `DrawGraphic` / `DrawSvg` that `DrawSymbolDef` needs).
///
/// The tests draw through the real `View` on an `SvgDeviceContext` and
/// compare exact strings — the same technique as `svg_device_context_test`
/// (task 05-03). Device Y coordinates are the logical Y flipped around the
/// page content height (2970 in this suite).
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart' show HorizontalAlignment;
import 'package:verovio_dart/src/core/bounding_box.dart' show SegmentedLine;
import 'package:verovio_dart/src/core/devicecontextbase.dart' show PenStyle;
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/smufl.dart' show smuflE050Gclef;
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show MeasurementSigned;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/svg_device_context.dart';
import 'package:verovio_dart/src/rendering/view.dart';

/// The page content height used by every test (`Doc.drawingPageContentHeight`).
const int kContentHeight = 2970;

/// The device Y of a logical Y (the `View` flips around the content height).
int dy(int y) => kContentHeight - y;

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
  });

  /// Draws on a fresh context (with the fonts loaded — `DrawMusicText` needs
  /// the glyph tables) through the [View] and serializes the whole document,
  /// so the tests compare exact strings against literals derived from the
  /// C++ output.
  String drawOne(void Function(View view, SvgDeviceContext dc) draw,
      {String docId = 'docid'}) {
    final Doc doc = Doc()..drawingPageContentHeight = kContentHeight;
    // Mirrors Doc::UpdatePageDrawingSizes (doc.cpp:2394, CalcMusicFontSize =
    // unit * 8 = 720 with the definition-factored unit of 90).
    doc.drawingSmuflFontSize = doc.getOptions().unit.value.toInt() * 8;
    final View view = View()..setDoc(doc);
    // The device context shares the document resources — the same wiring
    // DrawCurrentPage uses in the C++ (view_page.cpp).
    final Resources resources = doc.getResourcesForModification();
    expect(resources.initFonts(), isTrue);
    final SvgDeviceContext dc = SvgDeviceContext(docId);
    dc.setResources(resources);
    draw(view, dc);
    return dc.getStringSVG();
  }

  /// The document the C++ produces around the given elements drawn on a
  /// fresh context (default indent of 2; zero width/height).
  String envelope(String elements) {
    final String elementLines = elements.isEmpty
        ? ''
        : '${elements.split('\n').map((l) => '  $l').join('\n')}\n';
    return '<svg width="0px" height="0px" version="1.1" '
        'xmlns="http://www.w3.org/2000/svg" '
        'xmlns:xlink="http://www.w3.org/1999/xlink" overflow="visible" '
        'id="docid">\n'
        '  <desc>Engraved by Verovio 6.2.0</desc>\n'
        '$elementLines'
        '</svg>\n';
  }

  /// Normalizes indentation so blocks extracted from the golden (deeper in
  /// the document tree) can be compared with the ones drawn here.
  String unindent(String block) =>
      block.split('\n').map((l) => l.trim()).join('\n');

  group('ViewGraph — lines (view_graph.cpp:27-84)', () {
    test('drawVerticalLine', () {
      final String svg = drawOne((view, dc) {
        view.drawVerticalLine(dc, 100, 200, 50, 3);
      });
      expect(
          svg,
          envelope(
              '<path d="M50 ${dy(100)} L50 ${dy(200)}" stroke-width="3" />'));
    });

    test('drawVerticalLine pen width is at least 1 and dashes pass through',
        () {
      final String svg = drawOne((view, dc) {
        // width 0: std::max(1, 0) = 1; dashLength/gapLength forwarded.
        view.drawVerticalLine(dc, 0, 100, 30, 0, 4, 8);
      });
      expect(
          svg,
          envelope('<path d="M30 ${dy(0)} L30 ${dy(100)}" stroke-width="1" '
              'stroke-dasharray="4 8" />'));
    });

    test('drawHorizontalLine', () {
      final String svg = drawOne((view, dc) {
        view.drawHorizontalLine(dc, 10, 60, 40, 2);
      });
      expect(
          svg,
          envelope(
              '<path d="M10 ${dy(40)} L60 ${dy(40)}" stroke-width="2" />'));
    });

    test('drawObliqueLine', () {
      final String svg = drawOne((view, dc) {
        view.drawObliqueLine(dc, 10, 60, 40, 80, 2);
      });
      expect(
          svg,
          envelope(
              '<path d="M10 ${dy(40)} L60 ${dy(80)}" stroke-width="2" />'));
    });

    test('drawVerticalSegmentedLine draws separate segments', () {
      final String svg = drawOne((view, dc) {
        final SegmentedLine line = SegmentedLine(0, 100)..addGap(40, 60);
        view.drawVerticalSegmentedLine(dc, 30, line, 2);
      });
      // The dashed line is a pair of <path> elements, not stroke-dasharray.
      expect(
          svg,
          envelope('<path d="M30 ${dy(0)} L30 ${dy(40)}" stroke-width="2" />\n'
              '<path d="M30 ${dy(60)} L30 ${dy(100)}" stroke-width="2" />'));
    });

    test('drawHorizontalSegmentedLine draws separate segments', () {
      final String svg = drawOne((view, dc) {
        final SegmentedLine line = SegmentedLine(0, 100)..addGap(40, 60);
        view.drawHorizontalSegmentedLine(dc, 50, line, 2);
      });
      expect(
          svg,
          envelope('<path d="M0 ${dy(50)} L40 ${dy(50)}" stroke-width="2" />\n'
              '<path d="M60 ${dy(50)} L100 ${dy(50)}" stroke-width="2" />'));
    });
  });

  group('ViewGraph — shapes (view_graph.cpp:86-201)', () {
    test('drawNotFilledEllipse swaps y and sets an empty brush', () {
      final String svg = drawOne((view, dc) {
        view.drawNotFilledEllipse(dc, 10, 20, 50, 60, 2);
      });
      // After std::swap(y1, y2): origin (10, 60), w = 40, h = 40.
      expect(
          svg,
          envelope('<ellipse cx="30" cy="${dy(60) + 20}" rx="20" ry="20" '
              'fill-opacity="0" stroke-width="2" />'));
    });

    test('drawNotFilledRectangle (radius 0)', () {
      final String svg = drawOne((view, dc) {
        view.drawNotFilledRectangle(dc, 10, 20, 50, 60, 2);
      });
      // Note the C++ quirk: the height also goes through ToDeviceContextX.
      expect(
          svg,
          envelope('<rect stroke-width="2" fill-opacity="0" x="10" '
              'y="${dy(60)}" height="40" width="40" />'));
    });

    test('drawNotFilledRectangle (radius 5)', () {
      final String svg = drawOne((view, dc) {
        view.drawNotFilledRectangle(dc, 10, 20, 50, 60, 2, 5);
      });
      expect(
          svg,
          envelope('<rect stroke-width="2" fill-opacity="0" x="10" '
              'y="${dy(60)}" height="40" width="40" rx="5" />'));
    });

    test('drawFilledRectangle delegates to radius 0', () {
      final String svg = drawOne((view, dc) {
        view.drawFilledRectangle(dc, 10, 20, 50, 60);
      });
      // Pen 0 (no stroke-width) and the default brush (no fill attribute).
      expect(svg,
          envelope('<rect x="10" y="${dy(60)}" height="40" width="40" />'));
    });

    test('drawFilledRoundedRectangle', () {
      final String svg = drawOne((view, dc) {
        view.drawFilledRoundedRectangle(dc, 10, 20, 50, 60, 5);
      });
      expect(
          svg,
          envelope(
              '<rect x="10" y="${dy(60)}" height="40" width="40" rx="5" />'));
    });

    test('drawObliquePolygon keeps the vertex order', () {
      final String svg = drawOne((view, dc) {
        view.drawObliquePolygon(dc, 10, 100, 50, 200, 30);
      });
      // p0 (10,100), p1 (50,200), p2 (p1 shifted by the height), p3 (p0
      // shifted): the order defines the filling direction.
      expect(
          svg,
          envelope('<polygon points="10,${dy(100)} 50,${dy(200)} '
              '50,${dy(200) - 30} 10,${dy(100) - 30}" />'));
    });

    test('drawDiamond without fill', () {
      final String svg = drawOne((view, dc) {
        view.drawDiamond(dc, 10, 100, 60, 40, false, 2);
      });
      expect(
          svg,
          envelope('<polygon stroke-width="2" fill-opacity="0" '
              'points="10,${dy(100)} 30,${dy(130)} 50,${dy(100)} '
              '30,${dy(70)}" />'));
    });

    test('drawDiamond with fill', () {
      final String svg = drawOne((view, dc) {
        view.drawDiamond(dc, 10, 100, 60, 40, true, 2);
      });
      expect(
          svg,
          envelope('<polygon stroke-width="2" fill-opacity="1" '
              'points="10,${dy(100)} 30,${dy(130)} 50,${dy(100)} '
              '30,${dy(70)}" />'));
    });
  });

  group('ViewGraph — dots (view_graph.cpp:203-231)', () {
    test('drawDot uses a fifth of the double unit (36 at staffSize 100)', () {
      final String svg = drawOne((view, dc) {
        view.drawDot(dc, 90, 100, 100);
      });
      // r = max(180 / 5, 2) = 36 (unit 9.0 * definitionFactor = 90).
      expect(
          svg, envelope('<ellipse cx="90" cy="${dy(100)}" rx="36" ry="36" />'));
    });

    test('drawDot scales by the grace factor for dimin', () {
      final String svg = drawOne((view, dc) {
        view.drawDot(dc, 90, 100, 100, true);
      });
      // r = (36 * 0.75).toInt() = 27.
      expect(
          svg, envelope('<ellipse cx="90" cy="${dy(100)}" rx="27" ry="27" />'));
    });

    test('drawVerticalDots draws the dots of a single segment', () {
      final String svg = drawOne((view, dc) {
        // Decreasing line: top = 200, bottom = 0. interval 100: dots at
        // 150 and 50; radius = max(3, 2) = 3.
        final SegmentedLine line = SegmentedLine(200, 0);
        view.drawVerticalDots(dc, 40, line, 3, 100);
      });
      expect(
          svg,
          envelope('<ellipse cx="40" cy="${dy(150)}" rx="3" ry="3" />\n'
              '<ellipse cx="40" cy="${dy(50)}" rx="3" ry="3" />'));
    });

    test('drawVerticalDots refuses a multi-segment line', () {
      final String svg = drawOne((view, dc) {
        final SegmentedLine line = SegmentedLine(200, 0)..addGap(80, 120);
        expect(line.segmentCount, 2);
        view.drawVerticalDots(dc, 40, line, 3, 100);
      });
      expect(svg, envelope(''));
    });
  });

  group('ViewGraph — brackets (view_graph.cpp:233-257)', () {
    test('drawSquareBracket left draws the three filled rectangles', () {
      final String svg = drawOne((view, dc) {
        view.drawSquareBracket(dc, true, 100, 200, 300, 40, 10, 20);
      });
      // sign = 1; ht/2 = 5. Vertical: (100, 195, 120, 505); bottom:
      // (100, 195, 140, 205); top: (100, 495, 140, 505). Device y = 2970-y.
      expect(
          svg,
          envelope('<rect x="100" y="${dy(505)}" height="310" width="20" />\n'
              '<rect x="100" y="${dy(205)}" height="10" width="40" />\n'
              '<rect x="100" y="${dy(505)}" height="10" width="40" />'));
    });

    test('drawSquareBracket right mirrors the sign', () {
      final String svg = drawOne((view, dc) {
        view.drawSquareBracket(dc, false, 100, 200, 300, 40, 10, 20);
      });
      // sign = -1: the horizontal extents go to the left.
      expect(
          svg,
          envelope('<rect x="80" y="${dy(505)}" height="310" width="20" />\n'
              '<rect x="60" y="${dy(205)}" height="10" width="40" />\n'
              '<rect x="60" y="${dy(505)}" height="10" width="40" />'));
    });

    test('drawEnclosingBrackets draws both brackets with the offset', () {
      final String svg = drawOne((view, dc) {
        view.drawEnclosingBrackets(dc, 100, 200, 300, 40, 10, 40, 10, 20);
      });
      // Left bracket at x = 90, right at x = 100 + 40 + 10 = 150.
      expect(
          svg,
          envelope('<rect x="90" y="${dy(515)}" height="330" width="20" />\n'
              '<rect x="90" y="${dy(195)}" height="10" width="40" />\n'
              '<rect x="90" y="${dy(515)}" height="10" width="40" />\n'
              '<rect x="130" y="${dy(515)}" height="330" width="20" />\n'
              '<rect x="110" y="${dy(195)}" height="10" width="40" />\n'
              '<rect x="110" y="${dy(515)}" height="10" width="40" />'));
    });
  });

  group('ViewGraph — SMuFL family (view_graph.cpp:259-357)', () {
    test('drawSmuflCode with code 0 draws nothing', () {
      final String svg = drawOne((view, dc) {
        view.drawSmuflCode(dc, 10, 20, 0, 100, false);
      });
      expect(svg, envelope(''));
      expect(svg.contains('<defs>'), isFalse);
    });

    test(
        'drawSmuflCode reproduces the E050 <use>/<defs> of the note-001 golden',
        () {
      final String svg = drawOne((view, dc) {
        // The clef <use> of test/golden/cpp/note/note-001.svg is
        // translate(90, 1807); the logical y flips around the content height.
        view.drawSmuflCode(
            dc, 90, kContentHeight - 1807, smuflE050Gclef, 100, false);
      }, docId: 'o3u8kcw');

      final String goldenText =
          File('test/golden/cpp/note/note-001.svg').readAsStringSync();
      final String goldenUse = RegExp(r'<use[^>]*E050-o3u8kcw[^>]*/>')
          .firstMatch(goldenText)!
          .group(0)!;
      final String goldenDefs = RegExp(r'<g id="E050-o3u8kcw">[\s\S]*?</g>')
          .firstMatch(goldenText)!
          .group(0)!;

      // Same font size chain (CalcMusicFontSize = unit * 8 = 720 → scale
      // 0.72), same <defs> id (the doc id), same glyph path.
      expect(
          svg,
          contains('<use xlink:href="#E050-o3u8kcw" '
              'transform="translate(90, 1807) scale(0.72, 0.72)" />'));
      expect(unindent(svg), contains(unindent(goldenUse)));
      expect(
          unindent(RegExp(r'<g id="E050-o3u8kcw">[\s\S]*?</g>')
              .firstMatch(svg)!
              .group(0)!),
          unindent(goldenDefs));
    });

    test('drawSmuflCodeWithCustomFont falls back on an empty font name', () {
      final String withEmpty = drawOne((view, dc) {
        view.drawSmuflCodeWithCustomFont(
            dc, '', 90, kContentHeight - 1807, smuflE050Gclef, 100, false);
      });
      final String direct = drawOne((view, dc) {
        view.drawSmuflCode(
            dc, 90, kContentHeight - 1807, smuflE050Gclef, 100, false);
      });
      expect(withEmpty, direct);
    });

    test('drawSmuflCodeWithCustomFont swaps the font for the glyph', () {
      final String bravura = drawOne((view, dc) {
        view.drawSmuflCodeWithCustomFont(dc, 'Bravura', 90,
            kContentHeight - 1807, smuflE050Gclef, 100, false);
      });
      // The glyph comes from the swapped font: the bounding-box XML of both
      // fonts shares units-per-em 1000 (so the scale is unchanged), but the
      // <defs> path is the Bravura one, not the Leipzig one.
      final String leipzig = drawOne((view, dc) {
        view.drawSmuflCode(
            dc, 90, kContentHeight - 1807, smuflE050Gclef, 100, false);
      });
      final String? bravuraDefs = RegExp(r'<g id="E050-docid">[\s\S]*?</g>')
          .firstMatch(bravura)
          ?.group(0);
      final String? leipzigDefs = RegExp(r'<g id="E050-docid">[\s\S]*?</g>')
          .firstMatch(leipzig)
          ?.group(0);
      expect(bravuraDefs, isNotNull);
      expect(leipzigDefs, isNotNull);
      expect(bravuraDefs, isNot(leipzigDefs));
    });

    test('drawSmuflLine repeats the fill glyph per the integer count', () {
      final String svg = drawOne((view, dc) {
        view.drawSmuflLine(dc, Point(100, kContentHeight - 500), 1000, 100,
            false, smuflE050Gclef);
      });

      // fillWidth comes from Doc::GetGlyphAdvX (the documented headless
      // approximation: 1.75 staff spaces → 315 at the unit of 90); count =
      // (1000 + 315/2 - 0 - 0) / 315 = 3 (integer division).
      expect(RegExp(r'<use ').allMatches(svg).length, 3);
      expect(
          svg,
          contains('<use xlink:href="#E050-docid" '
              'transform="translate(100, 500) scale(0.72, 0.72)" />'));
      // The three uses advance by the real glyph advance of the font
      // (6460 * 720 / 10000 = 465, truncated).
      expect(svg,
          contains('transform="translate(565, 500) scale(0.72, 0.72)" />'));
      expect(svg,
          contains('transform="translate(1030, 500) scale(0.72, 0.72)" />'));
    });

    test('drawSmuflLine with a non positive length draws nothing', () {
      final String svg = drawOne((view, dc) {
        view.drawSmuflLine(dc, Point(100, kContentHeight - 500), 0, 100, false,
            smuflE050Gclef);
      });
      expect(svg, envelope(''));
    });

    test('drawSmuflString draws left aligned without extent', () {
      final String svg = drawOne((view, dc) {
        view.drawSmuflString(dc, 100, kContentHeight - 500,
            String.fromCharCode(smuflE050Gclef), HorizontalAlignment.left);
      });
      expect(
          svg,
          contains('<use xlink:href="#E050-docid" '
              'transform="translate(100, 500) scale(0.72, 0.72)" />'));
    });

    test('drawSmuflString shifts by half the extent for center', () {
      final String svg = drawOne((view, dc) {
        view.drawSmuflString(dc, 100, kContentHeight - 500,
            String.fromCharCode(smuflE050Gclef), HorizontalAlignment.center);
      });
      // extend.width for E050 at point size 720: ceil(6460 * 720 / 10000)
      // = 466; xDC = 100 - 466 / 2 = 100 - 233 = -133.
      expect(svg,
          contains('transform="translate(-133, 500) scale(0.72, 0.72)" />'));
    });

    test('drawSmuflString shifts by the extent for right', () {
      final String svg = drawOne((view, dc) {
        view.drawSmuflString(dc, 1000, kContentHeight - 500,
            String.fromCharCode(smuflE050Gclef), HorizontalAlignment.right);
      });
      // xDC = 1000 - 466 = 534.
      expect(svg,
          contains('transform="translate(534, 500) scale(0.72, 0.72)" />'));
    });
  });

  group('ViewGraph — bezier and symbolDef (view_graph.cpp:359-430)', () {
    test('drawThickBezierCurve fills between two beziers when solid', () {
      final String svg = drawOne((view, dc) {
        view.drawThickBezierCurve(
            dc,
            [
              Point(0, 100),
              Point(100, 100),
              Point(200, 100),
              Point(300, 100),
            ],
            10,
            100,
            2);
      });
      // A flat curve: the control points shift by thickness/2 (5). The pen
      // is max(1, stemWidth / 2) = max(1, 18 / 2) = 9. The second bezier is
      // appended backwards.
      expect(
          svg,
          envelope('<path d="M0,${dy(100)} C100,${dy(105)} 200,${dy(105)} '
              '300,${dy(100)} C200,${dy(95)} 100,${dy(95)} 0,${dy(100)}" '
              'stroke-width="9" stroke-linecap="round" '
              'stroke-linejoin="round" />'));
    });

    test('drawThickBezierCurve draws a uniform dashed line otherwise', () {
      final String svg = drawOne((view, dc) {
        view.drawThickBezierCurve(
            dc,
            [
              Point(0, 100),
              Point(100, 100),
              Point(200, 100),
              Point(300, 100),
            ],
            10,
            100,
            2,
            PenStyle.shortDash);
      });
      // setPen(thickness, style): shortDash → dash 2 * 10, gap 3 * 10.
      expect(
          svg,
          envelope('<path d="M0,${dy(100)} C100,${dy(105)} 200,${dy(105)} '
              '300,${dy(100)}" fill="none" stroke-width="10" '
              'stroke-linecap="round" stroke-linejoin="round" '
              'stroke-dasharray="20 30" />'));
    });

    test('drawSymbolDef draws an <svg> child shifted by the symbol height', () {
      final String svg = drawOne((view, dc) {
        // The symbolDef lives in a symbolTable (its C++ parent) and is drawn
        // with a symbol as the temporary parent for the bounding boxes.
        final SymbolTable symbolTable = SymbolTable();
        final SymbolDef symbolDef = SymbolDef();
        final Symbol symbol = Symbol();
        symbolTable.addChild(symbolDef);
        final Svg svgChild = Svg()
          ..content = '<svg width="100" height="50"><circle r="10" /></svg>';
        symbolDef.addChild(svgChild);
        view.drawSymbolDef(dc, symbol, symbolDef, 1500, 200, 100, false);
      });
      // Symbol height = 50 * 10 * 100 / 100 = 500; params.y = 200 + 500 =
      // 700 (left alignment: no x shift). The <svg> is drawn at device y
      // 2270 with scale 1 * definitionFactor.
      expect(
          svg,
          contains('<g class="svg" transform="translate(1500, ${dy(700)}) '
              'scale(10.000000, 10.000000)">'));
      expect(svg, contains('<circle r="10" />'));
    });

    test('drawSymbolDef shifts x for center and right alignment', () {
      String symbolAt(HorizontalAlignment alignment) {
        return drawOne((view, dc) {
          final SymbolTable symbolTable = SymbolTable();
          final SymbolDef symbolDef = SymbolDef();
          final Symbol symbol = Symbol();
          symbolTable.addChild(symbolDef);
          final Svg svgChild = Svg()
            ..content = '<svg width="100" height="50"><circle r="10" /></svg>';
          symbolDef.addChild(svgChild);
          view.drawSymbolDef(
              dc, symbol, symbolDef, 1500, 200, 100, false, alignment);
        });
      }

      // width = 1000: center → 1500 - 500 = 1000; right → 1500 - 1000 = 500.
      expect(
          symbolAt(HorizontalAlignment.center),
          contains(
              '<g class="svg" transform="translate(1000, ${dy(700)}) scale(10.000000, 10.000000)">'));
      expect(
          symbolAt(HorizontalAlignment.right),
          contains(
              '<g class="svg" transform="translate(500, ${dy(700)}) scale(10.000000, 10.000000)">'));
    });

    test('drawSymbolDef draws a <graphic> child through DrawGraphic', () {
      final String svg = drawOne((view, dc) {
        final SymbolTable symbolTable = SymbolTable();
        final SymbolDef symbolDef = SymbolDef();
        final Symbol symbol = Symbol();
        symbolTable.addChild(symbolDef);
        final Graphic graphic = Graphic()
          ..target = 'img.png'
          ..width = (MeasurementSigned()..setVu(2.0))
          ..height = (MeasurementSigned()..setVu(1.5));
        symbolDef.addChild(graphic);
        view.drawSymbolDef(dc, symbol, symbolDef, 100, 200, 100, false);
      });
      // Width = 2.0 * unit (90) = 180; height = 135; params.y = 200 + 135.
      // DrawGraphic starts the graphic with the SYMBOLREF id.
      expect(svg, contains('symbol-ref'));
      expect(
          svg,
          contains('<image xlink:href="img.png" x="100" y="${dy(335)}" '
              'width="180" height="135" />'));
    });
  });
}
