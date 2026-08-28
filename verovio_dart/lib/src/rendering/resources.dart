/// Port of `resources.h/cpp` — manages SMuFL music fonts and text glyph
/// tables used for bounding-box calculations.
library;

import 'package:xml/xml.dart';

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/file_reader.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/smufl.dart' as smufl;
import 'package:verovio_dart/src/core/zip_file_reader.dart';
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

  /// Add custom (external) fonts (mirrors `AddCustom`).
  ///
  /// Each entry of [extraFonts] is the path of a zip archive containing a
  /// custom font: `<name>.xml` (bounding boxes) and `<name>.css` at the
  /// archive root, glyph XML files in the `<name>/` folder.
  bool addCustom(List<String> extraFonts) {
    bool success = true;
    // Options supplied fonts.
    for (final String fontFile in extraFonts) {
      final ZipFileReader zipFile = ZipFileReader();
      if (!zipFile.load(fontFile)) {
        continue;
      }
      final String fontName = getCustomFontname(fontFile, zipFile);
      if (fontName.isEmpty || isFontLoaded(fontName)) {
        continue;
      }
      success = success && loadFont(fontName, zipFile);
      if (!success) {
        logError('Option supplied font $fontName could not be loaded.');
      }
    }
    return success;
  }

  /// Load all music fonts available in the resource directory (mirrors
  /// `LoadAll`).
  ///
  /// Deviations from the C++:
  /// - The directory iteration goes through the pluggable
  ///   [resourceDirectoryLister] instead of
  ///   `std::filesystem::directory_iterator`. A `null` result (directory
  ///   unavailable or web stub) counts as an empty directory, for which
  ///   `std::ranges::all_of` would also return `true`.
  bool loadAll() {
    final List<String>? entries = resourceDirectoryLister('$path/');
    if (entries == null) return true;
    for (final String entry in entries) {
      final String fileName = _fileNameOf(entry);
      // Mirrors the check `has_extension() && has_stem() && extension() ==
      // ".xml"`.
      if (_extensionOf(fileName).isNotEmpty &&
          _stemOf(fileName).isNotEmpty &&
          _extensionOf(fileName) == '.xml') {
        final String fontName = _stemOf(fileName);
        if (!isFontLoaded(fontName) && !loadFont(fontName)) {
          return false;
        }
      }
    }
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

  /// Get the fallback font name (mirrors `GetFallbackFont`).
  String get fallbackFont => fallbackFontName;

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

  /// Retrieve the font name either from the filename path or from the
  /// zipFile content (mirrors `GetCustomFontname`).
  ///
  /// Deviations from the C++:
  /// - The C++ has two variants selected with `#ifdef __EMSCRIPTEN__`: the
  ///   desktop one derives the name from the filename stem, the emscripten
  ///   one extracts it from the bounding box XML found in the archive.
  ///   Dart has no per-target compilation, so the emscripten scan of the
  ///   archive file list is tried first and the filename stem is the
  ///   fallback. On the standard custom-font layout (`<Name>.xml` and
  ///   `<Name>.css` at the archive root, glyphs in `<Name>/`) both variants
  ///   agree; on the desktop C++ a zip whose name differs from the archive
  ///   XML name fails later in `LoadFont` anyway (`<stem>.xml` is not in
  ///   the archive), so the scan order only loads archives the C++ would
  ///   reject.
  String getCustomFontname(String filename, ZipFileReader zipFile) {
    // Extracts the font name from the bounding box XML file.
    // For example, OneGlyph/OneGlyph.xml
    for (final String s in zipFile.getFileList()) {
      final String name = _fileNameOf(s);
      final String parent = _parentOf(s);
      if (parent.isEmpty || parent == _stemOf(name)) {
        if (_extensionOf(name) == '.xml') {
          return _stemOf(name);
        }
      }
    }
    // Desktop variant: derive the name from the filename stem.
    final String stem = _stemOf(_fileNameOf(filename));
    if (stem.isNotEmpty) return stem;
    logWarning(
        'The font name could not be extracted from the archive XML file');
    return '';
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

  /// Load a music font, from `<path>/<fontName>.xml` or, when [zipFile] is
  /// given, from the archive (mirrors `LoadFont`).
  bool loadFont(String fontName, [ZipFileReader? zipFile]) {
    String? content;
    if (zipFile != null) {
      // For zip archive custom font, load the data from the zipFile.
      final String filename = '$fontName.xml';
      if (!zipFile.hasFile(filename)) {
        // File not found — default bounding boxes will be used.
        logError('Failed to load the XML file containing glyph bounding boxes');
        return false;
      }
      content = zipFile.readTextFile(filename);
    } else {
      content = resourceFileReader('$path/$fontName.xml');
      if (content == null) {
        // File not found — default bounding boxes will be used.
        logError('Failed to load font and glyph bounding boxes');
        return false;
      }
    }

    XmlDocument doc;
    try {
      doc = XmlDocument.parse(content);
    } catch (_) {
      logError('Failed to parse the XML file containing glyph bounding boxes');
      return false;
    }

    final XmlElement root = doc.rootElement;
    final String? unitsPerEmAttr = root.getAttribute('units-per-em')?.trim();
    if (unitsPerEmAttr == null) {
      logError('No units-per-em attribute in bounding box file');
      return false;
    }
    final int unitsPerEm = int.tryParse(unitsPerEmAttr) ?? 0;

    final bool buildNameTable = fontName == _bravura;
    final bool isFallback = fontName == _bravura || fontName == _leipzig;

    final LoadedFont font = LoadedFont(fontName, isFallback);
    loadedFonts[fontName] = font;

    // For zip archive custom font also store the CSS.
    if (zipFile != null) {
      font.css = zipFile.readTextFile('$fontName.css');
    }

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
      if (zipFile != null) {
        // Store the XML in the glyph for fonts loaded from zip files.
        glyph.xml = zipFile.readTextFile(glyphFilename);
      } else {
        // Otherwise only store the path.
        glyph.path = '$path/$glyphFilename';
      }

      final String? hax = g.getAttribute('h-a-x');
      if (hax != null) {
        glyph.setHorizAdvXFromDouble(double.tryParse(hax) ?? 0.0);
      }

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

    if (isFallback && glyphTable.length < smufl.smuflCount) {
      logError(
          'Expected ${smufl.smuflCount} default SMuFL glyphs but could load only ${glyphTable.length}.');
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
    final String? content = resourceFileReader('$path/text/$fileName.xml');
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

    final Map<int, Glyph> currentTable = textFont.putIfAbsent(style, () => {});
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
      if (hax != null) {
        glyph.setHorizAdvXFromDouble(double.tryParse(hax) ?? 0.0);
      }

      if (currentTable.containsKey(code)) {
        logDebug('Redefining $code with $fileName');
      }
      currentTable[code] = glyph;
    }
    return true;
  }

  /// Static method that converts unicode music code points to SMuFL
  /// equivalent. Return the parameter char if nothing can be converted
  /// (mirrors the static `Resources::GetSmuflGlyphForUnicodeChar`).
  static int getSmuflGlyphForUnicodeChar(int unicodeChar) =>
      smufl.getSmuflGlyphForUnicodeChar(unicodeChar);

  //----------------//
  // Port helpers   //
  //----------------//

  /// Port helper (no C++ counterpart): the file name of a path, mirroring
  /// `std::filesystem::path::filename` for '/'- and '\'-separated paths.
  static String _fileNameOf(String path) {
    final int slash = path.lastIndexOf('/');
    final int backslash = path.lastIndexOf('\\');
    final int sep = slash > backslash ? slash : backslash;
    return sep >= 0 ? path.substring(sep + 1) : path;
  }

  /// Port helper (no C++ counterpart): the parent directory of a path,
  /// mirroring `std::filesystem::path::parent_path` ('' when there is none).
  static String _parentOf(String path) {
    final int slash = path.lastIndexOf('/');
    final int backslash = path.lastIndexOf('\\');
    final int sep = slash > backslash ? slash : backslash;
    return sep >= 0 ? path.substring(0, sep) : '';
  }

  /// Port helper (no C++ counterpart): the extension of a file name,
  /// mirroring `std::filesystem::path::extension` (empty when the only dot
  /// is the leading character, e.g., `.xml` has no extension).
  static String _extensionOf(String fileName) {
    final int dot = fileName.lastIndexOf('.');
    if (dot <= 0) return '';
    return fileName.substring(dot);
  }

  /// Port helper (no C++ counterpart): the stem of a file name, mirroring
  /// `std::filesystem::path::stem` (the name without its extension).
  static String _stemOf(String fileName) {
    final int dot = fileName.lastIndexOf('.');
    if (dot <= 0) return fileName;
    return fileName.substring(0, dot);
  }
}
