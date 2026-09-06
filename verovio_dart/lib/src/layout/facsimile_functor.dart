/// Port of `facsimilefunctor.h/cpp` — `SyncFromFacsimileFunctor` only.
///
/// `SyncFromFacsimileFunctor` propagates the geometry encoded in a
/// `<facsimile>` (zones attached via `@facs`) into the `m_drawingFacsX/Y`
/// (and friends) fields that the layout/rendering code reads for
/// transcription documents. It runs unconditionally — unlike
/// `PrepareFacsimileFunctor`, which `Doc::PrepareData` only runs when
/// `IsFacs()` — from `Doc::SyncFromFacsimileDoc` (doc.cpp:1586-1592), called
/// by `Toolkit::LoadData` right after cast-off for any
/// `IsTranscription() && HasFacsimile()` document (toolkit.cpp:922-924).
///
/// `SyncToFacsimileFunctor` (the reverse direction, used when *writing* a
/// facsimile from a layout) is not ported: nothing in this port calls it yet
/// (there is no facsimile-generation entry point), so it is out of scope
/// here.
///
/// Reference:
/// - `origin/src/include/vrv/facsimilefunctor.h:26-83`
/// - `origin/src/src/facsimilefunctor.cpp:33-203`
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/utils.dart' show isValidDouble;
import 'package:verovio_dart/src/core/vrvdef.dart'
    show ClassId, FunctorCode, definitionFactor;
import 'package:verovio_dart/src/layout/apply_ppu_factor.dart'
    show ApplyPPUFactorFunctor;
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Measure, Staff;
import 'package:verovio_dart/src/model/doc.dart' show Page;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart'
    show Pb, Sb, Surface;
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show System;
import 'package:verovio_dart/src/model/zone.dart' show Zone;
import 'package:verovio_dart/src/rendering/view.dart' show View;

/// Layer element classes `SyncFromFacsimileFunctor::VisitLayerElement`
/// handles (facsimilefunctor.cpp:46) — every other class returns
/// FUNCTOR_CONTINUE unchanged.
const Set<ClassId> _kSyncFacsimileLayerElementClasses = {
  ClassId.accid,
  ClassId.barLine,
  ClassId.chord,
  ClassId.clef,
  ClassId.custos,
  ClassId.divLine,
  ClassId.dot,
  ClassId.liquescent,
  ClassId.nc,
  ClassId.note,
  ClassId.rest,
  ClassId.syl,
};

/// This class syncs the layout encoded in the facsimile to `m_drawingFacsX/Y`
/// (and friends) (mirrors `vrv::SyncFromFacsimileFunctor`,
/// facsimilefunctor.h:32-83 / facsimilefunctor.cpp:33-203).
class SyncFromFacsimileFunctor extends DocFunctor {
  /// Mirrors `SyncFromFacsimileFunctor::SyncFromFacsimileFunctor`
  /// (facsimilefunctor.cpp:33-42).
  SyncFromFacsimileFunctor(super.doc) : view = View()..setDoc(doc);

  /// Mirrors `m_view`.
  final View view;

  /// Mirrors `m_currentPage`.
  Page? currentPage;

  /// Mirrors `m_currentSystem`.
  System? currentSystem;

  /// Mirrors `m_currentNeumeLine`.
  Measure? currentNeumeLine;

  /// Map to store the zone corresponding to a staff (mirrors
  /// `m_staffZones`).
  final Map<Staff, Zone> staffZones = {};

  /// Mirrors `m_pageMarginTop`.
  int pageMarginTop = 0;

  /// Mirrors `m_pageMarginLeft`.
  int pageMarginLeft = 0;

  /// Mirrors `m_ppuFactor`.
  double ppuFactor = 1.0;

  /// Mirrors `SyncFromFacsimileFunctor::VisitLayerElement`
  /// (facsimilefunctor.cpp:44-57).
  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    if (!_kSyncFacsimileLayerElementClasses.contains(layerElement.classId)) {
      return FunctorCode.continue_;
    }

    final Zone? zone = layerElement.zone;
    assert(zone != null);
    if (zone == null) return FunctorCode.continue_;
    layerElement.drawingFacsX = view.toLogicalX(
        (zone.ulx ?? meiUnset) * definitionFactor - pageMarginLeft);
    if (currentNeumeLine != null &&
        (layerElement.classId == ClassId.accid ||
            layerElement.classId == ClassId.syl)) {
      layerElement.drawingFacsY = view.toLogicalY(
          (zone.uly ?? meiUnset) * definitionFactor - pageMarginTop);
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `SyncFromFacsimileFunctor::VisitMeasure`
  /// (facsimilefunctor.cpp:59-73).
  @override
  FunctorCode visitMeasure(Measure measure) {
    // neon specific code - measures have no zone, we use the staff one in
    // visitStaff.
    if (measure.isNeumeLine()) {
      currentNeumeLine = measure;
    } else {
      final Zone? zone = measure.zone;
      assert(zone != null);
      if (zone != null) {
        measure.drawingFacsX1 = view.toLogicalX(
            (zone.ulx ?? meiUnset) * definitionFactor - pageMarginLeft);
        measure.drawingFacsX2 = view.toLogicalX(
            (zone.lrx ?? meiUnset) * definitionFactor - pageMarginLeft);
      }
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `SyncFromFacsimileFunctor::VisitPage`
  /// (facsimilefunctor.cpp:75-82).
  @override
  FunctorCode visitPage(Page page) {
    staffZones.clear();
    currentPage = page;
    doc.setDrawingPage(currentPage!.getPageIdx());

    return FunctorCode.continue_;
  }

  /// Mirrors `SyncFromFacsimileFunctor::VisitPageEnd`
  /// (facsimilefunctor.cpp:84-110).
  @override
  FunctorCode visitPageEnd(Page page) {
    // Used for adjusting staff size in neon - filled in visitStaff.
    if (staffZones.isNotEmpty) {
      // Since we multiply all values by DEFINITION_FACTOR, set it as PPU for
      // neon facs.
      ppuFactor = definitionFactor.toDouble();
    }

    // The staff size is calculated based on the zone height and takes into
    // account the rotation.
    for (final MapEntry<Staff, Zone> entry in staffZones.entries) {
      final Staff staff = entry.key;
      final Zone zone = entry.value;
      final double rotate = zone.hasRotate ? zone.rotate! : 0.0;
      final int yDiff = ((zone.lry ?? meiUnset) -
              (zone.uly ?? meiUnset) -
              ((zone.lrx ?? meiUnset) - (zone.ulx ?? meiUnset)) *
                  math.tan(rotate.abs() * math.pi / 180.0))
          .toInt();
      staff.drawingStaffSize = (100 *
              yDiff /
              (doc.getOptions().unit.value * 2 * (staff.drawingLines - 1)))
          .toInt();
      staff.setDrawingRotation(rotate);
    }

    currentPage!.setPPUFactor(ppuFactor);
    if (currentPage!.getPPUFactor() != 1.0) {
      final ApplyPPUFactorFunctor applyPPUFactor = ApplyPPUFactorFunctor();
      currentPage!.process(applyPPUFactor);
      doc.updatePageDrawingSizes();
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `SyncFromFacsimileFunctor::VisitPb`
  /// (facsimilefunctor.cpp:112-159).
  @override
  FunctorCode visitPb(Pb pb) {
    // This would happen if we run the functor on data not converted to
    // page-based.
    assert(currentPage != null);

    final Zone? zone = pb.zone;
    Surface? surface = pb.surface;
    if (surface == null && zone != null && zone.parent != null) {
      surface = zone.parent is Surface ? zone.parent as Surface : null;
    }
    assert(zone != null || surface != null);
    // Use the (parent) surface attributes if given.
    if (surface != null && surface.hasLrx && surface.hasLry) {
      currentPage!.pageHeight = (surface.lry ?? meiUnset) * definitionFactor;
      currentPage!.pageWidth = (surface.lrx ?? meiUnset) * definitionFactor;
      // Read the ppu factor from surface@type.
      final String surfaceType = surface.type ?? '';
      if (surfaceType.startsWith('ppu:')) {
        final String ppuFactorStr =
            surfaceType.substring(surfaceType.indexOf(':') + 1);
        if (isValidDouble(ppuFactorStr)) {
          final double? parsed = double.tryParse(ppuFactorStr.trim());
          if (parsed != null) {
            ppuFactor = parsed;
            ppuFactor *= definitionFactor / doc.getOptions().unit.value;
          }
        }
      }
      // Read margins.
      if (zone != null &&
          zone.hasUlx &&
          zone.hasUly &&
          zone.hasLrx &&
          zone.hasLry) {
        pageMarginTop = zone.uly! * definitionFactor;
        pageMarginLeft = zone.ulx! * definitionFactor;
        currentPage!.pageMarginTop = pageMarginTop;
        // Calculate the bottom margin looking at the surface lry and zone
        // lry.
        currentPage!.pageMarginBottom =
            currentPage!.pageHeight - zone.lry! * definitionFactor;
        currentPage!.pageMarginLeft = pageMarginLeft;
        // Calculate the right margin looking at the surface lrx and zone
        // lrx.
        currentPage!.pageMarginRight =
            currentPage!.pageWidth - zone.lrx! * definitionFactor;
        doc.updatePageDrawingSizes();
      }
    }
    // Fallback on zone.
    else {
      currentPage!.pageHeight = (zone!.lry ?? meiUnset) * definitionFactor;
      currentPage!.pageWidth = (zone.lrx ?? meiUnset) * definitionFactor;
    }

    // Update the page size to have View::ToLogicalX/Y valid.
    doc.updatePageDrawingSizes();

    return FunctorCode.continue_;
  }

  /// Mirrors `SyncFromFacsimileFunctor::VisitSb`
  /// (facsimilefunctor.cpp:161-172).
  @override
  FunctorCode visitSb(Sb sb) {
    // This would happen if we run the functor on data not converted to
    // page-based.
    assert(currentSystem != null);

    final Zone? zone = sb.zone;
    assert(zone != null);
    if (zone == null) return FunctorCode.continue_;
    currentSystem!.drawingFacsX = view.toLogicalX(
        (zone.ulx ?? meiUnset) * definitionFactor - pageMarginLeft);
    currentSystem!.drawingFacsY = view.toLogicalY(
        (zone.uly ?? meiUnset) * definitionFactor - pageMarginTop);

    return FunctorCode.continue_;
  }

  /// Mirrors `SyncFromFacsimileFunctor::VisitStaff`
  /// (facsimilefunctor.cpp:174-195).
  @override
  FunctorCode visitStaff(Staff staff) {
    final Zone? zone = staff.zone;
    assert(zone != null);
    if (zone == null) return FunctorCode.continue_;
    staff.drawingFacsY = view.toLogicalY(
        (zone.uly ?? meiUnset) * definitionFactor - pageMarginTop);

    // neon specific code - set the position of the pseudo measure (neume
    // line).
    if (currentNeumeLine != null) {
      currentNeumeLine!.drawingFacsX1 = view.toLogicalX(
          (zone.ulx ?? meiUnset) * definitionFactor - pageMarginLeft);
      currentNeumeLine!.drawingFacsX2 = view.toLogicalX(
          (zone.lrx ?? meiUnset) * definitionFactor - pageMarginLeft);
      staffZones[staff] = zone;

      // The staff slope is going up. The y left position needs to be
      // adjusted accordingly.
      if (zone.hasRotate && zone.rotate! < 0) {
        staff.drawingFacsY = (staff.drawingFacsY +
                (currentNeumeLine!.drawingFacsX2 -
                        currentNeumeLine!.drawingFacsX1) *
                    math.tan(zone.rotate! * math.pi / 180.0))
            .toInt();
      }
    }

    return FunctorCode.continue_;
  }

  /// Mirrors `SyncFromFacsimileFunctor::VisitSystem`
  /// (facsimilefunctor.cpp:197-203).
  @override
  FunctorCode visitSystem(System system) {
    currentSystem = system;
    currentNeumeLine = null;

    return FunctorCode.continue_;
  }
}
