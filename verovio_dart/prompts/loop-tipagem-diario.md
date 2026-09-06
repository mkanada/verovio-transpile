# Diário do loop de tipagem

Registro acumulado do que cada iteração **aprendeu**, independentemente de o código ter sido
commitado ou descartado. O supervisor anexa aqui o Diário do reporte de cada subagente **antes** de
qualquer restore, e comita este arquivo sozinho.

Neste loop a OBS mais valiosa tem forma fixa: **qual `catch` estava escondendo o quê.** O mapa
"engolidor → defeito real" é o ativo que este loop constrói, e ele sobrevive ao código descartado.

> Os números aqui são **fotografias datadas**, não estado atual. O estado de agora está em
> `tool/TYPE_DEBT.md` e `tool/SVG_VALIDATION.md` — nunca cite um número deste arquivo como corrente.

Formato por iteração:

```
## <data> — trilha <PREPARO|MORTOS|MEMBRO|MÉTODO> — alvo <membro, método ou lote>
D <antes>→<depois>  (A <a>→<a'>  B <b>→<b'>  C <c>→<c'>)   Falhas <f>  S <s>  N <n>  — <COMMIT|RESTORE>

- OBS-1: …
```

---

## 2026-09-05 — abertura do diário (sem iteração)

Censo da dívida medido na árvore em `1695f718`, por grep. **Estes são números crus**: a definição
exata de `A`, `B`, `C` e `D` é entregue pela iteração `PREPARO`, junto com o medidor que passa a
gerar `tool/TYPE_DEBT.md`. Há sobreposição conhecida entre as duas primeiras linhas de A (as três
declarações `dynamic _dyn(dynamic o) => o;` também são declarações `dynamic`).

**A — lavagem de tipo em `lib/src/rendering/`**

| Grafia | Total | view_control | view_element | view_mensural |
|---|---|---|---|---|
| chamadas a `_dyn(...)` | 324 | 199 | 93 | 32 |
| declarações `dynamic x` | 132 | 72 | 46 | 13 (+1 em view_text) |
| `as dynamic` | 0 | — | — | — |

**B — engolidores silenciosos em `lib/src/rendering/`**

| Grafia | Total | view_control | view_element | view_mensural | view_text |
|---|---|---|---|---|---|
| `catch` (todos) | 438 | 242 | 118 | 77 | 1 |
| dos quais `catch (e) { e.toString(); }` | 283 | 152 | 87 | 44 | — |
| dos quais `catch (_)` | 1 | — | — | — | 1 |
| com `rethrow` ou log | **0** | — | — | — | — |

**C — supressões de erro de tipo: 0.** Os 9 `// ignore:` do diretório são `dead_code` (4 em
`svg_device_context.dart`) e `unused_field` (4 em `view_mensural.dart`, deliberados e documentados na
linha 24 do arquivo) mais um `// ignore: unused` em `view_control.dart:392` — nenhum suprime erro de
tipo. Fora de escopo.

**Total cru: 894 pontos** (324 + 132 + 438).

- **OBS-1 (a dívida foi renomeada, não paga):** em 2026-08-29 o `verify_phases --fase=5` media 739
  `as dynamic` e 820 `catch (_)` em `rendering/`. Hoje mede 0 e 1 — e o CLAUDE.md chegou a registrar
  isso como dívida quitada. Não foi: viraram `_dyn(...)` (helper `dynamic _dyn(dynamic o) => o;`
  declarado em `view_control.dart:46`, `view_element.dart:208`, `view_mensural.dart:74`) e
  `catch (e) { e.toString(); }`. Nenhum dos dois gates do repositório enxerga a grafia nova:
  `verify_phases` critério 5.2 e `debt_report.dart` fazem grep literal de `catch (_)`. Por isso a
  primeira entrega do loop é o medidor, não código de `lib/`.
- **OBS-2 (o par é casado, e é por isso que a rodada tem de portar algo):** o `_dyn` faz um membro
  inexistente compilar; o `catch` faz o `NoSuchMethodError` sumir em runtime. Removê-los sem portar o
  membro só escolhe qual dos dois sintomas você prefere — silêncio ou crash. A medida de progresso
  honesta de uma rodada não é `D` cair, é **quantos membros de modelo foram portados do C++**; `D`
  cai como consequência. O supervisor foi instruído a pedir essa lista antes de commitar.
- **OBS-3 (a população desconhecida, e a maior alavanca do loop):** ninguém sabe quantos dos 438
  catches chegam a disparar. Se a maioria for morta — o que é plausível, dado que foram gerados em
  bloco como código defensivo durante a virada da Fase 5 — eles saem em um ou dois lotes e a dívida
  desaba sem risco nenhum. Os que disparam são a lista de defeitos de fidelidade que o loop de SVG
  não consegue enxergar, porque o sintoma dele aparece longe da causa. O censo (iteração `PREPARO`)
  é o que separa as duas populações; até ele existir, toda estimativa de esforço deste loop é chute.
- **OBS-4 (o gate que sobra):** `tool/SVG_VALIDATION.md` reporta hoje `Falhas (exceção durante
  renderização): 0` sobre 621 arquivos. Enquanto os catches existem, esse zero é barato — nada
  escapa. À medida que eles saem, esse número passa a ser o detector mais sensível do loop: o
  primeiro arquivo que estourar aponta exatamente para um `catch` que estava segurando uma exceção
  real. Por isso ele é gate duro e sem exceção.

---

## 2026-09-05 — trilha PREPARO — alvo medidor + censo

D não se aplica (PREPARO não mexe em `lib/`)   Falhas 0 (verificado durante o censo)   dart analyze 0
issues   dart test 701/701 — COMMIT

Duas entregas, ambas verificadas pelo supervisor antes de commitar (não só lidas do reporte do
subagente): `git diff --stat -- lib` vazio, `dart analyze` limpo, conteúdo de `tool/TYPE_DEBT.md`
conferido linha a linha.

**1. `tool/debt_report.dart` estendido** para contar a grafia atual: `_dyn(` (excluindo as 3
declarações do helper), declarações/parâmetros `dynamic` (idem), `as dynamic` (0 hoje), e todo
`catch` sem `rethrow` nem log — por *brace-matching* real, não regex de uma linha, porque há corpos
de `catch` multi-linha e `catch` duplo na mesma linha (`view_control.dart:3847`,
`view_mensural.dart:441/442`). Preserva `--by-method`/`--json`/`--baseline`/`--write-baseline` e
ganhou `--report=<path>` (default `tool/TYPE_DEBT.md`, escrito a cada rodada normal).

Medida em `1695f718` + o próprio commit desta entrega: **A=450 (324 `_dyn(` / 0 `as dynamic` / 126
`dynamic`) B=436 C=0 D=886** — 0,9% abaixo do censo cru de abertura (894), diferença esperada (o
grep cru conta as 3 linhas do helper e trata mal os `catch` duplo-por-linha; o medidor novo exclui e
separa corretamente). Por arquivo: `view_control.dart` D=507 (A=267 B=240), `view_element.dart`
D=256 (A=138 B=118), `view_mensural.dart` D=121 (A=44 B=77), `view_text.dart` D=2.

**2. Censo de catches vivos × mortos**, instrumentando os 436 `catch` de `lib/src/rendering/`
(`stderr.writeln('CATCH_HIT:arquivo:linha:índice')` após cada `{`, sem mudar controle de fluxo, mais
um marcador `CENSUS_FILE:` temporário em `tool/compare_svg.dart`), rodando
`compare_svg.dart --all` nos 621 arquivos do corpus (Falhas=0, `test/golden/dart/**` e
`SVG_VALIDATION.md` byte-idênticos ao golden — a instrumentação não mudou o SVG produzido) e
revertendo tudo (`git diff --stat -- lib` vazio, confirmado pelo supervisor).

- **OBS-1 (o resultado central do censo): 37 de 436 catches (8,5%) já dispararam em algum dos 621
  arquivos; 399 (91,5%) nunca dispararam.** Isso confirma a hipótese da OBS-3 de abertura — a maioria
  é morta — e diz que a trilha MORTOS da próxima rodada já tem lista pronta e provada:
  `tool/CATCH_CENSUS_dead.txt` (399 linhas `arquivo:linha:índice`).
- **OBS-2 (o maior alvo MEMBRO, dispara em TODOS os 621 arquivos):** `view_control.dart:3847:0`, em
  `drawSystemElement`, esconde que `systemMilestoneEnd.getStart()` não existe no modelo Dart — cai
  para `_dyn(element).start`. 4861 disparos totais. É o candidato número 1 para a próxima rodada
  MEMBRO: portar o getter certo (o C++ resolve via `LinkingInterface`, a conferir em
  `view_control.cpp` perto da linha 3847 do fonte gerado) destrava potencialmente todos os 621
  arquivos de uma vez.
- **OBS-3 (segundo maior, por contagem de disparos):** `view_element.dart:1711:0`, em `drawClef`,
  esconde que `Clef` não tem `getVisible` — 600 arquivos, 9311 disparos (o maior volume absoluto do
  censo). Segundo candidato MEMBRO forte.
- **OBS-4 (achado fora do padrão — vale um MÉTODO dedicado):** `view_control.dart:4227` (`_getFYRel`)
  chama `_dyn(this)` — ou seja, `_dyn` na própria `View`, não num objeto de modelo. É o único dos 436
  sites nesse formato; sugere que `View.getFYRel` deveria ser um método Dart tipado normal em vez de
  passar por `_dyn`, o que é uma causa diferente das outras 435 (membro de modelo faltante) — aqui é
  método da própria View não tipado.
- **OBS-5 (catch morto lado a lado com o mais disparado):** `view_control.dart:3847` tem dois
  `catch` na mesma linha; só o índice `:0` (OBS-2) já disparou nos 621 arquivos — o índice `:1`
  (fallback `_dyn(element).start`) nunca precisou rodar e está 100% morto apesar de vizinho do
  catch mais quente do censo. `view_mensural.dart:441:0/441:1/442:0/442:1` (outro par de catch-duplo
  por linha) está inteiramente morto — nenhum dos 4 disparou. Mostra que "catch duplo na mesma linha"
  não é sinal de que ambos disparam; têm de ser censados separadamente por índice, como o medidor faz.
- **OBS-6 (tabela completa e dados crus):** ranking completo dos 37 vivos com nota de qual membro/
  ramo cada um esconde está em `tool/CATCH_CENSUS.md`; lista morta completa em
  `tool/CATCH_CENSUS_dead.txt`; TSV `arquivo:linha:índice / arquivos / disparos` dos 37 vivos em
  `tool/CATCH_CENSUS_fired.tsv`. Regenerar só quando o número de catches mudar muito (ver prompt do
  supervisor).

Próxima rodada recomendada: **MORTOS** primeiro (399 catches já provados mortos, maior rendimento
por unidade de risco), depois **MEMBRO** em `view_control.dart:3847` (`LinkingInterface.getStart`,
621 arquivos) e `view_element.dart:1711` (`Clef.getVisible`, 600 arquivos, maior volume de disparos).

---

## 2026-09-05 — trilha MORTOS — alvo os 399 catches provados mortos pelo censo

D 886→435 (A 450→397  B 436→38  C 0→0)   Falhas 0→0   S/N inalterados (byte-idêntico)   dart analyze
0 issues   dart test 701→701 — COMMIT

398 dos 399 candidatos de `tool/CATCH_CENSUS_dead.txt` removidos (`try`+`catch` inteiros, mantendo o
corpo do `try` incondicional); 1 pulado. Arquivos: `view_control.dart`, `view_element.dart`,
`view_mensural.dart`, `view_text.dart`. `S`/`N` byte-idênticos ao baseline — esperado, já que remover
scaffolding morto não muda nenhum SVG produzido.

- **OBS-1 (falso positivo do censo):** `view_control.dart:2230:0` não era código — era texto dentro
  de um comentário (`// This guard used to be \`try { ... } catch (e) { return; }\`...`) documentando
  um fix anterior. O casador de `catch` do censo era baseado em linha/regex e não distinguia comentário
  de código. Corrigir para próximo censo: casar por AST, não por grep de linha.
- **OBS-2 (dois catches sem espaço escaparam do censo, mas eram seguros de remover):**
  `view_control.dart` linhas ~202/208 tinham `catch(e){ ... }` sem espaço — o regex do censo
  (`catch (`) não os instrumentou, então não apareciam nem em `dead.txt` nem em `fired.tsv`. Ambos
  viviam inteiramente dentro do corpo de catches **já provados mortos** pelo censo (`201:0`/`207:0`),
  então saíram automaticamente com o pai — a mesma lógica de prova se aplica (se o try externo nunca
  lança, nada dentro do seu catch, censado ou não, pode rodar). Ação para o medidor: ampliar o regex
  do censo para `catch\s*\(`.
- **OBS-3 (aninhamento morto-dentro-de-morto tem duas formas, e são diferentes):** um catch morto
  aninhado no **corpo do catch** de outro catch morto desaparece junto com o pai (ex.:
  `view_mensural.dart:441:0/1`, `442:0/1`; `view_control.dart:3847:1`, cujo irmão `:0` é o único catch
  **vivo** do arquivo inteiro e foi preservado). Um catch morto aninhado no **corpo do try** de outro
  catch morto precisa ser desembrulhado independentemente, ou sobra scaffolding morto — caso
  encontrado repetidamente em `view_control.dart` (ex. fallback de lista de `@staff`, três níveis de
  profundidade). Confundir os dois deixa lixo morto para trás.
- **OBS-4 (remover try/catch pode expor coisas que o analisador não sabia antes):** um `try` bloqueia
  a promoção de null-check do Dart através do seu corpo. Remover um try morto pode (a) tornar
  checagens `!= null` antigas redundantes (`unnecessary_null_comparison`) porque agora o Dart consegue
  provar a não-nulidade por promoção, e (b) tornar código depois de um antigo `return` dentro de um
  catch removido genuinamente inalcançável (`dead_code`) quando esse `return` virou incondicional.
  Ambos os casos nesta rodada eram consequências corretas do mesmo fato que o censo provou — foram
  limpos, não re-envolvidos em try/catch (isso seria a re-grafia proibida).
- **OBS-5 (A caiu por arraste aritmético, não por porte):** `A` caiu 450→397 porque alguns corpos de
  catch morto continham suas próprias chamadas `_dyn(...)` de fallback, que foram embora junto com o
  catch mission morto. Não é trabalho de trilha MEMBRO/MÉTODO — é efeito colateral mecânico e honesto
  da remoção.

Próxima rodada recomendada: **MEMBRO** em `view_control.dart` (ex-linha 3847, agora deslocada —
recensar a linha) `LinkingInterface.getStart` (disparava nos 621 arquivos) e `view_element.dart`
(ex-linha 1711) `Clef.getVisible` (600 arquivos, 9311 disparos — maior volume do censo). Os 38 catches
`B` restantes (todos vivos, por definição — só sobrou o que o censo provou disparar, mais os que a
trilha MORTOS não tocou por serem fora do CATCH_CENSUS_dead.txt) são a lista de trabalho completa das
próximas rodadas MEMBRO/MÉTODO; um recenso rápido (`grep -c` dos padrões atuais) deve preceder a
próxima rodada porque os números de linha mudaram com esta remoção.

---

## 2026-09-05 — trilha MEMBRO — alvo `view_element.dart` drawClef (catch de maior volume do censo)

D 435→431 (A 397→394  B 38→37  C 0→0)   Falhas 0→0   S/N inalterados (byte-idêntico, `test/corpus/clef`
conferido: 372 divergências numéricas, 5 divergentes, 0 falhas — igual antes/depois)   dart analyze
0 issues   dart test 701→701 — COMMIT

Alvo: o catch de **maior volume absoluto de todo o censo** (600/621 arquivos, 9311 disparos,
`tool/CATCH_CENSUS_fired.tsv` linha 2, era `view_element.dart:1711:0` antes do deslocamento de linhas
pela rodada MORTOS). Escolhido em vez do candidato nº1 por alcance de arquivos
(`view_control.dart` `drawSystemElement`/`LinkingInterface.getStart`, 621/621 arquivos, ainda pendente
— ver abaixo) porque, após investigar o C++, este se mostrou mais rápido de verificar por completo
numa única rodada.

- **OBS-A (o catch mais disparado do censo não escondia membro faltante — escondia exploração morta
  ao lado do fix correto):** `drawClef` chamava `_dyn(clef).getVisible`, um getter que **nunca
  existiu** nem no C++ (`Clef::GetVisible()`, `view_element.cpp:685`, na verdade
  `AttVisibility::GetVisible()`) nem no Dart. O Dart **já tinha** o membro certo, tipado:
  `AttVisibility.visible` (`bool?`, `atts_shared.dart:5837`), misturado em `Clef`
  (`basic_elements.dart:3157`) — e a própria função já usava `clef.visible == false` corretamente três
  linhas antes do `_dyn` que lançava, mais três vezes redundantemente depois (código de investigação
  nunca limpo, não invenção de membro). As 24 linhas de tentativas (try/catch + `dyn.hasVisible` +
  `dyn.visible.toString().contains('false')` + recheck direto) colapsaram para
  `if (clef.visible == false) { ... }`, citando `view_element.cpp:685`. Equivalência provada por
  leitura de todos os ramos antigos e confirmada por `compare_svg --all` byte-idêntico.
  **Lição para as próximas rodadas MEMBRO:** antes de assumir "membro faltante", grep o resto do
  método por usos não-`_dyn` do mesmo campo — pode já estar portado ao lado do ramo `_dyn` morto.

Pendente para a próxima rodada MEMBRO: `view_control.dart:3615` `drawSystemElement`, fallback em
`:3623` `_dyn(element).start` (localização atual pós-MORTOS) — dispara nos 621/621 arquivos, maior
alcance do censo, ainda não investigado a fundo (ao contrário do Clef, aqui é plausível que seja
membro genuinamente faltante via `LinkingInterface`, a confirmar no C++).

---

## 2026-09-05 — trilha MEMBRO — alvo `view_control.dart` drawSystemElement (maior alcance do censo, 621/621 arquivos)

D 431→425 (A 394→389  B 37→36  C 0→0)   Falhas 0→0   S/N inalterados (byte-idêntico:
test/corpus/ending 233 divergências numéricas/2 divergentes, test/corpus/section 805/2, e --all
completo 612/621 estrutural, 248/621 numérico, 44 estruturais, 27371 numéricas, 373 divergentes —
idêntico ao baseline em todos os campos)   dart analyze 0 issues   dart test 701→701 — COMMIT

Alvo: o catch de **maior alcance de todo o censo** — 621/621 arquivos, 4861 disparos
(`view_control.dart:3847:0`/`:1` no censo original, `:3623` pós-MORTOS).

- **OBS-A (mesma lição do caso Clef, agora no maior alcance do censo — membro já existia, tipado, do
  lado do `_dyn` morto):** `drawSystemElement` tentava `end.getStart()` — um **método** que nunca
  existiu nem no C++ nem no Dart. O C++ tem `GetStart()` como método porque `m_start` é privado
  (`systemmilestone.h:49`); o Dart já expõe o campo direto e público: `SystemMilestoneEnd.start`
  (`system_page_elements.dart:664`), `final Object`, não-nulo, setado no construtor. Por isso o catch
  `:0` (tentativa `getStart()`) disparava em **todo** arquivo do corpus (a chamada é sempre
  inalcançável) e o catch `:1` (fallback `_dyn(element).start`) nunca disparava (o campo real sempre
  resolve) — o par catch-duplo mais desbalanceado do censo (4861 disparos no `:0`, zero no `:1`) casa
  exatamente com essa explicação. Mirrors `view_control.cpp:3020-3025` (`assert(elementEnd->GetStart())`,
  sem condicional — daí o try/catch Dart não corresponder a nada real no C++) e
  `systemmilestone.h:49,75`. Removidos: 3 `_dyn(...)`, 2 declarações `dynamic`, 1 try/catch inteiro.
- **OBS-B (import faltando, não membro faltando):** ao remover o `_dyn`, o compilador só apontou
  `SystemMilestoneEnd` indefinido porque a classe nunca fora importada em `view.dart` (o `show`
  clause de `system_page_elements.dart` só trazia `PageElement, PageMilestoneEnd, System,
  SystemElement`) — a classe já existia, tipada, no arquivo de modelo. "Membro/classe não resolve"
  às vezes é plumbing de import, não ausência real — checar isso antes de assumir porte necessário.
- **OBS-C (padrão que se repete — vale generalizar para a próxima MEMBRO):** as duas maiores rodadas
  MEMBRO até agora (Clef.visible, 600 arquivos; SystemMilestoneEnd.start, 621 arquivos) foram as duas
  vezes em que o campo certo **já existia tipado no modelo**, e o `_dyn` era só uma tentativa de
  método/getter inventado ao lado dele. Para a próxima rodada MEMBRO, grep primeiro por usos
  não-`_dyn` do mesmo objeto/classe antes de ir direto ao C++ — pode ser um achado de 10 minutos, não
  um porte de verdade.

Os 36 catches `B` restantes são todos vivos (por definição) e a lista de trabalho das próximas
rodadas MEMBRO/MÉTODO; ver `tool/CATCH_CENSUS_fired.tsv` (linhas stale, recensar por conteúdo).

---

## 2026-09-05 — trilha MEMBRO — alvo `view_control.dart` calculatePrincipalStaff (era `:394:0`, 94/621 arquivos)

D 425→423 (A 389→388  B 36→35  C 0→0)   Falhas 0→0   S/N agregado inalterado (612/621 estrutural,
248/621 numérico, 44 estruturais, 27371 numéricas, 373 divergentes — idêntico); 4 arquivos mudaram
byte-a-byte dentro da mesma contagem de divergências (ver OBS-B)   dart analyze 0 issues   dart test
701→701 — COMMIT

Ao contrário das duas rodadas MEMBRO anteriores (Clef.visible, SystemMilestoneEnd.start), aqui **não**
era scaffolding morta ao lado de um campo já certo — era um porte de verdade que faltava por completo.

- **OBS-A (porte de verdade, não achado-e-limpa):** `Slur::CalculatePrincipalStaff` (`slur.h:160`,
  `slur.cpp:479-515`) reatribui a variável `staff` do laço em `view_control.cpp:333` — usada pelo
  resto da iteração (`SetCurrentFloatingPositioner` e todo o dispatch `Draw*`). O Dart nunca tinha essa
  reatribuição: o código antigo chamava `_dyn(element).calculatePrincipalStaff(staff, x1, x2)`, que
  sempre lançava (o único método parecido no modelo, `ControlElement.calculatePrincipalStaff` em
  `control_element.dart:81-86`, era um stub inventado — doc-comment citava `controlelement.cpp`, que
  não tem esse método, confirmado por grep — com assinatura de 1 argumento contra a chamada de 3), e o
  `catch` descartava o resultado mesmo no ramo hipotético sem exceção (`if (principal != null) {
  // ignore: unused }`). A maquinaria pesada (`CollectSpannedElements`) já existia portada como
  `_collectSpannedElements` em `slur_positioning.dart:754` — faltava só o método em si e o fio até o
  call site. Removido: 1 `_dyn`, 1 try/catch; deletado o stub inventado em `control_element.dart`.
  Porte novo: `Slur.calculatePrincipalStaff` em `slur_positioning.dart` (~40 linhas, cita
  `slur.cpp:479-515`).
- **OBS-B (o placar agregado do loop de SVG é cego a uma correção real que não cruza limiar):**
  `compare_svg --all` reportou os 6 números do placar **idênticos** antes/depois, mas 4 arquivos
  (`cross-staff-018/024`, `gracenote-016`, `slur-022`) mudaram byte-a-byte — mesma contagem de
  divergências por arquivo (94/87/81/88), só a magnitude de cada delta mudeu (2 ficaram mais perto do
  golden, 2 pioraram no desvio *máximo* do arquivo embora a *primeira* divergência tenha ficado mais
  perto do golden nos 4 — ex. `slur-022` primeira divergência 1332→1465 vs esperado 1462, ou seja
  130→3 de erro). É a assinatura de uma reatribuição correta e antes morta agora alcançando bugs de
  layout cross-staff preexistentes e não relacionados nesses mesmos arquivos — não um bug novo desta
  rodada. Só diff byte-a-byte revela isso; o placar agregado não.
- **OBS-C (achado descartável, fora do padrão de invenção-ao-lado-do-certo):**
  `ControlElement.calculatePrincipalStaff(Object? firstStaff)` era um stub com doc-comment citando um
  arquivo/método C++ inexistente — removido sem substituto na classe base, porque no C++ real o método
  só existe em `Slur`.

Sem exceção de cascata invocada: `S`/`N` agregados não subiram, então os três provas (a)/(b)/(c) nem
são necessárias — commit direto.

---

## 2026-09-05 — trilha MEMBRO — alvo `view_mensural.dart` drawLigatureNote (era `:522:0`, 51/621 arquivos, 5232 disparos)

D 423→419 (A 388→385  B 35→34  C 0→0)   Falhas 0→0   S/N agregado inalterado, byte-idêntico
(`git diff --stat` vazio em `test/golden/dart` e `test/golden/report` e `tool/SVG_VALIDATION.md` —
nenhum arquivo mudou, nem por número, nem byte-a-byte)   dart analyze 0 issues   dart test 701→701
— COMMIT

Diferente das três rodadas MEMBRO anteriores, aqui não era membro de **objeto de modelo** faltante —
era uma **opção do toolkit** nunca portada: `m_ligatureOblique` (`OptionIntMap`, `options.h:871`,
enum `option_LIGATURE_OBL` — `auto=0, straight, curved`, `options.h:79`), consumida por um switch
incondicional sem try/catch nenhum no C++ (`view_mensural.cpp:362-367`,
`switch (m_doc->GetOptions()->m_ligatureOblique.GetValue())`). O shell de opções Dart
(`lib/src/core/options_shell.dart`) simplesmente nunca tinha essa opção — `_dyn(doc!.getOptions())
.ligatureOblique` sempre lançava, 5232 vezes.

- **OBS-A (o catch mais disparado ainda não investigado escondia opção do toolkit ausente, não
  membro de objeto):** o fallback do catch (`straight = !isMensuralBlack`) reproduzia por coincidência
  exatamente o ramo `LIGATURE_OBL_auto` do C++ — por isso 51 arquivos disparavam o catch em toda nota
  de ligadura e o SVG já saía correto (nenhum arquivo do corpus seta `ligatureOblique` para um valor
  não-default, e a plumbing de opções via CLI/toolkit ainda não existe nesta fase — Fase 7). O porte
  remove a coincidência, não um bug visível — daí `S`/`N` ficarem byte-idênticos, o que aqui **não** é
  sinal de no-op: é o esperado quando a opção portada tem exatamente o mesmo default que o fallback
  antigo simulava.
- **OBS-B (nova categoria de achado — opção de toolkit, não membro de objeto):** as três rodadas
  MEMBRO anteriores eram sempre membro de **objeto de modelo** (campo/getter em `Clef`,
  `SystemMilestoneEnd`, `Slur`). Esta é a primeira vez que o alvo é uma **opção** (`OptionIntMap`) do
  `options_shell.dart`. Para as próximas rodadas: antes de assumir porte de membro de modelo, checar
  se a chamada `_dyn` é sobre `doc!.getOptions()` — nesse caso o padrão reutilizável já existe nos
  enums `Breaks`/`MensuralResp`/`Condense`/`SystemDivider` do mesmo arquivo.
- Porte: `enum LigatureOblique { auto, straight, curved }` +
  `late final Option<LigatureOblique> ligatureOblique` em `options_shell.dart` (ao lado de
  `ligatureAsBracket`); `LigatureOblique` adicionado ao `show` de `view.dart`; switch direto em
  `view_mensural.dart` citando `view_mensural.cpp:362-367`. Removidos: 1 `_dyn`, 2 declarações
  `dynamic`, 1 try/catch inteiro (sem substituto — o C++ não tem condicional de exceção ali).

Próxima rodada recomendada: `view_mensural.dart:948:0` (era 19 arquivos, 2858 disparos,
`getDrawingStemDir`) ou `view_control.dart:1588:0` (era 49 arquivos, 704 disparos,
`dynam.isSymbolOnly()`).

---

## 2026-09-05 — trilha MEMBRO — alvo `view_control.dart` drawDynam/drawDynamSymbolOnly (3 catches: `dynam.isSymbolOnly`/`getSymbolStr`/`getEnclosingGlyphs`, censo `:1588:0`/`:1749:0`/`:1801:0`, 49/43/43 arquivos, 704/627/627 disparos)

D 419→403 (A 385→372  B 34→31  C 0→0)   Falhas 0→0   S/N agregado inalterado
(612/621 estrutural, 248/621 numérico, 44 estruturais, 27371 numéricas, 373 divergentes — idêntico);
`git diff --stat` em `test/golden/dart`, `test/golden/report` e `tool/SVG_VALIDATION.md` vazio —
nenhum arquivo mudou, nem sequer byte-a-byte (checado em `test/corpus/dynam` isoladamente também:
174 divergências numéricas / 10 divergentes / 0 falhas, idêntico antes e depois via `git stash`)
dart analyze 0 issues   dart test 701→701 — COMMIT

Combinei as três catches indicadas pelo supervisor porque, depois de ler `dynam.h`/`dynam.cpp` no
C++, as três eram a mesma classe de achado do padrão já visto em Clef/SystemMilestoneEnd: nenhum
método real faltava por completo — faltava só portá-los de `Dynam` (nunca haviam sido escritos no
modelo Dart) e então religar os call sites já corretos que existiam ao lado, em `view_control.dart`,
como funções livres da própria `View` (`_dynamIsSymbolOnly`/`_dynamGetSymbolStr`) ou como blocos de
mapeamento manual duplicado (`getEnclosingGlyphs`).

- **OBS-A (qual catch estava escondendo o quê — `:1588:0`, `dynam.isSymbolOnly()`):** o catch
  escondia que `Dynam` (Dart) nunca teve `isSymbolOnly()`/`getSymbolStr()` — `Dynam::IsSymbolOnly()`
  (dynam.cpp:90-99) e `Dynam::GetSymbolStr()` (dynam.cpp:101-104) simplesmente não tinham porte no
  modelo (`control_elements_gen.dart`, classe `Dynam`, linha 760). Mas o ramo Dart **já calculava o
  resultado certo antes do `_dyn`**: `_dynamIsSymbolOnly(dynamText)` (função livre de
  `view_control.dart`, ex-linha 4035) é uma cópia byte-a-byte do método estático
  `Dynam::IsSymbolOnly(const u32string&)` (dynam.cpp:172-180), e `dynamText` vinha de
  `_dyn(dynam).getText()` — que também já era um método real e tipado (`TextListInterface.getText()`,
  `object.dart:1420`, usado sem `_dyn` em `view_page.dart:783/1063/1064`), só chamado via `_dyn` aqui
  por hábito local. O `try` em volta de `_dyn(dynam).isSymbolOnly()` só existia para "também respeitar
  o cache do modelo se existir" — um cache que nunca existiu — e o `catch` descartava sempre essa
  tentativa, deixando o valor já certo do helper livre. Mirrors `view_control.cpp:1841`
  (`dynam->IsSymbolOnly()`, chamada incondicional, sem try/catch no C++).
- **OBS-B (qual catch estava escondendo o quê — `:1749:0`, `dynam.getSymbolStr`):** mesmo padrão —
  `_dyn(dynam).getSymbolStr(singleGlyphs)` sempre lançava (método nunca existiu no modelo) e o catch
  caía para `_dynamGetSymbolStr(dynamText, singleGlyphs)`, outra função livre já correta (cópia da
  tabela de glifos SMuFL de `Dynam::GetSymbolStr(const u32string&, bool)`, dynam.cpp:182-260). Mirrors
  `view_control.cpp:1892` (`dynam->GetSymbolStr(singleGlyphs)`, sem condicional no C++).
- **OBS-C (qual catch estava escondendo o quê — `:1801:0`, `dynam.getEnclosingGlyphs`, o mais
  elaborado dos três):** aqui não havia nem um helper livre pronto — havia *três* tentativas de
  desestruturar o retorno de `_dyn(dynam).getEnclosingGlyphs()` (como `List`, como `Record`, como
  tupla com `.first`/`.second`) todas dentro do mesmo `try`, e o `catch` caía para um mapeamento manual
  de `_dyn(dynam).enclose` — mapeamento esse duplicado outra vez logo depois, num bloco
  "fallback if still 0 but has enclose" que também nunca era alcançável de outro jeito (o catch já
  preenchia os valores quando `enclose` existia). O C++ (`Dynam::GetEnclosingGlyphs`, dynam.cpp:106-116)
  é *idêntico* ao padrão já portado para `Fermata`/`Trill`/`Mordent`/`Turn` — mesmo switch, mesmos
  códigos SMuFL (`0xE26A-E26D`) — e esse padrão já existe como helper compartilhado `_encloseGlyphs`
  (`control_elements_gen.dart:83`, citado por doc-comment nos quatro outros `getEnclosingGlyphs()`).
  Faltava só dar a `Dynam` o mesmo `getEnclosingGlyphs() => _encloseGlyphs(this)` que as outras quatro
  classes já tinham, ao lado. Mirrors `view_control.cpp:1920` (`dynam->GetEnclosingGlyphs()`, sem
  condicional).
- **OBS-D (o padrão "campo já certo ao lado do `_dyn` morto" continua sendo a maioria dos achados
  MEMBRO, mas aqui em três variantes de "ao lado" diferentes):** Clef/SystemMilestoneEnd tinham o
  campo certo *na própria classe do modelo*; aqui o "já certo" estava espalhado em três lugares
  diferentes fora do modelo — duas funções livres da `View` (`_dynamIsSymbolOnly`/
  `_dynamGetSymbolStr`, cópias exatas dos métodos estáticos do C++) e um helper de modelo já
  compartilhado por quatro classes irmãs (`_encloseGlyphs`). Nenhum código de negócio novo foi escrito
  — os três métodos de `Dynam` adicionados (`isSymbolOnly`, `getSymbolStr`, `getEnclosingGlyphs`) são
  a mesma lógica já presente no arquivo, só realocada para o lugar que o C++ tem (a classe `Dynam`,
  não a `View`), e com o cache `_symbolStr` (`dynam.h:124`) explicitado como campo em vez de implícito
  na variável local `dynamText` compartilhada entre as duas chamadas.
- **OBS-E (por que `S`/`N` ficaram byte-idênticos, e por que isso não é um no-op suspeito aqui):**
  como em Clef e SystemMilestoneEnd, os fallbacks que os catches escondiam **já produziam exatamente
  o resultado certo** — não havia bug de fidelidade visível, só invenção de código morto ao lado do
  caminho correto. Diferente da rodada `Options.ligatureOblique` (onde o fallback só *coincidia* com
  o default do C++), aqui os fallbacks eram implementações corretas e completas dos próprios métodos
  do C++, não coincidências — então bater byte-a-byte no `test/corpus/dynam` isolado (via
  `git stash`/`git stash pop` antes/depois) e no `--all` completo é o resultado esperado, não um sinal
  de que nada mudou de verdade: o código morto (2 funções livres inteiras + 1 bloco de fallback
  duplicado + 3 try/catch) foi removido sem alterar nenhuma saída.
- Removidos: 10 `_dyn(...)` (`isSymbolOnly`, `getText`, `getSymbolStr`, `getEnclosingGlyphs`, `pair.$1`,
  `pair.$2`, `pair.first`, `pair.second`, `enc` ×2), 3 declarações `dynamic` (`pair`, `enc` ×2), 3
  try/catch inteiros, 2 funções livres inteiras (`_dynamIsSymbolOnly`, `_dynamGetSymbolStr` de
  `view_control.dart`, ~90 linhas) e 1 bloco de fallback duplicado morto ("Fallback if still 0 but has
  enclose"). Portado: `Dynam.isSymbolOnly()`/`isSymbolOnlyStr()`/`getSymbolStr()`/`symbolStrFor()`/
  `getEnclosingGlyphs()` em `control_elements_gen.dart` (dynam.h:74/80/90/124, dynam.cpp:90-116/172-260).
  `A` caiu 385→372 (13), `B` caiu 34→31 (3, um por try/catch removido), `D` 419→403.

Sem exceção de cascata invocada: `S`/`N` não subiram (nem sequer um arquivo mudou byte-a-byte), então
as três provas (a)/(b)/(c) não são necessárias — commit direto.

---

## 2026-09-05 — trilha MEMBRO — alvo `view_mensural.dart` stemDir (drawMaximaToBrevis + getMensuralStemDir, era `:948:0`/`:345:0`/`:349:0`)

D 403→391 (A 372→363  B 31→28  C 0→0)   Falhas 0→0   S/N inalterado, byte-idêntico (`--all` completo e
`git diff --stat` em `test/golden/dart`/`test/golden/report`/`SVG_VALIDATION.md` vazio; spot-check
`test/corpus/mensural`/`ligature`/`neume` também idêntico)   dart analyze 0 issues   dart test 701→701
— COMMIT

Dois catches do mesmo assunto (resolução de direção de haste em contexto mensural) corrigidos juntos:
`drawMaximaToBrevis` (era `:345:0`/`:349:0`, 19 arquivos, 668 disparos cada) e `getMensuralStemDir`
(era `:948:0`, 19 arquivos, 2858 disparos).

- **OBS-A (qual catch estava escondendo o quê — `drawMaximaToBrevis`):** o catch escondia que `Note`
  **já tinha** `stemDir` (via `AttStems`, `atts_shared.dart:4897`) e `getDrawingStemDir()`
  (`basic_elements.dart:1797`), ambos tipados. O `_dyn` tentava três formas (`hasStemDir`, `stemDir`,
  um `getStemDir()` que nunca existiu nem no C++ nem no Dart) num try/catch aninhado, quando o C++
  (`view_mensural.cpp:224-241`) é um `if`/`else if` incondicional sem try/catch nenhum.
- **OBS-B (qual catch estava escondendo o quê — `getMensuralStemDir`, e um bug real corrigido de
  quebra):** o catch escondia que `Layer` já tinha o método certo com **outro nome**:
  `getDrawingStemDirFor(LayerElement)` (`basic_elements.dart:1799`, já documentado como porte de
  `Layer::GetDrawingStemDir(const LayerElement*)`, `layer.cpp:301`). O `_dyn(layer)
  .getDrawingStemDir(note)` adivinhava nome/aridade errados e sempre lançava, caindo para o overload
  sem argumento (`layer.getDrawingStemDir()`) — semântica diferente da que o C++ pede. **Além disso**,
  o código antigo tinha um `if (hasStemDir && stemDir != none) return stemDir;` com uma condição extra
  (`&& stemDir != none`) que o C++ não tem (`if (note->HasStemDir()) stemDir = note->GetStemDir();` é
  incondicional a partir de `HasStemDir()`, sem checar o valor) — um bug real e independente do
  `_dyn`, corrigido de quebra ao reescrever a função linha a linha a partir de `view_mensural.cpp:731-746`.
  `S`/`N` ficarem byte-idênticos confirma que nenhum arquivo do corpus exercita
  `hasStemDir==true && stemDir==none`, então o bug era latente, não visível ainda.
- **OBS-C (padrão que se repete, quinta vez seguida):** quinta rodada MEMBRO consecutiva (depois de
  Clef.visible, SystemMilestoneEnd.start, Dynam.isSymbolOnly/getSymbolStr/getEnclosingGlyphs) em que
  nenhum membro precisou ser criado — só religar `_dyn`+catch ao acessor certo já existente, às vezes
  com nome ligeiramente diferente do que o call site tentava adivinhar (`getDrawingStemDir` vs
  `getDrawingStemDirFor`). `calculatePrincipalStaff` continua sendo a única exceção real (porte de
  verdade do zero) até agora.

Próxima rodada recomendada: `view_element.dart:723:0`/`:830:0`/`:834:0` (era 12 arquivos cada, 1030
disparos — `drawMultiRest` clef-lookup e cascatas de `numVisible`).

---

## 2026-09-05 — trilha MEMBRO — alvo `view_element.dart` drawMultiRest (era `:723:0`/`:830:0`/`:834:0`, 12/621 arquivos cada) — MELHOROU o placar de SVG

D 391→380 (A 363→355  B 28→25  C 0→0)   Falhas 0→0   S/N **melhorou**: Numérico 248→250/621 limpos,
divergências numéricas 27371→27173 (−198), Divergentes 373→371; Estrutural e divergências estruturais
inalterados (612/621, 44)   dart analyze 0 issues   dart test 701→701 — COMMIT (sem exceção de
cascata necessária, já que nada piorou)

Três catches da mesma função (`drawMultiRest`) corrigidos juntos: clef-lookup redundante (era `:723:0`)
e dois catches de `numVisible` (era `:830:0`/`:834:0`).

- **OBS-A (qual catch estava escondendo o quê — clef-lookup):** um segundo bloco
  `_dyn(layer).getNext?.call(element)` repetia, de outro jeito, uma busca de clef adjacente **já
  correta** três linhas acima (`layerChildren.indexOf`/`[idx+1]`, porte fiel de
  `layer->GetLast() != element` + `layer->GetNext(element)`, view_element.cpp:1351-1359) e descartava
  o resultado (`// already handled`) — nunca fazia nada mesmo sem lançar. Removido sem substituto.
- **OBS-B (qual catch estava escondendo o quê — numVisible, dois catches):** ambos escondiam que
  `_dyn(multiRest).getNumVisible()` (um **método**) nunca existiu — no C++ `GetNumVisible()` é membro
  *gerado* de `AttNumberPlacement`, mas o Dart expõe o mesmo dado como **campo** `numVisible` (`bool?`,
  `atts_cmn.dart:760`), já usado sem `_dyn` no mesmo arquivo (`bTrem.numVisible != false`, ~linha
  2823). `multiRest->GetNumVisible() != BOOLEAN_false` (view_element.cpp:1403) vira
  `multiRest.numVisible != false` — sem condicional no C++, sem try/catch no Dart.
- **OBS-C (bug real e independente, achado de quebra ao portar o gate — é o que melhorou o placar):**
  o cálculo de Y do número (view_element.cpp:1398-1417) usa `y1`/`y2` **já mutados** pelo ramo
  não-bloco em pauta de linhas ímpares (`y2 += unit; y1 += unit;`). O Dart tinha `y1` `final` (não
  mutável) e recomputava `finalY2`/`finalY1` do zero reaplicando a condição de linhas ímpares
  **incondicionalmente**, dobrando o deslocamento no ramo não-bloco e aplicando um deslocamento indevido
  no ramo de bloco. **Havia ainda um segundo bug, de tipo, sem relação com `_dyn`:** `dyn.numPlace as
  Staffrel?` usava o enum errado — `AttNumberPlacement.numPlace` é `StaffrelBasic?`, enum *diferente*
  de `Staffrel` (`mei_enums.dart:4760`/`:4786`). **E um terceiro, de lógica invertida:** o `min`/`max`
  do C++ (`std::min(minY, y2) - offset` / `std::max(maxY, y1) + offset`, view_element.cpp:1437-1439)
  virou `max`/`min` trocados no Dart antigo (`finalY2 < minY ? minY : finalY2` calcula `max`, não
  `min`). Corrigido tornando `y1` mutável, espelhando a mutação linha a linha, trocando o enum, e
  invertendo a comparação para bater com `std::min`/`std::max` de verdade — **confirmado por leitura
  direta do C++**, não só pelo resultado do placar. Efeito mensurável: `barline-010.svg` e
  `rest-009.svg` passaram de divergentes para limpos; `rest-012.svg` caiu de 84 para 24 divergências
  numéricas (resíduo restante é outro bug, `width="Nvu"`, fora de escopo desta rodada).
- **OBS-D (padrão que se repete, sexta vez — mas com uma lição nova):** de novo "membro faltante" era
  invenção de nome/aridade ao lado de um campo já certo. A lição nova: consertar o `_dyn` obrigou a
  reescrever a vizinhança inteira linha a linha contra o `.cpp`, e foi só nesse processo que os três
  bugs reais (mutação perdida, enum errado, min/max invertido) apareceram — "grep primeiro" resolve o
  `_dyn`, mas não substitui ler a função inteira contra o C++ quando o código ao redor também parece
  ad hoc.

Próxima rodada recomendada: recensar `tool/CATCH_CENSUS_fired.tsv` por conteúdo (números de linha
muito desatualizados após 6 rodadas MEMBRO) para achar o próximo maior alvo por arquivos/disparos.

---

## 2026-09-05 — trilha MEMBRO — varredura em lote de todos os catches restantes (bracketSpan/octave/ending/hairpin/dynam/_getFYRel/drawControlElementConnector/drawMRpt)

D 380→271 (A 355→268  B 25→3, das quais 1 falso-positivo do medidor — real é 2  C 0→0)   Falhas 0→0
S/N **melhorou**: Numérico 250→254/621 limpos, numéricas 27173→27098 (−75), Divergentes 371→367 (−4);
Estrutural e estruturais inalterados (612/621, 44)   dart analyze 0 issues   dart test 701→701 —
COMMIT (sem exceção de cascata necessária, nada piorou)

Em vez de recensar com instrumentação (só ~25 catches restavam, não valia o custo de ~700s), o
subagente releu os ~24 catches restantes diretamente (`grep -n "catch (e)"` em `lib/src/rendering/`)
e casou cada um por conteúdo/nome de função com as notas do `CATCH_CENSUS.md` original. Corrigiu quase
todos de uma vez, já que a maioria caiu no mesmo padrão "acessor certo já existe, com nome/aridade
diferente do que o `_dyn` tentava adivinhar".

- **OBS-1 (qual catch estava escondendo o quê — `Linestartendsymbol`/`Lineform`, bracketSpan/octave/
  ending, o maior grupo):** `AttLineRend`/`AttLineRendBase` (`atts_shared.dart:2194-2265`) já expunham
  `lstartsym`/`lendsym`/`lform` como campos tipados; o C++ chama `GetLstartsym()`/`GetLendsym()`/
  `GetLform()` sempre incondicionalmente (`view_control.cpp:596,609,884,931,934,1189,3222-3248`),
  retornando o default "unset" quando ausente. Os pares `_dyn`+catch adivinhavam nomes de getter
  inexistentes ao lado de campos que já funcionavam.
- **OBS-2 (achado real — `Octave.disPlace`, bug de tipo, não membro faltante):** `_getOctaveGlyph`
  fazia `octave.disPlace as Staffrel`, mas `AttOctaveDisplacement.disPlace` é `StaffrelBasic?`
  (`atts_shared.dart:3452`) — um enum **diferente** de `Staffrel`; o cast nunca poderia ter sucesso em
  nenhum arquivo. C++ confirma `data_STAFFREL_basic disPlace = octave->GetDisPlace()`
  (view_control.cpp:827). Como `drawOctave` já retorna cedo a menos que `@dis`+`@dis.place` estejam
  setados (view_control.cpp:822-824), nem o try/catch fazia falta — só o tipo certo.
- **OBS-3 (qual catch estava escondendo o quê — `drawEnding` isTop, achado do maior alcance e um bug
  de laço real e independente):** o catch escondia que `ScoreDef.endingRend` (`AttEndings`,
  atts_shared.dart:1534, `EndingsEndingrend?`) já existia tipado — o código fazia
  `_dyn(system.drawingScoreDef)?.endingRend` seguido de `.toString().contains('top')`. Reescrever
  linha a linha contra `view_control.cpp:3139-3153` revelou um bug real: o laço Dart tratava
  `staffDef == null` como "não escondido" e dava `break` no primeiro staff, enquanto o C++ só dá
  `break` quando `staffDef && !hidden` (senão continua até o fim, ficando com o **último** staff, não
  o primeiro). Corrigido para reproduzir exatamente esse comportamento (inclusive o "último staff se
  nenhum quebrar" — contraintuitivo, mas é o que o C++ faz).
- **OBS-4 (qual catch estava escondendo o quê — `_getFYRel`, achado do censo original confirmado):**
  era exatamente a suspeita já registrada no `CATCH_CENSUS.md` de abertura ("`_dyn(this)` incomum,
  sugere método real da View") — `View::GetFYRel` (view_element.cpp:2150-2177) é um método público
  real no C++, mas o Dart só tinha a versão privada `_getFYRel`; o `try` chamava
  `_dyn(this).getFYRel(...)` (nome público inexistente) só para cair sempre no fallback, que já era o
  porte completo e correto. Zero lógica nova — só apagar o try morto.
- **OBS-5 (qual catch estava escondendo o quê — `drawDynam` tstamp, invenção pura):**
  `_dyn(start).isTimestampAttr` nunca existiu em lugar nenhum do modelo (grep confirmou). O C++
  (view_control.cpp:1849-1854) não tem fallback nenhum — só `GetStart()->Is(TIMESTAMP_ATTR)`. As duas
  checagens extras (`dynam.tstamp`/`dynam.hasTstamp`) eram invenção pura ao lado do único teste real;
  removidas sem substituto.
- **OBS-6 (achado novo — nem todo catch "sem membro faltante" é achado-e-limpa; às vezes é fronteira
  de fase real, não invenção):** o par de catches de `Syl` (facsimile width/height,
  `view_element.dart`) é o primeiro caso desta série em que o membro C++ existe
  (`Syl::GetDrawingWidth/Height`, syl.cpp:134-146) e o Dart até tem a interface certa
  (`FacsimileInterface`), mas a infraestrutura de resolução (`PrepareFacsimileFunctor`) só roda para
  `doc.isFacs()`, não para o modo neume-lines que é o único a exercitar esse catch no corpus
  (`test/corpus/neume/neume-001.mei`). O subagente investigou a fundo (chegou a portar
  `FacsimileInterface.getWidth/getHeight`) e **reverteu** ao confirmar que `zone` fica `null` nesse
  modo — um erro ali quebraria `Falhas=0`. Ficou como dívida aberta e documentada (não como grafia
  nova) — os únicos 2 catches reais que sobram no diretório inteiro.
- **OBS-7 (segundo falso-positivo do medidor, mesma classe do MORTOS OBS-1):** `debt_report.dart`
  reporta B=1 a mais em `view_control.dart` mesmo depois de remover todos os catches reais do arquivo
  — é o texto `catch (e) { return; }` dentro de um comentário `//` na linha ~1903, que o grep de
  `catch (` do medidor não distingue de código. `D` real é 270, não 271 — mesma causa-raiz do MORTOS
  OBS-1 (casador por linha/regex, não por AST); vale corrigir o medidor numa rodada futura fora deste
  ciclo de portes.

**Dívida restante: só 2 catches reais em todo o diretório** (os dois da `Syl` facsimile, documentados
como dívida aberta legítima, não grafia). Não há mais alvo MEMBRO óbvio de porte de acessor — a
próxima rodada, se houver, é provavelmente **MÉTODO** (revisar `_dyn` restantes por método) ou resolver
o gap real de facsimile do OBS-6.

---

## 2026-09-05 — trilha MÉTODO — alvo `view_control.dart` drawEnding (maior dívida por método, 21→0)

D 271→250 (A 268→247  B 3→3, inalterado — 2 reais + 1 falso-positivo do medidor  C 0→0)   Falhas 0→0
S/N inalterado, byte-idêntico (`--all` e `git diff --stat` em `test/golden/dart`/`test/golden/report`/
`SVG_VALIDATION.md` vazio)   dart analyze 0 issues   dart test 701→701 — COMMIT

Primeira rodada MÉTODO de verdade: sem catch nenhum para guiar (só sobram os 2 catches reais de `Syl`
facsimile, fora de escopo), o alvo veio de `debt_report --by-method` — `drawEnding` era o método de
maior dívida do diretório (21 pontos, todos `_dyn`/`dynamic`, zero catch). Tipado por completo contra
`View::DrawEnding` (view_control.cpp:3055-3260); nenhum membro de modelo precisou ser criado — todos
os campos já existiam tipados em outro lugar (`SystemMilestoneInterface.systemMilestoneEnd`/
`.drawingMeasure`, `SystemMilestoneEnd.measure`, `Measure.getDrawingX()`/`.measureAligner`,
`FloatingObject.getDrawingY()`, `AttNNumberLike.n`/`hasN`, `AttLabelled.label`/`hasLabel`).

- **OBS-1 (sétima rodada seguida sem membro de modelo genuinamente faltante):** mais uma vez, "membro
  faltante" era nome/aridade inventados (`getEnd()`, `getMeasure()`, `getN()`) ao lado de campos já
  certos e tipados nos mixins corretos (`SystemMilestoneInterface`, `AttNNumberLike`, `AttLabelled`).
  Reforça a observação já registrada: a maior parte da dívida `_dyn` restante é esse padrão, não porte
  genuíno.
- **OBS-2 (um `_dyn` pode esconder comportamento inventado, não só membro inventado — sem catch
  nenhum para apontar):** o fallback `findDescendantByType`/`findAllDescendantsByType` para
  `firstMeasure`/`lastMeasure` não tinha contraparte C++ nenhuma (o C++ só `assert`+retorna,
  view_control.cpp:3064-3069) e, pior, era estruturalmente morto: quando `drawEnding` roda,
  `convertToPageBasedMilestone` já removeu os filhos reais de `ending`, então o fallback nunca
  encontraria nada mesmo se alcançado. Achado sem catch algum apontando para ele — só a releitura
  linha a linha revelou.
- **OBS-3 (bug real e independente, achado de novo forçando releitura linha a linha):** a lógica do
  texto da volta usava `if (endingText.isNotEmpty)` como gate em vez de espelhar
  `if (ending->HasN() || ending->HasLabel())` do C++ (view_control.cpp:3179), e tinha uma segunda
  tentativa morta de `getN()` no meio. Equivalente na prática para o corpus (confirmado byte-idêntico),
  mas um documento com `@n=""` (`HasN()==true`, string vazia) antes pulava o desenho do texto/
  parênteses inteiro onde o C++ ainda desenharia um label vazio-mas-presente — agora corrigido para
  bater exatamente.
- **OBS-4 (pré-atribuição morta, achada do mesmo jeito):** `int y1 = staff.getDrawingY();`
  imediatamente sobrescrita pela linha `_dyn` seguinte — sem contraparte C++ (view_control.cpp:3166 é
  uma única atribuição a partir de `ending`, nunca de `staff`). Removida junto com o `_dyn`.
- **OBS-5 (por que S/N ficou byte-idêntico aqui, e por que não é suspeito):** as três diferenças de
  comportamento real achadas (busca-fallback morta, pré-atribuição morta, gate de texto mal-condicionado)
  são todas comprovadamente inalcançáveis/no-op no corpus de 621 arquivos — os campos "caminho feliz"
  sempre estavam populados, e nenhum `<ending>` do corpus tem `@n=""`. `--all` e as quatro famílias-alvo
  confirmam byte-idêntico, consistente com remover scaffolding morta, não mudar comportamento vivo.

Próxima rodada recomendada: continuar MÉTODO pelo ranking de `debt_report --by-method` (próximo era
`drawHarm`, 20 pontos, antes desta rodada — recensar depois de aplicar esta).

---

## 2026-09-05 — trilha MÉTODO — alvo `view_control.dart` drawHarm (20→0)

D 250→229 (A 247→226  B 3→3 inalterado — 2 reais + 1 falso-positivo do medidor  C 0→0)   Falhas 0→0
S/N inalterado, byte-idêntico   dart analyze 0 issues   dart test 701→701 — COMMIT

Oitava rodada seguida sem membro de modelo genuinamente faltante — todo campo que `drawHarm` precisava
(`TimePointInterface.getStart`/`.getTstampStaves`, `ControlElement.getChildRendAlignment`,
`Object.id`/`.getFirst`/`.isClass`/`.children`, `LayerElement.getDrawingX`/`getDrawingRadius`,
`FloatingObject.getDrawingY`) já existia tipado em outro lugar. Tipado por completo contra
`View::DrawHarm` (view_control.cpp:2288-2349); também corrigido o único call site do dispatcher
(`drawHarm(dc, _dyn(element), ...)` → `drawHarm(dc, element as Harm, ...)`, `view_control.dart:101`).

- **OBS-1 (bug real e independente, achado forçando releitura linha a linha — sem catch nem `_dyn`
  apontando para ele):** `drawHarm` não tinha o guard de early-return do C++
  (`if (!harm->GetStart()) return;`, view_control.cpp:2296) — o código antigo fazia `(start as Object)`
  incondicionalmente quando `start` podia ser `null`, o que lançaria `TypeError` não capturado por
  nenhum try/catch. Nenhum `<harm>` do corpus de 621 arquivos exercita isso (daí byte-idêntico), mas
  era um risco de crash latente contra o gate `Falhas=0` em qualquer arquivo futuro. Corrigido para
  espelhar o C++ exatamente.
- **OBS-2 (ramo morto inventado, mesma espécie do `drawEnding`, e ele se repete em `drawDynam`):** o
  fallback `staffList.isEmpty` (reconstruindo a lista a partir do ancestral staff de `start`) não tem
  contraparte C++ nenhuma — `View::DrawHarm`/`DrawDynam`/`DrawReh`/etc. todos iteram
  `GetTstampStaves()` como está, sem substituto quando vazio. **Este mesmo fallback inventado também
  existe em `drawDynam`** (`view_control.dart` ~linha 1455-1459, dívida própria de 17 pontos daquele
  método, fora de escopo desta rodada) — quem pegar `drawDynam` a seguir já sabe o que procurar.
- **OBS-3 (checagem tripla-redundante inventada para "primeiro filho é `<fb>`"):** o código antigo
  tentava três formas diferentes (`_dyn`, uma busca morta `getFirst(ClassId.fb)` + reverificação de
  identidade em `children`, e um refetch final) onde o C++ é uma única checagem:
  `harm->GetFirst() && harm->GetFirst()->Is(FB)`. O passo morto do meio até carregava um comentário
  narrando a própria natureza de resíduo de investigação ("removed dead fb lookup... also check first
  child is fb via children list").
- **OBS-4 (por que S/N ficou byte-idêntico, e por que isso é esperado aqui):** os três achados reais
  (guard de null ausente, fallback de staffList inventado, checagem de FB tripla) são todos
  inalcançáveis no corpus atual de 621 arquivos — nenhum `<harm>` tem start não-resolvido, nenhum
  produz lista de tstamp-staff vazia, e o caminho de detecção de FB já concordava com a checagem única
  correta. Confirmado byte-idêntico no `--all` completo e em 5 famílias-alvo (`chord`, `figured-bass`,
  `harm`, `lyric`, `stem`).

Próxima rodada recomendada: continuar MÉTODO pelo ranking de `debt_report --by-method` — próximo era
`drawSyl` (18 pontos, dos quais 2 catches são os únicos reais do diretório, `Syl` facsimile,
documentados como dívida legítima aberta desde a rodada MEMBRO em lote — não forçar um fix inventado
ali) ou `drawDynam` (17 pontos, e já sabe-se que tem o mesmo fallback de staffList inventado do OBS-2).

---

## 2026-09-05 — trilha MÉTODO — alvo `view_control.dart` drawDynam (17→0)

D 229→210 (A 226→207  B 3→3 inalterado — 2 reais + 1 falso-positivo do medidor  C 0→0)   Falhas 0→0
S/N inalterado, byte-idêntico   dart analyze 0 issues   dart test 701→701 — COMMIT

Nona rodada seguida sem membro de modelo genuinamente faltante. Confirmado e removido, exatamente
como previsto pelo diário da rodada `drawHarm`: o mesmo fallback inventado `staffList.isEmpty` →
reconstrução via ancestral staff (sem contraparte em `view_control.cpp:1858-1859`, que itera
`GetTstampStaves()` como está). **Terceiro método seguido com esse padrão idêntico** (`drawEnding`,
`drawHarm`, agora `drawDynam`) — sugere que foi copiado-e-colado entre os três originalmente.

- **OBS-1 (segunda ocorrência do mesmo bug de guard ausente):** faltava
  `if (!dynam->GetStart()) return;` (view_control.cpp:1837) — a mesma classe de bug encontrada em
  `drawHarm` (view_control.cpp:2296), um cast incondicional de `start` nullable mais adiante na
  função. Nenhum `<dynam>` do corpus exercita isso, então byte-idêntico é o esperado.
  **Recomendação para quem pegar `drawReh` ou outro `Draw*` de `TimePointInterface` a seguir: grep
  por `if (!X->GetStart()) return;` no início da função C++ correspondente antes de mais nada — é a
  terceira vez que esse guard específico falta no Dart.**
- **OBS-2 (três tentativas redundantes de parsing de string para `enclose`/`place`, mesmo padrão de
  sempre):** `_dyn(dynam).enclose`/`hasEnclose`/`getEnclose?.call()` com `.toString().contains(...)`
  e `_dyn(dynam).place` com `.toString().contains('between')` — ambos campos já tipados
  (`AttEnclosingChars.enclose`/`hasEnclose`, `AttPlacementRelStaff.place`, `atts_shared.dart:1501/3982`)
  usados sem `_dyn` em vários outros `draw*` do mesmo arquivo.
- **OBS-3 (por que S/N ficou byte-idêntico, e por que isso é esperado):** os dois achados reais
  (guard ausente, fallback inventado) são inalcançáveis no corpus atual — consistente com toda a
  série de rodadas MÉTODO desde `drawEnding`.

`drawDynamSymbolOnly`'s parâmetro `dynamic dynam` também tipado de quebra (trivial, downstream direto).

Próxima rodada recomendada: continuar MÉTODO pelo ranking — próximo não-`drawSyl` era `drawTempo`
(13 pontos, 1 catch) ou `drawTimeSpanningElement` (11 pontos). Ao pegar qualquer método que use
`TimePointInterface`/`GetStart()`, checar o guard `if (!X->GetStart()) return;` primeiro (OBS-1).

---

## 2026-09-05 — trilha MÉTODO — alvo `view_control.dart` drawTempo (13→0)

D 210→196 (A 207→194  B 3→2 — o catch "1" era falso-positivo de comentário, confirmado e descontado
C 0→0)   Falhas 0→0   S/N inalterado, byte-idêntico   dart analyze 0 issues   dart test 701→701 —
COMMIT

Décima rodada seguida sem membro genuinamente faltante. **O catch contado pelo medidor era texto
dentro de um comentário** (`catch (e) { return; }` narrando um fix anterior) — terceira instância
confirmada desse falso-positivo (MORTOS OBS-1, lote MEMBRO OBS-7, agora aqui), o medidor `debt_report`
ainda não foi corrigido para isso (fora do escopo de rodadas de porte).

- **OBS-1 (quarta ocorrência do fallback `staffList.isEmpty` inventado, copiado-e-colado):** confirma
  que o padrão se estende de `drawEnding`→`drawHarm`→`drawDynam`→`drawTempo`, mesma forma
  (`getFirstAncestor(ClassId.staff)`), mesma ausência no C++ correspondente
  (view_control.cpp:2758), mesmo no-op completo no corpus atual.
- **OBS-2 (guard `GetStart()` já existia aqui, ao contrário de `drawHarm`/`drawDynam`):** adicionado
  numa tarefa anterior a este loop (2026-08-29-01) — confirma que vale checar por método, não assumir
  ausente.
- **OBS-3 (achado incidental — `Tempo.getDrawingXRelativeToStaff` já estava portado por completo):**
  o `_dyn` ao lado dele (`control_elements_gen.dart:2240`) nunca precisou existir — o método certo já
  estava lá, só não chamado diretamente.
- **OBS-4 (candidato para rodada futura, fora de escopo aqui):** `_convertHalign` (`view_control.dart`,
  ainda parâmetro `dynamic halign`) é o único sobrevivente de checagem de string no bairro de
  `drawTempo`/`drawDynam`/`drawHarm` — agora que todo call site do arquivo já passa um enum real
  (`Horizontalalignment`), dá para tipar o parâmetro e descartar o ramo de string, um ponto de dívida
  isolado e pequeno.

Próxima rodada recomendada: `drawTimeSpanningElement` (11 pontos) ou `drawOctave`/`drawTextEnclosure`/
`drawNote` (9 pontos cada). Ao pegar qualquer método com `staffList`/`GetTstampStaves`, checar o
fallback inventado do OBS-1 primeiro — já apareceu 4 vezes seguidas.

---

## 2026-09-05 — trilha MÉTODO — alvo `view_control.dart` drawTimeSpanningElement (11→0, ALTO ALCANCE)

D 196→185 (A 194→183  B 2→2 inalterado — 2 reais de `Syl`  C 0→0)   Falhas 0→0   S/N inalterado,
byte-idêntico (`--all` completo rodado pelo supervisor: 612/621 estrutural, 254/621 numérico, 44
estruturais, 27098 numéricas, 367 divergentes, 0 falhas — idêntico ao baseline)   dart analyze 0
issues   dart test 701→701 — COMMIT

Alvo de **alto alcance**: `drawTimeSpanningElement` é compartilhado por slur, tie, hairpin,
bracketSpan, octave, trill extension, ending, dir, dynam, gliss, pedal, tempo, beamspan,
pitchInflection — o supervisor rodou o `--all` (~700s) e o `dart test` pessoalmente, além de conferir
o diff linha a linha contra `view_control.cpp:183-320`, dada a superfície ampla.

- **OBS-1 (interface fallback inventado — `TimeSpanningInterface ?? TimePointInterface`):** o C++
  (`view_control.cpp:196-197`) só tem `TimeSpanningInterface *interface =
  element->GetTimeSpanningInterface(); assert(interface);` — sem fallback nenhum. Toda `ClassId` que
  chega nesta função mistura `TimeSpanningInterface` de verdade (confirmado em 7 headers C++:
  `dir.h`, `dynam.h`, `tempo.h`, `pedal.h`, `syl.h`, `trill.h`, `f.h`). Substituído por
  `assert(element is TimeSpanningInterface)` + cast direto, espelhando o C++ em vez de inventar
  fallback de `is`-check.
- **OBS-2 (quinta e maior instância do fallback `staffList.isEmpty` inventado):** diferente das quatro
  anteriores (`drawEnding`/`drawHarm`/`drawDynam`/`drawTempo`, cada uma com um `getFirstAncestor`
  simples), aqui o código reimplementava a **lógica inteira** de resolução `@staff`/`@place="between"`
  de `TimePointInterface.getTstampStaves` **uma segunda vez, pior** (via `_dyn(element).staff`/
  `.place` com parsing de string) — quando `getTstampStaves` (`time_interface.dart`, já mirrora
  `timeinterface.cpp:123-181` completo, staff/place/ancestor-de-start/staff-único-na-medida) já
  resolvia tudo isso corretamente. O C++ (`view_control.cpp:315`) não tem fallback nenhum — lista
  vazia só significa que o `for` não itera e a função retorna implicitamente. Confirma que o padrão
  generaliza além de um `getFirstAncestor` de uma linha: quem escreveu esses `draw*` tratava "lista
  vazia" como algo a sempre mascarar, mesmo quando a função de baixo já tinha contrato de resultado
  vazio implícito (não erro).
- **OBS-3 (desvio de forma nova — não `_dyn`, não catch, só indireção desnecessária):**
  `parentSystem1`/`parentSystem2` passavam por `Measure` (`start.getStartMeasure()?.getFirstAncestor
  (system)`) em vez do C++'s `start->GetFirstAncestor(SYSTEM)` direto (view_control.cpp:223-224).
  Equivalente para uma árvore bem formada, mas fácil de virar bug de cache obsoleto; corrigido para a
  forma literal do C++.
- **OBS-4 (byte-idêntico é esperado aqui, não suspeito):** todo ramo removido (fallback de interface,
  fallback de measure, parsing de string do barline, reconstrução inteira de staffList) era
  comprovadamente inalcançável ou preservava a lógica no corpus de 621 arquivos — mesma classe de
  achado das quatro rodadas MÉTODO anteriores.

Próxima rodada recomendada: `drawOctave`/`drawTextEnclosure`/`drawNote` (9 pontos cada, ranking
pós-commit a confirmar).

---

## 2026-09-05 — trilha MÉTODO — alvo `view_element.dart` drawNote (9→0, função de maior tráfego do renderer)

D 185→176 (A 183→174  B 2→2 inalterado — 2 reais de `Syl`  C 0→0)   Falhas 0→0   S/N inalterado,
byte-idêntico (`--all` rodado pelo supervisor pessoalmente: 612/621 estrutural, 254/621 numérico, 44
estruturais, 27098 numéricas, 367 divergentes, 0 falhas — idêntico)   dart analyze 0 issues   dart
test 701→701 — COMMIT

`drawNote` é executado por quase todo arquivo do corpus — supervisor rodou `--all` e `dart test`
pessoalmente e conferiu o diff linha a linha contra `view_element.cpp:1473-1581` antes de commitar,
dado o alcance.

- **OBS-1 (nono round sem membro genuinamente faltante):** todos os 9 pontos resolveram para
  campos/métodos já tipados nos mixins que `Note` já declara (`AttColoration.colored`,
  `AttNoteHeads.headColor`/`headMod`/`headVisible`, `StemmedDrawingInterface.getDrawingStemDir()`,
  `DurationInterface.isMensuralDur`, `Note.getDrawingDur()`/`flippedNotehead`/`hasStemSameasNote()`,
  `LayerElement.isInBeam()`).
- **OBS-2 (bug real e independente — guard ausente, mesma família dos bugs de `GetStart()` de
  `drawHarm`/`drawDynam`):** o deslocamento X da cabeça de nota (view_element.cpp:1505-1509) exige
  `HasStemSameasNote() && GetFlippedNotehead()` — o Dart só checava `flippedNotehead`. Hoje latente:
  o único setter de `flippedNotehead` em toda a árvore (`Note.calcNoteHeadShiftForSameasNote`,
  `basic_elements.dart:2577`) só é chamado em notas que já têm `stemSameasNote` setado, então
  `flippedNotehead == true` sempre implica `hasStemSameasNote() == true` hoje — mas um futuro setter
  sem esse pareamento quebraria em silêncio. Corrigido para espelhar o C++ exatamente.
- **OBS-3 (byte-idêntico esperado, confirmado em 5 famílias + `--all`):** `note`, `chord`, `accid`,
  `stem`, `beam` idênticos antes/depois via `git stash`/`pop`, mais o `--all` completo — consistente
  com o achado do OBS-2 ser inalcançável no corpus atual.

Próxima rodada recomendada: `drawOctave`/`drawTextEnclosure` (9 pontos cada — `drawNote` já feito).

---

## 2026-09-05 — trilha MÉTODO — alvo `view_control.dart` drawOctave (9→0) — MELHOROU o placar de SVG

D 176→167 (A 174→165  B 2→2 inalterado — 2 reais de `Syl`  C 0→0)   Falhas 0→0   S/N **melhorou**:
numéricas 27098→27090 (−8), demais campos inalterados (612/621 estrutural, 254/621 numérico, 44
estruturais, 367 divergentes)   dart analyze 0 issues   dart test 701→701 — COMMIT (sem exceção de
cascata necessária, placar melhorou)

Décima primeira rodada seguida sem membro genuinamente faltante — mas com um **bug real e
independente confirmado pelo supervisor contra o C++**.

- **OBS-1 (bug real, verificado linha a linha):** a variável `disPlace`, por estar `dynamic`,
  escondia uma comparação contra o enum errado: `disPlace == Staffrel.above` em vez de
  `disPlace == StaffrelBasic.above` (`view_control.cpp:868`,
  `const int yCode = (disPlace == STAFFREL_basic_above) ? ...`). Em Dart, comparar valores de dois
  enums *diferentes* nunca é `true`, então `isAbove` era **sempre `false`** — todo
  `<octave dis.place="above">` do corpus era desenhado com a geometria de "below" (posição Y do
  glifo). O helper irmão `_getOctaveGlyph` já usava `StaffrelBasic.above` corretamente (corrigido numa
  rodada MEMBRO anterior) — a mesma variável, só que local a `drawOctave`, nunca recebeu o mesmo
  tratamento. Confirmado pelo supervisor lendo `view_control.cpp:815-870` diretamente.
- **OBS-2 (lição para achar esse tipo de bug em rodadas futuras):** quando uma variável `dynamic` é
  comparada a um enum, sempre checar se existe uma variante `*Basic` do mesmo enum MEI (`Staffrel`/
  `StaffrelBasic` é o par conhecido; podem existir outros) já usada corretamente em outro método da
  mesma classe — foi exatamente comparar contra `_getOctaveGlyph` que expôs o bug aqui.
  `Options.octaveNoSpanningParentheses`/`octaveAlternativeSymbols`, `TimeSpanningInterface.getEnd()`/
  `hasEndid`, `BoundingBox.hasContentBB()`/`getContentX2()`, `Object.id` — todos já tipados, o `_dyn`
  só adivinhava nomes/casts desnecessários.
- **OBS-3 (efeito misto por arquivo, agregado melhora — mesma assinatura do `calculatePrincipalStaff`):**
  `octave-001` ganhou 1 divergência a mais mas com magnitude de erro bem menor (360→270); `octave-003`
  melhorou magnitude (296→156) com mesma contagem; `octave-004` melhorou tanto contagem (106→97)
  quanto magnitude. `octave-002` (só `dis.place="below"`) ficou byte-idêntico, como esperado —
  confirma que só o ramo "above", antes sempre-falso, mudou.

Próxima rodada recomendada: `drawTextEnclosure` (9 pontos).

---

## 2026-09-05 — trilha MÉTODO — alvo `view_control.dart` drawTextEnclosure (9→0)

D 167→158 (A 165→156  B 2→2 inalterado — 2 reais de `Syl`  C 0→0)   Falhas 0→0   S/N inalterado,
byte-idêntico   dart analyze 0 issues   dart test 701→701 — COMMIT

Décima segunda rodada seguida sem membro genuinamente faltante — todos os 4 tipos de acesso
(`Options.textEnclosureThickness`, `TextDrawingParams.enclosedRend` como `List<TextElement>`,
`BoundingBox.getContentLeft/Right/Bottom/Top`) já existiam tipados.

- **OBS-1 (achado de forma nova — ramo inventado sem catch nenhum apontando, e estruturalmente
  inalcançável, não só não-exercitado):** o fallback `rend.rend` com parsing de string e o ramo
  inteiro de desenho `Textrendition.tbox` não têm contraparte C++ nenhuma. O C++
  (`view_control.cpp:3273`) só lê `params.m_enclose` — um valor setado **uma única vez por rend**, em
  `View::DrawRend` (`view_text.cpp:463-466`) — nunca re-deriva por elemento dentro do laço de
  `DrawTextEnclosure`. Diferente da série `staffList.isEmpty` (que era "não exercitado no corpus
  atual"), este é **impossível de alcançar por construção**: `params.enclose` só pode ser
  `Textrendition.none` quando `enclosedRend` está vazio (nada para iterar).
- **OBS-2 (achado real sobre o próprio C++, não bug do Dart):** `Rend::HasEnclosure()`
  (`rend.cpp:90`) reconhece `TEXTRENDITION_tbox` como "tem enclosure" para fins de layout/espaçamento
  em `DrawRend`, mas o switch de `View::DrawTextEnclosure` **não tem case `tbox`** — ou seja, o
  próprio C++ nunca desenha forma nenhuma para `tbox`, só reserva espaço. O ramo antigo do Dart
  (`tbox` → `drawNotFilledRectangle`) não era porte faltante, era **desvio do C++** — removê-lo faz o
  Dart bater com o comportamento real (ainda que surpreendente) da referência. Achado que vale
  documentar caso uma tarefa futura mexa em `tbox` e assuma que deveria desenhar algo — não deveria.
- **OBS-3 (confirmado morto nos 7 arquivos do corpus que usam essas renditions):** grep por
  `rend="box"|"dbox"|"circle"|"tbox"` nos 621 arquivos achou 7 (`barline-010`, `mnum-001`, `dir-008`,
  `rend-002`, `rend-003`, `ossia-004`, `score-013`) — todos byte-idênticos antes/depois, confirmando
  que `params.enclose` já vinha certo de `DrawRend` em todo caso real.

Próxima rodada recomendada: recensar `debt_report --by-method` (próximo era `drawDotLayer`/
`drawFConnector`/`drawPitchInflection`/`_getRestGlyph`/`drawStem`, 7 pontos cada).
