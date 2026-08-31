# 05r3a — system_page_elements.dart: ScoreDef parent para StartGraphic path

## Contexto

Correção de `lib/src/model/system_page_elements.dart` (`System.setDrawingScoreDef`) para `arpeg/arpeg-003.mei`, `mensural/mensural-001.mei` e toda família com `DrawStaffGrp`/`grpSym` (37 arquivos com `StartGraphic` divergente antes do fix).

Trabalhe a partir de `verovio_dart/`. Não commite.

## A divergência

    dart run tool/probe_diff.dart test/corpus/arpeg/arpeg-003.mei
      seq 7  fn=StartGraphic  path=pages[1]/page[1]/system[1]/scoreDef[?]/staffGrp[1]/grpSym[1]
        gClass:   esperado ''   obtido ''
        gId:   esperado c1s10whe (pages[1]/page[1]/system[1]/scoreDef[?]/staffGrp[1]/grpSym[1])   obtido xP3I0KQ (scoreDef[1]/staffGrp[1]/grpSym[1])
      origem provável: SvgDeviceContext::StartGraphic (svgdevicecontext.cpp:249)

    dart run tool/probe_diff.dart --dir=test/corpus --rank
      37  StartGraphic :: SvgDeviceContext::StartGraphic — View::DrawLayerElement (antes)

## A causa (já diagnosticada — não investigue, aplique)

`System::m_drawingScoreDef` no C++ é criado como `new ScoreDef(); ReplaceWithCopyOf(drawingScoreDef); SetParent(this);` (`system.cpp:215-221`). O parent é `System`, então `probe::Path` para um `grpSym` descendente de `ScoreDef` inclui `pages/page/system/scoreDef[?]/staffGrp/grpSym` (`vrvprobe.h:299`, `SegmentKey` retorna `?` para membro System).

O Dart `System.setDrawingScoreDef` (`system_page_elements.dart:175`) fazia `this.drawingScoreDef = drawingScoreDef` — atribuição direta sem cópia nem `setParent`. O `upcomingScoreDef` do `ScoreDefSetCurrentFunctor` (`setscoredef_functor.dart:302`) é reutilizado entre sistemas; atribuir direto compartilhava o mesmo objeto entre múltiplos `System`s (causa do assert `parent==null` quando tentaram apenas `setParent` sem cópia, revertido em rodada 1). Sem parent, `DrawRecorder._cppPath` para o `grpSym` para em `scoreDef[1]` (parent null → `return '1'`), truncando o path para `scoreDef[1]/staffGrp[1]/grpSym[1]` sem `pages/page/system`.

O C++ clona e seta parent por sistema; o Dart deve fazer igual.

## A correção

Em `lib/src/model/system_page_elements.dart:175`, troque:

```dart
void setDrawingScoreDef(ScoreDef? drawingScoreDef) {
  this.drawingScoreDef = drawingScoreDef;
}
```

por (mirrors `system.cpp:215`):

```dart
void setDrawingScoreDef(ScoreDef? drawingScoreDef) {
  if (drawingScoreDef == null) {
    this.drawingScoreDef = null;
    return;
  }
  assert(this.drawingScoreDef == null);
  final ScoreDef copy = ScoreDef();
  copy.replaceWithCopyOf(drawingScoreDef);
  copy.setParent(this);
  this.drawingScoreDef = copy;
}
```

Já existe `replaceWithCopyOf` e `setParent` em `object.dart`. Não altere `Measure.setDrawingScoreDef` (lá o C++ NÃO seta parent, `measure.cpp:402`).

## Verificação

    dart run tool/probe_diff.dart test/corpus/arpeg/arpeg-003.mei
    # antes: seq 7 StartGraphic path diverge pages/... vs scoreDef[1]
    # depois: seq 7 StartGraphic limpo, primeira divergência migra para seq 67 DrawLine Staff (x2 2949 vs 4849) e ranking StartGraphic cai de 37 → 1 (só tuplet-004 resta)

    dart run tool/probe_diff.dart --dir=test/corpus --rank | head -20
    # StartGraphic deve cair para 1, DrawLine Staff sobe de 198 → ~216, DrawCurve brace ainda 8 (antes deste fix)

    dart analyze  # 8 issues
    dart test test/svg_golden_test.dart  # 2/2 pass

    tool/task_check.sh system_page_elements.dart arpeg mensural
    # PASS
