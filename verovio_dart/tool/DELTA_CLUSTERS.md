# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-07 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 166
- Divergências (nível de número): 21480
- Assinaturas distintas (classe/tag @atributo): 85
- Subárvores podadas por divergência estrutural: 15

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 75 | 3352 | `1` (7 arq), `90` (6 arq), `-45` (6 arq), `-1` (5 arq), `96` (5 arq) |
| 2 | `staff/path @d` | 73 | 4772 | `1` (7 arq), `96` (5 arq), `90` (4 arq), `-1` (4 arq), `414` (3 arq) |
| 3 | `barLine/path @d` | 70 | 1570 | `1` (7 arq), `96` (5 arq), `90` (4 arq), `-1` (4 arq), `-10` (3 arq) |
| 4 | `notehead/use @transform` | 67 | 1883 | `90` (6 arq), `1` (6 arq), `96` (5 arq), `2` (5 arq), `-36` (5 arq) |
| 5 | `slur/path @d` | 54 | 1218 | `1` (28 arq), `-1` (20 arq), `2` (17 arq), `-2` (11 arq), `95` (10 arq) |
| 6 | `clef/use @transform` | 50 | 156 | `1` (5 arq), `-1` (3 arq), `-9` (3 arq), `414` (3 arq), `152` (2 arq) |
| 7 | `beam/polygon @points` | 49 | 2390 | `1` (6 arq), `90` (4 arq), `96` (4 arq), `-1` (3 arq), `-45` (3 arq) |
| 8 | `ledgerLines/path @d` | 42 | 1105 | `1` (5 arq), `-1` (4 arq), `96` (3 arq), `414` (2 arq), `192` (2 arq) |
| 9 | `meterSig/use @transform` | 40 | 137 | `1` (5 arq), `-9` (3 arq), `414` (2 arq), `152` (2 arq), `-113` (1 arq) |
| 10 | `accid/use @transform` | 34 | 178 | `1` (4 arq), `96` (3 arq), `-1` (2 arq), `414` (2 arq), `14` (2 arq) |
| 11 | `system/path @d` | 34 | 77 | `1` (4 arq), `-1` (3 arq), `414` (3 arq), `-9` (2 arq), `-46` (1 arq) |
| 12 | `grpSym/path @d` | 30 | 502 | `1` (5 arq), `-1` (3 arq), `207` (3 arq), `414` (3 arq), `-9` (2 arq) |
| 13 | `rest/use @transform` | 29 | 270 | `1` (3 arq), `90` (3 arq), `2` (3 arq), `10` (2 arq), `14` (2 arq) |
| 14 | `keyAccid/use @transform` | 26 | 244 | `1` (4 arq), `-1` (2 arq), `-316` (2 arq), `414` (2 arq), `-113` (1 arq) |
| 15 | `flag/use @transform` | 25 | 210 | `1` (5 arq), `-45` (3 arq), `-90` (3 arq), `90` (2 arq), `-12` (1 arq) |
| 16 | `dots/ellipse @cy` | 24 | 157 | `540` (4 arq), `-180` (4 arq), `360` (3 arq), `414` (2 arq), `180` (2 arq) |
| 17 | `mNum/text @y` | 20 | 31 | `1` (4 arq), `8` (1 arq), `90` (1 arq), `-46` (1 arq), `76` (1 arq) |
| 18 | `dynam/use @transform` | 18 | 31 | `-9` (2 arq), `-5` (2 arq), `525` (2 arq), `-354` (2 arq), `208` (1 arq) |
| 19 | `tupletNum/use @transform` | 16 | 51 | `-1` (4 arq), `-180` (3 arq), `90` (2 arq), `76` (1 arq), `-46` (1 arq) |
| 20 | `artic/use @transform` | 15 | 200 | `1` (4 arq), `-45` (1 arq), `-90` (1 arq), `-135` (1 arq), `32` (1 arq) |
| 21 | `dir/text @y` | 14 | 39 | `-404` (2 arq), `-23` (2 arq), `-9` (2 arq), `442` (2 arq), `415` (1 arq) |
| 22 | `tie/path @d` | 12 | 457 | `-1` (2 arq), `90` (2 arq), `14` (2 arq), `1` (2 arq), `2` (2 arq) |
| 23 | `dots/ellipse @cx` | 12 | 89 | `-198` (3 arq), `-219` (3 arq), `192` (2 arq), `96` (2 arq), `-225` (2 arq) |
| 24 | `label/text @y` | 11 | 20 | `8` (1 arq), `-113` (1 arq), `-23` (1 arq), `152` (1 arq), `-21` (1 arq) |
| 25 | `arpeg/use @transform` | 9 | 246 | `54` (3 arq), `-149` (2 arq), `-21` (1 arq), `-198` (1 arq), `-291` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 33 |
| `-1` | 27 |
| `2` | 23 |
| `-2` | 18 |
| `-180` | 14 |
| `3` | 14 |
| `-3` | 12 |
| `-9` | 11 |
| `-5` | 11 |
| `95` | 11 |
| `4` | 9 |
| `-22` | 8 |
| `15` | 8 |
| `-45` | 7 |
| `-12` | 7 |
| `-6` | 7 |
| `-4` | 7 |
| `14` | 7 |
| `18` | 7 |
| `23` | 7 |
| `25` | 7 |
| `54` | 7 |
| `-90` | 6 |
| `-36` | 6 |
| `-13` | 6 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 34 |
| `system` | 34 |
| `slur` | 23 |
| `dir` | 8 |
| `stem` | 8 |
| `tupletNum` | 8 |
| `dynam` | 7 |
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
| beam/beam-045 | 1 |
| choice/choice-001 | 1 |
| dot/dot-002 | 1 |
| rest/rest-010 | 1 |
| slur/slur-021 | 1 |
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

