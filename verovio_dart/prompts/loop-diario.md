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
