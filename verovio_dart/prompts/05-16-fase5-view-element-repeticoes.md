# 05-16 — view_element.cpp (D): repetições, tremolos, grace groups, sílabas e versos

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar `view_element.cpp`: sinais de repetição de compasso e de tempo, tremolo de haste, grupos de
apojaturas, elemento genérico, sílabas de letra e versos. Ao final não sobra nenhum `_notYet` de
elemento de camada CMN.

## Pré-condições

Tarefa **05-15** concluída.

```bash
cd verovio_dart
grep -c "_notYet('DrawBTrem'" lib/src/rendering/view_element.dart   # 1
dart test 2>&1 | tail -1     # verde, ≥ 468
```

## Referência C++

`origin/src/src/view_element.cpp`, faixas:

| Linha | Função |
|---:|---|
| 434 | `DrawBarLine` (a sobrecarga de elemento de camada — **não** a de `view_page.cpp:815`) |
| 477 | `DrawBeatRpt` |
| 509 | `DrawBTrem` |
| 938 | `DrawGenericLayerElement` |
| 952 | `DrawGraceGrp` |
| 968 | `DrawHalfmRpt` |
| 1252 | `DrawMRpt` |
| 1293 | `DrawMRpt2` |
| 1450 | `DrawMultiRpt` |
| 1822 | `DrawSyl` |
| 1914 | `DrawVerse` |
| 2150 | `GetFYRel` |
| 2181 | `GetSylYRel` |

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/view_element.dart`.
- **Alterar** `test/view_element_test.dart`.

## Passo a passo

1. Leia as faixas.
2. Porte a família de repetição: `DrawBeatRpt`, `DrawHalfmRpt`, `DrawMRpt`, `DrawMRpt2`,
   `DrawMultiRpt` (usa `DrawMRptPart`, já portada na 05-13).
3. Porte `DrawBTrem` (509-580) — tremolo de haste, com o número de barras vindo de `@unitdur`.
4. Porte `DrawGraceGrp` e `DrawGenericLayerElement`.
5. Porte `DrawSyl` (1822-1913) e `DrawVerse` (1914-1980), mais os helpers `GetFYRel` e `GetSylYRel`.
   Sílaba e verso dependem de medição de texto real — agora que o device context está completo,
   os números devem bater.
6. Porte a sobrecarga de `DrawBarLine` de elemento de camada (434-476).
7. Testes: `test/corpus/repeats/` (8), `test/corpus/btrem/` (6), `test/corpus/gracenote/` (27),
   `test/corpus/lyric/` (16).
8. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 480 testes**
- [ ] `grep -c "_notYet('Draw" lib/src/rendering/view_element.dart` cobre **apenas** beam, tuplet,
      slur, mensural, neume e tab (as tarefas 05-17, 05-18, 05-23, 05-24) — nenhum elemento CMN sobrou
- [ ] `dart run tool/compare_svg.dart test/corpus/lyric --mode=structural` reporta **≥ 10 de 16** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/gracenote --mode=structural` reporta **≥ 18 de 27** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` maior que na tarefa 05-15
- [ ] Relatório em `prompts/reports/05-16.md`
- [ ] `PLANO.md`: checkbox de `view_element.cpp` (D) marcado

## Armadilhas conhecidas

- **Três `DrawBarLine`** no total no C++: `view_page.cpp:815`, `view_element.cpp:434` e uma no
  `DrawBarLines`. Não confunda.
- `DrawSyl` desenha a sílaba **e** registra o conector (hífen/extensor) que `DrawSylConnector`
  (`view_control.cpp:1394`, tarefa 05-20) vai desenhar depois. A parte de registro é desta tarefa.
- `GetSylYRel` depende do verso e do `AdjustSylSpacingFunctor` (tarefa 04e). Se o Y sair errado,
  verifique a Fase 4 antes.
- `DrawMRpt2` é a repetição de **dois** compassos; o glifo e o posicionamento são diferentes do
  `DrawMRpt`.
- Grace groups: o `AdjustGraceXPosFunctor` da Fase 4 já posicionou; aqui é só desenho.

## Fora de escopo

- `view_beam.cpp` (05-17), `view_tuplet.cpp`/`view_slur.cpp` (05-18).
