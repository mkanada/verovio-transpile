/// Ports of the small drawing/milestone interfaces used by the element
/// hierarchy: `VisibilityDrawingInterface` (from drawinginterface.h),
/// `SystemMilestoneInterface`, `PageMilestoneInterface`,
/// `BeamDrawingInterface` and `StemmedDrawingInterface`.
library;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration, meiUnset;
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_cmn.dart' show AttBeamSecondary;
import 'package:verovio_dart/src/model/atts/atts_shared.dart' show AttStems;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Staff, Note;
import 'package:verovio_dart/src/model/beam_segment.dart' show BeamElementCoord;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show StaffAlignment;
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart'
    show DurationInterface;
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show Chord, Stem;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show PageMilestoneEnd, SystemMilestoneEnd;

/// `DUR_MAX` (libmei/addons/attdef.h:37) — used by `IsRepeatedPattern` purely
/// to fold a note's Y position and duration into one comparable integer.
const int _durMax = 2048;

/// Mirrors the free function `GetNoteDirection` (drawinginterface.cpp:28).
Stemdirection _getNoteDirection(int leftNoteY, int rightNoteY) {
  if (leftNoteY == rightNoteY) return Stemdirection.none;
  return leftNoteY < rightNoteY ? Stemdirection.up : Stemdirection.down;
}

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

  /// The relative position of [crossStaffContent] with respect to
  /// [beamStaff] (mirrors `m_crossStaffRel`).
  StaffrelBasic crossStaffRel = StaffrelBasic.none;

  /// Owned element coords (mirrors `m_beamElementCoords`, drawinginterface.h:227).
  /// Populated by `InitCoords` during the render pass (view_beam.cpp).
  final List<BeamElementCoord> beamElementCoordsOwned = <BeamElementCoord>[];

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
  void initCoords(List<Object> childList, Staff? staff, Beamplace place) {
    resetDrawingInterface();
    clearCoords();
    if (childList.isEmpty) return;
    if (staff == null) return;
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
      if (child is DurationInterface) {
        curDur = (child as DurationInterface).getActualDur();
      }
      coord.dur = curDur;
      if (curDur.value > MeiDuration.dur8.value) {
        if (shortest == MeiDuration.none || curDur.value > shortest.value) {
          shortest = curDur;
        }
      } else if (shortest == MeiDuration.none) {
        shortest = curDur;
      }
      if (child.classId == ClassId.chord) hasChord = true;
      if (child is AttBeamSecondary) {
        final int? bs = (child as AttBeamSecondary).breaksec;
        if (bs != null) {
          coord.breaksec = bs;
          changing = true;
        }
      }
      if (child is LayerElement) {
        final Staff? cs = (child as LayerElement).crossStaff;
        if (cs != null && cs != staff) {
          crossStaffContent = cs;
          crossStaffRel = (child as LayerElement).getCrossStaffRel();
        } else if (child is Chord) {
          final Chord chord = child as Chord;
          for (final Note? note in [chord.getTopNote(), chord.getBottomNote()]) {
            if (note == null) continue;
            final Staff? noteCs = note.crossStaff;
            if (noteCs != null && noteCs != staff) {
              crossStaffContent = noteCs;
              crossStaffRel = note.getCrossStaffRel();
            }
          }
        }
      }
      final bool isChordOrNote =
          child.classId == ClassId.chord || child.classId == ClassId.note;
      if (isChordOrNote) {
        Stemdirection curDir = Stemdirection.none;
        if (child is StemmedDrawingInterface) {
          curDir = (child as StemmedDrawingInterface).getDrawingStemDir();
        }
        if (curDir == Stemdirection.none && child is AttStems) {
          curDir = (child as AttStems).stemDir ?? Stemdirection.none;
        }
        if (curDir == Stemdirection.none && child is StemmedDrawingInterface) {
          final Stem? stem = (child as StemmedDrawingInterface).getDrawingStem();
          if (stem != null) {
            curDir = stem.getDrawingStemDir();
            if (curDir == Stemdirection.none) {
              curDir = stem.dir ?? Stemdirection.none;
            }
          }
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
      if (lastDur != MeiDuration.none && curDur != lastDur) changing = true;
      lastDur = curDur;
      if (child is Chord) {
        coord.closestNote = child.getBottomNote() ?? child.getTopNote();
        coord.stem = child.getDrawingStem();
      } else if (child is Note) {
        coord.closestNote = child;
        coord.stem = child.getDrawingStem();
      }
      beamElementCoordsOwned.add(coord);
    }
    if (shortest == MeiDuration.none) shortest = MeiDuration.dur8;
    shortestDur = shortest;
    beamHasChord = hasChord;
    changingDur = changing;
    hasMultipleStemDir = hasMultiple;
    notesStemDir = notesDir;
    fractionSize = staff.drawingStaffSize;
  }

  void initCue(bool beamCue) {
    if (beamCue) {
      cueSize = true;
      return;
    }
    bool allCue = true;
    for (final BeamElementCoord coord in beamElementCoordsOwned) {
      final Object? el = coord.element;
      if (el == null) {
        allCue = false;
        break;
      }
      if (el is LayerElement) {
        final bool isGrace = el.isGraceNote();
        final bool isCue = el.drawingCueSize;
        if (!isGrace && !isCue) {
          allCue = false;
          break;
        }
      } else {
        allCue = false;
        break;
      }
    }
    cueSize = allCue;
  }

  void initGraceStemDir(bool graceGrp) {
    if (!graceGrp) {
      bool allGrace = true;
      for (final BeamElementCoord coord in beamElementCoordsOwned) {
        final Object? el = coord.element;
        if (el is! LayerElement || !el.isGraceNote()) {
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

  /// Mirrors `BeamDrawingInterface::IsHorizontal` (drawinginterface.cpp:295).
  ///
  /// Deviation: `m_closestNote`/`m_stem` are set eagerly by [initCoords] in
  /// this port (a simplified "closest note = self/bottom-or-top" guess),
  /// rather than staying null until a later `SetClosestNoteOrTabDurSym`/
  /// `SetDrawingStemDir` call as in the C++ (see the doc comment on
  /// `initCoords`). Because [beamElementCoordsOwned] and
  /// `BeamSegment.beamElementCoordRefs` share the same [BeamElementCoord]
  /// instances, this method still picks up the real, per-pass-refined
  /// `closestNote`/`stem` once `CalcBeamStemLength` has run in a prior
  /// `calcBeam` call on the same beam — matching the C++'s own reliance on
  /// state carried over from a previous pass — but on the very first call it
  /// sees the eager guess instead of "unset".
  bool isHorizontal() {
    if (isRepeatedPattern()) return true;
    if (hasOneStepHeight()) return true;
    if (drawingPlace == Beamplace.none) return true;

    final List<int> items = <int>[];
    final List<Beamplace> directions = <Beamplace>[];
    for (final BeamElementCoord coord in beamElementCoordsOwned) {
      if (coord.stem == null || coord.closestNote == null) continue;
      final Object cn = coord.closestNote!;
      if (cn is! LayerElement) continue;
      items.add(cn.getDrawingY());
      directions.add(coord.beamRelativePlace);
    }
    final int itemCount = items.length;
    if (itemCount < 2) return true;

    final int first = items.first;
    final int last = items.last;
    if (first == last) return true;

    if (drawingPlace == Beamplace.mixed && isHorizontalMixedBeam(items, directions)) {
      return true;
    }

    final bool firstStep = first != items[1];
    final bool lastStep = last != items[items.length - 2];
    if (itemCount > 2 && (firstStep || lastStep)) {
      for (int i = 1; i < itemCount - 1; ++i) {
        if (drawingPlace == Beamplace.above) {
          if (items[i] >= first && items[i] >= last) return true;
        } else if (drawingPlace == Beamplace.below) {
          if (items[i] <= first && items[i] <= last) return true;
        }
      }
      final List<int> pitches = <int>[];
      for (int i = 0; i < items.length; ++i) {
        if (i == 0 || items[i] != items[i - 1]) pitches.add(items[i]);
      }
      if (pitches.length == 2) {
        bool isSorted(List<int> l) {
          for (int i = 1; i < l.length; ++i) {
            if (l[i] < l[i - 1]) return false;
          }
          return true;
        }

        bool isSortedDesc(List<int> l) {
          for (int i = 1; i < l.length; ++i) {
            if (l[i] > l[i - 1]) return false;
          }
          return true;
        }

        if (drawingPlace == Beamplace.above) {
          if (firstStep && isSorted(items)) return true;
          if (lastStep && isSortedDesc(items)) return true;
        } else {
          if (lastStep && isSorted(items)) return true;
          if (firstStep && isSortedDesc(items)) return true;
        }
      }
    }

    return false;
  }

  /// Mirrors `BeamDrawingInterface::IsHorizontalMixedBeam`
  /// (drawinginterface.cpp:365).
  bool isHorizontalMixedBeam(List<int> items, List<Beamplace> directions) {
    if (items.length != directions.length) return false;

    int directionChanges = 0;
    Beamplace previous = directions.first;
    for (final Beamplace current in directions) {
      if (current != previous) {
        directionChanges++;
        previous = current;
      }
    }
    if (directionChanges <= 1) return false;

    int previousTop = meiUnset;
    int previousBottom = meiUnset;
    final Stemdirection outsidePitchDirection =
        _getNoteDirection(items.first, items.last);
    final Map<Stemdirection, int> beamDirections = <Stemdirection, int>{
      Stemdirection.none: 0,
      Stemdirection.up: 0,
      Stemdirection.down: 0,
    };
    for (int i = 0; i < directions.length; ++i) {
      final Beamplace direction = directions[i];
      if (direction == Beamplace.above) {
        if (previousTop == meiUnset) {
          previousTop = items[i];
        } else {
          final Stemdirection d = _getNoteDirection(previousTop, items[i]);
          beamDirections[d] = (beamDirections[d] ?? 0) + 1;
        }
      } else if (direction == Beamplace.below) {
        if (previousBottom == meiUnset) {
          previousBottom = items[i];
        } else {
          final Stemdirection d = _getNoteDirection(previousBottom, items[i]);
          beamDirections[d] = (beamDirections[d] ?? 0) + 1;
        }
      }
    }
    final int outsideCount = beamDirections[outsidePitchDirection] ?? 0;
    for (final MapEntry<Stemdirection, int> pair in beamDirections.entries) {
      if (pair.key == outsidePitchDirection) continue;
      if (pair.value > outsideCount) return true;
    }
    return false;
  }

  /// Mirrors `BeamDrawingInterface::IsRepeatedPattern` (drawinginterface.cpp:418).
  bool isRepeatedPattern() {
    if (drawingPlace == Beamplace.mixed) return false;
    if (drawingPlace == Beamplace.none) return false;

    final int elementCount = beamElementCoordsOwned.length;
    if (elementCount < 4) return false;

    final List<int> items = <int>[];
    for (final BeamElementCoord coord in beamElementCoordsOwned) {
      if (coord.stem == null || coord.closestNote == null) continue;
      final Object cn = coord.closestNote!;
      if (cn is! LayerElement) continue;
      // DUR_MAX in the C++ is the highest enumerator value across all
      // duration-like enums, used purely to make each note's Y position and
      // duration collide into one comparable integer.
      items.add(cn.getDrawingY() + _durMax * coord.dur.value);
    }
    final int itemCount = items.length;
    if (itemCount < 4) return false;
    bool allEqual = true;
    for (int i = 1; i < itemCount; ++i) {
      if (items[i] != items[0]) {
        allEqual = false;
        break;
      }
    }
    if (allEqual) return false;

    final List<int> dividers = <int>[];
    for (int i = 2; i <= itemCount ~/ 2; ++i) {
      if (itemCount % i == 0) dividers.add(i);
    }

    for (final int divider in dividers) {
      bool pattern = true;
      final List<int> v1 = items.sublist(0, divider);
      for (int j = 1; j < itemCount ~/ divider; ++j) {
        final List<int> v2 = items.sublist(j * divider, (j + 1) * divider);
        bool same = true;
        for (int k = 0; k < divider; ++k) {
          if (v1[k] != v2[k]) {
            same = false;
            break;
          }
        }
        if (!same) {
          pattern = false;
          break;
        }
      }
      if (pattern) return true;
    }
    return false;
  }

  /// Mirrors `BeamDrawingInterface::HasOneStepHeight` (drawinginterface.cpp:472).
  bool hasOneStepHeight() {
    if (shortestDur.value < MeiDuration.dur32.value) return false;

    int top = -128;
    int bottom = 128;
    for (final BeamElementCoord coord in beamElementCoordsOwned) {
      final Object? cn = coord.closestNote;
      if (cn is Note) {
        final int loc = cn.drawingLoc;
        if (loc > top) top = loc;
        if (loc < bottom) bottom = loc;
      }
    }
    return (top - bottom).abs() <= 1;
  }

  bool isFirstIn(Object? element) => getPosition(element) == 0;
  bool isLastIn(Object? element) => getPosition(element) == getListSize() - 1;

  int getListSize() {
    if (this is ObjectListInterface) {
      return (this as ObjectListInterface).getListSize();
    }
    return beamElementCoordsOwned.length;
  }

  int getPosition(Object? element) {
    if (element == null) return -1;
    if (this is ObjectListInterface) {
      final ObjectListInterface oli = this as ObjectListInterface;
      int pos = oli.getListIndex(element);
      if (pos == -1 && element is Note) {
        final Object? chord = element.isChordTone();
        if (chord != null) pos = oli.getListIndex(chord);
      }
      return pos;
    }
    return -1;
  }

  /// Mirrors `BeamDrawingInterface::GetBeamOverflow` (drawinginterface.cpp:525).
  ///
  /// [above]/[below] carry the caller's current alignment choice (out
  /// parameters in the C++ via `StaffAlignment *&`); returned unchanged when
  /// this beam has no cross-staff content to redirect to.
  (StaffAlignment?, StaffAlignment?) getBeamOverflow(
      StaffAlignment? above, StaffAlignment? below) {
    final Staff? bs = beamStaff as Staff?;
    final Staff? csc = crossStaffContent as Staff?;
    if (bs == null || csc == null) return (above, below);

    if (drawingPlace == Beamplace.mixed) {
      return (null, null);
    } else if (drawingPlace == Beamplace.below) {
      final StaffAlignment? newBelow = (crossStaffRel == StaffrelBasic.above)
          ? bs.staffAlignment
          : csc.staffAlignment;
      return (null, newBelow);
    } else if (drawingPlace == Beamplace.above) {
      final StaffAlignment? newAbove = (crossStaffRel == StaffrelBasic.below)
          ? bs.staffAlignment
          : csc.staffAlignment;
      return (newAbove, null);
    }
    return (above, below);
  }

  /// Mirrors `BeamDrawingInterface::GetBeamChildOverflow`
  /// (drawinginterface.cpp:552).
  (StaffAlignment?, StaffAlignment?) getBeamChildOverflow(
      StaffAlignment? above, StaffAlignment? below) {
    final Staff? bs = beamStaff as Staff?;
    final Staff? csc = crossStaffContent as Staff?;
    if (bs == null || csc == null) return (above, below);

    if (crossStaffRel == StaffrelBasic.above) {
      return (csc.staffAlignment, bs.staffAlignment);
    }
    return (bs.staffAlignment, csc.staffAlignment);
  }

  /// Mirrors `BeamDrawingInterface::GetAdditionalBeamCount`
  /// (drawinginterface.h:161) — the `{0, 0}` default. `Beam`
  /// (beam.cpp:2052) and `FTrem` (ftrem.cpp:100) both override it.
  (int, int) getAdditionalBeamCount() => (0, 0);
}

/// Port of `StemmedDrawingInterface` (drawinginterface.h).
///
/// The direction / length values live on the managed [Stem] object (mirrors
/// the C++ delegation through `m_drawingStem`).
///
/// Deviations from the C++:
/// - `GetDrawingStemEnd` takes the owning object explicitly (Dart has no
///   `this` upcast to the sibling LayerElement side of the C++ multiple
///   inheritance).
mixin StemmedDrawingInterface {
  /// The stem object managed by the interface (mirrors `m_drawingStem`).
  Stem? _drawingStem;

  /// Set the stem object managed by the interface (mirrors
  /// `SetDrawingStem`).
  void setDrawingStem(Stem? stem) => _drawingStem = stem;

  /// Get the stem object managed by the interface (mirrors
  /// `GetDrawingStem`).
  Stem? getDrawingStem() => _drawingStem;

  /// True when a stem is set (mirrors a NULL check on `m_drawingStem`).
  bool get hasDrawingStem => _drawingStem != null;

  /// Mirrors `StemmedDrawingInterface::Reset`.
  void resetStemmedDrawingInterface() {
    _drawingStem = null;
  }

  /// Set the stem direction, passing the value to the stem (mirrors
  /// `SetDrawingStemDir`).
  void setDrawingStemDir(Stemdirection stemDir) {
    _drawingStem?.setDrawingStemDir(stemDir);
  }

  /// Get the stem direction from the stem (mirrors `GetDrawingStemDir`).
  Stemdirection getDrawingStemDir() =>
      _drawingStem?.getDrawingStemDir() ?? Stemdirection.none;

  /// Set the stem length on the stem (mirrors `SetDrawingStemLen`).
  void setDrawingStemLen(int drawingStemLen) {
    _drawingStem?.setDrawingStemLen(drawingStemLen);
  }

  /// Get the stem length from the stem (mirrors `GetDrawingStemLen`).
  int getDrawingStemLen() => _drawingStem?.getDrawingStemLen() ?? 0;

  /// The relative Y for stem-modifier (tremolo slash / sprechgesang /
  /// buzz-roll) positioning, taken from the stem (mirrors
  /// `StemmedDrawingInterface::GetDrawingStemModRelY`).
  int getDrawingStemModRelY() => _drawingStem?.stemModRelY ?? 0;

  /// Return the start point of the stem (mirrors
  /// `StemmedDrawingInterface::GetDrawingStemStart`).
  ///
  /// [object] is the note/chord owning this interface, used as a fallback
  /// when there is no drawing stem (same explicit-object deviation as
  /// [getDrawingStemEnd]).
  Point getDrawingStemStart(Object object) {
    if (_drawingStem == null) {
      return Point(object.getDrawingX(), object.getDrawingY());
    }
    final Stem stem = _drawingStem!;
    return Point(stem.getDrawingX(), stem.getDrawingY());
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
      if (object is Chord) {
        return Point(object.getDrawingX(), object.getYBottom());
      }
      return Point(object.getDrawingX(), object.getDrawingY());
    }
    final Stem stem = _drawingStem!;
    return Point(stem.getDrawingX(), stem.getDrawingY() - getDrawingStemLen());
  }
}
