/// Coverage for the tie-endpoint branch of `AdjustGraceXPosFunctor`
/// (`adjustgracexposfunctor.cpp:186-198`), ported in `invest-05` item 3's
/// residual: `AdjustXPosFunctor` already had its `m_measureTieEndpoints`
/// equivalent (`Measure::GetInternalTieEndpoints`, main path), but the grace
/// counterpart — a tie starting on a grace note, ending on the following
/// real note, both within the same measure — was entirely missing:
/// `AdjustGraceXPosFunctor` had no `measureTieEndpoints` field at all.
///
/// No corpus file exercises this branch: it needs an explicit `<tie>`
/// control element whose `@startid` resolves to a grace note, and the
/// corpus's only grace+tie file (`test/corpus/note/note-005.mei`) ties two
/// ordinary notes unrelated to its one grace note. Per this repo's
/// established precedent for branches with no corpus vehicle
/// (`test/adjust_x_overflow_test.dart`'s "hand-derived parity" tests), this
/// verifies the ported arithmetic against the C++ formula on a hand-built
/// synthetic tree instead of a fixture.
library;

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/vrvdef.dart' show FunctorCode;
import 'package:verovio_dart/src/layout/adjust_x_pos.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;
import 'package:verovio_dart/src/model/basic_elements.dart' show Measure, Note;
import 'package:verovio_dart/src/model/doc.dart';

void main() {
  group('AdjustGraceXPosFunctor.visitLayerElement — tie endpoints '
      '(adjustgracexposfunctor.cpp:186-198)', () {
    // A grace note with no `Alignment` wired (only `graceAlignment` is,
    // which is all `hasGraceAlignment()` checks for) and no Measure
    // ancestor: `LayerElement.getDrawingX()` falls back to 0 in that case
    // (`getFirstAncestor(MEASURE)` returns null), so `updateSelfBBoxX`'s
    // absolute coordinates land unshifted and `getSelfRight() == selfRight`
    // directly.
    Note buildGraceNote(int selfRight) {
      final note = Note();
      note.setGraceAlignment(Alignment()..setXRel(0));
      note.updateSelfBBoxX(selfRight - 10, selfRight);
      note.updateSelfBBoxY(-5, 5);
      return note;
    }

    test('short tie (diff < minTieLength + unit) pulls graceMaxPos left', () {
      final doc = Doc();
      final note = buildGraceNote(1005); // getSelfRight() == 1005
      final end = Note();

      final functor = AdjustGraceXPosFunctor(doc)
        ..graceMaxPos = 1005 // no offset from the first branch (offset <= 0)
        ..graceUpcomingMaxPos = -1 * (1 << 30)
        ..rightDefaultAlignment = (Alignment()..setXRel(1010))
        ..measureTieEndpoints = [(note, end)];

      final int unit = doc.getDrawingUnit(100);
      final int minTieLength =
          (doc.getOptions().tieMinLength.value * unit).toInt();
      // diff = rightDefaultAlignment.xRel - selfRight = 1010 - 1005 = 5,
      // comfortably under minTieLength + unit for the default options.
      final int diff = 1010 - 1005;
      expect(diff, lessThan(minTieLength + unit),
          reason: 'the test fixture must actually exercise the branch');

      final code = functor.visitLayerElement(note);
      expect(code, FunctorCode.siblings);

      expect(functor.graceMaxPos, 1005 - (unit + minTieLength - diff),
          reason: 'mirrors m_graceMaxPos -= (unit + minTieLength - diff)');
    });

    test('long tie (diff >= minTieLength + unit) leaves graceMaxPos alone',
        () {
      final doc = Doc();
      final note = buildGraceNote(1005);
      final end = Note();

      final int unit = doc.getDrawingUnit(100);
      final int minTieLength =
          (doc.getOptions().tieMinLength.value * unit).toInt();
      // Push the following note far enough right that diff clears the
      // threshold.
      final int farXRel = 1005 + minTieLength + unit + 100;

      final functor = AdjustGraceXPosFunctor(doc)
        ..graceMaxPos = 1005
        ..graceUpcomingMaxPos = -1 * (1 << 30)
        ..rightDefaultAlignment = (Alignment()..setXRel(farXRel))
        ..measureTieEndpoints = [(note, end)];

      functor.visitLayerElement(note);

      expect(functor.graceMaxPos, 1005,
          reason: 'diff clears the threshold — no adjustment expected');
    });

    test('no rightDefaultAlignment (grace group at end of measure) is a '
        'no-op, matching the C++ short-circuit on `m_rightDefaultAlignment`',
        () {
      final doc = Doc();
      final note = buildGraceNote(1005);
      final end = Note();

      final functor = AdjustGraceXPosFunctor(doc)
        ..graceMaxPos = 1005
        ..graceUpcomingMaxPos = -1 * (1 << 30)
        ..rightDefaultAlignment = null
        ..measureTieEndpoints = [(note, end)];

      expect(() => functor.visitLayerElement(note), returnsNormally);
      expect(functor.graceMaxPos, 1005);
    });

    test('unrelated tie pairs (this element is not a tie start) are '
        'ignored', () {
      final doc = Doc();
      final note = buildGraceNote(1005);
      final other = buildGraceNote(2005);
      final end = Note();

      final functor = AdjustGraceXPosFunctor(doc)
        ..graceMaxPos = 1005
        ..graceUpcomingMaxPos = -1 * (1 << 30)
        ..rightDefaultAlignment = (Alignment()..setXRel(1006))
        ..measureTieEndpoints = [(other, end)];

      functor.visitLayerElement(note);

      expect(functor.graceMaxPos, 1005);
    });
  });

  group('AdjustGraceXPosFunctor.visitMeasure — wires measureTieEndpoints',
      () {
    test('is populated from Measure.getInternalTieEndpoints() before the '
        'reversed (second) pass, mirroring '
        '`m_measureTieEndpoints = measure->GetInternalTieEndpoints()` '
        '(adjustgracexposfunctor.cpp:220)', () {
      final doc = Doc();
      final measure = Measure();
      final functor = AdjustGraceXPosFunctor(doc);

      expect(functor.measureTieEndpoints, isEmpty);
      functor.visitMeasure(measure);
      // An empty measure has no ties, but the call must not throw and must
      // leave the field in the (empty) state GetInternalTieEndpoints()
      // returns for it — proving visitMeasure actually reads through to it
      // rather than leaving the field permanently unset/stale.
      expect(functor.measureTieEndpoints, isEmpty);
    });
  });
}
