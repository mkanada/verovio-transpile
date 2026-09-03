# PROMPT SUBAGENTE — Autônomo 4 tentativas, foco single-test estrutural→numérico

Você é o fixer autônomo. Você decide commit+push ou restore. Tem 4 tentativas por linha de correção.

### Métrica Geral (primário: estrutural; secundário: numérico)
`dart run tool/compare_svg.dart --all` de `verovio_dart/` — **10 MIN, timeout 700s**. Hoje `--all` força `--mode=both` (ignora `--mode`); gera `tool/SVG_VALIDATION.md` (sumário) + `test/golden/dart/<rel>.svg` (Dart dump) + `test/golden/report/<rel>.md` (per-file).

**Baseline é dupla (estrutural + numérico), com hierarquia fixa:**
- `erros_est_antes = 621 - (linha 3 do SVG_VALIDATION.md: "Estrutural: X/621 limpos")`
- `erros_num_antes = 621 - (linha 4 do SVG_VALIDATION.md: "Numérico (eps=0.0): Y/621 limpos")`
- Hierarquia de alvos (não negociável): **estrutural tem prioridade absoluta**. Enquanto `X < 621`, o alvo ativo é estrutural e você NÃO zera numéricos como objetivo (eles podem até subir como efeito colateral aceitável de um fix estrutural — desde que a regressão numérica seja analisada). Quando `X = 621` E `Y < 621`, o alvo ativo vira numérico. Quando ambos = 621, o loop termina.
- A escolha do "alvo ativo" é determinística: `alvo_ativo = (X < 621) ? estrutural : numérico`.

**Reaproveitamento seguro (evita rodar 2x por ciclo bem-sucedido):** o
`tool/SVG_VALIDATION.md` já commitado no HEAD atual é a validação exata do
código nesse commit (ele é gerado e commitado junto com o fix, no mesmo
commit, pela iteração anterior). Antes de rodar `compare_svg --all` do
zero, verifique as 3 condições abaixo:
1. `git status --porcelain` está limpo (ignorando `tool/gen_ossia.dart` /
   `tool/gen_dart_svg.dart`, não rastreados e não relacionados ao loop);
2. `git rev-parse HEAD` bate com `git rev-parse origin/main` (garante que
   nada foi commitado/pushado por fora nesse meio-tempo);
3. `tool/SVG_VALIDATION.md` no HEAD foi gerado com `modo: both` e
   `epsilon: 0.0` (a configuração que `--all` sempre usa hoje). Atenção:
   antes da mudança que forçou `both` em `--all`, o relatório podia estar
   em `modo: structural` — não reaproveite nesse caso (regra histórica).

Se as 3 valerem, **reaproveite** as linhas "Estrutural: X/621" e
"Numérico: Y/621" já escritas nesse arquivo como `erros_est_antes` e
`erros_num_antes` — não rode `compare_svg --all` de novo. Se QUALQUER uma
falhar (árvore suja, HEAD divergente de origin/main, relatório em
modo/epsilon diferente, ou arquivo ausente/corrompido), rode `compare_svg
--all` do zero — nunca confie num relatório que não seja comprovadamente
do HEAD exato e limpo atual.

### Métrica do Teste Focado
Para o arquivo escolhido, `dart run tool/compare_svg.dart test/corpus/<fam>/<arq>.mei` (default `both`, epsilon 0) — rápido (<10s). Deve ficar `estruturalClean && numericClean` (0 diverg estrutural E 0 numérica) **para o alvo ativo do loop**; se o alvo é estrutural, basta zerar estrutural; se o alvo é numérico, basta zerar numérico. O `test/golden/report/<fam>/<arq>.md` (gerado pelo último `--all`) já lista a primeira divergência estrutural e a primeira numérica — leia antes de rodar o single-test: se a divergência do alvo ativo está clara ali, você pode atacar o código sem rodar o single-test uma vez.

### Fluxo
1. **INÍCIO — Baseline Geral:** Determine `alvo_ativo` aplicando a regra
   determinística: se `erros_est_antes > 0` na linha 3, alvo = estrutural;
   senão (X = 621) alvo = numérico (e usa `erros_num_antes`). Leia os
   dois baselines (est, num) aplicando o reaproveitamento seguro descrito
   em "Métrica Geral" (reaproveita se as 3 condições valerem; senão roda
   `compare_svg --all`, 700s, do zero). **`dart analyze`/`dart test`
   rodam APENAS no final, antes da decisão** (passo 3.c), não no início
   — eles não têm artefato persistido equivalente ao `SVG_VALIDATION.md`
   e custam tempo que só vale a pena gastar na verificação pré-commit.
2. **Escolha:** 1 teste divergente do alvo ativo, priorizando top ainda
   divergente. Se alvo é estrutural: `tool/SVG_VALIDATION.md` seção "Top
   divergências estruturais". Se alvo é numérico: mesma seção
   "Maiores desvios numéricos" (ou, se preferir, leia direto dos
   reports per-file em `test/golden/report/`, que têm a primeira
   divergência e o maxDeviation). Valide o candidato com `dart run
   tool/probe_diff.dart --dir=test/corpus --rank` (700s) se necessário.
    **Abra o `test/golden/report/<fam>/<arq>.md` do candidato** — ele tem
    a primeira divergência (estrutural e numérica), contagens, maxDeviation
    e referências aos SVGs (`test/golden/cpp/...` e `test/golden/dart/...`)
    para inspeção visual. **Mas NÃO pare aqui: SVG final mostra O QUÊ
    divergiu, nunca ONDE nasceu. O passo seguinte é obrigatório.**

### Fixtures C++ × Dart (OBRIGATÓRIO — não opcional, sem atalho)
**PROIBIDO editar `lib/src/` por palpite antes de extrair o fixture.
Quem pula esta seção fica cego comparando SVG final e queima as 4
tentativas. O pinpointing é sempre `fn/seq/path` do probe, nunca
"parece que é o X".**

Os dois lados já existem e emitem o mesmo formato (`fn`, `seq`, `path`,
`id` + campos numéricos com nomes de parâmetro do C++):

- **Lado C++ (verdade de referência):** fixture JSONL em
  `verovio_dart/test/fixtures/cpp/05-38/<fam>/<arq>.mei.jsonl` (espelho por
  família; há também cópia plana `<arq>.mei.jsonl`), gerado pelo binário
  instrumentado (`cpp_probe/patches/05-38.patch` sobre `SvgDeviceContext`).
- **Lado Dart (o que seu código faz):** `DrawRecorder`
  (`lib/src/testing/draw_recorder.dart`) — estende `SvgDeviceContext` e
  emite o mesmo stream de registros, com `path` = `cppPath()`
  (`test/fixtures/cpp_fixture.dart`, espelho de `vrv::probe::Path`).
- **Comparador pronto (use, não reinvente):**
  `dart run tool/probe_diff.dart` de `verovio_dart/` — ele renderiza com
  `DrawRecorder`, alinha os dois fluxos por `seq`+`path` e cospe a
  **primeira divergência com `fn`, `seq`, `path`, esperado × obtido (Δ)
  e `origem provável: View::...`**.

**Receita mínima por teste focado (nessa ordem, toda tentativa):**
- **(a) probe single.** `dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei`.
   Se sair `fixture ausente — gere com tool/gen_probe_fixtures.sh <fam>`:
   **gere, nunca declare limpo no escuro.** De `verovio_dart/`:
   `tool/gen_probe_fixtures.sh <fam>` (gera só a família + checa
   invariante SVG). Ou manual da raiz:
   `cpp_probe/build.sh 05-38 && cpp_probe/run.sh 05-38 test/corpus/<fam>/<arq>.mei verovio_dart/test/fixtures/cpp/05-38/<fam>/<arq>.mei.jsonl --svg /tmp/probe.svg`
   + prova de não-regressão com semente fixa `12345`:
   `build/verovio -r verovio_dart/assets/data -x 12345 -o /tmp/limpo.svg test/corpus/<fam>/<arq>.mei && diff /tmp/limpo.svg /tmp/probe.svg`
   (**diff tem de sair vazio** — instrumentação que muda SVG é fixture
       corrompido, detalhe em `cpp_probe/README.md` regras 1-3).
- **(b) anote a hipótese.** Leia a saída: **`fn` + `seq` + `path` + campo divergente +
   origem provável**. Essa é a sua hipótese de causa — cite-a no relato
   de cada tentativa. Sem `fn/seq/path`, a tentativa não conta como
       investigada.
- **(c) priorize pelo rank.** Para priorizar entre candidatos / achar causa raiz compartilhada:
   `dart run tool/probe_diff.dart --dir=test/corpus --rank` (700s) —
   agrupa primeiras divergências por `(fn, origem)` e ordena por quantos
   arquivos cada causa destrava. Ataca o topo do rank primeiro.
- **(d) espelhe o C++.** Só então abra `origin/src/src/view_*.cpp` / `svgdevicecontext.cpp` no
   método da `origem provável` e espelhe em `verovio_dart/lib/src/`
   (cite `Mirrors`). Para divergência de functor de layout (não desenho),
   use o segundo par de ferramentas: `CppFixture.load('04x', ...)` +
   `.compare(fn:, field:, actual: (r) => ... byPath[r.path] ...)` com chave
       `cppPath()` — mesma disciplina, nunca chute o valor.
- **(e) SVG é só complemento.** Comparar `test/golden/cpp/<rel>.svg` vs `test/golden/dart/<rel>.svg`
    é **complemento visual opcional**, nunca substituto dos passos (a)–(b).
3. **Tentativa 1..4 (por teste):**
   a. Investigue causa **pelo fixture (obrigatório): `probe_diff` single →
      `fn/seq/path` + origem provável → registro C++ esperado × registro
      Dart obtido campo a campo** (leia também
      `test/golden/report/<fam>/<arq>.md` como contexto),
      corrija em `verovio_dart/lib/src/` espelhando `origin/src/` (cite `Mirrors`).
      Não toque `origin/src/`, não `dart format` em lib.
      **Se você não consegue citar `fn/seq/path` da tentativa, volte aos
      passos (a)–(b) da seção Fixtures — não edite no escuro.**
   b. **Foco single-test:** Rode **só** `dart run tool/compare_svg.dart test/corpus/<fam>/<arq>.mei` (both) repetidamente, ajustando código, até zerar a divergência do **alvo ativo** (estrutural OU numérico, não necessariamente os dois). Não rode --all ainda.
   c. **Só depois:** Rode verificação **geral** `compare_svg --all` (700s) → `erros_est_depois`, `erros_num_depois` + `dart analyze` + `dart test`.
   d. **Decisão sua:**
      - **Critério primário:** `erros_depois_do_alvo_ativo < erros_antes_do_alvo_ativo` **E** analyze/test não pioraram **E** nenhum arquivo piorou **no alvo ativo** (compare listas de limpos por arquivo do `tool/SVG_VALIDATION.md` antes/depois). Se verdadeiro: `git add -A && git commit -m "fix: svg <alvo> <antes>-><depois> [loop auto] <arq>" && git push origin main` → SUCESSO, encerre. (alvo ∈ {est, num}.)
      - **Tolerância ao alvo secundário:** o alvo secundário (numérico quando o alvo é estrutural, ou vice-versa) PODE subir como efeito colateral, desde que: (i) o alvo ativo melhorou, (ii) nenhuma regressão foi identificada no alvo ativo, (iii) analyze/test não pioraram. Se o alvo secundário regrediu mas a regressão não pode ser corrigida junto sem prejuízo do alvo ativo nesta iteração, documente no commit message (`sec: Yn→Yn+1`) e continue — não bloqueie o progresso do alvo ativo por causa de piora no secundário.
      - **Bloqueio por regressão no alvo ativo** (mesmo com teste isolado limpo, o geral piorou no alvo ativo) **OU** analyze/test piorou: **não descarte a mudança de imediato.** Compare o `tool/SVG_VALIDATION.md` antes/depois (lista de limpos por arquivo) **e os `test/golden/report/` correspondentes** para identificar exatamente **quais arquivos regrediram** no alvo ativo — estavam limpos no alvo e passaram a divergir. Investigue esse conjunto de regredidos **em conjunto** (eles costumam compartilhar a causa raiz com a correção que você acabou de aplicar — é um efeito colateral, não uma coincidência) e ajuste a correção para cobrir tanto o teste focado quanto os regredidos. Re-verifique o teste isolado (volta a b) e depois geral (c) — conta como próxima tentativa. Só recorra a `git reset --hard HEAD && git clean -fd` (desistir e reportar) se, esgotadas as 4 tentativas, a causa da regressão não puder ser isolada e corrigida junto com o teste focado.

Reporte: baseline geral (est X/621, num Y/621, alvo ativo), teste focado escolhido, cada tentativa (`fn/seq/path` do probe + origem provável + causa, correção, single-test alvo antes/depois, geral antes/depois no alvo ativo E secundário, regressões identificadas), decisão final, e — se commitou — novos totais X'/621, Y'/621 para o supervisor decidir o alvo da próxima iteração (estrutural se X' < 621; numérico se X' = 621 e Y' < 621; fim se X' = Y' = 621). Tentativa sem `fn/seq/path` = tentativa não investigada (explique por que o fixture não pôde ser extraído).
Workdir /home/mauricio/rust_projects/verovio-transpile (dart de verovio_dart/, cpp_probe da raiz).
