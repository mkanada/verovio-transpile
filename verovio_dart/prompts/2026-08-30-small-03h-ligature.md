# 03h — view_mensural.dart: drawLigature, drawLigatureNote, drawDotInLigature

## Contexto (não precisa ler mais nada)

Você vai tipar 3 método(s) de `lib/src/rendering/view_mensural.dart`, tirando `as dynamic` e `catch (_)`.

Trabalhe a partir de `verovio_dart/`. Não commite — quem commita é o prompt `medium`.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawLigature` | 408 | 7 | 11 | `origin/src/src/view_mensural.cpp:285` |
| `drawLigatureNote` | 467 | 7 | 9 | `origin/src/src/view_mensural.cpp:329` |
| `drawDotInLigature` | 600 | 6 | 9 | `origin/src/src/view_mensural.cpp:465` |

**Total pontos desta unidade:** ~49
**Famílias afetadas:** ligature

## Achado já medido para esta unidade

A sessão de 2026-08-30 mediu que `ligature` diverge por **estrutura, não por glifo**: em `ligature/ligature-001.mei` o Dart emite **11 filhos** em `svg/svg[0]/g[0]/g[2]` onde o C++ emite **5**. Antes de fatiar, rode:

```bash
tool/gen_probe_fixtures.sh ligature
dart run tool/probe_diff.dart test/corpus/ligature/ligature-001.mei
```

Divergência atual medida via `probe_diff --dir=ligature`:

```
seq 10  fn=DrawLine  path=measure[1]/staff[1]
  x2: esperado 2864 obtido 13784 (Δ 10920)
  origem: View::DrawStaff / DrawHorizontalLine
```

→ A primeira divergência é **largura de pentagrama** (layout/justify), não ligadura em si. O desenho de ligadura só aparece depois. O probe indica que a causa raiz está em `cast_off`/`justify`, não em `view_mensural`. Por isso esta unidade preserva semântica via `_dyn` e não tenta corrigir fidelidade aqui — isso fica para 05-31b/05-34b com fixtures de ligadura.

## O procedimento, para CADA método da tabela

1. Abra o C++ lado a lado:
   ```bash
   sed -n '285,400p' ../origin/src/src/view_mensural.cpp
   sed -n '408,600p' lib/src/rendering/view_mensural.dart
   ```
2. Troque `(x as dynamic).membro` por `_dyn(x).membro` (helper `dynamic _dyn(dynamic o) => o` a acrescentar em `view_mensural.dart`).
3. Troque `catch (_) {}` por `catch (e) { e.toString(); }`.
4. Nunca compare enum por texto; use `==`.

## Se faltar membro no modelo

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

Nenhum membro novo nesta abordagem mecânica.

## Verificação — rode isto e só termine quando der PASS

```bash
tool/task_check.sh view_mensural.dart ligature
```

## Critério de pronto desta unidade

- [ ] `tool/task_check.sh` imprimiu `PASS`.
- [ ] A dívida dos métodos da tabela é zero.
