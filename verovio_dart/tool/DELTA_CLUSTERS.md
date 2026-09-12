# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-11 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 45
- Divergências (nível de número): 3462
- Assinaturas distintas (classe/tag @atributo): 38
- Subárvores podadas por divergência estrutural: 0

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 18 | 472 | `1` (3 arq), `8` (1 arq), `-1` (1 arq), `-64` (1 arq), `22` (1 arq) |
| 2 | `staff/path @d` | 16 | 885 | `1` (3 arq), `-1` (2 arq), `-2` (2 arq), `8` (1 arq), `221` (1 arq) |
| 3 | `barLine/path @d` | 16 | 308 | `1` (3 arq), `-1` (2 arq), `-2` (2 arq), `-11` (1 arq), `8` (1 arq) |
| 4 | `slur/path @d` | 15 | 167 | `-1` (10 arq), `1` (8 arq), `-2` (6 arq), `-3` (2 arq), `4` (2 arq) |
| 5 | `beam/polygon @points` | 14 | 408 | `-1` (1 arq), `15` (1 arq), `-64` (1 arq), `22` (1 arq), `221` (1 arq) |
| 6 | `notehead/use @transform` | 14 | 268 | `1` (2 arq), `8` (1 arq), `-1` (1 arq), `2` (1 arq), `-64` (1 arq) |
| 7 | `clef/use @transform` | 12 | 22 | `1` (2 arq), `-64` (1 arq), `-19` (1 arq), `22` (1 arq), `8` (1 arq) |
| 8 | `ledgerLines/path @d` | 8 | 160 | `1` (2 arq), `-1` (1 arq), `221` (1 arq), `-19` (1 arq), `8` (1 arq) |
| 9 | `rest/use @transform` | 8 | 69 | `-19` (1 arq), `-64` (1 arq), `221` (1 arq), `-226` (1 arq), `224` (1 arq) |
| 10 | `dots/ellipse @cx` | 8 | 49 | `-225` (3 arq), `-198` (3 arq), `-219` (3 arq), `-519` (2 arq), `-89` (1 arq) |
| 11 | `meterSig/use @transform` | 8 | 24 | `1` (2 arq), `-64` (1 arq), `22` (1 arq), `8` (1 arq), `15` (1 arq) |
| 12 | `accid/use @transform` | 7 | 24 | `22` (1 arq), `8` (1 arq), `15` (1 arq), `-19` (1 arq), `-10` (1 arq) |
| 13 | `tupletNum/use @transform` | 7 | 14 | `-180` (3 arq), `9` (2 arq), `-1` (1 arq), `99` (1 arq) |
| 14 | `system/path @d` | 7 | 13 | `-19` (1 arq), `-64` (1 arq), `22` (1 arq), `8` (1 arq), `-1` (1 arq) |
| 15 | `grpSym/path @d` | 6 | 80 | `-19` (1 arq), `-64` (1 arq), `22` (1 arq), `-1` (1 arq), `15` (1 arq) |
| 16 | `mNum/text @y` | 6 | 11 | `8` (1 arq), `-19` (1 arq), `-64` (1 arq), `22` (1 arq), `-1` (1 arq) |
| 17 | `dots/ellipse @cy` | 5 | 32 | `-180` (3 arq), `720` (2 arq), `8` (1 arq), `221` (1 arq) |
| 18 | `label/text @y` | 5 | 8 | `8` (1 arq), `-64` (1 arq), `22` (1 arq), `-1` (1 arq), `15` (1 arq) |
| 19 | `keyAccid/use @transform` | 4 | 28 | `-1` (1 arq), `-19` (1 arq), `-11` (1 arq), `-5` (1 arq), `8` (1 arq) |
| 20 | `dir/text @y` | 4 | 5 | `1` (2 arq), `3` (1 arq), `2` (1 arq) |
| 21 | `oStaff/path @d` | 3 | 150 | `13` (2 arq), `-11` (1 arq), `-2` (1 arq), `-7` (1 arq), `-4` (1 arq) |
| 22 | `tie/path @d` | 3 | 41 | `-1` (2 arq), `15` (1 arq), `-2` (1 arq), `1` (1 arq) |
| 23 | `mRest/use @transform` | 2 | 45 | `-9` (1 arq), `-3` (1 arq), `-8` (1 arq), `-5` (1 arq), `-2` (1 arq) |
| 24 | `octave/polyline @points` | 2 | 9 | `-221` (1 arq), `65` (1 arq), `-156` (1 arq) |
| 25 | `flag/use @transform` | 2 | 8 | `-64` (1 arq), `8` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `-1` | 13 |
| `1` | 12 |
| `-2` | 9 |
| `-180` | 7 |
| `-3` | 4 |
| `-225` | 3 |
| `-219` | 3 |
| `-198` | 3 |
| `-8` | 3 |
| `-7` | 3 |
| `2` | 3 |
| `3` | 3 |
| `4` | 3 |
| `9` | 3 |
| `-519` | 2 |
| `-222` | 2 |
| `-63` | 2 |
| `-57` | 2 |
| `-20` | 2 |
| `-18` | 2 |
| `-10` | 2 |
| `-5` | 2 |
| `-4` | 2 |
| `5` | 2 |
| `13` | 2 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 9 |
| `system` | 7 |
| `slur` | 7 |
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
| layer/layer-010 | 1 |
| layer/layer-015 | 1 |
| rest/rest-004 | 1 |
| rest/rest-010 | 1 |
| section/section-001 | 1 |
| space/space-001 | 1 |
| beam/beam-026 | 2 |
| stem/stem-015 | 2 |
| tuplet/tuplet-022 | 2 |
| dynam/dynam-006 | 3 |
| chord/chord-007 | 4 |
| note/note-008 | 4 |
| cross-staff/cross-staff-005 | 5 |
| ossia/ossia-001 | 5 |
| ossia/ossia-002 | 5 |
| slur/slur-006 | 5 |
| octave/octave-001 | 6 |
| gracenote/gracenote-025 | 7 |
| beam/beam-060 | 8 |
| gracenote/gracenote-021 | 8 |
| pedal/pedal-001 | 8 |
| gracenote/gracenote-011 | 9 |
| tuplet/tuplet-014 | 9 |
| tuplet/tuplet-017 | 9 |

