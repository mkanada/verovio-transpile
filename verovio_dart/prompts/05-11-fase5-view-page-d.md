# 05-11 — view_page.cpp (D): pentagrama, linhas e linhas suplementares

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar `view_page.cpp`: desenhar o pentagrama, suas cinco linhas, as linhas suplementares e a camada.
Ao final, `view_page.cpp` está inteiro portado e não sobra nenhum `_notYet` nele.

## Pré-condições

Tarefa **05-10** concluída.

```bash
cd verovio_dart
grep -c "_notYet('DrawStaff'" lib/src/rendering/view_page.dart   # 1
dart test 2>&1 | tail -1                                          # verde, ≥ 424
```

## Referência C++

`origin/src/src/view_page.cpp`, faixas:

| Linha | Função |
|---:|---|
| 1263 | `DrawStaff` |
| 1317 | `DrawStaffLines` |
| 1407 | `DrawLedgerLines` |
| 1530 | `CalculatePitchCode` |
| 2055 | `DrawAnnot` |

`DrawLedgerLines` consome o que `CalcLedgerLinesFunctor` (tarefa 04g) acumulou em `Staff`.
Se essa tarefa não ligou os acumuladores, esta não tem o que desenhar — confira antes:

```bash
grep -n "ledgerLine\|LedgerLine" lib/src/model/basic_elements.dart | head
grep -n "class CalcLedgerLinesFunctor" lib/src/layout/calc_ledger_lines.dart
```

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/view_page.dart`.
- **Alterar** `test/view_page_test.dart`.

## Passo a passo

1. Leia as faixas.
2. Porte `DrawStaff` e `DrawStaffLines` (tratam pentagramas de 1 a N linhas, tablatura, e a opção
   de linhas invisíveis).
3. Porte `DrawLedgerLines` — o C++ desenha grupos de linhas acumulados, não uma por nota.
4. Porte `CalculatePitchCode` e `DrawAnnot`.
5. Testes: `test/corpus/note/` (nota bem acima e bem abaixo do pentagrama → linhas suplementares),
   `test/corpus/tab/` (5 arquivos, pentagramas de tablatura), `test/corpus/annot/` (7).
6. **Marco desta tarefa:** rode `dart run tool/compare_svg.dart --all` e registre o número. Com
   `view_page.cpp` inteiro, arquivos que só têm estrutura (sem notas desenhadas ainda) devem começar
   a bater estruturalmente em parte da árvore. Registre honestamente o número, seja ele qual for.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 432 testes**
- [ ] `grep -c "_notYet(" lib/src/rendering/view_page.dart` = **0**
- [ ] Toda função de `origin/src/src/view_page.cpp` tem contraparte — prove no relatório com o diff
      entre `grep -oP '^\w[\w:*& ]*View::\K\w+' origin/src/src/view_page.cpp` e os métodos do Dart
- [ ] `dart run tool/compare_svg.dart --all` roda até o fim e o relatório traz o número de limpos
- [ ] Relatório em `prompts/reports/05-11.md`
- [ ] `PLANO.md`: checkbox de `view_page.cpp` (D) marcado, e o item de `view_page.cpp` como um todo

## Armadilhas conhecidas

- `DrawStaffLines` respeita `@lines` do `staffDef` (padrão 5) e a tablatura pode ter 4, 6 ou mais.
- A linha suplementar é desenhada com a largura da cabeça de nota mais uma folga; a folga é uma
  constante do C++ — não a estime.
- Notas com acidente têm linhas suplementares mais largas do lado do acidente. `CalcLedgerLinesFunctor`
  já deveria ter registrado isso; se não registrou, o bug é da tarefa 04g — registre no relatório.
- `DrawStaff` abre um `<g class="staff">` cujo `id` vem do `@xml:id` do MEI. Se o id não bater com o
  golden, o problema é a geração de id no modelo, não aqui.

## Fora de escopo

- `view_element.cpp` (tarefas 05-13 a 05-16).
- A virada do layout para o `View` real (tarefa 05-12) — é a **próxima**.
