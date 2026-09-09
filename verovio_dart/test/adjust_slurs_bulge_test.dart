/// Coverage for `AdjustSlursFunctor.adjustSlurFromBulge` (`@bulge`,
/// `adjustslursfunctor.cpp:424-482`), ported for `invest-05` item 2.
///
/// No corpus file exercises this branch: `AdjustSlursFunctor` only ever
/// visits `SLUR`/`PHRASE` (`adjustslursfunctor.cpp:49`), and the only
/// `@bulge` in the corpus is on a `<tie>` (`test/corpus/tie/tie-006.mei`),
/// which never reaches `AdjustSlurFromBulge` — `Tie::CalculatePosition`
/// (`tie.cpp:133+`) never reads `@bulge`. So this uses a synthetic fixture
/// (`test/fixtures/synthetic/slur_bulge.mei`, a two-note slur with
/// `bulge="2 30"`) plus values captured from the real C++ binary, via
/// `cpp_probe` patch `05-53` (fprintf-only, `diff` against the clean binary
/// verified empty — see `cpp_probe/patches/05-53.patch`):
///
/// ```
/// build-probe/build/verovio -r verovio_dart/assets/data -x 12345 \
///     -o /tmp/out.svg verovio_dart/test/fixtures/synthetic/slur_bulge.mei
/// ```
///
/// **Entry-state divergence, found and fixed.** Patch 05-53 also printed
/// the bezier this fixture's slur enters `AdjustSlurFromBulge` with, and it
/// did NOT match the entry state the Dart pipeline produced for the same
/// fixture at the time (p1/p2 agreed; c1/c2 and the control heights didn't:
/// C++ `c1=(1288,-1522) c2=(1638,-1402) lH=-120 rH=120` vs Dart
/// `c1=(1249,-1769) c2=(1820,-1574) lH=127 rH=292`). Root cause: `Slur::
/// CalcInitialCurve` (slur.cpp:1148-1153) branches on `HasBulge()` — bulge
/// slurs get the parameterless `CalcInitialControlPointParams()` (offset =
/// dist/3, height = 0), non-bulge slurs get the doc-aware overload — and
/// `calcInitialCurveFor` (`slur_positioning.dart`) always called the
/// doc-aware overload, skipping that branch. Fixed there; the end-to-end
/// test below now matches the real C++ binary byte for byte. It was
/// invisible on the ordinary (non-bulge) collision-driven path because
/// steps 4-6 of `AdjustSlur` (`AllowControlOffsetAdjustment`/
/// `CalcControlPointVerticalShift`/`AdjustSlurShape`) re-derive the same
/// final shape regardless of it for every corpus slur measured so far,
/// self-correcting the stale entry state — `@bulge` was the first path
/// that skipped straight from that entry state to the output with no
/// further correction, making it the first thing to expose the bug. Logged
/// in `prompts/loop-diario.md` (2026-09-09).
///
/// `adjustSlurFromBulge` is additionally verified in isolation: fed the
/// real C++ entry bezier (from the probe) directly and checked against the
/// real C++ intermediate (shift) and final (post-`AdjustSlurShape`) control
/// points from the same probe run — proving this specific port
/// byte-for-byte correct independent of entry state.
library;

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart' show BezierCurve;
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart' show spanningStartEnd;
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/layout/adjust_slurs.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show FloatingCurvePositioner;
import 'package:verovio_dart/src/layout/vertical_aligner.dart' show StaffAlignment;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show CurvatureCurvedir;
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Slur;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/testing/svg_compare.dart';

/// Builds a `FloatingCurvePositioner` whose own drawing offset is zero, so
/// the [BezierCurve] points passed to `adjustSlurFromBulge` are used as
/// absolute coordinates directly (matches how `cpp_probe` patch 05-53's
/// values were captured: raw `Point` fields, no page/staff offset).
FloatingCurvePositioner _buildPositioner(Slur slur, CurvatureCurvedir dir,
    List<Point> initialPoints) {
  final positioner =
      FloatingCurvePositioner(slur, StaffAlignment(), spanningStartEnd);
  positioner.setObjectXY(StaffAlignment(), StaffAlignment());
  positioner.updateCurveParams(initialPoints, 0, dir);
  return positioner;
}

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  group('AdjustSlursFunctor.adjustSlurFromBulge (adjustslursfunctor.cpp:424)',
      () {
    // Entry bezier captured from the real C++ binary via cpp_probe patch
    // 05-53 for test/fixtures/synthetic/slur_bulge.mei's one slur (see the
    // library doc comment for why this is fed directly instead of letting
    // the Dart pipeline derive it).
    final Point p1 = Point(938, -1642);
    final Point c1 = Point(1288, -1522);
    final Point c2 = Point(1638, -1402);
    final Point p2 = Point(1988, -1282);
    const int unit = 90;

    Slur buildSlur() => Slur()..bulge = [(2.0, 30.0)];

    BezierCurve buildBezier() {
      final bezier = BezierCurve.of(p1, c1, c2, p2);
      bezier.setControlSides(false, false); // both "below", per the probe.
      bezier.updateControlPointParams();
      return bezier;
    }

    test('matches the C++ binary\'s own final control points byte for byte',
        () {
      final slur = buildSlur();
      final bezier = buildBezier();
      final positioner =
          _buildPositioner(slur, CurvatureCurvedir.below, [p1, c1, c2, p2]);
      final functor = AdjustSlursFunctor(Doc())
        ..currentSlur = slur
        ..currentCurve = positioner;

      functor.adjustSlurFromBulge(bezier, unit);

      // Endpoints are never touched by AdjustSlurFromBulge.
      expect(bezier.p1, Point(938, -1642));
      expect(bezier.p2, Point(1988, -1282));
      // Captured as "PROBE05-53 afterShape" in cpp_probe/patches/05-53.patch.
      expect(bezier.c1, Point(1093, -1819));
      expect(bezier.c2, Point(1668, -1678));
    });

    test('@bulge is inert when the slur has no bulge (sanity: the branch is '
        'actually gated on `hasBulge`)', () {
      final slur = Slur(); // no bulge set.
      expect(slur.hasBulge, isFalse);
    });
  });

  group('end-to-end fixture', () {
    test('the no-bulge baseline matches the C++ binary exactly', () {
      final String? svg = renderSvgForComparison(
          'test/fixtures/synthetic/slur_no_bulge.mei');
      expect(svg, isNotNull);
      final match =
          RegExp(r'class="slur">\s*<path d="([^"]+)"').firstMatch(svg!);
      expect(match, isNotNull, reason: 'no <g class="slur"> found in $svg');
      expect(match!.group(1),
          'M938,2372 C1249,2468 1798,2279 1988,2012 C1839,2329 1248,2532 938,2372');
    });

    test('the bulge fixture matches the C++ binary exactly '
        '(regression test for the CalcInitialCurve HasBulge branch)', () {
      final String? svg =
          renderSvgForComparison('test/fixtures/synthetic/slur_bulge.mei');
      expect(svg, isNotNull);
      final match =
          RegExp(r'class="slur">\s*<path d="([^"]+)"').firstMatch(svg!);
      expect(match, isNotNull, reason: 'no <g class="slur"> found in $svg');
      // Captured with `build/verovio -r assets/data -x 12345 -o out.svg
      // test/fixtures/synthetic/slur_bulge.mei` on the real C++ binary.
      expect(match!.group(1),
          'M938,2372 C1102,2518 1650,2381 1988,2012 C1686,2437 1082,2582 938,2372');
    });
  });
}
