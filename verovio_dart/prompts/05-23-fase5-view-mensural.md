# 05-23 — view_mensural.cpp: notação mensural e ligaduras

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `view_mensural.cpp` inteiro: notas mensurais, sinais de mensuração, ligaduras (retas e
oblíquas), plica, proporções.

## Pré-condições

Tarefa **05-22** concluída.

```bash
cd verovio_dart
grep -c "_notYet(" lib/src/rendering/view_control.dart   # 0
dart test 2>&1 | tail -1     # verde, ≥ 552
```

## Referência C++

`origin/src/src/view_mensural.cpp` (751 linhas):

| Linha | Função | Linha | Função |
|---:|---|---:|---|
| 33 | `s_drawingLigY[2]` (estado estático) | 465 | `DrawDotInLigature` |
| 34 | `s_drawingLigObliqua` (estado estático) | 511 | `DrawPlica` |
| 40 | `DrawMensuralNote` | 567 | `DrawProportFigures` |
| 80 | `DrawMensur` | 603 | `DrawProport` |
| 162 | `DrawMensuralStem` | 614 | `CalcBrevisPoints` |
| 206 | `DrawMaximaToBrevis` | 659 | `CalcObliquePoints` |
| 285 | `DrawLigature` | 725 | `GetMensuralStemDir` |
| 329 | `DrawLigatureNote` | | |

**As duas variáveis estáticas de arquivo (linhas 33-34) carregam estado entre chamadas.**
Em Dart, variáveis de topo de biblioteca dentro do `part` fazem o mesmo — mas documente isso como
desvio, porque estado global é frágil. Não as transforme em campos de `View` sem verificar se o C++
as reseta em algum ponto (`grep -n "s_drawingLig" origin/src/src/view_mensural.cpp`).

O modelo mensural já existe em Dart: `lib/src/model/mensur.dart`, `lib/src/layout/mensural_neume.dart`,
`lib/src/layout/cast_off_mensural.dart`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view_mensural.dart` (`part of` `view.dart`).
- **Alterar** `lib/src/rendering/view.dart` e `view_element.dart`.
- **Criar** `test/view_mensural_test.dart`.

## Passo a passo

1. Leia as 751 linhas.
2. Porte `GetMensuralStemDir`, `CalcBrevisPoints` e `CalcObliquePoints` primeiro — são os helpers
   geométricos de que tudo depende.
3. Porte `DrawMensuralNote`, `DrawMensuralStem`, `DrawMaximaToBrevis`, `DrawPlica`.
4. Porte a família de ligadura: `DrawLigature`, `DrawLigatureNote`, `DrawDotInLigature`, com o
   estado estático de duas passadas para a oblíqua.
5. Porte `DrawMensur`, `DrawProport`, `DrawProportFigures`.
6. Testes: `test/corpus/ligature/` (**50 arquivos**, a segunda maior categoria),
   `test/corpus/mensural/` (25), `test/corpus/mensur/` (8).
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 564 testes**
- [ ] As 13 funções de `view_mensural.cpp` têm contraparte — prove com o diff de nomes
- [ ] `dart run tool/compare_svg.dart test/corpus/ligature --mode=structural` reporta **≥ 35 de 50** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/mensural --mode=structural` reporta **≥ 16 de 25** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` maior que na tarefa 05-22
- [ ] Relatório em `prompts/reports/05-23.md`, documentando como o estado estático foi tratado
- [ ] `PLANO.md`: checkbox de `view_mensural.cpp` marcado

## Armadilhas conhecidas

- **`s_drawingLigObliqua` marca a primeira passada de uma oblíqua**: a ligadura oblíqua é desenhada
  em duas chamadas, e a primeira só guarda coordenadas. Se você desenhar na primeira, sai dobrado.
- `s_drawingLigY[2]` guarda os Y das duas notas da oblíqua entre as chamadas.
- `DrawMensur` trata `@sign`, `@slash`, `@dot`, `@orient`, `@num`/`@numbase` — muitas combinações.
  `test/corpus/mensur/` cobre.
- A direção da haste mensural **não** segue a regra CMN; `GetMensuralStemDir` tem a regra própria.
- `test/corpus/ligature/` é a categoria com mais arquivos depois de `beam`; se ela não subir, esta
  tarefa não cumpriu o objetivo.

## Fora de escopo

- `view_neume.cpp` e `view_tab.cpp` (tarefa 05-24).
