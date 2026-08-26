# 06-06 — ConvertToMensuralViewFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `ConvertToMensuralViewFunctor`, a conversão para a vista mensural responsiva, e ligar a opção
`mensuralResp` que hoje é um esqueleto em `lib/src/core/options_shell.dart:333`.

## Pré-condições

Tarefa **06-05** concluída.

```bash
cd verovio_dart
ls lib/src/layout/convert_to_cmn.dart
sed -n '330,340p' lib/src/core/options_shell.dart   # o comentário dizendo que não está portado
dart test 2>&1 | tail -1     # verde, ≥ 628
```

## Referência C++

`origin/src/include/vrv/convertfunctor.h` → `class ConvertToMensuralViewFunctor`.
`origin/src/src/convertfunctor.cpp` → `grep -n "ConvertToMensuralViewFunctor::" origin/src/src/convertfunctor.cpp`.

A opção: `OptionIntMap m_mensuralResp` em `origin/src/include/vrv/options.h`, registrada em
`origin/src/src/options.cpp` no grupo "Mensural notation options" (6 opções no total).
O enum `MensuralResp { none, auto, selection }` **já existe** em `options_shell.dart:16`.

`options_shell.dart:333` tem o comentário
`/// (ConvertToMensuralViewDoc) is not ported and behaves like 'auto'.` — esta tarefa o apaga.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/convert_to_mensural_view.dart`.
- **Alterar** `lib/src/model/doc.dart` — `convertToMensuralViewDoc`.
- **Alterar** `lib/src/core/options_shell.dart` — remover o comentário mentiroso e acrescentar as
  **6** opções do grupo mensural do C++ (leia-as em `options.cpp`).
- **Criar** `test/convert_to_mensural_view_test.dart`.

## Passo a passo

1. Leia a classe inteira e `Doc::ConvertToMensuralViewDoc` no C++.
2. Leia as 6 opções do grupo "Mensural notation options" em `origin/src/src/options.cpp`, com os
   defaults exatos.
3. Porte o functor e o método do `Doc`.
4. Acrescente as 6 opções ao `options_shell.dart`, e **apague o comentário da linha 333**.
5. Testes: `test/corpus/mensural/` (25) e `test/corpus/ligature/` (50), com os três valores de
   `mensuralResp`.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 636 testes**
- [ ] `grep -c "is not ported and behaves like" lib/src/core/options_shell.dart` = 0
- [ ] As 6 opções do grupo mensural existem em `options_shell.dart` com os defaults do C++;
      o relatório lista nome e default de cada uma, ao lado do valor lido de `options.cpp`
- [ ] Um teste cobre cada valor de `MensuralResp`
- [ ] `dart run tool/compare_svg.dart test/corpus/mensural --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/06-06.md`
- [ ] `PLANO.md`: checkbox de `ConvertToMensuralView` marcado

## Armadilhas conhecidas

- `mensuralResp = selection` depende do suporte a seleção, que é a tarefa 06-12. Se este functor
  precisar dele, porte o caminho `none`/`auto` agora e deixe `selection` marcado com um
  `TODO(06-12)` explícito — e diga isso no relatório.
- Mudar o default de qualquer opção mensural muda o layout de 75 arquivos do corpus
  (`mensural` 25 + `ligature` 50). Confira os defaults duas vezes.
- Este grupo tem só 6 opções; **não** porte o resto das 210 aqui (Fase 7).

## Fora de escopo

- As outras 204 opções.
