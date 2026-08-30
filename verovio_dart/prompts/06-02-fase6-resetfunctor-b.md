# 06-02 — resetfunctor.cpp (B): ResetDataFunctor, segunda metade dos Visit*

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Regra de números: critérios medem contra o estado corrente — nunca contra contagem fixa.

## Objetivo

Completar a segunda metade dos `Visit*` de `ResetDataFunctor`: `LayerElement` até `Verse`.

## Pré-condições

Tarefa **06-01** concluída.

```bash
cd verovio_dart
grep -c "visitLayerElement\|visitMeasure" lib/src/layout/reset_functor.dart   # existem (da 06-01 não — conferir)
dart run tool/verify_phases_6_plus.dart --fase=6 --verbose | grep "6.1"       # lista de ausentes menor
```

## Referência C++

`origin/src/src/resetfunctor.cpp:275-563` — `ResetDataFunctor::Visit*`: `LayerElement, Ligature,
Measure, MRest, Note, Nc, Object, Page, RepeatMark, Rest, Section, Slur, Staff, StaffDef, Stem,
Syl, System, SystemMilestone, TabDurSym, Tempo, Tuplet, Turn, Verse` (nominal; confira com o
grep da 06-01). `VisitObject` (`:345`) é o mais denso — reseta o núcleo de todo objeto.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/layout/reset_functor.dart`.
- **Alterar** `test/reset_functor_test.dart`.

## Passo a passo

1. Diff de inventário do escopo (LayerElement..Verse) — cole os faltantes.
2. Porte cada `Visit*` faltante, citando o C++ no doc comment.
3. Testes no molde da 06-01, um por `Visit*` portado.

## Critérios de aceite

- [ ] `dart analyze` — nenhum issue novo fora da baseline corrente
- [ ] `dart test` — verde, sem regressão, contagem só sobe (anote)
- [ ] O diff de inventário de `ResetDataFunctor` completo (linhas 55-563 do C++) está **vazio** — lista colada
- [ ] `verify_phases_6_plus --fase=6` — critério 6.1 sem nenhum `Reset*Functor` na lista de ausentes (cole a linha)
- [ ] Relatório em `prompts/reports/06-02.md`
- [ ] `PLANO.md`: sufixo de progresso no item de `resetfunctor.cpp`

## Armadilhas conhecidas

- `VisitObject` reseta campos que **todo** objeto carrega; se ele divergir do C++, todos os outros resets herdam o erro — porte-o primeiro e teste-o isolado.
- Mesmas da 06-01 (delegação dupla; valor dobrado).

## Fora de escopo

- `ResetHorizontalAlignment`/`ResetVerticalAlignment` (06-03).
