# 06-01 — resetfunctor.cpp: completar os functors de reset

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Conferir os três functors de `resetfunctor.h` contra o C++ e completar o que falta. O reset é o que
permite relayout e reprocessamento — sem ele correto, a Fase 7 (`Toolkit.loadData` duas vezes,
mudança de opção) produz estado corrompido.

## Pré-condições

Fase 5 concluída (tarefa **05-25**).

```bash
cd verovio_dart
dart run tool/compare_svg.dart --all --mode=structural | head -3   # ≥ 590/623
dart test 2>&1 | tail -1                                            # verde
```

## Referência C++

`origin/src/include/vrv/resetfunctor.h` declara **3** classes:
`ResetDataFunctor`, `ResetHorizontalAlignmentFunctor`, `ResetVerticalAlignmentFunctor`.

`origin/src/src/resetfunctor.cpp` tem **907 linhas** — a maior parte é `ResetDataFunctor`, com um
`Visit*` por classe de elemento (dezenas).

Em Dart existem as três (`lib/src/layout/reset_functor.dart` tem `ResetDataFunctor`;
`ResetHorizontalAlignmentFunctor` e `ResetVerticalAlignmentFunctor` estão em outros arquivos —
confirme com `grep -rn "class ResetHorizontalAlignmentFunctor\|class ResetVerticalAlignmentFunctor" lib/src/`).

**A questão não é se as classes existem, é se cobrem todos os `Visit*`.** Meça:

```bash
grep -oP '^\s*FunctorCode ResetDataFunctor::Visit\K\w+' origin/src/src/resetfunctor.cpp | sort -u > /tmp/cpp_reset.txt
grep -oP '^\s*FunctorCode visit\K\w+' lib/src/layout/reset_functor.dart | sort -u > /tmp/dart_reset.txt
comm -23 /tmp/cpp_reset.txt <(sed 's/^./\U&/' /tmp/dart_reset.txt)
```

(ajuste os comandos ao estilo real dos arquivos; o ponto é produzir a lista do que falta)

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/layout/reset_functor.dart` e os arquivos dos outros dois functors.
- **Criar** `test/reset_functor_test.dart`.

## Passo a passo

1. Produza a lista de `Visit*` faltantes para cada um dos três functors. **Cole a lista no relatório.**
2. Porte cada `Visit*` faltante, lendo o corpo no C++.
3. Escreva um teste de **idempotência de ciclo**: carregar um arquivo, fazer layout, resetar, fazer
   layout de novo, e afirmar que o SVG produzido é **byte a byte idêntico** ao da primeira vez.
   Faça isso para 10 arquivos de famílias diferentes. Este teste é o valor real da tarefa.
4. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 590 testes**
- [ ] A lista de `Visit*` faltantes, colada no relatório, está vazia ao final
- [ ] O teste de idempotência de ciclo passa para **10 arquivos** e compara SVG por igualdade exata
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/06-01.md`
- [ ] `PLANO.md`: checkbox de `resetfunctor.cpp` marcado

## Armadilhas conhecidas

- O teste de idempotência é o que revela reset incompleto. Se ele falhar num arquivo, o campo que não
  foi resetado aparece como coordenada acumulada — procure por valores que dobram.
- `ResetDataFunctor` reseta estado de *dados* (ligações, tempos); `ResetHorizontalAlignment` e
  `ResetVerticalAlignment` resetam estado de *layout*. Não misture.
- Alguns `Visit*` no C++ chamam o `Visit` do pai explicitamente antes do próprio corpo. Em Dart os
  corpos padrão já delegam para cima (`00-MESTRE.md` §5a) — chamar de novo reseta duas vezes.

## Fora de escopo

- Qualquer outro functor.
