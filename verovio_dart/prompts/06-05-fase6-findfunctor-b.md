# 06-05 — findfunctor.cpp (B): referências, staffDef de camada e flat list

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Regra de números: critérios medem contra o estado corrente — nunca contra contagem fixa.

## Objetivo

Portar as buscas por referência: `FindAllReferencedObjectsFunctor`, `FindAllReferringObjectsFunctor`, `FindElementInLayerStaffDefFunctor` e `AddToFlatListFunctor`.

## Pré-condições

Tarefa **06-04** concluída.

```bash
cd verovio_dart
dart test test/find_functors_test.dart 2>&1 | tail -1   # verde
grep -n "PrepareLinking\|m_refs\|references" lib/src/model/object.dart | head   # os back-links da Fase 4
```

## Referência C++

`origin/src/src/findfunctor.cpp:259-477` — `FindAllReferencedObjectsFunctor` (+`AddObject`),
`FindAllReferringObjectsFunctor` (varre `@startid`/`@endid`/`@plist`… via `ClassId` por atributo),
`FindElementInLayerStaffDefFunctor` (visita `Layer` e `Score`), `AddToFlatListFunctor`.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/layout/find_functors.dart` (ou o equivalente adotado na 06-04).
- **Alterar** `test/find_functors_test.dart`.

## Passo a passo

1. Inventário dos 4 nomes — cole faltantes.
2. Porte. As buscas de referência usam os back-links que `PrepareLinkingFunctor`/`PreparePlistFunctor` montaram na Fase 4 (`object.dart`) — use-os; não varra o documento à toa.
3. Testes: documento do corpus com `slur`/`plist`/`sameas` — achar referentes e referidos; caso de `FindElementInLayerStaffDef` com e sem o elemento na camada.

## Critérios de aceite

- [ ] `dart analyze` — nenhum issue novo fora da baseline corrente
- [ ] `dart test` — verde, sem regressão, contagem só sobe
- [ ] Inventário dos 4 nomes completo (contraparte confirmada) — tabela colada
- [ ] Testes de referência (positivo/negativo) e do staffDef-de-camada passam
- [ ] `verify_phases_6_plus --fase=6` — 6.1 sem `findfunctor.cpp` inteiro (cole a linha)
- [ ] Relatório em `prompts/reports/06-05.md`
- [ ] `PLANO.md`: checkbox de `findfunctor.cpp` marcado (última tarefa do item)

## Armadilhas conhecidas

- `FindAllReferringObjects` distingue **qual atributo** aponta o alvo (`startid` vs `plist` vs linking) — o C++ reporta o par (objeto, atributo); preserve o par.
- Não transforme as travessias em classes `Functor` só por simetria com o C++ se o Dart já escolheu métodos — o desvio documentado vale mais que a simetria falsa.

## Fora de escopo

- `findlayerelementsfunctor.cpp` (06-06).
