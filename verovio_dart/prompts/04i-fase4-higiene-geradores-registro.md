# 04i — Higiene: gerador de elementos, registros do ObjectFactory e bug do validate_layout

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Consertar três defeitos de infraestrutura levantados na auditoria, que bloqueiam ou sabotam as fases
seguintes: `tool/gen_elements.py` que destrói código ao rodar, nomes errados no `ObjectFactory`, e um
bug de interpolação de string em `tool/validate_layout.dart`.

**Esta tarefa não porta nada do C++.** É manutenção.

## Pré-condições

Tarefas **04a**–**04h** concluídas.

```bash
cd verovio_dart
dart test 2>&1 | tail -1     # verde, ≥ 302
```

## Referência C++

Só para conferir nomes de registro:

```bash
grep -rn "ClassRegistrar" origin/src/src/*.cpp
# formato: static const ClassRegistrar<Note> s_factory("note", NOTE);
```

Arquivos relevantes: `origin/src/src/annotscore.cpp:29`, `btrem.cpp:32`, `f.cpp:27`, `fb.cpp:27`,
`lv.cpp:26`, `ossia.cpp:32`, `phrase.cpp:25`, `genericlayerelement.cpp:25` (comentado no C++).

## Arquivos Dart a criar/alterar

- **Alterar** `tool/gen_elements.py`.
- **Alterar** `lib/src/model/factory_registry_gen.dart` e/ou `lib/src/factory_registry.dart`.
- **Alterar** `tool/validate_layout.dart`.
- **Alterar** `CLAUDE.md` — a nota sobre a baseline de `dart analyze`.
- **Criar** `test/factory_registry_test.dart`.

## Passo a passo

### Parte 1 — `tool/gen_elements.py` não é idempotente

Estado medido: rodar `python3 tool/gen_elements.py` **sobrescreve** os `*_gen.dart` versionados e
apaga código escrito à mão. Reproduza e meça antes de decidir:

```bash
cd verovio_dart
mkdir -p /tmp/genbak && cp lib/src/model/*_gen.dart /tmp/genbak/
python3 tool/gen_elements.py
for b in control_elements_gen.dart layer_elements_gen.dart misc_elements_gen.dart factory_registry_gen.dart; do
  echo "--- $b"; diff /tmp/genbak/$b lib/src/model/$b | head -30
done
cp /tmp/genbak/*_gen.dart lib/src/model/      # RESTAURE antes de qualquer outra coisa
```

O que o gerador destrói (medido em 2026-08-26):

| Arquivo | Perda |
|---|---|
| `control_elements_gen.dart` | overrides `isSupportedChild` de `AnchoredText` e `AnnotScore`; campos de drawing de `BeamSpan` |
| `layer_elements_gen.dart` | ~40 linhas de import (`fraction.dart`, `logging.dart`, ~30 constantes de `smufl.dart`) e o código que as usa |
| `misc_elements_gen.dart` | imports de `zone.dart`, `dart:math`, `attdef.dart`, `mei_enums.dart`; o `export` que substitui o stub de `AlignmentReference` pelo port de `layout/horizontal_aligner.dart`; campos de drawing de `Div` |
| `factory_registry_gen.dart` | ao contrário: o gerador **acrescenta** `f.register('f', ClassId.f, F.new);`, ausente no versionado |

**Escolha uma das duas saídas e justifique no relatório:**

- **(A) Tornar o gerador idempotente**: dar-lhe blocos preservados (marcadores
  `// <<< hand-written` … `// >>>`) que ele relê do arquivo existente e reemite, e mover os imports
  para uma tabela no próprio gerador. Preferível se `gen_elements.py` ainda for útil.
- **(B) Aposentar o gerador**: trocar o banner `GENERATED FILE` dos `*_gen.dart` por
  `// Originalmente gerado por tool/gen_elements.py; MANTIDO À MÃO desde 2026-08-26.`,
  renomear `tool/gen_elements.py` para `tool/gen_elements.py.obsolete` e registrar no `CLAUDE.md`
  que esses arquivos passaram a ser editáveis à mão.

Qualquer que seja a escolha, o resultado tem de satisfazer: **rodar o procedimento de geração
documentado não pode alterar nenhum `*_gen.dart` versionado.**

### Parte 2 — registros errados no `ObjectFactory`

Defeitos medidos:

1. `lib/src/model/factory_registry_gen.dart:32-35` registra **quatro** classes com o nome `'dots'`:
   ```
   f.register('dots', ClassId.dots, Dots.new);
   f.register('dots', ClassId.flag, Flag.new);
   f.register('dots', ClassId.tupletBracket, TupletBracket.new);
   f.register('dots', ClassId.tupletNum, TupletNum.new);
   ```
   No C++, `Dots`, `Flag`, `TupletBracket` e `TupletNum` **não têm `ClassRegistrar` nenhum**
   (confira: `grep -rn "ClassRegistrar" origin/src/src/dots.cpp origin/src/src/flag.cpp` não retorna nada).
   **Correção: remover os quatro registros.**
2. `factory_registry_gen.dart:13` registra `AnnotScore` como `'annot'`, colidindo com o `Annot`
   editorial de `lib/src/factory_registry.dart`. O C++ usa `'annotScore'` (`annotscore.cpp:29`).
3. `BTrem` é registrado como `'bTrem'`; o C++ usa `'btrem'` (`btrem.cpp:32`).
4. `F`, `Fb`, `Lv`, `Ossia`, `Phrase` **não são registrados**; o C++ registra `'f'`, `'fb'`, `'lv'`,
   `'ossia'`, `'phrase'`.
5. `DivLine`, `Liquescent`, `Oriscus`, `Quilisma`, `Strophicus`, `Text`, `TimestampAttr` são
   registrados só no Dart. Decida caso a caso: se o C++ não registra e nada em Dart cria por nome,
   remova; se o `mei_input.dart` depende, mantenha **com o nome MEI correto** e comente por quê.

Antes de mexer, confirme quem usa o factory por nome:

```bash
grep -rn "ObjectFactory.instance.create\|\.create(" lib/src/io/ lib/src/model/ | head -20
```

Depois de corrigir, o teste novo (`test/factory_registry_test.dart`) tem de garantir:

- nenhum nome registrado duas vezes;
- todo nome de `ClassRegistrar` do C++ que corresponde a uma classe existente em Dart está
  registrado com o mesmo nome;
- `ObjectFactory.instance.create('annot')` devolve um `Annot` editorial e
  `create('annotScore')` devolve um `AnnotScore`.

### Parte 3 — bug de interpolação em `tool/validate_layout.dart`

A tabela "System metrics" do relatório imprime literalmente:

```
y∈[Instance of 'SystemMetrics'.minStaffYRel, Instance of 'SystemMetrics'.maxStaffYRel]
```

É `"$obj.campo"` sem chaves. Corrija para `"${obj.campo}"` e reveja o arquivo inteiro procurando o
mesmo padrão (`grep -n '\$[a-zA-Z_][a-zA-Z0-9_]*\.' tool/validate_layout.dart`).

### Parte 4 — `CLAUDE.md`

A seção "Gotchas" afirma que `tool/_scratch_*.dart`, `tool/t8.dart` e `tool/dbg_c.dart` "are the only
source of `dart analyze` warnings". São 8 dos 10; há 2 warnings em `test/`
(`test/mei_input_test.dart:10`, `test/toolkit_io_test.dart:114`). Corrija a frase e cite a baseline
numérica. **Você pode corrigir esses 2 warnings** — são triviais e reduzem a baseline para 8;
se corrigir, diga isso no `CLAUDE.md` e no relatório.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.` (ou `8`, se você corrigiu os 2 de `test/` — diga qual no relatório)
- [ ] `dart test` verde, **≥ 306 testes**
- [ ] Idempotência do gerador provada por comando, e a saída colada no relatório:
      `cp lib/src/model/*_gen.dart /tmp/g1/ && <procedimento de geração> && diff -r /tmp/g1 <destino>`
      não reporta diferença
- [ ] `cat lib/src/model/factory_registry_gen.dart lib/src/factory_registry.dart | grep -oP "f\.register\('\K[^']+" | sort | uniq -d`
      **não imprime nada** (nenhum nome duplicado)
- [ ] `dart run tool/validate_layout.dart && grep -c "Instance of 'SystemMetrics'" tool/LAYOUT_VALIDATION.md` = **0**
- [ ] `CLAUDE.md` atualizado com a baseline correta de `dart analyze`
- [ ] Relatório em `prompts/reports/04i.md`, contendo a justificativa da escolha (A) ou (B) da Parte 1
- [ ] `PLANO.md`: checkbox "Corrigir `tool/gen_elements.py` …" da Fase 4 marcado

## Armadilhas conhecidas

- **Faça backup antes de rodar `gen_elements.py`.** Não há git aqui. Se você rodar sem backup e não
  restaurar, o trabalho está perdido para sempre.
- Remover os registros `'dots'` pode quebrar algo que dependia acidentalmente do fallback. Rode
  `dart test` logo depois de cada remoção, não todas de uma vez.
- `ClassId.f` existe no `vrvdef.dart`? Confira (`grep -n "^\s*f,$" lib/src/core/vrvdef.dart`) antes de
  registrar `'f'`.

## Fora de escopo

- Portar qualquer functor.
- Limpar os 8 warnings de `tool/_scratch_*` — são baseline por decisão registrada no `CLAUDE.md`.
