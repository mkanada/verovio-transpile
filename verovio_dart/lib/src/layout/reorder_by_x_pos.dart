/// Port of `miscfunctor.h/cpp` — `ReorderByXPosFunctor` and
/// `Object::ReorderByXPos()` / `Object::sortByUlx` (~40 lines).
///
/// Reorders children by the facsimile `ulx` coordinate. Only used by the
/// neume editor (`editortoolkit_neume.cpp`, Phase 6) but ported here to close
/// the Phase-4 checkbox. Validation is synthetic.
///
/// Reference:
/// - `origin/src/include/vrv/miscfunctor.h:175`
/// - `origin/src/src/miscfunctor.cpp:167-184`
/// - `origin/src/src/object.cpp:1222-1259` (`ReorderByXPos`)
/// - `origin/src/src/object.cpp:1296-1359` (`sortByUlx`)
library;

import 'package:verovio_dart/src/core/logging.dart' show logInfo;
import 'package:verovio_dart/src/core/vrvdef.dart' show ClassId, FunctorCode;
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/model/interfaces/facsimile_interface.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show Nc;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/zone.dart' show Zone;

/// Mirrors `vrv::Object::sortByUlx` (object.cpp:1296).
///
/// Returns true if [a] should be ordered before [b] by facsimile `ulx`.
/// The algorithm mirrors the C++ exactly:
/// - If the object itself has a facsimile (`hasFacs`), that zone's `ulx` is used.
/// - Otherwise the minimal `ulx` among all facsimile descendants (excluding `Syl`) is used.
/// - If either side has no facsimile, ordering is preserved (`false`).
/// - For two adjacent `Nc` children of the same parent with identical `ulx` and both
///   `hasLigated`, order by pitch (higher pitch first).
bool sortByUlx(Object a, Object b) {
  FacsimileInterface? fa;
  FacsimileInterface? fb;

  // Helper to obtain the representative facsimile interface for an object.
  FacsimileInterface? representative(Object obj) {
    if (obj is FacsimileInterface && (obj as FacsimileInterface).hasFacs) {
      return obj as FacsimileInterface;
    }
    // Search descendants with facsimile interface, skipping Syl.
    // Note: Dart's LayerElement does not register InterfaceId.facsimile via
    // hasInterface (unlike C++ GetFacsimileInterface), so we check `is`
    // directly instead of using InterfaceComparison.
    FacsimileInterface? best;
    void collect(Object current) {
      for (final Object child in current.children) {
        if (child is FacsimileInterface) {
          final FacsimileInterface fi = child as FacsimileInterface;
          if (child.classId != ClassId.syl && fi.hasFacs) {
            final Zone? zone = fi.zone;
            if (zone != null && zone.ulx != null) {
              if (best == null || zone.ulx! < best!.zone!.ulx!) {
                best = fi;
              }
            }
          }
        }
        // Recurse regardless of interface, to find deeper facsimile descendants
        // (e.g., Neume -> Nc).
        collect(child);
      }
    }

    collect(obj);
    return best;
  }

  fa = representative(a);
  fb = representative(b);

  // Preserve ligature neume component ordering when ulx is identical.
  if (a.classId == ClassId.nc && b.classId == ClassId.nc) {
    final Nc nca = a as Nc;
    final Nc ncb = b as Nc;
    final Zone? zoneA = (nca as FacsimileInterface).zone;
    final Zone? zoneB = (ncb as FacsimileInterface).zone;
    // Both have zones and are ligated, same parent, same ulx, adjacent index.
    if (zoneA != null &&
        zoneB != null &&
        zoneA.ulx != null &&
        zoneB.ulx != null &&
        nca.hasLigated &&
        ncb.hasLigated &&
        identical(a.parent, b.parent) &&
        zoneA.ulx == zoneB.ulx) {
      final Object? parent = a.parent;
      if (parent != null) {
        final int idxA = parent.getChildIndex(a);
        final int idxB = parent.getChildIndex(b);
        if ((idxA - idxB).abs() == 1) {
          // Return nc with higher pitch first (mirrors `PitchDifferenceTo > 0`).
          return nca.pitchDifferenceTo(ncb) > 0;
        }
      }
    }
  }

  if (fa == null || fb == null) {
    if (fa == null) {
      logInfo('No available facsimile interface for ${a.id}');
    }
    if (fb == null) {
      logInfo('No available facsimile interface for ${b.id}');
    }
    return false;
  }

  final int ulxA = fa.zone!.ulx!;
  final int ulxB = fb.zone!.ulx!;
  return ulxA < ulxB;
}

/// This class reorders elements by x-position (mirrors
/// `vrv::ReorderByXPosFunctor`).
class ReorderByXPosFunctor extends Functor {
  ReorderByXPosFunctor();

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitObject(Object object) {
    // Mirrors miscfunctor.cpp:171-174 — objects that already have a facs
    // would have been reordered already, so skip their children.
    if (object is FacsimileInterface) {
      final FacsimileInterface fi = object as FacsimileInterface;
      if (fi.hasFacs) {
        return FunctorCode.siblings;
      }
    }

    final List<Object> children = object.childrenForModification;
    // Stable sort by ulx (mirrors `std::stable_sort(..., Object::sortByUlx)`).
    // Dart's `List.sort` is stable since Dart 2.13, but we enforce stability
    // explicitly via indexed decoration to stay faithful on every runtime.
    final List<({Object obj, int idx})> indexed = [
      for (int i = 0; i < children.length; i++) (obj: children[i], idx: i)
    ];
    indexed.sort((x, y) {
      final bool xBeforeY = sortByUlx(x.obj, y.obj);
      final bool yBeforeX = sortByUlx(y.obj, x.obj);
      if (xBeforeY && !yBeforeX) return -1;
      if (yBeforeX && !xBeforeY) return 1;
      return x.idx.compareTo(y.idx);
    });
    children
      ..clear()
      ..addAll(indexed.map((e) => e.obj));

    object.modify();

    return FunctorCode.continue_;
  }
}

/// Extension that mirrors `vrv::Object::ReorderByXPos()` (object.cpp:1222).
extension ReorderByXPosExtension on Object {
  /// Reorders the object's children and all descendants by facsimile `ulx`
  /// (mirrors `Object::ReorderByXPos`).
  void reorderByXPos() {
    final ReorderByXPosFunctor functor = ReorderByXPosFunctor();
    process(functor);
  }
}
