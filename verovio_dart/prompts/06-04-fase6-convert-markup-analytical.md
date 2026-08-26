# 06-04 — ConvertMarkupAnalyticalFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `ConvertMarkupAnalyticalFunctor`: a conversão da marcação analítica do MEI (`@fermata`,
`@tie`, `@slur`, `@trill`, `@mordent`, `@turn` como **atributos** de nota) nos elementos de controle
correspondentes. Sem ele, arquivos que usam marcação analítica perdem esses símbolos na renderização.

## Pré-condições

Tarefa **06-03** concluída.

```bash
cd verovio_dart
ls lib/src/layout/find_layer_elements.dart
dart test 2>&1 | tail -1     # verde, ≥ 612
```

## Referência C++

`origin/src/include/vrv/convertfunctor.h` → `class ConvertMarkupAnalyticalFunctor`.
`origin/src/src/convertfunctor.cpp` (1465 linhas) → localize com
`grep -n "ConvertMarkupAnalyticalFunctor::" origin/src/src/convertfunctor.cpp`.

Quem o chama: `Doc::ConvertMarkupDoc` (`grep -n "ConvertMarkup" origin/src/src/doc.cpp`).
Em Dart, `Doc.convertMarkupDoc` **já existe** e já chama os equivalentes de
`ConvertMarkupArticFunctor` (`doc.dart:2278`) e `ConvertMarkupScoreDefFunctor` (`doc.dart:2315`) —
falta este terceiro.

A opção `preserveAnalyticalMarkup` (`OptionBool m_preserveAnalyticalMarkup` em
`origin/src/include/vrv/options.h`) desliga a conversão. Acrescente-a ao `options_shell.dart`
com o default do C++ — e **só ela**.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/model/doc.dart` — acrescentar o functor a `convertMarkupDoc`.
- **Criar** `lib/src/layout/convert_markup_analytical.dart`.
- **Alterar** `lib/src/core/options_shell.dart` — `preserveAnalyticalMarkup`.
- **Criar** `test/convert_markup_analytical_test.dart`.

## Passo a passo

1. Leia a classe inteira no `.cpp`.
2. Leia `Doc::ConvertMarkupDoc` no C++ e confira a ordem em que os três functors rodam.
3. Porte o functor.
4. Ligue no `doc.dart`, na posição certa.
5. Testes: arquivos do corpus com marcação analítica — encontre-os com
   ```bash
   grep -l 'tie="[im]\|slur="[im]\|fermata="' test/corpus/**/*.mei | head -10
   ```
   Para cada um, afirme que os elementos de controle nascem com os `@startid`/`@endid` certos.
   Teste também `preserveAnalyticalMarkup: true` (não converte).
6. Compare com o C++: `./build/verovio -r verovio_dart/assets/data -t mei -o /tmp/cpp.mei <arquivo>`
   e confira que os mesmos elementos aparecem.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 620 testes**
- [ ] `grep -c "class ConvertMarkupAnalyticalFunctor" lib/src/layout/convert_markup_analytical.dart` = 1
- [ ] Para ao menos 5 arquivos do corpus com marcação analítica, o histograma de elementos da árvore
      Dart bate com o do MEI convertido pelo C++ — use `dart run tool/validate_io.dart` ou um
      comando equivalente, e cole a saída no relatório
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` **sobe ou não regride**
- [ ] Relatório em `prompts/reports/06-04.md`
- [ ] `PLANO.md`: checkbox de `ConvertMarkupAnalytical` marcado

## Armadilhas conhecidas

- `@tie="i"` (início), `"m"` (meio), `"t"` (fim) formam cadeias. O functor tem de casar início com
  fim ao longo de compassos.
- Os elementos criados recebem `@xml:id` gerados. Se os ids não baterem com os do C++, o SVG
  diverge — confira como o C++ os gera antes de inventar.
- `preserveAnalyticalMarkup` mantém **os atributos** além de criar os elementos; não é só um "pular".
- A ordem dentro de `ConvertMarkupDoc` importa: markup analítico antes ou depois do de articulação
  muda o resultado.

## Fora de escopo

- `ConvertToCmnFunctor` (06-05) e `ConvertToMensuralViewFunctor` (06-06).
