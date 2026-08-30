# 06-04 — findfunctor.cpp (A): buscas básicas e comparadores

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Regra de números: critérios medem contra o estado corrente — nunca contra contagem fixa.

## Objetivo

Completar as buscas básicas de `findfunctor.cpp`: `FindByID`, `FindByComparison`, `FindAllByComparison`, `FindAllConstByComparison`, `FindAllBetween`, `FindNextChildByComparison`, `FindPreviousChildByComparison`, `FindExtremeByComparison` — como functors Dart ou completando os métodos equivalentes que o `object.dart` já expõe.

## Pré-condições

Tarefa **06-03** concluída.

```bash
cd verovio_dart
dart test test/reset_cycle_test.dart 2>&1 | tail -1   # verde
grep -n "findByID\|findAllByComparison\|findAllBetween" lib/src/model/object.dart | head   # o que já existe
```

## Referência C++

`origin/src/src/findfunctor.cpp:27-259` — `FindAllByComparisonFunctor` (com
`SetContinueDepthSearchForMatches`), `FindAllConstByComparisonFunctor`, `FindAllBetweenFunctor`,
`FindByComparisonFunctor`, `FindByIDFunctor`, `FindNextChildByComparisonFunctor`,
`FindPreviousChildByComparisonFunctor`, `FindExtremeByComparisonFunctor`. Headers:
`origin/src/include/vrv/findfunctor.h`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/find_functors.dart` (ou completar os métodos do `object.dart` — **decida pelo que já existe**, documente a escolha no relatório; o Dart pode ter escolhido métodos em vez de classes, e isso é desvio documentado, não defeito).
- **Criar** `test/find_functors_test.dart`.

## Passo a passo

1. Inventário: grep dos 8 nomes no C++ vs Dart — cole quem falta e em que forma (classe/método).
2. Porte o que falta, na forma que a base já adotou.
3. Testes: para cada busca, um caso positivo (acha) e um negativo (não acha), mais um caso de borda (primeiro/último filho; `continueDepthSearchForMatches` ligado e desligado).

## Critérios de aceite

- [ ] `dart analyze` — nenhum issue novo fora da baseline corrente
- [ ] `dart test` — verde, sem regressão, contagem só sobe
- [ ] Inventário dos 8 nomes: contraparte confirmada para todos (classe ou método documentado) — tabela colada
- [ ] Teste positivo + negativo + borda para cada busca
- [ ] `verify_phases_6_plus --fase=6` — 6.1 sem os `Find*` desta tarefa (cole a linha)
- [ ] Relatório em `prompts/reports/06-04.md`
- [ ] `PLANO.md`: sufixo de progresso no item de `findfunctor.cpp`

## Armadilhas conhecidas

- `FindAllBetween` usa ordem de **documento**, não de tempo — dois objetos em pentagramas diferentes têm ordem definida pela árvore.
- `FindNextChild`/`FindPreviousChild` operam sobre **irmãos**, não descendentes.
- As buscas de referência (06-05) dependem de back-links já montados na Fase 4 — não os refaça aqui.

## Fora de escopo

- `FindAllReferencedObjects`/`FindAllReferringObjects`/`FindElementInLayerStaffDef`/`AddToFlatList` (06-05) e `findlayerelementsfunctor.cpp` (06-06).
