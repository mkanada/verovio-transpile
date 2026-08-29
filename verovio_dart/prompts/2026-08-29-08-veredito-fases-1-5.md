# 2026-08-29-08 — Veredito: as Fases 1 a 5 terminaram?

> Antes de começar: leia `prompts/00-MESTRE.md` e `CLAUDE.md`. Trabalhe a partir de `verovio_dart/`.

## O que esta tarefa é

O portão final, e o único prompt desta série que é **reutilizável**: rode-o sempre que quiser a
resposta atualizada, hoje ou daqui a três meses, sem depender de nenhuma sessão anterior. Ele não
pressupõe que as tarefas `2026-08-29-01`..`-05`, `06` ou `07` tenham sido feitas — mede o que está
na árvore agora.

Você não escreve código de produção.

## Passo 1 — a medição completa

```bash
cd verovio_dart
dart run tool/verify_phases.dart --full --verbose
```

`--full` regera as medições caras antes de julgar (varredura dos 623 arquivos, `validate_layout`,
suíte de testes). Leva ~20 min. **Não use o modo rápido para dar veredito final**: sem `--full` os
números vêm de relatórios gravados, e embora o portão reprove relatório mais velho que `lib/`, um
relatório fresco escrito por uma tarefa que se enganou continua sendo um relatório de segunda mão.

## Passo 2 — o portão mede o que diz medir

Antes de aceitar um `PASS`, confirme que o portão não foi afrouxado desde 2026-08-29:

```bash
git log --oneline -- tool/verify_phases.dart
git diff <primeiro-commit-do-arquivo>..HEAD -- tool/verify_phases.dart
```

Reprove qualquer critério removido, rebaixado a `info`, ou com limiar alargado (`kAnalyzeBaseline`
acima de 8; `kFunctorsFase4Abertos` encurtada; entrada nova em `kResourcesEquivalentes` sem
justificativa citando o C++ no relatório da tarefa que a introduziu).

Se o portão passar mas tiver sido adulterado, o veredito é **ABERTA**.

## Passo 3 — as três provas que o portão não sabe fazer

Um verificador estático mede o que alguém lembrou de programar nele. Estas três não dá para automatizar:

**(a) O harness ainda não devolve os goldens.** Edite um número num golden de arquivo "limpo",
rode o comparador só nele, confirme que acusa divergência, desfaça com `git checkout --`.
Detalhes no Passo 1 da `07`. Sem esta prova, o número da Fase 5 não vale nada.

**(b) Os testes mordem.** Escolha três testes ao acaso entre os que cobrem trabalho recente, quebre
a linha de `lib/` que cada um cobre, confirme o vermelho, desfaça.

**(c) O SVG desenha a mesma música.** Escolha três arquivos limpos de famílias diferentes e compare
o SVG do Dart com o golden visualmente. Limpo estruturalmente não é o mesmo que correto.

## Passo 4 — o veredito

Grave `prompts/reports/2026-08-29-08.md` — ou, em execuções futuras,
`prompts/reports/<AAAA-MM-DD>-veredito.md` — com:

| Fase | Veredito | Evidência |
|---|---|---|
| 1 — Fundações | FECHADA / ABERTA | critério do portão + motivo |
| 2 — Modelo de dados MEI | | |
| 3 — Leitura de arquivos | | |
| 4 — Motor de layout | | |
| 5 — Renderização SVG | | |

Mais: a saída completa do portão, o resultado das três provas do Passo 3, e — para cada fase
ABERTA — **uma frase** dizendo o que falta e qual prompt a fecha. Se o prompt não existir, escreva-o
e linke no `README.md`.

Por fim, reconcilie o `PLANO.md`: a tabela "Estado medido" e os checkboxes têm de bater com esta
tabela. Se não baterem, o `PLANO.md` está errado — conserte-o, e diga no relatório o que estava
divergindo.

## As duas regras que não se negociam

1. **Fechar fase é consequência do número, não decisão de quem escreve o relatório.** Se um critério
   reprovar, a fase fica aberta, por menor que pareça o motivo.
2. **Silêncio não é aprovação.** Se uma verificação não rodou — porque deu erro, porque demorou,
   porque a ferramenta faltou — o resultado dela é `NÃO MEDIDO`, e uma fase com critério não medido
   é `ABERTA`. Nunca escreva "presumivelmente passa".

## Referência: o estado em 2026-08-29

Para você saber se subiu ou desceu desde o dia em que esta série foi escrita:

| Métrica | 2026-08-29 |
|---|---|
| `dart analyze` | 8 (baseline) |
| `dart test` | 681 testes, ~7 min, 1 falha no working tree |
| `compare_svg --all` | 115/623 estrutural, 4/623 numérico, 3 exceções |
| `validate_layout` | 618/621 layout OK, 173/191 timemaps |
| Fases fechadas | 3 de 5 (1, 2 e 4 com uma lacuna cada; 5 em 18,5%) |

## Fora de escopo

- Escrever código de produção.
- Fases 6 e 7.
