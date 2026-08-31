import 'dart:io';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/svg_device_context.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/testing/svg_compare.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;

void main(List<String> args) {
  final meiPath = args[0];
  Resources.defaultPath = 'assets/data';
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
  final dc = SvgDeviceContext('docid');
  dc.setResources(doc.getResources());
  dc.width = doc.getOptions().pageWidth.unfactoredValue;
  dc.height = doc.getOptions().pageHeight.unfactoredValue;
  view.drawCurrentPage(dc, false);
  final svg = dc.getStringSVG();
  final goldenPath = meiPath
      .replaceFirst('test/corpus/', 'test/golden/cpp/')
      .replaceFirst('.mei', '.svg');
  final golden = File(goldenPath).readAsStringSync();
  final comparator = SvgComparator(maxStoredDivergences: 40);
  final result = comparator.compare(dartSvg: svg, goldenSvg: golden, runNumeric: false);
  for (final d in result.structuralDivergences) {
    stdout.writeln('$meiPath: $d');
  }
}
