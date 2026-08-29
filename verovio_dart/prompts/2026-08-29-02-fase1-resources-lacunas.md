# 2026-08-29-02 — Fase 1: as duas últimas lacunas de `Resources`

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar a Fase 1. Restam **dois** métodos de `origin/src/include/vrv/resources.h` sem contraparte
em `lib/src/rendering/resources.dart`:

| C++ | Onde | O que faz |
|---|---|---|
| `Resources::SetCSSFont(const std::string &fontName)` | `resources.h`, `resources.cpp` | fixa a fonte de texto usada na emissão de CSS do SVG |
| `Resources::UseLiberationTextFont(bool)` | `resources.h`, `resources.cpp` | troca a família de texto Times ↔ Liberation |

Tarefa pequena e de baixo risco. Ela existe porque a Fase 1 foi declarada pronta com
38/40 métodos e o portão de verificação (`tool/verify_phases.dart`, critério 1.1) reprova
enquanto estes dois faltarem.

## Pré-condições

```bash
cd verovio_dart
dart run tool/verify_phases.dart --fase=1
# esperado hoje: FALHA 1.1 — "sem contraparte: UseLiberationTextFont → useLiberationTextFont,
#                              SetCSSFont → setCssFont"
```

## O que fazer

1. **Leia os dois métodos no C++** (`origin/src/src/resources.cpp` e o header). Note que o Dart já
   tem o estado que eles manipulam: o campo público `useLiberation` (`resources.dart:62`) e
   `getCSSFontFor(String fontName)` (`resources.dart:273`). O que falta são os *setters* com a
   semântica do C++, não o estado.

2. **Porte os dois**, com doc comment citando o contraparte C++, como manda o §4 do MESTRE. Duas
   armadilhas:
   - `UseLiberationTextFont` no C++ **não é** só `m_useLiberationTextFont = x`: confira se ele
     invalida ou recarrega alguma tabela de texto. Se invalidar, o Dart tem de invalidar também —
     o campo `textFont` e `currentFontName` são o estado equivalente aqui.
   - `SetCSSFont` interage com `LoadedFont::GetCSSFont(path)` (`resources.dart:36`). Leia como o
     C++ escolhe entre a fonte pedida e o fallback antes de escrever qualquer coisa.

3. **Se um dos dois for `inline` trivial no header** e o Dart já o cobrir de forma idiomática por
   um campo público, a saída correta **não** é portá-lo à força: é acrescentar a equivalência ao
   mapa `kResourcesEquivalentes` em `tool/verify_phases.dart`, com um comentário dizendo por quê.
   O mapa existe exatamente para isso. Mas prove primeiro, lendo o C++ — não é para usar como
   atalho quando dá trabalho.

4. **Teste.** `test/resources_device_context_test.dart` é o arquivo natural. Um teste por método,
   afirmando o efeito observável (que fonte sai no CSS; qual família de texto passa a valer), não
   a existência do método.

## Critérios de aceite

- [ ] `dart run tool/verify_phases.dart --fase=1` → **PASS**
- [ ] `dart analyze` ≤ 8
- [ ] `dart test` verde, com os testes novos
- [ ] `dart format` só nos arquivos alterados
- [ ] Relatório em `prompts/reports/2026-08-29-02.md`
- [ ] `PLANO.md`: nada a marcar — a Fase 1 já está `[x]`; registre no relatório que a lacuna
      residual medida em 2026-08-26 foi fechada

## Fora de escopo

- Qualquer outro arquivo de `lib/src/rendering/` (a dívida de tipagem é 05-34/05-35).
- Carregamento de fontes custom por zip.
