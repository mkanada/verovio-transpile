import 'dart:io';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/toolkit.dart';

void main(List<String> args) {
  Resources.defaultPath = 'assets/data';
  final data = File(args[0]).readAsStringSync();
  final toolkit = Toolkit();
  if (!toolkit.loadData(data)) {
    stdout.writeln('load failed');
    return;
  }
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();

  final syls = <Syl>[];
  void walk(model.Object o) {
    if (o is Syl) syls.add(o);
    for (final c in o.children) {
      walk(c);
    }
  }

  for (final c in doc.children) {
    walk(c);
  }
  stdout.writeln('syls=${syls.length}');
  var withStart = 0, withEnd = 0, both = 0;
  for (final s in syls) {
    if (s.getStart() != null) withStart++;
    if (s.getEnd() != null) withEnd++;
    if (s.getStart() != null && s.getEnd() != null) both++;
  }
  stdout.writeln('withStart=$withStart withEnd=$withEnd both=$both');
  for (final s in syls.take(5)) {
    stdout.writeln('  con=${s.con} wordpos=${s.wordpos} '
        'start=${s.getStart()?.className}:${s.getStart()?.id} '
        'end=${s.getEnd()?.className}:${s.getEnd()?.id} '
        'nextWord=${s.nextWordSyl?.id}');
  }
}
