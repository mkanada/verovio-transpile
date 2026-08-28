# `cpp_probe/` — instrumentar o C++ e extrair dados de referência

O port em `verovio_dart/` precisa comparar números com o Verovio 6.2.0 original. Os valores finais
saem do binário limpo (`build/verovio -t timemap`, SVG), mas os valores **intermediários** — o
`drawingXRel` que um functor recebeu e o que ele devolveu — não saem de lugar nenhum. Sem eles a
implementação de um functor vira adivinhação: o teste não bate e não há como saber em qual functor
a divergência nasceu.

`cpp_probe/` resolve isso: instrumenta o C++ com `fprintf`, roda, e grava os valores como fixtures
versionados em `verovio_dart/test/fixtures/cpp/<id>/<arquivo>.jsonl`, que os testes Dart consomem.

## Fluxo

```bash
# a partir da raiz do workspace
cpp_probe/sync.sh                 # origin/src -> build-probe/src (rsync, incremental)
$EDITOR build-probe/src/src/adjustlayersfunctor.cpp   # acrescente os fprintf
cpp_probe/mkpatch.sh 04a          # grava cpp_probe/patches/04a.patch
cpp_probe/build.sh 04a            # sync + patches até 04a + cmake/ninja incremental
cpp_probe/run.sh 04a test/corpus/layer/layer-001.mei \
    verovio_dart/test/fixtures/cpp/04a/layer-001.mei.jsonl --svg /tmp/probe.svg

# a instrumentação não pode ter mudado comportamento:
build/verovio -r verovio_dart/assets/data -x 12345 -o /tmp/limpo.svg \
    verovio_dart/test/corpus/layer/layer-001.mei
diff /tmp/limpo.svg /tmp/probe.svg     # tem de sair vazio
```

Depois é só ler o `.jsonl` — antes de escrever a primeira linha de Dart.

| Script | O que faz |
|---|---|
| `sync.sh` | `rsync` de `origin/src` para `build-probe/src`. Preserva mtimes, então o ninja recompila só o que o patch tocou. Exclui `include/vrv/git_commit.h`, que o cmake gera dentro da árvore de fontes. |
| `patch.sh <id>` | Aplica os patches listados em `patches/ORDER`, de cima para baixo, até `<id>` inclusive. `--list` mostra a pilha. |
| `mkpatch.sh <id>` | Grava `patches/<id>.patch` = diff entre (origin + patches anteriores) e `build-probe/src`. Avisa se o patch **remover** alguma linha. |
| `build.sh <id>` | `sync` + `patch` + `cmake`/`ninja` incremental. Mesmas flags do binário limpo: Release, `NO_HUMDRUM_SUPPORT=ON`. |
| `run.sh <id> <mei> <saida.jsonl> [--svg <svg>] [--opt <flag>]...` | Roda o binário instrumentado com a semente fixa e grava o fixture com o cabeçalho `_meta`. `--opt` (repetível) repassa uma flag extra do CLI do verovio ao binário — necessário quando o default de uma opção não exercita o comportamento a medir (ex.: `--opt --condense-first-page`); as flags usadas ficam registradas em `_meta.opts`. |

`build-probe/` é **ignorado pelo git** — é derivado, e regerar leva um `build.sh`.
`origin/` continua **intocado**: toda a instrumentação vive em `cpp_probe/patches/`.

## As três regras da instrumentação

1. **Só acrescentar.** Um patch que remove ou altera uma linha do C++ corrompe, silenciosamente,
   todo fixture que dele derivar. `mkpatch.sh` avisa; `grep -c '^-[^-]' patches/<id>.patch` tem de
   dar `0`.
2. **Nada de lógica.** Os helpers de `include/vrv/vrvprobe.h` só **leem** a árvore de objetos e
   escrevem texto. Nenhum valor que o Verovio calcula passa por eles.
3. **Prove.** O binário instrumentado tem de produzir SVG **idêntico** ao do limpo, com `diff`
   vazio, para os arquivos da sua tarefa. É esta verificação — não a boa intenção — que fecha a
   questão.

## Semente fixa dos `@xml:id`

A opção `xmlIdSeed` (short `-x`, `origin/src/src/options.cpp:980-984`) é **aleatória por padrão**:
sem fixá-la, os `@xml:id` mudam a cada execução e o fixture deixa de ser reproduzível.

**A semente é `12345`**, cravada em `run.sh` (`PROBE_SEED`). Não mude sem regerar *todos* os
fixtures — o campo `id` de cada registro depende dela.

## O esquema do `.jsonl`

Um objeto JSON por linha. A **primeira linha** é o cabeçalho de proveniência:

```json
{"_meta":{"task":"04a","source":"test/corpus/layer/layer-001.mei","xmlIdSeed":12345,"verovio":"6.2.0","patches":["EXEMPLO","04a"],"generated":"2026-08-27"}}
```

`generated` só muda quando os **registros** mudam: `run.sh` reaproveita a data anterior quando o
corpo do arquivo saiu igual, para que regerar um fixture inalterado dê o mesmo arquivo byte a byte.

Cada linha seguinte é um registro:

```json
{"fn":"AdjustXPos","pass":1,"path":"measure[1]/staff[1]/layer[1]/note[3]","id":"nxyz","xRel_in":420,"xRel_out":455}
```

| Campo | Significado |
|---|---|
| `fn` | nome do functor C++ que produziu o registro |
| `pass` | número da passada, quando o mesmo functor roda mais de uma vez. `probe::BeginPass("Fn")` é chamado **no ponto de chamada** (`page.cpp`), antes de cada `Process`, e `probe::CurrentPass("Fn")` é lido na emissão. Omita o campo quando o functor roda uma vez só. |
| `path` | **a chave de casamento** (abaixo) |
| `id` | o `@xml:id`, para leitura humana e conferência contra o SVG do C++ |
| `<campo>_in` / `<campo>_out` | o valor antes e depois do functor |
| qualquer outro campo | valores intermediários (`offset`, `selfLeft`, o ramo do `if` tomado…). O leitor Dart entrega o registro cru, então acrescentar campo não quebra nada. |

Quando `(fn, pass, path)` não identifica um registro só — em `AdjustXPos` o mesmo elemento é
visitado uma vez por `staffN` — acrescente o campo que desempata (ali, `staffN`) e filtre por ele
no lado Dart. `CppFixture.single()` **falha** em vez de escolher um registro ao acaso.

## `path`: a chave de casamento

Casar por `@xml:id` seria apostar numa paridade entre a geração de id do Dart e a do C++ que ninguém
mediu. O casamento é por **caminho estrutural**, derivável identicamente dos dois lados:
`vrv::probe::Path` em `include/vrv/vrvprobe.h` e `cppPath()` em
`verovio_dart/test/fixtures/cpp_fixture.dart`.

Um caminho é uma sequência de segmentos separados por `/`, e **todo segmento tem a forma
`<nomeDaClasseMei>[<chave>]`**. A chave sai da primeira regra que se aplicar:

1. **`@n`**, para `measure`, `staff` e `layer` que o tenham — é a identidade musical desses três, e
   é robusta a um pentagrama a mais ou a menos numa das árvores;
2. **um token de papel**, para objetos que são *membros* do pai em vez de filhos dele
   (`Measure::m_leftBarLine` → `left`, `m_rightBarLine` → `right`): eles não estão na lista de
   filhos, então nenhum índice os identifica e todos colidiriam em `[1]`;
3. **o índice 1-based** entre os filhos do pai que têm o mesmo nome de classe.

O caminho é **enraizado no `measure`** (inclusive). Page e system ficam de fora de propósito: a que
sistema um compasso pertence muda com o cast-off, e a chave não pode depender disso. Objetos sem
`measure` ancestral são enraizados no objeto mais alto abaixo do `doc`.

```
measure[1]/staff[1]/layer[2]/beam[1]/note[3]
measure[1]/barLine[right]
```

Uma chave `?` na saída significa que o objeto não é filho do pai dele nem é um membro conhecido:
estenda a regra 2 em `vrvprobe.h` **e** em `cpp_fixture.dart`, nunca só num lado.

## `patches/ORDER`

A pilha de patches, um id por linha, na ordem de execução das tarefas. `patch.sh <id>` aplica de
cima até `<id>`, então cada tarefa herda a instrumentação de todas as anteriores.

**`EXEMPLO` é o patch base e fica sempre em primeiro**: é ele que acrescenta `include/vrv/vrvprobe.h`
e o `#include` correspondente em `src/page.cpp`. Os patches das tarefas só acrescentam chamadas
`probe::BeginPass(...)` / `probe::Emit(...)` — assim dois patches nunca disputam a mesma linha de
include.

Ele também é a instrumentação de referência: `AdjustXPosFunctor::VisitLayerElement`, um functor que
já está portado em `verovio_dart/lib/src/layout/adjust_x_pos.dart`. Leia-o antes de escrever o seu.

## Do lado Dart

```dart
import 'fixtures/cpp_fixture.dart';

final fixture = CppFixture.load('04a', 'test/corpus/layer/layer-001.mei');
final divergences = fixture.compare(
  fn: 'AdjustLayers',
  pass: 1,
  field: 'xRel_out',
  actual: (record) => byPath[record.path]?.getAlignment()?.getXRel(),
);
expect(divergences, isEmpty, reason: divergences.join('\n'));
```

`byPath` é um `Map<String, LayerElement>` que o teste monta com `cppPath(element)`. O comparador
devolve **a lista de divergências**, com caminho, valor esperado e valor obtido: a mensagem de falha
é o produto. Fixture ausente, fixture vazio ou filtro que não casa com nada são **erro**, nunca um
teste verde silencioso.

## Quando um valor não bate

Não adivinhe e não ajuste o esperado. Volte ao patch, instrumente **mais fundo** dentro da função
divergente — valores intermediários, o ramo do `if` tomado, o retorno de cada helper —, regere o
fixture e compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a
divergência irredutível, pela política da seção 7 do `verovio_dart/prompts/00-MESTRE.md`, depois de
ter instrumentado até o nível da expressão. O patch fica versionado com o nível de detalhe a que
você chegou: a próxima pessoa herda o instrumento, não o problema.
