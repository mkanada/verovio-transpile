# 05-37 — Quitar a dívida de tipagem restante e perseguir 621/623

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Contexto

A auditoria `2026-08-29-07` (relatório `reports/2026-08-29-07.md`) declarou a Fase 5 **ABERTA**:

- `tool/verify_phases.dart --fase=5` reprova 5.1/5.2/5.3 (`739 as dynamic`, `820 catch (_)`, `9 ignore_for_file` em `lib/src/rendering/`) e 5.6 (`115/623` estrutural, `4/623` numérico, 3 exceções vs alvo `621/623` nos dois modos, zero exceções).
- Famílias difíceis permanecem `0/N`: `ligature 0/50`, `mensural 0/25`, `tuplet 0/22`, `lyric 0/16`, `dir 0/12`, `dynam 0/10` (`tool/SVG_VALIDATION.md` 23:40, medida fresca).
- `05-34` quitou 19/179 membros que `as dynamic` escondia (`view_control.dart` 468→0 via `fix_dynamic.py` revertido, 11 opções + `GetTstampStaves` + getters `AttLineRend`); restam **160 distintos** (`05-34.md:142`, `lib/src/rendering/view_control.dart:514` ainda).
- Testes de `view_text` não mordem com troca de glifo única (`anyOf` permissivo, limiar `>=0` — `2026-08-29-07.md:8`).

Enquanto 5.1/5.2/5.3 falharem, o número de divergências **não é interpretável**: cada membro de modelo faltante vira ramo pulado em silêncio (`2026-08-29-01.md:39` `DrawTempo` `GetStart()` nulo vs exceção).

## Objetivo

Esta tarefa é a `05-34b`+`05-35` combinadas, como recomendado em `PLANO.md:216` (“Antes de perseguir divergências uma a uma, quitar a dívida de tipagem”). Entrega o que `05-34` e `05-35` prometeram e, com o instrumento finalmente interpretável, persegue a cauda até o portão 5.6.

## Pré-condições

```bash
cd verovio_dart
dart test test/harness_integrity_test.dart # verde
grep -rn "test/golden/cpp" lib/src/testing/svg_compare.dart # 0
dart run tool/compare_svg.dart --all --mode=structural # anote ANTES 115/623
dart run tool/compare_svg.dart --all --mode=numeric --epsilon=0 # ANTES 4/623, 3 falhas
dart test # 719 verdes
```

## Parte 1 — quitar a tipagem (critérios 5.1/5.2/5.3)

> Siga exatamente o procedimento de `05-34.md:63` “O procedimento, método a método”, por **famílias inteiras `Draw*`**, nunca no meio de uma.

Ordem por densidade `catch (_)` (pior primeiro) e dependência:

1. `view_control.dart` (514/468) — realize `05-34b` fatiado por famílias:
   - 05-37-A: `DrawArpeg`/`DrawArpegEnclosing`/`_getArpegTopBottomNotes` + `DrawBreath`/`DrawCaesura`/`DrawFermata`/`DrawFing`
   - 05-37-B: `DrawBracketSpan`/`DrawOctave`/`DrawTie`/`DrawPedalLine`/`DrawControlElementConnector` (exige `AttLineRend` getters já em `atts_shared.dart:8`)
   - 05-37-C: `DrawDynam`/`DrawHarm`/`DrawReh`/`DrawTempo`/`DrawHairpin` (exige `getTstampStaves` já em `time_interface.dart`)
   - 05-37-D: `DrawGliss`/`DrawMordent`/`DrawPedal`/`DrawRepeatMark`/`DrawTrill`/`DrawTurn`/`DrawSystemElement`/`DrawEnding` + helpers `_getMordentGlyph`
2. `view_element.dart` (118/151) — `DrawNote`/`DrawChord`/`DrawAccid`/`DrawArtic`/`DrawRest`/`DrawClef`/`DrawKeySig`/`DrawMeterSig`
3. `view_mensural.dart` (40/85) — `DrawLigature`/`DrawMensur`/`DrawMensuralNote` (desbloqueia `ligature`/`mensural`)
4. Demais: `view_beam.dart`, `view_tuplet.dart`, `view_slur.dart`, `view_text.dart` (`DrawLyricString`/`DrawF`/`DrawSymbol`), `view_neume.dart`, `view_tab.dart`, `view_page.dart`, `view_graph.dart`, `view.dart`

Para cada método:

1. Abra `origin/src/src/view_*.cpp` ao lado.
2. Tipe `as dynamic` → tipado; se membro não existe, acrescente ao modelo citando `origin/src/include/vrv/...` (campo `Att*` ou método `const`) ou registre ausência como achado (`05-34.md:142` lista 160 restantes).
3. Troque `catch (_)` por teste explícito (`if (x==null) return;`, `has*` check) — o C++ correspondente é `if (!x) return;`.
4. `orderStr.contains('nonarp')` → `order == ArpeglogOrder.nonarp`, `form.contains('cres')` → `form == HairpinlogForm.cres`, etc.
5. Tire defaults inventados (`?? 'up'`, `?? 0`).
6. Remova `// ignore_for_file:` do topo ao final da família e trate o que o analisador apontar (`dart analyze` deve permanecer 8 sem supressão).
7. `dart format` **só no arquivo da família** (`00-MESTRE.md:3`).

Critérios de saída da Parte 1 (mesmos de `05-34.md:94` e `05-35`):

- `grep -rn "as dynamic" lib/src/rendering/` → 0
- `grep -rn "catch (_)" lib/src/rendering/` → 0 (ou `on Tipo catch` com comentário citando C++ e listagem no relatório)
- `grep -rn "ignore_for_file" lib/src/rendering/` → 0
- `dart analyze` ≤ 8 **sem** as 9 supressões (remova `invalid_assignment`, `argument_type_not_assignable`, `unchecked_use_of_nullable_value` de `view_control.dart:1`)
- `dart test` verde, nenhum `skip`
- `dart run tool/compare_svg.dart --all` nos dois modos **não regride**; onde melhorar, relatório diz qual adivinhação estava errada e lista membros que faltavam

## Parte 2 — as 3 exceções

Rode `dart run tool/compare_svg.dart --all` e use a seção **“Falhas (exceções durante renderização)”** como alvo (não a lista estática):

| Arquivo | Exceção (2026-08-29) |
|---|---|
| `ftrem/ftrem-002.mei` | `_TypeError: Null check operator used on a null value` (`lib/src/layout/adjust_beams.dart:407`) |
| `stem/stem-014.mei` | `UnsupportedError: Cannot remove from an unmodifiable list` (`lib/src/layout/adjust_beams.dart:526`) |
| `stem/stem-016.mei` | mesmo |

Ver `05-36.md:47` para conserto por classe de erro ( `_TypeError` = portar guard do C++, `UnsupportedError` = decidir se getter deve devolver lista viva ou chamador deve copiar, citando `std::vector` do C++). Nenhum entra em skip-list (única legítima `dir/dir-011.mei`, `dir/dir-012.mei`).

## Parte 3 — a caçada (mesmo protocolo da 05-36 Parte 2)

1. Classifique divergências por **causa**, não por arquivo (estrutural: falta/sobra `<g>`, ordem, `class`; numérica pequena <1: arredondamento/divisão inteira `~/` vs `floor()`, formatação `2.0` vs `2`; numérica grande: algoritmo; só `<defs>`: glifo não carregado).
2. Ataque na ordem de quantos arquivos cada causa destrava.
3. Para cada causa: reduza a arquivo mínimo, compare com `./build/verovio -r verovio_dart/assets/data -o /tmp/cpp.svg <arquivo>`, leia `.cpp` inteiro, conserte, meça quanto destravou (`tool/compare_svg.dart test/corpus/<dir>`).
4. Se leitura do `.cpp` não explicar, instrumente (`cpp_probe/` `00-MESTRE.md:6-bis`, patch `05-37`, só acréscimos, `diff` SVG vazio).

Hipótese já medida para começar: `note/note-001.mei` `accid` em `x=2802` Dart vs `x=2859` C++ (57 unidades, cabeça em `3026` nos dois — sistemática horizontal, `05-36.md:80`).

## Critérios de aceite (portão 5.6)

- [ ] `dart analyze` ≤ 8 (sem supressão nova em `lib/src/rendering/`)
- [ ] `dart test` verde, nenhum `skip`
- [ ] `tool/SVG_VALIDATION.md` **estrutural ≥ 590/623** (590 = 60 famílias × progresso + `mensur` já 8/8; ajuste se 5.1-5.3 ainda falharem — mas 5.1-5.3 devem passar primeiro)
- [ ] `tool/SVG_VALIDATION.md` **numérico (eps 0) ≥ 400/623**
- [ ] **0 falhas** (3 arquivos acima consertados)
- [ ] Tabela de classificação por causa (antes × depois, contagem de arquivos por classe)
- [ ] Uma entrada por divergência remanescente (arquivo, C++ vs Dart, hipótese com função:linha)
- [ ] Se instrumentou: patch `05-37` versionado, só acréscimos, `diff` vazio
- [ ] `lib/src/rendering/` sem `as dynamic`/`catch (_)`/`ignore_for_file`
- [ ] Relatório em `prompts/reports/05-37.md` e `PLANO.md` atualizado

> Se **e somente se** os dois números de SVG forem atingidos **e** 5.1/5.2/5.3 passarem: `PLANO.md` marca Fase 5 concluída. Caso contrário, Fase 5 **continua aberta** e este relatório escreve `05-38` nos mesmos moldes.

## Fora de escopo

- MIDI/timemap/transposição/editor (Fase 6), opções Toolkit (Fase 7). Divergência que dependa de opção não portada vira dependência registrada.

## Referência C++

- `origin/src/src/view_control.cpp` 3.306 linhas, `origin/src/src/view_element.cpp` 3.913 linhas, `origin/src/src/view_mensural.cpp` 461 linhas, `origin/src/src/view_beam.cpp`, `view_tuplet.cpp`, `view_slur.cpp`, `view_text.cpp`, `view_neume.cpp`, `view_tab.cpp`, `view_page.cpp`, `view_graph.cpp`, `origin/src/include/vrv/atts_shared.h` (`AttLineRend`), `origin/src/include/vrv/timeinterface.h:95` (`GetTstampStaves`), `origin/src/include/vrv/options.h:708` (11 opções de `05-34.md:13`).
