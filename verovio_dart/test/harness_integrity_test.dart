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
    test('harness não lê goldens: render difere do golden (1 estrutural + 4 numéricos)', () {
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
      // 2026-09-01 (loop de fidelidade 08): ConvertMarkupAnalyticalFunctor
      // (preparedata_functor.dart, mirrors convertfunctor.cpp:1111) passou a
      // converter @tie/@fermata em elementos <tie>/<fermata>, o que tornou
      // tie-001 (e o resto da família tie, agora 12/12) estruturalmente
      // limpo. Trocamos por score-011 (221 divergências, ainda sem causa
      // corrigida). O mesmo loop também corrigiu `Layer.getClefLocOffset`
      // não fazer a busca retroativa por `<clef>` inline (layer.cpp:234) em
      // `calcDrawingLocHeadless` (usado por `CalcStemFunctor`), e removeu o
      // cômputo espúrio de loc para notas sem pitch definido — o que tornou
      // mensural-006 (agora 24/25 na família) estruturalmente limpo.
      // Trocamos por mensural-025 (2 divergências, ainda sem causa
      // corrigida).
      // 2026-09-02 (loop de fidelidade 07): DrawVerse labelAbbr via
      // GetDrawingLabelAbbr + second AdjustSylSpacing after CastOff (page.cpp)
      // tornou lyric-012 (575 diverg) e score-011 (221) estruturalmente limpos.
      // Trocamos score-011 por score-004 (9 diverg, ainda sem causa).
      // 2026-09-02 (loop fix enclosure): DrawRend::HasEnclosure (rend.cpp:85)
      // + DrawRend HasEnclosure->enclosedRend (view_text.cpp:462) tornou
      // dir-008/rend-002 (box/circle, 20 diverg cada) e score-004 (que
      // contém rend box) estruturalmente limpos. Trocamos score-004 por
      // ossia-002 (148 diverg, ainda sem causa).
      // 2026-09-02 (loop de fidelidade 09): View.drawNote passou a
      // redesenhar os filhos de uma nota mensural com Dots (mirrors
      // View::DrawNote, view_element.cpp:1481-1485) e CalcDotsFunctor a
      // fixar `Dots.drawingXRel`/o loc do ponto de aumentação para notas
      // avulsas (mirrors CalcDotsFunctor::VisitNote,
      // calcdotsfunctor.cpp:96-121), o que tornou mensural-025 (2 diverg)
      // estrutural e numericamente limpo. Trocamos por gracenote-011 (73
      // diverg, ainda sem causa corrigida).
      // 2026-09-03 (loop de fidelidade): AlignHorizontallyFunctor.visitLayer
      // passou a promover `scoreDefRole` para ossia quando
      // `layer.drawOssiaStaffDef` (mirrors alignfunctor.cpp:74), visitOssia
      // passou a ligar a drawing left barline (alignfunctor.cpp:444) e
      // ScoreDefUnsetCurrentFunctor.visitOssia a resetar o drawing staffGrp
      // (setscoredeffunctor.cpp:861) — o que tornou ossia-002 (148 diverg,
      // cast-off errado por largura de compasso + barline triplicada)
      // estruturalmente limpo (e ossia-003 e bracketspan-001 junto).
      // Trocamos por tab-005 (66 diverg, ainda sem causa corrigida).
      // 2026-09-03 (loop de fidelidade): `LayerElement::IsInBeam` passou a
      // usar `getAncestorBeam()` (mirrors layerelement.cpp:228-256 — retorna
      // NULL para gracenote embutida em beam misto) em
      // `PrepareLayerElementPartsFunctor._isInBeam`,
      // `CalcStemFunctor._isInBeam` e `calcStemLenInThirdUnitsHeadless` — o
      // que tornou gracenote-011 (73 diverg: haste degenerada sem flag) e
      // cross-staff-015 (49 diverg: glifo de flag E242 ausente)
      // estruturalmente limpos. Trocamos gracenote-011 por
      // cross-staff-001 (9 diverg, ainda sem causa corrigida).
      // 2026-09-03 (loop de fidelidade tab): View.drawBeamSegment passou a
      // aplicar durRef/durRef2 deslocados so para lute French/German/
      // Italian + staff-like (mirrors view_beam.cpp:295, antes aplicava a
      // todo IsTablature inclusive tab.guitar) e
      // ScoreDefSetCurrentFunctor.visitStaff passou a escalar German por
      // germanTabStaffRatio proprio (mirrors setscoredeffunctor.cpp:334)
      // — o que tornou tab-005 (66 diverg: beams de 8 vs 11 filhos)
      // estruturalmente limpo. Trocamos tab-005 por tab-004 (14 diverg,
      // guitar-tab gaps, ainda sem causa corrigida).
      // 2026-09-04 (loop de fidelidade, fix numérico 01): o truncamento
      // por-termo em DrawBentParallelogram (view_mensural.dart) foi
      // corrigido para truncamento único (mirrors view_mensural.cpp:418-422),
      // o que zerou as divergências numéricas de chord-001 e beam-049
      // (num 112->138) — ambos ficaram só-numéricos→limpos. Trocamos
      // chord-001 por arpeg-003 e beam-049 por stem-014 (ambos com erro
      // estrutural real, ainda sem causa corrigida).
      // 2026-09-05 (loop de fidelidade, trilha ESTRUTURAL): a role
      // primary/secondary de `stem.sameas` (BeamSegment::UpdateSameasRoles,
      // beam.cpp:1162-1164 e :1515, decide qual dos dois beams ligados
      // desenha o polígono) nunca era propagada — faltava a chamada e
      // `ResetHorizontalAlignmentFunctor::VisitBeam` não zerava o role entre
      // passadas de layout (resetfunctor.cpp:583-591), então o role
      // congelava na 1ª passada horizontal (Y ainda 0 para todas as notas).
      // Corrigido em `beam_segment.dart`/`align_horizontally.dart`, o que
      // tornou stem-014 (e stem-016, fora desta lista) estruturalmente
      // limpos. Trocamos stem-014 por barline-009 (4 diverg, ainda sem causa
      // corrigida).
      // 2026-09-06 (loop de fidelidade, trilha CAUSA):
      // `getAncestorStaffResolveCrossStaff` (preparedata_functor.dart) só
      // checava `this.crossStaff` em vez de espelhar
      // `LayerElement::GetAncestorStaff(RESOLVE_CROSS_STAFF)`
      // (layerelement.cpp:280), que resolve via `GetCrossStaff()` — a busca
      // ancestral que sobe até o layer element mais próximo com
      // `m_crossStaff` setado. Elementos sem `AttStaffIdent` própria (accid,
      // que não carrega `@staff`) caíam direto no `<staff>` físico do XML em
      // vez de herdar o cross-staff da nota/acorde pai, inflando o overflow
      // vertical calculado para a pauta errada. Corrigido usando
      // `getCrossStaff()` (já correto, layer_element.dart:334), o que
      // tornou arpeg-003 (9 diverg) estruturalmente limpo. Trocamos por
      // midi/005-maqam-rast-external-tuning.mei (14 diverg, ainda sem causa
      // corrigida).
      // 2026-09-07 (loop de fidelidade, trilha ESTRUTURAL):
      // `_calcEventLoc` (lay_out_vertically.dart) passou a portar o ramo
      // tabGrp de `CalcAlignmentPitchPosFunctor::VisitLayerElement`
      // (calcalignmentpitchposfunctor.cpp:106-117) — o loc de nota de
      // tablatura vem de `Tuning::CalcPitchPos` (curso), não de
      // @pname/@oct — o que zerou a contagem de filhos errada das linhas de
      // pauta com gaps de tablatura e tornou tab-004 (14 diverg)
      // estruturalmente limpo. Trocamos por cross-staff-020 (3 diverg,
      // ledger lines de cross-staff, ainda sem causa corrigida).
      // 2026-09-07 (loop de fidelidade, trilha ESTRUTURAL): `ScoreDef.copyFrom`
      // (scoredef.dart) passou a zerar `barLen`/`barMethod`/`barPlace`
      // (AttBarring) — o C++ copia ScoreDef via `Object::operator=`
      // (object.cpp:137), que copia só a base Object e nunca os membros
      // Att-mixin, então o drawingScoreDef carrega sempre o default e
      // `GetMethodFromContext` nunca encontra `mensur` ali; o Dart honrava
      // (corretamente, mas não equivalentemente) o `bar.method="mensur"`,
      // desenhando taktstriche em vez de inside+outside-staff — o que tornou
      // barline-009 (4 diverg) estruturalmente limpo. Trocamos por
      // cross-staff-004 (1 diverg, ledger lines de cross-staff, ainda sem
      // causa corrigida).
      // 2026-09-08 (invest-02, unbeamed cross-staff stems): o `loc` headless
      // (`LayoutElementHelpers.calcDrawingLocHeadless`,
      // preparedata_functor.dart) lia a clave da camada física em vez da
      // camada cruzada — `note-L40F2` (@staff="2" em pauta de sol) calculava
      // loc -13 (sol) em vez de -1 (fá), e cada passada tardia de CalcStem/
      // CalcDots sobrescrevia o `drawingLoc` correto com o errado, gerando
      // 6 ledger lines fantasmas (8-vs-2) — mais a direção de acorde mista
      // via Y real (`_calcChordStemDirectionY`, calcstemfunctor.cpp:586-622).
      // Corrigido, o que tornou cross-staff-004 (1 diverg), cross-staff-005
      // (5), cross-staff-020 (3) e layer-015 (1) estruturalmente limpos —
      // restam só beam-049 (4) e midi/005 (14) com divergência estrutural no
      // corpus. Os probes 004/005/020 viram probes *numéricos* (ponte que
      // devolve o golden zeraria o numérico também): 004 (92), 005 (166),
      // 020 (232).
      // 2026-09-09 (loop de fidelidade, trilha ESTRUTURAL): o `calcStem`
      // "headless" que `Doc.prepareData` roda para dar estado de desenho a
      // consumidores sem passe de render (ver o comentário "Headless drawing
      // calculations" em `doc.dart`) executava `BeamSegment::CalcBeam`
      // (beam.cpp:89) contra geometria ainda não resolvida (toda pauta na Y
      // padrão) — para o beam de direção mista de `beam-049.mei`,
      // `NeedToResetPosition` (beam.cpp:131) lia essa geometria degenerada,
      // achava "sem espaço" e colapsava `m_drawingPlace` de `mixed` para
      // `above` permanentemente no objeto `Beam`. Como `IsHorizontal`
      // (drawinginterface.cpp:104-112) deliberadamente lê o `m_drawingPlace`
      // da passada ANTERIOR antes de recalculá-lo — mecanismo real do C++,
      // não bug —, esse colapso espúrio sobrevivia até a passada de layout
      // real (`layOutHorizontally`, que roda `CalcStemFunctor` de novo com Y
      // reais) e a desviava para o ramo errado (inclinado em vez de
      // horizontal), mudando a geometria final do beam e, a jusante, a
      // escolha acima/abaixo de `CalcArticFunctor` para a articulação sobre
      // ele (`E4A2` esperado virava `E4A3`). Corrigido limpando
      // `beamElementCoordsOwned` de todo `Beam` ao final da seção headless de
      // `Doc.prepareData` — a próxima passada real vê a lista vazia de novo e
      // reroda `initCoords` (que zera `m_drawingPlace` para `none`, o estado
      // real do C++ na primeira vez que `CalcBeam` roda, já que ele nunca
      // executa esse passe headless). Isso tornou beam-049 (4 diverg
      // estruturais, 25 numéricas) totalmente limpo — e não achou nenhum
      // outro arquivo do corpus com divergência estrutural sobrando, então o
      // corpus caiu de 2 para 1 arquivo estruturalmente divergente. Trocamos
      // beam-049 por rest-019 (228 diverg numéricas, ainda sem causa
      // corrigida) na lista de probes numéricos.
      // 2026-09-09 (loop de fidelidade, trilha CAUSA): mesma classe de bug do
      // `beam-049` acima, mas para `CalcSlurDirectionFunctor`
      // (calc_functors.dart), que também roda na seção "headless" de
      // `Doc.prepareData`. Antes de qualquer alinhamento horizontal existir,
      // `Layer.getDrawingStemDirFor` (basic_elements.dart, mirrors
      // `Layer::GetDrawingStemDir(const LayerElement*)`, layer.cpp:301) via
      // `getLayerCountForTimeSpanOf` sempre vê `Alignment` nulo e degrada
      // para conjunto vazio (0 camadas), então o ramo
      // `crossStaffFromBelow`/`crossStaffFromAbove` nunca era alcançado — o
      // slur caía no ramo `noteStemDir` simples, escolhendo `below` em vez
      // de `above` para `cross-staff-014.mei` (stems para cima numa camada
      // marcada `crossStaffFromBelow` por uma nota cruzada de outra pauta).
      // Como `hasDrawingCurveDir()` bloqueia a repasse real
      // (`layOutHorizontally`'s `calcSlurDirectionForHoriz`), a direção
      // errada sobrevivia até o desenho, invertendo qual pauta herdava o
      // `CalcMinimumRequiredSpacing` do slur (`AdjustStaffOverlapFunctor` /
      // `AdjustYPosFunctor`, adjuststaffoverlapfunctor.cpp,
      // adjustyposfunctor.cpp) e deslocando o sistema inteiro em Y. Corrigido
      // resetando `drawingCurveDir` para `none` em todo `Slur` ao final da
      // seção headless de `Doc.prepareData`, espelhando o fix do beam-049.
      // Isso tornou `cross-staff-005.mei` (era 166 diverg. numéricas) quase
      // totalmente limpo (3 diverg. numéricas residuais, sem causa
      // relacionada nesta) — abaixo do threshold do probe antigo (80).
      // Trocado o probe numérico por `arpeg-001.mei` (186 diverg. numéricas,
      // ainda sem causa corrigida).
      // 2026-09-09: `LayerElement.getDrawingTop/getDrawingBottom` (via
      // `Slur::CalcEndPoints`, slur.cpp:598) chamavam o helper reduzido
      // `drawingTopOf`/`drawingBottomOf` (sem checagem de articulação) em vez
      // do port completo com `withArtic` (`LayoutElementHelpers.getDrawingTop`
      // /`getDrawingBottom`, preparedata_functor.dart) — um slur ancorado numa
      // nota/acorde com `<artic>` ficava perto demais da cabeça de nota.
      // Corrigido chamando o método completo. Isso zerou `arpeg-001.mei`
      // (era 186 diverg. numéricas) — abaixo do threshold do probe antigo
      // (100). Trocado o probe por `ossia-003.mei` (640 diverg. numéricas,
      // sem causa relacionada a este fix).
      final structuralProbes = [
        'test/corpus/midi/005-maqam-rast-external-tuning.mei',
      ];
      for (final meiPath in structuralProbes) {
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
      // Probes numéricos: estruturalmente limpos após o invest-02, mas com
      // divergência numérica folgada — uma ponte que devolvesse o golden
      // zeraria estes contadores também.
      final numericProbes = {
        'test/corpus/cross-staff/cross-staff-004.mei': 40,
        'test/corpus/cross-staff/cross-staff-020.mei': 100,
        'test/corpus/rest/rest-019.mei': 100,
        'test/corpus/ossia/ossia-003.mei': 100,
      };
      for (final entry in numericProbes.entries) {
        final meiPath = entry.key;
        String? dartSvg;
        try {
          dartSvg = renderSvgForComparison(meiPath);
        } catch (e) {
          fail(
              'renderSvgForComparison lançou para $meiPath (deveria renderizar, não falhar): $e');
        }
        expect(dartSvg, isNotNull, reason: 'render nulo para $meiPath');
        final goldenPath = meiPath
            .replaceAll('test/corpus/', 'test/golden/cpp/')
            .replaceAll('.mei', '.svg');
        final goldenSvg = File(goldenPath).readAsStringSync();
        final result = SvgComparator(epsilon: 0)
            .compare(dartSvg: dartSvg, goldenSvg: goldenSvg);
        expect(result.numericDivergenceCount, greaterThan(entry.value),
            reason:
                'harness leu golden para $meiPath: divergência numérica colapsou (bridge reintroduzido?)');
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
