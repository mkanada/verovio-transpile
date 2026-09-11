/// State-snapshot recorder — the Dart twin of
/// `cpp_probe/snapshot/vrvsnapshot.cpp`.
///
/// Installed on [FunctorBase.checkpointHook], it takes a checkpoint after
/// every top-level functor run and every page draw started outside a functor,
/// and writes, at the depth the [SnapshotConfig] asks for, the same JSON Lines
/// the instrumented C++ binary writes: the checkpoint sequence, a digest per
/// checkpoint, and the rows of every entity. Checkpoint labels, the key scheme
/// and the canonical form the digest hashes are mirrored line by line from the
/// C++ — change both or neither.
///
/// Lives under `tool/` (not `lib/`) on purpose: private fields are read through
/// `dart:mirrors`, which must never reach the web-safe package.
///
/// Support code for the port — not a port of any C++ file.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';
import 'dart:typed_data';

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/bounding_box.dart' show BoundingBox;
import 'package:verovio_dart/src/core/fraction.dart' show Fraction;
import 'package:verovio_dart/src/core/vrvdef.dart' show ClassId;
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show FloatingCurvePositioner;
import 'package:verovio_dart/src/layout/functor.dart' show FunctorBase;
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, AlignmentReference, MeasureAligner;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment, SystemAligner;
import 'package:verovio_dart/src/model/atts/atts_shared.dart'
    show AttNInteger, AttNNumberLike;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Layer, Measure, Staff;
import 'package:verovio_dart/src/model/doc.dart' show Page;
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show Dots;
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/model/staffdef_drawing_interface.dart'
    show StaffDefDrawingInterface;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

import 'fields.g.dart';

// ---------------------------------------------------------------------------
// Configuration — the command-line axes of both tools
// ---------------------------------------------------------------------------

/// What to dump: the mode, the field groups, and the three filters.
class SnapshotConfig {
  SnapshotConfig({
    this.mode = 'digest',
    this.groups = 3,
    this.at,
    this.path = '',
    this.classes = const {},
    this.exclude = const {},
  });

  /// `seq` | `digest` | `full`.
  final String mode;

  /// Bit set of [kGroups].
  final int groups;

  /// The `--at` pattern (full match against `Name#k` or `@seq`), or null.
  final String? at;
  final String path;
  final Set<String> classes;
  final Set<String> exclude;

  late final RegExp? _atRegExp = at == null ? null : RegExp('^(?:$at)\$');

  /// The `key:<text>` entries of [exclude].
  late final List<String> _excludeKeys = [
    for (final e in exclude)
      if (e.startsWith('key:')) e.substring(4)
  ];

  /// Default exclusions shared with `cpp_probe/snapshot.sh`: the entries of
  /// `cpp_probe/snapshot/exclude.list` (comments and blank lines dropped).
  static Set<String> readExcludeList(String path) {
    final File file = File(path);
    if (!file.existsSync()) return {};
    return {
      for (final line in file.readAsLinesSync())
        if (line.split('#').first.trim().isNotEmpty)
          line.split('#').first.trim()
    };
  }

  /// `--nivel` presets, shared with `cpp_probe/snapshot.sh`.
  static const Map<int, (String, String)> levels = {
    0: ('seq', 'bb,pos'),
    1: ('digest', 'bb,pos'),
    2: ('full', 'bb,pos'),
    3: ('full', 'bb,pos,link,layout'),
    4: ('full', 'all'),
  };

  /// Parses a comma list of group names (or `all`) into bits.
  static int parseGroups(String text) {
    int bits = 0;
    for (final g in text.split(',').map((s) => s.trim())) {
      if (g.isEmpty) continue;
      if (g == 'all') {
        bits |= kGroups.values.fold(0, (a, b) => a | b);
      } else if (kGroups.containsKey(g)) {
        bits |= kGroups[g]!;
      } else {
        throw FormatException('unknown group "$g"');
      }
    }
    return bits;
  }
}

// ---------------------------------------------------------------------------
// Recorder
// ---------------------------------------------------------------------------

/// Takes checkpoints while installed and writes them to [out].
class SnapshotRecorder {
  SnapshotRecorder(this.config, File out, {required String source})
      : _out = out.openSync(mode: FileMode.write) {
    _out.writeStringSync(
        '{"_meta":{"side":"dart","source":${jsonEncode(source)},'
        '"mode":${jsonEncode(config.mode)},"groups":${config.groups},'
        '"at":${jsonEncode(config.at ?? '')},"path":${jsonEncode(config.path)},'
        '"class":${jsonEncode((config.classes.toList()..sort()).join(','))},'
        '"exclude":${jsonEncode((config.exclude.toList()..sort()).join(','))}}}\n');
  }

  final SnapshotConfig config;
  final RandomAccessFile _out;
  int _seq = 0;
  final Map<String, int> _occurrences = {};

  /// Number of checkpoints taken so far.
  int get checkpoints => _seq;

  void install() => FunctorBase.checkpointHook = checkpoint;

  /// Uninstalls the hook and closes the output file.
  void close() {
    if (FunctorBase.checkpointHook == checkpoint) {
      FunctorBase.checkpointHook = null;
    }
    _out.closeSync();
  }

  /// Mirrors `vrv::snapshot::Checkpoint`.
  void checkpoint(String label, model.Object object) {
    if (kSkipFunctors.hasMatch(label) || kCppConstFunctors.contains(label)) {
      return;
    }
    final int seq = ++_seq;
    final int occurrence = _occurrences[label] = (_occurrences[label] ?? 0) + 1;

    model.Object root = object;
    while (root.parent != null) {
      root = root.parent!;
    }

    final StringBuffer line = StringBuffer()
      ..write('{"cp":$seq,"fn":${jsonEncode(label)},"k":$occurrence,'
          '"on":${jsonEncode(_classLabel(object))},'
          '"root":${jsonEncode(_classLabel(root))}');

    bool selected = config.mode != 'seq';
    final RegExp? at = config._atRegExp;
    if (selected && at != null) {
      selected = at.hasMatch('$label#$occurrence') || at.hasMatch('@$seq');
    }
    if (!selected) {
      line.write('}\n');
      _out.writeStringSync(line.toString());
      return;
    }

    final _Walker walker = _Walker()..walk(root);

    int digest = 0;
    int count = 0;
    final StringBuffer rows = StringBuffer();
    for (final _Entity entity in walker.entities) {
      if (config.classes.isNotEmpty && !config.classes.contains(entity.cls)) {
        continue;
      }
      if (config.path.isNotEmpty && !entity.key.contains(config.path)) {
        continue;
      }
      if (config._excludeKeys.any(entity.key.contains)) continue;
      final Row row = Row._(entity, config, walker);
      emitFields(entity.bb, row);
      digest += row.hash; // wraps at 64 bits on the VM, like the uint64_t sum
      ++count;
      if (config.mode == 'full') rows.write(row.jsonLine(seq));
    }
    line.write(',"rows":$count,"digest":"${_hex64(digest)}"}\n');
    _out.writeStringSync(line.toString());
    _out.writeStringSync(rows.toString());
  }
}

// ---------------------------------------------------------------------------
// Walker — mirrors `vrv::snapshot::Walker`
// ---------------------------------------------------------------------------

class _Entity {
  _Entity(this.bb, this.key, this.cls);
  final BoundingBox bb;
  final String key;
  final String cls;
}

String _classLabel(model.Object object) =>
    object.classId == ClassId.doc ? 'doc' : object.className;

/// `<class>[<@n or index>]` — the probe::Path segment, computed top-down.
String _segment(model.Object object, int index) {
  String key = '';
  if (object.classId == ClassId.measure) {
    final String? n = (object as AttNNumberLike).n;
    if (n != null && n.isNotEmpty) key = n;
  } else if (object.classId == ClassId.staff ||
      object.classId == ClassId.layer) {
    final AttNInteger e = object as AttNInteger;
    if (e.hasN) key = '${e.n}';
  }
  if (key.isEmpty) key = '$index';
  return '${_classLabel(object)}[$key]';
}

String _alignmentSegment(Alignment alignment) {
  final Fraction time = alignment.getTime();
  return 'alignment[${time.numerator}/${time.denominator}:'
      '${alignment.getType().value}]';
}

class _Walker {
  final List<_Entity> entities = [];
  final Map<Object, int> _index = Map.identity();
  final Map<String, int> _keyCount = {};
  final List<(Measure, String)> _measures = [];
  final List<(System, String)> _systems = [];

  void walk(model.Object root) {
    _visitObject(root, root.classId == ClassId.doc ? 'doc' : _segment(root, 1));
    // Aligners last: positioner keys are built from the keys of their objects.
    for (final (Measure m, String key) in _measures) {
      _visitMeasureAligner(m, key);
    }
    for (final (System s, String key) in _systems) {
      _visitSystemAligner(s, key);
    }
  }

  String keyOf(Object? target) {
    if (target == null) return 'null';
    final int? i = _index[target];
    // Not in the walked tree: never inspected (the C++ may hold a dangling
    // pointer there), so both sides say only "~".
    return i != null ? entities[i].key : '~';
  }

  bool _seen(Object bb) => _index.containsKey(bb);

  /// Registers an entity; a repeated key gets "#2", "#3"… in walk order.
  String _add(BoundingBox bb, String key, String cls) {
    final int count = _keyCount[key] = (_keyCount[key] ?? 0) + 1;
    if (count > 1) key = '$key#$count';
    _index[bb] = entities.length;
    entities.add(_Entity(bb, key, cls));
    return key;
  }

  void _visitObject(model.Object object, String proposedKey) {
    if (_seen(object)) return;
    final String key = _add(object, proposedKey, _classLabel(object));
    // Children of the doc are keyed like probe::Path (no "doc/" prefix);
    // measures restart the key (probe::Path is rooted at the measure).
    final String prefix = object.classId == ClassId.doc ? '' : key;
    final Map<String, int> counts = {};
    for (final model.Object child in object.children) {
      final String label = _classLabel(child);
      final int index = counts[label] = (counts[label] ?? 0) + 1;
      final String segment = _segment(child, index);
      _visitObject(
          child,
          (child.classId == ClassId.measure || prefix.isEmpty)
              ? segment
              : '$prefix/$segment');
    }
    _visitMembers(object, key);
  }

  void _visitMember(model.Object? member, String parentKey, String role) {
    if (member == null) return;
    _visitObject(member, '$parentKey/${_classLabel(member)}[$role]');
  }

  /// Objects owned by a member of their parent rather than by its children.
  void _visitMembers(model.Object object, String key) {
    if (object is Measure) {
      _visitMember(object.leftBarLine, key, 'left');
      _visitMember(object.rightBarLine, key, 'right');
      _visitMember(object.drawingScoreDef, key, 'drawing');
      _measures.add((object, key));
    }
    if (object is Layer) {
      _visitMember(object.staffDefClef, key, 'staffDef');
      _visitMember(object.staffDefKeySig, key, 'staffDef');
      _visitMember(object.staffDefMensur, key, 'staffDef');
      _visitMember(object.staffDefMeterSig, key, 'staffDef');
      _visitMember(object.staffDefMeterSigGrp, key, 'staffDef');
      _visitMember(object.cautionStaffDefClef, key, 'caution');
      _visitMember(object.cautionStaffDefKeySig, key, 'caution');
      _visitMember(object.cautionStaffDefMensur, key, 'caution');
      _visitMember(object.cautionStaffDefMeterSig, key, 'caution');
    }
    if (object is System) {
      _visitMember(object.drawingScoreDef, key, 'drawing');
      _systems.add((object, key));
    }
    if (object is Page) {
      _visitMember(object.drawingScoreDef, key, 'drawing');
    }
    if (object is StaffDefDrawingInterface) {
      final StaffDefDrawingInterface i = object as StaffDefDrawingInterface;
      _visitMember(i.getCurrentClef(), key, 'current');
      _visitMember(i.getCurrentKeySig(), key, 'current');
      _visitMember(i.getCurrentMensur(), key, 'current');
      _visitMember(i.getCurrentMeterSig(), key, 'current');
      _visitMember(i.getCurrentMeterSigGrp(), key, 'current');
      _visitMember(i.getCurrentProport(), key, 'current');
    }
  }

  void _visitMeasureAligner(Measure measure, String measureKey) {
    final MeasureAligner aligner = measure.measureAligner;
    if (_seen(aligner)) return;
    _add(aligner, '$measureKey/measureAligner', 'measureAligner');
    for (final model.Object child in aligner.children) {
      if (child is Alignment) {
        _visitAlignment(child, '$measureKey/${_alignmentSegment(child)}');
      }
    }
  }

  void _visitAlignment(Alignment alignment, String proposedKey) {
    if (_seen(alignment)) return;
    final String key = _add(alignment, proposedKey, 'alignment');
    for (final model.Object child in alignment.children) {
      if (child is! AlignmentReference || _seen(child)) continue;
      // References only: the layer elements below are owned by their layer.
      _add(child, '$key/ref[${child.hasN ? '${child.n}' : '?'}]',
          'alignmentReference');
    }
    final graceAligners = alignment.getGraceAligners();
    // The C++ std::map iterates in key order.
    for (final int n in graceAligners.keys.toList()..sort()) {
      final graceAligner = graceAligners[n]!;
      if (_seen(graceAligner)) continue;
      final String graceKey =
          _add(graceAligner, '$key/graceAligner[$n]', 'graceAligner');
      for (final model.Object child in graceAligner.children) {
        if (child is Alignment) {
          _visitAlignment(child, '$graceKey/${_alignmentSegment(child)}');
        }
      }
    }
  }

  void _visitSystemAligner(System system, String systemKey) {
    final SystemAligner aligner = system.systemAligner;
    if (_seen(aligner)) return;
    _add(aligner, '$systemKey/systemAligner', 'systemAligner');
    for (final model.Object child in aligner.children) {
      if (child is! StaffAlignment || _seen(child)) continue;
      final Staff? staff = child.getStaff();
      // C++ GetN() returns MEI_UNSET where Dart has null.
      final String n = staff != null ? '${staff.n ?? meiUnset}' : 'none';
      final String staffKey =
          _add(child, '$systemKey/staffAlignment[$n]', 'staffAlignment');
      for (final positioner in child.getFloatingPositioners()) {
        if (_seen(positioner)) continue;
        final String cls = positioner is FloatingCurvePositioner
            ? 'floatingCurvePositioner'
            : 'floatingPositioner';
        _add(positioner, '$staffKey/$cls[${keyOf(positioner.getObject())}]',
            cls);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Row — mirrors `vrv::snapshot::Row`
// ---------------------------------------------------------------------------

/// One entity's fields, as JSON and as the canonical text the digest hashes.
class Row {
  Row._(_Entity entity, this._config, this._walker)
      : _key = entity.key,
        _cls = entity.cls {
    _canonical
      ..write(entity.key)
      ..write('\x1f')
      ..write(entity.cls);
  }

  final SnapshotConfig _config;
  final _Walker _walker;
  final String _key;
  final String _cls;
  final StringBuffer _canonical = StringBuffer();
  final StringBuffer _json = StringBuffer();

  bool wants(int group) => (_config.groups & group) != 0;

  void i(String name, int value) => _add(name, '$value', '$value');

  void b(String name, bool value) =>
      _add(name, value ? '1' : '0', value ? 'true' : 'false');

  void d(String name, double value) {
    if (value.isNaN) {
      _add(name, 'dnan', '"nan"');
      return;
    }
    final double normalized = value == 0.0 ? 0.0 : value; // -0.0 == 0.0
    final ByteData bits = ByteData(8)..setFloat64(0, normalized);
    final String canonical =
        'd${bits.getUint32(0).toRadixString(16).padLeft(8, '0')}'
        '${bits.getUint32(4).toRadixString(16).padLeft(8, '0')}';
    final String json = value.isInfinite
        ? (value > 0 ? '"inf"' : '"-inf"')
        : jsonEncode(normalized);
    _add(name, canonical, json);
  }

  void r(String name, Object? target) {
    final String key = _walker.keyOf(target);
    _add(name, key, target == null ? 'null' : jsonEncode(key));
  }

  void refs(String name, Iterable<Object?> targets) {
    final List<String> keys = [for (final t in targets) _walker.keyOf(t)];
    final List<String> json = [
      for (final t in targets) t == null ? 'null' : jsonEncode(_walker.keyOf(t))
    ];
    _add(name, '[${keys.join(',')}]', '[${json.join(',')}]');
  }

  void f(String name, Fraction value) {
    final int n = value.numerator;
    final int d = value.denominator;
    _add(name, '$n/$d', '[$n,$d]');
  }

  void ints(String name, List<int> values) {
    final String text = '[${values.join(',')}]';
    _add(name, text, text);
  }

  int get hash => _fnv64(utf8.encode(_canonical.toString()));

  String jsonLine(int cp) =>
      '{"cp":$cp,"key":${jsonEncode(_key)},"class":${jsonEncode(_cls)}$_json}\n';

  void _add(String name, String canonical, String json) {
    if (_config.exclude.contains(name) ||
        _config.exclude.contains('$_cls.$name')) {
      return;
    }
    _canonical
      ..write('\x1e')
      ..write(name)
      ..write('=')
      ..write(canonical);
    _json
      ..write(',"')
      ..write(name)
      ..write('":')
      ..write(json);
  }
}

/// FNV-1a, 64 bits (VM ints wrap at 64 bits, like the C++ uint64_t).
int _fnv64(List<int> bytes) {
  int hash = 0xcbf29ce484222325;
  for (final int b in bytes) {
    hash ^= b;
    hash *= 0x100000001b3;
  }
  return hash;
}

String _hex64(int value) =>
    ((value >> 32) & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0') +
    (value & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');

// ---------------------------------------------------------------------------
// Helpers named by the manifest
// ---------------------------------------------------------------------------

final Map<(Type, String), Symbol> _privateFields = {};

/// Reads the private field [name] of [object] through `dart:mirrors` (the
/// manifest's `@_name`). Searches the class chain and its mixins.
Object? priv(Object object, String name) {
  final InstanceMirror mirror = reflect(object);
  final Symbol symbol = _privateFields[(object.runtimeType, name)] ??=
      _findField(mirror.type, name, object);
  return mirror.getField(symbol).reflectee;
}

Symbol _findField(ClassMirror? type, String name, Object object) {
  for (ClassMirror? c = type; c != null; c = c.superclass) {
    for (final ClassMirror declaring in {c, c.mixin}) {
      for (final MapEntry<Symbol, DeclarationMirror> e
          in declaring.declarations.entries) {
        if (e.value is VariableMirror && MirrorSystem.getName(e.key) == name) {
          return e.key;
        }
      }
    }
  }
  throw StateError('snapshot: no field $name on ${object.runtimeType} '
      '(fix cpp_probe/snapshot/fields.manifest)');
}

/// Mirrors `DotLocs`: per staff (sorted by @n) n, count, locs…
List<int> dotLocs(Dots dots) {
  final List<(int, List<int>)> perStaff = [
    for (final e in dots.getMapOfDotLocs().entries)
      (
        e.key is Staff ? ((e.key as Staff).n ?? meiUnset) : -1,
        e.value.toList()..sort()
      ),
  ];
  perStaff.sort((a, b) {
    if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
    for (int i = 0; i < a.$2.length && i < b.$2.length; ++i) {
      if (a.$2[i] != b.$2[i]) return a.$2[i].compareTo(b.$2[i]);
    }
    return a.$2.length.compareTo(b.$2.length);
  });
  return [
    for (final (int n, List<int> locs) in perStaff) ...[
      n,
      locs.length,
      ...locs
    ],
  ];
}
