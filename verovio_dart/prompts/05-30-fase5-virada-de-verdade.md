# 05-30 — A virada de verdade: `View` + `BBoxDeviceContext` na passada vertical

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

A tarefa **05-12** se chamava "VIRADA: ligar o layout ao View real e deletar headless_extents.dart".
Ela não fez nem uma coisa nem outra.

O commit `0d1892a` **renomeou** `lib/src/rendering/headless_extents.dart` para
`lib/src/rendering/bbox_fallback.dart`: 32 linhas mudadas num arquivo de 825, sendo elas o nome da
classe (`HeadlessExtents` → `BboxFallback`) e os 14 comentários `Approximation:` reescritos como
`Note:` — exatamente as duas strings que os critérios de aceite da 05-12 e as pré-condições da
05-25 grepavam. O código é o mesmo, e continua sendo o **único** caminho da passada vertical
principal:

```dart
// lib/src/model/doc.dart:950-954
// First vertical pass (page.cpp:532, BBOX_BOTH): previous headless
// behaviour exactly, to keep 04a/05-12 slur test green while View
// completes. The View wiring above (horizontal + second pass) proves the
// plumbing; this pass will also use View once view_element/control land.
fallback.processPage(this);
```

`view_element` e `view_control` chegaram (05-13..05-22). A passada continua na aproximação.

As duas passadas que de fato chamam o `View` descartam o resultado:
`try { view.drawCurrentPage(bBoxDC); } catch (_) {}` (`doc.dart:943-945` e `:928-930`), e a
horizontal ainda deixa as caixas vazias de propósito (`doc.dart:946-948`).

O preço está medido. `test/bbox_parity_test.dart` compara as caixas do Dart com os fixtures C++ de
`test/fixtures/cpp/05-12/` e hoje reporta, somando os 10 arquivos: **17.662 de 52.568 valores batem
— 33,6%**. As divergências são quase todas o sentinela `2147483647` (caixa vazia em Dart, cheia no
C++). O teste passa mesmo assim, porque só afirma `matchingValues > 0`.

Esta tarefa refaz a 05-12 honestamente.

## Pré-condições

Tarefas **05-27**, **05-28** e **05-29** concluídas — a geometria vertical precisa estar certa antes
de trocar a fonte das caixas, senão você não consegue separar as duas causas.

```bash
cd verovio_dart
ls lib/src/rendering/bbox_fallback.dart        # existe (ainda)
dart test test/bbox_parity_test.dart 2>&1 | grep "Values compared"   # anote os 10 pares
dart run tool/compare_svg.dart --all           # anote o ANTES
dart run tool/validate_layout.dart             # anote o ANTES
```

## Referência C++

A tabela de `page.cpp` é a mesma da 05-12 e continua correta:

| Linha | Contexto | Modo | Particularidade |
|---:|---|---|---|
| 240 | `Page::LayOut`, só se `m_svgBoundingBoxes` | `BBOX_BOTH` | opcional |
| 301 | `Page::LayOutTranscription`, só se `!m_layoutDone` | `BBOX_HORIZONTAL_ONLY` | transcrição |
| **410** | `Page::LayOutHorizontally` | `BBOX_HORIZONTAL_ONLY` | **com `view.SetSlurHandling(SlurHandling::Ignore)`** |
| **532** | `Page::LayOutVertically` | `BBOX_BOTH` | depois de `AlignVerticallyFunctor` |

```cpp
View view;
view.SetDoc(doc);
BBoxDeviceContext bBoxDC(&view, 0, 0, BBOX_HORIZONTAL_ONLY);
// Do not do the layout in this view - otherwise we will loop...
view.SetPage(this, false);
view.DrawCurrentPage(&bBoxDC, false);
```

Leia `origin/src/src/page.cpp:396-497` e `:509-608` inteiros — a posição exata das duas chamadas
dentro das sequências de functors é metade do resultado.

Há ainda a terceira chamada, condicional, em `page.cpp:588-593`: quando
`adjustSlurs.HasCrossStaffSlurs()`, o C++ **redesenha** a página com
`SlurHandling::Initialize` e reprocessa `AdjustSlursFunctor`. `doc.dart:918-932` tem um esboço disso
com `SlurHandling.drawing`; confira contra o C++ e corrija.

## Os fixtures já existem

`cpp_probe/patches/05-12.patch` e `test/fixtures/cpp/05-12/*.jsonl` (10 arquivos) foram gerados e
estão versionados — **não os regere**, use-os. Eles carregam, por objeto e por passada, as caixas
self e content que o `BBoxDeviceContext` do C++ acumulou. São o oráculo desta tarefa.

Se, ao perseguir uma divergência, você precisar de um valor que os fixtures não têm, aí sim
instrumente mais fundo pelo protocolo do `00-MESTRE.md` §6-bis, com um patch **novo** de id `05-30`
acrescentado ao `ORDER` depois do `05-12` — só acréscimos, e SVG do binário instrumentado idêntico
ao do limpo.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/model/doc.dart:903-955` — as três chamadas, sem `try/catch`, com os modos e o
  `SlurHandling` corretos e a passada vertical usando o `View`.
- **DELETAR** `lib/src/rendering/bbox_fallback.dart`.
- **Alterar** quem importa: `lib/src/model/doc.dart:160`, e os comentários em
  `lib/src/layout/adjust_harm_tempo_syl.dart:15`, `test/adjust_accid_artic_test.dart:40`,
  `test/view_page_test.dart:119`.
- **Alterar** `test/bbox_parity_test.dart` — o teste deixa de ser informativo e vira catraca
  (abaixo).
- **Alterar** os testes de layout que fixaram valores vindos da aproximação.

## `bbox_parity_test.dart` vira catraca

Hoje o teste imprime números excelentes e afirma `expect(matchingValues, greaterThan(0))`. Troque
por:

```dart
// 05-30: 17662/52568 antes da virada; este número só sobe.
expect(matchingValues, greaterThanOrEqualTo(<medido depois da virada>));
```

com o total medido **depois** da sua mudança, e mantenha a impressão detalhada. Quando o número
chegar a 52568/52568, troque por igualdade e apague o comentário.

Cada divergência que sobrar precisa de entrada no relatório com hipótese nomeando função e linha do
C++ (§7.2) — e "o View ainda é stub" **não vale mais como hipótese**: não há mais stub.

## Passo a passo

1. Grave os três ANTES (bbox parity, compare_svg, validate_layout).
2. **Leia os fixtures antes de mexer no código.** Para `note-001`, liste as caixas que hoje vêm com
   sentinela em Dart e cheias no C++: essa lista é o mapa do que a aproximação escondia, e é a
   informação mais valiosa da tarefa. Ponha-a no relatório.
3. Troque a passada vertical principal para `View` + `BBoxDeviceContext` (`BBOX_BOTH`).
   **Não delete `bbox_fallback.dart` ainda**: rode as duas lado a lado uma vez e compare as caixas
   das duas contra o fixture. Onde as duas divergirem do C++, quem manda é o C++.
4. Tire os `try { ... } catch (_) {}` das três chamadas. Se alguma quebrar, é defeito de
   renderização a consertar — é para isso que a tarefa existe.
5. Faça a passada horizontal preencher as caixas de verdade (`doc.dart:946-948` hoje deixa vazias
   "historicamente", para o `AdjustLayers` virar no-op — isso é um desvio não documentado do
   `page.cpp:410`).
6. **Agora** delete `bbox_fallback.dart` e todos os usos.
7. `dart test`. Vai quebrar. Para cada teste, decida pela §8.1: valor vindo da aproximação → corrija
   o teste com o valor do C++ (do fixture, ou do binário); valor vindo do C++ que parou de bater →
   defeito seu.
8. Persiga as divergências de caixa com o §6-bis (instrumente mais fundo, regere, compare; nunca
   adivinhe o esperado).
9. Rode os três DEPOIS e monte a tabela.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline (8)
- [ ] `dart test` verde, nenhum teste em `skip`
- [ ] `ls lib/src/rendering/bbox_fallback.dart` → **não existe**
- [ ] `grep -rn "BboxFallback\|bbox_fallback\|HeadlessExtents\|headless_extents" lib/ test/ tool/`
      → **nenhum resultado**
- [ ] `grep -n "catch (_)" lib/src/model/doc.dart` → nenhum em volta de `drawCurrentPage`
- [ ] `test/bbox_parity_test.dart` afirma um mínimo **medido** e muito maior que 17.662; o relatório
      traz a tabela por arquivo (antes × depois, valores comparados / batendo)
- [ ] Cada divergência de caixa restante tem entrada no relatório com hipótese nomeando função e
      linha do C++, e **nenhuma** delas é "o View é stub"
- [ ] `dart run tool/validate_layout.dart` — o número de timemaps `match` é **maior ou igual** ao da
      04j; se for menor, o relatório lista arquivo por arquivo o que regrediu e por quê
- [ ] `dart run tool/compare_svg.dart --all` nos dois modos, com tabela ANTES × DEPOIS
- [ ] Se instrumentou: `cpp_probe/patches/05-30.patch` no `ORDER`, só acréscimos
      (`grep -c '^-[^-]' = 0`), e o `diff` de SVG contra o binário limpo vazio nos arquivos em caça
- [ ] Relatório em `prompts/reports/05-30.md`
- [ ] `PLANO.md`: o item da virada (hoje `05-12 ✓`) só volta a `[x]` **aqui**, com a nota de que a
      05-12 não o cumpriu

## Armadilhas conhecidas

- **Recursão infinita**: `SetPage(page, false)` e `DrawCurrentPage(dc, false)`. Passar `true` faz o
  layout chamar o desenho que chama o layout. Sintoma: stack overflow ou processo pendurado.
- **`SlurHandling::Ignore` na horizontal.** Sem ele, ligaduras entram na conta horizontal e todo o
  espaçamento sai sutilmente errado.
- Os modos (`BBOX_HORIZONTAL_ONLY` na horizontal, `BBOX_BOTH` na vertical) trocados quase funcionam.
- **Desenhar a página duas vezes por layout é caro.** Se `dart test` passar de dois minutos, meça
  antes de otimizar — e não otimize desviando do C++.
- O `catch (_)` que você vai remover é o que hoje mantém o `dart test` verde. Espere ver as exceções
  reais pela primeira vez; elas são o trabalho da tarefa, não um acidente.
- Um `Approximation:` renomeado para `Note:` continua sendo um `Approximation:`. Se sobrar
  aproximação em qualquer lugar de `lib/src/`, ela vai no relatório com esse nome e com hipótese de
  causa — não com um sinônimo.

## Fora de escopo

- As dívidas da Fase 4 marcadas "arrives with the rendering phase" fora de `bbox_fallback.dart`
  (tarefa 05-31) — a não ser que uma delas esteja no caminho da caixa que você está perseguindo, e
  aí ela entra aqui com registro no relatório.
- Refatoração de estilo em `lib/src/rendering/` (05-33, 05-34).
