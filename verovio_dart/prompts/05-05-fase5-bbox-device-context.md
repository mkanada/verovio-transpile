# 05-05 — BBoxDeviceContext: fechar as lacunas

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Completar `lib/src/rendering/bbox_device_context.dart` contra `origin/src/src/bboxdevicecontext.cpp`,
para que ele possa substituir `headless_extents.dart` na tarefa 05-12.

## Pré-condições

Tarefa **05-04** concluída.

```bash
cd verovio_dart
grep -c "UnimplementedError" lib/src/rendering/svg_device_context.dart   # 0
dart test 2>&1 | tail -1                                                  # verde, ≥ 362
```

## Referência C++

`origin/src/include/vrv/bboxdevicecontext.h` e `origin/src/src/bboxdevicecontext.cpp` (457 linhas),
que tem 40 métodos. Medido em 2026-08-26, `bbox_device_context.dart` (531 linhas) cobre 38.
**Faltam:**

- `BBoxDeviceContext::GetPenWidthOverlap`
- `BBoxDeviceContext::SetUserScale` (o C++ sobrescreve o da base)

E há um `TODO` em `lib/src/rendering/bbox_device_context.dart:414` sobre texto rotacionado
(`RotateGraphic` / `ResetGraphicRotation`).

Reconfira a lista antes de portar:

```bash
grep -oP '^\w[\w:*&<>, ]*BBoxDeviceContext::\K\w+' origin/src/src/bboxdevicecontext.cpp | sort -u
```

Constantes de modo: `BBOX_BOTH`, `BBOX_HORIZONTAL_ONLY`, `BBOX_VERTICAL_ONLY`
(`origin/src/include/vrv/bboxdevicecontext.h`) — confira que existem em
`lib/src/core/vrvdef.dart` com os mesmos valores.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/bbox_device_context.dart`.
- **Alterar** `lib/src/core/vrvdef.dart` se faltar alguma constante `BBOX_*`.
- **Alterar** `test/resources_device_context_test.dart` ou criar
  `test/bbox_device_context_test.dart`.

## Passo a passo

1. Rode o grep acima e monte a lista real do que falta. Cole no relatório.
2. Porte `GetPenWidthOverlap` e `SetUserScale`.
3. Resolva o `TODO` da linha 414: porte `RotateGraphic` e `ResetGraphicRotation` como no C++.
4. Confira `UpdateBB` (o coração da classe) linha a linha contra o C++ — ele é quem acumula a caixa
   e respeita o modo `BBOX_*`. Um erro aqui envenena a Fase 4 inteira depois da virada.
5. Testes: para cada modo (`BBOX_BOTH`, `BBOX_HORIZONTAL_ONLY`, `BBOX_VERTICAL_ONLY`), desenhe um
   retângulo conhecido e asserte a caixa resultante. Teste `GetPenWidthOverlap` com penas de
   larguras diferentes. Teste que texto rotacionado produz a caixa esperada.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 370 testes**
- [ ] Nenhum método de `origin/src/src/bboxdevicecontext.cpp` sem contraparte — prove no relatório
      colando a saída do diff de nomes
- [ ] `grep -c "TODO" lib/src/rendering/bbox_device_context.dart` = 0
- [ ] Um teste por modo `BBOX_*`, com caixa esperada calculada à mão a partir do C++
- [ ] Relatório em `prompts/reports/05-05.md`
- [ ] `PLANO.md`: checkbox de `bboxdevicecontext.cpp` marcado

## Armadilhas conhecidas

- `UpdateBB` acumula em coordenadas **lógicas**, não de dispositivo. A conversão passa pelo `View`
  (`ToLogicalX/Y`), que ainda não existe — porte a interface e deixe o teste usar um `View` falso.
- `BBOX_HORIZONTAL_ONLY` ignora Y **e** faz o `EndGraphic` gravar só a extensão horizontal. Não é só
  um filtro na hora de escrever.
- `GetPenWidthOverlap` devolve metade da largura da pena arredondada de um jeito específico; copie a
  aritmética, não a intenção.
- **Ainda não** ligue o `BBoxDeviceContext` ao layout — isso é a tarefa 05-12, e só faz sentido
  depois de o `View` existir.

## Fora de escopo

- Deletar `headless_extents.dart` (tarefa 05-12).
- `View` (tarefa 05-06).
