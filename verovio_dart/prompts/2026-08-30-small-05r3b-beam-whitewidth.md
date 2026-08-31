# 05r3b — doc.dart: beamWhiteWidth não inicializado → DrawBrace xdec deslocado

## Contexto

Correção de `lib/src/model/doc.dart` (`updatePageDrawingSizes`) para `arpeg/arpeg-003.mei` e 8 arquivos com `DrawCurve` de brace (view_page.cpp:588 `DrawBrace`).

Trabalhe a partir de `verovio_dart/`. Não commite.

## A divergência

    dart run tool/probe_diff.dart test/corpus/arpeg/arpeg-003.mei
      seq 8  fn=DrawCurve  path=pages[1]/page[1]/system[1]/scoreDef[?]/staffGrp[1]/grpSym[1]
        bezier1:   esperado -72,3771 -432,3231 18,2709 -252,2529   obtido -72,3771 -432,3231 18,2709 -252,2529  # ok
        bezier2:   esperado -72,3771 -369,3231 81,2709 -252,2529   obtido -72,3771 -414,3231 36,2709 -252,2529  # Δ -45 em x
      origem: View::DrawBrace / DrawThickBezierCurve (view_page.cpp:622, 359)

    dart run tool/probe_diff.dart --dir=test/corpus --rank
      8  DrawCurve :: View::DrawThickBezierCurve (antes) → 0 após fix

## A causa (já diagnosticada)

`View::DrawBrace` (`view_page.cpp:622`) faz `fact = GetDrawingBeamWhiteWidth(staffSize,false) + GetDrawingStemWidth(staffSize)` e `xdec = ToDeviceContextX(fact)`. O C++ inicializa `m_drawingBeamWhiteWidth = m_unit.GetValue()/2` em `Doc::UpdateDrawingValues` (`doc.cpp:2390-2391`). Com `unit` default 9 e `DEFINITION_FACTOR 10`, o valor é `90/2=45` a `staffSize 100` (`options.unit.value` já inclui o fator, `options_shell.dart:68`).

O Dart `Doc.updatePageDrawingSizes` (`doc.dart:1817`) nunca inicializava `drawingBeamWhiteWidth` nem `drawingBeamWidth` — ficavam 0. Resultado: `getDrawingBeamWhiteWidth(100)` devolvia 0, `fact = 0 + stemWidth(18)=18` vs C++ `45+18=63`, `xdec` 18 vs 63, Δ45 nos dois pontos médios do brace (`81→36` e `-369→-414` são ambos `x` com Δ45, o `y` não muda; a leitura anterior confundiu `x,y`).

## A correção

Em `lib/src/model/doc.dart:1845` (`updatePageDrawingSizes`), após:

```dart
drawingPageContentWidth = drawingPageWidth - drawingPageMarginLeft - drawingPageMarginRight;

drawingSmuflFontSize = options.unit.value.toInt() * 8;
```

acrescente (mirrors `doc.cpp:2390-2391`):

```dart
// Mirrors Doc::UpdateDrawingValues beam widths (doc.cpp:2390-2391):
drawingBeamWidth = options.unit.value.toInt();
drawingBeamWhiteWidth = (options.unit.value / 2).toInt();
```

Não acrescente `drawingBeamMaxSlope` — a opção não existe no shell Dart ainda. Não precisa copiar `drawingBrevisWidth` (depende de glyph, calculado sob demanda).

## Verificação

    dart run tool/probe_diff.dart test/corpus/arpeg/arpeg-003.mei
    # antes: seq 8 DrawCurve bezier2 x -369 vs -414
    # depois: seq 8 limpo, migra para seq 67 DrawLine Staff (x2 2949 vs 4849, Δ -8) — brace agora bate

    dart run tool/probe_diff.dart --dir=test/corpus --rank
    # DrawCurve deve sair do ranking (8→0), DrawLine Staff sobe 216→224

    dart run tool/compare_svg.dart --all  # Numérico 10→12 esperado (score 6/1→6/3), estrutural permanece 126 (brace é numérico, não estrutural)
    dart analyze  # 8
    tool/task_check.sh doc.dart arpeg
    # PASS
