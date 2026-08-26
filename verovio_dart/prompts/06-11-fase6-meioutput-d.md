# 06-11 — MEIOutput (D): controle, texto, editorial, SaveFunctor e `Toolkit.getMEI` de verdade

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar o `MEIOutput`: elementos de controle, elementos de texto, markup editorial, fac-símile,
o `SaveFunctor` que faz a travessia — e trocar o `Toolkit.getMEI()` que hoje ecoa o input por uma
serialização real da árvore.

## Pré-condições

Tarefa **06-10** concluída.

```bash
cd verovio_dart
grep -c "_notYet('WriteSlur'\|_notYet('WriteDynam'" lib/src/io/mei_output.dart   # > 0
dart test 2>&1 | tail -1     # verde, ≥ 670
```

## Referência C++

`origin/src/src/iomei.cpp`, os `Write*` de:

- **controle**: slur, tie, hairpin, dynam, dir, tempo, harm, fermata, trill, mordent, turn, octave,
  pedal, bracketSpan, breath, caesura, fing, gliss, arpeg, reh, repeatMark, lv, phrase, annotScore,
  pitchInflection, cpMark, beamSpan;
- **texto**: rend, lb, num, fig, svg, symbol, div, text, f, fb;
- **editorial**: app, lem, rdg, choice, sic, corr, orig, reg, abbr, expan, supplied, unclear, add,
  del, damage, restore, subst, annot, ref;
- **fac-símile**: facsimile, surface, zone.

Liste-os com:
```bash
grep -oP 'MEIOutput::Write\K\w+' origin/src/src/iomei.cpp | sort -u
```
e subtraia os já feitos nas tarefas 06-08 a 06-10.

`Toolkit::GetMEI` em `origin/src/src/toolkit.cpp` — leia-a; ela tem opções (`pageNo`, `scoreBased`,
`removeIds`) que o Dart terá de aceitar.

**`SaveFunctor`**: `origin/src/include/vrv/savefunctor.h` e `origin/src/src/savefunctor.cpp`
(187 linhas), mais `Object::SaveObject` (`grep -n "Object::SaveObject" origin/src/src/object.cpp`).
É o functor que percorre a árvore chamando a saída. Se a tarefa 06-08 escreveu uma travessia ad hoc
em `mei_output.dart`, **troque-a** por este functor e verifique que o resultado não muda.

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/io/mei_output.dart`.
- **Criar** `lib/src/io/save_functor.dart` — `SaveFunctor`.
- **Alterar** `lib/src/model/object.dart` — `saveObject`.
- **Alterar** `lib/src/toolkit.dart` — `getMEI()` real; **apagar** o campo `_mei` se ele deixar de ser
  necessário, ou documentar por que continua.
- **Alterar** `test/mei_output_test.dart`, `test/toolkit_io_test.dart`; criar `test/save_functor_test.dart`.

## Passo a passo

1. Produza a lista dos `Write*` restantes. Cole no relatório.
2. Porte-os.
3. Porte `SaveFunctor` e `Object.saveObject`, e faça `mei_output.dart` percorrer a árvore por ele.
4. Reescreva `Toolkit.getMEI()` para serializar a árvore via `MeiOutput`, com os parâmetros de
   `Toolkit::GetMEI` do C++.
5. **Teste que prova o buraco fechado:** carregar um **MusicXML** (`test/corpus/midi/*.musicxml`,
   5 arquivos) e pedir `getMEI()` tem de devolver **MEI**, não MusicXML. Compare com
   `./build/verovio -r verovio_dart/assets/data -t mei -o /tmp/cpp.mei <arquivo.musicxml>`.
6. Testes de round-trip sobre o corpus inteiro; mais um teste com um functor de saída falso que
   conta visitas, provando que a ordem de travessia do `SaveFunctor` é a do C++.
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 692 testes**
- [ ] `grep -c "_notYet(" lib/src/io/mei_output.dart` = **0**
- [ ] `grep -c "class SaveFunctor" lib/src/io/save_functor.dart` = 1
- [ ] `grep -c "return _mei;" lib/src/toolkit.dart` = 0 (o eco sumiu)
- [ ] Um teste carrega um `.musicxml` e afirma que `getMEI()` devolve um documento cuja raiz é
      `<mei>`, e compara o histograma de elementos com o do C++
- [ ] Round-trip estável para **≥ 550 dos 623** arquivos do corpus; o relatório traz o número
- [ ] Para **≥ 100 arquivos**, a serialização Dart bate com a do C++ em igualdade exata de string
- [ ] Relatório em `prompts/reports/06-11.md`
- [ ] `PLANO.md`: checkbox "IOMEI — escrita" inteiro e o de `savefunctor.cpp` marcados

## Armadilhas conhecidas

- Markup editorial aninhado (`app` > `rdg` > conteúdo) recursa; a ordem dos filhos importa.
- `annot` editorial vs. `annotScore`: são classes diferentes com o mesmo nome MEI base. A tarefa 04i
  consertou os registros; confira que a saída usa o nome certo para cada uma.
- Elementos de controle carregam `@startid`/`@endid`/`@tstamp`/`@tstamp2`. Se a leitura converteu
  tstamp em startid, a escrita tem de devolver o que estava no arquivo, não o convertido —
  veja o que o C++ faz.
- `Toolkit::GetMEI` com `pageNo` exporta uma página só; com `scoreBased` desfaz o cast-off.
- Se `getMEI()` mudar de comportamento, testes existentes em `test/toolkit_io_test.dart` vão quebrar.
  **Corrija-os para o comportamento correto**, não reverta a mudança.
- `SaveFunctor` tem `VisitObject` e `VisitObjectEnd`; o `End` é quem fecha o elemento XML. Faltando
  o `End`, tudo vira irmão em vez de filho. Trocar a travessia ad hoc pelo functor **não pode mudar
  a saída** — se mudar, você errou a travessia.

## Fora de escopo

- `facsimile.cpp` e os functors de sincronização (foram para a tarefa 06-07).
