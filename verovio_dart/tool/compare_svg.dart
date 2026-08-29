/// Phase 5 SVG comparison harness CLI (task 05-00).
///
/// Sweeps the corpus (`test/corpus/**.mei`), renders each file through the
/// Phase-5 hook (`renderSvgForComparison` — a stub until task 05-12) and
/// compares the result against the C++ golden SVGs (`test/golden/cpp/**.svg`)
/// in structural and/or numeric mode, aggregating everything into a markdown
/// report. The two deliberately non-UTF-8 corpus files
/// (`dir/dir-011.mei`, `dir/dir-012.mei`) are skipped with a reason.
///
/// This tool is support code for the port, not a port of any C++ file. The
/// comparison logic lives in `package:verovio_dart/src/testing/svg_compare.dart`
/// (shared with `test/svg_golden_test.dart`).
///
/// Usage (from verovio_dart/):
/// ```
/// dart run tool/compare_svg.dart [caminho]      # arquivo ou diretório sob test/corpus
/// dart run tool/compare_svg.dart --all          # os 623
/// dart run tool/compare_svg.dart --mode=structural|numeric|both   (default: both)
/// dart run tool/compare_svg.dart --epsilon=0    # tolerância numérica (default 0)
/// dart run tool/compare_svg.dart --report=tool/SVG_VALIDATION.md
/// ```
///
/// Auxiliary modes used to prove the comparator itself works (results are
/// also recorded in the report's "Auto-teste" section):
/// ```
/// dart run tool/compare_svg.dart --selftest=<arquivo.svg>   # o arquivo contra si mesmo
/// dart run tool/compare_svg.dart --a=<x.svg> --b=<y.svg>    # dois SVGs quaisquer
/// ```
library;

import 'dart:io';

import 'package:verovio_dart/src/testing/svg_compare.dart';
import 'package:xml/xml.dart' show XmlException;

const String corpusRoot = 'test/corpus';
const String goldenRoot = 'test/golden/cpp';
const String defaultReport = 'tool/SVG_VALIDATION.md';

/// The two corpus files that are deliberately non-UTF-8 (CLAUDE.md gotchas);
/// paths relative to [corpusRoot].
const Set<String> kNonUtf8CorpusFiles = {'dir/dir-011.mei', 'dir/dir-012.mei'};

const String _usage = '''
Uso (a partir de verovio_dart/):
  dart run tool/compare_svg.dart [caminho]     # arquivo .mei ou diretório sob test/corpus
  dart run tool/compare_svg.dart --all         # todo o corpus
Opções:
  --mode=structural|numeric|both   (default: both)
  --epsilon=<número>               tolerância numérica (default: 0)
  --report=<arquivo.md>            relatório de saída (default: tool/SVG_VALIDATION.md)
  --selftest=<arquivo.svg>         compara o SVG com ele mesmo (prova do comparador)
  --a=<x.svg> --b=<y.svg>          compara dois SVGs diretamente (prova de mutação)
''';

/// Outcome of one corpus file in the sweep.
enum _Status {
  clean,
  divergent,
  noRender,
  falha,
  skipped,
  noGolden,
  parseError
}

class _FileOutcome {
  _FileOutcome(this.rel, this.category, this.status);

  final String rel;
  final String category;
  _Status status;

  bool structuralClean = false;
  bool numericClean = false;
  int structuralCount = 0;
  int numericCount = 0;
  double maxDeviation = 0;
  String? firstStructural;
  String? firstNumeric;
  String? falhaTipo;
  String? falhaDetalhe;
}

void main(List<String> args) {
  var all = false;
  var mode = 'both';
  var epsilon = 0.0;
  String? reportPath;
  String? positional;
  String? pathA;
  String? pathB;
  String? selftest;

  for (final arg in args) {
    if (arg == '--all') {
      all = true;
    } else if (arg == '--help' || arg == '-h') {
      stdout.writeln(_usage);
      exit(0);
    } else if (arg.startsWith('--mode=')) {
      mode = arg.substring('--mode='.length);
    } else if (arg.startsWith('--epsilon=')) {
      epsilon = double.tryParse(arg.substring('--epsilon='.length)) ?? 0;
    } else if (arg.startsWith('--report=')) {
      reportPath = arg.substring('--report='.length);
    } else if (arg.startsWith('--a=')) {
      pathA = arg.substring('--a='.length);
    } else if (arg.startsWith('--b=')) {
      pathB = arg.substring('--b='.length);
    } else if (arg.startsWith('--selftest=')) {
      selftest = arg.substring('--selftest='.length);
    } else if (!arg.startsWith('--')) {
      positional = arg;
    } else {
      stderr.writeln('Argumento desconhecido: $arg');
      stdout.writeln(_usage);
      exit(2);
    }
  }

  if (mode != 'structural' && mode != 'numeric' && mode != 'both') {
    stderr.writeln('--mode inválido: $mode (structural|numeric|both)');
    exit(2);
  }

  // Auxiliary proof modes first: they record their outcome in the report's
  // auto-test section and exit.
  if (selftest != null) {
    _runPair(selftest, selftest, epsilon, mode, reportPath, selfCompare: true);
    return;
  }
  if (pathA != null && pathB != null) {
    _runPair(pathA, pathB, epsilon, mode, reportPath);
    return;
  }
  if (pathA != null || pathB != null) {
    stderr.writeln('--a e --b devem vir juntos');
    exit(2);
  }

  if (!all && positional == null) {
    stdout.writeln(_usage);
    exit(2);
  }

  _runSweep(
      all: all,
      positional: positional,
      mode: mode,
      epsilon: epsilon,
      reportPath: reportPath);
}

// ---------------------------------------------------------------------------
// Pair / self-test modes
// ---------------------------------------------------------------------------

void _runPair(
    String pathA, String pathB, double epsilon, String mode, String? reportPath,
    {bool selfCompare = false}) {
  final runNumeric = mode != 'structural';
  final a = File(pathA).readAsStringSync();
  final b = File(pathB).readAsStringSync();
  final result = SvgComparator(epsilon: epsilon)
      .compare(dartSvg: a, goldenSvg: b, runNumeric: runNumeric);

  final label = selfCompare ? 'auto-teste' : 'comparação';
  stdout.writeln('$label: $pathA${selfCompare ? '' : ' × $pathB'}');
  stdout.writeln(
      '  Estrutural: ${result.structuralDivergenceCount} divergência(s)'
      '${result.structuralClean ? ' — LIMPO' : ''}');
  if (runNumeric) {
    stdout.writeln('  Numérico (eps=$epsilon): '
        '${result.numericDivergenceCount} divergência(s), '
        'maior desvio ${result.maxNumericDeviation}'
        '${result.numericClean ? ' — LIMPO' : ''}');
  }
  for (final d in result.structuralDivergences.take(5)) {
    stdout.writeln('  estrutural: $d');
  }
  for (final d in result.numericDivergences.take(5)) {
    stdout.writeln('  numérico: $d');
  }

  if (reportPath != null) {
    _recordAutoTest(
        reportPath,
        selfCompare,
        pathA,
        pathB,
        epsilon,
        mode,
        result.structuralDivergenceCount,
        result.numericDivergenceCount,
        result.maxNumericDeviation,
        runNumeric);
  }
}

/// Records the last self-test / pair-comparison outcome in the report, so the
/// proof of the comparator's health travels with the living report.
void _recordAutoTest(
    String reportPath,
    bool selfCompare,
    String pathA,
    String pathB,
    double epsilon,
    String mode,
    int structuralCount,
    int numericCount,
    double maxDeviation,
    bool runNumeric) {
  final file = File(reportPath);
  const start = '<!-- autotest:start -->';
  const end = '<!-- autotest:end -->';
  final now = DateTime.now().toIso8601String().substring(0, 19);
  final command = selfCompare
      ? 'dart run tool/compare_svg.dart --selftest=$pathA'
      : 'dart run tool/compare_svg.dart --a=$pathA --b=$pathB';
  final section = '''
$start
## Auto-teste do comparador

Comando: `$command` (eps=$epsilon, modo=$mode, em $now)

- Estrutural: $structuralCount divergência(s)
- Numérico: ${runNumeric ? '$numericCount divergência(s), maior desvio $maxDeviation' : 'não executado'}
$end''';

  final existing =
      file.existsSync() ? file.readAsStringSync() : '# SVG_VALIDATION\n';
  final open = existing.indexOf(start);
  final close = existing.indexOf(end);
  String updated;
  if (open >= 0 && close > open) {
    updated =
        '${existing.substring(0, open)}$section${existing.substring(close + end.length)}';
  } else {
    updated = '${existing.trimRight()}\n\n$section\n';
  }
  file.writeAsStringSync(updated);
}

// ---------------------------------------------------------------------------
// Sweep mode
// ---------------------------------------------------------------------------

void _runSweep(
    {required bool all,
    required String? positional,
    required String mode,
    required double epsilon,
    String? reportPath}) {
  final corpusDir = Directory(corpusRoot);
  if (!corpusDir.existsSync()) {
    stderr
        .writeln('Corpus não encontrado: $corpusRoot (rode de verovio_dart/)');
    exit(2);
  }

  final List<String> relFiles;
  if (all) {
    relFiles = _listCorpus(corpusRoot);
  } else {
    final path = _corpusRelativePath(positional!);
    if (path == null) {
      stderr.writeln('O caminho deve estar sob $corpusRoot/: $positional');
      exit(2);
    }
    if (File(positional).existsSync()) {
      if (!path.endsWith('.mei')) {
        stderr.writeln('O arquivo deve ser um .mei: $positional');
        exit(2);
      }
      relFiles = [path];
    } else if (Directory(positional).existsSync()) {
      relFiles = _listCorpus(corpusRoot)
          .where((rel) => rel.startsWith('$path/'))
          .toList();
      if (relFiles.isEmpty) {
        stderr.writeln('Nenhum .mei sob $positional');
        exit(2);
      }
    } else {
      stderr.writeln('Caminho não encontrado: $positional');
      exit(2);
    }
  }

  final runNumeric = mode != 'structural';
  final comparator = SvgComparator(epsilon: epsilon);
  final outcomes = <_FileOutcome>[];
  var noGolden = 0;

  for (final rel in relFiles) {
    final category =
        rel.contains('/') ? rel.substring(0, rel.indexOf('/')) : '.';
    if (kNonUtf8CorpusFiles.contains(rel)) {
      outcomes.add(_FileOutcome(rel, category, _Status.skipped));
      continue;
    }
    final meiPath = '$corpusRoot/$rel';
    final goldenPath = '$goldenRoot/${rel.substring(0, rel.length - 4)}.svg';
    final goldenFile = File(goldenPath);
    if (!goldenFile.existsSync()) {
      noGolden++;
      outcomes.add(_FileOutcome(rel, category, _Status.noGolden));
      continue;
    }

    String? dartSvg;
    try {
      dartSvg = renderSvgForComparison(meiPath);
    } catch (e) {
      final falha = _FileOutcome(rel, category, _Status.falha);
      falha.falhaTipo = e.runtimeType.toString();
      falha.falhaDetalhe = e.toString();
      falha.firstStructural = '${e.runtimeType}: $e';
      outcomes.add(falha);
      continue;
    }
    if (dartSvg == null) {
      outcomes.add(_FileOutcome(rel, category, _Status.noRender));
      continue;
    }

    final outcome = _FileOutcome(rel, category, _Status.divergent);
    try {
      final result = comparator.compare(
          dartSvg: dartSvg,
          goldenSvg: goldenFile.readAsStringSync(),
          runNumeric: runNumeric);
      outcome.structuralClean = result.structuralClean;
      outcome.numericClean = result.numericClean;
      outcome.structuralCount = result.structuralDivergenceCount;
      outcome.numericCount = result.numericDivergenceCount;
      outcome.maxDeviation = result.maxNumericDeviation;
      outcome.firstStructural = result.structuralDivergences.isEmpty
          ? null
          : result.structuralDivergences.first.toString();
      outcome.firstNumeric = result.numericDivergences.isEmpty
          ? null
          : result.numericDivergences.first.toString();
      outcome.status =
          (result.structuralClean && (!runNumeric || result.numericClean))
              ? _Status.clean
              : _Status.divergent;
    } on XmlException catch (e) {
      outcome.status = _Status.parseError;
      outcome.firstStructural = 'XML inválido: $e';
    }
    outcomes.add(outcome);
  }

  final structuralClean = outcomes.where((o) => o.structuralClean).length;
  final numericClean = outcomes.where((o) => o.numericClean).length;
  final total = relFiles.length;
  final noRender = outcomes.where((o) => o.status == _Status.noRender).length;
  final falhas = outcomes.where((o) => o.status == _Status.falha).length;
  final divergentes =
      outcomes.where((o) => o.status == _Status.divergent).length;
  final skipped = outcomes.where((o) => o.status == _Status.skipped).length;
  final parseErrors =
      outcomes.where((o) => o.status == _Status.parseError).length;

  // Console summary.
  final modeLabel = mode == 'both'
      ? ''
      : (mode == 'structural' ? ' (modo estrutural)' : ' (modo numérico)');
  stdout.writeln('compare_svg$modeLabel — $total arquivo(s), eps=$epsilon');
  stdout.writeln('  Estrutural: $structuralClean/$total limpos');
  if (runNumeric) {
    stdout.writeln('  Numérico (eps=$epsilon): $numericClean/$total limpos');
  }
  stdout.writeln(
      '  Divergentes: $divergentes, falhas: $falhas, sem render: $noRender, '
      'pulados (não-UTF-8): $skipped'
      '${noGolden > 0 ? ', sem golden: $noGolden' : ''}'
      '${parseErrors > 0 ? ', erro de parse: $parseErrors' : ''}');
  if (total == 1) {
    final only = outcomes.single;
    if (only.status == _Status.noRender) {
      stdout
          .writeln('$corpusRoot/${only.rel}: sem renderização Dart disponível '
              '(renderSvgForComparison => null) — nada a comparar contra '
              '$goldenRoot/${only.rel.substring(0, only.rel.length - 4)}.svg.');
    } else if (only.status == _Status.falha) {
      stdout.writeln(
          '$corpusRoot/${only.rel}: falha (${only.falhaTipo}): ${only.falhaDetalhe}');
    } else if (only.status == _Status.skipped) {
      stdout.writeln('$corpusRoot/${only.rel}: pulado (não-UTF-8).');
    }
  }

  final path = reportPath ?? (positional == null ? defaultReport : null);
  if (path != null) {
    _writeReport(path, outcomes, total, structuralClean, numericClean, mode,
        epsilon, runNumeric, noRender, skipped, noGolden, parseErrors,
        falhas: falhas, divergentes: divergentes);
    stdout.writeln('  Relatório: $path');
  }
}

List<String> _listCorpus(String root) {
  final files = <String>[];
  for (final entity in Directory(root).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.mei')) {
      files.add(_relativeToCorpus(entity.path));
    }
  }
  files.sort();
  return files;
}

/// Normalizes [path] to a corpus-relative path ('note/note-001.mei'), or
/// returns null when it is not under [corpusRoot] (the corpus root itself
/// maps to '').
String? _corpusRelativePath(String path) {
  final normalized = path.replaceAll('\\', '/');
  while (normalized.endsWith('/')) {
    return normalized.substring(0, normalized.length - 1);
  }
  if (normalized == corpusRoot) return '';
  if (!normalized.startsWith('$corpusRoot/')) return null;
  return _relativeToCorpus(normalized);
}

String _relativeToCorpus(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.startsWith('$corpusRoot/')
      ? normalized.substring(corpusRoot.length + 1)
      : normalized;
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

void _writeReport(
    String path,
    List<_FileOutcome> outcomes,
    int total,
    int structuralClean,
    int numericClean,
    String mode,
    double epsilon,
    bool runNumeric,
    int noRender,
    int skipped,
    int noGolden,
    int parseErrors,
    {int falhas = 0,
    int divergentes = 0}) {
  final now = DateTime.now().toIso8601String().substring(0, 10);
  final buffer = StringBuffer();

  // The two summary lines must stay within the first 5 lines of the file.
  buffer.writeln('# SVG_VALIDATION — comparação de SVG (harness da Fase 5)');
  buffer.writeln();
  buffer.writeln('Estrutural: $structuralClean/$total limpos');
  buffer.writeln(runNumeric
      ? 'Numérico (eps=$epsilon): $numericClean/$total limpos'
      : 'Numérico: não executado (modo estrutural)');
  buffer.writeln();
  buffer.writeln('Gerado em $now por `dart run tool/compare_svg.dart` '
      '(modo: $mode, epsilon: $epsilon).');
  buffer.writeln();
  buffer.writeln('- Divergentes: $divergentes');
  buffer.writeln('- Falhas (exceção durante renderização): $falhas');
  buffer.writeln(
      '- Sem renderização Dart disponível (stub `renderSvgForComparison` '
      'da Fase 5): $noRender');
  buffer.writeln('- Pulados por não serem UTF-8: $skipped '
      '(${kNonUtf8CorpusFiles.join(', ')})');
  if (noGolden > 0) buffer.writeln('- Sem golden correspondente: $noGolden');
  if (parseErrors > 0) {
    buffer.writeln('- Erro de parse do SVG: $parseErrors');
  }
  buffer.writeln();

  // Per-category table.
  final categories = <String, List<_FileOutcome>>{};
  for (final outcome in outcomes) {
    categories.putIfAbsent(outcome.category, () => []).add(outcome);
  }
  final names = categories.keys.toList()..sort();
  buffer.writeln('## Por categoria (${names.length} categorias)');
  buffer.writeln();
  buffer.writeln(
      '| Categoria | Estrutural limpos | Numérico limpos | Divergentes | Falhas | Sem render | Pulados | Total |');
  buffer.writeln('|---|---|---|---|---|---|---|---|');
  for (final name in names) {
    final list = categories[name]!;
    final cleanS = list.where((o) => o.structuralClean).length;
    final cleanN = list.where((o) => o.numericClean).length;
    final div = list.where((o) => o.status == _Status.divergent).length;
    final fal = list.where((o) => o.status == _Status.falha).length;
    final nr = list.where((o) => o.status == _Status.noRender).length;
    final sk = list.where((o) => o.status == _Status.skipped).length;
    buffer.writeln(
        '| $name | $cleanS | $cleanN | $div | $fal | $nr | $sk | ${list.length} |');
  }
  buffer.writeln();

  // Falhas section.
  final falhasList = outcomes.where((o) => o.status == _Status.falha).toList()
    ..sort((a, b) => a.rel.compareTo(b.rel));
  if (falhasList.isNotEmpty) {
    buffer.writeln('## Falhas (exceções durante renderização)');
    buffer.writeln();
    buffer.writeln('| Arquivo | Tipo da exceção | Detalhe |');
    buffer.writeln('|---|---|---|');
    for (final f in falhasList) {
      buffer.writeln(
          '| ${f.rel} | ${_cell(f.falhaTipo)} | ${_cell(f.falhaDetalhe)} |');
    }
    buffer.writeln();
  }

  // Top structural divergences.
  final structural = outcomes.where((o) => o.structuralCount > 0).toList()
    ..sort((a, b) {
      final byCount = b.structuralCount.compareTo(a.structuralCount);
      return byCount != 0 ? byCount : a.rel.compareTo(b.rel);
    });
  buffer.writeln('## Top divergências estruturais '
      '(${structural.length} arquivo(s) com divergências; até 30 listados)');
  buffer.writeln();
  buffer.writeln('| Arquivo | Divergências | Primeira divergência |');
  buffer.writeln('|---|---|---|');
  for (final outcome in structural.take(30)) {
    buffer.writeln('| ${outcome.rel} | ${outcome.structuralCount} | '
        '${_cell(outcome.firstStructural)} |');
  }
  if (structural.isEmpty) {
    buffer.writeln('| (nenhum) | | |');
  }
  buffer.writeln();

  // Top numeric deviations.
  if (runNumeric) {
    final numeric = outcomes
        .where((o) =>
            o.status == _Status.divergent &&
            (o.maxDeviation > 0 || o.numericCount > 0))
        .toList()
      ..sort((a, b) {
        final byDev = b.maxDeviation.compareTo(a.maxDeviation);
        return byDev != 0 ? byDev : a.rel.compareTo(b.rel);
      });
    buffer.writeln('## Maiores desvios numéricos (até 10 listados)');
    buffer.writeln();
    buffer.writeln('| Arquivo | Maior desvio | Divergências numéricas | '
        'Primeira divergência |');
    buffer.writeln('|---|---|---|---|');
    for (final outcome in numeric.take(10)) {
      buffer.writeln('| ${outcome.rel} | ${outcome.maxDeviation} | '
          '${outcome.numericCount} | ${_cell(outcome.firstNumeric)} |');
    }
    if (numeric.isEmpty) {
      buffer.writeln('| (nenhum) | | | |');
    }
    buffer.writeln();
  }

  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());
}

String _cell(String? text) {
  if (text == null) return '';
  return text.replaceAll('|', '\\|').replaceAll('\n', ' ');
}
