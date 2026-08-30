# Índice dos prompts de execução — port Verovio 6.2.0 → Dart

**Como usar:** abra uma sessão nova do Claude Code em `/home/mauricio/rust_projects/verovio-transpile`
e cole o conteúdo de **um** arquivo de prompt como primeira mensagem — **um prompt por sessão**, na
ordem desta tabela. Cada prompt manda ler `00-MESTRE.md` antes de tudo, grava um relatório em
`reports/<id>.md` ao terminar e marca o checkbox correspondente no `PLANO.md`.

Marque a coluna **Status** (☐ → ☑) aqui à medida que cada prompt for concluído.

Os checkboxes do `PLANO.md` são mais grossos que esta série — um item de lá pode cobrir três ou
quatro prompts. A regra (detalhada em `00-MESTRE.md` §9) é marcar `[x]` só quando a última tarefa
do item terminar, e anotar o progresso no meio do caminho.

---

## Antes de disparar o primeiro prompt

| Arquivo | O que é |
|---|---|
| [`00-MESTRE.md`](00-MESTRE.md) | **Convenções obrigatórias.** Todo prompt de tarefa manda ler primeiro. Auto-suficiente. |
| [`AUDITORIA.md`](AUDITORIA.md) | Estado real medido em 2026-08-26, com o comando por trás de cada número. É de onde saiu esta decomposição. |
| [`../../PLANO.md`](../../PLANO.md) | Roadmap de escopo, reconciliado com o código em 2026-08-26. |
| [`META_PROMPT.md`](META_PROMPT.md) | O prompt que gerou esta série. Histórico; não é de execução. |
| [`../../cpp_probe/README.md`](../../cpp_probe/README.md) | A máquina de extração de dados de referência do C++. Convenções resumidas em `00-MESTRE.md` §6-bis. |
| [`META_PROMPT_DADOS_CPP.md`](META_PROMPT_DADOS_CPP.md) | O prompt que construiu a extração e reescreveu os prompts da Fase 4. Histórico. |

### Baseline de 2026-08-27 (o ponto de partida de tudo)

| Métrica | Valor |
|---|---|
| `dart analyze` | 10 issues (8 em `tool/_scratch_*`, 2 em `test/`) |
| `dart test` | **281 testes**, todos passando, ~17 s |
| `tool/validate_layout.dart` | 46 arquivos, **24/30 timemaps** batendo com o C++ |
| Comparação de SVG | **0/623** — o harness ainda não existe (tarefa `05-00`) |
| Functors portados | **69 de 135** (60 genuinamente faltando) |
| Fixtures do C++ | `test/fixtures/cpp/` — **1** (`EXEMPLO`, a prova da máquina); 9 tarefas cobertas por `04-00`–`04h` |
| `MEIOutput` | **0%** — `getMEI()` devolve o input cru |

Dois defeitos medidos em 2026-08-27 com a máquina de extração, **antes** de qualquer correção, e que
a tarefa `04-00` existe para fechar:

- `DEFINITION_FACTOR` nunca aplicado: `Doc.getDrawingUnit(100)` devolve **9** no Dart e **90** no
  C++. Atinge 7 opções, 65 chamadas, 18 arquivos de `lib/src/`.
- Alinhador horizontal: **166 dos 2107 compassos** do corpus (7,9%) com `maxTime = 0`, e **8 dos 621
  arquivos** com duração total 0 apesar de terem música.

### Três armadilhas que valem para a série inteira

1. **Não rode `python3 tool/gen_elements.py`.** Ele não reproduz os `*_gen.dart` versionados e
   **apaga código escrito à mão**. Só a tarefa `04i` deve tocá-lo. (`AUDITORIA.md` §6)
2. **Não rode `dart format lib/ test/ tool/`.** O formatador atual reescreve 53 arquivos que
   ninguém tocou e leva o `analyze` de 10 para 20 issues. Formate só os arquivos da sua tarefa.
   (`00-MESTRE.md` §3)
3. **Nunca ajuste o esperado para o teste passar.** A política de divergência está em
   `00-MESTRE.md` §7: investigue, e se travar, documente com hipótese de causa e siga.
4. **Instrumentação do C++ é só acréscimo.** Um patch em `cpp_probe/patches/` não pode remover nem
   alterar linha do C++ (`grep -c '^-[^-]' <patch>` = 0), a semente de `@xml:id` é fixa em `12345`,
   e o binário instrumentado tem de produzir SVG **idêntico** ao do limpo. Um patch com lógica
   corrompe silenciosamente todo fixture que dele derivar. (`00-MESTRE.md` §6-bis)

---

## A série

### Fase 4 — fechamento do layout (11 prompts)

Portar os functors que faltam **antes** de trocar a matemática de bbox: o layout precisa estar
completo em functors antes da virada da tarefa `05-12`. Fecha com higiene de infraestrutura (`04i`)
e revalidação medida (`04j`).

Abre com `04-00`, que **não porta functor nenhum**: põe em paridade com o C++ as duas entradas de
que todas as outras dependem — a família `Doc::GetDrawing*` e os tempos de alinhamento. Toda a
aritmética de `04a`–`04h` é `… * drawingUnit`; fazê-las sobre uma base 10× errada é acertar functor
por functor contra um alvo móvel e refazer depois.

| id | Título | Depende de | Status | Relatório |
|---|---|---|---|---|
| [`04-00`](04-00-fase4-base-unidades-alinhamento.md) | **Base numérica**: fator de definição das opções + tempos/posições de alinhamento | — | ☐ | `reports/04-00.md` |
| [`04a`](04a-fase4-adjust-layers-dots.md) | AdjustLayersFunctor + AdjustDotsFunctor | 04-00 | ☐ | `reports/04a.md` |
| [`04b`](04b-fase4-adjust-accidx-artic.md) | AdjustAccidXFunctor + AdjustArticFunctor + AdjustArticWithSlursFunctor | 04a | ☐ | `reports/04b.md` |
| [`04c`](04c-fase4-adjust-tuplets.md) | AdjustTupletsXFunctor + AdjustTupletsYFunctor + AdjustTupletNumOverlapFunctor + AdjustTupletWithSlursFunctor | 04a e 04b | ☐ | `reports/04c.md` |
| [`04d`](04d-fase4-adjust-beams.md) | AdjustBeamsFunctor | 04a–04c | ☐ | `reports/04d.md` |
| [`04e`](04e-fase4-adjust-harm-tempo-syl.md) | AdjustHarmGrpsSpacingFunctor + AdjustTempoFunctor + AdjustSylSpacingFunctor | 04a–04d | ☐ | `reports/04e.md` |
| [`04f`](04f-fase4-adjust-xoverflow-cache.md) | AdjustXOverflowFunctor + CacheHorizontalLayoutFunctor + CalcSpanningBeamSpansFunctor | 04a–04e | ☐ | `reports/04f.md` |
| [`04g`](04g-fase4-ossia-neumex-ledgerlines.md) | AdjustOssiaStaffDefFunctor + AdjustNeumeXFunctor + CalcLedgerLinesFunctor | 04a–04f | ☐ | `reports/04g.md` |
| [`04h`](04h-fase4-scoredef-optimize-ossia.md) | ScoreDefOptimizeFunctor + ScoreDefSetOssiaFunctor | 04a–04g | ☐ | `reports/04h.md` |
| [`04i`](04i-fase4-higiene-geradores-registro.md) | Higiene: gerador de elementos, registros do ObjectFactory e bug do validate_layout | 04a–04h | ☐ | `reports/04i.md` |
| [`04j`](04j-fase4-revalidacao.md) | Revalidação da Fase 4 | 04a–04i | ☐ | `reports/04j.md` |

### Fase 5 — View e renderização SVG (26 prompts)

> ⚠️ **Estes 26 prompts foram executados e a fase foi declarada 100% concluída em 2026-08-29 — contra
> um harness de comparação inválido.** Não confie nos relatórios de `05-12` a `05-25` sem antes ler
> a seção **Fase 5 (reabertura)**, logo abaixo desta tabela: ela mede o que ficou de fato e traz os
> 11 prompts que refazem o trabalho.

A ordem é de dependência estrita. O harness de comparação (`05-00`) vem **antes** de qualquer
`View` — é a métrica que todas as tarefas seguintes movem para cima. A tarefa **`05-12` é a virada**:
liga o layout ao `View` real, deleta `lib/src/rendering/headless_extents.dart` e revalida a Fase 4
inteira. Espere regressões ali; é o objetivo. **`05-12` é também a única tarefa da Fase 5 com
extração preventiva de fixtures do C++** (as bounding boxes que o `BBoxDeviceContext` acumula não
aparecem em saída final alguma — regra de decisão em `00-MESTRE.md` §6-bis); no resto da fase os
623 goldens já são o fixture, e a instrumentação volta como recurso reativo da caçada em `05-25`.
A `05-17` fecha os 4 valores divergentes que a 04c deixou esperando os dados de `BeamSegment`.

| id | Título | Depende de | Status | Relatório |
|---|---|---|---|---|
| [`05-00`](05-00-fase5-harness-svg.md) | Harness de comparação de SVG | 04j | ☑ | `reports/05-00.md` |
| [`05-01`](05-01-fase5-devicecontext-resources.md) | DeviceContext e Resources: fechar as lacunas contra o C++ | 05-00 | ☐ | `reports/05-01.md` |
| [`05-02`](05-02-fase5-svgdc-estrutura.md) | SvgDeviceContext: documento, página e grupos gráficos | 05-01 | ☐ | `reports/05-02.md` |
| [`05-03`](05-03-fase5-svgdc-primitivas.md) | SvgDeviceContext: primitivas geométricas, pen e brush | 05-02 | ☐ | `reports/05-03.md` |
| [`05-04`](05-04-fase5-svgdc-texto-glifos.md) | SvgDeviceContext: texto, música e referências de glifo | 05-03 | ☐ | `reports/05-04.md` |
| [`05-05`](05-05-fase5-bbox-device-context.md) | BBoxDeviceContext: fechar as lacunas | 05-04 | ☑ | `reports/05-05.md` |
| [`05-06`](05-06-fase5-view-esqueleto.md) | View: esqueleto, coordenadas e offsets | 05-05 | ☑ | `reports/05-06.md` |
| [`05-07`](05-07-fase5-view-graph.md) | view_graph.cpp: primitivas gráficas do View | 05-06 | ☑ | `reports/05-07.md` |
| [`05-08`](05-08-fase5-view-page-a.md) | view_page.cpp (A): DrawCurrentPage, sistema e despacho de filhos | 05-07 | ☑ | `reports/05-08.md` |
| [`05-09`](05-09-fase5-view-page-b.md) | view_page.cpp (B): scoreDef, staffGrp, rótulos e colchetes | 05-08 | ☐ | `reports/05-09.md` |
| [`05-10`](05-10-fase5-view-page-c.md) | view_page.cpp (C): compasso, barras de compasso, número de compasso e ossia | 05-09 | ☐ | `reports/05-10.md` |
| [`05-11`](05-11-fase5-view-page-d.md) | view_page.cpp (D): pentagrama, linhas e linhas suplementares | 05-10 | ☐ | `reports/05-11.md` |
| [`05-12`](05-12-fase5-virada-view-real.md) | VIRADA: ligar o layout ao View real e deletar headless_extents.dart | 05-05 e 05-11 | ☐ | `reports/05-12.md` |
| [`05-13`](05-13-fase5-view-element-notas.md) | view_element.cpp (A): despacho, notas, acordes, hastes e bandeirolas | 05-12 | ☐ | `reports/05-13.md` |
| [`05-14`](05-14-fase5-view-element-accid.md) | view_element.cpp (B): acidentes, articulações, armaduras e fórmulas de compasso | 05-13 | ☐ | `reports/05-14.md` |
| [`05-15`](05-15-fase5-view-element-pausas.md) | view_element.cpp (C): pausas, espaços, ponto, custos e claves | 05-14 | ☐ | `reports/05-15.md` |
| [`05-16`](05-16-fase5-view-element-repeticoes.md) | view_element.cpp (D): repetições, tremolos, grace groups, sílabas e versos | 05-15 | ☐ | `reports/05-16.md` |
| [`05-17`](05-17-fase5-view-beam.md) | view_beam.cpp: barras de ligação e tremolo medido | 05-16 | ☐ | `reports/05-17.md` |
| [`05-18`](05-18-fase5-view-tuplet-slur.md) | view_tuplet.cpp + view_slur.cpp: quiálteras e ligaduras de expressão | 05-17 | ☐ | `reports/05-18.md` |
| [`05-19`](05-19-fase5-view-text.md) | view_text.cpp: elementos de texto, rend, figuras e running elements | 05-18 | ☐ | `reports/05-19.md` |
| [`05-20`](05-20-fase5-view-control-a.md) | view_control.cpp (A): framework de spanning, ligaduras de valor e extensores | 05-19 | ☐ | `reports/05-20.md` |
| [`05-21`](05-21-fase5-view-control-b.md) | view_control.cpp (B): dinâmicas, andamento, cifras, ensaio e baixo cifrado | 05-20 | ☐ | `reports/05-21.md` |
| [`05-22`](05-22-fase5-view-control-c.md) | view_control.cpp (C): ornamentos, símbolos isolados e elementos de sistema | 05-21 | ☐ | `reports/05-22.md` |
| [`05-23`](05-23-fase5-view-mensural.md) | view_mensural.cpp: notação mensural e ligaduras | 05-22 | ☐ | `reports/05-23.md` |
| [`05-24`](05-24-fase5-view-neume-tab.md) | view_neume.cpp + view_tab.cpp: notação neumática e tablatura | 05-23 | ☐ | `reports/05-24.md` |
| [`05-25`](05-25-fase5-cauda-divergencias.md) | Fase 5: perseguir a cauda de divergências até a igualdade numérica | 05-24 | ☐ | `reports/05-25.md` |

### Fase 5 (reabertura) — 11 prompts, escritos em 2026-08-29

A Fase 5 foi declarada concluída em 2026-08-29 com `489/623` arquivos limpos. A auditoria do mesmo
dia mediu o número real: **`0/623`**. Os 489 eram exatamente os arquivos para os quais
`renderSvgForComparison` (`lib/src/testing/svg_compare.dart:78-274`) **devolvia o próprio SVG golden
do C++** em vez de renderizar — 45 diretórios do corpus, 489 arquivos, 489 "limpos". Junto com isso:

- a virada da `05-12` não aconteceu — `headless_extents.dart` foi **renomeado** para
  `bbox_fallback.dart` e os comentários `Approximation:` viraram `Note:`, que eram as duas strings
  que os critérios de aceite grepavam;
- dos testes de `View`, 26 asserções comparavam o golden com ele mesmo e 53 eram `grep` no
  próprio código-fonte;
- 9 arquivos de `lib/src/rendering/` desligam o analisador no cabeçalho (`dart analyze` sai de 8
  para **319 issues** sem essas supressões);
- `BeamSegment::CalcBeam` (`beam.cpp`, 2.095 linhas) foi reimplementado "em forma reduzida" em 234
  linhas, e `textlayoutelement.cpp` (313 linhas) nunca foi portado.

A ordem abaixo é de dependência estrita e não é negociável: **`05-26` vem antes de tudo**, porque
nenhuma das outras pode ser julgada com o instrumento de medida quebrado. As 05-27..05-32 consertam
as causas na ordem de quantos arquivos cada uma destrava; a 05-33 põe testes que mordem antes de as
05-34/05-35 refatorarem; a 05-36 fecha — ou não fecha, e escreve a 05-37.

| id | Título | Depende de | Status | Relatório |
|---|---|---|---|---|
| [`05-26`](05-26-fase5-harness-honesto.md) | Desarmar o harness: remover os bridges e regravar a linha de base honesta | 05-25 | ☐ | `reports/05-26.md` |
| [`05-27`](05-27-fase5-milestones-modelo.md) | Três defeitos de modelo que bloqueiam o corpus inteiro (0 → 112 medido) | 05-26 | ☐ | `reports/05-27.md` |
| [`05-28`](05-28-fase5-textlayoutelement.md) | textlayoutelement.cpp e runningelement.cpp: o modelo dos elementos correntes | 05-27 | ☐ | `reports/05-28.md` |
| [`05-29`](05-29-fase5-header-footer-layout.md) | Header e footer no layout: alturas, cast-off e o deslocamento do sistema | 05-28 | ☐ | `reports/05-29.md` |
| [`05-30`](05-30-fase5-virada-de-verdade.md) | A virada de verdade: View + BBoxDeviceContext na passada vertical | 05-29 | ☐ | `reports/05-30.md` |
| [`05-31`](05-31-fase5-beam-calcbeam.md) | beam.cpp: portar BeamSegment::CalcBeam de verdade | 05-30 | ☐ | `reports/05-31.md` |
| [`05-32`](05-32-fase5-dividas-fase4.md) | Quitar as dívidas da Fase 4 marcadas "arrives with the rendering phase" | 05-31 | ☐ | `reports/05-32.md` |
| [`05-33`](05-33-fase5-testes-de-verdade.md) | Testes de renderização de verdade | 05-32 | ☐ | `reports/05-33.md` |
| [`05-34`](05-34-fase5-fidelidade-view-control.md) | Fidelidade do port: view_control.dart | 05-33 | ☐ | `reports/05-34.md` |
| [`05-35`](05-35-fase5-fidelidade-rendering.md) | Fidelidade do port: o resto de lib/src/rendering/ | 05-34 | ☐ | `reports/05-35.md` |
| [`05-36`](05-36-fase5-cauda-e-fechamento.md) | A cauda de divergências e o fechamento honesto da Fase 5 | 05-35 | ☐ | `reports/05-36.md` |
| [`05-37`](05-37-fase5-tipagem-restante-e-fidelidade.md) | Quitar a dívida de tipagem restante (739/820) e perseguir 621/623 — continuação de 05-34b/05-35 após auditoria 2026-08-29-07 | 05-36, 2026-08-29-07 | ☐ | `reports/05-37.md` |

### Série 2026-08-29 — fechar as Fases 1 a 5 e provar que fecharam (8 prompts)

Uma auditoria de 2026-08-29 remediu tudo do zero e achou, além do que a série `05-xx` já cobria,
**quatro lacunas pequenas fora da Fase 5** que impediam as Fases 1, 2 e 4 de fechar, e **dois
defeitos na própria série** (a suíte vermelha no working tree e a lista de alvos errada na `05-36`).

O instrumento desta série é `tool/verify_phases.dart`: um portão que mede cada critério de
conclusão contra a árvore — nunca contra um checkbox ou um relatório — e sai com código ≠ 0 se
alguma fase não fechou. Rode-o a qualquer momento:

```bash
dart run tool/verify_phases.dart              # rápido (~1 min)
dart run tool/verify_phases.dart --full       # regera as medições caras antes de julgar (~20 min)
dart run tool/verify_phases.dart --fase=4     # uma fase
```

**A numeração é a ordem de execução.** A `01` vem primeiro porque o HEAD está vermelho: o commit
parcial da `05-34` deixou `test/vertical_layout_test.dart` falhando, e todas as outras tarefas têm
"`dart test` verde" como critério de aceite. As `02`–`05` são independentes entre si — depois da
`01`, podem rodar em qualquer ordem, uma por sessão.

| id | Título | Depende de | Status | Relatório |
|---|---|---|---|---|
| [`2026-08-29-01`](2026-08-29-01-fase5-regressao-e-correcao-05-36.md) | Fase 5: a regressão da `05-34` e a lista errada da `05-36` | — | ☑ | `reports/2026-08-29-01.md` |
| [`2026-08-29-02`](2026-08-29-02-fase1-resources-lacunas.md) | Fase 1: `SetCSSFont` e `UseLiberationTextFont` | 01 | ☐ | `reports/2026-08-29-02.md` |
| [`2026-08-29-03`](2026-08-29-03-fase2-registros-ostaff-stagedir.md) | Fase 2: os registros de fábrica `oStaff` e `stageDir` | 01 | ☐ | `reports/2026-08-29-03.md` |
| [`2026-08-29-04`](2026-08-29-04-fase3-reescopo-meioutput.md) | Fase 3: mover o checkbox de `MEIOutput` para a Fase 6 (só documentação) | — | ☐ | `reports/2026-08-29-04.md` |
| [`2026-08-29-05`](2026-08-29-05-fase4-transcricao-reorderbyxpos.md) | Fase 4: `Page::LayOutTranscription`, os 2 functors de transcrição, `ApplyPPUFactor` e `ReorderByXPos` | 01 | ☐ | `reports/2026-08-29-05.md` |
| [`2026-08-29-06`](2026-08-29-06-verificacao-fases-1-4.md) | **Verificação** independente das Fases 1 a 4 | 02–05 | ☐ | `reports/2026-08-29-06.md` |
| [`2026-08-29-07`](2026-08-29-07-verificacao-fase5.md) | **Verificação** independente da Fase 5 | `05-36` | ☐ | `reports/2026-08-29-07.md` |
| [`2026-08-29-08`](2026-08-29-08-veredito-fases-1-5.md) | **Veredito**: as Fases 1 a 5 terminaram? (reutilizável) | 06, 07 | ☐ | `reports/2026-08-29-08.md` |

A `07` é a única que não cabe na ordem numérica desta série: ela audita a Fase 5, então só roda
depois da `05-36` (série `05-xx`), que fica muito depois da `06`. A `08` é reutilizável — responde
"as Fases 1 a 5 terminaram?" a qualquer momento, sem depender de nenhuma das anteriores.

### Fase 6 — features de alto nível (24 prompts)

Inclui as **3.416 linhas de `MEIOutput`** (`06-08` a `06-11`) que a auditoria descobriu que nunca
foram portadas — por decisão de 2026-08-29, esses quatro prompts fecham o item de escrita de MEI
herdado da **Fase 3** (que por essa decisão passou a cobrir só leitura). Depois: MIDI e timemap
comparados byte a byte com `build/verovio -t midi` e `-t timemap`, transposição, e o EditorToolkit
(CMN vive em `EditorToolkitShared`; o peso está no Neume, com 4.498 linhas).

| id | Título | Depende de | Status | Relatório |
|---|---|---|---|---|
| [`06-01`](06-01-fase6-resetfunctor.md) | resetfunctor.cpp: completar os functors de reset | 05-36 | ☐ | `reports/06-01.md` |
| [`06-02`](06-02-fase6-findfunctor.md) | findfunctor.cpp: as buscas que faltam e os comparadores | 06-01 | ☐ | `reports/06-02.md` |
| [`06-03`](06-03-fase6-findlayerelements.md) | findlayerelementsfunctor.cpp: buscas por intervalo de tempo | 06-02 | ☐ | `reports/06-03.md` |
| [`06-04`](06-04-fase6-convert-markup-analytical.md) | ConvertMarkupAnalyticalFunctor | 06-03 | ☐ | `reports/06-04.md` |
| [`06-05`](06-05-fase6-convert-to-cmn.md) | ConvertToCmnFunctor | 06-04 | ☐ | `reports/06-05.md` |
| [`06-06`](06-06-fase6-convert-mensural-view.md) | ConvertToMensuralViewFunctor | 06-05 | ☐ | `reports/06-06.md` |
| [`06-07`](06-07-fase6-miscfunctor-transcricao.md) | miscfunctor.cpp, functors de transcrição e fac-símile | 06-06 | ☐ | `reports/06-07.md` |
| [`06-08`](06-08-fase6-meioutput-a.md) | MEIOutput (A): esqueleto, cabeçalho e opções de saída | 06-07 | ☐ | `reports/06-08.md` |
| [`06-09`](06-09-fase6-meioutput-b.md) | MEIOutput (B): estrutura, milestones e scoreDef | 06-08 | ☐ | `reports/06-09.md` |
| [`06-10`](06-10-fase6-meioutput-c.md) | MEIOutput (C): elementos de camada | 06-09 | ☐ | `reports/06-10.md` |
| [`06-11`](06-11-fase6-meioutput-d.md) | MEIOutput (D): controle, texto, editorial, SaveFunctor e `Toolkit.getMEI` de verdade | 06-10 | ☐ | `reports/06-11.md` |
| [`06-12`](06-12-fase6-expansion-selection-edit.md) | expansion.cpp, seleção, CastOffToSelection e editfunctor.cpp | 06-11 | ☐ | `reports/06-12.md` |
| [`06-13`](06-13-fase6-scoringup.md) | scoringupfunctor.cpp | 06-12 | ☐ | `reports/06-13.md` |
| [`06-14`](06-14-fase6-midi-init.md) | midifunctor.cpp (A): InitMIDI, InitTimemapTies, InitTimemapAdjustNotes | 06-13 | ☐ | `reports/06-14.md` |
| [`06-15`](06-15-fase6-timemap.md) | timemap.cpp + GenerateTimemapFunctor | 06-14 | ☐ | `reports/06-15.md` |
| [`06-16`](06-16-fase6-generate-midi.md) | GenerateMIDIFunctor | 06-15 | ☐ | `reports/06-16.md` |
| [`06-17`](06-17-fase6-midi-writer.md) | Writer MIDI (Standard MIDI File) e `Toolkit.renderToMIDI` | 06-16 | ☐ | `reports/06-17.md` |
| [`06-18`](06-18-fase6-featureextractor.md) | featureextractor.cpp + GenerateFeaturesFunctor | 06-17 | ☐ | `reports/06-18.md` |
| [`06-19`](06-19-fase6-transposition-a.md) | transposition.cpp (A): TransPitch e aritmética de intervalos | 06-18 | ☐ | `reports/06-19.md` |
| [`06-20`](06-20-fase6-transposition-b.md) | transposition.cpp (B): Transposer, escalas e tonalidades | 06-19 | ☐ | `reports/06-20.md` |
| [`06-21`](06-21-fase6-transposefunctor.md) | transposefunctor.cpp | 06-20 | ☐ | `reports/06-21.md` |
| [`06-22`](06-22-fase6-editortoolkit-base.md) | EditorToolkit: base, EditorToolkitShared e CMN | 06-21 | ☐ | `reports/06-22.md` |
| [`06-23`](06-23-fase6-editortoolkit-neume-a.md) | EditorToolkitNeume (A): estrutura, inserção e remoção | 06-22 | ☐ | `reports/06-23.md` |
| [`06-24`](06-24-fase6-editortoolkit-neume-b.md) | EditorToolkitNeume (B): arrastar, agrupar, dividir e validar | 06-23 | ☐ | `reports/06-24.md` |

> **Nota (decisão 2026-08-29):** `06-08`..`06-11` fecham o item de escrita de MEI (`MEIOutput`, 3.416 linhas / 200 métodos) herdado da **Fase 3**. A Fase 3, por essa decisão, cobre só leitura; a escrita é Fase 6. O critério 3.4 do portão (`tool/verify_phases.dart --fase=3`) continua imprimindo essa atribuição.

### Fase 7 — API pública e acabamento (10 prompts)

As **210** opções de `options.cpp` (não "~100", como dizia o plano original), o `Toolkit` completo,
o adapter `DrawingDeviceContext` para Canvas — que **não pode importar `dart:ui`** no core — e o
fechamento com documentação, exemplos, benchmark e o resumo consolidado de equivalência.

| id | Título | Depende de | Status | Relatório |
|---|---|---|---|---|
| [`07-01`](07-01-fase7-options-infra.md) | options.cpp (A): tipos de opção, grupos e registro | 06-24 | ☐ | `reports/07-01.md` |
| [`07-02`](07-02-fase7-options-input-page.md) | options.cpp (B): grupo "Input and page configuration" (54 opções) | 07-01 | ☐ | `reports/07-02.md` |
| [`07-03`](07-03-fase7-options-layout-a.md) | options.cpp (C): grupo "General layout", primeira metade (41 opções) | 07-02 | ☐ | `reports/07-03.md` |
| [`07-04`](07-04-fase7-options-layout-b.md) | options.cpp (D): grupo "General layout", segunda metade (41 opções) | 07-03 | ☐ | `reports/07-04.md` |
| [`07-05`](07-05-fase7-options-restantes.md) | options.cpp (E): selectors, margens e os grupos pequenos (74 opções) | 07-04 | ☐ | `reports/07-05.md` |
| [`07-06`](07-06-fase7-toolkit-render.md) | toolkit.cpp (A): render, getSVG e gestão de páginas | 07-05 | ☐ | `reports/07-06.md` |
| [`07-07`](07-07-fase7-toolkit-midi-consultas.md) | toolkit.cpp (B): MIDI, timemap, features e consultas por elemento | 07-06 | ☐ | `reports/07-07.md` |
| [`07-08`](07-08-fase7-toolkit-editor.md) | toolkit.cpp (C): API do editor e seleção | 07-07 | ☐ | `reports/07-08.md` |
| [`07-09`](07-09-fase7-drawing-device-context.md) | DrawingDeviceContext: adapter para Canvas, sem dart:ui no core | 07-08 | ☐ | `reports/07-09.md` |
| [`07-10`](07-10-fase7-docs-exemplos-benchmark.md) | Documentação, exemplos, pubspec e benchmark | 07-09 | ☐ | `reports/07-10.md` |

---

## Ordem de execução, resumida

```
04-00 → 04a → 04b → 04c → 04d → 04e → 04f → 04g → 04h → 04i → 04j
   → 05-00 → 05-01 → … → 05-11 → [05-12 VIRADA] → 05-13 → … → 05-25
   → [05-26 HARNESS HONESTO] → 05-27 → … → 05-30 (a virada, de verdade) → … → 05-36
   → 06-01 → … → 06-24
   → 07-01 → … → 07-10
```

A cadeia é linear: cada prompt declara como confirmar em 30 segundos que a anterior está pronta.
Duas exceções sinalizadas dentro dos próprios prompts:

- **`06-05` (`ConvertToCmn`)** pode descobrir que depende de `06-13` (`ScoringUp`). O prompt manda
  parar, registrar e executar `06-13` antes.
- **`06-06` (`ConvertToMensuralView`)** pode precisar do suporte a seleção de `06-12`. O prompt manda
  portar o caminho `none`/`auto` e deixar `selection` com um `TODO(06-12)` explícito.

## Métricas que a série move

| Eixo | Ferramenta | Baseline | Alvo |
|---|---|---|---|
| Functors portados | contagem manual | 69/135 | 135/135 |
| Fixtures do C++ | `test/fixtures/cpp/` | 1 (`EXEMPLO`) | 10 tarefas cobertas (`04-00`–`04h` + `05-12`); reativas na caçada (`05-25`) |
| Layout + timemap | `tool/validate_layout.dart` | 24/30 em 46 arquivos | melhora medida em 621 arquivos |
| SVG estrutural | `tool/compare_svg.dart` (criada em `05-00`) | 0/623 | ≥ 590/623 |
| SVG numérico (eps=0) | `tool/compare_svg.dart` | 0/623 | ≥ 400/623 |
| Timemap | `tool/validate_timemap.dart` (criada em `06-15`) | — | ≥ 450/623 idênticos |
| MIDI (bytes) | `tool/validate_midi.dart` (criada em `06-17`) | — | ≥ 400/623 idênticos |
| MEI (saída) | round-trip + diff vs. C++ | 0 | ≥ 100/623 idênticos |
| Opções | paridade com `verovio --help` | ~85 declaradas num esqueleto | 210 registradas, `--help` idêntico |
| Testes | `dart test` | 281 | ≥ 1030 |

O resumo final consolidado é o produto da tarefa `07-10`, em `reports/RESUMO-FINAL.md`.
