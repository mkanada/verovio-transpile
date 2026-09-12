# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-11 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 627
- Arquivos com divergência numérica: 43
- Divergências (nível de número): 12278
- Assinaturas distintas (classe/tag @atributo): 42
- Subárvores podadas por divergência estrutural: 8

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 21 | 2288 | `1` (3 arq), `-356` (2 arq), `-355` (1 arq), `-354` (1 arq), `-536` (1 arq) |
| 2 | `beam/polygon @points` | 17 | 2836 | `-356` (2 arq), `-1` (2 arq), `-355` (1 arq), `-354` (1 arq), `-536` (1 arq) |
| 3 | `staff/path @d` | 17 | 2170 | `1` (3 arq), `-356` (2 arq), `-1` (2 arq), `-2` (2 arq), `-355` (1 arq) |
| 4 | `notehead/use @transform` | 17 | 1267 | `-356` (2 arq), `1` (2 arq), `-355` (1 arq), `-354` (1 arq), `-536` (1 arq) |
| 5 | `barLine/path @d` | 17 | 704 | `1` (3 arq), `-356` (2 arq), `-1` (2 arq), `-2` (2 arq), `-355` (1 arq) |
| 6 | `slur/path @d` | 17 | 260 | `-1` (10 arq), `1` (9 arq), `-2` (6 arq), `-355` (2 arq), `-356` (2 arq) |
| 7 | `clef/use @transform` | 15 | 56 | `-356` (2 arq), `1` (2 arq), `-355` (1 arq), `-64` (1 arq), `-19` (1 arq) |
| 8 | `ledgerLines/path @d` | 11 | 602 | `-356` (2 arq), `1` (2 arq), `-604` (1 arq), `-355` (1 arq), `-536` (1 arq) |
| 9 | `meterSig/use @transform` | 11 | 34 | `-356` (2 arq), `1` (2 arq), `-64` (1 arq), `22` (1 arq), `8` (1 arq) |
| 10 | `accid/use @transform` | 10 | 170 | `-356` (2 arq), `-556` (1 arq), `-604` (1 arq), `-536` (1 arq), `22` (1 arq) |
| 11 | `rest/use @transform` | 10 | 147 | `-356` (2 arq), `-355` (1 arq), `-604` (1 arq), `-19` (1 arq), `-64` (1 arq) |
| 12 | `system/path @d` | 10 | 45 | `-356` (2 arq), `-355` (1 arq), `-19` (1 arq), `-64` (1 arq), `22` (1 arq) |
| 13 | `grpSym/path @d` | 9 | 304 | `-356` (2 arq), `-355` (1 arq), `-19` (1 arq), `-64` (1 arq), `22` (1 arq) |
| 14 | `mNum/text @y` | 9 | 24 | `-356` (2 arq), `8` (1 arq), `-355` (1 arq), `-19` (1 arq), `-64` (1 arq) |
| 15 | `dots/ellipse @cy` | 8 | 95 | `-180` (3 arq), `-356` (2 arq), `720` (2 arq), `8` (1 arq), `-556` (1 arq) |
| 16 | `tupletNum/use @transform` | 8 | 15 | `-180` (3 arq), `9` (2 arq), `-1` (1 arq), `-356` (1 arq), `99` (1 arq) |
| 17 | `keyAccid/use @transform` | 6 | 94 | `-356` (2 arq), `-1` (1 arq), `-19` (1 arq), `-11` (1 arq), `-5` (1 arq) |
| 18 | `dir/text @y` | 6 | 23 | `1` (2 arq), `-355` (1 arq), `-356` (1 arq), `3` (1 arq), `2` (1 arq) |
| 19 | `label/text @y` | 6 | 11 | `8` (1 arq), `-356` (1 arq), `-64` (1 arq), `22` (1 arq), `-1` (1 arq) |
| 20 | `tie/path @d` | 5 | 349 | `-1` (2 arq), `-356` (1 arq), `-536` (1 arq), `-604` (1 arq), `-357` (1 arq) |
| 21 | `artic/use @transform` | 5 | 171 | `-356` (2 arq), `-355` (1 arq), `-556` (1 arq), `-354` (1 arq), `-536` (1 arq) |
| 22 | `flag/use @transform` | 5 | 88 | `-356` (1 arq), `-556` (1 arq), `-604` (1 arq), `-64` (1 arq), `8` (1 arq) |
| 23 | `dynam/use @transform` | 4 | 14 | `-356` (2 arq), `-355` (1 arq), `-354` (1 arq), `-536` (1 arq), `-1` (1 arq) |
| 24 | `oStaff/path @d` | 3 | 150 | `13` (2 arq), `-11` (1 arq), `-2` (1 arq), `-7` (1 arq), `-4` (1 arq) |
| 25 | `hairpin/polyline @points` | 3 | 39 | `-355` (1 arq), `-356` (1 arq), `-354` (1 arq), `-536` (1 arq), `15` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `-1` | 15 |
| `1` | 12 |
| `-2` | 9 |
| `-180` | 7 |
| `4` | 4 |
| `-356` | 3 |
| `-5` | 3 |
| `-3` | 3 |
| `2` | 3 |
| `3` | 3 |
| `9` | 3 |
| `-355` | 2 |
| `-354` | 2 |
| `-95` | 2 |
| `-14` | 2 |
| `-8` | 2 |
| `-7` | 2 |
| `6` | 2 |
| `13` | 2 |
| `18` | 2 |
| `208` | 2 |
| `720` | 2 |
| `-1890` | 1 |
| `-666` | 1 |
| `-604` | 1 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `system` | 10 |
| `slur` | 7 |
| `staff` | 7 |
| `tupletNum` | 6 |
| `beam` | 3 |
| `stem` | 2 |
| `oStaff` | 2 |
| `dots` | 2 |
| `notehead` | 1 |
| `dynam` | 1 |
| `octave` | 1 |
| `tie` | 1 |

## Fila de menor custo — arquivos a poucos números do limpo

| Arquivo | Divergências (nível de número) |
|---|---|
| choice/choice-001 | 1 |
| rest/rest-010 | 1 |
| section/section-001 | 1 |
| space/space-001 | 1 |
| beam/beam-026 | 2 |
| tuplet/tuplet-022 | 2 |
| dynam/dynam-006 | 3 |
| chord/chord-007 | 4 |
| note/note-008 | 4 |
| cross-staff/cross-staff-005 | 5 |
| ossia/ossia-001 | 5 |
| ossia/ossia-002 | 5 |
| rest/rest-001 | 5 |
| slur/slur-006 | 5 |
| octave/octave-001 | 6 |
| gracenote/gracenote-025 | 7 |
| beam/beam-060 | 8 |
| gracenote/gracenote-021 | 8 |
| pedal/pedal-001 | 8 |
| gracenote/gracenote-011 | 9 |
| tuplet/tuplet-014 | 9 |
| gracenote/gracenote-022 | 10 |
| rest/rest-019 | 10 |
| tie/tie-009 | 13 |
| tab/tab-004 | 16 |

