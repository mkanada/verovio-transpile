# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-06 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 318
- Divergências (nível de número): 44926
- Assinaturas distintas (classe/tag @atributo): 98
- Subárvores podadas por divergência estrutural: 21

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 163 | 7137 | `-208` (18 arq), `25` (16 arq), `2` (16 arq), `1` (12 arq), `-1` (11 arq) |
| 2 | `staff/path @d` | 156 | 7973 | `1` (10 arq), `2` (9 arq), `25` (9 arq), `4` (7 arq), `-1` (6 arq) |
| 3 | `notehead/use @transform` | 153 | 4344 | `25` (16 arq), `2` (14 arq), `3` (9 arq), `4` (9 arq), `1` (9 arq) |
| 4 | `barLine/path @d` | 148 | 2554 | `2` (9 arq), `25` (9 arq), `1` (9 arq), `4` (7 arq), `-1` (6 arq) |
| 5 | `clef/use @transform` | 115 | 297 | `2` (8 arq), `4` (4 arq), `1` (4 arq), `3` (4 arq), `-1` (3 arq) |
| 6 | `ledgerLines/path @d` | 103 | 2835 | `2` (9 arq), `-1` (6 arq), `1` (6 arq), `25` (6 arq), `4` (6 arq) |
| 7 | `beam/polygon @points` | 101 | 6178 | `-208` (11 arq), `4` (9 arq), `25` (9 arq), `2` (9 arq), `1` (7 arq) |
| 8 | `slur/path @d` | 93 | 3616 | `2` (73 arq), `1` (62 arq), `3` (62 arq), `-1` (45 arq), `4` (41 arq) |
| 9 | `accid/use @transform` | 76 | 707 | `4` (6 arq), `28` (5 arq), `-26` (5 arq), `26` (4 arq), `-3` (4 arq) |
| 10 | `system/path @d` | 73 | 136 | `4` (4 arq), `2` (4 arq), `3` (4 arq), `-1` (3 arq), `1` (3 arq) |
| 11 | `meterSig/use @transform` | 70 | 227 | `2` (6 arq), `4` (3 arq), `3` (3 arq), `1` (3 arq), `189` (2 arq) |
| 12 | `grpSym/path @d` | 65 | 922 | `2` (5 arq), `3` (5 arq), `4` (4 arq), `1` (4 arq), `-1` (3 arq) |
| 13 | `artic/use @transform` | 51 | 674 | `427` (16 arq), `540` (14 arq), `360` (11 arq), `900` (11 arq), `180` (10 arq) |
| 14 | `rest/use @transform` | 49 | 376 | `4` (3 arq), `90` (3 arq), `2` (3 arq), `8` (3 arq), `12` (2 arq) |
| 15 | `keyAccid/use @transform` | 47 | 335 | `4` (4 arq), `-1` (3 arq), `189` (2 arq), `-316` (2 arq), `-11` (2 arq) |
| 16 | `flag/use @transform` | 43 | 445 | `2` (4 arq), `4` (4 arq), `25` (3 arq), `1` (3 arq), `13` (3 arq) |
| 17 | `dots/ellipse @cy` | 42 | 303 | `-180` (16 arq), `180` (5 arq), `360` (4 arq), `720` (4 arq), `540` (4 arq) |
| 18 | `tie/path @d` | 39 | 1084 | `1` (33 arq), `-1` (26 arq), `-2` (16 arq), `2` (6 arq), `3` (3 arq) |
| 19 | `dots/ellipse @cx` | 38 | 501 | `-226` (14 arq), `-219` (3 arq), `25` (2 arq), `-225` (2 arq), `-198` (2 arq) |
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
| `1` | 108 |
| `-1` | 90 |
| `2` | 86 |
| `3` | 72 |
| `-2` | 55 |
| `4` | 50 |
| `-8` | 34 |
| `-3` | 32 |
| `-4` | 31 |
| `14` | 31 |
| `6` | 30 |
| `-180` | 27 |
| `26` | 26 |
| `12` | 22 |
| `5` | 21 |
| `25` | 20 |
| `180` | 20 |
| `-208` | 19 |
| `13` | 19 |
| `28` | 19 |
| `34` | 19 |
| `40` | 19 |
| `540` | 19 |
| `20` | 18 |
| `360` | 18 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 72 |
| `system` | 72 |
| `slur` | 28 |
| `note` | 20 |
| `tie` | 18 |
| `stem` | 16 |
| `artic` | 15 |
| `dots` | 12 |
| `accid` | 8 |
| `tupletNum` | 6 |
| `dynam` | 6 |
| `dir` | 5 |
| `syl` | 5 |
| `beam` | 4 |
| `fTrem` | 3 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| chord/chord-004 | 1 |
| clef/clef-005 | 1 |
| gracenote/gracenote-010 | 1 |
| layer/layer-005 | 1 |
| lyric/lyric-011 | 1 |
| rest/rest-010 | 1 |
| stem/stem-014 | 1 |
| accid/accid-001 | 2 |
| accid/accid-011 | 2 |
| breath/breath-002 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| gracenote/gracenote-002 | 2 |
| gracenote/gracenote-012 | 2 |
| gracenote/gracenote-018 | 2 |
| ossia/ossia-004 | 2 |
| rend/rend-004 | 2 |
| score/score-016 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| accid/accid-014 | 3 |
| annot/annot-001 | 3 |
| artic/artic-003 | 3 |
| dynam/dynam-010 | 3 |

