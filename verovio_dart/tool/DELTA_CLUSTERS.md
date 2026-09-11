# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-11 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 53
- Divergências (nível de número): 4193
- Assinaturas distintas (classe/tag @atributo): 38
- Subárvores podadas por divergência estrutural: 0

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `slur/path @d` | 22 | 257 | `1` (17 arq), `-1` (13 arq), `2` (9 arq), `-2` (7 arq), `-3` (5 arq) |
| 2 | `stem/path @d` | 21 | 518 | `1` (3 arq), `162` (2 arq), `8` (1 arq), `-1` (1 arq), `1071` (1 arq) |
| 3 | `staff/path @d` | 17 | 1005 | `1` (3 arq), `-1` (2 arq), `-2` (2 arq), `8` (1 arq), `-22` (1 arq) |
| 4 | `barLine/path @d` | 17 | 334 | `1` (3 arq), `-1` (2 arq), `-2` (2 arq), `-11` (1 arq), `8` (1 arq) |
| 5 | `notehead/use @transform` | 17 | 304 | `1` (2 arq), `162` (2 arq), `8` (1 arq), `1071` (1 arq), `-1` (1 arq) |
| 6 | `beam/polygon @points` | 15 | 440 | `-1` (1 arq), `14` (1 arq), `-64` (1 arq), `21` (1 arq), `1071` (1 arq) |
| 7 | `clef/use @transform` | 14 | 26 | `1` (2 arq), `-64` (1 arq), `-22` (1 arq), `-19` (1 arq), `21` (1 arq) |
| 8 | `dots/ellipse @cy` | 11 | 84 | `360` (4 arq), `540` (3 arq), `180` (2 arq), `720` (2 arq), `1071` (1 arq) |
| 9 | `ledgerLines/path @d` | 9 | 222 | `1` (2 arq), `1071` (1 arq), `-1` (1 arq), `221` (1 arq), `-19` (1 arq) |
| 10 | `meterSig/use @transform` | 9 | 27 | `1` (2 arq), `-64` (1 arq), `21` (1 arq), `8` (1 arq), `14` (1 arq) |
| 11 | `rest/use @transform` | 8 | 195 | `-22` (1 arq), `-64` (1 arq), `-19` (1 arq), `221` (1 arq), `-226` (1 arq) |
| 12 | `dots/ellipse @cx` | 8 | 51 | `-225` (3 arq), `-198` (3 arq), `-219` (3 arq), `-519` (2 arq), `162` (2 arq) |
| 13 | `accid/use @transform` | 8 | 29 | `1071` (1 arq), `21` (1 arq), `8` (1 arq), `14` (1 arq), `-19` (1 arq) |
| 14 | `system/path @d` | 8 | 14 | `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `8` (1 arq), `-1` (1 arq) |
| 15 | `grpSym/path @d` | 7 | 90 | `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `-1` (1 arq), `14` (1 arq) |
| 16 | `tupletNum/use @transform` | 7 | 14 | `-180` (3 arq), `9` (2 arq), `-1` (1 arq), `99` (1 arq) |
| 17 | `mNum/text @y` | 6 | 11 | `8` (1 arq), `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `-1` (1 arq) |
| 18 | `keyAccid/use @transform` | 5 | 32 | `-1` (1 arq), `-19` (1 arq), `-11` (1 arq), `-5` (1 arq), `1071` (1 arq) |
| 19 | `label/text @y` | 5 | 8 | `8` (1 arq), `-64` (1 arq), `21` (1 arq), `-1` (1 arq), `14` (1 arq) |
| 20 | `tie/path @d` | 4 | 153 | `-1` (2 arq), `1071` (1 arq), `1004` (1 arq), `-720` (1 arq), `-729` (1 arq) |
| 21 | `dir/text @y` | 4 | 5 | `1` (2 arq), `3` (1 arq), `2` (1 arq) |
| 22 | `oStaff/path @d` | 3 | 150 | `13` (2 arq), `-11` (1 arq), `-2` (1 arq), `-7` (1 arq), `-4` (1 arq) |
| 23 | `mRest/use @transform` | 2 | 45 | `-9` (1 arq), `-3` (1 arq), `-8` (1 arq), `-5` (1 arq), `-2` (1 arq) |
| 24 | `octave/polyline @points` | 2 | 9 | `-221` (1 arq), `65` (1 arq), `-156` (1 arq) |
| 25 | `flag/use @transform` | 2 | 8 | `-64` (1 arq), `8` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 20 |
| `-1` | 16 |
| `-2` | 10 |
| `2` | 10 |
| `-3` | 6 |
| `3` | 6 |
| `-180` | 5 |
| `-5` | 4 |
| `360` | 4 |
| `-225` | 3 |
| `-219` | 3 |
| `-198` | 3 |
| `-6` | 3 |
| `5` | 3 |
| `9` | 3 |
| `180` | 3 |
| `540` | 3 |
| `-519` | 2 |
| `-63` | 2 |
| `-56` | 2 |
| `-20` | 2 |
| `-12` | 2 |
| `-9` | 2 |
| `-7` | 2 |
| `-4` | 2 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `slur` | 15 |
| `staff` | 9 |
| `system` | 7 |
| `tupletNum` | 6 |
| `dots` | 5 |
| `beam` | 3 |
| `stem` | 2 |
| `oStaff` | 2 |
| `notehead` | 1 |
| `dynam` | 1 |
| `octave` | 1 |
| `tie` | 1 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| rest/rest-010 | 1 |
| section/section-001 | 1 |
| space/space-001 | 1 |
| beam/beam-026 | 2 |
| layer/layer-015 | 2 |
| tuplet/tuplet-022 | 2 |
| dynam/dynam-006 | 3 |
| chord/chord-007 | 4 |
| note/note-008 | 4 |
| stem/stem-015 | 4 |
| tuplet/tuplet-001 | 4 |
| ossia/ossia-001 | 5 |
| ossia/ossia-002 | 5 |
| slur/slur-006 | 5 |
| tie/tie-010 | 5 |
| gracenote/gracenote-022 | 6 |
| layer/layer-010 | 6 |
| octave/octave-001 | 6 |
| rest/rest-004 | 6 |
| cross-staff/cross-staff-005 | 7 |
| gracenote/gracenote-025 | 7 |
| slur/slur-014 | 7 |
| beam/beam-060 | 8 |
| beamspan/beamspan-004 | 8 |

