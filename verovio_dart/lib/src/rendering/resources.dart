/// Port of `resources.h/cpp` — manages SMuFL music fonts and text glyph
/// tables used for bounding-box calculations.
library;

import 'package:xml/xml.dart';

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/file_reader.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/smufl.dart';
import 'package:verovio_dart/src/rendering/glyph.dart';

const String _bravura = 'Bravura';
const String _leipzig = 'Leipzig';

/// A pair of style attributes used to select the text font variant.
typedef StyleAttributes = (FontWeight, FontStyle);

const StyleAttributes kDefaultStyle = (FontWeight.normal, FontStyle.normal);

/// One loaded SMuFL font (mirrors `Resources::LoadedFont`).
class LoadedFont {
  LoadedFont(this.name, this.isFallback);

  final String name;
  final Map<int, Glyph> glyphTable = {};

  /// If the font needs to fall back when a glyph is not present.
  final bool isFallback;

  /// CSS font for fonts loaded as zip archives.
  String css = '';

  /// Mirrors `LoadedFont::GetCSSFont(path)`.
  String getCssFont(String path) {
    if (css.isNotEmpty) return css;
    return resourceFileReader('$path/$name.css') ?? '';
  }
}

/// This class provides resource values. It manages fonts and glyph tables
/// (mirrors `vrv::Resources`).
class Resources {
  Resources() {
    path = defaultPath;
    currentStyle = kDefaultStyle;
    useLiberation = false;
  }

  // -------------------------------------------------------------------------
  // Static members
  // -------------------------------------------------------------------------

  /// The default path to the resources directory (e.g., the `assets/data`
  /// directory of the package containing the SMuFL fonts as XML).
  static String defaultPath = 'data';

  // -------------------------------------------------------------------------

  String path = '';
  bool useLiberation = false;
  String defaultFontName = '';
  String fallbackFontName = '';
  final Map<String, LoadedFont> loadedFonts = {};
  String currentFontName = '';

  /// A text font used for bounding box calculations.
  final Map<StyleAttributes, Map<int, Glyph>> textFont = {};
  StyleAttributes currentStyle = kDefaultStyle;

  /// A map of glyph name / code.
  final Map<String, int> glyphNameTable = {};

  /// Cache of the last glyph that was looked up in loaded fonts.
  (int, Glyph)? cachedGlyph;

  /// Return the name of the text font (Times or Liberation).
  String get textFontName => useLiberation ? 'Liberation' : 'Times';

  /// Status checker: at least two music fonts must be loaded.
  bool get ok => loadedFonts.length > 1;

  /// Init the SMuFL music and text fonts (mirrors `InitFonts`).
  bool initFonts() {
    cachedGlyph = null;
    loadedFonts.clear();

    // Font Bravura first. As it is expected to always have all symbols we
    // build the code -> name table from it.
    if (!loadFont(_bravura)) logError('Bravura font could not be loaded.');
    // Leipzig is our initial default font.
    if (!loadFont(_leipzig)) logError('Leipzig font could not be loaded.');

    defaultFontName = _leipzig;
    currentFontName = defaultFontName;
    fallbackFontName = defaultFontName;

    const List<(StyleAttributes, String, bool)> textFontInfos = [
      (kDefaultStyle, 'Times', true),
      ((FontWeight.bold, FontStyle.normal), 'Times-bold', false),
      ((FontWeight.bold, FontStyle.italic), 'Times-bold-italic', false),
      ((FontWeight.normal, FontStyle.italic), 'Times-italic', false),
    ];

    for (final (style, fileName, isMandatory) in textFontInfos) {
      if (!initTextFont(fileName, style) && isMandatory) {
        logError('Text font could not be initialized.');
        return false;
      }
    }

    currentStyle = kDefaultStyle;

    return true;
  }

  /// Set the font to be used and load it if necessary (mirrors `SetFont`).
  bool setFont(String fontName) {
    cachedGlyph = null;

    // Add the default font provided in options, if it is not one of the
    // previous.
    if (fontName.isNotEmpty && !isFontLoaded(fontName)) {
      if (!loadFont(fontName)) {
        logError('$fontName font could not be loaded.');
        return false;
      }
    }

    defaultFontName = isFontLoaded(fontName) ? fontName : _leipzig;
    currentFontName = defaultFontName;

    return true;
  }

  /// Set the fallback font (Leipzig or Bravura) when some glyphs are missing
  /// in the current font.
  void setFallbackFont(String fontName) {
    cachedGlyph = null;
    fallbackFontName = fontName;
  }

  /// Select a particular font.
  bool setCurrentFont(String fontName, {bool allowLoading = false}) {
    cachedGlyph = null;

    if (isFontLoaded(fontName)) {
      currentFontName = fontName;
      return true;
    } else if (allowLoading && loadFont(fontName)) {
      currentFontName = fontName;
      return true;
    }

    return false;
  }

  String get currentFont => currentFontName;

  bool isFontLoaded(String fontName) => loadedFonts.containsKey(fontName);

  /// Returns the glyph (if it exists) for a [smuflCode] in the current SMuFL
  /// font.
  Glyph? getGlyphByCode(int smuflCode) {
    final (int cachedCode, Glyph? cachedValue) = cachedGlyph ?? (0, null);
    if (cachedValue != null && cachedCode == smuflCode) {
      return cachedValue;
    }

    final Map<int, Glyph> currentTable = getCurrentGlyphTable();
    final Glyph? glyph = currentTable[smuflCode];
    if (glyph != null) {
      cachedGlyph = (smuflCode, glyph);
      return glyph;
    } else if (!isCurrentFontFallback) {
      final Glyph? fallback = getFallbackGlyphTable()[smuflCode];
      if (fallback != null) {
        cachedGlyph = (smuflCode, fallback);
        return fallback;
      }
    }
    return null;
  }

  /// Returns the glyph (if it exists) for a [smuflName] in the current SMuFL
  /// font.
  Glyph? getGlyphByName(String smuflName) {
    final int code = getGlyphCode(smuflName);
    if (code != 0) return getGlyphByCode(code);
    return null;
  }

  /// Returns the glyph code for a [smuflName] (0 if unknown).
  int getGlyphCode(String smuflName) => glyphNameTable[smuflName] ?? 0;

  /// Check if the text has any character that needs the SMuFL fallback font.
  bool isSmuflFallbackNeeded(String text) {
    if (loadedFonts[currentFontName]?.isFallback ?? false) return false;
    for (final c in text.runes) {
      if (!getCurrentGlyphTable().containsKey(c)) return true;
    }
    return false;
  }

  /// Check if the current font is the fallback font.
  bool get isCurrentFontFallback => currentFontName == fallbackFontName;

  /// Returns true if [fontName] is loaded and contains [smuflCode].
  bool fontHasGlyphAvailable(String fontName, int smuflCode) {
    if (!isFontLoaded(fontName)) return false;
    return loadedFonts[fontName]!.glyphTable.containsKey(smuflCode);
  }

  /// Get the CSS font string for the corresponding font. Returns an empty
  /// string if the font has not been loaded.
  String getCSSFontFor(String fontName) {
    if (fontName == textFontName) {
      return resourceFileReader('$path/$textFontName.css') ?? '';
    }

    final LoadedFont? font = loadedFonts[fontName];
    if (font == null) return '';

    return font.getCssFont(path);
  }

  /// Set the current text style (mirrors `SelectTextFont`).
  void selectTextFont(FontWeight fontWeight, FontStyle fontStyle) {
    if (fontWeight == FontWeight.none_) fontWeight = FontWeight.normal;
    if (fontStyle == FontStyle.none_) fontStyle = FontStyle.normal;

    currentStyle = (fontWeight, fontStyle);
    if (!textFont.containsKey(currentStyle)) {
      logWarning(
          'Text font for style ($fontWeight, $fontStyle) is not loaded. Use default');
      currentStyle = kDefaultStyle;
    }
  }

  /// Returns the glyph (if it exists) for a text-font [code].
  Glyph? getTextGlyph(int code) {
    final StyleAttributes style =
        textFont.containsKey(currentStyle) ? currentStyle : kDefaultStyle;
    final Map<int, Glyph>? table = textFont[style];
    if (table == null) return null;
    return table[code];
  }

  Map<int, Glyph> getCurrentGlyphTable() =>
      loadedFonts[currentFontName]!.glyphTable;

  Map<int, Glyph> getFallbackGlyphTable() =>
      loadedFonts[fallbackFontName]!.glyphTable;

  /// Load a music font from `<path>/<fontName>.xml` (mirrors `LoadFont`).
  ///
  /// Custom fonts loaded from zip archives are not supported yet; they
  /// arrive with the IO phase.
  bool loadFont(String fontName) {
    final String? content = resourceFileReader('$path/$fontName.xml');
    if (content == null) {
      // File not found — default bounding boxes will be used.
      logError('Failed to load font and glyph bounding boxes');
      return false;
    }

    XmlDocument doc;
    try {
      doc = XmlDocument.parse(content);
    } catch (_) {
      logError('Failed to parse the XML file containing glyph bounding boxes');
      return false;
    }

    final XmlElement root = doc.rootElement;
    final String? unitsPerEmAttr =
        root.getAttribute('units-per-em')?.trim();
    if (unitsPerEmAttr == null) {
      logError('No units-per-em attribute in bounding box file');
      return false;
    }
    final int unitsPerEm = int.tryParse(unitsPerEmAttr) ?? 0;

    final bool buildNameTable = fontName == _bravura;
    final bool isFallback = fontName == _bravura || fontName == _leipzig;

    final LoadedFont font = LoadedFont(fontName, isFallback);
    loadedFonts[fontName] = font;

    final Map<int, Glyph> glyphTable = font.glyphTable;

    for (final XmlElement g in root.findElements('g')) {
      final String? cAttribute = g.getAttribute('c');
      final String? nAttribute = g.getAttribute('n');
      if (cAttribute == null || nAttribute == null) continue;

      final Glyph glyph = Glyph();
      glyph.unitsPerEm = unitsPerEm * 10;
      glyph.codeStr = cAttribute;
      double x = 0.0, y = 0.0, width = 0.0, height = 0.0;
      final String? xa = g.getAttribute('x');
      final String? ya = g.getAttribute('y');
      final String? wa = g.getAttribute('w');
      final String? ha = g.getAttribute('h');
      if (xa != null) x = double.tryParse(xa) ?? 0.0;
      if (ya != null) y = double.tryParse(ya) ?? 0.0;
      if (wa != null) width = double.tryParse(wa) ?? 0.0;
      if (ha != null) height = double.tryParse(ha) ?? 0.0;
      glyph.setBoundingBox(x, y, width, height);

      final String glyphFilename = '$fontName/$cAttribute.xml';
      // Store the path of the glyph XML (custom fonts from zip archives
      // will store the XML content instead once supported).
      glyph.path = '$path/$glyphFilename';

      final String? hax = g.getAttribute('h-a-x');
      if (hax != null) glyph.setHorizAdvXFromDouble(double.tryParse(hax) ?? 0.0);

      // Load anchors.
      for (final XmlElement anchor in g.findElements('a')) {
        final String? name = anchor.getAttribute('n');
        if (name != null) {
          // No check for possibly missing x/y attributes - not very safe.
          glyph.setAnchor(
            name,
            double.tryParse(anchor.getAttribute('x') ?? '') ?? 0.0,
            double.tryParse(anchor.getAttribute('y') ?? '') ?? 0.0,
          );
        }
      }

      final int smuflCode = int.tryParse(cAttribute, radix: 16) ?? 0;
      glyphTable[smuflCode] = glyph;
      if (buildNameTable) {
        glyphNameTable[nAttribute] = smuflCode;
      }
    }

    if (isFallback && glyphTable.length < smuflCount) {
      logError(
          'Expected $smuflCount default SMuFL glyphs but could load only ${glyphTable.length}.');
      return false;
    }

    return true;
  }

  /// Init a text font (bounding boxes and ASCII only).
  ///
  /// Mirrors `InitTextFont`; the [fileName] is one of Times, Times-bold,
  /// Times-bold-italic, Times-italic.
  bool initTextFont(String fileName, StyleAttributes style) {
    // For the text font we load the bounding boxes only. For now we have
    // only Times bounding boxes for ASCII chars; for any other char we use
    // the 'o' bounding box.
    final String? content =
        resourceFileReader('$path/text/$fileName.xml');
    if (content == null) {
      // File not found — default bounding boxes will be used.
      logInfo("Cannot load bounding boxes for text font '$fileName'");
      return false;
    }
    XmlDocument doc;
    try {
      doc = XmlDocument.parse(content);
    } catch (_) {
      logInfo("Cannot load bounding boxes for text font '$fileName'");
      return false;
    }
    final XmlElement root = doc.rootElement;
    final String? unitsPerEmAttr = root.getAttribute('units-per-em');
    if (unitsPerEmAttr == null) {
      logWarning('No units-per-em attribute in bounding box file');
      return false;
    }
    final int unitsPerEm = int.tryParse(unitsPerEmAttr) ?? 0;

    final Map<int, Glyph> currentTable =
        textFont.putIfAbsent(style, () => {});
    for (final XmlElement g in root.findElements('g')) {
      final String? c = g.getAttribute('c');
      if (c == null) continue;
      final int code = int.tryParse(c, radix: 16) ?? 0;

      // We create a glyph with only the units per em which is the only info
      // we need for the bounding boxes; path and codeStr remain `[unset]`.
      final Glyph glyph = Glyph.text(unitsPerEm);
      double x = 0.0, y = 0.0, width = 0.0, height = 0.0;
      final String? xa = g.getAttribute('x');
      final String? ya = g.getAttribute('y');
      final String? wa = g.getAttribute('w');
      final String? ha = g.getAttribute('h');
      if (xa != null) x = double.tryParse(xa) ?? 0.0;
      if (ya != null) y = double.tryParse(ya) ?? 0.0;
      if (wa != null) width = double.tryParse(wa) ?? 0.0;
      if (ha != null) height = double.tryParse(ha) ?? 0.0;
      glyph.setBoundingBox(x, y, width, height);

      final String? hax = g.getAttribute('h-a-x');
      if (hax != null) glyph.setHorizAdvXFromDouble(double.tryParse(hax) ?? 0.0);

      if (currentTable.containsKey(code)) {
        logDebug('Redefining $code with $fileName');
      }
      currentTable[code] = glyph;
    }
    return true;
  }
}
