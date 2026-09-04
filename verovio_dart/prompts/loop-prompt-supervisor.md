# PROMPT SUPERVISOR — Loop Infinito (delegação)

Você é o Supervisor. Loop infinito até `0` erro estrutural **E** `0` erro numérico (linhas 3 e 4 de `tool/SVG_VALIDATION.md`: "Estrutural: X/621 limpos" e "Numérico (eps=0.0): Y/621 limpos"). O loop só termina quando X = 621 **E** Y = 621.

**Prioridade por arquivo (não hierarquia global absoluta):**
- Arquivo **só-numérico** = estruturalmente limpo MAS numericamente divergente → **alvo efetivo numérico, COM PRIORIDADE** sobre arquivos com erro estrutural.
- Arquivo **com-erro-estrutural** = diverge no estrutural (independente do numérico) → alvo efetivo estrutural.
- Ou seja: a análise numérica tem prioridade, **mas apenas se o SVG tiver erros APENAS numéricos**. Nunca se ataca numérico num arquivo que ainda tem erro estrutural — ali o alvo continua sendo o estrutural.

A cada iteração:
1. Dispare 1 subagente com o prompt em `prompts/loop-prompt-subagente.md`.
2. Aguarde (subagente leva ~20-50min: 2× compare_svg --all 10min + foco single-test + fix). O subagente NÃO commita nem pusha — ele deixa o working tree pronto e reporta (com `alvo_efetivo` ∈ {est, num} e tipo do arquivo focado).
3. Verificação e git (sua responsabilidade, não do subagente): confira o reporte (baseline X/Y, alvo efetivo, tipo do arquivo, teste focado, `erros_depois` vs `erros_antes` **no alvo efetivo**, listas de limpos antes/depois em `tool/SVG_VALIDATION.md`, `dart analyze` + `dart test`).
   - Se `alvo_efetivo = num`: commit **somente se** `erros_num_depois < erros_num_antes` E **zero regressões numéricas** (nenhum arquivo num-limpo passou a divergir) E **zero regressões estruturais** (nenhum arquivo est-limpo passou a divergir) E analyze/test não pioraram.
   - Se `alvo_efetivo = est`: commit **somente se** `erros_est_depois < erros_est_antes` E zero regressões estruturais E analyze/test não pioraram (o numérico PODE regredir como efeito colateral — acrescente `sec: Yn→Yn+1` na mensagem).
   - Se condição satisfeita: `git add -A && git commit -m "fix: svg <alvo_efetivo> <antes>-><depois> [loop auto] <arq>" && git push origin main`. Caso contrário: `git reset --hard HEAD && git clean -fd` (restore) e logue o motivo (qual condição falhou, quais arquivos regrediram).
4. Logue resultado (baseline estrutural e numérico, alvo efetivo, tipo do arquivo, teste focado, delta geral estrutural e numérico, commit ou restore) e dispare próxima iteração.
5. **Critério de parada**: encerre o loop quando, ao logar o resultado da iteração, o relatório do HEAD recém-commitado mostrar X = 621 (estrutural) **E** Y = 621 (numérico). Escolha da próxima iteração (preferência, não exclusão): se existe arquivo só-numérico, a próxima iteração é numérica com prioridade; senão, estrutural; se X = 621, resta só numérico; se ambos = 621, fim.

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de verovio_dart/, cpp_probe da raiz).
