/// Port of `textlayoutelement.h`, `textelement.h` and `runningelement.h`
/// — the base classes of the text/running element families.
library;

import 'dart:math' as math;

import 'package:verovio_dart/src/core/attdef.dart' show HorizontalAlignment;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show
        Enclosure,
        Fontsizeterm,
        Horizontalalignment,
        Textrendition,
        Verticalalignment;
import 'package:verovio_dart/src/model/atts/mei_values.dart' show FontSize;
import 'package:verovio_dart/src/model/misc_elements_gen.dart'
    show Fig, Num, Rend, Svg, Text;
import 'package:verovio_dart/src/model/object.dart';

/// Mirrors `vrv::TextLayoutElement`.
class TextLayoutElement extends Object with ObjectListInterface, AttTyped {
  TextLayoutElement([ClassId classId = ClassId.textLayoutElement]) {
    assignClassId(classId);
    reset();
  }

  /// Stored the top `rend` or `fig` with the 9 possible positioning
  /// combinations, from top-left to bottom-right (going left to right first)
  /// Mirrors `m_cells[9]` (textlayoutelement.h:130).
  final List<List<TextElement>> _cells =
      List.generate(9, (_) => <TextElement>[]);

  /// Mirrors `m_drawingScalingPercent[3]` (textlayoutelement.h:135).
  final List<int> _drawingScalingPercent = [100, 100, 100];

  @override
  String get className => '[MISSING]';

  /// Port of `TextLayoutElement::Reset` (textlayoutelement.cpp:37).
  @override
  void reset() {
    super.reset();
    type = null;
    // The C++ Reset does not clear cells or scaling, but the Dart port
    // initializes scaling to 100 on construction; running elements reset it
    // explicitly via ResetDrawingScaling.
  }

  /// Port of `TextLayoutElement::IsSupportedChild` (textlayoutelement.cpp:43).
  @override
  bool isSupportedChild(ClassId classId) {
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Port of `TextLayoutElement::FilterList` (textlayoutelement.cpp:56).
  @override
  void filterList(List<Object> childList) {
    // Keep only figs and top level rend elements.
    childList.removeWhere((Object object) {
      if (object.classId == ClassId.rend) {
        return object.getFirstAncestor(ClassId.rend) != null;
      }
      return object.classId != ClassId.fig;
    });
  }

  /// Port of `TextLayoutElement::ResetCells` (textlayoutelement.cpp:77).
  void resetCells() {
    for (int i = 0; i < 9; ++i) {
      _cells[i].clear();
    }
  }

  /// Port of `TextLayoutElement::AppendTextToCell` (textlayoutelement.cpp:84).
  void appendTextToCell(int index, TextElement text) {
    assert(index >= 0 && index < 9);
    _cells[index].add(text);
  }

  /// Port of `TextLayoutElement::GetContentHeight` (textlayoutelement.cpp:90).
  int getContentHeight() {
    int height = 0;
    for (int i = 0; i < 3; ++i) {
      height += getRowHeight(i);
    }
    return height;
  }

  /// Port of `TextLayoutElement::GetContentWidth` (textlayoutelement.cpp:99).
  int getContentWidth() {
    int width = 0;
    for (int i = 0; i < 3; ++i) {
      width = math.max(width, getRowWidth(i));
    }
    return width;
  }

  /// Port of `TextLayoutElement::GetRowHeight` (textlayoutelement.cpp:108).
  int getRowHeight(int row) {
    assert(row >= 0 && row < 3);
    int height = 0;
    for (int i = 0; i < 3; ++i) {
      height = math.max(height, getCellHeight(row * 3 + i));
    }
    return height;
  }

  /// Port of `TextLayoutElement::GetColHeight` (textlayoutelement.cpp:119).
  int getColHeight(int col) {
    assert(col >= 0 && col < 3);
    int height = 0;
    for (int i = 0; i < 3; ++i) {
      height += getCellHeight(i * 3 + col);
    }
    return height;
  }

  /// Port of `TextLayoutElement::GetCellHeight` (textlayoutelement.cpp:130).
  int getCellHeight(int cell) {
    assert(cell >= 0 && cell < 9);
    int columnHeight = 0;
    final List<TextElement> textElements = _cells[cell];
    for (final TextElement element in textElements) {
      if (element.hasContentBB()) {
        columnHeight += element.getContentY2() - element.getContentY1();
      }
    }
    return columnHeight;
  }

  /// Port of `TextLayoutElement::GetRowWidth` (textlayoutelement.cpp:145).
  int getRowWidth(int row) {
    assert(row >= 0 && row < 3);
    final int col0 = getCellWidth(row * 3) > 0 ? 1 : 0;
    final int col1 = getCellWidth(row * 3 + 1) > 0 ? 1 : 0;
    final int col2 = getCellWidth(row * 3 + 2) > 0 ? 1 : 0;
    int width = 0;
    for (int i = 0; i < 3; ++i) {
      width = math.max(width, getCellWidth(row * 3 + i));
    }
    // If we have something in the middle column, ensure 3 times the max col width
    // Otherwise the maximum width for the number of columns
    return (col1 == 1 && (col0 == 1 || col2 == 1))
        ? width * 3
        : width * (col0 + col1 + col2);
  }

  /// Port of `TextLayoutElement::GetColWidth` (textlayoutelement.cpp:162).
  int getColWidth(int col) {
    assert(col >= 0 && col < 3);
    int width = 0;
    for (int i = 0; i < 3; ++i) {
      width = math.max(width, getCellWidth(i * 3 + col));
    }
    return width;
  }

  /// Port of `TextLayoutElement::GetCellWidth` (textlayoutelement.cpp:173).
  int getCellWidth(int cell) {
    assert(cell >= 0 && cell < 9);
    int columnWidth = 0;
    final List<TextElement> textElements = _cells[cell];
    for (final TextElement element in textElements) {
      if (element.hasContentBB()) {
        columnWidth = math.max(
            columnWidth, element.getContentX2() - element.getContentX1());
      }
    }
    return columnWidth;
  }

  /// Port of `TextLayoutElement::AdjustDrawingScaling` (textlayoutelement.cpp:188).
  bool adjustDrawingScaling(int width) {
    bool scale = false;
    // For each row
    for (int i = 0; i < 3; ++i) {
      int rowWidth = 0;
      // For each column
      for (int j = 0; j < 3; ++j) {
        final List<TextElement> textElements = _cells[i * 3 + j];
        int columnWidth = 0;
        // For each object
        for (final TextElement element in textElements) {
          if (element.hasContentBB()) {
            final int iterWidth =
                element.getContentX2() - element.getContentX1();
            columnWidth = math.max(columnWidth, iterWidth);
          }
        }
        rowWidth += columnWidth;
      }
      if (rowWidth != 0 && rowWidth > width) {
        _drawingScalingPercent[i] = width * 100 ~/ rowWidth;
        scale = true;
      }
    }
    return scale;
  }

  /// Port of `TextLayoutElement::ResetDrawingScaling` (textlayoutelement.cpp:215).
  void resetDrawingScaling() {
    for (int i = 0; i < 3; ++i) {
      _drawingScalingPercent[i] = 100;
    }
  }

  /// Port of `TextLayoutElement::AdjustRunningElementYPos` (textlayoutelement.cpp:222).
  bool adjustRunningElementYPos() {
    // First adjust the content of each cell
    for (int i = 0; i < 9; ++i) {
      int cumulatedYRel = 0;
      final List<TextElement> textElements = _cells[i];
      // For each object
      for (final TextElement element in textElements) {
        if (!element.hasContentBB()) {
          continue;
        }
        final int yShift = element.getContentY2();
        element.setDrawingYRel(cumulatedYRel - yShift);
        cumulatedYRel += (element.getContentY1() - element.getContentY2());
      }
    }

    int rowYRel = 0;
    // For each row
    for (int i = 0; i < 3; ++i) {
      final int currentRowHeigt = getRowHeight(i);
      // For each column
      for (int j = 0; j < 3; ++j) {
        final int cell = i * 3 + j;
        int colYShift = 0;
        // middle row - it needs to be middle-aligned so calculate the colYShift accordingly
        if (i == 1) {
          colYShift = (currentRowHeigt - getCellHeight(cell)) ~/ 2;
        }
        // bottom row - it needs to be bottom-aligned so calculate the colYShift accordingly
        else if (i == 2) {
          colYShift = (currentRowHeigt - getCellHeight(cell));
        }

        final List<TextElement> textElements = _cells[cell];
        // For each object - adjust the yRel according to the rowYRel and the colYshift
        for (final TextElement element in textElements) {
          if (!element.hasContentBB()) {
            continue;
          }
          element
              .setDrawingYRel(element.getDrawingYRel() + rowYRel - colYShift);
        }
      }
      rowYRel -= currentRowHeigt;
    }

    return true;
  }

  /// Port of `TextLayoutElement::GetAlignmentPos` (textlayoutelement.cpp:271).
  int getAlignmentPos(Horizontalalignment h, Verticalalignment v) {
    int pos = 0;
    switch (h) {
      case Horizontalalignment.left:
        break;
      case Horizontalalignment.center:
        pos += positionCenter;
        break;
      case Horizontalalignment.right:
        pos += positionRight;
        break;
      default:
        pos += positionLeft;
        break;
    }
    switch (v) {
      case Verticalalignment.top:
        break;
      case Verticalalignment.middle:
        pos += positionMiddle;
        break;
      case Verticalalignment.bottom:
        pos += positionBottom;
        break;
      default:
        pos += positionMiddle;
        break;
    }
    return pos;
  }

  /// Mirrors `TextLayoutElement::GetTotalHeight` (pure virtual in C++).
  /// Subclasses provide the concrete margin logic.
  int getTotalHeight(dynamic doc) {
    throw UnimplementedError('getTotalHeight must be overridden');
  }

  /// Mirrors `TextLayoutElement::GetTotalWidth` (pure virtual in C++).
  int getTotalWidth(dynamic doc) {
    throw UnimplementedError('getTotalWidth must be overridden');
  }

  /// Exposes the scaling percent for testing (mirrors `m_drawingScalingPercent`).
  int getDrawingScalingPercent(int row) => _drawingScalingPercent[row];

  /// Exposes cell content for testing.
  List<TextElement> getCell(int cell) => List.unmodifiable(_cells[cell]);
}

/// Mirrors `vrv::TextElement`: base class for the text element classes.
class TextElement extends TextLayoutElement with AttLabelled, AttTyped {
  TextElement([ClassId classId = ClassId.textElement]) {
    assignClassId(classId);
    reset();
  }

  /// The X drawing relative position (mirrors `m_drawingXRel`).
  int _drawingXRel = 0;

  /// The Y drawing relative position (mirrors `m_drawingYRel`).
  int _drawingYRel = 0;

  @override
  String get className => '[MISSING]';

  /// Port of `TextElement::Reset` (textelement.cpp:42).
  @override
  void reset() {
    super.reset();
    label = null;
    type = null;
    _drawingYRel = 0;
    _drawingXRel = 0;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    logDebug('Method for adding $classId to $className should be overridden');
    return false;
  }

  /// Port of `TextElement::GetDrawingX` (textelement.cpp:52).
  @override
  int getDrawingX() {
    final Object? textElement =
        getFirstAncestorInRange(ClassId.textElement, ClassId.textElementMax);
    if (textElement != null) {
      return textElement.getDrawingX() + getDrawingXRel();
    }
    final Object? textLayoutElement = getFirstAncestorInRange(
        ClassId.textLayoutElement, ClassId.textLayoutElementMax);
    if (textLayoutElement != null) {
      return textLayoutElement.getDrawingX() + getDrawingXRel();
    }
    if (parent == null) return getDrawingXRel();
    return parent!.getDrawingX() + getDrawingXRel();
  }

  /// Port of `TextElement::GetDrawingY` (textelement.cpp:71).
  @override
  int getDrawingY() {
    final Object? textElement =
        getFirstAncestorInRange(ClassId.textElement, ClassId.textElementMax);
    if (textElement != null) {
      return textElement.getDrawingY() + getDrawingYRel();
    }
    final Object? textLayoutElement = getFirstAncestorInRange(
        ClassId.textLayoutElement, ClassId.textLayoutElementMax);
    if (textLayoutElement != null) {
      return textLayoutElement.getDrawingY() + getDrawingYRel();
    }
    if (parent == null) return getDrawingYRel();
    return parent!.getDrawingY() + getDrawingYRel();
  }

  /// Port of `TextElement::SetDrawingXRel` (textelement.cpp:91).
  void setDrawingXRel(int drawingXRel) {
    resetCachedDrawingX();
    _drawingXRel = drawingXRel;
  }

  /// Port of `TextElement::GetDrawingXRel` (textelement.cpp:47).
  int getDrawingXRel() => _drawingXRel;

  /// Port of `TextElement::SetDrawingYRel` (textelement.cpp:97).
  void setDrawingYRel(int drawingYRel) {
    resetCachedDrawingY();
    _drawingYRel = drawingYRel;
  }

  /// Port of `TextElement::GetDrawingYRel` (textelement.h:49).
  int getDrawingYRel() => _drawingYRel;
}

/// Mirrors `vrv::RunningElement`: base class for pgHead / pgFoot.
class RunningElement extends TextLayoutElement with AttFormework {
  RunningElement([ClassId classId = ClassId.runningElement]) {
    assignClassId(classId);
    reset();
  }

  /// The page we are drawing, for the x position (mirrors
  /// `m_drawingPage`); typed as [Object] until the Page class is ported.
  Object? drawingPage;

  /// The y position of the running element (mirrors `m_drawingYRel`).
  int drawingYRel = 0;

  /// The system id the running element is attached to (drawing only).
  String? drawingSystemId;

  /// Flag indicating whether or not the element was generated (mirrors
  /// `m_isGenerated`).
  bool isGeneratedFlag = false;

  @override
  String get className => '[MISSING]';

  /// Port of `RunningElement::Reset` (runningelement.cpp:59).
  @override
  void reset() {
    super.reset();
    func = null;
    drawingSystemId = null;

    isGeneratedFlag = false;
    drawingPage = null;
    drawingYRel = 0;

    resetDrawingScaling();
  }

  /// Setter and getter of the generated flag (mirrors `IsGenerated`).
  bool getIsGenerated() => isGeneratedFlag;
  void setIsGenerated(bool isGenerated) => isGeneratedFlag = isGenerated;

  /// Port of `RunningElement::GetDrawingX` (runningelement.cpp:72).
  @override
  int getDrawingX() {
    if (drawingPage == null) return 0;

    /*
    if (this->GetHalign() == HORIZONTALALIGNMENT_left) {
        return 0;
    }
    else if (this->GetHalign() == HORIZONTALALIGNMENT_center) {
        return m_drawingPage->GetContentWidth() / 2;
    }
    else if (this->GetHalign() == HORIZONTALALIGNMENT_right) {
        return m_drawingPage->GetContentWidth();
    }
    */

    return 0;
  }

  /// Port of `RunningElement::GetDrawingY` (runningelement.cpp:91).
  @override
  int getDrawingY() {
    cachedDrawingY = 0;
    return drawingYRel;
  }

  /// Port of `RunningElement::SetDrawingYRel` (runningelement.cpp:97).
  void setDrawingYRel(int value) {
    resetCachedDrawingY();
    drawingYRel = value;
  }

  /// Port of `RunningElement::GetTotalWidth` (runningelement.cpp:103).
  @override
  int getTotalWidth(dynamic doc) {
    // In C++: return (doc->m_drawingPageContentWidth);
    return (doc as dynamic).drawingPageContentWidth as int;
  }

  /// Port of `RunningElement::SetDrawingPage` (runningelement.cpp:108).
  void setDrawingPage(Object? page) {
    resetList();
    resetCachedDrawingX();
    drawingPage = page;

    if (page != null) {
      setCurrentPageNum(page);
    }
  }

  /// Port of `RunningElement::SetCurrentPageNum` (runningelement.cpp:120).
  void setCurrentPageNum(Object currentPage) {
    final int? currentPageIdx = (currentPage as dynamic).idx as int?;
    // Page idx may be -1 when not in a Pages container; fall back to 0
    final int currentNum =
        (currentPageIdx != null && currentPageIdx >= 0 ? currentPageIdx : 0) +
            1;

    final num = findDescendantByType(ClassId.num) as Num?;
    if (num == null || (num.label != 'page')) return;

    final text = num.findDescendantByType(ClassId.text) as Text?;
    if (text == null || text.text != '#') return;

    final Text currentText = num.getCurrentText();

    currentText.text = '$currentNum';
  }

  /// Port of `RunningElement::LoadFooter` (runningelement.cpp:138).
  void loadFooter(dynamic doc) {
    final fig = Fig();
    final svg = Svg();
    // The C++ loads footer.svg from resources path; here we create a placeholder
    // Fig/Svg with center/bottom alignment. File I/O is not required for the
    // layout model test; the method exists for API parity.
    // In a full port the file would be read via resourceFileReader.
    fig.addChild(svg);
    fig.halign = Horizontalalignment.center;
    fig.valign = Verticalalignment.bottom;
    addChild(fig);
  }

  /// Port of `RunningElement::AddPageNum` (runningelement.cpp:154).
  void addPageNum(Horizontalalignment halign, Verticalalignment valign) {
    final rend = Rend();
    final fontsize = FontSize();
    fontsize.setTerm(Fontsizeterm.small);
    rend.fontsize = fontsize;
    rend.halign = halign;
    rend.valign = valign;

    final dash1 = Text();
    dash1.text = '\u2013 ';
    final num = Num();
    num.label = 'page';
    final text = Text();
    text.text = '#';
    final dash2 = Text();
    dash2.text = ' \u2013';

    num.addChild(text);
    rend.addChild(dash1);
    rend.addChild(num);
    rend.addChild(dash2);
    addChild(rend);
  }

  @override
  void copyFrom(covariant RunningElement other) {
    super.copyFrom(other);
    drawingPage = other.drawingPage;
    drawingYRel = other.drawingYRel;
    isGeneratedFlag = other.isGeneratedFlag;
  }
}

/// This class stores current drawing parameters for text
/// (mirrors `TextDrawingParams`, textelement.h:90).
///
/// Deviations from the C++:
/// - the `m_` prefixes are dropped (repo convention) and the constructor
///   initializations are inlined as field initializers.
/// - the virtual destructor has no equivalent (Dart has GC).
class TextDrawingParams {
  int x = 0;
  int y = 0;
  int width = 0;
  int height = 0;
  int actualWidth = 0;
  bool laidOut = false;

  /// Used when X and Y have been changed manually or otherwise (e.g., newline
  /// `<lb/>` shift or shift for boxed enclosure for rend).
  bool explicitPosition = false;
  bool verticalShift = false;
  HorizontalAlignment alignment = HorizontalAlignment.left;
  int pointSize = 0;
  final List<TextElement> enclosedRend = [];
  Textrendition enclose = Textrendition.none;
  Enclosure textEnclose = Enclosure.none;

  /// Value copy of the parameters (mirrors the C++ implicit copy constructor,
  /// used e.g. by `View::DrawRunningChildren`'s `TextDrawingParams paramsChild
  /// = params;`, view_page.cpp:1880): every field is copied, including the
  /// enclosedRend list.
  TextDrawingParams copy() {
    final TextDrawingParams copy = TextDrawingParams();
    copy.x = x;
    copy.y = y;
    copy.width = width;
    copy.height = height;
    copy.actualWidth = actualWidth;
    copy.laidOut = laidOut;
    copy.explicitPosition = explicitPosition;
    copy.verticalShift = verticalShift;
    copy.alignment = alignment;
    copy.pointSize = pointSize;
    copy.enclosedRend.addAll(enclosedRend);
    copy.enclose = enclose;
    copy.textEnclose = textEnclose;
    return copy;
  }
}
