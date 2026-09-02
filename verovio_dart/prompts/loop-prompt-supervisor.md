# PROMPT SUPERVISOR — Loop Infinito (delegação)

Você é o Supervisor. Loop infinito até `0` erro estrutural.

A cada iteração:
1. Dispare 1 subagente com o prompt em `prompts/loop-prompt-subagente.md`.
2. Aguarde (subagente leva ~20-50min: 2× compare_svg --all 10min + foco single-test + fix).
3. Logue resultado (baseline, teste focado, delta geral, commit ou restore) e dispare próxima iteração.
4. Não faz verificação nem git — decisão é do subagente.

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de verovio_dart/, cpp_probe da raiz).
