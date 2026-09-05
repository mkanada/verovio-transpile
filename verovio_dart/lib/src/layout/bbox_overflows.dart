/// Port of `calcbboxoverflowsfunctor.h/cpp` — CalcBBoxOverflowsFunctor.
///
/// This functor fills the arrays of bounding boxes (above and below) for
/// each staff alignment for which the box overflows.
///
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show LayoutElementHelpers;
import 'package:verovio_dart/src/layout/vertical_aligner.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart'
    show BeamDrawingInterface;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Beam, FTrem, KeySig, MeterSig;
import 'package:verovio_dart/src/model/mensur.dart' show Mensur;
import 'package:verovio_dart/src/model/object.dart';

/// This class fills the arrays of bounding boxes (above and below) for each
/// staff alignment for which the box overflows (mirrors
/// `vrv::CalcBBoxOverflowsFunctor`).
class CalcBBoxOverflowsFunctor extends DocFunctor {
  CalcBBoxOverflowsFunctor(super.doc);

  @override
  FunctorCode visitLayerEnd(Layer layer) {
    // Mirrors `CalcBBoxOverflowsFunctor::VisitLayerEnd`
    // (calcbboxoverflowsfunctor.cpp:27-42): revisits the four cautionary
    // staffDef objects if present, via VisitClef / VisitKeySig etc., exactly
    // as the C++ does. The Dart Layer already stores all four (field
    // `cautionStaffDef*`), so no model gap remains.
    final Clef? cautionClef = layer.getCautionStaffDefClef();
    if (cautionClef != null) {
      visitClef(cautionClef);
    }
    final KeySig? cautionKeySig = layer.getCautionStaffDefKeySig();
    if (cautionKeySig != null) {
      visitKeySig(cautionKeySig);
    }
    final Mensur? cautionMensur = layer.getCautionStaffDefMensur();
    if (cautionMensur != null) {
      visitMensur(cautionMensur);
    }
    final MeterSig? cautionMeterSig = layer.getCautionStaffDefMeterSig();
    if (cautionMeterSig != null) {
      visitMeterSig(cautionMeterSig);
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitObject(Object object) {
    // starting a new staff
    if (object.isClass(ClassId.staff)) {
      final Staff currentStaff = object as Staff;
      if (currentStaff.visible == false) {
        return FunctorCode.siblings;
      }
      return FunctorCode.continue_;
    }

    // starting new layer: the scoreDef attrs are visited through the normal
    // traversal in this port (they are tree children of the layer).
    if (object.isClass(ClassId.layer)) {
      return FunctorCode.continue_;
    }

    if (object.isSystemElement) {
      return FunctorCode.continue_;
    }

    if (object.isControlElement) {
      return FunctorCode.continue_;
    }

    if (!object.isLayerElement) {
      return FunctorCode.continue_;
    }

    // Take into account beam in cross-staff situation (mirrors
    // calcbboxoverflowsfunctor.cpp:88-93): ignore it if it has cross-staff
    // content but is not entirely cross-staff itself.
    if (object.isClass(ClassId.beam)) {
      final Beam beam = object as Beam;
      if (beam.crossStaffContent != null && beam.crossStaff == null) {
        return FunctorCode.continue_;
      }
    }

    // Take into account stem for notes in cross-staff situation and in
    // beams (mirrors calcbboxoverflowsfunctor.cpp:96-110): ignore the stem
    // of a cross-staff note/chord when its ancestor beam is not itself
    // entirely cross-staff, or when the note/chord is in a beamSpan.
    if (object.isClass(ClassId.stem)) {
      final Object? noteOrChord = object.parent;
      if (noteOrChord is LayerElement && noteOrChord.crossStaff != null) {
        final Object? beamAncestor =
            noteOrChord.getFirstAncestor(ClassId.beam);
        if (beamAncestor != null) {
          final Beam beam = beamAncestor as Beam;
          if (beam.crossStaff == null) {
            return FunctorCode.continue_;
          }
        } else if (noteOrChord.isInBeamSpan) {
          return FunctorCode.continue_;
        }
      }
    }

    if (object.isAny(const {ClassId.fb, ClassId.fig})) {
      return FunctorCode.continue_;
    }

    if (object.isClass(ClassId.syl)) {
      // We don't want to add the syl to the overflow since lyrics require a
      // full line anyway
      return FunctorCode.continue_;
    }

    final LayerElement current = object as LayerElement;
    if (!current.hasSelfBB()) {
      // if nothing was drawn, do not take it into account
      return FunctorCode.continue_;
    }

    // Deviation: GetOverflowStaffAlignments carries the plain staff
    // alignment plus the cross-staff chord redirect; the beam / stem
    // cross-staff exceptions (m_crossStaffContent, GetAncestorBeam checks)
    // arrive with the beam segment phase.
    StaffAlignment? above;
    StaffAlignment? below;
    _getOverflowStaffAlignments(current, (a, b) {
      above = a;
      below = b;
    });

    bool isScoreDefClef = false;
    // Exception for the scoreDef clef where we do not want to take into
    // account the general overflow. We have instead distinct members in
    // StaffAlignment to store them.
    if (current.isClass(ClassId.clef) &&
        current.getScoreDefRole() == ElementScoreDefRole.system) {
      isScoreDefClef = true;
    }

    if (above != null) {
      int overflowAbove = above!.calcOverflowAbove(current);
      int staffSize = above!.getStaffSize();
      if (overflowAbove > getStaffLineWidth(staffSize) ~/ 2) {
        if (isScoreDefClef) {
          above!.setScoreDefClefOverflowAbove(overflowAbove);
        } else {
          above!.setOverflowAbove(overflowAbove);
        }
        above!.addBBoxAbove(current);
      }
    }

    if (below != null) {
      int overflowBelow = below!.calcOverflowBelow(current);
      int staffSize = below!.getStaffSize();
      if (overflowBelow > getStaffLineWidth(staffSize) ~/ 2) {
        if (isScoreDefClef) {
          below!.setScoreDefClefOverflowBelow(overflowBelow);
        } else {
          below!.setOverflowBelow(overflowBelow);
        }
        below!.addBBoxBelow(current);
      }
    }

    return FunctorCode.continue_;
  }

  /// Port of `LayerElement::GetOverflowStaffAlignments`
  /// (layerelement.cpp:325): both overflows start at the alignment of the
  /// ancestor staff, then [LayerElement.getChordOverflow] redirects them for
  /// dots/flags/stems inside cross-staff chords, stems inside cross-staff
  /// beams/fTrems redirect via `getBeamChildOverflow` (layerelement.cpp:334-
  /// 344), and beams/fTrems that are themselves cross-staff redirect via
  /// `getBeamOverflow` (layerelement.cpp:346-350).
  static void _getOverflowStaffAlignments(LayerElement element,
      void Function(StaffAlignment? above, StaffAlignment? below) result) {
    final Staff? staff = element.getAncestorStaffResolveCrossStaff();
    StaffAlignment? above = staff?.staffAlignment;
    StaffAlignment? below = above;
    if (staff != null) {
      final (StaffAlignment?, StaffAlignment?) overflows =
          element.getChordOverflow(above, below, staff.n ?? 0);
      above = overflows.$1;
      below = overflows.$2;
    }

    if (element.isAny(const {ClassId.artic, ClassId.stem})) {
      final Object? beamAncestor = element.getFirstAncestor(ClassId.beam);
      if (beamAncestor != null) {
        final Beam beam = beamAncestor as Beam;
        if (beam.crossStaff == null) {
          final (StaffAlignment?, StaffAlignment?) overflows =
              beam.getBeamChildOverflow(above, below);
          above = overflows.$1;
          below = overflows.$2;
        }
      } else {
        final Object? fTremAncestor = element.getFirstAncestor(ClassId.fTrem);
        if (fTremAncestor != null) {
          final FTrem fTrem = fTremAncestor as FTrem;
          if (fTrem.crossStaff == null) {
            final (StaffAlignment?, StaffAlignment?) overflows =
                fTrem.getBeamChildOverflow(above, below);
            above = overflows.$1;
            below = overflows.$2;
          }
        }
      }
    } else if (element.isAny(const {ClassId.beam, ClassId.fTrem}) &&
        element.crossStaff == null) {
      final (StaffAlignment?, StaffAlignment?) overflows =
          (element as BeamDrawingInterface).getBeamOverflow(above, below);
      above = overflows.$1;
      below = overflows.$2;
    }

    result(above, below);
  }

  /// Mirrors `Doc::GetDrawingStaffLineWidth(staffSize)` (staffLineWidth
  /// option, default 0.10).
  int getStaffLineWidth(int staffSize) =>
      (doc.getOptions().staffLineWidth.value * doc.getDrawingUnit(staffSize))
          .toInt();
}
