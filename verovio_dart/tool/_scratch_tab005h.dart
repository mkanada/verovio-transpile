import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/model/system_page_elements.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/rendering/view.dart';

void main() {
  Resources.defaultPath = 'assets/data';
  final data = File('test/corpus/tab/tab-005.mei').readAsStringSync();
  final toolkit = Toolkit();
  toolkit.loadData(data);
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.setDrawingPage(0);
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);
  final page = doc.drawingPage!;
  void walk(model.Object o) {
    if (o.classId == ClassId.measure) {
      final m = o as dynamic;
      print('measure drawingX=${m.getDrawingX()} width=${m.getWidth()}');
      final al = m.measureAligner as dynamic;
      print('  aligner RBalignXRel=${al.getRightBarLineAlignment()?.getXRel()} '
          'ENDxRel=${al.getRightAlignment()?.getXRel()}');
      final rb = m.rightBarLine as dynamic;
      print('  rightBarLine drawingX=${rb?.getDrawingX()} alignXRel=${rb?.getAlignment()?.getXRel()}');
      final lb = m.leftBarLine as dynamic;
      print('  leftBarLine drawingX=${lb?.getDrawingX()}');
    }
    if (o.classId == ClassId.system) {
      final s = o as System;
      print('system drawingX=${s.getDrawingX()}');
    }
    for (final c in o.children) {
      if (c is model.Object) walk(c);
    }
  }
  walk(page);
}
