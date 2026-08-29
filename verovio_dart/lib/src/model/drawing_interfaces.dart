/// Ports of the small drawing/milestone interfaces used by the element
/// hierarchy: `VisibilityDrawingInterface` (from drawinginterface.h),
/// `SystemMilestoneInterface`, `PageMilestoneInterface`,
/// `BeamDrawingInterface` and `StemmedDrawingInterface`.
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show PageMilestoneEnd, SystemMilestoneEnd;

/// Mirrors `vrv::VisibilityDrawingInterface`.
///
/// Holds the visibility (hidden or visible) for an element implementing the
/// interface. By default all editorial elements are visible; in an `<app>`
/// only one `<rdg>` is visible at a time (the loader makes the first one
/// visible).
mixin VisibilityDrawingInterface {
  VisibilityType visibility = VisibilityType.visible;

  void resetVisibility() {
    visibility = VisibilityType.visible;
  }

  void setVisibility(VisibilityType value) => visibility = value;

  bool get isHidden => visibility == VisibilityType.hidden;
}

/// Mirrors `vrv::SystemMilestoneInterface`.
mixin SystemMilestoneInterface {
  /// The corresponding SystemMilestoneEnd (null for the end objects).
  Object? systemMilestoneEnd;

  /// The drawing measure attached to the milestone (set by layout functors).
  Object? drawingMeasure;

  bool isSystemMilestone() => systemMilestoneEnd != null;

  /// Mirrors `SystemMilestoneInterface::SetEnd`.
  void setSystemMilestoneEnd(Object end) {
    assert(systemMilestoneEnd == null);
    systemMilestoneEnd = end;
  }

  /// Mirrors `SystemMilestoneInterface::ConvertToPageBasedMilestone`.
  ///
  /// Adds a [SystemMilestoneEnd] for this object to [parent] (a System) and
  /// clears the relinquished children of [object].
  void convertToPageBasedMilestone(Object object, Object parent) {
    final SystemMilestoneEnd end = SystemMilestoneEnd(object);
    setSystemMilestoneEnd(end);
    parent.addChild(end);
    object.clearRelinquishedChildren();
  }
}

/// Mirrors `vrv::PageMilestoneInterface`.
mixin PageMilestoneInterface {
  /// The corresponding PageMilestoneEnd (null for the end objects).
  Object? pageMilestoneEnd;

  bool isPageMilestone() => pageMilestoneEnd != null;

  /// Mirrors `PageMilestoneInterface::SetEnd`.
  void setPageMilestoneEnd(Object end) {
    assert(pageMilestoneEnd == null);
    pageMilestoneEnd = end;
  }

  /// Mirrors `PageMilestoneInterface::ConvertToPageBasedMilestone`.
  ///
  /// Adds a [PageMilestoneEnd] for this object to [parent] (a Page) and
  /// clears the relinquished children of [object].
  void convertToPageBasedMilestone(Object object, Object parent) {
    final PageMilestoneEnd end = PageMilestoneEnd(object);
    setPageMilestoneEnd(end);
    parent.addChild(end);
    object.clearRelinquishedChildren();
  }
}

/// Port of the state parts of `BeamDrawingInterface` (drawinginterface.h).
mixin BeamDrawingInterface {
  /// The beam is being drawn with children already added.
  bool beamHasChildren = false;

  /// The beam content was already drawn (used by stem drawing).
  bool beamPassed = false;

  /// The current note count in the beam.
  int currentNoteCount = 0;

  /// The drawing place of the beam (mirrors `m_drawingPlace`).
  Beamplace drawingPlace = Beamplace.none;

  /// The staff of the cross-staff beam content, if any (mirrors
  /// `m_crossStaffContent`). Typed as [Object] to avoid an import cycle with
  /// the generated element classes.
  Object? crossStaffContent;

  /// The width of the black part of the beam, set by the beam calculation
  /// (mirrors `m_beamWidthBlack`).
  int beamWidthBlack = 0;

  /// The width of the beam (black + white), set by the beam calculation
  /// (mirrors `m_beamWidth`, drawinginterface.h); consumed by
  /// `AdjustBeamsFunctor`. Populated together with the rest of the
  /// `BeamSegment::CalcBeam` geometry (pending task); zero until then.
  int beamWidth = 0;

  /// White width and fraction size (mirrors `m_beamWidthWhite`/`m_fractionSize`).
  int beamWidthWhite = 0;
  int fractionSize = 100;

  /// Additional state from drawinginterface.h needed by the view renderer.
  bool changingDur = false;
  bool beamHasChord = false;
  bool hasMultipleStemDir = false;
  bool cueSize = false;
  bool isSpanningElement = false;
  MeiDuration shortestDur = MeiDuration.none;
  Stemdirection notesStemDir = Stemdirection.none;
  Object? beamStaff;
  Object? crossStaffContent2;
  int crossStaffRel = 0;

  /// Owned element coords (mirrors `m_beamElementCoords`, drawinginterface.h:227).
  /// Populated by `InitCoords` during the render pass (view_beam.cpp).
  final List<dynamic> beamElementCoordsOwned = [];

  void resetDrawingInterface() {
    beamHasChildren = false;
    beamPassed = false;
    currentNoteCount = 0;
    drawingPlace = Beamplace.none;
    crossStaffContent = null;
    beamWidthBlack = 0;
    beamWidth = 0;
    beamWidthWhite = 0;
    fractionSize = 100;
    changingDur = false;
    beamHasChord = false;
    hasMultipleStemDir = false;
    cueSize = false;
    isSpanningElement = false;
    shortestDur = MeiDuration.none;
    notesStemDir = Stemdirection.none;
    beamStaff = null;
    beamElementCoordsOwned.clear();
  }
}

/// Port of `StemmedDrawingInterface` (drawinginterface.h).
///
/// The direction / length values live on the managed [Stem] object (mirrors
/// the C++ delegation through `m_drawingStem`). The stem is stored as
/// [Object] to avoid an import cycle with the generated element classes.
mixin StemmedDrawingInterface {
  /// The stem object managed by the interface (mirrors `m_drawingStem`).
  Object? _drawingStem;

  /// Set the stem object managed by the interface (mirrors
  /// `SetDrawingStem`).
  void setDrawingStem(Object? stem) => _drawingStem = stem;

  /// Get the stem object managed by the interface (mirrors
  /// `GetDrawingStem`); typed dynamically to avoid an import cycle.
  dynamic getDrawingStem() => _drawingStem;

  /// True when a stem is set (mirrors a NULL check on `m_drawingStem`).
  bool get hasDrawingStem => _drawingStem != null;

  /// Mirrors `StemmedDrawingInterface::Reset`.
  void resetStemmedDrawingInterface() {
    _drawingStem = null;
  }

  /// Set the stem direction, passing the value to the stem (mirrors
  /// `SetDrawingStemDir`).
  void setDrawingStemDir(Stemdirection stemDir) {
    if (_drawingStem != null) {
      (_drawingStem as dynamic).setDrawingStemDir(stemDir);
    }
  }

  /// Get the stem direction from the stem (mirrors `GetDrawingStemDir`).
  Stemdirection getDrawingStemDir() {
    if (_drawingStem != null) {
      return (_drawingStem! as dynamic).getDrawingStemDir() as Stemdirection;
    }
    return Stemdirection.none;
  }

  /// Set the stem length on the stem (mirrors `SetDrawingStemLen`).
  void setDrawingStemLen(int drawingStemLen) {
    if (_drawingStem != null) {
      (_drawingStem as dynamic).setDrawingStemLen(drawingStemLen);
    }
  }

  /// Get the stem length from the stem (mirrors `GetDrawingStemLen`).
  int getDrawingStemLen() {
    if (_drawingStem != null) {
      return (_drawingStem! as dynamic).getDrawingStemLen() as int;
    }
    return 0;
  }

  /// Return the endpoint of the stem (mirrors
  /// `StemmedDrawingInterface::GetDrawingStemEnd`).
  ///
  /// [object] is the note/chord owning this interface (passed explicitly
  /// since Dart has no `this` upcast to the sibling LayerElement side of the
  /// multiple-inheritance split the C++ has here).
  Point getDrawingStemEnd(Object object) {
    if (_drawingStem == null) {
      // Somehow arbitrary for chord with no stem - stem end is the bottom.
      if (object.classId == ClassId.chord) {
        final int yBottom = (object as dynamic).getYBottom() as int;
        return Point(object.getDrawingX(), yBottom);
      }
      return Point(object.getDrawingX(), object.getDrawingY());
    }
    final Object stem = _drawingStem!;
    return Point(stem.getDrawingX(), stem.getDrawingY() - getDrawingStemLen());
  }
}
