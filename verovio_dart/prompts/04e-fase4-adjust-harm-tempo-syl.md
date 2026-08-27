# 04e — AdjustHarmGrpsSpacingFunctor + AdjustTempoFunctor + AdjustSylSpacingFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os três ajustes horizontais dirigidos por texto: espaçamento entre grupos de cifras
(`harm`), posicionamento de indicações de andamento (`tempo`) e espaçamento de sílabas de letra
(`syl`/`verse`) — este último via `Page::AdjustSylSpacingByVerse`.

## Pré-condições

Tarefas **04-00** e **04a**–**04d** concluídas.

```bash
ls verovio_dart/test/fixtures/cpp/04d/beam-001.mei.jsonl   # o fixture da 04d existe
cd verovio_dart
ls lib/src/layout/adjust_beams.dart
dart test 2>&1 | tail -1     # verde, ≥ 313
```

## Referência C++

| Arquivo | Linhas | Visits |
|---|---:|---|
| `origin/src/src/adjustharmgrpsspacingfunctor.cpp` | 222 | `VisitHarm`, `VisitMeasureEnd`, `VisitSystem`, `VisitSystemEnd` |
| `origin/src/src/adjusttempofunctor.cpp` | 71 | `VisitSystem`, `VisitTempo` |
| `origin/src/src/adjustsylspacingfunctor.cpp` | 206 | `VisitMeasureEnd`, `VisitStaff`, `VisitSystem`, `VisitSystemEnd`, `VisitVerse` |
| `origin/src/src/page.cpp:756-…` | — | `Page::AdjustSylSpacingByVerse(const IntTree &verseTree, Doc *doc)` — chamada de dentro do `AdjustSylSpacingFunctor` |
| `origin/src/src/page.cpp:396-497` | — | posição dos três na fase horizontal |

Headers correspondentes em `origin/src/include/vrv/` com o mesmo nome.
`AdjustHarmGrpsSpacingFunctor` e `AdjustSylSpacingFunctor` dependem de
`InitProcessingListsFunctor`, que **já existe** em Dart (`lib/src/layout/`) — confirme com
`grep -rn "class InitProcessingListsFunctor" lib/src/`, e veja que estrutura de `IntTree` ele produz.

## Dados de referência do C++

> Convenções em `00-MESTRE.md` §6-bis e `cpp_probe/README.md`. Instrumentação é **só acréscimo**:
> nenhum patch pode remover ou alterar uma linha do C++. Os números de linha abaixo são os da
> árvore **limpa**; com os patches anteriores aplicados eles andam algumas linhas, então localize
> sempre por nome com `grep -n` em `build-probe/src/`.

**Valores a medir**

- `AdjustHarmGrpsSpacingFunctor`: o `drawingXRel` de cada `Harm` antes e depois, o grupo (`@n`) a
  que pertence, e o `m_previousHarmPositioner` / `m_previousHarmStart` / `m_previousMeasure` no
  momento da conta.
- `AdjustTempoFunctor`: o `drawingXRel` de cada `Tempo` antes e depois.
- `AdjustSylSpacingFunctor` + `Page::AdjustSylSpacingByVerse`: o deslocamento acumulado por verso e
  o `drawingXRel` de cada `Syl` antes e depois.
- **A largura de texto que entra em cada conta** — `TextExtend::m_width` de cada rótulo. É aqui que
  a divergência vai estar (ver *Armadilhas conhecidas*), então meça-a explicitamente: sem esse
  número não dá para separar "portei a lógica errada" de "a largura de texto é aproximada".

**Funções a instrumentar**

| Onde | O quê |
|---|---|
| `origin/src/src/adjustharmgrpsspacingfunctor.cpp:35` `VisitHarm` | `drawingXRel` antes/depois, grupo e largura de texto |
| `origin/src/src/adjustharmgrpsspacingfunctor.cpp:156` `VisitMeasureEnd` | o estado acumulado por compasso |
| `origin/src/src/adjustharmgrpsspacingfunctor.cpp:180` `VisitSystemEnd` | **onde o ajuste final acontece** |
| `origin/src/src/adjusttempofunctor.cpp:36` `VisitTempo` | `drawingXRel` antes/depois |
| `origin/src/src/adjustsylspacingfunctor.cpp:95` `VisitVerse` | o que entra no acumulador |
| `origin/src/src/adjustsylspacingfunctor.cpp:69` `VisitSystemEnd` | **onde o ajuste acontece** |
| `origin/src/src/page.cpp:756` `Page::AdjustSylSpacingByVerse` | o deslocamento por verso |
| `origin/src/src/page.cpp:471`, `:476`, `:484` | `probe::BeginPass` para `InitProcessingLists`, `AdjustHarmGrpsSpacing` e `AdjustTempo` |

**Arquivos do corpus** (fixados aqui para o conjunto não variar entre execuções)

| Arquivo | Por quê |
|---|---|
| `test/corpus/harm/harm-001.mei` | cifras — o caso central de `AdjustHarmGrpsSpacing` |
| `test/corpus/tempo/tempo-001.mei` | indicação de andamento — o caso central de `AdjustTempo` |
| `test/corpus/lyric/lyric-001.mei` | **um dos dois arquivos cujo timemap diverge hoje** — o critério de aceite pergunta por ele |
| `test/corpus/lyric/lyric-004.mei` | segundo caso de letra, para não ajustar em cima de um arquivo só |

**Fixtures a gravar**: `test/fixtures/cpp/04e/<nome-do-arquivo>.jsonl`

**Comandos**

```bash
# a partir da RAIZ do workspace, não de verovio_dart/
cpp_probe/sync.sh
# edite build-probe/src/src/{adjustharmgrpsspacingfunctor,adjusttempofunctor,adjustsylspacingfunctor,page}.cpp — só fprintf, nada de lógica
cpp_probe/mkpatch.sh 04e        # grava cpp_probe/patches/04e.patch
cpp_probe/build.sh 04e          # incremental (~1 min) se build-probe/ já existe

for f in harm/harm-001 tempo/tempo-001 lyric/lyric-001 lyric/lyric-004; do
  n=$(basename $f)
  cpp_probe/run.sh 04e "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/04e/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
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

- **Criar** `lib/src/layout/adjust_harm_tempo_syl.dart` — os três functors.
- **Alterar** `lib/src/model/doc.dart` — ligar os três na fase horizontal, depois de
  `InitProcessingLists`, na ordem do `page.cpp`; atualizar os comentários de "skipped" em
  `:297-298` e `:342-344`.
- **Alterar** o arquivo onde vive `Page` (`lib/src/model/system_page_elements.dart`) — acrescentar
  `adjustSylSpacingByVerse`.
- **Criar** `test/adjust_harm_tempo_syl_test.dart`.

## Passo a passo

1. Leia os três `.cpp` e os três `.h`.
2. Leia `Page::AdjustSylSpacingByVerse` em `page.cpp:756` até o fim da função.
3. Confirme a forma do `IntTree` produzido por `InitProcessingListsFunctor` no Dart existente.
3-bis. **Extraia os dados de referência do C++ antes de escrever Dart.** Instrumente com `fprintf` as
   funções listadas em *Dados de referência do C++* e rode os comandos daquela seção. Confira que o
   binário instrumentado ainda produz SVG idêntico ao do limpo. **Leia os fixtures antes de escrever
   a primeira linha de Dart** — eles dizem o que o functor faz de verdade, caso a caso, melhor do
   que a leitura do `.cpp`.
4. Porte os três functors + `Page.adjustSylSpacingByVerse`.
5. Ligue no `doc.dart`.
6. Testes: use **os quatro arquivos fixados** em *Dados de referência do C++*
   (`harm/harm-001.mei`, `tempo/tempo-001.mei`, `lyric/lyric-001.mei`, `lyric/lyric-004.mei`).
   **`lyric/lyric-001.mei` é um dos dois arquivos cujo timemap hoje diverge do C++** — verifique
   se esta tarefa o conserta e registre o resultado no relatório de qualquer jeito.
7. Verificação.

**Protocolo de re-instrumentação — leia antes de "consertar" qualquer número.** Se um valor do Dart
não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao patch, instrumente mais
fundo dentro da função divergente (valores intermediários, o ramo do `if` tomado, o resultado de
cada helper), rode `cpp_probe/mkpatch.sh 04e && cpp_probe/build.sh 04e`, regere o fixture e
compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a divergência
irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
herda o instrumento, não o problema.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 320 testes**
- [ ] `grep -c "^class Adjust" lib/src/layout/adjust_harm_tempo_syl.dart` = 3
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.` e timemaps **≥ 24/30**
- [ ] O relatório diz explicitamente se `lyric/lyric-001.mei` passou de
      `6/10 differ @q=4.50` para `match`, e se não passou, a hipótese de causa
- [ ] `cpp_probe/patches/04e.patch` versionado, contendo **apenas** acréscimos de instrumentação
      (`grep -c '^-[^-]' cpp_probe/patches/04e.patch` = 0) — cole o resumo do `mkpatch.sh` no relatório
- [ ] `cpp_probe/build.sh 04e && cpp_probe/run.sh 04e …` reproduz os fixtures do zero, e o binário
      instrumentado produz SVG idêntico ao do binário limpo para os arquivos desta tarefa
      (`diff` vazio, colado no relatório)
- [ ] N valores do fixture comparados com o Dart em epsilon 0; o relatório traz N, quantos batem, e
      cada divergência restante com hipótese de causa nomeando função e linha do C++
- [ ] Relatório em `prompts/reports/04e.md`
- [ ] `PLANO.md`: os três nomes removidos da lista de faltantes

## Armadilhas conhecidas

- Extensões de texto vêm de `headless_extents.dart:593` e `:658`, que **estimam** com Times a ~60%
  da fonte de música. Os três functors desta tarefa dependem inteiramente de largura de texto, então
  os números **não vão bater** com o C++ até a tarefa 05-12. Isto é esperado: porte a lógica correta
  e documente a divergência numérica.
- `AdjustSylSpacingFunctor` acumula por verso e só age no `VisitSystemEnd`. Ordem de acumulação importa.
- `AdjustHarmGrpsSpacingFunctor` agrupa por `@n` do `harm`; grupos diferentes não interagem.
- `IntTree` não é um `Map` simples — reproduza a estrutura aninhada do C++.

## Fora de escopo

- Consertar `headless_extents.dart` (tarefa 05-12).
- `view_text.cpp` (tarefa 05-19).
- Instrumentar functors de outras tarefas: o seu patch cobre só os desta.
