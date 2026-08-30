# 06-14 — Verificação independente 2: MEIOutput (A)–(F)

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Verificação adversarial: sem código de produção. Achado vira relatório e, se preciso, prompt novo.

## O que esta tarefa é

Audita as tarefas **06-08 a 06-13** (infraestrutura, despachante, `WriteObjectInternal`,
`WriteDoc`, estrutura e scoreDef do MEIOutput) — sem confiar nos relatórios delas.

## Passo 1 — instrumento antes do resultado

1. Portão intacto desde a última verificação: `git log --oneline -- tool/verify_phases_6_plus.dart` + diff; critério rebaixado/alargado sem C++ citado = fraude.
2. As comparações "idêntico ao C++" dos relatórios do bloco: **reproduza uma** — gere `build/verovio -t mei` para `note-001.mei`, rode o export Dart, diff os fragmentos declarados idênticos. Divergência entre o que o relatório afirma e o que você mede = achado grave (relatório escrito contra outro estado).

## Passo 2 — portão mecânico

```bash
dart run tool/verify_phases_6_plus.dart --fase=6 --verbose
```
6.2 (superfície MEIOutput) deve listar apenas os `Write*` ainda legítimos das tarefas 06-15..06-20; 6.3/6.4 seguem reprovação correta (getMEI/validate_mei vêm na 06-21).

## Passo 3 — mordida e armadilhas estruturais

1. Prova de mordida (2 testes): mute a ordem de atributos no `WriteObjectInternal` (troque duas chamadas de interface) → o teste de ordem da 06-10 **tem** de ficar vermelho; desfaça. Desligue a indentação → o teste do `<meiHead>` da 06-11 tem de ficar vermelho; desfaça.
2. Confira que nenhum `Write*` portado no bloco lê default de constante hard-coded em vez da opção (`m_outputIndent` etc.).
3. `_notYet` restantes: gere a lista (grep) e confira que cada um nomeia a tarefa certa (06-15..06-20).

## Passo 4 — sem regressão transversal

`dart analyze` ≤ baseline; `dart test` verde; `compare_svg --all --mode=structural` não regride vs. medição ANTES do bloco (anotada nos relatórios).

## Veredito

`prompts/reports/06-14.md`: veredito por tarefa (06-08..06-13), saída do portão, tabela de mordida, divergências relatório×medição, achados com arquivo:linha, e o prompt que fecha o que estiver aberto (linkado no `README.md`). **Fechar tarefa é consequência do número.**

## Fora de escopo

- Código de produção (exceto prompt de conserto). Elementos de controle/camada (06-15 em diante).
