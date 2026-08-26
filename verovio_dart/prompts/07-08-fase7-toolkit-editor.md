# 07-08 — toolkit.cpp (C): API do editor e seleção

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar `toolkit.cpp`: a API do editor (`Edit`, `EditInfo`, `SetViewAndEditor`), a seleção
(`Select`), e o que restar de utilidades.

## Pré-condições

Tarefa **07-07** concluída.

```bash
cd verovio_dart
grep -c "TODO(phase-" lib/src/toolkit.dart   # 0
dart test 2>&1 | tail -1     # verde, ≥ 1000
```

## Referência C++

`origin/src/src/toolkit.cpp`. Esta tarefa:

`Edit`, `EditInfo`, `SetViewAndEditor`, `Select`, `SetCString`, `SetFont`, `SetLocale`,
`ResetLocale`, `IsUTF16`, `IsZip`, `IdentifyInputFrom`, `LoadUTF16File`, `LoadZipDataBase64`,
`LoadZipDataBuffer`, `PrintOptionUsage`, `PrintOptionUsageOutput`, `GetOptionUsageString`.

Localize com `grep -n "Toolkit::<nome>" origin/src/src/toolkit.cpp`.

`SetViewAndEditor` escolhe entre `EditorToolkitCMN` e `EditorToolkitNeume` conforme a notação —
ambos portados nas tarefas 06-22 a 06-24.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/toolkit.dart`.
- **Alterar** `tool/verovio_cli.dart` — `--help` com o texto de uso das 210 opções.
- **Criar** `test/toolkit_editor_test.dart`.

## Passo a passo

1. Leia os métodos listados.
2. Porte-os.
3. `GetOptionUsageString`/`PrintOptionUsage` geram o texto de `--help` a partir dos grupos e das
   descrições registradas nas tarefas 07-02 a 07-05. **O texto tem de ser idêntico ao do C++** —
   é o teste mais fácil e mais revelador desta tarefa.
4. Testes: ações do editor pela API pública; seleção; `--help` comparado com o do C++.
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 1015 testes**
- [ ] Todo método público de `origin/src/include/vrv/toolkit.h` tem contraparte, **exceto** os de
      Humdrum e PAE — prove no relatório com o diff de nomes e a lista dos excluídos
- [ ] `dart run tool/verovio_cli.dart --help` produz texto **idêntico** ao de
      `./build/verovio --help` (compare com `diff`; cole o resultado no relatório)
- [ ] Um teste executa uma ação do editor pela API pública e afirma o resultado
- [ ] Relatório em `prompts/reports/07-08.md`
- [ ] `PLANO.md`: checkbox de "editor API" marcado

## Armadilhas conhecidas

- O texto de `--help` é sensível a espaços e quebras de linha. Se o `diff` não for vazio, alguma
  descrição ou alguma largura de coluna está errada — não relaxe a comparação.
- `SetLocale`/`ResetLocale` mexem com formatação de número; em Dart não há locale global de `double`,
  mas o C++ o usa para evitar vírgula decimal. **Documente esse desvio** e garanta que a saída
  numérica seja sempre com ponto.
- `Select` depende do suporte a seleção da tarefa 06-12.
- `SetCString` é da API C/emscripten; porte-a como um método normal e documente.

## Fora de escopo

- `DrawingDeviceContext` (tarefa 07-09).
