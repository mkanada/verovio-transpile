import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;

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
  print('nbLayers=${measure.getDescendantCount(ClassId.layer)}');
  for (final Object child in measure.measureAligner.children) {
    final Alignment alignment = child as Alignment;
    final List<String> refDesc = [];
    for (final Object ref in alignment.children) {
      refDesc.add(ref.children.map((e) => e.className).join(','));
    }
    print(
        'type=${alignment.getType()} childCount=${alignment.childCount} '
        'time=${alignment.getTime().toDouble()} refs=$refDesc');
  }
}
