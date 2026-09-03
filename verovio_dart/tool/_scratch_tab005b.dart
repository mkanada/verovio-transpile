import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/testing/draw_recorder.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;

void main() {
  Resources.defaultPath = 'assets/data';
  const meiPath = 'test/corpus/tab/tab-005.mei';
  final data = File(meiPath).readAsStringSync();
  final toolkit = Toolkit();
  toolkit.loadData(data);
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.setDrawingPage(0);
  doc.getResourcesForModification().initFonts();
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);
  final dc = DrawRecorder(docId: 'docid');
  dc.setResources(doc.getResources());
  dc.width = doc.getOptions().pageWidth.unfactoredValue;
  dc.height = doc.getOptions().pageHeight.unfactoredValue;
  view.drawCurrentPage(dc, false);
  for (final r in dc.records.take(50)) {
    final m = Map.of(r)..remove('id');
    print(m);
  }
}
