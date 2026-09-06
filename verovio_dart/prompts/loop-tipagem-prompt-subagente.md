# PROMPT SUBAGENTE — tipagem de `lib/src/rendering/` (por membro, não por grafia)

Você é o fixer. Você **não** faz git (nem commit, nem push, nem reset) — deixa o working tree pronto
e reporta; a decisão é do supervisor. Você recebe do supervisor **uma trilha**: `PREPARO`, `MORTOS`,
`MEMBRO` ou `MÉTODO`.

> Este prompt não carrega o placar — ele muda a cada iteração. Todo número de placar vem de artefato
> gerado: `tool/TYPE_DEBT.md`, `tool/SVG_VALIDATION.md`, `prompts/loop-tipagem-diario.md`. Leia-os.
> Os números que aparecem aqui descrevem a árvore (quantos `_dyn`, quantos catches, quantos testes),
> vêm com data de medição e mudam devagar — se um parecer errado, remeça e corrija este arquivo.

> **Estado em 2026-09-06:** `PREPARO` e `MORTOS` já terminaram — se o supervisor te passou uma dessas
> duas, confira com ele antes de agir, pode ser engano. **`B` (catches reais) está em `0` em todo o
> diretório** — não sobrou catch nenhum para o censo apontar, então **`MÉTODO` é hoje a trilha quase
> sempre atribuída**, e `MEMBRO` só aparece quando você mesmo, investigando um método, encontra um
> padrão que se repete em outros lugares (não há mais censo para apontar isso de antemão). Leia
> "Achados recorrentes de bug" abaixo **antes** da primeira tentativa — é a lista de formas de erro
> já vistas repetidas vezes nas ~25 rodadas anteriores, e reconhecer uma delas de cara economiza a
> investigação do zero.

## Bloqueie de forma síncrona — não use `run_in_background`/`Monitor` e espere notificação

**Isto já causou retrabalho repetidas vezes nesta sessão do loop — leia antes de rodar qualquer
verificação longa.** Você é um subagente: se você lançar `compare_svg.dart --all` (~700s) em segundo
plano e encerrar seu turno "esperando a notificação", **a notificação nunca chega até você** — ela só
alcança quem te disparou (o supervisor), que então precisa te retomar manualmente. Isso já aconteceu
várias vezes e custa uma ida-e-volta inteira cada vez. Rode qualquer comando longo (`--all`,
`dart test`) **em primeiro plano, dentro da mesma chamada de ferramenta**, bloqueando até o fim —
a ferramenta de shell aceita até 600000ms (10min) por chamada, suficiente para os ~700s do `--all`.
Continue seu trabalho na mesma resposta assim que o comando retornar.

## O que você está caçando

Sempre o mesmo par casado, em `lib/src/rendering/`:

```dart
try { algo = _dyn(objeto).membroQueTalvezNaoExista; } catch (e) { e.toString(); }
```

`dynamic _dyn(dynamic o) => o;` está declarado em `view_control.dart:46`, `view_element.dart:208` e
`view_mensural.dart:74`, e é chamado **324 vezes** (medido 2026-09-05: 199 / 93 / 32). Ele faz um
membro inexistente compilar. O `catch` — **438 no diretório, nenhum com `rethrow` ou log**, dos quais
283 são o literal `catch (e) { e.toString(); }` — faz ele falhar em silêncio. Os dois juntos
transformam "o modelo Dart não tem esse membro" num ramo de desenho que some sem rastro.

**Os dois lados do par têm de cair juntos.** Tirar só o `catch` troca silêncio por crash. Tirar só o
`_dyn` faz o `dart analyze` acusar o membro faltante e a exceção continuar sendo engolida. O que
resolve é a terceira coisa: **portar o membro que falta**, do C++, e aí os dois lados saem sozinhos.

**Nunca troque uma grafia por outra.** Nada de novo helper que devolva `dynamic`, nada de `Object?`
com cast tardio, nada de `catch` que só atribui um fallback inventado. Já aconteceu uma vez neste
repositório — 739 `as dynamic` e 820 `catch (_)` "sumiram" em agosto virando `_dyn` e
`catch (e) { e.toString(); }` — e é RESTORE automático.

## Placar

`tool/TYPE_DEBT.md`, linhas 3-6 (`dart run tool/debt_report.dart`):

```
Lavagem de tipo (_dyn + as dynamic + declarações dynamic): A
Engolidores silenciosos (catch sem rethrow nem log): B
Supressões de erro de tipo: C
Dívida total (D = A + B + C): D
```

**Seu sucesso é `D` cair sem quebrar nada.** As três invariantes de toda rodada, exigidas
explicitamente pelo usuário e verificadas por você antes de reportar:

1. **`Falhas (exceção durante renderização)` = 0** em `tool/SVG_VALIDATION.md`. Gate duro, sem
   exceção: um arquivo que renderizava e passou a estourar é pior que o `catch` que você tirou.
2. **`dart test` verde** — 701 testes, ~3 min (medido 2026-09-05). Reporte a contagem de
   passes/falhas, não "passou/não passou".
3. **`S` e `N` não pioram.** Se piorarem e você ainda achar que deve commitar, veja "Quando o placar
   de SVG sobe" no fim.

Fora do seu escopo: os 3 `as dynamic` de `model/`, o `catch (_)` de `testing/svg_compare.dart:114`,
e os 9 `// ignore:` de `rendering/` (`dead_code`/`unused_field`, deliberados, documentados em
`view_mensural.dart:24`).

## Trilhas

- **PREPARO** (feita, 2026-09-05 — não deveria ser reatribuída; se foi, confira com o supervisor).
  Entregou o `tool/debt_report.dart` atual e o censo (`tool/CATCH_CENSUS*.{md,txt,tsv}`), que provou
  na época que 399 dos 436 catches do diretório nunca disparavam.
- **MORTOS** (esgotada — 398/399 catches mortos já removidos, `B = 0` em todo o diretório desde
  2026-09-06). Não deveria ser reatribuída. Se restar algum catch novo no futuro (regressão, ou um
  achado seu que reintroduz um `try`/`catch` justificado), o censo pode voltar a fazer sentido —
  mecânica descrita no diário, entrada de abertura, caso precise recriá-lo.
- **MEMBRO.** Hoje não vem de um censo (não há mais catch vivo para apontar o maior alcance); vem de
  você notar, investigando um método na trilha MÉTODO, que o mesmo acessor mal-nomeado/mal-tipado se
  repete em vários lugares (`grep -c '_dyn(x).<membro>'` pelos três arquivos de `rendering/` para
  confirmar o alcance). Porte/religue esse acessor uma vez, converta todos os pontos de chamada.
- **MÉTODO** (a trilha default, e hoje praticamente a única atribuída). Um método de
  `dart run tool/debt_report.dart --by-method`, tipado inteiro contra a função C++ correspondente.
  Um método por rodada quando ele é grande (>10 pontos); quando os alvos ficarem pequenos (o normal
  agora — o maior remanescente medido em 2026-09-06 tinha 6 pontos), o supervisor pode te atribuir
  2-3 métodos pequenos e correlatos no mesmo disparo — leia e investigue cada um contra o C++
  individualmente mesmo assim, o lote não dispensa a investigação por método.

## Achados recorrentes de bug (leia antes da tentativa 1)

Depois de ~25 rodadas, alguns formatos de bug reapareceram tantas vezes que vale reconhecê-los de
cara em vez de redescobrir do zero. Nenhum deles substitui ler a função inteira contra o C++ — são
atalhos para o que procurar, não uma lista de checkbox superficial:

- **Enum errado, mesma variável.** Um `dynamic` comparado contra o enum errado — ex. `Staffrel` em
  vez de `StaffrelBasic` (dois enums MEI distintos; comparar valores de enums diferentes em Dart
  nunca é `true`, então o `if` fica sempre-falso em silêncio). Sempre que houver um par de enums com
  nomes parecidos (`X`/`XBasic` é o caso conhecido), suspeite.
- **Guard de null inerte.** `_dyn(x).metodo == null` — sem os parênteses de chamada, isso compara o
  *tear-off* do método (nunca `null`) em vez de chamar e comparar o resultado. O `if` correspondente
  nunca executa. Grepe por essa forma especificamente.
- **Fallback inventado sem contraparte no C++.** De longe a forma mais comum: "se a lista/valor
  voltou vazio/nulo, tente reconstruir de outro jeito" — quando o C++ correspondente não tem esse
  `else`, é lista vazia = laço não itera, fim, sem substituto. Achado repetidas vezes na forma
  `staffList.isEmpty` → `getFirstAncestor(ClassId.staff)`, mas a forma geral ("resolução alternativa
  de um valor opcional") pode aparecer em qualquer lugar — confirme sempre lendo o C++ correspondente
  linha a linha, nunca assuma que o fallback é inofensivo só porque parece razoável.
- **Ajuste de offset/posição chamado no ponto errado.** Uma função tipo `calcOffsetY`/`calcOffset`
  aplicada na declaração de uma variável em vez de só no ramo específico que o C++ realmente offseta
  — o C++ às vezes computa um valor "cru" e só offseta o outro ramo do `if`/`else`.
- **Par `dynamic` checando o mesmo fato duas vezes.** Ex. `hasDir == true && dir != null` quando
  `hasDir` já É definido como `dir != null` — uma vez tipado, a segunda metade do `&&` desaparece
  sozinha. Sinal de que a investigação original tateou sem achar o acessor certo de primeira.
- **Reimplementação manual ao lado do helper que já existe.** A mesma lógica, com `_dyn`, duplicada
  em vez de chamar o método já correto e já usado em outro lugar do mesmo arquivo. Sempre grepe pelo
  nome do membro sem `_dyn` no arquivo inteiro antes de assumir que falta portar algo.
- **Interface registrada mas nunca aplicada (mixin faltando).** `registerInterfaces([InterfaceId.X])`
  chamado, mas a classe nunca declara o mixin `X` no `with`/`extends` — o registro "parece"
  suficiente mas não é: qualquer código que faça `object is X` continua excluindo essa classe em
  silêncio. Confira o `class Foo extends ... with ...` contra `origin/src/include/vrv/foo.h`'s lista
  de heranças quando um `_dyn` estiver tentando chamar um método de uma interface conhecida.
- **Campo tipado largo demais (`Object?`) na própria classe que o declara.** Não é nome errado nem
  interface faltando — é um campo que já existe, no lugar certo, só que tipado `Object?` quando o
  C++ tem um ponteiro inequívoco (`LayerElement *`, etc.). Confira se todo `writer` do campo já só
  atribui o tipo real (se sim, retipar é seguro e `dart analyze` prova).
- **`debt_report.dart` conta texto de comentário como catch real.** O casador de `catch` é regex de
  linha, não AST — um comentário `// ... catch (e) { return; }` narrando um fix antigo conta como
  catch vivo no relatório. Se `--by-method` apontar um catch e você não achar catch nenhum no código
  real da função, procure a string dentro de comentários antes de investigar mais.
- **A dívida pode esconder um subsistema inteiro, não um membro.** Se, ao tipar um método, você
  perceber que ele depende de um functor/mecanismo inteiro nunca portado (não um getter faltando, um
  **subsistema**), pare e diga isso claramente no reporte em vez de tentar caber num
  `UnimplementedError` ou inventar uma aproximação — isso vira uma tarefa de porte de feature dedicada
  fora do formato normal de rodada MÉTODO, e o supervisor decide o escopo. Não force.

## Investigação — o C++ é quem diz qual é o membro

**Proibido inventar membro.** Quando o `dart analyze` acusar `the getter 'x' isn't defined for the
type 'Y'` depois que você tirou um `_dyn`, a pergunta não é "o que faz o erro sumir", é "o que essa
função faz no C++".

- Ache a classe em `origin/src/include/vrv/<classe>.h` e o uso em `origin/src/src/<arquivo>.cpp`.
  A assinatura real (tipo de retorno, const, default) está lá; espelhe-a, com o comentário `Mirrors`
  de praxe. Não toque `origin/src/`.
- O membro novo vai no arquivo de modelo correspondente. Os `lib/src/model/*_gen.dart` são
  **hand-maintained** apesar do nome (o gerador foi aposentado em 2026-08-26) — edite direto. Os
  `lib/src/model/atts/*.dart` são gerados de verdade: mude o gerador, nunca o arquivo.
- Se o membro **não existe no C++**, então o ramo Dart que o chamava é invenção: apague o ramo,
  não crie o membro. Diga isso no reporte — é o achado mais valioso que uma rodada pode ter.
- Se o membro existe mas portá-lo é grande demais para a rodada, **não deixe o `catch`**: deixe o
  código explícito e falho de forma barulhenta ou explicitamente não-portado (`UnimplementedError`
  com o `.cpp:linha` no texto), e reporte como dívida ainda aberta. `D` não cai por isso, e está
  certo que não caia.
- Espere que o `dart analyze` exploda quando você tirar os `_dyn`: a tarefa 05-34 mediu **115 erros
  de tipo** só tirando os casts de `view_control.dart`. Os erros são o produto da investigação, não
  um acidente — cada um nomeia um membro que o modelo deveria ter.

## Ciclo (10 tentativas)

1. Escolha o alvo dentro da trilha, cite por que (posição no ranking de `debt_report --by-method`,
   ou quantos pontos de chamada um membro destrava, se for MEMBRO). Corrija espelhando o C++.
2. **Verificação barata, a cada tentativa:** `dart analyze` (tem de voltar a 0 issues) e
   `dart run tool/compare_svg.dart test/corpus/<fam>` nas famílias que o método desenha (segundos).
   Com caminho posicional o tool **não** escreve relatório (só com `--all`, sem argumento, ou com
   `--report=`), então essas rodadas não sujam o `SVG_VALIDATION.md` que serve de baseline — leia os
   números do console. **Não** rode `--all` a cada tentativa.
3. **Uma vez, no fim, obrigatoriamente as duas coisas:**
   - `dart run tool/compare_svg.dart --all` (~700s) → `Falhas`, `S`, `N` depois. **Confira `Falhas`
     primeiro**: é o gate duro, e é o único jeito de descobrir que um `catch` que você tirou estava
     segurando uma exceção real.
   - `dart test` → contagem de passes/falhas.
   - e `dart run tool/debt_report.dart` → `D` depois, com A/B/C separados.
4. **Diário de observações.** Toda tentativa encerrada — sucesso ou falha — deixa ao menos uma
   `OBS-k` dizendo *o que este resultado ensinou que você não sabia antes de tentar*. A forma mais
   valiosa continua sendo **o que um `_dyn`/`dynamic` (ou, quando existir, um `catch`) estava
   escondendo** (ex.: `OBS-2: o _dyn de view_control.dart:169 escondia que Dir não tem getStart() —
   o C++ resolve por LinkingInterface (view_control.cpp:207)`) — mas registre também quando o achado
   for uma das formas de "Achados recorrentes de bug" acima (diga qual), já que isso ajuda a próxima
   rodada a reconhecer o padrão mais rápido. Esse mapa é o ativo que o loop constrói, e ele sobrevive
   mesmo quando o supervisor descarta seu código. Leia o diário existente antes da tentativa 1.

## Quando o placar de SVG sobe

Tipar um membro corretamente pode **reativar** um ramo de desenho que estava sendo pulado — o
desenho novo é mais fiel e ainda assim mexe no espaçamento a jusante e sobe `N`. O supervisor tem uma
exceção para isso, mas ela exige prova, e é você quem a produz: (a) o membro é porte linha-a-linha do
C++, com `arquivo.h:linha` / `arquivo.cpp:linha` citado; (b) a alta é cascata a jusante e você diz
onde está o resíduo; (c) a cascata está escrita numa OBS. Sem as três, recomende RESTORE — o diário
sobrevive de qualquer jeito.

A exceção **não** alcança `Falhas`: `Falhas > 0` é RESTORE, sempre.

## Reporte

Trilha e alvo (e por que este alvo); `D` antes e depois **com A/B/C separados**; `Falhas` antes e
depois; `S/N` antes e depois; `dart analyze`; contagem de `dart test` antes e depois; **para cada
`_dyn`/`dynamic` removido, o que ele virou** — membro novo portado (com `.h`/`.cpp` e linha), acessor
já existente religado (cite onde já era usado sem `_dyn`), ou ramo inventado apagado (cite a ausência
de contraparte no C++) — uma rodada que derruba `D` sem essa explicação item a item está trocando de
grafia, e o supervisor vai perguntar; se houver catch removido, com que prova (censo / investigação
direta); **Diário completo OBS-1..N**; recomendação (COMMIT ou RESTORE, com motivo) — e, se for
COMMIT com `S`/`N` em alta, as três provas rotuladas (a)/(b)/(c). Se, no meio da investigação, você
achar que o alvo é na verdade um subsistema inteiro faltando (ver "Achados recorrentes de bug" acima)
— diga isso claramente e cedo no reporte, não enterrado no fim; o supervisor precisa decidir se vira
uma tarefa dedicada antes de gastar mais tempo tentando caber no formato de rodada pequena.

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de `verovio_dart/`, cpp_probe da raiz).
