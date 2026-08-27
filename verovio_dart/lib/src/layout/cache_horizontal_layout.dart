/// Port of `cachehorizontallayoutfunctor.h/cpp` — caches or restores the
/// cached horizontal layout for faster layout redoing (`Page::LayOutHorizontallyWithCache`,
/// page.cpp:499-507), consumed by `Doc::CastOffDocBase` to skip re-running
/// `Page::LayOutHorizontally` on a document whose uncast-off page still has
/// its horizontal positions cached.
///
/// Deviations from the C++:
/// - Verified against `cpp_probe` task `04f` (`section/section-001.mei`,
///   the heaviest cast-off case of the fixed corpus): every `VisitArpeg` /
///   `VisitLayerElement` / `VisitMeasure` record matches at epsilon 0. Every
///   record in that fixture has `restore=false` — a single load/render pass
///   through the CLI never exercises `restore=true` (that only happens on a
///   *second* `Doc::CastOffDoc()` call after an `UnCastOffDoc()`, which the
///   toolkit's plain render pipeline never does) — so the restore branch is
///   instead verified on synthetic state in
///   `test/adjust_x_overflow_test.dart`.
/// - `Arpeg.cacheXRel` is a faithful port of `Arpeg::CacheXRel`, but see the
///   deviation note on `Arpeg.drawingXRel` in `control_elements_gen.dart`:
///   `AdjustArpegFunctor` (an earlier, out-of-scope task) never writes that
///   field in production, so this branch always caches/restores 0 today.
library;

import 'package:verovio_dart/src/core/vrvdef.dart' show FunctorCode;
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Measure;
import 'package:verovio_dart/src/model/control_elements_gen.dart' show Arpeg;
import 'package:verovio_dart/src/model/layer_element.dart' show LayerElement;

/// This class caches or restores cached horizontal layout for faster layout
/// redoing (mirrors `vrv::CacheHorizontalLayoutFunctor`).
class CacheHorizontalLayoutFunctor extends DocFunctor {
  CacheHorizontalLayoutFunctor(super.doc);

  /// Indicates if the cache should be stored (default) or restored (mirrors
  /// `m_restore`).
  bool restore = false;

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitArpeg(Arpeg arpeg) {
    arpeg.cacheXRel(restore: restore);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    layerElement.cacheXRel(restore: restore);
    layerElement.cacheYRel(restore: restore);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    measure.cacheXRel(restore: restore);

    visitBarLine(measure.getLeftBarLine());
    visitBarLine(measure.getRightBarLine());

    return FunctorCode.continue_;
  }
}
