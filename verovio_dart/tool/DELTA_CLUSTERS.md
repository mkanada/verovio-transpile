# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-04 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 450
- Divergências (nível de número): 75350
- Assinaturas distintas (classe/tag @atributo): 120
- Subárvores podadas por divergência estrutural: 25

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 352 | 12580 | `436` (32 arq), `616` (32 arq), `-464` (31 arq), `-208` (29 arq), `90` (21 arq) |
| 2 | `beam/polygon @points` | 255 | 15594 | `436` (30 arq), `-464` (30 arq), `616` (27 arq), `481` (20 arq), `256` (18 arq) |
| 3 | `staff/path @d` | 220 | 12318 | `-1` (10 arq), `1` (10 arq), `25` (9 arq), `2` (7 arq), `4` (6 arq) |
| 4 | `notehead/use @transform` | 211 | 6896 | `-208` (20 arq), `25` (16 arq), `-1` (14 arq), `2` (11 arq), `1` (9 arq) |
| 5 | `barLine/path @d` | 208 | 3585 | `-1` (10 arq), `25` (9 arq), `1` (9 arq), `2` (7 arq), `4` (6 arq) |
| 6 | `clef/use @transform` | 181 | 457 | `1082` (6 arq), `2` (5 arq), `363` (4 arq), `4` (3 arq), `538` (3 arq) |
| 7 | `ledgerLines/path @d` | 143 | 4275 | `-1` (10 arq), `2` (6 arq), `1082` (6 arq), `-208` (6 arq), `25` (5 arq) |
| 8 | `meterSig/use @transform` | 117 | 358 | `2` (4 arq), `4` (3 arq), `447` (3 arq), `7` (2 arq), `90` (2 arq) |
| 9 | `system/path @d` | 101 | 198 | `363` (4 arq), `4` (3 arq), `447` (3 arq), `724` (2 arq), `7` (2 arq) |
| 10 | `slur/path @d` | 93 | 4271 | `2` (62 arq), `1` (53 arq), `3` (49 arq), `4` (32 arq), `-1` (23 arq) |
| 11 | `accid/use @transform` | 89 | 1106 | `28` (5 arq), `-26` (5 arq), `4` (5 arq), `-208` (4 arq), `-20` (3 arq) |
| 12 | `grpSym/path @d` | 82 | 1210 | `4` (3 arq), `724` (2 arq), `818` (2 arq), `1082` (2 arq), `570` (2 arq) |
| 13 | `rest/use @transform` | 71 | 532 | `90` (3 arq), `1082` (3 arq), `4` (3 arq), `-12` (3 arq), `12` (2 arq) |
| 14 | `keyAccid/use @transform` | 70 | 438 | `4` (3 arq), `447` (3 arq), `-12` (2 arq), `-316` (2 arq), `-5` (2 arq) |
| 15 | `dots/ellipse @cy` | 61 | 599 | `-180` (12 arq), `180` (4 arq), `360` (3 arq), `7` (2 arq), `816` (2 arq) |
| 16 | `flag/use @transform` | 56 | 543 | `-45` (5 arq), `90` (4 arq), `4` (4 arq), `25` (3 arq), `-2` (3 arq) |
| 17 | `artic/use @transform` | 51 | 731 | `427` (14 arq), `360` (11 arq), `540` (10 arq), `180` (7 arq), `607` (6 arq) |
| 18 | `mNum/text @y` | 44 | 58 | `4` (3 arq), `902` (2 arq), `1082` (2 arq), `816` (2 arq), `129` (1 arq) |
| 19 | `dots/ellipse @cx` | 43 | 504 | `-226` (12 arq), `-158` (3 arq), `-219` (3 arq), `25` (2 arq), `-225` (2 arq) |
| 20 | `tie/path @d` | 39 | 1889 | `-158` (29 arq), `158` (25 arq), `-585` (7 arq), `-45` (6 arq), `45` (6 arq) |
| 21 | `tupletNum/use @transform` | 36 | 179 | `-180` (2 arq), `-139` (2 arq), `25` (2 arq), `180` (2 arq), `12` (2 arq) |
| 22 | `dynam/use @transform` | 34 | 55 | `358` (2 arq), `372` (2 arq), `-386` (2 arq), `525` (2 arq), `-354` (2 arq) |
| 23 | `dir/text @y` | 28 | 66 | `-535` (3 arq), `-404` (2 arq), `67` (2 arq), `442` (2 arq), `3` (2 arq) |
| 24 | `note/path @d` | 18 | 618 | `40` (17 arq), `20` (13 arq), `6` (13 arq), `14` (13 arq), `26` (13 arq) |
| 25 | `note/polygon @points` | 17 | 352 | `-8` (17 arq), `-4` (13 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 86 |
| `2` | 75 |
| `3` | 59 |
| `-1` | 57 |
| `4` | 40 |
| `-208` | 39 |
| `-158` | 39 |
| `-4` | 36 |
| `-8` | 34 |
| `436` | 33 |
| `12` | 32 |
| `180` | 32 |
| `616` | 32 |
| `-464` | 31 |
| `158` | 31 |
| `6` | 30 |
| `-180` | 29 |
| `14` | 29 |
| `90` | 27 |
| `-2` | 25 |
| `26` | 25 |
| `360` | 25 |
| `11` | 24 |
| `40` | 24 |
| `-90` | 23 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `beam` | 120 |
| `staff` | 106 |
| `system` | 98 |
| `stem` | 27 |
| `note` | 20 |
| `artic` | 8 |
| `slur` | 8 |
| `dots` | 6 |
| `dynam` | 6 |
| `dir` | 5 |
| `syl` | 5 |
| `accid` | 4 |
| `gliss` | 4 |
| `tie` | 4 |
| `label` | 3 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| annot/annot-005 | 1 |
| dynam/dynam-007 | 1 |
| editorial/editorial-002 | 1 |
| tempo/tempo-004 | 1 |
| tuplet/tuplet-012 | 1 |
| accid/accid-001 | 2 |
| breath/breath-002 | 2 |
| chord/chord-003 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| gracenote/gracenote-002 | 2 |
| hairpin/hairpin-006 | 2 |
| rend/rend-004 | 2 |
| score/score-016 | 2 |
| accid/accid-014 | 3 |
| annot/annot-001 | 3 |
| chord/chord-004 | 3 |
| dynam/dynam-008 | 3 |
| dynam/dynam-010 | 3 |
| gracenote/gracenote-018 | 3 |
| pedal/pedal-005 | 3 |
| rend/rend-003 | 3 |
| accid/accid-011 | 4 |
| artic/artic-019 | 4 |
| dynam/dynam-002 | 4 |

