# 2026-08-31-medium-05-fidelidade-rodada-4 — Fidelidade: a linha de produção até 621/621 — rodada 4

> Você é o **Sonnet**. Leia `prompts/00-MESTRE.md` (§10) e `CLAUDE.md`.
> Depende de `2026-08-30-medium-01` (instrumento) e das `02`/`03`/`04` (tipagem zerada).
> Herda o formato de `2026-08-30-medium-05-fidelidade-linha-de-producao.md` rodada 3.

**Este prompt é um ciclo, não uma tarefa.** Cada rodada termina com um commit e com o placar atualizado.

## O alvo, sem maquiagem

O critério 5.6 exige **621/621 limpos nos dois modos** — estrutural e numérico com epsilon 0 — e **0 exceções**.

Estado após rodada 3 (2026-08-31): **126/621 estrutural, 12/621 numérico, 0 exceções**.
Rodada 3 fixou `System.setDrawingScoreDef` parent (StartGraphic 37→1) e `Doc.drawingBeamWhiteWidth` (DrawCurve brace 8→0, numérico 10→12). O portão continua ABERTO; estrutural não subiu.

## O ciclo, uma rodada (rodada 4)

### 1. Medir e ranquear

```bash
tool/phase5_status.sh --full
dart run tool/probe_diff.dart --dir=test/corpus --rank > /tmp/rank.txt
head -30 /tmp/rank.txt
```

Fila ao fim da rodada 3:
```
224  DrawLine :: View::DrawStaff / DrawHorizontalLine (view_graph.cpp:40)  ex.: accid-001 (x2 4056 vs 4065 Δ9), arpeg-003 (x2 4857 vs 4849 Δ-8), ligature-001 (x2 2864 vs 13784 Δ10920)
 34  DrawLine :: View::DrawLine (view_graph.cpp) -> SvgDeviceContext::DrawLine (svgdevicecontext.cpp:866)  ex.: arpeg-001 (y 2041 vs 2885 Δ844), dot-001 (y2 5589 vs 6023 Δ434)
  6  StartText :: View::DrawTextString (svgdevicecontext.cpp:1003)  ex.: chord-006 (y 1026 vs 1935 Δ909)
  6  DrawSmuflCode :: View::DrawMensur (view_mensural.cpp)  ex.: mensural-001 (defs 26 vs 20, E9F3 extra)
  1  DrawSmuflCode :: View::DrawSmuflCode (view_graph.cpp:279)  ex.: note-004 (mRest y 1266 vs 1446 Δ180)
  1  StartGraphic :: SvgDeviceContext::StartGraphic  ex.: tuplet-004 (tupletNum vs dots)
```

Famílias em zero: `ligature` 0/50 (11 vs5 children, system width 13784 vs 2864), `mensural` 0/25 (defs), `tuplet` 0/22, `lyric` 0/16, `dot` 0/6 (agora DrawLine generic), `arpeg` 0/7 etc.

### 2. Escolher as causas da rodada

Pegue as **3 a 6 causas do topo que couberem**, priorizando **estruturais** e **alto impacto**. Para esta rodada, recomenda-se:

1. **DrawLine Staff Δ9** (224-75=~149 arquivos sem ligature/mensural) — `AdjustAccidX` / `measure->GetWidth()` — `accid-001` é o menor do grupo. Instrumente `adjustaccidxfunctor.cpp` para emitir `xRel_in/out` por `accid` (como 04b) e compare com `tool/gen_probe_fixtures.sh accid`. Hipótese: `HorizontalRightOverlap` com `Resources` / `GetDrawingRadius` vs `getSelfLeft`.
2. **Ligature castOff 50+25** — `ligature-001` 11 vs5 filhos / system width 13784 vs 2864. Instrumente `convertfunctor.cpp:IsValidBreakPoint` (alignment `type`, `nbLayers`, `ligatureAsBracket`) e `MeasureAligner` children por ligature. Arquivo mínimo: `ligature/ligature-001.mei`.
3. **DrawLine genérico Δ844** (34 arquivos) — `arpeg-001` y 2041 vs 2885 (FloatingPositioner Y de `Arpeg`). Instrumente `view_control.cpp:DrawArpeg` / `adjustarpegfunctor.cpp` / `FloatingPositioner::GetContentTop`.

Para cada uma:
1. Reduza a um arquivo mínimo.
2. Leia o método C++ inteiro.
3. Compare com o Dart lado a lado.
4. Formule a correção **você**, não o Haiku.
5. Se ler o `.cpp` não explicar, instrumente com novo patch `05-39`/`05-40` (só acréscimo, diff SVG vazio).

### 3. Fatiar para o Haiku

Uma unidade `small` por causa. Use `prompts/2026-08-30-small-TEMPLATE.md`,
gravando como `prompts/2026-08-30-small-05r4<letra>-<slug>.md`.

O Haiku só termina quando `probe_diff` 0 e `task_check.sh` PASS.

### 4. Fechar a rodada

```bash
dart run tool/compare_svg.dart --all
dart run tool/verify_phases.dart --fase=5
dart test
```

- O número estrutural **tem de subir** (126 → >126).
- Atualize `pisoEstrutural` em `test/svg_golden_test.dart`.
- **Um commit** da rodada.

### 5. Decidir

```bash
tool/phase5_status.sh
```

- Exit 0 → Fase 5 fechou → `2026-08-30-medium-06`.
- Exit ≠0 → escreva `prompts/2026-08-31-medium-05-fidelidade-rodada-5.md`.

## Causas já medidas (ponto de partida da rodada 4)

| família | estado | o que o instrumento já disse |
|---|---|---|
| `ligature` | 0/50 | 11 vs5 filhos, system width 13784 vs 2864 — `ConvertToCastOffMensural` com break points (IsValidBreakPoint nbLayers/type) não gerando 4 segmentos |
| `mensural` | 0/25 | defs 26 vs20 com extras E9F3/E925/E084, DrawLine Staff 11183 vs 20000 — mesmo ramo mensural |
| `tuplet` | 0/22 | `tupletNum` vs `dots` em tuplet-004 (StartGraphic 6 vs2 filhos em layer) |
| `dot` | 0/6 | barLine extra 5 vs4 após Dots fix, mas probe agora DrawLine generic y 5589 vs 6023 |
| `accid` | 9/14 | `accid-001` DrawLine Staff Δ9 (measure width) — AdjustAccidX |
| `arpeg` | 0/7 | `arpeg-001` DrawLine y Δ844 (FloatingPositioner) — AdjustArpeg |

Hipótese para `accid` Δ9: `AdjustAccidX` usa `getSelfLeft()` vs `GetDrawingRadius` + `HorizontalRightOverlap` com `Resources` (glyph cutout).

## Regras que não negociam

- **Nunca** ajuste número sem entender fórmula do C++.
- **Nunca** relaxe catraca/portão.
- **Nunca** marque Fase 5 concluída sem `verify_phases --fase=5` 0.

## Critério de aceite

- [ ] `compare_svg --all` estrutural >126.
- [ ] `dart analyze` ≤8; `dart test` verde; 0 exceções.
- [ ] `pisoEstrutural` atualizado.
- [ ] Tabela causa → arquivos + fila top 15 no relatório.
- [ ] **Um commit**.
- [ ] Se não fechou: próxima rodada escrita e indexada em `prompts/README.md`.
