/// [scratch] Distribuição de primeiras divergências estruturais em todo o
/// corpus, agrupadas por padrão normalizado. Uso:
///   dart run tool/_scratch_firstdiv.dart
library;

import 'dart:io';

import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/svg_device_context.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/testing/svg_compare.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;

String? renderSvg(String meiPath) {
  Resources.defaultPath = 'assets/data';
  final file = File(meiPath);
  final data = file.readAsStringSync();
  final toolkit = Toolkit();
  final ok = toolkit.loadData(data);
  if (!ok) return null;
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.setDrawingPage(0);
  doc.getResourcesForModification().initFonts();
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);
  final dc = SvgDeviceContext('docid');
  dc.setResources(doc.getResources());
  dc.width = doc.getOptions().pageWidth.unfactoredValue;
  dc.height = doc.getOptions().pageHeight.unfactoredValue;
  view.drawCurrentPage(dc, false);
  return dc.getStringSVG();
}

void main() async {
  final files = <File>[];
  final root = Directory('test/corpus');
  await for (final e in root.list(recursive: true)) {
    if (e is File && e.path.endsWith('.mei')) files.add(e);
  }
  files.sort((a, b) => a.path.compareTo(b.path));

  final Map<String, List<String>> patterns = {};
  var clean = 0, failed = 0, noGolden = 0;

  for (final f in files) {
    final golden = File(
        f.path.replaceFirst('test/corpus/', 'test/golden/cpp/').replaceFirst('.mei', '.svg'));
    if (!golden.existsSync()) {
      noGolden++;
      continue;
    }
    String? svg;
    try {
      svg = renderSvg(f.path);
    } catch (_) {
      failed++;
      continue;
    }
    if (svg == null) {
      failed++;
      continue;
    }
    final comparator = SvgComparator();
    final result = comparator.compare(dartSvg: svg, goldenSvg: golden.readAsStringSync(), runNumeric: false);
    final divs = result.structuralDivergences;
    if (divs.isEmpty) {
      clean++;
      continue;
    }
    final first = divs.first;
    String norm =
        '${first.path}: esperado [${first.expected}], obtido [${first.actual}]';
    norm = norm.replaceAllMapped(RegExp(r'\[\d+\]'), (_) => '[N]');
    norm = norm.replaceAll(RegExp(r'\d+\.\d+'), '<num>');
    patterns.putIfAbsent(norm, () => []).add(f.path.split('/').last);
  }

  stdout.writeln('limpos=$clean falhas=$failed semGolden=$noGolden');
  final sorted = patterns.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (final e in sorted.take(30)) {
    stdout.writeln('${e.value.length.toString().padLeft(4)}  ${e.key}');
    stdout.writeln('       ex.: ${e.value.take(3).join(", ")}');
  }
}
