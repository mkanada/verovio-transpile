/// Port of `layerelement.h/cpp` — base class for the layer elements
/// (notes, rests, clefs, beams…).
library;

import 'package:verovio_dart/src/core/attdef.dart'
    show meiUnset, MeiDuration;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/smufl.dart'
    show
        smuflE220Tremolo1,
        smuflE221Tremolo2,
        smuflE222Tremolo3,
        smuflE223Tremolo4,
        smuflE224Tremolo5,
        smuflE22ABuzzRoll,
        smuflE645VocalSprechgesang;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;
import 'package:verovio_dart/src/model/atts/atts_facsimile.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Notationtype, StaffrelBasic, Stemmodifier;
// Dart allows circular library imports, so `m_crossStaff` / `m_crossLayer` can
// carry the concrete types `layerelement.h` gives them.
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Layer, Measure, Note, Staff;
import 'package:verovio_dart/src/model/doc.dart' show Doc;
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Chord, FTrem;
import 'package:verovio_dart/src/model/atts/atts_cmn.dart' show AttGraced;
import 'package:verovio_dart/src/model/zone.dart' show Zone;
import 'package:verovio_dart/src/model/comparison.dart'
    show ClassIdsComparison, InterfaceComparison;
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show StemmedDrawingInterface;
import 'package:verovio_dart/src/model/interfaces/facsimile_interface.dart';
import 'package:verovio_dart/src/model/interfaces/linking_interface.dart';
import 'package:verovio_dart/src/model/object.dart';

/// Mirrors `vrv::LayerElement`.
class LayerElement extends Object
    with
        AttFacsimile,
        AttLinking,
        AttCoordX1,
        AttLabelled,
        AttTyped,
        FacsimileInterface,
        LinkingInterface {
  LayerElement([ClassId classId = ClassId.layerElement]) {
    _init(classId);
  }

  void _init(ClassId classId) {
    assignClassId(classId);
    reset();
  }

  @override
  String get className => '[MISSING]';

  @override
  void reset() {
    super.reset();
    coordX1 = null;
    type = null;
    label = null;

    // Drawing values (mirrors the C++ Reset(), layerelement.cpp:121-123).
    drawingFacsX = meiUnset;
    drawingFacsY = meiUnset;
    drawingXRel = 0;
    drawingYRel = 0;
    drawingCueSize = false;
    scoreDefRole = ElementScoreDefRole.none;

    // Cached horizontal-layout values (mirrors `m_cachedXRel`/`m_cachedYRel`
    // reset in `LayerElement::Reset`, layerelement.cpp:127-128).
    _cachedXRel = meiUnset;
    _cachedYRel = meiUnset;

    // Alignment pointers (mirrors the C++ Reset()).
    _alignment = null;
    _graceAlignment = null;
    _alignmentLayerN = meiUnset;
  }

  /// Return true if the element has to be aligned horizontally.
  ///
  /// Typically false for mRest, mRpt, etc. Overridden by subclasses.
  bool get hasToBeAligned => false;

  /// Return true if the element is part of a scoreDef or staffDef.
  @override
  bool get isScoreDefElement => false;

  /// Return true if the element is relative to the staff and not to its
  /// parent (e.g., syl or artic).
  bool get isRelativeToStaff => false;

  /// Return true if the element is a grace note or belongs to a graceGrp
  /// (mirrors `IsGraceNote`).
  ///
  /// The note-specific checks are done generically through attribute
  /// lookups to avoid circular imports with the concrete classes.
  bool isGraceNote() {
    // First, regardless of the type, check whether it's part of GRACEGRP.
    if (getFirstAncestor(ClassId.graceGrp) != null) return true;
    if (classId == ClassId.note) {
      // For a note, look at it or at the parent chord
      // (layerelement.cpp:177-182).
      final Object? chord = getFirstAncestor(ClassId.chord, maxChordDepth);
      return ((chord ?? this) as AttGraced).hasGrace;
    } else if (classId == ClassId.chord) {
      // Mirrors `Chord::HasGrace` through the @grace attribute mixin.
      return (this as AttGraced).hasGrace;
    } else if (classId == ClassId.tuplet) {
      // The C++ takes the *first* note/chord descendant and answers from it
      // (`FindDescendantByComparison`, layerelement.cpp:191), not "any of
      // them".
      final Object? child = findDescendantByComparison(
          ClassIdsComparison(const [ClassId.note, ClassId.chord]));
      if (child != null) return (child as LayerElement).isGraceNote();
    } else {
      // For accid, artic, etc.: look at the parent note / chord.
      final Object? note = getFirstAncestor(ClassId.note, maxAccidDepth);
      if (note != null) return (note as LayerElement).isGraceNote();
      final Object? chord = getFirstAncestor(ClassId.chord, maxAccidDepth);
      if (chord != null) return (chord as LayerElement).isGraceNote();
    }
    return false;
  }

  /// Mirrors `LayerElement::StemModToGlyph` (layerelement.cpp:1000).
  int stemModToGlyph(Stemmodifier stemMod) {
    switch (stemMod) {
      case Stemmodifier.n1slash:
        return smuflE220Tremolo1;
      case Stemmodifier.n2slash:
        return smuflE221Tremolo2;
      case Stemmodifier.n3slash:
        return smuflE222Tremolo3;
      case Stemmodifier.n4slash:
        return smuflE223Tremolo4;
      case Stemmodifier.n5slash:
        return smuflE224Tremolo5;
      case Stemmodifier.n6slash:
        return smuflE224Tremolo5;
      case Stemmodifier.sprech:
        return smuflE645VocalSprechgesang;
      case Stemmodifier.z:
        return smuflE22ABuzzRoll;
      default:
        return 0;
    }
  }

  /// Mirrors `LayerElement::GetDrawingRadius` (layerelement.cpp:599): half
  /// the width of the notehead glyph this element draws, or 0 for the classes
  /// that draw none.
  int getDrawingRadius(Doc doc, {bool isInLigature = false}) {
    if (!isAny(const {
      ClassId.chord,
      ClassId.nc,
      ClassId.note,
      ClassId.rest,
    })) {
      return 0;
    }

    int code = 0;
    MeiDuration dur = MeiDuration.dur4;
    final Staff staff = getFirstAncestor(ClassId.staff) as Staff;
    bool isMensuralDur = false;
    if (classId == ClassId.note) {
      final Note note = this as Note;
      dur = note.getDrawingDur();
      isMensuralDur = note.isMensuralDur;
      if (isMensuralDur && !isInLigature) {
        code = note.getMensuralNoteheadGlyph();
      } else {
        code = note.getNoteheadGlyph(dur);
      }
    } else if (classId == ClassId.chord) {
      final Chord chord = this as Chord;
      dur = chord.getActualDur();
      isMensuralDur = chord.isMensuralDur;
      if (dur == MeiDuration.breve) {
        code = 0xE0A1; // noteheadDoubleWholeSquare
      } else if (dur == MeiDuration.dur1) {
        code = 0xE0A2; // noteheadWhole
      } else if (dur == MeiDuration.dur2) {
        code = 0xE0A3; // noteheadHalf
      } else {
        code = 0xE0A4; // noteheadBlack
      }
    } else if (classId == ClassId.rest || classId == ClassId.nc) {
      code = 0xE0A4; // noteheadBlack
    }

    // Mensural note shorter than DURATION_breve
    if ((isMensuralDur && dur.value <= MeiDuration.breve.value) ||
        (dur == MeiDuration.dur1 && isInLigature)) {
      final int widthFactor = (dur == MeiDuration.maxima) ? 2 : 1;
      if (staff.drawingNotationtype == Notationtype.mensuralBlack) {
        return (widthFactor *
                doc.getDrawingBrevisWidth(staff.drawingStaffSize) *
                0.7)
            .toInt();
      }
      return widthFactor * doc.getDrawingBrevisWidth(staff.drawingStaffSize);
    }

    // The code should not be null at this stage. It can above but only with
    // mensural notation.
    assert(code != 0);

    return doc.getGlyphWidth(code, staff.drawingStaffSize, drawingCueSize) ~/ 2;
  }

  /// Mirrors `LayerElement::IsInLigature` (layerelement.cpp:204).
  bool isInLigature() {
    if (classId != ClassId.note) return false;
    return getFirstAncestor(ClassId.ligature, maxLigatureDepth) != null;
  }

  /// Mirrors `LayerElement::GetOriginalLayerN` (layerelement.cpp:255):
  /// the alignment layer when set, otherwise the ancestor layer's `@n`.
  int getOriginalLayerN() {
    final int layerN = getAlignmentLayerN();
    if (layerN < 0) {
      final Object? layer = getFirstAncestor(ClassId.layer);
      if (layer is AttNInteger) return (layer as AttNInteger).n ?? layerN;
      return layerN;
    }
    return layerN;
  }

  /// Mirrors `LayerElement::GetAncestorBeam` (layerelement.cpp:223).
  ///
  /// Deviation: the grace-note refinement (returning NULL for a non-beamed
  /// grace note inside a beam) lives on the `LayoutElementHelpers` extension
  /// in `preparedata_functor.dart`, which has access to the concrete `Beam`
  /// class; this base-class helper returns the plain ancestor lookup.
  Object? getAncestorBeamBase() {
    if (!isAny(const {
      ClassId.chord,
      ClassId.note,
      ClassId.rest,
      ClassId.tabGrp,
      ClassId.tabDurSym,
      ClassId.stem,
    })) {
      return null;
    }
    final Object? beamParent = getFirstAncestor(ClassId.beam);
    if (classId == ClassId.rest) return beamParent;
    return beamParent;
  }

  /// Mirrors `Object::GetStemmedDrawingInterface` (object.h:190) and the three
  /// overrides that return `this`: `note.h:97`, `chord.h:64`,
  /// `tabdursym.h:47`. Every other class keeps the `NULL` default — a
  /// `TabGrp`, in particular, does *not* resolve to its `TabDurSym` child.
  StemmedDrawingInterface? getStemmedDrawingInterface() =>
      this is StemmedDrawingInterface ? this as StemmedDrawingInterface : null;

  // -------------------------------------------------------------------------
  // Drawing values set during layout (kept minimal until then)
  // -------------------------------------------------------------------------

  int drawingXRel = 0;
  int drawingYRel = 0;
  bool drawingCueSize = false;

  /// Mirrors `SetDrawingXRel` / `GetDrawingXRel`.
  void setDrawingXRel(int drawingXRel) {
    resetCachedDrawingX();
    this.drawingXRel = drawingXRel;
  }

  /// Mirrors `SetDrawingYRel` / `GetDrawingYRel`.
  void setDrawingYRel(int drawingYRel) {
    resetCachedDrawingY();
    this.drawingYRel = drawingYRel;
  }

  /// The cached values of [drawingXRel] / [drawingYRel] for caching the
  /// horizontal layout (mirrors `m_cachedXRel` / `m_cachedYRel`).
  int _cachedXRel = meiUnset;
  int _cachedYRel = meiUnset;

  /// Mirrors `LayerElement::CacheXRel`: with [restore] set, writes the cached
  /// value back into [drawingXRel]; otherwise stores the current value.
  void cacheXRel({bool restore = false}) {
    if (restore) {
      drawingXRel = _cachedXRel;
    } else {
      _cachedXRel = drawingXRel;
    }
  }

  /// Mirrors `LayerElement::CacheYRel`, symmetrical to [cacheXRel].
  void cacheYRel({bool restore = false}) {
    if (restore) {
      drawingYRel = _cachedYRel;
    } else {
      _cachedYRel = drawingYRel;
    }
  }

  /// Facsimile X/Y for transcription layout (mirrors `m_drawingFacsX` /
  /// `m_drawingFacsY`; Y is used only for accid and syl, set by the
  /// `FacsimileFunctor` — Phase 6, task 06-07).
  int drawingFacsX = meiUnset;
  int drawingFacsY = meiUnset;

  /// The cross-staff the element belongs to (mirrors `m_crossStaff`).
  Staff? crossStaff;

  /// The cross-layer the element belongs to (mirrors `m_crossLayer`).
  Layer? crossLayer;

  /// Mirrors `LayerElement::GetCrossStaff` (layerelement.cpp:300).
  ///
  /// Deviation from the C++: the `Layer *&layer` output parameter becomes the
  /// second element of the returned record, since Dart has no reference
  /// parameters.
  (Staff?, Layer?) getCrossStaff() {
    if (crossStaff != null) return (crossStaff, crossLayer);

    final Object? parent =
        getFirstAncestorInRange(ClassId.layerElement, ClassId.layerElementMax);
    if (parent is LayerElement) return parent.getCrossStaff();

    return (null, null);
  }

  /// Mirrors `LayerElement::GetCrossStaffRel` (layerelement.cpp:316).
  StaffrelBasic getCrossStaffRel() {
    final Staff? cross = crossStaff;
    if (cross == null) return StaffrelBasic.none;

    final Object? staff = getFirstAncestor(ClassId.staff);
    if (staff is! Staff) return StaffrelBasic.none;

    return ((cross.n ?? 0) < (staff.n ?? 0))
        ? StaffrelBasic.above
        : StaffrelBasic.below;
  }

  /// True when the element is contained in a beamSpan (mirrors
  /// `m_isInBeamspan`; only meaningful for note, chord and rest).
  bool isInBeamSpan = false;

  /// Mirrors `LayerElement::GetAncestorFTrem` (layerelement.cpp:217): the
  /// nearest FTREM ancestor, but only for CHORD/NOTE elements (null for
  /// every other class, including detached elements without such ancestor).
  ///
  /// Deviation: the C++ has mutable/const overloads returning
  /// `FTrem *` / `const FTrem *`; Dart returns the single `FTrem?`.
  FTrem? getAncestorFTrem() {
    if (classId != ClassId.chord && classId != ClassId.note) return null;
    return getFirstAncestor(ClassId.fTrem, maxFTremDepth) as FTrem?;
  }

  /// Mirrors `LayerElement::SetIsInBeamSpan` (layerelement.cpp:264): no-op
  /// unless the element is a chord, note or rest.
  ///
  /// Set by `PrepareBeamSpanElementsFunctor` (preparedatafunctor.cpp:1922)
  /// and cleared by `ResetDataFunctor` (resetfunctor.cpp:280).
  void setIsInBeamSpan(bool isInBeamSpan) {
    if (!isAny(const {ClassId.chord, ClassId.note, ClassId.rest})) return;
    this.isInBeamSpan = isInBeamSpan;
  }

  /// Mirrors `LayerElement::IsInBeam` (layerelement.h:137): true when the
  /// element has an ancestor beam or is contained in a beamSpan.
  ///
  /// Deviation: the grace-note refinement of `GetAncestorBeam`
  /// (layerelement.cpp:228-256) is delegated to the layout helper
  /// `getAncestorBeam` (preparedata_functor.dart), which the functors use;
  /// this predicate is the plain structural check.
  bool isInBeam() =>
      getFirstAncestor(ClassId.beam) != null || isInBeamSpan;

  /// Mirrors `LayerElement::GetChordOverflow` (layerelement.cpp:355): for
  /// dots, flags and stems inside a cross-staff chord, redirect the above /
  /// below staff alignments to the extreme staves of the chord.
  ///
  /// Deviation from the C++: output parameters become an updated record;
  /// callers pass the current `(above, below)` pair and use the result.
  ///
  /// Deviation: `Chord::GetCrossStaffExtremes` (chord.cpp:321) also returns
  /// the extreme layers; only the staves are used here, so the layer outputs
  /// are dropped (see `Chord.getCrossStaffExtremes`).
  (StaffAlignment?, StaffAlignment?) getChordOverflow(
      StaffAlignment? above, StaffAlignment? below, int staffN) {
    final Chord? chord =
        getFirstAncestor(ClassId.chord) as Chord?;
    // Dots, flags and stems with cross-staff chords need special treatment.
    if (isAny(const {ClassId.dots, ClassId.flag, ClassId.stem}) &&
        chord != null &&
        chord.hasCrossStaff()) {
      final (Staff?, Staff?, Layer?, Layer?) extremes =
          chord.getCrossStaffExtremes();
      final Staff? staffAbove = extremes.$1;
      final Staff? staffBelow = extremes.$2;
      if (staffAbove != null && (staffAbove.n ?? 0) < staffN) {
        above = staffAbove.getAlignment();
      }
      if (staffBelow != null && (staffBelow.n ?? 0) > staffN) {
        below = staffBelow.getAlignment();
      }
    }
    return (above, below);
  }

  /// Mirrors the static `LayerElement::GetDotCount`
  /// (layerelement.cpp:1020): the total number of dot locations.
  static int getDotCount(Map<Object, Set<int>> dotLocations) {
    var sum = 0;
    for (final Set<int> locs in dotLocations.values) {
      sum += locs.length;
    }
    return sum;
  }

  /// Mirrors the static `LayerElement::GetCollisionCount`
  /// (layerelement.cpp:1026): the number of dot locations shared by the two
  /// maps (same staff key and same loc).
  static int getCollisionCount(
      Map<Object, Set<int>> dotLocs1, Map<Object, Set<int>> dotLocs2) {
    var count = 0;
    for (final MapEntry<Object, Set<int>> entry in dotLocs1.entries) {
      final Set<int>? other = dotLocs2[entry.key];
      if (other == null) continue;
      count += entry.value.intersection(other).length;
    }
    return count;
  }

  /// Mirrors `LayerElement::GenerateZoneBounds` (layerelement.cpp:824):
  /// the bounding box of the zones of the facsimile descendants (excluding
  /// syl children, whose own zones are generated by `Syl.createDefaultZone`).
  ///
  /// Returns null when no descendant carries a zone.
  ///
  /// Deviation from the C++: output int* parameters become a nullable
  /// record, since Dart has no reference parameters.
  (int, int, int, int)? generateZoneBounds() {
    var ulx = 0x7FFFFFFF;
    var uly = 0x7FFFFFFF;
    var lrx = -0x7FFFFFFF;
    var lry = -0x7FFFFFFF;
    final List<Object> facsimileChildren = findAllDescendantsMatching(
        InterfaceComparison(InterfaceId.facsimile));
    var result = false;
    for (final Object object in facsimileChildren) {
      if (object is! FacsimileInterface) continue;
      if (object.isClass(ClassId.syl)) continue;
      final Zone? resolvedZone = (object as FacsimileInterface).zone;
      if (resolvedZone == null) continue;
      final int? zulx = resolvedZone.ulx;
      final int? zuly = resolvedZone.uly;
      final int? zlrx = resolvedZone.lrx;
      final int? zlry = resolvedZone.lry;
      if (zulx == null || zuly == null || zlrx == null || zlry == null) {
        continue;
      }
      if (zulx < ulx) ulx = zulx;
      if (zuly < uly) uly = zuly;
      if (zlrx > lrx) lrx = zlrx;
      if (zlry > lry) lry = zlry;
      result = true;
    }
    return result ? (ulx, uly, lrx, lry) : null;
  }

  /// The role of the element when it comes from a scoreDef (mirrors
  /// `m_scoreDefRole`); set by the horizontal alignment functor.
  ElementScoreDefRole scoreDefRole = ElementScoreDefRole.none;
  void setScoreDefRole(ElementScoreDefRole role) => scoreDefRole = role;
  ElementScoreDefRole getScoreDefRole() => scoreDefRole;

  // -------------------------------------------------------------------------
  // Horizontal alignment (mirrors layerelement.h m_alignment /
  // m_graceAlignment / m_alignmentLayerN)
  // -------------------------------------------------------------------------

  /// The alignment the element points to (set by the horizontal alignment
  /// functor; mirrors `m_alignment`).
  Alignment? _alignment;

  /// Mirrors `LayerElement::GetDrawingX` (layerelement.cpp:389): facsimile
  /// X when set, otherwise the measure/alignment/grace chain.
  ///
  /// The `m_drawingFacsX` value itself is set by the Facsimile functor
  /// (Phase 6, task 06-07) — this getter is the only part that can be
  /// ported headlessly now; the setter remains deferred with a named owner.
  @override
  int getDrawingX() {
    if (drawingFacsX != meiUnset) return drawingFacsX + drawingXRel;
    final Alignment? alignment = _alignment;
    if (alignment == null) {
      // Here we just get the measure position - no cast to Measure needed.
      // Deviation: detached elements (without a measure ancestor) sit at the
      // origin instead of asserting.
      final Object? measure = getFirstAncestor(ClassId.measure);
      return measure?.getDrawingX() ?? 0;
    }

    // First get the first layerElement parent (if any) and use its position
    // if they share the same alignment.
    final Object? parent =
        getFirstAncestorInRange(ClassId.layerElement, ClassId.layerElementMax);
    if (parent is LayerElement && identical(parent.getAlignment(), alignment)) {
      return parent.getDrawingX() + drawingXRel;
    }

    // Otherwise get the measure.
    final Object? measure = getFirstAncestor(ClassId.measure);
    if (measure == null) return drawingXRel;

    int graceNoteShift = 0;
    if (hasGraceAlignment()) {
      graceNoteShift = getGraceAlignment()!.getXRel();
    }

    return measure.getDrawingX() +
        alignment.getXRel() +
        drawingXRel +
        graceNoteShift;
  }

  /// Mirrors `LayerElement::GetDrawingY` (layerelement.cpp:429): facsimile
  /// Y when set, otherwise the cross-staff / parent / staff / measure chain.
  ///
  /// See [getDrawingX] for the facsimile ownership note (06-07).
  @override
  int getDrawingY() {
    if (drawingFacsY != meiUnset) return drawingFacsY + drawingYRel;
    if (cachedDrawingY != meiUnset) return cachedDrawingY;

    // Look if we have a crossStaff situation (layerelement.cpp:437).
    Object? object = crossStaff;
    // First get the first layerElement parent (if any) but only if the
    // element is not directly relative to staff (e.g., artic, syl) and has no
    // cross-staff situation.
    if (object == null && !isRelativeToStaff) {
      object = getFirstAncestorInRange(
          ClassId.layerElement, ClassId.layerElementMax);
    }
    // Otherwise get the first staff.
    object ??= getFirstAncestor(ClassId.staff);
    // Otherwise the first measure (this is the case with barLineAttr).
    object ??= getFirstAncestor(ClassId.measure);
    // Deviation: detached elements fall back to the origin instead of
    // asserting.
    if (object == null) return drawingYRel;

    cachedDrawingY = object.getDrawingY() + drawingYRel;
    return cachedDrawingY;
  }

  /// Get the alignment (mirrors `GetAlignment`).
  Alignment? getAlignment() => _alignment;

  /// Reset the alignment pointer to null (mirrors `ResetAlignment`).
  void resetAlignment() => _alignment = null;

  /// Set the alignment (mirrors `SetAlignment`).
  void setAlignment(Alignment? alignment) => _alignment = alignment;

  /// The grace alignment the element points to (mirrors `m_graceAlignment`).
  Alignment? _graceAlignment;

  /// Get the grace alignment (mirrors `GetGraceAlignment`).
  Alignment? getGraceAlignment() => _graceAlignment;

  /// Reset the grace alignment pointer to null (mirrors
  /// `ResetGraceAlignment`).
  void resetGraceAlignment() => _graceAlignment = null;

  /// Set the grace alignment (mirrors `SetGraceAlignment`).
  void setGraceAlignment(Alignment? graceAlignment) =>
      _graceAlignment = graceAlignment;

  /// True when a grace alignment is set (mirrors `HasGraceAlignment`).
  bool hasGraceAlignment() => _graceAlignment != null;

  /// The layer n used by the alignment reference holding this element
  /// (negative for cross-staff layers; mirrors `m_alignmentLayerN`,
  /// [meiUnset] when unset).
  int _alignmentLayerN = meiUnset;

  /// Get the alignment layer n (mirrors `GetAlignmentLayerN`).
  int getAlignmentLayerN() => _alignmentLayerN;

  /// Set the alignment layer n (mirrors `SetAlignmentLayerN`).
  void setAlignmentLayerN(int alignmentLayerN) =>
      _alignmentLayerN = alignmentLayerN;

  @override
  void copyFrom(covariant LayerElement other) {
    super.copyFrom(other);
    // Drawing values (mirrored from the C++ implicit copy constructor;
    // alignment pointers arrive with the layout phase).
    drawingFacsX = other.drawingFacsX;
    drawingFacsY = other.drawingFacsY;
    drawingXRel = other.drawingXRel;
    drawingYRel = other.drawingYRel;
    drawingCueSize = other.drawingCueSize;
    crossStaff = other.crossStaff;
    crossLayer = other.crossLayer;
  }

  /// Mirrors `LayerElement::CenterDrawingX` (layerelement.cpp:511).
  void centerDrawingX() {
    if (drawingFacsX != meiUnset) return;
    setDrawingXRel(0);
    final Object? measure = getFirstAncestor(ClassId.measure);
    assert(measure != null);
    // Use Measure's inner center if available, else fallback to drawingX
    final int innerCenterX;
    if (measure is Measure) {
      innerCenterX = measure.getInnerCenterX();
    } else {
      innerCenterX = getDrawingX();
    }
    setDrawingXRel(innerCenterX - getDrawingX());
  }

  @override
  bool isSupportedChild(ClassId classId) {
    logDebug('Method for adding $classId to $className should be overridden');
    return false;
  }
}

/// Mirrors `vrv::GenericLayerElement`: fallback class for layer elements
/// without a dedicated class (e.g., `<gap>`, `<pb>` / `<sb>` within layers).
class GenericLayerElement extends LayerElement {
  /// Mirrors `GenericLayerElement(const std::string &name)`.
  GenericLayerElement(this.meiName) : super(ClassId.genericElement) {
    assignClassId(ClassId.genericElement);
    classNameValue =
        meiName.substring(0, 1).toUpperCase() + meiName.substring(1);
    reset();
  }

  /// The MEI element name (mirrors `m_meiName`).
  final String meiName;

  /// The class name with a leading capital (mirrors `m_className`).
  String classNameValue = '[unspecified]';

  /// The serialized MEI content of the element (mirrors `m_content`).
  String content = '';

  @override
  ClassId get classId => ClassId.genericElement;

  @override
  String get className => classNameValue;

  @override
  Object clone() {
    final copy = GenericLayerElement(meiName);
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant GenericLayerElement other) {
    super.copyFrom(other);
    content = other.content;
  }
}
