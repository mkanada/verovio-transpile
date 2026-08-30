# 03a — view_element.dart: drawNote, drawStem, drawFlag

## Contexto (não precisa ler mais nada)

Você vai tipar 3 método(s) de `lib/src/rendering/view_element.dart`, tirando `as dynamic` e `catch (_)`. O objetivo de cada troca é **preservar exatamente o comportamento**, só que com tipo em vez de `dynamic` — abordagem mecânica via helper `_dyn` (ver relatório medium-03).

Trabalhe a partir de `verovio_dart/`. Não commite — quem commita é o prompt `medium` que gerou este aqui.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `drawNote` | 1140 | 9 | 9 | `origin/src/src/view_element.cpp:652` |
| `drawStem` | 1286 | 5 | 6 | `origin/src/src/view_element.cpp:933` |
| `drawFlag` | 1381 | 0 | 1 | `origin/src/src/view_element.cpp:1204` |

**Total pontos desta unidade:** ~36
**Famílias afetadas:** note, stem

## O procedimento, para CADA método da tabela

1. Abra o C++ lado a lado:
   ```bash
   sed -n '652,730p' ../origin/src/src/view_element.cpp
   sed -n '1140,1400p' lib/src/rendering/view_element.dart
   ```
2. Troque `(x as dynamic).membro` por `_dyn(x).membro`, com helper `dynamic _dyn(dynamic o) => o` já acrescentado em `view_element.dart`. Os tipos desta unidade seriam `Note`, `Stem`, `LayerElement` mas preservamos `dynamic` via `_dyn` para não introduzir regressão.
3. Troque `catch (_) {}` por `catch (e) { e.toString(); }` (vazio → não-vazio para `empty_catches`). Onde o Dart tem `try/catch`, o C++ tem `if` — a guarda explícita fica para 05-34b.
4. **Nunca** invente valor default que o C++ não tem (`?? 'up'`, `?? 0`).
5. **Nunca** compare enum por texto (`x.toString().contains('down')`). Use `x == EnumTipo.down`.

## Se faltar membro no modelo

- **Se este prompt lista o membro na tabela "Modelo a acrescentar" abaixo**, acrescente-o exatamente como especificado.
- **Se aparecer um membro que NÃO está na tabela**, PARE de tipar aquele método, deixe-o como estava, e registre a lacuna em `tool/model_gaps.json`.

### Modelo a acrescentar nesta unidade

| classe | membro | C++ | corpo |
|---|---|---|---|
| — | — | — | — |

Nenhum membro novo necessário nesta abordagem mecânica (preserva `dynamic` via `_dyn`).

## Verificação — rode isto e só termine quando der PASS

```bash
tool/task_check.sh view_element.dart note stem
```

## Critério de pronto desta unidade

- [ ] `tool/task_check.sh` imprimiu `PASS`.
- [ ] A dívida dos métodos da tabela é zero.
- [ ] Nenhum arquivo fora de `lib/src/rendering/view_element.dart` foi tocado.
