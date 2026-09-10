# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-09 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 102
- Divergências (nível de número): 13083
- Assinaturas distintas (classe/tag @atributo): 69
- Subárvores podadas por divergência estrutural: 1

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 43 | 1830 | `-1` (4 arq), `1` (3 arq), `8` (2 arq), `2` (2 arq), `157` (2 arq) |
| 2 | `staff/path @d` | 41 | 3097 | `-1` (4 arq), `1` (4 arq), `-10` (2 arq), `2` (2 arq), `-2` (2 arq) |
| 3 | `barLine/path @d` | 40 | 1005 | `-1` (4 arq), `1` (4 arq), `-10` (3 arq), `-2` (2 arq), `2` (2 arq) |
| 4 | `notehead/use @transform` | 37 | 965 | `-1` (3 arq), `2` (2 arq), `1` (2 arq), `-106` (2 arq), `162` (2 arq) |
| 5 | `slur/path @d` | 35 | 639 | `1` (18 arq), `-1` (15 arq), `2` (12 arq), `-2` (8 arq), `3` (6 arq) |
| 6 | `beam/polygon @points` | 29 | 1772 | `-1` (3 arq), `550` (2 arq), `472` (2 arq), `628` (2 arq), `108` (2 arq) |
| 7 | `clef/use @transform` | 27 | 91 | `-1` (3 arq), `1` (2 arq), `-46` (1 arq), `-113` (1 arq), `-125` (1 arq) |
| 8 | `ledgerLines/path @d` | 24 | 572 | `-1` (3 arq), `1` (2 arq), `-46` (1 arq), `1071` (1 arq), `-17` (1 arq) |
| 9 | `accid/use @transform` | 23 | 94 | `101` (3 arq), `43` (1 arq), `-1` (1 arq), `-46` (1 arq), `-312` (1 arq) |
| 10 | `meterSig/use @transform` | 20 | 87 | `-1` (3 arq), `1` (2 arq), `-113` (1 arq), `-46` (1 arq), `-97` (1 arq) |
| 11 | `rest/use @transform` | 18 | 223 | `-1` (2 arq), `2` (2 arq), `-22` (1 arq), `-46` (1 arq), `-19` (1 arq) |
| 12 | `dots/ellipse @cy` | 17 | 133 | `360` (4 arq), `-180` (4 arq), `540` (3 arq), `180` (2 arq), `720` (2 arq) |
| 13 | `system/path @d` | 16 | 45 | `-1` (2 arq), `-46` (1 arq), `-17` (1 arq), `-19` (1 arq), `-64` (1 arq) |
| 14 | `grpSym/path @d` | 14 | 302 | `-1` (2 arq), `-46` (1 arq), `-17` (1 arq), `-19` (1 arq), `-64` (1 arq) |
| 15 | `keyAccid/use @transform` | 13 | 174 | `-1` (3 arq), `-46` (1 arq), `-113` (1 arq), `-125` (1 arq), `-12` (1 arq) |
| 16 | `mNum/text @y` | 12 | 22 | `-1` (2 arq), `8` (1 arq), `-46` (1 arq), `-19` (1 arq), `-64` (1 arq) |
| 17 | `tupletNum/use @transform` | 10 | 36 | `-180` (3 arq), `-1` (2 arq), `-46` (1 arq), `123` (1 arq), `-138` (1 arq) |
| 18 | `label/text @y` | 10 | 18 | `8` (1 arq), `-46` (1 arq), `-113` (1 arq), `-23` (1 arq), `-17` (1 arq) |
| 19 | `artic/use @transform` | 9 | 47 | `-46` (1 arq), `-1` (1 arq), `-10` (1 arq), `-141` (1 arq), `-64` (1 arq) |
| 20 | `dir/text @y` | 9 | 11 | `1` (4 arq), `-1` (2 arq), `3` (1 arq), `2` (1 arq), `549` (1 arq) |
| 21 | `tie/path @d` | 8 | 202 | `-1` (3 arq), `1071` (1 arq), `43` (1 arq), `1004` (1 arq), `-720` (1 arq) |
| 22 | `dots/ellipse @cx` | 8 | 53 | `-198` (3 arq), `-219` (3 arq), `-225` (2 arq), `-519` (2 arq), `162` (2 arq) |
| 23 | `flag/use @transform` | 8 | 48 | `-12` (1 arq), `-97` (1 arq), `-64` (1 arq), `8` (1 arq), `-17` (1 arq) |
| 24 | `fermata/use @transform` | 8 | 15 | `1` (3 arq), `-139` (1 arq), `-97` (1 arq), `85` (1 arq), `-1` (1 arq) |
| 25 | `dynam/use @transform` | 8 | 11 | `-1` (2 arq), `-10` (1 arq), `-17` (1 arq), `90` (1 arq), `-90` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 26 |
| `-1` | 20 |
| `2` | 14 |
| `-2` | 13 |
| `-180` | 12 |
| `-3` | 9 |
| `3` | 8 |
| `-5` | 7 |
| `-22` | 6 |
| `16` | 6 |
| `-400` | 5 |
| `-21` | 5 |
| `-14` | 5 |
| `-6` | 5 |
| `-4` | 5 |
| `13` | 5 |
| `22` | 5 |
| `23` | 5 |
| `360` | 5 |
| `-87` | 4 |
| `-37` | 4 |
| `-26` | 4 |
| `-12` | 4 |
| `-10` | 4 |
| `-7` | 4 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 21 |
| `slur` | 16 |
| `system` | 15 |
| `tupletNum` | 5 |
| `voltaBracket` | 5 |
| `dots` | 5 |
| `syl` | 5 |
| `stem` | 4 |
| `beam` | 3 |
| `notehead` | 2 |
| `accid` | 2 |
| `dir` | 2 |
| `dynam` | 2 |
| `tie` | 2 |
| `arpeg` | 1 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| cross-staff/cross-staff-014 | 1 |
| dir/dir-001 | 1 |
| dir/dir-007 | 1 |
| mordent/mordent-003 | 1 |
| rest/rest-010 | 1 |
| space/space-001 | 1 |
| beam/beam-026 | 2 |
| breath/breath-002 | 2 |
| ossia/ossia-004 | 2 |
| trill/trill-005 | 2 |
| tuplet/tuplet-022 | 2 |
| artic/artic-003 | 3 |
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

