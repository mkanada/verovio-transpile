# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-07 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 245
- Divergências (nível de número): 28897
- Assinaturas distintas (classe/tag @atributo): 88
- Subárvores podadas por divergência estrutural: 19

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 104 | 4043 | `-208` (14 arq), `2` (12 arq), `-37` (10 arq), `90` (8 arq), `-1` (7 arq) |
| 2 | `staff/path @d` | 93 | 5303 | `2` (8 arq), `90` (7 arq), `1` (7 arq), `4` (6 arq), `-1` (6 arq) |
| 3 | `slur/path @d` | 93 | 3322 | `2` (83 arq), `1` (73 arq), `3` (66 arq), `-1` (51 arq), `4` (45 arq) |
| 4 | `barLine/path @d` | 89 | 1728 | `2` (8 arq), `1` (7 arq), `90` (6 arq), `-1` (6 arq), `4` (6 arq) |
| 5 | `notehead/use @transform` | 88 | 2201 | `2` (11 arq), `90` (9 arq), `-1` (6 arq), `1` (6 arq), `3` (6 arq) |
| 6 | `clef/use @transform` | 70 | 188 | `2` (8 arq), `-1` (5 arq), `1` (5 arq), `3` (5 arq), `4` (4 arq) |
| 7 | `beam/polygon @points` | 65 | 3474 | `-208` (12 arq), `2` (7 arq), `4` (6 arq), `1` (5 arq), `-1` (5 arq) |
| 8 | `ledgerLines/path @d` | 59 | 1543 | `2` (9 arq), `1` (5 arq), `-1` (4 arq), `4` (4 arq), `3` (3 arq) |
| 9 | `meterSig/use @transform` | 50 | 166 | `2` (6 arq), `1` (4 arq), `4` (3 arq), `3` (3 arq), `43` (3 arq) |
| 10 | `system/path @d` | 48 | 101 | `3` (5 arq), `4` (4 arq), `1` (4 arq), `-1` (4 arq), `2` (4 arq) |
| 11 | `grpSym/path @d` | 44 | 688 | `1` (6 arq), `3` (6 arq), `2` (5 arq), `4` (4 arq), `-1` (4 arq) |
| 12 | `accid/use @transform` | 43 | 207 | `-1` (5 arq), `4` (5 arq), `3` (4 arq), `96` (3 arq), `43` (2 arq) |
| 13 | `tie/path @d` | 39 | 1032 | `1` (37 arq), `-1` (25 arq), `-2` (16 arq), `2` (7 arq), `3` (5 arq) |
| 14 | `keyAccid/use @transform` | 33 | 278 | `4` (4 arq), `-1` (3 arq), `-11` (2 arq), `-316` (2 arq), `1` (2 arq) |
| 15 | `rest/use @transform` | 32 | 277 | `2` (4 arq), `4` (3 arq), `90` (3 arq), `54` (2 arq), `-26` (2 arq) |
| 16 | `flag/use @transform` | 28 | 219 | `-45` (3 arq), `-90` (3 arq), `2` (3 arq), `4` (3 arq), `54` (2 arq) |
| 17 | `dots/ellipse @cy` | 27 | 169 | `540` (4 arq), `-180` (4 arq), `360` (3 arq), `414` (2 arq), `180` (2 arq) |
| 18 | `mNum/text @y` | 27 | 38 | `4` (4 arq), `1` (3 arq), `2` (2 arq), `3` (2 arq), `8` (1 arq) |
| 19 | `dynam/use @transform` | 22 | 35 | `1` (3 arq), `-5` (2 arq), `525` (2 arq), `-354` (2 arq), `2` (2 arq) |
| 20 | `dir/text @y` | 20 | 49 | `3` (3 arq), `2` (3 arq), `-404` (2 arq), `90` (2 arq), `-23` (2 arq) |
| 21 | `note/path @d` | 18 | 618 | `40` (17 arq), `20` (13 arq), `6` (13 arq), `14` (13 arq), `26` (13 arq) |
| 22 | `note/polygon @points` | 17 | 352 | `-8` (17 arq), `-4` (13 arq) |
| 23 | `tupletNum/use @transform` | 16 | 52 | `-1` (3 arq), `1` (2 arq), `90` (2 arq), `-180` (2 arq), `79` (1 arq) |
| 24 | `artic/use @transform` | 15 | 200 | `4` (3 arq), `-26` (2 arq), `-45` (1 arq), `-90` (1 arq), `-135` (1 arq) |
| 25 | `dots/ellipse @cx` | 13 | 97 | `-198` (3 arq), `-219` (3 arq), `192` (2 arq), `96` (2 arq), `-225` (2 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 111 |
| `2` | 91 |
| `-1` | 84 |
| `3` | 72 |
| `-2` | 56 |
| `4` | 50 |
| `-3` | 31 |
| `-4` | 29 |
| `6` | 27 |
| `-8` | 26 |
| `14` | 22 |
| `26` | 20 |
| `40` | 19 |
| `5` | 18 |
| `20` | 17 |
| `-208` | 15 |
| `34` | 15 |
| `-37` | 14 |
| `-180` | 13 |
| `-9` | 13 |
| `-5` | 12 |
| `12` | 12 |
| `28` | 12 |
| `90` | 11 |
| `-36` | 10 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `system` | 48 |
| `slur` | 45 |
| `staff` | 38 |
| `note` | 20 |
| `tie` | 19 |
| `stem` | 16 |
| `dir` | 6 |
| `beam` | 6 |
| `tupletNum` | 6 |
| `dynam` | 6 |
| `syl` | 5 |
| `dots` | 4 |
| `dot` | 3 |
| `ledgerLines` | 3 |
| `voltaBracket` | 2 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| rest/rest-010 | 1 |
| breath/breath-002 | 2 |
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
| annot/annot-001 | 3 |
| artic/artic-003 | 3 |
| dynam/dynam-010 | 3 |
| note/note-003 | 3 |
| rend/rend-003 | 3 |
| barline/barline-009 | 4 |
| btrem/btrem-004 | 4 |
| chord/chord-006 | 4 |
| chord/chord-007 | 4 |
| dot/dot-001 | 4 |
| dynam/dynam-002 | 4 |

