// Tests for the ObjectFactory element-name registrations (tasks 04i, 2026-08-29-03).
//
// The expected name set mirrors the *active* `ClassRegistrar` static instances
// of the C++ 6.2.0 sources (`grep -rn "ClassRegistrar" origin/src/src/*.cpp`,
// format: `static const ClassRegistrar<Note> s_factory("note", NOTE);`).
//
// Documented exceptions to the 1:1 mirror:
// - `'oStaff'` / `'stageDir'` are registered under the distinct pseudo
//   ClassIds `FACTORY_OSTAFF` / `FACTORY_STAGEDIR` (`vrvdef.h:287-288`,
//   `staff.cpp:47`, `dir.cpp:31`) with custom lambdas (`Staff(1, true)`,
//   `Dir(true)`). The objects they create still carry `STAFF`/`DIR` as
//   `classId`/`className` (`Staff::IsOssia ? "oStaff" : "staff"`), so the
//   registry is keyed by the factory ids while `IsSupportedChild` matches on
//   the real ids — see `core/vrvdef.dart` deviation note. `mei_input.dart`
//   also handles `<oStaff>`/`<stageDir>` inline, mirroring `iomei.cpp:5817`/
//   `:5865`, but that does not replace the factory path (needed for clone/
//   toolkit, Phase 6).
// - `'alignmentreference'` is Dart-only (the C++ has no registrar for
//   `AlignmentReference`); kept so `createFromClassId` round-trips the class.
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Ossia, Staff;
import 'package:verovio_dart/src/model/control_elements_gen.dart'
    show AnnotScore, Dir, Lv, Phrase;
import 'package:verovio_dart/src/model/editorial_element.dart' show Annot;
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show BTrem;
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show F, Fb;
import 'package:verovio_dart/src/model/object.dart';

void main() {
  setUpAll(() {
    registerModelClasses();
  });

  group('factory registry hygiene (04i)', () {
    test('no MEI element name is registered twice', () {
      final names = _registeredNames();
      final seen = <String>{};
      final duplicates = <String>{};
      for (final name in names) {
        if (!seen.add(name)) duplicates.add(name);
      }
      expect(duplicates, isEmpty,
          reason: 'duplicate registrations silently overwrite each other');
    });

    test('every C++ ClassRegistrar name is registered with the same name', () {
      final registered = _registeredNames().toSet();
      final missing = kCppRegistrarNames.difference(registered);
      expect(missing, isEmpty,
          reason:
              'names registered in the C++ but missing (or renamed) in Dart');
    });

    test('Dart-only registrations stay within the documented set', () {
      final registered = _registeredNames().toSet();
      expect(registered.difference(kCppRegistrarNames), {'alignmentreference'},
          reason: 'AlignmentReference has no C++ ClassRegistrar; documented '
              'Dart-only registration');

      // Wrong or C++-absent names removed by 04i must stay out. In the C++
      // none of Dots/Flag/TupletBracket/TupletNum nor DivLine, Liquescent,
      // Oriscus, Quilisma, Strophicus, Text, TimestampAttr has a
      // ClassRegistrar, and the Dart readers construct them directly.
      for (final name in [
        'dots',
        'divLine',
        'liquescent',
        'oriscus',
        'quilisma',
        'strophicus',
        'text',
        'timestampAttr',
      ]) {
        expect(registered.contains(name), isFalse,
            reason: "'$name' has no C++ ClassRegistrar and must not be "
                'registered');
      }
    });

    test("create('annot') returns the editorial Annot, not AnnotScore", () {
      final annot = ObjectFactory.instance.create('annot');
      expect(annot, isA<Annot>());
      expect(annot, isNot(isA<AnnotScore>()));
    });

    test("create('annotScore') returns AnnotScore", () {
      expect(ObjectFactory.instance.create('annotScore'), isA<AnnotScore>());
    });

    test("create('btrem') returns BTrem (mirrors btrem.cpp:32)", () {
      expect(ObjectFactory.instance.create('btrem'), isA<BTrem>());
    });

    test("create('f'), create('fb') return the figured-bass elements", () {
      expect(ObjectFactory.instance.create('f'), isA<F>());
      expect(ObjectFactory.instance.create('fb'), isA<Fb>());
    });

    test("create('lv'), create('phrase') return the tie/slur subclasses", () {
      expect(ObjectFactory.instance.create('lv'), isA<Lv>());
      expect(ObjectFactory.instance.create('phrase'), isA<Phrase>());
    });

    test("create('ossia') returns Ossia (mirrors ossia.cpp:32)", () {
      expect(ObjectFactory.instance.create('ossia'), isA<Ossia>());
    });
  });

  group('factory registry — oStaff / stageDir (2026-08-29-03)', () {
    test(
        "create('oStaff') returns Staff with isOssia true and n==1 "
        "(mirrors staff.cpp:47)", () {
      final obj = ObjectFactory.instance.create('oStaff');
      expect(obj, isA<Staff>());
      final staff = obj as Staff;
      expect(staff.isOssia(), isTrue,
          reason: 'oStaff factory must set isOssia (Staff(1, true))');
      expect(staff.n, equals(1),
          reason: 'oStaff factory must set n=1 (Staff(1, true))');
      expect(staff.className, equals('oStaff'));
      // The runtime object carries STAFF as classId; the name maps to the
      // pseudo id only in the factory registry.
      expect(staff.classId, equals(ClassId.staff));
      expect(ObjectFactory.instance.getClassId('oStaff'),
          equals(ClassId.factoryOstaff));
    });

    test(
        "create('stageDir') returns Dir with isStageDir true "
        "(mirrors dir.cpp:31)", () {
      final obj = ObjectFactory.instance.create('stageDir');
      expect(obj, isA<Dir>());
      final dir = obj as Dir;
      expect(dir.isStageDir(), isTrue,
          reason: 'stageDir factory must set isStageDir (Dir(true))');
      expect(dir.className, equals('stageDir'));
      expect(dir.classId, equals(ClassId.dir));
      expect(ObjectFactory.instance.getClassId('stageDir'),
          equals(ClassId.factoryStagedir));
    });

    test("create('staff') still returns a normal Staff (contrast)", () {
      final obj = ObjectFactory.instance.create('staff');
      expect(obj, isA<Staff>());
      final staff = obj as Staff;
      expect(staff.isOssia(), isFalse);
      // n is not preset by the default factory (null / unset).
      expect(staff.n, isNull);
      expect(staff.className, equals('staff'));
      expect(staff.classId, equals(ClassId.staff));
      expect(ObjectFactory.instance.getClassId('staff'), equals(ClassId.staff));
    });

    test("create('dir') still returns a normal Dir (contrast)", () {
      final obj = ObjectFactory.instance.create('dir');
      expect(obj, isA<Dir>());
      final dir = obj as Dir;
      expect(dir.isStageDir(), isFalse);
      expect(dir.className, equals('dir'));
      expect(dir.classId, equals(ClassId.dir));
      expect(ObjectFactory.instance.getClassId('dir'), equals(ClassId.dir));
    });
  });
}

/// Extracts the registered names from the two registry sources, mirroring the
/// acceptance check
/// `cat lib/src/model/factory_registry_gen.dart lib/src/factory_registry.dart
/// | grep -oP "f\.register\('\K[^']+"`.
///
/// The registry itself cannot be introspected at runtime (`ObjectFactory` has
/// no read accessor), and a second registration would silently overwrite the
/// first in its internal maps — parsing the sources is the only way to catch
/// duplicates.
List<String> _registeredNames() {
  final names = <String>[];
  for (final path in [
    'lib/src/model/factory_registry_gen.dart',
    'lib/src/factory_registry.dart',
  ]) {
    final file = File(path);
    expect(file.existsSync(), isTrue,
        reason: '$path not found — run the '
            'tests from the package root');
    final source = file.readAsStringSync();
    names.addAll(
        RegExp(r"f\.register\(\s*'([^']+)'").allMatches(source).map((m) {
      return m.group(1)!;
    }));
  }
  return names;
}

/// Every active C++ `ClassRegistrar` element name (Verovio 6.2.0), including
/// `'oStaff'`/`'stageDir'` (pseudo-ClassIds `FACTORY_OSTAFF`/
/// `FACTORY_STAGEDIR`, see header comment) and excluding only the
/// commented-out `'generic'` (`genericlayerelement.cpp:25`).
///
/// Regenerate with:
/// `grep -rn "ClassRegistrar" origin/src/src/*.cpp`
const Set<String> kCppRegistrarNames = {
  'abbr',
  'accid',
  'add',
  'anchoredText',
  'annot',
  'annotScore',
  'app',
  'arpeg',
  'artic',
  'barLine',
  'beam',
  'beamSpan',
  'beatRpt',
  'bracketSpan',
  'breath',
  'btrem',
  'caesura',
  'choice',
  'chord',
  'clef',
  'corr',
  'course',
  'cpMark',
  'custos',
  'damage',
  'del',
  'dir',
  'div',
  'dot',
  'dynam',
  'ending',
  'expan',
  'expansion',
  'f',
  'fTrem',
  'facsimile',
  'fb',
  'fermata',
  'fig',
  'fing',
  'gliss',
  'graceGrp',
  'graphic',
  'grpSym',
  'hairpin',
  'halfmRpt',
  'harm',
  'instrDef',
  'keyAccid',
  'keySig',
  'label',
  'labelAbbr',
  'layer',
  'layerDef',
  'lb',
  'lem',
  'ligature',
  'lv',
  'mNum',
  'mRest',
  'mRpt',
  'mRpt2',
  'mSpace',
  'mdiv',
  'measure',
  'mensur',
  'meterSig',
  'meterSigGrp',
  'mordent',
  'multiRest',
  'multiRpt',
  'nc',
  'neume',
  'note',
  'num',
  'octave',
  'oStaff',
  'orig',
  'ornam',
  'ossia',
  'pb',
  'pedal',
  'pgFoot',
  'pgHead',
  'phrase',
  'pitchInflection',
  'plica',
  'proport',
  'rdg',
  'ref',
  'reg',
  'reh',
  'rend',
  'repeatMark',
  'rest',
  'restore',
  'sb',
  'score',
  'scoreDef',
  'section',
  'sic',
  'slur',
  'space',
  'staff',
  'staffDef',
  'staffGrp',
  'stageDir',
  'stem',
  'subst',
  'supplied',
  'surface',
  'svg',
  'syl',
  'syllable',
  'symbol',
  'symbolDef',
  'symbolTable',
  'tabDurSym',
  'tabGrp',
  'tempo',
  'tie',
  'trill',
  'tuning',
  'tuplet',
  'turn',
  'unclear',
  'verse',
  'zone',
};
