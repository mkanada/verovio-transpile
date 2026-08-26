import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';

void main(List<String> args) {
  registerModelClasses();
  logLevel = LogLevel.error;
  final file = File(args.first);
  final doc = Doc();
  final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  MeiInput(doc).import(data);
  doc.prepareData();
  doc.scoreDefSetCurrentDoc();
  final page = doc.setDrawingPage(0)!;
  page.layOutHorizontally();
  final Measure measure = page.findDescendantByType(ClassId.measure) as Measure;
  final int nbLayers = measure.getDescendantCount(ClassId.layer);
  final List<String> lines = [];
  for (final Object child in measure.measureAligner.children) {
    final alignment = child as dynamic;
    if (alignment.getType() == AlignmentType.default_) {
      final String refs =
          alignment.children.map((e) => e.children.length).join('+');
      if (alignment.childCount >= 2) {
        lines.add(
            't=${alignment.getTime().toDouble()} refs=${alignment.childCount}');
      }
    }
  }
  stdout.writeln('nbLayers=$nbLayers');
  for (final line in lines) {
    stdout.writeln(line);
  }
}
