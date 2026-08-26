# 05-24 — view_neume.cpp + view_tab.cpp: notação neumática e tablatura

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os dois últimos arquivos de desenho: notação neumática (canto) e tablatura.
Ao final, **todos os `view*.cpp` do C++ estão portados** e não sobra nenhum `_notYet` em `lib/`.

## Pré-condições

Tarefa **05-23** concluída.

```bash
cd verovio_dart
ls lib/src/rendering/view_mensural.dart
dart test 2>&1 | tail -1     # verde, ≥ 564
```

## Referência C++

| Arquivo | Linha | Função |
|---|---:|---|
| `origin/src/src/view_neume.cpp` (322 linhas) | 35 | `DrawSyllable` |
| | 58 | `DrawLiquescent` |
| | 70 | `DrawNc` |
| | 97 | `DrawNeume` |
| | 153 | `DrawNcAsNotehead` |
| | 173 | `DrawDivLine` |
| | 215 | `DrawEpisema` |
| | 267 | `DrawOriscus` |
| | 279 | `DrawQuilisma` |
| | 291 | `DrawStrophicus` |
| | 303 | `DrawNcGlyphs` |
| `origin/src/src/view_tab.cpp` (295 linhas) | 36 | `DrawTabClef` |
| | 72 | `DrawTabGrp` |
| | 90 | `DrawTabNote` |
| | 213 | `DrawTabDurSym` |

`DivLine`, `Liquescent`, `Oriscus`, `Quilisma`, `Strophicus` e `Episema` **não têm `Accept()` no C++**
e estão em `kAcceptChain` (`lib/src/layout/functor.dart:64`) mapeados para `layerElement`.
Confirme isso antes de mexer no despacho.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view_neume.dart` e `lib/src/rendering/view_tab.dart`
  (`part of` `view.dart`).
- **Alterar** `lib/src/rendering/view.dart` e `view_element.dart` (últimos `_notYet`).
- **Criar** `test/view_neume_tab_test.dart`.

## Passo a passo

1. Leia os dois arquivos (617 linhas somadas).
2. Porte `view_neume.cpp`: `DrawSyllable`, `DrawNeume`, `DrawNc`, `DrawNcGlyphs`,
   `DrawNcAsNotehead`, `DrawLiquescent`, `DrawOriscus`, `DrawQuilisma`, `DrawStrophicus`,
   `DrawEpisema`, `DrawDivLine`.
3. Porte `view_tab.cpp`: `DrawTabClef`, `DrawTabGrp`, `DrawTabNote`, `DrawTabDurSym`.
   Tablatura usa `Tuning`/`Course` — já existem (`lib/src/core/tunings.dart`,
   `lib/src/model/custom_tuning.dart`, `Course` em `factory_registry_gen.dart`).
4. Testes: `test/corpus/neume/` (6), `test/corpus/tab/` (5).
5. **Marco final de desenho:** rode `dart run tool/compare_svg.dart --all` nos dois modos.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 574 testes**
- [ ] `grep -rn "_notYet(" lib/src/rendering/` → **nenhum resultado**
- [ ] Toda função `View::` de todos os `origin/src/src/view*.cpp` tem contraparte em Dart — prove no
      relatório colando o diff completo de nomes:
      `grep -ohP '^\w[\w:*& ]*View::\K\w+' origin/src/src/view*.cpp | sort -u` contra os métodos do Dart
- [ ] `dart run tool/compare_svg.dart test/corpus/neume --mode=structural` reporta **≥ 4 de 6** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/tab --mode=structural` reporta **≥ 3 de 5** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` reporta **≥ 480 de 623** limpos
- [ ] Relatório em `prompts/reports/05-24.md`
- [ ] `PLANO.md`: checkbox de `view_mensural`/`view_neume`/`view_tab` marcado

## Armadilhas conhecidas

- Neumas dependem de `AdjustNeumeXFunctor` (tarefa 04g) e de `CalcLigatureOrNeumePosFunctor`
  (já portado). Se a posição sair errada, verifique a Fase 4 antes.
- No relatório de layout, os 6 arquivos de `test/corpus/neume/` saem hoje com largura de sistema
  `w=0`. Isso é estado conhecido; se continuar depois desta tarefa, registre como divergência
  em aberto para a 05-25.
- `DrawNcGlyphs` monta o neuma a partir de vários glifos SMuFL encadeados; a tabela de
  combinações está no C++.
- Tablatura: `@tab.course`/`@tab.fret` e a afinação do `staffDef`. `DrawTabDurSym` desenha o símbolo
  de duração acima da tablatura.

## Fora de escopo

- Perseguir a cauda de divergências (tarefa 05-25).
