/// Port of the vertical layout functors and of the vertical part of
/// `alignfunctor.h/cpp` / `resetfunctor.cpp`:
///
/// - [ResetVerticalAlignmentFunctor] mirrors `resetfunctor.cpp`
/// - [AlignVerticallyFunctor] and [AlignSystemsFunctor] mirror
///   `alignfunctor.h/cpp`
/// - [CalcAlignmentPitchPosFunctor] mirrors
///   `calcalignmentpitchposfunctor.h/cpp`
/// - [AdjustYPosFunctor] and [AdjustCrossStaffYPosFunctor] mirror
///   `adjustyposfunctor.h/cpp`
/// - [AdjustStaffOverlapFunctor] mirrors `adjuststaffoverlapfunctor.h/cpp`
///
/// The orchestration itself is `Page.layOutVertically` (doc.dart), mirroring
/// `Page::LayOutVertically`.
///
/// Deviations from the C++:
/// - The render pass filling the bounding boxes now uses `View` +
///   `BBoxDeviceContext` (page.cpp:530-536, 554-557) with fallback for elements
///   the View does not yet draw.
/// - Tablature pitch positions (`Tuning::CalcPitchPos`) and the cross-layer
///   clef offset refinement (`Layer::GetCrossStaffClefLocOffset`) are
///   deferred; the default staff location is used instead.
/// - `MRest::GetOptimalLayerLocation` (mrest.cpp) is ported (see
///   `_mRestOptimalLayerLocation` below), using a simplified full-measure
///   stand-in for `Layer::GetLayerElementsForTimeSpanOf` (see
///   `_fullMeasureLayerElements`) since an `MRest` always spans the whole
///   measure. `Rest::GetOptimalLayerLocation` (rest.cpp) is a substantially
///   larger algorithm (margin/offset options, cross-staff adjustments) and
///   remains deferred; the default staff location is used for `Rest`.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart'
    show meiUnset, meiUnsetOct, MeiDuration;
import 'package:verovio_dart/src/core/bounding_box.dart' show BoundingBox;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/calc_functors.dart'
    show CalcStemFunctor;
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show FloatingPositioner, StaffAlignment, SystemAligner;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Horizontalalignment, Notationtype, Pitchname, Staffrel;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Layer, Measure, Note, Rest, Score, Staff;
import 'package:verovio_dart/src/model/beam_segment.dart' show BeamSpanSegment;
import 'package:verovio_dart/src/model/control_elements_gen.dart'
    show BeamSpan, Octave;
import 'package:verovio_dart/src/model/doc.dart' show Doc, Page;
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart'
    show DurationInterface;
import 'package:verovio_dart/src/model/interfaces/pitch_interface.dart'
    show PitchInterface;
import 'package:verovio_dart/src/model/interfaces/position_interface.dart'
    show PositionInterface;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show
        Accid,
        Artic,
        Beam,
        Chord,
        Custos,
        Dot,
        MRest,
        MSpace,
        Nc,
        Space,
        Syllable,
        TabDurSym,
        TupletBracket,
        Verse;
import 'package:verovio_dart/src/model/misc_elements_gen.dart'
    show Div, Fig, Rend, Svg;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef, StaffDef;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/model/text_elements.dart'
    show RunningElement, TextElement;
import 'package:verovio_dart/src/model/floating_object.dart'
    show FloatingObject;

// ---------------------------------------------------------------------------
// Pitch position helpers
// ---------------------------------------------------------------------------

/// Mirrors `Staff::CalcPitchPosYRel`: the yRel of a loc on the staff.
int calcPitchPosYRel(Staff staff, Doc doc, int loc) {
  // The staff loc offset is based on the number of lines: 0 with 1 line,
  // 2 with 2, etc.
  final int staffLocOffset = (staff.drawingLines - 1) * 2;
  return (loc - staffLocOffset) * doc.getDrawingUnit(staff.drawingStaffSize);
}

/// Mirrors the `CHORD`/`NOTE`/`CUSTOS` branches of
/// `PitchInterface::CalcLoc(const LayerElement*, const Layer*, const
/// LayerElement*, bool)` (pitchinterface.cpp:143). Used by
/// [_mRestOptimalLayerLocation] below to compute the loc of a colliding
/// element in the *other* layer, as seen from [layer] (the layer whose
/// optimal mRest location is being computed) — not from the element's own
/// layer, which is why the [layer] parameter is threaded through explicitly.
///
/// Deviation: `Layer::GetCrossStaffClefLocOffset` (the branch taken when
/// [element]'s own layer differs from [layer]) only ever changes the offset
/// for a cross-staff element (`element->m_crossStaff`); cross-staff notes are
/// out of scope here (mirroring the `note.crossStaff`-only special case
/// already called out for chords elsewhere in this file), so this always
/// calls `layer.getClefLocOffset(crossStaffElement)` directly.
int _calcLocForElement(LayerElement element, Layer layer,
    LayerElement crossStaffElement, bool topChordNote) {
  if (element is Chord) {
    final Note? note =
        topChordNote ? element.getTopNote() : element.getBottomNote();
    if (note == null) return 0;
    return _calcLocForElement(note, layer, crossStaffElement, topChordNote);
  } else if (element is Note) {
    if (element.hasLoc) return element.loc!;
    if (element.pname != null &&
        (element.oct != null || element.hasOctDefault)) {
      final int offset = layer.getClefLocOffset(crossStaffElement);
      final int oct = element.oct ?? element.octDefault;
      return PitchInterface.calcLoc(element.pname!, oct, offset);
    }
    return 0;
  } else if (element is Custos) {
    if (element.hasLoc) return element.loc!;
    return PitchInterface.calcLoc(element.pname ?? Pitchname.none,
        element.oct ?? 0, layer.getClefLocOffset(crossStaffElement));
  }
  return 0;
}

/// Simplified mirror of `Layer::GetLayerElementsForTimeSpanOf` /
/// `LayerElementsInTimeSpanFunctor::VisitLayerElement`
/// (findlayerelementsfunctor.cpp) for the one case [_mRestOptimalLayerLocation]
/// ever needs it for: an `MRest` spans the *entire* measure, so the query
/// window is always [0, measure duration) and every qualifying element of
/// [otherLayer] collides with it. Rather than porting the general
/// `MeasureAligner`-driven time-span functor (not ported anywhere yet — see
/// `adjust_beams.dart`'s `_layerElementsForTimeSpanOf`, which stubs it to an
/// empty list for the same reason), this walks [otherLayer]'s subtree
/// directly, applying the same element filters as the C++ functor:
/// scoreDef-attached elements and `@sameas` links are skipped, `MRest`
/// contributes itself without recursing, containers without a
/// `DurationInterface` (beam, tuplet, …) are skipped but still descended
/// into, and a `Chord`'s child notes are never visited once the chord itself
/// is recorded.
List<LayerElement> _fullMeasureLayerElements(Layer otherLayer) {
  final List<LayerElement> result = [];

  void walk(Object node) {
    for (final Object child in node.children) {
      if (child is! LayerElement) continue;
      if (child.isScoreDefElement) continue;
      if (child.hasSameasLink) continue;
      if (child is MRest) {
        result.add(child);
        continue;
      }
      final bool hasDuration = child is DurationInterface;
      final bool isSpaceLike = child is MSpace || child is Space;
      if (!hasDuration || isSpaceLike) {
        walk(child);
        continue;
      }
      if (child is Note) {
        final Object? chordAncestor = child.getFirstAncestor(ClassId.chord);
        if (chordAncestor != null && result.contains(chordAncestor)) continue;
      }
      result.add(child);
      if (child is Chord) continue;
      walk(child);
    }
  }

  walk(otherLayer);
  return result;
}

/// Mirrors `MRest::GetOptimalLayerLocation` (mrest.cpp). Only handles the
/// 2-layer case, exactly like the C++ (3+ layers "are much more complex to
/// solve" per the original comment and fall back to [defaultLocation]).
int _mRestOptimalLayerLocation(MRest mRest, Layer layer, int defaultLocation) {
  final Staff? parentStaff = mRest.getFirstAncestor(ClassId.staff) as Staff?;
  if (parentStaff == null) return defaultLocation;

  if (parentStaff.getChildCount(ClassId.layer) != 2) return defaultLocation;

  final List<Layer> layers = parentStaff
      .findAllDescendantsByType(ClassId.layer,
          continueDepthSearchForMatches: false)
      .cast<Layer>();
  if (layers.length != 2) return defaultLocation;

  final bool isTopLayer = layers.first.n == layer.n;
  final Layer otherLayer = isTopLayer ? layers.last : layers.first;

  final List<LayerElement> collidingElements =
      _fullMeasureLayerElements(otherLayer);

  final List<int> locations = [];
  for (final LayerElement element in collidingElements) {
    if (element is Chord || element is Note) {
      locations.add(_calcLocForElement(element, layer, element, isTopLayer));
    } else if (element is Rest) {
      locations.add(element.drawingLoc);
    } else if (element is MRest) {
      locations.add(4);
    }
  }
  // if there are no other elements - just return default location
  if (locations.isEmpty) return defaultLocation;

  final int locAdjust = isTopLayer ? 4 : -3;
  int extremePoint = isTopLayer
      ? locations.reduce((a, b) => a > b ? a : b)
      : locations.reduce((a, b) => a < b ? a : b);
  extremePoint += locAdjust;
  if (extremePoint % 2 != 0) {
    extremePoint += isTopLayer ? 1 : -1;
  }
  // Make sure that lower layer don't go above centre, and vice versa for
  // upper layer. Hardcoded, so for the time being this is going to properly
  // adjust mRests only on the 5-line staves.
  if (isTopLayer && (extremePoint < 6)) {
    extremePoint = 6;
  } else if (!isTopLayer && (extremePoint > 4)) {
    extremePoint = 4;
  }

  return extremePoint;
}

// Deviation fixed 2026-09-01 (fidelidade loop 08): this used to be a private
// `_clefLocOffset(layerY, staffY)` helper that only ever looked at
// `layerY.staffDefClef` (the transient "redraw" clef) or the staffDef's
// ambient `getCurrentClef()`, exactly like `Layer::GetClef`/`GetClefLocOffset`
// do when passed a `null` test element. It never did the backward scan for
// an inline `<clef>` that precedes the specific element within the same
// layer (`Layer::GetClef(test)`, layer.cpp:234, walking
// `GetListFirstBackward(test, CLEF)`) — mirrored by [Layer.getClefLocOffset]
// itself in `basic_elements.dart`. A mid-measure clef change (e.g.
// `<rest/><rest/><clef/><note/>` in one layer) was therefore invisible to
// pitch position / stem direction calc for every element after it, and
// everything downstream (`CalcStemFunctor::VisitNote`,
// calcstemfunctor.cpp:271-276) used
// the *old* clef's staff-center comparison, flipping stem direction (and
// therefore the flag glyph, E240 vs E241, and articulation placement) for
// notes following an inline clef change. Call sites now go straight to
// `layerY.getClefLocOffset(layerElementY)`, matching
// `layer->GetClefLocOffset(layerElementY)` (calcalignmentpitchposfunctor.cpp:
// 130, 163) and the `PitchInterface::CalcLoc(note, layer, crossStaffElement)`
// overload (pitchinterface.cpp:161) used for notes.

/// Headless replacement for `ObjectListInterface::GetAtPos`: returns the last
/// layer element of [layer] at or before [x].
LayerElement? _layerElementAtPos(Layer layer, int x) {
  LayerElement? result;
  final List<Object> objects =
      layer.findAllDescendantsByType(ClassId.layerElement, deepness: 2);
  for (final Object object in objects) {
    if (object is! LayerElement) continue;
    if (object.getDrawingX() > x) break;
    result = object;
  }
  return result;
}

// ---------------------------------------------------------------------------
// ResetVerticalAlignmentFunctor (mirrors resetfunctor.cpp)
// ---------------------------------------------------------------------------

/// Reset the vertical alignment before a new layout pass (mirrors
/// `vrv::ResetVerticalAlignmentFunctor`).
class ResetVerticalAlignmentFunctor extends Functor {
  @override
  FunctorCode visitArtic(Artic artic) {
    // Call parent one too.
    visitLayerElement(artic);

    artic.startSlurPositioners.clear();
    artic.endSlurPositioners.clear();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitFloatingObject(FloatingObject floatingObject) {
    floatingObject.currentPositioner = null;
    floatingObject.maxDrawingYRel = -0x7FFFFFFF;
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    // Nothing to do since drawingYRel is reset in
    // ResetHorizontalAlignmentFunctor and set in CalcAlignmentPitchPosFunctor.
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitOctave(Octave octave) {
    visitFloatingObject(octave);
    // TODO(phase-6): Octave::ResetDrawingExtenderX arrives with extenders.
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    staff.setAlignment(null);
    staff.clearLedgerLines();
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    system.setDrawingYRel(0);

    system.systemAligner.reset();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTextElement(TextElement textElement) {
    // Deviation: the Dart TextElement does not carry drawing x/y offsets
    // (the text element hierarchy is not a LayerElement subclass in this
    // port); nothing to reset.
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTupletBracket(TupletBracket tupletBracket) {
    visitLayerElement(tupletBracket);

    tupletBracket.drawingYRelLeft = 0;
    tupletBracket.drawingYRelRight = 0;

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// AlignVerticallyFunctor (mirrors alignfunctor.cpp)
// ---------------------------------------------------------------------------

/// This class vertically aligns the content of a page (mirrors
/// `vrv::AlignVerticallyFunctor`).
///
/// For each staff instantiate its StaffAlignment.
class AlignVerticallyFunctor extends DocFunctor {
  AlignVerticallyFunctor(super.doc);

  /// The systemAligner (mirrors `m_systemAligner`).
  SystemAligner? _systemAligner;

  /// The staff index (mirrors `m_staffIdx`).
  int _staffIdx = 0;

  /// The staffN (mirrors `m_staffN`).
  int _staffN = 0;

  /// The cumulated shift for the default alignment (mirrors
  /// `m_cumulatedShift`).
  int _cumulatedShift = 0;

  /// The page width for aligning running elements (mirrors `m_pageWidth`).
  int _pageWidth = 0;

  /// Port of `AlignVerticallyFunctor::VisitDiv` (alignfunctor.cpp:503).
  @override
  FunctorCode visitDiv(Div div) {
    _systemAligner?.getBottomAlignment()?.setYRel(-div.getTotalHeight(doc));

    _pageWidth = div.getTotalWidth(doc);

    return FunctorCode.continue_;
  }

  /// Port of `AlignVerticallyFunctor::VisitFig` (alignfunctor.cpp:596).
  @override
  FunctorCode visitFig(Fig fig) {
    final Object? svgObj = fig.findDescendantByType(ClassId.svg);
    final Svg? svg = svgObj is Svg ? svgObj : null;
    final int width = svg != null ? svg.getWidth() : 0;

    final Horizontalalignment? halign = fig.halign;
    if (halign == Horizontalalignment.right) {
      fig.setDrawingXRel(_pageWidth - width);
    } else if (halign == Horizontalalignment.center) {
      fig.setDrawingXRel((_pageWidth - width) ~/ 2);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    // We also need to reset the staff index.
    _staffIdx = 0;

    return FunctorCode.continue_;
  }

  /// Port of `AlignVerticallyFunctor::VisitPageEnd` (alignfunctor.cpp:619).
  @override
  FunctorCode visitPageEnd(Page page) {
    _cumulatedShift = 0;

    final Object? headerObj = page.getHeader();
    if (headerObj is RunningElement) {
      headerObj.setDrawingPage(page);
      headerObj.setDrawingYRel(0);
      headerObj.process(this);
    }
    final Object? footerObj = page.getFooter();
    if (footerObj is RunningElement) {
      footerObj.setDrawingPage(page);
      footerObj.setDrawingYRel(0);
      footerObj.process(this);
    }

    return FunctorCode.continue_;
  }

  /// Port of `AlignVerticallyFunctor::VisitRend` (alignfunctor.cpp:640).
  @override
  FunctorCode visitRend(Rend rend) {
    if (rend.getFirstAncestorInRange(
            ClassId.textLayoutElement, ClassId.textLayoutElementMax) ==
        null) {
      return FunctorCode.siblings;
    }

    final Horizontalalignment? halign = rend.halign;
    if (halign != null) {
      if (halign == Horizontalalignment.right) {
        rend.setDrawingXRel(_pageWidth);
      } else if (halign == Horizontalalignment.center) {
        rend.setDrawingXRel(_pageWidth ~/ 2);
      }
    }

    return FunctorCode.siblings;
  }

  /// Port of `AlignVerticallyFunctor::VisitRunningElement` (alignfunctor.cpp:655).
  @override
  FunctorCode visitRunningElement(RunningElement runningElement) {
    visitTextLayoutElement(runningElement);

    _pageWidth = runningElement.getTotalWidth(doc);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    if (staff.isHidden) return FunctorCode.siblings;

    _staffN = staff.n ?? 0;

    // This gets (or creates) the staff alignment.
    final StaffAlignment? alignment =
        _systemAligner!.getStaffAlignment(_staffIdx, staff, doc);
    assert(alignment != null);
    staff.setAlignment(alignment);

    // Add verse numbers from the spanning elements (mirrors the
    // timeSpanningElements find_if lookups).
    for (final Object element in staff.timeSpanningElements) {
      if (element.classId == ClassId.verse) {
        final Verse verse = element as Verse;
        alignment!.addVerseN(verse.n ?? 1, verse.place ?? Staffrel.none);
        break;
      }
    }
    for (final Object element in staff.timeSpanningElements) {
      if (element.classId == ClassId.syl) {
        final Object? verseObject = element.getFirstAncestor(ClassId.verse);
        if (verseObject is Verse) {
          final int verseNumber = verseObject.n ?? 1;
          final Staffrel versePlace = verseObject.place ?? Staffrel.none;
          final bool verseCollapse = doc.getOptions().lyricVerseCollapse.value;
          if ((versePlace == Staffrel.above) &&
              alignment!.getVersePositionAbove(verseNumber, verseCollapse) ==
                  0) {
            alignment.addVerseN(verseNumber, versePlace);
          }
          if ((versePlace != Staffrel.above) &&
              alignment!.getVersePositionBelow(verseNumber, verseCollapse) ==
                  0) {
            alignment.addVerseN(verseNumber, versePlace);
          }
        }
        break;
      }
    }

    // For next staff.
    ++_staffIdx;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaffAlignmentEnd(StaffAlignment staffAlignment) {
    _cumulatedShift += staffAlignment.getMinimumSpacing(doc);

    staffAlignment.setYRel(-_cumulatedShift);

    _cumulatedShift += staffAlignment.getStaffHeight();
    ++_staffIdx;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSyllable(Syllable syllable) {
    if (syllable.findDescendantByType(ClassId.syl) == null) {
      return FunctorCode.continue_;
    }

    final StaffAlignment? alignment =
        _systemAligner?.getStaffAlignmentForStaffN(_staffN);
    if (alignment == null) return FunctorCode.continue_;
    // Current limitation of only one syl (verse n) by syllable.
    alignment.addVerseN(1, Staffrel.below);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    _systemAligner = system.systemAligner;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemEnd(System system) {
    _cumulatedShift = 0;
    _staffIdx = 0;

    // StaffAlignment are added following the staff element in the measures.
    // We can now reorder them according to the scoreDef order.
    if (system.drawingScoreDef != null) {
      system.systemAligner.reorder(system.drawingScoreDef!.getStaffNs());
    }

    system.systemAligner.process(this);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitVerse(Verse verse) {
    final StaffAlignment? alignment =
        _systemAligner?.getStaffAlignmentForStaffN(_staffN);

    if (alignment == null) return FunctorCode.continue_;

    // Add the number count.
    alignment.addVerseN(verse.n ?? 1, verse.place ?? Staffrel.none);

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// CalcAlignmentPitchPosFunctor
// ---------------------------------------------------------------------------

/// Set the pitch / pos alignment of the notes, rests, etc. (mirrors
/// `vrv::CalcAlignmentPitchPosFunctor`).
class CalcAlignmentPitchPosFunctor extends DocFunctor {
  CalcAlignmentPitchPosFunctor(super.doc);

  /// The current default octave (mirrors `m_octDefault`).
  int octDefault = meiUnsetOct;

  /// The default octaves per staffN (mirrors `m_octDefaultForStaffN`).
  final Map<int, int> octDefaultForStaffN = {};

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    LayerElement layerElementY = layerElement;
    Staff staffY = layerElement.getAncestorStaffLayout();
    Layer layerY = layerElement.getFirstAncestor(ClassId.layer) as Layer;

    final PitchInterface? pitchInterface =
        layerElement is PitchInterface ? layerElement as PitchInterface : null;
    if (pitchInterface != null) {
      pitchInterface.setOctDefault(octDefault);
      // Check if there is an octave default for the staff - ignore cross-staff
      // for this and use staffY.
      final int staffN = staffY.n ?? meiUnset;
      if (octDefaultForStaffN.containsKey(staffN)) {
        pitchInterface.setOctDefault(octDefaultForStaffN[staffN]!);
      }
    }

    if (layerElement.crossStaff is Staff && layerElement.crossLayer is Layer) {
      layerElementY = _layerElementAtPos(
              layerElement.crossLayer as Layer, layerElement.getDrawingX()) ??
          layerElement;
      staffY = layerElement.crossStaff as Staff;
      layerY = layerElement.crossLayer as Layer;
    }

    final int clefLocOffset = layerY.getClefLocOffset(layerElementY);

    // Adjust drawingYRel for notes and rests, etc.
    if (layerElement.classId == ClassId.accid) {
      final Accid accid = layerElement as Accid;
      if (accid.getFirstAncestor(ClassId.note) == null &&
          accid.getFirstAncestor(ClassId.custos) == null &&
          !doc.isNeumeLines()) {
        // Do something for accid that are not children of a note - e.g.,
        // mensural. Skip for neume-lines mode as accid doesn't have a pitch
        // in this case.
        final PositionInterface position = accid as PositionInterface;
        accid.setDrawingYRel(calcPitchPosYRel(staffY, doc,
            position.calcDrawingLoc(clefLocOffset: clefLocOffset)));
        accid.drawingLoc = position.drawingLoc;
      }
      // Override if the staff position is set explicitly.
      if (accid.hasPloc && accid.hasOloc) {
        accid.drawingLoc =
            PitchInterface.calcLoc(accid.ploc!, accid.oloc!, clefLocOffset);
        accid.setDrawingYRel(calcPitchPosYRel(staffY, doc, accid.drawingLoc));
      } else if (accid.hasLoc) {
        accid.drawingLoc = accid.loc!;
        accid.setDrawingYRel(calcPitchPosYRel(staffY, doc, accid.loc!));
      }
    } else if (layerElement.classId == ClassId.chord) {
      // The y position is set to the top note one.
      final Chord chord = layerElement as Chord;
      final List<Object> childList = chord.getList();
      final int loc = childList.isEmpty
          ? 0
          : _calcEventLoc(
              childList.last as Note, layerY, staffY, layerElementY);
      layerElement.setDrawingYRel(calcPitchPosYRel(staffY, doc, loc));
    } else if (layerElement.classId == ClassId.dot) {
      final Dot dot = layerElement as Dot;
      final PositionInterface position = dot as PositionInterface;
      dot.setDrawingYRel(calcPitchPosYRel(
          staffY, doc, position.calcDrawingLoc(clefLocOffset: clefLocOffset)));
    } else if (layerElement.classId == ClassId.custos) {
      final Custos custos = layerElement as Custos;
      int loc = 0;
      if (custos.hasPname && (custos.hasOct || custos.hasOctDefault)) {
        loc = PitchInterface.calcLoc(custos.pname!,
            custos.hasOct ? custos.oct! : custos.octDefault, clefLocOffset);
      }
      final int yRel = calcPitchPosYRel(staffY, doc, loc);
      (custos as PositionInterface).drawingLoc = loc;
      custos.setDrawingYRel(yRel);
    } else if (layerElement.classId == ClassId.note) {
      final Note note = layerElement as Note;
      final Object? chord = note.isChordTone();
      final int loc = _calcEventLoc(note, layerY, staffY, layerElementY);
      int yRel = calcPitchPosYRel(staffY, doc, loc);
      // Make it relative to the top note one (see above) but not for
      // cross-staff notes in chords.
      if (chord != null && note.crossStaff == null) {
        yRel -= (chord as LayerElement).drawingYRel;
      }
      (note as PositionInterface).drawingLoc = loc;
      note.setDrawingYRel(yRel);
    } else if (layerElement.classId == ClassId.mRest) {
      final MRest mRest = layerElement as MRest;
      int loc = 0;
      if (mRest.hasPloc && mRest.hasOloc) {
        loc = PitchInterface.calcLoc(mRest.ploc!, mRest.oloc!, clefLocOffset);
      } else if (mRest.hasLoc) {
        loc = mRest.loc!;
      } else {
        // Automatically calculate rest position: set the default location to
        // the middle of the staff.
        loc = staffY.drawingLines - 1;
        if (loc % 2 != 0) --loc;
        if (staffY.drawingLines > 1) loc += 2;
        // Limitation: GetLayerCount does not take into account editorial
        // markup (calcalignmentpitchposfunctor.cpp:141-142, kept as-is here).
        if (staffY.getChildCount(ClassId.layer) > 1) {
          loc = _mRestOptimalLayerLocation(mRest, layerY, loc);
        }
      }
      mRest.drawingLoc = loc;
      mRest.setDrawingYRel(calcPitchPosYRel(staffY, doc, loc));
    } else if (layerElement.isAny(const {ClassId.rest, ClassId.space})) {
      final DurationInterface durInterface = layerElement as DurationInterface;
      final Rest? rest =
          layerElement.classId == ClassId.rest ? layerElement as Rest : null;
      int loc = meiUnset;
      if (rest != null) {
        if (rest.hasPloc && rest.hasOloc) {
          loc = PitchInterface.calcLoc(rest.ploc!, rest.oloc!, clefLocOffset);
        } else if (rest.hasLoc) {
          loc = rest.loc!;
        }
      }
      // Automatically calculate rest position.
      if (loc == meiUnset) {
        loc = 0;
        // Set default location to the middle of the staff.
        final Staff staff = layerElement.getAncestorStaffLayout();
        final MeiDuration dur = durInterface.dur ?? MeiDuration.none;
        loc = staff.drawingLines - 1;
        if ((dur.value < MeiDuration.dur4.value) && (loc % 2 != 0)) {
          --loc;
        }
        // Adjust special cases.
        if ((dur == MeiDuration.dur1) && (staff.drawingLines > 1)) {
          loc += 2;
        }
        if ((dur == MeiDuration.breve) && (staff.drawingLines < 2)) {
          loc -= 2;
        }

        // If within a beam, calculate the rest's height based on its
        // relationship to the notes that surround it.
        final Object? beam = layerElement.getFirstAncestor(ClassId.beam, 1);
        if (beam != null) {
          loc = _calcBeamRestLoc(beam, layerElement, durInterface, loc);
        }

        // Deviation: Rest::GetOptimalLayerLocation is deferred; the default
        // location is kept.
      }
      if (rest != null) {
        rest.drawingLoc = loc;
      }
      layerElement.setDrawingYRel(calcPitchPosYRel(staffY, doc, loc));
    } else if (layerElement.classId == ClassId.tabDurSym) {
      final TabDurSym tabDurSym = layerElement as TabDurSym;
      int yRel = 0;
      // Deviation: tablature staff variants (IsTabWithStemsOutside…) are
      // deferred with the tablature support.
      if (staffY.drawingNotationtype == Notationtype.tab) {
        yRel += doc.getDrawingUnit(staffY.drawingStaffSize);
      }
      tabDurSym.setDrawingYRel(yRel);
    } else if (layerElement.classId == ClassId.nc) {
      final Nc nc = layerElement as Nc;
      int loc = 0;
      if (nc.hasPname && nc.hasOct) {
        loc = PitchInterface.calcLoc(nc.pname!, nc.oct!, clefLocOffset);
      } else if (nc.hasLoc) {
        loc = nc.loc!;
      }
      final int yRel = calcPitchPosYRel(staffY, doc, loc);
      nc.drawingLoc = loc;
      nc.setDrawingYRel(yRel);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScore(Score score) {
    final ScoreDef? scoreDef = score.getScoreDef() as ScoreDef?;
    if (scoreDef != null) {
      scoreDef.process(this);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    octDefaultForStaffN.clear();
    octDefault = scoreDef.hasOctDefault ? scoreDef.octDefault! : meiUnsetOct;
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaffDef(StaffDef staffDef) {
    if (staffDef.hasOctDefault && staffDef.hasN) {
      octDefaultForStaffN[staffDef.n!] = staffDef.octDefault!;
    }
    return FunctorCode.siblings;
  }

  /// Mirrors `PitchInterface::CalcLoc(element, layer, sameas)` for notes:
  /// the @loc override first, then @pname / @oct with the clef offset.
  int _calcEventLoc(Note note, Layer layerY, Staff staffY,
      [LayerElement? layerElementY]) {
    if (note.hasLoc) return note.loc ?? 0;
    if (note.hasPname && (note.hasOct || note.hasOctDefault)) {
      final int offset = layerY.getClefLocOffset(layerElementY ?? note);
      // Deviation: the parentLayer != layer cross-staff clef offset
      // refinement (GetCrossStaffClefLocOffset) is deferred.
      final int oct = note.hasOct ? note.oct! : note.octDefault;
      return PitchInterface.calcLoc(note.pname!, oct, offset);
    }
    return 0;
  }

  /// Mirrors the beam aware rest location adjustment of
  /// `CalcAlignmentPitchPosFunctor::VisitLayerElement`.
  int _calcBeamRestLoc(Object beam, LayerElement layerElement,
      DurationInterface durInterface, int initialLoc) {
    final Beam beamObj = beam as Beam;
    final List<Object> beamList = beamObj.getList();
    final int restIndex = beamObj.getListIndex(layerElement);
    // Deviation: when the rest is not found in the (cached) filtered beam
    // list, e.g., after the object tree has been restructured by the cast
    // off, keep the default location instead of crashing.
    if (restIndex < 0 || restIndex >= beamList.length) {
      return initialLoc;
    }

    int leftLoc = initialLoc;
    for (int i = restIndex; i >= 0; --i) {
      final Object object = beamList[i];
      if (object.classId == ClassId.note) {
        leftLoc = (object as LayerElement).calcDrawingLocHeadless();
        break;
      } else if (object.classId == ClassId.chord) {
        leftLoc = (_chordExtremumLoc(object, true) +
                _chordExtremumLoc(object, false)) ~/
            2;
        break;
      }
    }

    int rightLoc = initialLoc;
    for (int i = restIndex; i < beamList.length; ++i) {
      final Object object = beamList[i];
      if (object.classId == ClassId.note) {
        rightLoc = (object as LayerElement).calcDrawingLocHeadless();
        break;
      } else if (object.classId == ClassId.chord) {
        rightLoc = (_chordExtremumLoc(object, true) +
                _chordExtremumLoc(object, false)) ~/
            2;
        break;
      }
    }

    // With a rest or space at the first / last position, use the right /
    // left loc.
    if (restIndex == 0) {
      leftLoc = rightLoc;
      initialLoc = rightLoc;
    } else if (restIndex == beamList.length - 1) {
      rightLoc = leftLoc;
      initialLoc = leftLoc;
    }

    // Average the left note and right note's locations together to get our
    // rest location.
    final int locAvg = (rightLoc + leftLoc) ~/ 2;
    if ((locAvg - initialLoc).abs() > 3) {
      initialLoc = locAvg;
    }

    // Bottom aligned loc: where all of the rest's stems align to form a
    // straight line.
    int bottomAlignedLoc = initialLoc;
    if (durInterface.getActualDur() == MeiDuration.dur8) bottomAlignedLoc -= 2;

    // Top aligned loc: where all of the tops of the rests align.
    int topAlignedLoc = initialLoc;
    if (durInterface.getActualDur() == MeiDuration.dur32) topAlignedLoc += 2;

    const int topOfStaffLoc = 10;
    const int bottomOfStaffLoc = -4;

    // Move the extremas towards center a little for aesthetic reasons.
    final bool restAboveStaff = bottomAlignedLoc >= topOfStaffLoc;
    final bool restBelowStaff = topAlignedLoc <= bottomOfStaffLoc;
    if (restAboveStaff) {
      initialLoc--;
    } else if (restBelowStaff) {
      initialLoc++;
    }

    // If loc is odd, we need to offset it to be even so that the dots do not
    // collide with the staff lines or ledger lines.
    if (initialLoc % 2 != 0) {
      if (initialLoc > 4) {
        initialLoc--;
      } else {
        initialLoc++;
      }
    }

    return initialLoc;
  }

  /// Top / bottom loc of a chord (mirrors `PitchInterface::CalcLoc(chord, …,
  /// top)` using the sorted note list).
  int _chordExtremumLoc(Object chordObject, bool top) {
    final Chord chord = chordObject as Chord;
    final List<Object> childList = chord.getList();
    if (childList.isEmpty) return 0;
    final Note note = (top ? childList.last : childList.first) as Note;
    return note.calcDrawingLocHeadless();
  }
}

// ---------------------------------------------------------------------------
// AdjustYPosFunctor (mirrors adjustyposfunctor.cpp)
// ---------------------------------------------------------------------------

/// Adjust the Y position of each staff alignment (mirrors
/// `vrv::AdjustYPosFunctor`).
class AdjustYPosFunctor extends DocFunctor {
  AdjustYPosFunctor(super.doc);

  /// The cumulated shift (mirrors `m_cumulatedShift`).
  int _cumulatedShift = 0;

  @override
  FunctorCode visitDiv(Div div) {
    // Mirrors Div::AdjustRunningElementYPos; running element adjustments
    // arrive with their own phase.
    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitStaffAlignment(StaffAlignment staffAlignment) {
    final int defaultSpacing = staffAlignment.getMinimumSpacing(doc);
    int minSpacing = staffAlignment.calcMinimumRequiredSpacing(doc);
    minSpacing = math.max(staffAlignment.getRequestedSpacing(), minSpacing);

    if (minSpacing > defaultSpacing) {
      _cumulatedShift += minSpacing - defaultSpacing;
    }

    staffAlignment.setYRel(staffAlignment.getYRel() - _cumulatedShift);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    // We need to call this explicitly because changing the YRel of the
    // StaffAligner (below in the functor) will not trigger it.
    system.resetCachedDrawingY();

    _cumulatedShift = 0;

    system.systemAligner.process(this);

    return FunctorCode.continue_;
  }
}

/// Adjust the cross staff content after the Y position adjustment (mirrors
/// `vrv::AdjustCrossStaffYPosFunctor`).
class AdjustCrossStaffYPosFunctor extends DocFunctor {
  AdjustCrossStaffYPosFunctor(super.doc);

  @override
  FunctorCode visitSystem(System system) {
    final List<Object> drawingList = system.getDrawingList();
    for (final Object item in drawingList) {
      if (item.classId == ClassId.beamSpan) {
        final BeamSpan beamSpan = item as BeamSpan;
        final BeamSpanSegment? segment = beamSpan.getSegmentForSystem(system);
        if (segment != null) {
          final Layer? layer = segment.layer as Layer?;
          final Staff? staff = segment.staff as Staff?;
          if (layer != null && staff != null) {
            segment.calcBeam(layer, staff, doc, beamSpan, beamSpan.drawingPlace);
          }
        }
      }
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitChord(Chord chord) {
    if (!hasCrossStaff(chord)) return FunctorCode.siblings;

    // For cross staff chords we need to re-calculate the stem because the
    // staff position might have changed.
    final calcAlignmentPitchPos = CalcAlignmentPitchPosFunctor(doc);
    chord.process(calcAlignmentPitchPos);

    final calcStem = CalcStemFunctor(doc);
    chord.process(calcStem);

    return FunctorCode.siblings;
  }

  /// Mirrors `Chord::HasCrossStaff` (the chord itself or one of its notes has
  /// a cross-staff situation).
  static bool hasCrossStaff(Chord chord) {
    if (chord.crossStaff != null) return true;
    for (final Object object
        in chord.findAllDescendantsByType(ClassId.note, deepness: 1)) {
      if ((object as Note).crossStaff != null) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// AdjustStaffOverlapFunctor (mirrors adjuststaffoverlapfunctor.cpp)
// ---------------------------------------------------------------------------

/// Adjust the overlap of the staff alignments by looking at the overflow
/// bounding boxes (mirrors `vrv::AdjustStaffOverlapFunctor`).
///
/// Without the rendered bounding boxes the overflow arrays stay empty and
/// the overlap is driven by the scoreDef clef overflows and the requested
/// spacing only.
class AdjustStaffOverlapFunctor extends DocFunctor {
  AdjustStaffOverlapFunctor(super.doc);

  StaffAlignment? _previous;

  @override
  FunctorCode visitStaffAlignment(StaffAlignment staffAlignment) {
    // This is the first alignment.
    if (_previous == null) {
      _previous = staffAlignment;
      return FunctorCode.siblings;
    }

    final int spacing = math.max(
        _previous!.getOverflowBelow(), staffAlignment.getOverflowAbove());

    // Calculate the overlap for scoreDef clefs.
    final int overflowBelow = _previous!.getScoreDefClefOverflowBelow();
    final int overflowAbove = staffAlignment.getScoreDefClefOverflowAbove();
    if (spacing < (overflowBelow + overflowAbove)) {
      staffAlignment.setOverlap((overflowBelow + overflowAbove) - spacing);
    }

    // TODO(phase-6): AdjustBracketGroupSpacing arrives with the resources
    // phase (requires Doc glyph heights).

    // Calculate the requested spacing.
    final int currentStaffDistance = _previous!.getYRel() -
        _previous!.getStaffHeight() -
        staffAlignment.getYRel();
    final int requestedSpace = math.max(staffAlignment.getRequestedSpaceAbove(),
        _previous!.getRequestedSpaceBelow());
    if (requestedSpace > 0) {
      staffAlignment.setRequestedSpacing(currentStaffDistance + requestedSpace);
    }

    // This is the bottom alignment (or something is wrong) - this is all we
    // need to do.
    if (staffAlignment.getStaff() == null) {
      return FunctorCode.stop;
    }

    final int staffSize = staffAlignment.getStaffSize();
    final int drawingUnit = doc.getDrawingUnit(staffSize);

    // Go through all the elements of the top staff that have an overflow
    // below.
    for (final BoundingBox bboxBelow in _previous!.getBBoxesBelow()) {
      final List<BoundingBox> bboxesAbove = staffAlignment.getBBoxesAbove();
      for (int i = 0; i < bboxesAbove.length; ++i) {
        final BoundingBox elem = bboxesAbove[i];
        final bool overlaps;
        if (bboxBelow is FloatingPositioner) {
          final object = bboxBelow.getObject()!;
          if (object.isAny(const {ClassId.dir, ClassId.dynam, ClassId.tempo}) &&
              object.isExtenderElement) {
            overlaps =
                bboxBelow.horizontalContentOverlap(elem, drawingUnit * 4) ||
                    bboxBelow.verticalContentOverlap(elem);
          } else {
            overlaps = bboxBelow.horizontalContentOverlap(elem);
          }
        } else {
          overlaps = bboxBelow.horizontalContentOverlap(elem);
        }
        if (!overlaps) continue;
        // Calculate the vertical overlap and see if this is more than the
        // expected space.
        final int bboxOverflowBelow = _previous!.calcOverflowBelow(bboxBelow);
        final int bboxOverflowAbove =
            staffAlignment.calcOverflowAbove(bboxesAbove[i]);
        int minSpaceBetween = 0;
        if ((bboxBelow.isClass(ClassId.artic) &&
                elem.isAny(const {ClassId.artic, ClassId.note})) ||
            (bboxBelow.isClass(ClassId.note) && elem.isClass(ClassId.artic))) {
          minSpaceBetween = drawingUnit;
        }
        if (spacing <
            (bboxOverflowBelow + bboxOverflowAbove + minSpaceBetween)) {
          staffAlignment.setOverlap(
              (bboxOverflowBelow + bboxOverflowAbove + minSpaceBetween) -
                  spacing);
        }
      }
    }

    _previous = staffAlignment;

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    _previous = null;
    system.systemAligner.process(this);
    return FunctorCode.siblings;
  }
}

// ---------------------------------------------------------------------------
// AlignSystemsFunctor (mirrors alignfunctor.cpp)
// ---------------------------------------------------------------------------

/// This class aligns the systems by adjusting the drawingYRel position
/// looking at the SystemAligner (mirrors `vrv::AlignSystemsFunctor`).
class AlignSystemsFunctor extends DocFunctor {
  AlignSystemsFunctor(super.doc);

  /// The cumulated shift (mirrors `m_shift`).
  int _shift = 0;

  /// The system margin (mirrors `m_systemSpacing`).
  int _systemSpacing = 0;

  /// The sum of justification factors per page (mirrors
  /// `m_justificationSum`).
  double _justificationSum = 0;

  void setShift(int shift) => _shift = shift;
  void setSystemSpacing(int spacing) => _systemSpacing = spacing;

  /// Port of `AlignSystemsFunctor::VisitPage` (alignfunctor.cpp:783).
  @override
  FunctorCode visitPage(Page page) {
    _justificationSum = 0;

    final Object? headerObj = page.getHeader();
    if (headerObj is RunningElement) {
      headerObj.setDrawingYRel(_shift);
      final int headerHeight = headerObj.getTotalHeight(doc);
      if (headerHeight > 0) {
        _shift -= headerHeight;
      }
    }
    return FunctorCode.continue_;
  }

  /// Port of `AlignSystemsFunctor::VisitPageEnd` (alignfunctor.cpp:797).
  @override
  FunctorCode visitPageEnd(Page page) {
    page.drawingJustifiableHeight = _shift;
    page.justificationSum = _justificationSum;

    final Object? footerObj = page.getFooter();
    if (footerObj is RunningElement) {
      page.drawingJustifiableHeight -= footerObj.getTotalHeight(doc);

      if (doc.getOptions().adjustPageHeight.value) {
        if (page.childCount > 0) {
          final last = page.getLast(ClassId.system) as System?;
          if (last != null) {
            final int unit = doc.getDrawingUnit(100);
            final int topMargin =
                (doc.getOptions().topMarginPgFooter.value * unit).toInt();
            footerObj.setDrawingYRel(
                last.getDrawingYRel() - last.getHeight() - topMargin);
          }
        }
      } else {
        footerObj.setDrawingYRel(footerObj.getContentHeight());
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    final SystemAligner systemAligner = system.systemAligner;
    assert(systemAligner.getBottomAlignment() != null);

    // No spacing for the first system.
    if (!system.isFirstInPage()) {
      final int unit = doc.getDrawingUnit(100);
      _shift -= math.max(_systemSpacing, 2 * unit);
    }

    system.setDrawingYRel(_shift);

    _shift += systemAligner.getBottomAlignment()!.getYRel();

    _justificationSum += systemAligner.getJustificationSum(doc);
    if (system.isFirstInPage()) {
      // Remove extra system justification factor to get exactly
      // (systemsCount - 1) * justificationSystem.
      _justificationSum -= doc.getOptions().justificationSystem.value;
    }

    return FunctorCode.siblings;
  }
}
