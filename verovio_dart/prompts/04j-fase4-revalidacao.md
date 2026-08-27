# 04j — Revalidação da Fase 4

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar a Fase 4: ampliar `tool/validate_layout.dart` para cobrir mais do corpus, medir a melhora
trazida pelas tarefas 04-00 e 04a–04i e produzir o inventário definitivo do que ainda diverge do
C++ — que é a lista de suspeitos que a tarefa 05-12 vai atacar.

Esta tarefa **não produz fixtures novos: ela consome os nove**. Prová-los reprodutíveis depois de
nove tarefas empilhadas é metade do valor dela.

## Pré-condições

Tarefas **04-00** e **04a**–**04i** concluídas.

```bash
# os 9 fixtures da fase (04-00 e 04a-04h) e os 9 patches que os produzem
ls verovio_dart/test/fixtures/cpp/          # 04-00 04a 04b 04c 04d 04e 04f 04g 04h EXEMPLO
ls cpp_probe/patches/*.patch | wc -l        # esperado: 10 (EXEMPLO + 9)

cd verovio_dart
ls lib/src/layout/adjust_layers.dart lib/src/layout/adjust_accid_x.dart \
   lib/src/layout/adjust_artic.dart lib/src/layout/adjust_tuplets.dart \
   lib/src/layout/adjust_beams.dart lib/src/layout/adjust_harm_tempo_syl.dart \
   lib/src/layout/adjust_x_overflow.dart lib/src/layout/cache_horizontal_layout.dart \
   lib/src/layout/calc_spanning_beam_spans.dart lib/src/layout/adjust_ossia_neume.dart \
   lib/src/layout/calc_ledger_lines.dart
dart test 2>&1 | tail -1     # verde, ≥ 344
```

## Referência C++

`origin/src/src/page.cpp:221-247` (`Page::LayOut`), `:396-497` (`LayOutHorizontally`),
`:509-608` (`LayOutVertically`), `:610-633` (`JustifyHorizontally`), `:635-667`
(`JustifyVertically`), `:689-707` (`LayOutPitchPos`).

A sequência completa que o Dart tem de reproduzir, com o que **ainda** falta em negrito:

- **Horizontal**: AdjustOssiaStaffDef → AdjustArtic → AdjustLayers → AdjustDots → AdjustNeumeX →
  AdjustLayers (2ª passada) → AdjustAccidX → AdjustXPos → AdjustGraceXPos → AdjustClefChanges →
  InitProcessingLists → AdjustHarmGrpsSpacing → AdjustArpeg → AdjustTempo → AdjustTupletsX →
  AdjustXOverflow → AlignMeasures → CacheHorizontalLayout
- **Vertical**: ResetVerticalAlignment → CalcLedgerLines → AlignVertically → AdjustArticWithSlurs →
  AdjustBeams → AdjustTupletsY → AdjustSlurs → AdjustTupletWithSlurs → CalcBBoxOverflows →
  AdjustFloatingPositioners → AdjustStaffOverlap → AdjustYPos → AdjustFloatingPositionersBetween →
  AdjustCrossStaffYPos → AlignSystems

## Arquivos Dart a criar/alterar

- **Alterar** `tool/validate_layout.dart` — ampliar a cobertura e a saída.
- **Alterar** `test/horizontal_layout_test.dart` e `test/vertical_layout_test.dart` — acrescentar a
  asserção de que a sequência de functors executada bate com a do `page.cpp`.
- **Criar** `prompts/reports/04j.md` com o inventário de divergências.

## Passo a passo

1. **Amplie `tool/validate_layout.dart`** para varrer **todos os 623** arquivos de `test/corpus/`,
   e não os 46 atuais:
   - skip-list obrigatória: `test/corpus/dir/dir-011.mei` e `dir-012.mei` (não são UTF-8);
   - para cada arquivo: layout completo, asserções estruturais, e comparação de timemap contra
     `../build/verovio -t timemap` quando o C++ conseguir produzir um;
   - o relatório passa a trazer, no topo, **quatro contagens agregadas**: arquivos com layout OK,
     arquivos com todas as asserções estruturais passando, timemaps `match`, timemaps `differ`.
2. Acrescente ao relatório uma seção **"Divergências de timemap"** listando, para cada arquivo que
   diverge, o primeiro `@q` onde diverge e o id da nota — é o material de trabalho da tarefa 05-12.
3. Acrescente uma **asserção de sequência** aos testes de layout: instrumente `Doc` (ou o teste) para
   coletar os nomes dos functors executados na fase horizontal e na vertical, e compare com a lista
   literal do `page.cpp` acima. Assim uma ordem trocada vira teste vermelho, não um mistério numérico.
4. **Regere os nove fixtures do zero e prove que continuam reprodutíveis.** A árvore instrumentada
   acumulada tem todos os patches, então:

   ```bash
   # a partir da RAIZ do workspace
   cpp_probe/build.sh 04h          # aplica EXEMPLO + 04-00 + 04a..04h por cima de origin/ limpo
   git -C . status --short verovio_dart/test/fixtures/cpp/   # antes: limpo

   # regere cada fixture com o mesmo comando que a sua tarefa usou
   # (os comandos literais estão na seção "Dados de referência do C++" de cada prompt)
   ...

   git -C . diff --stat verovio_dart/test/fixtures/cpp/      # depois: tem de sair VAZIO
   ```

   `run.sh` reaproveita a data de `_meta.generated` quando os registros não mudam, então um fixture
   inalterado sai **byte a byte idêntico**. Um `diff` não vazio significa uma de três coisas, e o
   relatório tem de dizer qual: um patch deixou de aplicar, a semente mudou, ou o C++ passou a
   produzir números diferentes (o que seria grave e merece investigação, não um `git checkout`).

5. Rode tudo e registre os números.
6. No relatório, compare com a baseline de 2026-08-26 (46 arquivos, 24/30 timemaps) e diga
   explicitamente **quanto melhorou**. Compare também os dois números que a 04-00 mediu antes de
   qualquer correção: **166 dos 2107 compassos do corpus (7,9%) com o alinhador em `maxTime = 0`**,
   e **8 dos 621 arquivos com duração total 0 apesar de terem música**.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline registrada na tarefa 04i
- [ ] `dart test` verde, **≥ 346 testes**
- [ ] `dart run tool/validate_layout.dart` varre **621 arquivos** (623 menos os 2 não-UTF-8) e o
      relatório informa as quatro contagens agregadas no topo
- [ ] O número de timemaps `match` é **estritamente maior que 24**, e o relatório diz o número exato
- [ ] `tool/LAYOUT_VALIDATION.md` tem a seção "Divergências de timemap" com uma linha por arquivo
      divergente
- [ ] `grep -c "Instance of " tool/LAYOUT_VALIDATION.md` = 0
- [ ] Os testes de layout falham se a ordem dos functors for trocada (prove: inverta dois functors
      temporariamente, mostre o teste vermelho no relatório, desfaça)
- [ ] Os **9** fixtures de `test/fixtures/cpp/` (04-00 e 04a–04h) são regenerados do zero e ficam
      byte a byte idênticos aos versionados — `git diff --stat` vazio, colado no relatório; e o
      relatório traz o **total de valores comparados na Fase 4 e quantos batem**
- [ ] O relatório tem uma seção **"Paridade numérica por tarefa"** consolidando, para cada uma de
      04-00 a 04h, quantos valores do fixture batem com o Dart e quantos não — é o retrato honesto
      de quanto da Fase 4 está de fato equivalente ao C++
- [ ] Relatório em `prompts/reports/04j.md`
- [ ] `PLANO.md`: checkbox "Revalidação da fase com melhora medida" marcado, e o cabeçalho da Fase 4
      atualizado com os números novos

## Armadilhas conhecidas

- Varrer 623 arquivos e chamar o binário C++ para cada um é lento. Rode o C++ em paralelo
  (`Future.wait` com um limite de ~8 processos) ou cacheie os timemaps em `/tmp`. Se passar de
  ~10 minutos, o harness vira inútil na prática.
- Alguns arquivos do corpus (mensural, neume, ligature) não têm timemap comparável; classifique-os
  como `skipped` com o motivo, não como falha.
- A comparação de timemap tem tolerância de 0.01 quarter units e usa as primeiras 40 notas
  compartilhadas. **Não afrouxe isso.** Se quiser mudar, aperte.
- Espere que a maioria das divergências restantes venha das aproximações de bbox
  (`headless_extents.dart`), não dos functors que você acabou de portar. Registrá-las é o ponto
  desta tarefa.
- **Regerar os fixtures leva a primeira compilação inteira** se `build-probe/` não existir (~10 min
  em 4 núcleos). Não confunda isso com lentidão do harness.
- Se um patch não aplicar mais, a causa quase sempre é dois patches disputando a mesma região de
  `page.cpp`. `cpp_probe/patch.sh --list` mostra a pilha e a ordem; conserte o patch, não o `ORDER`.

## Fora de escopo

- Consertar as divergências que dependem de bbox — é a tarefa 05-12.
- Escrever instrumentação nova: esta tarefa **consome** os patches existentes, não os estende.
- Qualquer coisa de renderização.
