import 'dart:io';
import 'dart:convert';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/testing/draw_recorder.dart';
import 'package:verovio_dart/src/toolkit.dart';
import 'package:verovio_dart/src/core/options_shell.dart';
void main(){
  Resources.defaultPath = 'assets/data';
  final data = File('test/corpus/dynam/dynam-001.mei').readAsStringSync();
  final tk = Toolkit();
  tk.loadData(data);
  tk.doc.getOptions().breaks.setValue(Breaks.auto);
  tk.doc.prepareData();
  tk.doc.castOffDoc();
  tk.doc.setDrawingPage(0);
  tk.doc.getResourcesForModification().initFonts();
  final view = View()..setDoc(tk.doc);
  view.setPage(tk.doc.drawingPage!, true);
  final dc = DrawRecorder(docId: 'docid');
  dc.setResources(tk.doc.getResources());
  dc.width = tk.doc.getOptions().pageWidth.unfactoredValue;
  dc.height = tk.doc.getOptions().pageHeight.unfactoredValue;
  view.drawCurrentPage(dc, false);
  print(dc.records.length);
  final c = dc.records.where((r)=>r['fn']=='DrawSmuflCode').length;
  print('drawsmufl dart $c');
  for (var r in dc.records.where((r)=>r['path'].toString().contains('dynam')).take(10)) print(jsonEncode(r));
}
