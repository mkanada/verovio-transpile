# 04c — AdjustTupletsXFunctor + AdjustTupletsYFunctor + AdjustTupletNumOverlapFunctor + AdjustTupletWithSlursFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar a família inteira de ajuste de quiálteras: posicionamento X do colchete e do número,
posicionamento Y contra as notas, detecção de sobreposição do número e ajuste contra ligaduras.

## Pré-condições

Tarefas **04a** e **04b** concluídas.

```bash
cd verovio_dart
ls lib/src/layout/adjust_artic.dart lib/src/layout/adjust_accid_x.dart
dart test 2>&1 | tail -1     # verde, ≥ 274
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/include/vrv/adjusttupletsxfunctor.h` | — | `class AdjustTupletsXFunctor`, só `VisitTuplet`. |
| `origin/src/src/adjusttupletsxfunctor.cpp` | 107 | `AdjustTupletsXFunctor::VisitTuplet`. |
| `origin/src/include/vrv/adjusttupletsyfunctor.h` | — | `class AdjustTupletsYFunctor` (`VisitTuplet`), `class AdjustTupletNumOverlapFunctor` (`VisitLayerElement`), `class AdjustTupletWithSlursFunctor` (`VisitTuplet`). |
| `origin/src/src/adjusttupletsyfunctor.cpp` | 429 | os três functors. |
| `origin/src/src/page.cpp:396-497` | — | `AdjustTupletsX` na fase horizontal. |
| `origin/src/src/page.cpp:509-608` | — | `AdjustTupletsY` e `AdjustTupletWithSlurs` na fase vertical. |

`AdjustTupletNumOverlapFunctor` **não é chamado pelo `page.cpp`**: quem o instancia é
`AdjustTupletsYFunctor`, por dentro. Procure a chamada no `.cpp` antes de ligar qualquer coisa.

As classes de desenho `TupletBracket` e `TupletNum` já existem em Dart
(`lib/src/model/layer_elements_gen.dart`) — confirme os campos disponíveis com
`grep -n "class TupletBracket" -A 40 lib/src/model/layer_elements_gen.dart`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/adjust_tuplets.dart` — os quatro functors.
- **Alterar** `lib/src/model/doc.dart` — ligar `AdjustTupletsX` (horizontal) e
  `AdjustTupletsY` + `AdjustTupletWithSlurs` (vertical); atualizar os comentários de "skipped"
  em `:298-299`, `:344`, `:461-462` e `:505`.
- **Criar** `test/adjust_tuplets_test.dart`.

## Passo a passo

1. Leia `adjusttupletsxfunctor.cpp` (107 linhas) inteiro.
2. Leia `adjusttupletsyfunctor.cpp` (429 linhas) inteiro. Ele tem os três functors; identifique
   onde `AdjustTupletsYFunctor` instancia `AdjustTupletNumOverlapFunctor` e com que argumentos.
3. Porte os quatro em `adjust_tuplets.dart`, na mesma ordem em que aparecem no C++.
4. Ligue no `doc.dart`, nas posições do `page.cpp`.
5. Testes com `test/corpus/tuplet/tuplet-001.mei` e mais um dos 22 arquivos de `test/corpus/tuplet/`
   que tenha quiáltera aninhada (`grep -l "tuplet.*tuplet" test/corpus/tuplet/*.mei | head -3`).
   Asserte `drawingXRel`/`drawingYRel` do `TupletBracket` e do `TupletNum`.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 279 testes**
- [ ] `grep -c "^class Adjust" lib/src/layout/adjust_tuplets.dart` = 4
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.`, timemaps **≥ 24/30**, e
      `tuplet/tuplet-001.mei` continua com `Layout OK` e todos os `PASS`
- [ ] Relatório em `prompts/reports/04c.md`
- [ ] `PLANO.md`: os quatro nomes removidos da lista de faltantes

## Armadilhas conhecidas

- `AdjustTupletNumOverlapFunctor` é instanciado **dentro** do `AdjustTupletsYFunctor` e devolve um
  valor (a posição livre encontrada). Se você o ligar no pipeline como functor independente, o
  resultado muda.
- Quiálteras aninhadas: o C++ trata a profundidade explicitamente. Não simplifique.
- `AdjustTupletWithSlursFunctor` depende de posicionadores de slur (mesma armadilha da 04b) —
  tem de rodar depois de `AdjustSlursFunctor`.
- A bbox de slur hoje é aproximada (`headless_extents.dart:572`). Divergências numéricas contra o
  C++ nos casos com ligadura são **esperadas**; documente e siga.

## Fora de escopo

- `AdjustBeams` (tarefa 04d), mesmo que o `page.cpp` o mostre na mesma fase vertical.
- Consertar aproximações de bbox.
