/// Port of `castofffunctor.h/cpp` — the functors that break a continuous
/// (single page / single system) document into systems and pages:
///
/// - [CastOffSystemsFunctor]: fills a page by adding systems with the
///   appropriate length
/// - [CastOffPagesFunctor]: fills a document by adding pages with the
///   appropriate length
/// - [CastOffEncodingFunctor]: casts off according to the encoded `<pb>` /
///   `<sb>` breaks
/// - [UnCastOffFunctor]: undoes the cast off for both pages and systems
///
/// The orchestration is provided by the Doc methods of doc.dart mirroring
/// `Doc::CastOffDocBase`, `Doc::CastOffEncodingDoc` and `Doc::UnCastOffDoc`.
///
/// Deviations from the C++:
/// - `ConvertToCastOffMensuralFunctor` is deferred with the mensural phase.
/// - `CastOffToSelectionFunctor` is deferred with the selection support.
/// - The measure drawing overflow (`Measure::GetDrawingOverflow`) requires
///   the rendered bounding boxes; it is 0 until the rendering phase, so the
///   "pending overflow" branch never triggers.
/// - The measure cached xRel (`Measure::GetCachedXRel`) is not ported (it is
///   filled by the render pass); the current `drawingXRel` is used instead.
library;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/functor.dart';
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Measure, Score, Staff;
import 'package:verovio_dart/src/model/doc.dart' show Page, Pages;
import 'package:verovio_dart/src/model/editorial_element.dart'
    show EditorialElement;
import 'package:verovio_dart/src/model/misc_elements_gen.dart'
    show Div, Ending, Pb, Sb;
import 'package:verovio_dart/src/model/floating_object.dart'
    show FloatingObject;
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef;
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show
        PageElement,
        PageMilestoneEnd,
        System,
        SystemElement,
        SystemMilestoneEnd;

// ---------------------------------------------------------------------------
// CastOffSystemsFunctor
// ---------------------------------------------------------------------------

/// This class fills a page by adding systems with the appropriate length
/// (mirrors `vrv::CastOffSystemsFunctor`). Adds all the pending objects when
/// reaching the end.
class CastOffSystemsFunctor extends DocFunctor {
  /// Creates the functor; [page] is the page the new systems are added to.
  /// When [smart] is set, encoded `<sb>` are used smartly (threshold based).
  CastOffSystemsFunctor(Page page, super.doc, this._smart) : _page = page;

  /// The system we are taking the content from (mirrors `m_contentSystem`).
  System? _contentSystem;

  /// The page we are adding the system to (mirrors `m_page`).
  final Page _page;

  /// The current system (mirrors `m_currentSystem`).
  System _currentSystem = System();

  /// The cumulated shift: drawingXRel of the first measure of the current
  /// system (mirrors `m_shift`).
  int _shift = 0;

  /// The system width (mirrors `m_systemWidth`).
  int _systemWidth = 0;

  /// The current scoreDef width (mirrors `m_currentScoreDefWidth`).
  int _currentScoreDefWidth = 0;

  /// The pending elements (ScoreDef, Endings, etc.) to be placed at the
  /// beginning of a system (mirrors `m_pendingElements`).
  final List<Object> _pendingElements = [];

  /// Indicates to smartly use encoded system breaks (mirrors `m_smart`).
  final bool _smart;

  /// The leftover system: last system with only one measure (mirrors
  /// `m_leftoverSystem`).
  System? _leftoverSystem;

  /// Retrieve the leftover system (mirrors `GetLeftoverSystem`).
  System? getLeftoverSystem() => _leftoverSystem;

  /// Set the system width (mirrors `SetSystemWidth`).
  void setSystemWidth(int width) => _systemWidth = width;

  @override
  FunctorCode visitDiv(Div div) {
    // If we have a previous Measure or Div in the System, add a new one.
    if ((_currentSystem.getChildCount(ClassId.measure) > 0) ||
        (_currentSystem.getChildCount(ClassId.div) > 0)) {
      _currentSystem = System();
      _page.addChild(_currentSystem);
    }

    div.moveItselfTo(_currentSystem);

    // Always add a System after a Div.
    _currentSystem = System();
    _page.addChild(_currentSystem);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitEditorialElement(EditorialElement editorialElement) {
    // Since the functor returns FUNCTOR_SIBLINGS we should never go lower
    // than the system children.
    assert(editorialElement.parent is System);

    // Special case where we use the Relinquish method. We want to move the
    // editorial element to the currentSystem. However, we cannot use
    // DetachChild from the contentSystem because this screws up the iterator.
    // Relinquish gives up the ownership of the element - the contentSystem
    // will be deleted afterwards.
    final Object? relinquished =
        _contentSystem!.relinquish(editorialElement.idx!);
    assert(relinquished != null);
    // Move as pending since we want it at the beginning of the system in case
    // of a system break coming.
    _pendingElements.add(relinquished!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitEnding(Ending ending) {
    // See visitEditorialElement for the Relinquish explanation.
    assert(ending.parent is System);

    final Object? relinquished = _contentSystem!.relinquish(ending.idx!);
    assert(relinquished != null);
    _pendingElements.add(relinquished!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    // Deviation: the cached horizontal layout values are not stored in this
    // port (the cache functors require the render pass); the current values
    // are used instead and the overflow is 0 without rendered bounding boxes.
    final int overflow = 0;
    final int width = measure.getWidth();
    final int drawingXRel = measure.getDrawingXRel();

    final Object? nextMeasure =
        _contentSystem!.getNextSibling(measure, ClassId.measure);
    final bool isLeftoverMeasure = (nextMeasure == null) &&
        doc.getOptions().breaksNoWidow.value &&
        (doc.getOptions().breaks.value != Breaks.encoded);

    if (_currentSystem.childCount > 0) {
      // We have overflowing content (dir, dynam, tempo) larger than 5 units,
      // keep it as pending. Never triggered headless (see deviation above).
      if (overflow > (doc.getDrawingUnit(100) * 5)) {
        final Object? relinquished = _contentSystem!.relinquish(measure.idx!);
        assert(relinquished != null);
        // Move as pending since we want it not to be broken with the next
        // measure.
        _pendingElements.add(relinquished!);
        // Continue.
        return FunctorCode.siblings;
      }
      // Break it if necessary.
      else if (drawingXRel + width + _currentScoreDefWidth - _shift >
          _systemWidth) {
        _currentSystem = System();
        _page.addChild(_currentSystem);
        _shift = drawingXRel;
        // If the last measure requires a separate system - mark that system
        // as leftover for the future CastOffPages call.
        if (isLeftoverMeasure) {
          _leftoverSystem = _currentSystem;
        }
        for (final Object pendingElement in _pendingElements) {
          if (pendingElement.isClass(ClassId.measure)) {
            final Measure firstPendingMeasure = pendingElement as Measure;
            // Deviation: GetCachedXRel is not ported; the current xRel is
            // used.
            _shift = firstPendingMeasure.getDrawingXRel();
            _leftoverSystem = null;
            // It has to be the first measure.
            break;
          }
        }
      }
    }

    // First add all pending objects.
    for (final Object pendingElement in _pendingElements) {
      _currentSystem.addChild(pendingElement);
    }
    _pendingElements.clear();

    // Special case where we use the Relinquish method (see above).
    final Object? relinquished = _contentSystem!.relinquish(measure.idx!);
    assert(relinquished != null);
    _currentSystem.addChild(relinquished!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitPageElement(PageElement pageElement) {
    pageElement.moveItselfTo(_page);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitPageMilestone(PageMilestoneEnd pageMilestoneEnd) {
    pageMilestoneEnd.moveItselfTo(_page);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSb(Sb sb) {
    if (_smart) {
      // Get the last measure of the currentSystem.
      final Object? lastChild =
          _currentSystem.getChild(_currentSystem.childCount - 1);
      final Measure? measure = lastChild is Measure ? lastChild : null;
      if (measure != null) {
        final int measureRightX =
            measure.getDrawingX() + measure.getWidth() - _shift;
        final double smartSbThresh = doc.getOptions().breaksSmartSb.value;
        if (measureRightX > _systemWidth * smartSbThresh) {
          // Use this system break.
          _currentSystem = System();
          _page.addChild(_currentSystem);
          _shift += measureRightX;
        }
      }
    }
    // Keep the <sb> in the internal MEI, even if we're not using it to break
    // the system.
    sb.moveItselfTo(_currentSystem);
    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    // Since the functor returns FUNCTOR_SIBLINGS we should never go lower
    // than the system children.
    assert(scoreDef.parent is System);

    // Special case where we use the Relinquish method (see above).
    final Object? relinquished = _contentSystem!.relinquish(scoreDef.idx!);
    assert(relinquished != null);
    // Move as pending since we want it at the beginning of the system in case
    // of a system break coming.
    _pendingElements.add(relinquished!);
    // This is not perfect since now the scoreDefWidth is the one of the
    // intermediate scoreDefs (and not the initial one). Also, the abbr label
    // (width) changes would not be taken into account.
    _currentScoreDefWidth =
        scoreDef.drawingWidth + _contentSystem!.getDrawingAbbrLabelsWidth();

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    // We are starting a new system we need to cast off.
    _contentSystem = system;
    // We also need to create a new target system and add it to the page.
    final System targetSystem = System();
    _page.addChild(targetSystem);
    _currentSystem = targetSystem;

    _shift = -system.getDrawingLabelsWidth();
    _currentScoreDefWidth =
        _page.drawingScoreDef.drawingWidth + system.getDrawingAbbrLabelsWidth();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemEnd(System system) {
    if (_pendingElements.isEmpty) return FunctorCode.continue_;

    // Otherwise add all pending objects.
    for (final Object pendingElement in _pendingElements) {
      _currentSystem.addChild(pendingElement);
    }
    _pendingElements.clear();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemElement(SystemElement systemElement) {
    // Since the functor returns FUNCTOR_SIBLINGS we should never go lower
    // than the system children.
    assert(systemElement.parent is System);

    // Special case where we use the Relinquish method (see above).
    final Object? relinquished = _contentSystem!.relinquish(systemElement.idx!);
    assert(relinquished != null);
    _pendingElements.add(relinquished!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystemMilestone(SystemMilestoneEnd systemMilestoneEnd) {
    // See visitEditorialElement for the Relinquish explanation.
    assert(systemMilestoneEnd.parent is System);

    final Object? relinquished =
        _contentSystem!.relinquish(systemMilestoneEnd.idx!);
    assert(relinquished != null);
    // End milestones are not added to the pending objects because we do not
    // want them to be placed at the beginning of the next system but only if
    // the pending object array is empty (otherwise it will mess up the MEI
    // tree).
    if (_pendingElements.isEmpty) {
      _currentSystem.addChild(relinquished!);
    } else {
      _pendingElements.add(relinquished!);
    }

    return FunctorCode.siblings;
  }
}

// ---------------------------------------------------------------------------
// CastOffPagesFunctor
// ---------------------------------------------------------------------------

/// This class fills a document by adding pages with the appropriate length
/// (mirrors `vrv::CastOffPagesFunctor`).
class CastOffPagesFunctor extends DocFunctor {
  /// Creates the functor; [contentPage] is the page the content is taken
  /// from, [currentPage] the page the content is added to.
  CastOffPagesFunctor(Page contentPage, super.doc, Page currentPage)
      : _contentPage = contentPage,
        _currentPage = currentPage;

  /// The page we are taking the content from (mirrors `m_contentPage`).
  final Page _contentPage;

  /// The current page (mirrors `m_currentPage`).
  Page _currentPage;

  /// Whether we are still casting off the first page (mirrors
  /// `m_firstCastOffPage`).
  bool _firstCastOffPage = true;

  /// The cumulated shift: drawingYRel of the first system of the current
  /// page (mirrors `m_shift`; [meiUnset] mirrors VRV_UNSET).
  int _shift = meiUnset;

  /// The page height (mirrors `m_pageHeight`).
  int _pageHeight = 0;

  /// Running element heights per score (mirrors `m_pgHeadHeight` etc.).
  int _pgHeadHeight = 0;
  int _pgFootHeight = 0;
  int _pgHead2Height = 0;
  int _pgFoot2Height = 0;

  /// The leftover system: last system with only one measure (mirrors
  /// `m_leftoverSystem`).
  System? _leftoverSystem;

  /// The pending elements (Mdiv, Score) to be placed at the beginning of a
  /// page (mirrors `m_pendingPageElements`).
  final List<Object> _pendingPageElements = [];

  /// Set the leftover system (mirrors `SetLeftoverSystem`).
  void setLeftoverSystem(System? system) => _leftoverSystem = system;

  /// Set the page height (mirrors `SetPageHeight`).
  void setPageHeight(int height) => _pageHeight = height;

  @override
  FunctorCode visitPageEnd(Object page) {
    if (_pendingPageElements.isEmpty) return FunctorCode.continue_;

    // Otherwise add all pending objects.
    for (final Object pendingElement in _pendingPageElements) {
      _currentPage.addChild(pendingElement);
    }
    _pendingPageElements.clear();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitPageElement(PageElement pageElement) {
    final Object? relinquished = _contentPage.relinquish(pageElement.idx!);
    assert(relinquished != null);
    // Move as pending since we want it at the beginning of the page in case
    // of a page break coming.
    _pendingPageElements.add(relinquished!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitPageMilestone(PageMilestoneEnd pageMilestoneEnd) {
    final Object? relinquished = _contentPage.relinquish(pageMilestoneEnd.idx!);
    assert(relinquished != null);
    // End milestones can be added to the page only if the pending list is
    // empty. Otherwise we are going to mess up the order.
    if (_pendingPageElements.isEmpty) {
      _currentPage.addChild(relinquished!);
    } else {
      _pendingPageElements.add(relinquished!);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitScore(Score score) {
    visitPageElement(score);

    _pgHeadHeight = score.drawingPgHeadHeight;
    _pgFootHeight = score.drawingPgFootHeight;
    _pgHead2Height = score.drawingPgHead2Height;
    _pgFoot2Height = score.drawingPgFoot2Height;

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    // Check if this is the first system.
    if (_shift == meiUnset) {
      _shift = system.getDrawingYRel();
    }

    final int systemMaxPerPage = doc.getOptions().systemMaxPerPage.value;
    final int systemChildCount = _currentPage.getChildCount(ClassId.system);
    if ((systemMaxPerPage > 0 && (systemMaxPerPage == systemChildCount)) ||
        ((systemChildCount > 0) &&
            (_shift - system.getDrawingYRel() + system.getHeight() >
                getAvailableDrawingHeight()))) {
      // If this is the last system in the list, it doesn't fit the page and
      // it's a leftover system (has just one measure) => add the system
      // content to the previous system.
      final Object? nextSystem =
          _contentPage.getNextSibling(system, ClassId.system);
      final Object? lastSystem = _currentPage.getLast(ClassId.system);
      if (nextSystem == null &&
          lastSystem != null &&
          identical(system, _leftoverSystem)) {
        for (final Object child in system.childrenForModification) {
          child.moveItselfTo(lastSystem);
        }
        return FunctorCode.siblings;
      }

      _currentPage = Page();
      final Pages? pages = doc.getPages();
      assert(pages != null);
      pages!.addChild(_currentPage);
      _shift = system.getDrawingYRel();
      _firstCastOffPage = false;
    }

    // First add all pending objects.
    for (final Object pendingElement in _pendingPageElements) {
      _currentPage.addChild(pendingElement);
    }
    _pendingPageElements.clear();

    // Special case where we use the Relinquish method. We want to move the
    // system to the currentPage. However, we cannot use DetachChild from the
    // contentPage because this screws up the iterator. Relinquish gives up
    // the ownership of the system - the contentPage itself will be deleted
    // afterwards.
    final Object? relinquished = _contentPage.relinquish(system.idx!);
    assert(relinquished != null);
    _currentPage.addChild(relinquished!);

    return FunctorCode.siblings;
  }

  /// Returns the available height for system drawing on the current page
  /// (mirrors `GetAvailableDrawingHeight`, castofffunctor.cpp:391).
  int getAvailableDrawingHeight() {
    final int pageHeadAndFootHeight = _firstCastOffPage
        ? (_pgHeadHeight + _pgFootHeight)
        : (_pgHead2Height + _pgFoot2Height);
    return _pageHeight - pageHeadAndFootHeight;
  }
}

// ---------------------------------------------------------------------------
// CastOffEncodingFunctor
// ---------------------------------------------------------------------------

/// This class casts off the document according to the encoding provided (pb
/// and sb) (mirrors `vrv::CastOffEncodingFunctor`).
class CastOffEncodingFunctor extends DocFunctor {
  /// Creates the functor; [currentPage] is the first page of the cast-off
  /// result (already added to the pages). When [usePages] is false only
  /// systems are broken (no new page per `<pb>`).
  CastOffEncodingFunctor(super.doc, Page currentPage, {bool usePages = true})
      : _currentPage = currentPage,
        _usePages = usePages;

  /// The current page (mirrors `m_currentPage`).
  Page _currentPage;

  /// The current system (mirrors `m_currentSystem`).
  System? _currentSystem;

  // Deviation: the C++ keeps a m_contentSystem member that is assigned but
  // never read; it is not ported.

  /// Indicates if we want to use the pageBreaks from the document (mirrors
  /// `m_usePages`).
  final bool _usePages;

  @override
  FunctorCode visitDiv(Div div) {
    assert(_currentSystem != null);
    div.moveItselfTo(_currentSystem!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitEditorialElement(EditorialElement editorialElement) {
    // Only move editorial elements that are a child of the system.
    if (editorialElement.parent != null &&
        editorialElement.parent!.isClass(ClassId.system)) {
      assert(_currentSystem != null);
      editorialElement.moveItselfTo(_currentSystem!);
    }

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitEnding(Ending ending) {
    assert(_currentSystem != null);
    ending.moveItselfTo(_currentSystem!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    assert(_currentSystem != null);
    measure.moveItselfTo(_currentSystem!);

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitPageElement(PageElement pageElement) {
    pageElement.moveItselfTo(_currentPage);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitPageMilestone(PageMilestoneEnd pageMilestoneEnd) {
    if (pageMilestoneEnd.start.isClass(ClassId.score)) {
      // This is the end of a score, which means that the current system has
      // to be added to the current page.
      assert(_currentSystem != null);
      _currentPage.addChild(_currentSystem!);
      _currentSystem = null;
    }

    pageMilestoneEnd.moveItselfTo(_currentPage);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitPb(Pb pb) {
    // We look if the current system has a pb or at least one measure, or the
    // current page has at least a system. If yes, we assume that the <pb> is
    // not the one at the beginning of the content. This is not very robust
    // but at least makes it work when rendering an <mdiv> that does not start
    // with a <pb> (which we cannot force).
    if ((_currentSystem!.getChildCount(ClassId.pb) > 0) ||
        (_currentSystem!.getChildCount(ClassId.measure) > 0) ||
        (_currentPage.getChildCount(ClassId.system) > 0)) {
      _currentPage.addChild(_currentSystem!);
      _currentSystem = System();
      if (_usePages) {
        _currentPage = Page();
        final Pages? pages = doc.getPages();
        assert(pages != null);
        pages!.addChild(_currentPage);
      }
    }

    assert(_currentSystem != null);
    pb.moveItselfTo(_currentSystem!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSb(Sb sb) {
    // We look if the current system has at least one measure - if yes, we
    // assume that the <sb> is not the one at the beginning of the content
    // (<mdiv>). This is not very robust but at least makes it work when
    // rendering an <mdiv> that does not start with a <pb> or a <sb> (which we
    // cannot enforce).
    if ((_currentSystem!.getChildCount(ClassId.measure) > 0) ||
        (_currentSystem!.getChildCount(ClassId.div) > 0)) {
      _currentPage.addChild(_currentSystem!);
      _currentSystem = System();
    }

    assert(_currentSystem != null);
    sb.moveItselfTo(_currentSystem!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitScoreDef(ScoreDef scoreDef) {
    assert(_currentSystem != null);
    scoreDef.moveItselfTo(_currentSystem!);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitStaff(Staff staff) {
    // Staff alignments must be reset, otherwise they would dangle whenever
    // they belong to a deleted system.
    staff.setAlignment(null);
    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    // We are starting a new system we need to cast off.
    // Create the new system but do not add it to the page yet. It will be
    // added when reaching a pb / sb or at the end of the score in
    // PageMilestoneEnd::VisitPageMilestone.
    assert(_currentSystem == null);
    _currentSystem = System();

    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitSystemElement(SystemElement systemElement) {
    assert(_currentSystem != null);
    systemElement.moveItselfTo(_currentSystem!);

    return FunctorCode.siblings;
  }
}

// ---------------------------------------------------------------------------
// UnCastOffFunctor
// ---------------------------------------------------------------------------

/// This class undoes the cast off for both pages and systems (mirrors
/// `vrv::UnCastOffFunctor`). It is used by Doc.unCastOffDoc for putting all
/// pages / systems continuously.
class UnCastOffFunctor extends Functor {
  UnCastOffFunctor(Page page) : _page = page;

  /// The page we are adding systems to (mirrors `m_page`).
  final Page _page;

  /// The system we are adding content to (mirrors `m_currentSystem`).
  System? _currentSystem;

  /// Indicates if we need to reset the horizontal layout cache (mirrors
  /// `m_resetCache`).
  bool _resetCache = true;

  /// Set the reset cache flag (mirrors `SetResetCache`).
  void setResetCache(bool resetCache) => _resetCache = resetCache;

  @override
  FunctorCode visitFloatingObject(FloatingObject floatingObject) {
    floatingObject.currentPositioner = null;
    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitMeasure(Measure measure) {
    // Deviation: ResetCachedXRel / ResetCachedWidth / ResetCachedOverflow
    // mirror the C++ horizontal layout cache which is not stored in this
    // port (see cast_off.dart deviations).
    logDebug(
        'UnCastOffFunctor: no cached horizontal layout to reset ($_resetCache)');
    return FunctorCode.continue_;
  }

  @override
  FunctorCode visitPageElement(PageElement pageElement) {
    pageElement.moveItselfTo(_page);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitPageMilestone(PageMilestoneEnd pageMilestoneEnd) {
    if (pageMilestoneEnd.start.isClass(ClassId.score)) {
      // This is the end of a score, which means that nothing else should be
      // added to the current system and we set it to NULL.
      assert(_currentSystem != null);
      _currentSystem = null;
    }

    pageMilestoneEnd.moveItselfTo(_page);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitScore(Score score) {
    visitPageElement(score);

    assert(_currentSystem == null);
    final System system = System();
    _currentSystem = system;
    _page.addChild(system);

    return FunctorCode.siblings;
  }

  @override
  FunctorCode visitSystem(System system) {
    // Just move all the content of the system to the continuous one. Use the
    // MoveChildrenFrom method that moves and relinquishes them (see
    // Object::Relinquish).
    _currentSystem!.moveChildrenFrom(system);

    return FunctorCode.continue_;
  }
}
