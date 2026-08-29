# 2026-08-29-01 — Fase 5: a regressão da 05-34 e a lista errada da 05-36

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

Duas correções pequenas e independentes, ambas de higiene da série da Fase 5. Nenhuma delas fecha
a fase — quem fecha é a `05-36`. Esta tarefa existe para que a `05-34b`/`05-35`/`05-36` não comecem
em cima de uma árvore vermelha nem de uma lista de alvos errada.

---

## Parte 1 — a suíte está vermelha no working tree

Estado medido em 2026-08-29:

```
dart test        →  680 passaram, 1 falhou
falha:  test/vertical_layout_test.dart: layOutVertically (full pipeline) (setUpAll)
```

O HEAD (`19b5256`) passa; quem quebra são as mudanças **não commitadas** da `05-34`
(`options_shell.dart`, `atts_shared.dart`, `control_element.dart`, `control_elements_gen.dart`,
`interfaces/time_interface.dart`). Confirmado por `git stash`: com as mudanças guardadas, o teste
volta ao verde.

O rastro:

```
type 'Null' is not a subtype of type 'Object' in type cast
  view_control.dart 2479:63  ViewControl.drawTempo
  view_control.dart 107:7    ViewControl.drawControlElement
  view_page.dart 489:9       ViewPage.drawMeasureChildren
  ...
  doc.dart 976:12            Page._renderBoundingBoxes
  doc.dart 2159:9            Doc.layOut
```

### Por que isto é uma boa notícia

A `05-34` acrescentou um `TimePointInterface.getTstampStaves` de verdade. Antes dele, a chamada em
`view_control.dart:296` falhava e caía num `catch (_) {}`, `staffList` ficava vazia, e o laço de
`drawTempo` **nunca rodava**. Agora o método funciona, o laço roda, e estoura em `start as Object`
porque `start` é nulo.

Ou seja: o bug sempre esteve lá. O `catch (_)` o escondia. É exatamente o mecanismo descrito na
ressalva do topo do `PLANO.md`, e a primeira confirmação empírica dele — vale citar no relatório.

### O que fazer

1. **Não reverta a `05-34`.** O trabalho dela está certo; o que apareceu foi um defeito preexistente.
2. Vá a `origin/src/src/view_control.cpp`, `View::DrawTempo`, e leia **o que o C++ faz quando o
   `start` do `TimePointInterface` é nulo**. Ele testa antes? Retorna cedo? Usa outro objeto como
   âncora? Porte a decisão dele — não troque o cast por `start as Object?` para o erro sumir (§7.3).
3. Rode `dart test` inteiro. Se outros testes caírem pelo mesmo motivo (um `catch` que parou de
   engolir), trate cada um pelo mesmo procedimento: ler o C++, portar a decisão.
4. `dart run tool/compare_svg.dart --all` — o número tem de subir ou ficar igual, nunca cair.
   Medido em 2026-08-29 com o working tree: **115/623 estrutural, 4/623 numérico** (o HEAD dá 114).

---

## Parte 2 — a `05-36` aponta para os arquivos errados

A `05-36`, Parte 1, manda consertar três arquivos que lançam exceção:

> `test/corpus/color/color-001.mei`, `test/corpus/ftrem/ftrem-002.mei` e
> `test/corpus/symbol/symbol-002.mei` lançam `_TypeError: Null check operator used on a null value`

Essa lista é de antes da `05-30`. A medição de 2026-08-29 diz outra coisa:

| Arquivo | Exceção | Estado na 05-36 |
|---|---|---|
| `ftrem/ftrem-002.mei` | `_TypeError: Null check operator used on a null value` | ✅ listado |
| `stem/stem-014.mei` | `UnsupportedError: Cannot remove from an unmodifiable list` | ❌ não listado |
| `stem/stem-016.mei` | `UnsupportedError: Cannot remove from an unmodifiable list` | ❌ não listado |
| `color/color-001.mei` | — não lança mais (divergente, não falho) | ❌ listado à toa |
| `symbol/symbol-002.mei` | — não lança mais (divergente, não falho) | ❌ listado à toa |

E a classe de erro dos dois novos é **outra**: não é `!` num nulo, é mutação de lista imutável —
provavelmente um `List.unmodifiable`/`const []` devolvido por um getter e depois modificado, coisa
que no C++ é um `std::vector` por referência. O conserto não é o mesmo.

### O que fazer

1. **Edite `prompts/05-36-fase5-cauda-e-fechamento.md`, Parte 1**: troque a lista pelos três
   arquivos reais, com a exceção de cada um, e acrescente o parágrafo sobre as duas classes de erro
   distintas. Mantenha a regra que já está lá — nenhum deles entra em skip-list.
2. **Acrescente uma linha** dizendo que a lista foi medida em 2026-08-29 e que quem for executar a
   `05-36` deve **remedi-la** antes de começar (`dart run tool/compare_svg.dart --all`, seção
   "Falhas"), porque ela muda a cada tarefa da série.
3. **Não conserte os três arquivos aqui.** Isso é a `05-36`. Esta parte é só a correção do alvo.

---

## Critérios de aceite

- [ ] `dart test` verde — 0 falhas
- [ ] `dart analyze` ≤ 8
- [ ] `dart run tool/compare_svg.dart --all` ≥ 115 estrutural, ≥ 4 numérico
- [ ] `prompts/05-36-fase5-cauda-e-fechamento.md` com a lista corrigida e a instrução de remedir
- [ ] Relatório em `prompts/reports/2026-08-29-01.md`, com uma seção sobre o mecanismo
      `catch (_)` → bug escondido, citando este caso como evidência
- [ ] `PLANO.md`: remover o aviso "⚠️ O estado atual do working tree quebra
      `test/vertical_layout_test.dart`" da Fase 5, já que deixou de ser verdade

## Fora de escopo

- Terminar a `05-34` (é a `05-34b`, por famílias `Draw*`).
- Consertar os três arquivos que lançam (é a `05-36`).
- Qualquer refatoração de tipagem além do necessário para o `drawTempo` parar de estourar.
