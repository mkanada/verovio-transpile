/// Port of `AdjustBeamsFunctor` (origin/src/src/adjustbeamsfunctor.cpp, 434
/// lines): the vertical adjustment of the beams against the layer elements
/// that stay between them and the staff.
///
/// The functor computes, for every outer beam / fTrem, an `overlapMargin` and
/// writes it into each `BeamElementCoord::m_overlapMargin`
/// (`VisitBeamEnd`, adjustbeamsfunctor.cpp:114-118). The displacement itself
/// is applied when the stems are re-calculated
/// (`BeamElementCoord::SetDrawingStemDir`, beam.cpp:1912: `m_yBeam +=
/// m_overlapMargin`) during the render pass — see view_beam.cpp (task 05-17).
///
/// `BeamSegment::CalcBeam` (beam.cpp:89) and `BeamDrawingInterface::InitCoords`
/// (drawinginterface.cpp:140) are ported (`model/beam_segment.dart`,
/// `model/drawing_interfaces.dart`) and run during `Doc.prepareData()`
/// (`layout/calc_functors.dart`'s `CalcStemFunctor`), before this functor
/// runs during `Doc.layOut()`'s vertical layout — so `beamElementCoordRefs`
/// is populated by the time `VisitBeam`/`VisitFTrem` see it.
///
/// `Layer::GetLayerElementsForTimeSpanOf` (layer.cpp:417) and
/// `Doc::GetGlyphTop`/`GetGlyphBottom` (used by `VisitClef`) are likewise
/// ported and wired (`Layer.getLayerElementsForTimeSpanOf` in
/// `basic_elements.dart`; `Doc.getGlyphTop`/`getGlyphBottom` in `doc.dart`).
library;

import 'dart:math';

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/smufl.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/lay_out_vertically.dart'
    show calcPitchPosYRel;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Clef, Layer, Rest, Staff;
import 'package:verovio_dart/src/model/beam_segment.dart';
import 'package:verovio_dart/src/model/comparison.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/rendering/resources.dart';

/// This class calculates the vertical position adjustment for beams if they
/// overlap with layer elements (mirrors `vrv::AdjustBeamsFunctor`,
/// adjustbeamsfunctor.h:22).
class AdjustBeamsFunctor extends DocFunctor {
  AdjustBeamsFunctor(super.doc);

  /// The top-level beam that should be adjusted (mirrors `m_outerBeam`).
  Beam? outerBeam;

  /// The top-level ftrem that should be adjusted (mirrors `m_outerFTrem`).
  FTrem? outerFTrem;

  /// The y coordinates of the beam left and right side (mirrors
  /// `m_y1` / `m_y2`).
  int y1 = 0;
  int y2 = 0;

  /// The x coordinates of the beam left and right side (mirrors
  /// `m_x1` / `m_x2`).
  int x1 = 0;
  int x2 = 0;

  /// The slope of the beam (mirrors `m_beamSlope`).
  double beamSlope = 0.0;

  /// The direction bias (mirrors `m_directionBias`).
  int directionBias = 0;

  /// The overlap margin that the beam needs to be displaced by (mirrors
  /// `m_overlapMargin`).
  int overlapMargin = 0;

  /// Indicates whether an element from a different layer is processed
  /// (mirrors `m_isOtherLayer`).
  bool isOtherLayer = false;

  // ---------------------------------------------------------------------------
  // Functor interface
  // ---------------------------------------------------------------------------

  /// Mirrors `AdjustBeamsFunctor::VisitBeam` (adjustbeamsfunctor.cpp:41).
  @override
  FunctorCode visitBeam(Beam beam) {
    final BeamSegment beamSegment = beam.beamSegment;

    if (beam.isTabBeam() ||
        beam.hasSameas ||
        beam.childCount == 0 ||
        beamSegment.beamElementCoordRefs.isEmpty) {
      return FunctorCode.continue_;
    }

    // should never happen
    if (outerFTrem != null) return FunctorCode.continue_;

    // process highest-level beam
    if (outerBeam == null) {
      if (beam.drawingPlace == Beamplace.mixed) {
        // Mirrors `beamSegment.RequestStaffSpace(m_doc, beam)`.
        requestStaffSpace(doc, beam, beamSegment);
      } else {
        outerBeam = beam;
        y1 = beamSegment.beamElementCoordRefs.first.yBeam;
        y2 = beamSegment.beamElementCoordRefs.last.yBeam;
        x1 = beamSegment.beamElementCoordRefs.first.x;
        x2 = beamSegment.beamElementCoordRefs.last.x;
        beamSlope = beamSegment.beamSlope;
        directionBias = (beam.drawingPlace == Beamplace.above) ? 1 : -1;
        overlapMargin = calcLayerOverlap(beam);
      }
      return FunctorCode.continue_;
    }

    final BeamElementCoord first = beamSegment.beamElementCoordRefs.first;
    final BeamElementCoord last = beamSegment.beamElementCoordRefs.last;
    final int beamCount =
        outerBeam!.getBeamPartDuration(first.x) - MeiDuration.dur8.value;
    // The C++ assigns the double product to an int (implicit truncation);
    // `.truncate()` reproduces it (00-MESTRE §7).
    final int currentBeamYLeft = (y1 + beamSlope * (first.x - x1)).truncate();
    final int currentBeamYRight = (y1 + beamSlope * (last.x - x1)).truncate();
    final int leftMargin = first.yBeam -
        currentBeamYLeft +
        directionBias *
            (beamCount * outerBeam!.beamWidth + outerBeam!.beamWidthBlack);
    final int rightMargin = last.yBeam -
        currentBeamYRight +
        directionBias *
            (beamCount * outerBeam!.beamWidth + outerBeam!.beamWidthBlack);

    final int currentOverlap =
        max(leftMargin * directionBias, rightMargin * directionBias);
    if (currentOverlap >= overlapMargin) {
      final Staff staff = beam.getAncestorStaffLayout();
      final int staffOffset = doc.getDrawingUnit(staff.drawingStaffSize);
      overlapMargin = (currentOverlap + staffOffset) * directionBias;
    }
    return FunctorCode.siblings;
  }

  /// Mirrors `AdjustBeamsFunctor::VisitBeamEnd` (adjustbeamsfunctor.cpp:90).
  @override
  FunctorCode visitBeamEnd(Beam beam) {
    if (beam.isTabBeam()) return FunctorCode.continue_;

    if (outerBeam != beam) return FunctorCode.continue_;

    if (beam.drawingPlace == Beamplace.mixed) return FunctorCode.continue_;

    final Layer? parentLayer = beam.getFirstAncestor(ClassId.layer) as Layer?;
    if (parentLayer != null) {
      // find elements on the other layers for the duration of the current beam
      final List<model.Object> otherLayersElements =
          _layerElementsForTimeSpanOf(parentLayer, beam, true);
      if (otherLayersElements.isNotEmpty) {
        // call AdjustBeams separately for each element to find possible
        // overlaps
        isOtherLayer = true;
        for (final model.Object element in otherLayersElements) {
          if (!outerBeam!.horizontalContentOverlap(element)) continue;
          element.process(this, deepness: 0);
        }
        isOtherLayer = false;
      }
    }

    // set overlap margin for each coord in the beam
    if (overlapMargin != 0) {
      for (final BeamElementCoord coord
          in beam.beamSegment.beamElementCoordRefs) {
        coord.overlapMargin = overlapMargin;
      }
    }
    outerBeam = null;
    overlapMargin = 0;

    return FunctorCode.continue_;
  }

  /// Mirrors `AdjustBeamsFunctor::VisitClef` (adjustbeamsfunctor.cpp:125).
  @override
  FunctorCode visitClef(Clef clef) {
    if (outerBeam == null) return FunctorCode.siblings;
    // ignore elements that start before/after the beam
    if (clef.getDrawingX() < x1) return FunctorCode.continue_;
    if (clef.getDrawingX() > x2) return FunctorCode.continue_;

    final Staff staff = clef.getAncestorStaffLayout();
    // find number of beams at current position
    final int beams =
        outerBeam!.getBeamPartDurationOf(clef) - MeiDuration.dur4.value;
    final int beamWidth = outerBeam!.beamWidth;
    // find beam Y positions that are relevant to current clef
    final int currentBeamYLeft =
        (y1 + beamSlope * (clef.getContentLeft() - x1)).truncate();
    final int currentBeamYRight =
        (y1 + beamSlope * (clef.getContentRight() - x1)).truncate();
    // get clef code and find its bounds on the staff (anchor point and
    // top/bottom depending on the beam place)
    final int clefCode = _clefGlyph(clef, staff.drawingNotationtype ?? Notationtype.none);
    if (clefCode == 0) return FunctorCode.siblings;

    final int clefPosition = staff.getDrawingY() -
        doc.getDrawingDoubleUnit(staff.drawingStaffSize) *
            (staff.drawingLines - (clef.line ?? 0));
    final int clefGlyphBound = (directionBias > 0)
        ? doc.getGlyphTop(clefCode, staff.drawingStaffSize, false)
        : doc.getGlyphBottom(clefCode, staff.drawingStaffSize, false);
    final int clefBounds = clefPosition + clefGlyphBound;
    // calculate margins for the clef
    final int leftMargin =
        directionBias * (currentBeamYLeft - clefBounds) - beams * beamWidth;
    final int rightMargin =
        directionBias * (currentBeamYRight - clefBounds) - beams * beamWidth;
    int clefOverlapMargin = min(leftMargin, rightMargin);
    if (clefOverlapMargin >= 0) return FunctorCode.continue_;
    // calculate offset required for the beam
    clefOverlapMargin *= -directionBias;
    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    final int adjust = adjustOverlapToHalfUnit(clefOverlapMargin, unit);
    if (adjust.abs() > overlapMargin.abs()) overlapMargin = adjust;

    return FunctorCode.continue_;
  }

  /// Mirrors `AdjustBeamsFunctor::VisitFTrem` (adjustbeamsfunctor.cpp:162).
  @override
  FunctorCode visitFTrem(FTrem fTrem) {
    final BeamSegment beamSegment = fTrem.beamSegment;

    if (fTrem.hasSameas ||
        fTrem.childCount == 0 ||
        beamSegment.beamElementCoordRefs.isEmpty) {
      return FunctorCode.continue_;
    }

    if (outerBeam == null && outerFTrem == null) {
      if (fTrem.drawingPlace == Beamplace.mixed) {
        // Mirrors `beamSegment.RequestStaffSpace(m_doc, fTrem)`.
        requestStaffSpace(doc, fTrem, beamSegment);
      } else {
        outerFTrem = fTrem;
        y1 = beamSegment.beamElementCoordRefs.first.yBeam;
        y2 = beamSegment.beamElementCoordRefs.last.yBeam;
        x1 = beamSegment.beamElementCoordRefs.first.x;
        x2 = beamSegment.beamElementCoordRefs.last.x;
        beamSlope = beamSegment.beamSlope;
        directionBias = (fTrem.drawingPlace == Beamplace.above) ? 1 : -1;
        overlapMargin = calcLayerOverlap(fTrem);
      }
      return FunctorCode.continue_;
    }

    final int leftMargin = beamSegment.beamElementCoordRefs.first.yBeam - y1;
    final int rightMargin = beamSegment.beamElementCoordRefs.last.yBeam - y2;

    final int currentOverlap =
        max(leftMargin * directionBias, rightMargin * directionBias);
    if (currentOverlap >= overlapMargin) {
      final Staff staff = fTrem.getAncestorStaffLayout();
      final int staffOffset = doc.getDrawingUnit(staff.drawingStaffSize);
      overlapMargin = (currentOverlap + staffOffset) * directionBias;
    }
    return FunctorCode.siblings;
  }

  /// Mirrors `AdjustBeamsFunctor::VisitFTremEnd` (adjustbeamsfunctor.cpp:199).
  @override
  FunctorCode visitFTremEnd(FTrem fTrem) {
    if (outerFTrem != fTrem) return FunctorCode.continue_;

    if (fTrem.drawingPlace == Beamplace.mixed) return FunctorCode.continue_;

    final Layer? parentLayer = fTrem.getFirstAncestor(ClassId.layer) as Layer?;
    if (parentLayer != null) {
      // find elements on the other layers for the duration of the current beam
      final List<model.Object> otherLayersElements =
          _layerElementsForTimeSpanOf(parentLayer, fTrem, true);
      if (otherLayersElements.isNotEmpty) {
        // call AdjustBeams separately for each element to find possible
        // overlaps
        isOtherLayer = true;
        for (final model.Object element in otherLayersElements) {
          if (!outerFTrem!.horizontalContentOverlap(element)) continue;
          element.process(this, deepness: 0);
        }
        isOtherLayer = false;
      }
    }

    // set overlap margin for each coord in the beam
    if (overlapMargin != 0) {
      for (final BeamElementCoord coord
          in fTrem.beamSegment.beamElementCoordRefs) {
        coord.overlapMargin = overlapMargin;
      }
    }
    outerFTrem = null;
    overlapMargin = 0;

    return FunctorCode.continue_;
  }

  /// Mirrors `AdjustBeamsFunctor::VisitLayerElement`
  /// (adjustbeamsfunctor.cpp:232).
  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    // ignore elements that are not in the outer beam/ftrem or are direct
    // children
    final BeamDrawingInterface? outerBeamInterface = getOuterBeamInterface();
    if (outerBeamInterface == null) return FunctorCode.continue_;
    if (!isOtherLayer &&
        layerElement.classId != ClassId.accid &&
        !layerElement.isGraceNote() &&
        ((layerElement.getFirstAncestor(ClassId.beam) == outerBeam) ||
            (layerElement.getFirstAncestor(ClassId.fTrem) == outerFTrem))) {
      return FunctorCode.continue_;
    }
    // ignore elements that are both on other layer and cross-staff
    if (isOtherLayer && layerElement.crossStaff != null) {
      return FunctorCode.continue_;
    }
    // ignore specific elements, since they should not be influencing beam
    // positioning
    if (layerElement.classId == ClassId.bTrem ||
        layerElement.classId == ClassId.graceGrp ||
        layerElement.classId == ClassId.space ||
        layerElement.classId == ClassId.tuplet ||
        layerElement.classId == ClassId.tupletBracket ||
        layerElement.classId == ClassId.tupletNum) {
      return FunctorCode.continue_;
    }
    // ignore elements that start before the beam
    if (layerElement.getDrawingX() < x1) return FunctorCode.continue_;
    // ignore elements that have @visible attribute set to false
    final AttVisibilityComparison isInvisible =
        AttVisibilityComparison(layerElement.classId, false);
    if (isInvisible(layerElement)) return FunctorCode.siblings;
    // ignore accidentals outside the staff
    if (layerElement.classId == ClassId.accid) {
      final Accid accid = layerElement as Accid;
      if (accid.func == AccidlogFunc.edit) return FunctorCode.continue_;
      if (accid.hasPlace) return FunctorCode.continue_;
    }
    final StemmedDrawingInterface? stemInterface =
        layerElement.getStemmedDrawingInterface();
    if (stemInterface != null) {
      final Stemdirection stemDir = stemInterface.getDrawingStemDir();
      if ((directionBias == 1 && stemDir == Stemdirection.up) ||
          (directionBias == -1 && stemDir == Stemdirection.down)) {
        return FunctorCode.continue_;
      }
    }

    final Staff staff = layerElement.getAncestorStaffLayout();

    // check if top/bottom of the element overlaps with beam coordinates
    int leftMargin = 0, rightMargin = 0;
    // C++ dispatches `GetAdditionalBeamCount` on the beam interface: both
    // `Beam` (beam.cpp:2052) and `FTrem` (ftrem.cpp:100) override the
    // `{0, 0}` default of `BeamDrawingInterface` (drawinginterface.h:161).
    final (int above, int below) = outerBeamInterface.getAdditionalBeamCount();
    int beamCount = max(above, below);
    if (outerFTrem != null) --beamCount;
    final int currentBeamYLeft =
        (y1 + beamSlope * (layerElement.getContentLeft() - x1)).truncate();
    final int currentBeamYRight =
        (y1 + beamSlope * (layerElement.getContentRight() - x1)).truncate();
    if (directionBias > 0) {
      leftMargin = layerElement.getContentTop() -
          currentBeamYLeft +
          beamCount * outerBeamInterface.beamWidth +
          outerBeamInterface.beamWidthBlack;
      rightMargin = layerElement.getContentTop() -
          currentBeamYRight +
          beamCount * outerBeamInterface.beamWidth +
          outerBeamInterface.beamWidthBlack;
    } else {
      leftMargin = layerElement.getContentBottom() -
          currentBeamYLeft -
          beamCount * outerBeamInterface.beamWidth -
          outerBeamInterface.beamWidthBlack;
      rightMargin = layerElement.getContentBottom() -
          currentBeamYRight -
          beamCount * outerBeamInterface.beamWidth -
          outerBeamInterface.beamWidthBlack;
    }

    final int currentOverlap =
        max(leftMargin * directionBias, rightMargin * directionBias);
    if (currentOverlap >= directionBias * overlapMargin) {
      final int staffOffset = doc.getDrawingUnit(staff.drawingStaffSize);
      // The C++ mixes integer and double arithmetic —
      // `(overlapMargin + staffOffset - 1) / staffOffset` is integer division,
      // `+ 0.5` promotes to double and the multiplication back truncates on
      // the int assignment. Preserved verbatim (00-MESTRE §7).
      overlapMargin =
          (((currentOverlap + staffOffset - 1) ~/ staffOffset + 0.5) *
                  staffOffset)
              .truncate() *
              directionBias;
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `AdjustBeamsFunctor::VisitRest` (adjustbeamsfunctor.cpp:295).
  @override
  FunctorCode visitRest(Rest rest) {
    if (outerBeam == null) return FunctorCode.siblings;

    // Calculate possible overlap for the rest with beams
    final int beams =
        outerBeam!.getBeamPartDurationOf(rest, false) - MeiDuration.dur4.value;
    final int beamWidth = outerBeam!.beamWidth;
    int currentOverlap = beamIntersects(
            rest, outerBeam!, Accessor.self, beams * beamWidth, true) *
        directionBias;

    // Adjust drawing location for the rest based on the overlap with beams.
    // Adjustment should be an even number, so that the rest is positioned
    // properly
    if (currentOverlap >= 0) return FunctorCode.continue_;

    final Staff staff = rest.getAncestorStaffLayout();

    if ((!rest.hasOloc || !rest.hasPloc) && !rest.hasLoc) {
      // constants
      final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
      // calculate new and old locations for the rest
      final int locAdjust =
          directionBias * (currentOverlap - 2 * unit + 1) ~/ unit;
      final int oldLoc = rest.drawingLoc;
      final int newLoc = oldLoc + locAdjust - locAdjust % 2;
      if (staff.getChildCount(ClassId.layer) == 1) {
        rest.drawingLoc = newLoc;
        rest.setDrawingYRel(calcPitchPosYRel(staff, doc, newLoc));
        // If there are dots, adjust their location as well
        if ((rest.dots ?? 0) > 0) {
          final Dots? dots =
              rest.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;
          if (dots != null) {
            final Set<int> dotLocs = dots.modifyDotLocsForStaff(staff);
            final int dotLoc = (oldLoc % 2 != 0) ? oldLoc : oldLoc + 1;
            if (dotLocs.contains(dotLoc)) {
              dotLocs.remove(dotLoc);
              dotLocs.add(newLoc);
            }
          }
        }
        return FunctorCode.continue_;
      }
    }

    currentOverlap *= -directionBias;
    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    final int adjust = adjustOverlapToHalfUnit(currentOverlap, unit);
    if (adjust.abs() > overlapMargin.abs()) overlapMargin = adjust;

    return FunctorCode.continue_;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Get the drawing interface of the outer beam or the outer ftrem (mirrors
  /// `AdjustBeamsFunctor::GetOuterBeamInterface`,
  /// adjustbeamsfunctor.cpp:344).
  ///
  /// Deviation from the C++: the beam interface in Dart is the state carried
  /// by [Beam] / [FTrem] through the [BeamDrawingInterface] mixin; the lookup
  /// returns null when neither is set. Typed consumers read [outerBeam] /
  /// [outerFTrem] directly (Dart cannot upcast a mixin to its `this`).
  BeamDrawingInterface? getOuterBeamInterface() {
    if (outerBeam != null) return outerBeam;
    if (outerFTrem != null) return outerFTrem;
    return null;
  }

  /// Calculate the overlap with other layer elements that are placed within
  /// the duration of the element (mirrors
  /// `AdjustBeamsFunctor::CalcLayerOverlap`, adjustbeamsfunctor.cpp:351).
  int calcLayerOverlap(LayerElement beamElement) {
    // The C++ asserts `beamElement` — non-nullable here by construction.

    final Layer? parentLayer =
        beamElement.getFirstAncestor(ClassId.layer) as Layer?;
    if (parentLayer == null) return 0;
    // Check whether there are elements on the other layer in the duration of
    // the current beam
    final List<model.Object> collidingElementsList =
        _layerElementsForTimeSpanOf(parentLayer, beamElement, true);
    // Ignore any elements part of a stem-sameas beam
    if (beamElement.classId == ClassId.beam) {
      final Beam beam = beamElement as Beam;
      final Beam? stemSameAsBeam =
          beam.stemSameasBeam != null ? beam.stemSameasBeam as Beam : null;
      if (stemSameAsBeam != null) {
        collidingElementsList.removeWhere((model.Object object) {
          final LayerElement layerElement = object as LayerElement;
          return layerElement.getFirstAncestor(ClassId.beam) == stemSameAsBeam;
        });
      }
    }
    // If there are none - stop here, there's nothing to be done
    if (collidingElementsList.isEmpty) return 0;

    final Staff staff = beamElement.getAncestorStaffLayout();
    final int drawingY = beamElement.getDrawingY();
    final int yMin = min(y1, y2);
    final int yMax = max(y1, y2);
    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);

    int elementOverlap = 0;
    final List<int> elementOverlaps = <int>[];
    for (final model.Object object in collidingElementsList) {
      final LayerElement layerElement = object as LayerElement;
      if (!beamElement.horizontalContentOverlap(object)) continue;
      final int elementBottom = layerElement.getContentBottom();
      final int elementTop = layerElement.getContentTop();
      if (directionBias > 0) {
        // Ensure that there's actual overlap first
        if (elementBottom > yMax) continue;
        if (drawingY >= elementTop) continue;
        // If there is a mild overlap, then decrease the beam stem length via
        // negative overlap
        if (elementBottom > yMax - 3 * unit) {
          elementOverlap = min(elementBottom - yMax, 0);
        } else {
          elementOverlap = max(elementTop - yMin, 0);
        }
      } else {
        // Ensure that there's actual overlap first
        if (elementTop < yMin) continue;
        if (drawingY <= elementBottom) continue;
        // If there is a mild overlap, then decrease the beam stem length via
        // negative overlap
        if (elementTop < yMin + 3 * unit) {
          elementOverlap = min(yMin - elementTop, 0);
        } else {
          elementOverlap = max(yMax - elementBottom, 0);
        }
      }
      elementOverlaps.add(elementOverlap);
    }
    if (elementOverlaps.isEmpty) return 0;

    final int minOverlap = elementOverlaps.reduce(min);
    final int maxOverlap = elementOverlaps.reduce(max);
    int overlap = 0;
    if (maxOverlap > 0) {
      overlap = maxOverlap * directionBias;
    } else if (minOverlap < 0) {
      overlap = (minOverlap - unit) * directionBias;
    }
    final int adjust = adjustOverlapToHalfUnit(overlap, unit);
    return adjust;
  }

  /// Rounds the overlap to the closest multiple of a half unit (mirrors
  /// `AdjustBeamsFunctor::AdjustOverlapToHalfUnit`,
  /// adjustbeamsfunctor.cpp:426).
  int adjustOverlapToHalfUnit(int overlap, int unit) {
    final int overlapSign = (overlap >= 0) ? 1 : -1;
    final int halfUnit = unit ~/ 2;
    final int halfUnitChangeNumber =
        (overlap.abs() + halfUnit ~/ 2) ~/ halfUnit;
    return halfUnitChangeNumber * halfUnit * overlapSign;
  }

  /// Mirrors `Layer::GetLayerElementsForTimeSpanOf` (layer.cpp:417), via the
  /// already-ported [Layer.getLayerElementsForTimeSpanOf].
  List<model.Object> _layerElementsForTimeSpanOf(
      Layer parentLayer, LayerElement element, bool excludeCurrent) {
    // `getLayerElementsForTimeSpanOf` returns a `const []` in its own
    // no-alignment/no-beam edge cases; wrap in a fresh mutable list so
    // `calcLayerOverlap`'s `removeWhere` never sees an unmodifiable list
    // (matches the `UnsupportedError` this stub used to dodge for the
    // stem-sameas beams of `stem/stem-014.mei` and `stem-016.mei`).
    return <model.Object>[
      ...parentLayer.getLayerElementsForTimeSpanOf(element,
          excludeCurrent: excludeCurrent)
    ];
  }

  /// Mirrors `BeamSegment::RequestStaffSpace` (beam.cpp:1560): for a
  /// cross-staff mixed-place beam, requests extra vertical space on the
  /// staff above/below whenever the minimal stem length on that side falls
  /// short of `beamMixedStemMin` (+1 unit of cross-staff tolerance).
  void requestStaffSpace(
      Doc doc, BeamDrawingInterface beamInterface, BeamSegment segment) {
    if (beamInterface.drawingPlace != Beamplace.mixed) return;
    final Staff? beamStaff = beamInterface.beamStaff as Staff?;
    final Staff? crossStaffContent = beamInterface.crossStaffContent as Staff?;
    if (beamStaff == null || crossStaffContent == null) return;

    final int unit = doc.getDrawingUnit(beamStaff.drawingStaffSize);
    // Deviation: `beamMixedStemMin` is not in options_shell.dart yet (same
    // gap already documented for `BeamSegment.needToResetPosition`); this
    // hardcodes the C++ default (3.5) rather than wiring an unrelated new
    // option for this mixed-beam-only path.
    const double beamMixedStemMin = 3.5;
    final int minLength = ((1 + beamMixedStemMin) * unit).toInt();

    StaffAlignment? above;
    StaffAlignment? below;
    if ((beamStaff.n ?? 0) < (crossStaffContent.n ?? 0)) {
      above = beamStaff.staffAlignment;
      below = crossStaffContent.staffAlignment;
    } else {
      above = crossStaffContent.staffAlignment;
      below = beamStaff.staffAlignment;
    }

    final (int minLengthAbove, int minLengthBelow) =
        segment.getMinimalStemLength(beamInterface);
    // Deviation: unlike the C++ (which relies on a mixed-place beam always
    // having coords in both stem directions, so neither side of
    // GetMinimalStemLength stays unset), this port's per-note stem direction
    // for cross-staff mixed beams is not always reliable — guard against the
    // sentinel explicitly rather than let it flow into the space request as
    // a near-2^31 "shift" (see beam-050.mei).
    if (minLengthAbove != meiUnset && minLengthAbove < minLength && above != null) {
      above.setRequestedSpaceBelow(minLength - minLengthAbove);
    }
    if (minLengthBelow != meiUnset && minLengthBelow < minLength && below != null) {
      below.setRequestedSpaceAbove(minLength - minLengthBelow);
    }
  }
}

/// Mirrors the beam-aware `BoundingBox::Intersects` overload
/// (boundingbox.cpp:781): the vertical overlap of [box] with the beam line
/// described by [beam], as seen from the beam content side when
/// [fromBeamContentSide] is set. Top-level (not a [BoundingBox] member) to
/// keep the beam model classes out of `core/`; the C++ method is on
/// `BoundingBox` because `BeamDrawingInterface` lives in the same layer.
int beamIntersects(model.Object box, Beam beam, Accessor type, int margin,
    bool fromBeamContentSide) {
  final List<BeamElementCoord> coords = beam.beamSegment.beamElementCoordRefs;
  assert(coords.isNotEmpty);

  final Point beamLeft = Point(coords.first.x, coords.first.yBeam);
  final Point beamRight = Point(coords.last.x, coords.last.yBeam);

  final int leftX =
      (type == Accessor.self ? box.getSelfLeft() : box.getContentLeft()) -
          margin;
  final int rightX =
      (type == Accessor.self ? box.getSelfRight() : box.getContentRight()) +
          margin;

  Point leftIntersection = Point(0, 0);
  Point rightIntersection = Point(0, 0);
  final double beamSlope = BoundingBox.calcSlope(beamLeft, beamRight);
  if (leftX <= beamLeft.x) {
    // BB does not overlap horizontally with beam (left side of the beam)
    if (rightX < beamLeft.x) {
      return 0;
    }
    // BB overlaps with left side of the beam
    else if (rightX < beamRight.x) {
      leftIntersection = beamLeft;
      rightIntersection =
          Point(rightX, beamLeft.y + (beamSlope * (rightX - beamLeft.x)).toInt());
    }
    // BB covers the whole beam
    else {
      leftIntersection = beamLeft;
      rightIntersection = beamRight;
    }
  } else {
    if (rightX > beamRight.x) {
      // BB overlaps with right side of the beam
      if (leftX <= beamRight.x) {
        leftIntersection =
            Point(leftX, beamLeft.y + (beamSlope * (leftX - beamLeft.x)).toInt());
        rightIntersection = beamRight;
      }
      // BB does not overlap horizontally with beam (right side of the beam)
      else {
        return 0;
      }
    }
    // BB is inside of the beam
    else {
      leftIntersection =
          Point(leftX, beamLeft.y + (beamSlope * (leftX - beamLeft.x)).toInt());
      rightIntersection =
          Point(rightX, beamLeft.y + (beamSlope * (rightX - beamLeft.x)).toInt());
    }
  }

  // calculate vertical overlap of the BB with beam section
  final bool beamAbove = beam.drawingPlace == Beamplace.above;
  final bool beamBelow = beam.drawingPlace == Beamplace.below;

  if ((beamAbove && !fromBeamContentSide) ||
      (beamBelow && fromBeamContentSide)) {
    final int topY = max(leftIntersection.y, rightIntersection.y);
    final int shift =
        topY - (type == Accessor.self ? box.getSelfBottom() : box.getContentBottom()) +
            margin;
    return max(shift, 0);
  } else if ((beamBelow && !fromBeamContentSide) ||
      (beamAbove && fromBeamContentSide)) {
    final int bottomY = min(leftIntersection.y, rightIntersection.y);
    final int shift =
        bottomY - (type == Accessor.self ? box.getSelfTop() : box.getContentTop()) -
            margin;
    return min(shift, 0);
  }

  return 0;
}

/// The `StemmedDrawingInterface` of [element] when it carries one (mirrors
/// `LayerElement::GetStemmedDrawingInterface`): the Chord or Note interface,
/// or the TabDurSym interface for TabGrp. Returns null otherwise.
/// Mirrors `Clef::GetClefGlyph` (clef.cpp:132): the SMuFL code of the clef,
/// with @glyph.num / @glyph.name taking priority. Returns 0 when unknown.
///
/// Deviation from the C++: the resources instance is the process-wide one
/// (pointed at `assets/data`), not `Doc::GetResources()` — same pattern as
/// `_docGetGlyphWidth` in adjust_tuplets.dart. The clefChange glyph variants
/// need `Clef::GetAlignment()->GetType()`, not carried headlessly; they are
/// never selected.
int _clefGlyph(Clef clef, Notationtype notationtype) {
  _ClefGlyphResources.ensure();
  final Resources resources = _ClefGlyphResources.resources;
  if (!_ClefGlyphResources.ok) return 0;

  // If there is glyph.num, prioritize it
  if (clef.hasGlyphNum) {
    final int code = clef.glyphNum!;
    if (resources.getGlyphByCode(code) != null) return code;
  }
  // If there is glyph.name (second priority)
  else if (clef.hasGlyphName) {
    final int code = resources.getGlyphCode(clef.glyphName!);
    if (resources.getGlyphByCode(code) != null) return code;
  }

  switch (notationtype) {
    case Notationtype.tab:
    case Notationtype.tabGuitar:
      return smuflE06D6stringTabClef;
    case Notationtype.neume:
      // neume clefs
      switch (clef.shape) {
        case Clefshape.f:
          return smuflE902ChantFclef;
        case Clefshape.c:
          return smuflE906ChantCclef;
        case Clefshape.g:
          return smuflE900MensuralGclef;
        default:
          return smuflE906ChantCclef;
      }
    case Notationtype.mensural:
    case Notationtype.mensuralWhite:
      // mensural clefs
      switch (clef.shape) {
        case Clefshape.g:
          return smuflE901MensuralGclefPetrucci;
        case Clefshape.f:
          return smuflE904MensuralFclefPetrucci;
        case Clefshape.c:
          switch (clef.line) {
            case 1:
              return smuflE907MensuralCclefPetrucciPosLowest;
            case 2:
              return smuflE908MensuralCclefPetrucciPosLow;
            case 3:
              return smuflE909MensuralCclefPetrucciPosMiddle;
            case 4:
              return smuflE90AMensuralCclefPetrucciPosHigh;
            case 5:
              return smuflE90BMensuralCclefPetrucciPosHighest;
          }
          return smuflE909MensuralCclefPetrucciPosMiddle;
        default:
          return smuflE909MensuralCclefPetrucciPosMiddle;
      }
    case Notationtype.mensuralBlack:
      switch (clef.shape) {
        case Clefshape.c:
          return smuflE906ChantCclef;
        case Clefshape.f:
          return smuflE902ChantFclef;
        default:
          // G clef doesn't exist in black notation, so should never get
          // here, but just in case.
          if (clef.dis == null) return smuflE901MensuralGclefPetrucci;
      }
      return _cmnClefGlyph(clef);
    default:
      return _cmnClefGlyph(clef);
  }
}

/// The cmn clefs tail of `Clef::GetClefGlyph` (clef.cpp:184-213).
int _cmnClefGlyph(Clef clef) {
  switch (clef.shape) {
    case Clefshape.g:
      switch (clef.dis) {
        case OctaveDis.n8:
          return (clef.disPlace == StaffrelBasic.above)
              ? smuflE053GClef8va
              : smuflE052GClef8vb;
        case OctaveDis.n15:
          return (clef.disPlace == StaffrelBasic.above)
              ? smuflE054GClef15ma
              : smuflE051GClef15mb;
        default:
          return smuflE050Gclef;
      }
    case Clefshape.gg:
      return smuflE055GClef8vbOld;
    case Clefshape.f:
      switch (clef.dis) {
        case OctaveDis.n8:
          return (clef.disPlace == StaffrelBasic.above)
              ? smuflE065FClef8va
              : smuflE064FClef8vb;
        case OctaveDis.n15:
          return (clef.disPlace == StaffrelBasic.above)
              ? smuflE066FClef15ma
              : smuflE063FClef15mb;
        default:
          return smuflE062Fclef;
      }
    case Clefshape.c:
      switch (clef.dis) {
        case OctaveDis.n8:
          return smuflE05DCclef8vb;
        default:
          return smuflE05CCclef;
      }
    case Clefshape.perc:
      return smuflE069UnpitchedPercussionClef1;
    default:
      return 0;
  }
}

/// Lazy resources accessor for `_clefGlyph` — same pattern as
/// `_TupletGlyphMetrics` in adjust_tuplets.dart.
class _ClefGlyphResources {
  static bool _done = false;
  static late final Resources resources;

  static void ensure() {
    if (_done) return;
    _done = true;
    // Repo convention (00-MESTRE §4.6): consumers must point the resources
    // at the package assets folder; the static default ('data') is wrong for
    // this layout.
    final Resources res = Resources();
    res.path = 'assets/data';
    if (!res.ok) res.initFonts();
    resources = res;
  }

  static bool get ok => resources.ok;
}
