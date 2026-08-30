# 03c — view_element.dart: drawAccid, drawArtic

## Contexto

Você vai tipar 2 método(s) de `lib/src/rendering/view_element.dart`.

Trabalhe a partir de `verovio_dart/`. Não commite.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawAccid` | 1949 | 0 | 3 | `origin/src/src/view_element.cpp` |
| `drawArtic` | 2111 | 1 | 1 | `origin/src/src/view_element.cpp` |

**Famílias afetadas:** accid, artic

## O procedimento

1. Leia C++ e Dart lado a lado.
2. `(x as dynamic).membro` → `_dyn(x).membro`.
3. `catch (_) {}` → `catch (e) { e.toString(); }`.

### Modelo a acrescentar

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

## Verificação

```bash
tool/task_check.sh view_element.dart accid artic
```

## Critério de pronto

- [ ] `tool/task_check.sh` imprimiu `PASS`.
