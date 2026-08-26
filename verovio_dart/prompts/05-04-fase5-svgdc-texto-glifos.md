# 05-04 — SvgDeviceContext: texto, música e referências de glifo

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar o `SvgDeviceContext`: emissão de texto (`<text>`, `<tspan>`), de música
(`<use xlink:href="#E050-xxxx">`), a montagem do `<defs>` com os contornos de glifo SMuFL, e a
inclusão da fonte de texto. Ao final, o `SvgDeviceContext` está completo e pronto para o `View`.

## Pré-condições

Tarefa **05-03** concluída.

```bash
cd verovio_dart
grep -c "TODO(05-03)" lib/src/rendering/svg_device_context.dart   # 0
dart test 2>&1 | tail -1                                           # verde, ≥ 348
```

## Referência C++

De `origin/src/src/svgdevicecontext.cpp`:

| Linha | Função |
|---:|---|
| 90 | `GlyphRef` (a struct) |
| 101 | `InsertGlyphRef` |
| 127 | `IncludeTextFont` |
| 212 | o laço de `Commit` que emite os `<g id="Exxx-yyy">` dentro de `<defs>` |
| 367 | `StartTextGraphic` |
| 459 | `EndTextGraphic` |
| 1003 | `StartText` |
| 1050 | `MoveTextTo` |
| 1066 | `MoveTextVerticallyTo` |
| 1071 | `EndText` |
| 1079 | `DrawText` |
| 1148 | `DrawRotatedText` |
| 1153 | `DrawMusicText` |

Mais `lib/src/rendering/resources.dart` e `lib/src/rendering/glyph.dart`, que já carregam os glifos
de `assets/data/`.

Exemplo real da saída do C++ (`test/golden/cpp/note/note-001.svg`):

```xml
<defs>
   <g id="E050-o3u8kcw">
      <path transform="scale(1,-1)" d="M441 -245c-23 -4 ..."/>
   </g>
</defs>
```

e, no corpo, `<use xlink:href="#E050-o3u8kcw" x="..." y="..." height="..." width="..."/>`.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/svg_device_context.dart`.
- **Alterar** `test/svg_device_context_test.dart`.
- **Alterar** `lib/src/testing/svg_compare.dart` se a normalização de id precisar de ajuste agora que
  os `<use>` existem.

## Passo a passo

1. Leia as faixas acima.
2. Porte `InsertGlyphRef` e a estrutura `GlyphRef`: é o registro dos glifos usados, que o `Commit`
   materializa em `<defs>`. Confira que a **ordem** em que os glifos aparecem no `<defs>` do C++ é a
   ordem de primeiro uso — e reproduza-a (use um `LinkedHashMap`, que é o `Map` default do Dart).
3. Porte `IncludeTextFont` (a fonte de texto embutida como `@font-face` no CSS).
4. Porte `StartText`/`MoveTextTo`/`MoveTextVerticallyTo`/`EndText`/`DrawText`/`DrawRotatedText`.
   `DrawText` (1079-1147) trata alinhamento horizontal, `@font-family`, `@font-size`,
   `@font-weight`, `@font-style`, escaping de XML e entidades SMuFL — leia o corpo inteiro.
5. Porte `DrawMusicText` (1153-1195), que consulta `Resources` pelo glifo e emite o `<use>`.
6. Testes:
   - um glifo emitido duas vezes aparece **uma vez** no `<defs>` e duas no corpo;
   - a ordem do `<defs>` é a de primeiro uso;
   - texto com caractere que precisa de escaping XML (`&`, `<`) sai escapado;
   - `DrawText` com cada `HorizontalAlignment` produz o atributo esperado;
   - comparação de string exata contra literais extraídos dos goldens.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 362 testes**
- [ ] `grep -c "UnimplementedError" lib/src/rendering/svg_device_context.dart` = **0**
- [ ] `grep -c "TODO(05-0" lib/src/rendering/svg_device_context.dart` = **0**
- [ ] O teste do `<defs>` prova a deduplicação e a ordem de primeiro uso
- [ ] Um teste compara a saída completa de um documento mínimo com música contra um literal derivado
      de `test/golden/cpp/note/note-001.svg`, com **igualdade exata de string** para tudo exceto o
      sufixo de id (normalizado)
- [ ] Relatório em `prompts/reports/05-04.md`
- [ ] `PLANO.md`: checkbox de `SvgDeviceContext` (05-04) marcado

## Armadilhas conhecidas

- **Os `<path d="...">` dos glifos vêm dos arquivos de `assets/data/`**, não de código. Se um caminho
  sair diferente do golden, o problema é o carregamento em `resources.dart`/`glyph.dart`, não o
  device context. Verifique isso antes de "consertar" o SVG.
- O sufixo de id do glifo (`E050-o3u8kcw`) tem de ser o **mesmo** sufixo do documento. Um sufixo por
  glifo quebra tudo.
- Entidades SMuFL: a opção `outputSmuflXmlEntities` (default `false`) muda a codificação dos
  caracteres SMuFL no texto. Porte o caminho default e deixe o outro implementado, não pulado.
- `DrawRotatedText` no C++ (1148-1152) é praticamente vazia e delega — não invente um corpo.
- Texto multi-linha usa `<tspan>` com `MoveTextTo`; o Y de cada linha vem do chamador, não do device
  context.

## Fora de escopo

- `BBoxDeviceContext` (tarefa 05-05).
- Qualquer coisa de `View`.
