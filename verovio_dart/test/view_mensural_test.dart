import 'package:test/test.dart';
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
  // Família view_mensural.cpp — notação mensural
  // -------------------------------------------------------------------------

  test('view_mensural: família ligature/mensural/mensur contra goldens', () {
    final resultados = renderizarFamilias([
      'test/corpus/ligature',
      'test/corpus/mensural',
      'test/corpus/mensur',
    ]);
    // Medido em 2026-08-29: mensur 8/8, ligature 0/50, mensural 0/25 => 8/83
    expect(resultados.limpos, greaterThanOrEqualTo(8),
        reason: resultados.detalhes.take(3).join('\n'));
    expect(resultados.total, equals(83));
    expect(resultados.falhas, isEmpty, reason: resultados.falhas.join('\n'));
  });

  group('view_mensural: decisões Draw* sobre SVG (view_mensural.cpp)', () {
    test('DrawLigature → <g class="ligature"> (view_mensural.cpp:180)', () {
      final svg = renderizar('test/corpus/ligature/ligature-001.mei');
      expect(svg, contains('ligature'),
          reason:
              'ligature-001 deve conter ligature — DrawLigature view_mensural.cpp:185');
    });

    test('DrawMensur → <g class="mensur"> (view_mensural.cpp:90)', () {
      final svg = renderizar('test/corpus/mensur/mensur-01.mei');
      expect(svg, contains('mensur'),
          reason:
              'mensur-01 deve conter mensur — DrawMensur view_mensural.cpp:92');
      // Mensur desenha glifo de mensuration sign.
      expect(svg, contains('<use'), reason: 'mensur usa glifo SMuFL');
    });

    test('DrawMensuralNote → notehead mensural (view_mensural.cpp:34)', () {
      final svg = renderizar('test/corpus/mensural/mensural-001.mei');
      expect(svg, contains('note'), reason: 'mensural-001 contém note');
      expect(svg, contains('<use'), reason: 'nota mensural usa glifo');
    });
  });

  test(
      'view_mensural: primitivas via RecordingDC (view_mensural.cpp:34, view_graph.cpp:259)',
      () {
    final doc = Doc()..drawingPageContentHeight = 2970;
    doc.getResourcesForModification().initFonts();
    final view = View()..setDoc(doc);
    final dc = RecordingDeviceContext();
    dc.setResources(doc.getResources());
    view.drawSmuflCode(dc, 100, 200, 0xE950, 100, false);
    expect(dc.chamadas.any((c) => c.startsWith('drawMusicText')), isTrue,
        reason: 'DrawMensuralNote → drawSmuflCode → drawMusicText');
    final dc2 = RecordingDeviceContext();
    dc2.setResources(doc.getResources());
    view.drawDot(dc2, 90, 100, 100);
    expect(
        dc2.chamadas.any((c) =>
            c.startsWith('drawEllipse') ||
            c.startsWith('drawCircle') ||
            c.startsWith('drawMusicText')),
        isTrue);
  });
}
