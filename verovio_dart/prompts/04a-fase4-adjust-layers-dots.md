# 04a — AdjustLayersFunctor + AdjustDotsFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `AdjustLayersFunctor` e `AdjustDotsFunctor`, os dois primeiros ajustes horizontais que
o C++ roda em `Page::LayOutHorizontally` e que hoje estão pulados no Dart. Ao final, notas de
camadas diferentes que colidem no mesmo alinhamento são deslocadas em X, e os pontos de aumento
de camadas sobrepostas são desempilhados — como no C++.

## Pré-condições

Nenhuma tarefa anterior. Confirme a base em 30 s:

```bash
cd verovio_dart
dart test 2>&1 | tail -1          # esperado: "All tests passed!" com +265
grep -c "class AdjustLayersFunctor\|class AdjustDotsFunctor" lib/src/layout/*.dart
                                   # esperado: 0 (nenhum arquivo casa)
```

## Referência C++

| Arquivo | Conteúdo |
|---|---|
| `origin/src/include/vrv/adjustlayersfunctor.h` | `class AdjustLayersFunctor`. Estado: `m_staffNs`, `m_currentLayerN`, `m_previous`, `m_current`, `m_unison`, `m_ignoreDots`, `m_stemSameas`, `m_accumulatedShift`. |
| `origin/src/src/adjustlayersfunctor.cpp` (155 linhas) | `VisitAlignmentReference`, `VisitAlignmentReferenceEnd`, `VisitLayerElement`, `VisitMeasure`, `VisitSystem`. |
| `origin/src/include/vrv/adjustdotsfunctor.h` | `class AdjustDotsFunctor`. Estado: `m_staffNs`, `m_elements`, `m_dots`. |
| `origin/src/src/adjustdotsfunctor.cpp` (130 linhas) | `VisitAlignmentEnd`, `VisitLayerElement`, `VisitMeasure`, `VisitSystem`. |
| `origin/src/src/page.cpp:396-497` | `Page::LayOutHorizontally` — a ordem exata em que os dois entram. |

Atenção à ordem no C++ (`page.cpp`): `AdjustLayers` roda **duas vezes** —
uma antes de `AdjustDots` (`adjustLayers`, com `m_ignoreDots = true`) e uma depois
(`adjustLayersWithDots`, com `m_ignoreDots = false`). Reproduza as duas passadas e os dois valores.

Métodos de apoio que os dois functors chamam e que já existem em Dart — confirme a assinatura antes
de usar, não invente: `LayerElement::GetSelfBottom/GetSelfTop`, `Object::HorizontalContentOverlap`,
`Alignment::GetReferences`, `AlignmentReference::GetChildren`, `Staff::GetN`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/adjust_layers.dart` — `AdjustLayersFunctor`, `AdjustDotsFunctor`
  (os dois cabem num arquivo: são o mesmo passo do pipeline e compartilham a coleta de `staffNs`).
- **Alterar** `lib/src/model/doc.dart` — inserir as chamadas na fase horizontal, na ordem do
  `page.cpp`, e **remover das listas de "skipped"** os nomes `AdjustLayers` e `AdjustDots` nos
  comentários das linhas 296-299 e 312.
- **Criar** `test/adjust_layers_test.dart`.

Nenhuma classe de elemento nova → nada a mexer em `factory_registry.dart`, `vrvdef.dart`
ou `kAcceptChain`.

## Passo a passo

1. Leia `adjustlayersfunctor.h` e `.cpp` inteiros. Anote cada campo de estado e o que o zera.
2. Leia `adjustdotsfunctor.h` e `.cpp` inteiros.
3. Leia `page.cpp:396-497` e anote a ordem e os argumentos do construtor de cada functor.
4. Crie `adjust_layers.dart` com os dois functors, estendendo `DocFunctor`
   (`lib/src/layout/functor.dart:1102`). Cada `VisitXxx` do C++ vira `visitXxx` em Dart.
   Doc comment em cada classe e cada método citando o C++.
5. Ligue no `doc.dart`, na posição exata do `page.cpp`. Atualize os comentários de "skipped".
6. Escreva os testes: para cada functor, um caso mínimo de MEI de `test/corpus/` que exercite o
   deslocamento (sugestões: `test/corpus/layer/layer-001.mei` para camadas, `test/corpus/dot/dot-001.mei`
   para pontos) e asserções sobre `drawingXRel` dos elementos afetados.
   Lembre de `Resources.defaultPath = 'assets/data';` e `registerModelClasses()` no `setUpAll`.
7. Rode a verificação.

## Critérios de aceite

- [ ] `dart analyze` reporta no máximo `10 issues found.`
- [ ] `dart test` verde, com **≥ 269 testes** (265 da baseline + ao menos 4 novos)
- [ ] `grep -c "class AdjustLayersFunctor" lib/src/layout/adjust_layers.dart` = 1 e
      `grep -c "class AdjustDotsFunctor" lib/src/layout/adjust_layers.dart` = 1
- [ ] `dart run tool/validate_layout.dart` roda até o fim, `tool/LAYOUT_VALIDATION.md` continua com
      `Check notes: None. All structural assertions passed.` e a contagem de timemaps
      **não regride abaixo de 24/30**
- [ ] Relatório gravado em `prompts/reports/04a.md`
- [ ] No `PLANO.md`, na Fase 4, os nomes `AdjustLayers` e `AdjustDots` removidos da linha de
      functors faltantes

## Armadilhas conhecidas

- **As duas passadas de `AdjustLayers`.** Rodar só uma dá resultado quase certo e errado.
- `m_ignoreDots` muda o comportamento de `VisitLayerElement`; não é um flag decorativo.
- A ordem dentro de `VisitAlignmentReference` importa: o C++ compara pares consecutivos, não
  todos contra todos.
- O `AdjustDotsFunctor` acumula em `m_elements` e `m_dots` e só age em `VisitAlignmentEnd`.
  Zerar as listas no lugar errado dá deslocamento cumulativo entre alinhamentos.
- Divisão inteira: o C++ calcula deslocamentos em `int` (unidades de `drawingUnit`). Use `~/`, não `/`.

## Fora de escopo

- `AdjustAccidX` (tarefa 04b) e `AdjustNeumeX` (tarefa 04g), mesmo que o `page.cpp` os mostre por perto.
- Qualquer mexida em `headless_extents.dart` — as bboxes continuam aproximadas até a tarefa 05-12.
- Consertar os registros errados do `ObjectFactory` (tarefa 04i).
