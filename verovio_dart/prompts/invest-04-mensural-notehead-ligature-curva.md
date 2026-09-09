# invest-04 — Notehead/stem-X mensural + ligadura curva (13 divs, 5 arquivos)

**Status: ENCERRADO (2026-09-09).** Critério de aceite atingido —
mensural 25/25 e ligature 50/50 limpos. Item 1 (raio mensural) já tinha
fechado via `aa870b86`. O residual (mensural-001/002/003 + ligature-045,
10 divs) fechou em duas causas que NÃO são as do item 3 abaixo (a curva
`DrawBentParallelogramFilled` já estava correta, per `aa870b86`):
`Doc.convertToCastOffMensuralDoc` (doc.dart) rechamava `prepareData()`
condicionalmente (`if (!dataPreparationDone)`) quando o C++
(`doc.cpp:1432`) rechama incondicionalmente — sem essa segunda passada
os ponteiros `Dot.drawingNextElement`/`drawingPreviousElement` ficavam
presos ao estado pré-divisão mensural, em TODO doc mensural do corpus,
não só nos 3 arquivos com veículo; e `mensural_neume.dart` usava
`meiUnset` onde o C++ usa `-VRV_UNSET` (sinal trocado), fazendo notas de
ligadura preta empilharem sempre em vez de nunca. Achado incidental: a
ferramenta `tool/probe_diff.dart` nunca rodava cast-off nem a conversão
mensural (só `svg_compare.dart` fazia), por isso não conseguia
pinpointear nenhum dos dois — extraído o pipeline comum para
`prepareDocForRendering` (svg_compare.dart), usado por ambos agora.
Detalhes completos em `prompts/loop-diario.md`, entrada 2026-09-09.

**Objetivo.** Portar os dois ramos mensurais com veículo confirmado,
zerando `mensural-001/002/003/006` e `ligature-045`.

**Achados já provados (não reinvestigar).** Pesquisa 2026-09-09, veículos
confirmados por categoria (mensural 25 arq/4 divergentes/8 divs; ligature
50 arq/1 divergente/5 divs):

1. **Raio/stem-X mensural** (`calc_ledger_lines.dart:238-245`,
   `mensural_neume.dart:14-18,459+`): `_noteDrawingRadius` usa noteheads
   comuns (E0A1/E0A2/E0A3/E0A4); o C++ (`note.cpp:499-515`,
   `GetStemUpSE/DownNW`) usa `GetMensuralNoteheadGlyph()` (E938/E93C/E93D,
   `note.cpp:601-639`) quando `IsMensuralDur()` — larguras diferentes ⇒ X
   de attach do stem e largura de head diferentes. Veículos:
   `mensural-001/002/003` (2 divs cada, Δ45–49 em `polygon points[0]` —
   losangos de notehead: ex. `8635,7119 8680,7074…`; `mensural-001` só tem
   minimas/semínimas/fusas, sem `<ligature>`) e `mensural-006` (2 divs,
   `path d[2] 954→972`, Δ=18; só brevis — largura brevis,
   `GetDrawingBrevisWidth` vs aproximado; pedir `probe_diff` para cravar
   ledger vs head). `mensural-003` ainda contém `<ligature>` (soma o item 3).
2. **`@glyph.name`/`@head.shape|fill`** (`note.cpp:640+`, tabela
   `additionalNoteheadSymbols`, ramos diamond/rectangle/slash/x): SEM
   veículo hoje (`rg` não achou no corpus) — confirmar com grep antes de
   portar; não portar por conta própria.
3. **Ligadura curva** (`view_mensural.dart:31-35`): ramo curvo
   (`DrawBentParallelogramFilled`, view_mensural.cpp:407-431) cai para
   `drawObliquePolygon` reto. Veículo: **`ligature-045` (5 divs, Δ até
   558: `d[0] 12756→12612`)** — contém `lig="obliqua"` E staff
   `notationtype="mensural.black"`, e o C++ escolhe curvo também no
   default (`case LIGATURE_OBL_auto: straight = !isMensuralBlack`,
   view_mensural.cpp:363-367). O comentário do Dart ("sem
   `ligatureOblique=curved` no corpus" — `ligature-050` fixa `straight`,
   nenhum fixa `curved`) erra na conclusão: o fallback reto É exercitado
   via `auto`+black. Corrigir o comentário ao portar.

## Passos sugeridos

1. (i) Portar o ramo mensural de stem-X/head (`GetMensuralNoteheadGlyph`
   + larguras E93x via resources, com fallback) — valida em
   `mensural-001/002/003/006`; (ii) `DrawBentParallelogramFilled` curvo
   (paralelogramo curvado ≈ dois segmentos Bézier — checar primitivas de
   curva do `DeviceContext` do Dart) — valida em `ligature-045`;
   (iii) `@glyph.name/head.shape` por último, só com veículo.
2. `probe_diff` antes de cada edição (polígono/largura por registro).
3. Medir `compare_svg test/corpus/mensural test/corpus/ligature`
   (alvo 13→0) + `neume` (regressão).

## Aceite

- mensural 25/25 + ligature 50/50 limpos; `dart analyze` 0; suite verde.
