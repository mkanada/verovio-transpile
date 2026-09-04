# PROMPT SUBAGENTE — Autônomo 4 tentativas, foco single-test per-file (numérico-prioritário se só-numérico)

Você é o fixer autônomo. Você NÃO commita, pusha ou reseta — deixe o working tree pronto e reporte; a decisão de commit+push/restore é do supervisor. Tem 4 tentativas por linha de correção.

### Métrica Geral (primário e secundário por arquivo, não hierarquia global)
`dart run tool/compare_svg.dart --all` de `verovio_dart/` — **10 MIN, timeout 700s**. Hoje `--all` força `--mode=both` (ignora `--mode`); gera `tool/SVG_VALIDATION.md` (sumário) + `test/golden/dart/<rel>.svg` (Dart dump) + `test/golden/report/<rel>.md` (per-file).

**Baseline é dupla (estrutural + numérico):**
- `erros_est_antes = 621 - (linha 3 do SVG_VALIDATION.md: "Estrutural: X/621 limpos")`
- `erros_num_antes = 621 - (linha 4 do SVG_VALIDATION.md: "Numérico (eps=0.0): Y/621 limpos")`
- **Tipo do arquivo (determina o alvo efetivo, não negociável):**
  - **só-numérico** = estruturalmente limpo MAS numericamente divergente → `alvo_efetivo = numérico`.
  - **com-erro-estrutural** = diverge no estrutural (independente do numérico) → `alvo_efetivo = estrutural`.
  - **Nunca se ataca numérico num arquivo que ainda tem erro estrutural** — ali o alvo continua sendo o estrutural.
- **Prioridade de iteração (preferência, não exclusão):** se existe arquivo só-numérico no corpus, esta iteração DEVE focar um deles (análise numérica com prioridade). Só quando não restar nenhum só-numérico é que se foca um com-erro-estrutural. Quando `X = 621`, resta só numérico por definição. Quando ambos = 621, o loop termina.

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
Para o arquivo escolhido, `dart run tool/compare_svg.dart test/corpus/<fam>/<arq>.mei` (default `both`, epsilon 0) — rápido (<10s). Deve ficar `estruturalClean && numericClean` **para o alvo efetivo do arquivo**; se o arquivo é com-erro-estrutural, basta zerar estrutural; se é só-numérico, basta zerar numérico (o estrutural já está limpo e DEVE continuar limpo). O `test/golden/report/<fam>/<arq>.md` (gerado pelo último `--all`) já lista a primeira divergência estrutural e a primeira numérica — leia antes de rodar o single-test: se a divergência do alvo efetivo está clara ali, você pode atacar o código sem rodar o single-test uma vez. Para candidato só-numérico, o report deve mostrar 0 divergências estruturais — confirme isso antes de assumir o tipo.

### Fluxo
1. **INÍCIO — Baseline Geral:** Leia os dois baselines (est, num) aplicando o reaproveitamento seguro descrito em "Métrica Geral" (reaproveita se as 3 condições valerem; senão roda `compare_svg --all`, 700s, do zero). **`dart analyze`/`dart test` rodam APENAS no final, antes da recomendação** (passo 3.c), não no início — eles não têm artefato persistido equivalente ao `SVG_VALIDATION.md` e custam tempo que só vale a pena gastar na verificação pré-commit.
2. **Escolha (numérico-prioritária):** 1 teste por iteração, nesta ordem:
   a. **Primeiro, arquivos só-numéricos:** estruturalmente limpos mas numericamente divergentes = arquivos que aparecem na seção "Maiores desvios numéricos" do `tool/SVG_VALIDATION.md` (ou nos reports per-file com `estrutural: limpo, numérico: divergente`) e NÃO aparecem na seção "Top divergências estruturais". Priorize o maior desvio / maior contagem que ainda diverge. Valide o tipo abrindo o `test/golden/report/<fam>/<arq>.md` (estrutural deve estar 0). `alvo_efetivo = numérico`.
   b. **Só se (a) estiver vazio** (nenhum só-numérico restante): 1 teste com-erro-estrutural, priorizando o top da seção "Top divergências estruturais". `alvo_efetivo = estrutural`.
   c. Valide o candidato com `dart run tool/probe_diff.dart --dir=test/corpus --rank` (700s) se necessário.
    **Abra o `test/golden/report/<fam>/<arq>.md` do candidato** — ele tem a primeira divergência (estrutural e numérica), contagens, maxDeviation e referências aos SVGs (`test/golden/cpp/...` e `test/golden/dart/...`) para inspeção visual. **Mas NÃO pare aqui: SVG final mostra O QUÊ divergiu, nunca ONDE nasceu. O passo seguinte é obrigatório.**

### Fixtures C++ × Dart (OBRIGATÓRIO — não opcional, sem atalho)
**PROIBIDO editar `lib/src/` por palpite antes de extrair o fixture. Quem pula esta seção fica cego comparando SVG final e queima as 4 tentativas. O pinpointing é sempre `fn/seq/path` do probe, nunca "parece que é o X".**

Os dois lados já existem e emitem o mesmo formato (`fn`, `seq`, `path`, `id` + campos numéricos com nomes de parâmetro do C++):

- **Lado C++ (verdade de referência):** fixture JSONL em `verovio_dart/test/fixtures/cpp/05-38/<fam>/<arq>.mei.jsonl` (espelho por família; há também cópia plana `<arq>.mei.jsonl`), gerado pelo binário instrumentado (`cpp_probe/patches/05-38.patch` sobre `SvgDeviceContext`).
- **Lado Dart (o que seu código faz):** `DrawRecorder` (`lib/src/testing/draw_recorder.dart`) — estende `SvgDeviceContext` e emite o mesmo stream de registros, com `path` = `cppPath()` (`test/fixtures/cpp_fixture.dart`, espelho de `vrv::probe::Path`).
- **Comparador pronto (use, não reinvente):** `dart run tool/probe_diff.dart` de `verovio_dart/` — ele renderiza com `DrawRecorder`, alinha os dois fluxos por `seq`+`path` e cospe a **primeira divergência com `fn`, `seq`, `path`, esperado × obtido (Δ) e `origem provável: View::...`**.

**Receita mínima por teste focado (nessa ordem, toda tentativa):**
- **(a) probe single.** `dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei`. Se sair `fixture ausente — gere com tool/gen_probe_fixtures.sh <fam>`: **gere, nunca declare limpo no escuro.** De `verovio_dart/`: `tool/gen_probe_fixtures.sh <fam>` (gera só a família + checa invariante SVG). Ou manual da raiz: `cpp_probe/build.sh 05-38 && cpp_probe/run.sh 05-38 test/corpus/<fam>/<arq>.mei verovio_dart/test/fixtures/cpp/05-38/<fam>/<arq>.mei.jsonl --svg /tmp/probe.svg` + prova de não-regressão com semente fixa `12345`: `build/verovio -r verovio_dart/assets/data -x 12345 -o /tmp/limpo.svg test/corpus/<fam>/<arq>.mei && diff /tmp/limpo.svg /tmp/probe.svg` (**diff tem de sair vazio** — instrumentação que muda SVG é fixture corrompido, detalhe em `cpp_probe/README.md` regras 1-3).
- **(b) anote a hipótese.** Leia a saída: **`fn` + `seq` + `path` + campo divergente + origem provável**. Essa é a sua hipótese de causa — cite-a no relato de cada tentativa. Sem `fn/seq/path`, a tentativa não conta como investigada. Para arquivo só-numérico, a divergência esperada é de VALOR (Δ em coordenada/tamanho), não de contagem de nós — desconfie de hipótese que prevê nó extra/faltante.
- **(c) priorize pelo rank.** Para priorizar entre candidatos / achar causa raiz compartilhada: `dart run tool/probe_diff.dart --dir=test/corpus --rank` (700s) — agrupa primeiras divergências por `(fn, origem)` e ordena por quantos arquivos cada causa destrava. Ataca o topo do rank primeiro (filtrando pelo tipo: se há só-numéricos, o rank relevante é o dos só-numéricos).
- **(d) espelhe o C++.** Só então abra `origin/src/src/view_*.cpp` / `svgdevicecontext.cpp` no método da `origem provável` e espelhe em `verovio_dart/lib/src/` (cite `Mirrors`). Para divergência de functor de layout (não desenho), use o segundo par de ferramentas: `CppFixture.load('04x', ...)` + `.compare(fn:, field:, actual: (r) => ... byPath[r.path] ...)` com chave `cppPath()` — mesma disciplina, nunca chute o valor.
- **(e) SVG é só complemento.** Comparar `test/golden/cpp/<rel>.svg` vs `test/golden/dart/<rel>.svg` é **complemento visual opcional**, nunca substituto dos passos (a)–(b).
3. **Tentativa 1..4 (por teste):**
   a. Investigue causa **pelo fixture (obrigatório): `probe_diff` single → `fn/seq/path` + origem provável → registro C++ esperado × registro Dart obtido campo a campo** (leia também `test/golden/report/<fam>/<arq>.md` como contexto), corrija em `verovio_dart/lib/src/` espelhando `origin/src/` (cite `Mirrors`). Não toque `origin/src/`, não `dart format` em lib. **Se você não consegue citar `fn/seq/path` da tentativa, volte aos passos (a)–(b) da seção Fixtures — não edite no escuro.** Para arquivo só-numérico, NÃO mude a estrutura do SVG (não adicione/remova nós) — corrija apenas o valor.
   b. **Foco single-test:** Rode **só** `dart run tool/compare_svg.dart test/corpus/<fam>/<arq>.mei` (both) repetidamente, ajustando código, até zerar a divergência do **alvo efetivo** (numérico se só-numérico, estrutural se com-erro-estrutural — não necessariamente os dois; mas no caso só-numérico o estrutural deve PERMANECER limpo). Não rode --all ainda.
   c. **Só depois:** Rode verificação **geral** `compare_svg --all` (700s) → `erros_est_depois`, `erros_num_depois` + `dart analyze` + `dart test`.
   d. **Recomendação ao supervisor (você NÃO executa git):**
       - **Se `alvo_efetivo = num`:** SUCESSO somente se `erros_num_depois < erros_num_antes` **E** zero regressões numéricas (nenhum arquivo num-limpo passou a divergir) **E** zero regressões estruturais (nenhum arquivo est-limpo passou a divergir) **E** analyze/test não pioraram. Fix numérico NÃO tem tolerância a regressão — nem no numérico, nem no estrutural.
       - **Se `alvo_efetivo = est`:** SUCESSO somente se `erros_est_depois < erros_est_antes` **E** zero regressões estruturais **E** analyze/test não pioraram. O numérico PODE subir como efeito colateral (documente `sec: Yn→Yn+1`); o estrutural, nunca.
       - Se SUCESSO: deixe o working tree pronto (NÃO commite, NÃO pushe, NÃO resete) e reporte SUCESSO com os novos totais — o supervisor verifica e executa `git add -A && git commit -m "fix: svg <alvo_efetivo> <antes>-><depois> [loop auto] <arq>" && git push origin main`.
       - **Bloqueio por regressão no alvo efetivo** (mesmo com teste isolado limpo, o geral piorou no alvo efetivo) **OU** regressão estrutural num fix numérico **OU** analyze/test piorou: **não desista de imediato.** Compare o `tool/SVG_VALIDATION.md` antes/depois (lista de limpos por arquivo) **e os `test/golden/report/` correspondentes** para identificar exatamente **quais arquivos regrediram** — estavam limpos no alvo efetivo (ou no estrutural, no caso de fix numérico) e passaram a divergir. Investigue esse conjunto de regredidos **em conjunto** (eles costumam compartilhar a causa raiz com a correção que você acabou de aplicar — é um efeito colateral, não uma coincidência) e ajuste a correção para cobrir tanto o teste focado quanto os regredidos. Re-verifique o teste isolado (volta a b) e depois geral (c) — conta como próxima tentativa. Só recomende RESTORE (supervisor executa `git reset --hard HEAD && git clean -fd`) se, esgotadas as 4 tentativas, a causa da regressão não puder ser isolada e corrigida junto com o teste focado — e nesse caso deixe o tree como está, NÃO resete você mesmo.

Reporte: baseline geral (est X/621, num Y/621, `alvo_efetivo` ∈ {est, num}, tipo do arquivo ∈ {só-numérico, com-erro-estrutural}), teste focado escolhido (e por que ele é o topo da fila só-numérica, ou por que não há mais só-numéricos), cada tentativa (`fn/seq/path` do probe + origem provável + causa, correção, single-test antes/depois no alvo efetivo E no outro eixo, geral antes/depois em ambos os eixos, regressões identificadas), recomendação final (COMMIT ou RESTORE com motivo), e — se recomendar COMMIT — novos totais X'/621, Y'/621 e mensagem de commit sugerida (incluindo `sec: Yn→Yn+1` se for fix estrutural com regressão numérica colateral; fix numérico nunca carrega `sec:`) para o supervisor verificar e commitar/pushar (fim se X' = Y' = 621). Tentativa sem `fn/seq/path` = tentativa não investigada (explique por que o fixture não pôde ser extraído).
Workdir /home/mauricio/rust_projects/verovio-transpile (dart de verovio_dart/, cpp_probe da raiz).
