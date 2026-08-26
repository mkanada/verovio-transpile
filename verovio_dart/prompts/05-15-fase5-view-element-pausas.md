# 05-15 — view_element.cpp (C): pausas, espaços, ponto, custos e claves

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar o desenho de todas as formas de pausa, dos espaços, do ponto isolado, do custos e da clave.

## Pré-condições

Tarefa **05-14** concluída.

```bash
cd verovio_dart
grep -c "_notYet('DrawRest'" lib/src/rendering/view_element.dart   # 1
dart test 2>&1 | tail -1     # verde, ≥ 456
```

## Referência C++

`origin/src/src/view_element.cpp`, faixas:

| Linha | Função |
|---:|---|
| 671 | `DrawClef` |
| 746 | `DrawClefEnclosing` |
| 769 | `DrawCustos` |
| 809 | `DrawDot` |
| 1195 | `DrawMRest` |
| 1313 | `DrawMSpace` |
| 1329 | `DrawMultiRest` |
| 1583 | `DrawRest` |
| 1676 | `DrawSpace` |

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/view_element.dart`.
- **Alterar** `test/view_element_test.dart`.

## Passo a passo

1. Leia as faixas.
2. Porte `DrawClef` (671-745) e `DrawClefEnclosing` (746-768). A clave trata `@shape`, `@line`,
   `@dis`/`@dis.place` (oitavação) e clave de mudança em tamanho reduzido.
3. Porte `DrawRest` (1583-1675): pausas de todas as durações, com posicionamento vertical
   automático ou por `@loc`/`@oloc`.
4. Porte `DrawMRest` (pausa de compasso inteiro) e `DrawMultiRest` (1329-1449, a mais longa:
   desenha a barra de compassos múltiplos com o número em cima, ou o bloco de pausas antigas).
5. Porte `DrawMSpace`, `DrawSpace`, `DrawDot`, `DrawCustos`.
6. Testes: `test/corpus/rest/` (21), `test/corpus/clef/` (7), `test/corpus/custos/` (dos 623),
   `test/corpus/space/` (2), `test/corpus/mrest/`.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 468 testes**
- [ ] `dart run tool/compare_svg.dart test/corpus/rest --mode=structural` reporta **≥ 14 de 21** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/clef --mode=structural` reporta **≥ 5 de 7** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` maior que na tarefa 05-14
- [ ] Nenhum `_notYet` das funções desta tarefa restou
- [ ] Relatório em `prompts/reports/05-15.md`
- [ ] `PLANO.md`: checkbox de `view_element.cpp` (C) marcado

## Armadilhas conhecidas

- `DrawMultiRest` tem dois modos (barra moderna com número, ou blocos de pausas ao estilo antigo),
  escolhidos por opção. Porte os dois; use o default do C++.
- A posição vertical automática da pausa depende da camada (uma camada = centro; duas camadas =
  acima/abaixo). `CalcAlignmentPitchPosFunctor` da Fase 4 já resolveu isso — `DrawRest` só usa.
- `DrawCustos` desenha o glifo de guia no fim do sistema; a forma depende da notação (CMN vs.
  mensural vs. neumática).
- Clave em tamanho de mudança (`cue`) usa fator de escala diferente.

## Fora de escopo

- Repetições, tremolos, grace groups (tarefa 05-16).
