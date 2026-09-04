# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-04 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 482
- Divergências (nível de número): 120834
- Assinaturas distintas (classe/tag @atributo): 134
- Subárvores podadas por divergência estrutural: 25

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `staff/path @d` | 364 | 21546 | `9` (83 arq), `18` (41 arq), `1` (23 arq), `27` (20 arq), `45` (19 arq) |
| 2 | `stem/path @d` | 359 | 22379 | `-208` (140 arq), `28` (122 arq), `-28` (106 arq), `9` (100 arq), `-199` (80 arq) |
| 3 | `notehead/use @transform` | 356 | 12014 | `9` (205 arq), `18` (140 arq), `27` (105 arq), `36` (92 arq), `45` (83 arq) |
| 4 | `barLine/path @d` | 355 | 6358 | `9` (80 arq), `18` (38 arq), `1` (21 arq), `27` (20 arq), `45` (19 arq) |
| 5 | `beam/polygon @points` | 255 | 23346 | `-208` (122 arq), `-199` (75 arq), `-190` (65 arq), `9` (61 arq), `315` (59 arq) |
| 6 | `ledgerLines/path @d` | 221 | 7280 | `9` (86 arq), `18` (25 arq), `27` (20 arq), `7` (18 arq), `11` (17 arq) |
| 7 | `clef/use @transform` | 190 | 481 | `1082` (6 arq), `2` (5 arq), `45` (4 arq), `447` (4 arq), `-2` (3 arq) |
| 8 | `meterSig/use @transform` | 127 | 451 | `2` (5 arq), `-2` (4 arq), `9` (3 arq), `447` (3 arq), `-4` (2 arq) |
| 9 | `accid/use @transform` | 115 | 1403 | `9` (26 arq), `18` (13 arq), `27` (10 arq), `45` (8 arq), `-3` (6 arq) |
| 10 | `system/path @d` | 104 | 213 | `-2` (3 arq), `363` (3 arq), `447` (3 arq), `724` (2 arq), `7` (2 arq) |
| 11 | `rest/use @transform` | 96 | 1041 | `9` (24 arq), `18` (8 arq), `36` (8 arq), `-2` (7 arq), `-77` (6 arq) |
| 12 | `slur/path @d` | 93 | 4598 | `1` (36 arq), `9` (35 arq), `2` (34 arq), `3` (34 arq), `-1` (26 arq) |
| 13 | `grpSym/path @d` | 85 | 1318 | `-2` (3 arq), `724` (2 arq), `2` (2 arq), `-270` (2 arq), `1082` (2 arq) |
| 14 | `dots/ellipse @cx` | 77 | 666 | `9` (21 arq), `18` (9 arq), `-217` (6 arq), `27` (6 arq), `-226` (5 arq) |
| 15 | `keyAccid/use @transform` | 73 | 496 | `-2` (4 arq), `447` (3 arq), `-316` (2 arq), `-270` (2 arq), `1082` (2 arq) |
| 16 | `flag/use @transform` | 72 | 800 | `9` (16 arq), `18` (12 arq), `63` (7 arq), `36` (7 arq), `-2` (6 arq) |
| 17 | `dots/ellipse @cy` | 61 | 601 | `-180` (12 arq), `180` (4 arq), `360` (3 arq), `540` (3 arq), `7` (2 arq) |
| 18 | `artic/use @transform` | 51 | 913 | `9` (15 arq), `427` (14 arq), `18` (13 arq), `360` (11 arq), `540` (10 arq) |
| 19 | `mNum/text @y` | 43 | 58 | `-2` (3 arq), `902` (2 arq), `1082` (2 arq), `816` (2 arq), `129` (1 arq) |
| 20 | `tie/path @d` | 39 | 1916 | `-158` (20 arq), `158` (15 arq), `29` (8 arq), `-585` (7 arq), `27` (7 arq) |
| 21 | `tupletNum/use @transform` | 39 | 288 | `9` (16 arq), `18` (8 arq), `85` (4 arq), `27` (3 arq), `-225` (3 arq) |
| 22 | `dynam/use @transform` | 35 | 77 | `9` (10 arq), `135` (2 arq), `358` (2 arq), `372` (2 arq), `-386` (2 arq) |
| 23 | `dir/text @y` | 27 | 68 | `-404` (2 arq), `442` (2 arq), `67` (2 arq), `3` (2 arq), `-30` (1 arq) |
| 24 | `note/path @d` | 22 | 1078 | `40` (17 arq), `20` (13 arq), `6` (13 arq), `14` (13 arq), `26` (13 arq) |
| 25 | `note/polygon @points` | 22 | 632 | `-8` (17 arq), `-4` (13 arq), `-2` (3 arq), `-6` (1 arq), `-1` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `9` | 220 |
| `18` | 152 |
| `-208` | 151 |
| `28` | 140 |
| `-28` | 117 |
| `27` | 112 |
| `45` | 109 |
| `36` | 103 |
| `1` | 93 |
| `-199` | 86 |
| `-1` | 81 |
| `54` | 77 |
| `-190` | 71 |
| `2` | 71 |
| `63` | 70 |
| `3` | 68 |
| `315` | 64 |
| `-181` | 63 |
| `927` | 61 |
| `-2` | 59 |
| `-4` | 58 |
| `20` | 58 |
| `90` | 58 |
| `7` | 57 |
| `12` | 56 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 234 |
| `system` | 102 |
| `stem` | 22 |
| `note` | 20 |
| `beam` | 13 |
| `mensur` | 12 |
| `artic` | 8 |
| `slur` | 7 |
| `dynam` | 6 |
| `ledgerLines` | 5 |
| `dir` | 5 |
| `dots` | 5 |
| `syl` | 4 |
| `gliss` | 4 |
| `tie` | 4 |

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

