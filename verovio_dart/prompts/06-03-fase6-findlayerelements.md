# 06-03 — findlayerelementsfunctor.cpp: buscas por intervalo de tempo

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os functors que localizam elementos de camada por intervalo de tempo — a base de que a
geração de MIDI, a transposição seletiva e o editor precisam.

## Pré-condições

Tarefa **06-02** concluída.

```bash
cd verovio_dart
ls lib/src/model/find_references.dart
dart test 2>&1 | tail -1     # verde, ≥ 602
```

## Referência C++

`origin/src/include/vrv/findlayerelementsfunctor.h` e
`origin/src/src/findlayerelementsfunctor.cpp` (280 linhas). Classes:

- `LayerElementsInTimeSpanFunctor` — elementos de camada dentro de um intervalo `[start, end)`.
- `LayersInTimeSpanFunctor` — camadas ativas num intervalo.
- `FindSpannedLayerElementsFunctor` — elementos cobertos por um elemento que se estende no tempo
  (usado por slur, hairpin, octave para saber o que evitar).
- `GetRelativeLayerElementFunctor` — elemento vizinho na mesma camada, numa direção.
- `FindElementInLayerStaffDefFunctor` — se você já o portou na tarefa 06-02, **não duplique**;
  mova-o para cá e diga isso no relatório.

Os intervalos usam `Fraction` — que já existe em Dart (`lib/src/core/fraction.dart`).

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/find_layer_elements.dart`.
- **Alterar** `lib/src/layout/functor.dart` se algum `ClassId` faltar em `kAcceptChain`.
- **Criar** `test/find_layer_elements_test.dart`.

## Passo a passo

1. Leia o header e as 280 linhas do `.cpp`.
2. Porte os cinco functors.
3. Confira se algum deles é chamado por código já portado que hoje tem um `TODO` ou um caminho
   simplificado: `grep -rn "LayerElementsInTimeSpan\|FindSpannedLayerElements\|GetRelativeLayerElement" lib/src/`.
   Se houver, ligue-os agora e apague o `TODO`.
4. Testes: intervalos que pegam 0, 1 e N elementos; um slur sobre 3 notas
   (`test/corpus/slur/slur-001.mei`) para `FindSpannedLayerElements`; vizinho anterior e seguinte
   para `GetRelativeLayerElement`, incluindo os casos de borda (primeiro e último da camada).
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 612 testes**
- [ ] As 5 classes de `findlayerelementsfunctor.h` têm contraparte — prove com o diff de nomes
- [ ] Um teste cobre cada caso de borda de `GetRelativeLayerElement` (primeiro, último, camada vazia)
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/06-03.md`
- [ ] `PLANO.md`: checkbox de `findlayerelementsfunctor.cpp` marcado

## Armadilhas conhecidas

- Os intervalos do C++ são semiabertos `[start, end)`. Um `<=` no lugar de `<` inclui a nota errada
  e o erro só aparece no MIDI, muito depois.
- `Fraction` do C++ compara exato; não converta para `double` no meio do caminho.
- `FindSpannedLayerElementsFunctor` tem filtros por pentagrama e camada; ignorá-los faz um slur
  evitar notas de outro pentagrama.
- `GetRelativeLayerElementFunctor` pode atravessar compassos, dependendo do parâmetro.

## Fora de escopo

- `convertfunctor.cpp` (tarefas 06-04 a 06-06).
