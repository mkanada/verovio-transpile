import 'dart:io';
import 'package:verovio_dart/src/testing/svg_compare.dart';
void main(){
  var svg = renderSvgForComparison('test/corpus/ossia/ossia-002.mei');
  File('/tmp/dart_ossia.svg').writeAsStringSync(svg!);
  print('written len ${svg.length}');
}
