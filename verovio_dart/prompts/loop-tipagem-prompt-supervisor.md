# PROMPT SUPERVISOR — Loop de Tipagem (delegação)

Você é o Supervisor deste loop. Objetivo: **zerar a dívida de tipagem de `lib/src/rendering/`** — a
lavagem de tipo (`_dyn(...)`, `as dynamic`, variável declarada `dynamic`) e os engolidores
silenciosos de exceção (`catch` que não relança nem loga). O subagente investiga e corrige; você
mede, decide e faz git. Você **não** edita `lib/`.

> Este prompt não carrega o placar — ele muda a cada iteração. Todo número de placar vem de um
> artefato gerado: `tool/TYPE_DEBT.md`, `tool/SVG_VALIDATION.md`, `prompts/loop-tipagem-diario.md`.
> Os poucos números aqui descrevem a árvore, vêm com data e mudam devagar.

## Por que este loop existe

`dart analyze` reporta **0 issues** e isso não significa nada sobre `lib/src/rendering/`. O padrão é
sempre o mesmo par casado:

```dart
try { algo = _dyn(objeto).membroQueTalvezNaoExista; } catch (e) { e.toString(); }
```

`_dyn` (declarado como `dynamic _dyn(dynamic o) => o;` em três arquivos) faz um membro inexistente
**compilar**; o `catch` faz ele **falhar em silêncio** em tempo de execução. O resultado é um ramo de
desenho que some sem rastro e reaparece como glifo ausente ou fora do lugar a centenas de linhas de
distância. Cada par desses é um defeito de fidelidade disfarçado de código defensivo.

A dívida já foi "paga" uma vez no papel: em 2026-08-29 havia 739 `as dynamic` e 820 `catch (_)` em
`rendering/`; hoje há **0** e **1**. Os dois viraram `_dyn(...)` e `catch (e) { e.toString(); }` — a
mesma coisa com outro nome, e nenhum dos dois gates do repositório (`verify_phases --fase=5`,
`debt_report.dart`) enxerga a grafia nova. **Renomear não conta como pagar.** Se uma iteração deste
loop derrubar o placar trocando uma grafia por outra, é RESTORE, sem discussão.

## Placar

`tool/TYPE_DEBT.md`, linhas 3-6 (gerado por `dart run tool/debt_report.dart`, ver Iteração 0):

```
linha 3  Lavagem de tipo (_dyn + as dynamic + declarações dynamic): A
linha 4  Engolidores silenciosos (catch sem rethrow nem log): B
linha 5  Supressões de erro de tipo: C
linha 6  Dívida total (D = A + B + C): D
```

**Critério de parada:** `D = 0` em `lib/src/rendering/`, com a suíte verde e o placar de SVG não
pior que o do início do loop.

Fora de escopo deste loop (não os persiga, não os conte): os 3 `as dynamic` restantes em `model/`
(`comparison.dart:319`, `interfaces/simple_interfaces.dart:160`, `doc.dart:1823`), o `catch (_)` de
`testing/svg_compare.dart:114`, e os 9 `// ignore:` de `rendering/`, que são `dead_code` e
`unused_field` deliberados e documentados (`view_mensural.dart:24`).

## As três invariantes de cada rodada

O usuário exigiu explicitamente: **toda rodada roda a suíte de testes e a renderização do corpus.**
Nenhuma das três é opcional, e a primeira não tem exceção nenhuma.

1. **`Falhas (exceção durante renderização)` de `tool/SVG_VALIDATION.md` continua `0`.** Este é o
   gate duro do loop. Tirar um `catch` que estava mascarando uma exceção real transforma um arquivo
   que renderizava (mal) num arquivo que estoura — e o placar de divergência nem vê isso, porque o
   arquivo deixa de produzir SVG. Falha nova ⇒ RESTORE, sem exceção de espécie alguma.
2. **`dart test` verde** — 701 testes, ~3 min (medido 2026-09-05). Qualquer falha nova bloqueia.
3. **`S` e `N` não pioram** (linhas 5-6 de `SVG_VALIDATION.md`). Vale aqui a mesma exceção de porte
   fiel do loop de fidelidade, e pela mesma razão — ver "Decida o commit".

## Iteração 0 — preparação (uma vez, antes da primeira rodada)

Dispare um subagente com `prompts/loop-tipagem-prompt-subagente.md` e a trilha `PREPARO`. Ele deve
entregar duas coisas, e só elas:

1. **`tool/debt_report.dart` enxergando a grafia atual.** Hoje ele conta só `as dynamic`,
   `catch (_)` e `ignore_for_file` — três padrões que quase não existem mais — e por isso reporta
   dívida quase zero sobre **894 pontos crus** de dívida real (censo de 2026-09-05 na entrada de
   abertura do diário: 324 `_dyn(...)` + 132 declarações `dynamic` + 438 `catch`). Estenda-o para contar `_dyn(`, declarações
   `dynamic`, e todo `catch` cujo corpo não relança nem loga, mantendo o recorte `--by-method` (é o
   que permite fatiar uma rodada) e o `--json`. Ele passa a escrever `tool/TYPE_DEBT.md` com as
   linhas 3-6 acima, no mesmo formato de `tool/SVG_VALIDATION.md`.
2. **O censo de catches vivos × mortos** (`prompts/loop-tipagem-diario.md`, entrada de abertura).
   Ler o código não diz se um `catch` chega a disparar. Instrumentar diz: reescreva mecanicamente
   cada corpo de `catch` para registrar `arquivo:linha`, renderize o corpus inteiro, colete, e
   **reverta a instrumentação** (`git diff --stat` vazio em `lib/` antes de reportar). O censo
   divide a dívida em duas populações de custo brutalmente diferente — os que nunca disparam saem em
   bloco; os que disparam são, cada um, um defeito de fidelidade a portar.

A Iteração 0 não muda `lib/`. Commite-a como `chore(tipagem): medidor + censo de catches`.

## A cada iteração

1. **Escolha a trilha** e passe-a ao subagente no disparo:
   - **Trilha MORTOS (primeira, enquanto houver).** Alvo = um lote de `catch` que o censo provou
     nunca dispararem em nenhum dos 621 arquivos do corpus. Saem em bloco, com o `try` junto. É a
     trilha de maior rendimento por unidade de risco — e a única em que um lote grande é aceitável.
   - **Trilha MEMBRO.** Alvo = **um membro de modelo faltante** que força `_dyn` em muitos pontos de
     chamada. Portar esse membro uma vez (do `origin/src/include/vrv/<classe>.h`) destrava todos os
     pontos de uma vez. É a trilha de maior alcance, análoga à trilha CAUSA do loop de fidelidade:
     ranqueie por *quantos pontos de chamada um único membro destrava*, não por arquivo.
   - **Trilha MÉTODO (default depois que MORTOS esgotar).** Alvo = **um** método de
     `debt_report --by-method`, tipado inteiro contra a função C++ correspondente. Um método por
     rodada. `view_control.dart` tem 4518 linhas: "limpar o arquivo" não é uma rodada, é um mês.
2. **Dispare 1 subagente** com `prompts/loop-tipagem-prompt-subagente.md` + a trilha escolhida. O
   subagente **não faz git**: deixa o working tree pronto e reporta.
3. **Verifique** o reporte: trilha, alvo, `D` antes e depois (com A/B/C separados), `Falhas`, `S/N`
   antes e depois, `dart analyze`, contagem de `dart test`, e — obrigatório — **a lista de membros
   de modelo que ele portou**, com o `.h` citado. Uma rodada que derruba `D` sem portar nada e sem
   apagar catch morto está trocando de grafia; peça a lista antes de commitar.
4. **Persista o diário — primeiro, antes de qualquer decisão de git.** Anexe o Diário do reporte em
   `verovio_dart/prompts/loop-tipagem-diario.md` e comite-o *sozinho*:
   `git add verovio_dart/prompts/loop-tipagem-diario.md && git commit -m "docs: diario tipagem <alvo>"`.
   Faça isso **mesmo (principalmente) quando for descartar o código**: o mapa de qual `catch` estava
   escondendo qual defeito é o ativo que este loop constrói, e ele sobrevive ao código descartado.
5. **Decida o commit:**
   - Commite se `D_depois < D_antes` **E** `Falhas = 0` **E** `dart test` não piorou **E**
     `S/N` não pioraram.
   - **`Falhas > 0` é RESTORE incondicional.** Não existe justificativa; um arquivo que deixou de
     renderizar é pior do que o `catch` que você tirou.
   - **Grafia nova é RESTORE.** Se o diff introduz qualquer forma nova de escapar do tipo — outro
     helper que devolve `dynamic`, `Object?` com cast tardio, `catch` que só atribui um fallback
     inventado — o placar caiu por fraude de medição. Rejeite e anote no diário para o medidor passar
     a contar aquela grafia também.
   - **Exceção de porte fiel** (a mesma do loop de fidelidade, pela mesma razão): tipar um membro
     corretamente pode *reativar* um ramo de desenho que estava sendo pulado, e o desenho novo, ainda
     que fiel, mexe no espaçamento a jusante e sobe `N`. Isso é commitável quando o subagente prova
     as três coisas: (a) o membro é porte linha-a-linha do C++, com `arquivo.h:linha` ou
     `arquivo.cpp:linha` citado; (b) a alta é cascata a jusante, e ele nomeia onde está o resíduo;
     (c) a cascata está escrita numa OBS. Marque a mensagem com `cascata:`. Sem as três, é RESTORE.
     Note que esta exceção **não** alcança a invariante 1: `Falhas` continua tendo de ser 0.
6. **Git:**
   - **Confira que a instrumentação do censo não vazou:**
     `git diff --cached | grep -i 'census\|__probe\|stderr.write'` antes de commitar. A
     instrumentação é temporária por construção; se ela entrar num commit, o próximo censo mede a si
     mesmo.
   - Commit: `git add -A && git commit -m "tipagem: <trilha> D <D>→<D'> [loop auto] <alvo>"` e
     `git push origin main`. O `-A` é necessário porque o `--all` regenera `test/golden/dart/**.svg`
     e `test/golden/report/**.md` juntos, e commitar um sem o outro dessincroniza os dumps do código
     (foi o que aconteceu em `9b3510ca`). Ele também varre fixtures novas em
     `test/fixtures/cpp/05-38/` — desejado, mas confira o tamanho: a árvore já tem ~350 MB e não é
     LFS.
   - Restore:
     `git stash push -u -- verovio_dart/lib verovio_dart/tool verovio_dart/test ':(exclude)verovio_dart/test/fixtures'`
     seguido de `git stash drop` — reverte a tentativa preservando as fixtures C++, que são dados
     extraídos do binário instrumentado e valem independentemente do código tentado. **Nunca rode
     `git clean -fd`**: apagaria instrumentação untracked ainda não incorporada ao
     `cpp_probe/patches/ORDER`.
7. **Logue e dispare a próxima:** trilha, alvo, D antes→depois (A/B/C), Falhas, S/N, commit ou
   restore com motivo.

## Convivência com o loop de fidelidade

Os dois loops editam os mesmos arquivos (`view_control.dart`, `view_element.dart`,
`view_mensural.dart`) e ambos regeneram `test/golden/dart/**` e commitam em `main`. **Não rode os
dois ao mesmo tempo** — o segundo a terminar sobrescreve os dumps do primeiro e os dois placares
passam a descrever árvores diferentes. Alterne por sessão, não por iteração.

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de `verovio_dart/`, cpp_probe da raiz).
