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

Fora de escopo por decisão: `humlib` (~143 mil linhas), `iohumdrum.*` (~34 mil), IOPAE
(Plaine & Easie) e os filtros desabilitados por padrão no C++ (darms, cmme, volpiano, gabc).

Terceiros bundled substituídos: pugixml → `package:xml`; nlohmann/json → `dart:convert`;
CRC32, zip e tuning-library → ports próprios / `package:archive`.

A série de prompts de execução vive em `verovio_dart/prompts/` — comece por `prompts/README.md`.

## Estado medido

> **Medido em 2026-08-29**, tudo reexecutado do zero (não são números herdados de relatório).

| Métrica | Valor |
|---|---|
| `dart analyze` | 8 issues (baseline; todos em `tool/_scratch_*`) |
| `dart test` | 681 testes, ~7 min, verdes |
| `compare_svg --all` | **115/623 estrutural (18,5%)**, **4/623 numérico (eps 0)**, 3 exceções |
| `validate_layout` | 618/621 layout OK, 173/191 timemaps batendo |

| Fase | Estado | Fecha com |
|---|---|---|
| 0 — Infraestrutura | ✅ concluída | — |
| 1 — Fundações | 🔶 faltam `SetCSSFont` e `UseLiberationTextFont` em `Resources` | `2026-08-29-02` |
| 2 — Modelo de dados MEI | ✅ concluída (129/129) | `2026-08-29-03` |
| 3 — Leitura de arquivos | ✅ concluída | `2026-08-29-04` |
| 4 — Motor de layout | 🔶 falta `Page::LayOutTranscription` + 4 functors | `2026-08-29-05` |
| 5 — Renderização SVG | 🔶 largura completa, fidelidade em 18,5% | `05-34b`..`05-36` |
| 6 — Features de alto nível | ⬜ não iniciada | — |
| 7 — API pública | 🔶 ~5% (load-only; 118 das 210 opções) | — |

> **O portão.** `dart run tool/verify_phases.dart` mede cada critério de conclusão contra a árvore
> — nunca contra um checkbox ou relatório — e sai com código ≠ 0 se alguma fase não fechou.
> `--full` regera as medições caras antes de julgar; `--fase=N` isola uma fase. A série de prompts
> que fecha as Fases 1 a 5 e prova que fecharam está em `verovio_dart/prompts/`, prefixada
> `2026-08-29-`.

> **⚠️ Ressalva sobre o `dart analyze = 8`.** Ele não mede a saúde do código de rendering.
> `lib/src/rendering/` tem **739 `as dynamic`** e **820 `catch (_)`** em 10 arquivos — 514/468 só
> em `view_control.dart`, 118/151 em `view_element.dart`; `model/` + `layout/` somam mais 251/100.
> Nove arquivos de rendering têm `ignore_for_file`, e `view_control.dart` suprime os próprios erros de tipo
> (`invalid_assignment`, `argument_type_not_assignable`, `unchecked_use_of_nullable_value`).
> A 05-34 mediu o custo: tirar só os `as dynamic` desse arquivo expôs **115 erros de tipo**, cada
> um um membro de modelo inexistente — e os catches vazios transformam cada um num ramo de
> desenho silenciosamente pulado. É a causa direta de famílias inteiras renderizarem 0/N.

## Estratégia de validação

1. Binário CLI do Verovio C++ 6.2 sem Humdrum (`-DNO_HUMDRUM_SUPPORT=ON`) em `build/verovio`.
2. Corpus: 623 arquivos em `verovio_dart/test/corpus/` (2 deliberadamente não-UTF-8, pulados).
3. `tool/golden.sh` gera os 623 SVGs de referência em `test/golden/cpp/`.
4. `tool/compare_svg.dart` compara Dart vs golden (estrutural e numérico) → `tool/SVG_VALIDATION.md`;
   `tool/validate_layout.dart` compara layout e timemaps → `tool/LAYOUT_VALIDATION.md`.
5. `cpp_probe/` extrai dados de referência do C++ instrumentado (fixtures JSON Lines versionados em
   `verovio_dart/test/fixtures/cpp/<id>/`). Convenções em `prompts/00-MESTRE.md` §6-bis.

## Fases

### Fase 0 — Infraestrutura ✅

- [x] Scaffold do package, binário C++ de referência, corpus + goldens, conversão dos assets.

### Fase 1 — Fundações — 🔶 falta 1 item

- [x] `vrvdef.h` → enums, constantes, unidades.
- [x] Logging, `RuntimeClock`, utilitários (`misc`, `crc`, `fraction`).
- [x] `BoundingBox`, `DeviceContext` (abstrata), `BBoxDeviceContext` (40/40 métodos), `devicecontextbase`.
- [ ] `Resource`/carregador de fontes SMuFL via assets (`Glyph`, `Resources`, leitura plugável).
      Falta portar `Resources::SetCSSFont` e `Resources::UseLiberationTextFont`
      (`origin/src/include/vrv/resources.h`) — tarefa `2026-08-29-02`.

### Fase 2 — Modelo de dados MEI — ✅ concluída

- [x] Classe base `Object` (árvore, filhos, índices, IDs hash/base36), `ObjectListInterface`, `ObjectFactory`.
- [x] Interfaces MEI (`lib/src/model/interfaces/`): Position, Pitch, TimePoint/TimeSpanning, Duration,
      Facsimile, Linking, Plist, ScoreDef, TextDir, AltSym, AreaPos, Offset…
- [x] Classes de atributos MEI geradas por `tool/gen_atts.dart` (160 enums, 287 classes, ~520 atributos,
      um mixin por classe `Att*` em 22 módulos + runtime `mei_values.dart`).
- [x] ~140 classes de elementos, **129/129 registradas no `ObjectFactory`** (38 manuais + 91 em
      `factory_registry_gen.dart`) — `oStaff` (`staff.cpp:47`, `Staff(1, isOssia: true)`) e
      `stageDir` (`dir.cpp:32`, `Dir(isStageDir: true)`) fechados em `2026-08-29-03` com
      pseudo-`ClassId`s `factoryOstaff`/`factoryStagedir` (`vrvdef.h:287-288`); antes 127/129
      porque o `ClassRegistrar` quebrado em duas linhas escapou da auditoria de 2026-08-26.
- [x] Editorial (app/lem/rdg/sic/corr…), linking, `ExpansionMap`, `Comparison`, `CustomTuning`, `Doc`/`Page`/`Pages`.
- [x] `ScoreDef`, `StaffDef`, `StaffGrp`, running elements (pghead/pgfoot).

### Fase 3 — Leitura de arquivos ✅ (escrita de MEI é Fase 6, por decisão de 2026-08-29)

- [x] `IOBase` + detecção de formato (`format.dart`), Toolkit com load/zip/MXL/UTF-16.
- [x] **IOMEI — leitura** (`mei_input.dart`, ~5,3k linhas): estrutura page-based/score-based, layer/control/text,
      editorial markup, facsimile, upgrades MEI 3.0/4.0/5.0→6.0, árvore mutável `xml_node.dart`.
      Os **187 `MEIInput::Read*`** do C++ têm contraparte Dart.
- [x] **IOMusXML** (`iomusxml.dart`, ~6,5k linhas): score-partwise completo. Os 15 `MusicXmlInput::Read*`
      têm contraparte; 0 divergências estruturais no corpus `midi/*.musicxml` via `tool/validate_io.dart`.
- [x] **IOABC** (`ioabc.dart`, ~2,1k linhas): campos I:/K:/L:/M:/Q:/X:/w:, beams/tuplets/chords/grace/
      decorations/lyrics/repeats; 13 cenários testados.
- [x] Formatos desabilitados por padrão no C++ (iodarms, iocmme, iovolpiano, gabc): não portados,
      por paridade de build default. Incipits PAE em `<incipCode>` são pulados com warning.

> **Decisão de escopo 2026-08-29:** a Fase 3 cobre **leitura** de arquivos. A escrita de MEI
> (`MEIOutput`, 3.416 linhas / 200 métodos em `origin/src/src/iomei.cpp`) é da **Fase 6**
> (`06-08` a `06-11`). `Toolkit.getMEI()` hoje (`toolkit.dart:69`) devolve a string carregada,
> não a árvore serializada — o comportamento serializado será entregue na Fase 6.

### Fase 4 — Motor de layout — 🔶 falta 1 item

> `lib/src/layout/` tem 22.851 linhas e 89 classes `*Functor` (o C++ tem 135; dos 46 ausentes,
> 42 são da Fase 6 — MIDI, transpose, convert, find, save, scoringup, facsimile).
> A virada para o `View` real foi cumprida na 05-30: `bbox_fallback.dart`/`headless_extents.dart`
> deletados, 0 comentários `Approximation:` restantes.

- [x] Sistema de functors (`FunctorInterface`, despacho via `kAcceptChain`). `ConstFunctor`/
      `DocConstFunctor` não portados de propósito (Dart não tem const-correctness — desvio documentado).
- [x] `HorizontalAligner`/`VerticalAligner`, grace aligner, timestamp aligner.
- [x] Preparação de dados (`preparedata_functor.dart`, 30 functors `Prepare*`).
- [x] Cast off (`cast_off.dart`, `cast_off_mensural.dart`) e justify (`justify.dart`).
- [x] Posicionamento de floating objects (`floating_positioner.dart`, `slur_positioning.dart`,
      `adjust_floating.dart`, `adjust_slurs.dart`).
- [x] Mensural/neume specifics (`mensural_neume.dart`).
- [x] Infraestrutura de extração de dados do C++ (`cpp_probe/` + `test/fixtures/`), provada ponta a ponta:
      SVG do binário instrumentado idêntico ao do limpo, execuções reprodutíveis byte a byte.
- [x] Base numérica da fase (04-00): `DEFINITION_FACTOR` aplicado nas 7 opções `definitionFactor`;
      `Rest` sem registro de `InterfaceId.duration` corrigido. Relatório `prompts/reports/04-00.md`.
- [x] 19 functors de ajuste horizontal/vertical (04a–04g): `AdjustLayers`, `AdjustDots`, `AdjustArtic`,
      `AdjustArticWithSlurs`, `AdjustAccidX`, `AdjustTupletsX/Y`, `AdjustTupletNumOverlap`,
      `AdjustTupletWithSlurs`, `AdjustBeams`, `AdjustHarmGrpsSpacing`, `AdjustTempo`, `AdjustSylSpacing`,
      `AdjustXOverflow`, `CacheHorizontalLayout`, `CalcSpanningBeamSpans`, `AdjustOssiaStaffDef`,
      `AdjustNeumeX`, `CalcLedgerLines`. Relatórios `prompts/reports/04{a..g}.md`.
- [x] `ScoreDefOptimize` / `ScoreDefSetOssia` (04h) + as 4 opções `condense*`. Corrigidos de passagem
      `Staff::GetClassName`, `Staff::AttributesToInternal` e `Staff::DrawingIsVisible`.
      Relatório `prompts/reports/04h.md`.
- [x] `tool/gen_elements.py` **aposentado** (04i): os `*_gen.dart` passaram a ser mantidos à mão;
      registros errados do `ObjectFactory` corrigidos. Relatório `prompts/reports/04i.md`.
- [x] Revalidação da fase (04j): 621 arquivos varridos, timemaps 176 match vs 24 na baseline,
      sequência de functors assertada contra `page.cpp`. Relatório `prompts/reports/04j.md`.
- [ ] **Functors de transcrição** (`AdjustXRelForTranscription`, `AdjustYRelForTranscription`,
      `ApplyPPUFactor`) e `ReorderByXPos` — **verificado 2026-08-29: 0 ocorrências em `lib/`.**
      Único item aberto da fase, e maior do que parece: os dois primeiros só têm chamador dentro de
      `Page::LayOutTranscription` (`page.cpp:307/309`), que **também não está portado**;
      `ApplyPPUFactor` roda na leitura (`iomei.cpp:4462`), não no layout; e `ReorderByXPos` só é
      consumido pelo editor de neumas (Fase 6). `test/corpus/neume/neume-001.mei` é o único arquivo
      do corpus que exercita o caminho de transcrição. Tarefa `2026-08-29-05`.

### Fase 5 — Renderização SVG — 🔶 largura completa, fidelidade em 18,5%

> **Largura:** os 15 `view*.cpp` (13.425 linhas) têm contraparte Dart (20.183 linhas).
> `view_element` 37 métodos `Draw*` vs 39 do C++ (os 4 "faltantes" existem com nome adaptado),
> `view_control` 36/36.
>
> **Fidelidade (medida 2026-08-29):** **115/623 estrutural, 4/623 numérico**, 3 exceções.
> **46 das 75 categorias do corpus têm zero arquivos estruturalmente limpos.**

Famílias inteiras em zero (as maiores): ligature 0/50, mensural 0/25, tuplet 0/22, lyric 0/16,
dir 0/12, dynam 0/10, trill 0/8, arpeg 0/7, beamspan 0/6, dot 0/6.
Melhores: mensur 8/8 (a única família completa), beam 37/61, accid 9/14, score 6/16, stem 6/16.

Exceções durante a renderização: `ftrem/ftrem-002.mei` (`_TypeError`),
`stem/stem-014.mei` e `stem/stem-016.mei` (`Cannot remove from an unmodifiable list`).

- [x] Harness de comparação de SVG (`tool/compare_svg.dart` + `test/svg_golden_test.dart`), modos
      estrutural e numérico sobre os 623 goldens (05-00). Honestizado na 05-26 — os 489 "limpos"
      anteriores eram goldens devolvidos por bridges; `test/harness_integrity_test.dart` guarda contra
      a reintrodução disso.
- [x] `devicecontext.cpp`/`devicecontextbase` e `Resources` (05-01); `bboxdevicecontext.cpp` (05-05).
- [x] `SvgDeviceContext` — estrutura, ids, classes, `<defs>` (05-02 a 05-04).
- [x] `View` + `view_graph` — esqueleto e primitivas gráficas (05-06, 05-07).
- [x] `view_page.cpp` — página, sistema, scoreDef, medida, pentagrama, camada (05-08 a 05-11).
- [x] **Virada**: layout ligado ao `View` real com `BBoxDeviceContext` (`page.cpp:410`/`:532`),
      `bbox_fallback.dart` deletado, BBox parity 17662 → 37849/52568 (72%) — cumprida pela **05-30**
      (a 05-12 não cumpriu: só renomeou `headless_extents`→`bbox_fallback` e manteve o `try/catch`).
- [x] `view_beam`, `view_tuplet`, `view_slur`, `view_text` (05-17 a 05-19). O motor
      `BeamSegment::CalcBeam` foi portado reduzido (CMN) na 05-31; as 1500 linhas completas ficam na 05-31b.
- [x] `view_control.cpp` — famílias de objetos flutuantes (05-20 a 05-22).
- [x] `view_mensural`, `view_neume`, `view_tab` (05-23, 05-24).
- [x] Três defeitos de modelo que bloqueavam o corpus inteiro — `isSystemElement`/`isSystemElementId`
      via `classId`, `SystemMilestoneEnd`/`PageMilestoneEnd` sem `id = start.id`, `Stem.visible` só de
      `AttStems`, `drawSystemElement` sem `else` (05-27). 0 → 112/623 estrutural.
- [x] `textlayoutelement.cpp` e `runningelement.cpp`: grade de 9 células, alturas,
      `AdjustRunningElementYPos`, `GetTotalHeight` (05-28).
- [x] Header e footer no layout: alturas, cast-off e o deslocamento do sistema (05-29). 112 → 114/623.
- [x] Dívidas da Fase 4 marcadas "arrives with rendering phase" — 8 quitadas (05-32). Numérico 1 → 4/623.
- [x] Testes de renderização de verdade — as 53 asserções `expect(content, contains(...))` que faziam
      grep no próprio fonte viraram catraca por família + asserções sobre o SVG + `RecordingDeviceContext`
      (05-33). Relatório `prompts/reports/05-33.md`.
- [ ] **`view_element.cpp`** — notas/hastes, acidentes/articulações, pausas, clefs/keySig/meterSig
      (05-13 a 05-16): **reabertos**, foram fechados contra o harness inválido pré-05-26.
- [ ] **Fidelidade de `view_control`** (05-34) — **parcial**. `fix_dynamic.py` zerou os 468 `as dynamic`
      mas expôs 115 erros de tipo, e a tipagem de `view_control.dart` foi revertida. Entregue em
      `1d31040`: 11 opções faltantes, `GetTstampStaves`/`isOrdered`/`calculatePrincipalStaff`/
      `Octave` drawing + getters `AttLineRend` (19 de 179 membros). Faltam 160 membros → **05-34b**,
      por famílias `Draw*`. Relatório `prompts/reports/05-34.md`.
      A regressão que `1d31040` expôs em `test/vertical_layout_test.dart` foi **fechada** pela
      `2026-08-29-01`: `View::DrawTempo` retorna cedo quando `GetStart()` é nulo
      (`view_control.cpp:2741`) e o Dart testava exceção em vez de nulo. É a primeira confirmação
      empírica, em produção, do mecanismo descrito na ressalva do topo deste documento — um
      `catch (_)` escondendo um defeito real, revelado no instante em que o membro de modelo
      passou a existir. Relatório `prompts/reports/2026-08-29-01.md`.
- [ ] **Perseguição da cauda até igualdade numérica nos 623 arquivos** (05-25) — reaberta (fechada
      contra o harness inválido). É o item que fecha a fase.

> **Recomendação de sequência.** Antes de perseguir divergências uma a uma, quitar a dívida de
> tipagem descrita na ressalva do topo: enquanto os `catch (_)` vazios estiverem no lugar, cada
> membro de modelo faltante vira um ramo de desenho pulado em silêncio, e o número de divergências
> não distingue "algoritmo errado" de "código nunca executado". A catraca por família da 05-33 já
> existe para segurar o resultado enquanto isso é feito.

### Fase 6 — Features de alto nível ⬜ não iniciada

> `lib/src/midi/` e `lib/src/editing/` estão vazios. Volume C++: ~15.300 linhas.
> O peso está no Neume: `editortoolkit_neume.cpp` = 4.498 linhas
> (`editortoolkit_cmn.cpp` tem só 23 — a funcionalidade CMN está em `editortoolkit_shared.cpp`, 902).

- [ ] `resetfunctor.cpp` (907) — completar os `Reset*` faltantes (06-01).
- [ ] `findfunctor.cpp` (477) + `findlayerelementsfunctor.cpp` (280) — as 6 buscas sem contraparte
      e os 4 functors de layer-elements (06-02, 06-03).
- [ ] `convertfunctor.cpp` (1.465) — `ConvertMarkupAnalytical`, `ConvertToCmn`, `ConvertToMensuralView`
      (06-04 a 06-06).
- [ ] `miscfunctor.cpp` (185) + functors de transcrição + `facsimile.cpp` (108) e
      `facsimilefunctor.cpp` (06-07). O getter `m_drawingFacsX/Y` saiu na 05-32; o setter
      (`ApplyFacsimile`, `AdjustXRelForTranscription` etc.) fica aqui.
- [ ] **`MEIOutput` (3.416)** + `savefunctor.cpp` (187) + `Toolkit.getMEI` real (06-08 a 06-11) — item herdado da Fase 3 por decisão de 2026-08-29 (ver Fase 3).
- [ ] `expansion.cpp` (65) + selection + `CastOffToSelection` + `editfunctor.cpp` (147) (06-12).
- [ ] `scoringupfunctor.cpp` (734) (06-13).
- [ ] Export MIDI: `midifunctor.cpp` (1.324) + `timemap.cpp` (110) + writer MIDI próprio
      (06-14 a 06-17). Aceite: comparar com `build/verovio -t midi` e `-t timemap`.
- [ ] `featureextractor.cpp` (173) (06-18).
- [ ] Transposição: `transposition.cpp` (2.252) + `transposefunctor.cpp` (425) (06-19 a 06-21).
- [ ] EditorToolkit: `editortoolkit.cpp` (110) + `editortoolkit_shared.cpp` (902) + CMN (23)
      + `editortoolkit_neume.cpp` (4.498) (06-22 a 06-24).

### Fase 7 — API pública e acabamento — 🔶 ~5%

> `lib/src/toolkit.dart` tem 277 linhas e é load-only. `lib/src/core/options_shell.dart` tem 884
> linhas e **118 das 210 opções** registradas em `origin/src/src/options.cpp`
> (Input/page 54, General layout 82, Selectors 14, Element margins 45, Midi 3, Mensural 6,
> Neume 4, JSON 1, Deprecated 1).

- [x] Load: `loadData`/`loadFile`/`loadZipData`/`getMEI` + detecção de formato.
- [ ] `options.cpp` (2.185) — tipos `Option*`, grupos e as 92 opções restantes (07-01 a 07-05).
- [ ] `toolkit.cpp` (2.431) — render/getSVG/getPageCount/getMIDI/timemap/editor API (07-06 a 07-08).
      É o que liga o `View` já portado à API pública: hoje o único caminho até um SVG é
      `renderSvgForComparison` em `lib/src/testing/svg_compare.dart`.
- [ ] `DrawingDeviceContext`: adapter para `dart:ui` Canvas (Flutter-friendly, **sem importar
      dart:ui no core** para manter compatibilidade web/server) (07-09).
- [ ] Documentação, exemplos, pubspec final, benchmark básico (07-10).

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Volume (~190k linhas C++ em escopo) | Geradores onde o original também é gerado (atts MEI); port incremental sempre compilável/testável |
| **Código de rendering escrito em `dynamic` com exceções engolidas** | Ressalva do topo; catraca por família da 05-33 para segurar regressões enquanto se tipifica |
| Divergências sutis de layout vs C++ | Goldens do binário C++ real + fixtures do `cpp_probe/` com epsilon 0 |
| Aritmética de ponto flutuante/ponteiros | `double` + referências a objetos Dart; sem pointer math no original |
| Regex/std::regex no parsing ABC | `RegExp` do Dart (sintaxe ECMA compatível nos usos do verovio) |
| Performance em Flutter mobile | Evitar alocação excessiva na árvore de objetos; medir na Fase 7 |

## Definição de pronto (v1.0)

- Todos os formatos de entrada funcionando: MEI/MusicXML/ABC (build sem Humdrum; PAE excluído)
- SVG estruturalmente idêntico aos goldens do C++ **nos 623 arquivos do corpus** (hoje: 115)
- Export MIDI e timemap corretos
- Toolkit API completa com as **210** opções (hoje: 118)
- Testes automatizados rodando em < 10 min (hoje: ~7 min)
