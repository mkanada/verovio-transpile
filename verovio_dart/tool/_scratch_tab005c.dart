import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/testing/draw_recorder.dart';

void main() {
  Resources.defaultPath = 'assets/data';
  final res = Resources();
  res.initFonts();
  print('textFont=${res.textFontName}');
  final dc = DrawRecorder(docId: 'docid');
  dc.setResources(res);
  final fi = FontInfo()
    ..faceName = res.textFontName
    ..pointSize = 720; // lyric font-ish; exact value TBD
  dc.setFont(fi);
  for (final s in ['Staff notation', 'Guitar tablature', 'Staff-like notation']) {
    final ext = TextExtend();
    dc.getTextExtent(s, ext, typeSize: true);
    print('$s => width=${ext.width}');
  }
  for (final c in ['-', 'S', 'o', '.', ' ']) {
    final g = res.getTextGlyph(c.codeUnitAt(0));
    final gm = res.getGlyphByCode(c.codeUnitAt(0));
    print('char $c textGlyph=${g == null ? "null" : "w=${g.width}"} '
        'musicGlyph=${gm == null ? "null" : "found"}');
  }
}
