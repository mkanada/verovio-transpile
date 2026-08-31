/// Port of `justifyfunctor.h/cpp`:
///
/// - [JustifyXFunctor]: justifies the X positions
/// - [JustifyYFunctor]: justifies the Y positions
/// - [JustifyYAdjustCrossStaffFunctor]: adjusts the cross staff content after
///   vertical justification
///
/// The orchestration is `Page.justifyHorizontally` / `Page.justifyVertically`
/// (doc.dart), mirroring `Page::JustifyHorizontally` /
/// `Page::JustifyVertically`.
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment, MeasureAligner;
import 'package:verovio_dart/src/layout/vertical_aligner.dart'
    show SpacingType, StaffAlignment;
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Stemdirection;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Measure, Note, Section, Staff;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Chord, Flag, Stem;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;

// ---------------------------------------------------------------------------
// JustifyXFunctor
// ---------------------------------------------------------------------------

/// This class justifies the X positions (mirrors `vrv::JustifyXFunctor`).
class JustifyXFunctor extends DocFunctor {
  JustifyXFunctor(super.doc);

  /// The relative X position of the next measure (mirrors `m_measureXRel`).
  int _measureXRel = 0;

  /// The justification ratio (mirrors `m_justifiableRatio`).
  double _justifiableRatio = 1.0;

  /// The left / right barline X position (mirrors `m_leftBarLineX` /
  /// `m_rightBarLineX`).
  int _leftBarLineX = 0;
  int _rightBarLineX = 0;

  /// The system full width without system margins (mirrors
  /// `m_systemFullWidth`).
  int _systemFullWidth = 0;

  /// Indicates a shift of the next measure due to a section restart (mirrors
  /// `m_applySectionRestartShift`).
  bool _applySectionRestartShift = false;

  /// Set the full system width (mirrors `SetSystemFullWidth`).
  void setSystemFullWidth(int width) => _systemFullWidth = width;

  @override
  FunctorCode visitAlignment(Alignment alignment) {
    final AlignmentType alignmentType = alignment.getType();
    if (alignmentType.value <= AlignmentType.measureLeftBarline.value) {
      // Nothing to do for all left scoreDef elements and the left barline.
    } else if (alignmentType.value < AlignmentType.measureRightBarline.value) {
      // All elements up to the next barline: move them but also take into
      // account the leftBarLineX.
      alignment.setXRel(
          (((alignment.getXRel() - _leftBarLineX) * _justifiableRatio) +
                  _leftBarLineX)
              .ceil());
    } else {
      // Now move the right barline and all right scoreDef elements.
      final int shift = alignment.getXRel() - _rightBarLineX;
      alignment.setXRel(
          (((_rightBarLineX - _leftBarLineX) * _justifiableRatio) +
                  _leftBarLineX +
                  shift)
              .ceil());
    }

    // Finally, when reaching the end of the measure, update the measureXRel
    // for the next measure.
    if (alignmentType == AlignmentType.measureEnd) {
      _measureXRel += alignment.getXRel();
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    if (_applySectionRestartShift) {
      _measureXRel += _sectionRestartShift(measure);
      _applySectionRestartShift = false;
    }

    if (_measureXRel > 0) {
      measure.setDrawingXRel(_measureXRel);
    } else {
      _measureXRel = measure.getDrawingXRel();
    }

    measure.measureAligner.process(this);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasureAligner(MeasureAligner measureAligner) {
    _leftBarLineX = measureAligner.getLeftBarLineAlignment()!.getXRel();
    _rightBarLineX = measureAligner.getRightBarLineAlignment()!.getXRel();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    if (scoreDef.drawingLabelsWidth > 0) {
      _measureXRel += scoreDef.drawingLabelsWidth;
      _applySectionRestartShift = false;
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSection(Section section) {
    if (section.restart == true) {
      _applySectionRestartShift = true;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    _measureXRel = 0;
    final int margins = system.systemLeftMar + system.systemRightMar;
    // drawingTotalWidth includes the labels.
    final int nonJustifiableWidth =
        margins + (system.drawingTotalWidth - system.drawingJustifiableWidth);
    // Deviation: guard against an empty system (division by zero in C++).
    if (system.drawingJustifiableWidth <= 0) {
      return FunctorCode.siblings;
    }
    _justifiableRatio = (_systemFullWidth - nonJustifiableWidth) /
        system.drawingJustifiableWidth;

    if (_justifiableRatio < 0.8) {
      // Arbitrary value for avoiding over-compressed justification.
      logWarning('Justification is highly compressed (ratio smaller than 0.8: '
          '$_justifiableRatio)');
      logWarning('\tSystem full width: $_systemFullWidth');
      logWarning('\tNon-justifiable width: $nonJustifiableWidth');
      logWarning(
          '\tDrawing justifiable width: ${system.drawingJustifiableWidth}');
    }

    // Check if we are on the last system of an mdiv. Do not justify it if the
    // non-justified width is less than a specified percent.
    if (system.isLastOfMdiv() || system.isLastOfSelection()) {
      final double minLastJust = doc.getOptions().minLastJustification.value;
      if ((minLastJust > 0.0) && (_justifiableRatio > (1.0 / minLastJust))) {
        return FunctorCode.siblings;
      }
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `Measure::GetSectionRestartShift`.
  int _sectionRestartShift(Measure measure) {
    if (measure.isFirstInSystem()) return 0;
    return 5 * doc.getDrawingDoubleUnit(100);
  }
}

// ---------------------------------------------------------------------------
// JustifyYFunctor
// ---------------------------------------------------------------------------

/// A map of calculated shifts per StaffAlignment (mirrors `vrv::ShiftMap`).
typedef ShiftMap = Map<StaffAlignment, int>;

/// This class justifies the Y positions (mirrors `vrv::JustifyYFunctor`).
class JustifyYFunctor extends DocFunctor {
  JustifyYFunctor(super.doc);

  /// The cumulated shift (mirrors `m_cumulatedShift`).
  int _cumulatedShift = 0;

  /// The relative shift of the staff w.r.t. the system (mirrors
  /// `m_relativeShift`).
  int _relativeShift = 0;

  /// The amount of space for distribution (mirrors `m_spaceToDistribute`).
  int _spaceToDistribute = 0;

  /// The sum of justification factors per page (mirrors
  /// `m_justificationSum`).
  double _justificationSum = 0.0;

  /// A map of calculated shifts per StaffAlignment (mirrors
  /// `m_shiftForStaff`); transferred to [JustifyYAdjustCrossStaffFunctor].
  final ShiftMap _shiftForStaff = {};

  void setJustificationSum(double justificationSum) =>
      _justificationSum = justificationSum;
  void setSpaceToDistribute(int space) => _spaceToDistribute = space;
  ShiftMap getShiftForStaff() => _shiftForStaff;

  @override
  FunctorCode visitStaffAlignment(StaffAlignment staffAlignment) {
    if (_justificationSum <= 0.0) return FunctorCode.stop;
    if (_spaceToDistribute <= 0) return FunctorCode.stop;

    // Skip bottom aligner and first staff.
    if (staffAlignment.getStaff() != null &&
        staffAlignment.getSpacingType() != SpacingType.system) {
      final int shift = (staffAlignment.getJustificationFactor(doc) /
              _justificationSum *
              _spaceToDistribute)
          .toInt();
      _relativeShift += shift;
      _cumulatedShift += shift;

      staffAlignment.setYRel(staffAlignment.getYRel() - _relativeShift);
    }

    _shiftForStaff[staffAlignment] = _cumulatedShift;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    if (_justificationSum <= 0.0) return FunctorCode.stop;
    if (_spaceToDistribute <= 0) return FunctorCode.stop;

    final double systemJustificationFactor =
        doc.getOptions().justificationSystem.value;
    final double shift =
        systemJustificationFactor / _justificationSum * _spaceToDistribute;

    if (!system.isFirstInPage()) {
      _cumulatedShift += shift.toInt();
    }

    system.setDrawingYRel(system.getDrawingY() - _cumulatedShift.toInt());

    _relativeShift = 0;
    system.systemAligner.process(this);

    return FunctorCode.siblings;
  }
}

// ---------------------------------------------------------------------------
// JustifyYAdjustCrossStaffFunctor
// ---------------------------------------------------------------------------

/// This class adjusts the cross staff content after vertical justification
/// (mirrors `vrv::JustifyYAdjustCrossStaffFunctor`).
class JustifyYAdjustCrossStaffFunctor extends DocFunctor {
  JustifyYAdjustCrossStaffFunctor(super.doc);

  /// A map of calculated shifts per StaffAlignment transferred from
  /// [JustifyYFunctor] (mirrors `m_shiftForStaff`).
  ShiftMap _shiftForStaff = {};

  /// Transfer the shift map (mirrors `SetShiftForStaff`).
  void setShiftForStaff(ShiftMap shiftMap) => _shiftForStaff = shiftMap;

  @override
  FunctorCode visitChord(Chord chord) {
    // Check if chord spreads across several staves.
    final Map<int, Staff> extremalStaves = {};
    for (final Note? note in [chord.getTopNote(), chord.getBottomNote()]) {
      if (note == null) continue;
      final Staff? staff = _resolveStaff(note);
      if (staff != null) extremalStaves[staff.n ?? 0] = staff;
    }
    // Get the chord parent staff.
    final Staff? parentStaff = _resolveStaff(chord);
    if (parentStaff != null) extremalStaves[parentStaff.n ?? 0] = parentStaff;

    if (extremalStaves.length < 2) return FunctorCode.continue_;

    final List<int> sortedNs = extremalStaves.keys.toList()..sort();
    final int shift = getShift(extremalStaves[sortedNs.last]!) -
        getShift(extremalStaves[sortedNs.first]!);

    // Add the shift to the stem length of the chord.
    final Stem? stem = chord.findDescendantByType(ClassId.stem) as Stem?;
    if (stem == null) return FunctorCode.continue_;

    final int stemLen = stem.getDrawingStemLen();
    if (stem.getDrawingStemDir() == Stemdirection.up) {
      stem.setDrawingStemLen(stemLen - shift);
    } else {
      stem.setDrawingStemLen(stemLen + shift);
    }

    // Reposition the stem.
    final Staff rootStaff = (stem.getDrawingStemDir() == Stemdirection.up)
        ? extremalStaves[sortedNs.last]!
        : extremalStaves[sortedNs.first]!;
    stem.setDrawingYRel(
        stem.drawingYRel + getShift(parentStaff!) - getShift(rootStaff));

    // Add the shift to the flag position.
    final Flag? flag = stem.findDescendantByType(ClassId.flag) as Flag?;
    if (flag != null) {
      final int sign = (stem.getDrawingStemDir() == Stemdirection.up) ? 1 : -1;
      flag.setDrawingYRel(flag.drawingYRel + sign * shift);
    }

    return FunctorCode.continue_;
  }

  /// Calculate the shift due to vertical justification (mirrors `GetShift`).
  int getShift(Staff staff) {
    final StaffAlignment? alignment = staff.getAlignment();
    if (alignment != null && _shiftForStaff.containsKey(alignment)) {
      return _shiftForStaff[alignment]!;
    }
    return 0;
  }

  /// Headless variant of `GetAncestorStaff(RESOLVE_CROSS_STAFF)`: the
  /// cross-staff when set, the ancestor staff otherwise.
  static Staff? _resolveStaff(Object object) {
    if (object is LayerElement) {
      final Staff? cross = object.crossStaff;
      if (cross != null) return cross;
    }
    return object.getFirstAncestor(ClassId.staff) as Staff?;
  }
}
