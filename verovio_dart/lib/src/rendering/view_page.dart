/// Port of `view_page.cpp` (A) — the page/system drawing spine of the
/// `View`: `DrawCurrentPage`, `DrawSystem`, `DrawPageElement`,
/// `SetScoreDefDrawingWidth`, `GetPPUFactor`, `DrawSystemDivider`,
/// `DrawLayer`/`DrawLayerList`, the 7 `Draw*Children` dispatchers and the 7
/// `Draw*EditorialElement` dispatchers, plus `DrawAnnot`
/// (view_page.cpp:65-255 and 1575-2076).
///
/// The scoreDef / staffGrp side of `view_page.cpp` arrives with task 05-09,
/// the measure / barline side with 05-10 and the staff side with 05-11; the
/// methods they own are `_notYet` stubs at the bottom of this file.
///
/// This file is a `part` of the `view.dart` library (the task 05-06
/// partitioning decision: one `part` per `view_*.cpp`). The C++ continues
/// the `View` class here; Dart cannot split a class body across files, so
/// the methods are declared as members of the [ViewPage] extension below —
/// same library, therefore the same privacy scope as the class members
/// (like the C++ member visibility from every `view_*.cpp`).
///
/// Deviations from the C++:
/// - the `DeviceContext *dc` pointers become non-nullable [DeviceContext]
///   references (the `assert(dc)` of the C++ is subsumed).
/// - `m_drawingScoreDef = m_currentPage->m_drawingScoreDef` (a copy
///   assignment, view_page.cpp:80) becomes
///   `drawingScoreDef.copyFrom(currentPage!.drawingScoreDef)`: the Dart
///   field owns its instance and copies the page state in.
/// - the `assert(element)` / `assert(dc)` calls are subsumed by the
///   non-nullable parameter types; the `assert(false)` "impossible else"
///   branches of the dispatchers are kept as Dart `assert(false)` (no-ops in
///   release mode, like C++ `NDEBUG` builds).
/// - `UTF32to8(annot->GetText())` (view_page.cpp:2068) becomes
///   `annot.getText()` directly: Dart strings are already UTF-16 text, and
///   `DeviceContext.addDescription` takes a `String`.
part of 'view.dart';

/// The `view_page.cpp` methods of [View] ported by task 05-08.
extension ViewPage on View {
  /// Render the current page (mirrors `View::DrawCurrentPage`,
  /// view_page.cpp:65).
  ///
  /// [background] is kept for the C++ signature (view.h:157, default true);
  /// the only place the C++ uses it is the commented-out
  /// `DrawRectangle` of view_page.cpp:89.
  void drawCurrentPage(DeviceContext dc, [bool background = true]) {
    // Ensure that resources are set
    final bool dcHasResources = dc.hasResources;
    if (!dcHasResources) dc.setResources(doc!.resources);

    // Keep the width of the initial scoreDef
    setScoreDefDrawingWidth(dc, currentPage!.drawingScoreDef);

    // Set the current score def to the page one
    // The page one has previously been set by the ScoreDefSetCurrentFunctor
    // (mirrors `m_drawingScoreDef = m_currentPage->m_drawingScoreDef`, a
    // copy assignment - see the deviations block of this file).
    drawingScoreDef.copyFrom(currentPage!.drawingScoreDef);

    if ((doc!.getAdjustedDrawingPageHeight() > dc.height) &&
        options!.shrinkToFit.value) {
      dc.contentHeight = doc!.getAdjustedDrawingPageHeight();
    } else {
      dc.contentHeight = dc.height;
    }

    // if (background) dc.DrawRectangle(0, 0, m_doc->m_drawingPageWidth,
    //    m_doc->m_drawingPageHeight); (commented out in the C++)
    dc.drawBackgroundImage();

    final Point origin = dc.getLogicalOrigin();
    dc.setLogicalOrigin(origin.x - doc!.drawingPageMarginLeft,
        origin.y - doc!.drawingPageMarginTop);

    dc.startPage();

    for (final Object child in currentPage!.children) {
      if (child.isPageElement) {
        // cast to PageElement check in DrawSystemEditorial element
        drawPageElement(dc, child as PageElement);
      } else if (child.isClass(ClassId.system)) {
        final System system = child as System;
        drawSystem(dc, system);
      } else {
        assert(false);
      }
    }

    drawRunningElements(dc, currentPage!);

    dc.endPage();

    if (!dcHasResources) dc.resetResources();
  }

  /// Mirrors `View::GetPPUFactor` (view_page.cpp:118 / view.h:162).
  double getPPUFactor() {
    if (currentPage == null) return 1.0;

    return currentPage!.getPPUFactor();
  }

  /// Compute the drawing width of the initial scoreDef (mirrors
  /// `View::SetScoreDefDrawingWidth`, view_page.cpp:125).
  ///
  /// The C++ accumulates `int += double` expressions (glyph width plus
  /// margins times the unit); the whole sum is truncated once, exactly as
  /// the C++ implicit `int` conversion does.
  void setScoreDefDrawingWidth(DeviceContext dc, ScoreDef scoreDef) {
    int numAlteration = 0;

    // key signature of the scoreDef
    if (scoreDef.hasKeySigInfo()) {
      final KeySig keySig = scoreDef.getKeySig();
      numAlteration = (keySig.getAccidCount() > numAlteration)
          ? keySig.getAccidCount()
          : numAlteration;
    }

    // longest key signature of the staffDefs
    final List<Object> childList =
        scoreDef.getList(); // make sure it's initialized
    for (final Object child in childList) {
      final StaffDef staffDef = child as StaffDef;
      if (!staffDef.hasKeySigInfo()) continue;
      final KeySig keySig = staffDef.getKeySig();
      numAlteration = (keySig.getAccidCount() > numAlteration)
          ? keySig.getAccidCount()
          : numAlteration;
    }

    final int unit = doc!.getDrawingUnit(100);
    int width = 0;
    // G-clef as default width
    width += (doc!.getGlyphWidth(smuflE050Gclef, 100, false) +
            (doc!.getLeftMargin(ClassId.clef) +
                    doc!.getRightMargin(ClassId.clef)) *
                unit)
        .truncate();
    if (numAlteration > 0) {
      width += (doc!.getGlyphWidth(smuflE262AccidentalSharp, 100, false) *
                  tempKeysigStep +
              (doc!.getLeftMargin(ClassId.keysig) +
                      doc!.getRightMargin(ClassId.keysig)) *
                  unit)
          .truncate();
    }

    scoreDef.setDrawingWidth(width);
  }

  /// Draw the page-level milestone elements (mdiv / score / milestone end)
  /// (mirrors `View::DrawPageElement`, view_page.cpp:163).
  void drawPageElement(DeviceContext dc, PageElement element) {
    if (element.isClass(ClassId.pageMilestoneEnd)) {
      final PageMilestoneEnd elementEnd = element as PageMilestoneEnd;
      dc.startGraphic(elementEnd, elementEnd.start.id, elementEnd.id);
      dc.endGraphic(elementEnd);
    } else if (element.isClass(ClassId.mdiv)) {
      // When the mdiv is not visible, then there is no start / end element
      final String elementStart =
          (element.isMilestoneElement) ? 'pageMilestone' : '';
      dc.startGraphic(element, elementStart, element.id);
      dc.endGraphic(element);
    } else if (element.isClass(ClassId.score)) {
      dc.startGraphic(element, 'pageMilestone', element.id);
      dc.endGraphic(element);
    }
  }

  // ---------------------------------------------------------------------------
  // View - System
  // ---------------------------------------------------------------------------

  /// Draw a full system (mirrors `View::DrawSystem`, view_page.cpp:191).
  void drawSystem(DeviceContext dc, System system) {
    dc.startGraphic(system, '', system.id);

    final Measure? firstMeasure =
        system.findDescendantByType(ClassId.measure, deepness: 1) as Measure?;

    drawSystemDivider(dc, system, firstMeasure);

    // first we need to clear the drawing list of postponed elements
    system.resetDrawingList();

    if (firstMeasure != null) {
      // The C++ asserts the scoreDef inside DrawScoreDef (view_page.cpp:261);
      // the `!` here is the same contract.
      drawScoreDef(
          dc, system.drawingScoreDef!, firstMeasure, system.getDrawingX());
    }

    drawSystemChildren(dc, system, system);

    drawSystemList(dc, system, ClassId.syl);
    drawSystemList(dc, system, ClassId.annotScore);
    drawSystemList(dc, system, ClassId.beamSpan);
    drawSystemList(dc, system, ClassId.bracketSpan);
    drawSystemList(dc, system, ClassId.dynam);
    drawSystemList(dc, system, ClassId.dir);
    drawSystemList(dc, system, ClassId.gliss);
    drawSystemList(dc, system, ClassId.hairpin);
    drawSystemList(dc, system, ClassId.trill);
    drawSystemList(dc, system, ClassId.figure);
    drawSystemList(dc, system, ClassId.lv);
    drawSystemList(dc, system, ClassId.phrase);
    drawSystemList(dc, system, ClassId.octave);
    drawSystemList(dc, system, ClassId.ornam);
    drawSystemList(dc, system, ClassId.pedal);
    drawSystemList(dc, system, ClassId.pitchInflection);
    drawSystemList(dc, system, ClassId.tempo);
    drawSystemList(dc, system, ClassId.tie);
    drawSystemList(dc, system, ClassId.slur);
    drawSystemList(dc, system, ClassId.ending);

    dc.endGraphic(system);
  }

  /// Draw the postponed (time spanning) elements of the system drawing list
  /// (mirrors `View::DrawSystemList`, view_page.cpp:235).
  void drawSystemList(DeviceContext dc, System system, ClassId classId) {
    final List<Object> drawingList = system.getDrawingList();

    for (final Object object in drawingList) {
      // static const std::set<ClassId> in the C++
      const Set<ClassId> timeSpanningClasses = {
        ClassId.annotScore,
        ClassId.beamSpan,
        ClassId.bracketSpan,
        ClassId.dir,
        ClassId.dynam,
        ClassId.figure,
        ClassId.gliss,
        ClassId.hairpin,
        ClassId.lv,
        ClassId.octave,
        ClassId.ornam,
        ClassId.pedal,
        ClassId.phrase,
        ClassId.pitchInflection,
        ClassId.slur,
        ClassId.syl,
        ClassId.tempo,
        ClassId.tie,
        ClassId.trill,
      };
      if (object.isClass(classId) && timeSpanningClasses.contains(classId)) {
        startOffset(dc, object, 100);
        drawTimeSpanningElement(dc, object, system);
        endOffset(dc, object);
      }
      if (object.isClass(classId) && (classId == ClassId.ending)) {
        // cast to Ending check in DrawEnding
        drawEnding(dc, object as Ending, system);
      }
    }
  }

  /// Draw a layer and its postponed tuplets (mirrors `View::DrawLayer`,
  /// view_page.cpp:1575).
  void drawLayer(DeviceContext dc, Layer layer, Staff staff, Measure measure) {
    // first we need to clear the drawing list of postponed elements
    layer.resetDrawingList();

    // Now start to draw the layer content

    dc.startGraphic(layer, '', layer.id);

    drawLayerChildren(dc, layer, layer, staff, measure);

    dc.endGraphic(layer);

    // first draw the postponed tuplets
    drawLayerList(dc, layer, staff, measure, ClassId.tupletBracket);
    drawLayerList(dc, layer, staff, measure, ClassId.tupletNum);
  }

  /// Draw the postponed tuplet brackets / numbers of the layer drawing list
  /// (mirrors `View::DrawLayerList`, view_page.cpp:1598).
  void drawLayerList(DeviceContext dc, Layer layer, Staff staff,
      Measure measure, ClassId classId) {
    final List<Object> drawingList = layer.getDrawingList();

    for (final Object object in drawingList) {
      if (object.isClass(classId) && (classId == ClassId.tupletBracket)) {
        drawTupletBracket(dc, object as LayerElement, layer, staff, measure);
      }
      if (object.isClass(classId) && (classId == ClassId.tupletNum)) {
        drawTupletNum(dc, object as LayerElement, layer, staff, measure);
      }
    }
  }

  /// Draw a system divider between two systems when the scoreDef is
  /// optimized or the option asks for it (mirrors `View::DrawSystemDivider`,
  /// view_page.cpp:1617).
  ///
  /// Nothing is drawn for the first system of a page or of an mdiv, or when
  /// the option is off — the early returns of the C++ are preserved.
  void drawSystemDivider(
      DeviceContext dc, System system, Measure? firstMeasure) {
    // Draw system divider (from the second one) if scoreDef is optimized
    if (firstMeasure == null ||
        (options!.systemDivider.value == SystemDivider.none)) {
      return;
    }
    // No system divider if we are on the first system of a page or of an mdiv
    if (system.isFirstInPage() || system.isFirstOfMdiv()) return;

    // initialize to zero, first measure is not supposed to have system divider
    int previousSystemBottomMarginY = 0;
    final Object? page = system.getFirstAncestor(ClassId.page);
    if (page != null) {
      final Object? previousSystem = page.getPreviousSibling(system);
      if (previousSystem != null) {
        final Measure? previousSystemMeasure = previousSystem
            .findDescendantByType(ClassId.measure, deepness: 1) as Measure?;
        if (previousSystemMeasure != null) {
          final Staff? bottomStaff =
              previousSystemMeasure.getBottomVisibleStaff();
          // set Y position to that of lowest (bottom) staff, substact space
          // taken by staff lines and substract offset of the system divider
          // symbol itself (added to y2 and y4)
          if (bottomStaff != null) {
            previousSystemBottomMarginY = bottomStaff.getDrawingY() -
                (bottomStaff.drawingLines - 1) *
                    doc!.getDrawingDoubleUnit(bottomStaff.drawingStaffSize) -
                doc!.getDrawingUnit(100) * 5;
          }
        }
      }
    }

    if (system.drawingIsOptimized ||
        (options!.systemDivider.value.index > SystemDivider.auto.index)) {
      int y = system.getDrawingY();
      final Staff? staff = system.getTopVisibleStaff(true);
      if (staff != null) {
        // Place it in the middle of current and previous systems - in very
        // tight layout this can collision with the staff above. To be improved
        y = (staff.getDrawingY() + previousSystemBottomMarginY) ~/ 2;
      }
      final int x1 = system.getDrawingX() - doc!.getDrawingUnit(100) * 3;
      final int x2 = system.getDrawingX() + doc!.getDrawingUnit(100) * 3;
      final int y1 = y - doc!.getDrawingUnit(100) * 1;
      final int y2 = y + doc!.getDrawingUnit(100) * 3;
      final int y3 = y1 + doc!.getDrawingUnit(100) * 2;
      final int y4 = y2 + doc!.getDrawingUnit(100) * 2;
      // left and left-right
      dc.startCustomGraphic('systemDivider');

      drawObliquePolygon(
          dc, x1, y1, x2, y2, (doc!.getDrawingUnit(100) * 1.5).toInt());
      drawObliquePolygon(
          dc, x1, y3, x2, y4, (doc!.getDrawingUnit(100) * 1.5).toInt());
      if (options!.systemDivider.value == SystemDivider.leftRight) {
        // Right divider is not taken into account in the layout calculation
        // and can collision with the music content
        // The C++ searches the last measure with direction BACKWARD; the
        // Dart findAllDescendantsByType always walks forward, so the last
        // match is taken (same result for the same deepness of 1).
        final List<Object> measures =
            system.findAllDescendantsByType(ClassId.measure, deepness: 1);
        final Measure lastMeasure = measures.last as Measure;
        final int x4 =
            lastMeasure.getDrawingX() + lastMeasure.getRightBarLineRight();
        final int x3 = x4 - doc!.getDrawingUnit(100) * 6;
        drawObliquePolygon(
            dc, x3, y1, x4, y2, (doc!.getDrawingUnit(100) * 1.5).toInt());
        drawObliquePolygon(
            dc, x3, y3, x4, y4, (doc!.getDrawingUnit(100) * 1.5).toInt());
      }

      dc.endCustomGraphic();
    }
  }

  // ---------------------------------------------------------------------------
  // View - Children
  // ---------------------------------------------------------------------------

  /// Dispatch the children of a system (or of a system-level container) to
  /// their drawing method (mirrors `View::DrawSystemChildren`,
  /// view_page.cpp:1686).
  void drawSystemChildren(DeviceContext dc, Object parent, System system) {
    for (final Object current in parent.children) {
      if (current.isClass(ClassId.measure)) {
        // cast to Measure check in DrawMeasure
        drawMeasure(dc, current as Measure, system);
      }
      // scoreDef are not drawn directly, but anything else should not be possible
      else if (current.isClass(ClassId.scoreDef)) {
        // nothing to do, then
        final ScoreDef scoreDef = current as ScoreDef;

        final Measure? nextMeasure =
            system.getNextSibling(scoreDef, ClassId.measure) as Measure?;
        if (nextMeasure != null && scoreDef.drawLabelsFlag) {
          ScoreDef scoreDefToDraw = scoreDef;
          bool noLabels = false;
          // If we have an emprty scoreDef after a section with `@restart="true"`
          // still draw the staffGrp symbols (braces, bracket) but no labels -
          // use the system scoreDef for that
          if (scoreDef.childCount == 0) {
            scoreDefToDraw = system.drawingScoreDef!;
            noLabels = true;
          }
          drawScoreDef(dc, scoreDefToDraw, nextMeasure,
              nextMeasure.getDrawingX(), null, false, false, noLabels);
        }

        setScoreDefDrawingWidth(dc, scoreDef);
      } else if (current.isSystemElement) {
        // cast to SystemElement check in DrawSystemEditorial element
        drawSystemElement(dc, current as SystemElement, system);
      } else if (current.isClass(ClassId.div)) {
        // cast to Div check in DrawDiv element
        drawDiv(dc, current as Div, system);
      } else if (current.isEditorialElement) {
        // cast to EditorialElement check in DrawSystemEditorial element
        drawSystemEditorialElement(dc, current as EditorialElement, system);
      } else {
        assert(false);
      }
    }
  }

  /// Dispatch the children of a measure (mirrors
  /// `View::DrawMeasureChildren`, view_page.cpp:1737).
  void drawMeasureChildren(
      DeviceContext dc, Object parent, Measure measure, System system) {
    final List<Object> objects = parent.findAllDescendantsByType(
        ClassId.beamSpan,
        continueDepthSearchForMatches: false);
    for (final Object element in objects) {
      final BeamSpan beamSpan = element as BeamSpan;
      final BeamSpanSegment? segment = beamSpan.getSegmentForSystem(system);
      if (segment != null) {
        // Mirrors `segment->CalcBeam(segment->GetLayer(), segment->GetStaff(),
        // m_doc, beamSpan, beamSpan->m_drawingPlace)` —
        // `BeamSegment::CalcBeam` (beam.cpp:89) arrives with the beam
        // rendering phase (task 05-17).
        _notYet('CalcBeam', '05-17');
      }
    }

    for (final Object current in parent.children) {
      if (current.isClass(ClassId.ossia)) {
        drawOssia(dc, current as Ossia, measure, system);
      } else if (current.isClass(ClassId.staff)) {
        // cast to Staff check in DrawStaff
        drawStaff(dc, current as Staff, measure, system);
      } else if (current.isControlElement) {
        // cast to ControlElement check in DrawControlElement
        drawControlElement(dc, current as ControlElement, measure, system);
      } else if (current.isEditorialElement) {
        // cast to EditorialElement check in DrawMeasureEditorialElement
        drawMeasureEditorialElement(
            dc, current as EditorialElement, measure, system);
      } else {
        logDebug('Current is ${current.className}');
        assert(false);
      }
    }
  }

  /// Dispatch the children of a staff (mirrors `View::DrawStaffChildren`,
  /// view_page.cpp:1776).
  void drawStaffChildren(
      DeviceContext dc, Object parent, Staff staff, Measure measure) {
    for (final Object current in parent.children) {
      if (current.isClass(ClassId.layer)) {
        // cast to Layer check in DrawLayer
        drawLayer(dc, current as Layer, staff, measure);
      } else if (current.isEditorialElement) {
        // cast to EditorialElement check in DrawStaffEditorialElement
        drawStaffEditorialElement(
            dc, current as EditorialElement, staff, measure);
      } else {
        assert(false);
      }
    }
  }

  /// Dispatch the children of a layer (mirrors `View::DrawLayerChildren`,
  /// view_page.cpp:1798).
  void drawLayerChildren(DeviceContext dc, Object parent, Layer layer,
      Staff staff, Measure measure) {
    for (final Object current in parent.children) {
      if (current.isLayerElement) {
        drawLayerElement(dc, current as LayerElement, layer, staff, measure);
      } else if (current.isEditorialElement) {
        // cast to EditorialElement check in DrawLayerEditorialElement
        drawLayerEditorialElement(
            dc, current as EditorialElement, layer, staff, measure);
      } else if (!(current.isClass(ClassId.label) ||
          current.isClass(ClassId.labelAbbr))) {
        assert(false);
      }
    }
  }

  /// Dispatch the text children of a control element or text container
  /// (mirrors `View::DrawTextChildren`, view_page.cpp:1820).
  void drawTextChildren(
      DeviceContext dc, Object parent, TextDrawingParams params) {
    // For ControlElement, we need to set the positioner empty bounding box if no text
    if (parent.isControlElement) {
      if (parent.childCount == 0 || !parent.hasNonEditorialContent) {
        final ControlElement controlElement = parent as ControlElement;
        final FloatingPositioner? positioner =
            controlElement.getCurrentFloatingPositioner();
        // With MNum drawn from DrawMeasure there will be no positioner
        if (positioner != null) positioner.setEmptyBB();
      }
    }

    for (final Object current in parent.children) {
      if (current.isTextElement) {
        drawTextElement(dc, current as TextElement, params);
      } else if (current.isEditorialElement) {
        // cast to EditorialElement check in DrawTextEditorialElement
        drawTextEditorialElement(dc, current as EditorialElement, params);
      } else {
        assert(false);
      }
    }
  }

  /// Dispatch the children of an `fb` (figured bass) element (mirrors
  /// `View::DrawFbChildren`, view_page.cpp:1850).
  void drawFbChildren(
      DeviceContext dc, Object parent, TextDrawingParams params) {
    for (final Object current in parent.children) {
      if (current.isTextElement) {
        drawTextElement(dc, current as TextElement, params);
      } else if (current.isEditorialElement) {
        // cast to EditorialElement check in DrawLayerEditorialElement
        drawFbEditorialElement(dc, current as EditorialElement, params);
      } else {
        assert(false);
      }
    }
  }

  /// Dispatch the children of a running element (header / footer) (mirrors
  /// `View::DrawRunningChildren`, view_page.cpp:1869).
  void drawRunningChildren(
      DeviceContext dc, Object parent, TextDrawingParams params) {
    for (final Object current in parent.children) {
      if (current.isClass(ClassId.fig)) {
        drawFig(dc, current as Fig, params);
      } else if (current.isTextElement) {
        // We are now reaching a text element - start set only here because we
        // can have a figure (the C++ copies the params struct;
        // `TextDrawingParams.copy` mirrors the implicit copy constructor)
        final TextDrawingParams paramsChild = params.copy();
        dc.startText(toDeviceContextX(params.x), toDeviceContextY(params.y),
            HorizontalAlignment.left);
        drawTextElement(dc, current as TextElement, paramsChild);
        dc.endText();
      } else if (current.isEditorialElement) {
        // cast to EditorialElement check in DrawLayerEditorialElement
        drawRunningEditorialElement(dc, current as EditorialElement, params);
      } else {
        assert(false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // View - Editorial
  // ---------------------------------------------------------------------------

  /// Draw a system-level editorial element (mirrors
  /// `View::DrawSystemEditorialElement`, view_page.cpp:1900).
  void drawSystemEditorialElement(
      DeviceContext dc, EditorialElement element, System system) {
    if (element.isClass(ClassId.annot)) {
      drawAnnot(dc, element);
      return;
    }
    if (element.isClass(ClassId.app)) {
      // Mirrors `dynamic_cast<App *>(element)->GetLevel()`: in this port the
      // level lives on the shared EditorialElement base.
      final EditorialLevel level = element.editorialLevel;
      if ((level != EditorialLevel.score) &&
          (level != EditorialLevel.topLevel)) {
        return;
      }
    } else if (element.isClass(ClassId.choice)) {
      final EditorialLevel level = element.editorialLevel;
      if ((level != EditorialLevel.score) &&
          (level != EditorialLevel.topLevel)) {
        return;
      }
    }
    String elementStart = '';
    if (element.isMilestoneElement) elementStart = 'systemElementStart';

    dc.startGraphic(element, elementStart, element.id);
    // EditorialElements at the system level that are visible have no children
    // if (element->m_visibility == Visible) {
    //    DrawSystemChildren(dc, element, system);
    //}
    dc.endGraphic(element);
  }

  /// Draw a measure-level editorial element (mirrors
  /// `View::DrawMeasureEditorialElement`, view_page.cpp:1928).
  void drawMeasureEditorialElement(DeviceContext dc, EditorialElement element,
      Measure measure, System system) {
    if (element.isClass(ClassId.annot)) {
      drawAnnot(dc, element);
      return;
    }
    if (element.isClass(ClassId.app)) {
      assert(element.editorialLevel == EditorialLevel.measure);
    } else if (element.isClass(ClassId.choice)) {
      assert(element.editorialLevel == EditorialLevel.measure);
    }

    dc.startGraphic(element, '', element.id);
    if (!element.isHidden) {
      drawMeasureChildren(dc, element, measure, system);
    }
    dc.endGraphic(element);
  }

  /// Draw a staff-level editorial element (mirrors
  /// `View::DrawStaffEditorialElement`, view_page.cpp:1949).
  void drawStaffEditorialElement(DeviceContext dc, EditorialElement element,
      Staff staff, Measure measure) {
    if (element.isClass(ClassId.annot)) {
      drawAnnot(dc, element);
      return;
    }
    if (element.isClass(ClassId.app)) {
      assert(element.editorialLevel == EditorialLevel.staff);
    } else if (element.isClass(ClassId.choice)) {
      assert(element.editorialLevel == EditorialLevel.staff);
    }

    dc.startGraphic(element, '', element.id);
    if (!element.isHidden) {
      drawStaffChildren(dc, element, staff, measure);
    }
    dc.endGraphic(element);
  }

  /// Draw a layer-level editorial element (mirrors
  /// `View::DrawLayerEditorialElement`, view_page.cpp:1970).
  void drawLayerEditorialElement(DeviceContext dc, EditorialElement element,
      Layer layer, Staff staff, Measure measure) {
    if (element.isClass(ClassId.annot)) {
      drawAnnot(dc, element);
      return;
    }
    if (element.isClass(ClassId.app)) {
      assert(element.editorialLevel == EditorialLevel.layer);
    } else if (element.isClass(ClassId.choice)) {
      assert(element.editorialLevel == EditorialLevel.layer);
    }

    dc.startGraphic(element, '', element.id);
    if (!element.isHidden) {
      drawLayerChildren(dc, element, layer, staff, measure);
    }
    dc.endGraphic(element);
  }

  /// Draw a text-level editorial element (mirrors
  /// `View::DrawTextEditorialElement`, view_page.cpp:1992).
  void drawTextEditorialElement(
      DeviceContext dc, EditorialElement element, TextDrawingParams params) {
    if (element.isClass(ClassId.annot)) {
      drawAnnot(dc, element, true);
      return;
    }
    if (element.isClass(ClassId.app)) {
      assert(element.editorialLevel == EditorialLevel.text);
    } else if (element.isClass(ClassId.choice)) {
      assert(element.editorialLevel == EditorialLevel.text);
    }

    dc.startTextGraphic(element, '', element.id);
    if (!element.isHidden) {
      drawTextChildren(dc, element, params);
    }
    dc.endTextGraphic(element);
  }

  /// Draw an `fb`-level editorial element (mirrors
  /// `View::DrawFbEditorialElement`, view_page.cpp:2013).
  void drawFbEditorialElement(
      DeviceContext dc, EditorialElement element, TextDrawingParams params) {
    if (element.isClass(ClassId.annot)) {
      drawAnnot(dc, element, true);
      return;
    }
    if (element.isClass(ClassId.app)) {
      assert(element.editorialLevel == EditorialLevel.fb);
    } else if (element.isClass(ClassId.choice)) {
      assert(element.editorialLevel == EditorialLevel.fb);
    }

    dc.startTextGraphic(element, '', element.id);
    if (!element.isHidden) {
      drawFbChildren(dc, element, params);
    }
    dc.endTextGraphic(element);
  }

  /// Draw a running-element-level editorial element (mirrors
  /// `View::DrawRunningEditorialElement`, view_page.cpp:2034).
  void drawRunningEditorialElement(
      DeviceContext dc, EditorialElement element, TextDrawingParams params) {
    if (element.isClass(ClassId.annot)) {
      drawAnnot(dc, element, true);
      return;
    }
    if (element.isClass(ClassId.app)) {
      assert(element.editorialLevel == EditorialLevel.running);
    } else if (element.isClass(ClassId.choice)) {
      assert(element.editorialLevel == EditorialLevel.running);
    }

    dc.startGraphic(element, '', element.id);
    if (!element.isHidden) {
      drawRunningChildren(dc, element, params);
    }
    dc.endGraphic(element);
  }

  /// Draw an `annot` element as a description (mirrors `View::DrawAnnot`,
  /// view_page.cpp:2055).
  void drawAnnot(DeviceContext dc, EditorialElement element,
      [bool isTextElement = false]) {
    if (isTextElement) {
      dc.startTextGraphic(element, '', element.id);
    } else {
      dc.startGraphic(element, '', element.id);
    }

    final Annot annot = element as Annot;
    // The C++ applies UTF32to8 to the u32string text; Dart strings are text
    // already (deviation note of this file).
    dc.addDescription(annot.getText());

    if (isTextElement) {
      dc.endTextGraphic(element);
    } else {
      dc.endGraphic(element);
    }
  }

  // ---------------------------------------------------------------------------
  // Stubs for the methods of view_page.cpp owned by the following tasks
  // ---------------------------------------------------------------------------

  /// STUB — ported by task 05-09 (mirrors `View::DrawScoreDef`,
  /// view_page.cpp:257).
  ///
  /// The [barLine] parameter is typed `Object?` until 05-09 ports the real
  /// signature (`BarLine *barLine = NULL`, view.h:190).
  void drawScoreDef(DeviceContext dc, ScoreDef scoreDef, Measure measure, int x,
      [Object? barLine,
      bool isLastMeasure = false,
      bool isLastSystem = false,
      bool noLabels = false]) {
    _notYet('DrawScoreDef', '05-09');
  }

  /// STUB — ported by task 05-10 (mirrors `View::DrawMeasure`,
  /// view_page.cpp:993).
  void drawMeasure(DeviceContext dc, Measure measure, System system) {
    _notYet('DrawMeasure', '05-10');
  }

  /// STUB — ported by task 05-10 (mirrors `View::DrawOssia`,
  /// view_page.cpp:1183).
  void drawOssia(
      DeviceContext dc, Ossia ossia, Measure measure, System system) {
    _notYet('DrawOssia', '05-10');
  }

  /// STUB — ported by task 05-11 (mirrors `View::DrawStaff`,
  /// view_page.cpp:1263).
  void drawStaff(
      DeviceContext dc, Staff staff, Measure measure, System system) {
    _notYet('DrawStaff', '05-11');
  }

  // ---------------------------------------------------------------------------
  // Stubs for the methods owned by the other view_*.cpp files
  //
  // Each stub mirrors the C++ signature and names the task that ports it.
  // REMOVE the stub from this file when porting the real method: two
  // extensions of this library declaring the same member name are a compile
  // error, so the port has to replace it (the compile error makes the place
  // obvious).
  // ---------------------------------------------------------------------------

  /// STUB — ported by task 05-22 in `view_control.dart` (mirrors
  /// `View::DrawSystemElement`, view_control.cpp:3014).
  void drawSystemElement(
      DeviceContext dc, SystemElement element, System system) {
    _notYet('DrawSystemElement', '05-22');
  }

  /// STUB — ported by task 05-22 in `view_control.dart` (mirrors
  /// `View::DrawEnding`, view_control.cpp:3048).
  void drawEnding(DeviceContext dc, Ending ending, System system) {
    _notYet('DrawEnding', '05-22');
  }

  /// STUB — ported by task 05-19 in `view_text.dart` (mirrors
  /// `View::DrawDiv`, view_text.cpp:696).
  void drawDiv(DeviceContext dc, Div div, System system) {
    _notYet('DrawDiv', '05-19');
  }

  /// STUB — ported by task 05-20 in `view_control.dart` (mirrors
  /// `View::DrawControlElement`, view_control.cpp:72).
  void drawControlElement(DeviceContext dc, ControlElement element,
      Measure measure, System system) {
    _notYet('DrawControlElement', '05-20');
  }

  /// STUB — ported by task 05-13 in `view_element.dart` (mirrors
  /// `View::DrawLayerElement`, view_element.cpp:65).
  void drawLayerElement(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    _notYet('DrawLayerElement', '05-13');
  }

  /// STUB — ported by task 05-19 in `view_text.dart` (mirrors
  /// `View::DrawTextElement`, view_text.cpp:224).
  void drawTextElement(
      DeviceContext dc, TextElement element, TextDrawingParams params) {
    _notYet('DrawTextElement', '05-19');
  }

  /// STUB — ported by task 05-19 in `view_text.dart` (mirrors
  /// `View::DrawFig`, view_text.cpp:352).
  void drawFig(DeviceContext dc, Fig fig, TextDrawingParams params) {
    _notYet('DrawFig', '05-19');
  }

  /// STUB — ported by task 05-19 in `view_text.dart` (mirrors
  /// `View::DrawRunningElements`, view_text.cpp:642). The C++ no-ops for a
  /// page without header / footer (and for the vertical-update mode of the
  /// `BBoxDeviceContext`); until then every `drawCurrentPage` call ends
  /// here after having produced the whole page output.
  void drawRunningElements(DeviceContext dc, Page page) {
    _notYet('DrawRunningElements', '05-19');
  }

  /// STUB — ported by task 05-20 in `view_control.dart` (mirrors
  /// `View::DrawTimeSpanningElement`, view_control.cpp:183).
  void drawTimeSpanningElement(
      DeviceContext dc, Object element, System system) {
    _notYet('DrawTimeSpanningElement', '05-20');
  }

  /// STUB — ported by task 05-18 in `view_tuplet.dart` (mirrors
  /// `View::DrawTupletBracket`, view_tuplet.cpp:75).
  void drawTupletBracket(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    _notYet('DrawTupletBracket', '05-18');
  }

  /// STUB — ported by task 05-18 in `view_tuplet.dart` (mirrors
  /// `View::DrawTupletNum`, view_tuplet.cpp:153).
  void drawTupletNum(DeviceContext dc, LayerElement element, Layer layer,
      Staff staff, Measure measure) {
    _notYet('DrawTupletNum', '05-18');
  }
}

/// Marks a drawing method that the C++ has but a later task will port (the
/// stubs above and the `CalcBeam` call site inside
/// [ViewPage.drawMeasureChildren]). Each call names the task that fills it.
Never _notYet(String function, String task) {
  throw UnimplementedError('$function is not ported yet (task $task)');
}
