/// Port of `view_mensural.cpp` — mensural notation and ligatures (task 05-23).
///
/// Mirrors `View::DrawMensuralNote` (40), `DrawMensur` (80),
/// `DrawMensuralStem` (162), `DrawMaximaToBrevis` (206), `DrawLigature` (285),
/// `DrawLigatureNote` (329), `DrawDotInLigature` (465), `DrawPlica` (511),
/// `DrawProportFigures` (567), `DrawProport` (603), `CalcBrevisPoints` (614),
/// `CalcObliquePoints` (659) and `GetMensuralStemDir` (725) — 751 lines, 6.2.0.
///
/// This file is a `part` of the `view.dart` library (task 05-06 partitioning
/// decision: one `part` per `view_*.cpp`). The C++ continues the `View` class
/// here; Dart cannot split a class body across files, so the methods are
/// declared as members of the [ViewMensural] extension below — same library,
/// therefore the same privacy scope as the class members (like the C++ member
/// visibility from every `view_*.cpp`).
///
/// Deviations from the C++:
/// - the file-static `thread_local` state `s_drawingLigX[2]` / `s_drawingLigY[2]`
///   / `s_drawingLigObliqua` (view_mensural.cpp:33-34) is ported as three
///   library-level variables `_sDrawingLigX/_sDrawingLigY/_sDrawingLigObliqua`.
///   A `grep -n "s_drawingLig" origin/src/src/view_mensural.cpp` on 6.2.0
///   shows the definitions and **no other read or write**: the two-pass
///   oblique state the prompt describes is **not present in this version**
///   (the variables are dead). The Dart keeps them as `// ignore: unused_field`
///   faithfully and documents the deviation here rather than inventing a_reset.
/// - `char32_t code` becomes a Unicode code point `int`; `std::u32string`
///   becomes a Dart `String`.
/// - `Point *topLeft` / `int sides[4]` / `Point points[4]` become mutable
///   Dart `Point` objects and `List<int>` of length 4.
/// - `DeviceContext *dc` becomes non-nullable [DeviceContext]; the `assert(dc)`
///   is subsumed.
/// - `DrawBentParallelogramFilled` (the curved oblique ligature) has no Dart
///   `DeviceContext` counterpart yet; the curved branch falls back to
///   `drawObliquePolygon` (straight) — unexercised by the current mensural/
///   ligature corpus (no `ligatureOblique=curved` file), so structural fidelity
///   is preserved while `dart analyze` stays ≤ 8.
/// - Options `ligatureOblique` and `ligatureAsBracket` are read through
///   `doc.getOptions()` with a dynamic fallback: the Dart shell currently
///   exposes only `ligatureAsBracket`; absence is treated as `false`/`auto`.
part of 'view.dart';

// ---------------------------------------------------------------------------
// File-static ligature state (view_mensural.cpp:33-34, thread_local).
// ---------------------------------------------------------------------------

// ignore: unused_field
final List<int> _sDrawingLigX = [0, 0];
// ignore: unused_field
final List<int> _sDrawingLigY = [0, 0];
// ignore: unused_field
bool _sDrawingLigObliqua = false;

// SMuFL mensural prolation / stem code points (view_mensural.cpp).
const int _smuflE910MensuralProlation1 = 0xE910;
const int _smuflE911MensuralProlation2 = 0xE911;
const int _smuflE915MensuralProlation6 = 0xE915;
const int _smuflE916MensuralProlation7 = 0xE916;
const int _smuflE920MensuralProlationCombiningDot = 0xE920;
const int _smuflE925MensuralProlationCombiningStroke = 0xE925;
const int _smuflE93EMensuralCombStemUp = 0xE93E;
const int _smuflE93FMensuralCombStemDown = 0xE93F;
const int _smuflE949MensuralCombStemUpFlagSemiminima = 0xE949;
const int _smuflE94AMensuralCombStemDownFlagSemiminima = 0xE94A;
const int _smuflE94BMensuralCombStemUpFlagFusa = 0xE94B;
const int _smuflE94CMensuralCombStemDownFlagFusa = 0xE94C;

// Mensural notehead codes used by GetMensuralNoteheadGlyph (note.cpp:601).
const int _smuflE938MensuralNoteheadSemibrevisBlack = 0xE938;
const int _smuflE93CMensuralNoteheadMinimaWhite = 0xE93C;
const int _smuflE93DMensuralNoteheadSemiminimaWhite = 0xE93D;

/// The `view_mensural.cpp` methods of [View] (task 05-23).
extension ViewMensural on View {
  dynamic _dyn(dynamic o) => o;
  // -----------------------------------------------------------------------
  // View::DrawMensuralNote (view_mensural.cpp:40)
  // -----------------------------------------------------------------------

  /// Mirrors `View::DrawMensuralNote` (view_mensural.cpp:40).
  void drawMensuralNote(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final Note note = element as Note;

    int x = element.getDrawingX();
    int y = element.getDrawingY();

    final (int ox, int oy) = calcOffset(dc, x, y);
    x = ox;
    y = oy;

    final MeiDuration drawingDur = note.getDrawingDur();

    /************** Noteheads: **************/

    // Ligature, maxima, longa, and brevis
    if (note.isInLigature() && !doc!.getOptions().ligatureAsBracket.value) {
      drawLigatureNote(dc, element, layer, staff);
    } else if (drawingDur.value < MeiDuration.dur1.value) {
      drawMaximaToBrevis(dc, y, element, layer, staff);
    }
    // Semibrevis and shorter
    else {
      final int code = note.getMensuralNoteheadGlyph();
      dc.startCustomGraphic('notehead');
      drawSmuflCode(dc, x, y, code, staff.drawingStaffSize, false);
      dc.endCustomGraphic();
    }

    /************ Draw children (verse / syl) ************/

    drawLayerChildren(dc, note, layer, staff, measure);
  }

  // -----------------------------------------------------------------------
  // View::DrawMensur (view_mensural.cpp:80)
  // -----------------------------------------------------------------------

  /// Mirrors `View::DrawMensur` (view_mensural.cpp:80).
  void drawMensur(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final dynamic mensur = _dyn(element);

    bool hasSign = false;
    bool hasNum = false;

    hasSign = mensur.hasSign == true;

    hasNum = mensur.hasNum == true;

    if (!hasSign && !hasNum) return;

    int y = staff.getDrawingY() -
        doc!.getDrawingUnit(staff.drawingStaffSize) * (staff.drawingLines - 1);
    int x = element.getDrawingX();
    final int perfectRadius = doc!.getGlyphWidth(
            _smuflE910MensuralProlation1, staff.drawingStaffSize, false) ~/
        2;
    int code = 0;

    bool hasLoc = false;
    int locVal = 0;

    hasLoc = mensur.hasLoc == true;
    if (hasLoc) locVal = mensur.loc as int;

    bool hasNumbase = false;

    hasNumbase = mensur.hasNumbase == true;

    if (hasLoc) {
      y = staff.getDrawingY() -
          doc!.getDrawingUnit(staff.drawingStaffSize) *
              (2 * staff.drawingLines - 2 - locVal);
    } else if (hasNumbase && !hasNum) {
      y += 2 * doc!.getDrawingUnit(staff.drawingStaffSize);
    }

    Mensurationsign? sign;
    sign = mensur.sign as Mensurationsign?;
    Orientation? orient;
    orient = mensur.orient as Orientation?;

    if (sign == Mensurationsign.o) {
      code = _smuflE911MensuralProlation2;
    } else if (sign == Mensurationsign.c) {
      if (orient == Orientation.reversed) {
        code = _smuflE916MensuralProlation7;
      } else {
        code = _smuflE915MensuralProlation6;
      }
    }

    dc.startGraphic(element, '', element.id);

    drawSmuflCode(dc, x, y, code, staff.drawingStaffSize, false);

    x += perfectRadius;

    bool hasSlash = false;

    hasSlash = mensur.hasSlash == true;
    if (!hasSlash) {
      hasSlash = mensur.slash != null;
    }

    if (hasSlash) {
      final int w = doc!.getGlyphWidth(
              _smuflE925MensuralProlationCombiningStroke,
              staff.drawingStaffSize,
              false) ~/
          2;
      drawSmuflCode(dc, x - w, y, _smuflE925MensuralProlationCombiningStroke,
          staff.drawingStaffSize, false);
    }

    bool hasDot = false;

    // mensur.dot is bool in AttMensurVis
    hasDot = mensur.dot == true;

    if (hasDot) {
      final int w = doc!.getGlyphWidth(_smuflE920MensuralProlationCombiningDot,
              staff.drawingStaffSize, false) ~/
          2;
      drawSmuflCode(dc, x - w, y, _smuflE920MensuralProlationCombiningDot,
          staff.drawingStaffSize, false);
    }

    if (hasNum) {
      x = element.getDrawingX();
      bool hasSignOrTempus = false;

      hasSignOrTempus = (mensur.hasSign == true) || (mensur.hasTempus == true);

      if (hasSignOrTempus) {
        x += doc!.getDrawingUnit(staff.drawingStaffSize) * 6;
      }
      int numbase = 0;
      if (hasNumbase) {
        numbase = mensur.numbase as int;
      }
      int numVal = 0;
      numVal = mensur.num as int;
      drawProportFigures(dc, x, y, numVal, numbase, staff);
    } else if (hasNumbase) {
      y -= 4 * doc!.getDrawingUnit(staff.drawingStaffSize);
      int nb = 0;
      nb = mensur.numbase as int;
      drawProportFigures(dc, x, y, nb, 0, staff);
    }

    dc.endGraphic(element);
  }

  // -----------------------------------------------------------------------
  // View::DrawMensuralStem (view_mensural.cpp:162)
  // -----------------------------------------------------------------------

  /// Mirrors `View::DrawMensuralStem` (view_mensural.cpp:162).
  void drawMensuralStem(DeviceContext dc, Note note, Staff staff,
      Stemdirection dir, int xn, int originY) {
    final int staffSize = staff.drawingStaffSize;
    MeiDuration drawingDur = MeiDuration.none;

    drawingDur = note.getDrawingDur();

    int radius = 0;

    radius = _getDrawingRadius(note, staff);

    const bool drawingCueSize = false;
    bool mensuralBlack = false;

    mensuralBlack = staff.drawingNotationtype == Notationtype.mensuralBlack;

    final int nbFlags = mensuralBlack
        ? drawingDur.value - MeiDuration.dur2.value
        : drawingDur.value - MeiDuration.dur4.value;

    final int halfStemWidth = doc!.getGlyphWidth(
            _smuflE93EMensuralCombStemUp, staffSize, drawingCueSize) ~/
        2;
    final int yOffset = doc!.getDrawingUnit(staffSize) - halfStemWidth;
    originY = (dir == Stemdirection.up) ? originY + yOffset : originY - yOffset;

    int code;
    if (dir == Stemdirection.up) {
      switch (nbFlags) {
        case 1:
          code = _smuflE949MensuralCombStemUpFlagSemiminima;
          break;
        case 2:
          code = _smuflE94BMensuralCombStemUpFlagFusa;
          break;
        default:
          code = _smuflE93EMensuralCombStemUp;
      }
    } else {
      switch (nbFlags) {
        case 1:
          code = _smuflE94AMensuralCombStemDownFlagSemiminima;
          break;
        case 2:
          code = _smuflE94CMensuralCombStemDownFlagFusa;
          break;
        default:
          code = _smuflE93FMensuralCombStemDown;
      }
    }

    drawSmuflCode(dc, xn + radius - halfStemWidth, originY, code,
        staff.drawingStaffSize, drawingCueSize);

    _dyn(note).setDrawingStemDir(dir);
  }

  // -----------------------------------------------------------------------
  // View::DrawMaximaToBrevis (view_mensural.cpp:206)
  // -----------------------------------------------------------------------

  /// Mirrors `View::DrawMaximaToBrevis` (view_mensural.cpp:206).
  void drawMaximaToBrevis(
      DeviceContext dc, int y, LayerElement element, Layer layer, Staff staff) {
    final Note note = element as Note;

    bool isMensuralBlack = false;

    isMensuralBlack = staff.drawingNotationtype == Notationtype.mensuralBlack;

    bool colored = false;

    colored = _dyn(note).colored == true;

    final bool fillNotehead =
        (isMensuralBlack || colored) && !(isMensuralBlack && colored);

    final int stemWidth = doc!.getDrawingStemWidth(staff.drawingStaffSize);
    final int strokeWidth = (2.8 * stemWidth).toInt();
    final int staffSize = staff.drawingStaffSize;

    MeiDuration actualDur = MeiDuration.none;

    actualDur = note.getActualDur();

    int shape = ligatureDefault;
    if (actualDur != MeiDuration.breve) {
      bool up = false;
      bool hasStemDir = false;
      Stemdirection sd = Stemdirection.none;
      try {
        hasStemDir =
            _dyn(note).hasStemDir == true || _dyn(note).stemDir != null;
        sd = _dyn(note).stemDir as Stemdirection;
      } catch (e) {
        try {
          final dynamic d = _dyn(note).getStemDir();
          if (d != null) {
            hasStemDir = true;
            sd = d as Stemdirection;
          }
        } catch (e) {
          e.toString();
        }
      }
      if (hasStemDir && sd != Stemdirection.none) {
        up = (sd == Stemdirection.up);
      } else {
        bool isCmn = false;

        isCmn = staff.drawingNotationtype == Notationtype.none ||
            staff.drawingNotationtype == Notationtype.cmn;

        if (isCmn) {
          Stemdirection d = Stemdirection.none;
          d = _dyn(note).getDrawingStemDir() as Stemdirection;
          up = (d == Stemdirection.up);
        } else if (!isMensuralBlack) {
          final int verticalCenter = staff.getDrawingY() -
              doc!.getDrawingUnit(staffSize) * (staff.drawingLines - 1);
          up = (note.getDrawingY() < verticalCenter);
        }
      }
      shape = up ? ligatureStemRightUp : ligatureStemRightDown;
    }

    final Point topLeft = Point();
    final Point bottomRight = Point();
    final List<int> sides = List<int>.filled(4, 0);
    calcBrevisPoints(
        note, staff, topLeft, bottomRight, sides, shape, isMensuralBlack);

    dc.startCustomGraphic('notehead');

    if (!fillNotehead) {
      drawObliquePolygon(dc, topLeft.x + stemWidth, topLeft.y,
          bottomRight.x - stemWidth, topLeft.y, -strokeWidth);
      drawObliquePolygon(dc, topLeft.x + stemWidth, bottomRight.y,
          bottomRight.x - stemWidth, bottomRight.y, strokeWidth);
    } else {
      drawFilledRectangle(dc, topLeft.x + stemWidth, topLeft.y,
          bottomRight.x - stemWidth, bottomRight.y);
    }

    final Object? plica = note.findDescendantByType(ClassId.plica);
    if (plica != null) {
      dc.endCustomGraphic();
      return;
    }

    drawFilledRectangle(
        dc, topLeft.x, sides[0], topLeft.x + stemWidth, sides[1]);

    if (actualDur != MeiDuration.breve) {
      dc.endCustomGraphic();
      dc.startCustomGraphic('stem');
      drawFilledRectangle(
          dc, bottomRight.x - stemWidth, sides[2], bottomRight.x, sides[3]);
      dc.endCustomGraphic();
    } else {
      drawFilledRectangle(
          dc, bottomRight.x - stemWidth, sides[2], bottomRight.x, sides[3]);
      dc.endCustomGraphic();
    }
  }

  // -----------------------------------------------------------------------
  // View::DrawLigature (view_mensural.cpp:285)
  // -----------------------------------------------------------------------

  /// Mirrors `View::DrawLigature` (view_mensural.cpp:285).
  void drawLigature(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final dynamic ligature = _dyn(element);

    dc.startGraphic(element, '', element.id);

    drawLayerChildren(dc, ligature as Object, layer, staff, measure);

    bool ligatureAsBracket = false;

    ligatureAsBracket = (doc!.getOptions()).ligatureAsBracket.value as bool;

    if (ligatureAsBracket) {
      List<Object> notes = [];

      notes = _dyn(ligature).getList() as List<Object>;

      if (notes.isEmpty) {
        notes = _dyn(ligature).getList();
      }
      if (notes.isNotEmpty) {
        int y = staff.getDrawingY();
        Note? firstNote;
        Note? lastNote;
        firstNote = _dyn(ligature).getFirstNote() as Note?;
        lastNote = _dyn(ligature).getLastNote() as Note?;
        firstNote ??= notes.firstWhere((o) => o is Note,
            orElse: () => notes.first) as Note?;
        lastNote ??= notes.lastWhere((o) => o is Note, orElse: () => notes.last)
            as Note?;
        int x1 = 0;
        int x2 = 0;
        x1 = firstNote!.getContentLeft();
        x2 = lastNote!.getContentRight();
        for (final Object obj in notes) {
          if (obj is Note) {
            int top = 0;
            top = obj.getContentTop();
            if (top > y) y = top;
          }
        }
        final int bracketSize = 2 * doc!.getDrawingUnit(staff.drawingStaffSize);
        y += bracketSize + doc!.getDrawingStemWidth(staff.drawingStaffSize);
        final int lineWidth = doc!.getDrawingStemWidth(staff.drawingStaffSize);
        drawFilledRectangle(dc, x1, y, x1 + lineWidth, y - bracketSize);
        drawFilledRectangle(dc, x1, y, x2, y - lineWidth);
        drawFilledRectangle(dc, x2 - lineWidth, y, x2, y - bracketSize);
      }
    }

    dc.endGraphic(element);
  }

  // -----------------------------------------------------------------------
  // View::DrawLigatureNote (view_mensural.cpp:329)
  // -----------------------------------------------------------------------

  /// Mirrors `View::DrawLigatureNote` (view_mensural.cpp:329).
  void drawLigatureNote(
      DeviceContext dc, LayerElement element, Layer layer, Staff staff) {
    final Note note = element as Note;
    final dynamic ligature = note.getFirstAncestor(ClassId.ligature);
    if (ligature == null) return;

    List<int> drawingShapes = [];

    drawingShapes = (ligature.drawingShapes as List<int>);

    if (drawingShapes.length < 2) return;

    Note? prevNote;
    Note? nextNote;
    prevNote = _dyn(ligature).getListPrevious(note) as Note?;
    nextNote = _dyn(ligature).getListNext(note) as Note?;

    int position = -1;
    position = _dyn(ligature).getListIndex(note) as int;
    if (position == -1) return;

    final int shape = drawingShapes[position];
    final int prevShape = (position > 0) ? drawingShapes[position - 1] : 0;

    bool isMensuralBlack = false;
    isMensuralBlack = staff.drawingNotationtype == Notationtype.mensuralBlack;

    bool colored = false;
    colored = _dyn(note).colored == true;
    final bool fillNotehead =
        (isMensuralBlack || colored) && !(isMensuralBlack && colored);
    final bool oblique = ((shape & ligatureOblique) != 0) ||
        ((prevShape & ligatureOblique) != 0);
    final bool obliqueEnd = (prevShape & ligatureOblique) != 0;
    final bool stackedEnd = (shape & ligatureStacked) != 0;
    final int stemWidth = doc!.getDrawingStemWidth(staff.drawingStaffSize);
    final int strokeWidth = (2.8 * stemWidth).toInt();

    bool straight = true;
    // ligatureOblique option — not in current shell, fallback to auto logic.
    try {
      final dynamic opt = _dyn(doc!.getOptions()).ligatureOblique;
      if (opt != null) {
        final dynamic val = opt.value;
        final String s = val.toString().toLowerCase();
        if (s.contains('straight'))
          straight = true;
        else if (s.contains('curved'))
          straight = false;
        else
          straight = !isMensuralBlack;
      } else {
        straight = !isMensuralBlack;
      }
    } catch (e) {
      straight = !isMensuralBlack;
    }

    final List<Point> points = List<Point>.generate(4, (_) => Point());
    Point topLeft = points[0];
    Point bottomLeft = points[1];
    Point topRight = points[2];
    Point bottomRight = points[3];
    final List<int> sides = List<int>.filled(4, 0);

    if (!oblique) {
      calcBrevisPoints(
          note, staff, topLeft, bottomRight, sides, shape, isMensuralBlack);
      bottomLeft.x = topLeft.x;
      bottomLeft.y = bottomRight.y;
      topRight.x = bottomRight.x;
      topRight.y = topLeft.y;
    } else {
      if ((shape & ligatureOblique) != 0 && nextNote != null) {
        calcObliquePoints(note, nextNote, staff, points, sides, shape,
            isMensuralBlack, true, straight);
      } else if ((prevShape & ligatureOblique) != 0 && prevNote != null) {
        calcObliquePoints(prevNote, note, staff, points, sides, prevShape,
            isMensuralBlack, false, straight);
      } else {
        return;
      }
      topLeft = points[0];
      bottomLeft = points[1];
      topRight = points[2];
      bottomRight = points[3];
    }

    if (straight) {
      if (!fillNotehead) {
        drawObliquePolygon(
            dc, topLeft.x, topLeft.y, topRight.x, topRight.y, -strokeWidth);
        drawObliquePolygon(dc, bottomLeft.x, bottomLeft.y, bottomRight.x,
            bottomRight.y, strokeWidth);
      } else {
        drawObliquePolygon(dc, topLeft.x, topLeft.y, topRight.x, topRight.y,
            bottomLeft.y - topLeft.y);
      }
    } else {
      // Curved (bent) parallelogram — mirrors the C++ branch (view_mensural.cpp:408-431):
      // the curved side is built from device-context points, then drawn with
      // DrawBentParallelogramFilled (path with two cubic beziers).
      final int thickness = topLeft.y - bottomLeft.y;
      final List<Point> curvedSide = List<Point>.generate(4, (_) => Point());
      curvedSide[0] = toDeviceContext(topLeft);
      curvedSide[3] = toDeviceContext(topRight);
      final int width = curvedSide[3].x - curvedSide[0].x;
      final int height = curvedSide[3].y - curvedSide[0].y;
      curvedSide[1] = Point(curvedSide[3].x, curvedSide[3].y);
      // Mirrors C++ `Point::x -= (width * 0.7)` compound-assignment
      // semantics: single truncation of the full double result
      // (`x = (int)(x - width * 0.7)`), not per-term truncation.
      curvedSide[1].x = (curvedSide[1].x - width * 0.7).toInt();
      curvedSide[1].y =
          (curvedSide[1].y - (height * 0.7 + height * 0.07)).toInt();
      curvedSide[2] = Point(curvedSide[3].x, curvedSide[3].y);
      curvedSide[2].x = (curvedSide[2].x - width * 0.3).toInt();
      curvedSide[2].y =
          (curvedSide[2].y - (height * 0.3 + height * 0.07)).toInt();

      if (!fillNotehead) {
        dc.drawBentParallelogramFilled(
            curvedSide, toDeviceContextX(strokeWidth));
        for (final Point p in curvedSide)
          p.y += toDeviceContextX(thickness - strokeWidth);
        dc.drawBentParallelogramFilled(
            curvedSide, toDeviceContextX(strokeWidth));
      } else {
        dc.drawBentParallelogramFilled(curvedSide, toDeviceContextX(thickness));
      }
    }

    if (!obliqueEnd) {
      int sideTop = sides[0];
      int sideBottom = sides[1];
      if (prevNote != null) {
        final Point prevTopLeft = Point(topLeft.x, topLeft.y);
        final Point prevBottomRight = Point(bottomRight.x, bottomRight.y);
        final List<int> prevSides = List<int>.filled(4, 0);
        for (int i = 0; i < 4; i++) prevSides[i] = sides[i];
        calcBrevisPoints(prevNote, staff, prevTopLeft, prevBottomRight,
            prevSides, prevShape, isMensuralBlack);
        if (!stackedEnd) {
          sideTop = sides[0] > prevSides[2] ? sides[0] : prevSides[2];
          sideBottom = sides[1] < prevSides[3] ? sides[1] : prevSides[3];
        } else {
          sides[3] = prevSides[3];
        }
      }
      drawFilledRoundedRectangle(dc, topLeft.x, sideTop, topLeft.x + stemWidth,
          sideBottom, stemWidth ~/ 3);
    }

    if (nextNote == null) {
      drawFilledRoundedRectangle(dc, bottomRight.x - stemWidth, sides[2],
          bottomRight.x, sides[3], stemWidth ~/ 3);
    }
  }

  // -----------------------------------------------------------------------
  // View::DrawDotInLigature (view_mensural.cpp:465)
  // -----------------------------------------------------------------------

  /// Mirrors `View::DrawDotInLigature` (view_mensural.cpp:465).
  void drawDotInLigature(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final Dot dot = element as Dot;
    final Object? prev = dot.drawingPreviousElement;
    if (prev == null || prev is! Note) {
      int x = element.getDrawingX();
      int y = element.getDrawingY();
      final (int ox, int oy) = calcOffset(dc, x, y);
      x = ox;
      y = oy;
      drawDotsPart(dc, x, y, 1, staff);
      return;
    }
    final Note note = prev as Note;
    final dynamic ligature = note.getFirstAncestor(ClassId.ligature);
    double shiftMultiplier = 3.0;
    bool isVerticalDot = false;
    if (ligature != null) {
      bool ligatureAsBracket = false;
      ligatureAsBracket = (doc!.getOptions()).ligatureAsBracket.value as bool;
      if (!ligatureAsBracket) {
        int position = -1;
        position = _dyn(ligature).getListIndex(note) as int;
        if (position != -1) {
          List<int> shapes = [];
          shapes = _dyn(ligature).drawingShapes as List<int>;
          if (shapes.isNotEmpty && position < shapes.length) {
            final int shape = shapes[position];
            final bool isLast = position == shapes.length - 1;
            isVerticalDot = !isLast && (shape & ligatureOblique) != 0;
          }
        }
      } else {
        MeiDuration actualDur = MeiDuration.none;
        actualDur = note.getActualDur();
        if (actualDur == MeiDuration.dur1) shiftMultiplier = 3.5;
      }
    }

    int y = note.getDrawingY();
    int x = note.getDrawingX();
    if (isVerticalDot) {
      int radius = 0;
      radius = _getDrawingRadius(note, staff);
      x += radius;
      y += doc!.getDrawingUnit(staff.drawingStaffSize);
    } else {
      int radius = 0;
      radius = _getDrawingRadius(note, staff);
      x += (shiftMultiplier * radius).toInt();
      y -= doc!.getDrawingUnit(staff.drawingStaffSize);
    }

    drawDotsPart(dc, x, y, 1, staff);
  }

  // -----------------------------------------------------------------------
  // View::DrawPlica (view_mensural.cpp:511)
  // -----------------------------------------------------------------------

  /// Mirrors `View::DrawPlica` (view_mensural.cpp:511).
  void drawPlica(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final dynamic plica = _dyn(element);
    Note? note;
    note = plica.getFirstAncestor(ClassId.note) as Note?;
    if (note == null) return;

    bool isMensuralBlack = false;
    isMensuralBlack = staff.drawingNotationtype == Notationtype.mensuralBlack;
    final int stemWidth = doc!.getDrawingStemWidth(staff.drawingStaffSize);

    bool isLonga = false;

    final MeiDuration d = note.getActualDur();
    isLonga = (d == MeiDuration.long);

    // Fallback via string
    if (!isLonga) {
      final String s = _dyn(note).dur.toString().toLowerCase();
      if (s.contains('long')) isLonga = true;
    }
    bool up = false;

    final dynamic dir = plica.dir;
    final String s = dir.toString().toLowerCase();
    up = s.contains('up');

    int shape = ligatureDefault;
    final Point topLeft = Point();
    final Point bottomRight = Point();
    final List<int> sides = List<int>.filled(4, 0);
    calcBrevisPoints(
        note, staff, topLeft, bottomRight, sides, shape, isMensuralBlack);

    int stem = doc!.getDrawingUnit(staff.drawingStaffSize);
    stem *= (!isMensuralBlack) ? 7 : 5;
    int shortStem = doc!.getDrawingUnit(staff.drawingStaffSize);
    shortStem *= (!isMensuralBlack)
        ? 4
        : 3; // 3.5 and 2.5 approximated as int factor 4/3 for structural
    // Preserve original half-unit for accuracy: use double then toInt
    stem = (doc!.getDrawingUnit(staff.drawingStaffSize) *
            (!isMensuralBlack ? 7 : 5))
        .toInt();
    shortStem = (doc!.getDrawingUnit(staff.drawingStaffSize) *
            (!isMensuralBlack ? 3.5 : 2.5))
        .toInt();

    dc.startGraphic(element, '', element.id);

    if (isLonga) {
      if (up) {
        drawFilledRectangle(dc, topLeft.x, sides[1], topLeft.x + stemWidth,
            sides[1] + shortStem);
        drawFilledRectangle(dc, bottomRight.x, sides[1],
            bottomRight.x - stemWidth, sides[1] + stem);
      } else {
        drawFilledRectangle(dc, topLeft.x, sides[0], topLeft.x + stemWidth,
            sides[0] - shortStem);
        drawFilledRectangle(dc, bottomRight.x, sides[0],
            bottomRight.x - stemWidth, sides[0] - stem);
      }
    } else {
      if (up) {
        drawFilledRectangle(
            dc, topLeft.x, sides[1], topLeft.x + stemWidth, sides[1] + stem);
        drawFilledRectangle(dc, bottomRight.x, sides[1],
            bottomRight.x - stemWidth, sides[1] + shortStem);
      } else {
        drawFilledRectangle(
            dc, topLeft.x, sides[0], topLeft.x + stemWidth, sides[0] - stem);
        drawFilledRectangle(dc, bottomRight.x, sides[0],
            bottomRight.x - stemWidth, sides[0] - shortStem);
      }
    }

    dc.endGraphic(element);
  }

  // -----------------------------------------------------------------------
  // View::DrawProportFigures / DrawProport (view_mensural.cpp:567,603)
  // -----------------------------------------------------------------------

  /// Mirrors `View::DrawProportFigures` (view_mensural.cpp:567).
  void drawProportFigures(
      DeviceContext dc, int x, int y, int num, int numBase, Staff staff) {
    int yNum = 0, yDen = 0;
    final int textSize = staff.drawingStaffSize;
    String wtext;

    if (numBase != 0) {
      yNum = y + doc!.getDrawingDoubleUnit(textSize);
      yDen = y - doc!.getDrawingDoubleUnit(textSize);
    } else {
      yNum = y;
    }

    if (numBase > 9 || num > 9) {
      x += doc!.getDrawingUnit(textSize) * 2;
    }

    dc.setFont(doc!.getDrawingSmuflFont(textSize, false));

    wtext = intToTimeSigFigures(num);
    drawSmuflString(dc, x, yNum, wtext, HorizontalAlignment.center, textSize);

    if (numBase != 0) {
      wtext = intToTimeSigFigures(numBase);
      drawSmuflString(dc, x, yDen, wtext, HorizontalAlignment.center, textSize);
    }

    dc.resetFont();
  }

  /// Mirrors `View::DrawProport` (view_mensural.cpp:603) — placeholder graphic.
  void drawProport(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    dc.startGraphic(element, '', element.id);
    dc.endGraphic(element);
  }

  // -----------------------------------------------------------------------
  // View::CalcBrevisPoints (view_mensural.cpp:614)
  // -----------------------------------------------------------------------

  /// Mirrors `View::CalcBrevisPoints` (view_mensural.cpp:614).
  void calcBrevisPoints(Note note, Staff staff, Point topLeft,
      Point bottomRight, List<int> sides, int shape, bool isMensuralBlack) {
    final int y = note.getDrawingY();
    topLeft.x = note.getDrawingX();
    int width = 0;

    width = 2 * _getDrawingRadius(note, staff);

    bottomRight.x = topLeft.x + width;

    final double heightFactor = isMensuralBlack ? 0.8 : 1.0;
    topLeft.y = y +
        (doc!.getDrawingUnit(staff.drawingStaffSize) * heightFactor).toInt();
    bottomRight.y = y -
        (doc!.getDrawingUnit(staff.drawingStaffSize) * heightFactor).toInt();

    sides[0] = topLeft.y;
    sides[1] = bottomRight.y;

    if (!isMensuralBlack) {
      sides[0] += doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 3;
      sides[1] -= doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 3;
    } else if ((shape & ligatureOblique) != 0) {
      sides[0] -= doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 2;
      sides[1] += doc!.getDrawingUnit(staff.drawingStaffSize) ~/ 2;
    }

    sides[2] = sides[0];
    sides[3] = sides[1];

    int stem = doc!.getDrawingUnit(staff.drawingStaffSize);
    stem *= (!isMensuralBlack) ? 7 : 5;

    if ((shape & ligatureStemLeftUp) != 0) sides[0] = y + stem;
    if ((shape & ligatureStemLeftDown) != 0) sides[1] = y - stem;
    if ((shape & ligatureStemRightUp) != 0) sides[2] = y + stem;
    if ((shape & ligatureStemRightDown) != 0) sides[3] = y - stem;
  }

  // -----------------------------------------------------------------------
  // View::CalcObliquePoints (view_mensural.cpp:659)
  // -----------------------------------------------------------------------

  /// Mirrors `View::CalcObliquePoints` (view_mensural.cpp:659).
  void calcObliquePoints(
      Note note1,
      Note note2,
      Staff staff,
      List<Point> points,
      List<int> sides,
      int shape,
      bool isMensuralBlack,
      bool firstHalf,
      bool straight) {
    final int stemWidth = doc!.getDrawingStemWidth(staff.drawingStaffSize);
    int noteDiff = 0;

    noteDiff = _dyn(note1).pitchDifferenceTo(note2) as int;

    // Adjustment: C++ uses noteDiff * stemWidth /5 . NoteDiff positive when note1 higher than note2.
    final int yAdjust = noteDiff * stemWidth ~/ 5;

    final Point topLeft = points[0];
    final Point bottomLeft = points[1];
    final Point topRight = points[2];
    final Point bottomRight = points[3];

    final List<int> sides1 = List<int>.filled(4, 0);
    calcBrevisPoints(
        note1, staff, topLeft, bottomLeft, sides1, shape, isMensuralBlack);
    bottomLeft.x = topLeft.x;
    sides[0] = sides1[0];
    sides[1] = sides1[1];

    final List<int> sides2 = List<int>.filled(4, 0);
    calcBrevisPoints(note2, staff, topRight, bottomRight, sides2,
        ligatureOblique, isMensuralBlack);
    topRight.x = bottomRight.x;
    sides[2] = sides2[2];
    sides[3] = sides2[3];

    double slope = 0.0;
    if (bottomRight.x != bottomLeft.x) {
      slope = (bottomRight.y - bottomLeft.y) /
          (bottomRight.x - bottomLeft.x).toDouble();
    }

    int length = (bottomRight.x - bottomLeft.x) ~/ 2;
    if (!straight) slope *= 0.85;

    if (firstHalf) {
      length += 1;
      bottomRight.x = bottomLeft.x + length;
      topRight.x = bottomRight.x;
      bottomRight.y = bottomLeft.y + (length * slope).toInt();
      topRight.y = topLeft.y + (length * slope).toInt();
      topLeft.y += yAdjust;
      bottomLeft.y += yAdjust;
    } else {
      bottomLeft.x = bottomLeft.x + length;
      topLeft.x = bottomLeft.x;
      bottomLeft.y = bottomLeft.y + (length * slope).toInt();
      topLeft.y = topLeft.y + (length * slope).toInt();
      topRight.y -= yAdjust;
      bottomRight.y -= yAdjust;
    }
  }

  // -----------------------------------------------------------------------
  // View::GetMensuralStemDir (view_mensural.cpp:725)
  // -----------------------------------------------------------------------

  /// Mirrors `View::GetMensuralStemDir` (view_mensural.cpp:725).
  Stemdirection getMensuralStemDir(Layer layer, Note note, int verticalCenter) {
    MeiDuration drawingDur = MeiDuration.none;

    drawingDur = note.getDrawingDur();

    final int yNote = note.getDrawingY();

    Stemdirection layerStemDir = Stemdirection.none;
    Stemdirection stemDir = Stemdirection.none;
    bool hasStemDir = false;

    hasStemDir = _dyn(note).hasStemDir == true;
    if (hasStemDir) stemDir = _dyn(note).stemDir as Stemdirection;

    if (hasStemDir && stemDir != Stemdirection.none) {
      return stemDir;
    }

    try {
      layerStemDir = _dyn(layer).getDrawingStemDir(note) as Stemdirection;
    } catch (e) {
      layerStemDir = layer.getDrawingStemDir() as Stemdirection;
    }
    if (layerStemDir != Stemdirection.none) return layerStemDir;

    if (drawingDur.value < MeiDuration.dur1.value) {
      return Stemdirection.down;
    } else {
      return (yNote > verticalCenter) ? Stemdirection.down : Stemdirection.up;
    }
  }
}
