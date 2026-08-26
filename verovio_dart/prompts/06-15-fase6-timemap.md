# 06-15 — timemap.cpp + GenerateTimemapFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar a classe `Timemap` e o `GenerateTimemapFunctor`, e expor o timemap em JSON — o mesmo que
`./build/verovio -t timemap` produz. Ao final, o Dart tem um oráculo próprio comparável com o C++
byte a byte.

## Pré-condições

Tarefa **06-14** concluída.

```bash
cd verovio_dart
ls lib/src/midi/init_midi.dart
dart test 2>&1 | tail -1     # verde, ≥ 732
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/include/vrv/timemap.h` | — | `class Timemap`, `struct TimemapEntry` |
| `origin/src/src/timemap.cpp` | 110 | `Timemap::Reset`, `GetEntry`, `ToJson` |
| `origin/src/src/midifunctor.cpp` | — | `GenerateTimemapFunctor::` (`grep -n "GenerateTimemapFunctor::" origin/src/src/midifunctor.cpp`) |
| `origin/src/src/toolkit.cpp` | — | `Toolkit::RenderToTimemap` (`grep -n "RenderToTimemap" origin/src/src/toolkit.cpp`) |

Formato de referência — gere um e leia:
```bash
./build/verovio -r verovio_dart/assets/data -t timemap -o /tmp/tm.json test/corpus/note/note-001.mei
cat /tmp/tm.json
```

`tool/validate_layout.dart` **já compara timemaps** contra o C++ (é como os 24/30 são medidos);
leia como ele faz antes de escrever algo novo.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/midi/timemap.dart`.
- **Alterar** `lib/src/toolkit.dart` — `renderToTimemap()`.
- **Alterar** `tool/validate_layout.dart` — passar a usar o timemap **do Dart** em vez do cálculo
  ad hoc atual, se houver um.
- **Criar** `test/timemap_test.dart`.

## Passo a passo

1. Leia `timemap.h`, `timemap.cpp` e `GenerateTimemapFunctor`.
2. Porte a classe e o functor.
3. Porte `Toolkit.renderToTimemap`, com as opções que o C++ aceita
   (`includeMeasures`, `includeRests` — confirme os nomes em `toolkit.cpp`).
4. **Teste de igualdade exata:** para cada arquivo CMN do corpus, gere o timemap com o Dart e com o
   C++ e compare o **JSON inteiro**, não só os onsets. Escreva isso como uma tool
   (`tool/validate_timemap.dart`) que varre o corpus e emite `tool/TIMEMAP_VALIDATION.md`.
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 742 testes**
- [ ] `dart run tool/validate_timemap.dart` existe, varre o corpus e escreve
      `tool/TIMEMAP_VALIDATION.md`
- [ ] **≥ 450 dos 623** arquivos têm o JSON de timemap **idêntico** ao do C++ (comparação de string
      normalizada por espaços em branco); o relatório traz o número exato
- [ ] Para os que divergem, `tool/TIMEMAP_VALIDATION.md` lista a primeira entrada divergente
- [ ] Relatório em `prompts/reports/06-15.md`
- [ ] `PLANO.md`: checkbox de `timemap.cpp` marcado

## Armadilhas conhecidas

- **Formatação de número no JSON.** O C++ emite `4` ou `4.0` conforme o caso; o Dart faz diferente
  por padrão. Mesma armadilha da tarefa 05-03 — use um helper de formatação.
- A ordem das chaves no JSON importa para a comparação de string. Use um `Map` que preserve ordem
  (o default do Dart) e insira na ordem do C++.
- `includeRests`/`includeMeasures` mudam o conteúdo; use os defaults do C++ na comparação.
- Se um arquivo mensural divergir, o suspeito é o `ScoringUpFunctor` (tarefa 06-13), não este.
- Repetições e `expansion` mudam a linha do tempo; `test/corpus/expansion/` (3) e
  `test/corpus/repeats/` (8) cobrem.

## Fora de escopo

- Geração de MIDI propriamente dita (tarefas 06-16 e 06-17).
