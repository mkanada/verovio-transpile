# Meta-prompt — instrumentação do C++ e extração de dados de referência para a Fase 4

Cole este arquivo inteiro como primeira mensagem de uma sessão nova do Claude Code aberta em
`/home/mauricio/rust_projects/verovio-transpile`.

---

## 1. O problema que esta sessão resolve

A série de prompts em `verovio_dart/prompts/` está sendo executada. Na prática, as sessões que
implementam os functors da Fase 4 **vão e voltam por falta de dado**: o prompt manda espelhar o C++
e comparar números, mas o único oráculo disponível hoje é `build/verovio -t timemap` (onsets) e os
SVGs de `test/golden/cpp/` (que só existem depois da Fase 5). Os valores intermediários que o
functor realmente produz — `drawingXRel`, `drawingYRel`, extensões de bounding box, deslocamentos —
**não estão em lugar nenhum**. A LLM implementa no escuro, roda o teste, não bate, e não tem como
saber em qual functor a divergência começou.

Esta sessão conserta isso: dá a cada tarefa 04* a capacidade de **instrumentar o C++ original e
extrair os valores de que ela precisa, no curso da própria tarefa**, gravando-os como fixtures
versionados que os testes Dart consomem.

**Você não implementa nenhum functor nesta sessão.** Você constrói a máquina de extração, prova que
ela funciona, e reescreve oito prompts para usá-la.

## 2. O repositório

Port linha a linha do **Verovio 6.2.0** (biblioteca C++ de gravação musical: MEI/MusicXML/ABC → SVG)
para **Dart puro**. O objetivo é equivalência funcional com o C++.

| Caminho | Papel |
|---|---|
| `origin/src/` | Fontes C++ 6.2.0 originais — a referência de toda decisão. **Somente leitura, sem exceção.** |
| `build/verovio` | CLI C++ compilado (Release, `NO_HUMDRUM_SUPPORT=ON`). Binário limpo, não instrumentado. |
| `verovio_dart/` | O package Dart. |
| `verovio_dart/prompts/` | A série de prompts de execução. `README.md` é o índice; `00-MESTRE.md` são as convenções; `AUDITORIA.md` é o estado medido em 2026-08-26. |
| `PLANO.md` | Roadmap de escopo. |
| `CLAUDE.md` | Convenções do repositório. |

**É um repositório git** (inicializado em 2026-08-26, remoto privado `mkanada/verovio-transpile`).
Você pode e deve usar `git diff` e `git status`. Commits ficam a critério do dono do projeto — não
faça push.

Comandos, sempre a partir de `verovio_dart/`:

```bash
dart test        # baseline: 265 testes verdes, ~15 s
dart analyze     # baseline: 10 issues (8 em tool/_scratch_*, 2 em test/)
dart run tool/validate_layout.dart
```

Binário C++ limpo, a partir da raiz:

```bash
./build/verovio -r verovio_dart/assets/data -o /tmp/out.svg entrada.mei
./build/verovio -r verovio_dart/assets/data -t timemap -o /tmp/tm.json entrada.mei
```

## 3. Decisões já tomadas pelo dono do projeto — **não reabra nenhuma**

1. **`origin/src/` permanece intocado.** A instrumentação vive como **patches versionados** em
   `cpp_probe/patches/<id>.patch`, aplicados sobre uma cópia em árvore de trabalho ignorada pelo git.
2. **Formato dos dados: JSON Lines** (`.jsonl`), um objeto por linha, em
   `verovio_dart/test/fixtures/cpp/<id>/<arquivo-do-corpus>.jsonl`. Os fixtures **são versionados**.
3. **Escopo: só a Fase 4, por enquanto.** `04a`–`04h` passam a extrair dados; `04j` (revalidação)
   ganha um critério agregado que os consome; **`04i` não é tocado** (é higiene pura — gerador,
   registros do `ObjectFactory`, bug de interpolação — não há número do C++ a extrair).
4. **A extração acontece no curso da tarefa**, não como etapa separada: cada prompt ganha um passo
   fixo que estabelece o fixture-base logo depois de ler o C++, **mais** um protocolo explícito de
   voltar e instrumentar mais fundo quando um valor divergir. Este segundo ponto é o motivo de tudo:
   é o que impede a LLM de ficar adivinhando.
5. **Granularidade: antes/depois por functor.** Para cada elemento que o functor toca, o valor
   entrando e o valor saindo. É o que permite localizar **em qual** functor o Dart divergiu, e não
   apenas que divergiu.
6. **Chave dos registros: caminho estrutural + id**, casando pelo caminho. A geração de id do Dart
   nunca foi verificada contra a do C++; casar por id apostaria numa paridade que ninguém mediu.
7. **Cobertura: os arquivos que cada prompt já cita nos seus testes.** Quando o prompt cita uma
   categoria inteira em vez de arquivos nomeados, a tarefa escolhe de 2 a 4 arquivos dela e
   **grava a escolha no próprio prompt**, para o conjunto ficar fixado.
8. **Build: árvore única, patches acumulados.** Um só diretório instrumentado, ignorado pelo git,
   onde cada tarefa aplica o seu patch por cima dos anteriores; o ninja recompila só o que mudou.
9. **A instrumentação não pode alterar comportamento.** Só `fprintf`. O binário instrumentado tem de
   produzir SVG idêntico ao do binário limpo — e isso é critério de aceite verificável.

## 4. Etapa 1 — construir a infraestrutura e **provar** que ela funciona

Antes de tocar em qualquer prompt, construa e exercite a máquina. Se ela não funcionar aqui, oito
sessões vão descobrir isso uma a uma.

### 4.1 `cpp_probe/`

Crie, na raiz do workspace:

```
cpp_probe/
  README.md            # como funciona, em 20 linhas
  sync.sh              # origin/src -> build-probe/src via rsync, sem apagar objetos do ninja
  patch.sh <id>...     # aplica patches/<id>.patch acumulados, em ordem
  build.sh <id>        # sync + patch até <id> + cmake/ninja incremental
  run.sh <id> <mei> <saida.jsonl>   # roda o binário instrumentado e grava o fixture
  patches/
    EXEMPLO.patch      # o patch de prova da etapa 4.3
```

Requisitos:

- `sync.sh` usa `rsync` (não `cp -r`) para preservar os artefatos do ninja e manter o rebuild
  incremental. O destino é `build-probe/`, **ignorado pelo git**.
- `build.sh` compila com as mesmas flags do binário limpo:
  `cmake -S <src>/cmake -B <build> -G Ninja -DCMAKE_BUILD_TYPE=Release -DNO_HUMDRUM_SUPPORT=ON`.
- `run.sh` **sempre** passa `-x <semente-fixa>` (a opção `xmlIdSeed`, short `-x`, existe em
  `origin/src/src/options.cpp:980-984` e por padrão é aleatória). Fixe a semente e documente o valor
  em `cpp_probe/README.md`. Sem isso, os ids mudam a cada execução e o fixture deixa de ser
  reproduzível.
- Os scripts falham com mensagem clara se `origin/src` não existir, se um patch não aplicar, ou se
  o build falhar. Nada de falha silenciosa.

### 4.2 O esquema do fixture

Um objeto JSON por linha. Campos obrigatórios em todo registro:

```json
{"fn":"AdjustLayers","pass":1,"path":"m1/s1/l2/note[3]","id":"n1a2b3","xRel_in":420,"xRel_out":455}
```

| Campo | Significado |
|---|---|
| `fn` | nome do functor C++ que produziu o registro |
| `pass` | número da passada, quando o mesmo functor roda mais de uma vez (`AdjustLayers` roda duas) — omita quando não se aplica |
| `path` | **a chave de casamento**: caminho estrutural estável até o elemento |
| `id` | o `@xml:id`, para leitura humana e conferência contra o SVG do C++ |
| `<campo>_in` / `<campo>_out` | o valor antes e depois do functor |

Defina o formato de `path` **uma vez** e documente-o em `cpp_probe/README.md`; ele tem de ser
derivável identicamente dos dois lados. Sugestão: `m<n>/s<n>/l<n>/<classe>[<índice 1-based entre
irmãos da mesma classe>]`, com os `<n>` vindos do `@n` de measure/staff/layer. Se algum caso do
corpus não couber nessa forma, ajuste o esquema e registre por quê — mas **não** deixe dois formatos
conviverem.

A primeira linha de cada arquivo é um cabeçalho de proveniência, para o fixture não virar um número
órfão daqui a três semanas:

```json
{"_meta":{"task":"04a","source":"test/corpus/layer/layer-001.mei","xmlIdSeed":12345,"verovio":"6.2.0","patches":["04a"],"generated":"2026-08-27"}}
```

### 4.3 O patch de prova

Escreva `cpp_probe/patches/EXEMPLO.patch` instrumentando **um functor que já está portado em Dart**
— `AdjustXPosFunctor` (`origin/src/src/adjustxposfunctor.cpp`) é uma boa escolha, porque
`lib/src/layout/adjust_x_pos.dart` já existe e pode ser comparado de imediato.

Prove, ponta a ponta, e cole a saída de cada passo no relatório:

1. `cpp_probe/build.sh EXEMPLO` compila sem erro.
2. `cpp_probe/run.sh EXEMPLO test/corpus/note/note-001.mei /tmp/e.jsonl` grava um `.jsonl` válido
   (`python3 -c` ou `jq` confirmando que toda linha parseia).
3. **Duas execuções seguidas produzem arquivos byte a byte idênticos** (reprodutibilidade).
4. **O binário instrumentado produz SVG idêntico ao do binário limpo** para ao menos 5 arquivos do
   corpus — `diff` vazio. Este é o passo que prova que a instrumentação não mudou comportamento.
   Se divergir, o patch tem lógica onde deveria ter só `fprintf`.
5. O leitor Dart (4.4) carrega o arquivo e os valores batem com os do
   `lib/src/layout/adjust_x_pos.dart` já portado — ou, se não baterem, **isso é um achado real da
   Fase 4** e vai para o relatório com hipótese de causa.

### 4.4 O leitor no lado Dart

Crie `verovio_dart/test/fixtures/cpp_fixture.dart`:

- carrega um `.jsonl` pelo par (tarefa, arquivo do corpus);
- expõe consulta por `fn` + `path` (+ `pass`);
- oferece um comparador que, dado o objeto Dart e o campo, devolve **a lista de divergências** com
  caminho, valor esperado (C++) e valor obtido (Dart) — não um booleano. A mensagem de falha é o
  produto aqui;
- erra alto e claro se o fixture não existir, em vez de passar vazio. Um teste que passa porque o
  fixture sumiu é pior do que nenhum teste.

Escreva `verovio_dart/test/cpp_fixture_test.dart` cobrindo o leitor: arquivo bem formado, arquivo
ausente, `path` inexistente, cabeçalho `_meta` presente.

## 5. Etapa 2 — reescrever os prompts `04a`–`04h`

Cada um dos oito ganha as mudanças abaixo. **Preserve o template da seção 7 do `META_PROMPT.md`** —
as oito seções, na mesma ordem. Você está acrescentando, não redesenhando.

### 5.1 Nova seção `## Dados de referência do C++`

Entre `## Referência C++` e `## Arquivos Dart a criar/alterar`. Conteúdo, concreto por tarefa:

- **quais valores** esta tarefa precisa medir (ex.: 04a → `drawingXRel` de notas e de `Dots`;
  04c → `drawingXRel`/`drawingYRel` de `TupletBracket` e `TupletNum`);
- **quais funções C++ instrumentar**, nominais, com arquivo e linha;
- **quais arquivos do corpus**, nomeados. Onde o prompt hoje cita só uma categoria, escolha de 2 a 4
  arquivos e **escreva-os aqui**. O que cada prompt cita hoje:

  | Tarefa | Citado hoje | Ação |
  |---|---|---|
  | `04a` | `layer/layer-001.mei`, `dot/dot-001.mei` | usar esses |
  | `04b` | `accid/accid-001.mei`, `artic/artic-001.mei` | usar esses |
  | `04c` | `tuplet/tuplet-001.mei` + categoria `tuplet/` | escolher +1 ou +2 com quiáltera aninhada |
  | `04d` | categorias `beam/`, `cross-staff/`, `clef/` | escolher 3–4 (beam simples, cross-staff, beam com pausa) |
  | `04e` | categorias `harm/`, `tempo/`, `lyric/` | escolher 3–4, **incluindo `lyric/lyric-001.mei`** (timemap diverge hoje) |
  | `04f` | `section/section-001.mei` + categorias `beamspan/`, `dir/`, `dynam/` | escolher 3–4, **incluindo `section/section-001.mei`** (timemap diverge hoje) |
  | `04g` | categorias `ossia/`, `neume/`, `note/` | escolher 3–4 |
  | `04h` | categorias `ossia/`, `score/` | escolher 2–3 |

- **o caminho exato dos fixtures**: `test/fixtures/cpp/<id>/<nome-do-arquivo>.jsonl`;
- os comandos literais de gerar e regenerar.

### 5.2 Novos passos no `## Passo a passo`

**Um passo fixo, cedo** — logo depois de ler o C++ e antes de escrever Dart:

> Escreva `cpp_probe/patches/<id>.patch` instrumentando as funções listadas em *Dados de referência
> do C++*. Rode `cpp_probe/build.sh <id>` e gere os fixtures com `cpp_probe/run.sh`. Confira que o
> binário instrumentado ainda produz SVG idêntico ao do limpo. **Leia os fixtures antes de escrever
> a primeira linha de Dart** — eles dizem o que o functor faz de verdade, caso a caso, melhor do que
> a leitura do `.cpp`.

**E um protocolo de re-instrumentação**, no fim do passo a passo — este é o coração do pedido:

> Se um valor do Dart não bater com o fixture, **não adivinhe e não ajuste o esperado**: volte ao
> patch, instrumente mais fundo dentro da função divergente (valores intermediários, o ramo do `if`
> tomado, o resultado de cada helper), regere o fixture e compare de novo. Cada rodada de
> instrumentação estreita o intervalo onde a divergência nasce. Só declare a divergência
> irredutível — pela política da seção 7 do `00-MESTRE.md` — depois de ter instrumentado até o nível
> da expressão. O patch fica versionado com o nível de detalhe a que você chegou; a próxima pessoa
> herda o instrumento, não o problema.

### 5.3 Três critérios de aceite novos

Acrescente aos que já existem, sem remover nenhum:

```markdown
- [ ] `cpp_probe/patches/<id>.patch` versionado, contendo **apenas** `fprintf` (nenhuma alteração
      de lógica) — prove com `git diff` do patch no relatório
- [ ] `cpp_probe/build.sh <id> && cpp_probe/run.sh <id> …` reproduz os fixtures do zero, e o binário
      instrumentado produz SVG idêntico ao do binário limpo para os arquivos desta tarefa
- [ ] N valores do fixture comparados com o Dart em epsilon 0; o relatório traz N, quantos batem, e
      cada divergência restante com hipótese de causa nomeando função e linha do C++
```

Ajuste também a contagem esperada de `dart test` de cada prompt — ela sobe com os testes de fixture.
E acrescente ao `## Fora de escopo` que a tarefa **não** instrumenta functors de outras tarefas.

### 5.4 Corrija a cadeia de pré-condições

Cada prompt confere em 30 segundos que o anterior terminou. Com a infraestrutura nova, `04a` passa a
depender também de `cpp_probe/` existir. Acrescente às pré-condições de `04a`:

```bash
ls cpp_probe/build.sh verovio_dart/test/fixtures/cpp_fixture.dart
```

e às de `04b`–`04h`, a verificação de que o fixture da tarefa anterior existe.

## 6. Etapa 3 — `04j` (revalidação da Fase 4)

`04j` não produz fixtures; ela **consome os oito**. Acrescente:

- um passo que roda `cpp_probe/build.sh 04h` (a árvore acumulada tem todos os patches) e regera
  **todos** os fixtures do zero, provando que continuam reproduzíveis depois de oito tarefas;
- um critério de aceite agregado:

```markdown
- [ ] Os 8 fixtures de `test/fixtures/cpp/` são regenerados do zero e ficam byte a byte idênticos
      aos versionados; o relatório traz o total de valores comparados na Fase 4 e quantos batem
```

- uma seção no relatório dela consolidando, por tarefa, quantos valores batem — é o retrato honesto
  de quanto da Fase 4 está de fato equivalente ao C++.

## 7. Etapa 4 — convenções e índice

1. **`verovio_dart/prompts/00-MESTRE.md`** ganha uma seção nova, `## 6-bis. Extraindo dados de
   referência do C++`, entre o procedimento de verificação e a política de divergência. Ela explica
   o fluxo `cpp_probe/`, o esquema do `.jsonl`, a regra do `path`, a semente fixa, e a proibição de
   instrumentação que altere lógica. Esta é agora uma convenção permanente do repositório, não um
   detalhe de oito prompts.
2. **`verovio_dart/prompts/README.md`**: a tabela de métricas ganha uma linha
   (`Fixtures do C++ | test/fixtures/cpp/ | 0 | 8 tarefas cobertas`), e o bloco de armadilhas ganha
   a de instrumentação (só `fprintf`; semente fixa; SVG tem de continuar idêntico).
3. **`.gitignore`**: acrescente `/build-probe/` com um comentário dizendo o que é e como regenerar.
4. **`CLAUDE.md`**: a linha que descreve `origin/src/` como somente-leitura ganha a nota de que a
   instrumentação existe e vive em `cpp_probe/patches/`, sem tocar em `origin/`.
5. **`PLANO.md`**: acrescente, na Fase 4, um item marcado para a infraestrutura de extração.

## 8. Critérios de aceite do SEU trabalho nesta sessão

- [ ] `cpp_probe/` existe com `sync.sh`, `patch.sh`, `build.sh`, `run.sh`, `README.md` e
      `patches/EXEMPLO.patch`, todos executáveis
- [ ] `verovio_dart/test/fixtures/cpp_fixture.dart` e `test/cpp_fixture_test.dart` existem
- [ ] A prova ponta a ponta da seção 4.3 rodou, com os **cinco** passos, e a saída de cada um está
      no relatório
- [ ] O binário instrumentado produz SVG **idêntico** ao do limpo para ≥ 5 arquivos do corpus
      (`diff` vazio, colado no relatório)
- [ ] Duas execuções seguidas de `run.sh` produzem arquivos byte a byte idênticos
- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, com os testes novos do leitor de fixture (≥ 269)
- [ ] Os 8 prompts `04a`–`04h` têm a seção `## Dados de referência do C++`, o passo fixo de
      extração, o protocolo de re-instrumentação e os 3 critérios novos — **e continuam com as oito
      seções do template original**
- [ ] Todo arquivo do corpus citado nas seções novas existe (verifique com `ls`; nada de caminho
      inventado)
- [ ] `04j` consome os fixtures; `04i` **não foi tocado**
- [ ] `00-MESTRE.md`, `README.md`, `.gitignore`, `CLAUDE.md` e `PLANO.md` atualizados
- [ ] Teste de sanidade: leia `04d` inteiro como se fosse uma LLM sem contexto e confirme que dá
      para escrever o patch, gerar o fixture e implementar o functor **sem fazer nenhuma pergunta**.
      Se não der, conserte e revise os outros sete
- [ ] Relatório em `verovio_dart/prompts/reports/DADOS-CPP.md`
- [ ] Nenhum arquivo de `origin/` foi modificado — prove com `git status origin/` vazio

## 9. Proibições

- **Não modifique `origin/`.** Nem "só para testar". `git status origin/` no fim tem de estar limpo.
- Não implemente nenhum functor da Fase 4. Se der vontade de "já deixar o `AdjustLayers` pronto",
  não deixe — a tarefa é a máquina de extração.
- Não coloque lógica nos patches. Só `fprintf`. Um patch que muda um valor corrompe todos os
  fixtures que dele derivarem, silenciosamente.
- Não invente dados. Todo número que entrar num fixture sai de uma execução do C++ que você rodou.
- Não estenda para as Fases 5–7 nesta sessão. Se o desenho servir para elas — e deve —, registre
  isso em duas linhas no relatório e pare.
- Não faça `git push`.
