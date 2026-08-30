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

  // Resumo global — catraca do estado real da Fase 5.
  // Lê o relatório gerado por `dart run tool/compare_svg.dart --all` para
  // evitar re-renderizar os 621 arquivos do corpus em cada `dart test` (caro).
  //
  // É uma **catraca**: o piso só pode subir. Até 2026-08-29 esta asserção era
  // `contains('114/623 limpos')` — igualdade exata sobre um número que o
  // próprio comentário dizia que "só sobe", então ela falhava justamente
  // quando o port melhorava. Quebrou ao medir 115 (ganho de `1d31040`, a
  // 05-34 parcial); passava antes só porque o relatório em disco estava velho.
  // Ao subir o número, atualize `pisoEstrutural` (tarefa 2026-08-29-01).
  // 2026-08-30: 115 -> 116 (tipagem das famílias de ornamento de
  // `view_control.dart` + os métodos de modelo que ela exigiu).
  const int pisoEstrutural = 116;
  test('svg golden: resumo global — catraca ≥ $pisoEstrutural/621 estrutural',
      () {
    final report = File('tool/SVG_VALIDATION.md').readAsStringSync();
    final match =
        RegExp(r'Estrutural:\s*(\d+)/(\d+)\s+limpos').firstMatch(report);
    expect(match, isNotNull,
        reason: 'não achei a linha "Estrutural: N/M limpos" em '
            'tool/SVG_VALIDATION.md — rode `dart run tool/compare_svg.dart --all`');
    final limpos = int.parse(match!.group(1)!);
    expect(limpos, greaterThanOrEqualTo(pisoEstrutural),
        reason: 'regressão: $limpos limpos, piso $pisoEstrutural. '
            'Remeça com `dart run tool/compare_svg.dart --all`');
    if (limpos > pisoEstrutural) {
      fail('o piso subiu para $limpos (era $pisoEstrutural): atualize '
          '`pisoEstrutural` em test/svg_golden_test.dart para travar o ganho');
    }
    expect(report, contains('Falhas'), reason: 'relatório deve listar falhas');
    // As 3 falhas que existiam até 05-36 (`ftrem/ftrem-002.mei`,
    // `stem/stem-014.mei`, `stem/stem-016.mei`) foram corrigidas em
    // 2026-08-30; nenhuma exceção pode voltar. Esta é a asserção forte que
    // substitui a lista nominal antiga.
    final falhas =
        RegExp(r'Falhas \(exceção durante renderização\):\s*(\d+)')
            .firstMatch(report);
    expect(falhas, isNotNull,
        reason: 'não achei a contagem de falhas em tool/SVG_VALIDATION.md');
    expect(int.parse(falhas!.group(1)!), 0,
        reason: 'nenhum arquivo do corpus pode lançar durante a renderização');
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
