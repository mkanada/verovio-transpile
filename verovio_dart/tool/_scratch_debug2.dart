import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/doc.dart';

void main(List<String> args) {
  registerModelClasses();
  logLevel = LogLevel.error;
  final file = File(args.first);
  final doc = Doc();
  final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  MeiInput(doc).import(data);
  doc.prepareData();
  doc.convertToCastOffMensuralDoc(MensuralCastOffType.init);
  final pages = doc.getPages();
  int measures = 0;
  for (int i = 0; i < pages!.childCount; ++i) {
    final page = pages.getChild(i)!;
    measures += page.findAllDescendantsByType(ClassId.measure).length;
    print('page $i systems=${page.getChildCount(ClassId.system)}');
  }
  print('measures=$measures');
}
