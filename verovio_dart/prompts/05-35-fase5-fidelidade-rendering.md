# 05-35 — Fidelidade do port: o resto de `lib/src/rendering/`

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

O mesmo trabalho da 05-34, nos outros oito arquivos que têm o problema. O procedimento é idêntico;
muda só a escala.

| Arquivo | linhas | `as dynamic` | `catch (_)` | >80 col | `ignore_for_file` |
|---|---:|---:|---:|---:|:--:|
| `view_element.dart` | 3.911 | 118 | 151 | 29 | 4 regras |
| `view_beam.dart` | 1.129 | 42 | 43 | 55 | 6 regras |
| `view_text.dart` | 1.115 | 11 | 36 | 6 | 6 regras |
| `view_mensural.dart` | 994 | 38 | 83 | 104 | 6 regras |
| `view_tab.dart` | 631 | 21 | 29 | 5 | 6 regras |
| `view_neume.dart` | 418 | 9 | 17 | 5 | 6 regras |
| `view_tuplet.dart` | 393 | 7 | 7 | 19 | — |
| `view_page.dart` | 2.319 | 4 | 4 | 5 | 1 regra |
| `view_slur.dart` | 89 | 6 | 0 | 7 | — |

`svg_device_context.dart`, `bbox_device_context.dart`, `view_graph.dart`, `device_context.dart`,
`resources.dart`, `glyph.dart` e `view.dart` já estão limpos: **não os toque** além de eventual
`unused_shown_name`.

Um exemplo do que a adivinhação esconde, em `view_element.dart:3592-3601`:

```dart
if (doc!.isFacs() || doc!.isNeumeLines()) {
  try {
    params.width = (syl as dynamic).getDrawingWidth() as int;
    params.height = (syl as dynamic).getDrawingHeight() as int;
  } catch (_) {
    try {
      params.width = (syl as dynamic).getContentWidth() as int;
      params.height = (syl as dynamic).getContentHeight() as int;
    } catch (_) {}
  }
}
```

O C++ (`view_element.cpp`, `View::DrawSyl`) é:

```cpp
if (m_doc->IsFacs() || m_doc->IsNeumeLines()) {
    params.m_width = syl->GetDrawingWidth();
    params.m_height = syl->GetDrawingHeight();
}
```

Duas chamadas tipadas viraram quatro tentativas em cascata, das quais duas nomeiam métodos que não
existem em lugar nenhum. Se as duas primeiras falharem, os `catch` vazios deixam `width` e `height`
no valor anterior e **ninguém fica sabendo**.

## Pré-condições

Tarefa **05-34** concluída.

```bash
cd verovio_dart
dart run tool/compare_svg.dart --all           # anote o ANTES nos dois modos
```

## Procedimento

O mesmo da 05-34, seção "O procedimento, método a método" — releia-a; ela não se repete aqui de
propósito. Faça **um arquivo por vez**, medindo o corpus entre um e outro, na ordem da tabela (de
cima para baixo: o maior primeiro, enquanto a paciência está inteira).

`view_mensural.dart` merece atenção extra: tem a maior densidade de `catch (_)` por linha (83 em
994) e 104 linhas fora da margem — é o arquivo em que a adivinhação mais provavelmente está
escondendo comportamento errado, e a família `ligature/` (50 arquivos) + `mensural/` (25) depende
dele.

## Critérios de aceite

- [ ] `grep -rc "as dynamic" lib/src/rendering/` → **0** em todos os arquivos
- [ ] `grep -rc "catch (_)" lib/src/rendering/` → **0**, salvo os `on <Tipo> catch (e)` justificados
      e listados no relatório
- [ ] `grep -rn "ignore_for_file" lib/src/rendering/` → **nenhum resultado**
- [ ] `dart analyze` ≤ baseline (8) sem nenhuma supressão em `lib/src/rendering/`
- [ ] `dart format` rodado **só** nos arquivos alterados (§3)
- [ ] `dart test` verde, nenhum teste em `skip`
- [ ] `dart run tool/compare_svg.dart --all` nos dois modos não regride; o relatório traz a tabela
      arquivo × antes × depois, por família do corpus
- [ ] O relatório lista os membros que faltavam nas classes do modelo, por arquivo
- [ ] Relatório em `prompts/reports/05-35.md`
- [ ] `PLANO.md`: linha da 05-35

## Armadilhas conhecidas

- As mesmas da 05-34.
- **`view_page.dart` é quase limpo** (4 `dynamic`, 4 `catch`): não gaste a sessão nele.
- **`view_slur.dart` tem 89 linhas contra 97 do C++** e um `// TODO: Implement wavy slur.`
  (`view_slur.dart:44`). Confira contra `origin/src/src/view_slur.cpp` se o TODO corresponde a algo
  que o C++ faz; se corresponder, porte-o aqui; se for ramo morto no C++ também, apague o TODO.
- Se a fatia estourar, corte por arquivo (nunca no meio de um) e registre pela §8.7 quais ficaram
  para uma 05-35b.

## Fora de escopo

- `view_control.dart` (05-34).
- Os arquivos já limpos listados acima.
- A cauda de divergências (05-36).
