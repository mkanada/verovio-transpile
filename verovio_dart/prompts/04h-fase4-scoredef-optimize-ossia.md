# 04h — ScoreDefOptimizeFunctor + ScoreDefSetOssiaFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os dois functors de `setscoredeffunctor.cpp` que faltam: a otimização do `scoreDef`
(esconder pentagramas vazios — a opção `condense`) e a marcação de pentagramas de ossia.

## Pré-condições

Tarefas **04-00** e **04a**–**04g** concluídas.

```bash
ls verovio_dart/test/fixtures/cpp/04g/ossia-001.mei.jsonl   # o fixture da 04g existe
cd verovio_dart
ls lib/src/layout/calc_ledger_lines.dart
dart test 2>&1 | tail -1     # verde, ≥ 334
grep -n "ScoreDefOptimizeFunctor\|ScoreDefSetOssiaFunctor" lib/src/layout/setscoredef_functor.dart
# esperado: só a linha 15, um comentário dizendo que não estão portados
```

## Referência C++

| Arquivo | Conteúdo |
|---|---|
| `origin/src/include/vrv/setscoredeffunctor.h` | `class ScoreDefOptimizeFunctor`, `class ScoreDefSetOssiaFunctor`. |
| `origin/src/src/setscoredeffunctor.cpp` (928 linhas) | localize as duas classes com `grep -n "ScoreDefOptimizeFunctor::\|ScoreDefSetOssiaFunctor::" origin/src/src/setscoredeffunctor.cpp` |
| `origin/src/src/doc.cpp` | `Doc::ScoreDefOptimizeDoc` e `Doc::ScoreDefSetOssiaDoc` — quem os chama e com que pré-condições (`grep -n "ScoreDefOptimize\|ScoreDefSetOssia" origin/src/src/doc.cpp`) |
| `origin/src/include/vrv/options.h` | `OptionIntMap m_condense` e `OptionBool m_condenseFirstPage`, `m_condenseNotLastSystem`, `m_condenseTempoPages` — os valores que dirigem a otimização |

## Dados de referência do C++

> Convenções em `00-MESTRE.md` §6-bis e `cpp_probe/README.md`. Instrumentação é **só acréscimo**:
> nenhum patch pode remover ou alterar uma linha do C++. Os números de linha abaixo são os da
> árvore **limpa**; com os patches anteriores aplicados eles andam algumas linhas, então localize
> sempre por nome com `grep -n` em `build-probe/src/`.

**Valores a medir**

- `ScoreDefOptimizeFunctor`: para cada `StaffDef`, o `drawingVisibility` **antes e depois**
  (o functor marca invisível, não remove da árvore); para cada `StaffGrp`, se ficou escondido; e o
  valor efetivo das quatro opções `condense*` na execução.
- `ScoreDefSetOssiaFunctor`: para cada `Ossia`, qual `StaffDef` foi herdado
  (`GetPreviousStaffDef`), e o `Clef` / `Layer` / `Staff` que ele produziu.
- **Os defaults das quatro opções `condense*` como o C++ os lê** — é o número que a armadilha desta
  tarefa avisa que, se vier errado, muda o layout de todo o corpus.

**Funções a instrumentar**

| Onde | O quê |
|---|---|
| `origin/src/src/setscoredeffunctor.cpp:426` `ScoreDefOptimizeFunctor::VisitStaff` | `drawingVisibility` antes/depois |
| `origin/src/src/setscoredeffunctor.cpp:469` `VisitStaffGrpEnd` | o grupo escondido ou não |
| `origin/src/src/setscoredeffunctor.cpp:530` `VisitSystemEnd` | **onde a otimização é consolidada** |
| `origin/src/src/setscoredeffunctor.cpp:680` `ScoreDefSetOssiaFunctor::VisitOssia` | o que a ossia produziu |
| `origin/src/src/setscoredeffunctor.cpp:791` `GetPreviousStaffDef` | **o retorno**: qual `StaffDef` foi herdado |
| `origin/src/src/doc.cpp` `Doc::ScoreDefOptimizeDoc` / `Doc::ScoreDefSetOssiaDoc` (ache com `grep -n "ScoreDefOptimize\|ScoreDefSetOssia" origin/src/src/doc.cpp`) | `probe::BeginPass` e o valor efetivo das 4 opções `condense*` |

**Arquivos do corpus** (fixados aqui para o conjunto não variar entre execuções)

| Arquivo | Por quê |
|---|---|
| `test/corpus/score/score-002.mei` | **4 pentagramas, 23 compassos, 76 `mRest`** — pentagramas vazios de sobra para o `condense` ter o que esconder |
| `test/corpus/ossia/ossia-001.mei` | ossia — o caso central de `ScoreDefSetOssia` |

**Fixtures a gravar**: `test/fixtures/cpp/04h/<nome-do-arquivo>.jsonl`

**Comandos**

```bash
# a partir da RAIZ do workspace, não de verovio_dart/
cpp_probe/sync.sh
# edite build-probe/src/src/{setscoredeffunctor,doc}.cpp — só fprintf, nada de lógica
cpp_probe/mkpatch.sh 04h        # grava cpp_probe/patches/04h.patch
cpp_probe/build.sh 04h          # incremental (~1 min) se build-probe/ já existe

for f in score/score-002 ossia/ossia-001; do
  n=$(basename $f)
  cpp_probe/run.sh 04h "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/04h/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
  build/verovio -r verovio_dart/assets/data -x 12345 -o "/tmp/limpo-$n.svg" \
      "verovio_dart/test/corpus/$f.mei" >/dev/null
  diff "/tmp/limpo-$n.svg" "/tmp/probe-$n.svg" && echo "SVG idêntico: $n"
done
```

`doc.cpp` ainda não inclui `vrvprobe.h` — acrescente o `#include` no bloco de includes dele.
Nenhum outro patch toca `doc.cpp` a não ser a 04-00, que instrumenta `Doc::GetDrawingUnit`, bem
longe daqui; o `#include` já estará lá, então **não duplique**.

O id da sua tarefa **já está** em `cpp_probe/patches/ORDER`, na posição certa; `patch.sh --list`
mostra a pilha. `build.sh` para com mensagem clara se o patch de alguma tarefa anterior faltar —
isso quer dizer que aquela tarefa não rodou, não que algo quebrou.

Os `diff` têm de sair **vazios**. Se algum divergir, o patch tem lógica onde deveria
ter só `fprintf` — conserte antes de escrever qualquer Dart.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/layout/setscoredef_functor.dart` — acrescentar as duas classes e **corrigir o
  comentário da linha 15**, que hoje diz que não estão portadas.
- **Alterar** `lib/src/model/doc.dart` — `scoreDefOptimizeDoc` / `scoreDefSetOssiaDoc`; atualizar os
  comentários de `:1254` (ossia) e `:1494` (condense).
- **Alterar** `lib/src/core/options_shell.dart` — acrescentar as opções `condense`,
  `condenseFirstPage`, `condenseNotLastSystem`, `condenseTempoPages` **com os defaults exatos do C++**
  (leia-os em `origin/src/src/options.cpp`, procurando por `m_condense`). Nenhuma das quatro tem
  `definitionFactor` (confira no `Init`), então **não** ligue o fator que a 04-00 introduziu.
  Não porte o resto das opções: isso é a Fase 7.
- **Criar** `test/scoredef_optimize_test.dart`.

## Passo a passo

1. `grep -n "ScoreDefOptimizeFunctor::\|ScoreDefSetOssiaFunctor::" origin/src/src/setscoredeffunctor.cpp`
   para achar as faixas de linha; leia as duas classes inteiras.
2. Leia `Doc::ScoreDefOptimizeDoc` e `Doc::ScoreDefSetOssiaDoc` no `doc.cpp`.
3. Leia os defaults das 4 opções `condense*` em `origin/src/src/options.cpp`.
3-bis. **Extraia os dados de referência do C++ antes de escrever Dart.** Instrumente com `fprintf` as
   funções listadas em *Dados de referência do C++* e rode os comandos daquela seção. Confira que o
   binário instrumentado ainda produz SVG idêntico ao do limpo. **Leia os fixtures antes de escrever
   a primeira linha de Dart** — eles dizem o que o functor faz de verdade, caso a caso, melhor do
   que a leitura do `.cpp`.
4. Acrescente as opções ao `options_shell.dart`, no mesmo estilo das que já estão lá
   (`Breaks`, `MensuralResp`) — o `condense` é um `OptionIntMap`, ou seja, um enum com nomes.
5. Porte as duas classes em `setscoredef_functor.dart`.
6. Ligue no `doc.dart`.
7. Testes: use **os dois arquivos fixados** em *Dados de referência do C++* —
   `score/score-002.mei` (4 pentagramas, 76 `mRest`) para o condense e `ossia/ossia-001.mei` para
   a ossia.
8. Verificação.

**Protocolo de re-instrumentação — leia antes de "consertar" qualquer número.** Se um valor do Dart
não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao patch, instrumente mais
fundo dentro da função divergente (valores intermediários, o ramo do `if` tomado, o resultado de
cada helper), rode `cpp_probe/mkpatch.sh 04h && cpp_probe/build.sh 04h`, regere o fixture e
compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a divergência
irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
herda o instrumento, não o problema.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 340 testes**
- [ ] `grep -c "^class ScoreDefOptimizeFunctor\|^class ScoreDefSetOssiaFunctor" lib/src/layout/setscoredef_functor.dart` = 2
- [ ] `grep -c "ScoreDefOptimizeFunctor. and .ScoreDefSetOssiaFunctor. are" lib/src/layout/setscoredef_functor.dart` = 0
      (o comentário mentiroso da linha 15 sumiu)
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.`, timemaps **≥ 24/30**
- [ ] `cpp_probe/patches/04h.patch` versionado, contendo **apenas** acréscimos de instrumentação
      (`grep -c '^-[^-]' cpp_probe/patches/04h.patch` = 0) — cole o resumo do `mkpatch.sh` no relatório
- [ ] `cpp_probe/build.sh 04h && cpp_probe/run.sh 04h …` reproduz os fixtures do zero, e o binário
      instrumentado produz SVG idêntico ao do binário limpo para os arquivos desta tarefa
      (`diff` vazio, colado no relatório)
- [ ] N valores do fixture comparados com o Dart em epsilon 0; o relatório traz N, quantos batem, e
      cada divergência restante com hipótese de causa nomeando função e linha do C++
- [ ] Relatório em `prompts/reports/04h.md`
- [ ] `PLANO.md`: `ScoreDefOptimize` e `ScoreDefSetOssia` removidos da lista de faltantes

## Armadilhas conhecidas

- O default do `condense` no C++ **não é** "sempre condensar". Leia o valor real em `options.cpp`;
  com o default errado, todo o corpus muda de layout e os 623 goldens ficam inalcançáveis.
- `ScoreDefOptimizeFunctor` marca `StaffDef` como invisível, não remove nada da árvore.
- Ossia depende do `AdjustOssiaStaffDefFunctor` da tarefa 04g já estar ligado.

## Fora de escopo

- Portar o resto das 210 opções (Fase 7, tarefas 07-01 a 07-06). Acrescente **só** as 4 `condense*`.
- `View::DrawOssia` (tarefa 05-10).
- Instrumentar functors de outras tarefas: o seu patch cobre só os desta.
