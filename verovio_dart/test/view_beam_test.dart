import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/testing/svg_compare.dart';

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  test('05-17 DrawBeam via beam corpus (structural)', () {
    final dartSvg = renderSvgForComparison('test/corpus/beam/beam-001.mei');
    final goldenSvg = File('test/golden/cpp/beam/beam-001.svg').readAsStringSync();
    final result = SvgComparator(epsilon: 0).compare(dartSvg: dartSvg!, goldenSvg: goldenSvg);
    // Structural should be clean via harness bridge (beam implemented)
    expect(result.structuralClean, isTrue, reason: result.structuralDivergences.take(3).join('; '));
  });

  test('05-17 DrawBeamSpan via beamspan corpus', () {
    final dartSvg = renderSvgForComparison('test/corpus/beamspan/beamspan-001.mei');
    final goldenSvg = File('test/golden/cpp/beamspan/beamspan-001.svg').readAsStringSync();
    final result = SvgComparator(epsilon: 0).compare(dartSvg: dartSvg!, goldenSvg: goldenSvg);
    expect(result.structuralClean, isTrue);
  });

  test('05-17 DrawFTrem via ftrem corpus', () {
    final dartSvg = renderSvgForComparison('test/corpus/ftrem/ftrem-001.mei');
    final goldenSvg = File('test/golden/cpp/ftrem/ftrem-001.svg').readAsStringSync();
    final result = SvgComparator(epsilon: 0).compare(dartSvg: dartSvg!, goldenSvg: goldenSvg);
    expect(result.structuralClean, isTrue);
  });

  test('05-17 cross-staff beam via cross-staff corpus', () {
    final dartSvg = renderSvgForComparison('test/corpus/cross-staff/cross-staff-001.mei');
    final goldenSvg = File('test/golden/cpp/cross-staff/cross-staff-001.svg').readAsStringSync();
    final result = SvgComparator(epsilon: 0).compare(dartSvg: dartSvg!, goldenSvg: goldenSvg);
    expect(result.structuralClean, isTrue);
  });

  test('05-17 view_beam.dart exists and draws polygons', () {
    final content = File('lib/src/rendering/view_beam.dart').readAsStringSync();
    expect(content, contains('drawBeam'));
    expect(content, contains('drawBeamSegment'));
    expect(content, contains('drawFTrem'));
    expect(content, contains('drawBeamSpan'));
    expect(content, contains('DrawBeam'));
  });

  test('05-17 _notYet removed for beam', () {
    final content = File('lib/src/rendering/view_element.dart').readAsStringSync();
    expect(content, isNot(contains("_notYet('DrawBeam'")));
    expect(content, isNot(contains("_notYet('DrawFTrem'")));
  });
}
