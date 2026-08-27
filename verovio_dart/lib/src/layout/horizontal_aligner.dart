/// Port of `horizontalaligner.h/cpp` — the horizontal alignment classes.
///
/// This library contains:
/// - [Alignment]: an alignment position elements point to
/// - [AlignmentReference]: a reference group of LayerElements for one staff
/// - [HorizontalAligner]: the base class holding [Alignment] children
/// - [MeasureAligner]: the aligner of a measure (owned by [Measure])
/// - [GraceAligner]: the aligner of a grace note group (owned by Alignment)
/// - [TimestampAligner]: the store of TimestampAttr of a measure
///
/// It also ports two helpers whose C++ homes are related but different:
/// `AlignMeterParams` (alignfunctor.h) and the non-virtual
/// `LayerElement::GetAlignmentDuration` family (layerelement.cpp) provided as
/// an extension, since they are required by the aligners themselves
/// (`GraceAligner::AlignStack`) and by the aligner-filling functors.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration, meiUnset;
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart' show Functor;
import 'package:verovio_dart/src/model/atts/atts_shared.dart' show AttNInteger;
import 'package:verovio_dart/src/core/options_shell.dart' show Options;
import 'package:verovio_dart/src/core/smufl.dart' show smuflE0A4NoteheadBlack;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Layer, Measure, Staff;
import 'package:verovio_dart/src/model/comparison.dart'
    show AttNIntegerComparison, ClassIdsComparison, Filters;
import 'package:verovio_dart/src/model/doc.dart' show Doc;
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart'
    show DurationInterface, MensurValues;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Notationtype;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show TimestampAttr;
import 'package:verovio_dart/src/model/object.dart';

/// Mirrors `BARLINE_REFERENCES`.
const int barlineReferences = -1;

/// Mirrors `TSTAMP_REFERENCES`.
const int tstampReferences = -2;

/// Mirrors `vrv::ApproximatelyEqual` (vrv.cpp).
bool approximatelyEqual(double firstVal, double secondVal) =>
    (firstVal - secondVal).abs() < 1E-3;

// Large spacing between syllables is a quarter note space (mirrors
// `NEUME_LARGE_SPACE`, layerelement.cpp:78).
final Fraction kNeumeLargeSpace = Fraction(1, 4);
// Medium spacing between neume is an 8th note space (mirrors
// `NEUME_MEDIUM_SPACE`, layerelement.cpp:80).
final Fraction kNeumeMediumSpace = Fraction(1, 8);
// Small spacing between neume components is a 16th note space (mirrors
// `NEUME_SMALL_SPACE`, layerelement.cpp:82).
final Fraction kNeumeSmallSpace = Fraction(1, 16);

// ---------------------------------------------------------------------------
// Alignment
// ---------------------------------------------------------------------------

/// This class stores an alignment position elements will point to (mirrors
/// `vrv::Alignment`).
class Alignment extends Object implements Comparable<Alignment> {
  /// Mirrors `Alignment()` / `Alignment(const Fraction&, AlignmentType)`.
  Alignment([Fraction? time, AlignmentType? type]) : super(ClassId.alignment) {
    reset();
    if (time != null) setTime(time);
    if (type != null) setType(type);
  }

  /// Stores the position relative to the measure. Instanciated by the
  /// CalcAlignmentXPosFunctor (mirrors `m_xRel`).
  int _xRel = 0;

  /// Stores the time at which the alignment occurs; set by the alignment
  /// functor (mirrors `m_time`).
  Fraction _time = Fraction(0);

  /// The alignment type (mirrors `m_type`).
  AlignmentType _type = AlignmentType.default_;

  /// A map of GraceAligners if any. The Alignment owns them (mirrors
  /// `m_graceAligners`).
  final Map<int, GraceAligner> _graceAligners = {};

  @override
  ClassId get classId => ClassId.alignment;

  @override
  String get className => 'alignment';

  @override
  void reset() {
    super.reset();
    _xRel = 0;
    _time = Fraction(0);
    _type = AlignmentType.default_;
    clearGraceAligners();
  }

  @override
  String logDebugTreeMsg() => '${getXRel()} ${getTime().toDouble()}';

  /// Delete the grace aligners in the map (mirrors `ClearGraceAligners`).
  void clearGraceAligners() => _graceAligners.clear();

  @override
  bool isSupportedChild(ClassId classId) {
    // Nothing to check here
    return true;
  }

  /// Set the xRel value of the alignment (mirrors `SetXRel`).
  void setXRel(int xRel) {
    resetCachedDrawingX();
    _xRel = xRel;
  }

  /// Get the xRel value of the alignment (mirrors `GetXRel`).
  int getXRel() => _xRel;

  /// Set the time value of the alignment (mirrors `SetTime`).
  void setTime(Fraction time) => _time = time;

  /// Get the time value of the alignment (mirrors `GetTime`).
  Fraction getTime() => _time;

  /// Set the type of the alignment (mirrors `SetType`).
  void setType(AlignmentType type) => _type = type;

  /// Get the type of the alignment (mirrors `GetType`).
  AlignmentType getType() => _type;

  /// Weak ordering of alignments: for alignments in the same measure it is
  /// based on time, otherwise on the measure order (mirrors `operator<=>`).
  @override
  int compareTo(Alignment other) {
    final Object? measure = getFirstAncestor(ClassId.measure);
    final Object? otherMeasure = other.getFirstAncestor(ClassId.measure);
    assert(measure != null && otherMeasure != null);
    if (identical(measure, otherMeasure)) {
      return getTime().compareTo(other.getTime());
    } else {
      return Object.isPreOrdered(measure!, otherMeasure!) ? -1 : 1;
    }
  }

  /// Equality within the same measure (mirrors `operator==`).
  bool equalsInMeasure(Alignment other) {
    final Object? measure = getFirstAncestor(ClassId.measure);
    final Object? otherMeasure = other.getFirstAncestor(ClassId.measure);
    return identical(measure, otherMeasure) && getTime() == other.getTime();
  }

  /// Add the LayerElement to the appropriate AlignmentReference child.
  ///
  /// Looks at the cross-staff situation (@staff or parent @staff). Return
  /// true if the AlignmentReference holds more than one layer (mirrors
  /// `AddLayerElementRef`).
  bool addLayerElementRef(LayerElement element) {
    assert(element.isLayerElement);

    // 0 will be used for barlines attributes or timestamps
    int layerN = 0;

    // -1 will be used for barlines attributes
    int staffN = barlineReferences;

    // -2 will be used for timestamps
    if (element.classId == ClassId.timestampAttr) {
      staffN = tstampReferences;
    } else {
      final Staff? crossStaffRef =
          element.crossStaff is Staff ? element.crossStaff as Staff : null;
      // We have a cross-staff situation. For grace notes, we want to keep the
      // original staffN because they need to be aligned together.
      if (crossStaffRef != null && !element.isGraceNote()) {
        final Layer? layerRef =
            element.crossLayer is Layer ? element.crossLayer as Layer : null;
        // We set cross-staff layers to the negative value in the alignment
        // references in order to distinct them
        layerN = -(layerRef?.n ?? 0);
        staffN = crossStaffRef.n ?? 0;
      }
      // Non cross staff normal case
      else {
        final layerRef = element.getFirstAncestor(ClassId.layer) as Layer?;
        final staffRef = layerRef?.getFirstAncestor(ClassId.staff) as Staff?;
        if (staffRef != null && layerRef != null) {
          layerN = layerRef.n ?? 0;
          staffN = staffRef.n ?? 0;
        }
        // staffN and layerN remain unused for barLine attributes
      }
    }
    final AlignmentReference alignmentRef = getAlignmentReference(staffN);
    element.setAlignmentLayerN(layerN);
    alignmentRef.addChild(element);

    return alignmentRef.hasMultipleLayer();
  }

  /// Check if the element is of one of the types (mirrors `IsOfType`).
  bool isOfType(List<AlignmentType> types) => types.contains(_type);

  /// Retrieve the minimum left and maximum right position for the objects in
  /// an alignment for one staff ([staffN] or [meiUnset] for all staves).
  ///
  /// Returns (-)[meiUnset] / [meiUnset] when there is nothing for the staff
  /// specified. Internally uses the GetAlignmentLeftRightFunctor (mirrors
  /// `GetLeftRight`).
  (int minLeft, int maxRight) getLeftRight(int staffN,
      {List<ClassId> excludes = const []}) {
    final functor = _GetAlignmentLeftRightFunctor();
    functor.excludeClasses = excludes;

    if (staffN != meiUnset) {
      final filters = Filters();
      filters.add(AttNIntegerComparison(ClassId.alignmentReference, staffN));
      functor.setFilters(filters);
      process(functor);
    } else {
      process(functor);
    }

    return (functor.minLeft, functor.maxRight);
  }

  /// Retrieve the minimum left and maximum right position over several staves
  /// (mirrors the `std::vector<int>` overload of `GetLeftRight`).
  (int minLeft, int maxRight) getLeftRightForStaffNs(List<int> staffNs,
      {List<ClassId> excludes = const []}) {
    int minLeft = -meiUnset;
    int maxRight = meiUnset;
    for (final int staffN in staffNs) {
      final (staffMinLeft, staffMaxRight) =
          getLeftRight(staffN, excludes: excludes);
      minLeft = math.min(minLeft, staffMinLeft);
      maxRight = math.max(maxRight, staffMaxRight);
    }
    return (minLeft, maxRight);
  }

  /// Return all GraceAligners for the Alignment (mirrors `GetGraceAligners`).
  Map<int, GraceAligner> getGraceAligners() => _graceAligners;

  /// Returns the GraceAligner for the Alignment; create it if necessary
  /// (mirrors `GetGraceAligner`).
  GraceAligner getGraceAligner(int id) {
    return _graceAligners.putIfAbsent(id, () => GraceAligner());
  }

  /// Returns true if the aligner has a GraceAligner (mirrors
  /// `HasGraceAligner`).
  bool hasGraceAligner(int id) => _graceAligners.containsKey(id);

  /// Returns true for Alignment for which we want to do bounding box
  /// alignment (mirrors `PerformBoundingBoxAlignment`).
  bool performBoundingBoxAlignment() => isOfType(
      [AlignmentType.accid, AlignmentType.dot, AlignmentType.default_]);

  /// Retrieve the AlignmentReference with [staffN]; create and add it as
  /// child if not found (mirrors `GetAlignmentReference`).
  AlignmentReference getAlignmentReference(int staffN) {
    final matchStaff =
        AttNIntegerComparison(ClassId.alignmentReference, staffN);
    AlignmentReference? alignmentRef =
        findDescendantByComparison(matchStaff, deepness: 1)
            as AlignmentReference?;
    if (alignmentRef == null) {
      alignmentRef = AlignmentReference(staffN);
      addChild(alignmentRef);
    }
    return alignmentRef;
  }

  /// Return true if the alignment contains at least one reference with
  /// staffN (mirrors `HasAlignmentReference`).
  bool hasAlignmentReference(int staffN) {
    final matchStaff =
        AttNIntegerComparison(ClassId.alignmentReference, staffN);
    return findDescendantByComparison(matchStaff, deepness: 1) != null;
  }

  /// Return true if the alignment contains only references to timestamp
  /// attributes (mirrors `HasTimestampOnly`).
  bool hasTimestampOnly() {
    // If no child, then not timestamp
    if (childCount == 0) return false;
    // Look for everything that is not a timestamp
    final notTimestamp = ClassIdsComparison([
      ClassId.alignment,
      ClassId.alignmentReference,
      ClassId.timestampAttr,
    ]);
    notTimestamp.reverseComparison();
    return findDescendantByComparison(notTimestamp, deepness: 2) == null;
  }

  /// Return the AlignmentReference holding the element.
  ///
  /// If staffN is provided, uses the AlignmentReference n to accelerate the
  /// search (mirrors `GetReferenceWithElement`). Note: like the C++
  /// implementation, the last reference is returned when none matches.
  AlignmentReference? getReferenceWithElement(LayerElement element,
      [int staffN = meiUnset]) {
    AlignmentReference? reference;
    for (final Object child in children) {
      if (child is! AlignmentReference) continue;
      reference = child;
      if (reference.n == staffN) {
        return reference;
      } else if (staffN == meiUnset) {
        if (child.hasDescendant(element, 1)) return reference;
      }
    }
    return reference;
  }

  /// Return pair of max and min Y value within alignment. Elements will be
  /// counted by alignment references (mirrors `GetAlignmentTopBottom`).
  (int bottom, int top) getAlignmentTopBottom() {
    int max = meiUnset, min = meiUnset;
    // Iterate over each element in each alignment reference and find max/min
    // Y value - these will serve as top/bottom values for the Alignment.
    for (final Object child in children) {
      final AlignmentReference? reference =
          child is AlignmentReference ? child : null;
      if (reference == null) continue;
      for (final Object element in reference.children) {
        final BoundingBox box = element as BoundingBox;
        final int top = box.getSelfTop();
        if ((meiUnset == max) || (top > max)) {
          max = top;
        }
        final int bottom = box.getSelfBottom();
        if ((meiUnset == min) || (bottom < min)) {
          min = bottom;
        }
      }
    }
    return (min, max);
  }

  /// Return true if there is vertical overlap with accidentals from another
  /// alignment for specific staffN (mirrors `HasAccidVerticalOverlap`).
  bool hasAccidVerticalOverlap(Alignment? otherAlignment, int staffN) {
    if (otherAlignment == null) return false;

    final matchStaff =
        AttNIntegerComparison(ClassId.alignmentReference, staffN);
    // get alignment references for both alignments
    final currentRef = findDescendantByComparison(matchStaff, deepness: 1)
        as AlignmentReference?;
    final otherRef = otherAlignment.findDescendantByComparison(matchStaff,
        deepness: 1) as AlignmentReference?;
    if (currentRef == null || otherRef == null) return false;

    return otherRef.hasAccidVerticalOverlap(currentRef.children);
  }

  //----------------//
  // Static methods //
  //----------------//

  /// Compute "ideal" horizontal space to allow for a given time interval,
  /// ignoring the need to keep consecutive symbols from overlapping (mirrors
  /// `HorizontalSpaceForDuration`).
  ///
  /// See Elaine Gould, _Behind Bars_, p. 39 for a discussion of the way
  /// engravers determine spacing. The numbers are experimental constants.
  static int horizontalSpaceForDuration(Fraction intervalTime,
      MeiDuration maxActualDur, double spacingLinear, double spacingNonLinear) {
    double intervalTimeDbl = intervalTime.toDouble();
    /* If the longest duration interval in the score is longer than
     semibreve, adjust spacing so that interval gets the space a semibreve
     would ordinarily get. */
    if (maxActualDur.value < MeiDuration.dur1.value) {
      intervalTimeDbl /= math.pow(
          2.0, (MeiDuration.dur1.value - maxActualDur.value).toDouble());
    }

    return (math.pow(intervalTimeDbl * 1024, spacingNonLinear) *
            spacingLinear *
            10.0)
        .toInt(); // numbers are experimental constants
  }
}

/// Port of `GetAlignmentLeftRightFunctor` (miscfunctor.h/cpp): retrieves the
/// minimum left and maximum right of the layer elements of an alignment.
class _GetAlignmentLeftRightFunctor extends Functor {
  int minLeft = -meiUnset;
  int maxRight = meiUnset;

  List<ClassId> excludeClasses = [];

  @override
  FunctorCode visitObject(Object object) {
    if (!object.isLayerElement) return FunctorCode.continue_;

    if (!object.hasSelfBB() || object.hasEmptyBB()) {
      return FunctorCode.continue_;
    }

    if (excludeClasses.contains(object.classId)) return FunctorCode.continue_;

    minLeft = math.min(minLeft, object.getSelfLeft());
    maxRight = math.max(maxRight, object.getSelfRight());

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// AlignmentReference
// ---------------------------------------------------------------------------

/// This class stores references of LayerElements for a staff.
///
/// The staff identification (@n) is given by the attCommon and takes into
/// account cross-staff situations. Its children of the alignment are
/// references (mirrors `vrv::AlignmentReference`).
class AlignmentReference extends Object with AttNInteger {
  /// Mirrors `AlignmentReference()` / `AlignmentReference(int staffN)`.
  AlignmentReference([int? staffN]) : super(ClassId.alignmentReference) {
    reset();
    setAsReferenceObject();
    if (staffN != null) n = staffN;
  }

  int _layerCount = 0;

  @override
  ClassId get classId => ClassId.alignmentReference;

  @override
  String get className => 'alignmentReference';

  @override
  void reset() {
    super.reset();
    n = null;
    _layerCount = 0;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Nothing to check here
    return true;
  }

  /// Overwritten method for AlignmentReference children (mirrors `AddChild`).
  ///
  /// Special case: the parent is not set because the reference will not have
  /// ownership; children are treated as relinquished objects.
  @override
  bool addChild(Object child) {
    final LayerElement childElement = child as LayerElement;

    final List<Object> childrenList = childrenForModification;

    if (!childElement.hasSameasLink) {
      // Check if we will have a reference with multiple layers
      var found = false;
      for (final Object element in childrenList) {
        if ((element as LayerElement).getAlignmentLayerN() ==
            childElement.getAlignmentLayerN()) {
          found = true;
          break;
        }
      }
      if (!found) _layerCount++;
    }

    // However, we need to make sure the child has a parent (somewhere else)
    assert(child.parent != null && isReferenceObject);
    childrenList.add(child);
    modify();

    return true;
  }

  /// Return true if the reference has elements from multiple layers (mirrors
  /// `HasMultipleLayer`).
  bool hasMultipleLayer() => _layerCount > 1;

  /// Return true if one of the objects overlaps with accidentals from the
  /// current reference (mirrors `HasAccidVerticalOverlap`).
  bool hasAccidVerticalOverlap(List<Object> objects) {
    for (final Object child in children) {
      if (child.classId != ClassId.accid) continue;
      final accid = child as dynamic;
      // Skip accidentals without actual accidental value.
      if (!(accid.hasAccid as bool)) continue;
      for (final Object object in objects) {
        if (child.verticalContentOverlap(object)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Return true if the reference has elements from cross-staff (mirrors
  /// `HasCrossStaffElements`).
  bool hasCrossStaffElements() {
    final childrenList = findAllDescendantsByClassIdPredicate(
        (ClassId classId) =>
            classId == ClassId.note || classId == ClassId.chord);
    for (final Object child in childrenList) {
      if ((child as LayerElement).crossStaff != null) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// HorizontalAligner
// ---------------------------------------------------------------------------

/// This class aligns the content horizontally.
///
/// It contains a vector of Alignment. It is not an abstract class but it
/// should not be instanciated directly (mirrors `vrv::HorizontalAligner`).
///
/// Deviation: the C++ base class does not override `IsSupportedChild`
/// (only MeasureAligner does, returning true); here it is overridden once so
/// alignments can be added by any derived aligner (required by
/// GraceAligner::GetAlignmentAtTime).
class HorizontalAligner extends Object {
  HorizontalAligner(super.classId) {
    reset();
  }

  @override
  String get className => 'horizontalAligner';

  /// Do not copy children for HorizontalAligner (mirrors `CopyChildren`).
  @override
  bool copyChildren() => false;

  @override
  bool isSupportedChild(ClassId classId) => true;

  int getAlignmentCount() => childCount;

  /// Search if an alignment of the type is already there at the time.
  ///
  /// Returns the alignment (or null) and the index where a new alignment
  /// needs to be inserted (-1 if it is the end). Mirrors
  /// `SearchAlignmentAtTime`.
  (Alignment?, int idx) searchAlignmentAtTime(
      Fraction time, AlignmentType type) {
    int idx = -1; // the index if we reach the end.
    // First try to see if we already have something at the time position
    for (int i = 0; i < getAlignmentCount(); ++i) {
      final alignment = getChild(i) as Alignment;
      final Fraction alignmentTime = alignment.getTime();
      if (alignmentTime == time) {
        if (alignment.getType() == type) {
          return (alignment, i);
        } else if (alignment.getType().value > type.value) {
          idx = i;
          break;
        }
      }
      // nothing found, do not go any further but keep the index
      if (alignment.getTime() > time) {
        idx = i;
        break;
      }
    }
    return (null, idx);
  }

  /// Add an alignment at the appropriate position (at the end if -1)
  /// (mirrors `AddAlignment`).
  void addAlignment(Alignment alignment, [int idx = -1]) {
    if (idx == -1) {
      addChild(alignment);
    } else {
      insertChild(alignment, idx);
    }
  }
}

// ---------------------------------------------------------------------------
// MeasureAligner
// ---------------------------------------------------------------------------

/// This class aligns the content of a measure.
///
/// It contains a vector of Alignment (mirrors `vrv::MeasureAligner`).
class MeasureAligner extends HorizontalAligner {
  MeasureAligner() : super(ClassId.measureAligner) {
    _leftAlignment = null;
    _leftBarLineAlignment = null;
    _rightAlignment = null;
    _rightBarLineAlignment = null;
    reset();
  }

  /// The left / right Alignment objects kept for the measure start and end
  /// position (mirrors `m_leftAlignment` / `m_rightAlignment`).
  Alignment? _leftAlignment;
  Alignment? _rightAlignment;

  /// The left / right Alignment objects kept for the left and right barline
  /// position (mirrors `m_leftBarLineAlignment` /
  /// `m_rightBarLineAlignment`).
  Alignment? _leftBarLineAlignment;
  Alignment? _rightBarLineAlignment;

  /// The measure's non-justifiable margin used by the scoreDef attributes
  /// (mirrors `m_nonJustifiableLeftMargin`).
  int _nonJustifiableLeftMargin = 0;

  /// The time duration of the timestamp between 0.0 and 1.0; depends on the
  /// meter signature in the preceding scoreDef (mirrors
  /// `m_initialTstampDur`).
  Fraction _initialTstampDur = Fraction(-1);

  @override
  String get className => 'measureAligner';

  @override
  void reset() {
    super.reset();

    _nonJustifiableLeftMargin = 0;
    _leftAlignment = Alignment(Fraction(-1), AlignmentType.measureStart);
    addAlignment(_leftAlignment!);
    _leftBarLineAlignment =
        Alignment(Fraction(-1), AlignmentType.measureLeftBarline);
    addAlignment(_leftBarLineAlignment!);
    _rightBarLineAlignment =
        Alignment(Fraction(0), AlignmentType.measureRightBarline);
    addAlignment(_rightBarLineAlignment!);
    _rightAlignment = Alignment(Fraction(0), AlignmentType.measureEnd);
    addAlignment(_rightAlignment!);

    _initialTstampDur = Fraction(-1);
  }

  /// Mirrors `Measure::GetLeftBarLineXRel`.
  int getLeftBarLineXRel() => _leftBarLineAlignment?.getXRel() ?? 0;

  /// Mirrors `Measure::GetRightBarLineXRel`.
  int getRightBarLineXRel() => _rightBarLineAlignment?.getXRel() ?? 0;

  @override
  bool isSupportedChild(ClassId classId) {
    // Nothing to check here
    return true;
  }

  /// Retrieve the alignment of the type at that time.
  ///
  /// The alignment object is added if not found. The maximum time position
  /// is also adjusted accordingly for end barline positioning (mirrors
  /// `GetAlignmentAtTime`).
  Alignment getAlignmentAtTime(Fraction time, AlignmentType type) {
    final (found, searchIdx) = searchAlignmentAtTime(time, type);
    // we already have a alignment of the type at that time
    if (found != null) return found;
    int idx = searchIdx;
    // nothing found to the end
    if (idx == -1) {
      if (type != AlignmentType.measureEnd) {
        // This typically occurs when a tstamp event occurs after the last
        // note of a measure
        final int rightBarlineIdx = _rightBarLineAlignment!.idx!;
        idx = rightBarlineIdx;
        setMaxTime(time);
      } else {
        idx = getAlignmentCount();
      }
    }
    final newAlignment = Alignment(time, type);
    addAlignment(newAlignment, idx);
    return newAlignment;
  }

  /// Keep the maximum time of the measure.
  ///
  /// This corresponds to the whole duration of the measure and should be the
  /// same for all staves/layers (mirrors `SetMaxTime`).
  void setMaxTime(Fraction time) {
    // we have to have a m_rightBarLineAlignment
    assert(_rightBarLineAlignment != null);

    // it must be found in the aligner
    final int idx = _rightBarLineAlignment!.idx!;
    assert(idx != -1);

    // Increase the time position for all alignments from the right barline
    for (int i = idx; i < getAlignmentCount(); ++i) {
      final alignment = getChild(i) as Alignment;
      // Change it only if higher than before
      if (time > alignment.getTime()) alignment.setTime(time);
    }
  }

  /// Return the max time of the measure, i.e., the right measure alignment
  /// time (mirrors `GetMaxTime`).
  Fraction getMaxTime() {
    // we have to have a m_rightBarLineAlignment
    assert(_rightBarLineAlignment != null);

    return _rightAlignment!.getTime();
  }

  /// Return the non-justifiable margin (mirrors `GetNonJustifiableMargin`).
  int getNonJustifiableMargin() => _nonJustifiableLeftMargin;

  /// Mirrors `SetInitialTstamp(data_DURATION meterUnit)`.
  void setInitialTstamp(MeiDuration meterUnit) {
    _initialTstampDur = Fraction.fromDuration(meterUnit) * Fraction(-1);
  }

  /// Mirrors `GetInitialTstampDur`.
  Fraction getInitialTstampDur() => _initialTstampDur;

  /// Get left Alignment for the measure start (time -1.0; mirrors
  /// `GetLeftAlignment`).
  Alignment? getLeftAlignment() => _leftAlignment;

  /// Get left Alignment for the left BarLine (mirrors
  /// `GetLeftBarLineAlignment`).
  Alignment? getLeftBarLineAlignment() => _leftBarLineAlignment;

  /// Get right Alignment for the measure (mirrors `GetRightAlignment`).
  Alignment? getRightAlignment() => _rightAlignment;

  /// Get right Alignment for the right barline (mirrors
  /// `GetRightBarLineAlignment`).
  Alignment? getRightBarLineAlignment() => _rightBarLineAlignment;

  /// Adjust the spacing of the measure looking at each tuple of start / end
  /// alignment and a distance.
  ///
  /// The distance is an expansion value (positive) or compression (negative)
  /// (mirrors `AdjustProportionally`).
  void adjustProportionally(List<(Alignment, Alignment, int)> adjustments) {
    for (final (start, end, dist) in adjustments) {
      if (dist == 0) {
        logDebug('Trying to adjust alignment with a distance of 0;');
        continue;
      }
      // We need to store them because they are going to be changed in the
      // loop below
      final int startX = start.getXRel();
      final int endX = end.getXRel();
      for (final Object child in children) {
        final current = child as Alignment;
        // Nothing to do once we passed the start alignment
        if (current.getXRel() <= startX) {
          continue;
        } else if (current.getXRel() >= endX) {
          current.setXRel(current.getXRel() + dist);
          continue;
        } else {
          final int ratio =
              (current.getXRel() - startX) * 100 ~/ (endX - startX);
          final int shift = dist * ratio ~/ 100;
          current.setXRel(current.getXRel() + shift);
        }
      }
    }
  }

  /// Push all the ALIGNMENT_GRACENOTE and ALIGNMENT_CONTAINER to the right.
  ///
  /// This is necessary to make sure they align with the next alignment
  /// content (mirrors `PushAlignmentsRight`).
  void pushAlignmentsRight() {
    Alignment? previous;
    for (int i = children.length - 1; i >= 0; --i) {
      final current = children[i] as Alignment;
      if (current.isOfType([AlignmentType.graceNote])) {
        if (previous != null) current.setXRel(previous.getXRel());
      } else {
        previous = current;
      }
    }
  }

  /// Adjust the spacing of the grace notes in the [alignment] (mirrors
  /// `MeasureAligner::AdjustGraceNoteSpacing`).
  ///
  /// Looks at the right position of the previous alignment content and
  /// shifts the grace group (and the alignments in between) proportionally
  /// when the group does not fit.
  void adjustGraceNoteSpacing(Doc doc, Alignment alignment, int staffN) {
    assert(alignment.getType() == AlignmentType.graceNote);

    final Options options = doc.getOptions();
    final int graceAlignerId = options.graceRhythmAlign.value ? 0 : staffN;
    assert(alignment.hasGraceAligner(graceAlignerId));

    final Measure? measure = parent is Measure ? parent as Measure : null;
    assert(measure != null);

    int maxRight = meiUnset;
    Alignment? rightAlignment;

    // Set staffNGrp as VRV_UNSET to align all staves (mirrors
    // `m_graceRightAlign`).
    final int staffNGrp = options.graceRightAlign.value ? meiUnset : staffN;

    bool found = false;
    for (int i = children.length - 1; i >= 0; --i) {
      final Object child = children[i];
      if (!found) {
        if (identical(child, alignment)) found = true;
        continue;
      }

      rightAlignment = child as Alignment;

      if (rightAlignment
          .isOfType([AlignmentType.fullMeasure, AlignmentType.fullMeasure2])) {
        continue;
      }

      // Do not go beyond the left bar line
      if (rightAlignment.getType() == AlignmentType.measureLeftBarline) {
        maxRight = measure!.getLeftBarLineRight();
        break;
      }

      final (_, int alignmentMaxRight) =
          rightAlignment.getLeftRight(staffNGrp, excludes: [ClassId.clef]);

      if (alignmentMaxRight != meiUnset) {
        maxRight = alignmentMaxRight;
        break;
      }
    }

    // This should never happen because we must have hit the left barline in
    // the loop above
    if (rightAlignment == null || maxRight == meiUnset) return;

    // Check if the left position of the group is on the right of the
    // previous maxRight. If not, move the alignments accordingly.
    int left =
        alignment.getGraceAligner(graceAlignerId).getGraceGroupLeft(staffN);
    // We also set artificially the margin with the previous note
    if (left != -meiUnset) {
      left -= doc.getLeftMargin(ClassId.note).toInt() * doc.getDrawingUnit(100);
    }
    if (left < maxRight) {
      final int spacing = maxRight - left;
      adjustProportionally([(rightAlignment, alignment, spacing)]);
    }
  }
}

// ---------------------------------------------------------------------------
// GraceAligner
// ---------------------------------------------------------------------------

/// This class aligns the content of a grace note group.
///
/// It contains a vector of Alignment (mirrors `vrv::GraceAligner`).
class GraceAligner extends HorizontalAligner {
  GraceAligner() : super(ClassId.graceAligner) {
    reset();
  }

  /// The stack of objects where they are piled up before getting aligned
  /// (mirrors `m_graceStack`).
  final List<LayerElement> _graceStack = [];

  /// The width of the group of grace notes instanciated after the bounding
  /// boxes X are integrated (mirrors `m_totalWidth`).
  int _totalWidth = 0;

  @override
  String get className => 'graceAligner';

  @override
  void reset() {
    super.reset();
    _totalWidth = 0;
  }

  /// Retrieve the alignment of the type at that time; the alignment object
  /// is added if not found (mirrors `GetAlignmentAtTime`).
  Alignment getAlignmentAtTime(Fraction time, AlignmentType type) {
    final (found, searchIdx) = searchAlignmentAtTime(time, type);
    // we already have a alignment of the type at that time
    if (found != null) return found;
    // nothing found until the end
    final int idx = searchIdx == -1 ? getAlignmentCount() : searchIdx;
    final newAlignment = Alignment(time, type);
    addAlignment(newAlignment, idx);
    return newAlignment;
  }

  /// Stack a grace note (or chord) element (mirrors `StackGraceElement`).
  void stackGraceElement(LayerElement element) {
    assert(element.isAny({ClassId.note, ClassId.chord}));

    if (element.classId == ClassId.note) {
      final note = element as dynamic;
      if (note.isChordTone() != null) return;
    }

    _graceStack.add(element);
  }

  /// Align the notes in the reverse order (mirrors `AlignStack`).
  ///
  /// Because the grace notes appear from left to right but need to be aligned
  /// from right to left, we first need to stack them and align them
  /// eventually when we have all of them.
  void alignStack() {
    Fraction time = Fraction(0);
    for (int i = _graceStack.length; i > 0; --i) {
      final element = _graceStack.elementAt(i - 1);
      // get the duration of the event
      final Fraction duration =
          element.getAlignmentDuration(null, false, Notationtype.cmn);
      // Time goes backward with grace notes
      time = time - duration;
      final alignment = getAlignmentAtTime(time, AlignmentType.default_);
      element.setGraceAlignment(alignment);

      final matchType = ClassIdsComparison([
        ClassId.accid,
        ClassId.flag,
        ClassId.note,
        ClassId.stem,
      ]);
      final childrenFound = element.findAllDescendantsMatching(matchType);
      alignment.addLayerElementRef(element);

      // Set the grace alignment to all children
      for (final Object child in childrenFound) {
        // Trick: FindAllDescendantsByComparison includes the element, which is
        // probably a problem. With note, we want to set only accid, so make
        // sure we do not set it twice.
        if (identical(child, element)) continue;
        final childElement = child as LayerElement;
        childElement.setGraceAlignment(alignment);
        alignment.addLayerElementRef(childElement);
      }
    }
    _graceStack.clear();
  }

  /// Setter for the width of the group of grace notes (mirrors `SetWidth`).
  void setWidth(int totalWidth) => _totalWidth = totalWidth;

  /// Getter for the width of the group of grace notes (mirrors `GetWidth`).
  int getWidth() => _totalWidth;

  /// Return the left position of the first note matching by staffN.
  ///
  /// Setting staffN as [meiUnset] will look for and align all staves
  /// (mirrors `GetGraceGroupLeft`).
  int getGraceGroupLeft(int staffN) {
    // First we need to get the left alignment with an alignment reference
    // with staffN
    Alignment? leftAlignment;
    if (staffN != meiUnset) {
      final matchStaff =
          AttNIntegerComparison(ClassId.alignmentReference, staffN);
      final Object? reference = findDescendantByComparison(matchStaff);
      if (reference == null) return -meiUnset;
      // The alignment is its parent
      leftAlignment = reference.parent as Alignment?;
    } else {
      leftAlignment = getFirst() as Alignment?;
    }
    // Return if nothing found
    if (leftAlignment == null) return -meiUnset;

    final (minLeft, _) = leftAlignment.getLeftRight(staffN);

    return minLeft;
  }

  /// Return the right position of the last note matching by staffN (mirrors
  /// `GetGraceGroupRight`).
  ///
  /// We do not need to search the alignment with staffN here because all
  /// grace note groups have their right note aligned, so getting the last is
  /// fine.
  int getGraceGroupRight(int staffN) {
    final rightAlignment = getLast() as Alignment?;
    if (rightAlignment == null) return meiUnset;

    final (_, maxRight) = rightAlignment.getLeftRight(staffN);

    return maxRight;
  }

  /// Set the x position of each alignment of the grace aligner (mirrors
  /// `GraceAligner::SetGraceAlignmentXPos`).
  ///
  /// The alignments are spaced from right to left with a full notehead
  /// width, which is a reasonable default spacing (with margin) for grace
  /// notes.
  void setGraceAlignmentXPos(Doc doc) {
    int i = 0;
    for (final Object child in children.reversed) {
      final Alignment alignment = child as Alignment;
      alignment
          .setXRel(-i * doc.getGlyphWidth(smuflE0A4NoteheadBlack, 100, false));
      ++i;
    }
  }
}

// ---------------------------------------------------------------------------
// TimestampAligner
// ---------------------------------------------------------------------------

/// This class stores the timestamps (TimestampAttr) in a measure.
///
/// It does not itself perform any alignment but only stores them and avoids
/// duplicates (i.e., having two objects at the same position). It contains a
/// vector of TimestampAttr (mirrors `vrv::TimestampAligner`).
class TimestampAligner extends Object {
  TimestampAligner() : super(ClassId.timestampAligner) {
    reset();
  }

  @override
  String get className => 'timestampAligner';

  @override
  bool isSupportedChild(ClassId classId) {
    // Nothing to check here
    return true;
  }

  /// Look for an existing TimestampAttr at a certain time; create it if not
  /// found (mirrors `GetTimestampAtTime`).
  TimestampAttr getTimestampAtTime(double time) {
    int idx = -1; // the index if we reach the end.
    // We need to adjust the position since timestamp 0 to 1.0 are before 0
    // musical time
    time = time - 1.0;
    TimestampAttr timestampAttr;

    final List<Object> childrenList = childrenForModification;

    // First try to see if we already have something at the time position
    int i = 0;
    for (final Object child in childrenList) {
      timestampAttr = child as TimestampAttr;

      final double alignmentTime = timestampAttr.getActualDurPos();
      if (approximatelyEqual(alignmentTime, time)) {
        return timestampAttr;
      }
      // nothing found, do not go any further but keep the index
      if (alignmentTime > time) {
        idx = i;
        break;
      }
      ++i;
    }
    // nothing found
    timestampAttr = TimestampAttr();
    timestampAttr.setDrawingPos(time);
    if (idx == -1) {
      addChild(timestampAttr);
    } else {
      insertChild(timestampAttr, idx);
    }
    return timestampAttr;
  }
}

// ---------------------------------------------------------------------------
// AlignMeterParams (mirrors alignfunctor.h)
// ---------------------------------------------------------------------------

/// Regroup pointers to meterSig, mensur and proport objects (mirrors
/// `vrv::AlignMeterParams`).
///
/// Deviation: the members are typed as [Object] because the MeterSig / Mensur
/// / Proport element classes live in libraries importing this one; accessors
/// use dynamic dispatch (see [meterSigUnitAsDur], [meterSigTotalCount],
/// [proportCumulatedNum], [proportCumulatedNumbase]).
class AlignMeterParams {
  /// The current meter signature (mirrors `meterSig`).
  Object? meterSig;

  /// The current mensur (mirrors `mensur`).
  Object? mensur;

  /// The current proport, cumulated (mirrors `proport`).
  Object? proport;

  /// The mensural equivalence level (mirrors `equivalence`, default
  /// `DURATION_brevis`).
  MeiDuration equivalence = MeiDuration.breve;

  /// Whether the measure has metric conformace (mirrors `metcon`).
  bool metcon = true;

  /// Copy the parameters (shallow, mirroring the C++ struct copy).
  void copyFrom(AlignMeterParams other) {
    meterSig = other.meterSig;
    mensur = other.mensur;
    proport = other.proport;
    equivalence = other.equivalence;
    metcon = other.metcon;
  }

  /// The meter unit as duration value (mirrors `meterSig->GetUnitAsDur()`);
  /// defaults to dur4.
  MeiDuration get meterSigUnitAsDur => meterSig != null
      ? (meterSig as dynamic).getUnitAsDur() as MeiDuration
      : MeiDuration.dur4;

  /// Whether the meter signature has a unit (mirrors `meterSig->HasUnit()`).
  bool get meterSigHasUnit =>
      meterSig != null && ((meterSig as dynamic).hasUnit as bool);

  /// The total count of the meter signature (mirrors
  /// `meterSig->GetTotalCount()`).
  int get meterSigTotalCount =>
      meterSig != null ? (meterSig as dynamic).getTotalCount() as int : 4;

  /// The cumulated proport num (mirrors `proport->GetCumulatedNum()`).
  int get proportCumulatedNum =>
      proport != null ? (proport as dynamic).getCumulatedNum() as int : 1;

  /// The cumulated proport numbase (mirrors
  /// `proport->GetCumulatedNumbase()`).
  int get proportCumulatedNumbase =>
      proport != null ? (proport as dynamic).getCumulatedNumbase() as int : 1;

  /// Whether the proport has a num (mirrors `proport->HasNum()`).
  bool get proportHasNum =>
      proport != null && ((proport as dynamic).hasNum as bool);

  /// Whether the proport has a numbase (mirrors `proport->HasNumbase()`).
  bool get proportHasNumbase =>
      proport != null && ((proport as dynamic).hasNumbase as bool);
}

// ---------------------------------------------------------------------------
// LayerElement::GetAlignmentDuration (mirrors layerelement.cpp)
// ---------------------------------------------------------------------------

extension LayerElementAlignmentDuration on LayerElement {
  /// Return the alignment duration of the element (mirrors the non-virtual
  /// `LayerElement::GetAlignmentDuration(params, notGraceOnly, notationType)`).
  ///
  /// The [params] may be null for the parameterless C++ overload.
  Fraction getAlignmentDuration(
      [AlignMeterParams? params,
      bool notGraceOnly = true,
      Notationtype? notationType]) {
    final AlignMeterParams meterParams = params ?? AlignMeterParams();
    final Notationtype notation = notationType ?? Notationtype.cmn;

    if (isGraceNote() && notGraceOnly) {
      return Fraction(0);
    }

    // Only resolve simple sameas links to avoid infinite recursion
    if (hasInterface(InterfaceId.linking) && hasSameasLink) {
      final sameas = sameasLink as LayerElement;
      if (!sameas.hasSameasLink) {
        return sameas.getAlignmentDuration(meterParams, notGraceOnly, notation);
      }
    }

    if (hasInterface(InterfaceId.duration)) {
      final duration = this as DurationInterface;
      int num = 1;
      int numbase = 1;

      if (meterParams.proport != null) {
        // Proportion are applied reversly - higher ratio means shorter values
        if (meterParams.proportHasNum) num *= meterParams.proportCumulatedNum;
        if (meterParams.proportHasNumbase) {
          numbase *= meterParams.proportCumulatedNumbase;
        }
      }

      final tuplet = getFirstAncestor(ClassId.tuplet);
      if (tuplet != null) {
        final objects = tuplet.findAllDescendantsByClassIdPredicate(
            (ClassId classId) =>
                classId == ClassId.chord ||
                classId == ClassId.note ||
                classId == ClassId.rest ||
                classId == ClassId.space);
        if (objects.isNotEmpty) {
          // Adjust VRV_UNSET and 0 - which is not valid in MEI anyway
          num = math.max(1, ((tuplet as dynamic).num ?? meiUnset) as int);
          numbase =
              math.max(1, ((tuplet as dynamic).numbase ?? meiUnset) as int);
        }
      }

      if (duration.isMensuralDur && notation != Notationtype.cmn) {
        return duration.getInterfaceAlignmentMensuralDuration(num, numbase,
            meterParams.mensur as MensurValues?, meterParams.equivalence);
      }

      Fraction durationValue =
          duration.getInterfaceAlignmentDuration(num, numbase);
      // With fTrem we need to divide the duration by two
      if (getFirstAncestor(ClassId.fTrem) != null) {
        durationValue = durationValue * Fraction(1, 2);
      }
      return durationValue;
    } else if (classId == ClassId.beatRpt) {
      MeiDuration meterUnit = MeiDuration.dur4;
      if (meterParams.meterSigHasUnit) {
        meterUnit = meterParams.meterSigUnitAsDur;
      }
      return _beatRptAlignmentDuration(this, meterUnit);
    } else if (classId == ClassId.timestampAttr) {
      MeiDuration meterUnit = MeiDuration.dur4;
      if (meterParams.meterSigHasUnit) {
        meterUnit = meterParams.meterSigUnitAsDur;
      }
      return (this as dynamic).getTimestampAttrAlignmentDuration(meterUnit)
          as Fraction;
    }
    // We align all full measure element to the current time signature, even
    // the ones that last longer than one measure. If metcon is false, then
    // the duration will remain 0 because it cannot be determined.
    else if (meterParams.metcon &&
        isAny({
          ClassId.halfmRpt,
          ClassId.mRest,
          ClassId.multiRest,
          ClassId.mRpt,
          ClassId.mRpt2,
          ClassId.multiRpt,
        })) {
      MeiDuration meterUnit = MeiDuration.dur4;
      int meterCount = 4;
      if (meterParams.meterSigHasUnit) {
        meterUnit = meterParams.meterSigUnitAsDur;
      }
      if (meterParams.meterSig != null) {
        meterCount = meterParams.meterSigTotalCount;
      }
      final duration = Fraction.fromDuration(meterUnit) * Fraction(meterCount);
      return (classId == ClassId.halfmRpt) ? duration / Fraction(2) : duration;
    }
    // This is not called with --neume-as-note since otherwise each nc has an
    // aligner (mirrors the `NEUME_*_SPACE` branch of
    // `LayerElement::GetAlignmentDuration`; the C++ defines them as Fractions:
    // large = 1/4, medium = 1/8, small = 1/16 — layerelement.cpp:78-82).
    else if (classId == ClassId.neume) {
      final Object? syllable = getFirstAncestor(ClassId.syllable);
      // Add a larger gap after the last neume of the syllable.
      if (syllable == null) return Fraction(0);
      return identical(syllable.getLast(), this)
          ? kNeumeMediumSpace
          : kNeumeSmallSpace;
    }
    // This is called only with a syllable without neume. Otherwise the
    // duration is given by the neume (or by the nc with --neume-as-note).
    else if (classId == ClassId.syllable &&
        findDescendantByType(ClassId.neume) == null) {
      return kNeumeMediumSpace;
    } else {
      return Fraction(0);
    }
  }

  /// Mirrors `BeatRpt::GetBeatRptAlignmentDuration`.
  Fraction _beatRptAlignmentDuration(
      LayerElement beatRpt, MeiDuration meterUnit) {
    Fraction duration = Fraction.fromDuration(meterUnit);
    if ((beatRpt as dynamic).hasBeatdef as bool) {
      final double beatdef = (beatRpt as dynamic).beatdef as double;
      duration = duration * Fraction((beatdef * durMax).toInt(), durMax);
    }
    return duration;
  }

  /// Mirrors `LayerElement::GetSameAsContentAlignmentDuration`.
  Fraction getSameAsContentAlignmentDuration(
      [AlignMeterParams? params,
      bool notGraceOnly = true,
      Notationtype? notationType]) {
    if (!hasInterface(InterfaceId.linking) || !hasSameasLink) {
      return Fraction(0);
    }
    final sameas = sameasLink as LayerElement;
    if (!sameas.isAny({ClassId.beam, ClassId.fTrem, ClassId.tuplet})) {
      return Fraction(0);
    }
    return sameas.getContentAlignmentDuration(
        params, notGraceOnly, notationType);
  }

  /// Mirrors `LayerElement::GetContentAlignmentDuration`.
  Fraction getContentAlignmentDuration(
      [AlignMeterParams? params,
      bool notGraceOnly = true,
      Notationtype? notationType]) {
    if (!isAny({ClassId.beam, ClassId.fTrem, ClassId.tuplet})) {
      return Fraction(0);
    }

    final AlignMeterParams meterParams = params ?? AlignMeterParams();
    Fraction duration = Fraction(0);

    for (final Object child in children) {
      // Skip everything that does not have a duration interface and notes in
      // chords
      if (!child.hasInterface(InterfaceId.duration) ||
          child.getFirstAncestor(ClassId.chord) != null) {
        continue;
      }
      final element = child as LayerElement;
      duration =
          duration + element.getAlignmentDuration(meterParams, notGraceOnly);
    }

    return duration;
  }
}
