# 05-14 — view_element.cpp (B): acidentes, articulações, armaduras e fórmulas de compasso

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## Objetivo

Portar o desenho de acidentes, articulações, armaduras de clave (com cancelamento) e fórmulas de
compasso.

## Pré-condições

Tarefa **05-13** concluída.

```bash
cd verovio_dart
grep -c "_notYet('DrawAccid'" lib/src/rendering/view_element.dart   # 1
dart test 2>&1 | tail -1     # verde, ≥ 445
```

## Referência C++

`origin/src/src/view_element.cpp`, faixas:

| Linha | Função |
|---:|---|
| 242 | `DrawAccid` |
| 341 | `DrawArtic` |
| 993 | `DrawKeySig` |
| 1085 | `DrawMeterSig` (primeira sobrecarga) |
| 1107 | `DrawKeySigCancellation` |
| 1129 | `DrawKeyAccid` |
| 1146 | `DrawMeterSig` (segunda sobrecarga — **são duas funções distintas**) |
| 2049 | `DrawMeterSigFigures` |

## Arquivos Dart a criar/alterar

- **Alterar** `lib/src/rendering/view_element.dart`.
- **Alterar** `test/view_element_test.dart`.

## Passo a passo

1. Leia as faixas.
2. Porte `DrawAccid` (242-340): trata acidentes normais, de cortesia (`@func="caution"`,
   entre parênteses), microtonais e os de tabela SMuFL estendida.
3. Porte `DrawArtic` (341-433): posiciona o glifo dentro ou fora do pentagrama conforme o que o
   `AdjustArticFunctor` (tarefa 04b) decidiu.
4. Porte `DrawKeySig`, `DrawKeySigCancellation` e `DrawKeyAccid`.
5. Porte as **duas** sobrecargas de `DrawMeterSig` e `DrawMeterSigFigures`.
6. Testes: `test/corpus/accid/` (14), `test/corpus/artic/` (19), `test/corpus/keysig/` (6),
   `test/corpus/metersig/` (5), `test/corpus/mensur/` (8).
7. Verificação.

## Critérios de aceite

- [ ] `dart analyze` ≤ baseline
- [ ] `dart test` verde, **≥ 456 testes**
- [ ] `dart run tool/compare_svg.dart test/corpus/accid --mode=structural` reporta **≥ 8 de 14** limpos
- [ ] `dart run tool/compare_svg.dart test/corpus/keysig --mode=structural` reporta **≥ 4 de 6** limpos
- [ ] `dart run tool/compare_svg.dart --all --mode=structural` maior que na tarefa 05-13
- [ ] Nenhum `_notYet` das funções desta tarefa restou
- [ ] Relatório em `prompts/reports/05-14.md`
- [ ] `PLANO.md`: checkbox de `view_element.cpp` (B) marcado

## Armadilhas conhecidas

- **Duas `DrawMeterSig`** (1085 e 1146). Assinaturas diferentes. Porte as duas e ligue cada uma no
  seu chamador.
- Acidentes de cortesia são desenhados com parênteses **desenhados**, não com caractere de parêntese.
- `DrawKeySigCancellation` desenha os bequadros da armadura anterior; só aparece em mudança de
  armadura. `test/corpus/keysig/` tem os casos.
- O X dos acidentes veio do `AdjustAccidXFunctor` (tarefa 04b). Se colidirem, o bug é lá.
- Articulação dentro do pentagrama usa glifo diferente da de fora, em alguns casos.

## Fora de escopo

- Pausas, clefs, custos (tarefa 05-15).
