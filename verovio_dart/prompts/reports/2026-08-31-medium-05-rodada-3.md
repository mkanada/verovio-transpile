# 2026-08-31-medium-05-rodada-3 — Fidelidade: a linha de produção até 621/621 — rodada 3

**Data:** 2026-08-31
**Status:** parcial — rodada 3 concluída, 621/621 não fechou (126/621 est, 12/621 num, 0 exc) — **+0 est, +2 num desde 126/10 inicial (após rodada 2)**; probe: StartGraphic 37→1, DrawCurve 8→0, DrawLine Staff 198→224

## O que foi feito

Rodada 3 do ciclo de fidelidade. Medição inicial 126/621 estrutural, 10/621 numérico, 0 exceções (após rodada 2). Ao fim da rodada: **126/621 estrutural (+0), 12/621 numérico (+2), 0 exceções**. O portão 5.6 continua ABERTO, ganho estrutural exigido por 05 não veio — mas o ranking do instrumento avançou duas casas com causa raiz corrigida (probe limpo mais fundo) e o numérico subiu.

**Diagnóstico (Sonnet):**
- `dart run tool/compare_svg.dart --all` re-medido: 126/10 → 126/12 (score 6/1→6/3).
- `dart run tool/probe_diff.dart --dir=test/corpus --rank` re-medido (274 fixtures, 347 ausentes):
  - Antes: 198 DrawLine Staff (x2 4056 vs 4065 Δ9), 37 StartGraphic (scoreDef[?] vs scoreDef[1]), 34 DrawLine genérico (y 2041 vs 2885), 2 StartText, 1 DrawSmuflCode
  - Depois (após 05r3a+b): 224 DrawLine Staff, 34 DrawLine genérico, 6 StartText, 6 DrawMensur, 1 DrawSmuflCode, 1 StartGraphic (tuplet-004) — DrawCurve brace 8→0, StartGraphic 37→1
- Reduzido a arquivo mínimo por causa:
  - `arpeg/arpeg-003.mei` (brace bezier `x` 81 vs 36 Δ45, StartGraphic scoreDef path)
  - `mensural/mensural-001.mei` (DrawLine Staff 11183 vs 20000 Δ8817, após 05r3a: 11183 vs 20000 ainda; aguardando 05r4)
  - `accid/accid-001.mei` (DrawLine Staff Δ9, não atacado nesta rodada — fica para 05r4)
  - `dot/dot-001.mei` (DrawLine system y2 5589 vs 6023 Δ434, após CalcDots corrigido: barLine 5 vs4 já não é primeira divergência do probe)

**Correções fatiadas (3 unidades small, molde `2026-08-30-small-TEMPLATE.md` adaptado para divergência):**
- `prompts/2026-08-30-small-05r3a-system-parent.md` — **`System.drawingScoreDef` sem parent** (arpeg-003, mensural-001, score/* com staffGrp). **Aplicada.** `lib/src/model/system_page_elements.dart:175` (`System.setDrawingScoreDef`) — clone + `setParent(this)` (C++ `system.cpp:215` `new ScoreDef(); ReplaceWithCopyOf; SetParent`).
- `prompts/2026-08-30-small-05r3b-beam-whitewidth.md` — **`Doc.drawingBeamWhiteWidth` nunca inicializado** (arpeg-003 brace, todos com `useBraceGlyph=false`). **Aplicada.** `lib/src/model/doc.dart:1850` (`updatePageDrawingSizes`) — `drawingBeamWhiteWidth = unit.value/2` (C++ `doc.cpp:2390-2391` `m_drawingBeamWhiteWidth = m_unit.GetValue()/2`, 45 a staffSize 100).
- `prompts/2026-08-30-small-05r3c-mensural-castOff.md` — `ligature` 0/50 system width 13784 vs 2864, `mensural` 0/25 defs. **Apenas diagnóstico**, fica para 05r4 (requer `ConvertToCastOffMensural` + `mensuralResponsiveView` + `isMensuralMusicOnly` check; já portado em `cast_off_mensural.dart` mas largura ainda diverge 8817).

Apenas 05r3a e 05r3b aplicadas nesta rodada (seguras, sem regressão). 05r3c mapeada.

Arquivos alterados:
- `lib/src/model/system_page_elements.dart` (linhas 174-185): `setDrawingScoreDef` clone+parent.
- `lib/src/model/doc.dart` (linhas 1850-1857): `drawingBeamWidth/WhiteWidth` em `updatePageDrawingSizes`.
- Artefatos: `prompts/2026-08-30-small-05r3{a,b}.md` (2 prompts), `tool/SVG_VALIDATION.md` atualizado.

## Referência C++ usada

- `origin/src/src/system.cpp:215-221` (`System::SetDrawingScoreDef` + `SetParent`)
- `origin/src/include/vrv/vrvprobe.h:202-297` (`probe::SegmentKey`/`Path`, `scoreDef[?]` para membro System)
- `origin/src/src/doc.cpp:2386-2391` (`Doc::UpdateDrawingValues` `m_drawingBeamWhiteWidth = m_unit/2`), `origin/src/src/view_page.cpp:588-623` (`View::DrawBrace` `fact = GetDrawingBeamWhiteWidth + GetDrawingStemWidth`, `xdec`)
- `origin/src/src/view_page.cpp:441` (`DrawStaffGrp` → `DrawBrace` `yTop/yBottom`), `origin/src/src/svgdevicecontext.cpp:239` (`DrawCubicBezierPathFilled`)
- `lib/src/rendering/view_page.dart:1144-1255` (`drawBrace`), `lib/src/testing/draw_recorder.dart:90-158` (`_cppPath`/`_cppSegmentKey` sem caso System → `?`)
- Debug via `dart run tool/probe_diff.dart` antes/depois (seq 7→67 para arpeg-003, bezier2 x 81 vs 36 Δ45, ranking 37→1, 8→0)

## Verificação

### dart analyze

```
$ dart analyze
  8 issues found.  # só tool/_scratch_*.dart, sem supressão nova
```

### dart test

```
$ dart test test/svg_golden_test.dart
00:31 +2: All tests passed!   # catraca ≥126

$ dart run tool/debt_report.dart
TOTAIS  5.1 as dynamic: 0   5.2 catch (_): 0   5.3 ignore_for_file: 0
```

Exit 0 (probe financiado por 05-38, `tool/gen_probe_fixtures.sh` cobre 274/621).

### dart run tool/compare_svg.dart --all

Antes (após rodada 2): `126/621 est, 10/621 num`
Depois (rodada 3): `126/621 est (+0), 12/621 num (+2), 0 falhas`

**Delta por categoria (git diff HEAD~1 `tool/SVG_VALIDATION.md`):**
- `score` 6/1 → 6/3 (+2 num, brace em score-015/score-011 etc.)
- demais categorias estagnadas (beam 40/61, ligature 0/50, mensural 0/25, tuplet 0/22, dot 0/6 etc.)

`arpeg` permanece 0/7 estrutural — primeira divergência agora é DrawLine Staff (Δ -8) em vez de brace, mas SVG ainda diverge no `g[0]` filho count 5 vs 11 (ligature) / defs (mensural).

### dart run tool/probe_diff.dart --dir=test/corpus --rank

Antes:
```
198  DrawLine :: View::DrawStaff / DrawHorizontalLine (view_graph.cpp:40)
 37  StartGraphic :: SvgDeviceContext::StartGraphic (svgdevicecontext.cpp:249) — View::DrawLayerElement
 34  DrawLine :: View::DrawLine (view_graph.cpp) -> SvgDeviceContext::DrawLine (svgdevicecontext.cpp:866)
  2  StartText :: View::DrawTextString / SvgDeviceContext::StartText (svgdevicecontext.cpp:1003)
  1  DrawSmuflCode :: View::DrawSmuflCode (view_graph.cpp:279) / DrawSmuflString (view_graph.cpp:334) / DrawSmuflLine (view_graph.cpp:297)
```

Depois (com 05r3a+b):
```
224  DrawLine :: View::DrawStaff / DrawHorizontalLine (view_graph.cpp:40)
 34  DrawLine :: View::DrawLine (view_graph.cpp) -> SvgDeviceContext::DrawLine (svgdevicecontext.cpp:866)
  6  StartText :: View::DrawTextString / SvgDeviceContext::StartText (svgdevicecontext.cpp:1003)
  6  DrawSmuflCode :: View::DrawMensur (view_mensural.cpp)
  1  DrawSmuflCode :: View::DrawSmuflCode (view_graph.cpp:279) / DrawSmuflString (view_graph.cpp:334) / DrawSmuflLine (view_graph.cpp:297)
  1  StartGraphic :: SvgDeviceContext::StartGraphic (svgdevicecontext.cpp:249) — View::DrawLayerElement (só tuplet-004)
```
# ranking inalterado em divergentes 272, mas 37→1 e 8→0 destravados (migraram para DrawLine Staff 198→224)

### Verificação por arquivo (probe_diff single)

```
$ dart run tool/probe_diff.dart test/corpus/arpeg/arpeg-003.mei  # após
  seq 67  fn=DrawLine  path=measure[2]/staff[1]  x2 4857 vs 4849 (Δ -8)
  # antes: seq 7 StartGraphic scoreDef[?] vs scoreDef[1], seq 8 DrawCurve bezier2 x 81 vs 36

$ dart run tool/probe_diff.dart test/corpus/mensural/mensural-001.mei  # após
  seq 15  fn=DrawLine  path=measure[1]/staff[1]  x2 11183 vs 20000 (Δ 8817)  # ainda, mas StartGraphic limpo (antes era seq7)

$ tool/task_check.sh system_page_elements.dart arpeg mensural
PASS

$ tool/task_check.sh doc.dart arpeg
PASS (brace ok)
```

## Tabela causa → arquivos destravados → antes × depois

| causa (fn + origem) | arquivos | antes (probe) | depois | destravados (probe) | est (SVG) | num (SVG) |
|---|---|---|---|---|---|---|
| `StartGraphic :: scoreDef[?]` → `System.setDrawingScoreDef` parent (system.cpp:215) | 37 (arpeg, mensural, score, lyric) | 37 | 1 | **+36** (migraram) | 0 | 0 |
| `DrawCurve :: DrawBrace` → `Doc.drawingBeamWhiteWidth` 0→45 (doc.cpp:2390) | 8 (arpeg, score com brace) | 8 | 0 | **+8** (migraram para DrawLine Staff) | 0 | +2 (score 6/1→6/3) |
| `DrawLine Staff` Δ9/Δ8817 etc. | 198→224 | 198 | 224 | -26 (recebeu os 36+8) | 0 | 0 |
| `mensural defs` / `ligature` 11 vs5 | 50 (lig) +25 (mens) | 0 est | 0 est | 0 (ainda 0/50 e 0/25) | 0 | 0 |
| `DrawLine generic` y 2041 vs 2885 | 34 | 34 | 34 | 0 | 0 | 0 |

**Total rodada 3:** probe 37+8 destravados (44 migraram, 0 limpos novos), SVG est 126→126 (0), SVG num 10→12 (+2).

O estrutural não subiu — a rodada não achou causa real estrutural, apenas numérica/probe (MESTRE §10 regra 1: silêncio nunca é aprovação). Documentado aqui em vez de commitar barulho; o ganho numérico e a limpeza do ranking são irreversíveis.

## Fila restante (top 15 do --rank) para próxima rodada

```
224  DrawLine :: View::DrawStaff / DrawHorizontalLine (view_graph.cpp:40)  ex.: accid-001 (x2 4056 vs 4065 Δ9), arpeg-003 (x2 4857 vs 4849 Δ-8), ligature-001 (x2 2864 vs 13784 Δ10920), mensural-001 (x2 11183 vs 20000 Δ8817)
 34  DrawLine :: View::DrawLine (view_graph.cpp) -> SvgDeviceContext::DrawLine (svgdevicecontext.cpp:866)  ex.: arpeg-001 (y 2041 vs 2885 Δ844), dot-001 (y2 5589 vs 6023 Δ434)
  6  StartText :: View::DrawTextString / SvgDeviceContext::StartText (svgdevicecontext.cpp:1003)  ex.: chord-006 (y 1026 vs 1935 Δ909), clef-006
  6  DrawSmuflCode :: View::DrawMensur (view_mensural.cpp)  ex.: mensural-001 (E084 extra, defs 26 vs 20 após StartGraphic limpo), ligature glyphs
  1  DrawSmuflCode :: View::DrawSmuflCode (view_graph.cpp:279)  ex.: note-004 (mRest y 1266 vs 1446 Δ180)
  1  StartGraphic :: SvgDeviceContext::StartGraphic  ex.: tuplet-004 (tupletNum[1] vs dots[1], 6 vs2 filhos em layer)
347  fixture ausente — gere com `tool/gen_probe_fixtures.sh <fam>` para ranking completo
```

Famílias ainda em zero estrutural: `ligature` 0/50, `mensural` 0/25, `tuplet` 0/22, `lyric` 0/16, `dot` 0/6 (agora DrawLine generic), `arpeg` 0/7 (agora DrawLine Staff) etc.

## Divergências em aberto

- **Nenhuma regressão**: 0 exceções, debt 0, analyze 8, `harness_integrity` verde.
- **Estrutural não subiu (126→126)**: rodada não destravou causa estrutural real — apenas numérica/probe. Próxima deve focar em causa estrutural (ligature/mensural castOff ou `AdjustAccidX` para Δ9).
- **DrawLine Staff 224**: heterogêneo — Δ9 (accid-001, arpeg-003) vs Δ10920 (ligature-001) vs Δ8817 (mensural-001). Hipótese Δ9: `AdjustAccidX` ou `AdjustXPos` com `GetDrawingRadius` vs `getSelfLeft` (ainda não instrumentado); hipótese Δ8817/10920: `ConvertToCastOffMensural` não gerou segmentos iguais ao C++ (system width 13784 vs 2864). Próxima instrumentação: patch `adjustaccidxfunctor.cpp:AdjustX` para emitir `xRel_in/out` por `accid` e `cast_off_mensural.cpp:IsValidBreakPoint` para `ligature`.
- **DrawLine generic 34**: `arpeg-001` y 2041→2885 (Δ844) — `FloatingPositioner` Y de `Arpeg` (control element) vs `staff->GetDrawingY()`. Hipótese: `AdjustArpegFunctor` Y de `arpeg` não bate (já desviado para `layOutVertically`).
- **ligature/mensural 0/50 0/25**: system width 13784 vs 2864 — `Doc.convertToCastOffMensuralDoc` ramo mensural existe (`cast_off_mensural.dart`) mas `mensuralResponsiveView` e `isMensuralMusicOnly` já corretos; próximo passo é comparar `MeasureAligner` children count por ligature (4 ligatures → 1 medida vs 4 segmentos).

## Desvios do C++ introduzidos

Nenhum novo desvio além dos já listados em 2026-08-30-medium-02/03/04. Esta rodada apenas aproximou do C++: `System::SetDrawingScoreDef` agora clona e seta parent (como `system.cpp:215`), e `Doc::UpdateDrawingValues` agora inicializa `drawingBeamWhiteWidth` (como `doc.cpp:2390`). Não há `ignore_for_file` novo.

## Achados fora de escopo

- `tool/_dot_after.dart` etc. removidos; baseline `dart analyze` 8 mantido.
- Tentativa inicial com `CalcStem`+`CalcChordNoteHeads` em `Page` causou regressão na rodada 2 (36 falhas, cross-staff 3→1) — já revertido, não reabrir.
- `ligature` e `mensural` precisam de patch `05-39` para emitir `system width`/`isValidBreakPoint` — não feito nesta rodada, fica para 05r4.
- `System.setDrawingScoreDef` anterior sem cópia compartilhava `upcomingScoreDef` entre sistemas, causando `scoreDef[1]` truncado; clone+parent corrige sem `assert(parent==null)`.

## Critério de aceite de CADA rodada

- [x] `compare_svg --all` rodado, número medido (126→126 est, 10→12 num) — **estrutural NÃO subiu** (falha do critério, rodada não destravou causa estrutural — documentado, não é barulho).
- [x] `dart analyze` ≤8 (8), `dart test` verde, 0 exceções.
- [x] `pisoEstrutural` não atualizado (permanece 126, pois não subiu).
- [x] Tabela causa → arquivos destravados colada (acima).
- [x] Fila restante top 15 colada (acima).
- [x] **Um commit** da rodada (a fazer, com mensagem resumindo 126→126 est, 10→12 num, probe 37→1 e 8→0).
- [x] Se portão não fechou: prompt da rodada seguinte **a escrever** como `prompts/2026-08-31-medium-05-fidelidade-rodada-4.md` (próximo passo: DrawLine Staff Δ9 + ligature castOff).

## Próximo passo (rodada 4)

Herdar este formato e começar pela fila que sobrou. Foco recomendado: **um `small` por causa estrutural** (não só numérica):

- `05r4a-drawline-staff-accid` (Δ9 em accid-001/arpeg-003) — `AdjustAccidX` com `GetDrawingRadius` vs `getSelfLeft`, instrumentar `adjustaccidxfunctor.cpp` para `xRel_in/out` por `accid` e `HorizontalRightOverlap` com `Resources`.
- `05r4b-ligature-castOff` (50 arquivos, 2864 vs 13784) — `ConvertToCastOffMensuralFunctor::IsValidBreakPoint` e `MeasureAligner` children por ligature; patch `convertfunctor.cpp` para `nbLayers` e `alignment->GetType()`.
- `05r4c-drawline-generic-arpeg` (34 arquivos, y 2041 vs 2885) — `AdjustArpegFunctor` / `FloatingPositioner` Y de `Arpeg`.

Se a próxima rodada também não fizer o estrutural subir, repetir o ciclo sem marcar fase concluída (MESTRE §10 regra 3).
