# 06-01 — resetfunctor.cpp (A): ResetDataFunctor, primeira metade dos Visit*

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Regra de números: critérios medem contra o estado corrente — nunca contra contagem fixa.

## Objetivo

Completar os `Visit*` de `ResetDataFunctor` da primeira metade de `resetfunctor.cpp` em `lib/src/layout/reset_functor.dart`. O reset correto é o que permite relayout e reprocessamento sem estado corrompido — sem ele, a Fase 7 (recarregar, mudar opção) produz lixo.

## Pré-condições

Tarefa **06-00** concluída.

```bash
cd verovio_dart
dart run tool/verify_phases_6_plus.dart --fase=6 --verbose | head -5   # roda e lista critérios
grep -c "class ResetDataFunctor" lib/src/layout/reset_functor.dart      # 1 (a classe existe)
```

## Referência C++

`origin/src/src/resetfunctor.cpp:55-287` — `ResetDataFunctor::Visit*`: `Accid, Arpeg, Artic, Beam,
BeamSpan, Chord, ControlElement, Custos, Div, Dot, Dots, EditorialElement, Ending, F, Flag,
FloatingObject, FTrem, Hairpin, KeySig, Layer` (nominal; confira com
`grep -oP 'ResetDataFunctor::Visit\K\w+' origin/src/src/resetfunctor.cpp`).

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/layout/reset_functor.dart`.
- **Criar/alterar** `test/reset_functor_test.dart`.

## Passo a passo

1. Produza o diff de inventário: `Visit*` do C++ (comando acima) vs `visit*` existentes no Dart — **cole a lista dos faltantes no relatório**.
2. Porte cada `Visit*` faltante do escopo desta tarefa, lendo o corpo no C++ e citando-o no doc comment.
3. Escreva testes: para cada `Visit*` portado, carregar um arquivo do corpus que contenha o elemento, rodar o reset e afirmar que o campo de dados voltou ao estado inicial (ligações, tempos, ids gerados — o que o corpo do C++ limpa).

## Critérios de aceite

- [ ] `dart analyze` — nenhum issue novo fora da baseline corrente
- [ ] `dart test` — verde; nenhum teste que passava falhou; contagem só sobe (anote antes/depois)
- [ ] O diff de inventário do escopo (Accid..Layer) está **vazio** ao final — lista colada no relatório
- [ ] Um teste novo por `Visit*` portado, afirmando o estado resetado
- [ ] `dart run tool/verify_phases_6_plus.dart --fase=6 --verbose` — critério 6.1 lista menos ausentes que na 06-00 (cole a linha)
- [ ] Relatório em `prompts/reports/06-01.md`
- [ ] `PLANO.md`: sufixo de progresso no item de `resetfunctor.cpp`

## Armadilhas conhecidas

- `ResetDataFunctor` reseta estado de *dados*; `ResetHorizontalAlignment`/`ResetVerticalAlignment` (tarefas 06-02/06-03) resetam estado de *layout*. Não misture.
- Alguns `Visit*` no C++ chamam o `Visit` do pai explicitamente antes do próprio corpo. Em Dart os corpos padrão já delegam para cima (00-MESTRE §5a) — chamar de novo reseta duas vezes.
- Se um teste de reset falhar por "valor dobrado", algum campo não foi limpo — é o sintoma clássico.

## Fora de escopo

- `Visit*` de `LayerElement` em diante (tarefa 06-02) e os functors H/V (06-03).
- Qualquer outro functor.
