import 'dart:io';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Measure;
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/toolkit.dart';

void main(List<String> args) {
  Resources.defaultPath = 'assets/data';
  final data = File(args[0]).readAsStringSync();
  final toolkit = Toolkit();
  toolkit.loadData(data);
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.castOffDoc();
  doc.setDrawingPage(0);
  var n = 0;
  void walk(model.Object o) {
    if (o is Measure) {
      n++;
      if (n < 8) stdout.writeln('measure n=${o.n} index=${o.index} id=${o.id}');
    }
    for (final c in o.children) {
      walk(c);
    }
  }
  for (final c in doc.children) {
    walk(c);
  }
  stdout.writeln('total measures: $n');
}
