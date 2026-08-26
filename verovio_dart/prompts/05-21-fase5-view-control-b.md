# 05-21 — view_control.cpp (B): dinâmicas, andamento, cifras, ensaio e baixo cifrado

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os elementos de controle baseados em texto: reguladores de dinâmica, dinâmicas, indicações de
andamento, cifras, marcas de ensaio, baixo cifrado, e a moldura de texto que os envolve.

## Pré-condições

Tarefa **05-20** concluída.

```bash
cd verovio_dart
grep -c "_notYet('DrawHairpin'" lib/src/rendering/view_control.dart   # 1
dart test 2>&1 | tail -1     # verde, ≥ 524
```

## Referência C++

`origin/src/src/view_control.cpp`, faixas:

| Linha | Função |
|---:|---|
| 651 | `DrawHairpin` |
| 1745 | `DrawControlElementText` |
| 1829 | `DrawDynam` |
| 1910 | `DrawDynamSymbolOnly` |
| 1960 | `DrawFb` |
| 2288 | `DrawHarm` |
| 2583 | `DrawReh` |
| 2734 | `DrawTempo` |
| 3265 | `DrawTextEnclosure` |

A linha 3055 faz `vrv_cast<BBoxDeviceContext *>(dc)` — está dentro de `DrawEnding`, que é da
tarefa 05-22; não se confunda.

`Dir` não tem `DrawDir` próprio: é desenhado por `DrawControlElementText`. Confirme lendo
`DrawControlElement` (72-182).

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/view_control.dart`.
- **Alterar** `test/view_control_test.dart`.

## Passo a passo

1. Leia as faixas.
2. Porte `DrawControlElementText` (1745-1828) primeiro — é a base de `dir`, `tempo`, `harm`, `reh`.
3. Porte `DrawTextEnclosure` (3265-3306), a moldura (caixa/círculo) opcional.
4. Porte `DrawHairpin` (651-814): crescendo/diminuendo, com as variantes de forma e a interação com
   dinâmicas vizinhas que o `PrepareFloatingGrpsFunctor` já agrupou na Fase 4.
5. Porte `DrawDynam`, `DrawDynamSymbolOnly`, `DrawTempo`, `DrawHarm`, `DrawReh`, `DrawFb`.
6. Testes: `test/corpus/hairpin/` (6), `test/corpus/dynam/` (10), `test/corpus/tempo/` (4),
   `test/corpus/harm/` (5), `test/corpus/reh/` (1), `test/corpus/figured-bass/` (5),
   `test/corpus/dir/` (12, menos os 2 não-UTF-8).
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 536 testes**
- [ ] `dart run tool/compare_svg.dart test/corpus/hairpin --mode=structural` reporta **≥ 4 de 6** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/dynam --mode=structural` reporta **≥ 8 de 10** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` maior que na tarefa 05-20
- [ ] Nenhum `_notYet` das funções desta tarefa restou
- [ ] Relatório em `prompts/reports/05-21.md`
- [ ] `PLANO.md`: checkbox de `view_control.cpp` (B) marcado

## Armadilhas conhecidas

- `DrawDynamSymbolOnly` é o caminho rápido quando a dinâmica é só `p`/`f`/`mf`: emite glifos SMuFL
  em vez de texto. O critério de escolha está em `DrawDynam`; se você sempre usar um dos dois, metade
  do corpus diverge.
- Um regulador que termina numa dinâmica é encurtado para não colidir. O agrupamento veio de
  `PrepareFloatingGrpsFunctor` (Fase 4); aqui é só desenho — mas a **leitura** do grupo tem de estar certa.
- `DrawFb` desenha o baixo cifrado empilhado; a ordem vertical dos `<f>` importa.
- `DrawReh` usa `DrawTextEnclosure` por padrão (caixa em volta da marca de ensaio).
- `dir` não tem função própria. Não invente `DrawDir`.

## Fora de escopo

- Ornamentos e símbolos isolados (tarefa 05-22).
