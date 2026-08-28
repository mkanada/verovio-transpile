# 05-17 — view_beam.cpp: barras de ligação e tremolo medido

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `view_beam.cpp` inteiro: desenho de beams, segmentos de beam, tremolos medidos (`fTrem`) e
beams que cruzam sistemas (`beamSpan`).

## Pré-condições

Tarefa **05-16** concluída.

```bash
cd verovio_dart
grep -c "_notYet('DrawBeam'" lib/src/rendering/view_element.dart   # 1
dart test 2>&1 | tail -1     # verde, ≥ 480
```

## Referência C++

`origin/src/src/view_beam.cpp` (473 linhas):

| Linha | Função |
|---:|---|
| 34 | `DrawBeam` |
| 91 | `DrawFTrem` |
| 139 | `DrawFTremSegment` |
| 224 | `DrawBeamSegment` |
| 429 | `DrawBeamSpan` |

`DrawBeamSegment` (224-428) é o coração: 200 linhas que desenham cada nível de barra com as
sub-barras parciais. Leia-a inteira antes de escrever qualquer coisa.

Depende de `BeamSegment`/`BeamDrawingInterface` da Fase 4 (tarefa 04d) e do
`CalcSpanningBeamSpansFunctor` (tarefa 04f) para os beams que cruzam sistemas.

**Por que esta tarefa fecha divergências da Fase 4.** Os dados de `BeamSegment` só existem na
render pass do C++ — o relatório 04c deixou **4 valores de fixture divergentes** (`AdjustTupletsX/Y`
em `tuplet-001/010/015`) esperando exatamente por isto, e a 04d/04f registraram
`BeamDrawingInterface::InitCoords` como lacuna que bloqueia `BeamSpan.addSpanningSegment`. A
geometria desenhada por este arquivo sai inteira nos goldens de SVG, então **não há extração
preventiva aqui** (`00-MESTRE.md` §6-bis, "Quando extrair") — mas os fixtures da 04c passam a ter
os dados de que precisam: reexecute-os ao fechar (critério de aceite abaixo).

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view_beam.dart` (`part of` `view.dart`).
- **Alterar** `lib/src/rendering/view.dart` e `view_element.dart` (trocar o `_notYet`).
- **Criar** `test/view_beam_test.dart`.

## Passo a passo

1. Leia as 473 linhas.
2. Porte `DrawBeam`, depois `DrawBeamSegment`.
3. Porte `DrawFTrem` e `DrawFTremSegment`.
4. Porte `DrawBeamSpan`.
5. Testes: `test/corpus/beam/` tem **61 arquivos** — é a maior categoria do corpus e o melhor
   termômetro desta tarefa. Use também `test/corpus/beamspan/` (6), `test/corpus/ftrem/` (2),
   `test/corpus/cross-staff/` (24, beams entre pentagramas).
6. **Reexecute os fixtures da 04c** (`dart test -n 'AdjustTuplets'` ou o arquivo de teste da
   04c): os 4 valores que divergiam (`tuplet-001/010/015`) têm de bater agora — os dados de
   `BeamSegment` que faltavam são exatamente os que esta tarefa passa a produzir em produção. Se
   algum continuar divergindo, o protocolo de re-instrumentação do `00-MESTRE.md` §6-bis vale —
   e o relatório registra a hipótese de causa.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 490 testes**
- [ ] `dart run tool/compare_svg.dart test/corpus/beam --mode=structural` reporta **≥ 40 de 61** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/beamspan --mode=structural` reporta **≥ 4 de 6** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` maior que na tarefa 05-16
- [ ] Ao menos 5 arquivos de `test/corpus/beam/` passam também em `--mode=numeric --epsilon=0`;
      o relatório diz quais e quantos
- [ ] Os fixtures da 04c re-executados: os **4 valores divergentes** (`AdjustTupletsX/Y`,
      `tuplet-001/010/015`) passam a bater com epsilon 0 — ou divergência documentada com hipótese
      nomeando função e linha do C++
- [ ] Relatório em `prompts/reports/05-17.md`
- [ ] `PLANO.md`: checkbox de `view_beam.cpp` marcado

## Armadilhas conhecidas

- **Sub-barras parciais** (a barra curta que aponta para um lado só, em ritmos pontuados): a regra de
  para que lado ela aponta está em `DrawBeamSegment` e depende do vizinho. É o erro mais comum.
- A inclinação do beam foi calculada na Fase 4; aqui é só desenho. Se a inclinação estiver errada,
  o bug é do `CalcStemFunctor`/`AdjustBeamsFunctor`.
- Cross-staff: o beam muda de sistema de coordenadas no meio. `test/corpus/cross-staff/` cobre.
- `DrawFTremSegment` desenha barras **soltas** entre duas notas, não ligadas às hastes — geometria
  diferente da do beam.
- `DrawBeamSpan` usa a pilha de offsets do `View` (tarefa 05-06) para o segmento no segundo sistema.

## Fora de escopo

- `view_tuplet.cpp` e `view_slur.cpp` (tarefa 05-18).
