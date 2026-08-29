# 00-MESTRE — convenções obrigatórias do port Verovio → Dart

> **Todo prompt de tarefa manda ler este arquivo primeiro.** Ele é auto-suficiente: você não precisa
> abrir mais nada além dele, do prompt da sua tarefa e dos arquivos que o prompt citar.

---

## 1. O que é este projeto

Port **linha a linha** do **Verovio 6.2.0** — biblioteca C++ de gravação musical que converte
MEI/MusicXML/ABC em SVG — para **Dart puro** (Dart ≥ 3.0, sem FFI, compatível com Flutter e com web).

**A regra de ouro: espelhe o C++.** O objetivo é *equivalência funcional*, não um redesenho. Na dúvida,
faça igual ao original — mesmos nomes de método (em `lowerCamelCase`), mesma ordem de operações, mesma
aritmética, mesmos valores mágicos. Não "melhore" o algoritmo. Não troque um `for` indexado por um
`map` se isso mudar a ordem de avaliação. Não arredonde diferente.

Quando o Dart **obrigar** a divergir (não tem `const` em objetos, não tem ponteiro, não tem herança
múltipla de classe), documente no código com um bloco:

```dart
/// Deviations from the C++:
/// - `ConstFunctor` não é portado: Dart não tem árvore de objetos const, e os
///   functors mutáveis cobrem os dois usos.
```

Divergir por conveniência, sem esse bloco, é defeito.

---

## 2. Layout do workspace

Raiz: `/home/mauricio/rust_projects/verovio-transpile`. **É um repositório git** (inicializado em
2026-08-26, remoto privado `mkanada/verovio-transpile`): use `git diff` e `git status` à vontade —
o fluxo da seção 6-bis depende deles. **Não faça `git push`**; commits ficam a critério do dono do
projeto.

| Caminho | Papel |
|---|---|
| `origin/src/` | Fontes C++ 6.2.0 originais — **a referência de toda decisão**. `origin/src/src/*.cpp`, `origin/src/include/vrv/*.h`, `origin/src/libmei/dist/`. **Somente leitura: nunca edite nada aqui.** A instrumentação para extrair dados vive em `cpp_probe/patches/` (seção 6-bis) e nunca toca isto. |
| `cpp_probe/` | A máquina de extração de dados de referência do C++: scripts + patches de instrumentação. Seção 6-bis. |
| `build-probe/` | A árvore C++ instrumentada e o binário que sai dela. **Ignorada pelo git** — é derivada; regere com `cpp_probe/build.sh <id>`. |
| `build/verovio` | CLI C++ compilado (Release, `NO_HUMDRUM_SUPPORT=ON`). É o oráculo. |
| `verovio_dart/` | O package Dart. **Todo desenvolvimento acontece aqui.** |
| `PLANO.md` | Roadmap de escopo. Cada tarefa marca seu checkbox aqui ao terminar. |
| `verovio_dart/prompts/` | Esta série de prompts. `AUDITORIA.md` tem o estado medido em 2026-08-26. |
| `verovio_dart/prompts/reports/` | Um relatório markdown por tarefa concluída. |

Dentro de `verovio_dart/lib/src/`:

- **`core/`** — `vrvdef.dart` (o enum `ClassId`, constantes e unidades — a espinha de tudo),
  `bounding_box.dart` (classe base de `Object`), `devicecontextbase.dart` (Pen/Brush/FontInfo/
  BezierCurve/TextExtend), `point.dart`, `logging.dart`, `fraction.dart`, `smufl.dart`,
  `tunings.dart`, `utils.dart`, `crc.dart`, `attdef.dart`, `options_shell.dart`,
  `file_reader.dart` (import condicional `dart:io`/stub, para o package continuar válido na web).
- **`model/`** — a árvore de objetos MEI. `object.dart` define `class Object extends BoundingBox`,
  `ObjectListInterface` e `ObjectFactory`. Classes concretas divididas entre escritas à mão
  (`basic_elements.dart`, `scoredef.dart`, `doc.dart`, `text_elements.dart`,
  `system_page_elements.dart`, `layer_element.dart`, `control_element.dart`, `floating_object.dart`,
  `editorial_element.dart`, `mensur.dart`, `zone.dart`, `comparison.dart`, `expansion_map.dart`)
  e geradas (`*_gen.dart`). `interfaces/` tem as interfaces MEI (pitch, duration, time, position,
  plist, linking, facsimile…).
- **`model/atts/`** — classes de atributos MEI geradas, **um mixin por classe `Att*`**
  (`readXxx`/`writeXxx`/`copyAttXxx`), mais `mei_enums.dart`, `atts_conversion.dart` e o runtime
  escrito à mão `mei_values.dart`.
- **`io/`** — `mei_input.dart` (~5,3k linhas, inclui upgrades MEI 3/4/5→6), `iomusxml.dart` (~6,5k),
  `ioabc.dart`, `iobase.dart`, `format.dart`, e `xml_node.dart`: uma árvore `MeiXmlNode` **mutável**
  espelhando o pugixml, porque os leitores mutam atributos enquanto fazem o parse e o
  `package:xml` é imutável.
- **`layout/`** — o framework de functors e o motor de layout: aligners, `preparedata_functor`,
  `calc_*`, `adjust_*`, `cast_off*`, `justify`, `floating_positioner`, `slur_positioning`,
  `mensural_neume`.
- **`rendering/`** — `resources.dart` (fontes SMuFL de `assets/data`), `device_context.dart`,
  `bbox_device_context.dart`, `glyph.dart`, e `headless_extents.dart` (substituto temporário do
  `View`, marcado para deleção na tarefa 05-11).
- **`toolkit.dart`** — ponto de entrada público.
- Vazios, à espera das fases seguintes: `drawing/`, `editing/`, `midi/`, `resources/`.
  (`lib/src/atts/` também está vazio e é resto do plano original — os atts vivem em `model/atts/`.)

---

## 3. Comandos

**Rode tudo a partir de `verovio_dart/`** — os testes e as tools resolvem `test/corpus` e
`assets/data` relativos à raiz do package.

```bash
cd verovio_dart

dart test                                   # suíte completa (~15 s)
dart test test/mei_input_test.dart          # um arquivo
dart test -n 'trecho do nome do teste'      # um teste
dart analyze                                # lints (package:lints/recommended)
dart format <só os arquivos que você tocou>  # NÃO rode em lib/ test/ tool/ inteiros — veja abaixo

# Harnesses de validação (escrevem/atualizam relatórios markdown)
dart run tool/validate_layout.dart          # layout + timemap vs C++ → tool/LAYOUT_VALIDATION.md
dart run tool/validate_io.dart musicxml <entrada.musicxml> <mei-convertido-pelo-cpp.mei>
./tool/golden.sh                            # regenera test/golden/cpp/**.svg a partir de ../build/verovio

# Geradores de código
dart run tool/gen_atts.dart && dart format lib/src/model/atts/   # → lib/src/model/atts/*.dart
```

O binário C++ como oráculo pontual (a partir da **raiz** do workspace):

```bash
./build/verovio -r verovio_dart/assets/data -o /tmp/out.svg entrada.mei
./build/verovio -r verovio_dart/assets/data -t timemap -o /tmp/out.json entrada.mei
./build/verovio -r verovio_dart/assets/data -t mei    -o /tmp/out.mei  entrada.musicxml
./build/verovio -r verovio_dart/assets/data -t midi   -o /tmp/out.mid  entrada.mei
```

Recompilar o C++, se algum dia precisar:

```bash
cmake -S origin/src/cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DNO_HUMDRUM_SUPPORT=ON
ninja -C build
```

### ⚠️ `tool/gen_elements.py` foi APOSENTADO (tarefa 04i)

Medido em 2026-08-26: o gerador **não reproduzia** os arquivos `lib/src/model/*_gen.dart`
versionados — rodá-lo apagava código escrito à mão. Em vez de consertá-lo, a tarefa 04i o
**aposentou** (renomeado para `tool/gen_elements.py.obsolete`): os `*_gen.dart` passaram a ser
**mantidos à mão** e não há mais procedimento de geração para eles — edite-os diretamente e
registre no relatório. `lib/src/model/atts/*.dart` continua gerado e fiel via `tool/gen_atts.dart`.

`tool/gen_atts.dart` é fiel: reproduz `lib/src/model/atts/*.dart` exatamente, módulo `dart format`.
Sempre rode `dart format lib/src/model/atts/` depois dele.

### ⚠️ Não rode `dart format` na árvore inteira

Medido em 2026-08-27: `dart format lib/ test/ tool/` reformata **53 arquivos** que ninguém tocou e
leva o `dart analyze` de **10 para 20 issues** — a versão do formatador é mais nova que a com que o
repositório foi escrito, e a reformatação cria `curly_braces_in_flow_control_structures` em código
existente. **Formate só os arquivos da sua tarefa**, um a um:

```bash
dart format lib/src/layout/adjust_layers.dart test/adjust_layers_test.dart
```

---

## 4. Convenções obrigatórias do repositório

1. **Cite o original.** Quase toda classe e todo método carrega um doc comment nomeando o contraparte
   C++ ("Mirrors `Object::Process`", "Port of `AdjustDotsFunctor`", "Port of `functor.h`").
   **Continue fazendo isso** — é assim que o port é revisado. Um método novo sem citação é defeito.
2. **Documente desvios explicitamente**, num bloco `Deviations from the C++:` (seção 1).
3. **Nunca edite à mão `lib/src/model/atts/*.dart`** com banner `GENERATED FILE` (exceto
   `mei_values.dart`, escrito à mão) — mexa no gerador `tool/gen_atts.dart`. Já os
   `lib/src/model/*_gen.dart` são **mantidos à mão desde a tarefa 04i** (o gerador
   `tool/gen_elements.py` foi aposentado): edite-os diretamente.
4. `constant_identifier_names` está **desligado de propósito** em `analysis_options.yaml`, para que
   identificadores C++ (`FUNCTOR_CONTINUE`, `BBOX_HORIZONTAL_ONLY`, `SMUFL_E050_noteheadBlack`)
   sobrevivam. Use-os.
5. **`model.Object` sombreia o `Object` do `dart:core`.** Arquivos que precisam dos dois importam o
   modelo `as model` ou usam `hide Object`. **Antes de acrescentar um import, olhe o estilo já usado
   no arquivo** e siga-o.
6. **`Resources.defaultPath` vale `'data'` por padrão, o que está errado neste layout.** Todo teste e
   toda tool que precise de métricas de glifo tem de fazer
   `Resources.defaultPath = 'assets/data';`. Suítes que esquecem imprimem
   `Bravura font could not be loaded` no stderr e passam mesmo assim — **esse ruído é esperado, não é
   regressão**.
7. As fontes ficam em **`assets/data/`** (Bravura, Gootville, Leipzig, Leland, Petaluma, `text/`,
   `*.xml`, `*.css`, `footer.svg`, `tuning-glyphnames.json`), **não** em `assets/fonts/` — o
   `PLANO.md` original dizia `assets/fonts` e estava errado.
8. `test/corpus/dir/dir-011.mei` e `test/corpus/dir/dir-012.mei` **não são UTF-8** de propósito.
   Qualquer harness que varra o corpus tem de pular esses dois.
9. `tool/_scratch_*.dart`, `tool/t8.dart` e `tool/dbg_c.dart` são lixo de debug. **Não construa em
   cima deles e não tente limpar os warnings deles** — os 8 warnings que produzem fazem parte da
   baseline.
10. **Registre suas tools novas em `tool/`** com um nome descritivo (`compare_svg.dart`,
    `validate_midi.dart`), nunca com prefixo `_scratch_`.

---

## 5. Os dois mecanismos que você precisa entender antes de editar

### (a) Despacho de functor

O C++ resolve functors por dupla dispatch: cada classe tem um `Accept(Functor &)` virtual que chama
o `VisitXxx` certo (`Lv::Accept` chama `VisitLv`; `Episema` **não** tem override e cai no
`LayerElement::Accept`; as folhas editoriais compartilham `EditorialElement::Accept`).

**Dart não tem dupla dispatch.** A resolução é feita dentro de `Functor.visit` / `Functor.visitEnd`
em `lib/src/layout/functor.dart`, em dois passos:

1. A tabela **`kAcceptChain`** (`Map<ClassId, ClassId>`, em `functor.dart:64`) mapeia os `ClassId`
   das classes que **não** definem `Accept()` próprio para o `ClassId` cujo `visitXxx` roda.
   `ClassId`s ausentes da tabela são visitados como eles mesmos.
   `ClassId acceptClassId(ClassId)` (`functor.dart:104`) faz a consulta.
2. Um `switch` sobre o `ClassId` resolvido chama o método `visitXxx` tipado.

Os corpos padrão dos `visitXxx` espelham `functorinterface.cpp`: **cada visit delega para o visit do
pai** (`visitNote` → `visitLayerElement` → `visitObject`). Consequência prática: um functor que
sobrescreve só `visitObject` enxerga **todos** os nós.

**Se você acrescentar uma classe de elemento que no C++ não tem override de `Accept()`, ela precisa
entrar em `kAcceptChain`.** Esquecer disso faz o functor simplesmente não ver o nó, sem erro.

`FunctorBase` (`functor.dart:112`) e `Functor` (`:173`) são as bases; `DocFunctor` (`:1102`) é a base
dos functors que carregam um `Doc`. Os retornos são os do C++: `FUNCTOR_CONTINUE`, `FUNCTOR_SIBLINGS`,
`FUNCTOR_STOP`.

**Desvios já documentados no cabeçalho de `functor.dart`, não os reabra:** `ConstFunctor` /
`ConstFunctorInterface` não são portados (Dart não tem árvore const; os functors mutáveis cobrem os
dois usos); `ImplementsEndInterface` é `true` por padrão em vez de abstrato, porque Dart não
consegue detectar se um método `end` foi sobrescrito.

### (b) Registro de classe

Elementos nascem **pelo nome** através do `ObjectFactory` (`lib/src/model/object.dart`).
Uma classe de elemento nova precisa de **três** coisas:

1. Um valor no enum **`ClassId`** em `lib/src/core/vrvdef.dart` (hoje: 190 valores).
2. Um registro: `f.register('nomeMei', ClassId.xxx, Xxx.new);` em
   `lib/src/factory_registry.dart` (classes escritas à mão) ou em
   `lib/src/model/factory_registry_gen.dart` (geradas).
3. Se não tiver `Accept()` no C++, uma entrada em `kAcceptChain` (item (a)).

**Todo teste e toda tool tem de chamar `registerModelClasses()`** — em `setUpAll` nos testes, no
começo de `main` nas tools. Esquecer produz um `ObjectFactory` vazio e erros confusos de "classe
desconhecida".

O nome registrado tem de ser **exatamente** o nome do elemento MEI usado no C++, que você acha assim:

```bash
grep -rn "ClassRegistrar" origin/src/src/<arquivo>.cpp
# ex.: static const ClassRegistrar<Note> s_factory("note", NOTE);
```

A paridade dos nomes é garantida por `test/factory_registry_test.dart` (tarefa 04i): ele compara os
nomes registrados em Dart com a tabela de `ClassRegistrar` do C++. Os dois únicos desvios, lá
documentados: `'oStaff'`/`'stageDir'` (pseudo-`ClassId`s do C++ com lambdas de fábrica próprias, que
o Dart resolve em `mei_input.dart`) e `'alignmentreference'` (Dart-only).

---

## 6. Procedimento de verificação (obrigatório em toda tarefa)

Antes de considerar a tarefa pronta, rode **os quatro** e cole a saída real no relatório:

### 1. `dart analyze` — sem avisos novos

```bash
cd verovio_dart && dart analyze
```

**Baseline desde 2026-08-28 (tarefa 04i): `8 issues found.`** — todos em `tool/_scratch_*.dart`.
Os 2 warnings que existiam em `test/` foram corrigidos na 04i. Terminar com 8 é aceitável. Terminar
com 9 não é: o aviso novo é seu.

### 2. `dart test` — verde, sem regressão

```bash
cd verovio_dart && dart test
```

**Baseline em 2026-08-27: 281 testes, todos passando, ~17 s.** Sua tarefa acrescenta testes; a
contagem sobe. Se qualquer teste que passava passar a falhar, **é regressão sua** — conserte antes de
fechar a tarefa. Ver a seção 8, regra 1.

### 3. Diff estrutural contra o C++

Depende da fase, e o prompt da sua tarefa diz qual comando usar:

- **Fase 4**: `dart run tool/validate_layout.dart` — o relatório em `tool/LAYOUT_VALIDATION.md` tem
  de manter as asserções estruturais passando e **não piorar** a contagem de timemaps
  (baseline: **24/30** batendo, em 46 arquivos).
- **Fase 5**: `dart run tool/compare_svg.dart` (criada na tarefa 05-00) — compara com
  `test/golden/cpp/**.svg` em modo estrutural e numérico. Baseline inicial: **0/623**. Sua tarefa
  tem de **subir** esse número, e o prompt diz de quanto.
- **Fase 6**: comparação contra `./build/verovio -t midi` e `-t timemap` sobre o corpus.
- **Fase 7**: comparação da lista de opções e da saída do CLI contra o `build/verovio`.

### 4. Igualdade numérica exata como meta

O alvo **não** é "parecido". É **byte a byte / número a número idêntico ao C++**. Onde o prompt
autorizar um epsilon, use exatamente o epsilon que ele autoriza — e registre no relatório quantos
arquivos passam com epsilon 0.

---

## 6-bis. Extraindo dados de referência do C++

O binário limpo dá os valores **finais** (`build/verovio -t timemap`, o SVG). Os valores
**intermediários** — o `drawingXRel` que um functor recebeu e o que ele devolveu — não saem de lugar
nenhum, e sem eles implementar um functor vira adivinhação: o teste não bate e não há como saber em
qual functor a divergência nasceu.

`cpp_probe/` resolve isso. Instrumenta o C++ com `fprintf`, roda, e grava os valores como fixtures
versionados que os testes Dart consomem. **`origin/` continua intocado**: a instrumentação vive como
patches em `cpp_probe/patches/`, aplicados sobre uma cópia em `build-probe/` que o git ignora.

### Quando extrair fixtures (e quando não)

**Extrair antes de implementar é obrigatório só quando o valor que o código novo tem de produzir é
um intermediário invisível** — não aparece em nenhuma saída final do binário limpo (SVG, timemap,
MEI, MIDI). O teste de decisão: *"eu consigo apontar onde, numa saída final do binário limpo, este
valor aparece?"* Se não consegue, instrumente **antes** de escrever Dart — foi o caso de toda a
Fase 4 (o `xRel` que um functor recebe e devolve não sai em lugar nenhum) e é o caso das bounding
boxes de layout na tarefa 05-12 (as caixas que o `BBoxDeviceContext` acumula alimentam o layout e
nunca são serializadas).

Quando o alvo da tarefa **é** uma saída final observável — os `view*.cpp` da Fase 5 (exceto 05-12),
cujo produto sai inteiro nos 623 goldens de `test/golden/cpp/`; o MEI/MIDI/timemap da Fase 6; as
opções da Fase 7 — **os goldens já são o fixture**. Não duplique: implemente, compare com o
harness da fase e só então instrumente, reativamente, pelo protocolo "Quando um valor não bate"
(abaixo). Instrumentar preventivamente o que já sai na saída final é desperdício: o fixture registraria
redundantemente o que o golden já diz.

### O fluxo

```bash
# a partir da RAIZ do workspace
cpp_probe/sync.sh                 # origin/src -> build-probe/src (rsync, incremental)
$EDITOR build-probe/src/src/<functor>.cpp     # acrescente os fprintf
cpp_probe/mkpatch.sh <id>         # grava cpp_probe/patches/<id>.patch
cpp_probe/build.sh <id>           # sync + patches até <id> + ninja incremental
cpp_probe/run.sh <id> test/corpus/<x>.mei \
    verovio_dart/test/fixtures/cpp/<id>/<x>.mei.jsonl --svg /tmp/probe.svg
```

`cpp_probe/README.md` tem os detalhes. O que **toda tarefa** precisa saber está abaixo.

### As três regras da instrumentação

1. **Só acrescentar.** Um patch que remove ou altera uma linha do C++ corrompe, silenciosamente,
   todo fixture que dele derivar. `grep -c '^-[^-]' cpp_probe/patches/<id>.patch` tem de dar `0`.
2. **Nada de lógica.** Os helpers de `include/vrv/vrvprobe.h` só **leem** a árvore de objetos e
   escrevem texto. Nenhum valor que o Verovio calcula passa por eles.
3. **Prove.** O binário instrumentado tem de produzir SVG **idêntico** ao do limpo, `diff` vazio,
   para os arquivos da sua tarefa:

   ```bash
   build/verovio -r verovio_dart/assets/data -x 12345 -o /tmp/limpo.svg <entrada.mei>
   diff /tmp/limpo.svg /tmp/probe.svg     # vazio
   ```

### Semente fixa dos `@xml:id`

A opção `xmlIdSeed` (short `-x`, `origin/src/src/options.cpp:980-984`) é **aleatória por padrão**.
Sem fixá-la os `@xml:id` mudam a cada execução e o fixture deixa de ser reproduzível. **A semente é
`12345`**, cravada em `cpp_probe/run.sh`. Não mude sem regerar *todos* os fixtures.

### O esquema do `.jsonl`

Um objeto JSON por linha, em `verovio_dart/test/fixtures/cpp/<id>/<arquivo>.jsonl`. A primeira linha
é o cabeçalho de proveniência; as demais são registros:

```json
{"_meta":{"task":"04a","source":"test/corpus/layer/layer-001.mei","xmlIdSeed":12345,"verovio":"6.2.0","patches":["EXEMPLO","04a"],"generated":"2026-08-27"}}
{"fn":"AdjustLayers","pass":1,"path":"measure[1]/staff[1]/layer[2]/note[3]","id":"n1a2b3","xRel_in":420,"xRel_out":455}
```

`fn` é o functor; `pass` o número da passada quando o mesmo functor roda mais de uma vez (omita
quando não se aplica); `path` é **a chave de casamento**; `id` é o `@xml:id`, para leitura humana;
`<campo>_in` / `<campo>_out` são o valor antes e depois. Qualquer campo extra (valores
intermediários, o ramo do `if` tomado) é bem-vindo — o leitor entrega o registro cru.

### A regra do `path`

Casar por `@xml:id` seria apostar numa paridade entre a geração de id do Dart e a do C++ que ninguém
mediu. O casamento é por **caminho estrutural**, derivável identicamente dos dois lados:
`vrv::probe::Path` (C++) e `cppPath()` em `verovio_dart/test/fixtures/cpp_fixture.dart`.

**Todo segmento tem a forma `<nomeDaClasseMei>[<chave>]`**, e a chave sai da primeira regra que se
aplicar:

1. **`@n`**, para `measure`, `staff` e `layer` que o tenham;
2. **um token de papel**, para objetos que são *membros* do pai em vez de filhos dele —
   `Measure::m_leftBarLine` → `left`, os `staffDef` clef/keySig/meterSig que o `AlignHorizontally`
   materializa numa `Layer` → `staffDef`. Eles não estão na lista de filhos, então nenhum índice os
   identifica e todos colidiriam em `[1]`;
3. **o índice 1-based** entre os filhos do pai com o mesmo nome de classe.

O caminho é **enraizado no `measure`** (inclusive): a que sistema um compasso pertence muda com o
cast-off, e a chave não pode depender disso.

```
measure[1]/staff[1]/layer[2]/beam[1]/note[3]
measure[1]/barLine[right]
```

Uma chave `?` na saída significa que o objeto não é filho do pai dele nem é um membro conhecido:
estenda a regra 2 nos **dois** lados, nunca só num.

### Do lado Dart

```dart
import 'fixtures/cpp_fixture.dart';

final fixture = CppFixture.load('04a', 'test/corpus/layer/layer-001.mei');
final divergences = fixture.compare(
  fn: 'AdjustLayers', pass: 1, field: 'xRel_out',
  actual: (record) => byPath[record.path]?.getAlignment()?.getXRel(),
);
expect(divergences, isEmpty, reason: divergences.join('\n'));
```

`byPath` é um `Map<String, LayerElement>` que o teste monta com `cppPath(element)`. O comparador
devolve **a lista de divergências**, com caminho, valor esperado e obtido: a mensagem de falha é o
produto. Fixture ausente, fixture vazio ou filtro que não casa com nada são **erro**, nunca um teste
verde silencioso.

Para capturar os valores **em voo** no lado Dart sem tocar no código de produção, estenda o functor
no próprio teste e envolva o `visitXxx` (`super.visitXxx(...)` no meio). `test/cpp_fixture_test.dart`
tem o exemplo completo.

### Quando um valor não bate

Não adivinhe e não ajuste o esperado. Volte ao patch, instrumente **mais fundo** dentro da função
divergente — valores intermediários, o ramo do `if` tomado, o retorno de cada helper —, regere o
fixture e compare de novo. Cada rodada estreita o intervalo onde a divergência nasce. Só declare a
divergência irredutível, pela política da seção 7, depois de ter instrumentado até o nível da
expressão. O patch fica versionado com o nível de detalhe a que você chegou: a próxima pessoa herda
o instrumento, não o problema.

---

## 7. Política de divergência

Achou um número que não bate com o C++:

1. **Investigue até zerar.** Vá ao `.cpp` correspondente, leia a função, compare passo a passo.
   As causas mais comuns, em ordem de frequência:
   - **divisão inteira**: o C++ usa `int` onde o Dart usa `double` (ou vice-versa). `a / b` em Dart
     é divisão real; o equivalente de `int/int` do C++ é `a ~/ b`, que **trunca para zero**, enquanto
     `(a / b).floor()` arredonda para baixo. Para negativos os dois diferem.
   - **ordem de avaliação** trocada por um refactor "idiomático".
   - **arredondamento**: `round()` do Dart arredonda .5 para longe do zero; o C++ costuma usar
     truncamento implícito ou `std::round`.
   - um functor que ainda não existe, e cujo efeito você atribuiu a outro lugar.
   - `kAcceptChain` faltando a entrada da classe (o functor não visita o nó, silenciosamente).
2. **Se travar de verdade**, documente a divergência no relatório: qual arquivo, qual valor esperado,
   qual obtido, e **uma hipótese nomeada de causa** apontando função e linha do C++. Depois **siga
   para a próxima tarefa**. Uma divergência documentada é um resultado; uma divergência escondida é
   um defeito.
3. **Nunca "ajuste o esperado" para o teste passar.** Não afrouxe tolerância, não adicione o arquivo
   a uma skip-list, não troque `expect` por `expect(..., anything)`. Se você precisou fazer isso, a
   tarefa não está pronta.

---

## 8. Regras de higiene

1. **Não apague nem desabilite um teste que passou a falhar.** Se a sua mudança quebrou um teste,
   ou o teste estava errado (prove citando o C++, conserte-o e explique no relatório) ou a sua
   mudança está errada (conserte a mudança). `skip: true` é inaceitável sem justificativa citando o
   C++ no relatório.
2. **Não afrouxe tolerância** para fechar tarefa (ver seção 7.3).
3. **Não invente API que não existe no C++.** Se você precisou de um método auxiliar que o C++ não
   tem, prefixe com `_` (privado), documente que é auxiliar do port, e não o exponha.
4. **Não faça refatoração oportunista fora do escopo da tarefa.** Viu um defeito noutro arquivo?
   **Anote no relatório, na seção "Achados fora de escopo"**, e siga. Cada prompt tem uma seção
   "Fora de escopo" que você deve respeitar.
5. **Não toque em `origin/`.** É a referência. Somente leitura.
6. **Não mexa nos 623 arquivos de `test/golden/cpp/`** a menos que a tarefa seja regerá-los, e nesse
   caso use `./tool/golden.sh`.
7. **Uma tarefa, uma fatia.** Se a fatia estourou muito além do previsto no prompt, pare, entregue o
   que está completo e coerente, e registre no relatório o que ficou de fora e por quê. Fatiar mal é
   melhor do que entregar meia implementação misturada.

---

## 9. Formato do relatório

Ao terminar, grave **`verovio_dart/prompts/reports/<id>.md`**, onde `<id>` é o id do prompt
(ex.: `04a`, `05-07`, `06-11`). Template:

```markdown
# <id> — <título da tarefa>

**Data:** AAAA-MM-DD
**Status:** concluída | concluída com divergências | parcial

## O que foi feito
<Lista curta. Arquivos criados/alterados com contagem de linhas.>

## Referência C++ usada
<Arquivos e faixas de linha de origin/ que você efetivamente leu e portou.>

## Verificação

### dart analyze
```
<saída real, colada>
```

### dart test
```
<saída real: N testes, resultado>
```

### <verificação específica da tarefa>
```
<comando + saída real>
```

## Divergências em aberto
<Uma entrada por divergência: arquivo, valor esperado (C++), valor obtido (Dart),
hipótese de causa com função e linha do C++. "Nenhuma" se for o caso.>

## Desvios do C++ introduzidos
<Cada bloco `Deviations from the C++:` que você escreveu, e por quê. "Nenhum" se for o caso.>

## Achados fora de escopo
<Defeitos que você viu e deliberadamente não consertou, para a próxima pessoa. "Nenhum" se for o caso.>
```

E **marque o checkbox correspondente no `PLANO.md`** (a linha está citada no seu prompt).

**Quando o checkbox do `PLANO.md` cobre mais de uma tarefa** — acontece: o plano é mais grosso que a
série de prompts (o item "Export MIDI … (06-14 a 06-17)", por exemplo, cobre quatro) — a regra é:

- marque `[x]` **só quando a última tarefa daquele item terminar**;
- nas tarefas intermediárias, deixe `[ ]` e acrescente ao fim da linha um sufixo de progresso:
  `— 06-14 ✓, 06-15 ✓` e assim por diante.

Assim o `PLANO.md` continua sendo verdade sobre o que está pronto, que é a única coisa que ele
precisa ser. Nunca marque `[x]` por antecipação.

---

## 10. Checklist final antes de fechar qualquer tarefa

- [ ] Todo método/classe novo tem doc comment citando o contraparte C++.
- [ ] Todo desvio forçado pelo Dart tem bloco `Deviations from the C++:`.
- [ ] Nenhum arquivo `GENERATED FILE` editado à mão sem registro no relatório.
- [ ] Classe nova: `ClassId` + registro no factory + `kAcceptChain` se preciso.
- [ ] `dart analyze` ≤ baseline (8).
- [ ] `dart test` verde, contagem ≥ 281.
- [ ] A verificação específica da tarefa roda e dá o resultado que o prompt exige.
- [ ] `dart format` rodado **só nos arquivos da tarefa**.
- [ ] Relatório em `prompts/reports/<id>.md`.
- [ ] Checkbox marcado no `PLANO.md`.
- [ ] Se a tarefa instrumentou o C++: patch versionado em `cpp_probe/patches/`, sem linhas
      removidas, e SVG do binário instrumentado idêntico ao do limpo.
- [ ] Nada em `origin/` foi tocado.
