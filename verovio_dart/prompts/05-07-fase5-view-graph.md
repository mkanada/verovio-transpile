# 05-07 — view_graph.cpp: primitivas gráficas do View

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `view_graph.cpp`: as 21 primitivas que todo o resto do desenho usa — linhas, retângulos,
elipses, polígonos, pontos, colchetes, e sobretudo a família `DrawSmufl*`, que é como cada glifo
musical chega ao SVG.

## Pré-condições

Tarefa **05-06** concluída.

```bash
cd verovio_dart
ls lib/src/rendering/view.dart
dart test 2>&1 | tail -1     # verde, ≥ 382
```

## Referência C++

`origin/src/src/view_graph.cpp` (430 linhas), todas as funções:

| Linha | Função | Linha | Função |
|---:|---|---:|---|
| 27 | `DrawVerticalLine` | 203 | `DrawDot` |
| 40 | `DrawHorizontalLine` | 215 | `DrawVerticalDots` |
| 53 | `DrawObliqueLine` | 233 | `DrawSquareBracket` |
| 66 | `DrawVerticalSegmentedLine` | 248 | `DrawEnclosingBrackets` |
| 76 | `DrawHorizontalSegmentedLine` | 260 | `DrawSmuflCodeWithCustomFont` |
| 86 | `DrawNotFilledEllipse` | 279 | `DrawSmuflCode` |
| 104 | `DrawNotFilledRectangle` | 297 | `DrawSmuflLine` |
| 124 | `DrawFilledRectangle` | 334 | `DrawSmuflString` |
| 133 | `DrawFilledRoundedRectangle` | 359 | `DrawThickBezierCurve` |
| 151 | `DrawObliquePolygon` | 392 | `DrawSymbolDef` |
| 174 | `DrawDiamond` | | |

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view_graph.dart` (`part of` `view.dart`, conforme a decisão da 05-06).
- **Alterar** `lib/src/rendering/view.dart` para declarar a `part`.
- **Criar** `test/view_graph_test.dart`.

## Passo a passo

1. Leia as 430 linhas inteiras.
2. Porte na ordem do arquivo.
3. `DrawSmuflCode` (279-296) e `DrawSmuflString` (334-358) são as mais usadas de toda a Fase 5:
   elas consultam `Resources` pelo glifo e chamam `DrawMusicText` no device context. Confira o
   caminho inteiro contra `lib/src/rendering/resources.dart`.
4. `DrawSmuflLine` (297-333) desenha uma linha repetindo um glifo (extensores de trill, pedal, etc.)
   — a aritmética de quantos glifos cabem é delicada; copie-a exatamente.
5. `DrawSymbolDef` (392-430) desenha um `<symbolDef>` do MEI; depende de `SymbolDef`/`Symbol` no
   modelo. Confira que existem (`grep -rn "class SymbolDef\|class Symbol\b" lib/src/model/`).
6. Testes: para cada primitiva, desenhe num `SvgDeviceContext` e compare a string exata. Para
   `DrawSmuflCode`, use um glifo real de `assets/data/` e confira que o `<defs>` recebe o contorno
   certo (lembre `Resources.defaultPath = 'assets/data';`).
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 403 testes** (uma por primitiva)
- [ ] As 21 funções de `view_graph.cpp` têm contraparte — prove no relatório com o diff de nomes
- [ ] Um teste desenha `DrawSmuflCode` com o glifo `E050` (clave de sol) e compara com o
      `<use>`/`<defs>` extraído de `test/golden/cpp/note/note-001.svg`
- [ ] `dart run tool/compare_svg.dart --all` continua em `0/623` (ainda não há `DrawCurrentPage`)
- [ ] Relatório em `prompts/reports/05-07.md`
- [ ] `PLANO.md`: checkbox de `view_graph.cpp` marcado

## Armadilhas conhecidas

- `DrawVerticalSegmentedLine` e `DrawHorizontalSegmentedLine` desenham linhas tracejadas **como
  segmentos separados**, não com `stroke-dasharray`. O SVG resultante é diferente; siga o C++.
- `DrawSmuflLine`: o número de repetições vem de uma divisão inteira com resto tratado
  explicitamente. `~/` e o resto, não `round()`.
- `DrawThickBezierCurve` (359-391) monta duas curvas e preenche entre elas, chamando
  `DrawCubicBezierPathFilled` do device context (tarefa 05-03). Se o resultado sair errado, verifique
  primeiro o device context.
- `DrawDiamond` tem um parâmetro de preenchimento e outro de largura de pena; os dois mudam a saída.
- `DrawObliquePolygon` é usada por ligaduras mensurais e beams; a ordem dos vértices define o
  sentido de preenchimento.

## Fora de escopo

- `view_page.cpp` (tarefas 05-08 a 05-11).
