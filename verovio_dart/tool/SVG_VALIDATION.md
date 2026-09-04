# SVG_VALIDATION — comparação de SVG (harness da Fase 5)

Estrutural: 610/621 limpos
Numérico (eps=0.0): 112/621 limpos

Gerado em 2026-09-04 por `dart run tool/compare_svg.dart` (modo: both, epsilon: 0.0).

- Divergentes: 509
- Falhas (exceção durante renderização): 0
- Sem renderização Dart disponível (stub `renderSvgForComparison` da Fase 5): 0

## Por categoria (75 categorias)

| Categoria | Estrutural limpos | Numérico limpos | Divergentes | Falhas | Sem render | Total |
|---|---|---|---|---|---|---|
| accid | 14 | 2 | 12 | 0 | 0 | 14 |
| annot | 7 | 4 | 3 | 0 | 0 | 7 |
| app | 3 | 2 | 1 | 0 | 0 | 3 |
| arpeg | 6 | 0 | 7 | 0 | 0 | 7 |
| artic | 19 | 0 | 19 | 0 | 0 | 19 |
| barline | 9 | 5 | 5 | 0 | 0 | 10 |
| beam | 61 | 0 | 61 | 0 | 0 | 61 |
| beamspan | 6 | 0 | 6 | 0 | 0 | 6 |
| bracketspan | 1 | 0 | 1 | 0 | 0 | 1 |
| breath | 2 | 1 | 1 | 0 | 0 | 2 |
| btrem | 6 | 1 | 5 | 0 | 0 | 6 |
| caesura | 1 | 0 | 1 | 0 | 0 | 1 |
| choice | 1 | 0 | 1 | 0 | 0 | 1 |
| chord | 9 | 0 | 10 | 0 | 0 | 10 |
| clef | 7 | 2 | 5 | 0 | 0 | 7 |
| color | 4 | 1 | 3 | 0 | 0 | 4 |
| cpmark | 1 | 0 | 1 | 0 | 0 | 1 |
| cross-staff | 21 | 0 | 24 | 0 | 0 | 24 |
| custos | 1 | 0 | 1 | 0 | 0 | 1 |
| dir | 10 | 4 | 6 | 0 | 0 | 10 |
| dot | 6 | 0 | 6 | 0 | 0 | 6 |
| dynam | 10 | 0 | 10 | 0 | 0 | 10 |
| editorial | 2 | 0 | 2 | 0 | 0 | 2 |
| ending | 3 | 0 | 3 | 0 | 0 | 3 |
| expansion | 3 | 0 | 3 | 0 | 0 | 3 |
| fermata | 7 | 2 | 5 | 0 | 0 | 7 |
| figured-bass | 5 | 2 | 3 | 0 | 0 | 5 |
| fing | 2 | 0 | 2 | 0 | 0 | 2 |
| font | 2 | 0 | 2 | 0 | 0 | 2 |
| ftrem | 2 | 0 | 2 | 0 | 0 | 2 |
| gliss | 6 | 0 | 6 | 0 | 0 | 6 |
| gracenote | 27 | 1 | 26 | 0 | 0 | 27 |
| hairpin | 6 | 1 | 5 | 0 | 0 | 6 |
| harm | 5 | 1 | 4 | 0 | 0 | 5 |
| keysig | 6 | 4 | 2 | 0 | 0 | 6 |
| layer | 14 | 3 | 12 | 0 | 0 | 15 |
| ligature | 50 | 0 | 50 | 0 | 0 | 50 |
| lyric | 16 | 3 | 13 | 0 | 0 | 16 |
| mdiv | 1 | 0 | 1 | 0 | 0 | 1 |
| measure | 1 | 1 | 0 | 0 | 0 | 1 |
| mensur | 8 | 2 | 6 | 0 | 0 | 8 |
| mensural | 25 | 12 | 13 | 0 | 0 | 25 |
| metersig | 5 | 0 | 5 | 0 | 0 | 5 |
| midi | 1 | 0 | 2 | 0 | 0 | 2 |
| mnum | 1 | 1 | 0 | 0 | 0 | 1 |
| mordent | 5 | 1 | 4 | 0 | 0 | 5 |
| neume | 6 | 0 | 6 | 0 | 0 | 6 |
| note | 12 | 5 | 7 | 0 | 0 | 12 |
| octave | 4 | 0 | 4 | 0 | 0 | 4 |
| ornam | 1 | 1 | 0 | 0 | 0 | 1 |
| ossia | 4 | 0 | 4 | 0 | 0 | 4 |
| pedal | 6 | 4 | 2 | 0 | 0 | 6 |
| pgfoot | 1 | 0 | 1 | 0 | 0 | 1 |
| phrase | 1 | 0 | 1 | 0 | 0 | 1 |
| reh | 1 | 1 | 0 | 0 | 0 | 1 |
| rend | 4 | 2 | 2 | 0 | 0 | 4 |
| repeatmark | 2 | 2 | 0 | 0 | 0 | 2 |
| repeats | 8 | 0 | 8 | 0 | 0 | 8 |
| rest | 21 | 9 | 12 | 0 | 0 | 21 |
| sameas | 2 | 0 | 2 | 0 | 0 | 2 |
| score | 16 | 9 | 7 | 0 | 0 | 16 |
| section | 4 | 1 | 3 | 0 | 0 | 4 |
| slur | 25 | 0 | 25 | 0 | 0 | 25 |
| space | 2 | 1 | 1 | 0 | 0 | 2 |
| stagedir | 1 | 0 | 1 | 0 | 0 | 1 |
| stem | 14 | 3 | 13 | 0 | 0 | 16 |
| symbol | 2 | 1 | 1 | 0 | 0 | 2 |
| symboldef | 2 | 2 | 0 | 0 | 0 | 2 |
| tab | 4 | 0 | 5 | 0 | 0 | 5 |
| tempo | 4 | 0 | 4 | 0 | 0 | 4 |
| tie | 12 | 0 | 12 | 0 | 0 | 12 |
| trill | 8 | 4 | 4 | 0 | 0 | 8 |
| tuplet | 22 | 5 | 17 | 0 | 0 | 22 |
| turn | 6 | 3 | 3 | 0 | 0 | 6 |
| unison | 7 | 3 | 4 | 0 | 0 | 7 |

## Top divergências estruturais (11 arquivo(s) com divergências; até 30 listados)

| Arquivo | Divergências | Primeira divergência |
|---|---|---|
| midi/005-maqam-rast-external-tuning.mei | 14 | svg/svg[0]/g[0]: esperado [14 filhos], obtido [15 filhos] |
| tab/tab-004.mei | 14 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]: esperado [16 filhos], obtido [13 filhos] |
| stem/stem-014.mei | 9 | svg/svg[0]/g[0]/g[2]/g[6]/g[0]/g[3]/g[1]: esperado [2 filhos], obtido [4 filhos] |
| stem/stem-016.mei | 8 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[3]/g[2]: esperado [2 filhos], obtido [3 filhos] |
| chord/chord-009.mei | 6 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[3]/g[1]/g[2]: esperado [2 filhos], obtido [0 filhos] |
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
| chord/chord-008.mei | 9253.0 | 166 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[2]/g[0]/polygon[0]: esperado [points[0]=837.0], obtido [points[0]=999.0] |
| mensural/mensural-020.mei | 7803.0 | 96 | svg/svg[0]/g[0]/g[2]/g[6]/g[2]/g[0]/use[0]: esperado [transform[0]=1262.0], obtido [transform[0]=1371.0] |
| mensural/mensural-019.mei | 7597.0 | 93 | svg/svg[0]/g[0]/g[2]/g[6]/g[2]/g[0]/use[0]: esperado [transform[0]=1262.0], obtido [transform[0]=1371.0] |
| arpeg/arpeg-004.mei | 6573.0 | 158 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/path[0]: esperado [d[2]=6303.0], obtido [d[2]=4738.0] |
| mensural/mensural-016.mei | 6405.0 | 168 | svg/svg[0]/g[0]/g[2]/g[9]/g[2]/g[0]/use[0]: esperado [transform[0]=2573.0], obtido [transform[0]=2839.0] |
| ossia/ossia-003.mei | 5337.0 | 640 | svg/svg[0]/g[0]/g[2]/path[0]: esperado [d[3]=10268.0], obtido [d[3]=10155.0] |
| mensural/mensural-012.mei | 4670.0 | 151 | svg/svg[0]/g[0]/g[2]/g[5]/path[0]: esperado [d[2]=9146.0], obtido [d[2]=9269.0] |

