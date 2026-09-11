# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-11 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 88
- Divergências (nível de número): 7646
- Assinaturas distintas (classe/tag @atributo): 66
- Subárvores podadas por divergência estrutural: 0

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 33 | 1002 | `1` (3 arq), `8` (2 arq), `-1` (2 arq), `2` (2 arq), `157` (2 arq) |
| 2 | `staff/path @d` | 32 | 1633 | `1` (4 arq), `2` (2 arq), `-1` (2 arq), `-2` (2 arq), `-78` (2 arq) |
| 3 | `barLine/path @d` | 31 | 495 | `1` (4 arq), `-1` (2 arq), `-2` (2 arq), `2` (2 arq), `-10` (2 arq) |
| 4 | `notehead/use @transform` | 28 | 505 | `2` (2 arq), `1` (2 arq), `-106` (2 arq), `162` (2 arq), `8` (1 arq) |
| 5 | `slur/path @d` | 25 | 360 | `1` (17 arq), `-1` (13 arq), `2` (10 arq), `-2` (7 arq), `3` (5 arq) |
| 6 | `beam/polygon @points` | 21 | 1208 | `550` (2 arq), `472` (2 arq), `628` (2 arq), `108` (2 arq), `314` (2 arq) |
| 7 | `accid/use @transform` | 17 | 59 | `101` (3 arq), `-312` (1 arq), `1071` (1 arq), `-141` (1 arq), `21` (1 arq) |
| 8 | `clef/use @transform` | 17 | 39 | `1` (2 arq), `-64` (1 arq), `-22` (1 arq), `2210` (1 arq), `-19` (1 arq) |
| 9 | `ledgerLines/path @d` | 16 | 392 | `1` (2 arq), `1071` (1 arq), `-141` (1 arq), `-1` (1 arq), `221` (1 arq) |
| 10 | `dots/ellipse @cy` | 13 | 88 | `360` (4 arq), `-180` (4 arq), `540` (3 arq), `180` (2 arq), `720` (2 arq) |
| 11 | `rest/use @transform` | 11 | 200 | `2` (2 arq), `-22` (1 arq), `-19` (1 arq), `-64` (1 arq), `221` (1 arq) |
| 12 | `meterSig/use @transform` | 10 | 39 | `1` (2 arq), `2626` (1 arq), `-64` (1 arq), `21` (1 arq), `8` (1 arq) |
| 13 | `system/path @d` | 9 | 17 | `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `8` (1 arq), `-1` (1 arq) |
| 14 | `dots/ellipse @cx` | 8 | 53 | `-198` (3 arq), `-219` (3 arq), `-225` (2 arq), `-519` (2 arq), `162` (2 arq) |
| 15 | `tupletNum/use @transform` | 8 | 18 | `-180` (3 arq), `9` (2 arq), `-1` (1 arq), `123` (1 arq), `-138` (1 arq) |
| 16 | `grpSym/path @d` | 7 | 90 | `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `-1` (1 arq), `14` (1 arq) |
| 17 | `mNum/text @y` | 7 | 12 | `8` (1 arq), `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `-1` (1 arq) |
| 18 | `syl/text @y` | 6 | 149 | `-400` (5 arq), `8` (1 arq) |
| 19 | `label/text @y` | 6 | 9 | `8` (1 arq), `-64` (1 arq), `21` (1 arq), `-1` (1 arq), `14` (1 arq) |
| 20 | `tie/path @d` | 5 | 160 | `-1` (2 arq), `1071` (1 arq), `1004` (1 arq), `-720` (1 arq), `-729` (1 arq) |
| 21 | `voltaBracket/path @d` | 5 | 54 | `189` (3 arq), `54` (1 arq), `99` (1 arq), `27` (1 arq) |
| 22 | `keyAccid/use @transform` | 5 | 32 | `-1` (1 arq), `-19` (1 arq), `-11` (1 arq), `-5` (1 arq), `1071` (1 arq) |
| 23 | `flag/use @transform` | 5 | 15 | `-64` (1 arq), `8` (1 arq), `231` (1 arq), `157` (1 arq), `90` (1 arq) |
| 24 | `voltaBracket/text @y` | 5 | 9 | `189` (3 arq), `54` (1 arq), `99` (1 arq), `27` (1 arq) |
| 25 | `fermata/use @transform` | 5 | 7 | `1` (2 arq), `-139` (1 arq), `418` (1 arq), `-69` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 21 |
| `-1` | 17 |
| `-180` | 12 |
| `-2` | 12 |
| `2` | 12 |
| `-3` | 8 |
| `3` | 7 |
| `-400` | 5 |
| `-5` | 5 |
| `360` | 5 |
| `-4` | 4 |
| `5` | 4 |
| `9` | 4 |
| `180` | 4 |
| `-219` | 3 |
| `-198` | 3 |
| `-90` | 3 |
| `-56` | 3 |
| `-55` | 3 |
| `-54` | 3 |
| `-14` | 3 |
| `-12` | 3 |
| `-6` | 3 |
| `13` | 3 |
| `16` | 3 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 20 |
| `slur` | 12 |
| `system` | 8 |
| `tupletNum` | 6 |
| `dots` | 6 |
| `voltaBracket` | 5 |
| `syl` | 5 |
| `stem` | 4 |
| `accid` | 3 |
| `beam` | 2 |
| `notehead` | 2 |
| `dynam` | 2 |
| `oStaff` | 2 |
| `tie` | 2 |
| `arpeg` | 1 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| cross-staff/cross-staff-014 | 1 |
| rest/rest-005 | 1 |
| rest/rest-010 | 1 |
| section/section-001 | 1 |
| space/space-001 | 1 |
| beam/beam-026 | 2 |
| breath/breath-002 | 2 |
| cross-staff/cross-staff-019 | 2 |
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
| gracenote/gracenote-022 | 6 |

