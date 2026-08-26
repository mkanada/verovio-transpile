# 07-09 — DrawingDeviceContext: adapter para Canvas, sem dart:ui no core

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Entregar a segunda saída prometida no `PLANO.md`: uma API de drawing que um app Flutter possa
consumir para pintar num `Canvas` — **sem que o core do package importe `dart:ui`**, para que
`verovio_dart` continue válido em web e em servidor.

## Pré-condições

Tarefa **07-08** concluída.

```bash
cd verovio_dart
dart test 2>&1 | tail -1     # verde, ≥ 1015
grep -rn "dart:ui" lib/       # esperado: nada, e tem de continuar assim
```

## Referência C++

Não há contraparte direta: o C++ não tem esse adapter (é uma extensão do port, decisão registrada no
`PLANO.md`). O que existe é a interface `DeviceContext`
(`origin/src/include/vrv/devicecontext.h`), já portada em `lib/src/rendering/device_context.dart`,
e a implementação de bounding box como exemplo de subclasse.

Leia também `origin/src/src/svgdevicecontext.cpp` para ver como uma implementação concreta trata
cada primitiva — o adapter faz o mesmo, emitindo comandos em vez de XML.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/drawing/drawing_command.dart` — um tipo selado (`sealed class`) de comando de
  desenho: `DrawPathCommand`, `DrawTextCommand`, `DrawGlyphCommand`, `PushTransformCommand`,
  `PopTransformCommand`, `SetPaintCommand`, `GroupStartCommand`, `GroupEndCommand`…
  **Sem nenhum import de `dart:ui` ou de Flutter.**
- **Criar** `lib/src/drawing/drawing_device_context.dart` — `DrawingDeviceContext extends
  DeviceContext`, que acumula comandos em vez de escrever XML.
- **Alterar** `lib/src/toolkit.dart` — `renderToDrawingCommands(int pageNo)`.
- **Criar** `example/flutter_canvas_painter.dart` — um exemplo **fora de `lib/`** mostrando como um
  `CustomPainter` consome os comandos. Este arquivo pode citar Flutter em comentário, mas
  **não deve ser compilado pelo package** (deixe-o em `example/` e documente).
- **Criar** `test/drawing_device_context_test.dart`.

## Passo a passo

1. Leia `lib/src/rendering/device_context.dart` e liste todos os métodos abstratos que o adapter
   tem de implementar.
2. Desenhe o tipo de comando. Cada comando carrega números e strings puros — nada de tipos de
   Flutter. Cores como `int` ARGB; caminhos como listas de segmentos.
3. Implemente `DrawingDeviceContext`.
4. Implemente `Toolkit.renderToDrawingCommands`.
5. Escreva o exemplo em `example/`.
6. **Teste de equivalência:** para ao menos 20 arquivos do corpus, renderize a mesma página em SVG e
   em comandos, e afirme que a **contagem e a ordem** das primitivas batem (um `<path>` no SVG
   corresponde a um `DrawPathCommand`, etc.). É o que prova que o adapter não perde nada.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 1030 testes**
- [ ] `grep -rn "dart:ui\|package:flutter" lib/` → **nenhum resultado**
- [ ] `dart pub publish --dry-run` não reclama de dependência de Flutter (ou, se reclamar de outra
      coisa, o relatório explica)
- [ ] O teste de equivalência passa para **≥ 20 arquivos**, comparando contagem e ordem de primitivas
- [ ] `example/flutter_canvas_painter.dart` existe e está documentado como exemplo não compilado
- [ ] Relatório em `prompts/reports/07-09.md`
- [ ] `PLANO.md`: checkbox de `DrawingDeviceContext` marcado

## Armadilhas conhecidas

- **`dart:ui` no core é o erro que esta tarefa existe para evitar.** Um único import quebra a web.
  O grep do critério de aceite é o guarda.
- Glifos SMuFL: no SVG viram `<use>` para um `<defs>`; no Canvas viram um caminho ou um desenho de
  fonte. O comando tem de carregar o **caminho** do glifo (de `assets/data/`), não só o código, para
  o consumidor não precisar do `Resources`.
- Transformações: o SVG usa `transform="scale(1,-1)"`; o comando tem de expressar o mesmo.
- Não invente primitivas que o `DeviceContext` não tem.

## Fora de escopo

- Escrever um app Flutter completo. Só o exemplo mínimo.
