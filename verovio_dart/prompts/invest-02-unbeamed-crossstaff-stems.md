# invest-02 — Stems de notas cross-staff SEM beam (stems de ~2200, staff 2 Δ251)

**Objetivo.** Corrigir o comprimento/posição dos stems de notas cross-staff
fora de beam, que hoje saem com ~2200 unidades (esperado ~600) e deslocam a
pauta 2 (overflow → `AdjustYPos`), gerando a cascata de ledgers do
`cross-staff-004`. Pré-requisito do invest-01: o retry do beam amplifica
este mismatch (1→87 estruturais), então este item vem antes.

**Veículo.** `test/corpus/cross-staff/cross-staff-004.mei`, compasso MEI m53
(2º compasso do sistema 1 no SVG): `note-L40F2` (semínima com ponto,
`staff="2"`, cross-staff) + colcheia `staff="2"` — ambas FORA do
`beam(with=below)` de 4 colcheias do compasso. Caminho do sintoma no SVG:
`svg/svg[0]/g[0]/g[2]/g[4]/g[1]/g[0]` (`ledgerLines below`: 2 paths no C++,
8 no Dart).

## Achados já provados (não reinvestigar)

1. **É pré-existente e independente do retry do beam:** stems
   `M12416 4642 L12416 2420` e `M13409 4912 L13409 2420` (Dart) vs
   `M12404 4391 L12404 3789` e `M13396 4661 L13396 3969` (C++) — idênticos
   com retry ON e OFF. Noteheads Δ251 (shift da pauta 2: staff lines
   3609→3860). Stems de notas COM beam estão corretos.
2. **Na saída do `CalcStemFunctor`, esses stems estão sãos**
   (`len≈∓608`, `yRel≈±22`, medido por print temporário já removido) — algo
   os reescreve DEPOIS. Escritores pós-`CalcStem`: `calcSetStemValues`
   (só coords de beam — m53/b1 tem só as 4 colcheias, conferido), `justify`
   (só chords — L40F2 é `Note`), resto do `visitStem` (extensão ledger +
   `modAdjust`, ver item 3).
3. **Suspeita principal (não confirmada): extensão ledger-line com Ys não
   resolvidos.** `CalcStemFunctor::visitStem`, bloco "Ledger-line extension"
   (`lib/src/layout/calc_functors.dart`, espelha calcstemfunctor.cpp:439-472):
   `endY = stem.getDrawingY() - stem.getDrawingStemLen()` em passes
   headless (`prepareData` doc.dart:1842 sem `useDrawingY`, horizontal
   doc.dart:531) pode gerar `extendLen` espúrio e somar `(endY -
   verticalCenter)` ao `len` — em UMA passada (36 `visitStem` no arquivo
   todo: sem acumulação em massa). Medição pontual mostrou
   `extend=true` com `endY=-2790/-2520, vc=-900, len=-602` (passes
   `useDrawingY=true`) — plausível fonte do crescimento 602→~2492.
   Confirmar imprimindo `len` ANTES/DEPOIS desse bloco para L40F2 por
   passada (o print anterior quebrou em `Chord.pname` — guardar o acesso
   a `parent` com `is Note`).
4. **C++ acumula igual** (`SetDrawingYRel(GetDrawingYRel()+p.y)`,
   calcstemfunctor.cpp:379-405) e o `ResetDataFunctor::VisitStem` dos dois
   lados só zera dir+len — portanto a diferença está em nº de passes, Ys
   de entrada ou num reset que o C++ tem fora daqui. Contar passes
   `CalcStemFunctor` equivalentes no C++ (page.cpp:288/376/701 +
   `AdjustCrossStaffYPosFunctor`) vs Dart (doc.dart:531/773/1842 +
   lay_out_vertically.dart:1524 por acorde cross-staff).

## Passos sugeridos

1. `probe_diff` do stem de L40F2 (DrawingStemLen/YRel/XRel por passada) —
   ou prints temporários equivalentes — até achar a passada que estica.
2. Comparar o bloco de extensão campo a campo
   (`_verticalCenterAbsolute` vs `m_verticalCenter`, `stem.getDrawingY()`
   vs C++ no mesmo ponto do pipeline, `useDrawingY`).
3. Fix fiel ao C++ (provável: guardar a extensão para passes com Y
   resolvido, ou alinhar a ordem/reset com o C++ — decidir PELO probe,
   não por palpite).
4. Medir: `compare_svg test/corpus/cross-staff` (alvo: staff 2 Δ251→~0,
   ledgers 8→2 no 004) + `beamspan` + `chord` (regressão de stem).

## Aceite

- Stems L40F2+8ª ≈ 600–700, staff 2 sem shift, `cross-staff-004`
  estrutural ≤ 1; sem regressão em `beam/`; `dart analyze` 0.
