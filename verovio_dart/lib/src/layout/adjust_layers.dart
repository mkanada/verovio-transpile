/// Port of the multi-layer collision adjustment run twice in
/// `Page::LayOutHorizontally` (`page.cpp:396-497`):
///
/// - [AdjustLayersFunctor] mirrors `adjustlayersfunctor.h/cpp`
/// - [AdjustDotsFunctor] mirrors `adjustdotsfunctor.h/cpp`
///
/// The C++ runs `AdjustLayersFunctor` twice: once with `IgnoreDots(true)`
/// (default) before `AdjustDotsFunctor`, and once with `IgnoreDots(false)`
/// after it — see `doc.dart`'s horizontal layout phase for the exact order.
///
/// The two functors call a chain of support methods that were not yet ported:
/// `LayerElement::AdjustOverlappingLayers` / `CalcElementHorizontalOverlap`,
/// `Chord::AdjustOverlappingLayers`, `LayerElement::GetElementsInUnison`,
/// `Note::HandleLedgerLineStemCollision`, and `Stem::CompareToElementPosition`.
/// None of them are virtual-dispatched polymorphically by Dart (no double
/// dispatch — see `functor.dart`'s header comment for the project's general
/// approach to this), so [_adjustOverlappingLayers] manually branches to
/// [_chordAdjustOverlappingLayers] when the element is a [Chord], exactly
/// mirroring what C++ virtual dispatch does when `this` is a `Chord`.
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset, MeiDuration;
import 'package:verovio_dart/src/core/smufl.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, AlignmentReference, barlineReferences;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Stemdirection;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/comparison.dart'
    show AttNIntegerAnyComparison, Filters;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Accid, Chord, Dots, Flag, Stem;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

// ---------------------------------------------------------------------------
// Support chain: LayerElement/Chord/Note/Stem helpers not yet ported
// ---------------------------------------------------------------------------

/// Mirrors `LayerElement::CalcElementHorizontalOverlap`. Not virtual in the
/// C++ (single implementation branching on `this->Is(...)`); [element] here
/// stands in for `this`.
(int, bool) _calcElementHorizontalOverlap(LayerElement element, Doc doc,
    List<LayerElement> otherElements, bool areDotsAdjusted, bool isChordElement,
    [bool isLowerElement = false, bool unison = true]) {
  final Staff staff = element.getAncestorStaffLayout();

  bool isInUnison = false;
  int shift = 0;

  for (int i = 0; i < otherElements.length; ++i) {
    final LayerElement other = otherElements[i];
    int verticalMargin = 0;
    int horizontalMargin = 2 * doc.getDrawingStemWidth(staff.drawingStaffSize);
    bool isUnisonElement = false;

    // Handle stem collisions.
    if (element.classId == ClassId.stem) {
      final Stem stem = element as Stem;
      if (other.classId == ClassId.note) {
        shift += stem.compareToElementPosition(doc, other, -shift);
      } else if (other.classId == ClassId.dots &&
          stem.horizontalSelfOverlap(other, horizontalMargin)) {
        shift +=
            stem.horizontalLeftOverlap(other, 0, 0) + horizontalMargin ~/ 2;
      }
      if (shift != 0) break;
    }
    // Handle note collisions.
    else if (element.classId == ClassId.note && other.classId == ClassId.note) {
      final Note currentNote = element as Note;
      final Note previousNote = other as Note;
      isUnisonElement = currentNote.isUnisonWith(previousNote, true);

      if (unison && currentNote.isUnisonWith(previousNote, false)) {
        var previousDuration = previousNote.getDrawingDur();
        final bool isPreviousChord =
            previousNote.parent?.classId == ClassId.chord;
        bool isEdgeElement = false;
        final Stemdirection stemDir = currentNote.getDrawingStemDir();
        if (isPreviousChord) {
          final Chord parentChord = previousNote.parent as Chord;
          previousDuration = parentChord.getActualDur();
          isEdgeElement = ((stemDir == Stemdirection.down) &&
                  identical(parentChord.getBottomNote(), previousNote)) ||
              ((stemDir == Stemdirection.up) &&
                  identical(parentChord.getTopNote(), previousNote));
        } else if ((currentNote.getDrawingDur() == MeiDuration.dur1) &&
            (previousDuration == MeiDuration.dur1)) {
          horizontalMargin = 0;
        }

        if (!isPreviousChord || isEdgeElement || isChordElement) {
          if ((currentNote.getDrawingDur() == MeiDuration.dur2) &&
              (previousDuration == MeiDuration.dur2)) {
            isInUnison = true;
          } else if ((!currentNote.isGraceNote() &&
                  !currentNote.drawingCueSize) &&
              (previousNote.isGraceNote() || previousNote.drawingCueSize) &&
              (stemDir == Stemdirection.down)) {
            shift -= (0.8 * horizontalMargin).toInt();
            continue;
          } else if ((currentNote.isGraceNote() ||
                  currentNote.drawingCueSize) &&
              (!previousNote.isGraceNote() && !previousNote.drawingCueSize) &&
              (stemDir == Stemdirection.up)) {
            currentNote.setDrawingXRel(
                currentNote.drawingXRel + (0.8 * horizontalMargin).toInt());
            isInUnison = true;
            continue;
          } else if ((currentNote.getDrawingDur().value >
                  MeiDuration.dur2.value) &&
              (previousDuration.value > MeiDuration.dur2.value)) {
            isInUnison = true;
          }
          if (isInUnison &&
              ((currentNote.dots ?? meiUnset) ==
                  (previousNote.dots ?? meiUnset))) {
            continue;
          } else {
            isInUnison = false;
            if ((currentNote.getDrawingDur().value <= MeiDuration.dur1.value) ||
                (previousNote.getDrawingDur().value <=
                    MeiDuration.dur1.value)) {
              horizontalMargin *= -1;
            } else {
              horizontalMargin *= ((currentNote.dots ?? meiUnset) >=
                      (previousNote.dots ?? meiUnset))
                  ? 0
                  : -1;
            }
          }
        } else {
          horizontalMargin *= -1;
        }
      } else if (previousNote.drawingLoc - currentNote.drawingLoc > 1) {
        continue;
      } else if (previousNote.drawingLoc - currentNote.drawingLoc == 1) {
        horizontalMargin = 0;
      } else if ((previousNote.drawingLoc - currentNote.drawingLoc < 0) &&
          (previousNote.getDrawingStemDir() !=
              currentNote.getDrawingStemDir())) {
        if (previousNote.drawingLoc - currentNote.drawingLoc == -1) {
          horizontalMargin *= -1;
        } else if ((currentNote.getDrawingDur().value <=
                MeiDuration.dur1.value) &&
            (previousNote.getDrawingDur().value <= MeiDuration.dur1.value)) {
          continue;
        } else if (previousNote.crossStaff != null ||
            element.crossStaff != null) {
          continue;
        } else {
          horizontalMargin *= -1;
          verticalMargin = horizontalMargin;
        }
      }
    }
    // Handle dot collisions.
    else if (element.classId == ClassId.dots &&
        other.classId != ClassId.dots &&
        areDotsAdjusted) {
      final Dots dot = element as Dots;
      if (dot.isAdjusted ||
          !element.horizontalSelfOverlap(other, horizontalMargin)) {
        continue;
      }
      if (other.isAny({ClassId.note, ClassId.stem})) {
        shift -= other.horizontalLeftOverlap(
            element, shift + horizontalMargin ~/ 2, 0);
      } else {
        shift -= element.horizontalRightOverlap(other, -shift, verticalMargin);
      }
    } else if (element.classId == ClassId.accid &&
        other.classId == ClassId.note) {
      final Note? parentNote = element.getFirstAncestor(ClassId.note) as Note?;
      final Note otherNote = other as Note;
      final bool isUnisonOverlap = parentNote != null &&
          parentNote.isUnisonWith(otherNote, true) &&
          !parentNote.isUnisonWith(otherNote, false);
      if (isUnisonOverlap && element.horizontalContentOverlap(other)) {
        shift += element.horizontalRightOverlap(
            other, -doc.getDrawingUnit(staff.drawingStaffSize));
      }
    }

    if (element.classId == ClassId.note && other.classId != ClassId.stem) {
      // Nothing to do if we have no vertical overlap.
      if (!element.verticalSelfOverlap(other, verticalMargin)) continue;
      // Nothing to do either if we have no horizontal overlap.
      if (!element.horizontalSelfOverlap(other, horizontalMargin + shift)) {
        continue;
      }

      if (horizontalMargin < 0 || isLowerElement) {
        shift -= element.horizontalRightOverlap(other, -shift, verticalMargin);
        if (!isUnisonElement) shift -= horizontalMargin;
      } else if ((horizontalMargin >= 0) || isChordElement) {
        shift += element.horizontalLeftOverlap(
            other, horizontalMargin - shift, verticalMargin);
        // Additional adjustments for cross-staff and unison notes.
        if (element.crossStaff != null) shift -= horizontalMargin;
        if (isInUnison) shift *= -1;
      } else {
        // Otherwise move the appropriate parent to the right.
        shift -= horizontalMargin -
            element.horizontalRightOverlap(
                other, horizontalMargin - shift, verticalMargin);
      }
    } else if (element.classId == ClassId.note) {
      final Note currentNote = element as Note;
      if (other.classId == ClassId.stem && (shift == 0) && areDotsAdjusted) {
        final Stem stem = other as Stem;
        // Nothing to do if the note has a stem.sameas note.
        if (currentNote.hasStemSameasNote()) continue;
        shift -= stem.compareToElementPosition(doc, currentNote, 0);
      }
    }
  }

  // If the note is not in unison, has an accidental and were to be shifted to
  // the right, shift it to the left instead: the accidental should stay near
  // the note that actually has it, not near the lowest-layer note.
  if (element.classId == ClassId.note &&
      isChordElement &&
      unison &&
      (shift > 0)) {
    final Note currentNote = element as Note;
    if (currentNote.getDrawingAccid() != null) shift *= -1;
  }

  return (shift, isInUnison);
}

/// Mirrors `LayerElement::GetElementsInUnison`. [firstChord]/[secondChord]
/// are the sorted, deduplicated location sets (`std::set<int>` in the C++).
List<int> _getElementsInUnison(
    List<int> firstChord, List<int> secondChord, Stemdirection stemDirection) {
  if (firstChord.isEmpty || secondChord.isEmpty) return const [];

  final Set<int> firstSet = firstChord.toSet();
  final Set<int> secondSet = secondChord.toSet();
  final bool firstIsSmallerOrEqual = firstChord.length <= secondChord.length;

  final List<int> difference = firstIsSmallerOrEqual
      ? secondChord.where((e) => !firstSet.contains(e)).toList()
      : firstChord.where((e) => !secondSet.contains(e)).toList();

  if (difference.isNotEmpty) {
    for (final int element in difference) {
      if ((firstIsSmallerOrEqual &&
              (element > firstChord.first) &&
              (element < firstChord.last)) ||
          (!firstIsSmallerOrEqual &&
              (element > secondChord.first) &&
              (element < secondChord.last))) {
        return const [];
      }
    }
  }

  if (stemDirection == Stemdirection.down) {
    if ((firstChord.last > secondChord.last) ||
        (firstChord.first > secondChord.first)) {
      return const [];
    }
  } else {
    if ((firstChord.last < secondChord.last) ||
        (firstChord.first < secondChord.first)) {
      return const [];
    }
  }

  final List<int> intersection =
      firstChord.where((e) => secondSet.contains(e)).toList();
  if (intersection.isEmpty) return const [];
  for (int i = 0; i < intersection.length - 1; ++i) {
    if ((intersection[i] - intersection[i + 1]).abs() == 1) return const [];
  }
  return intersection;
}

/// Mirrors `Chord::AdjustOverlappingLayers`.
///
/// Deviation from the C++: none in behavior — [Chord.noteGroups] (built by
/// `PrepareLayerElementPartsFunctor`, preparedatafunctor.cpp:1155) backs the
/// `(margin < 0) && (m_noteGroups.size() > 0)` branch below.
/// Mirrors `m_noteGroups.size() > 0` (chord.cpp, via `Chord.noteGroups`).
bool _chordHasNoteGroups(Chord chord) => chord.noteGroups.isNotEmpty;

(int, bool, bool) _chordAdjustOverlappingLayers(
    Chord chord,
    Doc doc,
    List<LayerElement> otherElements,
    bool areDotsAdjusted,
    bool isUnison,
    bool stemSameas) {
  int margin = 0;
  final Set<int> otherElementLocations = {};
  for (final LayerElement element in otherElements) {
    if (element.classId == ClassId.note) {
      otherElementLocations.add((element as Note).drawingLoc);
    }
  }

  final List<Object> notes = chord.getList();
  final Set<int> chordElementLocations = {};
  for (final Object child in notes) {
    chordElementLocations.add((child as Note).drawingLoc);
  }

  final List<int> chordLocsSorted = chordElementLocations.toList()..sort();
  final List<int> otherLocsSorted = otherElementLocations.toList()..sort();
  final List<int> locationsInUnison = _getElementsInUnison(
      chordLocsSorted, otherLocsSorted, chord.getDrawingStemDir());

  final int expectedElementsInUnison = locationsInUnison.length;
  final bool isLowerPosition =
      (chord.getDrawingStemDir() == Stemdirection.down) &&
          otherLocsSorted.isNotEmpty &&
          (chordLocsSorted.first >= otherLocsSorted.first);
  int actualElementsInUnison = 0;

  for (final Object object in notes) {
    final Note note = object as Note;
    final (int overlap, bool isInUnison) = _calcElementHorizontalOverlap(
        note,
        doc,
        otherElements,
        areDotsAdjusted,
        true,
        isLowerPosition,
        expectedElementsInUnison > 0);
    if (((margin >= 0) && (overlap > margin)) ||
        ((margin <= 0) && (overlap < margin))) {
      margin = overlap;
    } else if ((margin < 0) && _chordHasNoteGroups(chord)) {
      margin = overlap;
    }
    if (isInUnison) ++actualElementsInUnison;
  }

  // If there are accidentals aligned for the layer separately, add margin
  // for them.
  int accidMargin = 0;
  for (final LayerElement iter in otherElements) {
    if (iter.classId != ClassId.note) continue;
    final Note note = iter as Note;
    final Accid? accid = note.getDrawingAccid();
    if (accid != null && accid.isAlignedWithSameLayer()) {
      accidMargin += accid.getContentRight() - accid.getContentLeft();
    }
  }
  if (accidMargin != 0) {
    accidMargin += (1.5 * doc.getDrawingUnit(100)).toInt();
  }

  if ((expectedElementsInUnison != 0) &&
      (expectedElementsInUnison == actualElementsInUnison)) {
    return (0, true, stemSameas);
  } else if (margin != 0) {
    margin -= accidMargin;
    chord.setDrawingXRel(chord.drawingXRel + margin);
    return (margin, isUnison, stemSameas);
  }
  return (0, isUnison, stemSameas);
}

/// Mirrors `LayerElement::AdjustOverlappingLayers` (virtual in the C++,
/// overridden by `Chord::AdjustOverlappingLayers`).
///
/// Returns `(shift, isUnison, stemSameas)`: Dart has no reference
/// out-parameters, so the two flags come back updated in the record instead
/// of being mutated in place — the caller ([AdjustLayersFunctor]) writes them
/// back into its own state fields exactly as the C++ mutates them in place.
(int, bool, bool) _adjustOverlappingLayers(
    LayerElement element,
    Doc doc,
    List<LayerElement> otherElements,
    bool areDotsAdjusted,
    bool isUnison,
    bool stemSameas) {
  if (element.classId == ClassId.note &&
      element.parent?.classId == ClassId.chord) {
    return (0, isUnison, stemSameas);
  } else if (element.classId == ClassId.stem && isUnison) {
    return (0, false, stemSameas);
  } else if (element.classId == ClassId.stem && stemSameas) {
    return (0, isUnison, false);
  }

  if (element is Chord) {
    return _chordAdjustOverlappingLayers(
        element, doc, otherElements, areDotsAdjusted, isUnison, stemSameas);
  }

  final (int margin, bool isInUnison) = _calcElementHorizontalOverlap(
      element, doc, otherElements, areDotsAdjusted, false);

  bool newIsUnison = isUnison;
  bool newStemSameas = stemSameas;
  if (element.classId == ClassId.note) {
    newIsUnison = isInUnison;
    if (newIsUnison) return (0, newIsUnison, newStemSameas);
    final Note note = element as Note;
    newStemSameas = note.hasStemSameasNote();
    if (newStemSameas) return (0, newIsUnison, newStemSameas);
  }

  if (element.isAny({ClassId.accid, ClassId.dots, ClassId.stem})) {
    final LayerElement parent = element.getFirstAncestorInRange(
        ClassId.layerElement, ClassId.layerElementMax) as LayerElement;
    parent.setDrawingXRel(parent.drawingXRel + margin);
  } else {
    element.setDrawingXRel(element.drawingXRel + margin);
  }
  return (margin, newIsUnison, newStemSameas);
}

/// Mirrors `Note::HandleLedgerLineStemCollision` (static in the C++).
bool _handleLedgerLineStemCollision(
    Doc doc, Staff staff, Note note1, Note note2) {
  if (note1.drawingLoc == note2.drawingLoc) return false;
  final bool note1IsUpper = note1.drawingLoc > note2.drawingLoc;
  final Note upperNote = note1IsUpper ? note1 : note2;
  final Note lowerNote = note1IsUpper ? note2 : note1;

  if (upperNote.getDrawingStemDir() != Stemdirection.down) return false;
  if (lowerNote.getDrawingStemDir() != Stemdirection.up) return false;

  final (_, int linesAboveUpper, int linesBelowUpper) =
      upperNote.hasLedgerLines(staff);
  final (_, int linesAboveLower, int linesBelowLower) =
      lowerNote.hasLedgerLines(staff);

  final int unit = doc.getDrawingUnit(staff.drawingStaffSize);

  if (linesBelowLower > linesBelowUpper) {
    final Object? upperChord = upperNote.isChordTone();
    final Stem? upperStem = upperChord is Chord
        ? upperChord.getDrawingStem()
        : upperNote.getDrawingStem();
    if (upperStem != null) {
      final int staffBottom =
          staff.getDrawingY() - 2 * unit * (staff.drawingLines - 1);
      final int stemBottom = upperStem.getSelfBottom();
      if (stemBottom < staffBottom - unit) return true;
    }
  }

  if (linesAboveUpper > linesAboveLower) {
    final Object? lowerChord = lowerNote.isChordTone();
    final Stem? lowerStem = lowerChord is Chord
        ? lowerChord.getDrawingStem()
        : lowerNote.getDrawingStem();
    if (lowerStem != null) {
      final int staffTop = staff.getDrawingY();
      final int stemTop = lowerStem.getSelfTop();
      if (stemTop > staffTop + unit) return true;
    }
  }

  return false;
}

extension _StemOverlapHelpers on Stem {
  /// Mirrors `Stem::CompareToElementPosition`.
  int compareToElementPosition(Doc doc, LayerElement otherElement, int margin) {
    final Staff staff = getAncestorStaffLayout();
    final int right = horizontalLeftOverlap(otherElement, margin, 0);
    final int left = horizontalRightOverlap(otherElement, margin, 0);
    if (right == 0 || left == 0) return 0;

    int horizontalMargin = 2 * doc.getDrawingStemWidth(staff.drawingStaffSize);
    final Flag? currentFlag =
        findDescendantByType(ClassId.flag, deepness: 1) as Flag?;
    if (currentFlag != null && currentFlag.drawingNbFlags != 0) {
      final int flagGlyph = currentFlag.getFlagGlyph(Stemdirection.down);
      final int flagWidth =
          doc.getGlyphWidth(flagGlyph, staff.drawingStaffSize, drawingCueSize);
      horizontalMargin += flagWidth;
    }

    if (right < left) {
      return right + horizontalMargin;
    } else {
      return -horizontalMargin - left;
    }
  }
}

extension _FlagGlyphHelpers on Flag {
  /// Mirrors `Flag::GetFlagGlyph`.
  int getFlagGlyph(Stemdirection stemDir) {
    if (stemDir == Stemdirection.up) {
      switch (drawingNbFlags) {
        case 1:
          return smuflE240Flag8thUp;
        case 2:
          return smuflE242Flag16thUp;
        case 3:
          return smuflE244Flag32ndUp;
        case 4:
          return smuflE246Flag64thUp;
        case 5:
          return smuflE248Flag128thUp;
        case 6:
          return smuflE24AFlag256thUp;
        case 7:
          return smuflE24CFlag512thUp;
        case 8:
          return smuflE24EFlag1024thUp;
        default:
          return 0;
      }
    } else {
      switch (drawingNbFlags) {
        case 1:
          return smuflE241Flag8thDown;
        case 2:
          return smuflE243Flag16thDown;
        case 3:
          return smuflE245Flag32ndDown;
        case 4:
          return smuflE247Flag64thDown;
        case 5:
          return smuflE249Flag128thDown;
        case 6:
          return smuflE24BFlag256thDown;
        case 7:
          return smuflE24DFlag512thDown;
        case 8:
          return smuflE24FFlag1024thDown;
        default:
          return 0;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// AdjustLayersFunctor
// ---------------------------------------------------------------------------

/// Adjusts the position of notes and chords for multiple layers (mirrors
/// `vrv::AdjustLayersFunctor`).
class AdjustLayersFunctor extends DocFunctor {
  AdjustLayersFunctor(super.doc);

  /// The list of staffN in the top-level scoreDef (mirrors `m_staffNs`).
  List<int> staffNs = [];

  /// The current layerN set in the AlignmentRef, negative for cross-staff
  /// (mirrors `m_currentLayerN`).
  int currentLayerN = meiUnset;

  /// The elements for the previous layer(s) (mirrors `m_previous`).
  final List<LayerElement> previous = [];

  /// The elements of the current layer (mirrors `m_current`).
  final List<LayerElement> current = [];

  /// Whether the element is in unison (mirrors `m_unison`).
  bool unison = false;

  /// Whether dots should be ignored (mirrors `m_ignoreDots`).
  bool ignoreDots = true;

  /// Whether the element (note) has a stem.sameas note (mirrors
  /// `m_stemSameas`).
  bool stemSameas = false;

  /// The total shift of the current note or chord (mirrors
  /// `m_accumulatedShift`).
  int accumulatedShift = 0;

  /// Mirrors `IgnoreDots(bool)`.
  void setIgnoreDots(bool value) => ignoreDots = value;

  @override
  FunctorCode visitAlignmentReference(AlignmentReference alignmentReference) {
    if (!alignmentReference.hasMultipleLayer()) return FunctorCode.siblings;

    currentLayerN = meiUnset;
    current.clear();
    previous.clear();
    accumulatedShift = 0;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitAlignmentReferenceEnd(
      AlignmentReference alignmentReference) {
    // Determine staff.
    if (current.isEmpty) return FunctorCode.continue_;
    final LayerElement firstElem = current.first;
    final Staff staff = firstElem.getAncestorStaffResolveCrossStaff()!;

    final int extension = doc.getDrawingLedgerLineExtension(
        staff.drawingStaffSize, firstElem.drawingCueSize);

    if ((accumulatedShift.abs() < 2 * extension) && ignoreDots) {
      // Check each pair of notes from different layers for possible
      // collisions of ledger lines with note stems.
      final bool handleLedgerLineStemCollision = current.any((currentElem) {
        if (currentElem.classId != ClassId.note) return false;
        final Note currentNote = currentElem as Note;
        return previous.any((previousElem) {
          if (previousElem.classId != ClassId.note) return false;
          final Note previousNote = previousElem as Note;
          return _handleLedgerLineStemCollision(
              doc, staff, currentNote, previousNote);
        });
      });

      // To avoid collisions shift the chord or note to the left.
      if (handleLedgerLineStemCollision) {
        Note? itElem;
        for (final LayerElement e in current) {
          if (e.classId == ClassId.note) {
            itElem = e as Note;
            break;
          }
        }
        final Object? chord = itElem!.isChordTone();
        final LayerElement element = chord is Chord ? chord : itElem;

        final int shift = 2 * extension - accumulatedShift.abs();
        element.setDrawingXRel(element.drawingXRel - shift);
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    // Check if we are starting a new layer - if yes copy the current
    // elements to previous.
    if (current.isNotEmpty &&
        (layerElement.getAlignmentLayerN() != currentLayerN)) {
      previous.addAll(current);
      current.clear();
    }

    currentLayerN = layerElement.getAlignmentLayerN();

    // These are the only ones we want to keep for further collision
    // detection.
    if (layerElement.hasSelfBB()) {
      if (layerElement.isAny({ClassId.note, ClassId.stem})) {
        current.add(layerElement);
      } else if (!ignoreDots && layerElement.classId == ClassId.dots) {
        current.add(layerElement);
      }
    }

    // We are processing the first layer, nothing to do yet.
    if (previous.isEmpty) return FunctorCode.siblings;

    final (int shift, bool newUnison, bool newStemSameas) =
        _adjustOverlappingLayers(
            layerElement, doc, previous, !ignoreDots, unison, stemSameas);
    unison = newUnison;
    stemSameas = newStemSameas;
    accumulatedShift += shift;

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    if (!measure.getHasAlignmentRefWithMultipleLayers()) {
      return FunctorCode.siblings;
    }

    final Filters filters = Filters();
    final Filters? previousFilters = setFilters(filters);

    for (final int n in staffNs) {
      filters.clear();
      // Create ad comparison object for each type / @n; barlineReferences
      // for barline attributes that need to be taken into account each time.
      filters.add(AttNIntegerAnyComparison(
          ClassId.alignmentReference, [barlineReferences, n]));

      measure.measureAligner.process(this);
    }

    setFilters(previousFilters);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    if (system.drawingScoreDef != null) {
      staffNs = system.drawingScoreDef!.getStaffNs();
    }

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// AdjustDotsFunctor
// ---------------------------------------------------------------------------

/// Adjusts the position of the augmentation dots for multiple layers
/// (mirrors `vrv::AdjustDotsFunctor`).
class AdjustDotsFunctor extends DocFunctor {
  AdjustDotsFunctor(super.doc);

  /// The list of staffN in the top-level scoreDef (mirrors `m_staffNs`).
  List<int> staffNs = [];

  /// All elements (except dots) for the alignment in the staff (mirrors
  /// `m_elements`).
  final List<LayerElement> elements = [];

  /// All dots for the alignment in the staff (mirrors `m_dots`).
  final List<Dots> dots = [];

  @override
  FunctorCode visitAlignmentEnd(Alignment alignment) {
    // Process dots only if there is at least 1 dot (vertical group) in the
    // alignment.
    if (elements.isNotEmpty && dots.isNotEmpty) {
      // Multimap of overlapping dots with other elements, grouped by dots
      // (mirrors `std::multimap<LayerElement *, LayerElement *>`).
      final Map<Dots, List<LayerElement>> overlapElements = {};

      // Try to find which dots can be grouped together. To achieve this,
      // find layer elements that collide with these dots. Then find if
      // their parents (note/chord) have dots - if they do then we can group
      // these dots together, otherwise they should be kept separate.
      for (final Dots dot in dots) {
        // A third staff size will be used as required margin.
        final Staff staff = dot.getAncestorStaffResolveCrossStaff()!;
        final int staffSize = staff.drawingStaffSize;
        final int thirdUnit = doc.getDrawingUnit(staffSize) ~/ 3;

        for (final LayerElement element in elements) {
          if (dot.horizontalSelfOverlap(element, thirdUnit) &&
              dot.verticalSelfOverlap(element, 2 * thirdUnit)) {
            if (element.isAny({ClassId.chord, ClassId.note})) {
              final int elementDots = element is Chord
                  ? (element.dots ?? meiUnset)
                  : ((element as Note).dots ?? meiUnset);
              if (elementDots < 1) continue;
              overlapElements.putIfAbsent(dot, () => []).add(element);
            } else {
              final Object? chordAncestor =
                  element.getFirstAncestor(ClassId.chord);
              if (chordAncestor != null) {
                if (chordAncestor is Chord &&
                    (chordAncestor.dots ?? meiUnset) >= 1) {
                  overlapElements.putIfAbsent(dot, () => []).add(chordAncestor);
                }
              } else {
                final Object? noteAncestor =
                    element.getFirstAncestor(ClassId.note);
                if (noteAncestor is Note &&
                    (noteAncestor.dots ?? meiUnset) >= 1) {
                  overlapElements.putIfAbsent(dot, () => []).add(noteAncestor);
                }
              }
            }
          }
        }
      }

      // If at least one overlapping element has been found, make sure to
      // adjust the relative positioning of the dots in the group to the
      // rightmost one.
      if (overlapElements.isNotEmpty) {
        for (final Dots dot in dots) {
          final List<LayerElement> group = overlapElements[dot] ?? const [];
          int max = 0;
          for (final LayerElement other in group) {
            final int diff =
                other.getDrawingX() + dot.drawingXRel - dot.getDrawingX();
            if (diff > max) max = diff;
          }
          if (max != 0) dot.setDrawingXRel(dot.drawingXRel + max);
          dot.setIsAdjusted();
        }
      }
    }

    elements.clear();
    dots.clear();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.classId == ClassId.note &&
        layerElement.parent?.classId == ClassId.chord) {
      return FunctorCode.siblings;
    }
    if (layerElement.classId == ClassId.dots) {
      dots.add(layerElement as Dots);
    } else {
      elements.add(layerElement);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    if (!measure.getHasAlignmentRefWithMultipleLayers()) {
      return FunctorCode.siblings;
    }

    final Filters filters = Filters();
    final Filters? previousFilters = setFilters(filters);

    for (final int n in staffNs) {
      filters.clear();
      filters.add(AttNIntegerAnyComparison(
          ClassId.alignmentReference, [barlineReferences, n]));

      measure.measureAligner.process(this);
    }

    setFilters(previousFilters);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    if (system.drawingScoreDef != null) {
      staffNs = system.drawingScoreDef!.getStaffNs();
    }

    return FunctorCode.continue_;
  }
}
