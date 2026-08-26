# 06-22 — EditorToolkit: base, EditorToolkitShared e CMN

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar a base do editor interativo: a classe abstrata `EditorToolkit`, a implementação
`EditorToolkitShared` (que contém **toda** a funcionalidade CMN) e `EditorToolkitCMN`.

> Correção de escopo medida em 2026-08-26: `origin/src/src/editortoolkit_cmn.cpp` tem **23 linhas**
> — só construtor e destrutor. Em 6.2.0 toda a lógica CMN vive em `EditorToolkitShared` (902 linhas).
> O peso do editor está no Neume (4.498 linhas), que é a tarefa 06-23/06-24.

## Pré-condições

Tarefa **06-21** concluída.

```bash
cd verovio_dart
ls lib/src/editing/transpose_functors.dart lib/src/editing/edit_functors.dart
dart test 2>&1 | tail -1     # verde, ≥ 845
```

## Referência C++

| Arquivo | Linhas |
|---|---:|
| `origin/src/include/vrv/editortoolkit.h` | 63 |
| `origin/src/src/editortoolkit.cpp` | 110 |
| `origin/src/include/vrv/editortoolkit_shared.h` | 164 |
| `origin/src/src/editortoolkit_shared.cpp` | 902 |
| `origin/src/include/vrv/editortoolkit_cmn.h` | 47 |
| `origin/src/src/editortoolkit_cmn.cpp` | 23 |

Métodos de `EditorToolkitShared` (de `editortoolkit_shared.h`):
`ParseEditorAction` (3 sobrecargas), `EditInfo`, `Chain`, `ParseContextAction`, `ParseDeleteAction`,
`ParseDragAction`, `ParseKeyDownAction`, `ParseInsertAction`, `ParseSetAction`, `SetEditInfo`,
`PrepareUndo`, `GetCurrentState`, `ReloadState`, `TrimUndoMemory`, `CanUndo`, `CanRedo`, `Undo`,
`Redo`, `Delete`, `Drag`, `KeyDown`, `Set`, `ClearContext`, `ContextForElement`, `ContextForScores`,
`ContextForSections`, `ContextForObject`, `ContextForObjects`, `ContextForReferences`,
`GetScoreBasedChildrenFor`, `Reset`, `GetClassName`, `IsSupportedChild`, `GetChildObjects`.

A API é dirigida por **JSON**: `ParseEditorAction` recebe uma string JSON com `action` e `param`.
O C++ usa `nlohmann/json`; o Dart usa `dart:convert` (decisão registrada no `PLANO.md`).

O undo/redo usa `GetCurrentState`/`ReloadState`, que serializam o documento — ou seja, dependem do
`MeiOutput` (tarefas 06-08 a 06-11) e do `MeiInput`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/editing/editor_toolkit.dart` — a base abstrata.
- **Criar** `lib/src/editing/editor_toolkit_shared.dart` — a implementação principal.
- **Criar** `lib/src/editing/editor_toolkit_cmn.dart` — as 23 linhas.
- **Criar** `test/editor_toolkit_test.dart`.

## Passo a passo

1. Leia os três headers e os três `.cpp` (1.035 linhas somadas).
2. Porte a base abstrata.
3. Porte `EditorToolkitShared`, seguindo a ordem do header. Comece pelo despacho
   (`ParseEditorAction` e `Chain`), depois as ações uma a uma.
4. Porte `EditorToolkitCMN` (trivial).
5. Testes: uma ação de cada tipo (`insert`, `delete`, `drag`, `set`, `keyDown`, `chain`), com o JSON
   exato que o C++ aceita, e a asserção do estado da árvore depois. Depois `undo` e a asserção de
   que a árvore voltou ao estado anterior — compare por serialização MEI.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 865 testes**
- [ ] Todo método público de `editortoolkit_shared.h` tem contraparte — prove com o diff de nomes
- [ ] Um teste por tipo de ação (`insert`, `delete`, `drag`, `set`, `keyDown`, `chain`)
- [ ] Um teste de undo/redo que compara a serialização MEI antes e depois, por igualdade exata
- [ ] Relatório em `prompts/reports/06-22.md`
- [ ] `PLANO.md`: checkbox de "EditorToolkit CMN" marcado

## Armadilhas conhecidas

- **O formato JSON das ações é contrato.** Um nome de campo diferente e nenhum cliente funciona.
  Copie os nomes exatos do C++.
- Undo depende de serializar/desserializar o documento. Se o `MeiOutput` não for fiel, o undo
  corrompe. Os testes de round-trip da tarefa 06-11 são a pré-condição real desta.
- `TrimUndoMemory` limita a pilha; sem ele, documentos grandes estouram a memória.
- `ContextFor*` são consultas, não mutações.
- `nlohmann/json` lança em JSON malformado; `dart:convert` também — mas as mensagens diferem.
  O C++ devolve `false` de `ParseEditorAction` em vez de propagar; faça igual.

## Fora de escopo

- `editortoolkit_neume.cpp` (tarefas 06-23 e 06-24).
