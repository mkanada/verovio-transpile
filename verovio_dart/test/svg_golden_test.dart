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
  // 2026-08-31: 116 -> 126 (CalcDots em Page.layOutVertically — Dots vazios em dot/rest/beam/slur)
  // 2026-08-31: 126 -> 370 (getXxxInterface() em Object + DrawDynamString via
  // drawTextString + DrawControlElement sem else — dir/dynam/mNum/harm/tempo desenhados)
  // 2026-08-31: 370 -> 396 (hook do octave via quirk NONE-vs-none; alignedNum do
  // tupletBracket; LayersInTimeSpanFunctor; direção de haste via calcBeam)
  // 2026-08-31: 396 -> 417 (texto SMuFL via DrawText e não DrawMusicText —
  // harm/symbol/lyric-elision; @font-face embutido no Commit; ClassId.figure
  // morto -> ClassId.f em DrawFb/DrawFConnector/DrawSystemList — figured-bass
  // 4/4, harm 4/5, stem-009, symbol 2/2, ornam, repeatmark-002, lyric-007)
  // 2026-08-31: 417 -> 444 (DrawSylConnectorLines — rect do conector de sílaba
  // via AddToDrawingList/resumeGraphic; probe 05-40)
  // 2026-08-31: 444 -> 468 (renderSvgForComparison passou a chamar
  // Doc.convertToCastOffMensuralDoc antes de castOffDoc, mirror de
  // toolkit.cpp:846-859 — sem isso um doc mensural sem <measure> não tinha
  // onde quebrar em sistemas; mensural 0->5/25, neume 0->3/6, ligature 34->49/50)
  // 2026-08-31: 468 -> 486 (Layer.getCurrentClef() em basic_elements.dart
  // retornava staffDefClef — o clone *transiente* criado por
  // setDrawingStaffDefValues só quando o clef precisa ser redesenhado, e
  // então zerado — em vez de espelhar Layer::GetCurrentClef, layer.cpp:490,
  // que lê staff->m_drawingStaffDef->GetCurrentClef(). Isso fazia
  // Layer.getClef()/drawKeySig() ver clef==null em toda medida que muda de
  // keySig/scoreDef sem também redesenhar o clef — a maioria das mudanças de
  // key signature no meio da peça — e o keySig inteiro (glifos de acidente
  // E260-E263 no <defs>) era pulado silenciosamente; keysig 3->? , ossia
  // 0->1/4, midi/003 corrigido; ver getCurrentMensur/getCurrentMeterSig no
  // mesmo arquivo para o padrão correto já existente)
  // 2026-08-31: 486 -> 503 (Beam.filterList em layer_elements_gen.dart usava
  // `List.removeWhere` com um `firstElement` capturado uma única vez antes do
  // laço, comparado por `identical`. Mirrors Beam::FilterList, beam.cpp:1650,
  // cujo `childList.begin() == iter` é reavaliado a cada iteração do laço C++
  // — "o primeiro elemento" é quem sobrevive primeiro ao ramo `else`, não o
  // cabeça literal da lista original, que para um <beam> é o próprio Beam
  // (sem DurationInterface) e nunca reaparece depois de removido. Com o
  // `firstElement` fixo no Beam, nenhuma nota era `identical` a ele,
  // `firstNoteGrace` nunca virava true, e TODA grace note de um beam era
  // removida da lista — inclusive o beam inteiro via `hasEmptyList()` em
  // `View::DrawBeam`/`drawBeam` quando só continha grace notes (early
  // `return` antes de qualquer `startGraphic`, apagando o `<g class="beam">`
  // e os `<note>` dentro dele do SVG). Portado como laço por índice (`i == 0`
  // no lugar de `iter == childList.begin()`, `removeAt(i)` sem incrementar no
  // lugar de `erase(iter); continue`) para replicar a semântica exata do
  // iterador. gracenote 12->26/27 (a família quase inteira — a maioria dos
  // arquivos de gracenote usa `<beam>` para os grupos de grace notes
  // articuladas); efeito colateral em outras famílias com beams de grace
  // notes (layer, mensural, etc.).
  // 2026-08-31: 503 -> 504 (Object._traverseChildrenOnly em model/object.dart
  // só descontava editorial elements de `deepness`, espelhando a sobrecarga
  // *mutável* de `Object::Process` — mas todo `Find*ByComparison`/
  // `Find*ByType`/`Find*ByID`/`FillFlatList` do C++ resolve, via
  // `std::as_const`, para a sobrecarga **const** de `Process`
  // (object.cpp:1120-1169), cujo desconto é
  // `IsEditorialElement() || this->Is(OSSIA)`. Sem o `OSSIA`, uma busca
  // `deepness: 1` a partir de `<measure>` (ex.: View::DrawStaffDefLabels
  // procurando seu `<staff>` por `@n`) nunca alcançava um `<staff>` aninhado
  // um nível a mais dentro de `<ossia>`, apagando labels/conteúdo em toda
  // medida com ossia. ossia 0->1/4 limpo (ossia-002/003/004 caíram de
  // 152/234/? divergências estruturais para 171/10/2 — não zerados, outras
  // causas raiz distintas ficam para a próxima iteração).
  // 2026-08-31: 504 -> 508 (loop 05, 2ª rodada: a hipótese inicial de uma
  // exceção engolida em `drawBeamSpan` — view_control.dart's silent
  // `catch (e) { e.toString(); }` — não se confirmou: instrumentado
  // temporariamente com `print` real, os 621 arquivos do corpus rodaram sem
  // nenhuma exceção capturada ali. A causa raiz real era um desenho
  // *duplicado*: `View::DrawMeasureChildren` (view_page.cpp:1744) só chama
  // `segment->CalcBeam(...)` no laço de `<beamSpan>` — o desenho de verdade
  // acontece depois, quando o placeholder vazio criado por
  // `DrawControlElement` (view_control.cpp:82, lista
  // ANNOTSCORE/BEAMSPAN/.../TIE) é retomado via `ResumeGraphic` na passada de
  // elementos com extensão. `drawMeasureChildren` (view_page.dart) chamava
  // `drawBeamSpan(dc, beamSpan, system, null)` diretamente nesse laço —
  // desenhando o conteúdo completo ali mesmo (um `<g class="beamSpan">` cheio)
  // e depois, na passada normal, o placeholder criava um *segundo* `<g>` vazio
  // com o mesmo id — dobrando o SVG relativo ao golden (a contagem de
  // `beamSpan` no SVG do Dart era sempre 2x a do golden). Corrigido trocando
  // a chamada por `segment.calcBeam(...)`, espelhando o C++ exatamente.
  // beamspan 0->4/6 limpo (beamspan-001/002/003/005 — 005 é o caso
  // cross-staff que a rodada anterior suspeitava ser o problema; ele também
  // ficou limpo, então a hipótese de que o motor de beam reduzido não
  // suportava cross-staff também não se confirmou. beamspan-004 e
  // beamspan-006 continuam divergentes, por causas raiz distintas — 006 por
  // um glifo `E240` a mais no `<defs>`, 004 por um `<g>` aninhado com 2
  // filhos em vez de 41 — não investigadas nesta iteração).
  // 2026-09-01: 508 -> 527 (loop 06). `View::DrawDotsPart` (view_element.cpp:2030)
  // desenha o ponto de aumentação mensural como um losango (`DrawDiamond`)
  // quando `staff->IsMensural()`, e como um círculo (`DrawDot`, um `<ellipse>`
  // no SVG) caso contrário. `drawDotsPart` (view_element.dart) checava isso
  // com uma reflexão dinâmica frágil (`_dyn(staff).isMensural`, um getter que
  // não existe em `Staff`, sempre lançando e caindo no `catch` para `false`)
  // — todo ponto de aumentação em notação mensural saía como `<ellipse>` em
  // vez do `<polygon>` losangular do C++. Trocado por um check direto de
  // `staff.drawingNotationtype` contra `Notationtype.mensural/mensuralWhite/
  // mensuralBlack` (mirrors `Staff::IsMensural`, staff.cpp:255). Mensural
  // 5/25 -> 23/25 estrutural; ligature (que também usa notação mensural)
  // 49/50 -> 50/50.
  // 2026-09-01: 527 -> 530 (loop 07b). `CastOffSystemsFunctor` (cast_off.dart)
  // hardcodava `+ 0` no lugar de `System::GetDrawingAbbrLabelsWidth()` em
  // `visitScoreDef`/`visitSystem` (castofffunctor.cpp:212/227), com um
  // comentário de "Deviation" afirmando que o getter não estava portado — mas
  // `System.getDrawingAbbrLabelsWidth()`/`setDrawingAbbrLabelsWidth()`
  // (system_page_elements.dart) e a chamada que o popula em `drawLabels`
  // (view_page.dart:1116) já existiam. Score-015 (e qualquer partitura com
  // rótulos abreviados em staffGrp) subestimava a largura do sistema em cada
  // quebra de sistema — probe C++ 05-42 (`CastOffVisitSystem`) confirmou
  // `abbrLabelsWidth=1324` onde o Dart usava 0. Fix: ler o valor real do
  // `System`/`_contentSystem` em vez do literal 0.
  // 2026-09-01: 530 -> 538 (loop 08). Three root causes, all in the pitch /
  // clef / stem pipeline:
  // (1) `Doc.convertMarkupDoc` (doc.dart) logged a warning and left @tie /
  //     @fermata attributes unconverted instead of running the equivalent of
  //     `ConvertMarkupAnalyticalFunctor` (convertfunctor.cpp:1111). Added
  //     `ConvertMarkupAnalyticalFunctor` (preparedata_functor.dart), driven
  //     per staff/layer exactly like `Doc::ConvertMarkupDoc`
  //     (doc.cpp:1515-1552) via the existing `InitProcessingListsFunctor` /
  //     `Filters` / `AttNIntegerComparison` machinery. tie 10/12 -> 12/12,
  //     fermata 5/7 -> 7/7.
  // (2) `_clefLocOffset` (lay_out_vertically.dart) and
  //     `getClefLocOffsetHeadless` (preparedata_functor.dart) only looked at
  //     `Layer.staffDefClef` / `StaffDef.getCurrentClef()`, never at an
  //     inline `<clef>` element preceding the specific note within the same
  //     layer — unlike `Layer::GetClef(test)` (layer.cpp:234), which walks
  //     backward via `GetListFirstBackward(test, CLEF)`. A mid-measure clef
  //     change (e.g. `<rest/><rest/><clef/><note/>`, clef-003.mei) made the
  //     pitch-position AND stem-direction calc for everything after it use
  //     the *old* clef, flipping the flag glyph (E240 vs E241) and
  //     articulation placement. Both call sites now delegate to the already
  //     correct `Layer.getClefLocOffset(layerElementY)`
  //     (calcalignmentpitchposfunctor.cpp:130/163/pitchinterface.cpp:161).
  // (3) `calcDrawingLocHeadless` (preparedata_functor.dart) computed a loc
  //     from `pname ?? Pitchname.none` even for pitchless notes (no
  //     `@pname`/`@oct`, e.g. a percussion note on a one-line staff,
  //     note-004.mei), instead of staying at loc `0` like
  //     `CalcAlignmentPitchPosFunctor::VisitLayerElement`
  //     (calcalignmentpitchposfunctor.cpp:114) does when neither
  //     `HasPname()`/`HasOct()`/`HasOctDefault()` nor `HasLoc()` holds —
  //     flipping stem direction/flag glyph for those notes too. Added the
  //     same guard `_calcEventLoc` already used.
  // Probe files note-004, clef-003 and font-002 (flag glyph) went clean, plus
  // the whole tie/fermata families; mensural-006 also went clean as a side
  // effect of (2)/(3), so `test/harness_integrity_test.dart` was updated to
  // probe score-011/mensural-025 instead of tie-001/mensural-006.
  // 2026-09-01: 538 -> 542 (loop 09). Two root causes:
  // (1) `View._getNoteheadGlyph` (view_element.dart) was a hand-rolled
  //     reimplementation of `Note::GetNoteheadGlyph` (note.cpp:640) that
  //     inspected `head.shape`/`head.fill`/`head.mod` via
  //     `dyn.field.toString().contains('diamond')`-style checks. None of
  //     those model enums override `toString()`, so every `.contains(...)`
  //     silently failed and every shaped notehead (`+`, `diamond`, `slash`,
  //     `x`, and the `head.shape="U+E0B3"`-style hexnum literals) fell back
  //     to the plain quarter/half/whole default — the exact
  //     `catch (_)`/`as dynamic` failure mode called out in CLAUDE.md.
  //     `Note.getNoteheadGlyph` (basic_elements.dart) already ported the
  //     method correctly and typed; `_getNoteheadGlyph` now just delegates
  //     to it. note-008.mei (all the head-shape/hexnum cases) went clean.
  // (2) `Mdiv` defaulted to `VisibilityType.visible` (the generic
  //     `VisibilityDrawingInterface` default) instead of Hidden
  //     (`Mdiv::Reset`, mdiv.cpp:42 explicitly calls `SetVisibility(Hidden)`
  //     after the base reset; only the selected `<mdiv>` — and its mdiv
  //     ancestors — are made visible again via `MakeVisible`,
  //     mei_input.dart's `readMdiv`/`readMdivChildren`). On top of that,
  //     `Doc._convertToPageBased` (doc.dart) was a plain recursive walk that
  //     never consulted `Object.skipChildren` — unlike the C++, which drives
  //     the equivalent traversal through `Object::Process`, and every
  //     functor defaults `VisibleOnly()` to `true` (functor.h:89), so
  //     `ConvertToPageBasedFunctor` never even descends into a hidden
  //     mdiv's children (`Object::SkipChildren`, object.cpp:1195). Together
  //     the two bugs meant a multi-`<mdiv>` document (mdiv-001.mei has 3)
  //     moved *every* mdiv's `<score>` content onto the single rendered
  //     page instead of only the first — extra clefs/brackets in `<defs>`
  //     (E003/E004/E052/E083) and extra systems. Fixed by giving `Mdiv` its
  //     own `reset()` override and by skipping descent into a hidden
  //     mdiv's children in `_convertToPageBased`.
  // 2026-09-01: 542 -> 551 (loop 10). Three root causes:
  // (1) `PrepareLayerElementPartsFunctor::VisitTabDurSym`
  //     (calcstemfunctor.cpp:485-573) was ported with its whole tail
  //     missing in `calc_functors.dart`: no `m_tabGrpWithNoNote` guard (a
  //     `<tabGrp><tabDurSym/></tabGrp>` place-holder with no `<note>` must
  //     stay virtual regardless of duration), no fallback to the layer's
  //     drawing stem direction (`stemDir = layerStemDir`,
  //     calcstemfunctor.cpp:526-528, needed for multi-layer tab staves),
  //     and — the main gap — no `if (staff->IsTabGuitar()) { flag->
  //     m_drawingNbFlags = ...; }` block at all, so every tab flag's
  //     `drawingNbFlags` stayed at the reset-functor default of 0 and no
  //     flag glyph was ever drawn. tab/tab-004.mei's `<defs>` now matches
  //     the golden exactly (structural divergences 32 -> 14; the remainder
  //     is an unrelated staff-line gap-count bug in `drawStaffLines`, left
  //     for a future round together with tab-005/tab-002).
  // (2) `Clef.copyFrom` (basic_elements.dart) never copied the
  //     `AttVisibility` `visible` field — the implicit "copy every base
  //     class" a C++ copy constructor gives you for free has to be spelled
  //     out by hand in Dart. A `<staffDef><clef visible="false"/></staffDef>`
  //     is materialized into the layer as the system's initial clef via
  //     `clone()`/`copyFrom` (scoredef.dart), so the hidden flag was
  //     silently dropped and a visible gClef got drawn where the C++ draws
  //     nothing. artic/artic-016.mei and chord/chord-007.mei — both using
  //     `<clef ... visible="false">` — went fully clean.
  // (3) `CalcStemFunctor.visitNote` (calc_functors.dart) resolved the stem
  //     direction of a `@stem.sameas` note by reading `note.stemDir` (the
  //     raw, almost-always-absent `@stem.dir` attribute) instead of calling
  //     the equivalent of `Note::CalcStemDirForSameasNote`
  //     (note.cpp:750-779), which compares the two linked notes' vertical
  //     positions. Every stem-sameas note therefore got `Stemdirection.none`
  //     and defaulted to an "up" flag/articulation glyph regardless of
  //     where its partner note sat. Added `_calcStemDirForSameasNote`
  //     (loc-based, matching this file's existing `m_verticalCenter`
  //     substitution) and wired it in. stem/stem-015.mei ("Flag for short
  //     values with stem sameas") dropped from 10 to 8 structural
  //     divergences (one remaining mismatch traced to the file's separate
  //     whole-`<layer sameas="...">` duplication, not investigated here).
  const int pisoEstrutural = 551;
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
