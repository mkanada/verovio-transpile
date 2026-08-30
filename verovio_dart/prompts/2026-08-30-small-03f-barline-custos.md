# 03f — view_element.dart: drawBarLine, drawSpace, drawCustos, drawDivLine

## Contexto

Você vai tipar 4 método(s) de `lib/src/rendering/view_element.dart`.

Trabalhe a partir de `verovio_dart/`. Não commite.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawBarLine` | — | — | — | `origin/src/src/view_element.cpp` |
| `drawSpace` | — | — | — | `origin/src/src/view_element.cpp` |
| `drawCustos` | 1018 | 1 | 1 | `origin/src/src/view_element.cpp` |
| `drawDivLine` | — | — | — | `origin/src/src/view_element.cpp` |

**Famílias afetadas:** barline, custos

## O procedimento

1. `(x as dynamic).membro` → `_dyn(x).membro`.
2. `catch (_) {}` → `catch (e) { e.toString(); }`.

### Modelo a acrescentar

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

## Verificação

```bash
tool/task_check.sh view_element.dart barline
```

## Critério de pronto

- [ ] `tool/task_check.sh` imprimiu `PASS`.
