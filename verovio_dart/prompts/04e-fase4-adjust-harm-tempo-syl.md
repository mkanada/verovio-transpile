# 04e — AdjustHarmGrpsSpacingFunctor + AdjustTempoFunctor + AdjustSylSpacingFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os três ajustes horizontais dirigidos por texto: espaçamento entre grupos de cifras
(`harm`), posicionamento de indicações de andamento (`tempo`) e espaçamento de sílabas de letra
(`syl`/`verse`) — este último via `Page::AdjustSylSpacingByVerse`.

## Pré-condições

Tarefas **04a**–**04d** concluídas.

```bash
cd verovio_dart
ls lib/src/layout/adjust_beams.dart
dart test 2>&1 | tail -1     # verde, ≥ 283
```

## Referência C++

| Arquivo | Linhas | Visits |
|---|---:|---|
| `origin/src/src/adjustharmgrpsspacingfunctor.cpp` | 222 | `VisitHarm`, `VisitMeasureEnd`, `VisitSystem`, `VisitSystemEnd` |
| `origin/src/src/adjusttempofunctor.cpp` | 71 | `VisitSystem`, `VisitTempo` |
| `origin/src/src/adjustsylspacingfunctor.cpp` | 206 | `VisitMeasureEnd`, `VisitStaff`, `VisitSystem`, `VisitSystemEnd`, `VisitVerse` |
| `origin/src/src/page.cpp:756-…` | — | `Page::AdjustSylSpacingByVerse(const IntTree &verseTree, Doc *doc)` — chamada de dentro do `AdjustSylSpacingFunctor` |
| `origin/src/src/page.cpp:396-497` | — | posição dos três na fase horizontal |

Headers correspondentes em `origin/src/include/vrv/` com o mesmo nome.
`AdjustHarmGrpsSpacingFunctor` e `AdjustSylSpacingFunctor` dependem de
`InitProcessingListsFunctor`, que **já existe** em Dart (`lib/src/layout/`) — confirme com
`grep -rn "class InitProcessingListsFunctor" lib/src/`, e veja que estrutura de `IntTree` ele produz.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/adjust_harm_tempo_syl.dart` — os três functors.
- **Alterar** `lib/src/model/doc.dart` — ligar os três na fase horizontal, depois de
  `InitProcessingLists`, na ordem do `page.cpp`; atualizar os comentários de "skipped" em
  `:297-298` e `:342-344`.
- **Alterar** o arquivo onde vive `Page` (`lib/src/model/system_page_elements.dart`) — acrescentar
  `adjustSylSpacingByVerse`.
- **Criar** `test/adjust_harm_tempo_syl_test.dart`.

## Passo a passo

1. Leia os três `.cpp` e os três `.h`.
2. Leia `Page::AdjustSylSpacingByVerse` em `page.cpp:756` até o fim da função.
3. Confirme a forma do `IntTree` produzido por `InitProcessingListsFunctor` no Dart existente.
4. Porte os três functors + `Page.adjustSylSpacingByVerse`.
5. Ligue no `doc.dart`.
6. Testes: `test/corpus/harm/` (5 arquivos), `test/corpus/tempo/` (4), `test/corpus/lyric/` (16).
   **`lyric/lyric-001.mei` é um dos dois arquivos cujo timemap hoje diverge do C++** — verifique
   se esta tarefa o conserta e registre o resultado no relatório de qualquer jeito.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 288 testes**
- [ ] `grep -c "^class Adjust" lib/src/layout/adjust_harm_tempo_syl.dart` = 3
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.` e timemaps **≥ 24/30**
- [ ] O relatório diz explicitamente se `lyric/lyric-001.mei` passou de
      `6/10 differ @q=4.50` para `match`, e se não passou, a hipótese de causa
- [ ] Relatório em `prompts/reports/04e.md`
- [ ] `PLANO.md`: os três nomes removidos da lista de faltantes

## Armadilhas conhecidas

- Extensões de texto vêm de `headless_extents.dart:593` e `:658`, que **estimam** com Times a ~60%
  da fonte de música. Os três functors desta tarefa dependem inteiramente de largura de texto, então
  os números **não vão bater** com o C++ até a tarefa 05-12. Isto é esperado: porte a lógica correta
  e documente a divergência numérica.
- `AdjustSylSpacingFunctor` acumula por verso e só age no `VisitSystemEnd`. Ordem de acumulação importa.
- `AdjustHarmGrpsSpacingFunctor` agrupa por `@n` do `harm`; grupos diferentes não interagem.
- `IntTree` não é um `Map` simples — reproduza a estrutura aninhada do C++.

## Fora de escopo

- Consertar `headless_extents.dart` (tarefa 05-12).
- `view_text.cpp` (tarefa 05-19).
