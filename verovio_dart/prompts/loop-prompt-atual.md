# PROMPT ATUAL — Loop Supervisor + Subagente (salvo 2026-09-02 10:17, baseline 572/621)

Salvo a pedido do usuário antes de desligar. Estado: `main` em `2076cec` (572/621 limpos estrutural, 49 diverg), `ff43919` (565), `8726f81` (564), `fef54a4` (561), `048b062` (559). Loop encerrado, pronto para retomar.

**2026-09-02: prompts divididos em dois arquivos** — o texto do Supervisor e do
Subagente que vivia embutido aqui foi movido para
`prompts/loop-prompt-supervisor.md` e `prompts/loop-prompt-subagente.md`
respectivamente. Este arquivo (`loop-prompt-atual.md`) passa a ser só o
registro de estado/histórico do loop; para retomar, use os dois arquivos
novos (o Supervisor referencia o Subagente pelo path). O item 3.d do
Subagente também ganhou uma revisão: em vez de descartar a mudança na
primeira piora, ele agora identifica quais arquivos regrediram e investiga
esse conjunto junto com o teste focado antes de recorrer a
`git reset --hard`.

---
Histórico loop até salvar:
- 558/621 (baseline inicial) → 559 (hasSystemStartLine) → 561 (invisibleStaffBarlines) → 564 (rptboth) → 565 (DrawVerse) → 572 (Layer.getCurrentClef) = +14 arquivos em 5 commits, loop encerrado a pedido para edição do prompt.
