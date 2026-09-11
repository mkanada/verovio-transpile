/// Comparador do snapshot de estado: lê o despejo do C++
/// (`cpp_probe/snapshot.sh`) e o do Dart (`tool/snapshot.dart`) de um mesmo
/// arquivo e diz **em que checkpoint** o estado da árvore deixa de bater.
///
/// Uso (a partir de `verovio_dart/`):
/// ```
/// dart run tool/snapshot_diff.dart <família>/<arquivo>.mei   # ou test/corpus/…
///     [--todos]            lista todas as divergências transitórias
///     [--max=N]            exemplos por (classe, campo)            (default 8)
///     [--excluir=a,b]      ignora `campo`, `classe.campo` ou `key:<texto>` ao
///                          comparar linhas (o hash já vem do despejo)
///     [--seq]              mostra a diferença de sequência inteira
/// dart run tool/snapshot_diff.dart --rank [--dir=<prefixo>]
///     agrupa, entre todos os arquivos com os dois despejos, o functor onde
///     nasce a primeira divergência — quantos arquivos cada um destrava
///     [--cpp=<dir>] [--dart=<dir>]   defaults ../tmp/snapshot/{cpp,dart}
/// ```
///
/// Como lê:
/// 1. Alinha as duas sequências de checkpoints pelo nome do functor (LCS). Um
///    checkpoint sem par é um functor que só um lado roda (ou roda em outro
///    ponto do pipeline) — um achado por si só.
/// 2. Percorre os pares alinhados em ordem e compara o estado: pelas linhas,
///    quando os dois despejos as têm naquele checkpoint (modo full), senão
///    pelo hash (modo digest).
/// 3. Separa as divergências transitórias (os dois lados fazem o mesmo trabalho
///    em outra ordem e o estado volta a bater) da **persistente**: a sequência
///    final de pares divergentes, depois da qual o estado nunca mais bate até
///    o desenho. O par onde ela começa localiza a origem: o estado batia depois
///    do par anterior e não bate depois deste, então a divergência nasceu no
///    código que roda entre os dois — o functor deste checkpoint e o que
///    houver antes dele (inclusive checkpoints sem par).
///
/// Support code for the port — not a port of any C++ file.
library;

import 'dart:convert';
import 'dart:io';

import 'snapshot/fields.g.dart' show kFieldOrigins;

const String _corpusPrefix = 'test/corpus/';

class _Checkpoint {
  _Checkpoint(Map<String, dynamic> j)
      : cp = j['cp'] as int,
        fn = j['fn'] as String,
        k = j['k'] as int,
        on = j['on'] as String? ?? '',
        rows = j['rows'] as int?,
        digest = j['digest'] as String?;
  final int cp;
  final String fn;
  final int k;
  final String on;
  final int? rows;
  final String? digest;
  String get label => '$fn#$k';
  bool get dumped => digest != null;
}

/// Synchronous, buffered line reader (dumps reach hundreds of MB).
class _LineReader {
  _LineReader(String path) : _file = File(path).openSync();
  final RandomAccessFile _file;
  final List<int> _pending = [];
  List<int> _buffer = const [];
  int _pos = 0;
  bool _eof = false;

  String? next() {
    while (true) {
      final int nl = _buffer.indexOf(10, _pos);
      if (nl >= 0) {
        final List<int> bytes = _pending.isEmpty
            ? _buffer.sublist(_pos, nl)
            : (_pending..addAll(_buffer.sublist(_pos, nl)));
        final String line = utf8.decode(bytes);
        _pending.clear();
        _pos = nl + 1;
        return line;
      }
      _pending.addAll(_buffer.sublist(_pos));
      if (_eof) {
        if (_pending.isEmpty) {
          _file.closeSync();
          return null;
        }
        final String line = utf8.decode(_pending);
        _pending.clear();
        return line;
      }
      _buffer = _file.readSync(1 << 20);
      _pos = 0;
      if (_buffer.isEmpty) _eof = true;
    }
  }
}

/// Walks a dump block by block: the n-th checkpoint header and its rows.
class _BlockStream {
  _BlockStream(String path) : _reader = _LineReader(path);
  final _LineReader _reader;
  int _block = -1;
  String? _lookahead;

  /// The rows of the [index]-th checkpoint as key -> the row text after the
  /// `{"cp":N,` prefix (blocks must be requested in increasing order).
  Map<String, String> rowsOfBlock(int index) {
    Map<String, String> rows = {};
    while (_block < index) {
      final String? header = _lookahead ?? _nextHeader();
      _lookahead = null;
      if (header == null) return {};
      _block++;
      rows = {};
      while (true) {
        final String? line = _reader.next();
        if (line == null) break;
        if (line.contains(',"fn":')) {
          _lookahead = line;
          break;
        }
        final int k = line.indexOf(',"key":"');
        if (k < 0) continue;
        final int end = line.indexOf('","class":"', k);
        rows[line.substring(k + 8, end)] = line.substring(k + 1);
      }
    }
    return rows;
  }

  String? _nextHeader() {
    while (true) {
      final String? line = _reader.next();
      if (line == null || line.contains(',"fn":')) return line;
    }
  }
}

class _Dump {
  _Dump(this.path);
  final String path;
  Map<String, dynamic> meta = {};
  final List<_Checkpoint> checkpoints = [];
  bool hasRows = false;

  static _Dump? load(String path) {
    final File file = File(path);
    if (!file.existsSync()) return null;
    final dump = _Dump(path);
    final _LineReader reader = _LineReader(path);
    for (String? line = reader.next(); line != null; line = reader.next()) {
      if (line.startsWith('{"_meta"')) {
        dump.meta = (jsonDecode(line) as Map<String, dynamic>)['_meta']
            as Map<String, dynamic>;
      } else if (line.contains(',"fn":')) {
        dump.checkpoints
            .add(_Checkpoint(jsonDecode(line) as Map<String, dynamic>));
      } else if (!dump.hasRows && line.contains(',"key":')) {
        dump.hasRows = true;
      }
    }
    return dump;
  }

  /// The rows of checkpoint [cp], keyed by entity key (read on demand).
  Map<String, Map<String, dynamic>> rowsAt(int cp) {
    final Map<String, Map<String, dynamic>> out = {};
    final String prefix = '{"cp":$cp,"key":';
    final _LineReader reader = _LineReader(path);
    for (String? line = reader.next(); line != null; line = reader.next()) {
      if (!line.startsWith(prefix)) continue;
      final Map<String, dynamic> row = jsonDecode(line) as Map<String, dynamic>;
      out[row['key'] as String] = row;
    }
    return out;
  }
}

/// LCS alignment of the two label sequences: pairs (i, j), -1 = no partner.
List<(int, int)> _align(List<String> a, List<String> b) {
  final int n = a.length;
  final int m = b.length;
  final List<List<int>> dp =
      List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (int i = n - 1; i >= 0; --i) {
    for (int j = m - 1; j >= 0; --j) {
      dp[i][j] = a[i] == b[j]
          ? dp[i + 1][j + 1] + 1
          : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }
  final List<(int, int)> out = [];
  int i = 0;
  int j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      out.add((i++, j++));
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      out.add((i++, -1));
    } else {
      out.add((-1, j++));
    }
  }
  while (i < n) {
    out.add((i++, -1));
  }
  while (j < m) {
    out.add((-1, j++));
  }
  return out;
}

String _rel(String input) {
  final String s = input.replaceAll('\\', '/');
  final int at = s.indexOf(_corpusPrefix);
  return at >= 0 ? s.substring(at + _corpusPrefix.length) : s;
}

String _fmt(Object? v) {
  if (v == null) return 'null';
  if (v is int && (v == 2147483647 || v == -2147483647)) {
    return v > 0 ? '+UNSET' : 'UNSET';
  }
  final String s = v is String ? v : jsonEncode(v);
  return s.length > 90 ? '${s.substring(0, 87)}...' : s;
}

String _delta(Object? c, Object? d) {
  if (c is num && d is num) {
    final num delta = d - c;
    return ' (Δ ${delta > 0 ? '+' : ''}${delta is double ? delta.toStringAsPrecision(6) : delta})';
  }
  if (c is List && d is List) {
    final int n = c.length < d.length ? c.length : d.length;
    for (int i = 0; i < n; ++i) {
      if (jsonEncode(c[i]) != jsonEncode(d[i])) {
        return ' ([$i]: ${_fmt(c[i])} × ${_fmt(d[i])}'
            '${c.length != d.length ? '; tamanhos ${c.length} × ${d.length}' : ''})';
      }
    }
    if (c.length != d.length) return ' (tamanhos ${c.length} × ${d.length})';
  }
  return '';
}

bool _same(Object? c, Object? d) {
  if (c is num && d is num) return c == d; // 1 == 1.0
  return jsonEncode(c) == jsonEncode(d);
}

/// Differences between two row sets: (only C++, only Dart, field diffs).
({
  List<String> onlyCpp,
  List<String> onlyDart,
  Map<String, List<(String, Object?, Object?)>> fields,
}) _diffRows(Map<String, Map<String, dynamic>> c,
    Map<String, Map<String, dynamic>> d, Set<String> exclude) {
  final List<String> keyTexts = [
    for (final e in exclude)
      if (e.startsWith('key:')) e.substring(4)
  ];
  bool keptKey(String k) => !keyTexts.any(k.contains);
  final List<String> onlyCpp = [
    for (final k in c.keys)
      if (!d.containsKey(k) && keptKey(k)) k
  ];
  final List<String> onlyDart = [
    for (final k in d.keys)
      if (!c.containsKey(k) && keptKey(k)) k
  ];
  final Map<String, List<(String, Object?, Object?)>> fields = {};
  for (final String key in c.keys) {
    final Map<String, dynamic>? dr = d[key];
    if (dr == null || !keptKey(key)) continue;
    final Map<String, dynamic> cr = c[key]!;
    final String cls = cr['class'] as String;
    for (final String f in {...cr.keys, ...dr.keys}) {
      if (f == 'cp' || f == 'key') continue;
      if (exclude.contains(f) || exclude.contains('$cls.$f')) continue;
      if (f == 'class') {
        if (cr[f] != dr[f]) {
          fields.putIfAbsent('class', () => []).add((key, cr[f], dr[f]));
        }
        continue;
      }
      if (!cr.containsKey(f) || !dr.containsKey(f) || !_same(cr[f], dr[f])) {
        fields.putIfAbsent('$cls.$f', () => []).add((
          key,
          cr.containsKey(f) ? cr[f] : '<ausente>',
          dr.containsKey(f) ? dr[f] : '<ausente>'
        ));
      }
    }
  }
  return (onlyCpp: onlyCpp, onlyDart: onlyDart, fields: fields);
}

/// The comparison of one file.
class _Result {
  _Result(this.rel, this.cpp, this.dart, this.pairs);
  final String rel;
  final _Dump cpp;
  final _Dump dart;
  final List<(int, int)> pairs;

  /// Aligned pairs dumped on both sides, in order: (index into [pairs], equal).
  final List<(int, bool)> states = [];

  int get compared => states.length;

  /// Index into [states] of the first divergent pair, or -1.
  int get first => states.indexWhere((s) => !s.$2);

  /// Index into [states] where the final divergent streak starts — from there
  /// on the state never matches again, so this is the divergence that reaches
  /// the drawing. -1 when the last compared pair matches.
  int get persistent {
    if (states.isEmpty || states.last.$2) return -1;
    int i = states.length - 1;
    while (i > 0 && !states[i - 1].$2) {
      --i;
    }
    return i;
  }

  _Checkpoint cppAt(int state) => cpp.checkpoints[pairs[states[state].$1].$1];
  _Checkpoint dartAt(int state) => dart.checkpoints[pairs[states[state].$1].$2];
}

_Result? _compare(String rel, String cppDir, String dartDir,
    {Set<String> exclude = const {}}) {
  final _Dump? cpp = _Dump.load('$cppDir/$rel.jsonl');
  final _Dump? dart = _Dump.load('$dartDir/$rel.jsonl');
  if (cpp == null || dart == null) return null;
  final pairs = _align([for (final c in cpp.checkpoints) c.fn],
      [for (final d in dart.checkpoints) d.fn]);
  final result = _Result(rel, cpp, dart, pairs);
  for (int p = 0; p < pairs.length; ++p) {
    final (int i, int j) = pairs[p];
    if (i < 0 || j < 0) continue;
    final _Checkpoint c = cpp.checkpoints[i];
    final _Checkpoint d = dart.checkpoints[j];
    if (!c.dumped || !d.dumped) continue;
    bool equal;
    if (cpp.hasRows && dart.hasRows && exclude.isNotEmpty) {
      final diff = _diffRows(cpp.rowsAt(c.cp), dart.rowsAt(d.cp), exclude);
      equal =
          diff.onlyCpp.isEmpty && diff.onlyDart.isEmpty && diff.fields.isEmpty;
    } else {
      equal = c.digest == d.digest;
    }
    result.states.add((p, equal));
  }
  return result;
}

/// One (entity, field) that diverges from some checkpoint on and never
/// matches again: the divergences that reach the drawing, each with the pair
/// where its final divergent streak starts.
class _Persistent {
  _Persistent(this.key, this.cls, this.field, this.birth, this.cpp, this.dart);
  final String key;
  final String cls;

  /// A manifest field, or `@presença` when the entity exists on one side only.
  final String field;

  /// Index into `_Result.states` of the pair where the divergence is born.
  final int birth;
  final Object? cpp;
  final Object? dart;
  String get signature => '$cls.$field';
}

/// True when both dumps carry rows at every compared pair (full mode, no --at).
bool _hasAllRows(_Result r) =>
    r.cpp.hasRows &&
    r.dart.hasRows &&
    r.compared > 0 &&
    r.compared == r.pairs.where((p) => p.$1 >= 0 && p.$2 >= 0).length;

/// Streams both dumps pair by pair and tracks, for every (key, field), where
/// its current divergent streak started; what is still divergent at the last
/// pair is persistent. Rows are compared as text first (the two sides write
/// the fields in the same order) and decoded only when the text differs.
List<_Persistent> _fieldPersistence(_Result r, Set<String> exclude) {
  final _BlockStream cs = _BlockStream(r.cpp.path);
  final _BlockStream ds = _BlockStream(r.dart.path);
  final List<String> keyTexts = [
    for (final e in exclude)
      if (e.startsWith('key:')) e.substring(4)
  ];
  // key -> field -> state index where its divergent streak started.
  final Map<String, Map<String, int>> active = {};
  Map<String, String> lastC = {};
  Map<String, String> lastD = {};
  const String presence = '@presença';
  for (int st = 0; st < r.states.length; ++st) {
    final (int i, int j) = r.pairs[r.states[st].$1];
    final Map<String, String> c = cs.rowsOfBlock(i);
    final Map<String, String> d = ds.rowsOfBlock(j);
    for (final String key in {...c.keys, ...d.keys}) {
      if (keyTexts.any(key.contains)) continue;
      final String? ct = c[key];
      final String? dt = d[key];
      if (ct == null || dt == null) {
        active.putIfAbsent(key, () => {}).putIfAbsent(presence, () => st);
        continue;
      }
      if (ct == dt) {
        active.remove(key);
        continue;
      }
      final Map<String, dynamic> cr =
          jsonDecode('{$ct') as Map<String, dynamic>;
      final Map<String, dynamic> dr =
          jsonDecode('{$dt') as Map<String, dynamic>;
      final String cls = cr['class'] as String;
      final Map<String, int> fields = active.putIfAbsent(key, () => {});
      fields.remove(presence);
      for (final String f in {...cr.keys, ...dr.keys}) {
        if (f == 'key' || f == 'class') continue;
        if (exclude.contains(f) || exclude.contains('$cls.$f')) continue;
        final bool equal =
            cr.containsKey(f) && dr.containsKey(f) && _same(cr[f], dr[f]);
        if (equal) {
          fields.remove(f);
        } else {
          fields.putIfAbsent(f, () => st);
        }
      }
      if (fields.isEmpty) active.remove(key);
    }
    lastC = c;
    lastD = d;
  }
  // Persistent: still divergent at the last pair, for entities that exist there.
  final List<_Persistent> out = [];
  for (final String key in {...lastC.keys, ...lastD.keys}) {
    final Map<String, int>? fields = active[key];
    if (fields == null) continue;
    final Map<String, dynamic>? cr = lastC[key] == null
        ? null
        : jsonDecode('{${lastC[key]}') as Map<String, dynamic>;
    final Map<String, dynamic>? dr = lastD[key] == null
        ? null
        : jsonDecode('{${lastD[key]}') as Map<String, dynamic>;
    final String cls = (cr ?? dr)!['class'] as String;
    for (final MapEntry<String, int> e in fields.entries) {
      if (e.key == presence) {
        out.add(_Persistent(
            key,
            cls,
            presence,
            e.value,
            cr == null ? '<ausente>' : 'presente',
            dr == null ? '<ausente>' : 'presente'));
      } else {
        out.add(_Persistent(
            key,
            cls,
            e.key,
            e.value,
            cr == null || !cr.containsKey(e.key) ? '<ausente>' : cr[e.key],
            dr == null || !dr.containsKey(e.key) ? '<ausente>' : dr[e.key]));
      }
    }
  }
  return out;
}

/// Groups [found] by (signature, birth functor): the per-file field report.
Map<(String, String), List<_Persistent>> _groupPersistent(
    _Result r, List<_Persistent> found) {
  final Map<(String, String), List<_Persistent>> out = {};
  for (final p in found) {
    out.putIfAbsent((p.signature, r.cppAt(p.birth).fn), () => []).add(p);
  }
  return out;
}

void _printPersistent(_Result r, List<_Persistent> found, int max) {
  if (found.isEmpty) {
    stdout.writeln(
        'Campos persistentes: nenhum — o estado final bate campo a campo.');
    return;
  }
  final groups = _groupPersistent(r, found).entries.toList()
    ..sort((a, b) {
      final int birth = a.value.first.birth.compareTo(b.value.first.birth);
      return birth != 0 ? birth : b.value.length.compareTo(a.value.length);
    });
  stdout.writeln('Campos persistentes (divergem até o fim), por onde nascem — '
      '${found.length} (entidade, campo) em ${groups.length} grupos:');
  for (final g in groups.take(max * 3)) {
    final _Persistent first = g.value.first;
    final String field =
        first.field.startsWith('@') ? first.field : first.field;
    final origin = kFieldOrigins[field];
    stdout.writeln('  ${g.key.$1} — nasce em C++ @${r.cppAt(first.birth).cp} '
        '${r.cppAt(first.birth).label} × Dart @${r.dartAt(first.birth).cp} — '
        '${g.value.length} entidade(s)'
        '${origin == null ? '' : '   [C++: ${origin.$2} ${origin.$3}]'}');
    for (final p in g.value.take(max)) {
      stdout.writeln('    ${p.key}: C++ ${_fmt(p.cpp)}  Dart ${_fmt(p.dart)}'
          '${_delta(p.cpp, p.dart)}');
    }
    if (g.value.length > max) stdout.writeln('    … +${g.value.length - max}');
  }
  if (groups.length > max * 3) {
    stdout.writeln('  … +${groups.length - max * 3} grupos (--max)');
  }
}

void main(List<String> args) {
  bool rank = false;
  bool all = false;
  bool showSeq = false;
  int max = 8;
  String? dirFilter;
  String cppDir = '../tmp/snapshot/cpp';
  String dartDir = '../tmp/snapshot/dart';
  Set<String> exclude = {};
  final List<String> inputs = [];
  for (final a in args) {
    final int eq = a.indexOf('=');
    final String name = eq < 0 ? a : a.substring(0, eq);
    final String value = eq < 0 ? '' : a.substring(eq + 1);
    switch (name) {
      case '--rank':
        rank = true;
      case '--todos' || '--all':
        all = true;
      case '--seq':
        showSeq = true;
      case '--max':
        max = int.tryParse(value) ?? max;
      case '--dir':
        dirFilter = _rel(value);
      case '--cpp':
        cppDir = value;
      case '--dart':
        dartDir = value;
      case '--excluir' || '--exclude':
        exclude = value.split(',').where((s) => s.isNotEmpty).toSet();
      default:
        if (a.startsWith('-')) {
          stderr.writeln('snapshot_diff: opção desconhecida: $a');
          exit(2);
        }
        inputs.add(_rel(a));
    }
  }

  if (rank) {
    _rank(cppDir, dartDir, dirFilter, exclude);
    return;
  }
  if (inputs.isEmpty) {
    stderr.writeln(
        'uso: dart run tool/snapshot_diff.dart <família>/<arquivo>.mei '
        '[--todos] [--max=N] [--excluir=..] [--seq]\n'
        '     dart run tool/snapshot_diff.dart --rank [--dir=<prefixo>]');
    exit(2);
  }
  int exitCode = 0;
  for (final rel in inputs) {
    if (!_report(rel, cppDir, dartDir,
        all: all, max: max, exclude: exclude, showSeq: showSeq)) {
      exitCode = 1;
    }
  }
  exit(exitCode);
}

/// Prints the report of one file; false when a divergence (or a missing dump)
/// was found.
bool _report(String rel, String cppDir, String dartDir,
    {required bool all,
    required int max,
    required Set<String> exclude,
    required bool showSeq}) {
  final _Result? r = _compare(rel, cppDir, dartDir, exclude: exclude);
  stdout.writeln('== $rel');
  if (r == null) {
    stdout.writeln('  despejo ausente: gere com\n'
        '    cpp_probe/snapshot.sh test/corpus/$rel\n'
        '    dart run tool/snapshot.dart test/corpus/$rel');
    return false;
  }
  _checkMeta(r);

  // 1. Sequence.
  final int paired = r.pairs.where((p) => p.$1 >= 0 && p.$2 >= 0).length;
  final int onlyCpp = r.pairs.where((p) => p.$2 < 0).length;
  final int onlyDart = r.pairs.where((p) => p.$1 < 0).length;
  stdout.writeln('Sequência: C++ ${r.cpp.checkpoints.length} checkpoints, '
      'Dart ${r.dart.checkpoints.length}; $paired alinhados, '
      '$onlyCpp só no C++, $onlyDart só no Dart.');
  final int target = r.persistent;
  final int seqLimit =
      showSeq || target < 0 ? r.pairs.length : r.states[target].$1 + 1;
  final List<String> seqLines = _sequenceRuns(r, seqLimit);
  if (seqLines.isNotEmpty) {
    stdout.writeln(showSeq || target < 0
        ? '  checkpoints sem par:'
        : '  checkpoints sem par até a divergência persistente:');
    seqLines.forEach(stdout.writeln);
  }

  // 2. State.
  if (r.compared == 0) {
    stdout.writeln('Estado: nenhum par alinhado tem despejo dos dois lados '
        '(modo seq, ou --at sem par comum).');
    return onlyCpp == 0 && onlyDart == 0;
  }
  final int divergentCount = r.states.where((s) => !s.$2).length;
  stdout.writeln(
      'Estado: ${r.compared} pares comparados, $divergentCount divergentes.');
  if (target < 0) {
    stdout.writeln(divergentCount == 0
        ? '  todos batem.'
        : '  o último par comparado bate: as divergências são transitórias '
            '(ordem de pipeline) e se reconciliam.');
    if (divergentCount > 0) _transients(r, all);
    return onlyCpp == 0 && onlyDart == 0 && divergentCount == 0;
  }
  final _Checkpoint c = r.cppAt(target);
  final _Checkpoint d = r.dartAt(target);
  stdout.writeln(
      '  divergência persistente (não volta a bater até o fim) começa em');
  stdout.writeln('    C++ @${c.cp} ${c.label} (sobre ${c.on})  ×  '
      'Dart @${d.cp} ${d.label} (sobre ${d.on})');
  _Checkpoint? cBefore;
  _Checkpoint? dBefore;
  if (target > 0) {
    cBefore = r.cppAt(target - 1);
    dBefore = r.dartAt(target - 1);
    stdout.writeln('    último par igual antes dela: C++ @${cBefore.cp} '
        '${cBefore.label}  ×  Dart @${dBefore.cp} ${dBefore.label}');
    stdout.writeln('    → nasce no código que roda entre o fim desses dois '
        'checkpoints (o functor ${c.fn} e o que houver sem par antes dele).');
  } else {
    stdout.writeln('    (nenhum par comparado batia antes: já está no primeiro '
        'estado despejado)');
  }
  if (r.first >= 0 && r.first < target) _transients(r, all, before: target);

  if (!r.cpp.hasRows || !r.dart.hasRows) {
    final String cAt = cBefore == null ? '@${c.cp}' : '@${cBefore.cp}|@${c.cp}';
    final String dAt = dBefore == null ? '@${d.cp}' : '@${dBefore.cp}|@${d.cp}';
    stdout
        .writeln('  sem linhas neste despejo (modo digest). Para ver os campos '
            '(antes e depois):');
    stdout.writeln(
        "    cpp_probe/snapshot.sh --nivel=3 --at='$cAt' test/corpus/$rel");
    stdout.writeln(
        "    dart run tool/snapshot.dart --nivel=3 --at='$dAt' test/corpus/$rel");
    stdout.writeln('    dart run tool/snapshot_diff.dart $rel');
    return false;
  }
  if (_hasAllRows(r)) {
    _printPersistent(r, _fieldPersistence(r, exclude), max);
    return false;
  }
  final Map<String, Map<String, dynamic>> cRows = r.cpp.rowsAt(c.cp);
  final Map<String, Map<String, dynamic>> before =
      cBefore == null ? const {} : r.cpp.rowsAt(cBefore.cp);
  final diff = _diffRows(cRows, r.dart.rowsAt(d.cp), exclude);
  stdout.writeln('Linhas: ${diff.onlyCpp.length} entidades só no C++, '
      '${diff.onlyDart.length} só no Dart, ${diff.fields.length} (classe.campo) '
      'com valores diferentes${before.isEmpty ? '' : ' (antes = valor no último par igual)'}.');
  void keys(String title, List<String> list) {
    if (list.isEmpty) return;
    stdout.writeln('  $title:');
    for (final k in list.take(max)) {
      stdout.writeln('    $k');
    }
    if (list.length > max) stdout.writeln('    … +${list.length - max}');
  }

  keys('só no C++', diff.onlyCpp);
  keys('só no Dart', diff.onlyDart);
  final entries = diff.fields.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (final e in entries) {
    final String field = e.key.contains('.') ? e.key.split('.').last : e.key;
    final origin = kFieldOrigins[field];
    stdout.writeln('  ${e.key} — ${e.value.length} entidade(s)'
        '${origin == null ? '' : '   [C++: ${origin.$2} ${origin.$3}]'}');
    for (final (String key, Object? cv, Object? dv) in e.value.take(max)) {
      final Map<String, dynamic>? b = before[key];
      final String was = b != null && b.containsKey(field)
          ? '  (antes ${_fmt(b[field])})'
          : '';
      stdout.writeln(
          '    $key: C++ ${_fmt(cv)}  Dart ${_fmt(dv)}${_delta(cv, dv)}$was');
    }
    if (e.value.length > max) stdout.writeln('    … +${e.value.length - max}');
  }
  return false;
}

/// Lists the divergent pairs that reconcile later (before [before], if given).
void _transients(_Result r, bool all, {int? before}) {
  final List<String> labels = [];
  for (int s = 0; s < (before ?? r.states.length); ++s) {
    if (!r.states[s].$2) labels.add(r.cppAt(s).label);
  }
  if (labels.isEmpty) return;
  final int shown = all ? labels.length : 6;
  stdout.writeln('  divergências transitórias antes (voltam a bater; em geral '
      'ordem de pipeline): ${labels.take(shown).join(', ')}'
      '${labels.length > shown ? ', … (+${labels.length - shown}; --todos)' : ''}');
}

void _checkMeta(_Result r) {
  for (final k in ['groups', 'path', 'class', 'exclude']) {
    if ('${r.cpp.meta[k]}' != '${r.dart.meta[k]}') {
      stdout.writeln('  AVISO: os despejos foram gerados com "$k" diferente '
          '(C++ ${r.cpp.meta[k]}, Dart ${r.dart.meta[k]}) — os hashes não são '
          'comparáveis.');
    }
  }
}

/// Compact runs of unpaired checkpoints among the first [limit] pairs.
List<String> _sequenceRuns(_Result r, int limit) {
  final List<String> out = [];
  int p = 0;
  while (p < limit && p < r.pairs.length) {
    final (int i, int j) = r.pairs[p];
    if (i >= 0 && j >= 0) {
      p++;
      continue;
    }
    // Context: the last paired checkpoint before this run.
    String after = 'início';
    for (int q = p - 1; q >= 0; --q) {
      if (r.pairs[q].$1 >= 0 && r.pairs[q].$2 >= 0) {
        after = r.cpp.checkpoints[r.pairs[q].$1].label;
        break;
      }
    }
    final List<String> cppOnly = [];
    final List<String> dartOnly = [];
    while (p < r.pairs.length && (r.pairs[p].$1 < 0 || r.pairs[p].$2 < 0)) {
      final (int a, int b) = r.pairs[p];
      if (b < 0)
        cppOnly.add('@${r.cpp.checkpoints[a].cp} ${r.cpp.checkpoints[a].fn}');
      if (a < 0)
        dartOnly
            .add('@${r.dart.checkpoints[b].cp} ${r.dart.checkpoints[b].fn}');
      p++;
    }
    out.add('    depois de $after:');
    if (cppOnly.isNotEmpty) out.add('      só C++:  ${cppOnly.join(', ')}');
    if (dartOnly.isNotEmpty) out.add('      só Dart: ${dartOnly.join(', ')}');
  }
  return out;
}

void _rank(
    String cppDir, String dartDir, String? dirFilter, Set<String> exclude) {
  final Directory root = Directory(cppDir);
  if (!root.existsSync()) {
    stderr.writeln('snapshot_diff: $cppDir não existe');
    exit(1);
  }
  final List<String> rels = [
    for (final f in root.listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.mei.jsonl'))
        f.path.substring(cppDir.length + 1, f.path.length - '.jsonl'.length)
  ]..sort();
  final Map<String, List<String>> byFn = {};
  final Map<(String, String), _FieldRank> byField = {};
  int fieldFiles = 0;
  final List<String> clean = [];
  final List<String> missing = [];
  final Map<String, int> unpairedCpp = {};
  final Map<String, int> unpairedDart = {};
  for (final rel in rels) {
    if (dirFilter != null && !rel.startsWith(dirFilter)) continue;
    final _Result? r = _compare(rel, cppDir, dartDir, exclude: exclude);
    if (r == null) {
      missing.add(rel);
      continue;
    }
    for (final (int i, int j) in r.pairs) {
      if (j < 0)
        unpairedCpp.update(r.cpp.checkpoints[i].fn, (v) => v + 1,
            ifAbsent: () => 1);
      if (i < 0)
        unpairedDart.update(r.dart.checkpoints[j].fn, (v) => v + 1,
            ifAbsent: () => 1);
    }
    if (_hasAllRows(r)) {
      final List<_Persistent> found = _fieldPersistence(r, exclude);
      if (found.isEmpty) {
        clean.add(rel);
        continue;
      }
      fieldFiles++;
      for (final e in _groupPersistent(r, found).entries) {
        final _FieldRank rank = byField.putIfAbsent(e.key, () => _FieldRank());
        rank.files.add(rel);
        rank.entities += e.value.length;
        rank.example ??= '$rel ${e.value.first.key}: C++ '
            '${_fmt(e.value.first.cpp)} Dart ${_fmt(e.value.first.dart)}';
      }
      continue;
    }
    final int target = r.persistent;
    if (target < 0) {
      clean.add(rel);
      continue;
    }
    final String fn = r.cppAt(target).fn;
    byFn.putIfAbsent(fn, () => []).add(rel);
  }
  final int total = byFn.values.fold(0, (a, b) => a + b.length) +
      clean.length +
      byField.values.fold<Set<String>>({}, (a, b) => a..addAll(b.files)).length;
  stdout.writeln(
      'Arquivos comparados: $total (${clean.length} sem divergência de '
      'estado persistente${missing.isEmpty ? '' : '; ${missing.length} sem o despejo Dart'}).');
  stdout.writeln();
  if (byField.isNotEmpty) {
    stdout.writeln('Por campo ($fieldFiles arquivos com linhas em todos os '
        'checkpoints): cada (classe.campo) que diverge até o fim, pelo functor '
        'onde a divergência nasce.');
    stdout.writeln();
    stdout.writeln('| # | Campo | Nasce em | Arquivos | Entidades | Exemplo |');
    stdout.writeln('|---|---|---|---|---|---|');
    final ranked = byField.entries.toList()
      ..sort((a, b) {
        final int files = b.value.files.length.compareTo(a.value.files.length);
        return files != 0
            ? files
            : b.value.entities.compareTo(a.value.entities);
      });
    for (int i = 0; i < ranked.length && i < 60; ++i) {
      final e = ranked[i];
      stdout.writeln('| ${i + 1} | `${e.key.$1}` | `${e.key.$2}` | '
          '${e.value.files.length} | ${e.value.entities} | ${e.value.example} |');
    }
    if (ranked.length > 60)
      stdout.writeln('| … | +${ranked.length - 60} | | | | |');
    stdout.writeln();
  }
  if (byFn.isEmpty) {
    unpairedReport(unpairedCpp, unpairedDart);
    return;
  }
  stdout.writeln(
      'Por hash (arquivos despejados sem linhas em todos os checkpoints):');
  stdout.writeln();
  stdout.writeln(
      '| # | Functor onde nasce a divergência persistente | Arquivos | Exemplos |');
  stdout.writeln('|---|---|---|---|');
  final ranked = byFn.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));
  for (int i = 0; i < ranked.length; ++i) {
    final e = ranked[i];
    stdout.writeln('| ${i + 1} | `${e.key}` | ${e.value.length} | '
        '${e.value.take(3).join(', ')}${e.value.length > 3 ? ', …' : ''} |');
  }
  unpairedReport(unpairedCpp, unpairedDart);
}

void unpairedReport(
    Map<String, int> unpairedCpp, Map<String, int> unpairedDart) {
  void unpaired(String title, Map<String, int> m) {
    if (m.isEmpty) return;
    final list = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    stdout.writeln();
    stdout.writeln('$title (ocorrências somadas em todos os arquivos):');
    for (final e in list.take(15)) {
      stdout.writeln('  ${e.value.toString().padLeft(6)}  ${e.key}');
    }
  }

  unpaired('Checkpoints só no C++', unpairedCpp);
  unpaired('Checkpoints só no Dart', unpairedDart);
}

class _FieldRank {
  final Set<String> files = {};
  int entities = 0;
  String? example;
}
