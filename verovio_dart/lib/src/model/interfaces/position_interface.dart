/// Port of `positioninterface.h/cpp` — interface for elements with a
/// position on the staff, such as rests.
library;

import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';

/// Mirrors `vrv::PositionInterface`.
///
/// Apply together with [AttStaffLoc] and [AttStaffLocPitched].
mixin PositionInterface
    on AttStaffLoc, AttStaffLocPitched
    implements Interface {
  /// The drawing location of the object (set by CalcAlignmentPitchPosFunctor).
  int drawingLoc = 0;

  @override
  InterfaceId get interfaceId => InterfaceId.position;

  @override
  void reset() {
    loc = null;
    oloc = null;
    ploc = null;
    drawingLoc = 0;
  }

  /// Copies the interface state from [other].
  void copyPositionFrom(covariant PositionInterface other) {
    loc = other.loc;
    oloc = other.oloc;
    ploc = other.ploc;
    drawingLoc = other.drawingLoc;
  }

  /// Interface comparison operator: checks the attributes of both.
  bool hasIdenticalPositionInterface(PositionInterface? other) {
    if (other == null) return false;
    if (loc != other.loc) return false;
    if (oloc != other.oloc) return false;
    if (ploc != other.ploc) return false;
    return true;
  }

  /// Calculate the drawing loc from @ploc/@oloc or @loc.
  ///
  /// The [clefLocOffset] corresponds to `layer->GetClefLocOffset(element)`
  /// and arrives from the layout phase.
  int calcDrawingLoc({required int clefLocOffset}) {
    drawingLoc = 0;
    if (hasPloc && hasOloc) {
      final Pitchname? pl = ploc;
      final int? ol = oloc;
      if (pl != null && ol != null) {
        // PitchInterface::CalcLoc inline to avoid the dependency cycle.
        drawingLoc = (ol - octaveOffset) * 7 + (pl.value - 1) + clefLocOffset;
      }
    } else if (hasLoc) {
      drawingLoc = loc ?? 0;
    }
    return drawingLoc;
  }
}
