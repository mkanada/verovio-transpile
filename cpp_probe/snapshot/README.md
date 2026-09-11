# Snapshot de estado C++ × Dart

Guia das ferramentas que despejam o estado inteiro da árvore de objetos do Verovio,
checkpoint a checkpoint, dos dois lados do port, e dizem **onde nasce** cada divergência:

| Ferramenta | Lado | Roda de |
|---|---|---|
| `cpp_probe/snapshot.sh` | C++ (binário instrumentado de `build-probe/`) | raiz do workspace |
| `verovio_dart/tool/snapshot.dart` | Dart (o mesmo pipeline de `renderSvgForComparison`) | `verovio_dart/` |
| `verovio_dart/tool/snapshot_diff.dart` | comparador | `verovio_dart/` |
| `verovio_dart/tool/gen_snapshot_fields.dart` | gerador dos dois lados a partir do manifesto | `verovio_dart/` |

Introduzidas em 2026-09-11. Os despejos vão para `tmp/snapshot/{cpp,dart}/`, que o git ignora.

---

## Para que serve

O layout do Verovio encadeia centenas de execuções de functor por documento antes de desenhar
(um arquivo pequeno do corpus passa por ~190 checkpoints). Quando o SVG do Dart diverge do C++,
`compare_svg`/`cluster_deltas` dizem **o que** diverge no desenho e `probe_diff` diz **em que
primitiva de desenho** — mas a origem costuma estar bem antes, num functor de layout, e chega
ao desenho já propagada. Os patches pontuais de `cpp_probe/patches/` respondem a uma pergunta por
vez: alguém suspeita de um functor, instrumenta aquele functor, compara.

O snapshot inverte a ordem. Despeja o estado da árvore depois de **cada** functor de nível 0 e
de **cada** desenho de página, nos dois lados, e o comparador localiza o ponto do pipeline depois
do qual o estado deixa de bater e não volta a bater até o desenho. É bisseção no eixo do tempo,
em vez de caça.

---

## Início rápido

```bash
# uma vez (e de novo quando a pilha de patches mudar): a pilha inteira + o snapshot
cpp_probe/build.sh snapshot

# 1. hash por checkpoint dos dois lados (barato) e o comparador
cpp_probe/snapshot.sh test/corpus/arpeg/arpeg-003.mei
cd verovio_dart
dart run tool/snapshot.dart test/corpus/arpeg/arpeg-003.mei
dart run tool/snapshot_diff.dart arpeg/arpeg-003.mei
#    → o par de checkpoints onde a divergência persistente começa, e os comandos exatos
#      (com o @seq de cada lado) para despejar as linhas daquele trecho

# 2. as linhas completas, de todos os checkpoints: o relatório por campo
../cpp_probe/snapshot.sh --nivel=3 test/corpus/arpeg/arpeg-003.mei
dart run tool/snapshot.dart --nivel=3 test/corpus/arpeg/arpeg-003.mei
dart run tool/snapshot_diff.dart arpeg/arpeg-003.mei

# 3. muitos arquivos de uma vez (diretório ou lista), e o ranking
../cpp_probe/snapshot.sh --nivel=3 test/corpus/tuplet
dart run tool/snapshot.dart --nivel=3 test/corpus/tuplet
dart run tool/snapshot_diff.dart --rank            # todo arquivo despejado dos dois lados
dart run tool/snapshot_diff.dart --rank --dir=tuplet
```

`--check-svg` (nas duas ferramentas) confirma, byte a byte, que despejar não mudou o desenho.

---

## Checkpoints

Um **checkpoint** é tirado:

- quando uma chamada `Object::Process(Functor &)` retorna sem outra `Process` na pilha — um
  functor de *nível 0*, dos que `Page::LayOutHorizontally`, `Doc::CastOffDoc` etc. chamam
  diretamente. Sub-functors rodados de dentro de uma visita não contam;
- quando `View::DrawCurrentPage` termina fora de qualquer functor: as passadas de bounding box
  (`View::DrawCurrentPage[bbox]`) e o desenho final (`View::DrawCurrentPage[svg]`).

Não são checkpoints: o `Object::Process(ConstFunctor &) const` (um functor const não muda o
estado — o lado C++ nem liga o gancho nessa sobrecarga, e o Dart pula as classes que derivam
de `ConstFunctor`/`DocConstFunctor` no C++, lista gerada dos headers), nem as consultas da
diretiva `@skip-functors` do manifesto (`Find*`, `AddToFlatListFunctor`, …).

Cada checkpoint tem um **rótulo** `Nome#k` — o nome da classe do functor (desmangled no C++,
`runtimeType` no Dart) e a k-ésima execução dele — e uma posição `@seq` na sequência *daquele
lado*. As duas sequências diferem (o Dart roda alguns functors em outra ordem ou mais vezes),
por isso `@seq` só vale para o próprio lado; o comparador as alinha pelo nome (LCS).

Cada checkpoint despeja a árvore a que o objeto processado pertence — sobe pelos pais até a
raiz, que é o `doc` ou, durante o cast-off, uma página ainda solta.

---

## Profundidade: três eixos

| Eixo | Opções | Escolhe |
|---|---|---|
| **quando** | `--at=<regex>` | os checkpoints despejados; casa **inteiro** contra `Nome#k` ou `@seq` (`'AdjustXPosFunctor#3'`, `'Adjust.*'`, `'@56\|@57'`). A linha de sequência de todos os outros sai sempre, para o alinhamento. |
| **onde** | `--path=<texto>`, `--classe=a,b` | as entidades: chave contém o texto; rótulo de classe (`note`, `staffAlignment`, `floatingCurvePositioner`, …). |
| **o quê** | `--modo=seq\|digest\|full`, `--grupos=…` | só a sequência; um hash por checkpoint; ou as linhas completas — dos grupos de campos pedidos. |

Grupos de campos (definidos no manifesto):

| Grupo | Conteúdo |
|---|---|
| `bb` | self e content bounding box de toda entidade (relativos à posição de desenho) |
| `pos` | posições relativas: `xRel`/`yRel` de layer elements, alignments, staff alignments, positioners, sistemas, compassos; `loc` |
| `link` | ponteiros para outras entidades (alignment de cada elemento, staff alignment de cada pauta, objetos de cada positioner, …) |
| `layout` | estado específico de classe: hastes, beams, pontos de ligadura, overflows, larguras do sistema, linhas suplementares, … |
| `cache` | os caches de posição (`m_cachedDrawingX`, `m_cachedXRel`, …) e dois campos sabidamente não determinísticos (ver Garantias) |

`--nivel` é o atalho, igual nas duas ferramentas:

| Nível | Modo | Grupos | Uso |
|---|---|---|---|
| 0 | `seq` | — | só a sequência de checkpoints: o pipeline roda as mesmas coisas na mesma ordem? |
| 1 (default) | `digest` | bb, pos | varredura barata de muitos arquivos |
| 2 | `full` | bb, pos | linhas completas das posições |
| 3 | `full` | bb, pos, link, layout | o nível do relatório por campo e do `--rank` |
| 4 | `full` | tudo | inclui caches |

Opções flexíveis sobrepõem as do nível (`--nivel=3 --at='@120|@121' --classe=note`). Outras:
`--excluir=…` e `--sem-lista` (ver `exclude.list`), `--saida=<dir>` e, no lado C++,
`--opt <flag>` (flag extra do CLI do verovio, como em `run.sh`).

Custo de referência (medido em 2026-09-11): nível 3 dos 90 arquivos com SVG divergente —
~2 min e 1,5 GB no C++, ~1,6 GB no Dart; corpus inteiro (621) no nível 4 no C++: 9 min, 8,9 GB.

---

## O que sai

JSON Lines, um arquivo por entrada: `tmp/snapshot/<lado>/<família>/<arquivo>.mei.jsonl`.

```jsonc
{"_meta":{"side":"cpp","source":"test/corpus/…","mode":"full","groups":15,"at":"","path":"","class":"","exclude":"…"}}
{"cp":24,"fn":"ScoreDefSetCurrentFunctor","k":1,"on":"doc","root":"doc","rows":312,"digest":"80fb93f14d41c253"}
{"cp":24,"key":"measure[1]/staff[1]/layer[1]/beam[1]/note[1]","class":"note","sx1":0,"sy1":-95,…,"xRel":0,"yRel":-630,"alignment":"measure[1]/alignment[0/1:19]",…}
```

- **linha de checkpoint**: `cp` (= `@seq`), `fn` e `k` (o rótulo), `on` (classe do objeto
  processado), `root` (classe da raiz despejada) e, quando despejado, `rows` e `digest`;
- **linha de entidade** (modo `full`): `key`, `class` e um campo por entrada do manifesto que
  se aplica à classe, na ordem do manifesto;
- valores: inteiros como estão (`±2147483647` é o `VRV_UNSET`, igual nos dois lados); `double`
  com precisão de ida e volta; `ref` como a chave do alvo, `null`, ou `"~"` (alvo fora da árvore
  despejada ou ponteiro pendurado); `frac` como `[num, den]`.

O **digest** é a soma (mod 2⁶⁴, independente de ordem) do FNV-1a 64 de uma forma canônica de
cada linha — a mesma nos dois lados, com `double` pelos bits IEEE e `-0.0` normalizado —, então
dois hashes iguais significam as mesmas linhas.

### Chaves das entidades

A chave casa uma entidade entre os dois lados; é calculada de cima para baixo, igual nos dois:

- segmentos `<classe>[<@n ou índice>]`, como o `probe::Path` dos fixtures: `@n` para
  `measure`/`staff`/`layer`, senão o índice 1-based entre os irmãos da mesma classe;
- **enraizada no `measure`** (inclusive): `measure[4]/staff[1]/layer[1]/chord[1]/stem[1]`, estável
  através do cast-off. O que está acima dos compassos leva o caminho inteiro sem o `doc`:
  `pages[1]/page[1]/system[1]`;
- **membros** que não estão na lista de filhos ganham um papel: `barLine[left|right]`,
  `clef[staffDef]`/`keySig[caution]` (layer), `scoreDef[drawing]` (página, sistema, compasso),
  `clef[current]` etc. (os `m_current*` de staffDef/scoreDef);
- **alinhadores**: `measure[4]/alignment[0/1:19]` (tempo : tipo), `…/ref[<staff>]`,
  `…/graceAligner[<n>]`; `…/system[1]/staffAlignment[<staff>]`;
  `…/staffAlignment[1]/floatingPositioner[<chave do objeto>]`;
- uma chave repetida ganha `#2`, `#3`… na ordem do percurso.

---

## O comparador

`dart run tool/snapshot_diff.dart <família>/<arquivo>.mei` faz, para um arquivo:

1. **Sequência** — alinha os checkpoints dos dois lados pelo nome (LCS) e lista os sem par: um
   functor que só um lado roda, ou que roda em outro ponto do pipeline.
2. **Estado, por checkpoint** — compara os pares alinhados (pelo hash, ou pelas linhas quando
   há) e separa as divergências **transitórias** (os dois lados fazem o mesmo trabalho em outra
   ordem e o estado volta a bater) da **persistente**: a sequência final de pares divergentes,
   depois da qual o estado nunca mais bate. O par onde ela começa localiza a origem — o estado
   batia depois do par anterior e não bate depois deste, então nasceu no código entre os dois
   (o functor do checkpoint e o que houver sem par antes dele). Sem linhas, o relatório imprime
   os comandos para despejá-las (`--at` com o `@seq` de cada lado, antes e depois).
3. **Estado, por campo** — com linhas em todos os checkpoints (`--nivel` 2–4 sem `--at`),
   rastreia cada (entidade, campo) separadamente: o que ainda diverge no último checkpoint é
   persistente, e o relatório agrupa por (classe.campo, functor onde a sequência final de
   divergência começou), com os valores C++ × Dart, o delta e o membro C++ de onde vem o campo.
   É o critério robusto: uma diferença inofensiva que persiste num campo não esconde as outras.

Exemplo (trecho real, `arpeg/arpeg-003.mei`, nível 3):

```
alignmentReference.refElements — nasce em C++ @31 AlignHorizontallyFunctor#1 × Dart @35 — 3 entidade(s)
  measure[4]/alignment[0/1:19]/ref[2]: C++ ["…/chord[1]","…/chord[1]/stem[1]"…  Dart ["…/chord[1]","…/chord[1]/note[1]"… (tamanhos 8 × 4)
system.sysCastOffTotalW — nasce em C++ @72 ScoreDefUnsetCurrentFunctor#1 × Dart @68 — 1 entidade(s)   [C++: System o->m_castOffTotalWidth]
  pages[1]/page[1]/system[1]: C++ 11958  Dart 11852 (Δ -106)
```

`--rank` faz o mesmo para todo arquivo despejado dos dois lados e conta **arquivos** por
(classe.campo, functor de nascimento) — o "onde nasce" do `probe_diff --rank` cruzado com o
"quanto vale" do `cluster_deltas`. Para arquivos despejados só com hash, cai no ranking por
functor da divergência persistente. Lista também os checkpoints sem par somados no corpus.

Outras opções: `--max=N` (exemplos por grupo), `--todos` (todas as transitórias), `--seq`
(a diferença de sequência inteira), `--excluir=…` (ignora campos só nesta comparação),
`--cpp=`/`--dart=` (outros diretórios de despejo).

---

## O manifesto — `cpp_probe/snapshot/fields.manifest`

A fonte única do que se despeja. Uma linha por campo:

```
group | C++ class | Dart class | name | type | C++ expression | Dart expression
pos   | LayerElement | LayerElement | xRel | int | o->m_drawingXRel | o.drawingXRel
```

- `o` é a entidade já convertida para a classe (`dynamic_cast` no C++, `is` no Dart —
  interfaces/mixins servem);
- tipos: `int`, `bool`, `double`, `enum`, `ref`, `refs`, `frac`, `ints`;
- formas expandidas pelo gerador: `EACH(v in <contêiner>: e1, e2, …)` (lista achatada, aninhável),
  `SORTED(…)`, `IF(cond: expr)` (só emite enquanto `cond` vale, a mesma condição dos dois lados)
  e, só no Dart, `@_campo` (campo privado lido por `dart:mirrors`);
- o formato completo está no cabeçalho do próprio arquivo.

### Acrescentar um campo

1. Ache o membro no C++ (`origin/src/include/vrv/*.h`) e o equivalente no Dart. No C++, prefira
   o membro cru (`o->m_xxx`: a unidade é compilada com `-fno-access-control`); no Dart, um getter
   que só devolve o campo, ou `@_campo`. **Nunca** um getter que calcula ou preenche cache.
2. `enum`: o C++ vira `int`; a expressão Dart tem de dar **o mesmo** inteiro — `.value` para os
   enums que carregam o valor C++ (os de `mei_enums.dart`, `AlignmentType`, `MeiDuration`),
   `.index` para os que só espelham a ordem (`ElementScoreDefRole`, `SlurCurveDirection`, …).
   Confira a declaração dos dois lados.
3. Confira quando o C++ **inicializa** o membro. Se o construtor/`Reset` não inicializa, o valor
   é lixo de heap até algum ponto: use `IF(cond: expr)` com uma condição que marque esse ponto,
   ou deixe o campo de fora com o motivo num comentário.
4. `dart run tool/gen_snapshot_fields.dart` (regrava `vrvsnapshot_fields.inc` e
   `tool/snapshot/fields.g.dart`). O lado C++ se recompila sozinho no próximo
   `cpp_probe/snapshot.sh` (ninja incremental); o lado Dart recusa rodar enquanto o código gerado
   não corresponder ao manifesto.
5. Rode o teste de determinismo (abaixo) nos arquivos que exercitam o campo.

---

## `cpp_probe/snapshot/exclude.list`

Diferenças **conhecidas e entendidas**, fora das linhas e do hash por padrão nas duas ferramentas
(`--sem-lista` mostra tudo). Entradas: `campo`, `classe.campo` ou `key:<texto>` (entidades cuja
chave contém o texto). Os dois despejos precisam da mesma lista — o comparador avisa quando não.

Toda entrada esconde estado, então toda entrada leva a justificativa escrita ao lado. Uma
**divergência do port** fica listada só enquanto se sabe que não chega ao desenho; saia da lista
quando for corrigida ou suspeita.

---

## Garantias e como são verificadas

1. **Despejar não muda o desenho.** `--check-svg`: no C++, o SVG do binário instrumentado contra o
   do `build/verovio` limpo (mesma semente `-x 12345`); no Dart, o SVG com e sem o gravador
   instalado. O teste `verovio_dart/test/snapshot_hook_test.dart` guarda o gancho da biblioteca.
   Medido em 2026-09-11: corpus inteiro (621) idêntico no C++ no nível 4; os 90 divergentes
   idênticos nos dois lados no nível 3.
2. **Nunca derreferenciar um ponteiro que pode estar pendurado.** O Verovio mantém ponteiros para
   objetos que já apagou e nunca mais lê (`Staff::m_staffAlignment` logo depois de
   `Doc::CastOffDocBase` apagar a página não-cast-off; `LayerElement::m_alignment` depois de os
   alinhadores serem refeitos). Um `ref` só resolve para a chave de uma entidade **viva e do tipo
   declarado do ponteiro** (`Walker::Valid` em `vrvsnapshot.cpp`: o `dynamic_cast` é feito sobre o
   objeto vivo encontrado naquele endereço); qualquer outra coisa sai `"~"` — o mesmo que o Dart
   dá para um alvo fora da árvore.
3. **O despejo C++ é determinístico.** Membros não inicializados ou ponteiros pendurados cujo
   endereço o alocador reaproveita fariam o despejo mudar de uma execução para outra. Para caçar,
   rode duas vezes com `MALLOC_PERTURB_` diferente (a glibc preenche a memória nova com o padrão)
   e compare — tudo que muda é não inicializado ou pendurado:
   ```bash
   MALLOC_PERTURB_=17 cpp_probe/snapshot.sh --nivel=4 --saida=tmp/snapshot/_a <arquivos>
   MALLOC_PERTURB_=99 cpp_probe/snapshot.sh --nivel=4 --saida=tmp/snapshot/_b <arquivos>
   ```
   Medido em 2026-09-11 nos 90 divergentes: só `stOverflowAboveBBs`/`stOverflowBelowBBs` variam
   (listas de `BoundingBox *` que o C++ não limpa — o tipo declarado não permite a checagem do
   item 2), por isso ficam no grupo `cache`, fora dos níveis 1–3. O lado Dart é determinístico
   por construção.

---

## Limitações conhecidas

- **Estado não é saída.** Uma divergência persistente de estado não chega necessariamente ao SVG
  (o bounding box do `system`, por exemplo). O ranking é um mapa de candidatos, não uma lista de
  bugs confirmados; confirme contra o `compare_svg`/`probe_diff` do arquivo.
- **Cobertura do manifesto.** 193 campos em 36 classes (2026-09-11): o estado de layout
  principal. Não é "todos os campos de todas as classes" — ele cresce sob demanda, quando uma
  investigação precisa de um campo.
- **Mudanças fora de functor** (código direto em `Doc::CastOffDocBase`, `Doc::SetDrawingPage`…)
  aparecem no checkpoint seguinte e são atribuídas a ele; o relatório diz "entre o fim desses dois
  checkpoints" por isso.
- **Não há granularidade por visita** dentro de um functor, nem um nível "tudo por reflexão"
  (`dart:mirrors` no Dart + `lldb` no C++). São os próximos passos naturais se o funil pedir.
- **Ordem de pipeline.** O Dart roda parte do pipeline em outra ordem (a cadeia `Calc*`, o
  `AlignVertically` da passada horizontal) e não roda o `ResetDataFunctor` que o C++ executa
  antes de cada passada de bounding box. O comparador trata isso como transitório, mas uma
  divergência que nasce "entre" dois checkpoints pode ter vindo de um functor sem par.

---

## Primeira rodada (2026-09-11)

Os 90 arquivos com SVG divergente naquele dia, nível 3, `--rank` — um retrato datado, não um
número a manter; regenere antes de confiar:

| Campo | Nasce em | Arquivos | Leitura |
|---|---|---|---|
| `staffAlignment.stClefOverflowAbove/Below` | `CalcBBoxOverflowsFunctor` | 69 | o C++ conta o overflow da clave do scoreDef (ex. 240/291), o Dart dá 0 — candidato para o espaçamento vertical (`stYRel` em `AdjustYPos`, 23 arquivos; `page.pJustH` em `AlignSystems`, 25) |
| `alignmentReference.refElements` / `@presença` | `AlignHorizontallyFunctor` | 25 / 19 | as alignment references de acordes têm outros elementos |
| `stem.alignmentLayerN`, `accid.alignmentLayerN` | `AlignHorizontallyFunctor` | 20 / 16 | C++ -1, Dart 1 — segue `alignment.alXRel` em `AdjustXPos` (17) e as larguras do sistema (`sysTotalW`, `measure.mXRel`) |
| `dots.dotLocs`, `dots.xRel` | `CalcDotsFunctor` | 11 / 8 | pontos de acordes cross-staff no mapa da pauta errada; `xRel` dos pontos de pausa 0 no Dart |
| `floatingCurvePositioner.cvPoints` | `AdjustSlursFunctor` | 17 | pontos de controle de ligadura, Δ≈5 |
| `system.cx1…cy2`, `system.sx1…sy2` | `View::DrawCurrentPage[bbox]` | 90 / 44 | o Dart nunca preenche o bounding box do `System` — provavelmente inofensivo |

Divergências estruturais achadas no caminho e postas na `exclude.list` (com o motivo lá):
`pgHead`/`pgFoot` vivem num `scoreDef` próprio no C++ e são copiados para todo scoreDef de
desenho no Dart; `Doc::m_drawingBeamMaxSlope` é estado morto; o `System` do Dart é um
`FloatingObject`. Também visível: depois de `CastOffPagesFunctor` o Dart zera o bounding box do
sistema movido, o C++ o mantém.

---

## Detalhes de implementação

- **Onde vive o runtime C++.** Diferente dos outros patches, fica fora do patch:
  `cpp_probe/snapshot/vrvsnapshot.{h,cpp}` + o `vrvsnapshot_fields.inc` gerado. O patch
  `cpp_probe/patches/snapshot.patch` (último da `ORDER`, 13 linhas, só acréscimos) liga ao build:
  o guarda RAII `snapshot::ProcessScope` como primeira instrução de `Object::Process(Functor &)`,
  o checkpoint no fim de `View::DrawCurrentPage` e a cola do CMake que compila
  `cpp_probe/snapshot/*.cpp` com `-fno-access-control`. Mudar o manifesto é regenerar e rodar
  `ninja` — sem `mkpatch`, e sem o `sync.sh --delete` apagar o que foi gerado.
- **Configuração C++** por variáveis de ambiente (`VRV_SNAPSHOT_OUT`, `_MODE`, `_GROUPS`, `_AT`,
  `_PATH`, `_CLASS`, `_EXCLUDE`, `_SOURCE`), que o `snapshot.sh` monta a partir da linha de
  comando. Sem `VRV_SNAPSHOT_OUT` nada é percorrido nem escrito: o custo é um contador por
  `Process`.
- **O lado Dart** fica em `tool/` porque lê campos privados com `dart:mirrors`, que não pode
  entrar no pacote web-safe. Na biblioteca há só `FunctorBase.checkpointHook`, chamado no fim de
  `Object.process` de nível 0 e de `View.drawCurrentPage` — nulo por padrão.
- **Espelho linha a linha.** Rótulos, esquema de chaves, forma canônica do hash e o percurso
  (`Walker`) estão duplicados em `vrvsnapshot.cpp` e `tool/snapshot/recorder.dart`, com os
  mesmos nomes; os campos não estão — vêm do manifesto. Mude os dois ou nenhum.
- **Checagem do código gerado** por conteúdo (`staleSnapshotFields()` no gerador, chamada pelo
  `snapshot.dart`), não por data: o git não preserva a data de modificação.
