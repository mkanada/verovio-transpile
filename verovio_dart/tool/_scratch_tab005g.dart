import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/test/fixtures/cpp_fixture.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/rendering/view.dart';

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
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);

  final fixture = CppFixture.load('05-38', meiPath);
  // Build path -> alignment xRel map from Dart side: walk measures/aligners?
  // Simpler: dump fixture CalcAlignmentXPos outs and Dart equivalents via
  // measure aligner traversal is complex; instead compare AdjustXPos xRel_out
  // for a few key elements using cppPath.
  final adj = fixture.records
      .where((r) => r['fn'] == 'AdjustXPos')
      .toList();
  print('AdjustXPos records: ${adj.length}');
  // print last few (right side of measure)
  for (final r in adj.skip(adj.length - 10)) {
    print('${r['path']} staffN=${r['staffN']} xRel_out=${r['xRel_out']}');
  }
}
