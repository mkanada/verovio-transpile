import 'dart:io';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Layer;
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/rendering/resources.dart';
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

  void walk(model.Object o) {
    if (o is MeterSig) {
      stdout.writeln('meterSig id=${o.id} count=${o.count} enclose=${o.enclose} '
          'unit=${o.unit} parent=${o.parent?.className}');
    }
    if (o is Layer) {
      final ms = o.staffDefMeterSig;
      if (ms != null) {
        stdout.writeln('LAYER staffDefMeterSig: count=${ms.count} enclose=${ms.enclose} unit=${ms.unit}');
      }
      final grp = o.staffDefMeterSigGrp;
      if (grp != null) {
        stdout.writeln('LAYER grp children=${grp.children.length} '
            '${grp.children.map((c) => (c as MeterSig).count?.counts).toList()}');
      }
    }
    for (final c in o.children) {
      walk(c);
    }
  }

  for (final c in doc.children) {
    walk(c);
  }
}
