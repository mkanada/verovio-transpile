# 07-03 — options.cpp (C): grupo "General layout", primeira metade (41 opções)

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Registrar a primeira metade das 82 opções do grupo "General layout options" e ligá-las aos seus
consumidores.

## Pré-condições

Tarefa **07-02** concluída.

```bash
cd verovio_dart
dart test 2>&1 | tail -1     # verde, ≥ 935
```

## Referência C++

`origin/src/src/options.cpp`, bloco `SetLabel("General layout options", ...)`:

```bash
grep -n 'SetLabel("General layout options"' origin/src/src/options.cpp
```

São **82** `Register(...)` até o próximo `SetLabel`. **Esta tarefa porta as primeiras 41**, na ordem
do arquivo. A tarefa 07-04 porta as 41 restantes.

Registre no relatório **a linha exata onde você parou** — é o contrato com a 07-04.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/core/options.dart`.
- **Alterar** `test/options_test.dart`.

## Passo a passo

Mesmo procedimento da tarefa 07-02: registrar com nome/descrição/default/min/max idênticos, achar o
consumidor de cada uma, marcar as sem consumidor, escrever o teste de tabela e o de paridade com o
`--help` do C++.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 943 testes**
- [ ] 41 opções novas registradas; o total de opções em `options.dart` é **95** (54 + 41)
- [ ] Teste de tabela cobrindo as 41
- [ ] Teste de paridade com `./build/verovio --help` para as 41
- [ ] O relatório diz **em que linha de `options.cpp`** a tarefa parou
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/07-03.md`
- [ ] `PLANO.md`: checkbox de "General layout (A)" marcado

## Armadilhas conhecidas

- Este grupo tem as opções que mais mudam o layout: `breaks`, `spacingStaff`, `spacingSystem`,
  `justifyVertically`, `evenNoteSpacing`, `condense`. **Algumas já foram parcialmente portadas** em
  tarefas anteriores (`condense*` na 04h, `breaks` no `options_shell.dart` original). Não as
  duplique — migre e confira o default.
- Se `compare_svg` regredir, foi um default. Bisseccione: registre metade, teste, registre a outra.

## Fora de escopo

- As 41 restantes do grupo (tarefa 07-04).
