# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-09 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 89
- Divergências (nível de número): 9400
- Assinaturas distintas (classe/tag @atributo): 67
- Subárvores podadas por divergência estrutural: 1

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 35 | 1194 | `1` (3 arq), `8` (2 arq), `-1` (2 arq), `2` (2 arq), `157` (2 arq) |
| 2 | `staff/path @d` | 34 | 2307 | `1` (4 arq), `-1` (2 arq), `2` (2 arq), `-2` (2 arq), `-78` (2 arq) |
| 3 | `barLine/path @d` | 33 | 759 | `1` (4 arq), `-1` (2 arq), `-2` (2 arq), `2` (2 arq), `-10` (2 arq) |
| 4 | `notehead/use @transform` | 30 | 601 | `2` (2 arq), `1` (2 arq), `-106` (2 arq), `162` (2 arq), `-12` (1 arq) |
| 5 | `slur/path @d` | 25 | 360 | `1` (17 arq), `-1` (13 arq), `2` (10 arq), `-2` (7 arq), `3` (5 arq) |
| 6 | `beam/polygon @points` | 22 | 1264 | `550` (2 arq), `472` (2 arq), `628` (2 arq), `108` (2 arq), `314` (2 arq) |
| 7 | `clef/use @transform` | 20 | 62 | `1` (2 arq), `-113` (1 arq), `-125` (1 arq), `-12` (1 arq), `-64` (1 arq) |
| 8 | `ledgerLines/path @d` | 17 | 396 | `1` (2 arq), `1071` (1 arq), `-141` (1 arq), `-1` (1 arq), `221` (1 arq) |
| 9 | `accid/use @transform` | 17 | 59 | `101` (3 arq), `-312` (1 arq), `1071` (1 arq), `-141` (1 arq), `21` (1 arq) |
| 10 | `dots/ellipse @cy` | 13 | 88 | `360` (4 arq), `-180` (4 arq), `540` (3 arq), `180` (2 arq), `720` (2 arq) |
| 11 | `meterSig/use @transform` | 13 | 59 | `1` (2 arq), `-113` (1 arq), `-97` (1 arq), `2626` (1 arq), `-64` (1 arq) |
| 12 | `rest/use @transform` | 12 | 202 | `2` (2 arq), `-22` (1 arq), `-19` (1 arq), `-64` (1 arq), `221` (1 arq) |
| 13 | `system/path @d` | 10 | 20 | `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `8` (1 arq), `-113` (1 arq) |
| 14 | `mNum/text @y` | 9 | 14 | `8` (1 arq), `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `-12` (1 arq) |
| 15 | `grpSym/path @d` | 8 | 118 | `-19` (1 arq), `-64` (1 arq), `21` (1 arq), `-113` (1 arq), `-125` (1 arq) |
| 16 | `dots/ellipse @cx` | 8 | 53 | `-198` (3 arq), `-219` (3 arq), `-225` (2 arq), `-519` (2 arq), `162` (2 arq) |
| 17 | `tupletNum/use @transform` | 8 | 18 | `-180` (3 arq), `9` (2 arq), `-1` (1 arq), `123` (1 arq), `-138` (1 arq) |
| 18 | `label/text @y` | 8 | 12 | `8` (1 arq), `-113` (1 arq), `-64` (1 arq), `21` (1 arq), `-12` (1 arq) |
| 19 | `flag/use @transform` | 7 | 45 | `-12` (1 arq), `-97` (1 arq), `-64` (1 arq), `8` (1 arq), `231` (1 arq) |
| 20 | `syl/text @y` | 6 | 149 | `-400` (5 arq), `8` (1 arq) |
| 21 | `keyAccid/use @transform` | 6 | 96 | `-113` (1 arq), `-125` (1 arq), `-12` (1 arq), `-1` (1 arq), `-19` (1 arq) |
| 22 | `fermata/use @transform` | 6 | 11 | `1` (2 arq), `-139` (1 arq), `-97` (1 arq), `85` (1 arq), `418` (1 arq) |
| 23 | `tie/path @d` | 5 | 160 | `-1` (2 arq), `1071` (1 arq), `1004` (1 arq), `-720` (1 arq), `-729` (1 arq) |
| 24 | `voltaBracket/path @d` | 5 | 54 | `189` (3 arq), `54` (1 arq), `99` (1 arq), `27` (1 arq) |
| 25 | `voltaBracket/text @y` | 5 | 9 | `189` (3 arq), `54` (1 arq), `99` (1 arq), `27` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `1` | 21 |
| `-1` | 17 |
| `-180` | 12 |
| `-2` | 12 |
| `2` | 12 |
| `-3` | 8 |
| `3` | 7 |
| `-400` | 5 |
| `-5` | 5 |
| `360` | 5 |
| `-12` | 4 |
| `-4` | 4 |
| `5` | 4 |
| `9` | 4 |
| `180` | 4 |
| `-219` | 3 |
| `-198` | 3 |
| `-90` | 3 |
| `-56` | 3 |
| `-55` | 3 |
| `-54` | 3 |
| `-14` | 3 |
| `-6` | 3 |
| `13` | 3 |
| `16` | 3 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `staff` | 20 |
| `slur` | 12 |
| `system` | 9 |
| `tupletNum` | 6 |
| `dots` | 6 |
| `voltaBracket` | 5 |
| `syl` | 5 |
| `stem` | 4 |
| `accid` | 3 |
| `beam` | 2 |
| `notehead` | 2 |
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
| section/section-001 | 1 |
| space/space-001 | 1 |
| beam/beam-026 | 2 |
| breath/breath-002 | 2 |
| cross-staff/cross-staff-019 | 2 |
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

