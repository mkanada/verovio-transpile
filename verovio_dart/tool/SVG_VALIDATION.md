# SVG_VALIDATION — comparação de SVG (harness da Fase 5)

Estrutural: 620/621 limpos
Numérico (eps=0.0): 523/621 limpos
Divergências estruturais (total): 14
Divergências numéricas (total): 5762

Gerado em 2026-09-09 por `dart run tool/compare_svg.dart` (modo: both, epsilon: 0.0).

- Divergentes: 98
- Falhas (exceção durante renderização): 0
- Sem renderização Dart disponível (stub `renderSvgForComparison` da Fase 5): 0

## Por categoria (75 categorias)

| Categoria | Estrutural limpos | Numérico limpos | Div. est. (total) | Div. num. (total) | Divergentes | Falhas | Sem render | Total |
|---|---|---|---|---|---|---|---|---|
| accid | 14 | 14 | 0 | 0 | 0 | 0 | 0 | 14 |
| annot | 7 | 7 | 0 | 0 | 0 | 0 | 0 | 7 |
| app | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 3 |
| arpeg | 7 | 4 | 0 | 252 | 3 | 0 | 0 | 7 |
| artic | 19 | 17 | 0 | 6 | 2 | 0 | 0 | 19 |
| barline | 10 | 10 | 0 | 0 | 0 | 0 | 0 | 10 |
| beam | 61 | 58 | 0 | 8 | 3 | 0 | 0 | 61 |
| beamspan | 6 | 3 | 0 | 224 | 3 | 0 | 0 | 6 |
| bracketspan | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| breath | 2 | 1 | 0 | 1 | 1 | 0 | 0 | 2 |
| btrem | 6 | 6 | 0 | 0 | 0 | 0 | 0 | 6 |
| caesura | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| choice | 1 | 0 | 0 | 1 | 1 | 0 | 0 | 1 |
| chord | 10 | 8 | 0 | 26 | 2 | 0 | 0 | 10 |
| clef | 7 | 7 | 0 | 0 | 0 | 0 | 0 | 7 |
| color | 4 | 4 | 0 | 0 | 0 | 0 | 0 | 4 |
| cpmark | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| cross-staff | 24 | 14 | 0 | 666 | 10 | 0 | 0 | 24 |
| custos | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| dir | 10 | 8 | 0 | 75 | 2 | 0 | 0 | 10 |
| dot | 6 | 6 | 0 | 0 | 0 | 0 | 0 | 6 |
| dynam | 10 | 8 | 0 | 5 | 2 | 0 | 0 | 10 |
| editorial | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| ending | 3 | 2 | 0 | 8 | 1 | 0 | 0 | 3 |
| expansion | 3 | 0 | 0 | 24 | 3 | 0 | 0 | 3 |
| fermata | 7 | 6 | 0 | 115 | 1 | 0 | 0 | 7 |
| figured-bass | 5 | 4 | 0 | 42 | 1 | 0 | 0 | 5 |
| fing | 2 | 1 | 0 | 216 | 1 | 0 | 0 | 2 |
| font | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| ftrem | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| gliss | 6 | 6 | 0 | 0 | 0 | 0 | 0 | 6 |
| gracenote | 27 | 21 | 0 | 69 | 6 | 0 | 0 | 27 |
| hairpin | 6 | 5 | 0 | 4 | 1 | 0 | 0 | 6 |
| harm | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 5 |
| keysig | 6 | 6 | 0 | 0 | 0 | 0 | 0 | 6 |
| layer | 15 | 13 | 0 | 45 | 2 | 0 | 0 | 15 |
| ligature | 50 | 50 | 0 | 0 | 0 | 0 | 0 | 50 |
| lyric | 16 | 14 | 0 | 295 | 2 | 0 | 0 | 16 |
| mdiv | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| measure | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| mensur | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 8 |
| mensural | 25 | 25 | 0 | 0 | 0 | 0 | 0 | 25 |
| metersig | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 5 |
| midi | 1 | 1 | 14 | 11 | 1 | 0 | 0 | 2 |
| mnum | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| mordent | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 5 |
| neume | 6 | 0 | 0 | 210 | 6 | 0 | 0 | 6 |
| note | 12 | 11 | 0 | 2 | 1 | 0 | 0 | 12 |
| octave | 4 | 1 | 0 | 159 | 3 | 0 | 0 | 4 |
| ornam | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| ossia | 4 | 0 | 0 | 881 | 4 | 0 | 0 | 4 |
| pedal | 6 | 5 | 0 | 5 | 1 | 0 | 0 | 6 |
| pgfoot | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| phrase | 1 | 0 | 0 | 58 | 1 | 0 | 0 | 1 |
| reh | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| rend | 4 | 4 | 0 | 0 | 0 | 0 | 0 | 4 |
| repeatmark | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| repeats | 8 | 8 | 0 | 0 | 0 | 0 | 0 | 8 |
| rest | 21 | 15 | 0 | 376 | 6 | 0 | 0 | 21 |
| sameas | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| score | 16 | 16 | 0 | 0 | 0 | 0 | 0 | 16 |
| section | 4 | 3 | 0 | 786 | 1 | 0 | 0 | 4 |
| slur | 25 | 14 | 0 | 464 | 11 | 0 | 0 | 25 |
| space | 2 | 1 | 0 | 1 | 1 | 0 | 0 | 2 |
| stagedir | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 |
| stem | 16 | 14 | 0 | 55 | 2 | 0 | 0 | 16 |
| symbol | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| symboldef | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| tab | 5 | 0 | 0 | 642 | 5 | 0 | 0 | 5 |
| tempo | 4 | 4 | 0 | 0 | 0 | 0 | 0 | 4 |
| tie | 12 | 9 | 0 | 9 | 3 | 0 | 0 | 12 |
| trill | 8 | 7 | 0 | 2 | 1 | 0 | 0 | 8 |
| tuplet | 22 | 18 | 0 | 19 | 4 | 0 | 0 | 22 |
| turn | 6 | 6 | 0 | 0 | 0 | 0 | 0 | 6 |
| unison | 7 | 7 | 0 | 0 | 0 | 0 | 0 | 7 |

## Top divergências estruturais (1 arquivo(s) com divergências; até 30 listados)

| Arquivo | Divergências | Primeira divergência |
|---|---|---|
| midi/005-maqam-rast-external-tuning.mei | 14 | svg/svg[0]/g[0]: esperado [14 filhos], obtido [15 filhos] |

## Maiores desvios numéricos (até 10 listados)

| Arquivo | Maior desvio | Divergências numéricas | Primeira divergência |
|---|---|---|---|
| tab/tab-005.mei | 6655.0 | 225 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[0]=3339.0], obtido [d[0]=5549.0] |
| ossia/ossia-004.mei | 3340.0 | 2 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/rect[0]: esperado [x[0]=5372.0], obtido [x[0]=2032.0] |
| neume/neume-001.mei | 2454.0 | 117 | svg/svg[0]/g[0]/g[2]/g[3]/path[0]: esperado [d[0]=2454.0], obtido [d[0]=0.0] |
| cross-staff/cross-staff-020.mei | 1800.0 | 167 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=3787.0], obtido [d[3]=4858.0] |
| rest/rest-019.mei | 1778.0 | 228 | svg/svg[0]/g[0]/g[3]/g[0]/g[0]/path[0]: esperado [d[1]=5426.0], obtido [d[1]=5404.0] |
| tab/tab-004.mei | 1732.0 | 124 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/path[1]: esperado [d[2]=3002.0], obtido [d[2]=3098.0] |
| rest/rest-001.mei | 1080.0 | 22 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[0]/g[0]/g[0]/ellipse[0]: esperado [cx[0]=10430.0], obtido [cx[0]=10205.0] |
| slur/slur-016.mei | 945.0 | 1 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1156.0], obtido [d[1]=2101.0] |
| rest/rest-017.mei | 900.0 | 118 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[2]=4927.0], obtido [d[2]=4799.0] |
| dir/dir-005.mei | 720.0 | 2 | svg/svg[0]/g[0]/g[2]/g[2]/g[1]/g[2]/g[0]/g[0]/path[0]: esperado [d[1]=2105.0], obtido [d[1]=2825.0] |

## Mais próximos do limpo — fila de menor custo (55 arquivo(s) com ≤10 divergências; até 30 listados)

| Arquivo | Divergências numéricas | Maior desvio | Primeira divergência |
|---|---|---|---|
| gracenote/gracenote-022.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[3]/path[0]: esperado [d[1]=3834.0], obtido [d[1]=3833.0] |
| gracenote/gracenote-025.mei | 1 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[9]/path[0]: esperado [d[2]=6392.0], obtido [d[2]=6391.0] |
| slur/slur-014.mei | 1 | 3.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]/path[0]: esperado [d[2]=2948.0], obtido [d[2]=2945.0] |
| tuplet/tuplet-001.mei | 1 | 3.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[2]/path[0]: esperado [d[4]=8412.0], obtido [d[4]=8415.0] |
| lyric/lyric-015.mei | 1 | 4.0 | svg/svg[0]/g[0]/g[2]/g[5]/g[1]/path[0]: esperado [d[2]=14884.0], obtido [d[2]=14880.0] |
| beamspan/beamspan-004.mei | 1 | 5.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[3]/path[0]: esperado [d[2]=4135.0], obtido [d[2]=4130.0] |
| rest/rest-010.mei | 1 | 9.0 | svg/svg[0]/g[0]/g[3]/g[0]/g[1]/g[4]/g[2]/g[0]/use[0]: esperado [transform[1]=4923.0], obtido [transform[1]=4932.0] |
| beam/beam-050.mei | 1 | 23.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[5]/path[0]: esperado [d[1]=1665.0], obtido [d[1]=1688.0] |
| breath/breath-002.mei | 1 | 45.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[2]/use[0]: esperado [transform[0]=1992.0], obtido [transform[0]=2037.0] |
| space/space-001.mei | 1 | 99.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[4]/g[2]/g[0]/use[0]: esperado [transform[1]=2291.0], obtido [transform[1]=2390.0] |
| rest/rest-005.mei | 1 | 180.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]/g[4]/g[0]/g[1]/ellipse[0]: esperado [cy[0]=3751.0], obtido [cy[0]=3571.0] |
| choice/choice-001.mei | 1 | 208.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[0]/g[0]/g[3]/g[0]/g[0]/g[0]/use[0]: esperado [transform[0]=3531.0], obtido [transform[0]=3739.0] |
| chord/chord-007.mei | 1 | 208.0 | svg/svg[0]/g[0]/g[2]/g[4]/g[0]/g[1]/g[0]/g[0]/path[0]: esperado [d[0]=8798.0], obtido [d[0]=9006.0] |
| cross-staff/cross-staff-014.mei | 1 | 264.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]/g[4]/g[0]/g[0]/g[2]/use[0]: esperado [transform[0]=2039.0], obtido [transform[0]=2303.0] |
| tie/tie-012.mei | 1 | 378.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[2]/path[0]: esperado [d[1]=765.0], obtido [d[1]=1143.0] |
| slur/slur-016.mei | 1 | 945.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[1]/path[0]: esperado [d[1]=1156.0], obtido [d[1]=2101.0] |
| note/note-008.mei | 2 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[2]/g[13]/g[1]/path[0]: esperado [d[0]=16177.0], obtido [d[0]=16178.0] |
| trill/trill-005.mei | 2 | 14.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[4]/use[0]: esperado [transform[0]=2809.0], obtido [transform[0]=2795.0] |
| artic/artic-007.mei | 2 | 23.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[2]/path[0]: esperado [d[1]=2226.0], obtido [d[1]=2204.0] |
| slur/slur-023.mei | 2 | 95.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[2]/path[0]: esperado [d[0]=3312.0], obtido [d[0]=3217.0] |
| beam/beam-026.mei | 2 | 180.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[1]/g[3]/g[0]/g[0]/g[0]/use[0]: esperado [transform[1]=1386.0], obtido [transform[1]=1206.0] |
| slur/slur-006.mei | 2 | 180.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[5]/g[6]/g[1]/g[1]/ellipse[0]: esperado [cy[0]=4184.0], obtido [cy[0]=4004.0] |
| tuplet/tuplet-022.mei | 2 | 180.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[0]/g[0]/g[2]/g[0]/g[0]/use[0]: esperado [transform[1]=1386.0], obtido [transform[1]=1206.0] |
| dynam/dynam-010.mei | 2 | 360.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[3]/use[0]: esperado [transform[0]=2295.0], obtido [transform[0]=2205.0] |
| dir/dir-005.mei | 2 | 720.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[1]/g[2]/g[0]/g[0]/path[0]: esperado [d[1]=2105.0], obtido [d[1]=2825.0] |
| ossia/ossia-004.mei | 2 | 3340.0 | svg/svg[0]/g[0]/g[2]/g[3]/g[1]/rect[0]: esperado [x[0]=5372.0], obtido [x[0]=2032.0] |
| gracenote/gracenote-011.mei | 3 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[6]/path[0]: esperado [d[5]=1575.0], obtido [d[5]=1574.0] |
| slur/slur-015.mei | 3 | 1.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[3]/path[0]: esperado [d[3]=1843.0], obtido [d[3]=1844.0] |
| tie/tie-009.mei | 3 | 1.0 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]/path[0]: esperado [d[4]=4233.0], obtido [d[4]=4234.0] |
| dynam/dynam-006.mei | 3 | 5.0 | svg/svg[0]/g[0]/g[2]/g[1]/g[3]/text[0]: esperado [y[0]=3285.0], obtido [y[0]=3290.0] |

