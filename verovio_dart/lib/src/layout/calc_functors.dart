/// Headless-capable ports of the Calc* drawing functors that share the role
/// of `preparedatafunctor.cpp`:
///
/// - [CalcStemFunctor] mirrors `calcstemfunctor.cpp` (direction + length)
/// - [CalcChordNoteHeadsFunctor] mirrors `calcchordnoteheadsfunctor.cpp`
/// - [CalcDotsFunctor] mirrors `calcdotsfunctor.cpp`
/// - [CalcArticFunctor] mirrors `calcarticfunctor.cpp`
/// - [CalcSlurDirectionFunctor] mirrors `calcslurdirectionfunctor.cpp`
///
/// Deviations from the C++ (all required because there is no rendering pass
/// with glyph metrics and staff drawing positions at this stage):
/// - Absolute Y comparisons are replaced by staff-relative locations: a note
///   "below the middle line" means `drawingLoc < lines - 1`, which is
///   equivalent for stem direction purposes.
/// - The drawing loc of notes is computed on the fly from @pname / @oct and
///   the current clef (the C++ receives it from CalcAlignmentPitchPosFunctor;
///   setting it here is idempotent with that functor).
/// - Stem lengths use `CalcStemLenInThirdUnits` without the glyph-based flag
///   shortening / ledger-line adjustments.
library;

// ignore_for_file: unused_shown_name

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration, meiUnset;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/point.dart' show Point;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/beam_segment.dart' show BeamElementCoord;
import 'package:verovio_dart/src/model/control_elements_gen.dart'
    show BeamSpan, Slur;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';

// ---------------------------------------------------------------------------
// CalcStemFunctor
// ---------------------------------------------------------------------------

/// Calculate the stem direction and length of notes, chords and tabDurSym
/// (headless port of `vrv::CalcStemFunctor`).
class CalcStemFunctor extends DocFunctor {
  CalcStemFunctor(super.doc);

  /// The chord stem length in half units (mirrors `m_chordStemLength`).
  int chordStemLength = 0;

  /// The middle line loc of the current staff; replaces the C++
  /// `m_verticalCenter` absolute position.
  int verticalCenterLoc = 0;

  /// The duration of the element owning the current stem (mirrors `m_dur`).
  MeiDuration dur = MeiDuration.dur1;

  bool isGraceNote = false;

  @override
  FunctorCode visitBeam(Beam beam) {
    // Mirrors `CalcStemFunctor::VisitBeam` (calcstemfunctor.cpp:44).
    final List<Object> beamChildren = beam.getList();
    if (beamChildren.isEmpty) return FunctorCode.continue_;
    Layer? layer = beam.getFirstAncestor(ClassId.layer) as Layer?;
    Staff? staff = layer?.getFirstAncestor(ClassId.staff) as Staff?;
    if (layer == null || staff == null) return FunctorCode.continue_;
    if (beam.beamElementCoordsOwned.isEmpty) {
      beam.initCoords(beamChildren, staff, beam.drawingPlace);
      final bool isCue =
          (beam.cue == true) || beam.getFirstAncestor(ClassId.graceGrp) != null;
      beam.initCue(isCue);
      beam.initGraceStemDir(beam.getFirstAncestor(ClassId.graceGrp) != null);
    }
    if (beam.isTabBeam()) return FunctorCode.continue_;
    final segment = beam.beamSegment;
    segment.initCoordRefs(beam.beamElementCoordsOwned.cast<BeamElementCoord>());
    // C++: `data_BEAMPLACE initialPlace = beam->GetPlace()` — the encoded
    // @place, never the computed drawingPlace (calcstemfunctor.cpp:69).
    Beamplace initialPlace = beam.place ?? Beamplace.none;
    if (beam.hasStemSameasBeam()) {
      segment.initSameasRoles(beam.stemSameasBeam, initialPlace);
    }
    segment.calcBeam(layer, staff, doc, beam, initialPlace);
    if (beam.hasStemSameasBeam()) {
      segment.calcNoteHeadShiftForStemSameas(beam.stemSameasBeam, initialPlace);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitChord(Chord chord) {
    // Stems have been calculated previously in beam or fTrem.
    if (_isInBeam(chord) || chord.getFirstAncestor(ClassId.fTrem) != null) {
      return FunctorCode.siblings;
    }

    // If the chord isn't visible, carry on.
    if (!chord.layoutIsVisible() || chord.stemVisible == false) {
      return FunctorCode.siblings;
    }

    final dynamic stem = chord.getDrawingStem();
    if (stem == null) return FunctorCode.continue_;

    Staff staff = chord.getAncestorStaffLayout();
    Layer? layer = chord.getFirstAncestor(ClassId.layer) as Layer?;

    if (chord.crossStaff is Staff) {
      staff = chord.crossStaff as Staff;
      if (chord.crossLayer is Layer) layer = chord.crossLayer as Layer;
    }

    dur = chord.getActualDur();
    isGraceNote = chord.isGraceNote();

    // Mirrors Chord::GetYExtremes: the list is sorted by pitch so the front
    // note is the bottom one and the back note the top one. In headless mode
    // we work with locations instead of absolute Y values.
    final List<Object> childList = chord.getList();
    assert(childList.isNotEmpty);
    final Note bottomNote = childList.first as Note;
    final Note topNote = childList.last as Note;
    final int bottomLoc = bottomNote.calcDrawingLocHeadless();
    final int topLoc = topNote.calcDrawingLocHeadless();
    // yMin - yMax in the C++ corresponds to -(span) * doubleUnit.
    chordStemLength = -(topLoc - bottomLoc) *
        doc.getDrawingDoubleUnit(staff.drawingStaffSize);
    verticalCenterLoc = _middleLineLoc(staff);

    /************ Set the direction ************/

    Stemdirection stemDir = Stemdirection.none;

    if ((stem.dir as Stemdirection?) != null &&
        stem.dir != Stemdirection.none) {
      stemDir = stem.dir as Stemdirection;
    } else if (layer != null &&
        _getLayerStemDir(layer, chord) != Stemdirection.none) {
      stemDir = _getLayerStemDir(layer, chord);
    } else {
      stemDir = _calcChordStemDirection(chord, childList);
    }

    chord.setDrawingStemDir(stemDir);

    // Position the stem to the bottom note when up and to the top note when
    // down (relative value in headless mode).
    if (stemDir == Stemdirection.up) {
      stem.setDrawingYRel(bottomLoc - topLoc);
    } else {
      stem.setDrawingYRel(0);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitFTrem(FTrem fTrem) {
    // Mirrors `CalcStemFunctor::VisitFTrem` (calcstemfunctor.cpp:175).
    final List<Object> children =
        fTrem.children.where((c) => c.isLayerElement).toList();
    if (children.isEmpty) return FunctorCode.continue_;
    Layer? layer = fTrem.getFirstAncestor(ClassId.layer) as Layer?;
    Staff? staff = layer?.getFirstAncestor(ClassId.staff) as Staff?;
    if (layer == null || staff == null) return FunctorCode.continue_;
    if (fTrem.beamElementCoordsOwned.isEmpty) {
      fTrem.initCoords(children, staff, Beamplace.none);
      fTrem.initCue(false);
    }
    if (fTrem.beamElementCoordsOwned.length != 2) {
      logDebug('Stem calculation: <fTrem> element has invalid number of descendants.');
      return FunctorCode.continue_;
    }
    final segment = fTrem.beamSegment;
    segment.initCoordRefs(fTrem.beamElementCoordsOwned.cast<BeamElementCoord>());
    segment.calcBeam(layer, staff, doc, fTrem, Beamplace.none);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitBeamSpan(BeamSpan beamSpan) {
    // BeamSpan calc during CalcStem is still deferred (same as 05-30) to keep
    // BBox parity stable; the View will calc via BeamSegment.calcBeam.
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    if (!note.layoutIsVisible() || note.stemVisible == false) {
      return FunctorCode.siblings;
    }

    // Stems have been calculated previously in Beam or fTrem.
    if (_isInBeam(note) || note.getFirstAncestor(ClassId.fTrem) != null) {
      return FunctorCode.siblings;
    }

    // We do not need to calc stems for mensural notes. We have no stem with
    // tab because it belongs to tabDurSym in this case.
    if (note.isMensuralDur || _isTabGrpNote(note)) {
      return FunctorCode.siblings;
    }

    if (note.isChordTone() != null) {
      return FunctorCode.continue_;
    }

    // This now should be NULL and the chord stem length will be 0.
    chordStemLength = 0;

    final dynamic stem = note.getDrawingStem();
    if (stem == null) return FunctorCode.continue_;

    Staff staff = note.getAncestorStaffLayout();
    Layer? layer = note.getFirstAncestor(ClassId.layer) as Layer?;

    if (note.crossStaff is Staff) {
      staff = note.crossStaff as Staff;
      if (note.crossLayer is Layer) layer = note.crossLayer as Layer;
    }

    dur = note.getActualDur();
    isGraceNote = note.isGraceNote();

    final int loc = note.calcDrawingLocHeadless();
    verticalCenterLoc = _middleLineLoc(staff);

    /************ Set the direction ************/

    Stemdirection stemDir = Stemdirection.none;

    if (note.hasStemSameasNote()) {
      stemDir = note.stemDir ?? Stemdirection.none;
    } else if ((stem.dir as Stemdirection?) != null &&
        stem.dir != Stemdirection.none) {
      stemDir = stem.dir as Stemdirection;
    } else if (isGraceNote) {
      stemDir = Stemdirection.up;
    } else if (layer != null &&
        _getLayerStemDir(layer, note) != Stemdirection.none) {
      stemDir = _getLayerStemDir(layer, note);
    } else {
      // GetDrawingY() >= verticalCenter <=> loc <= middle line.
      stemDir =
          loc >= verticalCenterLoc ? Stemdirection.down : Stemdirection.up;
    }

    note.setDrawingStemDir(stemDir);

    // Make sure the relative position of the stem is the same.
    stem.setDrawingYRel(0);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    final List<Object> layers =
        staff.findAllDescendantsByType(ClassId.layer, deepness: 1);
    if (layers.isEmpty) {
      return FunctorCode.continue_;
    }

    // Not more than one layer - drawing stem dir remains unset unless there
    // is cross-staff content.
    if (layers.length < 2) {
      final Layer layer = layers.first as Layer;
      if (layer.hasCrossStaffFromBelow()) {
        layer.setDrawingStemDir(Stemdirection.up);
      } else if (layer.hasCrossStaffFromAbove()) {
        layer.setDrawingStemDir(Stemdirection.down);
      }
      return FunctorCode.continue_;
    }

    for (final Object object in layers) {
      // Alter stem direction between even and odd numbered layers.
      final Layer layer = object as Layer;
      layer.setDrawingStemDir(
          (layer.n ?? 0).isOdd ? Stemdirection.up : Stemdirection.down);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStem(Stem stem) {
    final Staff? staff =
        (stem.parent is LayerElement ? stem.getAncestorStaffLayout() : null);
    if (staff == null) return FunctorCode.continue_;
    final LayerElement parent = stem.parent as LayerElement;

    final int stemShift = doc.getDrawingStemWidth(staff.drawingStaffSize) ~/ 2;

    // For notes longer than half notes the stem is always 0.
    if (dur.value < MeiDuration.dur2.value) {
      stem.drawingXRel = 0;
      stem.drawingYRel = 0;
      stem.setDrawingStemLen(0);
      return FunctorCode.continue_;
    }

    /************ Set the length ************/

    final Stemdirection stemDir = stem.getDrawingStemDir();
    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    int baseStem = 0;
    // Use the given one if any.
    if (stem.len != null) {
      baseStem = -(stem.len!.vu.toInt() * unit);
    }
    // Do not adjust the baseStem for stem sameas notes (its length is in
    // m_chordStemLength).
    else {
      final int thirdUnit = unit ~/ 3 == 0 ? 1 : unit ~/ 3;
      final int thirdUnits =
          parent.calcStemLenInThirdUnitsHeadless(staff, stemDir);
      baseStem = -(thirdUnits * thirdUnit);
      if (stem.drawingCueSize) {
        baseStem = doc.getCueSize(baseStem);
      }
    }
    // Even if a stem length is given we add the length of the chord content
    // (however only if not 0). Also, the given stem length is understood as
    // being measured from the center of the note; it is adjusted according
    // to the note head (mirrors calcstemfunctor.cpp:379-405).
    if (stem.len == null || stem.len!.vu.toInt() != 0) {
      Point p;
      if (stemDir == Stemdirection.up) {
        if (_stemPos(stem) == Stemposition.left) {
          p = _stemAnchor(doc, parent, staff, false, stem.drawingCueSize);
          p.x += stemShift;
        } else {
          p = _stemAnchor(doc, parent, staff, true, stem.drawingCueSize);
          p.x -= stemShift;
        }
        final int stemShortening = p.y;
        stem.setDrawingStemLen(baseStem + chordStemLength + stemShortening);
      } else {
        if (_stemPos(stem) == Stemposition.right) {
          p = _stemAnchor(doc, parent, staff, true, stem.drawingCueSize);
          p.x -= stemShift;
        } else {
          p = _stemAnchor(doc, parent, staff, false, stem.drawingCueSize);
          p.x += stemShift;
        }
        final int stemShortening = p.y;
        stem.setDrawingStemLen(-(baseStem + chordStemLength - stemShortening));
      }
      stem.drawingYRel = stem.drawingYRel + p.y;
      stem.drawingXRel = p.x;
    }

    /************ Flags ************/

    // There is never a flag with a duration longer than 8th notes.
    if (dur.value > MeiDuration.dur4.value) {
      final Flag? flag = stem.getFirst(ClassId.flag) as Flag?;
      if (flag != null) {
        flag.drawingNbFlags = dur.value - MeiDuration.dur4.value;
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTabGrp(TabGrp tabGrp) {
    dur = tabGrp.getActualDur();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitTabDurSym(TabDurSym tabDurSym) {
    // Stems have been calculated previously in Beam.
    if (_isInBeam(tabDurSym)) {
      return FunctorCode.siblings;
    }

    final dynamic stem = tabDurSym.getDrawingStem();
    if (stem == null) return FunctorCode.siblings;

    // Do not draw virtual (e.g., whole note) stems.
    if (dur.value < MeiDuration.dur2.value) {
      stem.setIsVirtual(true);
      return FunctorCode.siblings;
    }

    // Cache to avoid further lookup.
    final Staff staff = tabDurSym.getAncestorStaffLayout();

    /************ Set the direction ************/

    // Up by default with tablature.
    Stemdirection stemDir = Stemdirection.up;

    if ((stem.dir as Stemdirection?) != null &&
        stem.dir != Stemdirection.none) {
      stemDir = stem.dir as Stemdirection;
    }

    tabDurSym.setDrawingStemDir(stemDir);

    final int thirdUnits =
        tabDurSym.calcStemLenInThirdUnitsHeadless(staff, stemDir);
    int stemSize = thirdUnits * doc.getDrawingUnit(staff.drawingStaffSize);
    stemSize = stemSize ~/ 3;

    if (dur == MeiDuration.dur2) {
      // Stems for half notes twice shorter.
      stemSize = stemSize ~/ 2;
    }

    stem.setDrawingStemLen(stemSize);

    // Do not call VisitStem with TabDurSym because everything is done here.
    return FunctorCode.siblings;
  }

  /// Mirrors `CalcStemFunctor::CalcStemDirection` with locations instead of
  /// absolute Y values.
  Stemdirection _calcChordStemDirection(Chord chord, List<Object> childList) {
    // Notes are sorted by pitch: index 0 is the bottom note.
    final List<int> locs = [
      for (final Object object in childList)
        (object as Note).calcDrawingLocHeadless(),
    ];

    // Split notes into two vectors - above the center and below.
    final List<int> topNotes =
        locs.where((loc) => loc > verticalCenterLoc).toList();
    final List<int> bottomNotes =
        locs.where((loc) => loc <= verticalCenterLoc).toList();

    int bottomIdx = 0;
    int topIdx = topNotes.length - 1;
    while (bottomIdx < bottomNotes.length && topIdx >= 0) {
      final int bottomY = bottomNotes[bottomIdx];
      final int topY = topNotes[topIdx];
      final int middlePoint = (topY + bottomY) ~/ 2;

      // If notes are equidistant - proceed to the next pair of notes.
      if (middlePoint == verticalCenterLoc) {
        ++bottomIdx;
        --topIdx;
        continue;
      }
      // Otherwise return corresponding stem direction.
      else if (middlePoint > verticalCenterLoc) {
        return Stemdirection.down;
      } else {
        return Stemdirection.up;
      }
    }

    // If there are still unprocessed notes left on the bottom that are not on
    // the center - stem direction should be up.
    if (bottomIdx < bottomNotes.length &&
        bottomNotes[bottomIdx] != verticalCenterLoc) {
      return Stemdirection.up;
    }
    // Otherwise place it down.
    return Stemdirection.down;
  }

  /// Return the layer stem direction for an element; NONE unless the layer
  /// got a direction from the multi-layer / cross-staff pass.
  Stemdirection _getLayerStemDir(Layer layer, LayerElement element) =>
      layer.getDrawingStemDir();

  static bool _isInBeam(LayerElement element) =>
      element.getFirstAncestor(ClassId.beam) != null || element.isInBeamSpan;

  static bool _isTabGrpNote(LayerElement element) =>
      element.getFirstAncestor(ClassId.tabGrp) != null;

  /// Loc of the middle staff line (0 being the bottom line).
  static int _middleLineLoc(Staff staff) => staff.drawingLines - 1;

  /// Mirrors `Stem::GetPos()` (AttStemVis `@pos`; NONE unless set).
  Stemposition _stemPos(Stem stem) => stem.pos ?? Stemposition.none;

  /// The notehead anchor point used to position the stem (mirrors the
  /// `m_interface->GetStemUpSE` / `GetStemDownNW` calls in
  /// CalcStemFunctor::VisitStem): a note uses its own glyph anchor; a chord
  /// delegates to its bottom note for the SE point and top note for the NW
  /// point (chord.cpp:358-370).
  Point _stemAnchor(
      dynamic doc, LayerElement parent, Staff staff, bool up, bool cueSize) {
    if (parent is Note) {
      return up
          ? parent.getStemUpSE(doc, staff.drawingStaffSize, cueSize)
          : parent.getStemDownNW(doc, staff.drawingStaffSize, cueSize);
    }
    if (parent is Chord) {
      final List<Object> childList = parent.getList();
      if (childList.isNotEmpty) {
        final Note note = (up ? childList.first : childList.last) as Note;
        return up
            ? note.getStemUpSE(doc, staff.drawingStaffSize, cueSize)
            : note.getStemDownNW(doc, staff.drawingStaffSize, cueSize);
      }
    }
    return Point(0, 0);
  }
}

// ---------------------------------------------------------------------------
// CalcChordNoteHeadsFunctor
// ---------------------------------------------------------------------------

/// Adjust the noteheads of the notes within chords (headless port of
/// `vrv::CalcChordNoteHeadsFunctor`). Without glyph metrics only the flipped
/// notehead logic of note groups applies; the diameter based shifts are
/// skipped since they depend on the SMuFL widths.
class CalcChordNoteHeadsFunctor extends DocFunctor {
  CalcChordNoteHeadsFunctor(super.doc);

  AlignmentType alignmentType = AlignmentType.measureStart;

  @override
  FunctorCode visitChord(Chord chord) {
    if (chord.getDrawingStemDir() == Stemdirection.up) {
      alignmentType = chord.getAlignment()?.getType() ?? AlignmentType.default_;
      // Mark the chord tone locations so the note visits can compute the
      // shifts (diameter based positioning requires glyphs).
      for (final Object child in chord.getList()) {
        (child as Note).calcDrawingLocHeadless();
      }
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    // Nothing to calculate if note is not part of the chord.
    if (note.isChordTone() == null) return FunctorCode.siblings;

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// CalcDotsFunctor
// ---------------------------------------------------------------------------

/// Compute the optimal dot locations of the dotted elements (headless port
/// of `vrv::CalcDotsFunctor`; the xRel shifts depending on glyph widths are
/// skipped).
class CalcDotsFunctor extends DocFunctor {
  CalcDotsFunctor(super.doc);

  Dots? chordDots;
  Stemdirection chordStemDir = Stemdirection.none;

  @override
  FunctorCode visitChord(Chord chord) {
    // If the chord isn't visible, stop here.
    if (!chord.layoutIsVisible()) {
      return FunctorCode.siblings;
    }
    // If there aren't dot, stop here but only if no note has a dot.
    if ((chord.dots ?? 0) < 1) {
      if (!chord.getList().any((Object note) => (note as Note).dots != null)) {
        return FunctorCode.siblings;
      } else {
        return FunctorCode.continue_;
      }
    }

    final Dots? dots =
        chord.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;
    assert(dots != null);

    chordDots = dots;
    chordStemDir = chord.getDrawingStemDir();

    dots!.setMapOfDotLocs(chord.calcOptimalDotLocations());

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    if (!note.layoutIsVisible()) {
      return FunctorCode.siblings;
    }

    final Chord? chord = note.isChordTone() as Chord?;

    if (chord != null && (chord.dots ?? 0) > 0) {
      // For chord tones the chord dots already hold the shared locations.
      return FunctorCode.siblings;
    }
    if ((note.dots ?? 0) > 0) {
      // For single notes we need here to set the dot loc.
      final Dots? dots =
          note.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;
      assert(dots != null);

      dots!.setMapOfDotLocs(_noteOptimalDotLocations(note));
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitRest(Rest rest) {
    // We currently have no dots object with mensural rests.
    if (rest.isMensuralDur) {
      return FunctorCode.siblings;
    }

    // Nothing to do.
    if ((rest.dur?.value ?? MeiDuration.none.value) <=
            MeiDuration.breve.value ||
        (rest.dots ?? 0) < 1) {
      return FunctorCode.siblings;
    }

    final Staff staff = rest.getAncestorStaffLayout();

    // For single rests we need here to set the dot loc.
    final Dots? dots =
        rest.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;
    assert(dots != null);

    final Set<int> dotLocs = dots!.modifyDotLocsForStaff(staff);
    int loc = rest.calcDrawingLocHeadless();

    // If it's on a staff line to start with, we need to compensate here and
    // add a full unit like DrawDots would.
    if (loc.isEven) {
      loc += 1;
    }

    switch (rest.getActualDur().value) {
      case 6: // 32
      case 7: // 64
        loc += 2;
        break;
      case 8: // 128
      case 9: // 256
        loc += 4;
        break;
      case 10: // 512
        loc += 6;
        break;
      case 11: // 1024
        loc += 8;
        break;
      default:
        break;
    }

    dotLocs.add(loc);

    return FunctorCode.siblings;
  }

  /// Simplified port of `Note::CalcOptimalDotLocations`: single staff, dot
  /// goes to a free space next to the note loc.
  static Map<Object, Set<int>> _noteOptimalDotLocations(Note note) {
    final Map<Object, Set<int>> noteLocations = {};
    final Staff staff = note.getAncestorStaffLayout();
    int loc = note.calcDrawingLocHeadless();
    // Shift odd locs up one step so dots sit within a space.
    if (!loc.isEven) {
      loc += 1;
    }
    noteLocations[staff] = {loc};
    return noteLocations;
  }
}

// ---------------------------------------------------------------------------
// Chord helper for dot locations
// ---------------------------------------------------------------------------

extension ChordDotLocations on Chord {
  /// Simplified port of `Chord::CalcOptimalDotLocations` for a single staff:
  /// collects the note locs and resolves conflicts by shifting up.
  Map<Object, Set<int>> calcOptimalDotLocations() {
    final Map<Object, Set<int>> locations = {};
    final Staff staff = getAncestorStaffLayout();
    final Set<int> locs = {};
    for (final Object child in getList()) {
      final Note note = child as Note;
      int loc = note.calcDrawingLocHeadless();
      if (!loc.isEven) loc += 1;
      // Avoid duplicates within the chord by shifting up.
      while (locs.contains(loc)) {
        loc += 2;
      }
      locs.add(loc);
    }
    locations[staff] = locs;
    return locations;
  }
}

// ---------------------------------------------------------------------------
// CalcArticFunctor
// ---------------------------------------------------------------------------

/// Set the drawing place of articulations (headless port of
/// `vrv::CalcArticFunctor`; cross-staff extremes and beam places are not
/// resolved at this stage).
class CalcArticFunctor extends DocFunctor {
  CalcArticFunctor(super.doc);

  LayerElement? parent;
  Stemdirection stemDir = Stemdirection.none;

  @override
  FunctorCode visitArtic(Artic artic) {
    if (parent == null) return FunctorCode.continue_;

    /************** placement **************/

    Layer? layer = artic.getFirstAncestor(ClassId.layer) as Layer?;

    if (parent!.crossLayer is Layer) {
      layer = parent!.crossLayer as Layer;
    }

    // For now we ignore within @place.
    if (artic.place != null && artic.place != Staffrel.none) {
      artic.drawingPlace = artic.place!;
      // if we have a place indication do not allow to be changed to above
      // allowAbove = false; (see C++ calcarticfunctor.cpp:58-61)
    } else if (layer != null &&
        layer.getDrawingStemDirFor(parent!) != Stemdirection.none) {
      artic.drawingPlace = layer.getDrawingStemDirFor(parent!) ==
              Stemdirection.up
          ? Staffrel.above
          : Staffrel.below;
      // If we have more than one layer do not allow to be changed to above
      // allowAbove = false; (see C++ calcarticfunctor.cpp:63-66)
    } else if (stemDir == Stemdirection.up) {
      artic.drawingPlace = Staffrel.below;
    } else {
      artic.drawingPlace = Staffrel.above;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitChord(Chord chord) {
    parent = chord;
    stemDir = chord.getDrawingStemDir();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    if (note.isChordTone() != null) return FunctorCode.continue_;

    parent = note;
    stemDir = note.getDrawingStemDir();

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// CalcSlurDirectionFunctor
// ---------------------------------------------------------------------------

/// Compute the curve direction of slurs (headless port of
/// `vrv::CalcSlurDirectionFunctor`; mixed-stem handling across systems and
/// cross-staff preferences require the rendering layout and are reduced to
/// the boundary checks that work without it).
class CalcSlurDirectionFunctor extends DocFunctor {
  CalcSlurDirectionFunctor(super.doc);

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSlur(Slur slur) {
    // If curve direction is prescribed as above or below, use it.
    if (slur.hasCurvedir && slur.curvedir != CurvatureCurvedir.mixed) {
      slur.setDrawingCurveDir(slur.curvedir == CurvatureCurvedir.above
          ? SlurCurveDirection.above
          : SlurCurveDirection.below);
    }
    if (slur.hasDrawingCurveDir()) return FunctorCode.continue_;

    // Retrieve boundary.
    final LayerElement? start = slur.getStart();
    final LayerElement? end = slur.getEnd();
    if (start == null || end == null) {
      slur.setDrawingCurveDir(SlurCurveDirection.above);
      return FunctorCode.continue_;
    }

    // If curve direction is prescribed as mixed, use it if boundary lies in
    // different staves.
    if (slur.curvedir == CurvatureCurvedir.mixed) {
      if (slur.hasBulge) {
        logWarning('Mixed curve direction is ignored for slurs with '
            'prescribed bulge.');
      } else if (start.classId == ClassId.timestampAttr ||
          end.classId == ClassId.timestampAttr) {
        logWarning('Mixed curve direction is ignored for slurs with tstamp '
            'boundary.');
      } else {
        final int startStaffN = start.getAncestorStaffLayout().n ?? meiUnset;
        final int endStaffN = end.getAncestorStaffLayout().n ?? meiUnset;
        if (startStaffN < endStaffN) {
          slur.setDrawingCurveDir(SlurCurveDirection.belowAbove);
          return FunctorCode.continue_;
        } else if (startStaffN > endStaffN) {
          slur.setDrawingCurveDir(SlurCurveDirection.aboveBelow);
          return FunctorCode.continue_;
        } else {
          logWarning('Mixed curve direction is ignored for slurs starting '
              'and ending on the same staff.');
        }
      }
    }

    final bool isGraceToNoteSlur = start.classId != ClassId.timestampAttr &&
        end.classId != ClassId.timestampAttr &&
        start.isGraceNote() &&
        !end.isGraceNote();

    final Stemdirection startStemDir = start.getDrawingStemDirHeadless();

    if (_getPreferredCurveDirection(
            slur, start, startStemDir, isGraceToNoteSlur) ==
        CurvatureCurvedir.below) {
      slur.setDrawingCurveDir(SlurCurveDirection.below);
    } else {
      slur.setDrawingCurveDir(SlurCurveDirection.above);
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `CalcSlurDirectionFunctor::GetGraceCurveDirection`.
  CurvatureCurvedir _getGraceCurveDirection(Slur slur) {
    // Start on the notehead side.
    final Object? start = slur.getStart();
    final bool isStemDown = start is LayerElement &&
        start.getDrawingStemDirHeadless() == Stemdirection.down;
    return isStemDown ? CurvatureCurvedir.above : CurvatureCurvedir.below;
  }

  /// Mirrors `CalcSlurDirectionFunctor::GetPreferredCurveDirection` reduced
  /// to the cases decidable without staff drawing positions (the
  /// `isAboveStaffCenter` branch defaults to below like a mid-staff note).
  CurvatureCurvedir _getPreferredCurveDirection(
      Slur slur,
      LayerElement startElement,
      Stemdirection noteStemDir,
      bool isGraceToNoteSlur) {
    Note? startNote;
    Chord? startParentChord;
    if (startElement.classId == ClassId.note) {
      startNote = startElement as Note;
      startParentChord = startNote.isChordTone() as Chord?;
    }

    final Layer? layer = startElement.getFirstAncestor(ClassId.layer) as Layer?;
    Stemdirection layerStemDir = Stemdirection.none;

    CurvatureCurvedir drawingCurveDir = CurvatureCurvedir.above;
    // First should be the slur @curvedir.
    if (slur.hasCurvedir) {
      drawingCurveDir = (slur.curvedir == CurvatureCurvedir.above)
          ? CurvatureCurvedir.above
          : CurvatureCurvedir.below;
    }
    // Grace note slurs in case we have no drawing stem direction on the
    // layer.
    else if (isGraceToNoteSlur &&
        layer != null &&
        layer.getDrawingStemDir() == Stemdirection.none) {
      drawingCurveDir = _getGraceCurveDirection(slur);
    }
    // Otherwise layer direction trumps note direction.
    else if (layer != null &&
        (layerStemDir = layer.getDrawingStemDir()) != Stemdirection.none) {
      drawingCurveDir = (layerStemDir == Stemdirection.up)
          ? CurvatureCurvedir.above
          : CurvatureCurvedir.below;
    }
    // Look if in a chord.
    else if (startParentChord != null && startNote != null) {
      if (startParentChord.positionInChord(startNote) < 0) {
        drawingCurveDir = CurvatureCurvedir.below;
      } else if (startParentChord.positionInChord(startNote) > 0) {
        drawingCurveDir = CurvatureCurvedir.above;
      }
      // Away from the stem if odd number (center note).
      else {
        drawingCurveDir = (noteStemDir != Stemdirection.up)
            ? CurvatureCurvedir.above
            : CurvatureCurvedir.below;
      }
    } else if (noteStemDir == Stemdirection.up) {
      drawingCurveDir = CurvatureCurvedir.below;
    } else if (noteStemDir == Stemdirection.none) {
      // No information from the note stem directions: look at the position
      // in the notes (defaults to below in headless mode).
      drawingCurveDir = CurvatureCurvedir.below;
    }

    return drawingCurveDir;
  }
}
