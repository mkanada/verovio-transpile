# 05-12 — VIRADA: ligar o layout ao View real e deletar headless_extents.dart

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Substituir o substituto. Hoje o layout da Fase 4 calcula bounding boxes com
`lib/src/rendering/headless_extents.dart` — 825 linhas de aproximações. O C++ calcula-as
**desenhando de verdade** num `BBoxDeviceContext`. Esta tarefa reproduz o fluxo do C++, **deleta
`headless_extents.dart`** e revalida a Fase 4 inteira.

**Espere regressões.** Números que "batiam" com aproximações vão mudar. Isso é o objetivo: é a única
rota para igualdade numérica com o C++. Persiga-as até o fim.

## Pré-condições

Tarefas **05-05** (BBoxDeviceContext completo) e **05-11** (view_page inteiro) concluídas.

```bash
cd verovio_dart
grep -c "_notYet(" lib/src/rendering/view_page.dart          # 0
grep -c "TODO" lib/src/rendering/bbox_device_context.dart    # 0
dart test 2>&1 | tail -1                                      # verde, ≥ 432
dart run tool/validate_layout.dart                            # anote os números ANTES
```

**Anote no relatório os números de antes:** arquivos com layout OK, asserções estruturais, timemaps
`match`, timemaps `differ`. Eles são a linha de base contra a qual a virada será julgada.

## Referência C++

O fluxo exato, em `origin/src/src/page.cpp`:

| Linha | Contexto | Modo do BBoxDeviceContext | Particularidade |
|---:|---|---|---|
| 240 | `Page::LayOut`, **só se** `m_svgBoundingBoxes` está ligada | `BBOX_BOTH` | opcional; é o que popula as caixas para a saída de debug |
| 301 | `Page::LayOutTranscription`, só se `!m_layoutDone` | `BBOX_HORIZONTAL_ONLY` | documentos de transcrição |
| **410** | `Page::LayOutHorizontally` | `BBOX_HORIZONTAL_ONLY` | **com `view.SetSlurHandling(SlurHandling::Ignore);`** |
| **532** | `Page::LayOutVertically` | `BBOX_BOTH` | depois de `AlignVerticallyFunctor` |

O padrão é sempre o mesmo:

```cpp
View view;
view.SetDoc(doc);
BBoxDeviceContext bBoxDC(&view, 0, 0, BBOX_HORIZONTAL_ONLY);
// Do not do the layout in this view - otherwise we will loop...
view.SetPage(this, false);
view.DrawCurrentPage(&bBoxDC, false);
```

Repare no `false` de `SetPage` (não refaz layout) e no `false` de `DrawCurrentPage` (não desenha
fundo). Os dois são essenciais para não entrar em recursão.

Leia também `origin/src/src/page.cpp:396-608` inteiro, para ver onde exatamente as chamadas caem
dentro das sequências de functors.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/model/doc.dart` — remover o import de `headless_extents.dart` (linha 122-123)
  e a chamada `HeadlessExtents(doc)` (linha 497); pôr no lugar o fluxo `View` + `BBoxDeviceContext`
  nas **duas** posições (`page.cpp:410` e `:532`).
- **Alterar** `lib/src/model/system_page_elements.dart` (onde vive `Page`) — se as fases de layout
  moram lá, é lá que as chamadas entram.
- **DELETAR** `lib/src/rendering/headless_extents.dart`.
- **Alterar** `lib/src/layout/floating_positioner.dart:445` — trocar a aproximação de sobreposição
  por retângulo simples pela lógica do C++ (`origin/src/src/floatingobject.cpp`, procure
  `HorizontalContentOverlap`/`VerticalContentOverlap`).
- **Alterar** `lib/src/layout/slur_positioning.dart` — remover as 3 aproximações
  (linhas 11, 375, 534) e portar o que o C++ faz de verdade
  (`origin/src/src/adjustslursfunctor.cpp` e `origin/src/src/slur.cpp`).
- **Alterar** `lib/src/layout/lay_out_vertically.dart:18` — o comentário que cita `headless_extents`.
- **Alterar** os testes que dependiam das aproximações.

## Passo a passo

1. **Antes de qualquer coisa**, rode `dart run tool/validate_layout.dart` e
   `dart run tool/compare_svg.dart --all` e **grave os dois relatórios em `/tmp`** para comparar
   depois. Sem isso você não consegue julgar a virada.
2. Leia `page.cpp:221-247`, `:249-317`, `:396-497`, `:509-608` inteiros.
3. Encontre no Dart onde as fases horizontal e vertical estão implementadas
   (`grep -n "layOutHorizontally\|layOutVertically\|HeadlessExtents" lib/src/model/doc.dart lib/src/model/system_page_elements.dart`).
4. Insira o fluxo `View` + `BBoxDeviceContext` nos dois pontos, com os modos e o `SlurHandling`
   corretos. **Não remova `headless_extents.dart` ainda** — rode os dois lado a lado uma vez e
   compare as caixas produzidas, para saber onde a aproximação estava mentindo. Registre isso no
   relatório: é a informação mais valiosa desta tarefa.
5. **Agora** delete `headless_extents.dart` e o import.
6. Rode `dart test`. **Vai quebrar.** Para cada teste quebrado, decida:
   - o valor esperado do teste vinha da aproximação → **corrija o teste** para o valor do C++
     (obtenha-o do binário: `./build/verovio -r verovio_dart/assets/data -o /tmp/x.svg <arquivo>` e leia
     a coordenada no SVG). Explique no relatório;
   - o valor esperado vinha do C++ e agora não bate → **é bug seu**, conserte o código.
   **Nunca** relaxe uma asserção sem cair num destes dois casos, com justificativa.
7. Elimine as aproximações de `floating_positioner.dart` e `slur_positioning.dart`.
8. Rode `dart run tool/validate_layout.dart` e compare com o relatório de antes.
9. Rode `dart run tool/compare_svg.dart --all` e compare.
10. Persiga cada divergência nova. Use a política da seção 7 do `00-MESTRE.md`.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde (contagem pode variar; **nenhum teste em `skip`**)
- [ ] `ls lib/src/rendering/headless_extents.dart` → **arquivo não existe**
- [ ] `grep -rn "HeadlessExtents\|headless_extents" lib/ test/ tool/` → **nenhum resultado**
- [ ] `grep -rn "Approximation:" lib/src/` → **nenhum resultado**
- [ ] `dart run tool/validate_layout.dart` roda sobre os 621 arquivos e o número de timemaps
      `match` é **maior ou igual** ao registrado na tarefa 04j; se for menor, o relatório lista
      arquivo por arquivo o que regrediu e por quê
- [ ] `dart run tool/compare_svg.dart --all` roda sem exceção e o relatório traz o número de limpos
- [ ] O relatório traz uma tabela **antes × depois** com as quatro contagens do validate_layout e
      as duas do compare_svg
- [ ] Relatório em `prompts/reports/05-12.md`
- [ ] `PLANO.md`: checkbox da virada marcado, e a nota da Fase 4 sobre `headless_extents` removida

## Armadilhas conhecidas

- **Recursão infinita.** `SetPage(page, false)` e `DrawCurrentPage(dc, false)`. O C++ deixa um
  comentário explícito sobre isso; se você passar `true`, o layout chama o desenho que chama o
  layout. O sintoma é stack overflow ou o processo pendurado.
- **`SlurHandling::Ignore` na fase horizontal.** Sem ele, ligaduras entram na conta horizontal e
  todo o espaçamento sai errado — e o erro é sutil, não catastrófico.
- Os modos: `BBOX_HORIZONTAL_ONLY` na horizontal, `BBOX_BOTH` na vertical. Trocar é fácil e o
  resultado quase funciona.
- **Ordem**: a chamada de `page.cpp:410` vem **antes** de `AdjustOssiaStaffDefFunctor`, não depois.
  A de `:532` vem **depois** de `AlignVerticallyFunctor` e antes de `AdjustArticWithSlursFunctor`.
- Performance: desenhar a página inteira duas vezes por layout é caro. Se `dart test` passar de
  60 s, meça antes de otimizar — e **não** otimize desviando do C++.
- Teste em `skip: true` é reprovação automática desta tarefa.

## Fora de escopo

- `view_element.cpp`, `view_control.cpp` etc. — enquanto eles forem stubs, as caixas dos elementos
  de camada continuarão vazias e muitos números não vão bater. **Isso é esperado e tem de estar
  escrito no relatório**: a virada é estrutural, o fechamento numérico vem com as tarefas 05-13
  em diante e culmina na 05-25.
