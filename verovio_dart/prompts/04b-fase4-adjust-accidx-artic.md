# 04b — AdjustAccidXFunctor + AdjustArticFunctor + AdjustArticWithSlursFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar o desempilhamento horizontal de acidentes (`AdjustAccidX`) e o posicionamento vertical de
articulações fora do pentagrama (`AdjustArtic` e `AdjustArticWithSlurs`). Ao final, acidentes
sobrepostos deixam de colidir e articulações externas ficam acima/abaixo do que já ocupa o lugar.

## Pré-condições

Tarefas **04-00** e **04a** concluídas.

```bash
ls verovio_dart/test/fixtures/cpp/04a/layer-001.mei.jsonl   # o fixture da 04a existe
cd verovio_dart
ls lib/src/layout/adjust_layers.dart    # tem de existir
dart test 2>&1 | tail -1                # "All tests passed!", ≥ 293
```

## Referência C++

| Arquivo | Conteúdo |
|---|---|
| `origin/src/include/vrv/adjustaccidxfunctor.h` | `class AdjustAccidXFunctor`, estado `m_adjustedAccids`. |
| `origin/src/src/adjustaccidxfunctor.cpp` (198 linhas) | `VisitAlignment`, `VisitAlignmentReference`, `VisitMeasure`. |
| `origin/src/include/vrv/adjustarticfunctor.h` | `class AdjustArticFunctor` e `class AdjustArticWithSlursFunctor`, estado `m_articAbove`, `m_articBelow`. |
| `origin/src/src/adjustarticfunctor.cpp` (177 linhas) | `VisitArtic`, `VisitChord`, `VisitNote` (AdjustArtic) e `VisitArtic` (AdjustArticWithSlurs). |
| `origin/src/src/page.cpp:396-497` | posição de `AdjustArtic` e `AdjustAccidX` na fase horizontal. |
| `origin/src/src/page.cpp:509-608` | posição de `AdjustArticWithSlurs` na fase vertical (roda **depois** do `BBoxDeviceContext` da linha 532). |

`AdjustAccidXFunctor` usa `Accid::AdjustX` (`origin/src/src/accid.cpp`) — leia essa função também;
ela é o coração do algoritmo e é recursiva.

## Dados de referência do C++

> Convenções em `00-MESTRE.md` §6-bis e `cpp_probe/README.md`. Instrumentação é **só acréscimo**:
> nenhum patch pode remover ou alterar uma linha do C++. Os números de linha abaixo são os da
> árvore **limpa**; com os patches anteriores aplicados eles andam algumas linhas, então localize
> sempre por nome com `grep -n` em `build-probe/src/`.

**Valores a medir**

- `AdjustAccidXFunctor`: para cada `Accid`, o `drawingXRel` **antes e depois**, e o **retorno** de
  `Accid::AdjustX` (o número de acidentes ajustados) a cada chamada — o functor usa esse retorno
  para decidir se continua, então portar só o efeito não basta.
- `AdjustArticFunctor`: para cada `Artic`, o `drawingYRel` antes e depois, mais o `m_articAbove` /
  `m_articBelow` corrente e o `place` calculado.
- `AdjustArticWithSlursFunctor`: o `drawingYRel` do `Artic` antes e depois, e o deslocamento vindo
  do posicionador de slur.

**Funções a instrumentar**

| Onde | O quê |
|---|---|
| `origin/src/src/adjustaccidxfunctor.cpp:37` `VisitAlignmentReference` | **onde o algoritmo mora**: o `drawingXRel` de cada `Accid` antes/depois e o retorno de cada `Accid::AdjustX` |
| `origin/src/src/adjustaccidxfunctor.cpp:181` `AdjustAccidWithSpace` | o espaço encontrado e o deslocamento aplicado |
| `origin/src/src/accid.cpp` `Accid::AdjustX` (ache com `grep -n "Accid::AdjustX" origin/src/src/accid.cpp`) | é **recursiva**: emita a profundidade, o retorno e o `drawingXRel` a cada nível |
| `origin/src/src/adjustarticfunctor.cpp:30` `VisitArtic` | `drawingYRel` antes/depois e o ramo tomado |
| `origin/src/src/adjustarticfunctor.cpp:156` `AdjustArticWithSlursFunctor::VisitArtic` | idem, na fase vertical |
| `origin/src/src/page.cpp:420`, `:444`, `:540` | `probe::BeginPass` para `AdjustArtic`, `AdjustAccidX` e `AdjustArticWithSlurs` |

**Arquivos do corpus** (fixados aqui para o conjunto não variar entre execuções)

| Arquivo | Por quê |
|---|---|
| `test/corpus/accid/accid-001.mei` | acidentes empilhados — o caso central de `AdjustAccidX` |
| `test/corpus/artic/artic-001.mei` | articulações dentro e fora do pentagrama |

**Fixtures a gravar**: `test/fixtures/cpp/04b/<nome-do-arquivo>.jsonl`

**Comandos**

```bash
# a partir da RAIZ do workspace, não de verovio_dart/
cpp_probe/sync.sh
# edite build-probe/src/src/{adjustaccidxfunctor,adjustarticfunctor,accid,page}.cpp — só fprintf, nada de lógica
cpp_probe/mkpatch.sh 04b        # grava cpp_probe/patches/04b.patch
cpp_probe/build.sh 04b          # incremental (~1 min) se build-probe/ já existe

for f in accid/accid-001 artic/artic-001; do
  n=$(basename $f)
  cpp_probe/run.sh 04b "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/04b/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
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

- **Criar** `lib/src/layout/adjust_accid_x.dart` — `AdjustAccidXFunctor`.
- **Criar** `lib/src/layout/adjust_artic.dart` — `AdjustArticFunctor` e `AdjustArticWithSlursFunctor`.
- **Alterar** `lib/src/model/basic_elements.dart` ou o arquivo onde vive `Accid` — acrescentar
  `adjustX` se ainda não existir (`grep -n "adjustX" lib/src/model/*.dart` antes).
- **Alterar** `lib/src/model/doc.dart` — ligar os três na ordem do `page.cpp`; atualizar os
  comentários de "skipped" das linhas 296-299, 461-462 e 505.
- **Criar** `test/adjust_accid_artic_test.dart`.

## Passo a passo

1. Leia os dois headers e os dois `.cpp` inteiros, mais `Accid::AdjustX` em `origin/src/src/accid.cpp`.
2. Confirme com `grep -n "adjustX\|AdjustX" lib/src/model/` se `Accid.adjustX` já existe em Dart.
   Se não, porte-a junto, no arquivo onde `Accid` vive.
2-bis. **Extraia os dados de referência do C++ antes de escrever Dart.** Instrumente com `fprintf` as
   funções listadas em *Dados de referência do C++* e rode os comandos daquela seção. Confira que o
   binário instrumentado ainda produz SVG idêntico ao do limpo. **Leia os fixtures antes de escrever
   a primeira linha de Dart** — eles dizem o que o functor faz de verdade, caso a caso, melhor do
   que a leitura do `.cpp`.
3. Porte `AdjustAccidXFunctor` em `adjust_accid_x.dart`.
4. Porte `AdjustArticFunctor` e `AdjustArticWithSlursFunctor` em `adjust_artic.dart`.
   Note que `AdjustArticWithSlursFunctor` depende dos posicionadores de slur já criados pela
   fase vertical — ligue-o **depois** de `AdjustSlursFunctor`, exatamente como o `page.cpp`.
5. Ligue os três no `doc.dart` e atualize os comentários de "skipped".
6. Testes: `test/corpus/accid/accid-001.mei` (acidentes empilhados) e
   `test/corpus/artic/artic-001.mei` (articulações). Asserte `drawingXRel` dos acidentes e
   `drawingYRel` das articulações.
7. Verificação.

**Protocolo de re-instrumentação — leia antes de "consertar" qualquer número.** Se um valor do Dart
não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao patch, instrumente mais
fundo dentro da função divergente (valores intermediários, o ramo do `if` tomado, o resultado de
cada helper), rode `cpp_probe/mkpatch.sh 04b && cpp_probe/build.sh 04b`, regere o fixture e
compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a divergência
irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
herda o instrumento, não o problema.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 300 testes**
- [ ] `grep -l "class AdjustAccidXFunctor" lib/src/layout/adjust_accid_x.dart` casa, e
      `grep -c "class AdjustArtic" lib/src/layout/adjust_artic.dart` = 2
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.` e timemaps **≥ 24/30**
- [ ] `cpp_probe/patches/04b.patch` versionado, contendo **apenas** acréscimos de instrumentação
      (`grep -c '^-[^-]' cpp_probe/patches/04b.patch` = 0) — cole o resumo do `mkpatch.sh` no relatório
- [ ] `cpp_probe/build.sh 04b && cpp_probe/run.sh 04b …` reproduz os fixtures do zero, e o binário
      instrumentado produz SVG idêntico ao do binário limpo para os arquivos desta tarefa
      (`diff` vazio, colado no relatório)
- [ ] N valores do fixture comparados com o Dart em epsilon 0; o relatório traz N, quantos batem, e
      cada divergência restante com hipótese de causa nomeando função e linha do C++
- [ ] Relatório em `prompts/reports/04b.md`
- [ ] `PLANO.md`: `AdjustArtic`, `AdjustArticWithSlurs` e `AdjustAccidX` removidos da lista de faltantes

## Armadilhas conhecidas

- `Accid::AdjustX` é recursiva e devolve o número de acidentes ajustados; o functor usa esse retorno
  para decidir se continua. Porte o retorno, não só o efeito.
- `m_adjustedAccids` é limpo em `VisitAlignment`, não em `VisitMeasure`. Limpar no lugar errado faz
  acidentes de compassos diferentes interferirem.
- `AdjustArticWithSlursFunctor` **precisa** de posicionadores de slur; rodá-lo antes da fase vertical
  não faz nada e o teste passa em falso. Confira que ele roda depois de `AdjustSlursFunctor`.
- As bboxes de `Artic` hoje vêm de `headless_extents.dart:291` (caixa de 1 unidade, aproximada).
  **Isto vai fazer os números não baterem exatamente com o C++, e é esperado nesta tarefa.**
  Registre a divergência no relatório e siga — ela morre na tarefa 05-12.

## Fora de escopo

- Corrigir a aproximação de bbox de `Artic` em `headless_extents.dart`.
- `AdjustTuplets*` (tarefa 04c).
- Instrumentar functors de outras tarefas: o seu patch cobre só os desta.
