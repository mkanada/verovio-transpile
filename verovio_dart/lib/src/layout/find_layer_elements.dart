/// Ports of the find-layer-elements functors sharing the role of
/// `findlayerelementsfunctor.cpp`:
///
/// - [LayersInTimeSpanFunctor] mirrors `LayersInTimeSpanFunctor`
///   (findlayerelementsfunctor.cpp:26) — collects the layer `@n`s occurring in
///   a given time / duration span.
library;

import 'package:verovio_dart/src/core/fraction.dart' show Fraction;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show AlignMeterParams, LayerElementAlignmentDuration;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show MeterSig;
import 'package:verovio_dart/src/model/mensur.dart' show Mensur;
import 'package:verovio_dart/src/model/object.dart';

/// Collects all layer `@n`s which appear in the given time / duration (mirrors
/// `vrv::LayersInTimeSpanFunctor`, findlayerelementsfunctor.cpp:26).
class LayersInTimeSpanFunctor extends Functor {
  LayersInTimeSpanFunctor(
      final Object? meterSig, final Object? mensur) {
    meterParams.meterSig = meterSig;
    meterParams.mensur = mensur;
  }

  /// The current time alignment parameters (mirrors `m_meterParams`).
  final AlignMeterParams meterParams = AlignMeterParams();

  /// The time of the event (mirrors `m_time`).
  Fraction time = Fraction(0);

  /// The duration of the event (mirrors `m_duration`).
  Fraction duration = Fraction(0);

  /// The layers (layerN) found (mirrors `m_layers`).
  final Set<int> layers = {};

  /// Set the time and duration of the event (mirrors `SetEvent`).
  void setEvent(Fraction time, Fraction duration) {
    this.time = time;
    this.duration = duration;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    // For mRest we do not look at the time span
    if (layerElement.isClass(ClassId.mRest)) {
      // Add the layerN to the list of layers occurring in this time frame
      layers.add(layerElement.getAlignmentLayerN());
      return FunctorCode.siblings;
    }

    if (!layerElement.hasInterface(InterfaceId.duration) ||
        layerElement.isClass(ClassId.mSpace) ||
        layerElement.isClass(ClassId.space) ||
        layerElement.hasSameasLink) {
      return FunctorCode.continue_;
    }
    if (layerElement.isClass(ClassId.note) &&
        layerElement.parent!.isClass(ClassId.chord)) {
      return FunctorCode.continue_;
    }

    final Fraction elementDuration =
        layerElement.getAlignmentDuration(meterParams);
    final Fraction elementTime = layerElement.getAlignment()!.getTime();

    // The event is starting after the end of the element
    if ((elementTime + elementDuration) <= time) {
      return FunctorCode.continue_;
    }
    // The element is starting after the event end - we can stop here
    else if (elementTime >= (time + duration)) {
      return FunctorCode.stop;
    }

    // Add the layerN to the list of layers occurring in this time frame
    layers.add(layerElement.getAlignmentLayerN());

    // Not need to recurse for chords? Not quite sure about it.
    return (layerElement.isClass(ClassId.chord))
        ? FunctorCode.siblings
        : FunctorCode.continue_;
  }

  @override
  FunctorCode visitMensur(Mensur mensur) {
    meterParams.mensur = mensur;
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeterSig(MeterSig meterSig) {
    meterParams.meterSig = meterSig;
    return FunctorCode.continue_;
  }
}
