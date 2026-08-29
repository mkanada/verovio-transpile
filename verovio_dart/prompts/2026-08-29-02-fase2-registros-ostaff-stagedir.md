# 2026-08-29-02 — Fase 2: os dois registros de fábrica que faltam (`oStaff`, `stageDir`)

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar a Fase 2. O C++ registra **129** nomes no `ObjectFactory`; o Dart registra **127**. Faltam
dois, e os dois têm a mesma forma incomum: são um **segundo** registro para uma classe que já tem
o seu, apontando para um construtor diferente.

`origin/src/src/staff.cpp:47-48`:

```cpp
static const ClassRegistrar<Staff> s_factory("staff", STAFF);
static const ClassRegistrar<Staff> s_factoryOStaff(
    "oStaff", FACTORY_OSTAFF, []() -> Object * { return new Staff(1, true); });
```

`origin/src/src/dir.cpp:31-32`:

```cpp
static const ClassRegistrar<Dir> s_factory("dir", DIR);
static const ClassRegistrar<Dir> s_factoryStageDir(
    "stageDir", FACTORY_STAGEDIR, []() -> Object * { return new Dir(true); });
```

Ou seja: `oStaff` constrói `Staff(n: 1, isOssia: true)` e `stageDir` constrói `Dir(isStageDir: true)`.
Não são classes novas — são **fábricas nomeadas com argumento fixo**.

## Por que isso não apareceu antes

A auditoria de 2026-08-26 varreu os registros com um `grep` de **linha única**, e estes dois estão
quebrados em duas linhas: o `ClassRegistrar<Staff>` fica numa linha e a string `"oStaff"` na
seguinte. Passaram despercebidos. `tool/verify_phases.dart` (critério 2.1) usa `\s*` entre os dois
e por isso os enxerga.

O sintoma hoje é silencioso: `mei_input.dart` trata `oStaff` (`:2123`) e `stageDir` (`:2074`) por
nome, inline, então **a leitura de MEI funciona**. O que não funciona é qualquer caminho que
construa por nome pela fábrica — que é como o C++ resolve `Object::Clone`, o editor toolkit e a
releitura de árvore. Fase 6 vai depender disso.

## Pré-condições

```bash
cd verovio_dart
dart run tool/verify_phases.dart --fase=2
# esperado hoje: FALHA 2.1 — "sem registro: oStaff, stageDir"
```

## O que fazer

1. **Confira o que os dois construtores fazem** em `staff.cpp` (`Staff::Staff(int n, bool isOssia)`)
   e `dir.cpp` (`Dir::Dir(bool isStageDir)`), e ache os equivalentes Dart. `Staff` já tem o conceito
   (`Staff.isOssia()`, `basic_elements.dart:1121` devolve `'oStaff'` como `className`) e `Dir`
   também (`control_elements_gen.dart:579` devolve `'stageDir'`). O estado existe; falta a fábrica.

2. **Registre os dois** em `lib/src/factory_registry.dart`, com a lambda equivalente. Cite o C++ no
   comentário, como os registros vizinhos fazem.

3. **`FACTORY_OSTAFF` e `FACTORY_STAGEDIR` são `ClassId`s próprios no C++**, distintos de `STAFF` e
   `DIR` — confira em `vrvdef.h` e reproduza a decisão em `core/vrvdef.dart`. Cuidado: se você
   registrar `oStaff` com `ClassId.staff`, o critério 2.2 do portão (nenhum nome duplicado) continua
   passando mas o comportamento diverge do C++. Leia o que o C++ faz com esses dois ids antes de
   decidir — se eles existirem só para dar nome à fábrica e nunca forem comparados, documente isso
   num `Deviations from the C++:`.

4. **Teste** em `test/factory_registry_test.dart`: criar `'oStaff'` pela fábrica devolve um `Staff`
   com `isOssia() == true` e `n == 1`; criar `'stageDir'` devolve um `Dir` com o flag de stage
   direction ligado. E o contraste: `'staff'` e `'dir'` continuam devolvendo os objetos comuns.

## Critérios de aceite

- [ ] `dart run tool/verify_phases.dart --fase=2` → **PASS** (2.1 e 2.2 verdes)
- [ ] `dart analyze` ≤ 8
- [ ] `dart test` verde, com os quatro testes novos
- [ ] Relatório em `prompts/reports/2026-08-29-02.md`, dizendo explicitamente que decisão foi tomada
      sobre `FACTORY_OSTAFF`/`FACTORY_STAGEDIR` e por quê
- [ ] `PLANO.md`: registre no texto da Fase 2 que a contagem passou a 129/129

## Armadilha

**Não "conserte" o `mei_input.dart` para passar a usar a fábrica.** Ele trata esses nomes inline
porque o C++ também trata (`iomei.cpp:5817` e `:5865`). Mudar isso é refatoração fora de escopo
(§8.4) e provavelmente quebra a leitura.

## Fora de escopo

- Qualquer outro registro. O critério 2.1 lista tudo o que falta; se ele acusar mais alguma coisa
  depois desta tarefa, é achado novo — registre na seção "Achados fora de escopo" do relatório.
