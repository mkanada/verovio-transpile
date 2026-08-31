# 2026-08-31-medium-05-fidelidade-rodada-3 — Fidelidade: a linha de produção até 621/621 — rodada 3

> Você é o **Sonnet**. Leia `prompts/00-MESTRE.md` (§10) e `CLAUDE.md`.
> Depende de `2026-08-30-medium-01` (instrumento) e das `02`/`03`/`04` (tipagem zerada).
> Herda o formato de `2026-08-30-medium-05-fidelidade-linha-de-producao.md` rodada 2.

**Este prompt é um ciclo, não uma tarefa.** Cada rodada termina com um commit e com o placar atualizado.

## O alvo, sem maquiagem

O critério 5.6 exige **621/621 limpos nos dois modos** — estrutural e numérico com epsilon 0 — e **0 exceções**.

Estado após rodada 2 (2026-08-31): **126/621 estrutural, 10/621 numérico, 0 exceções**.
Rodada 2 fixou `CalcDots` em `Page.layOutVertically` (Dots vazios → +10 est). O portão continua ABERTO.

## O ciclo, uma rodada (rodada 3)

### 1. Medir e ranquear

```bash
tool/phase5_status.sh --full
dart run tool/probe_diff.dart --dir=test/corpus --rank > /tmp/rank.txt
head -30 /tmp/rank.txt
```

Fila ao fim da rodada 2:
```
216  DrawLine :: View::DrawStaff / DrawHorizontalLine (view_graph.cpp:40)  ex.: accid-001 (x2 4056 vs 4065, Δ9)
 34  DrawLine :: View::DrawLine (view_graph.cpp) -> SvgDeviceContext::DrawLine (svgdevicecontext.cpp:866)  ex.: arpeg-001 (y 2041 vs 2885)
  8  DrawCurve :: View::DrawThickBezierCurve (view_graph.cpp:359)  ex.: arpeg-003 (brace)
  6  StartText :: View::DrawTextString (svgdevicecontext.cpp:1003)  ex.: chord-006
  6  DrawSmuflCode :: View::DrawMensur (view_mensural.cpp)  ex.: mensural-001
  1  DrawSmuflCode :: View::DrawSmuflCode (view_graph.cpp:279)  ex.: note-004
  1  StartGraphic :: SvgDeviceContext::StartGraphic  ex.: tuplet-004
```

Famílias em zero: `ligature` 0/50 (11 vs 5 filhos, system width), `mensural` 0/25 (defs), `tuplet` 0/22, `lyric` 0/16, `dot` 0/6 (agora barLine 5 vs 4), `arpeg` 0/7 etc.

### 2. Escolher as causas da rodada

Pegue as **3 a 6 causas do topo que couberem**, priorizando **estruturais** e **alto impacto**. Para esta rodada, recomenda-se:

1. **DrawLine Staff Δ9** (216 arquivos) — `AdjustAccidX` / `measure->GetWidth()` — `accid-001` é o menor do grupo. Instrumente `adjust_accid_x.cpp` para emitir `xRel_in/out` por `accid` (como 04b) e compare com `tool/gen_probe_fixtures.sh accid`.
2. **DrawLine genérico Δ844** (34 arquivos) — `arpeg-001` y 2041 vs 2885 (FloatingPositioner Y de `Arpeg`). Instrumente `view_control.cpp: DrawArpeg` / `adjust_arpeg.cpp`.
3. **DrawCurve brace** (8 arquivos) — `arpeg-003` bezier x -369 vs -414 (xdec = beamWhiteWidth+stemWidth). Verifique `doc->GetDrawingBeamWhiteWidth` vs Dart.
4. Se sobrar tempo: `mensural defs` (6 arquivos) — `View::DrawMensur` guardas `HasNum`.

Para cada uma:
1. Reduza a um arquivo mínimo.
2. Leia o método C++ inteiro.
3. Compare com o Dart lado a lado.
4. Formule a correção **você**, não o Haiku.
5. Se ler o `.cpp` não explicar, instrumente com novo patch `05-39`/`05-40` (só acréscimo, diff SVG vazio).

### 3. Fatiar para o Haiku

Uma unidade `small` por causa. Use `prompts/2026-08-30-small-TEMPLATE.md`,
gravando como `prompts/2026-08-30-small-05r3<letra>-<slug>.md`.

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
- Exit ≠0 → escreva `prompts/2026-08-31-medium-05-fidelidade-rodada-4.md`.

## Causas já medidas (ponto de partida da rodada 3)

| família | estado | o que o instrumento já disse |
|---|---|---|
| `ligature` | 0/50 | 11 vs 5 filhos, system width 13784 vs 2864 — `ConvertToCastOffMensural` não chamado |
| `mensural` | 0/25 | defs 26 vs 20 com extras E9F3/E925/E084 — `DrawMensur` guardas |
| `tuplet` | 0/22 | `tupletNum` vs `dots` em `tuplet-004` (6 vs 2 filhos em layer) |
| `dot` | 0/6 | barLine extra 5 vs 4 após Dots fix |
| `accid` | 9/14 | `accid-001` DrawLine Staff Δ9 (measure width) |
| `arpeg` | 0/7 | `arpeg-001` DrawLine y Δ844 (FloatingPositioner) |

Hipótese para `accid`: `AdjustAccidX` usa `getSelfLeft()` vs `GetDrawingRadius`.

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

