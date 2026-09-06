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
    - **Trilha ESTRUTURAL.** Recomendada ~1 vez a cada 6 iterações numéricas (ou quando `S`
      subir). Prioridade é o numérico: `S=44` está concentrado em poucas famílias e o critério de
      parada precisa dele, mas interromper o rendimento numérico a cada 3 iterações custa mais do que
      rende — não deixe o estrutural morrer de fome, mas não o force em ritmo fixo.
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
     arquivos; alguns pioram enquanto o total cai. O que bloqueia é o **total** subir.
   - **Exceção de porte fiel (única exceção à catraca).** Um porte que *sobe* o placar ainda pode ser
     commitado quando o subagente prova as três coisas: (a) é porte linha-a-linha de uma função do
     C++, com `arquivo.cpp:linha` citado, e não um ajuste inventado para o placar; (b) a alta é
     cascata a jusante — a correção local está certa e o resíduo que ela expõe está em outro lugar da
     cadeia (o subagente nomeia onde); (c) a cascata está descrita numa OBS do diário. A catraca
     continua sendo o default: sem as três provas, é RESTORE. Quando usar a exceção, marque a
     mensagem com `cascata:` em vez de `S ...→... N ...→...`, para a exceção ficar auditável no
     histórico. Isto é o que a sessão manual de 2026-09-05 fez na prática em `ae51af95`
     (`Slur::CalcEndPoints`, N 27714→27741) e `1d6d1f08` (motor de beam, S 43→44), e o que a regra
     escrita da época mandava descartar.
   - **`dart test` está verde** — 701 testes, ~3 min, medido em 2026-09-05 (os testes de layout
     cronicamente vermelhos foram removidos em 2026-09-04, por decisão de foco no SVG). Qualquer
     falha nova bloqueia. Se algum dia voltar a haver falha crônica, não presuma o baseline: meça o
     do HEAD num worktree limpo (`git worktree add <tmp> HEAD`) antes de julgar "piorou".
6. **Git:**
   - **Antes de commitar, regenere o ranking:** `dart run tool/cluster_deltas.dart`. Ele lê os dumps
     que o `--all` acabou de reescrever; sem isso o `DELTA_CLUSTERS.md` commitado descreve o código
     do commit anterior e a próxima iteração escolhe alvo por um ranking morto. (Aconteceu: em
     `1695f718` os dumps mudaram e o ranking não foi refeito.)
   - Commit: `git add -A && git commit -m "fix: svg <trilha> S <S>→<S'> N <N>→<N'> [loop auto] <alvo>"`
     e `git push origin main`. `-A` aqui é importante: `--all` regenera `test/golden/dart/**.svg` e
     `test/golden/report/**.md` juntos, e commitar um sem o outro dessincroniza os dumps do código
     (foi o que aconteceu em `9b3510ca`, que levou os reports e a mudança em `lib/` sem os dumps).
     O `-A` também varre fixtures novas em `test/fixtures/cpp/05-38/` — isso é desejado (são dados de
     referência, valem por si), mas confira o tamanho antes de empurrar: a árvore já tem ~350 MB e
     **não** é LFS.
   - Restore:
     `git stash push -u -- verovio_dart/lib verovio_dart/tool verovio_dart/test ':(exclude)verovio_dart/test/fixtures'`
     seguido de `git stash drop` — reverte a tentativa **preservando as fixtures C++**, que são
     dados extraídos do binário instrumentado e continuam válidos independentemente do código que o
     subagente tentou. Sem o `:(exclude)` o restore joga fora horas de `gen_probe_fixtures.sh` junto
     com o patch descartado. Fora dessas pastas nada é tocado, então patches de instrumentação
     sobrevivem. **Nunca rode `git clean -fd`**: é o comando que apagaria instrumentação untracked
     ainda não incorporada ao `cpp_probe/patches/ORDER`.
7. **Logue e dispare a próxima:** trilha, alvo, S/N antes→depois, X/Y, commit ou restore com motivo.

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de `verovio_dart/`, cpp_probe da raiz).

> **Loop de tipagem encerrado em 2026-09-06 (`D=0`, ver `tool/TYPE_DEBT.md`).** Os prompts
> `loop-tipagem-prompt-*.md` ficam como histórico (só cabeçalho); não há mais alternância entre
> loops — este é o único loop ativo.
