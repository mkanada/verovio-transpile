import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/testing/draw_recorder.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;

const Set<String> _drawingFns = {
  'StartGraphic','EndGraphic','ResumeGraphic','EndResumedGraphic','RotateGraphic',
  'StartText','EndText','DrawLine','DrawPolyline','DrawPolygon','DrawRectangle',
  'DrawRoundedRectangle','DrawText','DrawSmuflCode','DrawSmuflString','DrawSmuflLine',
  'DrawCurve','DrawCircle','DrawEllipse',
};

List<Map<String, Object?>> loadFixture(String path) {
  final content = File(path).readAsStringSync();
  final lines = const LineSplitter().convert(content).where((l)=>l.trim().isNotEmpty).toList();
  final out = <Map<String,Object?>>[];
  for (final line in lines) {
    final decoded = jsonDecode(line) as Map<String,dynamic>;
    if (decoded.containsKey('_meta')) continue;
    final fn = decoded['fn'] as String?;
    if (fn != null && !_drawingFns.contains(fn)) continue;
    out.add(decoded.cast<String,Object?>());
  }
  return out;
}

List<Map<String, Object?>> renderDart(String meiPath) {
  Resources.defaultPath = 'assets/data';
  final data = File(meiPath).readAsStringSync();
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
  final dc = DrawRecorder(docId: 'docid');
  dc.setResources(doc.getResources());
  dc.width = doc.getOptions().pageWidth.unfactoredValue;
  dc.height = doc.getOptions().pageHeight.unfactoredValue;
  view.drawCurrentPage(dc, false);
  return dc.records;
}

void main() {
  final cpp = loadFixture('test/fixtures/cpp/05-38/midi/005-maqam-rast-external-tuning.mei.jsonl');
  final dart = renderDart('test/corpus/midi/005-maqam-rast-external-tuning.mei');
  print('cpp len=${cpp.length} dart len=${dart.length}');
  int firstDiff = -1;
  for (var i = 0; i < cpp.length && i < dart.length; i++) {
    final c = cpp[i];
    final d = dart[i];
    final same = c['fn']==d['fn'] && c['path']==d['path'];
    if (!same) { firstDiff = i; break; }
  }
  print('firstDiff index = $firstDiff');
  if (firstDiff >= 0) {
    for (var i = (firstDiff-5).clamp(0,cpp.length); i < firstDiff+20 && i < cpp.length && i < dart.length; i++) {
      final c = cpp[i];
      final d = dart[i];
      final same = c['fn']==d['fn'] && c['path']==d['path'];
      print('[$i] ${same?"OK ":"XX "} cpp=${c['fn']}/${c['path']}  dart=${d['fn']}/${d['path']}');
    }
  }
}
