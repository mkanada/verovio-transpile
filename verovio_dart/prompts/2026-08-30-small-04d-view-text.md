# 04d — view_text.dart: drawRend, drawSymbol, drawText, drawF, helpers

| método | linha | dynamic | catch | C++ |
|---|---|---|---|---|
| drawDynamString | 71 | 3 | 2 | view_text.cpp:91 |
| drawRend | 404 | 2 | 11 | view_text.cpp:369 |
| drawText | 583 | 0 | 4 | view_text.cpp:480 |
| drawSymbol | 710 | 2 | 7 | view_text.cpp:585 |
| drawLyricString | 262 | 1 | 1 | view_text.cpp:264 |
| drawF | 881 | 2 | 3 | view_text.cpp:49 |
| drawRunningElements | 811 | 0 | 2 | view_text.cpp:642 |
| drawTextLayoutElement | 841 | 1 | 1 | view_text.cpp:663 |
| _convertHalign | 929 | - | - | consolidado em view.dart |
| _convertFontStyle/Weight | 945/955 | - | - | mei_enums |

Consolidação _convertHalign: movido para `View.convertHalign` em view.dart (full mapping justify/none). view_text e view_control delegam.

Verificação: tool/task_check.sh view_text.dart lyric
