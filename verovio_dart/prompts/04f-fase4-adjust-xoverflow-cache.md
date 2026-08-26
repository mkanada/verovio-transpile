# 04f — AdjustXOverflowFunctor + CacheHorizontalLayoutFunctor + CalcSpanningBeamSpansFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar o fim da fase horizontal: tratamento do transbordo em X de elementos de controle no último
compasso do sistema (`AdjustXOverflow`), cache da configuração horizontal para o cast-off
(`CacheHorizontalLayout`) e criação dos segmentos de `beamSpan` que cruzam sistemas
(`CalcSpanningBeamSpans`).

## Pré-condições

Tarefas **04a**–**04e** concluídas.

```bash
cd verovio_dart
ls lib/src/layout/adjust_harm_tempo_syl.dart
dart test 2>&1 | tail -1     # verde, ≥ 288
```

## Referência C++

| Arquivo | Linhas | Visits |
|---|---:|---|
| `origin/src/src/adjustxoverflowfunctor.cpp` | 121 | `VisitControlElement`, `VisitMeasure`, `VisitSystem`, `VisitSystemEnd` |
| `origin/src/src/cachehorizontallayoutfunctor.cpp` | 52 | `VisitArpeg`, `VisitLayerElement`, `VisitMeasure` |
| `origin/src/src/calcspanningbeamspansfunctor.cpp` | 67 | `VisitBeamSpan` |
| `origin/src/src/page.cpp:396-497` | — | `AdjustXOverflow` e `CacheHorizontalLayout` no fim de `LayOutHorizontally` |
| `origin/src/src/page.cpp:499-507` | — | `Page::LayOutHorizontallyWithCache(bool restore)` — quem consome o cache |

`CacheHorizontalLayoutFunctor` tem um flag `m_restore`: a mesma classe grava e restaura.
Leia o header (`origin/src/include/vrv/cachehorizontallayoutfunctor.h`) antes de portar.

Onde `CalcSpanningBeamSpans` entra: procure com
`grep -rn "CalcSpanningBeamSpans" origin/src/src/*.cpp` — **não** é o `page.cpp`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/adjust_x_overflow.dart` — `AdjustXOverflowFunctor`.
- **Criar** `lib/src/layout/cache_horizontal_layout.dart` — `CacheHorizontalLayoutFunctor`
  e o método `Page.layOutHorizontallyWithCache`.
- **Criar** `lib/src/layout/calc_spanning_beam_spans.dart` — `CalcSpanningBeamSpansFunctor`.
- **Alterar** `lib/src/model/doc.dart` e `lib/src/model/system_page_elements.dart`.
- **Alterar** `lib/src/layout/align_horizontally.dart:187` — o `TODO(phase-4/5)` sobre segmentos de
  `beamSpan` é exatamente o que `CalcSpanningBeamSpans` resolve; atualize ou remova o comentário.
- **Criar** `test/adjust_x_overflow_test.dart`.

## Passo a passo

1. Leia os três `.cpp` e os três `.h`.
2. Leia `Page::LayOutHorizontallyWithCache` e descubra quem a chama
   (`grep -rn "LayOutHorizontallyWithCache" origin/src/src/`).
3. Descubra quem chama `CalcSpanningBeamSpansFunctor` no C++ e reproduza esse ponto, não invente outro.
4. Porte os três.
5. Ligue no `doc.dart` / `system_page_elements.dart`.
6. Testes: `test/corpus/beamspan/` (6 arquivos) para `CalcSpanningBeamSpans`;
   `test/corpus/dir/` ou `test/corpus/dynam/` para transbordo em X (elemento de controle no fim do
   sistema); um arquivo com muitos sistemas (`test/corpus/section/section-001.mei`, 20 compassos)
   para o cache.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 292 testes**
- [ ] Os três arquivos novos existem e cada um contém exatamente 1 `class …Functor`
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.` e timemaps **≥ 24/30**
- [ ] O relatório diz se `section/section-001.mei` passou de `10/20 differ @q=25.00` para `match`,
      e se não, a hipótese de causa
- [ ] Relatório em `prompts/reports/04f.md`
- [ ] `PLANO.md`: os três nomes removidos da lista de faltantes

## Armadilhas conhecidas

- `CacheHorizontalLayoutFunctor` com `m_restore = true` **restaura**; com `false`, **grava**.
  Trocar os dois produz um layout que parece funcionar e erra no cast-off.
- `AdjustXOverflowFunctor` só age no último compasso do sistema — `VisitSystemEnd` é onde a conta
  acontece, `VisitControlElement` só acumula o candidato de maior transbordo.
- `section/section-001.mei` diverge hoje em timemap com 4 páginas e 20 sistemas: é o caso de cast-off
  mais pesado do corpus validado. Se esta tarefa não o consertar, a suspeita seguinte é o cast-off,
  não estes três functors.

## Fora de escopo

- Reescrever `cast_off.dart` (já portado).
- `CastOffToSelectionFunctor` (tarefa 06-12, depende de selection).
