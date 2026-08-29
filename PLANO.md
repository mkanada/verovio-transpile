# Plano de Transpilação: Verovio 6.2 (C++) → verovio_dart (Dart)

## Visão geral

Port completo e funcionalmente equivalente (1:1) do [Verovio 6.2.0](origin/src) para Dart puro,
compatível com Flutter. Saída em SVG (string) **e** API de drawing para Canvas.

### Decisões registradas

| Aspecto | Decisão |
|---|---|
| Plataforma | Dart puro (Dart ≥ 3.0), sem FFI |
| Saída | SVG em string + primitivas de drawing (Canvas-ready) |
| Estilo | Idiomático Dart; equivalência funcional total com o C++ |
| Dependências | packages do pub.dev (`xml`, `crypto` etc.) + ports onde não houver |
| Recursos | Fontes SMuFL e dados embutidos como assets no package |
| Entradas | MEI, MusicXML, ABC. **Sem Humdrum e sem PAE** |
| Validação | Comparação golden-SVG contra binário C++ compilado localmente |
| Estrutura | Package único `verovio_dart` |

> **Estado medido em 2026-08-26** — ver `verovio_dart/prompts/AUDITORIA.md` para a evidência de cada
> número. Os checkboxes abaixo foram reconciliados com o código nessa data. Resumo: Fases 0–3 feitas;
> **Fase 4 parcialmente feita (~55%)** e apoiada em aproximações; Fases 5–7 não iniciadas.
> `dart analyze` = 10 warnings (8 em `tool/_scratch_*`, 2 em `test/`); `dart test` = 265 testes verdes;
> `tool/validate_layout.dart` = 46 arquivos, 24/30 timemaps batendo com o C++.
>
> A série de prompts de execução vive em `verovio_dart/prompts/` — comece por `prompts/README.md`.

## Inventário do código original

| Componente | Linhas | Observação |
|---|---:|---|
| `src/src/*.cpp` (núcleo, sem Humdrum/PAE) | ~108 mil | modelo, layout, render, IO |
| `include/vrv/*.h` (sem iohumdrum.h) | ~42 mil | ~260 headers |
| `libmei/dist/` (bindings gerados do schema MEI) | ~40 mil | gerado a partir dos XSD do MEI |
| **Total em escopo** | **~190 mil** | |

Fora de escopo (excluído por decisão):
- `src/src/hum/humlib.cpp` (~143 mil linhas)
- `src/src/iohumdrum.*` (~34 mil linhas)

Terceiros bundled que serão substituídos por packages/ports:
- **pugixml** → `package:xml`
- **nlohmann/json** → `dart:convert` (+ wrapper fino p/ API compatível)
- **CRC32** → port próprio (~50 linhas)
- **zip** (LeiMei/compressed assets) → `package:archive`
- **tuning-library** → port próprio (pequeno)

## Arquitetura alvo

```
verovio_dart/
├── lib/
│   ├── verovio.dart                  # API pública (espelha toolkit.h)
│   └── src/
│       ├── core/                     # vrvdef, enums, logging, utils, runtime_clock
│       ├── model/                    # Object, DocObject, LayerElement, ControlElement,
│       │                             # FloatingObject, interfaces (*interface.*),
│       │                             # ~140 classes de elementos MEI
│       ├── atts/                     # classes de atributos MEI (de libmei/dist)
│       ├── io/                       # iobase, iomei, iomusxml, ioabc
│       ├── layout/                   # aligners, functors, doc layout/castoff/justify
│       ├── rendering/                # view*, devicecontext, svgdevicecontext, boundingbox
│       ├── drawing/                  # DeviceContext p/ Canvas (API de drawing extra)
│       ├── midi/                     # export MIDI, timemap, featureextractor
│       ├── editing/                  # editortoolkit (CMN/Neume), expansion, transpose
│       └── resources/                # carregamento das fontes/dados embutidos
├── assets/data/{Bravura,Gootville,Leipzig,Leland,Petaluma}/...   # (real: assets/data, não assets/fonts)
├── tool/                             # scripts de geração (corpus, snapshots)
└── test/
    ├── golden/                       # SVGs de referência gerados do C++
    └── ...                           # testes unitários por módulo
```

## Estratégia de validação

1. Compilar binário CLI do Verovio C++ 6.2 sem Humdrum (`-DNO_HUMDRUM_SUPPORT=ON`, em `origin/build`) — já há cmake/g++/ninja no ambiente.
2. Corpus: arquivos de exemplo do repo + suíte de testes do verovio upstream.
3. Script `tool/golden.sh`: gera SVGs/timemaps/MIDI de referência.
4. Em cada fase, testes Dart comparam a saída contra os goldens
   (comparação estrutural de XML/SVG, tolerando apenas diferenças triviais documentadas).

## Fases

> Ordem por dependência; cada fase termina compilada, testada e validada contra o C++.

### Fase 0 — Infraestrutura (~1 sessão)
- [x] Scaffold do package `verovio_dart` (pubspec, analysis_options, CI-local).
- [x] Build do binário C++ de referência.
- [x] Corpus de teste + script de geração de goldens.
- [x] Pipeline de conversão dos assets (fontes `.xml`/`.css`/`.woff`, dados de tuning).

### Fase 1 — Fundações (~2 sessões)
- [x] `vrvdef.h` → enums, constantes, unidades (enums Dart com extension helpers).
- [x] Logging, `RuntimeClock`, utilitários (`misc`, `crc`, `fraction`).
- [x] `BoundingBox`, hierarquia base de `DeviceContext` (abstrata) e `BBoxDeviceContext`.
      (inclui `devicecontextbase`: Pen/Brush/FontInfo/BezierCurve/TextExtend)
- [x] `Resource`/carregador de fontes (SMuFL glyph map via assets).
      (`Glyph`, `Resources` + `Glyph`/text fonts; leitura via `resourceFileReader`
      plugável — zip custom fonts ficam para a Fase 3)
      **Lacuna medida (2026-08-26):** faltam em `Resources` os métodos `AddCustom`,
      `GetCustomFontname`, `GetSmuflGlyphForUnicodeChar`, `LoadAll`,
      `UseLiberationTextFont`, `IsCurrentFontFallback`, `Ok`, `Get/SetPath`,
      `SetCSSFont`; e em `BBoxDeviceContext` faltam `GetPenWidthOverlap` e o
      override de `SetUserScale` (38/40 métodos portados). Tarefas 05-01 ✓ e 05-05 ✓.

### Fase 2 — Modelo de dados MEI (~8–10 sessões)
- [x] Classe base `Object` (árvore, filhos, índices, UUIDs) — espelho fiel de `object.h`.
      (inclui `ObjectListInterface`, `ObjectFactory`, geração de IDs hash/base36;
      functors de busca genéricos chegam na Fase 4 — os helpers de busca já
      replicam a semântica de travessia do `Process`)
- [x] Interfaces: PositionInterface, PitchInterface,
      TimePointInterface/TimeSpanningInterface, DurationInterface, FacsimileInterface,
      LinkingInterface, PlistInterface, ScoreDefInterface, TextDirInterface,
      AltSymInterface, AreaPosInterface, OffsetInterface…
      (`lib/src/model/interfaces/` + `Zone`; DrawingInterface e os
      pseudo-functors chegam nas fases de layout; métodos dependentes de
      Layer/Staff/Measure/Beam ficam TODO até essas classes existirem)
- [x] Classes de atributos MEI (`libmei/dist/atts_*`) → mixins/sealed classes Dart.
      **Atalho executado**: gerador `tool/gen_atts.dart` lê os headers/C++ do
      libmei e produz `mei_enums.dart`, `atts_conversion.dart` e um mixin por
      classe Att em 22 módulos (`lib/src/model/atts/`), com runtime hand-written
      em `mei_values.dart`. 160 enums, 287 classes, ~520 atributos.
- [x] ~140 classes de elementos (note, staff, measure, layer, beam, slur, clef…)
      **Completo** (~140 classes): bases (LayerElement/ControlElement/
      FloatingObject/EditorialElement+19/System/Page/Text/Running/Doc/Page/
      Pages) + concretas manuais + **98 geradas**, todas registradas no
      `ObjectFactory`. Sessão 5 fechou: framework **Comparison**
      (`lib/src/model/comparison.dart` — comparadores de ClassId/interface/
      @n/@func/duração extrema/id/filtros + buscas `findDescendantByComparison`
      no `Object`), **ExpansionMap** (`expansion_map.dart` — expand recursivo,
      ids previsíveis `-rendN`, updateIDs de interfaces, generateExpansionFor),
      **CustomTuning** + port do tuning-library (`core/tunings.dart`,
      `custom_tuning.dart`) e **Doc/Page/Pages** (`doc.dart`; métodos de
      layout/functors marcados para a Fase 4). `copyFrom` completo nas bases
      (estado de drawing, back-links de LinkingInterface como no `operator=`).
- [x] Editorial (app/lem/rdg/sic/corr…), linking, expansion map, comparison.
      **Defeitos medidos (2026-08-26):** `factory_registry_gen.dart:32-35` registra
      `Dots`, `Flag`, `TupletBracket` e `TupletNum` todos com o nome `'dots'` (o C++
      não registra nenhum dos quatro), `AnnotScore` é registrado como `'annot'`
      colidindo com o `Annot` editorial, e `F`/`Fb`/`Lv`/`Ossia`/`Phrase` não são
      registrados. Faltam também em `Object`: `FindAllDescendantsBetween`,
      `FindNextChild`, `FindPreviousChild`, `FindAllReferringObjects`,
      `FindAllReferencedObjects`, `FindElementInLayerStaffDef`, e os comparadores
      `MeasureAlignerTypeComparison`/`MeasureOnsetOffsetComparison`
      (`comparison.dart:359`). Tarefas 04i e 06-02.
- [x] `ScoreDef`, `StaffDef`, `StaffGrp`, running elements (pghead/pgfoot).

### Fase 3 — Leitura de arquivos (~5–7 sessões)
- [x] `IOBase` + `FileReader` (detecção de formato como em `toolkit.cpp`).
      (`lib/src/io/iobase.dart` Input/Output + `format.dart`
      `identifyInputFrom`; Toolkit com loadData/loadFile/loadZipData,
      suporte a zip/MXL via META-INF/container.xml e decodificação UTF-16.)
- [x] **IOMEI — leitura** (`MEIInput`, ~5,6k linhas no C++) — parser nativo; inclui suporte a zip/MEI comprimido.
- [ ] **IOMEI — escrita** (`MEIOutput`, **3.416 linhas / 200 métodos de `origin/src/src/iomei.cpp`**):
      **não portado**. `Toolkit.getMEI()` hoje devolve a string carregada, não a árvore serializada
      (`toolkit.dart:70`). Tarefas 06-08 a 06-11.
      (`lib/src/io/mei_input.dart` ~5.3k linhas: leitores para toda a
      estrutura page-based/score-based, elementos de layer/control/text,
      editorial markup, facsimile, upgrades MEI 3.0/4.0/5.0→6.0; árvore
      mutável `xml_node.dart` espelhando pugixml. Doc ganhou
      convertToPageBasedDoc/convertMarkupDoc/generateDocumentScoreDef/
      expandExpansions; modelo completado com System, Ossia, Episema, Lv,
      Phrase, Fb, F, GenericLayerElement e atts faltantes em Note/Rest/
      Measure/Staff/BarLine.)
- [x] **IOMusXML** (~5k linhas) — MusicXML → MEI interno.
      (`lib/src/io/iomusxml.dart` ~6.5k linhas: score-partwise completo —
      parts/staffGrp, atributos, notas/beams/tuplets/slurs/ties, directions,
      harmony/figured-bass, repeats/endings → expansion, header MEI;
      validado estruturalmente contra o binário C++ via
      `tool/validate_io.dart`, 0 divergências no corpus midi/*.musicxml.)
- [x] **IOABC** — notação ABC.
      (`lib/src/io/ioabc.dart` ~2.1k linhas: campos I:/K:/L:/M:/Q:/X:/w:,
      música code com beams/tuplets/chords/grace/decorations/lyrics/repeats;
      13 cenários testados.)
- [x] Formatos legados desabilitados por padrão no C++ (iodarms, iocmme,
      iovolpiano): **não portados** (paridade de build default; GABC também
      fica fora até demanda). PAE excluído por decisão do plano — incipits
      PAE em `<incipCode>` são pulados com warning.
- Fora de escopo: **IOPAE** (Plaine & Easie) e todos os conversores Humdrum.

### Fase 4 — Motor de layout (~10–12 sessões) — **PARCIAL (~55%)**

> Medido em 2026-08-26: `lib/src/layout/` tem 16.825 linhas e **69 das 135 classes `*Functor` do C++**.
> Restam **60 functors** genuinamente ausentes (8 dos 68 nomes "faltantes" foram portados como
> métodos — lista em `prompts/AUDITORIA.md` §3). O layout agora usa o `View` real
> (`BBoxDeviceContext` + `View::DrawCurrentPage` em `page.cpp:410` e `:532`,
> tarefa 05-12); o antigo `headless_extents.dart` (825 linhas, 16 `Approximation:`)
> foi deletado e substituído por `bbox_fallback.dart` apenas para os elementos
> cujo `View::Draw*` ainda é stub (05-13..05-22).
> `tool/validate_layout.dart`: 46 arquivos, todas as asserções estruturais passando, **24/30 timemaps
> batendo com o C++** (divergem `lyric/lyric-001.mei` e `section/section-001.mei`).
>
> Medido em 2026-08-27, com a instrumentação do C++ (`cpp_probe/`): os testes existentes asseguram
> **estrutura** (monotônico, não-nulo, não-zero) e quase nunca **valor**, e o `validate_layout.dart`
> calcula onsets de `DurationInterface.scoreTimeOnset` com `--breaks none`, ou seja, não valida o
> alinhador horizontal. Em `note/note-001.mei` — o menor arquivo do corpus — o `AdjustXPos` do Dart
> visita exatamente os mesmos 10 elementos que o C++ e **nenhum dos 20 valores numéricos bate**.
> As duas causas estão listadas abaixo e são o escopo da tarefa 04-00.
>
> Revalidado em 2026-08-28 (tarefa 04j): `validate_layout.dart` varre **os 621 arquivos UTF-8 do
> corpus** (2 não-UTF-8 pulados), layout OK e asserções estruturais **621/621**, **176 timemaps
> match / 18 differ** (de 194 comparados — baseline 24; divergências inventariadas em
> `tool/LAYOUT_VALIDATION.md` §"Divergências de timemap"). Paridade numérica consolidada dos
> fixtures (04-00..04h): **2146 de 2204 valores batem (epsilon 0), 58 divergem** — todos os 58 de
> causas bbox/render já documentadas (04b/04c). Os 9 fixtures regenerados do zero ficaram
> byte a byte idênticos (`git diff --stat` vazio).
>
> Revalidado em 2026-08-28 (tarefa 05-12 — virada View real): `validate_layout.dart`
> **621/621** layout OK, asserções **621/621**, timemaps **176 match / 18 differ**
> (inalterado — o `View` ainda é stub para `view_element`/`view_control`, então as
> caixas que alimentam os timemaps continuam via `bbox_fallback`; a virada é
> estrutural, o fechamento numérico vem com 05-13..05-25). Paridade dos fixtures
> 04-00..04h re-executada: **2200 de 2204 batem**, restam **4** (todas da 04c,
> `BeamSegment::CalcBeam` — tarefa 05-17). `cpp_probe/patches/05-12.patch` só
> adições, 10 diffs de SVG vazios, `bbox_parity_test` com 8 campos × N objetos
> por fixture (epsilon 0) — divergências restantes nomeadas no relatório
> `prompts/reports/05-12.md`.

- [x] Sistema de functors (`FunctorInterface`, despacho via `kAcceptChain` em `layout/functor.dart`).
      `ConstFunctor`/`DocConstFunctor` não portados de propósito (desvio documentado).
- [x] `HorizontalAligner`/`VerticalAligner`, grace aligner, timestamp aligner.
- [x] Preparação de dados (`preparedata_functor.dart`, 30 functors `Prepare*`).
- [x] Cast off (`cast_off.dart`, `cast_off_mensural.dart`) e justify (`justify.dart`).
- [x] Posicionamento de floating objects (`floating_positioner.dart`, `slur_positioning.dart`,
      `adjust_floating.dart`, `adjust_slurs.dart`) — **com aproximações**.
- [x] Mensural/neume specifics (`mensural_neume.dart`).
- [x] **Infraestrutura de extração de dados do C++** (`cpp_probe/` + `verovio_dart/test/fixtures/`):
      scripts de instrumentação por patch sobre uma cópia de `origin/` (que segue intocado), fixtures
      JSON Lines versionados e o leitor/comparador `test/fixtures/cpp_fixture.dart`. Provada ponta a
      ponta em 2026-08-27 com `cpp_probe/patches/EXEMPLO.patch` (`AdjustXPosFunctor`): SVG do binário
      instrumentado idêntico ao do limpo em 8 arquivos do corpus, execuções reprodutíveis byte a byte.
      Convenções em `prompts/00-MESTRE.md` §6-bis.
- [x] **Base numérica da fase** (tarefa 04-00), medida com a infraestrutura acima e **pré-requisito
      das oito seguintes**, porque toda a aritmética delas é `… * drawingUnit`:
      - o `DEFINITION_FACTOR` (`vrvdef.h:453`) nunca é aplicado pelo `options_shell.dart`, então
        `Doc.getDrawingUnit(100)` devolve **9** onde o C++ devolve **90** — atinge as 7 opções
        `definitionFactor` (`unit`, `pageWidth`, `pageHeight`, 4 margens), 65 chamadas em 18 arquivos;
      - o alinhador horizontal perde tempo: **166 dos 2107 compassos do corpus (7,9%)** ficam com
        `maxTime = 0`, e **8 dos 621 arquivos** têm duração total 0 apesar de terem música.
      *(Feito em 2026-08-27: fator aplicado exatamente nas 7 opções + `unfactoredValue`; causa da
      lacuna era `Rest` sem registro de `InterfaceId.duration`. Paridade de unidades e de
      type/time/xRel de alinhamentos com epsilon 0 nos 5 fixtures 04-00; ramo NEUME/SYLLABLE de
      `GetAlignmentDuration` restabelecido. Após a correção: **112/2107** compassos com
      `maxTime = 0` (agrupados em conteúdo estrutural/vazio e diferenças de seleção multi-mdiv —
      ver relatório) e **0 arquivos** colapsados. Relatório:
      `verovio_dart/prompts/reports/04-00.md`.)*
- [x] **19 functors de ajuste horizontal/vertical faltantes** (tarefas 04a–04g):
      `AdjustArtic`, `AdjustArticWithSlurs`,
      `AdjustAccidX`,
      `AdjustBeams`.
      — 04a ✓ (`AdjustLayers`, `AdjustDots` portados; relatório
      `verovio_dart/prompts/reports/04a.md`), 04b ✓ (`AdjustArtic`, `AdjustArticWithSlurs`,
      `AdjustAccidX` portados — rodam em `layOutVertically`, não em `layOutHorizontally` como o
      C++, porque só ali as bounding boxes headless existem nesta porta; relatório
      `verovio_dart/prompts/reports/04b.md`), 04c ✓ (`AdjustTupletsX`, `AdjustTupletsY`,
      `AdjustTupletNumOverlap` — instanciado dentro do Y, como no C++ — e
      `AdjustTupletWithSlurs` portados; ramo beam dos ajustes Y degrada graciosamente até a fase
      de segmentos de beam, ver relatório `verovio_dart/prompts/reports/04c.md`), 04d ✓
      (`AdjustBeams` portado — `VisitBeam`/`VisitBeamEnd`/`VisitClef`/`VisitFTrem`/
      `VisitFTremEnd`/`VisitLayerElement`/`VisitRest` e os helpers `CalcLayerOverlap`/
      `AdjustOverlapToHalfUnit`/`GetOuterBeamInterface`; sem `BeamSegment::CalcBeam`
      \(tarefa futura\) os segmentos de beam ficam vazios em produção e o functor degrada pelo
      próprio guard de coords vazios do C++ — mesmo resultado final, paridade exercitada por
      árvores sintéticas reconstruídas dos fixtures; relatório `verovio_dart/prompts/reports/04d.md`),
      04e ✓ (`AdjustHarmGrpsSpacing`, `AdjustTempo`, `AdjustSylSpacing` portados, ligados em
      `layOutVertically` logo após o `HeadlessExtents` — não em `layOutHorizontally` como o C++,
      mesmo motivo do `AdjustArpeg` já portado; sem largura de texto renderizada (tarefa 05-12)
      `Harm`/`Tempo` recebem content box de largura zero e `Syl` nenhuma, então a paridade numérica
      fim-a-fim ainda não é possível em produção — paridade exercitada por árvores sintéticas com o
      content box exato do fixture (37 valores, 37 batem, epsilon 0). Três achados fora de escopo
      em código de fases anteriores: `AttNIntegerComparison` nunca casa `@n` ausente (nenhum
      `<verse>` sem `@n` é visitado em produção, afeta também `PrepareLyricsFunctor`), deslocamento
      constante por compasso em `harm-001.mei` e falha de resolução de `@tstamp` num compasso de
      anacruse em `tempo-001.mei`; relatório `verovio_dart/prompts/reports/04e.md`), 04f ✓
      (`AdjustXOverflow`, `CacheHorizontalLayout`, `CalcSpanningBeamSpans` portados; ligados em
      `layOutVertically`/`prepareData`, não em `layOutHorizontally`/`ResetAligners` como o C++,
      mesmo motivo das tarefas 04b/04e (precisam dos floating positioners que só existem após o
      `HeadlessExtents`). Corrigiu de quebra um cache de largura/xRel de `Measure` que estava
      conflado dentro de `setDrawingXRel` desde antes desta tarefa — `section/section-001.mei`
      (20 compassos, 4 páginas, o cast-off mais pesado do corpus validado) passou de timemap
      divergente para **match (20/20)**. Nenhum arquivo do corpus fixado exercita o ramo de
      "trabalho real" de nenhum dos três functors sob a invocação padrão do projeto (sem
      `--breaks`/página estreita forçada) — overflow nunca dispara, `restore=true` nunca roda numa
      única carga, e o único `beamSpan` do corpus nunca cruza sistema —, então esses ramos foram
      verificados em árvores sintéticas derivadas à mão do algoritmo do C++, não do fixture; ~1114
      valores de fixture comparados nos ramos que o corpus exercita, todos batem em epsilon 0.
      `BeamSpan.addSpanningSegment`'s coordinate lookup continua bloqueado por
      `BeamDrawingInterface::InitCoords` não portado (mesma lacuna que 04d documentou para
      `Beam`/`FTrem`); relatório `verovio_dart/prompts/reports/04f.md`), 04g ✓
      (`AdjustOssiaStaffDef`, `AdjustNeumeX`, `CalcLedgerLines` portados. Os dois primeiros ligados
      em `layOutVertically`, não em `layOutHorizontally` como o C++, mesmo motivo de 04b/04e/04f
      (precisam das bounding boxes de conteúdo que só existem após o `HeadlessExtents`);
      `CalcLedgerLines` roda **duas vezes**, como no C++ (`layOutVertically` antes do
      `AlignVertically`, e num novo `Page.layOutPitchPos()` espelhando `Page::LayOutPitchPos` — este
      não é chamado pelo `layOut()` padrão nem pelo C++, só por `Toolkit::RedoPagePitchPosLayout`,
      API interativa ainda não portada). `AdjustOssiaStaffDefFunctor` nunca sai do ramo trivial em
      nenhum dos três arquivos fixados — **inclusive no C++**: `Layer::DrawOssiaStaffDef` só fica
      `true` via `ScoreDefSetOssiaFunctor` (tarefa 04h — **portado agora**, ver 04h abaixo), então
      o ramo `assert(ossia)`-guarded de `VisitLayerElement` seguia inalcançável nesta porta com
      qualquer entrada até então; continua inalcançável hoje por um motivo diferente:
      `AlignHorizontallyFunctor::VisitLayer` ainda não *consome* `DrawOssiaStaffDef()` (lacuna
      registrada em `align_horizontally.dart` e no relatório da 04h). O achado colateral que essa
      lacuna causava — `doc.layOut()` **lançava** sob `dart test` para qualquer arquivo com
      `<ossia>` real (`AlignHorizontallyFunctor.visitStaff`'s `assert(drawingStaffDef != null)`
      nunca via o `drawingStaffDef` que só `ScoreDefSetOssiaFunctor` setaria) — está **fechado**
      pela 04h. `AdjustNeumeXFunctor` foi validado por
      reconstrução sintética por registro (`neume/neume-002.mei`, não `neume-001.mei` — este carrega
      `<facsimile type="transcription">`, então o C++ real roteia por `Page::LayOutTranscription`,
      que nunca chama nenhum dos três functors desta tarefa), porque o espaçamento horizontal de
      documentos neume já diverge do C++ por causas anteriores a esta tarefa (armadilha já registrada
      na tarefa). `CalcLedgerLinesFunctor` tem paridade de produção fim-a-fim em `note/note-009.mei`
      para a parte de altura (`drawingLoc`/contagem de linhas), e por reconstrução sintética para a
      posição X (mesmo motivo do neume: pequeno desvio horizontal pré-existente, não desta função);
      relatório `verovio_dart/prompts/reports/04g.md`)
- [ ] **Functors de transcrição** (`AdjustXRelForTranscription`, `AdjustYRelForTranscription`,
      `ApplyPPUFactor`) e `ReorderByXPos`.
- [x] **`ScoreDefOptimize` / `ScoreDefSetOssia`** (tarefa 04h: `ScoreDefOptimizeFunctor` e
      `ScoreDefSetOssiaFunctor` portados em `setscoredef_functor.dart`, ligados em
      `Doc.scoreDefOptimizeDoc()` / `Doc.scoreDefSetCurrentDoc()`; as 4 opções `condense*`
      acrescentadas a `options_shell.dart` com os defaults exatos do C++ (`condense=auto`, as
      outras três `false` — `CONDENSE_all` existe no enum mas não tem string de CLI em
      `options.cpp`, então só é alcançável programaticamente). `score/score-002.mei`, sugerido pelo
      prompt, nunca chega a `ScoreDefOptimizeDoc` sob opções default — nem `@optimize` nem `>1
      grpSym` — e foi trocado por `section/section-004.mei` (já teste ausente de qualquer fixture,
      tem `@optimize="true"` e uma seção de restart que derruba um staff inteiro), gerado com
      `cpp_probe/run.sh --opt --condense-first-page`, extensão desta tarefa ao `run.sh` para
      repassar flags de CLI ao binário instrumentado. Corrigido de passagem:
      `Staff::GetClassName` (`"oStaff"` vs `"staff"`) e `Staff::AttributesToInternal` (deslocamento
      de `@n` por `ossiaNOffset`) não estavam portados — sem eles nenhum caminho estrutural
      envolvendo `<oStaff>` bate com o C++; acrescentado `Staff.drawingIsVisible()`
      (`Staff::DrawingIsVisible`), o único consumidor natural de `StaffDef.GetDrawingVisibility()`.
      Relatório `verovio_dart/prompts/reports/04h.md`.
- [x] Corrigir `tool/gen_elements.py`, que **não reproduz** os `*_gen.dart` atuais (rodá-lo apaga
      código escrito à mão), os registros errados do `ObjectFactory` e o bug de interpolação de
      `tool/validate_layout.dart` (tarefa 04i — o gerador foi **aposentado** em vez de consertado,
      renomeado para `tool/gen_elements.py.obsolete`; os `*_gen.dart` passaram a ser mantidos à mão).
- [x] Revalidação da fase com melhora medida em `tool/validate_layout.dart` (tarefa 04j: 621
      arquivos, 176 timemaps match vs 24 na baseline de 2026-08-26, sequência de functors
      assertada contra `page.cpp` nos testes, 9 fixtures regenerados byte a byte idênticos;
      relatório `verovio_dart/prompts/reports/04j.md`).

### Fase 5 — Renderização SVG (~8–10 sessões) — **NÃO INICIADA (0%)**

> Medido em 2026-08-26: `SvgDeviceContext` não existe (0 contra 1.417 linhas no C++);
> `lib/src/drawing/` está vazio; **nenhum teste compara contra os 623 SVGs de
> `test/golden/cpp/`**. Volume C++ a portar: **13.425 linhas** (12 `view*.cpp` +
> `devicecontext.cpp` + `svgdevicecontext.cpp` + `bboxdevicecontext.cpp`).
> `bbox_device_context.dart` cobria 38/40 métodos — fechado pela 05-05 (40/40).

- [x] **Harness de comparação de SVG** (`tool/compare_svg.dart` + `test/svg_golden_test.dart`),
      modos estrutural e numérico, sobre os 623 goldens — **primeira tarefa da fase** (05-00).
- [x] `devicecontext.cpp`/`devicecontextbase` e `Resources` completados (05-01); `bboxdevicecontext.cpp`
      fechado (05-05). — 05-01 ✓, 05-05 ✓
- [ ] `SvgDeviceContext` (saída estruturalmente idêntica à do C++: estrutura, ids, classes, `<defs>`)
      (05-02 a 05-04). — 05-02 ✓, 05-03 ✓, 05-04 ✓
- [x] `View` + `view_graph` — esqueleto e primitivas gráficas (05-06, 05-07). — 05-06 ✓, 05-07 ✓
- [x] `view_page.cpp` — página, sistema, scoreDef, medida, pentagrama, camada (05-08 a 05-11). — 05-08 ✓, 05-09 ✓, 05-10 ✓, 05-11 ✓
- [x] **Virada**: ligar o layout ao `View` real (`BBoxDeviceContext` como em `page.cpp:410` e `:532`),
      **deletar `lib/src/rendering/headless_extents.dart`** e revalidar toda a Fase 4 (05-12). — 05-12 ✓
- [ ] `view_element.cpp` — notas/hastes, acidentes/articulações, pausas, clefs/keySig/meterSig
      (05-13 a 05-16). — 05-13 ✓, 05-14 ✓, 05-15 ✓, 05-16 ✓
- [x] `view_beam`, `view_tuplet`, `view_slur`, `view_text` (05-17 a 05-19). — 05-17 ✓, 05-18 ✓, 05-19 ✓
- [x] `view_control.cpp` — famílias de objetos flutuantes (05-20 a 05-22). — 05-20 ✓, 05-21 ✓, 05-22 ✓
- [x] `view_mensural`, `view_neume`, `view_tab` (05-23, 05-24). — 05-23 ✓, 05-24 ✓
- [ ] Perseguição da cauda de divergências até igualdade numérica nos 623 arquivos (05-25).

### Fase 6 — Features de alto nível (~5–7 sessões) — **NÃO INICIADA (0%)**

> Medido em 2026-08-26: `lib/src/midi/` e `lib/src/editing/` estão vazios.
> Volume C++: **15.300 linhas**. Correção de escopo: `editortoolkit_cmn.cpp` tem
> **23 linhas** (só construtor/destrutor em 6.2.0) — toda a funcionalidade CMN está em
> `editortoolkit_shared.cpp` (902). O peso está no Neume: `editortoolkit_neume.cpp` = 4.498.

- [ ] `resetfunctor.cpp` (907) — completar os `Reset*` faltantes (06-01).
- [ ] `findfunctor.cpp` (477) + `findlayerelementsfunctor.cpp` (280) — as 6 buscas sem contraparte
      e os 4 functors de layer-elements (06-02, 06-03).
- [ ] `convertfunctor.cpp` (1.465) — `ConvertMarkupAnalytical`, `ConvertToCmn`, `ConvertToMensuralView`
      (06-04 a 06-06).
- [ ] `miscfunctor.cpp` (185) + functors de transcrição + `facsimile.cpp` (108) e
      `facsimilefunctor.cpp` (06-07).
- [ ] **`MEIOutput` (3.416)** + `savefunctor.cpp` (187) + `Toolkit.getMEI` real (06-08 a 06-11).
- [ ] `expansion.cpp` (65) + selection + `CastOffToSelection` + `editfunctor.cpp` (147) (06-12).
- [ ] `scoringupfunctor.cpp` (734) (06-13).
- [ ] Export MIDI: `midifunctor.cpp` (1.324) + `timemap.cpp` (110) + writer MIDI próprio
      (06-14 a 06-17). Aceite: comparar com `build/verovio -t midi` e `-t timemap`.
- [ ] `featureextractor.cpp` (173) (06-18).
- [ ] Transposição: `transposition.cpp` (2.252) + `transposefunctor.cpp` (425) (06-19 a 06-21).
- [ ] EditorToolkit: `editortoolkit.cpp` (110) + `editortoolkit_shared.cpp` (902) + CMN (23)
      + `editortoolkit_neume.cpp` (4.498) (06-22 a 06-24).

### Fase 7 — API pública e acabamento (~2–3 sessões) — **~5%**

> Medido em 2026-08-26: `lib/src/toolkit.dart` tem 265 linhas e é load-only
> (`ready`, `getMEI`, `setInputFrom`, `loadData`, `loadFile`, `loadZipData`, `loadZipFile`,
> `isZipFile`). `lib/src/core/options_shell.dart` (566 linhas) é um esqueleto declarado.
> **Correção de escopo: não são "~100 opções", são 210**, registradas em 10 grupos em
> `origin/src/src/options.cpp` (Input/page 54, General layout 82, Selectors 14, Element margins 45,
> Midi 3, Mensural 6, Neume 4, JSON 1, Deprecated 1).

- [x] Load: `loadData`/`loadFile`/`loadZipData`/`getMEI` + detecção de formato.
- [ ] `options.cpp` (2.185) — tipos `Option*`, grupos e as 210 opções (07-01 a 07-05).
- [ ] `toolkit.cpp` (2.431) — render/getSVG/getPageCount/getMIDI/timemap/editor API
      (07-06 a 07-08).
- [ ] `DrawingDeviceContext`: adapter para `dart:ui` Canvas (Flutter-friendly,
      **sem importar dart:ui no core** para manter compatibilidade web/server) (07-09).
- [ ] Documentação, exemplos, pubspec final, benchmark básico (07-10).

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Volume (~190k linhas C++ em escopo) | Geradores de código onde o original também é gerado (atts MEI); port incremental sempre compilável/testável |
| Divergências sutis de layout vs C++ | Goldens gerados do binário C++ real, comparados estruturalmente |
| Aritmética de ponto flutuante/ponteiros | Usar `double` + referências a objetos Dart; sem pointer math no original (C++ "moderno") |
| Regex/std::regex no parsing ABC | `RegExp` do Dart (sintaxe ECMA compatível nos usos do verovio) |
| Performance em Flutter mobile | Evitar alocação excessiva na árvore de objetos; medir na Fase 7 |

## Definição de pronto (v1.0)

- Todos os formatos de entrada funcionando: MEI/MusicXML/ABC (build sem Humdrum; PAE excluído do escopo)
- SVG byte-comparável (estruturalmente idêntico) aos goldens do C++ para o corpus inteiro
- Export MIDI e timemap corretos
- Toolkit API completa com todas as **210** opções (10 grupos de `origin/src/src/options.cpp`)
- Testes automatizados rodando em < 10 min
