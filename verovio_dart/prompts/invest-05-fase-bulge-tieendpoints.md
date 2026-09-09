# invest-05 — Fase render/overflow (1.4/1.5), `@bulge` e `tieEndpoints`:
itens sem veículo no corpus (só com fixture sintética)

**Objetivo.** Tratar os desvios reais que HOJE têm rendimento zero no
placar, com fixture sintética + teste de fixture (nunca por palpite no
corpus). Fazer por último, depois dos invest-01–04.

## 1. Mudanças de fase (1.4/1.5 do desvios-documentados) — ARQUIVADO 2026-09-09

- Hipótese original: `adjust_x_pos.dart:8` (nesting por overlap inativo
  sem render pass) e `cast_off.dart:18,150` (overflow 0, ramo pending +
  `GetCachedXRel` inativos) explicariam o topo do ranking (`staff/path @d`
  / `stem/path @d`, ~49 arquivos cada, mesmo conjunto de arquivos nos
  dois). Pilotado com `probe_diff` em 3 arquivos (`accid/accid-009`,
  `keysig/keysig-002`, `layer/layer-006`) — protocolo do próprio item:
  "se o piloto não mover nada, arquivar como permanente".
- **Resultado do piloto: a hipótese não se sustenta.** Nos 3 arquivos a
  primeira divergência (`probe_diff`, alinhado por seq+path) é sempre
  `View::DrawStaff`/`DrawHorizontalLine` — a linha de pauta (= largura do
  compasso) curta por um delta fixo (-131/-316/-540) — mas isso é o local
  onde o número ERRADO é DESENHADO, não onde ele nasce. Os três arquivos
  têm em comum acidentes (`<accid>`) competindo por espaço horizontal
  (`accid-009`: 8 acidentes com `@loc/@ploc/@oloc` explícitos;
  `keysig-002`: mudança de armadura/metro no meio da peça; `layer-006`:
  acidente em layer concorrente com `mRest`) — não uma característica de
  fase/ordem de layout. `adjust_x_pos.dart:8`/`cast_off.dart:18,150` não
  aparecem em nenhum dos três rastros. **Arquivado**: não perseguir essa
  hipótese específica por conta própria.
- **Achado real, dentro do escopo do 2º bullet abaixo (fase/ordem
  documentada, mas já corrigida sem atualizar o comentário):**
  `adjust_artic.dart:5` e `adjust_accid_x.dart:15` — ambos os comentários
  de cabeçalho afirmavam que o functor "precisa do render pass, só
  disponível na fase vertical, por isso corre em `Doc.layOutVertically`".
  **Falso hoje**: `AdjustArticFunctor` (doc.dart:560) e
  `AdjustAccidXFunctor` (doc.dart:587) já correm dentro de
  `layOutHorizontally`, depois do `_renderBoundingBoxes(doc,
  horizontal:true)` (doc.dart:554) — o próprio comentário de
  `layOutVertically` (doc.dart:895-900, junto à chamada de
  `AdjustArticWithSlursFunctor`) confirma isso por extenso: "the X-only
  AdjustArtic/Accid/Ossia/Neume/Syl/Harm/Arpeg/Tempo/XOverflow adjusts
  have already run in layOutHorizontally before CastOff... and must not
  run again here". `AdjustArpegFunctor` (doc.dart:629) e
  `AdjustTupletsXFunctor` (doc.dart:639) confirmam o mesmo padrão. Os
  comentários de `adjust_artic.dart`/`adjust_accid_x.dart` ficaram
  parados numa versão anterior do pipeline (provavelmente pré-tarefa 04f,
  quando o render pass ainda não corria dentro de `layOutHorizontally`) e
  nunca foram atualizados quando o functor migrou de fase — corrigidos
  nesta sessão (comentário só, sem mudança de comportamento).
- **Não verificado** (fora do orçamento desta sessão, mesma regra se
  algum dia for retomado — só via pinpoint com fixture, nunca por
  palpite): `lay_out_vertically.dart:21,118,1331`,
  `preparedata_functor.dart:11`, `calc_functors.dart:12,500,559,835`,
  `align_horizontally.dart:12,14,754,839`, `adjust_tuplets.dart:21,786`,
  `cache_horizontal_layout.dart:17`, `basic_elements.dart:2027`,
  `layer_elements_gen.dart:680,787`.
- **Lead real para o cluster `staff/path @d`/`stem/path @d` (não
  perseguido aqui — mereceria seu próprio invest):** os 3 arquivos-piloto
  convergem em acidentes competindo por espaço horizontal, apontando para
  `AdjustAccidXFunctor`/`Accid.adjustX` (`adjust_accid_x.dart`). Mas a
  pista mais óbvia — `desvios-documentados.md` §2.7
  (`bounding_box.dart:246,282`, overlap horizontal sem recorte de glifo
  SMuFL) — já parece corrigida: `adjust_accid_x.dart:168,184` chama
  `horizontalLeftOverlapGlyphAware`/`horizontalRightOverlapGlyphAware`
  (`floating_positioner.dart`), não as versões planas, e o próprio
  `bounding_box.dart:246-251` documenta isso ("this plain form has no
  production callers"). Ou seja, §2.7 (pelo menos o lado horizontal) e a
  hipótese de fase deste item 1 estão AMBOS desatualizados/resolvidos, e
  a causa real do delta -131/-316/-540 ainda não foi isolada — precisa de
  uma sonda `cpp_probe` nova sobre `AdjustAccidXFunctor`/`AccidAdjustX`
  para os 3 arquivos-piloto (o fixture `04b` existente só cobre
  `accid-001`, que segundo `test/adjust_accid_artic_test.dart` já tem seu
  próprio comentário desatualizado — não reafirma valores numéricos, só
  cobertura estrutural). Não abrir isso por conta própria; registrar como
  candidato a `invest-06`.

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
- **Achado fora de escopo, corrigido em iteração seguinte do loop
  (2026-09-09, ver `prompts/loop-diario.md`):** o binário C++ real (via
  `cpp_probe` patch `05-53`, fprintf-only, `diff` vazio contra o binário
  limpo) mostrou que a entrada de `AdjustSlurFromBulge` para este fixture
  (`p1/c1/c2/p2`, `leftControlHeight`/`rightControlHeight`) já divergia do
  Dart ANTES do código deste item rodar. Causa raiz: `Slur::
  CalcInitialCurve` (`slur.cpp:1148-1153`) escolhe entre
  `CalcInitialControlPointParams()` (sem doc, offset=dist/3, height=0) e a
  sobrecarga com doc conforme `HasBulge()`; `calcInitialCurveFor`
  (`slur_positioning.dart`) sempre chamava a sobrecarga com doc, ignorando
  o branch. **Corrigido** — `slur_bulge.mei` agora bate byte a byte com o
  C++ real ponta a ponta (`test/adjust_slurs_bulge_test.dart`, teste
  "the bulge fixture matches..."). Não afeta o cluster `slur/path @d`
  (`DELTA_CLUSTERS.md` rank #4): esse branch só é tomado quando
  `HasBulge()` é verdadeiro, e nenhum `<slur>` do corpus tem `@bulge` —
  então a hipótese de "candidato forte" não se confirmou como causa do
  cluster, mas o bug em si era real e agora está corrigido.
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
