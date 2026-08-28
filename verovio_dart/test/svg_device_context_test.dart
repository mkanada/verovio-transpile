import 'package:test/test.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart'
    show LineCapStyle, LineJoinStyle, PenStyle, colorLightGrey, colorNone;
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
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
}
