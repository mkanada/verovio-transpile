# 06-03 — resetfunctor.cpp (C): Reset H/V e o teste de idempotência de ciclo

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Regra de números: critérios medem contra o estado corrente — nunca contra contagem fixa.

## Objetivo

Completar `ResetHorizontalAlignmentFunctor` e `ResetVerticalAlignmentFunctor` e entregar o **teste de idempotência de ciclo** — o valor real de todo o bloco de reset: carregar, layout, resetar, layout de novo, e o SVG tem de ser idêntico ao da primeira vez.

## Pré-condições

Tarefas **06-01** e **06-02** concluídas.

```bash
cd verovio_dart
grep -rn "class ResetHorizontalAlignmentFunctor\|class ResetVerticalAlignmentFunctor" lib/src/   # onde vivem
dart test test/reset_functor_test.dart 2>&1 | tail -1    # verde
```

## Referência C++

`origin/src/src/resetfunctor.cpp:564-806` (`ResetHorizontalAlignmentFunctor`: `Accid, Arpeg, Beam,
BeamSpan, Custos, Div, Dot, Dots, FloatingObject, Layer, LayerElement, Measure, MRest, Note,
Ossia, Proport, Rest, ScoreDef, System, Tuplet, TupletBracket, TupletNum`) e `:806-907`
(`ResetVerticalAlignmentFunctor`: `Artic, FloatingObject, LayerElement, Octave, Page, Staff,
System, TextElement, Tuplet, TupletBracket`).

## Arquivos Dart a criar/alterar

- **Alterar** os arquivos Dart dos dois functors (localize com o grep da pré-condição).
- **Criar** `test/reset_cycle_test.dart` — o teste de idempotência.

## Passo a passo

1. Diff de inventário para os dois functors — cole os faltantes.
2. Porte os `Visit*` faltantes.
3. **Teste de idempotência**: para cada família do corpus (um arquivo por diretório de `test/corpus/`), carregar → `prepareData` + `layOut` → renderizar via `renderSvgForComparison` → resetar (os três functors, na ordem em que o C++ os chama — veja `doc.cpp`/`toolkit.cpp`) → layout de novo → renderizar → **igualdade exata de string** entre os dois SVG. A lista de famílias é dinâmica: um arquivo por diretório que existir sob `test/corpus/`.
4. Verificação.

## Critérios de aceite

- [ ] `dart analyze` — nenhum issue novo fora da baseline corrente
- [ ] `dart test` — verde, sem regressão, contagem só sobe
- [ ] Diff de inventário dos dois functors **vazio** — colado no relatório
- [ ] O teste de idempotência passa para **todas as famílias** do corpus (uma por diretório, dinâmico) por igualdade exata de string; o relatório lista família × resultado
- [ ] `verify_phases_6_plus --fase=6` — nenhum `Reset*Functor` em 6.1 (cole a linha)
- [ ] Relatório em `prompts/reports/06-03.md`
- [ ] `PLANO.md`: checkbox de `resetfunctor.cpp` marcado (última tarefa do item)

## Armadilhas conhecidas

- O teste de idempotência é o que revela reset incompleto: campo não resetado aparece como coordenada acumulada — procure por valores que dobram.
- H/V resetam estado de *layout*, não de dados (00-MESTRE e 06-01).
- A ordem dos três resets importa: copie a do C++ (`ResetData` → H → V, ou como `doc.cpp` encadeia).

## Fora de escopo

- `findfunctor.cpp` (06-04/06-05).
