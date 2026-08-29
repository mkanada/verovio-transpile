# 05-34 — Fidelidade do port: `view_control.dart`

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

`lib/src/rendering/view_control.dart` tem **4.968 linhas** e não é um port linha a linha de
`view_control.cpp` — é código defensivo que adivinha a própria API:

| Medida | `view_control.dart` |
|---|---:|
| `catch (_)` | **463** |
| `as dynamic` | **468** |
| linhas com mais de 80 colunas | **359** |
| regras de lint desligadas no cabeçalho | **14** |

O padrão dominante é este (`view_control.dart:3044-3047`):

```dart
dynamic orderDyn;
try { orderDyn = (arpeg as dynamic).order ?? (arpeg as dynamic).getOrder?.call(); } catch (_) {}
final String orderStr = orderDyn?.toString().toLowerCase() ?? 'up';
if (orderStr.contains('nonarp')) {
```

O C++ correspondente (`view_control.cpp:1552-1560`) é:

```cpp
const arpegLog_ORDER order = arpeg->GetOrder();
if (order == arpegLog_ORDER_nonarp) {
```

Uma leitura de campo tipada virou: um `dynamic`, duas tentativas de nome de método, um `try/catch`
que engole o erro, uma conversão para texto, um `toLowerCase`, um `contains` de substring e um valor
padrão inventado. O resultado **acerta por acaso** neste caso (o default do C++ cai no mesmo ramo) e
erra em silêncio no dia em que o nome do getter mudar.

A primeira linha do arquivo desliga 14 regras do analisador, entre elas `invalid_assignment`,
`argument_type_not_assignable` e `unchecked_use_of_nullable_value` — ou seja, a verificação de tipos
está praticamente desligada nessas 4.968 linhas. Removendo as supressões dos 9 arquivos de
`lib/src/rendering/`, o `dart analyze` sai de 8 para **319 issues** (101 warnings, 218 infos, 0
erros). A "baseline de 8" que todas as tarefas da Fase 5 declararam cumprir vale para o repositório,
não para o código que elas escreveram.

Esta tarefa converte o arquivo num port de verdade. **Não muda comportamento de propósito** — mas
vai mudar por acidente onde a adivinhação estava errada, e cada mudança dessas é um defeito
encontrado.

## Pré-condições

Tarefa **05-33** concluída — a refatoração precisa de testes que mordam.

```bash
cd verovio_dart
dart run tool/compare_svg.dart --all           # anote o ANTES nos dois modos
dart test 2>&1 | tail -1                        # verde
```

## Referência C++

`origin/src/src/view_control.cpp` (3.306 linhas), inteiro. Para cada método Dart, releia o
correspondente C++ **antes** de mexer: o objetivo não é "limpar o Dart", é fazer o Dart dizer o
mesmo que o C++ diz.

## O procedimento, método a método

Vá por método, não por regra de lint. Para cada um:

1. Abra o C++ ao lado.
2. **Tipe os acessos.** Todo `(x as dynamic).foo` vira acesso tipado. Se o membro não existe na
   classe Dart, ele **falta** — acrescente-o à classe do modelo citando o C++, ou registre a
   ausência como achado. Trocar `dynamic` por `dynamic` com nome melhor não vale.
3. **Tire os `catch (_)`.** Cada um esconde uma de três coisas: um membro que não existe (item 2),
   uma condição que o C++ testa explicitamente (porte o teste), ou um erro de verdade (conserte).
   Nenhuma das três se resolve engolindo a exceção. Onde o C++ tem `if (!x) return;`, o Dart tem
   `if (x == null) return;` — não `try { ... } catch (_) {}`.
4. **Compare enum com enum.** `orderStr.contains('nonarp')` vira
   `order == ArpeglogOrder.nonarp`. Comparação de enum por substring de `toString()` é defeito
   mesmo quando dá o resultado certo.
5. **Tire os defaults inventados.** `?? 'up'` só existe porque o acesso podia falhar; com o acesso
   tipado, o default é o do C++ — e quando o C++ não tem default, não invente um.
6. **Remova ramos que o C++ não tem** (§8.3). O `else` final de `drawSystemElement` já saiu na
   05-27; procure os outros comparando a cadeia de `if/else if` com a do C++, ramo a ramo.
7. **Remova código morto**: `_drawArpegCompat() {}` e os outros que o `unused_element` apontar
   quando a supressão sair.
8. Rode `compare_svg` na família afetada. Se o número mudar, você achou um defeito — registre-o com
   arquivo, valor C++, valor Dart antes e depois.

Ao terminar, apague a linha `// ignore_for_file:` do topo e trate o que o analisador apontar. As 200
ocorrências globais de `curly_braces_in_flow_control_structures` são as únicas que podem ser
resolvidas por formatação; o resto é conteúdo.

## Critérios de aceite

- [ ] `grep -c "as dynamic" lib/src/rendering/view_control.dart` → **0**
- [ ] `grep -c "catch (_)" lib/src/rendering/view_control.dart` → **0**; se algum for realmente
      inevitável, ele vira `on <TipoEspecífico> catch (e)` com comentário citando o C++, e o
      relatório lista todos
- [ ] `head -1 lib/src/rendering/view_control.dart` não é `// ignore_for_file:`
- [ ] `dart analyze` ≤ baseline (8) **sem** a supressão do arquivo
- [ ] `dart format lib/src/rendering/view_control.dart` rodado (só este arquivo, §3)
- [ ] `dart test` verde, nenhum teste em `skip`
- [ ] `dart run tool/compare_svg.dart --all` nos dois modos **não regride**; onde melhorar, o
      relatório diz qual adivinhação estava errada
- [ ] O relatório lista, um por um, os membros que faltavam nas classes do modelo e que o `dynamic`
      escondia — essa lista é o produto mais útil da tarefa
- [ ] Nenhum método novo sem contraparte C++ (§8.3)
- [ ] Relatório em `prompts/reports/05-34.md`
- [ ] `PLANO.md`: linha da 05-34

## Armadilhas conhecidas

- **A tentação de trocar 468 `as dynamic` com sed.** Não funciona: metade deles esconde um membro
  que não existe, e o compilador só vai contar isso um a um.
- **Um `catch (_)` removido pode deixar a suíte vermelha na hora.** Ótimo: é a primeira vez que o
  erro aparece. Conserte a causa, não recoloque o `catch`.
- **Refatorar sem os testes da 05-33 é refatorar no escuro.** Se você chegou aqui sem eles, volte.
- Não mude a ordem das operações "para ficar mais legível" — §1: a ordem é parte do algoritmo.
- Se a fatia estourar (é provável: 4.968 linhas), pare num ponto coerente — por famílias inteiras de
  `Draw*`, nunca no meio de uma — e registre pela §8.7 o que ficou para uma 05-34b.

## Fora de escopo

- Os outros arquivos de `lib/src/rendering/` (05-35).
- Consertar divergências de geometria que não venham da adivinhação (05-36).
