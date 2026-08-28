/// Port of `view.h` and `view.cpp` — the `View` drawing context of the MVC
/// design pattern.
///
/// Partitioning strategy (task 05-06, decision recorded for the whole Phase 5):
/// the C++ splits the `View` methods over several `view_*.cpp` files
/// (`view_graph.cpp`, `view_page.cpp`, `view_element.cpp`, ...). The faithful
/// Dart equivalent is a **library split with `part` / `part of`**: this file
/// holds the class declaration and the content of `view.cpp`; every later task
/// adds its drawing methods in a `part` file of this library
/// (`view_graph.dart`, `view_page.dart`, ...). An `extension` cannot add
/// fields and cannot reach the library-private state (`_currentOffsets`),
/// while a `part` shares the library privacy — exactly like a C++ member
/// declared in `view.h` is visible from every `view_*.cpp`. The task registers
/// the decision here; the `part` directives themselves are added as the files
/// appear.
///
/// Deviations from the C++:
/// - `View` is used through pointers in the C++ (`Doc *`, `Page *`,
///   `DeviceContext *`); Dart has no pointers, so the object references are
///   nullable where the C++ pointer can be NULL.
/// - the private methods of `view.cpp` (`StartOffset`, `EndOffset`,
///   `SetOffsetStaffSize`, `CalcOffset*`, `IntTo*Figures`; view.h:605-672)
///   are public here so tests can exercise the arithmetic directly (same
///   pattern as `BBoxDeviceContext.getPenWidthOverlap`, task 05-05).
/// - the private nested class `View::Offset` (view.h:677-687) becomes the
///   library-private `_Offset` below: Dart has no nested classes, and
///   library-private is visible to the future `part` files of this library,
///   like the C++ private member is visible to every `view_*.cpp`.
/// - `m_doc`, `m_options`, `m_currentPage` (public) and `m_currentColor`,
///   `m_slurHandling`, `m_drawingScoreDef` (protected; view.h:691-721) are
///   plain public fields — Dart has no protected section.
/// - the drawing methods of the other `view_*.cpp` files are declared in the
///   `part` files of this library, but Dart cannot split a class body across
///   files: each `part` file declares the methods as members of an
///   `extension View* on View`. Extensions declared in the same library do
///   reach the library-private state (`_currentOffsets`, `_Offset`) and are
///   resolved statically, which is equivalent here because `vrv::View` has
///   no virtual drawing methods and is never subclassed.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart'
    show FontStyle, HorizontalAlignment, meiUnset;
import 'package:verovio_dart/src/core/bounding_box.dart'
    show BoundingBox, SegmentedLine;
import 'package:verovio_dart/src/core/devicecontextbase.dart'
    show FontInfo, PenStyle, TextExtend, colorNone;
import 'package:verovio_dart/src/core/logging.dart' show logDebug;
import 'package:verovio_dart/src/core/options_shell.dart'
    show Options, SystemDivider, tempKeysigStep;
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/smufl.dart'
    show
        smuflE000Brace,
        smuflE003BracketTop,
        smuflE004BracketBottom,
        smuflE044RepeatDot,
        smuflE04ASegnoSerpent1,
        smuflE050Gclef,
        smuflE08CTimeSigPlus,
        smuflE262AccidentalSharp;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show FloatingPositioner;
import 'package:verovio_dart/src/model/beam_segment.dart' show BeamSpanSegment;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show BarLine, BarlinePosition, Layer, Measure, Ossia, Staff;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Barrendition, Barmethod, MetersiggrplogFunc, StaffgroupingsymSymbol;
import 'package:verovio_dart/src/model/comparison.dart'
    show AttNIntegerComparison;
import 'package:verovio_dart/src/model/control_element.dart'
    show ControlElement;
import 'package:verovio_dart/src/model/control_elements_gen.dart'
    show BeamSpan, MNum, Reh;
import 'package:verovio_dart/src/model/doc.dart' show Doc, Page;
import 'package:verovio_dart/src/model/editorial_element.dart'
    show Annot, EditorialElement;
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart'
    show OffsetInterface, OffsetSpanningInterface;
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show KeySig, MeterSig, MeterSigGrp;
import 'package:verovio_dart/src/model/misc_elements_gen.dart'
    show Div, Ending, Fig, Graphic, GrpSym, Label, LabelAbbr, Svg, SymbolDef;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart'
    show LayerDef, ScoreDef, StaffDef, StaffGrp;
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show PageElement, PageMilestoneEnd, System, SystemElement;
import 'package:verovio_dart/src/model/text_elements.dart'
    show TextDrawingParams, TextElement;
import 'package:verovio_dart/src/rendering/device_context.dart';
import 'package:verovio_dart/src/rendering/resources.dart' show Resources;

part 'view_graph.dart';
part 'view_page.dart';

/// Internal class for storing current offset values
/// (mirrors the private nested `View::Offset`, view.h:677-687).
class _Offset {
  int ho = 0;
  int vo = 0;
  int startho = 0;
  int startvo = 0;
  int endho = 0;
  int endvo = 0;
  Object? object;
  int staffSize = 100;
}

/// This class is a drawing context and corresponds to the view of a MVC
/// design pattern (mirrors `vrv::View`, view.h:107).
class View {
  /// Mirrors `View::View` (view.cpp:28-35).
  View() {
    doc = null;
    options = null;
    slurHandling = SlurHandling.initialize;

    currentColor = colorNone;
  }

  /// Document (mirrors `m_doc`, view.h:691).
  Doc? doc;

  /// Options of the document (mirrors `m_options`, view.h:693).
  Options? options;

  /// The page currently being drawn (mirrors `m_currentPage`, view.h:701).
  Page? currentPage;

  /// The color currently being used when drawing. It can change when drawing
  /// the current element, for example (mirrors `m_currentColor`,
  /// view.h:709).
  int currentColor = colorNone;

  /// Controls the handling of slurs (mirrors `m_slurHandling`, view.h:714;
  /// the inline `GetSlurHandling` / `SetSlurHandling` accessors become the
  /// plain field).
  SlurHandling slurHandling = SlurHandling.initialize;

  /// The current drawing score def. It is set when starting to draw a page in
  /// `DrawCurrentPage` and then modified appropriately when going through the
  /// page (mirrors `m_drawingScoreDef`, view.h:721).
  ///
  /// Deviations from the C++:
  /// - `m_drawingScoreDef` is an embedded `ScoreDef` **object** — a copy, not
  ///   a reference (view.h:721). Dart only has references, so the field owns
  ///   its own instance and the drawing code must copy the current state in
  ///   (e.g., with `copyFrom`), never assign it by reference. Same pattern as
  ///   `Page.drawingScoreDef` (doc.dart).
  final ScoreDef drawingScoreDef = ScoreDef();

  /// The list of current offset values for the element being drawn (mirrors
  /// `m_currentOffsets`, view.h:735).
  ///
  /// The C++ uses a `std::list` kept as a stack: [startOffset] pushes to the
  /// front and [endOffset] pops the front, but the `calcOffsetSpanning*`
  /// methods walk the **whole** list, not only the top. A Dart `List` gives
  /// both behaviors (`insert(0, ...)` for `push_front`, plain iteration for
  /// the walk).
  final List<_Offset> _currentOffsets = [];

  /// Set the document the view is pointing to (mandatory). Several views can
  /// point to the same document (mirrors `View::SetDoc`, view.cpp:39).
  void setDoc(Doc? doc) {
    // Unset the doc
    if (doc == null) {
      this.doc = null;
      options = null;
    } else {
      this.doc = doc;
      options = doc.getOptions();
    }
    currentPage = null;
  }

  /// Set the current page (mirrors `View::SetPage`, view.cpp:53).
  ///
  /// If [doLayout] is true, the layout of the page will be calculated. This is
  /// the default behavior, however, in some cases, we do not want it. For
  /// example, when drawing the pages for getting the bounding boxes — the C++
  /// comments "Do not do the layout in this view - otherwise we will loop..."
  /// (page.cpp:241).
  ///
  /// Deviations from the C++:
  /// - the `assert(page)` of the C++ is subsumed by the non-nullable
  ///   parameter type.
  /// - `Page::LayOutTranscription` is not ported yet (its C++ body ends with
  ///   a BBoxDeviceContext render pass that loops back into a View,
  ///   page.cpp:296-306); the transcription / facsimile branch falls back to
  ///   `layOut()`, which is a no-op once the layout is done.
  void setPage(Page page, bool doLayout) {
    currentPage = page;

    if (doLayout) {
      doc!.scoreDefSetCurrentDoc();
      // if we once deal with multiple views, it would be better
      // to redo the layout only when necessary?
      if (doc!.isTranscription() || doc!.isFacs()) {
        currentPage!.layOut();
      } else {
        currentPage!.layOut();
      }
    }
  }

  /// Mirrors `View::ToDeviceContextX` (view.cpp:72) — the same.
  int toDeviceContextX(int i) {
    return i;
  }

  /// x value in the Logical world (mirrors `View::ToLogicalX`, view.cpp:78).
  int toLogicalX(int i) {
    return i;
  }

  /// y value in the View (mirrors `View::ToDeviceContextY`, view.cpp:84).
  ///
  /// Y coordinates are from bottom to top in the logical world and from top
  /// to bottom in the device context world (view.h:127-131): both methods
  /// flip around `m_drawingPageContentHeight`, so each of them is its own
  /// inverse — the pair is not a trivial identity but an involution.
  int toDeviceContextY(int i) {
    if (doc == null) {
      return 0;
    }

    return doc!.drawingPageContentHeight - i; // flipped
  }

  /// y value in the Logical world (mirrors `View::ToLogicalY`, view.cpp:94).
  int toLogicalY(int i) {
    if (doc == null) {
      return 0;
    }

    return doc!.drawingPageContentHeight - i; // flipped
  }

  /// Mirrors `View::ToDeviceContext` (view.cpp:103).
  Point toDeviceContext(Point p) {
    return Point(toDeviceContextX(p.x), toDeviceContextY(p.y));
  }

  /// Mirrors `View::ToLogical` (view.cpp:108).
  Point toLogical(Point p) {
    return Point(toLogicalX(p.x), toLogicalY(p.y));
  }

  /// Mirrors `View::IntToTupletFigures` (view.cpp:113).
  String intToTupletFigures(int number) {
    return intToSmuflFigures(number, 0xE880);
  }

  /// Mirrors `View::IntToTimeSigFigures` (view.cpp:118).
  String intToTimeSigFigures(int number) {
    return intToSmuflFigures(number, 0xE080);
  }

  /// Mirrors `View::IntToSmuflFigures` (view.cpp:123) — converts [number]
  /// into a string of SMuFL digit glyphs starting at code point [offset].
  ///
  /// Deviations from the C++:
  /// - the C++ builds a `std::u32string` (one char per code point); Dart
  ///   strings are UTF-16, so the SMuFL digits (>= 0xE080) come out as
  ///   surrogate pairs. The code points are identical (compare with
  ///   `.runes`).
  /// - `number` is `unsigned short` in the C++; a plain `int` here.
  String intToSmuflFigures(int number, int offset) {
    final String str = number.toString();

    return String.fromCharCodes(str.runes.map((int c) => c + offset - 48));
  }

  /// Start and end offset calculation for elements with `@ho` or `@vo`.
  /// Offset will be applied only if required by the DeviceContext. The staff
  /// size can be changed when it does for a particular element (e.g., control
  /// elements) (mirrors `View::StartOffset`, view.cpp:135).
  ///
  /// Deviations from the C++:
  /// - `object->GetOffsetInterface()` can return NULL in the C++ (hence the
  ///   `assert(interface)`); [Object.hasInterface] already guarantees the
  ///   cast below succeeds.
  void startOffset(DeviceContext dc, Object object, int staffSize) {
    if (!dc.applyOffset()) return;

    final int unit = doc!.getOptions().unit.value.toInt();

    final _Offset offset = _Offset();

    if (object.hasInterface(InterfaceId.offset)) {
      final OffsetInterface interface = object as OffsetInterface;

      if (interface.hasHo || interface.hasVo) {
        offset.ho = (interface.hasHo) ? (interface.ho!.vu * unit).toInt() : 0;
        offset.vo = (interface.hasVo) ? (interface.vo!.vu * unit).toInt() : 0;
        offset.object = object;
        offset.staffSize = staffSize;
      }
    }

    if (object.hasInterface(InterfaceId.offsetSpanning)) {
      final OffsetSpanningInterface interface =
          object as OffsetSpanningInterface;

      if (interface.hasStartho ||
          interface.hasStartvo ||
          interface.hasEndho ||
          interface.hasEndvo) {
        offset.startho =
            (interface.hasStartho) ? (interface.startho!.vu * unit).toInt() : 0;
        offset.startvo =
            (interface.hasStartvo) ? (interface.startvo!.vu * unit).toInt() : 0;
        offset.endho =
            (interface.hasEndho) ? (interface.endho!.vu * unit).toInt() : 0;
        offset.endvo =
            (interface.hasEndvo) ? (interface.endvo!.vu * unit).toInt() : 0;
        offset.object = object;
        offset.staffSize = staffSize;
      }
    }

    // This means we have at least one offset value
    if (offset.object != null) _currentOffsets.insert(0, offset);
  }

  /// Mirrors `View::EndOffset` (view.cpp:173).
  void endOffset(DeviceContext dc, Object object) {
    if (!dc.applyOffset() || _currentOffsets.isEmpty) return;

    if (identical(_currentOffsets.first.object, object)) {
      _currentOffsets.removeAt(0);
    }
  }

  /// Mirrors `View::SetOffsetStaffSize` (view.cpp:180).
  void setOffsetStaffSize(Object object, int staffSize) {
    if (_currentOffsets.isEmpty) return;

    if (identical(_currentOffsets.first.object, object)) {
      _currentOffsets.first.staffSize = staffSize;
    }
  }

  /// Calculate the current offset for a point. Applies current offsets
  /// recursively (e.g., accid within note) (mirrors `View::CalcOffset`,
  /// view.cpp:187).
  ///
  /// Deviations from the C++:
  /// - the `int &x, int &y` reference parameters become arguments plus a
  ///   returned `(x, y)` record; call sites assign the result back.
  (int, int) calcOffset(DeviceContext dc, int x, int y) {
    if (!dc.applyOffset() || _currentOffsets.isEmpty) return (x, y);

    for (final _Offset offset in _currentOffsets) {
      x = x + offset.ho * offset.staffSize ~/ 100;
      y = y + offset.vo * offset.staffSize ~/ 100;
    }
    return (x, y);
  }

  /// Mirrors `View::CalcOffsetX` (view.cpp:197).
  int calcOffsetX(DeviceContext dc, int x) {
    if (!dc.applyOffset() || _currentOffsets.isEmpty) return x;

    for (final _Offset offset in _currentOffsets) {
      x = x + offset.ho * offset.staffSize ~/ 100;
    }
    return x;
  }

  /// Mirrors `View::CalcOffsetY` (view.cpp:206).
  int calcOffsetY(DeviceContext dc, int y) {
    if (!dc.applyOffset() || _currentOffsets.isEmpty) return y;

    for (final _Offset offset in _currentOffsets) {
      y = y + offset.vo * offset.staffSize ~/ 100;
    }
    return y;
  }

  /// Mirrors `View::CalcOffsetSpanningStartX` (view.cpp:215).
  int calcOffsetSpanningStartX(DeviceContext dc, int x, int spanningType,
      [double factor = 1.0]) {
    if (!dc.applyOffset() || _currentOffsets.isEmpty) return x;

    for (final _Offset offset in _currentOffsets) {
      if (spanningType == spanningStartEnd) {
        x = (x + offset.startho * offset.staffSize ~/ 100 * factor).toInt();
      } else if (spanningType == spanningStart) {
        x = (x + offset.startho * offset.staffSize ~/ 100 * factor).toInt();
      }
    }
    return x;
  }

  /// Mirrors `View::CalcOffsetSpanningEndX` (view.cpp:229).
  int calcOffsetSpanningEndX(DeviceContext dc, int x, int spanningType,
      [double factor = 1.0]) {
    if (!dc.applyOffset() || _currentOffsets.isEmpty) return x;

    for (final _Offset offset in _currentOffsets) {
      if (spanningType == spanningStartEnd) {
        x = (x + offset.endho * offset.staffSize ~/ 100 * factor).toInt();
      } else if (spanningType == spanningEnd) {
        x = (x + offset.endho * offset.staffSize ~/ 100 * factor).toInt();
      }
    }
    return x;
  }

  /// Mirrors `View::CalcOffsetSpanningStartY` (view.cpp:243).
  int calcOffsetSpanningStartY(DeviceContext dc, int y, int spanningType,
      [double factor = 1.0]) {
    if (!dc.applyOffset() || _currentOffsets.isEmpty) return y;

    for (final _Offset offset in _currentOffsets) {
      if (spanningType == spanningStartEnd) {
        y = (y + offset.startvo * offset.staffSize ~/ 100 * factor).toInt();
      } else if (spanningType == spanningStart) {
        y = (y + offset.startvo * offset.staffSize ~/ 100 * factor).toInt();
      } else if (spanningType == spanningEnd) {
        y = (y +
                (offset.startvo + offset.endvo) ~/
                    2 *
                    offset.staffSize ~/
                    100 *
                    factor)
            .toInt();
      } else {
        final int diff = (offset.startvo - offset.endvo) ~/ 2;
        y = (y +
                ((offset.startvo + offset.endvo) ~/ 2 + diff) *
                    offset.staffSize ~/
                    100 *
                    factor)
            .toInt();
      }
    }
    return y;
  }

  /// Mirrors `View::CalcOffsetSpanningEndY` (view.cpp:264).
  int calcOffsetSpanningEndY(DeviceContext dc, int y, int spanningType,
      [double factor = 1.0]) {
    if (!dc.applyOffset() || _currentOffsets.isEmpty) return y;

    for (final _Offset offset in _currentOffsets) {
      if (spanningType == spanningStartEnd) {
        y = (y + offset.endvo * offset.staffSize ~/ 100 * factor).toInt();
      } else if (spanningType == spanningStart) {
        y = (y +
                (offset.endvo + offset.startvo) ~/
                    2 *
                    offset.staffSize ~/
                    100 *
                    factor)
            .toInt();
      } else if (spanningType == spanningEnd) {
        y = (y + offset.endvo * offset.staffSize ~/ 100 * factor).toInt();
      } else {
        final int diff = (offset.endvo - offset.startvo) ~/ 2;
        y = (y +
                ((offset.startvo + offset.endvo) ~/ 2 + diff) *
                    offset.staffSize ~/
                    100 *
                    factor)
            .toInt();
      }
    }
    return y;
  }

  /// Mirrors `View::CalcOffsetBezier` (view.cpp:285) — adjusts the four
  /// points of a bezier (end points and control points, `points[0]` is the
  /// start, `points[3]` the end) for the offsets currently on the stack.
  ///
  /// Deviations from the C++:
  /// - `Point points[4]` becomes a `List<Point>` of four points; the elements
  ///   are mutated in place (Dart `Point` has mutable fields), which keeps
  ///   the reference semantics of the array parameter.
  void calcOffsetBezier(
      DeviceContext dc, List<Point> points, int spanningType) {
    if (!dc.applyOffset() || _currentOffsets.isEmpty) return;

    final double diff = (points[3].x - points[0].x).toDouble();
    // factor for start control point
    final double factorStart =
        (diff != 0.0) ? (points[3].x - points[1].x) / diff : 1.0;
    // factor for end control point
    final double factorEnd =
        (diff != 0.0) ? (points[2].x - points[0].x) / diff : 1.0;

    // Adjust the start point y
    points[0].y = calcOffsetSpanningStartY(dc, points[0].y, spanningType);
    // Adjust the start (first) control point y considering both the startho
    // and endho - use opposite factor for endho
    points[1].y =
        calcOffsetSpanningStartY(dc, points[1].y, spanningType, factorStart);
    points[1].y = calcOffsetSpanningEndY(
        dc, points[1].y, spanningType, (1.0 - factorStart).abs());
    // Adjust the end (second) control point y
    points[2].y = calcOffsetSpanningStartY(
        dc, points[2].y, spanningType, (1.0 - factorEnd).abs());
    points[2].y =
        calcOffsetSpanningEndY(dc, points[2].y, spanningType, factorEnd);
    // Adjust the end point y
    points[3].y = calcOffsetSpanningEndY(dc, points[3].y, spanningType);

    // Adjust the x
    points[0].x = calcOffsetSpanningStartX(dc, points[0].x, spanningType);
    points[1].x =
        calcOffsetSpanningStartX(dc, points[1].x, spanningType, factorStart);
    points[1].x = calcOffsetSpanningEndX(
        dc, points[1].x, spanningType, (1.0 - factorStart).abs());
    points[2].x = calcOffsetSpanningStartX(
        dc, points[2].x, spanningType, (1.0 - factorEnd).abs());
    points[2].x =
        calcOffsetSpanningEndX(dc, points[2].x, spanningType, factorEnd);
    points[3].x = calcOffsetSpanningEndX(dc, points[3].x, spanningType);

    // Adjust considering ho and vo
    if (spanningType == spanningStartEnd) {
      for (int i = 0; i < 4; i++) {
        final (x, y) = calcOffset(dc, points[i].x, points[i].y);
        points[i].x = x;
        points[i].y = y;
      }
    }
    // Do not apply the horizontal offset for system start or end points
    else if (spanningType == spanningStart) {
      // Adjust end points (could be improved with a factor for the control point)
      for (int i = 2; i < 4; i++) {
        final (x, y) = calcOffset(dc, points[i].x, points[i].y);
        points[i].x = x;
        points[i].y = y;
      }
      // Vertical offset still does need to be applied
      points[0].y = calcOffsetY(dc, points[0].y);
      points[1].y = calcOffsetY(dc, points[1].y);
    } else if (spanningType == spanningEnd) {
      // Adjust start points
      for (int i = 0; i < 2; i++) {
        final (x, y) = calcOffset(dc, points[i].x, points[i].y);
        points[i].x = x;
        points[i].y = y;
      }
      // Vertical offset for end points
      points[2].y = calcOffsetY(dc, points[2].y);
      points[3].y = calcOffsetY(dc, points[3].y);
    }
    // Middle, only vertical offset
    else {
      points[0].y = calcOffsetY(dc, points[0].y);
      points[1].y = calcOffsetY(dc, points[1].y);
      points[2].y = calcOffsetY(dc, points[2].y);
      points[3].y = calcOffsetY(dc, points[3].y);
    }
  }
}
