/// Port of `zone.h/cpp` — the MEI `<zone>` element (facsimile area).
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/object.dart';

/// Implements the zone element in MEI (mirrors `vrv::Zone`).
class Zone extends Object with AttTyped, AttCoordinated, AttCoordinatedUl {
  Zone() : super(ClassId.zone) {
    assignClassId(ClassId.zone);
    reset();
  }

  @override
  ClassId get classId => ClassId.zone;

  @override
  String get className => 'zone';

  @override
  Object clone() {
    final copy = Zone();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    type = null;
    ulx = null;
    uly = null;
    lrx = null;
    lry = null;
    rotate = null;
  }

  /// Shift the zone by the given offsets (mirrors `ShiftByXY`).
  void shiftByXY(int xDiff, int yDiff) {
    if (ulx != null) ulx = ulx! + xDiff;
    if (lrx != null) lrx = lrx! + xDiff;
    if (uly != null) uly = uly! + yDiff;
    if (lry != null) lry = lry! + yDiff;
  }

  int? getLogicalUly() => uly;

  int? getLogicalLry() => lry;

  @override
  int getDrawingX() => parent?.getDrawingX() ?? 0;

  @override
  int getDrawingY() => parent?.getDrawingY() ?? 0;
}
