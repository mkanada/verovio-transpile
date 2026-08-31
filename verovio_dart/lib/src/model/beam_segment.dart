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
import 'package:verovio_dart/src/model/atts/atts_shared.dart' show AttStems;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Layer, Measure, Staff, Note;
import 'package:verovio_dart/src/model/doc.dart' show Doc;
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show BeamDrawingInterface, StemmedDrawingInterface;
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Beam, Chord, Stem;
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

  /// Mirrors `BeamElementCoord::SetDrawingStemDir` (beam.cpp:1837).
  ///
  /// Reduced port: only the stem-direction propagation is implemented
  /// (`m_stem->SetDrawingStemDir(stemDir)`, beam.cpp:1867) so that consumers
  /// reading the element's drawing stem direction (CalcArticFunctor, stem
  /// drawing) see the beam-resolved value. The m_x / m_yBeam geometry part
  /// is the pending 05-31b task.
  void setDrawingStemDir(Stemdirection dir, Object? staff, Object? doc,
      BeamSegment segment, dynamic beamInterface) {
    final Object? el = element;
    if (el == null) return;
    final StemmedDrawingInterface? holder =
        (el is LayerElement) ? el.getStemmedDrawingInterface() : null;
    if (holder == null) return;
    final Stem? stem = holder.getDrawingStem();
    stem?.setDrawingStemDir(dir);
  }

  /// Mirrors `BeamElementCoord::SetClosestNoteOrTabDurSym` (beam.cpp:2002).
  void setClosestNoteOrTabDurSym(Stemdirection dir, bool outsideStaff) {}

  /// Mirrors `BeamElementCoord::CalculateStemLength` (beam.cpp:1915).
  int calculateStemLength(Object? staff, Stemdirection dir, bool isHorizontal,
          MeiDuration prefDur) =>
      0;

  /// Mirrors `BeamElementCoord::CalculateStemLengthTab` (beam.cpp:1959).
  int calculateStemLengthTab(Object? staff, Stemdirection dir) => 0;

  /// Mirrors `BeamElementCoord::CalculateStemModAdjustment` (beam.cpp:1967).
  int calculateStemModAdjustment(int len, int bias) => 0;

  /// Mirrors `BeamElementCoord::GetStemHolderInterface` (beam.cpp:1988).
  Object? getStemHolderInterface() => null;

  /// Mirrors `BeamElementCoord::UpdateStemLength` (beam.cpp:2023).
  void updateStemLength(Object? iface, int y1, int y2, int adjust, bool mixed) {}
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

  void initSameasRoles(Object? sameasBeam, Beamplace place) {
    if (sameasBeam == null) return;
    if (sameasBeam is! Beam) {
      if (stemSameasRole == StemSameasDrawingRole.none) {
        stemSameasRole = StemSameasDrawingRole.unset;
      }
      return;
    }
    final Beam beam = sameasBeam;
    if (stemSameasRole == StemSameasDrawingRole.none) {
      final BeamSegment otherSeg = beam.beamSegment;
      stemSameasReverseRole = otherSeg.stemSameasRole;
      stemSameasRole = StemSameasDrawingRole.unset;
      otherSeg.stemSameasRole = StemSameasDrawingRole.unset;
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

  void calcNoteHeadShiftForStemSameas(Object? sameasBeam, Beamplace place) {
    if (sameasBeam == null) return;
    if (stemSameasReverseRole != null || stemSameasIsUnset()) return;
    if (sameasBeam is! Beam) return;
    final List<BeamElementCoord> otherCoords = sameasBeam.beamSegment.beamElementCoordRefs;
    final Stemdirection stemDir = place == Beamplace.above ? Stemdirection.up : Stemdirection.down;
    final int size = otherCoords.length < beamElementCoordRefs.length ? otherCoords.length : beamElementCoordRefs.length;
    for (int i = 0; i < size; ++i) {
      final Object? el1 = beamElementCoordRefs[i].element;
      final Object? el2 = otherCoords[i].element;
      if (el1 == null || el2 == null) continue;
      final bool isNote1 = el1.classId == ClassId.note;
      final bool isNote2 = el2.classId == ClassId.note;
      if (!isNote1 || !isNote2) continue;
      if (el1 is Note && el2 is Note) {
        // Mirrors Note::CalcNoteHeadShiftForSameasNote — stubbed in this reduced engine.
        // Full port in 05-31b delegates to Note; here we just guard the call.
        // Dart Note does not yet expose that method headlessly; keep no-op with guard.
        // ignore: unused_local_variable
        final Stemdirection _ = stemDir;
      }
    }
  }

  void appendSpanningCoordinates(Object? measure) {}

  void requestStaffSpace(Object? doc, Object? beamInterface) {}

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

    Beamplace drawPlace = place;
    if (drawPlace == Beamplace.none) {
      if (beamInterface.hasMultipleStemDir == true) {
        drawPlace = Beamplace.mixed;
      } else if (beamInterface.notesStemDir == Stemdirection.up) {
        drawPlace = Beamplace.above;
      } else if (beamInterface.notesStemDir == Stemdirection.down) {
        drawPlace = Beamplace.below;
      } else {
        int yMax = 0, yMin = 0;
        final Object? firstEl = coords.first.element;
        if (firstEl != null) {
          yMax = firstEl.getDrawingY();
          yMin = yMax;
          for (final c in coords) {
            final Object? el = c.element;
            if (el == null) continue;
            final int y = el.getDrawingY();
            if (y > yMax) yMax = y;
            if (y < yMin) yMin = y;
          }
        }
        int verticalCenterLocal = 0;
        final int staffY = staff.getDrawingY();
        final int dbl = doc.getDrawingDoubleUnit(staff.drawingStaffSize);
        verticalCenterLocal = staffY - dbl * 2;
        final Beamplace weighted = ((verticalCenterLocal - yMin) > (yMax - verticalCenterLocal)) ? Beamplace.above : Beamplace.below;
        drawPlace = weighted;
        weightedPlace = weighted;
      }
    }
    beamInterface.drawingPlace = drawPlace;
    weightedPlace = drawPlace;

    // Set drawing stem positions (mirrors `BeamSegment::CalcBeamPosition`,
    // beam.cpp:912-936; the geometry part of SetDrawingStemDir — m_x /
    // m_yBeam — is the pending 05-31b task, only the direction propagates).
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

    for (final c in coords) {
      final Object? el = c.element;
      if (el != null) {
        c.x = el.getDrawingX();
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

    int uniformStemLengthLocal = (unit * 7) ~/ 2;
    if (cue) uniformStemLengthLocal = (uniformStemLengthLocal * doc.getCueScaling()).toInt();
    uniformStemLength = uniformStemLengthLocal;

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
        c.yBeam = noteY + (c.beamRelativePlace == Beamplace.below ? -uniformStemLengthLocal : uniformStemLengthLocal);
      }
      beamSlope = 0.0;
    } else {
      final BeamElementCoord first = firstNoteOrChord!;
      final BeamElementCoord last = lastNoteOrChord!;
      int firstNoteY = 0, lastNoteY = 0;
      final Object? fn = first.closestNote;
      if (fn != null) {
        firstNoteY = fn.getDrawingY();
      } else {
        final Object? fe = first.element;
        if (fe != null) firstNoteY = fe.getDrawingY();
      }
      final Object? ln = last.closestNote;
      if (ln != null) {
        lastNoteY = ln.getDrawingY();
      } else {
        final Object? le = last.element;
        if (le != null) lastNoteY = le.getDrawingY();
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
      if (beamInterface.drawingPlace == Beamplace.none) isHorizontal = true;
      if (beamInterface.drawingPlace == Beamplace.mixed) isHorizontal = false;
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
        final Object? el = c.element;
        bool isChordOrNote = false;
        if (el != null) {
          final ClassId cid = el.classId;
          isChordOrNote = cid == ClassId.chord || cid == ClassId.note;
        }
        if (!isChordOrNote) continue;
        final Object? s = c.stem;
        if (s == null) continue;
        if (s is! Stem) continue;
        final Stem stemObj = s;
        final int y1 = c.yBeam;
        int y2 = 0;
        final Object? cn = c.closestNote;
        if (cn != null) {
          y2 = cn.getDrawingY();
        }
        final int stemLen = drawPlace == Beamplace.above ? y1 - y2 : y2 - y1;
        stemObj.setDrawingStemLen(stemLen);
        if (stemObj.getDrawingStemDir() == Stemdirection.none) {
          stemObj.setDrawingStemDir(drawPlace == Beamplace.above ? Stemdirection.up : Stemdirection.down);
        }
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
  }

  // Stubs for remaining helpers (full port in 05-31b)
  void calcBeamInit(Object? staff, Object? doc, Object? beamInterface, Beamplace place) {}
  void calcBeamInitForNotePair(Object? n1, Object? n2, Object? staff, int yMax, int yMin) {}
  bool calcBeamSlope(Object? staff, Object? doc, Object? beamInterface, int step) => false;
  int calcBeamSlopeStep(Object? doc, Object? staff, Object? beamInterface, int noteStep, bool shortStep) => 0;
  void calcMixedBeamPosition(Object? beamInterface, int step, int unit) {}
  void calcBeamPosition(Object? doc, Object? staff, Object? beamInterface, bool isHorizontal) {}
  void calcAdjustSlope(Object? staff, Object? doc, Object? beamInterface, int step) {}
  void calcAdjustPosition(Object? staff, Object? doc, Object? beamInterface) {}
  void calcBeamPlace(Object? layer, Object? beamInterface, Beamplace place) {}
  void calcBeamPlaceTab(Object? layer, Object? staff, Object? doc, Object? beamInterface, Beamplace place) {}
  void calcBeamStemLength(Object? staff, Beamplace place, bool isHorizontal) {}
  void calcSetStemValues(Object? staff, Object? doc, Object? beamInterface) {}
  void calcSetStemValuesTab(Object? staff, Object? doc, Object? beamInterface) {}
  int calcMixedBeamCenterY(int step, int unit) => 0;
  (int, MeiDuration, MeiDuration) calcStemDefiningNote(Object? staff, Beamplace place) => (0, MeiDuration.dur8, MeiDuration.none);
  void calcHorizontalBeam(Object? doc, Object? staff, Object? beamInterface) {}
  void calcMixedBeamPlace(Object? staff) {}
  void calcPartialFlagPlace() {}
  void calcSetValues() {}
  (int, int) getVerticalOffset(Object? beamInterface) => (0, 0);
  (int, int) getMinimalStemLength(Object? beamInterface) => (0, 0);
  bool doesBeamOverlap(Object? beamInterface, int topBorder, int bottomBorder, int minStemLength) => false;
  bool needToResetPosition(Object? staff, Object? doc, Object? beamInterface) => false;
  void adjustBeamToFrenchStyle(Object? beamInterface) {}
  void adjustBeamToLedgerLines(Object? doc, Object? staff, Object? beamInterface, bool isHorizontal) {}
  void adjustBeamToTremolos(Object? doc, Object? staff, Object? beamInterface) {}
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
