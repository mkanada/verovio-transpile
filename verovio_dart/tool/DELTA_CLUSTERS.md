# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-05 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 374
- Divergências (nível de número): 60154
- Assinaturas distintas (classe/tag @atributo): 119
- Subárvores podadas por divergência estrutural: 21

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 247 | 9288 | `-1` (36 arq), `-208` (27 arq), `90` (21 arq), `1` (19 arq), `25` (17 arq) |
| 2 | `staff/path @d` | 208 | 11383 | `1` (13 arq), `-1` (11 arq), `25` (10 arq), `4` (7 arq), `2` (7 arq) |
| 3 | `notehead/use @transform` | 200 | 6241 | `-208` (19 arq), `25` (17 arq), `-1` (16 arq), `2` (12 arq), `1` (12 arq) |
| 4 | `barLine/path @d` | 197 | 3385 | `1` (12 arq), `-1` (11 arq), `25` (10 arq), `4` (7 arq), `2` (7 arq) |
| 5 | `clef/use @transform` | 166 | 428 | `1082` (6 arq), `2` (6 arq), `4` (4 arq), `1` (4 arq), `363` (3 arq) |
| 6 | `ledgerLines/path @d` | 136 | 3873 | `-1` (10 arq), `2` (7 arq), `1` (7 arq), `1082` (6 arq), `25` (6 arq) |
| 7 | `beam/polygon @points` | 131 | 7862 | `-1` (20 arq), `-208` (15 arq), `1` (10 arq), `25` (9 arq), `4` (8 arq) |
| 8 | `meterSig/use @transform` | 107 | 334 | `2` (5 arq), `4` (3 arq), `1` (3 arq), `190` (2 arq), `7` (2 arq) |
| 9 | `system/path @d` | 95 | 183 | `4` (4 arq), `363` (3 arq), `1` (3 arq), `816` (3 arq), `2` (3 arq) |
| 10 | `slur/path @d` | 93 | 3949 | `2` (72 arq), `1` (63 arq), `3` (62 arq), `4` (38 arq), `-1` (37 arq) |
| 11 | `accid/use @transform` | 89 | 1082 | `4` (6 arq), `28` (5 arq), `-26` (5 arq), `12` (3 arq), `25` (3 arq) |
| 12 | `grpSym/path @d` | 75 | 1092 | `4` (4 arq), `2` (4 arq), `3` (3 arq), `1` (3 arq), `724` (2 arq) |
| 13 | `rest/use @transform` | 69 | 487 | `90` (3 arq), `-1` (3 arq), `4` (3 arq), `1082` (3 arq), `816` (3 arq) |
| 14 | `keyAccid/use @transform` | 66 | 413 | `4` (4 arq), `816` (3 arq), `-2` (2 arq), `-12` (2 arq), `190` (2 arq) |
| 15 | `flag/use @transform` | 57 | 518 | `-45` (5 arq), `1` (5 arq), `-2` (4 arq), `90` (4 arq), `2` (4 arq) |
| 16 | `dots/ellipse @cy` | 53 | 547 | `-180` (13 arq), `180` (4 arq), `360` (3 arq), `814` (2 arq), `7` (2 arq) |
| 17 | `artic/use @transform` | 51 | 695 | `427` (15 arq), `540` (12 arq), `360` (11 arq), `180` (8 arq), `900` (8 arq) |
| 18 | `dots/ellipse @cx` | 42 | 499 | `-226` (12 arq), `-158` (3 arq), `-219` (3 arq), `25` (2 arq), `-225` (2 arq) |
| 19 | `mNum/text @y` | 41 | 55 | `4` (4 arq), `1` (3 arq), `12` (2 arq), `902` (2 arq), `2` (2 arq) |
| 20 | `tie/path @d` | 39 | 1221 | `1` (30 arq), `-1` (22 arq), `-2` (13 arq), `2` (5 arq), `1082` (3 arq) |
| 21 | `dynam/use @transform` | 33 | 52 | `358` (2 arq), `372` (2 arq), `185` (2 arq), `525` (2 arq), `-354` (2 arq) |
| 22 | `tupletNum/use @transform` | 31 | 115 | `1` (5 arq), `-1` (5 arq), `5` (2 arq), `-180` (2 arq), `25` (2 arq) |
| 23 | `dir/text @y` | 27 | 64 | `-404` (2 arq), `-23` (2 arq), `-9` (2 arq), `442` (2 arq), `3` (2 arq) |
| 24 | `note/path @d` | 18 | 618 | `40` (17 arq), `20` (13 arq), `6` (13 arq), `14` (13 arq), `26` (13 arq) |
| 25 | `label/text @y` | 18 | 35 | `190` (2 arq), `634` (1 arq), `129` (1 arq), `7` (1 arq), `-113` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 121 |
| `-1` | 110 |
| `2` | 84 |
| `3` | 71 |
| `-2` | 47 |
| `4` | 46 |
| `-208` | 37 |
| `-8` | 33 |
| `-4` | 33 |
| `6` | 30 |
| `14` | 29 |
| `90` | 29 |
| `26` | 27 |
| `-180` | 26 |
| `-3` | 26 |
| `-90` | 24 |
| `12` | 23 |
| `180` | 23 |
| `5` | 22 |
| `25` | 22 |
| `360` | 22 |
| `7` | 20 |
| `28` | 20 |
| `34` | 20 |
| `-9` | 19 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 100 |
| `system` | 93 |
| `stem` | 36 |
| `note` | 20 |
| `beam` | 16 |
| `artic` | 15 |
| `slur` | 15 |
| `dots` | 9 |
| `tie` | 8 |
| `dynam` | 6 |
| `tupletNum` | 5 |
| `dir` | 5 |
| `syl` | 5 |
| `accid` | 4 |
| `gliss` | 4 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| annot/annot-005 | 1 |
| dynam/dynam-007 | 1 |
| editorial/editorial-002 | 1 |
| gracenote/gracenote-019 | 1 |
| lyric/lyric-011 | 1 |
| octave/octave-002 | 1 |
| stem/stem-014 | 1 |
| tempo/tempo-004 | 1 |
| tuplet/tuplet-012 | 1 |
| accid/accid-001 | 2 |
| breath/breath-002 | 2 |
| chord/chord-003 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| gracenote/gracenote-002 | 2 |
| gracenote/gracenote-010 | 2 |
| gracenote/gracenote-012 | 2 |
| hairpin/hairpin-006 | 2 |
| ossia/ossia-004 | 2 |
| rend/rend-004 | 2 |
| score/score-016 | 2 |
| tuplet/tuplet-019 | 2 |
| tuplet/tuplet-021 | 2 |
| tuplet/tuplet-022 | 2 |
| accid/accid-014 | 3 |

