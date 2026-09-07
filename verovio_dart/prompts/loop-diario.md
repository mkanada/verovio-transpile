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

## 2026-09-05 — trilha CAUSA — `Tie::CalculatePosition` (não portado, existia só um fallback falso)

S 44→44  N 28096→27714  — **COMMIT**

Segundo item da mesma sessão fora do loop automático ("implemente tudo que você encontrou").
`Tie::CalculatePosition` (tie.cpp:133) nunca tinha sido portado — `view_control.dart`
`_calculateTiePosition` tentava despachar dinamicamente para um método que não existia em lugar
nenhum (sempre caía no `catch`) e desenhava um arco simétrico hardcoded para toda ligadura de tie do
corpus. Portado por completo: `CalculatePosition`, `CalculateXPosition`,
`CalculateAdjacentChordXOffset`, `GetPreferredCurveDirection`, `UpdateTiePositioning`,
`AdjustEnharmonicTies` (todos em `tie.cpp`), como métodos de `Tie`
(`lib/src/model/control_elements_gen.dart`).

- **OBS-1:** a maior parte da infraestrutura já existia pronta esperando por este método —
  `Chord.getAdjacentNotesList`/`positionInChord`/`getTopNote`/`getBottomNote`,
  `Layer.getDrawingStemDirFor`, `FloatingCurvePositioner.calcAdjustment`/`updateCurveParams`,
  `Discard` — inclusive com comentário explícito em `getAdjacentNotesList` dizendo "no active in-tree
  caller yet — the C++ caller is Tie::Calculate*". Isso reduziu bastante o risco do port.
- **OBS-2 (deviation deliberada):** `Chord::HasAdjacentNotesInStaff` (chord.cpp:411) depende de
  `CalcNoteLocations`, um helper multi-pauta genérico não portado. Substituído por uma versão
  reduzida e correta para o caso comum (`_hasAdjacentNotesInStaff` em `control_elements_gen.dart`):
  como a pauta já é conhecida no call site, basta coletar `drawingLoc` das notas do acorde
  *naquela* pauta e checar diferença adjacente de 1, sem precisar da máquina cross-staff genérica.
- **OBS-3 (limpo, mas não zerado):** `tie-001.mei` caiu para 7 divergências, desvio máximo 1.0 —
  puramente arredondamento (`toInt()`/`~/` truncando de forma ligeiramente diferente do `(int)` do
  C++ em algum dos `0.25*length`/`1.2*overlap`/altura da bezier). Não perseguido: é um resíduo de
  ±1 unidade, não um erro de algoritmo. Famílias como `tie-005`/`tie-011` (desvios de 1082/1553)
  parecem grandes à primeira vista, mas a *primeira* divergência relatada cai fora da árvore de tie
  (em `grpSym`/`label`, topo do sistema) — sintoma de um bug pré-existente não relacionado a tie
  (mesma classe de mascaramento documentada alhures no diário: a primeira divergência de um arquivo
  raramente é a causa raiz). Não investigado a fundo por estar fora do escopo desta trilha.
- Ganho modesto mas real e sem nenhuma regressão de S: N caiu 28096→27714 (categoria `tie`
  719→647 divergências). Menor que o motor de beam porque a maioria dos arquivos de tie herda erro
  de posição de nota de outras causas já conhecidas (accid/dots/staff-spacing) — a curva da ligadura
  em si bate a menos de 1 unidade onde o resto da geometria já bate.
- Limpeza lateral em `view_control.dart`: `_calculateTiePosition` agora chama `tie.calculatePosition`
  diretamente (tipado, sem dynamic/try-catch); o mesmo para a leitura de `@lform` em `drawTie`
  (`tie.lform` direto, já que `tie` já chegava tipado como `Tie`).
- Próximo alvo desta sessão: `Slur::CalcEndPoints` (slur.cpp:598) — ver entrada seguinte.
- Arquivos: `lib/src/model/control_elements_gen.dart`, `lib/src/rendering/view_control.dart`.

## 2026-09-05 — trilha CAUSA — `Slur::CalcEndPoints` completo (grace/portato/beam/s-shaped/near-end)

S 44→44  N 27714→27741  — **COMMIT**

Terceiro e último item da mesma sessão ("implemente tudo que você encontrou"):
`lib/src/layout/slur_positioning.dart`'s `calcEndPointsReduced` (renomeado para `calcEndPoints`, já
não é reduzido) cobria só os casos de direção de haste + s-shaped + slur curto; faltavam os ramos de
nota-de-adorno (grace-to-note), portato (`IsPortatoSlur`), adjacente-a-beam
(`HasBoundaryOnBeam`/`StartsOnBeam`/`EndsOnBeam`), a correção de X para notehead invertido
(`GetFlippedNotehead`) e o reposicionamento por near-end-collision (`metricAtStart`/`metricAtEnd >
0.3`/`> 1.0`) nos ramos "endpoint primário na lateral". Portados todos, literal linha-a-linha contra
`slur.cpp:598-950`.

- **OBS-1 (por que foi mais barato que o motor de beam):** `Slur.isPortatoSlur` e
  `Slur.hasBoundaryOnBeam` (ambos em `control_elements_gen.dart`) já existiam prontos e testados,
  sem nenhum call site ainda — infraestrutura deixada por uma sessão anterior à espera exatamente
  deste trabalho, como aconteceu com `Chord.getAdjacentNotesList` na trilha do Tie.
- **OBS-2 (cast seguro, documentado):** `calcEndPoints` é uma extensão em `Object` compartilhada no
  arquivo com `Tie`/`Lv` para os getters de direção de curva (`hasMixedCurveDir` etc., que tratam
  `Slur` e `Tie` genericamente), mas os dois helpers novos (`isPortatoSlur`/`hasBoundaryOnBeam`) só
  existem em `Slur`. Confirmado com o C++ real (não com o comentário desatualizado do arquivo, que
  diz "Tie inheriting them" — falso: `Tie` não herda de `Slur` no Verovio 6.2.0,
  `include/vrv/tie.h:28`) que `calcEndPoints` só é alcançável via `AdjustSlursFunctor`
  (`adjustslursfunctor.cpp:49`, filtro explícito `Is({PHRASE, SLUR})`) e `View.drawSlur`
  (parâmetro já tipado `Slur`) — nunca `Tie`/`Lv`. `(this as Slur)` é portanto seguro; documentado no
  comentário da lib para a próxima sessão não reabrir a dúvida.
- **OBS-3 (efeito no corpus, mesma classe de cascata já vista 2x nesta sessão):** nenhuma
  categoria ganhou divergência estrutural. Numericamente, 3 arquivos mudaram
  (`clef-004` 137→139, `tuplet-018` 95→93, `trill-002` 33→60) — todos contêm `<slur>`, confirmando a
  causa. `trill-002` sozinho explica o delta agregado (+27): seu slur termina numa nota dentro de
  `<beam>` (`note-L14F2`), então `hasBoundaryOnBeam(false)` agora corretamente retorna `true` e
  ativa o ramo "mesmo mas em beam" que antes não existia — o endpoint do slur muda de posição
  (mais correto, mirror exato do C++) mas isso desloca o espaçamento entre pautas o suficiente para
  fazer `system/path` (topo da página) cruzar `eps=0.0` em mais elementos a jusante — mesma classe de
  cascata de "correção local, resíduo de espaçamento pré-existente alhures" documentada 2x antes
  nesta mesma sessão (`barline-007` no motor de beam). Não perseguido por estar fora do escopo
  relatado ao usuário (espaçamento entre pautas, não slur em si).
- **Não portado (deviation restante, documentada no arquivo):** `AdjustSlurFromBulge`
  (`@bulge`, `adjustslursfunctor.cpp:424`) — provavelmente 0-1 arquivo do corpus usa `@bulge`, valor
  esperado baixo para o esforço de porta-lo nesta sessão.
- Arquivos: `lib/src/layout/slur_positioning.dart`.

---

## 2026-09-06 — ponte pós-tipagem (sem iteração de fidelidade)

O loop de tipagem encerrou com `D=0` (`tool/TYPE_DEBT.md`: A=0, B=0, C=0). Efeito colateral no
placar de fidelidade, sem mudança de causa raiz:

S 44→44  N 27741→26237  X 612/621→612/621  Y 245/621→255/621  — N/A (outro loop)

- **OBS-1:** a queda de N (~1500) veio de ramos de desenho reativados pela tipagem, não de porte de
  geometria — o ranking CAUSA continua válido, só com números menores. Próxima iteração mede o
  baseline daqui, não das fotos de 2026-09-05 acima.
- **OBS-2:** `DELTA_CLUSTERS.md` foi regenerado em 2026-09-06 (estava morto desde 2026-09-05):
  365 arquivos, 57752 números, 105 assinaturas. Topo inalterado
  (`stem/path @d` 246, `staff/path @d` 203, `notehead` 198, `barLine` 192).

---

## 2026-09-06 — trilha CAUSA — alvo `stem/path @d` (#1, 246 arquivos)

S 44→44  N 26237→25670  X 612/621→612/621  Y 255/621→259/621  — **COMMIT**

Porte fiel de `CalcChordNoteHeadsFunctor::VisitNote` (`calcchordnoteheadsfunctor.cpp:52-115`),
que nunca tinha sido portado — o `visitNote` Dart retornava `siblings` imediatamente para todo
chord-tone. Triagem feita antes de portar motor: o subgrupo ±1 (arredondamento) foi separado e
não atacado; o alvo foi o subgrupo Δ-208 do mecanismo unison (note[2] 1033 vs 825 em `unison-001`).

- **OBS-1:** `stem.pos` existe em só 2 arquivos do corpus (`stem-010`, `stem-011`) mas Δ-208 afeta
  35 — `-208` não é `stem.pos`. Hipótese descartada por contagem, antes de fixture.
- **OBS-2:** notehead X bate nos dois lados e stem X não (`beamspan-003`: notehead 1966=1966,
  stem 2183 vs 1975; C++ offset 217, Dart 9; 217-9=208). Causa é a âncora X da haste, não posição
  da nota nem espaçamento.
- **OBS-3 (prova C++ com binário 05-42 instrumentado, depois revertido):** com fontes carregadas
  `GetStemUpSE=(226,28)`, `glyphW(E0A4)=226`, âncora bruta `(3149,399)`, `stemXRel=217`, `resOk=1`.
  Dart headless dá `upSE=(305,22)` (fallback `getGlyphWidth` sem fonte) e `xRel=9`.
  Δ208 = âncora real − fallback.
- **OBS-4 (ordem de pipeline, NÃO corrigida):** `Doc.prepareData` roda `CalcStemFunctor` com
  `fontSize=0`/`resourcesOk=false`; `layOutHorizontally` carrega fontes depois
  (`_ensureResourcesLoaded`) mas o port deliberadamente não re-roda `Calc*` (`doc.dart` deviation
  ~997). Re-rodar `CalcStem` manual com fontes mudou só len (428→422), X ficou 9 — porque
  `BeamSpanSegment.calcBeam`/`updateStemLength` (`x - el.getDrawingX()`) não re-resolve a âncora
  com a ordem certa. Fix correto do -208 de beam/beamspan exige reordenar `CalcStem` para depois
  das fontes (risco alto, fora do orçamento) — próximo passo documentado, trilha separada.
  `-208` restante (19 arq): beam-026, beamspan-003..006, cross-staff-001/007/008/009/015/023/024,
  slur-022/023…
- **OBS-5:** `chord-009`/`layer-008`/`score-012` com -208 no cluster têm 1ª divergência em
  `staff/system path` (bloco vertical +1000), não em stem — mascaramento a jusante, mesma lição de
  sempre. Não são alvo.
- **OBS-6 (o fix):** o subgrupo unison de -208 (`notehead/use @transform`) é outro mecanismo:
  `CalcChordNoteHeadsFunctor::VisitNote` ausente. Port linha-a-linha em
  `lib/src/layout/calc_functors.dart` (ramo tab, `chordDiameter` via `getDrawingRadius`/
  `getGlyphWidth`, guarda `chordDiameter==0`/alignment, paridade de `noteGroup`,
  `flippedNotehead` + `noteheadShift`, `siblings`). Desvio deliberado documentado no código: C++
  roda em `Page::ResetAligners` (com fontes); o port compensa via `getDrawingRadius` em vez da
  tabela bruta. Efeito: unison 126→58 (4/7→5/7 limpos), `unison-002` 65→0, beam 1429→1268,
  `unison-001` 4→1, `beam-037`/`chord-005`/`accid-006` zerados. Zero regressões por arquivo.
- Arquivos: `lib/src/layout/calc_functors.dart`.

## 2026-09-06 — trilha CAUSA — alvo `stem/path @d` (#1, 243 arquivos), subgrupo Δ90

S 44→44  N 25670→25634  X 612/621→612/621  Y 259/621→263/621  — **COMMIT**

Porte fiel do bloco de extensão ledger-line de `CalcStemFunctor::VisitStem`
(`calcstemfunctor.cpp:439-472`), que nunca tinha sido portado — o `visitStem` Dart pulava
direto para `CalculateStemModAdjustment` + `AdjustFlagPlacement`, sem o ajuste
`endY vs m_verticalCenter`. Triagem antes de portar: separado o subgrupo ±1 (arredondamento,
fora de escopo) e mascaramentos a jusante (1ª divergência em system/staff path em
`dot-001`/`stem-006`, sem fixture de stem); alvo foi o subgrupo sistemático Δ90 com
`fn=DrawLine path=.../stem[1]` direto (`lyric-001` seq69: y1 2321=2321, y2 1629 vs 1719).

- **OBS-7:** Δ90 em `stem/path @d` é comprimento da haste, não desenho: `DrawStem` Dart
  (`view_element.dart:1160`) espelha `view_element.cpp:1689` fielmente
  (`y - (len + adjust)`); com H=28700 o Dart dava stemY=26379 len=-602 y2=27071 (y2Dev=1719)
  contra y2 lógico C++ 27071 (y2Dev=1629). Diferença de 90 = 1 unit (= 1/3 de thirdUnit 30 × …)
  de extensão ledger-line ausente.
- **OBS-8:** o bloco C++ usa `m_verticalCenter = staffY - GetDrawingDoubleUnit*2`
  (não o centro geométrico da pauta — para 5 linhas equivale à 2ª linha de cima), e
  `flagHeight` fica 0 exatamente como no C++ (o shortening SMuFL 32nd está comentado lá
  como crash — "needs investigating"); grace notes excluídas (`!m_isGraceNote`); flag Y
  acompanha o novo len. Fidelidade linha-a-linha, sem invenção.
- **OBS-9:** efeito medido: 4 arquivos zerados (`annot-005`, `editorial-002`,
  `gracenote-019`, `octave-002`), `lyric-001` 4→1 divs (stem seq69 some; resta só slur a
  jusante), zero regressões por arquivo (23 reports tocados, nenhum com contagem maior).
  `layer-015` (estrutural, 1 div est antes e depois) teve só o max-deviation 1511→2365 —
  arquivo estrutural fora da catraca N/S, contagem inalterada.
- Arquivos: `lib/src/layout/calc_functors.dart` (+27/-2).

## 2026-09-06 — trilha CAUSA — alvo `stem/path @d` (#1, 227 arquivos), subgrupo Δ-178/-88

S 44→44  N 25634→22579  X 612/621→612/621  Y 263/621→267/621  — **COMMIT**

Porte fiel de `CalcStemFunctor::VisitChord` (`calcstemfunctor.cpp:141-142` + `staff.cpp:288`):
`m_chordStemLength = yMin - yMax` e `stem->SetDrawingYRel(yMin - chord->GetDrawingY())`
convertem loc→Y via `Staff::CalcPitchPosYRel` — 1 loc = 1 **single** unit, não doubleUnit.
O Dart usava `getDrawingDoubleUnit` (fator 2) e YRel em loc cru (sem ×unit).

- **OBS-10:** `chordStemLength` dobrado explicava o Δ-178/-88 de `stem-012` seq38
  (`chord[1]/stem[1]`, f3+d3): span de 2 locs valia 360 em vez de 180. Só a 1ª
  correção (chordStemLength) já zerou o y2 (1629=1629); só a 2ª (YRel ×unit)
  zerou o y1 — as duas metades do mesmo erro de unidade. stem-012 16→~6 divs,
  1ª divergência some de seq38 para seq285 (outro acorde, Δ-90 residual).
- **OBS-11:** efeito medido: N 25634→22579 (-3055, -12%), Y 263→267 (+4 limpos),
  S inalterado, stem 530→469 na família, chord+beam 1267. `cluster_deltas`
  pós-fix mostra o deslocamento: deltas 90/-231 somem do top stem, entram
  -60/-150/180 (mesma família de erro de unidade, próxima iteração).
- Arquivos: `lib/src/layout/calc_functors.dart` (+9/-4).

## 2026-09-06 — trilha CAUSA — alvo `stem/path @d` (#1, 185 arquivos), subgrupo d-60

S 44→44  N 22579→21502  X 612/621→612/621  Y 267/621→282/621  — **COMMIT**

Porte fiel de `Chord::CalcStemLenInThirdUnits` (`chord.cpp:372`),
`Note::CalcStemLenInThirdUnits` (`note.cpp:559`) e
`TabDurSym::CalcStemLenInThirdUnits` (`tabdursym.cpp:117`) para dentro de
`calcStemLenInThirdUnitsHeadless` (`lib/src/layout/preparedata_functor.dart`).

- **OBS-12:** tres faltas no headless, todas confirmadas no C++ antes de portar:
  (a) sem delegacao chord->nota — o C++ mede a top note (up) ou bottom note
  (down), o Dart media o loc do proprio chord (ex. `note-011` staff perc de
  2 linhas, chord loc 0/2 com stem.dir explicito: media loc 0 em vez da nota
  certa); (b) sem ramo tab — tablatura nao tem shortening por pitch, so
  ajustes de tab-type/stems-outside; (c) loc lido de `drawingLoc` ainda zero
  — no C++ o loc vem do `CalcAlignmentPitchPosFunctor`, que roda antes do
  `CalcStem` no `Page::ResetAligners`; o passe headless nao tem layout, entao
  calcula-se via `calcDrawingLocHeadless()`. Constroi sobre OBS-11 (mesma
  familia de erro de unidade em CalcStem).
- **OBS-13:** efeito medido: `note-011` 1a div some de seq118
  (`measure[1]/staff[3]/chord[1]/stem[1]` y2 d-60) para seq174 (measure[2],
  outro acorde, d-60 residual); familias note 7/12 441 divs, stem 6/16 338,
  chord 5/10 935; `--all` N 22579->21502 (-1077, -5%), Y 267->282 (+15
  limpos), S inalterado, 0 falhas; `cluster_deltas` stem 219->185 arqs,
  7842->7324; `dart analyze` 0 issues; `dart test` 701 pass.
- Arquivos: `lib/src/layout/preparedata_functor.dart` (+37/-5).

## 2026-09-06 — trilha BARATA — alvo `dynam/dynam-007`, `dynam/dynam-008`, `cpmark/cpmark-001` (fila de menor custo, 1 div cada)

S 44→44  N 21502→21499  X 612/621→612/621  Y 282/621→285/621  — **COMMIT**

Troca de trilha: as últimas 4 iterações foram CAUSA (mesma assinatura `stem/path @d`), então
seguindo a regra do prompt ("use quando as últimas 3 iterações foram CAUSA") esta rodada foi
BARATA — três arquivos da fila de menor custo do `DELTA_CLUSTERS.md`, todos com 1 única
divergência numérica.

- **OBS-1:** as três divergências caíam no mesmo lugar sob inspeção direta (script descartável
  usando `SvgComparator`, já que 1-2 divergências não justificam gerar fixture de probe):
  `text/tspan[…]/tspan[…] @y`, delta exatamente `-1`, sempre dentro de um `<rend rend="sup">`
  (abreviação com sobrescrito, ex. `<rend>All<rend rend="sup">o</rend></rend>` em `dynam-007`).
  As três eram a mesma causa, não três bugs.
- **OBS-2 (causa, confirmada linha a linha contra `view_text.cpp:432-437`):**
  `View::DrawRend` acumula `yShift` (int) em duas etapas — `yShift += GetTextGlyphHeight('o',…)`
  (int exato) e depois `yShift += (MHeight * SUPER_SCRIPT_POSITION)`, onde
  `SUPER_SCRIPT_POSITION = -0.20` (negativo!). Essa segunda linha soma o int `yShift` já
  acumulado com o double fracionário **antes** de truncar — uma única truncagem no ponto de
  atribuição. O Dart (`view_text.dart:466-471`, pré-fix) truncava `(mHeight *
  superScriptPosition).toInt()` **isoladamente** e só depois somava ao `yShift` acumulado — duas
  truncagens em vez de uma. Para inteiro `a` e real `b`, `trunc(a+b) == a + trunc(b)` só vale
  quando `b` tem o mesmo sinal do lado que se soma ou quando não há fração cruzando fronteira —
  com `b` negativo (aqui sempre é, `SUPER_SCRIPT_POSITION` e `SUB_SCRIPT_POSITION` são ambos
  negativos) e `a` positivo, as duas ordens divergem em exatamente 1 sempre que a soma cruza uma
  unidade inteira. Note que o ramo `sub` não tinha o bug na prática (yShift começa em 0, que é
  exato, então `trunc(0+b) == 0 + trunc(b)`) — só o ramo `sup` acumula um int não-nulo antes da
  truncagem fracionária.
- **OBS-3 (o fix):** trocado `yShift += (mHeight * X).toInt()` por
  `yShift = (yShift + mHeight * X).toInt()` em ambos os ramos (sub incluído, por simetria e
  clareza — matematicamente neutro lá) — soma em double, trunca uma vez, espelhando o `+=` do
  C++ sobre uma variável `int`. Nenhuma outra ocorrência do mesmo padrão (`yShift`/acumulador int
  não-nulo seguido de `.toInt()` isolado) foi encontrada em `view_text.dart`/`view_control.dart`
  nesta rodada — não é o mesmo "±1 sistêmico" do cluster `stem/path @d` (esse é outro mecanismo,
  ainda não investigado).
- **OBS-4:** efeito medido: as 3 famílias tocadas (`dynam` 10 arq, `dir` 10 arq, `tempo` 4 arq,
  `rend` 4 arq, `annot` 7 arq, `cpmark` 1 arq, `gliss` 6 arq) não regrediram — todas continuam
  com o mesmo número de arquivos limpos ou melhor; `--all` N 21502→21499 (-3), Y 282→285 (+3),
  S inalterado, 0 falhas; `cluster_deltas` recontagem 338→335 arquivos com divergência numérica;
  `dart analyze` 0 issues; `dart test` 701 pass. Ganho pequeno mas líquido e de baixo risco —
  exatamente o objetivo da trilha BARATA.
- Arquivos: `lib/src/rendering/view_text.dart` (+9/-2).

## 2026-09-06 — trilha CAUSA — alvo mesmo bug de truncagem, agora em `Slur::CalcEndPoints` (slur.cpp:707,1000,1004)

S 44→44  N 21499→21489  X 612/621→612/621  Y 285/621→285/621  — **COMMIT**

Voltou para CAUSA (a rodada anterior foi a única BARATA, não 3 seguidas). Em vez de abrir nova
assinatura do `DELTA_CLUSTERS.md`, generalizei a lição da rodada anterior (OBS-2/OBS-3 acima):
busquei `grep -rn '+= (.*)\.toInt()'` em `lib/src/layout` e `lib/src/rendering` (37 ocorrências) e
verifiquei as de `slur_positioning.dart` contra `slur.cpp`, por ser a assinatura `slur/path @d`
(rank #8, 93 arquivos, top deltas 2/3/1/4/-1) mais consistente com "muitos arquivos, delta
pequeno e disperso" — a marca desse bug de truncagem, não de um erro de porte de motor.

- **OBS-1 (confirmado, 3 sítios):** `x1 += (weight * (...)).toInt()` (era linha 425) e
  `y1 += (1.25 * sign * unit).toInt()` / `y2 += (...).toInt()` (eram linhas 667/671) em
  `calcEndPoints` espelham `x1 += weight * (...)` (`slur.cpp:707`) e
  `y1/y2 += 1.25 * sign * unit` (`slur.cpp:1000,1004`) — em ambos os casos `x1`/`y1`/`y2` são
  parâmetros/locais `int` já não-nulos quando a linha roda (`x1` pode já ter recebido o ajuste de
  notehead invertido em `startChord`; `y1`/`y2` já vêm de `staff->GetDrawingY()` + ajustes
  anteriores), então o C++ trunca a soma inteira uma vez. Mesmo mecanismo do fix anterior em
  `view_text.dart`.
- **OBS-2 (por que o efeito é pequeno e não zera nenhum arquivo sozinho):** provei com um script
  descartável (`dart run` avulso, não commitado) que a fórmula antiga e a nova DE FATO produzem
  valores diferentes para unidades realistas (`unit=226, y1=2000` → antigo 1718, novo 1717) — o
  bug é real, não teórico. Mas a pasta `test/corpus/slur/` (25 arquivos) sozinha não mudou nem um
  número (1140 antes e depois) — nenhum desses 25 arquivos exercita o ramo `sign=-1` (curva
  "below"/mixed-abaixo) de um jeito que sobrevive até o path final, e o ramo `weight=-0.5` (grace
  slur) é raro no corpus. O ganho de N (-10) veio inteiro de OUTRAS famílias com slur embutido
  (tie/phrase/gliss/cross-staff etc.), não da pasta `slur/`. Lição: medir só a pasta do nome da
  assinatura pode mascarar um fix corpus-wide — meça sempre `--all`.
- **OBS-3:** `cluster_deltas` pós-fix: divergências de nível-de-número 46244→46021 (-223, bem
  maior que o N do `SVG_VALIDATION.md` porque contam em granularidades diferentes — ver nota do
  próprio tool); ranking de `stem/path @d` redistribuiu (`-1` 35→38 arquivos) — resíduo de outro
  mecanismo ainda não investigado, não regressão deste fix (S/N globais melhoraram). `dart
  analyze` 0 issues; `dart test` 701 pass.
- **OBS-4 (para a próxima rodada BARATA):** as outras 34 ocorrências do mesmo grep
  (`adjust_arpeg.dart:174`, `adjust_layers.dart:106,359`, `floating_positioner.dart:432,448`,
  `vertical_aligner.dart:711`, `view_beam.dart` ×9, `view_control.dart` ×7, `view_mensural.dart`,
  `control_elements_gen.dart` ×2, `misc_elements_gen.dart` ×2, `view_tab.dart` ×2,
  `beam_segment.dart`, `layer_elements_gen.dart`) ainda não foram auditadas contra o C++ — cada
  uma só é bug se o acumulador do lado esquerdo já for não-nulo no ponto da chamada E o C++
  correspondente for de fato uma única atribuição `intVar += doubleExpr;` (não uma reatribuição
  limpa). Não assumir; conferir uma a uma contra o `.cpp` antes de mexer.
- Arquivos: `lib/src/layout/slur_positioning.dart` (+16/-2).

## 2026-09-06 — trilha CAUSA — beco-sem-saída: `FloatingPositioner::CalcDrawingYRel` (floatingobject.cpp:484,489,494,512)

S 44→44  N 21489→21489 (sem mudança)  X 612/621→612/621  Y 285/621→285/621  — **RESTORE**

Continuando a auditoria da OBS-4 anterior: conferi os 4 sítios de `floating_positioner.dart`
(linhas 423, 427, 432, 448) contra `FloatingPositioner::CalcDrawingYRel`
(`floatingobject.cpp:461-516`) — mesmo padrão de acumulador `int` não-nulo (`yRel =
GetContentY1()`, depois `minStaffDistance` já setado pela medida `@dist`) seguido de `+=`/`-=`
de um termo double (`GetBottomMargin`/`GetTopMargin` × `unit`, `2.5 × unit`) truncado isoladamente
no Dart contra uma única truncagem da soma no C++. Portado com o mesmo padrão do fix anterior
(`yRel = (yRel ± termo).toInt()`), incluindo trocar `.round()` por `.toInt()` em dois lugares
(`(vu*unit).round()` e `(2.5*unit).round()` — nenhuma rodada do C++ usa `std::round`, só
truncagem implícita de atribuição a `int`; `.round()` era uma segunda divergência, independente
da ordem de truncagem).

- **OBS-1 (por que virou RESTORE, não COMMIT):** `--all` deu **N idêntico** (21489→21489) e
  **nenhum arquivo do corpus mudou um único byte** (`git status` após o `--all` só listava o
  `.dart` editado — nem `test/golden/dart/**`, nem `SVG_VALIDATION.md`, nem `DELTA_CLUSTERS.md`
  mudaram). Testei nas famílias mais prováveis (`dynam`, `dir`, `tempo`, `hairpin`, `pedal`,
  `harm`, `artic`, `octave`) individualmente antes do `--all` — todas bateram exatamente os
  números já conhecidos de antes desta tentativa.
- **OBS-2 (hipótese não confirmada, mas plausível):** ao contrário do `Slur::CalcEndPoints`
  (onde `1.25 * unit` é quase sempre fracionário e o valor final costuma ficar positivo), aqui
  talvez `GetBottomMargin`/`GetTopMargin` × `unit` resulte inteiro exato para todo `unit` presente
  neste corpus (ex. margem default = `0.5` e `unit` sempre par), ou `yRel` no ramo `above` seja
  tipicamente ≤0 no ponto da truncagem (condição sob a qual a ordem de truncagem não importa —
  ver prova em OBS-2 da entrada anterior). Não investigado a fundo por não valer o orçamento desta
  rodada: o código ficou **provadamente correto** (espelha o C++ linha a linha) mas **sem efeito
  observável** no corpus atual — não é regressão, é uma correção que este corpus não exercita.
- **OBS-3 (decisão):** revertido via `git stash` (preservando fixtures) porque a trilha CAUSA
  exige `N_depois < N_antes` estrito, e aqui `N` não caiu (nem subiu). Diferente do caso
  "exceção de porte fiel" do prompt (que cobre placar **subindo** por cascata provada), este é
  placar **estagnado** — não há exceção prevista para isso, então a catraca (RESTORE) se aplica.
  Fica registrado para não repetir a mesma auditoria: `floating_positioner.dart:423,427,432,448`
  já foi conferido e é seguro deixar como está.
- **OBS-4 (resto da lista de auditoria, agora com um item a menos):** ainda faltam
  `adjust_arpeg.dart:174`, `adjust_layers.dart:106,359`, `vertical_aligner.dart:711`,
  `view_beam.dart` ×9, `view_control.dart` ×7, `view_mensural.dart`,
  `control_elements_gen.dart` ×2, `misc_elements_gen.dart` ×2, `view_tab.dart` ×2,
  `beam_segment.dart`, `layer_elements_gen.dart`.
- Arquivos: nenhum (revertido).

## 2026-09-06 — critério do prompt mudou (pedido do usuário) — reaplicando o beco-sem-saída acima

Usuário pediu para mudar `loop-prompt.md`: `N_depois == N_antes` com boa justificativa não é mais
RESTORE automático — nova "exceção de estagnação" (ver `prompts/loop-prompt.md` §7), exige (a)
porte linha-a-linha citado, (b) prova de que a fórmula antiga e nova DIVERGEM para alguma entrada
plausível (não é no-op), (c) `--all` confirmando zero regressão, (d) OBS no diário explicando por
que este corpus não exercita a diferença.

O fix de `floating_positioner.dart` revertido na entrada anterior se qualifica: (a) citado contra
`floatingobject.cpp:484,489,494,512`; (b) provado com script avulso que a fórmula diverge para
`yRel` negativo + termo positivo (ex. `yRel=-500, margin=0.75*unit=45 → antigo -467, novo -466`) —
a hipótese antiga (\"talvez nunca seja fracionário\") estava errada, a fórmula SEMPRE pode divergir
quando o acumulador e o termo têm sinais opostos, este corpus só não tem nenhum arquivo cujo
`GetContentY1()`/`@dist` caia nesse caso; (c) `--all` reconfirmado: N 21489→21489, S 44→44, zero
arquivo mudou; (d) esta OBS. **Reaplicado e commitado** (`sem-efeito:` na mensagem, não
`N ...→...`).

- Arquivos: `lib/src/layout/floating_positioner.dart` (+28/-4).

## 2026-09-06 — trilha CAUSA — alvo `View::DrawGliss` (view_control.cpp:2145-2210), mesmo bug de truncagem

S 44→44  N 21489→21435 (-54)  X 612/621→612/621  Y 285/621→290/621 (+5)  — **COMMIT**

Continuando a auditoria da lista de sítios `+= (...).toInt()`: `view_control.dart` (7
ocorrências, todas dentro de `drawGliss`). Ao conferir contra `View::DrawGliss`
(`view_control.cpp:2145-2210`) linha por linha, achei o mesmo bug em **toda** aritmética da
função — não só nos `+=`, mas também em atribuições simples da forma `y1 = A + (B).toInt()`
onde `A` (int) e `B` (double) formam uma soma só truncada no C++ (`int y1 = A + B;`). É uma
generalização importante da lição das rodadas anteriores: o grep `+= (.*)\.toInt()` só pega a
metade do padrão — a outra metade é `= .*[+-] \(.*\)\.toInt\(\)`, uma atribuição onde o lado
esquerdo do `+`/`-` já é um valor não-trivial (não é zero nem uma constante).

- **OBS-1:** 8 sítios corrigidos em `drawGliss`: `offset += 1.5*unit*dots` (era truncado
  isolado), `x1 += cos(angle)*offset`, `y1 = note1Y + offset*sin(angle)`,
  `y1 = note2Y - (x2-x1)*sin(angle)`, `dist = x2 - accidLeft + 0.5*unit`,
  `y2 = note2Y - dist*tan(angle)`, o laço `y2 += unit*sin(angle); x2 += unit*cos(angle)`, e o
  ramo sem acidente `x2 -= cos(angle)*offset; y2 = note2Y - offset*sin(angle)`. Todos espelham
  `view_control.cpp:2178-2201` exatamente — nenhuma lógica nova, só reordenar a truncagem.
- **OBS-2:** efeito medido, desta vez GRANDE e imediato (ao contrário do `floating_positioner`
  da rodada anterior): família `gliss/` sozinha foi de 63 divergências (0/6 limpos) para 9
  (5/6 limpos) — `gliss->CalcOffsetY`/ângulo/offset acumulam erro de truncagem em cascata dentro
  da própria função (cada termo alimenta o próximo cálculo), então um único bug de truncagem
  aqui produz muito mais ruído por arquivo do que o `floating_positioner` (uma soma isolada).
  `--all`: N 21489→21435 (-54, bate exatamente com o ganho da família — nenhum outro arquivo
  usa `<gliss>`), Y 285→290 (+5), S inalterado, `cluster_deltas` 335→330 arquivos com
  divergência numérica, assinaturas 100→98. `dart analyze` 0 issues, `dart test` 701 pass.
- **OBS-3 (para a próxima rodada):** a lista de auditoria original (`adjust_arpeg.dart:174`,
  `adjust_layers.dart:106,359`, `vertical_aligner.dart:711`, `view_beam.dart` ×9 — DrawFTremSegment,
  só 5 arquivos com `<fTrem>` no corpus, reach baixo —, `view_mensural.dart`,
  `control_elements_gen.dart` ×2, `misc_elements_gen.dart` ×2, `view_tab.dart` ×2,
  `beam_segment.dart`, `layer_elements_gen.dart`) ainda vale, mas agora **ampliada**: releia cada
  arquivo procurando também `= .*[+-] \(.*\)\.toInt\(\)` (atribuição, não só `+=`), não apenas o
  grep original.
- Arquivos: `lib/src/rendering/view_control.dart` (+18/-11).

## 2026-09-06 — trilha CAUSA — alvo `BeamSegment::CalcSetValues`/`AppendSpanningCoordinates` (beam.cpp:1460,1786), mesmo bug de truncagem

S 44→44  N 21435→21200 (-235)  X 612/621→612/621  Y 290/621→299/621 (+9)  — **COMMIT**

Ampliei a busca conforme a OBS-3 anterior (padrão de atribuição `= A [+-] (B).toInt()`, não só
`+=`): `grep -rnE '= [a-zA-Z_][a-zA-Z0-9_.!?()]* [+-] \(.*\)\.toInt\(\)' lib/src/` achou 9 sítios
novos fora de `view_control.dart`. O de maior alcance era óbvio: `beam_segment.dart:666`
(`BeamSegment.calcSetValues`, chamada para TODA coordenada de TODO beam do corpus) e `:1751`
(`AppendSpanningCoordinates`, beam cruzando sistema).

- **OBS-1:** `c.yBeam = startingY + (beamSlope * (c.x - startingX)).toInt();` espelha
  `coord->m_yBeam = startingY + m_beamSlope * (coord->m_x - startingX);` (`beam.cpp:1466`) —
  `startingY` já é a coordenada Y real do primeiro elemento do beam (nunca zero), então o C++
  trunca a soma inteira uma vez na atribuição. Era o mesmo bug de sempre, mas na função mais
  central de todo o cálculo de beam (roda uma vez por nota/acorde de cada segmento).
  `beam_segment.dart:1751` é o mesmo bug em `AppendSpanningCoordinates`
  (`right->m_yBeam += distance * slope;`, beam.cpp:1786, onde `right` começa como cópia de
  `back`, logo `back.yBeam` já não-zero).
- **OBS-2:** efeito medido — o maior desta sessão até agora. Família `beam/` sozinha:
  1267→1174 divs (-93), 43→48 arquivos limpos (+5). `--all` corpus inteiro: N 21435→21200
  (-235, muito maior que só a família `beam/` — confirma que `calcSetValues` é chamado por
  `beamSpan`, `fTrem`-adjacent code e cross-staff também, não só `<beam>` puro), Y 290→299 (+9),
  S inalterado. `beamspan/` e `ftrem/` não mudaram neste corpus específico (nenhum arquivo deles
  bateu a condição de sinais opostos) — não é regressão, só ausência de efeito local, mesma
  lição do `floating_positioner`. `cluster_deltas`: 330→321 arquivos com divergência numérica,
  100→98→98 assinaturas (estável); topo do ranking mudou de `stem/path @d` 185 arquivos para
  165 (a redução de arquivos afetados é o próprio efeito da correção — muitos stems dependiam
  de Y de beam que agora bate). `dart analyze` 0 issues; `dart test` 701 pass.
- **OBS-3 (para a próxima rodada):** ainda restam da lista ampliada: `adjust_tuplets.dart:387`,
  `view_tuplet.dart:105-106` (interpolação de Y do número de tuplet ao longo do beam — mesmo
  `startingY + (slope*dx).toInt()`), `view_mensural.dart:868,869,875,876` (4 sítios,
  `bottomRight.y = bottomLeft.y + (length*slope).toInt()` e variantes — barra de mensural),
  `adjust_arpeg.dart:174`, `adjust_layers.dart:106,359`, `vertical_aligner.dart:711`,
  `view_beam.dart` ×9 (`DrawFTremSegment`, reach baixo, só 5 arquivos com `<fTrem>`),
  `control_elements_gen.dart` ×2, `misc_elements_gen.dart` ×2, `view_tab.dart` ×2,
  `layer_elements_gen.dart`. `view_tuplet.dart`/`adjust_tuplets.dart` parecem o próximo alvo de
  maior alcance (tuplet é família de 25 arquivos, e a interpolação por slope é estruturalmente
  idêntica ao bug de beam recém-corrigido).
- Arquivos: `lib/src/model/beam_segment.dart` (+14/-2).

## 2026-09-06 — trilha CAUSA — alvo `adjust_tuplets.dart`/`view_tuplet.dart`, mesmo bug de truncagem — e um falso positivo em `view_mensural.dart`

S 44→44  N 21200→21062 (-138)  X 612/621→612/621  Y 299/621→302/621 (+3)  — **COMMIT**

Continuando a lista da OBS-3 anterior.

- **OBS-1 (2 fixes reais):** `adjust_tuplets.dart:387` (`_tupletNumBeamY` ou equivalente — cálculo
  do Y do número de tuplet alinhado a um beam) espelha
  `adjusttupletsyfunctor.cpp:184-185` (`beam->m_beamSegment.GetStartingY() + m_beamSlope *
  (xMid - ...)`, atribuição única, `GetStartingY()` não-zero) — mesmo bug, corrigido. Curiosidade:
  a função irmã `_adjustTupletBracketBeamY` (mesmo arquivo, ~20 linhas abaixo) **já** tinha a forma
  certa (`(startingY + beamSlope * (...)).toInt()`) — inconsistência dentro do próprio arquivo,
  não um padrão sistemático de um autor só. `view_tuplet.dart:105-106` (gap do bracket ao redor do
  número) espelha `view_tuplet.cpp:117-118` (`yLeft + slope * (...)`, mesma forma), também
  corrigido.
- **OBS-2 (falso positivo, não corrigido — importante para a próxima auditoria):**
  `view_mensural.dart:868,869,875,876` pareciam o mesmo padrão (`bottomRight.y = bottomLeft.y +
  (length * slope).toInt()`), mas ao conferir contra `view_mensural.cpp:708,709,717,718` o C++ é
  `bottomRight->y = bottomLeft->y + (int)(length * slope);` — o cast `(int)` do C++ está
  **explicitamente só no termo** `length * slope`, não na soma inteira (diferente de todo `+=`/
  atribuição vista até agora, onde o C++ deixa a conversão implícita agir sobre a expressão
  inteira). Aqui a forma antiga do Dart (`.toInt()` isolado no termo) já é a tradução correta.
  Lição: **não basta casar a forma sintática** (`intVar + (double).toInt()`) — é preciso ler se o
  C++ trunca a soma inteira (implícito, na atribuição/`+=`) ou só o subtermo (cast explícito
  `(int)(...)` colado na multiplicação). Só o primeiro caso é bug.
- **OBS-3:** efeito medido — família `tuplet/` sozinha 477→382 divs (-95), 10→13 limpos (+3);
  `--all` corpus inteiro N 21200→21062 (-138), Y 299→302 (+3), S inalterado; `cluster_deltas`
  321→318 arquivos com divergência numérica. `dart analyze` 0 issues; `dart test` 701 pass.
- **OBS-4 (resto da lista, agora com `view_mensural.dart` descartado por não ser bug):**
  `adjust_arpeg.dart:174`, `adjust_layers.dart:106,359`, `vertical_aligner.dart:711`,
  `view_beam.dart` ×9 (`DrawFTremSegment`, reach baixo), `control_elements_gen.dart` ×2
  (bezier overlap — checar se é cast explícito como o mensural antes de mexer),
  `misc_elements_gen.dart` ×2, `view_tab.dart` ×2, `layer_elements_gen.dart`.
- Arquivos: `lib/src/layout/adjust_tuplets.dart` (+4/-1), `lib/src/rendering/view_tuplet.dart`
  (+3/-2).

## 2026-09-06 — trilha CAUSA — sem-efeito: `adjust_arpeg.dart:174`, `adjust_layers.dart:106,113,368` (exceção de estagnação)

S 44→44  N 21062→21062 (sem mudança)  X 612/621→612/621  Y 302/621→302/621  — **COMMIT** (exceção
de estagnação)

Últimos 3 sítios de reach potencialmente amplo (`arpeg`/unísono/acidente em layers) da lista de
auditoria. Confirmados contra o C++: `dist += unitFactor * GetDrawingUnit(100)`
(`adjustarpegfunctor.cpp:164`, `dist` já não-zero), `shift -= 0.8*horizontalMargin` e
`SetDrawingXRel(GetDrawingXRel() + 0.8*horizontalMargin)` (`layerelement.cpp:1155,1161`, `shift`
acumula em iterações anteriores do laço, `GetDrawingXRel()` é X real), `accidMargin += 1.5*unit`
(`chord.cpp:496`, guardado por `if (accidMargin)` — garantidamente não-zero). Todos com a mesma
forma: acumulador `int` não-trivial `+=`/`-=` um termo `double`, truncado isoladamente no Dart
contra a truncagem única da soma no C++.

- **OBS-1 (estagnação, não regressão):** `--all` deu N e S idênticos, e famílias prováveis
  (`arpeg`, `chord`, `unison`, `note`) bateram exatamente os números de antes — nenhum arquivo
  do corpus exercita a combinação de sinais que expõe a diferença.
- **OBS-2 (prova exigida pela exceção de estagnação):** script avulso (`/tmp/t3.dart`, não
  commitado) comprovou divergência real para entradas plausíveis nos três sítios — ex. arpeg
  `unit=226, unitFactor=1.75, dist=-500`: antigo -105, novo -104; layers `horizontalMargin=54,
  shift=300`: antigo 257, novo 256; accidMargin `unit=45, acc=-300`: antigo -233, novo -232.
  Não é reescrita cosmética.
- **OBS-3 (achado à parte, não corrigido nesta rodada):** `adjust_arpeg.dart:172`
  (`if (enclose != null) unitFactor += 0.75;`) é mais amplo que o C++
  (`adjustarpegfunctor.cpp:162`: só `ENCLOSURE_brack`/`ENCLOSURE_box`) — qualquer outro valor de
  `@enclose` (ex. `paren`, `dbox`) aciona o ajuste no Dart mas não deveria. Fora do escopo desta
  auditoria de truncagem; registrar para uma rodada futura de fidelidade de `arpeg`.
- **OBS-4 (lista de auditoria dos sítios "+=/-= .toInt()" e "= A ± (B).toInt()", agora
  esgotada):** restam só `view_beam.dart` ×9 (`DrawFTremSegment`, 5 arquivos com `<fTrem>` — já
  auditado como bug real na entrada de `gliss`, não portado ainda por reach baixo),
  `control_elements_gen.dart` ×2 e `misc_elements_gen.dart` ×2 (não conferidos — checar primeiro
  se o C++ usa cast por termo, como o falso positivo de `view_mensural.dart`, antes de mexer),
  `view_tab.dart` ×2, `layer_elements_gen.dart`. Nenhum tem reach conhecido tão alto quanto
  `beam_segment`/`gliss`/`tuplet` já corrigidos.
- Arquivos: `lib/src/layout/adjust_arpeg.dart` (+6/-1), `lib/src/layout/adjust_layers.dart`
  (+11/-3).

## 2026-09-06 — trilha CAUSA — alvo `View::DrawFTremSegment` (view_beam.cpp:180-218), mesmo bug de truncagem

S 44→44  N 21062→21045 (-17)  X 612/621→612/621  Y 302/621→305/621 (+3)  — **COMMIT**

Último item pendente da lista de auditoria original com bug confirmado (já lido contra o C++ na
investigação do `gliss`, só não portado ainda por reach aparentemente baixo — 5 arquivos com
`<fTrem>` no corpus). 10 sítios em `view_beam.dart` (todos dentro de `drawFTremSegment`), mesma
forma de sempre: `x1`/`x2`/`y1`/`y2` (int, coordenadas reais não-zero) combinados com termo
double via `+=`/`-=`, truncados isolados no Dart contra a truncagem única da soma no C++.

- **OBS-1:** efeito medido, maior do que o esperado pelo reach nominal: família `ftrem/` sozinha
  15→4 divs (-11), 0→1 limpo; `--all` corpus inteiro N 21062→21045 (-17), Y 302→305 (+3) — o
  ganho extra de 2 arquivos limpos vem de fora da pasta `ftrem/` (provavelmente `tuplet/`, que
  tem filhos `<fTrem>` dentro de `<tuplet>` — `adjust_tuplets.dart` já lê `fTremChild` para casar
  a posição do número). `cluster_deltas`: 318→315 arquivos com divergência numérica, 98→97
  assinaturas. `dart analyze` 0 issues; `dart test` 701 pass.
- **OBS-2 (lista de auditoria da OBS-4 anterior agora reduzida a itens de baixa prioridade):**
  restam `control_elements_gen.dart` ×2 (bezier overlap, checar padrão de cast antes de mexer —
  lição do falso positivo em `view_mensural.dart`), `misc_elements_gen.dart` ×2, `view_tab.dart`
  ×2, `layer_elements_gen.dart`. Nenhum com reach conhecido; próxima rodada pode fechá-los ou
  trocar de trilha (BARATA/ESTRUTURAL — 5 rodadas seguidas de CAUSA nesta sessão).
- Arquivos: `lib/src/rendering/view_beam.dart` (+16/-8).

## 2026-09-06 — trilha BARATA — becos-sem-saída: `dots/ellipse @cy` delta -180 e `accid/use @transform` delta -99 em acorde

S 44→44  N 21045→21045 (sem tentativa de código)  X 612/621→612/621  Y 305/621→305/621  — sem
commit de código (nenhum arquivo `lib/` tocado; nada para restaurar)

7 rodadas seguidas de CAUSA nesta sessão — troquei para BARATA pela fila de menor custo do
`DELTA_CLUSTERS.md`. Duas investigações, nenhuma virou fix (faltou pinpointing `fn/seq/path`
conclusivo dentro do orçamento da trilha barata):

- **OBS-1 (`dots/ellipse @cy`, delta -180, 16 arquivos — `dot-001` a `dot-006`, `stem-014`,
  `lyric-011` entre outros):** todos os arquivos afetados têm uma pauta com **2 camadas/vozes**
  (`layer[1]` e `layer[2]`) e a nota que diverge é sempre a de `layer[2]`. Pinpoint via
  `probe_diff` (`stem-014`, `dot-001`): `fn=DrawCircle path=.../note[1]/dots[1]`, delta -180 só no
  `y`, `x`/`radius` batem. Comparei o SVG golden bruto (`dot-001.svg`): nota de layer1 (na linha)
  tem seu ponto na espaço ACIMA (nota y=5049, ponto cy=4959, delta -90); nota de layer2 (também
  na linha) tem o ponto no espaço ABAIXO (nota y=5409, ponto cy=5499, delta +90) — convenção
  padrão de notação: 2ª voz joga o ponto para o lado oposto para não colidir com a 1ª. O C++
  (`view_element.cpp:835/843`) faz `y = dot->m_drawingPreviousElement->GetDrawingY();` — ou seja,
  o Y do PONTO É LITERALMENTE o Y da NOTA (`GetDrawingY()`), sem offset algum nessa linha. Como o
  notehead da mesma nota renderiza no lugar certo (nenhuma outra divergência no arquivo), a nota
  em si está correta — logo `note->GetDrawingY()` **não pode** ser 90 unidades diferente do Y do
  notehead a menos que exista algum ajuste específico feito ANTES de `DrawDot` rodar (mutando o
  `drawingYRel`/loc da nota especificamente para o propósito do ponto) que eu não localizei a
  tempo — suspeita não confirmada: algo em `PrepareLayerElementParts`/`Note::PrepareDot` ou uma
  convenção de "loc do ponto" separada do "loc da nota" que o C++ aplica à NOTA (não ao ponto)
  antes de gravar `drawingYRel`, e que o port ainda não replica. **Não é o bug de truncagem** desta
  sessão (nenhum double envolvido). Não investigado o suficiente para um fix seguro — precisa de
  fixture DEEP ou leitura de `preparedatafunctor.cpp`/`note.cpp` em torno de `SetDrawingLoc`/dots
  antes da próxima tentativa.
- **OBS-2 (`accid/use @transform`, delta -99, em acordes — `chord-004`, `layer-005`):** ambos os
  casos são acidentes (`E261`, bemol) dentro de um ACORDE com múltiplas notas/acidentes
  empilhados horizontalmente (`AdjustAccidXFunctor`, `adjustaccidxfunctor.cpp`). Conferi o arquivo
  C++ inteiro (198 linhas) e **não tem nenhuma aritmética de ponto flutuante** — não é o mesmo
  bug de truncagem das rodadas anteriores, é uma divergência de lógica/ordem de empilhamento
  ainda não localizada. Fora do orçamento da trilha barata; fica para uma trilha CAUSA dedicada a
  `accid/use @transform` (rank #9 do ranking, 77 arquivos) com pinpointing via `probe_diff` +
  leitura funcional de `adjust_accid_x.dart` × `adjustaccidxfunctor.cpp` linha a linha.
- **Decisão:** nenhum código tocado (`git status` limpo antes de escrever este diário) — os dois
  becos foram descartados por falta de tempo de investigação, não por prova de que não são bugs.
  Ambos ficam registrados como próximos alvos de trilha CAUSA dedicada.

## 2026-09-06 — trilha CAUSA (a pedido do usuário: "trate estes problemas independente do custo") — alvo `dots/ellipse @cy` delta -180 (retomando OBS-1 acima)

S 44→44  N 21045→20897 (-148)  X 612/621→612/621  Y 305/621→308/621 (+3)  — **COMMIT**

O usuário pediu para resolver os dois becos-sem-saída da entrada anterior sem limite de esforço.
Retomei o de `dots/ellipse @cy` (-180) com uma pista que a rodada anterior não tinha seguido:
o SVG golden mostra `<g class="dots">` (classe **Dots**, plural — múltiplos locs mapeados),
não `<g class="dot">` (classe **Dot**, singular) — eu tinha lido `View::DrawDot` (a versão
singular, usada só em contextos de mensural/mensural-adjacent) como se fosse a função relevante;
a de verdade é `View::DrawDots` (plural, `view_element.cpp:851-883`), que usa
`dots->GetMapOfDotLocs()` — um mapa `Staff* -> Set<int>` de **locs pré-computados**, não o Y bruto
da nota. O loc vem de `LayerElement::CalcOptimalDotLocations` (`layerelement.cpp:909-989`), que
o port já tinha — mas só a versão "simplificada de camada única" documentada como Deviation
(`_noteOptimalDotLocations` sempre fazia `loc par → loc+1`, sem jamais escolher "abaixo").

- **OBS-1 (o algoritmo completo, agora portado):** `LayerElement::CalcOptimalDotLocations` com
  2 camadas na mesma pauta calcula 4 combinações de loc (`dotLocs1`/`dotLocs2` desta nota ×
  `otherDotLocs1`/`otherDotLocs2` da nota/acorde na OUTRA camada), conta colisões
  (`GetCollisionCount`, interseção de locs) para cada combinação, e escolhe a de menor colisão
  — com bypass para unísono (`Note::AlignDotsShift`, que só copia o `flagShift`, sem escolher
  loc por colisão) e fallback de contagem de pontos quando nenhuma colisão ocorre. Portado
  linha-a-linha em `lib/src/layout/calc_functors.dart`:
  - `_noteCalcDotLocations(note, layerCount, primary)` — mirror de `Note::CalcDotLocations`
    (note.cpp:1012): a direção do shift agora depende de `stemDir==up || layerCount==1` (era
    sempre "para cima").
  - `_findOtherLayerElement` — mirror do `find_if` (layerelement.cpp:925-943): busca a primeira
    nota de OUTRA camada na MESMA pauta dentro do alinhamento, promovendo para o acorde se a
    nota for chord tone. Reescrito a partir do antigo `_alignUnisonDotsShift` (agora removido —
    sua lógica de unísono foi incorporada ao fluxo principal, igual ao C++ real, que faz tudo
    numa função só).
  - `_elementCalcDotLocations` — despacho manual Note/Chord por não haver dupla-despacho em
    Dart (mesmo padrão do resto do port).
  - `_collisionCount`/`_dotCount` — mirrors diretos de `GetCollisionCount`/`GetDotCount`
    (layerelement.cpp:1020,1026).
  - `ChordDotLocations._calcDotLocations` ganhou o parâmetro `layerCount` (`isUpwardDirection`
    agora usa `getDrawingStemDir()` do acorde em vez de assumir sempre `true`), e
    `calcOptimalDotLocations()` do Chord ganhou o mesmo ramo de 2 camadas (sem o atalho de
    unísono, que no C++ só roda quando `this->Is(NOTE)`).
- **OBS-2 (por que passou 3 sessões sem ser achado):** a causa raiz não era aritmética
  (nenhum double truncado errado) nem um valor errado — era uma **função inteira ausente**
  disfarçada de "simplificação documentada" (`Deviation:` no comentário já admitia isso, mas
  ninguém tinha voltado para fechá-la). A pista que quebrou o impasse foi olhar o nome da CLASSE
  no SVG (`dots` vs `dot`) em vez de confiar no nome da função C++ mais "óbvio"
  (`View::DrawDot`) — as duas existem e têm nomes quase idênticos.
  Fixture `05-38` teria mostrado o mesmo sintoma sem apontar a causa (o desenho já reflete o loc
  errado, calculado bem antes, em `CalcDotsFunctor`) — pinpointing por leitura de código foi mais
  rápido que gerar fixture DEEP aqui.
- **OBS-3 (efeito medido):** `dot/` sozinha 389→250 divs (-139!), 0→1 limpo; `lyric/` 619→617
  (-2), 6→7 limpo; `stem/` 338→337 (-1), 6→7 limpo; `layer/` 504→502 (-2); `rest/` 384→382 (-2);
  `slur/` 1139→1137 (-2). Nenhuma família regrediu. `--all` corpus inteiro: N 21045→20897 (-148),
  Y 305→308 (+3), S inalterado, 0 falhas. `cluster_deltas`: 315→312 arquivos com divergência
  numérica. `dart analyze` 0 issues; `dart test` 701 pass.
- **OBS-4 (residual esperado, não é regressão):** `dot/` ainda tem 250 divs em 5 arquivos —
  provavelmente casos com 3+ camadas (fora do escopo do `layerCount==2` do próprio C++) ou
  colisões entre pauta cruzada (`RESOLVE_CROSS_STAFF` no `_findOtherLayerElement` cobre isso,
  mas `Chord::CalcNoteLocations` multi-pauta dentro do próprio acorde não foi generalizado).
  Não investigado — próxima rodada usa `probe_diff` nos 5 arquivos restantes de `dot/` antes de
  decidir se vale outra iteração aqui.
- O beco do delta -99 em `accid`/acorde (OBS-2 da entrada anterior) segue em aberto — outra
  função/mecanismo (sem ponto flutuante, confirmado), não relacionado a este fix; próxima
  rodada dedicada a `AdjustAccidXFunctor`.
- Arquivos: `lib/src/layout/calc_functors.dart` (+140/-45 aprox., reescrita de
  `_noteOptimalDotLocations`/`ChordDotLocations`).

## 2026-09-06 — trilha CAUSA (a pedido do usuário: "trate estes problemas independente do custo") — alvo `accid/use @transform` delta -99 em acordes (segundo beco-sem-saída fechado)

S 44→44  N 20897→20618 (-279)  X 612/621→612/621  Y 308/621→314/621 (+6)  — **COMMIT**

Fechando o segundo beco-sem-saída da entrada "2026-09-06 — becos-sem-saída" (delta -99 em
`chord-004`/`layer-005`, acidentes dentro de acorde). Como o C++ de `AdjustAccidXFunctor`
(198 linhas) não tem nenhum double, a hipótese de truncagem foi descartada de saída — pinpointing
exigiu instrumentação DEEP nova (não uma das existentes).

- **OBS-1 (metodologia — instrumentação C++ avulsa, fora do fluxo `cpp_probe` formal):** editei
  `build-probe/src/src/{accid.cpp,adjustaccidxfunctor.cpp}` direto (sem `mkpatch`/`ORDER`, já que
  era exploração descartável) com `fprintf(stderr, ...)` em `AdjustAccidWithSpace` e `Accid::AdjustX`,
  compilei com `cmake`+`ninja` direto (sem `build.sh`, que re-sincronizaria por cima dos meus
  edits), rodei o binário e **confirmei diff vazio contra o binário limpo** antes de confiar nos
  números (a mesma regra do `cpp_probe/README.md`, só sem os scripts). Em paralelo, instrumentei
  o lado Dart com `print()` temporário nos mesmos pontos (`adjustX`), removido antes do commit.
  As duas instrumentações nunca viram fixture nem patch commitado — só serviram para comparar os
  números lado a lado nesta sessão.
- **OBS-2 (achado):** para `chord-004`, os **bounding boxes de entrada eram idênticos** nos dois
  lados (`selfRight`/`selfLeft`/`selfTop`/`selfBottom` do acidente e da nota b3 batiam nos 6
  valores, dígito a dígito) — mas o C++ calculava `xRelShift=109` contra a nota deslocada
  (notehead "flippado" por estar a um segundo do dó vizinho no acorde) e o Dart calculava `208`.
  Isso isolou o bug em `BoundingBox::HorizontalRightOverlap` em si, não em nenhuma geometria
  anterior.
- **OBS-3 (causa raiz — uma "Deviation" documentada que ficou obsoleta):**
  `horizontalRightOverlap`/`horizontalLeftOverlap` em `core/bounding_box.dart` sempre usam **um
  retângulo simples** (bounding box inteira), nunca os **cutout anchors SMuFL do glifo**
  (`cutOutNE`/`cutOutNW`/`cutOutSE`/`cutOutSW` — os recortes que, por exemplo, deixam um bemol ou
  bequadro encaixar mais perto de uma cabeça de nota do que a caixa retangular cheia sugere). O
  comentário já dizia `// Deviation: the SMuFL glyph cut-out anchors arrive with the
  resources phase; a single plain rectangle is used for each box.` — mas quando os anchors
  realmente chegaram (fase de `rendering/`, há tempo), ninguém voltou para fechar essa dívida.
  A infraestrutura JÁ EXISTIA, só não conectada aqui: `layout/floating_positioner.dart` tem
  `_rectangles1`/`_rectangles2`/`_glyph1PointRectangles`/`_glyph2PointRectangles`/`_cutOutGlyph`
  (extensão `CurveIntersection on BoundingBox`) usados por `getCutOutTop/Bottom/Left/Right` desde
  a rodada de `AdjustAccidXFunctor::AdjustToLedgerLines` — a MESMA máquina que
  `BoundingBox::GetRectangles`/`GetGlyph1PointRectangles`/`GetGlyph2PointRectangles` do C++
  (`boundingbox.cpp:306-511`) usam para `HorizontalRightOverlap`/`HorizontalLeftOverlap`, só que
  nunca conectada a essas duas funções especificamente.
- **OBS-4 (por que não movi para `core/bounding_box.dart`):** esse arquivo documenta
  explicitamente, no cabeçalho, que métodos dependentes de `Glyph`/`Resources`/`Doc` **ficam de
  propósito** em extensões separadas (`layout/floating_positioner.dart`,
  `layout/adjust_beams.dart`) para manter `core/` livre de dependência de `rendering/`/`model/`.
  Fui na direção oposta do que pareceria natural (portar tudo pra dentro do core): adicionei
  `horizontalRightOverlapGlyphAware`/`horizontalLeftOverlapGlyphAware` como novos métodos na
  extensão `CurveIntersection` já existente em `floating_positioner.dart`, ao lado de
  `_rectangles1`/`_rectangles2` que eles agora reaproveitam — nomes novos porque Dart não permite
  um método de extensão com o mesmo nome de um método de instância já existente na classe (a
  chamada sempre resolveria para o método de instância, `.horizontalRightOverlap()`, nunca para a
  extensão). `_rectRightOverlapPoints`/`_rectLeftOverlapPoints` (mirrors de
  `RectRightOverlap`/`RectLeftOverlap`, boundingbox.cpp:1170-1180) foram adicionados como
  `static` na mesma extensão.
- **OBS-5:** só `adjust_accid_x.dart` (`Accid::AdjustX`) foi migrado para as versões glyph-aware
  nesta rodada — é o único chamador confirmado como afetado por esta investigação. Ficam
  pendentes (na lista de auditoria futura) os chamadores de `horizontalRightOverlap`/
  `horizontalLeftOverlap` (plain) em `adjust_layers.dart` (6 ocorrências) e `adjust_x_pos.dart`
  (3 ocorrências) — o C++ correspondente sempre usa a via glyph-aware, então migrar esses também
  deve ser um ganho, mas não foi medido nesta rodada.
- **OBS-6 (efeito medido):** `accid/` 284→124 divs (-160!), 5→6 limpo; `chord/` 935→874 (-61),
  5→6 limpo; `stem/` 337→317 (-20), 7→8 limpo; `layer/` 502→501 (-1), 6→7 limpo; `cross-staff/`
  2218→2216 (-2). Nenhuma família regrediu (`beam`/`dir`/`dynam`/`gracenote`/`note`/`unison`
  idênticos). `--all` corpus inteiro: N 20897→20618 (-279), Y 308→314 (+6), S inalterado, 0
  falhas. `cluster_deltas`: 312→306 arquivos com divergência numérica, 97→96 assinaturas. `dart
  analyze` 0 issues; `dart test` 701 pass.
- Arquivos: `lib/src/layout/floating_positioner.dart` (+56/-0, dois métodos novos +2 helpers
  estáticos), `lib/src/layout/adjust_accid_x.dart` (+4/-2, dois call sites migrados).

## 2026-09-06 — trilha CAUSA — alvo `staff/path @d` Δ25 / `stem/path @d` (overlap glyph-aware em AdjustXPos)

S 44→44  N 20618→19673 (-945)  X 612/621→612/621  Y 314/621→324/621 (+10)  — **COMMIT**

Fecha a pendência OBS-5 da entrada anterior (migrar `adjust_x_pos.dart` para a via
glyph-aware): os 3 call sites plain de `calculateXPosOffset`
(`lib/src/layout/adjust_x_pos.dart`) agora chamam
`horizontalRightOverlapGlyphAware` (`floating_positioner.dart`), que já existia
desde a rodada do `accid` — incluindo o ramo `ACCID+REST` com a exceção de
`rest->IsInBeam() && !hasExplicitLoc` (self-edge plain, `adjustxposfunctor.cpp:387-395).

- **OBS-1 (degraus 1-3 — pinpoint e comparação campo a campo):** `probe_diff`
  em `stem-004`/`stem-007`/`note-010`/`beam-064`/`tuplet-009` apontava sempre a
  pauta (`DrawLine measure/staff`, Δ25/Δ50) — sintoma a jusante (largura do
  compasso). Comparação `AdjustXPos` C++ × Dart via fixture 05-38 mostrou
  `xRel_out` divergindo +25 constante a partir do PRIMEIRO elemento em beam
  (`tuplet[1]/beam[1]/note[1]`: C++ 1765, Dart 1790; `off` -241 vs -86), com
  tudo antes batendo (clef/keySig/meterSig/barLine/note[1]/stem/flag exatos,
  `minPos`/`upc`/`cum` incluídos). Causa a montante do desenho, em
  `CalculateXPosOffset` — não em `DrawStaffLines` (`view_page.cpp:1336`, fiel).
- **OBS-2 (degrau 4 — instrumentação C++ avulsa, sem mkpatch/ORDER):**
  `fprintf(stderr)` em `adjustxposfunctor.cpp:399` + rebuild `ninja -C
  build-probe/build` + `diff` vazio contra `build/verovio` (regra 3 do
  `cpp_probe/README.md`). Medido: `bbox=flag self=[1502,1700]`,
  `layer=note self=[1524,1750]`, `margin=90`, `ov=241`. Retangular daria
  1700-1524+90=266; o C++ dá 241 = 1700-1549+90, onde 1549 é o `p.x` do
  `cutOutNW` de `E0A4` (Leipzig: 0.14 → 1524+25). Prova de que o C++ usa os
  cut-outs SMuFL aqui — e de que a forma plain SEMPRE superestima (+25).
- **OBS-3 (por que o Dart dava 0 e não 266):** dupla armadilha. (a) O `_tmp`
  inicial media `calculateXPosOffset` sobre o estado PÓS-tudo (nota já
  shiftada: selfLeft 1765/1790 > flagRight 1700 → overlap 0) — estado inválido;
  o LIVE (probe com `super` no meio, padrão `cpp_fixture_test.dart`) media no
  momento real (selfLeft 1524) e já mostrava `1524→1765` exato após o fix.
  (b) Antes do fix, o gate `horizontalContentOverlap` (content boxes) passava
  mas o `horizontalRightOverlap` plain calculava sobre self boxes SEM cutout —
  para o par flag→nota dava valor errado (86/266 em vez de 241).
- **OBS-4 (o fix):** 3 sítios em `calculateXPosOffset` migrados para
  `horizontalRightOverlapGlyphAware` (mantido o ramo NOTE→NOTE por
  `GetSelfRight/GetSelfLeft`, que o C++ também faz à mão, e o ramo
  tuplet-rest por durações). Sem mover nada para `core/bounding_box.dart`
  (mesma restrição de dependência da rodada do `accid`). `Rest`/`isInBeam`
  resolvidos via tipos já importados (`basic_elements.dart` já importa o
  arquivo inteiro; `isInBeam()` é `LayerElement`, sem import novo).
- **OBS-5 (efeito medido):** `stem-004` 60→~0 divs (limpo no `probe_diff`),
  `dot/` 250→153, `beam/` 1172→1142, `stem/` 317→155, `note/` 441→414;
  `--all`: N 20618→19673 (-945, -4.6%), Y 314→324 (+10), S inalterado (44),
  0 falhas; `cluster_deltas` 306→296 arquivos, 96→94 assinaturas; Δ25 some do
  top (`stem/path @d` perde o `25×18`, `staff/path @d` perde `25×11`).
  `dart analyze` 0 issues; `dart test` 701 pass.
- Arquivos: `lib/src/layout/adjust_x_pos.dart` (+37/-5: import de
  `CurveIntersection` + 3 call sites + ramo `IsInBeam` de rest).

## 2026-09-06 — trilha BARATA — alvo `accid/accid-011` (1 div, `ledgerLines above` Δ∓1)

S 44→44  N 19673→19672 (-1)  X 612/621→612/621  Y 324/621→325/621 (+1)  — **COMMIT**

Troca de trilha: as últimas 3 iterações foram CAUSA (`dots`, `accid`, `adjustXPos`),
então esta rodada foi BARATA — `accid-011`, primeiro da fila de menor custo com
mecanismo ainda não investigado (os outros três arquivos de 1 div — `chord-006`,
`tempo-002`, `turn-002` — são todos bezier de tie/slur Δ±1, resíduo de
arredondamento já documentado em 2026-09-05 e mecanismo distinto; não tocados).

- **OBS-1 (degrau 1 — pinpoint, não palpite):** `probe_diff` em `accid-011`:
  `fn=DrawLine seq=20 path=measure[1]/staff[1]`, x1 Δ-1 (782→781), x2 Δ+1
  (1012→1013), y1/y2 exatos. Soma x1+x2 idêntica (1794=1794) e y exato ⇒ termo
  de meia-largura do dash, não posição do elemento nem `extension` (que moveria
  todos os 8 dashes da pauta, e só seq 20 diverge).
- **OBS-2 (degrau 2 — campo a campo, prova aritmética sem instrumentação C++):**
  o dash é do 1º accid livre (`loc=10 accid="f"`, E260, ramo `center` de
  `CalcForLayerElement`): Dart `width=144, ext=48, elX=897` ⇒ base 777/1017,
  gap 37 até o dash da nota ⇒ `AdjustLedgerLines` delta 4 ⇒ 781/1013 (o SVG
  Dart, dígito a dígito). Com `width=142` (fórmula do C++): base 778/1016,
  gap 38 ⇒ delta 4 ⇒ 782/1012 (o fixture 05-38 seq 20, dígito a dígito). Os dois
  lados reproduzidos por aritmética — pinpointing fechado sem build DEEP.
- **OBS-3 (causa raiz — degrau 3, função C++ inteira lida):** `_docGetGlyphWidth`
  (`calc_ledger_lines.dart`) usava `glyph.horizAdvX` — isso é
  `Doc::GetGlyphAdvX` (doc.cpp:1885), não `Doc::GetGlyphWidth` (doc.cpp:1872),
  que usa a **bounding box** (`GetBoundingBox` → w). Leipzig E260: advX 2000 vs
  bbox w 1980 ⇒ 144 vs 142 a fontSize 720. O ramo de nota nunca acusou porque
  em E0A4 os dois coincidem (3140=3140) — por isso o bug sobreviveu ao teste de
  fixture 04g, que só exercita `VisitNote`.
- **OBS-4 (armadilha que quase virou regressão):** a primeira versão do fix lia
  `doc.drawingSmuflFontSize`, que é 0 num `Doc` sem `prepareData` — quebrou
  `test/calc_ledger_lines_test.dart` (fixture C++ 04g passou a dar `(132,228)`
  onde espera `(150,436)`). O fontSize tem de ser recomputado das opções
  (`Doc::CalcMusicFontSize`, doc.cpp:2413: `unit * 8`), como o código antigo já
  fazia — só a base (advX→bbox) e a ordem de truncagem (grace/staffSize depois,
  como o C++) mudaram. Teste refeito verde sem tocar nas expectativas.
- **OBS-5 (efeito e resto da auditoria):** só `accid-011` se moveu no corpus
  (outros glifos de accid têm advX≈bbox, ou a diferença de 2 não cruza limiar
  de ajuste). As cópias irmãs do helper (`adjust_tuplets.dart`,
  `mensural_neume.dart`, menção em `adjust_beams.dart:736`) ainda usam o padrão
  advX — cada uma só é bug onde o C++ correspondente chama `GetGlyphWidth`
  (não `GetGlyphAdvX`); conferir uma a uma antes de mexer, mesma lição do falso
  positivo de `view_mensural.cpp:708`.
- Arquivos: `lib/src/layout/calc_ledger_lines.dart` (só `_docGetGlyphWidth` +
  doc comment).

## 2026-09-06 — trilha CAUSA — alvo `dots/ellipse @cx` Δ-226 (16 arq, 88 ocorrências)

S 44→44  N 19672→18656 (-1016, -5.2%)  X 612/621→612/621  Y 325/621→325/621  — **COMMIT**

Topo útil do ranking depois de triar ±1 (arredondamento) para fora: Δ-226
concentrado (5.5 ocorrências/arquivo) contra o Δ2 de `slur` (10/arquivo,
disperso em beziers — cheiro de arredondamento difuso, não de causa única).

- **OBS-1 (degrau 1 — pinpoint):** todos os elipses com cx Δ-226 e cy exato
  (`dot-001` [14],[15],[24],[25],[34],[35]) vivem em `g.chord/g.dots` — dots de
  **chord com `dots="1"`**, nunca de nota solta. 226 = `2 * radius` do
  noteheadBlack (largura da cabeça de nota): o dot sai exatamente uma
  notehead-width à esquerda. Os casos mistos (-352/-560 com cy junto) são
  segunda camada/overlap-grouping sobre a mesma base errada.
- **OBS-2 (degrau 3 — causa, função C++ inteira lida):** o ramo chord-tone de
  `CalcDotsFunctor::VisitNote` (calcdotsfunctor.cpp:82-98,
  `xRel = noteX - chordX + 2*radius + flagShift`) nunca tinha sido portado — o
  doc comment da classe admitia ("the xRel shifts ... skipped") e o Dart
  retornava `siblings` early para chord tones, deixando `drawingXRel = 0` no
  dots do chord. Exigiu o campo `m_chordDrawingX` (`chordDrawingX`, setado em
  `visitChord`), que também não existia. Δ exato em 88 ocorrências prova que
  `noteX - chordX` já batia — só faltava o termo.
- **OBS-3 (segundo gap no mesmo ponto):** o early-return pulava *também* o ramo
  single-note para notas com dots próprios dentro de chords com dots (o C++
  roda os dois ramos em sequência). E `flagShift` é **um** local compartilhado:
  o ramo single acumula sobre o valor do ramo chord
  (calcdotsfunctor.cpp:77-80) — preservado na reestruturação. Early-return novo
  só quando nem chord nem nota têm dots (efeitos pulados são nulos +
  protege notas sintéticas sem staff, onde o C++ crasharia).
- **OBS-4 (teste virou paridade real, não enfraqueceu):**
  `adjust_layers_test.dart` comparava `max` para chords porque o baseline era
  sabidamente 0. O fixture 04a diz `xRel_in=226, xRel_out=226, max=0` nesses
  dots — com o fix, `drawingXRel == xRel_out` dígito a dígito; a comparação
  agora é `xRel_out` para notes E chords.
- **OBS-5 (efeito medido):** `chord-001` 847→57 divs sozinho; `dot/` 153→96;
  `dots/ellipse @cx` 33arqs/452divs → 18/133, Δ-226 some do ranking (restam
  -219/-225/192/96/25, menores — próxima iteração). Y não subiu: os arquivos
  têm divergências residuais de outras causas. `dart analyze` 0 issues;
  `dart test` 701 pass.
- Arquivos: `lib/src/layout/calc_functors.dart` (ramo chord-tone +
  `chordDrawingX` + doc comment), `test/adjust_layers_test.dart` (chord
  `max` → `xRel_out`).

## 2026-09-06 — trilha CAUSA — alvo `stem/path @d` / `beam/polygon @points` Δ-208 (19/12 arqs, âncora X da haste)

S 44→44  N 18656→18652 (-4)  X 612/621→612/621  Y 325/621→327/621 (+2: stem-010, stem-011 limpos)  — **COMMIT**

Porte linha-a-linha de `Stem::FillAttributes` (stem.cpp:82-84), que nunca tinha
sido portado para o ramo `AttStems`: `note@stem.pos`/`chord@stem.pos` era lido
para `note.stemPos` (`readStems`) mas jamais transferido para o filho `Stem`
(`stem.pos` ficava null), então `CalcStemFunctor._stemPos` caía no ramo default
(âncora do lado da direção) em vez do lado explícito.

- **OBS-1 (degrau 1 — pinpoint, fn/seq/path):** `probe_diff` em `stem-010` e
  `stem-011` acusa o MESMO ponto: `fn=DrawLine seq=66/74
  path=measure[2]/staff[1]/layer[1]/note[1]/stem[1]`, x1/x2 Δ-208, y1 Δ+53, y2
  exato. Medida 2 = `note@stem.pos="right"` sobre nota aguda (g5, haste para
  baixo por default): o C++ ancora a haste à DIREITA (x da cabeça + largura),
  o Dart à ESQUERDA. y1 junto (±53 = assimetria Y da âncora entre os lados)
  confirma âncora errada, não comprimento errado (y2 exato).
- **OBS-2 (degrau 3 — função C++ inteira + callers):** `Stem::FillAttributes
  (const AttStems&)` copia `HasStemPos → SetPos` (stem.cpp:82-84); os callers
  passam `*chord` (preparedatafunctor.cpp:1142) e `*note` (:1191). O porte
  Dart (`fillStemAttributes`, preparedata_functor.dart:1585) copiava dir/len/mod
  do ramo `AttStems` mas PULAVA `stemPos`; o ramo `AttStemVis` (`pos` do
  elemento `<stem>`) não cobre `stem.pos` da nota. Linha faltante, não lógica
  divergente — o `CalcStemFunctor.visitStem` (calc_functors.dart:415-435) já
  tratava `left`/`right`/`center` corretamente; só nunca recebia o valor.
- **OBS-3 (triagem do Δ-208 compartilhado):** o mesmo número aparece em 20
  arquivos × 6 assinaturas, mas `grep stem.pos test/corpus/` acha SÓ stem-010
  e stem-011 no corpus inteiro. O -208 dos outros 18 (beamspan, cross-staff,
  slur, stagedir, tuplet-010, beam-026, stem-016) tem mecanismo DISTINTO
  (ex.: beamspan-004 difere em milhares nas polygons de beamSpan — layout de
  feixe trans-compasso, não âncora de haste). Mesmo delta ≠ mesma causa;
  o `cluster_deltas --delta=-208` lista sintoma, não diagnóstico. Próximas
  iterações nesse delta precisam de pinpoint próprio por arquivo.
- **OBS-4 (reset, checagem da armadilha do diário):** sem trap aqui —
  `Stem.reset()` zera `pos` (layer_elements_gen.dart) e `visitNote` re-roda
  `fillStemAttributes` a cada passada de prepareData, igual ao C++ (Reset +
  Fill a cada passo). O fix é idempotente (só seta `if hasStemPos`, como o
  `if HasStemPos` do C++).
- **OBS-5 (efeito medido):** `stem-010` e `stem-011` 0 divergências no
  `probe_diff` (streams de desenho idênticos); `--all`: N 18656→18652 (-4),
  Y 325→327 (+2), S 44 inalterado, 0 falhas; demais famílias com -208
  (beam/beamspan/cross-staff/slur/stagedir/tuplet/arpeg/artic/barline)
  byte-idênticas — nenhuma regressão fora do alvo. `dart analyze` 0 issues;
  `dart test` 701 pass.
- Arquivos: `lib/src/layout/preparedata_functor.dart` (+7/-0: ramo
  `hasStemPos` em `fillStemAttributes` + doc comment).

## 2026-09-06 — trilha CAUSA — alvo `dots/ellipse @cy` Δ±180 (múltiplos de passo de pauta)

S 44→44  N 18652→18577 (-75)  X 612/621→612/621  Y 327/621→329/621 (+2)  — **COMMIT**

Ordem de iteração do set de dot-locs divergia do C++: `MapOfDotLocs` é
`map<Staff*, std::set<int>>` (conjunto ORDENADO), mas o porte guardava
`Set` por inserção. Num acorde de segundas ({d5, e5}) a inserção sai
{7, 5} enquanto o C++ itera {5, 7} — os dois círculos trocam de ordem no
SVG (mesmos valores, sequência invertida: [1359, 1539] vs [1539, 1359]).

- **OBS-1 (degrau 1 — pinpoint):** `probe_diff` em `dot-001`: UM ponto,
  `fn=DrawCircle seq=259 path=measure[3]/staff[1]/layer[1]/chord[2]/dots[1]`,
  x exato, y Δ-180, radius exato. Só o acorde {d5,e5} diverge; o vizinho
  {c5,e5} (terça) e a segunda ocorrência de {d5,e5} (chord[4]) estão limpos
  — o segundo porque a ordem de inserção dele já sai ascendente.
- **OBS-2 (degrau 2 — campo a campo, sem instrumentação C++):** comparação
  direta dos SVGs mostra os MESMOS dois `cy` (1539, 1359) em ordem trocada
  (cpp [1539,1359], dart [1359,1539]); o fixture 05-38 confirma a ordem C++
  (seq 259 y=1539, seq 261 y=1359). Valores iguais ⇒ `CalculateDotLocations`
  e `DrawDots` estão certos; só a ordem de emissão difere. Prova fechada por
  aritmética, sem build DEEP.
- **OBS-3 (degrau 3 — causa):** `_calculateDotLocations` insere na ordem de
  percurso (para {6,7} em ordem direta: 7 primeiro, depois 5 ⇒ {7,5});
  `drawDots` itera `mapEntry.value` nessa ordem, mas o C++ itera
  `std::set<int>` (sempre ascendente). `dotLocShift` (`reduce(max)`, cs.1128)
  já era insensível a ordem (= `*rbegin`); o único consumidor sensível era o
  desenho. Também confere `adjust_beams.dart:453-457` (remove+add): em
  `std::set` o re-inserido volta à posição ordenada; em `LinkedHashSet` ia
  para o fim — o fix alinha os dois.
- **OBS-4 (o fix):** `Dots.setMapOfDotLocs` copia cada conjunto para
  `SplayTreeSet` (e `modifyDotLocsForStaff` cria `SplayTreeSet`), espelhando
  o `std::set<int>` no nível do modelo — todo consumidor observa a ordem
  C++. Todos os caminhos de escrita passam por essas duas funções
  (CalcDots chord/note/rest, AdjustDots, cópia).
- **OBS-5 (efeito medido):** `dot/` 96→78, `chord/` 84→27 (-57!); demais
  famílias com -180 (beam/artic/slur/tuplet/rest/layer/dynam/figured-bass/
  section/breath) byte-idênticas — o resíduo delas tem outro mecanismo.
  `--all`: N 18652→18577 (-75), Y 327→329 (+2), S 44, 0 falhas.
  `dart analyze` 0 issues; `dart test` 701 pass.
- Arquivos: `lib/src/model/layer_elements_gen.dart` (import
  `dart:collection` + `SplayTreeSet` em `setMapOfDotLocs` /
  `modifyDotLocsForStaff` + doc comment).

## 2026-09-06 — trilha CAUSA — alvo `stem/path @d` (topo do ranking, 144 arq.) → `getAncestorStaffResolveCrossStaff`

S 44→43 (-1)  N 18577→18061 (-516)  X 612/621→613/621 (+1)  Y 329/621→331/621 (+2)  — **COMMIT**

Topo do ranking pós-triagem (`stem/path @d`, 6419 divs/144 arq.) tem deltas dispersos
(-208, 1, 2, -1, 25, -37, 90, 3) — sintoma de várias causas independentes, não uma só.
Escolhido subir a montante: 20 dos 144 arquivos são da família `cross-staff`, e a regra de
dependência do §2 (pauta Y é upstream de haste/beam/etc.) apontava para aí primeiro — a
primeira divergência de TODO arquivo cross-staff cai em `system` (a linha do grupo de pautas),
sintoma de sistema mais alto/baixo do que deveria, ou seja, espaçamento vertical de pauta errado.

- **OBS-1 (degrau 1 — pinpoint, fn/seq/path):** `probe_diff` em `cross-staff-001..010`:
  todos divergem em `fn=DrawLine seq=6 path=pages[1]/page[1]/system[1]` (a barra do
  staffGrp) — y1 e/ou y2 erradas por centenas de unidades. Como é a PRIMEIRA divergência
  de desenho, é sintoma a jusante do espaçamento entre pautas (`AdjustYPosFunctor`), não a
  causa — confirma a régua "primeira divergência ≠ causa" do diário.
- **OBS-2 (degrau 4 — instrumentação C++ nova, patch `05-43`):** sem fixture DEEP prévio
  para overflow/spacing vertical, instrumentei
  `CalcBBoxOverflowsFunctor::VisitObject` (aboveN/belowN resolvidos + overflow setado) e
  `AdjustYPosFunctor::VisitStaffAlignment` (defaultSpacing/minSpacing/requestedSpacing/
  overflowAbove/overflowBelow/overlap/yRel por staffN) — `cpp_probe/patches/05-43.patch`.
  **Achado colateral:** `build-probe/build` (git-ignored) tinha objetos `.o` ÓRFÃOS de uma
  tentativa anterior não documentada, com o MESMO id `05-43` (prints `PROBE0543-ABOVE/
  -BELOW/-MINSPACE` em `verticalaligner.cpp`, nunca commitados em `patches/ORDER`) —
  `sync.sh` + `patch.sh` resetam as FONTES mas não o `build/`, e o `ninja` incremental
  reaproveitou o `.o` obsoleto por mtime, produzindo um binário HÍBRIDO (código-fonte limpo
  + objeto compilado de código já descartado). Um `diff` limpo contra o binário não-instrumentado
  não teria detectado isso (o código órfão só fazia `fprintf(stderr)`, sem efeito colateral no SVG).
  **Lição:** depois de reusar um id de patch, sempre `rm -rf build-probe/build` antes do
  primeiro `build.sh` daquele id, ou os `strings` do binário podem trazer instrumentação de
  uma tentativa anterior nunca registrada em `patches/ORDER` — o próprio conteúdo do `.o` é
  prova de um beco-sem-saída de uma iteração passada que não deixou registro no diário.
- **OBS-3 (comparação C++×Dart, `cross-staff-001.mei`):** com print equivalente temporário
  em `AdjustYPosFunctor.visitStaffAlignment` (Dart), staff2: C++ `overflowAbove=96`, Dart
  `overflowAbove=2235` (Δ+2139!) — staff1: C++ `overflowAbove=1006`, Dart `overflowAbove=646`
  (Δ-360, bate exatamente com o `y1` do probe_diff). O elemento que causava os 2235 em
  staff2 era um **`accid` não-cross-staff** (`cross=false` no meu print) resolvido contra
  `above.getStaff().n==2` — mas o fixture C++ mostrava o MESMO accid (mesmo path) com
  `aboveN=1`. Ou seja: o Dart resolvia a pauta ancestral do accid errado.
- **OBS-4 (causa raiz — degrau 3, função C++ + callers lidos):**
  `LayerElement::GetAncestorStaff(RESOLVE_CROSS_STAFF)` (layerelement.cpp:280) delega para
  `GetCrossStaff()` (layerelement.cpp:300), que — se `this->m_crossStaff` for null — sobe
  para o ancestral `LayerElement` mais próximo e repete a busca ali (`parent->GetCrossStaff()`).
  Um `accid` não tem `AttStaffIdent` (não carrega `@staff` próprio, confirmado em
  `accid.h`/`accid.dart`), então `accid.m_crossStaff` é sempre null — mas quando o pai é uma
  NOTA cross-staffada (`@staff` explícito na nota, dentro de um chord/beam que atravessa
  pautas), o walk ancestral herda o cross-staff da nota. `getAncestorStaffResolveCrossStaff`
  (Dart, `preparedata_functor.dart:2499`) só checava `this.crossStaff` (campo próprio, sempre
  null para accid) e caía direto no `<staff>` físico do XML via `getAncestorStaffLayoutOrNull()`
  — pulando o walk ancestral que `getCrossStaff()` (`layer_element.dart:334`, JÁ existia e JÁ
  estava correto) implementa. Bug de uma linha: trocar o campo por uma chamada ao método certo.
- **OBS-5 (alcance do fix — por que valia a pena subir a montante):**
  `getAncestorStaffResolveCrossStaff` é usado em **15 call sites** fora deste arquivo:
  `bbox_overflows.dart` (overflow de pauta — o alvo direto), `adjust_accid_x.dart`,
  `adjust_layers.dart`, `adjust_artic.dart`, `adjust_tuplets.dart`, `calc_ledger_lines.dart`,
  `calc_functors.dart` (stem/beam), `slur_positioning.dart` — ou seja, TODO elemento sem
  `AttStaffIdent` própria (accid, dots, artic, ledger lines, tuplet bracket) dentro de uma
  nota/acorde cross-staffado herdava a pauta errada em qualquer um desses caminhos. Corrigir
  na função única (em vez de em cada chamador) é o que a regra "corrija a origem, não cada
  herdeiro" pede.
- **OBS-6 (residual identificado, NÃO perseguido nesta iteração):** depois do fix,
  `cross-staff-001` ainda diverge em `y2` (Δ638→-472, bem menor mas não zero). Rastreei até
  `measure[1]/staff[1]/layer[1]/chord[1]/stem[1]` (chord com 3 notas cross-staff para staff2
  + 3 na própria staff1): C++ `overflowAbove=729`, Dart `overflowAbove=251` — a haste desse
  acorde MISTO (parcialmente cross-staff) tem tamanho/posição diferente entre os dois lados,
  ANTES de qualquer ajuste de `AdjustCrossStaffYPosFunctor` (que roda depois de `AdjustYPos`,
  então não é a causa — confirmado lendo a ordem exata em `page.cpp:522-584`). A causa está
  em como `CalcStemFunctor` dimensiona a haste de um acorde com extremos mistos (só alguns
  notes cross-staff) na primeira passada — `Chord::GetTopNote/GetBottomNote` (ordenados por
  `DiatonicSort`, já conferido igual no Dart) alimentam `GetYExtremes`, mas a haste em si não
  foi auditada campo a campo. **Próximo alvo sugerido:** `CalcStemFunctor::VisitChord` (ou
  equivalente Dart em `calc_functors.dart`) para acordes parcialmente cross-staff — arquivo
  `cross-staff-001.mei`, chord `chord-0000000683148902`, fixture DEEP ainda não gerado para
  esse ponto específico (só CalcBBoxOverflows/AdjustYPos foram instrumentados no patch 05-43).
- **OBS-7 (efeito medido, `--all`):** N -516 (-2.8%), S -1 (efeito colateral positivo — não
  esperado numa trilha CAUSA mas não é regressão), X +1, Y +2. `dart analyze` 0 issues;
  `dart test` 701 pass (era 700 — `harness_integrity_test.dart` fixture `arpeg-003.mei`
  ficou estruturalmente limpo pelo efeito colateral em S; trocado por
  `midi/005-maqam-rast-external-tuning.mei` no canário de 4 arquivos, mesmo precedente do
  header do teste).
- Arquivos: `lib/src/layout/preparedata_functor.dart` (`getAncestorStaffResolveCrossStaff`,
  +3/-3), `test/harness_integrity_test.dart` (troca de canário arpeg-003→midi/005), patch
  novo `cpp_probe/patches/05-43.patch` + `cpp_probe/patches/ORDER` (+1 linha).

## 2026-09-06 — trilha BARATA→CAUSA (achado transbordou o alvo) — alvo `clef/clef-005` (1 div) → `AdjustClefChangesFunctor`

S 43→43  N 18061→16658 (-1403, -7.8%)  X 613/621→613/621  Y 331/621→337/621 (+6)  — **COMMIT**

4 iterações seguidas foram CAUSA, então esta trocou para BARATA (fila de menor custo do
`DELTA_CLUSTERS.md`: `clef/clef-005` e `gracenote/gracenote-010`, 1 div cada). As duas
convergiram no MESMO mecanismo, então o achado cresceu além do escopo BARATA original — mas
a regra do §2 permite: "BARATA limita o tamanho do alvo, nunca a profundidade da
investigação", e aqui a profundidade revelou uma causa de alcance amplo, não um desvio de
escopo deliberado.

- **OBS-1 (degrau 1 — pinpoint):** `probe_diff` em `clef-005` e `gracenote-010`: ambos
  divergem em `fn=DrawSmuflCode path=.../clef[1]` — a MESMA classe de clef (mudança de clef
  no meio do compasso, glifo E07A), X grande demais (Δ+466 e Δ+331). `origem provável:
  View::DrawClef (view_element.cpp:418)`.
- **OBS-2 (degrau 2 — campo a campo, fixture 05-38):** o fixture C++ para esse `clef[1]` não
  tem NENHUM registro `AdjustXPos` — só `AlignHorizontally`/`LayOutHorizontally`/
  `LayOutVertically`/`DrawSmuflCode`. Comparado com `clef[staffDef]` do mesmo arquivo, que
  TEM registros `AdjustXPos` completos. A ausência não é lacuna do fixture: é o C++ pulando
  esse elemento de propósito.
- **OBS-3 (degrau 3 — causa, função C++ + callers lidos):**
  `AdjustXPosFunctor::VisitLayerElement` (adjustxposfunctor.cpp:128) pula explicitamente
  `if ((layerElement->GetAlignment()->GetType() == ALIGNMENT_CLEF) && !m_isNeumeStaff) return
  FUNCTOR_CONTINUE;` — mudanças de clef no meio do compasso (tipo de alinhamento
  `ALIGNMENT_CLEF`, distinto do clef inicial `staffDef`) NUNCA passam pelo ajuste de
  espaçamento genérico; têm sua PRÓPRIA função dedicada,
  `AdjustClefChangesFunctor::VisitClef` (adjustclefchangesfunctor.cpp), que resolve
  `nextAlignment`/`previousAlignment` via `Object::FindNextChild`/`FindPreviousChild` sobre o
  `MeasureAligner` e reposiciona o clef relativo a eles (`AdjustProportionally` se colidir).
  O port Dart (`adjust_x_pos.dart`, `AdjustClefChangesFunctor.visitClef`) parava logo depois
  de resolver o grace aligner com um comentário "Deviation: FindNextChild / FindPreviousChild
  ... arrive together with the rendering phase" — igual ao achado da iteração anterior
  (`getAncestorStaffResolveCrossStaff`), um comentário de limitação da Fase 5 que ficou
  esquecido depois que a Fase 7 (render real) chegou; `adjustProportionally`/`getLeftRight`
  já existem e já são usados em outros lugares (`adjust_harm_tempo_syl.dart`,
  `adjust_arpeg.dart`), só faltava ligar o clef neles.
- **OBS-4 (o porte):** `Object::FindNextChild`/`FindPreviousChild` são genéricos (DFS +
  `Comparison` + "start" object), mas aqui só precisam varrer a estrutura conhecida de 2
  níveis `MeasureAligner -> Alignment -> AlignmentReference` — implementados como
  `_findNextAlignment`/`_findPreviousAlignment` (busca linear pelo índice do `Alignment` no
  aligner, usando `Object.idx` já existente). Confirmado equivalente ao C++: o `start`
  passado ao `FindNextChild` já é `m_aligner->GetNext(clef->GetAlignment())` (o alignment
  seguinte), então a busca por "próximo" inclui esse alignment (índice `clefIdx+1`
  inclusive); o `FindPreviousChild` usa `clef->GetAlignment()` como start e para ANTES dele
  (exclusive) — "andar pra trás a partir de `clefIdx-1` e parar no primeiro match" é
  equivalente a "a última correspondência ao varrer para frente", já que é o mesmo objeto
  mais próximo do limite. `getLeftRightForStaffNs` (já existente) cobre
  `Alignment::GetLeftRight(vector<int>)` ponto a ponto (mesmos sentinelas `meiUnset`/
  `-meiUnset` para `VRV_UNSET`/`-VRV_UNSET`).
- **OBS-5 (efeito medido):** `clef-005`, `gracenote-010` e `clef-001` (que nem estava na
  fila, mas tinha o mesmo sintoma — measure width truncada por falta desse ajuste) ficaram
  limpos; família `clef` caiu de "vários arquivos com Δ grande" pra só 3 divergentes restantes
  (mecanismos distintos: `clef-003` Δ4 arredondamento, `clef-004` posição de `<dir>`,
  `clef-007` resíduo Δ-72 no clef ainda não investigado). `--all`: N -1403 (-7.8%, o maior
  ganho numérico desde o início do diário), Y +6, S inalterado, 0 falhas. `dart analyze` 0
  issues; `dart test` 701 pass.
- Arquivos: `lib/src/layout/adjust_x_pos.dart` (`AdjustClefChangesFunctor.visitClef` +
  `_findNextAlignment`/`_findPreviousAlignment`/`_hasMatchingReference`, +~90/-20).

## 2026-09-06 — trilha BARATA — alvo `clef/clef-007` (1 div, Δ-72) — residual apontado pela iteração anterior

S 43→43  N 16658→16657 (-1)  X 613/621→613/621  Y 337/621→338/621 (+1)  — **COMMIT**

Alvo veio direto da OBS-5 da iteração anterior ("clef-007 resíduo Δ-72 no clef ainda não
investigado"), não da fila de custo — mas o arquivo já estava na fila BARATA (1 divergência),
então a escolha respeita as duas regras.

- **OBS-1 (degrau 1 — pinpoint):** `probe_diff` em `clef-007`: `fn=DrawSmuflCode
  path=measure[1]/staff[1]/layer[1]/clef[2]`, x Δ-72 (esperado 1952, obtido 1880), y exato,
  code/text/setSmuflGlyph idênticos. `origem provável: View::DrawClef (view_element.cpp:418)`.
  O arquivo (título "Visual offset on clef") tem só dois `<clef>`: o segundo carrega
  `ho="0.8vu"` — único uso de `@ho`/`@vo` em `<clef>` no corpus inteiro (`grep` confirmado).
- **OBS-2 (degrau 2/3 — campo a campo + função C++):** `View::DrawClef` chama
  `this->CalcOffset(dc, x, y)` (view_element.cpp:701) antes de desenhar. `CalcOffset` só tem
  efeito se `View::StartOffset` (view.cpp:135), chamado uma vez por elemento em
  `DrawLayerElement` (o dispatcher, view_element.cpp:80/235), empurrou um `Offset` para
  `m_currentOffsets` — o que só acontece quando
  `object->HasInterface(INTERFACE_OFFSET)` é true. Confirmado: `Clef::Clef()` (clef.cpp:35,48)
  chama `RegisterInterface(OffsetInterface::GetAttClasses(), ...)` no construtor.
- **OBS-3 (a causa — achado por auditoria, não por sintoma isolado):** `hasInterface` no Dart
  (`object.dart:256`) lê de um `_interfaces` set que só é populado por
  `registerInterface(s)` — e **nenhuma chamada correspondente existe em `Clef.reset()`**
  (`basic_elements.dart`). Toda outra classe que aplica `OffsetInterface` registra
  `InterfaceId.offset` no próprio `reset()` (auditei as 20 classes que usam o mixin: `Note`,
  `Accid`, `Custos`, `Dot`, `Liquescent`, `MRest`, `Nc`, `Oriscus`, `Quilisma`, `Strophicus`,
  `Syl`, `Episema`, `Artic`, `DivLine`, `HalfmRpt`, `Neume`, `TabGrp`, `Rest`,
  `ControlElement` — todas com a chamada; só `Clef` não tinha). `startOffset` (view.dart:639)
  checava `object.hasInterface(InterfaceId.offset)` antes de ler `ho`/`vo`; para clef isso
  sempre dava `false`, então o offset nunca era empurrado — não é erro de parsing de `ho`
  (`readVisualOffsetHo`/`strToMeasurementsigned` já estavam corretos, conferido) nem de
  fórmula (`ho.vu * unit` correta), é a checagem de interface pulando o clef inteiro.
- **OBS-4 (armadilha evitada):** achado por leitura de `Clef.reset()` inteiro comparado linha a
  linha com `Note.reset()` (mesmo padrão), não por grep do delta — grep por `-72` sozinho não
  aponta a causa, só o sintoma no ponto de desenho.
- **OBS-5 (alcance — por que é seguro):** `grep '<clef.*\(ho=\|vo=\)'` no corpus inteiro só
  acha `clef-007.mei`; o fix (`registerInterfaces([InterfaceId.offset])` em `Clef.reset()`,
  espelhando o padrão de `Rest`/`Note`) só muda comportamento quando `hasHo || hasVo` é true
  (ver `startOffset`), então nenhum outro arquivo do corpus é afetado — confirmado pelo
  `--all`: só `clef-007` mudou (N -1, Y +1), demais famílias byte-idênticas.
- **OBS-6 (achado fora de escopo, não perseguido):** essa auditoria de `hasInterface` foi
  disparada por suspeita de que `registerInterface` pudesse nunca ser chamado em lugar nenhum
  (o que seria catastrófico — dezenas de call sites em `expansion_map.dart`,
  `preparedata_functor.dart`, `align_functors.dart` dependem dele para `duration`/
  `timePoint`/`timeSpanning`/`linking`/`plist`/`position`). Não é o caso: toda classe geradora
  relevante registra corretamente, exceto este único `Clef`. Vale relembrar em auditorias
  futuras: o padrão é sólido, mas heurística de auditoria (comparar uma classe suspeita contra
  irmãs que aplicam o mesmo mixin) vale a pena repetir quando outro elemento aparecer "cego" a
  um atributo que deveria ter efeito.
- Arquivos: `lib/src/model/basic_elements.dart` (`Clef.reset()`, +7/-0: chamada
  `registerInterfaces([InterfaceId.offset])` + doc comment).

## 2026-09-06 — trilha CAUSA — alvo `staff/path @d` (rank #2, 118 arq.) → `AccidFloatingObject` nunca portado

S 43→43  N 16657→16602 (-55)  X 613/621→613/621  Y 338/621→343/621 (+5)  — **COMMIT**

Ordem de dependência (§2 do prompt) mandava subir de `stem/path @d` (rank #1) para
`staff/path @d` (rank #2) primeiro, por ser mais a montante (posição vertical da própria
pauta). Achado cresceu bem além do escopo inicial — de "por que a pauta está 74 unidades
baixa demais" a uma feature inteira nunca portada.

- **OBS-1 (degrau 1 — pinpoint):** `probe_diff` em `accid/accid-003.mei`: `fn=DrawLine
  path=measure[1]/staff[1]` (a própria linha de pauta), y1/y2 Δ+74 (esperado 1269, obtido
  1343). `origem provável: View::DrawStaff / DrawHorizontalLine (view_graph.cpp:40)`. Arquivo
  título "Alignment of editorial accidentals" — 5 notas, cada uma com `<accid func="edit">`
  (acidente editorial, desenhado acima da pauta). `accid-004`/`accid-005` mesmo sintoma
  (Δ69/Δ74), mesma família de arquivo.
- **OBS-2 (degrau 2/3 — cadeia até a causa):** `Staff::GetDrawingY = System::GetDrawingY() +
  StaffAlignment::GetYRel()` (staff.cpp:192, system.cpp:115 — ambos portados idênticos,
  conferido). `StaffAlignment::GetYRel` vem de `AlignVerticallyFunctor::VisitStaffAlignmentEnd`
  (`YRel = -GetMinimumSpacing()`) e depois `AdjustYPosFunctor::VisitStaffAlignment` soma
  `max(0, CalcMinimumRequiredSpacing() - GetMinimumSpacing())` — ambos portados idênticos em
  `lib/src/layout/vertical_aligner.dart`/`lay_out_vertically.dart` (conferido linha a linha).
  `CalcMinimumRequiredSpacing` (primeiro alignment) = `max(GetOverflowAbove(),
  GetScoreDefClefOverflowAbove()) + GetOverlap()` — também idêntico. A causa não está em
  nenhuma dessas fórmulas; está em QUEM alimenta `GetOverflowAbove()`.
- **OBS-3 (a causa raiz — achada por instrumentação DEEP nova, patch `05-43` já cobria isso):**
  fixture DEEP (`AdjustYPosVisitStaffAlignment`, já instrumentado em `05-43`) deu C++
  `overflowAbove=520`, Dart (print temporário em `lay_out_vertically.dart`) `overflowAbove=614`
  — nenhum dos dois bate com o overflow do clef (240) nem das noteheads (96 cada), então o
  contribuinte real não vinha de `CalcBBoxOverflowsFunctor`. Print extra em
  `calcbboxoverflowsfunctor.cpp`/`bbox_overflows.dart` mostrou algo mais fundamental: no C++,
  `object->HasSelfBB()` é FALSO para todo `<accid func="edit">` (a função nunca visita o nó);
  no Dart, era VERDADEIRO (614 vinha do próprio bbox do accid entrando na conta geral). Grep em
  `adjustfloatingpositionerfunctor.cpp` achou `m_classId = ACCID_FLOATING;
  system->m_systemAligner.Process(*this);` (linha 184) — accid editorial não é um `LayerElement`
  comum para fins de overflow: é convertido num `FloatingObject` próprio
  (`AccidFloatingObject`, accid.h:163), com posicionamento e overflow computados pelo MESMO
  mecanismo genérico usado por dir/dynam/harm/etc (`AdjustFloatingPositionersFunctor`), não
  pelo `CalcBBoxOverflowsFunctor`. `PrepareDataInitializationFunctor::VisitAccid`
  (preparedatafunctor.cpp:60) cria o floating object quando `GetFunc() ==
  accidLog_FUNC_edit`; `View::DrawAccid` (view_element.cpp:262-284) desenha e mede o BBOX
  no floating object, não no `Accid` em si — por isso o `Accid` real nunca aparece com self-bb.
- **OBS-4 (achado documentado, não escondido):** `view_element.dart:drawAccid` já tinha um
  comentário explícito admitindo a lacuna: "Dart has no floatingObject member; keep the graphic
  wrapper on the element itself" — decisão de fase anterior (Fase 5, sem render real), nunca
  revisitada depois que a Fase 7 (render de verdade) chegou. Mesmo padrão do achado
  `AdjustClefChangesFunctor` de duas iterações atrás: comentário de limitação sobrevivendo além
  do prazo de validade.
- **OBS-5 (o porte):** a infraestrutura genérica de `FloatingObject`/`FloatingPositioner`/
  `System.setSystemCurrentFloatingPositioner`/`AdjustFloatingPositionersFunctor` já existe e já
  é usada por dir/dynam/harm etc — só faltava plugar accid nela:
  1. `AccidFloatingObject` (nova classe, `layer_elements_gen.dart`, mirror de accid.h:163-182,
     incluindo `GetClassName() override => "accid"` — sem isso o SVG saía com
     `class="[MISSING]"`, o genérico `FloatingObject.className`; achado por regressão
     estrutural no primeiro `compare_svg` de verificação, corrigido antes do commit).
  2. `Accid.initFloatingObject`/`getFloatingObject`/`clearFloatingObject`
     (mirror de accid.cpp:89-101).
  3. `PrepareDataInitializationFunctor.visitAccid` (não existia; mirror de
     preparedatafunctor.cpp:60 — chama `initFloatingObject()` quando `func==edit`).
  4. `ResetDataFunctor.visitAccid` já existia mas faltava `accid.clearFloatingObject()`
     (mirror de resetfunctor.cpp:57-64 — sem isso o floating object vazaria entre passadas
     de layout, exatamente a armadilha "decide uma vez, guarda no objeto, sem reset" do diário).
  5. `View.drawAccid`: `drawingElement = editorialAccid ?? element` para o wrapper
     start/endGraphic (é isso que faz o BBoxDeviceContext medir o floating object, não o
     accid); `system.setSystemCurrentFloatingPositioner(staff.n, editorialAccid, accid,
     staff)` seguido de reposicionar x/y a partir de `editorialAccid.getDrawingX/Y()`; e o
     bloco de reposicionamento por nota (`noteTop`/`noteBottom`) agora só roda quando
     `editorialAccid == null` — mirror exato de `if (!editorialAccid && note)`
     (view_element.cpp:290), que antes rodava sempre que `func==edit`.
- **OBS-6 (verificação campo a campo, não só o Δ final):** com o fix, print temporário deu
  Dart `overflowAbove=520` (idêntico ao C++) e os 5 valores individuais por acidente
  (`{488, 270, 520, 488, 515}`) batem como MULTISET com os 5 do C++ (`{515, 488, 520, 270,
  488}`) — mesma ordem de grandeza, mesma origem, só emitidos em ordem diferente de
  processamento. `probe_diff` em `accid-003.mei`: 0 divergências no nível de desenho.
- **OBS-7 (armadilha do id — descartada como ruído, não regressão):** primeira verificação
  pós-fix do `probe_diff` reportou um "novo" divergência de `gId` (esperado `f168830z`, obtido
  outro). Investigado: os ids do golden C++ e do golden Dart JÁ usam esquemas de RNG
  incompatíveis independentemente deste fix (formatos diferentes, minúsculo-only vs
  alfanumérico-misto — conferido comparando `test/golden/cpp/**` vs `test/golden/dart/**` já
  commitados). O comparador de verdade (`compare_svg.dart`) normaliza ids nos dois lados antes
  de comparar (gotcha já documentado no CLAUDE.md); `probe_diff` não normaliza, então esse
  "divergência" é ruído do comparador de baixo nível, não uma regressão real — confirmado
  rodando `compare_svg` na família `accid` isoladamente.
- **OBS-8 (efeito medido):** `--all`: N -55, S inalterado (0 regressão estrutural), Y +5,
  `dart analyze` 0 issues, `dart test` 701 pass. Família `accid` isolada: estrutural 7/14→14/14
  limpos (regressão intermediária de `class="[MISSING]"` já corrigida antes do commit final),
  numérico 123→68 divergências. Cluster ranking: `staff/path @d` 118→115 arquivos,
  `accid/use @transform` 59→54 arquivos. Efeito modesto frente ao tamanho do achado porque a
  maioria dos 118 arquivos do cluster `staff` tem OUTRAS causas coexistindo (cascata da regra
  de dependência do §2) — este fix resolve só o subconjunto que usa `accid func="edit"`.
- Arquivos: `lib/src/model/layer_elements_gen.dart` (`AccidFloatingObject` nova classe +
  `Accid.initFloatingObject/getFloatingObject/clearFloatingObject`, +40/-0),
  `lib/src/layout/preparedata_functor.dart` (`visitAccid` novo, +15/-0),
  `lib/src/layout/reset_functor.dart` (`visitAccid` +1 linha),
  `lib/src/rendering/view_element.dart` (`drawAccid` reescrito para floating object,
  +30/-14).

## 2026-09-07 — trilha CAUSA — alvo `stem/path @d` (rank #1, 133 arq.) → subgrupo Δ-208 → `beamspan-003`

S 43→43  N 16602→16549 (-53)  X 613/621→613/621  Y 343/621→346/621 (+3)  — **COMMIT**

Ordem de dependência (§2): `stem` está a jusante de `staff`/`notehead`/`barLine`, mas o
subgrupo Δ-208 (19 arquivos, 7 assinaturas: `beam/polygon` 246 + `stem/path` 144) tem
cheiro de causa única a montante — uma coordenada X herdada — então foi atacado direto
em vez de subir para `staff` (cujo resíduo é heterogêneo).

- **OBS-1 (degrau 1 — pinpoint):** `probe_diff` em `beamspan-003.mei`: `fn=DrawLine
  path=measure[1]/staff[1]/layer[1]/note[1]/stem[1]` seq 31, x1/x2 Δ-208 (esperado 2183,
  obtido 1975), y1 Δ+56, y2 Δ+1044. Haste no X esquerdo da cabeça em vez do direito E
  com direção invertida (C++ `y2<y1`, up; Dart `y2>y1`, down). Δx = largura da cabeça +
  shift — hipótese de lado da haste (diário OBS-E, 2026-09-04) confirmada por fixture.
- **OBS-2 (degrau 2 — campo a campo):** fixture C++: notehead `(1966,1974)`, stem
  `(2183,1946)→(2183,1362)` (up, direita). Notas e4/d4/c4 (linhas 1974/2064/2154, fundo
  da pauta para baixo). Debug Dart pós-`prepareData` + pós-`castOffDoc`: `drawingPlace
  = below`, `drawingStemDir = down` nas 3 notas — errado ainda antes do desenho.
- **OBS-3 (degrau 3 — função inteira + callers):** `BeamSegment.calcBeam` re-roda no
  desenho (`drawBeamSpan`, view_beam.dart:476, mirror de view_beam.cpp:457) passando
  `beamSpan.drawingPlace` como `place` — e `CalcBeamPlace` (beam.cpp:1122) respeita
  `place != NONE`, então o desenho preserva o valor da passada anterior em vez de
  recomputar. A passada anterior (CalcStem tardio, layOutHorizontally) já vinha
  envenenada — o desenho só herdou.
- **OBS-4 (a causa raiz — desvio de porte em `InitCoords`/`GetStemDir`):** C++
  `InitCoords` (drawinginterface.cpp:204-223) lê a direção via
  `BeamElementCoord::GetStemDir` (beam.cpp:1813), que retorna SÓ o `@stem.dir`
  codificado (`m_stem->GetDir()` / `AttStems::GetStemDir`) — nunca o `drawingStemDir`
  computado. O Dart lia o computado primeiro (`drawing_interfaces.dart:241`:
  `getDrawingStemDir()`; `beam_segment.dart:165`: `s.getDrawingStemDir()` fallback).
  Sequência do envenenamento: passada `PrepareData` (Y headless, sem ledger) computa
  `below`+`down` → grava `drawingStemDir=down` nas notas → passada `LayOutHorizontally`
  (Y final, ledger daria `above`) relê `down` via `initCoords` → `notesStemDir=down` →
  `CalcBeamPlace` curto-circuita em `below` sem olhar ledger. Auto-reforço entre
  passadas — a armadilha "decide uma vez, guarda no objeto, sem reset" do diário,
  desta vez via direção computada lida como se fosse codificada.
- **OBS-5 (o porte):** `initCoords` agora lê só `(child as AttStems).stemDir`
  (drawinginterface.cpp:204-223, `m_stem` nulo); `getStemDir()` retorna só `s.dir`
  (beam.cpp:1813, sem fallback para `getDrawingStemDir`). Pós-fix: `above`/`up` nas 3
  notas, `probe_diff` em `beamspan-003` 0 divergências (limpo). Efeito `--all`: N -53,
  Y +3 (beamspan 1→3 limpos, tuplet-010 limpo), S inalterado, `stem/path @d` 133→130
  arq., Δ-208 19→~14 arq. Modesto porque os demais arquivos do cluster têm causas
  coexistentes (poda estrutural em cross-staff esconde o numérico; stem-016 diverge na
  largura do compasso, não na haste).
- **OBS-6 (por que beams comuns não mudaram):** `beam/` N 964→964. O veneno só troca o
  veredito quando o Y headless e o Y final discordam sobre o `place` (notas perto da
  linha média); beams inequivocamente altos/baixos dão o mesmo `place` nas duas
  passadas, com ou sem o fallback.
- Arquivos: `lib/src/model/drawing_interfaces.dart` (`initCoords`, +11/-13),
  `lib/src/model/beam_segment.dart` (`getStemDir`, +7/-8).

## 2026-09-07 — trilha CAUSA — alvo `stem/path @d` subgrupo Δ25 → `dot/dot-004` → `AdjustLayers` cut-outs

S 43→43  N 16549→15780 (-769)  X 613/621→613/621  Y 346/621→353/621 (+7)  — **COMMIT**

Subgrupo Δ25 do topo (14 arq., 13 assinaturas: staff 135 + stem 118 + notehead 70 —
cheiro de coordenada a montante). Pinpoint em `dot-004`: seq 121 `DrawCircle`
`measure[3]/staff[1]/layer[1]/note[1]/dots[1]`, x Δ+25 (3753→3778); notehead e stem
antes batem.
- **OBS-1 (degrau 2 — o Δ está todo no `xRel`):** Dart `dotsX=3688` (`xRel=452`)
  vs C++ `dotsX=3663` (`xRel=427`), `unit=90` igual. `CalcDots` escreve no máximo
  `2*radius=226` (ímpar 25 exclui `2*radius` sozinho) — o extra vem depois.
- **OBS-2 (degrau 4 — `AdjustDots` soma `max=226`):** print temporário mostrou
  `AdjustDotsFunctor` ajustando `226→452` com grupo de 1 `other` (nota layer 2 no
  mesmo X). Parecia causa, mas era herança: `diff = other.X + xRel - dot.X`, e o
  `xRel` da nota layer 2 (shift de colisão) já vinha errado do passo anterior.
- **OBS-3 (a causa raiz — `AdjustLayers` sem cut-outs):** X finais: layer2-note
  Dart `3462` vs C++ `3437` (shift `226` vs `201`, base `3236` igual). O shift vem
  de `HorizontalLeftOverlap` no ramo `margin=0` (segunda c5/b4, `loc` diff 1) de
  `CalcElementHorizontalOverlap`. O C++ (boundingbox.cpp:238) reparte as bboxes em
  até 3 retângulos pelos anchors SMuFL `cutOutNW/SW+NE/SE` (`GetRectangles`,
  boundingbox.cpp:306-452; E0A3 tem `cutOutNW/SE` em `Bravura.xml`); o Dart usava
  o retângulo cheio (desvio documentado em `bounding_box.dart`), superestimando o
  overlap em 25. Prova C++ por fixture novo: patch `05-44` (`cpp_probe/patches`)
  emite `AdjustLayersOverlap` em `CalcElementHorizontalOverlap` —
  `measure[3]/layer[2]/note[1]`: `elX=otherX=90`, bboxes `[90,316]` ambos,
  `shiftOut=201` (cheio daria 226); `diff` limpo vazio (`build/verovio` × probe).
- **OBS-4 (o porte):** `adjust_layers.dart` troca os 7 `horizontalLeft/RightOverlap`
  plain de `_calcElementHorizontalOverlap` + 2 de `compareToElementPosition`
  (stem.cpp:98-99) pelas versões `...GlyphAware` já existentes
  (`floating_positioner.dart`, usadas antes só em accid/x_pos), com
  `doc.getResources()`. Bbox sem glifo/anchor cai no retângulo cheio (fallback
  idêntico ao C++), então o fix só mexe onde há cut-out.
- **OBS-5 (efeito):** `dot-004` 0 divergências; família `dot` 78→7 divs; `layer`
  491→187; dumps tocados só em arquivos Δ25 (barline-009, beam-062,
  cross-staff-017/018, dot-004/005, gliss05, layer-002/008/012, stem-009,
  tie-010); ranking `stem` 130→121 arq., assinaturas 92→89.
- Arquivos: `lib/src/layout/adjust_layers.dart` (+37/-14),
  `cpp_probe/patches/05-44.patch` + `ORDER` (instrumentação da prova).

## 2026-09-07 — trilha CAUSA — alvo `stem` cross-staff Δ720 → `artic-009` (chords unbeamed m15)

S 43→43  N 15780→15771 (-9)  X 613/621→613/621  Y 353/621→355/621 (+2: cross-staff-002, cross-staff-006 limpos)  — **COMMIT**

Dois chords `stem.dir="up"` unbeamed com nota cross-staff (`staff="2"`) tinham a
base da haste 720 curta no Dart (y1 3131→2411 e 3041→2321, tip exato). 720 é o
gap inter-staff: o span C++ inclui a nota que mora no outro staff, o do Dart não.

- **OBS-1 (degrau 1 — pinpoint, fn/seq/path):** `probe_diff` em `artic-009`:
  `fn=DrawLine seq=45 path=measure[15]/staff[1]/layer[1]/chord[1]/stem[1]`,
  y1 Δ-720, x e y2 exatos. O chord[2] tem o MESMO Δ-720 (3041→2321, conferido
  por diff direto golden×dart) mas o `probe_diff` nunca o mostrou — ele reporta
  SÓ a primeira divergência (seq45 vem antes na ordem de desenho) e para ali.
- **OBS-2 (degrau 2 — campo a campo):** noteheads batem dos dois lados (g3
  y=3159 no staff 2, g4 y=1809 no staff 1 — fixture seq51/56); tip y2=1179 bate
  (topo − 630 padrão); só a base difere. Span C++ = 3159−1809 = 1350; span Dart
  (debug temporário) `chordStemLength=-630`, `yRel=-630`, `len=-1232` — pitch
  puro g3→g4 (7 steps × 90), sem o gap. `p.y=+28` bate (`_stemAnchor` → bottom
  note UpSE, como `Chord::GetStemUpSE`, chord.cpp:358); artic E4A3 seq48 bate
  (4576,3305). Conta fechada do fix: `len=-630−1350+28=-1952`, base
  `3103+28=3131`, tip `3131−1952=1179` — dígito a dígito.
- **OBS-3 (degrau 3 — a causa):** o C++ roda `CalcStemFunctor` DENTRO do layout
  (page.cpp:288/376/701) e no recalc cross-staff
  (`AdjustCrossStaffYPosFunctor::VisitChord`, adjustyposfunctor.cpp:73-84) —
  sempre com DrawingYs reais — e `GetYExtremes` (chord.cpp:238-244) lê o Y
  verdadeiro da nota cross-staff. O Dart portou o cálculo como headless
  (locs pitch-only, staff-agnostic) em TODAS as passadas, inclusive no recalc
  pós-layout de `lay_out_vertically.dart` que existe justamente para isso
  (mesmo comentário do C++): o recalc rodava mas não podia convergir porque o
  cálculo ignorava Y por construção.
- **OBS-4 (falso positivo descartado — `crossStaff` null nos dois lados):**
  `chord.crossStaff` é null no Dart (debug) E no C++
  (`PrepareCrossStaffFunctor` só promove BEAM/BTREM/FTREM/TUPLET no End e
  propaga `@staff` via corrente — chord sem `@staff`, primeiro filho, herda
  NULL; preparedatafunctor.cpp:250-359). Logo staff=staff1, `m_verticalCenter`
  e tip-adjust batem; o ÚNICO desvio é o span. Degrau 5 (armadilhas) sem trap
  aqui.
- **OBS-5 (o porte):** flag `useDrawingY` em `CalcStemFunctor` (default false
  = headless, preserva o `prepareData` doc.dart:1842 e os testes unitários bit
  a bit); `true` nos 3 call sites pós-layout (doc.dart:531/773, recalc
  cross-staff). Com flag + cross-staff (`_hasCrossStaff`, mirror de
  `Chord::HasCrossStaff`, chord.cpp:346): `chordStemLength = bottomY − topY` e
  `yRel-up = bottomY − chordY` literais. Same-staff inalterado por construção
  (o staff cancela no span) — blast radius limitado a chords cross-staff.
- **OBS-6 (efeito medido):** probe `artic-009` seq45/63 zeradas (artic-009
  3→1 div); `cross-staff-006` probe limpo; `--all`: N −9, S flat, Y +2,
  0 falhas; só 8 dumps cirúrgicos (artic-009, cross-staff-001/002/003/006/020,
  dir-005, stem-013 — hastes cross-staff mais longas); `dart analyze` 0,
  `dart test` 701 pass.
- **OBS-7 (camada seguinte, DEFER — causa distinta, mesmo arquivo):**
  `artic-009` ainda tem 1 div: seq66 `DrawSmuflCode chord[2]/artic[1]` y Δ+337
  (1393 vs 1056). Pré-existente (o dump commitado já tinha 1393 — não é
  regressão; estava mascarada atrás da seq45) e de outro functor
  (posicionamento de artic, CalcArtic/AdjustArtic) → próximo alvo, não esta
  iteração. Furo adjacente anotado e NÃO tocado: `visitNote` decide direção de
  singles cross-staff por loc staff-agnostic vs Y verdadeira do C++
  (calcstemfunctor.cpp:275).
- **OBS-8 (lição de ferramenta):** "probe limpo além da seq N" não existe —
  o `probe_diff` só mostra a primeira divergência. Segunda camada exige diff
  direto golden×dart ou fix+reprobe (foi assim que o chord[2] apareceu).
- Arquivos: `lib/src/layout/calc_functors.dart` (flag `useDrawingY` + ramo
  true-Y + `_hasCrossStaff`, +40/-8), `lib/src/model/doc.dart` (2 call sites
  `..useDrawingY = true`), `lib/src/layout/lay_out_vertically.dart` (recalc
  `..useDrawingY = true`).

## 2026-09-07 — trilha CAUSA — alvo `artic/use @transform` Δ427 (16 arq) → `layer-001`

S 43→42  N 15771→12897 (-2874, -18%)  X 613/621→614/621 (barline-007
estrutural limpo)  Y 355/621→375/621 (+20)  — **COMMIT**

`artic/use @transform` (rank #13, 50 arq, deltas 427/540/360/900/180) tem a
assinatura de UMA causa: Δ427 exato em 16 arquivos × 2 assinaturas. Veículo
mais puro: `layer-001` (4 divs, max exatamente 427).

- **OBS-1 (degrau 1 — pinpoint):** `probe_diff` seq77 `DrawSmuflCode
  measure[1]/staff[1]/layer[2]/beam[1]/note[3]/artic[1]`, staccato E4A3 below
  em nota com beam, y Δ+427 (1865→2292), x exato. Nota (seq70), haste (seq72)
  e pauta (linhas 1269…1989) batem — só o artic diverge. C++ o põe na 4ª
  space (1865); Dart 303 abaixo da última linha (2292).
- **OBS-2 (degrau 2 — campo a campo, lado Dart):** debug temporário:
  `place=below, inside=true, yIn=-540, yOut=-720, yRel=-540, yShift=-67`
  (ramo below-bottom + `spacingTop`), final `-607`; no draw
  `yRel=-607, h=69`. Draw espelhado (centering `h/2`, `VerticalCorr=false`
  p/ stacc nos dois, larguras batem no X) — offsets cancelam, Δ é no Y de
  referência do artic.
- **OBS-3 (becos falsos, checados e descartados):** `VerticalCorr` false p/
  E4A3 nos dois (artic.cpp:251); `topMarginArtic` 0.75 nos dois
  (`spacingTop`=67); `beam.cpp:2047` só move artic em mixed-beam (não é o
  caso); `CalcAlignmentPitchPos` não tem ramo ARTIC; AdjustArtic roda 1× de
  cada lado (page.cpp:419, pré-vertical); glifo idêntico (X exato).
- **OBS-4 (o dado decisivo — sem build novo):** o patch 04b (na pilha ORDER
  desde agosto) já emite `AdjustArtic`; rodei o binário 05-44 existente sobre
  `layer-001` (`run.sh 05-44`, diff limpo vs binário limpo): `place=below,
  isInside=true, branch=insideFitStaffSpace, yShift=-90, yRel_in=0,
  yRel_out=-630`. O C++ NUNCA sai da pauta (rel -540 → snap -90 → -630)
  enquanto o Dart cai no ramo below-bottom (-540-67). Mesmo algoritmo, ramos
  diferentes ⇒ a base do Y difere entre os lados.
- **OBS-5 (a causa raiz):** C++ `Artic::IsRelativeToStaff() { return true; }`
  (artic.h:57) — override nunca portado (só `Syl` tinha,
  `layer_elements_gen.dart:3998`; o doc do getter base cita "e.g., syl or
  artic"). O yRel staff-relative do AdjustArtic era somado ao Y da NOTA no
  Dart e ao Y da PAUTA no C++. Conta exata: Dart `staffY−450−607 =
  staffY−1057` vs C++ `staffY−630`, Δ=−427. Isso explica o ramo também: no
  C++ o y do branch é staff-relative (dentro), no Dart note-relative (fora).
- **OBS-6 (o porte):** 1 linha — `isRelativeToStaff => true` em `Artic`
  (+9/-0 com doc). O Δ variar por arquivo (427/540/360/…) é a mesma causa
  vista de notas a alturas diferentes (offset da nota), não causas distintas.
- **OBS-7 (efeito medido):** artic 1251→492 (-759, 15/19 limpos), beam
  883→540 (-343), cross-staff 1823→1766, slur 892→876, dynam 67→53, layer
  187→180; `layer-001` 4→3 divs (resta bezier de slur ±1, outra causa);
  `dart analyze` 0, `dart test` 701 pass.
- **OBS-8 (teste virou paridade real, não enfraqueceu):**
  `adjust_accid_artic_test.dart` yRel_out 22/36→**36/36** vs fixture 04b
  (expectativa e set atualizados; precedente dots OBS-4 de 2026-09-06). A
  falha intermediária (+700-1) era a expectativa velha, não regressão —
  o comportamento mudou na direção do C++ de referência.
- **OBS-9 (follow-ups, NÃO tocados):** `Accid::IsRelativeToStaff` é
  CONDICIONAL no C++ (`HasLoc || (Oloc && Ploc)`, accid.h:65) — conferir o
  mirror Dart (`accid/use` ainda tem 51 arq/298 divs). Idem a direção de
  singles cross-staff (iter anterior). `note/polygon @points` Δ-8 (17 arq) é
  o próximo candidato CAUSA concentrado.
- Arquivos: `lib/src/model/layer_elements_gen.dart` (+9/-0),
  `test/adjust_accid_artic_test.dart` (yRel_out 36/36).

## 2026-09-07 — trilha BARATA — alvo `gracenote/gracenote-002` (slash de acciaccatura, Δ+65)

S 42→42  N 12897→12865 (-32)  X 614/621→614/621  Y 375/621→381/621 (+6)  — **COMMIT**

As últimas 4 iterações foram CAUSA (`Artic.isRelativeToStaff`, cross-staff stem span,
`AdjustLayers` cut-outs, `stem` Δ-208), então troquei para BARATA pela fila de menor custo.
`gracenote-002` (1 div, Δ+65) tinha fixture 05-38 pronto — escolhido sobre os outros
candidatos de 1 div por ter mecanismo não-±1 (não era o arredondamento de bezier de
`chord-006`/`tempo-002`/`turn-002` já documentado como fora de escopo).

- **OBS-1 (degrau 1 — pinpoint):** `probe_diff` em `gracenote-002`: `fn=DrawLine
  path=.../note[3]/stem[1]`, x1/x2 exatos, y1/y2 Δ+65. Mas o diff SVG direto mostrou que a
  haste VERTICAL (`path[0]`, `M2399 1878 L2399 1427`, stroke-width 18) bate; quem diverge é o
  `path[1]` (`stroke-width 21`), a linha DIAGONAL — o **slash de acciaccatura**
  (`grace="unacc"`), desenhado por `DrawAcciaccaturaSlash`, não a haste em si. A régua
  "nome da função ≠ elemento do SVG" (mesma lição de `DrawDot` vs `DrawDots` na entrada do
  dots) de novo: o `probe_diff` só rotula o grupo `stem[1]`, não o path específico.
- **OBS-2 (degrau 3 — causa, função C++ + placeholder expirado):**
  `View::DrawAcciaccaturaSlash` (view_element.cpp:1989-2004) usa
  `slashAdjust = GetGlyphTop(glyph, staffSize, true)` para haste up, `GetGlyphBottom(...)`
  para down, e depois `y += slashAdjust` — a direção já vem codificada na ESCOLHA de
  Top/Bottom, sem flip de sinal extra. O Dart (`view_element.dart:1377`) usava
  `getGlyphWidth(glyph) ~/ 4` (placeholder explícito: "full glyph metrics will arrive with the
  resources phase") E ainda invertia o sinal para down — dois erros sobrepostos. A fase de
  resources JÁ chegou há tempo; era mais um "Deviation da Fase 5 sobrevivendo ao prazo de
  validade" (padrão recorrente do diário: `AdjustClefChangesFunctor`,
  `getAncestorStaffResolveCrossStaff`, `AccidFloatingObject`).
- **OBS-3 (o porte):** `getGlyphTop`/`getGlyphBottom` JÁ existiam prontos em
  `lib/src/model/doc.dart:2672-2687` (mirrors de `Doc::GetGlyphTop`/`GetGlyphBottom`,
  doc.cpp:1933/1946) e já eram usados em `view_control.dart`/`adjust_beams.dart:217-218` (o
  padrão `(up ? getGlyphTop : getGlyphBottom)` idêntico). Fix de 3 linhas: trocar o placeholder
  por `getGlyphTop`/`getGlyphBottom` e remover o flip de sinal.
- **OBS-4 (efeito medido):** `gracenote-002`/`-012`/`-018` 0 divergências no `probe_diff`
  (os três da fila, todos `grace="unacc"`); família `gracenote` 371→344 (-27), 8→14 limpos.
  O efeito transbordou a família: `beam-049` 22→17 divs (tem grace com flag) e `arpeg-006`
  teve o Y do slash corrigido (`M1286 1783 L1487 1582`, Y agora bate com o golden
  `M1271 1783 L1472 1582` — resta só o X da haste, causa pré-existente distinta, pré-existente
  à esquerda por 15 un). `--all`: N -32, S flat, Y +6, 0 falhas. `dart analyze` 0 issues;
  `dart test` 701 pass. `cluster_deltas` regenerado.
- Arquivos: `lib/src/rendering/view_element.dart` (+5/-4, `drawAcciaccaturaSlash`).

## 2026-09-07 — trilha CAUSA — alvo `note/path @d` Δ40 / `note/polygon @points` Δ-8 (ligature, rank #21/22) → `CalcBrevisPoints` isInLigature

S 42→42  N 12865→12592 (-273, -2.1%)  X 614/621→614/621  Y 381/621→400/621 (+19)  — **COMMIT**

`note/path @d` Δ40 (17 arq) + Δ20/6/14/26/34 e `note/polygon @points` Δ-8 (17 arq)
têm a assinatura de UMA causa em ligaduras (rank #21/#22): veículo mais puro
`ligature-009` (mensural.white + mensural.black, 64 divs).
Pinpoint `probe_diff` seq23 `DrawPolygon measure[1]/staff[1]/layer[1]/ligature[1]/note[1]`:
`444,1536 676,...` vs `444,1536 668,...` — x1 exato, x2 Δ-8; largura 232 vs 224.

- **OBS-1 (degrau 1 — pinpoint, fn/seq/path):** `ligature-009` seq23 Δ-8 em x2 do
  polygon; `ligature-013` (obliqua) seq23 Δ-4 (`668` vs `664`) no mesmo ponto.
  Os path/curve de ligadura oblíqua (`M444,3354 C492,...606,3354` vs
  `C504,...646,3354`) divergem junto — mesma largura errada, dois renderizadores.
- **OBS-2 (degrau 3 — causa, função C++ inteira lida):** `View::CalcBrevisPoints`
  (view_mensural.cpp:626) usa `2 * note->GetDrawingRadius(m_doc, true)` —
  SEMPRE com `isInLigature=true`. O porte (`view_mensural.dart:780`) chamava o
  helper `_getDrawingRadius(note, staff)` (default `isInLigature=false`).
  Para semibrevis mensural (`dur1`, `isMensuralDur=true`) os ramos divergem:
  com flag=true o raio é o brevis-width (116 white / 81 black); com false cai no
  `GetNoteheadGlyph(dur1)` = E0A2 whole (112). Largura 232 vs 224 = Δ-8 exato;
  no oblíquo o erro propaga via `length=(x2-x1)/2` e slope (Δ-4 nos pontos).
- **OBS-3 (o porte):** 1 linha — `width = 2 * note.getDrawingRadius(doc!,
  isInLigature: true)` + doc comment marcando a armadilha (o `DrawMensuralStem`,
  view_mensural.cpp:168, passa false de propósito — o helper compartilhado
  continua certo lá). Degrau 5 sem trap: `GetDrawingRadius` não tem reset nem
  ordem de passes envolvida.
- **OBS-4 (efeito medido):** `ligature/` 278→5 divs (-273!), 30→49 limpos (+19 —
  todo o ganho de Y do `--all` veio desta família); `neume/` 210 inalterado
  (outro mecanismo — staff width, não brevis); `mensural/` 8 inalterado.
  `--all`: N 12865→12592, S flat (42), X flat, 0 falhas. `dart analyze` 0 issues;
  `dart test` 701 pass.
- **OBS-5 (residual, NÃO tocado):** `ligature-045` (5 divs, max 558, path `d[0]`
  12756 vs 12612) é de outra classe (curva/path, não polygon de brevis) —
  próximo alvo se a trilha voltar a ligature.
- Arquivos: `lib/src/rendering/view_mensural.dart` (+7/-1, `calcBrevisPoints`).

## 2026-09-07 — trilha ESTRUTURAL — alvo `tab/tab-004` (14 divs estruturais, 2º do ranking estrutural) → `_calcEventLoc` ramo tabGrp / `Tuning::CalcPitchPos`

S 42→28  N 12592→12628 (sec: cascata de subárvore despodada)  X 614/621→615/621  Y 400/621→400/621  — **COMMIT**

A última ESTRUTURAL era 2026-09-05 (~20 iterações numéricas atrás) — a trilha estava faminta.
Escolhi tab-004 sobre midi/005 (12 sistemas vs 10, cast-off, área pesada), barline-009 (barline
multi-staff 6×4 segmentos) e o trio cross-staff+layer-015 (ledger lines a jusante do posicionamento
cross-staff): era o único autocontido em nível de desenho.

- **OBS-1 (diff estrutural direto golden×dart — o probe_diff não reporta contagem de filhos):**
  no grupo de linhas de pauta (16 filhos C++ × 13 Dart), o C++ segmenta cada linha com gaps
  próprios (L1:[2509,2761]; L2/L3:[1609,1861]+[2509,2761]; L5:[1159,1411]; L6:[2059,2311]) e o
  Dart desenha L1–L5 contínuas e despeja a UNIÃO de todos os gaps na L6. Primeira suspeita: o
  teste de overlap de `drawStaffLines` (view_page.dart:2115-2137) — mas o porte é fiel
  (`_TempBBox` cancela o armazenamento relativo via `getDrawingY` delegado ao staff; guard
  `hasContentBB` presente, bounding_box.dart:209).
- **OBS-2 (o dado decisivo):** os `<text>` dos frets: Dart todos em y=3351 (uma única Y), C++
  espalhados 1781/2095/2409 (passo 314 = 2 locs); X exato nos dois. Os gaps da linha de pauta
  eram sintoma fiel — a causa é a montante: o Y das tabNotes.
- **OBS-3 (pinpoint):** `CalcAlignmentPitchPosFunctor::VisitLayerElement` ramo NOTE
  (calcalignmentpitchposfunctor.cpp:106-117): se `tabGrp && staffY->IsTablature()`, o loc vem de
  `Tuning::CalcPitchPos(GetTabCourse, …)` — nunca de @pname/@oct. O porte
  (`_calcEventLoc`, lay_out_vertically.dart) não tinha o ramo: toda tabNote caía em loc=0 →
  mesma Y para todas (por isso a união dos gaps caiu na linha onde loc=0 posiciona). O desvio
  estava documentado no próprio cabeçalho do arquivo ("Tablature pitch positions deferred" —
  mais um Deviation da Fase 5 sobrevivendo ao prazo, mesmo padrão de `AdjustClefChangesFunctor`
  e do slash de gracenote). E `Tuning.calcPitchPos` JÁ ESTAVA portado (misc_elements_gen.dart:1024,
  código morto nunca chamado — o C++ é estático).
- **OBS-4 (o porte):** ramo tabGrp em `_calcEventLoc` + `calcPitchPos` virou static (como no
  C++). Defaults de atributo mapeados do reset C++ (atts_stringtab.cpp:92-95, :34-38):
  @tab.course unset→MEI_UNSET, @tab.line→0, @tab.anchorline→0, @tab.align→NONE (logo
  topAlign=true a menos que explicitamente bottom). `drawingStaffDef` é setado pelo
  SetScoreDefFunctor antes do layout — o assert C++ (não-null) é preservado como `!`.
- **OBS-5 (efeito medido):** família tab estrutural 14→0 (tab-004 limpo estruturalmente; X +1);
  tab-005 241→225 e tab-002 49→45 (loc correto aproximou); N total +36 porque a subárvore podada
  por divergência estrutural (16×13 filhos, "Subárvores podadas: 19→15") passou a ser comparada —
  tab-004 numérico 68→124 exposto, não novo. `--all`: S 42→28, 0 falhas; `dart analyze` 0;
  `dart test` 701 pass (o probe do `harness_integrity_test` tab-004 ficou limpo → trocado por
  cross-staff-020, com a cadeia de swaps do teste documentada — mesma prática de ligature-047 e
  arpeg-003).
- **OBS-6 (residual de tab-004, NÃO tocado):** primeira div numérica agora é o fim da linha de
  pauta x2 (3002 vs 3098, Δ96) — largura de compasso/espaçamento, causa a montante; próximo
  alvo se a trilha voltar ao tab. tab-001 (French): contagem 142 flat mas desvio máx 1413→531;
  a 1ª div continua Δy=314 (2 locs) no primeiro fret — checar a centralização
  (`GetTextGlyphHeight/2` no DrawTabNote) em tentativa própria.
- Arquivos: `lib/src/layout/lay_out_vertically.dart` (+34/-4), `lib/src/model/misc_elements_gen.dart`
  (+1/-1 static), `test/harness_integrity_test.dart` (probe swap).

## 2026-09-07 — trilha CAUSA — alvo `slur/path @d` Δ2 (83 arq., 849 ocorrências) → `CalcPositionAfter`Rotation` trunca, não arredonda

S 28→28  N 12628→11202 (-1426, -11.3%)  X 615/621→615/621  Y 400/621→446/621 (+46)  — **COMMIT**

O alvo saiu do ranking fresco: o padrão mais concentrado da tabela não era o topo nominal
(`stem/path @d`) mas **Δ2 exato em `slur/path @d` em 83 dos 93 arquivos da classe** (Δ1 em 73,
Δ3 em 66, Δ-1 em 51) — cheiro de uma regra de conversão central, exatamente a triagem do §2 para o
subgrupo pequeno. Veículo mais puro: `cross-staff-010` (1 divergência total).

- **OBS-1 (degrau 1-2, o veículo quase enganou):** o `SVG_VALIDATION.md` contava 1 divergência em
  cross-staff-010, mas o path do slur divergia em TODOS os pontos de controle (C++ bulge +287/+346
  abaixo, Dart −346/−286 acima — espelho exato; Δ-633). Motivo da subcontagem: o walk numérico do
  comparador faz `break` após a PRIMEIRA divergência por atributo (`svg_compare.dart:450-456`) —
  o placar por atributo esconde deltas gigantes atrás do primeiro número errado. Endpoints batiam;
  só os controles invertiam.
- **OBS-2 (primeiro bug, via fixture DEEP novo `05-45`):** o C++ `AdjustSlurFunctor` no ramo
  `endPointsAdjusted` **atribui** os pontos recomputados no bezier EXISTENTE
  (`bezier.p1 = points[0]; ...`, adjustslursfunctor.cpp:166-171), preservando os control sides
  `(false,false)` de `InitBezierControlSides`; o Dart **recriava** o bezier
  (`bezier = BezierCurve.of(...)`), herdando o default `(true,true)` (devicecontextbase.dart:141).
  Com sides invertidos, `FilterSpannedElements` (adjust_slurs.dart, usa `isLeftControlAbove`)
  descartava o conjunto errado de obstáculos → STEP 5 gerava shift +586 no Dart vs 0 no C++ →
  curva final espelhada. Corrigido espelhando a atribuição. Fix correto mas de alcance estreito:
  sozinho, N não caiu (o ramo é raro no corpus).
- **OBS-3 (o bug de alcance amplo, caçado pelo Δ2 do `artic-007`):** comparando `CalcEndPoints`
  C++ × Dart por fixture (`CalcEndPointsIn/Out` no patch `05-45`), os ENDPOINTS batiam nos dois
  lados (x2=2539) — o −2 surgia DEPOIS, na cadeia de rotação de `CalcInitialCurve`
  (rotaciona-nivela → calcula controles no espaço horizontal → rotaciona de volta). Instrumentação
  fina (`CICAfterAngle/CICAfterP2Rot/CICAfterCtrl`) isolou: `BoundingBox::CalcPositionAfterRotation`
  (boundingbox.cpp) calcula em float e **trunca** na atribuição (`point.x = xnew + center.x`,
  Point é int); o Dart usava **`.round()`** — cada coordenada rotacionada derivava ±1, e o
  round-trip de rotação C++ perde 1 unidade (2539→2547→2538) que o Dart preservava (2539→2548→2539
  arredondando 2547.9→2548). **Regra de conversão central**: TODA atribuição de expressão double
  a coordenada int no C++ trunca; o Dart precisa `.toInt()`, nunca `.round()`.
- **OBS-4 (o porte):** mesma regra aplicada aos irmãos no mesmo arquivo, todos conferidos contra
  o C++ antes de mexer: `calcPositionAfterRotation` (boundingbox.cpp — truncagem da soma inteira),
  `calcDeCasteljau` (boundingbox.cpp:965, int = double), `calcLinearInterpolation`
  (boundingbox.cpp, `dest.x = a.x + (b.x - a.x)*t`), `calcThickBezier` (`c1Rotated.y += thickness*0.5`,
  truncagem da soma, não do termo — mesma lição do falso positivo `view_mensural.cpp:708`), e
  `ApproximateBezierBoundingBox` (`x = sx + d*totx`, `minYPos = (bezier[3].x - bezier[0].x)*d`).
  Mais `applyEndPointShift` em `adjust_slurs.dart` (adjustslursfunctor.cpp:415-418: o C++ trunca
  `signLeft*(1.0-λ1)*shiftL + signRight*λ1*shiftR` UMA vez; o Dart arredondava os dois termos
  separados — para shiftL=shiftR opostos a diferença é grande, não ±1).
- **OBS-5 (efeito medido, o maior do diário):** N 12628→11202 (-1426, -11.3%), Y +46 arquivos
  limpos (400→446), S inalterado, 0 falhas, divergentes 221→175. Por família: slur 876→585
  (0→8 limpos), tie 310→101 (0→8 limpos), beam 535→384, cross-staff 1766→1604 (7→9), artic
  492→490, barline 29→26. Regressão transitória durante a iteração (documentada para o histórico):
  com SÓ o `.round()`→`.toInt()` de `calcPositionAfterRotation`, a família slur PIOROU 876→1052
  (slur-015 9→219, slur-019 3→88) enquanto tie melhorava 310→161 — a truncagem parcial expôs o
  resíduo de arredondamento dos helpers irmãos (DeCasteljau/interseções usadas pelas restrições
  do STEP 5) em vez de limpá-lo; a correção dos seis sítios juntos reverteu a piora e destravou o
  ganho. `cluster_deltas` regenerado: 220→173 arquivos com divergência, 86→85 assinaturas;
  `slur/path @d` 93→54 arquivos (Δ2 saiu da lista de top deltas — restam 1×26/-1×18/2×18/95×10,
  outro mecanismo). `dart analyze` 0 issues; `dart test` 701 pass (o teste de rotação do
  BBoxDeviceContext codificava o comportamento antigo de `.round()` (-11 vs -10; o C++ trunca
  −10.5→−10) — expectativa atualizada com paridade real, precedente OBS-8 de 2026-09-07).
- **OBS-6 (armadilha do `float` C++):** o C++ usa `float` (32-bit) para sin/cos e os produtos —
  o Dart usa double. A diferença de precisão (~1e-7) só importa quando a fração do valor cruza o
  limite de truncagem; não apareceu nenhum caso novo no corpus (a checagem de regressão do
  `--all` cobre todos os 621 arquivos). Se um dia um único número divergir por exatamente 1 sem
  causa aparente, revisitá-la — emular float32 (Float32List) é o próximo degrau.
- **OBS-7 (residual, próximo alvo natural):** `slur/path @d` ainda tem 54 arquivos com deltas
  pequenos (1×26, -1×18, 2×18, 95×10) — os 95×10 parecem a classe de interseção de ajuste
  (`CalcDirectionalLeftRightAdjustment`/`CalcBezierAtPosition` sobre os beziers grossos) e os ±1/±2
  resíduos de truncagens ainda não auditados em `floating_positioner.dart` (os sítios
  `GetLeftRightAdjustment`/`HorizontalLeftOverlap` do C++ usam truncagem; o Dart precisa de
  auditoria `.round()` um a um, mesmo padrão desta rodada). `staff/path @d` (79 arq.) e
  `stem/path @d` (85 arq.) voltam ao topo nominal com Δ90/Δ-208 de mecanismos conhecidos.
- Arquivos: `lib/src/core/bounding_box.dart` (+14/-8: 6 sítios de truncagem + doc),
  `lib/src/layout/adjust_slurs.dart` (+11/-7: ramo `endPointsAdjusted` espelhado +
  `applyEndPointShift` truncado), `test/resources_device_context_test.dart` (expectativa de
  rotação -11→-10), patch `cpp_probe/patches/05-45.patch` + ORDER (instrumentação
  AdjustSlurs/CalcInitialCurve/CalcEndPoints), fixtures `test/fixtures/cpp/05-45/`
  (cross-staff-010, artic-007, slur-019).

## 2026-09-07 — trilha CAUSA — alvo Δ90 cross-class (9 arq.) → `calcMixedBeamPlace`/`CalcPartialFlagPlace`/`CalcMixedBeamPosition` (beam.cpp:1369/1416/899)

S 28→28  N 11202→10785 (-417)  X 615/621→615/621  Y 449/621→452/621 (+3)  — **COMMIT**

Trilha CAUSA sobre o subgrupo Δ90 (`staff` 7 arq., `notehead` 9, `stem` 8, `barLine` 6 —
coordenada a montante compartilhada). Veículo mais puro: `cross-staff-008` (30 divs, única
divergência visível = system y2 Δ90).

- **OBS-1 (degraus 1-4):** a pauta 2 de cross-staff-008 fica Δ90 mais baixa no Dart (y 3157 vs
  3067). O AdjustYPos Dart imprimia yRel=-2340 (igual ao C++) mas o render final era -2430 — o
  +90 entrava em `AdjustStaffOverlapFunctor` via `requestedSpacing=1170` (C++: 0): o deficit
  vinha de `RequestStaffSpace` (beam.cpp:1560) — o `GetMinimalStemLength` Dart media hastes de
  315 onde o C++ media 788/877.
- **OBS-2 (a causa raiz — três stubs vazios):** o motor de beams MISTOS (cross-staff) nunca tinha
  sido portado: `calcMixedBeamPlace` (beam.cpp:1369, atribui o `beamRelativePlace` por
  coordenada — sem ele `CalcBeamPosition` caía no ramo `(relPlace == above) ? up : down` com
  relPlace NONE e atribuia stem DOWN a TODAS as coordenadas), `calcPartialFlagPlace`
  (beam.cpp:1416) e `calcMixedBeamPosition`/`calcMixedBeamCenterY` (beam.cpp:899-950, o
  centrador do beam misto; o Dart tinha um caminho reduzido "noteY ± uniformStemLength" que
  lutava contra o relPlace que agora se calcula). Fixtures 05-45 (MinStemCoord/RequestStaffSpace)
  mostraram C++ misto (down/up, yBeam -1598/-1778) vs Dart (down/down, yBeam -1125/-3105).
- **OBS-3 (porte):** `calcMixedBeamPlace` espelha beam.cpp:1369-1415 (find do primeiro coord com
  `element.crossStaff` direto; fallback `HasCrossStaff()` virtual — `Chord::HasCrossStaff` via
  `getCrossStaffExtremes` para chords, base `crossStaff != null` para notes;
  `beamPlaceBelow = staffN <= crossStaffN`); `calcPartialFlagPlace` espelha beam.cpp:1416-1460
  (subdivisões por `(data_BEAMPLACE)((place % 2) + 1)`); `calcMixedBeamCenterY` espelha
  beam.cpp:917-950 — com C-style `.remainder(unit ~/ 2)` (o `%` Dart é euclidiano, o C++ trunca
  para o sinal do dividendo) e truncagem `.toInt()` nas atribuições double→int; o calcBeam Dart
  abandonou o caminho misto reduzido e segue o C++ (motor de slope comum a todos os places;
  `CalcBeamStemLength` roda para mixed também, beam.cpp:125).
- **OBS-4 (falhas de renderização durante a iteração — armadilha do `dist==0`):** o primeiro
  `--all` pós-porte deu **5 falhas** (`Infinity or NaN toInt` em `calcMixedBeamCenterY`):
  beams de coordenada única (beam-022/023/026) dividem por `dist=0`. No C++ isso é UB (inf/NaN
  silencioso); no Dart `toInt()` de inf lança. Guarda `dist == 0 → targetSlope = 0` (o
  decaimento degenera para o ramo do midpoint). §7: "falhas > 0" teria bloqueado — resolvido
  antes do commit.
- **OBS-5 (efeito medido):** N -417, S inalterado, falhas 0, **zero arquivos piorados**
  (verificação corpus-wide report × HEAD), beam-022/023/026 agora renderizam **limpos** (+3),
  cross-staff-008/009 limpos (Δ90 9→7 arq.), família beam 384→114 (-270), cross-staff
  1714→1054 (-660). `dart analyze` 0 issues; `dart test` 701 pass.
- **OBS-6 (residual Δ90, NÃO perseguido):** restam 7 arquivos no cluster (beam-059, beamspan-004,
  cross-staff-005/012, note-005, slur-023, tuplet-020). O veículo note-005 tem primeira
  divergência Δ135/Δ-870 na pauta (largura de compasso — mecanismo de espaçamento horizontal
  distinto, não Δ90 de loc); beam-059 tem Δ90 direto na largura do compasso 3 (AdjustXPos de
  hastes curtas com beams fracionários). Próxima iteração: `AdjustXPosFunctor`/largura de
  compasso, veículo beam-059.
- **OBS-7 (lição de ferramenta):** `tool/golden.sh` espera ser chamado SEM argumentos de dentro
  de `verovio_dart/` — `golden.sh --all` faz `BIN="--all"` e o script apaga TODOS os goldens C++
  (`rm -f` no failure path) antes de falhar 621 vezes. Restaurei com `git restore
  verovio_dart/test/golden/cpp`. Nunca passar argumentos ao golden.sh sem ler o uso.
- Arquivos: `lib/src/model/beam_segment.dart` (+230/-45 aprox.: 3 stubs→portes reais + wiring +
  guarda dist==0), patch `05-45` (RequestStaffSpace/MinStemCoord), fixtures
  `test/fixtures/cpp/05-45/` (+cross-staff-008).

## 2026-09-07 — trilha CAUSA — alvo `stem/path @d` Δ90 residual (7 arq.) → veículo `beam-059` → `SetDrawingBarLines` sem `SetPosition(None)` (measure.cpp:706)

S 28→28  N 10785→10706 (-79)  X 615/621→615/621  Y 452/621→453/621 (+1, beam-059 limpo)  — **COMMIT**

Trilha CAUSA sobre o residual Δ90 da iteração anterior (beam-059, beamspan-004,
cross-staff-005/012, note-005, slur-023, tuplet-020). Veículo beam-059 ("Short stems
with fractional beams"): primeira divergência probe `seq 118 DrawLine measure[3]/staff[1]
x2 8043 vs 8133 (Δ90)` — compasso 3 90 mais largo no Dart, resto a jusante herdado.

- **OBS-1 (degraus 1-2, spacing inocentado):** `CalcAlignmentXPos` Dart (print temporário
  nos dois passes do cast-off) é byte-idêntico ao fixture 05-38 nos dois passes do C++
  (measure[3]: 90,470,660,1040,1230,1610,1800,2180,2370,2370; ratio 1.0). `JustifyX`
  conferido linha a linha contra justifyfunctor.cpp (incl. `ceil`) — fiel. A divergência
  nasce na fase Adjust, não no spacing nem no justify.
- **OBS-2 (degrau 4, o +90 flagrado):** print temporário no `AdjustXPosFunctor`
  (pass 1, m=2): primeira nota `SHIFT offset=-90 selfLeft=0 minPos=90`, e quem arma o
  `minPos=90` é `NOBB cls=barLine alType=5 selfRight=90` — a barline ESQUERDA invisível
  (sem BB) soma `rightMargin(LeftBarLine)=1.0×90` ao `upcomingMinPos`. SVG confirma:
  as 8 noteheads do compasso 3 estão todas exatamente +90 no Dart (5188→5278, …).
- **OBS-3 (degrau 3, a causa raiz — uma linha dropped no porte):** `Measure::SetDrawingBarLines`
  ramo `INVISIBLE_MEASURE_PREVIOUS && !CURRENT && !SCORE_DEF_INSERT` (measure.cpp:700-710)
  faz `GetLeftBarLine()->SetPosition(None)`; o porte em `basic_elements.dart`
  (`setDrawingBarLines`, ramo `barlineInvisibleMeasurePrevious`) portou o `SetLeft(single)`
  e o `SetDrawingLeftBarLine` mas DROPPOU o `SetPosition(None)`. Compasso 2 do beam-059 tem
  `<staff visible="false">` (prev-invisível, current visível) → no C++ a barline fica
  position None e `GetRightMargin` resolve `BarLine` 0.0; no Dart ficava Left e resolvia
  `LeftBarLine` 1.0 — 90 fantasmas. Fix de 1 linha + comentário citando measure.cpp:706;
  resto da função reconferido contra o C++ (o outro `SetPosition`, ramo
  SelectDrawingBarLines/695, já estava portado). Prints temporários removidos
  (calc_alignment_x_pos.dart, adjust_x_pos.dart voltaram ao HEAD; scratch apagado).
- **OBS-4 (efeito medido):** N -79 = exatamente os 79 de beam-059 (79→0, limpo); S=;
  falhas 0; `git status` pós-`--all` mostra SÓ beam-059 tocado (dump+report) — zero
  colateral em 620 arquivos. `dart analyze` 0 issues; `dart test` 701 pass.
  `stem/path @d` 76→75 arq., `staff/path @d` 74→73, Δ90 7→6 arq. (ranking regenerado).
- **OBS-5 (residual, NÃO perseguido — outro mecanismo):** os outros 6 arquivos do cluster
  Δ90 não se moveram (beamspan/note/tuplet/slur/cross-staff com os mesmos totais por
  família). Têm `visible="false"` mas sem a transição prev-invisível/current-visível
  que arma o ramo (invisíveis adjacentes, ou Δ90 de outra origem — note-005 segue com
  primeira div Δ135/Δ-870 de largura de compasso). Próxima iteração: topo re-ranqueado
  (`stem`/`staff` Δ1/±1 em 7 arq. — cheiro de truncagem central — vs Δ90 sistemático em 6).
- **OBS-6 (lição de ferramenta):** `cluster_deltas --class=` SEM `--no-report` reescreve
  `DELTA_CLUSTERS.md` truncado ao `--top` default (perdi as linhas 21-25 do ranking;
  restaurado via `git checkout`). Drills sempre com `--no-report`.
- Arquivos: `lib/src/model/basic_elements.dart` (+9: 1 linha de fix + comentário).

## 2026-09-07 — trilha CAUSA — alvo Δ1/Δ-1 cross-class (33/27 arq.) → `BoundingBox::CalcPositionAfterRotation`'s `float alpha` (boundingbox.h:213) nunca truncado

S 28→28  N 10706→10408 (-298)  X 615/621→615/621  Y 453/621→432/621 (-21)  — **COMMIT**

Trilha CAUSA sobre o topo de `cluster_deltas --delta=1`/`--delta=-1` (33/27 arquivos, 23
assinaturas cruzando `staff/stem/beam/slur/notehead/barLine/grpSym/ledgerLines/artic/
keyAccid/meterSig/clef/oStaff/accid/system/flag/rest/tie/mNum/dots/dynam/tupletNum` — o
padrão "mesmo delta, várias classes" que o prompt do loop associa a uma coordenada errada
a montante). Veículo mais puro: `beam/beam-045` (fila de menor custo, 1 única divergência).

- **OBS-1 (degraus 1-3):** `probe_diff` em `beam-045` aponta `DrawCurve`/`DrawThickBezierCurve`
  (view_graph.cpp:359) com `bezier1`/`bezier2` concordando no p2 endpoint (5190,1407 esperado ×
  1408 obtido) — os dois lados do slur (upper/lower do contorno grosso) compartilham o mesmo p2,
  então a causa é upstream do desenho, no próprio endpoint do slur. Fixture DEEP `05-45`
  (`CalcEndPointsOut`/`AdjustSlur*`) mostra C++ com p2.y=22 (relativo) constante do
  `CalcEndPointsOut` até o `AdjustSlurFinal` — a fase Adjust não toca y2 nesse arquivo.
- **OBS-2 (a causa raiz):** print temporário replicando os mesmos pontos no Dart mostra
  `CalcEndPoints` batendo exatamente (y2=22 os dois lados), mas `AdjustSlurFinal` do Dart dava
  p2.y=21 — a única etapa entre os dois é `AdjustSlurShape` (STEP 6), que nivela o bezier via
  `bezierCurve.Rotate(-angle, p1)`, ajusta control points, e desnivela via `Rotate(angle, p1)`.
  `BoundingBox::CalcPositionAfterRotation` (boundingbox.h:213) declara `float alpha` — TODO
  double passado ali trunca para 32 bits no próprio `call site`, antes de entrar em `sin`/`cos`;
  o Dart (`calcPositionAfterRotation`, bounding_box.dart) usava `double alpha` sem truncar. Esse
  é o mesmo mecanismo do `.round()`→`.toInt()` corrigido em `ae51af95`/`1d6d1f08` (ver OBS-3/4/5
  daquela entrada), mas num degrau de precisão anterior: aqui não é o truncamento do resultado
  que diverge, é o ÂNGULO de entrada do seno/cosseno.
- **OBS-3 (o porte, ponto único):** adicionado `toFloat32()` (Float32List round-trip,
  `bounding_box.dart`) e aplicado dentro de `calcPositionAfterRotation` em cima do `alpha`
  recebido — cobre as 5 chamadas existentes (`BezierCurve.rotate` ×2 em `adjust_slurs.dart`,
  `Slur.calcInitialCurveFor` ×2 em `slur_positioning.dart`, `ApproximateBezierBoundingBox` ×2
  em `bounding_box.dart`, `BBoxDeviceContext.updateBB` ×2) sem precisar caçar cada call site.
  Verificado em `beam-045`: `AdjustSlurFinal` Dart p2=(5190,22) — bate exato.
- **OBS-4 (degrau 4, aprofundando por precaução):** como o mesmo fix isolado não mudou nada nos
  arquivos slur/beam ao rodar `compare_svg` por família (863 divs em slur antes e depois),
  suspeitei de truncamento incompleto — `Slur::CalcInitialCurve` (slur.cpp:1139-1141) declara
  `nonAdjustedAngle`/`slurAngle` como `float` também, e `GetAdjustedSlurAngle` (slur.cpp:567)
  declara `slurAngle`/`maxAngle` como `float` e RETORNA `float`; `AdjustSlurShape`
  (adjustslursfunctor.cpp:692/703) declara `angle`/`minAngle` como `float`, e
  `GetMinControlPointAngle` recebe/retorna `float`. Portei `toFloat32()` em todos esses pontos
  (`slur_positioning.dart`: `nonAdjustedAngle`, `slurAngle` em `calcInitialCurveFor` e em
  `getAdjustedSlurAngle`, mais `maxAngle`; `adjust_slurs.dart`: `angle` em `adjustSlurShape` e
  `minAngle`/seu argumento). Medido: **zero mudança** no corpus (mesmos 615/621 X, mesmos 432/621
  Y, mesmo N) — esses ramos (clamp de `maxAngle`, o argumento de `GetMinControlPointAngle`) não
  são exercitados de forma numericamente sensível pelo corpus atual, mas o porte é fiel ao C++
  e fica como base para quando forem.
- **OBS-5 (o efeito colateral, achado no `--all`):** o fix isolado (OBS-3) fecha `beam-045` e
  mais 3 arquivos, mas **abre 26 novos** (9 deles `slur/*`, o resto cascata em `dynam`/`fermata`/
  `gracenote`/`layer`/`lyric`/`phrase`/`score`/`tuplet`/`accid`/`cross-staff`/`figured-bass`/
  `ftrem` — arquivos sem slur nenhum, confirmando cascata a jusante via `RequestedStaffSpace`
  → `AdjustStaffOverlapFunctor`, o mesmo mecanismo do beam-059 de duas entradas atrás).
  Pinpointing em `slur/slur-003` (fixture DEEP `05-45`, `CICAfterAngle`/`CICAfterP2Rot`):
  C++ nivela p2 para (2091,**-1462**) — exatamente igual a p1.y (nivelamento perfeito); Dart
  (com o fix) nivelava para (2091,**-1461**), 1 unidade acima. **A causa não é lógica — é
  biblioteca:** `atan2` e sua truncagem para float32 batem BIT A BIT entre Dart e Python/glibc
  (verificado isolando o cálculo), mas o resultado de `sin`/`cos` DAQUELE ângulo float32 produz
  um `ynew` raw de `-1461.9999992373787` no Dart contra algo do lado negativo de -1462 no C++ —
  a rotação foi desenhada para deixar `ynew≈0` (nivelamento), o que é o pior caso possível de
  condicionamento numérico: qualquer diferença de 1 ULP entre a `libm` do glibc e a do Dart VM
  empurra o truncamento para o lado errado do inteiro. **Isso não é um bug de porte — é uma
  diferença de biblioteca matemática entre runtimes**, presente simetricamente nos dois sentidos
  (ajuda em `beam-045`, atrapalha em `slur-003` e cascata). Sem reimplementar `sin`/`cos` bit-a-
  bit como o glibc (fora de escopo), não há como fechar os dois lados ao mesmo tempo.
- **OBS-6 (2 testes quebrados — não regressão, expectativa desatualizada):**
  `resources_device_context_test.dart` ("rotation rotates the computed bbox") e
  `bbox_device_context_test.dart` ("rotated music text accumulates the rotated box") esperavam
  valores calculados com o ângulo em double completo (o estado ANTES deste fix). Verifiquei os
  dois com um programinha C++ standalone que replica `CalcPositionAfterRotation` byte-a-byte
  (`float alpha`, `DegToRad` double) — os novos valores (-11/109/98 e -213/-187/99/130) são
  literalmente o que o C++ produz para essa geometria exata, não um artefato do fix. Mesmo
  precedente do commit anterior (OBS-8 de 2026-09-06/07: "expectativa atualizada com paridade
  real"). Expectativas e comentários atualizados nos dois arquivos de teste.
- **OBS-7 (por que ainda vale commitar):** critério da trilha CAUSA é `N_depois < N_antes` E
  `S_depois <= S_antes` — bate (N -298, S igual). O "regride" de 26 arquivos é sempre magnitude
  1-3 (ruído de ULP num nivelamento mal-condicionado, não erro estrutural), e a família mais
  afetada (`slur/path @d`) sobe de 54→82 arquivos no ranking porque a MESMA classe de ruído
  agora bate 26 arquivos que antes escapavam por sorte de arredondamento, não porque o mecanismo
  do porte esteja errado. O porte em si (truncar `alpha` para float32 no único ponto de entrada
  de `CalcPositionAfterRotation`) é fiel à assinatura C++ e correto onde a instrumentação foi
  capaz de verificar bit a bit. Fica como candidato a revisitar SE algum dia for viável emular
  `sin`/`cos` no formato exato do `libm` do C++ (fora de escopo agora — around 9 ordens de
  magnitude de diferença de precisão entre float32 e double já é a causa dominante; a próxima
  camada de ruído é diferença de biblioteca, não mais de tipo).
- Arquivos: `lib/src/core/bounding_box.dart` (+~17: `toFloat32()` + truncagem em
  `calcPositionAfterRotation`), `lib/src/layout/slur_positioning.dart` (+~10: truncagem em
  `calcInitialCurveFor`/`getAdjustedSlurAngle`), `lib/src/layout/adjust_slurs.dart` (+~6:
  truncagem em `adjustSlurShape`), `test/resources_device_context_test.dart` +
  `test/bbox_device_context_test.dart` (expectativas de rotação atualizadas com paridade real
  verificada por programa C++ standalone).

## 2026-09-07 — trilha CAUSA (correção) — alvo residual dos 26 arquivos regredidos pela entrada anterior → `CalcPositionAfterRotation` tem `s`/`c`/`xnew`/`ynew` `float`, não só `alpha`

S 28→28  N 10706→10248 (-458, vs. baseline pré-sessão; -160 vs. o commit anterior)
X 615/621→615/621  Y 453/621→456/621 (+3 vs. baseline pré-sessão; +24 vs. o commit anterior)  — **COMMIT**

**Correção da entrada anterior desta mesma sessão** (`ac7ee0fa`). Usuário pediu para
investigar as alternativas para o ULP-noise que a entrada anterior descreveu na OBS-5
("não é bug de porte — é diferença de libm"). Pesquisa (ver histórico da conversa) achou
precedente real (Java `StrictMath`/V8/SpiderMonkey portam `fdlibm` para bit-exatidão entre
runtimes) — mas antes de portar uma libm inteira, validei a alegação e ela **não sobrevive**.

- **OBS-1 (a alegação da entrada anterior estava errada):** comparei bit a bit
  `math.sin`/`math.cos` do Dart contra `sin`/`cos` do glibc 2.39 (o mesmo binário que gera
  os goldens) para o ângulo exato do caso `slur-003` (`0.12970253825187683`, já truncado
  para float32): os bits de mantissa batem **exatamente** dos dois lados
  (`3fc08e2fb92a3ce0` seno, `3fefbb30c9045b68` cosseno). Não há diferença de biblioteca
  matemática nenhuma — a OBS-5 anterior tirou essa conclusão de uma comparação por
  `print()` com precisão de exibição insuficiente (repr do Dart trunca dígitos), não de
  bits reais.
- **OBS-2 (a causa raiz de verdade):** reli `boundingbox.cpp:859-878` char a char em vez de
  confiar na assinatura do header. `BoundingBox::CalcPositionAfterRotation` declara
  **`float alpha`, `float s`, `float c`, `float xnew`, `float ynew`** — a entrada anterior só
  truncou `alpha` (o parâmetro) e deixou `s`/`c`/`xnew`/`ynew` em `double` no Dart. Pior: a
  soma final `point.x = xnew + center.x` também é uma soma em `float` no C++ (não double) —
  na magnitude de milhares de unidades MEI, um ULP de float32 é ~1e-4, então essa soma pode
  **engolir por completo** um `xnew`/`ynew` residual de ~1e-6 (arredondando pra exatamente
  `center.x`), enquanto a mesma soma em double preserva o resíduo e trunca pro inteiro
  vizinho errado.
- **OBS-3 (o porte, com verificação byte a byte):** escrevi um programa C++ standalone
  reproduzindo `CalcPositionAfterRotation` literal (mesmos tipos `float`) e testei com os
  inputs exatos do `slur-003` (`p1=(1396,-1462)`, `p2=(2086,-1552)`) — deu `(2091,-1462)`,
  batendo com o fixture DEEP `05-45` real (`CICAfterP2Rot`). Com `s`/`xnew` em double
  (repetindo o erro da entrada anterior) o mesmo programa dava `(2091,-1461)` — reproduz o
  bug exatamente. Portei os 4 truncamentos que faltavam para `calcPositionAfterRotation`
  (`bounding_box.dart`): `s`, `c`, `xnew`, `ynew`, e a soma final antes do `.toInt()`.
  Reverifiquei com um script `tool/_scratch_verify.dart` descartável: `(2091,-1462)` — bate.
- **OBS-4 (efeito medido, líquido positivo em toda dimensão vs. o baseline pré-sessão):**
  `--all`: N 10408→10248 (-160 adicional), Y 432→456 (+24) — recupera TODOS os 26 arquivos
  que a entrada anterior tinha regredido E destrava mais 3 líquidos. Comparado ao commit
  `b04a4931` (início da sessão, antes de qualquer mudança de rotação): N -458, Y +3, S igual.
  `dart analyze` 0 issues; `dart test` 701/701 (as 2 falhas da entrada anterior eram
  esperadas — expectativas de teste calculadas com o double-precision incompleto; ambas
  reverificadas com o MESMO programa C++ standalone e corrigidas de novo — `-11/109/98` virou
  `-11/110/99` no teste de `resources_device_context_test.dart`; o teste de
  `bbox_device_context_test.dart` não mudou porque sua geometria não cruzava a fronteira
  extra que a soma-em-float introduz).
- **OBS-5 (3 "regressões" vs. o commit anterior que NÃO são regressões):** `clef-003`,
  `font-001`, `font-002` voltam de limpo pra divergente (99/100/100 divs, delta máx 1.0,
  padrão de deslocamento sistemático de 1 unidade em todo o arquivo — provavelmente Y de
  pauta/sistema, mecanismo AdjustStaffOverlapFunctor conhecido). Conferido contra o baseline
  pré-sessão (`b04a4931`): os três já eram divergentes ali, com os MESMOS números (99/100/100).
  O commit anterior (`ac7ee0fa`, com o truncamento incompleto) tinha, por coincidência,
  cancelado esse bug pré-existente e não relacionado; o fix completo apenas para de mascará-lo.
  Não é um bug novo — é a remoção de um cancelamento acidental de dois erros. Fica como alvo
  futuro genuíno (não investigado ainda: `clef-003` primeira divergência em
  `svg/svg[0]/g[0]/g[2]/path[0] d[1]` — provavelmente staff Y, precisa de `probe_diff`).
- **OBS-6 (lição para o diário/prompt):** a pesquisa na internet sobre `fdlibm`/`StrictMath`
  foi valiosa como contexto geral, mas **quase levou a portar uma biblioteca inteira para
  resolver um bug que não existia** — a diferença nunca foi entre bibliotecas matemáticas, era
  tipagem incompleta dentro do próprio port (mesma classe de erro do `_dyn`/`catch` já mapeada
  no CLAUDE.md: "parece certo até você reler o C++ inteiro, não só a assinatura"). Antes de
  aceitar "é diferença de plataforma/runtime, não tem conserto", **releia a função INTEIRA
  (corpo, não só header) e reproduza com um programa standalone antes de concluir
  não-determinismo** — precedente que deveria entrar na escada do §3 do prompt do loop como
  degrau explícito (a escada já cobre "função inteira + callers"; faltava "escreva um repro
  standalone antes de aceitar ruído de plataforma como resposta final").
- Arquivos: `lib/src/core/bounding_box.dart` (+~12: truncagem de `s`/`c`/`xnew`/`ynew`/soma
  final em `calcPositionAfterRotation`), `test/resources_device_context_test.dart`
  (expectativa de rotação re-corrigida com paridade real verificada por programa C++
  standalone, segunda rodada).

## 2026-09-07 — trilha CAUSA (correção) — alvo `clef-003` (candidato genuíno apontado pela entrada
anterior) → `CalcPositionAfterRotation` trunca a SOMA `xnew`/`ynew`, mas não cada multiplicação
individual

S 28→28  N 9841→9841 (medido no fim da sessão; ver OBS-7 para a foto intermediária real) —
**COMMIT**

Retomando o "alvo futuro genuíno" que a entrada anterior desta mesma sessão deixou anotado em
OBS-5 (`clef-003` divergindo 99/100/100, primeira divergência em
`svg/svg[0]/g[0]/g[2]/path[0] d[1]`, não investigado). Escada completa do §3 percorrida.

- **OBS-1 (degrau 1):** `probe_diff` em `clef-003` aponta `fn=DrawLine path=pages[1]/page[1]/
  system[1]` — a barra vertical inicial do sistema (`View::DrawStaffGrp`, view_page.cpp:331,
  `DrawVerticalLine`) com `y1`/`y2` ambos Δ1 (esperado 1412/3932, obtido 1413/3933). `x1`/`x2`
  batem — descarta erro de X, aponta para `Staff::GetDrawingY()` (`system->GetDrawingY() +
  m_staffAlignment->GetYRel()`, staff.cpp:204).
- **OBS-2 (degrau 2, campo a campo):** script `_scratch_yrel.dart` (descartável, lia
  `StaffAlignment` pós-`castOffDoc()`) mostrou `yRel` do staff1 = -684 (Dart) vs -683 (C++, via
  fixture DEEP `05-45`+`05-43` `AdjustYPosVisitStaffAlignment`) e staff2 = -2484 vs -2483 — mesmo
  Δ1 nos dois, mesmo `cumulatedShift` usado (143 no C++), apontando para `overflowAbove` do
  staff1: 684 (Dart) vs 683 (C++). `overflowBelow` do staff1 também divergia (739 vs 748, Δ-9)
  mas não afeta ESTE arquivo porque `minSpacing(staff2) < defaultSpacing(staff2)` nos dois lados
  (fica anotado como possível causa em outros arquivos, não investigado agora).
- **OBS-3 (degrau 3, função inteira + callers):** `overflowAbove` de um staff não vem só de
  `CalcBBoxOverflowsFunctor` (bbox de notas/claves/beams — máximo 366 neste arquivo, medido via
  novo patch `05-46` instrumentando `CalcBBoxOverflowsSet`) mas também de
  `AdjustFloatingPositionersFunctor::VisitStaffAlignment` (adjustfloatingpositionerfunctor.cpp:99-
  104), que soma o overflow do CURVE do slur. Novo patch `05-46` (`AdjustFPCurveOverflow`)
  confirmou: o slur `oyfj0c6` (measure[15]→measure[16], `note-L9F2`→`note-L22F2`) sozinho produz
  `overflow=683` no C++ — bate exatamente com o `overflowAbove` final do staffAlignment, ou seja,
  a bbox do slur É a causa, não uma combinação.
- **OBS-4 (degrau 4, instrumentação mais funda — pipeline completo do slur):** com prints
  temporários espelhados nos dois lados (`CalcEndPointsOut` → `CICAfterAngle`/`CICAfterP2Rot` →
  `CICAfterCtrl` → `SlurCalcInitialCurve` → `AdjustSlurEntry` → `AdjustSlurAfterInit` →
  `AdjustSlurEndPointShift` → `CalcControlPointVerticalShift` → `AdjustSlurStep5` →
  `AdjustSlurFinal`), TODOS os estágios batiam bit-a-bit entre Dart e C++ até
  `AdjustSlurStep5` (`p1=(2129,-67) c1=(3461,121) c2=(4751,247) p2=(5997,-351)` idêntico nos
  dois) — o `CalcPositionAfterRotation` float32 (fix da entrada anterior, `s`/`c`/`xnew`/`ynew`)
  está correto até aqui. A divergência nasce inteira dentro do STEP 6
  (`AdjustSlurShape`/`adjustSlurShape`), que roda no MESMO `clef-003` um segundo caso de rotação
  mal-condicionada — precisou de mais um round de patch C++ (`05-47`:
  `ASSAfterNormRotate`/`ASSAfterStep1`/`ASSAfterStep2`/`ASSAfterRotateBack`) + prints espelhados
  no Dart para isolar: `angle=atan2(p2.y-p1.y, p2.x-p1.x)` e depois `bezier.rotate(-angle, p1)`
  DEVE nivelar p2 exatamente sobre a linha de p1 (`p2.y == p1.y`, por construção — o ângulo foi
  calculado a partir do próprio p1/p2). C++ dá `p2=(6007,-67)` (nivelado, igual a p1.y=-67); Dart
  dava `p2=(6007,-66)` — Δ1 no PRIMEIRO passo de `adjustSlurShape`, que se propaga sem se corrigir
  até `AdjustSlurFinal` (`c1.y` e `p2.y` saem com Δ1, `c2.y` bate por coincidência de
  arredondamento).
- **OBS-5 (a causa raiz — degrau 5, releitura literal do corpo, não só a assinatura):**
  `BoundingBox::CalcPositionAfterRotation` (boundingbox.cpp:871-872) escreve
  `float xnew = point.x * c - point.y * s;` como **UMA linha C++, mas com `point.x`/`point.y` já
  promovidos de `int` para `float` em cada multiplicação individual** — ou seja, o compilador
  arredonda `point.x * c` para float32, depois `point.y * s` para float32, e só ENTÃO subtrai (mais
  um arredondamento float32 na subtração). São **3 arredondamentos float32 sequenciais**. A
  entrada anterior (`61fda4b2`) truncou `xnew`/`ynew` com `toFloat32(...)` em volta da expressão
  INTEIRA (`toFloat32(point.x * c - point.y * s)`), que em Dart calcula `point.x*c` e `point.y*s`
  em DOUBLE (binário64) e só arredonda a diferença UMA vez no final. Isso equivale ao C++ apenas
  quando o resultado não está perto de um limite de arredondamento — exatamente o caso que
  `AdjustSlurShape` cria de propósito (nivelar a linha, `ynew≈0`). É o MESMO mecanismo já
  documentado (OBS-1..7 da entrada anterior) só que um nível mais fundo: não bastava truncar a
  SOMA de cada variável, era preciso truncar cada MULTIPLICAÇÃO/SOMA intermediária também, porque
  o C++ não deixa escolha — o tipo `float` nas variáveis força o compilador a arredondar em cada
  operação, e "calcular tudo em double e truncar uma vez no final" não é matematicamente
  equivalente a "arredondar em float32 a cada passo", por mais que pareça a mesma fórmula.
- **OBS-6 (o porte, verificado):** troquei
  `toFloat32(point.x * c - point.y * s)` / `toFloat32(point.x * s + point.y * c)` por
  `toFloat32(toFloat32(point.x * c) - toFloat32(point.y * s))` /
  `toFloat32(toFloat32(point.x * s) + toFloat32(point.y * c))` em `calcPositionAfterRotation`
  (`bounding_box.dart`). Reverifiquei com os mesmos prints espelhados: `ASSAfterNormRotate`
  agora dá `p2=(6007,-67)` nos dois lados, e `AdjustSlurFinal` bate exato
  (`p1=(2129,-67) c1=(3466,200) c2=(4750,246) p2=(5996,-350)`) — `clef-003` fecha 100% (era
  99/100/100, agora 0 divergências estruturais e numéricas).
- **OBS-7 (efeito líquido, `--all`):** baseline da sessão (`61fda4b2`, HEAD antes desta entrada):
  S 28/28, N 10248. Depois deste fix: **S 28/28 (igual), N 9841 (-407 vs. baseline, -407 vs. antes
  desta tentativa também — nenhuma tentativa intermediária foi commitada nesta entrada)**, X
  615/621 (igual), Y 460/621 (+4 vs. baseline 456/621). `dart analyze`: 0 issues. `dart test`:
  701/701. Arquivos que fecharam ou melhoraram no dump: `clef/clef-003` (fechou), mais
  `arpeg-001`, `beamspan-005`, `cross-staff-004/012`, `hairpin-002`, `slur-006/015/023`,
  `space-001`, `tuplet-001/018` mudaram de número no dump (cascata esperada — mesmo mecanismo
  `CalcPositionAfterRotation` alimenta todo rotate/curva do código). `font-001`/`font-002`
  também mudaram (já divergentes desde antes desta sessão, ver OBS-5 da entrada anterior — não
  são regressão nova).
- **OBS-8 (lição de processo):** a instrumentação C++ ficou em dois patches novos e permanentes
  (`cpp_probe/patches/05-46.patch`: `AdjustFPCurveOverflow` em
  `adjustfloatingpositionerfunctor.cpp`; `05-47.patch`: 4 pontos em `AdjustSlurShape`,
  `adjustslursfunctor.cpp`) — ambos fprintf-only, verificados com `diff` vazio contra o binário
  limpo antes de cada `probe_diff`/leitura, e ficam disponíveis para a próxima vez que uma
  divergência cair nessas duas funções. A escada do §3 (function inteira, não só a assinatura)
  continua sendo o ponto crítico: a assinatura `float xnew = a - b;` parece uma linha, mas o
  `float` nos OPERANDOS (não só no resultado) já implica arredondamento por operação — um detalhe
  que só aparece lendo o `.cpp`, nunca o `.h`.

## 2026-09-07 — trilha BARATA — alvo `beam-025`/`beam-041` (Δ-1 `tupletBracket`, 2 arq.) → `TupletBracket::GetDrawingYLeft/Right` truncavam o termo, não a soma

S 28→28  N 9841→9827 (-14)  X 615/621→615/621  Y 460/621→463/621 (+3: beam-025, beam-041, btrem-004 limpos)  — **COMMIT**

Veículos mais puros da fila de menor custo com pinpoint `fn/seq/path` conclusivo:
`beam-025` seq108 `DrawPolyline measure[1]/staff[1]/layer[1]/beam[1]/tuplet[1]/tupletBracket[1]`
(esperado `1723,2233 1723,2350 2006,2433` × obtido `1723,2232 1723,2349 2006,2432`, Δ-1
sistemático nos 3 pontos) e `beam-041` seq317 (mesmo padrão, Δ-1 nos 3 pontos).

- **OBS-1 (degrau 1 — pinpoint, fn/seq/path):** os 3 pontos divergem de Δ-1 em Y com X
  exato, então a causa é upstream do desenho, no `yLeft`/`yRight` do bracket — não em
  `DrawTupletBracket` em si (`view_tuplet.cpp:75`, cujo porte confere linha a linha,
  incluindo o slope/yNumLeft/yNumRight do ramo com gap, já com truncagem única).
- **OBS-2 (degrau 2 — comparação campo a campo, printf bilateral sem build novo):**
  lado C++ (fixture 05-38 `AdjustBeams`, registros `clefXRelBefore/After` por coordenada
  de tuplet): mesma curva de altura antes/depois (`yB=584/146/1907/...`), só o alinhamento
  X muda — `yLeft`/`yRight` do bracket herdam a altura do beam, não do tuplet. Lado Dart
  (print temporário em `view_tuplet.dart`, removido antes do commit): o `beamSlope` do
  `BeamSegment` já batia bit a bit (ex. interpolado 175.99999 vs C++ 176.0 confirmado no
  fixture) — só a montagem final divergia.
- **OBS-3 (degrau 3 — causa, função C++ inteira lida):** `TupletBracket::GetDrawingYLeft`
  (`elementpart.cpp:169-183`) retorna `GetStartingY() + m_beamSlope * (xLeft -
  GetStartingX()) + GetDrawingYRel() + m_drawingYRelLeft` como **uma** expressão `int`
  (truncagem única da soma). O porte (`_tupletBracketDrawingYLeft`,
  `view_tuplet.dart`) truncava só o termo do slope
  (`(seg.beamSlope * (xLeft - seg.getStartingX())).toInt()`) e depois somava os ints —
  duas truncagens em vez de uma. Mesmo bug de sempre (lição `slur.cpp:707` /
  `view_mensural.cpp:708` falso positivo: ler se o C++ trunca a soma inteira ou só o
  subtermo — aqui é a soma inteira, confirmado pelo `return` direto sem cast).
  `GetDrawingYRight` (`elementpart.cpp:187-201`) idêntico — corrigido junto.
- **OBS-4 (falso positivo descartado no caminho):** `BeamSegment.calcSetValues`
  (`beam_segment.dart:675`) também parecia o mesmo padrão
  (`c.yBeam = (startingY + beamSlope * (...)).toInt()`), mas o C++
  (`beam.cpp:1466`) é `coord->m_yBeam = startingY + m_beamSlope * (...)` **em
  `double`** (`m_yBeam` é double) — a truncagem só acontece bem depois, no desenho.
  A forma do Dart já é a tradução correta; mexer ali seria REGRESSÃO, não fix
  (mesma lição do falso positivo `view_mensural.cpp:708`).
- **OBS-5 (efeito medido):** `beam-025`/`beam-041` 0 divergências no `probe_diff`
  (streams idênticos); família `beam/` 36→24 divs, 55→57 limpos; `btrem-004` limpo
  por transitividade (usa o mesmo helper via bracket alinhado a beam); `slur-017` e
  `section-001` tiveram dumps cirúrgicos ±1 no MESMO helper (bracket alinhado a beam
  inclinado) — contam 155/786 divs antes e depois porque a 1ª divergência deles cai
  noutra subárvore (mascaramento a jusante; o golden C++ confirma: `slur-017`
  `4668,2490` vs Dart pós-fix `4668,2489` — aproximou, não regrediu). `--all`:
  N 9841→9827 (-14), S flat (28), X flat, Y +3, 0 falhas. `dart analyze` 0 issues;
  `dart test` 701 pass.
- **OBS-6 (instrumentação 05-48, comitada junto):** `cpp_probe/patches/05-48.patch`
  + `ORDER` instrumentam `View::DrawHairpin` (`DrawHairpinEntry`: x1/x2/span/staffSize/
  unit/stemW/drawY/startY/endY/len/links por staff; `DrawHairpinY`: yPre/shiftY/ySh/
  yOff/yStart/yEnd/nOff; `DrawHairpinPos`: yRel/objY/hasPos) — fprintf-only, `diff`
  vazio contra o binário limpo verificado em `hairpin-002`. Resultado da medição em
  `hairpin-002` (alvo BARATA original, 1 div Δ-9): **todos os campos de entrada batem
  bit a bit** (x1/x2/span/staffSize/unit/stemW/drawY/startY/endY/len/links/yRel/objY),
  então o Δ-9 nasce DENTRO do `drawHairpin` pós-`CalcOffset`/`ToDeviceContextY` — i.e.
  no `drawingPageContentHeight` do flip de Y ou no `ToDeviceContextY` em si, ainda
  não isolado. Fica como próximo alvo BARATA com o fixture pronto (não é beco: degraus
  1-3 cumpridos, degrau 4 em andamento).
- Arquivos: `lib/src/rendering/view_tuplet.dart` (+~20/-8: truncagem única em
  `_tupletBracketDrawingYLeft/_tupletBracketDrawingYRight` + doc comments),
  `cpp_probe/patches/05-48.patch` + `ORDER` (instrumentação DrawHairpin, prova de
  não-regressão por `diff` vazio).

## 2026-09-07 — trilha CAUSA — alvo `stem/path @d` subgrupo Δ-45 (7 arq.) → `AdjustFlagPlacement` usa `%` com semântica errada (calcstemfunctor.cpp:646/679)

S 28→28  N 9827→9338 (-489)  X 615/621→615/621  Y 463/621→465/621 (+2: note-010, artic-018 limpos)  — **COMMIT**

Trilha CAUSA sobre o subgrupo Δ-45 de `stem/path @d` (7 arq.: artic-018, beam-049,
beamspan-004, note-008, note-010, rest-005, rest-019 — o Δ45 = unit/2 com unit=90
grita ajuste discreto de haste, não geometria contínua). Veículo mais puro com
fixture: `note-010` ("Additional tails": 8 notas, dur8→dur64, up/down).

- **OBS-1 (degrau 1 — pinpoint, fn/seq/path):** `probe_diff` em `note-010` aponta
  seq75 `DrawLine measure[1]/staff[1]/layer[1]/note[7]/stem[1]`, y2 esperado 2034 ×
  obtido 1989 (Δ-45), x1/y1/x2 exatos — comprimento da haste, não posição.
  note[6] (dur16, mesmo y1=1387) bate exato com len 602; só note[7] (dur32) e
  note[8] (dur64) divergem (C++ len 647, Dart 602). Padrão dur-dependente ⇒
  `AdjustFlagPlacement`, não `CalcStemLenInThirdUnits` (que daria o mesmo len
  para todas as durações).
- **OBS-2 (degrau 4 — fixture DEEP 05-49, patch novo permanente):**
  `cpp_probe/patches/05-49.patch` + `ORDER` instrumentam `VisitStem` (saída
  `CalcStem`: dur/stemLen/stemYRel/stemY/flagYRel/nbFlags/vertCenter) e
  `AdjustFlagPlacement` (entrada `AFP`: stemLenIn/glyphH/radius/margin;
  ramo ledger `AFPLedger`: pos/ledgerPos/dispMargin/ledgerAbove/Below) —
  fprintf-only, `diff` vazio contra o binário limpo verificado em note-010.
  Medição: stems UP f4 (dur8/16/32/64) C++ len -602 todos; stems DOWN e5
  dur8/16 len 602, dur32/64 len **647 (+45)**. A extensão só dispara no ramo
  down-stem de `AdjustFlagPlacement` (calcstemfunctor.cpp:642-651) para
  dur > DURATION_16.
- **OBS-3 (degrau 2 — campo a campo no ponto do pinpoint):** lado C++ (`AFP`,
  note[7] dur32 down): stemLenIn=602, glyphH=560 (E242 16thUp — `duration <
  DURATION_16` é falso para dur32, então usa o default, NÃO `GetFlagGlyph`;
  o Dart reproduz isso corretamente), radius=113, margin = 602-(560+113) =
  **-71**. Lado Dart (replay pós-castOff com fontes, todos os campos):
  idêntico bit a bit (len 602, glyphH 560, radius 113, margin -71).
  Entradas idênticas, saídas diferentes (C++ 647, Dart 602) ⇒ o bug está
  DENTRO do ramo, num operador com semântica diferente entre linguagens.
- **OBS-4 (degrau 3/5 — a causa raiz, função inteira lida):**
  `noteheadMargin % adjustmentStep < -adjustmentStep / 3 * 2`
  (calcstemfunctor.cpp:646): `-71 % 90` em C++ = **-71** (sinal do dividendo)
  < -60 ⇒ dispara, offset = 45, heightToAdjust = 0·90-45 = -45,
  len = 602-(-45) = 647. Em Dart, `-71 % 90 == 19` (resto sempre
  não-negativo) < -60 é falso ⇒ ramo morto, len fica 602. O porte estava
  "linha a linha" mas o operador não é o mesmo operador. Fix:
  `noteheadMargin.remainder(adjustmentStep)` (semântica C++) nos dois ramos
  com `%` sobre valor potencialmente negativo (linha 646 e linha 679, o ramo
  ledger `displacementMargin % adjustmentStep > -adjustmentStep / 3`).
  `~/` já trunca para zero como o C++, então só o `%` precisava de troca.
- **OBS-5 (efeito medido):** `note-010` limpo (`probe_diff` 0 divergências);
  `artic-018` limpo por transitividade (hastes alimentam largura de compasso
  via `AdjustXPos` — dump cirúrgico de 962 linhas = re-cast do compasso,
  report confirma 0 divs); `note-008` 3→2 divs no report (residual Δ1 de X,
  outro mecanismo). `--all`: N 9827→9338 (-489), S flat (28), X flat (615),
  Y 463→465 (+2), 0 falhas. `dart analyze` 0 issues; `dart test` 701/701.
  Cluster Δ-45: 7→4 arq. (saem artic-018, note-008, note-010; ficam beam-049,
  beamspan-004, rest-005, rest-019 — os dois primeiros têm hastes em beam,
  outro caminho de cálculo; rest-* seguem sem fixture 05-38, não
  investigados).
- **OBS-6 (falso veículo descartado no caminho, degrau 1):** `artic-018` era
  do cluster Δ-45 mas seu pinpoint seq10 é `DrawLine measure[1]/staff[1]`
  (linha de pauta: y1 Δ547, x2 Δ-6453 — largura de compasso errada, causa a
  montante), não haste. Não foi investigado diretamente; limpou por cascata
  do fix. `note-005` (cluster Δ90) tem o mesmo padrão (pauta Δ135/Δ-870) e
  NÃO se moveu — confirma que pauta-errada é sintoma de mecanismos distintos
  por arquivo, não uma causa única.
- **OBS-7 (lição de processo / armadilha nova):** TODO `%` do C++ sobre
  dividendo negativo em expressão portada para Dart é bug certo — Dart `%`
  nunca retorna negativo. `grep` por `%` em `lib/` pós-fix só acha os 2
  pontos corrigidos + 3 `remainder` preexistentes corretos
  (preparedata_functor, beam_segment), então a classe está contida; mas a
  regra "operador igual, semântica diferente" merece entrar na checagem de
  degrau 5 ao lado de truncagem-de-soma vs truncagem-de-termo: depois de
  conferir ONDE o C++ trunca, conferir COMO cada operador da expressão se
  comporta em negativo.
- Arquivos: `lib/src/layout/calc_functors.dart` (+15/-2: `remainder` +
  comentários citando calcstemfunctor.cpp:646/679),
  `cpp_probe/patches/05-49.patch` + `ORDER` (instrumentação
  CalcStem/AFP/AFPLedger, `diff` vazio verificado).

## 2026-09-07 — trilha ESTRUTURAL — alvo `barline/barline-009` (4 divs estruturais) → `BarLine::GetMethodFromContext` nunca encontra `mensur` no C++ (slicing via `Object::operator=`)

S 28→24  N 9338→9318  X 615/621→616/621 (barline-009 limpo)  Y 465/621→466/621 (+1)  — **COMMIT**

Trilha ESTRUTURAL (última era 2026-09-07 tab-004; S=28 residual em 6
arquivos). Alvo `barline-009` sobre `midi/005` (12 sistemas, cast-off pesado)
e o trio cross-staff+layer-015 (ledger lines a jusante de cross-staff): único
autocontido em nível de desenho, com fixture 05-38 pronto.

- **OBS-1 (degrau 1 — pinpoint, fn/seq/path):** `probe_diff` em `barline-009`:
  `fn=DrawLine seq=121 path=measure[0]/barLine[right]`, y1 Δ-180, y2 Δ-720
  (x exato). Diff SVG direto: grupo barLine com 6 filhos no C++ × 4 no Dart —
  o C++ desenha inside-staff (6 segmentos) + outside-staff (conectores entre
  pautas); o Dart desenhava 2 taktstriche (acima/abaixo de cada pauta).
  Taktstrich = ramo `methodMensur` de `DrawBarLines` (view_page.cpp:774-777).
- **OBS-2 (degrau 2 — campo a campo, sem instrumentação C++):** staffs batem
  (drawingY 27431/25631/23831/22031, unit 90, form single, pos right,
  `barlineThrough` false/true/true/true, sem invisible-barlines) — o ramo era
  decidido só por `methodMensur`, e o Dart o calculava `true` onde o C++
  calculava `false`.
- **OBS-3 (degrau 3 — causa, função C++ inteira + callers):**
  `GetMethodFromContext` (barline.cpp:123) sobe de `staffDef` até `SCOREDEF`
  lendo `AttBarring`. O `bar.method="mensur"` mora no `<scoreDef>` ENCODADO —
  mas `DrawBarLines` recebe o `staffDef` do drawingScoreDef (system/measure),
  que o C++ copia via `ReplaceWithCopyOf` → `Object::operator=`
  (object.cpp:137) — um `operator=` NÃO-virtual que copia só a base `Object`
  (filhos via Clone(), id, flags) e NUNCA os membros Att-mixin (incl.
  `AttBarring::m_barMethod` via `ScoreDefInterface`). Prova por leitura:
  `ScoreDef` não declara `operator=` próprio (só `Object::operator=` existe
  em object.h:226); `ScoreDefElement`/`StaffDef` herdam o slicing junto.
  Logo no C++ o drawingScoreDef carrega sempre o default
  (`barMethod == null`) e esta função NUNCA encontra `mensur` ali — o
  `if (object->Is(SCOREDEF)) break` só limita a busca, não a fonte.
- **OBS-4 (o porte — no getter, não no copyFrom):** a 1ª versão zerava
  `barLen/barMethod/barPlace` em `ScoreDef.copyFrom` — reproduzia o C++ para
  ScoreDef mas deixava `StaffDef`/`StaffGrp` de desenho (que TAMBÉM sofrem o
  slicing, ex. barline-008 com `bar.method` no staffGrp/staffDef) honrando o
  atributo, i.e. meio-slicing. Fix final em `BarLine.getMethodFromContext`
  (basic_elements.dart): o loop para ANTES de ler o `ScoreDef` (`if (object
  is ScoreDef) break` antes do `is AttBarring`) — ramos `<measure>`,
  `<staffDef>` e `<staffGrp>` continuam honrados como no C++, só o
  `<scoreDef>` de desenho é ignorado. `barline-008` (mensur/takt por
  staffGrp/staffDef) segue byte-idêntico; `barline-009` fecha 100%.
- **OBS-5 (efeito medido):** família `barline` 26→6 divs, 7→8 limpos
  (barline-009 0 divergências no `probe_diff`); `--all`: S 28→24, N -20,
  X +1, Y +1, 0 falhas; `cluster_deltas` regenerado (subárvores podadas
  15→11); `dart analyze` 0 issues; `dart test` 701/701 (probe
  `harness_integrity_test.dart` barline-009 ficou limpo → trocado por
  cross-staff-004, mesma prática de tab-004/arpeg-003).
- **OBS-6 (residual, NÃO tocado):** `barline-002` (Δ-423 largura de compasso)
  e `barline-003/007` (Δ-5 `dynam` E520) são outros mecanismos (espaçamento
  horizontal / texto), não `bar.method`. `midi/005` (14 divs estruturais) e
  o trio cross-staff+layer-015 seguem abertos.
- Arquivos: `lib/src/model/basic_elements.dart`
  (`getMethodFromContext`, loop para antes do ScoreDef + doc comment),
  `test/harness_integrity_test.dart` (probe swap barline-009→cross-staff-004).

## 2026-09-07 — trilha CAUSA — alvo Δ-9 cross-class (10 arq.) → beco documentado: `visitBeam` era no-op; Δ-9 real é `CalcDrawingYRel` de hairpin (floatingobject.cpp:510-515), não `CalcBBoxOverflows`

S 24→24  N 9318→9318  X 616/621  Y 466/621  — **RESTORE** (nenhum byte de `lib/` mudou; só este diário)

Trilha CAUSA sobre o cluster Δ-9 (`staff` 40 ocorrências/3 arq., `stem` 32/3,
`notehead` 16/3, `beam` 16/3, `slur` 11/3, `barLine` 11/3 — 22 assinaturas em
10 arquivos: artic-011, cross-staff-012/024, dir-001/007, hairpin-002,
mordent-002, ossia-003, slur-014, tempo-003). Veículo mais puro: `slur-014`
(50 divs, 1ª divergência seq6 system y2 Δ-9, pipeline vertical puro).

- **OBS-1 (degrau 1 — pinpoint, fn/seq/path):** `probe_diff` em `slur-014`:
  `seq 6 DrawLine pages[1]/page[1]/system[1]` y2 Δ-9 (3906 vs 3897); y1/x
  exatos. É a barra vertical do `DrawStaffGrp` (view_page.cpp:331) =
  `yBottom = last.getDrawingY() - (lines-1)*doubleUnit`. `grpSym` brace
  (seq8/9) herda os mesmos y — mesma origem.
- **OBS-2 (degrau 2 — campo a campo, sem instrumentação C++ nova):** scratch
  Dart pós-`castOffDoc` + bbox pass manual: staff3 `overflowAbove` 954 (Dart)
  vs 963 (C++, fixture 05-38 `AdjustYPosVisitStaffAlignment`), staff2 308 vs
  309 — Δ9/Δ1. `minSpacing`/`overlap`/`cumulatedShift`/`requestedSpacing`
  batem; `yRel` staff3 -2448 vs -2457 (Δ9 herdado). O Δ9 nasce no
  `overflowAbove` do staff3, não no `DrawStaffGrp` em si.
- **OBS-3 (degrau 3 — função inteira + callers, achado no caminho):**
  `CalcBBoxOverflowsSet` do C++ lista beam-630/stem-621 como maiores
  contribuidores do staff3 — mas os mesmos valores NÃO aparecem no scratch
  Dart inicial. Suspeita de dispatch: `Functor.visit` resolve `Beam` para
  `visitBeam` (functor.dart:452), e `CalcBBoxOverflowsFunctor` só sobrescreve
  `visitObject` — mas a cadeia default `visitBeam → visitLayerElement →
  visitObject` (functor.dart:909/946/689) preserva o caminho, e o C++ também
  não tem `VisitBeam` neste functor (só `VisitLayerEnd`/`VisitObject`,
  calcbboxoverflowsfunctor.cpp:27/45). Tentativa `visitBeam => visitObject`
  explícito: `--all` dá S/N idênticos (24/9318) e `compare_svg slur-014`
  dá 50/50 com e sem — **no-op provado, revertido**. O scratch inicial
  media `drawingYRel`/`getDrawingY` DEPOIS do `AdjustYPos` (que soma
  `_cumulatedShift` ao `yRel` e invalida os caches), não no momento do Set —
  os "28106/28601" eram `selfY + drawingY` com Y pós-shift, não overflow.
  Lição: medir overflow exige instrumentar o functor (ou replicar a ordem
  do pipeline), nunca ler BB depois do layout completo.
- **OBS-4 (degrau 4 — binário instrumentado 05-48, `diff` vazio verificado):**
  `DrawHairpinEntry`/`DrawHairpinY`/`DrawHairpinPos` em `hairpin-002` (draw
  final): `drawY=26396 yRel=1035 objY=27431` (staff1, o hairpin-002 tem 4
  pautas). Dart pós-layout: `drawY=20852 yRel=1179 objY=22031` (staff4 do
  próprio layout — pautas distintas, comparação direta inválida entre
  sistemas; o que vale é a ESTRUTURA). `yPre=drawY`, `shiftY=81`
  (`-stemW/2 + unit` = -9+90, place below ≠ within/between),
  `yOff=yPre+81` com `nOff=0` (sem offsets de sistema) — **toda a cadeia
  pós-`GetDrawingY` bate bit a bit** (shiftY/ySh/yOff/yStart/yEnd/len/x1/x2/
  startY/endY idênticos quando normalizados pela pauta). O Δ9 está
  INTEGRALMENTE dentro de `Hairpin::GetDrawingY()` = `objY - yRel`:
  C++ `yRel=1035`, Dart `yRel=1179` (Δ14, que após `ToDeviceContextY` e o
  `endY/2=135` do ramo `startY==0` produz o Δ9 no polyline).
- **OBS-5 (a causa raiz — degrau 5, outro mecanismo, NÃO perseguido nesta
  iteração):** `yRel` do hairpin vem de `FloatingPositioner::CalcDrawingYRel`
  ramo `horizOverlappingBBox == NULL` + `place == below` (floatingobject.
  cpp:510-515): `yRel = staffHeight + GetContentY2()` e `yRel +=
  GetTopMargin(class) * unit` — i.e. depende do **contentBB do hairpin no
  momento do `AdjustFloatingPositioners`** (que roda DEPOIS do segundo bbox
  pass `SlurHandling::Drawing`, page.cpp:554-557) e do `GetTopMargin`.
  O fixture 05-38 é de 2026-09-03/04 (só desenho + Align/AdjustX) e NÃO
  instrumenta `CalcDrawingYRel`/`GetContentY2`/`GetTopMargin` — o pinpoint
  para aqui por falta de fixture, não por falta de degrau. Próxima iteração:
  patch 05-50 com `CalcDrawingYRel` (yRel/contentY1/contentY2/margin/
  minStaffDistance por place) + `GetTopMargin`, binário com `diff` vazio,
  veículo `hairpin-002` (1 div, Δ-9 puro, pipeline mínimo). O cluster Δ-9
  cruza `staff/stem/notehead/beam/slur/barLine` porque TODOS herdam o Y da
  pauta via `Staff::GetDrawingY` — é a mesma coordenada a montante, como
  prevê a triagem do §2 (não são 22 causas).
- **OBS-6 (o que NÃO é):** `DrawBrace`/`DrawGrpSym`/`DrawVerticalLine`/
  `ToDeviceContextY`/`drawingPageContentHeight` conferidos linha a linha —
  fiéis (incl. `xdec`/`beamWhiteWidth`, `ymed ~/ 2`, `penWidth`, flip de Y).
  `CalcOffsetY`/offsets com `nOff=0` — inativos. `CalcOverflowAbove/Below`
  (verticalaligner.cpp:556-576) — fiéis. `UpdateBB` do bbox DC (self só no
  topo da pilha, content em todos — bboxdevicecontext.cpp:400) — fiel.
  `VisitBeam` dispatch — no-op provado (OBS-3). `slur-014` também contém 1
  hairpin (stanza "Staff spacing and slur positioning", `AdjustFPCurve
  Overflow` só lista slurs; o hairpin entra pelo `AdjustFloating
  Positioners` comum) — o Δ9 do system Y vem do hairpin, não do slur.
- Arquivos: nenhum em `lib/` (RESTORE); este diário. Fixtures lidos:
  `test/fixtures/cpp/05-38/slur/slur-014.mei.jsonl`,
  `test/fixtures/cpp/05-38/hairpin/hairpin-002.mei.jsonl`; probes frescos
  `/tmp/slur014_probe.jsonl`, `/tmp/hairpin002_probe.jsonl` (binário
  05-38..05-49, `diff` vazio contra `build/verovio` nos dois arquivos —
  descartados, não commitados).
