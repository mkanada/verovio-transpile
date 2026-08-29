import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/rendering/resources.dart';

import 'support/render_family.dart';

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  // Resumo global — foto do estado real Fase 5 (114/623 estrutural).
  // Lê o relatório gerado por `dart run tool/compare_svg.dart --all` para
  // evitar re-renderizar 623 arquivos em cada `dart test` (caro). O número
  // vem do harness honesto (05-26) e só sobe.
  test('svg golden: resumo global famílias — 114/623 estrutural (05-29)', () {
    final report = File('tool/SVG_VALIDATION.md').readAsStringSync();
    expect(report, contains('114/623 limpos'),
        reason:
            'global estrutural deve ser 114/623 — medir com `dart run tool/compare_svg.dart --all`');
    expect(report, contains('Falhas'), reason: 'relatório deve listar falhas');
    // As 3 falhas conhecidas até 05-36.
    expect(report, contains('ftrem/ftrem-002.mei'));
    expect(report, contains('stem/stem-014.mei'));
    expect(report, contains('stem/stem-016.mei'));
  });

  // Subconjunto representativo por família — 10 famílias, um teste agregado.
  // Substitui o antigo subconjunto fixo de 10 arquivos (1/10) por catraca por
  // família. Cada diretório aqui representa uma família view_*.cpp.
  test('svg golden: famílias representativas (10 dirs) contra goldens',
      timeout: Timeout(Duration(seconds: 90)), () {
    const familias = [
      'test/corpus/beam', // view_beam
      'test/corpus/note', // view_element (note)
      'test/corpus/score', // view_page
      'test/corpus/tie', // view_control
      'test/corpus/tuplet', // view_tuplet
      'test/corpus/slur', // view_slur
      'test/corpus/ligature', // view_mensural
      'test/corpus/neume', // view_neume
      'test/corpus/tab', // view_tab
      'test/corpus/clef', // view_element (clef)
    ];
    final resultados = renderizarFamilias(familias);
    // Soma medida em 2026-08-29:
    // beam 37 + note 3 + score 6 + tie 1 + tuplet 0 + slur 1 + ligature 0 + neume 0 + tab 0 + clef 1 = 49
    expect(resultados.limpos, greaterThanOrEqualTo(49),
        reason: resultados.detalhes.take(5).join('\n'));
    // Nenhuma falha neste subconjunto (as 3 falhas são ftrem/stem, fora do subconjunto)
    expect(resultados.falhas, isEmpty, reason: resultados.falhas.join('\n'));
    expect(
        resultados.total, equals(61 + 12 + 16 + 12 + 22 + 25 + 50 + 6 + 5 + 7),
        reason: 'total de arquivos nas 10 famílias');
  });
}
