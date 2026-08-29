/// Ports of the small drawing/milestone interfaces used by the element
/// hierarchy: `VisibilityDrawingInterface` (from drawinginterface.h),
/// `SystemMilestoneInterface`, `PageMilestoneInterface`,
/// `BeamDrawingInterface` and `StemmedDrawingInterface`.
library;

// ignore_for_file: dead_code, unused_element, unused_local_variable

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/beam_segment.dart' show BeamElementCoord;
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

  int getTotalBeamWidth() =>
      beamWidthBlack + (shortestDur.value - MeiDuration.dur8.value) * beamWidth;

  void clearCoords() => beamElementCoordsOwned.clear();

  /// Mirrors `BeamDrawingInterface::InitCoords` (drawinginterface.cpp:140) — reduced.
  void initCoords(List<Object> childList, dynamic staff, Beamplace place) {
    resetDrawingInterface();
    clearCoords();
    if (childList.isEmpty) return;
    beamStaff = staff;
    MeiDuration shortest = MeiDuration.none;
    bool hasChord = false;
    bool changing = false;
    MeiDuration lastDur = MeiDuration.none;
    bool hasMultiple = false;
    Stemdirection notesDir = Stemdirection.none;
    for (final Object child in childList) {
      final BeamElementCoord coord = BeamElementCoord();
      coord.element = child;
      MeiDuration curDur = MeiDuration.dur8;
      try {
        curDur = (child as dynamic).getActualDur() as MeiDuration;
      } catch (_) {
        try {
          curDur = (child as dynamic).dur as MeiDuration;
        } catch (_) {}
      }
      coord.dur = curDur;
      if (curDur.value > MeiDuration.dur8.value) {
        if (shortest == MeiDuration.none || curDur.value > shortest.value) shortest = curDur;
      } else if (shortest == MeiDuration.none) {
        shortest = curDur;
      }
      try {
        if ((child as dynamic).classId == ClassId.chord) hasChord = true;
      } catch (_) {
        if (child.runtimeType.toString().contains('Chord')) hasChord = true;
      }
      try {
        final dynamic d = child as dynamic;
        if (d.hasBreaksec == true) {
          coord.breaksec = d.breaksec as int;
          changing = true;
        } else if (d.breaksec != null && d.breaksec != 0) {
          coord.breaksec = d.breaksec as int;
          changing = true;
        }
      } catch (_) {}
      try {
        final dynamic cs = (child as dynamic).crossStaff;
        if (cs != null && cs != staff) crossStaffContent = cs as Object?;
      } catch (_) {}
      try {
        bool isChordOrNote = false;
        try {
          final cid = (child as dynamic).classId as ClassId?;
          isChordOrNote = cid == ClassId.chord || cid == ClassId.note;
        } catch (_) {}
        if (isChordOrNote) {
          Stemdirection curDir = Stemdirection.none;
          try {
            curDir = (child as dynamic).getDrawingStemDir() as Stemdirection;
          } catch (_) {
            try {
              final dynamic stem = (child as dynamic).getDrawingStem();
              if (stem != null) curDir = (stem as dynamic).getDrawingStemDir() as Stemdirection;
            } catch (_) {}
          }
          if (curDir != Stemdirection.none) {
            if (notesDir != Stemdirection.none && notesDir != curDir) {
              hasMultiple = true;
              notesDir = Stemdirection.none;
            } else {
              notesDir = curDir;
            }
          }
        }
      } catch (_) {}
      if (lastDur != MeiDuration.none && curDur != lastDur) changing = true;
      lastDur = curDur;
      try {
        if ((child as dynamic).classId == ClassId.chord) {
          final ch = child as dynamic;
          coord.closestNote = ch.getBottomNote() ?? ch.getTopNote();
          try {
            coord.stem = (ch as dynamic).getDrawingStem();
          } catch (_) {}
        } else if ((child as dynamic).classId == ClassId.note) {
          coord.closestNote = child;
          try {
            coord.stem = (child as dynamic).getDrawingStem();
          } catch (_) {}
        }
      } catch (_) {}
      beamElementCoordsOwned.add(coord);
    }
    if (shortest == MeiDuration.none) shortest = MeiDuration.dur8;
    shortestDur = shortest;
    beamHasChord = hasChord;
    changingDur = changing;
    hasMultipleStemDir = hasMultiple;
    notesStemDir = notesDir;
    bool cue = false;
    try {
      cue = (this as dynamic).cueSize as bool;
    } catch (_) {
      cue = childList.every((e) {
        try {
          return (e as dynamic).drawingCueSize == true || (e as dynamic).isGraceNote() == true;
        } catch (_) {
          return false;
        }
      });
    }
    cueSize = cue;
    try {
      fractionSize = (staff as dynamic).drawingStaffSize as int;
    } catch (_) {}
  }

  void initCue(bool beamCue) {
    if (beamCue) {
      cueSize = true;
      return;
    }
    bool allCue = true;
    for (final dynamic coord in beamElementCoordsOwned) {
      try {
        final el = coord.element;
        if (el == null) {
          allCue = false;
          break;
        }
        final bool isGrace = (el as dynamic).isGraceNote() == true;
        final bool isCue = (el as dynamic).getDrawingCueSize() == true || (el as dynamic).drawingCueSize == true;
        if (!isGrace && !isCue) {
          allCue = false;
          break;
        }
      } catch (_) {
        allCue = false;
        break;
      }
    }
    cueSize = allCue;
  }

  void initGraceStemDir(bool graceGrp) {
    if (!graceGrp) {
      bool allGrace = true;
      for (final dynamic coord in beamElementCoordsOwned) {
        try {
          final el = coord.element;
          if (el == null || (el as dynamic).isGraceNote() != true) {
            allGrace = false;
            break;
          }
        } catch (_) {
          allGrace = false;
          break;
        }
      }
      graceGrp = allGrace;
    }
    if (graceGrp && notesStemDir == Stemdirection.none) {
      notesStemDir = Stemdirection.up;
    }
  }

  bool isHorizontal() {
    if (drawingPlace == Beamplace.none) return true;
    if (beamElementCoordsOwned.length < 2) return true;
    // Simplified: if first and last y equal
    try {
      final first = beamElementCoordsOwned.first as BeamElementCoord;
      final last = beamElementCoordsOwned.last as BeamElementCoord;
      final int y1 = (first.closestNote as dynamic).getDrawingY() as int;
      final int y2 = (last.closestNote as dynamic).getDrawingY() as int;
      if (y1 == y2) return true;
    } catch (_) {}
    return false;
  }

  bool isRepeatedPattern() => false;
  bool hasOneStepHeight() => false;

  bool isFirstIn(dynamic element) => getPosition(element) == 0;
  bool isLastIn(dynamic element) => getPosition(element) == getListSize() - 1;
  int getListSize() {
    try {
      return (this as dynamic).getListSize() as int;
    } catch (_) {
      try {
        return (this as dynamic).getList().length as int;
      } catch (_) {
        return beamElementCoordsOwned.length;
      }
    }
  }

  int getPosition(dynamic element) {
    try {
      final dynamic self = this as dynamic;
      int pos = self.getListIndex(element) as int;
      if (pos == -1) {
        try {
          if ((element as dynamic).classId == ClassId.note) {
            final chord = (element as dynamic).isChordTone() as dynamic;
            if (chord != null) pos = self.getListIndex(chord) as int;
          }
        } catch (_) {}
      }
      return pos;
    } catch (_) {
      return -1;
    }
  }

  void getBeamOverflow(dynamic above, dynamic below) {}
  void getBeamChildOverflow(dynamic above, dynamic below) {}
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
