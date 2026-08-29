/// Port of `verticalaligner.h/cpp` — the vertical alignment classes.
///
/// This library contains [SystemAligner] (owned by System) and [StaffAlignment].
/// The [FloatingPositioner] / [FloatingCurvePositioner] classes they reference
/// are ported in `floating_positioner.dart` (mirroring floatingobject.h) and
/// re-exported here for compatibility with the earlier phases.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show StaffgroupingsymSymbol, Staffrel;
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show MeasurementSigned, MeasurementType;
import 'package:verovio_dart/src/model/basic_elements.dart' show Staff;
import 'package:verovio_dart/src/model/comparison.dart'
    show VisibleStaffDefOrGrpObject;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/floating_object.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show GrpSym;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart'
    show ScoreDef, StaffDef, StaffGrp;

export 'package:verovio_dart/src/layout/floating_positioner.dart'
    show
        CurveSpannedElement,
        Discard,
        FloatingCurvePositioner,
        FloatingPositioner;

// ---------------------------------------------------------------------------
// Helpers (Doc geometry until Doc carries its own layout helpers)
// ---------------------------------------------------------------------------

/// Mirrors `Doc::GetDrawingUnit(int staffSize)`.
int docDrawingUnit(Doc doc, int staffSize) =>
    (doc.getOptions().unit.value * staffSize / 100).toInt();

/// Mirrors `Doc::GetDrawingDoubleUnit(int staffSize)`.
int docDrawingDoubleUnit(Doc doc, int staffSize) =>
    (doc.getOptions().unit.value * 2 * staffSize / 100).toInt();

/// Mirrors `Doc::GetBottomMargin(STAFF)` (falls back to the default bottom
/// margin like the C++).
double docBottomMarginStaff(Doc doc) =>
    doc.getOptions().defaultBottomMargin.value;

// ---------------------------------------------------------------------------
// SystemAligner
// ---------------------------------------------------------------------------

/// Declares different spacing types between staves (mirrors
/// `vrv::SystemAligner::SpacingType`).
enum SpacingType { system, staff, brace, bracket, ossia, none }

/// This class aligns the content of a system.
///
/// It contains a vector of StaffAlignment (mirrors `vrv::SystemAligner`).
class SystemAligner extends Object {
  SystemAligner() : super(ClassId.systemAligner) {
    reset();
  }

  /// A pointer to the StaffAlignment object kept for the system bottom
  /// position (mirrors `m_bottomAlignment`).
  StaffAlignment? _bottomAlignment;

  /// Stores the above spacing type of staves based on visibility (mirrors
  /// `m_spacingTypes`).
  final Map<int, SpacingType> _spacingTypes = {};

  /// Stores the parent system once resolved (mirrors `m_system`).
  Object? _system;

  @override
  ClassId get classId => ClassId.systemAligner;

  @override
  String get className => 'systemAligner';

  @override
  void reset() {
    super.reset();
    _spacingTypes.clear();
    _system = null;

    _bottomAlignment = StaffAlignment();
    _bottomAlignment!.setStaff(null, null, SpacingType.none);
    _bottomAlignment!.setParentSystem(getSystem());
    addChild(_bottomAlignment!);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Nothing to check here
    return true;
  }

  /// Do not copy children for SystemAligner (mirrors `CopyChildren`).
  @override
  bool copyChildren() => false;

  /// Get bottom StaffAlignment for the system (mirrors `GetBottomAlignment`).
  StaffAlignment? getBottomAlignment() => _bottomAlignment;

  /// Get the StaffAlignment at index idx; create it if not there yet.
  ///
  /// Checks that they are created incrementally (without gap). If a staff is
  /// passed, it will be used for initializing the aligner (mirrors
  /// `GetStaffAlignment`).
  StaffAlignment? getStaffAlignment(int idx, Staff? staff, Doc? doc) {
    final List<Object> childrenList = childrenForModification;

    // The last one is always the bottomAlignment
    assert(_bottomAlignment != null);
    // remove it temporarily
    childrenList.removeLast();

    StaffAlignment? alignment =
        getStaffAlignmentForStaffN(staff?.n ?? meiUnset);
    if (alignment != null) {
      childrenList.add(_bottomAlignment!);
      return alignment;
    }

    // This is the first time we are looking for it (e.g., first staff)
    // We create the StaffAlignment
    alignment = StaffAlignment();
    alignment.setStaff(staff, doc, getAboveSpacingType(staff));
    alignment.setParentSystem(getSystem());
    addChild(alignment);

    // put back the bottomAlignment
    childrenList.add(_bottomAlignment!);

    return alignment;
  }

  /// Reorder the staff alignments as given in the staffNs (mirrors
  /// `ReorderBy`).
  ///
  /// Reordering will fail if some staffAlignment pointers are missing for a
  /// corresponding staffN.
  void reorder(List<int> staffNs) {
    final order = [...staffNs]..sort();
    // First check that staffNs are unique
    final unique = order.toSet();
    // If not, we should return because the re-ordering below would corrupt
    // the data. Returning will keep the order as it is.
    if (unique.length != staffNs.length) return;

    final List<Object> childrenList = childrenForModification;

    // Since we have a bottom alignment, the number is +1. The children list
    // can be smaller with optimized systems.
    if (childrenList.length > staffNs.length + 1) return;

    final orderedAlignments = <StaffAlignment>[];
    for (final int staffN in staffNs) {
      final alignment = getStaffAlignmentForStaffN(staffN);
      // This happens with condensed systems where some alignment for staffN
      // are not there
      if (alignment == null) continue;
      orderedAlignments.add(alignment);
    }
    int i = 0;
    // Since the number of staffAlignment is the same and they are unique, we
    // can blindly replace them in the StaffAligner children
    for (final alignment in orderedAlignments) {
      childrenList[i] = alignment;
      ++i;
    }
  }

  /// Get the StaffAlignment for the staffN; null if not found (mirrors
  /// `GetStaffAlignmentForStaffN`).
  StaffAlignment? getStaffAlignmentForStaffN(int staffN) {
    for (int i = 0; i < childCount; ++i) {
      final alignment = getChild(i) as StaffAlignment?;

      if (alignment != null &&
          alignment.getStaff() != null &&
          (alignment.getStaff()!.n ?? meiUnset) == staffN) {
        return alignment;
      }
    }
    return null;
  }

  /// Get pointer to the parent system (mirrors `GetSystem`); resolves it
  /// through the ancestors when not cached.
  Object? getSystem() {
    _system ??= getFirstAncestor(ClassId.system);
    return _system;
  }

  /// Find all the positioners pointing to an object (mirrors
  /// `FindAllPositionerPointingTo`). Full behaviour arrives with the floating
  /// positioner phase.
  void findAllPositionerPointingTo(
      List<FloatingPositioner> positioners, FloatingObject object) {
    positioners.clear();

    for (final Object child in children) {
      final alignment = child as StaffAlignment;
      final positioner = alignment.getCorrespFloatingPositioner(object);
      if (positioner != null && identical(positioner.getObject(), object)) {
        positioners.add(positioner);
      }
    }
  }

  /// Find all the intersection points with a vertical line (top to bottom)
  /// (mirrors `FindAllIntersectionPoints`).
  void findAllIntersectionPoints(SegmentedLine line, BoundingBox boundingBox,
      List<ClassId> classIds, int margin) {
    for (final Object child in children) {
      final alignment = child as StaffAlignment;
      alignment.findAllIntersectionPoints(line, boundingBox, classIds, margin);
    }
  }

  /// Get system overflow above (mirrors `GetOverflowAbove`).
  int getOverflowAbove(Doc doc, [bool scoreDefClef = false]) {
    if (childCount == 0 || identical(getChild(0), _bottomAlignment)) return 0;

    final alignment = getChild(0) as StaffAlignment;
    return scoreDefClef
        ? alignment.getScoreDefClefOverflowAbove()
        : alignment.getOverflowAbove();
  }

  /// Get system overflow below (mirrors `GetOverflowBelow`).
  int getOverflowBelow(Doc doc, [bool scoreDefClef = false]) {
    if (childCount == 0 || identical(getChild(0), _bottomAlignment)) return 0;

    final alignment = getChild(childCount - 2) as StaffAlignment;
    return scoreDefClef
        ? alignment.getScoreDefClefOverflowBelow()
        : alignment.getOverflowBelow();
  }

  /// Get justification sum (mirrors `GetJustificationSum`).
  double getJustificationSum(Doc doc) {
    double justificationSum = 0;
    for (final Object child in children) {
      final alignment = child is StaffAlignment ? child : null;
      justificationSum +=
          alignment != null ? alignment.getJustificationFactor(doc) : 0.0;
    }
    return justificationSum;
  }

  /// Calculates and sets the spacing types for the specified scoreDef
  /// (mirrors `SetSpacing`).
  void setSpacing(ScoreDef? scoreDef) {
    assert(scoreDef != null);

    _spacingTypes.clear();

    for (final Object object in scoreDef!.getList()) {
      // It should be staffDef only, but double check.
      if (object.classId != ClassId.staffDef) continue;
      final staffDef = object as StaffDef;
      final SpacingType spacing = calculateSpacingAbove(staffDef);

      // Get the ossias above
      final nsAbove = <int>[];
      staffDef.getOssiaAboveNs(nsAbove);
      // push main staff at the end so it will get an ossia spacing if needed
      nsAbove.add(staffDef.n ?? meiUnset);
      for (final int n in nsAbove) {
        _spacingTypes[n] = SpacingType.ossia;
      }
      // Top one (ossia or main staff if no ossias) gets the main staff spacing
      _spacingTypes[nsAbove.first] = spacing;
      // Clear list and add ossia below with ossia spacing
      final nsBelow = <int>[];
      staffDef.getOssiaBelowNs(nsBelow);
      for (final int n in nsBelow) {
        _spacingTypes[n] = SpacingType.ossia;
      }
    }
  }

  /// Return the above spacing type for the passed staff; calculates the
  /// spacings if required (mirrors `GetAboveSpacingType`).
  SpacingType getAboveSpacingType(Staff? staff) {
    if (staff == null) return SpacingType.none;

    if (_spacingTypes.isEmpty) {
      final system = staff.getFirstAncestor(ClassId.system);
      final scoreDef = system == null
          ? null
          : (system as dynamic).drawingScoreDef as ScoreDef?;
      setSpacing(scoreDef);
    }

    final spacingType = _spacingTypes[staff.n];
    if (spacingType == null) {
      logWarning(
          "No spacing type found matching @n=${staff.n} for '${staff.id}'");
      return SpacingType.none;
    }

    return spacingType;
  }

  /// Calculates the above spacing type for a staffDef (mirrors
  /// `CalculateSpacingAbove`).
  SpacingType calculateSpacingAbove(Object? staffDefObj) {
    assert(staffDefObj != null);

    final staffDef = staffDefObj as StaffDef;
    SpacingType spacingType = SpacingType.none;
    if (staffDef.drawingVisibility != VisibilityOptimization.hidden) {
      Object staffChild = staffDef;
      Object? staffParent = staffChild.parent;
      bool notFirstInGroup = false;
      final matchType = VisibleStaffDefOrGrpObject();
      while (spacingType == SpacingType.none) {
        matchType.skip(staffParent!);
        final firstVisible =
            staffParent.findDescendantByComparison(matchType, deepness: 1);

        // for first child in staff group parent's symbol should be taken,
        // except when we had a child which is not on the first place in
        // group, than take first symbol
        notFirstInGroup = notFirstInGroup ||
            (firstVisible != null && !identical(firstVisible, staffChild));
        if (notFirstInGroup) {
          final staffGrp = staffParent is StaffGrp ? staffParent : null;
          final grpSym = staffGrp?.getFirst(ClassId.grpSym) as GrpSym?;
          if (grpSym != null) {
            switch (grpSym.symbol) {
              case StaffgroupingsymSymbol.brace:
                spacingType = SpacingType.brace;
                break;
              case StaffgroupingsymSymbol.bracket:
              case StaffgroupingsymSymbol.bracketsq:
                spacingType = SpacingType.bracket;
                break;
              default:
                spacingType = SpacingType.none;
            }
          }
        }

        if (spacingType == SpacingType.none) {
          staffChild = staffParent;
          staffParent = staffChild.parent;
          if (staffParent == null || staffParent.classId != ClassId.staffGrp) {
            spacingType =
                notFirstInGroup ? SpacingType.staff : SpacingType.system;
          }
        }
      }
    }

    return spacingType;
  }
}

// ---------------------------------------------------------------------------
// StaffAlignment
// ---------------------------------------------------------------------------

/// This class stores an alignment position staves point to (mirrors
/// `vrv::StaffAlignment`).
class StaffAlignment extends Object {
  StaffAlignment() : super(ClassId.staffAlignment) {
    _yRel = 0;
    _verseAboveNs.clear();
    _verseBelowNs.clear();
    _staff = null;
    _floatingPositionersSorted = true;

    _overflowAbove = 0;
    _overflowBelow = 0;
    _staffHeight = 0;
    _overlap = 0;
    _requestedSpaceAbove = 0;
    _requestedSpaceBelow = 0;
    _requestedSpacing = 0;
    _scoreDefClefOverflowAbove = 0;
    _scoreDefClefOverflowBelow = 0;
  }

  /// Defines the spacing type between the current staff and the previous one
  /// (mirrors `m_spacingType`).
  SpacingType _spacingType = SpacingType.none;

  /// The list of FloatingPositioners for the staff (mirrors
  /// `m_floatingPositioners`).
  final List<FloatingPositioner> _floatingPositioners = [];

  /// Flag indicating whether the list of FloatingPositioner is sorted
  /// (mirrors `m_floatingPositionersSorted`).
  bool _floatingPositionersSorted = true;

  /// Stores a pointer to the staff from which the aligner was created
  /// (mirrors `m_staff`).
  Staff? _staff;

  /// Stores a pointer to the system the Alignment belongs to (mirrors
  /// `m_system`).
  Object? _system;

  /// Stores the position relative to the system (mirrors `m_yRel`).
  int _yRel = 0;

  /// Stores the verse@n attached to the aligner, above and below (mirrors
  /// `m_verseAboveNs` / `m_verseBelowNs`).
  final Set<int> _verseAboveNs = {};
  final Set<int> _verseBelowNs = {};

  /// Overflow / overlap values (mirrors `m_overflowAbove`, …).
  int _overflowAbove = 0;
  int _overflowBelow = 0;
  int _overlap = 0;
  int _requestedSpaceAbove = 0;
  int _requestedSpaceBelow = 0;
  int _requestedSpacing = 0;
  int _staffHeight = 0;
  int _scoreDefClefOverflowAbove = 0;
  int _scoreDefClefOverflowBelow = 0;

  /// The lists of overflowing bounding boxes (e.g., LayerElement or
  /// FloatingPositioner; mirrors `m_overflowAboveBBoxes` /
  /// `m_overflowBelowBBoxes`).
  final List<BoundingBox> _overflowAboveBBoxes = [];
  final List<BoundingBox> _overflowBelowBBoxes = [];

  @override
  ClassId get classId => ClassId.staffAlignment;

  @override
  String get className => 'staffAlignment';

  /// Setter for yRel; only lowers the value (mirrors `SetYRel`).
  void setYRel(int yRel) {
    if (yRel < _yRel) {
      _yRel = yRel;
    }
  }

  /// Getter for yRel (mirrors `GetYRel`).
  int getYRel() => _yRel;

  /// Add a verse n above or below (mirrors `AddVerseN`).
  ///
  /// When setting a value of 0, then 1 is assumed.
  void addVerseN(int verseN, Staffrel place) {
    // if 0, then assume 1;
    verseN = math.max(verseN, 1);
    (place == Staffrel.above)
        ? _verseAboveNs.add(verseN)
        : _verseBelowNs.add(verseN);
  }

  /// Total verse count (mirrors `GetVerseCount`).
  int getVerseCount(bool collapse) =>
      getVerseCountAbove(collapse) + getVerseCountBelow(collapse);

  int getVerseCountAbove(bool collapse) {
    if (_verseAboveNs.isEmpty) {
      return 0;
    } else if (collapse) {
      return _verseAboveNs.length;
    } else {
      return _verseAboveNs.last;
    }
  }

  int getVerseCountBelow(bool collapse) {
    if (_verseBelowNs.isEmpty) {
      return 0;
    } else if (collapse) {
      return _verseBelowNs.length;
    } else {
      return _verseBelowNs.last;
    }
  }

  int getVersePositionAbove(int verseN, bool collapse) {
    if (_verseAboveNs.isEmpty) {
      // Syl in neumatic notation - since verse count will be 0, position -1
      return -1;
    } else if (collapse) {
      return _verseAboveNs.toList().indexOf(verseN);
    } else {
      return verseN - 1;
    }
  }

  int getVersePositionBelow(int verseN, bool collapse) {
    if (_verseBelowNs.isEmpty) {
      // Syl in neumatic notation - since verse count will be 0, position -1
      return -1;
    } else if (collapse) {
      final list = _verseBelowNs.toList().reversed.toList();
      return list.indexOf(verseN);
    } else {
      return _verseBelowNs.last - verseN;
    }
  }

  /// Retrieves or creates the FloatingPositioner for the FloatingObject on
  /// this staff (mirrors `SetCurrentFloatingPositioner` in verticalaligner.cpp,
  /// including the back-link `object->SetCurrentFloatingPositioner` on which
  /// `View::DrawArpeg` depends).
  void setCurrentFloatingPositioner(
      FloatingObject object, Object objectX, Object objectY, int spanningType) {
    FloatingPositioner? positioner = getCorrespFloatingPositioner(object);
    if (positioner == null) {
      if (object
          .isAny({ClassId.lv, ClassId.phrase, ClassId.slur, ClassId.tie})) {
        positioner = FloatingCurvePositioner(object, this, spanningType);
        _floatingPositioners.add(positioner);
      } else {
        positioner = FloatingPositioner(object, this, spanningType);
        _floatingPositioners.add(positioner);
      }
      _floatingPositionersSorted = false;
    }
    positioner.setObjectXY(objectX, objectY);
    // Back-link on the floating object (mirrors
    // `object->SetCurrentFloatingPositioner(positioner)`).
    object.setCurrentFloatingPositioner(positioner);
  }

  /// Retrieve all FloatingPositioners (mirrors `GetFloatingPositioners`).
  List<FloatingPositioner> getFloatingPositioners() => _floatingPositioners;

  /// Look for the first FloatingPositioner corresponding to the
  /// FloatingObject of the ClassId (mirrors `FindFirstFloatingPositioner`).
  FloatingPositioner? findFirstFloatingPositioner(ClassId classId) {
    for (final positioner in _floatingPositioners) {
      if (positioner.getObject()!.classId == classId) return positioner;
    }
    return null;
  }

  /// Find all FloatingPositioners corresponding to a FloatingObject with the
  /// given ClassId (mirrors `FindAllFloatingPositioners`).
  List<FloatingPositioner> findAllFloatingPositioners(ClassId classId) {
    return _floatingPositioners
        .where((positioner) => positioner.getObject()!.classId == classId)
        .toList();
  }

  /// Look for the FloatingPositioner corresponding to the FloatingObject;
  /// null if not found and nothing is created (mirrors
  /// `GetCorrespFloatingPositioner`).
  FloatingPositioner? getCorrespFloatingPositioner(FloatingObject object) {
    for (final positioner in _floatingPositioners) {
      if (identical(positioner.getObject(), object)) return positioner;
    }
    return null;
  }

  /// Setter of the staff from which the alignment was created (mirrors
  /// `SetStaff`).
  void setStaff(Staff? staff, Doc? doc, SpacingType spacingType) {
    _staff = staff;
    _spacingType = spacingType;
    if (staff != null && doc != null) {
      _staffHeight = (staff.drawingLines - 1) *
          docDrawingDoubleUnit(doc, staff.drawingStaffSize);
    }
  }

  /// Getter of the staff from which the alignment was created (mirrors
  /// `GetStaff`).
  Staff? getStaff() => _staff;

  /// Setter of the system the Alignment belongs to (mirrors
  /// `SetParentSystem`).
  void setParentSystem(Object? system) => _system = system;

  /// Getter of the system the Alignment belongs to (mirrors
  /// `GetParentSystem`).
  Object? getParentSystem() => _system;

  /// Returns the staff size, 100 if no staff object is referred to (mirrors
  /// `GetStaffSize`).
  int getStaffSize() => _staff != null ? _staff!.drawingStaffSize : 100;

  /// Returns the spacing type of the alignment (mirrors `GetSpacingType`).
  SpacingType getSpacingType() => _spacingType;

  /// Returns the spacing attribute object of the corresponding scoreDef
  /// (mirrors `GetAttSpacing`).
  ScoreDef? getAttSpacing() {
    final system = getParentSystem();
    assert(system != null);
    return (system as dynamic).drawingScoreDef as ScoreDef?;
  }

  /// Calculates the overflow above for the bounding box (mirrors
  /// `CalcOverflowAbove`).
  int calcOverflowAbove(BoundingBox box) {
    if (!box.hasContentVerticalBB()) return 0;
    if (box is FloatingPositioner) {
      return box.getContentTop() - getYRel();
    }
    return box.getSelfTop() - getYRel();
  }

  /// Calculates the overflow below for the bounding box (mirrors
  /// `CalcOverflowBelow`).
  int calcOverflowBelow(BoundingBox box) {
    if (!box.hasContentVerticalBB()) return 0;
    if (box is FloatingPositioner) {
      return -(box.getContentBottom() + _staffHeight - getYRel());
    }
    return -(box.getSelfBottom() + _staffHeight - getYRel());
  }

  int getMinimumSpacing(Doc doc) {
    int spacing = 0;
    final scoreDefSpacing = getAttSpacing();

    if (scoreDefSpacing == null) return spacing;
    final staffDef = _staff?.drawingStaffDef;
    if (_staff != null && staffDef != null) {
      // Default or staffDef spacing
      final hasSpacing =
          (staffDef as dynamic).hasSpacingStaff as bool? ?? false;
      if (hasSpacing) {
        final measurement =
            (staffDef as dynamic).spacingStaff as MeasurementSigned?;
        spacing = measurement!.type == MeasurementType.px
            ? measurement.px
            : (measurement.vu * docDrawingUnit(doc, 100)).toInt();
      } else {
        switch (_spacingType) {
          case SpacingType.system:
            // Top staff spacing (above) is half of a staff spacing
            spacing = getMinimumStaffSpacing(doc, scoreDefSpacing) ~/ 2;
            break;
          case SpacingType.staff:
            spacing = getMinimumStaffSpacing(doc, scoreDefSpacing);
            break;
          case SpacingType.brace:
            final option = doc.getOptions().spacingBraceGroup;
            spacing = option.isSet
                ? option.value * docDrawingUnit(doc, getStaffSize())
                : getMinimumStaffSpacing(doc, scoreDefSpacing);
            break;
          case SpacingType.bracket:
            final option = doc.getOptions().spacingBracketGroup;
            spacing = option.isSet
                ? option.value * docDrawingUnit(doc, getStaffSize())
                : getMinimumStaffSpacing(doc, scoreDefSpacing);
            break;
          case SpacingType.ossia:
            // Ossia spacing is third of a staff spacing
            spacing = (getMinimumStaffSpacing(doc, scoreDefSpacing) *
                    doc.getOptions().spacingOssia.value)
                .toInt();
            break;
          case SpacingType.none:
            break;
        }
      }
    }
    // This is the bottom aligner - spacing is half of a staff spacing
    else {
      spacing = getMinimumStaffSpacing(doc, scoreDefSpacing) ~/ 2;
    }

    return spacing;
  }

  int calcMinimumRequiredSpacing(Doc doc) {
    final Object? parent = this.parent;
    assert(parent != null);

    final previous = parent?.getPreviousSibling(this) as StaffAlignment?;

    if (previous == null) {
      final maxOverflow =
          math.max(getOverflowAbove(), getScoreDefClefOverflowAbove());
      return maxOverflow + getOverlap();
    }

    int overflowSum = 0;
    final verseCollapse = doc.getOptions().lyricVerseCollapse.value;
    if (previous.getVerseCount(verseCollapse) > 0) {
      overflowSum = previous.getOverflowBelow() + getOverflowAbove();
    } else {
      // The maximum between the overflow below of the previous staff and the
      // overflow above of the current
      overflowSum = math.max(previous.getOverflowBelow(), getOverflowAbove());
      // add overlap if there any
      overflowSum += getOverlap();
    }

    final unit = docDrawingUnit(doc, getStaffSize());

    // Add a margin but not for the bottom aligner
    if (_staff != null) {
      overflowSum += (docBottomMarginStaff(doc) * unit).toInt();
    }

    return overflowSum;
  }

  /// Returns the justification factor based on the staff type (mirrors
  /// `GetJustificationFactor`).
  double getJustificationFactor(Doc doc) {
    double justificationFactor = 0;
    if (_staff != null) {
      switch (_spacingType) {
        case SpacingType.system:
          justificationFactor = doc.getOptions().justificationSystem.value;
          break;
        case SpacingType.staff:
          justificationFactor = doc.getOptions().justificationStaff.value;
          break;
        case SpacingType.brace:
          justificationFactor = doc.getOptions().justificationBraceGroup.value;
          break;
        case SpacingType.bracket:
          justificationFactor =
              doc.getOptions().justificationBracketGroup.value;
          break;
        case SpacingType.ossia:
          justificationFactor = doc.getOptions().justificationStaff.value *
              doc.getOptions().spacingOssia.value;
          break;
        case SpacingType.none:
          break;
      }
      if (_spacingType != SpacingType.system) {
        justificationFactor *= getStaffSize() / 100.0;
      }
    }

    return justificationFactor;
  }

  /// Setter and getter of the overflow and overlap values (monotonic
  /// setters, mirroring the C++).
  void setOverflowAbove(int overflowAbove) {
    if (overflowAbove > _overflowAbove) _overflowAbove = overflowAbove;
  }

  int getOverflowAbove() => _overflowAbove;

  void setRequestedSpaceAbove(int space) {
    if (space > _requestedSpaceAbove) _requestedSpaceAbove = space;
  }

  int getRequestedSpaceAbove() => _requestedSpaceAbove;

  void setOverlap(int overlap) {
    if (overlap > _overlap) _overlap = overlap;
  }

  int getOverlap() => _overlap;

  void setOverflowBelow(int overflowBottom) {
    if (overflowBottom > _overflowBelow) _overflowBelow = overflowBottom;
  }

  int getOverflowBelow() => _overflowBelow;

  void setRequestedSpaceBelow(int space) {
    if (space > _requestedSpaceBelow) _requestedSpaceBelow = space;
  }

  int getRequestedSpaceBelow() => _requestedSpaceBelow;

  void setRequestedSpacing(int spacing) => _requestedSpacing = spacing;

  int getRequestedSpacing() => _requestedSpacing;

  int getStaffHeight() => _staffHeight;

  void setScoreDefClefOverflowAbove(int overflowAbove) =>
      _scoreDefClefOverflowAbove = overflowAbove;

  int getScoreDefClefOverflowAbove() => _scoreDefClefOverflowAbove;

  void setScoreDefClefOverflowBelow(int overflowBelow) =>
      _scoreDefClefOverflowBelow = overflowBelow;

  int getScoreDefClefOverflowBelow() => _scoreDefClefOverflowBelow;

  /// Modify / get the arrays of overflowing objects above or below (mirrors
  /// `AddBBoxAbove` … `GetBBoxesBelow`).
  void addBBoxAbove(BoundingBox box) => _overflowAboveBBoxes.add(box);
  void addBBoxBelow(BoundingBox box) => _overflowBelowBBoxes.add(box);
  void clearBBoxesAbove() => _overflowAboveBBoxes.clear();
  void clearBBoxesBelow() => _overflowBelowBBoxes.clear();
  List<BoundingBox> getBBoxesAboveForModification() => _overflowAboveBBoxes;
  List<BoundingBox> getBBoxesBelowForModification() => _overflowBelowBBoxes;
  List<BoundingBox> getBBoxesAbove() => _overflowAboveBBoxes;
  List<BoundingBox> getBBoxesBelow() => _overflowBelowBBoxes;

  /// Deletes all the FloatingPositioner objects (mirrors `ClearPositioners`).
  void clearPositioners() {
    _floatingPositioners.clear();
    _floatingPositionersSorted = true;
  }

  /// Sort the FloatingPositioner objects (mirrors `SortPositioners`).
  void sortPositioners() {
    if (!_floatingPositionersSorted) {
      _floatingPositioners.sort((left, right) {
        final leftClassId = left.getObject()!.classId;
        final rightClassId = right.getObject()!.classId;
        if (leftClassId == rightClassId) {
          final Staffrel leftPlace = left.getDrawingPlace();
          final Staffrel rightPlace = right.getDrawingPlace();
          if (leftPlace == rightPlace) {
            return left
                    .getObject()!
                    .isCloserToStaffThan(right.getObject()!, rightPlace)
                ? -1
                : 1;
          } else {
            return leftPlace.value < rightPlace.value ? -1 : 1;
          }
        } else {
          return leftClassId.index.compareTo(rightClassId.index);
        }
      });
      _floatingPositionersSorted = true;
    }
  }

  /// Find all the intersection points with a vertical line (top to bottom)
  /// (mirrors `FindAllIntersectionPoints`).
  void findAllIntersectionPoints(SegmentedLine line, BoundingBox boundingBox,
      List<ClassId> classIds, int margin) {
    for (final positioner in _floatingPositioners) {
      assert(positioner.getObject() != null);
      if (!positioner.getObject()!.isAny(classIds.toSet())) {
        continue;
      }
      if (positioner.horizontalContentOverlap(boundingBox, margin ~/ 2)) {
        line.addGap(positioner.getContentTop() + margin,
            positioner.getContentBottom() - margin);
      }
    }
  }

  /// Returns the minimum preset spacing (mirrors `GetMinimumStaffSpacing`).
  int getMinimumStaffSpacing(Doc doc, ScoreDef attSpacing) {
    final option = doc.getOptions().spacingStaff;

    int staffSize = getStaffSize();
    // Revert ossia staff ratio for it not to impact vertical spacing
    if (_staff != null && _staff!.isOssia()) {
      staffSize = (staffSize / doc.getOptions().ossiaStaffSize.value).toInt();
    }

    int spacing = (option.value * docDrawingUnit(doc, staffSize)).toInt();

    if (!option.isSet && attSpacing.hasSpacingStaff) {
      final measurement = attSpacing.spacingStaff!;
      if (measurement.type == MeasurementType.px) {
        spacing = measurement.px;
      } else {
        spacing = (measurement.vu * docDrawingUnit(doc, 100)).toInt();
      }
    }
    return spacing;
  }

  // TODO(phase-4): AdjustBracketGroupSpacing / IsInBracketGroup arrive with
  // the staff overlap adjustment; they require Doc glyph heights (SMuFL
  // resources).
}
