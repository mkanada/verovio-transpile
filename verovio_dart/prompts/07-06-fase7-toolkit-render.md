# 07-06 — toolkit.cpp (A): render, getSVG e gestão de páginas

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fazer o `Toolkit` renderizar de verdade: `renderToSVG`, `getPageCount`, `redoLayout`,
`setScale`, `setOptions`/`getOptions`, e a gestão do documento carregado.

## Pré-condições

Tarefa **07-05** concluída.

```bash
cd verovio_dart
dart test 2>&1 | tail -1     # verde, ≥ 965
grep -n "TODO(phase-5): renderToSVG" lib/src/toolkit.dart   # linha 263
```

## Referência C++

`origin/src/include/vrv/toolkit.h` e `origin/src/src/toolkit.cpp` (2431 linhas). Esta tarefa:

`LoadData`, `LoadFile`, `LoadZipData`, `LoadZipFile`, `RenderData`, `RenderToSVG`,
`RenderToSVGFile`, `RenderToDeviceContext`, `GetPageCount`, `GetPageWithElement`, `RedoLayout`,
`RedoPagePitchPosLayout`, `SetScale`, `GetScale`, `SetOptions`, `GetOptions`, `GetDefaultOptions`,
`GetAvailableOptions`, `ResetOptions`, `SetResourcePath`, `GetResourcePath`, `SetInputFrom`,
`GetInputFrom`, `SetOutputTo`, `GetOutputTo`, `GetVersion`, `ResetXmlIdSeed`, `SaveFile`.

Localize cada um com `grep -n "Toolkit::<nome>" origin/src/src/toolkit.cpp`.

**Fora de escopo permanente** (Humdrum e PAE, excluídos por decisão do `PLANO.md`):
`ClearHumdrumBuffer`, `ConvertHumdrumToHumdrum`, `ConvertHumdrumToMIDI`, `ConvertMEIToHumdrum`,
`GetHumdrum`, `GetHumdrumFile`, `SetHumdrumBuffer`, `RenderToPAE`, `RenderToPAEFile`,
`ValidatePAE`, `ValidatePAEFile`. **Não os porte**; deixe um comentário dizendo que estão fora de
escopo por decisão registrada.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/toolkit.dart` — vai crescer bastante; considere dividir em
  `lib/src/toolkit.dart` + `lib/src/toolkit_render.dart` (`part of`) e justifique no relatório.
- **Alterar** `test/toolkit_io_test.dart`, criar `test/toolkit_render_test.dart`.
- **Criar** `tool/verovio_cli.dart` — um CLI mínimo espelhando o do C++, para comparar saídas.

## Passo a passo

1. Leia os métodos listados no `toolkit.cpp`.
2. Porte-os. `RenderToSVG` é o centro: instancia o `View`, o `SvgDeviceContext`, chama
   `DrawCurrentPage` e devolve a string.
3. **Apague os `TODO(phase-5)` e `TODO(phase-6)` de `toolkit.dart:263-264`** (o de MIDI sai na 07-07).
4. Escreva `tool/verovio_cli.dart` aceitando `-r`, `-o`, `-t`, `--scale`, `-p` e as opções longas,
   como o C++.
5. **Teste de ponta a ponta:** para cada arquivo do corpus, rode o CLI Dart e o C++ com os mesmos
   argumentos e compare os SVGs com `tool/compare_svg.dart`. Este é o teste que fecha a Fase 5 de
   verdade, agora pela API pública.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 985 testes**
- [ ] `grep -c "TODO(phase-5)" lib/src/toolkit.dart` = 0
- [ ] `dart run tool/verovio_cli.dart -r assets/data -o /tmp/d.svg test/corpus/note/note-001.mei`
      produz um SVG, e ele bate estruturalmente com o do C++
- [ ] Um teste varre os 623 arquivos pela API pública (`loadFile` + `renderToSVG`) e compara com os
      goldens; o número de limpos é **≥ o da tarefa 05-25**
- [ ] `getPageCount()` bate com o do C++ para ao menos 20 arquivos multipágina
- [ ] Relatório em `prompts/reports/07-06.md`
- [ ] `PLANO.md`: checkbox de "Toolkit público: load/render" marcado

## Armadilhas conhecidas

- `RenderToSVG` recebe o número de página **1-based**, como o C++.
- `SetOptions` recebe JSON; opções desconhecidas geram aviso, não erro.
- `RedoLayout` refaz o layout preservando (ou não) as quebras, conforme parâmetro.
- `ResetXmlIdSeed` é o que permite reproduzir os ids — o comparador de SVG depende disso.
  Exponha-o e use-o nos testes.
- Se o SVG pela API pública divergir do SVG pelos testes internos da Fase 5, alguma opção default
  está diferente entre os dois caminhos. Ache qual.

## Fora de escopo

- MIDI/timemap/features pela API (tarefa 07-07), editor (07-08).
