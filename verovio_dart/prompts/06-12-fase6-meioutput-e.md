# 06-12 — MEIOutput (E): estrutura do documento — mdiv até scoreDef

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Regra de números: critérios medem contra o estado corrente — nunca contra contagem fixa.

## Objetivo

Portar os `Write*` da estrutura do documento: `WriteMdiv, WritePages, WriteScore, WritePage,
WritePageElement, WritePageMilestoneEnd, WriteSystem, WriteSystemElement,
WriteSystemMilestoneEnd, WriteSection, WriteEnding, WriteExpansion, WritePb, WriteSb,
WriteScoreDefElement, WriteScoreDef`.

## Pré-condições

Tarefa **06-11** concluída.

```bash
cd verovio_dart
dart test test/mei_output_test.dart 2>&1 | tail -1
```

## Referência C++

`origin/src/src/iomei.cpp:1657-1835` — os 16 `Write*` nominais acima (confira com
`grep -n "MEIOutput::Write" origin/src/src/iomei.cpp | sed -n '…'` e cole a lista no relatório).

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/io/mei_output.dart`.
- **Alterar** `test/mei_output_test.dart`.

## Passo a passo

1. Porte os 16, na ordem do arquivo, citando linha.
2. Teste: exportar `note-001.mei` (page-based) e `test/corpus/score/score-006.mei` — comparar a espinha dorsal (`<mdiv>`/`<score>`/`<pages>`/`<page>`/`<system>`/`<measure>` aninhamento e milestones) com o C++, igualdade exata dos fragmentos em escopo.

## Critérios de aceite

- [ ] `dart analyze` — nenhum issue novo fora da baseline corrente
- [ ] `dart test` — verde, sem regressão, contagem só sobe
- [ ] Nenhum `_notYet` dos 16 resta — diff de nomes (C++×Dart) vazio para o intervalo, colado
- [ ] Fragmentos estruturais dos arquivos de teste idênticos ao C++ (colados)
- [ ] Relatório em `prompts/reports/06-12.md`
- [ ] `PLANO.md`: sufixo de progresso

## Armadilhas conhecidas

- **Milestones**: `Ending`/`Section`/`Expansion` viram pares início/fim no formato page-based e voltam a aninhar no score-based — `lib/src/model/drawing_interfaces.dart` tem `convertToPageBasedMilestone`; a saída faz o inverso.
- Exportar score-based documento cast-off exige desfazer o cast-off (`UnCastOffFunctor`, já portado em `lib/src/layout/cast_off.dart`) — sem mutar além do que o C++ muta.

## Fora de escopo

- Família scoreDef-interna (06-13) e controle/camada (06-15 em diante).
