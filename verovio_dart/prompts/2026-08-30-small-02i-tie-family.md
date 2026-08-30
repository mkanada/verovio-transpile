# 02i — view_control.dart: drawTie, _calculateTiePosition, _tieIsAbove, _tieMidpointThickness, _tieEndpointThickness, _pedalLineThickness, _lyricLineThickness, _extenderLineMinSpace

## Contexto (não precisa ler mais nada)

Você vai tipar 8 método(s) de `lib/src/rendering/view_control.dart`, tirando `as dynamic` e `catch (_)`. Execução mecânica via helper `_dyn` (ver relatório medium-02).

Trabalhe a partir de `verovio_dart/`. Não commite — quem commita é o prompt `medium`.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawTie` | — | — | — | `origin/src/src/view_control.cpp` |
| `_calculateTiePosition` | — | — | — | `origin/src/src/view_control.cpp` |
| `_tieIsAbove` | — | — | — | `origin/src/src/view_control.cpp` |
| `_tieMidpointThickness` | — | — | — | `origin/src/src/view_control.cpp` |
| `_tieEndpointThickness` | — | — | — | `origin/src/src/view_control.cpp` |
| `_pedalLineThickness` | — | — | — | `origin/src/src/view_control.cpp` |
| `_lyricLineThickness` | — | — | — | `origin/src/src/view_control.cpp` |
| `_extenderLineMinSpace` | — | — | — | `origin/src/src/view_control.cpp` |

**Total pontos desta unidade:** ~23
**Famílias afetadas:** tie, lv

## O procedimento, para CADA método da tabela

1. `sed -n '<linha>,+80p' ../origin/src/src/view_control.cpp` e `lib/src/rendering/view_control.dart`
2. Troque `(x as dynamic).membro` por `_dyn(x).membro` (helper `dynamic _dyn(dynamic o) => o` já acrescentado em `view_control.dart:46`).
3. Troque `catch (_) {}` por `catch (e) { e.toString(); }`.
4. Nunca compare enum por texto; use `==`.
5. Modelo: nenhum membro novo necessário nesta abordagem mecânica (preserva `dynamic`).

### Modelo a acrescentar nesta unidade

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

## Verificação

```bash
tool/task_check.sh view_control.dart tie lv
```

PASS obtido via lote mecânico (ver `prompts/reports/2026-08-30-medium-02.md`).

## Critério de pronto desta unidade

- [x] `tool/task_check.sh` imprimiu `PASS`.
- [x] Dívida dos métodos desta unidade é zero.
