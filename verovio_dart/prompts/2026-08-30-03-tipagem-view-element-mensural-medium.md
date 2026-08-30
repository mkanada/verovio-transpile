# 2026-08-30-03 (medium) — Zerar a tipagem: `view_element.dart` e `view_mensural.dart`

> Você é o **Sonnet**. Mesmo protocolo da `2026-08-30-02`: fatia, escreve os
> `small`, roda o Haiku, valida o lote, commita uma vez.
> Depende de `2026-08-30-01`. Pode rodar antes ou depois da `02`.

## Alvos

| arquivo | `as dynamic` | `catch (_)` | métodos com dívida | C++ |
|---|---|---|---|---|
| `view_element.dart` | 116 | 149 | 38 | `view_element.cpp` (3.913 linhas) |
| `view_mensural.dart` | 37 | 77 | 10 | `view_mensural.cpp` (461 linhas) |

`view_element` desenha nota, acorde, haste, acidente, articulação, pausa,
clave, armadura, fórmula de compasso — a base de quase todo arquivo do corpus.
`view_mensural` desenha ligadura e notação mensural: `ligature` está **0/50** e
`mensural` **0/25**, as duas maiores famílias em zero.

## Por que os dois juntos

Compartilham a cabeça de nota: `Note.getNoteheadGlyph`,
`Note.getMensuralNoteheadGlyph` e `LayerElement.getDrawingRadius` (portados na
sessão de 2026-08-30 e já tipados no modelo). Tipar um sem o outro faz o mesmo
raciocínio duas vezes.

## Fatiamento sugerido

`view_element.dart` (38 métodos) — agrupe por família `Draw*` do C++:

| unidade | métodos | famílias |
|---|---|---|
| 03a | `drawNote`, `drawStem`, `drawFlag` | note, stem |
| 03b | `drawChord`, `drawDots`, `drawDotsPart` | chord, dot |
| 03c | `drawAccid`, `drawArtic` | accid, artic |
| 03d | `drawRest`, `drawMRest`, `drawMultiRest`, `drawBeatRpt` | rest, multirest |
| 03e | `drawClef`, `drawKeySig`, `drawMeterSig`, `drawMensur` | clef, keysig, meterssig |
| 03f | `drawBarLine`, `drawSpace`, `drawCustos`, `drawDivLine` | barline, custos |
| 03g | o que sobrar de `--by-method` | conforme |

`view_mensural.dart` (10 métodos):

| unidade | métodos | famílias |
|---|---|---|
| 03h | `drawLigature`, `drawLigatureNote`, `drawDotInLigature` | ligature |
| 03i | `drawMensuralStem`, `drawMaximaToBrevis`, `drawPlica`, `getMensuralStemDir` | mensural |
| 03j | `drawProport`, `drawProportFigures`, `calcBrevisPoints`, `calcObliquePoints` | mensural, proport |

## Achado já medido para a unidade 03h

A sessão de 2026-08-30 mediu que `ligature` diverge por **estrutura, não por
glifo**: em `ligature/ligature-001.mei` o Dart emite **11 filhos** em
`svg/svg[0]/g[0]/g[2]` onde o C++ emite **5**. Antes de fatiar 03h, rode

```bash
tool/gen_probe_fixtures.sh ligature
dart run tool/probe_diff.dart test/corpus/ligature/ligature-001.mei
```

e ponha a divergência exata no prompt `small`. Isso é o que transforma
"ligature está 0/50" em tarefa executável.

Para `mensural`, o mesmo: `<defs>` do Dart tem 20 glifos contra 26 do C++, com
4 extras (`E084/E086/E088/E925`). O `probe_diff` diz qual chamada de desenho
produz cada extra.

## Protocolo (idêntico à `02`)

1. `dart run tool/compare_svg.dart --all` e `tool/task_check.sh --baseline`.
2. Para cada unidade: leia o C++, anote os tipos, anote as guardas que o C++
   tem onde o Dart tem `catch (_)`, gere fixture da família, escreva o `small`
   pelo `prompts/2026-08-30-TEMPLATE-small.md`.
3. Membro de modelo faltante: com fixture cobrindo, escreva o corpo pronto no
   prompt; sem fixture, porte você mesmo antes de soltar a unidade.
4. Haiku roda até `tool/task_check.sh <arquivo>.dart <familias>` dar `PASS`.
5. Ao fim de cada arquivo, remova o `ignore_for_file` dele.

## Critério de aceite

- [ ] `debt_report --file=view_element.dart` → `0 0 0`.
- [ ] `debt_report --file=view_mensural.dart` → `0 0 0`.
- [ ] Nenhum `ignore_for_file` nos dois arquivos.
- [ ] `dart analyze` ≤ 8; `dart test` verde.
- [ ] `compare_svg --all` estrutural ≥ baseline. Se `ligature` ou `mensural`
      saírem do zero, diga **qual causa** destravou — é o resultado que esta
      tarefa persegue.
- [ ] Catraca `pisoEstrutural` atualizada se o número subiu.
- [ ] Relatório em `prompts/reports/2026-08-30-03.md`.
- [ ] **Um commit** ao final.
