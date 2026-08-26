import 'package:test/test.dart';
import 'package:verovio_dart/src/core/tunings.dart' as tunings;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show KeySignature;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/comparison.dart';
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/expansion_map.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';

void main() {
  group('Tunings (tuning-library)', () {
    test('even temperament matches standard MIDI frequencies', () {
      final tuning = tunings.Tuning();
      expect(tuning.frequencyForMidiNote(69), closeTo(440.0, 0.01));
      expect(tuning.frequencyForMidiNote(60), closeTo(261.63, 0.01));
      expect(tuning.scalePositionForMidiNote(60), 0);
    });

    test('parses ASCL data with note names and reference pitch', () {
      const ascl = '''
! quarter tone scale
!
Quarter tones
8
50.
100.
150.
200.
250.
300.
350.
400.
! @ABL NOTE_NAMES "C" "C+" "C#" "C#+" "D" "D+" "D#" "D#+"
! @ABL REFERENCE_PITCH 4 0 261.6256
''';
      final as = tunings.parseASCLData(ascl);
      expect(as.scale.count, 8);
      // The first name is rotated to the end to match scale.tones.
      expect(as.notationMapping.names.last, 'C');
      expect(as.notationMapping.count, 8);

      final tuning = tunings.Tuning.fromAbletonScale(as);
      expect(tuning.midiNoteForNoteName('C', 4), 60);
      // Quarter tone sharp above middle C.
      expect(tuning.midiNoteForNoteName('C+', 4), 61);
      expect(tuning.frequencyForMidiNote(60), closeTo(261.63, 0.01));
    });

    test('invalid note name throws a TuningError', () {
      final tuning = tunings.Tuning();
      expect(() => tuning.midiNoteForNoteName('H', 4),
          throwsA(isA<tunings.TuningError>()));
    });
  });

  group('ExpansionMap', () {
    test('addExpandedIDToExpansionMap links original and clones', () {
      final map = ExpansionMap();
      // Clones are always registered against the original id (as in the
      // C++ expansion flow).
      map.addExpandedIDToExpansionMap('sec1', 'sec1-rend2');
      expect(
          map.getExpansionIDsForElement('sec1'), ['sec1', 'sec1-rend2']);
      expect(map.getExpansionIDsForElement('sec1-rend2'),
          ['sec1', 'sec1-rend2']);
      expect(map.hasExpansionMap(), isTrue);

      map.addExpandedIDToExpansionMap('sec1', 'sec1-rend3');
      expect(
          map.getExpansionIDsForElement('sec1'),
          containsAll(['sec1-rend3']));
      // Middle keys accumulate the newest clone too.
      expect(
          map.getExpansionIDsForElement('sec1-rend2'),
          containsAll(['sec1-rend3']));

      // Unknown ids return themselves.
      expect(map.getExpansionIDsForElement('other'), ['other']);

      map.reset();
      expect(map.hasExpansionMap(), isFalse);
    });

    test('toJson serializes the map', () {
      final map = ExpansionMap();
      map.addExpandedIDToExpansionMap('a', 'a-rend2');
      expect(map.toJson(), contains('"a"'));
      expect(map.toJson(), contains('a-rend2'));
    });

    test('expand clones plist sections with predictable ids', () {
      // Build: score > section(expansion + section#s1 + section#s2)
      final score = Score();
      final section = Section();
      score.addChild(section);

      final expansion = Expansion()
        ..plist = ['#s1', '#s2', '#s1'];

      final s1 = Section()..id = 's1';
      s1.addChild(Measure());
      final s2 = Section()..id = 's2';
      s2.addChild(Measure());
      section.addChild(expansion);
      section.addChild(s1);
      section.addChild(s2);

      final map = ExpansionMap();
      final existingList = <String>[];
      final deletionList = <String>[];

      final result =
          map.expand(expansion, existingList, s1, deletionList);

      expect(result, isNotNull);
      // The second #s1 occurrence must be cloned with a predictable id.
      final cloned = section.findAllDescendantsByType(ClassId.section,
              continueDepthSearchForMatches: true)
          .where((o) => o.id.startsWith('s1-rend'))
          .toList();
      expect(cloned, hasLength(1));
      expect(cloned.first.id, 's1-rend2');
      expect(map.hasExpansionMap(), isTrue);
      // Ids are stored without the leading '#'; the expansion parent id
      // comes first.
      expect(existingList, contains('s1'));
      expect(existingList.last, 's1-rend2');
    });

    test('repeat detection helpers', () {
      final repeatBoth = Measure()
        ..left = Barrendition.rptboth
        ..right = Barrendition.rptboth;
      expect(ExpansionMap.isRepeatStart(repeatBoth), isTrue);
      expect(ExpansionMap.isNextRepeatStart(repeatBoth), isTrue);
      expect(ExpansionMap.isRepeatEnd(repeatBoth), isTrue);
      expect(ExpansionMap.isPreviousRepeatEnd(repeatBoth), isTrue);

      final startOnly = Measure()..left = Barrendition.rptstart;
      final endOnly = Measure()..right = Barrendition.rptend;

      // A repeat start on the left ends the previous repeat span.
      expect(ExpansionMap.isRepeatStart(startOnly), isTrue);
      expect(ExpansionMap.isPreviousRepeatEnd(startOnly), isFalse);
      expect(ExpansionMap.isRepeatEnd(endOnly), isTrue);
      expect(ExpansionMap.isNextRepeatStart(endOnly), isFalse);

      final plain = Measure();
      expect(ExpansionMap.isRepeatStart(plain), isFalse);
      expect(ExpansionMap.isRepeatEnd(plain), isFalse);
    });

    test('generateExpansionFor builds an expansion from repeats', () {
      final score = Score();
      final section = Section();
      score.addChild(section);
      section.addChild(Measure()); // no repeat
      section.addChild(Measure()
        ..right = Barrendition.rptend); // repeat end

      final map = ExpansionMap();
      map.generateExpansionFor(score);

      expect(map.isProcessed(), isTrue);
      final expansions =
          section.findDescendantsByType(const [ClassId.expansion]);
      expect(expansions.length, greaterThanOrEqualTo(0));
    });
  });

  group('Comparison framework', () {
    test('ClassIdComparison matches and reverses', () {
      final comp = ClassIdComparison(ClassId.note);
      expect(comp(Note()), isTrue);
      expect(comp(Rest()), isFalse);

      comp.reverseComparison();
      expect(comp(Rest()), isTrue);
    });

    test('IsAttributeComparison filters attribute-like children', () {
      final keySig = KeySig()
        ..sig = KeySignature(2, AccidentalWritten.s);
      keySig.generateKeyAccidAttribChildren();

      final comp = IsAttributeComparison(ClassId.keyAccid);
      expect(keySig.getChild(0)!, isNotNull);
      expect(comp(keySig.getChild(0)!), isTrue);
    });

    test('AttNNumberLikeComparison matches @n strings', () {
      final course = Course()..n = '3';
      final comp = AttNNumberLikeComparison(ClassId.course, '3');
      expect(comp(course), isTrue);
      expect(comp(Course()..n = '4'), isFalse);
    });

    test('Filters combine comparisons', () {
      final filters = Filters.of([
        ClassIdComparison(ClassId.section),
        IDComparison(ClassId.section, 'x1'),
      ]);
      final section = Section()..id = 'x1';
      expect(filters.apply(section), isTrue);

      final other = Section()..id = 'y2';
      expect(filters.apply(other), isFalse);

      // A class-id filter for another class is ignored.
      filters.add(IDComparison(ClassId.measure, 'zzz'));
      expect(filters.apply(section), isTrue);
    });

    test('editorial elements can be found through comparison searches',
        () {
      final measure = Measure();
      measure.addChild(App());

      expect(
          measure.findDescendantByComparison(
              IsEditorialElementComparison()),
          isNotNull);
    });
  });
}

// Local alias so the test reads like the C++ pair type.
typedef KeySigSig = dynamic;

/// Small helper mirroring `FindDescendantsByType` plural used in one test.
extension FindMany on Object {
  List<Object> findDescendantsByType(List<ClassId> classIds) =>
      findAllDescendantsByType(classIds.first)
          .where((o) => classIds.contains(o.classId))
          .toList();
}
