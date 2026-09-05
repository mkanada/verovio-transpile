# Diário de observações do loop de fidelidade

Registro acumulado do que cada iteração **aprendeu**, independentemente de o código ter sido
commitado ou descartado. O supervisor anexa aqui o Diário do reporte de cada subagente **antes** de
qualquer restore, e comita este arquivo sozinho — um beco-sem-saída documentado vale a iteração; um
beco-sem-saída esquecido faz o próximo subagente repeti-lo.

> Os números aqui são **fotografias datadas**, não estado atual. Cada entrada vale para o commit em
> que foi escrita. O estado de agora está em `tool/SVG_VALIDATION.md` e `tool/DELTA_CLUSTERS.md` —
> nunca cite um número deste arquivo como se fosse corrente.

Formato por iteração:

```
## <data> — trilha <CAUSA|BARATA|ESTRUTURAL> — alvo <assinatura ou arquivo>
S <antes>→<depois>  N <antes>→<depois>  — <COMMIT|RESTORE>

- OBS-1: …
- OBS-2: …
```

Uma OBS boa diz o que o resultado ensinou que não se sabia antes de tentar, e é falseável:
`OBS-3: radius 116 igual nos dois lados ⇒ causa não está em DrawDiamond, está no drawingNextElement a
montante`. Uma OBS ruim repete o sintoma (`OBS-3: ainda diverge`).

---

## 2026-09-04 — abertura do diário (sem iteração)

Estado ao trocar a estratégia do loop de "um arquivo por vez" para "uma causa por vez":
`S = 60`, `N = 46598`, `X = 611/621`, `Y = 138/621`.

Observações da análise que motivou a troca — valem como ponto de partida, não como conclusões:

- **OBS-A:** 473 arquivos divergem só no numérico (482 se contarmos também os estruturalmente sujos
  cujas subárvores ainda emparelham — a população do `cluster_deltas`), somando ~121k números
  diferentes, mas com mediana de **19 deltas distintos e 7 classes de elemento por arquivo**. Não são
  473 bugs; são poucas dezenas de defeitos compartilhados vistos de 473 ângulos.
- **OBS-B:** as cinco maiores assinaturas do `cluster_deltas` (`staff/path @d`, `stem/path @d`,
  `notehead/use @transform`, `barLine/path @d`, `beam/polygon @points`) afetam 255-364 arquivos cada.
- **OBS-C:** 27% de todos os deltas são múltiplos exatos de **9** (= 1/10 da unidade de pauta; o
  espaçamento entre linhas é 180). O delta `9` sozinho aparece em 220 arquivos, `18` em 152, `27` em
  125 — uma escada aritmética, assinatura de **um** erro de espaçamento que acumula, não de bugs
  independentes.
- **OBS-D:** em `beam/beam-001` a pauta termina em 2704 no C++ e 2713 no Dart, e a barra de compasso
  em 2691 vs 2700 — o lado direito inteiro deslocado +9, com a distância barra→fim da pauta (13)
  idêntica nos dois lados. O compasso é 9 unidades largo demais; não é erro de desenho da pauta.
- **OBS-E:** o delta `-208` aparece em 151 arquivos e domina `stem/path @d` (971 ocorrências) e
  `beam/polygon @points` (794). Em `beam-001` a haste sai do X da cabeça de nota em vez de
  cabeça + largura — hipótese de lado da haste, ainda não confirmada por fixture.
- **OBS-F:** 335 dos 482 arquivos têm sua *primeira* divergência na linha de pauta ou do sistema.
  Isso é ordem de desenho, não causa: a pauta é o primeiro `<path>` de cada compasso e mascara todo o
  resto. Escolher alvo pela primeira divergência leva 335 vezes ao mesmo sintoma.
- **OBS-G:** existem 41 arquivos a ≤3 divergências do limpo e 10 a exatamente 1 — três deles puro
  arredondamento de ±1 (`dynam-007` 2551↔2550, `tuplet-012` 5847↔5846, `pedal-005` 2529↔2528),
  provavelmente uma única regra de arredondamento.
- **OBS-H:** os dumps `test/golden/dart/**.svg` estavam **dessincronizados** do código: o último
  commit a tocá-los foi `86b09906` (10:54), enquanto `lib/` mudou em `9b3510ca` (16:04), que levou os
  42 reports per-file e nenhum dump. Quem lê os dumps (`cluster_deltas`) lia um estado de código
  anterior — nos 5 arquivos de ligature checados, pontos de controle diferiam em 1 unidade.
  `--all` regenera dumps e reports juntos; commite os dois juntos.
- **OBS-I:** `renderSvgForComparison` não fixava `xmlIdSeed`, então todo `--all` reescrevia os 621
  dumps só trocando ids gerados — `git diff` nos dumps era inútil para revisar o que um fix mudou.
  **Resolvido:** o hook agora chama `Object.seedID(kHarnessXmlIdSeed)` por render. Não pode alterar
  veredito de comparação: o comparador normaliza ids dos dois lados, justamente porque os goldens do
  C++ carregam ids aleatórios por execução.
- **OBS-K:** 10 testes cronicamente vermelhos foram removidos em 2026-09-04 (grupos de sequência de
  functor em `horizontal_layout`/`vertical_layout`, `full pipeline` do vertical cujo `setUpAll`
  falhava, mais casos isolados em `adjust_accid_artic`, `adjust_beams`, `floating_positioners`,
  `scoredef`, `text_layout_element`). A suíte foi de `+704 -10` para `+701` verde. **Eles cobriam a
  camada de layout — a montante do SVG, exatamente onde estão as maiores assinaturas do
  `cluster_deltas`.** Consequência: uma regressão em ordem de functor ou em `layOutVertically` não
  tem mais teste que a pegue; o único detector agora é o próprio placar S/N. Se um fix de causa
  derrubar N num lugar e subir noutro sem explicação, desconfie da camada de layout antes de
  desconfiar do desenho.
- **OBS-J:** semear sozinho não bastava, e o motivo é a razão de OBS-I ter parecido "geometria
  determinística" antes: **todo** `Object` construído incrementa o mesmo contador de id
  (`object.dart` `_init` → `generateID`), e um processo frio constrói objetos extras aquecendo estado
  preguiçoso. Resultado: só o **primeiro** render de cada processo saía diferente; do segundo em
  diante era estável. O hook absorve isso renderizando o primeiro arquivo pedido duas vezes e
  descartando a passagem fria. Verificado: mesmo arquivo antes e depois de outro render bate, e o
  hash de três renders bate entre processos distintos.
  Consequência prática para o loop: **agora `git diff` em `test/golden/dart/` mostra exatamente a
  geometria que o fix mudou** — use isso para revisar uma correção antes de aceitar o placar.

## 2026-09-04 — trilha CAUSA — alvo `staff/path @d` (#1 do ranking, 364 arquivos)

S 60→428  N 46598→41295  — RESTORE

- **OBS-1:** confirmado por fixture (não só hipótese) o mecanismo de OBS-C/D/E: em `beam-001`,
  `probe_diff` acusa `fn=DrawLine path=measure[1]/staff[1]` com Δ9 no fim da pauta. Rastreando
  `AdjustXPosFunctor`, todo elemento bate exatamente contra o fixture C++ (`clef`, `keySig`,
  `barLine`, `note`) **exceto o `stem`**: C++ `selfLeft=943 selfRight=1051`, Dart
  `selfLeft=726 selfRight=843` (Δ≈−208/−217, a própria assinatura #2 do ranking). O `selfLeft` da
  haste mal posicionada cai abaixo do `minPos` herdado, e `AdjustXPosFunctor` empurra tudo +9 para
  compensar — a família "múltiplos de 9" não é bug em `AdjustXPos`, é a haste alimentando-o errado.
- **OBS-2:** causa raiz é `BeamElementCoord::SetDrawingStemDir`/`UpdateStemLength`
  (`origin/src/src/beam.cpp:1837` e `:2029`) nunca terem sido portados para a parte **X** — só a
  direção do stem propagava. O próprio `lib/src/model/beam_segment.dart` já tinha comentário
  marcando isso como pendência conhecida ("pending 05-31b"). Corrigir só a âncora X (independente de
  Y/comprimento, que segue pendente) já fecha `staff/path @d` em `beam-001` (X da haste bate
  exatamente: esperado 1042, obtido 1042) — resta só divergência em Y, fora do escopo desta trilha.
  Efeito no corpus: N caiu 11% (46598→41295), **30 categorias melhoraram, nenhuma piorou**
  numericamente (beam −1335, section −465, barline −390, gracenote −337, repeats −291, tuplet −216,
  figured-bass −205, tie −195, cross-staff −174, slur −147, e mais 20 categorias menores).
- **OBS-3 (o motivo do restore):** `section/section-001.mei` foi o único arquivo a ganhar
  divergência estrutural (368, de 0). Mecanismo: o harness força cast-off automático
  (`Breaks.auto`), e o compasso `n="5"` (tercinas com `bracket.visible="false"`) foi de largura 4522
  para 4653 com o fix — **mais correto** (fixture `05-38` espera 5028: ainda falta 375 unidades,
  provavelmente um bug separado de espaçamento de tuplet/tercina, não investigado). Esse ganho de
  131 unidades tira o compasso do primeiro sistema (golden 6/4/4/4/2 compassos por sistema; dart
  vira 5/4/4/4/3) — sistemas 1-3 batem, só o primeiro e o último mudam de contagem. **Não é
  regressão nova**: é uma correção parcial e correta empurrando um caso já limítrofe de cast-off
  através de um limiar de quebra de sistema. Se o bug de tuplet/tercina for corrigido junto (fechar
  o resíduo de 375 unidades), a hipótese é que a quebra volta a bater e `S` não sobe mais.
  **A regra "S nunca sobe numa trilha numérica" não tem exceção por contagem de arquivos — bloqueia
  mesmo sendo 1 arquivo só. Confirmado pelo supervisor: mantém o RESTORE.**
- **OBS-4:** próxima tentativa em `stem`/`beam` deveria **incluir** o fechamento do resíduo de
  espaçamento de tercina/tuplet em `section-001` (fixture `05-38` já tem os valores esperados de
  largura de compasso) **na mesma iteração**, para que o cast-off não cruze o limiar de quebra
  sozinho. Reaplicar o fix de `beam_segment.dart` descrito em OBS-1/OBS-2 (mirror de
  `beam.cpp:1837`/`:2029`, helper `_stemAnchorFor` para Note/Chord análogo a `chord.cpp:358-370`) é
  reproduzível a partir desta entrada — o código foi descartado pelo restore, não fica em nenhum
  branch.

## 2026-09-04 — trilha CAUSA (2ª tentativa) — alvo `staff/path @d`, completar OBS-4

S 60→428  N 46598→33630  — RESTORE

Reaplicou a âncora X (OBS-1/2 acima), confirmada exata por fixture (`beam-001` x1=1042 nos dois
lados). Foi além: investigou o resíduo de `section-001` e **refutou** a hipótese de tuplet/tercina do
OBS-4.

- **OBS-5:** `CalcAlignmentXPosFunctor::VisitSystem` (`calcalignmentxposfunctor.cpp:118`,
  `System::EstimateJustificationRatio` em `system.cpp:425`) nunca tinha sido portado — stub fixo em
  ratio=1.0. Portado (`system_page_elements.dart` + religado em `calc_alignment_x_pos.dart`). Fix
  real e correto (N de `section` caiu 531→457), mas **só afeta a 2ª passada** de
  `LayOutHorizontally` (pós-cast-off) — a decisão de corte de sistema usa só a 1ª passada
  ("uncast pass", ratio sempre 1.0 nos dois lados), então este fix **não pode**, por construção,
  mudar em que sistema uma medida cai. Não confundir os dois passes de novo.
- **OBS-6:** margem vertical accid↔note em `AdjustXPosFunctor::CalculateXPosOffset`
  (`adjustxposfunctor.cpp:369-379`) também nunca portada (a nota de "Deviation" em `adjust_x_pos.dart`
  dizendo que dependia de "posições absolutas de staff que a fase de render não fornece" está
  desatualizada — `getAncestorStaffLayout()`/`getDrawingY()` já existem no pipeline atual). Portada.
  Correta, mas confirmada por instrumentação como **sem efeito** no resíduo de `section-001`
  especificamente (verticalMargin calcula 0 nos dois lados nesse par).
- **OBS-7 (refuta OBS-4):** o resíduo de 140 unidades no uncast pass de `section-001` measure[5] não
  vem de tercina/bracket-invisível — vem do branch catch-all `else` de
  `AdjustXPosFunctor.calculateXPosOffset` (colisão haste↔accid, não nota↔accid, que já bate). A
  haste de note[1] tem geometria **própria** errada no Dart: aponta para baixo ~324 unidades onde o
  fixture espera para cima ~593 unidades — a diferença bate exatamente com `uniformStemLength = 315`
  de `beam_segment.dart`. **Causa real: o ramo Y de `BeamSegment.calcBeam` (`calcBeamPlace`,
  `calcAdjustPosition`, `adjustBeamToLedgerLines`, `needToResetPosition` — linhas 613-639, todos
  stub) — a pendência "05-31b" já citada no próprio arquivo, não um bug de tuplet.** Não tentado
  nesta iteração por ser claramente maior que o orçamento de 10 tentativas (é o motor de beam
  inteiro, não um fix pontual).
- **OBS-8:** os dois passes de `LayOutHorizontally` (`unCastOffPage` em `Doc::CastOffDocBase` vs.
  `Page::LayOut()` via `View::SetPage`) são distinguíveis no fixture só pela ordem de invocação, não
  por um campo explícito — confundir os dois leva a atribuir efeito de decisão de corte a um fix que
  só toca a 2ª passada (ver OBS-5).
- **Recomendação para a 3ª tentativa:** ir direto ao ramo Y de `BeamSegment.calcBeam`
  (`calcBeamPlace`/`calcAdjustPosition`/`adjustBeamToLedgerLines`/`needToResetPosition`, mirror de
  `beam.cpp`, tarefa "05-31b") **reaplicando também** a âncora X (OBS-1/2) e os dois fixes desta
  entrada (OBS-5/6, corretos e reprodutíveis, sem efeito colateral próprio) na mesma iteração. A
  hipótese, ainda não testada, é que portar o Y do beam corretamente faz a haste de note[1] parar de
  colidir com o accid de note[2], o que fecharia o resíduo de 140 e pararia o cruzamento de sistema
  em `section-001` como efeito colateral — sem isso, é provável que qualquer nova tentativa em
  `staff/stem/beam` esbarre no mesmo S=428 de novo.

## 2026-09-04 — trilha CAUSA (3ª tentativa) — motor Y do beam ("05-31b")

S 60→60  N 46598→32326  X 611/621→611/621  Y 138/621→170/621  — **COMMIT**

A hipótese da entrada anterior (OBS-7/recomendação) foi testada e confirmada: portar o Y do beam fez
a haste de `section-001` measure[5]/note[1] parar de colidir com o acidente da nota seguinte, e o
compasso não voltou a cruzar o limiar de quebra de sistema (`section` S continua 0/4). Terceira
tentativa consecutiva na mesma assinatura (`staff/path @d`) — as duas primeiras (restauradas) não
foram desperdício: isolaram a causa raiz exata que esta resolveu.

- **OBS-1 (reaplicado):** âncora X do stem (`beam.cpp:1837-1913`) — `beam-001` `x1=1042` nos dois
  lados, como nas tentativas anteriores.
- **OBS-2:** com o motor Y completo, `Y1` (junção haste↔nota) também bate exato (`beam-001` seq 29,
  `y1` esperado/obtido `1871`/`1871`). Só `Y2` (ponta da haste) diverge agora (Δ436) — evolução clara
  frente ao "direção errada" das tentativas anteriores.
- **OBS-3 (aponta o próximo alvo, falseável):** o delta `436` virou o mais compartilhado em
  `stem/path @d` (32 arquivos) e `beam/polygon @points` (30 arquivos) no `DELTA_CLUSTERS.md`
  pós-fix. Hipótese para a próxima trilha CAUSA: `CalcBeamSlope`/`CalcAdjustSlope`/
  `CalcBeamSlopeStep`/`CalcHorizontalBeam` (`beam.cpp:702-897,964-1082,1339-1367`) e o real
  `BeamDrawingInterface.isHorizontal()` (`drawinginterface.cpp:295`) — deliberadamente deixados de
  fora desta iteração (documentado no doc comment de `beam_segment.dart`), junto com
  `AdjustBeamToFrenchStyle` (opção default off) e `AdjustBeamToTremolos` (precisa de
  `Stem.calculateStemModAdjustment`, ainda não existe).
- **OBS-4:** `staff/path @d` caiu de #1 (364 arquivos) para #3 (220 arquivos) no ranking — o motor Y
  resolveu a maior parte do que a âncora X sozinha não resolvia.
- **OBS-5:** `section-001` ainda carrega um warning pré-existente não relacionado ("Justification is
  highly compressed", ratio≈0.0048) — o fix de `estimateJustificationRatio` desta sessão reduziu o
  Δ desse `DrawLine` residual de 38559→12496 mas não zerou; hipótese: bug separado em
  `castOffJustifiableWidth`, não investigado.
- Arquivos: `lib/src/model/beam_segment.dart` (reescrito), `lib/src/model/basic_elements.dart`
  (+`Note.calcStemLenInThirdUnits`, mirror `note.cpp:559`, real — distinto do
  `calcStemLenInThirdUnitsHeadless` de prepare), `lib/src/model/system_page_elements.dart`
  (+`System.estimateJustificationRatio`), `lib/src/layout/calc_alignment_x_pos.dart`,
  `lib/src/layout/adjust_x_pos.dart`.
