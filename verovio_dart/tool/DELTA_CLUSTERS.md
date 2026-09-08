# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-07 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 129
- Divergências (nível de número): 15773
- Assinaturas distintas (classe/tag @atributo): 77
- Subárvores podadas por divergência estrutural: 11

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 56 | 2207 | `96` (5 arq), `-1` (4 arq), `1` (3 arq), `2` (3 arq), `-60` (3 arq) |
| 2 | `staff/path @d` | 54 | 3657 | `96` (5 arq), `-1` (4 arq), `1` (4 arq), `-2` (3 arq), `-316` (3 arq) |
| 3 | `barLine/path @d` | 52 | 1226 | `96` (5 arq), `-1` (4 arq), `1` (4 arq), `-10` (3 arq), `-2` (3 arq) |
| 4 | `notehead/use @transform` | 48 | 1192 | `96` (5 arq), `-1` (3 arq), `2` (3 arq), `192` (2 arq), `14` (2 arq) |
| 5 | `slur/path @d` | 47 | 1091 | `1` (19 arq), `-1` (14 arq), `2` (14 arq), `95` (10 arq), `3` (8 arq) |
| 6 | `beam/polygon @points` | 36 | 1960 | `96` (4 arq), `-1` (3 arq), `14` (2 arq), `192` (2 arq), `550` (2 arq) |
| 7 | `ledgerLines/path @d` | 32 | 675 | `-1` (3 arq), `96` (3 arq), `1` (2 arq), `192` (2 arq), `-17` (1 arq) |
| 8 | `clef/use @transform` | 31 | 103 | `-1` (3 arq), `1` (2 arq), `76` (1 arq), `-46` (1 arq), `-113` (1 arq) |
| 9 | `accid/use @transform` | 27 | 134 | `96` (3 arq), `192` (2 arq), `56` (2 arq), `43` (1 arq), `-1` (1 arq) |
| 10 | `meterSig/use @transform` | 25 | 100 | `-1` (3 arq), `1` (2 arq), `-113` (1 arq), `-46` (1 arq), `-97` (1 arq) |
| 11 | `rest/use @transform` | 21 | 235 | `-1` (2 arq), `2` (2 arq), `-22` (1 arq), `-60` (1 arq), `-46` (1 arq) |
| 12 | `dots/ellipse @cy` | 21 | 140 | `-180` (5 arq), `360` (4 arq), `540` (4 arq), `1080` (3 arq), `180` (2 arq) |
| 13 | `system/path @d` | 19 | 51 | `-1` (2 arq), `-46` (1 arq), `76` (1 arq), `-17` (1 arq), `-360` (1 arq) |
| 14 | `grpSym/path @d` | 17 | 344 | `-1` (2 arq), `76` (1 arq), `-46` (1 arq), `-17` (1 arq), `-360` (1 arq) |
| 15 | `keyAccid/use @transform` | 17 | 202 | `-1` (3 arq), `-316` (2 arq), `-113` (1 arq), `76` (1 arq), `-125` (1 arq) |
| 16 | `mNum/text @y` | 14 | 24 | `-1` (2 arq), `8` (1 arq), `-46` (1 arq), `76` (1 arq), `372` (1 arq) |
| 17 | `flag/use @transform` | 13 | 62 | `-90` (2 arq), `-12` (1 arq), `-97` (1 arq), `-64` (1 arq), `8` (1 arq) |
| 18 | `dots/ellipse @cx` | 11 | 88 | `-198` (3 arq), `-219` (3 arq), `192` (2 arq), `96` (2 arq), `-225` (2 arq) |
| 19 | `artic/use @transform` | 11 | 57 | `-1` (1 arq), `-46` (1 arq), `-10` (1 arq), `449` (1 arq), `-141` (1 arq) |
| 20 | `tupletNum/use @transform` | 11 | 38 | `-180` (3 arq), `-1` (2 arq), `76` (1 arq), `-46` (1 arq), `123` (1 arq) |
| 21 | `tie/path @d` | 10 | 333 | `-1` (3 arq), `14` (2 arq), `192` (1 arq), `96` (1 arq), `-98` (1 arq) |
| 22 | `label/text @y` | 10 | 18 | `8` (1 arq), `-113` (1 arq), `-23` (1 arq), `-17` (1 arq), `-64` (1 arq) |
| 23 | `dynam/use @transform` | 10 | 14 | `-1` (2 arq), `-10` (1 arq), `-17` (1 arq), `98` (1 arq), `90` (1 arq) |
| 24 | `dir/text @y` | 9 | 12 | `1` (4 arq), `-1` (2 arq), `-121` (1 arq), `3` (1 arq), `2` (1 arq) |
| 25 | `fermata/use @transform` | 8 | 18 | `1` (3 arq), `-97` (1 arq), `-139` (1 arq), `-360` (1 arq), `3` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 27 |
| `-1` | 19 |
| `2` | 18 |
| `-180` | 15 |
| `-2` | 13 |
| `3` | 11 |
| `95` | 11 |
| `-3` | 10 |
| `-22` | 7 |
| `-6` | 7 |
| `-5` | 7 |
| `23` | 7 |
| `180` | 7 |
| `-90` | 6 |
| `-14` | 6 |
| `4` | 6 |
| `13` | 6 |
| `14` | 6 |
| `15` | 6 |
| `25` | 6 |
| `96` | 6 |
| `-400` | 5 |
| `-21` | 5 |
| `-16` | 5 |
| `-10` | 5 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 30 |
| `slur` | 21 |
| `system` | 18 |
| `stem` | 7 |
| `tupletNum` | 6 |
| `voltaBracket` | 5 |
| `dots` | 5 |
| `syl` | 5 |
| `beam` | 3 |
| `dir` | 3 |
| `dot` | 3 |
| `ledgerLines` | 3 |
| `dynam` | 2 |
| `tie` | 2 |
| `arpeg` | 1 |

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
| mensural/mensural-006 | 2 |
| ossia/ossia-004 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| artic/artic-003 | 3 |
| dynam/dynam-006 | 3 |
| dynam/dynam-010 | 3 |
| note/note-003 | 3 |
| chord/chord-007 | 4 |
| dot/dot-001 | 4 |
| note/note-008 | 4 |
| stem/stem-015 | 4 |
| tuplet/tuplet-001 | 4 |
| mensural/mensural-001 | 5 |
| neume/neume-002 | 5 |
| neume/neume-004 | 5 |
| neume/neume-006 | 5 |

