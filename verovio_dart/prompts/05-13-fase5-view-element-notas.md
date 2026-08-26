# 05-13 — view_element.cpp (A): despacho, notas, acordes, hastes e bandeirolas

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar o despachante de elementos de camada e a família da nota: nota, acorde, cluster, haste,
bandeirola, pontos de aumento, modificadores de haste e a barra da apojatura.

## Pré-condições

Tarefa **05-12** concluída.

```bash
cd verovio_dart
ls lib/src/rendering/headless_extents.dart 2>&1 | grep -q "No such\|inexistente" && echo "OK: deletado"
grep -rn "Approximation:" lib/src/ | wc -l    # 0
dart test 2>&1 | tail -1                       # verde
```

## Referência C++

`origin/src/src/view_element.cpp` (2212 linhas), faixas:

| Linha | Função |
|---:|---|
| 65 | `DrawLayerElement` (o despachante — porte-o inteiro, com todos os casos, mesmo os que ainda são stub) |
| 581 | `DrawChord` |
| 606 | `DrawChordCluster` |
| 856 | `DrawDots` |
| 886 | `DrawDurationElement` |
| 911 | `DrawFlag` |
| 1473 | `DrawNote` |
| 1689 | `DrawStem` |
| 1744 | `DrawStemMod` |
| 1981 | `DrawAcciaccaturaSlash` |
| 2030 | `DrawDotsPart` |
| 2114 | `DrawMRptPart` |

Os casos de `DrawLayerElement` que **não** são desta tarefa viram `_notYet('DrawXxx', '05-1N')`,
nomeando a tarefa: 05-14 (accid/artic/keySig/meterSig), 05-15 (rests/space/dot/custos/clef),
05-16 (rpt/trem/graceGrp/syl/verse/generic), 05-17 (beam), 05-18 (tuplet/slur),
05-23 (mensural), 05-24 (neume/tab).

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view_element.dart` (`part of` `view.dart`).
- **Alterar** `lib/src/rendering/view.dart` para declarar a `part`.
- **Criar** `test/view_element_test.dart`.

## Passo a passo

1. Leia `DrawLayerElement` (65-241) inteiro e monte o despachante completo, com stubs `_notYet`
   para o que não é desta tarefa.
2. Porte `DrawDurationElement`, `DrawNote`, `DrawChord`, `DrawChordCluster`.
3. Porte `DrawStem`, `DrawFlag`, `DrawStemMod`, `DrawAcciaccaturaSlash`.
4. Porte `DrawDots` e `DrawDotsPart`.
5. Porte `DrawMRptPart` (usada por 05-16, mas mora perto de `DrawDotsPart`).
6. Testes: `test/corpus/note/` (12 arquivos), `test/corpus/chord/` (10),
   `test/corpus/stem/` (16), `test/corpus/dot/` (6), `test/corpus/unison/` (7).
   Compare com os goldens em modo **estrutural** e, para ao menos 3 arquivos, também em modo
   **numérico com epsilon 0**, e registre quantos passam.
7. Rode `dart run tool/compare_svg.dart --all` e registre.
8. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 445 testes**
- [ ] `dart run tool/compare_svg.dart test/corpus/note --mode=structural` reporta **≥ 6 de 12**
      arquivos limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` reporta um número **estritamente
      maior** que o da tarefa 05-11, e o relatório traz os dois números
- [ ] Todo caso de `DrawLayerElement` que não é desta tarefa tem `_notYet` nomeando a tarefa certa
- [ ] Relatório em `prompts/reports/05-13.md`
- [ ] `PLANO.md`: checkbox de `view_element.cpp` (A) marcado

## Armadilhas conhecidas

- `DrawNote` trata cabeça de nota, cue size, cor, `@head.shape`, `@head.mod`, notas em ossia e
  cross-staff. É longa (1473-1582) e cada `if` importa.
- **A direção da haste** já foi decidida pelo `CalcStemFunctor` na Fase 4; `DrawStem` só desenha.
  Se a haste sair para o lado errado, o bug é da Fase 4.
- `DrawFlag` usa glifos SMuFL diferentes por duração e por direção; a tabela está no C++.
- `DrawDots`/`DrawDotsPart`: `Dots` é um objeto de desenho criado pelo `CalcDotsFunctor`. Ele existe
  em Dart (`lib/src/model/layer_elements_gen.dart`) — não o recrie.
- `DrawChordCluster` é o desenho de cluster (`@cluster`), raro; não confunda com `DrawChord`.
- Cor: `@color` no MEI vira `m_currentColor` no `View`. Empilhe e desempilhe como o C++.

## Fora de escopo

- Todo caso marcado `_notYet`.
