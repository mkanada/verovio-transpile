# 04b — AdjustAccidXFunctor + AdjustArticFunctor + AdjustArticWithSlursFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar o desempilhamento horizontal de acidentes (`AdjustAccidX`) e o posicionamento vertical de
articulações fora do pentagrama (`AdjustArtic` e `AdjustArticWithSlurs`). Ao final, acidentes
sobrepostos deixam de colidir e articulações externas ficam acima/abaixo do que já ocupa o lugar.

## Pré-condições

Tarefa **04a** concluída.

```bash
cd verovio_dart
ls lib/src/layout/adjust_layers.dart    # tem de existir
dart test 2>&1 | tail -1                # "All tests passed!", ≥ 269
```

## Referência C++

| Arquivo | Conteúdo |
|---|---|
| `origin/src/include/vrv/adjustaccidxfunctor.h` | `class AdjustAccidXFunctor`, estado `m_adjustedAccids`. |
| `origin/src/src/adjustaccidxfunctor.cpp` (198 linhas) | `VisitAlignment`, `VisitAlignmentReference`, `VisitMeasure`. |
| `origin/src/include/vrv/adjustarticfunctor.h` | `class AdjustArticFunctor` e `class AdjustArticWithSlursFunctor`, estado `m_articAbove`, `m_articBelow`. |
| `origin/src/src/adjustarticfunctor.cpp` (177 linhas) | `VisitArtic`, `VisitChord`, `VisitNote` (AdjustArtic) e `VisitArtic` (AdjustArticWithSlurs). |
| `origin/src/src/page.cpp:396-497` | posição de `AdjustArtic` e `AdjustAccidX` na fase horizontal. |
| `origin/src/src/page.cpp:509-608` | posição de `AdjustArticWithSlurs` na fase vertical (roda **depois** do `BBoxDeviceContext` da linha 532). |

`AdjustAccidXFunctor` usa `Accid::AdjustX` (`origin/src/src/accid.cpp`) — leia essa função também;
ela é o coração do algoritmo e é recursiva.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/adjust_accid_x.dart` — `AdjustAccidXFunctor`.
- **Criar** `lib/src/layout/adjust_artic.dart` — `AdjustArticFunctor` e `AdjustArticWithSlursFunctor`.
- **Alterar** `lib/src/model/basic_elements.dart` ou o arquivo onde vive `Accid` — acrescentar
  `adjustX` se ainda não existir (`grep -n "adjustX" lib/src/model/*.dart` antes).
- **Alterar** `lib/src/model/doc.dart` — ligar os três na ordem do `page.cpp`; atualizar os
  comentários de "skipped" das linhas 296-299, 461-462 e 505.
- **Criar** `test/adjust_accid_artic_test.dart`.

## Passo a passo

1. Leia os dois headers e os dois `.cpp` inteiros, mais `Accid::AdjustX` em `origin/src/src/accid.cpp`.
2. Confirme com `grep -n "adjustX\|AdjustX" lib/src/model/` se `Accid.adjustX` já existe em Dart.
   Se não, porte-a junto, no arquivo onde `Accid` vive.
3. Porte `AdjustAccidXFunctor` em `adjust_accid_x.dart`.
4. Porte `AdjustArticFunctor` e `AdjustArticWithSlursFunctor` em `adjust_artic.dart`.
   Note que `AdjustArticWithSlursFunctor` depende dos posicionadores de slur já criados pela
   fase vertical — ligue-o **depois** de `AdjustSlursFunctor`, exatamente como o `page.cpp`.
5. Ligue os três no `doc.dart` e atualize os comentários de "skipped".
6. Testes: `test/corpus/accid/accid-001.mei` (acidentes empilhados) e
   `test/corpus/artic/artic-001.mei` (articulações). Asserte `drawingXRel` dos acidentes e
   `drawingYRel` das articulações.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 274 testes**
- [ ] `grep -l "class AdjustAccidXFunctor" lib/src/layout/adjust_accid_x.dart` casa, e
      `grep -c "class AdjustArtic" lib/src/layout/adjust_artic.dart` = 2
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.` e timemaps **≥ 24/30**
- [ ] Relatório em `prompts/reports/04b.md`
- [ ] `PLANO.md`: `AdjustArtic`, `AdjustArticWithSlurs` e `AdjustAccidX` removidos da lista de faltantes

## Armadilhas conhecidas

- `Accid::AdjustX` é recursiva e devolve o número de acidentes ajustados; o functor usa esse retorno
  para decidir se continua. Porte o retorno, não só o efeito.
- `m_adjustedAccids` é limpo em `VisitAlignment`, não em `VisitMeasure`. Limpar no lugar errado faz
  acidentes de compassos diferentes interferirem.
- `AdjustArticWithSlursFunctor` **precisa** de posicionadores de slur; rodá-lo antes da fase vertical
  não faz nada e o teste passa em falso. Confira que ele roda depois de `AdjustSlursFunctor`.
- As bboxes de `Artic` hoje vêm de `headless_extents.dart:291` (caixa de 1 unidade, aproximada).
  **Isto vai fazer os números não baterem exatamente com o C++, e é esperado nesta tarefa.**
  Registre a divergência no relatório e siga — ela morre na tarefa 05-12.

## Fora de escopo

- Corrigir a aproximação de bbox de `Artic` em `headless_extents.dart`.
- `AdjustTuplets*` (tarefa 04c).
