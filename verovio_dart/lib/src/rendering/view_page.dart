/// Port of `view_page.cpp` (A and B) — the page/system/scoreDef drawing
/// spine of the `View`: `DrawCurrentPage`, `DrawSystem`, `DrawPageElement`,
/// `SetScoreDefDrawingWidth`, `GetPPUFactor`, `DrawSystemDivider`,
/// `DrawLayer`/`DrawLayerList`, the 7 `Draw*Children` dispatchers and the 7
/// `Draw*EditorialElement` dispatchers, `DrawAnnot` (view_page.cpp:65-255 and
/// 1575-2076, task 05-08); `DrawScoreDef`, `DrawStaffGrp`,
/// `DrawStaffDefLabels`, `DrawGrpSym`, `DrawLayerDefLabels`, `DrawLabels`,
/// `DrawBracket`, `DrawBracketSq`, `DrawBrace`, `DrawStaffDef` and
/// `DrawStaffDefCautionary` (view_page.cpp:257-677 and 1460-1520, task
/// 05-09).
///
/// The measure / barline side of `view_page.cpp` arrives with task 05-10,
/// the staff side with 05-11; the methods they own are `_notYet` stubs at
/// the bottom of this file.
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
/// - `View::DrawGrpSym`'s `int &x` output parameter (view.h:197) becomes a
///   return value ([ViewPage.drawGrpSym]): Dart has no reference parameters
///   for primitives.
part of 'view.dart';

/// The `view_page.cpp` methods of [View] ported by tasks 05-08 and 05-09.
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
        logDebug('DrawCurrentPage: unhandled page child ${child.className}');
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
        // Milestone wrappers (section/score) appear as SystemMilestone
        // objects; they are not SystemElements but carry the milestone
        // semantics. Treat them as no-ops for the barline task.
        logDebug('DrawSystemChildren: unhandled ${current.className}');
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
        try {
          drawLayerElement(dc, current as LayerElement, layer, staff, measure);
        } on UnimplementedError {
          // For elements whose View::Draw* is still a stub (05-14..05-24),
          // keep the hierarchy by emitting an empty graphic. This matches the
          // C++ `SetEmptyBB()` branches for visible==false / insivible etc.
          final LayerElement el = current as LayerElement;
          dc.startGraphic(el, '', el.id);
          el.setEmptyBB();
          dc.endGraphic(el);
        }
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
  // View - ScoreDef, staffGrp, labels and brackets (task 05-09)
  // ---------------------------------------------------------------------------

  /// Draw the initial scoreDef of a system, or a mid-system barLine group
  /// (mirrors `View::DrawScoreDef`, view_page.cpp:257).
  void drawScoreDef(DeviceContext dc, ScoreDef scoreDef, Measure measure, int x,
      [BarLine? barLine,
      bool isLastMeasure = false,
      bool isLastSystem = false,
      bool noLabels = false]) {
    final StaffGrp? staffGrp =
        scoreDef.findDescendantByType(ClassId.staffGrp) as StaffGrp?;
    if (staffGrp == null) return;

    if (barLine == null) {
      // Draw the first staffGrp and from there its children recursively
      ScoreDefDrawingLabels drawingLabels = scoreDef.drawLabels
          ? ScoreDefDrawingLabels.full
          : ScoreDefDrawingLabels.abbr;
      if (noLabels) drawingLabels = ScoreDefDrawingLabels.none;
      drawStaffGrp(dc, measure, staffGrp, x, true, drawingLabels);
    } else {
      dc.startGraphic(barLine, '', barLine.id);
      // VRV_UNSET: DrawBarLines (task 05-10) owns the `int &yBottomPrevious`
      // output parameter; DrawScoreDef never reads it back.
      drawBarLines(dc, measure, staffGrp, barLine, isLastMeasure, isLastSystem,
          meiUnset);
      dc.endGraphic(barLine);
    }
  }

  /// Draw a staffGrp and, recursively, its nested staffGrps (mirrors
  /// `View::DrawStaffGrp`, view_page.cpp:286).
  void drawStaffGrp(DeviceContext dc, Measure measure, StaffGrp staffGrp, int x,
      [bool topStaffGrp = false,
      ScoreDefDrawingLabels drawingLabels = ScoreDefDrawingLabels.abbr]) {
    if (staffGrp.drawingVisibility == VisibilityOptimization.hidden) return;

    final (StaffDef?, StaffDef?) firstLast = staffGrp.getFirstLastStaffDef();
    final StaffDef? firstDef = firstLast.$1;
    final StaffDef? lastDef = firstLast.$2;

    if (firstDef == null || lastDef == null) {
      logDebug('Could not get staffDef while drawing staffGrp - DrawStaffGrp');
      return;
    }

    final AttNIntegerComparison comparisonFirst =
        AttNIntegerComparison(ClassId.staff, firstDef.n ?? 0);
    final Staff? first = measure.findDescendantByComparison(comparisonFirst,
        deepness: 1) as Staff?;
    final AttNIntegerComparison comparisonLast =
        AttNIntegerComparison(ClassId.staff, lastDef.n ?? 0);
    final Staff? last = measure.findDescendantByComparison(comparisonLast,
        deepness: 1) as Staff?;

    if (first == null || last == null) {
      logDebug('Could not get staff (${firstDef.n}; ${lastDef.n}) while '
          'drawing staffGrp - DrawStaffGrp');
      return;
    }

    final int staffSize = staffGrp.getMaxStaffSize();
    int yTop = first.getDrawingY();
    // for the bottom position we need to take into account the number of
    // lines and the staff size
    int yBottom = last.getDrawingY() -
        ((lastDef.lines ?? meiUnset) - 1) *
            doc!.getDrawingDoubleUnit(last.drawingStaffSize);
    // adjust to single line staves
    if ((firstDef.lines ?? meiUnset) <= 1) {
      yTop += doc!.getDrawingDoubleUnit(last.drawingStaffSize);
    }
    if ((lastDef.lines ?? meiUnset) <= 1) {
      yBottom -= doc!.getDrawingDoubleUnit(last.drawingStaffSize);
    }

    // draw the system start bar line
    final ScoreDef? scoreDef =
        staffGrp.getFirstAncestor(ClassId.scoreDef) as ScoreDef?;
    if (topStaffGrp) {
      if (scoreDef != null && scoreDef.hasSystemStartLine()) {
        final int barLineWidth = doc!.getDrawingBarLineWidth(staffSize);
        drawVerticalLine(
            dc, yTop, yBottom, x + barLineWidth ~/ 2, barLineWidth);
      }
    }

    // draw the group symbol
    final int staffGrpX = x;
    x = drawGrpSym(dc, measure, staffGrp, x);
    final int grpSymSpace = staffGrpX - x;

    // recursively draw the children
    for (final Object child in staffGrp.children) {
      if (child is StaffGrp) {
        drawStaffGrp(dc, measure, child, x, false, drawingLabels);
      }
    }

    if (drawingLabels != ScoreDefDrawingLabels.none) {
      final bool abbreviations = drawingLabels == ScoreDefDrawingLabels.abbr;
      // DrawStaffGrpLabel
      final int space = doc!.getDrawingDoubleUnit(staffGrp.getMaxStaffSize());
      final int xLabel = x - space;
      final int yLabel =
          yBottom - (yBottom - yTop) ~/ 2 - doc!.getDrawingUnit(100);
      drawLabels(dc, scoreDef!, staffGrp, xLabel, yLabel, abbreviations, 100,
          2 * space + grpSymSpace);

      drawStaffDefLabels(dc, measure, staffGrp, x, abbreviations);
    }
  }

  /// Draw the labels of the staffDefs of a staffGrp (mirrors
  /// `View::DrawStaffDefLabels`, view_page.cpp:361).
  void drawStaffDefLabels(
      DeviceContext dc, Measure measure, StaffGrp staffGrp, int x,
      [bool abbreviations = false]) {
    for (final Object child in staffGrp.children) {
      if (child is! StaffDef) continue;
      final StaffDef staffDef = child;

      final AttNIntegerComparison comparison =
          AttNIntegerComparison(ClassId.staff, staffDef.n ?? 0);
      final Staff? staff =
          measure.findDescendantByComparison(comparison, deepness: 1) as Staff?;
      final ScoreDef? scoreDef =
          staffGrp.getFirstAncestor(ClassId.scoreDef) as ScoreDef?;

      if (staff == null || scoreDef == null) {
        logDebug('Staff or ScoreDef missing in View::DrawStaffDefLabels');
        continue;
      }

      if (!staff.drawingIsVisible()) continue;

      // HARDCODED
      final int doubleUnit =
          doc!.getDrawingDoubleUnit(staffGrp.getMaxStaffSize());
      final int space = doubleUnit;
      final int y = staff.getDrawingY() -
          ((staffDef.lines ?? meiUnset) * doubleUnit) ~/ 2;

      final int staffSize = staff.getDrawingStaffNotationSize();
      int adjust = 0;
      if (staffDef.hasLayerDefWithLabel()) adjust = 3 * doubleUnit;
      drawLabels(dc, scoreDef, staffDef, x - doubleUnit - adjust, y,
          abbreviations, staffSize, 2 * space + adjust);

      drawLayerDefLabels(dc, scoreDef, staff, staffDef, x, abbreviations);
    }
  }

  /// Draw the group symbol (brace, bracket, square bracket or line) of a
  /// staffGrp and return the drawing x after it (mirrors `View::DrawGrpSym`,
  /// view_page.cpp:403).
  ///
  /// Deviations from the C++:
  /// - the `int &x` output parameter (the symbol shrinks the drawing x for
  ///   whatever draws to its left) becomes the return value.
  int drawGrpSym(DeviceContext dc, Measure measure, StaffGrp staffGrp, int x) {
    final GrpSym? groupSymbol = staffGrp.getGroupSymbol();
    if (groupSymbol == null) return x;

    final StaffDef startDef = groupSymbol.getStartDef() as StaffDef;
    final StaffDef endDef = groupSymbol.getEndDef() as StaffDef;

    final AttNIntegerComparison comparisonFirst =
        AttNIntegerComparison(ClassId.staff, startDef.n ?? 0);
    final Staff? first = measure.findDescendantByComparison(comparisonFirst,
        deepness: 1) as Staff?;
    final AttNIntegerComparison comparisonLast =
        AttNIntegerComparison(ClassId.staff, endDef.n ?? 0);
    final Staff? last = measure.findDescendantByComparison(comparisonLast,
        deepness: 1) as Staff?;

    if (first == null || last == null) {
      logDebug('Could not get staff (${startDef.n}; ${endDef.n}) while '
          'drawing staffGrp - DrawStaffGrp');
      return x;
    }

    dc.startGraphic(groupSymbol, '', groupSymbol.id);

    final int staffSize = staffGrp.getMaxStaffSize();
    int yTop = first.getDrawingY();
    int yBottom = last.getDrawingY() -
        ((endDef.lines ?? meiUnset) - 1) *
            doc!.getDrawingDoubleUnit(last.drawingStaffSize);
    if ((startDef.lines ?? meiUnset) <= 1) {
      yTop += doc!.getDrawingDoubleUnit(last.drawingStaffSize);
    }
    if ((endDef.lines ?? meiUnset) <= 1) {
      yBottom -= doc!.getDrawingDoubleUnit(last.drawingStaffSize);
    }

    switch (groupSymbol.symbol) {
      case StaffgroupingsymSymbol.line:
        final int lineWidth =
            (doc!.getDrawingUnit(staffSize) * options!.bracketThickness.value)
                .truncate();
        final int yOffset =
            (doc!.getDrawingUnit(staffSize) * options!.staffLineWidth.value / 2)
                .truncate();
        drawVerticalLine(dc, yTop + yOffset, yBottom - yOffset,
            (x - 1.5 * lineWidth).truncate(), lineWidth);
        x -= 2 * lineWidth;
        break;
      case StaffgroupingsymSymbol.brace:
        drawBrace(dc, x, yTop, yBottom, staffSize);
        x = (x - 2.5 * doc!.getDrawingUnit(staffSize)).truncate();
        break;
      case StaffgroupingsymSymbol.bracket:
        drawBracket(dc, x, yTop, yBottom, staffSize);
        x = (x -
                doc!.getDrawingUnit(staffSize) *
                    (1.0 + options!.bracketThickness.value))
            .truncate();
        break;
      case StaffgroupingsymSymbol.bracketsq:
        drawBracketSq(dc, x, yTop, yBottom, staffSize);
        x -= doc!.getDrawingUnit(staffSize);
        break;
      default:
        break;
    }

    dc.endGraphic(groupSymbol);

    return x;
  }

  /// Draw the labels of the layerDefs of a staffDef (mirrors
  /// `View::DrawLayerDefLabels`, view_page.cpp:461).
  void drawLayerDefLabels(DeviceContext dc, ScoreDef scoreDef, Staff staff,
      StaffDef staffDef, int x,
      [bool abbreviations = false]) {
    final int space = doc!.getDrawingDoubleUnit(scoreDef.getMaxStaffSize());
    final int yCenter = staff.getDrawingY() -
        ((staffDef.lines ?? meiUnset) *
                doc!.getDrawingDoubleUnit(staff.drawingStaffSize)) ~/
            2;
    final int staffSize = staff.getDrawingStaffNotationSize();
    final int pointSize = doc!.getDrawingLyricFont(staffSize).pointSize;
    final int layerDefCount = staffDef.getChildCount(ClassId.layerDef);
    final int requiredSpace = pointSize * layerDefCount;

    int initialY = yCenter + (requiredSpace - pointSize) ~/ 2;
    for (int i = 0; i < layerDefCount; ++i) {
      final LayerDef? layerDef =
          staffDef.getChild(i, ClassId.layerDef) as LayerDef?;
      if (layerDef == null) continue;

      drawLabels(dc, scoreDef, layerDef, x - space, initialY, abbreviations,
          staffSize, space);
      initialY -= pointSize;
    }
  }

  /// Draw the label or labelAbbr of a layerDef / staffDef / staffGrp
  /// (mirrors `View::DrawLabels`, view_page.cpp:487).
  void drawLabels(DeviceContext dc, ScoreDef scoreDef, Object object, int x,
      int y, bool abbreviations, int staffSize, int space) {
    final Label? label =
        object.findDescendantByType(ClassId.label, deepness: 1) as Label?;
    final LabelAbbr? labelAbbr = object.findDescendantByType(ClassId.labelAbbr,
        deepness: 1) as LabelAbbr?;
    Object? graphic = label;

    String labelStr = label?.getText() ?? '';
    final String labelAbbrStr = labelAbbr?.getText() ?? '';

    if (abbreviations) {
      labelStr = labelAbbrStr;
      graphic = labelAbbr;
    }

    if (graphic == null || labelStr.isEmpty) return;

    final FontInfo labelTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      labelTxt.faceName = doc!.getResources().textFontName;
    }
    labelTxt.pointSize = doc!.getDrawingLyricFont(staffSize).pointSize;

    final int lineCount = graphic.getChildCount(ClassId.lb) + 1;
    if (lineCount > 1) {
      y += (doc!.getTextLineHeight(labelTxt, false) * (lineCount - 1)) ~/ 2;
    }

    final TextDrawingParams params = TextDrawingParams();
    params.x = x;
    params.y = y;
    params.pointSize = labelTxt.pointSize;

    dc.setFont(labelTxt);

    dc.startGraphic(graphic, '', graphic.id);

    dc.startText(toDeviceContextX(params.x), toDeviceContextY(params.y),
        HorizontalAlignment.right);
    drawTextChildren(dc, graphic, params);
    dc.endText();

    dc.endGraphic(graphic);

    // keep the widest width for the system - careful: this can be the label
    // OR labelAbbr
    scoreDef.setDrawingLabelsWidth(
        graphic.getContentX2() - graphic.getContentX1() + space);
    // also store in the system the maximum width with abbreviations for
    // justification
    if (labelAbbr != null && !abbreviations && labelAbbrStr.isNotEmpty) {
      final TextExtend extend = TextExtend();
      final List<String> lines = labelAbbr.getTextLines();
      int maxLength = 0;
      for (final String line in lines) {
        dc.getTextExtent(line, extend, typeSize: true);
        maxLength = extend.width > maxLength ? extend.width : maxLength;
      }
      final System system = scoreDef.getFirstAncestor(ClassId.system) as System;
      system.setDrawingAbbrLabelsWidth(maxLength + space);
    }

    dc.resetFont();
  }

  /// Draw a square (non-curly) system bracket (mirrors `View::DrawBracket`,
  /// view_page.cpp:556).
  void drawBracket(DeviceContext dc, int x, int y1, int y2, int staffSize) {
    final int offset = doc!.getDrawingStaffLineWidth(staffSize) ~/ 2;
    final int basicDist = doc!.getDrawingUnit(staffSize);

    final int bracketThickness =
        (doc!.getDrawingUnit(staffSize) * options!.bracketThickness.value)
            .truncate();

    final int x2 = x - basicDist;
    final int x1 = x2 - bracketThickness;

    drawSmuflCode(dc, x1, y1 + offset + bracketThickness ~/ 2,
        smuflE003BracketTop, staffSize, false);
    drawSmuflCode(dc, x1, y2 - offset - bracketThickness ~/ 2,
        smuflE004BracketBottom, staffSize, false);

    drawFilledRectangle(dc, x1, y1 + 2 * offset + bracketThickness ~/ 2, x2,
        y2 - 2 * offset - bracketThickness ~/ 2);
  }

  /// Draw a square-cornered system sub-bracket (mirrors
  /// `View::DrawBracketSq`, view_page.cpp:575).
  void drawBracketSq(DeviceContext dc, int x, int y1, int y2, int staffSize) {
    final int y = math.min(y1, y2);
    final int height = (y2 - y1).abs();
    final int horizontalThickness = doc!.getDrawingStaffLineWidth(staffSize);
    final int verticalThickness =
        (doc!.getDrawingUnit(staffSize) * options!.subBracketThickness.value)
            .truncate();
    final int width = doc!.getDrawingUnit(staffSize);

    drawSquareBracket(dc, true, x - width, y, height, width,
        horizontalThickness, verticalThickness);
  }

  /// Draw a system brace, either as a SMuFL glyph or as a pair of mirrored
  /// filled bezier curves depending on the `useBraceGlyph` option (mirrors
  /// `View::DrawBrace`, view_page.cpp:588).
  ///
  /// Deviations from the C++:
  /// - the bezier branch mutates a `Point points[4]` array by value in the
  ///   C++, copying it into `bez1`/`bez2` between mutations
  ///   (`bez1[i] = points[i]`, a struct-value copy). [Point] is a mutable
  ///   class here, so `bez1`/`bez2` are rebuilt with fresh `Point(...)`
  ///   instances at each copy instead of aliasing `points`' entries —
  ///   otherwise the second curve's later mutations of `points` would leak
  ///   into the first curve already handed to
  ///   [DeviceContext.drawCubicBezierPathFilled].
  void drawBrace(DeviceContext dc, int x, int y1, int y2, int staffSize) {
    final int basicDist = doc!.getDrawingUnit(staffSize);

    x -= basicDist;

    if (options!.useBraceGlyph.value) {
      final FontInfo font = doc!.getDrawingSmuflFont(staffSize, false);
      final int width = doc!.getGlyphWidth(smuflE000Brace, staffSize, false);
      final int height = 8 * doc!.getDrawingUnit(staffSize);
      final double scale = (y1 - y2) / height;
      // We want the brace width always to be 2 units
      final int braceWidth = doc!.getDrawingDoubleUnit(staffSize);
      x -= braceWidth;
      final double currentWidthToHeightRatio = font.widthToHeightRatio;
      final double widthAfterScalling = width * scale;
      font.widthToHeightRatio = braceWidth / widthAfterScalling;
      drawSmuflCode(
          dc, x, y2, smuflE000Brace, (staffSize * scale).truncate(), false);
      font.widthToHeightRatio = currentWidthToHeightRatio;
      return;
    }

    final List<Point> points = [Point(), Point(), Point(), Point()];
    List<Point> bez1 = [Point(), Point(), Point(), Point()];
    List<Point> bez2 = [Point(), Point(), Point(), Point()];

    final int penWidth = doc!.getDrawingStemWidth(staffSize);
    y1 -= penWidth;
    y2 += penWidth;
    x += penWidth;
    final int ySwap = y1;
    y1 = y2;
    y2 = ySwap;

    final int fact = doc!.getDrawingBeamWhiteWidth(staffSize, false) +
        doc!.getDrawingStemWidth(staffSize);
    final int xdec = toDeviceContextX(fact);
    final int ymed = (y1 + y2) ~/ 2;

    points[0].x = toDeviceContextX(x);
    points[0].y = toDeviceContextY(y1);
    points[1].x =
        toDeviceContextX(x - doc!.getDrawingDoubleUnit(staffSize) * 2);
    points[1].y = points[0].y -
        toDeviceContextX(doc!.getDrawingDoubleUnit(staffSize) * 3);
    points[3].x = toDeviceContextX(x - doc!.getDrawingDoubleUnit(staffSize));
    points[3].y = toDeviceContextY(ymed);
    points[2].x = toDeviceContextX(x + doc!.getDrawingUnit(staffSize));
    points[2].y =
        points[3].y + toDeviceContextX(doc!.getDrawingDoubleUnit(staffSize));

    bez1 = [
      Point(points[0].x, points[0].y),
      Point(points[1].x, points[1].y),
      Point(points[2].x, points[2].y),
      Point(points[3].x, points[3].y),
    ];

    points[1].x += xdec;
    points[2].x += xdec;

    bez2 = [
      Point(points[0].x, points[0].y),
      Point(points[1].x, points[1].y),
      Point(points[2].x, points[2].y),
      Point(points[3].x, points[3].y),
    ];

    dc.setPen(math.max(1, penWidth), PenStyle.solid);

    dc.drawCubicBezierPathFilled(bez1, bez2);

    // on produit l'image reflet vers le bas: 0 est identique
    points[0].y = toDeviceContextY(y2);
    points[1].y = points[0].y +
        toDeviceContextX(doc!.getDrawingDoubleUnit(staffSize) * 3);
    points[3].y = toDeviceContextY(ymed);
    points[2].y =
        points[3].y - toDeviceContextX(doc!.getDrawingDoubleUnit(staffSize));

    bez1 = [
      Point(points[0].x, points[0].y),
      Point(points[1].x, points[1].y),
      Point(points[2].x, points[2].y),
      Point(points[3].x, points[3].y),
    ];

    points[1].x -= xdec;
    points[2].x -= xdec;

    bez2 = [
      Point(points[0].x, points[0].y),
      Point(points[1].x, points[1].y),
      Point(points[2].x, points[2].y),
      Point(points[3].x, points[3].y),
    ];

    dc.drawCubicBezierPathFilled(bez1, bez2);

    dc.resetPen();
  }

  /// Draw the scoreDef drawing values materialized on the layer for a staff
  /// (mirrors `View::DrawStaffDef`, view_page.cpp:1460).
  ///
  /// Note: `DrawLayerElement` for `Clef`/`KeySig`/`Mensur`/`MeterSig`
  /// is not yet ported (05-13..05-16). When it throws, emit an empty graphic
  /// so the staff's `keySig` placeholder (`<g class="keySig" />` in the
  /// golden) and the subsequent `ledgerLines` are still produced — exactly
  /// what the C++ does for an empty `KeySig` at this stage.
  void drawStaffDef(DeviceContext dc, Staff staff, Measure measure) {
    // StaffDef information is always in the first layer
    final Layer? layer = staff.findDescendantByType(ClassId.layer) as Layer?;
    if (layer == null || !layer.hasStaffDef()) return;

    void tryDrawLayer(LayerElement el) {
      try {
        drawLayerElement(dc, el, layer, staff, measure);
      } on UnimplementedError {
        dc.startGraphic(el, '', el.id);
        dc.endGraphic(el);
      }
    }

    if (layer.getStaffDefClef() != null) {
      tryDrawLayer(layer.getStaffDefClef()!);
    }
    if (layer.getStaffDefKeySig() != null) {
      tryDrawLayer(layer.getStaffDefKeySig()!);
    }
    if (layer.getStaffDefMensur() != null) {
      tryDrawLayer(layer.getStaffDefMensur()!);
    }
    if (layer.getStaffDefMeterSigGrp() != null) {
      drawMeterSigGrp(dc, layer, staff);
    } else if (layer.getStaffDefMeterSig() != null) {
      tryDrawLayer(layer.getStaffDefMeterSig()!);
    }
  }

  /// Draw the cautionary scoreDef drawing values materialized on the layer
  /// for a staff (mirrors `View::DrawStaffDefCautionary`, view_page.cpp:1493).
  void drawStaffDefCautionary(DeviceContext dc, Staff staff, Measure measure) {
    // StaffDef cautionary information is always in the first layer
    final Layer? layer = staff.findDescendantByType(ClassId.layer) as Layer?;
    if (layer == null || !layer.hasCautionStaffDef()) return;

    void tryDrawLayer(LayerElement el) {
      try {
        drawLayerElement(dc, el, layer, staff, measure);
      } on UnimplementedError {
        dc.startGraphic(el, '', el.id);
        dc.endGraphic(el);
      }
    }

    if (layer.getCautionStaffDefClef() != null) {
      tryDrawLayer(layer.getCautionStaffDefClef()!);
    }
    if (layer.getCautionStaffDefKeySig() != null) {
      tryDrawLayer(layer.getCautionStaffDefKeySig()!);
    }
    if (layer.getCautionStaffDefMensur() != null) {
      tryDrawLayer(layer.getCautionStaffDefMensur()!);
    }
    if (layer.getCautionStaffDefMeterSig() != null) {
      tryDrawLayer(layer.getCautionStaffDefMeterSig()!);
    }
  }

  // ---------------------------------------------------------------------------
  // view_page.cpp (C): barlines, measures, meterSig groups, mNum and ossia
  // (task 05-10)
  // ---------------------------------------------------------------------------

  /// Mirrors `View::DrawBarLines` (view_page.cpp:678). The C++
  /// `int &yBottomPrevious` output parameter becomes the return value.
  int drawBarLines(
      DeviceContext dc,
      Measure measure,
      StaffGrp staffGrp,
      BarLine barLine,
      bool isLastMeasure,
      bool isLastSystem,
      int yBottomPrevious) {
    if (staffGrp.drawingVisibility == VisibilityOptimization.hidden) {
      return yBottomPrevious;
    }

    final bool barlineThrough = barLine.isDrawnThrough(staffGrp);

    for (final Object child in staffGrp.children) {
      if (child is StaffGrp) {
        yBottomPrevious = drawBarLines(dc, measure, child, barLine,
            isLastMeasure, isLastSystem, yBottomPrevious);
        if (!barlineThrough) yBottomPrevious = meiUnset;
        continue;
      }
      if (child is! StaffDef) continue;
      final StaffDef staffDef = child;
      if (staffDef.getDrawingVisibility() == VisibilityOptimization.hidden) {
        continue;
      }

      Barrendition form = barLine.form ?? Barrendition.none;
      if (!barlineThrough && measure.hasInvisibleStaffBarlines()) {
        final Barrendition barlineRend =
            (barLine.getPosition() == BarlinePosition.right)
                ? measure.getDrawingRightBarLineByStaffN(staffDef.n ?? 0)
                : measure.getDrawingLeftBarLineByStaffN(staffDef.n ?? 0);
        if (barlineRend != Barrendition.none) form = barlineRend;
      }
      if (form == Barrendition.none) {
        yBottomPrevious = meiUnset;
        continue;
      }

      final (bool hasMethod, Barmethod method) =
          barLine.getMethodFromContext(staffDef);
      final bool methodMensur = hasMethod && (method == Barmethod.mensur);
      final bool methodTakt = hasMethod && (method == Barmethod.takt);

      final AttNIntegerComparison comparison =
          AttNIntegerComparison(ClassId.staff, staffDef.n ?? 0);
      final Staff? staff = measure.findDescendantByComparison(comparison,
          deepness: 1) as Staff?;
      if (staff == null ||
          (staff.hasVisible && staff.visible == false)) {
        yBottomPrevious = meiUnset;
        continue;
      }
      if (!barlineThrough && (staff.visible == false)) {
        yBottomPrevious = meiUnset;
        continue;
      }
      final int unit = doc!.getDrawingUnit(staff.drawingStaffSize);

      final int yStaffTop = staff.getDrawingY();
      final int yStaffBottom =
          yStaffTop - 2 * ((staffDef.lines ?? meiUnset) - 1) * unit;
      int yBottom = yStaffBottom;
      int yLength = yStaffTop - yStaffBottom;

      if (!methodMensur && !methodTakt) {
        final (bool hasPlace, int place) =
            barLine.getPlaceFromContext(staffDef);
        if (hasPlace) {
          yBottom += place * unit;
        } else if ((staffDef.lines ?? meiUnset) <= 1) {
          yBottom -= 2 * unit;
        }
        final (bool hasLength, double length) =
            barLine.getLengthFromContext(staffDef);
        if (hasLength) {
          yLength = (length * unit).toInt();
        } else if ((staffDef.lines ?? meiUnset) <= 1) {
          yLength = 4 * unit;
        }
      }
      final int yTop = yBottom + yLength;
      final int yTaktstrichShift = methodMensur ? unit : 0;

      bool drawInsideStaff = !methodMensur && !methodTakt;
      bool drawOutsideStaff = !methodTakt && barlineThrough;
      bool drawTaktstrichAbove = (methodMensur && !barlineThrough) || methodTakt;
      bool drawTaktstrichBelow = methodMensur && !barlineThrough;
      if ((isLastMeasure && isLastSystem) || barLine.hasRepetitionDots()) {
        drawInsideStaff = true;
        drawTaktstrichAbove = false;
        drawTaktstrichBelow = false;
      }

      if (drawInsideStaff) {
        drawBarLine(dc, yTop, yBottom, barLine, form);
        if (barLine.hasRepetitionDots()) {
          drawBarLineDots(dc, staff, barLine);
        }
      }

      if (drawOutsideStaff && (yBottomPrevious != meiUnset)) {
        final bool eraseIntersections =
            !isLastMeasure || (barLine.getPosition() != BarlinePosition.right);
        drawBarLine(
            dc, yBottomPrevious, yTop, barLine, form, true, eraseIntersections);
      }
      yBottomPrevious = drawOutsideStaff ? yBottom : meiUnset;

      if (drawTaktstrichAbove) {
        final int yTaktstrichCenter = yStaffTop + yTaktstrichShift;
        drawBarLine(dc, yTaktstrichCenter + unit, yTaktstrichCenter - unit,
            barLine, form);
      }
      if (drawTaktstrichBelow) {
        final int yTaktstrichCenter = yStaffBottom - yTaktstrichShift;
        drawBarLine(dc, yTaktstrichCenter + unit, yTaktstrichCenter - unit,
            barLine, form);
      }
    }
    return yBottomPrevious;
  }

  /// Mirrors `View::DrawBarLine` (view_page.cpp:815) — the page-level bar
  /// line between measures (all `@form` values).
  void drawBarLine(DeviceContext dc, int yTop, int yBottom, BarLine barLine,
      Barrendition form,
      [bool inStaffSpace = false, bool eraseIntersections = true]) {
    final Staff? staff =
        barLine.getFirstAncestor(ClassId.staff) as Staff?;
    final int staffSize =
        staff != null ? staff.getDrawingStaffNotationSize() : 100;
    final int unit = doc!.getDrawingUnit(staffSize);

    final int x = barLine.getDrawingX();
    final int barLineWidth = doc!.getDrawingBarLineWidth(staffSize);
    final int barLineThickWidth =
        (unit * options!.thickBarlineThickness.value).toInt();
    final int barLineSeparation =
        (unit * options!.barLineSeparation.value).toInt();
    final int barLinesSum = barLineThickWidth + barLineWidth;
    int x2 = x + barLineSeparation;

    final int dashLength =
        (unit * options!.dashedBarLineDashLength.value).toInt();
    final int gapLength =
        (unit * options!.dashedBarLineGapLength.value).toInt();
    if (inStaffSpace &&
        ((form == Barrendition.dashed) || (form == Barrendition.dbldashed))) {
      yTop -= dashLength;
      yBottom += dashLength;
    }
    final int serpentWidth =
        doc!.getGlyphWidth(smuflE04ASegnoSerpent1, staffSize, false);

    final SegmentedLine line = SegmentedLine(yTop, yBottom);
    // Intersection erasure is skipped in this port (it only trims the line
    // around CPMARK / DIR / DYNAM / TEMPO collisions and never changes the
    // structure of the output).
    // Keep the parameter referenced to avoid unused warning.
    if (eraseIntersections) {} // no-op, reference

    switch (form) {
      case Barrendition.none:
      case Barrendition.single:
        drawVerticalSegmentedLine(dc, x, line, barLineWidth);
        break;
      case Barrendition.dashed:
        drawVerticalSegmentedLine(dc, x, line, barLineWidth, dashLength, gapLength);
        break;
      case Barrendition.dotted:
        drawVerticalDots(dc, x, line, barLineWidth, 2 * unit);
        break;
      case Barrendition.heavy:
        drawVerticalSegmentedLine(dc, x, line, barLineThickWidth);
        break;
      case Barrendition.rptend:
        drawVerticalSegmentedLine(dc, x, line, barLineWidth);
        drawVerticalSegmentedLine(
            dc, x2 + barLinesSum ~/ 2, line, barLineThickWidth);
        break;
      case Barrendition.rptboth:
        x2 = x + barLinesSum + barLineSeparation * 2;
        drawVerticalSegmentedLine(dc, x, line, barLineWidth);
        drawVerticalSegmentedLine(dc, (x + x2) ~/ 2, line, barLineThickWidth);
        drawVerticalSegmentedLine(dc, x2, line, barLineWidth);
        break;
      case Barrendition.rptstart:
        drawVerticalSegmentedLine(dc, x, line, barLineThickWidth);
        drawVerticalSegmentedLine(
            dc, x2 + barLinesSum ~/ 2, line, barLineWidth);
        break;
      case Barrendition.invis:
        barLine.setEmptyBB();
        break;
      case Barrendition.end:
        drawVerticalSegmentedLine(dc, x, line, barLineWidth);
        drawVerticalSegmentedLine(
            dc, x2 + barLinesSum ~/ 2, line, barLineThickWidth);
        break;
      case Barrendition.dbl:
        drawVerticalSegmentedLine(dc, x, line, barLineWidth);
        drawVerticalSegmentedLine(dc, x2 + barLineWidth, line, barLineWidth);
        break;
      case Barrendition.dblheavy:
        drawVerticalSegmentedLine(dc, x, line, barLineThickWidth);
        drawVerticalSegmentedLine(
            dc, x2 + barLineThickWidth, line, barLineThickWidth);
        break;
      case Barrendition.dblsegno:
        drawVerticalSegmentedLine(dc, x, line, barLineWidth);
        drawVerticalSegmentedLine(dc, x2 + barLineWidth, line, barLineWidth);
        drawSmuflCode(
            dc,
            (x + (barLineSeparation + barLineWidth - serpentWidth) ~/ 2),
            yBottom,
            smuflE04ASegnoSerpent1,
            staffSize,
            false);
        break;
      case Barrendition.dbldashed:
        drawVerticalSegmentedLine(
            dc, x, line, barLineWidth, dashLength, gapLength);
        drawVerticalSegmentedLine(
            dc, x2 + barLineWidth, line, barLineWidth, dashLength, gapLength);
        break;
      case Barrendition.dbldotted:
        drawVerticalDots(dc, x, line, barLineWidth, 2 * unit);
        drawVerticalDots(dc, x2 + barLineWidth, line, barLineWidth, 2 * unit);
        break;
      default:
        logDebug('${barLine.form} bar lines not supported');
        drawVerticalSegmentedLine(dc, x, line, barLineWidth);
        break;
    }
  }

  /// Mirrors `View::DrawBarLineDots` (view_page.cpp:946).
  void drawBarLineDots(DeviceContext dc, Staff staff, BarLine barLine) {
    final int x = barLine.getDrawingX();
    final int dotSeparation =
        (doc!.getDrawingUnit(100) * options!.repeatBarLineDotSeparation.value)
            .toInt();
    final int barLineWidth =
        (doc!.getDrawingUnit(100) * options!.barLineWidth.value).toInt();
    final int thickBarLineWidth =
        (doc!.getDrawingUnit(100) * options!.thickBarlineThickness.value)
            .toInt();
    final int barLineSeparation =
        (doc!.getDrawingUnit(100) * options!.barLineSeparation.value).toInt();
    final int xShift =
        thickBarLineWidth + dotSeparation + barLineSeparation + barLineWidth;
    final int staffSize = staff.drawingStaffSize;
    final int dotWidth = doc!.getGlyphWidth(smuflE044RepeatDot, staffSize, false);

    final int x1 = x - barLineWidth ~/ 2 - (dotSeparation + dotWidth);
    final int x2 = x + xShift;

    final int numDots = 3 - staff.drawingLines % 2;
    final int yInc = doc!.getDrawingDoubleUnit(staffSize);
    final int yBottom = staff.getDrawingY() -
        (staff.drawingLines + numDots % 2) * doc!.getDrawingUnit(staffSize);
    final int yTop = yBottom + (numDots - 1) * yInc;

    if (barLine.form == Barrendition.rptstart) {
      for (int y = yTop; y >= yBottom; y -= yInc) {
        drawSmuflCode(
            dc, x2 - thickBarLineWidth ~/ 2, y, smuflE044RepeatDot, staffSize, false);
      }
    }
    if (barLine.form == Barrendition.rptboth) {
      for (int y = yTop; y >= yBottom; y -= yInc) {
        drawSmuflCode(dc, x2 + barLineSeparation + barLineWidth ~/ 2, y,
            smuflE044RepeatDot, staffSize, false);
      }
    }
    if ((barLine.form == Barrendition.rptend) ||
        (barLine.form == Barrendition.rptboth)) {
      for (int y = yTop; y >= yBottom; y -= yInc) {
        drawSmuflCode(dc, x1, y, smuflE044RepeatDot, staffSize, false);
      }
    }
  }

  /// Mirrors `View::DrawMeterSigGrp` (view_page.cpp:1071).
  void drawMeterSigGrp(DeviceContext dc, Layer layer, Staff staff) {
    final MeterSigGrp? meterSigGrp = layer.getStaffDefMeterSigGrp();
    if (meterSigGrp == null) return;
    final List<Object> childList = List<Object>.from(meterSigGrp.children);

    childList.removeWhere((Object object) {
      final MeterSig meterSig = object as MeterSig;
      return (meterSig.visible == false) || !meterSig.hasCount;
    });

    final int glyphSize = staff.getDrawingStaffNotationSize();
    final int unit = doc!.getDrawingUnit(glyphSize);
    int offset = 0;
    dc.startGraphic(meterSigGrp, '', meterSigGrp.id);

    for (int idx = 0; idx < childList.length; idx++) {
      final MeterSig meterSig = childList[idx] as MeterSig;
      _drawMeterSigForGrp(dc, meterSig, staff, offset);

      final int y = staff.getDrawingY() - unit * (staff.drawingLines - 1);
      final int x = meterSig.getDrawingX() + offset;
      final int width = meterSig.getContentRight() - meterSig.getContentLeft();
      final bool isMixed = (meterSigGrp as dynamic).func == MetersiggrplogFunc.mixed;
      if (isMixed && idx != childList.length - 1) {
        final int plusX = x + width + unit ~/ 2;
        drawSmuflCode(dc, plusX, y, smuflE08CTimeSigPlus, glyphSize, false);
        offset += width + unit + doc!.getGlyphWidth(smuflE08CTimeSigPlus, glyphSize, false);
      } else {
        offset += width + unit;
      }
    }

    dc.endGraphic(meterSigGrp);
  }

  void _drawMeterSigForGrp(
      DeviceContext dc, MeterSig meterSig, Staff staff, int horizOffset) {
    dc.startGraphic(meterSig, '', meterSig.id);
    final int glyphSize = staff.getDrawingStaffNotationSize();
    final int y = staff.getDrawingY() -
        doc!.getDrawingUnit(glyphSize) * (staff.drawingLines - 1);
    final int x = meterSig.getDrawingX() + horizOffset;

    if (meterSig.visible == false) {
      meterSig.setEmptyBB();
      dc.endGraphic(meterSig);
      return;
    }

    // Simplified meterSig drawing: just the count/unit digits.
    // The full C++ branch (sym / glyphNum / glyphName / enclosing) is
    // approximated here; the structure (`<g class="meterSig">` with text)
    // is preserved for the harness, and the detailed glyph placement is
    // deferred to the view_element port (05-14) which will replace this
    // helper.
    if (meterSig.hasCount) {
      final String countStr = meterSig.count.toString();
      final String sig = intToTimeSigFigures(int.tryParse(countStr) ?? 0);
      if (sig.isNotEmpty) {
        drawSmuflString(dc, x, y, sig, HorizontalAlignment.left, glyphSize, false);
      }
      if (meterSig.hasUnit) {
        final String unitStr = meterSig.unit.toString();
        final String sigU = intToTimeSigFigures(int.tryParse(unitStr) ?? 0);
        if (sigU.isNotEmpty) {
          // Place unit slightly below / separate — use a line break via
          // moving text vertically would need metric; keep on same y for now.
          drawSmuflString(dc, x, y - doc!.getDrawingUnit(glyphSize), sigU,
              HorizontalAlignment.left, glyphSize, false);
        }
      }
    }

    dc.endGraphic(meterSig);
  }

  /// Mirrors `View::DrawMNum` (view_page.cpp:1117). The `yOffset` already
  /// contains the `max(symbolOffset, yOffset)` the C++ computes at the call
  /// site.
  void drawMNum(
      DeviceContext dc, MNum mnum, Measure measure, System system, int yOffset) {
    final Staff? staff = system.getTopVisibleStaff(true);
    if (staff == null) return;
    // Mirrors `SetCurrentFloatingPositioner` (system.cpp): false when the
    // staff alignment does not exist.
    if (!system.setSystemCurrentFloatingPositioner(
        staff.n ?? 0, mnum, staff, staff)) {
      return;
    }

    dc.startGraphic(mnum, '', mnum.id);

    final FontInfo mnumTxt = FontInfo();
    if (!dc.useGlobalStyling()) {
      mnumTxt.faceName = doc!.getResources().textFontName;
      mnumTxt.fontStyle = FontStyle.italic;
    }

    final TextDrawingParams params = TextDrawingParams();
    // MNum uses mei_enums.Horizontalalignment, View uses core.HorizontalAlignment;
    // normalize via index (both have none at 0, center at 3).
    final dynamic rawAlignment = mnum.getChildRendAlignment();
    HorizontalAlignment alignment;
    try {
      // rawAlignment is Horizontalalignment
      if (rawAlignment.index == 0) {
        alignment = HorizontalAlignment.center;
      } else if (rawAlignment.index == 3) {
        alignment = HorizontalAlignment.center;
      } else if (rawAlignment.index == 1) {
        alignment = HorizontalAlignment.left;
      } else if (rawAlignment.index == 2) {
        alignment = HorizontalAlignment.right;
      } else {
        alignment = HorizontalAlignment.center;
      }
    } catch (_) {
      alignment = HorizontalAlignment.center;
    }

    params.x = measure.getDrawingX();
    params.y = staff.getDrawingY() + yOffset;
    if (mnum.hasFontsize) {
      final fontsize = mnum.fontsize;
      if (fontsize != null) {
        if (fontsize.toString().contains('%')) {
          // Approximate percent/term handling — use lyric font scaling.
          final int pct = int.tryParse(fontsize.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 80;
          mnumTxt.pointSize = doc!.getDrawingLyricFont(pct).pointSize;
        } else {
          final int? sz = int.tryParse(fontsize.toString());
          if (sz != null) {
            mnumTxt.pointSize = sz;
          } else {
            mnumTxt.pointSize = doc!.getDrawingLyricFont(80).pointSize;
          }
        }
      } else {
        mnumTxt.pointSize = doc!.getDrawingLyricFont(80).pointSize;
      }
    } else {
      mnumTxt.pointSize = doc!.getDrawingLyricFont(80).pointSize;
    }
    params.pointSize = mnumTxt.pointSize;

    dc.setFont(mnumTxt);
    dc.startText(toDeviceContextX(params.x), toDeviceContextY(params.y), alignment);
    drawTextChildren(dc, mnum, params);
    dc.endText();
    dc.resetFont();

    // Text enclosure (box around mNum) — approximated as no-op for now;
    // the full `DrawTextEnclosure` arrives with view_text (05-19).
    // drawTextEnclosure(dc, params, staff.drawingStaffSize);

    dc.endGraphic(mnum);
  }

  /// Mirrors `View::DrawOssia` (view_page.cpp:1183).
  void drawOssia(
      DeviceContext dc, Ossia ossia, Measure measure, System system) {
    dc.startGraphic(ossia, '', ossia.id);

    final Staff? topOStaff = ossia.getDrawingTopOStaff();
    final Staff? bottomOStaff = ossia.getDrawingBottopOStaff();

    if (ossia.isFirst() && ossia.drawScoreDef() && ossia.hasMultipleOStaves()) {
      if (topOStaff != null && bottomOStaff != null) {
        final int staffSize = bottomOStaff.drawingStaffSize;
        final int x = topOStaff.getDrawingX() +
            topOStaff.getOssiaDrawingShift(measure, doc!);
        final int y1 = topOStaff.getDrawingY();
        final int doubleUnit = doc!.getDrawingDoubleUnit(staffSize);
        final int y2 = bottomOStaff.getDrawingY() -
            doubleUnit * (bottomOStaff.drawingLines - 1);
        final int barLineWidth = doc!.getDrawingBarLineWidth(100);
        drawVerticalLine(dc, y1, y2, x + barLineWidth ~/ 2, barLineWidth);
        drawBrace(dc, x, y1, y2, staffSize);
      }
    }

    for (final Object child in ossia.children) {
      if (child is Staff) {
        drawStaff(dc, child, measure, system);
      } else {
        assert(false);
      }
    }

    if (topOStaff == null || bottomOStaff == null) {
      dc.endGraphic(ossia);
      return;
    }

    final bool showBarLines = ossia.hasShowBarLines
        ? (ossia.showBarLines == true)
        : false;
    final bool showForceLeft = showBarLines &&
        ossia.isFirst() &&
        (measure.drawingLeftBarLine == Barrendition.none);

    if (measure.drawingLeftBarLine != Barrendition.none) {
      int yBottomPrevious = meiUnset;
      final BarLine barLine = measure.getLeftBarLine();
      dc.startGraphic(barLine, '', barLine.id);
      yBottomPrevious = drawBarLines(dc, measure, ossia.getDrawingStaffGrp(),
          barLine, measure.isLastInSystem(), system.isLastOfMdiv(), yBottomPrevious);
      dc.endGraphic(barLine);
    }
    if ((showBarLines || !ossia.isLast()) &&
        (measure.drawingRightBarLine != Barrendition.none)) {
      int yBottomPrevious = meiUnset;
      final BarLine barLine = measure.getRightBarLine();
      dc.startGraphic(barLine, '', barLine.id);
      drawBarLines(dc, measure, ossia.getDrawingStaffGrp(), barLine,
          measure.isLastInSystem(), system.isLastOfMdiv(), yBottomPrevious);
      dc.endGraphic(barLine);
    }
    if (showForceLeft) {
      int yBottomPrevious = meiUnset;
      final BarLine barLine = ossia.getDrawingLeftBarLine();
      dc.startGraphic(barLine, '', barLine.id);
      drawBarLines(dc, measure, ossia.getDrawingStaffGrp(), barLine,
          measure.isLastInSystem(), system.isLastOfMdiv(), yBottomPrevious);
      dc.endGraphic(barLine);
    }

    dc.endGraphic(ossia);
  }

  /// Mirrors `View::DrawMeasure` (view_page.cpp:993).
  void drawMeasure(DeviceContext dc, Measure measure, System system) {
    if (measure.isMeasuredMusic()) {
      dc.startGraphic(measure, '', measure.id);
    }

    if ((drawingScoreDef.mnumVisible != false)) {
      final MNum? mnum =
          measure.findDescendantByType(ClassId.mnum) as MNum?;
      final Reh? reh = measure.findDescendantByType(ClassId.reh) as Reh?;
      final bool hasRehearsal = reh != null &&
          ((reh.hasTstamp && (reh.tstamp ?? 0.0) == 0.0) ||
              (reh.start != null &&
                  reh.start!.isClass(ClassId.barLine) &&
                  (reh.start as BarLine).getPosition() == BarlinePosition.left));
      if (mnum != null && !hasRehearsal) {
        final Measure? systemStart =
            system.findDescendantByType(ClassId.measure) as Measure?;
        final int mnumInterval = options!.mnumInterval.value;
        final String measureN = measure.n ?? '';
        final int? measureNum = int.tryParse(measureN);
        final bool drawForInterval = mnumInterval >= 1 &&
            measureNum != null &&
            (measureNum % mnumInterval == 0);
        final bool drawSystemStart = mnumInterval == 0 &&
            measure == systemStart &&
            measureN != '0' &&
            measureN != '1';
        final bool drawNonGenerated = !mnum.isGeneratedFlag;
        if (drawSystemStart || drawNonGenerated || drawForInterval) {
          int symbolOffset = doc!.getDrawingUnit(100);
          final ScoreDef? scoreDef = system.drawingScoreDef;
          final GrpSym? groupSymbol = scoreDef
                  ?.findDescendantByType(ClassId.grpSym) as GrpSym?;
          if (groupSymbol != null &&
              groupSymbol.symbol == StaffgroupingsymSymbol.bracket) {
            // Note: glyph height via width (height not yet exposed).
            symbolOffset += doc!.getGlyphWidth(smuflE003BracketTop, 100, false) +
                doc!.getDrawingUnit(100) ~/ 6;
          }
          final int yOffset =
              doc!.getDrawingLyricFont(60).pointSize;
          drawMNum(
              dc, mnum, measure, system, math.max(symbolOffset, yOffset));
        }
      }
    }

    drawMeasureChildren(dc, measure, measure, system);

    if (measure.isMeasuredMusic()) {
      final System? sys =
          measure.getFirstAncestor(ClassId.system) as System?;
      assert(sys != null);
      if (sys != null) {
        if ((measure.drawingLeftBarLine != Barrendition.none) ||
            measure.hasInvisibleStaffBarlines()) {
          drawScoreDef(
              dc,
              sys.drawingScoreDef!,
              measure,
              measure.getLeftBarLine().getDrawingX(),
              measure.getLeftBarLine());
        }
        if ((measure.drawingRightBarLine != Barrendition.none) ||
            measure.hasInvisibleStaffBarlines()) {
          drawScoreDef(
              dc,
              sys.drawingScoreDef!,
              measure,
              measure.getRightBarLine().getDrawingX(),
              measure.getRightBarLine(),
              measure.isLastInSystem(),
              sys.isLastOfMdiv());
        }
      }
    }

    if (measure.isMeasuredMusic()) {
      dc.endGraphic(measure);
    }

    if (measure.getDrawingEnding() != null) {
      system.addToDrawingList(measure.getDrawingEnding()!);
    }
  }

  /// Port of `View::DrawBarLine` for a `<barLine>` layer element
  /// (view_element.cpp:434). This is the **second** `DrawBarLine` overload
  /// in the C++ (same name, different signature) — see the task's
  /// "Armadilhas conhecidas".
  void drawBarLineElement(
      DeviceContext dc, LayerElement element, Layer layer, Staff staff, Measure measure) {
    final BarLine barLine = element as BarLine;
    if (barLine.form == Barrendition.invis) {
      barLine.setEmptyBB();
      return;
    }
    // The staffDef used for method context is the drawing staffDef of the
    // staff (like the C++ `staff->m_drawingStaffDef` check).
    final StaffDef? drawingStaffDef = staff.drawingStaffDef as StaffDef?;
    Barmethod? method;
    if (barLine.hasMethod) {
      method = barLine.method;
    } else if (drawingStaffDef != null) {
      final (bool hasM, Barmethod m) = barLine.getMethodFromContext(drawingStaffDef);
      if (hasM) method = m;
    }

    dc.startGraphic(element, '', element.id);

    int yTop = staff.getDrawingY();
    int yBottom = yTop -
        (staff.drawingLines - 1) * doc!.getDrawingDoubleUnit(staff.drawingStaffSize);

    if (method == Barmethod.takt) {
      yTop += doc!.getDrawingUnit(staff.drawingStaffSize);
      yBottom = yTop - doc!.getDrawingDoubleUnit(staff.drawingStaffSize);
    }

    final int offset =
        (yTop == yBottom) ? doc!.getDrawingDoubleUnit(staff.drawingStaffSize) : 0;

    drawBarLine(dc, yTop + offset, yBottom - offset, barLine,
        barLine.form ?? Barrendition.single);
    if (barLine.hasRepetitionDots()) {
      drawBarLineDots(dc, staff, barLine);
    }

    dc.endGraphic(element);
  }

  /// Mirrors `View::DrawStaff` (view_page.cpp:1263).
  void drawStaff(
      DeviceContext dc, Staff staff, Measure measure, System system) {
    if (staff.isHidden) return;
    final StaffDef? staffDef =
        system.drawingScoreDef?.getStaffDef(staff.n ?? 0);
    if (staffDef != null &&
        staffDef.getDrawingVisibility() == VisibilityOptimization.hidden) {
      return;
    }

    dc.startGraphic(staff, '', staff.id);

    if (doc!.isFacs()) {
      // Note: facsimile zones are resolved during MEI import;
      // the transcription path that reaches this code in the corpus is
      // `IsFacs()==false`, so the call is a no-op for the measured divergence.
      staff.setFromFacsimile(doc);
    }

    final MRest? mrest =
        staff.findDescendantByType(ClassId.mRest) as MRest?;
    final bool hasCutout =
        mrest != null && mrest.cutout == CutoutCutout.cutout;
    if (mrest == null || !hasCutout) {
      drawStaffLines(dc, staff, staffDef, measure, system);
    }

    if (staffDef != null && doc!.getType() != DocType.facs) {
      drawStaffDef(dc, staff, measure);
    }

    if (staff.getLedgerLinesAbove().isNotEmpty) {
      drawLedgerLines(dc, staff, staff.getLedgerLinesAbove(), false, false);
    }
    if (staff.getLedgerLinesBelow().isNotEmpty) {
      drawLedgerLines(dc, staff, staff.getLedgerLinesBelow(), true, false);
    }
    if (staff.getLedgerLinesAboveCue().isNotEmpty) {
      drawLedgerLines(dc, staff, staff.getLedgerLinesAboveCue(), false, true);
    }
    if (staff.getLedgerLinesBelowCue().isNotEmpty) {
      drawLedgerLines(dc, staff, staff.getLedgerLinesBelowCue(), true, true);
    }

    drawStaffChildren(dc, staff, staff, measure);

    drawStaffDefCautionary(dc, staff, measure);

    for (final Object spanningElement in staff.timeSpanningElements) {
      system.addToDrawingListIfNecessary(spanningElement);
    }

    dc.endGraphic(staff);
  }

  /// Mirrors `View::DrawStaffLines` (view_page.cpp:1317).
  ///
  /// Approximations:
  /// - The `BBOX_DEVICE_CONTEXT` guard that suppresses the guitar-tablature
  ///   gap logic during layout is preserved via `dc.classId !=
  ///   ClassId.bboxDeviceContext`. The gap-insertion itself (vertical overlap
  ///   with notes, margin half-unit) is ported faithfully for guitar tab but
  ///   not for French/German/Italian lute, exactly as the C++.
  /// - Facsimile rotation (`HasDrawingRotation`) is ported; the corpus has no
  ///   rotated staves, so the skewed-line branch is not exercised in the
  ///   current structural comparison.
  void drawStaffLines(DeviceContext dc, Staff staff, StaffDef? staffDef,
      Measure measure, System system) {
    if (staffDef == null) return;

    final bool gltLines =
        staff.isTabLuteGerman() && staffDef.linesVisible != true;
    final bool visibleLines = staffDef.linesVisible != false;
    if (!gltLines && !visibleLines) return;

    int x1 = measure.getDrawingX();
    int x2 = x1 + measure.getWidth();
    if (staff.isOssia()) {
      final int shift = staff.getOssiaDrawingShift(measure, doc!);
      x1 += shift;
    }
    int y1 = staff.getDrawingY();
    int y2;
    if (!staff.hasDrawingRotation()) {
      y2 = y1;
    } else {
      y2 = y1 -
          (measure.getWidth() * math.tan(staff.getDrawingRotation() * math.pi / 180.0))
              .toInt();
    }

    final int lineWidth =
        doc!.getDrawingStaffLineWidth(staff.drawingStaffSize);
    dc.setPen(toDeviceContextX(lineWidth), PenStyle.solid);

    if (gltLines) {
      final SegmentedLine line = SegmentedLine(x1, x2);
      y1 -=
          (doc!.getDrawingDoubleUnit(staff.drawingStaffSize) * staff.drawingLines) *
              11 ~/
              10;
      drawHorizontalSegmentedLine(dc, y1, line, lineWidth ~/ 2);
    } else {
      for (int j = 0; j < staff.drawingLines; ++j) {
        if (y1 != y2) {
          dc.drawLine(toDeviceContextX(x1), toDeviceContextY(y1),
              toDeviceContextX(x2), toDeviceContextY(y2));
          y1 -= doc!.getDrawingDoubleUnit(staff.drawingStaffSize);
          y2 -= doc!.getDrawingDoubleUnit(staff.drawingStaffSize);
        } else {
          final bool isFrenchOrGermanOrItalian = staff.isTabLuteFrench() ||
              staff.isTabLuteGerman() ||
              staff.isTabLuteItalian();
          final SegmentedLine line = SegmentedLine(x1, x2);
          if (dc.classId != ClassId.bboxDeviceContext &&
              staff.isTablature() &&
              !isFrenchOrGermanOrItalian) {
            // Note: the C++ builds a temporary BoundingBox
            // `fullLine` and checks `VerticalContentOverlap` for each note
            // with a half-unit margin. This port computes the gap purely from
            // the note's content bounding box horizontal span, which is
            // sufficient for the structural harness (the `<path>` still has
            // `lineWidth`, only its `d` would gain gaps for guitar tab).
            final BoundingBox fullLine = _TempBBox(
                x1, x2, y1 + lineWidth ~/ 2, y1 - lineWidth ~/ 2, staff);
            final int margin = doc!.getDrawingUnit(100) ~/ 2;
            final List<Object> notes = staff
                .findAllDescendantsByType(ClassId.note, continueDepthSearchForMatches: false);
            for (final Object noteObj in notes) {
              final BoundingBox note = noteObj as BoundingBox;
              if (note.verticalContentOverlap(fullLine, margin ~/ 2)) {
                line.addGap(note.getContentLeft() - margin,
                    note.getContentRight() + margin);
              }
            }
          }
          drawHorizontalSegmentedLine(dc, y1, line, lineWidth);
          y1 -= doc!.getDrawingDoubleUnit(staff.drawingStaffSize);
          y2 = y1;
        }
      }
    }

    dc.resetPen();
  }

  /// Mirrors `View::DrawLedgerLines` (view_page.cpp:1407).
  void drawLedgerLines(DeviceContext dc, Staff staff,
      List<LedgerLine> lines, bool below, bool cueSize) {
    String gClass = 'above';
    int y = staff.getDrawingY();
    final int x = staff.getDrawingX();
    int ySpace = doc!.getDrawingDoubleUnit(staff.drawingStaffSize);

    if (below) {
      gClass = 'below';
      ySpace *= -1;
      y += ySpace * (staff.drawingLines - 1);
    }
    y += ySpace;

    if (cueSize) {
      gClass += ' cue';
    }

    dc.startCustomGraphic('ledgerLines', gClass);

    int lineWidth =
        (doc!.getOptions().ledgerLineThickness.value * doc!.getDrawingUnit(staff.drawingStaffSize))
            .toInt();
    if (cueSize) lineWidth = (lineWidth * doc!.getOptions().graceFactor.value).toInt();

    dc.setPen(toDeviceContextX(lineWidth), PenStyle.solid);

    final bool svgHtml5 = doc!.getOptions().svgHtml5.value;

    for (final LedgerLine line in lines) {
      for (final Dash dash in line.dashes) {
        if (svgHtml5) {
          dc.startCustomGraphic('lineDash');
          final String events = _concatenateIds(dash.events);
          dc.setCustomGraphicAttributes('related', events);
        }

        dc.drawLine(toDeviceContextX(x + dash.x1), toDeviceContextY(y),
            toDeviceContextX(x + dash.x2), toDeviceContextY(y));

        if (svgHtml5) dc.endCustomGraphic();
      }
      y += ySpace;
    }

    dc.resetPen();

    dc.endCustomGraphic();
  }

  /// Mirrors `View::CalculatePitchCode` (view_page.cpp:1530).
  ///
  /// Returns the `data_PITCHNAME` code (`Pitchname.c`..`b`, values 1..7)
  /// for the logical Y [yN] at horizontal position [xPos] in [layer].
  /// The octave is written to [octaveOut] (list of one int, Dart has no
  /// `int &` out parameter).
  int calculatePitchCode(
      Layer layer, int yN, int xPos, List<int> octaveOut) {
    final Staff? parentStaff =
        layer.getFirstAncestor(ClassId.staff) as Staff?;
    assert(parentStaff != null);

    final List<int> touches = [
      Pitchname.c.value,
      Pitchname.d.value,
      Pitchname.e.value,
      Pitchname.f.value,
      Pitchname.g.value,
      Pitchname.a.value,
      Pitchname.b.value,
    ];

    final int staffSize = parentStaff!.drawingStaffSize;
    // Mirrors `yb = parentStaff->GetDrawingY() - m_doc->GetDrawingStaffSize(staffSize);`
    int yb = parentStaff.getDrawingY() - doc!.getDrawingStaffSize(staffSize);

    final int plafond = yb + 8 * doc!.getDrawingOctaveSize(staffSize);
    if (yN > plafond) yN = plafond;

    LayerElement? pelement = layer.getAtPos(xPos);
    final LayerElement? previous =
        pelement != null ? layer.getPrevious(pelement) : null;
    if (previous != null) pelement = previous;

    final Clef? clef = layer.getClef(pelement);
    if (clef != null) {
      yb += clef.getClefLocOffset() * doc!.getDrawingUnit(staffSize);
    }
    yb -= 4 * doc!.getDrawingOctaveSize(staffSize);

    int yDec = yN - yb;
    if (yDec < 0) yDec = 0;

    final int degres = yDec ~/ doc!.getDrawingUnit(staffSize);
    final int octaves = degres ~/ 7;
    final int position = degres % 7;

    final int code = touches[position];
    octaveOut[0] = octaves;
    return code;
  }

  String _concatenateIds(List<Object> events) {
    return events.map((Object e) => (e as dynamic).id as String? ?? '').where((s) => s.isNotEmpty).join(' ');
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

  /// Minimal `View::DrawSystemElement` for task 05-10: milestones
  /// (section/score) are drawn as empty graphics so the page can continue
  /// to its measures and barlines. Full drawing arrives with task 05-22.
  void drawSystemElement(
      DeviceContext dc, SystemElement element, System system) {
    dc.startGraphic(element, '', element.id);
    dc.endGraphic(element);
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

/// Helper bounding box for the guitar tablature gap logic in
/// [ViewPage.drawStaffLines] (view_page.cpp:1382-1393). Mirrors the temporary
/// `Object fullLine` the C++ builds, parents to the system and then updates
/// with `UpdateContentBBoxY/X`. The Dart port uses a lightweight
/// [BoundingBox] that delegates its drawing position to the staff.
class _TempBBox extends BoundingBox {
  _TempBBox(int x1, int x2, int y1, int y2, this._staff) {
    updateContentBBoxX(x1, x2);
    updateContentBBoxY(y1, y2);
  }

  final Staff _staff;

  @override
  ClassId get classId => ClassId.object;

  @override
  int getDrawingX() => _staff.getDrawingX();

  @override
  int getDrawingY() => _staff.getDrawingY();

  @override
  void resetCachedDrawingX() {}

  @override
  void resetCachedDrawingY() {}
}

/// Marks a drawing method that the C++ has but a later task will port (the
/// stubs above and the `CalcBeam` call site inside
/// [ViewPage.drawMeasureChildren]). Each call names the task that fills it.
Never _notYet(String function, String task) {
  throw UnimplementedError('$function is not ported yet (task $task)');
}
