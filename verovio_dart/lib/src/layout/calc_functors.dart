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
///   shortening (still commented out in the C++ itself) / ledger-line
///   adjustments.
library;

// ignore_for_file: unused_shown_name

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration, meiUnset;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/smufl.dart' show
        smuflE0A4NoteheadBlack,
        smuflE240Flag8thUp,
        smuflE242Flag16thUp;
import 'package:verovio_dart/src/core/point.dart' show Point;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/beam_segment.dart'
    show BeamElementCoord, BeamSpanSegment;
import 'package:verovio_dart/src/model/control_elements_gen.dart'
    show BeamSpan, Slur;
import 'package:verovio_dart/src/model/doc.dart' show Doc;
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show StemmedDrawingInterface;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

// ---------------------------------------------------------------------------
// CalcStemFunctor
// ---------------------------------------------------------------------------

/// Calculate the stem direction and length of notes, chords and tabDurSym
/// (headless port of `vrv::CalcStemFunctor`).
class CalcStemFunctor extends DocFunctor {
  CalcStemFunctor(super.doc);

  /// The chord stem length in half units (mirrors `m_chordStemLength`).
  int chordStemLength = 0;

  /// True while the current note is the secondary note of a `@stem.sameas`
  /// pair (mirrors `m_isStemSameasSecondary`): its own stem must not be
  /// drawn/lengthened independently — the visible stem line belongs to the
  /// primary note (calcstemfunctor.cpp:284-288).
  bool isStemSameasSecondary = false;

  /// Whether real drawing Y values are available (mirrors the C++, which
  /// always reads `GetDrawingY()`: `CalcStemFunctor` only runs inside Page
  /// layout — page.cpp:288/376/701 — and `AdjustCrossStaffYPosFunctor`,
  /// adjustyposfunctor.cpp:73-84).
  ///
  /// The headless `prepareData` pass (doc.dart) and unit tests run before
  /// any vertical layout, so they keep the staff-relative loc span below.
  /// Post-layout callers (the `ResetAligners`/transcription chains in
  /// doc.dart and the cross-staff recalc in lay_out_vertically.dart) set
  /// this to true so cross-staff chord spans include the inter-staff gap,
  /// which pitch-only locs cannot see.
  bool useDrawingY = false;

  /// The middle line loc of the current staff; replaces the C++
  /// `m_verticalCenter` absolute position.
  int verticalCenterLoc = 0;

  /// The duration of the element owning the current stem (mirrors `m_dur`).
  MeiDuration dur = MeiDuration.dur1;

  /// Whether the current tabGrp has no note child at all (mirrors
  /// `m_tabGrpWithNoNote`, set in `VisitTabGrp` and read in
  /// `VisitTabDurSym` to keep the tabDurSym's stem virtual — e.g. the
  /// place-holder `<tabGrp><tabDurSym/></tabGrp>` groups in tab/tab-004.mei).
  bool tabGrpWithNoNote = false;

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
    segment.initCoordRefs(beam.getElementCoords());
    // C++: `data_BEAMPLACE initialPlace = beam->GetPlace()` — the encoded
    // @place, never the computed drawingPlace (calcstemfunctor.cpp:69).
    Beamplace initialPlace = beam.place ?? Beamplace.none;
    if (beam.hasStemSameasBeam()) {
      initialPlace = segment.initSameasRoles(beam.stemSameasBeam, initialPlace);
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
    if (_isInBeam(chord) || chord.getAncestorFTrem() != null) {
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
    isStemSameasSecondary = false;

    // Chord Y extremes. `Chord::GetYExtremes` (chord.cpp:238-244) reads the
    // notes' true drawing Y, which for a cross-staff note lives on another
    // staff — the span then includes the inter-staff gap. Pitch-only locs
    // are exact for same-staff chords (the staff offset cancels) but blind
    // to that gap, so with real Ys available ([useDrawingY]) cross-staff
    // chords use the literal C++ computation
    // (`m_chordStemLength = yMin - yMax`, calcstemfunctor.cpp:142).
    // Headless passes keep the loc span (staff Ys are still zero there).
    final List<Object> childList = chord.getList();
    assert(childList.isNotEmpty);
    final Note bottomNote = childList.first as Note;
    final Note topNote = childList.last as Note;
    final int bottomLoc = bottomNote.calcDrawingLocHeadless();
    final int topLoc = topNote.calcDrawingLocHeadless();
    int? yMin;
    if (useDrawingY && _hasCrossStaff(chord)) {
      yMin = bottomNote.getDrawingY();
      final int yMax = topNote.getDrawingY();
      chordStemLength = yMin - yMax;
    } else {
      // Mirrors `m_chordStemLength = yMin - yMax` (calcstemfunctor.cpp:142)
      // with `Staff::CalcPitchPosYRel` (staff.cpp:288): each loc step is one
      // single drawing unit, so the Y span is -(span) * unit (not doubleUnit).
      chordStemLength = -(topLoc - bottomLoc) *
          doc.getDrawingUnit(staff.drawingStaffSize);
    }
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
    // down (mirrors `stem->SetDrawingYRel(yMin - chord->GetDrawingY())`,
    // calcstemfunctor.cpp:165-172): loc steps convert to drawing units via
    // `Staff::CalcPitchPosYRel` (staff.cpp:288), i.e. one single unit each.
    // With real Ys ([useDrawingY], cross-staff chords) this is the literal
    // C++ assignment, so the stem base lands on the cross-staff note.
    if (stemDir == Stemdirection.up) {
      if (yMin != null) {
        stem.setDrawingYRel(yMin - chord.getDrawingY());
      } else {
        stem.setDrawingYRel((bottomLoc - topLoc) *
            doc.getDrawingUnit(staff.drawingStaffSize));
      }
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
    segment.initCoordRefs(fTrem.getElementCoords());
    segment.calcBeam(layer, staff, doc, fTrem, Beamplace.none);
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitBeamSpan(BeamSpan beamSpan) {
    // Mirrors `CalcStemFunctor::VisitBeamSpan` (calcstemfunctor.cpp:80).
    if (beamSpan.getStart() == null ||
        beamSpan.getEnd() == null ||
        beamSpan.getBeamedElements().isEmpty) {
      return FunctorCode.continue_;
    }

    final Layer? layer =
        beamSpan.getStart()!.getFirstAncestor(ClassId.layer) as Layer?;
    final Staff? staff =
        beamSpan.getStart()!.getFirstAncestor(ClassId.staff) as Staff?;
    final Measure? measure =
        beamSpan.getStart()!.getFirstAncestor(ClassId.measure) as Measure?;
    if (layer == null || staff == null) return FunctorCode.continue_;

    final Beamplace place = beamSpan.place ?? Beamplace.none;
    beamSpan.initCoords(beamSpan.getBeamedElements(), staff, place);

    final BeamSpanSegment firstSegment = beamSpan.getSegment(0);
    firstSegment.measure = measure;
    firstSegment.staff = staff;
    firstSegment.layer = layer;
    final List<BeamElementCoord> coord =
        beamSpan.beamElementCoordsOwned.cast<BeamElementCoord>();
    if (coord.isEmpty) return FunctorCode.continue_;
    firstSegment.beginCoord = coord.first;
    firstSegment.endCoord = coord.last;
    firstSegment.initCoordRefs(coord);
    firstSegment.calcBeam(layer, staff, doc, beamSpan, place);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    if (!note.layoutIsVisible() || note.stemVisible == false) {
      return FunctorCode.siblings;
    }

    // Stems have been calculated previously in Beam or fTrem.
    if (_isInBeam(note) || note.getAncestorFTrem() != null) {
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
    isStemSameasSecondary = false;

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
      // Mirrors `stemDir = note->CalcStemDirForSameasNote(m_verticalCenter)`
      // (calcstemfunctor.cpp:262-263) — this used to read `note.stemDir`,
      // the raw (almost always absent) `@stem.dir` attribute, instead of
      // computing the direction from the linked note pair's vertical
      // position. Every `@stem.sameas` note therefore fell through to
      // `Stemdirection.none` and got an "up" flag/articulation regardless
      // of where its partner note actually sat, e.g. stem/stem-015.mei.
      stemDir = _calcStemDirForSameasNote(note, verticalCenterLoc);
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

    // Use chordStemLength for the length of the stem between the notes; the
    // value of `stemSameasRole` is set by `_calcStemDirForSameasNote` above
    // (mirrors calcstemfunctor.cpp:284-288).
    if (note.hasStemSameasNote() &&
        note.stemSameasRole == StemSameasDrawingRole.secondary) {
      final Object? sameasNote = note.stemSameasNote;
      if (sameasNote is Note) {
        chordStemLength =
            -(note.getDrawingY() - sameasNote.getDrawingY()).abs();
      }
      isStemSameasSecondary = true;
    }

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
    if (stem.parent is! LayerElement) return FunctorCode.continue_;
    final LayerElement parent = stem.parent as LayerElement;
    // Mirrors `CalcStemFunctor::VisitNote`/`VisitChord`
    // (calcstemfunctor.cpp:232-236/126-130): the cached `m_staff` (and hence
    // `m_verticalCenter` below) resolves through the note/chord's cross staff
    // (`note->m_crossStaff`), not the plain ancestor `<staff>`. Reading the
    // ancestor here made the ledger-line extension below compare a
    // cross-staff stem tip against the wrong staff's center (e.g.
    // cross-staff-004 m53 `note-L40F2`: tip −2520 vs staff-1 center −900
    // extended spuriously to −2222; against staff-2's −2700 it holds −602
    // like the C++).
    final Staff? staff = parent.getAncestorStaffResolveCrossStaff();
    if (staff == null) return FunctorCode.continue_;

    final int stemShift = doc.getDrawingStemWidth(staff.drawingStaffSize) ~/ 2;

    // For notes longer than half notes the stem is always 0.
    if (dur.value < MeiDuration.dur2.value) {
      stem.drawingXRel = 0;
      stem.drawingYRel = 0;
      stem.setDrawingStemLen(0);
      final int modAdjust = stem.calculateStemModAdjustment(doc, staff, 0);
      if (modAdjust != 0) {
        stem.setDrawingStemLen(stem.getDrawingStemLen() + modAdjust);
      }
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
    // chordStemLength).
    else if (!isStemSameasSecondary) {
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
        final int stemShortening = isStemSameasSecondary ? 0 : p.y;
        stem.setDrawingStemLen(baseStem + chordStemLength + stemShortening);
      } else {
        if (_stemPos(stem) == Stemposition.right) {
          p = _stemAnchor(doc, parent, staff, true, stem.drawingCueSize);
          p.x -= stemShift;
        } else {
          p = _stemAnchor(doc, parent, staff, false, stem.drawingCueSize);
          p.x += stemShift;
        }
        final int stemShortening = isStemSameasSecondary ? 0 : p.y;
        stem.setDrawingStemLen(-(baseStem + chordStemLength - stemShortening));
      }
      stem.drawingYRel = stem.drawingYRel + p.y;
      stem.drawingXRel = p.x;
    }

    /************ Set flag (if necessary) and adjust the length ************/

    // There is never a flag with a duration longer than 8th notes. There is
    // never a flag with stem sameas notes either.
    int flagOffset = 0;
    Flag? flag;
    if (dur.value > MeiDuration.dur4.value) {
      flag = stem.getFirst(ClassId.flag) as Flag?;
      if (flag != null) {
        if (isStemSameasSecondary) {
          flag.drawingNbFlags = 0;
        } else {
          flag.drawingNbFlags = dur.value - MeiDuration.dur4.value;
          flagOffset = unit * (flag.drawingNbFlags + 1);
        }
      }
    }

    // SMUFL flags cover some additional stem length from the 32th only
    // (mirrors calcstemfunctor.cpp:423-426). Without this the flag glyph
    // stays at its reset-functor default yRel (0), i.e. drawn at the note
    // head instead of the stem tip.
    if (flag != null) {
      flag.setDrawingYRel(-stem.getDrawingStemLen());
    }

    // Do not adjust the length with stem sameas notes or if given in the
    // encoding (mirrors calcstemfunctor.cpp:427-433: the ledger-line
    // shortening pass itself, calcstemfunctor.cpp:439-472, is a separate,
    // still-unported deviation — see the file-level doc comment).
    if (isStemSameasSecondary || stem.len != null) {
      if ((stem.len?.vu.toInt() ?? -1) == 0 && flag != null) {
        flag.drawingNbFlags = 0;
      }
      return FunctorCode.continue_;
    }
    if (stem.visible == false && flag != null) {
      flag.drawingNbFlags = 0;
      return FunctorCode.continue_;
    }

    // Ledger-line extension (mirrors calcstemfunctor.cpp:439-472): extend
    // the stem when its tip does not reach the staff vertical center, so it
    // clears the notehead side / first ledger line. `flagHeight` stays 0
    // here exactly as in the C++ (the GetStemUpSE/GetStemDownNW shortening
    // for 32nds is commented out there as crashing — "needs investigating").
    // Grace notes are excluded (mirrors `!m_isGraceNote`); the flag Y tracks
    // the new length.
    final int verticalCenter = _verticalCenterAbsolute(staff);
    final int endY =
        stem.getDrawingY() - stem.getDrawingStemLen();
    bool extendLen = false;
    if (stemDir == Stemdirection.up && endY < verticalCenter) {
      extendLen = true;
    } else if (stemDir == Stemdirection.down && endY > verticalCenter) {
      extendLen = true;
    }
    if (extendLen && !isGraceNote) {
      stem.setDrawingStemLen(
          stem.getDrawingStemLen() + (endY - verticalCenter));
      if (flag != null) {
        flag.setDrawingYRel(-stem.getDrawingStemLen());
      }
    }

    if (!isGraceNote && !stem.drawingCueSize && !isStemSameasSecondary) {
      final int modAdjust =
          stem.calculateStemModAdjustment(doc, staff, flagOffset);
      if (modAdjust != 0) {
        stem.setDrawingStemLen(stem.getDrawingStemLen() + modAdjust);
      }
      if (flag != null) {
        flag.setDrawingYRel(-stem.getDrawingStemLen());
      }
    }

    if (flag != null) {
      adjustFlagPlacement(doc, stem, flag, staff.drawingStaffSize,
          _verticalCenterAbsolute(staff), dur);
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `CalcStemFunctor::AdjustFlagPlacement` (calcstemfunctor.cpp:624):
  /// lengthens the stem so a down-stem flag clears the notehead and so the
  /// flag clears the first ledger line on either side.
  ///
  /// Deviation: the C++ takes absolute `staffSize`/`verticalCenter` drawing
  /// positions and `Stem`/`Flag`/`Doc` pointers; the headless engine carries
  /// only staff-relative locs, so the ledger-line branch resolves ledger
  /// presence through `PositionInterface.hasLedgerLines` on the note's
  /// drawing loc (set by `calcDrawingLocHeadless`), and the Y geometry
  /// through the stem/note drawing offsets.
  void adjustFlagPlacement(dynamic doc, Stem stem, Flag flag, int staffSize,
      int verticalCenter, MeiDuration duration) {
    final LayerElement? parent =
        stem.parent is LayerElement ? stem.parent as LayerElement : null;
    if (parent == null) return;

    final Stemdirection stemDirection = stem.getDrawingStemDir();
    // For overlapping purposes we don't care for flags shorter than 16th
    // since they grow in opposite direction.
    int flagGlyph = smuflE242Flag16thUp; // SMUFL_E242_flag16thUp
    if (duration.value < MeiDuration.dur16.value) {
      flagGlyph = flag.getFlagGlyph(stemDirection);
    }
    final int glyphHeight =
        doc.getGlyphHeight(flagGlyph, staffSize, stem.drawingCueSize);

    // Make sure that flags don't overlap with notehead. Upward flags cannot
    // overlap with noteheads so check only downward ones.
    final int adjustmentStep = doc.getDrawingUnit(staffSize);
    if (stemDirection == Stemdirection.down) {
      final int noteheadMargin = stem.getDrawingStemLen() -
          (glyphHeight + parent.getDrawingRadius(doc));
      if ((duration.value > MeiDuration.dur16.value) && (noteheadMargin < 0)) {
        int offset = 0;
        // Mirrors `noteheadMargin % adjustmentStep < -adjustmentStep / 3 * 2`
        // (calcstemfunctor.cpp:646): C++ `%` keeps the dividend's sign
        // (e.g. -71 % 90 == -71), while Dart's `%` always returns a
        // non-negative remainder (-71 % 90 == 19). Emulate the C++ remainder
        // or the taker branch never fires (e.g. note-010 dur32/64 Δ-45:
        // margin -71 vs threshold -60 — fires in C++, dead in Dart).
        final int cxxRemainder =
            noteheadMargin.remainder(adjustmentStep);
        if (cxxRemainder < -adjustmentStep ~/ 3 * 2) {
          offset = adjustmentStep ~/ 2;
        }
        final int heightToAdjust =
            (noteheadMargin ~/ adjustmentStep) * adjustmentStep - offset;
        stem.setDrawingStemLen(stem.getDrawingStemLen() - heightToAdjust);
        flag.setDrawingYRel(-stem.getDrawingStemLen());
      }
    }

    Note? note;
    if (parent.classId == ClassId.note) {
      note = parent as Note;
    } else if (parent.classId == ClassId.chord) {
      note = (parent as Chord).getTopNote();
    }
    if (note == null) return;
    final Staff? staff =
        note.getAncestorStaffResolveCrossStaff() as Staff?;
    if (staff == null) return;
    final (bool hasLedger, int ledgerAbove, int ledgerBelow) =
        note.hasLedgerLines(staff);
    if (!hasLedger) return;
    if (((stemDirection == Stemdirection.up) && ledgerBelow == 0) ||
        ((stemDirection == Stemdirection.down) && ledgerAbove == 0)) {
      return;
    }

    // Make sure that flags don't overlap with first (top or bottom) ledger
    // line (effectively avoiding all ledgers).
    final int directionBias = (stemDirection == Stemdirection.down) ? -1 : 1;
    final int position = stem.getDrawingY() -
        stem.getDrawingStemLen() -
        directionBias * glyphHeight;
    final int ledgerPosition =
        verticalCenter - 6 * directionBias * adjustmentStep;
    final int displacementMargin = (position - ledgerPosition) * directionBias;

    if (displacementMargin < 0) {
      int offset = 0;
      if ((stemDirection == Stemdirection.down) &&
          // C++-sign `%` (see above): Dart's `%` would never be negative
          // here, silently dropping the `offset = step/2` taker branch.
          (displacementMargin.remainder(adjustmentStep) >
              -adjustmentStep ~/ 3)) {
        offset = adjustmentStep ~/ 2;
      }
      final int heightToAdjust =
          (displacementMargin ~/ adjustmentStep - 1) * adjustmentStep * directionBias -
              offset;
      stem.setDrawingStemLen(stem.getDrawingStemLen() + heightToAdjust);
      flag.setDrawingYRel(-stem.getDrawingStemLen());
    }
  }

  /// Absolute vertical center of the staff (mirrors the C++
  /// `m_verticalCenter = staffY - GetDrawingDoubleUnit(staffSize) * 2`,
  /// calcstemfunctor.cpp:146).
  int _verticalCenterAbsolute(Staff staff) =>
      staff.getDrawingY() -
      doc.getDrawingDoubleUnit(staff.drawingStaffSize) * 2;

  @override
  FunctorCode visitTabGrp(TabGrp tabGrp) {
    dur = tabGrp.getActualDur();
    // Mirrors `m_tabGrpWithNoNote = !tabGrp->FindDescendantByType(NOTE)`
    // (calcstemfunctor.cpp:581) — a tabGrp holding only a `<tabDurSym/>`
    // place-holder (no `<note>`) must keep its stem virtual regardless of
    // duration, so nothing is drawn for it.
    tabGrpWithNoNote = tabGrp.findDescendantByType(ClassId.note) == null;

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
    if (dur.value < MeiDuration.dur2.value || tabGrpWithNoNote) {
      stem.setIsVirtual(true);
      return FunctorCode.siblings;
    }

    // Cache to avoid further lookup.
    final Staff staff = tabDurSym.getAncestorStaffLayout();
    final Layer? layer = tabDurSym.getFirstAncestor(ClassId.layer) as Layer?;

    /************ Set the direction ************/

    // Up by default with tablature.
    Stemdirection stemDir = Stemdirection.up;

    if ((stem.dir as Stemdirection?) != null &&
        stem.dir != Stemdirection.none) {
      stemDir = stem.dir as Stemdirection;
    } else if (layer != null &&
        layer.getDrawingStemDir() != Stemdirection.none) {
      // Mirrors `stemDir = layerStemDir` (calcstemfunctor.cpp:526-528) —
      // this fallback to the layer's drawing stem direction (set per-parity
      // in `VisitStaff` for multi-layer staves) was missing entirely, so
      // every tabDurSym in an even-numbered layer wrongly got an "up" flag
      // glyph (E240/E242) instead of the "down" one (E241/E243).
      stemDir = layer.getDrawingStemDir();
    }

    tabDurSym.setDrawingStemDir(stemDir);

    int stemDirFactor = -1;
    if (stemDir == Stemdirection.down) {
      // Mirrors `tabDurSym->AdjustDrawingYRel(m_staff, m_doc)`
      // (calcstemfunctor.cpp:534).
      tabDurSym.adjustDrawingYRel(staff, doc);
      stemDirFactor = 1;
    }

    int stemSize;
    if (staff.isTabWithStemsOutside()) {
      // Make sure the relative position of the stem is the same.
      stem.setDrawingYRel(0);
      final int thirdUnits =
          tabDurSym.calcStemLenInThirdUnitsHeadless(staff, stemDir);
      stemSize = thirdUnits * doc.getDrawingUnit(staff.drawingStaffSize);
      stemSize = stemSize ~/ (3 * stemDirFactor);
    } else {
      // Otherwise attach it to the closest note.
      final TabGrp? tabGrp =
          tabDurSym.getFirstAncestor(ClassId.tabGrp) as TabGrp?;
      final Note? note = tabGrp == null
          ? null
          : (stemDir == Stemdirection.down
              ? tabGrp.getBottomNote()
              : tabGrp.getTopNote());
      int yRel = note?.drawingYRel ?? 0;
      // Because the tabDurSym is relative to the top or bottom staff line,
      // remove its relative value.
      yRel -= tabDurSym.drawingYRel;
      // Remove a unit for the stem not to go to the center of the note.
      yRel -= doc.getDrawingUnit(staff.drawingStaffSize) * stemDirFactor;
      stem.setDrawingYRel(yRel);
      final int thirdUnits =
          tabDurSym.calcStemLenInThirdUnitsHeadless(staff, stemDir);
      stemSize = thirdUnits * doc.getDrawingUnit(staff.drawingStaffSize);
      stemSize = stemSize ~/ (3 * stemDirFactor);
    }

    if (dur == MeiDuration.dur2) {
      // Stems for half notes twice shorter.
      stemSize = stemSize ~/ 2;
    }

    stem.setDrawingStemLen(stemSize);

    // Flag currently used only for guitar tablature because it is included
    // in the glyphs for lute tab (mirrors calcstemfunctor.cpp:565-571 —
    // this whole block was missing, leaving every tab flag's
    // `drawingNbFlags` at its reset-functor default of 0 and the flag
    // glyph silently unrendered, e.g. tab/tab-004.mei, tab/tab-005.mei).
    if (staff.isTabGuitar()) {
      final Flag? flag = stem.getFirst(ClassId.flag) as Flag?;
      if (flag != null) {
        flag.drawingNbFlags = dur.value - MeiDuration.dur4.value;
        flag.setDrawingYRel(-stemSize);
      }
    }

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

  /// Return the layer stem direction for an element (mirrors the
  /// element-aware `Layer::GetDrawingStemDir(element)` used by
  /// calcstemfunctor.cpp:154 (chord) and :271 (note) — returns NONE when
  /// fewer than 2 layers overlap the element's time span (@sameas/space
  /// elements are skipped by LayersInTimeSpanFunctor, so a sameas-only
  /// overlap does not force a stem direction).
  Stemdirection _getLayerStemDir(Layer layer, LayerElement element) =>
      layer.getDrawingStemDirFor(element);

  /// Mirrors `Note::CalcStemDirForSameasNote`, with the C++'s absolute
  /// `GetDrawingY()` comparisons replaced by `calcDrawingLocHeadless()` —
  /// same headless substitution this file already makes for
  /// `m_verticalCenter` (see the class doc on [verticalCenterLoc]); higher
  /// loc means higher on the staff exactly like higher Y does in the C++,
  /// so every comparison direction carries over unchanged.
  ///
  /// Deviation: the C++ also calls `CalcNoteHeadShiftForSameasNote` here to
  /// flag whichever of the two notes needs its notehead nudged; that call
  /// needs a real `GetDrawingY()` (it compares absolute pixel position, not
  /// staff loc), which is not yet available in this functor's headless
  /// pass. `Note.calcNoteHeadShiftForSameasNote` (`basic_elements.dart`) is
  /// ported and wired instead from `BeamSegment.calcNoteHeadShiftForStemSameas`
  /// (`beam_segment.dart`), which runs later, once real Y is available; the
  /// plain (non-beamed) `stem.sameas` pair remains unflagged. Neither call
  /// affects the stem direction (hence the flag/articulation glyph choice)
  /// computed and returned here.
  Stemdirection _calcStemDirForSameasNote(Note note, int verticalCenterLoc) {
    final Note counterpart = note.stemSameasNote as Note;

    // This is the first of the note pair reached — calculate and set the
    // stem direction (and role) for both notes.
    if (note.stemSameasRole == StemSameasDrawingRole.unset) {
      Stemdirection stemDir = Stemdirection.up;
      final int thisLoc = note.calcDrawingLocHeadless();
      final int otherLoc = counterpart.calcDrawingLocHeadless();
      final bool thisIsTop = thisLoc > otherLoc;
      final Note topNote = thisIsTop ? note : counterpart;
      final Note bottomNote = thisIsTop ? counterpart : note;

      // First check if we have an encoded stem direction.
      if (note.hasStemDir) {
        stemDir = note.stemDir!;
      } else {
        // Otherwise auto-determine it.
        final int topLoc = thisIsTop ? thisLoc : otherLoc;
        final int bottomLoc = thisIsTop ? otherLoc : thisLoc;
        final int middlePoint = (topLoc + bottomLoc) ~/ 2;
        stemDir = middlePoint > verticalCenterLoc
            ? Stemdirection.down
            : Stemdirection.up;
      }
      // We also set the role to both notes accordingly.
      topNote.stemSameasRole = stemDir == Stemdirection.up
          ? StemSameasDrawingRole.primary
          : StemSameasDrawingRole.secondary;
      bottomNote.stemSameasRole = stemDir == Stemdirection.up
          ? StemSameasDrawingRole.secondary
          : StemSameasDrawingRole.primary;

      return stemDir;
    } else {
      // Otherwise use the stem direction set for the other note previously
      // when this method was called for it.
      return counterpart.getDrawingStemDir();
    }
  }

  /// Mirrors `LayerElement::IsInBeam` (`GetAncestorBeam() ||
  /// GetIsInBeamSpan()`, layerelement.cpp:270): the ancestor-beam lookup
  /// must go through [getAncestorBeam] (imported via [LayoutElementHelpers]),
  /// which returns NULL for a grace note embedded in a mixed beam
  /// (layerelement.cpp:228-256) — such notes get individual stem direction
  /// and length instead of the beam's (e.g. gracenote-011).
  static bool _isInBeam(LayerElement element) =>
      element.getAncestorBeam() != null || element.isInBeamSpan;

  static bool _isTabGrpNote(LayerElement element) =>
      element.getFirstAncestor(ClassId.tabGrp) != null;

  /// Loc of the middle staff line (0 being the bottom line).
  static int _middleLineLoc(Staff staff) => staff.drawingLines - 1;

  /// Mirrors `Stem::GetPos()` (AttStemVis `@pos`; NONE unless set).
  Stemposition _stemPos(Stem stem) => stem.pos ?? Stemposition.none;

  /// Mirrors `Chord::HasCrossStaff` (chord.cpp:346-356): the chord itself
  /// or one of its notes is rendered on another staff.
  static bool _hasCrossStaff(Chord chord) {
    if (chord.crossStaff != null) return true;
    for (final Object object in chord.getList()) {
      if ((object as Note).crossStaff != null) return true;
    }
    return false;
  }

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

    // Mirrors `CalcChordNoteHeadsFunctor::VisitNote`
    // (calcchordnoteheadsfunctor.cpp:52-115): unison chord tones share one
    // stem side — the note on the "wrong" side is flagged so `View.drawNote`
    // offsets its head. The C++ runs this in Page::ResetAligners (with
    // SMuFL glyphs loaded), but the Dart port defers Calc* to
    // Doc.prepareData (headless). Compensate by resolving anchors through
    // `getDrawingRadius` (glyph-width based, correct once fonts are loaded)
    // instead of the raw glyph table (empty headlessly).
    final Chord? chord = note.isChordTone() as Chord?;
    if (chord == null) return FunctorCode.siblings;
    final Staff? staff = note.getFirstAncestor(ClassId.staff) as Staff?;
    if (staff == null) return FunctorCode.siblings;
    return _visitChordToneNote(note, chord, staff);
  }

  /// Chord-tone half of `CalcChordNoteHeadsFunctor::VisitNote` (split out
  /// for readability; called only from [visitNote] above).
  FunctorCode _visitChordToneNote(Note note, Chord chord, Staff staff) {
    final int staffSize = staff.drawingStaffSize;
    // Tab staff branch (calcchordnoteheadsfunctor.cpp:58-64).
    if (staff.isTabStaffLike()) {
      final int staffNotationSize = staff.getDrawingStaffNotationSize();
      final int width =
          doc.getGlyphWidth(smuflE0A4NoteheadBlack, staffNotationSize, false) ~/
              2;
      note.drawingXRel = -width;
      return FunctorCode.siblings;
    }

    // Chord-level diameter (calcchordnoteheadsfunctor.cpp:34-46): only for
    // stem-up chords; in-beam chords use twice the drawing radius, others
    // the bottom note's head glyph width. `diameter` below is the note's
    // own (cpp:69).
    int chordDiameter = 0;
    if (chord.getDrawingStemDir() == Stemdirection.up) {
      if (note.isInBeam()) {
        chordDiameter = 2 * chord.getDrawingRadius(doc);
      } else {
        final Note? bottomNote = chord.getBottomNote();
        if (bottomNote != null) {
          chordDiameter = doc.getGlyphWidth(
              bottomNote.getNoteheadGlyph(chord.getActualDur()),
              staffSize,
              chord.drawingCueSize ? bottomNote.drawingCueSize : false);
        }
      }
    }

    final int diameter = 2 * note.getDrawingRadius(doc);
    int noteheadShift = 0;
    if (note.getDrawingStemDir() == Stemdirection.up && chordDiameter != 0) {
      noteheadShift = chordDiameter - diameter;
    }

    // Nothing to do for notes that are not in a note group and without base
    // diameter for the chord (cpp:72-73).
    final List<Note>? noteGroup = note.getNoteGroup();
    if ((chordDiameter == 0 ||
            (alignmentType != (note.getAlignment()?.getType() ??
                    AlignmentType.default_))) &&
        noteGroup == null) {
      return FunctorCode.siblings;
    }

    // Notehead direction (cpp:77-99).
    bool flippedNotehead = false;
    if (noteGroup != null) {
      final int noteGroupPosition = note.noteGroupPosition;
      if (note.getDrawingStemDir() == Stemdirection.down) {
        if (noteGroup.length % 2 == 0) {
          flippedNotehead = (noteGroupPosition % 2 != 0);
        } else {
          flippedNotehead = (noteGroupPosition % 2 == 0);
        }
      } else {
        flippedNotehead = (noteGroupPosition % 2 == 0);
      }
    }

    // Position notehead (cpp:101-109).
    if (flippedNotehead) {
      if (note.getDrawingStemDir() == Stemdirection.up) {
        note.drawingXRel =
            diameter - doc.getDrawingStemWidth(staffSize);
      } else {
        note.drawingXRel =
            -diameter + doc.getDrawingStemWidth(staffSize);
      }
    }
    note.drawingXRel = note.drawingXRel + noteheadShift;

    note.flippedNotehead = flippedNotehead;

    return FunctorCode.siblings;
  }
}

// ---------------------------------------------------------------------------
// CalcDotsFunctor
// ---------------------------------------------------------------------------

/// Compute the optimal dot locations of the dotted elements (port of
/// `vrv::CalcDotsFunctor`, calcdotsfunctor.cpp), including the `xRel` shifts
/// of the dots past the noteheads (`noteX - chordX + 2 * radius + flagShift`
/// for chord tones, `2 * radius + flagShift` for single notes).
class CalcDotsFunctor extends DocFunctor {
  CalcDotsFunctor(super.doc);

  Dots? chordDots;

  /// Mirrors `m_chordDrawingX` (calcdotsfunctor.cpp): the chord's drawing X
  /// at `VisitChord` time, the origin the chord-tone `xRel` is relative to.
  int chordDrawingX = 0;
  Stemdirection chordStemDir = Stemdirection.none;

  @override
  FunctorCode visitChord(Chord chord) {
    // If the chord isn't visible, stop here.
    if (!chord.layoutIsVisible()) {
      return FunctorCode.siblings;
    }
    // If there aren't dot, stop here but only if no note has a dot.
    // Mirrors `!chord->HasNoteWithDots()` (calcdotsfunctor.cpp:41).
    if ((chord.dots ?? 0) < 1) {
      if (!chord.hasNoteWithDots()) {
        return FunctorCode.siblings;
      } else {
        return FunctorCode.continue_;
      }
    }

    final Dots? dots =
        chord.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;
    assert(dots != null);

    chordDots = dots;
    chordDrawingX = chord.getDrawingX();
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

    // Neither branch below can fire without dots on the chord or on the
    // note itself; their inputs (`flagShift`, `radius`) are side-effect-free
    // locals, so skipping them is unobservable. This also keeps synthetic
    // staff-less notes (which never reach either branch) behaving as before
    // — the C++ computes the same values unconditionally, but would crash on
    // such a tree when resolving the staff.
    if ((chord == null || (chord.dots ?? 0) < 1) && (note.dots ?? 0) < 1) {
      return FunctorCode.siblings;
    }

    // Mirrors `int flagShift = 0; int radius = note->GetDrawingRadius(m_doc);`
    // (calcdotsfunctor.cpp:77-80): shared by both branches below — the single
    // note branch accumulates onto the chord-tone branch's `flagShift`.
    int flagShift = 0;
    final int radius = note.getDrawingRadius(doc);

    if (chord != null && (chord.dots ?? 0) > 0) {
      // Mirrors the chord-tone branch (calcdotsfunctor.cpp:82-98): the shared
      // chord dots sit past the rightmost notehead of the chord.
      final Dots? dots = chordDots;
      assert(dots != null);

      // Stem up, shorter than 4th and not in beam.
      if ((note.dots ?? 0) > 0 &&
          chordStemDir == Stemdirection.up &&
          note.getDrawingDur().value > MeiDuration.dur4.value &&
          !CalcStemFunctor._isInBeam(note)) {
        // Shift according to the flag width if the top note is not flipped.
        if (identical(note, chord.getTopNote()) && !note.flippedNotehead) {
          // HARDCODED (calcdotsfunctor.cpp:91).
          final int staffSize =
              note.getAncestorStaffResolveCrossStaff()!.drawingStaffSize;
          flagShift += (doc.getGlyphWidth(smuflE240Flag8thUp, staffSize,
                      note.drawingCueSize) *
                  0.8)
              .toInt();
        }
      }

      final int xRel =
          note.getDrawingX() - chordDrawingX + 2 * radius + flagShift;
      if (xRel > dots!.drawingXRel) {
        dots.drawingXRel = xRel;
      }
    }
    if ((note.dots ?? 0) > 0) {
      // For single notes we need here to set the dot loc.
      final Dots? dots =
          note.findDescendantByType(ClassId.dots, deepness: 1) as Dots?;
      assert(dots != null);

      // Mirrors `Note::CalcOptimalDotLocations`, i.e.
      // `LayerElement::CalcOptimalDotLocations` (layerelement.cpp:909-989):
      // full two-layer collision-avoidance, including the unison branch's
      // `Note::AlignDotsShift` (note.cpp:193) side effect.
      final Map<Object, Set<int>> dotLocs = _noteOptimalDotLocations(note);
      dots!.setMapOfDotLocs(dotLocs);
      final int dotLocShift = dotLocs.values.first.reduce(math.max) - note.drawingLoc;
      final int staffSize =
          note.getAncestorStaffResolveCrossStaff()!.drawingStaffSize;

      // Mirrors `CalcDotsFunctor::VisitNote`'s `xRel = 2 * radius +
      // flagShift` (calcdotsfunctor.cpp:96-119): the horizontal shift of
      // the dot glyph(s) past the notehead, plus the extra shift needed so
      // the dot doesn't collide with a nearby stem flag. `flagShift` is the
      // shared local from the top of `VisitNote` — the C++ accumulates the
      // chord-tone branch's shift into the same variable before reaching
      // this branch.
      final int existingShift = dots.flagShift;
      if (existingShift != 0) {
        flagShift += existingShift;
      } else if (note.getDrawingStemDir() == Stemdirection.up &&
          !CalcStemFunctor._isInBeam(note) &&
          note.getDrawingStemLen() < 3 &&
          _isDotOverlappingWithFlag(doc, note, staffSize, dotLocShift)) {
        final int shift =
            (doc.getGlyphWidth(smuflE240Flag8thUp, staffSize, note.drawingCueSize) *
                    0.8)
                .toInt();
        flagShift += shift;
        dots.flagShift = shift;
      }

      final int xRel = 2 * radius + flagShift;
      if (xRel > dots.drawingXRel) {
        dots.drawingXRel = xRel;
      }
    }

    return FunctorCode.siblings;
  }

  /// Mirrors `CalcDotsFunctor::IsDotOverlappingWithFlag` (calcdotsfunctor.cpp:175):
  /// whether [note]'s dot(s) would visually collide with its stem's flag,
  /// given the dot has already been shifted up/down by [dotLocShift] steps.
  bool _isDotOverlappingWithFlag(
      Doc doc, Note note, int staffSize, int dotLocShift) {
    final Object? stemObject = note.getFirst(ClassId.stem);
    if (stemObject == null) return false;
    final Stem stem = stemObject as Stem;

    final Object? flagObject = stem.getFirst(ClassId.flag);
    if (flagObject == null) return false;
    final Flag flag = flagObject as Flag;
    if (flag.drawingNbFlags == 0) return false;

    // For the purposes of vertical spacing we care only up to 16th flags -
    // shorter ones grow upwards.
    int flagGlyph = smuflE242Flag16thUp;
    final MeiDuration dur = note.dur ?? MeiDuration.none;
    if (dur.value < MeiDuration.dur16.value) {
      flagGlyph = flag.getFlagGlyph(note.getDrawingStemDir());
    }
    final int flagHeight =
        doc.getGlyphHeight(flagGlyph, staffSize, note.drawingCueSize);

    final int dotMargin = flag.getDrawingY() -
        note.getDrawingY() -
        flagHeight -
        note.getDrawingRadius(doc) ~/ 2 -
        dotLocShift * doc.getDrawingUnit(staffSize);

    return dotMargin < 0;
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

  /// Mirrors `Note::CalcDotLocations(layerCount, primary)` (note.cpp:1012):
  /// the loc shifts only when it sits *on* a line (`loc % 2 == 0`); the
  /// shift direction is "up" when `isUpwardDirection == primary`, and
  /// `isUpwardDirection` is the note's own stem direction unless there is
  /// only one layer at this time position (`layerCount == 1`), which is
  /// always treated as upward.
  static Map<Object, Set<int>> _noteCalcDotLocations(
      Note note, int layerCount, bool primary) {
    final bool isUpwardDirection =
        (note.getDrawingStemDir() == Stemdirection.up) || (layerCount == 1);
    final bool shiftUpwards = isUpwardDirection == primary;
    final Staff staff =
        note.getAncestorStaffResolveCrossStaff() ?? note.getAncestorStaffLayout();
    int loc = note.calcDrawingLocHeadless();
    if (loc.isEven) {
      loc += shiftUpwards ? 1 : -1;
    }
    return {staff: {loc}};
  }

  /// Stands in for the C++ virtual call `other->CalcDotLocations(layerCount,
  /// primary)` (Dart has no double dispatch — see `functor.dart`'s header
  /// comment for the project's general approach), dispatching to
  /// [_noteCalcDotLocations] or [ChordDotLocations._dotLocationsFor]
  /// depending on the concrete type of [element].
  static Map<Object, Set<int>> _elementCalcDotLocations(
      LayerElement element, int layerCount, bool primary) {
    if (element is Note) {
      return _noteCalcDotLocations(element, layerCount, primary);
    }
    if (element is Chord) {
      return element._dotLocationsFor(layerCount, primary);
    }
    return const {};
  }

  /// Mirrors `LayerElement::GetDotCount` (layerelement.cpp:1020).
  static int _dotCount(Map<Object, Set<int>> dotLocs) =>
      dotLocs.values.fold(0, (sum, locs) => sum + locs.length);

  /// Mirrors `LayerElement::GetCollisionCount` (layerelement.cpp:1026).
  static int _collisionCount(Map<Object, Set<int>> a, Map<Object, Set<int>> b) {
    int count = 0;
    for (final MapEntry<Object, Set<int>> entry in a.entries) {
      final Set<int>? other = b[entry.key];
      if (other != null) {
        count += entry.value.intersection(other).length;
      }
    }
    return count;
  }

  /// Mirrors the `std::find_if` in `LayerElement::CalcOptimalDotLocations`
  /// (layerelement.cpp:925-943): the first note in [current]'s alignment
  /// that sits on a *different* layer of the *same* staff, promoted to its
  /// chord when it is a chord tone. `null` means [current] is effectively
  /// alone at this time position, so the two-layer branch does not apply
  /// (`layerCount` collapses to 1).
  static LayerElement? _findOtherLayerElement(LayerElement current) {
    final Alignment? alignment = current.getAlignment();
    if (alignment == null) return null;
    final Staff? currentStaff = current.getAncestorStaffResolveCrossStaff();
    if (currentStaff == null) return null;
    final int currentLayerN = current.getAlignmentLayerN().abs();
    final List<Object> notes =
        alignment.findAllDescendantsByType(ClassId.note);
    for (final Object obj in notes) {
      final Note otherNote = obj as Note;
      if (currentLayerN == otherNote.getAlignmentLayerN().abs()) continue;
      if (otherNote.getAncestorStaffResolveCrossStaff() != currentStaff) {
        continue;
      }
      final Object? chord = otherNote.isChordTone();
      return (chord as LayerElement?) ?? otherNote;
    }
    return null;
  }

  /// Mirrors `LayerElement::CalcOptimalDotLocations` (layerelement.cpp:909)
  /// for [Note]. With another note on a different layer of the same staff
  /// (`layerCount == 2`), picks whichever of the "primary" (above) /
  /// "secondary" (below) dot placements collides least with the other
  /// layer's note or chord — short-circuited by a unison check
  /// (`Note::AlignDotsShift`, note.cpp:193) when the two notes share a
  /// pitch, which instead copies the `flagShift` and always gives the
  /// primary placement to the numerically-lower layer. With no other layer,
  /// or no collision at all, falls back to the dot-count comparison, which
  /// for a single note always prefers "primary" (both orderings produce
  /// exactly one dot).
  static Map<Object, Set<int>> _noteOptimalDotLocations(Note note) {
    final LayerElement? other = _findOtherLayerElement(note);
    final int layerCount = (other != null) ? 2 : 1;

    final Map<Object, Set<int>> dotLocs1 =
        _noteCalcDotLocations(note, layerCount, true);
    final Map<Object, Set<int>> dotLocs2 =
        _noteCalcDotLocations(note, layerCount, false);

    if (layerCount == 2 && other != null) {
      final int currentLayerN = note.getAlignmentLayerN().abs();
      final int otherLayerN = other.getAlignmentLayerN().abs();
      final Map<Object, Set<int>> otherDotLocs1 =
          _elementCalcDotLocations(other, layerCount, true);
      final Map<Object, Set<int>> otherDotLocs2 =
          _elementCalcDotLocations(other, layerCount, false);

      if (other is Note) {
        final Note otherNote = other;
        if (note.isUnisonWith(otherNote)) {
          if (note.getDrawingStemDir() == Stemdirection.up) {
            otherNote.alignDotsShift(note);
          } else if (otherNote.getDrawingStemDir() == Stemdirection.up) {
            note.alignDotsShift(otherNote);
          }
          return (currentLayerN < otherLayerN) ? dotLocs1 : dotLocs2;
        }
      }

      final int c11 = _collisionCount(dotLocs1, otherDotLocs1);
      final int c12 = _collisionCount(dotLocs1, otherDotLocs2);
      final int c21 = _collisionCount(dotLocs2, otherDotLocs1);
      final int c22 = _collisionCount(dotLocs2, otherDotLocs2);
      final int maxCollisions = [c11, c12, c21, c22].reduce(math.max);

      if (maxCollisions > 0) {
        final int minCollisions = [c11, c12, c21, c22].reduce(math.min);
        if (c11 == minCollisions) return dotLocs1;
        if (c12 == minCollisions) {
          if (c21 == minCollisions) {
            return (currentLayerN < otherLayerN) ? dotLocs1 : dotLocs2;
          }
          return dotLocs1;
        }
        return dotLocs2;
      }
    }

    final bool usePrimary = _dotCount(dotLocs1) >= _dotCount(dotLocs2);
    return usePrimary ? dotLocs1 : dotLocs2;
  }
}

// ---------------------------------------------------------------------------
// Chord helper for dot locations
// ---------------------------------------------------------------------------

extension ChordDotLocations on Chord {
  /// Port of the free function `CalculateDotLocations` (chord.cpp:42) for an
  /// ascending list of note locations (duplicates allowed — the source is a
  /// `multiset`, see [_calcDotLocations]).
  ///
  /// [reverseOrder] mirrors `isReverseOrder`: iterate the locations in
  /// descending order with the adjustment list negated. Unlike the note
  /// loop, this can genuinely *drop* a location when none of the 5
  /// candidate offsets is both odd and free — matching the C++, which uses
  /// `std::set::insert` and simply moves to the next note when every
  /// attempt fails (no shift-until-free loop).
  Set<int> _calculateDotLocations(List<int> locs, bool reverseOrder) {
    final List<int> locAdjust = reverseOrder
        ? const [0, -1, 1, 2, -2]
        : const [0, 1, -1, -2, 2];
    final List<int> order = reverseOrder ? locs.reversed.toList() : locs;
    final Set<int> dotLocations = {};
    for (var i = 0; i < order.length; i++) {
      final int loc = order[i];
      for (final int adjust in locAdjust) {
        final int candidate = loc + adjust;
        if (candidate.isEven) continue;
        if (i != 0 && order[i - 1] == loc && adjust == -2) continue;
        if (dotLocations.add(candidate)) break;
      }
    }
    return dotLocations;
  }

  /// Port of `Chord::CalcDotLocations` (chord.cpp:573) for a single staff
  /// (no cross-staff notes): compute the note locations (deduplicated, as
  /// the C++ `std::set<int>` does via `CalcNoteLocations`), sorted
  /// ascending, then feed [_calculateDotLocations] in the requested order.
  Set<int> _calcDotLocations(int layerCount, bool primary) {
    final bool isUpwardDirection =
        (getDrawingStemDir() == Stemdirection.up) || (layerCount == 1);
    final bool useReverseOrder = isUpwardDirection != primary;

    // `MapOfNoteLocs` is `map<Staff*, multiset<int>>` (vrvdef.h:400) — a
    // *multiset*, not a set: two unison notes at the same loc both survive
    // into the sorted list (each still needs its own dot, just nudged to a
    // different odd slot by `_calculateDotLocations`'s duplicate-aware
    // `adjust == -2` guard). Using a `Set` here previously collapsed
    // same-loc notes before the odd-slot search ever ran, silently merging
    // the two dots of a same-space unison into one (regression on
    // `dot/dot-006.mei`, "Single stemmed dotted unisons").
    final List<int> noteLocs = [];
    for (final Object child in getList()) {
      final Note note = child as Note;
      // Mirrors the `CalcNoteLocations` predicate `!note->HasDots()`: skip
      // notes that already carry their own explicit @dots.
      if (note.hasDots) continue;
      noteLocs.add(note.calcDrawingLocHeadless());
    }
    noteLocs.sort();
    return _calculateDotLocations(noteLocs, useReverseOrder);
  }

  /// [_calcDotLocations] wrapped as a `{staff: locs}` map, for the single
  /// staff this port targets — the shape `CalcDotsFunctor._elementCalcDotLocations`
  /// needs to treat a [Chord] uniformly with a [Note] in the two-layer
  /// collision comparison.
  Map<Object, Set<int>> _dotLocationsFor(int layerCount, bool primary) {
    final Staff staff = getAncestorStaffLayout();
    return {staff: _calcDotLocations(layerCount, primary)};
  }

  /// Mirrors `LayerElement::CalcOptimalDotLocations` (layerelement.cpp:909)
  /// for [Chord], for a single staff (no cross-staff notes). With another
  /// note (or its chord) on a different layer of the same staff
  /// (`layerCount == 2`), picks whichever of the "primary" (above) /
  /// "secondary" (below) dot placements collides least with it — the
  /// unison short-circuit does not apply here (`this->Is(NOTE)` is false
  /// for a chord in the C++). With no other layer, or no collision at all,
  /// falls back to the dot-count comparison, primary winning ties —
  /// mirrors `usePrimary = GetDotCount(dotLocs1) >= GetDotCount(dotLocs2)`.
  Map<Object, Set<int>> calcOptimalDotLocations() {
    final LayerElement? other = CalcDotsFunctor._findOtherLayerElement(this);
    final int layerCount = (other != null) ? 2 : 1;

    final Map<Object, Set<int>> dotLocs1 = _dotLocationsFor(layerCount, true);
    final Map<Object, Set<int>> dotLocs2 = _dotLocationsFor(layerCount, false);

    if (layerCount == 2 && other != null) {
      final int currentLayerN = getAlignmentLayerN().abs();
      final int otherLayerN = other.getAlignmentLayerN().abs();
      final Map<Object, Set<int>> otherDotLocs1 =
          CalcDotsFunctor._elementCalcDotLocations(other, layerCount, true);
      final Map<Object, Set<int>> otherDotLocs2 =
          CalcDotsFunctor._elementCalcDotLocations(other, layerCount, false);

      final int c11 = CalcDotsFunctor._collisionCount(dotLocs1, otherDotLocs1);
      final int c12 = CalcDotsFunctor._collisionCount(dotLocs1, otherDotLocs2);
      final int c21 = CalcDotsFunctor._collisionCount(dotLocs2, otherDotLocs1);
      final int c22 = CalcDotsFunctor._collisionCount(dotLocs2, otherDotLocs2);
      final int maxCollisions = [c11, c12, c21, c22].reduce(math.max);

      if (maxCollisions > 0) {
        final int minCollisions = [c11, c12, c21, c22].reduce(math.min);
        if (c11 == minCollisions) return dotLocs1;
        if (c12 == minCollisions) {
          if (c21 == minCollisions) {
            return (currentLayerN < otherLayerN) ? dotLocs1 : dotLocs2;
          }
          return dotLocs1;
        }
        return dotLocs2;
      }
    }

    final bool usePrimary =
        CalcDotsFunctor._dotCount(dotLocs1) >= CalcDotsFunctor._dotCount(dotLocs2);
    return usePrimary ? dotLocs1 : dotLocs2;
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
  Staff? staffAbove;
  Staff? staffBelow;
  Layer? layerAbove;
  Layer? layerBelow;
  bool crossStaffAbove = false;
  bool crossStaffBelow = false;

  @override
  FunctorCode visitArtic(Artic artic) {
    if (parent == null) return FunctorCode.continue_;

    /************** placement **************/

    Layer? layer = artic.getFirstAncestor(ClassId.layer) as Layer?;

    if (parent!.crossLayer is Layer) {
      layer = parent!.crossLayer as Layer;
    }

    bool allowAbove = true;

    // For now we ignore within @place.
    if (artic.place != null && artic.place != Staffrel.none) {
      artic.drawingPlace = artic.place!;
      // if we have a place indication do not allow to be changed to above
      allowAbove = false;
    } else if (layer != null &&
        layer.getDrawingStemDirFor(parent!) != Stemdirection.none) {
      artic.drawingPlace = layer.getDrawingStemDirFor(parent!) ==
              Stemdirection.up
          ? Staffrel.above
          : Staffrel.below;
      // If we have more than one layer do not allow to be changed to above
      allowAbove = false;
    } else if (stemDir == Stemdirection.up) {
      artic.drawingPlace = Staffrel.below;
    } else {
      artic.drawingPlace = Staffrel.above;
    }

    // Not sure what this is anymore... (calcarticfunctor.cpp:68-73)
    if (artic.isOutsideArtic()) {
      // If allowAbove is true it will place the artic above if the content
      // requires so (even if place below is given).
      if (artic.drawingPlace == Staffrel.below &&
          allowAbove &&
          artic.alwaysAbove()) {
        artic.drawingPlace = Staffrel.above;
      }
    }

    /************** adjust the xRel position **************/

    final Stem? stem = parent!.findDescendantByType(ClassId.stem) as Stem?;
    artic.setDrawingXRel(calculateHorizontalShift(artic, stem?.getIsVirtual() ?? false));

    /************** set cross-staff / layer **************/

    // Exception for artic because they are relative to the staff - we set
    // m_crossStaff and m_crossLayer (calcarticfunctor.cpp:91-99).
    if ((artic.drawingPlace == Staffrel.above) && crossStaffAbove) {
      artic.crossStaff = staffAbove;
      artic.crossLayer = layerAbove;
    } else if ((artic.drawingPlace == Staffrel.below) && crossStaffBelow) {
      artic.crossStaff = staffBelow;
      artic.crossLayer = layerBelow;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitChord(Chord chord) {
    parent = chord;
    stemDir = chord.getDrawingStemDir();

    final Staff? staff = chord.getFirstAncestor(ClassId.staff) as Staff?;
    final Layer? layer = chord.getFirstAncestor(ClassId.layer) as Layer?;

    staffAbove = staff;
    staffBelow = staff;
    layerAbove = layer;
    layerBelow = layer;
    crossStaffAbove = false;
    crossStaffBelow = false;

    if (chord.crossStaff is Staff) {
      staffAbove = chord.crossStaff as Staff;
      staffBelow = chord.crossStaff as Staff;
      layerAbove = chord.crossLayer;
      layerBelow = chord.crossLayer;
      crossStaffAbove = true;
      crossStaffBelow = true;
    } else {
      final (Staff?, Staff?, Layer?, Layer?) extremes =
          chord.getCrossStaffExtremes();
      if (extremes.$1 != null) {
        staffAbove = extremes.$1;
        layerAbove = extremes.$3;
        crossStaffAbove = true;
        staffBelow = staff;
        layerBelow = layer;
      } else if (extremes.$2 != null) {
        staffBelow = extremes.$2;
        layerBelow = extremes.$4;
        crossStaffBelow = true;
        staffAbove = staff;
        layerAbove = layer;
      }
    }

    includeBeamStaff(chord);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNote(Note note) {
    if (note.isChordTone() != null) return FunctorCode.continue_;

    parent = note;
    stemDir = note.getDrawingStemDir();

    final Staff? staff = note.getFirstAncestor(ClassId.staff) as Staff?;
    final Layer? layer = note.getFirstAncestor(ClassId.layer) as Layer?;

    staffAbove = staff;
    staffBelow = staff;
    layerAbove = layer;
    layerBelow = layer;
    crossStaffAbove = false;
    crossStaffBelow = false;

    if (note.crossStaff is Staff) {
      staffAbove = note.crossStaff as Staff;
      staffBelow = note.crossStaff as Staff;
      layerAbove = note.crossLayer;
      layerBelow = note.crossLayer;
      crossStaffAbove = true;
      crossStaffBelow = true;
    }

    includeBeamStaff(note);

    return FunctorCode.continue_;
  }

  /// Mirrors `CalcArticFunctor::CalculateHorizontalShift`
  /// (calcarticfunctor.cpp:174): the x offset of an artic from its parent's
  /// center, accounting for stem-side staccato placement.
  int calculateHorizontalShift(Artic artic, bool virtualStem) {
    int shift = parent!.getDrawingRadius(doc);
    if (virtualStem ||
        (parent!.getChildCount(ClassId.artic) > 1) ||
        doc.getOptions().staccatoCenter.value) {
      return shift;
    }
    switch (artic.getArticFirst()) {
      case Articulation.stacc:
      case Articulation.stacciss:
        final Staff? staff = artic.getFirstAncestor(ClassId.staff) as Staff?;
        if (staff == null) break;
        final int stemWidth = doc.getDrawingStemWidth(staff.drawingStaffSize);
        if ((stemDir == Stemdirection.up) &&
            (artic.drawingPlace == Staffrel.above)) {
          shift += shift - stemWidth ~/ 2;
        } else if ((stemDir == Stemdirection.down) &&
            (artic.drawingPlace == Staffrel.below)) {
          shift = stemWidth ~/ 2;
        }
        break;
      default:
        break;
    }
    return shift;
  }

  /// Mirrors `CalcArticFunctor::IncludeBeamStaff`
  /// (calcarticfunctor.cpp:201): when the parent sits in a beam placed
  /// above/below, the artic's cross-staff side follows the beam's staff.
  void includeBeamStaff(LayerElement layerElement) {
    final Beam? beam = layerElement.getAncestorBeam();
    if (beam == null) return;
    if (crossStaffAbove && (beam.drawingPlace == Beamplace.above)) {
      staffAbove =
          beam.getAncestorStaffResolveCrossStaff() as Staff?;
    } else if (crossStaffBelow && (beam.drawingPlace == Beamplace.below)) {
      staffBelow =
          beam.getAncestorStaffResolveCrossStaff() as Staff?;
    }
  }
}

// ---------------------------------------------------------------------------
// CalcSlurDirectionFunctor
// ---------------------------------------------------------------------------

/// Compute the curve direction of slurs (mirrors
/// `vrv::CalcSlurDirectionFunctor`, calcslurdirectionfunctor.cpp:34-120).
class CalcSlurDirectionFunctor extends DocFunctor {
  CalcSlurDirectionFunctor(super.doc);

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSlur(Slur slur) {
    // If curve direction is prescribed as above or below, use it
    // (calcslurdirectionfunctor.cpp:37).
    if (slur.hasCurvedir && slur.curvedir != CurvatureCurvedir.mixed) {
      slur.setDrawingCurveDir(slur.curvedir == CurvatureCurvedir.above
          ? SlurCurveDirection.above
          : SlurCurveDirection.below);
    }
    if (slur.hasDrawingCurveDir()) return FunctorCode.continue_;

    // Retrieve boundary (calcslurdirectionfunctor.cpp:44).
    final LayerElement? start = slur.getStart();
    final LayerElement? end = slur.getEnd();
    if (start == null || end == null) {
      slur.setDrawingCurveDir(SlurCurveDirection.above);
      return FunctorCode.continue_;
    }

    // If curve direction is prescribed as mixed, use it if boundary lies in
    // different staves (calcslurdirectionfunctor.cpp:52).
    if (slur.curvedir == CurvatureCurvedir.mixed) {
      if (slur.hasBulge) {
        logWarning('Mixed curve direction is ignored for slurs with '
            'prescribed bulge.');
      } else if (start.classId == ClassId.timestampAttr ||
          end.classId == ClassId.timestampAttr) {
        logWarning('Mixed curve direction is ignored for slurs with tstamp '
            'boundary.');
      } else {
        final Staff? startStaff =
            start.getAncestorStaffLayoutOrNull() ?? start.crossStaff;
        final Staff? endStaff =
            end.getAncestorStaffLayoutOrNull() ?? end.crossStaff;
        final int startStaffN = startStaff?.n ?? meiUnset;
        final int endStaffN = endStaff?.n ?? meiUnset;
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

    // Retrieve staves and system (calcslurdirectionfunctor.cpp:77).
    final Measure? startMeasure = slur.getStartMeasure();
    List<Staff> staffList = [];
    if (startMeasure != null) {
      staffList = slur.getTstampStaves(startMeasure, slur);
    }
    if (staffList.isEmpty) {
      slur.setDrawingCurveDir(SlurCurveDirection.above);
      return FunctorCode.continue_;
    }
    final Staff staff = staffList.first;
    final System? system =
        staff.getFirstAncestor(ClassId.system) as System?;

    // Mirrors `slur->GetBoundaryCrossStaff() != NULL`
    // (calcslurdirectionfunctor.cpp:86).
    final bool isCrossStaff = slur.getBoundaryCrossStaff() != null;
    final bool isGraceToNoteSlur = start.classId != ClassId.timestampAttr &&
        end.classId != ClassId.timestampAttr &&
        start.isGraceNote() &&
        !end.isGraceNote();

    if (start.classId != ClassId.timestampAttr &&
        end.classId != ClassId.timestampAttr &&
        !isGraceToNoteSlur &&
        system != null &&
        system.hasMixedDrawingStemDir(start, end)) {
      // Handle mixed stem direction (calcslurdirectionfunctor.cpp:90).
      if (isCrossStaff &&
          (system.getPreferredCurveDirection(start, end, slur) ==
              CurvatureCurvedir.below)) {
        slur.setDrawingCurveDir(SlurCurveDirection.below);
      } else {
        slur.setDrawingCurveDir(SlurCurveDirection.above);
      }
    } else {
      // Handle uniform stem direction, time stamp boundaries and grace note
      // slurs (calcslurdirectionfunctor.cpp:100).
      Stemdirection startStemDir = Stemdirection.none;
      final StemmedDrawingInterface? startStemDrawInterface =
          start.getStemmedDrawingInterface();
      if (startStemDrawInterface != null) {
        startStemDir = startStemDrawInterface.getDrawingStemDir();
      }

      final int center = staff.getDrawingY() -
          doc.getDrawingStaffSize(staff.drawingStaffSize) ~/ 2;
      final bool isAboveStaffCenter = (start.getDrawingY() > center);
      if (getPreferredCurveDirection(
              slur, startStemDir, isAboveStaffCenter, isGraceToNoteSlur) ==
          CurvatureCurvedir.below) {
        slur.setDrawingCurveDir(SlurCurveDirection.below);
      } else {
        slur.setDrawingCurveDir(SlurCurveDirection.above);
      }
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `CalcSlurDirectionFunctor::GetGraceCurveDirection`
  /// (calcslurdirectionfunctor.cpp:122).
  CurvatureCurvedir getGraceCurveDirection(Slur slur) {
    // Start on the notehead side.
    final LayerElement? start = slur.getStart();
    final StemmedDrawingInterface? startStemDrawInterface =
        start?.getStemmedDrawingInterface();
    final bool isStemDown = startStemDrawInterface != null &&
        startStemDrawInterface.getDrawingStemDir() == Stemdirection.down;
    return isStemDown ? CurvatureCurvedir.above : CurvatureCurvedir.below;
  }

  /// Backwards-compatible alias kept for the headless callers inside this
  /// file (same body as [getPreferredCurveDirection]).
  CurvatureCurvedir _getGraceCurveDirection(Slur slur) =>
      getGraceCurveDirection(slur);

  /// Mirrors `CalcSlurDirectionFunctor::GetPreferredCurveDirection`
  /// (calcslurdirectionfunctor.cpp:132).
  ///
  /// Deviation: the C++ takes the start [LayerElement] only implicitly
  /// (through `slur->GetStart()`); this port keeps the explicit
  /// [startElement] parameter from the earlier headless version and reads
  /// `layer->GetDrawingStemDir(layerElement)` through the element-aware
  /// `Layer.getDrawingStemDir` (layer.h:114) instead of the bare overload.
  CurvatureCurvedir getPreferredCurveDirection(
      Slur slur,
      Stemdirection noteStemDir,
      bool isAboveStaffCenter,
      bool isGraceToNoteSlur) {
    final LayerElement? startElement = slur.getStart();
    return _getPreferredCurveDirection(
        slur, startElement, noteStemDir, isGraceToNoteSlur);
  }

  /// Shared body of [getPreferredCurveDirection] (see above).
  CurvatureCurvedir _getPreferredCurveDirection(
      Slur slur,
      LayerElement? startElement,
      Stemdirection noteStemDir,
      bool isGraceToNoteSlur) {
    Note? startNote;
    Chord? startParentChord;
    if (startElement != null && startElement.classId == ClassId.note) {
      startNote = startElement as Note;
      startParentChord = startNote.isChordTone() as Chord?;
    }

    // Mirrors `std::tie(layer, layerElement) = slur->GetBoundaryLayer()`
    // (calcslurdirectionfunctor.cpp:145) — now wired to `Slur` instead of
    // the start element alone.
    Layer? layer;
    LayerElement? layerElement;
    final boundary = slur.getBoundaryLayer();
    layer = boundary.$1;
    layerElement = boundary.$2;
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
    // Otherwise layer direction trumps note direction
    // (calcslurdirectionfunctor.cpp:160).
    else if (layer != null &&
        layerElement != null &&
        (layerStemDir = layer.getDrawingStemDirFor(layerElement)) !=
            Stemdirection.none) {
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
