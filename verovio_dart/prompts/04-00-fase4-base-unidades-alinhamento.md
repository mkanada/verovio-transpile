# 04-00 — Base numérica da Fase 4: fator de definição e tempos de alinhamento

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Pôr em paridade numérica exata com o C++ as **duas entradas de que todos os functors de 04a–04h
dependem**: a família `Doc::GetDrawing*` (hoje 10× menor que a do C++, porque o fator de definição
das opções não é aplicado) e os tempos/posições dos `Alignment` produzidos por
`AlignHorizontally` + `CalcAlignmentXPos`. Ao final, `dart run tool/validate_layout.dart` compara
contra fixtures do C++ com epsilon 0 nessas duas famílias de valores.

**Esta tarefa vem antes da 04a de propósito.** Toda a aritmética das oito tarefas seguintes é
`… * drawingUnit`: `m_doc->GetRightMargin(x) * drawingUnit`, `drawingUnit / 3 + tremWidth / 2`,
`1.5 * (rest->GetDur() - DURATION_8) * drawingUnit`. Implementá-las sobre uma base 10× errada é
acertar functor por functor contra um alvo móvel e refazer tudo depois.

## Pré-condições

Nenhuma tarefa da Fase 4 anterior. Confirme a infraestrutura de extração em 30 s:

```bash
ls cpp_probe/build.sh verovio_dart/test/fixtures/cpp_fixture.dart   # ambos existem
ls verovio_dart/test/fixtures/cpp/EXEMPLO/note-001.mei.jsonl        # o fixture de referência
cd verovio_dart && dart test 2>&1 | tail -1                         # "All tests passed!", ≥ 281
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/include/vrv/options.h` | 221-320 | `OptionDbl` (`:221`) e `OptionInt` (`:269`): `Init(default, min, max, bool definitionFactor)`, `GetValue()` e `GetUnfactoredValue()`. |
| `origin/src/src/options.cpp` | 286-289, 366-369 | `OptionDbl::GetValue()` e `OptionInt::GetValue()` = `(m_definitionFactor) ? m_value * DEFINITION_FACTOR : m_value`. |
| `origin/src/src/options.cpp` | 1100-1120, 1198-1199 | **as 7 opções com `definitionFactor = true`**: `m_pageHeight`, `m_pageMarginBottom`, `m_pageMarginLeft`, `m_pageMarginRight`, `m_pageMarginTop`, `m_pageWidth`, `m_unit`. Nenhuma outra. |
| `origin/src/include/vrv/vrvdef.h` | 453, 455 | `#define DEFINITION_FACTOR 10`, `#define DEFAULT_UNIT 9.0`. |
| `origin/src/src/doc.cpp` | 2022-2025 | `Doc::GetDrawingUnit(int staffSize)` = `m_options->m_unit.GetValue() * staffSize / 100`. Leia também, na vizinhança, `GetDrawingDoubleUnit`, `GetDrawingStaffSize`, `GetDrawingBeamWidth`, `GetDrawingBeamWhiteWidth`, `GetDrawingLedgerLineExtension`, `GetDrawingBarLineWidth`, `GetDrawingStaffLineWidth`, `GetDrawingStemWidth`, `GetLeftMargin`, `GetRightMargin` — **toda a família**. |
| `origin/src/src/horizontalaligner.cpp` | 759-768 | `Alignment::HorizontalSpaceForDuration` — o `* 10.0` daqui é **constante experimental, não** o `DEFINITION_FACTOR`. Já está portado fielmente; não mexa. |
| `origin/src/src/alignfunctor.cpp` | 60, 110, 145, 396, 415 | `AlignHorizontallyFunctor`: `VisitLayer`, `VisitLayerEnd`, **`VisitLayerElement` (`:145`, onde o cursor de tempo avança)**, `VisitMeasure`, `VisitMeasureEnd`. |
| `origin/src/src/calcalignmentxposfunctor.cpp` | 33, 96, 109, 118 | `CalcAlignmentXPosFunctor`: **`VisitAlignment` (`:33`, quem grava o `xRel` inicial)**, `VisitMeasure`, `VisitMeasureAligner`, `VisitSystem`. Note que **não há** `VisitMeasureEnd` nesta classe. |
| `origin/src/src/layerelement.cpp` | 661, 777, 783 | `LayerElement::GetAlignmentDuration` (duas sobrecargas) e `GetSameAsContentAlignmentDuration` — a duração que faz o cursor andar. |

## Dados de referência do C++

> Convenções em `00-MESTRE.md` §6-bis e `cpp_probe/README.md`. Instrumentação é **só acréscimo**:
> nenhum patch pode remover ou alterar uma linha do C++.

**Valores a medir**

1. **Unidades** — uma linha por documento carregado, emitida uma vez: `unit` (o
   `m_options->m_unit.GetValue()` factored), `drawingUnit` para `staffSize` 100 e para o tamanho de
   cada `StaffAlignment` do documento, `drawingDoubleUnit`, `drawingStaffSize`, `pageWidth`,
   `pageHeight` e as quatro margens, tudo como o C++ os vê depois do fator.
2. **Alinhamentos** — para cada `Alignment` do `MeasureAligner`, ao fim de
   `CalcAlignmentXPosFunctor`: `type`, `time` (como fração, numerador/denominador — **não** como
   double, para a comparação ser exata) e `xRel`.
3. **Duração por elemento** — para cada `LayerElement` visitado por
   `AlignHorizontallyFunctor::VisitLayerElement`: a duração devolvida por `GetAlignmentDuration`
   (numerador/denominador) e o `time` do cursor antes e depois. É o valor que localiza a
   divergência da lacuna 2 abaixo.

**Funções a instrumentar** (arquivo:linha na árvore **limpa**; depois de aplicar `EXEMPLO.patch` os
números de `page.cpp` andam 3 linhas, então localize sempre por nome com `grep -n`):

| Onde | O quê |
|---|---|
| `origin/src/src/doc.cpp:2022` `Doc::GetDrawingUnit` | emita **uma vez por documento** o bloco de unidades (use um `static bool` local no probe, não no Verovio) |
| `origin/src/src/calcalignmentxposfunctor.cpp:33` `VisitAlignment` | um registro por `Alignment`: `type`, `time` (num/den) e `xRel` antes e depois |
| `origin/src/src/alignfunctor.cpp:145` `AlignHorizontallyFunctor::VisitLayerElement` | duração devolvida por `GetAlignmentDuration` (num/den) e cursor antes/depois |
| `origin/src/src/page.cpp` `Page::ResetAligners` | `probe::BeginPass("AlignHorizontally")` antes do `Process` de `:337`, e `probe::BeginPass("CalcAlignmentXPos")` antes do de `:366` (números da árvore limpa) |

`page.cpp` já inclui `vrvprobe.h` (vem do `EXEMPLO.patch`). `doc.cpp`,
`calcalignmentxposfunctor.cpp` e `alignfunctor.cpp` ainda não — acrescente o `#include "vrvprobe.h"`
no bloco de includes de cada um. Nenhum outro patch toca esses três arquivos, então não há conflito.

**Arquivos do corpus** (fixados aqui para o conjunto não variar entre execuções):

| Arquivo | Por quê |
|---|---|
| `test/corpus/note/note-001.mei` | o menor caso onde a lacuna 2 aparece (1 compasso, pausa/nota/pausa) |
| `test/corpus/beam/beam-001.mei` | caso de controle: o alinhador do Dart **já** bate aqui (2 quartos dos dois lados) |
| `test/corpus/rest/rest-001.mei` | colapso total: 2 compassos, 24 pausas, alinhador do Dart devolve duração 0 |
| `test/corpus/dot/dot-001.mei` | 3 compassos, 49 notas, 8 acordes — volume, e a base de 04a |
| `test/corpus/score/score-002.mei` | 4 pentagramas, 23 compassos — exercita `staffSize` ≠ 100 e as margens de página |

**Fixtures a gravar**: `test/fixtures/cpp/04-00/<nome-do-arquivo>.jsonl`

**Comandos** (a partir da **raiz** do workspace, não de `verovio_dart/`):

```bash
cpp_probe/sync.sh
# edite build-probe/src/src/{doc,calcalignmentxposfunctor,alignfunctor,page}.cpp — só fprintf
cpp_probe/mkpatch.sh 04-00        # grava cpp_probe/patches/04-00.patch
cpp_probe/build.sh 04-00          # incremental (~1 min); a 1ª vez compila tudo (~10 min em 4 núcleos)

for f in note/note-001 beam/beam-001 rest/rest-001 dot/dot-001 score/score-002; do
  n=$(basename $f)
  cpp_probe/run.sh 04-00 "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/04-00/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
  build/verovio -r verovio_dart/assets/data -x 12345 -o "/tmp/limpo-$n.svg" \
      "verovio_dart/test/corpus/$f.mei" >/dev/null
  diff "/tmp/limpo-$n.svg" "/tmp/probe-$n.svg" && echo "SVG idêntico: $n"
done
```

O id da sua tarefa **já está** em `cpp_probe/patches/ORDER`, na posição certa; `patch.sh --list`
mostra a pilha. `build.sh` para com mensagem clara se o patch de alguma tarefa anterior faltar —
isso quer dizer que aquela tarefa não rodou, não que algo quebrou.

Os cinco `diff` têm de sair **vazios**. Se algum divergir, o patch tem lógica onde deveria ter só
`fprintf` — conserte antes de escrever qualquer Dart.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/core/options_shell.dart` — `Option<T>` ganha o fator de definição:
  um campo `definitionFactor` (default `false`) no construtor/`createOption`, e `value` passa a
  devolver o valor multiplicado por `definitionFactor` (`lib/src/core/vrvdef.dart:31`) quando ligado.
  Acrescente `unfactoredValue`, espelhando `GetUnfactoredValue()`. Ligue o fator **exatamente** nas
  7 opções que o C++ liga: `unit`, `pageWidth`, `pageHeight`, `pageMarginBottom`, `pageMarginLeft`,
  `pageMarginRight`, `pageMarginTop`. **Nenhuma outra.**
- **Conferir** `lib/src/model/doc.dart:1786-1800` e `:1386-1391` — a família `getDrawing*` e
  `updatePageDrawingSizes`. Depois do fator elas devem ficar **inalteradas**: elas já espelham o
  C++; era a opção que mentia. Se alguma tiver uma compensação escondida (um `* 10` ou um `/ 10`
  avulso posto para "dar certo"), **remova-a** e registre no relatório.
- **Alterar** o que a lacuna 2 exigir em `lib/src/layout/align_horizontally.dart` e/ou
  `lib/src/model/layer_element.dart` (`getAlignmentDuration`) — **guiado pelo fixture**, não por
  palpite: os registros de duração por elemento dizem qual elemento devolve duração diferente da do
  C++.
- **Criar** `test/base_units_test.dart` — paridade da família `getDrawing*` contra o fixture.
- **Criar** `test/alignment_parity_test.dart` — paridade de `time` e `xRel` de cada `Alignment`.
- **Alterar** `tool/validate_layout.dart` — acrescentar as duas contagens agregadas novas
  (arquivos com unidades batendo, arquivos com todos os alinhamentos batendo).

## Passo a passo

1. Leia `options.h:225-300` e `options.cpp:286-300`. Anote **quais** opções recebem `true` no
   `Init` (`options.cpp:1100-1120` e `1198-1199`) — são 7, confira com
   `grep -c "\.Init(.*, true)" origin/src/src/options.cpp`.
2. Leia `Doc::GetDrawingUnit` e a família inteira em `doc.cpp`.
3. Leia `AlignHorizontallyFunctor::VisitLayerElement` e `LayerElement::GetAlignmentDuration`.
4. **Extraia os dados de referência do C++ antes de escrever Dart.** Instrumente com `fprintf` as
   funções listadas em *Dados de referência do C++* e rode os comandos daquela seção. Confira os
   cinco `diff` de SVG. **Leia os fixtures antes de escrever a primeira linha de Dart** — eles
   dizem o que o C++ faz de verdade, caso a caso, melhor do que a leitura do `.cpp`.
5. Aplique o fator de definição no `options_shell.dart`. **Espere regressão**: `pageWidth` sai de
   2100 para 21000, `drawingUnit` de 9 para 90, e o cast-off passa a caber muito mais compasso por
   sistema. Isso é a correção aparecendo, não quebrando. Persiga cada teste vermelho até entender
   por que ele era verde antes.
6. Escreva `test/base_units_test.dart` comparando contra o fixture, epsilon 0.
7. Ataque a lacuna 2 com os registros de duração por elemento em mãos. Escopo medido em 2026-08-27,
   **antes** de qualquer correção: **166 dos 2107 compassos do corpus (7,9%)** têm o alinhador do
   Dart com `maxTime = 0`, e **8 dos 621 arquivos** têm duração total 0 apesar de terem música.
   `note/note-001.mei` devolve 1 quarto onde o C++ devolve 3; `beam/beam-001.mei`,
   `layer/layer-001.mei` e `dot/dot-001.mei` já batem. Meça de novo ao terminar e ponha os dois
   números no relatório.
8. Escreva `test/alignment_parity_test.dart`.
9. Rode a verificação.

**Protocolo de re-instrumentação — leia antes de "consertar" qualquer número.** Se um valor do Dart
não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao patch, instrumente mais
fundo dentro da função divergente (valores intermediários, o ramo do `if` tomado, o resultado de
cada helper), rode `cpp_probe/mkpatch.sh 04-00 && cpp_probe/build.sh 04-00`, regere o fixture e
compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a divergência
irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
herda o instrumento, não o problema.

## Critérios de aceite

- [ ] `dart analyze` reporta no máximo `10 issues found.`
- [ ] `dart test` verde, com **≥ 287 testes**
- [ ] `grep -c "definitionFactor" lib/src/core/options_shell.dart` ≥ 1, e exatamente **7** opções o
      ligam — prove com o grep no relatório
- [ ] `doc.getDrawingUnit(100)` devolve **90**, e todos os valores do bloco de unidades do fixture
      batem com epsilon 0 nos 5 arquivos
- [ ] `cpp_probe/patches/04-00.patch` versionado, contendo **apenas** acréscimos de instrumentação
      (`grep -c '^-[^-]' cpp_probe/patches/04-00.patch` = 0) — cole o resumo do `mkpatch.sh` no relatório
- [ ] `cpp_probe/build.sh 04-00 && cpp_probe/run.sh 04-00 …` reproduz os 5 fixtures do zero, e o
      binário instrumentado produz SVG idêntico ao do limpo para os 5 (`diff` vazio, colado no relatório)
- [ ] N valores de alinhamento (`time` e `xRel`) comparados com o Dart em epsilon 0; o relatório traz
      N, quantos batem, e cada divergência restante com hipótese de causa nomeando função e linha do C++
- [ ] O relatório traz a contagem de compassos com `maxTime = 0` **antes** (166/2107) e **depois**
- [ ] `dart run tool/validate_layout.dart` roda até o fim e o relatório em `tool/LAYOUT_VALIDATION.md`
      mantém `Check notes: None. All structural assertions passed.`
- [ ] Relatório gravado em `prompts/reports/04-00.md`, com uma seção listando **todo teste que ficou
      vermelho por causa do fator** e por que ele era verde antes
- [ ] No `PLANO.md`, na Fase 4, o item novo de base numérica marcado

## Armadilhas conhecidas

- **O fator não é uniforme hoje, e é isso que faz mal.** `Alignment::HorizontalSpaceForDuration`
  está portado fielmente e produz o mesmo passo (690 em `note-001.mei`) dos dois lados, enquanto
  tudo que vem de `getDrawingUnit` sai 10× menor. O port mistura duas escalas; não é um fator
  global que dê para "corrigir na saída".
- **Não ligue o fator em opção que o C++ não liga.** São 7, listadas acima. Ligar em `spacingLinear`
  ou em `staffLineWidth`, por exemplo, quebra tudo de um jeito difícil de rastrear.
- `GetValue()` versus `GetUnfactoredValue()`: o C++ usa o **unfactored** ao serializar as opções
  (`toolkit.cpp:1133-1135`). Se você não portar os dois, a Fase 7 vai emitir as opções com o valor
  errado. Porte os dois agora.
- O `time` dos alinhamentos é uma **fração** (`core/fraction.dart`). Compare numerador e denominador,
  não `toDouble()` — a comparação em double esconde erro de arredondamento que é exatamente o que
  esta tarefa procura.
- `note-001.mei` tem `<note visible="false">`: invisível **não** quer dizer sem duração. Se a sua
  correção da lacuna 2 passar a ignorar elementos invisíveis, você trocou um defeito por outro.
- Os 8 arquivos que colapsam para duração 0 estão quase todos em `test/corpus/rest/`; mas
  `rest/rest-004.mei` e `rest/rest-005.mei` **já batem**. A causa não é "pausa", é mais estreita
  que isso — o fixture de duração por elemento é que vai dizer qual.

## Fora de escopo

- Portar o resto das ~210 opções: é a Fase 7 (tarefas 07-01 a 07-06). Mexa **só** no mecanismo do
  fator e nas 7 opções que o usam.
- Qualquer um dos functors de ajuste de 04a–04h.
- Instrumentar functors das outras tarefas.
- Consertar `headless_extents.dart` ou as aproximações de bbox — é a tarefa 05-12.
