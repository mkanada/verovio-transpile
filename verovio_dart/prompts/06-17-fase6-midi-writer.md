# 06-17 — Writer MIDI (Standard MIDI File) e `Toolkit.renderToMIDI`

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Escrever o serializador de Standard MIDI File em Dart puro e ligá-lo ao `Toolkit`, para que
`renderToMIDI()` produza **bytes idênticos** aos de `./build/verovio -t midi`.

> Decisão de escopo registrada: o C++ usa a biblioteca externa **midifile**; o Dart escreve o writer
> do zero, porque é pequeno e evita uma dependência. O contrato é a interface `MidiSequence`
> definida na tarefa 06-16.

## Pré-condições

Tarefa **06-16** concluída.

```bash
cd verovio_dart
ls lib/src/midi/midi_sequence.dart lib/src/midi/generate_midi.dart
dart test 2>&1 | tail -1     # verde, ≥ 754
```

## Referência C++ e formato

- `origin/src/src/toolkit.cpp` → `Toolkit::RenderToMIDI` e `Toolkit::GetMIDI`
  (`grep -n "RenderToMIDI\|GetMIDI" origin/src/src/toolkit.cpp`) — como o C++ escreve e como
  codifica em base64.
- O formato SMF em si: header `MThd` (formato, número de tracks, divisão) e tracks `MTrk` com
  eventos em **delta-time VLQ**. A referência de verdade é o arquivo produzido pelo C++:

```bash
./build/verovio -r verovio_dart/assets/data -t midi -o /tmp/cpp.mid test/corpus/note/note-001.mei
xxd /tmp/cpp.mid | head -20
```

- As 3 opções do grupo "Midi options" de `origin/src/src/options.cpp` — acrescente-as ao
  `options_shell.dart`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/midi/smf_writer.dart`.
- **Alterar** `lib/src/toolkit.dart` — `renderToMIDI()` (bytes) e `getMIDI()` (base64, como o C++).
- **Alterar** `lib/src/core/options_shell.dart` — as 3 opções MIDI.
- **Criar** `tool/validate_midi.dart` e `test/midi_writer_test.dart`.

## Passo a passo

1. Gere alguns arquivos MIDI de referência com o C++ e leia os bytes (`xxd`). Entenda a estrutura
   antes de escrever.
2. Escreva o writer: `MThd`, `MTrk`, VLQ, running status (**confira se o C++ o usa** — se usar e
   você não usar, os bytes diferem), meta-eventos de tempo e de fim de track.
3. Ligue `Toolkit.renderToMIDI()` e `getMIDI()`.
4. **`tool/validate_midi.dart`**: varre os 623 arquivos do corpus (menos os 2 não-UTF-8), gera o MIDI
   com o Dart e com o C++, e compara **byte a byte**. Emite `tool/MIDI_VALIDATION.md` com a contagem
   de idênticos e, para os divergentes, o **offset do primeiro byte diferente** e o que há em volta.
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 764 testes**
- [ ] `dart run tool/validate_midi.dart` existe, varre o corpus e escreve `tool/MIDI_VALIDATION.md`
- [ ] **≥ 400 dos 623** arquivos produzem MIDI **byte a byte idêntico** ao do C++; o relatório traz
      o número exato
- [ ] Para os divergentes, o relatório traz o offset do primeiro byte diferente
- [ ] `Toolkit.getMIDI()` devolve base64 com o mesmo prefixo do C++ para ao menos 5 arquivos
- [ ] Relatório em `prompts/reports/06-17.md`
- [ ] `PLANO.md`: checkbox de "Export MIDI" marcado

## Armadilhas conhecidas

- **Running status**: comprime eventos consecutivos do mesmo tipo omitindo o status byte.
  Se a midifile o usa e você não, todo arquivo diverge a partir do segundo evento. Verifique nos
  bytes do C++ antes de escrever uma linha.
- **VLQ** (variable-length quantity) para delta-times: 7 bits por byte, bit alto de continuação.
  Erro clássico é não tratar delta 0 e deltas > 127.
- Número de tracks: formato 0 (uma track) vs. formato 1 (várias). Veja o que o C++ emite.
- Meta-evento de fim de track (`FF 2F 00`) é obrigatório em cada track.
- A ordem de eventos com o mesmo tick (tarefa 06-16) é o que decide os bytes. Se divergir aqui, o
  bug provavelmente está lá.
- Não use `package:` de MIDI do pub. O escopo diz writer próprio.

## Fora de escopo

- `featureextractor.cpp` (tarefa 06-18).
