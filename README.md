# verovio-transpile

Port linha a linha do [Verovio 6.2.0](https://www.verovio.org/) — biblioteca C++ de gravação
musical que converte MEI, MusicXML e ABC em SVG — para **Dart puro**. O objetivo é equivalência
funcional com o C++, não uma reimplementação: na dúvida, o código espelha o original.

## Estrutura

| Caminho | Conteúdo |
|---|---|
| `origin/src/` | Fontes C++ 6.2.0 originais — referência de toda decisão de port. Somente leitura. |
| `verovio_dart/` | O package Dart. Todo o desenvolvimento acontece aqui. |
| `PLANO.md` | Roadmap de escopo e progresso do port. |
| `CLAUDE.md` | Convenções do repositório para quem for editar o código. |
| `verovio_dart/prompts/` | Série de prompts que guia a conclusão do port em tarefas pequenas e verificáveis. |

## Estado atual

Leitura de MEI/MusicXML/ABC e o modelo de dados estão portados. O motor de layout está parcial, e
a renderização para SVG, MIDI/timemap e a API pública do Toolkit ainda não foram portados. Detalhes
de progresso ficam em `PLANO.md` e `verovio_dart/prompts/AUDITORIA.md`.

## Comandos

Rode a partir de `verovio_dart/`:

```bash
dart test          # suíte de testes
dart analyze        # lints
```

Veja `CLAUDE.md` para o restante dos comandos (validação de layout, geração de goldens, geradores
de código) e as convenções do projeto.

## Fora de escopo

Humdrum, PAE (Plaine & Easie) e os filtros de notação desabilitados por padrão no C++ (darms, cmme,
volpiano, gabc) — decisão registrada em `PLANO.md`.
