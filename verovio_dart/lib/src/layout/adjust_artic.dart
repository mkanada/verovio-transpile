/// Port of `adjustarticfunctor.h/cpp` — vertical positioning of
/// articulations outside the staff.
///
/// Deviations from the C++:
/// - Both functors need the rendered self bounding boxes of notes / stems /
///   articulations. In this port those are only filled by [View+BBoxDeviceContext]
///   during the vertical layout phase, not during `Page::layOutHorizontally`
///   as in the C++. [AdjustArticFunctor] is therefore wired into
///   `Doc.layOutVertically`, right after the headless extents pass — the
///   same documented deviation already used for `AdjustArpegFunctor` (see
///   `doc.dart`).
/// - `Flag::GetStemUpSE` / `GetStemDownNW` need `Doc::GetResources()`, not
///   wired to [Doc] in this phase (see [Flag.getStemUpSE]'s doc); they
///   return a zero offset, which only matters for notes with a drawn flag
///   (eighth-or-shorter, unbeamed) — not exercised by this task's corpus.
/// - [AdjustArticWithSlursFunctor] depends on `Artic.startSlurPositioners` /
///   `endSlurPositioners`, populated in the C++ by
///   `Slur::AddPositionerToArticulations` (`slur.cpp`) — out of scope here
///   (see `adjust_accid_x.dart`'s sibling note and the field's own doc in
///   `layer_elements_gen.dart`); the lists stay empty, so this functor
///   always no-ops on the current corpus, which has no slurs either.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show CurveIntersection;
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers, StaffLayoutHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Artic, Beam, Chord, Flag, Stem;

// ---------------------------------------------------------------------------
// AdjustArticFunctor
// ---------------------------------------------------------------------------

/// Adjusts the position of articulations outside the staff (mirrors
/// `vrv::AdjustArticFunctor`).
class AdjustArticFunctor extends DocFunctor {
  AdjustArticFunctor(super.doc);

  @override
  bool get implementsEndInterface => false;

  /// The list of above / below articulations (mirrors `m_articAbove` /
  /// `m_articBelow`).
  final List<Artic> articAbove = [];
  final List<Artic> articBelow = [];

  /// The parent element the articulations refer to (mirrors `m_parent`).
  LayerElement? parent;

  @override
  FunctorCode visitArtic(Artic artic) {
    final LayerElement? parent = this.parent;
    if (parent == null) return FunctorCode.continue_;

    final Staff staff = artic.getAncestorStaffResolveCrossStaff()!;
    final Beam? beam = artic.getAncestorBeam();
    final int staffHeight = doc.getDrawingDoubleUnit(staff.drawingStaffSize) *
        (staff.drawingLines - 1);

    final Stem? stem = parent.findDescendantByType(ClassId.stem) as Stem?;
    final Flag? flag = parent.findDescendantByType(ClassId.flag) as Flag?;

    int yIn;
    int yOut;
    // Avoid the artic being in the ledger lines.
    if (artic.drawingPlace == Staffrel.above) {
      int yAboveStem =
          parent.getDrawingTop(doc, staff.drawingStaffSize, withArtic: false) -
              staff.getDrawingY();
      if (flag != null &&
          stem != null &&
          stem.getDrawingStemDir() == Stemdirection.up) {
        yAboveStem += flag.getStemUpSE(doc, staff.drawingStaffSize, false).y;
      }
      yIn = math.max(yAboveStem, -staffHeight);
      yOut = math.max(yIn, 0);
    } else {
      final bool isStemDown =
          stem != null && stem.getDrawingStemDir() == Stemdirection.down;
      int yBelowStem = parent.getDrawingBottom(doc, staff.drawingStaffSize,
              withArtic: false) -
          staff.getDrawingY();
      if (flag != null && isStemDown) {
        yBelowStem += flag.getStemDownNW(doc, staff.drawingStaffSize, false).y;
      }
      yIn = math.min(yBelowStem, 0);
      if (beam != null &&
          beam.crossStaffContent != null &&
          beam.drawingPlace == Beamplace.mixed &&
          isStemDown) {
        yIn -= beam.beamWidthBlack;
      }
      yOut = math.min(yIn, -staffHeight);
    }

    final int yRel = artic.isInsideArtic() ? yIn : yOut;
    artic.setDrawingYRel(yRel);

    // Adjust according to the position of a previous artic.
    if (artic.drawingPlace == Staffrel.above && articAbove.isNotEmpty) {
      final Artic previous = articAbove.last;
      final int inTop = previous.getContentTop();
      final int outBottom = artic.getContentBottom();
      if (inTop > outBottom) {
        artic.setDrawingYRel(artic.drawingYRel + inTop - outBottom);
      }
    }
    if (artic.drawingPlace == Staffrel.below && articBelow.isNotEmpty) {
      final Artic previous = articBelow.last;
      final int inBottom = previous.getContentBottom();
      final int outTop = artic.getContentTop();
      if (inBottom < outTop) {
        artic.setDrawingYRel(artic.drawingYRel - outTop + inBottom);
      }
    }

    // Add spacing.
    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    final int spacingTop = (doc.getTopMargin(ClassId.artic) * unit).toInt();
    final int spacingBottom =
        (doc.getBottomMargin(ClassId.artic) * unit).toInt();
    final int direction = artic.drawingPlace == Staffrel.above ? 1 : -1;
    final int y = artic.getDrawingY();
    int yShift = 0;

    if (artic.isInsideArtic()) {
      // If we are above the top of the staff, just pile them up.
      if (artic.drawingPlace == Staffrel.above && y > staff.getDrawingY()) {
        yShift += spacingBottom;
      }
      // If we are below the bottom, just pile them down.
      else if (artic.drawingPlace == Staffrel.below &&
          y < staff.getDrawingY() - staffHeight) {
        if (y > staff.getDrawingY() - staffHeight - unit) {
          yShift = (staff.getDrawingY() - staffHeight - unit) - y;
          if (yShift.abs() < spacingTop) yShift = -spacingTop;
        } else {
          yShift -= spacingTop;
        }
      }
      // Otherwise make it fit in the staff space.
      else {
        yShift =
            staff.getNearestInterStaffPosition(y, doc, artic.drawingPlace) - y;
        if (staff.isOnStaffLine(y + yShift, doc)) yShift += unit * direction;
      }
    }
    // Artic parts outside just need to be piled up or down.
    else {
      final int spacing = direction > 0 ? spacingBottom : spacingTop;
      yShift += spacing * direction;
    }
    artic.setDrawingYRel(artic.drawingYRel + yShift);

    // Add it to the list of previous artics.
    if (artic.drawingPlace == Staffrel.above) {
      articAbove.add(artic);
    } else {
      articBelow.add(artic);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitChord(Chord chord) {
    parent = chord;
    articAbove.clear();
    articBelow.clear();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    if (note.isChordTone() != null) return FunctorCode.continue_;

    parent = note;
    articAbove.clear();
    articBelow.clear();

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// AdjustArticWithSlursFunctor
// ---------------------------------------------------------------------------

/// Adjusts the position of outside articulations to avoid slurs (mirrors
/// `vrv::AdjustArticWithSlursFunctor`).
class AdjustArticWithSlursFunctor extends DocFunctor {
  AdjustArticWithSlursFunctor(super.doc);

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitArtic(Artic artic) {
    if (artic.startSlurPositioners.isEmpty &&
        artic.endSlurPositioners.isEmpty) {
      return FunctorCode.continue_;
    }

    final int margin = doc.getDrawingUnit(100);
    for (final curve in artic.endSlurPositioners) {
      final int shift = artic.intersectsCurve(curve, Accessor.content, margin);
      if (shift != 0) artic.setDrawingYRel(artic.drawingYRel + shift);
    }

    for (final curve in artic.startSlurPositioners) {
      final int shift = artic.intersectsCurve(curve, Accessor.content, margin);
      if (shift != 0) artic.setDrawingYRel(artic.drawingYRel + shift);
    }

    return FunctorCode.siblings;
  }
}
