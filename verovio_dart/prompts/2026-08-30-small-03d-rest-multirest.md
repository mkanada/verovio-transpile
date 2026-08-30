# 03d — view_element.dart: drawRest, drawMRest, drawMultiRest, drawBeatRpt

## Contexto

Você vai tipar 4 método(s) de `lib/src/rendering/view_element.dart`.

Trabalhe a partir de `verovio_dart/`. Não commite.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawRest` | 378 | 1 | 2 | `origin/src/src/view_element.cpp` |
| `drawMRest` | 613 | 2 | 3 | `origin/src/src/view_element.cpp` |
| `drawMultiRest` | 693 | 7 | 9 | `origin/src/src/view_element.cpp` |
| `drawBeatRpt` | 3357 | — | — | `origin/src/src/view_element.cpp` |

**Famílias afetadas:** rest, multirest

## O procedimento

1. `(x as dynamic).membro` → `_dyn(x).membro`.
2. `catch (_) {}` → `catch (e) { e.toString(); }`.

### Modelo a acrescentar

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

## Verificação

```bash
tool/task_check.sh view_element.dart rest
```

## Critério de pronto

- [ ] `tool/task_check.sh` imprimiu `PASS`.
