# 06-21 — transposefunctor.cpp

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os três functors de transposição e ligá-los ao `Doc`, para que um documento inteiro possa ser
transposto por intervalo, por tonalidade ou para altura real.

## Pré-condições

Tarefa **06-20** concluída.

```bash
cd verovio_dart
grep -c "_notYet(" lib/src/editing/transposer.dart   # 0
dart test 2>&1 | tail -1     # verde, ≥ 835
```

## Referência C++

`origin/src/include/vrv/transposefunctor.h` → `TransposeFunctor`,
`TransposeSelectedMdivFunctor`, `TransposeToSoundingPitchFunctor`.
`origin/src/src/transposefunctor.cpp` (425 linhas).

Quem os chama: `grep -n "Transpose" origin/src/src/doc.cpp origin/src/src/toolkit.cpp`.

As opções `transpose`, `transposeMdiv`, `transposeSelectedOnly`, `transposeToSoundingPitch`
(grupo "Loading selectors and processing" de `origin/src/src/options.cpp`) — acrescente **só essas
4** ao `options_shell.dart`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/editing/transpose_functors.dart`.
- **Alterar** `lib/src/model/doc.dart` — `transposeDoc` e afins.
- **Alterar** `lib/src/core/options_shell.dart` — as 4 opções.
- **Criar** `test/transpose_functors_test.dart`.

## Passo a passo

1. Leia as 425 linhas e os métodos do `Doc`.
2. Porte os três functors.
3. Ligue-os no `doc.dart`.
4. Acrescente as 4 opções.
5. Testes: transponha arquivos do corpus e compare com o C++:
   ```bash
   ./build/verovio -r verovio_dart/assets/data --transpose P5 -t mei -o /tmp/cpp.mei test/corpus/note/note-001.mei
   ```
   (confirme a flag exata com `./build/verovio --help | grep -i transpose`)
   Compare o MEI resultante com o do Dart usando o `MeiOutput` da tarefa 06-11.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 845 testes**
- [ ] `grep -c "^class Transpose" lib/src/editing/transpose_functors.dart` = 3
- [ ] Para ao menos **10 arquivos** do corpus e **5 intervalos** diferentes (50 combinações), o MEI
      transposto pelo Dart é idêntico ao do C++; o relatório traz a tabela de resultados
- [ ] `transposeToSoundingPitch` testado em ao menos 3 arquivos com instrumento transpositor
      (procure `@trans.semi` ou `@trans.diat`: `grep -l "trans.semi\|trans.diat" test/corpus/**/*.mei`)
- [ ] Relatório em `prompts/reports/06-21.md`
- [ ] `PLANO.md`: checkbox de "Transposição" marcado

## Armadilhas conhecidas

- Transpor **muda o documento em memória**. Testes em sequência precisam recarregar.
- `TransposeToSoundingPitchFunctor` usa `@trans.semi`/`@trans.diat` do `staffDef`; se o documento não
  os tiver, não faz nada. Um teste que passa num documento sem eles não prova nada.
- A armadura tem de ser transposta junto, e os acidentes de cortesia recalculados.
- `TransposeSelectedMdivFunctor` depende do suporte a seleção (tarefa 06-12).
- Se o MEI transposto divergir do C++ só na ordem de atributos, o bug é do `MeiOutput` (06-10), não
  daqui.

## Fora de escopo

- `EditorToolkit` (tarefa 06-22).
