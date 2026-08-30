# 06-07 — Verificação independente 1: portão, reset e find

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Esta é uma tarefa de **verificação adversarial**: você não escreve código de produção. Achado vira relatório e, se preciso, prompt novo.

## O que esta tarefa é

Primeira verificação da cadência (a cada ~5 tarefas de execução). Audita as tarefas **06-00 a 06-06** (portão, resetfunctor, findfunctor, findlayerelements) sem confiar em nenhum relatório delas — mede tudo de novo.

## Passo 1 — o instrumento antes do resultado

1. O portão não foi adulterado desde a 06-00:
   ```bash
   git log --oneline -- tool/verify_phases_6_plus.dart
   git diff <commit-da-06-00>..HEAD -- tool/verify_phases_6_plus.dart
   ```
   Qualquer critério removido, rebaixado (`checa`→`info`) ou com limiar alargado sem justificativa citando C++ = **fraude de portão** — reprove imediatamente e escreva o prompt de conserto.
2. As provas de honestidade da 06-00 ainda valem: re-execute as duas (critério comentado muda veredito; relatório envelhecido reprova), desfaça.

## Passo 2 — o portão mecânico

```bash
dart run tool/verify_phases_6_plus.dart --fase=6 --verbose
```

Confirme: 6.1 sem nenhum `Reset*`/`Find*`/`AddToFlatList`/`LayersInTimeSpan`/`GetRelativeLayerElement` na lista de ausentes; os critérios de golden (6.4-6.6) reprovam por "relatório ausente" (as ferramentas ainda não existem — **silêncio não é aprovação**, e essa é a falha correta).

## Passo 3 — medição fresca e mordida

1. Re-execute os testes do bloco (`test/reset_*`, `test/find_*`) e compare com o que os relatórios 06-01..06-06 afirmam — divergência relatório×medição é achado grave.
2. Prova de mordida (2 testes, no mínimo): mute uma decisão no `lib/` (ex.: um campo que um `Visit*` do reset deveria limpar — deixe de limpá-lo) → o teste correspondente **tem** de ficar vermelho; desfaça (`git checkout -- <arquivo>`). Teste que permanece verde sob mutação da sua linha é tautológico — achado.
3. O teste de idempotência da 06-03: confira que ele cobre **todas** as famílias de `test/corpus/` dinamicamente (a lista não é hard-coded) e que a igualdade é exata de string.

## Passo 4 — sem regressão transversal

```bash
dart analyze                    # ≤ baseline corrente
dart test                       # verde, nenhum skip novo
dart run tool/compare_svg.dart --all --mode=structural   # não regride vs. medição ANTES (anotada nos relatórios do bloco)
```

## Veredito

`prompts/reports/06-07.md`, nesta ordem: (1) veredito por tarefa (06-00..06-06) — FECHADA/ABERTA com motivo; (2) saída do portão; (3) tabela mordida×mutação; (4) divergências entre relatórios e medições frescas; (5) achados com arquivo:linha e C++ vs Dart; (6) se algo ficou ABERTO: o prompt que fecha, gravado e linkado no `README.md`.

**Regra que não negocia:** fechar tarefa é consequência do número, não decisão de quem escreve o relatório.

## Fora de escopo

- Código de produção (exceto prompt novo de conserto).
- MEIOutput (06-08 em diante).
