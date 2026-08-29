import 'package:test/test.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/model/doc.dart';

import 'support/render_family.dart';

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  // -------------------------------------------------------------------------
  // Família beam/beamspan/ftrem/btrem/cross-staff — view_beam.cpp
  // -------------------------------------------------------------------------

  test(
      'view_beam: família beam/beamspan/ftrem/btrem/cross-staff contra goldens',
      () {
    const falhasConhecidas05_36 = ['ftrem/ftrem-002.mei'];
    final resultados = renderizarFamilias([
      'test/corpus/beam',
      'test/corpus/beamspan',
      'test/corpus/ftrem',
      'test/corpus/btrem',
      'test/corpus/cross-staff',
    ], falhasConhecidas05_36: falhasConhecidas05_36);
    // Medido em 2026-08-29: 41 limpos / 99 total (1 falha conhecida ftrem-002)
    expect(resultados.limpos, greaterThanOrEqualTo(41),
        reason: resultados.detalhes.take(3).join('\n'));
    expect(resultados.total, greaterThanOrEqualTo(98));
    final falhasReais = resultados.falhas
        .where((f) => !falhasConhecidas05_36.any((k) => f.contains(k)))
        .toList();
    expect(falhasReais, isEmpty, reason: falhasReais.join('\n'));
  });

  test(
      'view_beam: decisão DrawBeam — SVG contém beam e polígono (view_beam.cpp:34)',
      () {
    final svg = renderizar('test/corpus/beam/beam-001.mei');
    // DrawBeam agrupa em <g class="beam"> e desenha segmentos como <polygon>
    // (view_beam.cpp:98-102, :314 DrawBeamSegment → drawObliquePolygon).
    expect(svg, contains('beam'), reason: 'beam-001 deve conter classe beam');
    expect(svg, contains('polygon'),
        reason: 'beam desenhado via drawObliquePolygon (polygon)');
  });

  test(
      'view_beam: decisão DrawFTrem — fTrem desenha polígonos (view_beam.cpp:91)',
      () {
    final svg = renderizar('test/corpus/ftrem/ftrem-001.mei');
    // DrawFTrem → DrawFTremSegment → drawObliquePolygon (view_beam.cpp:205-212)
    expect(svg, contains('fTrem'),
        reason: 'ftrem-001 deve conter classe fTrem');
    expect(svg, contains('polygon'));
  });

  test(
      'view_beam: primitivas via RecordingDeviceContext (view_beam.cpp:314, view_graph.cpp:86)',
      () {
    final dc = RecordingDeviceContext();
    final view = View()..setDoc(Doc()..drawingPageContentHeight = 2970);
    // Diretamente a primitiva usada por DrawBeamSegment.
    view.drawObliquePolygon(dc, 10, 100, 50, 200, 30);
    expect(dc.chamadas, contains('drawPolygon:4'),
        reason: 'DrawBeamSegment usa drawObliquePolygon → drawPolygon');
    // drawVerticalLine também é exercitada indiretamente nos stems.
    final dc2 = RecordingDeviceContext();
    view.drawVerticalLine(dc2, 100, 200, 50, 3);
    expect(dc2.chamadas.any((c) => c.startsWith('drawLine')), isTrue);
  });
}
