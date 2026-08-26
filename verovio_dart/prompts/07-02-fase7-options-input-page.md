# 07-02 — options.cpp (B): grupo "Input and page configuration" (54 opções)

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Registrar as 54 opções do grupo "Input and page configuration options" e ligar cada uma ao código que
a consome.

## Pré-condições

Tarefa **07-01** concluída.

```bash
cd verovio_dart
ls lib/src/core/options.dart
dart test 2>&1 | tail -1     # verde, ≥ 925
```

## Referência C++

`origin/src/src/options.cpp`, o bloco que começa em
`m_general.SetLabel("Input and page configuration options", ...)`. Localize:

```bash
grep -n 'SetLabel("Input and page configuration options"' origin/src/src/options.cpp
```

e leia dali até o próximo `SetLabel`. São **54** chamadas de `this->Register(...)`.

Para cada opção, o C++ dá: nome curto, nome longo, descrição, valor default, e (para numéricas)
mínimo e máximo. **Porte os cinco.** As descrições vão para o `--help`, que a tarefa 07-06 usa.

Também `origin/src/include/vrv/options.h`, bloco `OptionGrp m_general;` — a declaração dos campos.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/core/options.dart`.
- **Alterar** `test/options_test.dart`.

## Passo a passo

1. Leia as 54 registrações no `options.cpp`.
2. Registre-as em `options.dart`, na **mesma ordem**, com nome, descrição, default, mínimo e máximo
   idênticos.
3. Para cada opção, **encontre quem a consome** no Dart:
   ```bash
   grep -rn "<nomeDaOpcao>" lib/src/
   ```
   Se ninguém consome porque a funcionalidade não foi portada, marque com
   `// TODO(consumidor): <onde deveria ser usada, com arquivo C++ e linha>` e **liste no relatório**.
   Se alguém consome um valor hard-coded, troque pelo valor da opção.
4. Testes: para **cada uma** das 54, um teste que afirma nome, default, mínimo e máximo.
   Escreva-o como uma tabela dirigida por dados, não 54 funções.
5. **Teste de paridade com o C++:** compare a lista de opções do Dart com a de
   `./build/verovio --help` (ou `--?` — confira a flag). Todas as 54 têm de aparecer com o mesmo
   nome e o mesmo default.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 935 testes**
- [ ] As 54 opções estão registradas; `options.dart` as conta e o teste afirma o número
- [ ] O teste de tabela cobre nome, default, mínimo e máximo das 54
- [ ] O teste de paridade com `./build/verovio --help` passa para as 54
- [ ] O relatório lista quais opções ainda não têm consumidor em Dart e por quê
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/07-02.md`
- [ ] `PLANO.md`: checkbox do grupo "Input and page configuration" marcado

## Armadilhas conhecidas

- **Defaults.** É a única coisa que pode quebrar o corpus inteiro nesta tarefa. Confira um a um.
- Opções deste grupo controlam tamanho de página, margens e escala — se o SVG mudar de dimensão
  depois desta tarefa, é um default errado.
- Algumas opções são só de linha de comando (`m_help`, `m_version`, `m_outfile`); elas têm um flag
  no C++. Preserve-o.
- Não invente opções que o C++ não tem.

## Fora de escopo

- Os outros 9 grupos.
