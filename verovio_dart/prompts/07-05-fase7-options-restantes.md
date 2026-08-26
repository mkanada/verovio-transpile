# 07-05 — options.cpp (E): selectors, margens e os grupos pequenos (74 opções)

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar as 210 opções: registrar os grupos "Loading selectors and processing" (14), "Element margins"
(45), "Midi" (3), "Mensural" (6), "Neumatic" (4), "Method JSON" (1) e "Deprecated" (1).

## Pré-condições

Tarefa **07-04** concluída.

```bash
cd verovio_dart
dart test 2>&1 | tail -1     # verde, ≥ 951
```

## Referência C++

`origin/src/src/options.cpp`, os blocos:

| `SetLabel` | Opções |
|---|---:|
| `"Loading selectors and processing"` | 14 |
| `"Element margins"` | 45 |
| `"Midi options"` | 3 |
| `"Mensural notation options"` | 6 |
| `"Neumatic notation options"` | 4 |
| `"Method JSON options for the command-line"` | 1 |
| `"Deprecated options"` | 1 |

Algumas já foram portadas em tarefas anteriores: as mensurais na 06-06, as MIDI na 06-17, as de
transposição (grupo selectors) na 06-21. **Migre-as, não as duplique**, e confira os defaults.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/core/options.dart`.
- **Alterar** `test/options_test.dart`.

## Passo a passo

Mesmo procedimento das tarefas 07-02 a 07-04, grupo a grupo.

O grupo "Element margins" (45 opções) é o mais mecânico: são margens por tipo de elemento
(`leftMarginAccid`, `rightMarginNote`…). **Verifique se o layout da Fase 4 já as consome** — o
`AdjustXPosFunctor` usa margens; se estiverem hard-coded lá, troque pelas opções.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 965 testes**
- [ ] O total de opções registradas é **210**; um teste afirma esse número e a contagem por grupo,
      batendo com a tabela acima
- [ ] Teste de paridade com `./build/verovio --help` para **todas as 210**
- [ ] Nenhuma opção duplicada (o registro rejeita nome repetido, e há um teste que prova)
- [ ] O relatório lista as opções que ainda não têm consumidor em Dart
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/07-05.md`
- [ ] `PLANO.md`: checkbox "options.cpp" inteiro marcado

## Armadilhas conhecidas

- As margens de elemento afetam o espaçamento horizontal de **todo** o corpus. Se elas estavam
  hard-coded na Fase 4 com o valor certo, trocar pela opção não muda nada — e isso é o resultado
  esperado. Se mudar, um valor estava errado; ache qual.
- Opções `Deprecated` existem para dar aviso, não para funcionar. Porte o aviso.
- `Method JSON options` é uma opção `OptionJson` — a classe menos óbvia da 07-01.

## Fora de escopo

- `toolkit.cpp` (tarefas 07-06 a 07-08).
