# 05-29 — Header e footer no layout: alturas, cast-off e o deslocamento do sistema

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Com a 05-28 o `pgHead` e o `pgFoot` sabem a própria altura. Esta tarefa faz a **página** usar essa
altura — que é o que hoje desloca **todos** os 623 arquivos do corpus.

Medido em `test/corpus/note/note-001.mei`: as cinco linhas da pauta saem em
`540 / 720 / 900 / 1080 / 1260`, e no C++ em `1267 / 1447 / 1627 / 1807 / 1987`. Diferença constante
de **727 unidades**, que é exatamente a altura do cabeçalho que o Dart nunca subtrai. A cabeça da
nota sai em `x=3026` nos dois lados: o eixo horizontal está certo, o vertical inteiro está deslocado
por um único termo faltante.

O termo está aqui, `lib/src/layout/lay_out_vertically.dart:916-923`:

```dart
FunctorCode visitPage(Page page) {
  _justificationSum = 0;
  // Deviation: the header adjustment arrives with the running element
  // phase (Page.getHeader returns null until then).
  return FunctorCode.continue_;
}
```

`Page.getHeader` já **não** devolve `null` desde a 05-25. A fase chegou; o desvio ficou.

## Pré-condições

Tarefa **05-28** concluída.

```bash
cd verovio_dart
dart test test/text_layout_element_test.dart 2>&1 | tail -1    # verde
dart run tool/compare_svg.dart --all --mode=structural         # anote o ANTES
```

## Referência C++

| Arquivo:linha | O que fazer |
|---|---|
| `origin/src/src/alignfunctor.cpp:782-795` | `AlignSystemsFunctor::VisitPage` — `header->SetDrawingYRel(m_shift)` e, **se `headerHeight > 0`**, `m_shift -= headerHeight` |
| `origin/src/src/alignfunctor.cpp:797-822` | `AlignSystemsFunctor::VisitPageEnd` — `m_drawingJustifiableHeight -= footer->GetTotalHeight()`, e os **dois** ramos de posicionamento do rodapé (`adjustPageHeight` ligado: abaixo do último sistema com `m_topMarginPgFooter`; desligado: `footer->SetDrawingYRel(footer->GetContentHeight())`) |
| `origin/src/src/page.cpp:595-601` | `Page::LayOutVertically` chama `GetHeader()->AdjustRunningElementYPos()` e `GetFooter()->AdjustRunningElementYPos()` **depois** de `AdjustCrossStaffYPos` e **antes** do `AlignSystemsFunctor` |
| `origin/src/src/score.cpp:104-140` | `Score::CalcRunningElementHeight` — cria **duas páginas descartáveis**, faz `LayOutVertically` em cada uma e grava `m_drawingPgHeadHeight`/`PgFootHeight` (página 1) e `m_drawingPgHead2Height`/`PgFoot2Height` (página 2), depois deleta as duas |
| `origin/src/src/doc.cpp:1138-1140` | onde `CalcRunningElementHeight` é chamado: dentro do cast-off, **depois** do `LayOutVertically` da página única e **antes** do `CastOffPagesFunctor` |
| `origin/src/src/castofffunctor.cpp:284-285, 335-336, 391-396` | `CastOffPagesFunctor` — os quatro campos e `GetAvailableDrawingHeight()`, que escolhe o par de alturas por `m_firstCastOffPage` |
| `origin/src/src/page.cpp` `Page::GetContentHeight` | soma `GetFooter()->GetTotalHeight(doc)` — é o desvio de `lib/src/model/doc.dart:802` |
| `origin/src/src/toolkit.cpp:820-834` | `LoadData` — **footer primeiro, header depois**, cada um com sua condição, e `GenerateMeasureNumbers()` logo em seguida |
| `origin/src/src/doc.cpp:298-330` | `Doc::GenerateMeasureNumbers` — **não existe em Dart** (`grep -rn "generateMeasureNumbers" lib/src/` → nada) |

## Os cinco pontos

### (a) `AlignSystemsFunctor` volta a ter cabeça e pé

`lib/src/layout/lay_out_vertically.dart:916-933`. Porte `VisitPage` e `VisitPageEnd` inteiros. O
`if (headerHeight > 0)` do C++ não é decorativo: cabeçalho vazio não pode consumir margem.

### (b) `Page::LayOutVertically` chama `AdjustRunningElementYPos`

Ache onde a sequência de functors da fase vertical está montada no Dart (`lib/src/model/doc.dart`,
método `_layOutVertically`/equivalente) e insira as duas chamadas **na posição exata** do C++
(`page.cpp:595-601`): depois de `AdjustCrossStaffYPosFunctor`, antes de `AlignSystemsFunctor`.
Posição errada dá número plausível e errado.

### (c) `Score::CalcRunningElementHeight` e o cast-off

Este é o ponto mais delicado da tarefa: o C++ **monta e destrói duas páginas de mentira** só para
medir a altura do cabeçalho na primeira página e nas demais (que podem diferir, por
`PGFUNC_first` vs `PGFUNC_all`). Porte o método como está, inclusive a criação e a remoção das
páginas, e chame-o do mesmo ponto do cast-off (`doc.cpp:1138`).

Depois ligue os quatro campos em `lib/src/layout/cast_off.dart` (hoje os desvios das linhas 369 e
492 dizem que as alturas são 0) e porte `GetAvailableDrawingHeight`. É isso que decide quantos
sistemas cabem numa página — enquanto for 0, todo documento de mais de uma página quebra nas
posições erradas.

### (d) `Doc::GetAdjustedDrawingPageHeight` e `Page::GetContentHeight`

`lib/src/model/doc.dart:802` tem o desvio "the footer total height arrives with the running element
phase". Feche-o com `page.cpp` `Page::GetContentHeight`, que soma `GetFooter()->GetTotalHeight(doc)`.
Confira também `Doc::GetAdjustedDrawingPageHeight` (`doc.cpp`) — a divisão por `DEFINITION_FACTOR`
é inteira.

### (e) O caminho de chamada: `Toolkit::LoadData` e `GenerateMeasureNumbers`

`lib/src/toolkit.dart:124-130` hoje faz:

```dart
try { doc.generateHeader(); } catch (_) {}
try { doc.generateFooter(); } catch (_) {}
```

Três defeitos numa linha e meia: a ordem é o inverso da do C++ (`toolkit.cpp:825-830` faz footer,
depois header), não há condição nenhuma (o C++ testa `footerOption`/`headerOption`), e o
`catch (_) {}` esconde qualquer erro na geração.

- Ordem: corrija agora.
- Condição: as opções `header`/`footer`/`adjustPageHeight` são da Fase 7 (07-02). Escreva a condição
  contra o valor **default** do C++ (`HEADER_auto`, `FOOTER_auto`, `adjustPageHeight` falso), com um
  `Deviations from the C++:` dizendo que o gate real chega com as opções — e **sem** `catch`.
- `catch (_) {}`: fora. Se `generateHeader` quebra, é defeito a consertar, não a esconder.
- E porte `Doc::GenerateMeasureNumbers` (`doc.cpp:298-330`), que é chamado logo depois em
  `LoadData` e hoje simplesmente não existe: sem ele os `mNum` gerados a partir de `@n` não aparecem
  e todo arquivo com número de compasso diverge.

Faça o mesmo caminho valer em `lib/src/testing/svg_compare.dart` — o harness tem de renderizar pelo
**mesmo** caminho do `Toolkit`, não por uma cópia paralela que pode divergir dele. Se o jeito mais
limpo for o harness chamar `Toolkit.loadData`, faça isso e registre no relatório.

## Arquivos Dart a criar/alterar

- `lib/src/layout/lay_out_vertically.dart` — (a)
- `lib/src/model/doc.dart` — (b), (d), e `generateMeasureNumbers`
- `lib/src/model/basic_elements.dart` (onde vive `Score`) — (c) `calcRunningElementHeight`
- `lib/src/layout/cast_off.dart` — (c) os quatro campos e `getAvailableDrawingHeight`
- `lib/src/toolkit.dart` e `lib/src/testing/svg_compare.dart` — (e)
- **Criar** `test/running_element_layout_test.dart` — o teste desta tarefa

## O teste

`test/running_element_layout_test.dart`:

1. **O deslocamento de 727.** Para `test/corpus/note/note-001.mei`, afirme as cinco coordenadas das
   linhas de pauta **iguais às do golden** (`1267 / 1447 / 1627 / 1807 / 1987`), lidas do golden pelo
   próprio teste, não escritas à mão.
2. **Cabeçalho vazio não consome margem.** Um documento sem título gera `pgHead` de altura 0 e o
   primeiro sistema não desce (`if (headerHeight > 0)`).
3. **`CalcRunningElementHeight` mede as duas páginas.** Afirme `drawingPgHeadHeight` e
   `drawingPgHead2Height` num arquivo com `pgHead` `PGFUNC_first` diferente do `PGFUNC_all`, e que
   as duas páginas descartáveis não sobreviveram ao método.
4. **O cast-off usa as alturas.** Num arquivo multi-página do corpus, afirme que o número de
   sistemas na primeira página muda quando o cabeçalho existe — e bate com o golden.
5. **`GenerateMeasureNumbers`.** Um `measure@n` sem `mNum` filho ganha um `mNum` gerado; um `mNum`
   já gerado numa execução anterior é removido antes (é o que o C++ faz em `doc.cpp:305-312`).

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline (8)
- [ ] `dart test` verde, nenhum teste em `skip`
- [ ] `grep -rn "arrives with the running element" lib/src/` → **nenhum resultado**
- [ ] `grep -rn "generateMeasureNumbers" lib/src/` → existe e é chamado no caminho de `loadData`
- [ ] `grep -n "catch (_)" lib/src/toolkit.dart` → nenhum em volta de `generateHeader`/`Footer`
- [ ] As linhas de pauta de `note-001.mei` batem **exatamente** com o golden (epsilon 0)
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **sobe** em relação ao ANTES; o
      relatório traz a tabela ANTES × DEPOIS por diretório do corpus
- [ ] `dart run tool/compare_svg.dart --all --mode=numeric --epsilon=0` sobe também — esta é a
      primeira tarefa da reabertura em que o número **numérico** tem chance de subir de verdade, já
      que o eixo vertical inteiro depende deste termo. Se ele não subir, algo está errado: investigue
      antes de fechar
- [ ] `dart run tool/validate_layout.dart` não regride (a fase vertical mudou; compare com o número
      registrado na 04j e explique cada diferença)
- [ ] Relatório em `prompts/reports/05-29.md`
- [ ] `PLANO.md`: linha da 05-29

## Armadilhas conhecidas

- **A ordem das chamadas dentro de `LayOutVertically`.** `AdjustRunningElementYPos` vem depois do
  `AdjustCrossStaffYPos` e antes do `AlignSystems`. Antes disso, as caixas dos filhos do cabeçalho
  ainda não estão completas e você mede zero.
- **`m_shift` é um acumulador que desce.** `VisitSystem` já o usa (`lay_out_vertically.dart:936-958`);
  `VisitPage` tem de subtrair a altura do cabeçalho **antes** do primeiro `VisitSystem`, não depois.
- **As duas páginas de mentira do `CalcRunningElementHeight` precisam ser removidas.** Em C++ é
  `pages->DeleteChild(page1)`; em Dart, garanta que elas não fiquem na árvore nem no `Pages` —
  um teste que conte `pages.childCount` antes e depois pega isso.
- **`m_firstCastOffPage`** escolhe entre o par 1 e o par 2 de alturas. Usar sempre o par 1 funciona
  em documentos de uma página e erra silenciosamente em todos os outros.
- Os dois ramos de `VisitPageEnd` dependem de `adjustPageHeight`, que é opção da Fase 7. Porte os
  dois ramos e escolha pelo default do C++, com o desvio documentado.
- Espere quebrar testes de layout da Fase 4 que fixaram coordenadas verticais medidas **sem**
  cabeçalho. Cada um cai na §8.1: ou o esperado veio da ausência do cabeçalho (corrija o teste,
  citando `alignfunctor.cpp:782`), ou a mudança está errada.

## Fora de escopo

- As opções `header`, `footer`, `usePgHeaderForAll`, `adjustPageHeight` (Fase 7, 07-02/07-03).
- `Div` como elemento de sistema — só a `GetTotalHeight` dele, que a 05-28 já portou.
- A virada do `BBoxDeviceContext` (05-30).
