# 04f — AdjustXOverflowFunctor + CacheHorizontalLayoutFunctor + CalcSpanningBeamSpansFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar o fim da fase horizontal: tratamento do transbordo em X de elementos de controle no último
compasso do sistema (`AdjustXOverflow`), cache da configuração horizontal para o cast-off
(`CacheHorizontalLayout`) e criação dos segmentos de `beamSpan` que cruzam sistemas
(`CalcSpanningBeamSpans`).

## Pré-condições

Tarefas **04-00** e **04a**–**04e** concluídas.

```bash
ls verovio_dart/test/fixtures/cpp/04e/lyric-001.mei.jsonl   # o fixture da 04e existe
cd verovio_dart
ls lib/src/layout/adjust_harm_tempo_syl.dart
dart test 2>&1 | tail -1     # verde, ≥ 320
```

## Referência C++

| Arquivo | Linhas | Visits |
|---|---:|---|
| `origin/src/src/adjustxoverflowfunctor.cpp` | 121 | `VisitControlElement`, `VisitMeasure`, `VisitSystem`, `VisitSystemEnd` |
| `origin/src/src/cachehorizontallayoutfunctor.cpp` | 52 | `VisitArpeg`, `VisitLayerElement`, `VisitMeasure` |
| `origin/src/src/calcspanningbeamspansfunctor.cpp` | 67 | `VisitBeamSpan` |
| `origin/src/src/page.cpp:396-497` | — | `AdjustXOverflow` e `CacheHorizontalLayout` no fim de `LayOutHorizontally` |
| `origin/src/src/page.cpp:499-507` | — | `Page::LayOutHorizontallyWithCache(bool restore)` — quem consome o cache |

`CacheHorizontalLayoutFunctor` tem um flag `m_restore`: a mesma classe grava e restaura.
Leia o header (`origin/src/include/vrv/cachehorizontallayoutfunctor.h`) antes de portar.

Onde `CalcSpanningBeamSpans` entra: procure com
`grep -rn "CalcSpanningBeamSpans" origin/src/src/*.cpp` — **não** é o `page.cpp`.

## Dados de referência do C++

> Convenções em `00-MESTRE.md` §6-bis e `cpp_probe/README.md`. Instrumentação é **só acréscimo**:
> nenhum patch pode remover ou alterar uma linha do C++. Os números de linha abaixo são os da
> árvore **limpa**; com os patches anteriores aplicados eles andam algumas linhas, então localize
> sempre por nome com `grep -n` em `build-probe/src/`.

**Valores a medir**

- `AdjustXOverflowFunctor`: o `m_currentWidth` acumulado, o `m_lastMeasure` e o
  `m_currentSystem` correntes, e — em `VisitSystemEnd` — **o ajuste final aplicado** ao alinhamento
  da barra de compasso direita, antes e depois.
- `CacheHorizontalLayoutFunctor`: para cada elemento, o par (valor corrente, valor em cache) tanto
  na passada de **gravação** (`m_restore = false`) quanto na de **restauração** (`m_restore = true`).
  Emita `m_restore` em todo registro: é o que separa as duas no fixture.
- `CalcSpanningBeamSpansFunctor`: para cada `BeamSpan`, quantos segmentos foram criados e o primeiro
  e o último elemento de cada segmento.

**Funções a instrumentar**

| Onde | O quê |
|---|---|
| `origin/src/src/adjustxoverflowfunctor.cpp:33` `VisitControlElement` | o candidato a maior transbordo e a largura que ele impõe |
| `origin/src/src/adjustxoverflowfunctor.cpp:88` `VisitSystemEnd` | **onde a conta acontece**: o ajuste antes/depois |
| `origin/src/src/cachehorizontallayoutfunctor.cpp:27` `VisitArpeg` | valor corrente e em cache, com `m_restore` |
| `origin/src/src/cachehorizontallayoutfunctor.cpp:34` `VisitLayerElement` | idem |
| `origin/src/src/cachehorizontallayoutfunctor.cpp:42` `VisitMeasure` | idem |
| `origin/src/src/calcspanningbeamspansfunctor.cpp:24` `VisitBeamSpan` | número de segmentos e extremos de cada um |
| `origin/src/src/page.cpp:492`, `:506`, `:393` | `probe::BeginPass` para `AdjustXOverflow`, `CacheHorizontalLayout` e `CalcSpanningBeamSpans` (este último **não** está em `LayOutHorizontally` — confirme com `grep -rn "CalcSpanningBeamSpans" origin/src/src/*.cpp`) |

**Arquivos do corpus** (fixados aqui para o conjunto não variar entre execuções)

| Arquivo | Por quê |
|---|---|
| `test/corpus/section/section-001.mei` | **20 compassos, 4 páginas — o caso de cast-off mais pesado do corpus validado, e o segundo arquivo cujo timemap diverge hoje**. É quem exercita o cache. |
| `test/corpus/beamspan/beamspan-001.mei` | `beamSpan` cruzando sistema — o caso de `CalcSpanningBeamSpans` |
| `test/corpus/dir/dir-001.mei` | elemento de controle textual no fim do sistema — transbordo em X |
| `test/corpus/dynam/dynam-001.mei` | segundo caso de transbordo, com dinâmica |

**Fixtures a gravar**: `test/fixtures/cpp/04f/<nome-do-arquivo>.jsonl`

**Comandos**

```bash
# a partir da RAIZ do workspace, não de verovio_dart/
cpp_probe/sync.sh
# edite build-probe/src/src/{adjustxoverflowfunctor,cachehorizontallayoutfunctor,calcspanningbeamspansfunctor,page}.cpp — só fprintf, nada de lógica
cpp_probe/mkpatch.sh 04f        # grava cpp_probe/patches/04f.patch
cpp_probe/build.sh 04f          # incremental (~1 min) se build-probe/ já existe

for f in section/section-001 beamspan/beamspan-001 dir/dir-001 dynam/dynam-001; do
  n=$(basename $f)
  cpp_probe/run.sh 04f "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/04f/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
  build/verovio -r verovio_dart/assets/data -x 12345 -o "/tmp/limpo-$n.svg" \
      "verovio_dart/test/corpus/$f.mei" >/dev/null
  diff "/tmp/limpo-$n.svg" "/tmp/probe-$n.svg" && echo "SVG idêntico: $n"
done
```

O id da sua tarefa **já está** em `cpp_probe/patches/ORDER`, na posição certa; `patch.sh --list`
mostra a pilha. `build.sh` para com mensagem clara se o patch de alguma tarefa anterior faltar —
isso quer dizer que aquela tarefa não rodou, não que algo quebrou.

Os `diff` têm de sair **vazios**. Se algum divergir, o patch tem lógica onde deveria
ter só `fprintf` — conserte antes de escrever qualquer Dart.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/adjust_x_overflow.dart` — `AdjustXOverflowFunctor`.
- **Criar** `lib/src/layout/cache_horizontal_layout.dart` — `CacheHorizontalLayoutFunctor`
  e o método `Page.layOutHorizontallyWithCache`.
- **Criar** `lib/src/layout/calc_spanning_beam_spans.dart` — `CalcSpanningBeamSpansFunctor`.
- **Alterar** `lib/src/model/doc.dart` e `lib/src/model/system_page_elements.dart`.
- **Alterar** `lib/src/layout/align_horizontally.dart:187` — o `TODO(phase-4/5)` sobre segmentos de
  `beamSpan` é exatamente o que `CalcSpanningBeamSpans` resolve; atualize ou remova o comentário.
- **Criar** `test/adjust_x_overflow_test.dart`.

## Passo a passo

1. Leia os três `.cpp` e os três `.h`.
2. Leia `Page::LayOutHorizontallyWithCache` e descubra quem a chama
   (`grep -rn "LayOutHorizontallyWithCache" origin/src/src/`).
3. Descubra quem chama `CalcSpanningBeamSpansFunctor` no C++ e reproduza esse ponto, não invente outro.
3-bis. **Extraia os dados de referência do C++ antes de escrever Dart.** Instrumente com `fprintf` as
   funções listadas em *Dados de referência do C++* e rode os comandos daquela seção. Confira que o
   binário instrumentado ainda produz SVG idêntico ao do limpo. **Leia os fixtures antes de escrever
   a primeira linha de Dart** — eles dizem o que o functor faz de verdade, caso a caso, melhor do
   que a leitura do `.cpp`.
4. Porte os três.
5. Ligue no `doc.dart` / `system_page_elements.dart`.
6. Testes: use **os quatro arquivos fixados** em *Dados de referência do C++* —
   `beamspan/beamspan-001.mei` para `CalcSpanningBeamSpans`, `dir/dir-001.mei` e
   `dynam/dynam-001.mei` para o transbordo em X, e `section/section-001.mei` (20 compassos,
   4 páginas) para o cache.
7. Verificação.

**Protocolo de re-instrumentação — leia antes de "consertar" qualquer número.** Se um valor do Dart
não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao patch, instrumente mais
fundo dentro da função divergente (valores intermediários, o ramo do `if` tomado, o resultado de
cada helper), rode `cpp_probe/mkpatch.sh 04f && cpp_probe/build.sh 04f`, regere o fixture e
compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a divergência
irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
herda o instrumento, não o problema.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 326 testes**
- [ ] Os três arquivos novos existem e cada um contém exatamente 1 `class …Functor`
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.` e timemaps **≥ 24/30**
- [ ] O relatório diz se `section/section-001.mei` passou de `10/20 differ @q=25.00` para `match`,
      e se não, a hipótese de causa
- [ ] `cpp_probe/patches/04f.patch` versionado, contendo **apenas** acréscimos de instrumentação
      (`grep -c '^-[^-]' cpp_probe/patches/04f.patch` = 0) — cole o resumo do `mkpatch.sh` no relatório
- [ ] `cpp_probe/build.sh 04f && cpp_probe/run.sh 04f …` reproduz os fixtures do zero, e o binário
      instrumentado produz SVG idêntico ao do binário limpo para os arquivos desta tarefa
      (`diff` vazio, colado no relatório)
- [ ] N valores do fixture comparados com o Dart em epsilon 0; o relatório traz N, quantos batem, e
      cada divergência restante com hipótese de causa nomeando função e linha do C++
- [ ] Relatório em `prompts/reports/04f.md`
- [ ] `PLANO.md`: os três nomes removidos da lista de faltantes

## Armadilhas conhecidas

- `CacheHorizontalLayoutFunctor` com `m_restore = true` **restaura**; com `false`, **grava**.
  Trocar os dois produz um layout que parece funcionar e erra no cast-off.
- `AdjustXOverflowFunctor` só age no último compasso do sistema — `VisitSystemEnd` é onde a conta
  acontece, `VisitControlElement` só acumula o candidato de maior transbordo.
- `section/section-001.mei` diverge hoje em timemap com 4 páginas e 20 sistemas: é o caso de cast-off
  mais pesado do corpus validado. Se esta tarefa não o consertar, a suspeita seguinte é o cast-off,
  não estes três functors.

## Fora de escopo

- Reescrever `cast_off.dart` (já portado).
- `CastOffToSelectionFunctor` (tarefa 06-12, depende de selection).
- Instrumentar functors de outras tarefas: o seu patch cobre só os desta.
