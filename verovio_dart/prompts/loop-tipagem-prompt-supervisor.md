# PROMPT SUPERVISOR — Loop de Tipagem (delegação)

Você é o Supervisor deste loop. Objetivo: **zerar a dívida de tipagem de `lib/src/rendering/`** — a
lavagem de tipo (`_dyn(...)`, `as dynamic`, variável declarada `dynamic`) e os engolidores
silenciosos de exceção (`catch` que não relança nem loga). O subagente investiga e corrige; você
mede, decide e faz git. Você **não** edita `lib/`.

> Este prompt não carrega o placar — ele muda a cada iteração. Todo número de placar vem de um
> artefato gerado: `tool/TYPE_DEBT.md`, `tool/SVG_VALIDATION.md`, `prompts/loop-tipagem-diario.md`.
> Os poucos números aqui descrevem a árvore, vêm com data e mudam devagar.

> **Estado em 2026-09-06, revisado após ~25 rodadas:** `PREPARO` e `MORTOS` já terminaram (ver
> diário) — não redispare essas trilhas, são histórico. **`B` (catches reais) chegou a `0` em todo o
> diretório** — o par `_dyn`+`catch` que abriu este loop está zerado na dimensão do engolidor; resta
> só `A` (105 pontos em `_dyn`/`dynamic` sem catch, medido nessa data), espalhado por métodos cada
> vez menores (o maior remanescente tem 6 pontos). Isso muda a forma do trabalho: **MEMBRO** (que
> dependia do censo de catches para achar o maior alvo) não tem mais insumo — vira, na prática, achar
> um acessor mal-tipado/mal-nomeado por investigação direta, não por censo. **MÉTODO é hoje a única
> trilha ativa de verdade.** Releia o diário inteiro (ou pelo menos os OBS de cada rodada) antes de
> preparar o próximo disparo — ele carrega uma lista de formas de bug já vistas repetidas vezes que o
> prompt do subagente agora também cita, mas o diário tem os exemplos concretos com arquivo:linha.

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
`rendering/`; em 2026-09-05 (abertura deste loop) esses dois contadores liam **0** e **1**. Os dois
tinham virado `_dyn(...)` e `catch (e) { e.toString(); }` — a mesma coisa com outro nome, e nenhum
dos dois gates antigos do repositório (`verify_phases --fase=5`, o `debt_report.dart` de então)
enxergava a grafia nova. **Renomear não conta como pagar.** Se uma iteração deste loop derrubar o
placar trocando uma grafia por outra, é RESTORE, sem discussão — é exatamente o que já aconteceu uma
vez e é por isso que este loop existe.

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

## Achados recorrentes (formas de bug que já apareceram mais de uma vez)

O prompt do subagente carrega a versão completa desta lista, com o dever de checá-la a cada rodada.
Ela existe aqui também para você reconhecer o padrão ao ler um reporte e não aceitar uma explicação
mais fraca do que uma dessas quando ela se aplica:

- **Enum errado, mesmo nome de variável.** `Staffrel` vs `StaffrelBasic` — dois enums MEI distintos
  que uma variável `dynamic` deixava passar despercebido (`drawOctave`, achado 2x).
- **Guard de null inerte.** `_dyn(x).metodo == null` sem os parênteses de chamada — sempre `false`,
  o `if` nunca executa (`drawFConnector`).
- **Fallback inventado sem contraparte no C++.** A forma mais comum: "se a lista/valor voltou vazio,
  reconstrua de outro jeito" — o C++ não tem esse `else`, é lista vazia = laço não itera, fim. Achado
  em `drawEnding`, `drawHarm`, `drawDynam`, `drawTempo`, `drawTimeSpanningElement`,
  `drawFConnector` — seis vezes com a mesma forma (`staffList.isEmpty`), e uma vez com forma
  ligeiramente diferente (fallback de `_getRestGlyph`'s classificação mensural).
- **Ajuste de offset chamado no ponto errado.** `calcOffsetY` aplicado na declaração de uma variável
  em vez de só no ramo que o C++ realmente offseta (`drawPitchInflection`).
- **Par `dynamic` checando o mesmo fato duas vezes.** `hasDir == true && dir != null` quando `hasDir`
  já É `dir != null` (`drawStem`).
- **Reimplementação manual ao lado do helper de verdade.** Mesma lógica, sem chamar o método que já
  existe no mesmo arquivo (recorrente — quase toda rodada tem um caso).
- **Interface registrada mas nunca aplicada.** `registerInterfaces([InterfaceId.X])` sem o mixin `X`
  na declaração da classe — acontece em silêncio porque o registro "parece" suficiente
  (`Rest`/`_getRestGlyph`, achado no `AltSymInterface`; `Note` tem o mesmo gap, ainda não corrigido).
- **Campo tipado largo demais na própria classe que o declara.** `Object?` no Dart onde o C++ tem um
  ponteiro tipado inequívoco (`Dot.drawingPreviousElement`/`drawingNextElement`, era `LayerElement*`).
- **Falso-positivo do medidor: texto de comentário contado como catch real.** `debt_report.dart`
  casa `catch` por regex de linha, não por AST — um comentário `// ... catch (e) { return; }`
  narrando um fix antigo conta como catch vivo. Confirmado 3x (MORTOS, lote MEMBRO, `drawTempo`).
  Não corrigido no medidor ainda (baixa prioridade agora que B=0, mas relevante se voltar a subir).
- **A dívida esconde um subsistema inteiro, não um membro.** Ver "Escalada para porte de feature",
  no passo 1 de "A cada iteração", abaixo — o caso `SyncFromFacsimileFunctor`.

## Iteração 0 — preparação (feita em 2026-09-05, histórico)

`PREPARO` já rodou e está commitado (`chore(tipagem): medidor + censo de catches`). Não redispare
esta trilha — ela existe só para explicar o que `tool/debt_report.dart`/`tool/TYPE_DEBT.md` e o censo
de catches (`tool/CATCH_CENSUS*.{md,txt,tsv}`) são e de onde vieram, caso precise recriá-los do zero
num fork/branch novo. Se `tool/TYPE_DEBT.md` já existe e `dart run tool/debt_report.dart` roda sem
erro, PREPARO está feito; siga direto para "A cada iteração".

## A cada iteração

1. **Escolha a trilha** e passe-a ao subagente no disparo. Com `B = 0` (nenhum catch real
   remanescente, medido 2026-09-06), a ordem de prioridade mudou:
   - **Trilha MORTOS — esgotada.** Não há mais catch para provar morto (só o falso-positivo de
     comentário do medidor, ver "Achados recorrentes"). Não dispare.
   - **Trilha MEMBRO — hoje é achado por investigação, não por censo.** Sem catches vivos, não há
     mais "o catch de maior alcance" para apontar o alvo. Ainda vale a pena quando, lendo um método
     na trilha MÉTODO, você enxerga um padrão que se repete em vários lugares (ex.: o mesmo acessor
     mal-nomeado usado em 3 métodos diferentes) — aí vira uma MEMBRO explícita: portar/religar esse
     acessor uma vez, converter todos os pontos de chamada. Não dispare MEMBRO "às cegas" mais; deixe
     que ela emerja de dentro de uma investigação MÉTODO.
   - **Trilha MÉTODO — a trilha default e, na prática, a única.** Alvo = **um** método de
     `debt_report --by-method`, tipado inteiro contra a função C++ correspondente. Um método por
     rodada quando o método é grande; **quando os alvos ficarem pequenos (≤6-7 pontos, o normal a
     partir de meados do loop), é aceitável agrupar 2-3 métodos pequenos e correlatos num único
     disparo** (ex.: `_getDrawingTopForElement` + `_getDrawingBottomForElement`, que são espelhos um
     do outro) — desde que o subagente ainda leia cada um contra o C++ individualmente e não trate o
     lote como desculpa para não investigar.
   - **Escalada para "porte de feature" — trilha nova, fora do padrão de rodada pequena.** Às vezes
     tipar um método revela que ele depende de um **subsistema inteiro nunca portado** (aconteceu com
     `SyncFromFacsimileFunctor`, 2026-09-06 — um functor de ~170 linhas com 8 visitors, não um
     "membro faltante"). Quando isso acontecer, não force o subagente a caber isso numa rodada
     MÉTODO comum: pare, avalie o escopo (quantos arquivos C++ envolvidos, quantos visitors, qual o
     raio de alcance no corpus — `grep` pelo elemento/atributo que dispara o caminho), e dispare uma
     tarefa dedicada com esse escopo explícito, sem o rótulo `[loop auto]` na mensagem de commit
     (é `fix: svg porta <Functor>` normal, com uma nota `tipagem: D <a>→<b> [loop auto]` só se também
     zerar dívida de tipagem de quebra). O `git diff --stat` deve provar que o raio de alcance real
     bate com o previsto (no caso do facsimile, só 1 arquivo do corpus tem `<facsimile>` — confirme
     algo assim antes de aprovar).
2. **Dispare 1 subagente** com `prompts/loop-tipagem-prompt-subagente.md` + a trilha escolhida. O
   subagente **não faz git**: deixa o working tree pronto e reporta.
   - **Instrua explicitamente para bloquear de forma síncrona em verificações longas.** Subagentes
     repetidamente tentaram `run_in_background`/`Monitor` para o `compare_svg.dart --all` (~700s) e
     depois encerravam o turno "esperando a notificação" — que nunca chega para um subagente (só o
     disparador recebe notificação de tarefas em segundo plano de um subagente seu). Isso custou
     múltiplas idas e vindas manuais em praticamente toda sessão longa deste loop. O prompt do
     subagente já carrega essa instrução; reforce-a na mensagem de disparo mesmo assim.
3. **Verifique** o reporte: trilha, alvo, `D` antes e depois (com A/B/C separados), `Falhas`, `S/N`
   antes e depois, `dart analyze`, contagem de `dart test`, e — obrigatório — **para cada
   `_dyn`/`dynamic` removido, o que ele virou**: membro novo portado (com `.h`/`.cpp` citado), acessor
   já existente religado (cite onde já era usado sem `_dyn`), ou ramo inventado apagado (cite a
   ausência de contraparte no C++). Nas rodadas MÉTODO de hoje a maioria é a segunda opção — não
   exija "lista de membros portados" como se isso fosse sempre o caso; exija a explicação, seja ela
   qual for. Sem essa explicação por item, é trocar de grafia; não commite. Confira também você mesmo
   o diff contra o `.cpp` citado antes de commitar — não aceite a citação sem checar, mesmo quando o
   reporte parece completo; várias rodadas desta sessão só foram verificadas de verdade porque o
   supervisor leu o `origin/src/src/<arquivo>.cpp` correspondente linha a linha, não só confiou no
   reporte.
4. **Persista o diário — primeiro, antes de qualquer decisão de git.** Anexe o Diário do reporte em
   `verovio_dart/prompts/loop-tipagem-diario.md`. Quando a decisão for RESTORE, comite o diário
   **sozinho** antes de descartar o código
   (`git add verovio_dart/prompts/loop-tipagem-diario.md && git commit -m "docs: diario tipagem <alvo>"`)
   — é o único jeito de garantir que o mapa "catch/achado → defeito real" sobrevive ao `git stash
   drop` do passo 6. Quando a decisão for COMMIT, não há esse risco: pode incluir o diário no mesmo
   `git add -A` do passo 6 sem problema, contanto que ele já esteja escrito e revisado antes do
   commit — a separação em dois commits existe para proteger contra descarte, não é um ritual em si.
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
