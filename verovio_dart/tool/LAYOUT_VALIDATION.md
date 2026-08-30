# Phase 4 layout validation

Headless pipeline: `MeiInput -> prepareData -> layOut` (breaks auto; encoded breaks honoured when the input provides layout information). Full-corpus sweep (task 04j).

- Corpus files scanned: **621** of 623 (2 skipped: non-UTF-8 by design).
- C++ reference binary (`build/verovio`): available — timemap comparison runs on CMN files only; results cached under `/tmp/validate_layout_timemap_cache`.

## Aggregate counts

| Metric | Files |
|---|---|
| Layout OK | **618** / 621 |
| All structural assertions passing | **618** / 621 |
| Timemap match | **173** |
| Timemap differ | **18** |

Of 621 files, 191 were compared against the C++ timemap (CMN categories); the rest: 84 skipped (mensural/ligature/neume categories), 36 unavailable (C++ produced no timemap), 310 with no shared note ids.

## Base numérica 04-00 vs C++ (epsilon 0)

- Arquivos com unidades batendo: **5/5** (50 valores)
- Arquivos com todos os alinhamentos batendo: **5/5** (196 valores de type/time/xRel)

## Divergências de timemap

Primeira divergência por arquivo (o `@q` é o onset do C++ em quarter units; o id é a nota onde ela nasce) — material de trabalho da tarefa 05-12:

| File | First divergence | Note id | Mismatches / compared |
|---|---|---|---|
| arpeg/arpeg-001.mei | @q=0.04 | note-0000001986960701 | 1/2 |
| beam/beam-049.mei | @q=0.05 | note-0000001704964791 | 5/10 |
| cross-staff/cross-staff-015.mei | @q=1.44 | note_24918 | 1/7 |
| cross-staff/cross-staff-019.mei | @q=3.06 | note_4164a | 2/14 |
| expansion/expansion-001.mei | @q=12.00 | n1687zus | 1/2 |
| expansion/expansion-003.mei | @q=12.00 | n1687zus | 1/2 |
| gracenote/gracenote-002.mei | @q=1.00 | note-L5F1 | 1/2 |
| gracenote/gracenote-009.mei | @q=1.88 | note-L172F1 | 1/6 |
| gracenote/gracenote-011.mei | @q=0.25 | note-L14F2 | 8/16 |
| gracenote/gracenote-016.mei | @q=0.06 | note_13074 | 3/7 |
| gracenote/gracenote-017.mei | @q=1.38 | note_9390 | 2/8 |
| gracenote/gracenote-024.mei | @q=0.94 | note-L6F1 | 14/16 |
| gracenote/gracenote-025.mei | @q=0.50 | N2 | 12/24 |
| gracenote/gracenote-026.mei | @q=0.50 | N2 | 12/24 |
| gracenote/gracenote-027.mei | @q=0.06 | note_6576a | 8/16 |
| layer/layer-006.mei | @q=5.00 | note-0000001245590624 | 1/2 |
| lyric/lyric-009.mei | @q=32.00 | note-L27F1 | 21/35 |
| trill/trill-002.mei | @q=0.50 | note-L9F2 | 1/2 |

## Summary per category

| Category | Files | Laid out | Sanity checks | Timemap |
|---|---|---|---|---|
| accid | 14 | 14 | 14 | 1 match / 0 differ / 13 no shared ids |
| annot | 7 | 7 | 7 | 5 match / 0 differ / 2 no shared ids |
| app | 3 | 3 | 3 | 1 match / 0 differ / 2 no shared ids |
| arpeg | 7 | 7 | 7 | 0 match / 1 differ / 6 no shared ids |
| artic | 19 | 19 | 19 | 3 match / 0 differ / 16 no shared ids |
| barline | 10 | 10 | 10 | 3 match / 0 differ / 3 no shared ids / 4 unavailable |
| beam | 61 | 61 | 61 | 3 match / 1 differ / 57 no shared ids |
| beamspan | 6 | 6 | 6 | 6 match / 0 differ |
| bracketspan | 1 | 1 | 1 | 1 match / 0 differ |
| breath | 2 | 2 | 2 | no shared ids |
| btrem | 6 | 6 | 6 | 2 match / 0 differ / 4 no shared ids |
| caesura | 1 | 1 | 1 | 1 match / 0 differ |
| choice | 1 | 1 | 1 | no shared ids |
| chord | 10 | 10 | 10 | 2 match / 0 differ / 8 no shared ids |
| clef | 7 | 7 | 7 | 3 match / 0 differ / 3 no shared ids / 1 unavailable |
| color | 4 | 4 | 4 | 1 match / 0 differ / 3 no shared ids |
| cpmark | 1 | 1 | 1 | no shared ids |
| cross-staff | 24 | 24 | 24 | 10 match / 2 differ / 12 no shared ids |
| custos | 1 | 1 | 1 | no shared ids |
| dir | 10 | 10 | 10 | 2 match / 0 differ / 8 no shared ids |
| dot | 6 | 6 | 6 | 1 match / 0 differ / 5 no shared ids |
| dynam | 10 | 10 | 10 | 2 match / 0 differ / 8 no shared ids |
| editorial | 2 | 2 | 2 | no shared ids |
| ending | 3 | 3 | 3 | 1 match / 0 differ / 2 no shared ids |
| expansion | 3 | 3 | 3 | 0 match / 2 differ / 1 no shared ids |
| fermata | 7 | 7 | 7 | 5 match / 0 differ / 1 no shared ids / 1 unavailable |
| figured-bass | 5 | 5 | 5 | 2 match / 0 differ / 3 no shared ids |
| fing | 2 | 2 | 2 | 2 match / 0 differ |
| font | 2 | 2 | 2 | 2 match / 0 differ |
| ftrem | 2 | 1 | 2 | no shared ids |
| gliss | 6 | 6 | 6 | 6 match / 0 differ |
| gracenote | 27 | 27 | 27 | 1 match / 9 differ / 17 no shared ids |
| hairpin | 6 | 6 | 6 | 2 match / 0 differ / 4 no shared ids |
| harm | 5 | 5 | 5 | 3 match / 0 differ / 2 no shared ids |
| keysig | 6 | 6 | 6 | unavailable |
| layer | 15 | 15 | 15 | 4 match / 1 differ / 10 no shared ids |
| ligature | 50 | 50 | 50 | skipped (mensural/ligature/neume: timemap não comparável) |
| lyric | 16 | 16 | 16 | 15 match / 1 differ |
| mdiv | 1 | 1 | 1 | unavailable |
| measure | 1 | 1 | 1 | no shared ids |
| mensur | 8 | 8 | 8 | no shared ids |
| mensural | 25 | 25 | 25 | skipped (mensural/ligature/neume: timemap não comparável) |
| metersig | 5 | 5 | 5 | 1 match / 0 differ / 4 no shared ids |
| midi | 2 | 2 | 2 | 1 match / 0 differ / 1 no shared ids |
| mnum | 1 | 1 | 1 | no shared ids |
| mordent | 5 | 5 | 5 | 5 match / 0 differ |
| neume | 6 | 6 | 6 | skipped (mensural/ligature/neume: timemap não comparável) |
| note | 12 | 12 | 12 | 2 match / 0 differ / 10 no shared ids |
| octave | 4 | 4 | 4 | 4 match / 0 differ |
| ornam | 1 | 1 | 1 | 1 match / 0 differ |
| ossia | 4 | 4 | 4 | 1 match / 0 differ / 2 no shared ids / 1 unavailable |
| pedal | 6 | 6 | 6 | 1 match / 0 differ / 5 no shared ids |
| pgfoot | 1 | 1 | 1 | no shared ids |
| phrase | 1 | 1 | 1 | 1 match / 0 differ |
| reh | 1 | 1 | 1 | 1 match / 0 differ |
| rend | 4 | 4 | 4 | 1 match / 0 differ / 3 no shared ids |
| repeatmark | 2 | 2 | 2 | unavailable |
| repeats | 8 | 8 | 8 | no shared ids |
| rest | 21 | 21 | 21 | 1 match / 0 differ / 6 no shared ids / 14 unavailable |
| sameas | 2 | 2 | 2 | 2 match / 0 differ |
| score | 16 | 16 | 16 | 2 match / 0 differ / 6 no shared ids / 8 unavailable |
| section | 4 | 4 | 4 | 2 match / 0 differ / 2 no shared ids |
| slur | 25 | 25 | 25 | 24 match / 0 differ / 1 no shared ids |
| space | 2 | 2 | 2 | 1 match / 0 differ / 1 no shared ids |
| stagedir | 1 | 1 | 1 | 1 match / 0 differ |
| stem | 16 | 14 | 16 | 1 match / 0 differ / 13 no shared ids |
| symbol | 2 | 2 | 2 | no shared ids |
| symboldef | 2 | 2 | 2 | 2 match / 0 differ |
| tab | 5 | 5 | 5 | 2 match / 0 differ / 3 no shared ids |
| tempo | 4 | 4 | 4 | 2 match / 0 differ / 2 no shared ids |
| tie | 12 | 12 | 12 | 12 match / 0 differ |
| trill | 8 | 8 | 8 | 4 match / 1 differ / 3 no shared ids |
| tuplet | 22 | 22 | 22 | 2 match / 0 differ / 20 no shared ids |
| turn | 6 | 6 | 6 | 6 match / 0 differ |
| unison | 7 | 7 | 7 | no shared ids |

## Per-file details

| File | Layout | Pages | Systems | Measures | X order | Measures once | Widths ≥ 0 | Timemap |
|---|---|---|---|---|---|---|---|---|
| accid/accid-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| accid/accid-002.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | no shared ids |
| accid/accid-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| accid/accid-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| accid/accid-005.mei | OK | 1 | 2 | 4 | PASS | PASS | PASS | no shared ids |
| accid/accid-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| accid/accid-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| accid/accid-008.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| accid/accid-009.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| accid/accid-010.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| accid/accid-011.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| accid/accid-012.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| accid/accid-013.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| accid/accid-014.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| annot/annot-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| annot/annot-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| annot/annot-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| annot/annot-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| annot/annot-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| annot/annot-006.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (2) |
| annot/annot-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (3) |
| app/app-001.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (7) |
| app/app-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| app/app-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| arpeg/arpeg-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | 1/2 differ@q=0.04 (note-0000001986960701) |
| arpeg/arpeg-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| arpeg/arpeg-003.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | no shared ids |
| arpeg/arpeg-004.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| arpeg/arpeg-005.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| arpeg/arpeg-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| arpeg/arpeg-007.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| artic/artic-001.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | no shared ids |
| artic/artic-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| artic/artic-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| artic/artic-004.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| artic/artic-005.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| artic/artic-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| artic/artic-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (8) |
| artic/artic-008.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| artic/artic-009.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| artic/artic-010.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| artic/artic-011.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (8) |
| artic/artic-012.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| artic/artic-013.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| artic/artic-014.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| artic/artic-015.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| artic/artic-016.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| artic/artic-017.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (4) |
| artic/artic-018.mei | OK | 1 | 2 | 6 | PASS | PASS | PASS | no shared ids |
| artic/artic-019.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| barline/barline-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | unavailable |
| barline/barline-002.mei | OK | 1 | 2 | 13 | PASS | PASS | PASS | unavailable |
| barline/barline-003.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (7) |
| barline/barline-004.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | unavailable |
| barline/barline-005.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| barline/barline-006.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| barline/barline-007.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (7) |
| barline/barline-008.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | unavailable |
| barline/barline-009.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | match (2) |
| barline/barline-010.mei | OK | 1 | 1 | 7 | PASS | PASS | PASS | no shared ids |
| beam/beam-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-008.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-009.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-010.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| beam/beam-011.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-012.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-013.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-014.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-015.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-016.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-017.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-018.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-019.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-020.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-021.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-022.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-023.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-025.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-026.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-031.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-032.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-033.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-034.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-035.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| beam/beam-036.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-037.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-038.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| beam/beam-039.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-040.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-041.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| beam/beam-042.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-043.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| beam/beam-044.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| beam/beam-045.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| beam/beam-046.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-047.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-048.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| beam/beam-049.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | 5/10 differ@q=0.05 (note-0000001704964791) |
| beam/beam-050.mei | OK | 1 | 2 | 2 | PASS | PASS | PASS | match (3) |
| beam/beam-051.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-052.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-053.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-054.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-055.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-056.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-057.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-058.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-059.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | no shared ids |
| beam/beam-060.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-061.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| beam/beam-062.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| beam/beam-063.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| beam/beam-064.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| beam/beam-065.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| beam/beam-066.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| beamspan/beamspan-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (9) |
| beamspan/beamspan-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (8) |
| beamspan/beamspan-003.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (6) |
| beamspan/beamspan-004.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (26) |
| beamspan/beamspan-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (16) |
| beamspan/beamspan-006.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| bracketspan/bracketspan-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (10) |
| breath/breath-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| breath/breath-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| btrem/btrem-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (4) |
| btrem/btrem-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| btrem/btrem-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| btrem/btrem-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| btrem/btrem-005.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| btrem/btrem-006.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (1) |
| caesura/caesura-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (1) |
| choice/choice-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| chord/chord-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| chord/chord-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| chord/chord-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| chord/chord-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| chord/chord-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| chord/chord-006.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| chord/chord-007.mei | OK | 1 | 2 | 5 | PASS | PASS | PASS | no shared ids |
| chord/chord-008.mei | OK | 1 | 2 | 2 | PASS | PASS | PASS | no shared ids |
| chord/chord-009.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| chord/chord-010.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| clef/clef-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| clef/clef-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | unavailable |
| clef/clef-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| clef/clef-004.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (24) |
| clef/clef-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| clef/clef-006.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| clef/clef-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| color/color-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (3) |
| color/color-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| color/color-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| color/color-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| cpmark/cpmark-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-004.mei | OK | 1 | 2 | 6 | PASS | PASS | PASS | match (4) |
| cross-staff/cross-staff-005.mei | OK | 1 | 1 | 7 | PASS | PASS | PASS | match (18) |
| cross-staff/cross-staff-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-007.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-008.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-009.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-010.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| cross-staff/cross-staff-011.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-012.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (4) |
| cross-staff/cross-staff-013.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| cross-staff/cross-staff-014.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| cross-staff/cross-staff-015.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | 1/7 differ@q=1.44 (note_24918) |
| cross-staff/cross-staff-016.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-017.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-018.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (12) |
| cross-staff/cross-staff-019.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | 2/14 differ@q=3.06 (note_4164a) |
| cross-staff/cross-staff-020.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (39) |
| cross-staff/cross-staff-021.mei | OK | 1 | 2 | 8 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-022.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| cross-staff/cross-staff-023.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| cross-staff/cross-staff-024.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| custos/custos-001.mei | OK | 1 | 2 | 8 | PASS | PASS | PASS | no shared ids |
| dir/dir-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| dir/dir-002.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| dir/dir-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| dir/dir-004.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| dir/dir-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| dir/dir-006.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| dir/dir-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| dir/dir-008.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| dir/dir-009.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| dir/dir-010.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| dot/dot-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| dot/dot-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| dot/dot-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| dot/dot-004.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| dot/dot-005.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| dot/dot-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| dynam/dynam-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| dynam/dynam-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| dynam/dynam-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (15) |
| dynam/dynam-004.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| dynam/dynam-005.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| dynam/dynam-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| dynam/dynam-007.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| dynam/dynam-008.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| dynam/dynam-009.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| dynam/dynam-010.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| editorial/editorial-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| editorial/editorial-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| ending/ending-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (7) |
| ending/ending-002.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | no shared ids |
| ending/ending-003.mei | OK | 1 | 2 | 12 | PASS | PASS | PASS | no shared ids |
| expansion/expansion-001.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | 1/2 differ@q=12.00 (n1687zus) |
| expansion/expansion-002.mei | OK | 1 | 2 | 11 | PASS | PASS | PASS | no shared ids |
| expansion/expansion-003.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | 1/2 differ@q=12.00 (n1687zus) |
| fermata/fermata-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (1) |
| fermata/fermata-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (1) |
| fermata/fermata-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | unavailable |
| fermata/fermata-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| fermata/fermata-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (1) |
| fermata/fermata-006.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (2) |
| fermata/fermata-007.mei | OK | 1 | 2 | 7 | PASS | PASS | PASS | no shared ids |
| figured-bass/figured-bass-001.mei | OK | 2 | 2 | 16 | PASS | PASS | PASS | match (6) |
| figured-bass/figured-bass-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| figured-bass/figured-bass-003.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| figured-bass/figured-bass-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| figured-bass/figured-bass-005.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| fing/fing-001.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | match (7) |
| fing/fing-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (27) |
| font/font-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| font/font-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| ftrem/ftrem-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| ftrem/ftrem-002.mei | **Null check operator used on a null value** | | | | | | | |
| gliss/gliss01.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (7) |
| gliss/gliss02.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (11) |
| gliss/gliss03.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (4) |
| gliss/gliss04.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (8) |
| gliss/gliss05.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (16) |
| gliss/gliss06.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (7) |
| gracenote/gracenote-001.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | 1/2 differ@q=1.00 (note-L5F1) |
| gracenote/gracenote-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-008.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-009.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | 1/6 differ@q=1.88 (note-L172F1) |
| gracenote/gracenote-010.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-011.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | 8/16 differ@q=0.25 (note-L14F2) |
| gracenote/gracenote-012.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-013.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-014.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-015.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-016.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | 3/7 differ@q=0.06 (note_13074) |
| gracenote/gracenote-017.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | 2/8 differ@q=1.38 (note_9390) |
| gracenote/gracenote-018.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-019.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-020.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-021.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-022.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| gracenote/gracenote-023.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| gracenote/gracenote-024.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | 14/16 differ@q=0.94 (note-L6F1) |
| gracenote/gracenote-025.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | 12/24 differ@q=0.50 (N2) |
| gracenote/gracenote-026.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | 12/24 differ@q=0.50 (N2) |
| gracenote/gracenote-027.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | 8/16 differ@q=0.06 (note_6576a) |
| hairpin/hairpin-001.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| hairpin/hairpin-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (12) |
| hairpin/hairpin-003.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| hairpin/hairpin-004.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| hairpin/hairpin-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (3) |
| hairpin/hairpin-006.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| harm/harm-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| harm/harm-002.mei | OK | 1 | 2 | 4 | PASS | PASS | PASS | match (6) |
| harm/harm-003.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | match (17) |
| harm/harm-004.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| harm/harm-005.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (2) |
| keysig/keysig-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | unavailable |
| keysig/keysig-002.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| keysig/keysig-003.mei | OK | 1 | 2 | 8 | PASS | PASS | PASS | unavailable |
| keysig/keysig-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | unavailable |
| keysig/keysig-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | unavailable |
| keysig/keysig-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| layer/layer-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (6) |
| layer/layer-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| layer/layer-003.mei | OK | 1 | 2 | 3 | PASS | PASS | PASS | no shared ids |
| layer/layer-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| layer/layer-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| layer/layer-006.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | 1/2 differ@q=5.00 (note-0000001245590624) |
| layer/layer-007.mei | OK | 1 | 1 | 12 | PASS | PASS | PASS | no shared ids |
| layer/layer-008.mei | OK | 1 | 1 | 14 | PASS | PASS | PASS | no shared ids |
| layer/layer-009.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| layer/layer-010.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| layer/layer-011.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| layer/layer-012.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (19) |
| layer/layer-013.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| layer/layer-014.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (4) |
| layer/layer-015.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| ligature/ligature-001.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| ligature/ligature-002.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| ligature/ligature-003.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| ligature/ligature-004.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| ligature/ligature-005.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| ligature/ligature-006.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| ligature/ligature-007.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| ligature/ligature-008.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| ligature/ligature-009.mei | OK | 1 | 1 | 8 | PASS | PASS | PASS | skipped |
| ligature/ligature-010.mei | OK | 1 | 1 | 8 | PASS | PASS | PASS | skipped |
| ligature/ligature-011.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-012.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-013.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-014.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-015.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-016.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-017.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-018.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-019.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-020.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-021.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-022.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-023.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-024.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-025.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-026.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-027.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-028.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-029.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-030.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-031.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-032.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-033.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-034.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-035.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-036.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-037.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-038.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-039.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-040.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-041.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-042.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-043.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-044.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | skipped |
| ligature/ligature-045.mei | OK | 1 | 2 | 6 | PASS | PASS | PASS | skipped |
| ligature/ligature-046.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | skipped |
| ligature/ligature-047.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | skipped |
| ligature/ligature-048.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | skipped |
| ligature/ligature-049.mei | OK | 1 | 2 | 12 | PASS | PASS | PASS | skipped |
| ligature/ligature-050.mei | OK | 1 | 2 | 12 | PASS | PASS | PASS | skipped |
| lyric/lyric-001.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (10) |
| lyric/lyric-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (7) |
| lyric/lyric-003.mei | OK | 1 | 2 | 7 | PASS | PASS | PASS | match (13) |
| lyric/lyric-004.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (21) |
| lyric/lyric-005.mei | OK | 1 | 2 | 12 | PASS | PASS | PASS | match (30) |
| lyric/lyric-006.mei | OK | 1 | 2 | 12 | PASS | PASS | PASS | match (30) |
| lyric/lyric-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| lyric/lyric-008.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | match (18) |
| lyric/lyric-009.mei | OK | 1 | 2 | 12 | PASS | PASS | PASS | 21/35 differ@q=32.00 (note-L27F1) |
| lyric/lyric-010.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (40) |
| lyric/lyric-011.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (13) |
| lyric/lyric-012.mei | OK | 1 | 3 | 18 | PASS | PASS | PASS | match (40) |
| lyric/lyric-013.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (3) |
| lyric/lyric-014.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | match (6) |
| lyric/lyric-015.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | match (12) |
| lyric/lyric-016.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (8) |
| mdiv/mdiv-001.mei | OK | 1 | 3 | 20 | PASS | PASS | PASS | unavailable |
| measure/measure-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| mensur/mensur-01.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| mensur/mensur-02.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| mensur/mensur-03.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| mensur/mensur-04.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| mensur/mensur-05.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| mensur/mensur-06.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| mensur/mensur-07.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| mensur/mensur-08.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| mensural/mensural-001.mei | OK | 4 | 10 | 18 | PASS | PASS | PASS | skipped |
| mensural/mensural-002.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | skipped |
| mensural/mensural-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-004.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| mensural/mensural-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-006.mei | OK | 1 | 1 | 7 | PASS | PASS | PASS | skipped |
| mensural/mensural-007.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | skipped |
| mensural/mensural-008.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-009.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| mensural/mensural-010.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | skipped |
| mensural/mensural-011.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | skipped |
| mensural/mensural-012.mei | OK | 1 | 2 | 7 | PASS | PASS | PASS | skipped |
| mensural/mensural-013.mei | OK | 1 | 1 | 8 | PASS | PASS | PASS | skipped |
| mensural/mensural-014.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-015.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-016.mei | OK | 1 | 2 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-017.mei | OK | 1 | 2 | 3 | PASS | PASS | PASS | skipped |
| mensural/mensural-018.mei | OK | 1 | 2 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-019.mei | OK | 1 | 2 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-020.mei | OK | 1 | 2 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-021.mei | OK | 1 | 2 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-022.mei | OK | 1 | 2 | 2 | PASS | PASS | PASS | skipped |
| mensural/mensural-023.mei | OK | 1 | 6 | 18 | PASS | PASS | PASS | skipped |
| mensural/mensural-024.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | skipped |
| mensural/mensural-025.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | skipped |
| metersig/metersig-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| metersig/metersig-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (12) |
| metersig/metersig-003.mei | OK | 1 | 3 | 8 | PASS | PASS | PASS | no shared ids |
| metersig/metersig-004.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| metersig/metersig-005.mei | OK | 1 | 3 | 8 | PASS | PASS | PASS | no shared ids |
| midi/003-keys-and-accidentals-advanced.mei | OK | 1 | 3 | 14 | PASS | PASS | PASS | no shared ids |
| midi/005-maqam-rast-external-tuning.mei | OK | 2 | 18 | 118 | PASS | PASS | PASS | match (27) |
| mnum/mnum-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| mordent/mordent-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| mordent/mordent-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (1) |
| mordent/mordent-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (1) |
| mordent/mordent-004.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (16) |
| mordent/mordent-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (7) |
| neume/neume-001.mei | OK | 1 | 3 | 10 | PASS | PASS | PASS | skipped |
| neume/neume-002.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | skipped |
| neume/neume-003.mei | OK | 1 | 1 | 7 | PASS | PASS | PASS | skipped |
| neume/neume-004.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | skipped |
| neume/neume-005.mei | OK | 1 | 2 | 71 | PASS | PASS | PASS | skipped |
| neume/neume-006.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | skipped |
| note/note-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| note/note-002.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| note/note-003.mei | OK | 1 | 1 | 8 | PASS | PASS | PASS | no shared ids |
| note/note-004.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (1) |
| note/note-005.mei | OK | 1 | 4 | 26 | PASS | PASS | PASS | match (4) |
| note/note-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| note/note-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| note/note-008.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| note/note-009.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| note/note-010.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| note/note-011.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| note/note-012.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| octave/octave-001.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (2) |
| octave/octave-002.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (3) |
| octave/octave-003.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (3) |
| octave/octave-004.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | match (6) |
| ornam/ornam-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (1) |
| ossia/ossia-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| ossia/ossia-002.mei | OK | 1 | 2 | 8 | PASS | PASS | PASS | no shared ids |
| ossia/ossia-003.mei | OK | 1 | 2 | 16 | PASS | PASS | PASS | unavailable |
| ossia/ossia-004.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (1) |
| pedal/pedal-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (9) |
| pedal/pedal-002.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| pedal/pedal-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| pedal/pedal-004.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| pedal/pedal-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| pedal/pedal-006.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| pgfoot/pghead-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| phrase/phrase-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (4) |
| reh/reh-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (1) |
| rend/rend-001.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| rend/rend-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| rend/rend-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| rend/rend-004.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (3) |
| repeatmark/repeatmark-001.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | unavailable |
| repeatmark/repeatmark-002.mei | OK | 1 | 1 | 8 | PASS | PASS | PASS | unavailable |
| repeats/rpt-001.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | no shared ids |
| repeats/rpt-002.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| repeats/rpt-003.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| repeats/rpt-004.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| repeats/rpt-005.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| repeats/rpt-006.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| repeats/rpt-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| repeats/rpt-008.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| rest/rest-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | unavailable |
| rest/rest-002.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | unavailable |
| rest/rest-003.mei | OK | 1 | 2 | 8 | PASS | PASS | PASS | unavailable |
| rest/rest-004.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| rest/rest-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| rest/rest-006.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| rest/rest-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | unavailable |
| rest/rest-008.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | unavailable |
| rest/rest-009.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | unavailable |
| rest/rest-010.mei | OK | 1 | 2 | 4 | PASS | PASS | PASS | no shared ids |
| rest/rest-011.mei | OK | 1 | 2 | 5 | PASS | PASS | PASS | no shared ids |
| rest/rest-012.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | unavailable |
| rest/rest-013.mei | OK | 1 | 1 | 9 | PASS | PASS | PASS | unavailable |
| rest/rest-014.mei | OK | 1 | 1 | 8 | PASS | PASS | PASS | unavailable |
| rest/rest-015.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | unavailable |
| rest/rest-016.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (4) |
| rest/rest-017.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| rest/rest-018.mei | OK | 2 | 9 | 61 | PASS | PASS | PASS | unavailable |
| rest/rest-019.mei | OK | 1 | 4 | 10 | PASS | PASS | PASS | unavailable |
| rest/rest-020.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | unavailable |
| rest/rest-021.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | unavailable |
| sameas/sameas-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (1) |
| sameas/sameas-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (1) |
| score/score-001.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | unavailable |
| score/score-002.mei | OK | 1 | 3 | 23 | PASS | PASS | PASS | unavailable |
| score/score-003.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | unavailable |
| score/score-004.mei | OK | 1 | 2 | 4 | PASS | PASS | PASS | no shared ids |
| score/score-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| score/score-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | unavailable |
| score/score-007.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | no shared ids |
| score/score-008.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | unavailable |
| score/score-009.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| score/score-010.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| score/score-011.mei | OK | 1 | 1 | 8 | PASS | PASS | PASS | unavailable |
| score/score-012.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| score/score-013.mei | OK | 7 | 19 | 204 | PASS | PASS | PASS | unavailable |
| score/score-014.mei | OK | 4 | 7 | 84 | PASS | PASS | PASS | unavailable |
| score/score-015.mei | OK | 1 | 3 | 16 | PASS | PASS | PASS | match (40) |
| score/score-016.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (16) |
| section/section-001.mei | OK | 1 | 5 | 20 | PASS | PASS | PASS | match (20) |
| section/section-002.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (4) |
| section/section-003.mei | OK | 1 | 3 | 24 | PASS | PASS | PASS | no shared ids |
| section/section-004.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| slur/slur-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| slur/slur-002.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (4) |
| slur/slur-003.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (4) |
| slur/slur-004.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (8) |
| slur/slur-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (6) |
| slur/slur-006.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (8) |
| slur/slur-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (16) |
| slur/slur-008.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (8) |
| slur/slur-009.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| slur/slur-010.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (4) |
| slur/slur-011.mei | OK | 1 | 2 | 6 | PASS | PASS | PASS | match (6) |
| slur/slur-012.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | match (12) |
| slur/slur-013.mei | OK | 1 | 2 | 12 | PASS | PASS | PASS | match (20) |
| slur/slur-014.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| slur/slur-015.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (18) |
| slur/slur-016.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| slur/slur-017.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (8) |
| slur/slur-018.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (8) |
| slur/slur-019.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | match (6) |
| slur/slur-020.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| slur/slur-021.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| slur/slur-022.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (6) |
| slur/slur-023.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (6) |
| slur/slur-024.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (3) |
| slur/slur-025.mei | OK | 1 | 2 | 18 | PASS | PASS | PASS | match (4) |
| space/space-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| space/space-002.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| stagedir/stagedir-001.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (4) |
| stem/stem-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| stem/stem-002.mei | OK | 1 | 2 | 4 | PASS | PASS | PASS | no shared ids |
| stem/stem-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| stem/stem-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| stem/stem-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| stem/stem-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| stem/stem-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| stem/stem-008.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| stem/stem-009.mei | OK | 1 | 1 | 5 | PASS | PASS | PASS | no shared ids |
| stem/stem-010.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| stem/stem-011.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| stem/stem-012.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| stem/stem-013.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| stem/stem-014.mei | **Unsupported operation: Cannot remove from an unmodifiable list** | | | | | | | |
| stem/stem-015.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| stem/stem-016.mei | **Unsupported operation: Cannot remove from an unmodifiable list** | | | | | | | |
| symbol/symbol-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| symbol/symbol-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| symboldef/symboldef-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (1) |
| symboldef/symboldef-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (6) |
| tab/tab-001.mei | OK | 1 | 1 | 7 | PASS | PASS | PASS | match (6) |
| tab/tab-002.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (6) |
| tab/tab-003.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| tab/tab-004.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| tab/tab-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tempo/tempo-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (4) |
| tempo/tempo-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (1) |
| tempo/tempo-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| tempo/tempo-004.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| tie/tie-001.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (14) |
| tie/tie-002.mei | OK | 1 | 2 | 6 | PASS | PASS | PASS | match (6) |
| tie/tie-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| tie/tie-004.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (24) |
| tie/tie-005.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (14) |
| tie/tie-006.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (14) |
| tie/tie-007.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (8) |
| tie/tie-008.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (8) |
| tie/tie-009.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (16) |
| tie/tie-010.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | match (7) |
| tie/tie-011.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (16) |
| tie/tie-012.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (8) |
| trill/trill-001.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| trill/trill-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | 1/2 differ@q=0.50 (note-L9F2) |
| trill/trill-003.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| trill/trill-004.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| trill/trill-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (4) |
| trill/trill-006.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (2) |
| trill/trill-007.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| trill/trill-008.mei | OK | 1 | 1 | 4 | PASS | PASS | PASS | match (4) |
| tuplet/tuplet-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (4) |
| tuplet/tuplet-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-005.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-008.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-009.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-010.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-011.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-012.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-013.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-014.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-015.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-016.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-017.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-018.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (10) |
| tuplet/tuplet-019.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-020.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-021.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-022.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |
| tuplet/tuplet-023.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| turn/turn-001.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| turn/turn-002.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (2) |
| turn/turn-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (5) |
| turn/turn-004.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | match (4) |
| turn/turn-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (6) |
| turn/turn-006.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | match (2) |
| unison/unison-001.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| unison/unison-002.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| unison/unison-003.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| unison/unison-004.mei | OK | 1 | 1 | 6 | PASS | PASS | PASS | no shared ids |
| unison/unison-005.mei | OK | 1 | 1 | 2 | PASS | PASS | PASS | no shared ids |
| unison/unison-006.mei | OK | 1 | 1 | 1 | PASS | PASS | PASS | no shared ids |
| unison/unison-007.mei | OK | 1 | 1 | 3 | PASS | PASS | PASS | no shared ids |

## Check notes
None. All structural assertions passed.

## Known limitations of the comparison

- SVG comparison is not possible yet (rendering is Phase 5); the C++ binary is only used for `-t timemap` onset times, which are independent of the visual layout.
- The C++ CLI cannot expose the mensural cast-off segment structure directly: segments are unmeasured measures which are not drawn as `measure` groups in SVG and are undone before MEI export. The structural counts quoted in the tests were derived from the C++ SVG staff-group counts (one staff group per segment per staff).
- Timemap comparisons use the first 40 shared note ids per file with a tolerance of 0.01 quarter units. Files where the two sides share no note id (ids generated independently) are reported as `no shared ids`, not as matches.
- Mensural / ligature / neume categories are skipped with reason (mensural, ligature, neume): the C++ CLI does not produce a comparable timemap for them.
