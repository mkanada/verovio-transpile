# 06-19 — transposition.cpp (A): TransPitch e aritmética de intervalos

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar a primeira metade de `transposition.cpp`: a classe `TransPitch` (altura com nome de nota,
acidente e oitava) e toda a aritmética de intervalos diatônicos e cromáticos sobre ela.

## Pré-condições

Tarefa **06-18** concluída.

```bash
cd verovio_dart
ls lib/src/midi/feature_extractor.dart
dart test 2>&1 | tail -1     # verde, ≥ 772
```

## Referência C++

`origin/src/include/vrv/transposition.h` — declara `class TransPitch` e `class Transposer`.
`origin/src/src/transposition.cpp` (2252 linhas).

Esta tarefa: **`TransPitch` inteira** e os métodos de `Transposer` que fazem aritmética de intervalo.
Localize a fronteira:

```bash
grep -n "^TransPitch\|^int TransPitch\|^bool TransPitch\|^void TransPitch\|^std::string TransPitch" origin/src/src/transposition.cpp
grep -n "^Transposer::\|^int Transposer::\|^bool Transposer::\|^void Transposer::" origin/src/src/transposition.cpp | head -40
```

Métodos de intervalo de `Transposer` (nomes a confirmar no header): `GetInterval`,
`IntervalToDiatonicChromatic`, `DiatonicChromaticToIntervalClass`, `IntervalToSemitones`,
`SemitonesToIntervalClass`, `GetIntervalClass`, `PerfectUnisonClass` e as constantes de classe de
intervalo.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/editing/trans_pitch.dart` — `TransPitch`.
- **Criar** `lib/src/editing/transposer.dart` — o esqueleto de `Transposer` com a aritmética de
  intervalo; o resto fica na tarefa 06-20, marcado com `_notYet('…', '06-20')`.
- **Criar** `test/trans_pitch_test.dart`.

## Passo a passo

1. Leia `transposition.h` inteiro e a parte de `TransPitch` no `.cpp`.
2. Porte `TransPitch` com todos os operadores e conversões.
3. Porte a aritmética de intervalo de `Transposer`.
4. Testes: esta é a tarefa mais fácil de testar exaustivamente da Fase 6 — é matemática pura.
   Escreva testes de tabela: para cada par (nota, intervalo) num conjunto de ao menos **50 casos**,
   afirme a nota resultante. Tire os casos esperados do C++, não da sua cabeça: escreva um programa
   C++ pequeno, ou derive-os das tabelas do próprio `transposition.cpp`.
   Inclua os casos difíceis: dobrados sustenidos, dobrados bemóis, mudança de oitava, intervalos
   descendentes, unísono aumentado.
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 800 testes** (a tabela de 50 casos conta)
- [ ] `grep -c "class TransPitch" lib/src/editing/trans_pitch.dart` = 1
- [ ] A tabela de testes cobre ≥ 50 pares (nota, intervalo), incluindo dobrados acidentes e
      mudanças de oitava
- [ ] Todo método de `TransPitch` no header C++ tem contraparte — prove com o diff de nomes
- [ ] Relatório em `prompts/reports/06-19.md`
- [ ] `PLANO.md`: checkbox de `transposition.cpp` (A) marcado

## Armadilhas conhecidas

- `TransPitch` usa inteiros para nome de nota (0=C … 6=B) e para acidente (0=natural, +1=sustenido,
  −1=bemol). As convenções exatas estão no header; usar outra convenção quebra tudo silenciosamente.
- Aritmética modular com negativos: em C++, `-1 % 7` é `-1`; em Dart, `-1 % 7` é `6`. **Esta é a
  armadilha número um desta tarefa.** Use `%` do Dart só onde quiser o resultado positivo; onde o
  C++ depende do resto negativo, use `remainder()`.
- Divisão inteira com negativos: `~/` trunca para zero em Dart, como o C++; `(a/b).floor()` não.
- Intervalos "classe" vs. "semitons" vs. "diatônico+cromático" são três representações diferentes.
  Não as confunda.

## Fora de escopo

- `Transposer` completo (tarefa 06-20), `transposefunctor.cpp` (06-21).
