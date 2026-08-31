# 05r1a — view_element.dart: correção do cálculo de altura do KeySig (y off by 720)

## Contexto

Você vai corrigir `lib/src/rendering/view_element.dart`, método `drawKeySig` e helpers `_calcLoc` / `_keyAccidStaffLoc`.
Trabalhe a partir de `verovio_dart/`. Não commite — quem commita é o `medium` que gerou este aqui.

Famílias afetadas: `chord` (1 arquivo), `note` (1 arquivo) via `keySig[staffDef]` no `probe_diff --rank`.

## A divergência

    dart run tool/probe_diff.dart test/corpus/chord/chord-004.mei
      seq 19  fn=DrawSmuflCode  path=measure[1]/staff[1]/layer[1]/keySig[staffDef]
        x:      esperado 769   obtido 769
        y:      esperado 1809   obtido 1089   (Δ -720)
        code:   esperado E260   obtido E260
      origem provável: View::DrawKeySig (view_element.cpp:993)

    dart run tool/probe_diff.dart test/corpus/note/note-001.mei
      seq  8  fn=DrawSmuflCode  path=measure[1]/staff[1]/layer[1]/keySig[staffDef]
        y:      esperado 1627   obtido 906   (Δ -721)  # variação similar

O mesmo padrão aparece em `note/note-004.mei` (mRest y +180) — ambos vêm de `loc` errado.

## A causa (já diagnosticada — não investigue, aplique)

`View::DrawKeySig` (view_element.cpp:993) e `View::DrawKeyAccid` (view_element.cpp:1129) calculam

```cpp
const int loc = PitchInterface::CalcLoc(pname, oct, clefLocOffset);
int y = staff->GetDrawingY() + staff->CalcPitchPosYRel(m_doc, loc);
```

onde `PitchInterface::CalcLoc` (pitchinterface.cpp:188) é

```cpp
return ((oct - OCTAVE_OFFSET) * 7 + (pname - 1) + clefLocOffset);
```

com `OCTAVE_OFFSET = 4`.

O Dart em `view_element.dart:2598` faz

```dart
int _calcLoc(Pitchname pname, int oct, int clefLocOffset) {
  return (pname.value - 1) + oct * 7 - clefLocOffset;
}
```

isto é `oct*7` em vez de `(oct-4)*7` e `-clefLocOffset` em vez de `+clefLocOffset`.
Delta para `clefLocOffset = 0` é `28 - 0 = 28` passos diatônicos, que vezes `unit` (≈ 25-90) dá o Δ ≈ 720 observado.

O mesmo `_calcLoc` alimenta `_keyAccidStaffLoc` e `drawKeySigCancellation` via `_calcLoc`/`PitchInterface.calcLoc`. O `drawMRest` também usa `element.getDrawingY()` que vem de `PitchInterface::CalcLoc` correto no layout, mas o `drawKeySig` usa o `_calcLoc` quebrado no rendering.

`_clefLocOffset` em `view_element.dart:2488` ainda usa `_dyn(clef).getClefLocOffset` com try/catch e fallback por string `contains('g')`. O C++ usa `Clef::GetClefLocOffset()` direto (clef.cpp:85) e o Dart já tem `Clef.getClefLocOffset()` idêntico (basic_elements.dart:2340). O try/catch esconde o método tipado.

## A correção

1. **Fix `_calcLoc`** em `lib/src/rendering/view_element.dart:2598`:
   ```dart
   int _calcLoc(Pitchname pname, int oct, int clefLocOffset) {
     // Mirrors PitchInterface::CalcLoc (pitchinterface.cpp:188)
     // with OCTAVE_OFFSET = 4 (vrvdef.h:744)
     return (oct - 4) * 7 + (pname.value - 1) + clefLocOffset;
   }
   ```
   Remova o comentário longo que descreve a aproximação errada.

2. **Fix `_clefLocOffset`** em `lib/src/rendering/view_element.dart:2488`:
   Troque
   ```dart
   int _clefLocOffset(Clef clef) {
     try {
       final dynamic dyn = _dyn(clef);
       if (dyn.getClefLocOffset != null) {
         return dyn.getClefLocOffset() as int;
       }
     } catch (e) { e.toString(); }
     // fallback string contains ...
   }
   ```
   por
   ```dart
   int _clefLocOffset(Clef clef) {
     // Mirrors Clef::GetClefLocOffset (clef.cpp:85)
     return clef.getClefLocOffset();
   }
   ```
   Remova todo fallback por `shape.contains`.

3. **Garantir import** se necessário: `view.dart` já expõe `Pitchname`; não precisa nova import. Se o linter reclamar de `Pitchname` não importado, importe `package:verovio_dart/src/model/atts/mei_enums.dart` em `view.dart` (já importado).

4. **Opcional**: `drawMRest` y para `mRest` não usa `_calcLoc`; se após o fix o `probe_diff` de `note-004.mei` ainda divergir em `mRest` y (+180), abra nova investigação — não mexa no `drawMRest` nesta unidade.

## Verificação

    dart run tool/probe_diff.dart test/corpus/chord/chord-004.mei
    # tem de sair "0 divergências" para este arquivo (seq 19 limpo)

    dart run tool/probe_diff.dart test/corpus/note/note-001.mei
    # y do keySig deve bater

    tool/task_check.sh view_element.dart chord note
    # tem de imprimir PASS

O Haiku só termina quando **as duas** verificações passarem.
