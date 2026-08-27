# 04c — AdjustTupletsXFunctor + AdjustTupletsYFunctor + AdjustTupletNumOverlapFunctor + AdjustTupletWithSlursFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar a família inteira de ajuste de quiálteras: posicionamento X do colchete e do número,
posicionamento Y contra as notas, detecção de sobreposição do número e ajuste contra ligaduras.

## Pré-condições

Tarefas **04-00**, **04a** e **04b** concluídas.

```bash
ls verovio_dart/test/fixtures/cpp/04b/accid-001.mei.jsonl   # o fixture da 04b existe
cd verovio_dart
ls lib/src/layout/adjust_artic.dart lib/src/layout/adjust_accid_x.dart
dart test 2>&1 | tail -1     # verde, ≥ 300
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/include/vrv/adjusttupletsxfunctor.h` | — | `class AdjustTupletsXFunctor`, só `VisitTuplet`. |
| `origin/src/src/adjusttupletsxfunctor.cpp` | 107 | `AdjustTupletsXFunctor::VisitTuplet`. |
| `origin/src/include/vrv/adjusttupletsyfunctor.h` | — | `class AdjustTupletsYFunctor` (`VisitTuplet`), `class AdjustTupletNumOverlapFunctor` (`VisitLayerElement`), `class AdjustTupletWithSlursFunctor` (`VisitTuplet`). |
| `origin/src/src/adjusttupletsyfunctor.cpp` | 429 | os três functors. |
| `origin/src/src/page.cpp:396-497` | — | `AdjustTupletsX` na fase horizontal. |
| `origin/src/src/page.cpp:509-608` | — | `AdjustTupletsY` e `AdjustTupletWithSlurs` na fase vertical. |

`AdjustTupletNumOverlapFunctor` **não é chamado pelo `page.cpp`**: quem o instancia é
`AdjustTupletsYFunctor`, por dentro. Procure a chamada no `.cpp` antes de ligar qualquer coisa.

As classes de desenho `TupletBracket` e `TupletNum` já existem em Dart
(`lib/src/model/layer_elements_gen.dart`) — confirme os campos disponíveis com
`grep -n "class TupletBracket" -A 40 lib/src/model/layer_elements_gen.dart`.

## Dados de referência do C++

> Convenções em `00-MESTRE.md` §6-bis e `cpp_probe/README.md`. Instrumentação é **só acréscimo**:
> nenhum patch pode remover ou alterar uma linha do C++. Os números de linha abaixo são os da
> árvore **limpa**; com os patches anteriores aplicados eles andam algumas linhas, então localize
> sempre por nome com `grep -n` em `build-probe/src/`.

**Valores a medir**

- `AdjustTupletsXFunctor`: `drawingXRel` de `TupletBracket` e de `TupletNum`, antes e depois.
- `AdjustTupletsYFunctor`: `drawingYRel` dos dois, antes e depois, mais o retorno de
  `CalcBracketShift` e a profundidade de aninhamento da quiáltera.
- `AdjustTupletNumOverlapFunctor`: **o valor que ele devolve** (a posição livre encontrada) e o
  `m_horizontalMargin` / `m_verticalMargin` com que foi instanciado — ele é criado **dentro** do
  `AdjustTupletsYFunctor`, não pelo `page.cpp`.
- `AdjustTupletWithSlursFunctor`: `drawingYRel` antes e depois, e o deslocamento vindo do slur.

**Funções a instrumentar**

| Onde | O quê |
|---|---|
| `origin/src/src/adjusttupletsxfunctor.cpp:25` `VisitTuplet` | `drawingXRel` de bracket e num, antes/depois |
| `origin/src/src/adjusttupletsyfunctor.cpp:30` `VisitTuplet` | o ponto de entrada e a profundidade |
| `origin/src/src/adjusttupletsyfunctor.cpp:59` `AdjustTupletBracketY` | `drawingYRel` do bracket antes/depois |
| `origin/src/src/adjusttupletsyfunctor.cpp:127` `AdjustTupletNumY` | `drawingYRel` do num antes/depois |
| `origin/src/src/adjusttupletsyfunctor.cpp:223` `AdjustTupletBracketBeamY` | o caso com beam, que tem geometria própria |
| `origin/src/src/adjusttupletsyfunctor.cpp:311` `CalcBracketShift` | **o retorno**, que é o número que a 04c precisa acertar |
| `origin/src/src/adjusttupletsyfunctor.cpp:338` `AdjustTupletNumOverlapFunctor::VisitLayerElement` | a posição livre encontrada e o elemento que a limitou |
| `origin/src/src/adjusttupletsyfunctor.cpp:376` `AdjustTupletWithSlursFunctor::VisitTuplet` | `drawingYRel` antes/depois |
| `origin/src/src/page.cpp:488`, `:548`, `:561` | `probe::BeginPass` para `AdjustTupletsX`, `AdjustTupletsY` e `AdjustTupletWithSlurs` |

**Arquivos do corpus** (fixados aqui para o conjunto não variar entre execuções)

| Arquivo | Por quê |
|---|---|
| `test/corpus/tuplet/tuplet-001.mei` | quiálteras simples, 3 no arquivo |
| `test/corpus/tuplet/tuplet-010.mei` | **aninhamento de 3 níveis** — o caso que o C++ trata explicitamente e que não se pode simplificar |
| `test/corpus/tuplet/tuplet-015.mei` | aninhamento de 2 níveis, para separar "aninha" de "aninha fundo" |

**Fixtures a gravar**: `test/fixtures/cpp/04c/<nome-do-arquivo>.jsonl`

**Comandos**

```bash
# a partir da RAIZ do workspace, não de verovio_dart/
cpp_probe/sync.sh
# edite build-probe/src/src/{adjusttupletsxfunctor,adjusttupletsyfunctor,page}.cpp — só fprintf, nada de lógica
cpp_probe/mkpatch.sh 04c        # grava cpp_probe/patches/04c.patch
cpp_probe/build.sh 04c          # incremental (~1 min) se build-probe/ já existe

for f in tuplet/tuplet-001 tuplet/tuplet-010 tuplet/tuplet-015; do
  n=$(basename $f)
  cpp_probe/run.sh 04c "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/04c/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
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

- **Criar** `lib/src/layout/adjust_tuplets.dart` — os quatro functors.
- **Alterar** `lib/src/model/doc.dart` — ligar `AdjustTupletsX` (horizontal) e
  `AdjustTupletsY` + `AdjustTupletWithSlurs` (vertical); atualizar os comentários de "skipped"
  em `:298-299`, `:344`, `:461-462` e `:505`.
- **Criar** `test/adjust_tuplets_test.dart`.

## Passo a passo

1. Leia `adjusttupletsxfunctor.cpp` (107 linhas) inteiro.
2. Leia `adjusttupletsyfunctor.cpp` (429 linhas) inteiro. Ele tem os três functors; identifique
   onde `AdjustTupletsYFunctor` instancia `AdjustTupletNumOverlapFunctor` e com que argumentos.
2-bis. **Extraia os dados de referência do C++ antes de escrever Dart.** Instrumente com `fprintf` as
   funções listadas em *Dados de referência do C++* e rode os comandos daquela seção. Confira que o
   binário instrumentado ainda produz SVG idêntico ao do limpo. **Leia os fixtures antes de escrever
   a primeira linha de Dart** — eles dizem o que o functor faz de verdade, caso a caso, melhor do
   que a leitura do `.cpp`.
3. Porte os quatro em `adjust_tuplets.dart`, na mesma ordem em que aparecem no C++.
4. Ligue no `doc.dart`, nas posições do `page.cpp`.
5. Testes com `test/corpus/tuplet/tuplet-001.mei` e mais um dos 22 arquivos de `test/corpus/tuplet/`
   que tenha quiáltera aninhada (`grep -l "tuplet.*tuplet" test/corpus/tuplet/*.mei | head -3`).
   Asserte `drawingXRel`/`drawingYRel` do `TupletBracket` e do `TupletNum`.
6. Verificação.

**Protocolo de re-instrumentação — leia antes de "consertar" qualquer número.** Se um valor do Dart
não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao patch, instrumente mais
fundo dentro da função divergente (valores intermediários, o ramo do `if` tomado, o resultado de
cada helper), rode `cpp_probe/mkpatch.sh 04c && cpp_probe/build.sh 04c`, regere o fixture e
compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a divergência
irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
herda o instrumento, não o problema.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 307 testes**
- [ ] `grep -c "^class Adjust" lib/src/layout/adjust_tuplets.dart` = 4
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.`, timemaps **≥ 24/30**, e
      `tuplet/tuplet-001.mei` continua com `Layout OK` e todos os `PASS`
- [ ] `cpp_probe/patches/04c.patch` versionado, contendo **apenas** acréscimos de instrumentação
      (`grep -c '^-[^-]' cpp_probe/patches/04c.patch` = 0) — cole o resumo do `mkpatch.sh` no relatório
- [ ] `cpp_probe/build.sh 04c && cpp_probe/run.sh 04c …` reproduz os fixtures do zero, e o binário
      instrumentado produz SVG idêntico ao do binário limpo para os arquivos desta tarefa
      (`diff` vazio, colado no relatório)
- [ ] N valores do fixture comparados com o Dart em epsilon 0; o relatório traz N, quantos batem, e
      cada divergência restante com hipótese de causa nomeando função e linha do C++
- [ ] Relatório em `prompts/reports/04c.md`
- [ ] `PLANO.md`: os quatro nomes removidos da lista de faltantes

## Armadilhas conhecidas

- `AdjustTupletNumOverlapFunctor` é instanciado **dentro** do `AdjustTupletsYFunctor` e devolve um
  valor (a posição livre encontrada). Se você o ligar no pipeline como functor independente, o
  resultado muda.
- Quiálteras aninhadas: o C++ trata a profundidade explicitamente. Não simplifique.
- `AdjustTupletWithSlursFunctor` depende de posicionadores de slur (mesma armadilha da 04b) —
  tem de rodar depois de `AdjustSlursFunctor`.
- A bbox de slur hoje é aproximada (`headless_extents.dart:572`). Divergências numéricas contra o
  C++ nos casos com ligadura são **esperadas**; documente e siga.

## Fora de escopo

- `AdjustBeams` (tarefa 04d), mesmo que o `page.cpp` o mostre na mesma fase vertical.
- Consertar aproximações de bbox.
- Instrumentar functors de outras tarefas: o seu patch cobre só os desta.
