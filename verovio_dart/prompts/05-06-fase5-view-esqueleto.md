# 05-06 — View: esqueleto, coordenadas e offsets

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `view.cpp`: a classe `View`, a conversão entre coordenadas lógicas e de dispositivo, e a pilha
de offsets usada pelos elementos que cruzam sistemas. É a base sobre a qual todo o resto da Fase 5
é construído.

## Pré-condições

Tarefa **05-05** concluída.

```bash
cd verovio_dart
grep -c "TODO" lib/src/rendering/bbox_device_context.dart   # 0
dart test 2>&1 | tail -1                                     # verde, ≥ 370
```

## Referência C++

`origin/src/include/vrv/view.h` (a classe inteira) e `origin/src/src/view.cpp` (342 linhas):

| Linha | Função |
|---:|---|
| 28 | `View::View` (construtor) |
| 39 | `SetDoc` |
| 53 | `SetPage` |
| 72 | `ToDeviceContextX` |
| 78 | `ToLogicalX` |
| 84 | `ToDeviceContextY` |
| 94 | `ToLogicalY` |
| 103 | `ToDeviceContext` |
| 108 | `ToLogical` |
| 113 | `IntToTupletFigures` |
| 118 | `IntToTimeSigFigures` |
| 123 | `IntToSmuflFigures` |
| 135 | `StartOffset` |
| 173 | `EndOffset` |
| 180 | `SetOffsetStaffSize` |
| 187 | `CalcOffset` |
| 197 | `CalcOffsetX` |
| 206 | `CalcOffsetY` |
| 215 | `CalcOffsetSpanningStartX` |
| 229 | `CalcOffsetSpanningEndX` |
| 243 | `CalcOffsetSpanningStartY` |
| 264 | `CalcOffsetSpanningEndY` |
| 285 | `CalcOffsetBezier` |

Membros de `View` (de `view.h`): `m_doc`, `m_options`, `m_currentPage`, `m_currentColor`,
`m_slurHandling`, `m_drawingScoreDef`, `m_currentOffsets`, mais a struct interna `Offset`
(`m_ho`, `m_vo`, `m_startho`, `m_startvo`, `m_endho`, `m_endvo`, `m_object`, `m_staffSize`).

`SlurHandling` é um enum — ache-o (`grep -rn "enum class SlurHandling" origin/src/include/vrv/`).

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view.dart` — `class View`, `class Offset`, todo o conteúdo de
  `view.cpp`. Os métodos `Draw*` dos outros `view_*.cpp` **não** entram aqui: cada tarefa seguinte
  os acrescenta em `part`/`extension` (decida qual e justifique — o C++ os divide em arquivos,
  e `part of` é o equivalente Dart mais fiel).
- **Alterar** `lib/src/core/vrvdef.dart` se faltar `SlurHandling` ou constantes de View.
- **Criar** `test/view_test.dart`.

## Passo a passo

1. Leia `view.h` inteiro e `view.cpp` inteiro (342 linhas).
2. Decida a estratégia de particionamento antes de escrever a primeira linha: `view.dart` com
   `part 'view_graph.dart'`, `part 'view_page.dart'`, etc., espelhando os arquivos do C++.
   **Registre a decisão no relatório** — todas as tarefas seguintes vão depender dela.
3. Porte a classe `View` e a struct `Offset`.
4. Porte as conversões de coordenada. Elas dependem de `Doc` (fatores de escala e PPU) —
   confira o que já existe (`grep -n "ppuFactor\|drawingPageHeight\|drawingPageWidth" lib/src/model/doc.dart`).
5. Porte `IntToTupletFigures`, `IntToTimeSigFigures`, `IntToSmuflFigures` — convertem um inteiro numa
   string de códigos SMuFL de dígito. Teste-as isoladamente: são fáceis e são usadas em toda parte.
6. Porte a pilha de offsets (`StartOffset` … `CalcOffsetBezier`).
7. Testes: conversões lógico↔dispositivo de ida e volta (`toLogicalX(toDeviceContextX(x)) == x`),
   as três funções `IntTo*Figures` com valores conhecidos, e um cenário de offset aninhado.
8. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 382 testes**
- [ ] `grep -c "^class View" lib/src/rendering/view.dart` = 1
- [ ] Toda função de `view.cpp` tem contraparte — prove no relatório colando o diff de nomes
      entre `grep -oP '^\w[\w:*& ]*View::\K\w+' origin/src/src/view.cpp` e os métodos do Dart
- [ ] Teste de ida e volta das conversões passa para ao menos 20 valores, incluindo negativos e zero
- [ ] Relatório em `prompts/reports/05-06.md`, com a decisão de particionamento explicada
- [ ] `PLANO.md`: checkbox de `view.cpp` marcado

## Armadilhas conhecidas

- **`ToLogicalY` não é o inverso trivial de `ToDeviceContextY`**: o eixo Y é invertido e há o offset
  da página. Leia as duas (84-102) juntas.
- `m_currentOffsets` é uma `std::list` usada como pilha, mas `CalcOffsetSpanning*` percorre a lista
  inteira, não só o topo. Uma pilha simples do Dart não basta.
- `SetPage(page, doLayout)` com `doLayout = false` é o caso usado pelo `BBoxDeviceContext` — o C++
  comenta "Do not do the layout in this view - otherwise we will loop...". Porte o parâmetro.
- `m_drawingScoreDef` é uma **cópia** do scoreDef corrente, não uma referência. Copiar por referência
  aqui produz corrupção difícil de achar.

## Fora de escopo

- Qualquer `Draw*`. Esta tarefa é só a infraestrutura.
