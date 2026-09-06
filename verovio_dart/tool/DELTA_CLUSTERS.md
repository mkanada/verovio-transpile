# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-06 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 357
- Divergências (nível de número): 55374
- Assinaturas distintas (classe/tag @atributo): 104
- Subárvores podadas por divergência estrutural: 21

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 227 | 8720 | `-1` (35 arq), `-208` (18 arq), `1` (17 arq), `25` (16 arq), `2` (15 arq) |
| 2 | `staff/path @d` | 196 | 10680 | `1` (11 arq), `25` (9 arq), `2` (8 arq), `4` (7 arq), `1082` (6 arq) |
| 3 | `notehead/use @transform` | 190 | 5809 | `25` (16 arq), `2` (13 arq), `1` (10 arq), `4` (9 arq), `7` (8 arq) |
| 4 | `barLine/path @d` | 186 | 3167 | `1` (10 arq), `25` (9 arq), `2` (8 arq), `4` (7 arq), `-1` (6 arq) |
| 5 | `clef/use @transform` | 162 | 383 | `2` (7 arq), `1082` (6 arq), `1` (5 arq), `4` (4 arq), `363` (3 arq) |
| 6 | `ledgerLines/path @d` | 130 | 3647 | `2` (8 arq), `1` (7 arq), `1082` (6 arq), `25` (6 arq), `4` (6 arq) |
| 7 | `beam/polygon @points` | 127 | 7162 | `-1` (19 arq), `1` (11 arq), `-208` (11 arq), `25` (9 arq), `2` (9 arq) |
| 8 | `meterSig/use @transform` | 103 | 322 | `2` (5 arq), `1` (4 arq), `4` (3 arq), `358` (3 arq), `190` (2 arq) |
| 9 | `system/path @d` | 95 | 182 | `4` (4 arq), `1` (4 arq), `363` (3 arq), `816` (3 arq), `3` (3 arq) |
| 10 | `slur/path @d` | 93 | 3922 | `2` (73 arq), `3` (64 arq), `1` (63 arq), `4` (42 arq), `-1` (38 arq) |
| 11 | `accid/use @transform` | 84 | 1058 | `4` (6 arq), `28` (5 arq), `-26` (5 arq), `26` (4 arq), `5` (4 arq) |
| 12 | `grpSym/path @d` | 76 | 1102 | `4` (4 arq), `1` (4 arq), `2` (4 arq), `3` (4 arq), `724` (2 arq) |
| 13 | `rest/use @transform` | 67 | 465 | `1082` (3 arq), `4` (3 arq), `816` (3 arq), `-12` (3 arq), `12` (2 arq) |
| 14 | `keyAccid/use @transform` | 64 | 405 | `4` (4 arq), `358` (3 arq), `816` (3 arq), `-2` (2 arq), `-12` (2 arq) |
| 15 | `flag/use @transform` | 54 | 512 | `90` (4 arq), `2` (4 arq), `4` (4 arq), `25` (3 arq), `12` (3 arq) |
| 16 | `dots/ellipse @cy` | 52 | 549 | `-180` (12 arq), `180` (4 arq), `360` (3 arq), `814` (2 arq), `7` (2 arq) |
| 17 | `artic/use @transform` | 51 | 673 | `427` (15 arq), `540` (13 arq), `360` (11 arq), `900` (9 arq), `180` (8 arq) |
| 18 | `mNum/text @y` | 42 | 56 | `4` (4 arq), `1` (3 arq), `12` (2 arq), `902` (2 arq), `2` (2 arq) |
| 19 | `tie/path @d` | 39 | 1212 | `1` (33 arq), `-1` (19 arq), `-2` (13 arq), `2` (6 arq), `1082` (3 arq) |
| 20 | `dots/ellipse @cx` | 38 | 501 | `-226` (14 arq), `-219` (3 arq), `25` (2 arq), `-225` (2 arq), `-198` (2 arq) |
| 21 | `dynam/use @transform` | 33 | 51 | `358` (2 arq), `372` (2 arq), `185` (2 arq), `525` (2 arq), `-354` (2 arq) |
| 22 | `tupletNum/use @transform` | 30 | 104 | `1` (6 arq), `-1` (6 arq), `5` (2 arq), `-180` (2 arq), `25` (2 arq) |
| 23 | `dir/text @y` | 27 | 65 | `-404` (2 arq), `-23` (2 arq), `-9` (2 arq), `442` (2 arq), `3` (2 arq) |
| 24 | `note/path @d` | 18 | 618 | `40` (17 arq), `20` (13 arq), `6` (13 arq), `14` (13 arq), `26` (13 arq) |
| 25 | `note/polygon @points` | 17 | 352 | `-8` (17 arq), `-4` (13 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 117 |
| `-1` | 102 |
| `2` | 85 |
| `3` | 73 |
| `4` | 50 |
| `-2` | 46 |
| `-8` | 34 |
| `-4` | 31 |
| `6` | 30 |
| `5` | 29 |
| `14` | 29 |
| `-3` | 27 |
| `26` | 27 |
| `-180` | 23 |
| `12` | 23 |
| `360` | 22 |
| `25` | 20 |
| `-208` | 19 |
| `20` | 19 |
| `34` | 19 |
| `40` | 19 |
| `180` | 19 |
| `28` | 18 |
| `90` | 18 |
| `-9` | 17 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `system` | 93 |
| `staff` | 89 |
| `stem` | 27 |
| `note` | 20 |
| `slur` | 20 |
| `beam` | 16 |
| `artic` | 15 |
| `dots` | 10 |
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
| clef/clef-005 | 1 |
| dynam/dynam-007 | 1 |
| dynam/dynam-008 | 1 |
| gracenote/gracenote-010 | 1 |
| lyric/lyric-011 | 1 |
| stem/stem-014 | 1 |
| tempo/tempo-004 | 1 |
| tuplet/tuplet-012 | 1 |
| unison/unison-001 | 1 |
| accid/accid-001 | 2 |
| accid/accid-011 | 2 |
| breath/breath-002 | 2 |
| chord/chord-003 | 2 |
| chord/chord-004 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| gracenote/gracenote-002 | 2 |
| gracenote/gracenote-012 | 2 |
| gracenote/gracenote-018 | 2 |
| ossia/ossia-004 | 2 |
| rend/rend-004 | 2 |
| score/score-016 | 2 |
| tuplet/tuplet-019 | 2 |
| tuplet/tuplet-021 | 2 |
| tuplet/tuplet-022 | 2 |

