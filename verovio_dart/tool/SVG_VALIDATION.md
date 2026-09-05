# SVG_VALIDATION — comparação de SVG (harness da Fase 5)

Estrutural: 613/621 limpos
Numérico (eps=0.0): 170/621 limpos
Divergências estruturais (total): 43
Divergências numéricas (total): 32318

Gerado em 2026-09-05 por `dart run tool/compare_svg.dart` (modo: both, epsilon: 0.0).

- Divergentes: 451
- Falhas (exceção durante renderização): 0
- Sem renderização Dart disponível (stub `renderSvgForComparison` da Fase 5): 0

## Por categoria (75 categorias)

| Categoria | Estrutural limpos | Numérico limpos | Div. est. (total) | Div. num. (total) | Divergentes | Falhas | Sem render | Total |
|---|---|---|---|---|---|---|---|---|
| accid | 14 | 2 | 0 | 353 | 12 | 0 | 0 | 14 |
| annot | 7 | 4 | 0 | 8 | 3 | 0 | 0 | 7 |
| app | 3 | 2 | 0 | 16 | 1 | 0 | 0 | 3 |
| arpeg | 6 | 0 | 1 | 719 | 7 | 0 | 0 | 7 |
| artic | 19 | 0 | 0 | 1733 | 19 | 0 | 0 | 19 |
| barline | 9 | 6 | 4 | 449 | 4 | 0 | 0 | 10 |
| beam | 61 | 0 | 0 | 3223 | 61 | 0 | 0 | 61 |
| beamspan | 6 | 0 | 0 | 447 | 6 | 0 | 0 | 6 |
| bracketspan | 1 | 0 | 0 | 15 | 1 | 0 | 0 | 1 |
| breath | 2 | 1 | 0 | 1 | 1 | 0 | 0 | 2 |
| btrem | 6 | 1 | 0 | 194 | 5 | 0 | 0 | 6 |
| caesura | 1 | 0 | 0 | 38 | 1 | 0 | 0 | 1 |
| choice | 1 | 0 | 0 | 34 | 1 | 0 | 0 | 1 |
| chord | 10 | 0 | 0 | 1442 | 10 | 0 | 0 | 10 |
| clef | 7 | 2 | 0 | 373 | 5 | 0 | 0 | 7 |
| color | 4 | 1 | 0 | 23 | 3 | 0 | 0 | 4 |
| cpmark | 1 | 0 | 0 | 99 | 1 | 0 | 0 | 1 |
| cross-staff | 21 | 1 | 9 | 2281 | 23 | 0 | 0 | 24 |
| custos | 1 | 0 | 0 | 70 | 1 | 0 | 0 | 1 |
| dir | 10 | 4 | 0 | 360 | 6 | 0 | 0 | 10 |
| dot | 6 | 0 | 0 | 442 | 6 | 0 | 0 | 6 |
| dynam | 10 | 0 | 0 | 208 | 10 | 0 | 0 | 10 |
| editorial | 2 | 0 | 0 | 6 | 2 | 0 | 0 | 2 |
| ending | 3 | 1 | 0 | 233 | 2 | 0 | 0 | 3 |
| expansion | 3 | 0 | 0 | 153 | 3 | 0 | 0 | 3 |
| fermata | 7 | 2 | 0 | 268 | 5 | 0 | 0 | 7 |
| figured-bass | 5 | 2 | 0 | 109 | 3 | 0 | 0 | 5 |
| fing | 2 | 0 | 0 | 259 | 2 | 0 | 0 | 2 |
| font | 2 | 0 | 0 | 200 | 2 | 0 | 0 | 2 |
| ftrem | 2 | 0 | 0 | 64 | 2 | 0 | 0 | 2 |
| gliss | 6 | 0 | 0 | 69 | 6 | 0 | 0 | 6 |
| gracenote | 27 | 1 | 0 | 1130 | 26 | 0 | 0 | 27 |
| hairpin | 6 | 1 | 0 | 64 | 5 | 0 | 0 | 6 |
| harm | 5 | 2 | 0 | 379 | 3 | 0 | 0 | 5 |
| keysig | 6 | 5 | 0 | 41 | 1 | 0 | 0 | 6 |
| layer | 14 | 4 | 1 | 797 | 11 | 0 | 0 | 15 |
| ligature | 50 | 30 | 0 | 286 | 20 | 0 | 0 | 50 |
| lyric | 16 | 4 | 0 | 2698 | 12 | 0 | 0 | 16 |
| mdiv | 1 | 0 | 0 | 121 | 1 | 0 | 0 | 1 |
| measure | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| mensur | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 8 |
| mensural | 25 | 21 | 0 | 78 | 4 | 0 | 0 | 25 |
| metersig | 5 | 0 | 0 | 348 | 5 | 0 | 0 | 5 |
| midi | 1 | 1 | 14 | 778 | 1 | 0 | 0 | 2 |
| mnum | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| mordent | 5 | 1 | 0 | 110 | 4 | 0 | 0 | 5 |
| neume | 6 | 0 | 0 | 1031 | 6 | 0 | 0 | 6 |
| note | 12 | 5 | 0 | 497 | 7 | 0 | 0 | 12 |
| octave | 4 | 0 | 0 | 189 | 4 | 0 | 0 | 4 |
| ornam | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| ossia | 4 | 0 | 0 | 1044 | 4 | 0 | 0 | 4 |
| pedal | 6 | 4 | 0 | 172 | 2 | 0 | 0 | 6 |
| pgfoot | 1 | 0 | 0 | 14 | 1 | 0 | 0 | 1 |
| phrase | 1 | 0 | 0 | 58 | 1 | 0 | 0 | 1 |
| reh | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| rend | 4 | 2 | 0 | 5 | 2 | 0 | 0 | 4 |
| repeatmark | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| repeats | 8 | 0 | 0 | 241 | 8 | 0 | 0 | 8 |
| rest | 21 | 11 | 0 | 826 | 10 | 0 | 0 | 21 |
| sameas | 2 | 0 | 0 | 45 | 2 | 0 | 0 | 2 |
| score | 16 | 10 | 0 | 1350 | 6 | 0 | 0 | 16 |
| section | 4 | 2 | 0 | 821 | 2 | 0 | 0 | 4 |
| slur | 25 | 0 | 0 | 1504 | 25 | 0 | 0 | 25 |
| space | 2 | 1 | 0 | 150 | 1 | 0 | 0 | 2 |
| stagedir | 1 | 0 | 0 | 119 | 1 | 0 | 0 | 1 |
| stem | 16 | 4 | 0 | 579 | 12 | 0 | 0 | 16 |
| symbol | 2 | 1 | 0 | 11 | 1 | 0 | 0 | 2 |
| symboldef | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| tab | 4 | 0 | 14 | 609 | 5 | 0 | 0 | 5 |
| tempo | 4 | 0 | 0 | 184 | 4 | 0 | 0 | 4 |
| tie | 12 | 0 | 0 | 788 | 12 | 0 | 0 | 12 |
| trill | 8 | 4 | 0 | 128 | 4 | 0 | 0 | 8 |
| tuplet | 22 | 5 | 0 | 940 | 17 | 0 | 0 | 22 |
| turn | 6 | 3 | 0 | 92 | 3 | 0 | 0 | 6 |
| unison | 7 | 3 | 0 | 202 | 4 | 0 | 0 | 7 |

## Top divergências estruturais (8 arquivo(s) com divergências; até 30 listados)

| Arquivo | Divergências | Primeira divergência |
|---|---|---|
| midi/005-maqam-rast-external-tuning.mei | 14 | svg/svg[0]/g[0]: esperado [14 filhos], obtido [15 filhos] |
| tab/tab-004.mei | 14 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]: esperado [16 filhos], obtido [13 filhos] |
| cross-staff/cross-staff-005.mei | 5 | svg/svg[0]/g[0]/g[2]/g[2]/g[1]/g[3]: esperado [3 filhos], obtido [7 filhos] |
| barline/barline-009.mei | 4 | svg/svg[0]/g[0]/g[2]/g[3]/g[5]: esperado [6 filhos], obtido [4 filhos] |
| cross-staff/cross-staff-020.mei | 3 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]/g[3]: esperado [9 filhos], obtido [13 filhos] |
| arpeg/arpeg-003.mei | 1 | svg/svg[0]/g[0]/g[2]/g[6]/g[2]: esperado [11 filhos], obtido [15 filhos] |
| cross-staff/cross-staff-004.mei | 1 | svg/svg[0]/g[0]/g[2]/g[4]/g[1]/g[0]: esperado [2 filhos], obtido [8 filhos] |
| layer/layer-015.mei | 1 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/g[0]: esperado [4 filhos], obtido [7 filhos] |

## Maiores desvios numéricos (até 10 listados)

| Arquivo | Maior desvio | Divergências numéricas | Primeira divergência |
|---|---|---|---|
| neume/neume-001.mei | 26879.0 | 938 | svg/svg[0]/g[0]: esperado [transform[0]=0.0], obtido [transform[0]=500.0] |
| chord/chord-001.mei | 14835.0 | 1085 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[1]=1458.0], obtido [d[1]=5218.0] |
| tab/tab-005.mei | 13000.0 | 241 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[0]=3339.0], obtido [d[0]=5549.0] |
| arpeg/arpeg-004.mei | 6573.0 | 158 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[2]=6303.0], obtido [d[2]=4738.0] |
| chord/chord-007.mei | 4472.0 | 133 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[1]=1548.0], obtido [d[1]=4950.0] |
| beamspan/beamspan-004.mei | 4426.0 | 189 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=4459.0], obtido [d[3]=4081.0] |
| section/section-001.mei | 3423.0 | 819 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=3890.0], obtido [d[3]=4460.0] |
| ossia/ossia-004.mei | 3340.0 | 28 | svg/svg[0]/g[0]/g[2]/g[3]/g[0]/g[1]/g[1]/g[0]/polygon[0]: esperado [points[1]=3492.0], obtido [points[1]=2850.0] |
| lyric/lyric-005.mei | 3243.0 | 637 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=8533.0], obtido [d[3]=8980.0] |
| lyric/lyric-006.mei | 3243.0 | 637 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=8531.0], obtido [d[3]=8978.0] |

## Mais próximos do limpo — fila de menor custo (115 arquivo(s) com ≤10 divergências; até 30 listados)

| Arquivo | Divergências numéricas | Maior desvio | Primeira divergência |
|---|---|---|---|
| dynam/dynam-007.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[4]/g[2]/text[0]/tspan[1]/tspan[0]: esperado [y[0]=2551.0], obtido [y[0]=2550.0] |
| pedal/pedal-005.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[5]/polyline[0]: esperado [points[1]=2529.0], obtido [points[1]=2528.0] |
| tuplet/tuplet-012.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[4]/g[2]/g[0]/g[1]/g[1]/polyline[1]: esperado [points[5]=5847.0], obtido [points[5]=5846.0] |
| breath/breath-002.mei | 1 | 45.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[2]/use[0]: esperado [transform[0]=1992.0], obtido [transform[0]=2037.0] |
| gracenote/gracenote-002.mei | 1 | 65.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[4]/g[2]/g[1]/path[1]: esperado [d[1]=1593.0], obtido [d[1]=1658.0] |
| annot/annot-005.mei | 1 | 90.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/g[4]/g[0]/g[1]/path[0]: esperado [d[3]=3429.0], obtido [d[3]=3519.0] |
| editorial/editorial-002.mei | 1 | 90.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[4]/g[1]/g[1]/path[0]: esperado [d[3]=1957.0], obtido [d[3]=1867.0] |
| tempo/tempo-004.mei | 1 | 90.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[2]/g[0]/g[0]/path[0]: esperado [d[3]=2430.0], obtido [d[3]=2520.0] |
| chord/chord-003.mei | 1 | 178.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[4]/g[0]/g[0]/path[0]: esperado [d[1]=2141.0], obtido [d[1]=1963.0] |
| slur/slur-016.mei | 1 | 996.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1156.0], obtido [d[1]=2152.0] |
| gliss/gliss03.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1307.0], obtido [d[1]=1306.0] |
| layer/layer-014.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1066.0], obtido [d[1]=1067.0] |
| slur/slur-009.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1156.0], obtido [d[1]=1157.0] |
| slur/slur-025.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[7]/g[1]/path[0]: esperado [d[1]=1426.0], obtido [d[1]=1427.0] |
| accid/accid-001.mei | 2 | 3.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[0]/g[3]/g[2]/use[0]: esperado [transform[0]=6552.0], obtido [transform[0]=6549.0] |
| accid/accid-014.mei | 2 | 3.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[3]/g[2]/g[2]/use[0]: esperado [transform[0]=2909.0], obtido [transform[0]=2906.0] |
| mensural/mensural-002.mei | 2 | 45.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[0]/g[1]/polygon[0]: esperado [points[0]=6492.0], obtido [points[0]=6537.0] |
| mensural/mensural-003.mei | 2 | 45.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[2]/g[1]/polygon[0]: esperado [points[0]=1725.0], obtido [points[0]=1770.0] |
| mensural/mensural-001.mei | 2 | 49.0 | svg/svg[0]/g[0]/g[2]/g[5]/g[3]/g[3]/polygon[0]: esperado [points[0]=8635.0], obtido [points[0]=8684.0] |
| slur/slur-021.mei | 2 | 85.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1516.0], obtido [d[1]=1517.0] |
| gracenote/gracenote-018.mei | 2 | 90.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/g[4]/g[4]/g[1]/path[1]: esperado [d[1]=1603.0], obtido [d[1]=1566.0] |
| hairpin/hairpin-006.mei | 2 | 90.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[1]/polyline[0]: esperado [points[2]=5817.0], obtido [points[2]=5727.0] |
| rest/rest-016.mei | 2 | 158.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[0]=1599.0], obtido [d[0]=1441.0] |
| section/section-002.mei | 2 | 158.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[0]=1599.0], obtido [d[0]=1441.0] |
| slur/slur-010.mei | 2 | 158.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/path[0]: esperado [d[1]=1606.0], obtido [d[1]=1607.0] |
| dynam/dynam-010.mei | 2 | 360.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[3]/use[0]: esperado [transform[0]=2295.0], obtido [transform[0]=2205.0] |
| dynam/dynam-001.mei | 2 | 525.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/use[0]: esperado [transform[1]=2498.0], obtido [transform[1]=3023.0] |
| dynam/dynam-009.mei | 2 | 525.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/use[0]: esperado [transform[1]=2498.0], obtido [transform[1]=3023.0] |
| color/color-001.mei | 2 | 540.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[2]/g[4]/g[2]/use[0]: esperado [transform[1]=2356.0], obtido [transform[1]=2896.0] |
| score/score-016.mei | 2 | 591.0 | svg/svg[0]/g[0]/g[2]/g[18]/g[0]/text[0]: esperado [y[0]=1598.0], obtido [y[0]=1007.0] |

