/// Port of `adjustxrelfortranscriptionfunctor.h/cpp` and
/// `adjustyrelfortranscriptionfunctor.h/cpp` (35 lines each).
///
/// Both functors adjust the drawing positions of layer elements for
/// transcription layout (`Page::LayOutTranscription`, page.cpp:307-310).
/// Only elements with facsimile coordinates (`drawingFacsX/Y != meiUnset`)
/// and with a non-empty self bounding box are touched; scoreDef elements
/// are skipped with `FUNCTOR_SIBLINGS`.
///
/// Reference:
/// - `origin/src/include/vrv/adjustxrelfortranscriptionfunctor.h`
/// - `origin/src/src/adjustxrelfortranscriptionfunctor.cpp`
/// - `origin/src/include/vrv/adjustyrelfortranscriptionfunctor.h`
/// - `origin/src/src/adjustyrelfortranscriptionfunctor.cpp`
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/vrvdef.dart' show FunctorCode;
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/model/layer_element.dart';

/// This class adjusts the XRel positions taking into account the bounding
/// boxes (mirrors `vrv::AdjustXRelForTranscriptionFunctor`).
class AdjustXRelForTranscriptionFunctor extends Functor {
  AdjustXRelForTranscriptionFunctor();

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.drawingFacsX == meiUnset) return FunctorCode.continue_;
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;
    if (!layerElement.hasSelfBB()) return FunctorCode.continue_;
    layerElement.setDrawingXRel(-layerElement.getSelfX1());
    return FunctorCode.continue_;
  }
}

/// This class adjusts the YRel positions taking into account the bounding
/// boxes (mirrors `vrv::AdjustYRelForTranscriptionFunctor`).
class AdjustYRelForTranscriptionFunctor extends Functor {
  AdjustYRelForTranscriptionFunctor();

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.drawingFacsY == meiUnset) return FunctorCode.continue_;
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;
    if (!layerElement.hasSelfBB()) return FunctorCode.continue_;
    layerElement.setDrawingYRel(-layerElement.getSelfY1());
    return FunctorCode.continue_;
  }
}
