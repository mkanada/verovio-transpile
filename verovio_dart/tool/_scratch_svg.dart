import 'dart:io';
import 'package:verovio_dart/src/testing/svg_compare.dart';
void main(){
  final dartSvg = renderSvgForComparison('test/corpus/dynam/dynam-001.mei');
  final golden = File('test/golden/cpp/dynam/dynam-001.svg').readAsStringSync();
  final res = SvgComparator().compare(dartSvg: dartSvg, goldenSvg: golden);
  for (var d in res.structuralDivergences.take(20)) print(d);
  print('count ${res.structuralDivergenceCount}');
}
