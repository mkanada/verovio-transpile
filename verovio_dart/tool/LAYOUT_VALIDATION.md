# Phase 4 layout validation

Headless pipeline: `MeiInput -> prepareData -> layOut` (breaks auto; encoded breaks honoured when the input provides layout information).

- Files validated: **46**
- C++ reference binary (`build/verovio`): available — timemap comparison runs on CMN files only.

## Summary per category

| Category | Files | Laid out | Sanity checks | Timemap vs C++ |
|---|---|---|---|---|
| ? | 46 | 46 | 46 | 24/30 clean |

## Per-file details

| File | Layout | Pages | Systems | Staves | Measures | Positioners (w/ bbox) | Slurs (positioned) | X order | Measures once | Widths ≥ 0 | Timemap |
|---|---|---|---|---|---|---|---|---|---|---|---|
| accid/accid-001.mei | OK | 1 | 3 | 6 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| artic/artic-001.mei | OK | 1 | 5 | 10 | 5 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| barline/barline-001.mei | OK | 1 | 3 | 6 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | unavailable |
| beam/beam-001.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| chord/chord-001.mei | OK | 1 | 1 | 5 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| clef/clef-001.mei | OK | 1 | 3 | 9 | 3 | 1 (1) | 0 (0) | PASS | PASS | PASS | match (0) |
| cross-staff/cross-staff-001.mei | OK | 1 | 2 | 6 | 2 | 3 (3) | 0 (0) | PASS | PASS | PASS | match (0) |
| cross-staff/cross-staff-013.mei | OK | 1 | 1 | 3 | 1 | 2 (2) | 1 (1) | PASS | PASS | PASS | match (2) |
| custos/custos-001.mei | OK | 1 | 8 | 16 | 8 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| dot/dot-001.mei | OK | 1 | 3 | 12 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| dynam/dynam-001.mei | OK | 1 | 3 | 6 | 3 | 10 (10) | 0 (0) | PASS | PASS | PASS | match (0) |
| editorial/editorial-001.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| gracenote/gracenote-001.mei | OK | 1 | 4 | 8 | 4 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| hairpin/hairpin-001.mei | OK | 1 | 6 | 12 | 6 | 1 (1) | 0 (0) | PASS | PASS | PASS | match (0) |
| keysig/keysig-001.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | unavailable |
| layer/layer-001.mei | OK | 1 | 1 | 3 | 1 | 3 (3) | 3 (3) | PASS | PASS | PASS | match (6) |
| ligature/ligature-001.mei | OK | 1 | 4 | 12 | 4 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| ligature/ligature-013.mei | OK | 1 | 1 | 3 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| ligature/ligature-026.mei | OK | 1 | 1 | 3 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| ligature/ligature-038.mei | OK | 1 | 1 | 3 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| lyric/lyric-001.mei | OK | 1 | 4 | 8 | 4 | 1 (1) | 1 (1) | PASS | PASS | PASS | 6/10 differ @q=4.50 |
| measure/measure-001.mei | OK | 1 | 2 | 4 | 2 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| mensural/mensural-001.mei | OK | 1 | 2 | 10 | 2 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-005.mei | OK | 1 | 2 | 4 | 2 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-009.mei | OK | 1 | 4 | 16 | 4 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-013.mei | OK | 2 | 8 | 32 | 8 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-017.mei | OK | 2 | 3 | 24 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| mensural/mensural-021.mei | OK | 1 | 2 | 10 | 2 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| metersig/metersig-001.mei | OK | 1 | 3 | 6 | 3 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| neume/neume-001.mei | OK | 1 | 1 | 2 | 10 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-002.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-003.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-004.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-005.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| neume/neume-006.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | skipped |
| note/note-001.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| note/note-007.mei | OK | 1 | 1 | 2 | 1 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| ossia/ossia-001.mei | OK | 1 | 3 | 6 | 3 | 2 (2) | 2 (2) | PASS | PASS | PASS | match (0) |
| ossia/ossia-003.mei | OK | 6 | 16 | 80 | 16 | 0 (0) | 0 (0) | PASS | PASS | PASS | unavailable |
| repeats/rpt-001.mei | OK | 1 | 5 | 15 | 5 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (0) |
| rest/rest-001.mei | OK | 1 | 1 | 2 | 2 | 0 (0) | 0 (0) | PASS | PASS | PASS | unavailable |
| section/section-001.mei | OK | 4 | 20 | 60 | 20 | 16 (16) | 6 (6) | PASS | PASS | PASS | 10/20 differ @q=25.00 |
| slur/slur-001.mei | OK | 1 | 1 | 3 | 1 | 1 (1) | 1 (1) | PASS | PASS | PASS | match (2) |
| slur/slur-013.mei | OK | 2 | 12 | 24 | 12 | 18 (18) | 12 (12) | PASS | PASS | PASS | match (20) |
| tie/tie-001.mei | OK | 1 | 4 | 12 | 4 | 0 (0) | 0 (0) | PASS | PASS | PASS | match (14) |
| tuplet/tuplet-001.mei | OK | 1 | 2 | 6 | 2 | 2 (2) | 2 (2) | PASS | PASS | PASS | match (4) |

## System metrics (first system per file)

| File | Systems | First system: measures / width / staves / yRel range |
|---|---|---|
| accid/accid-001.mei | 3 | 1 m / w=2778 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| artic/artic-001.mei | 5 | 1 m / w=2778 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| barline/barline-001.mei | 3 | 1 m / w=1349 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| beam/beam-001.mei | 1 | 1 m / w=1721 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| chord/chord-001.mei | 1 | 1 m / w=7058 / 5 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| clef/clef-001.mei | 3 | 1 m / w=1160 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| cross-staff/cross-staff-001.mei | 2 | 1 m / w=4811 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| cross-staff/cross-staff-013.mei | 1 | 1 m / w=1811 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| custos/custos-001.mei | 8 | 1 m / w=1599 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| dot/dot-001.mei | 3 | 1 m / w=2053 / 4 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| dynam/dynam-001.mei | 3 | 1 m / w=2778 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| editorial/editorial-001.mei | 1 | 1 m / w=2859 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| gracenote/gracenote-001.mei | 4 | 1 m / w=2448 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| hairpin/hairpin-001.mei | 6 | 1 m / w=2118 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| keysig/keysig-001.mei | 1 | 1 m / w=135 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| layer/layer-001.mei | 1 | 1 m / w=2510 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ligature/ligature-001.mei | 4 | 1 m / w=2422 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ligature/ligature-013.mei | 1 | 1 m / w=1252 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ligature/ligature-026.mei | 1 | 1 m / w=4682 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ligature/ligature-038.mei | 1 | 1 m / w=1252 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| lyric/lyric-001.mei | 4 | 1 m / w=708 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| measure/measure-001.mei | 2 | 1 m / w=1599 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-001.mei | 2 | 1 m / w=6794 / 5 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-005.mei | 2 | 1 m / w=1250 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-009.mei | 4 | 1 m / w=3752 / 4 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-013.mei | 8 | 1 m / w=3754 / 4 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-017.mei | 3 | 1 m / w=3754 / 8 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| mensural/mensural-021.mei | 2 | 1 m / w=7262 / 5 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| metersig/metersig-001.mei | 3 | 1 m / w=1359 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-001.mei | 1 | 10 m / w=0 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-002.mei | 1 | 1 m / w=0 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-003.mei | 1 | 1 m / w=0 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-004.mei | 1 | 1 m / w=0 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-005.mei | 1 | 1 m / w=0 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| neume/neume-006.mei | 1 | 1 m / w=0 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| note/note-001.mei | 1 | 1 m / w=699 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| note/note-007.mei | 1 | 1 m / w=2298 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ossia/ossia-001.mei | 3 | 1 m / w=3609 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| ossia/ossia-003.mei | 16 | 1 m / w=1601 / 5 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| repeats/rpt-001.mei | 5 | 1 m / w=2870 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| rest/rest-001.mei | 1 | 2 m / w=270 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| section/section-001.mei | 20 | 1 m / w=710 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| slur/slur-001.mei | 1 | 1 m / w=1760 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| slur/slur-013.mei | 12 | 1 m / w=2118 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| tie/tie-001.mei | 4 | 1 m / w=3620 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
| tuplet/tuplet-001.mei | 2 | 1 m / w=4681 / 3 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |

## Check notes
None. All structural assertions passed.

## Known limitations of the comparison

- SVG comparison is not possible yet (rendering is Phase 5); the C++ binary is only used for `-t timemap` onset times, which are independent of the visual layout.
- The C++ CLI cannot expose the mensural cast-off segment structure directly: segments are unmeasured measures which are not drawn as `measure` groups in SVG and are undone before MEI export. The structural counts quoted in the tests were derived from the C++ SVG staff-group counts (one staff group per segment per staff).
- Timemap comparisons use the first 40 shared note ids per file with a tolerance of 0.01 quarter units.
