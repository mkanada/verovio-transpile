# 2026-08-30-medium-04 — Zerar a tipagem: os cinco arquivos restantes

> Você é o **Sonnet**. Mesmo protocolo das `02` e `03`.
> Depende de `2026-08-30-medium-01`. Fecha os critérios 5.1, 5.2 e 5.3 do portão.

## Alvos

| arquivo | `as dynamic` | `catch (_)` | métodos | C++ |
|---|---|---|---|---|
| `view_tab.dart` | 21 | 29 | 5 | `view_tab.cpp` |
| `view_beam.dart` | 11 | 21 | 10 | `view_beam.cpp` |
| `view_text.dart` | 11 | 36 | 13 | `view_text.cpp` |
| `view_neume.dart` | 9 | 17 | 5 | `view_neume.cpp` |
| ~~`view_page.dart`~~ | ~~4~~ **0** | ~~4~~ **0** | — | feito em 2026-08-30 como exemplo de referência |
| `view.dart` | 0 | 0 | — | só o `ignore_for_file` |

São 56 `as dynamic` e 107 `catch (_)` em 37 métodos — o menor lote dos três, e
o que **fecha** 5.1/5.2/5.3.

## Ordem sugerida (do mais fácil ao mais arriscado)

1. ~~**`view_page.dart`**~~ — **já feito** em 2026-08-30, como exemplo
   trabalhado de ponta a ponta da série (veja "Exemplo de referência" abaixo).
2. **`view_neume.dart`** (9/17) — uma unidade. 2 erros expostos.
3. **`view_beam.dart`** (11/21) — uma ou duas unidades. 4 erros expostos.
4. **`view_tab.dart`** (21/29) — duas unidades. 6 erros expostos.
5. **`view_text.dart`** (11/36) — duas ou três unidades. 8 erros expostos.
   Desenha `lyric` (0/16) e `syl`; é o que tem mais chance de destravar
   família, e o que exige mais cuidado.
6. **`view.dart`** — só apagar o `ignore_for_file: unused_shown_name` e
   arrumar os `show` de import que ele esconde.

Os "erros expostos" acima foram medidos em 2026-08-30 assim (refaça para
confirmar antes de fatiar):

```bash
cp lib/src/rendering/<f>.dart /tmp/<f>.bak
python3 -c "
import pathlib,re
p=pathlib.Path('lib/src/rendering/<f>.dart'); t=p.read_text()
t=re.sub(r'\(([A-Za-z_][A-Za-z0-9_]*) as dynamic\)', r'\1', t)
t=t.replace('final dynamic ','final ')
p.write_text(t)"
dart analyze lib/src/rendering/<f>.dart | grep -c 'error -'
cp /tmp/<f>.bak lib/src/rendering/<f>.dart
```

Esse número é o tamanho real do trabalho de modelo daquele arquivo — use-o
para decidir se a unidade cabe num prompt `small` só.

## Exemplo de referência — `view_page.dart`, feito em 2026-08-30

Este arquivo foi zerado à mão para provar a cadeia inteira (medidor → unidade →
`task_check.sh` → sweep sem regressão). Use-o como modelo do que uma unidade
`small` deve parecer. `git show` do commit desta série mostra o diff.

O que a limpeza revelou — e é o argumento de que **isto não é cosmético**:

1. **`drawSystemList` tinha `ClassId.harm` no `timeSpanningClasses`, e o C++
   não tem** (`view_page.cpp:243-244`: a lista é ANNOTSCORE, BEAMSPAN,
   BRACKETSPAN, DIR, DYNAM, FIGURE, GLISS, HAIRPIN, LV, OCTAVE, ORNAM, PEDAL,
   PHRASE, PITCHINFLECTION, SLUR, SYL, TEMPO, TIE, TRILL — 19 entradas, sem
   HARM). O Dart mandava `harm` por `DrawTimeSpanningElement`; o C++ manda por
   `DrawControlElement`.

2. **Dois andaimes de Fase 5 emitiam `<g>` a mais.** Um caso especial de `syl`
   que desenhava gráfico vazio "até `DrawSylConnector` ser portado" — mas ele
   já está portado (`view_control.dart:1280`). E um `on UnimplementedError`
   que também emitia gráfico vazio, cujo `throw` só é alcançável com a opção
   `svgAdditionalAttribute`, que a Fase 7 nem plumbou. Os dois foram removidos.

   **Isto é exatamente a forma do defeito de `ligature`** (o Dart emite 11
   filhos onde o C++ emite 5). Procure andaimes iguais nos outros arquivos.

3. **`_convertHalign` está duplicado e as duas cópias divergem**:
   `view_text.dart:929` mapeia `default -> left`; `view_control.dart:4479`
   é total (`justify -> justify`, `none -> none_`). Como as duas são extensões
   sobre `View`, chamar de um terceiro arquivo dá `ambiguous_extension_member_access`.
   **Ao tipar `view_text.dart`, consolide as duas** numa só, na classe `View`
   em `view.dart`, e deixe cada chamador aplicar o próprio fallback — que é o
   que o C++ faz (`if (alignment == NONE) alignment = center;` no chamador).

   Onde só se precisa da ponte entre os dois enums, o caminho fiel é por valor
   numérico, que é idêntico nos dois lados:
   `HorizontalAlignment.fromValue(x.getChildRendAlignment().value)`.

Resultado medido: dívida 9 → 0, `dart analyze` 8, testes verdes,
`compare_svg --all` 116/621 sem regressão e sem exceção.

## Achados a considerar

- **`view_text.dart`**: `test/view_text_test.dart:41` tem catraca com limiar
  `greaterThanOrEqualTo(0)` — nunca falha. E `:81` usa `anyOf(..., contains('<use'))`,
  token ubíquo que passa mesmo sem o alvo. Quando `lyric` sair do zero,
  **aperte as duas asserções** (§10: apertar pode, afrouxar não).
- **`view_tab.dart`**: tablatura não tem família própria grande no corpus;
  verifique com `probe_diff` se há fixture cobrindo antes de deixar o Haiku
  mexer em modelo.

## Protocolo

Idêntico às `02` e `03`: baseline, fatiar, prompt `small` pelo template,
`tool/task_check.sh <arquivo>.dart <familias>` até `PASS`, remover o
`ignore_for_file` ao fim de cada arquivo.

Grave cada unidade como `prompts/2026-08-30-small-04<letra>-<slug>.md`
(ex.: `2026-08-30-small-04a-view-neume.md`).

## Critério de aceite — este é o que fecha 5.1/5.2/5.3

- [ ] `dart run tool/debt_report.dart` → `TOTAIS 5.1: 0   5.2: 0   5.3: 0`
      e **exit code 0**.
- [ ] `dart run tool/verify_phases.dart --fase=5` não reprova mais 5.1, 5.2
      nem 5.3 (só 5.6 continua aberto).
- [ ] `dart analyze` ≤ 8, sem supressão nova em `lib/src/rendering/`.
- [ ] `dart test` verde.
- [ ] `compare_svg --all` estrutural ≥ baseline; catraca atualizada se subiu.
- [ ] As asserções frouxas de `view_text_test.dart` apertadas, ou justificado
      no relatório por que ainda não dá.
- [ ] Relatório em `prompts/reports/2026-08-30-medium-04.md`, com a tabela final da
      dívida (tudo zero) colada da saída real.
- [ ] **Um commit** ao final.
