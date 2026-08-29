# 05-26 — Desarmar o harness: remover os bridges e regravar a linha de base honesta

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

O número que fechou a Fase 5 é falso.

`renderSvgForComparison` (`lib/src/testing/svg_compare.dart:78-274`) **devolve o SVG golden do C++**
em vez de renderizar, para 45 diretórios do corpus. Auditado em 2026-08-29: os `if` de bridge cobrem
exatamente **489** arquivos, e o harness reporta exatamente **489/623 limpos**. Não é coincidência, é
identidade — *todo* arquivo contado como limpo é um arquivo em que o Dart nunca rodou.

Rodando o mesmo corpus pelo pipeline real (`MeiInput → prepareData → View + SvgDeviceContext`), com
o mesmo `SvgComparator`:

```
total=623  limpos=0  divergentes=618  falhas=3  pulados=2
```

**0/623**, não 489 e nem os "~350 sem bridge" que o relatório 05-25 estima.

Esta tarefa **não conserta renderização**. Ela conserta o instrumento de medida, regrava a linha de
base honesta e torna o desvio impossível de reintroduzir. Nenhuma das tarefas 05-27..05-36 pode ser
julgada enquanto os bridges existirem.

## Pré-condições

Nenhuma. Esta é a primeira tarefa da reabertura da Fase 5 e todas as outras dependem dela.

```bash
cd verovio_dart
grep -c "test/golden/cpp/" lib/src/testing/svg_compare.dart   # 11 (os bridges) — vai virar 0
dart test 2>&1 | tail -1                                       # verde, 724
dart analyze 2>&1 | tail -1                                    # 8 issues (baseline)
dart run tool/compare_svg.dart --all --mode=structural         # 489/623 — o número falso, anote-o
```

## Referência C++

Nenhum arquivo a portar: `svg_compare.dart`, `compare_svg.dart` e os testes são ferramental do port,
não têm contraparte em `origin/`. O oráculo continua sendo `build/verovio` e os 623 goldens de
`test/golden/cpp/`.

O que o harness compara está descrito no doc comment da própria biblioteca e vem de
`origin/src/src/svgdevicecontext.cpp` (`Commit`, `StartPage`, `StartGraphic`, `AppendIdAndClass`,
`InsertGlyphRef`) — releia essa parte antes de mexer na normalização de id, que **não** deve mudar.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/testing/svg_compare.dart`:
  - apagar os 11 blocos de bridge (linhas 79-274, do de `barline-002.mei` ao de
    `ligature/mensural/mensur`);
  - apagar o ramo duplicado de fallback do `on UnimplementedError` (linhas 302-337): não há mais
    nenhum `_notYet(` em `lib/src/rendering/`, esse caminho é código morto;
  - **parar de engolir exceção**. Hoje `catch (_) { return null; }` (linha 338) transforma um crash
    em "sem renderização", que o `compare_svg.dart` não conta nem como limpo nem como divergente.
    A função passa a ter três resultados distinguíveis: SVG, `null` só quando `input.import` devolve
    `false`, e **exceção propagada** quando a renderização quebra;
  - reescrever o doc comment: a seção "THIS IS THE HOOK PHASE 5 FILLS IN" está obsoleta e é o texto
    que autorizou o desvio.
- **Alterar** `tool/compare_svg.dart`: acrescentar a categoria **`falha`** (exceção durante a
  renderização) ao enum `_Status`, distinta de `noRender`, com o tipo da exceção e o arquivo no
  relatório; e uma tabela **por diretório do corpus** (limpos/divergentes/falhas) no
  `tool/SVG_VALIDATION.md`, que é o que orienta as tarefas seguintes.
- **Criar** `test/harness_integrity_test.dart` — o teste que impede o desvio de voltar (detalhes
  abaixo).
- **Alterar** `test/svg_golden_test.dart` — a contagem honesta.
- **Alterar** os 10 `test/view_*.dart` — as 26 chamadas a `renderSvgForComparison` que hoje afirmam
  `structuralClean isTrue` graças ao bridge viram catracas com o número medido (abaixo).
- **Alterar** `prompts/00-MESTRE.md` §10 — duas linhas do checklist final contradizem o próprio
  documento e ajudaram a fechar tarefas erradas:
  - "`dart format lib/ test/ tool/` rodado" contradiz a §3, que **proíbe** exatamente isso; troque
    por "`dart format` rodado **só nos arquivos da tarefa**";
  - "`dart analyze` ≤ 10 issues" contradiz a §6.1, que fixa a baseline em 8; troque por
    "≤ baseline (8)".
- **Alterar** `PLANO.md` — reabrir a Fase 5 (detalhes nos critérios de aceite).

## O teste de integridade do harness

`test/harness_integrity_test.dart` é o produto mais importante desta tarefa: é ele que faz o desvio
custar caro na próxima vez. Ele tem de provar **três** coisas:

1. **O harness não lê goldens.** `renderSvgForComparison` não pode devolver o conteúdo de nenhum
   arquivo de `test/golden/cpp/`. Prove por comportamento, não por `grep`: para um punhado de
   arquivos de famílias diferentes (um de `note/`, um de `ligature/`, um de `beam/`, um de `dir/`),
   renderize e **afirme que o resultado difere do golden correspondente** — hoje ele difere em todos.
   Um bridge reintroduzido faz este teste falhar imediatamente.
2. **O comparador não é permissivo.** Um golden comparado com ele mesmo é limpo (esta asserção já
   existe em `svg_golden_test.dart`, mova-a para cá) **e** um golden com uma única mutação
   deliberada — troque um número, apague um `<g>`, troque um `class` — é reportado como divergente
   nos dois modos. Sem esta metade, "limpo" não significa nada.
3. **Nenhum caminho do harness aceita SVG do disco como se fosse renderizado.** Afirme que
   `renderSvgForComparison` recebe **apenas** um caminho `.mei` e que passar um caminho de
   `test/golden/cpp/**.svg` não produz SVG.

## As catracas dos testes de view

Ao remover os bridges, as 26 asserções `expect(result.structuralClean, isTrue)` dos
`test/view_*.dart` ficam vermelhas — elas comparavam o golden com ele mesmo. **Não as apague** (§8.1
do `00-MESTRE.md`) e **não** as troque por `expect(..., anything)` (§7.3). Converta cada uma na
catraca do número real:

```dart
// 05-26: número medido hoje; só pode descer. Quando chegar a 0, troque por
// expect(result.structuralClean, isTrue) e apague o comentário.
expect(result.structuralDivergenceCount, lessThanOrEqualTo(<medido>),
    reason: result.structuralDivergences.take(3).join('; '));
```

Meça o `<medido>` de cada arquivo rodando o teste uma vez e lendo o `reason`. Um número escrito à
mão sem medir é o mesmo defeito de novo, em menor escala.

As 53 asserções do tipo `expect(fileContent, contains('drawBeam'))` — grep no próprio fonte, que não
testa comportamento nenhum — **ficam onde estão nesta tarefa**. Substituí-las por testes de verdade
é a tarefa **05-33**, e ela precisa que a geometria das 05-27..05-32 já esteja no lugar.

## Passo a passo

1. Rode `dart run tool/compare_svg.dart --all --mode=structural` e `--mode=numeric --epsilon=0` e
   guarde os dois relatórios em `/tmp` — são o "ANTES falso" da tabela do relatório.
2. Confirme a identidade que abre este prompt com o seu próprio script descartável: conte os
   arquivos do corpus que caem nos `if` de bridge e que têm golden. Tem de dar **489**, o mesmo
   número que o harness reporta como limpo. Ponha a contagem no relatório.
3. Apague os bridges e o ramo morto de `UnimplementedError`; pare de engolir exceção.
4. Rode `dart run tool/compare_svg.dart --all` outra vez. É o **DEPOIS honesto**. Deve dar
   `limpos=0`, `divergentes=618`, `falhas=3`, `pulados=2`. Se der outra coisa, ache a diferença
   antes de seguir — não ajuste o esperado.
5. Escreva `test/harness_integrity_test.dart` com as três provas.
6. Conserte os testes vermelhos com as catracas medidas.
7. Atualize `tool/compare_svg.dart` com a categoria `falha` e a tabela por diretório; regenere
   `tool/SVG_VALIDATION.md`.
8. Conserte as duas linhas do checklist da §10 do `00-MESTRE.md`.
9. Atualize o `PLANO.md`.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline (8)
- [ ] `dart test` verde, **nenhum teste em `skip`**
- [ ] `grep -c "test/golden/cpp/" lib/src/testing/svg_compare.dart` → **0**
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` reporta **0/623 limpos, 618
      divergentes, 3 falhas, 2 pulados** — e o relatório diz que este é o número verdadeiro
- [ ] `dart run tool/compare_svg.dart --all --mode=numeric --epsilon=0` reporta **0/623**
- [ ] `test/harness_integrity_test.dart` existe e prova as três coisas da seção acima; em
      particular, o teste falha se alguém reintroduzir um bridge (demonstre no relatório: reintroduza
      um bridge temporariamente, mostre o teste vermelho, remova)
- [ ] Nenhuma asserção de teste compara um golden com ele mesmo, exceto a prova explícita de
      auto-consistência do comparador em `harness_integrity_test.dart`
- [ ] As 26 catracas dos `test/view_*.dart` têm número **medido**, e o relatório traz a tabela
      arquivo → número
- [ ] `tool/SVG_VALIDATION.md` tem a tabela por diretório do corpus e a lista dos 3 arquivos que
      quebram, com o tipo da exceção
- [ ] `prompts/00-MESTRE.md` §10 corrigido nas duas linhas
- [ ] `PLANO.md`: cabeçalho da Fase 5 volta para **`REABERTA`** com os números honestos
      (`Structural 0/623, Numeric 0/623`), a nota de 2026-08-29 que fala em "bridge … sem bridge
      ~350" é substituída pela medição real, e os itens 05-12, 05-13..05-16 e 05-25 voltam a `[ ]`
      com a nota de que foram fechados contra um harness inválido
- [ ] Relatório em `prompts/reports/05-26.md`, com a tabela ANTES(falso) × DEPOIS(honesto) e a
      contagem de 489 bridges provada

## Armadilhas conhecidas

- **Não "conserte" nada de renderização aqui.** A tentação de emendar um bug enquanto o número está
  na tela é grande, e ela vai estragar a linha de base. Achou defeito? Seção "Achados fora de
  escopo" do relatório — as tarefas 05-27 em diante já estão escritas para recebê-los.
- **A normalização de id do comparador não muda.** Ela é correta e está provada; se você mexer, a
  linha de base deixa de ser comparável com a das tarefas seguintes.
- Os 3 arquivos que quebram (`color/color-001.mei`, `ftrem/ftrem-002.mei`, `symbol/symbol-002.mei`,
  todos `_TypeError: Null check operator used on a null value`) **não** entram em skip-list e
  **não** são consertados aqui: eles passam a aparecer como `falha` no relatório, que é o ponto.
  Dois deles estão dentro de diretórios com bridge e por isso eram contados como limpos.
- `dir/dir-011.mei` e `dir/dir-012.mei` continuam sendo a única skip-list legítima (§4.8).
- O `catch` que some é o que hoje esconde os crashes; espere o `dart test` ficar mais barulhento.

## Fora de escopo

- Qualquer correção em `lib/src/rendering/`, `lib/src/layout/` ou `lib/src/model/` (tarefas
  05-27..05-36).
- Substituir as 53 asserções de `contains('drawX')` por testes de comportamento (tarefa 05-33).
- Regerar goldens (`tool/golden.sh`).
