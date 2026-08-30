# 2026-08-30-medium-06 — O portão final e o fechamento da Fase 5

> Você é o **Sonnet**. Leia `prompts/00-MESTRE.md` (§10) e `CLAUDE.md`.
> Depende de `2026-08-30-medium-01` a `05`. **Não escreve código de produção.**
>
> Esta tarefa é reutilizável: rode-a sempre que quiser saber, com prova, se a
> Fase 5 terminou. Ela responde sim ou não — e a resposta é consequência do
> número, nunca decisão sua.

## A pergunta

A Fase 5 terminou?

## Passo 1 — medir do zero

Nada de número herdado de relatório. Regere tudo:

```bash
cd verovio_dart
dart analyze                                   2>&1 | tail -2
dart test                                      2>&1 | tail -2
dart run tool/compare_svg.dart --all           2>&1 | tail -5
dart run tool/validate_layout.dart             2>&1 | tail -3
dart run tool/debt_report.dart
dart run tool/verify_phases.dart --full --verbose
```

Cole **a saída real** de cada um no relatório. Paráfrase não vale.

## Passo 2 — provar que o portão não foi adulterado

§10 diz: portão adulterado reprova a fase mesmo com PASS.

```bash
git log --oneline -- tool/verify_phases.dart
git diff a25ef2e..HEAD -- tool/verify_phases.dart
```

Confira, um por um:

- Nenhum critério foi **removido**.
- Nenhum `checa(...)` virou `info(...)` (rebaixamento silencioso).
- Nenhum limiar foi **alargado**. Apertar pode; alargar exige justificativa
  datada no próprio código e aval do dono.
- `kAnalyzeBaseline` continua 8.
- O alvo de 5.6 continua `total` nos dois modos.

Faça o mesmo com as catracas:

```bash
git diff a25ef2e..HEAD -- test/svg_golden_test.dart test/view_*_test.dart | grep -E '^[-+].*(greaterThan|piso|Equal)'
```

`pisoEstrutural` só pode ter **subido**.

## Passo 3 — as três provas que o portão não sabe fazer

Cole a saída real das três. Sem elas, o número não vale nada.

**(a) O harness não devolve os próprios goldens** (prova por mutação — a mais
importante; foi o defeito do episódio `05-26`, quando 489 "limpos" eram
goldens devolvidos):

```bash
grep -rn "test/golden/cpp" lib/src/testing/svg_compare.dart   # EXIT 1, nada
dart test test/harness_integrity_test.dart                    # verde
# mutar um golden limpo -> o comparador tem de acusar
python3 -c "import re,pathlib; p=pathlib.Path('test/golden/cpp/clef/clef-002.svg'); t=p.read_text(); m=re.search(r'x=\"(\d+)\"',t); p.write_text(t[:m.start()]+'x=\"9999\"'+t[m.end():])"
dart run tool/compare_svg.dart test/corpus/clef/clef-002.mei  # tem de virar divergente
git checkout -- test/golden/cpp/clef/clef-002.svg
dart run tool/compare_svg.dart test/corpus/clef/clef-002.mei  # volta a limpo
```

**(b) Os testes mordem.** Escolha 3 testes ao acaso que cubram trabalho
recente. Para cada um: mute a linha de `lib/` que ele cobre, rode o teste (tem
de ficar **vermelho**), `git checkout` do arquivo, rode de novo (**verde**).
Tabela no relatório com o `Expected/Actual` de cada falha.

**(c) O SVG desenha a mesma música.** Escolha 3 arquivos estruturalmente
limpos de famílias diferentes e mostre que a árvore de elementos e o conjunto
de glifos batem com o golden. Limpo estrutural não é o mesmo que correto — esta
prova separa os dois.

## Passo 4 — o veredito

Regra única e não negociável:

```
verify_phases.dart --fase=5 sai 0  E  as três provas do Passo 3 passam
    -> Fase 5 FECHADA
qualquer outra coisa
    -> Fase 5 ABERTA
```

Não há meio-termo, não há "praticamente fechada", não há arredondamento.

### Se FECHADA

- `PLANO.md`: marque a Fase 5 concluída, com **os números medidos** (não
  adjetivos) e a data.
- `PLANO.md` "Estado medido": atualize as quatro métricas.
- `prompts/README.md`: marque a série `2026-08-30-medium-*` como concluída.
- Relatório em `prompts/reports/2026-08-30-medium-06.md` com tudo do Passo 1 ao 3.
- **Um commit.**

### Se ABERTA

- **Não marque nada.** `PLANO.md` continua `🔶` com o número medido.
- Escreva a rodada seguinte (`prompts/2026-08-31-medium-NN-...`) herdando
  o formato da `2026-08-30-medium-05`, começando pela fila que sobrou do `--rank`.
- Indexe em `prompts/README.md`.
- Relatório dizendo, sem eufemismo: **qual critério reprovou e por quanto**.
- **Um commit.**

## Encerramento por decisão do dono

§10 abre uma exceção: o dono pode encerrar uma fase sem o número. Se for o
caso, o registro tem de ser **explícito, datado e com o estado medido no
momento do encerramento** — em `PLANO.md`, não só num relatório. Você não toma
essa decisão; só a registra quando ela for dada.

## Critério de aceite

- [ ] Saída real de todos os comandos do Passo 1 colada no relatório.
- [ ] Passo 2 conferido item a item, com o `git diff` colado.
- [ ] As três provas do Passo 3 com saída real.
- [ ] Veredito explícito: FECHADA ou ABERTA, com o critério que decidiu.
- [ ] `PLANO.md` reconciliado com o que foi medido.
- [ ] Se ABERTA: o prompt da rodada seguinte existe e está indexado.
- [ ] **Um commit.**
