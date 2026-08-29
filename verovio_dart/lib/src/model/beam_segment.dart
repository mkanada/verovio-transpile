/// Minimal port of the beam-segment drawing state: `vrv::BeamSegment` and
/// `vrv::BeamElementCoord` (`origin/src/include/vrv/beam.h:36` and `:395`).
///
/// Only the state consumed by `AdjustBeamsFunctor` (adjustbeamsfunctor.cpp)
/// is carried here — see the task 04d report. The full geometry engine
/// (`BeamSegment::CalcBeam`, beam.cpp:89, and `BeamDrawingInterface::InitCoords`,
/// drawinginterface.cpp:140) arrives with its own task; until then nothing in
/// production populates [BeamSegment.beamElementCoordRefs], and every functor
/// that reads beam segment data degrades through its own C++ guards (an empty
/// coord list makes `AdjustBeamsFunctor::VisitBeam` return early exactly as in
/// the C++).
///
/// Deviations from the C++:
/// - `BeamSegment` here is a plain state holder, not the calculation engine:
///   `CalcBeam` and its ~20 helpers (beam.cpp:89-1610) are not ported yet.
/// - `m_beamElementCoords` (owned, `BeamDrawingInterface`) and
///   `m_beamElementCoordRefs` (the segment's reference list, set by
///   `InitCoordRefs` to point at the same objects) are a single list here:
///   without `CalcBeam` there is no second ordering to distinguish.
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/vrvdef.dart'
    show
        StemSameasDrawingRole,
        spanningEnd,
        spanningMiddle,
        spanningStart,
        spanningStartEnd;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/object.dart';

/// Port of the state parts of `vrv::BeamElementCoord` (beam.h:395).
class BeamElementCoord {
  /// The x position of the coord (mirrors `m_x`).
  int x = 0;

  /// The y value of the stem top position (mirrors `m_yBeam`).
  int yBeam = 0;

  /// The drawing duration (mirrors `m_dur`).
  MeiDuration dur = MeiDuration.dur8;

  /// The @breaksec value (mirrors `m_breaksec`).
  int breaksec = 0;

  /// The overlap margin the beam needs to be displaced by (mirrors
  /// `m_overlapMargin`); set by `AdjustBeamsFunctor::VisitBeamEnd`.
  int overlapMargin = 0;

  /// The beam place of the partial flags (mirrors `m_partialFlagPlace`),
  /// read by `Beam::GetAdditionalBeamCount`.
  Beamplace partialFlagPlace = Beamplace.none;

  /// The beam-relative place for mixed beams (mirrors `m_beamRelativePlace`).
  Beamplace beamRelativePlace = Beamplace.none;

  /// Partial flags per duration level (mirrors `m_partialFlags[MAX_DURATION_PARTIALS]`).
  /// Values are 0=PARTIAL_NONE, 1=THROUGH, 2=RIGHT, 3=LEFT.
  final List<int> partialFlags = List<int>.filled(16, 0);

  /// The note or chord the coord stands for (mirrors `m_element`). Typed as
  /// [Object] to avoid an import cycle with the generated element classes.
  Object? element;

  /// The closest note for chords (mirrors `m_closestNote`).
  Object? closestNote;

  /// TabDurSym for tablature beams (mirrors `m_tabDurSym`).
  Object? tabDurSym;

  /// A pointer to the stem, cached to avoid re-casts (mirrors `m_stem`).
  Object? stem;

  /// Whether the beam is centered on the line (mirrors `m_centered`).
  bool centered = false;
}

/// Port of the state parts of `vrv::BeamSegment` (beam.h:36).
class BeamSegment {
  /// Values set by `CalcBeam`: the slope of the beam (mirrors `m_beamSlope`).
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

  /// An array of coordinates for each element (mirrors
  /// `m_beamElementCoordRefs`); see the library doc comment for the owned /
  /// refs deviation.
  final List<BeamElementCoord> beamElementCoordRefs = <BeamElementCoord>[];

  /// Mirrors `BeamSegment::InitCoordRefs` (beam.cpp:84): points the segment
  /// at the coords computed from the beam's child list. The C++ copies the
  /// pointers of the passed array; here the [coords] entries are appended to
  /// the (reset) reference list.
  void initCoordRefs(List<BeamElementCoord> coords) {
    beamElementCoordRefs.clear();
    beamElementCoordRefs.addAll(coords);
  }

  /// Mirrors `BeamSegment::ClearCoordRefs`.
  void clearCoordRefs() => beamElementCoordRefs.clear();

  /// Mirrors `BeamSegment::Reset`.
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

  /// Mirrors `BeamSegment::GetElementCoordRefs`.
  List<BeamElementCoord> getElementCoordRefs() => beamElementCoordRefs;

  /// Mirrors `BeamSegment::GetStartingX` / `GetStartingY`.
  int getStartingX() => beamElementCoordRefs.isEmpty ? 0 : beamElementCoordRefs.first.x;
  int getStartingY() => beamElementCoordRefs.isEmpty ? 0 : beamElementCoordRefs.first.yBeam;

  /// Initialize sameas roles (mirrors `BeamSegment::InitSameasRoles`, beam.cpp:1493).
  void initSameasRoles(dynamic sameasBeam, Beamplace initialPlace) {
    if (sameasBeam == null) return;
    if (stemSameasRole == StemSameasDrawingRole.none) {
      try {
        final otherSeg = (sameasBeam as dynamic).beamSegment as BeamSegment;
        stemSameasReverseRole = otherSeg.stemSameasRole as StemSameasDrawingRole?;
        // Actually store reference to other's role? Simplified: set both to unset
        stemSameasRole = StemSameasDrawingRole.unset;
        otherSeg.stemSameasRole = StemSameasDrawingRole.unset;
      } catch (_) {
        stemSameasRole = StemSameasDrawingRole.unset;
      }
    } else if (stemSameasReverseRole == null) {
      // second beam calling
      // initialPlace adjustment handled by caller if needed
    }
  }

  /// Mirrors `BeamSegment::AppendSpanningCoordinates` (beam.cpp:1767) – minimal:
  /// extend the beam visually when spanning; here we just keep coordinates.
  void appendSpanningCoordinates(Object? measure) {
    // No-op for simple beams; kept for API parity with view_beam.cpp's
    // `AppendSpanningCoordinates` call.
  }
}

/// Port of `vrv::BeamSpanSegment` (beam.h:225) — one system-local slice of a
/// `beamSpan` that crosses systems, built by
/// `CalcSpanningBeamSpansFunctor`/`BeamSpan::AddSpanningSegment` (task 04f).
///
/// Deviation: `BeamSpanSegment::AppendSpanningCoordinates` (beam.cpp:1767) is
/// drawing code (extends the beam visually to the barline) consumed only by
/// `view_beam.cpp` — out of scope until the rendering phase (05-17).
class BeamSpanSegment extends BeamSegment {
  /// The measure this segment belongs to (mirrors `m_measure`).
  Object? measure;

  /// The staff this segment belongs to (mirrors `m_staff`).
  Object? staff;

  /// The layer this segment belongs to (mirrors `m_layer`).
  Object? layer;

  /// The first / last coordinate of the segment (mirrors `m_begin`/`m_end`).
  BeamElementCoord? beginCoord;
  BeamElementCoord? endCoord;

  /// The spanning type — one of `spanningStartEnd`/`spanningStart`/
  /// `spanningEnd`/`spanningMiddle` (`core/vrvdef.dart`; mirrors
  /// `m_spanningType`, default `SPANNING_START_END`).
  int spanningType = spanningStartEnd;

  /// Mirrors `BeamSpanSegment::SetSpanningType` (beam.cpp:1754): the first
  /// system-group gets `spanningStart`, the last gets `spanningEnd`, and
  /// everything in between gets `spanningMiddle`.
  void setSpanningType(int systemIndex, int systemCount) {
    if (systemIndex == 0) {
      spanningType = spanningStart;
    } else if (systemIndex == systemCount - 1) {
      spanningType = spanningEnd;
    } else {
      spanningType = spanningMiddle;
    }
  }
}
