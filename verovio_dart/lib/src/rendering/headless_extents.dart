/// Headless bounding-box provider for the vertical layout.
///
/// In the C++, `Page::LayOutVertically` runs `View::DrawCurrentPage` with a
/// BBoxDeviceContext to fill the bounding boxes of the layer elements and to
/// create / initialize the FloatingPositioners of the control events. The
/// full View rendering is ported in Phase 5; this pass mirrors ONLY the
/// fragments of view_element.cpp / view_control.cpp / view_page.cpp needed
/// to produce credible bounding boxes:
///
/// - noteheads, rests, clefs, accidentals, dots: SMuFL glyph bboxes through
///   [Resources] (exactly the math of BBoxDeviceContext.drawMusicText);
/// - stems: vertical bars using the stem length computed by
///   CalcStemFunctor (mirrors View::DrawStem);
/// - beams / tuplet brackets: no bounding box (the C++ only has them after
///   the beam segment phase; undrawn elements are ignored by
///   CalcBBoxOverflowsFunctor as well);
/// - staff lines extent: not required (staves are not part of the overflow
///   arrays); the staff height is known from StaffAlignment;
/// - control events: positioner creation through
///   System.setSystemCurrentFloatingPositioner (mirroring
///   View::DrawTimeSpanningElement) with approximate content extents;
/// - slurs / ties: initial curve calculation mirroring Slur.CalcInitialCurve
///   (see the approximations documented on [calcInitialCurveFor]).
///
/// Every deviation from the C++ drawing math is documented inline with
/// "Approximation:".
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset, MeiDuration;
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/smufl.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/layout/adjust_arpeg.dart'
    show getDrawingTopBottomNotes;
import 'package:verovio_dart/src/layout/functor.dart' show Functor;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/layout/slur_positioning.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Clef, Measure, Note, Rest, Staff;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart'
    show DurationInterface;
import 'package:verovio_dart/src/model/interfaces/time_interface.dart'
    show TimeSpanningInterface;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Accid, Artic, KeySig, Stem;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/rendering/glyph.dart';
import 'package:verovio_dart/src/rendering/resources.dart';

/// The headless extents pass over one page.
class HeadlessExtents {
  HeadlessExtents(this.doc);

  final Doc doc;

  /// The resources used for the glyph metrics (loaded once).
  final Resources resources = Resources();
  bool _fontsInitialized = false;

  /// Try to load the SMuFL fonts once; failures fall back to tabulated
  /// default boxes.
  void _ensureFonts() {
    if (_fontsInitialized) return;
    _fontsInitialized = true;
    if (!resources.ok) {
      resources.initFonts();
    }
  }

  /// True when real glyph metrics are available.
  bool get hasGlyphMetrics => resources.ok;

  // -------------------------------------------------------------------------
  // Glyph helpers
  // -------------------------------------------------------------------------

  /// Mirrors `Doc::GetDrawingSmuflFont(staffSize, graceSize).GetPointSize()`.
  int _musicFontSize(int staffSize, bool cueSize) {
    int value = doc.getDrawingStaffSize(staffSize);
    if (cueSize) value = doc.getCueSize(value);
    return value;
  }

  /// Width of a glyph in logical units (mirrors `Doc::GetGlyphWidth`);
  /// falls back to [Doc.getGlyphWidth] when the fonts are not loaded.
  int glyphWidth(int code, int staffSize, bool cueSize) {
    _ensureFonts();
    final Glyph? glyph =
        hasGlyphMetrics ? resources.getGlyphByCode(code) : null;
    if (glyph != null) {
      final int pointSize = _musicFontSize(staffSize, cueSize);
      return (glyph.horizAdvX * pointSize) ~/ glyph.unitsPerEm;
    }
    return doc.getGlyphWidth(code, staffSize, cueSize);
  }

  /// Fill the SELF bounding box of [target] with the bbox of a single SMuFL
  /// glyph drawn at ([x], [y]) (exact port of the drawMusicText math of
  /// BBoxDeviceContext).
  ///
  /// Returns false when the glyph is not available (no font loaded).
  bool fillGlyphBox(BoundingBox target, int x, int y, int code, int staffSize,
      {bool cueSize = false}) {
    _ensureFonts();
    if (!hasGlyphMetrics) return false;
    final Glyph? glyph = resources.getGlyphByCode(code);
    if (glyph == null) return false;

    final int pointSize = _musicFontSize(staffSize, cueSize);
    final (int gX, int gY, int gW, int gH) = glyph.getBoundingBox();

    // Note: the y axis is NOT flipped here: this pass computes LOGICAL
    // coordinates directly (the device context flip of View::ToLogicalY is
    // already undone).
    final int xOff = x + (gX * pointSize) ~/ glyph.unitsPerEm;
    final int x2 = xOff + (gW * pointSize) ~/ glyph.unitsPerEm;
    // The glyph box extends downwards from the baseline in logical coords.
    final int yTop = y + (gY * pointSize) ~/ glyph.unitsPerEm;
    final int yBottom = yTop - (gH * pointSize) ~/ glyph.unitsPerEm;

    target.updateSelfBBoxX(xOff, x2);
    target.updateSelfBBoxY(yTop, yBottom);
    target.updateContentBBoxX(xOff, x2);
    target.updateContentBBoxY(yTop, yBottom);

    return true;
  }

  // -------------------------------------------------------------------------
  // Page processing
  // -------------------------------------------------------------------------

  /// Fill the bounding box of [curve] from its bezier points (analytic
  /// equivalent of drawing the thick bezier curve).
  void fillCurveBox(FloatingCurvePositioner curve) {
    final List<Point> points = curve.getPoints();
    if (points[0].x >= points[3].x) return;

    final (Point pos, int width, int height, _, _) =
        BoundingBox.approximateBezierBoundingBox(points);

    final int halfThickness = curve.getThickness() ~/ 2;
    curve.updateContentBBoxX(pos.x, pos.x + width);
    curve.updateContentBBoxY(
        pos.y + height + halfThickness, pos.y - halfThickness);
    curve.updateSelfBBoxX(pos.x, pos.x + width);
    curve.updateSelfBBoxY(
        pos.y + height + halfThickness, pos.y - halfThickness);
  }

  /// Run the pass over [page]: fill layer element bounding boxes and create /
  /// initialize the floating positioners (mirrors View::DrawCurrentPage
  /// reduced to the needs of LayOutVertically).
  void processPage(Page page) {
    for (final Object child in page.children) {
      if (child is! System) continue;
      fillLayerElementExtents(child);
      createControlEventPositioners(child);
    }
  }

  /// Fill the bounding boxes of the curve positioners from their bezier
  /// points (headless replacement of the second render pass with
  /// SlurHandling::Drawing that follows AdjustSlursFunctor in the C++; the
  /// adjusted curves are "redrawn" here analytically).
  void fillCurvePositionerBoxes(Page page) {
    _ensureFonts();
    for (final Object child in page.children) {
      if (child is! System) continue;
      child.systemAligner.process(_CurveBoxFiller(this));
    }
  }

  /// Fill the self / content bounding boxes of all layer elements below
  /// [system].
  void fillLayerElementExtents(System system) {
    final List<Object> elements =
        system.findAllDescendantsByClassIdPredicate(Object.isLayerElementId);

    for (final Object object in elements) {
      final LayerElement element = object as LayerElement;
      if (element.isScoreDefElement) continue;
      final Staff? staff = element.getAncestorStaffLayoutOrNull();
      if (staff == null) continue;
      if (!element.layoutIsVisible()) continue;
      _fillElementSelfBBox(element, staff);
    }

    // Propagate the children boxes to the ancestor layer elements (mirrors
    // the content bounding box stretching done by BBoxDeviceContext for the
    // objects left on the graphic stack).
    for (final Object object in elements) {
      final LayerElement element = object as LayerElement;
      if (!element.hasSelfBB()) continue;
      Object? ancestor = element.parent;
      while (ancestor != null &&
          ancestor.isLayerElement &&
          ancestor.classId != ClassId.staff) {
        final LayerElement parent = ancestor as LayerElement;
        parent.updateContentBBoxX(element.getSelfLeft(), element.getSelfRight());
        parent.updateContentBBoxY(element.getSelfTop(), element.getSelfBottom());
        ancestor = parent.parent;
      }
    }
  }

  /// Fill the self bbox of one layer element according to its class
  /// (headless equivalents of the View::DrawXxx methods).
  void _fillElementSelfBBox(LayerElement element, Staff staff) {
    final int x = element.getDrawingX();
    final int y = element.getDrawingY();
    final int staffSize = staff.drawingStaffSize;

    switch (element.classId) {
      case ClassId.note:
      case ClassId.nc:
        final DurationInterface duration = element as DurationInterface;
        final MeiDuration dur =
            duration.dur ?? MeiDuration.dur4;
        fillGlyphBox(element, x, y, noteheadGlyph(dur), staffSize,
            cueSize: element.drawingCueSize);
        break;
      case ClassId.chord:
        // Approximation: the chord itself gets no self box; its content box
        // is filled from the notes (like the C++ where the chord graphic
        // wraps the noteheads).
        break;
      case ClassId.rest:
        final Rest rest = element as Rest;
        final MeiDuration dur =
            rest.hasDur ? rest.dur! : MeiDuration.dur4;
        fillGlyphBox(element, x, y, restGlyph(dur), staffSize);
        break;
      case ClassId.dot:
      case ClassId.dots:
        // Approximation: small circle of half unit diameter at the dot
        // position (the C++ draws an actual SMuFL augmentation dot).
        const int radius = 0;
        element.updateSelfBBoxX(
            x - doc.getDrawingUnit(staffSize) ~/ 4,
            x + doc.getDrawingUnit(staffSize) ~/ 4 + radius);
        element.updateSelfBBoxY(
            y - doc.getDrawingUnit(staffSize) ~/ 4,
            y + doc.getDrawingUnit(staffSize) ~/ 4);
        element.updateContentBBoxX(element.getSelfX1(), element.getSelfX2());
        element.updateContentBBoxY(element.getSelfY1(), element.getSelfY2());
        break;
      case ClassId.clef:
        fillGlyphBox(element, x, y, clefGlyph(element as Clef), staffSize);
        break;
      case ClassId.accid:
        fillGlyphBox(element, x, y, accidGlyph(element as Accid), staffSize,
            cueSize: element.drawingCueSize);
        break;
      case ClassId.keysig:
        // Approximation: full staff height box with two units per
        // alteration (the C++ draws each accidental glyph).
        final unit = doc.getDrawingUnit(staffSize);
        final KeySig keySig = element as KeySig;
        final int alterations =
            keySig.hasSig ? (keySig.sig!.sig.abs()) : 0;
        element.updateSelfBBoxX(x, x + unit * (alterations + 1));
        element.updateSelfBBoxY(y, y - (staff.drawingLines - 1) * 2 * unit);
        element.updateContentBBoxX(element.getSelfX1(), element.getSelfX2());
        element.updateContentBBoxY(element.getSelfY1(), element.getSelfY2());
        break;
      case ClassId.meterSig:
        // Approximation: full staff height box, two units wide.
        final unit = doc.getDrawingUnit(staffSize);
        element.updateSelfBBoxX(x, x + 2 * unit);
        element.updateSelfBBoxY(y, y - 3 * 2 * unit);
        element.updateContentBBoxX(element.getSelfX1(), element.getSelfX2());
        element.updateContentBBoxY(element.getSelfY1(), element.getSelfY2());
        break;
      case ClassId.stem:
        _fillStemBBox(element as Stem);
        break;
      case ClassId.artic:
        // Approximation: one unit high box on the drawing place side of the
        // note (the artic drawing place was set by CalcArticFunctor).
        final Artic artic = element as Artic;
        final unit = doc.getDrawingUnit(staffSize);
        final bool above = artic.drawingPlace != Staffrel.below;
        element.updateSelfBBoxX(x - unit ~/ 2, x + unit ~/ 2);
        element.updateSelfBBoxY(above ? y : y, above ? y + unit : y - unit);
        element.updateContentBBoxX(element.getSelfX1(), element.getSelfX2());
        element.updateContentBBoxY(element.getSelfY1(), element.getSelfY2());
        break;
      case ClassId.mRest:
      case ClassId.mRpt:
      case ClassId.mRpt2:
      case ClassId.multiRest:
      case ClassId.multiRpt:
        // Approximation: centered double-unit square (the C++ width spans
        // the measure or the number of measures).
        final unit = doc.getDrawingUnit(staffSize);
        element.updateSelfBBoxX(x - unit, x + unit);
        element.updateSelfBBoxY(y - unit, y + unit);
        element.updateContentBBoxX(element.getSelfX1(), element.getSelfX2());
        element.updateContentBBoxY(element.getSelfY1(), element.getSelfY2());
        break;
      default:
        // Beams, tuplet brackets, flags, syl, verse etc. have no headless
        // bounding box ("if nothing was drawn, do not take it into account"
        // like CalcBBoxOverflowsFunctor).
        break;
    }
  }

  /// Mirrors View::DrawStem reduced to the bounding box.
  void _fillStemBBox(Stem stem) {
    final dynamic parent = stem.parent;
    if (parent == null || parent is! LayerElement) return;
    final Staff? staff = parent.getAncestorStaffLayoutOrNull();
    if (staff == null) return;

    final int len = stem.getDrawingStemLen();
    if (len == 0) return;

    final int x = stem.getDrawingX();
    final int y = stem.getDrawingY();
    final int halfWidth = doc.getDrawingStemWidth(staff.drawingStaffSize) ~/ 2;

    // The stem end is at drawingY - len (see StemmedDrawingInterface::
    // GetDrawingStemEnd).
    final int endY = y - len;

    stem.updateSelfBBoxX(x - halfWidth, x + halfWidth);
    stem.updateSelfBBoxY(math.max(y, endY), math.min(y, endY));
    stem.updateContentBBoxX(stem.getSelfX1(), stem.getSelfX2());
    stem.updateContentBBoxY(stem.getSelfY1(), stem.getSelfY2());
  }

  // -------------------------------------------------------------------------
  // Control events
  // -------------------------------------------------------------------------

  /// Create the floating positioners for the control events of [system]
  /// (mirrors View::DrawTimeSpanningElement reduced to the positioner
  /// creation; the drawing itself arrives with Phase 5).
  void createControlEventPositioners(System system) {
    final List<Object> measures =
        system.findAllDescendantsByType(ClassId.measure, deepness: 1);

    for (final Object object in measures) {
      final Measure measure = object as Measure;
      for (final Object child in measure.children) {
        if (!child.isControlElement) continue;

        if (child.hasInterface(InterfaceId.timeSpanning)) {
          final TimeSpanningInterface interface =
              child as TimeSpanningInterface;
          final Object? start = interface.getStart();
          Object? end = interface.getEnd();
          if (start != null &&
              end != null &&
              !identical(start, end)) {
            _processControlEvent(system, measure, child, interface);
            continue;
          }
        }

        // Point like control events (fermata, breath, arpeg…) get a
        // positioner anchored at their start element (mirrors the direct
        // DrawControlElement calls).
        _processPointControlEvent(system, measure, child);
      }
    }
  }

  /// Create the positioner of a point-like control event.
  void _processPointControlEvent(System system, Measure measure, Object element) {
    final dynamic dynamicElement = element;
    if (!element.hasInterface(InterfaceId.timePoint) &&
        !element.isClass(ClassId.arpeg)) {
      return;
    }
    final Object? start =
        element.hasInterface(InterfaceId.timePoint)
            ? (element as dynamic).getStart() as Object?
            : null;

    // Arpeg: mirrors View::DrawArpeg.
    if (element.isClass(ClassId.arpeg)) {
      final (Note? topNote, Note? bottomNote) =
          getDrawingTopBottomNotes(dynamicElement);
      if (topNote == null || bottomNote == null) return;
      final Staff staff = topNote.getAncestorStaffLayout();
      final bool created = system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset,
          element as FloatingObject,
          topNote,
          staff,
          spanningStartEnd);
      if (!created) return;
      final FloatingPositioner? positioner =
          dynamicElement.getCurrentFloatingPositioner() as FloatingPositioner?;
      // The xRel is stored on the Arpeg itself in the C++; keep 0 headlessly.
      if (positioner != null) {
        positioner.setDrawingXRel((element as dynamic).drawingXRel as int);
        final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
        final int x = element.getDrawingX();
        final int top = topNote.getDrawingY() + unit;
        final int bottom = bottomNote.getDrawingY() - unit;
        positioner.updateContentBBoxX(x - unit ~/ 2, x + unit ~/ 2);
        positioner.updateContentBBoxY(bottom, top);
        positioner.updateSelfBBoxX(x - unit ~/ 2, x + unit ~/ 2);
        positioner.updateSelfBBoxY(bottom, top);
      }
      return;
    }

    if (start == null || start is! LayerElement) return;

    final List<Staff> staffList = _tstampStaves(measure, element, start);
    for (final Staff staff in staffList) {
      final bool created = system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset,
          element as FloatingObject,
          start,
          staff,
          spanningStartEnd);
      if (!created) continue;
      final FloatingPositioner? positioner =
          dynamicElement.getCurrentFloatingPositioner() as FloatingPositioner?;
      if (positioner != null) {
        _fillControlEventBox(positioner, element, start.getDrawingX(),
            start.getDrawingX(), staff);
      }
      break;
    }
  }

  void _processControlEvent(System system, Measure measure, Object element,
      TimeSpanningInterface interface) {
    final Object? start = interface.getStart();
    Object? end = interface.getEnd();

    // Deviation: the LinkingInterface next-link branch (open elements
    // continued by @next) is not ported yet.
    if (start == null || end == null) return;
    if (start is! LayerElement || end is! LayerElement) return;

    // Get the parent system of the first and last element
    final Object? parentSystem1 = start.getFirstAncestor(ClassId.system);
    final Object? parentSystem2 = end.getFirstAncestor(ClassId.system);

    int x1;
    int x2;
    Object objectX;
    int spanningType = spanningStartEnd;
    Measure anchorMeasure = measure;

    if (identical(system, parentSystem1) && identical(system, parentSystem2)) {
      anchorMeasure = interface.getStartMeasure() ?? measure;
      x1 = start.getDrawingX();
      objectX = start;
      x2 = end.getDrawingX();
    } else if (identical(system, parentSystem1)) {
      // Open at the end of the system
      final List<Object> measures =
          system.findAllDescendantsByType(ClassId.measure, deepness: 1);
      if (measures.isEmpty) return;
      anchorMeasure = measures.last as Measure;
      x1 = start.getDrawingX();
      objectX = start;
      x2 = anchorMeasure.getDrawingX() + anchorMeasure.measureAligner.getRightBarLineXRel();
      spanningType = spanningStart;
    } else if (identical(system, parentSystem2)) {
      final List<Object> measures =
          system.findAllDescendantsByType(ClassId.measure, deepness: 1);
      if (measures.isEmpty) return;
      anchorMeasure = measures.first as Measure;
      x1 = anchorMeasure.getDrawingX() +
          anchorMeasure.measureAligner.getLeftBarLineXRel();
      objectX = anchorMeasure.leftBarLine;
      x2 = end.getDrawingX();
      spanningType = spanningEnd;
    } else {
      // Connector throughout the system
      final List<Object> measures =
          system.findAllDescendantsByType(ClassId.measure, deepness: 1);
      if (measures.length < 2) return;
      anchorMeasure = measures.first as Measure;
      x1 = anchorMeasure.getDrawingX() +
          anchorMeasure.measureAligner.getLeftBarLineXRel();
      objectX = anchorMeasure.leftBarLine;
      final Measure last = measures.last as Measure;
      x2 = last.getDrawingX() + last.measureAligner.getRightBarLineXRel();
      spanningType = spanningMiddle;
    }

    // Overwrite the spanning type for open ended control events ending on a
    // right barline (not detectable headlessly — see Phase 5).

    final int startRadius = _drawingRadius(start);
    final int endRadius = _drawingRadius(end);

    if (spanningType == spanningStartEnd) {
      x1 += startRadius;
      x2 += endRadius;
    } else if (spanningType == spanningStart) {
      x1 += startRadius;
    } else if (spanningType == spanningEnd) {
      x2 += endRadius;
    }

    final List<Staff> staffList = _tstampStaves(anchorMeasure, element, start);
    bool isFirst = true;
    for (final Staff staff in staffList) {
      // For slurs we limit support to one value in @staff (see the C++).
      if (!isFirst &&
          element.isAny(const {ClassId.slur, ClassId.phrase, ClassId.lv, ClassId.tie})) {
        break;
      }

      // Create the floating positioner (slurs use the principal staff in the
      // C++; Approximation: the tstamp staff is used instead since the
      // spanned element search requires the rendered positions).
      final bool created = system.setSystemCurrentFloatingPositioner(
          staff.n ?? meiUnset,
          element as FloatingObject,
          objectX,
          staff,
          spanningType);
      if (!created) {
        isFirst = false;
        continue;
      }

      final dynamic dynamicElement = element;
      final FloatingPositioner? positioner =
          dynamicElement.getCurrentFloatingPositioner() as FloatingPositioner?;
      if (positioner is! FloatingCurvePositioner) {
        // Non curve elements: fill an approximate content bounding box.
        _fillControlEventBox(positioner, element, x1, x2, staff);
        isFirst = false;
        continue;
      }

      // Slurs / ties: initial curve calculation (mirrors View::CalcInitialSlur
      // with SlurHandling::Initialize).
      positioner.setCachedX12((x1, x2));

      if (element.isAny(const {ClassId.tie, ClassId.lv})) {
        // Approximation: the tie direction is derived from the boundary stem
        // directions (ties avoid stems); the refined Tie::GetTieDirection
        // logic arrives with the rendering phase.
        final Stemdirection startDir = start.getDrawingStemDirHeadless();
        final Stemdirection endDir = end.getDrawingStemDirHeadless();
        final bool stemsUp = (startDir == Stemdirection.up) ||
            (endDir == Stemdirection.up);
        dynamicElement.setDrawingCurveDir(
            stemsUp ? SlurCurveDirection.below : SlurCurveDirection.above);
      }

      element.calcInitialCurveFor(doc, positioner, null);
      element.calcSpannedElementsFor(doc, positioner);
      // Fill the initial bounding box of the curve (the C++ gets it from the
      // first render pass; Approximation: analytic bezier bbox expanded by
      // half the thickness).
      fillCurveBox(positioner);
      isFirst = false;
    }
  }

  /// Approximate the content bounding box of a non curve control event
  /// relative to the staff top line (see the class documentation for the
  /// coordinate conventions).
  void _fillControlEventBox(
      FloatingPositioner? positioner, Object element, int x1, int x2, Staff staff) {
    if (positioner == null) return;

    final int staffSize = staff.drawingStaffSize;
    final int unit = doc.getDrawingUnit(staffSize);
    final Staffrel place =
        positioner.getDrawingPlace() == Staffrel.none
            ? Staffrel.above
            : positioner.getDrawingPlace();

    // Height and width by class. Approximation: text extents are estimated
    // from the character count (or measured with the Times text font when
    // available).
    int height;
    switch (element.classId) {
      case ClassId.hairpin:
        height = unit;
        break;
      case ClassId.fermata:
        height = 2 * unit;
        break;
      case ClassId.trill:
      case ClassId.mordent:
      case ClassId.turn:
      case ClassId.ornam:
        height = 2 * unit;
        break;
      case ClassId.octave:
      case ClassId.bracketSpan:
        height = 3 * unit;
        break;
      case ClassId.breath:
      case ClassId.caesura:
        height = unit;
        break;
      case ClassId.pedal:
        height = 3 * unit ~/ 2;
        break;
      default:
        // Text based control events (dir, dynam, tempo, harm, reh, fing…)
        height = _textHeight(element, staffSize);
        break;
    }

    // Anchor the box adjacent to the staff top line (see the class docs):
    // above → [0, h]; below → [-h, 0]; between/within → [-h/2, h/2].
    int y1;
    int y2;
    switch (place) {
      case Staffrel.above:
        y1 = 0;
        y2 = height;
        break;
      case Staffrel.within:
        y1 = -height ~/ 2;
        y2 = height ~/ 2;
        break;
      default:
        y1 = -height;
        y2 = 0;
        break;
    }

    positioner.updateContentBBoxX(x1, x2);
    positioner.updateContentBBoxY(y1, y2);
    positioner.updateSelfBBoxX(x1, x2);
    positioner.updateSelfBBoxY(y1, y2);
  }

  /// Approximated text height for text based control events.
  int _textHeight(Object element, int staffSize) {
    final String text = collectControlText(element);
    if (text.isEmpty) return doc.getDrawingUnit(staffSize) * 2;

    _ensureFonts();
    // Approximation: measure with the Times text font at ~60% of the music
    // size (the C++ lyric / dir fonts are derived from the staff size too).
    final int pointSize = doc.getDrawingUnit(staffSize) * 6;
    if (hasGlyphMetrics) {
      final Map<int, Glyph>? table = resources.textFont[resources.currentStyle];
      if (table != null) {
        int ascent = 0;
        int descent = 0;
        int width = 0;
        for (final int rune in text.runes) {
          final Glyph? glyph = table[rune] ??
              table['o'.runes.first];
          if (glyph == null) continue;
          ascent = math.max(ascent, (glyph.y * pointSize) ~/ glyph.unitsPerEm);
          descent = math.min(descent, ((glyph.y + glyph.height) * pointSize) ~/
              glyph.unitsPerEm);
          width += (glyph.horizAdvX * pointSize) ~/ glyph.unitsPerEm;
        }
        if (width > 0) return ascent - descent;
      }
    }
    // Fallback without fonts: half unit per character, bounded.
    return math.max(text.runes.length * doc.getDrawingUnit(staffSize) ~/ 2,
        doc.getDrawingUnit(staffSize) * 2);
  }

  /// The drawing radius of an element (reduced port of
  /// LayerElement::GetDrawingRadius): half the notehead glyph width for
  /// notes / chords / rests; 0 otherwise. Mensural specifics are deferred
  /// (task 7).
  int _drawingRadius(LayerElement element) {
    if (!element.isAny(const {ClassId.chord, ClassId.nc, ClassId.note, ClassId.rest})) {
      return 0;
    }
    final Staff? staff = element.getAncestorStaffLayoutOrNull();
    final int staffSize = staff?.drawingStaffSize ?? 100;

    MeiDuration dur = MeiDuration.dur4;
    if (element is DurationInterface) {
      dur = (element as DurationInterface).getActualDur();
    }
    final int code = element.isClass(ClassId.rest)
        ? smuflE0A4NoteheadBlack
        : noteheadGlyph(dur);
    return glyphWidth(code, staffSize, element.drawingCueSize) ~/ 2;
  }

  /// The staves addressed by a control event (reduced port of
  /// TimeSpanningInterface::GetTstampStaves): the @staff values when present,
  /// otherwise the staff of the start element.
  List<Staff> _tstampStaves(Measure measure, Object element, Object? start) {
    final List<Staff> result = <Staff>[];
    final dynamic staffAttr = (element as dynamic).staff;
    final List<Object> staves =
        measure.findAllDescendantsByType(ClassId.staff, deepness: 1);

    if (staffAttr is List<int> && staffAttr.isNotEmpty) {
      for (final int n in staffAttr) {
        for (final Object object in staves) {
          final Staff staff = object as Staff;
          if (staff.n == n) result.add(staff);
        }
      }
      if (result.isNotEmpty) return result;
    }

    final Object? staffObject = start?.getFirstAncestor(ClassId.staff);
    if (staffObject is Staff) return [staffObject];
    if (staves.isNotEmpty) return [staves.first as Staff];
    return result;
  }
}

/// The notehead glyph for a duration (reduced port of
/// `Note::GetNoteheadGlyph`; head shapes and mensural glyphs arrive with
/// their phases).
int noteheadGlyph(MeiDuration dur) {
  if (dur.value <= MeiDuration.breve.value) return 0xE0A1;
  if (dur == MeiDuration.dur1) return 0xE0A2;
  if (dur == MeiDuration.dur2) return 0xE0A3;
  return smuflE0A4NoteheadBlack;
}

/// The rest glyph for a duration (SMuFL rest series E4E0..E4EB).
int restGlyph(MeiDuration dur) {
  if (dur.value >= MeiDuration.dur1024.value) return 0xE4EB;
  if (dur.value >= MeiDuration.longa.value) return 0xE4E1;
  switch (dur) {
    case MeiDuration.long:
      return 0xE4E1;
    case MeiDuration.maxima:
      return 0xE4E0;
    case MeiDuration.breve:
      return 0xE4E2;
    case MeiDuration.dur1:
      return 0xE4E3;
    case MeiDuration.dur2:
      return 0xE4E4;
    case MeiDuration.dur4:
      return 0xE4E5;
    case MeiDuration.dur8:
      return 0xE4E6;
    case MeiDuration.dur16:
      return 0xE4E7;
    case MeiDuration.dur32:
      return 0xE4E8;
    case MeiDuration.dur64:
      return 0xE4E9;
    case MeiDuration.dur128:
      return 0xE4EA;
    case MeiDuration.dur256:
      return 0xE4EB;
    default:
      return 0xE4E5;
  }
}

/// The clef glyph (reduced mapping of the common shapes).
int clefGlyph(Clef clef) {
  switch (clef.shape) {
    case Clefshape.f:
      return 0xE062; // fClef
    case Clefshape.c:
      return 0xE05C; // cClef
    case Clefshape.perc:
      return 0xE069; // unpitchedPercussionClef1
    case Clefshape.g:
    case Clefshape.gg:
    default:
      return 0xE050; // gClef
  }
}

/// The accidental glyph (mirrors `Accid::GetAccidGlyph`).
int accidGlyph(Accid accid) {
  final AccidentalWritten? alter = accid.accid;
  if (alter == null) return smuflE261AccidentalNatural;
  return Accid.getAccidGlyph(alter);
}

/// Collect the concatenated text content of a text based control event
/// (dir, dynam, tempo, harm…; mirrors the text traversal of the View).
String collectControlText(Object element) {
  final StringBuffer buffer = StringBuffer();
  for (final Object object in element.findAllDescendantsByType(ClassId.text)) {
    final dynamic text = (object as dynamic).text;
    if (text is String) buffer.write(text);
  }
  return buffer.toString();
}

/// Functor filling the bounding boxes of the curve positioners (helper of
/// [HeadlessExtents.fillCurvePositionerBoxes]).
class _CurveBoxFiller extends Functor {
  _CurveBoxFiller(this.owner);

  final HeadlessExtents owner;

  @override
  FunctorCode visitStaffAlignment(StaffAlignment staffAlignment) {
    for (final FloatingPositioner positioner
        in staffAlignment.getFloatingPositioners()) {
      if (positioner is! FloatingCurvePositioner) continue;
      owner.fillCurveBox(positioner);
    }
    return FunctorCode.siblings;
  }
}
