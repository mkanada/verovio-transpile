import 'package:test/test.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/rendering/glyph.dart';

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
  group('Glyph', () {
    test('setBoundingBox scales by 10', () {
      final glyph = Glyph();
      glyph.setBoundingBox(10.2, -5.0, 204.8, 100.0);
      final (x, y, w, h) = glyph.getBoundingBox();
      expect(x, 102);
      expect(y, -50);
      expect(w, 2048);
      expect(h, 1000);
    });

    test('text constructor multiplies units per em by 10', () {
      expect(Glyph.text(2048).unitsPerEm, 20480);
      expect(Glyph().unitsPerEm, 20480);
    });

    test('anchors are stored as staff spaces (upm / 4)', () {
      final glyph = Glyph();
      glyph.unitsPerEm = 20480;
      glyph.setAnchor('stemUpSE', 2.0, -1.0);
      glyph.setAnchor('unusedAnchor', 5.0, 5.0);
      expect(glyph.hasAnchor(SMuFLGlyphAnchor.stemUpSE), isTrue);
      expect(glyph.hasAnchor(SMuFLGlyphAnchor.cutOutNE), isFalse);
      // 2.0 * 20480 / 4 = 10240
      expect(glyph.getAnchor(SMuFLGlyphAnchor.stemUpSE).x, 10240);
      expect(glyph.getAnchor(SMuFLGlyphAnchor.stemUpSE).y, -5120);
    });

    test('BezierCurve control point roundtrip', () {
      final curve = BezierCurve()
        ..p1 = Point(0, 0)
        ..c1 = Point(30, 30)
        ..c2 = Point(60, -60)
        ..p2 = Point(90, -30)
        ..setControlSides(true, true)
        ..updateControlPointParams();
      expect(curve.leftControlOffset, 30);
      expect(curve.rightControlOffset, 30);
      expect(curve.leftControlHeight, 30);
      expect(curve.rightControlHeight, -30);

      curve.updateControlPoints();
      expect(curve.c1.x, 30);
      expect(curve.c1.y, 30);
      expect(curve.c2.x, 60);
      expect(curve.c2.y, -60);
    });
  });
}
