// Generator for the MEI attribute classes (libmei/dist/atts_*).
//
// Reads the original Verovio libmei sources (atttypes.h, attconverter.cpp,
// addons/att.cpp and atts_<module>.h/.cpp) and emits idiomatic Dart:
//
//   lib/src/model/atts/mei_enums.dart        - all MEI data enums
//   lib/src/model/atts/atts_conversion.dart  - string <-> enum converters
//   lib/src/model/atts/atts_<module>.dart    - one mixin per Att class
//
// Hand-written companions used by the generated code live in
// lib/src/model/atts/mei_values.dart.
//
// Usage (from the verovio_dart directory):
//   dart run tool/gen_atts.dart [path-to-libmei-dist]
import 'dart:io';

final String defaultDistPath = '../origin/src/libmei/dist';

// ---------------------------------------------------------------------------
// Parsing structures
// ---------------------------------------------------------------------------

class EnumMember {
  EnumMember(this.id, this.value);
  final String id;
  final int value;
}

class MeiEnum {
  MeiEnum(this.name, this.members);
  final String name;
  final List<EnumMember> members;
}

class AttMember {
  AttMember(this.attrName, this.cppName, this.cppType) {
    dartName = _sanitizeField(lowerCamel(cppName));
    final conv = _resolveConverters('', this);
    readFn = conv[0];
    writeFn = conv[1];
  }
  final String cppType;

  /// The MEI attribute name (e.g. "clef.line").
  String attrName;

  /// The C++ member name without the leading "m_" (e.g. "clefLine").
  final String cppName;

  /// The sanitized Dart field name.
  late String dartName;

  late String readFn;
  late String writeFn;
}

/// "ClefShape" -> "clefShape" (keeps inner capitals).
String _lowerFirstPreservingCase(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

String _sanitizeField(String s) => sanitizeIdent(s
    .replaceAll('.', '_')
    .replaceAllMapped(RegExp(r'^[0-9]'), (m) => 'n${m.group(0)}'));

class AttClass {
  AttClass(this.name, this.module);
  final String name;
  final String module;
  final List<AttMember> members = [];
}

// ---------------------------------------------------------------------------
// Naming helpers
// ---------------------------------------------------------------------------

String lowerCamel(String s) {
  final parts = s.split('_');
  final out = StringBuffer(parts.first.toLowerCase());
  for (int i = 1; i < parts.length; ++i) {
    if (parts[i].isEmpty) continue;
    out.write(parts[i][0].toUpperCase());
    out.write(parts[i].substring(1).toLowerCase());
  }
  return out.toString();
}

const Set<String> _reserved = {
  'assert', 'break', 'case', 'catch', 'class', 'const', 'continue',
  'default', 'do', 'else', 'enum', 'extends', 'false', 'final', 'finally',
  'for', 'if', 'in', 'is', 'new', 'null', 'rethrow', 'return', 'super',
  'switch', 'this', 'throw', 'true', 'try', 'var', 'void', 'while', 'with',
};

String sanitizeIdent(String s) {
  var id = s;
  // Leading underscores would make the enum constant library-private.
  if (RegExp(r'^[0-9_]').hasMatch(id)) id = 'n$id';
  if (_reserved.contains(id)) id = '${id}Value';
  return id;
}

/// data_ACCIDENTAL_GESTURAL_basic -> AccidentalGesturalBasic
String enumDartName(String cppName) {
  var n = cppName;
  if (n.startsWith('data_')) n = n.substring(5);
  return n
      .split('_')
      .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1).toLowerCase())
      .join();
}

/// ACCIDENTAL_WRITTEN_1qf with enum data_ACCIDENTAL_WRITTEN -> "q1qf"-like id
String memberValueName(String enumCppName, String memberId) {
  final prefix = enumCppName.startsWith('data_')
      ? enumCppName.substring(5)
      : enumCppName;
  var rest = memberId;
  if (rest.length >= prefix.length &&
      rest.substring(0, prefix.length).toLowerCase() == prefix.toLowerCase()) {
    rest = rest.substring(prefix.length);
    if (rest.startsWith('_')) rest = rest.substring(1);
  } else {
    // Fall back: strip everything up to and including the last prefix word.
    final lastWord = prefix.split('_').last;
    final idx = rest.indexOf('${lastWord}_');
    if (idx >= 0) rest = rest.substring(idx + lastWord.length + 1);
  }
  if (rest.isEmpty || rest.toLowerCase() == 'none') return 'none';
  return sanitizeIdent(lowerCamel(rest));
}

String cap(String s) => s[0].toUpperCase() + s.substring(1);

// ---------------------------------------------------------------------------
// Type mapping tables
// ---------------------------------------------------------------------------

const Map<String, String> specialClassTypes = {
  'data_FONTSIZE': 'FontSize',
  'data_HEADSHAPE': 'HeadShape',
  'data_MEASUREMENTSIGNED': 'MeasurementSigned',
  'data_MEASUREMENTUNSIGNED': 'MeasurementUnsigned',
  'data_LINEWIDTH': 'LineWidth',
  'data_MIDIVALUE_NAME': 'MidiValueName',
  'data_MIDIVALUE_PAN': 'MidiValuePan',
  'data_PLACEMENT': 'Placement',
  'data_KEYSIGNATURE': 'KeySignature',
  'data_MEASUREBEAT': 'MeasureBeat',
  'data_METERCOUNT_pair': 'MeterCountPair',
};

const Map<String, List<String>> specialConverters = {
  // cppType -> [readFn, writeFn]
  'data_FONTSIZE': ['strToFontsize', 'fontsizeToStr'],
  'data_HEADSHAPE': ['strToHeadshape', 'headshapeToStr'],
  'data_MEASUREMENTSIGNED': ['strToMeasurementsigned', 'measurementsignedToStr'],
  'data_MEASUREMENTUNSIGNED': [
    'strToMeasurementunsigned',
    'measurementunsignedToStr'
  ],
  'data_LINEWIDTH': ['strToLinewidth', 'linewidthToStr'],
  'data_MIDIVALUE_NAME': ['strToMidivalueName', 'midivalueNameToStr'],
  'data_MIDIVALUE_PAN': ['strToMidivaluePan', 'midivaluePanToStr'],
  'data_PLACEMENT': ['strToPlacement', 'placementToStr'],
  'data_KEYSIGNATURE': ['strToKeysignature', 'keysignatureToStr'],
  'data_MEASUREBEAT': ['strToMeasurebeat', 'measurebeatToStr'],
  'data_METERCOUNT_pair': ['strToMetercountPair', 'metercountPairToStr'],
};

/// cpp simple type -> [dart nullable type, readFn, writeFn]
const Map<String, List<String>> simpleTypes = {
  'data_DURATION': ['MeiDuration?', 'strToDuration', 'durationToStr'],
  'char': ['int?', 'strToInt', 'intToStr'],
  'data_HEXNUM': ['int?', 'strToHexnum', 'hexnumToStr'],
  'int': ['int?', 'strToInt', 'intToStr'],
  'signed char': ['int?', 'strToInt', 'intToStr'],
  'char32_t': ['int?', 'strToHexnum', 'hexnumToStr'],
  'double': ['double?', 'strToDbl', 'dblToStr'],
  'std::string': ['String?', 'identityStr', 'identityStr'],
  'data_VU': ['double?', 'strToDbl', 'vuToStr'],
  'data_DEGREES': ['double?', 'strToDbl', 'degreesToStr'],
  'data_PERCENT': ['double?', 'strToDbl', 'percentToStr'],
  'data_PERCENT_LIMITED': ['double?', 'strToDbl', 'percentLimitedToStr'],
  'data_PERCENT_LIMITED_SIGNED': [
    'double?',
    'strToDbl',
    'percentLimitedSignedToStr'
  ],
  'data_FONTSIZENUMERIC': ['double?', 'strToDbl', 'fontsizenumericToStr'],
  'data_MIDIBPM': ['int?', 'strToInt', 'midibpmToStr'],
  'data_MIDICHANNEL': ['int?', 'strToInt', 'midichannelToStr'],
  'data_MIDIMSPB': ['int?', 'strToInt', 'midimspbToStr'],
  'data_MIDIVALUE': ['int?', 'strToInt', 'midivalueToStr'],
  'data_NCNAME': ['String?', 'identityStr', 'ncnameToStr'],
  'data_OCTAVE': ['int?', 'strToInt', 'octaveToStr'],
  'data_BOOLEAN': ['bool?', 'strToBoolean', 'booleanToStr'],
};

/// cpp list type -> [dart element type, readFn, writeFn]
const Map<String, List<String>> listTypes = {
  'data_BULGE': ['BulgePair', 'strToBulge', 'bulgeToStr'],
  'data_ARTICULATION_List': ['Articulation', 'strToArticulationList', 'articulationListToStr'],
  'xsdAnyURI_List': ['String', 'strToXsdAnyURIList', 'xsdAnyURIListToStr'],
  'xsdPositiveInteger_List': ['int', 'strToXsdPositiveIntegerList', 'xsdPositiveIntegerListToStr'],
  'std::vector<std::string>': ['String', 'strToStringList', 'stringListToStr'],
  'std::vector<int>': ['int', 'strToIntList', 'intListToStr'],
  'std::vector<std::pair<double, double>>': ['BulgePair', 'strToBulge', 'bulgeToStr'],
};

// ---------------------------------------------------------------------------
// Global registries filled while parsing converters
// ---------------------------------------------------------------------------

/// data_TYPE -> enum definition
Map<String, MeiEnum> enums = {};

/// data_TYPE -> true when a string<->value table was found
Set<String> enumsWithTable = {};

final List<String> warnings = [];

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final distPath = args.isNotEmpty ? args[0] : defaultDistPath;
  final dist = Directory(distPath);
  if (!dist.existsSync()) {
    stderr.writeln('libmei dist directory not found: $distPath');
    exit(1);
  }

  enums = parseEnums(File('$distPath/atttypes.h').readAsStringSync());
  final addonDefs = File('$distPath/../addons/attdef.h').readAsStringSync();
  enums.addAll(parseEnums(addonDefs));
  stdout.writeln('Parsed ${enums.length} enums');

  parseConverterTables(distPath);
  stdout.writeln('Found string tables for ${enumsWithTable.length} enums');

  emitEnums();
  emitConversion();

  const modules = [
    'analytical', 'cmn', 'cmnornaments', 'critapp', 'edittrans',
    'externalsymbols', 'facsimile', 'figtable', 'fingering', 'gestural',
    'harmony', 'header', 'mei', 'mensural', 'midi', 'neumes', 'pagebased',
    'performance', 'shared', 'stringtab', 'usersymbols', 'visual',
  ];

  int totalClasses = 0;
  int totalMembers = 0;
  for (final module in modules) {
    final hFile = File('$distPath/atts_$module.h');
    final cppFile = File('$distPath/atts_$module.cpp');
    if (!hFile.existsSync()) continue;

    final classes = parseClasses(hFile.readAsStringSync(), module);
    final cpp = cppFile.existsSync() ? cppFile.readAsStringSync() : '';
    applyReadInfo(classes, cpp);

    totalClasses += classes.length;
    totalMembers += classes.fold(0, (n, c) => n + c.members.length);
    emitModule(module, classes);
  }
  stdout.writeln('Generated $totalClasses att classes ($totalMembers members)');
  if (warnings.isNotEmpty) {
    stderr.writeln('${warnings.length} warnings:');
    warnings.take(30).forEach(stderr.writeln);
  }
}

// ---------------------------------------------------------------------------
// Enums & converters parsing
// ---------------------------------------------------------------------------

Map<String, MeiEnum> parseEnums(String src) {
  final result = <String, MeiEnum>{};
  final blockRe = RegExp(r'enum\s+(\w+)([^{]*)\{(.*?)\};', dotAll: true);
  for (final m in blockRe.allMatches(src)) {
    var name = m.group(1)!;
    if (name == 'class') {
      // C++ `enum class X` - skip (X is ported by hand when needed).
      continue;
    }
    final body = m.group(3)!;
    final members = <EnumMember>[];
    int next = 0;
    for (final rawPart in body.split(',')) {
      var part = rawPart.trim();
      final commentIdx = part.indexOf('//');
      if (commentIdx >= 0) part = part.substring(0, commentIdx).trim();
      if (part.isEmpty) continue;
      final mm = RegExp(r'^(\w+)\s*(?:=\s*(.+?))?$', dotAll: true)
          .firstMatch(part.replaceAll('\n', ' ').trim());
      if (mm == null) continue;
      final id = mm.group(1)!;
      if (id.endsWith('_MAX')) continue;
      int value;
      final explicit = mm.group(2)?.trim();
      if (explicit != null) {
        value = explicit.startsWith('0x')
            ? int.parse(explicit.substring(2), radix: 16)
            : int.tryParse(explicit) ?? next;
      } else {
        value = next;
      }
      next = value + 1;
      members.add(EnumMember(id, value));
    }
    result[name] = MeiEnum(name, members);
  }
  return result;
}

void parseConverterTables(String distPath) {
  // Scan signatures of both converter implementation files to build
  // authoritative maps: data type <-> converter function names.
  final toStrByType = <String, String>{};
  final typeByStrToFn = <String, String>{};
  _typeByStrToFnGlobal = typeByStrToFn;
  for (final path in [
    '$distPath/attconverter.cpp',
    '$distPath/../addons/att.cpp',
  ]) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final src = f.readAsStringSync();
    final sigRe = RegExp(
        r'std::string\s+(?:AttConverterBase|Att)::(\w+ToStr)\s*\((?:const\s+)?([A-Za-z0-9_]+)[^)]*\)');
    for (final m in sigRe.allMatches(src)) {
      toStrByType.putIfAbsent(m.group(2)!, () => m.group(1)!);
    }
    final strSigRe = RegExp(
        r'([A-Za-z0-9_]+)\s+(?:AttConverterBase|Att)::(StrTo\w+)\s*\(');
    for (final m in strSigRe.allMatches(src)) {
      typeByStrToFn.putIfAbsent(m.group(2)!, () => m.group(1)!);
    }
  }

  for (final dataType in enums.keys) {
    final toStrFn = toStrByType[dataType];
    if (toStrFn == null) continue;
    final bodies = <String>[];
    for (final path in [
      '$distPath/attconverter.cpp',
      '$distPath/../addons/att.cpp',
    ]) {
      final f = File(path);
      if (!f.existsSync()) continue;
      final src = f.readAsStringSync();
      final re = RegExp(
          '(?:std::string|void)\\s+(?:AttConverterBase|Att)::${RegExp.escape(toStrFn)}\\s*\\([^)]*\\)[^{]*\\{',
          dotAll: true);
      final m = re.firstMatch(src);
      if (m != null) {
        final end = src.indexOf('\n}\n', m.end);
        if (end > m.end) bodies.add(src.substring(m.end, end));
      }
    }
    final caseRe = RegExp(r'case\s+(\w+)\s*:\s*value\s*=\s*"([^"]*)"');
    final found = <int, String>{};
    for (final body in bodies) {
      for (final cm in caseRe.allMatches(body)) {
        final memberId = cm.group(1)!;
        final idx =
            enums[dataType]!.members.indexWhere((e) => e.id == memberId);
        if (idx >= 0) found[idx] = cm.group(2)!;
      }
    }
    if (found.isNotEmpty &&
        found.length >= enums[dataType]!.members.length - 2) {
      enumsWithTable.add(dataType);
      _tables[dataType] = found;
    }
  }
}

final Map<String, Map<int, String>> _tables = {};
Map<String, String> _typeByStrToFnGlobal = {};

// ---------------------------------------------------------------------------
// Class parsing
// ---------------------------------------------------------------------------

List<AttClass> parseClasses(String src, String module) {
  final classes = <AttClass>[];
  final classRe =
      RegExp(r'class (Att\w+)\s*:\s*public Att \{(.*?)\n\};', dotAll: true);
  for (final m in classRe.allMatches(src)) {
    final cls = AttClass(m.group(1)!, module);
    final body = m.group(2)!;
    final memberRe = RegExp(
        r'(?:/\*\*(.*?)\*/\s*)?([A-Za-z_][\w:<>, ]*?)\s+m_(\w+);',
        dotAll: true);
    for (final mm in memberRe.allMatches(body)) {
      var typePart =
          mm.group(2)!.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      // Strip stray access specifiers that slipped before the declaration.
      for (final kw in ['protected:', 'private:', 'public:']) {
        if (typePart.endsWith(kw)) {
          typePart = typePart.substring(0, typePart.length - kw.length).trim();
        }
      }
      cls.members.add(AttMember(mm.group(3)!, mm.group(3)!, typePart));
    }
    classes.add(cls);
  }
  return classes;
}

/// Uses the Read functions as authoritative source for attribute names and
/// the converter actually applied.
void applyReadInfo(List<AttClass> classes, String cpp) {
  if (cpp.isEmpty) return;
  for (final cls in classes) {
    final re = RegExp('bool ${cls.name}::Read\\w+\\([^)]*\\)\\s*\\{(.*?)\\n\\}',
        dotAll: true);
    final m = re.firstMatch(cpp);
    if (m == null) continue;
    final body = m.group(1)!;
    for (final pm in RegExp(
            r'element\.attribute\("([^"]+)"\)\)\s*\{\s*this->Set(\w+)\((\w+)\(')
        .allMatches(body)) {
      final attrName = pm.group(1)!;
      final setterSuffix = pm.group(2)!;
      final cppReadFn = pm.group(3)!;

      AttMember? member;
      for (final mem in cls.members) {
        if (mem.attrName[0].toUpperCase() + mem.attrName.substring(1) ==
            setterSuffix) {
          member = mem;
          break;
        }
        if (lowerCamel(setterSuffix) == mem.attrName) {
          member = mem;
          break;
        }
      }
      if (member == null) {
        warnings.add('${cls.name}: setter Set$setterSuffix has no member');
        continue;
      }
      member.attrName = attrName;
      member.dartName =
          _sanitizeField(_lowerFirstPreservingCase(setterSuffix));

      final conv = _resolveConverters(cppReadFn, member);
      member.readFn = conv[0];
      member.writeFn = conv[1];
    }
  }
}

const Map<String, List<String>> _basicConverters = {
  'StrToInt': ['strToInt', 'intToStr'],
  'StrToDbl': ['strToDbl', 'dblToStr'],
  'StrToStr': ['identityStr', 'identityStr'],
  'StrToNcname': ['identityStr', 'ncnameToStr'],
  'StrToBoolean': ['strToBoolean', 'booleanToStr'],
  'StrToHexnum': ['strToHexnum', 'hexnumToStr'],
  'StrToVU': ['strToDbl', 'vuToStr'],
  'StrToDegrees': ['strToDbl', 'degreesToStr'],
  'StrToPercent': ['strToDbl', 'percentToStr'],
  'StrToPercentLimited': ['strToDbl', 'percentLimitedToStr'],
  'StrToPercentLimitedSigned': [
    'strToDbl',
    'percentLimitedSignedToStr'
  ],
  'StrToFontsizenumeric': ['strToDbl', 'fontsizenumericToStr'],
  'StrToMidibpm': ['strToInt', 'midibpmToStr'],
  'StrToMidichannel': ['strToInt', 'midichannelToStr'],
  'StrToMidimspb': ['strToInt', 'midimspbToStr'],
  'StrToMidivalue': ['strToInt', 'midivalueToStr'],
  'StrToOctave': ['strToInt', 'octaveToStr'],
};

const Map<String, String> _specialByStrToFn = {
  'StrToFontsize': 'fontsize',
  'StrToHeadshape': 'headshape',
  'StrToLinewidth': 'linewidth',
  'StrToMeasurementsigned': 'measurementsigned',
  'StrToMeasurementunsigned': 'measurementunsigned',
  'StrToKeysignature': 'keysignature',
  'StrToMeasurebeat': 'measurebeat',
  'StrToMetercountPair': 'metercountPair',
  'StrToMidivalueName': 'midivalueName',
  'StrToMidivaluePan': 'midivaluePan',
  'StrToPlacement': 'placement',
};

const Map<String, List<String>> _listByStrToFn = {
  'StrToArticulationList': ['strToArticulationList', 'articulationListToStr'],
  'StrToBulge': ['strToBulge', 'bulgeToStr'],
  'StrToXsdAnyURIList': ['strToXsdAnyURIList', 'xsdAnyURIListToStr'],
  'StrToXsdPositiveIntegerList': [
    'strToXsdPositiveIntegerList',
    'xsdPositiveIntegerListToStr'
  ],
  'StrToStringList': ['strToStringList', 'stringListToStr'],
  'StrToIntList': ['strToIntList', 'intListToStr'],
};

/// Resolves the Dart read/write function names for a member given the C++
/// StrToXxx function used by its Read implementation.
List<String> _resolveConverters(String cppReadFn, AttMember member) {
  // 1) Authoritative: derive from the converter used in the Read function.
  if (cppReadFn.isNotEmpty) {
    if (_basicConverters.containsKey(cppReadFn)) {
      return _basicConverters[cppReadFn]!;
    }
    if (_specialByStrToFn.containsKey(cppReadFn)) {
      final stem = _specialByStrToFn[cppReadFn]!;
      final stemCap = stem[0].toUpperCase() + stem.substring(1);
      return ['strTo$stemCap', '${stem}ToStr'];
    }
    if (_listByStrToFn.containsKey(cppReadFn)) {
      return _listByStrToFn[cppReadFn]!;
    }
    final dataType = _typeByStrToFnGlobal[cppReadFn];
    if (dataType != null && enumsWithTable.contains(dataType)) {
      final n = enumDartName(dataType);
      return ['strTo$n', '${n[0].toLowerCase()}${n.substring(1)}ToStr'];
    }
    warnings.add('unresolved converter $cppReadFn '
        '(member ${member.attrName}: ${member.cppType})');
  }

  // 2) Fallback: derive from the declared member type.
  final t = member.cppType;
  if (simpleTypes.containsKey(t)) {
    final v = simpleTypes[t]!;
    return [v[1], v[2]];
  }
  if (specialConverters.containsKey(t)) return specialConverters[t]!;
  if (listTypes.containsKey(t)) return listTypes[t]!.sublist(1);
  if (_typeByStrToFnGlobal.isNotEmpty) {
    // Enum type without known Read fn: use generated enum converters when a
    // table exists.
    final n = enumDartName(t);
    return ['strTo$n', '${n[0].toLowerCase()}${n.substring(1)}ToStr'];
  }
  warnings.add('no converters for member ${member.attrName} (${member.cppType})');
  return ['identityStr', 'identityStr'];
}

// ---------------------------------------------------------------------------
// Emission: enums file
// ---------------------------------------------------------------------------

void emitEnums() {
  Directory('lib/src/model/atts').createSync(recursive: true);
  final out = StringBuffer();
  out.writeln('// GENERATED FILE - do not edit. Regenerate with:');
  out.writeln('//   dart run tool/gen_atts.dart');
  out.writeln('// Source: origin/src/libmei/dist/atttypes.h');
  out.writeln('library;');
  out.writeln();

  final sortedKeys = enums.keys.toList()..sort();
  for (final name in sortedKeys) {
    // `Duration` would shadow dart:core's class; the canonical type is the
    // hand-written MeiDuration in core/attdef.dart.
    if (name == 'data_DURATION') continue;
    final def = enums[name]!;
    out.writeln("/// MEI `$name`.");
    out.writeln('enum ${enumDartName(name)} {');

    final usedNames = <String, int>{};
    for (final member in def.members) {
      var valueName = memberValueName(name, member.id);
      final count = usedNames[valueName];
      if (count != null) {
        usedNames[valueName] = count + 1;
        valueName = '$valueName$count';
      } else {
        usedNames[valueName] = 0;
      }
      out.writeln("  /// `${member.id}`");
      out.writeln('  $valueName(${member.value}),');
    }
    out.writeln(';');
    out.writeln();
    out.writeln('  const ${enumDartName(name)}(this.value);');
    out.writeln();
    out.writeln('  final int value;');
    out.writeln();
    out.writeln('  static ${enumDartName(name)} fromValue(int value) =>');
    out.writeln('      ${enumDartName(name)}.values');
    out.writeln('          .firstWhere((e) => e.value == value,');
    out.writeln('              orElse: () => ${enumDartName(name)}.values.first);');
    out.writeln('}');
    out.writeln();
  }
  File('lib/src/model/atts/mei_enums.dart').writeAsStringSync(out.toString());
}

// ---------------------------------------------------------------------------
// Emission: conversion file
// ---------------------------------------------------------------------------

void emitConversion() {
  final out = StringBuffer();
  out.writeln('// GENERATED FILE - do not edit. Regenerate with:');
  out.writeln('//   dart run tool/gen_atts.dart');
  out.writeln("// Source: origin/src/libmei/dist/attconverter.cpp + addons/att.cpp");
  out.writeln('library;');
  out.writeln();
  out.writeln("import '../../core/logging.dart';");
  out.writeln("import 'mei_enums.dart';");
  out.writeln();
  out.writeln('const String _unknownValue = "";');
  out.writeln();

  final sortedKeys = enums.keys.toList()..sort();
  for (final name in sortedKeys) {
    if (!enumsWithTable.contains(name)) continue;
    // Simple types are hand-written in mei_values.dart.
    if (name == 'data_BOOLEAN') continue;
    // `Duration` would shadow dart:core's class; the canonical type is the
    // hand-written MeiDuration in core/attdef.dart.
    if (name == 'data_DURATION') continue;
    final dartName = enumDartName(name);
    final def = enums[name]!;
    final table = _tables[name]!;

    // ToStr
    out.writeln('/// `$name` -> string.');
    out.writeln('String ${dartName[0].toLowerCase()}${dartName.substring(1)}ToStr('
        '$dartName data) {');
    out.writeln('  switch (data.value) {');
    for (final entry in table.entries) {
      final member = def.members[entry.key];
      out.writeln("    case ${member.value}: return '${entry.value}';");
    }
    out.writeln('  }');
    out.writeln(
        "  logWarning(\"Unknown value '\${data.value}' for $name\");");
    out.writeln('  return _unknownValue;');
    out.writeln('}');
    out.writeln();

    // StrTo
    out.writeln('/// string -> `$name`.');
    out.writeln('$dartName strTo$dartName(String value) {');
    // `memberValueName` disambiguates colliding `_NONE`/`_none` into
    // `none`/`none0` and `emitEnums` suffixes later collisions (`none0`,
    // `none1`, ...). Reproduce that exact numbering here in *member
    // declaration order* (not string-table order, which differs), so each
    // member index maps to its real enum member — e.g. the MEI "none"
    // string returns `none0` (the `*_none` member), while the unmatched
    // default returns `none` (the `*_NONE` unset member), matching the C++
    // `StrTo*` (`return X_none;` vs `return X_NONE;`).
    final disambig = <String>[];
    final usedConvNames = <String, int>{};
    for (final member in def.members) {
      var valueName = memberValueName(name, member.id);
      final count = usedConvNames[valueName];
      if (count != null) {
        usedConvNames[valueName] = count + 1;
        valueName = '$valueName$count';
      } else {
        usedConvNames[valueName] = 0;
      }
      disambig.add(valueName);
    }
    for (final entry in table.entries) {
      out.writeln("  if (value == '${entry.value}') "
          "return $dartName.${disambig[entry.key]};");
    }
    out.writeln("  if (value.isNotEmpty) {");
    out.writeln("    logWarning(\"Unsupported value '\$value' for $name\");");
    out.writeln('  }');
    final noneIdx = def.members
        .indexWhere((m) => m.id.toLowerCase().endsWith('_none'));
    out.writeln(
        '  return $dartName.${disambig[noneIdx >= 0 ? noneIdx : 0]};');
    out.writeln('}');
    out.writeln();
  }
  File('lib/src/model/atts/atts_conversion.dart')
      .writeAsStringSync(out.toString());
}

// ---------------------------------------------------------------------------
// Emission: per-module attribute mixins
// ---------------------------------------------------------------------------

String dartFieldType(String cppType) {
  if (specialClassTypes.containsKey(cppType)) {
    return '${specialClassTypes[cppType]}?';
  }
  if (simpleTypes.containsKey(cppType)) return simpleTypes[cppType]![0];
  if (listTypes.containsKey(cppType)) {
    return 'List<${listTypes[cppType]![0]}>?';
  }
  return '${enumDartName(cppType)}?';
}

void emitModule(String module, List<AttClass> classes) {
  final out = StringBuffer();
  out.writeln('// GENERATED FILE - do not edit. Regenerate with:');
  out.writeln('//   dart run tool/gen_atts.dart');
  out.writeln('// Source: origin/src/libmei/dist/atts_$module.h/.cpp');
  out.writeln('library;');
  out.writeln();
  final hasMembers = classes.any((c) => c.members.isNotEmpty);
  final usesConversion = classes.any((c) => c.members
      .any((m) => enumsWithTable.contains(m.cppType)));
  final usesEnums = classes.any((c) => c.members
      .any((m) => !simpleTypes.containsKey(m.cppType) &&
          !specialClassTypes.containsKey(m.cppType) &&
          !listTypes.containsKey(m.cppType)));
  // mei_values provides MeiAttributeReader; xml provides XmlBuilder.
  if (hasMembers) out.writeln("import 'package:xml/xml.dart';");
  if (usesConversion) out.writeln("import 'atts_conversion.dart';");
  if (usesEnums) out.writeln("import 'mei_enums.dart';");
  if (hasMembers) out.writeln("import 'mei_values.dart';");
  out.writeln();
  for (final cls in classes) {
    emitClass(out, cls);
  }
  File('lib/src/model/atts/atts_$module.dart')
      .writeAsStringSync(out.toString());
}

String fieldName(String attrName) => sanitizeIdent(attrName);

void emitClass(StringBuffer out, AttClass cls) {
  final shortName = cls.name.substring(3);
  out.writeln('/// MEI attribute class for `att.$shortName` '
      '(mirrors `vrv::${cls.name}`).');
  out.writeln('mixin ${cls.name} {');
  for (final member in cls.members) {
    final field = member.dartName;
    out.writeln('  /// `${member.attrName}` — ${member.cppType}.');
    out.writeln('  ${dartFieldType(member.cppType)} $field;');
    out.writeln(
        '  bool get has${cap(field)} => $field != null;');
  }
  out.writeln();
  out.writeln('  /// Mirrors `${cls.name}::Read$shortName`.');
  out.writeln(
      '  bool read$shortName(MeiAttributeReader element, {bool removeAttr = true}) {');
  out.writeln('    bool hasAttribute = false;');
  for (final member in cls.members) {
    final f = member.dartName;
    out.writeln("    final ${f}Raw = element.get('${member.attrName}');");
    out.writeln('    if (${f}Raw != null) {');
    out.writeln('      $f = ${member.readFn}(${f}Raw);');
    out.writeln("      if (removeAttr) element.remove('${member.attrName}');");
    out.writeln('      hasAttribute = true;');
    out.writeln('    }');
  }
  out.writeln('    return hasAttribute;');
  out.writeln('  }');
  out.writeln();
  out.writeln('  /// Mirrors `${cls.name}::Write$shortName`.');
  out.writeln('  void write$shortName(XmlBuilder element) {');
  for (final member in cls.members) {
    final f = member.dartName;
    out.writeln('    if (has${cap(f)}) {');
    out.writeln("      element.attribute('${member.attrName}',");
    out.writeln('          ${member.writeFn}($f!));');
    out.writeln('    }');
  }
  out.writeln('  }');
  // Copy helper: copies this attribute class' fields from [other].
  final copyName = 'copyAtt$shortName';
  out.writeln();
  out.writeln('  /// Copies the `${cls.name}` members from [other].');
  out.writeln('  void $copyName(covariant ${cls.name} other) {');
  for (final member in cls.members) {
    final f = member.dartName;
    out.writeln('    $f = other.$f;');
  }
  out.writeln('  }');
  out.writeln('}');
  out.writeln();
}
