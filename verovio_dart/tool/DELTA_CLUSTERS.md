# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-06 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 306
- Divergências (nível de número): 44270
- Assinaturas distintas (classe/tag @atributo): 96
- Subárvores podadas por divergência estrutural: 21

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 158 | 7025 | `-208` (19 arq), `25` (18 arq), `2` (15 arq), `1` (13 arq), `-1` (12 arq) |
| 2 | `staff/path @d` | 151 | 7928 | `25` (11 arq), `1` (10 arq), `2` (9 arq), `4` (8 arq), `-1` (6 arq) |
| 3 | `notehead/use @transform` | 148 | 4207 | `25` (18 arq), `2` (14 arq), `4` (10 arq), `3` (9 arq), `1` (9 arq) |
| 4 | `barLine/path @d` | 144 | 2534 | `25` (11 arq), `2` (9 arq), `1` (9 arq), `4` (8 arq), `-1` (6 arq) |
| 5 | `clef/use @transform` | 115 | 297 | `2` (8 arq), `4` (4 arq), `1` (4 arq), `3` (4 arq), `-1` (3 arq) |
| 6 | `beam/polygon @points` | 101 | 6160 | `-208` (12 arq), `25` (10 arq), `4` (9 arq), `2` (9 arq), `1` (7 arq) |
| 7 | `ledgerLines/path @d` | 101 | 2757 | `2` (9 arq), `25` (7 arq), `4` (7 arq), `-1` (6 arq), `1` (6 arq) |
| 8 | `slur/path @d` | 93 | 3616 | `2` (74 arq), `1` (62 arq), `3` (61 arq), `-1` (45 arq), `4` (41 arq) |
| 9 | `system/path @d` | 73 | 136 | `4` (4 arq), `2` (4 arq), `3` (4 arq), `-1` (3 arq), `1` (3 arq) |
| 10 | `accid/use @transform` | 70 | 608 | `4` (6 arq), `28` (5 arq), `26` (4 arq), `-20` (3 arq), `-1` (3 arq) |
| 11 | `meterSig/use @transform` | 70 | 227 | `2` (6 arq), `4` (3 arq), `3` (3 arq), `1` (3 arq), `189` (2 arq) |
| 12 | `grpSym/path @d` | 65 | 922 | `2` (5 arq), `3` (5 arq), `4` (4 arq), `1` (4 arq), `-1` (3 arq) |
| 13 | `artic/use @transform` | 51 | 674 | `427` (16 arq), `540` (14 arq), `360` (11 arq), `900` (11 arq), `180` (10 arq) |
| 14 | `rest/use @transform` | 49 | 376 | `4` (3 arq), `90` (3 arq), `2` (3 arq), `8` (3 arq), `12` (2 arq) |
| 15 | `keyAccid/use @transform` | 47 | 335 | `4` (4 arq), `-1` (3 arq), `189` (2 arq), `-316` (2 arq), `-11` (2 arq) |
| 16 | `flag/use @transform` | 41 | 420 | `2` (4 arq), `4` (4 arq), `25` (3 arq), `1` (3 arq), `20` (2 arq) |
| 17 | `tie/path @d` | 39 | 1084 | `1` (33 arq), `-1` (26 arq), `-2` (16 arq), `2` (6 arq), `3` (3 arq) |
| 18 | `dots/ellipse @cx` | 36 | 472 | `-226` (15 arq), `25` (4 arq), `-219` (3 arq), `-225` (2 arq), `-519` (2 arq) |
| 19 | `dots/ellipse @cy` | 34 | 267 | `-180` (7 arq), `180` (5 arq), `360` (5 arq), `720` (4 arq), `540` (4 arq) |
| 20 | `mNum/text @y` | 31 | 43 | `4` (4 arq), `1` (3 arq), `2` (2 arq), `3` (2 arq), `8` (1 arq) |
| 21 | `dynam/use @transform` | 28 | 45 | `-354` (2 arq), `372` (2 arq), `184` (2 arq), `2` (2 arq), `1` (2 arq) |
| 22 | `tupletNum/use @transform` | 25 | 94 | `-1` (4 arq), `90` (2 arq), `-180` (2 arq), `1` (2 arq), `25` (2 arq) |
| 23 | `dir/text @y` | 25 | 58 | `3` (3 arq), `2` (3 arq), `-404` (2 arq), `90` (2 arq), `-23` (2 arq) |
| 24 | `note/path @d` | 18 | 618 | `40` (17 arq), `20` (13 arq), `6` (13 arq), `14` (13 arq), `26` (13 arq) |
| 25 | `note/polygon @points` | 17 | 352 | `-8` (17 arq), `-4` (13 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 109 |
| `2` | 88 |
| `-1` | 87 |
| `3` | 71 |
| `-2` | 55 |
| `4` | 51 |
| `-8` | 35 |
| `-4` | 31 |
| `-3` | 31 |
| `6` | 31 |
| `14` | 31 |
| `26` | 26 |
| `25` | 23 |
| `5` | 22 |
| `12` | 21 |
| `-208` | 20 |
| `34` | 20 |
| `40` | 20 |
| `180` | 20 |
| `-180` | 19 |
| `28` | 19 |
| `360` | 19 |
| `540` | 19 |
| `13` | 18 |
| `20` | 18 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `system` | 72 |
| `staff` | 68 |
| `slur` | 30 |
| `note` | 20 |
| `tie` | 18 |
| `stem` | 16 |
| `artic` | 15 |
| `syl` | 8 |
| `dynam` | 6 |
| `tupletNum` | 6 |
| `dots` | 6 |
| `dir` | 5 |
| `accid` | 4 |
| `beam` | 4 |
| `clef` | 3 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| clef/clef-005 | 1 |
| gracenote/gracenote-010 | 1 |
| rest/rest-010 | 1 |
| accid/accid-001 | 2 |
| accid/accid-011 | 2 |
| breath/breath-002 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| gracenote/gracenote-002 | 2 |
| gracenote/gracenote-012 | 2 |
| gracenote/gracenote-018 | 2 |
| lyric/lyric-002 | 2 |
| ossia/ossia-004 | 2 |
| rend/rend-004 | 2 |
| score/score-016 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| accid/accid-014 | 3 |
| annot/annot-001 | 3 |
| artic/artic-003 | 3 |
| dynam/dynam-010 | 3 |
| note/note-003 | 3 |
| rend/rend-003 | 3 |
| stem/stem-011 | 3 |

