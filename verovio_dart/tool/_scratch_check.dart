import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/object.dart';

void main(List<String> args) {
  registerModelClasses();
  logLevel = LogLevel.error;
  for (final String path in args) {
    final file = File(path);
    final doc = Doc();
    final data = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
    final bool ok = MeiInput(doc).import(data);
    if (!ok) {
      stdout.writeln('$path: import FAILED');
      continue;
    }
    doc.getOptions().breaks.setValue(Breaks.auto);
    String status;
    try {
      doc.prepareData();
      doc.layOut(hasEncodedBreaks: false);
      int systems = 0;
      int measures = 0;
      final pages = doc.getPages();
      if (pages != null) {
        for (int i = 0; i < pages.childCount; ++i) {
          final page = pages.getChild(i)!;
          systems += page.getChildCount(ClassId.system).toInt();
          for (final Object child in page.children) {
            measures +=
                (child as dynamic).findAllDescendantsByType(ClassId.measure).length as int;
          }
        }
      }
      status = 'OK pages=${doc.getPageCount()} systems=$systems measures=$measures';
    } catch (e) {
      status = 'CRASH $e';
    }
    stdout.writeln('$path: $status');
  }
}
