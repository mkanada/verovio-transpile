/// Port of `facsimileinterface.h/cpp` — interface for elements with a
/// facs link to a surface/zone.
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_facsimile.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/zone.dart';

/// Minimal stand-in for the `Surface` element until the facsimile model
/// classes are ported; holds the zone children.
class FacsSurface extends Object {
  @override
  ClassId get classId => ClassId.surface;

  @override
  String get className => 'surface';

  @override
  Object clone() {
    final copy = FacsSurface();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) => classId == ClassId.zone;
}

/// Mirrors `vrv::FacsimileInterface`.
///
/// Apply together with [AttFacsimile].
mixin FacsimileInterface on AttFacsimile implements Interface {
  /// The resolved zone (from @facs).
  Zone? zone;

  /// The resolved surface containing the zone.
  FacsSurface? surface;

  @override
  InterfaceId get interfaceId => InterfaceId.facsimile;

  @override
  void reset() {
    facs = null;
    zone = null;
    surface = null;
  }

  /// Check if the object has a facsimile.
  bool get hasFacsimile => hasFacs;

  /// Copies the interface state from [other].
  void copyFacsimileFrom(covariant FacsimileInterface other) {
    facs = other.facs;
    zone = other.zone;
    surface = other.surface;
  }

  /// Link to the zone.
  void attachZone(Zone newZone) {
    if (zone != null) {
      logWarning('Replacing an existing zone in FacsimileInterface');
    }
    zone = newZone;
    final Object? parent = newZone.parent;
    if (parent is FacsSurface) {
      surface = parent;
    } else {
      logWarning('Zone has no valid parent surface');
      surface = null;
    }
  }
}
