/// Port of `adjustarpegfunctor.h/cpp` — AdjustArpegFunctor, plus the
/// `Arpeg::GetDrawingTopBottomNotes` helper of arpeg.cpp.
///
/// The functor adjusts the x position of the arpeggios by looking at the
/// content of the preceding alignments.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart';
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Enclosure;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Measure, Note, Staff;
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Arpeg;
import 'package:verovio_dart/src/model/object.dart';

/// A tuple of an Alignment, an arpeg and a staffN with a flag indicating if
/// we have reached the alignment yet (mirrors the private struct
/// `vrv::AlignmentArpegTuple`).
class AlignmentArpegTuple {
  AlignmentArpegTuple(this.alignment, this.arpeg, this.staffN);

  Alignment alignment;
  Object arpeg;
  int staffN;
  bool reached = false;
}

/// This class adjusts the X position of the arpeggios (mirrors
/// `vrv::AdjustArpegFunctor`).
class AdjustArpegFunctor extends DocFunctor {
  AdjustArpegFunctor(super.doc) {
    measureAlignerRef = null;
  }

  /// The array of Alignment / arpeg / staffN / bool tuples (mirrors
  /// `m_alignmentArpegTuples`).
  final List<AlignmentArpegTuple> alignmentArpegTuples = [];

  /// The current measure aligner (mirrors `m_measureAligner`).
  MeasureAligner? measureAlignerRef;

  @override
  FunctorCode visitAlignment(Alignment alignment) {
    final AlignmentType alignmentType = alignment.getType();

    // We are reaching the alignment to which an arpeg points to (i.e., the
    // topNote one) or checking alignments preceding it
    for (int i = 0; i < alignmentArpegTuples.length; ++i) {
      final AlignmentArpegTuple tuple = alignmentArpegTuples[i];
      if (identical(tuple.alignment, alignment)) {
        tuple.reached = true;
        continue;
      }
      // We have not reached the alignment of the arpeg, just continue
      // (backwards)
      if (!tuple.reached) continue;

      // We are now in an alignment preceding an arpeg - check for overlap
      var (int minLeft, int maxRight) =
          alignment.getLeftRight(tuple.staffN);

      // Nothing for the staff we are looking at? We also need to check with
      // barlines
      if (maxRight == meiUnset) {
        (minLeft, maxRight) = alignment.getLeftRight(-1);
      }

      // Make sure that there is no overlap with right barline of the previous
      // measure (mirrors adjustarpegfunctor.cpp:58-71: the barline
      // alignment's own left/right, shifted back by the previous measure
      // width — not a 1-unit box around the XRel).
      if ((maxRight == meiUnset) &&
          (alignmentType == AlignmentType.measureLeftBarline)) {
        final Measure? measure =
            alignment.getFirstAncestor(ClassId.measure) as Measure?;
        if (measure != null) {
          final Object? parent = measure.parent;
          final Object? previousObject =
              parent?.getPreviousSibling(measure, ClassId.measure);
          final Measure? previous = previousObject is Measure ? previousObject : null;
          if (previous != null) {
            final Alignment? barLineAlignment =
                previous.measureAligner.getRightBarLineAlignment();
            if (barLineAlignment != null) {
              (minLeft, maxRight) = barLineAlignment.getLeftRight(-1);
              if (maxRight != meiUnset) {
                final int previousWidth = previous.getWidth();
                minLeft -= previousWidth;
                maxRight -= previousWidth;
              }
            }
          }
        }
      }

      // Make sure that there is no overlap with grace notes (since they are
      // handled separately by graceAligner) — mirrors
      // adjustarpegfunctor.cpp:74-85.
      if (alignmentType == AlignmentType.graceNote) {
        final int graceAlignerId =
            doc.getOptions().graceRhythmAlign.value ? 0 : tuple.staffN;
        if (alignment.hasGraceAligner(graceAlignerId)) {
          final GraceAligner graceAligner =
              alignment.getGraceAligner(graceAlignerId);
          maxRight = graceAligner.getGraceGroupRight(tuple.staffN);
          final FloatingPositioner? gracePositioner =
              (tuple.arpeg as Arpeg).getCurrentFloatingPositioner();
          if (gracePositioner != null) {
            final int graceOverlap =
                maxRight - gracePositioner.getSelfLeft();
            if (graceOverlap > 0) {
              final int drawingUnit = doc.getDrawingUnit(100);
              alignment.setXRel(alignment.getXRel() - drawingUnit ~/ 6);
            }
          }
        }
      }

      // Nothing, just continue
      if (maxRight == meiUnset) {
        continue;
      }

      final dynamic arpeg = tuple.arpeg;
      final FloatingPositioner? positioner =
          arpeg.getCurrentFloatingPositioner() as FloatingPositioner?;
      if (positioner == null) continue;

      final int overlap = maxRight - positioner.getSelfLeft();
      final int drawingUnit = doc.getDrawingUnit(100);
      // HARDCODED
      final int adjust = overlap + drawingUnit ~/ 2 * 3;
      if (adjust > 0) {
        measureAlignerRef?.adjustProportionally([
          (alignment, tuple.alignment, adjust),
        ]);
        // After adjusting, make sure that arpeggio does not overlap with
        // elements from the previous alignment — mirrors
        // adjustarpegfunctor.cpp:101-116: only for clef alignments with
        // real vertical overlap against the arpeg's top/bottom notes.
        if (alignmentType == AlignmentType.clef) {
          final (int currentMin, int currentMax) =
              alignment.getAlignmentTopBottom();
          // getAlignmentTopBottom returns (bottom, top) in this port
          // (mirrors GetAlignmentTopBottom's min/max pair).
          final int alignBottom = currentMin;
          final int alignTop = currentMax;
          final Arpeg arpegObj = tuple.arpeg as Arpeg;
          final (Note? topNote, Note? bottomNote) =
              arpegObj.getDrawingTopBottomNotes();
          if (topNote != null && bottomNote != null) {
            final int arpegMax =
                topNote.getDrawingY() + drawingUnit ~/ 2;
            final int arpegMin =
                bottomNote.getDrawingY() - drawingUnit ~/ 2;
            if (((alignBottom < arpegMin) && (alignTop > arpegMin)) ||
                ((alignTop > arpegMax) && (alignBottom < arpegMax))) {
              tuple.alignment.setXRel(
                  tuple.alignment.getXRel() + overlap + drawingUnit ~/ 2);
            }
          }
        }
      }

      // We can remove it from the list
      alignmentArpegTuples.removeAt(i);
      --i;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitArpeg(Object arpeg) {
    if (arpeg is! Arpeg) return FunctorCode.continue_;
    // Mirrors `Arpeg::GetDrawingTopBottomNotes` (arpeg.cpp:144): sorted by
    // drawing Y, start + plist refs with chords expanded — not the plist
    // order. Using the member (as the C++ `VisitArpeg` does) matters for
    // chords and single-note refs.
    final (Note? topNote, Note? bottomNote) =
        arpeg.getDrawingTopBottomNotes();

    // Nothing to do without a top and a bottom note
    if (topNote == null || bottomNote == null) return FunctorCode.continue_;

    // We should have processed DrawArpeg before
    assert(arpeg.getCurrentFloatingPositioner() != null);

    final Staff topStaff = topNote.getAncestorStaffLayout();
    final Staff bottomStaff = bottomNote.getAncestorStaffLayout();

    final Staff? crossStaff = arpeg.getCrossStaff();
    final int staffN = crossStaff?.n ?? topStaff.n ?? 0;

    final Alignment? topAlignment = topNote.getAlignment();
    if (topAlignment == null) return FunctorCode.continue_;

    var (int minTopLeft, _) = topAlignment.getLeftRight(staffN);

    alignmentArpegTuples
        .add(AlignmentArpegTuple(topAlignment, arpeg, topStaff.n ?? 0));

    if (topStaff.n != bottomStaff.n) {
      final (int bottomMinLeft, _) = topAlignment.getLeftRight(bottomStaff.n ?? 0);
      minTopLeft = math.min(minTopLeft, bottomMinLeft);

      alignmentArpegTuples
          .add(AlignmentArpegTuple(topAlignment, arpeg, bottomStaff.n ?? 0));
    }

    if (minTopLeft != -meiUnset) {
      int dist = topNote.getDrawingX() - minTopLeft;
      // HARDCODED
      double unitFactor = 1.0;
      // Mirrors adjustarpegfunctor.cpp:162: only brack/box enclosures widen.
      final Enclosure? enclose = arpeg.enclose;
      if (enclose == Enclosure.brack || enclose == Enclosure.box) {
        unitFactor += 0.75;
      }
      if (arpeg.arrow == true) unitFactor += 0.33;
      // Mirrors `dist += unitFactor * m_doc->GetDrawingUnit(...);`
      // (adjustarpegfunctor.cpp:164): `dist` (int) already holds
      // `topNote.getDrawingX() - minTopLeft` (non-zero), so the C++ `+=`
      // truncates the sum once. Same bug class fixed elsewhere in this
      // loop (slur, floating margin, gliss, beam, tuplet).
      dist = (dist +
              unitFactor * doc.getDrawingUnit(topStaff.drawingStaffSize))
          .toInt();

      // Mirrors `arpeg->SetDrawingXRel(-dist)` (adjustarpegfunctor.cpp:165):
      // stores on the Arpeg AND the positioner (arpeg.cpp:86). Writing only
      // the positioner is lost — `View::DrawArpeg` copies the stored value
      // back over the positioner on every draw (view_control.cpp:1546).
      arpeg.setDrawingXRel(-dist);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    // Mirrors adjustarpegfunctor.cpp:171-183: every measure-end with pending
    // tuples processes its own aligner backwards. No null guard — the C++
    // overwrites `m_measureAligner` per measure; guarding on null processes
    // only the first measure and leaves multi-measure files (all of arpeg/
    // except 002/006) with unadjusted overlaps.
    if (alignmentArpegTuples.isNotEmpty) {
      measureAlignerRef = measure.measureAligner;
      // Process backwards on the measure aligner, then reset to the previous
      // direction.
      final bool previousDirection = setDirection(false);
      measure.measureAligner.process(this);
      setDirection(previousDirection);
      alignmentArpegTuples.clear();
    }

    return FunctorCode.continue_;
  }
}

/// Mirrors `Arpeg::GetDrawingTopBottomNotes` (arpeg.cpp:144) via the member:
/// kept as a free function for callers holding a dynamic Arpeg.
(Note?, Note?) getDrawingTopBottomNotes(dynamic arpeg) {
  if (arpeg is Arpeg) return arpeg.getDrawingTopBottomNotes();
  Note? topNote;
  Note? bottomNote;

  final List<Object> refs = (arpeg.getRefs() as List<Object>? ?? const []);
  for (final Object object in refs) {
    if (object is! Note) continue;
    bottomNote ??= object;
    topNote = object;
  }

  return (topNote, bottomNote);
}
