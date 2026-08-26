# 06-10 — MEIOutput (C): elementos de camada

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Serializar todos os elementos de camada: notas, acordes, pausas, beams, quiálteras, claves,
armaduras, ligaduras mensurais, neumas, tablatura.

## Pré-condições

Tarefa **06-09** concluída.

```bash
cd verovio_dart
grep -c "_notYet('WriteNote'" lib/src/io/mei_output.dart   # 1
dart test 2>&1 | tail -1     # verde, ≥ 658
```

## Referência C++

`origin/src/src/iomei.cpp`. Liste os `Write*` de elementos de camada:

```bash
grep -oP 'MEIOutput::Write\K\w+' origin/src/src/iomei.cpp | sort -u
```

e cruze com as classes de `lib/src/model/layer_elements_gen.dart` e `lib/src/model/basic_elements.dart`.
São as classes cujo `ClassId` está na faixa de elemento de camada em `lib/src/core/vrvdef.dart`.

Cada `Write*` no C++ chama os `WriteAtt*` dos mixins de atributo. Em Dart os mixins gerados em
`lib/src/model/atts/` têm `writeXxx(element)` — **use-os**, um por classe `Att` que a classe usa.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/io/mei_output.dart`.
- **Alterar** `test/mei_output_test.dart`.

## Passo a passo

1. Produza a lista de elementos de camada a serializar e **cole-a no relatório**.
2. Para cada um: leia o `Write*` do C++, veja quais `WriteAtt*` ele chama, e escreva a contraparte
   Dart chamando os `writeXxx` dos mixins.
3. Testes: round-trip por categoria do corpus. Para cada uma das 10 maiores categorias
   (`beam` 61, `ligature` 50, `gracenote` 27, `slur` 25, `mensural` 25, `cross-staff` 24,
   `tuplet` 22, `rest` 21, `artic` 19, `stem` 16), afirme que o round-trip é estável e compare com
   o MEI do C++.
4. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 670 testes**
- [ ] Nenhum `_notYet` de elemento de camada restou
- [ ] Round-trip estável (duas serializações idênticas) para **≥ 200 dos 623** arquivos do corpus —
      escreva uma tool ou um teste que meça isso e cole o número no relatório
- [ ] Para ao menos 20 arquivos, a serialização Dart bate com a do C++ em **igualdade exata de
      string**; o relatório lista quais e o número total
- [ ] Relatório em `prompts/reports/06-10.md`
- [ ] `PLANO.md`: checkbox "IOMEI — escrita (C)" marcado

## Armadilhas conhecidas

- **Ordem dos atributos.** O C++ chama os `WriteAtt*` numa ordem fixa, definida na declaração da
  classe. Chamar os mixins em outra ordem gera atributos em ordem diferente e a comparação exata
  falha. Confira a ordem no `Write*` do C++, uma por uma.
- Atributos com valor default **não são escritos** pelo C++ (o `writeXxx` do mixin só escreve se
  `isSet`). Se o Dart escrever defaults, o arquivo cresce e diverge.
- `@xml:id`: veja a nota da tarefa 06-08 sobre `m_removeIds`.
- Elementos de desenho (`Dots`, `Flag`, `TupletBracket`, `TupletNum`, `Stem`) **não são exportados** —
  são criados pelo layout. Se aparecerem na saída, é bug.
- Duração: `@dur` vs. `@dur.ges` vs. `Fraction` interna. O C++ escreve o que leu, não o calculado.

## Fora de escopo

- Elementos de controle, texto e editorial (tarefa 06-11).
