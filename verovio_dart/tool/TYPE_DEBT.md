# TYPE_DEBT — dívida de tipagem de `lib/src/rendering/` (loop de tipagem)

Lavagem de tipo (_dyn + as dynamic + declarações dynamic): 388
Engolidores silenciosos (catch sem rethrow nem log): 35
Supressões de erro de tipo: 0
Dívida total (D = A + B + C): 423

Gerado em 2026-09-05 por `dart run tool/debt_report.dart`.

- A.1 chamadas `_dyn(...)` (exclui as 3 linhas de declaração do helper): 275
- A.2 `as dynamic`: 0
- A.3 declarações/parâmetros `dynamic x` (exclui o helper): 113
- B.1 total de `catch` no diretório: 35
- B.2 dos quais sem `rethrow` nem log (contam para B): 35
- C — supressões de erro de tipo fora da allowlist (`dead_code`/`unused*`, ver `view_mensural.dart:24` e `view_control.dart:392`): 0

## Por arquivo

| arquivo | linhas | A (_dyn/as dynamic/dynamic decl) | B (catch silencioso / total) | C | D |
|---|---|---|---|---|---|
| bbox_device_context.dart | 585 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| device_context.dart | 420 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| glyph.dart | 126 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| resources.dart | 594 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| svg_device_context.dart | 1975 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| view.dart | 659 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| view_beam.dart | 491 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| view_control.dart | 4267 | 241 (177/0/64) | 25 / 25 | 0 | 266 |
| view_element.dart | 3415 | 110 (72/0/38) | 6 / 6 | 0 | 116 |
| view_graph.dart | 471 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| view_mensural.dart | 963 | 36 (26/0/10) | 4 / 4 | 0 | 40 |
| view_neume.dart | 343 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| view_page.dart | 2334 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| view_slur.dart | 83 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| view_tab.dart | 501 | 0 (0/0/0) | 0 / 0 | 0 | 0 |
| view_text.dart | 976 | 1 (0/0/1) | 0 / 0 | 0 | 1 |
| view_tuplet.dart | 370 | 0 (0/0/0) | 0 / 0 | 0 | 0 |

Escopo: apenas `lib/src/rendering/`. Fora de escopo (não contados aqui, ver `prompts/loop-tipagem-prompt-supervisor.md`): os 3 `as dynamic` de `model/` (`comparison.dart:319`, `interfaces/simple_interfaces.dart:160`, `doc.dart:1823`), o `catch (_)` de `testing/svg_compare.dart:114`, e os `// ignore:` de código morto/não usado (allowlist acima).
