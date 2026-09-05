/// Port of `beam.h` / `beam.cpp` — `BeamSegment` and `BeamElementCoord`
/// (`origin/src/include/vrv/beam.h:36` and `:395`, `origin/src/src/beam.cpp`).
///
/// Task 05-31 moves the calculation engine from `view_beam.dart` (where it was
/// re-implemented in reduced form) to the model, as in the C++ (beam.cpp:89,
/// drawinginterface.cpp:140). Task 05-31b (this file, current pass) ports the
/// Y-axis engine that was previously stubbed: `SetDrawingStemDir`'s geometry
/// (beam.cpp:1837), `CalcStemDefiningNote`/`CalcBeamStemLength`
/// (beam.cpp:1200/1271 — the real per-beam stem length, replacing a fixed
/// `unit*3.5` approximation), `CalcAdjustPosition` (beam.cpp:1084),
/// `AdjustBeamToLedgerLines` (beam.cpp:509), `CalcSetStemValues`
/// (beam.cpp:149) and the mixed-beam reset helpers (`NeedToResetPosition`,
/// `DoesBeamOverlap`, `GetVerticalOffset`, `GetMinimalStemLength`,
/// beam.cpp:303-452). The View must not re-implement it.
///
/// Deviations from the C++ (all scoped deliberately to keep this pass
/// reviewable — see `prompts/loop-diario.md` 2026-09-04 for the investigation
/// that motivated it):
/// - `m_beamElementCoordRefs` holds references to the same objects owned by
///   `BeamDrawingInterface`; the two lists are kept in sync via `initCoordRefs`.
/// - `m_stemSameasReverseRole` (a `data_STEMSAMEASDRAWINGROLE *` in the C++,
///   pointing directly at the *other* beam's role field so that
///   `UpdateSameasRoles` can set both beams' roles from whichever beam
///   computes `CalcBeamPlace` first) is ported as [stemSameasReversePartner],
///   a nullable reference to the *other* `BeamSegment` itself, since Dart has
///   no pointer-to-field. [updateSameasRoles] writes through it to the
///   partner's `stemSameasRole` directly, reproducing the write-through the
///   C++ pointer gives for free. An earlier pass (2026-09-05) stored a copy
///   of the *value* instead of a live reference, which silently broke the
///   propagation: the partner beam's role never left `unset`, so
///   `stemSameasIsSecondary()` was false for both of a `stem.sameas` pair and
///   both drew their own beam polygon (see `prompts/loop-diario.md`, trilha
///   ESTRUTURAL, `stem-014`/`stem-016`).
/// - The non-mixed slope engine (`CalcBeamSlope`/`CalcBeamSlopeStep`/
///   `CalcAdjustSlope`/`CalcHorizontalBeam`, beam.cpp:702-897/964-1082/
///   1339-1367) and the real `BeamDrawingInterface::IsHorizontal`/
///   `IsRepeatedPattern`/`HasOneStepHeight`/`IsHorizontalMixedBeam`
///   (drawinginterface.cpp:295/365/418/472, in `drawing_interfaces.dart`)
///   are now ported. The mixed-beam counterparts
///   (`CalcMixedBeamPosition`/`CalcMixedBeamCenterY`, beam.cpp:1088-1234)
///   remain stubs — [calcBeam]'s mixed-place branch keeps its pre-existing
///   fixed-formula approximation, since `NeedToResetPosition`'s retry (see
///   below) is not wired in either and the two belong together.
/// - `initCoords` (`drawing_interfaces.dart`) sets each coord's
///   `closestNote`/`stem` eagerly, from the element itself, rather than
///   leaving them null until `SetClosestNoteOrTabDurSym`/`SetDrawingStemDir`
///   run later — a pre-existing simplification `IsHorizontal` inherits: on a
///   beam's first pass through the pipeline it sees this eager guess instead
///   of the C++'s "unset", and only sees the real, per-pass-refined values
///   from the second pass onward (since [beamElementCoordRefs] and
///   `BeamDrawingInterface.beamElementCoordsOwned` share the same
///   [BeamElementCoord] instances).
/// - `AdjustBeamToFrenchStyle` (beam.cpp:454) is gated by the unported
///   `beamFrenchStyle` option (default `false` in the C++ — never triggers)
///   and is not ported; it remains a no-op stub. `AdjustBeamToTremolos`
///   (beam.cpp:541) *is* now ported, using `Stem.calculateStemModAdjustment`
///   (`layer_elements_gen.dart`, distinct from
///   `BeamElementCoord.calculateStemModAdjustment` which was already
///   ported).
/// - `NeedToResetPosition`'s two option reads (`beamMixedPreserve`,
///   `beamMixedStemMin`) are not in `options_shell.dart` yet (118/210 ported);
///   this port hardcodes their C++ defaults (`false`, `3.5`) rather than
///   wiring unrelated new options for a mixed-beam-only path.
/// - `NeedToResetPosition`'s retry (`CalcBeamInit`/`CalcBeamStemLength`/
///   `CalcBeamPosition` called again, beam.cpp:131-135) is not wired into
///   [calcBeam]: the helpers are ported and correct in isolation, but
///   `CalcBeamInit`'s equivalent is still inlined in [calcBeam] rather than a
///   standalone re-callable method. Wiring the retry is left for a future
///   iteration (mixed beams are not the target of this pass).
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration, meiUnset;
import 'package:verovio_dart/src/core/bounding_box.dart' show BoundingBox;
import 'package:verovio_dart/src/core/point.dart' show Point;
import 'package:verovio_dart/src/core/vrvdef.dart'
    show
        ClassId,
        StemSameasDrawingRole,
        spanningEnd,
        spanningMiddle,
        spanningStart,
        spanningStartEnd,
        standardStemLength;
import 'package:verovio_dart/src/model/atts/atts_shared.dart' show AttStems;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Layer, Measure, Staff, Note;
import 'package:verovio_dart/src/model/doc.dart' show Doc;
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show BeamDrawingInterface, StemmedDrawingInterface;
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Artic, Beam, Chord, Stem;
import 'package:verovio_dart/src/model/object.dart';

// -----------------------------------------------------------------------------
// Hardcoded C++ option defaults for options not yet ported to options_shell.dart
// (see the class doc comment "Deviations from the C++").
// -----------------------------------------------------------------------------
const bool _beamMixedPreserveDefault = false;
const double _beamMixedStemMinDefault = 3.5;

/// Mirrors the `Note::GetStemUpSE` / `Note::GetStemDownNW` dispatch through
/// `Chord::GetStemUpSE` / `Chord::GetStemDownNW` (chord.cpp:358-370): a
/// chord's own stem cut-out point is taken from its bottom note (stem up) or
/// top note (stem down), since Dart's `Chord` does not itself carry a
/// `getStemUpSE`/`getStemDownNW` override (only [Note] does).
Point _stemAnchorFor(Object el,
    {required bool up, required dynamic doc, required int staffSize, required bool cueSize}) {
  if (el is Note) {
    return up
        ? el.getStemUpSE(doc, staffSize, cueSize)
        : el.getStemDownNW(doc, staffSize, cueSize);
  }
  if (el is Chord) {
    if (up) {
      final Note? bottom = el.getBottomNote();
      return bottom?.getStemUpSE(doc, staffSize, cueSize) ?? Point(0, 0);
    } else {
      final Note? top = el.getTopNote();
      return top?.getStemDownNW(doc, staffSize, cueSize) ?? Point(0, 0);
    }
  }
  return Point(0, 0);
}

/// Returns the [MeiDuration] with the given [value], or [MeiDuration.none]
/// when no member has that value (mirrors the C++'s permissive
/// `static_cast<data_DURATION>` in `CalcStemDefiningNote`, beam.cpp:1333,
/// which can land on a value with no named enumerator).
MeiDuration _durationFromValueOrNone(int value) {
  for (final MeiDuration d in MeiDuration.values) {
    if (d.value == value) return d;
  }
  return MeiDuration.none;
}

/// Port of `vrv::BeamElementCoord` (beam.h:395).
class BeamElementCoord {
  int x = 0;
  int yBeam = 0;
  MeiDuration dur = MeiDuration.dur8;
  int breaksec = 0;
  int overlapMargin = 0;
  Beamplace partialFlagPlace = Beamplace.none;
  Beamplace beamRelativePlace = Beamplace.none;
  final List<int> partialFlags = List<int>.filled(16, 0);
  Object? element;
  Object? closestNote;
  Object? tabDurSym;
  Object? stem;
  bool centered = false;

  /// Mirrors `BeamElementCoord::GetStemDir` (beam.h:417).
  /// C++: if (m_stem) return m_stem-&gt;GetDir();
  ///      if (!m_element) return NONE;
  ///      AttStems iface = dynamic_cast&lt;AttStems*&gt;(m_element);
  ///      if (!iface) return NONE;
  ///      return iface-&gt;GetStemDir();
  Stemdirection getStemDir() {
    final Object? s = stem;
    if (s != null) {
      if (s is Stem) {
        final Stemdirection? dir = s.dir;
        if (dir != null) return dir;
        return s.getDrawingStemDir();
      }
      if (s is AttStems) {
        final Stemdirection? dir = (s as AttStems).stemDir;
        if (dir != null) return dir;
      }
    }
    final Object? el = element;
    if (el == null) return Stemdirection.none;
    if (el is AttStems) {
      final Stemdirection? dir = (el as AttStems).stemDir;
      if (dir != null) return dir;
    }
    return Stemdirection.none;
  }

  /// Mirrors `BeamElementCoord::SetDrawingStemDir` (beam.cpp:1837) — full
  /// geometry: stem-direction propagation, the X cut-out anchor (via
  /// [_stemAnchorFor], analogous to `chord.cpp:358-370` for chords), the Y
  /// anchor off the closest note plus `uniformStemLength`, the cue-note
  /// shift, and the vertical-center snap.
  ///
  /// Deviation: the `m_tabDurSym` branch (beam.cpp:1880-1884) is not ported —
  /// tablature rendering is out of scope elsewhere in this port too.
  void setDrawingStemDir(Stemdirection stemDir, Object? staffObj, Object? docObj,
      BeamSegment segment, dynamic beamInterface) {
    if (staffObj is! Staff || docObj is! Doc || beamInterface == null) return;
    final Staff staff = staffObj;
    final Doc doc = docObj;
    final Object? el = element;
    if (el == null) return;

    int stemLen = segment.uniformStemLength;
    if (beamInterface.crossStaffContent != null ||
        beamInterface.drawingPlace == Beamplace.mixed) {
      if ((stemDir == Stemdirection.up && stemLen < 0) ||
          (stemDir == Stemdirection.down && stemLen > 0)) {
        stemLen = -stemLen;
      }
    }
    final bool elIsGrace = (el is LayerElement) && el.isGraceNote();
    centered = (segment.uniformStemLength % 2 != 0) || elIsGrace;

    if ((el.classId == ClassId.rest || el.classId == ClassId.space) && el is LayerElement) {
      x += el.getDrawingRadius(doc);
      yBeam = el.getDrawingY();
      yBeam += (stemLen * doc.getDrawingUnit(staff.drawingStaffSize)) ~/ 2;
      return;
    }

    final StemmedDrawingInterface? stemIface = getStemHolderInterface();
    if (stemIface == null) return;

    final Stem? s = stemIface.getDrawingStem();
    stem = s;
    if (s == null) return;
    s.setDrawingStemDir(stemDir);
    yBeam = el.getDrawingY();

    final bool cueSize = beamInterface.cueSize as bool;
    final int staffSize = staff.drawingStaffSize;
    if (stemDir == Stemdirection.up) {
      final Point p =
          _stemAnchorFor(el, up: true, doc: doc, staffSize: staffSize, cueSize: cueSize);
      x += p.x;
      x -= doc.getDrawingStemWidth(staffSize) ~/ 2;
    } else {
      final Point p =
          _stemAnchorFor(el, up: false, doc: doc, staffSize: staffSize, cueSize: cueSize);
      x += p.x;
      x += doc.getDrawingStemWidth(staffSize) ~/ 2;
    }

    final Object? cn = closestNote;
    if (cn == null || cn is! Note) return;

    if (!cueSize &&
        elIsGrace &&
        el.getFirstAncestor(ClassId.chord) == null &&
        stemDir == Stemdirection.up) {
      final double cueScaling = doc.getCueScaling() as double;
      final int diameter = 2 * el.getDrawingRadius(doc);
      final double cueShift = (1.0 / cueScaling - 1.0) * diameter;
      x -= cueShift.toInt();
    }

    yBeam = cn.getDrawingY();
    yBeam += (stemLen * doc.getDrawingUnit(staffSize)) ~/ 2;

    if (elIsGrace) return;

    final bool isSpanningElement = beamInterface.isSpanningElement as bool;
    if (!isSpanningElement &&
        beamInterface.crossStaffContent == null &&
        beamInterface.drawingPlace != Beamplace.mixed) {
      if ((stemDir == Stemdirection.up && yBeam <= segment.verticalCenter) ||
          (stemDir == Stemdirection.down && segment.verticalCenter <= yBeam)) {
        yBeam = segment.verticalCenter;
        centered = false;
      }
    }

    yBeam += overlapMargin;
  }

  /// Mirrors `BeamElementCoord::SetClosestNoteOrTabDurSym` (beam.cpp:2002).
  ///
  /// Deviation: the `TABGRP` branch is not ported (no tablature rendering).
  void setClosestNoteOrTabDurSym(Stemdirection dir, bool outsideStaff) {
    closestNote = null;
    final Object? el = element;
    if (el == null) return;
    if (el is Note) {
      closestNote = el;
    } else if (el is Chord) {
      closestNote = dir == Stemdirection.up ? el.getTopNote() : el.getBottomNote();
    }
  }

  /// Mirrors `BeamElementCoord::CalculateStemLength` (beam.cpp:1915).
  int calculateStemLength(
      Object? staffObj, Stemdirection stemDir, bool isHorizontal, MeiDuration preferredDur) {
    if (staffObj is! Staff) return 0;
    final Object? cn = closestNote;
    if (cn == null || cn is! Note) return 0;
    final Staff staff = staffObj;
    final Note closest = cn;

    final bool onStaffSpace = closest.drawingLoc % 2 != 0;
    bool extend = onStaffSpace;
    const int standardStemLen = standardStemLength * 2;
    final int stemLenInHalfUnits = closest.calcStemLenInThirdUnits(staff, stemDir) * 2 ~/ 3;
    if (stemLenInHalfUnits != standardStemLen) extend = false;

    final int directionBias = stemDir == Stemdirection.up ? 1 : -1;
    int stemLen = directionBias;
    if (preferredDur == MeiDuration.dur8) {
      if (stemLenInHalfUnits != standardStemLen) {
        stemLen *= stemLenInHalfUnits;
      } else {
        stemLen *= (onStaffSpace || !isHorizontal) ? 14 : 13;
      }
    } else {
      final bool isOddLength = extend || !isHorizontal;
      switch (dur) {
        case MeiDuration.dur16:
          stemLen *= isOddLength ? 14 : 13;
          break;
        case MeiDuration.dur32:
          stemLen *= isOddLength ? 18 : 16;
          break;
        case MeiDuration.dur64:
          stemLen *= isOddLength ? 22 : 20;
          break;
        case MeiDuration.dur128:
          stemLen *= isOddLength ? 26 : 24;
          break;
        case MeiDuration.dur256:
          stemLen *= isOddLength ? 30 : 28;
          break;
        case MeiDuration.dur512:
          stemLen *= isOddLength ? 34 : 32;
          break;
        case MeiDuration.dur1024:
          stemLen *= isOddLength ? 38 : 36;
          break;
        default:
          stemLen *= 14;
      }
    }

    return stemLen + calculateStemModAdjustment(stemLen, directionBias);
  }

  /// Mirrors `BeamElementCoord::CalculateStemLengthTab` (beam.cpp:1959).
  int calculateStemLengthTab(Object? staff, Stemdirection dir) => 0;

  /// Mirrors `BeamElementCoord::CalculateStemModAdjustment` (beam.cpp:1967).
  int calculateStemModAdjustment(int stemLength, int directionBias) {
    int slashFactor = 0;
    final Object? el = element;
    if (el is Note) {
      final Object? cn = closestNote;
      if (cn is Note) {
        final Stemmodifier mod = cn.stemMod ?? Stemmodifier.none;
        if (mod.value < Stemmodifier.sprech.value) slashFactor = mod.value - 1;
      }
    } else if (el is Chord) {
      final Stemmodifier mod = el.stemMod ?? Stemmodifier.none;
      if (mod.value < Stemmodifier.sprech.value) slashFactor = mod.value - 1;
    }
    final int stemLengthInUnits = (stemLength ~/ 2).abs();
    if (stemLengthInUnits - 3 < slashFactor) {
      return directionBias * (3 + slashFactor - stemLengthInUnits) * 4;
    }
    return 0;
  }

  /// Mirrors `BeamElementCoord::GetStemHolderInterface` (beam.cpp:1988).
  ///
  /// Deviation: the `TABGRP` branch is not ported (no tablature rendering).
  StemmedDrawingInterface? getStemHolderInterface() {
    final Object? el = element;
    if (el == null) return null;
    if (el is Note || el is Chord) {
      return (el as LayerElement).getStemmedDrawingInterface();
    }
    return null;
  }

  /// Mirrors `BeamElementCoord::UpdateStemLength` (beam.cpp:2023) — including
  /// the mixed-beam existing-articulation adjustment.
  void updateStemLength(
      StemmedDrawingInterface? stemmedInterface, int y1, int y2, int stemAdjust, bool inMixedBeam) {
    if (stemmedInterface == null) return;
    final Stem? stemObj = stemmedInterface.getDrawingStem();
    if (stemObj == null) return;
    final Object? el = element;
    if (el == null || el is! LayerElement) return;

    stemObj.setDrawingXRel(x - el.getDrawingX());
    stemObj.setDrawingYRel(y2 - el.getDrawingY());
    final int prevStemLen = stemObj.getDrawingStemLen();
    final int newStemLen = y2 - y1;
    stemObj.setDrawingStemLen(newStemLen);
    stemObj.drawingStemAdjust = -stemAdjust;
    final int lenChange = newStemLen - prevStemLen;
    if (lenChange == 0 || !inMixedBeam) return;

    final List<Object> artics = el.findAllDescendantsByType(ClassId.artic);
    for (final Object a in artics) {
      if (a is Artic) {
        final bool up =
            a.drawingPlace == Staffrel.above && stemObj.getDrawingStemDir() == Stemdirection.up;
        final bool down =
            a.drawingPlace == Staffrel.below && stemObj.getDrawingStemDir() == Stemdirection.down;
        if (up || down) {
          a.setDrawingYRel(a.drawingYRel - lenChange);
        }
      }
    }
  }
}

/// Port of `vrv::BeamSegment` (beam.h:36).
class BeamSegment {
  double beamSlope = 0.0;
  int verticalCenter = 0;
  int ledgerLinesAbove = 0;
  int ledgerLinesBelow = 0;
  int uniformStemLength = 0;
  Beamplace weightedPlace = Beamplace.none;
  BeamElementCoord? firstNoteOrChord;
  BeamElementCoord? lastNoteOrChord;
  int nbNotesOrChords = 0;
  StemSameasDrawingRole stemSameasRole = StemSameasDrawingRole.none;

  /// Mirrors `m_stemSameasReverseRole` (beam.h:214) — see the class doc
  /// comment "Deviations from the C++" for why this is a reference to the
  /// partner [BeamSegment], not a copy of its role.
  BeamSegment? stemSameasReversePartner;

  bool stemSameasIsSecondary() => stemSameasRole == StemSameasDrawingRole.secondary;
  bool stemSameasIsUnset() => stemSameasRole == StemSameasDrawingRole.unset;
  bool stemSameasIsPrimary() => stemSameasRole == StemSameasDrawingRole.primary;

  final List<BeamElementCoord> beamElementCoordRefs = <BeamElementCoord>[];

  void initCoordRefs(List<BeamElementCoord> coords) {
    beamElementCoordRefs.clear();
    beamElementCoordRefs.addAll(coords);
  }

  void clearCoordRefs() => beamElementCoordRefs.clear();

  void reset() {
    beamSlope = 0.0;
    verticalCenter = 0;
    ledgerLinesAbove = 0;
    ledgerLinesBelow = 0;
    uniformStemLength = 0;
    weightedPlace = Beamplace.none;
    firstNoteOrChord = null;
    lastNoteOrChord = null;
    nbNotesOrChords = 0;
    stemSameasRole = StemSameasDrawingRole.none;
    stemSameasReversePartner = null;
    beamElementCoordRefs.clear();
  }

  List<BeamElementCoord> getElementCoordRefs() => beamElementCoordRefs;
  int getStartingX() => beamElementCoordRefs.isEmpty ? 0 : beamElementCoordRefs.first.x;
  int getStartingY() => beamElementCoordRefs.isEmpty ? 0 : beamElementCoordRefs.first.yBeam;

  int getAdjacentElementsDuration(int elementX) {
    if (beamElementCoordRefs.isEmpty) return MeiDuration.dur8.value;
    if (elementX < beamElementCoordRefs.first.x || elementX > beamElementCoordRefs.last.x) {
      return MeiDuration.dur8.value;
    }
    for (int i = 0; i < beamElementCoordRefs.length - 1; ++i) {
      if (beamElementCoordRefs[i].x < elementX && beamElementCoordRefs[i + 1].x > elementX) {
        final int d1 = beamElementCoordRefs[i].dur.value;
        final int d2 = beamElementCoordRefs[i + 1].dur.value;
        return d1 < d2 ? d1 : d2;
      }
    }
    return MeiDuration.dur8.value;
  }

  /// Mirrors `BeamSegment::InitSameasRoles` (beam.cpp:1492), including the
  /// `data_BEAMPLACE &initialPlace` out-parameter: the C++ takes it by
  /// reference and may overwrite it (the "second beam" branch); Dart returns
  /// the (possibly unchanged) place instead — callers must use the return
  /// value as their `initialPlace` going forward (see `view_beam.dart`).
  Beamplace initSameasRoles(Object? sameasBeam, Beamplace initialPlace) {
    if (sameasBeam == null) return initialPlace;
    if (sameasBeam is! Beam) {
      if (stemSameasRole == StemSameasDrawingRole.none) {
        stemSameasRole = StemSameasDrawingRole.unset;
      }
      return initialPlace;
    }
    final Beam beam = sameasBeam;
    // This is the first time and the first beam for which we are calling it.
    // All we need to do is keep a reference to the other beam's segment (so
    // updateSameasRoles can write its role directly, mirroring the C++
    // pointer) and mark both of them as unset.
    if (stemSameasRole == StemSameasDrawingRole.none) {
      final BeamSegment otherSeg = beam.beamSegment;
      stemSameasReversePartner = otherSeg;
      stemSameasRole = StemSameasDrawingRole.unset;
      otherSeg.stemSameasRole = StemSameasDrawingRole.unset;
      return initialPlace;
    }
    // The reverse role is not set, which means we are calling it from the
    // second beam. Use the initial place as previously computed for the
    // first one (already reflected in this beam's own role by that point).
    else if (stemSameasReversePartner == null) {
      return stemSameasIsPrimary() ? Beamplace.below : Beamplace.above;
    }
    // Otherwise, calling it (again) from the first beam, nothing to do.
    return initialPlace;
  }

  /// Mirrors `BeamSegment::UpdateSameasRoles` (beam.cpp:1515) — writes
  /// through to the partner beam's role directly (see
  /// [stemSameasReversePartner]).
  void updateSameasRoles(Beamplace place) {
    if (stemSameasReversePartner == null || !stemSameasIsUnset()) return;
    if (place == Beamplace.above) {
      stemSameasRole = StemSameasDrawingRole.primary;
      stemSameasReversePartner!.stemSameasRole = StemSameasDrawingRole.secondary;
    } else {
      stemSameasRole = StemSameasDrawingRole.secondary;
      stemSameasReversePartner!.stemSameasRole = StemSameasDrawingRole.primary;
    }
  }

  /// Mirrors `BeamSegment::CalcNoteHeadShiftForStemSameas` (beam.cpp:1531):
  /// for two beams sharing `stem.sameas` note pairs, flags whichever
  /// corresponding note needs a flipped/offset notehead so it does not
  /// collide with its partner (only runs from the second beam, once the
  /// shared role is resolved).
  void calcNoteHeadShiftForStemSameas(Object? sameasBeam, Beamplace place) {
    if (sameasBeam == null) return;
    if (stemSameasReversePartner != null || stemSameasIsUnset()) return;
    if (sameasBeam is! Beam) return;
    final List<BeamElementCoord> otherCoords = sameasBeam.beamSegment.beamElementCoordRefs;
    final Stemdirection stemDir = place == Beamplace.above ? Stemdirection.up : Stemdirection.down;
    final int size = otherCoords.length < beamElementCoordRefs.length ? otherCoords.length : beamElementCoordRefs.length;
    for (int i = 0; i < size; ++i) {
      final Object? el1 = beamElementCoordRefs[i].element;
      final Object? el2 = otherCoords[i].element;
      if (el1 == null || el2 == null) continue;
      if (el1 is Note && el2 is Note) {
        el1.calcNoteHeadShiftForSameasNote(el2, stemDir);
      }
    }
  }

  void appendSpanningCoordinates(Object? measure) {}

  // -------------------------------------------------------------------------
  // CalcStemDefiningNote / CalcBeamStemLength — real stem-length engine
  // (beam.cpp:1271 / :1200), replacing the fixed `unit*3.5` approximation.
  // -------------------------------------------------------------------------

  /// Mirrors `BeamSegment::CalcStemDefiningNote` (beam.cpp:1271).
  (int, MeiDuration, MeiDuration) calcStemDefiningNote(Staff staff, Beamplace place) {
    MeiDuration shortestDuration = MeiDuration.dur4;
    int shortestLoc = meiUnset;
    MeiDuration relevantDuration = MeiDuration.dur4;
    int relevantLoc = meiUnset;
    final Stemdirection globalStemDir =
        place == Beamplace.below ? Stemdirection.down : Stemdirection.up;

    for (final BeamElementCoord c in beamElementCoordRefs) {
      final Stemdirection stemDir = place != Beamplace.mixed
          ? globalStemDir
          : (c.beamRelativePlace == Beamplace.below ? Stemdirection.down : Stemdirection.up);
      c.setClosestNoteOrTabDurSym(stemDir, staff.isTabWithStemsOutside());
      final Object? cn = c.closestNote;
      if (cn == null || cn is! Note) continue;
      final int currentLoc = cn.drawingLoc;

      if (relevantLoc == meiUnset) {
        relevantLoc = currentLoc;
        shortestLoc = relevantLoc;
        relevantDuration = c.dur;
        shortestDuration = relevantDuration;
        continue;
      }

      if (place == Beamplace.above && currentLoc > relevantLoc) {
        relevantLoc = currentLoc;
        relevantDuration = c.dur;
      } else if (place == Beamplace.below && currentLoc < relevantLoc) {
        relevantLoc = currentLoc;
        relevantDuration = c.dur;
      }

      if (c.dur.value > shortestDuration.value) {
        shortestDuration = c.dur;
        shortestLoc = currentLoc;
      } else if (c.dur.value == shortestDuration.value) {
        if ((stemDir == Stemdirection.up && currentLoc > shortestLoc) ||
            (stemDir == Stemdirection.down && currentLoc < shortestLoc)) {
          shortestDuration = c.dur;
          shortestLoc = currentLoc;
        }
      }
    }

    MeiDuration adjustedDuration = MeiDuration.none;
    final int shortRelDiff = shortestDuration.value - relevantDuration.value;
    final int locDiff = (relevantLoc - shortestLoc).abs();
    if (shortRelDiff > locDiff + 1) {
      relevantLoc = shortestLoc;
      relevantDuration = shortestDuration;
    } else if (shortRelDiff == locDiff + 1) {
      if ((globalStemDir == Stemdirection.up && relevantLoc > 4) ||
          (globalStemDir == Stemdirection.down && relevantLoc < 4)) {
        relevantLoc = shortestLoc;
        relevantDuration = shortestDuration;
      }
    } else if (shortRelDiff == locDiff) {
      adjustedDuration =
          _durationFromValueOrNone((relevantDuration.value + shortestDuration.value) ~/ 2);
    }

    return (relevantLoc, relevantDuration, adjustedDuration);
  }

  /// Mirrors `BeamSegment::CalcBeamStemLength` (beam.cpp:1200) — sets
  /// [uniformStemLength] for real (non-mixed, non-tab path).
  void calcBeamStemLength(Staff staff, Beamplace place, bool isHorizontal) {
    final (int noteLoc, MeiDuration noteDur, MeiDuration preferredDur) =
        calcStemDefiningNote(staff, place);
    final Stemdirection globalStemDir =
        place == Beamplace.below ? Stemdirection.down : Stemdirection.up;

    for (final BeamElementCoord c in beamElementCoordRefs) {
      final Stemdirection stemDir = place != Beamplace.mixed
          ? globalStemDir
          : (c.beamRelativePlace == Beamplace.below ? Stemdirection.down : Stemdirection.up);
      final Object? cn = c.closestNote;
      if (cn == null || cn is! Note) continue;
      if (c.dur.value < noteDur.value) {
        final Object? el = c.element;
        final bool inFTrem = el != null && el.getFirstAncestor(ClassId.fTrem) != null;
        if (!inFTrem) continue;
      }
      final MeiDuration dur = preferredDur != MeiDuration.none ? preferredDur : c.dur;
      final int coordStemLength = c.calculateStemLength(staff, stemDir, isHorizontal, dur);
      if (cn.drawingLoc == noteLoc) {
        uniformStemLength = coordStemLength;
      }
    }

    for (final BeamElementCoord c in beamElementCoordRefs) {
      final Object? el = c.element;
      if (el is LayerElement && el.isGraceNote()) {
        uniformStemLength = (uniformStemLength * 0.75).toInt();
        break;
      }
    }
  }

  // -------------------------------------------------------------------------
  // CalcAdjustPosition / AdjustBeamToLedgerLines / CalcSetValues
  // (beam.cpp:1084 / :509 / :1460).
  // -------------------------------------------------------------------------

  /// Mirrors `BeamSegment::CalcSetValues` (beam.cpp:1460): propagates
  /// [beamSlope] from `firstNoteOrChord` across every coordinate.
  void calcSetValues() {
    final BeamElementCoord? first = firstNoteOrChord;
    if (first == null) return;
    final int startingX = first.x;
    final int startingY = first.yBeam;
    for (final BeamElementCoord c in beamElementCoordRefs) {
      c.yBeam = startingY + (beamSlope * (c.x - startingX)).toInt();
    }
  }

  /// Mirrors `BeamSegment::CalcAdjustPosition` (beam.cpp:1084).
  void calcAdjustPosition(Staff staff, Doc doc, BeamDrawingInterface beamInterface) {
    final int staffTop = staff.getDrawingY();
    final int staffHeight = doc.getDrawingStaffSize(staff.drawingStaffSize);
    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);

    final BeamElementCoord? first = firstNoteOrChord;
    final BeamElementCoord? last = lastNoteOrChord;
    if (first == null || last == null) return;

    double adjust = 0;
    final int start = first.yBeam;
    final int end = last.yBeam;
    final int height = (end - start).abs();
    if (start <= staffTop && start >= staffTop - staffHeight) {
      // Mirrors C++'s truncating `%` (toward zero), unlike Dart's Euclidean
      // `%` — the difference matters here because `staffTop - start` can be
      // negative.
      final int mod2Unit = unit * 2;
      final int positionWithinStaffLines =
          ((staffTop - start) - ((staffTop - start) ~/ mod2Unit) * mod2Unit).abs();
      if (beamInterface.drawingPlace == Beamplace.above) {
        if ((positionWithinStaffLines == unit && beamSlope > 0 && height != unit) ||
            (positionWithinStaffLines == unit * 0.5 && beamSlope < 0)) {
          adjust = -0.5 * unit;
        }
      } else if (beamInterface.drawingPlace == Beamplace.below) {
        if ((positionWithinStaffLines == unit && beamSlope < 0 && height != unit) ||
            (positionWithinStaffLines == unit * 1.5 && beamSlope > 0)) {
          adjust = 0.5 * unit;
        }
      }
    }

    first.yBeam += adjust.toInt();

    calcSetValues();
  }

  /// Mirrors `BeamSegment::AdjustBeamToLedgerLines` (beam.cpp:509).
  void adjustBeamToLedgerLines(
      Doc doc, Staff staff, BeamDrawingInterface beamInterface, bool isHorizontal) {
    int adjust = 0;
    final int staffTop = staff.getDrawingY();
    final int staffHeight = doc.getDrawingStaffSize(staff.drawingStaffSize);
    final int doubleUnit = doc.getDrawingDoubleUnit(staff.drawingStaffSize);
    final int staffMargin = isHorizontal ? doubleUnit ~/ 2 : 0;
    for (final BeamElementCoord c in beamElementCoordRefs) {
      if (beamInterface.drawingPlace == Beamplace.below) {
        final int topPosition = c.yBeam + beamInterface.getTotalBeamWidth();
        if (topPosition > staffTop - staffMargin) {
          adjust = ((topPosition - staffTop) ~/ doubleUnit + 1) * doubleUnit;
          break;
        }
      } else if (beamInterface.drawingPlace == Beamplace.above) {
        final int bottomPosition = c.yBeam - beamInterface.getTotalBeamWidth();
        final int bottomMargin = staffTop - staffHeight;
        if (bottomPosition < bottomMargin + staffMargin) {
          adjust = ((bottomPosition - bottomMargin) ~/ doubleUnit - 1) * doubleUnit;
          break;
        }
      }
    }
    if (adjust != 0) {
      for (final BeamElementCoord c in beamElementCoordRefs) {
        c.yBeam -= adjust;
      }
    }
  }

  // -------------------------------------------------------------------------
  // Mixed-beam reset helpers (beam.cpp:303-452). Ported for fidelity but not
  // yet wired into [calcBeam]'s retry (see the class doc comment).
  // -------------------------------------------------------------------------

  /// Mirrors `BeamSegment::GetVerticalOffset` (beam.cpp:317).
  (int, int) getVerticalOffset(BeamDrawingInterface beamInterface) {
    final (int topBeams, int bottomBeams) = beamInterface.getAdditionalBeamCount();
    final int topOffset = topBeams * beamInterface.beamWidth;
    final int bottomOffset = bottomBeams * beamInterface.beamWidth;
    return (topOffset, bottomOffset);
  }

  /// Mirrors `BeamSegment::GetMinimalStemLength` (beam.cpp:325).
  (int, int) getMinimalStemLength(BeamDrawingInterface beamInterface) {
    int minLengthAbove = meiUnset;
    int minLengthBelow = meiUnset;
    final (int topOffset, int bottomOffset) = getVerticalOffset(beamInterface);

    for (final BeamElementCoord c in beamElementCoordRefs) {
      final Object? el = c.element;
      final bool isNoteOrChord =
          el != null && (el.classId == ClassId.chord || el.classId == ClassId.note);
      if (!isNoteOrChord) continue;
      final StemmedDrawingInterface? stemIface = c.getStemHolderInterface();
      if (stemIface == null) continue;
      final Stem? s = stemIface.getDrawingStem();
      if (s == null) continue;
      final bool isStemUp = s.getDrawingStemDir() == Stemdirection.up;
      final Object? cn = c.closestNote;
      if (cn == null) continue;

      final int currentLength = isStemUp
          ? c.yBeam - bottomOffset - cn.getDrawingY()
          : cn.getDrawingY() - c.yBeam - topOffset;

      if (isStemUp) {
        minLengthBelow =
            minLengthBelow == meiUnset ? currentLength : (currentLength < minLengthBelow ? currentLength : minLengthBelow);
      } else {
        minLengthAbove =
            minLengthAbove == meiUnset ? currentLength : (currentLength < minLengthAbove ? currentLength : minLengthAbove);
      }
    }
    return (minLengthAbove, minLengthBelow);
  }

  /// Mirrors `BeamSegment::DoesBeamOverlap` (beam.cpp:303).
  bool doesBeamOverlap(
      BeamDrawingInterface beamInterface, int topBorder, int bottomBorder, int minStemLength) {
    final bool outsideBounds =
        beamElementCoordRefs.any((c) => c.yBeam > topBorder || c.yBeam < bottomBorder);
    if (outsideBounds) return true;
    final (int minLengthAbove, int minLengthBelow) = getMinimalStemLength(beamInterface);
    final int m = minLengthAbove < minLengthBelow ? minLengthAbove : minLengthBelow;
    return m < minStemLength;
  }

  /// Mirrors `BeamSegment::NeedToResetPosition` (beam.cpp:367).
  ///
  /// Deviation: `beamMixedPreserve`/`beamMixedStemMin` are not in
  /// `options_shell.dart` — this uses their C++ defaults (see the file-level
  /// `_beamMixedPreserveDefault`/`_beamMixedStemMinDefault`).
  bool needToResetPosition(Staff staff, Doc doc, BeamDrawingInterface beamInterface) {
    if (beamElementCoordRefs.isEmpty) return false;

    if (beamInterface.crossStaffContent != null) {
      final Beamplace place = beamElementCoordRefs.first.beamRelativePlace;
      final bool allSame =
          beamElementCoordRefs.every((c) => c.beamRelativePlace == place);
      if (allSame) {
        beamInterface.drawingPlace = place;
        return true;
      }
      return false;
    }

    if (_beamMixedPreserveDefault) return false;

    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    final int minStemLength = (_beamMixedStemMinDefault * unit).toInt();
    final (int topOffset, int bottomOffset) = getVerticalOffset(beamInterface);

    final int staffTop = staff.getDrawingY();
    final int staffBottom =
        staffTop - doc.getDrawingDoubleUnit(staff.drawingStaffSize) * (staff.drawingLines - 1);
    final int topBorder = staffTop + topOffset + unit;
    final int bottomBorder = staffBottom - bottomOffset - unit;

    if (!doesBeamOverlap(beamInterface, topBorder, bottomBorder, minStemLength)) return false;

    int minY = beamElementCoordRefs.first.element?.getDrawingY() ?? 0;
    int maxY = minY;
    for (final BeamElementCoord c in beamElementCoordRefs) {
      final int y = c.element?.getDrawingY() ?? 0;
      if (y > maxY) maxY = y;
      if (y < minY) minY = y;
    }
    final int midpoint = (maxY + minY) ~/ 2;
    final bool isMidpointWithinBounds = midpoint < topBorder && midpoint > bottomBorder;

    if (isMidpointWithinBounds) {
      final int midpointOffset =
          (beamElementCoordRefs.first.yBeam + beamElementCoordRefs.last.yBeam - 2 * midpoint) ~/ 2;
      for (final BeamElementCoord c in beamElementCoordRefs) {
        c.yBeam -= midpointOffset;
      }
      if (!doesBeamOverlap(beamInterface, topBorder, bottomBorder, minStemLength)) return false;
    }
    if (!isMidpointWithinBounds && midpoint > staffBottom) {
      final int offset =
          (beamElementCoordRefs.first.yBeam + beamElementCoordRefs.last.yBeam - 2 * topBorder) ~/ 2;
      for (final BeamElementCoord c in beamElementCoordRefs) {
        c.yBeam -= offset;
      }
    } else if (!isMidpointWithinBounds && midpoint < staffTop) {
      final int offset =
          (beamElementCoordRefs.first.yBeam + beamElementCoordRefs.last.yBeam - 2 * bottomBorder) ~/ 2;
      for (final BeamElementCoord c in beamElementCoordRefs) {
        c.yBeam -= offset;
      }
    }
    if (!doesBeamOverlap(beamInterface, topBorder, bottomBorder, minStemLength)) return false;

    final int stemUpCount =
        beamElementCoordRefs.where((c) => c.getStemDir() == Stemdirection.up).length;
    final int stemDownCount =
        beamElementCoordRefs.where((c) => c.getStemDir() == Stemdirection.down).length;
    final Stemdirection newDirection =
        stemUpCount >= stemDownCount ? Stemdirection.up : Stemdirection.down;
    beamInterface.drawingPlace = newDirection == Stemdirection.up ? Beamplace.above : Beamplace.below;
    if (newDirection == Stemdirection.down && uniformStemLength > 0) {
      uniformStemLength *= -1;
    }

    return true;
  }

  void adjustBeamToFrenchStyle(BeamDrawingInterface? beamInterface) {
    // Deviation: gated by the unported `beamFrenchStyle` option, default
    // `false` in the C++ — never triggers, so left unported (see class doc).
  }

  /// Mirrors `BeamSegment::AdjustBeamToTremolos` (beam.cpp:541): shifts the
  /// whole beam (and every stem's drawing length) by the largest
  /// `Stem::CalculateStemModAdjustment` needed so a tremolo-slash glyph
  /// (`@stem.mod`) on any note in the beam clears the beam.
  void adjustBeamToTremolos(Doc? doc, Staff? staff, BeamDrawingInterface? beamInterface) {
    if (doc == null || staff == null || beamInterface == null) return;

    int maxAdjustment = 0;
    for (final BeamElementCoord coord in beamElementCoordRefs) {
      final StemmedDrawingInterface? stemmedInterface = coord.getStemHolderInterface();
      if (stemmedInterface == null) continue;

      final Stem? stem = stemmedInterface.getDrawingStem();
      if (stem == null) continue;

      final int offset = (coord.dur.value - MeiDuration.dur8.value) *
              (beamInterface.beamWidth) +
          beamInterface.beamWidthBlack;
      final int currentAdjustment =
          stem.calculateStemModAdjustment(doc, staff, offset);
      if (currentAdjustment.abs() > maxAdjustment.abs()) {
        maxAdjustment = currentAdjustment;
      }
    }
    if (maxAdjustment == 0) return;

    for (final BeamElementCoord coord in beamElementCoordRefs) {
      coord.yBeam -= maxAdjustment;

      final StemmedDrawingInterface? stemmedInterface = coord.getStemHolderInterface();
      if (stemmedInterface == null) continue;

      final Stem? stem = stemmedInterface.getDrawingStem();
      if (stem == null) continue;
      stem.setDrawingStemLen(stem.getDrawingStemLen() + maxAdjustment);
    }
  }

  /// Mirrors `BeamSegment::CalcSetStemValues` (beam.cpp:149) — commits the
  /// final per-note stem length/adjust/relative-position to the [Stem]
  /// objects.
  ///
  /// Deviation: the mixed-beam `GetFloatingBeamCount` cross-staff fTrem
  /// adjustment (beam.cpp:214-220) is not ported — `beams`/`beamsFloat`
  /// are treated as `(0, 0)` (see `BeamDrawingInterface.getFloatingBeamCount`
  /// default). `AdjustBeamToFrenchStyle` (beam.cpp:249) remains a no-op stub,
  /// correctly so — it is gated by the unported `beamFrenchStyle` option,
  /// which defaults to `false` in the C++ and has no MEI-side trigger.
  void calcSetStemValues(Staff staff, Doc doc, BeamDrawingInterface beamInterface) {
    final int stemWidth = doc.getDrawingStemWidth(staff.drawingStaffSize);
    for (final BeamElementCoord c in beamElementCoordRefs) {
      final Object? el = c.element;
      if (el == null) continue;
      final bool isChordOrNote = el.classId == ClassId.chord || el.classId == ClassId.note;
      if (!isChordOrNote) continue;

      final StemmedDrawingInterface? stemmedInterface = c.getStemHolderInterface();
      if (stemmedInterface == null) continue;

      final Object? cnObj = c.closestNote;
      if (cnObj == null || cnObj is! Note) continue;
      final Note closestNote = cnObj;

      int y1 = c.yBeam;
      int y2 = closestNote.getDrawingY();
      bool isStemSameas = false;

      if (stemSameasIsSecondary() && el is Note) {
        if (el.hasStemSameasNote()) {
          final Object? sameas = el.stemSameasNote;
          if (sameas is Note) {
            y1 = sameas.getDrawingY();
            isStemSameas = true;
          }
        }
      }

      final int staffSize = staff.drawingStaffSize;
      final bool cueSize = beamInterface.cueSize;

      int stemAdjust = 0;
      if (beamInterface.drawingPlace == Beamplace.above) {
        if (isStemSameas) {
          y1 += _stemAnchorFor(el, up: true, doc: doc, staffSize: staffSize, cueSize: cueSize).y;
        } else {
          stemAdjust = -stemWidth;
        }
        y2 += _stemAnchorFor(el, up: true, doc: doc, staffSize: staffSize, cueSize: cueSize).y;
      } else if (beamInterface.drawingPlace == Beamplace.below) {
        if (isStemSameas) {
          y1 += _stemAnchorFor(el, up: false, doc: doc, staffSize: staffSize, cueSize: cueSize).y;
        } else {
          stemAdjust = stemWidth;
        }
        y2 += _stemAnchorFor(el, up: false, doc: doc, staffSize: staffSize, cueSize: cueSize).y;
      } else if (beamInterface.drawingPlace == Beamplace.mixed) {
        int stemOffset = 0;
        final int unit = doc.getDrawingUnit(staffSize);
        if (c.partialFlagPlace == c.beamRelativePlace) {
          stemOffset = (c.dur.value - MeiDuration.dur8.value) * (beamInterface.beamWidth as int);
        } else if (el is LayerElement &&
            el.isInBeamSpan &&
            c.partialFlagPlace != Beamplace.above &&
            c.stem is Stem &&
            (c.stem as Stem).getDrawingStemDir() == Stemdirection.up) {
          stemOffset = -unit ~/ 2;
        }
        // Deviation: GetFloatingBeamCount not ported — treated as (0, 0).
        if (c.beamRelativePlace == Beamplace.below) {
          y2 += _stemAnchorFor(el, up: false, doc: doc, staffSize: staffSize, cueSize: cueSize).y;
          stemAdjust = -((beamInterface.beamWidthBlack as int) + stemOffset);
        } else {
          y2 += _stemAnchorFor(el, up: true, doc: doc, staffSize: staffSize, cueSize: cueSize).y;
          stemAdjust = stemOffset;
        }
      }

      if (el.classId == ClassId.chord && el is Chord) {
        final (int yMax, int yMin) = el.getYExtremes();
        if (beamInterface.drawingPlace == Beamplace.mixed) {
          y2 += (c.beamRelativePlace == Beamplace.above) ? (yMin - yMax) : (yMax - yMin);
        } else {
          y2 += (beamInterface.drawingPlace == Beamplace.above) ? (yMin - yMax) : (yMax - yMin);
        }
      }

      c.updateStemLength(
          stemmedInterface, y1, y2, stemAdjust, beamInterface.drawingPlace == Beamplace.mixed);
    }

    adjustBeamToFrenchStyle(beamInterface);
    adjustBeamToTremolos(doc, staff, beamInterface);
  }

  // -------------------------------------------------------------------------
  // CalcBeam — moved from view_beam.dart (beam.cpp:89)
  // -------------------------------------------------------------------------

  /// Mirrors `BeamSegment::CalcBeam` (beam.cpp:89).
  ///
  /// The slope engine (`CalcBeamSlope`/`CalcAdjustSlope`/`CalcHorizontalBeam`)
  /// keeps the pre-existing reduced linear-interpolation heuristic (see the
  /// class doc comment "Deviations from the C++"); everything else in the
  /// non-mixed path — stem length, per-note anchor, vertical-center snap,
  /// ledger-line clearance, final stem commit — is now the real engine.
  void calcBeam(Layer? layer, Staff? staff, Doc? doc, BeamDrawingInterface? beamInterface,
      Beamplace place,
      {bool init = true}) {
    // C++ guards: assert(layer); assert(staff); assert(doc);
    //             assert(m_beamElementCoordRefs.size() > 0);
    if (layer == null || staff == null || doc == null || beamInterface == null) return;
    if (beamElementCoordRefs.isEmpty) return;
    final List<BeamElementCoord> coords = beamElementCoordRefs;

    // Tablature early exit — mirrors beam.cpp:104
    final bool isTab = staff.isTablature() || staff.isTabStaffLike();
    if (isTab) {
      final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
      int black = unit ~/ 2;
      int white = unit ~/ 4;
      black = beamInterface.beamWidthBlack;
      final int staffY = staff.getDrawingY();
      for (final c in coords) {
        final Object? el = c.element;
        if (el != null) {
          c.x = el.getDrawingX();
        }
        c.yBeam = staffY + unit;
      }
      beamSlope = 0.0;
      firstNoteOrChord = coords.first;
      lastNoteOrChord = coords.last;
      beamInterface.beamWidthBlack = black;
      beamInterface.beamWidthWhite = white;
      beamInterface.beamWidth = black + white;
      return;
    }

    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    final bool cue = beamInterface.cueSize;
    int black = unit;
    if (cue) black = (black * doc.getCueScaling()).toInt();
    int white = unit ~/ 2;
    if (cue) white = (white * doc.getCueScaling()).toInt();
    if (beamInterface.shortestDur == MeiDuration.dur64) {
      white = white * 4 ~/ 3;
    }
    beamInterface.beamWidthBlack = black;
    beamInterface.beamWidthWhite = white;
    beamInterface.beamWidth = black + white;
    beamInterface.fractionSize = staff.drawingStaffSize;

    // Point of center of the staff (mirrors beam.cpp:589-590).
    final int staffY = staff.getDrawingY();
    final int dbl = doc.getDrawingDoubleUnit(staff.drawingStaffSize);
    verticalCenter = staffY - dbl * 2;

    // Initialize coord.x from the element's own drawing X (mirrors
    // `CalcBeamInit`, beam.cpp:584-587 — done *before* the extrema loop and
    // *before* `SetDrawingStemDir` below, which only *adds* the stem cut-out
    // offset on top; there is no later reset).
    for (final c in coords) {
      final Object? el = c.element;
      if (el != null) c.x = el.getDrawingX();
    }

    /******************************************************************/
    // Calculate the extreme values (mirrors `BeamSegment::CalcBeamInit`,
    // beam.cpp:620-677 — extrema start at the vertical center; ledger lines
    // are accumulated for the CalcBeamPlace tie-breaker).
    int yMax = verticalCenter;
    int yMin = verticalCenter;
    void setExtrema(int currentY) {
      if (currentY > yMax) yMax = currentY;
      if (currentY < yMin) yMin = currentY;
    }

    ledgerLinesAbove = 0;
    ledgerLinesBelow = 0;
    for (final c in coords) {
      final Object? el = c.element;
      if (el is Chord) {
        final Note? bottomNote = el.getBottomNote();
        final Note? topNote = el.getTopNote();
        if (bottomNote != null && topNote != null) {
          // Mirrors CalcBeamInitForNotePair (beam.cpp:681-694): the "max" is
          // seeded with the bottom note Y and the "min" with the top note Y;
          // both are folded through SetExtrema, so the net effect is the
          // extrema over both notes.
          final int chordYMax = bottomNote.getDrawingY();
          final int chordYMin = topNote.getDrawingY();
          setExtrema(chordYMax);
          setExtrema(chordYMin);
        }
      } else if (el is Note) {
        // In a stem.sameas context, use both notes to determine the beam
        // place (as with a chord) — mirrors beam.cpp:662-668. `stemSameasNote`
        // is set bidirectionally by `PrepareLinkingFunctor.resolveStemSameas`
        // on *both* notes of the pair (the target too, not just the one
        // carrying @stem.sameas), so this branch also fires for the "primary"
        // beam's own notes.
        if (el.hasStemSameasNote()) {
          final Note partner = el.stemSameasNote as Note;
          final Note bottomNote =
              el.getDrawingY() > partner.getDrawingY() ? partner : el;
          final Note topNote =
              el.getDrawingY() > partner.getDrawingY() ? el : partner;
          setExtrema(bottomNote.getDrawingY());
          setExtrema(topNote.getDrawingY());
          final (bool bottomHas, _, int bottomLinesBelow) =
              bottomNote.hasLedgerLines(staff);
          if (bottomHas) ledgerLinesBelow += bottomLinesBelow;
          final (bool topHas, int topLinesAbove, _) =
              topNote.hasLedgerLines(staff);
          if (topHas) ledgerLinesAbove += topLinesAbove;
        } else {
          setExtrema(el.getDrawingY());
          final (bool has, int linesAbove, int linesBelow) =
              el.hasLedgerLines(staff);
          if (has) {
            ledgerLinesBelow += linesBelow;
            ledgerLinesAbove += linesAbove;
          }
        }
      }
    }
    weightedPlace = ((verticalCenter - yMin) > (yMax - verticalCenter))
        ? Beamplace.above
        : Beamplace.below;

    /******************************************************************/
    // Resolve the drawing place (mirrors `BeamSegment::CalcBeamPlace`,
    // beam.cpp:1114-1156).
    Beamplace drawPlace = place;
    if (drawPlace == Beamplace.none) {
      // Default with cross-staff
      if (beamInterface.hasMultipleStemDir == true) {
        drawPlace = Beamplace.mixed;
      }
      // Now look at the stem direction of the notes within the beam
      else if (beamInterface.notesStemDir == Stemdirection.up) {
        drawPlace = Beamplace.above;
      } else if (beamInterface.notesStemDir == Stemdirection.down) {
        drawPlace = Beamplace.below;
      } else if (beamInterface.crossStaffContent != null) {
        drawPlace = Beamplace.mixed;
      }
      // Look at the layer direction or, finally, at the note position
      else {
        Stemdirection layerStemDir = Stemdirection.none;
        // Do not look at the layer context when notes from different layers
        // are stemmed together (mirrors `BeamSegment::StemSameas`, beam.h:83).
        if (stemSameasRole == StemSameasDrawingRole.none) {
          layerStemDir = layer.getDrawingStemDirForBeamCoords(coords);
        }
        // Layer direction?
        if (layerStemDir == Stemdirection.none) {
          if (ledgerLinesBelow != ledgerLinesAbove) {
            drawPlace = (ledgerLinesBelow > ledgerLinesAbove)
                ? Beamplace.above
                : Beamplace.below;
          } else {
            drawPlace = weightedPlace;
          }
        }
        // Look at the note position
        else {
          drawPlace = (layerStemDir == Stemdirection.up)
              ? Beamplace.above
              : Beamplace.below;
        }
      }
    }
    // Refresh `closestNote` on the *owned* coords (shared objects with
    // [beamElementCoordRefs]) and `drawingPlace` using this pass's
    // just-resolved [drawPlace] *before* reading `IsHorizontal` — a
    // deliberate deviation from the C++ order (`IsHorizontal()` runs before
    // `CalcBeamPlace` there, so it reads whatever `drawingPlace`/
    // `closestNote`/Y state survived from the *previous* CalcBeam call). In
    // the C++, that previous-pass state is safe to read because `CalcBeam`
    // only runs once note Y positions are already final (View::DrawBeam,
    // post vertical-layout). This port's pipeline calls [calcBeam] at
    // additional, earlier stages (see class doc) where a beam's notes can
    // still be mid-resolution; reading genuinely stale `drawingPlace`/
    // `closestNote`/Y data there was observed to make `IsHorizontal` flap
    // between passes for the same physical beam (structural + large
    // numeric regression on `barline-007`, non-mixed place only handled
    // here — mixed keeps whatever `beamRelativePlace` it currently has).
    beamInterface.drawingPlace = drawPlace;
    if (drawPlace != Beamplace.mixed) {
      final Stemdirection globalStemDir =
          drawPlace == Beamplace.below ? Stemdirection.down : Stemdirection.up;
      for (final c in coords) {
        c.setClosestNoteOrTabDurSym(globalStemDir, staff.isTabWithStemsOutside());
      }
    }
    final bool isHorizontal = beamInterface.isHorizontal();

    // If we have a stem.sameas context and it is unset, update the roles.
    // This updates the roles for both beams (mirrors beam.cpp:1162-1164).
    // Missing this call was the root cause of a structural divergence: with
    // both linked beams stuck at role `unset`, `stemSameasIsSecondary()` was
    // false for both, so both drew their own beam polygon instead of exactly
    // one of them (see `prompts/loop-diario.md`, trilha ESTRUTURAL,
    // `stem-014`/`stem-016`).
    if (stemSameasIsUnset()) {
      updateSameasRoles(drawPlace);
    }

    // Real stem-length engine (mirrors `CalcBeamStemLength`, beam.cpp:1200)
    // for non-mixed beams; mixed beams keep the previous fixed-formula
    // approximation untouched (out of scope this session — see class doc).
    if (drawPlace == Beamplace.mixed) {
      int uniformStemLengthLocal = (unit * 7) ~/ 2;
      if (cue) uniformStemLengthLocal = (uniformStemLengthLocal * doc.getCueScaling()).toInt();
      uniformStemLength = uniformStemLengthLocal;
    } else {
      calcBeamStemLength(staff, drawPlace, isHorizontal);
    }

    // Set drawing stem positions (mirrors `BeamSegment::CalcBeamPosition`,
    // beam.cpp:912-936 — now backed by the real per-coordinate geometry in
    // `BeamElementCoord.setDrawingStemDir`).
    for (final c in coords) {
      if (drawPlace == Beamplace.above) {
        c.setDrawingStemDir(
            Stemdirection.up, staff, doc, this, beamInterface);
      } else if (drawPlace == Beamplace.below) {
        c.setDrawingStemDir(
            Stemdirection.down, staff, doc, this, beamInterface);
      }
      // cross-staff or beam@place=mixed
      else {
        // The Dart holds the cross staff (Object) where the C++ has a bool.
        if (beamInterface.crossStaffContent != null) {
          final Stemdirection dir = (c.beamRelativePlace == Beamplace.above)
              ? Stemdirection.up
              : Stemdirection.down;
          c.setDrawingStemDir(dir, staff, doc, this, beamInterface);
        } else {
          final Stemdirection stemDir = c.getStemDir();
          c.setDrawingStemDir(stemDir, staff, doc, this, beamInterface);
        }
      }
    }

    firstNoteOrChord = null;
    lastNoteOrChord = null;
    nbNotesOrChords = 0;
    for (final c in coords) {
      final Object? el = c.element;
      bool isChordOrNote = false;
      if (el != null) {
        final ClassId cid = el.classId;
        isChordOrNote = cid == ClassId.chord || cid == ClassId.note;
      }
      if (isChordOrNote) {
        firstNoteOrChord ??= c;
        lastNoteOrChord = c;
        nbNotesOrChords++;
        if (c.element != null) {
          final Object? elem = c.element;
          if (elem != null && elem.classId == ClassId.chord) {
            if (elem is Chord) {
              final Chord ch = elem;
              if (drawPlace == Beamplace.below) {
                c.closestNote = ch.getBottomNote();
              } else if (drawPlace == Beamplace.above) {
                c.closestNote = ch.getTopNote();
              } else {
                c.closestNote = ch.getBottomNote();
              }
            }
          }
        }
      }
    }
    if (firstNoteOrChord == null) {
      firstNoteOrChord = coords.first;
      lastNoteOrChord = coords.last;
    }

    if (drawPlace == Beamplace.mixed) {
      for (final c in coords) {
        if (c.closestNote == null) {
          final Object? el = c.element;
          if (el != null) {
            c.yBeam = el.getDrawingY();
          }
          c.beamRelativePlace = Beamplace.above;
          c.partialFlagPlace = Beamplace.above;
          continue;
        }
        Stemdirection dir = Stemdirection.none;
        final Object? el = c.element;
        if (el is LayerElement) {
          // LayerElement has no direct getDrawingStemDir; use StemmedDrawingInterface or AttStems
          if (el is Stem) {
            dir = el.getDrawingStemDir();
          } else if (el is Note) {
            dir = el.getDrawingStemDir();
          } else if (el is Chord) {
            dir = el.getDrawingStemDir();
          }
        }
        if (dir == Stemdirection.none) {
          final Object? s = c.stem;
          if (s is Stem) {
            dir = s.getDrawingStemDir();
          }
        }
        c.beamRelativePlace = dir == Stemdirection.down ? Beamplace.below : Beamplace.above;
        c.partialFlagPlace = c.beamRelativePlace;
        int noteY = 0;
        final Object? cn = c.closestNote;
        if (cn != null) {
          noteY = cn.getDrawingY();
        }
        c.yBeam = noteY + (c.beamRelativePlace == Beamplace.below ? -uniformStemLength : uniformStemLength);
      }
      beamSlope = 0.0;
    } else {
      // Real slope engine (mirrors the non-mixed branch of
      // `BeamSegment::CalcBeamPosition`, beam.cpp:940-955): `first`/`last`
      // already carry the per-note anchor `setDrawingStemDir` committed
      // above, so — unlike the previous reduced pass — nothing here
      // recomputes their Y from scratch.
      beamSlope = 0.0;
      if (!isHorizontal) {
        final List<int> step = <int>[0];
        if (calcBeamSlope(staff, doc, beamInterface, step)) {
          calcAdjustSlope(staff, doc, beamInterface, step);
        } else {
          calcAdjustPosition(staff, doc, beamInterface);
        }
      } else {
        calcHorizontalBeam(doc, staff, beamInterface);
      }
      if (beamInterface.crossStaffContent == null) {
        adjustBeamToLedgerLines(doc, staff, beamInterface, isHorizontal);
      }
    }

    if (drawPlace == Beamplace.mixed) {
      // Simplified CalcPartialFlagPlace
      int idx = coords.indexWhere((c) => c.dur.value >= MeiDuration.dur16.value);
      if (idx != -1) {
        int start = idx;
        while (start < coords.length) {
          int end = start;
          Beamplace placeLocal = coords[start].beamRelativePlace;
          while (end < coords.length) {
            final BeamElementCoord c = coords[end];
            final Object? el = c.element;
            bool isRest = false;
            if (el != null) {
              isRest = el.classId == ClassId.rest;
            }
            if (isRest) break;
            if (c.beamRelativePlace != placeLocal) break;
            if (c.dur.value <= MeiDuration.dur8.value) break;
            if (c.breaksec != 0) {
              end++;
              break;
            }
            end++;
          }
          for (int i = start; i < end && i < coords.length; ++i) {
            coords[i].partialFlagPlace = placeLocal == Beamplace.above ? Beamplace.above : Beamplace.below;
          }
          if (end >= coords.length) break;
          start = end + 1;
        }
      }
    }

    // Commit final per-note stem length/adjust to the Stem objects (mirrors
    // the tail of `CalcBeam`, beam.cpp:144-146, non-tab path).
    calcSetStemValues(staff, doc, beamInterface);
  }

  // -------------------------------------------------------------------------
  // Slope engine (beam.cpp:700-1082, non-mixed path) — was stubbed with a
  // reduced linear-interpolation heuristic; now a real, literal port. The
  // mixed-beam branches (`CalcMixedBeamPosition`/`CalcMixedBeamCenterY`,
  // beam.cpp:1088-1234) remain stubs: they are not reachable from [calcBeam]
  // outside the mixed path, which this session does not target (see class
  // doc "Deviations" — the mixed-beam reset retry is a separate gap).
  // -------------------------------------------------------------------------

  /// Mirrors `BeamSegment::CalcBeamSlope` (beam.cpp:700). [step] is a
  /// single-element out-parameter (Dart has no reference `int&`).
  bool calcBeamSlope(
      Staff staff, Doc doc, BeamDrawingInterface beamInterface, List<int> step) {
    beamSlope = 0.0;

    if (nbNotesOrChords < 2) return false;
    final BeamElementCoord first = firstNoteOrChord!;
    final BeamElementCoord last = lastNoteOrChord!;

    beamSlope =
        BoundingBox.calcSlope(Point(first.x, first.yBeam), Point(last.x, last.yBeam));

    int noteStep = 0;
    double noteSlope = 0.0;
    final Object? firstClosest = first.closestNote;
    final Object? lastClosest = last.closestNote;
    if (firstClosest != null && lastClosest != null) {
      noteSlope = BoundingBox.calcSlope(Point(first.x, firstClosest.getDrawingY()),
          Point(last.x, lastClosest.getDrawingY()));
      noteStep = (firstClosest.getDrawingY() - lastClosest.getDrawingY()).abs();
    }

    // This can happen with two notes with 32nd or 64th notes and a diatonic
    // step. Force the noteSlope to be considered instead.
    if (beamSlope == 0.0) beamSlope = noteSlope;
    if (beamSlope == 0.0) return false;

    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    final List<bool> shortStep = <bool>[false];
    step[0] = calcBeamSlopeStep(doc, staff, beamInterface, noteStep, shortStep);

    final Beamplace place = beamInterface.drawingPlace;
    // The current step according to stems - this can be flat because of the
    // stem extended.
    final int curStep = (first.yBeam - last.yBeam).abs();
    // We can keep the current slope but only if curStep is not 0 and smaller
    // than the step.
    if (curStep != 0 && curStep < step[0] && place != Beamplace.mixed) {
      return false;
    }
    // This occurs when the current stem would yield a horizontal beam. We
    // need to extend one side first in order to make sure it will be
    // oblique.
    else if (curStep == 0) {
      if (place == Beamplace.above) {
        if (beamSlope > 0.0) {
          last.yBeam += step[0];
        } else {
          first.yBeam += step[0];
        }
      } else if (place == Beamplace.below) {
        if (beamSlope < 0.0) {
          last.yBeam -= step[0];
        } else {
          first.yBeam -= step[0];
        }
      }
    }

    // Now adjust the stem - for short steps, we need to adjust both sides
    // when the shorter one is not centered.
    if (place == Beamplace.above) {
      if (beamSlope > 0.0) {
        first.centered = last.centered;
        if (shortStep[0] && !last.centered) {
          last.yBeam = last.yBeam + step[0];
          last.centered = true;
        }
        first.yBeam = last.yBeam - step[0];
      } else {
        last.centered = first.centered;
        if (shortStep[0] && !first.centered) {
          first.yBeam = first.yBeam + step[0];
          first.centered = true;
        }
        last.yBeam = first.yBeam - step[0];
      }
    } else if (place == Beamplace.below) {
      if (beamSlope < 0.0) {
        first.centered = last.centered;
        if (shortStep[0] && !last.centered) {
          last.yBeam = last.yBeam - step[0];
          last.centered = true;
        }
        first.yBeam = last.yBeam + step[0];
      } else {
        last.centered = first.centered;
        if (shortStep[0] && !first.centered) {
          first.yBeam = first.yBeam - step[0];
          first.centered = true;
        }
        last.yBeam = first.yBeam + step[0];
      }
    } else if (place == Beamplace.mixed) {
      int mixedStep = step[0];
      if (mixedStep <= unit || mixedStep > unit * 2) {
        mixedStep = unit * 2;
      }
      calcMixedBeamPosition(beamInterface, mixedStep, unit);
      step[0] = mixedStep;
    }

    beamSlope =
        BoundingBox.calcSlope(Point(first.x, first.yBeam), Point(last.x, last.yBeam));

    // With two notes we never have to adjust the slope.
    if (nbNotesOrChords == 2) return false;

    return true;
  }

  /// Mirrors `BeamSegment::CalcBeamSlopeStep` (beam.cpp:867).
  int calcBeamSlopeStep(Doc doc, Staff staff, BeamDrawingInterface beamInterface,
      int noteStep, List<bool> shortStep) {
    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    // Default (maximum) step is two stave-spaces (4 units).
    int step = 4 * unit;
    final int dist = lastNoteOrChord!.x - firstNoteOrChord!.x;

    if (nbNotesOrChords == 2) {
      step = unit * 2;
      if (dist <= unit * 6) {
        step = unit ~/ 2;
        shortStep[0] = true;
      }
    } else if (nbNotesOrChords == 3) {
      if (dist <= unit * 12) {
        step = unit * 2;
      } else if (noteStep <= unit * 4) {
        step = unit * 2;
      }
    } else {
      if (noteStep < unit * 3) {
        step = unit ~/ 2;
        shortStep[0] = true;
      } else if (noteStep <= unit * 4) {
        step = unit * 2;
      } else if (nbNotesOrChords == 4) {
        if (beamElementCoordRefs[1].yBeam == beamElementCoordRefs[2].yBeam &&
            (firstNoteOrChord!.yBeam == beamElementCoordRefs[1].yBeam ||
                lastNoteOrChord!.yBeam == beamElementCoordRefs[2].yBeam)) {
          step = unit * 2;
        }
      }
    }

    // Prevent short step with values not shorter than a 16th.
    if (shortStep[0] && beamInterface.shortestDur.value >= MeiDuration.dur32.value) {
      step = unit * 2;
      shortStep[0] = false;
    }

    return step;
  }

  /// Mirrors `BeamSegment::CalcAdjustSlope` (beam.cpp:964). [step] is a
  /// single-element in/out-parameter (Dart has no reference `int&`).
  void calcAdjustSlope(
      Staff staff, Doc doc, BeamDrawingInterface beamInterface, List<int> step) {
    calcAdjustPosition(staff, doc, beamInterface);

    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    final BeamElementCoord first = firstNoteOrChord!;
    final BeamElementCoord last = lastNoteOrChord!;

    int refLen = 0;
    if (beamInterface.drawingPlace == Beamplace.above) {
      if (beamSlope > 0.0) {
        refLen = last.yBeam - last.closestNote!.getDrawingY();
      } else {
        refLen = first.yBeam - first.closestNote!.getDrawingY();
      }
    } else if (beamInterface.drawingPlace == Beamplace.below) {
      if (beamSlope < 0.0) {
        refLen = last.closestNote!.getDrawingY() - last.yBeam;
      } else {
        refLen = first.closestNote!.getDrawingY() - first.yBeam;
      }
    }
    // We can actually tolerate a stem slightly shorter within the beam.
    refLen -= unit;

    bool lengthen = false;
    for (final BeamElementCoord coord in beamElementCoordRefs) {
      if (coord.stem != null && coord.closestNote != null) {
        final int len = (coord.yBeam - coord.closestNote!.getDrawingY()).abs();
        if (len < refLen) {
          lengthen = true;
          break;
        }
        // Here we should look at duration too because longer values in the
        // middle could actually be OK as they are.
        else if ((!identical(coord, last) || !identical(coord, first)) &&
            coord.dur.value > MeiDuration.dur8.value) {
          final int durLen = (len - 0.9 * unit).toInt();
          if (durLen < refLen) {
            lengthen = true;
            break;
          }
        }
      }
    }
    // We need to lengthen the stems.
    if (lengthen) {
      // First if the slope step is 4 units (or more?) reduce it to 2 units
      // and try again (recursive call).
      if (step[0] >= 4 * unit) {
        step[0] = 2 * unit;
        if (beamInterface.drawingPlace == Beamplace.above) {
          if (beamSlope > 0.0) {
            first.yBeam += 2 * unit;
          } else {
            last.yBeam += 2 * unit;
          }
        } else if (beamInterface.drawingPlace == Beamplace.below) {
          if (beamSlope < 0.0) {
            first.yBeam -= 2 * unit;
          } else {
            last.yBeam -= 2 * unit;
          }
        }

        // Reset the slope and the value.
        beamSlope = BoundingBox.calcSlope(
            Point(first.x, first.yBeam), Point(last.x, last.yBeam));

        calcAdjustPosition(staff, doc, beamInterface);
        // Try again - shortening will obviously be false at this stage.
        return calcAdjustSlope(staff, doc, beamInterface, step);
      }
      // Other handling possibility by simply making the beam horizontal -
      // not sure which one is best.
      else {
        if (beamInterface.drawingPlace == Beamplace.above) {
          if (beamSlope > 0.0) {
            first.yBeam = last.yBeam;
          } else {
            last.yBeam = first.yBeam;
          }
        } else if (beamInterface.drawingPlace == Beamplace.below) {
          if (beamSlope < 0.0) {
            first.yBeam = last.yBeam;
          } else {
            last.yBeam = first.yBeam;
          }
        }

        // Reset the slope and the value.
        beamSlope = BoundingBox.calcSlope(
            Point(first.x, first.yBeam), Point(last.x, last.yBeam));

        calcAdjustPosition(staff, doc, beamInterface);
        // Simply ignore shortening.
        return;
      }
    }
  }

  /// Mirrors `BeamSegment::CalcHorizontalBeam` (beam.cpp:1339). The mixed
  /// branch delegates to the (stubbed) [calcMixedBeamPosition] — see the
  /// section doc comment.
  void calcHorizontalBeam(Doc doc, Staff staff, BeamDrawingInterface beamInterface) {
    if (beamInterface.drawingPlace == Beamplace.mixed) {
      final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
      calcMixedBeamPosition(beamInterface, 0, unit);
    } else {
      int maxLength =
          beamInterface.drawingPlace == Beamplace.above ? meiUnset : -meiUnset;

      // Find the longest stem length.
      for (final BeamElementCoord coord in beamElementCoordRefs) {
        if (coord.stem == null) continue;
        if (beamInterface.drawingPlace == Beamplace.above) {
          if (maxLength < coord.yBeam) maxLength = coord.yBeam;
        } else if (beamInterface.drawingPlace == Beamplace.below) {
          if (maxLength > coord.yBeam) maxLength = coord.yBeam;
        }
      }

      if (maxLength.abs() != -meiUnset) {
        beamElementCoordRefs.first.yBeam = maxLength;
      }
    }

    calcAdjustPosition(staff, doc, beamInterface);
  }

  // Stubs for remaining helpers not reached by [calcBeam] this pass (full
  // integration in a future iteration — see class doc "Deviations").
  void calcBeamInit(Object? staff, Object? doc, Object? beamInterface, Beamplace place) {}
  void calcBeamInitForNotePair(Object? n1, Object? n2, Object? staff, int yMax, int yMin) {}
  void calcMixedBeamPosition(BeamDrawingInterface? beamInterface, int step, int unit) {}
  void calcBeamPosition(Object? doc, Object? staff, Object? beamInterface, bool isHorizontal) {}
  void calcBeamPlace(Object? layer, Object? beamInterface, Beamplace place) {}
  void calcBeamPlaceTab(Object? layer, Object? staff, Object? doc, Object? beamInterface, Beamplace place) {}
  void calcSetStemValuesTab(Object? staff, Object? doc, Object? beamInterface) {}
  int calcMixedBeamCenterY(int step, int unit) => 0;
  void calcMixedBeamPlace(Object? staff) {}
  void calcPartialFlagPlace() {}
}

class BeamSpanSegment extends BeamSegment {
  Object? measure;
  Object? staff;
  Object? layer;
  BeamElementCoord? beginCoord;
  BeamElementCoord? endCoord;
  int spanningType = spanningStartEnd;
  void setSpanningType(int systemIndex, int systemCount) {
    if (systemIndex == 0) {
      spanningType = spanningStart;
    } else if (systemIndex == systemCount - 1) {
      spanningType = spanningEnd;
    } else {
      spanningType = spanningMiddle;
    }
  }

  @override
  void appendSpanningCoordinates(Object? measure) {
    if (spanningType == spanningStartEnd) return;
    if (beamElementCoordRefs.isEmpty) return;
    if (measure is! Measure) return;
    final Measure m = measure;
    final Object bar = m.getRightBarLine();
    // Measure.getRightBarLine() returns BarLine which has getDrawingX via LayerElement.
    final int rightSide = bar.getDrawingX();
    final BeamElementCoord front = beamElementCoordRefs.first;
    final BeamElementCoord back = beamElementCoordRefs.last;
    double slope = 0.0;
    if (beamElementCoordRefs.length > 1) {
      final int dx = back.x - front.x;
      if (dx != 0) slope = (back.yBeam - front.yBeam) / dx;
    }
    if (spanningType == spanningStart || spanningType == spanningMiddle) {
      final BeamElementCoord right = BeamElementCoord()
        ..x = rightSide
        ..yBeam = back.yBeam + ((rightSide - back.x) * slope).toInt()
        ..dur = back.dur
        ..element = back.element
        ..closestNote = back.closestNote
        ..stem = back.stem;
      beamElementCoordRefs.add(right);
    }
    if (spanningType == spanningEnd || spanningType == spanningMiddle) {
      final BeamElementCoord left = BeamElementCoord()
        ..x = front.x
        ..yBeam = front.yBeam
        ..dur = front.dur
        ..element = front.element
        ..closestNote = front.closestNote
        ..stem = front.stem;
      int offset = 0;
      if (beamElementCoordRefs.length > 1) {
        final int divideBy = 2 * (beamElementCoordRefs.length - 1);
        offset = (back.x - front.x) ~/ divideBy;
      } else {
        offset = 270;
      }
      left.x -= offset;
      left.yBeam -= (offset * slope).toInt();
      beamElementCoordRefs.insert(0, left);
    }
  }
}
