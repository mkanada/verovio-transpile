/// Port of `adjustxoverflowfunctor.h/cpp` — prevents `<dir>`/`<dynam>`/etc.
/// content of the last measure of a system from overflowing past the right
/// barline, by adjusting the barline's alignment.
///
/// Deviations from the C++:
/// - [ControlElement.getChildRendAlignment] (`ControlElement::GetChildRendAlignment`,
///   controlelement.cpp:75) is ported alongside this functor, as its only
///   caller — it belongs on the model class, not here, but nothing else in
///   the port needed it yet.
/// - Verified against `cpp_probe` task `04f` (`dir/dir-001.mei`,
///   `dynam/dynam-001.mei`, `section/section-001.mei`): every early-return
///   branch (`VisitControlElement`'s widest-positioner bookkeeping,
///   `VisitSystemEnd`'s `noop_nocandidate`/`noop_nooverflow` guards) matches
///   at epsilon 0, but no file in the fixed corpus ever reaches the
///   overflow-applied branch under this project's plain rendering invocation
///   (`-x 12345 -o out.svg`, no forced narrow page/breaks) — see
///   `prompts/reports/04f.md`. That branch is instead verified on a
///   synthetic tree in `test/adjust_x_overflow_test.dart`.
library;

import 'package:verovio_dart/src/core/logging.dart' show logDebug;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;
import 'package:verovio_dart/src/model/basic_elements.dart' show Measure;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Horizontalalignment;
import 'package:verovio_dart/src/model/control_element.dart' show ControlElement;
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

/// The control-element classes `AdjustXOverflowFunctor::VisitControlElement`
/// considers (`adjustxoverflowfunctor.cpp:35`).
const Set<ClassId> _xOverflowControlElements = {
  ClassId.cpMark,
  ClassId.dir,
  ClassId.dynam,
  ClassId.ornam,
  ClassId.repeatMark,
  ClassId.tempo,
};

/// This class adjusts the X position of right barlines in order to make sure
/// there is no text content overflowing (mirrors `vrv::AdjustXOverflowFunctor`).
class AdjustXOverflowFunctor extends Functor {
  AdjustXOverflowFunctor(this.margin);

  /// The current system (mirrors `m_currentSystem`).
  System? currentSystem;

  /// The last measure (mirrors `m_lastMeasure`).
  Measure? lastMeasure;

  /// The current widest control event (mirrors `m_currentWidest`).
  FloatingPositioner? currentWidest;

  /// The margin (mirrors `m_margin`).
  final int margin;

  @override
  bool get implementsEndInterface => true;

  @override
  FunctorCode visitControlElement(ControlElement controlElement) {
    if (!_xOverflowControlElements.contains(controlElement.classId)) {
      return FunctorCode.siblings;
    }

    // Right aligned cannot overflow.
    if (controlElement.getChildRendAlignment() == Horizontalalignment.right) {
      return FunctorCode.siblings;
    }

    assert(currentSystem != null);

    // Get all the positioners for this object - all of them (all staves)
    // because we can have different staff sizes.
    final List<FloatingPositioner> positioners = [];
    currentSystem!.systemAligner
        .findAllPositionerPointingTo(positioners, controlElement);

    // Something is probably not right if nothing found - maybe no @staff.
    if (positioners.isEmpty) {
      logDebug('Something was wrong when searching positioners for '
          '${controlElement.className} \'${controlElement.id}\'');
      return FunctorCode.siblings;
    }

    // Keep the one with the highest right position.
    for (final FloatingPositioner positioner in positioners) {
      if (currentWidest == null ||
          currentWidest!.getContentRight() < positioner.getContentRight()) {
        currentWidest = positioner;
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    lastMeasure = measure;
    // For now look only at the content of the last measure, so discard any
    // previous control event. We need to do this because AdjustXOverflow is
    // run before measures are aligned, so the right position comparison do
    // not actually tell us which one is the longest. This is not optimal and
    // can be improved.
    currentWidest = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    currentSystem = system;
    lastMeasure = null;
    currentWidest = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemEnd(System system) {
    // Continue if no measure or no widest element.
    if (lastMeasure == null || currentWidest == null) {
      return FunctorCode.continue_;
    }

    // Continue if the right position of the measure is larger than the
    // widest element right.
    final int measureRightX =
        lastMeasure!.getDrawingX() + lastMeasure!.getRightBarLineLeft() - margin;
    if (measureRightX > currentWidest!.getContentRight()) {
      return FunctorCode.continue_;
    }

    final Object? widestObjectX = currentWidest!.getObjectX();
    final LayerElement? objectX =
        widestObjectX is LayerElement ? widestObjectX : null;
    if (objectX == null) {
      return FunctorCode.continue_;
    }
    Alignment? left = objectX.getAlignment();
    final Measure? objectXMeasure =
        objectX.getFirstAncestor(ClassId.measure) as Measure?;
    if (!identical(objectXMeasure, lastMeasure)) {
      left = lastMeasure!.getLeftBarLine().getAlignment();
    }

    final int overflow = currentWidest!.getContentRight() - measureRightX;
    if (overflow > 0 && left != null) {
      final Alignment? right = lastMeasure!.getRightBarLine().getAlignment();
      if (right != null) {
        lastMeasure!.measureAligner
            .adjustProportionally([(left, right, overflow)]);
      }
    }

    return FunctorCode.continue_;
  }
}
