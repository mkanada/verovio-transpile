/// Port of `textlayoutelement.h`, `textelement.h` and `runningelement.h`
/// — the base classes of the text/running element families.
library;

import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Fontsizeterm, Horizontalalignment, Verticalalignment;
import 'package:verovio_dart/src/model/atts/mei_values.dart' show FontSize;
import 'package:verovio_dart/src/model/misc_elements_gen.dart'
    show Num, Rend, Text;
import 'package:verovio_dart/src/model/object.dart';

/// Mirrors `vrv::TextLayoutElement`.
class TextLayoutElement extends Object with ObjectListInterface, AttTyped {
  TextLayoutElement([ClassId classId = ClassId.textLayoutElement]) {
    assignClassId(classId);
    reset();
  }

  @override
  String get className => '[MISSING]';

  @override
  void reset() {
    super.reset();
    type = null;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  @override
  void filterList(List<Object> childList) {
    // Keep only figs and top level rend elements (mirrors
    // `TextLayoutElement::FilterList`).
    childList.removeWhere((Object object) {
      if (object.classId == ClassId.rend) {
        return object.getFirstAncestor(ClassId.rend) != null;
      }
      return object.classId != ClassId.fig;
    });
  }
}

/// Mirrors `vrv::TextElement`: base class for the text element classes.
class TextElement extends TextLayoutElement with AttLabelled, AttTyped {
  TextElement([ClassId classId = ClassId.textElement]) {
    assignClassId(classId);
    reset();
  }

  @override
  String get className => '[MISSING]';

  @override
  void reset() {
    super.reset();
    label = null;
    type = null;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    logDebug('Method for adding $classId to $className should be overridden');
    return false;
  }
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

  @override
  void reset() {
    super.reset();
    func = null;
    drawingSystemId = null;

    isGeneratedFlag = false;
    drawingPage = null;
    drawingYRel = 0;
  }

  /// Setter and getter of the generated flag (mirrors `IsGenerated`).
  bool getIsGenerated() => isGeneratedFlag;
  void setIsGenerated(bool isGenerated) => isGeneratedFlag = isGenerated;

  @override
  int getDrawingX() {
    if (drawingPage == null) return 0;
    return 0;
  }

  @override
  int getDrawingY() {
    cachedDrawingY = 0;
    return drawingYRel;
  }

  void setDrawingYRel(int value) {
    resetCachedDrawingY();
    drawingYRel = value;
  }

  /// Set the current drawing page (mirrors `SetDrawingPage`). The page is
  /// used for resolving `<num label="page">#</num>` placeholders.
  void setDrawingPage(Object? page) {
    resetList();
    resetCachedDrawingX();
    drawingPage = page;

    if (page != null) {
      setCurrentPageNum(page);
    }
  }

  /// Set the current page number by looking for a
  /// `<num label="page">#</num>` element (mirrors `SetCurrentPageNum`).
  void setCurrentPageNum(Object currentPage) {
    final int? currentPageIdx = (currentPage as dynamic).idx as int?;
    final int currentNum = (currentPageIdx ?? 0) + 1;

    final num = findDescendantByType(ClassId.num) as Num?;
    if (num == null || (num.label != 'page')) return;

    final text = num.findDescendantByType(ClassId.text) as Text?;
    if (text == null || text.text != '#') return;

    final Text currentText = num.getCurrentText();
    currentText.text = '$currentNum';
  }

  /// Add page numbering to the running element (mirrors `AddPageNum`).
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
