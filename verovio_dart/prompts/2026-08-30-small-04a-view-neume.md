# 04a — view_neume.dart: drawEpisema, drawNeume, drawDivLine, drawNc

## Contexto
Tipar 5 métodos de `lib/src/rendering/view_neume.dart`, tirando `as dynamic` e `catch (_)`.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| drawNc | 74 | 0 | 1 | view_neume.cpp:70 |
| drawNeume | 103 | 2 | 7 | view_neume.cpp:97 |
| drawNcAsNotehead | 190 | 0 | 1 | view_neume.cpp:153 |
| drawDivLine | 213 | 1 | 2 | view_neume.cpp:173 |
| drawEpisema | 267 | 6 | 6 | view_neume.cpp:215 |

## Tipos desta unidade
- `doc!.getOptions().neumeAsNote.value` -> bool
- `neume.getFirst/getLast` -> Nc?
- `doc!.getOptions().octaveLineThickness.value` -> double
- `episema.place` -> Eventrel?
- `episema.form` -> EpisemavisForm?
- `divLine.form` -> DivlinelogForm?

## Verificação
tool/task_check.sh view_neume.dart neume
