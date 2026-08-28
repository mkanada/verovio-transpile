import 'package:test/test.dart';
import 'package:verovio_dart/src/layout/functor.dart';

/// The functor runs expected from `Page::LayOutHorizontally`
/// (`page.cpp:396-497`), including the `Page::ResetAligners` preamble
/// (`page.cpp:404`) and one entry per process call (the C++ re-runs the same
/// `AdjustXPosFunctor` instance at `page.cpp:453-456`, which the trace
/// records twice).
///
/// Deviations documented on `Page.layOutHorizontally` (doc.dart): the C++
/// AdjustOssiaStaffDef / AdjustArtic / AdjustNeumeX / AdjustAccidX /
/// InitProcessingLists / AdjustSylSpacingByVerse / AdjustHarmGrpsSpacing /
/// AdjustArpeg / AdjustTempo / AdjustXOverflow functors run in this port's
/// `layOutVertically` instead, because they consume rendered bounding boxes /
/// floating positioners that the headless pipeline only fills there. They are
/// asserted in [verticalFunctorSequence] below.
const List<String> horizontalFunctorSequence = [
  // Page::ResetAligners (page.cpp:404):
  'ResetHorizontalAlignmentFunctor',
  'AlignHorizontallyFunctor',
  // CalcAlignmentXPos runs unless evenNoteSpacing (default: off).
  'CalcAlignmentXPosFunctor',
  // page.cpp:425 / 430 / 438 (second pass with dots):
  'AdjustLayersFunctor',
  'AdjustDotsFunctor',
  'AdjustLayersFunctor',
  // page.cpp:448 and the same-instance re-run at page.cpp:453-456:
  'AdjustXPosFunctor',
  'AdjustXPosFunctor',
  'AdjustGraceXPosFunctor', // page.cpp:460
  'AdjustClefChangesFunctor', // page.cpp:465
  'AdjustTupletsXFunctor', // page.cpp:487
  'AlignMeasuresFunctor', // page.cpp:495
];

/// The functor runs expected from `Page::LayOutVertically`
/// (`page.cpp:509-608`), adjusted by the documented headless deviations of
/// `Page.layOutVertically` (doc.dart):
/// - the two BBoxDeviceContext render passes are replaced by
///   [HeadlessExtents] (plain class; only its private `_CurveBoxFiller`
///   functor goes through `Object.process`);
/// - the functors marked "(moved)" run here instead of
///   `LayOutHorizontally`, see `horizontalFunctorSequence`;
/// - CalcAlignmentPitchPos / CalcLigatureOrNeumePos run here instead of
///   `Page::ResetAligners` (needs drawingLoc / headless ordering);
/// - CalcLedgerLines runs after CalcAlignmentPitchPos instead of right after
///   ResetVerticalAlignment;
/// - the cross-staff slur redraw (second AdjustSlurs, `page.cpp:588-593`) and
///   the header / footer adjustments are not ported yet.
///
/// Sub-functor runs nested inside another functor's visits
/// (`AdjustTupletNumOverlapFunctor` inside AdjustTupletsY,
/// `AdjustFloatingPositionerGrpsFunctor` inside AdjustFloatingPositioners)
/// are not recorded by the trace and not asserted here.
///
/// An entry ending in `*` matches zero or more consecutive runs of that
/// functor (`AdjustSylSpacingByVerse` runs AdjustSylSpacingFunctor once per
/// verse in the verse tree, `page.cpp:473`).
const List<String> verticalFunctorSequence = [
  'ResetVerticalAlignmentFunctor', // page.cpp:518
  'AlignVerticallyFunctor', // page.cpp:527
  'CalcAlignmentPitchPosFunctor', // moved from Page::ResetAligners
  'CalcLigatureOrNeumePosFunctor', // moved from Page::ResetAligners
  'CalcLedgerLinesFunctor', // page.cpp:521, moved after pitchPos
  'AdjustOssiaStaffDefFunctor', // page.cpp:415 (moved)
  'AdjustNeumeXFunctor', // page.cpp:434 (moved)
  'AdjustArticFunctor', // page.cpp:419 (moved)
  'AdjustArticWithSlursFunctor', // page.cpp:539
  'AdjustAccidXFunctor', // page.cpp:443 (moved)
  'InitProcessingListsFunctor', // page.cpp:470 (moved)
  'AdjustSylSpacingFunctor*', // page.cpp:473 (moved), 0..N runs
  'AdjustHarmGrpsSpacingFunctor', // page.cpp:475 (moved)
  'AdjustArpegFunctor', // page.cpp:479 (moved)
  'AdjustTempoFunctor', // page.cpp:483 (moved)
  'AdjustXOverflowFunctor', // page.cpp:491 (moved)
  'AdjustBeamsFunctor', // page.cpp:543
  'AdjustTupletsYFunctor', // page.cpp:547
  'AdjustSlursFunctor', // page.cpp:551
  '_CurveBoxFiller', // headless replacement of the page.cpp:555-557 render pass
  'AdjustTupletWithSlursFunctor', // page.cpp:560
  'CalcBBoxOverflowsFunctor', // page.cpp:564
  'AdjustFloatingPositionersFunctor', // page.cpp:568
  'AdjustStaffOverlapFunctor', // page.cpp:572
  'AdjustYPosFunctor', // page.cpp:577
  'AdjustFloatingPositionersBetweenFunctor', // page.cpp:581
  'AdjustCrossStaffYPosFunctor', // page.cpp:584
  'AlignSystemsFunctor', // page.cpp:604
];

/// Collect the functor runs of [body] through the opt-in
/// [FunctorBase.executionTrace].
List<String> traceFunctors(void Function() body) {
  final trace = <String>[];
  final List<String>? previous = FunctorBase.executionTrace;
  FunctorBase.executionTrace = trace;
  try {
    body();
  } finally {
    FunctorBase.executionTrace = previous;
  }
  return trace;
}

/// Compare [actual] functor runs against [expected], where an expected entry
/// ending in `*` matches zero or more consecutive runs of that functor.
/// Returns an empty list when the sequences match, otherwise a description of
/// the first mismatch.
List<String> mismatchOfSequence(List<String> actual, List<String> expected) {
  int i = 0; // index into actual
  int j = 0; // index into expected
  while (j < expected.length) {
    final String pattern = expected[j];
    final bool multiple = pattern.endsWith('*');
    final String name =
        multiple ? pattern.substring(0, pattern.length - 1) : pattern;
    if (multiple) {
      // Skip zero or more consecutive runs.
      while (i < actual.length && actual[i] == name) {
        ++i;
      }
      ++j;
      continue;
    }
    if (i >= actual.length) {
      return [
        'functor "$name" (expected at position $j) did not run; '
            'trace ended after ${actual.length} runs'
      ];
    }
    if (actual[i] != name) {
      return [
        'run $i: expected "$name" (expected[$j]), got "${actual[i]}" '
            '(full actual trace: ${actual.join(" -> ")})'
      ];
    }
    ++i;
    ++j;
  }
  if (i < actual.length) {
    return [
      'unexpected extra functor runs: '
          '${actual.sublist(i).join(" -> ")}'
    ];
  }
  return [];
}

/// Expect [actual] to match [expected] (see [mismatchOfSequence]).
void expectFunctorSequence(List<String> actual, List<String> expected) {
  final mismatches = mismatchOfSequence(actual, expected);
  expect(mismatches, isEmpty, reason: mismatches.join('\n'));
}
