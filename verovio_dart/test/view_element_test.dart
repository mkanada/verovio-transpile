import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/svg_device_context.dart';
import 'package:verovio_dart/src/rendering/view.dart';

import 'support/render_family.dart';

String renderMei(String meiPath) {
  final data = File(meiPath).readAsStringSync();
  final doc = Doc();
  final input = MeiInput(doc);
  final ok = input.import(data);
  if (!ok) throw StateError('import failed $meiPath');
  doc.prepareData();
  doc.setDrawingPage(0);
  doc.getResourcesForModification().initFonts();
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);
  final dc = SvgDeviceContext('docid');
  dc.setResources(doc.getResources());
  dc.width = doc.getOptions().pageWidth.unfactoredValue;
  dc.height = doc.getOptions().pageHeight.unfactoredValue;
  try {
    view.drawCurrentPage(dc, false);
  } on UnimplementedError {
    // Return partial svg as harness does
  }
  return dc.getStringSVG();
}

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  // -------------------------------------------------------------------------
  // Família view_element.cpp — elementos de camada e sistema
  // -------------------------------------------------------------------------

  test(
      'view_element: família element/ (note/chord/stem/accid/artic/keysig/metersig/rest/clef/custos/dot/space) contra goldens',
      () {
    const falhasConhecidas05_36 = ['stem/stem-014.mei', 'stem/stem-016.mei'];
    final resultados = renderizarFamilias([
      'test/corpus/note',
      'test/corpus/chord',
      'test/corpus/stem',
      'test/corpus/accid',
      'test/corpus/artic',
      'test/corpus/clef',
      'test/corpus/keysig',
      'test/corpus/metersig',
      'test/corpus/rest',
      'test/corpus/custos',
      'test/corpus/dot',
      'test/corpus/space',
      'test/corpus/gracenote',
      'test/corpus/editorial',
    ], falhasConhecidas05_36: falhasConhecidas05_36);
    // Medido em 2026-08-29: 35 limpos / 148 total (stem 6, note3, chord3, accid9, artic4, clef1, keysig2, metersig2, rest2, gracenote2, editorial1)
    expect(resultados.limpos, greaterThanOrEqualTo(35),
        reason: resultados.detalhes.take(3).join('\n'));
    final falhasReais = resultados.falhas
        .where((f) => !falhasConhecidas05_36.any((k) => f.contains(k)))
        .toList();
    expect(falhasReais, isEmpty, reason: falhasReais.join('\n'));
  });

  group('view_element: decisões Draw* sobre SVG (view_element.cpp)', () {
    test('DrawNote via note corpus → notehead e stem (view_element.cpp:210)',
        () {
      final svg = renderMei('test/corpus/note/note-002.mei');
      expect(svg, contains('notehead'),
          reason:
              'note-002 deve conter notehead — DrawNote view_element.cpp:215');
      expect(svg, contains('stem'),
          reason: 'note-002 deve conter stem — DrawStem view_element.cpp:340');
    });

    test('DrawChord via chord corpus → chord (view_element.cpp:380)', () {
      final svg = renderMei('test/corpus/chord/chord-001.mei');
      expect(svg, contains('notehead'));
      expect(svg, contains('chord'),
          reason:
              'chord-001 deve conter chord — DrawChord view_element.cpp:385');
    });

    test('DrawAccid via accid corpus → accid (view_element.cpp:800)', () {
      final svg = renderMei('test/corpus/accid/accid-002.mei');
      expect(svg, contains('accid'),
          reason:
              'accid-002 deve conter accid — DrawAccid view_element.cpp:810');
    });

    test('DrawArtic via artic corpus → artic (view_element.cpp:900)', () {
      final svg = renderMei('test/corpus/artic/artic-001.mei');
      expect(svg, contains('artic'),
          reason: 'artic-001 contém artic — DrawArtic view_element.cpp:905');
    });

    test('DrawKeySig via keysig corpus → keySig (view_element.cpp:1000)', () {
      final svg = renderMei('test/corpus/keysig/keysig-002.mei');
      expect(svg, contains('keySig'),
          reason:
              'keysig-002 deve conter keySig — DrawKeySig view_element.cpp:1010');
    });

    test('DrawMeterSig via metersig corpus → meterSig (view_element.cpp:1100)',
        () {
      final svg = renderMei('test/corpus/metersig/metersig-001.mei');
      expect(svg, contains('meterSig'),
          reason:
              'metersig-001 deve conter meterSig — DrawMeterSig view_element.cpp:1110');
    });

    test('DrawRest / DrawMRest → rest/mRest (view_element.cpp:600)', () {
      final svg = renderMei('test/corpus/rest/rest-001.mei');
      expect(svg, contains('rest'),
          reason: 'rest-001 contém rest — DrawRest view_element.cpp:610');
      final svg2 = renderMei('test/corpus/note/note-004.mei');
      expect(svg2, contains('mRest'), reason: 'mRest via DrawMRest');
    });

    test('DrawClef → clef (view_element.cpp:700)', () {
      final svg = renderMei('test/corpus/clef/clef-002.mei');
      expect(svg, contains('clef'),
          reason: 'clef-002 contém clef — DrawClef view_element.cpp:710');
    });
  });

  test(
      'view_element: primitivas via RecordingDC (view_element.cpp:800, view_graph.cpp:259)',
      () {
    final doc = Doc()..drawingPageContentHeight = 2970;
    doc.getResourcesForModification().initFonts();
    final view = View()..setDoc(doc);
    final dc = RecordingDeviceContext();
    dc.setResources(doc.getResources());
    view.drawSmuflCode(dc, 100, 200, 0xE262, 100, false);
    expect(dc.chamadas.any((c) => c.startsWith('drawMusicText')), isTrue,
        reason:
            'DrawAccid usa drawSmuflCode → drawMusicText (view_element.cpp:820)');
    final dc2 = RecordingDeviceContext();
    dc2.setResources(doc.getResources());
    view.drawDot(dc2, 90, 100, 100);
    expect(
        dc2.chamadas.any(
            (c) => c.startsWith('drawEllipse') || c.startsWith('drawCircle')),
        isTrue,
        reason: 'DrawDot → drawDot → drawEllipse (view_graph.cpp:203)');
  });
}
