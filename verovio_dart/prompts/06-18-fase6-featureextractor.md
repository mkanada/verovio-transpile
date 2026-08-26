# 06-18 — featureextractor.cpp + GenerateFeaturesFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar o extrator de características (usado para busca e comparação de melodias) e o functor que o
alimenta.

## Pré-condições

Tarefa **06-17** concluída.

```bash
cd verovio_dart
ls lib/src/midi/smf_writer.dart
dart test 2>&1 | tail -1     # verde, ≥ 764
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/include/vrv/featureextractor.h` | — | `class FeatureExtractor` |
| `origin/src/src/featureextractor.cpp` | 173 | a implementação |
| `origin/src/src/midifunctor.cpp` | — | `GenerateFeaturesFunctor::` (`grep -n "GenerateFeaturesFunctor::" origin/src/src/midifunctor.cpp`) |
| `origin/src/src/toolkit.cpp` | — | `Toolkit::GetDescriptiveFeatures` (`grep -n "DescriptiveFeatures\|Features" origin/src/src/toolkit.cpp`) |

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/midi/feature_extractor.dart` — a classe e o functor.
- **Alterar** `lib/src/toolkit.dart` — `getDescriptiveFeatures()`.
- **Criar** `test/feature_extractor_test.dart`.

## Passo a passo

1. Leia os três trechos.
2. Porte a classe e o functor.
3. Porte `Toolkit.getDescriptiveFeatures()`, com o mesmo JSON de saída do C++.
4. Testes: compare o JSON com o do C++. Descubra a flag da CLI:
   `./build/verovio --help | grep -i feature`. Se a CLI não expuser, use os valores documentados no
   header e teste as características uma a uma sobre arquivos simples do corpus.
5. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 772 testes**
- [ ] `grep -c "class FeatureExtractor" lib/src/midi/feature_extractor.dart` = 1
- [ ] Para ao menos 10 arquivos do corpus, o JSON de características bate com o do C++ (ou, se a CLI
      não expuser, cada característica é testada isoladamente com valor calculado à mão a partir do
      C++) — o relatório diz qual dos dois caminhos foi usado e por quê
- [ ] Relatório em `prompts/reports/06-18.md`
- [ ] `PLANO.md`: checkbox de `featureextractor.cpp` marcado

## Armadilhas conhecidas

- As características são intervalos e contornos melódicos; dependem dos onsets, ou seja, do timemap
  (tarefa 06-15). Se divergirem, verifique o timemap antes.
- O JSON tem arrays cuja ordem é a ordem das notas no documento.
- É um arquivo pequeno (173 linhas) — não invente características que o C++ não tem.

## Fora de escopo

- Transposição (tarefas 06-19 a 06-21).
