# 05-02 — SvgDeviceContext: documento, página e grupos gráficos

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Criar `SvgDeviceContext` com o **esqueleto do documento SVG**: raiz `<svg>` com os atributos do C++,
`<desc>`, `<defs>`, abertura/fechamento de página, e o mecanismo de grupos `<g>` com `id` e `class`
que envolve todo objeto desenhado. Ao final, um documento vazio produz um SVG estruturalmente
idêntico ao do C++ para um MEI trivial.

## Pré-condições

Tarefa **05-01** concluída.

```bash
cd verovio_dart
grep -c "dart:io" lib/src/rendering/resources.dart     # 0
dart test 2>&1 | tail -1                                # verde, ≥ 320
```

## Referência C++

`origin/src/include/vrv/svgdevicecontext.h` inteiro, e de `origin/src/src/svgdevicecontext.cpp`
(1.417 linhas) **estas faixas**:

| Linha | Função |
|---:|---|
| 38 | `SvgDeviceContext::SvgDeviceContext` (construtor — os defaults importam) |
| 82 | `CopyFileToStream` |
| 148 | `Commit` |
| 249 | `StartGraphic` |
| 360 | `StartCustomGraphic` |
| 367 | `StartTextGraphic` |
| 418 | `ResumeGraphic` |
| 429 | `EndGraphic` |
| 436 | `EndCustomGraphic` |
| 442 | `SetCustomGraphicColor` |
| 448 | `SetCustomGraphicAttributes` |
| 453 | `EndResumedGraphic` |
| 459 | `EndTextGraphic` |
| 466 | `RotateGraphic` |
| 475 | `StartPage` |
| 547 | `EndPage` |
| 558-590 | `SetBackground`, `SetBackgroundImage`, `SetBackgroundMode`, `SetTextForeground`, `SetTextBackground`, `SetLogicalOrigin`, `GetLogicalOrigin` |
| 591 | `AddChild` |
| 1224 | `AddDescription` |
| 1230 | `AppendIdAndClass` |
| 1260 | `AppendAdditionalAttributes` |
| 1289 | `GetStringSVG` |

Golden de referência para conferir a forma: `test/golden/cpp/note/note-001.svg`. As três primeiras
linhas do que o C++ emite:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="2100px" height="2970px" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" overflow="visible" id="o3u8kcw">
   <desc>Engraved by Verovio 6.2.0</desc>
```

Atenção: **a indentação é de 3 espaços** e a ordem dos atributos é significativa para a comparação
byte a byte que é a meta final.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/svg_device_context.dart` — só as partes desta tarefa; os `Draw*`
  ficam nas tarefas 05-03 e 05-04, com `throw UnimplementedError()` por enquanto **e um TODO
  nomeando a tarefa que os preenche**.
- **Alterar** `lib/src/core/vrvdef.dart` se faltar `ClassId` para o device context.
- **Criar** `test/svg_device_context_test.dart`.

## Passo a passo

1. Leia o header e as faixas listadas acima.
2. Escolha a representação da árvore SVG em memória. O C++ usa pugixml e monta um `pugi::xml_document`;
   o Dart tem `lib/src/io/xml_node.dart` (`MeiXmlNode`, mutável, espelhando pugixml) — **reutilize-o**
   em vez de inventar outra árvore. Se ele não servir, diga por quê no relatório antes de criar outra.
3. Porte o construtor com **todos** os defaults do C++, `StartPage`/`EndPage`, `Commit`,
   `GetStringSVG`, `AddChild`, `AddDescription`, `AppendIdAndClass`, `AppendAdditionalAttributes`,
   e a família `Start*Graphic`/`End*Graphic`/`Resume*`.
4. Implemente a serialização com a **mesma indentação (3 espaços)** e a mesma ordem de atributos
   do C++.
5. Deixe todos os `Draw*` como `UnimplementedError` com `// TODO(05-03)` ou `// TODO(05-04)`.
6. Testes: monte um `SvgDeviceContext` à mão, chame `StartPage`, dois `StartGraphic`/`EndGraphic`
   aninhados, `EndPage`, `Commit`, e compare a string resultante com um literal esperado escrito
   à mão a partir do golden. Teste também `AppendIdAndClass` com e sem id.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 328 testes**
- [ ] `grep -c "class SvgDeviceContext" lib/src/rendering/svg_device_context.dart` = 1
- [ ] O teste compara a saída de um documento mínimo com um literal e passa **com igualdade exata de
      string** (não `contains`)
- [ ] Todo método `Draw*` ainda não portado lança `UnimplementedError` e tem um `TODO(05-0N)`
      nomeando a tarefa — prove com
      `grep -c "TODO(05-0" lib/src/rendering/svg_device_context.dart` > 0
- [ ] `dart run tool/compare_svg.dart --all` continua em `0/623` (ainda não há `View`)
- [ ] Relatório em `prompts/reports/05-02.md`
- [ ] `PLANO.md`: checkbox de `SvgDeviceContext` (05-02) marcado

## Armadilhas conhecidas

- **A ordem dos atributos** no `<svg>` raiz é fixa no C++ (`width`, `height`, `version`, `xmlns`,
  `xmlns:xlink`, `overflow`, `id`). Um `Map` do Dart preserva ordem de inserção — use isso, não um
  `SplayTreeMap`.
- `StartGraphic` empilha; `EndGraphic` desempilha. `ResumeGraphic`/`EndResumedGraphic` reabrem um
  grupo já fechado — o C++ tem essa distinção de propósito (elementos que cruzam sistemas). Não
  colapse os dois pares.
- `DeactivateGraphic`/`DeactivateGraphicX`/`DeactivateGraphicY` (na base `DeviceContext`) mudam o que
  `StartGraphic` emite. Confira a interação.
- O `id` do documento é o sufixo aleatório: gere-o do mesmo jeito que o C++
  (`grep -rn "GenerateHashID\|m_xmlIdSeed" origin/src/src/`), e faça o seed ser injetável, para que
  os testes possam fixá-lo.
- `Commit` é quem fecha e serializa. Chamar `GetStringSVG` sem `Commit` no C++ dá resultado diferente.

## Fora de escopo

- Qualquer `Draw*` geométrico (tarefa 05-03) ou de texto/glifo (tarefa 05-04).
- `View` (tarefa 05-06).
