/// Port of `calcspanningbeamspansfunctor.h/cpp` — breaks a `<beamSpan>` that
/// crosses systems into one segment per system, so each can be drawn as its
/// own control element.
///
/// Deviations from the C++:
/// - Verified against `cpp_probe` task `04f` (`beamspan/beamspan-001.mei`,
///   the corpus file built for cross-system `beamSpan`): under this
///   project's plain rendering invocation (`-x 12345 -o out.svg`, no forced
///   narrow page / `--breaks`), both of its measures land in the same,
///   single system, so [visitBeamSpan] only ever takes the `noop_samesystem`
///   early return — matched at epsilon 0 against the fixture. The
///   segment-creation path (`BeamSpan.addSpanningSegment`) is not exercised
///   by any file in the fixed corpus and is instead verified on a synthetic
///   two-system tree in `test/adjust_x_overflow_test.dart` — see
///   `prompts/reports/04f.md`.
/// - Task 05-40 loop 05 ported `CalcStemFunctor::VisitBeamSpan`
///   (calcstemfunctor.cpp:80, see `calc_functors.dart`), which calls
///   `BeamDrawingInterface::InitCoords` for every `beamSpan` and populates
///   `BeamSpan.beamElementCoordsOwned` — the same list `addSpanningSegment`
///   reads from. Before that fix `beamElementCoordsOwned` was always empty
///   in production (nothing called `initCoords` for a `beamSpan`), so
///   `addSpanningSegment`'s coordinate lookup always failed and — far more
///   consequentially — `BeamSpan.getSegment(0)` (the seed segment every
///   `beamSpan` starts with, `InitBeamSegments`) never got a `measure`, so
///   `GetSegmentForSystem` (`view_beam.dart`) returned null and
///   *every* `beamSpan` — cross-system or not — drew nothing but an empty
///   `<g>`. That was the real root cause of `beamspan/*` being 0/6
///   structurally clean; this functor's own same-system-only coverage was
///   never the bottleneck.
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart' show BeamSpan;
import 'package:verovio_dart/src/model/object.dart';

/// This class resolves spanning beamSpans by breaking them into separate
/// parts, each belonging to the corresponding system/measure (mirrors
/// `vrv::CalcSpanningBeamSpansFunctor`).
class CalcSpanningBeamSpansFunctor extends DocFunctor {
  CalcSpanningBeamSpansFunctor(super.doc);

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitBeamSpan(BeamSpan beamSpan) {
    final List<Object> beamedElements = beamSpan.getBeamedElements();

    if (beamedElements.isEmpty ||
        beamSpan.getStart() == null ||
        beamSpan.getEnd() == null) {
      return FunctorCode.continue_;
    }

    final Object? startSystem =
        beamSpan.getStart()!.getFirstAncestor(ClassId.system);
    final Object? endSystem = beamSpan.getEnd()!.getFirstAncestor(ClassId.system);
    assert(startSystem != null && endSystem != null);
    if (identical(startSystem, endSystem)) {
      return FunctorCode.continue_;
    }

    // Find layerElements that belong to another system and store them
    // alongside the system they belong to. This will allow us to break down
    // the beamSpan based on the systems. [elements] entries are
    // `(startIndex, system)` — see the doc comment on
    // `BeamSpan.addSpanningSegment` for why this differs shape-wise from the
    // C++'s iterator-based `SpanIndexVector`.
    final List<(int, Object?)> elements = [];
    Object? firstSystem = startSystem;
    int iter = 0;
    while (iter < beamedElements.length) {
      elements.add((iter, firstSystem));
      int found = beamedElements.length;
      for (int k = iter; k < beamedElements.length; ++k) {
        final Object? parentSystem =
            beamedElements[k].getFirstAncestor(ClassId.system);
        if (identical(firstSystem, parentSystem)) continue;
        firstSystem = parentSystem;
        found = k;
        break;
      }
      iter = found;
    }
    elements.add((beamedElements.length, null));

    // Iterator for the elements are based on the initial order of the
    // elements, so skip the current system when found and process it
    // separately in the end.
    final Object? currentSystem = beamSpan.getFirstAncestor(ClassId.system);
    int currentSystemIndex = 0;
    for (int i = 0; i < elements.length - 1; ++i) {
      if (identical(elements[i].$2, currentSystem)) {
        currentSystemIndex = i;
        continue;
      }
      beamSpan.addSpanningSegment(doc, elements, i);
    }
    beamSpan.addSpanningSegment(doc, elements, currentSystemIndex,
        newSegment: false);

    return FunctorCode.continue_;
  }
}
