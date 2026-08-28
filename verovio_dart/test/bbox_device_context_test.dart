/// Tests for `lib/src/rendering/bbox_device_context.dart` (task 05-05) —
/// closing the gaps against `origin/src/src/bboxdevicecontext.cpp`
/// (`BBOX_*` modes, `GetPenWidthOverlap`, `SetUserScale`, `RotateGraphic`
/// rotation of the accumulated boxes, `DrawRotatedText` no-op, and the
/// `int` truncation of the quad-bezier extremum parameter).
library;

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/rendering/bbox_device_context.dart';
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

  BBoxDeviceContext makeDc({int update = BBOX_BOTH}) => BBoxDeviceContext(
        toLogicalX: (x) => x,
        toLogicalY: (y) => y,
        width: 2100,
        height: 2970,
        update: update,
      )
        ..resources = resources
        ..setFont(FontInfo()..pointSize = 100);

  group('BBoxDeviceContext — BBOX_* update modes (05-05)', () {
    // Hand-computed from the C++ with pen width 7:
    // GetPenWidthOverlap -> p1 = 7/2 = 3, odd -> ++p1 = 4, p2 = 3
    // (bboxdevicecontext.cpp:443-455).
    // DrawRoundedRectangle(100, 200, 50, 30, 0) ->
    //   UpdateBB(100 - 4, 200 - 3, 150 + 3, 230 + 4) = UpdateBB(96, 197, 153, 234)
    //   (bboxdevicecontext.cpp:238-253).
    const int expectedLeft = 96, expectedRight = 153;
    const int expectedBottom = 197, expectedTop = 234;

    // UpdateBB itself never consults m_update (bboxdevicecontext.cpp:400-434):
    // the BBOX_HORIZONTAL_ONLY vertical filtering happens in the View
    // consumers (`UpdateVerticalValues`, view_control.cpp:192/:3057 and
    // view_text.cpp:650), ported with the View (05-06) and wired in 05-12.
    void expectKnownBox(BoundingBox box) {
      expect(box.getSelfLeft(), expectedLeft);
      expect(box.getSelfRight(), expectedRight);
      expect(box.getSelfBottom(), expectedBottom);
      expect(box.getSelfTop(), expectedTop);
      // A single object on the stack gets both the self and the content box.
      expect(box.getContentX1(), expectedLeft);
      expect(box.getContentX2(), expectedRight);
      expect(box.getContentY1(), expectedBottom);
      expect(box.getContentY2(), expectedTop);
    }

    test('BBOX_BOTH updates horizontal and vertical values', () {
      final dc = makeDc(update: BBOX_BOTH);
      expect(dc.updateHorizontalValues(), isTrue);
      expect(dc.updateVerticalValues(), isTrue);

      final box = TestBox();
      dc.setPen(7, PenStyle.solid);
      dc.startGraphic(box, '', 'both');
      dc.drawRoundedRectangle(100, 200, 50, 30, 0);
      dc.endGraphic(box);
      expectKnownBox(box);
    });

    test('BBOX_HORIZONTAL_ONLY updates horizontal values only', () {
      final dc = makeDc(update: BBOX_HORIZONTAL_ONLY);
      expect(dc.updateHorizontalValues(), isTrue);
      expect(dc.updateVerticalValues(), isFalse);

      final box = TestBox();
      dc.setPen(7, PenStyle.solid);
      dc.startGraphic(box, '', 'horizontal');
      dc.drawRoundedRectangle(100, 200, 50, 30, 0);
      dc.endGraphic(box);
      // At the device-context level the box is updated on both axes; the
      // vertical skip is done by the View (see the group comment above).
      expectKnownBox(box);
    });

    test('BBOX_VERTICAL_ONLY updates vertical values only', () {
      final dc = makeDc(update: BBOX_VERTICAL_ONLY);
      expect(dc.updateHorizontalValues(), isFalse);
      expect(dc.updateVerticalValues(), isTrue);

      final box = TestBox();
      dc.setPen(7, PenStyle.solid);
      dc.startGraphic(box, '', 'vertical');
      dc.drawRoundedRectangle(100, 200, 50, 30, 0);
      dc.endGraphic(box);
      expectKnownBox(box);
    });
  });

  group('BBoxDeviceContext — GetPenWidthOverlap (05-05)', () {
    test('splits the pen width shifting odd widths to the left/top', () {
      final dc = makeDc();
      // penWidth = 1: p1 = 0, odd -> ++p1, p2 = 0.
      expect(dc.getPenWidthOverlap(), (1, 0));
      // penWidth = 2: p1 = p2 = 1.
      dc.setPen(2, PenStyle.solid);
      expect(dc.getPenWidthOverlap(), (1, 1));
      // penWidth = 7: p1 = 3, odd -> 4 on the left/top, 3 on the right/bottom
      // (the example from bboxdevicecontext.cpp:450-452).
      dc.setPen(7, PenStyle.solid);
      expect(dc.getPenWidthOverlap(), (4, 3));
      // penWidth = 8: p1 = p2 = 4.
      dc.setPen(8, PenStyle.solid);
      expect(dc.getPenWidthOverlap(), (4, 4));
    });
  });

  group('BBoxDeviceContext — rotation (05-05)', () {
    test('rotated music text accumulates the rotated box', () {
      final dc = makeDc();
      final box = TestBox();
      dc.startGraphic(box, '', 'arpeg');
      // The DrawArpeg / glissando flow: RotateGraphic + DrawSmuflLine
      // (view_control.cpp:1586 and :2250).
      dc.rotateGraphic(Point(0, 0), 90.0);
      dc.drawMusicText('\uE0A4', 100, 200, setSmuflGlyph: true);
      dc.endGraphic(box);

      // Leipzig E0A4 (noteheadBlack): x=0, y=-1330, w=3140, h=2660,
      // h-a-x=3140, units-per-em=10000; pointSize=100.
      // Unrotated: xOff = 100 + 0 = 100; yOff = 200 - (-133) = 213;
      //   x2 = 100 + 31 = 131; y2 = 213 - 26 = 187
      //   (bboxdevicecontext.cpp:375-381).
      // UpdateBB applies CalcPositionAfterRotation with 90° CCW around the
      // origin: (100, 213) -> (-213, 100); (131, 187) -> (-187, 131)
      // (bboxdevicecontext.cpp:406-413).
      expect(box.getSelfLeft(), -213);
      expect(box.getSelfRight(), -187);
      expect(box.getSelfBottom(), 100);
      expect(box.getSelfTop(), 131);
      // The glyph is registered on the box in both axis branches
      // (bboxdevicecontext.cpp:421-426).
      expect(box.boundingBoxGlyph, 0xE0A4);
      expect(box.boundingBoxGlyphFontSize, 100);
    });

    test('drawRotatedText does not update the box (empty C++ body)', () {
      final dc = makeDc();
      final box = TestBox();
      dc.startGraphic(box, '', 'rotated-text');
      dc.drawRotatedText('abc', 10, 20, 90.0);
      dc.endGraphic(box);

      // DrawRotatedText is an empty body in the C++
      // (bboxdevicecontext.cpp:349-352): nothing is accumulated.
      expect(box.getSelfX1(), -meiUnset);
      expect(box.getSelfX2(), meiUnset);
      expect(box.getSelfY1(), -meiUnset);
      expect(box.getSelfY2(), meiUnset);
    });

    test('rotation resets on start/end graphic (ResetGraphicRotation)', () {
      final dc = makeDc();
      final parent = TestBox();
      final child = TestBox();
      dc.startGraphic(parent, '', 'parent');
      dc.rotateGraphic(Point(0, 0), 90.0);
      // StartGraphic resets the rotation (bboxdevicecontext.cpp:54).
      dc.startGraphic(child, '', 'child');
      expect(dc.rotationAngle, 0.0);
      expect(dc.rotationOrigin, Point(0, 0));

      // With pen width 1: overlap (1, 0) ->
      // UpdateBB(10 - 1, 10 - 0, 20 + 0, 20 + 1) = (9, 10, 20, 21). Unrotated
      // — a surviving 90° rotation would map it to x in [-21, -10].
      dc.drawRoundedRectangle(10, 10, 10, 10, 0);
      expect(child.getSelfLeft(), 9);
      expect(child.getSelfRight(), 20);
      expect(child.getSelfBottom(), 10);
      expect(child.getSelfTop(), 21);

      // EndGraphic resets the rotation as well (bboxdevicecontext.cpp:68).
      dc.endGraphic(child);
      expect(dc.rotationAngle, 0.0);
      dc.endGraphic(parent);
    });
  });

  group('BBoxDeviceContext — quad bezier t truncation (05-05)', () {
    test('drawQuadBezierPath truncates t to int like the C++', () {
      final dc = makeDc();
      final box = TestBox();
      dc.startGraphic(box, '', 'bezier');
      // pMin = (0, 0), pMax = (20, 0); control (30, -60) is outside, so the
      // extremum block runs. The C++ assigns the clamped t to `int`s
      // (bboxdevicecontext.cpp:132-135): tx = int(0.75) = 0, ty = int(0.5) = 0
      // -> q = (0, 0) and the box stays the endpoints' one:
      // UpdateBB(0, 0, 20, 0). With the true extremum the box would dip to
      // y = -30.
      dc.drawQuadBezierPath([Point(0, 0), Point(30, -60), Point(20, 0)]);
      dc.endGraphic(box);

      expect(box.getSelfLeft(), 0);
      expect(box.getSelfRight(), 20);
      expect(box.getSelfBottom(), 0);
      expect(box.getSelfTop(), 0);
    });
  });

  group('BBoxDeviceContext — SetUserScale (05-05)', () {
    test('setUserScale stores the scale like the C++ override', () {
      final dc = makeDc();
      // Identical body to the hidden base setter
      // (bboxdevicecontext.cpp:111-116).
      dc.setUserScale(2.5, 4.0);
      expect(dc.userScaleX, 2.5);
      expect(dc.userScaleY, 4.0);
    });
  });
}
