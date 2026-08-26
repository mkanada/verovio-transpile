# 06-07 — miscfunctor.cpp, functors de transcrição e fac-símile

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `ApplyPPUFactorFunctor`, `ReorderByXPosFunctor`, `AdjustXRelForTranscriptionFunctor`,
`AdjustYRelForTranscriptionFunctor`, o `Page::LayOutTranscription` que os usa, e o suporte a
fac-símile (`facsimile.cpp` + os dois functors de sincronização) — o caminho de layout inteiro para
documentos de transcrição com coordenadas de fac-símile.

## Pré-condições

Tarefa **06-06** concluída.

```bash
cd verovio_dart
ls lib/src/layout/convert_to_mensural_view.dart
grep -n "TODO(phase-4): ApplyPPUFactorFunctor" lib/src/io/mei_input.dart   # linha 884
dart test 2>&1 | tail -1     # verde, ≥ 636
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/include/vrv/miscfunctor.h` | — | `ApplyPPUFactorFunctor`, `ReorderByXPosFunctor` |
| `origin/src/src/miscfunctor.cpp` | 185 | as duas |
| `origin/src/src/adjustxrelfortranscriptionfunctor.cpp` | 35 | `AdjustXRelForTranscriptionFunctor` |
| `origin/src/src/adjustyrelfortranscriptionfunctor.cpp` | 35 | `AdjustYRelForTranscriptionFunctor` |
| `origin/src/src/page.cpp:249-317` | — | `Page::LayOutTranscription(bool force)` — a sequência inteira, incluindo o `BBoxDeviceContext` da linha 301 em modo `BBOX_HORIZONTAL_ONLY` |
| `origin/src/src/facsimile.cpp` | 108 | funções livres de suporte a fac-símile |
| `origin/src/include/vrv/facsimilefunctor.h` | — | `SyncFromFacsimileFunctor`, `SyncToFacsimileFunctor` |
| `origin/src/src/facsimilefunctor.cpp` | — | as duas |
| `origin/src/src/doc.cpp` | — | `Doc::SyncFromFacsimileDoc`, `Doc::SyncToFacsimileDoc` (`grep -n "SyncFromFacsimile\|SyncToFacsimile" origin/src/src/doc.cpp`) |

Em Dart já existem `lib/src/model/zone.dart`, `FacsimileInterface`
(`lib/src/model/interfaces/facsimile_interface.dart`) e `PrepareFacsimileFunctor`.
`mei_input.dart:599` tem um comentário dizendo que a sincronização chega depois — esta é a tarefa.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/misc_functors.dart` — `ApplyPPUFactorFunctor`, `ReorderByXPosFunctor`.
- **Criar** `lib/src/layout/adjust_transcription.dart` — os dois functors de transcrição.
- **Criar** `lib/src/layout/facsimile_functors.dart` — `SyncFromFacsimileFunctor`, `SyncToFacsimileFunctor`.
- **Alterar** `lib/src/model/doc.dart` — `syncFromFacsimileDoc`, `syncToFacsimileDoc`; e
  `lib/src/io/mei_input.dart:599` — atualizar/remover o comentário sobre a sincronização.
- **Alterar** `lib/src/model/system_page_elements.dart` — `Page.layOutTranscription`.
- **Alterar** `lib/src/io/mei_input.dart:884` — apagar o `TODO(phase-4): ApplyPPUFactorFunctor` e
  ligar o functor.
- **Criar** `test/transcription_test.dart`.

## Passo a passo

1. Leia os quatro `.cpp` e `Page::LayOutTranscription` inteiro.
2. Porte os quatro functors.
3. Porte `Page.layOutTranscription`, reproduzindo o fluxo `View` + `BBoxDeviceContext` da linha 301
   exatamente como a tarefa 05-12 fez para as linhas 410 e 532.
4. Ligue `ApplyPPUFactorFunctor` em `mei_input.dart:884`.
5. Porte `facsimile.cpp` e os dois functors de sincronização, mais os dois métodos do `Doc`.
6. Testes: arquivos com fac-símile — encontre-os com
   `grep -l "<facsimile" test/corpus/**/*.mei`. Se o corpus não tiver nenhum, **diga isso no
   relatório** e construa um caso mínimo à mão em `test/`, documentando que o corpus não cobre.
   Teste chave: `syncFromFacsimile` seguido de `syncToFacsimile` tem de devolver as **mesmas**
   coordenadas de zona.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 652 testes**
- [ ] `grep -c "TODO(phase-4): ApplyPPUFactorFunctor" lib/src/io/mei_input.dart` = 0
- [ ] Os 4 functors existem, cada um com `class …Functor` e doc comment citando o C++
- [ ] `Page.layOutTranscription` usa `BBoxDeviceContext` em modo `BBOX_HORIZONTAL_ONLY`, como o
      `page.cpp:301` — prove citando o trecho no relatório
- [ ] `grep -c "class SyncFromFacsimileFunctor\|class SyncToFacsimileFunctor" lib/src/layout/facsimile_functors.dart` = 2
- [ ] O teste de ida e volta (`syncFrom` → `syncTo`) devolve coordenadas idênticas
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/06-07.md`
- [ ] `PLANO.md`: checkbox de `miscfunctor.cpp`, dos functors de transcrição e de `facsimile.cpp` marcados

## Armadilhas conhecidas

- `ApplyPPUFactorFunctor` reescala **todo** o documento; rodá-lo duas vezes escala duas vezes.
  O C++ o chama num ponto só. Confira qual.
- `ReorderByXPosFunctor` reordena filhos na árvore por posição X — muda a ordem de emissão do SVG.
  Se o corpus regredir depois desta tarefa, é o suspeito.
- Transcrição usa coordenadas absolutas do fac-símile; o layout normal é pulado. Não misture os
  dois caminhos.
- `mei_input.dart:2140` tem um `TODO(phase-4): also hide when GetOriginalStaffForOssia fails` —
  não é desta tarefa, mas anote no relatório se ainda estiver lá.
- `SyncFromFacsimile` sobrescreve as coordenadas de desenho calculadas pelo layout. Rodá-lo num
  documento sem fac-símile zera tudo. O C++ tem uma guarda; porte-a.
- As coordenadas de fac-símile são em unidades da imagem, não do documento; o fator de escala é o
  do `ApplyPPUFactorFunctor` desta mesma tarefa.
- `Zone` já existe (`lib/src/model/zone.dart`); não o recrie.

## Fora de escopo

- `expansion.cpp` e seleção (tarefa 06-12).
