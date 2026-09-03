/// Ports of the find-layer-elements functors sharing the role of
/// `findlayerelementsfunctor.cpp`:
///
/// - [LayersInTimeSpanFunctor] mirrors `LayersInTimeSpanFunctor`
///   (findlayerelementsfunctor.cpp:26) — collects the layer `@n`s occurring in
///   a given time / duration span.
/// - [LayerElementsInTimeSpanFunctor] mirrors `LayerElementsInTimeSpanFunctor`
///   (findlayerelementsfunctor.cpp:86) — collects the layer elements
///   occurring in a given time / duration span, restricted to one layer (or
///   to every layer but it).
/// - [GetRelativeLayerElementFunctor] mirrors `GetRelativeLayerElementFunctor`
///   (findlayerelementsfunctor.cpp:249) — the next/previous note, chord or
///   ftrem relative to a given layer element index (or the first one found
///   when searching a neighboring layer).
library;

import 'package:verovio_dart/src/core/fraction.dart' show Fraction;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show AlignMeterParams, LayerElementAlignmentDuration;
import 'package:verovio_dart/src/model/basic_elements.dart' show Layer, Note;
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

/// Collects all layer elements which appear in the given time / duration
/// (mirrors `vrv::LayerElementsInTimeSpanFunctor`,
/// findlayerelementsfunctor.cpp:86).
class LayerElementsInTimeSpanFunctor extends Functor {
  LayerElementsInTimeSpanFunctor(
      final Object? meterSig, final Object? mensur, this.layer) {
    meterParams.meterSig = meterSig;
    meterParams.mensur = mensur;
  }

  // Mirrors `ImplementsEndInterface() const override { return false; }`
  // (findlayerelementsfunctor.h). Without this, `Object.process` fires the
  // generic end-visit after a node's own visit, which resets `code` back to
  // `continue_` (see `Functor.visitLayerElementEnd`'s default) — silently
  // undoing the `FunctorCode.stop` this functor returns once the time
  // window has passed, so the traversal would collect elements beyond it.
  @override
  bool get implementsEndInterface => false;

  /// The current time alignment parameters (mirrors `m_meterParams`).
  final AlignMeterParams meterParams = AlignMeterParams();

  /// The time of the event (mirrors `m_time`).
  Fraction time = Fraction(0);

  /// The duration of the event (mirrors `m_duration`).
  Fraction duration = Fraction(0);

  /// The list of layer elements found (mirrors `m_elements`).
  final List<Object> elements = [];

  /// The layer to consider (mirrors `m_layer`).
  final Layer? layer;

  /// ... or to ignore (mirrors `m_allLayersButCurrent`).
  bool allLayersButCurrent = false;

  /// Set the time and duration of the event (mirrors `SetEvent`).
  void setEvent(Fraction time, Fraction duration) {
    this.time = time;
    this.duration = duration;
  }

  /// Consider all layers except the current one (mirrors
  /// `ConsiderAllLayersButCurrent`).
  void considerAllLayersButCurrent() => allLayersButCurrent = true;

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    final Layer? currentLayer =
        layerElement.getFirstAncestor(ClassId.layer) as Layer?;
    // Either get layer referenced by `layer` or all layers but it, depending
    // on the `allLayersButCurrent` flag.
    if ((!allLayersButCurrent && currentLayer != layer) ||
        (allLayersButCurrent && currentLayer == layer)) {
      return FunctorCode.siblings;
    }
    if (currentLayer == null || layerElement.isScoreDefElement) {
      return FunctorCode.siblings;
    }

    if (layerElement.hasSameasLink) return FunctorCode.continue_;

    if (layerElement.isClass(ClassId.mRest)) {
      elements.add(layerElement);
      return FunctorCode.continue_;
    }

    if (!layerElement.hasInterface(InterfaceId.duration) ||
        layerElement.isAny(const {ClassId.mSpace, ClassId.space})) {
      return FunctorCode.continue_;
    }

    final Object? chordAncestor =
        layerElement.getFirstAncestor(ClassId.chord);
    final Fraction elementDuration = chordAncestor == null
        ? layerElement.getAlignmentDuration(meterParams)
        : (chordAncestor as LayerElement).getAlignmentDuration(meterParams);
    final Fraction elementTime = layerElement.getAlignment()!.getTime();

    // The event is starting after the end of the element.
    if ((elementTime + elementDuration) <= time) {
      return FunctorCode.continue_;
    }
    // The element is starting after the event end - we can stop here.
    if (elementTime >= (time + duration)) {
      return FunctorCode.stop;
    }

    if (layerElement.isClass(ClassId.note)) {
      final Object? chord = (layerElement as Note).isChordTone();
      if (chord != null && elements.contains(chord)) {
        return FunctorCode.continue_;
      }
    }
    elements.add(layerElement);

    // Not need to recurse for chords.
    return layerElement.isClass(ClassId.chord)
        ? FunctorCode.siblings
        : FunctorCode.continue_;
  }
}

/// This class goes through all layer elements of the layer and returns the
/// next/previous element (depending on traversal direction) relative to the
/// specified layer element. It will search recursively through children
/// elements until note, chord or ftrem is found. It can be used to look into
/// neighboring layers as well, but only the first element will be checked
/// (mirrors `vrv::GetRelativeLayerElementFunctor`,
/// findlayerelementsfunctor.cpp:249).
class GetRelativeLayerElementFunctor extends Functor {
  GetRelativeLayerElementFunctor(this.initialElementIndex, this.isInNeighboringLayer);

  // Mirrors `ImplementsEndInterface() const override { return false; }`
  // (findlayerelementsfunctor.h) — see the identical note on
  // `LayerElementsInTimeSpanFunctor` above. Here the correctness impact is
  // direct: this functor's whole contract is "stop at the first match", so
  // without this override the end-visit that follows every node's own visit
  // would reset `code` back to `continue_` right after a match sets it to
  // `stop`, and the search would silently keep going and return the last
  // match instead of the first.
  @override
  bool get implementsEndInterface => false;

  /// The next/previous relevant layer element (mirrors `m_relativeElement`).
  LayerElement? relativeElement;

  /// The index of the layer element that is being compared to (starting
  /// point) (mirrors `m_initialElementIndex`).
  final int initialElementIndex;

  /// The flag to indicate whether search is done in the same layer as the
  /// given element, or in a neighboring one (mirrors
  /// `m_isInNeighboringLayer`).
  final bool isInNeighboringLayer;

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    // Do not check for index of the element if we're looking into
    // neighboring layer or if a nested element is being processed (e.g.
    // ignore index of children of beams, since they have their own indices
    // irrelevant to the one that has been passed inside this functor).
    if (!isInNeighboringLayer && (layerElement.parent?.isClass(ClassId.layer) ?? false)) {
      final int idx = layerElement.parent!.getChildIndex(layerElement);
      if (direction == forward && idx < initialElementIndex) {
        return FunctorCode.siblings;
      }
      if (direction == backward && idx > initialElementIndex) {
        return FunctorCode.siblings;
      }
    }

    if (layerElement.isAny(const {ClassId.note, ClassId.chord, ClassId.fTrem})) {
      relativeElement = layerElement;
      return FunctorCode.stop;
    }

    if (layerElement.isClass(ClassId.rest)) {
      return isInNeighboringLayer ? FunctorCode.stop : FunctorCode.siblings;
    }

    return FunctorCode.continue_;
  }
}
