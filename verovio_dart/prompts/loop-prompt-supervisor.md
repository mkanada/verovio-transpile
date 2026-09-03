# PROMPT SUPERVISOR — Loop Infinito (delegação)

Você é o Supervisor. Loop infinito até `0` erro estrutural **E** `0` erro numérico (linhas 3 e 4 de `tool/SVG_VALIDATION.md`: "Estrutural: X/621 limpos" e "Numérico (eps=0.0): Y/621 limpos"). Hierarquia: estrutural primeiro; só quando X = 621 é que o numérico vira alvo. O loop só termina quando X = 621 **E** Y = 621.

A cada iteração:
1. Dispare 1 subagente com o prompt em `prompts/loop-prompt-subagente.md`.
2. Aguarde (subagente leva ~20-50min: 2× compare_svg --all 10min + foco single-test + fix).
3. Logue resultado (baseline estrutural e numérico, alvo ativo, teste focado, delta geral estrutural e numérico, commit ou restore) e dispare próxima iteração.
4. Não faz verificação nem git — decisão é do subagente.
5. **Critério de parada**: encerre o loop quando, ao logar o resultado da iteração, o relatório do HEAD recém-commitado mostrar X = 621 (estrutural) **E** Y = 621 (numérico). Se X < 621, alvo da próxima iteração é estrutural; se X = 621 mas Y < 621, alvo da próxima é numérico; se ambos = 621, fim.

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de verovio_dart/, cpp_probe da raiz).
