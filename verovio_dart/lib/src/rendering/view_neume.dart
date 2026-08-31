/// Port of `view_neume.cpp` — neumática (task 05-24).
///
/// Mirrors `View::DrawSyllable` (35), `DrawLiquescent` (58), `DrawNc` (70),
/// `DrawNeume` (97), `DrawNcAsNotehead` (153), `DrawDivLine` (173),
/// `DrawEpisema` (215), `DrawOriscus` (267), `DrawQuilisma` (279),
/// `DrawStrophicus` (291), `DrawNcGlyphs` (303) — 322 linhas, 6.2.0.
///
/// This file is a `part` of the `view.dart` library (task 05-06 partitioning
/// decision: one `part` per `view_*.cpp`). The C++ continues the `View` class
/// here; Dart cannot split a class body across files, so the methods are
/// declared as members of the [ViewNeume] extension below — same library,
/// therefore the same privacy scope as the class members (like the C++ member
/// visibility from every `view_*.cpp`).
///
/// Deviations from the C++:
/// - `DeviceContext *dc` pointers become non-nullable [DeviceContext] references.
/// - `vrv_cast<Nc *>` / `dynamic_cast<Syllable *>` become Dart `as` casts.
/// - `m_options->m_neumeAsNote` becomes `doc!.getOptions().neumeAsNote.value`.
/// - `m_doc->GetOptions()->m_octaveLineThickness` is read via
///   `doc!.getOptions().octaveLineThickness.value`.
/// - `Staff::IsOnStaffLine` is reproduced inline from staff.cpp:359.
/// - `Nc::m_drawingGlyphs` offsets are `double` in Dart (`float` in C++) — same
///   arithmetic.
/// - The `assert(dc)` / `assert(element)` checks are subsumed by non-nullable types.
part of 'view.dart';

// SMuFL code points used by view_neume.cpp (from include/vrv/smufl.h).
const int _smuflChantDivisioMinima = 0xE8F3;
const int _smuflChantDivisioMaior = 0xE8F4;
const int _smuflChantDivisioMaxima = 0xE8F5;
const int _smuflChantDivisioFinalis = 0xE8F6;
const int _smuflChantVirgula = 0xE8F7;
const int _smuflChantCaesura = 0xE8F8;
const int _smuflChantIctusAbove = 0xE9D0;
const int _smuflChantIctusBelow = 0xE9D1;
const int _smuflChantEpisema = 0xE9D8;

/// The `view_neume.cpp` methods of [View] (task 05-24).
extension ViewNeume on View {
  // -------------------------------------------------------------------------
  // View::DrawSyllable (view_neume.cpp:35)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawSyllable` (view_neume.cpp:35).
  void drawSyllable(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final Syllable syllable = element as Syllable;

    dc.startGraphic(element, '', element.id);

    drawLayerChildren(dc, syllable, layer, staff, measure);

    dc.endGraphic(element);
  }

  // -------------------------------------------------------------------------
  // View::DrawLiquescent (view_neume.cpp:58)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawLiquescent` (view_neume.cpp:58) — empty graphic.
  void drawLiquescent(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    dc.startGraphic(element, '', element.id);
    dc.endGraphic(element);
  }

  // -------------------------------------------------------------------------
  // View::DrawNc (view_neume.cpp:70)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawNc` (view_neume.cpp:70).
  void drawNc(DeviceContext dc, LayerElement element, Layer layer, Staff staff,
      Measure measure) {
    final Nc nc = element as Nc;

    final bool neumeAsNote = doc!.getOptions().neumeAsNote.value;

    if (neumeAsNote) {
      drawNcAsNotehead(dc, nc, layer, staff, measure);
      return;
    }

    dc.startGraphic(element, '', element.id);

    drawNcGlyphs(dc, nc, staff);

    // Draw the children (liquescent, oriscus, etc. — though they are empty)
    drawLayerChildren(dc, nc, layer, staff, measure);

    dc.endGraphic(element);
  }

  // -------------------------------------------------------------------------
  // View::DrawNeume (view_neume.cpp:97)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawNeume` (view_neume.cpp:97).
  void drawNeume(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final Neume neume = element as Neume;

    dc.startGraphic(element, '', element.id);
    drawLayerChildren(dc, neume, layer, staff, measure);

    final bool neumeAsNote = doc!.getOptions().neumeAsNote.value;

    if (neumeAsNote) {
      final Nc? first = neume.getFirst(ClassId.nc) as Nc?;
      final Nc? last = neume.getLast(ClassId.nc) as Nc?;
      if (first != null && last != null && !identical(first, last)) {
        final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
        final double octaveLineThickness =
            doc!.getOptions().octaveLineThickness.value;
        final int lineWidth = (octaveLineThickness * unit).toInt();

        int x1 = first.getDrawingX();
        int x2 = last.getDrawingX();
        int y = staff.getDrawingY();

        final (int ox1, int oy) = calcOffset(dc, x1, y);
        x1 = ox1;
        y = oy;
        x2 = calcOffsetX(dc, x2);

        final int maxNcY = first.getDrawingY() > last.getDrawingY()
            ? first.getDrawingY()
            : last.getDrawingY();
        if (maxNcY + unit > y) y = maxNcY + unit;
        y += 2 * unit;

        x1 += lineWidth ~/ 2;
        x2 += 2 * _getNcDrawingRadius(last, staff) - lineWidth ~/ 2;

        dc.setPen(lineWidth, PenStyle.solid,
            lineCap: LineCapStyle.butt, lineJoin: LineJoinStyle.miter);

        dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y),
            toDeviceContextX(x2), toDeviceContextY(y));
        dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y + lineWidth ~/ 2),
            toDeviceContextX(x1), toDeviceContextY(y - unit));
        dc.drawLine(toDeviceContextX(x2), toDeviceContextY(y + lineWidth ~/ 2),
            toDeviceContextX(x2), toDeviceContextY(y - unit));

        dc.resetPen();
      }
    }

    dc.endGraphic(element);
  }

  // -------------------------------------------------------------------------
  // View::DrawNcAsNotehead (view_neume.cpp:153)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawNcAsNotehead` (view_neume.cpp:153).
  void drawNcAsNotehead(
      DeviceContext dc, Nc nc, Layer layer, Staff staff, Measure measure) {
    dc.startGraphic(nc, '', nc.id);

    final int noteX = nc.getDrawingX();
    final int noteY = nc.getDrawingY();

    final bool cueSize = nc.findDescendantByType(ClassId.liquescent) != null;

    drawSmuflCode(dc, noteX, noteY, _smuflE0A4NoteheadBlack,
        staff.drawingStaffSize, cueSize, true);

    dc.endGraphic(nc);
  }

  // -------------------------------------------------------------------------
  // View::DrawDivLine (view_neume.cpp:173)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawDivLine` (view_neume.cpp:173).
  void drawDivLine(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final DivLine divLine = element as DivLine;

    dc.startGraphic(element, '', element.id);

    int sym = 0;
    final DivlinelogForm form = divLine.form ?? DivlinelogForm.none;
    switch (form) {
      case DivlinelogForm.minima:
        sym = _smuflChantDivisioMinima;
        break;
      case DivlinelogForm.maior:
        sym = _smuflChantDivisioMaior;
        break;
      case DivlinelogForm.maxima:
        sym = _smuflChantDivisioMaxima;
        break;
      case DivlinelogForm.finalis:
        sym = _smuflChantDivisioFinalis;
        break;
      case DivlinelogForm.caesura:
        sym = _smuflChantCaesura;
        break;
      case DivlinelogForm.virgula:
        sym = _smuflChantVirgula;
        break;
      default:
        break;
    }

    int x = divLine.getDrawingX();
    int y = staff.getDrawingY();

    final (int ox, int oy) = calcOffset(dc, x, y);
    x = ox;
    y = oy;

    y -= doc!.getDrawingUnit(staff.drawingStaffSize) * 3;

    if (staff.hasDrawingRotation()) {
      y -= staff.getDrawingRotationOffsetFor(x);
    }

    drawSmuflCode(dc, x, y, sym, staff.drawingStaffSize, false, true);

    dc.endGraphic(element);
  }

  // -------------------------------------------------------------------------
  // View::DrawEpisema (view_neume.cpp:215)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawEpisema` (view_neume.cpp:215).
  void drawEpisema(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final Episema episema = element as Episema;

    dc.startGraphic(element, '', element.id);

    final Nc? nc = episema.getFirstAncestor(ClassId.nc) as Nc?;
    if (nc != null) {
      int x = nc.getDrawingX();
      int y = nc.getDrawingY();

      if (nc.drawingGlyphs.isNotEmpty) {
        x += doc!.getGlyphWidth(
                nc.drawingGlyphs.first.fontNo, staff.drawingStaffSize, false) ~/
            2;
      }

      if (staff.hasDrawingRotation()) {
        y -= staff.getDrawingRotationOffsetFor(x);
      }

      final (int ox, int oy) = calcOffset(dc, x, y);
      x = ox;
      y = oy;

      final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
      final bool above = episema.place != Eventrel.below;

      // The SMuFL glyphs place their mark ~1 unit from the anchor.
      if (!_isOnStaffLine(y, staff)) {
        y += above ? unit : -unit;
      }

      final EpisemavisForm form = episema.form ?? EpisemavisForm.none;
      final int sym;
      if (form == EpisemavisForm.h) {
        sym = _smuflChantEpisema;
      } else {
        sym = above ? _smuflChantIctusAbove : _smuflChantIctusBelow;
      }

      drawSmuflCode(dc, x, y, sym, staff.drawingStaffSize, false, true);
    }

    dc.endGraphic(element);
  }

  // -------------------------------------------------------------------------
  // View::DrawOriscus / DrawQuilisma / DrawStrophicus (view_neume.cpp:267-301)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawOriscus` (view_neume.cpp:267) — empty graphic.
  void drawOriscus(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    dc.startGraphic(element, '', element.id);
    dc.endGraphic(element);
  }

  /// Mirrors `View::DrawQuilisma` (view_neume.cpp:279) — empty graphic.
  void drawQuilisma(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    dc.startGraphic(element, '', element.id);
    dc.endGraphic(element);
  }

  /// Mirrors `View::DrawStrophicus` (view_neume.cpp:291) — empty graphic.
  void drawStrophicus(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    dc.startGraphic(element, '', element.id);
    dc.endGraphic(element);
  }

  // -------------------------------------------------------------------------
  // View::DrawNcGlyphs (view_neume.cpp:303)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawNcGlyphs` (view_neume.cpp:303).
  void drawNcGlyphs(DeviceContext dc, Nc nc, Staff staff) {
    int ncX = nc.getDrawingX();
    int ncY = nc.getDrawingY();

    if (staff.hasDrawingRotation()) {
      ncY -= staff.getDrawingRotationOffsetFor(ncX);
    }

    for (final NcDrawingGlyph glyph in nc.drawingGlyphs) {
      drawSmuflCode(
          dc,
          (ncX + glyph.xOffset).toInt(),
          (ncY + glyph.yOffset).toInt(),
          glyph.fontNo,
          staff.drawingStaffSize,
          false,
          true);
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  bool _isOnStaffLine(int y, Staff staff) {
    final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);
    return ((y - staff.getDrawingY()) % (2 * unit) == 0);
  }

  int _getNcDrawingRadius(Nc nc, Staff staff) {
    // Mirrors LayerElement::GetDrawingRadius for NC (code = E0A4).
    // Keep identical to view_element.dart's _getDrawingRadiusForLayerElement fallback.
    return doc!.getGlyphWidth(_smuflE0A4NoteheadBlack, staff.drawingStaffSize,
            nc.drawingCueSize) ~/
        2;
  }
}
