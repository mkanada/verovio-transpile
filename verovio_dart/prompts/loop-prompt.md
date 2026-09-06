# PROMPT LOOP — Fidelidade SVG (agente único, sem subagente)

Você é o agente do loop. Loop infinito até **zero divergência estrutural E zero divergência
numérica** no corpus. Você investiga, corrige, mede, decide e faz git — tudo na mesma sessão,
sem delegar a subagente.

> Este prompt não carrega números do estado do corpus — eles mudam a cada iteração. Todo número
> vem de um artefato gerado: `tool/SVG_VALIDATION.md`, `tool/DELTA_CLUSTERS.md`,
> `test/golden/report/`, `prompts/loop-diario.md`. Leia-os; não confie em placar escrito em prompt.
> Os poucos números que aparecem aqui descrevem a **árvore**, não o placar (quantas fixtures
> existem, quantos testes), vêm com data de medição e mudam devagar — se um deles parecer errado,
> remeça e corrija este arquivo.

## Placar

`tool/SVG_VALIDATION.md`, linhas 3-6:

```
linha 3  Estrutural: X/T limpos                       ← placar DISCRETO (arquivos, manchete)
linha 4  Numérico (eps=0.0): Y/T limpos               ← placar DISCRETO (arquivos, manchete)
linha 5  Divergências estruturais (total): S          ← placar CONTÍNUO (o que decide commit)
linha 6  Divergências numéricas (total): N            ← placar CONTÍNUO (o que decide commit)
```

**O placar discreto não decide nada.** Ele só se move quando um arquivo cruza de "alguma
divergência" para "nenhuma" — e um arquivo divergente típico carrega vários defeitos
independentes ao mesmo tempo, de classes de elemento diferentes. Uma correção que elimine
milhares de divergências sem terminar nenhum arquivo pontua **zero** nele, e o loop antigo, que
decidia por ele, mandava `git reset --hard` exatamente nesse caso. Use X e Y como manchete no
log; **decida por S e N.** **Seu sucesso é `N` cair (ou `S` cair, na trilha ESTRUTURAL). Não é
"um arquivo ficou limpo".**

**Critério de parada:** S = 0 **E** N = 0 (equivalentemente X = Y = T).

**Regressão por arquivo não bloqueia sozinha.** Um fix de causa compartilhada toca centenas de
arquivos; alguns pioram enquanto o total cai. O que bloqueia é o **total** subir — e, numa
iteração numérica, `S` subir.

## A cada iteração

### 1. Baseline (reaproveite, não remeça à toa)

Se (1) `git status --porcelain` está limpo, (2) `git rev-parse HEAD` = `git rev-parse origin/main`,
e (3) `tool/SVG_VALIDATION.md` traz as linhas 5-6 (relatórios antigos não têm), reaproveite S e N
do arquivo commitado. Senão rode `dart run tool/compare_svg.dart --all` (timeout 700s).

> ⚠️ `--all` regenera `test/golden/dart/**.svg` **e** `test/golden/report/**.md`. Os dois têm de
> andar juntos: o commit `9b3510ca` levou os reports e a mudança em `lib/` sem os dumps, e os dumps
> ficaram um commit de código atrás — o que envenena o `cluster_deltas`, que lê os dumps. Se você
> rodar `--all`, deixe os dois no working tree.

### 2. Escolha da trilha e do alvo

- **Trilha CAUSA (default).** Alvo = uma assinatura do topo de `tool/DELTA_CLUSTERS.md`
  (`dart run tool/cluster_deltas.dart`), que ranqueia por *quantos arquivos cada causa destrava*.
  É a trilha de maior rendimento: o topo do ranking é, por construção, a causa de maior alcance.
  Abra a assinatura com `--class=<nome>` e `--delta=<n>`: quais arquivos, quais deltas, com que
  frequência. Um mesmo delta sob várias classes é **uma** coordenada errada a montante que todo o
  resto herdou — corrija a origem, não cada herdeiro.
  **Triagem antes de portar:** separe o subgrupo `±1` (cheiro de arredondamento `toInt()`/`~/` vs
  `(int)` do C++ — ex. `tie-001` bate a <1 unidade) do subgrupo sistemático (`-208`, `90`, `25` —
  âncora/geometria, ex. haste X/Y). O primeiro pede uma regra de conversão central; o segundo pede
  porte de função. Não porte motor para fechar `±1`.
- **Trilha BARATA.** Alvo = um arquivo da seção "Mais próximos do limpo" do `SVG_VALIDATION.md`.
  Serve para converter placar contínuo em discreto. Use quando as últimas 3 iterações foram CAUSA,
  ou quando a trilha CAUSA travou.
- **Trilha ESTRUTURAL.** Alvo = seção "Top divergências estruturais" do `SVG_VALIDATION.md`. Aqui o
  alvo é `S`. Recomendada ~1 vez a cada 6 iterações numéricas (ou quando `S` subir). Prioridade é o
  numérico: o `S` residual está concentrado em poucas famílias e o critério de parada precisa dele,
  mas interromper o rendimento numérico em ritmo fixo custa mais do que rende — não deixe o
  estrutural morrer de fome, mas não o force.

**Nunca escolha alvo pela "primeira divergência" nem pelo "maior desvio".** A pauta é desenhada
antes de tudo em cada compasso, então a primeira divergência é sistematicamente o sintoma mais a
jusante: a maior parte do corpus aponta para a linha de pauta ou do sistema, que é consequência do
espaçamento, não causa (a tabela "Onde cai a primeira divergência" do `DELTA_CLUSTERS.md` mostra a
distribuição atual — ela existe para tornar esse mascaramento visível). E "maior desvio" ranqueia
por dificuldade, mandando você para o pior arquivo do corpus primeiro.

**Ordem de dependência (respeite ou trabalhe em cima de fundação torta).** Geometria é uma cadeia:
**página/sistema Y → pauta Y → espaçamento X do compasso → X do elemento → haste → beam →
ligadura/tie → articulação**. Uma nota no X errado torna erradas todas as coordenadas de beam e
slur que dependem dela, por mais correto que esteja o código de beam. Se o alvo escolhido está a
jusante de uma assinatura ainda aberta em `staff`/`notehead`/`barLine`, **suba para a montante
primeiro** e registre a troca no diário.

### 3. Investigação — fixtures C++ × Dart

**Proibido editar `lib/src/` por palpite.** O pinpointing é `fn/seq/path` do probe, nunca "parece
que é o X". Sem `fn/seq/path`, a tentativa não conta como investigada.

- **Lado C++, nível de desenho (05-38):** fixture JSONL em
  `test/fixtures/cpp/05-38/<fam>/<arq>.mei.jsonl`. **442 dos 621 arquivos do corpus já têm
  (medido 2026-09-05) — confira antes de gerar.** Cobrem o stream de desenho, que resolve a maioria
  das divergências de coordenada. Para gerar o que faltar, **use o script, não o `run.sh` na mão**:
  `tool/gen_probe_fixtures.sh <fam>` (de `verovio_dart/`) roda a família inteira e **aborta no
  primeiro arquivo cujo SVG instrumentado divergir do limpo** — a prova de não-regressão de
  `cpp_probe/README.md` (regras 1-3) já vem embutida. Ele fixa `TASK=05-38` porque é esse o nível
  que o `probe_diff.dart` lê.
- **Suba para o nível DEEP só quando precisar de valor de functor de layout** (`drawingXRel`,
  spacing, cast-off) — isto é, quando o fixture de desenho mostrar que os dois lados desenham o
  mesmo objeto em lugares diferentes e a causa está a montante do desenho.
  `DEEP=$(grep -v '^#' cpp_probe/patches/ORDER | grep -v '^$' | tail -n 1)` (era `05-42` em
  2026-09-06), então `cpp_probe/build.sh $DEEP` (1 build por iteração) e
  `cpp_probe/run.sh $DEEP test/corpus/<fam>/<arq>.mei verovio_dart/test/fixtures/cpp/$DEEP/<fam>/<arq>.mei.jsonl --svg /tmp/probe.svg`.
  **Grave sob `$DEEP`, nunca dentro de `05-38`**: a pilha de patches é cumulativa, então o binário
  DEEP também emite os registros de desenho, e despejá-los no diretório 05-38 mistura dois níveis
  numa árvore que o `probe_diff` trata como sendo só de desenho. O fixture DEEP você lê direto
  (`test/fixtures/cpp_fixture.dart`), não pelo `probe_diff`.
  Prova de não-regressão obrigatória (o `run.sh` na mão não a faz por você):
  `build/verovio -r verovio_dart/assets/data -x 12345 -o /tmp/limpo.svg test/corpus/<fam>/<arq>.mei && diff /tmp/limpo.svg /tmp/probe.svg`
  — **diff vazio**, senão o fixture está corrompido (`cpp_probe/README.md`, regras 1-3).
- **Comparador pronto:** `dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei` alinha os dois
  fluxos por `seq`+`path` e cospe `fn`, `seq`, `path`, esperado × obtido (Δ) e `origem provável:
  View::...`. `--dir=test/corpus --rank` agrupa as **primeiras** divergências por `(fn, origem)`.
  Complementa o `cluster_deltas`: o rank diz **onde nasce**, o cluster diz **quanto vale**. Para
  mismatch de contagem de filhos (não de número), use diff estrutural direto golden×dart — o
  `probe_diff` não reporta essa classe.
- **Depois** abra `origin/src/src/view_*.cpp` / `svgdevicecontext.cpp` no método da origem provável
  e espelhe em `lib/src/` (cite `Mirrors`). Não toque `origin/src/`, não `dart format` em `lib/`.
- **Antes de concluir "o C++ desenha e o Dart não", cheque regressão de tipagem.**
  O loop de tipagem zerou `lib/src/rendering/` em 2026-09-06 (`D=0`: zero `_dyn(...)` vivo, zero
  `catch` real). Se um `grep -n '_dyn(\|catch' <arquivo>` achar um par vivo em volta do trecho
  suspeito, trate como **regressão**: tipe o membro, cite no diário — não alargue o catch.
- Leia `prompts/loop-diario.md` antes da tentativa 1. Regra geral falseável que o diário já provou:
  toda lógica "decide uma vez, guarda no objeto" portada de um functor C++ tem de ser conferida
  contra `resetfunctor.cpp` — uma função de decisão correta não basta se nada manda ela rodar de
  novo a cada passada.

### 4. Ciclo (até 10 tentativas)

1. Investigue pelo fixture → `fn/seq/path` + origem provável → registro C++ × registro Dart campo
   a campo. Corrija espelhando o C++.
2. **Verificação barata, a cada tentativa:** rode `dart run tool/compare_svg.dart test/corpus/<fam>`
   (uma família, segundos) nas famílias que a assinatura mais afeta — o `cluster_deltas --class=`
   lista quais. Itere aqui. **Não** rode `--all` a cada tentativa. Com caminho posicional o tool
   **não** escreve relatório (só com `--all`, sem argumento, ou com `--report=` explícito), então
   essas rodadas não sujam o `SVG_VALIDATION.md` que serve de baseline — leia S/N da saída no
   console.
3. **Diário de observações.** Toda tentativa encerrada — sucesso ou falha — deixa ao menos uma
   `OBS-k` dizendo *o que este resultado ensinou que você não sabia antes de tentar*
   (ex.: `OBS-3: radius igual nos dois lados ⇒ causa não está em DrawDiamond, está no
   drawingNextElement a montante`). A tentativa seguinte abre citando: `constrói sobre OBS-k` ou
   `descarta OBS-k porque …`. O diário é o payload mais valioso da iteração quando não há fix.

### 5. Verificação final (uma vez, no fim)

Rode em primeiro plano, bloqueando até o fim (timeout até 600000ms por chamada — suficiente para
os ~700s do `--all`):

1. `dart run tool/compare_svg.dart --all` → S/N depois.
2. `dart run tool/cluster_deltas.dart` — relê os dumps recém-escritos e deixa o ranking coerente
   com o código para a próxima iteração.
3. `dart analyze` (tem de voltar a 0 issues) e `dart test` (~3 min). A suíte está **verde** — 701
   testes, medido em 2026-09-05 (os testes de layout cronicamente vermelhos foram removidos em
   2026-09-04, por decisão de foco no SVG). Qualquer falha nova é sua e **bloqueia** — anote a
   contagem de passes/falhas, não "passou/não passou". Se algum dia voltar a haver falha crônica,
   não presuma o baseline: meça o do HEAD num worktree limpo (`git worktree add <tmp> HEAD`) antes
   de julgar "piorou".

### 6. Diário primeiro — antes de qualquer decisão de git

Anexe o Diário de observações em `verovio_dart/prompts/loop-diario.md` (formato: `## <data> —
trilha <CAUSA|BARATA|ESTRUTURAL> — alvo <assinatura ou arquivo>`, linha `S <antes>→<depois>
N <antes>→<depois> — <COMMIT|RESTORE>`, lista `OBS-1..N`) e comite-o *sozinho*:
`git add verovio_dart/prompts/loop-diario.md && git commit -m "docs: diario loop <alvo>"`.
Faça isso **mesmo (principalmente) quando for descartar o código** — um beco-sem-saída
documentado vale a iteração; um beco-sem-saída esquecido faz a próxima iteração repeti-lo. Quando
a decisão for COMMIT, pode incluir o diário no mesmo `git add -A` — a separação em dois commits
existe para proteger contra descarte, não é um ritual em si.

### 7. Decisão de commit

- **Trilha CAUSA ou BARATA:** commite se `N_depois < N_antes` **E** `S_depois <= S_antes` **E**
  analyze/test não pioraram.
- **Trilha ESTRUTURAL:** commite se `S_depois < S_antes` **E** analyze/test não pioraram. N pode
  subir como efeito colateral — anote `sec: N→N'` na mensagem.
- Nenhuma trilha exige que algum arquivo fique inteiramente limpo. Se X ou Y subirem, ótimo,
  mencione — mas não é condição.
- **Exceção de porte fiel (única exceção à catraca).** Um porte que *sobe* o placar ainda pode ser
  commitado quando você prova as três coisas: (a) é porte linha-a-linha de uma função do C++, com
  `arquivo.cpp:linha` citado, e não um ajuste inventado para o placar; (b) a alta é cascata a
  jusante — a correção local está certa e o resíduo que ela expõe está em outro lugar da cadeia
  (você nomeia onde); (c) a cascata está descrita numa OBS do diário. A catraca continua sendo o
  default: sem as três provas, é RESTORE. Quando usar a exceção, marque a mensagem com `cascata:`
  em vez de `S ...→... N ...→...`, para a exceção ficar auditável no histórico. Precedentes:
  `ae51af95` (`Slur::CalcEndPoints`, N 27714→27741) e `1d6d1f08` (motor de beam, S 43→44).
- **Restaure quando:** o total subiu sem as três provas; `S` subiu numa trilha numérica; `dart test`
  ganhou falha; `Falhas (exceção durante renderização)` > 0. Sem exceção para falhas.

### 8. Git

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
  seguido de `git stash drop` — reverte a tentativa **preservando as fixtures C++**, que são dados
  extraídos do binário instrumentado e continuam válidos independentemente do código tentado. Sem o
  `:(exclude)` o restore joga fora horas de `gen_probe_fixtures.sh` junto com o patch descartado.
  Fora dessas pastas nada é tocado, então patches de instrumentação sobrevivem. **Nunca rode
  `git clean -fd`**: é o comando que apagaria instrumentação untracked ainda não incorporada ao
  `cpp_probe/patches/ORDER`.

### 9. Logue a próxima

Trilha, alvo, S/N antes→depois, X/Y, commit ou restore com motivo — e volte ao passo 1.

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de `verovio_dart/`, cpp_probe da raiz).

> **Loop de tipagem encerrado em 2026-09-06 (`D=0`, ver `tool/TYPE_DEBT.md`).** Os prompts
> `loop-tipagem-prompt-*.md` ficam como histórico (só cabeçalho); não há mais alternância entre
> loops — este é o único loop ativo.
