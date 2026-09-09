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

## 2. `@bulge` (slur/tie) — ENCERRADO 2026-09-09

- Estado original: `AdjustSlurFromBulge` adiado (`adjust_slurs.dart:7`,
  `slur_positioning.dart:11`); parsing de `@bulge` existe
  (`atts_shared.dart:949-997`). `rg bulge` no corpus: SÓ
  `tie/tie-006.mei` (6 ties, `bulge="1 50"` — e tie-006 está LIMPO).
- Correção ao doc de desvios (já estava certa): `AdjustSlursFunctor` só
  visita `{PHRASE, SLUR}` (adjustslursfunctor.cpp:49) — ties NUNCA passam
  por `AdjustSlurFromBulge`; `Tie::CalculatePosition` (tie.cpp:133+) não lê
  `bulge`. Gatilho correto: corpus com `<slur bulge=...>` (hoje: nenhum).
- Portado: `AdjustSlurFromBulge` completo (filtro de valores admissíveis,
  lambdaMin/Max, ajuste horizontal via `Set`/`GetLeftControlOffset`,
  constraint por entrada de bulge via `CalcBezierParamAtPosition`,
  `SolveControlPointConstraints` (já existia) + `AdjustSlurShape` (já
  existia)) — `adjust_slurs.dart`'s `adjustSlurFromBulge`, chamado do
  `if (slur.hasBulge)` logo após STEP 3 de `adjustSlur`, espelhando
  `adjustslursfunctor.cpp:178-182`.
- Fixture sintética: `test/fixtures/synthetic/slur_bulge.mei` (+
  `slur_no_bulge.mei`, baseline) — duas notas, um `<slur bulge="2 30">`.
- **Achado fora de escopo (registrado, não corrigido aqui):** o binário
  C++ real (via `cpp_probe` patch `05-53`, fprintf-only, `diff` vazio
  contra o binário limpo) mostra que a entrada de `AdjustSlurFromBulge`
  para este fixture (`p1/c1/c2/p2`, `leftControlHeight`/
  `rightControlHeight`) já diverge do Dart ANTES do código deste item
  rodar — a causa é upstream, em `CalcInitialCurve`/
  `InitBezierControlSides` (`slur_positioning.dart`, portado antes do
  invest-05). Essa divergência fica invisível no caminho comum
  (colisão-driven, steps 4-6) porque ele parece re-derivar a mesma forma
  final independente dela para todo slur do corpus medido até agora — o
  `@bulge` é o primeiro caminho que pula direto da entrada para a saída
  sem essa correção, então é o primeiro a expor o problema. É candidato
  forte para explicar parte do cluster `slur/path @d` (`DELTA_CLUSTERS.md`
  rank #4, 46 arquivos, 1023 divs) — mas investigar/corrigir isso é fora
  do escopo deste item; ver `prompts/loop-diario.md` 2026-09-09.
- Validação: já que a entrada real do pipeline diverge por essa causa
  alheia, `adjustSlurFromBulge` foi verificado ISOLADO — alimentado com a
  bezier de entrada exata capturada do C++ (via a mesma sonda 05-53),
  contornando o bug upstream — e o resultado final (pós-`AdjustSlurShape`)
  bate byte a byte com o do C++ real (`test/adjust_slurs_bulge_test.dart`).
  O baseline sem bulge do mesmo fixture (que não passa por
  `AdjustSlurFromBulge`) bate com o C++ ponta a ponta, o que confirma que
  a única causa da divergência de ponta a ponta do fixture COM bulge é a
  pré-existente, não o código novo. `compare_svg --all` idêntico byte a
  byte antes/depois (nenhum arquivo do corpus tem `<slur bulge>`, então
  zero efeito, como esperado). `dart analyze` 0, `dart test` 706→709.

## 3. `m_measureTieEndpoints` (GAP-B do tie) — ENCERRADO 2026-09-09

- Correção a este doc: o ramo principal (`adjustxposfunctor.cpp:187-206`)
  já estava portado quando este arquivo foi escrito — `AdjustXPosFunctor`
  já tinha `measureTieEndpoints`/`getInternalTieEndpoints()` wired em
  `adjust_x_pos.dart` (visível hoje em `adjust_x_pos.dart:96,325-352,400`).
  A afirmação "ausente no Dart" acima só valia para o ramo grace.
- O que faltava de fato: `AdjustGraceXPosFunctor`
  (`adjustgracexposfunctor.cpp:186-198,220`) não tinha o campo
  `measureTieEndpoints` — tie começando numa grace note, terminando na
  nota real seguinte, ambas na mesma medida, nunca alargava o grupo de
  grace. Portado: campo + `visitMeasure` popula antes da 2ª passada
  (revertida) + bloco em `visitLayerElement` (mirrors
  `m_graceMaxPos -= (unit + minTieLength - diff)`).
- Sem veículo real: nenhum arquivo do corpus tem `<tie startid=...>`
  apontando para uma grace note (`note-005.mei`, o único grace+tie do
  corpus, tie liga duas notas comuns não relacionadas à sua grace note;
  `gracenote-009` seguia limpo). Testado por 5 casos hand-derived em
  `test/adjust_grace_x_pos_tie_test.dart` (precedente:
  `adjust_x_overflow_test.dart`'s "hand-derived parity" para ramos sem
  veículo) — falha antes (campo inexistente, erro de compilação), passa
  depois. `compare_svg --all` confirmado idêntico byte a byte antes/depois
  (S 18/18, N 6894, X 503/621, 118 divergentes — zero efeito no corpus,
  como esperado). `dart analyze` 0, `dart test` 701→706 (5 novos).

## Aceite (para cada subitem)

- Fixture sintética + teste que falha antes e passa depois; corpus da
  categoria sem regressão (`compare_svg` antes/depois); `dart analyze` 0.
- Sem fixture que prove efeito: NÃO portar (registrar e arquivar).
