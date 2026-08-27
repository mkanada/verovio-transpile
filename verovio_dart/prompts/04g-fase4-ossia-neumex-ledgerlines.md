# 04g — AdjustOssiaStaffDefFunctor + AdjustNeumeXFunctor + CalcLedgerLinesFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os três functors restantes das fases horizontal e vertical: ajuste do `staffDef` de ossia,
espaçamento X de neumas e cálculo das linhas suplementares (ledger lines).

## Pré-condições

Tarefas **04-00** e **04a**–**04f** concluídas.

```bash
ls verovio_dart/test/fixtures/cpp/04f/section-001.mei.jsonl   # o fixture da 04f existe
cd verovio_dart
ls lib/src/layout/adjust_x_overflow.dart lib/src/layout/calc_spanning_beam_spans.dart
dart test 2>&1 | tail -1     # verde, ≥ 326
```

## Referência C++

| Arquivo | Linhas | Visits |
|---|---:|---|
| `origin/src/src/adjustossiastaffdeffunctor.cpp` | 106 | `VisitAlignment`, `VisitLayerElement`, `VisitMeasure`, `VisitMeasureEnd`, `VisitStaff` |
| `origin/src/src/adjustneumexfunctor.cpp` | 102 | `VisitLayer`, `VisitLayerEnd`, `VisitStaff`, `VisitNeume`, `VisitSyl` |
| `origin/src/src/calcledgerlinesfunctor.cpp` | 191 | `VisitAccid`, `VisitNote`, `VisitStaffEnd` |
| `origin/src/src/page.cpp:396-497` | — | `AdjustOssiaStaffDef` (primeiro da fase horizontal) e `AdjustNeumeX` |
| `origin/src/src/page.cpp:509-608` | — | `CalcLedgerLines` (logo depois de `ResetVerticalAlignment`) |
| `origin/src/src/page.cpp:689-707` | — | `Page::LayOutPitchPos` — `CalcLedgerLines` roda **também** aqui |

`CalcLedgerLinesFunctor` acumula em `Staff` e materializa em `VisitStaffEnd`; leia
`Staff::AddLedgerLineAbove/Below` em `origin/src/src/staff.cpp` e confirme o que existe em Dart:

```bash
grep -n "ledgerLine\|LedgerLine" lib/src/model/basic_elements.dart | head -20
```

## Dados de referência do C++

> Convenções em `00-MESTRE.md` §6-bis e `cpp_probe/README.md`. Instrumentação é **só acréscimo**:
> nenhum patch pode remover ou alterar uma linha do C++. Os números de linha abaixo são os da
> árvore **limpa**; com os patches anteriores aplicados eles andam algumas linhas, então localize
> sempre por nome com `grep -n` em `build-probe/src/`.

**Valores a medir**

- `AdjustOssiaStaffDefFunctor`: o `xRel` do alinhamento de ossia antes e depois, e o `m_staffAlignment`
  corrente.
- `AdjustNeumeXFunctor`: o `drawingXRel` de cada `Neume` e de cada `Syl` antes e depois, mais o
  `m_currentSyl` / a largura acumulada.
- `CalcLedgerLinesFunctor`: para cada `Staff`, em `VisitStaffEnd`, **a lista de ledger lines
  materializada** — quantas acima, quantas abaixo, e para cada uma o par (esquerda, direita). E, em
  `CalcForLayerElement`, a largura de cabeça de nota usada, que vem das métricas de glifo e é onde a
  divergência costuma nascer.

**Funções a instrumentar**

| Onde | O quê |
|---|---|
| `origin/src/src/adjustossiastaffdeffunctor.cpp:28` `VisitAlignment` | `xRel` antes/depois |
| `origin/src/src/adjustossiastaffdeffunctor.cpp:82` `VisitMeasureEnd` | o ajuste final do compasso |
| `origin/src/src/adjustneumexfunctor.cpp:37` `VisitLayerEnd` | **onde o espaçamento é aplicado** |
| `origin/src/src/adjustneumexfunctor.cpp:56` `VisitNeume` / `:84` `VisitSyl` | `drawingXRel` antes/depois |
| `origin/src/src/calcledgerlinesfunctor.cpp:40` `VisitNote` / `:25` `VisitAccid` | o que é acumulado |
| `origin/src/src/calcledgerlinesfunctor.cpp:57` `CalcForLayerElement` | **a largura de cabeça de nota** e os extremos calculados |
| `origin/src/src/calcledgerlinesfunctor.cpp:93` `VisitStaffEnd` | **a lista materializada**: contagem e extremos de cada ledger line |
| `origin/src/src/calcledgerlinesfunctor.cpp:106` `AdjustLedgerLines` | a fusão de linhas vizinhas |
| `origin/src/src/page.cpp:416`, `:435`, `:522`, `:705` | `probe::BeginPass` para `AdjustOssiaStaffDef`, `AdjustNeumeX` e as **duas** chamadas de `CalcLedgerLines` (fase vertical em `:522` e `LayOutPitchPos` em `:705`) |

**Arquivos do corpus** (fixados aqui para o conjunto não variar entre execuções)

| Arquivo | Por quê |
|---|---|
| `test/corpus/ossia/ossia-001.mei` | ossia — o caso central de `AdjustOssiaStaffDef` |
| `test/corpus/neume/neume-001.mei` | notação neumática — o caso central de `AdjustNeumeX` |
| `test/corpus/note/note-009.mei` | **oitavas 3 e 6**: notas bem abaixo e bem acima do pentagrama, ou seja, ledger lines dos dois lados |

**Fixtures a gravar**: `test/fixtures/cpp/04g/<nome-do-arquivo>.jsonl`

**Comandos**

```bash
# a partir da RAIZ do workspace, não de verovio_dart/
cpp_probe/sync.sh
# edite build-probe/src/src/{adjustossiastaffdeffunctor,adjustneumexfunctor,calcledgerlinesfunctor,page}.cpp — só fprintf, nada de lógica
cpp_probe/mkpatch.sh 04g        # grava cpp_probe/patches/04g.patch
cpp_probe/build.sh 04g          # incremental (~1 min) se build-probe/ já existe

for f in ossia/ossia-001 neume/neume-001 note/note-009; do
  n=$(basename $f)
  cpp_probe/run.sh 04g "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/04g/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
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

- **Criar** `lib/src/layout/adjust_ossia_neume.dart` — `AdjustOssiaStaffDefFunctor` e
  `AdjustNeumeXFunctor`.
- **Criar** `lib/src/layout/calc_ledger_lines.dart` — `CalcLedgerLinesFunctor`.
- **Alterar** o arquivo de `Staff` para os acumuladores de ledger line, se faltarem.
- **Alterar** `lib/src/model/doc.dart` — ligar os três; **remover** o comentário
  `// Deviation: CalcLedgerLinesFunctor arrives with the rendering phase.` em `:473` e a menção
  em `:464`; atualizar `:296` e `:1254` (nota de ossia).
- **Alterar** `lib/src/layout/align_horizontally.dart:669` e `:187` — os `TODO(phase-5+)` sobre ossia.
- **Criar** `test/adjust_ossia_neume_test.dart` e `test/calc_ledger_lines_test.dart`.

## Passo a passo

1. Leia os três `.h` e os três `.cpp`.
2. Leia `Staff::AddLedgerLineAbove`/`Below` e `Staff::ResetLedgerLines` no C++, e confira o estado
   equivalente na classe `Staff` em Dart. Acrescente o que faltar.
2-bis. **Extraia os dados de referência do C++ antes de escrever Dart.** Instrumente com `fprintf` as
   funções listadas em *Dados de referência do C++* e rode os comandos daquela seção. Confira que o
   binário instrumentado ainda produz SVG idêntico ao do limpo. **Leia os fixtures antes de escrever
   a primeira linha de Dart** — eles dizem o que o functor faz de verdade, caso a caso, melhor do
   que a leitura do `.cpp`.
3. Porte os três functors.
4. Ligue no `doc.dart` nas **três** posições (`LayOutHorizontally`, `LayOutVertically`,
   `LayOutPitchPos`).
5. Testes: use **os três arquivos fixados** em *Dados de referência do C++*
   (`ossia/ossia-001.mei`, `neume/neume-001.mei`, `note/note-009.mei` — este último tem notas em
   oitava 3 e 6, ou seja, ledger lines acima e abaixo).
6. Verificação.

**Protocolo de re-instrumentação — leia antes de "consertar" qualquer número.** Se um valor do Dart
não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao patch, instrumente mais
fundo dentro da função divergente (valores intermediários, o ramo do `if` tomado, o resultado de
cada helper), rode `cpp_probe/mkpatch.sh 04g && cpp_probe/build.sh 04g`, regere o fixture e
compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a divergência
irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
herda o instrumento, não o problema.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 334 testes**
- [ ] `grep -c "class CalcLedgerLinesFunctor" lib/src/layout/calc_ledger_lines.dart` = 1
- [ ] `grep -c "Deviation: CalcLedgerLinesFunctor arrives" lib/src/model/doc.dart` = 0
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.`, timemaps **≥ 24/30**, e
      `ossia/ossia-001.mei` + `neume/neume-001.mei` continuam com `Layout OK`
- [ ] `cpp_probe/patches/04g.patch` versionado, contendo **apenas** acréscimos de instrumentação
      (`grep -c '^-[^-]' cpp_probe/patches/04g.patch` = 0) — cole o resumo do `mkpatch.sh` no relatório
- [ ] `cpp_probe/build.sh 04g && cpp_probe/run.sh 04g …` reproduz os fixtures do zero, e o binário
      instrumentado produz SVG idêntico ao do binário limpo para os arquivos desta tarefa
      (`diff` vazio, colado no relatório)
- [ ] N valores do fixture comparados com o Dart em epsilon 0; o relatório traz N, quantos batem, e
      cada divergência restante com hipótese de causa nomeando função e linha do C++
- [ ] Relatório em `prompts/reports/04g.md`
- [ ] `PLANO.md`: os três nomes removidos da lista de faltantes

## Armadilhas conhecidas

- `CalcLedgerLines` roda **duas vezes** no C++ (fase vertical e `LayOutPitchPos`). Ligar em só um
  lugar deixa metade dos casos errada.
- Largura da linha suplementar depende da largura da cabeça de nota, que vem das métricas de glifo
  (`Resources`). Isso **existe** em Dart (`lib/src/rendering/resources.dart`) — use as métricas
  reais, não uma constante. Lembre de `Resources.defaultPath = 'assets/data';` nos testes.
- `AdjustNeumeXFunctor` só faz sentido em documentos neumáticos; nos 6 arquivos de
  `test/corpus/neume/` a largura de sistema hoje sai `w=0` no relatório de layout — isso é estado
  conhecido, não regressão sua.
- Ossia: `align_horizontally.dart` tem dois `TODO` dizendo que ossia chega depois. Esta é a tarefa;
  atualize os comentários em vez de deixá-los mentindo.

## Fora de escopo

- Desenhar as linhas suplementares (`View::DrawLedgerLines`, tarefa 05-11).
- `ScoreDefSetOssiaFunctor` (tarefa 04h).
- Instrumentar functors de outras tarefas: o seu patch cobre só os desta.
