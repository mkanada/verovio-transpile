/// Generates both sides of the state-snapshot field emitters from the shared
/// manifest `cpp_probe/snapshot/fields.manifest`.
///
/// Usage (from `verovio_dart/`):
/// ```
/// dart run tool/gen_snapshot_fields.dart           # regenerate both files
/// dart run tool/gen_snapshot_fields.dart --check   # exit 1 if either is stale
/// ```
///
/// Writes:
/// - `../cpp_probe/snapshot/vrvsnapshot_fields.inc` — `EmitFields()`, included
///   by `vrvsnapshot.cpp` inside the instrumented C++ binary;
/// - `tool/snapshot/fields.g.dart` — `emitFields()` plus the field metadata the
///   comparator uses to name the C++ member behind a divergent field.
///
/// Both functions test the entity against the manifest classes in the same
/// order and emit the fields in the same order, so a row has the same shape on
/// both sides. The manifest format is documented at the top of the manifest.
///
/// Support code for the port — not a port of any C++ file.
library;

import 'dart:io';

const String _manifestPath = '../cpp_probe/snapshot/fields.manifest';
const String _cppOutPath = '../cpp_probe/snapshot/vrvsnapshot_fields.inc';
const String _dartOutPath = 'tool/snapshot/fields.g.dart';
const String _cppHeadersDir = '../origin/src/include/vrv';

const Map<String, int> _groups = {
  'bb': 1,
  'pos': 2,
  'link': 4,
  'layout': 8,
  'cache': 16,
};

const Set<String> _types = {
  'int',
  'bool',
  'double',
  'enum',
  'ref',
  'refs',
  'frac',
  'ints',
};

const Set<String> _reserved = {'cp', 'key', 'class'};

class _Field {
  _Field(this.line, this.group, this.cppClass, this.dartClass, this.name,
      this.type, this.cppExpr, this.dartExpr);
  final int line;
  final String group;
  final String cppClass;
  final String dartClass;
  final String name;
  final String type;
  final String cppExpr;
  final String dartExpr;
}

Never _fail(String message) {
  stderr.writeln('gen_snapshot_fields: $message');
  exit(2);
}

void main(List<String> args) {
  final bool check = args.contains('--check');
  final ({Map<String, String> outputs, int fields, int classes}) gen =
      generateSnapshotFields();
  bool stale = false;
  for (final MapEntry<String, String> e in gen.outputs.entries) {
    final File out = File(e.key);
    final bool same = out.existsSync() && out.readAsStringSync() == e.value;
    if (check) {
      if (!same) {
        stderr.writeln('stale: ${e.key}');
        stale = true;
      }
    } else if (!same) {
      out.parent.createSync(recursive: true);
      out.writeAsStringSync(e.value);
      stdout.writeln('wrote ${e.key}');
    } else {
      stdout.writeln('unchanged ${e.key}');
    }
  }
  if (check && stale) {
    stderr.writeln('run: dart run tool/gen_snapshot_fields.dart');
    exit(1);
  }
  stdout.writeln('${gen.fields} fields, ${gen.classes} classes');
}

/// The generated files that do not match what the manifest generates now —
/// empty when both sides are up to date. A content check, not an mtime one:
/// git does not preserve modification times, so a fresh clone would make any
/// "manifest newer than the output" test fire for nothing. Used by
/// `tool/snapshot.dart` before it dumps.
List<String> staleSnapshotFields() => [
      for (final MapEntry<String, String> e
          in generateSnapshotFields().outputs.entries)
        if (!File(e.key).existsSync() ||
            File(e.key).readAsStringSync() != e.value)
          e.key
    ];

/// Parses the manifest and returns the content of both generated files, keyed
/// by path (relative to `verovio_dart/`).
({Map<String, String> outputs, int fields, int classes})
    generateSnapshotFields() {
  final File manifest = File(_manifestPath);
  if (!manifest.existsSync()) {
    _fail('$_manifestPath not found — run from verovio_dart/.');
  }

  final List<_Field> fields = [];
  final List<String> dartImports = [];
  String? skipFunctors;
  final Set<String> names = {};
  final List<String> lines = manifest.readAsLinesSync();
  for (int i = 0; i < lines.length; ++i) {
    final String raw = lines[i].trim();
    if (raw.isEmpty || raw.startsWith('#')) continue;
    if (raw.startsWith('@skip-functors ')) {
      skipFunctors = raw.substring('@skip-functors '.length).trim();
      continue;
    }
    if (raw.startsWith('@dart-import ')) {
      dartImports.add(raw.substring('@dart-import '.length).trim());
      continue;
    }
    final List<String> cols = raw.split(' | ').map((c) => c.trim()).toList();
    if (cols.length != 7) {
      _fail('line ${i + 1}: expected 7 columns separated by " | ", '
          'got ${cols.length}');
    }
    final f = _Field(
        i + 1, cols[0], cols[1], cols[2], cols[3], cols[4], cols[5], cols[6]);
    if (!_groups.containsKey(f.group)) {
      _fail('line ${f.line}: unknown group "${f.group}"');
    }
    if (!_types.contains(f.type)) {
      _fail('line ${f.line}: unknown type "${f.type}"');
    }
    if (_reserved.contains(f.name) || !names.add(f.name)) {
      _fail('line ${f.line}: field name "${f.name}" is reserved or repeated');
    }
    fields.add(f);
  }
  if (skipFunctors == null) _fail('missing @skip-functors directive');

  // Class blocks in order of first appearance.
  final List<String> classOrder = [];
  final Map<String, List<_Field>> byClass = {};
  for (final f in fields) {
    final String key = '${f.cppClass}|${f.dartClass}';
    if (!byClass.containsKey(key)) classOrder.add(key);
    byClass.putIfAbsent(key, () => []).add(f);
  }

  return (
    outputs: {
      _cppOutPath: _generateCpp(classOrder, byClass, skipFunctors),
      _dartOutPath: _generateDart(classOrder, byClass, skipFunctors,
          dartImports, _cppConstFunctors(), fields),
    },
    fields: fields.length,
    classes: classOrder.length,
  );
}

/// Every C++ class deriving from ConstFunctor / DocConstFunctor: the C++ side
/// never hooks the const `Object::Process`, so the Dart side skips these.
List<String> _cppConstFunctors() {
  final Directory dir = Directory(_cppHeadersDir);
  if (!dir.existsSync()) _fail('$_cppHeadersDir not found');
  final RegExp decl =
      RegExp(r'^class (\w+) : public (?:Doc)?ConstFunctor\b', multiLine: true);
  final Set<String> out = {};
  for (final e in dir.listSync()) {
    if (e is! File || !e.path.endsWith('.h')) continue;
    for (final m in decl.allMatches(e.readAsStringSync())) {
      out.add(m.group(1)!);
    }
  }
  return out.toList()..sort();
}

// ---------------------------------------------------------------------------
// Expression forms: EACH / SORTED / plain
// ---------------------------------------------------------------------------

/// Splits [s] on top-level commas (not inside (), [], {}, <> of templates is
/// not tracked — templates with commas must be parenthesised).
List<String> _splitTop(String s) {
  final List<String> out = [];
  int depth = 0;
  int start = 0;
  for (int i = 0; i < s.length; ++i) {
    final String c = s[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') depth--;
    if (c == ',' && depth == 0) {
      out.add(s.substring(start, i).trim());
      start = i + 1;
    }
  }
  out.add(s.substring(start).trim());
  return out;
}

/// Index of the ')' matching the '(' at [open].
int _matching(String s, int open) {
  int depth = 0;
  for (int i = open; i < s.length; ++i) {
    if (s[i] == '(') depth++;
    if (s[i] == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  _fail('unbalanced parentheses in "$s"');
}

/// A parsed `EACH(v in container: e1, e2, ...)`, or null.
({String v, String container, List<String> elements})? _each(String expr) {
  final String e = expr.trim();
  if (!e.startsWith('EACH(') || _matching(e, 4) != e.length - 1) return null;
  final String inner = e.substring(5, e.length - 1);
  final Match? m = RegExp(r'^\s*(\w+)\s+in\s+').firstMatch(inner);
  if (m == null) _fail('bad EACH, expected "EACH(v in ...: ...)": $expr');
  final String rest = inner.substring(m.end);
  // First top-level ':' that is not part of '::'.
  int depth = 0;
  for (int i = 0; i < rest.length; ++i) {
    final String c = rest[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') depth--;
    if (c == ':' && depth == 0) {
      final bool dbl = (i + 1 < rest.length && rest[i + 1] == ':') ||
          (i > 0 && rest[i - 1] == ':');
      if (dbl) continue;
      return (
        v: m.group(1)!,
        container: rest.substring(0, i).trim(),
        elements: _splitTop(rest.substring(i + 1)),
      );
    }
  }
  _fail('bad EACH, missing ":" after the container: $expr');
}

/// A parsed `IF(cond: expr)`, or null — the field is emitted only when
/// `cond` holds (for members the C++ leaves uninitialized until some point).
({String cond, String expr})? _if(String expr) {
  final String e = expr.trim();
  if (!e.startsWith('IF(') || _matching(e, 2) != e.length - 1) return null;
  final String inner = e.substring(3, e.length - 1);
  int depth = 0;
  for (int i = 0; i < inner.length; ++i) {
    final String c = inner[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') depth--;
    if (c == ':' && depth == 0) {
      final bool dbl = (i + 1 < inner.length && inner[i + 1] == ':') ||
          (i > 0 && inner[i - 1] == ':');
      if (dbl) continue;
      return (
        cond: inner.substring(0, i).trim(),
        expr: inner.substring(i + 1).trim()
      );
    }
  }
  _fail('bad IF, expected "IF(cond: expr)": $expr');
}

/// The inner expression of `SORTED(x)`, or null.
String? _sorted(String expr) {
  final String e = expr.trim();
  if (!e.startsWith('SORTED(') || _matching(e, 6) != e.length - 1) return null;
  return e.substring(7, e.length - 1);
}

// ---------------------------------------------------------------------------
// C++
// ---------------------------------------------------------------------------

String _cppCast(String kind, String e) =>
    kind == 'refs' ? 'row.Valid($e)' : '(long long)($e)';

void _cppFill(StringBuffer b, String expr, String vec, String kind,
    String indent, int line) {
  final each = _each(expr);
  if (each != null) {
    b.writeln('${indent}for (const auto &${each.v} : (${each.container})) {');
    for (final el in each.elements) {
      if (_each(el) != null) {
        _cppFill(b, el, vec, kind, '$indent    ', line);
      } else if (_sorted(el) != null) {
        _fail('line $line: SORTED() is only allowed at the top level');
      } else {
        b.writeln('$indent    $vec.push_back(${_cppCast(kind, el)});');
      }
    }
    b.writeln('$indent}');
    return;
  }
  b.writeln('${indent}for (const auto &_e : ($expr)) '
      '$vec.push_back(${_cppCast(kind, '_e')});');
}

String _generateCpp(List<String> classOrder, Map<String, List<_Field>> byClass,
    String skipFunctors) {
  final b = StringBuffer();
  b.writeln('// GENERATED FILE — do not edit.');
  b.writeln('// Source: cpp_probe/snapshot/fields.manifest');
  b.writeln('// Regenerate: (cd verovio_dart && dart run '
      'tool/gen_snapshot_fields.dart)');
  b.writeln('//');
  b.writeln('// Included by cpp_probe/snapshot/vrvsnapshot.cpp inside '
      'namespace vrv::snapshot.');
  b.writeln('// The Dart twin is verovio_dart/tool/snapshot/fields.g.dart.');
  b.writeln();
  b.writeln('static const char *const kSkipFunctors = '
      '"${skipFunctors.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}";');
  b.writeln();
  b.writeln('static void EmitFields(const BoundingBox *bb, Row &row)');
  b.writeln('{');
  for (final key in classOrder) {
    final List<_Field> fs = byClass[key]!;
    final String cls = fs.first.cppClass;
    if (cls == 'BoundingBox') {
      b.writeln('    {');
      b.writeln('        const BoundingBox *o = bb;');
    } else {
      b.writeln('    if (const $cls *o = dynamic_cast<const $cls *>(bb)) {');
    }
    for (final field in fs) {
      final guard = _if(field.cppExpr);
      final _Field f = guard == null
          ? field
          : _Field(field.line, field.group, field.cppClass, field.dartClass,
              field.name, field.type, guard.expr, field.dartExpr);
      final String g = guard == null
          ? 'G_${f.group.toUpperCase()}'
          : 'G_${f.group.toUpperCase()}) && (${guard.cond}';
      final String n = '"${f.name}"';
      switch (f.type) {
        case 'int':
        case 'enum':
          b.writeln('        if (row.Wants($g)) row.Int($n, '
              '(long long)(${f.cppExpr}));');
        case 'bool':
          b.writeln('        if (row.Wants($g)) row.Bool($n, '
              '(bool)(${f.cppExpr}));');
        case 'double':
          b.writeln('        if (row.Wants($g)) row.Double($n, '
              '(double)(${f.cppExpr}));');
        case 'ref':
          b.writeln('        if (row.Wants($g)) row.Ref($n, ${f.cppExpr});');
        case 'frac':
          b.writeln('        if (row.Wants($g)) row.Frac($n, ${f.cppExpr});');
        case 'ints':
        case 'refs':
          final String vt =
              f.type == 'refs' ? 'const BoundingBox *' : 'long long';
          b.writeln('        if (row.Wants($g)) {');
          b.writeln('            std::vector<$vt> v;');
          final String? sortedInner = _sorted(f.cppExpr);
          _cppFill(
              b, sortedInner ?? f.cppExpr, 'v', f.type, '            ', f.line);
          if (sortedInner != null) {
            b.writeln('            std::sort(v.begin(), v.end());');
          }
          b.writeln('            row.${f.type == 'refs' ? 'Refs' : 'Ints'}'
              '($n, v);');
          b.writeln('        }');
      }
    }
    b.writeln('    }');
  }
  b.writeln('}');
  return b.toString();
}

// ---------------------------------------------------------------------------
// Dart
// ---------------------------------------------------------------------------

String _dartPriv(_Field f) {
  final String name = f.dartExpr.substring(1);
  switch (f.type) {
    case 'int':
    case 'enum':
      return "priv(o, '$name') as int";
    case 'bool':
      return "priv(o, '$name') as bool";
    case 'double':
      return "priv(o, '$name') as double";
    case 'ref':
      return "priv(o, '$name')";
    default:
      _fail('line ${f.line}: @_field is only supported for scalar types');
  }
}

String _dartList(String expr, int line) {
  final each = _each(expr);
  if (each != null) {
    final List<String> els = [
      for (final el in each.elements)
        if (_each(el) != null)
          '...${_dartList(el, line)}'
        else if (_sorted(el) != null)
          _fail('line $line: SORTED() is only allowed at the top level')
        else
          el,
    ];
    if (els.length == 1 && !els.first.startsWith('...')) {
      return '[for (final ${each.v} in ${each.container}) ${els.first}]';
    }
    return '[for (final ${each.v} in ${each.container}) ...[${els.join(', ')}]]';
  }
  final String? inner = _sorted(expr);
  if (inner != null) return '(${_dartList(inner, line)}..sort())';
  final String e = expr.trim();
  if (e.startsWith('[')) return e;
  return '[...($e)]';
}

Map<String, String> _dartClassFiles() {
  final Map<String, String> out = {};
  final RegExp decl = RegExp(
      r'^(?:abstract |base |final |sealed )*(?:class|mixin) (\w+)\b',
      multiLine: true);
  for (final e in Directory('lib/src').listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    for (final m in decl.allMatches(e.readAsStringSync())) {
      final String rel = e.path.substring('lib/'.length);
      out.putIfAbsent(m.group(1)!, () => rel);
    }
  }
  return out;
}

String _generateDart(
    List<String> classOrder,
    Map<String, List<_Field>> byClass,
    String skipFunctors,
    List<String> extraImports,
    List<String> cppConstFunctors,
    List<_Field> fields) {
  final Map<String, String> files = _dartClassFiles();
  final Map<String, Set<String>> imports = {};
  for (final key in classOrder) {
    final String cls = byClass[key]!.first.dartClass;
    final String? file = files[cls];
    if (file == null) _fail('Dart class "$cls" not found under lib/src');
    imports.putIfAbsent(file, () => {}).add(cls);
  }
  final List<String> importLines = [
    for (final e in imports.entries)
      "import 'package:verovio_dart/${e.key}' show ${(e.value.toList()..sort()).join(', ')};",
    for (final extra in extraImports)
      "import '${extra.split(' ').first}'${extra.contains(' show ') ? ' show ${extra.split(' show ').last}' : ''};",
  ]..sort();

  final b = StringBuffer();
  b.writeln('// GENERATED FILE — do not edit.');
  b.writeln('// Source: cpp_probe/snapshot/fields.manifest');
  b.writeln('// Regenerate: dart run tool/gen_snapshot_fields.dart');
  b.writeln('//');
  b.writeln('// The C++ twin is cpp_probe/snapshot/vrvsnapshot_fields.inc.');
  b.writeln('// ignore_for_file: unnecessary_cast, unnecessary_parenthesis');
  b.writeln();
  // Deduplicate: an extra import may repeat a class file.
  for (final l in importLines.toSet()) {
    b.writeln(l);
  }
  b.writeln();
  b.writeln("import 'recorder.dart' show Row, dotLocs, priv;");
  b.writeln();
  b.writeln('/// Functors whose checkpoints are skipped (the manifest\'s '
      '`@skip-functors`).');
  b.writeln("final RegExp kSkipFunctors = RegExp(r'$skipFunctors');");
  b.writeln();
  b.writeln('/// C++ classes deriving from ConstFunctor / DocConstFunctor: the '
      'C++ side never');
  b.writeln('/// hooks the const `Object::Process`, so their Dart runs are not '
      'checkpoints.');
  b.writeln('const Set<String> kCppConstFunctors = {');
  for (final n in cppConstFunctors) {
    b.writeln("  '$n',");
  }
  b.writeln('};');
  b.writeln();
  b.writeln('/// Group bits, as in the C++ runtime.');
  b.writeln('const Map<String, int> kGroups = {');
  for (final e in _groups.entries) {
    b.writeln("  '${e.key}': ${e.value},");
  }
  b.writeln('};');
  b.writeln();
  b.writeln(
      '/// Field name -> (group, C++ class, C++ expression), for reports.');
  b.writeln('const Map<String, (String, String, String)> kFieldOrigins = {');
  for (final f in fields) {
    final String expr =
        f.cppExpr.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    b.writeln("  '${f.name}': ('${f.group}', '${f.cppClass}', '$expr'),");
  }
  b.writeln('};');
  b.writeln();
  b.writeln('/// Emits the manifest fields of [bb] into [row] (mirrors '
      '`EmitFields` in the C++).');
  b.writeln('void emitFields(BoundingBox bb, Row row) {');
  for (final key in classOrder) {
    final List<_Field> fs = byClass[key]!;
    final String cls = fs.first.dartClass;
    if (cls == 'BoundingBox') {
      b.writeln('  {');
      b.writeln('    final BoundingBox o = bb;');
    } else {
      b.writeln('  if (bb is $cls) {');
      b.writeln('    final $cls o = bb as $cls;');
    }
    for (final field in fs) {
      final guard = _if(field.dartExpr);
      final _Field f = guard == null
          ? field
          : _Field(field.line, field.group, field.cppClass, field.dartClass,
              field.name, field.type, field.cppExpr, guard.expr);
      final String g = guard == null
          ? '${_groups[f.group]} /* ${f.group} */'
          : '${_groups[f.group]} /* ${f.group} */) && (${guard.cond}';
      final String n = "'${f.name}'";
      final bool priv = f.dartExpr.startsWith('@_');
      final String e = priv ? _dartPriv(f) : f.dartExpr;
      switch (f.type) {
        case 'int':
        case 'enum':
          b.writeln('    if (row.wants($g)) row.i($n, $e);');
        case 'bool':
          b.writeln('    if (row.wants($g)) row.b($n, $e);');
        case 'double':
          b.writeln('    if (row.wants($g)) row.d($n, $e);');
        case 'ref':
          b.writeln('    if (row.wants($g)) row.r($n, $e);');
        case 'frac':
          b.writeln('    if (row.wants($g)) row.f($n, $e);');
        case 'ints':
          b.writeln('    if (row.wants($g)) row.ints($n, '
              '${_dartList(f.dartExpr, f.line)});');
        case 'refs':
          b.writeln('    if (row.wants($g)) row.refs($n, '
              '${_dartList(f.dartExpr, f.line)});');
      }
    }
    b.writeln('  }');
  }
  b.writeln('}');
  return b.toString();
}
