# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-09 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 97
- Divergências (nível de número): 12036
- Assinaturas distintas (classe/tag @atributo): 67
- Subárvores podadas por divergência estrutural: 1

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 40 | 1602 | `1` (3 arq), `8` (2 arq), `-1` (2 arq), `2` (2 arq), `157` (2 arq) |
| 2 | `staff/path @d` | 39 | 2797 | `1` (4 arq), `-10` (2 arq), `2` (2 arq), `-1` (2 arq), `-2` (2 arq) |
| 3 | `barLine/path @d` | 38 | 939 | `1` (4 arq), `-10` (3 arq), `-1` (2 arq), `-2` (2 arq), `2` (2 arq) |
| 4 | `notehead/use @transform` | 35 | 851 | `2` (2 arq), `1` (2 arq), `-106` (2 arq), `162` (2 arq), `-46` (1 arq) |
| 5 | `slur/path @d` | 35 | 636 | `1` (18 arq), `-1` (15 arq), `2` (12 arq), `-2` (8 arq), `23` (6 arq) |
| 6 | `beam/polygon @points` | 26 | 1576 | `550` (2 arq), `472` (2 arq), `628` (2 arq), `108` (2 arq), `314` (2 arq) |
| 7 | `clef/use @transform` | 25 | 85 | `1` (2 arq), `-46` (1 arq), `-113` (1 arq), `-125` (1 arq), `-12` (1 arq) |
| 8 | `ledgerLines/path @d` | 22 | 554 | `1` (2 arq), `-46` (1 arq), `1071` (1 arq), `-17` (1 arq), `-141` (1 arq) |
| 9 | `accid/use @transform` | 22 | 85 | `101` (3 arq), `43` (1 arq), `-46` (1 arq), `-312` (1 arq), `1071` (1 arq) |
| 10 | `meterSig/use @transform` | 18 | 82 | `1` (2 arq), `-113` (1 arq), `-46` (1 arq), `-97` (1 arq), `2626` (1 arq) |
| 11 | `rest/use @transform` | 16 | 219 | `2` (2 arq), `-22` (1 arq), `-46` (1 arq), `-19` (1 arq), `-64` (1 arq) |
| 12 | `dots/ellipse @cy` | 16 | 110 | `360` (4 arq), `-180` (4 arq), `540` (3 arq), `180` (2 arq), `720` (2 arq) |
| 13 | `system/path @d` | 15 | 43 | `-46` (1 arq), `-17` (1 arq), `-19` (1 arq), `-64` (1 arq), `21` (1 arq) |
| 14 | `grpSym/path @d` | 13 | 288 | `-46` (1 arq), `-17` (1 arq), `-19` (1 arq), `-64` (1 arq), `21` (1 arq) |
| 15 | `keyAccid/use @transform` | 11 | 162 | `-46` (1 arq), `-113` (1 arq), `-125` (1 arq), `-12` (1 arq), `-10` (1 arq) |
| 16 | `mNum/text @y` | 11 | 19 | `8` (1 arq), `-46` (1 arq), `-19` (1 arq), `-64` (1 arq), `21` (1 arq) |
| 17 | `label/text @y` | 10 | 18 | `8` (1 arq), `-46` (1 arq), `-113` (1 arq), `-23` (1 arq), `-17` (1 arq) |
| 18 | `tupletNum/use @transform` | 9 | 34 | `-180` (3 arq), `-46` (1 arq), `-1` (1 arq), `123` (1 arq), `-138` (1 arq) |
| 19 | `dots/ellipse @cx` | 8 | 53 | `-198` (3 arq), `-219` (3 arq), `-225` (2 arq), `-519` (2 arq), `162` (2 arq) |
| 20 | `flag/use @transform` | 8 | 48 | `-12` (1 arq), `-97` (1 arq), `-64` (1 arq), `8` (1 arq), `-17` (1 arq) |
| 21 | `artic/use @transform` | 8 | 38 | `-46` (1 arq), `-10` (1 arq), `-141` (1 arq), `-64` (1 arq), `-28` (1 arq) |
| 22 | `tie/path @d` | 7 | 188 | `-1` (2 arq), `1071` (1 arq), `43` (1 arq), `1004` (1 arq), `-720` (1 arq) |
| 23 | `dynam/use @transform` | 7 | 10 | `-10` (1 arq), `-17` (1 arq), `90` (1 arq), `-90` (1 arq), `-180` (1 arq) |
| 24 | `syl/text @y` | 6 | 149 | `-400` (5 arq), `8` (1 arq) |
| 25 | `fermata/use @transform` | 6 | 11 | `1` (2 arq), `-139` (1 arq), `-97` (1 arq), `85` (1 arq), `418` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 22 |
| `-1` | 19 |
| `2` | 14 |
| `-2` | 13 |
| `-180` | 12 |
| `-3` | 9 |
| `3` | 8 |
| `-22` | 7 |
| `-5` | 7 |
| `16` | 6 |
| `23` | 6 |
| `-400` | 5 |
| `-14` | 5 |
| `-6` | 5 |
| `13` | 5 |
| `360` | 5 |
| `-87` | 4 |
| `-37` | 4 |
| `-21` | 4 |
| `-20` | 4 |
| `-12` | 4 |
| `-10` | 4 |
| `-7` | 4 |
| `-4` | 4 |
| `5` | 4 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 20 |
| `slur` | 17 |
| `system` | 14 |
| `dots` | 6 |
| `tupletNum` | 5 |
| `voltaBracket` | 5 |
| `syl` | 5 |
| `stem` | 4 |
| `beam` | 2 |
| `notehead` | 2 |
| `accid` | 2 |
| `dynam` | 2 |
| `tie` | 2 |
| `arpeg` | 1 |
| `breath` | 1 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| cross-staff/cross-staff-014 | 1 |
| rest/rest-005 | 1 |
| rest/rest-010 | 1 |
| space/space-001 | 1 |
| beam/beam-026 | 2 |
| breath/breath-002 | 2 |
| ossia/ossia-004 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| dir/dir-005 | 3 |
| dynam/dynam-006 | 3 |
| dynam/dynam-010 | 3 |
| chord/chord-007 | 4 |
| note/note-008 | 4 |
| stem/stem-015 | 4 |
| tuplet/tuplet-001 | 4 |
| neume/neume-002 | 5 |
| neume/neume-004 | 5 |
| neume/neume-006 | 5 |
| ossia/ossia-001 | 5 |
| gracenote/gracenote-022 | 6 |
| hairpin/hairpin-005 | 6 |
| octave/octave-001 | 6 |
| slur/slur-006 | 6 |

