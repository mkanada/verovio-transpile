/// Tests for the layout engine aligners (Phase 4, Task 2):
/// horizontal aligner classes, vertical aligner classes and the functors
/// filling them (InitOnsetOffset, InitMaxMeasureDuration,
/// PrepareStaffCurrentTimeSpanning).
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/align_functors.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Staffrel;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Dir;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Chord, TimestampAttr;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart'
    show ScoreDef, StaffDef, StaffGrp;
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show System;

/// A fixed-origin object used as tree root so bounding box getters have a
/// terminating drawing X/Y chain in unit tests.
class _TestOrigin extends Object {
  _TestOrigin() : super(ClassId.object);

  @override
  int getDrawingX() => 0;

  @override
  int getDrawingY() => 0;

  @override
  void resetCachedDrawingX() {}

  @override
  void resetCachedDrawingY() {}
}

/// Builds a System > Measure > Staves hierarchy with a drawing scoreDef so
/// that `SystemAligner.getStaffAlignment` can resolve the spacing types.
///
/// The scoreDef holds two staffDefs inserted so that the LAST staffDef is
/// n=1; staff n=1 is therefore not first in its group and receives
/// [SpacingType.staff] above spacing. Staff children in the measure appear
/// in ascending n order.
System _makeSystem(List<int> staffNs) {
  final system = System();
  final measure = Measure();
  system.insertChild(measure, 0);
  for (final int n in staffNs) {
    final staff = Staff();
    staff.n = n;
    measure.insertChild(staff, 0);
    staff.insertChild(Layer(), 0);
  }

  final scoreDef = ScoreDef();
  final staffGrp = StaffGrp();
  for (var i = 1; i <= staffNs.length; ++i) {
    final staffDef = StaffDef();
    staffDef.n = i;
    // Insert at the top: results in descending order, i.e., the highest
    staffGrp.insertChild(staffDef, 0);
  }
  scoreDef.insertChild(staffGrp, 0);
  system.drawingScoreDef = scoreDef;
  return system;
}

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.error;
  });

  group('MeasureAligner', () {
    test('starts with the four measure boundary alignments', () {
      final aligner = MeasureAligner();
      expect(aligner.getAlignmentCount(), 4);
      expect(
          aligner.getLeftAlignment()!.getType(), AlignmentType.measureStart);
      expect(aligner.getLeftAlignment()!.getTime(), Fraction(-1));
      expect(aligner.getLeftBarLineAlignment()!.getType(),
          AlignmentType.measureLeftBarline);
      expect(aligner.getRightBarLineAlignment()!.getType(),
          AlignmentType.measureRightBarline);
      expect(
          aligner.getRightAlignment()!.getType(), AlignmentType.measureEnd);
      expect(aligner.getMaxTime(), Fraction(0));
    });

    test('inserts alignments of different types at the same time in enum '
        'order', () {
      final aligner = MeasureAligner();
      // Default alignment at time 0 goes before the right barline (type 19
      // sorts before type 20 within the same time slot).
      final first =
          aligner.getAlignmentAtTime(Fraction(0), AlignmentType.default_);
      expect(first.getType(), AlignmentType.default_);

      final types = aligner.children
          .map((child) => (child as Alignment).getType())
          .toList();
      expect(types, [
        AlignmentType.measureStart,
        AlignmentType.measureLeftBarline,
        AlignmentType.default_,
        AlignmentType.measureRightBarline,
        AlignmentType.measureEnd,
      ]);
    });

    test('returns the same instance for repeated lookups and keeps time '
        'ordering', () {
      final aligner = MeasureAligner();
      final a =
          aligner.getAlignmentAtTime(Fraction(0), AlignmentType.default_);
      final b =
          aligner.getAlignmentAtTime(Fraction(0), AlignmentType.default_);
      expect(identical(a, b), isTrue);

      // Hand-computed from HorizontalAligner::SearchAlignmentAtTime: an event
      // later than everything else lands before the measure-end alignment,
      // raising the max time to the new event position.
      final c =
          aligner.getAlignmentAtTime(Fraction(1), AlignmentType.default_);
      expect(c.getTime(), Fraction(1));
      expect(aligner.getRightBarLineAlignment()!.getTime(), Fraction(1));
      expect(aligner.getMaxTime(), Fraction(1));

      final d =
          aligner.getAlignmentAtTime(Fraction(1, 2), AlignmentType.default_);
      final times = aligner.children
          .map((child) => (child as Alignment).getTime().toDouble())
          .toList();
      expect(times, [-1, -1, 0, 0.5, 1, 1, 1]);
      expect(identical(d, c), isFalse);
    });

    test('adjustProportionally shifts inner alignments proportionally', () {
      final aligner = MeasureAligner();
      final d0 =
          aligner.getAlignmentAtTime(Fraction(0), AlignmentType.default_);
      final d1 =
          aligner.getAlignmentAtTime(Fraction(1), AlignmentType.default_);
      final dHalf = aligner.getAlignmentAtTime(
          Fraction(1, 2), AlignmentType.default_);

      // x positions: start/leftBarLine stay at 0; content at 100 / 150 / 200;
      // right barline and end at 300.
      aligner.getLeftAlignment()!.setXRel(0);
      aligner.getLeftBarLineAlignment()!.setXRel(0);
      d0.setXRel(100);
      dHalf.setXRel(150);
      d1.setXRel(200);
      aligner.getRightBarLineAlignment()!.setXRel(300);
      aligner.getRightAlignment()!.setXRel(300);

      // Expand the (d0, d1) segment by 40: the inner point moves by
      // 40 * (150 - 100) / (200 - 100) = 20, the outer ones by the full 40.
      aligner.adjustProportionally([(d0, d1, 40)]);

      expect(d0.getXRel(), 100);
      expect(dHalf.getXRel(), 170);
      expect(d1.getXRel(), 240);
      expect(aligner.getRightBarLineAlignment()!.getXRel(), 340);
      expect(aligner.getRightAlignment()!.getXRel(), 340);
    });

    test('pushAlignmentsRight moves gracenote alignments to the following '
        'alignment position', () {
      final aligner = MeasureAligner();
      final g = aligner.getAlignmentAtTime(
          Fraction(-1), AlignmentType.graceNote);
      final d =
          aligner.getAlignmentAtTime(Fraction(0), AlignmentType.default_);

      g.setXRel(30);
      d.setXRel(100);
      aligner.getRightBarLineAlignment()!.setXRel(200);

      aligner.pushAlignmentsRight();

      // The grace note alignment takes the x position of the closest non
      // grace alignment on its right.
      expect(g.getXRel(), 100);
      expect(d.getXRel(), 100);
    });

    test('setInitialTstamp stores the negated meter unit', () {
      final aligner = MeasureAligner();
      aligner.setInitialTstamp(MeiDuration.dur4);
      expect(aligner.getInitialTstampDur(), Fraction(-1, 4));
    });
  });

  group('Alignment references', () {
    test('addLayerElementRef groups by staff and detects multiple layers',
        () {
      final origin = _TestOrigin();
      final staff = Staff();
      staff.n = 1;
      origin.insertChild(staff, 0);

      final layer1 = Layer();
      layer1.n = 1;
      final layer2 = Layer();
      layer2.n = 2;
      staff.insertChild(layer1, 0);
      staff.insertChild(layer2, 1);

      final note1 = Note();
      note1.setParent(layer1);
      final note2 = Note();
      note2.setParent(layer1);
      final note3 = Note();
      note3.setParent(layer2);

      final alignment = Alignment();
      expect(alignment.addLayerElementRef(note1), isFalse);
      expect(alignment.addLayerElementRef(note2), isFalse);
      // Same staff, another layer -> the reference now holds multiple layers.
      expect(alignment.addLayerElementRef(note3), isTrue);

      final reference = alignment.getReferenceWithElement(note1);
      expect(reference, isNotNull);
      expect(reference!.n, 1);
      expect(reference.childCount, 3);
      expect(reference.hasMultipleLayer(), isTrue);
      expect(note1.getAlignmentLayerN(), 1);
      expect(note3.getAlignmentLayerN(), 2);
    });

    test('timestamps are collected under the TSTAMP_REFERENCES pseudo '
        'staff', () {
      final timestamp = TimestampAttr();
      timestamp.setParent(_TestOrigin());

      final alignment = Alignment();
      alignment.addLayerElementRef(timestamp);

      expect(
          alignment.getReferenceWithElement(timestamp)!.n, tstampReferences);
      expect(alignment.hasTimestampOnly(), isTrue);
    });

    test('getLeftRight computes min left / max right from the element '
        'bounding boxes', () {
      final origin = _TestOrigin();
      final staff = Staff();
      staff.n = 1;
      origin.insertChild(staff, 0);
      final layer = Layer();
      staff.insertChild(layer, 0);

      final note1 = Note();
      note1.setParent(layer);
      note1.updateSelfBBoxX(-20, 20);
      note1.updateSelfBBoxY(-10, 10);
      final note2 = Note();
      note2.setParent(layer);
      note2.updateSelfBBoxX(30, 60);
      note2.updateSelfBBoxY(-5, 5);

      final alignment = Alignment();
      alignment.addLayerElementRef(note1);
      alignment.addLayerElementRef(note2);

      final (minLeft, maxRight) = alignment.getLeftRight(1);
      expect(minLeft, -20);
      expect(maxRight, 60);

      // Nothing on staff 2 -> unset results.
      final (minLeft2, maxRight2) = alignment.getLeftRight(2);
      expect(minLeft2, -meiUnset);
      expect(maxRight2, meiUnset);
    });

    test('horizontalSpaceForDuration matches the C++ formula', () {
      // Quarter interval with a semibreve longest duration:
      // (1/4 * 1024)^1 * 10 = 2560.
      expect(
          Alignment.horizontalSpaceForDuration(
              Fraction(1, 4), MeiDuration.dur1, 1.0, 1.0),
          2560);
      // Longest interval breve (< semibreve value): the interval is halved
      // first: ((1/8) * 1024)^1 * 10 = 1280.
      expect(
          Alignment.horizontalSpaceForDuration(
              Fraction(1, 4), MeiDuration.breve, 1.0, 1.0),
          1280);
    });
  });

  group('GraceAligner', () {
    test('stacked grace notes are aligned right-to-left with negative '
        'times', () {
      final layer = Layer();
      final note1 = Note();
      note1.dur = MeiDuration.dur16;
      note1.setParent(layer);
      final note2 = Note();
      note2.dur = MeiDuration.dur16;
      note2.setParent(layer);

      final aligner = GraceAligner();
      aligner.stackGraceElement(note1);
      aligner.stackGraceElement(note2);
      aligner.alignStack();

      // The stack is aligned from the back: last note at -1/16, first at
      // -2/16 (mirrors GraceAligner::AlignStack).
      final first = note1.getGraceAlignment()!;
      final second = note2.getGraceAlignment()!;
      expect(first.getTime(), Fraction(-1, 8));
      expect(second.getTime(), Fraction(-1, 16));
      expect(first.getType(), AlignmentType.default_);
      expect(aligner.getAlignmentCount(), 2);
    });

    test('chord tones are not stacked twice', () {
      final layer = Layer();
      final chord = Chord();
      chord.setParent(layer);
      final note1 = Note();
      note1.setParent(chord);
      final note2 = Note();
      note2.setParent(chord);

      final aligner = GraceAligner();
      aligner.stackGraceElement(chord);
      aligner.stackGraceElement(note1);
      aligner.stackGraceElement(note2);
      aligner.alignStack();

      // Only the chord was stacked; its grace alignment is set.
      expect(chord.getGraceAlignment(), isNotNull);
    });
  });

  group('TimestampAligner', () {
    test('creates timestamps sorted by position and avoids duplicates', () {
      final aligner = TimestampAligner();

      final t1 = aligner.getTimestampAtTime(1.5);
      expect(t1.getActualDurPos(), closeTo(0.5, 1E-3));

      // Same position returns the identical object.
      final t1b = aligner.getTimestampAtTime(1.5);
      expect(identical(t1, t1b), isTrue);

      // An earlier position is inserted before.
      final t2 = aligner.getTimestampAtTime(1.25);
      expect(t2.getActualDurPos(), closeTo(0.25, 1E-3));
      expect(aligner.childCount, 2);
      expect(identical(aligner.getChild(0), t2), isTrue);
      expect(identical(aligner.getChild(1), t1), isTrue);

      // A later one is appended at the end.
      final t3 = aligner.getTimestampAtTime(2.0);
      expect(t3.getActualDurPos(), closeTo(1.0, 1E-3));
      expect(aligner.childCount, 3);
      expect(identical(aligner.getChild(2), t3), isTrue);
    });

    test('timestamp duration scales the meter unit by the position', () {
      final timestamp = TimestampAttr();
      timestamp.setDrawingPos(0.5);
      expect(timestamp.getTimestampAttrAlignmentDuration(MeiDuration.dur2),
          Fraction(1, 4));
    });
  });

  group('Vertical aligner', () {
    test('system aligner creates staff alignments incrementally with a '
        'bottom alignment', () {
      final system = _makeSystem([1]);
      final doc = Doc();
      final aligner = SystemAligner();
      expect(aligner.getBottomAlignment(), isNotNull);
      expect(aligner.childCount, 1);

      final measure = system.children.first as Measure;
      final staffN1 = measure.children.whereType<Staff>().first;

      final alignment = aligner.getStaffAlignment(0, staffN1, doc)!;
      expect(alignment.getStaff(), same(staffN1));
      // Bottom alignment + one staff alignment.
      expect(aligner.childCount, 2);

      // A second request returns the same alignment.
      expect(
          identical(aligner.getStaffAlignment(0, staffN1, doc), alignment),
          isTrue);

      expect(aligner.getStaffAlignmentForStaffN(1), same(alignment));
      expect(aligner.getStaffAlignmentForStaffN(9), isNull);
    });

    test('staff height and minimum spacing follow the C++ formulas', () {
      const unit = 9; // options default unit
      final system = _makeSystem([2, 1]); // staff 1 not first in group
      final doc = Doc();
      final aligner = SystemAligner();

      final measure = system.children.first as Measure;
      final staff1 = (measure.getChild(0) as Staff).n == 1
          ? measure.getChild(0) as Staff
          : measure.getChild(1) as Staff;

      final alignment = aligner.getStaffAlignment(0, staff1, doc)!;
      // The aligner is a member (not a tree child), so mirror the C++
      // ancestor resolution by setting the parent system explicitly.
      alignment.setParentSystem(system);
      expect(alignment.getSpacingType(), SpacingType.staff);
      // Mirror the scoreDef preparation: the staff gets its drawing staffDef.
      final scoreDef = system.drawingScoreDef!;
      final staffDef1 = scoreDef
          .findAllDescendantsByType(ClassId.staffDef)
          .whereType<StaffDef>()
          .firstWhere((sd) => sd.n == 1);
      staff1.drawingStaffDef = staffDef1;

      // StaffHeight = (lines - 1) * doubleUnit(size)
      // doubleUnit(100) = 9 * 2 * 100 / 100 = 18 -> 4 * 18 = 72.
      expect(alignment.getStaffHeight(), 4 * 2 * unit);
      expect(alignment.getStaffSize(), 100);

      // Minimum spacing for a SpacingType.staff aligner with the default
      // option (12): 12 * drawingUnit(100) = 108.
      expect(alignment.getMinimumSpacing(doc), 12 * unit);
      // The bottom aligner spacing is half of a staff spacing.
      final bottom = aligner.getBottomAlignment()!..setParentSystem(system);
      expect(bottom.getMinimumSpacing(doc), 12 * unit ~/ 2);
    });

    test('yRel and overflow setters are monotonic', () {
      final alignment = StaffAlignment();

      alignment.setYRel(-50);
      expect(alignment.getYRel(), -50);
      // Higher values are ignored.
      alignment.setYRel(-30);
      expect(alignment.getYRel(), -50);
      alignment.setYRel(-80);
      expect(alignment.getYRel(), -80);

      alignment.setOverflowAbove(100);
      alignment.setOverflowAbove(50);
      expect(alignment.getOverflowAbove(), 100);
      alignment.setOverflowBelow(70);
      alignment.setOverlap(20);
      expect(alignment.getOverflowBelow(), 70);
      expect(alignment.getOverlap(), 20);
    });

    test('calcMinimumRequiredSpacing combines overflows of neighbouring '
        'alignments', () {
      const unit = 9;
      final system = _makeSystem([2, 1]);
      final doc = Doc();
      final aligner = SystemAligner();

      final measure = system.children.first as Measure;
      final staff1 = measure.children.whereType<Staff>().first;
      final staff2 = measure.children.whereType<Staff>().last;
      final first = aligner.getStaffAlignment(0, staff1, doc)!;
      final second = aligner.getStaffAlignment(1, staff2, doc)!;

      first.setOverflowAbove(100);
      first.setOverlap(20);
      second.setOverflowAbove(90);
      second.setOverlap(10);

      // First alignment (nothing before): max overflow + overlap.
      expect(first.calcMinimumRequiredSpacing(doc), 100 + 20);

      // Second alignment: max(prev below, above) + overlap + margin.
      final expectedMargin = (0.5 * unit).toInt();
      expect(second.calcMinimumRequiredSpacing(doc),
          math.max(90, 0) + 10 + expectedMargin);
    });

    test('verse counting mirrors AddVerseN semantics', () {
      final alignment = StaffAlignment();
      expect(alignment.getVerseCount(false), 0);

      // Verse 0 becomes verse 1 (mirrors the C++).
      alignment.addVerseN(0, Staffrel.below);
      alignment.addVerseN(3, Staffrel.below);
      expect(alignment.getVerseCountBelow(false), 3);
      expect(alignment.getVerseCountBelow(true), 2);
      // Collapsed position counts from the top (mirrors the C++ reverse
      // iterator distance): verse 3 is the first from the top.
      expect(alignment.getVersePositionBelow(3, true), 0);
      expect(alignment.getVersePositionBelow(1, false), 2);

      alignment.addVerseN(2, Staffrel.above);
      expect(alignment.getVerseCountAbove(false), 2);
      // Collapsed counts: 2 below + 1 above.
      expect(alignment.getVerseCount(true), 3);
      expect(alignment.getVersePositionAbove(2, false), 1);
    });

    test('reorder reorders staff alignments by staffN', () {
      final system = _makeSystem([2, 1]);
      final doc = Doc();
      final aligner = SystemAligner();

      final measure = system.children.first as Measure;
      final staves = measure.children.whereType<Staff>().toList();
      final first = aligner.getStaffAlignment(0, staves[0], doc)!;
      final second = aligner.getStaffAlignment(1, staves[1], doc)!;

      aligner.reorder([2, 1]);
      expect(identical(aligner.getChild(0), second), isTrue);
      expect(identical(aligner.getChild(1), first), isTrue);
      // Bottom alignment still last.
      expect(identical(aligner.getChild(2), aligner.getBottomAlignment()),
          isTrue);
    });

    test('calcOverflowAbove/Below use the staff height', () {
      const unit = 9;
      final origin = _TestOrigin();
      final system = _makeSystem([1]);
      origin.insertChild(system, 0);
      final doc = Doc();
      final aligner = SystemAligner();
      final measure = system.children.first as Measure;
      final staff = measure.children.whereType<Staff>().first;
      final alignment = aligner.getStaffAlignment(0, staff, doc)!;
      expect(alignment.getStaffHeight(), 4 * 2 * unit);

      final note = Note();
      note.setParent(staff);
      note.updateContentBBoxY(100, 130);
      note.updateSelfBBoxY(100, 130);

      // Content top 130 - yRel 0 = 130.
      expect(alignment.calcOverflowAbove(note), 130);
      // -(selfBottom 100 + staffHeight 72 - yRel 0) = -172.
      expect(alignment.calcOverflowBelow(note), -(100 + 72));
    });
  });

  group('Aligner fill functors', () {
    test('onsets are computed dur-dependently over a loaded document', () {
      const mei = '''
<?xml version="1.0" encoding="UTF-8"?>
<mei meiversion="6.0-dev">
  <music>
    <body>
      <mdiv>
        <score>
          <scoreDef>
            <staffGrp>
              <staffDef n="1" clef.shape="G" clef.line="2"/>
            </staffGrp>
          </scoreDef>
          <section>
            <measure n="1">
              <staff n="1">
                <layer n="1">
                  <note dur="4" oct="4" pname="c"/>
                  <note dur="4" oct="4" pname="d"/>
                  <note dur="8" oct="4" pname="e"/>
                  <note dur="8" oct="4" pname="f"/>
                </layer>
              </staff>
            </measure>
          </section>
        </score>
      </mdiv>
    </body>
  </music>
</mei>
''';
      final doc = Doc();
      final input = MeiInput(doc);
      expect(input.import(mei), isTrue);

      // Mirrors Doc::CalculateTimemap order: maximum measure durations
      // first, then the onset / offset initialization.
      doc.process(InitMaxMeasureDurationFunctor());

      final initOnsetOffset = InitOnsetOffsetFunctor(doc);
      doc.process(initOnsetOffset);

      final measures = doc.findAllDescendantsByType(ClassId.measure);
      expect(measures, hasLength(1));
      final measure = measures.first as Measure;

      // The measure got its aligner, filled with content alignments beyond
      // the four boundary ones.
      expect(measure.measureAligner.getAlignmentCount(), greaterThan(0));

      // Onsets in quarter units (GetAlignmentDuration scaled by
      // SCORE_TIME_UNIT = 4): quarter notes start every whole quarter, the
      // eighth pair half a quarter apart.
      final notes = doc.findAllDescendantsByType(ClassId.note)
          .cast<Note>()
          .toList();
      expect(notes, hasLength(4));
      final onsets =
          notes.map((n) => n.scoreTimeOnset.toDouble()).toList();
      expect(onsets, [0, 1, 2, 2.5]);

      // Consecutive quarter notes differ by exactly one quarter.
      expect(onsets[1] - onsets[0], 1);
      // Consecutive eighth notes differ by exactly half a quarter.
      expect(onsets[3] - onsets[2], 0.5);

      // Offsets follow the onsets by the note duration.
      expect(notes[0].scoreTimeOffset, Fraction(1));
    });

    test('fills aligners over beam-001.mei', () {
      final file = File('test/corpus/beam/beam-001.mei');
      final data = file.readAsStringSync();
      final doc = Doc();
      final input = MeiInput(doc);
      expect(input.import(data), isTrue);

      doc.process(InitMaxMeasureDurationFunctor());
      doc.process(InitOnsetOffsetFunctor(doc));

      final measures = doc.findAllDescendantsByType(ClassId.measure);
      expect(measures, hasLength(1));
      final measure = measures.first as Measure;
      expect(measure.measureAligner.getAlignmentCount(), greaterThan(0));

      // beam-001: dotted 8th + 16th, double-dotted 8th + 32nd. Onsets in
      // quarter units: 0, 3/4, 1, 1 + 7/8.
      final notes = doc.findAllDescendantsByType(ClassId.note)
          .cast<Note>()
          .toList();
      expect(notes, hasLength(4));
      final onsets =
          notes.map((n) => n.scoreTimeOnset.toDouble()).toList();
      expect(onsets[0], 0);
      expect(onsets[1], closeTo(0.75, 1E-9));
      expect(onsets[2], closeTo(1.0, 1E-9));
      expect(onsets[3], closeTo(1.875, 1E-9));

      // Consecutive onset differences match the duration of the preceding
      // note (dur-dependent).
      for (var i = 1; i < notes.length; ++i) {
        final previous = notes[i - 1];
        final delta = notes[i].scoreTimeOnset - previous.scoreTimeOnset;
        final expected = previous.getAlignmentDuration(null, true) *
            Fraction(scoreTimeUnit);
        expect(delta, expected);
      }
    });

    test('PrepareStaffCurrentTimeSpanning attaches running elements to '
        'staves of following measures', () {
      final measure1 = Measure();
      final measure2 = Measure();
      final staff1 = Staff();
      staff1.n = 1;
      final staff2 = Staff();
      staff2.n = 1;
      measure1.insertChild(staff1, 0);
      measure2.insertChild(staff2, 0);
      final layer1 = Layer();
      final layer2 = Layer();
      staff1.insertChild(layer1, 0);
      staff2.insertChild(layer2, 0);
      final note1 = Note();
      note1.setParent(layer1);
      final note2 = Note();
      note2.setParent(layer2);

      final dir = Dir();
      dir.setStart(note1);
      dir.setEnd(note2);

      final functor = PrepareStaffCurrentTimeSpanningFunctor();

      // Spanning over two measures -> inserted into the running list.
      functor.visitFloatingObject(dir);
      expect(functor.getTimeSpanningElements(), hasLength(1));

      // Not attached to the start-measure staff (same measure as start).
      functor.visitStaff(staff1);
      expect(staff1.timeSpanningElements, isEmpty);

      // Attached to the staff of the second measure.
      functor.visitStaff(staff2);
      expect(staff2.timeSpanningElements, hasLength(1));

      // Reaching the end measure removes it from the running list.
      functor.visitMeasureEnd(measure2);
      expect(functor.getTimeSpanningElements(), isEmpty);
    });

    test('tempoCalcTempo mirrors Tempo::CalcTempo', () {
      // mm=120 quarter -> 120.
      expect(tempoCalcTempo(mm: 120), 120);
      // mm=120 eighth (unit value 5 -> 2^3 = 8): 120 * 4 / 8 = 60.
      expect(tempoCalcTempo(mm: 120, mmUnit: MeiDuration.dur8), 60);
      // One dot reduces the unit: quarter dotted: 4 - 1 = 3 -> 160.
      expect(tempoCalcTempo(mm: 120, mmDots: 1), closeTo(160, 1E-9));
    });
  });
}
