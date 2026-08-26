/// Port of `glyph.h/cpp` — a SMuFL music (or text) font glyph.
library;

import 'package:verovio_dart/src/core/file_reader.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';

/// This class is used for storing a music font glyph.
///
/// All glyph values are integers. However, for keeping precision as high as
/// possible, they are 10 times the original values. Since the units per em
/// value is also 10 times the original, there is no impact on calculations
/// elsewhere. It does increase the precision because units are always
/// multiplied by a point size before being divided by the unit per em.
/// Ex: 10.2 becomes 102, with a unit per em of 20480 (instead of 2048).
class Glyph {
  /// Default constructor mirroring `Glyph()`.
  Glyph()
      : unitsPerEm = 20480,
        codeStr = '[unset]',
        path = '[unset]';

  /// Text-font constructor: only the units per em is needed for bounding
  /// boxes; path and codeStr remain `[unset]` (mirrors `Glyph(int)`).
  Glyph.text(int upm)
      : unitsPerEm = upm * 10,
        codeStr = '[unset]',
        path = '[unset]';

  /// Constructor reading the units-per-em from a glyph SVG file's viewBox
  /// (mirrors `Glyph(path, codeStr)`).
  Glyph.fromFile(this.path, this.codeStr) : unitsPerEm = 20480 {
    final String? content = resourceFileReader(path);
    if (content == null) {
      // Font file could not be loaded — keep defaults.
      return;
    }
    final RegExp viewBoxRegex = RegExp(r'viewBox\s*=\s*"([^"]*)"');
    final Match? match = viewBoxRegex.firstMatch(content);
    if (match == null) return;
    final List<String> parts = match.group(1)!.trim().split(RegExp(r'\s+'));
    // The viewBox attribute is expected to contain four coordinates:
    // "0 0 2048 2048" — we are looking for the last value.
    if (parts.length < 4) return;
    unitsPerEm = (int.tryParse(parts.last) ?? 2048) * 10;
  }

  /// The bounding box values of the glyph.
  int x = 0, y = 0, width = 0, height = 0;

  /// The horizontal adv x (if any), scaled by 10.
  int horizAdvX = 0;

  /// Units per EM for the glyph.
  int unitsPerEm;

  /// The Unicode code in hexa as string.
  String codeStr;

  /// Path to the glyph XML file.
  String path;

  /// XML content of the glyph, used only for glyphs from zip custom fonts.
  String xml = '';

  /// The available anchors.
  final Map<SMuFLGlyphAnchor, Point> anchors = {};

  /// A flag indicating it is a fallback.
  bool isFallback = false;

  /// Set the bounds of the glyph. These are original values from the font
  /// and will be stored as `(10.0 * x).toInt()`.
  void setBoundingBox(double bx, double by, double bw, double bh) {
    x = (10.0 * bx).toInt();
    y = (10.0 * by).toInt();
    width = (10.0 * bw).toInt();
    height = (10.0 * bh).toInt();
  }

  /// Get the bounds of the glyph as a record `(x, y, w, h)`.
  (int, int, int, int) getBoundingBox() => (x, y, width, height);

  /// Mirrors `SetHorizAdvX(double)` (stores the value scaled by 10).
  void setHorizAdvXFromDouble(double horizAdv) =>
      horizAdvX = (horizAdv * 10.0).toInt();

  /// Add an anchor for the glyph. The [anchorStr] is turned into a
  /// [SMuFLGlyphAnchor] ("cutOutNE" => `SMuFLGlyphAnchor.cutOutNE`).
  void setAnchor(String anchorStr, double ax, double ay) {
    late SMuFLGlyphAnchor anchorId;
    switch (anchorStr) {
      case 'stemDownNW':
        anchorId = SMuFLGlyphAnchor.stemDownNW;
      case 'stemUpSE':
        anchorId = SMuFLGlyphAnchor.stemUpSE;
      case 'cutOutNE':
        anchorId = SMuFLGlyphAnchor.cutOutNE;
      case 'cutOutNW':
        anchorId = SMuFLGlyphAnchor.cutOutNW;
      case 'cutOutSE':
        anchorId = SMuFLGlyphAnchor.cutOutSE;
      case 'cutOutSW':
        anchorId = SMuFLGlyphAnchor.cutOutSW;
      // Silently ignore unused anchors.
      default:
        return;
    }
    // Anchor points are given as staff spaces (upm / 4).
    anchors[anchorId] =
        Point((ax * unitsPerEm / 4).toInt(), (ay * unitsPerEm / 4).toInt());
  }

  /// Check if the glyph has the provided anchor.
  bool hasAnchor(SMuFLGlyphAnchor anchor) => anchors.containsKey(anchor);

  /// Return the SMuFL anchor for the glyph (must exist).
  Point getAnchor(SMuFLGlyphAnchor anchor) => anchors[anchor]!;

  /// Return the XML (content) of the glyph: the stored XML or load it from
  /// the path.
  String getXml() {
    if (xml.isNotEmpty) return xml;
    return resourceFileReader(path) ?? '';
  }
}
