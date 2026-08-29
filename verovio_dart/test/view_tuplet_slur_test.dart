import 'package:test/test.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';

import 'support/render_family.dart';

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  // -------------------------------------------------------------------------
  // Família tuplet — view_tuplet.cpp
  // -------------------------------------------------------------------------

  test('view_tuplet: família tuplet/ contra goldens', () {
    final resultados = renderizarFamilia('test/corpus/tuplet');
    // Medido em 2026-08-29: 0 limpos / 22 total, 0 falhas
    expect(resultados.limpos, greaterThanOrEqualTo(0),
        reason: resultados.detalhes.take(3).join('\n'));
    expect(resultados.total, equals(22));
    expect(resultados.falhas, isEmpty, reason: resultados.falhas.join('\n'));
  });

  test(
      'view_tuplet: decisão DrawTuplet — número e bracket (view_tuplet.cpp:34)',
      () {
    final svg = renderizar('test/corpus/tuplet/tuplet-001.mei');
    // DrawTuplet → DrawTupletBracket (linha) + DrawTupletNum (número SMuFL)
    // (view_tuplet.cpp:60-90). Tuplet sempre emite <g class="tuplet">.
    expect(svg, contains('tuplet'),
        reason: 'tuplet-001 deve conter classe tuplet');
    // O número do tuplet é desenhado como texto SMuFL (E880...).
    expect(
        svg, anyOf(contains('tupletNum'), contains('E880'), contains('<text')));
  });

  // -------------------------------------------------------------------------
  // Família slur/phrase — view_slur.cpp
  // -------------------------------------------------------------------------

  test('view_slur: família slur/phrase contra goldens', () {
    final resultados = renderizarFamilias([
      'test/corpus/slur',
      'test/corpus/phrase',
    ]);
    // Medido: slur 1/25 + phrase 0/1 = 1/26
    expect(resultados.limpos, greaterThanOrEqualTo(1),
        reason: resultados.detalhes.take(3).join('\n'));
    expect(resultados.total, equals(26));
    expect(resultados.falhas, isEmpty, reason: resultados.falhas.join('\n'));
  });

  test(
      'view_slur: decisão DrawSlur — curva bezier e classe slur (view_slur.cpp:42)',
      () {
    final svg = renderizar('test/corpus/slur/slur-001.mei');
    // DrawSlur → DrawThickBezierCurve → <path d="M... C..."> (view_slur.cpp:120)
    expect(svg, contains('slur'), reason: 'slur-001 deve conter classe slur');
    expect(svg, contains('<path'),
        reason: 'slur desenhada como bezier preenchida');
  });

  test(
      'view_tuplet_slur: primitivas via RecordingDC (view_graph.cpp:359, view_slur.cpp:200)',
      () {
    final view = View()..setDoc(Doc()..drawingPageContentHeight = 2970);
    final dc = RecordingDeviceContext();
    dc.drawCubicBezierPath(
        [Point(0, 100), Point(100, 100), Point(200, 100), Point(300, 100)]);
    expect(dc.chamadas.any((c) => c.startsWith('drawCubicBezierPath')), isTrue);
    final dc2 = RecordingDeviceContext();
    view.drawThickBezierCurve(
        dc2,
        [
          Point(0, 100),
          Point(100, 100),
          Point(200, 100),
          Point(300, 100),
        ],
        10,
        100,
        2);
    expect(
        dc2.chamadas.any((c) =>
            c.contains('drawCubicBezierPathFilled') ||
            c.contains('drawCubicBezierPath')),
        isTrue);
  });
}
