# 06-24 — EditorToolkitNeume (B): arrastar, agrupar, dividir e validar

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar `editortoolkit_neume.cpp` e, com ele, a Fase 6 inteira: arrastar, alterar propriedades,
agrupar/desagrupar, unir/dividir, ligaduras, mudança de pentagrama, redimensionamento e os
validadores.

## Pré-condições

Tarefa **06-23** concluída.

```bash
cd verovio_dart
grep -c "_notYet(" lib/src/editing/editor_toolkit_neume.dart   # > 0
dart test 2>&1 | tail -1     # verde, ≥ 880
```

## Referência C++

`origin/src/src/editortoolkit_neume.cpp` — todos os métodos que a tarefa 06-23 marcou como desta.
A lista com faixas de linha está em `prompts/reports/06-23.md`. **Leia esse relatório primeiro.**

Tipicamente: `Drag`, `Set`, `SetText`, `SetClef`, `Group`, `Ungroup`, `Merge`, `Split`,
`ChangeGroup`, `ToggleLigature`, `ChangeStaff`, `Resize`, `MatchHeight`, `Remove`, `ChangeSkeleton`,
e os `Is*`/`Validate*`.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/editing/editor_toolkit_neume.dart`.
- **Alterar** `test/editor_toolkit_neume_test.dart`.

## Passo a passo

1. Leia `prompts/reports/06-23.md` para saber exatamente o que falta.
2. Porte os métodos restantes.
3. Testes: um por ação, com o JSON exato e a asserção da árvore. Para `Group`/`Ungroup` e
   `Merge`/`Split`, teste a ida e a volta: agrupar e desagrupar tem de devolver a estrutura original.
4. **Fechamento da Fase 6:** rode todas as validações acumuladas e registre os números:
   ```bash
   dart run tool/validate_layout.dart
   dart run tool/validate_timemap.dart
   dart run tool/validate_midi.dart
   dart run tool/compare_svg.dart --all
   ```
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 900 testes**
- [ ] `grep -c "_notYet(" lib/src/editing/editor_toolkit_neume.dart` = **0**
- [ ] Todo método de `editortoolkit_neume.cpp` tem contraparte — prove com o diff de nomes
- [ ] Testes de ida e volta para `Group`/`Ungroup` e `Merge`/`Split`
- [ ] O relatório traz os quatro números de validação (layout, timemap, MIDI, SVG) e compara com os
      da tarefa 06-17/06-15, provando que nada regrediu
- [ ] Relatório em `prompts/reports/06-24.md`
- [ ] `PLANO.md`: Fase 6 inteira marcada, com os números finais no cabeçalho da fase

## Armadilhas conhecidas

- `Group`/`Ungroup` reorganizam a árvore e **precisam preservar os ids**, senão o undo e o SVG
  divergem.
- `ToggleLigature` altera `@ligated` e a estrutura; há regras sobre quais neumas podem ser ligados.
- `ChangeStaff` move elementos entre pentagramas e recalcula posições de fac-símile.
- `Resize`/`MatchHeight` operam sobre `zone`, não sobre coordenadas de layout.
- Os validadores devolvem mensagens de erro que o cliente exibe; copie as strings exatas.

## Fora de escopo

- Fase 7 (opções e Toolkit público).
