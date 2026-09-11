/// A ferramenta do lado Dart do snapshot de estado: renderiza pelo mesmo
/// pipeline do harness (`renderSvgForComparison`) com o [SnapshotRecorder]
/// instalado e despeja o estado da árvore depois de cada functor de nível 0 e
/// de cada desenho de página. O lado C++ é `cpp_probe/snapshot.sh` (mesmas
/// opções); o comparador é `tool/snapshot_diff.dart`. Guia:
/// `cpp_probe/snapshot/README.md`.
///
/// Uso (a partir de `verovio_dart/`):
/// ```
/// dart run tool/snapshot.dart [opções] <arquivo.mei | diretório>...
///
///   --nivel=N         0 seq | 1 digest bb,pos (default) | 2 full bb,pos |
///                     3 full bb,pos,link,layout | 4 full all
///   --modo=seq|digest|full   --grupos=bb,pos,link,layout,cache|all
///   --at=<regex>      só despeja os checkpoints cujo "Nome#k" ou "@seq" casa
///   --path=<texto>    --classe=a,b
///   --excluir=a,b     fora das linhas e do hash: `campo`, `classe.campo` ou
///                     `key:<texto>`; soma-se a cpp_probe/snapshot/exclude.list
///   --sem-lista       não aplica cpp_probe/snapshot/exclude.list
///   --saida=<dir>     default ../tmp/snapshot/dart
///   --check-svg       confere que o SVG com o snapshot instalado é idêntico
///                     ao SVG sem ele (o dump não pode mudar o comportamento)
/// ```
///
/// Saída: `<saida>/<família>/<arquivo>.mei.jsonl`.
///
/// Support code for the port — not a port of any C++ file.
library;

import 'dart:io';

import 'package:verovio_dart/src/factory_registry.dart'
    show registerModelClasses;
import 'package:verovio_dart/src/layout/functor.dart' show FunctorBase;
import 'package:verovio_dart/src/rendering/resources.dart' show Resources;
import 'package:verovio_dart/src/testing/svg_compare.dart'
    show renderSvgForComparison;

import 'gen_snapshot_fields.dart' show staleSnapshotFields;
import 'snapshot/recorder.dart';

const String _corpusPrefix = 'test/corpus/';
const String _excludeList = '../cpp_probe/snapshot/exclude.list';

Never _usage([String? error]) {
  if (error != null) stderr.writeln('snapshot: $error');
  stderr.writeln('uso: dart run tool/snapshot.dart [--nivel=0..4] [--modo=..] '
      '[--grupos=..] [--at=..] [--path=..] [--classe=..] [--excluir=..] '
      '[--saida=..] [--check-svg] <arquivo.mei | diretório>...');
  exit(2);
}

void main(List<String> args) {
  int level = 1;
  String? mode;
  String? groups;
  String? at;
  String path = '';
  Set<String> classes = {};
  Set<String> exclude = {};
  String outDir = '../tmp/snapshot/dart';
  bool checkSvg = false;
  bool noList = false;
  final List<String> inputs = [];

  Set<String> commaSet(String v) =>
      v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
  for (final a in args) {
    final int eq = a.indexOf('=');
    final String name = eq < 0 ? a : a.substring(0, eq);
    final String value = eq < 0 ? '' : a.substring(eq + 1);
    switch (name) {
      case '--nivel' || '--level':
        level = int.tryParse(value) ?? -1;
      case '--modo' || '--mode':
        mode = value;
      case '--grupos' || '--groups':
        groups = value;
      case '--at':
        at = value.isEmpty ? null : value;
      case '--path':
        path = value;
      case '--classe' || '--class':
        classes = commaSet(value);
      case '--excluir' || '--exclude':
        exclude = commaSet(value);
      case '--saida' || '--out':
        outDir = value;
      case '--check-svg':
        checkSvg = true;
      case '--sem-lista':
        noList = true;
      case '-h' || '--help':
        _usage();
      default:
        if (a.startsWith('-')) _usage('opção desconhecida: $a');
        inputs.add(a);
    }
  }
  if (inputs.isEmpty) _usage();
  final preset = SnapshotConfig.levels[level];
  if (preset == null) _usage('--nivel vai de 0 a 4');
  mode ??= preset.$1;
  if (!{'seq', 'digest', 'full'}.contains(mode))
    _usage('--modo inválido: $mode');
  final int groupBits;
  try {
    groupBits = SnapshotConfig.parseGroups(groups ?? preset.$2);
  } on FormatException catch (e) {
    _usage(e.message);
  }

  // The generated field emitters must match the manifest (and the C++ side).
  final List<String> stale = staleSnapshotFields();
  if (stale.isNotEmpty) {
    stderr.writeln('snapshot: o código gerado não corresponde a '
        'cpp_probe/snapshot/fields.manifest (${stale.join(', ')}).\n'
        '  Rode antes: dart run tool/gen_snapshot_fields.dart '
        '(e o lado C++ se recompila sozinho no próximo cpp_probe/snapshot.sh)');
    exit(1);
  }

  final List<String> files = [];
  for (final input in inputs) {
    if (FileSystemEntity.isDirectorySync(input)) {
      files.addAll(Directory(input)
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => p.endsWith('.mei'))
          .toList()
        ..sort());
    } else if (File(input).existsSync()) {
      files.add(input);
    } else {
      _usage('entrada não encontrada: $input');
    }
  }

  final config = SnapshotConfig(
    mode: mode,
    groups: groupBits,
    at: at,
    path: path,
    classes: classes,
    exclude: {
      if (!noList) ...SnapshotConfig.readExcludeList(_excludeList),
      ...exclude,
    },
  );

  registerModelClasses();
  Resources.defaultPath = 'assets/data';
  // The harness renders the first file of a process twice (cold pass
  // discarded) so every later render is byte-stable; warm up without the
  // recorder so the cold pass never reaches a dump.
  renderSvgForComparison(files.first);

  int failures = 0;
  for (final String file in files) {
    final String normalized = file.replaceAll('\\', '/');
    final int at = normalized.indexOf(_corpusPrefix);
    final String rel = at >= 0
        ? normalized.substring(at + _corpusPrefix.length)
        : normalized.split('/').last;
    final File out = File('$outDir/$rel.jsonl');
    out.parent.createSync(recursive: true);

    final recorder = SnapshotRecorder(config, out, source: 'test/corpus/$rel');
    String? svg;
    Object? error;
    recorder.install();
    try {
      svg = renderSvgForComparison(file);
    } catch (e) {
      error = e;
    } finally {
      recorder.close();
    }
    if (error != null || svg == null) {
      stdout.writeln('FALHOU  $rel (${error ?? 'loadData devolveu false'})');
      failures++;
      continue;
    }
    String status = '';
    if (checkSvg) {
      assert(FunctorBase.checkpointHook == null);
      final String? clean = renderSvgForComparison(file);
      if (clean == svg) {
        status = '  svg idêntico';
      } else {
        status =
            '  SVG DIFERENTE sem o snapshot — o dump mudou o comportamento';
        failures++;
      }
    }
    stdout.writeln('${recorder.checkpoints} checkpoints  ${out.path}$status');
  }
  if (failures > 0) {
    stderr.writeln('snapshot: $failures falha(s)');
    exit(1);
  }
}
