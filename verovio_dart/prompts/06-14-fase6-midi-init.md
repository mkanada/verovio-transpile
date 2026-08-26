# 06-14 — midifunctor.cpp (A): InitMIDI, InitTimemapTies, InitTimemapAdjustNotes

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar os três functors de preparação de MIDI: inicialização dos canais e instrumentos, resolução de
ligaduras de valor em notas únicas, e o ajuste de notas (arpejos, tremolos, ornamentos) que altera
onsets e durações.

## Pré-condições

Tarefa **06-13** concluída.

```bash
cd verovio_dart
ls lib/src/layout/scoring_up.dart
grep -rn "class InitOnsetOffsetFunctor\|class InitMaxMeasureDurationFunctor" lib/src/   # já existem
dart test 2>&1 | tail -1     # verde, ≥ 720
```

## Referência C++

`origin/src/include/vrv/midifunctor.h` declara **8** classes:
`InitOnsetOffsetFunctor`, `InitMaxMeasureDurationFunctor` (**já portados** — confirme com o grep
acima), `InitTimemapTiesFunctor`, `InitTimemapAdjustNotesFunctor`, `InitMIDIFunctor`,
`GenerateMIDIFunctor`, `GenerateTimemapFunctor`, `GenerateFeaturesFunctor`.

Esta tarefa porta os **três** de inicialização: `InitTimemapTiesFunctor`,
`InitTimemapAdjustNotesFunctor`, `InitMIDIFunctor`.

`origin/src/src/midifunctor.cpp` (1324 linhas) — localize com
`grep -n "InitTimemapTiesFunctor::\|InitTimemapAdjustNotesFunctor::\|InitMIDIFunctor::" origin/src/src/midifunctor.cpp`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/midi/init_midi.dart`. (Primeiro arquivo de `lib/src/midi/`, hoje vazio.)
- **Alterar** `lib/src/model/doc.dart`.
- **Criar** `test/midi_init_test.dart`.

## Passo a passo

1. Leia o header inteiro e as três classes no `.cpp`.
2. Porte as três em `lib/src/midi/init_midi.dart`.
3. Ligue-as onde o C++ as chama (`grep -rn "InitMIDIFunctor\|InitTimemapTies" origin/src/src/doc.cpp origin/src/src/toolkit.cpp`).
4. Testes: `test/corpus/tie/` (12 arquivos) para as ligaduras — duas notas ligadas viram **uma** nota
   MIDI com a duração somada. `test/corpus/arpeg/` (7), `test/corpus/btrem/` (6),
   `test/corpus/trill/` (8), `test/corpus/turn/` (6), `test/corpus/mordent/` (5) para o ajuste.
   `test/corpus/midi/` (2) para os canais.
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 732 testes**
- [ ] `grep -c "class InitTimemapTiesFunctor\|class InitTimemapAdjustNotesFunctor\|class InitMIDIFunctor" lib/src/midi/init_midi.dart` = 3
- [ ] Um teste prova que duas notas ligadas produzem **uma** entrada com duração somada
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **não regride**
- [ ] Relatório em `prompts/reports/06-14.md`
- [ ] `PLANO.md`: checkbox de `midifunctor.cpp` (A) marcado

## Armadilhas conhecidas

- Cadeias de ligadura de 3+ notas: `InitTimemapTiesFunctor` tem de somar todas, não só as duas
  primeiras.
- `InitTimemapAdjustNotesFunctor` **modifica** onsets/durações; rodá-lo duas vezes ajusta duas vezes.
- Ornamentos (trinado, grupeto, mordente) viram várias notas no MIDI, com durações derivadas.
  A tabela de expansão está no C++; não invente.
- Canais MIDI: o canal 10 é percussão e é reservado. O C++ trata isso em `InitMIDIFunctor`.
- `Fraction` na aritmética de tempo, não `double`.

## Fora de escopo

- `GenerateTimemapFunctor` (06-15), `GenerateMIDIFunctor` (06-16).
