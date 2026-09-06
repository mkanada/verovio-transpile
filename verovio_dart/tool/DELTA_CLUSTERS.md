# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-06 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 293
- Divergências (nível de número): 40899
- Assinaturas distintas (classe/tag @atributo): 94
- Subárvores podadas por divergência estrutural: 21

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 144 | 6419 | `-208` (17 arq), `1` (13 arq), `2` (13 arq), `-1` (11 arq), `25` (11 arq) |
| 2 | `staff/path @d` | 136 | 7488 | `1` (10 arq), `2` (8 arq), `90` (6 arq), `4` (6 arq), `25` (6 arq) |
| 3 | `notehead/use @transform` | 133 | 3705 | `2` (12 arq), `25` (11 arq), `1` (10 arq), `90` (8 arq), `3` (7 arq) |
| 4 | `barLine/path @d` | 131 | 2384 | `1` (9 arq), `2` (8 arq), `4` (6 arq), `25` (6 arq), `90` (5 arq) |
| 5 | `clef/use @transform` | 114 | 295 | `2` (8 arq), `1` (5 arq), `4` (4 arq), `3` (4 arq), `-1` (3 arq) |
| 6 | `slur/path @d` | 93 | 3612 | `2` (77 arq), `1` (65 arq), `3` (62 arq), `-1` (47 arq), `4` (41 arq) |
| 7 | `beam/polygon @points` | 92 | 5676 | `-208` (12 arq), `1` (9 arq), `2` (8 arq), `4` (7 arq), `90` (5 arq) |
| 8 | `ledgerLines/path @d` | 91 | 2431 | `2` (9 arq), `1` (7 arq), `-1` (5 arq), `4` (4 arq), `25` (4 arq) |
| 9 | `system/path @d` | 72 | 134 | `4` (4 arq), `2` (4 arq), `1` (4 arq), `3` (4 arq), `-1` (3 arq) |
| 10 | `meterSig/use @transform` | 69 | 223 | `2` (6 arq), `1` (4 arq), `4` (3 arq), `3` (3 arq), `189` (2 arq) |
| 11 | `grpSym/path @d` | 64 | 908 | `2` (5 arq), `1` (5 arq), `3` (5 arq), `4` (4 arq), `-1` (3 arq) |
| 12 | `accid/use @transform` | 62 | 381 | `4` (5 arq), `26` (3 arq), `-1` (3 arq), `3` (3 arq), `96` (3 arq) |
| 13 | `artic/use @transform` | 51 | 670 | `427` (16 arq), `540` (13 arq), `360` (11 arq), `900` (11 arq), `180` (10 arq) |
| 14 | `rest/use @transform` | 47 | 370 | `4` (3 arq), `90` (3 arq), `2` (3 arq), `12` (2 arq), `189` (2 arq) |
| 15 | `keyAccid/use @transform` | 46 | 333 | `4` (4 arq), `-1` (3 arq), `189` (2 arq), `-316` (2 arq), `-11` (2 arq) |
| 16 | `tie/path @d` | 39 | 1067 | `1` (33 arq), `-1` (25 arq), `-2` (16 arq), `2` (5 arq), `3` (3 arq) |
| 17 | `flag/use @transform` | 36 | 352 | `2` (4 arq), `4` (4 arq), `1` (3 arq), `12` (2 arq), `189` (2 arq) |
| 18 | `dots/ellipse @cy` | 33 | 258 | `-180` (7 arq), `180` (5 arq), `360` (5 arq), `720` (4 arq), `540` (4 arq) |
| 19 | `mNum/text @y` | 31 | 43 | `4` (4 arq), `1` (3 arq), `2` (2 arq), `3` (2 arq), `8` (1 arq) |
| 20 | `dynam/use @transform` | 28 | 45 | `1` (3 arq), `2` (2 arq), `372` (2 arq), `184` (2 arq), `-354` (2 arq) |
| 21 | `dir/text @y` | 25 | 58 | `3` (3 arq), `2` (3 arq), `-404` (2 arq), `90` (2 arq), `-23` (2 arq) |
| 22 | `tupletNum/use @transform` | 22 | 81 | `-1` (4 arq), `90` (2 arq), `-180` (2 arq), `1` (2 arq), `1787` (1 arq) |
| 23 | `note/path @d` | 18 | 618 | `40` (17 arq), `20` (13 arq), `6` (13 arq), `14` (13 arq), `26` (13 arq) |
| 24 | `dots/ellipse @cx` | 18 | 133 | `-219` (3 arq), `192` (2 arq), `25` (2 arq), `96` (2 arq), `-225` (2 arq) |
| 25 | `note/polygon @points` | 17 | 352 | `-8` (17 arq), `-4` (13 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 110 |
| `2` | 88 |
| `-1` | 87 |
| `3` | 71 |
| `-2` | 55 |
| `4` | 49 |
| `-8` | 34 |
| `-3` | 31 |
| `-4` | 30 |
| `6` | 28 |
| `14` | 27 |
| `26` | 23 |
| `180` | 21 |
| `34` | 19 |
| `40` | 19 |
| `360` | 19 |
| `-208` | 18 |
| `-180` | 18 |
| `427` | 18 |
| `540` | 18 |
| `5` | 17 |
| `20` | 17 |
| `12` | 16 |
| `-9` | 15 |
| `900` | 15 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `system` | 71 |
| `staff` | 56 |
| `slur` | 31 |
| `note` | 20 |
| `tie` | 18 |
| `artic` | 15 |
| `stem` | 15 |
| `dots` | 8 |
| `dynam` | 7 |
| `tupletNum` | 6 |
| `syl` | 5 |
| `dir` | 5 |
| `beam` | 5 |
| `accid` | 4 |
| `clef` | 3 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| clef/clef-005 | 1 |
| gracenote/gracenote-010 | 1 |
| rest/rest-010 | 1 |
| accid/accid-001 | 2 |
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
| note/note-003 | 3 |
| rend/rend-003 | 3 |
| sameas/sameas-002 | 3 |
| artic/artic-019 | 4 |
| btrem/btrem-004 | 4 |

