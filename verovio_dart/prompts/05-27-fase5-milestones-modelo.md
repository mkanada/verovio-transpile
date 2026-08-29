# 05-27 — Três defeitos de modelo que bloqueiam o corpus inteiro

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Com o harness honesto (05-26), a primeira divergência estrutural de **444 dos 618** arquivos
divergentes está no mesmo lugar: os filhos do `<g class="system">`. A causa é um defeito de três
linhas no modelo, não no `View`.

Auditado em 2026-08-29: corrigir os dois primeiros defeitos abaixo leva o placar honesto de
**0/623 para 112/623 limpos**, medido. É a maior razão de correção por linha de código de toda a
fase. O terceiro é o mesmo tipo de defeito (atributo inventado que o C++ não propaga) achado na
mesma investigação; ele não move a contagem, mas suja o SVG de quase todo arquivo com nota
invisível.

## Pré-condições

Tarefa **05-26** concluída.

```bash
cd verovio_dart
grep -c "test/golden/cpp/" lib/src/testing/svg_compare.dart   # 0
dart run tool/compare_svg.dart --all --mode=structural         # 0/623 — anote o ANTES
```

## Referência C++

| Arquivo:linha | O que dizer |
|---|---|
| `origin/src/include/vrv/object.h:105-145` | `IsSystemElement()` e as sete irmãs: o C++ testa `m_classId`, e `m_classId` é **sempre** o valor concreto porque todo construtor o passa para cima |
| `origin/src/src/systemmilestone.cpp:28-33` | `SystemMilestoneEnd::SystemMilestoneEnd(Object *start) : SystemElement(SYSTEM_MILESTONE_END)` — passa o ClassId concreto ao construtor da base, guarda `m_start` e `m_startClassName`, e **não copia o id** |
| `origin/src/src/pagemilestone.cpp:28-33` | `PageMilestoneEnd`, idem, com `PageElement(PAGE_MILESTONE_END)` |
| `origin/src/src/view_control.cpp:3014-3046` | `View::DrawSystemElement` — o despacho que hoje nunca é alcançado; repare que ele emite `StartGraphic(element, elementEnd->GetStart()->GetID(), element->GetID())`: **classe** = id do início, **id** = id próprio, dois valores diferentes |
| `origin/src/src/view_page.cpp:1704-1740` | `View::DrawSystemChildren` — o `else` final é `assert(false)`, não um desenho genérico |
| `origin/src/src/stem.cpp:72-91` | `Stem::FillAttributes(const AttStems &attSource)` — a assinatura toma **só** `AttStems`, e `SetVisible` sai de `attSource.GetStemVisible()` (`@stem.visible`), nunca de `@visible` |

## Os três defeitos

### (a) `isSystemElement` e as sete irmãs leem o campo privado, não o getter

`lib/src/model/object.dart:164-171`:

```dart
bool get isSystemElement => isSystemElementId(_classId);
```

`_classId` é o campo que `assignClassId()` escreve. Mas `SystemMilestoneEnd`
(`lib/src/model/system_page_elements.dart:397-398`) e `PageMilestoneEnd` (`:423-424`) **sobrescrevem
o getter `classId`** e **nunca chamam `assignClassId`** — então `_classId` fica no valor sentinela da
base (`ClassId.systemElement` / `ClassId.pageElement`), e `_inRange` (`object.dart:217`, que exige
`>` estrito) devolve `false`.

Efeito medido: `Object.isSystemElement` é `false` para um `SystemMilestoneEnd`, `drawSystemChildren`
(`view_page.dart:451`) cai no `else` de log, `drawSystemElement` nunca roda, e **nenhum arquivo com
`<section>` emite `<g class="systemMilestoneEnd">`** — o que é praticamente todo o corpus.

Conserte pelos **dois** lados, porque cada um sozinho deixa a armadilha armada:

1. as oito checagens de grupo passam a consultar o getter `classId`;
2. os dois construtores passam a chamar `assignClassId(ClassId.systemMilestoneEnd)` /
   `assignClassId(ClassId.pageMilestoneEnd)`, como o C++ faz ao chamar
   `SystemElement(SYSTEM_MILESTONE_END)`.

E **audite as outras 24 classes** que sobrescrevem `ClassId get classId =>`
(`grep -rn "ClassId get classId =>" lib/src/model/`): para cada uma, verifique se o construtor
também chama `assignClassId` com o mesmo valor. Qualquer divergência entre os dois é a mesma
armadilha esperando outro functor. A tabela dessa auditoria vai no relatório.

### (b) O construtor dos milestone-end copia o id do início

`system_page_elements.dart:382-386` e `:411-414`:

```dart
// Copy the id from the start element (mirrors the C++ constructor).
id = start.id;
```

O comentário afirma espelhar o C++, e o C++ (`systemmilestone.cpp:28-33`) **não faz isso**. O
resultado é id duplicado no SVG: `<g id="cAVEWC" class="section systemMilestone" />` seguido de
`<g id="cAVEWC" class="systemMilestoneEnd cAVEWC" />`, onde o C++ tem dois ids distintos
(`f3btyno` e `c1d4rhaq`). Além de SVG inválido, isso quebra a normalização posicional de id do
comparador e mascara a divergência real.

Apague a cópia nos dois construtores. O id do início continua saindo no **atributo `class`**, que é
o que o C++ faz — e é por isso que `DrawSystemElement` passa os dois valores separados.

### (c) O `Stem` herda `@visible` da nota

`lib/src/layout/preparedata_functor.dart:1548-1551` acrescenta um ramo que o C++ não tem:

```dart
if (source is AttVisibility) {
  final AttVisibility visibility = source as AttVisibility;
  if (visibility.hasVisible) stem.visible = visibility.visible;
}
```

`Stem::FillAttributes` (`stem.cpp:72-91`) só lê `AttStems` — `@stem.visible`, o atributo do *stem*,
não o `@visible` do elemento pai. Efeito: uma nota com `@visible="false"` (por exemplo
`test/corpus/note/note-001.mei`) faz o Dart emitir `<g class="stem" visibility="hidden">` onde o
C++ emite `<g class="stem">`; o `visibility="hidden"` correto vai só no `<g class="note">`, que é o
objeto que tem `AttVisibility`.

Enquanto estiver nessa função, confira o ramo `AttStemVis` logo acima contra
`attSource.HasStemPos()` do C++ e confirme se `stemMod` (linha 1539, "arrives with the rendering
phase") já pode ser fechado com `m_drawingStemMod` — se puder, feche; se não, deixe a nota e
registre no relatório para a tarefa 05-32.

### O `else` inventado em `drawSystemElement`

`lib/src/rendering/view_control.dart:3818-3821` acrescenta um ramo final que desenha um gráfico
vazio para qualquer `SystemElement` não reconhecido. `View::DrawSystemElement` (`view_control.cpp:
3014`) não tem esse `else`: elemento não reconhecido não desenha nada. Com (a) corrigido esse ramo
passa a receber objetos de verdade e a inventar `<g>` que o C++ não tem. Remova-o.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/model/object.dart:164-171` — as oito checagens de grupo.
- **Alterar** `lib/src/model/system_page_elements.dart:382-386, 411-414` — `assignClassId` e a
  remoção da cópia de id nos dois construtores.
- **Alterar** `lib/src/layout/preparedata_functor.dart:1548-1551` — remover o ramo `AttVisibility`.
- **Alterar** `lib/src/rendering/view_control.dart:3818-3821` — remover o `else` inventado.
- **Alterar** as outras classes que a auditoria de `assignClassId` apontar.
- **Criar** `test/class_id_parity_test.dart` — para **toda** classe registrada no `ObjectFactory`,
  afirme `objeto.classId == objeto.<campo interno>` e que as oito checagens de grupo concordam com a
  faixa do enum. É este teste que fecha a armadilha para sempre; sem ele a correção é pontual.
- **Alterar** as catracas dos `test/view_*.dart` que melhorarem (elas só descem — §7.3).

## Passo a passo

1. Grave o ANTES (`compare_svg --all` nos dois modos).
2. Corrija (a) pelos dois lados e rode só `test/corpus/note/note-001.mei` pelo harness: a primeira
   divergência tem de deixar de ser a contagem de filhos do sistema.
3. Corrija (b) e confira no SVG do mesmo arquivo que os dois ids passaram a ser distintos e que o
   `class` do fim continua carregando o id do início.
4. Rode `compare_svg --all`. **Tem de dar 112 limpos.** A auditoria de 2026-08-29 mediu exatamente
   esse número com (a)+(b) aplicados; se você obtiver menos, ache a diferença antes de seguir — não
   ajuste o esperado.
5. Corrija (c) e o `else` inventado. Nenhum dos dois muda a contagem (medido: continua 112); os dois
   removem divergência dentro de arquivos que seguem divergindo por outros motivos.
6. Escreva `test/class_id_parity_test.dart` e a auditoria das 26 classes.
7. Reajuste as catracas dos testes de view para os números novos.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline (8)
- [ ] `dart test` verde, nenhum teste em `skip`
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` reporta **≥ 112/623 limpos**
- [ ] `dart run tool/compare_svg.dart --all --mode=numeric --epsilon=0` reporta o número medido, com
      a tabela ANTES × DEPOIS
- [ ] `grep -rn "id = start.id" lib/src/model/system_page_elements.dart` → nenhum resultado
- [ ] Nenhum `<g>` do corpus tem id duplicado: acrescente essa verificação ao harness ou ao teste
      novo e prove no relatório
- [ ] `test/class_id_parity_test.dart` cobre **todas** as classes do `ObjectFactory` e falharia com
      qualquer um dos dois defeitos (demonstre: reintroduza um, mostre vermelho, remova)
- [ ] O relatório traz a tabela das 26 classes que sobrescrevem `classId`, dizendo para cada uma se
      o construtor chama `assignClassId` com o mesmo valor
- [ ] As catracas dos `test/view_*.dart` foram reajustadas para baixo, nunca para cima
- [ ] Relatório em `prompts/reports/05-27.md`
- [ ] `PLANO.md`: linha da 05-27 marcada com o número novo

## Armadilhas conhecidas

- **`_inRange` exige `>` estrito** (`object.dart:217`), igual ao C++ (`object.h:139-142`). O valor
  sentinela da base (`ClassId.systemElement`) fica de fora da faixa de propósito — é por isso que o
  defeito é silencioso em vez de dar erro.
- **Corrigir só o getter, ou só o construtor, "funciona"** e deixa a armadilha armada para a próxima
  classe. Faça os dois, e é o teste novo que garante isso.
- Ao remover a cópia de id, procure quem dependia dela: `grep -rn "startClassName\|\.start\b"
  lib/src/` — se algum código casava milestone início/fim **pelo id**, ele estava certo por acidente
  e precisa passar a usar a referência `start`.
- Espere `dart test` quebrar em testes que afirmavam o id copiado. Cada um cai numa das duas
  hipóteses da §8.1: ou o teste espelhava o defeito (conserte o teste, citando `systemmilestone.cpp:
  28`), ou a sua mudança está errada.
- Não persiga aqui as divergências que **sobrarem** nos 506 arquivos. Elas são das tarefas 05-28
  (geometria vertical) e 05-36 (cauda).

## Fora de escopo

- Header/footer e a geometria vertical (05-28, 05-29).
- A virada do `BBoxDeviceContext` (05-30).
- Qualquer refatoração de estilo em `lib/src/rendering/` (05-34, 05-35).
