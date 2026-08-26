/// Ports of the small drawing/milestone interfaces used by the element
/// hierarchy: `VisibilityDrawingInterface` (from drawinginterface.h),
/// `SystemMilestoneInterface`, `PageMilestoneInterface`,
/// `BeamDrawingInterface` and `StemmedDrawingInterface`.
library;

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
///
/// The full drawing logic arrives with the beam rendering phase; for now it
/// carries the same mutable state as the C++ interface.
mixin BeamDrawingInterface {
  /// The beam is being drawn with children already added.
  bool beamHasChildren = false;

  /// The beam content was already drawn (used by stem drawing).
  bool beamPassed = false;

  /// The current note count in the beam.
  int currentNoteCount = 0;

  /// The drawing place of the beam (mirrors `m_drawingPlace`).
  Beamplace drawingPlace = Beamplace.none;

  void resetDrawingInterface() {
    beamHasChildren = false;
    beamPassed = false;
    currentNoteCount = 0;
    drawingPlace = Beamplace.none;
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
}
