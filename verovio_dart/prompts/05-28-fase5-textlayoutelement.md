# 05-28 — `textlayoutelement.cpp` e `runningelement.cpp`: o modelo dos elementos correntes

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

A tarefa 05-25 acrescentou `Doc::GenerateHeader` / `GenerateFooter`: o `pgHead` e o `pgFoot`
autogerados **existem** na árvore e **aparecem** no SVG. Mas ninguém os mede nem os posiciona, porque
o arquivo que faz isso nunca foi portado.

`origin/src/src/textlayoutelement.cpp` — **313 linhas** — é a grade de 9 células (3 alinhamentos
horizontais × 3 verticais) em que um `PgHead`, um `PgFoot` ou um `Div` distribui seus filhos de
texto, e é de onde saem todas as alturas e larguras desses objetos. Em Dart,
`class TextLayoutElement` (`lib/src/model/text_elements.dart:22`) tem exatamente três métodos:
`reset`, `isSupportedChild` e `filterList`. **Nenhuma** das 13 funções de geometria existe.

Consequência medida em `test/corpus/note/note-001.mei`: o Dart emite

```xml
<text y="28700" font-size="0px">
  <tspan class="rend" x="0" y="28700" text-anchor="middle">
```

onde o C++ emite

```xml
<text font-size="0px">
  <tspan class="rend" x="10000" y="415" text-anchor="middle">
```

Esta tarefa porta o **modelo**: as células, as alturas, as larguras, o escalonamento e o
`AdjustRunningElementYPos`. Ligar isso ao layout da página é a tarefa **05-29**; as duas juntas é que
tiram o deslocamento vertical de 727 unidades que hoje afeta **todos** os 623 arquivos.

## Pré-condições

Tarefas **05-26** e **05-27** concluídas.

```bash
cd verovio_dart
dart run tool/compare_svg.dart --all --mode=structural   # ≥112/623 — anote o ANTES
grep -c "getRowHeight\|getCellHeight\|adjustRunningElementYPos" -r lib/src/   # 0 hoje
```

## Referência C++

| Arquivo | Linhas | O que porta |
|---|---:|---|
| `origin/src/src/textlayoutelement.cpp` | 313 (inteiro) | `Reset`, `IsSupportedChild`, `FilterList`, `ResetCells`, `AppendTextToCell`, `GetContentHeight`, `GetContentWidth`, `GetRowHeight`, `GetColHeight`, `GetCellHeight`, `GetRowWidth`, `GetColWidth`, `GetCellWidth`, `AdjustDrawingScaling`, `ResetDrawingScaling`, `AdjustRunningElementYPos`, `GetAlignmentPos` |
| `origin/src/include/vrv/textlayoutelement.h` | 30-120 | os campos `m_cells[9]`, `m_drawingScalingPercent[3]`, e o `POSITION_*` que indexa a grade |
| `origin/src/src/runningelement.cpp` | 59-202 | `Reset`, `GetDrawingX`, `GetDrawingY`, `SetDrawingYRel`, `GetTotalWidth`, `SetDrawingPage`, `SetCurrentPageNum`, `LoadFooter`, `AddPageNum` |
| `origin/src/src/pghead.cpp:20-40` | | `PgHead::GetTotalHeight` = `GetContentHeight()` + `m_bottomMarginPgHead * unit`, **só quando a altura é > 0** |
| `origin/src/src/pgfoot.cpp:20-40` | | `PgFoot::GetTotalHeight`, idem com `m_topMarginPgFooter` |
| `origin/src/src/div.cpp:72-116` | | `Div::GetTotalHeight` — a terceira implementação do mesmo virtual puro |
| `origin/src/src/alignfunctor.cpp:655` | | `AlignVerticallyFunctor::VisitRunningElement` — o que hoje é o stub de `lib/src/layout/lay_out_vertically.dart:250` |
| `origin/src/src/alignfunctor.cpp:587` | | `AlignVerticallyFunctor::VisitDiv`, que usa `GetTotalHeight` |
| `origin/src/src/view_text.cpp:642-701` | | `View::DrawRunningElements` / `DrawTextLayoutElement` — os consumidores; leia para saber que valores eles pedem |

Duas armadilhas de aritmética que valem a leitura atenta (§7 do `00-MESTRE.md`):

- `AdjustRunningElementYPos` (`textlayoutelement.cpp:222-268`) usa `/ 2` sobre `int` na linha do meio
  (`colYShift = (currentRowHeigt - this->GetCellHeight(cell)) / 2;`) — em Dart é `~/`, e o C++ trunca
  para zero.
- `GetAlignmentPos` (`:271-291`) monta o índice da célula somando um `POSITION_*` horizontal a um
  vertical. O `default:` do primeiro `switch` cai em `POSITION_LEFT` e o do segundo em
  `POSITION_MIDDLE` — **não** em zero nos dois casos. Copie os `default` como estão.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/model/text_elements.dart` — `TextLayoutElement` ganha a grade de 9 células e
  as 13 funções; `RunningElement` ganha o que falta de `runningelement.cpp`.
- **Alterar** `lib/src/model/misc_elements_gen.dart` — `PgHead.getTotalHeight` / `PgFoot.getTotalHeight`
  (arquivo mantido à mão desde a 04i; registre a edição no relatório, §4.3).
- **Alterar** `lib/src/layout/lay_out_vertically.dart:250` — `visitRunningElement` deixa de ser stub
  e passa a fazer o que `AlignVerticallyFunctor::VisitRunningElement` (`alignfunctor.cpp:655`) faz;
  confira também `visitDiv`.
- **Criar** `test/text_layout_element_test.dart` — geometria da grade (abaixo).

## O teste

`test/text_layout_element_test.dart` tem de cobrir a grade **por construção**, não só pelo resultado
final no SVG:

1. **As 9 células.** Monte um `PgHead` com `Rend` em cada combinação `halign` × `valign` e afirme
   que `getAlignmentPos` devolve o índice certo para as 9, incluindo os dois `default` assimétricos.
2. **As alturas.** Para uma grade conhecida, afirme `getCellHeight`, `getRowHeight`, `getColHeight`
   e `getContentHeight` com números calculados à mão a partir das caixas dos filhos — não a partir
   da sua própria implementação.
3. **`adjustRunningElementYPos`.** Afirme o `drawingYRel` final de cada filho nas três linhas
   (topo alinhado ao topo, meio centralizado, base alinhada à base), com a divisão inteira do meio
   exercitada por um caso de altura ímpar.
4. **`getTotalHeight` com altura zero.** `PgHead` vazio devolve `0` e **não** soma a margem — é o
   `if (height > 0)` de `pghead.cpp:24`, e errar isso desloca a página inteira por uma margem.
5. **`setCurrentPageNum`.** O `Num` com `@label="page"` cujo texto é `#` vira o número da página
   (`runningelement.cpp:120-136`); qualquer outro `Num` fica intacto.

## Passo a passo

1. Grave o ANTES.
2. Leia `textlayoutelement.cpp` inteiro antes de escrever qualquer linha. São 313 linhas e a metade
   delas é a mesma soma vista por linha, por coluna e por célula — entender a grade uma vez evita
   três implementações divergentes.
3. Porte `TextLayoutElement` inteiro, com os doc comments citando `textlayoutelement.cpp:<linha>`
   método a método (§4.1).
4. Complete `RunningElement` (a parte que falta de `runningelement.cpp`) e as três
   `GetTotalHeight`.
5. Tire o stub de `visitRunningElement` no `AlignVerticallyFunctor`.
6. Escreva o teste e faça os cinco grupos passarem com números calculados à mão.
7. Rode `compare_svg --all`. Espere melhora **parcial**: o conteúdo do `pgHead` passa a ter
   geometria própria, mas a página ainda não o desloca — isso é a 05-29. Registre no relatório
   quanto mexeu e por que não fecha sozinho.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline (8)
- [ ] `dart test` verde, nenhum teste em `skip`
- [ ] As 17 funções da tabela de referência existem em Dart, cada uma com doc comment citando
      arquivo e linha do C++
- [ ] `test/text_layout_element_test.dart` cobre os cinco grupos, com os valores esperados
      calculados à mão (mostre a conta no comentário do teste, não só o número)
- [ ] `dart run tool/compare_svg.dart --all` não regride, e o relatório explica o que mudou e o que
      só fecha na 05-29
- [ ] O `<text>` do `pgHead` de `test/corpus/note/note-001.mei` deixa de sair com `y="28700"`; cole
      o antes e o depois no relatório ao lado do golden
- [ ] Nenhum método novo sem contraparte C++ (§8.3); auxiliares do port com `_` e documentados
- [ ] Relatório em `prompts/reports/05-28.md`
- [ ] `PLANO.md`: linha da 05-28

## Armadilhas conhecidas

- **`m_cells` tem 9 posições fixas**, não um mapa. O índice vem de `GetAlignmentPos` e a ordem
  importa (`i * 3 + j`, linha × coluna). Um `Map` "mais idiomático" muda a ordem de iteração e o
  resultado.
- `FilterList` (`textlayoutelement.cpp:56`) é o que decide **quais** filhos entram nas células.
  Portar as alturas sem portar o filtro dá números plausíveis e errados.
- `GetContentHeight` soma as **linhas**, não as células (`:90-98`). Some duas vezes e a página anda
  o dobro.
- `ResetDrawingScaling` / `AdjustDrawingScaling` (`:188-221`) só entram em jogo quando o conteúdo é
  mais largo que a página. Não são opcionais: `AdjustDrawingScaling` devolve `bool` e o chamador usa
  esse retorno.
- `RunningElement::GetDrawingX` (`runningelement.cpp:72-89`) **devolve 0**, com o cálculo por
  `halign` comentado no próprio C++. Porte o comportamento real (0) e o comentário; não "conserte"
  o C++.
- `SetDrawingPage` chama `ResetList()` e `ResetCachedDrawingX()` antes de guardar a página — a ordem
  importa porque a lista filtrada é cacheada.

## Fora de escopo

- Ligar as alturas ao cast-off, ao `AlignSystemsFunctor` e ao `Score::CalcRunningElementHeight`
  (05-29).
- `Doc::GenerateHeader` / `GenerateFooter`, que já existem desde a 05-25 — se você achar defeito
  neles, registre para a 05-29, que é quem mexe no caminho de chamada.
- As opções `header` / `footer` / `usePgHeaderForAll` do Toolkit (Fase 7).
