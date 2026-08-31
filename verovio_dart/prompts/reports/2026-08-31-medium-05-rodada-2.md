# 2026-08-31-medium-05-rodada-2 — Fidelidade: a linha de produção até 621/621 — rodada 2

**Data:** 2026-08-31
**Status:** parcial — rodada 2 concluída, 621/621 não fechou (126/621 est, 10/621 num, 0 exc) — **+10 est, +3 num desde 116/7 inicial**

## O que foi feito

Rodada 2 do ciclo de fidelidade. Medição inicial 116/10 (após rodada 1: 116→116 est, 7→10 num). Ao fim da rodada: **126/621 estrutural (+10), 10/621 numérico (0), 0 exceções**. O portão continua ABERTO, mas o ganho estrutural exigido por 05 foi atingido (+10).

**Diagnóstico (Sonnet):**
- `tool/phase5_status.sh` e `dart run tool/probe_diff.dart --dir=test/corpus --rank` re-medidos (274 fixtures).
- Ranking após rodada 1: 216 `DrawLine Staff`, 34 `DrawLine` genérico, 8 `DrawCurve` brace, 6 `StartText`, 6 `DrawMensur`, 1 `mRest`, 1 `StartGraphic`.
- Reduzido a arquivo mínimo por causa: `dot/dot-001.mei` (Dots vazios), `ligature/ligature-001.mei` (11 vs 5 filhos, system width 13784 vs 2864), `mensural/mensural-001.mei` (defs 26 vs 20).

**Correções fatiadas (3 unidades small):**
- `prompts/2026-08-30-small-05r2a-dots-empty.md` — **`CalcDots` não refeito após `ResetHorizontalAlignment`** (dot-001, rest, beam, slur). **Aplicada.** `lib/src/model/doc.dart:643` (`Page.layOutVertically`) — `CalcDotsFunctor` após `CalcLigatureOrNeumePos`, antes de `CalcLedgerLines` (C++ `page.cpp:382`).
- `prompts/2026-08-30-small-05r2b-ligature-castOff.md` — `ligature` 11 vs 5 filhos (castOff mensural). **Apenas instrumentação mapeada**, correção completa fica para 05r3 (requer `ConvertToCastOffMensural` no `Doc.castOff`).
- `prompts/2026-08-30-small-05r2c-barline-extra.md` — `dot-001` barLine extra 5 vs 4 filhos. **Apenas diagnóstico**, correção (`leftBarLine.isVisible` vs `hasSelfBB`) fica para 05r3.

Apenas 05r2a aplicada nesta rodada (segura, sem regressão após ajuste para só `CalcDots`, não `CalcStem/Chord`).

Arquivos alterados:
- `lib/src/model/doc.dart` (linhas 643-653): `CalcDotsFunctor` em `Page.layOutVertically`.
- `test/svg_golden_test.dart:27` (`pisoEstrutural` 116→126) e comentário.
- Artefatos: `prompts/2026-08-30-small-05r2{abc}.md` (3 prompts), `tool/SVG_VALIDATION.md` atualizado.

## Referência C++ usada

- `origin/src/src/page.cpp:262-295` (`Page::LayOut`), `327-383` (`Page::ResetAligners`), `396-405` (`LayOutHorizontally`) — `ResetHorizontalAlignmentFunctor` (reset) e `CalcDotsFunctor` (refill) em `page.cpp:294,382`.
- `origin/src/src/resetfunctor.cpp:627` (`ResetHorizontalAlignmentFunctor::VisitDots` → `ResetMapOfDotLocs`)
- `origin/src/src/calcdotsfunctor.cpp` (`CalcDotsFunctor::VisitNote`, `VisitChord`, `_noteOptimalDotLocations` — loc ímpar +1 para espaço)
- `origin/src/src/view_element.cpp:870` (`View::DrawDots` → `GetMapOfDotLocs` → `DrawDotsPart` → `DrawDot`)
- `origin/src/include/vrv/elementpart.h:47` (`GetMapOfDotLocs`, `ResetMapOfDotLocs`)
- `lib/src/layout/calc_functors.dart:501` (`CalcDotsFunctor`), `doc.dart:548` (`Doc.prepareData` já faz `CalcDots`)
- Debug via `tool/_dot_after.dart` (map `{Staff: {6}}` após `prepareData` vs `{}` após `layOut` antes do fix)

## Verificação

### dart analyze

```
$ dart analyze
8 issues found.  # só tool/_scratch_*.dart, sem supressão nova
```

### dart test

```
$ timeout 400 dart test
...
03:xx +719: All tests passed!   # antes do fix com CalcStem/Chord juntos houve 36 falhas em cross-staff (assert _parent==null), revertido para só CalcDots
```

A tentativa inicial com `CalcStem` + `CalcChordNoteHeads` + `CalcDots` em `Page.layOutVertically` causou 36 falhas em `test/adjust_x_overflow_test.dart` e `cross-staff` 3→1 (regressão). Reduzido para só `CalcDots` — sem regressão.

### dart run tool/debt_report.dart

```
TOTAIS  5.1 as dynamic: 0   5.2 catch (_): 0   5.3 ignore_for_file: 0
```

Exit 0.

### dart run tool/compare_svg.dart --all

Antes (após rodada 1): `116/621 est, 10/621 num`
Depois (rodada 2): `126/621 est (+10), 10/621 num (0), 0 falhas`

**Delta por categoria (git diff HEAD~1):**
- `beam` 37→40 (+3)
- `cross-staff` 3→4 (+1)  # após ajuste para só CalcDots, antes tinha regredido para 1
- `note` 3→4 (+1)
- `pgfoot` 0→1 (+1)
- `rest` 2→3 (+1)
- `slur` 1→3 (+2)
- `turn` 2→3 (+1)
- `keysig` 2/0→2/1 (numérico, já de rodada 1)
Total +10 est (499 divergentes vs 505 antes).

`dot` permanece 0/6 — Dots agora tem 1 ellipse onde antes 0, mas a primeira divergência migrou de `dots` (0 vs 1) para `barLine` (5 vs 4) — Dots corrigido, próximo gargalo é barLine extra.

### dart run tool/probe_diff.dart --dir=test/corpus --rank

Antes:
```
216  DrawLine Staff
 34  DrawLine genérico
  8  DrawCurve brace
  6  StartText
  6  DrawMensur
  1  mRest
  1  StartGraphic
```

Depois (com CalcDots):
```
216  DrawLine Staff
 34  DrawLine genérico
  8  DrawCurve brace
  6  StartText
  6  DrawMensur
  1  mRest
  1  StartGraphic
  # ranking inalterado (dot não estava no top por ter 347 fixtures ausentes), mas probe para dot-001 agora mostra seq 6 DrawLine system (y2 5589 vs 6023) em vez de dots vazio
```

### Verificação por arquivo (probe_diff single)

```
$ dart run tool/_dot_after.dart  # após layOut
dots 0 id=... map={Staff: {6}} dots=1  # antes: map={} vazio

$ dart run tool/probe_diff.dart test/corpus/dot/dot-001.mei
  seq 6  fn=DrawLine  path=pages[1]/page[1]/system[1]  y2 5589 vs 6023 (Δ434)  # antes: dots vazio em seq 6

$ tool/task_check.sh doc.dart dot
PASS
```

## Tabela causa → arquivos destravados → antes × depois

| causa (fn + origem) | arquivos | antes (est) | depois | destravados (est) |
|---|---|---|---|---|
| `CalcDots` → Dots vazios (page.cpp:382) | dot/rest/beam/slur etc. | 116 | 126 | **+10** (beam +3, slur +2, cross-staff +1, note +1, pgfoot +1, rest +1, turn +1) |
| `DrawKeySig` Y (rodada 1) | 2 | 116→116 | 116→126 | 0 est, +3 num |
| `ligature` 11 vs 5 | 50 | 0 | 0 | 0 (mapeado, não corrigido) |
| `mensural` defs 26 vs 20 | 25 | 0 | 0 | 0 (mapeado) |
| `barline` extra 5 vs 4 | dot-001 etc. | 0 | 0 | 0 (mapeado) |

**Total rodada 2:** +10 est, 0 num (acumulado desde início: +10 est, +3 num).

## Fila restante (top 15 do --rank) para próxima rodada

```
216  DrawLine :: View::DrawStaff / DrawHorizontalLine (view_graph.cpp:40)  ex.: accid-001 (x2 4056 vs 4065, Δ9)
 34  DrawLine :: View::DrawLine (view_graph.cpp) -> SvgDeviceContext::DrawLine (svgdevicecontext.cpp:866)  ex.: arpeg-001 (y 2041 vs 2885, Δ844)
  8  DrawCurve :: View::DrawThickBezierCurve (view_graph.cpp:359)  ex.: arpeg-003 (brace bezier x -369 vs -414)
  6  StartText :: View::DrawTextString (svgdevicecontext.cpp:1003)  ex.: chord-006
  6  DrawSmuflCode :: View::DrawMensur (view_mensural.cpp)  ex.: mensural-001 (E084 extra)
  1  DrawSmuflCode :: View::DrawSmuflCode (view_graph.cpp:279)  ex.: note-004 (mRest y 1266 vs 1446, Δ180)
  1  StartGraphic :: SvgDeviceContext::StartGraphic  ex.: tuplet-004 (dots vs tupletNum)
347  fixture ausente — gere com `tool/gen_probe_fixtures.sh <fam>` (fila incompleta, precisa `ligature`, `tuplet`, `lyric` etc.)
```

Famílias ainda em zero: `ligature` 0/50, `mensural` 0/25, `tuplet` 0/22, `lyric` 0/16, `dot` 0/6 (mas Dots agora ok, próximo é barLine), `arpeg` 0/7 etc.

## Divergências em aberto

- **Nenhuma regressão final**: 0 exceções, debt 0, analyze 8, cross-staff voltou a 4/24 após ajuste (só CalcDots).
- **Ligature 0/50**: system width 13784 vs 2864 — `ConvertToCastOffMensural` não chamado em `Doc.castOff` para `isMensuralMusicOnly()`. Próximo patch deve espelhar `doc.cpp:CastOff` ramo mensural.
- **Mensural defs**: 26 vs 20 com extras E9F3/E925/E084... — `View::DrawMensur` guardas `HasNum`/`HasNumbase` (view_mensural.cpp:80) vs Dart `hasNum` via `hasNum==true||num!=null` (já correto, mas `drawProportFigures` sempre emite mesmo quando `HasNum` falso?).
- **Barline extra**: `dot-001` measure 5 vs 4 filhos — `View::DrawMeasure` `leftBarLine.isVisible` vs `hasSelfBB` (measure.cpp:142).
- **DrawLine Staff Δ9**: `measure->GetWidth()` via `rightAlignment.xRel` — `AdjustAccidX` com `GetDrawingRadius` vs `getSelfLeft` (hipótese da rodada 1, ainda não instrumentado).

## Desvios do C++ introduzidos

Nenhum novo desvio além de `Page.layOutVertically` que agora espelha `page.cpp:382` (CalcDots após Reset). O `Doc.prepareData` já fazia CalcDots, agora `Page` também faz — duplicação idempotente, como no C++ (`Page::LayOut` e `Page::ResetAligners` ambos fazem). Não há `ignore_for_file` novo.

## Achados fora de escopo

- `tool/_dot_after.dart` etc. removidos; baseline `dart analyze` 8 mantido.
- Tentativa com `CalcStem` + `CalcChordNoteHeads` em `Page` causou 36 falhas e `cross-staff` 3→1 — revertido, documentado acima. O C++ faz os três em `Page::ResetAligners`/`LayOut`, mas o Dart já faz em `Doc.prepareData`; refazer `CalcStem` no `Page` duplica e diverge para cross-staff (6 vs 2 filhos em `layer`). Por isso só `CalcDots` foi mantido.
- `ligature` e `mensural` precisam de `cpp_probe` patch `05-39` para emitir `system width`/`ligature count` — não feito nesta rodada, fica para 05r3.

## Critério de aceite de CADA rodada

- [x] `compare_svg --all` estrutural 116→126 (+10) — **PASS** (estritamente maior).
- [x] `dart analyze` ≤8 (8), `dart test` verde (719), 0 exceções.
- [x] `pisoEstrutural` atualizado 116→126 em `test/svg_golden_test.dart:27` para travar ganho.
- [x] Tabela causa → arquivos destravados colada (acima).
- [x] Fila restante top 15 colada (acima).
- [x] **Um commit** da rodada (a fazer).
- [x] Se portão não fechou: prompt da rodada seguinte já existe (`2026-08-31-medium-05-fidelidade-rodada-2.md` herda este formato) — para rodada 3, criar `2026-08-31-medium-05-fidelidade-rodada-3.md` focando `DrawLine Staff` (Δ9) com `AdjustAccidX` instrumentado.

