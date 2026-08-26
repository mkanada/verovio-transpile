# 07-07 — toolkit.cpp (B): MIDI, timemap, features e consultas por elemento

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Expor pela API pública tudo o que a Fase 6 produziu: MIDI, timemap, características descritivas,
expansion map, e as consultas de tempo/atributo por id de elemento.

## Pré-condições

Tarefa **07-06** concluída.

```bash
cd verovio_dart
ls tool/verovio_cli.dart
dart test 2>&1 | tail -1     # verde, ≥ 985
```

## Referência C++

`origin/src/src/toolkit.cpp`. Esta tarefa:

`RenderToMIDI`, `RenderToMIDIFile`, `RenderToTimemap`, `RenderToTimemapFile`,
`RenderToExpansionMap`, `RenderToExpansionMapFile`, `GetMIDIValuesForElement`,
`GetTimeForElement`, `GetTimesForElement`, `GetElementsAtTime`, `GetElementAttr`,
`GetExpansionIdsForElement`, `GetNotatedIdForElement`, `GetDescriptiveFeatures`, `GetClassIds`,
`GetID`, `ResetMidiDoc`, `SetMidiDoc`, `GetLog`, `ResetLogBuffer`, `LogRedirectStart`,
`LogRedirectStop`, `InitClock`, `ResetClock`, `GetRuntimeInSeconds`, `LogRuntime`.

Localize cada um com `grep -n "Toolkit::<nome>" origin/src/src/toolkit.cpp`.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/toolkit.dart` (ou o `part` criado na 07-06).
- **Alterar** `tool/verovio_cli.dart` — suportar `-t midi|timemap|mei|expansionmap`.
- **Criar** `test/toolkit_query_test.dart`.

## Passo a passo

1. Leia os métodos listados.
2. Porte-os, apoiando-se no que a Fase 6 construiu (`lib/src/midi/`, `lib/src/io/mei_output.dart`,
   `lib/src/model/expansion_map.dart`).
3. **Apague o `TODO(phase-6)` de `toolkit.dart:264`.**
4. Estenda o CLI.
5. Testes de ponta a ponta comparando com o C++, para cada `-t`:
   ```bash
   for t in midi timemap mei; do
     ./build/verovio -r verovio_dart/assets/data -t $t -o /tmp/cpp.$t <arquivo>
     dart run tool/verovio_cli.dart -r assets/data -t $t -o /tmp/dart.$t <arquivo>
     diff /tmp/cpp.$t /tmp/dart.$t
   done
   ```
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 1000 testes**
- [ ] `grep -c "TODO(phase-6)" lib/src/toolkit.dart` = 0
- [ ] `dart run tool/verovio_cli.dart -t timemap` produz saída idêntica à do C++ para
      **≥ 450 dos 623** arquivos (o número da tarefa 06-15, agora pela API pública)
- [ ] `dart run tool/verovio_cli.dart -t midi` produz bytes idênticos aos do C++ para
      **≥ 400 dos 623** (o número da tarefa 06-17)
- [ ] `dart run tool/verovio_cli.dart -t mei` produz saída idêntica à do C++ para
      **≥ 100 dos 623** (o número da tarefa 06-11)
- [ ] `getTimeForElement`, `getElementsAtTime` e `getElementAttr` testados contra o C++ para ao
      menos 10 elementos
- [ ] Relatório em `prompts/reports/07-07.md`
- [ ] `PLANO.md`: checkbox de "getSVG/getMEI/getMIDI/timemap" marcado

## Armadilhas conhecidas

- `GetMIDI` devolve **base64**; `RenderToMIDIFile` devolve bytes. Não confunda.
- As consultas por tempo exigem que o timemap tenha sido gerado; o C++ o gera sob demanda e cacheia
  (`ResetMidiDoc`/`SetMidiDoc`). Porte o cache, senão cada consulta refaz tudo.
- `GetLog`/`LogRedirect*` mexem com o sistema de logging (`lib/src/core/logging.dart`);
  redirecionar o log é global — não deixe um teste vazar redirecionamento para outro.
- `GetRuntimeInSeconds` usa `RuntimeClock` (`lib/src/core/runtime_clock.dart`), que já existe.

## Fora de escopo

- API do editor (tarefa 07-08).
