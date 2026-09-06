/// Port of `facsimileinterface.h/cpp` — interface for elements with a
/// facs link to a surface/zone.
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_facsimile.dart';
import 'package:verovio_dart/src/model/interfaces/interface.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show Surface;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/zone.dart';

/// Mirrors `vrv::FacsimileInterface`.
///
/// Apply together with [AttFacsimile].
mixin FacsimileInterface on AttFacsimile implements Interface {
  /// The resolved zone (from @facs; mirrors `m_zone`).
  Zone? zone;

  /// The resolved surface (from @facs when it references a `<surface>`
  /// directly, e.g. `Pb`/`Sb`; mirrors `m_surface`).
  Surface? surface;

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

  /// Mirrors `FacsimileInterface::GetWidth` (facsimileinterface.cpp:62-66):
  /// the zone's width in MEI units. Asserts a resolved zone, like the C++.
  int getWidth() {
    assert(zone != null);
    return (zone!.lrx ?? 0) - (zone!.ulx ?? 0);
  }

  /// Mirrors `FacsimileInterface::GetHeight` (facsimileinterface.cpp:68-71):
  /// the zone's logical height in MEI units.
  int getHeight() {
    assert(zone != null);
    return (zone!.getLogicalLry() ?? 0) - (zone!.getLogicalUly() ?? 0);
  }

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
    if (parent is Surface) {
      surface = parent;
    } else {
      logWarning('Zone has no valid parent surface');
      surface = null;
    }
  }
}
