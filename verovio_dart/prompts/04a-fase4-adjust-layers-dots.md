# 04a — AdjustLayersFunctor + AdjustDotsFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `AdjustLayersFunctor` e `AdjustDotsFunctor`, os dois primeiros ajustes horizontais que
o C++ roda em `Page::LayOutHorizontally` e que hoje estão pulados no Dart. Ao final, notas de
camadas diferentes que colidem no mesmo alinhamento são deslocadas em X, e os pontos de aumento
de camadas sobrepostas são desempilhados — como no C++.

## Pré-condições

Tarefa **04-00** concluída (a base numérica: fator de definição e tempos de alinhamento).
Confirme em 30 s:

```bash
ls cpp_probe/build.sh verovio_dart/test/fixtures/cpp_fixture.dart   # a infra de extração existe
ls verovio_dart/test/fixtures/cpp/04-00/                            # os fixtures da 04-00
cd verovio_dart
dart test 2>&1 | tail -1          # esperado: "All tests passed!" com ≥ 287
grep -c "definitionFactor" lib/src/core/options_shell.dart   # esperado: ≥ 1 (a 04-00 rodou)
grep -c "class AdjustLayersFunctor\|class AdjustDotsFunctor" lib/src/layout/*.dart
                                   # esperado: 0 (nenhum arquivo casa)
```

## Referência C++

| Arquivo | Conteúdo |
|---|---|
| `origin/src/include/vrv/adjustlayersfunctor.h` | `class AdjustLayersFunctor`. Estado: `m_staffNs`, `m_currentLayerN`, `m_previous`, `m_current`, `m_unison`, `m_ignoreDots`, `m_stemSameas`, `m_accumulatedShift`. |
| `origin/src/src/adjustlayersfunctor.cpp` (155 linhas) | `VisitAlignmentReference`, `VisitAlignmentReferenceEnd`, `VisitLayerElement`, `VisitMeasure`, `VisitSystem`. |
| `origin/src/include/vrv/adjustdotsfunctor.h` | `class AdjustDotsFunctor`. Estado: `m_staffNs`, `m_elements`, `m_dots`. |
| `origin/src/src/adjustdotsfunctor.cpp` (130 linhas) | `VisitAlignmentEnd`, `VisitLayerElement`, `VisitMeasure`, `VisitSystem`. |
| `origin/src/src/page.cpp:396-497` | `Page::LayOutHorizontally` — a ordem exata em que os dois entram. |

Atenção à ordem no C++ (`page.cpp`): `AdjustLayers` roda **duas vezes** —
uma antes de `AdjustDots` (`adjustLayers`, com `m_ignoreDots = true`) e uma depois
(`adjustLayersWithDots`, com `m_ignoreDots = false`). Reproduza as duas passadas e os dois valores.

Métodos de apoio que os dois functors chamam e que já existem em Dart — confirme a assinatura antes
de usar, não invente: `LayerElement::GetSelfBottom/GetSelfTop`, `Object::HorizontalContentOverlap`,
`Alignment::GetReferences`, `AlignmentReference::GetChildren`, `Staff::GetN`.

## Dados de referência do C++

> Convenções em `00-MESTRE.md` §6-bis e `cpp_probe/README.md`. Instrumentação é **só acréscimo**:
> nenhum patch pode remover ou alterar uma linha do C++. Os números de linha abaixo são os da
> árvore **limpa**; com os patches anteriores aplicados eles andam algumas linhas, então localize
> sempre por nome com `grep -n` em `build-probe/src/`.

**Valores a medir**

- `AdjustLayersFunctor`: para cada `LayerElement` que o functor toca, o `drawingXRel` **antes e
  depois**; e, em `VisitAlignmentReferenceEnd`, o `m_accumulatedShift` da referência. Emita o
  `m_ignoreDots` corrente em cada registro — as duas passadas se distinguem por ele.
- `AdjustDotsFunctor`: para cada `Dots` em `VisitAlignmentEnd`, o `drawingXRel` antes e depois, mais
  o tamanho de `m_dots` e de `m_elements` no momento em que a conta acontece.

**Funções a instrumentar**

| Onde | O quê |
|---|---|
| `origin/src/src/adjustlayersfunctor.cpp:33` `VisitAlignmentReference` | o estado de entrada da referência |
| `origin/src/src/adjustlayersfunctor.cpp:45` `VisitAlignmentReferenceEnd` | **onde o deslocamento acontece**: `m_accumulatedShift` e o `drawingXRel` de cada elemento deslocado |
| `origin/src/src/adjustlayersfunctor.cpp:90` `VisitLayerElement` | o elemento acumulado e o ramo tomado sob `m_ignoreDots` |
| `origin/src/src/adjustdotsfunctor.cpp:27` `VisitAlignmentEnd` | **onde a conta acontece**: `drawingXRel` de cada `Dots` antes/depois |
| `origin/src/src/adjustdotsfunctor.cpp:84` `VisitLayerElement` | o que entra em `m_elements` / `m_dots` |
| `origin/src/src/page.cpp:426`, `:431`, `:440` | `probe::BeginPass("AdjustLayers")` antes de `:426` e de `:440`, e `probe::BeginPass("AdjustDots")` antes de `:431` — é o que separa as duas passadas de `AdjustLayers` no fixture |

**Arquivos do corpus** (fixados aqui para o conjunto não variar entre execuções)

| Arquivo | Por quê |
|---|---|
| `test/corpus/layer/layer-001.mei` | camadas colidindo — o caso central de `AdjustLayers` (14 notas, 3 acordes, 1 compasso) |
| `test/corpus/dot/dot-001.mei` | pontos de aumento empilhados — o caso central de `AdjustDots` (3 compassos, 49 notas) |

**Fixtures a gravar**: `test/fixtures/cpp/04a/<nome-do-arquivo>.jsonl`

**Comandos**

```bash
# a partir da RAIZ do workspace, não de verovio_dart/
cpp_probe/sync.sh
# edite build-probe/src/src/{adjustlayersfunctor,adjustdotsfunctor,page}.cpp — só fprintf, nada de lógica
cpp_probe/mkpatch.sh 04a        # grava cpp_probe/patches/04a.patch
cpp_probe/build.sh 04a          # incremental (~1 min) se build-probe/ já existe

for f in layer/layer-001 dot/dot-001; do
  n=$(basename $f)
  cpp_probe/run.sh 04a "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/04a/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
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

- **Criar** `lib/src/layout/adjust_layers.dart` — `AdjustLayersFunctor`, `AdjustDotsFunctor`
  (os dois cabem num arquivo: são o mesmo passo do pipeline e compartilham a coleta de `staffNs`).
- **Alterar** `lib/src/model/doc.dart` — inserir as chamadas na fase horizontal, na ordem do
  `page.cpp`, e **remover das listas de "skipped"** os nomes `AdjustLayers` e `AdjustDots` nos
  comentários das linhas 296-299 e 312.
- **Criar** `test/adjust_layers_test.dart`.

Nenhuma classe de elemento nova → nada a mexer em `factory_registry.dart`, `vrvdef.dart`
ou `kAcceptChain`.

## Passo a passo

1. Leia `adjustlayersfunctor.h` e `.cpp` inteiros. Anote cada campo de estado e o que o zera.
2. Leia `adjustdotsfunctor.h` e `.cpp` inteiros.
3. Leia `page.cpp:396-497` e anote a ordem e os argumentos do construtor de cada functor.
3-bis. **Extraia os dados de referência do C++ antes de escrever Dart.** Instrumente com `fprintf` as
   funções listadas em *Dados de referência do C++* e rode os comandos daquela seção. Confira que
   o binário instrumentado ainda produz SVG idêntico ao do limpo. **Leia os fixtures antes de
   escrever a primeira linha de Dart** — eles dizem o que o functor faz de verdade, caso a caso,
   melhor do que a leitura do `.cpp`.
4. Crie `adjust_layers.dart` com os dois functors, estendendo `DocFunctor`
   (`lib/src/layout/functor.dart:1102`). Cada `VisitXxx` do C++ vira `visitXxx` em Dart.
   Doc comment em cada classe e cada método citando o C++.
5. Ligue no `doc.dart`, na posição exata do `page.cpp`. Atualize os comentários de "skipped".
6. Escreva os testes: para cada functor, um caso mínimo de MEI de `test/corpus/` que exercite o
   deslocamento (sugestões: `test/corpus/layer/layer-001.mei` para camadas, `test/corpus/dot/dot-001.mei`
   para pontos) e asserções sobre `drawingXRel` dos elementos afetados.
   Lembre de `Resources.defaultPath = 'assets/data';` e `registerModelClasses()` no `setUpAll`.
7. Rode a verificação.

**Protocolo de re-instrumentação — leia antes de "consertar" qualquer número.** Se um valor do Dart
não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao patch, instrumente mais
fundo dentro da função divergente (valores intermediários, o ramo do `if` tomado, o resultado de
cada helper), rode `cpp_probe/mkpatch.sh 04a && cpp_probe/build.sh 04a`, regere o fixture e
compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a divergência
irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
herda o instrumento, não o problema.

## Critérios de aceite

- [ ] `dart analyze` reporta no máximo `10 issues found.`
- [ ] `dart test` verde, com **≥ 293 testes**
- [ ] `grep -c "class AdjustLayersFunctor" lib/src/layout/adjust_layers.dart` = 1 e
      `grep -c "class AdjustDotsFunctor" lib/src/layout/adjust_layers.dart` = 1
- [ ] `dart run tool/validate_layout.dart` roda até o fim, `tool/LAYOUT_VALIDATION.md` continua com
      `Check notes: None. All structural assertions passed.` e a contagem de timemaps
      **não regride abaixo de 24/30**
- [ ] `cpp_probe/patches/04a.patch` versionado, contendo **apenas** acréscimos de instrumentação
      (`grep -c '^-[^-]' cpp_probe/patches/04a.patch` = 0) — cole o resumo do `mkpatch.sh` no relatório
- [ ] `cpp_probe/build.sh 04a && cpp_probe/run.sh 04a …` reproduz os fixtures do zero, e o binário
      instrumentado produz SVG idêntico ao do binário limpo para os arquivos desta tarefa
      (`diff` vazio, colado no relatório)
- [ ] N valores do fixture comparados com o Dart em epsilon 0; o relatório traz N, quantos batem, e
      cada divergência restante com hipótese de causa nomeando função e linha do C++
- [ ] Relatório gravado em `prompts/reports/04a.md`
- [ ] No `PLANO.md`, na Fase 4, os nomes `AdjustLayers` e `AdjustDots` removidos da linha de
      functors faltantes

## Armadilhas conhecidas

- **As duas passadas de `AdjustLayers`.** Rodar só uma dá resultado quase certo e errado.
- `m_ignoreDots` muda o comportamento de `VisitLayerElement`; não é um flag decorativo.
- A ordem dentro de `VisitAlignmentReference` importa: o C++ compara pares consecutivos, não
  todos contra todos.
- O `AdjustDotsFunctor` acumula em `m_elements` e `m_dots` e só age em `VisitAlignmentEnd`.
  Zerar as listas no lugar errado dá deslocamento cumulativo entre alinhamentos.
- Divisão inteira: o C++ calcula deslocamentos em `int` (unidades de `drawingUnit`). Use `~/`, não `/`.

## Fora de escopo

- `AdjustAccidX` (tarefa 04b) e `AdjustNeumeX` (tarefa 04g), mesmo que o `page.cpp` os mostre por perto.
- Qualquer mexida em `headless_extents.dart` — as bboxes continuam aproximadas até a tarefa 05-12.
- Consertar os registros errados do `ObjectFactory` (tarefa 04i).
- Instrumentar functors de outras tarefas: o seu patch cobre só os desta.
