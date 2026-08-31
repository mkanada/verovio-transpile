import 'dart:io';
import 'package:verovio_dart/src/testing/svg_compare.dart';
void main(List<String> args) {
  final svg = renderSvgForComparison(args[0]);
  File('/tmp/opencode/dart_out.svg').writeAsStringSync(svg ?? 'NULL');
}
