# 04e — view.dart: remover ignore_for_file e limpar imports

- Remover `// ignore_for_file: unused_shown_name`
- Remover `show` não usados: smuflE550, smuflE552, Fontsizeterm, MordentlogForm, RepeatmarklogFunc, StemdirectionBasic, TurnlogForm
- Adicionar DivlinelogForm, EpisemavisForm, Eventrel, BeamDrawingInterface aos imports
- Adicionar `View.convertHalign` consolidado
- Mudar `misc_elements_gen` import para sem `show` para evitar unused_shown_name em part

Verificação: tool/task_check.sh view.dart
