# SVG_VALIDATION — comparação de SVG (harness da Fase 5)

Estrutural: 612/621 limpos
Numérico (eps=0.0): 327/621 limpos
Divergências estruturais (total): 44
Divergências numéricas (total): 18652

Gerado em 2026-09-06 por `dart run tool/compare_svg.dart` (modo: both, epsilon: 0.0).

- Divergentes: 294
- Falhas (exceção durante renderização): 0
- Sem renderização Dart disponível (stub `renderSvgForComparison` da Fase 5): 0

## Por categoria (75 categorias)

| Categoria | Estrutural limpos | Numérico limpos | Div. est. (total) | Div. num. (total) | Divergentes | Falhas | Sem render | Total |
|---|---|---|---|---|---|---|---|---|
| accid | 14 | 7 | 0 | 123 | 7 | 0 | 0 | 14 |
| annot | 7 | 5 | 0 | 7 | 2 | 0 | 0 | 7 |
| app | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 3 |
| arpeg | 6 | 0 | 1 | 706 | 7 | 0 | 0 | 7 |
| artic | 19 | 0 | 0 | 1480 | 19 | 0 | 0 | 19 |
| barline | 8 | 7 | 5 | 639 | 3 | 0 | 0 | 10 |
| beam | 61 | 49 | 0 | 1134 | 12 | 0 | 0 | 61 |
| beamspan | 6 | 1 | 0 | 433 | 5 | 0 | 0 | 6 |
| bracketspan | 1 | 0 | 0 | 15 | 1 | 0 | 0 | 1 |
| breath | 2 | 1 | 0 | 1 | 1 | 0 | 0 | 2 |
| btrem | 6 | 4 | 0 | 4 | 2 | 0 | 0 | 6 |
| caesura | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| choice | 1 | 0 | 0 | 1 | 1 | 0 | 0 | 1 |
| chord | 10 | 6 | 0 | 84 | 4 | 0 | 0 | 10 |
| clef | 7 | 2 | 0 | 330 | 5 | 0 | 0 | 7 |
| color | 4 | 3 | 0 | 2 | 1 | 0 | 0 | 4 |
| cpmark | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| cross-staff | 21 | 2 | 9 | 2211 | 22 | 0 | 0 | 24 |
| custos | 1 | 0 | 0 | 70 | 1 | 0 | 0 | 1 |
| dir | 10 | 4 | 0 | 223 | 6 | 0 | 0 | 10 |
| dot | 6 | 1 | 0 | 96 | 5 | 0 | 0 | 6 |
| dynam | 10 | 2 | 0 | 67 | 8 | 0 | 0 | 10 |
| editorial | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| ending | 3 | 2 | 0 | 8 | 1 | 0 | 0 | 3 |
| expansion | 3 | 0 | 0 | 38 | 3 | 0 | 0 | 3 |
| fermata | 7 | 5 | 0 | 152 | 2 | 0 | 0 | 7 |
| figured-bass | 5 | 2 | 0 | 46 | 3 | 0 | 0 | 5 |
| fing | 2 | 1 | 0 | 242 | 1 | 0 | 0 | 2 |
| font | 2 | 0 | 0 | 200 | 2 | 0 | 0 | 2 |
| ftrem | 2 | 1 | 0 | 4 | 1 | 0 | 0 | 2 |
| gliss | 6 | 5 | 0 | 9 | 1 | 0 | 0 | 6 |
| gracenote | 27 | 7 | 0 | 537 | 20 | 0 | 0 | 27 |
| hairpin | 6 | 4 | 0 | 14 | 2 | 0 | 0 | 6 |
| harm | 5 | 4 | 0 | 200 | 1 | 0 | 0 | 5 |
| keysig | 6 | 5 | 0 | 41 | 1 | 0 | 0 | 6 |
| layer | 14 | 7 | 1 | 491 | 8 | 0 | 0 | 15 |
| ligature | 50 | 30 | 0 | 278 | 20 | 0 | 0 | 50 |
| lyric | 16 | 11 | 0 | 301 | 5 | 0 | 0 | 16 |
| mdiv | 1 | 0 | 0 | 121 | 1 | 0 | 0 | 1 |
| measure | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| mensur | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 8 |
| mensural | 25 | 21 | 0 | 78 | 4 | 0 | 0 | 25 |
| metersig | 5 | 4 | 0 | 142 | 1 | 0 | 0 | 5 |
| midi | 1 | 1 | 14 | 767 | 1 | 0 | 0 | 2 |
| mnum | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| mordent | 5 | 1 | 0 | 123 | 4 | 0 | 0 | 5 |
| neume | 6 | 0 | 0 | 210 | 6 | 0 | 0 | 6 |
| note | 12 | 7 | 0 | 414 | 5 | 0 | 0 | 12 |
| octave | 4 | 1 | 0 | 159 | 3 | 0 | 0 | 4 |
| ornam | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| ossia | 4 | 0 | 0 | 986 | 4 | 0 | 0 | 4 |
| pedal | 6 | 5 | 0 | 171 | 1 | 0 | 0 | 6 |
| pgfoot | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| phrase | 1 | 0 | 0 | 58 | 1 | 0 | 0 | 1 |
| reh | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| rend | 4 | 2 | 0 | 5 | 2 | 0 | 0 | 4 |
| repeatmark | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| repeats | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 8 |
| rest | 21 | 14 | 0 | 382 | 7 | 0 | 0 | 21 |
| sameas | 2 | 0 | 0 | 14 | 2 | 0 | 0 | 2 |
| score | 16 | 11 | 0 | 1259 | 5 | 0 | 0 | 16 |
| section | 4 | 2 | 0 | 796 | 2 | 0 | 0 | 4 |
| slur | 25 | 0 | 0 | 1122 | 25 | 0 | 0 | 25 |
| space | 2 | 1 | 0 | 150 | 1 | 0 | 0 | 2 |
| stagedir | 1 | 0 | 0 | 119 | 1 | 0 | 0 | 1 |
| stem | 16 | 12 | 0 | 151 | 4 | 0 | 0 | 16 |
| symbol | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| symboldef | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| tab | 4 | 0 | 14 | 606 | 5 | 0 | 0 | 5 |
| tempo | 4 | 1 | 0 | 40 | 3 | 0 | 0 | 4 |
| tie | 12 | 0 | 0 | 310 | 12 | 0 | 0 | 12 |
| trill | 8 | 6 | 0 | 62 | 2 | 0 | 0 | 8 |
| tuplet | 22 | 15 | 0 | 215 | 7 | 0 | 0 | 22 |
| turn | 6 | 4 | 0 | 5 | 2 | 0 | 0 | 6 |
| unison | 7 | 7 | 0 | 0 | 0 | 0 | 0 | 7 |

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
| tab/tab-005.mei | 13000.0 | 241 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[0]=3339.0], obtido [d[0]=5549.0] |
| arpeg/arpeg-004.mei | 6573.0 | 158 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[2]=6303.0], obtido [d[2]=4738.0] |
| beamspan/beamspan-004.mei | 4426.0 | 188 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=4459.0], obtido [d[3]=4458.0] |
| layer/layer-015.mei | 4131.0 | 71 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=3789.0], obtido [d[3]=6840.0] |
| ossia/ossia-004.mei | 3340.0 | 2 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/rect[0]: esperado [x[0]=5372.0], obtido [x[0]=2032.0] |
| cross-staff/cross-staff-005.mei | 3273.0 | 226 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=3225.0], obtido [d[3]=5418.0] |
| artic/artic-018.mei | 3105.0 | 671 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[1]=1658.0], obtido [d[1]=1838.0] |
| cross-staff/cross-staff-004.mei | 2920.0 | 271 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[1]=1629.0], obtido [d[1]=1678.0] |
| tab/tab-004.mei | 2761.0 | 68 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]: esperado [16 filhos], obtido [13 filhos] |
| beam/beam-026.mei | 2565.0 | 66 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=3789.0], obtido [d[3]=4879.0] |

## Mais próximos do limpo — fila de menor custo (129 arquivo(s) com ≤10 divergências; até 30 listados)

| Arquivo | Divergências numéricas | Maior desvio | Primeira divergência |
|---|---|---|---|
| chord/chord-006.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[2]/path[0]: esperado [d[4]=2160.0], obtido [d[4]=2161.0] |
| lyric/lyric-013.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[3]/path[0]: esperado [d[2]=6629.0], obtido [d[2]=6630.0] |
| tempo/tempo-002.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[4]/path[0]: esperado [d[3]=2972.0], obtido [d[3]=2971.0] |
| turn/turn-002.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[2]/path[0]: esperado [d[2]=1656.0], obtido [d[2]=1657.0] |
| lyric/lyric-001.mei | 1 | 3.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/path[0]: esperado [d[2]=7191.0], obtido [d[2]=7194.0] |
| figured-bass/figured-bass-004.mei | 1 | 5.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[7]/path[0]: esperado [d[2]=2416.0], obtido [d[2]=2421.0] |
| rest/rest-010.mei | 1 | 9.0 | svg/svg[0]/g[0]/g[3]/g[0]/g[1]/g[4]/g[2]/g[0]/use[0]: esperado [transform[1]=4923.0], obtido [transform[1]=4932.0] |
| gracenote/gracenote-012.mei | 1 | 37.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[2]/g[0]/g[1]/path[1]: esperado [d[1]=1785.0], obtido [d[1]=1748.0] |
| gracenote/gracenote-018.mei | 1 | 37.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/g[4]/g[4]/g[1]/path[1]: esperado [d[1]=1603.0], obtido [d[1]=1566.0] |
| breath/breath-002.mei | 1 | 45.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[2]/use[0]: esperado [transform[0]=1992.0], obtido [transform[0]=2037.0] |
| gracenote/gracenote-002.mei | 1 | 65.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[4]/g[2]/g[1]/path[1]: esperado [d[1]=1593.0], obtido [d[1]=1658.0] |
| slur/slur-001.mei | 1 | 180.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]/path[0]: esperado [d[0]=1539.0], obtido [d[0]=1359.0] |
| choice/choice-001.mei | 1 | 208.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[0]/g[0]/g[3]/g[0]/g[0]/g[0]/use[0]: esperado [transform[0]=3531.0], obtido [transform[0]=3739.0] |
| chord/chord-007.mei | 1 | 208.0 | svg/svg[0]/g[0]/g[2]/g[4]/g[0]/g[1]/g[0]/g[0]/path[0]: esperado [d[0]=8798.0], obtido [d[0]=9006.0] |
| gracenote/gracenote-010.mei | 1 | 331.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]/g[3]/g[2]/use[0]: esperado [transform[0]=2905.0], obtido [transform[0]=3236.0] |
| clef/clef-005.mei | 1 | 466.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[1]/g[3]/g[1]/use[0]: esperado [transform[0]=2980.0], obtido [transform[0]=3446.0] |
| slur/slur-016.mei | 1 | 945.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1156.0], obtido [d[1]=2101.0] |
| btrem/btrem-001.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]/path[0]: esperado [d[3]=2231.0], obtido [d[3]=2230.0] |
| btrem/btrem-004.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[3]/g[1]/g[0]/use[0]: esperado [transform[1]=2480.0], obtido [transform[1]=2479.0] |
| lyric/lyric-010.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[6]/path[0]: esperado [d[2]=11054.0], obtido [d[2]=11055.0] |
| rest/rest-016.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[3]=2326.0], obtido [d[3]=2327.0] |
| section/section-002.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[3]=2326.0], obtido [d[3]=2327.0] |
| slur/slur-010.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/path[0]: esperado [d[2]=1306.0], obtido [d[2]=1307.0] |
| slur/slur-025.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[7]/g[1]/path[0]: esperado [d[2]=10502.0], obtido [d[2]=10503.0] |
| tie/tie-003.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[2]=731.0], obtido [d[2]=732.0] |
| dynam/dynam-004.mei | 2 | 2.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[4]/path[0]: esperado [d[2]=3073.0], obtido [d[2]=3074.0] |
| layer/layer-014.mei | 2 | 2.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[2]=2148.0], obtido [d[2]=2149.0] |
| slur/slur-009.mei | 2 | 2.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[2]=1100.0], obtido [d[2]=1102.0] |
| slur/slur-024.mei | 2 | 2.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[2]=2347.0], obtido [d[2]=2348.0] |
| tuplet/tuplet-001.mei | 2 | 2.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[2]/path[0]: esperado [d[2]=5169.0], obtido [d[2]=5170.0] |

