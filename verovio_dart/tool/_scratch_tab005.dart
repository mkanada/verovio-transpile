import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/model/scoredef.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;

void main() {
  Resources.defaultPath = 'assets/data';
  const meiPath = 'test/corpus/tab/tab-005.mei';
  final data = File(meiPath).readAsStringSync();
  final toolkit = Toolkit();
  final ok = toolkit.loadData(data);
  if (!ok) throw StateError('loadData falhou');
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.setDrawingPage(0);
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);
  print('pageContentHeight=${doc.drawingPageContentHeight}');
  print('pageWidth=${doc.drawingPageWidth}');
  final page = doc.drawingPage!;
  for (final child in page.children) {
    if (child is System) {
      print('system drawingX=${child.getDrawingX()} drawingY=${child.getDrawingY()}');
      // find first measure staves
      final meas = child.findDescendantByType(ClassId.measure, deepness: 1);
      print('firstMeasure=$meas');
      if (meas != null) {
        for (final s in meas.children.whereType<Staff>()) {
          print('  staff n=${s.n} drawingX=${s.getDrawingX()} drawingY=${s.getDrawingY()} '
              'staffSize=${s.drawingStaffSize} lines=?');
        }
      }
      final sd = child.drawingScoreDef;
      if (sd != null) {
        final sg = sd.findDescendantByType(ClassId.staffGrp);
        print('staffGrp=$sg');
        if (sg is StaffGrp) {
          final fl = sg.getFirstLastStaffDef();
          print('firstDef n=${fl.$1?.n} lines=${fl.$1?.lines} '
              'lastDef n=${fl.$2?.n} lines=${fl.$2?.lines} maxStaffSize=${sg.getMaxStaffSize()}');
        }
        print('hasSystemStartLine=${(sd as ScoreDef).hasSystemStartLine()}');
      }
    }
  }
  print('barLineWidth(100)=${doc.getDrawingBarLineWidth(100)}');
  print('doubleUnit(100)=${doc.getDrawingDoubleUnit(100)}');
  // labels width path: find system, print leftMar + labelsWidth
  for (final child in page.children) {
    if (child is System) {
      print('systemLeftMar=${child.systemLeftMar} labelsWidth=${child.getDrawingLabelsWidth()} '
          'sum=${child.systemLeftMar + child.getDrawingLabelsWidth()}');
      final sd = child.drawingScoreDef;
      if (sd != null) {
        // dump label content boxes
        void walk(model.Object o, String indent) {
          final n = o.classId.toString().split('.').last;
          if (n == 'label' || n == 'text' || n == 'labelAbbr') {
            print('$indent$n contentX1=${o.getContentX1()} contentX2=${o.getContentX2()}');
          }
          for (final c in o.children) {
            if (c is model.Object) walk(c, '$indent  ');
          }
        }
        walk(sd, '');
      }
    }
  }
}
