# 05-03 — SvgDeviceContext: primitivas geométricas, pen e brush

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Preencher todos os `Draw*` geométricos do `SvgDeviceContext` e a tradução de `Pen`/`Brush` para
atributos SVG (`stroke`, `stroke-width`, `stroke-linecap`, `stroke-linejoin`, `stroke-dasharray`,
`fill`, `fill-opacity`).

## Pré-condições

Tarefa **05-02** concluída.

```bash
cd verovio_dart
grep -c "TODO(05-03)" lib/src/rendering/svg_device_context.dart   # > 0
dart test 2>&1 | tail -1                                           # verde, ≥ 328
```

## Referência C++

De `origin/src/src/svgdevicecontext.cpp`:

| Linha | Função |
|---:|---|
| 602 | `AppendStrokeLineCap` |
| 612 | `AppendStrokeLineJoin` |
| 624 | `AppendStrokeDashArray` |
| 633 | `PrefixCssRules` |
| 670 | `DrawQuadBezierPath` |
| 693 | `DrawCubicBezierPath` |
| 717 | `DrawCubicBezierPathFilled` |
| 740 | `DrawBentParallelogramFilled` |
| 761 | `DrawCircle` |
| 766 | `DrawEllipse` |
| 797 | `DrawEllipticArc` |
| 866 | `DrawLine` |
| 888 | `DrawPolyline` |
| 918 | `DrawPolygon` |
| 954 | `DrawRectangle` |
| 959 | `DrawRoundedRectangle` |
| 1196 | `DrawSpline` |
| 1198 | `DrawGraphicUri` |
| 1208 | `DrawSvgShape` |
| 1222 | `DrawBackgroundImage` |
| 1274 | `GetColor` |
| 1296 | `DrawSvgBoundingBoxRectangle` |
| 1320 | `DrawSvgBoundingBox` |

Mais `origin/src/include/vrv/devicecontextbase.h` para `Pen` e `Brush`, e a base
`DeviceContext::SetPen`/`SetBrush` (`origin/src/src/devicecontext.cpp`), já portadas em
`lib/src/rendering/device_context.dart:115-157`.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/svg_device_context.dart`.
- **Alterar** `test/svg_device_context_test.dart`.

## Passo a passo

1. Leia as faixas acima. `DrawEllipticArc` (797-865) é a mais longa e a mais fácil de errar: ela
   converte ângulos em parâmetros do comando `A` do SVG. Leia-a por inteiro antes de escrever.
2. Porte `GetColor` primeiro — todo o resto depende dela para a string de cor.
3. Porte `AppendStrokeLineCap`, `AppendStrokeLineJoin`, `AppendStrokeDashArray`, que traduzem `Pen`.
4. Porte os `Draw*` na ordem em que aparecem no `.cpp`.
5. Porte `DrawSvgBoundingBox` e `DrawSvgBoundingBoxRectangle` (usadas pela opção
   `svgBoundingBoxes`); elas ficam desligadas por default, mas o corpo tem de existir.
6. Testes: para cada primitiva, um caso que produz um elemento SVG e compara a string exata contra um
   literal derivado do C++. Onde a saída depende de `Pen`/`Brush`, teste ao menos dois estados.
   Use os goldens como fonte: `grep -o '<ellipse[^>]*>' test/golden/cpp/**/*.svg | head` dá exemplos reais.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 348 testes** (ao menos um teste por primitiva)
- [ ] `grep -c "UnimplementedError" lib/src/rendering/svg_device_context.dart` cobre **só** os
      métodos de texto/glifo da tarefa 05-04 — os geométricos sumiram
- [ ] `grep -c "TODO(05-03)" lib/src/rendering/svg_device_context.dart` = 0
- [ ] Cada teste de primitiva compara **string exata**, não `contains`
- [ ] Relatório em `prompts/reports/05-03.md`
- [ ] `PLANO.md`: checkbox de `SvgDeviceContext` (05-03) marcado

## Armadilhas conhecidas

- **Formatação de número.** O C++ emite inteiros como inteiros e `double` com um número específico de
  casas. `2.0` em Dart vira `"2.0"` por default, e o C++ emitiria `"2"`. Escreva um helper de
  formatação **desde a primeira primitiva** e use-o em todas — é a causa número um de divergência
  numérica em massa nesta fase.
- `DrawEllipticArc`: os flags `large-arc` e `sweep` do SVG são calculados no C++; copiar a fórmula
  errada dá arcos visualmente parecidos e numericamente errados.
- `DrawCubicBezierPathFilled` recebe **duas** curvas e monta um caminho fechado; a ordem em que a
  segunda é percorrida (invertida) importa.
- `DrawPolyline` tem um parâmetro `close`; `DrawPolygon` sempre fecha. Não unifique.
- Divisão inteira nas conversões de coordenada: `~/`, não `/`.

## Fora de escopo

- `DrawText`, `DrawMusicText`, `StartText`, `MoveTextTo`, `DrawRotatedText`, `InsertGlyphRef`,
  `IncludeTextFont` — tarefa 05-04.
