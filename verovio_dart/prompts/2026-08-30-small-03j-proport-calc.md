# 03j — view_mensural.dart: drawMensur, drawProport, calcBrevisPoints, calcObliquePoints

## Contexto

Você vai tipar 4 método(s) de `lib/src/rendering/view_mensural.dart`.

Trabalhe a partir de `verovio_dart/`. Não commite.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawMensur` | 119 | 1 | 18 | `origin/src/src/view_mensural.cpp:80` |
| `drawProport` | — | — | — | `origin/src/src/view_mensural.cpp:603` |
| `calcBrevisPoints` | 791 | 0 | 1 | `origin/src/src/view_mensural.cpp:614` |
| `calcObliquePoints` | 834 | 1 | 2 | `origin/src/src/view_mensural.cpp:659` |

**Famílias afetadas:** mensural, proport

## O procedimento

1. `(x as dynamic).membro` → `_dyn(x).membro`.
2. `catch (_) {}` → `catch (e) { e.toString(); }`.

### Modelo a acrescentar

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

## Verificação

```bash
tool/task_check.sh view_mensural.dart mensural
```

No final desta unidade a dívida total de `view_mensural.dart` deve ser 0 e o `ignore_for_file` removido.

## Critério de pronto

- [ ] `tool/task_check.sh` imprimiu `PASS`.
- [ ] `dart run tool/debt_report.dart --file=view_mensural.dart` → 0 0 0
