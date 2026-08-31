/// Port of `timeinterface.h/cpp` — TimePointInterface and
/// TimeSpanningInterface.
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/utils.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment;
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Staffrel;
import 'package:verovio_dart/src/model/basic_elements.dart' show Measure, Staff;
import 'package:verovio_dart/src/model/comparison.dart'
    show AttNIntegerComparison;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';
import 'package:verovio_dart/src/model/layer_element.dart'
    show LayerElement;
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show System;

/// This class is an interface for elements having a single time point, such
/// as tempo, reh, etc. (mirrors `vrv::TimePointInterface`).
///
/// Apply together with [AttPartIdent], [AttStaffIdent], [AttStartId] and
/// [AttTimestampLog].
///
/// Note: the C++ stores a `LayerElement *`; until the element hierarchy is
/// ported the start/end are kept as [Object].
mixin TimePointInterface
    on AttPartIdent, AttStaffIdent, AttStartId, AttTimestampLog
    implements Interface {
  /// The resolved @startid element.
  LayerElement? start;

  /// The fragment of the @startid attribute.
  String startID = '';

  @override
  InterfaceId get interfaceId => InterfaceId.timePoint;

  @override
  void reset() {
    part = null;
    partstaff = null;
    staff = null;
    startid = null;
    tstamp = null;

    start = null;
    startID = '';
  }

  /// Set the first LayerElement. Asserts that none was previously set.
  void setStart(LayerElement element) {
    assert(start == null);
    start = element;
  }

  /// Set the first LayerElement by verifying it is the expected one.
  bool setStartOnly(LayerElement element) {
    if (start == null && startID.isNotEmpty && element.id == startID) {
      setStart(element);
      return true;
    }
    return false;
  }

  /// Add a staff n to the @staff list (if not already there).
  void addStaff(int n) {
    final List<int>? staves = staff;
    if (staves == null) {
      staff = [n];
    } else if (!staves.contains(n)) {
      staff = [...staves, n];
    }
  }

  /// Extract the fragment of the @startid if given.
  void setIDStr() {
    if (hasStartid && startid != null) {
      startID = extractIDFragment(startid!);
    }
  }

  /// Return true if a start is given (@startid or @tstamp).
  bool get hasStart => start != null;

  /// Return the resolved start element (mirrors `GetStart`).
  LayerElement? getStart() => start;

  /// Return the resolved end element for spanning interfaces; null here
  /// (overridden by [TimeSpanningInterface]).
  LayerElement? getEnd() => null;

  /// Return the start measure of the TimePointInterface (mirrors
  /// `GetStartMeasure`).
  Measure? getStartMeasure() {
    if (start == null) return null;
    return start!.getFirstAncestor(ClassId.measure) as Measure?;
  }

  /// Return true if the TimePointInterface occurs on the staff @n.
  ///
  /// Looks at the @staff values or at the parent staff of the @startid
  /// (mirrors `IsOnStaff`).
  bool isOnStaff(int n) {
    final List<int>? staffList = staff;
    if (staffList != null) {
      for (final int staffN in staffList) {
        if (staffN == n) return true;
      }
      return false;
    } else if (start != null) {
      final staff = start!.getFirstAncestor(ClassId.staff) as Staff?;
      if (staff != null && (staff.n ?? meiUnset) == n) return true;
    }
    return false;
  }

  /// Mirrors `TimePointInterface::GetTstampStaves` (timeinterface.cpp:123).
  ///
  /// Returns the staves for a time-pointing element, looking at `@staff`,
  /// `@part="%all"` and the ancestor of `@startid` as in the C++.
  List<Staff> getTstampStaves(Measure measure, Object object) {
    final List<Staff> staves = [];
    final List<int> staffList = [];

    // For <f> within <harm> without @staff we try to get the @staff from the <harm> ancestor
    // (C++ `object->Is(FIGURE)`, timeinterface.cpp:132 — FIGURE ↔ Dart ClassId.f)
    if (object.isClass(ClassId.f) && !hasStaff) {
      final harm = object.getFirstAncestor(ClassId.harm);
      if (harm != null && harm is AttStaffIdent) {
        final List<int>? harmStaff = (harm as AttStaffIdent).staff;
        if (harmStaff != null) staffList.addAll(harmStaff);
      }
    } else if (hasPart && part == '%all') {
      // For control elements with `@part="%all"`, use the top visible staff
      // independently from the `@staff`.
      final System? system = measure.getFirstAncestor(ClassId.system) as System?;
      final Staff? top = system?.getTopVisibleStaff(false);
      if (top?.n != null) staffList.add(top!.n!);
    } else if (hasStaff) {
      bool isInBetween = false;
      if (object.isAny(const {
        ClassId.dynam,
        ClassId.dir,
        ClassId.hairpin,
        ClassId.tempo,
      })) {
        isInBetween =
            (object as AttPlacementRelStaff).place == Staffrel.between;
      }
      if (isInBetween) {
        final List<int>? s = staff;
        if (s != null && s.isNotEmpty) staffList.add(s.first);
      } else {
        final List<int>? s = staff;
        if (s != null) staffList.addAll(s);
      }
    } else if (start != null &&
        !start!.isClass(ClassId.barLine) &&
        !start!.isClass(ClassId.timestampAttr)) {
      final Staff? st = start!.getFirstAncestor(ClassId.staff) as Staff?;
      if (st != null && st.n != null) staffList.add(st.n!);
    } else {
      // If we have no @staff or startid but only one staff child assume it is the first one
      final List<Object> allStaves =
          measure.findAllDescendantsByType(ClassId.staff, deepness: 1);
      if (allStaves.length == 1) {
        final Staff? st = allStaves.first as Staff?;
        if (st != null && st.n != null) staffList.add(st.n!);
      }
    }

    for (final int staffN in staffList) {
      final Object? found = measure.findDescendantByComparison(
          AttNIntegerComparison(ClassId.staff, staffN),
          deepness: 1);
      if (found == null || found is! Staff) continue;
      if (!found.drawingIsVisible()) continue;
      staves.add(found);
    }
    return staves;
  }

  /// Copies the interface state from [other].
  void copyTimePointFrom(covariant TimePointInterface other) {
    part = other.part;
    partstaff = other.partstaff;
    staff = other.staff == null ? null : [...other.staff!];
    startid = other.startid;
    tstamp = other.tstamp;
    start = other.start;
    startID = other.startID;
  }
}

/// This class is an interface for spanning elements, such as slur, hairpin,
/// etc. (mirrors `vrv::TimeSpanningInterface`).
///
/// Apply together with [TimePointInterface], [AttStartEndId] and
/// [AttTimestamp2Log].
mixin TimeSpanningInterface
    on TimePointInterface, AttStartEndId, AttTimestamp2Log
    implements Interface {
  /// The resolved @endid element.
  LayerElement? end;

  /// The fragment of the @endid attribute.
  String endID = '';

  @override
  InterfaceId get interfaceId => InterfaceId.timeSpanning;

  @override
  void reset() {
    super.reset();
    endid = null;
    tstamp2 = null;

    end = null;
    endID = '';
  }

  /// Set the second LayerElement. Asserts that none was previously set.
  void setEnd(LayerElement element) {
    assert(end == null);
    end = element;
  }

  /// Set both start and end when they are the same element (e.g., @plist
  /// resolution); returns true on success.
  bool setStartAndEnd(LayerElement element) {
    final bool okStart = (start == null);
    final bool okEnd = (end == null);
    if (okStart) setStart(element);
    if (okEnd) setEnd(element);
    return okStart && okEnd;
  }

  /// Return true if both start and end are given and resolved.
  bool get hasStartAndEnd => start != null && end != null;

  /// Return the resolved start element (mirrors `TimePointInterface::GetStart`).
  @override
  LayerElement? getStart() => start;

  /// Return the resolved end element (mirrors `GetEnd`).
  @override
  LayerElement? getEnd() => end;

  /// Return the end measure of the TimeSpanningInterface (mirrors
  /// `GetEndMeasure`).
  Measure? getEndMeasure() {
    if (end == null) return null;
    return end!.getFirstAncestor(ClassId.measure) as Measure?;
  }

  /// Return true if the element is spanning over two or more measures
  /// (mirrors `IsSpanningMeasures`).
  bool isSpanningMeasures() {
    if (!hasStartAndEnd) return false;
    final Measure? startMeasure = getStartMeasure();
    final Measure? endMeasure = getEndMeasure();
    return !identical(startMeasure, endMeasure);
  }

  /// Mirrors `TimeSpanningInterface::IsOrdered` (timeinterface.cpp).
  /// Returns true if start temporally precedes end; for the Dart port we
  /// check that both exist and are not the same object (the C++ checks
  /// timestamps via `IsOrdered(start, end)`).
  bool isOrdered() => hasStartAndEnd && !identical(start, end);

  /// Mirrors `TimeSpanningInterface::IsOrdered(start, end)` overload
  /// (timeinterface.cpp:270) — start temporally precedes end: within the same
  /// measure the alignment order decides, across measures the measure index.
  bool isOrderedWith(Object? s, Object? e) {
    if (s is! LayerElement || e is! LayerElement) return true;
    final Measure? startMeasure = s.getFirstAncestor(ClassId.measure) as Measure?;
    final Measure? endMeasure = e.getFirstAncestor(ClassId.measure) as Measure?;
    if (identical(startMeasure, endMeasure)) {
      final Alignment? sa = s.getAlignment();
      final Alignment? ea = e.getAlignment();
      if (sa == null || ea == null) return true;
      return Object.isPreOrdered(sa, ea);
    } else {
      if (startMeasure == null || endMeasure == null) return true;
      return startMeasure.index < endMeasure.index;
    }
  }

  /// Copies the interface state from [other].
  void copyTimeSpanningFrom(covariant TimeSpanningInterface other) {
    copyTimePointFrom(other);
    endid = other.endid;
    tstamp2 = other.tstamp2;
    end = other.end;
    endID = other.endID;
  }

  /// Extract the fragments of the @startid/@endid.
  @override
  void setIDStr() {
    super.setIDStr();
    if (hasEndid && endid != null) {
      endID = extractIDFragment(endid!);
    }
  }
}
