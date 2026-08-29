# 2026-08-29-06 — Verificação independente das Fases 1 a 4

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## O que esta tarefa é

Uma **auditoria adversarial**. Você não está aqui para confirmar que as tarefas `2026-08-29-02` a
`-05` foram feitas; está aqui para **tentar provar que não foram**, e só declarar as fases fechadas
se não conseguir.

Isto não é paranoia de processo. A Fase 5 já foi declarada concluída uma vez, em 2026-08-29, com
`489/623` arquivos limpos — e o número real era `0/623`, porque o harness devolvia os próprios
goldens (ver `prompts/reports/05-26.md`). Uma fase declarada pronta contra um instrumento quebrado
custou mais do que teria custado desconfiar na hora.

**Você não escreve código de produção nesta tarefa.** Se achar um defeito, ele vira uma linha no
relatório e um prompt novo — não um conserto. A única exceção é consertar o próprio verificador,
se ele estiver medindo errado.

## Passo 1 — o portão mecânico

```bash
cd verovio_dart
dart run tool/verify_phases.dart --verbose
```

Anote a saída inteira no relatório. Cada `FALHA` é uma fase que não terminou. Se tudo passar,
**não pare aqui** — os passos seguintes existem porque um portão só mede o que alguém lembrou de
programar nele.

## Passo 2 — o portão não foi adulterado

O jeito mais barato de fazer uma fase "passar" é afrouxar o medidor. Confira:

```bash
git log --oneline -- tool/verify_phases.dart
git diff <commit-antes-da-01>..HEAD -- tool/verify_phases.dart
```

Reprove se encontrar, sem justificativa escrita no relatório da tarefa correspondente:

- entrada nova em `kResourcesEquivalentes` (o mapa de equivalências idiomáticas da Fase 1) — cada
  uma é uma dívida de nomenclatura assumida e precisa de razão citando o C++;
- critério removido, ou rebaixado de `checa`/`falha` para `info`;
- `kAnalyzeBaseline` acima de 8;
- `kFunctorsFase4Abertos` encurtada;
- qualquer alargamento em `_leRelatorio` que aceite relatório obsoleto.

## Passo 3 — as quatro correções são ports, não contornos

Para cada tarefa, abra o diff e o C++ lado a lado. O que você procura é **a decisão do C++
reproduzida**, não o sintoma removido.

**`2026-08-29-02` (Resources).** `SetCSSFont` e `UseLiberationTextFont` existem? Compare com
`origin/src/src/resources.cpp`: se o C++ invalida estado ao trocar de fonte, o Dart invalida também?
Se a tarefa resolveu algum dos dois acrescentando ao mapa de equivalências em vez de portar, a
justificativa está no relatório e cita o header?

**`2026-08-29-03` (`oStaff`/`stageDir`).** Os dois registros existem e constroem
`Staff(1, isOssia: true)` e `Dir(isStageDir: true)`? Que `ClassId` receberam? O C++ usa
`FACTORY_OSTAFF`/`FACTORY_STAGEDIR`, distintos de `STAFF`/`DIR` — se o Dart reusou `ClassId.staff`
e `ClassId.dir`, existe um bloco `Deviations from the C++:` explicando por quê, e alguém verificou
que nenhum `isClass(...)` do port depende da distinção?

**`2026-08-29-04` (reescopo).** `git diff --stat` da tarefa toca **só** `PLANO.md` e
`prompts/README.md`? A Fase 6 do `PLANO.md` diz que `MEIOutput` veio da Fase 3? Se o reescopo
apagou a pendência sem realojá-la com destaque, isso é maquiagem — reprove.

**`2026-08-29-05` (transcrição).** Este é o de maior risco. Perguntas, em ordem:
1. `Page::LayOutTranscription` foi portado, ou só os functors? Se só os functors, eles são código
   morto — o relatório admite isso explicitamente?
2. Os functors novos são **alcançados** em execução? Prove: ponha um `print`/breakpoint temporário
   dentro de `AdjustXRelForTranscription` e rode `test/corpus/neume/neume-001.mei`. Se não passar
   por lá, a tarefa entregou classes que nada invoca. Desfaça o `print` depois.
3. `ApplyPPUFactor` está ligado em `readPage` na mesma condição do C++
   (`IsTranscription() && ppuFactor != 1.0`)?
4. `neume/neume-001.mei` melhorou, piorou ou ficou igual? O relatório diz a verdade sobre isso?

## Passo 4 — os testes novos mordem

Um teste que passa com o código quebrado não é teste. Para **cada** teste acrescentado pelas quatro
tarefas, faça uma prova de mordida:

1. quebre deliberadamente a linha de `lib/` que o teste cobre (inverta um sinal, devolva `null`,
   troque a constante);
2. rode só aquele teste — ele **tem** de ficar vermelho;
3. desfaça a quebra (`git checkout --` no arquivo) e confirme o verde.

Liste no relatório: teste × mutação aplicada × ficou vermelho (sim/não). Qualquer "não" é um
defeito a reportar.

## Passo 5 — nada foi afrouxado no caminho

```bash
git diff <commit-antes-da-01>..HEAD -- test/ | grep -nE '^\+.*(skip:|anything|isNotNull|greaterThan\(0\)|tolerance|epsilon)'
git diff <commit-antes-da-01>..HEAD -- lib/ | grep -nE '^\+.*(ignore_for_file|as dynamic|catch \(_\))'
```

Toda linha que aparecer precisa de justificativa no relatório da tarefa que a introduziu (§7.3,
§8.1, §8.2 do MESTRE). `expect(x, isNotNull)` no lugar de um valor esperado é o afrouxamento mais
comum e o mais fácil de deixar passar.

Confira também que nenhuma skip-list nova apareceu. A única legítima em todo o projeto continua
sendo `dir/dir-011.mei` e `dir/dir-012.mei` (não-UTF-8 por decisão).

## Passo 6 — sem regressão nas medições caras

```bash
dart analyze                                  # ≤ 8
dart test                                     # verde, 0 falhas
dart run tool/validate_layout.dart            # ≥ 618/621 layout OK, ≥ 173 timemaps
dart run tool/compare_svg.dart --all          # ≥ 115 estrutural, ≥ 4 numérico (baseline 2026-08-29)
```

A Fase 4 não pode ter derrubado a Fase 5. Se o SVG piorou, é regressão da `2026-08-29-05` —
reprove, mesmo que o portão da Fase 4 passe.

## O veredito

Escreva `prompts/reports/2026-08-29-06.md` com, nesta ordem:

1. **Veredito por fase**, uma linha cada: `Fase N — FECHADA` ou `Fase N — ABERTA: <motivo em uma frase>`.
2. A saída completa de `verify_phases.dart --verbose`.
3. A tabela de provas de mordida do Passo 4.
4. Os achados, se houver, cada um com arquivo, linha, o que o C++ faz e o que o Dart faz.
5. Se alguma fase ficou aberta: o **prompt novo** que a fecha, gravado como
   `prompts/2026-08-29-<NN>-<slug>.md` e linkado no `README.md`. Não conserte aqui.

### A regra que não se negocia

**Fechar fase é consequência do número, não decisão de quem escreve o relatório.** Se o portão
reprovar, a fase fica aberta — mesmo que o motivo pareça pequeno, mesmo que só falte um método,
mesmo que "na prática funcione". Foi assim que `489/623` virou `0/623`.

## Fora de escopo

- Fase 5 inteira (é a `07`).
- Escrever código de produção.
- Marcar checkbox no `PLANO.md` — quem marca é a tarefa que fez o trabalho; você só confere se a
  marca corresponde ao medido, e reporta se não corresponder.
