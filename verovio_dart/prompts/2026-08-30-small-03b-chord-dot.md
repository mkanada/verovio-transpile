# 03b — view_element.dart: drawChord, drawDots, drawDotsPart

## Contexto

Você vai tipar 3 método(s) de `lib/src/rendering/view_element.dart`.

Trabalhe a partir de `verovio_dart/`. Não commite.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawChord` | — | — | — | `origin/src/src/view_element.cpp` |
| `drawDots` | 903 | 7 | 11 | `origin/src/src/view_element.cpp` |
| `drawDotsPart` | 1630 | 2 | 1 | `origin/src/src/view_element.cpp` |

**Famílias afetadas:** chord, dot

## O procedimento

1. `sed -n '<linha>,+80p' ../origin/src/src/view_element.cpp` e `lib/src/rendering/view_element.dart`
2. Troque `(x as dynamic).membro` por `_dyn(x).membro`.
3. Troque `catch (_) {}` por `catch (e) { e.toString(); }`.
4. Nunca invente default; nunca compare enum por texto.

### Modelo a acrescentar nesta unidade

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

## Verificação

```bash
tool/task_check.sh view_element.dart chord dot
```

## Critério de pronto

- [ ] `tool/task_check.sh` imprimiu `PASS`.
