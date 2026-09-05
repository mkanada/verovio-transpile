# PROMPT SUBAGENTE — tipagem de `lib/src/rendering/` (por membro, não por grafia)

Você é o fixer. Você **não** faz git (nem commit, nem push, nem reset) — deixa o working tree pronto
e reporta; a decisão é do supervisor. Você recebe do supervisor **uma trilha**: `PREPARO`, `MORTOS`,
`MEMBRO` ou `MÉTODO`.

> Este prompt não carrega o placar — ele muda a cada iteração. Todo número de placar vem de artefato
> gerado: `tool/TYPE_DEBT.md`, `tool/SVG_VALIDATION.md`, `prompts/loop-tipagem-diario.md`. Leia-os.
> Os números que aparecem aqui descrevem a árvore (quantos `_dyn`, quantos catches, quantos testes),
> vêm com data de medição e mudam devagar — se um parecer errado, remeça e corrija este arquivo.

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

- **PREPARO** (uma vez, iteração 0). Duas entregas, e só elas — **não toque em `lib/`**:
  1. Estenda `tool/debt_report.dart` para contar a grafia atual (`_dyn(`, declarações `dynamic`,
     `catch` sem rethrow/log), preservando `--by-method`, `--json` e `--baseline`, e a fazê-lo
     escrever `tool/TYPE_DEBT.md` com as linhas 3-6 acima. Hoje ele conta `as dynamic`, `catch (_)`
     e `ignore_for_file` — os três padrões que praticamente não existem mais — e por isso reporta
     dívida quase zero sobre **894 pontos crus** reais (324 `_dyn(...)` + 132 declarações `dynamic`
     + 438 `catch`; censo completo na abertura do diário).
  2. O **censo de catches vivos × mortos** (ver a seção seguinte), entregue como entrada de abertura
     do diário.
- **MORTOS.** Um lote de `catch` que o censo provou nunca dispararem em nenhum dos 621 arquivos do
  corpus. Apague o `catch` **e o `try`** — um `try` cujo corpo nunca lança é ruído que esconde o
  próximo. Única trilha em que lote grande é aceitável, porque o censo já é a prova.
- **MEMBRO.** Um membro de modelo faltante que força `_dyn` em muitos pontos. Ranqueie por *quantos
  pontos de chamada um único membro destrava* (`grep -c '_dyn(x).<membro>'` pelos três arquivos) e
  pegue o topo. Porte o membro uma vez, tipado, e converta todos os pontos de chamada.
- **MÉTODO.** Um método de `dart run tool/debt_report.dart --by-method`, tipado inteiro contra a
  função C++ correspondente. **Um** método por rodada — `view_control.dart` tem 4518 linhas.

## O censo (a ferramenta que separa 10 minutos de 2 horas)

Ler um `catch` não diz se ele dispara. A distinção importa mais que qualquer outra coisa neste loop:
um `catch` que nunca dispara sai de graça; um que dispara é um defeito de fidelidade a portar.

Mecânica exigida — mecânica, não a olho:

1. Reescreva mecanicamente cada corpo de `catch` de `lib/src/rendering/` para registrar
   `arquivo:linha` (as 283 formas de uma linha são regex trivial; as demais aceitam uma linha
   inserida após o `{`). Sem mudar controle de fluxo: o fallback que já existia continua rodando.
2. Renderize o corpus inteiro (`dart run tool/compare_svg.dart --all`, ~700s) — é o que exercita os
   621 arquivos.
3. Colete o resultado num arquivo fora de `lib/` e **reverta a instrumentação**. Prove que reverteu:
   `git diff --stat -- verovio_dart/lib` vazio. Instrumentação que vaza para um commit faz o censo
   seguinte medir a si mesmo.

O censo vale para todo o loop; regenere-o só quando o número de catches tiver mudado muito.

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

1. Escolha o alvo dentro da trilha, cite por que (posição no ranking / pontos que destrava / linha do
   censo). Corrija espelhando o C++.
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
   `OBS-k` dizendo *o que este resultado ensinou que você não sabia antes de tentar*. Neste loop a
   OBS mais valiosa tem uma forma fixa: **qual `catch` estava escondendo o quê**
   (ex.: `OBS-2: o catch de view_control.dart:169 disparava em 34 arquivos escondendo que Dir não
   tem getStart() — o C++ resolve por LinkingInterface (view_control.cpp:207)`). Esse mapa é o ativo
   que o loop constrói, e ele sobrevive mesmo quando o supervisor descarta seu código. Leia o diário
   existente antes da tentativa 1.

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
depois; `S/N` antes e depois; `dart analyze`; contagem de `dart test` antes e depois; **a lista de
membros de modelo portados, cada um com o `.h`/`.cpp` e linha** — uma rodada que derruba `D` sem
portar nada e sem apagar catch morto está trocando de grafia, e o supervisor vai perguntar; quais
`catch` você removeu e com que prova (censo / tipagem); **Diário completo OBS-1..N**; recomendação
(COMMIT ou RESTORE, com motivo) — e, se for COMMIT com `S`/`N` em alta, as três provas rotuladas
(a)/(b)/(c).

Workdir /home/mauricio/rust_projects/verovio-transpile (dart de `verovio_dart/`, cpp_probe da raiz).
