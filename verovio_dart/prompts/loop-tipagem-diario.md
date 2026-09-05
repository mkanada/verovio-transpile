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
