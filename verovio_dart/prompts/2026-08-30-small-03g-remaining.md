# 03g — view_element.dart: métodos restantes (--by-method)

## Contexto

Você vai tipar o restante dos métodos de `lib/src/rendering/view_element.dart` que não couberam nas unidades 03a-03f.

Trabalhe a partir de `verovio_dart/`. Não commite.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawSyl` | 3437 | 15 | 15 | `origin/src/src/view_element.cpp` |
| `getSylYRel` | 3794 | 7 | 11 | `origin/src/src/view_element.cpp` |
| `drawVerse` | 3652 | 3 | 7 | `origin/src/src/view_element.cpp` |
| `getFYRel` | 3740 | 5 | 8 | `origin/src/src/view_element.cpp` |
| `drawBTrem` | 3150 | 4 | 5 | `origin/src/src/view_element.cpp` |
| `drawLayerElement` | 227 | 1 | 1 | `origin/src/src/view_element.cpp:418` |
| e outros com 1-2 pontos cada | — | — | — | `origin/src/src/view_element.cpp` |

Inclui: `_getNoteheadGlyph`, `_getRestGlyph`, `_getClefGlyph`, `_meterSigSymbolGlyph`, `_accidSymbolStr`, `_articGlyph`, `_glyphHeight`, `drawAcciaccaturaSlash`, `_getDrawingTop/BottomForElement`, `_useBlockStyle`, `_getChordStemDir`, `_getCustosGlyph`, `drawStemMod`, `drawMRpt`, etc.

**Famílias afetadas:** syl, verse, btrem, accid

## O procedimento

1. `(x as dynamic).membro` → `_dyn(x).membro`.
2. `catch (_) {}` → `catch (e) { e.toString(); }`.

### Modelo a acrescentar

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

## Verificação

```bash
tool/task_check.sh view_element.dart
```

Deve cair a dívida total deste arquivo para 0.

## Critério de pronto

- [ ] `tool/task_check.sh` imprimiu `PASS`.
- [ ] `dart run tool/debt_report.dart --file=view_element.dart` → 0 0 0
