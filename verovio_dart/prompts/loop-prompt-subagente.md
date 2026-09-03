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
   `compare_svg --all`, 700s, do zero). Rode `dart analyze`/`dart test`
   normalmente (são rápidos — segundos e poucos minutos — e não têm um
   artefato persistido equivalente ao SVG_VALIDATION.md para reaproveitar
   com a mesma segurança).
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
   para inspeção visual. Use fixtures obrigatório C++
   (`cpp_probe/sync.sh → mkpatch → build → run --svg /tmp/probe.svg →
   diff vazio`, seed 12345) + Dart (`CppFixture`/`DrawRecorder`).
3. **Tentativa 1..4 (por teste):**
   a. Investigue causa (probe `fn/seq/path`, leia `test/golden/report/<fam>/<arq>.md`,
      compare `test/golden/cpp/<rel>.svg` vs `test/golden/dart/<rel>.svg` se preciso),
      corrija em `verovio_dart/lib/src/` espelhando `origin/src/` (cite `Mirrors`).
      Não toque `origin/src/`, não `dart format` em lib.
   b. **Foco single-test:** Rode **só** `dart run tool/compare_svg.dart test/corpus/<fam>/<arq>.mei` (both) repetidamente, ajustando código, até zerar a divergência do **alvo ativo** (estrutural OU numérico, não necessariamente os dois). Não rode --all ainda.
   c. **Só depois:** Rode verificação **geral** `compare_svg --all` (700s) → `erros_est_depois`, `erros_num_depois` + `dart analyze` + `dart test`.
   d. **Decisão sua:**
      - **Critério primário:** `erros_depois_do_alvo_ativo < erros_antes_do_alvo_ativo` **E** analyze/test não pioraram **E** nenhum arquivo piorou **no alvo ativo** (compare listas de limpos por arquivo do `tool/SVG_VALIDATION.md` antes/depois). Se verdadeiro: `git add -A && git commit -m "fix: svg <alvo> <antes>-><depois> [loop auto] <arq>" && git push origin main` → SUCESSO, encerre. (alvo ∈ {est, num}.)
      - **Tolerância ao alvo secundário:** o alvo secundário (numérico quando o alvo é estrutural, ou vice-versa) PODE subir como efeito colateral, desde que: (i) o alvo ativo melhorou, (ii) nenhuma regressão foi identificada no alvo ativo, (iii) analyze/test não pioraram. Se o alvo secundário regrediu mas a regressão não pode ser corrigida junto sem prejuízo do alvo ativo nesta iteração, documente no commit message (`sec: Yn→Yn+1`) e continue — não bloqueie o progresso do alvo ativo por causa de piora no secundário.
      - **Bloqueio por regressão no alvo ativo** (mesmo com teste isolado limpo, o geral piorou no alvo ativo) **OU** analyze/test piorou: **não descarte a mudança de imediato.** Compare o `tool/SVG_VALIDATION.md` antes/depois (lista de limpos por arquivo) **e os `test/golden/report/` correspondentes** para identificar exatamente **quais arquivos regrediram** no alvo ativo — estavam limpos no alvo e passaram a divergir. Investigue esse conjunto de regredidos **em conjunto** (eles costumam compartilhar a causa raiz com a correção que você acabou de aplicar — é um efeito colateral, não uma coincidência) e ajuste a correção para cobrir tanto o teste focado quanto os regredidos. Re-verifique o teste isolado (volta a b) e depois geral (c) — conta como próxima tentativa. Só recorra a `git reset --hard HEAD && git clean -fd` (desistir e reportar) se, esgotadas as 4 tentativas, a causa da regressão não puder ser isolada e corrigida junto com o teste focado.

Reporte: baseline geral (est X/621, num Y/621, alvo ativo), teste focado escolhido, cada tentativa (causa, correção, single-test alvo antes/depois, geral antes/depois no alvo ativo E secundário, regressões identificadas), decisão final, e — se commitou — novos totais X'/621, Y'/621 para o supervisor decidir o alvo da próxima iteração (estrutural se X' < 621; numérico se X' = 621 e Y' < 621; fim se X' = Y' = 621).
Workdir /home/mauricio/rust_projects/verovio-transpile (dart de verovio_dart/, cpp_probe da raiz).
