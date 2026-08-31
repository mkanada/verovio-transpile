import 'dart:io';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Layer, Note;
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
    if (o is Beam) {
      final Layer? beamLayer = o.getFirstAncestor(ClassId.layer) as Layer?;
      final coords = o.beamSegment.beamElementCoordRefs;
      final dir = (beamLayer != null && coords.isNotEmpty)
          ? beamLayer.getDrawingStemDirForBeamCoords(coords)
          : null;
      stdout.writeln('beam place=${o.place} drawingPlace=${o.drawingPlace} '
          'weighted=${o.beamSegment.weightedPlace} '
          'ledgerAbove=${o.beamSegment.ledgerLinesAbove} ledgerBelow=${o.beamSegment.ledgerLinesBelow} '
          'notesStemDir=${o.notesStemDir} multiple=${o.hasMultipleStemDir} '
          'layerStemDirViaCoords=$dir layer.drawingStemDir=${beamLayer?.drawingStemDir}');
    }
    if (o is Artic) {
      final layer = o.getFirstAncestor(ClassId.layer) as Layer?;
      final note = o.getFirstAncestor(ClassId.note);
      final layerStemDir =
          (layer != null && note is LayerElement) ? layer.getDrawingStemDirFor(note) : null;
      stdout.writeln('artic place=${o.place} drawingPlace=${o.drawingPlace} '
          'layerStemDir=$layerStemDir '
          'noteStemDir=${note is Note ? note.getDrawingStemDir() : null}');
    }
    for (final c in o.children) {
      walk(c);
    }
  }

  for (final c in doc.children) {
    walk(c);
  }
}
