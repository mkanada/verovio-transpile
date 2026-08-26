# 04h — ScoreDefOptimizeFunctor + ScoreDefSetOssiaFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os dois functors de `setscoredeffunctor.cpp` que faltam: a otimização do `scoreDef`
(esconder pentagramas vazios — a opção `condense`) e a marcação de pentagramas de ossia.

## Pré-condições

Tarefas **04a**–**04g** concluídas.

```bash
cd verovio_dart
ls lib/src/layout/calc_ledger_lines.dart
dart test 2>&1 | tail -1     # verde, ≥ 298
grep -n "ScoreDefOptimizeFunctor\|ScoreDefSetOssiaFunctor" lib/src/layout/setscoredef_functor.dart
# esperado: só a linha 15, um comentário dizendo que não estão portados
```

## Referência C++

| Arquivo | Conteúdo |
|---|---|
| `origin/src/include/vrv/setscoredeffunctor.h` | `class ScoreDefOptimizeFunctor`, `class ScoreDefSetOssiaFunctor`. |
| `origin/src/src/setscoredeffunctor.cpp` (928 linhas) | localize as duas classes com `grep -n "ScoreDefOptimizeFunctor::\|ScoreDefSetOssiaFunctor::" origin/src/src/setscoredeffunctor.cpp` |
| `origin/src/src/doc.cpp` | `Doc::ScoreDefOptimizeDoc` e `Doc::ScoreDefSetOssiaDoc` — quem os chama e com que pré-condições (`grep -n "ScoreDefOptimize\|ScoreDefSetOssia" origin/src/src/doc.cpp`) |
| `origin/src/include/vrv/options.h` | `OptionIntMap m_condense` e `OptionBool m_condenseFirstPage`, `m_condenseNotLastSystem`, `m_condenseTempoPages` — os valores que dirigem a otimização |

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/layout/setscoredef_functor.dart` — acrescentar as duas classes e **corrigir o
  comentário da linha 15**, que hoje diz que não estão portadas.
- **Alterar** `lib/src/model/doc.dart` — `scoreDefOptimizeDoc` / `scoreDefSetOssiaDoc`; atualizar os
  comentários de `:1254` (ossia) e `:1494` (condense).
- **Alterar** `lib/src/core/options_shell.dart` — acrescentar as opções `condense`,
  `condenseFirstPage`, `condenseNotLastSystem`, `condenseTempoPages` **com os defaults exatos do C++**
  (leia-os em `origin/src/src/options.cpp`, procurando por `m_condense`). Não porte o resto das
  opções: isso é a Fase 7.
- **Criar** `test/scoredef_optimize_test.dart`.

## Passo a passo

1. `grep -n "ScoreDefOptimizeFunctor::\|ScoreDefSetOssiaFunctor::" origin/src/src/setscoredeffunctor.cpp`
   para achar as faixas de linha; leia as duas classes inteiras.
2. Leia `Doc::ScoreDefOptimizeDoc` e `Doc::ScoreDefSetOssiaDoc` no `doc.cpp`.
3. Leia os defaults das 4 opções `condense*` em `origin/src/src/options.cpp`.
4. Acrescente as opções ao `options_shell.dart`, no mesmo estilo das que já estão lá
   (`Breaks`, `MensuralResp`) — o `condense` é um `OptionIntMap`, ou seja, um enum com nomes.
5. Porte as duas classes em `setscoredef_functor.dart`.
6. Ligue no `doc.dart`.
7. Testes: `test/corpus/ossia/` (4 arquivos) e um arquivo com pentagrama vazio para o condense
   (`grep -l 'mRest\|<staff n="2"' test/corpus/score/*.mei | head -3`).
8. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 302 testes**
- [ ] `grep -c "^class ScoreDefOptimizeFunctor\|^class ScoreDefSetOssiaFunctor" lib/src/layout/setscoredef_functor.dart` = 2
- [ ] `grep -c "ScoreDefOptimizeFunctor. and .ScoreDefSetOssiaFunctor. are" lib/src/layout/setscoredef_functor.dart` = 0
      (o comentário mentiroso da linha 15 sumiu)
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.`, timemaps **≥ 24/30**
- [ ] Relatório em `prompts/reports/04h.md`
- [ ] `PLANO.md`: `ScoreDefOptimize` e `ScoreDefSetOssia` removidos da lista de faltantes

## Armadilhas conhecidas

- O default do `condense` no C++ **não é** "sempre condensar". Leia o valor real em `options.cpp`;
  com o default errado, todo o corpus muda de layout e os 623 goldens ficam inalcançáveis.
- `ScoreDefOptimizeFunctor` marca `StaffDef` como invisível, não remove nada da árvore.
- Ossia depende do `AdjustOssiaStaffDefFunctor` da tarefa 04g já estar ligado.

## Fora de escopo

- Portar o resto das 210 opções (Fase 7, tarefas 07-01 a 07-06). Acrescente **só** as 4 `condense*`.
- `View::DrawOssia` (tarefa 05-10).
