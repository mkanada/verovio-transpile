# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-11 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 79
- Divergências (nível de número): 4808
- Assinaturas distintas (classe/tag @atributo): 55
- Subárvores podadas por divergência estrutural: 0

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 25 | 568 | `1` (3 arq), `162` (2 arq), `8` (1 arq), `-1` (1 arq), `1071` (1 arq) |
| 2 | `slur/path @d` | 23 | 268 | `1` (17 arq), `-1` (13 arq), `2` (9 arq), `-2` (7 arq), `-3` (5 arq) |
| 3 | `staff/path @d` | 19 | 1090 | `1` (3 arq), `-1` (2 arq), `-2` (2 arq), `-78` (2 arq), `8` (1 arq) |
| 4 | `barLine/path @d` | 18 | 336 | `1` (3 arq), `-1` (2 arq), `-2` (2 arq), `-78` (2 arq), `-11` (1 arq) |
| 5 | `notehead/use @transform` | 18 | 307 | `1` (2 arq), `162` (2 arq), `8` (1 arq), `1071` (1 arq), `-1` (1 arq) |
| 6 | `beam/polygon @points` | 16 | 552 | `360` (1 arq), `-1` (1 arq), `14` (1 arq), `-64` (1 arq), `21` (1 arq) |
| 7 | `clef/use @transform` | 15 | 30 | `1` (2 arq), `-64` (1 arq), `-22` (1 arq), `-19` (1 arq), `21` (1 arq) |
| 8 | `dots/ellipse @cy` | 11 | 84 | `360` (4 arq), `540` (3 arq), `180` (2 arq), `720` (2 arq), `1071` (1 arq) |
| 9 | `ledgerLines/path @d` | 9 | 222 | `1` (2 arq), `1071` (1 arq), `-1` (1 arq), `221` (1 arq), `-19` (1 arq) |
| 10 | `meterSig/use @transform` | 9 | 27 | `1` (2 arq), `-64` (1 arq), `21` (1 arq), `8` (1 arq), `14` (1 arq) |
| 11 | `rest/use @transform` | 8 | 195 | `-22` (1 arq), `-64` (1 arq), `-19` (1 arq), `221` (1 arq), `-226` (1 arq) |
| 12 | `dots/ellipse @cx` | 8 | 51 | `-225` (3 arq), `-198` (3 arq), `-219` (3 arq), `-519` (2 arq), `162` (2 arq) |
| 13 | `accid/use @transform` | 8 | 29 | `1071` (1 arq), `21` (1 arq), `8` (1 arq), `14` (1 arq), `-19` (1 arq) |
| 14 | `system/path @d` | 8 | 14 | `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `8` (1 arq), `-1` (1 arq) |
| 15 | `grpSym/path @d` | 7 | 90 | `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `-1` (1 arq), `14` (1 arq) |
| 16 | `tupletNum/use @transform` | 7 | 14 | `-180` (3 arq), `9` (2 arq), `-1` (1 arq), `99` (1 arq) |
| 17 | `syl/text @y` | 6 | 149 | `-400` (5 arq), `8` (1 arq) |
| 18 | `mNum/text @y` | 6 | 11 | `8` (1 arq), `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `-1` (1 arq) |
| 19 | `tie/path @d` | 5 | 160 | `-1` (2 arq), `1071` (1 arq), `1004` (1 arq), `-720` (1 arq), `-729` (1 arq) |
| 20 | `voltaBracket/path @d` | 5 | 54 | `189` (3 arq), `54` (1 arq), `99` (1 arq), `27` (1 arq) |
| 21 | `keyAccid/use @transform` | 5 | 32 | `-1` (1 arq), `-19` (1 arq), `-11` (1 arq), `-5` (1 arq), `1071` (1 arq) |
| 22 | `voltaBracket/text @y` | 5 | 9 | `189` (3 arq), `54` (1 arq), `99` (1 arq), `27` (1 arq) |
| 23 | `label/text @y` | 5 | 8 | `8` (1 arq), `-64` (1 arq), `21` (1 arq), `-1` (1 arq), `14` (1 arq) |
| 24 | `dir/text @y` | 5 | 6 | `1` (2 arq), `3` (1 arq), `2` (1 arq), `549` (1 arq) |
| 25 | `oStaff/path @d` | 3 | 150 | `13` (2 arq), `-11` (1 arq), `-2` (1 arq), `-7` (1 arq), `-4` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 20 |
| `-1` | 16 |
| `-2` | 10 |
| `2` | 10 |
| `-180` | 8 |
| `-3` | 7 |
| `3` | 6 |
| `360` | 6 |
| `-400` | 5 |
| `-5` | 4 |
| `180` | 4 |
| `-225` | 3 |
| `-219` | 3 |
| `-198` | 3 |
| `-90` | 3 |
| `-14` | 3 |
| `-6` | 3 |
| `-4` | 3 |
| `5` | 3 |
| `9` | 3 |
| `16` | 3 |
| `189` | 3 |
| `540` | 3 |
| `720` | 3 |
| `-519` | 2 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `slur` | 15 |
| `staff` | 11 |
| `system` | 7 |
| `tupletNum` | 6 |
| `stem` | 5 |
| `voltaBracket` | 5 |
| `dots` | 5 |
| `syl` | 5 |
| `beam` | 3 |
| `dynam` | 2 |
| `oStaff` | 2 |
| `tabDurSym` | 2 |
| `tie` | 2 |
| `arpeg` | 1 |
| `breath` | 1 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| rest/rest-010 | 1 |
| section/section-001 | 1 |
| space/space-001 | 1 |
| tab/tab-001 | 1 |
| beam/beam-026 | 2 |
| breath/breath-002 | 2 |
| cross-staff/cross-staff-001 | 2 |
| layer/layer-015 | 2 |
| ossia/ossia-004 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| dir/dir-005 | 3 |
| dynam/dynam-006 | 3 |
| dynam/dynam-010 | 3 |
| chord/chord-007 | 4 |
| note/note-008 | 4 |
| stem/stem-015 | 4 |
| tuplet/tuplet-001 | 4 |
| neume/neume-002 | 5 |
| neume/neume-004 | 5 |
| neume/neume-006 | 5 |
| ossia/ossia-001 | 5 |
| ossia/ossia-002 | 5 |
| slur/slur-006 | 5 |

