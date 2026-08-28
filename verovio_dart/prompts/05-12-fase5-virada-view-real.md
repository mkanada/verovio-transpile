# 05-12 — VIRADA: ligar o layout ao View real e deletar headless_extents.dart

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Substituir o substituto. Hoje o layout da Fase 4 calcula bounding boxes com
`lib/src/rendering/headless_extents.dart` — 825 linhas de aproximações. O C++ calcula-as
**desenhando de verdade** num `BBoxDeviceContext`. Esta tarefa reproduz o fluxo do C++, **deleta
`headless_extents.dart`** e revalida a Fase 4 inteira.

**Espere regressões.** Números que "batiam" com aproximações vão mudar. Isso é o objetivo: é a única
rota para igualdade numérica com o C++. Persiga-as até o fim.

## Pré-condições

Tarefas **05-05** (BBoxDeviceContext completo) e **05-11** (view_page inteiro) concluídas.

```bash
cd verovio_dart
grep -c "_notYet(" lib/src/rendering/view_page.dart          # 0
grep -c "TODO" lib/src/rendering/bbox_device_context.dart    # 0
dart test 2>&1 | tail -1                                      # verde, ≥ 432
dart run tool/validate_layout.dart                            # anote os números ANTES
```

Confirme a infraestrutura de extração em 30 s (você vai precisar dela — `00-MESTRE.md` §6-bis):

```bash
ls cpp_probe/build.sh verovio_dart/test/fixtures/cpp_fixture.dart   # ambos existem
cpp_probe/patch.sh --list | tail -1                                 # 05-12 (seu id, já no ORDER)
```

**Anote no relatório os números de antes:** arquivos com layout OK, asserções estruturais, timemaps
`match`, timemaps `differ`. Eles são a linha de base contra a qual a virada será julgada.

## Referência C++

O fluxo exato, em `origin/src/src/page.cpp`:

| Linha | Contexto | Modo do BBoxDeviceContext | Particularidade |
|---:|---|---|---|
| 240 | `Page::LayOut`, **só se** `m_svgBoundingBoxes` está ligada | `BBOX_BOTH` | opcional; é o que popula as caixas para a saída de debug |
| 301 | `Page::LayOutTranscription`, só se `!m_layoutDone` | `BBOX_HORIZONTAL_ONLY` | documentos de transcrição |
| **410** | `Page::LayOutHorizontally` | `BBOX_HORIZONTAL_ONLY` | **com `view.SetSlurHandling(SlurHandling::Ignore);`** |
| **532** | `Page::LayOutVertically` | `BBOX_BOTH` | depois de `AlignVerticallyFunctor` |

O padrão é sempre o mesmo:

```cpp
View view;
view.SetDoc(doc);
BBoxDeviceContext bBoxDC(&view, 0, 0, BBOX_HORIZONTAL_ONLY);
// Do not do the layout in this view - otherwise we will loop...
view.SetPage(this, false);
view.DrawCurrentPage(&bBoxDC, false);
```

Repare no `false` de `SetPage` (não refaz layout) e no `false` de `DrawCurrentPage` (não desenha
fundo). Os dois são essenciais para não entrar em recursão.

Leia também `origin/src/src/page.cpp:396-608` inteiro, para ver onde exatamente as chamadas caem
dentro das sequências de functors.

## Dados de referência do C++

> Esta é **a única tarefa da Fase 5 com extração preventiva de fixtures**, e não é por acaso
> (`00-MESTRE.md` §6-bis, "Quando extrair"): as bounding boxes que o `BBoxDeviceContext` acumula
> alimentam o layout e **não aparecem em nenhuma saída final** — nem no SVG, nem no timemap. O
> `headless_extents.dart` que você vai deletar chuta esses valores em 16 pontos `Approximation:`, e
> o relatório 04j rastreia a eles **as 58 divergências de fixture e 16 das 18 de timemap** (todas
> menos as 2 de expansão de id) que restam da Fase 4. Sem os valores verdadeiros, a reescrita seria acertar contra um alvo invisível —
> exatamente o problema que fez a Fase 4 instrumentar antes de portar. Em todo o resto da Fase 5 os
> goldens já são o fixture; aqui, não.

**Valores a medir** — para cada objeto desenhado nas duas passadas de layout, no instante em que a
caixa dele está completa:

1. **Bboxes por elemento** (`fn` = `"LayOutHorizontally"` ou `"LayOutVertically"`, `pass` do
   `BeginPass`): `path` estrutural (`probe::Path`), `id`, e os pares relative+absoluto de cada caixa
   — `GetSelfX1()/X2/Y1/Y2()` e `GetContentX1()/X2/Y1/Y2()` (`boundingbox.h:110-117`), mais
   `GetDrawingX()`/`GetDrawingY()` do objeto, para que o teste reconstrua o absoluto. Tudo `int` no
   C++: compare com epsilon 0.
2. **Texto** não precisa de fixture à parte: o `BBoxDeviceContext` mede texto pelos glifos dos
   assets (`bboxdevicecontext.cpp:332` via `Resources`), fonte determinística dos dois lados. O
   efeito dele aparece dentro das caixas do item 1.

**Funções a instrumentar** (arquivo:linha na árvore limpa; o `EXEMPLO.patch` desloca `page.cpp`,
então localize sempre por nome com `grep -n`):

| Onde | O quê |
|---|---|
| `origin/src/src/bboxdevicecontext.cpp:62` `EndGraphic` | um registro por objeto, no `pop_back` de `m_objects` — é onde a caixa acumulada está completa |
| `origin/src/src/bboxdevicecontext.cpp:71` `EndResumedGraphic` | idem — elementos que retomam o grupo (ex.: beamSpan cruzando sistema) passam por aqui, não por `EndGraphic` |
| `origin/src/src/page.cpp` `Page::LayOutHorizontally` | `probe::BeginPass("LayOutHorizontally")` antes do `DrawCurrentPage` de `:410` |
| `origin/src/src/page.cpp` `Page::LayOutVertically` | `probe::BeginPass("LayOutVertically")` antes do `DrawCurrentPage` de `:532` |

`page.cpp` já inclui `vrvprobe.h` (vem do `EXEMPLO.patch`); `bboxdevicecontext.cpp` ainda não —
acrescente o `#include "vrvprobe.h"` no bloco de includes. Nenhum patch anterior toca esse arquivo.
Objetos desenhados **sem** `StartGraphic` (caixa acumulada fora da pilha de `m_objects`) não caem
nesses dois pontos; se faltar caixa que o layout consome, instrumente também
`BoundingBox::UpdateSelfBBoxX/UpdateContentBBoxY` (`boundingbox.cpp:50-125`, enxergam o objeto por
`this`) filtrando por `probe::CurrentPass`, e registre a decisão no relatório.

**Arquivos do corpus** (fixados para cobrir todas as causas nomeadas no relatório 04j):

| Arquivo | Por quê |
|---|---|
| `test/corpus/note/note-001.mei` | o menor caso do corpus, controle |
| `test/corpus/accid/accid-001.mei` | as 54 divergências da 04b (bbox de recorte SMuFL, `Accid::InitFloatingObject`) |
| `test/corpus/artic/artic-001.mei` | a outra metade das divergências da 04b |
| `test/corpus/tuplet/tuplet-001.mei` | as 4 divergências da 04c (`BeamSegment` só na render pass) |
| `test/corpus/gracenote/gracenote-002.mei` | 9 das 18 divergências de timemap |
| `test/corpus/cross-staff/cross-staff-015.mei` | cross-staff: bboxes de render alimentam o alinhador |
| `test/corpus/beamspan/beamspan-001.mei` | beam cruzando sistema — o ramo `EndResumedGraphic` |
| `test/corpus/trill/trill-002.mei` | spanning control element cuja bbox alimenta o layout |
| `test/corpus/arpeg/arpeg-001.mei` | idem |
| `test/corpus/lyric/lyric-009.mei` | texto com extensão estimada hoje (`Approximation:` de `headless_extents`) |

**Fixtures a gravar**: `test/fixtures/cpp/05-12/<nome-do-arquivo>.jsonl`

**Comandos** (a partir da **raiz** do workspace; seu id `05-12` **já está** em
`cpp_probe/patches/ORDER`, depois do `04h`):

```bash
cpp_probe/sync.sh
# edite build-probe/src/src/{bboxdevicecontext,page}.cpp — só fprintf
cpp_probe/mkpatch.sh 05-12         # grava cpp_probe/patches/05-12.patch
cpp_probe/build.sh 05-12           # sync + pilha até 05-12 + ninja incremental

for f in note/note-001 accid/accid-001 artic/artic-001 tuplet/tuplet-001 \
         gracenote/gracenote-002 cross-staff/cross-staff-015 beamspan/beamspan-001 \
         trill/trill-002 arpeg/arpeg-001 lyric/lyric-009; do
  n=$(basename $f)
  cpp_probe/run.sh 05-12 "test/corpus/$f.mei" \
      "verovio_dart/test/fixtures/cpp/05-12/$n.mei.jsonl" --svg "/tmp/probe-$n.svg"
  build/verovio -r verovio_dart/assets/data -x 12345 -o "/tmp/limpo-$n.svg" \
      "verovio_dart/test/corpus/$f.mei" >/dev/null
  diff "/tmp/limpo-$n.svg" "/tmp/probe-$n.svg" && echo "SVG idêntico: $n"
done
```

Os dez `diff` têm de sair **vazios** antes de qualquer reescrita — o binário instrumentado é quem
vira o oráculo das caixas.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/model/doc.dart` — remover o import de `headless_extents.dart` (linha 122-123)
  e a chamada `HeadlessExtents(doc)` (linha 497); pôr no lugar o fluxo `View` + `BBoxDeviceContext`
  nas **duas** posições (`page.cpp:410` e `:532`).
- **Alterar** `lib/src/model/system_page_elements.dart` (onde vive `Page`) — se as fases de layout
  moram lá, é lá que as chamadas entram.
- **DELETAR** `lib/src/rendering/headless_extents.dart`.
- **Alterar** `lib/src/layout/floating_positioner.dart:445` — trocar a aproximação de sobreposição
  por retângulo simples pela lógica do C++ (`origin/src/src/floatingobject.cpp`, procure
  `HorizontalContentOverlap`/`VerticalContentOverlap`).
- **Alterar** `lib/src/layout/slur_positioning.dart` — remover as 3 aproximações
  (linhas 11, 375, 534) e portar o que o C++ faz de verdade
  (`origin/src/src/adjustslursfunctor.cpp` e `origin/src/src/slur.cpp`).
- **Alterar** `lib/src/layout/lay_out_vertically.dart:18` — o comentário que cita `headless_extents`.
- **Alterar** os testes que dependiam das aproximações.
- **Criar** `test/bbox_parity_test.dart` — paridade das caixas (self e content, relativa e absoluta)
  contra os fixtures `05-12`, por `path`, com o leitor `test/fixtures/cpp_fixture.dart`.

## Passo a passo

1. **Antes de qualquer coisa**, rode `dart run tool/validate_layout.dart` e
   `dart run tool/compare_svg.dart --all` e **grave os dois relatórios em `/tmp`** para comparar
   depois. Sem isso você não consegue julgar a virada.
2. **Extraia os fixtures de bbox antes de escrever Dart** — seção *Dados de referência do C++*
   acima: instrumente, gere os 10 fixtures, prove os 10 `diff` de SVG vazios e **leia os fixtures**.
   Eles dizem quanto as 16 aproximações do `headless_extents.dart` mentiam, caixa a caixa — ponha
   essa comparação no relatório: é a informação mais valiosa desta tarefa.
3. Leia `page.cpp:221-247`, `:249-317`, `:396-497`, `:509-608` inteiros.
4. Encontre no Dart onde as fases horizontal e vertical estão implementadas
   (`grep -n "layOutHorizontally\|layOutVertically\|HeadlessExtents" lib/src/model/doc.dart lib/src/model/system_page_elements.dart`).
5. Insira o fluxo `View` + `BBoxDeviceContext` nos dois pontos, com os modos e o `SlurHandling`
   corretos. **Não remova `headless_extents.dart` ainda** — rode os dois lado a lado uma vez e
   compare as caixas de ambos contra o fixture do C++; onde as duas divergem dele, é o C++ quem
   ganha, não a aproximação.
6. **Agora** delete `headless_extents.dart` e o import.
7. Rode `dart test`. **Vai quebrar.** Para cada teste quebrado, decida:
   - o valor esperado do teste vinha da aproximação → **corrija o teste** para o valor do C++
     (obtenha-o do **fixture de bbox** da sua tarefa; para um valor que não esteja nos fixtures, use
     o binário: `./build/verovio -r verovio_dart/assets/data -o /tmp/x.svg <arquivo>` e leia a
     coordenada no SVG). Explique no relatório;
   - o valor esperado vinha do C++ e agora não bate → **é bug seu**, conserte o código.
   **Nunca** relaxe uma asserção sem cair num destes dois casos, com justificativa.
8. Elimine as aproximações de `floating_positioner.dart` e `slur_positioning.dart`.
9. Escreva `test/bbox_parity_test.dart` e persiga cada divergência de caixa com o protocolo de
   re-instrumentação do `00-MESTRE.md` §6-bis (instrumente mais fundo, regere, compare — nunca
   adivinhe o esperado).
10. Rode `dart run tool/validate_layout.dart` e compare com o relatório de antes.
11. Rode `dart run tool/compare_svg.dart --all` e compare.
12. Persiga cada divergência nova. Use a política da seção 7 do `00-MESTRE.md`.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde (contagem pode variar; **nenhum teste em `skip`**)
- [ ] `ls lib/src/rendering/headless_extents.dart` → **arquivo não existe**
- [ ] `grep -rn "HeadlessExtents\|headless_extents" lib/ test/ tool/` → **nenhum resultado**
- [ ] `grep -rn "Approximation:" lib/src/` → **nenhum resultado**
- [ ] `cpp_probe/patches/05-12.patch` versionado, só acréscimos
      (`grep -c '^-[^-]' cpp_probe/patches/05-12.patch` = 0), e os 10 `diff` de SVG contra o
      binário limpo vazios (colados no relatório)
- [ ] `test/bbox_parity_test.dart` compara self/content, relativa e absoluta, nos 10 fixtures, com
      epsilon 0; o relatório traz N valores comparados, quantos batem e cada divergência restante
      com hipótese de causa nomeando função e linha do C++
- [ ] **Os fixtures da Fase 4 re-executados** (`dart test` cobre os de 04-00..04h): a contagem
      **2146/2204** sobe; cada divergência que sobrar tem de ser de causa nomeada fora do escopo
      desta tarefa (hoje, as 4 da 04c esperam o `BeamSegment` da 05-17) — nada além disso
- [ ] `dart run tool/validate_layout.dart` roda sobre os 621 arquivos e o número de timemaps
      `match` é **maior ou igual** ao registrado na tarefa 04j; se for menor, o relatório lista
      arquivo por arquivo o que regrediu e por quê
- [ ] `dart run tool/compare_svg.dart --all` roda sem exceção e o relatório traz o número de limpos
- [ ] O relatório traz uma tabela **antes × depois** com as quatro contagens do validate_layout e
      as duas do compare_svg, e a comparação caixa a caixa aproximação × C++
- [ ] Relatório em `prompts/reports/05-12.md`
- [ ] `PLANO.md`: checkbox da virada marcado, e a nota da Fase 4 sobre `headless_extents` removida

## Armadilhas conhecidas

- **Recursão infinita.** `SetPage(page, false)` e `DrawCurrentPage(dc, false)`. O C++ deixa um
  comentário explícito sobre isso; se você passar `true`, o layout chama o desenho que chama o
  layout. O sintoma é stack overflow ou o processo pendurado.
- **`SlurHandling::Ignore` na fase horizontal.** Sem ele, ligaduras entram na conta horizontal e
  todo o espaçamento sai errado — e o erro é sutil, não catastrófico.
- Os modos: `BBOX_HORIZONTAL_ONLY` na horizontal, `BBOX_BOTH` na vertical. Trocar é fácil e o
  resultado quase funciona.
- **Ordem**: a chamada de `page.cpp:410` vem **antes** de `AdjustOssiaStaffDefFunctor`, não depois.
  A de `:532` vem **depois** de `AlignVerticallyFunctor` e antes de `AdjustArticWithSlursFunctor`.
- **O path do fixture é enraizado no `measure`.** Objetos fora de compasso (scoreDef, running
  elements, system elements) saem com a chave `?` até você estender a regra 2 do §6-bis — nos
  **dois** lados, C++ e Dart, nunca só num.
- **A mesma caixa aparece duas vezes** (uma por passada): o `fn` do registro (`LayOutHorizontally`
  vs `LayOutVertically`) é o que separa. Uma caixa em `BBOX_HORIZONTAL_ONLY` só tem eixo X
  significativo — o comparador tem de saber isso.
- Performance: desenhar a página inteira duas vezes por layout é caro. Se `dart test` passar de
  60 s, meça antes de otimizar — e **não** otimize desviando do C++.
- Teste em `skip: true` é reprovação automática desta tarefa.

## Fora de escopo

- `view_element.cpp`, `view_control.cpp` etc. — enquanto eles forem stubs, as caixas dos elementos
  de camada continuarão vazias e muitos números não vão bater. **Isso é esperado e tem de estar
  escrito no relatório**: a virada é estrutural, o fechamento numérico vem com as tarefas 05-13
  em diante e culmina na 05-25.
