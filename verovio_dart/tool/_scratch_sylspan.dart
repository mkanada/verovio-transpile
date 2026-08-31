import 'dart:io';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show System;
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/svg_device_context.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/toolkit.dart';

void main(List<String> args) {
  Resources.defaultPath = 'assets/data';
  final data = File(args[0]).readAsStringSync();
  final toolkit = Toolkit();
  if (!toolkit.loadData(data)) {
    stdout.writeln('load failed');
    return;
  }
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.castOffDoc();
  doc.setDrawingPage(0);
  doc.getResourcesForModification().initFonts();
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);
  final dc = SvgDeviceContext('docid');
  dc.setResources(doc.getResources());
  dc.width = doc.getOptions().pageWidth.unfactoredValue;
  dc.height = doc.getOptions().pageHeight.unfactoredValue;
  view.drawCurrentPage(dc, false);

  final page = doc.drawingPage!;
  final systems = page.findAllDescendantsByType(ClassId.system, deepness: 1);
  var idx = 0;
  for (final system in systems) {
    final sys = system as System;
    final list = sys.getDrawingList();
    for (final o in list) {
      if (o is! Syl) continue;
      final syl = o;
      final start = syl.getStart();
      final end = syl.getEnd();
      final startSys = start?.getFirstAncestor(ClassId.system);
      final endSys = end?.getFirstAncestor(ClassId.system);
      // which system does this drawing pass belong to
      String type;
      if (identical(sys, startSys) && identical(sys, endSys)) {
        type = 'START_END';
      } else if (identical(sys, startSys)) {
        type = 'START';
      } else if (identical(sys, endSys)) {
        type = 'END';
      } else {
        type = 'MIDDLE';
      }
      final int x1 = syl.getContentRight();
      final int x2 = syl.nextWordSyl?.getContentLeft() ?? -999999;
      final int dashLength = syl.calcHyphenLength(doc, 100);
      stdout.writeln(
          'syl[$idx] id=${syl.id} con=${syl.con} wordpos=${syl.wordpos} span=$type '
          'nextWord=${syl.nextWordSyl != null} '
          'contentH=${syl.hasContentHorizontalBB()} '
          'nextH=${syl.nextWordSyl?.hasContentHorizontalBB()} '
          'x1=$x1 x2=$x2 dist=${x2 - x1} dashLen=$dashLength '
          'startSysNull=${startSys == null} endSysNull=${endSys == null}');
      idx++;
    }
  }

  // Dump the rendered SVG from the SAME process so ids match the probe.
  final svg = dc.getStringSVG();
  File('/tmp/opencode/dart_out.svg').writeAsStringSync(svg);
}
