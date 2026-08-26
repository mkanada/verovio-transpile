import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/object.dart';

void main(List<String> args) {
  registerModelClasses();
  logLevel = LogLevel.error;
  final file = File(args.first);
  final doc = Doc();
  final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  MeiInput(doc).import(data);
  doc.prepareData();
  doc.calculateTimemap();

  final List<Object> notes =
      doc.findAllDescendantsByType(ClassId.note);
  final Set<String> onsets = {};
  for (final Object object in notes) {
    final DurationInterface note = object as DurationInterface;
    onsets.add(note.scoreTimeOnset.toDouble().toStringAsFixed(4));
    // also offsets
    onsets.add('off:${note.scoreTimeOffset.toDouble().toStringAsFixed(4)}');
  }
  final sorted = onsets.where((s) => !s.startsWith('off')).map(double.parse).toList()..sort();
  stdout.writeln('distinct onsets (${sorted.length}): ${sorted.take(20)}');
}
