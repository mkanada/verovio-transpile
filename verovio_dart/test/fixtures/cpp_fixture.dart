/// Reader for the C++ reference fixtures produced by `cpp_probe/`.
///
/// A fixture is a JSON Lines file at
/// `test/fixtures/cpp/<task>/<corpus-basename>.jsonl`; its first line is a
/// `_meta` provenance header and every other line is one record emitted by an
/// instrumented Verovio 6.2.0 functor. See `cpp_probe/README.md` for how the
/// files are produced and for the specification of the `path` field, which
/// [cppPath] re-implements on this side — the two implementations are the
/// matching key and must stay in step.
///
/// Nothing here is part of the published package: this file lives under
/// `test/` and is only imported by tests.
library;

import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart'
    show AttNInteger, AttNNumberLike;
import 'package:verovio_dart/src/model/object.dart' as model;

/// Thrown when a fixture cannot be read. Never swallowed into an empty result:
/// a test that passes because its fixture vanished is worse than no test.
class CppFixtureError implements Exception {
  CppFixtureError(this.message);

  final String message;

  @override
  String toString() => 'CppFixtureError: $message';
}

// ---------------------------------------------------------------------------
// Structural path
// ---------------------------------------------------------------------------

/// The structural path of [object], mirroring `vrv::probe::Path` in
/// `cpp_probe/patches/EXEMPLO.patch` (`include/vrv/vrvprobe.h`).
///
/// The path is rooted at the object's `measure` ancestor (inclusive) because
/// page and system membership changes with cast-off. Objects with no measure
/// ancestor are rooted at the topmost object below the `doc`.
///
///     measure[1]/staff[1]/layer[2]/beam[1]/note[3]
///     measure[1]/barLine[right]
String cppPath(model.Object? object) {
  if (object == null) return '';
  final List<String> segments = <String>[];
  model.Object? current = object;
  while (current != null && current.classId != ClassId.doc) {
    segments.add(_cppSegment(current));
    if (current.classId == ClassId.measure) break;
    current = current.parent;
  }
  return segments.reversed.join('/');
}

/// One path segment: `<className>[<key>]`.
String _cppSegment(model.Object object) =>
    '${object.className}[${_cppSegmentKey(object)}]';

/// The key of one path segment, in the precedence order of `probe::SegmentKey`:
/// `@n` for measure/staff/layer, then the role token of an object that is a
/// member of its parent rather than a child of it, then the 1-based index among
/// same-class children.
String _cppSegmentKey(model.Object object) {
  final model.Object? parent = object.parent;

  // 1. @n identity
  switch (object.classId) {
    case ClassId.measure:
      final AttNNumberLike measure = object as AttNNumberLike;
      final String? n = measure.n;
      if (n != null && n.isNotEmpty) return n;
    case ClassId.staff:
    case ClassId.layer:
      final AttNInteger element = object as AttNInteger;
      if (element.hasN) return '${element.n}';
    default:
      break;
  }

  if (parent == null) return '1';

  // 2. member objects: they carry the parent but are not among its children,
  //    so an index cannot tell them apart (they would all collide on 1).
  if (parent.classId == ClassId.measure) {
    final dynamic measure = parent;
    if (identical(object, measure.leftBarLine)) return 'left';
    if (identical(object, measure.rightBarLine)) return 'right';
  } else if (parent.classId == ClassId.layer) {
    // The scoreDef clef/keySig/mensur/meterSig that AlignHorizontally
    // materialises at the start of a layer, and their cautionary twins at the
    // end of it.
    final dynamic layer = parent;
    if (identical(object, layer.staffDefClef) ||
        identical(object, layer.staffDefKeySig) ||
        identical(object, layer.staffDefMensur) ||
        identical(object, layer.staffDefMeterSig) ||
        identical(object, layer.staffDefMeterSigGrp)) {
      return 'staffDef';
    }
    if (identical(object, layer.cautionStaffDefClef) ||
        identical(object, layer.cautionStaffDefKeySig) ||
        identical(object, layer.cautionStaffDefMensur) ||
        identical(object, layer.cautionStaffDefMeterSig)) {
      return 'caution';
    }
  }

  // 3. index among same-class children
  int index = 0;
  final String className = object.className;
  for (final model.Object child in parent.children) {
    if (child.className != className) continue;
    ++index;
    if (identical(child, object)) return '$index';
  }

  // Not a child of its parent and not a known member.
  return '?';
}

// ---------------------------------------------------------------------------
// Records
// ---------------------------------------------------------------------------

/// One line of a fixture: what a C++ functor did to one object.
class CppRecord {
  CppRecord(this.fields, this.lineNumber);

  /// The raw JSON object, so a test can read a field the reader knows nothing
  /// about (`offset`, `selfRight`, the branch of an `if`…).
  final Map<String, dynamic> fields;

  /// 1-based line number in the fixture, for failure messages.
  final int lineNumber;

  String get fn => fields['fn'] as String? ?? '';
  int? get pass => (fields['pass'] as num?)?.toInt();
  String get path => fields['path'] as String? ?? '';
  String get id => fields['id'] as String? ?? '';

  dynamic operator [](String field) => fields[field];

  /// The numeric value of [field], or null when the record does not carry it.
  num? number(String field) => fields[field] as num?;

  /// Like [number] but fails loudly: a missing field is a fixture/patch
  /// mismatch, not a zero.
  num require(String field) {
    final num? value = number(field);
    if (value == null) {
      throw CppFixtureError('record on line $lineNumber ($fn $path) has no '
          'numeric field "$field"; it carries ${fields.keys.join(", ")}');
    }
    return value;
  }

  @override
  String toString() => '$fn${pass == null ? '' : '#$pass'} $path'
      '${id.isEmpty ? '' : ' ($id)'}';
}

/// The `_meta` provenance header of a fixture.
class CppFixtureMeta {
  CppFixtureMeta(this.fields);

  final Map<String, dynamic> fields;

  String get task => fields['task'] as String? ?? '';
  String get source => fields['source'] as String? ?? '';
  int get xmlIdSeed => (fields['xmlIdSeed'] as num?)?.toInt() ?? -1;
  String get verovio => fields['verovio'] as String? ?? '';
  List<String> get patches =>
      (fields['patches'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => '$e')
          .toList();
  String get generated => fields['generated'] as String? ?? '';

  @override
  String toString() => 'task=$task source=$source seed=$xmlIdSeed '
      'patches=${patches.join("+")} generated=$generated';
}

/// One value that the Dart port does not reproduce.
class CppDivergence {
  CppDivergence({
    required this.record,
    required this.field,
    required this.expected,
    required this.actual,
  });

  final CppRecord record;
  final String field;
  final num expected;
  final num? actual;

  @override
  String toString() => '${record.fn}'
      '${record.pass == null ? '' : ' pass ${record.pass}'} '
      '${record.path} [$field] C++=$expected Dart=${actual ?? "<ausente>"}'
      '${record.id.isEmpty ? '' : '  (@xml:id ${record.id})'}';
}

// ---------------------------------------------------------------------------
// Fixture
// ---------------------------------------------------------------------------

/// A loaded `.jsonl` fixture.
class CppFixture {
  CppFixture._(this.file, this.meta, this.records);

  /// Path of the file this was read from, for failure messages.
  final String file;

  final CppFixtureMeta meta;
  final List<CppRecord> records;

  /// Loads the fixture of [task] for the corpus file [corpusPath] (given
  /// either as `test/corpus/note/note-001.mei` or as `note-001.mei`).
  ///
  /// Throws [CppFixtureError] — naming the command that regenerates it — when
  /// the file is missing. It never returns an empty fixture instead.
  factory CppFixture.load(String task, String corpusPath) {
    final String basename = corpusPath.split('/').last;
    return CppFixture.loadFile('test/fixtures/cpp/$task/$basename.jsonl',
        task: task, corpusPath: corpusPath);
  }

  /// Loads a fixture from an explicit path.
  factory CppFixture.loadFile(String path, {String? task, String? corpusPath}) {
    final File handle = File(path);
    if (!handle.existsSync()) {
      throw CppFixtureError('fixture ausente: $path\n'
          '  Regenere com, a partir da raiz do workspace:\n'
          '    cpp_probe/build.sh ${task ?? "<id>"} && \\\n'
          '    cpp_probe/run.sh ${task ?? "<id>"} '
          '${corpusPath ?? "<entrada.mei>"} verovio_dart/$path');
    }

    final List<String> lines = const LineSplitter()
        .convert(handle.readAsStringSync())
        .where((String line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      throw CppFixtureError('fixture vazio: $path');
    }

    final dynamic head = _decode(path, 1, lines.first);
    if (head is! Map<String, dynamic> || head['_meta'] == null) {
      throw CppFixtureError('a primeira linha de $path não é o cabeçalho '
          '"_meta" de proveniência exigido por cpp_probe/README.md');
    }
    final CppFixtureMeta meta =
        CppFixtureMeta((head['_meta'] as Map).cast<String, dynamic>());

    final List<CppRecord> records = <CppRecord>[];
    for (int i = 1; i < lines.length; ++i) {
      final dynamic value = _decode(path, i + 1, lines[i]);
      if (value is! Map<String, dynamic>) {
        throw CppFixtureError('$path linha ${i + 1}: registro não é um objeto');
      }
      records.add(CppRecord(value, i + 1));
    }
    if (records.isEmpty) {
      throw CppFixtureError(
          '$path só tem o cabeçalho "_meta": nenhum registro. '
          'O patch não instrumenta nada que este arquivo exercite.');
    }

    return CppFixture._(path, meta, records);
  }

  static dynamic _decode(String path, int lineNumber, String line) {
    try {
      return jsonDecode(line);
    } on FormatException catch (error) {
      throw CppFixtureError('$path linha $lineNumber: JSON inválido — $error');
    }
  }

  /// Every record matching the given filters, in file order.
  List<CppRecord> where({
    String? fn,
    int? pass,
    String? path,
    bool Function(CppRecord record)? test,
  }) {
    return records.where((CppRecord record) {
      if (fn != null && record.fn != fn) return false;
      if (pass != null && record.pass != pass) return false;
      if (path != null && record.path != path) return false;
      if (test != null && !test(record)) return false;
      return true;
    }).toList();
  }

  /// The one record matching the filters. Throws when there is none, and when
  /// there is more than one — an ambiguous key silently comparing the wrong
  /// record is the failure this guards against.
  CppRecord single({
    String? fn,
    int? pass,
    String? path,
    bool Function(CppRecord record)? test,
  }) {
    final List<CppRecord> found =
        where(fn: fn, pass: pass, path: path, test: test);
    if (found.isEmpty) {
      throw CppFixtureError('$file: nenhum registro para '
          'fn=$fn pass=$pass path=$path');
    }
    if (found.length > 1) {
      throw CppFixtureError('$file: ${found.length} registros para '
          'fn=$fn pass=$pass path=$path — refine o filtro '
          '(as linhas são ${found.map((CppRecord r) => r.lineNumber).join(", ")})');
    }
    return found.single;
  }

  /// The distinct `path` values of the matching records, in file order.
  List<String> paths({String? fn, int? pass}) {
    final List<String> seen = <String>[];
    for (final CppRecord record in where(fn: fn, pass: pass)) {
      if (!seen.contains(record.path)) seen.add(record.path);
    }
    return seen;
  }

  /// Compares [field] of every matching record against the Dart value that
  /// [actual] produces for that record, and returns **the list of
  /// divergences** — the message is the product here, not a boolean.
  ///
  /// [actual] returns null when the Dart side has no object at the record's
  /// `path`; that counts as a divergence and is reported as `<ausente>`.
  ///
  /// Throws when no record matches: comparing nothing and reporting success is
  /// the failure mode this whole mechanism exists to prevent.
  List<CppDivergence> compare({
    required String field,
    required num? Function(CppRecord record) actual,
    String? fn,
    int? pass,
    bool Function(CppRecord record)? test,
    num epsilon = 0,
  }) {
    final List<CppRecord> selected = where(fn: fn, pass: pass, test: test);
    if (selected.isEmpty) {
      throw CppFixtureError('$file: nenhum registro para fn=$fn pass=$pass — '
          'não há o que comparar. Confira o nome do functor e a passada.');
    }
    final List<CppDivergence> divergences = <CppDivergence>[];
    for (final CppRecord record in selected) {
      final num expected = record.require(field);
      final num? value = actual(record);
      if (value == null || (value - expected).abs() > epsilon) {
        divergences.add(CppDivergence(
            record: record, field: field, expected: expected, actual: value));
      }
    }
    return divergences;
  }

  /// A one-line summary for a report: `N valores, M divergem`.
  String summary(String field, List<CppDivergence> divergences,
      {String? fn, int? pass}) {
    final int total = where(fn: fn, pass: pass).length;
    return '$field: $total valores comparados, '
        '${total - divergences.length} batem, ${divergences.length} divergem';
  }
}
