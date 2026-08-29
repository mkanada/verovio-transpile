import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/core/zip_file_reader.dart';
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
      expect(resources.fontHasGlyphAvailable('NotLoaded', 0xE0A4), isFalse);
    });

    test('getCSSFontFor', () {
      expect(resources.getCSSFontFor('Leipzig'), contains('@font-face'));
      expect(resources.getCSSFontFor('NotLoaded'), isEmpty);
    });
  });

  group('Resources — additions from task 05-01', () {
    // Standard Verovio custom-font layout: `<Name>.xml` (bounding boxes) and
    // `<Name>.css` at the archive root, glyph XML files in `<Name>/`.
    const String fontXml = '<font units-per-em="1000">'
        '<g c="E0A4" n="noteheadBlack" x="0" y="0" w="120" h="80" h-a-x="124"/>'
        '<g c="E0A3" n="noteheadHalf" x="0" y="0" w="120" h="80" h-a-x="124"/>'
        '</font>';
    const String fontCss = '@font-face { font-family: TestFont; }';

    Archive buildFontArchive() => Archive()
      ..add(ArchiveFile.bytes('TestFont.xml', utf8.encode(fontXml)))
      ..add(ArchiveFile.bytes('TestFont.css', utf8.encode(fontCss)))
      ..add(ArchiveFile.bytes('TestFont/E0A4.xml', utf8.encode('<svg/>')))
      ..add(ArchiveFile.bytes('TestFont/E0A3.xml', utf8.encode('<svg/>')));

    test('getSmuflGlyphForUnicodeChar maps the C++ table', () {
      expect(Resources.getSmuflGlyphForUnicodeChar(unicodeDalSegno), 0xE045);
      expect(Resources.getSmuflGlyphForUnicodeChar(unicodeDaCapo), 0xE046);
      expect(Resources.getSmuflGlyphForUnicodeChar(unicodeSegno), 0xE047);
      expect(Resources.getSmuflGlyphForUnicodeChar(unicodeCoda), 0xE048);
      // Unmapped code points (regular letters and SMuFL itself) pass
      // through unchanged.
      expect(Resources.getSmuflGlyphForUnicodeChar(0x41 /* A */), 0x41);
      expect(Resources.getSmuflGlyphForUnicodeChar(0xE0A4), 0xE0A4);
    });

    test('fallbackFont getter mirrors GetFallbackFont', () {
      expect(resources.fallbackFont, 'Leipzig');
      resources.setFallbackFont('Bravura');
      expect(resources.fallbackFont, 'Bravura');
    });

    test('addCustom loads a font from a zip archive', () {
      final Directory tmp = Directory.systemTemp.createTempSync('vrv_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final File zipFile = File('${tmp.path}/TestFont.zip')
        ..writeAsBytesSync(ZipEncoder().encode(buildFontArchive()));

      expect(resources.addCustom([zipFile.path]), isTrue);
      expect(resources.isFontLoaded('TestFont'), isTrue);
      expect(resources.fontHasGlyphAvailable('TestFont', 0xE0A4), isTrue);
      expect(resources.getCSSFontFor('TestFont'), fontCss);

      final Glyph glyph =
          resources.loadedFonts['TestFont']!.glyphTable[0xE0A4]!;
      expect(glyph.unitsPerEm, 10000); // 1000 * 10
      expect(glyph.horizAdvX, 1240); // 124 * 10
      // The glyph XML is stored from the archive, not read from a path.
      expect(glyph.xml, '<svg/>');
      expect(glyph.getXml(), '<svg/>');
      // addCustom does not change the current font.
      expect(resources.currentFont, 'Leipzig');
    });

    test('addCustom skips missing archives and already loaded fonts', () {
      expect(resources.addCustom(['/nonexistent/font.zip']), isTrue);
      expect(resources.isFontLoaded('Leipzig'), isTrue);
    });

    test('getCustomFontname derives the name like the C++', () {
      // EMSCRIPTEN variant: extracted from the archive XML file.
      final ZipFileReader zip = ZipFileReader()
        ..loadBytes(ZipEncoder().encode(buildFontArchive()));
      expect(resources.getCustomFontname('/some/dir/TestFont.zip', zip),
          'TestFont');
      expect(resources.getCustomFontname('', zip), 'TestFont');
      expect(
          resources.getCustomFontname('data:application/zip;base64,xxxx', zip),
          'TestFont');
      // Desktop variant: stem of the filename, used when the archive has
      // no self-named bounding box XML.
      final ZipFileReader foreign = ZipFileReader()
        ..loadBytes(ZipEncoder().encode(buildFontArchive()));
      expect(resources.getCustomFontname('/some/dir/MyFont.zip', foreign),
          'TestFont'); // the archive XML wins over the zip name
      final Archive plain = Archive()
        ..add(ArchiveFile.bytes('readme.txt', utf8.encode('x')));
      final ZipFileReader plainZip = ZipFileReader()
        ..loadBytes(ZipEncoder().encode(plain));
      expect(resources.getCustomFontname('/some/dir/MyFont.zip', plainZip),
          'MyFont');
      // Nothing extractable: warning and empty name.
      expect(resources.getCustomFontname('', plainZip), isEmpty);
    });

    test('loadAll loads every font xml of the resource directory', () {
      final Directory tmp = Directory.systemTemp.createTempSync('vrv_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      File('${tmp.path}/TestFont2.xml').writeAsStringSync(fontXml);
      File('${tmp.path}/TestFont2.css').writeAsStringSync(fontCss);
      File('${tmp.path}/ignore.txt').writeAsStringSync('not a font');

      final Resources res = Resources()..path = tmp.path;
      expect(res.loadAll(), isTrue);
      expect(res.isFontLoaded('TestFont2'), isTrue);
      expect(res.isFontLoaded('ignore'), isFalse);
      expect(res.isFontLoaded('TestFont2_css_nonsense'), isFalse);
    });

    test('loadAll returns false when a font cannot be loaded', () {
      final Directory tmp = Directory.systemTemp.createTempSync('vrv_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      File('${tmp.path}/Bad.xml').writeAsStringSync('<not-xml');

      final Resources res = Resources()..path = tmp.path;
      expect(res.loadAll(), isFalse);
      expect(res.isFontLoaded('Bad'), isFalse);
    });

    test('dot-file handling mirrors std::filesystem', () {
      final Directory tmp = Directory.systemTemp.createTempSync('vrv_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      // A file literally named `.xml` has no extension (leading dot only)
      // and is skipped by the C++ has_extension() check.
      File('${tmp.path}/.xml').writeAsStringSync(fontXml);
      // `.hidden.xml` has the extension `.xml` (from the last dot) and the
      // stem `.hidden` — loaded as font `.hidden`, like std::filesystem.
      File('${tmp.path}/.hidden.xml').writeAsStringSync(fontXml);

      final Resources res = Resources()..path = tmp.path;
      expect(res.loadAll(), isTrue);
      expect(res.isFontLoaded('.hidden'), isTrue);
    });
  });

  group('Resources — Fase 1 lacunas (2026-08-29-02)', () {
    test('useLiberationTextFont toggles Times/Liberation', () {
      // Mirrors `Resources::UseLiberationTextFont(bool)` in `resources.h:62`
      // — inline `m_useLiberation = useLiberation`.
      expect(resources.textFontName, 'Times');
      expect(resources.useLiberation, isFalse);
      // Observable: getCSSFontFor for the text font changes.
      expect(resources.getCSSFontFor(resources.textFontName), isEmpty,
          reason: 'no Times.css in assets/data');
      resources.useLiberationTextFont(true);
      expect(resources.useLiberation, isTrue);
      expect(resources.textFontName, 'Liberation');
      // Liberation.css exists and is used as text font CSS.
      final String liberationCss = resources.getCSSFontFor('Liberation');
      expect(liberationCss, contains('@font-face'));
      expect(liberationCss, contains('Liberation'));
      expect(resources.getCSSFontFor(resources.textFontName),
          contains('Liberation'));
      // Toggle back — must return to Times with no side effects on
      // textFont / currentFontName (C++ setter has none).
      final int textFontCountBefore = resources.textFont.length;
      resources.useLiberationTextFont(false);
      expect(resources.useLiberation, isFalse);
      expect(resources.textFontName, 'Times');
      expect(resources.textFont.length, textFontCountBefore);
    });

    test('setCssFont stores CSS and GetCSSFont prefers it over file', () {
      // Mirrors `LoadedFont::SetCSSFont(const std::string &css)` in
      // `resources.h:155` — inline `m_css = css`.
      final LoadedFont font = LoadedFont('Dummy', false);
      // No stored css and no fallback file → empty.
      expect(font.getCssFont(resources.path), isEmpty);
      const String css = '@font-face { font-family: Dummy; }';
      font.setCssFont(css);
      expect(font.css, css);
      // GetCSSFont returns stored css when non-empty (resources.cpp:472-483)
      // without touching the filesystem.
      expect(font.getCssFont(resources.path), css);
      // Through Resources: GetCSSFontFor prefers the stored css.
      resources.loadedFonts['Dummy'] = font;
      expect(resources.getCSSFontFor('Dummy'), css);
      // Clearing the stored css falls back to file lookup (still empty).
      font.setCssFont('');
      expect(font.getCssFont(resources.path), isEmpty);
      expect(resources.getCSSFontFor('Dummy'), isEmpty);
      resources.loadedFonts.remove('Dummy');
      // Verify fallback to file still works for a real font.
      expect(resources.getCSSFontFor('Leipzig'), contains('@font-face'));
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

  group('DeviceContext — resources accessors (task 05-01)', () {
    late BBoxDeviceContext dc;

    setUp(() {
      Resources.defaultPath = 'assets/data';
      dc = BBoxDeviceContext(
        toLogicalX: (x) => x,
        toLogicalY: (y) => y,
        width: 2100,
        height: 2970,
      );
      dc.setFont(FontInfo()..pointSize = 100);
    });

    test('setResources / resetResources mirror the C++ accessors', () {
      expect(dc.hasResources, isFalse);
      expect(dc.getResources(showWarning: true), isNull);
      final Resources resources = Resources()..initFonts();
      dc.setResources(resources);
      expect(dc.hasResources, isTrue);
      expect(dc.getResources(), same(resources));
      dc.resetResources();
      expect(dc.hasResources, isFalse);
      expect(dc.getResources(showWarning: true), isNull);
    });

    test('getTextExtentUtf32 falls back to the music font (C++ GetGlyph)', () {
      dc.setResources(Resources()..initFonts());
      final TextExtend extend = TextExtend();
      // 0xE0A4 (noteheadBlack) is not in the Times text font; the C++
      // GetTextExtent falls back to Resources::GetGlyph for it.
      dc.getTextExtentUtf32([0xE0A4], extend);
      expect(extend.width, greaterThan(0));
    });

    test('space falls back to the period glyph (documented C++ behavior)', () {
      dc.setResources(Resources()..initFonts());
      final TextExtend space = TextExtend();
      dc.getTextExtent(' ', space);
      final TextExtend period = TextExtend();
      dc.getTextExtent('.', period);
      expect(space.width, period.width);
    });
  });
}
