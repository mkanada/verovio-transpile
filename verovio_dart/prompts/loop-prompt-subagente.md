# PROMPT SUBAGENTE — Autônomo 4 tentativas, foco single-test estrutural+numérico

Você é o fixer autônomo. Você decide commit+push ou restore. Tem 4 tentativas por linha de correção.

### Métrica Geral
`dart run tool/compare_svg.dart --all --mode=structural` de `verovio_dart/` — **10 MIN, timeout 700s**. Leitura `tool/SVG_VALIDATION.md:3` `Estrutural: X/Y limpos` → `erros = Y-X` (Y=621, epsilon 0). Também `dart analyze` e `dart test` gerais.

**Reaproveitamento seguro (evita rodar 2x por ciclo bem-sucedido):** o
`tool/SVG_VALIDATION.md` já commitado no HEAD atual é a validação exata do
código nesse commit (ele é gerado e commitado junto com o fix, no mesmo
commit, pela iteração anterior). Antes de rodar `compare_svg --all` do
zero, verifique as 3 condições abaixo:
1. `git status --porcelain` está limpo (ignorando `tool/gen_ossia.dart`,
   não rastreado e não relacionado ao loop);
2. `git rev-parse HEAD` bate com `git rev-parse origin/main` (garante que
   nada foi commitado/pushado por fora nesse meio-tempo);
3. `tool/SVG_VALIDATION.md` no HEAD foi gerado com `modo: structural` e
   `epsilon: 0.0` (a mesma configuração que este fluxo usa).

Se as 3 valerem, **reaproveite** o `Estrutural: X/Y limpos` já escrito
nesse arquivo como `erros_antes` — não rode `compare_svg --all` de novo.
Se QUALQUER uma falhar (árvore suja, HEAD divergente de origin/main,
relatório em modo/epsilon diferente, ou arquivo ausente/corrompido), rode
`compare_svg --all --mode=structural` do zero — nunca confie num relatório
que não seja comprovadamente do HEAD exato e limpo atual.

### Métrica do Teste Focado
Para o arquivo escolhido, `dart run tool/compare_svg.dart test/corpus/<fam>/<arq>.mei` (default `both`, epsilon 0) — rápido (<10s). Deve ficar `estruturalClean && numericClean` (0 diverg estrutural E 0 numérica). Só então valida geral.

### Fluxo
1. **INÍCIO — Baseline Geral:** Obtenha `erros_antes` aplicando o
   reaproveitamento seguro descrito em "Métrica Geral" (reaproveita se as 3
   condições valerem; senão roda `compare_svg --all --mode=structural`,
   700s, do zero). Rode `dart analyze`/`dart test` normalmente (são
   rápidos — segundos e poucos minutos — e não têm um artefato persistido
   equivalente ao SVG_VALIDATION.md para reaproveitar com a mesma
   segurança).
2. **Escolha:** 1 teste divergente estrutural via `tool/SVG_VALIDATION.md` Top e `dart run tool/probe_diff.dart --dir=test/corpus --rank` (700s). Priorize top ainda divergente. Use fixtures obrigatório C++ (`cpp_probe/sync.sh → mkpatch → build → run --svg /tmp/probe.svg → diff vazio`, seed 12345) + Dart (`CppFixture`/`DrawRecorder`).
3. **Tentativa 1..4 (por teste):**
   a. Investigue causa (probe `fn/seq/path`), corrija em `verovio_dart/lib/src/` espelhando `origin/src/` (cite `Mirrors`). Não toque `origin/src/`, não `dart format` em lib.
   b. **Foco single-test:** Rode **só** `dart run tool/compare_svg.dart test/corpus/<fam>/<arq>.mei` (both) repetidamente, ajustando código, até aquele arquivo ficar sem divergência estrutural **e** numérica. Não rode --all ainda.
   c. **Só depois:** Rode verificação **geral** `compare_svg --all --mode=structural` (700s) → `erros_depois` + `dart analyze` + `dart test`.
   d. **Decisão sua:**
      - Se `erros_depois < erros_antes` **E** analyze/test não pioraram: `git add -A && git commit -m "fix: svg <antes>-><depois> [loop auto] <arq>" && git push origin main` → SUCESSO, encerre.
      - Se `erros_depois >= erros_antes` (não melhora geral, mesmo com teste isolado limpo) **OU** analyze/test piorou: **não descarte a mudança de imediato.** Compare o `tool/SVG_VALIDATION.md` antes/depois (lista de limpos por arquivo) para identificar exatamente **quais arquivos regrediram** — estavam estruturalmente limpos e passaram a divergir. Investigue esse conjunto de regredidos **em conjunto** (eles costumam compartilhar a causa raiz com a correção que você acabou de aplicar — é um efeito colateral, não uma coincidência) e ajuste a correção para cobrir tanto o teste focado quanto os regredidos. Re-verifique o teste isolado (volta a b) e depois geral (c) — conta como próxima tentativa. Só recorra a `git reset --hard HEAD && git clean -fd` (desistir e reportar) se, esgotadas as 4 tentativas, a causa da regressão não puder ser isolada e corrigida junto com o teste focado.

Reporte: baseline geral, teste focado escolhido, cada tentativa (causa, correção, single-test estrut+numérico antes/depois, geral antes/depois), decisão final.
Workdir /home/mauricio/rust_projects/verovio-transpile (dart de verovio_dart/, cpp_probe da raiz).
