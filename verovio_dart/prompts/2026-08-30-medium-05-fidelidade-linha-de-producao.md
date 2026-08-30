# 2026-08-30-medium-05 — Fidelidade: a linha de produção até 621/621

> Você é o **Sonnet**. Leia `prompts/00-MESTRE.md` (§10) e `CLAUDE.md`.
> Depende de `2026-08-30-medium-01` (instrumento) e das `02`/`03`/`04` (tipagem zerada).
>
> **Este prompt é um ciclo, não uma tarefa.** Você o executa repetidamente,
> uma rodada por sessão, até o portão fechar. Cada rodada termina com um
> commit e com o placar atualizado.

## O alvo, sem maquiagem

O critério 5.6 exige **621/621 limpos nos dois modos** — estrutural e numérico
com epsilon 0 — e **0 exceções**. O dono decidiu manter esse alvo.

Estado em 2026-08-30: **116/621 estrutural, 7/621 numérico, 0 exceções**.

Isso é muito trabalho e **não fecha numa rodada**. O que este prompt garante é
que cada rodada seja *medida, guiada e irreversível*: nunca se perde terreno, e
o próximo sempre sabe onde pegar. Se ao fim de uma rodada o portão não fechou,
você escreve a rodada seguinte — não marca a fase como concluída (§10, regra 3).

## O ciclo, uma rodada

### 1. Medir e ranquear

```bash
tool/phase5_status.sh --full                       # placar; ~10 min
dart run tool/probe_diff.dart --dir=test/corpus --rank > /tmp/rank.txt
head -30 /tmp/rank.txt
```

O `--rank` agrupa a **primeira divergência** de cada arquivo por
`(primitiva, método C++ de origem)` e ordena por **quantos arquivos aquela
causa destrava**. É a fila de trabalho. Uma causa no topo com 40 arquivos vale
quarenta vezes mais que uma com 1.

### 2. Escolher as causas da rodada

Pegue as **3 a 6 causas do topo** que couberem na sessão. Para cada uma:

1. Reduza a um arquivo mínimo (o menor do grupo).
2. Leia o método C++ inteiro — não o trecho, o método.
3. Compare com o Dart lado a lado.
4. Formule a correção **você**, não o Haiku. O Haiku aplica; quem entende o
   algoritmo é você.
5. Se ler o `.cpp` não explicar, instrumente mais fundo: novo patch em
   `cpp_probe/patches/`, seguindo `00-MESTRE.md` §6-bis (só acréscimo, `diff`
   de SVG vazio).

### 3. Fatiar para o Haiku

Uma unidade `small` por causa. Use `prompts/2026-08-30-small-TEMPLATE.md`,
gravando como `prompts/2026-08-30-small-05r<rodada><letra>-<slug>.md` (ex.:
`2026-08-30-small-05r1a-ligature-estrutura.md`), e adaptando a seção
"O procedimento" para o formato de correção de divergência:

```markdown
## A divergência

    seq 412  fn=DrawSmuflCode  path=measure[1]/staff[1]/layer[1]/note[2]
      x:  esperado 2859   obtido 2802   (Δ -57)

## A causa (já diagnosticada — não investigue, aplique)

`View::DrawAccid` (view_element.cpp:1204) calcula
`x = accid->GetDrawingX() - accid->GetDrawingRadius(m_doc)`.
O Dart em `view_element.dart:<linha>` usa `getSelfLeft()`.

## A correção

<o patch exato, ou a instrução linha a linha>

## Verificação

    dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei
    # tem de sair "0 divergências" para este arquivo

    tool/task_check.sh view_element.dart <fam>
    # tem de imprimir PASS
```

O Haiku só termina quando **as duas** verificações passarem.

### 4. Fechar a rodada

```bash
dart run tool/compare_svg.dart --all
dart run tool/verify_phases.dart --fase=5
dart test
```

- O número estrutural **tem de subir**. Se não subiu, a rodada não achou causa
  real — diga isso no relatório em vez de commitar barulho.
- Atualize `pisoEstrutural` em `test/svg_golden_test.dart` para travar o ganho.
- **Um commit** da rodada.

### 5. Decidir

```bash
tool/phase5_status.sh
```

- **Exit 0** → a Fase 5 fechou. Vá para `2026-08-30-medium-06`.
- **Exit ≠ 0** → escreva a rodada seguinte como
  `prompts/2026-08-31-medium-NN-fidelidade-rodada-<n>.md`, herdando este
  formato e começando pela fila que sobrou. Registre no relatório: quantos
  arquivos a rodada destravou, qual causa deu mais retorno, e qual é a
  próxima do ranking.

## Causas já medidas (ponto de partida da rodada 1)

Não precisa redescobrir estas — foram medidas em 2026-08-30:

| família | estado | o que o instrumento já disse |
|---|---|---|
| `ligature` | 0/50 | o Dart emite 11 filhos em `svg/g[0]/g[2]` onde o C++ emite 5 — divergência **estrutural**, não de glifo |
| `mensural` | 0/25 | `<defs>` com 20 glifos contra 26, e 4 extras (`E084/E086/E088/E925`) |
| `tuplet` | 0/22 | não investigado |
| `lyric` | 0/16 | depende de `view_text.dart` (tipado na `04`) |
| `dir`/`dynam` | 0/12, 0/10 | dependem de `view_control.dart` (tipado na `02`) |

E uma hipótese antiga que continua valendo o teste:
`note/note-001.mei`, o `accid` sai em `x=2802` no Dart e `x=2859` no C++
(57 unidades), com a cabeça em `3026` nos dois — desvio horizontal sistemático.

## Regras que não negociam nesta tarefa

- **Nunca** ajuste um número no Dart para "bater" sem entender a fórmula do
  C++. O objetivo é equivalência funcional, não coincidência numérica.
  Se você não sabe *por que* o C++ dá 2859, não commite 2859.
- **Nunca** relaxe uma catraca, um limiar de teste ou um critério do portão
  para fazer a rodada "fechar" (§10, regra 3).
- **Nunca** marque a Fase 5 concluída sem `verify_phases.dart --fase=5`
  saindo 0.

## Critério de aceite de CADA rodada

- [ ] `compare_svg --all` estrutural estritamente maior que no início da rodada.
- [ ] `dart analyze` ≤ 8; `dart test` verde; 0 exceções de renderização.
- [ ] `pisoEstrutural` atualizado.
- [ ] Tabela no relatório: causa → arquivos destravados → antes × depois.
- [ ] Fila restante (top 15 do `--rank`) colada no relatório.
- [ ] **Um commit** da rodada.
- [ ] Se o portão não fechou: o prompt da rodada seguinte escrito e indexado
      em `prompts/README.md`.
