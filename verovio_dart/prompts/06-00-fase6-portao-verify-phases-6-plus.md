# 06-00 — Portão das Fases 6 e 7: `tool/verify_phases_6_plus.dart`

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.
> Regra de números: nenhum alvo aqui é absoluto — o portão mede contra `origin/` e contra relatórios frescos, nunca contra constante hard-coded.

## Objetivo

Criar o portão mecânico das Fases 6 e 7, no molde de `tool/verify_phases.dart` (Fases 1–5): um CLI Dart que mede cada critério de conclusão contra a árvore e os relatórios gerados por ferramenta — nunca contra checkbox ou relatório escrito à mão — e sai com código ≠ 0 se algo reprovar. O instrumento vem **antes** do resultado: toda tarefa e toda verificação da série 06/07 o invoca.

## Pré-condições

Fases 1–4 fechadas; a Fase 5 foi encerrada pelo dono — não a reabra e não bloqueie por ela.

```bash
cd verovio_dart
dart test 2>&1 | tail -1        # verde (anote a contagem corrente no relatório)
dart analyze 2>&1 | tail -1     # baseline corrente (tool/_scratch_*)
dart run tool/verify_phases.dart --verbose 2>&1 | tail -3   # Fases 1–4 PASS
```

## Referência C++ (contra o que o portão mede)

- Inventários: `origin/src/include/vrv/*.h` (functors, superfícies públicas de `editortoolkit*.h`, `transposition.h`, `toolkit.h`, `options.h`).
- Blocos nominais: `MEIOutput::` em `origin/src/src/iomei.cpp`; `midifunctor.cpp`; `timemap.cpp`; `featureextractor.cpp`; `transposition.cpp`; `transposefunctor.cpp`; `editortoolkit*.cpp`; `this->Register(` em `options.cpp` (contagem dinâmica); `toolkit.cpp`.
- Saídas finais do binário limpo como goldens: `-t mei`, `-t timemap`, `-t midi` (00-MESTRE §3).

## Arquivos Dart a criar/alterar

- **Criar** `tool/verify_phases_6_plus.dart` — copie a arquitetura de `tool/verify_phases.dart` (Criterio/ok/falha/info/checa, `_leRelatorio` com frescor contra `lib/`, `--fase=6|7`, `--verbose`, `--full` para regerar medições caras).

## Critérios que o portão mede (todos dinâmicos)

**Fase 6 — `--fase=6`:**

- **6.1 Inventário de functors** — todo `class XFunctor` dos headers C++ tem contraparte Dart (exclusões legítimas: `ConstFunctor`, `DocConstFunctor`, desvio registrado em `functor.dart`). Alvo: zero ausentes; enquanto a fase está aberta, o portão lista os ausentes e reprova.
- **6.2 MEIOutput — superfície** — `class MeiOutput` existe e todo `MEIOutput::Write*`/`Export`/`Skip` de `iomei.cpp` tem contraparte `write*`/`export`/`skip` (diff de nomes, dinâmico via grep nos dois lados).
- **6.3 MEIOutput — getMEI serializa** — teste de produção existe e passa: carregar MusicXML e chamar `getMEI()` devolve MEI serializado, não o input cru.
- **6.4 Round-trip MEI (golden)** — relatório fresco de `tool/validate_mei.dart` (tarefa 06-21): **todos** os arquivos comparáveis idênticos byte a byte ao `build/verovio -t mei`; toda divergência remanescente precisa de causa nomeada no relatório — divergência sem causa reprova.
- **6.5 Timemap (golden)** — idem via `tool/validate_timemap.dart` (06-38), contra `-t timemap`.
- **6.6 MIDI (golden)** — idem via `tool/validate_midi.dart` (06-41), contra `-t midi`, byte a byte.
- **6.7 Transposição — superfície** — todo método público de `transposition.h` + os 3 functors de `transposefunctor.cpp` têm contraparte (diff dinâmico).
- **6.8 Editor — superfície** — todo método público de `editortoolkit*.h` tem contraparte (diff dinâmico) e os testes de ação por tipo passam.
- **6.9 Features** — `featureextractor.cpp` + `GenerateFeaturesFunctor` portados; a saída não é exposta pelo CLI (só via API) — a paridade usa **fixture cpp_probe** (tarefa 06-42, 00-MESTRE §6-bis).

**Fase 7 — `--fase=7`:**

- **7.1 Opções — registro** — todo `this->Register(` de `options.cpp` tem registro Dart com o mesmo nome e default (dinâmico; o teste da 07-08 confere defaults um a um).
- **7.2 Opções — usage** — paridade da string de uso (`GetOptionUsageString`, 07-11) com a do binário C++.
- **7.3 Toolkit — superfície** — todo método público de `toolkit.h` tem contraparte, exceto as exclusões documentadas (Humdrum/PAE, fora de escopo por decisão do `PLANO.md`) — a lista de exclusões vive num const comentado.
- **7.4 CLI ponta a ponta** — relatório fresco do comparador do `tool/verovio_cli.dart` (07-12): SVG pela API pública idêntico ao caminho interno da Fase 5 para os mesmos arquivos.
- **7.5 Transversal** — `dart analyze` ≤ baseline corrente e `dart test` verde (baseline lida de const datada e justificada, como no portão 1–5).

## Passo a passo

1. Leia `tool/verify_phases.dart` inteiro — o portão novo usa os mesmos helpers e as mesmas regras de frescor de relatório.
2. Implemente os critérios. **Nenhuma contagem hard-coded**: contagens vêm de `grep` sobre `origin/` e `lib/` na execução; alvos vêm dos totais que as ferramentas reportam. A única constante legítima é a baseline de `dart analyze`, com comentário datado.
3. Critérios cujas ferramentas ainda não existem (`validate_mei/timemap/midi`, CLI) **reprovam com "relatório ausente — rode a tarefa X"**. Silêncio nunca é aprovação.
4. Auto-teste de honestidade do próprio portão (prove no relatório): (a) comente um critério → o veredito muda; desfaça; (b) envelheça um relatório (`touch -d '2 days ago' …`) → o frescor reprova; desfaça.
5. Rode `dart run tool/verify_phases_6_plus.dart --fase=6 --verbose`: espera-se **FAIL em quase tudo** (a fase nem começou) — esse é o baseline correto. Cole a saída.

## Critérios de aceite

- [ ] `dart analyze` — nenhum issue novo fora da baseline corrente (anote-a)
- [ ] `dart test` — verde, sem regressão (contagens antes/depois no relatório)
- [ ] `--fase=6 --verbose` roda e reprova listando cada critério — saída colada no relatório
- [ ] `--fase=7 --verbose` idem
- [ ] As duas provas de honestidade do portão passaram e estão documentadas
- [ ] Relatório em `prompts/reports/06-00.md`
- [ ] `PLANO.md`: item do portão na Fase 6 marcado

## Armadilhas conhecidas

- O portão 1–5 já sobreviveu a uma tentativa de adulteração (2026-08-29-08 §3): qualquer alargamento de critério exige justificativa citando C++ e baseline datada. Escreva os critérios já no formato final — sem limiares "temporários".
- O `_leRelatorio` do portão 1–5 reprova relatório mais velho que `lib/` — copie esse comportamento; é o que impede número obsoleto de passar por fresco.
- Não enumere opções/métodos no código do portão: meça com `grep` na execução. Lista hard-coded apodrece.

## Fora de escopo

- Qualquer implementação de port — o portão só mede.
