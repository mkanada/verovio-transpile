/// Port of `adjustossiastaffdeffunctor.h/cpp` and `adjustneumexfunctor.h/cpp`:
///
/// - [AdjustOssiaStaffDefFunctor]: shifts the clef / key signature alignment
///   of an ossia staffDef so that they sit to the left of the measure
///   content, mirroring `AdjustOssiaStaffDefFunctor`.
/// - [AdjustNeumeXFunctor]: adjusts the X position of neumes and syllables so
///   that the text underlay does not overlap the neume above it, mirroring
///   `AdjustNeumeXFunctor`.
///
/// Both functors run in `Page::LayOutHorizontally` in the C++ (right after
/// the bounding-box render pass, since both read rendered content bounding
/// boxes: `GetContentX1/X2` for the clef/keySig widths, `GetContentLeft/Right`
/// for the neume/syl extents). In this port they run in `Doc.layOutVertically`
/// instead, right after `View+BBoxDeviceContext.processPage` fills those same
/// boxes — see the deviation note there.
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Layer, Measure, Ossia, Staff;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart' show Neume, Syl;
import 'package:verovio_dart/src/model/object.dart';

// ---------------------------------------------------------------------------
// AdjustOssiaStaffDefFunctor
// ---------------------------------------------------------------------------

/// Adjusts the position of the clef and key signature for ossia staffDefs
/// (mirrors `vrv::AdjustOssiaStaffDefFunctor`).
class AdjustOssiaStaffDefFunctor extends DocFunctor {
  AdjustOssiaStaffDefFunctor(super.doc);

  /// The key signature maximal width (mirrors `m_keySigWidth`).
  int keySigWidth = 0;

  /// The clef maximal width (mirrors `m_clefWidth`).
  int clefWidth = 0;

  /// The current staff size (mirrors `m_staffSize`).
  int staffSize = 100;

  /// The keySig / clef alignment (mirrors `m_keySigAlignment` /
  /// `m_clefAlignment`).
  Alignment? keySigAlignment;
  Alignment? clefAlignment;

  /// The list of ossias found in the current measure (mirrors `m_ossias`,
  /// a `std::list<Ossia *>`).
  final List<Ossia> ossias = [];

  @override
  FunctorCode visitAlignment(Alignment alignment) {
    if (alignment.getType().value >= AlignmentType.measureStart.value) {
      return FunctorCode.siblings;
    }

    if (alignment.getType() == AlignmentType.scoreDefOssiaKeySig) {
      keySigAlignment = alignment;
    } else if (alignment.getType() == AlignmentType.scoreDefOssiaClef) {
      clefAlignment = alignment;
    }

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;

    final int unit = doc.getDrawingUnit(staffSize);

    if (layerElement.classId == ClassId.keysig) {
      final int width =
          layerElement.getContentX1() + layerElement.getContentX2() + unit;
      keySigWidth = width > keySigWidth ? width : keySigWidth;
    } else if (layerElement.classId == ClassId.clef) {
      final int width =
          layerElement.getContentX1() + layerElement.getContentX2() + unit;
      clefWidth = width > clefWidth ? width : clefWidth;
    }
    final Ossia ossia = layerElement.getFirstAncestor(ClassId.ossia) as Ossia;
    ossias.add(ossia);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    keySigWidth = 0;
    clefWidth = 0;
    staffSize = 100;

    keySigAlignment = null;
    clefAlignment = null;

    ossias.clear();

    // Process on measure aligner backwards.
    setDirection(backward);
    measure.measureAligner.process(this);
    setDirection(forward);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasureEnd(Measure measure) {
    if (keySigAlignment != null) {
      keySigAlignment!.setXRel(-keySigWidth);
    }
    if (clefAlignment != null) {
      clefAlignment!.setXRel(-keySigWidth - clefWidth);
    }

    _uniqueConsecutive(ossias);

    for (final Ossia ossia in ossias) {
      ossia.setClefAlignment(clefAlignment);
      ossia.setKeySigAlignment(keySigAlignment);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitStaff(Staff staff) => FunctorCode.siblings;
}

/// Removes consecutive duplicate elements in place (mirrors
/// `std::list::unique`, which — unlike a full dedup — only collapses
/// elements equal to their immediate predecessor).
void _uniqueConsecutive<T>(List<T> list) {
  for (int i = list.length - 1; i > 0; i--) {
    if (identical(list[i], list[i - 1])) list.removeAt(i);
  }
}

// ---------------------------------------------------------------------------
// AdjustNeumeXFunctor
// ---------------------------------------------------------------------------

/// Adjusts the X position of neumes and syllables so that the neume and the
/// text underlay of a syllable do not overlap (mirrors
/// `vrv::AdjustNeumeXFunctor`).
class AdjustNeumeXFunctor extends DocFunctor {
  AdjustNeumeXFunctor(super.doc);

  /// The minimum position of the next syl (mirrors `m_minPos`).
  int minPos = meiUnset;

  /// The minimum position of the next neume (mirrors `m_neumeMinPos`).
  ///
  /// Deviation: the C++ leaves `m_neumeMinPos` uninitialized until the first
  /// `VisitSyl` of a layer runs (there is no member initializer); this port
  /// starts it at `meiUnset` instead, which is what every `VisitSyl` sets it
  /// to anyway before any `VisitNeume` of that syllable can read it.
  int neumeMinPos = meiUnset;

  @override
  FunctorCode visitLayer(Layer layer) {
    minPos = meiUnset;
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitLayerEnd(Layer layer) {
    final Measure measure = layer.getFirstAncestor(ClassId.measure) as Measure;
    final Alignment alignment = measure.measureAligner.getRightAlignment()!;

    final int selfLeft = alignment.getXRel();
    if (selfLeft < minPos) {
      final int adjust = minPos - selfLeft;
      alignment.setXRel(alignment.getXRel() + adjust);
    }

    minPos = meiUnset;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitNeume(Neume neume) {
    // It is unset when we process the first neume of the syllable.
    if (neumeMinPos != meiUnset) {
      final Alignment alignment = neume.getAlignment()!;

      final int selfLeft = neume.getContentLeft();
      if (selfLeft < neumeMinPos) {
        final int adjust = neumeMinPos - selfLeft;
        alignment.setXRel(alignment.getXRel() + adjust);
      }
    }

    neumeMinPos = neume.getContentRight() + doc.getDrawingUnit(100);

    // Check if the neume takes more space than the syllable text.
    if (neumeMinPos > minPos) minPos = neumeMinPos;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    if (!staff.isNeume()) return FunctorCode.siblings;

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSyl(Syl syl) {
    final Alignment alignment = syl.getAlignment()!;

    // Indicates that the neume will be the first of the syllable.
    neumeMinPos = meiUnset;

    final int selfLeft = syl.getContentLeft();
    if (selfLeft < minPos) {
      final int adjust = minPos - selfLeft;
      alignment.setXRel(alignment.getXRel() + adjust);
    }

    minPos = syl.getContentRight() + doc.getDrawingUnit(100);

    return FunctorCode.continue_;
  }
}
