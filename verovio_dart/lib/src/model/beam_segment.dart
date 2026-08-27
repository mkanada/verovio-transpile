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

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/vrvdef.dart'
    show spanningEnd, spanningMiddle, spanningStart, spanningStartEnd;
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

  /// The note or chord the coord stands for (mirrors `m_element`). Typed as
  /// [Object] to avoid an import cycle with the generated element classes.
  Object? element;

  /// The closest note for chords (mirrors `m_closestNote`).
  Object? closestNote;

  /// A pointer to the stem, cached to avoid re-casts (mirrors `m_stem`).
  Object? stem;
}

/// Port of the state parts of `vrv::BeamSegment` (beam.h:36).
class BeamSegment {
  /// Values set by `CalcBeam`: the slope of the beam (mirrors `m_beamSlope`).
  double beamSlope = 0.0;

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

  /// Mirrors `BeamSegment::Reset`.
  void reset() {
    beamSlope = 0.0;
    beamElementCoordRefs.clear();
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
