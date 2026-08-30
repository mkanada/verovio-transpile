# 2026-08-30-02 (medium) — Zerar a dívida de tipagem: `view_control.dart`

> Você é o **Sonnet**. Leia `prompts/00-MESTRE.md` (§10) e `CLAUDE.md`.
> Trabalhe a partir de `verovio_dart/`. Depende de `2026-08-30-01` (instrumento).
>
> Aqui você **coordena**: fatia o trabalho, escreve os prompts `small`, roda o
> Haiku em cada um, valida o lote e commita **uma vez** ao final.

## Alvo

`lib/src/rendering/view_control.dart` — o pior arquivo do port:
**237 `as dynamic`, 280 `catch (_)`, 1 `ignore_for_file`**, em **42 métodos**.
Contraparte: `origin/src/src/view_control.cpp` (3.306 linhas).

Medição inicial (cole no relatório):
```bash
dart run tool/debt_report.dart --file=view_control.dart --by-method
```

## Por que este arquivo importa mais que os outros

Ele desenha dir, dynam, tempo, trill, octave, pedal, hairpin, tie, syl —
famílias que estão **todas em zero** no `compare_svg`. E foi nele que a sessão
anterior mediu os defeitos que a tipagem revela: `contains('n')` casando todo
valor de enum, `contains('coda')` casando `daCapoAlCoda`, pedal `@dir="up"`
desenhando o glifo errado. Cada `catch (_)` aqui é um ramo de desenho
possivelmente pulado em silêncio.

## Passo 1 — baseline do lote

```bash
dart run tool/compare_svg.dart --all          # ~10 min, deixa o relatório fresco
tool/task_check.sh --baseline
```

## Passo 2 — fatiar em unidades Haiku

Agrupe os 42 métodos em unidades de **3 a 6 métodos** ou **até ~60 pontos de
dívida**, o que vier primeiro. Agrupe por **família `Draw*` do C++**, nunca
corte uma família ao meio — métodos da mesma família compartilham helpers e
tipos, e o Haiku erra menos quando o contexto é coeso.

Agrupamento sugerido (ajuste ao que `--by-method` mostrar):

| unidade | métodos | famílias de corpus afetadas |
|---|---|---|
| 02a | `drawEnding` (73 pontos — sozinho) | ending, measure |
| 02b | `drawDynam`, `drawDynamSymbolOnly`, `_collectDynamText` | dynam |
| 02c | `drawOctave`, `_getOctaveGlyph`, `_getOctaveLineWidth` | octave |
| 02d | `drawControlElementText`, `drawTextEnclosure` | dir, tempo, cpmark |
| 02e | `drawHarm`, `drawFb`, `drawFConnector` | harm, figured-bass |
| 02f | `drawTempo`, `drawTimeSpanningElement` | tempo |
| 02g | `drawSylConnector`, `drawSylConnectorLines`, `_getSylYRel` | lyric, syl |
| 02h | `drawBracketSpan`, `drawPedalLine`, `drawTrillExtension`, `drawControlElementConnector` | bracketspan, pedal, trill |
| 02i | `drawTie`, `_calculateTiePosition`, `_tieIsAbove`, `_tieMidpointThickness`, `_tieEndpointThickness` | tie, lv |
| 02j | `_getHairpinBarlineOverlapAdjustment` + o que sobrar | hairpin |

Para **cada** unidade, antes de escrever o prompt, faça o trabalho de juízo que
o Haiku não pode fazer:

1. Leia o método C++ correspondente inteiro.
2. Anote o **tipo de cada parâmetro** que hoje é `dynamic` (o C++ diz).
3. Anote, para cada `catch (_)`, **qual guarda o C++ tem no mesmo ponto**.
4. Rode o probe para saber se a família tem fixture:
   ```bash
   tool/gen_probe_fixtures.sh <familia>
   dart run tool/probe_diff.dart --dir=test/corpus/<familia> | head -20
   ```
5. Se a tipagem exigir membro novo de modelo:
   - **com fixture cobrindo o caminho de desenho** → escreva a assinatura e o
     corpo prontos na tabela "Modelo a acrescentar" do prompt `small`, citando
     `origin/src/...:linha`. O Haiku pode aplicar.
   - **sem fixture cobrindo** → você mesmo porta o membro, aqui, antes de
     soltar a unidade. O Haiku não porta às cegas.

## Passo 3 — escrever e rodar os prompts `small`

Use `prompts/2026-08-30-TEMPLATE-small.md`. Grave como
`prompts/2026-08-30-02<letra>-<slug>-small.md`.

Rode uma unidade por vez. O Haiku só termina quando
`tool/task_check.sh view_control.dart <familias>` imprimir `PASS`.

Se uma unidade falhar duas vezes seguidas no mesmo ponto, **não insista**:
refatore o prompt (fatia menor, mais contexto, o tipo escrito explicitamente)
e rode de novo. Prompt ruim é responsabilidade sua, não do Haiku.

## Passo 4 — o `ignore_for_file`

Depois que a dívida de `as dynamic` e `catch (_)` do arquivo chegar a zero,
remova a diretiva `// ignore_for_file:` do topo — em especial
`invalid_assignment`, `argument_type_not_assignable` e
`unchecked_use_of_nullable_value`, que existem só para esconder erro de tipo.

Trate o que o analisador apontar. `dart analyze` tem de continuar em 8.

## Passo 5 — validar o lote e commitar

```bash
dart run tool/debt_report.dart --file=view_control.dart   # tem de dar 0 0 0
dart analyze                                             # 8
dart test                                                # verde
dart run tool/compare_svg.dart --all                     # não regride
dart run tool/probe_diff.dart --dir=test/corpus --rank | head -20
```

O `compare_svg` **não pode cair**. Se cair, a tipagem mudou semântica: use
`probe_diff` para achar em qual método e conserte antes de commitar.

Se subir, ótimo — atualize `pisoEstrutural` em `test/svg_golden_test.dart`
para travar o ganho (a catraca exige isso).

## Critério de aceite

- [ ] `dart run tool/debt_report.dart --file=view_control.dart` → `0 0 0`.
- [ ] Nenhum `ignore_for_file` em `view_control.dart`.
- [ ] `dart analyze` ≤ 8, sem supressão nova.
- [ ] `dart test` verde.
- [ ] `compare_svg --all` estrutural **≥** o valor da baseline do Passo 1.
- [ ] Tabela antes × depois por método no relatório.
- [ ] Cada defeito de semântica que a tipagem revelou está no relatório com o
      C++ citado (é o achado mais valioso desta tarefa — não o omita).
- [ ] `tool/model_gaps.json` vazio ou com as pendências justificadas.
- [ ] Relatório em `prompts/reports/2026-08-30-02.md`.
- [ ] **Um commit** ao final de todo o lote.
