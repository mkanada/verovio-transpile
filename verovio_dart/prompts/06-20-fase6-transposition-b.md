# 06-20 — transposition.cpp (B): Transposer, escalas e tonalidades

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar `transposition.cpp`: a classe `Transposer` completa — transposição por intervalo, por
tonalidade, para altura real (sounding pitch), e a manipulação de armaduras.

## Pré-condições

Tarefa **06-19** concluída.

```bash
cd verovio_dart
grep -c "_notYet(" lib/src/editing/transposer.dart   # > 0
dart test 2>&1 | tail -1     # verde, ≥ 800
```

## Referência C++

`origin/src/src/transposition.cpp` (2252 linhas) — tudo o que a tarefa 06-19 deixou de fora.
`origin/src/include/vrv/transposition.h` — a declaração completa de `Transposer`.

Métodos principais (confirme os nomes no header): `SetTransposition`,
`SetTranspositionDC`, `SetBase40`, `SetBase600`, `Transpose` (várias sobrecargas),
`GetKeyTonic`, `GetKeyTonicFromKeySignature`, `IsValidIntervalName`, `IsValidKeyTonic`,
`IsValidSemitones`, `GetIntervalName`, `DiatonicChromaticToIntervalName`.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/editing/transposer.dart`.
- **Criar** `test/transposer_test.dart`.

## Passo a passo

1. Leia o resto do `.cpp`.
2. Porte os métodos restantes.
3. Testes de tabela, como na 06-19: transposição de escalas inteiras, de cada tonalidade maior e
   menor para cada outra, e as armaduras resultantes. Ao menos **60 casos**.
   Inclua as entradas de intervalo por nome (`"P5"`, `"m3"`, `"A4"`) e por semitons.
4. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 835 testes**
- [ ] `grep -c "_notYet(" lib/src/editing/transposer.dart` = **0**
- [ ] Todo método público de `Transposer` no header C++ tem contraparte — prove com o diff de nomes
- [ ] A tabela de testes cobre ≥ 60 casos, incluindo todas as 15 tonalidades maiores e suas relativas
- [ ] Relatório em `prompts/reports/06-20.md`
- [ ] `PLANO.md`: checkbox de `transposition.cpp` (B) marcado

## Armadilhas conhecidas

- **Base 40** é a representação interna de altura do Verovio (herdada do Humdrum): 40 valores por
  oitava, o que permite representar até dobrados acidentes sem colisão. Não a substitua por MIDI
  pitch, que perde a informação enarmônica.
- Aritmética modular com negativos (ver 06-19).
- Nomes de intervalo (`"P5"`, `"m3"`, `"A4"`, `"d5"`) têm uma gramática; `IsValidIntervalName` a
  valida. Copie a validação, não aceite qualquer string.
- Transposição de armadura não é transposição de nota: uma armadura de 5 sustenidos transposta pode
  virar 7 bemóis ou 5 bemóis, conforme o modo enarmônico escolhido. O C++ tem a regra.

## Fora de escopo

- `transposefunctor.cpp` (tarefa 06-21).
