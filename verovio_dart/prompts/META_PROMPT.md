# Meta-prompt — gerar a série de prompts de execução do port Verovio → Dart

Cole este arquivo inteiro como primeira mensagem de uma sessão nova do Claude Code
aberta em `/home/mauricio/rust_projects/verovio-transpile`.

---

## 1. Seu papel nesta sessão

Você **não implementa nada do port** nesta sessão. Você faz duas coisas, nesta ordem:

1. **Audita** o estado real do trabalho já feito (o `PLANO.md` mente: os checkboxes atrasam em relação ao código).
2. **Escreve uma série de arquivos de prompt** em `verovio_dart/prompts/`, em **português**, que outra LLM
   *menos capaz*, em sessões independentes e sem nenhum contexto prévio, consiga executar até terminar o port.

Se você sentir vontade de "só arrumar rapidinho" um arquivo Dart, não arrume: registre como tarefa num prompt.
A única exceção é `PLANO.md`, que você **deve** corrigir ao final da auditoria (checkboxes e notas de estado).

## 2. O que é este repositório

Port linha-a-linha do **Verovio 6.2.0** (biblioteca C++ de gravação musical: MEI/MusicXML/ABC → SVG) para **Dart puro**.
O objetivo é **equivalência funcional com o C++**, não um redesenho. Na dúvida, espelhe o original.

| Caminho | Papel |
|---|---|
| `origin/src/` | Fontes C++ 6.2.0 originais — a **referência** de toda decisão (`src/*.cpp`, `include/vrv/*.h`, `libmei/dist/`). Somente leitura. |
| `build/verovio` | CLI C++ compilado localmente (Release, `NO_HUMDRUM_SUPPORT=ON`) — gera goldens e serve de oráculo. |
| `verovio_dart/` | O package Dart. Todo desenvolvimento acontece aqui. |
| `PLANO.md` | Roadmap de escopo (português). Fonte da verdade sobre **escopo**, não sobre **progresso**. |
| `CLAUDE.md` | Convenções obrigatórias do repositório. **Leia antes de qualquer coisa.** |

Não é um repositório git — não existe histórico para consultar nem `git diff` para revisar. Todo estado tem de ser
inferido do código.

Comandos (sempre a partir de `verovio_dart/`):

```bash
dart test                    # suíte completa (~15 s)
dart analyze                 # lints
dart run tool/validate_layout.dart   # pipeline de layout + timemap vs C++ → tool/LAYOUT_VALIDATION.md
dart run tool/validate_io.dart musicxml <in.musicxml> <cpp.mei>
./tool/golden.sh             # regenera test/golden/cpp/**.svg a partir de ../build/verovio
dart run tool/gen_atts.dart          # gera lib/src/model/atts/*.dart
python3 tool/gen_elements.py         # gera lib/src/model/*_gen.dart
```

Binário C++ de referência, quando precisar de um oráculo pontual:

```bash
build/verovio -r verovio_dart/assets/data -o out.svg entrada.mei     # -t timemap | -t mei | -t midi
```

Fora de escopo por decisão registrada: Humdrum (`humlib`, `iohumdrum`), PAE (`iopae`) e os filtros desabilitados por
padrão no C++ (darms, cmme, volpiano, gabc).

## 3. Estado levantado em 2026-08-26 (reconfira; não confie de olhos fechados)

- **Fases 0–3 (infra, fundações, modelo MEI, leitura de arquivos): concluídas.** ~43k linhas em `lib/src/model/`,
  ~14k em `lib/src/io/`, 265 testes verdes.
- **Fase 4 (layout): parcial, e mais incompleta do que parece.**
  - `lib/src/layout/` tem ~17k linhas (aligners, adjust_*, castoff, justify, preparedata).
  - **68 das 135 classes `*Functor` do C++ existem em Dart.**
  - O layout não usa o `View` real: apoia-se em `lib/src/rendering/headless_extents.dart`, um substituto
    aproximado que preenche bounding boxes sem desenhar. Há **16 marcadores `Approximation:`** em
    `headless_extents.dart`, `layout/floating_positioner.dart` e `layout/slur_positioning.dart`.
  - `tool/LAYOUT_VALIDATION.md` reporta 46 arquivos com layout OK, mas apenas **18/30 timemaps batem com o C++**.
- **Fases 5–7 (SVG/View, MIDI/timemap/transposição/editor, Toolkit público): não iniciadas.**
  `lib/src/drawing/`, `lib/src/midi/`, `lib/src/editing/`, `lib/src/resources/` estão vazios.
  `lib/src/toolkit.dart` é load-only (`loadData`/`loadFile`/`loadZipData`/`getMEI`).
- **Corpus e goldens**: 623 arquivos `.mei` em `test/corpus/`, 623 SVGs de referência em `test/golden/cpp/`.
  Nada compara contra eles ainda.

Volume C++ restante, medido:

| Bloco | Arquivos | Linhas |
|---|---|---:|
| Fase 5 — View + device contexts | `view.cpp` 342, `view_graph.cpp` 430, `view_page.cpp` 2078, `view_element.cpp` 2212, `view_control.cpp` 3306, `view_beam.cpp` 473, `view_slur.cpp` 97, `view_tuplet.cpp` 211, `view_text.cpp` 701, `view_mensural.cpp` 751, `view_neume.cpp` 322, `view_tab.cpp` 295, `svgdevicecontext.cpp` 1417, `devicecontext.cpp` 333, `bboxdevicecontext.cpp` 457 | ~13.4k |
| Fase 6 — features | `midifunctor.cpp` 1324, `timemap.cpp` 110, `featureextractor.cpp` 173, `transposition.cpp` 2252, `transposefunctor.cpp` 425, `expansion.cpp` 65, `editfunctor.cpp` 147, `findfunctor.cpp` 477, `savefunctor.cpp` 187, `resetfunctor.cpp` 907, `convertfunctor.cpp` 1465, `facsimile.cpp` 108, `editortoolkit*.cpp` ~5.5k | ~13.2k |
| Fase 7 — API | `toolkit.cpp` 2431, `options.cpp` 2185 | ~4.6k |

Functors do C++ **sem contraparte de mesmo nome em Dart** (68 nomes — trate como *pista*, não veredito: alguns
foram portados como métodos, p.ex. `ConvertToPageBasedFunctor` virou `Doc.convertToPageBasedDoc`; confirme
caso a caso antes de transformar em tarefa):

```
AddToFlatList AdjustAccidX AdjustArtic AdjustArticWithSlurs AdjustBeams AdjustDots AdjustHarmGrpsSpacing
AdjustLayers AdjustNeumeX AdjustOssiaStaffDef AdjustSylSpacing AdjustTempo AdjustTupletNumOverlap
AdjustTupletsX AdjustTupletsY AdjustTupletWithSlurs AdjustXOverflow AdjustXRelForTranscription
AdjustYRelForTranscription ApplyPPUFactor CacheHorizontalLayout CalcLedgerLines CalcSpanningBeamSpans
CastOffToSelection Const ConvertMarkupAnalytical ConvertMarkupArtic ConvertMarkupScoreDef ConvertToCmn
ConvertToMensuralView ConvertToPageBased DocConst Doc FindAllBetween FindAllByComparison
FindAllConstByComparison FindAllReferencedObjects FindAllReferringObjects FindByComparison FindByID
FindElementInLayerStaffDef FindExtremeByComparison FindNextChildByComparison FindPreviousChildByComparison
FindSpannedLayerElements GenerateFeatures GenerateMIDI GenerateTimemap GetAlignmentLeftRight
GetRelativeLayerElement InitMIDI InitTimemapAdjustNotes InitTimemapTies LayerElementsInTimeSpan
LayersInTimeSpan ReorderByXPos ReplaceDrawingValuesInStaffDef Save ScoreContext ScoreDefOptimize
ScoreDefSetOssia ScoringUp SectionContext SetStaffDefRedrawFlags SyncFromFacsimile SyncToFacsimile
Transpose TransposeSelectedMdiv TransposeToSoundingPitch
```

## 4. Decisões já tomadas pelo dono do projeto — **não reabra nenhuma**

1. **Estrutura**: um prompt mestre (`00-MESTRE.md`) com convenções + muitos prompts de tarefa curtos.
2. **Escopo dos prompts**: auditoria → fechamento da Fase 4 → Fases 5, 6 e 7 **integralmente**, incluindo
   MIDI/timemap/featureextractor, transposição/expansion/selection, **EditorToolkit CMN e Neume**, Toolkit
   completo com as ~100 opções de `options.h` e o adapter `DrawingDeviceContext` para Canvas/`dart:ui`.
3. **Idioma e local**: português, em `verovio_dart/prompts/`.
4. **Critérios de aceite** (todos, em todo prompt): `dart analyze` limpo + `dart test` verde + diff estrutural do
   SVG contra o C++ + **igualdade numérica exata como meta** + relatório markdown por tarefa.
5. **Ambiente do executor**: mesmo ambiente, **autonomia total** — pode criar ferramentas em `tool/`, decidir a
   decomposição em arquivos e recompilar o C++ se precisar.
6. **`headless_extents.dart` será substituído pelo `View` real.** Portar `View` + `BBoxDeviceContext` como no C++,
   fazer o layout passar a usar o `View` de verdade e **deletar** `headless_extents.dart`. Isso obriga a revalidar
   toda a Fase 4 — é esperado e desejado, é a única rota para igualdade numérica.
7. **Política de divergência**: a LLM investiga até zerar a diferença, perseguindo a causa no C++. Se travar,
   documenta a divergência no relatório com hipótese de causa e segue para a próxima tarefa. Nunca "ajusta o
   esperado" para o teste passar.
8. **Progresso**: cada prompt termina marcando o checkbox correspondente no `PLANO.md` e gravando seu relatório.
9. **Granularidade**: fatias pequenas, **~300–600 linhas de Dart por prompt**. Espere 40–70 prompts no total.
   Prompt grande demais é falha de projeto seu.
10. **Harness de comparação de SVG**: é a **primeira tarefa da série** (5.0), não algo pressuposto.

## 5. Etapa 1 — Auditoria

Produza `verovio_dart/prompts/AUDITORIA.md`. Trabalho de investigação, com evidência para cada afirmação.
Sugestões de medição (invente outras à vontade):

- Inventário de functors: `grep -rhoP '^class \K\w+Functor'` em `origin/src/include/vrv/*functor*.h` versus
  `verovio_dart/lib/src/**.dart`, e depois **confirme manualmente** cada faltante (pode ter virado método).
- Inventário de elementos MEI: classes registradas em `lib/src/factory_registry.dart` +
  `factory_registry_gen.dart` versus as de `origin/src/libmei/dist/` e `include/vrv/`.
- Todos os `Approximation:`, `TODO`, `FIXME` de `lib/src/`, com o que cada um implica.
- Rode `dart analyze`, `dart test` e `dart run tool/validate_layout.dart` e registre o resultado **real**
  (número de testes, falhas, quantos timemaps batem). Nota do `CLAUDE.md`: o ruído
  `Bravura font could not be loaded` em alguns testes é esperado, não é regressão.
- Compare a cobertura de IO: `dart run tool/validate_io.dart` sobre o corpus MusicXML.
- Verifique se os geradores (`tool/gen_atts.dart`, `tool/gen_elements.py`) ainda reproduzem os arquivos
  `*_gen.dart` atuais sem diferença.

O `AUDITORIA.md` deve terminar com uma tabela **fase → % pronto → evidência → o que falta**, e essa tabela é a
entrada da Etapa 3. Ao terminar, **corrija o `PLANO.md`**: marque o que está realmente feito, desmarque o que
não está, e acrescente notas curtas de estado onde o texto atual estiver otimista demais (a Fase 4, por exemplo,
está listada como não iniciada quando na verdade está parcialmente feita e apoiada em aproximações).

## 6. Etapa 2 — `prompts/00-MESTRE.md`

Um único arquivo que todo prompt de tarefa manda ler primeiro. Conteúdo obrigatório:

- O que é o projeto e a regra de ouro: **espelhar o C++**; onde o Dart obrigar a divergir, documentar num bloco
  `Deviations from the C++:` no código.
- Layout do workspace e todos os comandos da seção 2 deste meta-prompt.
- Convenções do `CLAUDE.md`, repetidas por extenso (não presuma que a LLM vai abrir o arquivo):
  citar o contraparte C++ em doc comment de cada classe/método; **nunca** editar à mão os arquivos com banner
  `GENERATED FILE` (`lib/src/model/atts/*.dart` exceto `mei_values.dart`, `lib/src/model/*_gen.dart`) — mexer no
  gerador em `tool/`; `constant_identifier_names` está desligado de propósito; `model.Object` sombreia o
  `Object` de `dart:core` (importar `as model` ou com `hide`); `Resources.defaultPath` precisa virar
  `'assets/data'` em testes e tools; fontes ficam em `assets/data/`, não `assets/fonts/`;
  `test/corpus/dir/dir-011.mei` e `dir-012.mei` não são UTF-8 e ficam em skip-list;
  `tool/_scratch_*.dart`, `tool/t8.dart`, `tool/dbg_c.dart` são lixo de debug — não construa em cima nem
  tente limpar os warnings deles.
- Os dois mecanismos que quem edita este código precisa entender **antes** de mexer, explicados de verdade:
  (a) **despacho de functor** — o C++ usa `Accept()` virtual, o Dart resolve com a tabela `kAcceptChain` em
  `lib/src/layout/functor.dart` (`ClassId` → `ClassId` cujo `visitXxx` roda) mais um switch em
  `Functor.visit`/`visitEnd`; os corpos padrão delegam para cima (`visitNote` → `visitLayerElement` →
  `visitObject`) como em `functorinterface.cpp`; classe nova sem `Accept()` no C++ tem de entrar em `kAcceptChain`;
  (b) **registro de classe** — elementos nascem pelo nome via `ObjectFactory`; classe nova precisa de entrada em
  `lib/src/factory_registry.dart` (ou vir do gerador) **e** de um `ClassId` em `lib/src/core/vrvdef.dart`; todo
  teste/tool chama `registerModelClasses()` no `setUpAll`/`main`.
- O procedimento padrão de verificação e a política de divergência (decisões 4 e 7 da seção anterior).
- O formato do relatório de tarefa e onde gravá-lo (`prompts/reports/<id>.md`).
- Regras de higiene: não apagar teste que passou a falhar, não afrouxar tolerância para fechar tarefa, não
  inventar API que não existe no C++, não fazer refatoração oportunista fora do escopo da tarefa.

## 7. Etapa 3 — Os prompts de tarefa

### Nomenclatura e ordem

`prompts/NN-<fase>-<slug>.md`, numeração que reflete a ordem de execução e a dependência —
`04a-…`, `04b-…` para o fechamento da Fase 4, `05-00-harness-svg.md`, `05-01-…`, `06-…`, `07-…`.

### Template obrigatório de cada prompt

```markdown
# <id> — <título curto>

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo
<1–3 frases. O que existe ao final que não existia antes.>

## Pré-condições
<Tarefas que precisam estar prontas; como confirmar em 30 s que estão (comando + saída esperada).>

## Referência C++
<Arquivos e faixas de linha exatos em origin/. Funções/classes nominais. Cabeçalhos correspondentes.>

## Arquivos Dart a criar/alterar
<Caminhos exatos. Se criar classe nova: onde registrar (factory_registry, vrvdef ClassId, kAcceptChain).>

## Passo a passo
<Numerado, granular, na ordem de dependência.>

## Critérios de aceite
- [ ] `dart analyze` sem novos avisos
- [ ] `dart test` verde (N testes, sem regressão)
- [ ] <verificação específica desta tarefa: comando + resultado esperado, quantitativo>
- [ ] Relatório gravado em `prompts/reports/<id>.md`
- [ ] Checkbox correspondente marcado no `PLANO.md`

## Armadilhas conhecidas
<O que já se sabe que dá errado aqui.>

## Fora de escopo
<O que a LLM não deve tocar, para não estourar a fatia.>
```

Cada critério de aceite tem de ser **verificável por comando**, não por opinião. "Renderiza corretamente" é
inaceitável; "`dart run tool/compare_svg.dart test/corpus/beam` reporta 0 divergências estruturais em 40
arquivos" é aceitável.

### Decomposição a produzir

**Fase 4 — fechamento** (venha antes da Fase 5; o layout precisa estar completo em functors antes de trocar a
matemática de bbox): um prompt por grupo coeso de functors faltantes, guiado pelo `AUDITORIA.md`. Agrupe por
arquivo C++ e mantenha a fatia em 300–600 linhas de Dart. Ex.: `adjustbeamsfunctor.cpp` + `adjustdotsfunctor.cpp`
numa tarefa; `adjusttupletsxfunctor.cpp` + `adjusttupletsyfunctor.cpp` noutra. Feche com um prompt de
revalidação que roda `tool/validate_layout.dart` e exige melhora medida no número de timemaps que batem.

**Fase 5 — View e SVG**, nesta ordem de dependência:

1. **`05-00-harness-svg.md`** — antes de qualquer View. Cria `tool/compare_svg.dart` + `test/svg_golden_test.dart`:
   compara o SVG produzido pelo Dart com `test/golden/cpp/**.svg` em dois modos, **estrutural** (mesma árvore de
   elementos, mesmos `id`/`class`, mesma ordem) e **numérico** (coordenadas iguais dentro de um epsilon
   explicitado), e emite um relatório markdown agregado com contagem de arquivos limpos sobre os 623 do corpus.
   Enquanto não houver renderização, o harness roda contra um stub e reporta 0/623 — isso é o baseline correto,
   e é a métrica que todas as tarefas seguintes movem para cima.
2. `devicecontext.cpp` + `devicecontextbase` — conferir o que já existe em `lib/src/rendering/device_context.dart`
   contra o C++ e completar.
3. `svgdevicecontext.cpp` (1417 linhas → 2–3 tarefas): estrutura do SVG, ids, classes, `<defs>`/símbolos de
   glyph, texto, transformações. A saída tem de ser **estruturalmente idêntica** à do C++, ids inclusive.
4. `bboxdevicecontext.cpp` — conferir/completar `lib/src/rendering/bbox_device_context.dart`.
5. `view.cpp` + `view_graph.cpp` — o esqueleto do `View` e as primitivas gráficas.
6. `view_page.cpp` (2078 → ~4 tarefas): página, sistema, medida, pentagrama, camada.
7. **Tarefa de virada**: ligar o layout ao `View` real. Localize em `doc.cpp`/`toolkit.cpp` onde o C++ instancia
   o `BBoxDeviceContext` e como `View::DrawCurrentPage` participa do layout; reproduza esse fluxo, **remova**
   `lib/src/rendering/headless_extents.dart` e todos os `Approximation:` que ele justificava, e revalide a Fase 4
   inteira com `tool/validate_layout.dart`. Espere regressões aqui — o prompt deve dizer isso e mandar
   persegui-las até o fim.
8. `view_element.cpp` (2212 → ~4–5 tarefas, fatiadas por família: notas/hastes, acidentes/articulações,
   pausas, custos/clefs/keysig/mensur, etc.).
9. `view_beam.cpp`, `view_tuplet.cpp`, `view_slur.cpp`, `view_text.cpp`.
10. `view_control.cpp` (3306 → ~6–8 tarefas, uma por família de objeto flutuante: slur/tie, hairpin/dynam,
    tempo/dir/harm, trill/mordent/turn, octave/pedal, bracketSpan/lv/breath, etc.). Fatie listando as funções
    `View::Draw*` do arquivo e agrupando por afinidade.
11. `view_mensural.cpp`, `view_neume.cpp`, `view_tab.cpp` — notação antiga e tablatura.
12. Prompt final da fase: correr o harness sobre os **623** arquivos e perseguir a cauda de divergências
    até a meta de igualdade numérica exata, com relatório do que sobrou e por quê.

**Fase 6 — features**: MIDI (`midifunctor.cpp` + writer MIDI próprio, já que não há dependência C++ a portar),
`timemap.cpp`, `featureextractor.cpp`, `transposition.cpp` + `transposefunctor.cpp`, `expansion.cpp`,
`selectfunctor`/`editfunctor`, `findfunctor.cpp`, `savefunctor.cpp`, `resetfunctor.cpp`, `convertfunctor.cpp`,
`facsimile.cpp`, e por fim `editortoolkit_shared/cmn/neume` (~5.5k linhas → 8–12 tarefas).
Aceite do MIDI/timemap: comparar contra `build/verovio -t midi` e `-t timemap` sobre o corpus.

**Fase 7 — API**: `options.cpp` (~100 opções, fatiar por grupo de opções), `toolkit.cpp` (load/render/getSVG/
getMEI/getMIDI/timemap/editor API), o `DrawingDeviceContext` para Canvas — que **não pode importar `dart:ui`**
no core, para o package continuar válido em web/servidor —, e um prompt final de documentação, exemplos,
`pubspec` e benchmark.

## 8. Etapa 4 — `prompts/README.md`

Índice central: tabela com **id, título, fase, depende de, status, relatório**. É o mapa que o dono do projeto
usa para saber qual prompt disparar em seguida. Inclua no topo uma explicação de duas frases de como usar a
série (abrir sessão nova, colar o conteúdo de um prompt, um prompt por sessão).

## 9. Critérios de aceite do SEU trabalho nesta sessão

- [ ] `verovio_dart/prompts/AUDITORIA.md` existe, com evidência (comando + saída) para cada afirmação de estado.
- [ ] `PLANO.md` corrigido para refletir a realidade medida.
- [ ] `verovio_dart/prompts/00-MESTRE.md` existe e é suficiente sozinho para alguém entender como trabalhar no repo.
- [ ] 40–70 prompts de tarefa, todos no template da seção 7, todos com critérios verificáveis por comando.
- [ ] Nenhum prompt de tarefa passa de ~600 linhas de Dart estimadas; se passar, foi mal fatiado — divida.
- [ ] Todo prompt cita arquivos e funções C++ **nominais** de `origin/`, com caminhos reais que você conferiu
      que existem.
- [ ] `verovio_dart/prompts/README.md` indexa tudo, na ordem de execução, com as dependências explícitas.
- [ ] Nenhum arquivo de `lib/`, `test/` ou `tool/` foi modificado nesta sessão.
- [ ] Teste de sanidade final: pegue **um** prompt de tarefa do meio da série, leia-o como se fosse uma LLM sem
      contexto, e confirme que dá para executá-lo sem fazer nenhuma pergunta. Se não der, conserte o template
      e reveja todos os outros.

## 10. Proibições

- Não implemente nada do port (exceto corrigir o `PLANO.md`).
- Não invente estado: se não mediu, não escreva. Rode o comando.
- Não reabra as decisões da seção 4.
- Não colapse a série em poucos prompts grandes "por eficiência" — a granularidade fina é o pedido.
- Não escreva prompts que dependem de contexto de conversa: cada arquivo é lido por uma sessão que nunca viu esta.
