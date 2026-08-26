/// Structural validation of the IO filters against the C++ reference
/// binary.
///
/// Usage (after generating the C++ MEI conversion with the reference CLI):
///
///   build/verovio -r assets/data -t mei -o /tmp/out.mei file.musicxml
///   dart run tool/validate_io.dart musicxml file.musicxml /tmp/out.mei
///   dart run tool/validate_io.dart abc file.abc /tmp/out.mei
///
/// Compares the histogram of element types produced by the Dart importer
/// with the element tags present in the C++-converted MEI.
library;

import 'dart:io';

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/iobase.dart';
import 'package:verovio_dart/src/io/ioabc.dart';
import 'package:verovio_dart/src/io/iomusxml.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/object.dart' as model;

Map<String, int> histogram(model.Object root) {
  final Map<String, int> counts = {};
  void walk(model.Object o) {
    counts[o.className] = (counts[o.className] ?? 0) + 1;
    for (final model.Object c in o.children) {
      walk(c);
    }
  }

  walk(root);
  return counts;
}

void main(List<String> args) {
  registerModelClasses();
  logLevel = LogLevel.error;

  final String kind = args[0];
  final String inputPath = args[1];
  final String cppMeiPath = args[2];

  final Doc doc = Doc();
  Input? input;
  if (kind == 'musicxml') {
    input = MusicXmlInput(doc);
  } else if (kind == 'abc') {
    input = AbcInput(doc);
  } else {
    stderr.write('Unknown format $kind (use musicxml or abc)\n');
    exit(2);
  }

  final bool ok = input.import(File(inputPath).readAsStringSync());
  print('import: $ok');
  if (!ok) exit(1);

  final Map<String, int> ours = histogram(doc)..remove('body');
  // Include the Score's owned scoreDef subtrees (not part of the tree).
  for (final Object scoreObj in doc.findAllDescendantsByType(ClassId.score)) {
    final dynamic subtree = (scoreObj as dynamic).scoreDefSubtree;
    if (subtree != null) {
      histogram(subtree as model.Object).forEach((k, v) {
        ours[k] = (ours[k] ?? 0) + v;
      });
    }
  }

  // Count element names in the C++-converted MEI. Note: isAttribute children
  // are serialized by the C++ as attributes on the parent element, so small
  // differences for keySig etc. are expected and benign.
  final RegExp re = RegExp(r'<([a-zA-Z][\w]*)[ />]');
  final Map<String, int> theirs = {};
  for (final RegExpMatch m in re.allMatches(File(cppMeiPath).readAsStringSync())) {
    final String name = m.group(1)!;
    theirs[name] = (theirs[name] ?? 0) + 1;
  }

  const List<String> interesting = [
    'note', 'rest', 'measure', 'staff', 'layer', 'slur', 'tie', 'clef',
    'keySig', 'meterSig', 'beam', 'chord', 'mRest', 'space', 'accid',
    'artic', 'dot', 'dir', 'dynam', 'tempo', 'hairpin', 'fermata', 'pedal',
    'barLine', 'verse', 'syl',
  ];
  int mismatches = 0;
  final List<String> keys = ({...ours.keys, ...theirs.keys}
        ..retainWhere(interesting.contains))
      .toList()
    ..sort();
  for (final String k in keys) {
    final int a = ours[k] ?? 0;
    final int b = theirs[k] ?? 0;
    if (a != b) {
      mismatches++;
      print('DIFF $k: dart=$a cpp=$b');
    } else {
      print('OK   $k: $a');
    }
  }
  print('mismatches=$mismatches');
  exit(mismatches == 0 ? 0 : 1);
}
