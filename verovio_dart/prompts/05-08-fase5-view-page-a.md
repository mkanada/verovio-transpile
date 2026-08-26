# 05-08 — view_page.cpp (A): DrawCurrentPage, sistema e despacho de filhos

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar a espinha do desenho de página: `DrawCurrentPage`, `DrawSystem`, `DrawPageElement`, e os 14
despachantes `Draw*Children` / `Draw*EditorialElement`. Ao final, uma página vazia (só o `<svg>`,
`<defs>` e os `<g>` de página/sistema) já sai estruturalmente igual à do C++.

## Pré-condições

Tarefa **05-07** concluída.

```bash
cd verovio_dart
ls lib/src/rendering/view_graph.dart
dart test 2>&1 | tail -1     # verde, ≥ 403
```

## Referência C++

`origin/src/src/view_page.cpp` (2078 linhas), **estas faixas**:

| Linha | Função |
|---:|---|
| 65 | `DrawCurrentPage` |
| 118 | `GetPPUFactor` |
| 125 | `SetScoreDefDrawingWidth` |
| 163 | `DrawPageElement` |
| 191 | `DrawSystem` |
| 235 | `DrawSystemList` |
| 1575 | `DrawLayer` |
| 1598 | `DrawLayerList` |
| 1617 | `DrawSystemDivider` |
| 1686 | `DrawSystemChildren` |
| 1737 | `DrawMeasureChildren` |
| 1776 | `DrawStaffChildren` |
| 1798 | `DrawLayerChildren` |
| 1820 | `DrawTextChildren` |
| 1850 | `DrawFbChildren` |
| 1869 | `DrawRunningChildren` |
| 1900 | `DrawSystemEditorialElement` |
| 1928 | `DrawMeasureEditorialElement` |
| 1949 | `DrawStaffEditorialElement` |
| 1970 | `DrawLayerEditorialElement` |
| 1992 | `DrawTextEditorialElement` |
| 2013 | `DrawFbEditorialElement` |
| 2034 | `DrawRunningEditorialElement` |
| 2055 | `DrawAnnot` |

**Não porte** nesta tarefa: `DrawScoreDef`, `DrawStaffGrp`, labels, brackets, braces (tarefa 05-09);
`DrawMeasure`, barlines, MNum, meterSigGrp, ossia (05-10); `DrawStaff`, staff lines, ledger lines,
staffDef (05-11).

Deixe cada um deles como um stub que chama `_notYet('DrawScoreDef', '05-09')` — um helper que lança
`UnimplementedError` com a tarefa nomeada.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view_page.dart` (`part of` `view.dart`).
- **Alterar** `lib/src/rendering/view.dart` para declarar a `part`.
- **Criar** `test/view_page_test.dart`.

## Passo a passo

1. Leia as faixas acima.
2. Os 7 `Draw*Children` são despachantes: percorrem os filhos e chamam o desenho certo por tipo.
   Os 7 `Draw*EditorialElement` tratam `app`/`choice`/`lem`/`rdg`/etc. dentro de cada contexto.
   Eles são repetitivos e quase idênticos entre si **de propósito** no C++ — não os unifique numa
   função genérica. Espelhe.
3. Porte `DrawCurrentPage` (65-117): é ela que abre a página no device context, desenha o
   `scoreDef` corrente e percorre os sistemas.
4. Porte os stubs `_notYet` para o que fica nas tarefas seguintes.
5. Testes: carregue `test/corpus/note/note-001.mei`, faça o layout, desenhe num `SvgDeviceContext`
   e compare **em modo estrutural** com `test/golden/cpp/note/note-001.svg`. Espere divergências
   (falta quase tudo) — o teste desta tarefa afirma que o `<svg>`, o `<desc>`, o `<defs>` e os `<g>`
   de `page`/`system` estão certos, e nada mais.
6. Rode `dart run tool/compare_svg.dart --all` e registre o novo número.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 408 testes**
- [ ] `grep -c "_notYet(" lib/src/rendering/view_page.dart` > 0, e cada chamada nomeia a tarefa
      que a preenche
- [ ] Um teste prova que os `<g class="page-margin">` e `<g class="system">` saem com a estrutura e
      os atributos `class` do golden
- [ ] `dart run tool/compare_svg.dart --all` roda até o fim sem exceção
- [ ] O relatório traz o número de arquivos estruturalmente limpos **antes** (0) e **depois**
- [ ] Relatório em `prompts/reports/05-08.md`
- [ ] `PLANO.md`: checkbox de `view_page.cpp` (A) marcado

## Armadilhas conhecidas

- **`DrawCurrentPage` é chamada tanto para renderizar quanto para calcular bounding boxes**
  (`page.cpp:410` e `:532`). O segundo parâmetro (`background`) muda o comportamento. Porte-o.
- Os `<g>` de página têm `class` fixos (`page-margin`, `system`, `measure`, `staff`, `layer`) que a
  comparação estrutural verifica. Um `class` errado invalida a árvore inteira abaixo.
- `DrawSystemDivider` só desenha em condições específicas (opção + posição do sistema). Não o chame
  incondicionalmente.
- `GetPPUFactor` afeta a escala de tudo. Confira contra `Doc` em Dart.
- Se `compare_svg` reportar `0/623` ainda depois desta tarefa, **isso é esperado** — falta o
  conteúdo. O que não pode é lançar exceção.

## Fora de escopo

- Tudo o que virou stub `_notYet`.
