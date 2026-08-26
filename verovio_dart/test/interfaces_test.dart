import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/model/atts/atts_cmn.dart';
import 'package:verovio_dart/src/model/atts/atts_gestural.dart';
import 'package:verovio_dart/src/model/atts/atts_mensural.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/atts/atts_facsimile.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/interfaces/linking_interface.dart';
import 'package:verovio_dart/src/model/interfaces/pitch_interface.dart';
import 'package:verovio_dart/src/model/interfaces/position_interface.dart';
import 'package:verovio_dart/src/model/zone.dart';
import 'package:verovio_dart/src/model/interfaces/facsimile_interface.dart';
import 'package:verovio_dart/src/model/interfaces/plist_interface.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/object.dart';

// ---------------------------------------------------------------------------
// Concrete test classes applying the interface mixins with the required atts
// ---------------------------------------------------------------------------

class PitchedNote extends Object
    with AttNoteGes, AttOctave, AttPitch, AttPitchGes, PitchInterface {}

class PositionedRest extends Object
    with AttStaffLoc, AttStaffLocPitched, PositionInterface {}

class DurableElement extends Object
    with
        AttAugmentDots,
        AttBeamSecondary,
        AttDurationGes,
        AttDurationLog,
        AttDurationQuality,
        AttDurationRatio,
        AttFermataPresent,
        AttStaffIdent,
        DurationInterface {}

class PointingControl extends Object
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        TimePointInterface {}

class SpanningControl extends Object
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        TimePointInterface,
        TimeSpanningInterface {}

class LinkedElement extends Object with AttLinking, LinkingInterface {}

class ReferencingElement extends Object with AttPlist, PlistInterface {}

void main() {
  group('Zone / FacsimileInterface', () {
    test('shiftByXY and attachZone', testFacsimile);
  });

  group('PitchInterface', () {
    test('adjustPitchByOffset shifts within the octave', () {
      final note = PitchedNote()
        ..pname = Pitchname.c
        ..oct = 4;
      note.adjustPitchByOffset(2); // c -> e
      expect(note.pname, Pitchname.e);
      expect(note.oct, 4);
    });

    test('adjustPitchByOffset wraps across octaves', () {
      final note = PitchedNote()
        ..pname = Pitchname.b
        ..oct = 4;
      note.adjustPitchByOffset(1);
      expect(note.pname, Pitchname.c);
      expect(note.oct, 5);

      final low = PitchedNote()
        ..pname = Pitchname.c
        ..oct = 4;
      low.adjustPitchByOffset(-1);
      expect(low.pname, Pitchname.b);
      expect(low.oct, 3);
    });

    test('adjustPitchByOffset clamps to the allowed range', () {
      final high = PitchedNote()
        ..pname = Pitchname.b
        ..oct = 9;
      high.adjustPitchByOffset(7);
      expect(high.pname, Pitchname.b);
      expect(high.oct, 9);

      final low = PitchedNote()
        ..pname = Pitchname.a
        ..oct = 0;
      low.adjustPitchByOffset(-14);
      expect(low.pname, Pitchname.c);
      expect(low.oct, 0);
    });

    test('pitchDifferenceTo', () {
      final a = PitchedNote()
        ..pname = Pitchname.c
        ..oct = 4;
      final b = PitchedNote()
        ..pname = Pitchname.e
        ..oct = 4;
      expect(a.pitchDifferenceTo(b), -2);
      expect(b.pitchDifferenceTo(a), 2);

      final c = PitchedNote()
        ..pname = Pitchname.c
        ..oct = 5;
      expect(c.pitchDifferenceTo(a), 7);
    });
  });

  group('PositionInterface', () {
    test('hasIdenticalPositionInterface compares loc attributes', () {
      final a = PositionedRest()..loc = 4;
      final b = PositionedRest()..loc = 4;
      final c = PositionedRest()..loc = 6;
      expect(a.hasIdenticalPositionInterface(b), isTrue);
      expect(a.hasIdenticalPositionInterface(c), isFalse);
      expect(a.hasIdenticalPositionInterface(null), isFalse);
    });

    test('calcDrawingLoc uses ploc/oloc or loc', () {
      final rest = PositionedRest()
        ..ploc = Pitchname.c
        ..oloc = 4;
      // C4 -> loc 0 (clef offset 0).
      expect(rest.calcDrawingLoc(clefLocOffset: 0), 0);

      final withLoc = PositionedRest()..loc = -3;
      expect(withLoc.calcDrawingLoc(clefLocOffset: 0), -3);
    });
  });

  group('DurationInterface', () {
    test('mensural durations map to CMN values', () {
      final el = DurableElement();
      el.dur = MeiDuration.longa;
      expect(el.getActualDur(), MeiDuration.long);
      el.dur = MeiDuration.semibrevis;
      expect(el.getActualDur(), MeiDuration.dur1);
      el.dur = MeiDuration.minima;
      expect(el.getActualDur(), MeiDuration.dur2);
      el.dur = MeiDuration.minima;
      expect(el.isMensuralDur, isTrue);

      el.dur = MeiDuration.dur8;
      expect(el.getActualDur(), MeiDuration.dur8);
      el.dur = MeiDuration.dur4;
      expect(el.isMensuralDur, isFalse);
    });

    test('getActualDur falls back to durDefault', () {
      final el = DurableElement()..setDurDefault(MeiDuration.dur8);
      expect(el.hasDur, isFalse);
      expect(el.getActualDur(), MeiDuration.dur8);
    });

    test('getInterfaceAlignmentDuration computes dotted ratios', () {
      // Quarter without dots.
      final q = DurableElement()..dur = MeiDuration.dur4;
      expect(q.getInterfaceAlignmentDuration(1, 1), Fraction(1, 4));

      // Dotted quarter.
      final dq = DurableElement()
        ..dur = MeiDuration.dur4
        ..dots = 1;
      expect(dq.getInterfaceAlignmentDuration(1, 1), Fraction(3, 8));

      // Double-dotted half.
      final ddh = DurableElement()
        ..dur = MeiDuration.dur2
        ..dots = 2;
      expect(ddh.getInterfaceAlignmentDuration(1, 1), Fraction(7, 8));

      // With @num/@numbase triplet: three in the time of two quarters.
      final trip = DurableElement()
        ..dur = MeiDuration.dur4
        ..num = 3
        ..numbase = 2;
      // Mirrors the C++ arithmetic: 1/4 scaled by numBase/num = 2/3.
      expect(trip.getInterfaceAlignmentDuration(1, 1), Fraction(1, 6));
    });

    test('MIDI timing accessors', () {
      final el = DurableElement();
      el.setScoreTimeOnset(Fraction(3, 2));
      el.setScoreTimeOffset(Fraction(7, 4));
      el.setRealTimeOnsetSeconds(1.5);
      el.setRealTimeOffsetSeconds(2.75);
      el.setScoreTimeTiedDuration(Fraction(1));

      expect(el.scoreTimeOnset, Fraction(3, 2));
      expect(el.scoreTimeOffset, Fraction(7, 4));
      expect(el.getScoreTimeDuration(), Fraction(1, 4));
      expect(el.realTimeOnsetMilliseconds, 1500.0);
      expect(el.realTimeOffsetMilliseconds, 2750.0);
    });

    test('mensural equivalence with brevis reference', () {
      final el = DurableElement()..dur = MeiDuration.maxima;

      final mensur = _TestMensur(
        modusmaior: Modusmaior.n3,
        modusminor: Modusminor.n2,
        tempus: Tempus.n2,
        prolatio: Prolatio.n3,
      );
      // maxima = breve(2/1) * |modusminor|(2) * |modusmaior|(3) = 12.
      final d = el.getInterfaceAlignmentMensuralDuration(
          1, 1, mensur, MeiDuration.breve);
      expect(d, Fraction(12));
    });
  });

  group('TimePoint / TimeSpanning interfaces', () {
    test('setStartOnly matches by id fragment', () {
      final ctrl = PointingControl();
      ctrl.startid = '#note-42';
      ctrl.setIDStr();
      expect(ctrl.startID, 'note-42');

      final element = Object()..id = 'note-42';
      expect(ctrl.setStartOnly(element), isTrue);
      expect(ctrl.start, same(element));

      final other = Object()..id = 'note-43';
      final second = PointingControl();
      second.startid = '#note-42';
      second.setIDStr();
      expect(second.setStartOnly(other), isFalse);
      expect(second.hasStart, isFalse);
    });

    test('addStaff accumulates unique staff numbers', () {
      final ctrl = PointingControl();
      ctrl.addStaff(2);
      ctrl.addStaff(1);
      ctrl.addStaff(2);
      expect(ctrl.staff, [2, 1]);
    });

    test('spanning start/end resolution', () {
      final slur = SpanningControl();
      slur.startid = '#n1';
      slur.endid = '#n2';
      slur.setIDStr();

      final n1 = Object()..id = 'n1';
      final n2 = Object()..id = 'n2';

      expect(slur.hasStartAndEnd, isFalse);
      slur.setStart(n1);
      slur.setEnd(n2);
      expect(slur.hasStartAndEnd, isTrue);
    });
  });

  group('LinkingInterface', () {
    test('addBackLink uses the id or the existing corresp', () {
      final first = LinkedElement();
      final target = Object()..id = 'target-id';

      first.addBackLink(target);
      expect(first.corresp, '#target-id');

      // If the target has its own corresp, it is reused.
      final linkedTarget = LinkedElement()..corresp = '#other';
      final second = LinkedElement();
      second.addBackLink(linkedTarget);
      expect(second.corresp, '#other');
    });

    test('setIDStr extracts fragments from next/sameas', () {
      final el = LinkedElement()
        ..next = '#m-next'
        ..sameas = '#s-sameas';
      el.setIDStr();
      expect(el.nextID, 'm-next');
      expect(el.sameasID, 's-sameas');
    });
  });

  group('PlistInterface', () {
    test('addRef avoids duplicates, allowDuplicate does not', () {
      final el = ReferencingElement();
      el.addRef('#a');
      el.addRef('#a');
      expect(el.plist, ['#a']);

      el.addRefAllowDuplicate('#a');
      expect(el.plist, ['#a', '#a']);
    });

    test('setIDStrs parses the plist uris', () {
      final el = ReferencingElement()
        ..plist = ['#one', '#two'];
      el.setIDStrs();
      expect(el.ids, ['one', 'two']);
    });

    test('setRef stores unique validated refs', () {
      final el = ReferencingElement();
      final o1 = Object();
      el.setRef(o1);
      el.setRef(o1);
      expect(el.getRefs().length, 1);

      final strict = StrictReferencingElement();
      strict.setRef(Object());
      expect(strict.getRefs(), isEmpty);
    });
  });
}

class StrictReferencingElement extends ReferencingElement {
  @override
  bool isValidRef(Object ref) => false;
}

class _TestMensur implements MensurValues {
  _TestMensur({
    required this.modusmaior,
    required this.modusminor,
    required this.tempus,
    required this.prolatio,
  });

  @override
  final Modusmaior modusmaior;
  @override
  final Modusminor modusminor;
  @override
  final Tempus tempus;
  @override
  final Prolatio prolatio;
}

// ---------------------------------------------------------------------------
// Zone / FacsimileInterface
// ---------------------------------------------------------------------------

class FacsNote extends Object
    with AttFacsimile, FacsimileInterface {}

void testFacsimile() {
  final surface = FacsSurface();
  final zone = Zone()
    ..ulx = 10
    ..uly = 20
    ..lrx = 110
    ..lry = 60;
  surface.addChild(zone);

  expect(zone.shiftByXY, isNotNull);
  zone.shiftByXY(5, -5);
  expect(zone.ulx, 15);
  expect(zone.lrx, 115);
  expect(zone.getLogicalUly(), 15);

  final note = FacsNote();
  expect(note.hasFacsimile, isFalse);
  note.facs = '#zone-1';
  expect(note.hasFacsimile, isTrue);
  note.attachZone(zone);
  expect(note.zone, same(zone));
  expect(note.surface, same(surface));

  // A zone without a surface parent warns and clears the surface.
  final orphan = Zone();
  final note2 = FacsNote();
  note2.attachZone(orphan);
  expect(note2.zone, same(orphan));
  expect(note2.surface, isNull);
}
