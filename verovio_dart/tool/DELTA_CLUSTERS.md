# DELTA_CLUSTERS — divergências numéricas agrupadas por causa provável

Gerado em 2026-09-11 por `dart run tool/cluster_deltas.dart` sobre `test/golden/cpp` × `test/golden/dart` (dumpados por `compare_svg.dart --all`).

- Pares comparados: 621
- Arquivos com divergência numérica: 40
- Divergências (nível de número): 3377
- Assinaturas distintas (classe/tag @atributo): 38
- Subárvores podadas por divergência estrutural: 0

> Delta = Dart − C++. Contagem em nível de número, não de atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do tool).

## Ranking por alcance — quantos arquivos cada assinatura destrava

| # | Assinatura | Arquivos | Divergências | Deltas mais compartilhados |
|---|---|---|---|---|
| 1 | `stem/path @d` | 18 | 472 | `1` (3 arq), `8` (1 arq), `-1` (1 arq), `-64` (1 arq), `15` (1 arq) |
| 2 | `slur/path @d` | 15 | 167 | `-1` (10 arq), `1` (8 arq), `-2` (6 arq), `-3` (2 arq), `4` (2 arq) |
| 3 | `staff/path @d` | 14 | 870 | `1` (3 arq), `-1` (2 arq), `-2` (2 arq), `8` (1 arq), `221` (1 arq) |
| 4 | `beam/polygon @points` | 14 | 424 | `-1` (2 arq), `15` (1 arq), `-64` (1 arq), `22` (1 arq), `221` (1 arq) |
| 5 | `barLine/path @d` | 14 | 302 | `1` (3 arq), `-1` (2 arq), `-2` (2 arq), `-11` (1 arq), `8` (1 arq) |
| 6 | `notehead/use @transform` | 14 | 268 | `1` (2 arq), `8` (1 arq), `-1` (1 arq), `2` (1 arq), `-64` (1 arq) |
| 7 | `clef/use @transform` | 12 | 22 | `1` (2 arq), `-64` (1 arq), `-19` (1 arq), `22` (1 arq), `8` (1 arq) |
| 8 | `ledgerLines/path @d` | 8 | 160 | `1` (2 arq), `-1` (1 arq), `221` (1 arq), `-19` (1 arq), `8` (1 arq) |
| 9 | `meterSig/use @transform` | 8 | 24 | `1` (2 arq), `-64` (1 arq), `22` (1 arq), `8` (1 arq), `15` (1 arq) |
| 10 | `rest/use @transform` | 7 | 29 | `-19` (1 arq), `-64` (1 arq), `221` (1 arq), `180` (1 arq), `8` (1 arq) |
| 11 | `accid/use @transform` | 7 | 24 | `22` (1 arq), `8` (1 arq), `15` (1 arq), `-19` (1 arq), `-208` (1 arq) |
| 12 | `tupletNum/use @transform` | 7 | 14 | `-180` (3 arq), `9` (2 arq), `-1` (1 arq), `99` (1 arq) |
| 13 | `system/path @d` | 7 | 13 | `-19` (1 arq), `-64` (1 arq), `22` (1 arq), `8` (1 arq), `-1` (1 arq) |
| 14 | `grpSym/path @d` | 6 | 80 | `-19` (1 arq), `-64` (1 arq), `22` (1 arq), `-1` (1 arq), `15` (1 arq) |
| 15 | `mNum/text @y` | 6 | 11 | `8` (1 arq), `-19` (1 arq), `-64` (1 arq), `22` (1 arq), `-1` (1 arq) |
| 16 | `dots/ellipse @cy` | 5 | 32 | `-180` (3 arq), `720` (2 arq), `8` (1 arq), `221` (1 arq) |
| 17 | `label/text @y` | 5 | 8 | `8` (1 arq), `-64` (1 arq), `22` (1 arq), `-1` (1 arq), `15` (1 arq) |
| 18 | `keyAccid/use @transform` | 4 | 28 | `-1` (1 arq), `-19` (1 arq), `-11` (1 arq), `-5` (1 arq), `8` (1 arq) |
| 19 | `dir/text @y` | 4 | 5 | `1` (2 arq), `3` (1 arq), `2` (1 arq) |
| 20 | `oStaff/path @d` | 3 | 150 | `13` (2 arq), `-11` (1 arq), `-2` (1 arq), `-7` (1 arq), `-4` (1 arq) |
| 21 | `tie/path @d` | 3 | 41 | `-1` (2 arq), `15` (1 arq), `-2` (1 arq), `1` (1 arq) |
| 22 | `mRest/use @transform` | 2 | 45 | `-9` (1 arq), `-3` (1 arq), `-8` (1 arq), `-5` (1 arq), `-2` (1 arq) |
| 23 | `octave/polyline @points` | 2 | 9 | `-221` (1 arq), `65` (1 arq), `-156` (1 arq) |
| 24 | `flag/use @transform` | 2 | 8 | `-64` (1 arq), `8` (1 arq) |
| 25 | `artic/use @transform` | 2 | 7 | `-64` (1 arq), `22` (1 arq) |

## Deltas mais compartilhados entre arquivos

Um mesmo delta sob várias classes costuma ser **uma** coordenada errada a montante que todo o resto herdou — atacar a origem custa uma correção e limpa todas as classes de uma vez.

| Delta (Dart − C++) | Arquivos |
|---|---|
| `-1` | 14 |
| `1` | 11 |
| `-2` | 9 |
| `-180` | 7 |
| `4` | 4 |
| `-3` | 3 |
| `2` | 3 |
| `3` | 3 |
| `9` | 3 |
| `-14` | 2 |
| `-8` | 2 |
| `-7` | 2 |
| `-5` | 2 |
| `13` | 2 |
| `208` | 2 |
| `720` | 2 |
| `-1890` | 1 |
| `-666` | 1 |
| `-458` | 1 |
| `-416` | 1 |
| `-376` | 1 |
| `-355` | 1 |
| `-354` | 1 |
| `-331` | 1 |
| `-314` | 1 |

## Onde cai a primeira divergência de cada arquivo

A pauta é desenhada antes de tudo em cada compasso, então a "primeira divergência" é sistematicamente o sintoma mais a jusante. Esta tabela existe para tornar esse mascaramento visível — não use a primeira divergência como escolha de alvo.

| Classe | Arquivos cuja 1ª divergência cai aqui |
|---|---|
| `system` | 7 |
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

