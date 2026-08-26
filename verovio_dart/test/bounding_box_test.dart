import 'package:test/test.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';

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
  group('BoundingBox', () {
    test('reset state uses unset sentinels', () {
      final box = TestBox();
      expect(box.hasContentBB(), isFalse);
      expect(box.hasSelfBB(), isFalse);
    });

    test('updateContentBBox tracks min/max relative to drawing pos', () {
      final box = TestBox(x: 10, y: 20);
      box.updateContentBBoxX(5, 15);
      box.updateContentBBoxY(30, 40);
      // Values are stored relative to the drawing position.
      expect(box.getContentLeft(), 10 - 5);
      expect(box.getContentRight(), 10 + 5);
      expect(box.getContentTop(), 20 + 20);
      expect(box.getContentBottom(), 20 + 10);
      expect(box.hasContentBB(), isTrue);
    });

    test('update only expands the box', () {
      final box = TestBox();
      box.updateContentBBoxX(0, 10);
      box.updateContentBBoxX(-5, 3); // expands left only
      expect(box.getContentX1(), -5);
      expect(box.getContentX2(), 10);
    });

    test('overlap checks', () {
      final a = TestBox(x: 0, y: 0)..updateContentBBoxX(0, 10)..updateContentBBoxY(0, 10);
      final b = TestBox(x: 0, y: 0)..updateContentBBoxX(5, 15)..updateContentBBoxY(5, 15);
      final c = TestBox(x: 0, y: 0)..updateContentBBoxX(50, 60)..updateContentBBoxY(50, 60);

      expect(a.horizontalContentOverlap(b), isTrue);
      expect(a.verticalContentOverlap(b), isTrue);
      expect(a.horizontalContentOverlap(c), isFalse);
      // With margin they can overlap
      expect(a.horizontalContentOverlap(c, 100), isTrue);
    });

    test('encloses', () {
      final a = TestBox(x: 0, y: 0)..updateContentBBoxX(0, 10)..updateContentBBoxY(0, 10);
      expect(a.encloses(Point(5, 5)), isTrue);
      expect(a.encloses(Point(15, 5)), isFalse);
    });

    test('setEmptyBB / hasEmptyBB', () {
      final box = TestBox()..setEmptyBB();
      expect(box.hasEmptyBB(), isTrue);
    });

    test('bezier param at position', () {
      final bezier = [Point(0, 0), Point(10, 20), Point(20, 20), Point(30, 0)];
      final t = BoundingBox.calcBezierParamAtPosition(bezier, 15);
      expect(t, closeTo(0.5, 1e-3));
      final p = BoundingBox.calcPointAtBezier(bezier, 0.5);
      expect(p.x, 15);
      expect(p.y, 15);
    });

    test('calcSlope', () {
      expect(BoundingBox.calcSlope(Point(0, 0), Point(10, 10)), 1.0);
      expect(BoundingBox.calcSlope(Point(0, 0), Point(0, 10)), 0.0);
    });
  });

  group('SegmentedLine', () {
    test('single segment', () {
      final line = SegmentedLine(0, 100);
      expect(line.isUnsegmented(), isTrue);
      expect(line.getStartEnd(0), (0, 100));
    });

    test('reversed line reads backwards', () {
      final line = SegmentedLine(100, 0);
      expect(line.getStartEnd(0), (100, 0));
    });

    test('addGap drops covered segment', () {
      final line = SegmentedLine(0, 100)..addGap(40, 60);
      expect(line.segmentCount, 2);
      expect(line.getStartEnd(0), (0, 40));
      expect(line.getStartEnd(1), (60, 100));
    });

    test('addGap cuts inner segment', () {
      final line = SegmentedLine(0, 100)
        ..addGap(0, 10)
        ..addGap(90, 100)
        ..addGap(45, 55);
      // Like the C++, cutting keeps degenerate segments at the boundaries
      // (e.g. (0,0) when a gap starts exactly at the segment start).
      expect(line.segmentCount, 4);
      expect(line.getStartEnd(0), (0, 0));
      expect(line.getStartEnd(1), (10, 45));
      expect(line.getStartEnd(2), (55, 90));
      expect(line.getStartEnd(3), (100, 100));
    });

    test('addGap can empty the line', () {
      final line = SegmentedLine(0, 100)..addGap(0, 100);
      expect(line.isEmpty(), isTrue);
    });
  });
}
