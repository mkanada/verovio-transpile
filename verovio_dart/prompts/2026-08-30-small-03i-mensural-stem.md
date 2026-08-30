# 03i — view_mensural.dart: drawMensuralStem, drawMaximaToBrevis, drawPlica, getMensuralStemDir

## Contexto

Você vai tipar 4 método(s) de `lib/src/rendering/view_mensural.dart`.

Trabalhe a partir de `verovio_dart/`. Não commite.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawMensuralStem` | 244 | 1 | 5 | `origin/src/src/view_mensural.cpp:162` |
| `drawMaximaToBrevis` | 311 | 6 | 8 | `origin/src/src/view_mensural.cpp:206` |
| `drawPlica` | 670 | 3 | 7 | `origin/src/src/view_mensural.cpp:511` |
| `getMensuralStemDir` | 901 | 5 | 7 | `origin/src/src/view_mensural.cpp:725` |

**Famílias afetadas:** mensural

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

## Critério de pronto

- [ ] `tool/task_check.sh` imprimiu `PASS`.
