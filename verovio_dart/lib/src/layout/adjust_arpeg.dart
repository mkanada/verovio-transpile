/// Port of `adjustarpegfunctor.h/cpp` — AdjustArpegFunctor, plus the
/// `Arpeg::GetDrawingTopBottomNotes` helper of arpeg.cpp.
///
/// The functor adjusts the x position of the arpeggios by looking at the
/// content of the preceding alignments.
///
/// Deviations from the C++:
/// - The grace aligner branch (ALIGNMENT_GRACENOTE) is reduced: grace group
///   right positions require the grace alignment widths of the horizontal
///   layout; the check is skipped until then.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart';
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Measure, Note, Staff;
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
      // measure
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
            final int rightBarLineXRel =
                previous.measureAligner.getRightBarLineXRel();
            maxRight = rightBarLineXRel + _rightBarLineWidth(previous);
            minLeft = rightBarLineXRel - _leftBarLineWidth(previous);
          }
        }
      }

      // Deviation: the ALIGNMENT_GRACENOTE case is not ported yet (see the
      // library header).

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
        // elements from the previous alignment.
        // Deviation: the clef alignment vertical check of the C++ requires
        // the rendered note positions; the xRel shift is applied directly.
        tuple.alignment.setXRel(tuple.alignment.getXRel() + overlap + drawingUnit ~/ 2);
      }

      // We can remove it from the list
      alignmentArpegTuples.removeAt(i);
      --i;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitArpeg(Object arpeg) {
    final dynamic arpegDyn = arpeg;
    final (Note? topNote, Note? bottomNote) = getDrawingTopBottomNotes(arpegDyn);

    // Nothing to do without a top and a bottom note
    if (topNote == null || bottomNote == null) return FunctorCode.continue_;

    // We should have processed DrawArpeg before
    assert(arpegDyn.getCurrentFloatingPositioner() != null);

    final Staff topStaff = topNote.getAncestorStaffLayout();
    final Staff bottomStaff = bottomNote.getAncestorStaffLayout();

    final Staff? crossStaff = arpegDyn.getCrossStaff() as Staff?;
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
      final dynamic enclose = arpegDyn.enclose;
      if (enclose != null) unitFactor += 0.75;
      if (arpegDyn.arrow == true) unitFactor += 0.33;
      dist += (unitFactor * doc.getDrawingUnit(topStaff.drawingStaffSize)).toInt();

      final FloatingPositioner? positioner =
          arpegDyn.getCurrentFloatingPositioner() as FloatingPositioner?;
      positioner?.setDrawingXRel(-dist);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    if (measureAlignerRef == null && alignmentArpegTuples.isNotEmpty) {
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

  /// Approximated barline half-widths for the previous measure barline
  /// overlap check. Deviation: the C++ reads the actual barline bounding
  /// boxes; a single unit wide box is used instead.
  int _rightBarLineWidth(Measure measure) =>
      doc.getDrawingUnit(100);

  int _leftBarLineWidth(Measure measure) =>
      doc.getDrawingUnit(100);
}

/// Mirrors `Arpeg::GetDrawingTopBottomNotes` reduced to the plist references:
/// the notes sorted by their pitch (the list order defines top and bottom).
(Note?, Note?) getDrawingTopBottomNotes(dynamic arpeg) {
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
