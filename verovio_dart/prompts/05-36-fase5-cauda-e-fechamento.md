# 05-36 — A cauda de divergências e o fechamento honesto da Fase 5

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Esta é a 05-25 refeita, com o instrumento consertado e as causas sistemáticas já fora do caminho.
O alvo é o mesmo de sempre: **igualdade numérica exata com o C++ nos 623 arquivos**.

Duas diferenças em relação à 05-25:

1. Os números agora são reais. A 05-25 fechou a fase declarando `489/623` — que eram os 489 arquivos
   em que o harness devolvia o próprio golden. O valor honesto naquele dia era `0/623`.
2. **Esta tarefa pode não fechar a fase.** Se os critérios não forem atingidos, a saída correta é
   escrever a `05-37` com o que sobrou, não declarar a fase pronta. Fechar fase é consequência do
   número, não decisão de quem escreve o relatório.

## Pré-condições

Tarefas **05-26** a **05-35** concluídas.

```bash
cd verovio_dart
grep -rn "as dynamic\|catch (_)\|ignore_for_file" lib/src/rendering/   # nada
ls lib/src/rendering/bbox_fallback.dart                                 # não existe
grep -c "test/golden/cpp/" lib/src/testing/svg_compare.dart             # 0
dart run tool/compare_svg.dart --all --mode=structural                  # anote o ANTES
dart run tool/compare_svg.dart --all --mode=numeric --epsilon=0         # anote o ANTES
```

## Parte 1 — os três arquivos que quebram

`test/corpus/color/color-001.mei`, `test/corpus/ftrem/ftrem-002.mei` e
`test/corpus/symbol/symbol-002.mei` lançam `_TypeError: Null check operator used on a null value`
durante a renderização. Dois deles estavam dentro de diretórios com bridge e por isso apareciam como
limpos até a 05-26.

Cada um é um `!` aplicado a algo que o C++ testa antes de usar. Ache o ponto, leia o C++
correspondente, e porte o teste que ele faz — não troque `!` por `?` para o erro sumir: se o C++
segue adiante com o valor nulo, o Dart tem de seguir também, e se o C++ retorna cedo, o Dart tem de
retornar cedo.

**Nenhum destes três entra em skip-list** (§7.3). A única skip-list legítima continua sendo
`dir/dir-011.mei` e `dir/dir-012.mei`.

## Parte 2 — a caçada

O procedimento é o da 05-25, que estava certo; o que faltou foi executá-lo:

1. Rode os dois modos e **classifique as divergências por causa**, não por arquivo — a tabela de
   classificação é o principal produto da tarefa. Eixos sugeridos: estrutural (falta/sobra `<g>`,
   ordem, `class` errado), numérica pequena (< 1 unidade: arredondamento ou divisão inteira),
   numérica grande (algoritmo errado), só em `<defs>` (glifo não carregado).
2. Ataque as classes na ordem de quantos arquivos cada uma destrava.
3. Para cada causa: reduza a um arquivo mínimo, compare com
   `./build/verovio -r verovio_dart/assets/data -o /tmp/cpp.svg <arquivo>`, ache a função C++, leia-a
   inteira, conserte, meça quanto destravou.
4. **Quando a leitura do `.cpp` não explicar**, instrumente — `00-MESTRE.md` §6-bis. Patch de id
   `05-36` no `ORDER`, só acréscimos, SVG do instrumentado idêntico ao do limpo. A 05-25 pulou esta
   etapa inteira ("o tempo esgotou") e por isso a hipótese dos 88 arquivos de extensor nunca saiu de
   hipótese.

Uma divergência já medida e ainda não explicada, para começar: em
`test/corpus/note/note-001.mei` o acidente sai em `x=2802` no Dart e `x=2859` no C++ — 57 unidades,
com a cabeça da nota em `3026` nos dois lados. É horizontal, é pequena e é sistemática: bom primeiro
alvo, e provável causa comum de uma família inteira.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline (8)
- [ ] `dart test` verde, **nenhum teste em `skip`**
- [ ] `dart run tool/compare_svg.dart --all` reporta **0 falhas** (os três arquivos consertados)
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` ≥ **590 de 623**
- [ ] `dart run tool/compare_svg.dart --all --mode=numeric --epsilon=0` ≥ **400 de 623**
- [ ] Nenhuma tolerância afrouxada, nenhum arquivo acrescentado a skip-list, nenhum teste
      desabilitado para fechar a tarefa
- [ ] O relatório traz a tabela de classificação das divergências por causa, com contagem de
      arquivos por classe, antes e depois
- [ ] O relatório traz **uma entrada por divergência remanescente**, com arquivo, valor do C++,
      valor do Dart e hipótese de causa nomeando função e linha do C++
- [ ] Se instrumentou: patch `05-36` versionado, só acréscimos, `diff` de SVG vazio nos arquivos em
      caça, colado no relatório
- [ ] Relatório em `prompts/reports/05-36.md`

### Só então, o fechamento

- [ ] Se **e somente se** os dois números acima foram atingidos: `PLANO.md` marca a Fase 5 como
      concluída, com os números honestos no cabeçalho e a nota de que a fase foi reaberta em
      2026-08-29 pelas tarefas 05-26..05-36.
- [ ] Se **não** foram atingidos: a Fase 5 **continua aberta**. Escreva `05-37` com a fatia
      restante, nos moldes desta série, e registre no `PLANO.md` o número real com a tarefa que o
      recebe. Entregar a fase aberta com número verdadeiro é resultado; entregá-la fechada com
      número falso é o defeito que originou esta série inteira.

## Armadilhas conhecidas

- **Formatação de número** é a causa mais provável de divergência em massa: `2.0` vs `2`, `0.5` vs
  `.5`, casas decimais. Se muitos arquivos divergem em muitos números por zero, é isso — confira o
  helper de formatação da 05-03 antes de qualquer outra coisa.
- **Divisão inteira**: `~/` trunca para zero, `(a/b).floor()` arredonda para baixo; para negativos
  os dois diferem, e o C++ com `int/int` faz o primeiro.
- **Ordem de emissão**: dois elementos com as mesmas coordenadas em ordem trocada dão divergência
  estrutural. A ordem vem do percurso da árvore.
- Se um arquivo depender de um functor da Fase 6 (`ScoringUpFunctor`, `ConvertToCmnFunctor`,
  `expansion.cpp`) ou de uma opção da Fase 7, isso é **achado**, não fracasso: registre com a tarefa
  que o recebe e siga (§7.2). `test/corpus/expansion/expansion-001.mei` já é um caso conhecido
  (depende de `expansion.cpp:65`, tarefa 06-12).
- Não persiga uma divergência para sempre (§7.2). Mas "documentei e segui" só vale depois de ter
  instrumentado até o nível da expressão — foi exatamente aí que a 05-25 parou cedo.

## Fora de escopo

- MIDI, timemap, transposição, editor (Fase 6).
- Opções do Toolkit (Fase 7): divergência que dependa de opção não portada vira dependência
  registrada, não uma opção portada aqui.
