# 04g — AdjustOssiaStaffDefFunctor + AdjustNeumeXFunctor + CalcLedgerLinesFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os três functors restantes das fases horizontal e vertical: ajuste do `staffDef` de ossia,
espaçamento X de neumas e cálculo das linhas suplementares (ledger lines).

## Pré-condições

Tarefas **04a**–**04f** concluídas.

```bash
cd verovio_dart
ls lib/src/layout/adjust_x_overflow.dart lib/src/layout/calc_spanning_beam_spans.dart
dart test 2>&1 | tail -1     # verde, ≥ 292
```

## Referência C++

| Arquivo | Linhas | Visits |
|---|---:|---|
| `origin/src/src/adjustossiastaffdeffunctor.cpp` | 106 | `VisitAlignment`, `VisitLayerElement`, `VisitMeasure`, `VisitMeasureEnd`, `VisitStaff` |
| `origin/src/src/adjustneumexfunctor.cpp` | 102 | `VisitLayer`, `VisitLayerEnd`, `VisitStaff`, `VisitNeume`, `VisitSyl` |
| `origin/src/src/calcledgerlinesfunctor.cpp` | 191 | `VisitAccid`, `VisitNote`, `VisitStaffEnd` |
| `origin/src/src/page.cpp:396-497` | — | `AdjustOssiaStaffDef` (primeiro da fase horizontal) e `AdjustNeumeX` |
| `origin/src/src/page.cpp:509-608` | — | `CalcLedgerLines` (logo depois de `ResetVerticalAlignment`) |
| `origin/src/src/page.cpp:689-707` | — | `Page::LayOutPitchPos` — `CalcLedgerLines` roda **também** aqui |

`CalcLedgerLinesFunctor` acumula em `Staff` e materializa em `VisitStaffEnd`; leia
`Staff::AddLedgerLineAbove/Below` em `origin/src/src/staff.cpp` e confirme o que existe em Dart:

```bash
grep -n "ledgerLine\|LedgerLine" lib/src/model/basic_elements.dart | head -20
```

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/adjust_ossia_neume.dart` — `AdjustOssiaStaffDefFunctor` e
  `AdjustNeumeXFunctor`.
- **Criar** `lib/src/layout/calc_ledger_lines.dart` — `CalcLedgerLinesFunctor`.
- **Alterar** o arquivo de `Staff` para os acumuladores de ledger line, se faltarem.
- **Alterar** `lib/src/model/doc.dart` — ligar os três; **remover** o comentário
  `// Deviation: CalcLedgerLinesFunctor arrives with the rendering phase.` em `:473` e a menção
  em `:464`; atualizar `:296` e `:1254` (nota de ossia).
- **Alterar** `lib/src/layout/align_horizontally.dart:669` e `:187` — os `TODO(phase-5+)` sobre ossia.
- **Criar** `test/adjust_ossia_neume_test.dart` e `test/calc_ledger_lines_test.dart`.

## Passo a passo

1. Leia os três `.h` e os três `.cpp`.
2. Leia `Staff::AddLedgerLineAbove`/`Below` e `Staff::ResetLedgerLines` no C++, e confira o estado
   equivalente na classe `Staff` em Dart. Acrescente o que faltar.
3. Porte os três functors.
4. Ligue no `doc.dart` nas **três** posições (`LayOutHorizontally`, `LayOutVertically`,
   `LayOutPitchPos`).
5. Testes: `test/corpus/ossia/` (4 arquivos), `test/corpus/neume/` (6),
   `test/corpus/note/` para ledger lines (uma nota bem acima e outra bem abaixo do pentagrama).
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 298 testes**
- [ ] `grep -c "class CalcLedgerLinesFunctor" lib/src/layout/calc_ledger_lines.dart` = 1
- [ ] `grep -c "Deviation: CalcLedgerLinesFunctor arrives" lib/src/model/doc.dart` = 0
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.`, timemaps **≥ 24/30**, e
      `ossia/ossia-001.mei` + `neume/neume-001.mei` continuam com `Layout OK`
- [ ] Relatório em `prompts/reports/04g.md`
- [ ] `PLANO.md`: os três nomes removidos da lista de faltantes

## Armadilhas conhecidas

- `CalcLedgerLines` roda **duas vezes** no C++ (fase vertical e `LayOutPitchPos`). Ligar em só um
  lugar deixa metade dos casos errada.
- Largura da linha suplementar depende da largura da cabeça de nota, que vem das métricas de glifo
  (`Resources`). Isso **existe** em Dart (`lib/src/rendering/resources.dart`) — use as métricas
  reais, não uma constante. Lembre de `Resources.defaultPath = 'assets/data';` nos testes.
- `AdjustNeumeXFunctor` só faz sentido em documentos neumáticos; nos 6 arquivos de
  `test/corpus/neume/` a largura de sistema hoje sai `w=0` no relatório de layout — isso é estado
  conhecido, não regressão sua.
- Ossia: `align_horizontally.dart` tem dois `TODO` dizendo que ossia chega depois. Esta é a tarefa;
  atualize os comentários em vez de deixá-los mentindo.

## Fora de escopo

- Desenhar as linhas suplementares (`View::DrawLedgerLines`, tarefa 05-11).
- `ScoreDefSetOssiaFunctor` (tarefa 04h).
