# SVG_VALIDATION — comparação de SVG (harness da Fase 5)

Estrutural: 508/621 limpos
Numérico (eps=0.0): 76/621 limpos

Gerado em 2026-08-31 por `dart run tool/compare_svg.dart` (modo: both, epsilon: 0.0).

- Divergentes: 545
- Falhas (exceção durante renderização): 0
- Sem renderização Dart disponível (stub `renderSvgForComparison` da Fase 5): 0

## Por categoria (75 categorias)

| Categoria | Estrutural limpos | Numérico limpos | Divergentes | Falhas | Sem render | Total |
|---|---|---|---|---|---|---|
| accid | 12 | 2 | 12 | 0 | 0 | 14 |
| annot | 7 | 4 | 3 | 0 | 0 | 7 |
| app | 1 | 1 | 2 | 0 | 0 | 3 |
| arpeg | 4 | 0 | 7 | 0 | 0 | 7 |
| artic | 14 | 0 | 19 | 0 | 0 | 19 |
| barline | 7 | 4 | 6 | 0 | 0 | 10 |
| beam | 58 | 0 | 61 | 0 | 0 | 61 |
| beamspan | 4 | 0 | 6 | 0 | 0 | 6 |
| bracketspan | 0 | 0 | 1 | 0 | 0 | 1 |
| breath | 2 | 1 | 1 | 0 | 0 | 2 |
| btrem | 5 | 0 | 6 | 0 | 0 | 6 |
| caesura | 1 | 0 | 1 | 0 | 0 | 1 |
| choice | 1 | 0 | 1 | 0 | 0 | 1 |
| chord | 7 | 0 | 10 | 0 | 0 | 10 |
| clef | 3 | 2 | 5 | 0 | 0 | 7 |
| color | 4 | 1 | 3 | 0 | 0 | 4 |
| cpmark | 1 | 0 | 1 | 0 | 0 | 1 |
| cross-staff | 18 | 0 | 24 | 0 | 0 | 24 |
| custos | 0 | 0 | 1 | 0 | 0 | 1 |
| dir | 9 | 3 | 7 | 0 | 0 | 10 |
| dot | 3 | 0 | 6 | 0 | 0 | 6 |
| dynam | 9 | 0 | 10 | 0 | 0 | 10 |
| editorial | 2 | 0 | 2 | 0 | 0 | 2 |
| ending | 2 | 0 | 3 | 0 | 0 | 3 |
| expansion | 3 | 0 | 3 | 0 | 0 | 3 |
| fermata | 5 | 1 | 6 | 0 | 0 | 7 |
| figured-bass | 5 | 2 | 3 | 0 | 0 | 5 |
| fing | 2 | 0 | 2 | 0 | 0 | 2 |
| font | 1 | 0 | 2 | 0 | 0 | 2 |
| ftrem | 2 | 0 | 2 | 0 | 0 | 2 |
| gliss | 6 | 0 | 6 | 0 | 0 | 6 |
| gracenote | 26 | 1 | 26 | 0 | 0 | 27 |
| hairpin | 6 | 1 | 5 | 0 | 0 | 6 |
| harm | 5 | 0 | 5 | 0 | 0 | 5 |
| keysig | 4 | 2 | 4 | 0 | 0 | 6 |
| layer | 12 | 2 | 13 | 0 | 0 | 15 |
| ligature | 49 | 0 | 50 | 0 | 0 | 50 |
| lyric | 14 | 2 | 14 | 0 | 0 | 16 |
| mdiv | 0 | 0 | 1 | 0 | 0 | 1 |
| measure | 1 | 1 | 0 | 0 | 0 | 1 |
| mensur | 8 | 2 | 6 | 0 | 0 | 8 |
| mensural | 5 | 2 | 23 | 0 | 0 | 25 |
| metersig | 4 | 0 | 5 | 0 | 0 | 5 |
| midi | 0 | 0 | 2 | 0 | 0 | 2 |
| mnum | 0 | 0 | 1 | 0 | 0 | 1 |
| mordent | 5 | 1 | 4 | 0 | 0 | 5 |
| neume | 5 | 0 | 6 | 0 | 0 | 6 |
| note | 9 | 1 | 11 | 0 | 0 | 12 |
| octave | 4 | 0 | 4 | 0 | 0 | 4 |
| ornam | 1 | 1 | 0 | 0 | 0 | 1 |
| ossia | 1 | 0 | 4 | 0 | 0 | 4 |
| pedal | 6 | 4 | 2 | 0 | 0 | 6 |
| pgfoot | 1 | 0 | 1 | 0 | 0 | 1 |
| phrase | 1 | 0 | 1 | 0 | 0 | 1 |
| reh | 1 | 1 | 0 | 0 | 0 | 1 |
| rend | 2 | 1 | 3 | 0 | 0 | 4 |
| repeatmark | 2 | 2 | 0 | 0 | 0 | 2 |
| repeats | 8 | 0 | 8 | 0 | 0 | 8 |
| rest | 19 | 9 | 12 | 0 | 0 | 21 |
| sameas | 0 | 0 | 2 | 0 | 0 | 2 |
| score | 10 | 6 | 10 | 0 | 0 | 16 |
| section | 3 | 0 | 4 | 0 | 0 | 4 |
| slur | 23 | 0 | 25 | 0 | 0 | 25 |
| space | 2 | 1 | 1 | 0 | 0 | 2 |
| stagedir | 1 | 0 | 1 | 0 | 0 | 1 |
| stem | 12 | 3 | 13 | 0 | 0 | 16 |
| symbol | 2 | 1 | 1 | 0 | 0 | 2 |
| symboldef | 2 | 1 | 1 | 0 | 0 | 2 |
| tab | 1 | 0 | 5 | 0 | 0 | 5 |
| tempo | 4 | 0 | 4 | 0 | 0 | 4 |
| tie | 10 | 0 | 12 | 0 | 0 | 12 |
| trill | 7 | 4 | 4 | 0 | 0 | 8 |
| tuplet | 22 | 3 | 19 | 0 | 0 | 22 |
| turn | 6 | 3 | 3 | 0 | 0 | 6 |
| unison | 6 | 0 | 7 | 0 | 0 | 7 |

## Top divergências estruturais (113 arquivo(s) com divergências; até 30 listados)

| Arquivo | Divergências | Primeira divergência |
|---|---|---|
| lyric/lyric-012.mei | 575 | svg/svg[0]/g[0]/g[3]/g[1]/g[1]/g[2]/g[0]: esperado [5 filhos], obtido [7 filhos] |
| midi/005-maqam-rast-external-tuning.mei | 544 | svg/svg[0]/g[0]: esperado [15 filhos], obtido [14 filhos] |
| score/score-015.mei | 535 | svg/svg[0]/g[0]/g[2]: esperado [14 filhos], obtido [13 filhos] |
| score/score-013.mei | 378 | svg/svg[0]/g[0]/g[2]: esperado [17 filhos], obtido [16 filhos] |
| rest/rest-018.mei | 314 | svg/svg[0]/g[0]/g[3]: esperado [16 filhos], obtido [15 filhos] |
| score/score-011.mei | 221 | svg/svg[0]/g[0]/g[2]/g[19]: esperado [14 filhos], obtido [15 filhos] |
| layer/layer-008.mei | 198 | svg/svg[0]/g[0]/g[2]: esperado [17 filhos], obtido [16 filhos] |
| ossia/ossia-002.mei | 171 | svg/svg[0]/g[0]/g[2]/g[3]/g[0]/g[2]: esperado [3 filhos], obtido [1 filhos] |
| tie/tie-001.mei | 109 | svg/svg[0]/g[0]/g[2]/g[2]: esperado [3 filhos], obtido [5 filhos] |
| gracenote/gracenote-011.mei | 73 | svg/svg[0]/g[0]/g[2]/g[2]/g[1]/g[5]/g[1]/g[1]/g[1]: esperado [1 filhos], obtido [2 filhos] |
| ending/ending-003.mei | 69 | svg/svg[0]/g[0]/g[2]/g[5]/g[2]: esperado [0 filhos], obtido [7 filhos] |
| tab/tab-005.mei | 66 | svg/svg[0]/g[0]/g[2]/g[6]/g[1]/g[2]/g[0]: esperado [11 filhos], obtido [8 filhos] |
| neume/neume-001.mei | 61 | svg/svg[0]/g[0]: esperado [11 filhos], obtido [16 filhos] |
| fermata/fermata-006.mei | 52 | svg/defs[0]/g[3]: esperado [id="E0A2-@doc"], obtido [id="E4C0-@doc"] |
| cross-staff/cross-staff-015.mei | 49 | svg/defs[0]: esperado [defs 8 glifos], obtido [defs 9 glifos (faltam E242-@doc)] |
| midi/003-keys-and-accidentals-advanced.mei | 49 | svg/svg[0]/g[0]/g[3]: esperado [10 filhos], obtido [9 filhos] |
| tie/tie-005.mei | 47 | svg/svg[0]/g[0]/g[2]/g[1]: esperado [2 filhos], obtido [5 filhos] |
| beam/beam-059.mei | 44 | svg/svg[0]/g[0]/g[2]/g[1]: esperado [2 filhos], obtido [3 filhos] |
| score/score-007.mei | 42 | svg/svg[0]/g[0]/g[2]/g[2]: esperado [3 filhos], obtido [4 filhos] |
| arpeg/arpeg-004.mei | 36 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]: esperado [10 filhos], obtido [11 filhos] |
| note/note-008.mei | 34 | svg/defs[0]: esperado [defs 18 glifos], obtido [defs 26 glifos (faltam E0A9-@doc,E0AF-@doc,E0B3-@doc,E0B5-@doc)] |
| tab/tab-004.mei | 32 | svg/defs[0]: esperado [defs 2 glifos], obtido [defs 5 glifos (faltam E240-@doc,E241-@doc,E243-@doc)] |
| barline/barline-006.mei | 26 | svg/svg[0]/g[0]/g[2]/g[2]/g[3]: esperado [0 filhos], obtido [17 filhos] |
| fermata/fermata-001.mei | 24 | svg/defs[0]: esperado [defs 6 glifos], obtido [defs 8 glifos (faltam E4C0-@doc,E4C1-@doc)] |
| dir/dir-008.mei | 20 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]: esperado [1 filhos], obtido [2 filhos] |
| rend/rend-002.mei | 20 | svg/svg[0]/g[0]/g[2]/g[2]/g[1]: esperado [1 filhos], obtido [2 filhos] |
| tab/tab-002.mei | 20 | svg/defs[0]: esperado [defs 18 glifos], obtido [defs 19 glifos (faltam EBAA-@doc)] |
| chord/chord-007.mei | 18 | svg/defs[0]: esperado [defs 3 glifos], obtido [defs 2 glifos (extras E050-@doc)] |
| cross-staff/cross-staff-001.mei | 18 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[3]: esperado [7 filhos], obtido [5 filhos] |
| custos/custos-001.mei | 16 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]: esperado [7 filhos], obtido [6 filhos] |

## Maiores desvios numéricos (até 10 listados)

| Arquivo | Maior desvio | Divergências numéricas | Primeira divergência |
|---|---|---|---|
| neume/neume-001.mei | 26879.0 | 73 | svg: esperado [width[0]=2100.0], obtido [width[0]=7758.0] |
| ossia/ossia-003.mei | 13732.0 | 739 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=10155.0], obtido [d[3]=10268.0] |
| tab/tab-005.mei | 13000.0 | 201 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[0]=5549.0], obtido [d[0]=3339.0] |
| chord/chord-008.mei | 9253.0 | 166 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[2]/g[0]/polygon[0]: esperado [points[0]=999.0], obtido [points[0]=837.0] |
| accid/accid-005.mei | 8144.0 | 72 | svg/svg[0]/g[0]: esperado [7 filhos], obtido [8 filhos] |
| mensural/mensural-020.mei | 7803.0 | 96 | svg/svg[0]/g[0]/g[2]/g[6]/g[2]/g[0]/use[0]: esperado [transform[0]=1371.0], obtido [transform[0]=1262.0] |
| mensural/mensural-019.mei | 7597.0 | 93 | svg/svg[0]/g[0]/g[2]/g[6]/g[2]/g[0]/use[0]: esperado [transform[0]=1371.0], obtido [transform[0]=1262.0] |
| accid/accid-013.mei | 6887.0 | 169 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[1]=4502.0], obtido [d[1]=1458.0] |
| arpeg/arpeg-004.mei | 6573.0 | 104 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]: esperado [10 filhos], obtido [11 filhos] |
| mensural/mensural-016.mei | 6405.0 | 168 | svg/svg[0]/g[0]/g[2]/g[9]/g[2]/g[0]/use[0]: esperado [transform[0]=2839.0], obtido [transform[0]=2573.0] |

