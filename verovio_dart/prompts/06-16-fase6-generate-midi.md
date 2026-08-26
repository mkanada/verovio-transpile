# 06-16 — GenerateMIDIFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `GenerateMIDIFunctor`: a travessia que transforma a árvore MEI numa sequência de eventos MIDI
(note on/off, program change, controle, tempo, pedal).

## Pré-condições

Tarefa **06-15** concluída.

```bash
cd verovio_dart
ls lib/src/midi/timemap.dart
dart run tool/validate_timemap.dart | head -3
dart test 2>&1 | tail -1     # verde, ≥ 742
```

## Referência C++

`origin/src/include/vrv/midifunctor.h` → `class GenerateMIDIFunctor` (o maior de
`midifunctor.cpp`, 1324 linhas no arquivo).
Localize: `grep -n "GenerateMIDIFunctor::" origin/src/src/midifunctor.cpp`.

O C++ escreve para uma `smf::MidiFile` da biblioteca **midifile**, que é uma dependência externa
(`origin/src/include/midi/`). Confira o que existe:
```bash
ls origin/src/include/midi/ 2>/dev/null || find origin/src -name "MidiFile*" | head
```

**Decisão de escopo já tomada:** o writer MIDI é escrito do zero em Dart (tarefa 06-17), não portado
da midifile. Nesta tarefa, defina uma **interface mínima de sequenciador**
(`addNoteOn`, `addNoteOff`, `addPatchChange`, `addTempo`, `addController`, `addTrack`,
`setTicksPerQuarterNote`) espelhando **só o que `GenerateMIDIFunctor` chama** — nada mais.
Liste no relatório os métodos da `smf::MidiFile` que o functor usa; essa lista é o contrato da 06-17.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/midi/midi_sequence.dart` — a interface do sequenciador e uma implementação em
  memória (lista de eventos).
- **Criar** `lib/src/midi/generate_midi.dart` — `GenerateMIDIFunctor`.
- **Criar** `test/generate_midi_test.dart`.

## Passo a passo

1. Leia `GenerateMIDIFunctor` inteiro.
2. **Liste todos os métodos de `smf::MidiFile` que ele chama** (`grep -oP 'm_midiFile->\K\w+' ...`
   ou equivalente) e cole a lista no relatório.
3. Defina `MidiSequence` com exatamente esses métodos.
4. Porte o functor contra essa interface.
5. Testes: contagem e ordem de eventos para arquivos conhecidos. Não compare bytes ainda (isso é a
   06-17); compare a **sequência lógica**: para `test/corpus/note/note-001.mei`, N note-on com as
   alturas e os tempos esperados.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 754 testes**
- [ ] `grep -c "class GenerateMIDIFunctor" lib/src/midi/generate_midi.dart` = 1
- [ ] O relatório lista todos os métodos de `smf::MidiFile` usados pelo functor, e `MidiSequence`
      tem exatamente esses
- [ ] Um teste afirma a sequência exata de eventos (tipo, canal, altura, velocity, tick) para
      `test/corpus/note/note-001.mei` e `test/corpus/chord/chord-001.mei`
- [ ] Relatório em `prompts/reports/06-16.md`
- [ ] `PLANO.md`: checkbox de `GenerateMIDIFunctor` marcado

## Armadilhas conhecidas

- Ticks por semínima: o C++ tem um valor fixo. Ache-o e use o mesmo, senão nada bate.
- Velocity vem de dinâmicas (`@vel`, `dynam`); há um mapa no C++.
- Pedal vira controlador 64; sustain on/off tem regras de sobreposição.
- Ornamentos e arpejos já foram expandidos pelo `InitTimemapAdjustNotesFunctor` (tarefa 06-14) —
  não os expanda de novo.
- Canal 10 é percussão.
- A ordem dos eventos com o mesmo tick importa para a comparação byte a byte da 06-17; o C++ tem uma
  ordem determinística.

## Fora de escopo

- Serializar para o formato SMF (tarefa 06-17).
