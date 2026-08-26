import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';

void main(List<String> args) {
  registerModelClasses();
  logLevel = LogLevel.error;
  final doc = Doc();
  final data = File(args.first).readAsStringSync();
  MeiInput(doc).import(data);
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.layOut(hasEncodedBreaks: false);
  doc.calculateTimemap();

  final dynamic cpp = jsonDecode(File(args[1]).readAsStringSync());
  final Map<String, double> onsets = {};
  for (final dynamic entry in cpp as List) {
    final double q = (entry['qstamp'] as num).toDouble();
    for (final dynamic id in ((entry['on'] as List?) ?? <dynamic>[])) {
      onsets.putIfAbsent(id as String, () => q);
    }
  }
  for (final Object object in doc.findAllDescendantsByType(ClassId.note)) {
    final Note note = object as Note;
    final DurationInterface di = note;
    final Object? measure = note.getFirstAncestor(ClassId.measure);
    final double measureOnset =
        measure is Measure ? measure.getScoreTimeOnset().toDouble() : 0.0;
    final double onset = measureOnset + di.scoreTimeOnset.toDouble();
    final String id = note.id;
    stdout.writeln('$id ours=$onset cpp=${onsets[id]}'
        '${onsets.containsKey(id) && (onsets[id]! - onset).abs() > 0.01 ? " MISMATCH" : ""}'
        '${!onsets.containsKey(id) ? " not-in-cpp" : ""}');
  }
}
