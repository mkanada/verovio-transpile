# 2026-08-29-04 — Fase 4: o caminho de transcrição e `ReorderByXPos`

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Fechar o **último item aberto da Fase 4**. O checkbox diz "functors de transcrição
(`AdjustXRelForTranscription`, `AdjustYRelForTranscription`, `ApplyPPUFactor`) e `ReorderByXPos`",
mas os quatro não são um grupo: têm chamadores diferentes, em fases diferentes. Leia esta seção
inteira antes de escrever código — portar os quatro sem os chamadores deixa código morto, e código
morto passa no `analyze` e mente no relatório.

| O que | C++ | Linhas | Quem chama |
|---|---|---:|---|
| `AdjustXRelForTranscriptionFunctor` | `adjustxrelfortranscriptionfunctor.cpp` | 35 | `Page::LayOutTranscription` (`page.cpp:307`) |
| `AdjustYRelForTranscriptionFunctor` | `adjustyrelfortranscriptionfunctor.cpp` | 35 | `Page::LayOutTranscription` (`page.cpp:309`) |
| `ApplyPPUFactorFunctor` | `miscfunctor.cpp` / `.h:22` | ~40 | `MEIInput::ReadPage` (`iomei.cpp:4462`) |
| `ReorderByXPosFunctor` + `Object::ReorderByXPos()` | `miscfunctor.h:175`, `object.cpp:1222` | ~40 | **só** `editortoolkit_neume.cpp` (Fase 6) |

Três consequências:

1. **Os dois de transcrição exigem `Page::LayOutTranscription`** (`page.cpp:~270-316`), que **não
   está portado** — está anotado como lacuna em `rendering/view.dart:278` e `model/doc.dart:546`.
   Portar os functors sem o método é entregar duas classes que nada invoca.
2. **`ApplyPPUFactor` é da leitura**, não do layout: roda em `ReadPage` quando
   `m_doc->IsTranscription()` e `GetPPUFactor() != 1.0`.
3. **`ReorderByXPos` não tem chamador nesta fase.** O único consumidor no C++ é o editor de neumas,
   que é a tarefa `06-23`/`06-24`. Porte-o mesmo assim (o checkbox pede), mas com os olhos abertos:
   a validação dele será sintética, e o relatório tem de dizer isso.

## O arquivo que importa

`test/corpus/neume/neume-001.mei` é o **único** arquivo do corpus com
`<facsimile type="transcription">` — conferido em 2026-08-29. No C++ ele roteia por
`Page::LayOutTranscription`; no Dart, hoje, não, porque o método não existe. O relatório da `04g`
já tinha registrado isso como armadilha ("neume-001 carrega facsimile type=transcription, então o
C++ real roteia por Page::LayOutTranscription") e a tarefa desviou para `neume-002`.

Esse arquivo é a sua validação de ponta a ponta. Hoje a família `neume/` está **0/6** estruturalmente
limpa no `compare_svg`; se o caminho de transcrição estiver certo, `neume-001` é o candidato natural
a virar. **Não prometa que ele vai virar** — pode haver outras causas — mas meça antes e depois.

## Pré-condições

```bash
cd verovio_dart
dart run tool/verify_phases.dart --fase=4
# esperado hoje: FALHA 4.1 — faltam os quatro
dart run tool/compare_svg.dart test/corpus/neume     # anote o ANTES (0/6 em 2026-08-29)
```

## O que fazer, na ordem

1. **`Page::LayOutTranscription`** (`page.cpp`, leia o método inteiro). Ele não é chamado pelo
   `layOut()` padrão: quem o chama é `Doc::LayOutTranscription`, que por sua vez sai de
   `Toolkit::LoadData` quando o documento é de transcrição. Porte o método e o caminho que leva
   até ele; se o gatilho depender de API de `Toolkit` ainda não portada (Fase 7), exponha o método
   e documente no relatório quem deveria chamá-lo, como a `04g` fez com `Page::LayOutPitchPos`.

   Note o bloco `if (!m_layoutDone)` em `page.cpp:297-305`: ele monta um `View` com
   `BBOX_HORIZONTAL_ONLY` e chama `DrawCurrentPage`. Isso agora **existe** no Dart (virada da
   05-30) — use o `View` real, não recrie um atalho.

2. **Os dois functors de transcrição.** São 35 linhas cada; o risco não está no tamanho, está em
   `FacsimileInterface` — leia `facsimile.cpp` e `facsimileinterface.h` para entender de onde saem
   as coordenadas. O getter `m_drawingFacsX/Y` foi portado na `05-32`; o **setter** (`ApplyFacsimile`)
   é da `06-07`. Se o functor precisar do setter, pare, registre pela §8.7 e entregue o resto —
   não invente o setter aqui.

3. **`ApplyPPUFactorFunctor`**, e ligue-o em `MeiInput.readPage`, na mesma condição do C++
   (`IsTranscription() && ppuFactor != 1.0`). Nenhum arquivo do corpus tem `@ppu` — conferido em
   2026-08-29 — então este ramo **não roda em produção**: valide por árvore sintética, como as
   tarefas `04d`/`04f` fizeram, e diga isso no relatório.

4. **`Object::ReorderByXPos()` + `ReorderByXPosFunctor`.** Sem chamador nesta fase. Porte, teste
   sinteticamente (uma `Layer` com filhos fora de ordem de X, afirmando a ordem resultante contra o
   algoritmo de `object.cpp:1222`), e registre que o consumidor chega na `06-23`.

5. **`kAcceptChain`**: cada functor novo que visite uma classe sem `Accept()` próprio precisa da
   entrada. §5(a) do MESTRE.

## Critérios de aceite

- [ ] `dart run tool/verify_phases.dart --fase=4` → **PASS**
- [ ] `dart analyze` ≤ 8, **sem** `ignore_for_file` novo
- [ ] `dart test` verde; testes novos para os quatro, nomeando qual é de produção e qual é sintético
- [ ] `dart run tool/compare_svg.dart test/corpus/neume` — o relatório traz antes × depois, e **diz
      a verdade** se não melhorou
- [ ] `dart run tool/validate_layout.dart` sem regressão (618/621 layout OK, 173 timemaps)
- [ ] Relatório em `prompts/reports/2026-08-29-04.md` com uma seção explícita
      "o que roda em produção e o que é sintético"
- [ ] `PLANO.md`: marcar o último `[ ]` da Fase 4 e mudar a linha da fase na tabela de estado para
      ✅ — **só se** o portão passar

## Armadilhas

- **`Page::LayOutTranscription` pode estourar a fatia.** Se estourar, a ordem de corte é: entregue
  `ApplyPPUFactor` + `ReorderByXPos` (independentes) e deixe o par de transcrição para uma
  `2026-08-29-04b`, registrando pela §8.7. **Não** entregue os functors de transcrição sem o
  chamador só para marcar o checkbox.
- **Não desvie para `neume-002`** como a `04g` fez. Aquele desvio era correto quando o caminho de
  transcrição não existia; o ponto desta tarefa é justamente fazê-lo existir.
- Se `neume-001` continuar divergente depois de tudo, isso é **resultado**, não fracasso — descreva
  a primeira divergência restante com hipótese de causa (§7.2) e siga.

## Fora de escopo

- `ApplyFacsimile` e o resto de `facsimilefunctor.cpp` (tarefa `06-07`).
- O editor de neumas (`06-23`, `06-24`).
- A dívida de tipagem de `lib/src/rendering/` (`05-34`, `05-35`).
