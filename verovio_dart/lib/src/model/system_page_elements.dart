/// Port of `systemelement.h` and `pageelement.h` — the base classes for
/// system-level and page-level elements, plus the milestone end objects.
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment, SystemAligner;
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show CurvatureCurvedir, Stemdirection;
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show MeasurementType;
import 'package:verovio_dart/src/model/basic_elements.dart' show Staff;
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/drawing_interfaces.dart';
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart'
    show Dir, Dynam, Pedal, Tempo, Trill;
import 'package:verovio_dart/src/model/doc.dart' show Page;
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef;

/// Mirrors `vrv::SystemElement`: base class for system elements (section,
/// ending, pb, sb, expansion…).
class SystemElement extends FloatingObject
    with AttTyped, VisibilityDrawingInterface {
  SystemElement([ClassId classId = ClassId.systemElement]) {
    _init(classId);
  }

  void _init(ClassId classId) {
    assignClassId(classId);
    reset();
  }

  @override
  String get className => '[MISSING]';

  @override
  void reset() {
    super.reset();
    // The C++ stores an m_visibility optimization flag; layout functors set
    // it during casting. Kept as a simple field until then.
    visibilityOptimization = VisibilityOptimization.none;
    type = null;
    visibility = VisibilityType.visible;
  }

  VisibilityOptimization visibilityOptimization = VisibilityOptimization.none;

  @override
  bool isSupportedChild(ClassId classId) {
    logDebug('Method for adding $classId to $className should be overridden');
    return false;
  }
}

/// Mirrors `vrv::PageElement`: base class for page elements (mdiv, score…).
class PageElement extends Object with AttTyped {
  PageElement([ClassId classId = ClassId.pageElement]) {
    _init(classId);
  }

  void _init(ClassId classId) {
    assignClassId(classId);
    reset();
  }

  @override
  String get className => '[MISSING]';

  @override
  void reset() {
    super.reset();
    type = null;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    logDebug('Method for adding $classId to $className should be overridden');
    return false;
  }
}

/// Mirrors `vrv::System`: a page-based system containing measures.
///
/// The vertical aligner and the drawing list arrive with the layout phase
/// (Phase 4); this port carries the state needed by the IO (margins, facs
/// coordinates) and the drawing scoreDef.
class System extends SystemElement with DrawingListInterface {
  System() : super(ClassId.system) {
    reset();
  }

  /// The left margin (MEI @system.leftmar; mirrors `m_systemLeftMar`).
  int systemLeftMar = 0;

  /// The right margin (MEI @system.rightmar; mirrors `m_systemRightMar`).
  int systemRightMar = 0;

  /// The system x position relative to the page, set by the horizontal
  /// layout (mirrors `m_drawingXRel`).
  int _drawingXRel = 0;

  /// The system y position relative to the page, set by the vertical layout
  /// (mirrors `m_drawingYRel`).
  int _drawingYRel = 0;

  /// The total width of the system, set by AlignMeasuresFunctor (mirrors
  /// `m_drawingTotalWidth`).
  int drawingTotalWidth = 0;

  /// The justifiable width of the system, set by AlignMeasuresFunctor
  /// (mirrors `m_drawingJustifiableWidth`).
  int drawingJustifiableWidth = 0;

  /// The total width of the system stored at cast-off time (mirrors
  /// `m_castOffTotalWidth`; used by System::EstimateJustificationRatio).
  int castOffTotalWidth = 0;

  /// The justifiable width of the system stored at cast-off time (mirrors
  /// `m_castOffJustifiableWidth`).
  int castOffJustifiableWidth = 0;

  /// Facsimile X position (mirrors `m_drawingFacsX`).
  int drawingFacsX = meiUnset;

  /// Facsimile Y position (MEI @uly; mirrors `m_drawingFacsY`).
  int drawingFacsY = meiUnset;

  /// The top scoreDef of the system (mirrors `m_drawingScoreDef`); owned.
  ScoreDef? drawingScoreDef;

  /// Whether the scoreDef of the system was optimized (condensed; mirrors
  /// `m_drawingIsOptimized` / `IsDrawingOptimized`).
  bool drawingIsOptimized = false;

  /// The system aligner that holds the y positions of the staves of the
  /// system (mirrors the public `m_systemAligner`).
  final SystemAligner systemAligner = SystemAligner();

  @override
  ClassId get classId => ClassId.system;

  @override
  String get className => 'system';

  @override
  Object clone() {
    final copy = System();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    // Mirrors `System::Reset` calling `DrawingListInterface::Reset`
    // (system.cpp:70 / drawinginterface.cpp:39).
    resetDrawingList();
    type = null;
    visibility = VisibilityType.visible;
    systemLeftMar = 0;
    systemRightMar = 0;
    drawingFacsX = meiUnset;
    drawingFacsY = meiUnset;
    drawingIsOptimized = false;
    resetDrawingAbbrLabelsWidth();
    resetDrawingScoreDef();
    // Mirrors `System::Reset`: the system aligner needs its parent so that
    // the ancestor lookups of the StaffAlignments resolve.
    if (systemAligner.parent == null) {
      systemAligner.setParent(this);
    }
  }

  /// Mirrors `System::SetDrawingScoreDef` / `ResetDrawingScoreDef`
  /// (system.cpp:215). C++ clones the ScoreDef and sets its parent to the
  /// System, which is required for the structural probe path
  /// `system/scoreDef[?]/staffGrp/...` to include the `pages/page/system`
  /// ancestors (vrvprobe.h:221, test/fixtures/cpp_fixture.dart:88).
  void setDrawingScoreDef(ScoreDef? drawingScoreDef) {
    if (drawingScoreDef == null) {
      this.drawingScoreDef = null;
      return;
    }
    assert(this.drawingScoreDef == null);
    final ScoreDef copy = ScoreDef();
    copy.replaceWithCopyOf(drawingScoreDef);
    copy.setParent(this);
    this.drawingScoreDef = copy;
  }

  void resetDrawingScoreDef() {
    drawingScoreDef = null;
  }

  /// Mirrors `SetDrawingXRel` / `GetDrawingXRel`.
  void setDrawingXRel(int drawingXRel) {
    resetCachedDrawingX();
    _drawingXRel = drawingXRel;
  }

  int getDrawingXRel() => _drawingXRel;

  /// Mirrors `System::SetDrawingYRel` / `GetDrawingYRel`.
  void setDrawingYRel(int drawingYRel) {
    resetCachedDrawingY();
    _drawingYRel = drawingYRel;
  }

  int getDrawingYRel() => _drawingYRel;

  /// Mirrors `System::GetDrawingY`: the layout y position (the view flips
  /// the y axis when rendering; the layout origin is the bottom of the
  /// page content area).
  @override
  int getDrawingY() => _drawingYRel;

  /// Mirrors `System::GetHeight`: the height of the system from its aligner.
  int getHeight() {
    final StaffAlignment? bottom = systemAligner.getBottomAlignment();
    if (bottom != null) return -bottom.getYRel();
    return 0;
  }

  /// Mirrors `System::IsFirstInPage`.
  bool isFirstInPage() {
    assert(parent != null);
    return identical(parent?.getFirst(ClassId.system), this);
  }

  /// Mirrors `System::IsFirstOfMdiv` (system.cpp:397): true when the
  /// previous sibling of the system's page is a page element (e.g., a score
  /// milestone start).
  bool isFirstOfMdiv() {
    assert(parent != null);
    final Object? previousSibling = parent!.getPreviousSibling(this);
    return previousSibling != null &&
        Object.isPageElementId(previousSibling.classId);
  }

  /// Return the top (first) visible staff in the system, if any; takes into
  /// account system optimization (mirrors `System::GetTopVisibleStaff`,
  /// system.cpp:148).
  ///
  /// An ossia staff is returned only when [includeOssia] is set and the ossia
  /// is on the first measure of the system.
  Staff? getTopVisibleStaff(bool includeOssia) {
    for (final Object child in systemAligner.children) {
      final StaffAlignment alignment = child as StaffAlignment;
      final Staff? staff = alignment.getStaff();
      if (staff == null) continue;
      if (!staff.isOssia()) return staff;
      if (!includeOssia) continue;
      // Return the ossia staff only if requested and the ossia in on the
      // first measure
      if (identical(staff.getFirstAncestor(ClassId.measure),
          findDescendantByType(ClassId.measure))) {
        return staff;
      }
    }
    return null;
  }

  /// Mirrors `System::IsLastInPage`.
  bool isLastInPage() {
    assert(parent != null);
    return identical(parent?.getLast(ClassId.system), this);
  }

  /// Mirrors `System::IsLastOfMdiv`: true when the next sibling of the
  /// system's page is a page element (e.g., a score milestone end).
  bool isLastOfMdiv() {
    assert(parent != null);
    final Object? nextSibling = parent!.getNextSibling(this);
    return nextSibling != null && Object.isPageElementId(nextSibling.classId);
  }

  /// Mirrors `System::HasMixedDrawingStemDir` (system.cpp:232).
  ///
  /// Collects the chord/note children between [start] and [end] — the only
  /// measure when both sit in it, otherwise every measure in between found
  /// by ancestor traversal — restricted to the start staff/layer, and
  /// answers whether their drawing stem directions disagree.
  ///
  /// Deviation: `FindAllBetweenFunctor` / `FindAllDescendantsBetween` (which
  /// need a functor pipeline run over `System::Process`) are replaced by a
  /// flat descendant scan of each measure filtered by traversal order
  /// (same-measure bounds are subtree checks; cross-measure bounds use the
  /// measure `index` order).
  bool hasMixedDrawingStemDir(LayerElement start, LayerElement end) {
    final Object? measureStart =
        start.getFirstAncestor(ClassId.measure);
    final Object? measureEnd = end.getFirstAncestor(ClassId.measure);
    if (measureStart == null || measureEnd == null) return false;

    final List<Object> measures = [];
    if (identical(measureStart, measureEnd)) {
      measures.add(measureStart);
    } else {
      // Otherwise look for measures in between (system.cpp:250): walk the
      // system's direct measure children in index order between the two.
      final Object? system = getFirstAncestor(ClassId.system) ??
          measureStart.getFirstAncestor(ClassId.system);
      final List<Object> allMeasures = system != null
          ? system.findAllDescendantsByType(ClassId.measure, deepness: 1)
          : [measureStart, measureEnd];
      bool inside = false;
      for (final Object measure in allMeasures) {
        if (identical(measure, measureStart) ||
            identical(measure, measureEnd)) {
          if (!inside) {
            measures.add(measure);
            inside = true;
            if (identical(measureStart, measureEnd)) break;
            continue;
          } else {
            measures.add(measure);
            break;
          }
        }
        if (inside) measures.add(measure);
      }
      if (measures.isEmpty) {
        measures.add(measureStart);
        if (!identical(measureStart, measureEnd)) measures.add(measureEnd);
      }
    }

    // Now look for chords and notes (system.cpp:257).
    final List<Object> children = [];
    for (final Object measure in measures) {
      final Object curStart =
          identical(measure, measureStart) ? start : measure.getFirst()!;
      final Object curEnd =
          identical(measure, measureEnd) ? end : measure.getLast()!;
      children.addAll(_descendantsBetween(
          measure, const {ClassId.chord, ClassId.note}, curStart, curEnd));
    }

    final Object? layerStart = start.getFirstAncestor(ClassId.layer);
    if (layerStart == null) return false;
    final Object? staffStartObj = layerStart.getFirstAncestor(ClassId.staff);
    if (staffStartObj == null || staffStartObj is! Staff) return false;
    final Staff staffStart = staffStartObj;
    final int layerStartN = (layerStart as AttNInteger).n ?? meiUnset;

    Stemdirection stemDir = Stemdirection.none;
    for (final Object child in children) {
      final Object? layer = child.getFirstAncestor(ClassId.layer);
      final Object? staffObj = child.getFirstAncestor(ClassId.staff);
      if (layer == null || staffObj == null || staffObj is! Staff) continue;

      // Skip notes/chords from other staves and layers (system.cpp:282).
      if ((staffObj.n != staffStart.n) ||
          ((layer as AttNInteger).n != layerStartN)) {
        continue;
      }

      final StemmedDrawingInterface? interface =
          (child as LayerElement).getStemmedDrawingInterface();
      if (interface == null) continue;

      // First pass.
      if (stemDir == Stemdirection.none) {
        stemDir = interface.getDrawingStemDir();
      } else if (stemDir != interface.getDrawingStemDir()) {
        return true;
      }
    }

    return false;
  }

  /// Flat-subtree equivalent of `Measure::FindAllDescendantsBetween` for
  /// the same-/cross-measure collection above: descendants of [container]
  /// matching [classIds] between [start] and [end] in document order.
  static List<Object> _descendantsBetween(Object container,
      Set<ClassId> classIds, Object start, Object end) {
    final List<Object> flat = [];
    container.fillFlatList(flat);
    int startIdx = flat.indexOf(start);
    int endIdx = flat.indexOf(end);
    // Same-measure chord/note bounds (`curStart`/`curEnd` above) are the
    // boundary elements themselves, not their positions in the flat list:
    // fall back to subtree containment.
    if (startIdx == -1 || endIdx == -1) {
      return flat
          .where((Object o) =>
              classIds.contains(o.classId) &&
              _isDescendantOfOrSelf(start, o, container, true) &&
              _isDescendantOfOrSelf(end, o, container, false))
          .toList();
    }
    if (startIdx > endIdx) {
      final int tmp = startIdx;
      startIdx = endIdx;
      endIdx = tmp;
    }
    return flat
        .sublist(startIdx, endIdx + 1)
        .where((Object o) => classIds.contains(o.classId))
        .toList();
  }

  /// True when [bound] is inside [candidate]'s subtree ([after] selects
  /// whether [candidate] must come after [bound] rather than before).
  static bool _isDescendantOfOrSelf(
      Object bound, Object candidate, Object container, bool after) {
    final List<Object> flat = [];
    container.fillFlatList(flat);
    final int boundIdx = flat.indexOf(bound);
    final int candIdx = flat.indexOf(candidate);
    if (boundIdx == -1 || candIdx == -1) return after ? true : true;
    return after ? candIdx >= boundIdx : candIdx <= boundIdx;
  }

  /// Mirrors `System::GetPreferredCurveDirection` (system.cpp:301).
  ///
  /// Collects chord/note elements spanned by the slur x-range; the first
  /// off-layer element decides the preference (above when its layer `@n` is
  /// greater, below when smaller); layers on both sides cancel to none.
  CurvatureCurvedir getPreferredCurveDirection(
      LayerElement start, LayerElement end, Object slur) {
    final Object? layerStart = start.getFirstAncestor(ClassId.layer);
    if (layerStart == null) return CurvatureCurvedir.none;
    final int layerStartN = (layerStart as AttNInteger).n ?? meiUnset;

    final int xMin = start.getDrawingX();
    final int xMax = end.getDrawingX();
    final int lo = xMin < xMax ? xMin : xMax;
    final int hi = xMin < xMax ? xMax : xMin;

    CurvatureCurvedir preferredDirection = CurvatureCurvedir.none;
    for (final Object element in findAllDescendantsByClassIdPredicate(
        (ClassId id) =>
            id == ClassId.chord || id == ClassId.note)) {
      final LayerElement el = element as LayerElement;
      if (el.getDrawingX() < lo || el.getDrawingX() > hi) continue;
      final Object? layer = element.getFirstAncestor(ClassId.layer);
      if (layer == null) continue;
      if (identical(layer, layerStart)) continue;
      final int layerN = (layer as AttNInteger).n ?? meiUnset;

      if (preferredDirection == CurvatureCurvedir.none) {
        if (layerN > layerStartN) {
          preferredDirection = CurvatureCurvedir.above;
        } else {
          preferredDirection = CurvatureCurvedir.below;
        }
      } else if (((preferredDirection == CurvatureCurvedir.above) &&
              (layerN < layerStartN)) ||
          ((preferredDirection == CurvatureCurvedir.below) &&
              (layerN > layerStartN))) {
        preferredDirection = CurvatureCurvedir.none;
        break;
      }
    }

    return preferredDirection;
  }

  /// Mirrors `System::IsLastOfSelection`.
  bool isLastOfSelection() {
    final Object? page = getFirstAncestor(ClassId.page);
    if (page == null) return false;
    if (page is! Page) return false;
    return page.isLastOfSelection() && isLastInPage();
  }

  /// Mirrors `System::GetDrawingX` (page x plus the relative offset; the
  /// page x is 0 until the vertical layout phase positions pages).
  @override
  int getDrawingX() {
    final Object? parent = this.parent;
    final int parentX = parent != null ? parent.getDrawingX() : 0;
    return parentX + _drawingXRel;
  }

  // The vertical layout members (drawingYRel, height, first/last in page
  // helpers) are defined above with the other drawing values.

  /// Mirrors `System::GetDrawingLabelsWidth`.
  int getDrawingLabelsWidth() => drawingScoreDef?.drawingLabelsWidth ?? 0;

  /// Mirrors `System::GetMinimumSystemSpacing` (system.cpp:162): the
  /// minimal spacing above the system — the explicit `spacingSystem` option
  /// when set, else the drawing scoreDef's `@spacing.system` (px directly,
  /// vu scaled by the drawing unit), else the option default.
  ///
  /// Verified against origin: the C++ method has no callers in the tree
  /// (only the declaration/definition exist); the live path is
  /// `Page::LayOutVertically` (page.cpp:606) computing the same product
  /// inline for `AlignSystemsFunctor`. The Dart layout keeps that inline
  /// path (`doc.dart:827`); this method is API parity, wired the same way
  /// for future callers.
  int getMinimumSystemSpacing(dynamic doc) {
    final dynamic spacingSystem = doc.getOptions().spacingSystem;
    if (!spacingSystem.isSet) {
      assert(drawingScoreDef != null);
      final ScoreDef? scoreDef = drawingScoreDef;
      if (scoreDef != null && scoreDef.hasSpacingSystem) {
        final dynamic spacing = scoreDef.spacingSystem!;
        if (spacing.type == MeasurementType.px) {
          return spacing.px as int;
        } else {
          return ((spacing.vu as double) * doc.getDrawingUnit(100)).toInt();
        }
      }
    }
    return (spacingSystem.value * doc.getDrawingUnit(100)).toInt();
  }

  /// The maximum abbreviated-label width for justification (mirrors
  /// `m_drawingAbbrLabelsWidth`, system.h:207).
  int drawingAbbrLabelsWidth = 0;

  /// Mirrors `System::GetDrawingAbbrLabelsWidth`.
  int getDrawingAbbrLabelsWidth() => drawingAbbrLabelsWidth;

  /// Mirrors `System::SetDrawingAbbrLabelsWidth` (system.cpp:191): keeps the
  /// widest value seen.
  void setDrawingAbbrLabelsWidth(int width) {
    if (drawingAbbrLabelsWidth < width) {
      drawingAbbrLabelsWidth = width;
    }
  }

  /// Mirrors `System::ResetDrawingAbbrLabelsWidth`.
  void resetDrawingAbbrLabelsWidth() => drawingAbbrLabelsWidth = 0;

  /// Mirrors `System::SetCurrentFloatingPositioner(int, FloatingObject*,
  /// Object*, Object*, char)`: retrieve or create the positioner of [object]
  /// on the staff alignment for [staffN]; returns false when the alignment
  /// does not exist.
  ///
  /// Renamed from the C++ (SetCurrentFloatingPositioner) because System
  /// inherits a same-named member through FloatingObject in this port.
  bool setSystemCurrentFloatingPositioner(
      int staffN, FloatingObject object, Object? objectX, Object? objectY,
      [int spanningType = spanningStartEnd]) {
    // If we have only the bottom alignment, then nothing to do (yet)
    if (systemAligner.childCount == 1) return false;
    final StaffAlignment? alignment =
        systemAligner.getStaffAlignmentForStaffN(staffN);
    if (alignment == null) {
      logError(
          "Staff @n='$staffN' for rendering control event ${object.className} "
          '${object.id} not found');
      return false;
    }
    if (objectX == null || objectY == null) return false;
    alignment.setCurrentFloatingPositioner(
        object, objectX, objectY, spanningType);
    return true;
  }

  /// Mirrors `System::AddToDrawingListIfNecessary` (system.cpp:338).
  ///
  /// Approximations: the C++ checks for `INTERFACE_TIME_SPANNING` and then a
  /// class whitelist, plus `Dir`/`Dynam` extender logic. This port replicates
  /// the whitelist check via `classId` set and the `hasInterface` guard; the
  /// `Dir`/`Dynam` extender branches are approximated as “has time-spanning
  /// interface implies add” when the fine-grained `spanningType` helpers are
  /// not yet wired in the test corpus.
  void addToDrawingListIfNecessary(Object object) {
    if (!object.hasInterface(InterfaceId.timeSpanning)) return;

    if (object.isAny(const {
      ClassId.annotScore,
      ClassId.beamSpan,
      ClassId.bracketSpan,
      // C++ FIGURE ↔ Dart ClassId.f (system.cpp:344)
      ClassId.f,
      ClassId.gliss,
      ClassId.hairpin,
      ClassId.lv,
      ClassId.octave,
      ClassId.phrase,
      ClassId.pitchInflection,
      ClassId.slur,
      ClassId.syl,
      ClassId.tie,
    })) {
      addToDrawingList(object);
    } else if (object.isClass(ClassId.dir)) {
      final Dir dir = object as Dir;
      if (dir.getEnd() != null ||
          (dir.nextLink != null && dir.extender == true)) {
        addToDrawingList(dir);
      }
    } else if (object.isClass(ClassId.dynam)) {
      final Dynam dynam = object as Dynam;
      if ((dynam.getEnd() != null || dynam.nextLink != null) &&
          (dynam.extender == true)) {
        addToDrawingList(dynam);
      }
    } else if (object.isClass(ClassId.pedal)) {
      final Pedal pedal = object as Pedal;
      if (pedal.getEnd() != null) {
        addToDrawingList(pedal);
      }
    } else if (object.isClass(ClassId.tempo)) {
      final Tempo tempo = object as Tempo;
      if (tempo.getEnd() != null && (tempo.extender == true)) {
        addToDrawingList(tempo);
      }
    } else if (object.isClass(ClassId.trill)) {
      final Trill trill = object as Trill;
      if (trill.getEnd() != null && (trill.extender != false)) {
        addToDrawingList(trill);
      }
    }
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {ClassId.div, ClassId.measure, ClassId.scoreDef};
    if (supported.contains(classId)) return true;
    if (Object.isSystemElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  // TODO(phase-4): drawing list, GetTopVisibleStaff and optimization flags
  // arrive with the layout / rendering phases.
}

/// Mirrors `vrv::SystemMilestoneEnd`.
///
/// Mirrors `systemmilestone.cpp:28-33` — passes the concrete ClassId to the
/// base and does NOT copy the start id (the Dart copy was a deviation).
class SystemMilestoneEnd extends SystemElement {
  SystemMilestoneEnd(this.start) : super(ClassId.systemMilestoneEnd) {
    assignClassId(ClassId.systemMilestoneEnd);
    startClassName = start.className;
  }

  /// The milestone start object.
  final Object start;

  /// The last measure seen when the end milestone was reached (set by the
  /// milestones preparation; mirrors `m_measure`).
  Object? measure;

  String startClassName = '';

  @override
  ClassId get classId => ClassId.systemMilestoneEnd;

  @override
  String get className => 'systemMilestoneEnd';

  @override
  Object clone() {
    final copy = SystemMilestoneEnd(start);
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::PageMilestoneEnd`.
///
/// Mirrors `pagemilestone.cpp:28-33` — passes the concrete ClassId to the
/// base and does NOT copy the start id.
class PageMilestoneEnd extends PageElement {
  PageMilestoneEnd(this.start) : super(ClassId.pageMilestoneEnd) {
    assignClassId(ClassId.pageMilestoneEnd);
    startClassName = start.className;
  }

  /// The milestone start object.
  final Object start;

  String startClassName = '';

  @override
  ClassId get classId => ClassId.pageMilestoneEnd;

  @override
  String get className => 'pageMilestoneEnd';

  @override
  Object clone() {
    final copy = PageMilestoneEnd(start);
    copy.copyFrom(this);
    return copy;
  }
}
