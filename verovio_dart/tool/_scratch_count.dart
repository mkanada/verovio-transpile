import 'dart:io';
import 'package:xml/xml.dart';

void main(List<String> args) {
  final p1 = '/home/mauricio/rust_projects/verovio-transpile/verovio_dart/test/golden/cpp/ossia/ossia-002.svg';
  final p2 = '/home/mauricio/rust_projects/verovio-transpile/verovio_dart/test/golden/dart/ossia/ossia-002.svg';
  final f1 = File(p1).readAsStringSync();
  final f2 = File(p2).readAsStringSync();
  final doc1 = XmlDocument.parse(f1);
  final doc2 = XmlDocument.parse(f2);
  final root1 = doc1.findAllElements('svg').first;
  final root2 = doc2.findAllElements('svg').first;
  // svg[0] is the inner svg
  final inner1 = root1.findElements('svg').first;
  final inner2 = root2.findElements('svg').first;
  // g[0] is first g in inner
  final g1 = inner1.findElements('g').first;
  final g2 = inner2.findElements('g').first;
  final kids1 = g1.childElements.toList();
  final kids2 = g2.childElements.toList();
  print('g[0] (page-margin) child elements:');
  print('  C++: ${kids1.length}');
  for (var i = 0; i < kids1.length; i++) {
    final k = kids1[i];
    final c = k.getAttribute('class') ?? '';
    final id = k.getAttribute('id') ?? '';
    print('    [$i] class="$c" id="$id"');
  }
  print('  Dart: ${kids2.length}');
  for (var i = 0; i < kids2.length; i++) {
    final k = kids2[i];
    final c = k.getAttribute('class') ?? '';
    final id = k.getAttribute('id') ?? '';
    print('    [$i] class="$c" id="$id"');
  }
}
