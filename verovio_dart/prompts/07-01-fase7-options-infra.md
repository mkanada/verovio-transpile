# 07-01 — options.cpp (A): tipos de opção, grupos e registro

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar a infraestrutura de opções do Verovio: as classes `Option*`, `OptionGrp`, o container
`Options` com registro e busca, e a serialização/desserialização em JSON. As 210 opções em si vêm
nas tarefas 07-02 a 07-05.

> Correção de escopo medida em 2026-08-26: o `PLANO.md` dizia "~100 opções". São **210**,
> registradas em 10 grupos.

## Pré-condições

Fase 6 concluída (tarefa **06-24**).

```bash
cd verovio_dart
dart test 2>&1 | tail -1     # verde, ≥ 900
wc -l lib/src/core/options_shell.dart   # ~566 hoje; é o esqueleto que esta tarefa substitui
```

## Referência C++

`origin/src/include/vrv/options.h` — declara:
`OptionGrp`, `Option`, `OptionBool`, `OptionDbl`, `OptionInt`, `OptionString`, `OptionArray`,
`OptionIntMap`, `OptionStaffrel`, `OptionJson`, e `Options`.

`origin/src/src/options.cpp` (2185 linhas) — leia:
- o construtor de `Options` (é ele que cria os grupos e registra tudo);
- `Options::GetItems`, `Options::GetGrps`, `Options::Register`;
- os métodos de cada `Option*`: `Init`, `SetValue`, `GetStrValue`, `GetDefaultStrValue`,
  `SetValueDbl`, `SetValueBool`, `SetValueArray`, `Reset`, `IsSet`.

Os 10 grupos e suas contagens (medidos com `Register()` por `SetLabel()`):

| Grupo | Opções |
|---|---:|
| Base short options | 0 (13 declaradas em `options.h`, registradas por outro caminho) |
| Input and page configuration options | 54 |
| General layout options | 82 |
| Loading selectors and processing | 14 |
| Element margins | 45 |
| Midi options | 3 |
| Mensural notation options | 6 |
| Neumatic notation options | 4 |
| Method JSON options for the command-line | 1 |
| Deprecated options | 1 |
| **Total** | **210** |

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/core/options.dart` — a infraestrutura completa.
- **Alterar** `lib/src/core/options_shell.dart` — passar a **delegar** para `options.dart`,
  mantendo a API que o resto de `lib/` já usa, ou ser substituído. **Decida e justifique no
  relatório**; o critério é não quebrar os ~15 arquivos que já o importam
  (`grep -rln "options_shell" lib/ test/ tool/`).
- **Criar** `test/options_test.dart`.

## Passo a passo

1. Leia `options.h` inteiro.
2. Leia os métodos das classes `Option*` em `options.cpp`.
3. Porte as 11 classes. `OptionIntMap` (um enum com nomes de string) e `OptionJson` são as menos
   óbvias — leia-as inteiras.
4. Porte `Options` com `Register`, `GetItems`, `GetGrps`, `Reset`.
5. **Não registre nenhuma opção ainda** além das que `options_shell.dart` já tinha
   (as `condense*` da 04h, as mensurais da 06-06, as de saída da 06-08, as MIDI da 06-17, as de
   transposição da 06-21). Migre-as para a infraestrutura nova, preservando nome e default.
6. Testes: para cada classe `Option*`, `SetValue` com valor válido, inválido e no limite;
   `GetStrValue`/`GetDefaultStrValue`; `Reset`; `IsSet`.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 925 testes**
- [ ] As 11 classes de `options.h` têm contraparte — prove com o diff de nomes
- [ ] Todas as opções que já existiam em `options_shell.dart` continuam funcionando com o **mesmo
      nome e o mesmo default** — prove listando-as no relatório, antes e depois
- [ ] Um teste por classe `Option*`, cobrindo valor inválido
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride** (nenhum default mudou)
- [ ] Relatório em `prompts/reports/07-01.md`
- [ ] `PLANO.md`: checkbox de infraestrutura de opções marcado

## Armadilhas conhecidas

- **Mudar um default muda o layout de todo o corpus.** Ao migrar as opções existentes, confira cada
  default contra `options.cpp` — se o esqueleto tinha um valor errado, corrija-o **e diga no
  relatório**, porque o SVG vai mudar.
- `OptionStaffrel` valida contra um conjunto de valores MEI (`above`, `below`, `within`…).
- `OptionIntMap` guarda a string e o int; a serialização usa a string.
- `Option::IsSet` distingue "explicitamente definido" de "no default" — o `MeiOutput` e o CLI
  dependem disso.
- `options_shell.dart` é importado por vários arquivos de `lib/`; quebrar a API dele quebra tudo.
  Migre com cuidado e rode `dart test` a cada passo.

## Fora de escopo

- Registrar as 210 opções (tarefas 07-02 a 07-05).
