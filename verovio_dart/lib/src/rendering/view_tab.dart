// ignore_for_file: dead_code, unused_element, unused_local_variable, non_constant_identifier_names, unnecessary_cast, curly_braces_in_flow_control_structures

/// Port of `view_tab.cpp` — tablatura (task 05-24).
///
/// Mirrors `View::DrawTabClef` (36), `DrawTabGrp` (72), `DrawTabNote` (90),
/// `DrawTabDurSym` (213) — 295 linhas, 6.2.0.
///
/// This file is a `part` of the `view.dart` library (task 05-06 partitioning
/// decision: one `part` per `view_*.cpp`). The C++ continues the `View` class
/// here; Dart cannot split a class body across files, so the methods are
/// declared as members of the [ViewTab] extension below — same library,
/// therefore the same privacy scope as the class members (like the C++ member
/// visibility from every `view_*.cpp`).
///
/// Deviations from the C++:
/// - `DeviceContext *dc` pointers become non-nullable [DeviceContext] references.
/// - `vrv_cast<Clef *>` / `dynamic_cast<Note *>` become Dart `as` casts.
/// - `std::u32string` becomes Dart `String` (SMuFL code points are BMP).
/// - `char32_t` becomes `int` code point.
/// - `FontInfo` handling mirrors `Doc::GetDrawingSmuflFont` / `GetTextFont`.
/// - `TabGrp::GetActualDur` / `GetActualDurGes` / `GetDots` etc. are read via
///   `dynamic` fallback when the generated model does not expose the typed
///   accessor directly — same pattern as `view_mensural.dart`.
/// - `Note::GetTabFretString` is ported inline as [_getTabFretString] (see
///   note.cpp:259) to avoid a model dependency cycle.
part of 'view.dart';

// SMuFL code points used by view_tab.cpp.
const int _smuflLuteDurationDoubleWhole = 0xEBA6;
const int _smuflLuteDurationWhole = 0xEBA7;
const int _smuflLuteDurationHalf = 0xEBA8;
const int _smuflLuteDurationQuarter = 0xEBA9;
const int _smuflLuteDuration8th = 0xEBAA;
const int _smuflLuteDuration16th = 0xEBAB;
const int _smuflLuteDuration32nd = 0xEBAC;
const int _smuflLuteItalianFret0 = 0xEBE0;
const int _smuflLuteItalianFret1 = 0xEBE1;
const int _smuflLuteItalianFret2 = 0xEBE2;
const int _smuflLuteItalianFret3 = 0xEBE3;
const int _smuflLuteItalianFret4 = 0xEBE4;
const int _smuflLuteGermanAUpper = 0xEC17;
const int _smuflLuteGermanNUpper = 0xEC23;
const int _smuflLuteGermanALower = 0xEC00;
const int _smuflLuteGermanZLower = 0xEC16;
const int _smuflLuteFrenchFretA = 0xEBC0;
const int _smuflLuteFrench7thCourse = 0xEBCD;
const int _smuflNoteheadSlashHorizontalEnds = 0xE101;
const int _smuflFigbass1 = 0xEA51;
const int _smuflFigbass2 = 0xEA52;
const int _smuflFigbass3 = 0xEA54;
const int _smuflFigbass4 = 0xEA55;
const int _smuflFigbass5 = 0xEA57;
const int _smuflFigbass7Raised2 = 0xEA5F;
const int _smuflFigbass9 = 0xEA61;

/// The `view_tab.cpp` methods of [View] (task 05-24).
extension ViewTab on View {
  // -------------------------------------------------------------------------
  // View::DrawTabClef (view_tab.cpp:36)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawTabClef` (view_tab.cpp:36).
  void drawTabClef(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final Clef clef = element as Clef;

    final int glyphSize = staff.getDrawingStaffNotationSize();

    int x = element.getDrawingX();
    int y = staff.getDrawingY();

    int sym = 0;
    try {
      sym = _getClefGlyphForTab(clef, staff.drawingNotationtype);
    } catch (_) {
      sym = 0;
    }

    if (sym == 0) {
      clef.setEmptyBB();
      return;
    }

    y -= doc!.getDrawingUnit(staff.drawingStaffSize) * (staff.drawingLines - 1);

    dc.startGraphic(element, '', element.id);

    drawSmuflCode(dc, x, y, sym, glyphSize, false);

    // Possibly draw enclosing brackets
    drawClefEnclosing(dc, clef, staff, sym, x, y);

    dc.endGraphic(element);
  }

  int _getClefGlyphForTab(Clef clef, Notationtype? notationType) {
    // Mirrors Clef::GetClefGlyph for tab notation — glyph.num/name priority then tab default.
    try {
      final dynamic dyn = clef as dynamic;
      if (dyn.hasGlyphNum == true && dyn.glyphNum != null) {
        final int c = dyn.glyphNum as int;
        if (c != 0 && doc!.getResources().getGlyphByCode(c) != null) return c;
      }
      if (dyn.hasGlyphName == true && dyn.glyphName != null) {
        final String name = dyn.glyphName as String;
        if (name.isNotEmpty) {
          final int c = doc!.getResources().getGlyphCode(name);
          if (c != 0 && doc!.getResources().getGlyphByCode(c) != null) return c;
        }
      }
    } catch (_) {}
    // Default: tabClef
    return 0xE06D; // SMUFL_E06D_6stringTabClef
  }

  // -------------------------------------------------------------------------
  // View::DrawTabGrp (view_tab.cpp:72)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawTabGrp` (view_tab.cpp:72).
  void drawTabGrp(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final TabGrp tabGrp = element as TabGrp;

    dc.startGraphic(tabGrp, '', tabGrp.id);

    // Draw children (rhythm, notes)
    drawLayerChildren(dc, tabGrp, layer, staff, measure);

    dc.endGraphic(tabGrp);
  }

  // -------------------------------------------------------------------------
  // View::DrawTabNote (view_tab.cpp:90)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawTabNote` (view_tab.cpp:90).
  void drawTabNote(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final Note note = element as Note;

    int x = element.getDrawingX();
    int y = element.getDrawingY();

    final (int ox, int oy) = calcOffset(dc, x, y);
    x = ox;
    y = oy;

    final int glyphSize = staff.getDrawingStaffNotationSize();
    const bool drawingCueSize = false;
    int overline = 0;
    int strike = 0;
    int underline = 0;

    final Notationtype notationType =
        staff.drawingNotationtype ?? Notationtype.tab;

    if (notationType == Notationtype.tabGuitar) {
      final String fret = _getTabFretString(note, notationType, staff);
      // Extract overline/strike/underline via helper that also returns them.
      final (String s, int ov, int st, int un) =
          _getTabFretStringWithDecor(note, notationType, staff);
      overline = ov;
      strike = st;
      underline = un;

      FontInfo fretTxt = FontInfo();
      try {
        fretTxt.faceName = doc!.getResources().textFontName;
      } catch (_) {
        fretTxt.faceName = 'Times';
      }
      // Preserve global styling check without importing SvgDeviceContext: if global styling, keep font empty
      bool useGlobalStyling = false;
      try {
        useGlobalStyling = (dc as dynamic).useGlobalStyling == true;
      } catch (_) {}
      if (useGlobalStyling) fretTxt.faceName = '';

      final TextDrawingParams params = TextDrawingParams();
      params.x = x;
      params.y = y;
      int lyricPointSize = 0;
      try {
        lyricPointSize = doc!.getDrawingLyricFont(glyphSize).pointSize * 4 ~/ 5;
      } catch (_) {
        lyricPointSize = (doc!.getDrawingUnit(glyphSize) * 2).toInt();
      }
      fretTxt.pointSize = lyricPointSize;
      params.pointSize = lyricPointSize;

      dc.setFont(fretTxt);

      int halfH = 0;
      try {
        halfH = doc!.getTextGlyphHeight(
                '0'.codeUnitAt(0), fretTxt, drawingCueSize) ~/
            2;
      } catch (_) {
        halfH = doc!.getDrawingUnit(glyphSize) ~/ 2;
      }
      params.y -= halfH;

      dc.startText(toDeviceContextX(params.x), toDeviceContextY(params.y),
          HorizontalAlignment.center);
      drawTextString(dc, s.isEmpty ? fret : s, params);
      dc.endText();

      dc.resetFont();
    } else {
      final (String fret, int ov, int st, int un) =
          _getTabFretStringWithDecor(note, notationType, staff);
      overline = ov;
      strike = st;
      underline = un;

      // Center for italian tablature
      if (staff.isTabLuteItalian()) {
        y -= doc!.getGlyphHeight(
                _smuflLuteItalianFret0, glyphSize, drawingCueSize) ~/
            2;
      } else if (staff.isTabLuteFrench()) {
        y -= doc!.getDrawingUnit(staff.drawingStaffSize) -
            doc!.getDrawingStaffLineWidth(staff.drawingStaffSize);
      } else if (staff.isTabLuteGerman()) {
        y -= doc!.getGlyphHeight(
                _smuflLuteGermanAUpper, glyphSize, drawingCueSize) ~/
            2;
      }

      dc.setFont(doc!.getDrawingSmuflFont(glyphSize, false));
      drawSmuflString(dc, x, y, fret, HorizontalAlignment.center, glyphSize);

      // Add overlines, strikethroughs and underlines if required
      if ((overline > 0 || strike > 0 || underline > 0) && fret.isNotEmpty) {
        double lyricThickness = 0.25;
        try {
          lyricThickness = (doc!.getOptions() as dynamic)
                  .lyricLineThickness
                  ?.value as double? ??
              0.25;
        } catch (_) {
          try {
            lyricThickness =
                doc!.getOptions().lyricLineThickness.value as double;
          } catch (_) {}
        }
        final int lineThickness =
            (lyricThickness * doc!.getDrawingUnit(staff.drawingStaffSize))
                .toInt();
        final int widthFront =
            doc!.getGlyphWidth(fret.codeUnitAt(0), glyphSize, drawingCueSize);
        final int widthBack = doc!.getGlyphWidth(
            fret.codeUnitAt(fret.length - 1), glyphSize, drawingCueSize);
        final TextExtend extend = TextExtend();
        dc.getSmuflTextExtent(fret, extend);

        final int x1 = x -
            (fret.length == 1 ? widthFront * 7 ~/ 10 : widthFront * 12 ~/ 10);
        final int x2 = x + extend.width - widthBack * 1 ~/ 10;

        dc.setPen(lineThickness, PenStyle.solid);

        // overlines
        int y1 = y + extend.ascent + lineThickness;
        for (int i = 0; i < overline; ++i) {
          dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
              toDeviceContextX(x2), toDeviceContextY(y1));
          y1 += 2 * lineThickness;
        }

        // strikethroughs
        y1 = y + extend.ascent ~/ 2 - (strike - 1) * lineThickness;
        for (int i = 0; i < strike; ++i) {
          dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
              toDeviceContextX(x2), toDeviceContextY(y1));
          y1 += 2 * lineThickness;
        }

        // underlines
        y1 = y - extend.descent - lineThickness;
        for (int i = 0; i < underline; ++i) {
          dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
              toDeviceContextX(x2), toDeviceContextY(y1));
          y1 -= 2 * lineThickness;
        }

        dc.resetPen();
      }
      dc.resetFont();
    }

    // Draw children (nothing yet)
    drawLayerChildren(dc, note, layer, staff, measure);
  }

  // -------------------------------------------------------------------------
  // Helpers: Tab fret string (mirrors Note::GetTabFretString, note.cpp:259)
  // -------------------------------------------------------------------------

  String _getTabFretString(Note note, Notationtype notationType, Staff staff) {
    return _getTabFretStringWithDecor(note, notationType, staff).$1;
  }

  (String, int, int, int) _getTabFretStringWithDecor(
      Note note, Notationtype notationType, Staff staff) {
    int overline = 0;
    int strike = 0;
    int underline = 0;

    // @glyph.num / @glyph.name / @altsym priority (note.cpp first block)
    try {
      final resources = doc!.resources;
      if ((note as dynamic).hasGlyphNum == true) {
        final int code = (note as dynamic).glyphNum as int;
        if (code != 0 && resources.getGlyphByCode(code) != null) {
          return (String.fromCharCode(code), 0, 0, 0);
        }
      } else if ((note as dynamic).hasGlyphName == true) {
        final String name = (note as dynamic).glyphName as String;
        if (name.isNotEmpty) {
          final int code = resources.getGlyphCode(name);
          if (code != 0 && resources.getGlyphByCode(code) != null) {
            return (String.fromCharCode(code), 0, 0, 0);
          }
        }
      } else if ((note as dynamic).hasAltsym == true) {
        try {
          final Object? symDef = (note as dynamic).getAltSymbolDef() as Object?;
          if (symDef != null) {
            final List<Object> symbols =
                (symDef as dynamic).getChildren() as List<Object>? ?? [];
            final StringBuffer buf = StringBuffer();
            for (final Object child in symbols) {
              if (child.classId == ClassId.symbol) {
                final dynamic sym = child as dynamic;
                if (sym.hasGlyphNum == true) {
                  final int c = sym.glyphNum as int;
                  if (c != 0 && resources.getGlyphByCode(c) != null)
                    buf.writeCharCode(c);
                } else if (sym.hasGlyphName == true) {
                  final String n = sym.glyphName as String;
                  if (n.isNotEmpty) {
                    final int c = resources.getGlyphCode(n);
                    if (c != 0 && resources.getGlyphByCode(c) != null)
                      buf.writeCharCode(c);
                  }
                }
              }
            }
            if (buf.isNotEmpty) return (buf.toString(), 0, 0, 0);
          }
        } catch (_) {}
      }
    } catch (_) {}

    int fret = 0;
    int course = 0;
    try {
      fret = (note as dynamic).tabFret as int? ?? note.tabFret ?? 0;
    } catch (_) {
      try {
        fret = note.tabFret ?? 0;
      } catch (_) {}
    }
    try {
      course = (note as dynamic).tabCourse as int? ?? note.tabCourse ?? 0;
    } catch (_) {
      try {
        course = note.tabCourse ?? 0;
      } catch (_) {}
    }

    if (notationType == Notationtype.tabLuteItalian) {
      final StringBuffer fretStr = StringBuffer();
      if (course <= 7 || fret != 0) {
        if (fret >= 10) {
          final int q = fret ~/ 10;
          fretStr.writeCharCode(_smuflLuteItalianFret0 + q);
        }
        final int r = fret % 10;
        fretStr.writeCharCode(_smuflLuteItalianFret0 + r);
        if (course >= 7) strike = 1;
        underline = course >= 7 ? (course - 7).clamp(0, 100) : 0;
      } else {
        if (course >= 10) {
          final int q = course ~/ 10;
          fretStr.writeCharCode(_smuflLuteItalianFret0 + q);
        }
        final int r = course % 10;
        fretStr.writeCharCode(_smuflLuteItalianFret0 + r);
      }
      return (fretStr.toString(), overline, strike, underline);
    } else if (notationType == Notationtype.tabLuteFrench) {
      final StringBuffer fretStr = StringBuffer();
      if (course >= 11) {
        fretStr.writeCharCode(_smuflLuteItalianFret4 + course - 11);
      } else if (course >= 7 && fret == 0) {
        fretStr.writeCharCode(_smuflLuteFrench7thCourse + course - 7);
      } else {
        if (course >= 8) {
          for (int i = 0; i < course - 7; ++i)
            fretStr.writeCharCode(_smuflNoteheadSlashHorizontalEnds);
        }
        const List<int> letters = [
          _smuflLuteFrenchFretA,
          0xEBC1,
          0xEBC2,
          0xEBC3,
          0xEBC4,
          0xEBC5,
          0xEBC6,
          0xEBC7,
          0xEBC8,
          0xEBC9,
          0xEBCA,
          0xEBCB,
          0xEBCC,
        ];
        if (fret >= 0 && fret < letters.length)
          fretStr.writeCharCode(letters[fret]);
      }
      return (fretStr.toString(), overline, strike, underline);
    } else if (notationType == Notationtype.tabLuteGerman) {
      final StringBuffer fretStr = StringBuffer();
      if (course >= 6 && fret >= 0 && fret <= 13) {
        if (fret == 0) {
          fretStr.writeCharCode(_smuflFigbass1);
          strike = course - 5;
        } else {
          fretStr.writeCharCode(_smuflLuteGermanAUpper + fret - 1);
          overline = course - 6;
        }
      } else if (course >= 1 && course <= 5 && fret == 0) {
        const List<int> digits = [
          _smuflFigbass1,
          _smuflFigbass2,
          _smuflFigbass3,
          _smuflFigbass4,
          _smuflFigbass5
        ];
        fretStr.writeCharCode(digits[5 - course]);
      } else if (course >= 1 && course <= 5 && fret >= 0 && fret <= 10) {
        final int firstFret = fret <= 5 ? fret : fret - 5;
        if (course == 2 && firstFret == 5) {
          fretStr.writeCharCode(_smuflFigbass7Raised2);
        } else if (course == 1 && firstFret == 5) {
          fretStr.writeCharCode(_smuflFigbass9);
        } else {
          fretStr.writeCharCode(
              _smuflLuteGermanALower + (5 - course) + (firstFret - 1) * 5);
        }
        overline = (fret >= 6) ? 1 : 0;
      }
      return (fretStr.toString(), overline, strike, underline);
    } else {
      // guitar / default tab: decimal fret number as text
      return (fret.toString(), 0, 0, 0);
    }
  }

  // -------------------------------------------------------------------------
  // View::DrawTabDurSym (view_tab.cpp:213)
  // -------------------------------------------------------------------------

  /// Mirrors `View::DrawTabDurSym` (view_tab.cpp:213).
  void drawTabDurSym(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    final TabDurSym tabDurSym = element as TabDurSym;

    TabGrp? tabGrp;
    try {
      tabGrp = tabDurSym.getFirstAncestor(ClassId.tabGrp) as TabGrp?;
    } catch (_) {
      tabGrp = element.getFirstAncestor(ClassId.tabGrp) as TabGrp?;
    }
    if (tabGrp == null) return;

    dc.startGraphic(tabDurSym, '', tabDurSym.id);

    int x = element.getDrawingX();
    int y = element.getDrawingY();

    final int glyphSize = staff.getDrawingStaffNotationSize();

    int drawingDur = MeiDuration.none.value;
    try {
      // GetActualDurGes vs GetActualDur logic: durGes != NONE ? actualDurGes : actualDur
      final dynamic grp = tabGrp as dynamic;
      MeiDuration? durGes;
      try {
        durGes = grp.durGes as MeiDuration?;
      } catch (_) {}
      if (durGes != null && durGes != MeiDuration.none) {
        try {
          drawingDur = (grp.getActualDurGes() as MeiDuration).value;
        } catch (_) {
          drawingDur = durGes.value;
        }
      } else {
        try {
          drawingDur = (grp.getActualDur() as MeiDuration).value;
        } catch (_) {
          drawingDur = MeiDuration.dur4.value;
        }
      }
    } catch (_) {
      drawingDur = MeiDuration.dur4.value;
    }

    bool isInBeam = false;
    try {
      isInBeam = (tabGrp as dynamic).isInBeam() as bool;
    } catch (_) {
      try {
        isInBeam = tabGrp.getFirstAncestor(ClassId.beam) != null;
      } catch (_) {}
      if (!isInBeam) {
        try {
          isInBeam = (tabGrp as dynamic).isInBeamSpan == true;
        } catch (_) {}
      }
    }

    bool isTabGuitar = false;
    try {
      isTabGuitar = staff.isTabGuitar();
    } catch (_) {}

    if (!isInBeam && !isTabGuitar) {
      int symc = 0;
      switch (drawingDur) {
        case 1: // DURATION_1
          symc = _smuflLuteDurationDoubleWhole;
          break;
        case 2: // DURATION_2
          symc = _smuflLuteDurationWhole;
          break;
        case 4: // DURATION_4
          symc = _smuflLuteDurationHalf;
          break;
        case 8: // DURATION_8
          symc = _smuflLuteDurationQuarter;
          break;
        case 16:
          symc = _smuflLuteDuration8th;
          break;
        case 32:
          symc = _smuflLuteDuration16th;
          break;
        case 64:
          symc = _smuflLuteDuration32nd;
          break;
        default:
          symc = _smuflLuteDurationQuarter;
      }

      drawSmuflCode(dc, x, y, symc, glyphSize, true);
    }

    bool hasDots = false;
    int dotsCount = 0;
    try {
      hasDots = (tabGrp as dynamic).hasDots() == true ||
          (tabGrp.dots != null && tabGrp.dots! > 0);
      if (tabGrp.dots != null) dotsCount = tabGrp.dots!;
      if (dotsCount == 0) {
        try {
          dotsCount = (tabGrp as dynamic).getDots() as int;
        } catch (_) {}
        hasDots = dotsCount > 0;
      }
    } catch (_) {}

    if (hasDots && dotsCount > 0) {
      int stemDirFactor = 1;
      try {
        final dynamic dir = (tabDurSym as dynamic).getDrawingStemDir();
        if (dir == Stemdirection.down) stemDirFactor = -1;
      } catch (_) {
        try {
          if (tabDurSym.getDrawingStemDir() == Stemdirection.down)
            stemDirFactor = -1;
        } catch (_) {}
      }

      final dynamic stemObj = (tabDurSym as dynamic).getDrawingStem?.call();
      Stem? stemForY;
      try {
        if (stemObj is Stem) {
          y = stemObj.getDrawingY();
        } else if (stemObj != null) {
          try {
            y = (stemObj as dynamic).getDrawingY() as int;
          } catch (_) {}
        }
      } catch (_) {}

      int dotSize = 0;

      if (isInBeam || isTabGuitar) {
        y += (doc!.getDrawingUnit(glyphSize) * 0.5 * stemDirFactor).toInt();
        x += doc!.getDrawingUnit(glyphSize);
        dotSize = glyphSize * 2 ~/ 3;
      } else {
        int durOffset = (drawingDur > 2) ? drawingDur : 2;
        durOffset = (durOffset < 64) ? durOffset : 64;
        final int durfactor = 64 - durOffset + 1;
        y += (doc!.getDrawingUnit(glyphSize) *
            stemDirFactor *
            durfactor *
            2 ~/
            5);
        x += doc!.getGlyphWidth(_smuflLuteDurationQuarter, glyphSize, false) ~/
            2;
        dotSize = glyphSize * 9 ~/ 10;
      }

      for (int i = 0; i < dotsCount; ++i) {
        drawDot(dc, x, y, dotSize);
        x += (doc!.getDrawingUnit(glyphSize) * 0.75).toInt();
      }
    }

    if (isInBeam || isTabGuitar) {
      drawLayerChildren(dc, tabDurSym, layer, staff, measure);
    }

    dc.endGraphic(tabDurSym);
  }
}
