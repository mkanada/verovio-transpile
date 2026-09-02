/// Port of `view_text.cpp` — text, rend, figures and running elements (task 05-19).
///
/// Mirrors the 18 `View::Draw*` methods of `view_text.cpp` (701 lines, 6.2.0):
/// `DrawF` (49), `DrawTextString` (69), `DrawDirString` (76), `DrawDynamString`
/// (91), `DrawHarmString` (155), `DrawTextElement` (224), `DrawLyricString`
/// (264), `DrawLb` (318), `DrawNum` (334), `DrawFig` (352), `DrawRend` (369),
/// `DrawText` (480), `DrawGraphic` (536), `DrawSvg` (557), `DrawSymbol` (585),
/// `DrawRunningElements` (642), `DrawTextLayoutElement` (663), `DrawDiv` (696).
///
/// This file is a `part` of the `view.dart` library (task 05-06 partitioning
/// decision: one `part` per `view_*.cpp`). The C++ continues the `View` class
/// here; Dart cannot split a class body across files, so the methods are
/// declared as members of the [ViewText] extension below — same library,
/// therefore the same privacy scope as the class members (like the C++ member
/// visibility from every `view_*.cpp`).
///
/// Deviations from the C++:
/// - `DeviceContext *dc` pointers become non-nullable [DeviceContext] references.
/// - `std::u32string` becomes Dart `String` (UTF-16); SMuFL code points used
///   here are all in the BMP except the supplementary musical symbols, which
///   are handled as `String.fromCharCode`.
/// - `int &x, int &y` output parameters of `ToDeviceContextX/Y` are plain
///   return values.
/// - the C++ `vrv_cast<BBoxDeviceContext*>` check in `DrawRunningElements`
///   (view_text.cpp:648) is reproduced with `is BBoxDeviceContext`.
/// - `data_FONTSIZE` alternative handling uses the Dart [FontSize] class
///   (`mei_values.dart`) and the term/percent tables from that file.
/// - `Rend` font attribute access uses the generated `AttTypography` /
///   `AttExtSymAuth` / `AttTextRendition` etc. mixins; names are
///   `fontfam`/`fontname`/`fontsize`/`fontstyle`/`fontweight`/`letterspacing`
///   etc., not the C++ `GetFontname()`/`HasFontsize()` forms — the mapping is
///   documented on each branch.
/// - `Dynam::GetSymbolsInStr` / `GetSymbolStr` are ported as private helpers
///   [_dynamGetSymbolsInStr] / [_dynamGetSymbolStr] inside this extension;
///   the token table is the same literal table as `dynam.cpp:29-30`.
/// - `VRV_TEXT_HARM` / `VRV_UNSET` map to [vrvTextHarm] / [meiUnset].
part of 'view.dart';

/// The `view_text.cpp` methods of [View] (task 05-19).
extension ViewText on View {
  // ---------------------------------------------------------------------------
  // Low-level string helpers (view_text.cpp:69-223)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawTextString` (view_text.cpp:69).
  void drawTextString(DeviceContext dc, String str, TextDrawingParams params) {
    // In the C++ this is `dc->DrawText(UTF32to8(str), str);` — the first
    // argument is only for the old `char*` overload; Dart's `drawText` takes
    // the string directly.
    dc.drawText(str, wtext: str);
  }

  /// Mirrors `View::DrawDirString` (view_text.cpp:76).
  void drawDirString(DeviceContext dc, String str, TextDrawingParams params) {
    assert(dc.hasFont);
    String converted = str;
    if (dc.hasFont && dc.font.smuflFont != SmuflTextFont.none) {
      final StringBuffer buf = StringBuffer();
      for (final int cp in str.runes) {
        final int mapped = Resources.getSmuflGlyphForUnicodeChar(cp);
        buf.writeCharCode(mapped);
      }
      converted = buf.toString();
    }
    drawTextString(dc, converted, params);
  }

  /// Mirrors `View::DrawDynamString` (view_text.cpp:91).
  void drawDynamString(
      DeviceContext dc, String str, TextDrawingParams params, Rend? rend) {
    assert(dc.hasFont);

    const bool singleGlyphs = false;

    // If rend has @fontfam, render as plain text (view_text.cpp:98-101)
    final bool hasFontFam = rend != null && rend.hasFontfam;
    if (hasFontFam) {
      drawTextString(dc, str, params);
      return;
    }

    if (params.textEnclose != Enclosure.none) {
      String open = '';
      switch (params.textEnclose) {
        case Enclosure.paren:
          open = '(';
          break;
        case Enclosure.brack:
          open = '[';
          break;
        default:
          break;
      }
      if (open.isNotEmpty) drawTextString(dc, open, params);
    }

    final List<(String, bool)> tokens = [];
    final bool hasSymbols = _dynamGetSymbolsInStr(str, tokens);
    if (hasSymbols) {
      // first flag not needed in Dart — we preserve the C++ empty-separator logic
      for (final (String token, bool isSymbol) in tokens) {
        if (isSymbol) {
          final String smuflStr = _dynamGetSymbolStr(token, singleGlyphs);
          final FontInfo vrvTxt = FontInfo();
          final int basePoint =
              dc.hasFont ? dc.font.pointSize : params.pointSize;
          vrvTxt.pointSize = (basePoint * _musicToLyricRatio()).toInt();
          vrvTxt.faceName = doc!.getResources().currentFont;
          final bool isFallbackNeeded =
              doc!.getResources().isSmuflFallbackNeeded(smuflStr);
          vrvTxt.setSmuflWithFallback(isFallbackNeeded);
          vrvTxt.fontStyle = FontStyle.normal;
          vrvTxt.letterSpacing = 90;
          dc.setFont(vrvTxt);
          // The C++ draws the symbol through View::DrawTextString →
          // dc->DrawText, i.e. a <tspan> inside the current <text> with
          // @font-family set to the music font (which makes Commit() embed
          // the woff2 @font-face via VrvTextFont()). It is NOT the
          // <use>-based drawMusicText path.
          drawTextString(dc, smuflStr, params);
          dc.resetFont();
        } else {
          drawTextString(dc, token, params);
        }
      }
    } else {
      drawTextString(dc, str, params);
    }

    if (params.textEnclose != Enclosure.none) {
      String close = '';
      switch (params.textEnclose) {
        case Enclosure.paren:
          close = ')';
          break;
        case Enclosure.brack:
          close = ']';
          break;
        default:
          break;
      }
      if (close.isNotEmpty) drawTextString(dc, close, params);
    }
  }

  /// Mirrors `View::DrawHarmString` (view_text.cpp:155).
  void drawHarmString(DeviceContext dc, String str, TextDrawingParams params) {
    assert(dc.hasFont);

    int toDcX = toDeviceContextX(params.x);
    int toDcY = toDeviceContextY(params.y);

    int prevPos = 0;
    while (true) {
      int pos = _findFirstOfHarm(str, prevPos);
      if (pos == -1) break;

      if (pos > prevPos) {
        final String substr = str.substring(prevPos, pos);
        dc.drawText(substr, wtext: substr, x: toDcX, y: toDcY);
        toDcX = meiUnset;
        toDcY = meiUnset;
      }

      if (pos == prevPos || pos < str.length) {
        final String accid = str.substring(pos, pos + 1);
        String smuflAccid;
        if (accid == '\u266D' || accid == '\uE260') {
          smuflAccid = String.fromCharCode(0xEA64); // figbassFlat
        } else if (accid == '\u266E' || accid == '\uE261') {
          smuflAccid = String.fromCharCode(0xEA65); // figbassNatural
        } else if (accid == '\u266F' || accid == '\uE262') {
          smuflAccid = String.fromCharCode(0xEA66); // figbassSharp
        } else if (accid == '\uE264') {
          smuflAccid = String.fromCharCode(0xEA63); // figbassDoubleFlat
        } else if (accid == '\uE263') {
          smuflAccid = String.fromCharCode(0xEA67); // figbassDoubleSharp
        } else {
          smuflAccid = accid;
        }

        final FontInfo vrvTxt = FontInfo();
        final int basePoint = dc.hasFont ? dc.font.pointSize : params.pointSize;
        vrvTxt.pointSize = (basePoint * _musicToLyricRatio()).toInt();
        vrvTxt.faceName = doc!.getResources().currentFont;
        final bool isFallbackNeeded =
            doc!.getResources().isSmuflFallbackNeeded(smuflAccid);
        vrvTxt.setSmuflWithFallback(isFallbackNeeded);
        dc.setFont(vrvTxt);
        // The C++ draws the accidental through dc->DrawText (view_text.cpp:202)
        // — a <tspan font-family="Leipzig"> carrying the SMuFL character, not
        // the <use>-based DrawMusicText path. DrawText also flags VrvTextFont()
        // (svgdevicecontext.cpp:1104-1111) so Commit() appends the embedded
        // @font-face <style> (svgdevicecontext.cpp:184-196). toDcX/toDcY may
        // already be meiUnset here — DrawText handles unset x/y itself.
        dc.drawText(smuflAccid, wtext: smuflAccid, x: toDcX, y: toDcY);
        dc.resetFont();
        toDcX = meiUnset;
        toDcY = meiUnset;
      }
      prevPos = pos + 1;
      if (prevPos >= str.length) break;
    }
    if (prevPos < str.length) {
      final String substr = str.substring(prevPos);
      dc.drawText(substr, wtext: substr, x: toDcX, y: toDcY);
    }

    params.x = meiUnset;
  }

  // ---------------------------------------------------------------------------
  // Dispatcher (view_text.cpp:224-262)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawTextElement` (view_text.cpp:224).
  void drawTextElement(
      DeviceContext dc, TextElement element, TextDrawingParams params) {
    if (element.classId == ClassId.f) {
      final F f = element as F;
      drawF(dc, f, params);
    } else if (element.classId == ClassId.lb) {
      final Lb lb = element as Lb;
      drawLb(dc, lb, params);
    } else if (element.classId == ClassId.num) {
      final Num num = element as Num;
      drawNum(dc, num, params);
    } else if (element.classId == ClassId.rend) {
      final Rend rend = element as Rend;
      drawRend(dc, rend, params);
    } else if (element.classId == ClassId.symbol) {
      final Symbol symbol = element as Symbol;
      drawSymbol(dc, symbol, params);
    } else if (element.classId == ClassId.text) {
      final Text text = element as Text;
      drawText(dc, text, params);
    } else {
      assert(false, 'DrawTextElement: unhandled ${element.className}');
    }
  }

  // ---------------------------------------------------------------------------
  // Lyric / Lb / Num / Fig (view_text.cpp:264-367)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawLyricString` (view_text.cpp:264).
  void drawLyricString(DeviceContext dc, String str,
      [int staffSize = 100, TextDrawingParams? params]) {
    assert(dc.hasFont);

    bool wroteText = false;
    String lyricStr = str;

    final int dcX = (params != null) ? toDeviceContextX(params.x) : meiUnset;
    final int dcY = (params != null) ? toDeviceContextY(params.y) : meiUnset;
    final int width = (params != null) ? params.width : meiUnset;
    final int height = (params != null) ? params.height : meiUnset;

    // Check lyric elision option
    const int elisionVal = smuflE551LyricsElision;

    // ELISION_unicode sentinel is not in Dart options shell; we treat
    // unicodeUndertie (0x203F) as the trigger for replacement, matching the C++
    // branch where m_lyricElision == ELISION_unicode.
    if (elisionVal == unicodeUndertie) {
      lyricStr = lyricStr.replaceAll('_', String.fromCharCode(unicodeUndertie));
      dc.drawText(lyricStr,
          wtext: lyricStr, x: dcX, y: dcY, width: width, height: height);
      wroteText = lyricStr.isNotEmpty;
    } else {
      String remaining = lyricStr;
      String currentSyl = '';
      while (currentSyl != remaining) {
        wroteText = true;
        final int index = remaining.indexOf('_');
        if (index == -1) {
          currentSyl = remaining;
          dc.drawText(currentSyl,
              wtext: currentSyl, x: dcX, y: dcY, width: width, height: height);
          break;
        } else {
          currentSyl = remaining.substring(0, index);
          dc.drawText(currentSyl,
              wtext: currentSyl, x: dcX, y: dcY, width: width, height: height);

          final FontInfo vrvTxt = FontInfo();
          final int basePoint = dc.hasFont ? dc.font.pointSize : 0;
          final int pt = basePoint != 0
              ? basePoint
              : (params?.pointSize ?? doc!.getDrawingLyricFont(100).pointSize);
          vrvTxt.pointSize = (pt * _musicToLyricRatio()).toInt();
          vrvTxt.faceName = doc!.getResources().currentFont;
          final String elision = String.fromCharCode(elisionVal);
          final bool isFallbackNeeded =
              doc!.getResources().isSmuflFallbackNeeded(elision);
          vrvTxt.setSmuflWithFallback(isFallbackNeeded);
          dc.setFont(vrvTxt);
          // The C++ draws the elision through dc->DrawText (view_text.cpp:297)
          // — a <tspan font-family="Leipzig"> carrying the SMuFL character,
          // not the <use>-based DrawMusicText path. DrawText also flags
          // VrvTextFont() (svgdevicecontext.cpp:1104-1111) so Commit() appends
          // the embedded @font-face <style> (svgdevicecontext.cpp:184-196).
          // The C++ passes dcX/dcY/width/height through to DrawText.
          dc.drawText(elision,
              wtext: elision, x: dcX, y: dcY, width: width, height: height);
          dc.resetFont();

          currentSyl = '';
          remaining = remaining.substring(index + 1);
          if (remaining.isEmpty) {
            // Avoid infinite loop when string ends with '_'
            break;
          }
        }
      }
      if (!wroteText && lyricStr.isEmpty && params != null) {
        // handled below
      }
    }

    if (!wroteText && params != null) {
      dc.drawText('',
          wtext: '',
          x: toDeviceContextX(params.x),
          y: toDeviceContextY(params.y),
          width: params.width,
          height: params.height);
    }
  }

  /// Mirrors `View::DrawLb` (view_text.cpp:318).
  void drawLb(DeviceContext dc, Lb lb, TextDrawingParams params) {
    assert(dc.hasFont);
    dc.startTextGraphic(lb, '', lb.id);

    final FontInfo? currentFont = dc.hasFont ? dc.font : null;
    if (currentFont != null) {
      params.y -= doc!.getTextLineHeight(currentFont, false);
    } else {
      params.y -= doc!.getDrawingUnit(100);
    }
    params.explicitPosition = true;

    dc.endTextGraphic(lb);
  }

  /// Mirrors `View::DrawNum` (view_text.cpp:334).
  void drawNum(DeviceContext dc, Num num, TextDrawingParams params) {
    dc.startTextGraphic(num, '', num.id);

    final Text currentText = num.getCurrentText();
    if (currentText.text.isNotEmpty) {
      drawText(dc, currentText, params);
    } else {
      drawTextChildren(dc, num, params);
    }

    dc.endTextGraphic(num);
  }

  /// Mirrors `View::DrawFig` (view_text.cpp:352).
  void drawFig(DeviceContext dc, Fig fig, TextDrawingParams params) {
    dc.startGraphic(fig, '', fig.id);

    // Find Svg descendant (Fig may contain Svg)
    final Svg? svg = fig.findDescendantByType(ClassId.svg) as Svg?;
    if (svg != null) {
      params.x = fig.getDrawingX();
      params.y = fig.getDrawingY();
      drawSvg(dc, svg, params, 100, false);
    }

    dc.endGraphic(fig);
  }

  // ---------------------------------------------------------------------------
  // DrawRend (view_text.cpp:369-478) — the longest
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawRend` (view_text.cpp:369).
  void drawRend(DeviceContext dc, Rend rend, TextDrawingParams params) {
    dc.startTextGraphic(rend, '', rend.id);

    if (params.laidOut) {
      if (params.alignment == HorizontalAlignment.none_) {
        HorizontalAlignment halign = HorizontalAlignment.left;
        if (rend.hasHalign) {
          final dynamic h = rend.halign;
          if (h is HorizontalAlignment) {
            halign = h;
          } else if (h is Horizontalalignment) {
            halign = convertHalign(h);
          }
        }
        params.alignment = halign;
        params.x = rend.getDrawingX();
        params.y = rend.getDrawingY();
        dc.moveTextTo(toDeviceContextX(params.x), toDeviceContextY(params.y),
            params.alignment);
      }
    }

    final FontInfo rendFont = FontInfo();
    bool customFont = false;

    // @fontname / @fontfam
    String? fontname;
    if (rend.hasFontname) {
      fontname = rend.fontname;
    } else if (rend.hasFontfam) {
      fontname = rend.fontfam;
    }
    if (fontname != null && fontname.isNotEmpty) {
      rendFont.faceName = fontname;
      customFont = true;
    }

    // @fontsize
    if (rend.hasFontsize && rend.fontsize != null) {
      final FontSize fs = rend.fontsize!;
      if (fs.type == FontSizeType.fontSizeNumeric) {
        rendFont.pointSize = fs.fontSizeNumeric.toInt();
      } else if (fs.type == FontSizeType.term) {
        final int percent = fs.getPercentForTerm();
        rendFont.pointSize = params.pointSize * percent ~/ 100;
      } else if (fs.type == FontSizeType.percent) {
        rendFont.pointSize = params.pointSize * fs.percent ~/ 100;
      }
      customFont = true;
      params.pointSize = rendFont.pointSize;
    }

    // @glyph.auth == smufl
    if (rend.hasGlyphAuth && rend.glyphAuth == 'smufl') {
      rendFont.setSmuflWithFallback(false);
      rendFont.faceName = doc!.getResources().currentFont;
      int pt = rendFont.pointSize != 0 ? rendFont.pointSize : params.pointSize;
      rendFont.pointSize = (pt * _musicToLyricRatio()).toInt();
      customFont = true;
    }

    // @fontstyle
    if (rend.hasFontstyle && rend.fontstyle != null) {
      final Fontstyle fs = rend.fontstyle!;
      rendFont.fontStyle = _convertFontStyle(fs);
      customFont = true;
    }

    // @fontweight
    if (rend.hasFontweight && rend.fontweight != null) {
      final Fontweight fw = rend.fontweight!;
      rendFont.fontWeight = _convertFontWeight(fw);
      customFont = true;
    }

    // @letterspacing
    if (rend.hasLetterspacing && rend.letterspacing != null) {
      rendFont.letterSpacing =
          (rend.letterspacing! * doc!.getDrawingUnit(100)).toInt();
      customFont = true;
    }

    if (customFont) dc.setFont(rendFont);

    int yShift = 0;
    final Textrendition rendVal = rend.rend ?? Textrendition.none;
    if (rendVal == Textrendition.sup || rendVal == Textrendition.sub) {
      final FontInfo curFont = dc.hasFont ? dc.font : rendFont;
      final int mHeight =
          doc!.getTextGlyphHeight('M'.codeUnitAt(0), curFont, false);
      if (rendVal == Textrendition.sup) {
        yShift += doc!.getTextGlyphHeight('o'.codeUnitAt(0), curFont, false);
        yShift += (mHeight * superScriptPosition).toInt();
      } else {
        yShift += (mHeight * subScriptPosition).toInt();
      }
      params.y += yShift;
      params.verticalShift = true;
      dc.font.supSubScript = true;
      dc.font.pointSize = (dc.font.pointSize * superScriptFactor).toInt();
    }

    if (rendVal == Textrendition.box && params.actualWidth != 0) {
      params.x = params.actualWidth + doc!.getDrawingUnit(100);
      params.explicitPosition = true;
    }

    drawTextChildren(dc, rend, params);

    if (rendVal == Textrendition.sup || rendVal == Textrendition.sub) {
      params.y -= yShift;
      params.verticalShift = true;
      dc.font.supSubScript = false;
      dc.font.pointSize = (dc.font.pointSize / superScriptFactor).toInt();
    }

    // Mirrors `Rend::HasEnclosure` (rend.cpp:85) and `View::DrawRend`
    // (view_text.cpp:462): box/circle/dbox/tbox rend pushes an enclosure.
    final bool hasEnclosure = rendVal == Textrendition.box ||
        rendVal == Textrendition.circle ||
        rendVal == Textrendition.dbox ||
        rendVal == Textrendition.tbox;
    if (hasEnclosure) {
      params.enclosedRend.add(rend);
      // C++: params.m_x = rend->GetContentRight() + GetDrawingUnit(100)
      // ContentRight comes from the Rend's own bounding box after its
      // children have been laid out (filled via View+BBoxDeviceContext in
      // Page._renderBoundingBoxes).
      try {
        params.x = rend.getContentRight() + doc!.getDrawingUnit(100);
      } catch (_) {
        // Fallback if content box not yet available (mirrors defensive
        // try/catch pattern in view_control.dart drawTextEnclosure)
        params.x = rend.getContentRight();
      }
      params.explicitPosition = true;
      params.enclose = rendVal;
    }

    if (customFont) {
      dc.resetFont();
      assert(dc.hasFont);
      params.pointSize = dc.hasFont ? dc.font.pointSize : params.pointSize;
    }

    dc.endTextGraphic(rend);
  }

  // ---------------------------------------------------------------------------
  // DrawText (view_text.cpp:480-534)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawText` (view_text.cpp:480).
  void drawText(DeviceContext dc, Text text, TextDrawingParams params) {
    assert(dc.hasFont);
    final Resources resources = dc.getResources() ?? doc!.getResources();
    dc.startTextGraphic(text, '', text.id);

    final FontWeight w = dc.font.fontWeight;
    final FontStyle s = dc.font.fontStyle;
    resources.selectTextFont(w, s);

    if (params.explicitPosition) {
      dc.moveTextTo(toDeviceContextX(params.x), toDeviceContextY(params.y),
          HorizontalAlignment.none_);
      params.explicitPosition = false;
    } else if (params.verticalShift) {
      dc.moveTextVerticallyTo(toDeviceContextY(params.y));
      params.verticalShift = false;
    }

    final String txt = text.text;
    bool handled = false;

    // Check ancestors for special strings
    final bool isCpmark = text.getFirstAncestor(ClassId.cpMark) != null;
    final bool isDir = text.getFirstAncestor(ClassId.dir) != null;
    final bool isOrnam = text.getFirstAncestor(ClassId.ornam) != null;
    final bool isRepeatMark = text.getFirstAncestor(ClassId.repeatMark) != null;
    final bool isDynam = text.getFirstAncestor(ClassId.dynam) != null;
    final bool isHarm = text.getFirstAncestor(ClassId.harm) != null;
    final bool isSyl = text.getFirstAncestor(ClassId.syl) != null;

    if (isCpmark || isDir || isOrnam || isRepeatMark) {
      drawDirString(dc, txt, params);
      handled = true;
    } else if (isDynam) {
      final Rend? rendAnc = text.getFirstAncestor(ClassId.rend) as Rend?;
      drawDynamString(dc, txt, params, rendAnc);
      handled = true;
    } else if (isHarm) {
      drawHarmString(dc, txt, params);
      handled = true;
    } else if (isSyl) {
      if (params.height != meiUnset && params.height != 0) {
        drawLyricString(dc, txt, 100, params);
      } else {
        drawLyricString(dc, txt);
      }
      handled = true;
    }

    if (!handled) {
      drawTextString(dc, txt, params);
    }

    params.actualWidth = text.getContentRight();

    resources.selectTextFont(FontWeight.none_, FontStyle.none_);

    dc.endTextGraphic(text);
  }

  // ---------------------------------------------------------------------------
  // Graphic / Svg / Symbol (view_text.cpp:536-640)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawGraphic` (view_text.cpp:536).
  void drawGraphic(DeviceContext dc, Graphic graphic, TextDrawingParams params,
      int staffSize, bool dimin) {
    dc.startGraphic(graphic, '', graphic.id, graphicID: GraphicID.symbolRef);

    int width =
        graphic.getDrawingWidth(doc!.getDrawingUnit(staffSize), staffSize);
    int height =
        graphic.getDrawingHeight(doc!.getDrawingUnit(staffSize), staffSize);

    if (dimin) {
      width = (width * options!.graceFactor.value).toInt();
      height = (height * options!.graceFactor.value).toInt();
    }

    dc.drawGraphicUri(toDeviceContextX(params.x), toDeviceContextY(params.y),
        width, height, graphic.target ?? '');

    dc.endGraphic(graphic);
  }

  /// Mirrors `View::DrawSvg` (view_text.cpp:557).
  void drawSvg(DeviceContext dc, Svg svg, TextDrawingParams params,
      int staffSize, bool dimin) {
    dc.startGraphic(svg, '', svg.id);

    int width = svg.getWidth();
    int height = svg.getHeight();
    double scale = 1.0;

    if (staffSize != 100) {
      width = width * staffSize ~/ 100;
      height = height * staffSize ~/ 100;
      scale = scale * staffSize / 100;
    }
    if (dimin) {
      width = (width * options!.graceFactor.value).toInt();
      height = (height * options!.graceFactor.value).toInt();
      scale = scale * options!.graceFactor.value;
    }

    dc.drawSvgShape(toDeviceContextX(params.x), toDeviceContextY(params.y),
        width, height, scale, svg.content ?? '');

    dc.endGraphic(svg);
  }

  /// Mirrors `View::DrawSymbol` (view_text.cpp:585).
  void drawSymbol(DeviceContext dc, Symbol symbol, TextDrawingParams params) {
    dc.startTextGraphic(symbol, '', symbol.id);

    if (params.explicitPosition) {
      dc.moveTextTo(toDeviceContextX(params.x), toDeviceContextY(params.y),
          HorizontalAlignment.none_);
      params.explicitPosition = false;
    }

    int glyph = 0;
    if (symbol.hasGlyphNum && symbol.glyphNum != null) {
      glyph = symbol.glyphNum!;
    } else if (symbol.hasGlyphName && symbol.glyphName != null) {
      glyph = doc!.getResources().getGlyphCode(symbol.glyphName!);
    }

    final String str = glyph != 0 ? String.fromCharCode(glyph) : '';

    final FontInfo symbolFont = FontInfo();

    // @fontsize
    if (symbol.hasFontsize && symbol.fontsize != null) {
      final FontSize fs = symbol.fontsize!;
      if (fs.type == FontSizeType.fontSizeNumeric) {
        symbolFont.pointSize = fs.fontSizeNumeric.toInt();
      } else if (fs.type == FontSizeType.term) {
        final int percent = fs.getPercentForTerm();
        symbolFont.pointSize = params.pointSize * percent ~/ 100;
      } else if (fs.type == FontSizeType.percent) {
        symbolFont.pointSize = params.pointSize * fs.percent ~/ 100;
      }
    }

    // @fontstyle
    if (symbol.hasFontstyle && symbol.fontstyle != null) {
      final Fontstyle fs = symbol.fontstyle!;
      symbolFont.fontStyle = _convertFontStyle(fs);
    } else {
      symbolFont.fontStyle = FontStyle.normal;
    }

    // @glyph.auth == smufl
    if (symbol.hasGlyphAuth && symbol.glyphAuth == 'smufl') {
      final String s = str;
      final bool isFallbackNeeded =
          doc!.getResources().isSmuflFallbackNeeded(s);
      symbolFont.setSmuflWithFallback(isFallbackNeeded);
      symbolFont.faceName = doc!.getResources().currentFont;
      int pt =
          symbolFont.pointSize != 0 ? symbolFont.pointSize : params.pointSize;
      symbolFont.pointSize = (pt * _musicToLyricRatio()).toInt();
    }

    dc.setFont(symbolFont);

    // The C++ always draws the symbol through View::DrawTextString →
    // dc->DrawText (view_text.cpp:634) — a <tspan font-family="Leipzig">
    // carrying the SMuFL character when glyph.auth == smufl, never the
    // <use>-based DrawMusicText path. DrawText also flags VrvTextFont()
    // (svgdevicecontext.cpp:1104-1111) so Commit() appends the embedded
    // @font-face <style> (svgdevicecontext.cpp:184-196).
    drawTextString(dc, str, params);

    dc.resetFont();

    dc.endTextGraphic(symbol);
  }

  // ---------------------------------------------------------------------------
  // Running elements (view_text.cpp:642-701)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawRunningElements` (view_text.cpp:642).
  void drawRunningElements(DeviceContext dc, Page page) {
    if (dc is BBoxDeviceContext) {
      final BBoxDeviceContext bBoxDC = dc;
      if (!bBoxDC.updateVerticalValues()) return;
    }

    // Retrieve header/footer via Page.getHeader/getFooter (now implemented
    // in view_page.dart to return the scoredef's pgHead/pgFoot).
    final RunningElement? header = page.getHeader() as RunningElement?;
    final RunningElement? footer = page.getFooter() as RunningElement?;

    if (header != null) {
      drawTextLayoutElement(dc, header);
    }
    if (footer != null) {
      drawTextLayoutElement(dc, footer);
    }
  }

  /// Mirrors `View::DrawTextLayoutElement` (view_text.cpp:663).
  void drawTextLayoutElement(
      DeviceContext dc, TextLayoutElement textLayoutElement) {
    dc.startGraphic(textLayoutElement, '', textLayoutElement.id);

    final FontInfo textElementFont = FontInfo();
    if (!dc.useGlobalStyling()) {
      textElementFont.faceName = doc!.getResources().textFontName;
    }

    final TextDrawingParams params = TextDrawingParams();

    params.x = textLayoutElement.getDrawingX();
    params.y = textLayoutElement.getDrawingY();
    params.width = textLayoutElement.getTotalWidth(doc);
    params.alignment = HorizontalAlignment.none_;
    params.laidOut = true;
    params.pointSize = doc!.getDrawingLyricFont(100).pointSize;

    textElementFont.pointSize = params.pointSize;

    dc.setFont(textElementFont);

    drawRunningChildren(dc, textLayoutElement, params);

    dc.resetFont();

    dc.endGraphic(textLayoutElement);
  }

  /// Mirrors `View::DrawDiv` (view_text.cpp:696).
  void drawDiv(DeviceContext dc, Div div, System system) {
    drawTextLayoutElement(dc, div);
  }

  /// Mirrors `View::DrawF` (view_text.cpp:49).
  void drawF(DeviceContext dc, F f, TextDrawingParams params) {
    dc.startTextGraphic(f, '', f.id);

    drawTextChildren(dc, f, params);

    // If F has start and end, postpone connector drawing
    final bool hasStartEnd = f.startid != null && f.endid != null;
    if (hasStartEnd) {
      final System? currentSystem =
          f.getFirstAncestor(ClassId.system) as System?;
      if (currentSystem != null) {
        currentSystem.addToDrawingList(f);
      }
    }

    dc.endTextGraphic(f);
  }

  // ---------------------------------------------------------------------------
  // Helpers (private)
  // ---------------------------------------------------------------------------

  double _musicToLyricRatio() {
    final int smufl = doc!.drawingSmuflFontSize;
    final int lyric = doc!.drawingLyricFontSize != 0
        ? doc!.drawingLyricFontSize
        : (doc!.getOptions().unit.value * doc!.getOptions().lyricSize.value)
            .toInt();
    if (lyric == 0) return 1.0;
    return smufl / lyric;
  }

  FontStyle _convertFontStyle(Fontstyle style) {
    switch (style) {
      case Fontstyle.italic:
        return FontStyle.italic;
      case Fontstyle.oblique:
        return FontStyle.oblique;
      case Fontstyle.normal:
        return FontStyle.normal;
      default:
        return FontStyle.normal;
    }
  }

  FontWeight _convertFontWeight(Fontweight weight) {
    switch (weight) {
      case Fontweight.bold:
        return FontWeight.bold;
      case Fontweight.normal:
        return FontWeight.normal;
      default:
        return FontWeight.normal;
    }
  }

  int _findFirstOfHarm(String str, int start) {
    const String harmSet =
        '\u266D\u266E\u266F\uE260\uE261\uE262\uE263\uE264\uEA50\uEA51\uEA52\uEA53\uEA54\uEA55\uEA56\uEA57\uEA58\uEA59\uEA5A\uEA5B\uEA5C\uEA5D\uEA5E\uEA5F\uEA60\uEA61\uEA62\uEA63\uEA64\uEA65\uEA66\uEA67\uECC0';
    for (int i = start; i < str.length; i++) {
      if (harmSet.contains(str[i])) return i;
      // also check rune for supplementary ?
      final int cp = str.codeUnitAt(i);
      if (harmSet.runes.contains(cp)) return i;
    }
    return -1;
  }

  // Dynam helpers — port of dynam.cpp:29-260
  static const List<String> _dynamChars = ['p', 'm', 'f', 'r', 's', 'z', 'n'];
  static const List<int> _dynamSmufl = [
    0xE520,
    0xE521,
    0xE522,
    0xE523,
    0xE524,
    0xE525,
    0xE526
  ];

  bool _dynamGetSymbolsInStr(String str, List<(String, bool)> tokens) {
    tokens.clear();
    bool hasSymbols = false;
    String remaining = str;
    String currentToken = '';
    while (currentToken != remaining) {
      final int index = remaining.indexOf(' ');
      if (index == -1) {
        currentToken = remaining;
      } else {
        currentToken = remaining.substring(0, index);
      }

      if (_dynamIsSymbolOnly(currentToken)) {
        hasSymbols = true;
        if (tokens.isNotEmpty) {
          if (tokens.last.$2 == false) {
            tokens[tokens.length - 1] = ('${tokens.last.$1} ', false);
          } else {
            tokens.add((' ', false));
          }
        }
        tokens.add((currentToken, true));
      } else {
        if (tokens.isNotEmpty) {
          if (tokens.last.$2 == false) {
            tokens[tokens.length - 1] =
                ('${tokens.last.$1} $currentToken', false);
          } else {
            tokens.add((' $currentToken', false));
          }
        } else {
          tokens.add((currentToken, false));
        }
      }

      if (index == -1) break;
      currentToken = '';
      remaining = remaining.substring(index + 1);
    }
    return hasSymbols;
  }

  bool _dynamIsSymbolOnly(String str) {
    if (str.isEmpty) return false;
    for (final int cp in str.runes) {
      final String ch = String.fromCharCode(cp);
      if (!_dynamChars.contains(ch)) return false;
    }
    return true;
  }

  String _dynamGetSymbolStr(String str, bool singleGlyphs) {
    String dynam = '';
    if (!singleGlyphs) {
      if (str == 'p')
        dynam = String.fromCharCode(0xE520);
      else if (str == 'm')
        dynam = String.fromCharCode(0xE521);
      else if (str == 'f')
        dynam = String.fromCharCode(0xE522);
      else if (str == 'r')
        dynam = String.fromCharCode(0xE523);
      else if (str == 's')
        dynam = String.fromCharCode(0xE524);
      else if (str == 'z')
        dynam = String.fromCharCode(0xE525);
      else if (str == 'n')
        dynam = String.fromCharCode(0xE526);
      else if (str == 'pppppp')
        dynam = String.fromCharCode(0xE527);
      else if (str == 'ppppp')
        dynam = String.fromCharCode(0xE528);
      else if (str == 'pppp')
        dynam = String.fromCharCode(0xE529);
      else if (str == 'ppp')
        dynam = String.fromCharCode(0xE52A);
      else if (str == 'pp')
        dynam = String.fromCharCode(0xE52B);
      else if (str == 'mp')
        dynam = String.fromCharCode(0xE52C);
      else if (str == 'mf')
        dynam = String.fromCharCode(0xE52D);
      else if (str == 'pf')
        dynam = String.fromCharCode(0xE52E);
      else if (str == 'ff')
        dynam = String.fromCharCode(0xE52F);
      else if (str == 'fff')
        dynam = String.fromCharCode(0xE530);
      else if (str == 'ffff')
        dynam = String.fromCharCode(0xE531);
      else if (str == 'fffff')
        dynam = String.fromCharCode(0xE532);
      else if (str == 'ffffff')
        dynam = String.fromCharCode(0xE533);
      else if (str == 'fp')
        dynam = String.fromCharCode(0xE534);
      else if (str == 'fz')
        dynam = String.fromCharCode(0xE535);
      else if (str == 'sf')
        dynam = String.fromCharCode(0xE536);
      else if (str == 'sfp')
        dynam = String.fromCharCode(0xE537);
      else if (str == 'sfpp')
        dynam = String.fromCharCode(0xE538);
      else if (str == 'sfz')
        dynam = String.fromCharCode(0xE539);
      else if (str == 'sfzp')
        dynam = String.fromCharCode(0xE53A);
      else if (str == 'sffz')
        dynam = String.fromCharCode(0xE53B);
      else if (str == 'rf')
        dynam = String.fromCharCode(0xE53C);
      else if (str == 'rfz') dynam = String.fromCharCode(0xE53D);
    }

    if (dynam.isNotEmpty) return dynam;

    dynam = str;
    for (int i = 0; i < _dynamChars.length; i++) {
      final String from = _dynamChars[i];
      final String to = String.fromCharCode(_dynamSmufl[i]);
      dynam = dynam.replaceAll(from, to);
    }
    return dynam;
  }
}
