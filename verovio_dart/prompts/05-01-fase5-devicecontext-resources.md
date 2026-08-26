# 05-01 — DeviceContext e Resources: fechar as lacunas contra o C++

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Completar `lib/src/rendering/device_context.dart`, `lib/src/core/devicecontextbase.dart` e
`lib/src/rendering/resources.dart` contra o C++, para que o `SvgDeviceContext` e o `View` das
tarefas seguintes tenham toda a base de que precisam.

## Pré-condições

Tarefa **05-00** concluída.

```bash
cd verovio_dart
ls tool/compare_svg.dart lib/src/testing/svg_compare.dart
dart test 2>&1 | tail -1     # verde, ≥ 310
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/include/vrv/devicecontext.h` | — | a interface abstrata inteira |
| `origin/src/src/devicecontext.cpp` | 333 | `GetResources`, `SetViewBoxFactor`, `SetPen`, `SetBrush`, `SetFont`, `GetFont`, `ResetPen/Brush/Font`, `DeactivateGraphic`, `DeactivateGraphicX`, `DeactivateGraphicY`, `ReactivateGraphic`, `GetTextExtent` (2 sobrecargas), `GetSmuflTextExtent`, `AddGlyphToTextExtend` |
| `origin/src/include/vrv/devicecontextbase.h` | — | `Pen`, `Brush`, `FontInfo`, `Point`, `BezierCurve`, `TextExtend` |
| `origin/src/include/vrv/resources.h` | — | a classe `Resources` inteira |
| `origin/src/src/resources.cpp` | — | as implementações |

Lacunas medidas em 2026-08-26 (reconfira antes de portar; podem ter mudado):

**`Resources`** — sem contraparte em `lib/src/rendering/resources.dart`:
`AddCustom`, `GetCustomFontname`, `GetSmuflGlyphForUnicodeChar`, `LoadAll`, `UseLiberationTextFont`,
`IsCurrentFontFallback`, `Ok`, `GetPath`/`SetPath`, `SetCSSFont`.

**`DeviceContext`** — confira método a método com:
```bash
grep -oP '^\s+\w[\w:*&<>, ]*\s+\K\w+(?=\()' origin/src/include/vrv/devicecontext.h | sort -u
grep -oP '^\s+(abstract\s+)?\w[\w<>,? ]*\s+\K\w+(?=\()' lib/src/rendering/device_context.dart | sort -u
```

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/resources.dart`.
- **Alterar** `lib/src/rendering/device_context.dart`.
- **Alterar** `lib/src/core/devicecontextbase.dart` se faltar campo em `Pen`/`Brush`/`FontInfo`/
  `BezierCurve`/`TextExtend`.
- **Alterar** `test/resources_device_context_test.dart`.

## Passo a passo

1. Rode os dois greps acima e monte a lista real do que falta. **Cole essa lista no relatório.**
2. Porte o que falta em `Resources`, na ordem do header C++. `LoadAll` e `AddCustom` mexem com o
   `resourceFileReader` plugável que já existe — não quebre a compatibilidade web
   (`lib/src/core/file_reader.dart` usa import condicional; **não importe `dart:io` diretamente**).
3. Porte o que falta em `DeviceContext` e em `devicecontextbase.dart`.
4. Confira que `Resources.defaultPath` continua com o valor de hoje (`'data'`) — **não o mude**:
   testes e tools o sobrescrevem para `'assets/data'`, e mudar o default agora quebra a convenção
   documentada. Se quiser corrigi-lo, é outra tarefa.
5. Acrescente testes em `test/resources_device_context_test.dart` para cada método novo. Em especial
   `GetSmuflGlyphForUnicodeChar`, que tem uma tabela de mapeamento no C++ — teste ao menos 5 pares.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 320 testes**
- [ ] Nenhum método público de `origin/src/include/vrv/resources.h` sem contraparte em
      `lib/src/rendering/resources.dart` — prove colando no relatório a saída do diff de nomes
      (mesmo comando do passo 1, agora vazio ou só com desvios justificados)
- [ ] `lib/src/rendering/resources.dart` **não** importa `dart:io`
      (`grep -c "dart:io" lib/src/rendering/resources.dart` = 0)
- [ ] `dart run tool/compare_svg.dart --all` continua rodando e reportando `0/623` (nada mudou ainda)
- [ ] Relatório em `prompts/reports/05-01.md`
- [ ] `PLANO.md`: checkbox de `devicecontext.cpp`/Resources da Fase 5 marcado

## Armadilhas conhecidas

- `lib/src/core/file_reader.dart` existe **exatamente** para manter o package válido na web.
  Importar `dart:io` em qualquer lugar de `lib/` fora dele quebra isso silenciosamente (só falha
  ao compilar para web). Use `resourceFileReader`.
- `FontInfo` no C++ carrega estado de estilo (weight, style, family, supplement) que o SVG usa
  literalmente nos atributos. Campo faltando aqui vira divergência de atributo lá na frente.
- `GetTextExtent` tem duas sobrecargas no C++ (String e UTF-32); as duas já existem em Dart
  (`device_context.dart:214` e `:219`) — confira o comportamento, não só a assinatura.

## Fora de escopo

- `SvgDeviceContext` (tarefas 05-02 a 05-04).
- `BBoxDeviceContext` (tarefa 05-05).
