# 06-23 — EditorToolkitNeume (A): estrutura, inserção e remoção

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar a primeira metade de `editortoolkit_neume.cpp` (4.498 linhas): a classe, o despacho de ações
e as operações de inserção e remoção de elementos neumáticos.

## Pré-condições

Tarefa **06-22** concluída.

```bash
cd verovio_dart
ls lib/src/editing/editor_toolkit_shared.dart lib/src/editing/editor_toolkit_cmn.dart
dart test 2>&1 | tail -1     # verde, ≥ 865
```

## Referência C++

`origin/src/include/vrv/editortoolkit_neume.h` (266 linhas) e
`origin/src/src/editortoolkit_neume.cpp` (4498 linhas).

Liste os métodos e as faixas de linha antes de fatiar:

```bash
grep -n "^bool EditorToolkitNeume::\|^void EditorToolkitNeume::\|^std::string EditorToolkitNeume::" origin/src/src/editortoolkit_neume.cpp
```

**Esta tarefa:** a declaração da classe, `ParseEditorAction`, o despacho, e todas as ações de
**inserir** e **remover** (`Insert`, `InsertToSyllable`, `Delete`, `Remove`, `RemoveFromSyllable`
e o que mais o grep revelar com esses verbos).

**A tarefa 06-24** pega o resto: `Drag`, `Set`, `Group`/`Ungroup`, `Merge`/`Split`, `ChangeGroup`,
`ToggleLigature`, `ChangeStaff`, `Resize`, `MatchHeight`, `SetClef`, e os validadores.

Deixe cada método da 06-24 como `_notYet('Xxx', '06-24')`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/editing/editor_toolkit_neume.dart`.
- **Criar** `test/editor_toolkit_neume_test.dart`.

## Passo a passo

1. Rode o grep acima e **cole no relatório a lista completa de métodos com suas faixas de linha**,
   marcando quais são desta tarefa e quais da 06-24. Essa lista é o contrato entre as duas tarefas.
2. Porte a classe, o despacho e as ações de inserção/remoção.
3. Testes: `test/corpus/neume/` (6 arquivos). Para cada ação, o JSON exato e a asserção da árvore.
4. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 880 testes**
- [ ] O relatório traz a lista completa de métodos de `editortoolkit_neume.cpp` com faixas de linha,
      marcados como 06-23 ou 06-24
- [ ] Todo método da 06-24 tem `_notYet('Xxx', '06-24')`
- [ ] Um teste por ação de inserção e de remoção
- [ ] Relatório em `prompts/reports/06-23.md`
- [ ] `PLANO.md`: checkbox de "EditorToolkit Neume (A)" marcado

## Armadilhas conhecidas

- A árvore neumática é `syllable > neume > nc`, com `syl` para o texto. Inserir um `nc` no lugar
  errado quebra a estrutura sem erro.
- As posições vêm em coordenadas de fac-símile (`zone`), não de layout. Depende da tarefa 06-13.
- `DivLine`, `Liquescent`, `Oriscus`, `Quilisma`, `Strophicus` não têm `Accept()` no C++ e estão em
  `kAcceptChain` (`00-MESTRE.md` §5a). Se você criar uma classe nova aqui, ela precisa entrar lá.
- 4.498 linhas é muito. **Se a fatia estourar, pare, entregue o que está coerente e registre o que
  ficou** (`00-MESTRE.md` §8.7).

## Fora de escopo

- Tudo marcado `_notYet('…', '06-24')`.
