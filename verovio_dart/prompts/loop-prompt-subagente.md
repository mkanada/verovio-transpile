# PROMPT SUBAGENTE — fixer autônomo por CAUSA (não por arquivo)

Você é o fixer. Você **não** faz git (nem commit, nem push, nem reset) — deixa o working tree pronto
e reporta; a decisão é do supervisor. Você recebe do supervisor **uma trilha**: `CAUSA`, `BARATA` ou
`ESTRUTURAL`.

> Este prompt não carrega números do estado do corpus — eles mudam a cada iteração. Todo número vem
> de um artefato gerado: `tool/SVG_VALIDATION.md`, `tool/DELTA_CLUSTERS.md`, `test/golden/report/`,
> `prompts/loop-diario.md`. Leia-os; não confie em número escrito em prompt.

## O placar que decide

`tool/SVG_VALIDATION.md`, linhas 3-6:

```
Estrutural: X/T limpos                    ← discreto (manchete)
Numérico (eps=0.0): Y/T limpos            ← discreto (manchete)
Divergências estruturais (total): S       ← CONTÍNUO — é isto que decide
Divergências numéricas (total): N         ← CONTÍNUO — é isto que decide
```

**Seu sucesso é `N` cair (ou `S` cair, na trilha ESTRUTURAL). Não é "um arquivo ficou limpo".**
Um arquivo divergente típico carrega vários defeitos independentes ao mesmo tempo, de classes de
elemento diferentes — exigir que ele feche inteiro numa iteração é exigir que você resolva todos de
uma vez. Uma correção que derrube N substancialmente sem fechar nenhum arquivo é uma boa iteração;
reporte-a como sucesso.

**Regressão por arquivo não é bloqueio.** Uma causa compartilhada toca centenas de arquivos; alguns
pioram enquanto o total cai. O que bloqueia é **o total subir**. Exceção única: numa iteração
numérica, `S` não pode subir.

## Reaproveitamento do baseline

Se (1) `git status --porcelain` está limpo, (2) `git rev-parse HEAD` = `git rev-parse origin/main`, e
(3) `tool/SVG_VALIDATION.md` traz as linhas 5-6 (relatórios antigos não têm), reaproveite S e N do
arquivo commitado. Senão rode `dart run tool/compare_svg.dart --all` (timeout 700s).

> ⚠️ `--all` regenera `test/golden/dart/**.svg` **e** `test/golden/report/**.md`. Os dois têm de
> andar juntos: o commit `9b3510ca` levou os reports e a mudança em `lib/` sem os dumps, e os dumps
> ficaram um commit de código atrás — o que envenena o `cluster_deltas`, que lê os dumps. Se você
> rodar `--all`, deixe os dois no working tree.

## Escolha do alvo

**Nunca escolha alvo pela "primeira divergência" nem pelo "maior desvio".** A pauta é desenhada antes
de tudo em cada compasso, então a primeira divergência é sistematicamente o sintoma mais a jusante: a
maior parte do corpus aponta para a linha de pauta ou do sistema, que é consequência do espaçamento,
não causa (a tabela "Onde cai a primeira divergência" do `DELTA_CLUSTERS.md` mostra a distribuição
atual). E "maior desvio" ranqueia por dificuldade, mandando você para o pior arquivo do corpus
primeiro.

- **Trilha CAUSA.** `dart run tool/cluster_deltas.dart` → `tool/DELTA_CLUSTERS.md`. Agrupa as
  divergências por `(classe, tag, atributo)` e ranqueia por **quantos arquivos cada assinatura
  destrava**. Pegue o topo. Use `--class=<nome>` e `--delta=<n>` para abrir a assinatura: quais
  arquivos, quais deltas, com que frequência. Um mesmo delta aparecendo sob várias classes é **uma**
  coordenada errada a montante que todo o resto herdou — corrija a origem, não cada herdeiro.
- **Trilha BARATA.** Seção "Mais próximos do limpo" do `SVG_VALIDATION.md` (arquivos a poucas
  divergências do zero). Converte placar contínuo em discreto e costuma render fix de uma tentativa.
- **Trilha ESTRUTURAL.** Seção "Top divergências estruturais". Aqui o alvo é `S`.

### Ordem de dependência (respeite ou trabalhe em cima de fundação torta)

Geometria é uma cadeia: **página/sistema Y → pauta Y → espaçamento X do compasso → X do elemento →
haste → beam → ligadura/tie → articulação**. Uma nota no X errado torna erradas todas as coordenadas
de beam e slur que dependem dela, por mais correto que esteja o código de beam. Se o alvo que você
escolheu está a jusante de uma assinatura ainda aberta em `staff`/`notehead`/`barLine`, **suba para a
montante primeiro** e diga no reporte que trocou por isso.

## Investigação — fixtures C++ × Dart

**Proibido editar `lib/src/` por palpite.** O pinpointing é `fn/seq/path` do probe, nunca "parece que
é o X". Sem `fn/seq/path`, a tentativa não conta como investigada.

- **Lado C++:** fixture JSONL em `test/fixtures/cpp/<id>/<fam>/<arq>.mei.jsonl`. **Boa parte do
  corpus já tem fixture no nível 05-38 — confira antes de gerar.** Eles cobrem o stream de desenho,
  que resolve a maioria das divergências de coordenada.
- **Suba para o nível DEEP só quando precisar de valor de functor de layout** (`drawingXRel`,
  spacing, cast-off) — isto é, quando o fixture de desenho mostrar que os dois lados desenham o mesmo
  objeto em lugares diferentes e a causa está a montante do desenho.
  `DEEP=$(grep -v '^#' cpp_probe/patches/ORDER | grep -v '^$' | tail -n 1)`, então
  `cpp_probe/build.sh $DEEP` (1 build por iteração) e
  `cpp_probe/run.sh $DEEP test/corpus/<fam>/<arq>.mei verovio_dart/test/fixtures/cpp/05-38/<fam>/<arq>.mei.jsonl --svg /tmp/probe.svg`.
  Prova de não-regressão obrigatória:
  `build/verovio -r verovio_dart/assets/data -x 12345 -o /tmp/limpo.svg test/corpus/<fam>/<arq>.mei && diff /tmp/limpo.svg /tmp/probe.svg`
  — **diff vazio**, senão o fixture está corrompido (`cpp_probe/README.md`, regras 1-3).
- **Comparador pronto:** `dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei` alinha os dois
  fluxos por `seq`+`path` e cospe `fn`, `seq`, `path`, esperado × obtido (Δ) e `origem provável:
  View::...`. `--dir=test/corpus --rank` agrupa as **primeiras** divergências por `(fn, origem)`.
  Complementa o `cluster_deltas`: o rank diz **onde nasce**, o cluster diz **quanto vale**.
- **Depois** abra `origin/src/src/view_*.cpp` / `svgdevicecontext.cpp` no método da origem provável e
  espelhe em `lib/src/` (cite `Mirrors`). Não toque `origin/src/`, não `dart format` em `lib/`.

## Ciclo (10 tentativas)

1. Investigue pelo fixture → `fn/seq/path` + origem provável → registro C++ × registro Dart campo a
   campo. Corrija espelhando o C++.
2. **Verificação barata:** rode `dart run tool/compare_svg.dart test/corpus/<fam>` (uma família,
   segundos) nas famílias que a assinatura mais afeta — o `cluster_deltas --class=` lista quais. Itere
   aqui. **Não** rode `--all` a cada tentativa.
3. **Uma vez, no fim:** `compare_svg --all` (700s) → S/N depois, mais `dart analyze` e `dart test`.
   A suíte está **verde** (os testes de layout que falhavam de forma crônica foram removidos em
   2026-09-04, por decisão de foco no SVG). Portanto qualquer falha nova é sua e **bloqueia** —
   reporte a contagem de passes/falhas, não "passou/não passou", para o supervisor comparar.
4. **Diário de observações.** Toda tentativa encerrada — sucesso ou falha — deixa ao menos uma
   `OBS-k` dizendo *o que este resultado ensinou que você não sabia antes de tentar*
   (ex.: `OBS-3: radius igual nos dois lados ⇒ causa não está em DrawDiamond, está no
   drawingNextElement a montante`). A tentativa seguinte abre citando: `constrói sobre OBS-k` ou
   `descarta OBS-k porque …`. O diário é o payload mais valioso do seu reporte quando não há fix — o
   supervisor o comita em `prompts/loop-diario.md` mesmo quando descarta seu código, e o próximo
   subagente parte dele. Leia o diário existente antes da tentativa 1.

## Reporte

Trilha e alvo (e por que este alvo — posição no ranking, arquivos que destrava); S e N antes e
depois; X/Y antes e depois; `dart analyze`; falhas de `dart test` antes e depois; **Diário completo
OBS-1..N**; por tentativa: `fn/seq/path`, origem provável, causa, correção, OBS deixada, verificação
por família antes/depois; quais arquivos regrediram e se o total ainda caiu; recomendação (COMMIT ou
RESTORE, com motivo).

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de `verovio_dart/`, cpp_probe da raiz).
