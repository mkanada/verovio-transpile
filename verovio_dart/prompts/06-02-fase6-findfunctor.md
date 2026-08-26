# 06-02 — findfunctor.cpp: as buscas que faltam e os comparadores

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar a superfície de busca de `Object`. O Dart já resolve a maioria das buscas do C++ por travessia
direta em `lib/src/model/object.dart`; faltam **6** e dois comparadores.

## Pré-condições

Tarefa **06-01** concluída.

```bash
cd verovio_dart
dart test 2>&1 | tail -1     # verde, ≥ 590
```

## Referência C++

`origin/src/include/vrv/findfunctor.h` e `origin/src/src/findfunctor.cpp` (477 linhas).

O que **já existe** em Dart (não reporte, não reescreva):

| C++ | Dart | Linha |
|---|---|---|
| `FindDescendantByID` | `findDescendantByID` | `object.dart:838` |
| `FindDescendantByType` | `findDescendantByType` | `object.dart:853` |
| `FindAllDescendantsByType` | `findAllDescendantsByType` | `object.dart:861` |
| `FindDescendantByComparison` | `findDescendantByComparison` | `object.dart:954` |
| `FindDescendantExtremeByComparison` | `findDescendantExtremeByComparison` | `object.dart:970` |
| `FindAllDescendantsByComparison` | `findAllDescendantsMatching` | `object.dart:983` |
| `FillFlatList` | `fillFlatList` | `object.dart:996` |

O que **falta** (verificado por `grep` em `object.dart` e `comparison.dart` em 2026-08-26):

1. `Object::FindAllDescendantsBetween` — busca entre dois objetos na ordem de documento.
2. `Object::FindNextChild` — próximo irmão que casa com um comparador.
3. `Object::FindPreviousChild` — irmão anterior.
4. `FindAllReferringObjectsFunctor` — quem aponta para este objeto (`@startid`/`@endid`/`@plist`).
5. `FindAllReferencedObjectsFunctor` — para quem este objeto aponta.
6. `FindElementInLayerStaffDefFunctor` (`origin/src/src/findlayerelementsfunctor.cpp`) — elemento
   num `staffDef` de camada.

Mais os dois comparadores marcados em `lib/src/model/comparison.dart:359`:
`MeasureAlignerTypeComparison` e `MeasureOnsetOffsetComparison`
(`origin/src/include/vrv/comparison.h`).

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/model/object.dart` — as 3 travessias faltantes.
- **Alterar** `lib/src/model/comparison.dart` — os 2 comparadores; remover o `TODO(layout)` de `:359`.
- **Criar** `lib/src/model/find_references.dart` — as buscas de referência (4, 5, 6), que precisam
  varrer o documento inteiro e não cabem em `object.dart`.
- **Criar** `test/find_test.dart`.

## Passo a passo

1. Leia `findfunctor.h` inteiro e as partes do `.cpp` correspondentes aos 6 itens faltantes.
2. Porte as 3 travessias em `object.dart`, no estilo das que já estão lá (travessia direta com doc
   comment citando o functor C++, não uma classe `Functor`). **Documente esse desvio** —
   `00-MESTRE.md` §1.
3. Porte os 2 comparadores em `comparison.dart` e apague o `TODO(layout)` da linha 359.
4. Porte as buscas de referência em `find_references.dart`.
5. Testes: cada busca com um caso positivo e um negativo, sobre arquivos reais do corpus.
   Para as buscas de referência, use `test/corpus/sameas/` (2 arquivos) e `test/corpus/slur/`
   (`@startid`/`@endid`).
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 602 testes**
- [ ] `grep -c "TODO(layout): MeasureAlignerTypeComparison" lib/src/model/comparison.dart` = 0
- [ ] Cada uma das 6 buscas tem contraparte e teste; o relatório lista as 6 com o arquivo:linha em Dart
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/06-02.md`
- [ ] `PLANO.md`: checkbox de `findfunctor.cpp` marcado

## Armadilhas conhecidas

- `FindAllDescendantsBetween` usa a ordem de **documento**, não de tempo. Dois objetos em pentagramas
  diferentes têm ordem definida pela árvore.
- As buscas de referência dependem dos back-links que `PrepareLinkingFunctor` e `PreparePlistFunctor`
  já montaram na Fase 4 (`object.dart:110` menciona a lista). Use-os; não varra o documento à toa.
- `FindNextChild`/`FindPreviousChild` operam sobre **irmãos**, não descendentes.
- Não transforme as travessias em classes `Functor` só por simetria com o C++ — o Dart já escolheu o
  outro caminho e o `object.dart` documenta isso.

## Fora de escopo

- `findlayerelementsfunctor.cpp` além do `FindElementInLayerStaffDef` (tarefa 06-03).
