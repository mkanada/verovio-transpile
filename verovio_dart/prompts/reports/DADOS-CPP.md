# DADOS-CPP — instrumentação do C++ e extração de dados de referência para a Fase 4

**Data:** 2026-08-27
**Status:** concluída

## O que foi feito

Construída a máquina de extração de dados de referência do C++, provada ponta a ponta, e reescrita
a série de prompts da Fase 4 para usá-la. **Nenhum functor da Fase 4 foi implementado.**

| Arquivo | Linhas | O que é |
|---|---:|---|
| `cpp_probe/sync.sh` | 65 | `origin/src` → `build-probe/src` via rsync, incremental |
| `cpp_probe/patch.sh` | 64 | aplica a pilha de `patches/ORDER` até um id |
| `cpp_probe/mkpatch.sh` | 64 | grava `patches/<id>.patch` = diff da sua contribuição sobre as anteriores |
| `cpp_probe/build.sh` | 46 | sync + patch + cmake/ninja incremental |
| `cpp_probe/run.sh` | 136 | roda o binário instrumentado, grava o `.jsonl` com o cabeçalho `_meta` |
| `cpp_probe/README.md` | 160 | como funciona, o esquema do fixture, a regra do `path` |
| `cpp_probe/patches/EXEMPLO.patch` | 323 | o patch de prova: `AdjustXPosFunctor` + o helper `vrvprobe.h` |
| `cpp_probe/patches/ORDER` | 25 | a pilha: `EXEMPLO 04-00 04a … 04h` |
| `verovio_dart/test/fixtures/cpp_fixture.dart` | 374 | leitor + comparador + `cppPath()` |
| `verovio_dart/test/cpp_fixture_test.dart` | 338 | 16 testes: o leitor e a prova ponta a ponta |
| `verovio_dart/test/fixtures/cpp/EXEMPLO/note-001.mei.jsonl` | 27 | o fixture de referência, versionado |

Prompts reescritos: `04-00` (novo), `04a`–`04h` (seção *Dados de referência do C++*, passo fixo de
extração, protocolo de re-instrumentação, 3 critérios novos), `04j` (consome os 9 fixtures).
`04i` **não foi tocado**, como o meta-prompt pediu.

Convenções: `00-MESTRE.md` §6-bis (nova), `prompts/README.md`, `.gitignore`, `CLAUDE.md`, `PLANO.md`.

## Referência C++ usada

- `origin/src/src/adjustxposfunctor.cpp` (418 linhas) — o functor instrumentado no `EXEMPLO`.
- `origin/src/src/page.cpp:396-497` (`Page::LayOutHorizontally`) — os pontos de chamada e as duas
  passadas de `AdjustXPos`.
- `origin/src/include/vrv/object.h`, `boundingbox.h:42`, `measure.h:200-203`, `layer.h:188-229` —
  a API de leitura da árvore que `vrvprobe.h` usa (`GetParent`, `GetChildren`, `GetClassName`,
  `GetID`, `Is`, e os objetos-membro de `Measure` e `Layer`).
- `origin/src/src/options.cpp:286-289, 366-369, 980-984, 1100-1120, 1198-1199` e
  `origin/src/include/vrv/vrvdef.h:453,455` — o fator de definição e a opção `xmlIdSeed`.
- `origin/src/src/doc.cpp:2022-2025` (`Doc::GetDrawingUnit`) e
  `origin/src/src/horizontalaligner.cpp:759-768` (`Alignment::HorizontalSpaceForDuration`) —
  os dois lados do achado 1.
- `origin/src/tools/get_git_commit.sh` e `origin/src/cmake/CMakeLists.txt:132-136` — por que o
  binário instrumentado carimbava uma versão diferente.

## Verificação

### A prova ponta a ponta (seção 4.3 do meta-prompt), os cinco passos

**1. `cpp_probe/build.sh EXEMPLO` compila sem erro**

```
[1/4] Building CXX object CMakeFiles/verovio.dir/.../build-probe/src/src/adjustxposfunctor.cpp.o
[2/4] Building CXX object CMakeFiles/verovio.dir/.../build-probe/src/src/page.cpp.o
[3/4] Building CXX object CMakeFiles/verovio.dir/.../build-probe/src/src/vrv.cpp.o
[4/4] Linking CXX executable verovio
cpp_probe/build.sh: .../build-probe/build/verovio pronto (patches até EXEMPLO)
```

O `rsync` preserva os mtimes, então uma alteração no patch recompila 4 arquivos, não os ~290.

**2. `cpp_probe/run.sh` grava um `.jsonl` válido**

```
cpp_probe/run.sh: verovio_dart/test/fixtures/cpp/EXEMPLO/note-001.mei.jsonl (26 registros, semente 12345)
```

`run.sh` valida cada linha com `json.loads` antes de gravar e aborta se alguma não parsear.
Conferido também com `jq`: todas as 27 linhas (1 `_meta` + 26 registros) parseiam.

**3. Duas execuções seguidas produzem arquivos byte a byte idênticos**

```
$ cmp /tmp/r1.jsonl /tmp/r2.jsonl && md5sum /tmp/r1.jsonl /tmp/r2.jsonl
ada4607594e7ca73a9e5cdd268178f55  /tmp/r1.jsonl
ada4607594e7ca73a9e5cdd268178f55  /tmp/r2.jsonl
```

**4. O binário instrumentado produz SVG idêntico ao do limpo — 8 arquivos, `diff` vazio**

```
SVG idêntico   note/note-001.mei             27601 bytes      26 registros
SVG idêntico   layer/layer-001.mei           36350 bytes     112 registros
SVG idêntico   dot/dot-001.mei               62551 bytes     392 registros
SVG idêntico   accid/accid-001.mei           32583 bytes     100 registros
SVG idêntico   beam/beam-001.mei             25894 bytes      32 registros
SVG idêntico   tuplet/tuplet-001.mei         59924 bytes     224 registros
SVG idêntico   section/section-001.mei      247987 bytes    1190 registros
SVG idêntico   score/score-002.mei          111356 bytes     636 registros
```

E o patch não remove nada:

```
$ cpp_probe/mkpatch.sh EXEMPLO
cpp_probe/mkpatch.sh: .../cpp_probe/patches/EXEMPLO.patch (3 arquivos, 244 linhas acrescentadas, 0 removidas)
$ grep -c '^-[^-]' cpp_probe/patches/EXEMPLO.patch
0
```

**5. O leitor Dart carrega o fixture e compara com `lib/src/layout/adjust_x_pos.dart`**

Rodou, e **não bateu** — o que, pela própria seção 4.3, é um achado real da Fase 4. Está na seção
*Divergências em aberto*, com hipótese de causa.

### dart analyze

```
10 issues found.
```

Baseline mantida (8 em `tool/_scratch_*`, 2 em `test/`).

### dart test

```
00:17 +281: All tests passed!
```

265 da baseline + **16 novos** em `test/cpp_fixture_test.dart`.

### dart run tool/validate_layout.dart

```
| Category | Files | Laid out | Sanity checks | Timemap vs C++ |
|---|---|---|---|---|
| ? | 46 | 46 | 46 | 24/30 clean |
```

Sem regressão: 24/30, e `tool/LAYOUT_VALIDATION.md` sai idêntico ao versionado
(`git status` limpo nele).

### origin/ intocado

```
$ git status --short origin/
$
```

Vazio.

## Divergências em aberto

As duas foram encontradas pela própria máquina, no primeiro arquivo instrumentado
(`test/corpus/note/note-001.mei` — um compasso: pausa, nota, pausa). Nenhuma foi corrigida nesta
sessão; as duas são o escopo da tarefa **04-00**, criada por causa delas.

### 1. `DEFINITION_FACTOR` nunca aplicado pelas opções — sistêmico

| | C++ | Dart |
|---|---:|---:|
| `Doc::GetDrawingUnit(100)` | **90** | **9** |

**Causa, verificada:** `OptionDbl::GetValue()` (`origin/src/src/options.cpp:286-289`) e
`OptionInt::GetValue()` (`:366-369`) devolvem `m_value * DEFINITION_FACTOR` quando a opção foi
inicializada com `definitionFactor = true`. São **7** opções — `m_unit` (`options.cpp:1199`),
`m_pageWidth`, `m_pageHeight` e as quatro margens (`:1100-1120`). O `lib/src/core/options_shell.dart`
define `definitionFactor = 10` em `lib/src/core/vrvdef.dart:31` mas **nunca o usa**;
`Doc.getDrawingUnit` (`lib/src/model/doc.dart:1792`) espelha o C++ corretamente — era a opção que
mentia.

**Alcance medido:** 7 opções, **65** chamadas de `getDrawingUnit`/`getDrawingDoubleUnit`/
`getDrawingStaffSize` em **18** arquivos de `lib/src/`, mais `drawingPageWidth`/`Height`/as quatro
margens em `doc.dart:1386-1391`.

**O que faz isto ser grave e não um fator global inofensivo:** `Alignment::HorizontalSpaceForDuration`
(`origin/src/src/horizontalaligner.cpp:759-768`) está portado fielmente — o `* 10.0` de lá é
constante experimental, não o `DEFINITION_FACTOR` — e produz o **mesmo** passo (690 em `note-001`)
dos dois lados, enquanto o deslocamento inicial derivado da unidade sai 90 no C++ e 9 no Dart.
**O port mistura duas escalas.** Não dá para corrigir dividindo a saída.

### 2. O alinhador horizontal perde tempo em parte do corpus

Em `note-001.mei`, a pausa e a nota compartilham **o mesmo objeto `Alignment`** em `time = 0.0`, e o
compasso termina em `0.25` semibreve (1 quarto) onde o C++ vê 3 quartos — o timemap do C++ põe a
nota em `qstamp 1`.

**Escopo medido no corpus inteiro** (621 arquivos, antes de qualquer correção):

| Medida | Valor |
|---|---|
| Compassos com `measureAligner.maxTime == 0` | **166 de 2107 (7,9 %)** |
| Arquivos com duração total 0 apesar de terem música | **8 de 621** |

**Hipótese, não confirmada:** a duração devolvida por `getAlignmentDuration`
(`lib/src/layout/align_horizontally.dart:550-575`, espelhando
`origin/src/src/layerelement.cpp:661`) é 0 para uma classe de elementos que no C++ tem duração. A
correlação **não é simplesmente "pausa"**: `beam/beam-001.mei`, `layer/layer-001.mei` e
`dot/dot-001.mei` batem, e `rest/rest-004.mei` e `rest/rest-005.mei` também, apesar de terem pausas.
O fixture de duração por elemento que a `04-00` manda extrair é o que vai dizer qual elemento é.

**Por que 265 testes verdes não pegaram nada disto:** os testes de layout asseguram *estrutura* —
xRel monotônico, não-nulo, não-zero (`test/horizontal_layout_test.dart:63-88`) — e quase nunca
*valor*; e o `tool/validate_layout.dart` calcula onsets de `DurationInterface.scoreTimeOnset` com
`--breaks none` (`tool/validate_layout.dart:326-369`), ou seja, valida o pipeline de duração e não
o alinhador horizontal. Os "24/30 timemaps batendo" continuam verdadeiros e continuam não dizendo
nada sobre estes dois achados.

### 3. Ordem de travessia dentro de uma referência de alinhamento

O C++ visita `note[1]`, `stem[1]`, `accid[1]`; o Dart visita `note[1]`, `accid[1]`, `stem[1]`. Com
as bounding boxes vazias isso não muda número nenhum hoje, mas muda quando elas existirem (05-12),
porque `AdjustXPos` compara pares consecutivos. Registrado aqui, sem tarefa dona.

## Desvios do C++ introduzidos

Nenhum no port. Três decisões de projeto na máquina de extração, todas documentadas em
`cpp_probe/README.md`:

1. **A regra do `path` não é a sugerida pelo meta-prompt.** A sugestão era `m<n>/s<n>/l<n>/…`; a
   forma adotada é **`<classeMei>[<chave>]` em todo segmento**, com a chave saindo de `@n`, depois
   de um token de papel, depois do índice entre irmãos da mesma classe. Motivo: sem o token de papel
   três caminhos de `note-001.mei` saíam com chave `?` e colidiam — `Measure::m_leftBarLine` e
   `m_rightBarLine` têm o compasso como pai mas **não** estão na lista de filhos dele, e o mesmo
   vale para os `staffDef` clef/keySig/meterSig que o `AlignHorizontally` materializa numa `Layer`.
   Manter `m1/s1/l1` e `barLine[left]` lado a lado seriam dois formatos convivendo; a forma única
   com bracket cobre os dois casos com uma regra só. O caminho é enraizado no `measure` porque a
   que sistema um compasso pertence muda com o cast-off.

2. **O patch acrescenta um header, não só `fprintf`.** Das 244 linhas acrescentadas, **223** são o
   novo `include/vrv/vrvprobe.h` (helpers de caminho, escape JSON, contador de passada, stream de
   saída), **18** são a instrumentação de `adjustxposfunctor.cpp` e **3** são o `#include` e os dois
   `probe::BeginPass` em `page.cpp`. Nada ali é chamado pelo
   código de gravação: os helpers só **leem** a árvore e escrevem texto, e nenhum valor que o Verovio
   calcula passa por eles. A prova é o passo 4 acima — SVG idêntico em 8 arquivos — mais
   `grep -c '^-[^-]' = 0`.

3. **`sync.sh` neutraliza `tools/get_git_commit.sh`.** O script original carimba o SHA do
   repositório no binário (`Verovio 6.2.0-f997a93`) e esse texto sai no `<desc>` do SVG; o binário
   limpo em `build/` foi compilado antes de o workspace virar um repositório git e diz só
   `Verovio 6.2.0`. Sem neutralizar, a verificação "o SVG do instrumentado é idêntico ao do limpo"
   acusava uma diferença que não tem nada a ver com a instrumentação — e que mudaria a cada commit.
   O arquivo fica fora do diff do patch, então a instrumentação continua sendo só instrumentação.

Uma decisão a mais, sobre o teste: os dois testes de comparação numérica do `EXEMPLO` afirmam a
**contagem medida** de divergências (9 para `xRel_in`, 10 para `xRel_out`), não `isEmpty`. É um
teste de caracterização, marcado como tal no código: se o número **cair**, o port melhorou e o
teste manda atualizá-lo (ou trocar por `isEmpty` ao chegar a zero); se **subir**, é regressão. O que
ele assere de fato — e que é o valor real — é a **paridade estrutural**: o `AdjustXPos` do Dart
visita exatamente os mesmos 10 elementos que o C++, casados por caminho.

## Achados fora de escopo

- **`dart format lib/ test/ tool/`, que o `00-MESTRE.md` §3 mandava rodar, quebra a baseline.** O
  formatador atual reescreve **53** arquivos que ninguém tocou e leva o `dart analyze` de 10 para 20
  issues, criando `curly_braces_in_flow_control_structures` em código existente. Revertido, e a
  instrução corrigida em `00-MESTRE.md` §3, `CLAUDE.md` e `prompts/README.md`: formate só os arquivos
  da sua tarefa.
- **`00-MESTRE.md` §2 e `CLAUDE.md` diziam que o workspace não é um repositório git.** É desde
  2026-08-26, e o fluxo novo depende de `git diff`/`git status`. Corrigido nos dois.
- **`04i` continua citando `dart test ≥ 302` / `≥ 306`.** Não foi tocado, por instrução explícita do
  meta-prompt. Os números seguem verdadeiros como piso (a contagem real ao chegar lá será ≥ 340),
  só estão frouxos.
- **A cadeia de contagens de teste foi recalculada** a partir da baseline nova de 281:
  `04-00` ≥ 287, `04a` ≥ 293, `04b` ≥ 300, `04c` ≥ 307, `04d` ≥ 313, `04e` ≥ 320, `04f` ≥ 326,
  `04g` ≥ 334, `04h` ≥ 340, `04j` ≥ 346.

## Serve para as Fases 5–7?

Serve, e sem mudança de desenho. O `path`, o `_meta`, a semente fixa e o leitor Dart são agnósticos
de fase: a Fase 5 pode instrumentar `View::Draw*` e comparar coordenadas de SVG antes de o
`compare_svg.dart` existir, e a Fase 6 pode dumpar a árvore parseada pelo C++ para validar os
leitores com muito mais força do que o histograma de elementos do `validate_io.dart` — que é o
oráculo de hoje e só pega elemento faltando, não atributo errado. Nada disso foi estendido nesta
sessão, por decisão do meta-prompt.
