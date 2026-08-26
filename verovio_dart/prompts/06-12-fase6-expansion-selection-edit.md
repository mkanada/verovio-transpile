# 06-12 — expansion.cpp, seleção, CastOffToSelection e editfunctor.cpp

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar o suporte a seleção (recorte do documento por intervalo de compassos), o `CastOffToSelectionFunctor`
que o materializa, e os dois functors de contexto de `editfunctor.cpp` que o editor da Fase 6 usa.

## Pré-condições

Tarefa **06-11** concluída.

```bash
cd verovio_dart
grep -c "_notYet(" lib/src/io/mei_output.dart   # 0
ls lib/src/io/save_functor.dart
grep -n "CastOffToSelectionFunctor. is deferred" lib/src/layout/cast_off.dart   # linha ~17
dart test 2>&1 | tail -1     # verde, ≥ 692
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/src/expansion.cpp` | 65 | a classe `Expansion` |
| `origin/src/include/vrv/castofffunctor.h` | — | `class CastOffToSelectionFunctor` |
| `origin/src/src/castofffunctor.cpp` | 727 | localize com `grep -n "CastOffToSelectionFunctor::" origin/src/src/castofffunctor.cpp` |
| `origin/src/include/vrv/editfunctor.h` | — | `ScoreContextFunctor`, `SectionContextFunctor` |
| `origin/src/src/editfunctor.cpp` | 147 | as duas |
| `origin/src/src/toolkit.cpp` | — | `Toolkit::SetSelection`/`LoadSelection` (`grep -n "Selection" origin/src/src/toolkit.cpp`) |

Em Dart já existem `lib/src/model/expansion_map.dart` (ExpansionMap completo) e o resto do cast-off
em `lib/src/layout/cast_off.dart` — cujo comentário da linha 17 diz que `CastOffToSelectionFunctor`
foi adiado. Esta tarefa o apaga.

A opção de seleção está no grupo "Loading selectors and processing" (14 opções) de
`origin/src/src/options.cpp`. Acrescente ao `options_shell.dart` **só as que esta tarefa usa**, e
diga quais no relatório.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/layout/cast_off.dart` — `CastOffToSelectionFunctor`; apagar o comentário da linha 17.
- **Criar** `lib/src/editing/edit_functors.dart` — `ScoreContextFunctor`, `SectionContextFunctor`.
  (Primeiro arquivo de `lib/src/editing/`, hoje vazio.)
- **Alterar** `lib/src/model/doc.dart` — o suporte a seleção.
- **Alterar** `lib/src/core/options_shell.dart`.
- **Criar** `test/selection_test.dart`.

## Passo a passo

1. Leia `expansion.cpp`, a classe `CastOffToSelectionFunctor` e `editfunctor.cpp`.
2. Leia como o `Toolkit` do C++ expressa a seleção (uma string JSON com `start`/`end`/`mdiv`).
3. Porte `CastOffToSelectionFunctor` e apague o comentário adiado.
4. Porte os dois functors de contexto em `lib/src/editing/edit_functors.dart`.
5. Confira que `Expansion`/`ExpansionMap` do Dart cobre `expansion.cpp` (65 linhas); complete o que faltar.
6. Testes: `test/corpus/expansion/` (3 arquivos) e `test/corpus/section/` (4, com 20 compassos).
   Selecione um intervalo de compassos e afirme que o documento resultante tem só eles.
   Compare com o C++ se a CLI expuser a seleção (`./build/verovio --help | grep -i select`).
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 702 testes**
- [ ] `grep -c "CastOffToSelectionFunctor. is deferred" lib/src/layout/cast_off.dart` = 0
- [ ] `ls lib/src/editing/edit_functors.dart` existe
- [ ] Um teste seleciona os compassos 5–10 de `test/corpus/section/section-001.mei` (20 compassos) e
      afirma que o documento resultante tem exatamente 6 compassos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/06-12.md`, listando quais opções de seleção foram portadas
- [ ] `PLANO.md`: checkbox de expansion/selection/editfunctor marcado

## Armadilhas conhecidas

- Seleção **muda o documento em memória**. Se um teste selecionar e o próximo esperar o documento
  inteiro, o segundo falha. Recarregue por teste.
- `CastOffToSelectionFunctor` interage com o cast-off normal; a ordem importa.
- `ScoreContextFunctor`/`SectionContextFunctor` só coletam contexto (qual score/section contém um
  objeto) — não modificam nada. Se estiverem modificando, você errou.
- `mensuralResp = selection` (tarefa 06-06) pode ter ficado com um `TODO(06-12)`. Se ficou, resolva-o
  aqui e diga no relatório.

## Fora de escopo

- `EditorToolkit` (tarefas 06-20 a 06-22).
