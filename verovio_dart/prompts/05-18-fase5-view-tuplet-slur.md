# 05-18 — view_tuplet.cpp + view_slur.cpp: quiálteras e ligaduras de expressão

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar o desenho de quiálteras (colchete e número) e de ligaduras de expressão.

## Pré-condições

Tarefa **05-17** concluída.

```bash
cd verovio_dart
ls lib/src/rendering/view_beam.dart
dart test 2>&1 | tail -1     # verde, ≥ 490
```

## Referência C++

| Arquivo | Linha | Função |
|---|---:|---|
| `origin/src/src/view_tuplet.cpp` (211 linhas) | 27 | `NestedTuplets` |
| | 51 | `DrawTuplet` |
| | 75 | `DrawTupletBracket` |
| | 153 | `DrawTupletNum` |
| `origin/src/src/view_slur.cpp` (97 linhas) | 33 | `DrawSlur` |
| | 76 | `CalcInitialSlur` |

`view_slur.cpp` é curto porque **toda a matemática da curva está no `AdjustSlursFunctor` e em
`Slur`**, já portados na Fase 4 (`lib/src/layout/adjust_slurs.dart`, `lib/src/layout/slur_positioning.dart`).
Confirme que as aproximações de `slur_positioning.dart` foram removidas na tarefa 05-12:

```bash
grep -c "Approximation:" lib/src/layout/slur_positioning.dart    # tem de ser 0
```

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view_tuplet.dart` e `lib/src/rendering/view_slur.dart`
  (`part of` `view.dart`).
- **Alterar** `lib/src/rendering/view.dart` e `view_element.dart`.
- **Criar** `test/view_tuplet_slur_test.dart`.

## Passo a passo

1. Leia os dois arquivos inteiros (308 linhas somadas).
2. Porte `NestedTuplets`, `DrawTuplet`, `DrawTupletBracket`, `DrawTupletNum`.
3. Porte `DrawSlur` e `CalcInitialSlur`.
4. Testes: `test/corpus/tuplet/` (22 arquivos), `test/corpus/slur/` (25), `test/corpus/phrase/` (1).
   `Phrase` estende `Slur` no modelo — confirme que o desenho o cobre.
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 498 testes**
- [ ] `dart run tool/compare_svg.dart test/corpus/tuplet --mode=structural` reporta **≥ 16 de 22** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/slur --mode=structural` reporta **≥ 16 de 25** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` maior que na tarefa 05-17
- [ ] Relatório em `prompts/reports/05-18.md`
- [ ] `PLANO.md`: checkbox de `view_tuplet.cpp`/`view_slur.cpp` marcado

## Armadilhas conhecidas

- Se a curva da ligadura sair diferente do C++, o bug quase certamente **não** está em
  `view_slur.cpp` (97 linhas), e sim no `AdjustSlursFunctor`/`slur_positioning.dart` da Fase 4.
  Antes de mexer aqui, compare os pontos de controle da bezier com os do C++.
- `DrawTupletBracket` decide se desenha colchete pelos flags calculados na Fase 4
  (`AdjustTupletsXFunctor`/`AdjustTupletsYFunctor`, tarefa 04c).
- Quiálteras aninhadas: `NestedTuplets` conta a profundidade e afasta os colchetes.
- `Phrase` usa a mesma geometria de `Slur` mas com `class` diferente no SVG — a comparação
  estrutural pega isso.

## Fora de escopo

- `view_text.cpp` (tarefa 05-19).
