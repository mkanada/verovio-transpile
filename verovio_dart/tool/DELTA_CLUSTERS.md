# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-07 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 150
- Divergências (nível de número): 19479
- Assinaturas distintas (classe/tag @atributo): 86
- Subárvores podadas por divergência estrutural: 11

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 68 | 2882 | `-1` (6 arq), `90` (5 arq), `96` (5 arq), `2` (5 arq), `-36` (5 arq) |
| 2 | `staff/path @d` | 67 | 4532 | `-1` (5 arq), `96` (5 arq), `1` (4 arq), `414` (4 arq), `90` (3 arq) |
| 3 | `barLine/path @d` | 64 | 1498 | `-1` (5 arq), `96` (5 arq), `1` (4 arq), `414` (4 arq), `90` (3 arq) |
| 4 | `notehead/use @transform` | 61 | 1644 | `-1` (5 arq), `96` (5 arq), `90` (5 arq), `2` (5 arq), `-36` (5 arq) |
| 5 | `slur/path @d` | 46 | 1094 | `1` (18 arq), `-1` (14 arq), `2` (14 arq), `95` (10 arq), `3` (9 arq) |
| 6 | `beam/polygon @points` | 42 | 2170 | `-1` (5 arq), `96` (4 arq), `90` (3 arq), `-45` (3 arq), `2` (3 arq) |
| 7 | `clef/use @transform` | 42 | 139 | `-1` (4 arq), `414` (4 arq), `17` (2 arq), `1` (2 arq), `76` (1 arq) |
| 8 | `ledgerLines/path @d` | 38 | 1067 | `-1` (5 arq), `96` (3 arq), `414` (2 arq), `1` (2 arq), `192` (2 arq) |
| 9 | `meterSig/use @transform` | 34 | 119 | `-1` (3 arq), `414` (3 arq), `1` (2 arq), `-113` (1 arq), `-46` (1 arq) |
| 10 | `accid/use @transform` | 30 | 163 | `96` (3 arq), `-1` (2 arq), `414` (2 arq), `14` (2 arq), `192` (2 arq) |
| 11 | `system/path @d` | 28 | 66 | `414` (4 arq), `-1` (3 arq), `-46` (1 arq), `76` (1 arq), `-21` (1 arq) |
| 12 | `rest/use @transform` | 25 | 262 | `-1` (3 arq), `2` (3 arq), `90` (2 arq), `10` (2 arq), `14` (2 arq) |
| 13 | `grpSym/path @d` | 24 | 422 | `207` (4 arq), `414` (4 arq), `-1` (3 arq), `76` (1 arq), `-46` (1 arq) |
| 14 | `keyAccid/use @transform` | 22 | 223 | `-1` (4 arq), `414` (3 arq), `-316` (2 arq), `-113` (1 arq), `76` (1 arq) |
| 15 | `dots/ellipse @cy` | 22 | 154 | `540` (4 arq), `-180` (4 arq), `360` (3 arq), `414` (2 arq), `180` (2 arq) |
| 16 | `flag/use @transform` | 17 | 84 | `90` (2 arq), `-90` (2 arq), `-12` (1 arq), `-97` (1 arq), `152` (1 arq) |
| 17 | `dir/text @y` | 16 | 39 | `1` (4 arq), `-404` (2 arq), `-1` (2 arq), `442` (2 arq), `414` (1 arq) |
| 18 | `mNum/text @y` | 16 | 27 | `-1` (2 arq), `8` (1 arq), `-46` (1 arq), `76` (1 arq), `17` (1 arq) |
| 19 | `dynam/use @transform` | 13 | 24 | `525` (2 arq), `-354` (2 arq), `-1` (2 arq), `207` (1 arq), `-10` (1 arq) |
| 20 | `tie/path @d` | 12 | 457 | `-1` (3 arq), `14` (2 arq), `1` (2 arq), `2` (2 arq), `414` (1 arq) |
| 21 | `dots/ellipse @cx` | 12 | 89 | `-198` (3 arq), `-219` (3 arq), `192` (2 arq), `96` (2 arq), `-225` (2 arq) |
| 22 | `tupletNum/use @transform` | 12 | 45 | `-180` (3 arq), `-1` (2 arq), `76` (1 arq), `-46` (1 arq), `90` (1 arq) |
| 23 | `artic/use @transform` | 11 | 58 | `-1` (1 arq), `-46` (1 arq), `-10` (1 arq), `-141` (1 arq), `-64` (1 arq) |
| 24 | `label/text @y` | 11 | 20 | `8` (1 arq), `-113` (1 arq), `-23` (1 arq), `152` (1 arq), `-21` (1 arq) |
| 25 | `arpeg/use @transform` | 9 | 246 | `54` (3 arq), `-149` (2 arq), `-21` (1 arq), `-198` (1 arq), `-291` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 27 |
| `-1` | 20 |
| `2` | 20 |
| `-180` | 14 |
| `-2` | 13 |
| `3` | 13 |
| `-3` | 11 |
| `95` | 11 |
| `15` | 8 |
| `-22` | 7 |
| `-6` | 7 |
| `-5` | 7 |
| `-4` | 7 |
| `4` | 7 |
| `13` | 7 |
| `14` | 7 |
| `18` | 7 |
| `23` | 7 |
| `25` | 7 |
| `54` | 7 |
| `-36` | 6 |
| `-21` | 6 |
| `-13` | 6 |
| `-12` | 6 |
| `-10` | 6 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 35 |
| `system` | 28 |
| `slur` | 19 |
| `dir` | 8 |
| `stem` | 6 |
| `tupletNum` | 5 |
| `dynam` | 5 |
| `dots` | 5 |
| `syl` | 5 |
| `beam` | 4 |
| `voltaBracket` | 3 |
| `dot` | 3 |
| `ledgerLines` | 3 |
| `mordent` | 2 |
| `tie` | 2 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| dir/dir-001 | 1 |
| dir/dir-007 | 1 |
| mordent/mordent-003 | 1 |
| rest/rest-010 | 1 |
| space/space-001 | 1 |
| beam/beam-026 | 2 |
| breath/breath-002 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| mensural/mensural-006 | 2 |
| ossia/ossia-004 | 2 |
| rend/rend-004 | 2 |
| score/score-016 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| turn/turn-004 | 2 |
| annot/annot-001 | 3 |
| artic/artic-003 | 3 |
| dynam/dynam-010 | 3 |
| note/note-003 | 3 |
| rend/rend-003 | 3 |
| chord/chord-007 | 4 |
| dot/dot-001 | 4 |
| dynam/dynam-002 | 4 |

