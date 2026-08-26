/// Port of `timeinterface.h/cpp` — TimePointInterface and
/// TimeSpanningInterface.
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/utils.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Measure, Staff;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';

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
  Object? start;

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
  void setStart(Object element) {
    assert(start == null);
    start = element;
  }

  /// Set the first LayerElement by verifying it is the expected one.
  bool setStartOnly(Object element) {
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
  Object? getStart() => start;

  /// Return the resolved end element for spanning interfaces; null here
  /// (overridden by [TimeSpanningInterface]).
  Object? getEnd() => null;

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
  Object? end;

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
  void setEnd(Object element) {
    assert(end == null);
    end = element;
  }

  /// Set both start and end when they are the same element (e.g., @plist
  /// resolution); returns true on success.
  bool setStartAndEnd(Object element) {
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
  Object? getStart() => start;

  /// Return the resolved end element (mirrors `GetEnd`).
  @override
  Object? getEnd() => end;

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
