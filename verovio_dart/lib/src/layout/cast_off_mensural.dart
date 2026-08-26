/// Port of the mensural cast-off functors from `convertfunctor.h/cpp`:
///
/// - [ConvertToCastOffMensuralFunctor]: converts mensural MEI into cast-off
///   (measure) segments looking at the barLine objects. Segment positions
///   occur where a barLine is set on all staves.
/// - [convertToUnCastOffMensuralSystem]: mirrors
///   `System::ConvertToUnCastOffMensuralSystem`, driven by the port of
///   `ConvertToUnCastOffMensuralFunctor`.
///
/// The orchestration is provided by `Doc.convertToCastOffMensuralDoc`
/// (doc.dart) mirroring `Doc::ConvertToCastOffMensuralDoc`.
///
/// Deviations from the C++:
/// - The C++ functor objects keep `std::list` iterators into the segment /
///   break point lists; here plain indices are used.
/// - Control events attached to the content measure (dir, slur…) are moved
///   with the first segment only when they are layer children — exactly as
///   in the C++, measure-level control events are not re-attached to the
///   segments (they would be dropped with the content system; mensural
///   unmeasured encodings rarely have them).
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show Alignment;
import 'package:verovio_dart/src/layout/preparedata_functor.dart'
    show InitProcessingListsFunctor;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Layer, Measure, Section, Staff;
import 'package:verovio_dart/src/model/comparison.dart';
import 'package:verovio_dart/src/model/layer_element.dart'
    show LayerElement;
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Ligature;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef;
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show System, SystemElement;

/// Mirrors the `MensuralCastOffType` doc comment — the enum itself lives in
/// vrvdef.dart (`MensuralCastOffType`).

// ---------------------------------------------------------------------------
// ConvertToCastOffMensuralFunctor
// ---------------------------------------------------------------------------

/// This class converts mensural MEI into cast-off (measure) segments looking
/// at the barLine objects (mirrors `vrv::ConvertToCastOffMensuralFunctor`).
class ConvertToCastOffMensuralFunctor extends DocFunctor {
  /// Creates the functor; [targetSystem] is the system the segments are
  /// added to.
  ConvertToCastOffMensuralFunctor(super.doc, this._targetSystem);

  /// The list of segments (i.e., measures) we are going to create (mirrors
  /// `m_segments`).
  final List<Measure> _segments = [];

  /// The current segment index, reset for every staff/layer (mirrors
  /// `m_currentSegment`).
  int _currentSegment = 0;

  /// The list of break points (one less than the segments; mirrors
  /// `m_breakPoints`).
  final List<Alignment> _breakPoints = [];

  /// The current breakpoint index, reset for every staff/layer (mirrors
  /// `m_currentBreakPoint`).
  int _currentBreakPoint = 0;

  /// The content staff from which we are copying the elements (mirrors
  /// `m_contentStaff`).
  Staff? _contentStaff;

  /// The content layer from which we are copying the elements (mirrors
  /// `m_contentLayer`).
  Layer? _contentLayer;

  // The target system, staff & layer (mirrors `m_targetSystem`,
  // `m_targetStaff` / `m_targetLayer`; the target measure is looked up in
  // `_segments`).
  final System _targetSystem;
  Staff? _targetStaff;
  Layer? _targetLayer;

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitLayer(Layer layer) {
    _contentLayer = layer;
    _targetLayer = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    _segments.clear();
    _breakPoints.clear();

    final int nbLayers = measure.getDescendantCount(ClassId.layer);
    bool isFirst = true;

    // Create at least one segment to copy stuff to
    final Measure segment = Measure(MeasureType.unmeasured);
    _targetSystem.addChild(segment);
    _segments.add(segment);

    for (final Object child in measure.measureAligner.children) {
      final Alignment alignment = child as Alignment;
      // We use the alignments with an element at all layer as a breakpoint
      if (!isValidBreakPoint(alignment, nbLayers)) continue;
      // Do not break at the first one
      if (isFirst) {
        isFirst = false;
        continue;
      }
      final Measure newSegment = Measure(MeasureType.unmeasured);
      _targetSystem.addChild(newSegment);
      _segments.add(newSegment);
      _breakPoints.add(alignment);
    }

    // Now we are ready to process staves/layers and to move content to the
    // segments
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitObject(Object object) {
    assert(object.parent != null);
    // We want to move only the children of the layer of any type (notes,
    // editorial elements, etc)
    if (object.parent!.isClass(ClassId.layer)) {
      initSegment(object);
      assert(_targetLayer != null);
      object.moveItselfTo(_targetLayer!);
      // Do not process children because we move the full sub-tree
      return FunctorCode.siblings;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    scoreDef.moveItselfTo(_targetSystem);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    _currentSegment = 0;
    _currentBreakPoint = 0;

    _contentStaff = staff;
    _targetStaff = null;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemElement(SystemElement systemElement) {
    systemElement.moveItselfTo(_targetSystem);

    return FunctorCode.continue_;
  }

  /// Check if the alignment is a valid breakpoint (mirrors
  /// `IsValidBreakPoint`).
  bool isValidBreakPoint(Alignment alignment, int nbLayers) {
    if (alignment.getType() != AlignmentType.default_) return false;

    // Not all layers have an alignment and we cannot break here
    if (alignment.childCount != nbLayers) return false;

    final bool ligatureAsBracket =
        doc.getOptions().ligatureAsBracket.value;

    for (final Object child in alignment.children) {
      for (final Object refChild in child.children) {
        // Do not break within editorial markup
        if (refChild.getFirstAncestorInRange(
                ClassId.editorialElement, ClassId.editorialElementMax) !=
            null) {
          return false;
        }
        // Do not break within a ligature when rendered as bracket - (notes
        // in it will have a different aligner except for the first one)
        if (ligatureAsBracket &&
            refChild.getFirstAncestor(ClassId.ligature) != null) {
          final Ligature ligature =
              refChild.getFirstAncestor(ClassId.ligature) as Ligature;
          if (!identical(ligature.getAlignment(), alignment)) {
            return false;
          }
        }
      }
      // When we have more than one neume in a syllable, every neume has its
      // own alignment. Only the first one, which is shared with the
      // syllable, is a valid break point
      if (child.findDescendantByType(ClassId.nc) != null &&
          child.findDescendantByType(ClassId.syllable) == null) {
        return false;
      }
    }

    return true;
  }

  /// Create the staff and layer when a new segment starts (mirrors
  /// `InitSegment`).
  void initSegment(Object object) {
    assert(_contentStaff != null);
    assert(_contentLayer != null);

    LayerElement? element;
    if (object.isLayerElement) element = object as LayerElement;

    if (element != null &&
        element.getAlignment() != null &&
        // Mirrors `element->GetAlignment() == *m_currentBreakPoint`: once
        // every break point was consumed the C++ compares against the end
        // sentinel which never matches; guard the index accordingly.
        _currentBreakPoint < _breakPoints.length &&
        identical(element.getAlignment(), _breakPoints[_currentBreakPoint])) {
      _targetStaff = null;
      _targetLayer = null;
      ++_currentBreakPoint;
      ++_currentSegment;
    }

    if (_targetStaff != null && _targetLayer != null) return;

    final Staff targetStaff = Staff();
    _copyStaffAttributes(_contentStaff!, targetStaff);
    // Keep the xml:id of the staff in the first staff segment
    targetStaff.swapID(_contentStaff!);
    _segments[_currentSegment].addChild(targetStaff);
    _targetStaff = targetStaff;

    final Layer targetLayer = Layer();
    _copyLayerAttributes(_contentLayer!, targetLayer);
    // Keep the xml:id of the layer in the first segment
    targetLayer.swapID(_contentLayer!);
    _targetStaff!.addChild(targetLayer);
    _targetLayer = targetLayer;
  }

  /// Copy the attribute values of a staff (mirrors the AttModule copies of
  /// `Object::CopyAttributesTo` for the Staff attribute classes).
  static void _copyStaffAttributes(Staff source, Staff target) {
    target.coordY1 = source.coordY1;
    target.n = source.n;
    target.type = source.type;
    target.visible = source.visible;
    target.facs = source.facs;
  }

  /// Copy the attribute values of a layer (mirrors `Object::CopyAttributesTo`
  /// for the Layer attribute classes).
  static void _copyLayerAttributes(Layer source, Layer target) {
    target.cue = source.cue;
    target.n = source.n;
    target.type = source.type;
    target.visible = source.visible;
  }
}

// ---------------------------------------------------------------------------
// ConvertToUnCastOffMensuralFunctor
// ---------------------------------------------------------------------------

/// This class converts cast-off (measure) mensural segments MEI into
/// mensural (mirrors `vrv::ConvertToUnCastOffMensuralFunctor`).
class ConvertToUnCastOffMensuralFunctor extends Functor {
  ConvertToUnCastOffMensuralFunctor() {
    resetContent();
    // We process layer by layer, keep a list of segments to be deleted the
    // first time we go through
    trackSegmentsToDelete = true;
  }

  /// The content/target measure and layer => null at the beginning of a
  /// section (mirrors `m_contentMeasure` / `m_contentLayer`).
  Measure? _contentMeasure;
  Layer? _contentLayer;

  /// Indicates if we keep a reference of the measure segments to delete at
  /// the end (mirrors `m_trackSegmentsToDelete`).
  bool trackSegmentsToDelete = true;

  /// Measure segments to delete at the end (fill in the first pass only;
  /// mirrors `m_segmentsToDelete`).
  final List<Object> segmentsToDelete = [];

  @override
  bool get implementsEndInterface => false;

  /// Mirrors `ResetContent`.
  void resetContent() {
    _contentMeasure = null;
    _contentLayer = null;
  }

  @override
  FunctorCode visitLayer(Layer layer) {
    if (_contentLayer == null) {
      _contentLayer = layer;
    } else {
      _contentLayer!.moveChildrenFrom(layer);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    // First measure of the section, move all content to it and keep it
    if (_contentMeasure == null) {
      _contentMeasure = measure;
    }
    // First pass, mark the measure to be deleted once finished
    else if (trackSegmentsToDelete) {
      segmentsToDelete.add(measure);
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSection(Section section) {
    resetContent();

    return FunctorCode.continue_;
  }
}

// ---------------------------------------------------------------------------
// System::ConvertToUnCastOffMensuralSystem
// ---------------------------------------------------------------------------

/// Mirrors `System::ConvertToUnCastOffMensuralSystem`: merge the cast-off
/// (measure) segments of [system] back into single measures per section.
void convertToUnCastOffMensuralSystem(System system) {
  // We need to populate processing lists for processing the document by
  // layer.
  final InitProcessingListsFunctor initProcessingLists =
      InitProcessingListsFunctor();
  system.process(initProcessingLists);
  final Map<int, Set<int>> layerTree = initProcessingLists.layerTree;

  // Checking just in case
  if (layerTree.isEmpty) return;

  final ConvertToUnCastOffMensuralFunctor convertToUnCastOffMensural =
      ConvertToUnCastOffMensuralFunctor();

  // Now we can process by layer and move their content to (measure)
  // segments
  for (final int staffN in layerTree.keys) {
    for (final int layerN in layerTree[staffN]!) {
      // Create an comparison object for each type / @n
      final Filters filters = Filters();
      filters.add(AttNIntegerComparison(ClassId.staff, staffN));
      filters.add(AttNIntegerComparison(ClassId.layer, layerN));

      convertToUnCastOffMensural.setFilters(filters);
      convertToUnCastOffMensural.resetContent();
      system.process(convertToUnCastOffMensural);
      // Mirrors TrackSegmentsToDelete(false): keep the list filled by the
      // first pass.
      convertToUnCastOffMensural.trackSegmentsToDelete = false;
    }
  }
  convertToUnCastOffMensural.setFilters(null);

  // Detach the segments
  for (final Object measure in convertToUnCastOffMensural.segmentsToDelete) {
    system.deleteChild(measure);
  }

  logDebug('convertToUnCastOffMensuralSystem: '
      '${convertToUnCastOffMensural.segmentsToDelete.length} segments removed');
}
