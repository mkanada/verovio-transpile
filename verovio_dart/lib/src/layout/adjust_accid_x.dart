/// Port of `adjustaccidxfunctor.h/cpp` — horizontal de-stacking of
/// accidentals — plus the two `Accid` instance methods it drives
/// (`Accid::AdjustX`, `Accid::AdjustToLedgerLines`, both from `accid.cpp`)
/// and the `AccidSpaceSort` / `AccidOctaveSort` comparators (`accid.h`).
///
/// `Accid::AdjustX` / `AdjustToLedgerLines` and `Chord::HasAdjacentNotesInStaff`
/// are ported as extensions on the generated [Accid] / [Chord] classes
/// instead of hand-edited instance methods, following the precedent already
/// set by `ChordDotLocations` in `calc_functors.dart`: it keeps
/// `layer_elements_gen.dart` free of anything beyond the state fields that
/// genuinely cannot live outside the class (Dart extensions cannot add
/// fields).
///
/// Deviations from the C++:
/// - `Accid::AdjustToLedgerLines`'s special-case shrink for flats
///   (`GetCutOutRight(resources, true)`) uses [BoundingBox.getCutOutRight],
///   itself an approximation (see that method's doc) since the SMuFL glyph
///   cut-out anchors are not wired to [Doc] in this phase.
/// - This functor (like `AdjustArticFunctor`) needs the rendered self
///   bounding boxes of notes/stems/accidentals. In this port those are only
///   filled by [HeadlessExtents] during the vertical layout phase, not
///   during `Page::layOutHorizontally` as in the C++. It is therefore wired
///   into `Doc.layOutVertically`, right after the headless extents pass —
///   the same documented deviation already used for `AdjustArpegFunctor`
///   (see `doc.dart`).
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, AlignmentReference;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Accid, Chord;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef, StaffDef;

// ---------------------------------------------------------------------------
// AccidSpaceSort / AccidOctaveSort
// ---------------------------------------------------------------------------

/// Mirrors `AccidSpaceSort::operator()`: sorts by drawing Y, descending
/// (top to bottom); on a Y tie, an accidental with value `n` sorts before
/// one that isn't (the literal C++ predicate — despite its own comment
/// claiming naturals sort last, `operator()(natural, other) == true` places
/// the natural *before* `other` under `std::sort`'s convention; mirrored
/// as written, not as commented).
int _accidSpaceCompare(Accid first, Accid second) {
  if (first.getDrawingY() == second.getDrawingY()) {
    final bool firstIsNatural = first.accid == AccidentalWritten.n;
    final bool secondIsNatural = second.accid == AccidentalWritten.n;
    if (firstIsNatural && !secondIsNatural) return -1;
    if (secondIsNatural && !firstIsNatural) return 1;
    return 0;
  }
  return second.getDrawingY().compareTo(first.getDrawingY());
}

/// Mirrors `AccidOctaveSort::GetOctaveID`: a key grouping accidentals that
/// are an octave apart on the same note/chord and accidental kind.
///
/// Deviation: `std::multiset`'s `equal_range` groups elements with an equal
/// key while preserving insertion order among them; a `Map` from key to a
/// list of `Accid` built by iterating the (already `AccidSpaceSort`-sorted)
/// input in order reproduces the same grouping and relative order without
/// needing an ordered-multimap type.
String _octaveId(Accid accid) {
  final Note note = accid.getFirstAncestor(ClassId.note) as Note;
  final Object? chord = note.isChordTone();
  final String ownerId = chord is Chord ? chord.id : note.id;
  return '$ownerId-${accid.accid?.value ?? 0}-${note.pname?.value ?? 0}';
}

// ---------------------------------------------------------------------------
// Accid::AdjustX / Accid::AdjustToLedgerLines
// ---------------------------------------------------------------------------

extension AccidAdjustX on Accid {
  /// Mirrors `Accid::AdjustToLedgerLines`.
  void adjustToLedgerLines(Doc doc, LayerElement element, int staffSize) {
    final Staff staff = element.getAncestorStaffResolveCrossStaff()!;
    final Object? chordAncestor = getFirstAncestor(ClassId.chord);
    final Chord? chord = chordAncestor is Chord ? chordAncestor : null;

    final int unit = doc.getDrawingUnit(staffSize);
    final int rightMargin = (doc.getRightMargin(ClassId.accid) * unit).toInt();
    if (element.classId == ClassId.note &&
        chord != null &&
        chord.hasAdjacentNotesInStaff(staff)) {
      final int horizontalMargin =
          (doc.options.ledgerLineExtension.value * unit + 0.5 * rightMargin)
              .toInt();
      final int staffTop = staff.getDrawingY();
      final int staffBottom = staffTop - doc.getDrawingStaffSize(staffSize);
      if (horizontalContentOverlap(element)) {
        if ((getContentTop() > staffTop + 2 * unit &&
                getDrawingY() < element.getDrawingY()) ||
            (getContentBottom() < staffBottom - 2 * unit &&
                getDrawingY() > element.getDrawingY())) {
          int right = getSelfRight();
          // Special case: reduce shift for flats intersecting only the
          // first ledger line above the staff.
          if (accid == AccidentalWritten.f || accid == AccidentalWritten.ff) {
            if (getContentTop() > staffTop + 2 * unit &&
                getContentTop() < staffTop + 4 * unit) {
              right = getCutOutRight(true);
            }
          }
          final int xRelShift =
              right - element.getSelfLeft() + horizontalMargin;
          if (xRelShift > 0) setDrawingXRel(drawingXRel - xRelShift);
        }
      }
    }
  }

  /// Mirrors `Accid::AdjustX`. [leftAccids] and [adjustedAccids] are the
  /// caller-owned collections the C++ passes by reference.
  void adjustX(LayerElement element, Doc doc, int staffSize,
      List<Accid> leftAccids, Set<Accid> adjustedAccids) {
    if (identical(this, element)) return;

    final int unit = doc.getDrawingUnit(staffSize);
    // `horizontalMargin` is `int` from the start in the C++ (truncated at
    // each assignment, not deferred to one final conversion) — mirrored
    // step by step so the truncation points line up exactly.
    int horizontalMargin = (doc.getRightMargin(ClassId.accid) * unit).toInt();
    // Reduce spacing for successive accidentals.
    if (element.classId == ClassId.accid) {
      horizontalMargin = (horizontalMargin * 0.66).toInt();
    } else if (element.classId == ClassId.note) {
      final Note note = element as Note;
      final Staff staff = note.getAncestorStaffResolveCrossStaff()!;
      final (bool hasLedgerLines, _, _) = note.hasLedgerLines(staff);
      if (hasLedgerLines) {
        final int value = (doc.options.ledgerLineExtension.value * unit +
                0.5 * horizontalMargin)
            .toInt();
        horizontalMargin = horizontalMargin > value ? horizontalMargin : value;
      }
    }
    final int verticalMargin = unit ~/ 4;

    if (!verticalSelfOverlap(element, verticalMargin)) {
      adjustToLedgerLines(doc, element, staffSize);
      return;
    }

    // Look for identical accidentals that need to remain superimposed.
    if (element.classId == ClassId.accid &&
        getDrawingY() == element.getDrawingY()) {
      final Accid other = element as Accid;
      if (_symbolKey(this) == _symbolKey(other)) {
        // There is the same accidental, so we leave it in the same place.
        // This should also work for chords on multiple layers by setting the
        // unison accidental.
        other.setDrawingUnisonAccid(this);
        return;
      }
    }

    if (element.classId == ClassId.accid) {
      final Accid other = element as Accid;
      if (horizontalLeftOverlap(element, horizontalMargin, verticalMargin) ==
          0) {
        // There is enough space on the right of the accidental, but maybe we
        // will need to adjust it again (see the recursive call below), so
        // keep the accidental that is on the left.
        leftAccids.add(other);
        return;
      }
      if (!adjustedAccids.contains(other)) return;
    }

    int xRelShift;
    if (element.classId == ClassId.stem) {
      xRelShift = getSelfRight() - element.getSelfLeft() + horizontalMargin;
    } else {
      xRelShift =
          horizontalRightOverlap(element, horizontalMargin, verticalMargin);
    }

    // Move only to the left.
    if (xRelShift > 0) {
      setDrawingXRel(drawingXRel - xRelShift);
      adjustedAccids.add(this);
      // We have some accidentals on the left, check again with all of these.
      if (leftAccids.isNotEmpty) {
        final List<Accid> leftAccidsSubset = [];
        // Recursively adjust all accidentals that are on the left because
        // enough space was previously available.
        for (final Accid accid in leftAccids) {
          adjustX(accid, doc, staffSize, leftAccidsSubset, adjustedAccids);
        }
      }
    }
  }
}

/// Reduced stand-in for `Accid::GetSymbolStr` equality (only usage: the
/// unison-superimposition check in [AccidAdjustX.adjustX]). `GetSymbolStr`
/// builds the full SMuFL glyph string (including enclosing brackets and
/// glyph substitutions, `Accid::CreateSymbolStr` in `accid.cpp`), which is a
/// rendering-string concern not ported at this phase; this compares the
/// identity data that drives it instead (same effective equality for any
/// accidental that isn't glyph-overridden).
(AccidentalWritten?, Enclosure?, int?, String?) _symbolKey(Accid accid) =>
    (accid.accid, accid.enclose, accid.glyphNum, accid.glyphName);

// ---------------------------------------------------------------------------
// Chord::HasAdjacentNotesInStaff
// ---------------------------------------------------------------------------

extension ChordLedgerLineHelpers on Chord {
  /// Mirrors `Chord::HasAdjacentNotesInStaff`.
  ///
  /// Deviation: `Chord::CalcNoteLocations` is not ported as a standalone
  /// method (no other caller needs it in this phase); its effect is inlined
  /// here directly from the notes' already-computed `drawingLoc`.
  bool hasAdjacentNotesInStaff(Staff staff) {
    final List<int> locs = [];
    for (final Object child in getList()) {
      final Note note = child as Note;
      if (note.getAncestorStaffResolveCrossStaff() != staff) continue;
      locs.add(note.drawingLoc);
    }
    if (locs.length <= 1) return false;
    locs.sort();
    for (int i = 1; i < locs.length; i++) {
      if (locs[i] - locs[i - 1] == 1) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// AdjustAccidXFunctor
// ---------------------------------------------------------------------------

/// Adjusts the X position of accidentals, including in chords (mirrors
/// `vrv::AdjustAccidXFunctor`).
class AdjustAccidXFunctor extends DocFunctor {
  AdjustAccidXFunctor(super.doc);

  @override
  bool get implementsEndInterface => false;

  /// The current measure (mirrors `m_currentMeasure`); unused beyond mirror
  /// fidelity — no method in this functor consults it, same as the C++.
  Measure? currentMeasure;

  /// The accidentals that were already adjusted (mirrors
  /// `m_adjustedAccids`).
  final Set<Accid> adjustedAccids = {};

  @override
  FunctorCode visitAlignment(Alignment alignment) {
    for (final graceAligner in alignment.getGraceAligners().values) {
      graceAligner.process(this);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitAlignmentReference(AlignmentReference alignmentReference) {
    adjustedAccids.clear();

    final List<Accid> accids = _accidentalsForAdjustment(alignmentReference);
    if (accids.isEmpty) return FunctorCode.siblings;

    final ScoreDef? scoreDef = doc
        .getCorrespondingScore(alignmentReference)
        ?.getScoreDef() as ScoreDef?;
    final StaffDef? staffDef = scoreDef?.getStaffDef(alignmentReference.n ?? 0);
    final int staffSize =
        staffDef != null && staffDef.hasScale ? staffDef.scale!.toInt() : 100;

    accids.sort(_accidSpaceCompare);
    // Process accid layer alignment.
    for (final Accid accid in accids) {
      _setAccidLayerAlignment(accid, alignmentReference);
    }

    // Detect accids that are an octave apart so they get grouped together.
    final Map<String, List<Accid>> octaveEquivalence = {};
    for (final Accid accid in accids) {
      octaveEquivalence.putIfAbsent(_octaveId(accid), () => []).add(accid);
    }

    // Align the octaves.
    for (final Accid accid in accids) {
      // Skip any accid that was already adjusted.
      if (adjustedAccids.contains(accid)) continue;
      // Skip accid not descendant of a note (e.g., mensural).
      if (accid.getFirstAncestor(ClassId.note) == null) continue;

      final List<Accid> range = octaveEquivalence[_octaveId(accid)]!;
      // Handle at least two octave accids without unisons.
      final Set<int> octaves = {};
      for (final Accid octaveAccid in range) {
        final Note note = octaveAccid.getFirstAncestor(ClassId.note) as Note;
        octaves.add(note.oct ?? 0);
      }
      if (range.length < 2 || octaves.length < range.length) continue;

      // Now adjust the octave accids and store the left most position.
      int minDrawingX = -meiUnset;
      for (final Accid octaveAccid in range) {
        _adjustAccidWithSpace(octaveAccid, alignmentReference, staffSize);
        if (octaveAccid.getDrawingX() < minDrawingX) {
          minDrawingX = octaveAccid.getDrawingX();
        }
      }
      // Finally, align the accidentals whenever the adjustment is not too
      // large.
      for (final Accid octaveAccid in range) {
        final int dist = octaveAccid.getDrawingX() - minDrawingX;
        if (dist > 0 && octaveAccid.hasContentHorizontalBB()) {
          final int accidWidth =
              octaveAccid.getContentRight() - octaveAccid.getContentLeft();
          if (dist < accidWidth ~/ 2) {
            octaveAccid.setDrawingXRel(octaveAccid.drawingXRel - dist);
          }
        }
      }
    }

    // Align accidentals for unison notes if any of them are present.
    for (final Accid accid in accids) {
      final Accid? unison = accid.getDrawingUnisonAccid();
      if (unison == null) continue;
      accid.setDrawingXRel(unison.drawingXRel);
    }

    final int count = accids.length;
    // Zig-zag processing, taking multiple accidentals per note into account.
    int j = count - 1;
    for (int i = 0; i < count; ++i) {
      // Top one - but skip if already adjusted (i.e. octaves).
      if (!adjustedAccids.contains(accids[i])) {
        _adjustAccidWithSpace(accids[i], alignmentReference, staffSize);
      }

      // Top one - don't zig-zag if the next accidental belongs to the
      // current note, to preserve order.
      if (i < count - 1 &&
          identical(accids[i].getFirstAncestor(ClassId.note),
              accids[i + 1].getFirstAncestor(ClassId.note))) {
        continue;
      }

      // Bottom one - back up to the first accidental of the current note to
      // preserve order.
      final int k = j;
      while (j > 0 &&
          identical(accids[j].getFirstAncestor(ClassId.note),
              accids[j - 1].getFirstAncestor(ClassId.note))) {
        --j;
      }

      // Bottom one - but skip if already adjusted.
      for (int l = j; l <= k; ++l) {
        if (!adjustedAccids.contains(accids[l])) {
          _adjustAccidWithSpace(accids[l], alignmentReference, staffSize);
        }
      }

      // Bottom one - move to the previous position.
      --j;
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    currentMeasure = measure;

    measure.measureAligner.process(this);

    return FunctorCode.continue_;
  }

  /// Mirrors `AdjustAccidXFunctor::GetAccidentalsForAdjustment`.
  List<Accid> _accidentalsForAdjustment(AlignmentReference alignmentReference) {
    final List<Accid> accidentals = [];
    for (final Object child in alignmentReference.children) {
      if (child.classId != ClassId.accid) continue;
      final Accid accid = child as Accid;
      if (accid.hasAccid && accid.getFirstAncestor(ClassId.note) != null) {
        accidentals.add(accid);
      }
    }
    return accidentals;
  }

  /// Mirrors `AdjustAccidXFunctor::SetAccidLayerAlignment`.
  void _setAccidLayerAlignment(
      Accid accid, AlignmentReference alignmentReference) {
    if (accid.isAlignedWithSameLayer()) return;

    final Note parentNote = accid.getFirstAncestor(ClassId.note) as Note;
    bool hasUnisonOverlap = false;
    for (final Object object in alignmentReference.children) {
      if (object.classId != ClassId.note) continue;
      final Note otherNote = object as Note;
      // In case notes are in unison but have different accidentals.
      if (parentNote.isUnisonWith(otherNote, true) &&
          !parentNote.isUnisonWith(otherNote, false)) {
        hasUnisonOverlap = true;
        break;
      }
    }

    if (!hasUnisonOverlap) return;

    final Object? chordAncestor = parentNote.isChordTone();
    // No chord, so align only the parent note.
    if (chordAncestor is! Chord) {
      accid.setAlignedWithSameLayer(true);
      return;
    }
    // We have a chord ancestor, so we need to align all of its accidentals.
    for (final Object object
        in chordAncestor.findAllDescendantsByType(ClassId.accid)) {
      (object as Accid).setAlignedWithSameLayer(true);
    }
  }

  /// Mirrors `AdjustAccidXFunctor::AdjustAccidWithSpace`.
  void _adjustAccidWithSpace(
      Accid accid, AlignmentReference alignmentReference, int staffSize) {
    final List<Accid> leftAccids = [];

    for (final Object child in alignmentReference.children) {
      // If the accidental has a unison overlap, ignore elements on other
      // layers for overlap.
      if (accid.isAlignedWithSameLayer() &&
          accid.getFirstAncestor(ClassId.layer) !=
              child.getFirstAncestor(ClassId.layer)) {
        continue;
      }
      accid.adjustX(
          child as LayerElement, doc, staffSize, leftAccids, adjustedAccids);
    }

    // Mark as adjusted (even if the position was not altered).
    adjustedAccids.add(accid);
  }
}
