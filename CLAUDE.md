# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A line-by-line port of **Verovio 6.2.0** (C++ music-engraving library: MEI/MusicXML/ABC → SVG) to **pure Dart**.
The goal is *functional equivalence with the C++*, not a reimagining — when in doubt, mirror the original.

Workspace layout (a git repository since 2026-08-26; don't `git push`):

| Path | Role |
|---|---|
| `origin/src/` | Unmodified Verovio 6.2.0 C++ sources — the **reference** for every port decision (`src/*.cpp`, `include/vrv/*.h`, `libmei/dist/`). Read-only, no exceptions: the instrumentation used to extract reference data lives as patches in `cpp_probe/patches/` and never touches this tree. |
| `cpp_probe/` | The reference-data extraction machine: `sync/patch/mkpatch/build/run.sh` + versioned instrumentation patches. See `cpp_probe/README.md`. |
| `build-probe/` | The instrumented C++ tree and its binary. Git-ignored (derived); regenerate with `cpp_probe/build.sh <id>`. |
| `build/verovio` | Locally compiled C++ CLI (Release, `NO_HUMDRUM_SUPPORT=ON`) used to generate goldens and cross-check output. |
| `verovio_dart/` | The Dart package. All development happens here. |
| `PLANO.md` | Roadmap of record (Portuguese): scope decisions, phase plan, out-of-scope list. Checkboxes reconciled against the tree on 2026-08-29; they drift as soon as work lands, so re-measure before trusting them. |

Out of scope by decision: Humdrum (`humlib`, `iohumdrum`), PAE (`iopae`), and the C++ default-disabled filters (darms, cmme, volpiano, gabc).

## Commands

Run everything from `verovio_dart/` — tests and tools resolve `test/corpus`, `assets/data` relative to the package root.

```bash
dart test                                   # full suite (~7 min; 681 tests, measured 2026-08-29)
dart test test/mei_input_test.dart          # one file
dart test -n 'substring of test name'       # one test
dart analyze                                # lints (package:lints/recommended)

# Is phase N actually done? Measures every completion criterion against the tree — never against a
# checkbox or a report — and exits non-zero if any phase is open. --full regenerates the expensive
# measurements first (~20 min); --fase=N isolates one phase.
dart run tool/verify_phases.dart [--full] [--fase=N] [--verbose]

# Validation harnesses (write/refresh markdown reports)
dart run tool/compare_svg.dart --all        # Dart SVG vs the 621 C++ goldens → tool/SVG_VALIDATION.md
dart run tool/validate_layout.dart          # layout pipeline + timemap diff vs C++ → tool/LAYOUT_VALIDATION.md
dart run tool/validate_io.dart musicxml <in.musicxml> <cpp-converted.mei>   # element histogram diff
./tool/golden.sh                            # regenerate test/golden/cpp/**.svg from ../build/verovio

# Code generator (regenerate from origin/, then re-run dart analyze && dart test)
dart run tool/gen_atts.dart                 # → lib/src/model/atts/*.dart
```

> ⚠️ As of 2026-08-28 the `gen_atts.dart` output no longer byte-matches the checked-in
> `lib/src/model/atts/*.dart` (24 files differ pre-`dart format`; after the documented
> `dart format lib/src/model/atts/` step, `atts_conversion.dart` still picks up a cosmetic
> reformat and a new lint). Back up and diff before running it; see report 04i "Achados fora de
> escopo".

> `tool/gen_elements.py` was **retired on 2026-08-26** (renamed to
> `tool/gen_elements.py.obsolete`): it was a one-shot migration helper whose
> output no longer matched the hand-maintained `lib/src/model/*_gen.dart`
> files, and running it destroyed hand-written code. Those files are now
> hand-editable; there is **no** generation procedure for them. See
> `verovio_dart/prompts/reports/04i.md`.

Extracting reference data from the C++ (see `cpp_probe/README.md` and
`verovio_dart/prompts/00-MESTRE.md` section 6-bis):

```bash
# from the workspace root, not verovio_dart/
cpp_probe/sync.sh                    # origin/src -> build-probe/src (rsync, incremental)
# edit build-probe/src/src/<functor>.cpp — fprintf only, never logic
cpp_probe/mkpatch.sh <id>            # writes cpp_probe/patches/<id>.patch
cpp_probe/build.sh <id>              # sync + patch stack + incremental ninja
cpp_probe/run.sh <id> test/corpus/<x>.mei \
    verovio_dart/test/fixtures/cpp/<id>/<x>.mei.jsonl --svg /tmp/probe.svg

# the instrumented binary MUST produce byte-identical SVG to the clean one:
build/verovio -r verovio_dart/assets/data -x 12345 -o /tmp/clean.svg verovio_dart/test/corpus/<x>.mei
diff /tmp/clean.svg /tmp/probe.svg   # empty
```

Fixtures are JSON Lines, versioned under `verovio_dart/test/fixtures/cpp/<id>/`, read by
`verovio_dart/test/fixtures/cpp_fixture.dart`. Records are matched by a structural `path`, not by
`@xml:id`. The `xmlIdSeed` is pinned to `12345` — without it the ids are random per run.

Rebuilding the C++ reference binary:

```bash
cmake -S origin/src/cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DNO_HUMDRUM_SUPPORT=ON && ninja -C build
build/verovio -r verovio_dart/assets/data -o out.svg input.mei     # -t timemap / -t mei for other outputs
```

## Architecture

Pipeline, mirroring `toolkit.cpp`:

```
input bytes → format.identifyInputFrom → MeiInput / MusicXmlInput / AbcInput → Doc (Object tree)
            → Doc.prepareData (functors) → Doc/Page.layOut (align → adjust → cast off → justify,
              with View + BBoxDeviceContext filling the bounding boxes as in page.cpp:410/:532)
            → View + SvgDeviceContext → SVG string
```

The last leg is **not reachable through `Toolkit`** yet (that is Phase 7's `toolkit.cpp` port).
Today the only entry point into rendering is `renderSvgForComparison` in
`lib/src/testing/svg_compare.dart`, which the harness and the tests drive.

`lib/src/`:

- **`core/`** — `vrvdef.dart` (the `ClassId` enum, constants, units — the spine everything keys off), `bounding_box.dart` (base class of `Object`), `devicecontextbase.dart` (Pen/Brush/FontInfo/TextExtend), `options_shell.dart` (118 of the C++'s 210 options), `logging.dart`, `fraction.dart`, `smufl.dart`, `tunings.dart`, `file_reader.dart` (conditional `dart:io`/stub import so the package stays web-safe).
- **`model/`** — the MEI object tree. `object.dart` defines `class Object extends BoundingBox` plus `ObjectListInterface` and the `ObjectFactory`. Concrete elements are split between hand-written (`basic_elements.dart`, `scoredef.dart`, `doc.dart`, `text_elements.dart`, `system_page_elements.dart`, …) and generated (`*_gen.dart`). `interfaces/` holds the MEI interfaces (pitch, duration, time, position, plist, linking…). `comparison.dart` and `expansion_map.dart` port the search/expansion helpers.
- **`model/atts/`** — generated MEI attribute classes, one **mixin per `Att*` class** (`readXxx`/`writeXxx`/`copyAttXxx`), plus `mei_enums.dart`, `atts_conversion.dart` and the hand-written `mei_values.dart` runtime.
- **`io/`** — `mei_input.dart` (~5.3k lines, includes MEI 3/4/5→6 upgrades), `iomusxml.dart` (~6.5k), `ioabc.dart`, `format.dart`, and `xml_node.dart`: a **mutable** `MeiXmlNode` tree mirroring pugixml, because the readers mutate attributes while parsing and `package:xml` is immutable.
- **`layout/`** — the functor framework and the layout engine: aligners, `preparedata_functor`, `calc_*`, `adjust_*`, `cast_off*`, `justify`, `floating_positioner`, `slur_positioning`, `mensural_neume`.
- **`rendering/`** — `resources.dart` (SMuFL font/glyph loading from `assets/data`), `glyph.dart`, the three device contexts (`device_context.dart` abstract + `bbox_device_context.dart` + `svg_device_context.dart`), and the `View` (`view.dart` and one `view_*.dart` per C++ `view_*.cpp`: `page`, `element`, `control`, `beam`, `tuplet`, `slur`, `text`, `mensural`, `neume`, `tab`, `graph`). The Phase-4 stand-in `headless_extents.dart`/`bbox_fallback.dart` was deleted in task 05-30 — the layout now goes through the real `View`.
- **`testing/svg_compare.dart`** — `renderSvgForComparison` (the only path from a `.mei` path to an SVG string today) plus `SvgComparator`, shared by `tool/compare_svg.dart` and the tests. Support code for the port, not a port of any C++ file.
- **`toolkit.dart`** — public entry point; currently load-only (`loadData`/`loadFile`/`loadZipData`/`getMEI`). `getMEI()` returns the string that was loaded, not a serialized tree — `MEIOutput` is unported. Rendering and option plumbing are later phases.
- Empty and awaiting later phases: `drawing/`, `editing/`, `midi/`, `resources/`.

### Two mechanisms worth understanding before editing

**Functor dispatch.** C++ resolves functors through per-class `Accept()` virtual overrides. Dart has no double dispatch, so `layout/functor.dart` resolves it with the `kAcceptChain` table (`ClassId` → the `ClassId` whose `visitXxx` runs, for classes that don't define their own `Accept`) followed by a switch in `Functor.visit`/`visitEnd`. Default visit bodies delegate upward (`visitNote` → `visitLayerElement` → `visitObject`) exactly like `functorinterface.cpp`, so overriding `visitObject` alone sees every node. Adding an element class that lacks an `Accept()` override in C++ means adding it to `kAcceptChain`.

**Class registration.** Elements are constructed by name through `ObjectFactory`. A new element must be registered in `lib/src/factory_registry.dart` (hand-written classes, 36) or in `lib/src/model/factory_registry_gen.dart` (the rest, 91 — hand-maintained despite the name, see Conventions), and needs a `ClassId` in `core/vrvdef.dart`. Callers must run `registerModelClasses()` before parsing — every test and tool does this in `setUpAll`/`main`.

## Conventions

- **Cite the original.** Almost every class and method carries a doc comment naming its C++ counterpart ("Mirrors `Object::Process`", "Port of `functor.h`"). Keep doing this; it is how the port is reviewed.
- **Document deviations explicitly.** Where Dart forces a different shape (no `const` functors, no pointer math, mutable XML tree), say so in a `Deviations from the C++:` block rather than silently diverging.
- **Generated vs hand-maintained.** `lib/src/model/atts/*.dart` (except `mei_values.dart`) carry a `GENERATED FILE` banner and are regenerated by `tool/gen_atts.dart` — never hand-edit them, change the generator. The `lib/src/model/*_gen.dart` files used to be generated by `tool/gen_elements.py`, which was retired on 2026-08-26 (see Commands); they are now **hand-maintained** and edit them directly.
- `constant_identifier_names` is disabled in `analysis_options.yaml` so C++ identifiers can survive.
- `tool/_scratch_*.dart`, `tool/t8.dart`, `tool/dbg_c.dart` are throwaway debug scripts. They are the source of the **8 warnings that make up the `dart analyze` baseline** (re-measured 2026-08-29): 1 in `_scratch_debug.dart`, 1 in `_scratch_debug2.dart`, 1 in `_scratch_debug3.dart`, 2 in `_scratch_debug4.dart`, 2 in `_scratch_lig.dart`, 1 in `_scratch_onsets.dart`. Don't build on them and don't clean their warnings. (The 2 warnings that used to exist in `test/` were fixed in task 04i.)
- **⚠️ A green `dart analyze` does not mean the rendering code type-checks.** Measured 2026-08-29 by `dart run tool/verify_phases.dart --fase=5` (occurrence counts, not line counts): `lib/src/rendering/` holds **739 `as dynamic`** and **820 `catch (_)`** across 10 files — worst are `view_control.dart` (514 / 468) and `view_element.dart` (118 / 151); `model/` + `layout/` add another 251 / 100. Nine rendering files carry `ignore_for_file`, and `view_control.dart` suppresses the type errors themselves (`invalid_assignment`, `argument_type_not_assignable`, `unchecked_use_of_nullable_value`). Task 05-34 measured the cost: removing only the `as dynamic` from `view_control.dart` surfaced **115 type errors**, each a model member that does not exist — and the empty catches turn every one of them into a silently skipped drawing branch. This is the leading cause of whole corpus families rendering 0/N. Do not add to this pattern; when you touch one of these files, type the members you need and let the failures show.
- **Don't run `dart format` over `lib/ test/ tool/`.** The current formatter rewrites 53 untouched files and takes `dart analyze` beyond its baseline (measured 10 → 20 issues on 2026-08-27, when the baseline was 10). Format only the files you edited.

## Gotchas

- `model.Object` shadows `dart:core`'s `Object`. Files that need both import the model as `as model` or hide the name — check the existing import style in the file before adding one.
- `Resources.defaultPath` defaults to `'data'`, which is wrong for this layout. Tests and tools that need glyph metrics set `Resources.defaultPath = 'assets/data'`. Test suites that skip it print `Bravura font could not be loaded` to stderr and still pass — that noise in the test output is expected, not a regression.
- Fonts and MEI data live in `assets/data/` (not `assets/fonts/`, despite `PLANO.md`).
- The two deliberately non-UTF-8 corpus files (`test/corpus/dir/dir-011.mei`, `dir-012.mei`) were **removed from the corpus on 2026-08-30** at the user's request — being non-UTF-8 they cost more than they were worth, and no skip-lists remain. Anything dated before that (reports, measurements, prompts) speaks of 623 corpus files with 2 skipped; that is history, not the current state.
- `test/golden/cpp/**.svg` (621 files, one per corpus file — 623 before the removal) are the C++ reference output and **are** compared against now — by `tool/compare_svg.dart` and by the per-family ratchets in `test/view_*_test.dart`. State measured 2026-08-29: **115/623 structurally clean, 4/623 numerically clean (epsilon 0)**, 3 files throwing. Timemaps (`-t timemap`) and element histograms (`-t mei`) remain the secondary cross-checks.
- `test/harness_integrity_test.dart` exists because task 05-26 found the harness had been handing back the goldens themselves (489 "clean" files that were bridges). It asserts that four known-divergent files really do diverge. If you change `renderSvgForComparison`, keep that test meaningful — a suspiciously large jump in the clean count is the symptom it guards against.
