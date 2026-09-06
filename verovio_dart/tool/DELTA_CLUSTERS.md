# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-06 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 353
- Divergências (nível de número): 49127
- Assinaturas distintas (classe/tag @atributo): 100
- Subárvores podadas por divergência estrutural: 21

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 219 | 7842 | `-1` (35 arq), `-60` (21 arq), `-208` (18 arq), `-150` (18 arq), `-90` (18 arq) |
| 2 | `staff/path @d` | 168 | 8623 | `180` (11 arq), `1` (11 arq), `2` (9 arq), `25` (9 arq), `4` (7 arq) |
| 3 | `notehead/use @transform` | 166 | 5025 | `25` (16 arq), `2` (14 arq), `180` (11 arq), `1` (10 arq), `4` (9 arq) |
| 4 | `barLine/path @d` | 159 | 2688 | `1` (10 arq), `2` (9 arq), `180` (9 arq), `25` (9 arq), `4` (7 arq) |
| 5 | `clef/use @transform` | 126 | 313 | `180` (10 arq), `2` (8 arq), `1` (5 arq), `4` (4 arq), `-1` (3 arq) |
| 6 | `beam/polygon @points` | 118 | 6862 | `-1` (19 arq), `1` (11 arq), `-208` (11 arq), `25` (9 arq), `2` (9 arq) |
| 7 | `ledgerLines/path @d` | 110 | 3209 | `2` (9 arq), `180` (9 arq), `1` (7 arq), `25` (6 arq), `4` (6 arq) |
| 8 | `slur/path @d` | 93 | 3879 | `2` (73 arq), `3` (66 arq), `1` (64 arq), `4` (44 arq), `-1` (39 arq) |
| 9 | `accid/use @transform` | 78 | 1015 | `4` (6 arq), `28` (5 arq), `-26` (5 arq), `26` (4 arq), `180` (3 arq) |
| 10 | `system/path @d` | 78 | 145 | `4` (4 arq), `180` (4 arq), `1` (4 arq), `2` (4 arq), `3` (3 arq) |
| 11 | `meterSig/use @transform` | 76 | 236 | `2` (6 arq), `1` (4 arq), `180` (4 arq), `4` (3 arq), `190` (2 arq) |
| 12 | `grpSym/path @d` | 67 | 952 | `1` (5 arq), `2` (5 arq), `4` (4 arq), `3` (4 arq), `45` (3 arq) |
| 13 | `rest/use @transform` | 54 | 390 | `180` (5 arq), `4` (3 arq), `2` (3 arq), `8` (3 arq), `-12` (3 arq) |
| 14 | `artic/use @transform` | 51 | 674 | `427` (16 arq), `540` (14 arq), `360` (12 arq), `900` (11 arq), `180` (8 arq) |
| 15 | `flag/use @transform` | 50 | 455 | `-90` (5 arq), `2` (4 arq), `4` (4 arq), `25` (3 arq), `12` (3 arq) |
| 16 | `keyAccid/use @transform` | 50 | 338 | `4` (4 arq), `2` (3 arq), `-2` (2 arq), `-12` (2 arq), `190` (2 arq) |
| 17 | `dots/ellipse @cy` | 43 | 475 | `-180` (15 arq), `180` (6 arq), `360` (4 arq), `540` (3 arq), `720` (3 arq) |
| 18 | `tie/path @d` | 39 | 1087 | `1` (33 arq), `-1` (25 arq), `-2` (16 arq), `2` (6 arq), `3` (3 arq) |
| 19 | `dots/ellipse @cx` | 38 | 501 | `-226` (14 arq), `-219` (3 arq), `25` (2 arq), `-225` (2 arq), `-198` (2 arq) |
| 20 | `mNum/text @y` | 32 | 44 | `4` (4 arq), `1` (3 arq), `3` (2 arq), `2` (2 arq), `12` (2 arq) |
| 21 | `tupletNum/use @transform` | 30 | 104 | `1` (6 arq), `-1` (6 arq), `5` (2 arq), `-180` (2 arq), `25` (2 arq) |
| 22 | `dynam/use @transform` | 30 | 47 | `2` (3 arq), `-354` (2 arq), `372` (2 arq), `185` (2 arq), `525` (2 arq) |
| 23 | `dir/text @y` | 25 | 58 | `3` (4 arq), `-404` (2 arq), `-23` (2 arq), `-9` (2 arq), `442` (2 arq) |
| 24 | `note/path @d` | 18 | 618 | `40` (17 arq), `20` (13 arq), `6` (13 arq), `14` (13 arq), `26` (13 arq) |
| 25 | `note/polygon @points` | 17 | 352 | `-8` (17 arq), `-4` (13 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 117 |
| `-1` | 109 |
| `2` | 85 |
| `3` | 77 |
| `-2` | 53 |
| `4` | 52 |
| `-8` | 34 |
| `-4` | 32 |
| `-3` | 30 |
| `5` | 29 |
| `6` | 29 |
| `14` | 29 |
| `-180` | 28 |
| `26` | 27 |
| `-90` | 26 |
| `180` | 26 |
| `-60` | 24 |
| `12` | 24 |
| `-150` | 20 |
| `25` | 20 |
| `-208` | 19 |
| `20` | 19 |
| `34` | 19 |
| `40` | 19 |
| `360` | 19 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 77 |
| `system` | 77 |
| `stem` | 41 |
| `slur` | 21 |
| `note` | 20 |
| `beam` | 17 |
| `artic` | 15 |
| `tie` | 14 |
| `dots` | 11 |
| `dynam` | 6 |
| `syl` | 5 |
| `tupletNum` | 5 |
| `dir` | 5 |
| `gliss` | 4 |
| `accid` | 4 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| clef/clef-005 | 1 |
| dynam/dynam-007 | 1 |
| dynam/dynam-008 | 1 |
| gracenote/gracenote-010 | 1 |
| lyric/lyric-011 | 1 |
| repeats/rpt-005 | 1 |
| stem/stem-014 | 1 |
| tempo/tempo-004 | 1 |
| tuplet/tuplet-012 | 1 |
| unison/unison-001 | 1 |
| accid/accid-001 | 2 |
| accid/accid-011 | 2 |
| breath/breath-002 | 2 |
| choice/choice-001 | 2 |
| chord/chord-004 | 2 |
| cpmark/cpmark-001 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| gracenote/gracenote-002 | 2 |
| gracenote/gracenote-008 | 2 |
| gracenote/gracenote-012 | 2 |
| gracenote/gracenote-018 | 2 |
| ossia/ossia-004 | 2 |
| rend/rend-004 | 2 |
| score/score-005 | 2 |

