# 05r1c — lib/src/testing/draw_recorder.dart: corrigir path de scoreDef[?] vs scoreDef[1]

## Contexto

Correção de divergência de `StartGraphic` onde o `gId`/`path` não batem por causa do `SegmentKey` retornando `1` em vez de `?` para objetos membro.

Trabalhe a partir de `verovio_dart/`. Não commite.

Famílias afetadas: 37 arquivos com `StartGraphic` no topo do ranking (ex.: `arpeg/arpeg-003.mei`, `beam/beam-026.mei`).

## A divergência

    dart run tool/probe_diff.dart test/corpus/arpeg/arpeg-003.mei
      seq 7  fn=StartGraphic  path=pages[1]/page[1]/system[1]/scoreDef[?]/staffGrp[1]/grpSym[1]
        gClass:   esperado    obtido 
        gId:   esperado c1s10whe (pages[1]/page[1]/system[1]/scoreDef[?]/staffGrp[1]/grpSym[1])   obtido aNGIEQP (scoreDef[1]/staffGrp[1]/grpSym[1])
        graphicID:      esperado 0   obtido 0
        prepend:      esperado 0   obtido 0
      origem provável: SvgDeviceContext::StartGraphic (svgdevicecontext.cpp:249) — View::DrawLayerElement

O `path` esperado inclui `pages[1]/page[1]/system[1]/scoreDef[?]` enquanto o obtido é `scoreDef[1]/staffGrp[1]/grpSym[1]` (sem prefixo e com `1` em vez de `?`). O `gId` diverge porque é `@xml:id` volátil (`xmlIdSeed=12345`) comparado por `path` — quando os `path`s diferem, o `gId` também diverge (probe_diff mostra `c1s10whe (pages/...)` vs `aNGIEQP (scoreDef/...)`).

## A causa (já diagnosticada — não investigue, aplique)

`vrv::probe::Path` (build-probe/src/include/vrv/vrvprobe.h:281) enraíza em `Measure` quando há ancestral `Measure`; caso contrário, enraíza no topo abaixo de `Doc` (ex.: `pages`). Para `GrpSym` cujo pai é `StaffGrp` cujo pai é `ScoreDef` cujo pai é `System` (não `Measure`), o caminho C++ é `pages[1]/page[1]/system[1]/scoreDef[?]/staffGrp[1]/grpSym[1]`.

O `ScoreDef` cujo pai é `System` **não é filho** de `System` (é o `m_drawingScoreDef` membro `System::m_drawingScoreDef`, system.h). Portanto `SegmentKey` em C++ retorna `"?"` (vrvprobe.h:261) — "não é filho do pai nem membro conhecido".

O Dart em `lib/src/testing/draw_recorder.dart:104` tem `_cppSegmentKey` que só conhece `Measure::m_leftBarLine/rightBarLine` e `Layer::GetStaffDef*`. Quando `parent is System && object is ScoreDef`, cai no fallback que conta filhos com mesmo `className` entre `parent.children` — como `System.children` não contém `ScoreDef`, `index` fica 0 e retorna `"?"`? Na verdade o código atual retorna `"1"` quando `parent == null` mas para `System` com `ScoreDef`, `parent` não é null, então entra no loop: `for (child in parent.children) if (className==ScoreDef) index++` — como nenhum filho é `ScoreDef`, `index` fica 0 e depois `return '?'` (linha 157). O comportamento atual já retorna `"?"` para `ScoreDef` sob `System`? Mas o `path` observado é `scoreDef[1]`, não `scoreDef[?]`. Isso indica que o `ScoreDef` do `GrpSym` nesta divergência **não tem pai `System`**, mas sim pai `Doc` ou `Score` onde ele **é** filho (lista contém `ScoreDef`), então retorna `1`.

No C++, o `ScoreDef` desenhado é `System::m_drawingScoreDef`, cujo pai é `System` (definido em `System::SetDrawingScoreDef` ou via `setParent` durante `ScoreDefSetSystemFunctor`). No Dart, `System.setDrawingScoreDef` (system_page_elements.dart:175) faz `this.drawingScoreDef = drawingScoreDef` sem `setParent`. Portanto o `ScoreDef` copiado não tem `parent = System`; seu `parent` permanece o original (`Score`/`Section`) ou null, então `_cppPath` sobe até `scoreDef[1]` sem prefix `pages/system`.

Além disso, `Pages` → `Page` → `System` não aparecem no `_cppPath` do Dart porque o `System` não é ancestral do `ScoreDef` quando o `parent` não é setado.

## A correção

1. Em `lib/src/model/system_page_elements.dart:175`, `System.setDrawingScoreDef`:
   ```dart
   void setDrawingScoreDef(ScoreDef? drawingScoreDef) {
     this.drawingScoreDef = drawingScoreDef;
     if (drawingScoreDef != null) {
       drawingScoreDef.setParent(this);
     }
   }
   ```
   E `resetDrawingScoreDef` deve limpar parent se necessário.

2. Em `lib/src/model/doc.dart:265` (`Page.drawingScoreDef` é `final ScoreDef drawingScoreDef = ScoreDef();`) — ela já é membro da `Page`, mas seu `parent` deve ser `Page`. Garanta em `Page.reset()` ou onde `drawingScoreDef` é usada que `drawingScoreDef.setParent(this)` é chamado após `replaceWithCopyOf`. Verifique `lib/src/layout/setscoredef_functor.dart:388` onde `page.drawingScoreDef.replaceWithCopyOf(upcomingScoreDef)` — não seta parent. Acrescente `page.drawingScoreDef.setParent(page);` após o replace.

3. Em `lib/src/testing/draw_recorder.dart:104`, `_cppSegmentKey`, acrescente caso para `System`/`Page` ScoreDef:
   ```dart
   if (parent is System && object is ScoreDef) return '?';
   if (parent is Page && object is ScoreDef) return '?';
   if (parent is Pages && object is Page) {
     // Page sob Pages já é filho, retorna índice normal — não precisa '?'
   }
   ```
   E para `System` sob `Page` e `Page` sob `Pages`, o caminho deve incluir `pages[1]/page[1]/system[1]` quando não há `Measure` ancestral — o `_cppPath` já faz isso se o `parent` chain estiver correto. Não mude o loop que coleta até `measure` break; para objetos sem `Measure`, ele já sobe até `Doc`, então `pages` aparecerá quando o `ScoreDef` tiver `parent = System`.

4. Verifique `lib/src/model/doc.dart` onde `Pages` é adicionado a `Doc`: `Doc` deve ter `Pages` como filho, e `Page` como filho de `Pages`, `System` como filho de `Page`. O `Find` de `Measure` deve estar sob `System` (já é). Após corrigir parents, o `_cppPath` para `GrpSym` deve ser `pages[1]/page[1]/system[1]/scoreDef[?]/staffGrp[1]/grpSym[1]` igual ao C++.

## Verificação

    dart run tool/probe_diff.dart test/corpus/arpeg/arpeg-003.mei
    # seq 7 deve passar a limpo ou divergir em campo posterior (não mais path)

    dart run tool/probe_diff.dart test/corpus/beam/beam-026.mei
    # similar

    tool/task_check.sh draw_recorder.dart arpeg beam
    # PASS (task_check verifica debt, não path; probe_diff verifica path)

Se o `gId` ainda divergir mas o `path` bater, o `probe_diff` compara `gId` por `path` (xpath) e deve passar — `gId` é volátil mas comparado via `cppIdToPath`. Com `path` igual, `gId` divergência desaparece.

