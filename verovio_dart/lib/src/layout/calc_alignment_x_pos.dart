/// Port of `calcalignmentxposfunctor.h/cpp` — sets the x position of each
/// Alignment of the measure aligners, with a non-linear spacing based on the
/// time interval between alignments (mirrors `vrv::CalcAlignmentXPosFunctor`).
///
/// The grace aligner positions are set through
/// [GraceAligner.setGraceAlignmentXPos] (horizontal_aligner.dart).
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, MeasureAligner;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

/// Mirrors `DEFINITION_FACTOR` (vrvdef.h).
const int definitionFactor = 10;

/// This class calculates the position of the Alignment.
///
/// Looks at the time difference from the previous Alignment (mirrors
/// `vrv::CalcAlignmentXPosFunctor`).
class CalcAlignmentXPosFunctor extends DocFunctor {
  CalcAlignmentXPosFunctor(super.doc);

  /// The previous time position (mirrors `m_previousTime`).
  Fraction previousTime = Fraction(0);

  /// The previous x rel position (mirrors `m_previousXRel`).
  int previousXRel = 0;

  /// Duration of the longest note (mirrors `m_longestActualDur`).
  MeiDuration longestActualDur = MeiDuration.none;

  /// The estimated justification ratio of the system (mirrors
  /// `m_estimatedJustificationRatio`). The ratio stays at 1.0 until the
  /// cast-off system widths are stored (Phase 6).
  double estimatedJustificationRatio = 1.0;

  /// The last alignment that was not timestamp-only (mirrors
  /// `m_lastNonTimestamp`).
  Alignment? lastNonTimestamp;

  /// The list of timestamp-only alignments that need to be adjusted (mirrors
  /// `m_timestamps`).
  final List<Alignment> timestamps = [];

  /// The MeasureAligner currently processed (mirrors `m_measureAligner`).
  Object? measureAligner;

  /// Mirrors `GetLongestActualDur` / `SetLongestActualDur`.
  MeiDuration getLongestActualDur() => longestActualDur;
  void setLongestActualDur(MeiDuration dur) => longestActualDur = dur;

  @override
  FunctorCode visitAlignment(Alignment alignment) {
    // Do not set an x pos for anything before the barline (including it)
    if (alignment.getType().value <= AlignmentType.measureLeftBarline.value) {
      return FunctorCode.continue_;
    }

    int intervalXRel = 0;
    Fraction intervalTime = alignment.getTime() - previousTime;

    if (alignment.getType().value > AlignmentType.measureRightBarline.value) {
      intervalTime = Fraction(0);
    }

    // Do not move aligners that are only time-stamps at this stage but add it
    // to the pending list
    if (alignment.hasTimestampOnly()) {
      timestamps.add(alignment);
      return FunctorCode.continue_;
    }

    if (intervalTime > Fraction(0)) {
      intervalXRel = Alignment.horizontalSpaceForDuration(
          intervalTime,
          longestActualDur,
          doc.getOptions().spacingLinear.value,
          doc.getOptions().spacingNonLinear.value);
    }

    alignment.getGraceAligners().forEach((_, graceAligner) {
      graceAligner.setGraceAlignmentXPos(doc);
    });

    alignment.setXRel(previousXRel +
        (intervalXRel * definitionFactor * estimatedJustificationRatio)
            .toInt());
    previousTime = alignment.getTime();
    previousXRel = alignment.getXRel();

    // This is an alignment which is not timestamp only. If we have a list of
    // pending timestamp alignments, then we now need to move them
    // appropriately
    if (timestamps.isNotEmpty && lastNonTimestamp != null) {
      final int startXRel = lastNonTimestamp!.getXRel();
      Fraction startTime = lastNonTimestamp!.getTime();
      final Fraction endTime = alignment.getTime();

      // We have timestamp alignments between the left barline and the first
      // beat. We need to use the MeasureAligner::m_initialTstampDur to
      // calculate the time (percentage) position
      if (lastNonTimestamp!.getType() == AlignmentType.measureLeftBarline &&
          measureAligner is MeasureAligner) {
        final MeasureAligner aligner = measureAligner as MeasureAligner;
        startTime = aligner.getInitialTstampDur();
      }

      // The duration since the last alignment and the current one
      final Fraction duration = endTime - startTime;
      final int space = alignment.getXRel() - lastNonTimestamp!.getXRel();

      // For each timestamp alignment, move them proportionally to the space
      // we currently have
      for (final Alignment tsAlignment in timestamps) {
        // Avoid division by zero (nothing to move with the alignment anyway
        if (duration == Fraction(0)) break;
        final double percent =
            ((tsAlignment.getTime() - startTime) / duration).toDouble();
        tsAlignment.setXRel(startXRel + (space * percent).toInt());
      }
      timestamps.clear();
    }

    // Do not use clef change and gracenote alignment as reference since these
    // are not aligned at this stage
    if (!alignment.isOfType([AlignmentType.clef, AlignmentType.graceNote])) {
      lastNonTimestamp = alignment;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    // We start a new Measure. Reset the previous time position and x_rel to
    // 0; in un-measured music we never have a left barline, so do not add a
    // default space.
    previousTime = Fraction(0);
    previousXRel = measure.isMeasuredMusic() ? doc.getDrawingUnit(100) : 0;

    measure.measureAligner.process(this);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasureAligner(MeasureAligner measureAligner) {
    lastNonTimestamp = measureAligner.getLeftBarLineAlignment();
    this.measureAligner = measureAligner;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    // Mirrors `CalcAlignmentXPosFunctor::VisitSystem`
    // (calcalignmentxposfunctor.cpp:118-125).
    final double ratio = system.estimateJustificationRatio(doc);
    if ((!system.isLastOfMdiv() && !system.isLastOfSelection()) ||
        ratio < estimatedJustificationRatio) {
      estimatedJustificationRatio = ratio;
    }
    return FunctorCode.continue_;
  }
}
