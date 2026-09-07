# Desvios documentados (Deviation) com efeito no SVG — backlog do loop de fidelidade

Levantamento exaustivo dos 226 blocos `Deviation`/`Deviations from the C++`
em `verovio_dart/lib/`, filtrados para **(A) comportamento real divergente
com efeito no SVG/layout**. Adaptações benignas de linguagem (ponteiros,
UTF-16, asserts, import cycles) e fora-de-escopo por decisão
(Humdrum, PAE, tablatura, facsimile, MEI-output, selection/focus, web-stub)
foram excluídos — ver metodologia no fim.

- Medido em: 2026-09-07. Baseline do placar nesse dia: `S=24, N=9207,
  X=616/621, Y=470/621` (`tool/SVG_VALIDATION.md:3-6`).
- Números de categoria/ranking citados são desse baseline
  (`tool/SVG_VALIDATION.md`, `tool/DELTA_CLUSTERS.md`).
- Convenção: cada item traz `arquivo:linha` (linha da nota `Deviation`,
  não necessariamente do código a portar), a referência C++ citada, o
  sintoma no corpus e o impacto estimado.

## Ordem sugerida (rendimento)

1. verse-filter sem `@n` (lyric, §1) — 295 divs, causa única e isolada.
2. arpeg `drawingXRel` (§2) — 691 divs, 7/7 arquivos divergentes.
3. beam misto: `CalcMixedBeamPosition`/`CenterY` + retry (§3) —
   cross-staff 1402 divs + beamspan 410 divs.
4. `GetLayerPlace` (§4) — mordent 80 + trill 62 + turn 2.
5. tie-endpoints / `HasAdjacentNotes` (§5) — tie 457 divs.
6. Restante médio/baixo (§§6-8) na ordem das seções.

## 1. Alto rendimento

### 1.1 `adjust_harm_tempo_syl.dart:37` — `Filters` nunca casa `<verse>` sem `@n`
`Page.adjustSylSpacingByVerse` monta filtros `(staff,layer,verse)`; a verse
tree registra `@n` ausente como `0`, mas `AttNIntegerComparison` compara
contra o atributo cru, onde ausente lê `null` — nunca `0`. Resultado:
`AdjustSylSpacingFunctor` nunca visita um `Verse` real em produção.
Evidência: `lyric-001.mei` tem 9× `<verse>` sem `n` (só `lyric-002/003/004/005`
usam `n="1..4"`). Placar: lyric 295 divs, 2/16 arquivos.
Fix: normalizar ausente→0 na chave ou tornar a comparação nullable-aware.
Checagem: `compare_svg test/corpus/lyric` antes/depois.

### 1.2 `control_elements_gen.dart:302` + `adjust_arpeg.dart:172` — arpeg `drawingXRel` sempre 0
`AdjustArpegFunctor` só escreve o shift horizontal no `FloatingPositioner`,
nunca em `Arpeg.drawingXRel` — ao contrário de `Arpeg::SetDrawingXRel`
(arpeg.cpp:86), que atualiza ambos. `Arpeg.cacheXRel` (port fiel) nunca sai
de 0 no pipeline de produção. Placar: arpeg 691 divs, 7/7 divergentes, 0
limpos. Fix: escrever `drawingXRel` no functor (verificar ordem vs.
`CacheXRel`). Checagem: `compare_svg test/corpus/arpeg`.

### 1.3 `beam_segment.dart:39,64` — motor de beam misto é stub
`CalcMixedBeamPosition`/`CalcMixedBeamCenterY` (beam.cpp:1088-1234) seguem
stubs com fórmula fixa; o retry de `NeedToResetPosition`
(`CalcBeamInit`/`CalcBeamStemLength`/`CalcBeamPosition` de novo,
beam.cpp:131-135) não está religado em `calcBeam` (`CalcBeamInit`
equivalente segue inlinado, sem método re-chamável). Placar: cross-staff
1402 divs (9 estruturais), beamspan 410 divs. É o maior bloco, portar por
partes com fixture DEEP (`RequestStaffSpace`/`MinStemCoord`, patch 05-45
já existe). Relacionado (mesmo arquivo): `beam_segment.dart:934,999`
(`GetFloatingBeamCount` cross-staff fTrem como `(0,0)`, beam.cpp:214-220)
e `beam_segment.dart:809` (`beamMixedPreserve`/`beamMixedStemMin`
hardcoded `false`/`3.5` — iguais aos defaults C++; só vira problema com
corpus que sete essas opções).

### 1.4 `adjust_x_pos.dart:8` — sem render pass, nesting por overlap inativo
Sem o render pass que preenche bounding boxes, elementos sem BB caem para
a posição do alignment (igual ao C++ para BB vazia) e o nesting baseado em
overlap fica inativo até a fase de resources. Efeito em cascata na largura
de compasso — sintoma no topo do ranking (`staff/path @d` #2, 4532 divs).
Portar = aproximar a ordem/fase do C++ (`Page::LayOutHorizontally`), não
um valor isolado; medir por família antes/depois.

### 1.5 `cast_off.dart:18,150` — overflow de desenho zerado, ramo pending inativo
`Measure::GetDrawingOverflow` requer BBs renderizadas; é 0 até a fase de
render, então o ramo "pending overflow" nunca dispara (e o `GetCachedXRel`
gated nele tampouco); o cache horizontal não é armazenado (usa valores
correntes + overflow 0 no `visitMeasure`). Afeta quebra de sistema/medida.
Mesma natureza do 1.4: mudança de fase, medir por família.

## 2. Médio rendimento

### 2.1 `floating_positioner.dart:248` — `GetLayerPlace` sem refinamento
`mordent/ornam/trill/turn/repeatMark` usam `@place` codificado ou `above`,
sem o refinamento `GetLayerPlace` por stem-direction da camada. Corpus
mordent sem `@place` (`mordent-001/002/003` — só `mordent-001` tem um
`place="below"` em 4). Placar: mordent 80, trill 62, turn 2.
(Relacionado e já pago: `intersectsBeamGeometry` em `floating_positioner.dart`
porta `Intersects(Beam)` — ver diario 2026-09-07; o fallback
`intersectsRectangle` só resta para beam sem coords.)

### 2.2 `bbox_overflows.dart:129` — exceções cross-staff adiadas
`GetOverflowStaffAlignments` leva só alignment plain + redirect de chord
cross-staff; as exceções beam/stem (`m_crossStaffContent`,
`GetAncestorBeam`, layerelement.cpp:334-350) chegam "com a fase beam-segment".
Afeta cross-staff/beamspan (mesmo cluster do §3).

### 2.3 Tie: `adjust_x_pos.dart:137` + `control_elements_gen.dart:2428`
`m_measureTieEndpoints` não portado (falta geometria de tie) e
`_hasAdjacentNotesInStaff` é staff-scoped sem `CalcNoteLocations`
multi-staff (chord.cpp:411) — erra `tie.cpp:265
CalculateAdjacentChordXOffset` em acorde split cross-staff. Placar: tie
rank #20, 457 divs. (`@bulge` em `tie-006` é outro mecanismo — §8.)

### 2.4 `system_page_elements.dart:310` — `HasMixedDrawingStemDir` por varredura plana
Troca `FindAllBetweenFunctor`/`FindAllDescendantsBetween` (`System::Process`,
system.cpp:232/250/257) por scan plano de descendentes filtrado por `index`
de compassos. Pode divergir em direção de stem/beamSpan entre compassos.
Medir em beamspan/cross-staff.

### 2.5 `adjust_arpeg.dart:8,98,121` — ramo gracenote + check de clave
Ramo `ALIGNMENT_GRACENOTE` reduzido/pulado (faltam grace widths);
check vertical de clave pulado (`xRel` aplicado direto). `arpeg-006.mei`
contém grace notes — bom veículo isolado após o 1.2.

### 2.6 `adjust_harm_tempo_syl.dart:44` — harms `@tstamp` + tempo em upbeat
Harms `@tstamp` com delta constante por measure + tempo em upbeat
misresolvido (código alignment/tstamp anterior a este functor).
Placar: harm 200 divs concentrados em `harm-002` (só 1/5 diverge).
Veículo: `harm-002`.

### 2.7 `bounding_box.dart:246,282` — overlaps horizontais sem recortes SMuFL
`HorizontalRight/LeftOverlap` usam retângulo único, sem os recortes de
glifo NW/NE/SW/SE (`GetRectangles`, fase resources). Superestima overlap →
justificação/colisão X. (`:312,:329` verticais sem chamadores em 6.2.0 —
baixo, não portar por conta própria.)

### 2.8 `drawing_interfaces.dart:325` — `initCoords` com palpite avidamente
`m_closestNote`/`m_stem` inicializados por palpite em vez de null até
`SetClosestNoteOrTabDurSym`/`SetDrawingStemDir`
(drawinginterface.cpp:295, beam.cpp). Enviesa `IsHorizontal` na 1ª passada
(slope/polígono de beam). Investigar com fixture de `IsHorizontal` antes
de mexer — o compartilhamento de instâncias entre owned/refs pode estar
mascarando.

### 2.9 `layer_elements_gen.dart:748` — owned vs refs sem `CalcBeam`
`getBeamPartDuration` itera `beamElementCoordRefs` para busca e fallbacks;
o C++ separa owned (`m_beamElementCoords`) de refs. Sem `CalcBeam` não há
distinção observável — aceitar como permanente ou reavaliar após o §3.

## 3. Baixo rendimento / ramo raro

- `adjust_slurs.dart:7`, `slur_positioning.dart:11` — `AdjustSlurFromBulge`
  (`@bulge`) adiado. No corpus só `tie/tie-006.mei` tem `bulge` (3 ties,
  nenhum slur) — sem efeito mensurável hoje; portar quando tie-006 for alvo.
- `adjust_arpeg.dart:207` — bbox real de barline trocada por caixa de 1
  unidade em `_right/_leftBarLineWidth`. Baixo.
- `calc_functors.dart:1727`, `control_elements_gen.dart:2179` —
  `m_staccatoCenter` ausente (lê false; artics mantêm shift de stem-side).
  Baixo.
- `adjust_beams.dart:609,734`, `beam_segment.dart:809,888` —
  `beamMixedStemMin=3.5` hardcoded (= default C++), `beamFrenchStyle` stub
  (default false, nunca dispara). Baixo salvo corpus com essas opções.
- `adjust_harm_tempo_syl.dart:26` — `CalcHyphenLength`/elision
  `GetGlyphAdvX` aproximados por unit. Não exercitado por
  `lyric-001/004`; checar `lyric-014/015` antes de portar.
- `view_mensural.dart:31` — `DrawBentParallelogramFilled` curvo cai para
  `drawObliquePolygon` reto. Só `ligatureOblique=curved` (ligature 5 divs).
- `calc_ledger_lines.dart:238`, `mensural_neume.dart:14,459` — raio/glyph
  mensural aproximado (`GetMensuralNoteheadGlyph`, `@glyph.name`,
  `@head.shape/fill` ignorados). Baixo.
- `lay_out_vertically.dart:21,118,1331`, `preparedata_functor.dart:11`,
  `calc_functors.dart:12,500,559,835`, `align_horizontally.dart:12,14,754,839`,
  `adjust_tuplets.dart:21,786`, `adjust_artic.dart:5`,
  `adjust_accid_x.dart:15`, `cache_horizontal_layout.dart:17`,
  `basic_elements.dart:2027`, `layer_elements_gen.dart:680,787` —
  fase/ordem/headless documentados; tratar somente via pinpoint com fixture,
  nunca por palpite (precedente: `visitBeam` no-op, diario 2026-09-07).

## 4. Não portar (divergiriam do C++)

- `view_graph.dart:282` — `DrawSmuflCodeWithCustomFont` portada como código
  vivo embora comentada no C++ (view_graph.cpp:259-277). Só dispara com
  custom font carregada — troca que o C++ jamais faria. Manter como está.
- `rendering/resources.dart:309` — `getCustomFontname` tenta varredura
  emscripten-first. Só afeta zips cujo nome difere do XML interno.
  C++ desktop rejeitaria; manter.

## 5. Higiene (só comentário, sem código)

- `layer_elements_gen.dart:343` diz que `Slur::AddPositionerToArticulations`
  "não portado, listas sempre vazias" — stale: `slur_positioning.dart:713`
  porta (`addPositionerToArticulationsFor`) e `view_slur.dart:79` conecta.
  Atualizar o comentário quando tocar no arquivo.

## Metodologia

1. `rg -n "Deviation" verovio_dart/lib` → 226 ocorrências (lista bruta
   salva em `/tmp/deviations.txt` na sessão de 2026-09-07, descartada).
2. Dois subagentes em paralelo triaram `layout/` e
   `rendering/+model/+core/`, lendo ±30 linhas por ocorrência e
   classificando em (A) divergência real / (B) adaptação de linguagem /
   (C) fora de escopo.
3. Cruzamento com o placar: `tool/SVG_VALIDATION.md` (por categoria) e
   `tool/DELTA_CLUSTERS.md` (ranking por alcance) + checagens pontuais no
   corpus (`verse` sem `n`, `bulge`, grace em arpeg, `@place` em mordent,
   `@tstamp` em harm).
4. Itens de fase/ordem (1.4, 1.5, vários do §3) exigem fixture DEEP antes
   de qualquer edição, pelo protocolo do loop (`loop-prompt.md` §3):
   `probe_diff` → campo a campo → função C++ inteira + callers →
   instrumentação (`fprintf`, `diff` vazio) → armadilhas do diário.
