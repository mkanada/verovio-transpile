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

## 2026-09-05 — trilha ESTRUTURAL — alvo família `stem` (`stem-014.mei`+`stem-016.mei`, 17/60 do total estrutural, maior categoria do ranking)

S 60→43  N 32326→32318  X 611/621→613/621  Y 170/621→170/621  — **COMMIT**

Trilha obrigatória por regra do supervisor: as 3 iterações anteriores foram CAUSA/numéricas
(`staff/path @d`) e `S` continuava >0. Achado por fixture, não palpite: diff estrutural direto (não o
`probe_diff` numérico, que não reporta mismatch de contagem de filhos) achou o grupo de beam de
`stem-014` com 4 filhos onde o golden C++ tem 2 — dois `<polygon>` de beam extras.

- **OBS-1:** a divergência estrutural de `stem-014`/`stem-016` é duplicação de polígono de beam em
  `@stem.sameas` (duas layers compartilhando uma haste física), **não** o gap já conhecido de
  comprimento/inclinação de haste (OBS-3 da entrada anterior, 2026-09-04). `probe_diff` não pega essa
  classe de bug porque só compara deltas numéricos, não contagem de filhos — usar diff estrutural
  direto quando a assinatura for "esperado [N filhos], obtido [M filhos]".
- **OBS-2:** o mecanismo de supressão (`View::DrawBeam` checando `StemSameasIsSecondary()` antes/depois
  de `CalcBeam`) já estava certo em `view_beam.dart`; a quebra estava inteira a montante, em
  `BeamSegment` nunca transicionar o role de `unset` para `primary`/`secondary`. Ler o call site
  primeiro teria apontado errado para a view layer.
- **OBS-3 (a cara):** só adicionar a chamada faltante `UpdateSameasRoles` (`beam.cpp:1162-1164`) **não
  mudou nada** no `compare_svg`. A causa: o estado de `beamSegment` persiste através do pipeline
  horizontal→vertical→render (os objetos não são recriados entre passadas), e o role já tinha
  congelado numa passada anterior com `drawingY==0` para todas as notas (dado degenerado). Confirmado
  instrumentando `calcBeam` com prints — o mesmo beam era visitado 6+ vezes com role idêntico (e
  errado) após a 1ª resolução. **Regra geral falseável: toda lógica "decide uma vez, guarda no objeto"
  portada de um functor C++ tem que ser conferida contra `resetfunctor.cpp` por uma chamada de reset
  equivalente antes de cada passada que a recalcula — uma função de decisão correta não basta se nada
  manda ela rodar de novo.** Fix: `ResetHorizontalAlignmentFunctor.visitBeam` (não existia em Dart;
  mirror de `resetfunctor.cpp:583-591`) zerando `stemSameasRole`/`stemSameasReversePartner` antes de
  cada passada horizontal.
- **OBS-4 (gap irmão, não corrigido):** `ResetDataFunctor::VisitBeam` (`resetfunctor.cpp:86-100`)
  também zera `m_beamSegment` no C++ e `reset_functor.dart` não tem essa chamada. Não corrigido nesta
  iteração — parece inerte hoje porque cada render da suíte faz parse de um `Doc` novo (esse functor
  só roda uma vez por doc recém-parseado), mas é gap latente para qualquer cenário futuro de
  relayout sem reparse (edição interativa, `redoLayout`). Não verificado contra um caso que falhe —
  é pista, não bug confirmado.
- **OBS-5:** achado alcançável tanto por CAUSA (`(class=beam, tag=polygon)`) quanto por ESTRUTURAL
  (trilha atribuída). Registrado em ESTRUTURAL por atribuição. `beam`/`stem` agora têm 0 divergência
  estrutural — reranquear `DELTA_CLUSTERS.md` antes de escolher outro alvo beam-adjacente; os deltas
  `436`/`-464` do motor de inclinação (`CalcBeamSlope` etc., ainda não portado, ver entrada de
  2026-09-04 OBS-3) continuam sendo o próximo alvo CAUSA natural nesta mesma família de arquivo.
- Terceira causa raiz, menor: `CalcBeamInitForNotePair`'s stem.sameas branch (`beam.cpp:662-668`) devia
  usar as duas notas do par para extrema de Y / desempate de place; a nota de "Deviation" em
  `beam_segment.dart` dizendo que isso não era portado estava desatualizada — `Note.hasStemSameasNote`/
  `stemSameasNote` já existiam (sessão anterior) só não estavam ligados aqui. Portado.
- `test/harness_integrity_test.dart` trocou `stem-014.mei` (ficou estruturalmente limpo, não serve
  mais como probe "ainda divergente") por `barline/barline-009.mei` (4 divergências, causa não
  corrigida), seguindo o precedente de troca já documentado no próprio teste.
- Arquivos: `lib/src/model/beam_segment.dart`, `lib/src/layout/align_horizontally.dart`,
  `lib/src/layout/calc_functors.dart`, `lib/src/rendering/view_beam.dart`,
  `test/harness_integrity_test.dart`.

## 2026-09-05 — trilha CAUSA — motor de inclinação do beam (`CalcBeamSlope`/`CalcAdjustSlope`/
`CalcHorizontalBeam`, alvo apontado pela entrada anterior)

S 43→44  N 32318→28096  — **COMMIT** (uma exceção documentada à regra de S, ver OBS-2)

Portado por fora do loop automático, a pedido direto do usuário ("implemente tudo que você
encontrou" após uma busca prévia de código não portado relevante à fidelidade do SVG).

- **OBS-1:** o motor real (`beam.cpp:702-1082`) e o `BeamDrawingInterface::IsHorizontal` real
  (`drawinginterface.cpp:295`, com `IsRepeatedPattern`/`HasOneStepHeight`/`IsHorizontalMixedBeam`)
  substituem a heurística de interpolação linear que ficava em `calcBeam`. Efeito no corpus: N caiu
  13% (32318→28096), numérico-limpos subiu de 170→245 (+75 arquivos), sem nenhuma categoria piorando
  em total — exceto o caso estrutural isolado do OBS-2.
- **OBS-2 (a exceção):** `barline/barline-007.mei` ("Dotted and dashed bar line example", barra
  dupla-pontilhada abrangendo as 4 pautas) ganhou 1 divergência estrutural nova (68→70 elipses no
  grupo de pontos da barra) e piorou numericamente (76→284 divergências, mas o desvio na MESMA
  coordenada que antes era o pior do arquivo caiu de 702→264 unidades). Isolado por comparação direta
  golden×dart do grupo de beam (`h1WRIV4E`/`o1FK4NGH`): o comprimento e a forma interna de cada haste
  batem exatamente (`M4450 4057 L4450 2843` golden vs `M4450 4321 L4450 3107` dart — mesmo
  comprimento 1214, mesmo desenho relativo); a pauta 2 inteira (e tudo abaixo) está deslocada
  verticalmente em bloco por 264 unidades. **Causa raiz não é o motor de inclinação** — é um bug
  pré-existente, não investigado, no cálculo de espaçamento vertical entre pautas (a ponte
  `getBeamOverflow`/`getBeamChildOverflow`, stubs em `drawing_interfaces.dart:551-552`, é a suspeita
  mais provável — documentada como deviation desde antes desta sessão). O motor de inclinação apenas
  tornou esse resíduo pré-existente **menor** (702→264); o efeito colateral é que 264 ainda basta para
  cruzar o limiar de contagem de pontos do padrão pontilhado, o mesmo mecanismo de "correção parcial
  cruza limiar de renderização discreta" do OBS-3 de 2026-09-04 (`section-001`). Decisão: aceitar a
  exceção porque (a) o ganho é grande e verificado arquivo-a-arquivo, não só no placar agregado, (b) a
  causa raiz do resíduo é comprovadamente alheia a este motor e já era pior antes, (c) não investigada
  a fundo por estar fora do escopo desta sessão (foco era o motor de beam, não o espaçamento entre
  pautas). Não usar este precedente para justificar folga na regra em trilhas futuras do loop
  automático — ali a regra permanece sem exceção.
- **OBS-3 (achado lateral, não perseguido):** ao investigar o OBS-2 foi descoberto que
  `beamInterface.isHorizontal()` lido *antes* de reatribuir `drawingPlace`/`closestNote` (ordem
  literal do C++, que assume dados já estáveis por rodar só no passe de render) podia, neste port,
  ler estado momentaneamente obsoleto em passes mais cedo do pipeline. Reordenado para atualizar
  `drawingPlace` e `closestNote` (via `setClosestNoteOrTabDurSym`, caso não-mixed) *antes* da leitura
  — mudança neutra no corpus inteiro (mesmo S/N antes/depois), mantida por ser mais robusta e não ter
  custado nada.
- Próximo alvo natural nesta família: a ponte de beam-overflow (OBS-2) para fechar o resíduo de
  espaçamento entre pautas — não tentado aqui por estar fora do escopo relatado ao usuário
  (beam/tie/slur).
- Arquivos: `lib/src/model/beam_segment.dart`, `lib/src/model/drawing_interfaces.dart`.
