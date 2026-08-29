# 05-33 — Testes de renderização de verdade

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

A 05-26 tirou a mentira do harness. Falta tirar a mentira dos testes.

Nos 10 arquivos `test/view_*.dart` há **53 asserções** desta forma:

```dart
test('05-17 view_beam.dart exists and draws polygons', () {
  final content = File('lib/src/rendering/view_beam.dart').readAsStringSync();
  expect(content, contains('drawBeam'));
  expect(content, contains('drawBeamSegment'));
});
```

Isso não testa comportamento nenhum: é `grep` no próprio fonte. Passa com a função vazia, passa com
a função errada, passa com a função que joga exceção. São 46 leituras de arquivo-fonte dentro dos
testes de view, e elas são a maior parte do que a Fase 5 chamou de cobertura.

Esta tarefa troca as 53 por testes que falham quando o desenho está errado.

## Pré-condições

Tarefas **05-26** a **05-32** concluídas. Esta tarefa vem **depois** da geometria porque um teste
escrito contra números que estão prestes a mudar nasce errado; e vem **antes** das 05-34/05-35
porque é ele que protege a refatoração de fidelidade.

```bash
cd verovio_dart
grep -c "expect(content, contains" test/view_*.dart    # 53 no total, hoje
dart run tool/compare_svg.dart --all                    # anote o ANTES
```

## O que substituir cada asserção por

Três instrumentos, nesta ordem de preferência:

### 1. Comparação com o golden, por família

O instrumento primário: renderize um arquivo do corpus e compare com `test/golden/cpp/**.svg` pelo
`SvgComparator`, com catraca por família (o padrão que a 05-26 introduziu). Um teste por família de
`view_*.cpp`, com a lista de arquivos daquela família e o número de limpos como catraca:

```dart
test('view_beam: família beam/ contra os goldens', () {
  final resultados = renderizarFamilia('test/corpus/beam');
  // 05-33: <N> limpos hoje; este número só sobe.
  expect(resultados.limpos, greaterThanOrEqualTo(<N>));
  expect(resultados.falhas, isEmpty, reason: resultados.falhas.join('\n'));
});
```

**`falhas` vazio não é catraca, é asserção dura**: nenhum arquivo pode lançar exceção durante a
renderização. Hoje três lançam (05-36 os conserta); até lá, esses três ficam numa lista explícita e
nomeada no teste, com o id da tarefa que os recebe — nunca num `skip`.

### 2. Asserção sobre a saída, para o que o golden não isola

Quando o objetivo é uma decisão específica do `Draw*` (um glifo escolhido, um `class` emitido, uma
ordem de emissão), afirme sobre o **SVG renderizado**, não sobre o fonte:

```dart
final svg = renderizar('test/corpus/arpeg/arpeg-004.mei');
expect(glifosEmDefs(svg), contains('EAA9'));   // view_control.cpp:1588
```

Toda asserção dessas cita a linha do C++ que a justifica, como o resto do repositório (§4.1).

### 3. Teste de unidade com `DeviceContext` de mentira

Para as primitivas e para os caminhos que o corpus não exercita, chame o método com um
`DeviceContext` que registra as chamadas recebidas e afirme a **sequência** (`startGraphic`,
`drawSmuflCode`, `endGraphic`) com os argumentos. `test/view_graph_test.dart` (578 linhas) já faz
isso e é o modelo a seguir — é o único dos dez que testa comportamento.

## Arquivos a alterar/criar

- **Alterar** os 10 `test/view_*.dart` — fora as 53 asserções de `contains`, dentro os três
  instrumentos.
- **Criar** `test/support/render_family.dart` (ou equivalente) — o auxiliar de renderizar uma
  família e agregar limpos/divergentes/falhas, para os 10 arquivos não reimplementarem isso 10
  vezes. Registre-o como código de apoio do port, não como port de nada (§4.1).
- **Alterar** `test/svg_golden_test.dart` — o subconjunto fixo de 10 arquivos vira o resumo das
  famílias, com o número global.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline (8)
- [ ] `dart test` verde, nenhum teste em `skip`
- [ ] `grep -c "expect(content, contains" test/view_*.dart` → **0** em todos os dez
- [ ] `grep -n "readAsStringSync()" test/view_*.dart` → nenhuma leitura de arquivo sob `lib/`
- [ ] Toda família de `view_*.cpp` tem um teste de catraca contra os goldens, com o número medido
- [ ] Nenhum arquivo do corpus lança exceção durante a renderização, exceto os que estiverem numa
      lista nomeada no teste apontando a tarefa que os recebe
- [ ] **Prova de que os testes mordem**: escolha três `Draw*` de famílias diferentes, quebre cada um
      deliberadamente (troque um glifo, inverta um sinal, remova um `startGraphic`), mostre no
      relatório qual teste ficou vermelho em cada caso, e desfaça. Um teste que não fica vermelho
      quando o código quebra não conta como cobertura
- [ ] O relatório traz a tabela família → arquivos → limpos, que é a foto do estado real da Fase 5
- [ ] Relatório em `prompts/reports/05-33.md`
- [ ] `PLANO.md`: linha da 05-33

## Armadilhas conhecidas

- **Não escreva o número da catraca sem medir.** Foi assim que a fase inteira derrapou.
- **Não use o golden como entrada.** O golden é o esperado; a entrada é sempre o `.mei`. O teste da
  05-26 (`harness_integrity_test.dart`) existe para pegar isso, mas ele só cobre o harness — nos
  testes novos a disciplina é sua.
- Renderizar 623 arquivos em cada `dart test` é caro. Um teste por família com **todos** os arquivos
  da família é o alvo; se a suíte passar de dois minutos, meça e divida por marcador de teste, não
  reduzindo a cobertura.
- As catracas de família tornam redundantes as 26 catracas por arquivo que a 05-26 criou. Consolide
  — mas só depois de a de família estar verde, e diga no relatório quais sumiram.

## Fora de escopo

- Consertar os divergentes que os testes novos expõem (05-36).
- Refatoração de `lib/src/rendering/` (05-34, 05-35).
