# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-07 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 173
- Divergências (nível de número): 23006
- Assinaturas distintas (classe/tag @atributo): 85
- Subárvores podadas por divergência estrutural: 15

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 85 | 3666 | `-208` (14 arq), `90` (8 arq), `1` (7 arq), `2` (6 arq), `-45` (5 arq) |
| 2 | `staff/path @d` | 79 | 4947 | `90` (7 arq), `1` (7 arq), `96` (5 arq), `-1` (3 arq), `414` (3 arq) |
| 3 | `notehead/use @transform` | 74 | 1959 | `90` (9 arq), `1` (6 arq), `96` (5 arq), `2` (5 arq), `-36` (5 arq) |
| 4 | `barLine/path @d` | 74 | 1603 | `1` (7 arq), `90` (6 arq), `96` (5 arq), `-1` (3 arq), `-10` (3 arq) |
| 5 | `beam/polygon @points` | 59 | 3154 | `-208` (12 arq), `1` (6 arq), `90` (5 arq), `2` (4 arq), `96` (4 arq) |
| 6 | `clef/use @transform` | 55 | 164 | `1` (5 arq), `90` (3 arq), `-9` (3 arq), `414` (3 arq), `-1` (2 arq) |
| 7 | `slur/path @d` | 54 | 1231 | `1` (26 arq), `-1` (18 arq), `2` (18 arq), `95` (10 arq), `3` (9 arq) |
| 8 | `ledgerLines/path @d` | 45 | 1137 | `1` (5 arq), `-1` (3 arq), `96` (3 arq), `414` (2 arq), `192` (2 arq) |
| 9 | `meterSig/use @transform` | 43 | 142 | `1` (5 arq), `-9` (3 arq), `414` (2 arq), `43` (2 arq), `2` (2 arq) |
| 10 | `system/path @d` | 39 | 84 | `1` (4 arq), `90` (3 arq), `414` (3 arq), `-1` (2 arq), `43` (2 arq) |
| 11 | `grpSym/path @d` | 35 | 566 | `1` (5 arq), `45` (3 arq), `207` (3 arq), `90` (3 arq), `414` (3 arq) |
| 12 | `accid/use @transform` | 35 | 187 | `1` (4 arq), `96` (3 arq), `414` (2 arq), `192` (2 arq), `43` (1 arq) |
| 13 | `rest/use @transform` | 29 | 270 | `1` (3 arq), `90` (3 arq), `2` (3 arq), `10` (2 arq), `8` (2 arq) |
| 14 | `keyAccid/use @transform` | 27 | 250 | `1` (4 arq), `-1` (2 arq), `-316` (2 arq), `414` (2 arq), `-113` (1 arq) |
| 15 | `flag/use @transform` | 27 | 213 | `1` (5 arq), `-45` (3 arq), `-90` (3 arq), `90` (2 arq), `-12` (1 arq) |
| 16 | `dots/ellipse @cy` | 24 | 157 | `540` (4 arq), `-180` (4 arq), `360` (3 arq), `414` (2 arq), `180` (2 arq) |
| 17 | `mNum/text @y` | 21 | 32 | `1` (4 arq), `8` (1 arq), `90` (1 arq), `-46` (1 arq), `76` (1 arq) |
| 18 | `dynam/use @transform` | 18 | 31 | `-9` (2 arq), `-5` (2 arq), `525` (2 arq), `-354` (2 arq), `208` (1 arq) |
| 19 | `tupletNum/use @transform` | 16 | 52 | `-1` (4 arq), `90` (2 arq), `-180` (2 arq), `76` (1 arq), `-46` (1 arq) |
| 20 | `artic/use @transform` | 15 | 200 | `1` (4 arq), `-45` (1 arq), `-90` (1 arq), `-135` (1 arq), `32` (1 arq) |
| 21 | `dir/text @y` | 15 | 42 | `-404` (2 arq), `90` (2 arq), `-23` (2 arq), `-9` (2 arq), `442` (2 arq) |
| 22 | `dots/ellipse @cx` | 13 | 97 | `-198` (3 arq), `-219` (3 arq), `192` (2 arq), `96` (2 arq), `-225` (2 arq) |
| 23 | `tie/path @d` | 12 | 457 | `2` (3 arq), `-1` (2 arq), `90` (2 arq), `1` (2 arq), `414` (1 arq) |
| 24 | `label/text @y` | 11 | 20 | `8` (1 arq), `-113` (1 arq), `-23` (1 arq), `152` (1 arq), `-21` (1 arq) |
| 25 | `arpeg/use @transform` | 9 | 246 | `54` (3 arq), `-149` (2 arq), `-21` (1 arq), `-198` (1 arq), `-291` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 31 |
| `-1` | 25 |
| `2` | 24 |
| `-2` | 16 |
| `-208` | 14 |
| `-180` | 13 |
| `3` | 13 |
| `-3` | 12 |
| `95` | 11 |
| `-9` | 10 |
| `-5` | 10 |
| `-4` | 9 |
| `4` | 9 |
| `90` | 9 |
| `-90` | 8 |
| `-6` | 8 |
| `15` | 8 |
| `23` | 8 |
| `25` | 8 |
| `45` | 8 |
| `54` | 8 |
| `-95` | 7 |
| `-22` | 7 |
| `-12` | 7 |
| `13` | 7 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `system` | 39 |
| `staff` | 35 |
| `slur` | 21 |
| `dir` | 8 |
| `stem` | 8 |
| `beam` | 8 |
| `tupletNum` | 7 |
| `dynam` | 7 |
| `dots` | 5 |
| `syl` | 5 |
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
| btrem/btrem-004 | 4 |

