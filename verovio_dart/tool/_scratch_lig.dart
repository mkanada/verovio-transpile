import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart' hide Object;
import 'package:verovio_dart/src/model/object.dart';

void main(List<String> args) {
  registerModelClasses();
  logLevel = LogLevel.error;
  final file = File(args.first);
  final doc = Doc();
  final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  MeiInput(doc).import(data);
  doc.prepareData();
  doc.layOut(hasEncodedBreaks: false);

  final List<Object> ligatures = doc.findAllDescendantsByType(ClassId.ligature);
  stdout.writeln('ligatures=${ligatures.length}');
  if (ligatures.isNotEmpty) {
    final Ligature lig = ligatures.first as Ligature;
    final List<Object> notes = lig.getList();
    for (final Object n in notes) {
      final dynamic note = n;
      stdout.writeln('note shapes=${lig.getDrawingNoteShape(n)} '
          'xRel=${note.drawingXRel}');
    }
    stdout.writeln('shapes=${lig.drawingShapes}');
  }

  final List<Object> neumes = doc.findAllDescendantsByType(ClassId.neume);
  stdout.writeln('neumes=${neumes.length}');
  int ncCount = 0;
  int glyphed = 0;
  for (final Object neumeObject in neumes) {
    final List<Object> ncs =
        (neumeObject as dynamic).findAllDescendantsByType(ClassId.nc) as List<Object>;
    for (final Object ncObject in ncs) {
      final Nc nc = ncObject as Nc;
      ++ncCount;
      if (nc.drawingGlyphs.isNotEmpty && nc.drawingGlyphs[0].fontNo != 0) {
        ++glyphed;
      }
    }
  }
  stdout.writeln('ncs=$ncCount withGlyph=$glyphed');
}
