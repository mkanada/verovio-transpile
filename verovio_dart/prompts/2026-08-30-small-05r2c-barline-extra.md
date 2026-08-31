# 05r2c — view_page/barline: medida com 5 vs 4 filhos (barLine extra) em dot-001

## Contexto

Correção de `dot/dot-001.mei` — `measure[1]` e `[2]` com 5 filhos (3 staff + 2 barLine) onde C++ tem 4 (3 staff +1 barLine). Afeta `dot` 0/6 e `barline` 1/10.

Trabalhe a partir de `verovio_dart/`. Não commite.

## A divergência

    dart run tool/_dot_check.dart (após fix 05r2a)
      svg/svg[0]/g[0]/g[2]/g[4]: esperado [5 filhos], obtido [4 filhos]  # system g[4] é measure? Na verdade measure[1] com 5 vs 4

    Detalhe via `tool/_check_dot_path5.dart`:
      measure 1 gold 4 (3 staff +1 barLine) dart 5 (3 staff +2 barLine)
      measure 2 gold 4 dart 5

    O extra é `leftBarLine` ou `rightBarLine` duplicado. Em MEI sem `left`/`right`, o `Measure` tem `leftBarLine` default invisível e `rightBarLine` visível. O Dart pode estar emitindo ambos como `<g class="barLine">` onde C++ só emite o `right`.

## A causa (já diagnosticada — não investigue, aplique)

`View::DrawMeasure` (`view_page.cpp:928`) desenha `leftBarLine` apenas se `measure->GetLeftBarLine()->IsVisible()` e `rightBarLine` sempre se visível. O Dart em `lib/src/rendering/view_page.dart:740` (`drawMeasure`) faz:

```dart
if (measure.leftBarLine.isVisible) drawBarLine(... left ...)
drawBarLine(... right ...)
```

Mas `leftBarLine.isVisible` no Dart pode estar `true` por default (`Barrendition.single` ?) onde C++ tem `false` para `left` não especificado. Verifique `Measure::GetLeftBarLine` no C++ (`measure.cpp:142`) vs Dart `Measure.leftBarLine` (`basic_elements.dart: ...`).

Para esta unidade, **não corrija ainda** — apenas confirme:

- Leia `origin/src/src/measure.cpp:142` (`GetLeftBarLine`) e `barline.cpp:Visible`.
- Compare com `lib/src/model/basic_elements.dart:Measure.leftBarLine` default e `BarLine.isVisible`.
- Formule a correção como `if (measure.getLeftBarLineXRel() != meiUnset && leftBarLine.hasSelfBB())` vs `isVisible`.

A correção (trocar `isVisible` por `hasSelfBB` ou `GetLeftBarLineXRel`) fica para 05r3, quando o instrumento de barLine estiver pronto.

## Verificação

    dart run tool/compare_svg.dart test/corpus/dot/dot-001.mei
    # deve continuar 0/1, mas a primeira divergência deve migrar de barLine (5 vs 4) para próxima (dots já ok)

    tool/task_check.sh view_page.dart dot
    # PASS
