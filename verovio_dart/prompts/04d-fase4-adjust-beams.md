# 04d — AdjustBeamsFunctor

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar `AdjustBeamsFunctor`: o ajuste vertical das barras de ligação (beams) contra os elementos
de camada que ficam entre elas e o pentagrama. Ao final, uma barra deixa de atravessar notas,
pausas ou claves que estejam no seu caminho.

## Pré-condições

Tarefas **04a**–**04c** concluídas.

```bash
cd verovio_dart
ls lib/src/layout/adjust_tuplets.dart
dart test 2>&1 | tail -1     # verde, ≥ 279
```

## Referência C++

| Arquivo | Linhas | Conteúdo |
|---|---:|---|
| `origin/src/include/vrv/adjustbeamsfunctor.h` | — | `class AdjustBeamsFunctor`. Visits: `Beam`, `BeamEnd`, `Clef`, `FTrem`, `FTremEnd`, `LayerElement`, `Rest`. |
| `origin/src/src/adjustbeamsfunctor.cpp` | 434 | todos os visits acima. |
| `origin/src/src/page.cpp:509-608` | — | `AdjustBeamsFunctor adjustBeams(doc);` na fase vertical, logo depois de `AdjustArticWithSlurs`. |

Classes de apoio que o functor usa: `BeamSegment`, `BeamDrawingInterface` (`origin/src/include/vrv/beam.h`).
Confirme o que já existe em Dart antes de portar:

```bash
grep -rn "class BeamSegment\|class BeamDrawingInterface\|mixin BeamDrawingInterface" lib/src/
```

## Arquivos Dart a criar/alterar

- **Criar** `lib/src/layout/adjust_beams.dart` — `AdjustBeamsFunctor`.
- **Alterar** `lib/src/model/doc.dart` — ligar na fase vertical, na posição do `page.cpp`;
  atualizar o comentário de "skipped" em `:461-462` e `:505`.
- **Criar** `test/adjust_beams_test.dart`.

## Passo a passo

1. Leia `adjustbeamsfunctor.h` e as 434 linhas do `.cpp` inteiras.
2. Levante o que falta das classes de apoio (`BeamSegment`, campos de `BeamDrawingInterface`) com o
   grep acima. Se faltar campo, acrescente-o na classe Dart correspondente com doc comment citando
   o C++ — mas **só o que este functor usa**.
3. Porte `AdjustBeamsFunctor` em `adjust_beams.dart`.
4. Ligue no `doc.dart`.
5. Testes: `test/corpus/beam/` tem **61 arquivos**. Escolha três que exercitem casos distintos —
   um beam simples, um cross-staff (`test/corpus/cross-staff/`), um com pausa dentro do beam.
   Asserte a coordenada Y dos extremos do `BeamSegment`.
6. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ `10 issues found.`
- [ ] `dart test` verde, **≥ 283 testes**
- [ ] `grep -c "class AdjustBeamsFunctor" lib/src/layout/adjust_beams.dart` = 1
- [ ] `dart run tool/validate_layout.dart`: `Check notes: None.`, timemaps **≥ 24/30**,
      `beam/beam-001.mei` com `Layout OK` e todos os `PASS`
- [ ] Relatório em `prompts/reports/04d.md`
- [ ] `PLANO.md`: `AdjustBeams` removido da lista de faltantes

## Armadilhas conhecidas

- `VisitFTrem`/`VisitFTremEnd` existem porque o tremolo compartilha a geometria de beam. Não pule.
- `VisitClef` está lá para o caso de uma mudança de clave no meio do beam. Caso raro, mas
  `test/corpus/clef/` cobre.
- O functor trabalha com `m_outerBeam`/estado de aninhamento — beams dentro de beams. Copie a
  gestão de estado ao pé da letra.
- Cross-staff: a coordenada Y de referência muda de pentagrama. `test/corpus/cross-staff/` tem 24
  arquivos; use-os.
- Divisão inteira: coordenadas de beam são `int` em unidades de desenho. `~/`, não `/`.

## Fora de escopo

- `view_beam.cpp` (o **desenho** do beam) — é a tarefa 05-17, muito depois.
- `CalcSpanningBeamSpans` (tarefa 04f).
