# invest-03 — tie-011: 93 dos 102 divs de tie (LV + fim timestamp)

**Status: ENCERRADO (2026-09-09).** Critério de aceite atingido — tie está
em 9/12 arquivos limpos, **9 divs totais** (≤ 12, era 93 só no tie-011) —
via commit `8259ace2` ("invest-03 tie-011 — Note.CalcStemLenInThirdUnits
chord dur em headless"). A causa real **não** foi a hipótese abaixo (guard
`Lv::CalculatePosition` / geometria de `tstamp2`): foi
`Note.CalcStemLenInThirdUnits` usando `getActualDur()` em vez de
`GetDrawingDur()` para a nota mais aguda de um acorde headless
(`note.cpp:585-594`), o que deslocava a página inteira em -60 por faltar o
cap de "shortening" de colcheias fora de beam. `Lv`/tie-endpoints
continuam corretos e não precisam de porte. Resíduos remanescentes
(tie-009 Δ1, tie-010 5 divs, tie-012 Δ378) são gaps documentados à parte,
fora do escopo deste prompt — não reabrir por causa deles. Achados abaixo
preservados como registro histórico da investigação (a hipótese estava
errada, mas os achados de `_hasAdjacentNotesInStaff`/grace/cross-staff
seguem válidos).

**Objetivo.** Zerar (ou explicar por fixture) os 93 divs numéricos de
`test/corpus/tie/tie-011.mei` — 90% da categoria tie (12 arq, 8 limpos,
102 divs no baseline `tool/SVG_VALIDATION.md`).

**Achados já provados (não reinvestigar).** Medição por arquivo (sessão
2026-09-09):

| arquivo | divs | conteúdo | atribuição |
|---|---|---|---|
| tie-011 | 93 | só `<lv>` (16×), zero `<tie>`; fim = `tstamp2` (timestampAttr); acordes multicamada | NÃO é `_hasAdjacentNotes` nem `m_measureTieEndpoints`. Candidatos: guard `Lv::CalculatePosition` (lv.cpp:40-56: exige `SPANNING_START_END` + mesmo compasso) **não portado** (`Lv` sem override em `control_elements_gen.dart`) + geometria X de fim-timestamp |
| tie-012 | 1 (Δ=378) | ties cross-measure + slurs `tstamp` | fora de `GetInternalTieEndpoints` por construção |
| tie-010 | 5 | ties cross-measure, acordes `stem.dir=down` + dynam | mistura tie-chord + dynam |
| tie-009 | 3 (Δ=1) | 4 ties same-measure, notas simples com beam | GAP-B inerte (sem `CHORD` ancestral / sem `FLAG`) — Δ=1 é outra fonte |
| tie-006 | limpo | 6× `bulge="1 50"` | bulge em tie é inerte nos dois lados (ver invest-05) |

- `_hasAdjacentNotesInStaff`/`getAdjacentNotesList` JÁ equivalem ao C++
  (commit desta semana: `crossStaff ?? ancestor` → `getCrossStaff().$1
  ?? ancestor`, i.e. `GetAncestorStaff(RESOLVE_CROSS_STAFF)`); resto da
  divergência cross-staff-split sem veículo no corpus.
- Ramo grace (`gracenote-009`, 1 `<tie>`) limpo: GAP-B sem efeito hoje.

**Veículo.** `test/corpus/tie/tie-011.mei` (primeira divergência e resto via
`compare_svg test/corpus/tie/tie-011.mei`).

## Passos sugeridos (protocolo do loop)

1. `probe_diff test/corpus/tie/tie-011.mei` (ou patch de probe em
   `Tie::CalculatePosition`/`Lv::CalculatePosition`: start/end X por
   registro) para separar: (a) guard LV ausente, (b) X de fim-timestamp,
   (c) `UpdateTiePositioning`/`AdjustEnharmonicTies`.
2. Portar o que o probe apontar, na ordem: guard LV → fim-timestamp →
   resto. Checar `lv.cpp:40-56` na íntegra + callers.
3. Medir `compare_svg test/corpus/tie` (alvo 102→~9) + `slur` (regressão
   de curva).

## Aceite

- tie-011 limpo ou com fixture cravando resíduo irredutível (§7 do
  `00-MESTRE.md`); tie total ≤ 12 divs; `dart analyze` 0; suite verde.
