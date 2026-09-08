# invest-05 — Fase render/overflow (1.4/1.5), `@bulge` e `tieEndpoints`:
itens sem veículo no corpus (só com fixture sintética)

**Objetivo.** Tratar os desvios reais que HOJE têm rendimento zero no
placar, com fixture sintética + teste de fixture (nunca por palpite no
corpus). Fazer por último, depois dos invest-01–04.

## 1. Mudanças de fase (1.4/1.5 do desvios-documentados)

- `adjust_x_pos.dart:8` (nesting por overlap inativo sem render pass) e
  `cast_off.dart:18,150` (overflow 0, ramo pending + `GetCachedXRel`
  inativos). Sintoma agregado no topo do ranking (`staff/path @d` #2,
  4532 divs em 67 arquivos) — mas é hipótese, não atribuição: primeiro
  provar por `probe_diff` em 1–2 arquivos-piloto que o ramo inativo é o
  que decide aqueles deltas, e que aproximar a ordem
  (`Page::LayOutHorizontally`) move o placar para melhor SEM regressão
  estrutural. Precedente contrário: `visitBeam` no-op
  (`prompts/loop-diario.md` 2026-09-07). Se o piloto não mover nada,
  arquivar como permanente.
- Demais fase/ordem/headless do §3
  (`lay_out_vertically.dart:21,118,1331`, `preparedata_functor.dart:11`,
  `calc_functors.dart:12,500,559,835`, `align_horizontally.dart:12,14,
  754,839`, `adjust_tuplets.dart:21,786`, `adjust_artic.dart:5`,
  `adjust_accid_x.dart:15`, `cache_horizontal_layout.dart:17`,
  `basic_elements.dart:2027`, `layer_elements_gen.dart:680,787`): mesma
  regra — somente via pinpoint com fixture.

## 2. `@bulge` (slur/tie)

- Estado: `AdjustSlurFromBulge` adiado (`adjust_slurs.dart:7`,
  `slur_positioning.dart:11`); parsing de `@bulge` existe
  (`atts_shared.dart:949-997`). `rg bulge` no corpus: SÓ
  `tie/tie-006.mei` (6 ties, `bulge="1 50"` — e tie-006 está LIMPO).
- Correção ao doc de desvios: `AdjustSlursFunctor` só visita
  `{PHRASE, SLUR}` (adjustslursfunctor.cpp:49) — ties NUNCA passam por
  `AdjustSlurFromBulge`; `Tie::CalculatePosition` (tie.cpp:133+) não lê
  `bulge`. O bulge do tie-006 é inerte nos dois lados (0 divs). Gatilho
  correto: corpus com `<slur bulge=...>` (hoje: nenhum).
- Passos: fixture sintética (`<slur bulge="2 30">`); portar
  `AdjustSlurFromBulge` (~50 linhas, `SolveControlPointConstraints` já
  existe) + ramo `slur.cpp:1148` (verificar se `calcInitialCurveFor` já
  contempla); validar SÓ na fixture + `compare_svg test/corpus/slur`
  sem regressão.

## 3. `m_measureTieEndpoints` (GAP-B do tie)

- Estado: ausente no Dart (`adjustxposfunctor.cpp:187-206` e ramo grace
  `adjustgracexposfunctor.cpp:188-198`: ties mesma-medida mais curtos que
  `tieMinLength` com ancestral `CHORD` ou descendente `FLAG` forçam
  alargamento). Option `tieMinLength` existe; falta o consumo.
- Sem veículo: nenhum corpus dispara (tie-009 same-measure: notas com
  beam, sem `FLAG`/`CHORD` — inerte; `gracenote-009` limpo).
- Passos: fixture sintética (tie curto same-measure entre acordes);
  portar `measure.getInternalTieEndpoints()` + bloco; validar na fixture.

## Aceite (para cada subitem)

- Fixture sintética + teste que falha antes e passa depois; corpus da
  categoria sem regressão (`compare_svg` antes/depois); `dart analyze` 0.
- Sem fixture que prove efeito: NÃO portar (registrar e arquivar).
