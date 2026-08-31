# 2026-08-31-fidelidade-loop-03 — Interface getters + DrawDynamString + quirk do octave — 325→396 est

## Placar

| métrica | antes | depois | delta |
|---|---|---|---|
| Estrutural (compare_svg --all) | 325/621 | **396/621** | **+71 (+22%)** |
| Numérico (eps=0.0) | 51/621 | 62/621 | +11 |
| Exceções | 0 | 0 | 0 |
| dart analyze | 8 | 8 | 0 |

## Causas raiz corrigidas (9 unidades, todas confirmadas por probe/fixture C++)

1. **`Object.getXxxInterface()` ausentes** (`lib/src/model/object.dart`): o rendering
   chama `getTimePointInterface()`/`getTimeSpanningInterface()`/`getTextDirInterface()`
   (view_control.dart ×7) mas nenhum modelo definia — cada chamada caía em
   NoSuchMethodError silenciado por catch vazio → **dir/dynam/harm/tempo inteiros não
   desenhavam nada** (`<g class="dynam" />` vazio; `dir` nem StartGraphic emitia).
   Port de `object.h:166-196` via `this is XxxInterface ? this : null` (mixin Dart
   equivale ao `vrv_cast` C++).
2. **`DrawControlElement` com else** (view_control.dart): o C++ (view_control.cpp:72-170)
   **não tem else** — mNum é desenhado por `DrawMeasure` (view_page.cpp:1005). O else
   desviava mNum para `drawControlElementText` com start null → NPE no
   `_renderBoundingBoxes` do castOff. Removido.
3. **`DrawDynamString` usava `drawMusicText`** (view_text.dart:117): o C++ chama
   `DrawTextString` → `dc->DrawText` → `<tspan font-family="Leipzig">` (que dispara
   `VrvTextFont()` → @font-face woff2 embutido no `Commit()` — o `<style>` final da
   raiz, o "5 vs 4 filhos" da raiz svg). Fix: `drawTextString(dc, smuflStr, params)`.
4. **`drawControlElementText` reescrito tipado** (view_control.dart:1463): espelha
   view_control.cpp:1745-1822 (isBetweenStaves, xAdjust, GetTextXHeight), remove
   fallback `start!.getFirstAncestor` não-C++ e silent catches; `Measure.getFirstStaff/`
   `getLastStaff` portados (measure.cpp:481-520).
5. **`TextDirInterface.areChildrenAlignedTo`** (simple_interfaces.dart): port de
   textdirinterface.cpp:46 — o método era chamado e não existia.
6. **pgHead composer: quirk do xpath pugixml** (doc.dart `_findMeiPersonNodes`): o xpath
   `//fileDesc/titleStmt/composer|arranger|lyricist|respStmt/persName[...]` (pghead.cpp:83)
   tem os últimos três termos RELATIVOS ao documento — só `<composer>` filho direto de
   titleStmt casa. O Dart casava persName em qualquer lugar → composer duplicado/extra.
   Ex.: beam-049 pgHead 2 texts vs 1.
7. **Quirk `LINESTARTENDSYMBOL_NONE` vs `_none`** (view_control.dart drawOctave): o C++
   testa `!= LINESTARTENDSYMBOL_none` (valor MEI "none", 20) e não `_NONE` (default
   unset, 0) — **o hook do octave é desenhado por default** (view_control.cpp:931).
   Dart excluía os dois → `<polyline>` do hook faltava (octave 0/4 → 3/4).
8. **`TupletBracket.alignedNum` nunca setado** (adjust_tuplets.dart): `TupletNum::
   SetAlignedBracket` (elementpart.cpp:265) seta os DOIS lados; o Dart só o num→bracket.
   Sem o back-pointer, `DrawTupletBracket` nunca usava a variante "bracket com gap"
   (2 polylines, view_tuplet.cpp:131-132) → tuplet 8/22 → 13/22.
9. **`LayersInTimeSpanFunctor` portado** (`lib/src/layout/find_layer_elements.dart` +
   `Layer.getLayersNInTimeSpan/getLayerCountForTimeSpanOf/getDrawingStemDirFor`):
   layer.cpp:301-379 + findlayerelementsfunctor.cpp. `CalcArticFunctor.visitArtic` agora
   usa o overload `GetDrawingStemDir(m_parent)` do C++ (antes: no-arg, direção errada).
10. **`BeamElementCoord.setDrawingStemDir`** (beam_segment.dart): stub vazio → propaga
    `m_stem->SetDrawingStemDir(stemDir)` (beam.cpp:1867) chamado de `calcBeam`
    (beam.cpp:912-936 CalcBeamPosition). Stems de beamed chords recebem a direção
    resolvida do beam → staccato above/below correto (E4A2/E4A3, barline-003/007 idem).

## Instrumentação C++ nova

- `cpp_probe/patches/05-39.patch`: fprintf em `CalcArticFunctor::VisitArtic`
  (stemDir/layerStemDir/place/count por artic). SVG invariante verificado
  (`diff` clean vs probe vazio). Provou que `layerStemDir=0 (NONE) count=1` sempre em
  beam-049 — o place vem do `m_stemDir` do beam, não da layer.
- `tool/gen_probe_fixtures.sh artic` → 19 fixtures 05-38/artic gerados.

## Verificação

- `dart run tool/compare_svg.dart --all`: 325 → 396 est, 51 → 62 num, 0 falhas.
- `dart test test/svg_golden_test.dart test/harness_integrity_test.dart`: verde
  (ratchet 325→396; integrity: dir-001 ficou limpo — substituído por mensural-001).
- `dart test` completo: **10 falhas, todas pré-existentes no baseline a377005**
  (verificado por git stash: horizontal/vertical_layout functor-sequence, scoredef/
  text setCurrentPageNum, floating_positioners slur-collision, adjust_accid_artic
  8/12, adjust_beams clef-004). Nenhuma regressão introduzida.
- `dart analyze`: 8 (baseline).

## Divergências em aberto (fila por contagem, `tool/_tmp_loop/rankall` — removido)

- 21→24 arquivos com 1 divergência estrutural cruzaram o zero nesta rodada; restam
  causas heterogêneas de contagem 1 (ossia barLine path, layer-015 4 vs 7 filhos,
  beam-060 37 vs 14 filhos, beam-049 10 vs 12, arpeg-001/003 DrawLine y).
- `ligature` 34/50, `mensural` 0/25, `lyric` 2/16, `dot` 2/6, `dynam` 0/10 seguem.

## Próximo passo

Continuar o loop: rankall → atacar clusters de contagem 1-2 (ossia barLine, arpeg
DrawLine y Δ844 do FloatingPositioner, beam-060) e depois as famílias inteiras em zero.
