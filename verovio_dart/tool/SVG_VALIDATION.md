# SVG_VALIDATION — comparação de SVG (harness da Fase 5)

Estrutural: 112/623 limpos
Numérico: não executado (modo estrutural)

Gerado em 2026-08-29 por `dart run tool/compare_svg.dart` (modo: structural, epsilon: 0.0).

- Divergentes: 506
- Falhas (exceção durante renderização): 3
- Sem renderização Dart disponível (stub `renderSvgForComparison` da Fase 5): 0
- Pulados por não serem UTF-8: 2 (dir/dir-011.mei, dir/dir-012.mei)

## Por categoria (75 categorias)

| Categoria | Estrutural limpos | Numérico limpos | Divergentes | Falhas | Sem render | Pulados | Total |
|---|---|---|---|---|---|---|---|
| accid | 9 | 0 | 5 | 0 | 0 | 0 | 14 |
| annot | 5 | 0 | 2 | 0 | 0 | 0 | 7 |
| app | 0 | 0 | 3 | 0 | 0 | 0 | 3 |
| arpeg | 0 | 0 | 7 | 0 | 0 | 0 | 7 |
| artic | 4 | 0 | 15 | 0 | 0 | 0 | 19 |
| barline | 1 | 0 | 9 | 0 | 0 | 0 | 10 |
| beam | 37 | 0 | 24 | 0 | 0 | 0 | 61 |
| beamspan | 0 | 0 | 6 | 0 | 0 | 0 | 6 |
| bracketspan | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| breath | 2 | 0 | 0 | 0 | 0 | 0 | 2 |
| btrem | 1 | 0 | 5 | 0 | 0 | 0 | 6 |
| caesura | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| choice | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| chord | 3 | 0 | 7 | 0 | 0 | 0 | 10 |
| clef | 1 | 0 | 6 | 0 | 0 | 0 | 7 |
| color | 1 | 0 | 2 | 1 | 0 | 0 | 4 |
| cpmark | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| cross-staff | 3 | 0 | 21 | 0 | 0 | 0 | 24 |
| custos | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| dir | 0 | 0 | 10 | 0 | 0 | 2 | 12 |
| dot | 0 | 0 | 6 | 0 | 0 | 0 | 6 |
| dynam | 0 | 0 | 10 | 0 | 0 | 0 | 10 |
| editorial | 1 | 0 | 1 | 0 | 0 | 0 | 2 |
| ending | 0 | 0 | 3 | 0 | 0 | 0 | 3 |
| expansion | 0 | 0 | 3 | 0 | 0 | 0 | 3 |
| fermata | 3 | 0 | 4 | 0 | 0 | 0 | 7 |
| figured-bass | 0 | 0 | 5 | 0 | 0 | 0 | 5 |
| fing | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| font | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| ftrem | 0 | 0 | 1 | 1 | 0 | 0 | 2 |
| gliss | 0 | 0 | 6 | 0 | 0 | 0 | 6 |
| gracenote | 2 | 0 | 25 | 0 | 0 | 0 | 27 |
| hairpin | 0 | 0 | 6 | 0 | 0 | 0 | 6 |
| harm | 0 | 0 | 5 | 0 | 0 | 0 | 5 |
| keysig | 2 | 0 | 4 | 0 | 0 | 0 | 6 |
| layer | 1 | 0 | 14 | 0 | 0 | 0 | 15 |
| ligature | 0 | 0 | 50 | 0 | 0 | 0 | 50 |
| lyric | 0 | 0 | 16 | 0 | 0 | 0 | 16 |
| mdiv | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| measure | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| mensur | 8 | 0 | 0 | 0 | 0 | 0 | 8 |
| mensural | 0 | 0 | 25 | 0 | 0 | 0 | 25 |
| metersig | 2 | 0 | 3 | 0 | 0 | 0 | 5 |
| midi | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| mnum | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| mordent | 2 | 0 | 3 | 0 | 0 | 0 | 5 |
| neume | 0 | 0 | 6 | 0 | 0 | 0 | 6 |
| note | 3 | 0 | 9 | 0 | 0 | 0 | 12 |
| octave | 0 | 0 | 4 | 0 | 0 | 0 | 4 |
| ornam | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| ossia | 0 | 0 | 4 | 0 | 0 | 0 | 4 |
| pedal | 0 | 0 | 6 | 0 | 0 | 0 | 6 |
| pgfoot | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| phrase | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| reh | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| rend | 0 | 0 | 4 | 0 | 0 | 0 | 4 |
| repeatmark | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| repeats | 2 | 0 | 6 | 0 | 0 | 0 | 8 |
| rest | 2 | 0 | 19 | 0 | 0 | 0 | 21 |
| sameas | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| score | 6 | 0 | 10 | 0 | 0 | 0 | 16 |
| section | 0 | 0 | 4 | 0 | 0 | 0 | 4 |
| slur | 0 | 0 | 25 | 0 | 0 | 0 | 25 |
| space | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| stagedir | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| stem | 6 | 0 | 10 | 0 | 0 | 0 | 16 |
| symbol | 0 | 0 | 1 | 1 | 0 | 0 | 2 |
| symboldef | 0 | 0 | 2 | 0 | 0 | 0 | 2 |
| tab | 0 | 0 | 5 | 0 | 0 | 0 | 5 |
| tempo | 0 | 0 | 4 | 0 | 0 | 0 | 4 |
| tie | 1 | 0 | 11 | 0 | 0 | 0 | 12 |
| trill | 0 | 0 | 8 | 0 | 0 | 0 | 8 |
| tuplet | 0 | 0 | 22 | 0 | 0 | 0 | 22 |
| turn | 2 | 0 | 4 | 0 | 0 | 0 | 6 |
| unison | 2 | 0 | 5 | 0 | 0 | 0 | 7 |

## Falhas (exceções durante renderização)

| Arquivo | Tipo da exceção | Detalhe |
|---|---|---|
| color/color-001.mei | _TypeError | Null check operator used on a null value |
| ftrem/ftrem-002.mei | _TypeError | Null check operator used on a null value |
| symbol/symbol-002.mei | _TypeError | Null check operator used on a null value |

## Top divergências estruturais (506 arquivo(s) com divergências; até 30 listados)

| Arquivo | Divergências | Primeira divergência |
|---|---|---|
| lyric/lyric-005.mei | 489 | svg/defs[0]: esperado [defs 14 glifos], obtido [defs 15 glifos (faltam E520-@doc)] |
| lyric/lyric-006.mei | 489 | svg/defs[0]: esperado [defs 14 glifos], obtido [defs 15 glifos (faltam E520-@doc)] |
| score/score-016.mei | 397 | svg/svg[0]/g[0]/g[2]/g[18]/g[0]: esperado [4 filhos], obtido [1 filhos] |
| lyric/lyric-010.mei | 395 | svg: esperado [4 filhos], obtido [5 filhos] |
| lyric/lyric-012.mei | 371 | svg/svg[0]/g[0]: esperado [7 filhos], obtido [9 filhos] |
| score/score-011.mei | 274 | svg/svg[0]/g[0]/g[2]/g[18]: esperado [15 filhos], obtido [14 filhos] |
| tuplet/tuplet-012.mei | 240 | svg/svg[0]/g[0]/g[2]/g[2]: esperado [4 filhos], obtido [5 filhos] |
| layer/layer-008.mei | 221 | svg/svg[0]/g[0]/g[2]: esperado [17 filhos], obtido [16 filhos] |
| dot/dot-001.mei | 220 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[2]/g[0]/g[1]: esperado [0 filhos], obtido [1 filhos] |
| cross-staff/cross-staff-020.mei | 195 | svg/svg[0]/g[0]/g[2]/g[2]: esperado [10 filhos], obtido [11 filhos] |
| barline/barline-007.mei | 192 | svg/defs[0]: esperado [defs 16 glifos], obtido [defs 16 glifos (faltam E4A3-@doc extras E4A2-@doc)] |
| score/score-014.mei | 192 | svg/svg[0]/g[0]: esperado [7 filhos], obtido [6 filhos] |
| layer/layer-012.mei | 184 | svg/svg[0]/g[0]/g[2]/g[2]: esperado [9 filhos], obtido [10 filhos] |
| ossia/ossia-003.mei | 182 | svg/svg[0]/g[0]: esperado [7 filhos], obtido [8 filhos] |
| figured-bass/figured-bass-001.mei | 172 | svg: esperado [4 filhos], obtido [5 filhos] |
| layer/layer-007.mei | 171 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]: esperado [8 filhos], obtido [9 filhos] |
| lyric/lyric-009.mei | 167 | svg/svg[0]/g[0]: esperado [7 filhos], obtido [8 filhos] |
| barline/barline-003.mei | 166 | svg/defs[0]: esperado [defs 17 glifos], obtido [defs 17 glifos (faltam E4A3-@doc extras E4A2-@doc)] |
| harm/harm-003.mei | 166 | svg: esperado [4 filhos], obtido [5 filhos] |
| stem/stem-009.mei | 165 | svg: esperado [4 filhos], obtido [5 filhos] |
| harm/harm-005.mei | 163 | svg/svg[0]/g[0]/g[2]/g[2]/g[2]: esperado [0 filhos], obtido [1 filhos] |
| fing/fing-002.mei | 162 | svg/defs[0]: esperado [defs 11 glifos], obtido [defs 10 glifos (extras E4A1-@doc)] |
| barline/barline-009.mei | 161 | svg/svg[0]/g[0]/g[2]/g[3]/g[5]: esperado [4 filhos], obtido [6 filhos] |
| lyric/lyric-011.mei | 157 | svg/svg[0]/g[0]/g[2]/g[1]/g[0]/g[3]/g[0]/g[0]/g[1]: esperado [0 filhos], obtido [1 filhos] |
| lyric/lyric-008.mei | 153 | svg: esperado [4 filhos], obtido [5 filhos] |
| score/score-002.mei | 151 | svg/svg[0]/g[0]: esperado [7 filhos], obtido [8 filhos] |
| cross-staff/cross-staff-021.mei | 150 | svg/svg[0]/g[0]/g[2]/g[4]: esperado [4 filhos], obtido [3 filhos] |
| unison/unison-005.mei | 142 | svg/svg[0]/g[0]/g[2]/g[2]: esperado [3 filhos], obtido [4 filhos] |
| harm/harm-001.mei | 135 | svg/svg[0]/g[0]/g[2]/g[2]/g[0]/g[3]/g[1]/g[1]: esperado [0 filhos], obtido [1 filhos] |
| harm/harm-002.mei | 134 | svg/svg[0]/g[0]: esperado [7 filhos], obtido [8 filhos] |

