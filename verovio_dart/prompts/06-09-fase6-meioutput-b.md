# 06-09 — MEIOutput (B): estrutura, milestones e scoreDef

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Serializar a estrutura do documento: `mdiv`, `score`, `section`, `page`, `system`, `measure`,
`staff`, `layer`, os milestones de página e de sistema, e a família `scoreDef`/`staffGrp`/`staffDef`.

## Pré-condições

Tarefa **06-08** concluída.

```bash
cd verovio_dart
grep -c "_notYet(" lib/src/io/mei_output.dart   # > 0
dart test 2>&1 | tail -1     # verde, ≥ 650
```

## Referência C++

`origin/src/src/iomei.cpp`. Localize:

```bash
grep -n "MEIOutput::WriteMdiv\|WriteScore\|WriteSection\|WritePage\|WriteSystem\|WriteMeasure\|WriteStaff\|WriteLayer\|WriteScoreDef\|WriteStaffGrp\|WriteStaffDef\|WriteLayerDef\|WritePageElement\|WriteSystemElement\|WriteMilestone" origin/src/src/iomei.cpp
```

Contraparte de leitura em `lib/src/io/mei_input.dart` — leia a função de leitura de cada elemento
antes de escrever a de escrita; elas têm de ser simétricas.

O modo **page-based vs. score-based**: o C++ exporta em score-based por padrão, desfazendo o
cast-off. Encontre onde isso é decidido (`grep -n "IsPageBased\|m_scoreBasedMEI" origin/src/src/iomei.cpp`)
e reproduza.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/io/mei_output.dart`.
- **Alterar** `test/mei_output_test.dart`.

## Passo a passo

1. Leia as funções listadas.
2. Porte-as, na ordem em que aparecem no C++.
3. Trate o modo page-based/score-based como o C++.
4. Testes: para 10 arquivos de famílias diferentes do corpus, faça
   **round-trip**: carregar → serializar → carregar de novo → serializar, e afirmar que as duas
   serializações são **idênticas**. Depois compare a primeira com o MEI do C++:
   ```bash
   ./build/verovio -r verovio_dart/assets/data -t mei -o /tmp/cpp.mei <arquivo>
   ```
   Onde divergir, registre — muitas divergências só somem com as tarefas 06-10/06-11.
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 658 testes**
- [ ] O teste de round-trip passa para **10 arquivos**, com igualdade exata entre as duas serializações
- [ ] Para ao menos 3 arquivos simples (`note-001`, `measure-001`, `clef-001`), a estrutura
      (`mdiv`/`score`/`section`/`measure`/`staff`/`layer`) bate elemento a elemento com o MEI do C++;
      o relatório traz o diff
- [ ] Nenhum `_notYet` das funções desta tarefa restou
- [ ] Relatório em `prompts/reports/06-09.md`
- [ ] `PLANO.md`: checkbox "IOMEI — escrita (B)" marcado

## Armadilhas conhecidas

- **Milestones**: `Ending`, `Section`, `Expansion` viram pares início/fim no formato page-based.
  Na exportação score-based eles voltam a ser elementos aninhados. `lib/src/model/drawing_interfaces.dart`
  tem `convertToPageBasedMilestone` (`:47`, `:72`) — a saída faz o inverso.
- Se o documento passou por cast-off, exportar score-based exige desfazê-lo
  (`UnCastOffFunctor`, já portado em `lib/src/layout/cast_off.dart`). **Não** modifique o documento
  em memória para exportar: o C++ trabalha sobre uma cópia ou desfaz e refaz. Veja qual e siga.
- `scoreDef` tem valores herdados que foram materializados pelo `ScoreDefSetCurrentFunctor` na
  Fase 4. Exportar os valores materializados em vez dos originais infla o arquivo. Confira o que o
  C++ escreve.

## Fora de escopo

- Elementos de camada (06-10), de controle/texto/editorial (06-11).
