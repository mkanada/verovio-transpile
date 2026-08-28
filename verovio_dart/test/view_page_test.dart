/// Tests for `lib/src/rendering/view_page.dart` (task 05-08) — the page
/// drawing spine of the `View` ported from `origin/src/src/view_page.cpp`
/// (view_page.cpp:65-255 and 1575-2076): `DrawCurrentPage`, `DrawSystem`,
/// `DrawPageElement`, `SetScoreDefDrawingWidth`, `GetPPUFactor`,
/// `DrawSystemDivider`, the `Draw*Children` / `Draw*EditorialElement`
/// dispatchers and `DrawAnnot`.
///
/// The page is drawn through the real `View` on an `SvgDeviceContext` and
/// compared in structural mode with `test/golden/cpp/note/note-001.svg`.
/// Almost all of the page content is still missing (the scoreDef / measure /
/// staff methods are `_notYet` stubs ported by 05-09..05-11 and the element
/// methods by 05-13..05-22), so the main test asserts exactly what this task
/// produces — the `<svg>` envelope, the `<desc>`, the `<style>`, the
/// `<g class="page-margin">` and the `<g class="system">` — and nothing
/// more.
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/options_shell.dart'
    show Breaks, tempKeysigStep;
import 'package:verovio_dart/src/core/smufl.dart'
    show smuflE050Gclef, smuflE262AccidentalSharp;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart'
    show registerModelClasses;
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Score;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/editorial_element.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show Text;
import 'package:verovio_dart/src/model/scoredef.dart' show StaffDef;
import 'package:verovio_dart/src/model/system_page_elements.dart'
    show PageMilestoneEnd;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/svg_device_context.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:xml/xml.dart';

/// The golden the structural comparison runs against.
const String kGoldenPath = 'test/golden/cpp/note/note-001.svg';

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  /// Loads note-001.mei, lays it out and returns the doc + a view pointing
  /// at page 0 (mirrors `Toolkit::RenderToDeviceContext`,
  /// toolkit.cpp:1671-1674: `SetDrawingPage` + `View::SetPage(page, true)`).
  (Doc, View) loadNote001() {
    final doc = Doc();
    final input = MeiInput(doc);
    final data = File('test/corpus/note/note-001.mei').readAsStringSync();
    final bool ok = input.import(data);
    expect(ok, isTrue, reason: 'MEI import of note-001.mei failed');
    doc.getOptions().breaks.setValue(Breaks.auto);
    doc.prepareData();
    doc.setDrawingPage(0);
    final view = View()..setDoc(doc);
    // Do not do the layout in this view - otherwise we will loop...
    view.setPage(doc.drawingPage!, true);
    return (doc, view);
  }

  /// Draws page 0 on a fresh context with the sizes of
  /// `RenderToDeviceContext` (unfactored page width / height) and returns
  /// the partial SVG produced before the first `_notYet` stub throws — the
  /// same string `GetStringSVG` gives after `Commit`.
  (String, UnimplementedError) drawNote001Partial() {
    final (doc, view) = loadNote001();
    doc.getResourcesForModification().initFonts();
    final SvgDeviceContext dc = SvgDeviceContext('docid');
    dc.setResources(doc.getResources());
    // toolkit.cpp:1680-1681: width / height from the unfactored page options
    // (no adjustPageWidth/Height, breaks auto, no landscape).
    dc.width = doc.getOptions().pageWidth.unfactoredValue;
    dc.height = doc.getOptions().pageHeight.unfactoredValue;
    // Mirrors toolkit.cpp:1714: `m_view.DrawCurrentPage(deviceContext, false)`.
    try {
      view.drawCurrentPage(dc, false);
      fail('expected the first _notYet stub to throw');
    } on UnimplementedError catch (e) {
      return (dc.getStringSVG(), e);
    }
  }

  XmlElement firstChild(XmlElement parent, String name) =>
      parent.childElements.firstWhere((e) => e.name.qualified == name);

  String? classOf(XmlElement element) => element.getAttribute('class');

  test('drawCurrentPage para no primeiro stub _notYet (DrawScoreDef, 05-09)',
      () {
    final (_, error) = drawNote001Partial();
    expect(error.message, contains('DrawScoreDef'));
    expect(error.message, contains('05-09'));
  });

  test('drawCurrentPage: página estruturalmente igual ao golden até o sistema',
      () {
    final (String svg, _) = drawNote001Partial();
    final golden = File(kGoldenPath).readAsStringSync();

    final dartDoc = XmlDocument.parse(svg);
    final goldenDoc = XmlDocument.parse(golden);
    final dartRoot = dartDoc.rootElement;
    final goldenRoot = goldenDoc.rootElement;

    // The <svg> root envelope (name and seed-dependent id).
    expect(dartRoot.name.qualified, goldenRoot.name.qualified);
    expect(dartRoot.getAttribute('id'), isNotNull);
    expect(goldenRoot.getAttribute('id'), isNotNull);

    // The <desc> — same text as the golden.
    final dartDesc = firstChild(dartRoot, 'desc');
    final goldenDesc = firstChild(goldenRoot, 'desc');
    expect(dartDesc.innerText, 'Engraved by Verovio 6.2.0');
    expect(dartDesc.innerText, goldenDesc.innerText);

    // The golden carries a <defs> of drawn glyphs; the partial page drew no
    // glyph yet (everything below the system is still a stub), so it has no
    // <defs> — the first expected divergence. The default CSS <style> is
    // emitted by both (StartPage), prefixed by the document id.
    expect(dartRoot.childElements.map((e) => e.name.qualified).toList(),
        ['desc', 'style', 'svg'],
        reason: 'sem <defs>: nenhum glifo foi desenhado nesta tarefa');
    expect(goldenRoot.childElements.map((e) => e.name.qualified).toList(),
        ['desc', 'defs', 'style', 'svg']);
    final goldenDocId = goldenRoot.getAttribute('id')!;
    final goldenStyle = firstChild(goldenRoot, 'style')
        .innerText
        .replaceAll(goldenDocId, '@doc');
    expect(firstChild(dartRoot, 'style').innerText.replaceAll('docid', '@doc'),
        goldenStyle);

    // The definition-scale <svg> and the page-margin <g>.
    final dartScale = firstChild(dartRoot, 'svg');
    final goldenScale = firstChild(goldenRoot, 'svg');
    expect(classOf(dartScale), 'definition-scale');
    expect(classOf(dartScale), classOf(goldenScale));
    expect(dartScale.getAttribute('viewBox'), '0 0 21000 29700',
        reason: 'width*viewBoxFactor e contentHeight*viewBoxFactor, como no '
            'golden (2100/2970 dos unfactored options, factor 10)');
    final dartMargin = firstChild(dartScale, 'g');
    final goldenMargin = firstChild(goldenScale, 'g');
    expect(classOf(dartMargin), 'page-margin');
    expect(classOf(dartMargin), classOf(goldenMargin));
    expect(dartMargin.getAttribute('transform'), 'translate(500, 500)');
    expect(dartMargin.getAttribute('transform'),
        goldenMargin.getAttribute('transform'));

    // The <g> children of the page-margin: same element names and same class
    // attributes as the golden, in the same order — mdiv / score milestones
    // (DrawPageElement) and the system (DrawSystem).
    final dartKids = dartMargin.childElements.toList();
    final goldenKids = goldenMargin.childElements.toList();
    expect(dartKids.length, lessThanOrEqualTo(goldenKids.length));
    for (var i = 0; i < dartKids.length; i++) {
      expect(dartKids[i].name.qualified, goldenKids[i].name.qualified,
          reason: 'filho $i do page-margin');
      expect(classOf(dartKids[i]), classOf(goldenKids[i]),
          reason: 'filho $i do page-margin');
    }
    expect(dartKids.map(classOf).toList(),
        ['mdiv pageMilestone', 'score pageMilestone', 'system']);
    expect(dartKids.last.getAttribute('id'), isNotNull);

    // The system <g> is empty in the partial output: DrawScoreDef (05-09)
    // threw before anything was drawn inside it, so nothing below the system
    // exists yet. The golden continues with the section milestone and the
    // measures.
    final dartSystem = dartKids.last;
    final goldenSystem = goldenKids[2];
    expect(classOf(dartSystem), 'system');
    expect(classOf(dartSystem), classOf(goldenSystem));
    expect(dartSystem.childElements, isEmpty);
    expect(goldenSystem.childElements, isNotEmpty);

    // The first system draws no system divider (DrawSystemDivider early
    // return for the first system of the page).
    expect(svg.contains('systemDivider'), isFalse);

    // And nothing else was produced: the partial has exactly the elements
    // walked above.
    expect(svg, isNot(contains('measure')));
    expect(svg, isNot(contains('staff')));
    expect(svg, isNot(contains('layer')));
  });

  test('drawPageElement: PageMilestoneEnd usa o id do start como classe', () {
    final (doc, view) = loadNote001();
    doc.getResourcesForModification().initFonts();
    final SvgDeviceContext dc = SvgDeviceContext('docid');
    dc.setResources(doc.getResources());

    // The golden (note-001.svg:93) has:
    //   <g id="dzj5nv5" class="pageMilestoneEnd q14gtc1t" />
    // — the class carries the id of the start (the score milestone).
    final score = Score();
    score.id = 'q14gtc1t';
    view.drawPageElement(dc, PageMilestoneEnd(score));

    expect(dc.getStringSVG(),
        contains('<g id="q14gtc1t" class="pageMilestoneEnd q14gtc1t" />'));
  });

  test('drawAnnot escreve o texto como <desc> dentro do grupo', () {
    final (doc, view) = loadNote001();
    doc.getResourcesForModification().initFonts();
    final SvgDeviceContext dc = SvgDeviceContext('docid');
    dc.setResources(doc.getResources());

    final annot = Annot();
    annot.id = 'a1';
    annot.addChild(Text()..text = 'Olás');
    view.drawAnnot(dc, annot);

    final annotG = XmlDocument.parse(dc.getStringSVG())
        .rootElement
        .childElements
        .firstWhere((e) => e.getAttribute('class') == 'annot');
    expect(annotG.getAttribute('class'), 'annot');
    expect(annotG.innerText.trim(), 'Olás');
  });

  test('getPPUFactor: 1.0 sem página corrente e com a página de reset', () {
    final (doc, view) = loadNote001();

    final bareView = View()..setDoc(doc);
    expect(bareView.getPPUFactor(), 1.0,
        reason: 'View::GetPPUFactor devolve 1.0 sem m_currentPage');
    // Page::Reset (page.cpp:100) sets m_PPUFactor = 1.0.
    expect(view.currentPage!.getPPUFactor(), 1.0);
    expect(view.getPPUFactor(), 1.0);
  });

  test('setScoreDefDrawingWidth: clave + 5 acidentes da armadura do staffDef',
      () {
    final (doc, view) = loadNote001();
    final SvgDeviceContext dc = SvgDeviceContext('docid');
    final scoreDef = doc.drawingPage!.drawingScoreDef;

    // note-001 has keysig="5f" on the staffDef: the scoreDef itself has no
    // direct keySig child (HasKeySigInfo is false), the alteration count
    // comes from the longest staffDef key signature (5 flats).
    expect(scoreDef.hasKeySigInfo(), isFalse);
    final staffDef = scoreDef.getList().first as StaffDef;
    expect(staffDef.hasKeySigInfo(), isTrue);
    expect((staffDef.getKeySig()).getAccidCount(), 5);

    view.setScoreDefDrawingWidth(dc, scoreDef);

    // The C++ formula (view_page.cpp:150-160), with the same truncation:
    // each `width +=` sums a glyph width and margin*unit doubles and
    // truncates the whole sum once.
    final int unit = doc.getDrawingUnit(100);
    final int clefPart = (doc.getGlyphWidth(smuflE050Gclef, 100, false) +
            (doc.getLeftMargin(ClassId.clef) +
                    doc.getRightMargin(ClassId.clef)) *
                unit)
        .truncate();
    final int keysigPart =
        (doc.getGlyphWidth(smuflE262AccidentalSharp, 100, false) *
                    tempKeysigStep +
                (doc.getLeftMargin(ClassId.keysig) +
                        doc.getRightMargin(ClassId.keysig)) *
                    unit)
            .truncate();
    expect(scoreDef.drawingWidth, clefPart + keysigPart);
  });
}
