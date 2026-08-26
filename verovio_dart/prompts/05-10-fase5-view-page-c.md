# 05-10 — view_page.cpp (C): compasso, barras de compasso, número de compasso e ossia

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Desenhar o compasso e tudo o que o delimita: as barras de compasso em todas as suas formas, os
pontos de repetição, o número de compasso, os grupos de fórmula de compasso e o pentagrama de ossia.

## Pré-condições

Tarefa **05-09** concluída.

```bash
cd verovio_dart
grep -c "_notYet('DrawMeasure'" lib/src/rendering/view_page.dart   # 1
dart test 2>&1 | tail -1                                            # verde, ≥ 414
```

## Referência C++

`origin/src/src/view_page.cpp`, faixas:

| Linha | Função |
|---:|---|
| 678 | `DrawBarLines` |
| 815 | `DrawBarLine` |
| 946 | `DrawBarLineDots` |
| 993 | `DrawMeasure` |
| 1071 | `DrawMeterSigGrp` |
| 1117 | `DrawMNum` |
| 1183 | `DrawOssia` |

Mais `origin/src/src/view_element.cpp:434` (`View::DrawBarLine`, a sobrecarga para o `BarLine`
como elemento de camada — **é outra função com o mesmo nome**; porte as duas e não as confunda).

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/view_page.dart`.
- **Alterar** `test/view_page_test.dart`.

## Passo a passo

1. Leia as faixas.
2. `DrawBarLines` (678-814) decide **quais** barras desenhar por grupo de pentagramas; `DrawBarLine`
   (815-945) desenha **uma**, tratando todas as formas de `@form`
   (`single`, `dbl`, `rptstart`, `rptend`, `rptboth`, `end`, `invis`, `dashed`, `dotted`, `heavy`…).
   Leia a tabela de formas inteira.
3. `DrawBarLineDots` (946-992) põe os pontos de repetição.
4. `DrawMNum` (1117-1182) posiciona o número de compasso conforme as opções.
5. `DrawOssia` (1183-1262) desenha o pentagrama de ossia — depende do `AdjustOssiaStaffDefFunctor`
   da tarefa 04g.
6. Testes: `test/corpus/barline/` (10 arquivos) cobre as formas; `test/corpus/mnum/` (1),
   `test/corpus/ossia/` (4), `test/corpus/measure/` (1), `test/corpus/repeats/` (8).
   Compare estruturalmente com os goldens.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 424 testes**
- [ ] Nenhum `_notYet` das funções desta tarefa restou
- [ ] Um teste cobre **cada** forma de `@form` de barra de compasso presente em
      `test/corpus/barline/` (liste-as com
      `grep -oh 'form="[^"]*"' test/corpus/barline/*.mei | sort -u`)
- [ ] `dart run tool/compare_svg.dart test/corpus/barline` reporta o número de limpos, e ele é
      **maior que 0**
- [ ] Relatório em `prompts/reports/05-10.md`
- [ ] `PLANO.md`: checkbox de `view_page.cpp` (C) marcado

## Armadilhas conhecidas

- **Duas funções `View::DrawBarLine`**: `view_page.cpp:815` (a barra de compasso entre compassos) e
  `view_element.cpp:434` (o `<barLine>` dentro de uma camada). Assinaturas diferentes, propósitos
  diferentes. Porte as duas.
- As barras que atravessam vários pentagramas (`@bar.thru`) são desenhadas uma vez pelo grupo, não
  uma por pentagrama. `DrawBarLines` é quem sabe disso.
- `DrawMNum` respeita opções de posicionamento que ainda não existem no `options_shell.dart`.
  Use o default do C++ e **não** porte o resto das opções — isso é a Fase 7.
- Repetições (`rptstart`/`rptend`) combinam glifo + linhas + pontos; a ordem de emissão no SVG importa
  para a comparação estrutural.

## Fora de escopo

- `DrawStaff`, `DrawStaffLines`, `DrawLedgerLines` (tarefa 05-11).
