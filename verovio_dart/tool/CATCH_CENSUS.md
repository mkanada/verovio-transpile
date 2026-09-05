# CATCH_CENSUS — catches vivos × mortos em `lib/src/rendering/` (loop de tipagem, PREPARO)

Censo mecânico, não por leitura: cada um dos 436 `catch` de `lib/src/rendering/` (`view_control.dart`,
`view_element.dart`, `view_mensural.dart`, `view_text.dart`) foi instrumentado para registrar
`arquivo:linha:índice` (o índice distingue as 3 linhas com dois `catch` na mesma linha) quando dispara,
sem mudar controle de fluxo — o fallback que já existia continuou rodando depois do registro. O corpus
inteiro (621 arquivos de `test/corpus`) foi renderizado com `dart run tool/compare_svg.dart --all`
(instrumentado), a saída de instrumentação (stderr, separada de stdout) foi coletada, e a
instrumentação foi revertida (`git checkout -- verovio_dart/lib`) antes de este arquivo ser gravado —
`git diff --stat -- verovio_dart/lib` ficou vazio depois.

**Falhas (exceção durante renderização) = 0** durante a corrida instrumentada (mesmo total de
`tool/SVG_VALIDATION.md` sem instrumentação: 373 divergentes, 0 falhas, 0 sem-render) — a
instrumentação não mudou o SVG produzido (byte-idêntico: `git diff --stat` de
`test/golden/dart/**` e `tool/SVG_VALIDATION.md` ficou vazio após a corrida).

## Resultado principal

| | contagem |
|---|---|
| `catch` totais instrumentados | 436 |
| `catch` que dispararam (vivos) em pelo menos 1 dos 621 arquivos | **37** (8.5%) |
| `catch` que nunca dispararam (mortos) | **399** (91.5%) |
| total de disparos (todos os catches vivos somados, todos os arquivos) | 32032 |

Por arquivo:

| arquivo | catch totais | vivos | mortos |
|---|---|---|---|
| view_control.dart | 240 | 26 | 214 |
| view_element.dart | 118 | 7 | 111 |
| view_mensural.dart | 77 | 4 | 73 |
| view_text.dart | 1 | 0 | 1 |

A imensa maioria (91.5%) dos `catch (e) { e.toString(); }`/equivalentes em `rendering/` é código morto
sobre o corpus atual — nunca protege nada nos 621 arquivos. Isso é a maior alavanca do loop: a trilha
MORTOS pode remover esses 399 `catch` (e o `try` associado) em lote, sem risco, porque este censo é a
prova. Os 37 vivos são a lista real de defeitos de fidelidade candidatos à trilha MEMBRO/MÉTODO.

## Os 37 catches vivos, por número de arquivos do corpus que disparam (maior alcance primeiro)

Cada linha: chave `arquivo:linha:índice`, quantos dos 621 arquivos do corpus dispararam nele ao menos
uma vez, total de disparos somado, e uma nota rápida (não investigação profunda — isso é trabalho das
rodadas MEMBRO/MÉTODO) do que o `try` ao redor parece estar tentando obter.

| chave | arquivos | disparos | o que o `try` tenta (nota rápida) |
|---|---|---|---|
| `view_control.dart:3847:0` | 621 | 4861 | `drawSystemElement` — `end.getStart()` num `systemMilestoneEnd`; cai para `_dyn(element).start`. Dispara em **todo** arquivo do corpus — candidato nº1 para MEMBRO. |
| `view_element.dart:1711:0` | 600 | 9311 | `drawClef` — bloco que só teria efeito se `_dyn(clef).getVisible` existisse (o corpo do `if` está vazio, é comentário morto); a chamada `_dyn(clef).getVisible` em si lança porque `Clef` não tem esse getter. Maior contagem de disparos do censo. |
| `view_control.dart:394:0` | 94 | 1894 | `calculatePrincipalStaff` via `_dyn(element)` num `ControlElement` de phrase/slur; o corpo do `try` só tem um `if` com comentário `// ignore: unused` vazio — parece um `try` inteiramente vestigial. |
| `view_mensural.dart:522:0` | 51 | 5232 | ligature straight/curved: leitura de uma opção/valor (`val`) cujo `toString()` decide reto×curvo; cai para `straight = !isMensuralBlack`. |
| `view_control.dart:1588:0` | 49 | 704 | `dynam.isSymbolOnly()` via `_dyn` (cache de modelo); cai silenciosamente, mantendo o valor já calculado por `_dynamIsSymbolOnly`. |
| `view_control.dart:1749:0` | 43 | 627 | `drawDynam` — `_dyn(dynam).getSymbolStr(singleGlyphs)`; cai para `_dynamGetSymbolStr(dynamText, singleGlyphs)` (helper local já existe, não é `UnimplementedError`). |
| `view_control.dart:1801:0` | 43 | 627 | `drawDynamSymbolOnly` — `_dyn(dynam).getEnclosingGlyphs()` (tenta 3 formas: List, Record, tupla dinâmica) sempre lança; cai para mapeamento manual de `_dyn(dynam).enclose`. |
| `view_mensural.dart:948:0` | 19 | 2858 | `getMensuralStemDir`/análogo — `_dyn(layer).getDrawingStemDir(note)`; cai para `layer.getDrawingStemDir()` sem argumento (que também não existe, ver `:949` no corpo, mas esse **não** disparou — a 2ª camada de fallback nunca chegou a lançar porque a análise não avançou, ou a 3ª tentativa (`:950`) resolveu). |
| `view_mensural.dart:345:0` | 19 | 668 | `_dyn(note).stemDir` num contexto de nota mensural; cai para `_dyn(note).getStemDir()`. |
| `view_mensural.dart:349:0` | 19 | 668 | fallback aninhado do anterior — `_dyn(note).getStemDir()` também lança; cai silenciosamente (`hasStemDir`/`sd` ficam como estavam). |
| `view_element.dart:723:0` | 12 | 1030 | `drawMultiRest` — tenta achar o próximo clef via `layer.getNext` dinâmico; corpo do `if` interno é vazio (comentário `// already handled`) — outro `try` de efeito nulo. |
| `view_element.dart:830:0` | 12 | 1030 | `drawMultiRest` — leitura de `numVisible`/`hasNumVisible`/`getNumVisible` via `_dyn(multiRest)` em cascata; cai para a 2ª tentativa em `:834`. |
| `view_element.dart:834:0` | 12 | 1030 | 2ª tentativa do anterior: `_dyn(multiRest).getNumVisible()`; também lança, `numVisible` fica com o valor default `true`. |
| `view_control.dart:4467:0` | 12 | 100 | `drawBarLine`(ish) — `_dyn(leftBarline).form ?? _dyn(leftBarline).getForm?.call()`; cai silenciosamente, `form` fica `null`, `fs` vira `''`. |
| `view_control.dart:1645:0` | 8 | 124 | leitura de `tstamp`/`hasTstamp` via `_dyn(dynam)` para decidir alinhamento (`isTstamp`); cai sem setar `isTstamp`. |
| `view_control.dart:4026:0` | 8 | 115 | `drawSystemElement`/ending — `_dyn(endingMeasure).calculateRightBarLineWidth(doc, staffSize)`; cai para `rightBarLineWidth = unit * 2`. |
| `view_control.dart:3961:0` | 8 | 105 | ending — leitura de `endingRend` (top/grouped) via encadeamento `_dyn`; cai deixando `isTop = false`. |
| `view_control.dart:4043:0` | 8 | 90 | ending — leitura de `drawingRightBarLine` via `_dyn(endingMeasure)` para decidir se a barra é invisível; cai sem ajustar `endX`. |
| `view_control.dart:4154:0` | 4 | 40 | `_getOctaveGlyph` — `octave.disPlace` direto lança (getter não existe no tipo estático); cai para `:4157`. |
| `view_control.dart:4157:0` | 4 | 40 | 2ª tentativa do anterior — `_dyn(octave).getDisPlace()`; também lança; `place = Staffrel.above` (default). |
| `view_control.dart:4131:0` | 4 | 40 | `_getOctaveLineWidth` — `_dyn(oct).getLineWidth(doc, unit)`; cai para o cálculo manual `w * unit` com `octaveLineThickness`. |
| `view_control.dart:829:0` | 4 | 40 | octave — `_dyn(octave).getLendsym()`; cai deixando `lendsym = Linestartendsymbol.none` (default já setado antes do `try`). |
| `view_control.dart:839:0` | 4 | 35 | octave — `_dyn(octave).getLform()`; cai deixando `lf` sem valor (o `if (lf == ...)` seguinte nunca bate). |
| `view_element.dart:3252:0` | 1 | 232 | `drawSyl` (modo facsimile/neume) — `_dyn(syl).getDrawingWidth()/getDrawingHeight()`; cai para `:3256`. |
| `view_element.dart:3256:0` | 1 | 232 | 2ª tentativa — `_dyn(syl).getContentWidth()/getContentHeight()`; também lança (só 1 arquivo do corpus exercita este modo). |
| `view_element.dart:3060:0` | 1 | 49 | `mRpt`/repetição — leitura de `numVisible` em cascata (`dyn.numVisible`/`hasNumVisible`/`getNumVisible`); cai sem alterar `numVisible`. |
| `view_control.dart:4092:0` | 1 | 30 | `_getBracketSpanLineWidth` — `_dyn(bs).getLineWidth(doc, unit)` com `doc` nullable; cai para `:4095`. |
| `view_control.dart:4095:0` | 1 | 30 | 2ª tentativa — `_dyn(bs).getLineWidth(doc!, unit)` (com `!`); também lança; cai para o cálculo manual com `octaveLineThickness`. |
| `view_control.dart:561:0` | 1 | 30 | bracketSpan — `bracketSpan.lstartsym` direto; cai para `:565`. |
| `view_control.dart:565:0` | 1 | 30 | 2ª tentativa — `_dyn(bracketSpan).getLstartsym()`; também lança; `lstart` fica no default `none`. |
| `view_control.dart:590:0` | 1 | 30 | bracketSpan — `bracketSpan.lendsym` direto; cai para `:593`. |
| `view_control.dart:593:0` | 1 | 30 | 2ª tentativa — `_dyn(bracketSpan).getLendsym()`; também lança; `lendsym` fica no default. |
| `view_control.dart:1132:0` | 1 | 21 | bloco de extensão de linha (trill/ligadura?) — leitura de `hasContentBB`/`getContentLeft` via `nextPos`; corpo externo inteiro cai (engloba um `try` interno em `:1125/:1128` que **não** disparou sozinho — só o `catch` externo registrou). |
| `view_control.dart:1179:0` | 1 | 21 | `_dyn(element).getNextLink()` para decidir `deactivate`; cai deixando `deactivate = true` (default). |
| `view_control.dart:4227:0` | 1 | 14 | `_getFYRel` — `_dyn(this).getFYRel(f, staff)`; cai (sem `return` no catch — repare que o método aparenta continuar para o fallback manual logo abaixo, ver observação de possível bug de controle de fluxo). |
| `view_control.dart:1039:0` | 1 | 7 | trill — `trill.lstartsym` direto; cai para `:1042`. |
| `view_control.dart:1042:0` | 1 | 7 | 2ª tentativa — `_dyn(trill).getLstartsym()`; também lança; `lstartsym` fica no default. |

### Observação de possível bug real (não investigado a fundo — reportar para a rodada MÉTODO)

`view_control.dart:4227` (`_getFYRel`) tem a forma:
```dart
int _getFYRel(F f, Staff staff) {
  try {
    return _dyn(this).getFYRel(f, staff) as int;
  } catch (e) { ...; e.toString(); }
  // Fallback: emulate view_element.cpp GetFYRel
  int y = staff.getDrawingY();
  ...
}
```
O `catch` não tem `return`, então quando dispara o método CONTINUA para o fallback manual abaixo — isso é
o comportamento correto (a ausência de `return` no catch É o fallback, não um bug). Mas vale a pena uma
rodada MÉTODO conferir se `_getFYRel` teria de existir como membro em algum tipo (`F`? `this`, i.e.
`View`?) no C++ — `_dyn(this).getFYRel(...)` chamando um método na própria `View` via `_dyn` é incomum
(as outras 435 chamadas são sobre objetos do modelo, não sobre `this`) e sugere um método real da
`View` (`GetFYRel`) que talvez devesse ser um método Dart tipado normal em vez de passar por `_dyn`.

## As 3 linhas com dois `catch` na mesma linha (índice 0 e 1)

`view_control.dart:3847` (`try { start = end.getStart(); } catch (e) { ...:0...; try { start =
_dyn(element).start; } catch (e) { ...:1...; e.toString(); } }`) — **só o índice 0 disparou** (621
arquivos); o índice 1 (fallback `_dyn(element).start`) nunca precisou disparar nos 621 arquivos do
corpus — o que sugere que `_dyn(element).start` sempre resolve quando `getStart()` falha, i.e. o
segundo `catch` de `3847` é 100% morto apesar do primeiro ser o catch mais disparado do censo.

`view_mensural.dart:441` e `:442` (duas tentativas de `getContentLeft/Right` × `getDrawingX`) — **nenhum
dos dois índices disparou** em nenhum arquivo do corpus; ambos os pares (4 `catch` no total) estão
mortos.

## Lista completa dos 399 `catch` mortos (nunca dispararam nos 621 arquivos do corpus)

Formato `arquivo:linha:índice` (índice quase sempre 0; ver seção acima para os pares 3847/441/442).
Ordenados por arquivo, depois por linha. Prova de morte: instrumentação + corrida completa do corpus
(`dart run tool/compare_svg.dart --all`, 621/621 arquivos processados, 0 falhas).

Amostra (20 primeiras das 399 — lista completa em `tool/CATCH_CENSUS_dead.txt`):

```
view_control.dart:169:0
view_control.dart:175:0
view_control.dart:185:0
view_control.dart:201:0
view_control.dart:207:0
view_control.dart:220:0
view_control.dart:281:0
view_control.dart:289:0
view_control.dart:295:0
view_control.dart:312:0
view_control.dart:323:0
view_control.dart:332:0
view_control.dart:339:0
view_control.dart:344:0
view_control.dart:364:0
view_control.dart:369:0
view_control.dart:418:0
view_control.dart:485:0
view_control.dart:497:0
view_control.dart:508:0
```

O arquivo completo com as 399 linhas (não truncado) está em `tool/CATCH_CENSUS_dead.txt`, um `arquivo:
linha:índice` por linha, para consumo mecânico pela trilha MORTOS (grep/awk direto, sem precisar
reabrir este relatório). O arquivo completo com os 37 vivos (chave + contagem de arquivos + contagem de
disparos) está em `tool/CATCH_CENSUS_fired.tsv`.

## Metodologia (para reproduzir ou refazer o censo)

1. Reescrita mecânica de cada corpo de `catch` em `lib/src/rendering/*.dart` inserindo, logo após o `{`
   de abertura, `stderr.writeln('CATCH_HIT:<arquivo>:<linha>:<índice>');` — sem mudar controle de fluxo
   (o fallback original continua rodando na mesma linha/depois). Script mecânico (não manual), aplicado
   às 436 ocorrências de `catch (` do diretório (`_dyn.` e `catch (_)` não entram nessa contagem — são
   os `catch` em si).
2. Marcador por arquivo do corpus: uma linha adicionada em `tool/compare_svg.dart` (revertida depois),
   `stderr.writeln('CENSUS_FILE:$rel');`, logo antes de `renderSvgForComparison(meiPath)` no loop do
   modo `--all`, para atribuir cada disparo ao arquivo do corpus que o produziu (ambos os marcadores
   vão para stderr, na mesma ordem de execução — sem risco de entrelaçamento entre streams).
3. `dart run tool/compare_svg.dart --all` com stdout e stderr redirecionados para arquivos separados.
   621/621 arquivos processados, 0 falhas, resultado idêntico (byte a byte) ao `tool/SVG_VALIDATION.md`
   e aos dumps de `test/golden/dart/**` gerados sem instrumentação — a instrumentação não altera o SVG
   produzido.
4. `stderr` parseado linha a linha: cada `CENSUS_FILE:` atualiza o "arquivo atual"; cada `CATCH_HIT:`
   incrementa o contador daquela chave e adiciona o arquivo atual ao conjunto de arquivos que a
   dispararam.
5. Instrumentação revertida com `git checkout -- verovio_dart/lib verovio_dart/tool/compare_svg.dart`.
   `git diff --stat -- verovio_dart/lib` vazio confirmado antes deste arquivo ser gravado.

Gerado em 2026-09-05, árvore em `1695f718` (mais o `tool/debt_report.dart` novo desta rodada PREPARO).
