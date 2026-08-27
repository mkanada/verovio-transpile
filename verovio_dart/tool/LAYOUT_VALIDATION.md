# Phase 4 layout validation

Headless pipeline: `MeiInput -> prepareData -> layOut` (breaks auto; encoded breaks honoured when the input provides layout information).

- Files validated: **46**
- C++ reference binary (`build/verovio`): available — timemap comparison runs on CMN files only.

## Base numérica 04-00 vs C++ (epsilon 0)

- Arquivos com unidades batendo: **4/4** (40 valores)
- Arquivos com todos os alinhamentos batendo: **4/4** (78 valores de type/time/xRel)

## Summary per category

| Category | Files | Laid out | Sanity checks | Timemap vs C++ |
|---|---|---|---|---|
| ? | 46 | 46 | 46 | 26/30 clean |

## Per-file details

| File | Layout | Pages | Systems | Staves | Measures | Positioners (w/ bbox) | Slurs (positioned) | X order | Measures once | Widths ≥ 0 | Timemap |
|---|---|---|---|---|---|---|---|---|---|---|---|
| accid/accid-001.mei | OK | 1 | 1 | 2 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| artic/artic-001.mei | OK | 1 | 1 | 2 | 5 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| barline/barline-001.mei | OK | 1 | 1 | 2 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | unavailable |
| beam/beam-001.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| chord/chord-001.mei | OK | 1 | 1 | 5 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| clef/clef-001.mei | OK | 1 | 1 | 3 | 3 | 1 (1) | 0 (0) | PASS | PASS | PASS | match (0) |
| cross-staff/cross-staff-001.mei | OK | 1 | 1 | 3 | 2 | 3 (3) | 0 (0) | PASS | PASS | PASS | match (0) |
| cross-staff/cross-staff-013.mei | OK | 1 | 1 | 3 | 1 | 2 (2) | 1 (1) | PASS | PASS | PASS | match (2) |
| custos/custos-001.mei | OK | 1 | 1 | 2 | 8 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| dot/dot-001.mei | OK | 1 | 1 | 4 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| dynam/dynam-001.mei | OK | 1 | 1 | 2 | 3 | 10 (10) | 0 (0) | PASS | PASS | PASS | match (0) |
| editorial/editorial-001.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| gracenote/gracenote-001.mei | OK | 1 | 1 | 2 | 4 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| hairpin/hairpin-001.mei | OK | 1 | 1 | 2 | 6 | 1 (1) | 0 (0) | PASS | PASS | PASS | match (0) |
| keysig/keysig-001.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | unavailable |
| layer/layer-001.mei | OK | 1 | 1 | 3 | 1 | 3 (3) | 3 (3) | PASS | PASS | PASS | match (6) |
| ligature/ligature-001.mei | OK | 1 | 1 | 3 | 4 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| ligature/ligature-013.mei | OK | 1 | 1 | 3 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| ligature/ligature-026.mei | OK | 1 | 1 | 3 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| ligature/ligature-038.mei | OK | 1 | 1 | 3 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| lyric/lyric-001.mei | OK | 1 | 1 | 2 | 4 | 1 (1) | 1 (1) | PASS | PASS | PASS | match (10) |
| measure/measure-001.mei | OK | 1 | 1 | 2 | 2 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| mensural/mensural-001.mei | OK | 3 | 8 | 40 | 18 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-005.mei | OK | 1 | 1 | 2 | 2 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-009.mei | OK | 1 | 1 | 4 | 4 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-013.mei | OK | 1 | 1 | 4 | 8 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-017.mei | OK | 1 | 1 | 8 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-021.mei | OK | 1 | 2 | 10 | 2 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| metersig/metersig-001.mei | OK | 1 | 1 | 2 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| neume/neume-001.mei | OK | 1 | 3 | 6 | 10 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-002.mei | OK | 1 | 1 | 2 | 5 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-003.mei | OK | 1 | 1 | 2 | 7 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-004.mei | OK | 1 | 1 | 2 | 5 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-005.mei | OK | 1 | 2 | 4 | 71 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-006.mei | OK | 1 | 1 | 2 | 5 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| note/note-001.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| note/note-007.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| ossia/ossia-001.mei | OK | 1 | 1 | 2 | 3 | 2 (2) | 2 (2) | PASS | PASS | PASS | match (0) |
| ossia/ossia-003.mei | OK | 1 | 2 | 10 | 16 | 0 (0) | 0 (0) | PASS | PASS | PASS | unavailable |
| repeats/rpt-001.mei | OK | 1 | 1 | 3 | 5 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| rest/rest-001.mei | OK | 1 | 1 | 2 | 2 | 0 (0) | 0 (0) | PASS | PASS | PASS | unavailable |
| section/section-001.mei | OK | 1 | 3 | 9 | 20 | 16 (16) | 6 (6) | PASS | PASS | PASS | match (20) |
| slur/slur-001.mei | OK | 1 | 1 | 3 | 1 | 1 (1) | 1 (1) | PASS | PASS | PASS | match (2) |
| slur/slur-013.mei | OK | 1 | 2 | 4 | 12 | 18 (18) | 12 (12) | PASS | PASS | PASS | match (20) |
| tie/tie-001.mei | OK | 1 | 1 | 3 | 4 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (14) |
| tuplet/tuplet-001.mei | OK | 1 | 1 | 3 | 2 | 2 (2) | 2 (2) | PASS | PASS | PASS | match (4) |

## System metrics (first system per file)

| File | Systems | First system: measures / width / staves / yRel range |
|---|---|---|
| accid/accid-001.mei | 1 | 3 m / w=8847 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| artic/artic-001.mei | 1 | 5 m / w=13365 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| barline/barline-001.mei | 1 | 3 m / w=4290 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| beam/beam-001.mei | 1 | 1 m / w=1822 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| chord/chord-001.mei | 1 | 1 m / w=7229 / 5 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| clef/clef-001.mei | 1 | 3 m / w=6384 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| cross-staff/cross-staff-001.mei | 1 | 2 m / w=7536 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| cross-staff/cross-staff-013.mei | 1 | 1 m / w=1917 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| custos/custos-001.mei | 1 | 8 m / w=13440 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| dot/dot-001.mei | 1 | 3 m / w=8960 / 4 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| dynam/dynam-001.mei | 1 | 3 m / w=8187 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| editorial/editorial-001.mei | 1 | 1 m / w=2940 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| gracenote/gracenote-001.mei | 1 | 4 m / w=10806 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| hairpin/hairpin-001.mei | 1 | 6 m / w=13734 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| keysig/keysig-001.mei | 1 | 1 m / w=1350 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| layer/layer-001.mei | 1 | 1 m / w=2706 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ligature/ligature-001.mei | 1 | 4 m / w=9707 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ligature/ligature-013.mei | 1 | 1 m / w=1277 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ligature/ligature-026.mei | 1 | 1 m / w=4707 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ligature/ligature-038.mei | 1 | 1 m / w=1277 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| lyric/lyric-001.mei | 1 | 4 m / w=7866 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| measure/measure-001.mei | 1 | 2 m / w=3360 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-001.mei | 8 | 3 m / w=17791 / 5 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-005.mei | 1 | 2 m / w=2500 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-009.mei | 1 | 4 m / w=13199 / 4 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-013.mei | 1 | 8 m / w=15049 / 4 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-017.mei | 1 | 3 m / w=19681 / 8 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-021.mei | 2 | 1 m / w=7287 / 5 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| metersig/metersig-001.mei | 1 | 3 m / w=4320 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-001.mei | 3 | 4 m / w=16350 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-002.mei | 1 | 5 m / w=3450 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-003.mei | 1 | 7 m / w=3150 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-004.mei | 1 | 5 m / w=3450 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-005.mei | 2 | 41 m / w=19950 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-006.mei | 1 | 5 m / w=2550 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| note/note-001.mei | 1 | 1 m / w=2160 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| note/note-007.mei | 1 | 1 m / w=3159 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ossia/ossia-001.mei | 1 | 3 m / w=10179 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ossia/ossia-003.mei | 2 | 13 m / w=19767 / 5 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| repeats/rpt-001.mei | 1 | 5 m / w=10746 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| rest/rest-001.mei | 1 | 2 m / w=18852 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| section/section-001.mei | 3 | 8 m / w=20609 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| slur/slur-001.mei | 1 | 1 m / w=1956 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| slur/slur-013.mei | 2 | 9 m / w=20601 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| tie/tie-001.mei | 1 | 4 m / w=14763 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| tuplet/tuplet-001.mei | 1 | 2 m / w=8076 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |

## Check notes
None. All structural assertions passed.

## Known limitations of the comparison

- SVG comparison is not possible yet (rendering is Phase 5); the C++ binary is only used for `-t timemap` onset times, which are independent of the visual layout.
- The C++ CLI cannot expose the mensural cast-off segment structure directly: segments are unmeasured measures which are not drawn as `measure` groups in SVG and are undone before MEI export. The structural counts quoted in the tests were derived from the C++ SVG staff-group counts (one staff group per segment per staff).
- Timemap comparisons use the first 40 shared note ids per file with a tolerance of 0.01 quarter units.
