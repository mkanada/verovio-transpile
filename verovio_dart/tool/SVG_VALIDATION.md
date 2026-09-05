# SVG_VALIDATION — comparação de SVG (harness da Fase 5)

Estrutural: 612/621 limpos
Numérico (eps=0.0): 246/621 limpos
Divergências estruturais (total): 44
Divergências numéricas (total): 27601

Gerado em 2026-09-05 por `dart run tool/compare_svg.dart` (modo: both, epsilon: 0.0).

- Divergentes: 375
- Falhas (exceção durante renderização): 0
- Sem renderização Dart disponível (stub `renderSvgForComparison` da Fase 5): 0

## Por categoria (75 categorias)

| Categoria | Estrutural limpos | Numérico limpos | Div. est. (total) | Div. num. (total) | Divergentes | Falhas | Sem render | Total |
|---|---|---|---|---|---|---|---|---|
| accid | 14 | 3 | 0 | 326 | 11 | 0 | 0 | 14 |
| annot | 7 | 4 | 0 | 8 | 3 | 0 | 0 | 7 |
| app | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 3 |
| arpeg | 6 | 0 | 1 | 719 | 7 | 0 | 0 | 7 |
| artic | 19 | 0 | 0 | 1501 | 19 | 0 | 0 | 19 |
| barline | 8 | 6 | 5 | 811 | 4 | 0 | 0 | 10 |
| beam | 61 | 42 | 0 | 1436 | 19 | 0 | 0 | 61 |
| beamspan | 6 | 1 | 0 | 434 | 5 | 0 | 0 | 6 |
| bracketspan | 1 | 0 | 0 | 15 | 1 | 0 | 0 | 1 |
| breath | 2 | 1 | 0 | 1 | 1 | 0 | 0 | 2 |
| btrem | 6 | 1 | 0 | 175 | 5 | 0 | 0 | 6 |
| caesura | 1 | 0 | 0 | 38 | 1 | 0 | 0 | 1 |
| choice | 1 | 0 | 0 | 34 | 1 | 0 | 0 | 1 |
| chord | 10 | 1 | 0 | 1376 | 9 | 0 | 0 | 10 |
| clef | 7 | 2 | 0 | 372 | 5 | 0 | 0 | 7 |
| color | 4 | 2 | 0 | 19 | 2 | 0 | 0 | 4 |
| cpmark | 1 | 0 | 0 | 99 | 1 | 0 | 0 | 1 |
| cross-staff | 21 | 2 | 9 | 2183 | 22 | 0 | 0 | 24 |
| custos | 1 | 0 | 0 | 70 | 1 | 0 | 0 | 1 |
| dir | 10 | 4 | 0 | 300 | 6 | 0 | 0 | 10 |
| dot | 6 | 0 | 0 | 415 | 6 | 0 | 0 | 6 |
| dynam | 10 | 0 | 0 | 174 | 10 | 0 | 0 | 10 |
| editorial | 2 | 1 | 0 | 1 | 1 | 0 | 0 | 2 |
| ending | 3 | 1 | 0 | 233 | 2 | 0 | 0 | 3 |
| expansion | 3 | 0 | 0 | 153 | 3 | 0 | 0 | 3 |
| fermata | 7 | 2 | 0 | 268 | 5 | 0 | 0 | 7 |
| figured-bass | 5 | 2 | 0 | 49 | 3 | 0 | 0 | 5 |
| fing | 2 | 1 | 0 | 230 | 1 | 0 | 0 | 2 |
| font | 2 | 0 | 0 | 200 | 2 | 0 | 0 | 2 |
| ftrem | 2 | 0 | 0 | 15 | 2 | 0 | 0 | 2 |
| gliss | 6 | 0 | 0 | 69 | 6 | 0 | 0 | 6 |
| gracenote | 27 | 3 | 0 | 802 | 24 | 0 | 0 | 27 |
| hairpin | 6 | 2 | 0 | 23 | 4 | 0 | 0 | 6 |
| harm | 5 | 3 | 0 | 295 | 2 | 0 | 0 | 5 |
| keysig | 6 | 5 | 0 | 41 | 1 | 0 | 0 | 6 |
| layer | 14 | 4 | 1 | 787 | 11 | 0 | 0 | 15 |
| ligature | 50 | 30 | 0 | 286 | 20 | 0 | 0 | 50 |
| lyric | 16 | 5 | 0 | 2043 | 11 | 0 | 0 | 16 |
| mdiv | 1 | 0 | 0 | 121 | 1 | 0 | 0 | 1 |
| measure | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| mensur | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 8 |
| mensural | 25 | 21 | 0 | 78 | 4 | 0 | 0 | 25 |
| metersig | 5 | 4 | 0 | 150 | 1 | 0 | 0 | 5 |
| midi | 1 | 1 | 14 | 778 | 1 | 0 | 0 | 2 |
| mnum | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| mordent | 5 | 1 | 0 | 123 | 4 | 0 | 0 | 5 |
| neume | 6 | 0 | 0 | 1031 | 6 | 0 | 0 | 6 |
| note | 12 | 7 | 0 | 476 | 5 | 0 | 0 | 12 |
| octave | 4 | 0 | 0 | 169 | 4 | 0 | 0 | 4 |
| ornam | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| ossia | 4 | 0 | 0 | 986 | 4 | 0 | 0 | 4 |
| pedal | 6 | 4 | 0 | 172 | 2 | 0 | 0 | 6 |
| pgfoot | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| phrase | 1 | 0 | 0 | 58 | 1 | 0 | 0 | 1 |
| reh | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| rend | 4 | 2 | 0 | 5 | 2 | 0 | 0 | 4 |
| repeatmark | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| repeats | 8 | 6 | 0 | 55 | 2 | 0 | 0 | 8 |
| rest | 21 | 11 | 0 | 660 | 10 | 0 | 0 | 21 |
| sameas | 2 | 0 | 0 | 30 | 2 | 0 | 0 | 2 |
| score | 16 | 10 | 0 | 1300 | 6 | 0 | 0 | 16 |
| section | 4 | 2 | 0 | 805 | 2 | 0 | 0 | 4 |
| slur | 25 | 0 | 0 | 1450 | 25 | 0 | 0 | 25 |
| space | 2 | 1 | 0 | 150 | 1 | 0 | 0 | 2 |
| stagedir | 1 | 0 | 0 | 119 | 1 | 0 | 0 | 1 |
| stem | 16 | 4 | 0 | 553 | 12 | 0 | 0 | 16 |
| symbol | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| symboldef | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| tab | 4 | 0 | 14 | 609 | 5 | 0 | 0 | 5 |
| tempo | 4 | 0 | 0 | 154 | 4 | 0 | 0 | 4 |
| tie | 12 | 0 | 0 | 647 | 12 | 0 | 0 | 12 |
| trill | 8 | 6 | 0 | 74 | 2 | 0 | 0 | 8 |
| tuplet | 22 | 10 | 0 | 673 | 12 | 0 | 0 | 22 |
| turn | 6 | 3 | 0 | 40 | 3 | 0 | 0 | 6 |
| unison | 7 | 3 | 0 | 134 | 4 | 0 | 0 | 7 |

## Top divergências estruturais (9 arquivo(s) com divergências; até 30 listados)

| Arquivo | Divergências | Primeira divergência |
|---|---|---|
| midi/005-maqam-rast-external-tuning.mei | 14 | svg/svg[0]/g[0]: esperado [14 filhos], obtido [15 filhos] |
| tab/tab-004.mei | 14 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]: esperado [16 filhos], obtido [13 filhos] |
| cross-staff/cross-staff-005.mei | 5 | svg/svg[0]/g[0]/g[2]/g[2]/g[1]/g[3]: esperado [3 filhos], obtido [7 filhos] |
| barline/barline-009.mei | 4 | svg/svg[0]/g[0]/g[2]/g[3]/g[5]: esperado [6 filhos], obtido [4 filhos] |
| cross-staff/cross-staff-020.mei | 3 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]/g[3]: esperado [9 filhos], obtido [13 filhos] |
| arpeg/arpeg-003.mei | 1 | svg/svg[0]/g[0]/g[2]/g[6]/g[2]: esperado [11 filhos], obtido [15 filhos] |
| barline/barline-007.mei | 1 | svg/svg[0]/g[0]/g[2]/g[7]/g[7]: esperado [68 filhos], obtido [70 filhos] |
| cross-staff/cross-staff-004.mei | 1 | svg/svg[0]/g[0]/g[2]/g[4]/g[1]/g[0]: esperado [2 filhos], obtido [8 filhos] |
| layer/layer-015.mei | 1 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/g[0]: esperado [4 filhos], obtido [7 filhos] |

## Maiores desvios numéricos (até 10 listados)

| Arquivo | Maior desvio | Divergências numéricas | Primeira divergência |
|---|---|---|---|
| neume/neume-001.mei | 26879.0 | 938 | svg/svg[0]/g[0]: esperado [transform[0]=0.0], obtido [transform[0]=500.0] |
| chord/chord-001.mei | 14835.0 | 1085 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[1]=1458.0], obtido [d[1]=5218.0] |
| tab/tab-005.mei | 13000.0 | 241 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[0]=3339.0], obtido [d[0]=5549.0] |
| arpeg/arpeg-004.mei | 6573.0 | 158 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[2]=6303.0], obtido [d[2]=4738.0] |
| beamspan/beamspan-004.mei | 4426.0 | 189 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=4459.0], obtido [d[3]=4457.0] |
| chord/chord-007.mei | 3402.0 | 133 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[1]=1548.0], obtido [d[1]=4950.0] |
| ossia/ossia-004.mei | 3340.0 | 2 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/rect[0]: esperado [x[0]=5372.0], obtido [x[0]=2032.0] |
| section/section-001.mei | 3211.0 | 803 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=3890.0], obtido [d[3]=4460.0] |
| accid/accid-013.mei | 3044.0 | 169 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[1]=1458.0], obtido [d[1]=4502.0] |
| slur/slur-012.mei | 2856.0 | 137 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[1]=1278.0], obtido [d[1]=2890.0] |

## Mais próximos do limpo — fila de menor custo (127 arquivo(s) com ≤10 divergências; até 30 listados)

| Arquivo | Divergências numéricas | Maior desvio | Primeira divergência |
|---|---|---|---|
| dynam/dynam-007.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[4]/g[2]/text[0]/tspan[1]/tspan[0]: esperado [y[0]=2551.0], obtido [y[0]=2550.0] |
| figured-bass/figured-bass-004.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[7]/path[0]: esperado [d[1]=1516.0], obtido [d[1]=1517.0] |
| pedal/pedal-005.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[5]/polyline[0]: esperado [points[1]=2529.0], obtido [points[1]=2528.0] |
| tempo/tempo-002.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[4]/path[0]: esperado [d[3]=2972.0], obtido [d[3]=2971.0] |
| tuplet/tuplet-012.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[4]/g[2]/g[0]/g[1]/g[1]/polyline[1]: esperado [points[5]=5847.0], obtido [points[5]=5846.0] |
| turn/turn-002.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[2]/path[0]: esperado [d[2]=1656.0], obtido [d[2]=1657.0] |
| gracenote/gracenote-012.mei | 1 | 37.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[2]/g[0]/g[1]/path[1]: esperado [d[1]=1785.0], obtido [d[1]=1748.0] |
| breath/breath-002.mei | 1 | 45.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[2]/use[0]: esperado [transform[0]=1992.0], obtido [transform[0]=2037.0] |
| gracenote/gracenote-002.mei | 1 | 65.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[4]/g[2]/g[1]/path[1]: esperado [d[1]=1593.0], obtido [d[1]=1658.0] |
| annot/annot-005.mei | 1 | 90.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/g[4]/g[0]/g[1]/path[0]: esperado [d[3]=3429.0], obtido [d[3]=3519.0] |
| editorial/editorial-002.mei | 1 | 90.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[4]/g[1]/g[1]/path[0]: esperado [d[3]=1957.0], obtido [d[3]=1867.0] |
| gracenote/gracenote-019.mei | 1 | 90.0 | svg/svg[0]/g[0]/g[3]/g[1]/g[0]/g[4]/g[1]/g[1]/path[0]: esperado [d[3]=1809.0], obtido [d[3]=1719.0] |
| octave/octave-002.mei | 1 | 90.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[0]/g[1]/g[0]/g[1]/path[0]: esperado [d[3]=1995.0], obtido [d[3]=1905.0] |
| tempo/tempo-004.mei | 1 | 90.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[2]/g[0]/g[0]/path[0]: esperado [d[3]=2430.0], obtido [d[3]=2520.0] |
| chord/chord-003.mei | 1 | 178.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[4]/g[0]/g[0]/path[0]: esperado [d[1]=2141.0], obtido [d[1]=1963.0] |
| lyric/lyric-011.mei | 1 | 180.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[0]/g[1]/g[0]/g[0]/g[1]/ellipse[0]: esperado [cy[0]=1899.0], obtido [cy[0]=1719.0] |
| stem/stem-014.mei | 1 | 180.0 | svg/svg[0]/g[0]/g[2]/g[6]/g[1]/g[4]/g[1]/g[0]/g[1]/ellipse[0]: esperado [cy[0]=2797.0], obtido [cy[0]=2617.0] |
| stem/stem-011.mei | 1 | 208.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[0]/g[0]/g[1]/path[0]: esperado [d[0]=3653.0], obtido [d[0]=3445.0] |
| slur/slur-016.mei | 1 | 996.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1156.0], obtido [d[1]=2152.0] |
| gliss/gliss03.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1307.0], obtido [d[1]=1306.0] |
| layer/layer-014.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1066.0], obtido [d[1]=1067.0] |
| repeats/rpt-002.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[0]/g[1]/polygon[1]: esperado [points[1]=2230.0], obtido [points[1]=2229.0] |
| rest/rest-016.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[3]=2326.0], obtido [d[3]=2327.0] |
| section/section-002.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[3]=2326.0], obtido [d[3]=2327.0] |
| slur/slur-009.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1156.0], obtido [d[1]=1157.0] |
| slur/slur-010.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/path[0]: esperado [d[1]=1606.0], obtido [d[1]=1607.0] |
| slur/slur-021.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1516.0], obtido [d[1]=1517.0] |
| slur/slur-025.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[7]/g[1]/path[0]: esperado [d[1]=1426.0], obtido [d[1]=1427.0] |
| tie/tie-003.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[2]=731.0], obtido [d[2]=732.0] |
| tuplet/tuplet-019.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[2]/g[0]/g[0]/use[0]: esperado [transform[1]=531.0], obtido [transform[1]=532.0] |

