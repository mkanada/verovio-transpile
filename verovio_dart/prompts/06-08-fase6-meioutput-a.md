# 06-08 — MEIOutput (A): esqueleto, cabeçalho e opções de saída

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Começar a portar `MEIOutput` — **3.416 linhas / 200 métodos de `origin/src/src/iomei.cpp` que hoje
não existem em Dart**. Esta tarefa cria a classe, a serialização do documento MEI e o cabeçalho.

> Contexto medido em 2026-08-26: `Toolkit.getMEI()` (`lib/src/toolkit.dart:70`) devolve **a string
> que foi carregada**, não uma serialização da árvore. Carregar MusicXML e pedir MEI devolve o
> MusicXML. Isto é um buraco da Fase 3 que só foi detectado na auditoria.

## Pré-condições

Tarefa **06-07** concluída.

```bash
cd verovio_dart
grep -rn "class MeiOutput" lib/src/    # esperado: nada
sed -n '69,74p' lib/src/toolkit.dart   # o getMEI que devolve _mei
dart test 2>&1 | tail -1               # verde, ≥ 644
```

## Referência C++

`origin/src/include/vrv/iomei.h` → `class MEIOutput`.
`origin/src/src/iomei.cpp` (9.176 linhas no total; os blocos `MEIOutput::` somam **3.416**).

Localize os métodos desta tarefa:

```bash
grep -n "MEIOutput::MEIOutput\|MEIOutput::~MEIOutput\|MEIOutput::Export\|MEIOutput::Skip\|MEIOutput::WriteDoc\|MEIOutput::WriteMeiHead\|MEIOutput::Write(" origin/src/src/iomei.cpp
```

Do lado da leitura, `lib/src/io/mei_input.dart` (~5,3k linhas) já resolve os problemas gêmeos
(árvore `MeiXmlNode` mutável em `lib/src/io/xml_node.dart`, upgrades de versão). **Leia-o antes de
escrever**: a saída tem de ser simétrica à entrada, e a `MeiXmlNode` é a estrutura a reusar.

Opções de saída relevantes (`origin/src/include/vrv/options.h`): `m_outputIndent`,
`m_outputIndentTab`, `m_outputFormatRaw`, `m_outputSmuflXmlEntities`, `m_removeIds`.
Acrescente **só essas 5** ao `options_shell.dart`.

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/io/mei_output.dart` — `class MeiOutput`, com o esqueleto e o cabeçalho.
- **Alterar** `lib/src/core/options_shell.dart` — as 5 opções acima.
- **Criar** `test/mei_output_test.dart`.

## Passo a passo

1. Leia `iomei.h` (a declaração de `MEIOutput`) inteiro.
2. Leia a leitura correspondente em `lib/src/io/mei_input.dart` para saber o que a árvore contém.
3. Porte: construtor, `Export`, `Skip`, `WriteDoc`, a serialização do `<mei>`/`<meiHead>` e o
   despachante genérico `Write(Object*)` que roteia por `ClassId`.
   Os `Write<Elemento>` específicos ficam nas tarefas 06-09 a 06-11: deixe cada um como
   `_notYet('WriteXxx', '06-09')`.
4. Acrescente as 5 opções.
5. Testes: carregue `test/corpus/note/note-001.mei`, serialize, e compare o `<meiHead>` e a
   estrutura de topo com o MEI que o C++ produz:
   ```bash
   ./build/verovio -r verovio_dart/assets/data -t mei -o /tmp/cpp.mei test/corpus/note/note-001.mei
   ```
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 650 testes**
- [ ] `grep -c "class MeiOutput" lib/src/io/mei_output.dart` = 1
- [ ] Um teste compara o `<meiHead>` gerado com o do C++ por **igualdade exata de string**
- [ ] Todo `Write*` não portado tem `_notYet` nomeando a tarefa (06-09, 06-10 ou 06-11)
- [ ] As 5 opções de saída existem com os defaults do C++; o relatório lista nome e default lido de
      `options.cpp`
- [ ] Relatório em `prompts/reports/06-08.md`
- [ ] `PLANO.md`: checkbox "IOMEI — escrita (A)" marcado

## Armadilhas conhecidas

- **Indentação.** O C++ indenta com `m_outputIndent` espaços (default lido de `options.cpp`) ou tab.
  A comparação com o C++ é de string exata; errar a indentação faz tudo divergir.
- `m_removeIds` remove `@xml:id` gerados, mantendo os que vieram do arquivo original. Distinguir os
  dois exige saber quais foram gerados — veja como o modelo marca isso
  (`grep -n "isAttribute\|generatedID\|_idGenerated" lib/src/model/object.dart`).
- A ordem dos atributos na saída segue a ordem das classes `Att*`, não alfabética. Os mixins
  gerados em `lib/src/model/atts/` têm `writeXxx` — use-os, não escreva atributo à mão.
- Não reescreva `xml_node.dart`; ele já é a árvore mutável espelhando pugixml.

## Fora de escopo

- Os `Write*` de elementos (06-09 a 06-11).
