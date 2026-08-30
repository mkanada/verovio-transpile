# 06-13 — MEIOutput (F): família do scoreDef

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Regra de números: critérios medem contra o estado corrente — nunca contra contagem fixa.

## Objetivo

Portar os `Write*` da família scoreDef e elementos correntes de página: `WriteTextLayoutElement,
WriteRunningElement, WriteGrpSym, WriteDiv, WritePgFoot, WritePgHead, WriteStaffGrp,
WriteStaffDef, WriteInstrDef, WriteLabel, WriteLabelAbbr, WriteLayerDef, WriteTuning,
WriteCourse, WriteSymbolTable`.

## Pré-condições

Tarefa **06-12** concluída.

```bash
cd verovio_dart
dart test test/mei_output_test.dart 2>&1 | tail -1
```

## Referência C++

`origin/src/src/iomei.cpp:1835-1988` — os 15 `Write*` nominais (grep + lista colada no relatório).

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/io/mei_output.dart`.
- **Alterar** `test/mei_output_test.dart`.

## Passo a passo

1. Porte os 15, citando linha.
2. Teste: um arquivo do corpus com `pgHead`/`pgFoot` (grep no corpus para achar — dinâmico) e um com `staffGrp`/`labels` (a maioria); fragmentos idênticos ao C++.

## Critérios de aceite

- [ ] `dart analyze` — nenhum issue novo fora da baseline corrente
- [ ] `dart test` — verde, sem regressão, contagem só sobe
- [ ] Nenhum `_notYet` dos 15 resta — diff de nomes vazio para o intervalo, colado
- [ ] Fragmentos scoreDef/pgHead idênticos ao C++ (colados)
- [ ] Relatório em `prompts/reports/06-13.md`
- [ ] `PLANO.md`: sufixo de progresso

## Armadilhas conhecidas

- `WriteStaffDef` interage com `AdjustStaffDef` (06-11) para decidir o que escrever; ordem errada escreve scoreDef inflado.
- `WriteTuning`/`WriteCourse` são tablatura — o corpus `tab/` cobre.
- `WriteSymbolTable` só existe com `symbolDef`; sem ele, o C++ nem chama — preserved a guarda.

## Fora de escopo

- `WriteMeasure`/controle (06-15/06-16) e camada (06-17/06-18).
