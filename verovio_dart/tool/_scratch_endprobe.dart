import 'dart:io';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/core/vrvdef.dart';
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
  final systems = page.findAllDescendantsByType(ClassId.system, deepness: 1);
  var si = 0;
  for (final system in systems) {
    final sys = system as System;
    final list = sys.getDrawingList();
    final endings = list.where((o) => o.isClass(ClassId.ending)).toList();
    stdout.writeln('system[$si]: drawingList=${list.length} endings=${endings.length}');
    final seen = <String, int>{};
    for (final e in endings) {
      seen[e.id] = (seen[e.id] ?? 0) + 1;
    }
    stdout.writeln('  ids: ${seen.entries.map((k) => '${k.key}x${k.value}').join(', ')}');
    si++;
  }
}
