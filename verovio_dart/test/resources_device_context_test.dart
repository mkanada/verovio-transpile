import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/rendering/bbox_device_context.dart';
import 'package:verovio_dart/src/rendering/glyph.dart';
import 'package:verovio_dart/src/rendering/resources.dart';

/// Minimal concrete BoundingBox for testing.
class TestBox extends BoundingBox {
  TestBox({this.x = 0, this.y = 0});

  int x;
  int y;

  @override
  ClassId get classId => ClassId.object;

  @override
  int getDrawingX() => x;

  @override
  int getDrawingY() => y;

  @override
  void resetCachedDrawingX() {}

  @override
  void resetCachedDrawingY() {}
}

void main() {
  late Resources resources;

  setUp(() {
    Resources.defaultPath = 'assets/data';
    resources = Resources();
    expect(resources.initFonts(), isTrue);
  });

  group('Resources', () {
    test('initFonts loads Bravura and Leipzig', () {
      expect(resources.ok, isTrue);
      expect(resources.isFontLoaded('Bravura'), isTrue);
      expect(resources.isFontLoaded('Leipzig'), isTrue);
      expect(resources.currentFont, 'Leipzig');
      expect(resources.isCurrentFontFallback, isTrue);
    });

    test('glyph name table built from Bravura', () {
      final int code = resources.getGlyphCode('noteheadBlack');
      expect(code, 0xE0A4);
      final Glyph? glyph = resources.getGlyphByName('noteheadBlack');
      expect(glyph, isNotNull);
      expect(glyph!.unitsPerEm, 10000); // 1000 * 10
      expect(glyph.horizAdvX, greaterThan(0));
    });

    test('getGlyphByCode with fallback', () {
      // Gootville misses some glyphs; Leipzig (fallback) has them all.
      expect(resources.setCurrentFont('Gootville', allowLoading: true), isTrue);
      expect(resources.isCurrentFontFallback, isFalse);
      // A glyph surely present in both fonts:
      final Glyph? direct = resources.getGlyphByCode(0xE0A4);
      expect(direct, isNotNull);
      // Switch current font to a font without that glyph would fall back;
      // here just verify fallback lookup works after clearing cache.
      resources.setFallbackFont('Leipzig');
      expect(resources.isSmuflFallbackNeeded('o'), isTrue);
      expect(resources.isSmuflFallbackNeeded('\uE0A4'), isFalse);
    });

    test('text font bounding boxes are loaded', () {
      final Glyph? oGlyph = resources.getTextGlyph(0x6F /* o */);
      expect(oGlyph, isNotNull);
      expect(oGlyph!.unitsPerEm, 20480); // 2048 * 10

      // Selecting an unloaded style falls back to the default style.
      resources.selectTextFont(FontWeight.bold, FontStyle.italic);
      resources.selectTextFont(FontWeight.bold, FontStyle.oblique);
      expect(resources.currentStyle, kDefaultStyle);
    });

    test('fontHasGlyphAvailable', () {
      expect(resources.fontHasGlyphAvailable('Leipzig', 0xE0A4), isTrue);
      expect(
          resources.fontHasGlyphAvailable('NotLoaded', 0xE0A4), isFalse);
    });

    test('getCSSFontFor', () {
      expect(resources.getCSSFontFor('Leipzig'), contains('@font-face'));
      expect(resources.getCSSFontFor('NotLoaded'), isEmpty);
    });
  });

  group('BBoxDeviceContext', () {
    late BBoxDeviceContext dc;

    setUp(() {
      dc = BBoxDeviceContext(
        toLogicalX: (x) => x,
        toLogicalY: (y) => y,
        width: 2100,
        height: 2970,
      );
      dc.resources = resources;
      dc.setFont(FontInfo()..pointSize = 100);
    });

    test('pen stack computes dash lengths like the C++', () {
      dc.setPen(2, PenStyle.dot);
      expect(dc.pen.dashLength, 1);
      expect(dc.pen.gapLength, 6);
      dc.setPen(3, PenStyle.longDash);
      expect(dc.pen.dashLength, 12);
      expect(dc.pen.gapLength, 9);
      dc.resetPen();
      dc.resetPen();
    });

    test('setFont inherits point size from stack top', () {
      final FontInfo f = FontInfo();
      dc.setFont(f);
      expect(f.pointSize, 100);
      dc.resetFont();
    });

    test('drawLine updates self and content bounding boxes', () {
      final box = TestBox(x: 0, y: 0);
      dc.startGraphic(box, '', 'test');
      dc.drawLine(10, 10, 50, 20);
      dc.endGraphic(box);

      // Pen width defaults to 1 => overlap (p1, p2) = (1, 0):
      // left/top shifted by p2, right/bottom extended by p1.
      expect(box.getSelfLeft(), 9);
      expect(box.getSelfRight(), 50);
      expect(box.getSelfTop(), 21);
      expect(box.getSelfBottom(), 10);
      expect(box.getContentLeft(), box.getSelfLeft());
      expect(box.getContentRight(), box.getSelfRight());
    });

    test('deactivate X skips x updates only', () {
      final box = TestBox(x: 0, y: 0);
      dc.startGraphic(box, '', 'test');
      dc.deactivateGraphicX();
      dc.drawLine(10, 10, 50, 20);
      dc.reactivateGraphic();
      dc.endGraphic(box);

      expect(box.getSelfX1(), -meiUnset); // untouched
      expect(box.getSelfX2(), meiUnset);
      expect(box.getSelfTop(), 21);
      expect(box.getSelfBottom(), 10);
    });

    test('drawMusicText accumulates bounding boxes from glyphs', () {
      final box = TestBox(x: 0, y: 0);
      dc.startGraphic(box, '', 'smufl');
      // noteheadBlack E0A4
      dc.drawMusicText('\uE0A4', 100, 200);
      dc.endGraphic(box);

      expect(box.getSelfRight(), greaterThan(box.getSelfLeft()));
      expect(box.getSelfLeft(), lessThan(100 + 100));
    });

    test('startText/drawText/endText computes text extents', () {
      final box = TestBox(x: 0, y: 0);
      dc.startGraphic(box, '', 'text');
      dc.startText(500, 1000);
      dc.drawText('oo');
      dc.endText();
      dc.endGraphic(box);

      expect(box.getSelfRight() - box.getSelfLeft(), greaterThan(0));
      expect(box.getContentTop(), greaterThan(1000)); // ascent above baseline
    });

    test('nested graphics stretch content bbox of parents', () {
      final parent = TestBox();
      final child = TestBox();
      dc.startGraphic(parent, '', 'parent');
      dc.startGraphic(child, '', 'child');
      dc.drawRectangle(10, 10, 40, 40);
      dc.endGraphic(child);
      dc.drawRectangle(100, 100, 20, 20);
      dc.endGraphic(parent);

      expect(child.getContentRight(), 50);
      expect(parent.getContentRight(), 120);
      expect(parent.getSelfRight(), 120);
    });

    test('rotation rotates the computed bbox', () {
      final box = TestBox();
      dc.startGraphic(box, '', 'rot');
      dc.rotateGraphic(Point(0, 0), 90.0);
      dc.drawRectangle(100, 0, 10, 10);
      dc.endGraphic(box);

      // CCW rotation by 90° maps (x, y) to (-y, x).
      expect(box.getSelfLeft(), -11);
      expect(box.getSelfRight(), 0);
      expect(box.getSelfTop(), 110);
      expect(box.getSelfBottom(), 99);
    });

    test('logical transforms are applied', () {
      final BBoxDeviceContext shifted = BBoxDeviceContext(
        toLogicalX: (x) => x + 1000,
        toLogicalY: (y) => y + 2000,
      );
      shifted.setFont(FontInfo()..pointSize = 100);
      final box = TestBox();
      shifted.startGraphic(box, '', 't');
      shifted.drawRectangle(0, 0, 10, 10);
      shifted.endGraphic(box);
      expect(box.getSelfLeft(), 999);
      expect(box.getSelfRight(), 1010);
      expect(box.getSelfBottom(), 2000);
      expect(box.getSelfTop(), 2011);
    });
  });
}
