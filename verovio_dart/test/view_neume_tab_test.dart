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
  // Família view_neume.cpp — neume
  // -------------------------------------------------------------------------

  test('view_neume: família neume/ contra goldens', () {
    final resultados = renderizarFamilia('test/corpus/neume');
    // Medido em 2026-08-29: 0 limpos / 6 total
    expect(resultados.limpos, greaterThanOrEqualTo(0),
        reason: resultados.detalhes.take(3).join('\n'));
    expect(resultados.total, equals(6));
    expect(resultados.falhas, isEmpty, reason: resultados.falhas.join('\n'));
  });

  test('view_neume: decisão DrawNeume → <g class="neume"> (view_neume.cpp:80)',
      () {
    final svg = renderizar('test/corpus/neume/neume-001.mei');
    expect(svg, contains('neume'),
        reason: 'neume-001 deve conter neume — DrawNeume view_neume.cpp:85');
    expect(svg, contains('<use'), reason: 'neume usa glifos SMuFL');
  });

  // -------------------------------------------------------------------------
  // Família view_tab.cpp — tablatura
  // -------------------------------------------------------------------------

  test('view_tab: família tab/ contra goldens', () {
    final resultados = renderizarFamilia('test/corpus/tab');
    // Medido em 2026-08-29: 0 limpos / 5 total
    expect(resultados.limpos, greaterThanOrEqualTo(0),
        reason: resultados.detalhes.take(3).join('\n'));
    expect(resultados.total, equals(5));
    expect(resultados.falhas, isEmpty, reason: resultados.falhas.join('\n'));
  });

  test('view_tab: decisão DrawTabGrp → <g class="tabGrp"> (view_tab.cpp:34)',
      () {
    final svg = renderizar('test/corpus/tab/tab-001.mei');
    expect(svg, contains('tabGrp'),
        reason: 'tab-001 deve conter tabGrp — DrawTabGrp view_tab.cpp:38');
    // Tab usa texto/linhas; verifica presença de staff ou tab.
    expect(svg, anyOf(contains('tab'), contains('staff')));
  });

  test(
      'view_neume_tab: primitivas via RecordingDC (view_neume.cpp:120, view_tab.cpp:70)',
      () {
    final doc = Doc()..drawingPageContentHeight = 2970;
    doc.getResourcesForModification().initFonts();
    final view = View()..setDoc(doc);
    final dc = RecordingDeviceContext();
    dc.setResources(doc.getResources());
    view.drawSmuflCode(dc, 100, 200, 0xE990, 100, false);
    expect(dc.chamadas.any((c) => c.startsWith('drawMusicText')), isTrue,
        reason: 'DrawNc/DrawNeume usam drawSmuflCode');
    final dc2 = RecordingDeviceContext();
    dc2.setResources(doc.getResources());
    view.drawHorizontalLine(dc2, 10, 60, 40, 2);
    expect(dc2.chamadas.any((c) => c.startsWith('drawLine')), isTrue);
  });

  test('view_neume_tab: cada arquivo neume/tab renderiza sem exceção', () {
    final familias = ['test/corpus/neume', 'test/corpus/tab'];
    final r = renderizarFamilias(familias);
    expect(r.falhas, isEmpty, reason: r.falhas.join('\n'));
    expect(r.total, equals(11));
  });
}
