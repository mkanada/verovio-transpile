# 06-06 — findlayerelementsfunctor.cpp: buscas por intervalo de tempo

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Regra de números: critérios medem contra o estado corrente — nunca contra contagem fixa.

## Objetivo

Portar os 4 functors de `findlayerelementsfunctor.cpp`: `LayersInTimeSpanFunctor`,
`LayerElementsInTimeSpanFunctor`, `FindSpannedLayerElementsFunctor`,
`GetRelativeLayerElementFunctor` — as buscas por intervalo de tempo que o editor e o MIDI consomem.

## Pré-condições

Tarefa **06-05** concluída.

```bash
cd verovio_dart
dart test test/find_functors_test.dart 2>&1 | tail -1   # verde
ls lib/src/layout/find_functors.dart                     # onde a 06-04/05 trabalhou
```

## Referência C++

`origin/src/src/findlayerelementsfunctor.cpp` (280 linhas) — os 4 functors nominais, com
`SetEvent`, `SetMinMaxPos`, `SetMinMaxLayerN` (encontre cada um com
`grep -n "Functor::" origin/src/src/findlayerelementsfunctor.cpp`).

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/layout/find_functors.dart` (ou o equivalente da série).
- **Criar** `test/find_layer_elements_test.dart`.

## Passo a passo

1. Inventário dos 4 nomes — cole faltantes.
2. Porte cada functor, citando o C++.
3. Testes: intervalo que pega notas de duas camadas; `FindSpannedLayerElements` com filtros de pentagrama/camada ligados e desligados; `GetRelativeLayerElement` atravessando compasso e dentro do compasso.

## Critérios de aceite

- [ ] `dart analyze` — nenhum issue novo fora da baseline corrente
- [ ] `dart test` — verde, sem regressão, contagem só sobe
- [ ] Inventário dos 4 nomes completo — tabela colada
- [ ] Testes de intervalo semiaberto, filtros e travessia de compasso passam
- [ ] `verify_phases_6_plus --fase=6` — 6.1 sem os 4 nomes (cole a linha)
- [ ] Relatório em `prompts/reports/06-06.md`
- [ ] `PLANO.md`: checkbox de `findlayerelementsfunctor.cpp` marcado

## Armadilhas conhecidas

- Os intervalos do C++ são **semiabertos** `[start, end)` — um `<=` no lugar de `<` inclui a nota errada e o erro só aparece no MIDI, muito depois.
- `Fraction` do C++ compara exato; não converta para `double` no meio do caminho.
- `FindSpannedLayerElements` tem filtros por pentagrama e camada; ignorá-los faz um slur "achar" notas de outro pentagrama.
- `GetRelativeLayerElement` pode atravessar compassos, dependendo do parâmetro.

## Fora de escopo

- `convertfunctor.cpp` (a partir da 06-31).
