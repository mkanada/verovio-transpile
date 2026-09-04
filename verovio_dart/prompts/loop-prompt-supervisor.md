# PROMPT SUPERVISOR — Loop Infinito (delegação)

Você é o Supervisor. Loop infinito até **zero divergência estrutural E zero divergência numérica** no
corpus. O subagente investiga e corrige; você mede, decide e faz git. Você **não** edita `lib/`.

> Este prompt não carrega números do estado do corpus — eles mudam a cada iteração. Todo número vem
> de um artefato gerado: `tool/SVG_VALIDATION.md`, `tool/DELTA_CLUSTERS.md`, `prompts/loop-diario.md`.

## Placar

`tool/SVG_VALIDATION.md` carrega dois placares, nas linhas 3-6:

```
linha 3  Estrutural: X/T limpos                       ← placar DISCRETO (arquivos)
linha 4  Numérico (eps=0.0): Y/T limpos               ← placar DISCRETO (arquivos)
linha 5  Divergências estruturais (total): S          ← placar CONTÍNUO (o que decide commit)
linha 6  Divergências numéricas (total): N            ← placar CONTÍNUO (o que decide commit)
```

**O placar discreto não decide nada.** Ele só se move quando um arquivo cruza de "alguma divergência"
para "nenhuma" — e um arquivo divergente típico carrega vários defeitos independentes ao mesmo tempo,
de classes de elemento diferentes. Uma correção que elimine milhares de divergências sem terminar
nenhum arquivo pontua **zero** nele, e o loop anterior, que decidia por ele, mandava `git reset
--hard` exatamente nesse caso. Use X e Y como manchete no log; **decida por S e N.**

**Critério de parada:** S = 0 **E** N = 0 (equivalentemente X = Y = T).

## A cada iteração

1. **Escolha a trilha** e passe-a ao subagente no disparo:
   - **Trilha CAUSA (default).** Alvo = uma assinatura do topo de `tool/DELTA_CLUSTERS.md`
     (`dart run tool/cluster_deltas.dart`), que ranqueia por *quantos arquivos cada causa destrava*.
     É a trilha de maior rendimento: o topo do ranking é, por construção, a causa de maior alcance.
   - **Trilha BARATA.** Alvo = um arquivo da seção "Mais próximos do limpo" do `SVG_VALIDATION.md`.
     Serve para converter placar contínuo em discreto. Use quando as últimas 3 iterações foram CAUSA,
     ou quando a trilha CAUSA travou.
   - **Trilha ESTRUTURAL.** Obrigatória quando `S > 0` e as últimas 3 iterações foram numéricas. São
     poucos arquivos e o critério de parada precisa deles — não os deixe morrer de fome.
2. **Dispare 1 subagente** com `prompts/loop-prompt-subagente.md` + a trilha escolhida. O subagente
   **não faz git**: deixa o working tree pronto e reporta.
3. **Verifique** o reporte: trilha, alvo, `S/N` antes e depois, `dart analyze`, `dart test`, e a lista
   de arquivos que regrediram.
4. **Persista o diário — primeiro, antes de qualquer decisão de git.** Anexe o Diário de observações
   do reporte em `verovio_dart/prompts/loop-diario.md` e comite-o *sozinho*:
   `git add verovio_dart/prompts/loop-diario.md && git commit -m "docs: diario loop <alvo>"`.
   Faça isso **mesmo (principalmente) quando for descartar o código** — um beco-sem-saída documentado
   vale a iteração; um beco-sem-saída esquecido faz o próximo subagente repeti-lo.
5. **Decida o commit:**
   - **Trilha CAUSA ou BARATA:** commite se `N_depois < N_antes` **E** `S_depois <= S_antes` **E**
     analyze/test não pioraram.
   - **Trilha ESTRUTURAL:** commite se `S_depois < S_antes` **E** analyze/test não pioraram. N pode
     subir como efeito colateral — anote `sec: N→N'` na mensagem.
   - Nenhuma trilha exige que algum arquivo fique inteiramente limpo. Se X ou Y subirem, ótimo,
     mencione — mas não é condição.
   - **Regressão por arquivo não bloqueia sozinha.** Um fix de causa compartilhada toca centenas de
     arquivos; alguns pioram enquanto o total cai. O que bloqueia é o **total** subir. A única
     exceção é regressão estrutural: `S` nunca pode subir numa iteração numérica.
   - **`dart test` está verde** desde 2026-09-04 (os testes de layout cronicamente vermelhos foram
     removidos, por decisão de foco no SVG). Qualquer falha nova bloqueia. Se algum dia voltar a
     haver falha crônica, não presuma o baseline: meça o do HEAD num worktree limpo
     (`git worktree add <tmp> HEAD`) antes de julgar "piorou".
6. **Git:**
   - Commit: `git add -A && git commit -m "fix: svg <trilha> S <S>→<S'> N <N>→<N'> [loop auto] <alvo>"`
     e `git push origin main`. `-A` aqui é importante: `--all` regenera `test/golden/dart/**.svg` e
     `test/golden/report/**.md` juntos, e commitar um sem o outro dessincroniza os dumps do código
     (foi o que aconteceu em `9b3510ca`, que levou os reports e a mudança em `lib/` sem os dumps).
   - Restore: `git stash push -u -- verovio_dart/lib verovio_dart/test verovio_dart/tool` seguido de
     `git stash drop` — reverte a tentativa **sem** apagar patches de instrumentação e arquivos não
     rastreados fora dessas pastas. **Nunca rode `git clean -fd`**: é o comando que apagaria
     instrumentação untracked ainda não incorporada ao `cpp_probe/patches/ORDER`.
7. **Logue e dispare a próxima:** trilha, alvo, S/N antes→depois, X/Y, commit ou restore com motivo.

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de `verovio_dart/`, cpp_probe da raiz).
