# 06-13 — scoringupfunctor.cpp

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `ScoringUpFunctor`: a aplicação das regras mensurais de imperfeição, alteração e ponto de
divisão, que convertem os valores nominais das notas mensurais nas durações reais.

## Pré-condições

Tarefa **06-12** concluída.

```bash
cd verovio_dart
ls lib/src/editing/edit_functors.dart
dart test 2>&1 | tail -1     # verde, ≥ 710
```

## Referência C++

`origin/src/include/vrv/scoringupfunctor.h` → `class ScoringUpFunctor`.
`origin/src/src/scoringupfunctor.cpp` (734 linhas).

Quem o chama: `grep -rn "ScoringUp" origin/src/src/doc.cpp origin/src/src/toolkit.cpp`.

O modelo mensural em Dart: `lib/src/model/mensur.dart` (`Mensur` com `@prolatio`, `@tempus`,
`@modusminor`, `@modusmaior`), `lib/src/core/fraction.dart`.

**Se a tarefa 06-05 (`ConvertToCmnFunctor`) descobriu que dependia desta**, ela deve ter parado e
mandado executar esta primeiro. Se você está aqui depois da 06-05, confira no relatório de 06-05
o que ficou pendente.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/scoring_up.dart`.
- **Alterar** `lib/src/model/doc.dart`.
- **Criar** `test/scoring_up_test.dart`.

## Passo a passo

1. Leia as 734 linhas. É denso: as regras mensurais têm muitos casos.
2. Porte o functor.
3. Ligue no `doc.dart`, na posição do C++.
4. Testes: `test/corpus/mensural/` (25 arquivos) e `test/corpus/mensur/` (8).
   O melhor oráculo é o **timemap** do C++, que reflete as durações reais:
   ```bash
   ./build/verovio -r verovio_dart/assets/data -t timemap -o /tmp/cpp.json <arquivo mensural>
   ```
   Compare os onsets com os do Dart, como `tool/validate_layout.dart` já faz para CMN.
5. **Amplie `tool/validate_layout.dart`** para deixar de marcar os arquivos mensurais como `skipped`
   na coluna de timemap, agora que as durações reais existem.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 720 testes**
- [ ] `grep -c "class ScoringUpFunctor" lib/src/layout/scoring_up.dart` = 1
- [ ] `dart run tool/validate_layout.dart` deixa de reportar `skipped` para os arquivos mensurais e
      reporta `match` ou `differ` para eles; o relatório traz quantos batem de quantos
- [ ] **≥ 15 dos 25** arquivos de `test/corpus/mensural/` têm timemap `match` com o C++
- [ ] Relatório em `prompts/reports/06-13.md`
- [ ] `PLANO.md`: checkbox de `scoringupfunctor.cpp` marcado

## Armadilhas conhecidas

- **Imperfeição** (nota vale 2/3 do nominal) e **alteração** (nota vale 2× o nominal) dependem do
  contexto: o que vem antes e depois, e o nível de mensuração. Não há atalho; siga o C++ caso a caso.
- O **ponto de divisão** (`punctus divisionis`) vs. o **ponto de aumento** (`punctus additionis`):
  o mesmo `<dot>` no MEI significa coisas diferentes conforme a posição.
- Use `Fraction` (`lib/src/core/fraction.dart`) em toda a aritmética. Converter para `double` no meio
  perde a exatidão e o timemap diverge por arredondamento.
- Se o timemap mensural continuar divergindo, compare **nota a nota** com o do C++ e ache a primeira
  que difere; o erro costuma ser numa regra específica, não em todas.

## Fora de escopo

- MIDI (tarefas 06-14 a 06-17).
