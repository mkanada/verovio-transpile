# AUDITORIA — estado real do port Verovio 6.2.0 → Dart

**Data da medição:** 2026-08-26
**Método:** todas as afirmações abaixo vêm de um comando executado neste workspace. Onde a saída é longa,
está resumida, mas o comando está sempre citado para reprodução. Nenhum arquivo de `lib/`, `test/` ou `tool/`
foi modificado nesta auditoria (os geradores foram executados e os arquivos originais restaurados e
reconferidos byte a byte).

A série de prompts de execução derivada desta auditoria está em `prompts/README.md` (70 tarefas).

---

## 0. Resumo executivo

| Fase | % pronto | Veredito curto |
|---|---:|---|
| 0 — Infraestrutura | 100% | Feita. |
| 1 — Fundações | ~95% | Feita, menos alguns métodos de `Resources` e `GetPenWidthOverlap`. |
| 2 — Modelo MEI | ~97% | Feita. Defeitos pontuais de registro no `ObjectFactory`. |
| 3 — Leitura de arquivos | ~95% | Feita (MEI/MusicXML/ABC). Corpus MusicXML mínimo (5 arquivos). |
| 3 — **Escrita de MEI** | **0%** | **`MEIOutput` não existe**; `getMEI()` ecoa o input. 3.416 linhas a portar. |
| 4 — Layout | **~55%** | Parcial. 60 functors do C++ faltam; a matemática de bbox é aproximada. |
| 5 — View + SVG | **0%** | Não iniciada. |
| 6 — Features | **0%** | Não iniciada. |
| 7 — API pública | **~5%** | Só o load; `options_shell.dart` é um esqueleto de 566 linhas. |

Três achados que mudam o plano e que **não estavam registrados em lugar nenhum**:

1. **`tool/gen_elements.py` NÃO reproduz os arquivos `*_gen.dart` atuais.** Rodá-lo destrói código
   escrito à mão. Detalhe na seção 6.
2. **`lib/src/model/factory_registry_gen.dart` registra 4 classes com o nome errado** (`'dots'` para
   `Dots`, `Flag`, `TupletBracket` e `TupletNum`) e 7 classes com nome divergente do C++. Seção 5.
3. **`tool/validate_layout.dart` tem um bug de interpolação** que imprime
   `y∈[Instance of 'SystemMetrics'.minStaffYRel, …]` em vez dos números. Seção 7. → tarefa **04i**.
4. **`MEIOutput` não está portado** — 3.416 linhas / 200 métodos — e `Toolkit.getMEI()` devolve
   a string carregada em vez de serializar a árvore. Seção 7-bis. → tarefas **06-08 a 06-11**.

---

## 1. Compilação, testes e lints

### `dart analyze`

```
$ cd verovio_dart && dart analyze
10 issues found.
```

As 10 são warnings, nenhuma em `lib/`:

| Arquivo | Qtd | Natureza |
|---|---:|---|
| `tool/_scratch_debug.dart`, `_scratch_debug2/3/4.dart`, `_scratch_lig.dart`, `_scratch_onsets.dart` | 8 | imports/variáveis não usados — lixo de debug, documentado no `CLAUDE.md` |
| `test/mei_input_test.dart:10` | 1 | `unused_import` de `model/object.dart` |
| `test/toolkit_io_test.dart:114` | 1 | `unused_local_variable` `encoder` |

**Correção ao `CLAUDE.md`:** ele afirma que os scripts de scratch são "the only source of `dart analyze`
warnings". São 8 dos 10 — há 2 warnings em `test/`. A baseline correta para "sem novos avisos" é
**10 issues**.

### `dart test`

```
$ cd verovio_dart && dart test
00:15 +265: All tests passed!
```

**265 testes, 0 falhas, ~15 s.** 25 arquivos de teste em `test/`. O ruído
`Bravura font could not be loaded` / `Text font could not be initialized` no stderr é esperado
(suítes que não setam `Resources.defaultPath = 'assets/data'`), não é regressão.

### `dart run tool/validate_layout.dart`

```
$ cd verovio_dart && dart run tool/validate_layout.dart
Report written to tool/LAYOUT_VALIDATION.md
```

Resultado real, contado a partir da coluna `Timemap` do relatório gerado:

| Resultado | Arquivos |
|---|---:|
| `match` (bate com o C++) | **24** |
| `N/N differ` (diverge) | **2** |
| `skipped` (mensural/neume/ligature — sem timemap comparável) | 16 |
| `unavailable` (C++ não emitiu timemap) | 4 |
| **Total validado** | **46** |

Cabeçalho do relatório: `24/30 clean`. Os 2 divergentes:

```
lyric/lyric-001.mei      6/10 differ @q=4.50
section/section-001.mei  10/20 differ @q=25.00
```

**Correção ao META_PROMPT:** ele registra "18/30 timemaps batem". O número real hoje é **24/30**.
Todos os 46 arquivos passam nas asserções estruturais (ordem X, medidas únicas, larguras ≥ 0);
a seção "Check notes" do relatório diz `None. All structural assertions passed.`

### Binário C++ de referência

```
$ ./build/verovio --version
Verovio 6.2.0
```
Disponível e funcional (`build/verovio`, 10,6 MB, Release, `NO_HUMDRUM_SUPPORT=ON`).

---

## 2. Volume de código

```
$ find verovio_dart/lib -name '*.dart' | xargs wc -l | tail -1
80791 total
```

| Diretório | Arquivos | Linhas |
|---|---:|---:|
| `lib/src/model/atts/` | 25 | 26.712 |
| `lib/src/layout/` | 22 | 16.825 |
| `lib/src/model/` (raiz) | 21 | 15.342 |
| `lib/src/io/` | 6 | 14.359 |
| `lib/src/core/` | 16 | 3.729 |
| `lib/src/rendering/` | 5 | 2.302 |
| `lib/src/model/interfaces/` | 9 | 1.180 |
| `lib/src/drawing/` | 0 | 0 |
| `lib/src/editing/` | 0 | 0 |
| `lib/src/midi/` | 0 | 0 |
| `lib/src/resources/` | 0 | 0 |
| `lib/src/atts/` | 0 | 0 (diretório vazio remanescente do plano original) |

Volume C++ que falta portar, medido com `wc -l` em `origin/src/src/`:

| Bloco | Linhas |
|---|---:|
| Fase 4 — 19 `*functor.cpp` faltantes | **3.565** |
| Fase 5 — 12 `view*.cpp` + 3 device contexts | **13.425** |
| Fase 6 — midi/timemap/transpose/convert/reset/find/save/edit/facsimile/scoringup/editortoolkit | **15.300** |
| Fase 7 — `toolkit.cpp` + `options.cpp` | **4.616** |

---

## 3. Inventário de functors

```
$ grep -rhoP '^class \K\w+Functor' origin/src/include/vrv/*.h | sort -u | wc -l
135
$ grep -rhoP '^\s*(abstract\s+)?class \K\w+Functor' verovio_dart/lib/src/ --include='*.dart' | sort -u | wc -l
69
```

Dos 68 nomes sem contraparte homônima em Dart, **8 foram confirmados como portados de outra forma** e
**não devem virar tarefa**:

| Functor C++ | Onde está em Dart | Evidência |
|---|---|---|
| `ConvertToPageBasedFunctor` | `Doc.convertToPageBasedDoc` | `model/doc.dart:2142`, `:2162` |
| `ConvertMarkupArticFunctor` | método em `Doc` | `model/doc.dart:2278`, helper em `:2394` |
| `ConvertMarkupScoreDefFunctor` | método em `Doc` | `model/doc.dart:2315` |
| `ReplaceDrawingValuesInStaffDefFunctor` | método em `ScoreDef` | `model/scoredef.dart:410` |
| `SetStaffDefRedrawFlagsFunctor` | método em `ScoreDef` | `model/scoredef.dart:630`, `:657` |
| `GetAlignmentLeftRightFunctor` | `_GetAlignmentLeftRightFunctor` (privado) | `layout/horizontal_aligner.dart` |
| `ConstFunctor` | desvio documentado — não portado de propósito | `layout/functor.dart:18-20` |
| `DocConstFunctor` | idem | `layout/functor.dart:18-20` |

**Restam 60 functors genuinamente ausentes**, agrupados pelo header C++ onde vivem (esta tabela é a
entrada direta da decomposição em prompts):

| Header C++ | Linhas do `.cpp` | Functors faltantes |
|---|---:|---|
| `adjustaccidxfunctor.h` | 198 | `AdjustAccidXFunctor` |
| `adjustarticfunctor.h` | 177 | `AdjustArticFunctor`, `AdjustArticWithSlursFunctor` |
| `adjustbeamsfunctor.h` | 434 | `AdjustBeamsFunctor` |
| `adjustdotsfunctor.h` | 130 | `AdjustDotsFunctor` |
| `adjustharmgrpsspacingfunctor.h` | 222 | `AdjustHarmGrpsSpacingFunctor` |
| `adjustlayersfunctor.h` | 155 | `AdjustLayersFunctor` |
| `adjustneumexfunctor.h` | 102 | `AdjustNeumeXFunctor` |
| `adjustossiastaffdeffunctor.h` | 106 | `AdjustOssiaStaffDefFunctor` |
| `adjustsylspacingfunctor.h` | 206 | `AdjustSylSpacingFunctor` |
| `adjusttempofunctor.h` | 71 | `AdjustTempoFunctor` |
| `adjusttupletsxfunctor.h` | 107 | `AdjustTupletsXFunctor` |
| `adjusttupletsyfunctor.h` | 429 | `AdjustTupletsYFunctor`, `AdjustTupletNumOverlapFunctor`, `AdjustTupletWithSlursFunctor` |
| `adjustxoverflowfunctor.h` | 121 | `AdjustXOverflowFunctor` |
| `adjustxrelfortranscriptionfunctor.h` | 35 | `AdjustXRelForTranscriptionFunctor` |
| `adjustyrelfortranscriptionfunctor.h` | 35 | `AdjustYRelForTranscriptionFunctor` |
| `cachehorizontallayoutfunctor.h` | 52 | `CacheHorizontalLayoutFunctor` |
| `calcledgerlinesfunctor.h` | 191 | `CalcLedgerLinesFunctor` |
| `calcspanningbeamspansfunctor.h` | 67 | `CalcSpanningBeamSpansFunctor` |
| `castofffunctor.h` | 727 (parcialmente portado) | `CastOffToSelectionFunctor` |
| `convertfunctor.h` | 1465 | `ConvertMarkupAnalyticalFunctor`, `ConvertToCmnFunctor`, `ConvertToMensuralViewFunctor` |
| `editfunctor.h` | 147 | `ScoreContextFunctor`, `SectionContextFunctor` |
| `facsimilefunctor.h` | 108 | `SyncFromFacsimileFunctor`, `SyncToFacsimileFunctor` |
| `findfunctor.h` | 477 | 12 functors — ver nota abaixo |
| `findlayerelementsfunctor.h` | 280 | `FindSpannedLayerElementsFunctor`, `GetRelativeLayerElementFunctor`, `LayerElementsInTimeSpanFunctor`, `LayersInTimeSpanFunctor` |
| `midifunctor.h` | 1324 | `InitMIDIFunctor`, `GenerateMIDIFunctor`, `GenerateTimemapFunctor`, `GenerateFeaturesFunctor`, `InitTimemapTiesFunctor`, `InitTimemapAdjustNotesFunctor` |
| `miscfunctor.h` | 185 | `ApplyPPUFactorFunctor`, `ReorderByXPosFunctor` |
| `savefunctor.h` | 187 | `SaveFunctor` |
| `scoringupfunctor.h` | 734 | `ScoringUpFunctor` |
| `setscoredeffunctor.h` | 928 (parcialmente portado) | `ScoreDefOptimizeFunctor`, `ScoreDefSetOssiaFunctor` |
| `transposefunctor.h` | 425 | `TransposeFunctor`, `TransposeSelectedMdivFunctor`, `TransposeToSoundingPitchFunctor` |

**Nota sobre `findfunctor.h`.** Os 12 functors de busca (`FindByIDFunctor`, `FindByComparisonFunctor`,
`FindAllByComparisonFunctor`, `FindAllConstByComparisonFunctor`, `FindExtremeByComparisonFunctor`,
`FindAllBetweenFunctor`, `FindNextChildByComparisonFunctor`, `FindPreviousChildByComparisonFunctor`,
`AddToFlatListFunctor`, `FindAllReferringObjectsFunctor`, `FindAllReferencedObjectsFunctor`,
`FindElementInLayerStaffDefFunctor`) foram **em grande parte substituídos por travessia direta** em
`lib/src/model/object.dart`, com doc comments citando o C++:

| C++ | Dart | Linha |
|---|---|---|
| `FindDescendantByID` | `findDescendantByID` | `object.dart:838` |
| `FindDescendantByType` | `findDescendantByType` | `object.dart:853` |
| `FindAllDescendantsByType` | `findAllDescendantsByType` | `object.dart:861` |
| `FindDescendantByComparison` | `findDescendantByComparison` | `object.dart:954` |
| `FindDescendantExtremeByComparison` | `findDescendantExtremeByComparison` | `object.dart:970` |
| `FindAllDescendantsByComparison` | `findAllDescendantsMatching` | `object.dart:983` |
| `FillFlatList` | `fillFlatList` | `object.dart:996` |

**Sem contraparte alguma** (verificado por `grep` em `object.dart` e `comparison.dart`):
`FindAllDescendantsBetween`, `FindNextChild`, `FindPreviousChild`, `FindAllReferringObjects`,
`FindAllReferencedObjects`, `FindElementInLayerStaffDef`. São essas 6 lacunas que precisam de tarefa,
não os 12 functors. → tarefa **06-02**.

---

## 4. Aproximações e TODOs em `lib/`

```
$ grep -rn "Approximation:" verovio_dart/lib/src/ --include='*.dart' | wc -l
16
$ grep -rn "TODO\|FIXME" verovio_dart/lib/src/ --include='*.dart' | wc -l
24
```

### Os 16 `Approximation:` — todos morrem com o `View` real

| Arquivo:linha | O que aproxima | Implicação |
|---|---|---|
| `rendering/headless_extents.dart:26` | cabeçalho da biblioteca | — |
| `headless_extents.dart:236` | acorde não recebe bbox própria | bbox de `Chord` diverge |
| `headless_extents.dart:248` | ponto de aumento = círculo de meia unidade | `Dots` diverge |
| `headless_extents.dart:268` | clef = caixa de altura total do pentagrama, 2 unidades | `Clef` diverge |
| `headless_extents.dart:280` | armadura = caixa de altura total, 2 unidades | `KeySig` diverge |
| `headless_extents.dart:291` | articulação = caixa de 1 unidade | `Artic` diverge |
| `headless_extents.dart:306` | quadrado duplo centrado | largura errada |
| `headless_extents.dart:530` | usa o pentagrama do `tstamp` em vez do C++ | posicionador flutuante errado |
| `headless_extents.dart:558` | direção da ligadura derivada da haste da extremidade | `Tie` diverge |
| `headless_extents.dart:572` | bbox de bezier analítica expandida | `Slur` diverge |
| `headless_extents.dart:593` | extensão de texto estimada | todo texto diverge |
| `headless_extents.dart:658` | mede com Times a ~60% da fonte de música | todo texto diverge |
| `layout/floating_positioner.dart:445` | sobreposição por retângulo simples | agrupamento de flutuantes diverge |
| `layout/slur_positioning.dart:11` | cabeçalho | — |
| `layout/slur_positioning.dart:375` | reposicionamento de colisão perto da extremidade não feito | slur diverge |
| `layout/slur_positioning.dart:534` | retorna `false` (sem ajuste por direção melódica) | slur diverge |

→ todos morrem na tarefa **05-12**.

`headless_extents.dart` tem **825 linhas** e é usado em um único ponto:
`lib/src/model/doc.dart:497` (`final headlessExtents = HeadlessExtents(doc);`), importado em `doc.dart:122`.
Nenhum teste ou tool o importa diretamente. **A remoção é cirúrgica: um import e uma chamada.**

O C++ faz o equivalente instanciando um `BBoxDeviceContext` sobre um `View` e chamando
`View::DrawCurrentPage(&bBoxDC, false)`, em **quatro** pontos de `origin/src/src/page.cpp`:

| Linha | Contexto | Modo |
|---:|---|---|
| 240 | `Page::LayOut`, só se `m_svgBoundingBoxes` | `BBOX_BOTH` |
| 301 | `Page::LayOutTranscription` | `BBOX_HORIZONTAL_ONLY` |
| **410** | `Page::LayOutHorizontally` (com `view.SetSlurHandling(SlurHandling::Ignore)`) | `BBOX_HORIZONTAL_ONLY` |
| **532** | `Page::LayOutVertically` | `BBOX_BOTH` |

Os pontos 410 e 532 são os que `HeadlessExtents` substitui.

### Os 24 `TODO`/`FIXME`

`toolkit.dart:263-264` (render/MIDI), `misc_elements_gen.dart:740` (GetSymbolWidth/Height),
`custom_tuning.dart:242` (FIXME herdado do C++), `comparison.dart:359`
(`MeasureAlignerTypeComparison`, `MeasureOnsetOffsetComparison`), `basic_elements.dart:75` e `:1179`,
`system_page_elements.dart:275`, `doc.dart:179` e `:2043` (GenerateFooter/Header, GenerateMeasureNumbers),
`lay_out_vertically.dart:127`, `:147`, `:810`, `mei_input.dart:884` (ApplyPPUFactor) e `:2140`,
`align_horizontally.dart:187`, `:219`, `:669` (ossia), `vertical_aligner.dart:878`
(AdjustBracketGroupSpacing), `tunings.dart:403` e `:405`, `bbox_device_context.dart:414` (texto rotacionado),
`iomusxml.dart:4385` e `:5228`.

---

## 5. Registro de classes no `ObjectFactory`

```
$ cat lib/src/model/factory_registry_gen.dart lib/src/factory_registry.dart | grep -c "f.register("
133
$ ... | grep -oP "f\.register\('\K[^']+" | sort -u | wc -l
128
$ grep -rhoP 'ClassRegistrar<\w+>\s+s_factory\("\K[^"]+' origin/src/src/*.cpp | sort -u | wc -l
127
$ sed -n '/^enum ClassId/,/^}/p' lib/src/core/vrvdef.dart | grep -cP '^\s+\w+,'
190
```

133 chamadas para 128 nomes distintos → **há colisões**.

### Defeito 1 — quatro classes registradas com o nome `'dots'`

```
$ grep -n "f.register('dots'" lib/src/model/factory_registry_gen.dart
32:  f.register('dots', ClassId.dots, Dots.new);
33:  f.register('dots', ClassId.flag, Flag.new);
34:  f.register('dots', ClassId.tupletBracket, TupletBracket.new);
35:  f.register('dots', ClassId.tupletNum, TupletNum.new);
```

`ObjectFactory.create('dots')` devolve o que foi registrado por último (`TupletNum`). No C++,
`Dots`, `Flag`, `TupletBracket` e `TupletNum` **não têm `ClassRegistrar` nenhum** — são objetos de
desenho internos, não elementos MEI:

```
$ grep -rn "ClassRegistrar" origin/src/src/dots.cpp origin/src/src/flag.cpp
(sem resultado)
```

O correto é **não registrar nenhuma das quatro**.

### Defeito 2 — sete nomes divergentes do C++

```
$ comm -23 <nomes do C++> <nomes do Dart>
annotScore btrem f fb generic lv ossia phrase
$ comm -13 <nomes do C++> <nomes do Dart>
bTrem divLine dots liquescent oriscus quilisma strophicus text timestampAttr
```

| Classe | Nome no C++ | Nome no Dart | Onde |
|---|---|---|---|
| `AnnotScore` | `annotScore` (`annotscore.cpp:29`) | `annot` — **colide com `Annot` editorial** | `factory_registry_gen.dart:13` |
| `BTrem` | `btrem` (`btrem.cpp:32`) | `bTrem` | `factory_registry_gen.dart:21` |
| `F` | `f` (`f.cpp:27`) | ausente | — |
| `Fb` | `fb` (`fb.cpp:27`) | ausente | — |
| `Lv` | `lv` (`lv.cpp:26`) | ausente | — |
| `Ossia` | `ossia` (`ossia.cpp:32`) | ausente | — |
| `Phrase` | `phrase` (`phrase.cpp:25`) | ausente | — |

`GenericLayerElement` (`generic`) está comentado no C++ (`genericlayerelement.cpp:25`) — o Dart
acertou em não registrar. `DivLine`, `Liquescent`, `Oriscus`, `Quilisma`, `Strophicus`, `Text` e
`TimestampAttr` são registrados só no Dart; no C++ não têm `ClassRegistrar` (são construídos
diretamente pelos leitores). Impacto baixo hoje — `mei_input.dart` constrói esses elementos por
`if (currentName == …)` e não pelo factory (`mei_input.dart:2048`, `:2058`, `:2062`, `:2482`) —
mas o factory é a porta de entrada do `EditorToolkit` na Fase 6, onde os nomes passam a importar.
→ tarefa **04i**.

---

## 6. Geradores de código — round-trip

### `tool/gen_atts.dart` — **reproduz** (módulo formatação)

```
$ dart run tool/gen_atts.dart
Parsed 160 enums / Found string tables for 159 enums / Generated 287 att classes (520 members)
```

Diff bruto: os 24 arquivos diferem. Depois de `dart format` nos dois lados, **sobra 1 diferença
cosmética** (`atts_conversion.dart:2322`, chaves em `if` de uma linha). Ou seja: o gerador é fiel,
os arquivos versionados só passaram por `dart format` depois de gerados.

**Procedimento correto:** `dart run tool/gen_atts.dart && dart format lib/src/model/atts/`.

### `tool/gen_elements.py` — **NÃO reproduz** ⚠️

```
$ python3 tool/gen_elements.py
WARN GenericLayerElement: no GetClassName found
WARN GenericLayerElement: no ClassId mapping
WARN AlignmentReference: no GetClassName found
WARN HorizontalAligner: no GetClassName found
WARN HorizontalAligner: no ClassId mapping
```

Diff contra os arquivos versionados, **depois** de `dart format` nos dois lados:

| Arquivo | O que o gerador destrói |
|---|---|
| `control_elements_gen.dart` | overrides `isSupportedChild` de `AnchoredText` e `AnnotScore`; campos de drawing de `BeamSpan` |
| `layer_elements_gen.dart` | ~40 linhas de `import` (`fraction.dart`, `logging.dart`, ~30 constantes SMuFL de `smufl.dart`) e o código que as usa |
| `misc_elements_gen.dart` | `import`s de `zone.dart`, `dart:math`, `attdef.dart`, `mei_enums.dart`; o `export` que substitui o stub de `AlignmentReference` pelo port de `layout/horizontal_aligner.dart`; campos de drawing de `Div` |
| `factory_registry_gen.dart` | ao contrário: o gerador **acrescenta** `f.register('f', ClassId.f, F.new);`, ausente no arquivo versionado |

**Conclusão:** os arquivos `*_gen.dart` foram editados à mão depois de gerados, contrariando o banner
`GENERATED FILE` e o `CLAUDE.md`. Rodar `python3 tool/gen_elements.py` hoje **apaga trabalho**.

Isto vira duas obrigações para a série de prompts:

1. **Nenhum prompt pode mandar rodar `tool/gen_elements.py`** sem antes reconciliar o gerador.
2. Existe uma tarefa dedicada (`04i`) para tornar o gerador idempotente ou marcar os arquivos como
   não-mais-gerados.

---

## 7. Corpus, goldens e harnesses

```
$ find verovio_dart/test/corpus -name '*.mei' | wc -l
623
$ find verovio_dart/test/golden -name '*.svg' | wc -l
623
$ find verovio_dart/test/corpus \( -name '*.musicxml' -o -name '*.xml' \) | wc -l
5
$ find verovio_dart/test/corpus -name '*.abc' | wc -l
0
```

623 arquivos MEI em 69 categorias; 623 SVGs de referência gerados por `tool/golden.sh` a partir de
`build/verovio` **sem nenhuma opção além de `-r assets/data`** (padrões do C++). **Nada compara contra
eles ainda** — nenhum arquivo em `test/` menciona `golden/cpp`.

Maiores categorias: `beam` 61, `ligature` 50, `gracenote` 27, `slur` 25, `mensural` 25,
`cross-staff` 24, `tuplet` 22, `rest` 21, `artic` 19, `stem` 16, `score` 16, `lyric` 16, `layer` 15,
`accid` 14.

Corpus MusicXML: **5 arquivos**, todos em `test/corpus/midi/`. `tool/validate_io.dart` compara
histogramas de elementos e exige o MEI convertido pelo C++ passado como argumento — não varre o
corpus sozinho.

**Não há corpus ABC** em `test/corpus/`; `ioabc_test.dart` usa strings embutidas.

### Bug em `tool/validate_layout.dart`

A tabela "System metrics" do relatório gerado imprime:

```
| accid/accid-001.mei | 3 | 1 m / w=2778 / 2 st / y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel] |
```

`${obj.campo}` sem chaves dentro de uma string interpolada. A coluna yRel é inútil hoje.

### Arquivos não-UTF-8

`test/corpus/dir/dir-011.mei` e `dir-012.mei` são deliberadamente não-UTF-8 e estão na skip-list dos
testes de layout. Qualquer harness novo que varra os 623 precisa da mesma skip-list.

---

## 7-bis. ⚠️ `MEIOutput` não existe — `getMEI()` é um eco do input

```
$ grep -rn "class MeiOutput\|MeiOutput" verovio_dart/lib/src/ --include='*.dart'
(sem resultado)
$ sed -n '69,74p' verovio_dart/lib/src/toolkit.dart
  /// Returns the currently loaded MEI document as a string.
  String getMEI() {
    if (!_loaded) throw StateError('No data loaded');
    return _mei;
  }
```

`Toolkit.getMEI()` devolve **a string que foi carregada**, não uma serialização da árvore de objetos.
Consequências:

- Carregar MusicXML ou ABC e pedir `getMEI()` devolve o MusicXML/ABC original, não o MEI convertido.
- Nada do que os functors fazem (expansão, conversão de markup, cast-off) aparece na saída.
- `tool/validate_io.dart` compara **histogramas de elementos da árvore em memória**, não a saída MEI —
  por isso o buraco passou despercebido.

Volume a portar, medido em `origin/src/src/iomei.cpp` (9.176 linhas no total):

```
$ python3 (soma as linhas dos blocos de função por classe)
linhas em blocos MEIOutput::   3416
linhas em blocos MEIInput::    5586
$ grep -oP '\bMEIOutput::\K\w+' origin/src/src/iomei.cpp | sort -u | wc -l
200
```

**3.416 linhas / 200 métodos completamente ausentes.** Isto reabre a Fase 3, que o `PLANO.md` dava
como fechada: o item "IOMEI (~9k linhas) — parser nativo" cobriu só a metade de leitura.
Tarefas **06-08 a 06-11**.

---

## 8. Fase 1 — lacunas remanescentes

### `Resources`

Métodos do C++ (`origin/src/include/vrv/resources.h`) sem contraparte em
`lib/src/rendering/resources.dart`:

`AddCustom`, `GetCustomFontname`, `GetSmuflGlyphForUnicodeChar`, `LoadAll`, `UseLiberationTextFont`,
`IsCurrentFontFallback`, `Ok`, `GetPath`/`SetPath`, `SetCSSFont`. → tarefa **05-01**.

### `DeviceContext` / `BBoxDeviceContext`

`lib/src/rendering/bbox_device_context.dart` (531 linhas) cobre **38 dos 40** métodos de
`origin/src/src/bboxdevicecontext.cpp`. Faltam `GetPenWidthOverlap` e `SetUserScale`
(este último existe na base `DeviceContext`, mas o C++ o sobrescreve em `BBoxDeviceContext`).
`bbox_device_context.dart:414` tem um `TODO` para texto rotacionado. → tarefa **05-05**.

`lib/src/core/devicecontextbase.dart` (297 linhas) porta `Pen`, `Brush`, `FontInfo`, `BezierCurve`,
`TextExtend`; o C++ tem também `Point` (que aqui vive em `core/point.dart`) — cobertura completa.

`lib/src/rendering/device_context.dart` (411 linhas) declara toda a interface abstrata de desenho.
`SvgDeviceContext` **não existe** (0 linhas contra 1.417 no C++).

---

## 9. Fase 7 — estado real

`lib/src/toolkit.dart` tem **265 linhas** e expõe apenas:
`ready`, `getMEI()`, `setInputFrom()`, `loadData()`, `loadFile()`, `loadZipData()`, `loadZipFile()`,
`isZipFile()`, `loadDataString()`. Os `TODO` em `:263-264` marcam render e MIDI.

`lib/src/core/options_shell.dart` tem **566 linhas** e é explicitamente um esqueleto
("Minimal shell of `options.h/cpp` … The full set of ~100 options and their parsing are ported with
the public Toolkit API (Phase 7)"). Define `Option<T>`, `Breaks`, `MensuralResp` e ~85 campos.

O C++ registra **210 opções** em 10 grupos:

```
$ python3 (conta Register() por SetLabel() em origin/src/src/options.cpp)
Base short options                            0
Input and page configuration options          54
General layout options                        82
Loading selectors and processing              14
Element margins                               45
Midi options                                   3
Mensural notation options                      6
Neumatic notation options                      4
Method JSON options for the command-line       1
Deprecated options                             1
TOTAL 210
```

**Correção ao `PLANO.md` e ao META_PROMPT:** não são "~100 opções", são **210**.
(As 13 "Base short options" de `m_baseOptions` são declaradas em `options.h` mas registradas por outro
caminho; somando, `options.h` declara 221 campos `Option*`.)

---

## 10. Fase 5 — superfície a portar, funções nominais

Inventário obtido com `grep -oP '^\w[\w:*& ]*View::\K\w+' origin/src/src/view*.cpp`:

| Arquivo | Linhas | Funções `View::` |
|---|---:|---|
| `view.cpp` | 342 | `SetDoc`, `SetPage`, `ToDeviceContextX/Y`, `ToLogicalX/Y`, `ToDeviceContext`, `ToLogical`, `StartOffset`, `EndOffset`, `SetOffsetStaffSize`, `CalcOffset*` (9 variantes) |
| `view_graph.cpp` | 430 | `DrawVerticalLine`, `DrawHorizontalLine`, `DrawObliqueLine`, `DrawVerticalSegmentedLine`, `DrawHorizontalSegmentedLine`, `DrawNotFilledEllipse`, `DrawNotFilledRectangle`, `DrawFilledRectangle`, `DrawFilledRoundedRectangle`, `DrawObliquePolygon`, `DrawDiamond`, `DrawDot`, `DrawVerticalDots`, `DrawSquareBracket`, `DrawEnclosingBrackets`, `DrawSmuflCode`, `DrawSmuflCodeWithCustomFont`, `DrawSmuflLine`, `DrawSmuflString`, `DrawThickBezierCurve`, `DrawSymbolDef`, `IntToTupletFigures`, `IntToTimeSigFigures`, `IntToSmuflFigures` |
| `view_page.cpp` | 2078 | `DrawCurrentPage`, `GetPPUFactor`, `SetScoreDefDrawingWidth`, `DrawPageElement`, `DrawSystem`, `DrawSystemList`, `DrawScoreDef`, `DrawStaffGrp`, `DrawStaffDefLabels`, `DrawGrpSym`, `DrawLayerDefLabels`, `DrawLabels`, `DrawBracket`, `DrawBracketSq`, `DrawBrace`, `DrawBarLines`, `DrawBarLine`, `DrawBarLineDots`, `DrawMeasure`, `DrawMeterSigGrp`, `DrawMNum`, `DrawOssia`, `DrawStaff`, `DrawStaffLines`, `DrawLedgerLines`, `DrawStaffDef`, `DrawStaffDefCautionary`, `CalculatePitchCode`, `DrawLayer`, `DrawLayerList`, `DrawSystemDivider`, `Draw*Children` (7), `Draw*EditorialElement` (7), `DrawAnnot` |
| `view_element.cpp` | 2212 | `DrawLayerElement`, `DrawAccid`, `DrawArtic`, `DrawBarLine`, `DrawBeatRpt`, `DrawBTrem`, `DrawChord`, `DrawChordCluster`, `DrawClef`, `DrawClefEnclosing`, `DrawCustos`, `DrawDot`, `DrawDots`, `DrawDurationElement`, `DrawFlag`, `DrawGenericLayerElement`, `DrawGraceGrp`, `DrawHalfmRpt`, `DrawKeySig`, `DrawMeterSig`, `DrawKeySigCancellation`, `DrawKeyAccid`, `DrawMRest`, `DrawMRpt`, `DrawMRpt2`, `DrawMSpace`, `DrawMultiRest`, `DrawMultiRpt`, `DrawNote`, `DrawRest`, `DrawSpace`, `DrawStem`, `DrawStemMod`, `DrawSyl`, `DrawVerse`, `DrawAcciaccaturaSlash`, `DrawDotsPart`, `DrawMRptPart` |
| `view_control.cpp` | 3306 | `DrawControlElement`, `DrawTimeSpanningElement`, `DrawAnnotScore`, `DrawBracketSpan`, `DrawHairpin`, `DrawOctave`, `DrawPitchInflection`, `DrawTie`, `DrawPedalLine`, `DrawTrillExtension`, `DrawControlElementConnector`, `DrawFConnector`, `DrawSylConnector`, `DrawSylConnectorLines`, `DrawArpeg`, `DrawArpegEnclosing`, `DrawBreath`, `DrawCaesura`, `DrawControlElementText`, `DrawDynam`, `DrawDynamSymbolOnly`, `DrawFb`, `DrawFermata`, `DrawFing`, `DrawGliss`, `DrawHarm`, `DrawMordent`, `DrawPedal`, `DrawReh`, `DrawRepeatMark`, `DrawTempo`, `DrawTrill`, `DrawTurn`, `DrawSystemElement`, `DrawEnding`, `DrawTextEnclosure` |
| `view_text.cpp` | 701 | `DrawF`, `DrawTextString`, `DrawDirString`, `DrawDynamString`, `DrawHarmString`, `DrawTextElement`, `DrawLyricString`, `DrawLb`, `DrawNum`, `DrawFig`, `DrawRend`, `DrawText`, `DrawGraphic`, `DrawSvg`, `DrawSymbol`, `DrawRunningElements`, `DrawTextLayoutElement`, `DrawDiv` |
| `view_beam.cpp` | 473 | `DrawBeam`, `DrawFTrem`, `DrawFTremSegment`, `DrawBeamSegment`, `DrawBeamSpan` |
| `view_tuplet.cpp` | 211 | `NestedTuplets`, `DrawTuplet`, `DrawTupletBracket`, `DrawTupletNum` |
| `view_slur.cpp` | 97 | `DrawSlur`, `CalcInitialSlur` |
| `view_mensural.cpp` | 751 | `DrawMensuralNote`, `DrawMensur`, `DrawMensuralStem`, `DrawMaximaToBrevis`, `DrawLigature`, `DrawLigatureNote`, `DrawDotInLigature`, `DrawPlica`, `DrawProportFigures`, `DrawProport`, `CalcBrevisPoints`, `CalcObliquePoints`, `GetMensuralStemDir` |
| `view_neume.cpp` | 322 | `DrawSyllable`, `DrawLiquescent`, `DrawNc`, `DrawNeume`, `DrawNcAsNotehead`, `DrawDivLine`, `DrawEpisema`, `DrawOriscus`, `DrawQuilisma`, `DrawStrophicus`, `DrawNcGlyphs` |
| `view_tab.cpp` | 295 | `DrawTabClef`, `DrawTabGrp`, `DrawTabNote`, `DrawTabDurSym` |
| `svgdevicecontext.cpp` | 1417 | 57 métodos `SvgDeviceContext::` (Start/EndGraphic, StartPage/EndPage, todos os `Draw*`, `AppendIdAndClass`, `GetStringSVG`, `DrawSvgBoundingBox`…) |

Membros de `View` (de `origin/src/include/vrv/view.h`): `m_doc`, `m_options`, `m_currentPage`,
`m_currentColor`, `m_slurHandling`, `m_drawingScoreDef`, `m_currentOffsets`, mais a struct `Offset`
(`m_ho`, `m_vo`, `m_startho`, `m_startvo`, `m_endho`, `m_endvo`, `m_object`, `m_staffSize`).

---

## 11. Fase 6 — correção de volume

O META_PROMPT estima "editortoolkit*.cpp ~5.5k". Medido:

```
$ wc -l origin/src/src/editortoolkit*.cpp
    23 editortoolkit_cmn.cpp
   110 editortoolkit.cpp
  4498 editortoolkit_neume.cpp
   902 editortoolkit_shared.cpp
```

**`editortoolkit_cmn.cpp` tem 23 linhas** — em 6.2.0 é só construtor e destrutor; **toda** a
funcionalidade CMN vive em `EditorToolkitShared` (902 linhas). O peso real está no Neume (4.498).
Headers: `editortoolkit.h` 63, `editortoolkit_shared.h` 164, `editortoolkit_cmn.h` 47,
`editortoolkit_neume.h` 266, `editortoolkit_mensural.h` 35 (sem `.cpp`).

Demais volumes da Fase 6: `midifunctor.cpp` 1324, `timemap.cpp` 110, `featureextractor.cpp` 173,
`transposition.cpp` 2252, `transposefunctor.cpp` 425, `expansion.cpp` 65, `editfunctor.cpp` 147,
`findfunctor.cpp` 477, `savefunctor.cpp` 187, `resetfunctor.cpp` 907, `convertfunctor.cpp` 1465,
`facsimile.cpp` 108, `miscfunctor.cpp` 185, `scoringupfunctor.cpp` 734,
`findlayerelementsfunctor.cpp` 280, `setscoredeffunctor.cpp` 928.

---

## 12. Sequência de functors do C++ — referência para a Fase 4

Extraída de `origin/src/src/page.cpp`. É a espinha do que a Fase 4 tem de reproduzir; os que
**faltam em Dart** estão em **negrito**.

**`Page::LayOutHorizontally()` (linha 396)** — precedida do `BBoxDeviceContext` horizontal (linha 410):

**AdjustOssiaStaffDef** → **AdjustArtic** → **AdjustLayers** → **AdjustDots** → **AdjustNeumeX** →
**AdjustLayers** (segunda passada, com pontos) → **AdjustAccidX** → AdjustXPos → AdjustGraceXPos →
AdjustClefChanges → InitProcessingLists → **AdjustHarmGrpsSpacing** → AdjustArpeg → **AdjustTempo** →
**AdjustTupletsX** → **AdjustXOverflow** → AlignMeasures → **CacheHorizontalLayout**

**`Page::LayOutVertically()` (linha 509)** — `BBoxDeviceContext` completo na linha 532:

ResetVerticalAlignment → **CalcLedgerLines** → AlignVertically → **AdjustArticWithSlurs** →
**AdjustBeams** → **AdjustTupletsY** → AdjustSlurs → **AdjustTupletWithSlurs** → CalcBBoxOverflows →
AdjustFloatingPositioners → AdjustStaffOverlap → AdjustYPos → AdjustFloatingPositionersBetween →
AdjustCrossStaffYPos → AlignSystems

**`Page::JustifyHorizontally()` (610)**: JustifyX
**`Page::JustifyVertically()` (635)**: JustifyY → JustifyYAdjustCrossStaff
**`Page::LayOutPitchPos()` (689)**: CalcAlignmentPitchPos → CalcStem → **CalcLedgerLines**

**`Page::LayOut()` (221)**: `LayOutHorizontally` → `JustifyHorizontally` → `LayOutVertically` →
`JustifyVertically`, e só depois o `BBoxDeviceContext` opcional de `m_svgBoundingBoxes`.

O Dart documenta em `doc.dart:296-299`, `:342-344`, `:461-464`, `:473` e `:505` exatamente quais
desses functors estão pulados — as anotações batem com esta medição.

---

## 13. Tabela final — fase → % pronto → evidência → o que falta

| Fase | % | Evidência (comando/arquivo) | O que falta |
|---|---:|---|---|
| **0 — Infra** | 100% | `build/verovio --version` = 6.2.0; `assets/data/` 12 MB com Bravura/Gootville/Leipzig/Leland/Petaluma; `tool/golden.sh` produz 623 SVGs | nada |
| **1 — Fundações** | 95% | `core/` 3.729 linhas; `devicecontextbase.dart` 297 linhas cobre Pen/Brush/FontInfo/BezierCurve/TextExtend; `bbox_device_context.dart` 38/40 métodos | `Resources`: `AddCustom`, `GetCustomFontname`, `GetSmuflGlyphForUnicodeChar`, `LoadAll`, `UseLiberationTextFont`, `IsCurrentFontFallback`, `Ok`, `Get/SetPath`, `SetCSSFont`; `BBoxDeviceContext.GetPenWidthOverlap`/`SetUserScale`; `bbox_device_context.dart:414` texto rotacionado |
| **2 — Modelo MEI** | 97% | `model/` 15.342 + `atts/` 26.712 + `interfaces/` 1.180 linhas; 190 `ClassId`; 133 registros no factory; 265 testes verdes | 4 registros com nome `'dots'`; 7 nomes divergentes do C++; `Object`: `FindAllDescendantsBetween`, `FindNextChild`, `FindPreviousChild`, `FindAllReferringObjects`, `FindAllReferencedObjects`, `FindElementInLayerStaffDef`; `MeasureAlignerTypeComparison`/`MeasureOnsetOffsetComparison` (`comparison.dart:359`) |
| **3 — IO (leitura)** | 95% | `io/` 14.359 linhas (`mei_input` 5.3k, `iomusxml` 6.5k, `ioabc` 2.1k); `validate_io.dart` 0 divergências nos 5 MusicXML | corpus MusicXML de 5 arquivos e nenhum ABC; 2 `TODO` em `iomusxml.dart` (`:4385` tabGrp+verse, `:5228` beam) |
| **3 — IO (escrita)** | **0%** | `grep MeiOutput lib/` sem resultado; `toolkit.dart:70` devolve `_mei` cru | **`MEIOutput` inteiro: 3.416 linhas / 200 métodos de `origin/src/src/iomei.cpp`** (§7-bis) |
| **4 — Layout** | **55%** | `layout/` 16.825 linhas, 69 functors Dart vs 135 C++; `LAYOUT_VALIDATION.md` 46 arquivos, 24/30 timemaps | **60 functors** (seção 3); 16 `Approximation:`; `headless_extents.dart` (825 linhas) tem de morrer; 2 timemaps divergentes |
| **5 — View/SVG** | **0%** | `lib/src/drawing/` vazio; `SvgDeviceContext` inexistente; nenhum teste lê `test/golden/cpp` | 13.425 linhas de C++: `view*.cpp` (12 arquivos) + `svgdevicecontext.cpp`; harness de comparação de SVG |
| **6 — Features** | **0%** | `lib/src/midi/`, `lib/src/editing/` vazios | 15.300 linhas: MIDI/timemap/features, transposição, convert, reset, save, find, edit, facsimile, scoringup, EditorToolkit (Shared 902 + Neume 4498) |
| **7 — API** | **5%** | `toolkit.dart` 265 linhas (load-only); `options_shell.dart` 566 linhas de esqueleto | 210 opções em 10 grupos; render/getSVG/getMIDI/timemap/editor; `DrawingDeviceContext` para Canvas; docs/exemplos/benchmark |

---

## 14. Itens que a série de prompts precisa endereçar e que não são "portar C++"

1. `tool/gen_elements.py` não é idempotente (seção 6) — **bloqueante para qualquer tarefa que precise
   regerar elementos**.
2. Registros errados no `ObjectFactory` (seção 5) — bloqueante para o `EditorToolkit` da Fase 6.
3. Bug de interpolação em `tool/validate_layout.dart` (seção 7).
4. 2 warnings em `test/` (seção 1) — a baseline de `dart analyze` é 10, não 8.
5. Não existe harness de comparação de SVG; os 623 goldens estão parados desde que foram gerados.
   → tarefa **05-00**.
6. `lib/src/atts/` é um diretório vazio remanescente do plano original (os atts vivem em
   `lib/src/model/atts/`).
7. `Toolkit.getMEI()` mente: devolve o input carregado, não a árvore serializada (seção 7-bis).
