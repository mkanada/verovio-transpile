# 2026-08-30-small-TEMPLATE — molde dos prompts do Haiku (não execute este arquivo)

> Este é o molde que os prompts `medium` preenchem para gerar cada unidade de
> trabalho do Haiku. Copie, substitua os `<…>` e grave como
> `prompts/2026-08-30-small-<nn>-<slug>.md`.
>
> **Regra de ouro do molde:** o Haiku não decide nada. Tudo que exige juízo
> (qual é a semântica correta, qual método do C++ portar) já vem resolvido
> aqui dentro, com arquivo e linha. O que sobra para o Haiku é executar e
> verificar.

---

# <nn> — <arquivo>: <lista dos métodos desta unidade>

## Contexto (não precisa ler mais nada)

Você vai tipar `<N>` método(s) de `lib/src/rendering/<arquivo>.dart`, tirando
`as dynamic` e `catch (_)`. O objetivo de cada troca é **preservar exatamente
o comportamento**, só que com tipo em vez de `dynamic`.

Trabalhe a partir de `verovio_dart/`. Não commite — quem commita é o prompt
`medium` que gerou este aqui.

## Métodos desta unidade

| método | linha | `as dynamic` | `catch (_)` | contraparte C++ |
|---|---|---|---|---|
| `<metodo>` | `<linha>` | `<n>` | `<n>` | `origin/src/src/<arq>.cpp:<linha>` |

## O procedimento, para CADA método da tabela

1. Abra o C++ lado a lado:
   ```bash
   sed -n '<linha_cpp>,<linha_cpp+80>p' ../origin/src/src/<arq>.cpp
   ```
2. Abra o Dart:
   ```bash
   sed -n '<linha>,<linha+80>p' lib/src/rendering/<arquivo>.dart
   ```
3. Troque `(x as dynamic).membro` por `x.membro`, com `x` no tipo que o C++
   usa na mesma posição. Os tipos desta unidade são:
   <lista: nome do parâmetro -> tipo Dart, ex.: `dynam` -> `Dynam`>
4. Troque `catch (_) {}` pelo teste explícito que o C++ faz no mesmo ponto.
   O C++ nunca usa exceção para fluxo: onde o Dart tem `try/catch`, o C++ tem
   um `if`. Padrões:
   - `try { x = a.getFoo(); } catch (_) { return; }` → `final T? x = a.getFoo(); if (x == null) return;`
   - `try { … } catch (_) {}` em volta de um desenho → remova o `try`, e se o
     C++ tiver uma guarda (`if (!foo) return;`), porte a guarda.
   - `int v = 0; try { v = a.bar as int; } catch (_) {}` → `final int v = a.bar;`
5. **Nunca** invente valor default que o C++ não tem (`?? 'up'`, `?? 0`).
   Se o atributo é opcional no C++, o Dart usa o mesmo default do C++.
6. **Nunca** compare enum por texto (`x.toString().contains('down')`). Use
   `x == EnumTipo.down`. Comparação por texto é a causa de defeito nº 1 deste
   arquivo — `contains('n')` casa *todo* valor do enum.

## Se faltar membro no modelo

Alguns membros que o C++ tem podem não existir em `lib/src/model/`.

- **Se este prompt lista o membro na tabela "Modelo a acrescentar" abaixo**,
  acrescente-o exatamente como especificado — a assinatura e o corpo vêm
  prontos, com o C++ citado.
- **Se aparecer um membro que NÃO está na tabela**, PARE de tipar aquele
  método, deixe-o como estava, e registre a lacuna:
  ```bash
  python3 - <<'PY'
  import json, pathlib
  p = pathlib.Path('tool/model_gaps.json')
  gaps = json.loads(p.read_text()) if p.exists() else []
  gaps.append({"unidade": "<nn>", "arquivo": "<arquivo>.dart",
               "metodo": "<metodo>", "membro_faltante": "<Classe.membro>",
               "cpp": "<origin/src/... se souber, senão vazio>"})
  p.write_text(json.dumps(gaps, indent=2, ensure_ascii=False) + "\n")
  PY
  ```
  Depois siga para o próximo método. **Não invente o membro.**

### Modelo a acrescentar nesta unidade

<vazio, ou:>

| classe | membro | C++ | corpo |
|---|---|---|---|
| `<Classe>` em `lib/src/model/<arq>.dart` | `<assinatura>` | `<cpp:linha>` | ```<corpo pronto>``` |

## Verificação — rode isto e só termine quando der PASS

```bash
tool/task_check.sh <arquivo>.dart <familias afetadas separadas por espaço>
```

Esse comando checa, nesta ordem: `dart analyze` na baseline, a dívida não
subiu em lugar nenhum, a dívida **deste arquivo caiu**, os testes do arquivo
estão verdes, e as famílias de corpus não têm exceção. Ele imprime `PASS` ou
`FAIL: <motivo>` com o comando que mostra o detalhe.

Se der `FAIL`, conserte e rode de novo. Não passe adiante com FAIL.

## Critério de pronto desta unidade

- [ ] `tool/task_check.sh` imprimiu `PASS`.
- [ ] A dívida dos métodos da tabela é zero:
      `dart run tool/debt_report.dart --file=<arquivo>.dart --by-method`
      não lista mais nenhum método desta unidade.
- [ ] Nenhum arquivo fora de `lib/src/rendering/<arquivo>.dart` e dos membros
      de modelo listados na tabela foi tocado (`git status --short`).
- [ ] Se houve lacuna: `tool/model_gaps.json` tem a entrada.
