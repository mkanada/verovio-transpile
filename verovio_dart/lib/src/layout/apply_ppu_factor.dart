/// Port of `miscfunctor.h/cpp` — `ApplyPPUFactorFunctor` (~40 lines).
///
/// Applies the pixel-per-unit factor of the page to its elements. Called from
/// `MEIInput::ReadPage` (`iomei.cpp:4461`) when the document is a
/// transcription and `GetPPUFactor() != 1.0`.
///
/// Reference:
/// - `origin/src/include/vrv/miscfunctor.h:22`
/// - `origin/src/src/miscfunctor.cpp:27-111`
/// - `origin/src/src/iomei.cpp:4461-4464`
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/vrvdef.dart' show FunctorCode;
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Measure, Staff;
import 'package:verovio_dart/src/model/doc.dart' show Page;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show Surface;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/model/zone.dart' show Zone;

/// This class applies the Pixel Per Unit factor of the page to its elements
/// (mirrors `vrv::ApplyPPUFactorFunctor`).
class ApplyPPUFactorFunctor extends Functor {
  ApplyPPUFactorFunctor([this.page]);

  /// The current page (mirrors `m_page`).
  Page? page;

  @override
  bool get implementsEndInterface => false;

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    assert(page != null);
    if (layerElement.isScoreDefElement) return FunctorCode.siblings;
    final double ppu = page!.getPPUFactor();
    if (layerElement.drawingFacsX != meiUnset) {
      layerElement.drawingFacsX = (layerElement.drawingFacsX / ppu).toInt();
    }
    if (layerElement.drawingFacsY != meiUnset) {
      layerElement.drawingFacsY = (layerElement.drawingFacsY / ppu).toInt();
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    assert(page != null);
    final double ppu = page!.getPPUFactor();
    if (measure.drawingFacsX1 != meiUnset) {
      measure.drawingFacsX1 = (measure.drawingFacsX1 / ppu).toInt();
    }
    if (measure.drawingFacsX2 != meiUnset) {
      measure.drawingFacsX2 = (measure.drawingFacsX2 / ppu).toInt();
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitPage(Page page) {
    this.page = page;
    final double ppu = page.getPPUFactor();
    // Mirrors miscfunctor.cpp:58-63 — int fields divided by double PPU
    // (C++ truncates toward zero; Dart `toInt()` does the same).
    page.pageWidth = (page.pageWidth / ppu).toInt();
    page.pageHeight = (page.pageHeight / ppu).toInt();
    page.pageMarginBottom = (page.pageMarginBottom / ppu).toInt();
    page.pageMarginLeft = (page.pageMarginLeft / ppu).toInt();
    page.pageMarginRight = (page.pageMarginRight / ppu).toInt();
    page.pageMarginTop = (page.pageMarginTop / ppu).toInt();
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    assert(page != null);
    final double ppu = page!.getPPUFactor();
    if (staff.drawingFacsY != meiUnset) {
      staff.drawingFacsY = (staff.drawingFacsY / ppu).toInt();
    }
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSurface(Surface surface) {
    assert(page != null);
    final double ppu = page!.getPPUFactor();
    // Mirrors miscfunctor.cpp:81-84 — coordinated fields are multiplied.
    if (surface.hasUlx) surface.ulx = (surface.ulx! * ppu).toInt();
    if (surface.hasUly) surface.uly = (surface.uly! * ppu).toInt();
    if (surface.hasLrx) surface.lrx = (surface.lrx! * ppu).toInt();
    if (surface.hasLry) surface.lry = (surface.lry! * ppu).toInt();
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystem(System system) {
    assert(page != null);
    final double ppu = page!.getPPUFactor();
    if (system.drawingFacsX != meiUnset) {
      system.drawingFacsX = (system.drawingFacsX / ppu).toInt();
    }
    if (system.drawingFacsY != meiUnset) {
      system.drawingFacsY = (system.drawingFacsY / ppu).toInt();
    }
    system.systemLeftMar = (system.systemLeftMar * ppu).toInt();
    system.systemRightMar = (system.systemRightMar * ppu).toInt();
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitZone(Zone zone) {
    assert(page != null);
    final double ppu = page!.getPPUFactor();
    if (zone.hasUlx) zone.ulx = (zone.ulx! * ppu).toInt();
    if (zone.hasUly) zone.uly = (zone.uly! * ppu).toInt();
    if (zone.hasLrx) zone.lrx = (zone.lrx! * ppu).toInt();
    if (zone.hasLry) zone.lry = (zone.lry! * ppu).toInt();
    return FunctorCode.continue_;
  }
}
