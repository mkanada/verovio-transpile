# 05-22 — view_control.cpp (C): ornamentos, símbolos isolados e elementos de sistema

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar `view_control.cpp`: arpejos, respirações, cesuras, fermatas, dedilhados, glissandos,
mordentes, pedais, marcas de repetição, trinados, grupetos, inflexões de altura, anotações de
partitura e os elementos de sistema (finais de repetição). Ao final não sobra nenhum `_notYet`
em `view_control.dart`.

## Pré-condições

Tarefa **05-21** concluída.

```bash
cd verovio_dart
grep -c "_notYet('DrawArpeg'" lib/src/rendering/view_control.dart   # 1
dart test 2>&1 | tail -1     # verde, ≥ 536
```

## Referência C++

`origin/src/src/view_control.cpp`, faixas:

| Linha | Função | Linha | Função |
|---:|---|---:|---|
| 464 | `DrawAnnotScore` | 2145 | `DrawGliss` |
| 964 | `DrawPitchInflection` | 2351 | `DrawMordent` |
| 1518 | `DrawArpeg` | 2507 | `DrawPedal` |
| 1598 | `DrawArpegEnclosing` | 2671 | `DrawRepeatMark` |
| 1641 | `DrawBreath` | 2798 | `DrawTrill` |
| 1697 | `DrawCaesura` | 2900 | `DrawTurn` |
| 1999 | `DrawFermata` | 3014 | `DrawSystemElement` |
| 2092 | `DrawFing` | 3048 | `DrawEnding` |

`DrawEnding` (3048-3264) tem o `vrv_cast<BBoxDeviceContext *>(dc)` da linha 3055 — reproduza o
caminho especial.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/view_control.dart`.
- **Alterar** `test/view_control_test.dart`.

## Passo a passo

1. Leia as faixas.
2. Porte os ornamentos: `DrawMordent`, `DrawTrill`, `DrawTurn`. Cada um trata acidentes acima e
   abaixo do glifo (`@accidupper`/`@accidlower`) e as formas do `@form`.
3. Porte `DrawArpeg` e `DrawArpegEnclosing`.
4. Porte `DrawFermata`, `DrawBreath`, `DrawCaesura`, `DrawFing`, `DrawGliss`,
   `DrawPitchInflection`, `DrawPedal`, `DrawRepeatMark`, `DrawAnnotScore`.
5. Porte `DrawSystemElement` e `DrawEnding` (finais de repetição, com colchete e número).
6. Testes: `test/corpus/arpeg/` (7), `test/corpus/fermata/` (7), `test/corpus/trill/` (8),
   `test/corpus/turn/` (6), `test/corpus/mordent/` (5), `test/corpus/pedal/` (6),
   `test/corpus/gliss/` (6), `test/corpus/breath/` (2), `test/corpus/fing/` (2),
   `test/corpus/ending/` (3), `test/corpus/repeatmark/` (2), `test/corpus/ornam/` (1),
   `test/corpus/annot/` (7), `test/corpus/cpmark/`.
7. **Marco:** `view_control.cpp` inteiro portado. Rode `dart run tool/compare_svg.dart --all` em
   ambos os modos e registre.
8. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 552 testes**
- [ ] `grep -c "_notYet(" lib/src/rendering/view_control.dart` = **0**
- [ ] Toda função de `origin/src/src/view_control.cpp` tem contraparte — prove com o diff de nomes
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` reporta **≥ 380 de 623** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=numeric --epsilon=0` roda e o relatório traz o número
- [ ] Relatório em `prompts/reports/05-22.md`
- [ ] `PLANO.md`: checkbox de `view_control.cpp` (C) marcado

## Armadilhas conhecidas

- Ornamentos com acidente: o acidente vai acima **e** abaixo do glifo, em tamanho reduzido, com um
  espaçamento específico. Três coisas para errar.
- `DrawEnding`: o colchete do final de repetição cruza compassos e pode cruzar sistemas — usa
  `DrawTimeSpanningElement` da tarefa 05-20.
- `DrawArpegEnclosing` desenha o parêntese/colchete opcional em volta do arpejo.
- `DrawPitchInflection` é a curva de bend (guitarra/jazz); geometria própria.
- `DrawPedal` tem formas de linha e de símbolo, com `DrawPedalLine` (tarefa 05-20) para a linha.
  Se a linha não aparecer, verifique se a 05-20 ligou o despachante certo.
- Se `compare_svg` não chegar a 380/623, **não relaxe o critério**. Investigue: nesse ponto o único
  desenho que ainda falta é mensural, neume e tablatura (categorias `ligature` 50, `mensural` 25,
  `neume` 6, `tab` 5 = 86 arquivos), o que ainda deixaria ~537 possíveis.

## Fora de escopo

- `view_mensural.cpp` (05-23), `view_neume.cpp`/`view_tab.cpp` (05-24).
