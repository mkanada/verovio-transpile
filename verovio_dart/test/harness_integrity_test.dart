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

  group('harness integrity — 05-27', () {
    test('harness não lê goldens: render difere do golden para 4 famílias', () {
      // Se alguém reintroduzir um bridge que devolve o golden, este teste falha
      // imediatamente porque o SVG renderizado seria idêntico ao golden.
      // 05-27: note-001 agora é 1/10 limpo (milestones), então trocamos por chord-001 que segue divergente.
      // 2026-08-31: dir-001 ficou limpo (getTimePointInterface portado — dir/dynam agora desenham),
      // então trocamos por mensural-001 (83 divergências) e ligature-001 (21).
      // 2026-08-31 (loop de fidelidade): renderSvgForComparison passou a rodar
      // Doc.convertToCastOffMensuralDoc antes do castOffDoc (mirrors
      // toolkit.cpp:846-859), o que tornou mensural-001 e 49/50 arquivos de
      // ligature (inclusive ligature-001) estruturalmente limpos — trocamos
      // por mensural-006 (ainda divergente: precisa de ScoringUpDoc, não
      // portado) e ligature-047 (o único arquivo de ligature ainda
      // divergente).
      // 2026-09-01 (loop de fidelidade 06): DrawDotsPart passou a checar
      // Staff.drawingNotationtype corretamente (mirrors Staff::IsMensural,
      // staff.cpp:255) em vez de uma reflexão dinâmica frágil, o que corrigiu
      // o desenho de pontos de aumentação mensurais (losango via DrawDiamond
      // em vez de círculo via DrawDot) e tornou ligature-047 — e o resto da
      // família ligature, agora 50/50 — estruturalmente limpo. Trocamos por
      // tie-001 (109 divergências, família ainda sem probe aqui).
      final probes = [
        'test/corpus/chord/chord-001.mei',
        'test/corpus/tie/tie-001.mei',
        'test/corpus/beam/beam-049.mei',
        'test/corpus/mensural/mensural-006.mei',
      ];
      for (final meiPath in probes) {
        String? dartSvg;
        try {
          dartSvg = renderSvgForComparison(meiPath);
        } catch (e) {
          fail(
              'renderSvgForComparison lançou para $meiPath (deveria renderizar divergente, não falhar): $e');
        }
        expect(dartSvg, isNotNull, reason: 'render nulo para $meiPath');
        final goldenPath = meiPath
            .replaceAll('test/corpus/', 'test/golden/cpp/')
            .replaceAll('.mei', '.svg');
        final goldenSvg = File(goldenPath).readAsStringSync();
        final result = SvgComparator(epsilon: 0)
            .compare(dartSvg: dartSvg, goldenSvg: goldenSvg);
        expect(result.structuralClean, isFalse,
            reason:
                'harness leu golden para $meiPath: deveria divergir mas foi limpo (bridge reintroduzido?)');
        // Também garante que não é byte-identico (mesmo após normalização de ids, a estrutura diverge)
        expect(result.structuralDivergenceCount, greaterThan(0),
            reason: 'sem divergência para $meiPath');
      }
    });

    test('comparador não é permissivo: golden vs si mesmo é limpo', () {
      final golden =
          File('test/golden/cpp/note/note-001.svg').readAsStringSync();
      final result =
          SvgComparator().compare(dartSvg: golden, goldenSvg: golden);
      expect(result.structuralDivergenceCount, 0,
          reason: result.structuralDivergences.join('\n'));
      expect(result.numericDivergenceCount, 0,
          reason: result.numericDivergences.join('\n'));
      expect(result.structuralClean, isTrue);
      expect(result.numericClean, isTrue);
    });

    test(
        'comparador não é permissivo: mutação única é divergente nos dois modos',
        () {
      final golden =
          File('test/golden/cpp/note/note-001.svg').readAsStringSync();
      // Mutação 1: troca um número (x="90" -> x="91") — deve divergir no modo numérico
      final mutatedNumber =
          golden.replaceFirst(RegExp(r'x="(\d+)"'), 'x="9999"');
      expect(mutatedNumber, isNot(equals(golden)),
          reason: 'mutação de número não alterou');
      final rNum = SvgComparator(epsilon: 0)
          .compare(dartSvg: mutatedNumber, goldenSvg: golden);
      expect(rNum.numericDivergenceCount, greaterThan(0),
          reason: 'mutação numérica não detectada');
      expect(rNum.numericClean, isFalse);
      // Mutação 2: troca um class — deve divergir no modo estrutural
      final mutatedClass = golden.replaceFirst('class="', 'class="MUTATED-');
      expect(mutatedClass, isNot(equals(golden)));
      final rStruct = SvgComparator(epsilon: 0)
          .compare(dartSvg: mutatedClass, goldenSvg: golden);
      expect(rStruct.structuralDivergenceCount, greaterThan(0),
          reason: 'mutação de class não detectada');
      expect(rStruct.structuralClean, isFalse);
      // Mutação 3: altera um id — deve divergir estrutural (mantém XML válido)
      final mutatedId =
          golden.replaceFirst(RegExp(r'id="[^"]+"'), 'id="MUTATED-id"');
      expect(mutatedId, isNot(equals(golden)));
      final rId = SvgComparator(epsilon: 0)
          .compare(dartSvg: mutatedId, goldenSvg: golden);
      expect(rId.structuralDivergenceCount, greaterThan(0),
          reason: 'mutação de id não detectada');
    });

    test('harness não aceita SVG do disco como se fosse renderizado', () {
      // renderSvgForComparison deve aceitar apenas .mei; passar um .svg deve falhar
      final svgPath = 'test/golden/cpp/note/note-001.svg';
      expect(
          () => renderSvgForComparison(svgPath), throwsA(isA<ArgumentError>()),
          reason: 'harness aceitou SVG como entrada — deveria rejeitar .svg');
      // Também garante que nenhum caminho .svg produz SVG (não lê goldens)
      final svgPath2 = 'test/golden/cpp/beam/beam-001.svg';
      expect(() => renderSvgForComparison(svgPath2),
          throwsA(isA<ArgumentError>()));
    });
  });
}
