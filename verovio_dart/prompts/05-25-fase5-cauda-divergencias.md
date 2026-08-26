# 05-25 — Fase 5: perseguir a cauda de divergências até a igualdade numérica

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar a Fase 5: com todos os `view*.cpp` portados, atacar sistematicamente os arquivos do corpus
que ainda divergem do C++, até chegar o mais perto possível de **igualdade numérica exata nos 623
arquivos** — e documentar, com hipótese de causa, cada divergência que sobrar.

**Esta tarefa é diferente das outras: ela não porta um arquivo, ela investiga.** Espere gastar a
maior parte do tempo lendo o C++ e comparando números, não escrevendo código novo.

## Pré-condições

Tarefa **05-24** concluída.

```bash
cd verovio_dart
grep -rn "_notYet(" lib/src/rendering/ | wc -l     # 0
grep -rn "Approximation:" lib/src/ | wc -l         # 0
ls lib/src/rendering/headless_extents.dart 2>&1 | grep -qi "no such\|inexistente" && echo "OK"
dart test 2>&1 | tail -1                            # verde, ≥ 574
dart run tool/compare_svg.dart --all                # anote os números ANTES
```

## Referência C++

Todos os `origin/src/src/view*.cpp`, `svgdevicecontext.cpp`, e — conforme a investigação apontar —
os functors de layout em `origin/src/src/*functor.cpp`. O binário `build/verovio` é o oráculo
para qualquer número.

## Arquivos Dart a criar/alterar

Qualquer arquivo de `lib/src/` que a investigação indicar. Também:

- **Alterar** `test/svg_golden_test.dart` — subir o número de arquivos limpos esperados.
- **Alterar** `tool/compare_svg.dart` se o relatório precisar de mais detalhe para a caçada.

## Passo a passo

1. Rode `dart run tool/compare_svg.dart --all --mode=structural` e
   `--mode=numeric --epsilon=0`. Grave os dois relatórios.
2. **Classifique** as divergências por causa provável, não por arquivo. Sugestão de eixos:
   - divergência **estrutural** (falta um `<g>`, sobra um, ordem trocada, `class` errado);
   - divergência **numérica pequena** (< 1 unidade) — quase sempre arredondamento ou divisão inteira;
   - divergência **numérica grande** — algoritmo errado ou functor faltando;
   - divergência **só em `<defs>`** — carregamento de glifo.
   Ponha essa classificação no relatório, com a contagem de arquivos em cada classe. **Essa tabela
   é o principal produto desta tarefa.**
3. Ataque as classes em ordem de quantos arquivos cada uma destrava. Para cada causa:
   - reduza a um arquivo mínimo do corpus;
   - compare com `./build/verovio -r verovio_dart/assets/data -o /tmp/cpp.svg <arquivo>`;
   - ache a função C++ responsável e leia-a de novo;
   - conserte;
   - rode `--all` de novo e registre quantos arquivos a correção destravou.
4. Repita até esgotar o tempo razoável ou zerar.
5. Para o que sobrar, escreva no relatório **uma entrada por divergência**, com: arquivo, o que
   diverge, valor do C++, valor do Dart, e **hipótese de causa nomeando função e linha do C++**.
6. Atualize `test/svg_golden_test.dart` com a contagem nova.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, sem nenhum teste em `skip`
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` reporta **≥ 590 de 623** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=numeric --epsilon=0` reporta **≥ 400 de 623** limpos
- [ ] `test/svg_golden_test.dart` afirma a contagem nova (não a antiga)
- [ ] O relatório traz a tabela de classificação de divergências por causa, com contagem
- [ ] O relatório traz uma entrada por divergência remanescente, com hipótese de causa nomeando
      função e linha do C++
- [ ] Nenhuma tolerância foi afrouxada e nenhum arquivo foi acrescentado a skip-list para fechar a
      tarefa (a única skip-list legítima continua sendo `dir-011.mei` e `dir-012.mei`)
- [ ] Relatório em `prompts/reports/05-25.md`
- [ ] `PLANO.md`: Fase 5 inteira marcada, com os números finais no cabeçalho da fase

## Armadilhas conhecidas

- **Formatação de número** é a causa mais provável de divergência em massa: `2.0` vs `2`,
  `0.5` vs `.5`, número de casas decimais. Se muitos arquivos divergem em muitos números por um
  valor de zero, é isso. Verifique o helper de formatação da tarefa 05-03 antes de tudo.
- **Divisão inteira**: procure `/` onde o C++ tem `int / int`. Em Dart é `~/`, e para negativos
  `~/` (trunca) difere de `(a/b).floor()`.
- **Ordem de emissão**: dois elementos com as mesmas coordenadas mas em ordem trocada no SVG dão
  divergência estrutural. A ordem vem da ordem de percurso da árvore.
- **Sufixo de id**: se de repente tudo divergir, verifique se a normalização do comparador ainda
  funciona depois das mudanças.
- Se um arquivo diverge por um functor de layout faltando, isso é **um achado**, não um fracasso:
  registre qual, porque pode ser da Fase 6 (`ScoringUpFunctor`, `ConvertToCmnFunctor`).
- Não persiga uma divergência para sempre. A política da seção 7 do `00-MESTRE.md` vale: documente
  e siga.

## Fora de escopo

- MIDI, timemap, transposição, editor (Fase 6).
- Opções do Toolkit (Fase 7) — se uma divergência depender de uma opção não portada, registre-a
  como dependência da Fase 7 em vez de portar a opção aqui.
