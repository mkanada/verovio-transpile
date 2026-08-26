# 05-20 — view_control.cpp (A): framework de spanning, ligaduras de valor e extensores

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar a infraestrutura de elementos de controle e toda a família dos que se estendem no tempo:
ligadura de valor, bracketSpan, oitava, linha de pedal, extensor de trinado e os conectores.

## Pré-condições

Tarefa **05-19** concluída.

```bash
cd verovio_dart
ls lib/src/rendering/view_text.dart
dart test 2>&1 | tail -1     # verde, ≥ 512
```

## Referência C++

`origin/src/src/view_control.cpp` (3306 linhas), faixas desta tarefa:

| Linha | Função |
|---:|---|
| 72 | `DrawControlElement` (o despachante — porte-o inteiro com `_notYet` para o resto) |
| 183 | `DrawTimeSpanningElement` |
| 435 | `HasValidTimeSpanningOrder` |
| 564 | `DrawBracketSpan` |
| 815 | `DrawOctave` |
| 1067 | `DrawTie` |
| 1110 | `DrawPedalLine` |
| 1189 | `DrawTrillExtension` |
| 1240 | `DrawControlElementConnector` |
| 1336 | `DrawFConnector` |
| 1394 | `DrawSylConnector` |
| 1468 | `DrawSylConnectorLines` |

A linha 190 faz `vrv_cast<BBoxDeviceContext *>(dc)` — caminho especial para o cálculo de caixa.
Reproduza-o.

Os casos de `DrawControlElement` que não são desta tarefa viram `_notYet('DrawXxx', '05-21')` ou
`'05-22'`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view_control.dart` (`part of` `view.dart`).
- **Alterar** `lib/src/rendering/view.dart`.
- **Criar** `test/view_control_test.dart`.

## Passo a passo

1. Leia `DrawControlElement` (72-182) e `DrawTimeSpanningElement` (183-434) inteiros. O segundo é a
   máquina que resolve início/fim de um elemento que pode cruzar sistemas, e é usado por todos os
   `Draw*` desta tarefa.
2. Monte o despachante completo com `_notYet` para o que fica nas 05-21/05-22.
3. Porte `HasValidTimeSpanningOrder`.
4. Porte `DrawTie`, `DrawBracketSpan`, `DrawOctave`, `DrawPedalLine`, `DrawTrillExtension`.
5. Porte os conectores: `DrawControlElementConnector`, `DrawFConnector`, `DrawSylConnector`,
   `DrawSylConnectorLines` (os hífens e extensores da letra que `DrawSyl` registrou na tarefa 05-16).
6. Testes: `test/corpus/tie/` (12), `test/corpus/bracketspan/` (6), `test/corpus/octave/` (4),
   `test/corpus/pedal/` (6), `test/corpus/trill/` (8), `test/corpus/lyric/` (16, conectores).
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 524 testes**
- [ ] `dart run tool/compare_svg.dart test/corpus/tie --mode=structural` reporta **≥ 8 de 12** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/octave --mode=structural` reporta **≥ 3 de 4** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` maior que na tarefa 05-19
- [ ] Todo caso de `DrawControlElement` fora do escopo tem `_notYet` nomeando 05-21 ou 05-22
- [ ] Relatório em `prompts/reports/05-20.md`
- [ ] `PLANO.md`: checkbox de `view_control.cpp` (A) marcado

## Armadilhas conhecidas

- **Elementos que cruzam sistemas** são desenhados em pedaços, um por sistema, com a pilha de
  offsets do `View` (tarefa 05-06). `DrawTimeSpanningElement` decide os pedaços; errar aqui erra
  tudo o que depende dele.
- `DrawTie` é curta (1067-1109) porque a geometria vem de `Slur`/`Tie` da Fase 4 — mesma observação
  da tarefa 05-18.
- `DrawSylConnector`/`DrawSylConnectorLines`: hífen entre sílabas vs. linha extensora depois da
  última. São regras diferentes; leia as duas.
- `HasValidTimeSpanningOrder` protege contra `@startid`/`@endid` invertidos; sem ela, arquivos
  malformados do corpus explodem.
- O caminho `BBoxDeviceContext` da linha 190 evita desenhar o mesmo elemento duas vezes no cálculo
  de caixa. Sem ele, as caixas ficam grandes demais.

## Fora de escopo

- Tudo que virou `_notYet`.
