import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/testing/svg_compare.dart';

/// Ten files, one per family (task 05-00): note, beam, slur, chord, rest,
/// clef, accid, tuplet, lyric, measure.
const List<String> kBaselineSubset = [
  'test/corpus/note/note-001.mei',
  'test/corpus/beam/beam-001.mei',
  'test/corpus/slur/slur-001.mei',
  'test/corpus/chord/chord-001.mei',
  'test/corpus/rest/rest-001.mei',
  'test/corpus/clef/clef-001.mei',
  'test/corpus/accid/accid-001.mei',
  'test/corpus/tuplet/tuplet-001.mei',
  'test/corpus/lyric/lyric-001.mei',
  'test/corpus/measure/measure-001.mei',
];

String goldenPathFor(String meiPath) => meiPath
    .replaceFirst('test/corpus/', 'test/golden/cpp/')
    .replaceFirst('.mei', '.svg');

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  test('svg golden: baseline estrutural do subconjunto fixo', () {
    var clean = 0;
    for (final meiPath in kBaselineSubset) {
      final dartSvg = renderSvgForComparison(meiPath);
      if (dartSvg == null) continue; // no rendering yet (Phase-5 stub)
      final golden = File(goldenPathFor(meiPath)).readAsStringSync();
      final result =
          SvgComparator().compare(dartSvg: dartSvg, goldenSvg: golden);
      if (result.structuralClean) clean++;
    }
    // TASK 05-00 BASELINE: this number may only go up. While
    // `renderSvgForComparison` is a stub it stays 0; each following Phase-5
    // task that turns files structurally clean raises this expectation.
    expect(clean, 0);
  });

  test('svg golden: o comparador é limpo contra si mesmo', () {
    // Guard against comparator regressions: a golden compared with itself
    // must be clean in both modes (proof required by task 05-00).
    final golden = File('test/golden/cpp/note/note-001.svg').readAsStringSync();
    final result = SvgComparator().compare(dartSvg: golden, goldenSvg: golden);
    expect(result.structuralDivergenceCount, 0,
        reason: result.structuralDivergences.join('\n'));
    expect(result.numericDivergenceCount, 0,
        reason: result.numericDivergences.join('\n'));
  });
}
