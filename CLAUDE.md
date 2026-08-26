# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A line-by-line port of **Verovio 6.2.0** (C++ music-engraving library: MEI/MusicXML/ABC → SVG) to **pure Dart**.
The goal is *functional equivalence with the C++*, not a reimagining — when in doubt, mirror the original.

Workspace layout (not a git repository):

| Path | Role |
|---|---|
| `origin/src/` | Unmodified Verovio 6.2.0 C++ sources — the **reference** for every port decision (`src/*.cpp`, `include/vrv/*.h`, `libmei/dist/`). Read-only. |
| `build/verovio` | Locally compiled C++ CLI (Release, `NO_HUMDRUM_SUPPORT=ON`) used to generate goldens and cross-check output. |
| `verovio_dart/` | The Dart package. All development happens here. |
| `PLANO.md` | Roadmap of record (Portuguese): scope decisions, phase plan, out-of-scope list. Its checkboxes **lag the code** — verify against the tree before trusting them. |

Out of scope by decision: Humdrum (`humlib`, `iohumdrum`), PAE (`iopae`), and the C++ default-disabled filters (darms, cmme, volpiano, gabc).

## Commands

Run everything from `verovio_dart/` — tests and tools resolve `test/corpus`, `assets/data` relative to the package root.

```bash
dart test                                   # full suite (~15 s, 265 tests)
dart test test/mei_input_test.dart          # one file
dart test -n 'substring of test name'       # one test
dart analyze                                # lints (package:lints/recommended)

# Validation harnesses (write/refresh markdown reports)
dart run tool/validate_layout.dart          # layout pipeline + timemap diff vs C++ → tool/LAYOUT_VALIDATION.md
dart run tool/validate_io.dart musicxml <in.musicxml> <cpp-converted.mei>   # element histogram diff
./tool/golden.sh                            # regenerate test/golden/cpp/**.svg from ../build/verovio

# Code generators (regenerate from origin/, then re-run dart analyze && dart test)
dart run tool/gen_atts.dart                 # → lib/src/model/atts/*.dart
python3 tool/gen_elements.py                # → lib/src/model/*_gen.dart + factory_registry_gen.dart
```

Rebuilding the C++ reference binary:

```bash
cmake -S origin/src/cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DNO_HUMDRUM_SUPPORT=ON && ninja -C build
build/verovio -r verovio_dart/assets/data -o out.svg input.mei     # -t timemap / -t mei for other outputs
```

## Architecture

Pipeline, mirroring `toolkit.cpp`:

```
input bytes → format.identifyInputFrom → MeiInput / MusicXmlInput / AbcInput → Doc (Object tree)
            → Doc.prepareData (functors) → Doc/Page.layOut (align → adjust → cast off → justify)
            → [Phase 5: View + SVGDeviceContext — not yet ported]
```

`lib/src/`:

- **`core/`** — `vrvdef.dart` (the `ClassId` enum, constants, units — the spine everything keys off), `bounding_box.dart` (base class of `Object`), `logging.dart`, `fraction.dart`, `smufl.dart`, `tunings.dart`, `file_reader.dart` (conditional `dart:io`/stub import so the package stays web-safe).
- **`model/`** — the MEI object tree. `object.dart` defines `class Object extends BoundingBox` plus `ObjectListInterface` and the `ObjectFactory`. Concrete elements are split between hand-written (`basic_elements.dart`, `scoredef.dart`, `doc.dart`, `text_elements.dart`, `system_page_elements.dart`, …) and generated (`*_gen.dart`). `interfaces/` holds the MEI interfaces (pitch, duration, time, position, plist, linking…). `comparison.dart` and `expansion_map.dart` port the search/expansion helpers.
- **`model/atts/`** — generated MEI attribute classes, one **mixin per `Att*` class** (`readXxx`/`writeXxx`/`copyAttXxx`), plus `mei_enums.dart`, `atts_conversion.dart` and the hand-written `mei_values.dart` runtime.
- **`io/`** — `mei_input.dart` (~5.3k lines, includes MEI 3/4/5→6 upgrades), `iomusxml.dart` (~6.5k), `ioabc.dart`, `format.dart`, and `xml_node.dart`: a **mutable** `MeiXmlNode` tree mirroring pugixml, because the readers mutate attributes while parsing and `package:xml` is immutable.
- **`layout/`** — the functor framework and the layout engine: aligners, `preparedata_functor`, `calc_*`, `adjust_*`, `cast_off*`, `justify`, `floating_positioner`, `slur_positioning`, `mensural_neume`.
- **`rendering/`** — `resources.dart` (SMuFL font/glyph loading from `assets/data`), `device_context.dart` + `bbox_device_context.dart`, and `headless_extents.dart` (a Phase-4 stand-in that fills bounding boxes and creates floating positioners without a real `View`; every divergence from the C++ drawing math is flagged with an inline `Approximation:` comment).
- **`toolkit.dart`** — public entry point; currently load-only (`loadData`/`loadFile`/`loadZipData`/`getMEI`). Rendering and option plumbing are later phases.
- Empty and awaiting later phases: `drawing/`, `editing/`, `midi/`, `resources/`.

### Two mechanisms worth understanding before editing

**Functor dispatch.** C++ resolves functors through per-class `Accept()` virtual overrides. Dart has no double dispatch, so `layout/functor.dart` resolves it with the `kAcceptChain` table (`ClassId` → the `ClassId` whose `visitXxx` runs, for classes that don't define their own `Accept`) followed by a switch in `Functor.visit`/`visitEnd`. Default visit bodies delegate upward (`visitNote` → `visitLayerElement` → `visitObject`) exactly like `functorinterface.cpp`, so overriding `visitObject` alone sees every node. Adding an element class that lacks an `Accept()` override in C++ means adding it to `kAcceptChain`.

**Class registration.** Elements are constructed by name through `ObjectFactory`. A new element must be registered in `lib/src/factory_registry.dart` (hand-written classes) or emerge from `factory_registry_gen.dart` (generated ones), and needs a `ClassId` in `core/vrvdef.dart`. Callers must run `registerModelClasses()` before parsing — every test and tool does this in `setUpAll`/`main`.

## Conventions

- **Cite the original.** Almost every class and method carries a doc comment naming its C++ counterpart ("Mirrors `Object::Process`", "Port of `functor.h`"). Keep doing this; it is how the port is reviewed.
- **Document deviations explicitly.** Where Dart forces a different shape (no `const` functors, no pointer math, mutable XML tree), say so in a `Deviations from the C++:` block rather than silently diverging.
- **Never hand-edit generated files.** `lib/src/model/atts/*.dart` (except `mei_values.dart`) and `lib/src/model/*_gen.dart` carry a `GENERATED FILE` banner — change the generator in `tool/` instead.
- `constant_identifier_names` is disabled in `analysis_options.yaml` so C++ identifiers can survive.
- `tool/_scratch_*.dart`, `tool/t8.dart`, `tool/dbg_c.dart` are throwaway debug scripts; they are the only source of `dart analyze` warnings. Don't build on them.

## Gotchas

- `model.Object` shadows `dart:core`'s `Object`. Files that need both import the model as `as model` or hide the name — check the existing import style in the file before adding one.
- `Resources.defaultPath` defaults to `'data'`, which is wrong for this layout. Tests and tools that need glyph metrics set `Resources.defaultPath = 'assets/data'`. Test suites that skip it print `Bravura font could not be loaded` to stderr and still pass — that noise in the test output is expected, not a regression.
- Fonts and MEI data live in `assets/data/` (not `assets/fonts/`, despite `PLANO.md`).
- A few corpus files are deliberately non-UTF-8 (`test/corpus/dir/dir-011.mei`, `dir-012.mei`) and are skip-listed by the layout tests.
- `test/golden/cpp/**.svg` are C++ outputs kept for Phase 5; nothing compares against them yet, since SVG rendering is unported. Current cross-checking against the C++ goes through `-t timemap` (onsets) and `-t mei` (element histograms).
