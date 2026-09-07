# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-07 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 187
- Divergências (nível de número): 22057
- Assinaturas distintas (classe/tag @atributo): 86
- Subárvores podadas por divergência estrutural: 15

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `slur/path @d` | 82 | 2041 | `-1` (65 arq), `1` (54 arq), `-2` (37 arq), `2` (35 arq), `3` (15 arq) |
| 2 | `stem/path @d` | 79 | 3285 | `2` (8 arq), `90` (6 arq), `-1` (6 arq), `-45` (6 arq), `96` (5 arq) |
| 3 | `staff/path @d` | 78 | 4752 | `-1` (6 arq), `2` (5 arq), `96` (5 arq), `90` (4 arq), `414` (4 arq) |
| 4 | `barLine/path @d` | 75 | 1553 | `-1` (6 arq), `2` (5 arq), `96` (5 arq), `90` (4 arq), `-2` (4 arq) |
| 5 | `notehead/use @transform` | 72 | 1846 | `2` (8 arq), `90` (6 arq), `-1` (6 arq), `96` (5 arq), `-36` (5 arq) |
| 6 | `clef/use @transform` | 54 | 154 | `-1` (5 arq), `2` (4 arq), `414` (4 arq), `-9` (3 arq), `152` (2 arq) |
| 7 | `beam/polygon @points` | 50 | 2390 | `-1` (5 arq), `2` (5 arq), `90` (4 arq), `96` (4 arq), `-45` (3 arq) |
| 8 | `ledgerLines/path @d` | 46 | 1199 | `2` (5 arq), `-1` (5 arq), `96` (3 arq), `414` (2 arq), `-19` (2 arq) |
| 9 | `meterSig/use @transform` | 40 | 127 | `414` (3 arq), `2` (3 arq), `-9` (3 arq), `-1` (2 arq), `152` (2 arq) |
| 10 | `accid/use @transform` | 34 | 175 | `-1` (3 arq), `96` (3 arq), `414` (2 arq), `2` (2 arq), `192` (2 arq) |
| 11 | `system/path @d` | 32 | 72 | `414` (4 arq), `-1` (3 arq), `-9` (2 arq), `-46` (1 arq), `79` (1 arq) |
| 12 | `grpSym/path @d` | 28 | 470 | `207` (4 arq), `414` (4 arq), `-1` (3 arq), `17` (2 arq), `-9` (2 arq) |
| 13 | `rest/use @transform` | 27 | 265 | `90` (3 arq), `2` (3 arq), `-1` (2 arq), `10` (2 arq), `8` (2 arq) |
| 14 | `keyAccid/use @transform` | 25 | 230 | `-1` (3 arq), `414` (3 arq), `-316` (2 arq), `-113` (1 arq), `79` (1 arq) |
| 15 | `dots/ellipse @cy` | 23 | 155 | `540` (4 arq), `-180` (4 arq), `360` (3 arq), `414` (2 arq), `180` (2 arq) |
| 16 | `flag/use @transform` | 22 | 205 | `-45` (3 arq), `-90` (3 arq), `90` (2 arq), `-12` (1 arq), `-135` (1 arq) |
| 17 | `mNum/text @y` | 19 | 30 | `-1` (2 arq), `8` (1 arq), `90` (1 arq), `-46` (1 arq), `79` (1 arq) |
| 18 | `tupletNum/use @transform` | 18 | 60 | `-1` (5 arq), `-180` (3 arq), `90` (2 arq), `79` (1 arq), `-46` (1 arq) |
| 19 | `dir/text @y` | 18 | 45 | `-404` (2 arq), `-23` (2 arq), `-1` (2 arq), `-9` (2 arq), `442` (2 arq) |
| 20 | `dynam/use @transform` | 17 | 30 | `-9` (2 arq), `-5` (2 arq), `525` (2 arq), `-354` (2 arq), `207` (1 arq) |
| 21 | `tie/path @d` | 12 | 457 | `-1` (2 arq), `90` (2 arq), `1` (2 arq), `2` (2 arq), `414` (1 arq) |
| 22 | `artic/use @transform` | 12 | 171 | `-45` (1 arq), `-90` (1 arq), `-135` (1 arq), `32` (1 arq), `-46` (1 arq) |
| 23 | `dots/ellipse @cx` | 12 | 89 | `-198` (3 arq), `-219` (3 arq), `192` (2 arq), `96` (2 arq), `-225` (2 arq) |
| 24 | `label/text @y` | 11 | 20 | `8` (1 arq), `-113` (1 arq), `-23` (1 arq), `152` (1 arq), `-19` (1 arq) |
| 25 | `fermata/use @transform` | 10 | 22 | `2` (2 arq), `-39` (1 arq), `-97` (1 arq), `-139` (1 arq), `-360` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `-1` | 72 |
| `1` | 60 |
| `-2` | 44 |
| `2` | 41 |
| `-3` | 20 |
| `3` | 20 |
| `-180` | 14 |
| `-9` | 11 |
| `-5` | 11 |
| `95` | 11 |
| `-6` | 9 |
| `-22` | 8 |
| `-4` | 8 |
| `4` | 8 |
| `15` | 8 |
| `23` | 8 |
| `25` | 8 |
| `-45` | 7 |
| `-10` | 7 |
| `5` | 7 |
| `10` | 7 |
| `14` | 7 |
| `18` | 7 |
| `54` | 7 |
| `-90` | 6 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `slur` | 47 |
| `staff` | 39 |
| `system` | 32 |
| `stem` | 8 |
| `tupletNum` | 8 |
| `dir` | 6 |
| `dynam` | 6 |
| `syl` | 5 |
| `dots` | 4 |
| `beam` | 3 |
| `dot` | 3 |
| `ledgerLines` | 3 |
| `fermata` | 2 |
| `voltaBracket` | 2 |
| `hairpin` | 2 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| rest/rest-010 | 1 |
| beam/beam-026 | 2 |
| breath/breath-002 | 2 |
| dynam/dynam-001 | 2 |
| dynam/dynam-009 | 2 |
| mensural/mensural-006 | 2 |
| ossia/ossia-004 | 2 |
| rend/rend-004 | 2 |
| score/score-016 | 2 |
| slur/slur-021 | 2 |
| space/space-001 | 2 |
| tempo/tempo-003 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| turn/turn-004 | 2 |
| annot/annot-001 | 3 |
| artic/artic-003 | 3 |
| dynam/dynam-004 | 3 |
| dynam/dynam-010 | 3 |
| lyric/lyric-013 | 3 |
| note/note-003 | 3 |
| rend/rend-003 | 3 |
| btrem/btrem-004 | 4 |
| chord/chord-007 | 4 |

