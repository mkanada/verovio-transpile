import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;

void main() {
  Resources.defaultPath = 'assets/data';
  final data = File('test/corpus/tab/tab-005.mei').readAsStringSync();
  final toolkit = Toolkit();
  toolkit.loadData(data);
  final doc = toolkit.doc;
  final sd = doc.findDescendantByType(ClassId.scoreDef, deepness: 10);
  print('scoreDef: $sd');
  if (sd is model.Object) {
    print('scoreDef children: ${sd.children.length}');
    for (final c in sd.children) {
      print('  ${(c as model.Object).classId}');
    }
    final labels = <model.Object>[];
    void walk(model.Object o) {
      if (o.classId == ClassId.label) labels.add(o);
      for (final c in o.children) {
        if (c is model.Object) walk(c);
      }
    }
    walk(sd);
    print('labels under scoreDef: ${labels.length}');
    for (final l in labels) {
      final kids = l.children.whereType<model.Object>().toList();
      print('label kids: ${kids.map((k) => k.classId).toList()}');
      for (final k in kids) {
        print('   kid runtime=${k.runtimeType}');
      }
    }
  }
}
