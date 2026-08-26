# 05-00 — Harness de comparação de SVG

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Criar o instrumento de medição da Fase 5 inteira: `tool/compare_svg.dart` e
`test/svg_golden_test.dart`, que comparam o SVG produzido pelo Dart com os 623 goldens de
`test/golden/cpp/**.svg` em dois modos — **estrutural** e **numérico** — e emitem um relatório
markdown agregado. Enquanto não houver renderização, o harness roda contra um stub e reporta
**0/623**: esse é o baseline correto, e é a métrica que todas as tarefas seguintes sobem.

**Esta é a primeira tarefa da Fase 5. Nada de `View` aqui.**

## Pré-condições

Tarefa **04j** concluída.

```bash
cd verovio_dart
dart test 2>&1 | tail -1                          # verde, ≥ 308
find test/golden/cpp -name '*.svg' | wc -l        # esperado: 623
find test/corpus -name '*.mei' | wc -l            # esperado: 623
head -3 test/golden/cpp/note/note-001.svg
```

## Referência C++

Você não porta C++ nesta tarefa, mas precisa entender **o que** vai comparar. Leia:

| Arquivo | Para quê |
|---|---|
| `origin/src/src/svgdevicecontext.cpp` | a forma exata do SVG que o C++ emite. Métodos-chave: `StartPage` (raiz `<svg>`, `<desc>`, `<defs>`), `StartGraphic`/`EndGraphic` (os `<g>` com `id` e `class`), `AppendIdAndClass`, `InsertGlyphRef` (os `<g id="E050-xxxx">` dentro de `<defs>`), `GetStringSVG`, `Commit`. |
| `tool/golden.sh` | como os goldens foram gerados: `verovio -r assets/data -o <svg> <mei>`, **sem nenhuma outra opção** — ou seja, todos os defaults do C++. |
| `test/golden/cpp/note/note-001.svg` | um exemplo real, para ver a estrutura. |

Observação crítica sobre **ids**: o C++ gera um sufixo aleatório por documento
(`id="o3u8kcw"`, `id="E050-o3u8kcw"`), semeado por `m_xmlIdSeed`. O comparador **tem de normalizar
esse sufixo** antes de comparar — senão nenhum arquivo bate nunca. Procure como o C++ o produz
(`grep -rn "xmlIdSeed\|GenerateHashID\|Object::GenerateID" origin/src/src/`) e decida:
normalizar (recomendado para o modo estrutural) ou fixar a semente (necessário no fim, para
igualdade byte a byte).

## Arquivos Dart a criar/alterar

- **Criar** `tool/compare_svg.dart` — a ferramenta de linha de comando.
- **Criar** `lib/src/testing/svg_compare.dart` — a lógica de comparação, reutilizável pelo teste.
  (Diretório novo `lib/src/testing/`; é código de apoio ao port, não port do C++ — documente isso
  no cabeçalho do arquivo.)
- **Criar** `test/svg_golden_test.dart`.
- **Criar** `tool/SVG_VALIDATION.md` (gerado pela tool; não escreva à mão).

## Passo a passo

1. **Defina a fonte do SVG do Dart** através de um único ponto de entrada:
   ```dart
   String? renderSvgForComparison(String meiPath);   // null enquanto não houver renderização
   ```
   Hoje ele devolve `null` (stub). A tarefa 05-12 e as seguintes o ligam ao `View` real. Deixe isso
   explícito num doc comment: **este é o gancho que a Fase 5 vai preencher.**
2. **Modo estrutural.** Parseie os dois SVGs com `package:xml` e compare:
   - a mesma árvore de elementos, na mesma ordem (nome do elemento, profundidade, número de filhos);
   - os mesmos atributos `class`;
   - os mesmos atributos `id`, **depois de normalizar o sufixo aleatório do documento**;
   - o mesmo conjunto de referências de glifo em `<defs>`.
   **Não** compare coordenadas neste modo.
   Saída: lista de divergências com o caminho XPath-like até o nó (`svg/g[0]/g[2]/path[1]`).
3. **Modo numérico.** Para cada atributo que carrega número (`x`, `y`, `width`, `height`, `d`,
   `transform`, `points`, `cx`, `cy`, `r`, `x1`, `y1`, `x2`, `y2`), extraia os números e compare com
   um **epsilon explícito, passado por flag** (`--epsilon=0`, default `0`). Reporte o maior desvio
   absoluto encontrado por arquivo.
4. **CLI de `tool/compare_svg.dart`:**
   ```
   dart run tool/compare_svg.dart [caminho]        # arquivo ou diretório sob test/corpus
   dart run tool/compare_svg.dart --all            # os 623
   dart run tool/compare_svg.dart --mode=structural|numeric|both   (default: both)
   dart run tool/compare_svg.dart --epsilon=0
   dart run tool/compare_svg.dart --report=tool/SVG_VALIDATION.md
   ```
   Skip-list obrigatória: `test/corpus/dir/dir-011.mei` e `dir-012.mei` (não são UTF-8).
5. **Relatório markdown** `tool/SVG_VALIDATION.md`, com:
   - no topo: `Estrutural: N/623 limpos` e `Numérico (eps=E): N/623 limpos`;
   - uma tabela por categoria do corpus (são 69 categorias) com limpos/total;
   - uma tabela dos 30 arquivos com mais divergências estruturais, com a primeira divergência de cada.
6. **`test/svg_golden_test.dart`**: um teste que roda o modo estrutural sobre um subconjunto pequeno
   e fixo (dez arquivos, um por família: note, beam, slur, chord, rest, clef, accid, tuplet, lyric,
   measure) e afirma a contagem **atual** de limpos. Comece com `expect(clean, 0)` e um comentário
   dizendo que esse número **só pode subir**. Cada tarefa seguinte da Fase 5 atualiza esse número
   para cima.
   Lembre: `Resources.defaultPath = 'assets/data';` e `registerModelClasses()` no `setUpAll`.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 310 testes**
- [ ] `dart run tool/compare_svg.dart --all` roda até o fim sem exceção, em menos de 5 minutos,
      e escreve `tool/SVG_VALIDATION.md`
- [ ] `head -5 tool/SVG_VALIDATION.md` mostra `Estrutural: 0/623 limpos` (baseline correto: ainda não
      há renderização)
- [ ] `dart run tool/compare_svg.dart test/corpus/note/note-001.mei` imprime uma mensagem clara de
      "sem renderização Dart disponível", **não** uma exceção
- [ ] O comparador é testado contra si mesmo: comparar um golden **com ele mesmo** dá 0 divergências
      em ambos os modos (prove no relatório com o comando e a saída)
- [ ] O comparador detecta uma mudança injetada: copie um golden, altere um número, e mostre que o
      modo numérico o acusa e o estrutural não (prove no relatório)
- [ ] Relatório em `prompts/reports/05-00.md`
- [ ] `PLANO.md`: checkbox "Harness de comparação de SVG" da Fase 5 marcado

## Armadilhas conhecidas

- **O sufixo aleatório de id.** Sem normalizá-lo, o modo estrutural reporta 623/623 divergentes para
  sempre e o harness não serve para nada. Resolva isso primeiro e prove com o auto-teste.
- Os `<path d="...">` dentro de `<defs>` são os contornos dos glifos SMuFL, idênticos em todo
  documento que usa o mesmo glifo. São milhares de números por arquivo; compare-os, mas conte-os
  como uma categoria à parte no relatório, senão eles afogam o sinal.
- `package:xml` é imutável e ignora whitespace por padrão dependendo da chamada — configure o parse
  para preservar o que importa e normalizar o que não importa, e documente a escolha.
- Não use `test/golden/cpp` como fonte de verdade sem confirmar que foi gerado com este binário:
  `./build/verovio --version` tem de dizer `6.2.0`.
- **Não regenere os goldens** nesta tarefa.

## Fora de escopo

- Qualquer renderização. O gancho `renderSvgForComparison` devolve `null` e pronto.
- Comparar MIDI ou timemap (Fase 6).
