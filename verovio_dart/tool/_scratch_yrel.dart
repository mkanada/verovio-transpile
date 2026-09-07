import 'dart:io';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/layout/vertical_aligner.dart' show StaffAlignment;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/toolkit.dart';

void main(List<String> args) {
  registerModelClasses();
  Resources.defaultPath = 'assets/data';
  final data = File(args[0]).readAsStringSync();
  final toolkit = Toolkit();
  toolkit.loadData(data);
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.castOffDoc();
  doc.setDrawingPage(0);
  doc.getResourcesForModification().initFonts();
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);
  final page = doc.drawingPage!;
  for (var i = 0; i < page.childCount; i++) {
    final c = page.getChild(i);
    if (c is! System) continue;
    final sys = c;
    final aligner = sys.systemAligner;
    for (var j = 0; j < aligner.childCount; j++) {
      final a = aligner.getChild(j) as StaffAlignment;
      // ignore: avoid_print
      print('sys[$i] align[$j] ${a.runtimeType} staffN=${a.getStaff()?.n} '
          'yRel=${a.getYRel()} minSpacing=${a.getMinimumSpacing(doc)} '
          'requestedSpacing=${a.getRequestedSpacing()}');
    }
  }
}
