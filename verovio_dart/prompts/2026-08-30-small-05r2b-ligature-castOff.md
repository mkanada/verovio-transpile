# 05r2b — doc.dart: Ligature 11 vs 5 filhos — castOff mensural não quebra sistema

## Contexto

Investigação de `ligature/ligature-001.mei` (mensural.white/black, sem `<measure>`, 4 ligatures por staff) — 0/50 estrutural.

Trabalhe a partir de `verovio_dart/`. Não commite.

## A divergência

    dart run tool/compare_svg.dart test/corpus/ligature/ligature-001.mei
      svg/svg[0]/g[0]/g[2]: esperado [5 filhos], obtido [11 filhos]
      # C++: 1 ligature por sistema (2864 width), Dart: 4 ligatures num sistema (13784 width)

    /tmp/dart_lig.svg vs test/golden/cpp/ligature/ligature-001.svg
      Dart staff path M0 1266 L13784 1266 (system width 13784) vs C++ M0 1266 L2864 1266

    probe:
      ligature-001 sem fixture (ainda), mas `tool/_lig_svg.dart` mostra 4 ligatures em `layer` onde C++ tem 1.

## A causa (já diagnosticada — não investigue, aplique)

O arquivo é `notationtype="mensural.white"` / `black`, sem `<measure>` — é `Page::LayOut` mensural, que no C++ usa `ConvertToCastOffMensuralFunctor` (`cast_off_mensural.cpp`) para quebrar ligatures em sistemas por largura (`doc->GetOptions()->m_pageWidth`). O Dart em `lib/src/layout/cast_off_mensural.dart` (`ConvertToCastOffMensuralFunctor`) existe mas `Page.layOut` (`doc.dart:2041`) chama `castOffSinglePage.layOutVertically()` sem passar por `ConvertToCastOffMensural`.

O `Doc::CastOff` (`doc.cpp`) detecta `isMensuralMusicOnly()` e chama `ConvertToCastOffMensural` antes de `CastOffSystems`. O Dart `Doc.castOff` (`doc.dart:1980`) não tem esse ramo — apenas `ConvertToCastOffMensural` é importado mas nunca chamado em `castOff` normal.

Para esta unidade, **não corrija o castOff ainda** — apenas instrumente:

- Acrescente `fprintf` em `origin/src/src/cast_off.cpp` e `cast_off_mensural.cpp` para emitir `system width` e `ligature count` por sistema via `cpp_probe` patch `05-39` (só acréscimo, diff SVG vazio).
- Gere fixture `test/fixtures/cpp/05-39/ligature-001.mei.jsonl` com `tool/gen_probe_fixtures.sh ligature`.

A correção completa (ligatureAsBracket vs mensural) fica para 05r3, quando o instrumento estiver pronto.

## Verificação

    cpp_probe/build.sh 05-39 && cpp_probe/run.sh 05-39 test/corpus/ligature/ligature-001.mei /tmp/lig.jsonl --svg /tmp/probe.svg
    diff /tmp/clean.svg /tmp/probe.svg  # vazio

    dart run tool/probe_diff.dart test/corpus/ligature/ligature-001.mei  # deve mostrar system width divergente com seq e path
