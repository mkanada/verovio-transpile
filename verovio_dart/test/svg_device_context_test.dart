import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart' show HorizontalAlignment;
import 'package:verovio_dart/src/core/devicecontextbase.dart'
    show
        FontInfo,
        LineCapStyle,
        LineJoinStyle,
        PenStyle,
        colorLightGrey,
        colorNone;
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/svg_device_context.dart';

void main() {
  group('SvgDeviceContext', () {
    test('minimal document matches the C++ output byte for byte', () {
      final SvgDeviceContext dc = SvgDeviceContext('o3u8kcw');
      dc.setResources(Resources());
      dc.width = 2100;
      dc.height = 2970;
      dc.contentHeight = 2970;
      dc.indent = 3;

      dc.startPage();

      final Measure measure = Measure();
      final Staff staff = Staff();
      staff.drawingStaffDef = StaffDef();
      dc.startGraphic(measure, '', 'm1');
      dc.startGraphic(staff, '', 's1');
      dc.endGraphic(staff);
      dc.endGraphic(measure);

      dc.endPage();

      const String expected =
          '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n'
          '<svg width="2100px" height="2970px" version="1.1" '
          'xmlns="http://www.w3.org/2000/svg" '
          'xmlns:xlink="http://www.w3.org/1999/xlink" overflow="visible" '
          'id="o3u8kcw">\n'
          '   <desc>Engraved by Verovio 6.2.0</desc>\n'
          '   <style type="text/css">#o3u8kcw g.ending, #o3u8kcw g.fing, '
          '#o3u8kcw g.reh, #o3u8kcw g.tempo {font-weight:bold;}'
          '#o3u8kcw g.dir, #o3u8kcw g.dynam, #o3u8kcw g.mNum '
          '{font-style:italic;}#o3u8kcw g.label {font-weight:normal;}'
          '#o3u8kcw ellipse, #o3u8kcw path, #o3u8kcw polygon, '
          '#o3u8kcw polyline, #o3u8kcw rect {stroke:currentColor}</style>\n'
          '   <svg class="definition-scale" color="black" '
          'font-family="Times, serif" viewBox="0 0 21000 29700">\n'
          '      <g class="page-margin" transform="translate(0, 0)">\n'
          '         <g id="m1" class="measure">\n'
          '            <g id="s1" class="staff" />\n'
          '         </g>\n'
          '      </g>\n'
          '   </svg>\n'
          '</svg>\n';
      // Exact string equality, mirroring the C++ output for a trivial page.
      expect(dc.getStringSVG(true), expected);
    });

    test('appendIdAndClass with id', () {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      dc.startCustomGraphic('note', '', 'g1');
      expect(dc.currentNode.attr('id'), 'g1');
      expect(dc.currentNode.attr('class'), 'note');
      expect(dc.currentNode.hasAttr('data-id'), isFalse);
    });

    test('appendIdAndClass without id', () {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      dc.startCustomGraphic('measure', 'extra');
      expect(dc.currentNode.hasAttr('id'), isFalse);
      expect(dc.currentNode.attr('class'), 'measure extra');
    });

    test('appendIdAndClass spanning and symbol-ref', () {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      dc.startCustomGraphic('g');
      dc.appendIdAndClass('g2', 'beam', '', GraphicID.spanning);
      expect(dc.currentNode.attr('class'), 'beam id-g2 spanning');
      expect(dc.currentNode.hasAttr('id'), isFalse);
      dc.endCustomGraphic();

      dc.startCustomGraphic('g');
      dc.appendIdAndClass('g3', 'slur', 'added', GraphicID.symbolRef);
      expect(dc.currentNode.attr('class'), 'slur id-g3 symbol-ref added');
      expect(dc.currentNode.hasAttr('id'), isFalse);
    });

    test('appendIdAndClass html5 uses data attributes', () {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      dc.html5 = true;
      dc.startCustomGraphic('note', '', 'g1');
      expect(dc.currentNode.attr('data-id'), 'g1');
      expect(dc.currentNode.attr('data-class'), 'note');
      expect(dc.currentNode.hasAttr('id'), isFalse);
    });

    test('resumeGraphic reopens a closed group', () {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      dc.setResources(Resources());
      dc.indent = 3;
      dc.startPage();

      final Measure measure = Measure();
      dc.startGraphic(measure, '', 'm1');
      dc.endGraphic(measure);
      dc.resumeGraphic(measure, 'm1');
      dc.addDescription('resumed content');
      dc.endResumedGraphic(measure);

      dc.endPage();

      final String svg = dc.getStringSVG();
      expect(
          svg,
          contains('<g id="m1" class="measure">\n'
              '            <desc>resumed content</desc>\n'
              '         </g>'));
    });

    test('logical origin is negated', () {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      dc.setLogicalOrigin(10, 20);
      expect(dc.getLogicalOrigin(), Point(-10, -20));
    });
  });

  group('SvgDeviceContext primitives (05-03)', () {
    // The document the C++ produces around a single primitive drawn on a
    // fresh context (default indent of 2; zero width/height).
    String envelope(String element, {String unit = 'px'}) {
      final String elementLine = element.isEmpty ? '' : '  $element\n';
      return '<svg width="0$unit" height="0$unit" version="1.1" '
          'xmlns="http://www.w3.org/2000/svg" '
          'xmlns:xlink="http://www.w3.org/1999/xlink" overflow="visible" '
          'id="docid">\n'
          '  <desc>Engraved by Verovio 6.2.0</desc>\n'
          '$elementLine'
          '</svg>\n';
    }

    /// Draws on a fresh context and serializes the whole document, so the
    /// tests compare exact strings against literals derived from the C++.
    /// The resources are set because `DrawSvgBoundingBox` asserts on them.
    String drawOne(void Function(SvgDeviceContext dc) draw) {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      dc.setResources(Resources());
      draw(dc);
      return dc.getStringSVG();
    }

    test('getColor maps the named colors and formats the rest as #%06X', () {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      expect(dc.getColor(colorNone), 'currentColor');
      expect(dc.getColor(0x000000), '#000000');
      expect(dc.getColor(0xFFFFFF), '#FFFFFF');
      expect(dc.getColor(0xFF0000), '#FF0000');
      expect(dc.getColor(0x00FF00), '#00FF00');
      expect(dc.getColor(0x0000FF), '#0000FF');
      expect(dc.getColor(0x00FFFF), '#00FFFF');
      // COLOR_LIGHT_GREY (0x7F7F7F) maps to a literal of its own in the C++.
      expect(dc.getColor(colorLightGrey), '#777777');
      expect(dc.getColor(0x12345), '#012345');
      expect(dc.getColor(0x123456), '#123456');
    });

    test('drawLine with the default pen', () {
      final String svg = drawOne((dc) => dc.drawLine(1, 2, 30, 40));
      expect(svg, envelope('<path d="M1 2 L30 40" stroke-width="1" />'));
    });

    test('drawLine with color, opacity, line cap and dash array', () {
      final String svg = drawOne((dc) {
        dc.setPen(3, PenStyle.dot,
            lineCap: LineCapStyle.round, color: 0xFF00FF, opacity: 0.5);
        dc.drawLine(1, 2, 30, 40);
      });
      // PEN_DOT: dashLength 1, gapLength width*3 = 9.
      expect(
          svg,
          envelope('<path d="M1 2 L30 40" stroke-width="3" stroke="#FF00FF" '
              'stroke-opacity="0.5" stroke-linecap="round" '
              'stroke-dasharray="1 9" />'));
    });

    test('drawLine without global styling always writes the stroke', () {
      final String svg = drawOne((dc) {
        dc.mmOutput = true;
        dc.drawLine(1, 2, 3, 4);
      });
      expect(
          svg,
          envelope(
              '<path d="M1 2 L3 4" stroke-width="1" '
              'stroke="currentColor" />',
              unit: 'mm'));
    });

    test('drawQuadBezierPath', () {
      final String svg = drawOne((dc) =>
          dc.drawQuadBezierPath([Point(1, 2), Point(3, 4), Point(5, 6)]));
      expect(
          svg,
          envelope('<path d="M1,2 Q3,4 5,6" fill="none" stroke-width="1" '
              'stroke-linecap="round" stroke-linejoin="round" />'));
    });

    test('drawQuadBezierPath with a colored pen', () {
      final String svg = drawOne((dc) {
        dc.setPen(4, PenStyle.solid, color: 0x00FF00);
        dc.drawQuadBezierPath([Point(1, 2), Point(3, 4), Point(5, 6)]);
      });
      expect(
          svg,
          envelope('<path d="M1,2 Q3,4 5,6" fill="none" stroke-width="4" '
              'stroke="#00FF00" stroke-linecap="round" '
              'stroke-linejoin="round" />'));
    });

    test('drawCubicBezierPath', () {
      final String svg = drawOne((dc) => dc.drawCubicBezierPath(
          [Point(1, 2), Point(3, 4), Point(5, 6), Point(7, 8)]));
      expect(
          svg,
          envelope('<path d="M1,2 C3,4 5,6 7,8" fill="none" stroke-width="1" '
              'stroke-linecap="round" stroke-linejoin="round" />'));
    });

    test('drawCubicBezierPathFilled walks the second bezier backwards', () {
      final String svg = drawOne((dc) {
        dc.setPen(2, PenStyle.solid, color: 0x123456);
        dc.drawCubicBezierPathFilled(
            [Point(1, 2), Point(3, 4), Point(5, 6), Point(7, 8)],
            [Point(9, 8), Point(7, 6), Point(5, 4), Point(3, 2)]);
      });
      // The second bezier is appended as C bezier2[2] bezier2[1] bezier2[0],
      // and there is no fill attribute.
      expect(
          svg,
          envelope('<path d="M1,2 C3,4 5,6 7,8 C5,4 7,6 9,8" '
              'stroke-width="2" stroke="#123456" stroke-linecap="round" '
              'stroke-linejoin="round" />'));
    });

    test('drawBentParallelogramFilled', () {
      final String svg = drawOne((dc) => dc.drawBentParallelogramFilled(
          [Point(0, 0), Point(10, 0), Point(10, 10), Point(0, 10)], 5));
      expect(
          svg,
          envelope('<path d="M0,0 C10,0 10,10 0,10 L0,15 C10,15 10,5 0,5 Z" '
              'stroke-width="1" stroke-linecap="round" '
              'stroke-linejoin="round" />'));
    });

    test('drawCircle delegates to drawEllipse', () {
      final String svg = drawOne((dc) => dc.drawCircle(10, 20, 5));
      expect(
          svg,
          envelope(
              '<ellipse cx="10" cy="20" rx="5" ry="5" stroke-width="1" />'));
    });

    test('drawEllipse with the default pen and brush', () {
      final String svg = drawOne((dc) => dc.drawEllipse(10, 20, 30, 40));
      expect(
          svg,
          envelope(
              '<ellipse cx="25" cy="40" rx="15" ry="20" stroke-width="1" />'));
    });

    test('drawEllipse with brush opacity and pen opacity', () {
      final String svg = drawOne((dc) {
        dc.setBrush(0.75, 0xFF0000);
        dc.setPen(2, PenStyle.solid, color: 0x00FF00, opacity: 0.25);
        dc.drawEllipse(10, 20, 30, 40);
      });
      expect(
          svg,
          envelope('<ellipse cx="25" cy="40" rx="15" ry="20" '
              'fill-opacity="0.75" stroke-width="2" stroke="#00FF00" '
              'stroke-opacity="0.25" />'));
    });

    test('drawEllipticArc computes the SVG arc flags like the C++', () {
      // start=0, end=90: theta1=0, theta2=-pi/2 → fArc=0, fSweep=0.
      expect(
          drawOne((dc) => dc.drawEllipticArc(100, 50, 60, 40, 0, 90)),
          envelope(
              '<path d="M160 70 A30 20 0.0 0 0 130 50" stroke-width="1" />'));
      // start=90, end=270: theta1=-pi/2, theta2=+pi/2 → fArc=1, fSweep=0.
      expect(
          drawOne((dc) => dc.drawEllipticArc(100, 50, 60, 40, 90, 270)),
          envelope(
              '<path d="M130 50 A30 20 0.0 1 0 130 90" stroke-width="1" />'));
      // start=180, end=90: theta1=+pi, theta2=-pi/2 → fArc=0, fSweep=1.
      expect(
          drawOne((dc) => dc.drawEllipticArc(100, 50, 60, 40, 180, 90)),
          envelope(
              '<path d="M100 70 A30 20 0.0 0 1 130 50" stroke-width="1" />'));
    });

    test('drawPolyline with more than two points sets fill none', () {
      final String svg = drawOne(
          (dc) => dc.drawPolyline([Point(1, 1), Point(2, 2), Point(3, 3)]));
      // The C++ appends a trailing space after each point.
      expect(
          svg,
          envelope('<polyline stroke-width="1" fill="none" '
              'points="1,1 2,2 3,3 " />'));
    });

    test('drawPolyline with two points keeps no fill and honours pen state',
        () {
      final String svg = drawOne((dc) {
        dc.setPen(6, PenStyle.shortDash,
            lineCap: LineCapStyle.butt,
            lineJoin: LineJoinStyle.miter,
            color: colorLightGrey,
            opacity: 0.5);
        dc.drawPolyline([Point(1, 1), Point(2, 2)]);
      });
      // PEN_SHORT_DASH: dashLength width*2 = 12, gapLength width*3 = 18.
      // Note the C++ quirk: COLOR_LIGHT_GREY prints as #777777.
      expect(
          svg,
          envelope('<polyline stroke-width="6" stroke="#777777" '
              'stroke-opacity="0.5" stroke-linecap="butt" '
              'stroke-linejoin="miter" stroke-dasharray="12 18" '
              'points="1,1 2,2 " />'));
    });

    test('drawPolyline with close emits a polygon', () {
      final String svg = drawOne((dc) => dc
          .drawPolyline([Point(1, 1), Point(2, 2), Point(3, 3)], close: true));
      expect(
          svg,
          envelope('<polygon stroke-width="1" fill="none" '
              'points="1,1 2,2 3,3 " />'));
    });

    test('drawPolygon', () {
      final String svg = drawOne(
          (dc) => dc.drawPolygon([Point(1, 1), Point(2, 2), Point(3, 3)]));
      // No line cap for polygons; the points are space separated without a
      // trailing space.
      expect(
          svg, envelope('<polygon stroke-width="1" points="1,1 2,2 3,3" />'));
    });

    test('drawPolygon with brush color and opacity', () {
      final String svg = drawOne((dc) {
        dc.setBrush(0.5, 0xFF0000);
        dc.setPen(1, PenStyle.solid, lineJoin: LineJoinStyle.bevel);
        dc.drawPolygon([Point(1, 1), Point(2, 2), Point(3, 3)]);
      });
      expect(
          svg,
          envelope('<polygon stroke-width="1" stroke-linejoin="bevel" '
              'fill="#FF0000" fill-opacity="0.5" points="1,1 2,2 3,3" />'));
    });

    test('drawRectangle delegates to drawRoundedRectangle with radius 0', () {
      final String svg = drawOne((dc) => dc.drawRectangle(1, 2, 30, 40));
      expect(
          svg,
          envelope(
              '<rect stroke-width="1" x="1" y="2" height="40" width="30" />'));
    });

    test('drawRoundedRectangle with radius and negative width/height', () {
      final String svg = drawOne((dc) {
        dc.setBrush(1.0, 0xFF0000);
        dc.drawRoundedRectangle(10, 10, -20, -30, 5);
      });
      // Negative sizes are flipped into positive ones; the origin moves.
      expect(
          svg,
          envelope('<rect stroke-width="1" fill="#FF0000" fill-opacity="1" '
              'x="-10" y="-20" height="30" width="20" rx="5" />'));
    });

    test('drawSpline draws nothing (empty in the C++)', () {
      final String svg =
          drawOne((dc) => dc.drawSpline([Point(1, 1), Point(2, 2)]));
      expect(svg, envelope(''));
    });

    test('drawGraphicUri emits an image with xlink:href', () {
      final String svg =
          drawOne((dc) => dc.drawGraphicUri(1, 2, 30, 40, 'img.png'));
      expect(
          svg,
          envelope(
              '<image xlink:href="img.png" x="1" y="2" width="30" height="40" />'));
    });

    test(
        'drawSvgShape sets the transform, removes the id and copies the children',
        () {
      final String svg = drawOne((dc) {
        dc.startCustomGraphic('svgish', '', 'svg1');
        dc.drawSvgShape(5, 6, 0, 0, 0.5,
            '<svg id="inner"><rect x="1" y="2"/><desc>hi</desc></svg>');
      });
      // `%f` prints six decimals; the duplicated id is removed from the
      // current graphic.
      expect(
          svg,
          envelope('<g class="svgish" '
              'transform="translate(5, 6) scale(5.000000, 5.000000)">\n'
              '    <rect x="1" y="2" />\n'
              '    <desc>hi</desc>\n'
              '  </g>'));
    });

    test('drawSvgBoundingBoxRectangle flips negative sizes', () {
      final String svg =
          drawOne((dc) => dc.drawSvgBoundingBoxRectangle(10, 980, 40, -60));
      expect(
          svg,
          envelope('<rect x="10" y="920" height="60" width="40" '
              'fill="transparent" stroke-width="0" />'));
    });

    test('drawSvgBoundingBox draws the self bounding box group', () {
      final System system = System();
      final Measure measure = Measure();
      system.addChild(measure);
      measure.updateSelfBBoxX(10, 50);
      measure.updateSelfBBoxY(20, 80);
      final String svg = drawOne((dc) {
        dc.svgBoundingBoxes = true;
        dc.contentHeight = 1000;
        dc.drawSvgBoundingBox(measure,
            toDeviceContextX: (x) => x,
            toDeviceContextY: (y) => dc.contentHeight - y);
      });
      // The object id is the generated one (mirrors `Object::GenerateID`);
      // it is interpolated, the comparison stays string-exact.
      expect(
          svg,
          envelope('<g id="bbox-${measure.id}" class="measure bounding-box">\n'
              '    <rect x="10" y="920" height="60" width="40" '
              'fill="transparent" stroke-width="0" />\n'
              '  </g>'));
    });

    test('drawSvgBoundingBox draws the content bounding box too when enabled',
        () {
      final System system = System();
      final Measure measure = Measure();
      system.addChild(measure);
      measure.updateSelfBBoxX(10, 50);
      measure.updateSelfBBoxY(20, 80);
      measure.updateContentBBoxX(12, 48);
      measure.updateContentBBoxY(30, 70);
      final String svg = drawOne((dc) {
        dc.svgBoundingBoxes = true;
        dc.svgContentBoundingBoxes = true;
        dc.contentHeight = 1000;
        dc.drawSvgBoundingBox(measure,
            toDeviceContextX: (x) => x,
            toDeviceContextY: (y) => dc.contentHeight - y);
      });
      // The content box group is prepended, so it comes first.
      expect(
          svg,
          envelope('<g id="cbbox-${measure.id}" '
              'class="measure content-bounding-box">\n'
              '    <rect x="12" y="930" height="40" width="36" '
              'fill="transparent" stroke-width="0" />\n'
              '  </g>\n'
              '  <g id="bbox-${measure.id}" class="measure bounding-box">\n'
              '    <rect x="10" y="920" height="60" width="40" '
              'fill="transparent" stroke-width="0" />\n'
              '  </g>'));
    });

    test('endGraphic draws no bounding box without view conversions', () {
      final String svg = drawOne((dc) {
        dc.svgBoundingBoxes = true;
        final Measure measure = Measure();
        dc.startGraphic(measure, '', 'm1');
        dc.endGraphic(measure);
      });
      expect(svg, envelope('<g id="m1" class="measure" />'));
    });
  });

  group('SvgDeviceContext text and glyphs (05-04)', () {
    setUpAll(() {
      Resources.defaultPath = 'assets/data';
    });

    // The document the C++ produces around a single primitive drawn on a
    // fresh context (default indent of 2; zero width/height).
    String envelope(String element, {String unit = 'px'}) {
      final String elementLine = element.isEmpty ? '' : '  $element\n';
      return '<svg width="0$unit" height="0$unit" version="1.1" '
          'xmlns="http://www.w3.org/2000/svg" '
          'xmlns:xlink="http://www.w3.org/1999/xlink" overflow="visible" '
          'id="docid">\n'
          '  <desc>Engraved by Verovio 6.2.0</desc>\n'
          '$elementLine'
          '</svg>\n';
    }

    /// Draws on a fresh context with the fonts loaded (drawMusicText needs
    /// the glyph tables) and serializes the whole document, so the tests
    /// compare exact strings against literals derived from the C++. Returns
    /// the context (for flag assertions) together with the document.
    (SvgDeviceContext, String) drawWithContext(
        void Function(SvgDeviceContext dc) draw) {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      final Resources resources = Resources();
      expect(resources.initFonts(), isTrue);
      dc.setResources(resources);
      draw(dc);
      return (dc, dc.getStringSVG());
    }

    /// Same as [drawWithContext], returning only the serialized document.
    String drawOne(void Function(SvgDeviceContext dc) draw) =>
        drawWithContext(draw).$2;

    /// The complete output of the minimal document below, derived from
    /// `test/golden/cpp/note/note-001.svg` (C++ 6.2.0 output over
    /// `test/corpus/note/note-001.mei`): the envelope, the `<defs>` blocks
    /// (glyph paths byte-identical to the golden and to
    /// `assets/data/Leipzig/E050.xml` / `E260.xml`), the default `<style>`,
    /// the definition-scale/page-margin skeleton, the staff lines, the clef
    /// and keySig `<use>` elements and the pgHead text block — all exact
    /// golden fragments. The golden's document id suffix (`o3u8kcw`) is
    /// normalized to `docid` and the generated object ids are replaced by
    /// the literals the test passes to `startGraphic` (the C++ ids are
    /// random per run); the elements dropped from the full golden (the
    /// extra keyAccids, meterSig, the layer content, the barLines and the
    /// pgFooter) are outside this minimal document.
    test('minimal document with music matches a golden-derived literal', () {
      final SvgDeviceContext dc = SvgDeviceContext('docid');
      final Resources resources = Resources();
      expect(resources.initFonts(), isTrue);
      dc.setResources(resources);
      dc.width = 2100;
      dc.height = 2970;
      dc.contentHeight = 2970;
      dc.indent = 3;
      dc.setLogicalOrigin(-500, -500);

      final Mdiv mdiv = Mdiv();
      final Score score = Score();
      final System system = System();
      final Section section = Section();
      final Measure measure = Measure();
      final Staff staff = Staff();
      staff.drawingStaffDef = StaffDef();
      final SystemMilestoneEnd sectionEnd = SystemMilestoneEnd(section);
      final PageMilestoneEnd scoreEnd = PageMilestoneEnd(score);
      final PageMilestoneEnd mdivEnd = PageMilestoneEnd(mdiv);
      final Clef clef = Clef();
      final KeySig keySig = KeySig();
      final KeyAccid keyAccid = KeyAccid();
      final PgHead pgHead = PgHead();
      final Rend rend1 = Rend()..label = 'title';
      final Rend rend2 = Rend();
      final Text text = Text();

      dc.startPage();

      dc.startGraphic(mdiv, 'pageMilestone', 'mm1');
      dc.endGraphic(mdiv);
      dc.startGraphic(score, 'pageMilestone', 'sc1');
      dc.endGraphic(score);

      dc.startGraphic(system, '', 'sy1');
      dc.startGraphic(section, 'systemMilestone', 'se1');
      dc.endGraphic(section);
      dc.startGraphic(measure, '', 'me1');
      dc.startGraphic(staff, '', 'st1');
      dc.setPen(13, PenStyle.solid);
      dc.drawLine(0, 1267, 4581, 1267);
      dc.drawLine(0, 1447, 4581, 1447);
      dc.drawLine(0, 1627, 4581, 1627);
      dc.drawLine(0, 1807, 4581, 1807);
      dc.drawLine(0, 1987, 4581, 1987);
      dc.resetPen();
      dc.startGraphic(clef, '', 'cl1');
      dc.setFont(FontInfo()..pointSize = 720);
      dc.drawMusicText('\uE050', 90, 1807);
      dc.resetFont();
      dc.endGraphic(clef);
      dc.startGraphic(keySig, '', 'ks1');
      dc.startGraphic(keyAccid, '', 'ka1');
      dc.setFont(FontInfo()..pointSize = 720);
      dc.drawMusicText('\uE260', 735, 1627);
      dc.resetFont();
      dc.endGraphic(keyAccid);
      dc.endGraphic(keySig);
      dc.endGraphic(staff);
      dc.endGraphic(measure);
      // The View draws the milestone ends with the start element's id as the
      // graphic class; here that id is the literal passed to startGraphic
      // above ('se1', 'sc1', 'mm1').
      dc.startGraphic(sectionEnd, 'se1', 'se1e');
      dc.endGraphic(sectionEnd);
      dc.endGraphic(system);

      dc.startGraphic(scoreEnd, 'sc1', 'sce1');
      dc.endGraphic(scoreEnd);
      dc.startGraphic(mdivEnd, 'mm1', 'mme1');
      dc.endGraphic(mdivEnd);

      dc.startGraphic(pgHead, 'autogenerated', 'ph1');
      dc.setFont(FontInfo());
      dc.startText(0, 0);
      dc.startTextGraphic(rend1, '', 'r1');
      dc.moveTextTo(10000, 415, HorizontalAlignment.center);
      dc.startTextGraphic(rend2, '', 'r2');
      dc.startTextGraphic(text, '', 't1');
      dc.setFont(FontInfo()..pointSize = 607);
      dc.drawText('Hidden notes');
      dc.resetFont();
      dc.endTextGraphic(text);
      dc.endTextGraphic(rend2);
      dc.endTextGraphic(rend1);
      dc.endText();
      dc.resetFont();
      dc.endGraphic(pgHead);

      dc.endPage();

      // Exact string equality against the golden-derived literal (only the
      // id suffix and the generated ids are normalized).
      expect(dc.getStringSVG(true), kGoldenMinimalDoc);
    });

    test(
        'drawMusicText deduplicates glyphs and keeps the defs in first-use order',
        () {
      final String svg = drawOne((dc) {
        dc.setFont(FontInfo()..pointSize = 720);
        dc.startCustomGraphic('layer', '', 'l1');
        dc.drawMusicText('\uE050', 10, 20);
        dc.drawMusicText('\uE260', 30, 40);
        dc.drawMusicText('\uE050', 50, 60);
        dc.endCustomGraphic();
      });

      // One <defs> entry per glyph, in first-use order (E050 was drawn
      // before E260; the repeated E050 adds nothing).
      expect(RegExp('<g id="E050-docid">').allMatches(svg).length, 1);
      expect(RegExp('<g id="E260-docid">').allMatches(svg).length, 1);
      expect(svg.indexOf('<g id="E050-docid">'),
          lessThan(svg.indexOf('<g id="E260-docid">')));

      // One <use> per drawn char, all sharing the single defs id.
      expect(RegExp('<use xlink:href="#E050-docid"').allMatches(svg).length, 2);
      expect(RegExp('<use xlink:href="#E260-docid"').allMatches(svg).length, 1);
      expect(
          svg,
          contains('<use xlink:href="#E050-docid" '
              'transform="translate(10, 20) scale(0.72, 0.72)" />'));
      expect(
          svg,
          contains('<use xlink:href="#E260-docid" '
              'transform="translate(30, 40) scale(0.72, 0.72)" />'));
      expect(
          svg,
          contains('<use xlink:href="#E050-docid" '
              'transform="translate(50, 60) scale(0.72, 0.72)" />'));
    });

    test('drawText escapes XML special characters and pads edge spaces', () {
      final String svg = drawOne((dc) {
        dc.setFont(FontInfo()..pointSize = 100);
        dc.startText(0, 0);
        dc.drawText('a & b < c > d " e');
        dc.endText();
        dc.drawText(' padded ');
      });
      // & < > are escaped in pcdata, the double quote is not; the leading
      // and trailing spaces become non-breakable spaces (U+00A0).
      expect(
          svg,
          envelope('<text font-size="0px">\n'
              '    <tspan font-size="100px">a &amp; b &lt; c &gt; d " e</tspan>\n'
              '  </text>\n'
              '  <tspan font-size="100px">\u00A0padded\u00A0</tspan>'));
    });

    test('startText writes text-anchor only for right and center', () {
      String startText(HorizontalAlignment alignment) => drawOne((dc) {
            dc.setFont(FontInfo());
            dc.startText(5, 7, alignment);
            dc.endText();
          });

      expect(startText(HorizontalAlignment.left),
          envelope('<text x="5" y="7" font-size="0px" />'));
      expect(startText(HorizontalAlignment.right),
          envelope('<text x="5" y="7" text-anchor="end" font-size="0px" />'));
      expect(
          startText(HorizontalAlignment.center),
          envelope(
              '<text x="5" y="7" text-anchor="middle" font-size="0px" />'));
    });

    test('moveTextTo writes the anchor for every alignment but none', () {
      String moveTextTo(HorizontalAlignment alignment) => drawOne((dc) {
            dc.setFont(FontInfo());
            dc.startText(0, 0);
            dc.moveTextTo(5, 7, alignment);
            dc.endText();
          });

      expect(moveTextTo(HorizontalAlignment.left),
          envelope('<text font-size="0px" x="5" y="7" text-anchor="start" />'));
      expect(moveTextTo(HorizontalAlignment.right),
          envelope('<text font-size="0px" x="5" y="7" text-anchor="end" />'));
      expect(
          moveTextTo(HorizontalAlignment.center),
          envelope(
              '<text font-size="0px" x="5" y="7" text-anchor="middle" />'));
      expect(moveTextTo(HorizontalAlignment.none_),
          envelope('<text font-size="0px" x="5" y="7" />'));
    });

    test('moveTextVerticallyTo moves the y only', () {
      final String svg = drawOne((dc) {
        dc.setFont(FontInfo());
        dc.startText(0, 0);
        dc.moveTextVerticallyTo(9);
        dc.endText();
      });
      expect(svg, envelope('<text font-size="0px" y="9" />'));
    });

    test('drawText with a smufl selected font marks vrvTextFont', () {
      late final SvgDeviceContext dc;
      late final Resources resources;
      final String svg = drawWithContext((d) {
        dc = d;
        resources = d.resources!;
        d.setFont(FontInfo()
          ..pointSize = 100
          ..faceName = 'Leipzig'
          ..smuflFont = SmuflTextFont.fontSelected);
        d.startText(0, 0);
        d.drawText('a');
        d.endText();
      }).$2;

      expect(dc.vrvTextFont, isTrue);
      // The tspan carries the font family; the commit emits the embedded
      // @font-face CSS for the current font.
      expect(svg,
          contains('<tspan font-family="Leipzig" font-size="100px">a</tspan>'));
      expect(
          svg,
          contains('<style type="text/css">'
              '${resources.getCSSFontFor(resources.currentFontName)}'
              '</style>'));
    });

    test('drawText with the fallback smufl font marks vrvTextFontFallback', () {
      late final SvgDeviceContext dc;
      final String svg = drawWithContext((d) {
        dc = d;
        d.setFont(FontInfo()
          ..pointSize = 100
          ..faceName = 'Bravura'
          ..smuflFont = SmuflTextFont.fontFallback);
        d.startText(0, 0);
        d.drawText('a');
        d.endText();
      }).$2;

      expect(dc.vrvTextFontFallback, isTrue);
      expect(dc.vrvTextFont, isFalse);
      // The fallback always names Leipzig in the tspan.
      expect(svg,
          contains('<tspan font-family="Leipzig" font-size="100px">a</tspan>'));
    });

    test('drawRotatedText draws nothing (empty in the C++)', () {
      final String svg = drawOne((dc) => dc.drawRotatedText('x', 1, 2, 3.0));
      expect(svg, envelope(''));
    });
  });
}

/// The literal of the golden-derived test above (see its doc comment).
const String kGoldenMinimalDoc =
    '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n'
    '<svg width="2100px" height="2970px" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" overflow="visible" id="docid">\n'
    '   <desc>Engraved by Verovio 6.2.0</desc>\n'
    '   <defs>\n'
    '      <g id="E050-docid">\n'
    '         <path transform="scale(1,-1)" d="M441 -245c-23 -4 -48 -6 -76 -6c-59 0 -102 7 -130 20c-88 42 -150 93 -187 154c-26 44 -43 103 -48 176c0 6 -1 13 -1 19c0 54 15 111 45 170c29 57 65 106 110 148s96 85 153 127c-3 16 -8 46 -13 92c-4 43 -5 73 -5 89c0 117 16 172 69 257c34 54 64 82 89 82 c21 0 43 -30 69 -92s39 -115 41 -159v-15c0 -109 -21 -162 -67 -241c-13 -20 -63 -90 -98 -118c-13 -9 -25 -19 -37 -29l31 -181c8 1 18 2 28 2c58 0 102 -12 133 -35c59 -43 92 -104 98 -184c1 -7 1 -15 1 -22c0 -123 -87 -209 -181 -248c8 -57 17 -110 25 -162 c5 -31 6 -58 6 -80c0 -30 -5 -53 -14 -70c-35 -64 -88 -99 -158 -103c-5 0 -11 -1 -16 -1c-37 0 -72 10 -108 27c-50 24 -77 59 -80 105v11c0 29 7 55 20 76c18 28 45 42 79 44h6c49 0 93 -42 97 -87v-9c0 -51 -34 -86 -105 -106c17 -24 51 -36 102 -36c62 0 116 43 140 85 c9 16 13 41 13 74c0 20 -1 42 -5 67c-8 53 -18 106 -26 159zM461 939c-95 0 -135 -175 -135 -286c0 -24 2 -48 5 -71c50 39 92 82 127 128c40 53 60 100 60 140v8c-4 53 -22 81 -55 81h-2zM406 119l54 -326c73 25 110 78 110 161c0 7 0 15 -1 23c-7 95 -57 142 -151 142h-12 zM382 117c-72 -2 -128 -47 -128 -120v-7c2 -46 43 -99 75 -115c-3 -2 -7 -5 -10 -10c-70 33 -116 88 -123 172v11c0 68 44 126 88 159c23 17 49 29 78 36l-29 170c-21 -13 -52 -37 -92 -73c-50 -44 -86 -84 -109 -119c-45 -69 -67 -130 -67 -182v-13c5 -68 35 -127 93 -176 s125 -73 203 -73c25 0 50 3 75 9c-19 111 -36 221 -54 331z" />\n'
    '      </g>\n'
    '      <g id="E260-docid">\n'
    '         <path transform="scale(1,-1)" d="M20 110c32 16 54 27 93 27c26 0 35 -3 54 -13c13 -7 24 -20 27 -38l4 -25c0 -28 -16 -57 -45 -89c-23 -25 -39 -44 -65 -68l-88 -79v644h20v-359zM90 106c-32 0 -48 -10 -70 -29v-194c31 31 54 59 71 84c21 32 32 59 32 84c0 9 1 16 1 20c0 14 -3 21 -11 30l-8 3z" />\n'
    '      </g>\n'
    '   </defs>\n'
    '   <style type="text/css">#docid g.ending, #docid g.fing, #docid g.reh, #docid g.tempo {font-weight:bold;}#docid g.dir, #docid g.dynam, #docid g.mNum {font-style:italic;}#docid g.label {font-weight:normal;}#docid ellipse, #docid path, #docid polygon, #docid polyline, #docid rect {stroke:currentColor}</style>\n'
    '   <svg class="definition-scale" color="black" font-family="Times, serif" viewBox="0 0 21000 29700">\n'
    '      <g class="page-margin" transform="translate(500, 500)">\n'
    '         <g id="mm1" class="mdiv pageMilestone" />\n'
    '         <g id="sc1" class="score pageMilestone" />\n'
    '         <g id="sy1" class="system">\n'
    '            <g id="se1" class="section systemMilestone" />\n'
    '            <g id="me1" class="measure">\n'
    '               <g id="st1" class="staff">\n'
    '                  <path d="M0 1267 L4581 1267" stroke-width="13" />\n'
    '                  <path d="M0 1447 L4581 1447" stroke-width="13" />\n'
    '                  <path d="M0 1627 L4581 1627" stroke-width="13" />\n'
    '                  <path d="M0 1807 L4581 1807" stroke-width="13" />\n'
    '                  <path d="M0 1987 L4581 1987" stroke-width="13" />\n'
    '                  <g id="cl1" class="clef">\n'
    '                     <use xlink:href="#E050-docid" transform="translate(90, 1807) scale(0.72, 0.72)" />\n'
    '                  </g>\n'
    '                  <g id="ks1" class="keySig">\n'
    '                     <g id="ka1" class="keyAccid">\n'
    '                        <use xlink:href="#E260-docid" transform="translate(735, 1627) scale(0.72, 0.72)" />\n'
    '                     </g>\n'
    '                  </g>\n'
    '               </g>\n'
    '            </g>\n'
    '            <g id="se1e" class="systemMilestoneEnd se1" />\n'
    '         </g>\n'
    '         <g id="sce1" class="pageMilestoneEnd sc1" />\n'
    '         <g id="mme1" class="pageMilestoneEnd mm1" />\n'
    '         <g id="ph1" class="pgHead autogenerated">\n'
    '            <text font-size="0px">\n'
    '               <tspan id="r1" class="rend" x="10000" y="415" text-anchor="middle">\n'
    '                  <title class="labelAttr">title</title>\n'
    '                  <tspan id="r2" class="rend">\n'
    '                     <tspan id="t1" class="text">\n'
    '                        <tspan font-size="607px">Hidden notes</tspan>\n'
    '                     </tspan>\n'
    '                  </tspan>\n'
    '               </tspan>\n'
    '            </text>\n'
    '         </g>\n'
    '      </g>\n'
    '   </svg>\n'
    '</svg>\n';
