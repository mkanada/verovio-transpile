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
