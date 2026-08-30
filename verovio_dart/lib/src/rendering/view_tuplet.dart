/// Port of `view_tuplet.cpp` — tuplet drawing (task 05-18).
///
/// Mirrors `View::NestedTuplets` (view_tuplet.cpp:27),
/// `View::DrawTuplet` (:51), `View::DrawTupletBracket` (:75) and
/// `View::DrawTupletNum` (:153).
///
/// This file is a `part` of the `view.dart` library (task 05-06 partitioning
/// decision: one `part` per `view_*.cpp`). The C++ continues the `View` class
/// here; Dart cannot split a class body across files, so the methods are
/// declared as members of the [ViewTuplet] extension below — same library,
/// therefore the same privacy scope as the class members (like the C++ member
/// visibility from every `view_*.cpp`).
part of 'view.dart';

/// The `view_tuplet.cpp` methods of [View] (task 05-18).
extension ViewTuplet on View {
  /// Mirrors `View::NestedTuplets` (view_tuplet.cpp:27).
  ///
  /// Returns the depth of nested tuplets/beams inside [object].
  int nestedTuplets(Object object) {
    int tupletDepth = 1;

    for (int i = 0; i < object.childCount; ++i) {
      int tupletCount = 1;

      final Object child = object.children[i];
      // check how many nested tuplets there are
      if (child.isClass(ClassId.tuplet)) {
        tupletCount += nestedTuplets(child);
      }
      // and don't forget beams
      if (child.isClass(ClassId.beam)) {
        tupletCount = nestedTuplets(child);
      }

      tupletDepth = tupletCount > tupletDepth ? tupletCount : tupletDepth;
    }

    return tupletDepth;
  }

  /// Mirrors `View::DrawTuplet` (view_tuplet.cpp:51).
  void drawTuplet(
      DeviceContext dc, LayerElement element, Layer layer, Staff staff, Measure measure) {
    final Tuplet tuplet = element as Tuplet;

    // We do it here because we have no dedicated functor to do it (which would be an overkill)
    if (tuplet.drawingBracketPos == StaffrelBasic.none) {
      _tupletCalcDrawingBracketAndNumPos(tuplet, doc!.getOptions().tupletNumHead.value);
    }

    dc.startGraphic(element, '', element.id);

    // Draw the inner elements
    drawLayerChildren(dc, tuplet, layer, staff, measure);

    dc.endGraphic(element);
  }

  /// Mirrors `View::DrawTupletBracket` (view_tuplet.cpp:75).
  void drawTupletBracket(
      DeviceContext dc, LayerElement element, Layer layer, Staff staff, Measure measure) {
    final TupletBracket tupletBracket = element as TupletBracket;

    if (tupletBracket.bracketVisible == false) {
      tupletBracket.setEmptyBB();
      return;
    }

    final Object? ancestor = tupletBracket.getFirstAncestor(ClassId.tuplet);
    if (ancestor is! Tuplet) {
      tupletBracket.setEmptyBB();
      return;
    }
    final Tuplet tuplet = ancestor;

    if (tuplet.drawingLeft == null || tuplet.drawingRight == null) {
      tupletBracket.setEmptyBB();
      return;
    }

    dc.resumeGraphic(tupletBracket, tupletBracket.id);

    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    final int lineWidth =
        (doc!.getDrawingUnit(staff.drawingStaffSize) * _tupletBracketThickness()).toInt();
    final int xLeft = _tupletBracketDrawingXLeft(tuplet, tupletBracket) + lineWidth ~/ 2;
    final int xRight = _tupletBracketDrawingXRight(tuplet, tupletBracket) - lineWidth ~/ 2;
    final int yLeft = _tupletBracketDrawingYLeft(tuplet, tupletBracket);
    final int yRight = _tupletBracketDrawingYRight(tuplet, tupletBracket);
    int bracketHeight = (tuplet.drawingBracketPos == StaffrelBasic.above) ? -1 : 1;

    dc.setPen(lineWidth, PenStyle.solid,
        lineCap: LineCapStyle.butt, lineJoin: LineJoinStyle.miter);

    // Draw a bracket with a gap
    final Object? alignedNumObj = tupletBracket.alignedNum;
    if (alignedNumObj is TupletNum && alignedNumObj.hasSelfBB()) {
      final TupletNum alignedNum = alignedNumObj;
      final int xNumLeft = alignedNum.getSelfLeft() - unit ~/ 2;
      final int xNumRight = alignedNum.getSelfRight() + unit ~/ 2;
      final double slope = (xRight - xLeft) != 0
          ? (yRight - yLeft) / (xRight - xLeft).toDouble()
          : 0.0;
      final int yNumLeft = yLeft + (slope * (xNumLeft - xLeft)).toInt();
      final int yNumRight = yRight - (slope * (xRight - xNumRight)).toInt();
      bracketHeight *=
          (alignedNum.getSelfTop() - alignedNum.getSelfBottom()).abs() ~/ 2;

      final List<Point> bracketLeft = [
        Point(toDeviceContextX(xLeft), toDeviceContextY(yLeft + bracketHeight)),
        Point(toDeviceContextX(xLeft), toDeviceContextY(yLeft)),
        Point(toDeviceContextX(xNumLeft), toDeviceContextY(yNumLeft)),
      ];
      final List<Point> bracketRight = [
        Point(toDeviceContextX(xRight), toDeviceContextY(yRight + bracketHeight)),
        Point(toDeviceContextX(xRight), toDeviceContextY(yRight)),
        Point(toDeviceContextX(xNumRight), toDeviceContextY(yNumRight)),
      ];

      dc.drawPolyline(bracketLeft);
      dc.drawPolyline(bracketRight);
    } else {
      bracketHeight *= unit + lineWidth;

      final List<Point> bracket = [
        Point(toDeviceContextX(xLeft), toDeviceContextY(yLeft + bracketHeight)),
        Point(toDeviceContextX(xLeft), toDeviceContextY(yLeft)),
        Point(toDeviceContextX(xRight), toDeviceContextY(yRight)),
        Point(toDeviceContextX(xRight), toDeviceContextY(yRight + bracketHeight)),
      ];

      dc.drawPolyline(bracket);
    }

    dc.resetPen();

    dc.endResumedGraphic(tupletBracket);
  }

  /// Mirrors `View::DrawTupletNum` (view_tuplet.cpp:153).
  void drawTupletNum(
      DeviceContext dc, LayerElement element, Layer layer, Staff staff, Measure measure) {
    final TupletNum tupletNum = element as TupletNum;

    final Object? ancestor = tupletNum.getFirstAncestor(ClassId.tuplet);
    if (ancestor is! Tuplet) {
      tupletNum.setEmptyBB();
      return;
    }
    final Tuplet tuplet = ancestor;

    if (!tuplet.hasNum || (tuplet.numVisible == false)) {
      tupletNum.setEmptyBB();
      return;
    }

    if (tuplet.drawingLeft == null || tuplet.drawingRight == null) {
      tupletNum.setEmptyBB();
      return;
    }

    final TextExtend extend = TextExtend();
    final bool drawingCueSize = tuplet.drawingCueSize;
    final int glyphSize = staff.getDrawingStaffNotationSize();
    dc.setFont(doc!.getDrawingSmuflFont(glyphSize, drawingCueSize));
    String notes = intToTupletFigures(tuplet.num ?? 0);
    if (tuplet.numFormat == TupletvisNumformat.ratio) {
      if (tuplet.hasNumbase) {
        notes += String.fromCharCode(0xE88A);
        notes += intToTupletFigures(tuplet.numbase ?? 0);
      }
    }
    dc.getSmuflTextExtent(notes, extend);

    int x = _tupletNumDrawingXMid(tuplet, tupletNum);
    // since the number is slanted, move the center left
    x -= extend.width ~/ 2;

    int y = _tupletNumDrawingYMid(tuplet, tupletNum);
    // adjust the baseline (to be improved with slanted brackets
    y -= doc!.getGlyphHeight(notes.runes.last, glyphSize, drawingCueSize) ~/ 2;

    dc.resumeGraphic(tupletNum, tupletNum.id);

    drawSmuflString(dc, x, y, notes, HorizontalAlignment.left, glyphSize, drawingCueSize);

    dc.endResumedGraphic(tupletNum);

    dc.resetFont();
  }

  // -------------------------------------------------------------------------
  // Helpers mirroring tuplet.cpp / elementpart.cpp
  // -------------------------------------------------------------------------

  double _tupletBracketThickness() => doc!.getOptions().tupletBracketThickness.value;

  /// Mirrors `Tuplet::CalcDrawingBracketAndNumPos` (tuplet.cpp:208).
  void _tupletCalcDrawingBracketAndNumPos(Tuplet tuplet, bool tupletNumHead) {
    tuplet.drawingBracketPos = StaffrelBasic.none;

    if (tuplet.hasBracketPlace) {
      tuplet.drawingBracketPos = tuplet.bracketPlace!;
    }

    if (tuplet.hasNumPlace) {
      tuplet.drawingNumPos = tuplet.numPlace!;
    } else {
      tuplet.drawingNumPos = tuplet.drawingBracketPos;
    }

    // if both are given we are all good (num is set in any case if bracket is)
    if (tuplet.drawingBracketPos != StaffrelBasic.none) {
      return;
    }

    final List<Object> tupletChildren = tuplet.getList();

    // There are unbeamed notes of two different beams
    // treat all the notes as unbeamed
    int ups = 0, downs = 0;

    // The first step is to calculate all the stem directions
    // cycle into the elements and count the up and down dirs
    for (final Object child in tupletChildren) {
      if (child is Chord) {
        if (_tupletStemDirOf(child) == Stemdirection.up) {
          ++ups;
        } else {
          ++downs;
        }
      } else if (child is Note) {
        if (child.isChordTone() == null && _tupletStemDirOf(child) == Stemdirection.up) {
          ++ups;
        }
        if (child.isChordTone() == null && _tupletStemDirOf(child) == Stemdirection.down) {
          ++downs;
        }
      }
    }
    // true means up
    tuplet.drawingBracketPos = ups > downs ? StaffrelBasic.above : StaffrelBasic.below;

    if (tupletNumHead) {
      tuplet.drawingBracketPos =
          (tuplet.drawingBracketPos == StaffrelBasic.below) ? StaffrelBasic.above : StaffrelBasic.below;
    }

    // also use it for the num unless it is already set
    if (tuplet.drawingNumPos == StaffrelBasic.none) {
      tuplet.drawingNumPos = tuplet.drawingBracketPos;
    }
  }

  Stemdirection _tupletStemDirOf(LayerElement element) {
    if (element is! StemmedDrawingInterface) return Stemdirection.none;
    final Stem? stem = (element as StemmedDrawingInterface).getDrawingStem();
    return stem?.getDrawingStemDir() ?? Stemdirection.none;
  }

  int _tupletBracketDrawingXLeft(Tuplet tuplet, TupletBracket bracket) =>
      tuplet.drawingLeft!.getDrawingX() + bracket.drawingXRelLeft;

  int _tupletBracketDrawingXRight(Tuplet tuplet, TupletBracket bracket) =>
      tuplet.drawingRight!.getDrawingX() + bracket.drawingXRelRight;

  int _tupletBracketDrawingYLeft(Tuplet tuplet, TupletBracket bracket) {
    final int plain = bracket.getDrawingY() + bracket.drawingYRelLeft;
    final Object? beamObj = tuplet.bracketAlignedBeam;
    if (beamObj is! Beam) return plain;
    final BeamSegment seg = beamObj.beamSegment;
    if (seg.beamElementCoordRefs.isEmpty) return plain;
    final int xLeft = tuplet.drawingLeft!.getDrawingX() + bracket.drawingXRelLeft;
    return seg.getStartingY() +
        (seg.beamSlope * (xLeft - seg.getStartingX())).toInt() +
        bracket.drawingYRel +
        bracket.drawingYRelLeft;
  }

  int _tupletBracketDrawingYRight(Tuplet tuplet, TupletBracket bracket) {
    final int plain = bracket.getDrawingY() + bracket.drawingYRelRight;
    final Object? beamObj = tuplet.bracketAlignedBeam;
    if (beamObj is! Beam) return plain;
    final BeamSegment seg = beamObj.beamSegment;
    if (seg.beamElementCoordRefs.isEmpty) return plain;
    final int xRight = tuplet.drawingRight!.getDrawingX() + bracket.drawingXRelRight;
    return seg.getStartingY() +
        (seg.beamSlope * (xRight - seg.getStartingX())).toInt() +
        bracket.drawingYRel +
        bracket.drawingYRelRight;
  }

  int _tupletNumDrawingYMid(Tuplet tuplet, TupletNum tupletNum) {
    final Object? alignedBracketObj = tupletNum.alignedBracket;
    if (alignedBracketObj is TupletBracket) {
      final int yLeft = _tupletBracketDrawingYLeft(tuplet, alignedBracketObj);
      final int yRight = _tupletBracketDrawingYRight(tuplet, alignedBracketObj);
      return yLeft + ((yRight - yLeft) ~/ 2);
    } else {
      return tupletNum.getDrawingY();
    }
  }

  int _tupletNumDrawingXMid(Tuplet tuplet, TupletNum tupletNum) {
    final Object? alignedBracketObj = tupletNum.alignedBracket;
    if (alignedBracketObj is TupletBracket) {
      final int xLeft = _tupletBracketDrawingXLeft(tuplet, alignedBracketObj);
      final int xRight = _tupletBracketDrawingXRight(tuplet, alignedBracketObj);
      return xLeft + ((xRight - xLeft) ~/ 2);
    } else {
      int xLeft = tuplet.drawingLeft!.getDrawingX();
      int xRight = tuplet.drawingRight!.getDrawingX();
      if (doc != null) {
        xRight += _tupletGetDrawingRadius(tuplet.drawingRight!, doc!) * 2;
      }
      final Object? beamObj = tuplet.numAlignedBeam;
      if (beamObj is Beam) {
        final Beamplace place = beamObj.drawingPlace;
        switch (place) {
          case Beamplace.above:
            xLeft += _tupletGetDrawingRadius(tuplet.drawingLeft!, doc!);
            break;
          case Beamplace.below:
            xRight -= _tupletGetDrawingRadius(tuplet.drawingRight!, doc!);
            break;
          default:
            break;
        }
      }
      return xLeft + ((xRight - xLeft) ~/ 2);
    }
  }

  int _tupletGetDrawingRadius(LayerElement element, Doc doc) {
    if (!element.isAny(const {ClassId.chord, ClassId.note, ClassId.rest})) {
      return 0;
    }
    int code = 0;
    MeiDuration dur = MeiDuration.dur4;
    final Object? staffObj = element.getFirstAncestor(ClassId.staff);
    final Staff? staff = staffObj is Staff ? staffObj : null;
    if (staff == null) return 0;
    bool isMensuralDur = false;
    if (element is Note) {
      dur = element.getDrawingDur();
      isMensuralDur = element.isMensuralDur;
      code = _tupletNoteheadGlyphForDur(dur);
    } else if (element is Chord) {
      dur = element.getActualDur();
      isMensuralDur = element.isMensuralDur;
      code = _tupletNoteheadGlyphForDur(dur);
    } else if (element.classId == ClassId.rest) {
      code = 0xE0A4;
    }
    if (isMensuralDur && dur.value <= MeiDuration.breve.value) {
      return doc.getDrawingBrevisWidth(staff.drawingStaffSize);
    }
    if (code == 0) return 0;
    return doc.getGlyphWidth(code, staff.drawingStaffSize, element.drawingCueSize) ~/ 2;
  }

  int _tupletNoteheadGlyphForDur(MeiDuration dur) {
    if (dur == MeiDuration.breve) return 0xE0A1;
    if (dur == MeiDuration.long) return 0xE0A1;
    if (dur == MeiDuration.dur1) return 0xE0A2;
    if (dur == MeiDuration.dur2) return 0xE0A3;
    return 0xE0A4;
  }
}
