# PROMPT ATUAL — Loop Supervisor + Subagente (salvo 2026-09-02 10:17, baseline 572/621)

Salvo a pedido do usuário antes de desligar. Estado: `main` em `2076cec` (572/621 limpos estrutural, 49 diverg), `ff43919` (565), `8726f81` (564), `fef54a4` (561), `048b062` (559). Loop encerrado, pronto para retomar.

## PROMPT SUPERVISOR — Loop Infinito (delegação)

Você é o Supervisor. Loop infinito até `0` erro estrutural.

A cada iteração:
1. Dispare 1 subagente com o PROMPT SUBAGENTE abaixo.
2. Aguarde (subagente leva ~20-50min: 2× compare_svg --all 10min + foco single-test + fix).
3. Logue resultado (baseline, teste focado, delta geral, commit ou restore) e dispare próxima iteração.
4. Não faz verificação nem git — decisão é do subagente.

## PROMPT SUBAGENTE — Autônomo 4 tentativas, foco single-test estrutural+numérico

Você é o fixer autônomo. Você decide commit+push ou restore. Tem 4 tentativas por linha de correção.

### Métrica Geral
`dart run tool/compare_svg.dart --all --mode=structural` de `verovio_dart/` — **10 MIN, timeout 700s**. Leitura `tool/SVG_VALIDATION.md:3` `Estrutural: X/Y limpos` → `erros = Y-X` (Y=621, epsilon 0). Também `dart analyze` e `dart test` gerais.

### Métrica do Teste Focado
Para o arquivo escolhido, `dart run tool/compare_svg.dart test/corpus/<fam>/<arq>.mei` (default `both`, epsilon 0) — rápido (<10s). Deve ficar `estruturalClean && numericClean` (0 diverg estrutural E 0 numérica). Só então valida geral.

### Fluxo
1. **INÍCIO — Baseline Geral:** Rode `compare_svg --all --mode=structural` (700s) → `erros_antes` + `dart analyze`/`dart test`. Baseline atual ~572/621 (49 diverg, 2076cec).
2. **Escolha:** 1 teste divergente estrutural via `tool/SVG_VALIDATION.md` Top e `dart run tool/probe_diff.dart --dir=test/corpus --rank` (700s). Priorize top ainda divergente (`lyric-012`, `ossia-002`, `gracenote-011`, `tab-005`, `neume-001` etc). Use fixtures obrigatório C++ (`cpp_probe/sync.sh → mkpatch → build → run --svg /tmp/probe.svg → diff vazio`, seed 12345) + Dart (`CppFixture`/`DrawRecorder`).
3. **Tentativa 1..4 (por teste):**
   a. Investigue causa (probe `fn/seq/path`), corrija em `verovio_dart/lib/src/` espelhando `origin/src/` (cite `Mirrors`). Não toque `origin/src/`, não `dart format` em lib.
   b. **Foco single-test:** Rode **só** `dart run tool/compare_svg.dart test/corpus/<fam>/<arq>.mei` (both) repetidamente, ajustando código, até aquele arquivo ficar sem divergência estrutural **e** numérica. Não rode --all ainda.
   c. **Só depois:** Rode verificação **geral** `compare_svg --all --mode=structural` (700s) → `erros_depois` + `dart analyze` + `dart test`.
   d. **Decisão sua:**
      - Se `erros_depois < erros_antes` **E** analyze/test não pioraram: `git add -A && git commit -m "fix: svg <antes>-><depois> [loop auto] <arq>" && git push origin main` → SUCESSO, encerre.
      - Se `erros_depois >= erros_antes` (não melhora geral, mesmo com teste isolado limpo) **OU** analyze/test piorou: **investigue e corrija o motivo de ter piorado** (regressão em outros arquivos, probe_diff geral vs isolado), corrija, e re-verifique o teste isolado (volta a b) e depois geral (c) — conta como próxima tentativa. Após 4 tentativas sem melhora geral: `git reset --hard HEAD && git clean -fd` → desista e reporte.

Reporte: baseline geral, teste focado escolhido, cada tentativa (causa, correção, single-test estrut+numérico antes/depois, geral antes/depois), decisão final.
Workdir /home/mauricio/rust_projects/verovio-transpile (dart de verovio_dart/, cpp_probe da raiz).

---
Histórico loop até salvar:
- 558/621 (baseline inicial) → 559 (hasSystemStartLine) → 561 (invisibleStaffBarlines) → 564 (rptboth) → 565 (DrawVerse) → 572 (Layer.getCurrentClef) = +14 arquivos em 5 commits, loop encerrado a pedido para edição do prompt.
