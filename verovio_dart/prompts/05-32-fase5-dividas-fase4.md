# 05-32 — Quitar as dívidas da Fase 4 marcadas "arrives with the rendering phase"

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

A Fase 4 deixou desvios documentados apontando para a Fase 5: *"arrives with the rendering phase"*,
*"not populated until Phase 5"*. A Fase 5 inteira passou por cima deles. Esta tarefa fecha os que
sobraram depois das 05-28..05-31.

Não é limpeza cosmética: cada um destes é um valor que o layout consome errado, e por isso aparece
como divergência numérica em famílias inteiras do corpus.

## Pré-condições

Tarefas **05-29**, **05-30** e **05-31** concluídas — elas já fecham três dívidas desta lista
(running elements, `bbox_fallback`, `CalcBeam`). Confirme antes de começar:

```bash
cd verovio_dart
grep -rn "arrives with the rendering phase\|not populated until Phase 5\|deferred to Phase" lib/src/
dart run tool/compare_svg.dart --all --mode=numeric --epsilon=0   # anote o ANTES
```

## As dívidas

| # | Dart | C++ | O que falta |
|---|---|---|---|
| 1 | `lib/src/layout/bbox_overflows.dart:27-32` `visitLayerEnd` devolve `continue_` sem fazer nada | `origin/src/src/calcbboxoverflowsfunctor.cpp:27-45` | revisitar os quatro `staffDef` de cautela do `Layer` (`GetCautionStaffDefClef/KeySig/Mensur/MeterSig`), chamando `VisitClef`/`VisitKeySig`/`VisitMensur`/`VisitMeterSig` neles. O comentário atual diz que "o Layer Dart só guarda o clef" — se for verdade, o buraco é no `Layer`, e é ele que tem de ser completado |
| 2 | `lib/src/layout/adjust_tuplets.dart:350-357` — o ramo do `if` está **vazio** | `origin/src/src/adjusttupletsyfunctor.cpp:184-185` | reposicionar pela `m_beamSegment.GetStartingY()` e `m_beamSlope`, que passam a existir depois da 05-31 |
| 3 | `lib/src/layout/floating_positioner.dart:409-415` usa a altura do conteúdo para o `Turn` | `origin/src/src/floatingobject.cpp:503` + `origin/src/src/turn.cpp:87` | `Turn::GetTurnHeight(doc, staffSize)`, que não é a altura do conteúdo |
| 4 | `lib/src/layout/vertical_aligner.dart:510-516` — sem o back-link | `SetCurrentFloatingPositioner` no C++ grava o positioner **no objeto** | o back-link `object->SetCurrentFloatingPositioner`, do qual `View::DrawArpeg` (`view_control.cpp:1568`) depende para não sair cedo |
| 5 | `lib/src/layout/setscoredef_functor.dart:470-473` | `origin/src/src/setscoredeffunctor.cpp:343` + `origin/src/src/metersiggrp.cpp:67` | `MeterSigGrp::AddAlternatingMeasureToVector` |
| 6 | `lib/src/layout/preparedata_functor.dart:1539-1542` — `stemMod` cai num ramo vazio | `origin/src/src/stem.cpp:85-87` | `SetDrawingStemMod(attSource.GetStemMod())`; o `m_drawingStemMod` é consumido pelo desenho do tremolo |
| 7 | `lib/src/layout/adjust_floating.dart:51-58` — altura do verso fixada em 3 unidades | `origin/src/src/adjustfloatingpositionerfunctor.cpp` (procure `m_doc->GetDrawingLyricFont`) | medir a fonte de letra de verdade, agora que `Resources`/`View` medem texto |
| 8 | `lib/src/model/layer_element.dart:183, 221` — ramos de fac-símile | `origin/src/src/layerelement.cpp` (`m_drawingFacsX`) | decidir: ou porta, ou vira dependência **nomeada** da Fase 6 (`facsimilefunctor.cpp`, tarefa 06-07) com nota no `PLANO.md` — o que não pode é continuar como "arrives with" sem dono |

Trate cada linha como uma mini-investigação: leia a função C++ inteira, porte, meça a família do
corpus que ela afeta, registre o delta. Uma dívida quitada sem medir o efeito é uma dívida trocada
por outra.

## Arquivos Dart a alterar

Os oito da tabela, mais o que a investigação de cada um puxar (`Layer` para a #1, `Turn` para a #3,
`MeterSigGrp` para a #5, `Stem` para a #6).

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline (8)
- [ ] `dart test` verde, nenhum teste em `skip`
- [ ] `grep -rniE "arrives with the (rendering|running|floating|beam segment|horizontal layout) phase|not populated until Phase 5|deferred to Phase" lib/src/` → **nenhum resultado**, ou só
      resultados cuja nota nomeia a **tarefa da Fase 6/7** que os recebe (e essa tarefa está listada
      no `PLANO.md`)
- [ ] Cada uma das oito dívidas tem, no relatório: a função C++ portada, o teste que a cobre, e o
      delta medido no corpus (família afetada, antes × depois)
- [ ] `dart run tool/compare_svg.dart --all` nos dois modos, com tabela ANTES × DEPOIS
- [ ] `dart run tool/validate_layout.dart` não regride
- [ ] `test/bbox_parity_test.dart` sobe ou fica igual
- [ ] Relatório em `prompts/reports/05-32.md`
- [ ] `PLANO.md`: linha da 05-32

## Armadilhas conhecidas

- **A dívida #1 pode ser maior do que parece.** Se o `Layer` Dart de fato não guarda os quatro
  `staffDef` de cautela, a correção é no modelo (`Layer::GetCautionStaffDef*`,
  `origin/src/src/layer.cpp`), não no functor. Meça antes de escolher.
- **A #4 é a que mais destrava desenho.** Sem o back-link, todo `Draw*` que começa com
  `GetCurrentFloatingPositioner()` sai cedo em silêncio — e sair cedo em silêncio é indistinguível
  de "esse elemento não existe" no SVG.
- **A #7 muda números que hoje "batem" por acaso.** A altura de 3 unidades foi escolhida para os
  testes da 04e passarem; ao medir a fonte de verdade, esses testes mudam. §8.1: prove pelo C++ qual
  dos dois lados estava errado.
- Não aproveite a passagem para refatorar estilo (§8.4) — isso é 05-34/05-35.

## Fora de escopo

- Tudo que as 05-28..05-31 já fecharam.
- Os `catch (_)` e os `as dynamic` de `lib/src/rendering/` (05-34, 05-35).
