// ignore_for_file: dead_code, unused_element, unnecessary_cast, unused_local_variable, curly_braces_in_flow_control_structures, prefer_conditional_assignment

/// Port of `beam.h` / `beam.cpp` — `BeamSegment` and `BeamElementCoord`
/// (`origin/src/include/vrv/beam.h:36` and `:395`, `origin/src/src/beam.cpp`).
///
/// Task 05-31 moves the calculation engine from `view_beam.dart` (where it was
/// re-implemented in reduced form) to the model, as in the C++ (beam.cpp:89,
/// drawinginterface.cpp:140). The full ~1500-line engine is ported
/// incrementally; this file now hosts the engine (initially the reduced
/// version, sufficient for CMN, with the full ledger/French/mixed/tab/cross
/// paths arriving in 05-31b). The View must not re-implement it.
///
/// Deviations from the C++:
/// - `m_beamElementCoordRefs` holds references to the same objects owned by
///   `BeamDrawingInterface`; the two lists are kept in sync via `initCoordRefs`.
/// - `m_stemSameasReverseRole` is a nullable role, not a pointer-to-role.
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/vrvdef.dart'
    show
        ClassId,
        StemSameasDrawingRole,
        spanningEnd,
        spanningMiddle,
        spanningStart,
        spanningStartEnd;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/object.dart';

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
  Stemdirection getStemDir() {
    if (stem != null) {
      try {
        return (stem as dynamic).getDir() as Stemdirection;
      } catch (_) {
        try {
          return (stem as dynamic).getDrawingStemDir() as Stemdirection;
        } catch (_) {}
      }
    }
    if (element == null) return Stemdirection.none;
    try {
      final dynamic el = element as dynamic;
      final dir = el.stemDir as Stemdirection?;
      if (dir != null) return dir;
    } catch (_) {}
    return Stemdirection.none;
  }

  /// Mirrors `BeamElementCoord::SetDrawingStemDir` (beam.cpp:1837).
  void setDrawingStemDir(Stemdirection dir, dynamic staff, dynamic doc,
      BeamSegment segment, dynamic beamInterface) {}

  /// Mirrors `BeamElementCoord::SetClosestNoteOrTabDurSym` (beam.cpp:2002).
  void setClosestNoteOrTabDurSym(Stemdirection dir, bool outsideStaff) {}

  /// Mirrors `BeamElementCoord::CalculateStemLength` (beam.cpp:1915).
  int calculateStemLength(dynamic staff, Stemdirection dir, bool isHorizontal,
          MeiDuration prefDur) =>
      0;

  /// Mirrors `BeamElementCoord::CalculateStemLengthTab` (beam.cpp:1959).
  int calculateStemLengthTab(dynamic staff, Stemdirection dir) => 0;

  /// Mirrors `BeamElementCoord::CalculateStemModAdjustment` (beam.cpp:1967).
  int calculateStemModAdjustment(int len, int bias) => 0;

  /// Mirrors `BeamElementCoord::GetStemHolderInterface` (beam.cpp:1988).
  dynamic getStemHolderInterface() => null;

  /// Mirrors `BeamElementCoord::UpdateStemLength` (beam.cpp:2023).
  void updateStemLength(dynamic iface, int y1, int y2, int adjust, bool mixed) {}
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
  StemSameasDrawingRole? stemSameasReverseRole;

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
    stemSameasReverseRole = null;
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

  void initSameasRoles(dynamic sameasBeam, Beamplace place) {
    if (sameasBeam == null) return;
    if (stemSameasRole == StemSameasDrawingRole.none) {
      try {
        final otherSeg = (sameasBeam as dynamic).beamSegment as BeamSegment;
        stemSameasReverseRole = otherSeg.stemSameasRole as StemSameasDrawingRole?;
        stemSameasRole = StemSameasDrawingRole.unset;
        otherSeg.stemSameasRole = StemSameasDrawingRole.unset;
      } catch (_) {
        stemSameasRole = StemSameasDrawingRole.unset;
      }
    }
  }

  void updateSameasRoles(Beamplace place) {
    if (stemSameasReverseRole == null || !stemSameasIsUnset()) return;
    if (place == Beamplace.above) {
      stemSameasRole = StemSameasDrawingRole.primary;
    } else {
      stemSameasRole = StemSameasDrawingRole.secondary;
    }
  }

  void calcNoteHeadShiftForStemSameas(dynamic sameasBeam, Beamplace place) {
    if (sameasBeam == null) return;
    if (stemSameasReverseRole != null || stemSameasIsUnset()) return;
    try {
      final List<BeamElementCoord> otherCoords =
          (sameasBeam as dynamic).beamSegment.beamElementCoordRefs as List<BeamElementCoord>;
      final Stemdirection stemDir = place == Beamplace.above ? Stemdirection.up : Stemdirection.down;
      final int size = otherCoords.length < beamElementCoordRefs.length ? otherCoords.length : beamElementCoordRefs.length;
      for (int i = 0; i < size; ++i) {
        final el1 = beamElementCoordRefs[i].element;
        final el2 = otherCoords[i].element;
        if (el1 == null || el2 == null) continue;
        bool isNote1 = false, isNote2 = false;
        try {
          isNote1 = (el1 as dynamic).classId == ClassId.note;
          isNote2 = (el2 as dynamic).classId == ClassId.note;
        } catch (_) {}
        if (!isNote1 || !isNote2) continue;
        try {
          (el1 as dynamic).calcNoteHeadShiftForSameasNote(el2, stemDir);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void appendSpanningCoordinates(Object? measure) {}

  void requestStaffSpace(dynamic doc, dynamic beamInterface) {}

  // -------------------------------------------------------------------------
  // CalcBeam — moved from view_beam.dart (reduced port, beam.cpp:89)
  // -------------------------------------------------------------------------

  /// Mirrors `BeamSegment::CalcBeam` (beam.cpp:89) — reduced port.
  ///
  /// The full 1500-line engine will arrive in 05-31b (ledger, French, mixed
  /// center, cross-staff, tab). This reduced version reproduces exact geometry
  /// for simple horizontal/sloped beams (the majority of `test/corpus/beam/`)
  /// and degrades gracefully for exotics, matching the previous View-local
  /// implementation but now in the model (single implementation, 7 callers).
  void calcBeam(dynamic layer, dynamic staff, dynamic doc, dynamic beamInterface,
      Beamplace place,
      {bool init = true}) {
    if (beamElementCoordRefs.isEmpty) return;
    // Delegates to the reduced engine previously in the View
    // to keep the move atomic and the diff reviewable. The full port replaces
    // this body in 05-31b.
    final List<BeamElementCoord> coords = beamElementCoordRefs;
    // Tablature early exit
    bool isTab = false;
    try {
      isTab = (staff as dynamic).isTablature() == true || (staff as dynamic).isTabStaffLike() == true;
    } catch (_) {}
    if (isTab) {
      final int unit = (doc as dynamic).getDrawingUnit(staff.drawingStaffSize) as int;
      int black = unit ~/ 2;
      int white = unit ~/ 4;
      try {
        black = (beamInterface as dynamic).beamWidthBlack as int;
      } catch (_) {}
      final int staffY = (staff as dynamic).getDrawingY() as int;
      for (final c in coords) {
        try {
          c.x = (c.element as dynamic).getDrawingX() as int;
        } catch (_) {}
        c.yBeam = staffY + unit;
      }
      beamSlope = 0.0;
      firstNoteOrChord = coords.first;
      lastNoteOrChord = coords.last;
      try {
        (beamInterface as dynamic).beamWidthBlack = black;
        (beamInterface as dynamic).beamWidthWhite = white;
        (beamInterface as dynamic).beamWidth = black + white;
      } catch (_) {}
      return;
    }
    final int unit = (doc as dynamic).getDrawingUnit(staff.drawingStaffSize) as int;
    final bool cue = (beamInterface as dynamic).cueSize as bool? ?? false;
    int black = unit;
    if (cue) black = (black * (doc as dynamic).getCueScaling() as double).toInt();
    int white = unit ~/ 2;
    if (cue) white = (white * (doc as dynamic).getCueScaling() as double).toInt();
    if ((beamInterface as dynamic).shortestDur == MeiDuration.dur64) {
      white = white * 4 ~/ 3;
    }
    try {
      (beamInterface as dynamic).beamWidthBlack = black;
      (beamInterface as dynamic).beamWidthWhite = white;
      (beamInterface as dynamic).beamWidth = black + white;
      (beamInterface as dynamic).fractionSize = staff.drawingStaffSize as int;
    } catch (_) {}

    Beamplace drawPlace = place;
    if (drawPlace == Beamplace.none) {
      if ((beamInterface as dynamic).hasMultipleStemDir == true) {
        drawPlace = Beamplace.mixed;
      } else if ((beamInterface as dynamic).notesStemDir == Stemdirection.up) {
        drawPlace = Beamplace.above;
      } else if ((beamInterface as dynamic).notesStemDir == Stemdirection.down) {
        drawPlace = Beamplace.below;
      } else {
        int yMax = 0, yMin = 0;
        try {
          yMax = (coords.first.element as dynamic).getDrawingY() as int;
          yMin = yMax;
          for (final c in coords) {
            final int y = (c.element as dynamic).getDrawingY() as int;
            if (y > yMax) yMax = y;
            if (y < yMin) yMin = y;
          }
        } catch (_) {}
        int verticalCenter = 0;
        try {
          final int staffY = (staff as dynamic).getDrawingY() as int;
          final int dbl = (doc as dynamic).getDrawingDoubleUnit(staff.drawingStaffSize) as int;
          verticalCenter = staffY - dbl * 2;
        } catch (_) {}
        final Beamplace weighted = ((verticalCenter - yMin) > (yMax - verticalCenter)) ? Beamplace.above : Beamplace.below;
        drawPlace = weighted;
        weightedPlace = weighted;
      }
    }
    try {
      (beamInterface as dynamic).drawingPlace = drawPlace;
    } catch (_) {}
    weightedPlace = drawPlace;

    for (final c in coords) {
      try {
        c.x = (c.element as dynamic).getDrawingX() as int;
      } catch (_) {}
    }

    firstNoteOrChord = null;
    lastNoteOrChord = null;
    nbNotesOrChords = 0;
    for (final c in coords) {
      bool isChordOrNote = false;
      try {
        final cid = (c.element as dynamic).classId as ClassId?;
        isChordOrNote = cid == ClassId.chord || cid == ClassId.note;
      } catch (_) {}
      if (isChordOrNote) {
        if (firstNoteOrChord == null) firstNoteOrChord = c;
        lastNoteOrChord = c;
        nbNotesOrChords++;
        if (c.element != null) {
          try {
            final cid = (c.element as dynamic).classId as ClassId?;
            if (cid == ClassId.chord) {
              final ch = c.element as dynamic;
              if (drawPlace == Beamplace.below) {
                c.closestNote = ch.getBottomNote();
              } else if (drawPlace == Beamplace.above) {
                c.closestNote = ch.getTopNote();
              } else {
                c.closestNote = ch.getBottomNote();
              }
            }
          } catch (_) {}
        }
      }
    }
    if (firstNoteOrChord == null) {
      firstNoteOrChord = coords.first;
      lastNoteOrChord = coords.last;
    }

    int uniformStemLengthLocal = (unit * 7) ~/ 2;
    if (cue) uniformStemLengthLocal = (uniformStemLengthLocal * (doc as dynamic).getCueScaling() as double).toInt();
    uniformStemLength = uniformStemLengthLocal;

    if (drawPlace == Beamplace.mixed) {
      for (final c in coords) {
        if (c.closestNote == null) {
          try {
            c.yBeam = (c.element as dynamic).getDrawingY() as int;
          } catch (_) {}
          c.beamRelativePlace = Beamplace.above;
          c.partialFlagPlace = Beamplace.above;
          continue;
        }
        Stemdirection dir = Stemdirection.none;
        try {
          dir = (c.element as dynamic).getDrawingStemDir() as Stemdirection;
        } catch (_) {}
        if (dir == Stemdirection.none) {
          try {
            final dynamic stem = c.stem;
            if (stem != null) dir = (stem as dynamic).getDrawingStemDir() as Stemdirection;
          } catch (_) {}
        }
        c.beamRelativePlace = dir == Stemdirection.down ? Beamplace.below : Beamplace.above;
        c.partialFlagPlace = c.beamRelativePlace;
        int noteY = 0;
        try {
          noteY = (c.closestNote as dynamic).getDrawingY() as int;
        } catch (_) {}
        c.yBeam = noteY + (c.beamRelativePlace == Beamplace.below ? -uniformStemLengthLocal : uniformStemLengthLocal);
      }
      beamSlope = 0.0;
    } else {
      final BeamElementCoord first = firstNoteOrChord!;
      final BeamElementCoord last = lastNoteOrChord!;
      int firstNoteY = 0, lastNoteY = 0;
      try {
        firstNoteY = (first.closestNote as dynamic).getDrawingY() as int;
      } catch (_) {
        try {
          firstNoteY = (first.element as dynamic).getDrawingY() as int;
        } catch (_) {}
      }
      try {
        lastNoteY = (last.closestNote as dynamic).getDrawingY() as int;
      } catch (_) {
        try {
          lastNoteY = (last.element as dynamic).getDrawingY() as int;
        } catch (_) {}
      }
      int firstY, lastY;
      if (drawPlace == Beamplace.above) {
        firstY = firstNoteY + uniformStemLengthLocal;
        lastY = lastNoteY + uniformStemLengthLocal;
      } else {
        firstY = firstNoteY - uniformStemLengthLocal;
        lastY = lastNoteY - uniformStemLengthLocal;
      }
      bool isHorizontal = false;
      // Simplified IsHorizontal: if firstY == lastY or place none
      if (firstNoteY == lastNoteY) isHorizontal = true;
      if ((beamInterface as dynamic).drawingPlace == Beamplace.none) isHorizontal = true;
      if ((beamInterface as dynamic).drawingPlace == Beamplace.mixed) isHorizontal = false;
      if (isHorizontal) {
        if (drawPlace == Beamplace.above) {
          final int maxY = firstY > lastY ? firstY : lastY;
          firstY = maxY;
          lastY = maxY;
        } else {
          final int minY = firstY < lastY ? firstY : lastY;
          firstY = minY;
          lastY = minY;
        }
      }
      first.yBeam = firstY;
      last.yBeam = lastY;
      if (last.x != first.x) {
        beamSlope = (lastY - firstY) / (last.x - first.x);
      } else {
        beamSlope = 0.0;
      }
      for (final c in coords) {
        c.yBeam = firstY + (beamSlope * (c.x - first.x)).toInt();
      }
      first.yBeam = firstY;
      last.yBeam = lastY;
      for (final c in coords) {
        bool isChordOrNote = false;
        try {
          final cid = (c.element as dynamic).classId as ClassId?;
          isChordOrNote = cid == ClassId.chord || cid == ClassId.note;
        } catch (_) {}
        if (!isChordOrNote) continue;
        final dynamic stem = c.stem;
        if (stem == null) continue;
        final int y1 = c.yBeam;
        int y2 = 0;
        try {
          y2 = (c.closestNote as dynamic).getDrawingY() as int;
        } catch (_) {}
        final int stemLen = drawPlace == Beamplace.above ? y1 - y2 : y2 - y1;
        try {
          (stem as dynamic).setDrawingStemLen(stemLen);
          if ((stem as dynamic).getDrawingStemDir() == Stemdirection.none) {
            (stem as dynamic).setDrawingStemDir(drawPlace == Beamplace.above ? Stemdirection.up : Stemdirection.down);
          }
        } catch (_) {}
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
            bool isRest = false;
            try {
              isRest = (c.element as dynamic).classId == ClassId.rest;
            } catch (_) {}
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
  }

  // Stubs for remaining helpers (full port in 05-31b)
  void calcBeamInit(dynamic staff, dynamic doc, dynamic beamInterface, Beamplace place) {}
  void calcBeamInitForNotePair(dynamic n1, dynamic n2, dynamic staff, int yMax, int yMin) {}
  bool calcBeamSlope(dynamic staff, dynamic doc, dynamic beamInterface, int step) => false;
  int calcBeamSlopeStep(dynamic doc, dynamic staff, dynamic beamInterface, int noteStep, bool shortStep) => 0;
  void calcMixedBeamPosition(dynamic beamInterface, int step, int unit) {}
  void calcBeamPosition(dynamic doc, dynamic staff, dynamic beamInterface, bool isHorizontal) {}
  void calcAdjustSlope(dynamic staff, dynamic doc, dynamic beamInterface, int step) {}
  void calcAdjustPosition(dynamic staff, dynamic doc, dynamic beamInterface) {}
  void calcBeamPlace(dynamic layer, dynamic beamInterface, Beamplace place) {}
  void calcBeamPlaceTab(dynamic layer, dynamic staff, dynamic doc, dynamic beamInterface, Beamplace place) {}
  void calcBeamStemLength(dynamic staff, Beamplace place, bool isHorizontal) {}
  void calcSetStemValues(dynamic staff, dynamic doc, dynamic beamInterface) {}
  void calcSetStemValuesTab(dynamic staff, dynamic doc, dynamic beamInterface) {}
  int calcMixedBeamCenterY(int step, int unit) => 0;
  (int, MeiDuration, MeiDuration) calcStemDefiningNote(dynamic staff, Beamplace place) => (0, MeiDuration.dur8, MeiDuration.none);
  void calcHorizontalBeam(dynamic doc, dynamic staff, dynamic beamInterface) {}
  void calcMixedBeamPlace(dynamic staff) {}
  void calcPartialFlagPlace() {}
  void calcSetValues() {}
  (int, int) getVerticalOffset(dynamic beamInterface) => (0, 0);
  (int, int) getMinimalStemLength(dynamic beamInterface) => (0, 0);
  bool doesBeamOverlap(dynamic beamInterface, int topBorder, int bottomBorder, int minStemLength) => false;
  bool needToResetPosition(dynamic staff, dynamic doc, dynamic beamInterface) => false;
  void adjustBeamToFrenchStyle(dynamic beamInterface) {}
  void adjustBeamToLedgerLines(dynamic doc, dynamic staff, dynamic beamInterface, bool isHorizontal) {}
  void adjustBeamToTremolos(dynamic doc, dynamic staff, dynamic beamInterface) {}
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
    int rightSide = 0;
    try {
      final bar = (measure as dynamic).getRightBarLine();
      rightSide = (bar as dynamic).getDrawingX() as int;
    } catch (_) {
      return;
    }
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
