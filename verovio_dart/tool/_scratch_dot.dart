import 'dart:io';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/toolkit.dart';
import 'package:verovio_dart/src/factory_registry.dart';

void main() {
  registerModelClasses();
  model.Object.seedID(12345);
  Resources.defaultPath = 'assets/data';
  const path = 'test/corpus/dot/dot-004.mei';
  final data = File(path).readAsStringSync();
  final tk = Toolkit();
  print('load=${tk.loadData(data)}');
  final dynamic doc = tk.doc;
  doc.prepareData();
  doc.castOffDoc();
  print('unit100=${doc.getDrawingUnit(100)}');
  final List<Object> all = doc.findAllDescendantsByType(ClassId.dots, deepness: 100);
  print('dotsCount=${all.length}');
  for (final dynamic d in all) {
    try {
      final dynamic note = d.parent;
      final dynamic stem = (note as dynamic).getDrawingStem();
      print('dots xRel=${d.drawingXRel} x=${d.getDrawingX()} '
          'flagShift=${d.flagShift} '
          'note=${note.id} nx=${note.getDrawingX()} '
          'radius=${note.getDrawingRadius(doc)} '
          'stemDir=${note.getDrawingStemDir()} '
          'stemLen=${stem?.getDrawingStemLen()} '
          'dur=${note.getActualDur()}');
    } catch (e) {
      print('ERR $e');
    }
  }
}
