/// Clusters every numeric divergence in the corpus by its probable cause.
///
/// `tool/compare_svg.dart` answers "how far is each file from the golden".
/// This tool answers the question the fidelity loop actually needs: **which
/// single defect, if fixed, unblocks the most files**. It reads the two SVG
/// trees that `compare_svg.dart --all` already dumps —
/// `test/golden/cpp/<rel>.svg` (the C++ reference) and
/// `test/golden/dart/<rel>.svg` (what the port produces) — walks them in
/// lockstep, and groups every differing number by
/// `(nearest ancestor @class, element tag, attribute, delta)`.
///
/// The grouping matters because the divergences are not independent. A corpus
/// sweep run on 2026-09-04 found 473 numerically-divergent files carrying
/// ~117k differing numbers, but a median of only **19 distinct deltas per
/// file** — and the deltas repeat across files (27% of them are exact
/// multiples of 9, the tenth of a staff unit). Those are a few dozen shared
/// defects seen from 473 angles, not 473 bugs. Ranking by *files affected*
/// puts the shared ones on top.
///
/// This is support code for the port, not a port of any C++ file. It shares
/// [kNumericAttributes] with the comparator so both agree on which attributes
/// carry geometry.
///
/// **Counting deviation from `compare_svg.dart`** (deliberate): the comparator
/// stops at the first differing number within an attribute
/// (`_walkNumeric` breaks after one hit), so its totals count divergent
/// *(element, attribute)* pairs. This tool counts every differing *number*,
/// because the delta itself is the signature being clustered — a `points`
/// attribute whose eight numbers are all off by -208 is eight pieces of
/// evidence for one cause. Expect this tool's totals to exceed the report's.
///
/// Usage (from verovio_dart/):
/// ```
/// dart run tool/cluster_deltas.dart                  # ranking + tool/DELTA_CLUSTERS.md
/// dart run tool/cluster_deltas.dart --top=40         # more rows
/// dart run tool/cluster_deltas.dart --class=stem     # drill into one class, list files
/// dart run tool/cluster_deltas.dart --delta=-208     # which files carry this exact delta
/// dart run tool/cluster_deltas.dart --report=<path>  # default tool/DELTA_CLUSTERS.md
/// ```
library;

import 'dart:io';

import 'package:verovio_dart/src/testing/svg_compare.dart'
    show kNumericAttributes;
import 'package:xml/xml.dart';

const String cppGoldenRoot = 'test/golden/cpp';
const String dartGoldenRoot = 'test/golden/dart';
const String defaultReport = 'tool/DELTA_CLUSTERS.md';

const String _usage = '''
Uso (a partir de verovio_dart/):
  dart run tool/cluster_deltas.dart              # ranking geral + relatório
Opções:
  --top=<n>            linhas por ranking (default: 25)
  --class=<nome>       detalha uma classe (lista arquivos afetados)
  --delta=<número>     detalha um delta exato (lista arquivos afetados)
  --report=<arquivo>   relatório de saída (default: $defaultReport)
  --no-report          só console
''';

void main(List<String> args) {
  var top = 25;
  String? drillClass;
  double? drillDelta;
  String? reportPath = defaultReport;

  for (final arg in args) {
    if (arg == '--help' || arg == '-h') {
      stdout.write(_usage);
      return;
    } else if (arg.startsWith('--top=')) {
      top = int.tryParse(arg.substring('--top='.length)) ?? top;
    } else if (arg.startsWith('--class=')) {
      drillClass = arg.substring('--class='.length);
    } else if (arg.startsWith('--delta=')) {
      drillDelta = double.tryParse(arg.substring('--delta='.length));
      if (drillDelta == null) {
        stderr.writeln('--delta precisa de um número: $arg');
        exit(2);
      }
    } else if (arg.startsWith('--report=')) {
      reportPath = arg.substring('--report='.length);
    } else if (arg == '--no-report') {
      reportPath = null;
    } else {
      stderr.writeln('Argumento desconhecido: $arg');
      stderr.write(_usage);
      exit(2);
    }
  }

  final cppRoot = Directory(cppGoldenRoot);
  final dartRoot = Directory(dartGoldenRoot);
  if (!cppRoot.existsSync()) {
    stderr.writeln('Não encontrado: $cppGoldenRoot (rode de verovio_dart/)');
    exit(2);
  }
  if (!dartRoot.existsSync()) {
    stderr.writeln('Não encontrado: $dartGoldenRoot — rode antes '
        '`dart run tool/compare_svg.dart --all` para dumpar o lado Dart.');
    exit(2);
  }

  final analysis = _analyze();
  if (analysis.pairs == 0) {
    stderr.writeln('Nenhum par golden/dart comparável sob $dartGoldenRoot.');
    exit(2);
  }

  _printConsole(analysis, top, drillClass, drillDelta);
  if (reportPath != null) {
    _writeReport(reportPath, analysis, top);
    stdout.writeln('  Relatório: $reportPath');
  }
}

// ---------------------------------------------------------------------------
// Walk
// ---------------------------------------------------------------------------

/// One clustering key. [cls] is the nearest ancestor `@class` (first token —
/// `ending systemMilestone` clusters as `ending`), which is what names the
/// drawing routine responsible; [tag] and [attr] localize it further.
class _Key {
  const _Key(this.cls, this.tag, this.attr);

  final String cls;
  final String tag;
  final String attr;

  @override
  bool operator ==(Object other) =>
      other is _Key && other.cls == cls && other.tag == tag && other.attr == attr;

  @override
  int get hashCode => Object.hash(cls, tag, attr);

  @override
  String toString() => '$cls/$tag @$attr';
}

/// Aggregate for one key: how many numbers differ, in how many distinct files,
/// and the histogram of deltas behind it.
class _Agg {
  int count = 0;
  final Set<String> files = <String>{};
  final Map<double, int> deltas = <double, int>{};
  final Map<double, Set<String>> deltaFiles = <double, Set<String>>{};

  void add(String file, double delta) {
    count++;
    files.add(file);
    deltas[delta] = (deltas[delta] ?? 0) + 1;
    deltaFiles.putIfAbsent(delta, () => <String>{}).add(file);
  }

  /// Deltas ordered by how many files carry them — a delta seen in many files
  /// is a shared rule, one seen in a single file is that file's own accident.
  List<MapEntry<double, int>> topDeltas(int n) {
    final entries = deltas.entries.toList()
      ..sort((a, b) {
        final byFiles =
            deltaFiles[b.key]!.length.compareTo(deltaFiles[a.key]!.length);
        return byFiles != 0 ? byFiles : b.value.compareTo(a.value);
      });
    return entries.take(n).toList();
  }
}

class _Analysis {
  int pairs = 0;
  int divergentFiles = 0;
  int totalDivergences = 0;
  int prunedSubtrees = 0;
  final Map<_Key, _Agg> byKey = <_Key, _Agg>{};

  /// Where each file's *first* divergence lands, in document order. The SVG
  /// emits the staff rules before anything else in a measure, so the first
  /// divergence is systematically the most downstream symptom, not the cause —
  /// this histogram makes that masking visible instead of letting it steer the
  /// investigation.
  final Map<String, int> firstDivergenceByClass = <String, int>{};

  /// Files ranked by how few numbers separate them from clean.
  final List<MapEntry<String, int>> perFile = <MapEntry<String, int>>[];
}

_Analysis _analyze() {
  final analysis = _Analysis();
  final dartFiles = Directory(dartGoldenRoot)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.svg'))
      .map((f) => f.path.replaceAll('\\', '/'))
      .toList()
    ..sort();

  for (final dartPath in dartFiles) {
    final rel = dartPath.substring(dartGoldenRoot.length + 1);
    final cppFile = File('$cppGoldenRoot/$rel');
    if (!cppFile.existsSync()) continue;

    final XmlElement cppRoot;
    final XmlElement dartRoot;
    try {
      cppRoot = XmlDocument.parse(cppFile.readAsStringSync()).rootElement;
      dartRoot = XmlDocument.parse(File(dartPath).readAsStringSync()).rootElement;
    } on XmlException {
      continue;
    }
    analysis.pairs++;

    final label = rel.substring(0, rel.length - 4);
    var fileCount = 0;
    String? firstClass;

    void record(String cls, String tag, String attr, double delta) {
      fileCount++;
      firstClass ??= cls;
      analysis.totalDivergences++;
      analysis.byKey
          .putIfAbsent(_Key(cls, tag, attr), () => _Agg())
          .add(label, delta);
    }

    _walk(cppRoot, dartRoot, null, record, analysis);

    if (fileCount > 0) {
      analysis.divergentFiles++;
      analysis.perFile.add(MapEntry(label, fileCount));
      final cls = firstClass ?? '(sem classe)';
      analysis.firstDivergenceByClass[cls] =
          (analysis.firstDivergenceByClass[cls] ?? 0) + 1;
    }
  }

  analysis.perFile.sort((a, b) {
    final byCount = a.value.compareTo(b.value);
    return byCount != 0 ? byCount : a.key.compareTo(b.key);
  });
  return analysis;
}

final RegExp _numberPattern =
    RegExp(r'[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?');

List<double> _numbers(String value) {
  final out = <double>[];
  for (final match in _numberPattern.allMatches(value)) {
    final parsed = double.tryParse(match.group(0)!);
    if (parsed != null) out.add(parsed);
  }
  return out;
}

/// Walks the C++ and Dart trees in lockstep. Mirrors the comparator's pruning
/// rule: once the shapes disagree (different tag, different child count) the
/// numbers below are no longer paired with their counterparts, so comparing
/// them would manufacture deltas that mean nothing. Those subtrees are counted
/// in [_Analysis.prunedSubtrees] rather than silently dropped.
void _walk(
    XmlElement cpp,
    XmlElement dart,
    String? inheritedClass,
    void Function(String cls, String tag, String attr, double delta) record,
    _Analysis analysis) {
  if (cpp.name.qualified != dart.name.qualified) {
    analysis.prunedSubtrees++;
    return;
  }

  final own = cpp.getAttribute('class');
  final cls = (own != null && own.trim().isNotEmpty)
      ? own.trim().split(RegExp(r'\s+')).first
      : inheritedClass;
  final tag = cpp.name.qualified;

  for (final attr in kNumericAttributes) {
    final cv = cpp.getAttribute(attr);
    final dv = dart.getAttribute(attr);
    if (cv == null && dv == null) continue;
    if (cv == null || dv == null) continue;
    final cn = _numbers(cv);
    final dn = _numbers(dv);
    if (cn.length != dn.length) continue;
    for (var i = 0; i < cn.length; i++) {
      if (cn[i] != dn[i]) {
        // Delta is Dart minus C++: the correction the port still owes.
        final delta = double.parse((dn[i] - cn[i]).toStringAsFixed(3));
        record(cls ?? '(sem classe)', tag, attr, delta);
      }
    }
  }

  final cppKids = cpp.childElements.toList();
  final dartKids = dart.childElements.toList();
  if (cppKids.length != dartKids.length) {
    analysis.prunedSubtrees++;
    return;
  }
  for (var i = 0; i < cppKids.length; i++) {
    _walk(cppKids[i], dartKids[i], cls, record, analysis);
  }
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

List<MapEntry<_Key, _Agg>> _rankByReach(Map<_Key, _Agg> byKey) {
  final entries = byKey.entries.toList()
    ..sort((a, b) {
      final byFiles = b.value.files.length.compareTo(a.value.files.length);
      if (byFiles != 0) return byFiles;
      final byCount = b.value.count.compareTo(a.value.count);
      return byCount != 0 ? byCount : a.key.toString().compareTo(b.key.toString());
    });
  return entries;
}

/// Deltas ranked across all keys: the same delta showing up under several
/// classes usually means one upstream coordinate is wrong and everything
/// downstream inherited it.
List<MapEntry<double, Set<String>>> _rankDeltas(Map<_Key, _Agg> byKey) {
  final merged = <double, Set<String>>{};
  for (final agg in byKey.values) {
    agg.deltaFiles.forEach((delta, files) {
      merged.putIfAbsent(delta, () => <String>{}).addAll(files);
    });
  }
  final entries = merged.entries.toList()
    ..sort((a, b) {
      final byFiles = b.value.length.compareTo(a.value.length);
      return byFiles != 0 ? byFiles : a.key.compareTo(b.key);
    });
  return entries;
}

void _printConsole(
    _Analysis a, int top, String? drillClass, double? drillDelta) {
  stdout.writeln('cluster_deltas — ${a.pairs} par(es) golden/dart, '
      '${a.divergentFiles} com divergência numérica');
  stdout.writeln('  Divergências (nível de número): ${a.totalDivergences}');
  stdout.writeln('  Assinaturas (classe/tag @atributo): ${a.byKey.length}');
  if (a.prunedSubtrees > 0) {
    stdout.writeln('  Subárvores podadas por divergência estrutural: '
        '${a.prunedSubtrees} (números abaixo delas não são comparáveis)');
  }

  if (drillClass != null) {
    _printDrillClass(a, drillClass, top);
    return;
  }
  if (drillDelta != null) {
    _printDrillDelta(a, drillDelta, top);
    return;
  }

  stdout.writeln();
  stdout.writeln('== Ranking por alcance (arquivos destravados) ==');
  stdout.writeln(
      '${'arq'.padLeft(5)} ${'divs'.padLeft(7)}  assinatura                         deltas mais comuns');
  for (final e in _rankByReach(a.byKey).take(top)) {
    final deltas = e.value
        .topDeltas(4)
        .map((d) => '${_fmt(d.key)}×${e.value.deltaFiles[d.key]!.length}')
        .join(' ');
    stdout.writeln('${e.value.files.length.toString().padLeft(5)} '
        '${e.value.count.toString().padLeft(7)}  '
        '${e.key.toString().padRight(34)} $deltas');
  }

  stdout.writeln();
  stdout.writeln('== Deltas mais compartilhados (todos os arquivos) ==');
  for (final e in _rankDeltas(a.byKey).take(top)) {
    stdout.writeln('${e.value.length.toString().padLeft(5)} arquivos  '
        'delta ${_fmt(e.key)}');
  }

  stdout.writeln();
  stdout.writeln('== Onde cai a PRIMEIRA divergência de cada arquivo ==');
  stdout.writeln('   (sintoma mais a jusante, não a causa — ver doc do tool)');
  final firsts = a.firstDivergenceByClass.entries.toList()
    ..sort((x, y) => y.value.compareTo(x.value));
  for (final e in firsts.take(10)) {
    stdout.writeln('${e.value.toString().padLeft(5)} arquivos  ${e.key}');
  }

  stdout.writeln();
  stdout.writeln('== Fila de menor custo (menos números até o limpo) ==');
  for (final e in a.perFile.take(top)) {
    stdout.writeln('${e.value.toString().padLeft(5)} divs  ${e.key}');
  }
}

void _printDrillClass(_Analysis a, String cls, int top) {
  final keys = a.byKey.entries.where((e) => e.key.cls == cls).toList();
  if (keys.isEmpty) {
    stdout.writeln('\nNenhuma divergência sob a classe "$cls".');
    final available = a.byKey.keys.map((k) => k.cls).toSet().toList()..sort();
    stdout.writeln('Classes disponíveis: ${available.join(', ')}');
    return;
  }
  final files = <String>{};
  for (final e in keys) {
    files.addAll(e.value.files);
  }
  stdout.writeln('\n== Classe "$cls" — ${files.length} arquivo(s) afetado(s) ==');
  for (final e in keys
    ..sort((x, y) => y.value.count.compareTo(x.value.count))) {
    stdout.writeln('  ${e.key} — ${e.value.count} divs em '
        '${e.value.files.length} arquivos');
    for (final d in e.value.topDeltas(8)) {
      stdout.writeln('      delta ${_fmt(d.key).padRight(12)} '
          '${d.value.toString().padLeft(6)} ocorrências em '
          '${e.value.deltaFiles[d.key]!.length} arquivos');
    }
  }
  final sorted = files.toList()..sort();
  stdout.writeln('\n  Arquivos (${sorted.length}):');
  for (final f in sorted.take(top)) {
    stdout.writeln('    $f');
  }
  if (sorted.length > top) {
    stdout.writeln('    … e mais ${sorted.length - top} (use --top=)');
  }
}

void _printDrillDelta(_Analysis a, double delta, int top) {
  final hits = <_Key, int>{};
  final files = <String>{};
  a.byKey.forEach((key, agg) {
    final n = agg.deltas[delta];
    if (n != null) {
      hits[key] = n;
      files.addAll(agg.deltaFiles[delta]!);
    }
  });
  if (hits.isEmpty) {
    stdout.writeln('\nNenhuma divergência com delta exatamente ${_fmt(delta)}.');
    return;
  }
  stdout.writeln('\n== Delta ${_fmt(delta)} — ${files.length} arquivo(s), '
      '${hits.length} assinatura(s) ==');
  final sortedHits = hits.entries.toList()
    ..sort((x, y) => y.value.compareTo(x.value));
  for (final e in sortedHits.take(top)) {
    stdout.writeln('  ${e.value.toString().padLeft(6)}  ${e.key}');
  }
  final sorted = files.toList()..sort();
  stdout.writeln('\n  Arquivos (${sorted.length}):');
  for (final f in sorted.take(top)) {
    stdout.writeln('    $f');
  }
  if (sorted.length > top) {
    stdout.writeln('    … e mais ${sorted.length - top} (use --top=)');
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

void _writeReport(String path, _Analysis a, int top) {
  final now = DateTime.now().toIso8601String().substring(0, 10);
  final buffer = StringBuffer();
  buffer.writeln('# DELTA_CLUSTERS — divergências numéricas agrupadas por '
      'causa provável');
  buffer.writeln();
  buffer.writeln('Gerado em $now por `dart run tool/cluster_deltas.dart` '
      'sobre `$cppGoldenRoot` × `$dartGoldenRoot` '
      '(dumpados por `compare_svg.dart --all`).');
  buffer.writeln();
  buffer.writeln('- Pares comparados: ${a.pairs}');
  buffer.writeln('- Arquivos com divergência numérica: ${a.divergentFiles}');
  buffer.writeln('- Divergências (nível de número): ${a.totalDivergences}');
  buffer.writeln('- Assinaturas distintas (classe/tag @atributo): '
      '${a.byKey.length}');
  buffer.writeln('- Subárvores podadas por divergência estrutural: '
      '${a.prunedSubtrees}');
  buffer.writeln();
  buffer.writeln('> Delta = Dart − C++. Contagem em nível de número, não de '
      'atributo — difere de `SVG_VALIDATION.md` por construção (ver doc do '
      'tool).');
  buffer.writeln();

  buffer.writeln('## Ranking por alcance — quantos arquivos cada assinatura '
      'destrava');
  buffer.writeln();
  buffer.writeln('| # | Assinatura | Arquivos | Divergências | '
      'Deltas mais compartilhados |');
  buffer.writeln('|---|---|---|---|---|');
  var i = 1;
  for (final e in _rankByReach(a.byKey).take(top)) {
    final deltas = e.value
        .topDeltas(5)
        .map((d) =>
            '`${_fmt(d.key)}` (${e.value.deltaFiles[d.key]!.length} arq)')
        .join(', ');
    buffer.writeln('| ${i++} | `${e.key}` | ${e.value.files.length} | '
        '${e.value.count} | $deltas |');
  }
  buffer.writeln();

  buffer.writeln('## Deltas mais compartilhados entre arquivos');
  buffer.writeln();
  buffer.writeln('Um mesmo delta sob várias classes costuma ser **uma** '
      'coordenada errada a montante que todo o resto herdou — atacar a '
      'origem custa uma correção e limpa todas as classes de uma vez.');
  buffer.writeln();
  buffer.writeln('| Delta (Dart − C++) | Arquivos |');
  buffer.writeln('|---|---|');
  for (final e in _rankDeltas(a.byKey).take(top)) {
    buffer.writeln('| `${_fmt(e.key)}` | ${e.value.length} |');
  }
  buffer.writeln();

  buffer.writeln('## Onde cai a primeira divergência de cada arquivo');
  buffer.writeln();
  buffer.writeln('A pauta é desenhada antes de tudo em cada compasso, então '
      'a "primeira divergência" é sistematicamente o sintoma mais a jusante. '
      'Esta tabela existe para tornar esse mascaramento visível — não use a '
      'primeira divergência como escolha de alvo.');
  buffer.writeln();
  buffer.writeln('| Classe | Arquivos cuja 1ª divergência cai aqui |');
  buffer.writeln('|---|---|');
  final firsts = a.firstDivergenceByClass.entries.toList()
    ..sort((x, y) => y.value.compareTo(x.value));
  for (final e in firsts.take(15)) {
    buffer.writeln('| `${e.key}` | ${e.value} |');
  }
  buffer.writeln();

  buffer.writeln('## Fila de menor custo — arquivos a poucos números do limpo');
  buffer.writeln();
  buffer.writeln('| Arquivo | Divergências (nível de número) |');
  buffer.writeln('|---|---|');
  for (final e in a.perFile.take(top)) {
    buffer.writeln('| ${e.key} | ${e.value} |');
  }
  buffer.writeln();

  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());
}
