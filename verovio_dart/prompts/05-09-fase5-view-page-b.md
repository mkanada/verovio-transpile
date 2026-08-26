# 05-09 — view_page.cpp (B): scoreDef, staffGrp, rótulos e colchetes

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Desenhar o começo de cada sistema: o `scoreDef` (claves, armaduras e fórmulas de compasso iniciais),
os grupos de pentagramas, os rótulos de instrumento e os colchetes/chaves que os agrupam.

## Pré-condições

Tarefa **05-08** concluída.

```bash
cd verovio_dart
grep -c "_notYet('DrawScoreDef'" lib/src/rendering/view_page.dart   # 1
dart test 2>&1 | tail -1                                             # verde, ≥ 408
```

## Referência C++

`origin/src/src/view_page.cpp`, faixas:

| Linha | Função |
|---:|---|
| 125 | `SetScoreDefDrawingWidth` |
| 257 | `DrawScoreDef` |
| 286 | `DrawStaffGrp` |
| 361 | `DrawStaffDefLabels` |
| 403 | `DrawGrpSym` |
| 461 | `DrawLayerDefLabels` |
| 487 | `DrawLabels` |
| 556 | `DrawBracket` |
| 575 | `DrawBracketSq` |
| 588 | `DrawBrace` |
| 1460 | `DrawStaffDef` |
| 1493 | `DrawStaffDefCautionary` |

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/view_page.dart` — trocar os stubs `_notYet` correspondentes.
- **Alterar** `test/view_page_test.dart`.

## Passo a passo

1. Leia as faixas acima.
2. Porte `DrawScoreDef` e `DrawStaffGrp` primeiro — eles orquestram o resto.
3. `DrawBrace` (588-677) é a mais longa: a chave é desenhada como uma curva bezier composta ou como
   glifo, dependendo do tamanho. Leia o corpo inteiro; há dois caminhos.
4. `DrawLabels` (487-555) trata rótulo e abreviação, com quebra de linha. Depende de medição de
   texto, que vem do device context (tarefa 05-01/05-04).
5. `DrawStaffDefCautionary` desenha clave/armadura de cortesia no fim do sistema.
6. Testes: `test/corpus/score/` (16 arquivos) tem os casos de grupo; `test/corpus/clef/` (7) e
   `test/corpus/keysig/` (6) cobrem o scoreDef inicial. Compare em modo estrutural com os goldens
   correspondentes e afirme que o subgrupo `<g class="grpSym">` / `<g class="labelAbbr">` existe
   e está na posição certa.
7. Rode `dart run tool/compare_svg.dart --all` e registre o número.
8. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 414 testes**
- [ ] `grep -c "_notYet('DrawScoreDef'\|_notYet('DrawStaffGrp'\|_notYet('DrawBrace'" lib/src/rendering/view_page.dart` = 0
- [ ] `dart run tool/compare_svg.dart --all` roda e o relatório traz o número de limpos
- [ ] O relatório compara o número de arquivos estruturalmente limpos com o da tarefa 05-08 e
      **ele subiu ou a razão de não ter subido está explicada** (é legítimo: faltam pentagramas
      e notas até a 05-11/05-13)
- [ ] Relatório em `prompts/reports/05-09.md`
- [ ] `PLANO.md`: checkbox de `view_page.cpp` (B) marcado

## Armadilhas conhecidas

- `DrawBrace`: os dois caminhos (glifo vs. bezier) produzem SVG completamente diferente. O critério
  de escolha está no C++; não chute.
- A largura reservada pelo `scoreDef` (`SetScoreDefDrawingWidth`) foi calculada na Fase 4 e é
  **consumida** aqui. Se o desenho não couber, o bug provavelmente é da Fase 4, não seu — registre.
- `DrawGrpSym` trata `symbol="brace|bracket|bracketsq|line"`; cada um tem um desenho próprio.
- Rótulos usam a fonte de texto, cujas métricas hoje ainda são as do `Resources`; confira que
  `Resources.defaultPath` está setado nos testes.

## Fora de escopo

- `DrawMeasure` e barlines (05-10), `DrawStaff` (05-11).
