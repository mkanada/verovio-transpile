# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-06 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 282
- Divergências (nível de número): 35712
- Assinaturas distintas (classe/tag @atributo): 92
- Subárvores podadas por divergência estrutural: 20

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 133 | 5427 | `-208` (17 arq), `2` (13 arq), `25` (11 arq), `1` (9 arq), `-37` (9 arq) |
| 2 | `staff/path @d` | 118 | 6678 | `2` (8 arq), `90` (7 arq), `1` (7 arq), `4` (6 arq), `25` (6 arq) |
| 3 | `notehead/use @transform` | 116 | 3085 | `2` (11 arq), `25` (11 arq), `90` (9 arq), `1` (7 arq), `-36` (7 arq) |
| 4 | `barLine/path @d` | 114 | 2148 | `2` (8 arq), `1` (7 arq), `90` (6 arq), `4` (6 arq), `25` (6 arq) |
| 5 | `slur/path @d` | 93 | 3525 | `2` (81 arq), `1` (70 arq), `3` (64 arq), `-1` (49 arq), `4` (42 arq) |
| 6 | `clef/use @transform` | 87 | 226 | `2` (8 arq), `1` (5 arq), `4` (4 arq), `3` (4 arq), `-1` (3 arq) |
| 7 | `beam/polygon @points` | 81 | 4510 | `-208` (13 arq), `2` (8 arq), `4` (7 arq), `1` (6 arq), `90` (5 arq) |
| 8 | `ledgerLines/path @d` | 78 | 1821 | `2` (9 arq), `1` (6 arq), `4` (4 arq), `25` (4 arq), `50` (4 arq) |
| 9 | `meterSig/use @transform` | 61 | 207 | `2` (6 arq), `1` (4 arq), `4` (3 arq), `3` (3 arq), `43` (3 arq) |
| 10 | `accid/use @transform` | 59 | 346 | `4` (5 arq), `26` (3 arq), `-1` (3 arq), `3` (3 arq), `96` (3 arq) |
| 11 | `system/path @d` | 58 | 119 | `4` (4 arq), `1` (4 arq), `3` (4 arq), `2` (4 arq), `-1` (3 arq) |
| 12 | `grpSym/path @d` | 50 | 764 | `1` (5 arq), `2` (5 arq), `3` (5 arq), `4` (4 arq), `45` (4 arq) |
| 13 | `artic/use @transform` | 50 | 649 | `427` (16 arq), `540` (13 arq), `360` (11 arq), `900` (11 arq), `180` (10 arq) |
| 14 | `rest/use @transform` | 41 | 343 | `2` (4 arq), `4` (3 arq), `90` (3 arq), `12` (2 arq), `189` (2 arq) |
| 15 | `tie/path @d` | 39 | 1055 | `1` (34 arq), `-1` (25 arq), `-2` (16 arq), `2` (6 arq), `3` (4 arq) |
| 16 | `keyAccid/use @transform` | 39 | 310 | `4` (4 arq), `-1` (3 arq), `189` (2 arq), `-316` (2 arq), `-11` (2 arq) |
| 17 | `flag/use @transform` | 33 | 294 | `2` (3 arq), `4` (3 arq), `189` (2 arq), `54` (2 arq), `-45` (2 arq) |
| 18 | `mNum/text @y` | 30 | 42 | `4` (4 arq), `1` (3 arq), `2` (2 arq), `3` (2 arq), `8` (1 arq) |
| 19 | `dots/ellipse @cy` | 29 | 183 | `-180` (4 arq), `360` (3 arq), `540` (3 arq), `414` (2 arq), `180` (2 arq) |
| 20 | `dynam/use @transform` | 25 | 40 | `1` (3 arq), `372` (2 arq), `184` (2 arq), `525` (2 arq), `-354` (2 arq) |
| 21 | `dir/text @y` | 22 | 52 | `3` (3 arq), `2` (3 arq), `-404` (2 arq), `90` (2 arq), `-23` (2 arq) |
| 22 | `tupletNum/use @transform` | 19 | 69 | `-1` (3 arq), `1` (2 arq), `90` (2 arq), `-180` (2 arq), `1787` (1 arq) |
| 23 | `note/path @d` | 18 | 618 | `40` (17 arq), `20` (13 arq), `6` (13 arq), `14` (13 arq), `26` (13 arq) |
| 24 | `dots/ellipse @cx` | 18 | 133 | `-219` (3 arq), `192` (2 arq), `25` (2 arq), `96` (2 arq), `-225` (2 arq) |
| 25 | `note/polygon @points` | 17 | 352 | `-8` (17 arq), `-4` (13 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 111 |
| `2` | 91 |
| `-1` | 85 |
| `3` | 71 |
| `-2` | 54 |
| `4` | 50 |
| `-3` | 32 |
| `-4` | 30 |
| `-8` | 28 |
| `6` | 26 |
| `14` | 24 |
| `26` | 23 |
| `-208` | 19 |
| `40` | 19 |
| `34` | 17 |
| `180` | 17 |
| `360` | 17 |
| `427` | 17 |
| `540` | 17 |
| `5` | 16 |
| `20` | 16 |
| `-180` | 15 |
| `90` | 14 |
| `-9` | 13 |
| `12` | 13 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `system` | 57 |
| `staff` | 51 |
| `slur` | 37 |
| `stem` | 20 |
| `note` | 20 |
| `tie` | 18 |
| `artic` | 15 |
| `dynam` | 7 |
| `dir` | 6 |
| `beam` | 6 |
| `tupletNum` | 6 |
| `syl` | 5 |
| `dots` | 5 |
| `accid` | 4 |
| `dot` | 3 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| rest/rest-010 | 1 |
| accid/accid-001 | 2 |
| breath/breath-002 | 2 |
| cross-staff/cross-staff-002 | 2 |
| cross-staff/cross-staff-006 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| gracenote/gracenote-002 | 2 |
| gracenote/gracenote-012 | 2 |
| gracenote/gracenote-018 | 2 |
| mensural/mensural-006 | 2 |
| ossia/ossia-004 | 2 |
| rend/rend-004 | 2 |
| score/score-016 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| accid/accid-014 | 3 |
| annot/annot-001 | 3 |
| artic/artic-003 | 3 |
| artic/artic-009 | 3 |
| dynam/dynam-010 | 3 |
| note/note-003 | 3 |
| rend/rend-003 | 3 |
| sameas/sameas-002 | 3 |

