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

  test('svg golden: baseline honesta 0/10 estrutural', () {
    var clean = 0;
    for (final meiPath in kBaselineSubset) {
      String? dartSvg;
      try {
        dartSvg = renderSvgForComparison(meiPath);
      } catch (_) {
        continue;
      }
      if (dartSvg == null) continue;
      final golden = File(goldenPathFor(meiPath)).readAsStringSync();
      final result =
          SvgComparator().compare(dartSvg: dartSvg, goldenSvg: golden);
      if (result.structuralClean) clean++;
    }
    // 05-26: baseline honesta sem bridges — 0/10 limpos, 0/623 limpos.
    // Harness honesto reporta 0/623 estrutural, 618 divergentes, 3 falhas, 2 pulados.
    expect(clean, equals(0), reason: 'baseline honesta 0/10, obtido $clean/10');
  });

  test('svg golden: baseline honesta --all 0/623', () {
    final report = File('tool/SVG_VALIDATION.md').readAsStringSync();
    expect(report, contains('0/623 limpos'));
    expect(report, contains('618'));
    expect(report, contains('Falhas'));
  });
}
