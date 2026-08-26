import 'package:test/test.dart';
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/object.dart';

void main() {
  setUp(registerModelClasses);

  group('MEI tree construction', () {
    test('builds a document tree with supported children only', () {
      final mdiv = Mdiv();
      final score = Score();
      final section = Section();
      final measure = Measure();
      final staff = Staff()..n = 1;
      final layer = Layer()..n = 1;
      final note = Note()
        ..dur = MeiDuration.dur4
        ..pname = Pitchname.c
        ..oct = 4;

      expect(mdiv.addChild(score), isTrue);
      expect(score.addChild(section), isTrue);
      expect(section.addChild(measure), isTrue);
      expect(measure.addChild(staff), isTrue);
      expect(staff.addChild(layer), isTrue);
      expect(layer.addChild(note), isTrue);

      // Unsupported children are rejected:
      expect(staff.addChild(Note()), isFalse);
      expect(layer.addChild(Measure()), isFalse);
      expect(measure.addChild(Layer()), isFalse);

      // Control elements are allowed in measures:
      final dir = _FakeControl();
      expect(measure.addChild(dir), isTrue);

      // Editorial elements pass through everywhere relevant:
      expect(note.addChild(App()), isTrue);
      expect(staff.addChild(Sic()), isTrue);
    });

    test('tree lookups work across the hierarchy', () {
      final score = Score();
      final section = Section();
      final measure1 = Measure();
      final measure2 = Measure();
      score.addChild(section);
      section.addChild(measure1);
      section.addChild(measure2);

      expect(score.getDescendantCount(ClassId.measure), 2);
      expect(measure2.getFirstAncestor(ClassId.score), same(score),
          reason: 'first ancestor of measure2 is the score');
      expect(section.getNextSibling(measure1), same(measure2));
      expect(section.getPreviousSibling(measure2), same(measure1));
    });
  });

  group('ObjectFactory with model classes', () {
    test('registers all generated families', () {
      extraFactoryChecks();
    });

    test('creates elements by MEI name', () {
      final note = ObjectFactory.instance.create('note');
      expect(note, isA<Note>());
      expect(note!.className, 'note');
      expect(note.classId, ClassId.note);

      final rdg = ObjectFactory.instance.create('rdg');
      expect(rdg, isA<Rdg>());

      // Slur is now generated as a control element:
      final slur = ObjectFactory.instance.create('slur');
      expect(slur, isNotNull);
      expect(slur!.className, 'slur');
      expect(ObjectFactory.instance.create('nonexistent-element'), isNull);
    });

    test('clone produces independent copies', () {
      final note = Note()
        ..id = 'orig'
        ..pname = Pitchname.g
        ..oct = 3;
      final copy = note.clone() as Note;
      expect(copy.pname, Pitchname.g);
      expect(copy.oct, 3);
      expect(copy.id, isNot('orig'), reason: 'copy gets a fresh id');
      expect(identical(copy, note), isFalse);
    });
  });

  group('Note duration interface wiring', () {
    test('note exposes DurationInterface behaviour', () {
      final note = Note()
        ..dur = MeiDuration.dur2
        ..dots = 1;
      expect(note.getActualDur(), MeiDuration.dur2);
      expect(note.getInterfaceAlignmentDuration(1, 1), Fraction(3, 4));
    });
  });
}

/// Minimal control element stand-in (full control classes come later).
class _FakeControl extends Object {
  @override
  ClassId get classId => ClassId.dir;

  @override
  String get className => 'dir';

  @override
  Object clone() => _FakeControl();
}

void extraFactoryChecks() {
  // Spot-check a few generated classes across families.
  for (final name in ['beam', 'chord', 'accid', 'artic', 'tuplet', 'fermata',
      'slur', 'tie', 'hairpin', 'dir', 'dynam', 'tempo', 'pedal', 'octave',
      'text', 'rend', 'lb', 'pgHead', 'pgFoot', 'ending', 'expansion',
      'graceGrp', 'multiRest', 'mRest', 'meterSig', 'keySig']) {
    final obj = ObjectFactory.instance.create(name);
    if (obj == null) {
      throw StateError('factory could not create $name');
    }
    if (obj.className != name) {
      throw StateError('$name className mismatch: ${obj.className}');
    }
  }
}
