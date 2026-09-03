import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;

void main() {
  Resources.defaultPath = 'assets/data';
  final data = File('test/corpus/tab/tab-005.mei').readAsStringSync();
  final toolkit = Toolkit();
  toolkit.loadData(data);
  final doc = toolkit.doc;
  final Map<String, int> counts = {};
  void walk(model.Object o) {
    final n = o.classId.toString().split('.').last;
    counts[n] = (counts[n] ?? 0) + 1;
    if (n == 'label' || n == 'labelAbbr') {
      print('LABEL node: runtimeType=${o.runtimeType} children=${o.children.length}');
      for (final c in o.children) {
        if (c is model.Object) {
          print('   child: ${c.runtimeType} classId=${c.classId}');
        } else {
          print('   child(non-model): ${c.runtimeType}');
        }
      }
    }
    for (final c in o.children) {
      if (c is model.Object) walk(c);
    }
  }
  walk(doc);
  final keys = counts.keys.toList()..sort();
  for (final k in keys) {
    print('$k: ${counts[k]}');
  }
}
