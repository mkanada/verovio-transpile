import 'dart:io';
import 'package:verovio_dart/src/testing/svg_compare.dart';

void main(List<String> args) {
  for (final rel in args) {
    final mei = 'test/corpus/$rel';
    final golden = 'test/golden/cpp/${rel.replaceAll('.mei', '.svg')}';
    final dartSvg = renderSvgForComparison(mei);
    final r = SvgComparator(epsilon: 0, maxStoredDivergences: 200)
        .compare(dartSvg: dartSvg, goldenSvg: File(golden).readAsStringSync());
    print('=== $rel (${r.structuralDivergenceCount})');
    for (final d in r.structuralDivergences) {
      print('  $d');
    }
  }
}
