# 07-04 — options.cpp (D): grupo "General layout", segunda metade (41 opções)

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar o grupo "General layout options": registrar as 41 opções restantes.

## Pré-condições

Tarefa **07-03** concluída.

```bash
cd verovio_dart
cat prompts/reports/07-03.md | grep -i "linha"    # onde a 07-03 parou
dart test 2>&1 | tail -1     # verde, ≥ 943
```

## Referência C++

`origin/src/src/options.cpp`, do ponto onde a tarefa 07-03 parou (registrado em
`prompts/reports/07-03.md`) até o `SetLabel` seguinte.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/core/options.dart`.
- **Alterar** `test/options_test.dart`.

## Passo a passo

Mesmo procedimento das tarefas 07-02 e 07-03.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 951 testes**
- [ ] O total de opções registradas é **136** (54 + 82)
- [ ] Um teste afirma que o grupo "General layout options" tem exatamente **82** opções
- [ ] Teste de paridade com `./build/verovio --help` para as 41 novas
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/07-04.md`
- [ ] `PLANO.md`: checkbox de "General layout (B)" marcado

## Armadilhas conhecidas

- Mesmas da 07-03: defaults são o risco.
- Se a soma não der 82, você pulou ou duplicou. Conte com
  `grep -c "this->Register" ` no bloco do C++.

## Fora de escopo

- Os outros grupos.
