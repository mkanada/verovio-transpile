# 06-05 — ConvertToCmnFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `ConvertToCmnFunctor`: a conversão de notação mensural para notação moderna (CMN), com
divisão de notas longas em notas ligadas e criação de compassos.

## Pré-condições

Tarefa **06-04** concluída.

```bash
cd verovio_dart
ls lib/src/layout/convert_markup_analytical.dart
dart test 2>&1 | tail -1     # verde, ≥ 620
```

## Referência C++

`origin/src/include/vrv/convertfunctor.h` → `class ConvertToCmnFunctor`.
`origin/src/src/convertfunctor.cpp` → localize com
`grep -n "ConvertToCmnFunctor::" origin/src/src/convertfunctor.cpp`.

Quem o chama e sob que opção: `grep -rn "ConvertToCmn" origin/src/src/doc.cpp origin/src/src/toolkit.cpp`.

Depende de `ScoringUpFunctor`? Verifique (`grep -n "ScoringUp" origin/src/src/convertfunctor.cpp`).
Se depender, esta tarefa vem **depois** da 06-13 — nesse caso, **pare, registre a descoberta no
relatório e execute a 06-13 primeiro**. A ordem da série é uma hipótese, não uma verdade.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/convert_to_cmn.dart`.
- **Alterar** `lib/src/model/doc.dart`.
- **Alterar** `lib/src/core/options_shell.dart` — só a opção que dirige esta conversão.
- **Criar** `test/convert_to_cmn_test.dart`.

## Passo a passo

1. Leia a classe inteira.
2. Confirme a dependência de `ScoringUpFunctor` (passo acima).
3. Porte o functor.
4. Ligue no `doc.dart`.
5. Testes: `test/corpus/mensural/` (25 arquivos). Compare o resultado com o do C++:
   ```bash
   ./build/verovio -r verovio_dart/assets/data -t mei -o /tmp/cpp.mei <arquivo mensural>
   ```
   (descubra a flag da opção com `./build/verovio --help | grep -i cmn`)
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 628 testes**
- [ ] `grep -c "class ConvertToCmnFunctor" lib/src/layout/convert_to_cmn.dart` = 1
- [ ] Para ao menos 5 arquivos de `test/corpus/mensural/`, o número de `measure`, `note` e `tie`
      produzidos bate com o do MEI convertido pelo C++; a tabela vai no relatório
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/06-05.md`
- [ ] `PLANO.md`: checkbox de `ConvertToCmn` marcado

## Armadilhas conhecidas

- A divisão de uma nota longa em notas ligadas depende do sinal de mensuração vigente
  (`Mensur`, com `@prolatio`, `@tempus`, `@modusminor`, `@modusmaior`). O modelo já tem
  `lib/src/model/mensur.dart` — use-o.
- Imperfeição e alteração (regras mensurais em que uma nota vale 2/3 ou 2× do nominal) são tratadas
  antes desta conversão, no `ScoringUpFunctor`. Se os valores saírem errados, o bug é lá.
- A conversão **cria** objetos novos na árvore. Todos precisam de `@xml:id` gerados como no C++.
- Não confunda com `ConvertToCastOffMensuralFunctor`, que **já existe** em Dart
  (`lib/src/layout/cast_off_mensural.dart`) e faz outra coisa.

## Fora de escopo

- `ConvertToMensuralViewFunctor` (tarefa 06-06).
