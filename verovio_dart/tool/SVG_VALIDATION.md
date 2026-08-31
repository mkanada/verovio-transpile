# SVG_VALIDATION — comparação de SVG (harness da Fase 5)

Estrutural: 396/621 limpos
Numérico (eps=0.0): 62/621 limpos

Gerado em 2026-08-31 por `dart run tool/compare_svg.dart` (modo: both, epsilon: 0.0).

- Divergentes: 559
- Falhas (exceção durante renderização): 0
- Sem renderização Dart disponível (stub `renderSvgForComparison` da Fase 5): 0

## Por categoria (75 categorias)

| Categoria | Estrutural limpos | Numérico limpos | Divergentes | Falhas | Sem render | Total |
|---|---|---|---|---|---|---|
| accid | 11 | 2 | 12 | 0 | 0 | 14 |
| annot | 7 | 4 | 3 | 0 | 0 | 7 |
| app | 1 | 1 | 2 | 0 | 0 | 3 |
| arpeg | 2 | 0 | 7 | 0 | 0 | 7 |
| artic | 12 | 0 | 19 | 0 | 0 | 19 |
| barline | 5 | 4 | 6 | 0 | 0 | 10 |
| beam | 53 | 0 | 61 | 0 | 0 | 61 |
| beamspan | 0 | 0 | 6 | 0 | 0 | 6 |
| bracketspan | 0 | 0 | 1 | 0 | 0 | 1 |
| breath | 2 | 1 | 1 | 0 | 0 | 2 |
| btrem | 5 | 0 | 6 | 0 | 0 | 6 |
| caesura | 1 | 0 | 1 | 0 | 0 | 1 |
| choice | 1 | 0 | 1 | 0 | 0 | 1 |
| chord | 7 | 0 | 10 | 0 | 0 | 10 |
| clef | 3 | 1 | 6 | 0 | 0 | 7 |
| color | 4 | 1 | 3 | 0 | 0 | 4 |
| cpmark | 1 | 0 | 1 | 0 | 0 | 1 |
| cross-staff | 17 | 0 | 24 | 0 | 0 | 24 |
| custos | 0 | 0 | 1 | 0 | 0 | 1 |
| dir | 9 | 3 | 7 | 0 | 0 | 10 |
| dot | 3 | 0 | 6 | 0 | 0 | 6 |
| dynam | 9 | 0 | 10 | 0 | 0 | 10 |
| editorial | 2 | 0 | 2 | 0 | 0 | 2 |
| ending | 0 | 0 | 3 | 0 | 0 | 3 |
| expansion | 0 | 0 | 3 | 0 | 0 | 3 |
| fermata | 5 | 1 | 6 | 0 | 0 | 7 |
| figured-bass | 0 | 0 | 5 | 0 | 0 | 5 |
| fing | 2 | 0 | 2 | 0 | 0 | 2 |
| font | 0 | 0 | 2 | 0 | 0 | 2 |
| ftrem | 2 | 0 | 2 | 0 | 0 | 2 |
| gliss | 6 | 0 | 6 | 0 | 0 | 6 |
| gracenote | 12 | 1 | 26 | 0 | 0 | 27 |
| hairpin | 5 | 1 | 5 | 0 | 0 | 6 |
| harm | 3 | 0 | 5 | 0 | 0 | 5 |
| keysig | 3 | 2 | 4 | 0 | 0 | 6 |
| layer | 8 | 2 | 13 | 0 | 0 | 15 |
| ligature | 34 | 0 | 50 | 0 | 0 | 50 |
| lyric | 2 | 0 | 16 | 0 | 0 | 16 |
| mdiv | 0 | 0 | 1 | 0 | 0 | 1 |
| measure | 1 | 1 | 0 | 0 | 0 | 1 |
| mensur | 8 | 2 | 6 | 0 | 0 | 8 |
| mensural | 0 | 0 | 25 | 0 | 0 | 25 |
| metersig | 2 | 0 | 5 | 0 | 0 | 5 |
| midi | 0 | 0 | 2 | 0 | 0 | 2 |
| mnum | 0 | 0 | 1 | 0 | 0 | 1 |
| mordent | 5 | 1 | 4 | 0 | 0 | 5 |
| neume | 0 | 0 | 6 | 0 | 0 | 6 |
| note | 7 | 1 | 11 | 0 | 0 | 12 |
| octave | 4 | 0 | 4 | 0 | 0 | 4 |
| ornam | 0 | 0 | 1 | 0 | 0 | 1 |
| ossia | 0 | 0 | 4 | 0 | 0 | 4 |
| pedal | 2 | 2 | 4 | 0 | 0 | 6 |
| pgfoot | 1 | 0 | 1 | 0 | 0 | 1 |
| phrase | 1 | 0 | 1 | 0 | 0 | 1 |
| reh | 1 | 1 | 0 | 0 | 0 | 1 |
| rend | 2 | 1 | 3 | 0 | 0 | 4 |
| repeatmark | 1 | 1 | 1 | 0 | 0 | 2 |
| repeats | 8 | 0 | 8 | 0 | 0 | 8 |
| rest | 18 | 8 | 13 | 0 | 0 | 21 |
| sameas | 0 | 0 | 2 | 0 | 0 | 2 |
| score | 10 | 6 | 10 | 0 | 0 | 16 |
| section | 3 | 0 | 4 | 0 | 0 | 4 |
| slur | 21 | 0 | 25 | 0 | 0 | 25 |
| space | 1 | 0 | 2 | 0 | 0 | 2 |
| stagedir | 1 | 0 | 1 | 0 | 0 | 1 |
| stem | 11 | 3 | 13 | 0 | 0 | 16 |
| symbol | 0 | 0 | 2 | 0 | 0 | 2 |
| symboldef | 2 | 1 | 1 | 0 | 0 | 2 |
| tab | 1 | 0 | 5 | 0 | 0 | 5 |
| tempo | 2 | 0 | 4 | 0 | 0 | 4 |
| tie | 9 | 0 | 12 | 0 | 0 | 12 |
| trill | 5 | 4 | 4 | 0 | 0 | 8 |
| tuplet | 20 | 3 | 19 | 0 | 0 | 22 |
| turn | 6 | 3 | 3 | 0 | 0 | 6 |
| unison | 6 | 0 | 7 | 0 | 0 | 7 |

## Top divergências estruturais (225 arquivo(s) com divergências; até 30 listados)

| Arquivo | Divergências | Primeira divergência |
|---|---|---|
| lyric/lyric-012.mei | 623 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[3]/g[0]/g[5]/g[0]: esperado [1 filhos], obtido [2 filhos] |
| midi/005-maqam-rast-external-tuning.mei | 547 | svg/svg[0]/g[0]: esperado [15 filhos], obtido [14 filhos] |
| score/score-015.mei | 535 | svg/svg[0]/g[0]/g[2]: esperado [14 filhos], obtido [13 filhos] |
| score/score-013.mei | 378 | svg/svg[0]/g[0]/g[2]: esperado [17 filhos], obtido [16 filhos] |
| rest/rest-018.mei | 314 | svg/svg[0]/g[0]/g[3]: esperado [16 filhos], obtido [15 filhos] |
| stem/stem-009.mei | 252 | svg: esperado [4 filhos], obtido [5 filhos] |
| ossia/ossia-003.mei | 234 | svg/svg[0]/g[0]/g[2]: esperado [13 filhos], obtido [16 filhos] |
| figured-bass/figured-bass-003.mei | 226 | svg: esperado [4 filhos], obtido [5 filhos] |
| score/score-011.mei | 221 | svg/svg[0]/g[0]/g[2]/g[19]: esperado [14 filhos], obtido [15 filhos] |
| layer/layer-008.mei | 209 | svg/svg[0]/g[0]/g[2]: esperado [17 filhos], obtido [16 filhos] |
| expansion/expansion-002.mei | 197 | svg/svg[0]/g[0]/g[2]/g[10]: esperado [16 filhos], obtido [1 filhos] |
| midi/003-keys-and-accidentals-advanced.mei | 196 | svg/defs[0]/g[3]: esperado [id="E261-@doc"], obtido [id="E442-@doc"] |
| barline/barline-007.mei | 181 | svg/defs[0]: esperado [defs 16 glifos], obtido [defs 16 glifos (faltam E4A3-@doc extras E4A2-@doc)] |
| figured-bass/figured-bass-001.mei | 181 | svg: esperado [4 filhos], obtido [5 filhos] |
| barline/barline-003.mei | 180 | svg/defs[0]: esperado [defs 17 glifos], obtido [defs 17 glifos (faltam E4A3-@doc extras E4A2-@doc)] |
| layer/layer-007.mei | 171 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]: esperado [8 filhos], obtido [9 filhos] |
| ossia/ossia-002.mei | 152 | svg/svg[0]/g[0]/g[2]: esperado [7 filhos], obtido [8 filhos] |
| lyric/lyric-009.mei | 137 | svg/svg[0]/g[0]/g[2]: esperado [9 filhos], obtido [8 filhos] |
| lyric/lyric-005.mei | 118 | svg/svg[0]/g[0]/g[2]: esperado [14 filhos], obtido [10 filhos] |
| lyric/lyric-006.mei | 118 | svg/svg[0]/g[0]/g[2]: esperado [14 filhos], obtido [10 filhos] |
| ending/ending-001.mei | 109 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[3]/g[2]/g[3]/g[0]: esperado [1 filhos], obtido [2 filhos] |
| tie/tie-001.mei | 109 | svg/svg[0]/g[0]/g[2]/g[2]: esperado [3 filhos], obtido [5 filhos] |
| gracenote/gracenote-024.mei | 97 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[0]: esperado [3 filhos], obtido [5 filhos] |
| figured-bass/figured-bass-004.mei | 94 | svg: esperado [4 filhos], obtido [5 filhos] |
| expansion/expansion-003.mei | 93 | svg/svg[0]/g[0]/g[2]/g[5]: esperado [6 filhos], obtido [1 filhos] |
| ending/ending-003.mei | 92 | svg/svg[0]/g[0]/g[2]/g[4]/g[0]: esperado [7 filhos], obtido [8 filhos] |
| expansion/expansion-001.mei | 89 | svg/svg[0]/g[0]/g[2]/g[4]: esperado [6 filhos], obtido [1 filhos] |
| gracenote/gracenote-015.mei | 88 | svg/svg[0]/g[0]/g[2]/g[3]/g[0]/g[2]: esperado [1 filhos], obtido [2 filhos] |
| trill/trill-001.mei | 84 | svg/defs[0]: esperado [defs 6 glifos], obtido [defs 5 glifos (extras E59D-@doc)] |
| mensural/mensural-001.mei | 83 | svg/defs[0]: esperado [defs 26 glifos], obtido [defs 20 glifos (extras E084-@doc,E086-@doc,E088-@doc,E925-@doc)] |

## Maiores desvios numéricos (até 10 listados)

| Arquivo | Maior desvio | Divergências numéricas | Primeira divergência |
|---|---|---|---|
| harm/harm-004.mei | 177759.0 | 101 | svg: esperado [4 filhos], obtido [5 filhos] |
| figured-bass/figured-bass-004.mei | 64208.0 | 74 | svg: esperado [4 filhos], obtido [5 filhos] |
| harm/harm-003.mei | 59159.0 | 156 | svg: esperado [4 filhos], obtido [5 filhos] |
| lyric/lyric-008.mei | 59159.0 | 162 | svg: esperado [4 filhos], obtido [5 filhos] |
| figured-bass/figured-bass-001.mei | 31581.0 | 250 | svg: esperado [4 filhos], obtido [5 filhos] |
| figured-bass/figured-bass-002.mei | 31039.0 | 64 | svg: esperado [4 filhos], obtido [5 filhos] |
| stem/stem-009.mei | 30634.0 | 224 | svg: esperado [4 filhos], obtido [5 filhos] |
| figured-bass/figured-bass-003.mei | 30531.0 | 264 | svg: esperado [4 filhos], obtido [5 filhos] |
| neume/neume-001.mei | 26879.0 | 73 | svg: esperado [width[0]=2100.0], obtido [width[0]=7758.0] |
| neume/neume-005.mei | 19309.0 | 14 | svg/svg[0]/g[0]: esperado [7 filhos], obtido [9 filhos] |

