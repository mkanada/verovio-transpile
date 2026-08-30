# 2026-08-30-01 (medium) — O instrumento: pinpointing de chamadas de desenho

> Você é o **Sonnet**. Antes de começar: leia `prompts/00-MESTRE.md` (§6-bis e
> §10) e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
>
> Esta tarefa você faz **sozinho** — não gere prompts `small`. Ela constrói o
> instrumento que todas as tarefas seguintes usam, e §10 do MESTRE diz que o
> instrumento vem antes do resultado.

## Por que esta tarefa existe

Hoje a Fase 5 sabe *quantos* arquivos divergem (505 de 621) mas não sabe *qual
função* diverge em cada um. Isso torna 5.6 inacionável e torna a tipagem
perigosa: trocar `dynamic` por tipo pode mudar a semântica sem que teste algum
perceba, porque o arquivo já divergia por outro motivo.

A saída é comparar o **fluxo de chamadas de desenho** do Dart com o do C++
instrumentado. A primeira divergência nomeia função, caminho estrutural,
argumento, esperado × obtido — e isso é tarefa de tamanho Haiku.

## Pré-condições

```bash
cd verovio_dart
dart run tool/phase5_status.sh          # placar atual, para o relatório
ls ../build/verovio                     # binário limpo existe
ls ../build-probe/build/verovio         # binário instrumentado existe
cat ../cpp_probe/README.md              # convenções da máquina de probe
```

## Parte 1 — patch de instrumentação `05-38`

O próximo id livre é `05-38` (veja `cpp_probe/patches/ORDER`).

Instrumente **`SvgDeviceContext`** (`origin/src/src/svgdevicecontext.cpp`) nas
primitivas de desenho, emitindo um registro por chamada:

- `DrawSmuflCode`, `DrawSmuflString`, `DrawSmuflLine`
- `DrawLine`, `DrawPolyline`, `DrawCurve`, `DrawRectangle`, `DrawRoundedRectangle`
- `DrawText`, `StartText`, `EndText`
- `StartGraphic`, `EndGraphic`, `ResumeGraphic`, `RotateGraphic`

Cada registro precisa de: `fn`, número de sequência global (`seq`), `path`
(caminho estrutural do objeto corrente — reuse `probe::Path`), e **todos os
argumentos numéricos e de código de glifo**, com o nome do parâmetro do C++.

Regras da máquina de probe (`00-MESTRE.md` §6-bis), todas obrigatórias:

- Só `fprintf`/`probe::Emit` — **nunca** altere lógica.
- Só acréscimo de linhas; o `diff` do patch não pode remover nada.
- `cpp_probe/mkpatch.sh 05-38` gera o patch; acrescente `05-38` ao fim de
  `cpp_probe/patches/ORDER`.
- **Invariante que reprova a tarefa se falhar:** o SVG do binário instrumentado
  tem de ser byte a byte idêntico ao do limpo.
  ```bash
  cd .. && build/verovio -r verovio_dart/assets/data -x 12345 -o /tmp/clean.svg \
      verovio_dart/test/corpus/note/note-001.mei
  cpp_probe/run.sh 05-38 test/corpus/note/note-001.mei \
      verovio_dart/test/fixtures/cpp/05-38/note-001.mei.jsonl --svg /tmp/probe.svg
  diff /tmp/clean.svg /tmp/probe.svg   # TEM de sair vazio
  ```

## Parte 2 — o gravador do lado Dart

Existe `RecordingDeviceContext` em `test/support/render_family.dart:184`, mas
ele grava só fronteira de gráfico, sem argumento numérico.

Crie `lib/src/testing/draw_recorder.dart` — código de apoio do port, como
`lib/src/testing/svg_compare.dart`, não port de arquivo C++ nenhum:

- `class DrawRecorder extends SvgDeviceContext`, sobrescrevendo **as mesmas
  primitivas** da Parte 1 e emitindo **o mesmo formato de registro**.
- `List<Map<String, Object?>> get records`.
- `String toJsonl()` — uma linha por registro, na mesma forma do fixture.

O formato tem de bater campo a campo com o C++. Onde o nome do parâmetro
diferir entre os dois lados, use **o nome do C++** e comente o desvio.

Migre `RecordingDeviceContext` de `test/support/` para usar o novo gravador,
para não haver duas implementações divergindo.

## Parte 3 — `tool/probe_diff.dart`

```
dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei
dart run tool/probe_diff.dart --dir=test/corpus/<fam>      # a família toda
dart run tool/probe_diff.dart --dir=test/corpus --rank     # ranking por causa
```

Comportamento:

1. Renderiza o arquivo com `DrawRecorder`.
2. Lê o fixture C++ correspondente em `test/fixtures/cpp/05-38/`.
   Se não existir, **reprova com "fixture ausente — gere com
   `tool/gen_probe_fixtures.sh <fam>`"**. Silêncio nunca é aprovação (§10).
3. Alinha os dois fluxos por `seq` e por `path`.
4. Reporta a **primeira** divergência assim:

   ```
   test/corpus/dir/dir-001.mei
     seq 412  fn=DrawSmuflCode  path=measure[1]/staff[1]/layer[1]/note[2]
       x:      esperado 2859   obtido 2802   (Δ -57)
       y:      esperado 1170   obtido 1170
       code:   esperado E262   obtido E262
     origem provável: View::DrawAccid (view_element.cpp:1204)
   ```

   A linha "origem provável" vem de um mapa `fn+contexto -> método C++` que
   você monta a partir de quem chama a primitiva no C++.

5. Com `--rank`: agrupa as primeiras divergências de todo o corpus por
   `(fn, origem provável)` e ordena por **quantos arquivos cada causa
   destrava**. Essa é a fila de trabalho de 5.6.

## Parte 4 — geração dos fixtures

`tool/gen_probe_fixtures.sh [familia…]` — roda `cpp_probe/run.sh 05-38` sobre
o corpus (ou só as famílias pedidas), grava em `test/fixtures/cpp/05-38/`, e
**verifica a invariante do SVG idêntico em cada arquivo**, abortando no
primeiro que divergir.

Fixtures de todo o corpus são grandes. Regra: gere sob demanda, por família, e
não commite fixture que nenhuma tarefa consome ainda.

## Parte 5 — prova de que o instrumento é honesto

Cole no relatório, com a saída real:

1. **Mutação no Dart:** mude uma constante de desenho (ex.: um `x - xCorr`
   para `x - xCorr + 1`) num método já limpo → `probe_diff` acusa a
   divergência exata. Desfaça.
2. **Fixture ausente:** apague um fixture → `probe_diff` reprova com a
   mensagem certa. Restaure.
3. **Arquivo limpo:** um dos 7 numericamente limpos (`clef/clef-002.mei`)
   → `probe_diff` diz zero divergências.

Sem estas três provas a tarefa não fecha: um instrumento que não morde não
serve para guiar o Haiku.

## Critério de aceite

- [ ] `cpp_probe/patches/05-38.patch` versionado, só acréscimos, `05-38` no fim de `ORDER`.
- [ ] `diff` do SVG limpo × instrumentado vazio em pelo menos 5 arquivos de famílias diferentes.
- [ ] `lib/src/testing/draw_recorder.dart` existe; `test/support/render_family.dart` usa ele.
- [ ] `tool/probe_diff.dart` e `tool/gen_probe_fixtures.sh` existem e rodam.
- [ ] As 3 provas da Parte 5 coladas no relatório.
- [ ] `dart analyze` ≤ 8; `dart test` verde.
- [ ] `dart run tool/probe_diff.dart --dir=test/corpus --rank` roda e produz a fila inicial de causas — cole as 15 primeiras no relatório.
- [ ] Relatório em `prompts/reports/2026-08-30-01.md`.
- [ ] **Um commit** ao final, com a fila de causas resumida na mensagem.

## O que NÃO fazer aqui

- Não conserte nenhuma divergência. Esta tarefa constrói o instrumento; quem
  conserta são as tarefas 02 a 05.
- Não toque em `lib/src/rendering/view_*.dart` (fora a migração do gravador).
