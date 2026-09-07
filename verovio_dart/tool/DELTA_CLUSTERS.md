# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-07 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 154
- Divergências (nível de número): 19710
- Assinaturas distintas (classe/tag @atributo): 86
- Subárvores podadas por divergência estrutural: 15

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 71 | 2926 | `90` (6 arq), `96` (5 arq), `2` (5 arq), `-36` (5 arq), `-1` (4 arq) |
| 2 | `staff/path @d` | 70 | 4582 | `96` (5 arq), `90` (4 arq), `1` (4 arq), `414` (4 arq), `-1` (3 arq) |
| 3 | `barLine/path @d` | 67 | 1511 | `96` (5 arq), `90` (4 arq), `1` (4 arq), `414` (4 arq), `-1` (3 arq) |
| 4 | `notehead/use @transform` | 64 | 1666 | `90` (6 arq), `96` (5 arq), `2` (5 arq), `-36` (5 arq), `414` (4 arq) |
| 5 | `slur/path @d` | 46 | 1110 | `1` (18 arq), `-1` (14 arq), `2` (14 arq), `95` (10 arq), `3` (9 arq) |
| 6 | `clef/use @transform` | 46 | 143 | `414` (4 arq), `-9` (3 arq), `-1` (2 arq), `152` (2 arq), `17` (2 arq) |
| 7 | `beam/polygon @points` | 45 | 2190 | `90` (4 arq), `96` (4 arq), `-1` (3 arq), `-45` (3 arq), `2` (3 arq) |
| 8 | `ledgerLines/path @d` | 39 | 1077 | `-1` (3 arq), `96` (3 arq), `414` (2 arq), `1` (2 arq), `192` (2 arq) |
| 9 | `meterSig/use @transform` | 38 | 124 | `414` (3 arq), `-9` (3 arq), `1` (2 arq), `152` (2 arq), `-113` (1 arq) |
| 10 | `accid/use @transform` | 31 | 166 | `96` (3 arq), `414` (2 arq), `14` (2 arq), `192` (2 arq), `43` (1 arq) |
| 11 | `system/path @d` | 30 | 68 | `414` (4 arq), `-1` (2 arq), `-9` (2 arq), `-46` (1 arq), `76` (1 arq) |
| 12 | `grpSym/path @d` | 26 | 442 | `207` (4 arq), `414` (4 arq), `-1` (2 arq), `-9` (2 arq), `76` (1 arq) |
| 13 | `rest/use @transform` | 26 | 264 | `90` (3 arq), `2` (3 arq), `10` (2 arq), `14` (2 arq), `8` (2 arq) |
| 14 | `keyAccid/use @transform` | 23 | 225 | `414` (3 arq), `-1` (2 arq), `-316` (2 arq), `-113` (1 arq), `76` (1 arq) |
| 15 | `dots/ellipse @cy` | 22 | 154 | `540` (4 arq), `-180` (4 arq), `360` (3 arq), `414` (2 arq), `180` (2 arq) |
| 16 | `flag/use @transform` | 18 | 85 | `90` (2 arq), `-90` (2 arq), `-12` (1 arq), `-97` (1 arq), `152` (1 arq) |
| 17 | `dynam/use @transform` | 17 | 30 | `-9` (2 arq), `-5` (2 arq), `525` (2 arq), `-354` (2 arq), `207` (1 arq) |
| 18 | `dir/text @y` | 16 | 41 | `-404` (2 arq), `-23` (2 arq), `-9` (2 arq), `442` (2 arq), `1` (2 arq) |
| 19 | `mNum/text @y` | 16 | 27 | `8` (1 arq), `90` (1 arq), `-46` (1 arq), `76` (1 arq), `17` (1 arq) |
| 20 | `tupletNum/use @transform` | 13 | 46 | `-180` (3 arq), `90` (2 arq), `76` (1 arq), `-46` (1 arq), `-1` (1 arq) |
| 21 | `tie/path @d` | 12 | 457 | `-1` (2 arq), `90` (2 arq), `14` (2 arq), `1` (2 arq), `2` (2 arq) |
| 22 | `dots/ellipse @cx` | 12 | 89 | `-198` (3 arq), `-219` (3 arq), `192` (2 arq), `96` (2 arq), `-225` (2 arq) |
| 23 | `artic/use @transform` | 11 | 58 | `32` (1 arq), `-46` (1 arq), `-10` (1 arq), `-141` (1 arq), `-64` (1 arq) |
| 24 | `label/text @y` | 11 | 20 | `8` (1 arq), `-113` (1 arq), `-23` (1 arq), `152` (1 arq), `-21` (1 arq) |
| 25 | `arpeg/use @transform` | 9 | 246 | `54` (3 arq), `-149` (2 arq), `-21` (1 arq), `-198` (1 arq), `-291` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 23 |
| `2` | 20 |
| `-1` | 19 |
| `-180` | 14 |
| `-2` | 13 |
| `3` | 13 |
| `95` | 11 |
| `-9` | 10 |
| `-5` | 10 |
| `-3` | 9 |
| `-6` | 8 |
| `15` | 8 |
| `23` | 8 |
| `-22` | 7 |
| `-4` | 7 |
| `4` | 7 |
| `5` | 7 |
| `13` | 7 |
| `14` | 7 |
| `18` | 7 |
| `25` | 7 |
| `54` | 7 |
| `-36` | 6 |
| `-13` | 6 |
| `-12` | 6 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 36 |
| `system` | 30 |
| `slur` | 18 |
| `dir` | 8 |
| `dynam` | 7 |
| `stem` | 6 |
| `tupletNum` | 5 |
| `dots` | 5 |
| `syl` | 5 |
| `beam` | 4 |
| `voltaBracket` | 3 |
| `dot` | 3 |
| `ledgerLines` | 3 |
| `hairpin` | 2 |
| `tie` | 2 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| dot/dot-002 | 1 |
| rest/rest-010 | 1 |
| space/space-001 | 1 |
| beam/beam-026 | 2 |
| breath/breath-002 | 2 |
| dir/dir-001 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| mensural/mensural-006 | 2 |
| ossia/ossia-004 | 2 |
| rend/rend-004 | 2 |
| score/score-016 | 2 |
| tempo/tempo-003 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| turn/turn-004 | 2 |
| annot/annot-001 | 3 |
| artic/artic-003 | 3 |
| dir/dir-007 | 3 |
| dynam/dynam-010 | 3 |
| hairpin/hairpin-002 | 3 |
| note/note-003 | 3 |
| rend/rend-003 | 3 |
| chord/chord-007 | 4 |

