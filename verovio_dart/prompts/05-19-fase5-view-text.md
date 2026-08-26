# 05-19 — view_text.cpp: elementos de texto, rend, figuras e running elements

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `view_text.cpp` inteiro: o desenho de todo conteúdo textual — `rend`, `lb`, `num`, `fig`,
`svg`, `symbol`, `div`, as strings especializadas (dir/dynam/harm/lyric), e os running elements
(cabeçalho e rodapé de página).

## Pré-condições

Tarefa **05-18** concluída.

```bash
cd verovio_dart
ls lib/src/rendering/view_slur.dart lib/src/rendering/view_tuplet.dart
dart test 2>&1 | tail -1     # verde, ≥ 498
```

## Referência C++

`origin/src/src/view_text.cpp` (701 linhas):

| Linha | Função | Linha | Função |
|---:|---|---:|---|
| 49 | `DrawF` | 352 | `DrawFig` |
| 69 | `DrawTextString` | 369 | `DrawRend` |
| 76 | `DrawDirString` | 480 | `DrawText` |
| 91 | `DrawDynamString` | 536 | `DrawGraphic` |
| 155 | `DrawHarmString` | 557 | `DrawSvg` |
| 224 | `DrawTextElement` | 585 | `DrawSymbol` |
| 264 | `DrawLyricString` | 642 | `DrawRunningElements` |
| 318 | `DrawLb` | 663 | `DrawTextLayoutElement` |
| 334 | `DrawNum` | 696 | `DrawDiv` |

Atenção à linha 648, que faz `vrv_cast<BBoxDeviceContext *>(dc)` — há um caminho especial quando o
device context é o de bounding box. Reproduza-o (em Dart, um `is BBoxDeviceContext`).

`DrawRend` (369-479) é a mais longa: trata `@fontfamily`, `@fontsize`, `@fontstyle`, `@fontweight`,
`@halign`, `@valign`, `@rend`, e a recursão em filhos.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/rendering/view_text.dart` (`part of` `view.dart`).
- **Alterar** `lib/src/rendering/view.dart` e `view_page.dart` (running elements).
- **Criar** `test/view_text_test.dart`.

## Passo a passo

1. Leia as 701 linhas.
2. Porte `DrawTextElement` (o despachante) e `DrawText`.
3. Porte `DrawRend`, `DrawLb`, `DrawNum`, `DrawFig`, `DrawGraphic`, `DrawSvg`, `DrawSymbol`, `DrawDiv`.
4. Porte as strings especializadas: `DrawDirString`, `DrawDynamString`, `DrawHarmString`,
   `DrawLyricString`, `DrawF`, `DrawTextString`.
   `DrawDynamString` (91-154) e `DrawHarmString` (155-223) fazem substituição de caracteres por
   glifos SMuFL (o `p`/`f`/`mf` das dinâmicas, os símbolos de cifra) — leia as tabelas.
5. Porte `DrawTextLayoutElement` e `DrawRunningElements`, com o caminho especial do
   `BBoxDeviceContext` da linha 648.
6. Testes: `test/corpus/rend/` (4), `test/corpus/dir/` (12, menos `dir-011`/`dir-012` que não são
   UTF-8), `test/corpus/dynam/` (10), `test/corpus/harm/` (5), `test/corpus/lyric/` (16),
   `test/corpus/figured-bass/` (5), `test/corpus/pgfoot/` (1), `test/corpus/symbol/` (2),
   `test/corpus/font/` (2).
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 512 testes**
- [ ] As 18 funções de `view_text.cpp` têm contraparte — prove no relatório com o diff de nomes
- [ ] `dart run tool/compare_svg.dart test/corpus/dynam --mode=structural` reporta **≥ 7 de 10** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/harm --mode=structural` reporta **≥ 3 de 5** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` maior que na tarefa 05-18
- [ ] Um teste prova o caminho especial de `BBoxDeviceContext` em `DrawRunningElements`
- [ ] Relatório em `prompts/reports/05-19.md`
- [ ] `PLANO.md`: checkbox de `view_text.cpp` marcado

## Armadilhas conhecidas

- `test/corpus/dir/dir-011.mei` e `dir-012.mei` **não são UTF-8**. Pule-os.
- As tabelas de substituição SMuFL de `DrawDynamString`/`DrawHarmString` são literais no C++.
  Copie-as caractere a caractere; um símbolo errado só aparece num arquivo do corpus.
- `DrawRend` recursa em filhos `rend` aninhados, empilhando estado de fonte. Empilhe e desempilhe.
- Alinhamento horizontal (`@halign`) muda o atributo `text-anchor` do SVG **e** o X emitido.
- Running elements são desenhados fora do fluxo de sistemas, com coordenadas de página.

## Fora de escopo

- `view_control.cpp` (tarefas 05-20 a 05-22).
