import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/testing/draw_recorder.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;

// Full-stream diff: print first 12 divergences with field detail.
void main() {
  Resources.defaultPath = 'assets/data';
  const meiPath = 'test/corpus/tab/tab-005.mei';
  final data = File(meiPath).readAsStringSync();
  final toolkit = Toolkit();
  toolkit.loadData(data);
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.setDrawingPage(0);
  doc.getResourcesForModification().initFonts();
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);
  final dc = DrawRecorder(docId: 'docid');
  dc.setResources(doc.getResources());
  dc.width = doc.getOptions().pageWidth.unfactoredValue;
  dc.height = doc.getOptions().pageHeight.unfactoredValue;
  view.drawCurrentPage(dc, false);
  final dart = dc.records;

  const drawFns = {
    'StartGraphic', 'EndGraphic', 'ResumeGraphic', 'EndResumedGraphic',
    'RotateGraphic', 'StartText', 'EndText', 'DrawLine', 'DrawPolyline',
    'DrawPolygon', 'DrawRectangle', 'DrawRoundedRectangle', 'DrawText',
    'DrawSmuflCode', 'DrawSmuflString', 'DrawSmuflLine', 'DrawCurve',
    'DrawCircle', 'DrawEllipse',
  };
  final cpp = <Map<String, Object?>>[];
  for (final line in const LineSplitter().convert(
      File('test/fixtures/cpp/05-38/tab/tab-005.mei.jsonl').readAsStringSync())) {
    if (line.trim().isEmpty) continue;
    final m = (jsonDecode(line) as Map).cast<String, Object?>();
    if (m.containsKey('_meta')) continue;
    if (!drawFns.contains(m['fn'])) continue;
    cpp.add(m);
  }
  print('cpp=${cpp.length} dart=${dart.length}');
  int shown = 0;
  final n = cpp.length < dart.length ? cpp.length : dart.length;
  for (var i = 0; i < n && shown < 12; i++) {
    final c = cpp[i], d = dart[i];
    if (c['fn'] != d['fn'] || c['path'] != d['path']) {
      print('seq?={i+1} FNMISMATCH cpp=${c['fn']} ${c['path']} '
          'dart=${d['fn']} ${d['path']}');
      shown++;
      continue;
    }
    final diffs = <String>[];
    for (final k in c.keys) {
      if (k == 'fn' || k == 'seq' || k == 'path' || k == 'id') continue;
      final e = c[k], o = d[k];
      if (e is num && o is num) {
        if ((e - o).abs() > 1e-9) diffs.add('$k: $e vs $o');
      } else if (e != o) {
        diffs.add('$k: $e vs $o');
      }
    }
    if (diffs.isNotEmpty) {
      print('seq=${c['seq']} fn=${c['fn']} path=${c['path']}');
      for (final x in diffs) {
        print('   $x');
      }
      shown++;
    }
  }
}
