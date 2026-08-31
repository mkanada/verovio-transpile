# 05r1b — view_element.dart: correção do DrawAccid x (Δ -57) e investigação de largura de pentagrama

## Contexto

Correção de divergência de `DrawSmuflString` para `accid` e de `DrawLine` para `staff` (largura do compasso).
Trabalhe a partir de `verovio_dart/`. Não commite.

Famílias afetadas: `accid` (14), `note` (via accid), `chord` etc. — 198 arquivos no ranking com `DrawLine Staff` e o `accid` com `x` off.

## A divergência

    dart run tool/probe_diff.dart test/corpus/accid/accid-001.mei
      seq 10  fn=DrawLine  path=measure[1]/staff[1]
        x1:      esperado 0   obtido 0
        y1:      esperado 1269   obtido 1269
        x2:      esperado 4056   obtido 4065   (Δ 9)
        y2:      esperado 1269   obtido 1269
      origem provável: View::DrawStaff / DrawHorizontalLine (view_graph.cpp:40)

    dart run tool/probe_diff.dart test/corpus/note/note-004.mei  # via probe antes do fix 05r1a
      seq 27  fn=DrawSmuflCode  path=measure[1]/staff[1]/layer[1]/mRest[1]
        y: 1266 vs 1446 (Δ 180)

A nota `note-001.mei` com `accid`:
      seq  8  fn=DrawSmuflString  path=measure[1]/staff[1]/layer[1]/note[2]/accid[1]
        x: esperado 2859 obtido 2802 (Δ -57), y ok, code E262
      cabeça da nota em x=3026 nos dois — desvio horizontal sistemático do accid.

## A causa (já diagnosticada — não investigue, aplique)

1. **Largura de pentagrama (x2)**: `View::DrawStaffLines` (view_page.cpp:1317) faz `x2 = x1 + measure->GetWidth()`. O `measure->GetWidth()` vem de `Measure::GetWidth()` = `rightAlignment.getXRel()` (measure.cpp). O Dart em `basic_elements.dart:553` faz igual, mas o `rightAlignment.xRel` pode divergir por causa do `AdjustAccidXFunctor` (adjust_accid_x.dart) que não aplica o mesmo offset que o C++. O `probe_diff` de `accid` com Δ 9 na largura é sintoma de `accid` xRel errado de 57 propagado para `rightAlignment`.

   Para esta rodada, o foco é o **x do accid** (Δ -57). A largura `x2` deve convergir quando o `x` do accid convergir; não mexa em `view_page.dart` nesta unidade — o `measure.getWidth()` virá certo quando o `accid.getDrawingX()` vier certo.

2. **accid x**: `View::DrawAccid` (view_element.cpp:242) desenha em `accid->GetDrawingX()` sem acrescentar `note->GetDrawingRadius()` no caso normal (só quando `HasPlace`/`HasOnstaff`/`edit`). O Dart em `view_element.dart:1972` faz `int x = accid.getDrawingX();` igual, mas o `accid.getDrawingX()` já deveria ter sido ajustado por `AdjustAccidXFunctor` (adjust_accid_x.dart). O functor Dart pode estar usando `getDrawingRadius` vs `getSelfLeft()` errado, ou `getContentRight` vs `getDrawingRadius`.

   Leitura do C++: `AdjustAccidXFunctor::VisitAccid` e `AdjustAccidWithSpace` usam `accid->GetDrawingRadius(m_doc)` para espaçamento. O Dart usa `accid.getSelfLeft()` / `getSelfRight()` em alguns ramos (ver `view_element.dart:_getDrawingRadius` fallback). Verifique `lib/src/model/layer_elements_gen.dart` se `Accid` tem `getDrawingRadius`.

   Para esta unidade, a correção é garantir que `AdjustAccidX` use `accid.getDrawingRadius(doc)` (nota) e que `View::DrawAccid` use `accid.getDrawingX()` sem offset extra no caso normal — exatamente como o C++. Se `accid.getDrawingX()` ainda estiver off por 57, a causa está no functor, não no `DrawAccid`; instrumente o functor com `cpp_probe` patch adicional se necessário, mas não adivinhe número.

## A correção

- Em `lib/src/layout/adjust_accid_x.dart`, verifique `VisitAccid` e `AdjustAccidWithSpace`: o cálculo `x = accid->GetDrawingX() - accid->GetDrawingRadius(m_doc)` vs `getSelfLeft()` está documentado no prompt 2026-08-30-medium-05 como hipótese. Compare linha a linha com `origin/src/src/adjustaccidxfunctor.cpp` (todo o arquivo, não trecho). A correção é usar `accid.getDrawingRadius(doc)` onde o C++ usa `GetDrawingRadius`, e `note.getDrawingRadius(doc)` onde usa `note->GetDrawingRadius`.

- Em `lib/src/rendering/view_element.dart:1972`, mantenha `int x = accid.getDrawingX();` sem `+ _getDrawingRadius` fora do bloco `hasPlace/hasOnstaff/isEdit`. O Dart já faz isso; confirme que não há `x += _getDrawingRadius` fora desse bloco (linha 2016 deve estar dentro do `if (hasPlace||...)`).

- Se `accid.getDrawingRadius` não existir no modelo, acrescente em `lib/src/model/layer_elements_gen.dart` (classe `Accid`): `int getDrawingRadius(Doc doc) => doc.getGlyphWidth(getAccidGlyph(...), staffSize, cueSize)/2` — mire `accid.cpp: GetDrawingRadius`.

## Verificação

    dart run tool/probe_diff.dart test/corpus/accid/accid-001.mei
    # seq 10 x2 deve bater (ou reduzir Δ de 9 para 0); se ainda off por <2, pode ser arredondamento

    dart run tool/probe_diff.dart test/corpus/note/note-001.mei
    # se accid x bater, a largura também deve bater

    tool/task_check.sh adjust_accid_x.dart accid
    tool/task_check.sh view_element.dart accid
    # ambos PASS
