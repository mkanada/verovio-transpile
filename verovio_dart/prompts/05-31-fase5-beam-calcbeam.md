# 05-31 — `beam.cpp`: portar `BeamSegment::CalcBeam` de verdade

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

`lib/src/rendering/view_beam.dart:8-16` declara, no cabeçalho do arquivo:

> `BeamSegment::CalcBeam` (beam.cpp:89) and `BeamDrawingInterface::InitCoords`
> (drawinginterface.cpp:140) are **re-implemented here in a reduced form** sufficient for the CMN
> beam corpus. The full ~1500-line engine (ledger-line handling, French style, mixed-beam center,
> cross-staff, tab) is **not ported**; the reduced version reproduces the exact geometry for simple
> horizontal and sloped beams that dominate `test/corpus/beam/` and **degrades gracefully** for the
> exotic cases.

Isso é exatamente o que a regra de ouro do `00-MESTRE.md` §1 proíbe: *"não redesenhe, não 'melhore'
o algoritmo, na dúvida faça igual ao original"*. Um bloco `Deviations from the C++:` documenta um
desvio que o **Dart obriga** (não tem `const`, não tem ponteiro); não autoriza reimplementar um
motor de 1.500 linhas em 234.

O tamanho do buraco: `origin/src/src/beam.cpp` tem **2.095 linhas**;
`origin/src/src/drawinginterface.cpp` (de onde vem `InitCoords`) tem 845. Em Dart,
`lib/src/model/beam_segment.dart` tem 204 linhas e é só a estrutura de dados; a matemática toda vive
em `_beamCalcBeam`, **234 linhas** dentro do arquivo de desenho — que também é o lugar errado: no
C++ ela é do **modelo** (`BeamSegment`), chamada por sete lugares diferentes, dos quais o `View` é só
um.

**264 dos 623 arquivos do corpus** (42%) contêm `<beam>`, `<beamSpan>` ou `<fTrem>`. Nenhum deles vai
fechar numericamente enquanto o motor for uma aproximação.

## Pré-condições

Tarefa **05-30** concluída (a virada precisa estar feita: `CalcBeam` consome e produz caixas).

```bash
cd verovio_dart
dart run tool/compare_svg.dart --all           # anote o ANTES
dart run tool/compare_svg.dart test/corpus/beam --mode=numeric --epsilon=0   # o ANTES da família
```

## Referência C++

| Arquivo:linha | Função |
|---|---|
| `origin/src/src/beam.cpp:89-570` | `BeamSegment::CalcBeam` — o corpo principal |
| `:571-679` | `CalcBeamInit` |
| `:680-913` | `CalcBeamInitForNotePair` |
| `:914-1116` | `CalcBeamPosition` |
| `:1117-1169` | `CalcBeamPlace` |
| `:1170-1199` | `CalcBeamPlaceTab` |
| `:1200-…` | `CalcBeamStemLength` e o resto dos helpers de `BeamSegment` |
| `origin/src/include/vrv/beam.h` | a interface completa de `BeamSegment` e `BeamElementCoord` — a lista do que falta |
| `origin/src/src/drawinginterface.cpp:140-…` | `BeamDrawingInterface::InitCoords` |
| `origin/src/src/view_beam.cpp:69, 119, 457` | os três chamadores no `View` |
| `origin/src/src/calcstemfunctor.cpp:73, 98, 202` | os três chamadores no layout — **é por aqui que a dívida da 04 (`calc_functors.dart:63`) se fecha** |
| `origin/src/src/beamspan.cpp:135` e `origin/src/src/adjustyposfunctor.cpp:96` | os outros dois |

Leia `beam.h` **antes** de `beam.cpp`: a lista de membros de `BeamSegment` e `BeamElementCoord` diz
de saída quanto do estado o Dart não tem.

## Onde o código deve morar

`CalcBeam` é método de `BeamSegment`, não do `View`. Mova-o para
`lib/src/model/beam_segment.dart` (ou um arquivo irmão, se ficar grande demais) com a mesma
assinatura do C++, e faça os **sete** chamadores usarem o mesmo método — hoje o layout
(`calc_functors.dart:63`) não chama nada e o desenho chama a versão reduzida. Enquanto houver duas
implementações, layout e desenho vão divergir entre si.

## Passo a passo

1. Grave o ANTES, global e da família `beam/`.
2. Leia `beam.h` e depois `beam.cpp` inteiro. Não comece a escrever antes: as sete funções
   compartilham estado em `m_beamElementCoordRefs` e a ordem em que o preenchem é o algoritmo.
3. Complete `BeamElementCoord` e `BeamSegment` (`beam_segment.dart`) com **todos** os membros de
   `beam.h`. Sem o estado completo, as funções seguintes viram adivinhação de novo.
4. Porte `InitCoords` (`drawinginterface.cpp:140`) por inteiro, no lugar certo
   (`BeamDrawingInterface`, não no `View`).
5. Porte as funções de `CalcBeam` na ordem em que o C++ as chama, uma por vez, medindo a família
   `beam/` a cada uma. Este é o tipo de tarefa em que a instrumentação do §6-bis paga: quando um
   `yBeam` não bater, instrumente `CalcBeamPosition` e compare valor a valor, em vez de ler o `.cpp`
   pela quarta vez.
6. Apague `_beamCalcBeam` e os helpers reduzidos de `view_beam.dart`, e faça os três `Draw*` e os
   três chamadores de layout apontarem para o método do modelo.
7. Feche a dívida de `lib/src/layout/calc_functors.dart:60-67` (`CalcStemFunctor::VisitBeam`,
   `calcstemfunctor.cpp:73`), que hoje só loga "beam segments are deferred to Phase 4".
8. Meça de novo e monte a tabela por família.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline (8)
- [ ] `dart test` verde, nenhum teste em `skip`
- [ ] `grep -n "reduced form\|degrades gracefully" lib/src/rendering/view_beam.dart` → **nenhum
      resultado**; o bloco `Deviations from the C++:` do arquivo só lista desvios que o Dart obriga
- [ ] `grep -rn "_beamCalcBeam\|_fTremCalcBeam" lib/src/` → nenhum resultado (uma implementação só,
      no modelo)
- [ ] `grep -rn "deferred to Phase 4" lib/src/layout/calc_functors.dart` → nenhum resultado
- [ ] Todos os membros de `BeamSegment` e `BeamElementCoord` de `beam.h` existem em Dart
- [ ] `dart run tool/compare_svg.dart test/corpus/beam --mode=numeric --epsilon=0` — o relatório traz
      o número de limpos antes e depois na família; a expectativa é fechar a **maioria** dos 61
- [ ] `dart run tool/compare_svg.dart --all` nos dois modos, com tabela ANTES × DEPOIS
- [ ] `test/bbox_parity_test.dart` não regride (as caixas dos beams entram nele)
- [ ] Cada caso exótico que continuar divergindo (French style, mixed beam, cross-staff, tab) tem
      entrada no relatório com arquivo, valor C++, valor Dart e função:linha — não uma nota genérica
      dizendo que é exótico
- [ ] Se instrumentou: patch `05-31` no `ORDER`, só acréscimos, `diff` de SVG vazio
- [ ] Relatório em `prompts/reports/05-31.md`
- [ ] `PLANO.md`: a linha do `view_beam` (hoje `05-17 ✓`) ganha a nota de que o motor só foi portado
      aqui

## Armadilhas conhecidas

- **`m_beamElementCoordRefs` é uma lista de ponteiros para coords que vivem no `Beam`.** Em Dart são
  referências; garanta que as duas listas não se dessincronizem, porque metade do algoritmo escreve
  por uma e lê pela outra.
- **`CalcBeamPlace` tem um caminho para tablatura** (`CalcBeamPlaceTab`) que não é opcional: os 5
  arquivos de `test/corpus/tab/` passam por ele.
- **`m_beamSlope` é `double` no C++**, e quase tudo mais é `int`. Onde o C++ multiplica o slope por
  um `int` e atribui a `int`, há truncamento — replique-o (§7, primeira causa mais comum).
- `CalcBeamStemLength` interage com `CalcStemFunctor`: depois de portar, os dois têm de concordar,
  senha haste desenhada num lugar e medida noutro.
- Espere `test/adjust_beams_test.dart` e os fixtures de `04d` mudarem. Se um fixture da Fase 4
  passar a divergir, é porque ele foi gravado contra o C++ **de verdade** e a aproximação é que
  batia por acaso — nesse caso o defeito é seu, não do fixture.
- Se a fatia estourar (é a maior da reabertura), pare no ponto coerente e registre pela §8.7 o que
  ficou: por exemplo, `CalcBeam` + `CalcBeamPosition` completos e `CalcBeamPlaceTab` para uma
  05-31b.

## Fora de escopo

- `view_beam.cpp` em si (os `Draw*`), que já está portado — só a troca de chamador.
- As outras dívidas "arrives with the rendering phase" (05-32).
- Refatoração de estilo do arquivo (05-35).
