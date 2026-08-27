# 04d — AdjustBeamsFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `AdjustBeamsFunctor`: o ajuste vertical das barras de ligação (beams) contra os elementos
de camada que ficam entre elas e o pentagrama. Ao final, uma barra deixa de atravessar notas,
pausas ou claves que estejam no seu caminho.

## Pré-condições

Tarefas **04-00** e **04a**–**04c** concluídas.

```bash
ls verovio_dart/test/fixtures/cpp/04c/tuplet-001.mei.jsonl   # o fixture da 04c existe
cd verovio_dart
ls lib/src/layout/adjust_tuplets.dart
dart test 2>&1 | tail -1     # verde, ≥ 307
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/include/vrv/adjustbeamsfunctor.h` | — | `class AdjustBeamsFunctor`. Visits: `Beam`, `BeamEnd`, `Clef`, `FTrem`, `FTremEnd`, `LayerElement`, `Rest`. |
| `origin/src/src/adjustbeamsfunctor.cpp` | 434 | todos os visits acima. |
| `origin/src/src/page.cpp:509-608` | — | `AdjustBeamsFunctor adjustBeams(doc);` na fase vertical, logo depois de `AdjustArticWithSlurs`. |

Classes de apoio que o functor usa: `BeamSegment`, `BeamDrawingInterface` (`origin/src/include/vrv/beam.h`).
Confirme o que já existe em Dart antes de portar:

```bash
grep -rn "class BeamSegment\|class BeamDrawingInterface\|mixin BeamDrawingInterface" lib/src/
```

## Dados de referência do C++

> Convenções em `00-MESTRE.md` §6-bis e `cpp_probe/README.md`. Instrumentação é **só acréscimo**:
> nenhum patch pode remover ou alterar uma linha do C++. Os números de linha abaixo são os da
> árvore **limpa**; com os patches anteriores aplicados eles andam algumas linhas, então localize
> sempre por nome com `grep -n` em `build-probe/src/`.

**Valores a medir**

- `AdjustBeamsFunctor`: para cada `Beam`, o Y dos **dois extremos** do `BeamSegment`
  (`m_beamElementCoordRefs` primeiro e último, ou `m_startingY`/`m_beamSlope`) antes e depois; o
  `m_overlapMargin` acumulado; e o estado de aninhamento (`m_outerBeam`) a cada entrada/saída.
- O **retorno** de `CalcLayerOverlap` e de `AdjustOverlapToHalfUnit` — são os dois números que
  decidem o deslocamento, e onde a divisão inteira do C++ costuma divergir do Dart.
- Para cross-staff: qual `Staff` foi tomado como referência e o seu `drawingY`.

**Funções a instrumentar**

| Onde | O quê |
|---|---|
| `origin/src/src/adjustbeamsfunctor.cpp:41` `VisitBeam` | Y dos extremos na entrada, `m_outerBeam` |
| `origin/src/src/adjustbeamsfunctor.cpp:90` `VisitBeamEnd` | **onde o ajuste é aplicado**: Y dos extremos na saída e `m_overlapMargin` |
| `origin/src/src/adjustbeamsfunctor.cpp:125` `VisitClef` | o caso de mudança de clave no meio do beam |
| `origin/src/src/adjustbeamsfunctor.cpp:162` `VisitFTrem` / `:199` `VisitFTremEnd` | o tremolo, que compartilha a geometria de beam |
| `origin/src/src/adjustbeamsfunctor.cpp:232` `VisitLayerElement` | o elemento avaliado e o overlap que ele contribuiu |
| `origin/src/src/adjustbeamsfunctor.cpp:295` `VisitRest` | a pausa dentro do beam |
| `origin/src/src/adjustbeamsfunctor.cpp:351` `CalcLayerOverlap` | **o retorno** |
| `origin/src/src/adjustbeamsfunctor.cpp:426` `AdjustOverlapToHalfUnit` | **o retorno** e o `unit` recebido |
| `origin/src/src/page.cpp:544` | `probe::BeginPass("AdjustBeams")` |

**Arquivos do corpus** (fixados aqui para o conjunto não variar entre execuções)

| Arquivo | Por quê |
|---|---|
| `test/corpus/beam/beam-001.mei` | beam simples, 5 notas — o caso base |
| `test/corpus/beam/beam-061.mei` | **o único arquivo de `beam/` com pausa dentro do beam** (confira com `grep -l` se duvidar) |
| `test/corpus/cross-staff/cross-staff-001.mei` | beam cruzando pentagrama: o Y de referência muda de staff |
| `test/corpus/clef/clef-004.mei` | **3 mudanças de clave dentro da camada** — exercita `VisitClef` |

**Fixtures a gravar**: `test/fixtures/cpp/04d/<nome-do-arquivo>.jsonl`

**Comandos**

```bash
# a partir da RAIZ do workspace, não de verovio_dart/
cpp_probe/sync.sh
# edite build-probe/src/src/{adjustbeamsfunctor,page}.cpp — só fprintf, nada de lógica
cpp_probe/mkpatch.sh 04d        # grava cpp_probe/patches/04d.patch
cpp_probe/build.sh 04d          # incremental (~1 min) se build-probe/ já existe

for f in beam/beam-001 beam/beam-061 cross-staff/cross-staff-001 clef/clef-004; do
  n=$(basename $f)
  cpp_probe/run.sh 04d "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/04d/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
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

- **Criar** `lib/src/layout/adjust_beams.dart` — `AdjustBeamsFunctor`.
- **Alterar** `lib/src/model/doc.dart` — ligar na fase vertical, na posição do `page.cpp`;
  atualizar o comentário de "skipped" em `:461-462` e `:505`.
- **Criar** `test/adjust_beams_test.dart`.

## Passo a passo

1. Leia `adjustbeamsfunctor.h` e as 434 linhas do `.cpp` inteiras.
2. Levante o que falta das classes de apoio (`BeamSegment`, campos de `BeamDrawingInterface`) com o
   grep acima. Se faltar campo, acrescente-o na classe Dart correspondente com doc comment citando
   o C++ — mas **só o que este functor usa**.
2-bis. **Extraia os dados de referência do C++ antes de escrever Dart.** Instrumente com `fprintf` as
   funções listadas em *Dados de referência do C++* e rode os comandos daquela seção. Confira que o
   binário instrumentado ainda produz SVG idêntico ao do limpo. **Leia os fixtures antes de escrever
   a primeira linha de Dart** — eles dizem o que o functor faz de verdade, caso a caso, melhor do
   que a leitura do `.cpp`.
3. Porte `AdjustBeamsFunctor` em `adjust_beams.dart`.
4. Ligue no `doc.dart`.
5. Testes: use **os quatro arquivos fixados** em *Dados de referência do C++*
   (`beam/beam-001.mei`, `beam/beam-061.mei`, `cross-staff/cross-staff-001.mei`,
   `clef/clef-004.mei`). Asserte a coordenada Y dos extremos do `BeamSegment` contra o fixture,
   com epsilon 0.
6. Verificação.

**Protocolo de re-instrumentação — leia antes de "consertar" qualquer número.** Se um valor do Dart
não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao patch, instrumente mais
fundo dentro da função divergente (valores intermediários, o ramo do `if` tomado, o resultado de
cada helper), rode `cpp_probe/mkpatch.sh 04d && cpp_probe/build.sh 04d`, regere o fixture e
compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a divergência
irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
herda o instrumento, não o problema.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 313 testes**
- [ ] `grep -c "class AdjustBeamsFunctor" lib/src/layout/adjust_beams.dart` = 1
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.`, timemaps **≥ 24/30**,
      `beam/beam-001.mei` com `Layout OK` e todos os `PASS`
- [ ] `cpp_probe/patches/04d.patch` versionado, contendo **apenas** acréscimos de instrumentação
      (`grep -c '^-[^-]' cpp_probe/patches/04d.patch` = 0) — cole o resumo do `mkpatch.sh` no relatório
- [ ] `cpp_probe/build.sh 04d && cpp_probe/run.sh 04d …` reproduz os fixtures do zero, e o binário
      instrumentado produz SVG idêntico ao do binário limpo para os arquivos desta tarefa
      (`diff` vazio, colado no relatório)
- [ ] N valores do fixture comparados com o Dart em epsilon 0; o relatório traz N, quantos batem, e
      cada divergência restante com hipótese de causa nomeando função e linha do C++
- [ ] Relatório em `prompts/reports/04d.md`
- [ ] `PLANO.md`: `AdjustBeams` removido da lista de faltantes

## Armadilhas conhecidas

- `VisitFTrem`/`VisitFTremEnd` existem porque o tremolo compartilha a geometria de beam. Não pule.
- `VisitClef` está lá para o caso de uma mudança de clave no meio do beam. Caso raro, mas
  `clef/clef-004.mei` — um dos quatro arquivos fixados — tem 3 delas dentro da camada.
- O functor trabalha com `m_outerBeam`/estado de aninhamento — beams dentro de beams. Copie a
  gestão de estado ao pé da letra.
- Cross-staff: a coordenada Y de referência muda de pentagrama. Use `cross-staff/cross-staff-001.mei`,
  que é o arquivo fixado desta tarefa; os outros 23 de `test/corpus/cross-staff/` servem se você
  quiser conferir um caso, mas o fixture cobre só o fixado.
- Divisão inteira: coordenadas de beam são `int` em unidades de desenho. `~/`, não `/`.

## Fora de escopo

- `view_beam.cpp` (o **desenho** do beam) — é a tarefa 05-17, muito depois.
- `CalcSpanningBeamSpans` (tarefa 04f).
- Instrumentar functors de outras tarefas: o seu patch cobre só o desta.
