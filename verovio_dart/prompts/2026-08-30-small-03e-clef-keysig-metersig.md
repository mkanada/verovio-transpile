# 03e — view_element.dart: drawClef, drawKeySig, drawMeterSig, drawMensur

## Contexto

Você vai tipar 4 método(s) de `lib/src/rendering/view_element.dart`.

Trabalhe a partir de `verovio_dart/`. Não commite.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawClef` | 1706 | 3 | 4 | `origin/src/src/view_element.cpp:418` |
| `drawKeySig` | 2379 | 1 | 3 | `origin/src/src/view_element.cpp:1121` |
| `drawMeterSig` | 2624 | 1 | 1 | `origin/src/src/view_element.cpp` |
| `drawMensur` | — | — | — | `origin/src/src/view_mensural.cpp:80` mas no view_element |

**Famílias afetadas:** clef, keysig, metersig

## O procedimento

1. `(x as dynamic).membro` → `_dyn(x).membro`.
2. `catch (_) {}` → `catch (e) { e.toString(); }`.

### Modelo a acrescentar

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

## Verificação

```bash
tool/task_check.sh view_element.dart clef keysig
```

## Critério de pronto

- [ ] `tool/task_check.sh` imprimiu `PASS`.
