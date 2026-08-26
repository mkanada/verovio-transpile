/// Port of `comparison.h` — the Comparison framework used by the object
/// searches (`FindDescendantByComparison` and friends).
///
/// Comparators that depend on the layout infrastructure (Alignment types,
/// measure onset/offset times) are ported with the layout phase.
library;

import 'package:meta/meta.dart' show protected;
import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart'
    show AttFormework, AttNInteger, AttNNumberLike, AttVisibility;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart';

/// Mirrors `vrv::DurExtreme`.
enum DurExtreme { longest, shortest }

/// Base class of all comparisons (mirrors `vrv::Comparison`).
abstract class Comparison {
  bool call(Object object);

  /// For classes that do a reverse comparison, return reversed result.
  bool result(bool comparison) => _reverse ? !comparison : comparison;

  /// Set reverse comparison. Only possible for classes that allow it
  /// explicitly (assertion).
  void reverseComparison() {
    assert(_supportReverse);
    _reverse = true;
  }

  /// Set to true in the constructor of classes that allow reversing.
  bool _supportReverse = false;
  bool _reverse = false;

  @protected
  void supportsReverse() => _supportReverse = true;
}

/// Evaluates if the object is of a given ClassId (mirrors
/// `vrv::ClassIdComparison`).
class ClassIdComparison extends Comparison {
  ClassIdComparison(this.classId) {
    supportsReverse();
  }

  final ClassId classId;

  @override
  bool call(Object object) => result(matchesType(object));

  bool matchesType(Object object) =>
      classId == ClassId.unspecified || object.classId == classId;
}

/// Evaluates if the object is one of several ClassIds (mirrors
/// `vrv::ClassIdsComparison`).
class ClassIdsComparison extends Comparison {
  ClassIdsComparison(List<ClassId> classIds)
      : classIds = List<ClassId>.unmodifiable(classIds) {
    supportsReverse();
  }

  final List<ClassId> classIds;

  @override
  bool call(Object object) => result(matchesType(object));

  bool matchesType(Object object) => classIds.contains(object.classId);
}

/// Evaluates if the object has a given interface (mirrors
/// `vrv::InterfaceComparison`).
class InterfaceComparison extends Comparison {
  InterfaceComparison(this.interfaceId);

  final InterfaceId interfaceId;

  @override
  bool call(Object object) => object.hasInterface(interfaceId);
}

/// Evaluates if the parent of the object is of a given ClassId (mirrors
/// `vrv::ChildOfClassIdComparison`).
class ChildOfClassIdComparison extends Comparison {
  ChildOfClassIdComparison(this.classId);

  final ClassId classId;

  @override
  bool call(Object object) =>
      object.parent != null && object.parent!.classId == classId;
}

/// Evaluates TimePointInterface elements pointing to [pointingTo] via their
/// resolved @startid (mirrors `vrv::PointingToComparison`).
class PointingToComparison extends ClassIdComparison {
  PointingToComparison(super.classId, this.pointingTo);

  final Object? pointingTo;

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    // Note: explicit casts are required here (mixins with `on` constraints
    // are not valid promotion targets).
    if (object is! TimePointInterface) return false;
    final TimePointInterface interface = object as TimePointInterface;
    return interface.start == pointingTo;
  }
}

/// Evaluates TimeSpanningInterface elements ending at [pointingTo] via
/// their resolved @endid (mirrors `vrv::SpanningToComparison`).
class SpanningToComparison extends ClassIdComparison {
  SpanningToComparison(super.classId, this.pointingTo);

  final Object? pointingTo;

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    if (object is! TimeSpanningInterface) return false;
    final TimeSpanningInterface interface = object as TimeSpanningInterface;
    return interface.end == pointingTo;
  }
}

/// Evaluates if the object is an editorial element (mirrors
/// `vrv::IsEditorialElementComparison`).
class IsEditorialElementComparison extends Comparison {
  IsEditorialElementComparison() {
    supportsReverse();
  }

  @override
  bool call(Object object) => result(object.isEditorialElement);
}

/// Evaluates if the object is of a certain ClassId and is empty (mirrors
/// `vrv::IsEmptyComparison`).
class IsEmptyComparison extends ClassIdComparison {
  IsEmptyComparison(super.classId) {
    supportsReverse();
  }

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    return result(object.childCount == 0);
  }
}

/// Evaluates if the object is of a certain ClassId and represents an
/// attribute in the original MEI (mirrors `vrv::IsAttributeComparison`).
class IsAttributeComparison extends ClassIdComparison {
  IsAttributeComparison(super.classId);

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    return object.isAttribute;
  }
}

/// Evaluates if the object is of a certain ClassId with @n of value [n]
/// (mirrors `vrv::AttNIntegerComparison`).
class AttNIntegerComparison extends ClassIdComparison {
  AttNIntegerComparison(super.classId, this.n);

  int n;

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    // This should not happen, but just in case.
    if (object is! AttNInteger) return false;
    final AttNInteger element = object as AttNInteger;
    return element.n == n;
  }
}

/// Evaluates if the object is of a certain ClassId with @n within [ns]
/// (mirrors `vrv::AttNIntegerAnyComparison`).
class AttNIntegerAnyComparison extends ClassIdComparison {
  AttNIntegerAnyComparison(super.classId, List<int> ns) : ns = [...ns];

  List<int> ns;

  void setNs(List<int> value) => ns = [...value];
  void appendN(int value) => ns.add(value);

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    // This should not happen, but just in case.
    if (object is! AttNInteger) return false;
    final AttNInteger element = object as AttNInteger;
    return ns.contains(element.n);
  }
}

/// Evaluates if the object is of a certain ClassId with a string @n
/// (mirrors `vrv::AttNNumberLikeComparison`).
class AttNNumberLikeComparison extends ClassIdComparison {
  AttNNumberLikeComparison(super.classId, this.n);

  String n;

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    // This should not happen, but just in case.
    if (object is! AttNNumberLike) return false;
    final AttNNumberLike element = object as AttNNumberLike;
    return element.n == n;
  }
}

/// Evaluates if the object has the extreme duration so far; the object must
/// have a DurationInterface and a @dur. Looks for [extremeType] (mirrors
/// `vrv::AttDurExtremeComparison`).
class AttDurExtremeComparison extends Comparison {
  AttDurExtremeComparison(this.extremeType)
      : extremeDur = (extremeType == DurExtreme.longest) ? -meiUnset : meiUnset;

  final DurExtreme extremeType;
  int extremeDur;

  @override
  bool call(Object object) {
    if (object is! DurationInterface) return false;
    final DurationInterface interface = object as DurationInterface;
    if (interface.hasDur) {
      final int actualDur = interface.getActualDur().value;
      if ((extremeType == DurExtreme.longest) && (actualDur < extremeDur)) {
        extremeDur = actualDur;
        return true;
      } else if ((extremeType == DurExtreme.shortest) &&
          (actualDur > extremeDur)) {
        extremeDur = actualDur;
        return true;
      }
    }
    return false;
  }
}

/// Evaluates if the object is of a certain ClassId and visible (mirrors
/// `vrv::AttVisibilityComparison`).
class AttVisibilityComparison extends ClassIdComparison {
  AttVisibilityComparison(super.classId, this.isVisible);

  final bool? isVisible;

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    // The object must apply AttVisibility.
    if (object is! AttVisibility) return false;
    final AttVisibility visibility = object as AttVisibility;
    return visibility.visible == isVisible;
  }
}

/// Evaluates if the object is of a certain ClassId with a @func of value
/// [func] (mirrors `vrv::AttFormeworkComparison`).
class AttFormeworkComparison extends ClassIdComparison {
  AttFormeworkComparison(super.classId, this.func);

  final Pgfunc? func;

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    // This should not happen, but just in case.
    if (object is! AttFormework) return false;
    final AttFormework element = object as AttFormework;
    return element.func == func;
  }
}

/// Evaluates if the alignment reference contains cross-staff elements
/// (mirrors `vrv::CrossAlignmentReferenceComparison`).
class CrossAlignmentReferenceComparison extends ClassIdComparison {
  CrossAlignmentReferenceComparison() : super(ClassId.alignmentReference);

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    return (object as dynamic).hasCrossStaffElements() as bool;
  }
}

/// Evaluates if the object is of a certain ClassId and has a certain id
/// (mirrors `vrv::IDComparison`).
class IDComparison extends ClassIdComparison {
  IDComparison(super.classId, this.id);

  String id;

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    return object.id == id;
  }
}

/// Evaluates if the object is an Alignment of a certain type (mirrors
/// `vrv::MeasureAlignerTypeComparison`).
///
/// Deviation: the C++ casts to `Alignment *`; here the accessor is resolved
/// dynamically to avoid an import cycle with the aligner library.
class MeasureAlignerTypeComparison extends ClassIdComparison {
  MeasureAlignerTypeComparison(this.type) : super(ClassId.alignment);

  AlignmentType type;

  @override
  bool call(Object object) {
    if (!matchesType(object)) return false;
    final dynamic alignment = object;
    return alignment.getType() as AlignmentType == type;
  }
}

/// Evaluates if the object is a visible StaffDef or StaffGrp, excluding an
/// optional object (mirrors `vrv::VisibleStaffDefOrGrpObject`).
class VisibleStaffDefOrGrpObject extends ClassIdsComparison {
  VisibleStaffDefOrGrpObject()
      : super(const [ClassId.staffDef, ClassId.staffGrp]);

  Object? _objectToExclude;

  void skip(Object objectToExclude) => _objectToExclude = objectToExclude;

  @override
  bool call(Object object) {
    if (identical(object, _objectToExclude) || !super.call(object)) {
      return false;
    }

    VisibilityOptimization visibility;
    if (object is StaffDef) {
      visibility = object.getDrawingVisibility();
    } else if (object is StaffGrp) {
      visibility = object.drawingVisibility;
    } else {
      return false;
    }
    return visibility != VisibilityOptimization.hidden;
  }
}

// TODO(layout): MeasureAlignerTypeComparison and MeasureOnsetOffsetComparison
// arrive with the horizontal aligner (Phase 4); NoteOrRestOnsetOffsetComparison
// arrives once note onsets are calculated by the MIDI functors.

/// Stores comparison filters and applies them when necessary (mirrors
/// `vrv::Filters`).
class Filters {
  Filters() : filters = [];

  Filters.of(List<Comparison> comps) : filters = [...comps];

  final List<Comparison> filters;
  FiltersType type = FiltersType.allOf;

  void add(Comparison comp) => filters.add(comp);
  void clear() => filters.clear();
  void setType(FiltersType value) => type = value;

  /// Apply the comparison filter based on the specified type (mirrors
  /// `Filters::Apply`). Class-id based comparisons that do not match the
  /// object class are ignored.
  bool apply(Object object) {
    bool condition(Comparison iter) {
      // Ignore any class comparison which does not match the object class.
      if (iter is ClassIdComparison && iter.classId != object.classId) {
        return true;
      }
      return iter(object);
    }

    switch (type) {
      case FiltersType.anyOf:
        return filters.any(condition);
      case FiltersType.allOf:
        return filters.every(condition);
    }
  }
}

/// Mirrors `Filters::Type`.
enum FiltersType { allOf, anyOf }
