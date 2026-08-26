# 07-10 — Documentação, exemplos, pubspec e benchmark

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar o port: documentação pública da API, exemplos executáveis, `pubspec.yaml` pronto para
publicação, um benchmark básico, e um relatório final consolidando o estado de equivalência com o
C++ em todos os eixos medidos.

## Pré-condições

Tarefa **07-09** concluída.

```bash
cd verovio_dart
grep -rn "dart:ui" lib/ | wc -l    # 0
dart test 2>&1 | tail -1           # verde, ≥ 1030
```

## Referência C++

`origin/src/README.md`, `origin/src/doc/` e `origin/src/bindings/` (para ver que superfície de API os
outros bindings expõem — é um bom guia do que documentar).

## Arquivos Dart a criar/alterar

- **Criar/alterar** `verovio_dart/README.md`.
- **Alterar** `lib/verovio_dart.dart` — conferir que a API pública exportada é a certa e nada de
  `src/` vaza sem querer.
- **Criar** `example/` — ao menos: `mei_to_svg.dart`, `musicxml_to_mei.dart`, `mei_to_midi.dart`,
  `options.dart`, mais o `flutter_canvas_painter.dart` da tarefa 07-09.
- **Alterar** `pubspec.yaml` — descrição, versão, homepage, `topics`, assets.
- **Criar** `tool/benchmark.dart`.
- **Criar** `prompts/reports/RESUMO-FINAL.md`.
- **Alterar** `CHANGELOG.md` (criar se não existir).

## Passo a passo

1. **API pública.** Rode `dart doc` e veja o que sai. Todo símbolo exportado por
   `lib/verovio_dart.dart` precisa de doc comment. Símbolos internos não devem ser exportados.
2. **README**: o que é, como instalar, um exemplo de 10 linhas, a tabela de formatos suportados,
   o que está fora de escopo (Humdrum, PAE, darms/cmme/volpiano/gabc) e por quê, e o estado de
   equivalência com o C++ com os números reais.
3. **Exemplos** executáveis com `dart run example/<nome>.dart`.
4. **`pubspec.yaml`**: confira que `assets/data/` (12 MB) está incluído e que as dependências são só
   as necessárias.
5. **`tool/benchmark.dart`**: mede o tempo de load, layout e render para um conjunto fixo de
   arquivos (pequeno, médio, grande), e compara com o tempo do `build/verovio` nos mesmos arquivos.
   Emite `tool/BENCHMARK.md`.
6. **`prompts/reports/RESUMO-FINAL.md`**: a tabela consolidada de equivalência, com os números de
   todas as validações:

   | Eixo | Ferramenta | Resultado |
   |---|---|---|
   | SVG estrutural | `tool/compare_svg.dart --mode=structural` | N/623 |
   | SVG numérico (eps=0) | `tool/compare_svg.dart --mode=numeric --epsilon=0` | N/623 |
   | Timemap | `tool/validate_timemap.dart` | N/623 |
   | MIDI (bytes) | `tool/validate_midi.dart` | N/623 |
   | MEI (saída) | round-trip + comparação com C++ | N/623 |
   | Layout estrutural | `tool/validate_layout.dart` | N/621 |
   | `--help` | `diff` contra o C++ | idêntico / difere |
   | Testes | `dart test` | N testes |
   | Performance | `tool/benchmark.dart` | ×N vs. C++ |

   Mais uma seção **"Divergências conhecidas"**, consolidando as que sobraram nos relatórios das
   tarefas anteriores, cada uma com hipótese de causa.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde
- [ ] `dart doc` roda sem aviso de símbolo público sem documentação
- [ ] Cada arquivo de `example/` roda com `dart run` e produz a saída esperada — o relatório mostra a
      saída de cada um
- [ ] `dart pub publish --dry-run` passa (ou o relatório explica o que falta e por quê)
- [ ] `dart run tool/benchmark.dart` produz `tool/BENCHMARK.md` com a comparação contra o C++
- [ ] `prompts/reports/RESUMO-FINAL.md` existe com a tabela consolidada preenchida com números reais
- [ ] `PLANO.md`: Fase 7 inteira marcada, e a seção "Definição de pronto (v1.0)" atualizada com o
      que foi e o que não foi atingido
- [ ] Relatório em `prompts/reports/07-10.md`

## Armadilhas conhecidas

- `assets/data/` tem 12 MB; o pub.dev tem limite de tamanho de package. Confira antes de anunciar que
  está pronto para publicar, e se estourar, registre a alternativa (baixar os assets em tempo de
  execução, ou um package separado).
- `dart doc` reclama de links `[[...]]` quebrados nos doc comments.
- O benchmark contra o C++ não é justo se você medir o startup do processo. Meça só a parte de
  processamento, e diga como mediu.
- **Não infle os números do resumo final.** Se um eixo ficou em 60%, escreva 60%. O valor do
  documento é ser verdadeiro.

## Fora de escopo

- Publicar de fato no pub.dev — é decisão do dono do projeto.
