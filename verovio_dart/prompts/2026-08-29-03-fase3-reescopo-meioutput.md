# 2026-08-29-03 — Fase 3: mover o checkbox de `MEIOutput` para a Fase 6

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Tarefa **documental**: nenhuma linha de `lib/` muda.

A Fase 3 se chama "Leitura de arquivos" e tem seis itens, cinco de leitura e um de escrita
(`MEIOutput`, 3.416 linhas / 200 métodos de `origin/src/src/iomei.cpp`). A leitura está completa e
medida — os **187** `MEIInput::Read*` e os **15** `MusicXmlInput::Read*` do C++ têm contraparte
Dart, verificado em 2026-08-29. A escrita nunca foi começada, e o próprio plano já a decompôs em
quatro prompts da Fase 6 (`06-08` a `06-11`).

Decisão tomada em 2026-08-29 pelo dono do projeto: **a escrita é Fase 6**. Esta tarefa registra
isso, para que a Fase 3 pare de ser reportada como incompleta por um item que foi realocado.

## O que fazer

1. **`PLANO.md`, Fase 3** — o parágrafo final hoje diz:

   > **`MEIOutput` (3.416 linhas / 200 métodos) não portado** — `Toolkit.getMEI()` (`toolkit.dart:69`)
   > devolve a string carregada, não a árvore serializada. Trabalho realocado para a Fase 6 (06-08 a 06-11).

   Reescreva-o como decisão de escopo consumada, não como pendência: a Fase 3 cobre leitura, a
   escrita de MEI é da Fase 6, e o ponteiro para `06-08..06-11` permanece. Ajuste o título da fase
   para deixar isso explícito já no cabeçalho (algo como "Fase 3 — Leitura de arquivos ✅ (escrita
   de MEI é Fase 6, por decisão de 2026-08-29)").

2. **`PLANO.md`, tabela de estado** — a linha da Fase 3 deve passar a `✅ concluída`, sem ressalva.

3. **`PLANO.md`, Fase 6** — o item `MEIOutput` já está lá (06-08 a 06-11). Acrescente uma frase
   dizendo que ele veio da Fase 3 por decisão de 2026-08-29, para que a origem não se perca.

4. **`PLANO.md`, "Definição de pronto"** — confira se algum critério de v1.0 depende de
   `getMEI()` devolver a árvore serializada. Se depender, ele continua válido: o reescopo move
   *quando* o trabalho acontece, não *se*.

5. **`prompts/README.md`** — a tabela da Fase 6 já lista `06-08..06-11`. Acrescente na coluna de
   observação, ou numa nota abaixo da tabela, que esses quatro fecham um item herdado da Fase 3.

6. **Nada mais.** Em particular: **não** mude `toolkit.dart`, **não** mude o comportamento de
   `getMEI()`, e **não** marque nenhum checkbox de `06-08..06-11`.

## Critérios de aceite

- [ ] `dart run tool/verify_phases.dart --fase=3` → **PASS** (já passa hoje; confirme que continua)
- [ ] `git diff --stat` mostra **apenas** `PLANO.md` e `prompts/README.md`
- [ ] `dart analyze` e `dart test` inalterados (nada de `lib/` foi tocado)
- [ ] Relatório em `prompts/reports/2026-08-29-03.md` — curto, registrando a decisão e a data

## Nota sobre honestidade de escopo

Reescopar é legítimo; **reescopar para poder declarar uma fase pronta não é**, a menos que o
trabalho realocado continue agendado e visível. Por isso os passos 3 e 5 não são opcionais: se
`MEIOutput` sair da Fase 3 sem aparecer com destaque na Fase 6, esta tarefa virou maquiagem.
O critério 3.4 do portão existe para isso — ele imprime, toda vez que roda, que a escrita não está
portada e a quem ela pertence.
