import 'package:test/test.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/scoredef.dart';
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
}
