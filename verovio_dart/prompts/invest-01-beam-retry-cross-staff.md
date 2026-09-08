# invest-01 — Religar o retry `NeedToResetPosition` do beam misto (cross-staff)

**Objetivo.** Portar o retry de `BeamSegment::CalcBeam` (beam.cpp:131-135:
`CalcBeamInit` + `CalcBeamStemLength` + `CalcBeamPosition` de novo quando
`NeedToResetPosition` retorna true) sem regressão estrutural, fechando
`prompts/desvios-documentados.md` §1.3.

**Estado atual (2026-09-09, verificado).** O retry está DESLIGADO de propósito
em `lib/src/model/beam_segment.dart` (ver comentário no fim de `calcBeam`):
uma tentativa fiel religou e deu cross-staff **1402→1352 divs numéricos,
mas 9→95 estruturais** (só `cross-staff-004`: 1→87). Revertido; a árvore está
no estado pré-retry. Não religue sem antes resolver o invest-02 (causa raiz
a montante) — o retry amplifica aquele mismatch.

**Veículo.** `test/corpus/cross-staff/cross-staff-004.mei` (6 compassos,
MEI m51–m56; beams com `beam.with=below`, cross-staff, tuplets).

## Achados já provados (não reinvestigar)

1. **Decisões do retry batem 100% com o C++.** Fixture `NeedResetIn/Out`
   (patch cpp_probe 05-51, REVERTIDO — recriar §5): `m51/beam[3]` rel
   `(2,2,1)` e `m54/beam[2]` rel `(1,1,2,2)` ficam mixed (`ret=0`); todos os
   demais `all-same` colapsam (`ret=1`, `newPlace=1=above`). O Dart produz
   exatamente os mesmos 4 padrões de `relPlaces` (conferido por print
   temporário, 216 chamadas). `calcMixedBeamPlace` está correto.
2. **yBeam pós-segundo-passe bate para m51–m55** (steady-state, 16x):
   m51/b1 −90, b2 −270, b3 mixed (−1575,−1644,−1755), b4 −1440;
   m52/b1 −1710, b2 −1890, b3 −1980, b4 −2160; m53/b1 −2160; m54/b1 −1890,
   b2 mixed (−1845,−1774,−1735,−1665); m55/b1 −270, b2 −1440.
   Iguais ao `BeamYBeam` do C++ (a menos de Δ1 numa variante de m54/b2).
3. **`IsHorizontal` tem que ler o `drawingPlace` STALE (ordem exata do C++).**
   `IsHorizontal()` roda antes de `CalcBeamPlace` (beam.cpp:104-112); na
   passada seguinte ao colapso ele lê `above` (não `mixed`) e toma o ramo
   horizontal (`CalcHorizontalBeam` → max → −1440). Ler o place
   recém-resolvido (como o código fazia até 2026-09-04 por causa do flap
   `barline-007`) mantém `mixed` → ramo slope → −1710. A reordenação para a
   ordem fiel, SOZINHA, não regrediu nada (004 ficou em 1/271).
4. **Armadilha do segundo passe:** ele precisa ser o MESMO código do primeiro
   (extrair `_calcBeamPositionPhase` compartilhada: stem-length + laço
   `setDrawingStemDir` + first/last **com** o fixup `closestNote` de chord +
   slope + ledger). Uma tentativa que duplicou o bloco sem o fixup regrediu
   sozinha.
5. `uniformStemLength`, `closestNote.Y`, `vCenter`, `unit` do segundo passe
   conferem (ex. m51/b4: 10, (−2160,−1890,−2430), −900, 90).

## O que falta descobrir

- Com yBeams iguais, o SVG diverge em **ledgers/staff-Y** (staff 2 Δ251,
  +6 paths `ledgerLines below`, beam polygon Δ386): sintoma a jusante, não
  no beam. Suspeita principal: overflows lidos de `yBeam` de passes
  intermediários (não-finais) ou stems do invest-02. Comparar
  `RequestStaffSpace`/`getMinimalStemLength` e `CalcBBoxOverflows` por
  passada antes de culpar o retry.
- `m51/b2` roda 14 passes contra 16 dos demais — entender por quê.

## Passos sugeridos (protocolo do loop, `loop-prompt.md` §3)

1. Recriar o patch de probe 05-51 (estava em `cpp_probe/patches/05-51.patch`,
   revertido; recriar via `cpp_probe/sync.sh`, editar
   `build-probe/src/src/beam.cpp` com fprintf-only em `NeedToResetPosition`
   (In/Out), fim de `CalcBeam` (`BeamYBeam`), fim de `CalcBeamStemLength`
   (`BeamStemLen`), fim de `SetDrawingStemDir` (`BeamCoord`),
   `cpp_probe/mkpatch.sh 05-51` (tem que dar 0 remoções lógicas),
   `cpp_probe/build.sh 05-51`, `cpp_probe/run.sh` + `diff` vazio contra
   `build/verovio` (regra 3 do `cpp_probe/README.md`).
2. Resolver o invest-02 PRIMEIRO (stems sem beam + shift de staff).
3. Religar o retry via fase compartilhada (item 4 acima), com a ordem fiel
   de `IsHorizontal` (item 3).
4. Medir: `compare_svg test/corpus/cross-staff test/corpus/beamspan
   test/corpus/beam` + `barline-007` (guardião do flap) antes/depois.

## Aceite

- cross-staff numeric < 1402 E estrutural ≤ 9; beamspan < 224;
  `barline-007` sem mudança; `dart analyze` 0; suite verde.
- Nunca commitar retry com estrutural maior (precedente 1→87).
