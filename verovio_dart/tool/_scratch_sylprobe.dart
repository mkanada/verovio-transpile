import 'dart:io';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';
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
  var sysIdx = 0;
  final systems = page.findAllDescendantsByType(ClassId.system, deepness: 1);
  for (final system in systems) {
    final sys = system as System;
    final list = sys.getDrawingList();
    final syls = list.where((o) => o.isClass(ClassId.syl)).toList();
    stdout.writeln('system[$sysIdx]: drawingList=${list.length} syls=${syls.length}');
    for (final s in syls.take(3)) {
      final syl = s as Syl;
      stdout.writeln('  syl con=${syl.con} start=${syl.getStart()} end=${syl.getEnd()} '
          'nextWord=${syl.nextWordSyl != null} selfBB=${syl.hasSelfBB()} '
          'contentHBB=${syl.hasContentHorizontalBB()} contentBB=${syl.hasContentBB()} '
          'cl=${syl.getContentLeft()} cr=${syl.getContentRight()}');
    }
    sysIdx++;
  }
}
