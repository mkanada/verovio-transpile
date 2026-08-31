# 05r2a — doc.dart: Dots vazios (0 vs 1 ellipse) — CalcDots não refeito após ResetHorizontalAlignment

## Contexto

Correção de `lib/src/model/doc.dart` (`Page.layOutVertically`) para `dot/dot-001.mei` e toda família `dot` (6 arquivos) e `rest`/`beam` com dots.

Trabalhe a partir de `verovio_dart/`. Não commite.

## A divergência

    dart run tool/compare_svg.dart test/corpus/dot/dot-001.mei
      # primeiro divergente antes do fix:
      svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[2]/g[0]/g[1]: esperado [1 filhos] (ellipse), obtido [0 filhos] (vazio)
      # Dots sob Note em `measure[1]/staff[1]/layer[1]/note[1]` etc. — todo `note` com `dots="1"` tinha Dots vazio.

    tool/_dot_after.dart (debug) após `prepareData` mas antes de `layOut`:
      dots id=c1OJZ9W4 map={Staff: {6}} dots=1  # ok
    após `page.layOut()`:
      dots id=cQYAZZS map={} dots=1  # vazio! Após ResetHorizontalAlignment sem refill.

    compare_svg --all antes: dot 0/6, rest 2/21, beam 37/61 — após: dot ainda 0/6 (mas Dots agora tem 1 ellipse onde antes 0, primeiro divergente migrou para barLine extra)

## A causa (já diagnosticada — não investigue, aplique)

`Dots::GetMapOfDotLocs()` é preenchido por `CalcDotsFunctor` (`calcdotsfunctor.cpp`) durante `Doc::PrepareData` (doc.cpp) e também durante `Page::LayOut` (`page.cpp:294` e `382`) **após** cada `ResetHorizontalAlignmentFunctor` (`page.cpp:262,327`). O `ResetHorizontalAlignmentFunctor::VisitDots` (`resetfunctor.cpp:627`) faz `dots->ResetMapOfDotLocs()`.

O Dart em `lib/src/model/doc.dart:548` faz `CalcDots` durante `Doc.prepareData`, mas `Page.layOutVertically` (`doc.dart:620`) faz `ResetHorizontalAlignment` (via `ResetHorizontalAlignmentFunctor` em `align_horizontally.dart:119`) sem nunca refazer `CalcDots` depois. Resultado: mapa limpo no `prepareData` é esvaziado no `layOut` e permanece vazio no `View::DrawDots` (`view_element.cpp:870`), então `drawDotsPart` nunca é chamado e o `<g class="dots">` fica vazio.

O C++ refaz `CalcDots` em `Page::LayOut` e `Page::ResetAligners` (page.cpp:294,382) **após** o reset, antes do `BBoxDeviceContext` render. O Dart não.

## A correção

Em `lib/src/model/doc.dart:643` (`Page.layOutVertically`), após `CalcLigatureOrNeumePos` e antes de `CalcLedgerLines` (mesma ordem do C++ `page.cpp:382`), acrescente:

```dart
    final calcDots = CalcDotsFunctor(doc);
    process(calcDots);
```

Já importado em `doc.dart:117` (`CalcDotsFunctor`). Não acrescente `CalcStem`/`CalcChordNoteHeads` aqui — eles já são feitos em `Doc.prepareData` e refazê-los no `Page` causa regressão em `cross-staff` (3→1 limpos) como medido em 2026-08-31.

Ordem exata (C++ `page.cpp:376-383`):
```
CalcAlignmentPitchPos
CalcLigatureOrNeumePos
CalcStem (já em Doc.prepareData, não repetir no Page)
CalcChordNoteHeads (já em Doc.prepareData)
CalcDots  ← este é o que faltava no Page
CalcLedgerLines
render BBox
```

## Verificação

    dart run tool/_dot_after.dart  # custom debug: após layOut, map deve ser {Staff: {loc}} não {}
    # deve imprimir map={Staff: {6}} etc. após layOut

    dart run tool/compare_svg.dart test/corpus/dot/dot-001.mei
    # antes: primeira divergência em dots 0 vs 1; depois: migra para barLine (5 vs 4) — Dots agora com 1 ellipse

    tool/task_check.sh doc.dart dot
    # PASS (debt 0, analyze 8, testes sem exceção)

    dart run tool/compare_svg.dart --all  # 116→126 estrutural esperado (dot ainda 0/6 mas beam 37→40, cross-staff 3→4 etc.)

O Haiku só termina quando `tool/_dot_after.dart` mostrar map não vazio e `task_check` PASS.
