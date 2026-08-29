# 2026-08-29-07 — Verificação independente da Fase 5

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## O que esta tarefa é

A mesma auditoria adversarial da `06`, aplicada à fase que **já foi declarada pronta uma vez sem
estar**. Rode-a depois que a `05-36` (ou a `05-37`, se ela existir) disser que fechou.

Você não escreve código de produção. Achado vira linha de relatório e prompt novo.

## O histórico que você precisa conhecer antes de acreditar em qualquer número

Em 2026-08-29 a Fase 5 foi fechada com `489/623` arquivos limpos. A auditoria descobriu que o
harness devolvia o próprio golden para 489 arquivos: o valor honesto era `0/623`
(`prompts/reports/05-26.md`). O instrumento foi consertado, `test/harness_integrity_test.dart`
passou a guardar contra a reintrodução, e a série `05-27`..`05-36` reconstruiu a fase.

Sua primeira obrigação é **verificar o instrumento antes do resultado**.

## Passo 1 — o harness não está mentindo

Três verificações, nesta ordem. Se qualquer uma falhar, pare: o resto dos números não significa nada.

```bash
cd verovio_dart
# 1. o harness não lê os goldens
grep -rn "test/golden/cpp" lib/src/testing/svg_compare.dart     # esperado: nada
grep -rn "golden" lib/src/testing/svg_compare.dart              # examine cada ocorrência

# 2. o guarda existe e passa
dart test test/harness_integrity_test.dart

# 3. prova viva: um arquivo que o C++ e o Dart renderizam diferente TEM de acusar divergência
dart run tool/compare_svg.dart test/corpus/dir/dir-001.mei
```

Depois, a prova por mutação — a mais importante:

1. pegue um arquivo que o relatório diz estar **limpo**;
2. edite o golden dele em `test/golden/cpp/**.svg`, mudando **um** número (ex.: um `x="123"` para
   `x="124"`);
3. rode o comparador só naquele arquivo: ele **tem** de acusar divergência;
4. `git checkout -- test/golden/cpp/` para desfazer.

Se um golden alterado continuar "limpo", o harness está devolvendo o golden de novo. Isso é o
defeito mais grave possível nesta fase — reprove imediatamente e escreva o prompt de conserto.

## Passo 2 — o portão mecânico

```bash
dart run tool/verify_phases.dart --fase=5 --verbose
```

Os critérios 5.1/5.2/5.3 (`as dynamic`, `catch (_)`, `ignore_for_file` em `lib/src/rendering/`) são
os que separam "renderiza errado" de "nunca executou". Enquanto qualquer um deles falhar, o número
de divergências **não é interpretável**: cada membro de modelo faltante vira um ramo de desenho
pulado em silêncio.

O critério 5.6 exige `621/623` nos dois modos (623 menos os 2 não-UTF-8) e **zero** exceções.

Confira também que o portão não foi adulterado (Passo 2 da `06`, mesmas regras).

## Passo 3 — a medição é fresca e é sua

Não confie em `tool/SVG_VALIDATION.md` como estava. Regere:

```bash
dart run tool/compare_svg.dart --all
```

Compare com o que o relatório da `05-36` afirma. **Divergência entre o relatório e a sua medição é
um achado**, e dos graves: significa que o relatório foi escrito contra outro estado da árvore.

Baseline de 2026-08-29, para você saber se subiu ou desceu: **115/623 estrutural, 4/623 numérico,
3 exceções** (`ftrem/ftrem-002.mei`, `stem/stem-014.mei`, `stem/stem-016.mei`).

## Passo 4 — a fidelidade é real, não estatística

`621/623` estrutural pode ser alcançado com sorte em famílias fáceis. Amostre por família, com o
`compare_svg` por diretório, e confira que as **difíceis** viraram:

| Família | struct em 2026-08-29 |
|---|---|
| `ligature` | 0/50 |
| `mensural` | 0/25 |
| `tuplet` | 0/22 |
| `lyric` | 0/16 |
| `dir` | 0/12 |
| `dynam` | 0/10 |

Se a média subiu mas `ligature/` e `mensural/` continuam em zero, a fase não fechou — essas duas
dependem de `view_mensural.dart`, que tinha a maior densidade de `catch (_)` por linha do projeto.

Depois, escolha **três** arquivos limpos ao acaso, de famílias diferentes, e faça a comparação
"olho no olho": abra o SVG do Dart e o golden lado a lado e confira que os dois desenham a mesma
música. Um comparador estrutural pode considerar limpos dois arquivos que desenham coisas
diferentes se a divergência estiver fora do que ele inspeciona.

## Passo 5 — os testes de renderização mordem

A `05-33` substituiu 53 asserções que faziam `grep` no próprio fonte por catracas por família. Elas
só valem se apertarem. Para cada `test/view_*_test.dart`:

1. confirme que **nenhuma** asserção lê arquivo sob `lib/`
   (`grep -rn "readAsStringSync\|File(" test/view_*_test.dart` — cada ocorrência tem de apontar para
   `test/corpus` ou `test/golden`, nunca para `lib/`);
2. confirme que a catraca da família é asserção dura, não `skip`;
3. prova de mordida: quebre uma decisão de desenho em `lib/src/rendering/` (troque um glifo SMuFL,
   inverta uma direção de haste) e confirme que a catraca daquela família fica vermelha. Desfaça.

Liste família × mutação × ficou vermelha (sim/não).

## Passo 6 — sem regressão fora da fase

```bash
dart analyze                          # ≤ 8, sem supressão nova em lib/src/rendering/
dart test                             # verde, 0 falhas, nenhum skip novo
dart run tool/validate_layout.dart    # ≥ 618/621 layout OK, ≥ 173 timemaps
dart run tool/verify_phases.dart      # todas as fases
```

## O veredito

`prompts/reports/2026-08-29-07.md`, nesta ordem:

1. **Fase 5 — FECHADA** ou **ABERTA: `<motivo em uma frase>`**.
2. Resultado do Passo 1, com destaque para a prova por mutação do golden.
3. Saída de `verify_phases.dart --fase=5 --verbose` e a sua medição fresca do corpus.
4. A tabela por família, antes (2026-08-29) × agora.
5. A tabela de provas de mordida.
6. Achados, com arquivo/linha/C++ vs Dart.
7. Se ficou aberta: o prompt que a fecha (`05-37`, `05-38`, …), gravado e linkado no `README.md`.

### A regra que não se negocia

**Fechar fase é consequência do número, não decisão de quem escreve o relatório.** E nesta fase, em
particular: se o Passo 1 não passar, nada mais importa. Foi um instrumento quebrado que produziu
`489/623` da primeira vez.

## Fora de escopo

- Fases 1 a 4 (é a `06`).
- Escrever código de produção.
- Fase 6 e 7.
