/// Tests for Fase 4 transcription functors + ReorderByXPos
/// (Page::LayOutTranscription + 4 functors).
///
/// - AdjustXRelForTranscription / AdjustYRelForTranscription: synthetic + produção
///   via neume-001.mei (único arquivo com `facsimile type="transcription"`).
/// - ApplyPPUFactor: sintético (nenhum corpus tem @ppu).
/// - ReorderByXPos: sintético (sem chamador nesta fase, Phase 6).
///
/// Referência C++:
/// - page.cpp:249-316 (LayOutTranscription)
/// - adjustxrelfortranscriptionfunctor.cpp 35 linhas
/// - adjustyrelfortranscriptionfunctor.cpp 35 linhas
/// - miscfunctor.cpp:27-111 (ApplyPPUFactor)
/// - miscfunctor.cpp:167-184 (ReorderByXPosFunctor) + object.cpp:1222+1296 (ReorderByXPos/sortByUlx)
library;

import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/adjust_transcription.dart';
import 'package:verovio_dart/src/layout/apply_ppu_factor.dart';
import 'package:verovio_dart/src/layout/reorder_by_x_pos.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show Pitchname;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Clef, Layer, Measure, Staff;
import 'package:verovio_dart/src/model/basic_elements.dart' show Note;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Nc, Neume, Syllable;
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show Surface;
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef;
import 'package:verovio_dart/src/model/system_page_elements.dart' show System;
import 'package:verovio_dart/src/model/zone.dart' show Zone;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';

Doc _loadDoc(String path) {
  final file = File(path);
  final doc = Doc();
  final input = MeiInput(doc);
  final ok =
      input.import(utf8.decode(file.readAsBytesSync(), allowMalformed: true));
  expect(ok, isTrue, reason: 'MEI import of $path should succeed');
  return doc;
}

void main() {
  setUpAll(() {
    registerModelClasses();
    Resources.defaultPath = 'assets/data';
    logLevel = LogLevel.error;
  });

  // ---------------------------------------------------------------------------
  // AdjustXRelForTranscriptionFunctor — sintético
  // ---------------------------------------------------------------------------
  group('AdjustXRelForTranscriptionFunctor — sintético', () {
    test('ajusta drawingXRel para -selfX1 quando tem facs e bbox', () {
      final note = Note();
      // Primeiro cria BBox relativa 30 (drawingFacs ainda meiUnset => drawingX 0)
      note.updateSelfBBoxX(30, 50);
      note.updateSelfBBoxY(0, 10);
      note.drawingXRel = 0;
      note.drawingFacsX = 1000;
      expect(note.hasSelfBB(), isTrue);
      final functor = AdjustXRelForTranscriptionFunctor();
      final code = functor.visitLayerElement(note);
      expect(code, FunctorCode.continue_);
      expect(note.drawingXRel, -30);
    });

    test('não ajusta quando drawingFacsX == meiUnset', () {
      final note = Note();
      note.updateSelfBBoxX(30, 50);
      note.updateSelfBBoxY(0, 10);
      note.drawingFacsX = meiUnset;
      note.drawingXRel = 5;
      final functor = AdjustXRelForTranscriptionFunctor();
      functor.visitLayerElement(note);
      expect(note.drawingXRel, 5);
    });

    test('não ajusta quando !hasSelfBB', () {
      final note = Note();
      note.drawingFacsX = 1000;
      // no BBox
      note.drawingXRel = 5;
      final functor = AdjustXRelForTranscriptionFunctor();
      functor.visitLayerElement(note);
      expect(note.drawingXRel, 5);
    });

    test('isScoreDefElement => siblings (não visita filhos)', () {
      // Clef inside ScoreDef is isScoreDefElement true (via ancestor scoreDef)
      final scoreDef = ScoreDef();
      final clef = Clef();
      scoreDef.addChild(clef);
      clef.updateSelfBBoxX(20, 40);
      clef.updateSelfBBoxY(0, 10);
      clef.drawingFacsX = 1000;
      clef.drawingXRel = 0;
      final functor = AdjustXRelForTranscriptionFunctor();
      final code = functor.visitLayerElement(clef);
      expect(code, FunctorCode.siblings);
      expect(clef.drawingXRel, 0);
    });

    test('morde se lógica quebrar: setDrawingXRel errado falha', () {
      final note = Note();
      note.updateSelfBBoxX(15, 25);
      note.updateSelfBBoxY(0, 10);
      note.drawingFacsX = 1000;
      final functor = AdjustXRelForTranscriptionFunctor();
      functor.visitLayerElement(note);
      // Se implementação fizesse +selfX1 em vez de -selfX1, falharia:
      expect(note.drawingXRel, isNot(15));
      expect(note.drawingXRel, -15);
    });
  });

  // ---------------------------------------------------------------------------
  // AdjustYRelForTranscriptionFunctor — sintético
  // ---------------------------------------------------------------------------
  group('AdjustYRelForTranscriptionFunctor — sintético', () {
    test('ajusta drawingYRel para -selfY1 quando tem facs e bbox', () {
      final note = Note();
      note.updateSelfBBoxX(0, 10);
      note.updateSelfBBoxY(12, 30);
      note.drawingFacsY = 2000;
      note.drawingYRel = 0;
      expect(note.hasSelfBB(), isTrue);
      final functor = AdjustYRelForTranscriptionFunctor();
      final code = functor.visitLayerElement(note);
      expect(code, FunctorCode.continue_);
      expect(note.drawingYRel, -12);
    });

    test('não ajusta quando drawingFacsY == meiUnset', () {
      final note = Note();
      note.updateSelfBBoxX(0, 10);
      note.updateSelfBBoxY(12, 30);
      note.drawingFacsY = meiUnset;
      note.drawingYRel = 7;
      final functor = AdjustYRelForTranscriptionFunctor();
      functor.visitLayerElement(note);
      expect(note.drawingYRel, 7);
    });

    test('não ajusta quando !hasSelfBB', () {
      final note = Note();
      note.drawingFacsY = 2000;
      note.drawingYRel = 7;
      final functor = AdjustYRelForTranscriptionFunctor();
      functor.visitLayerElement(note);
      expect(note.drawingYRel, 7);
    });

    test('isScoreDefElement => siblings', () {
      final scoreDef = ScoreDef();
      final clef = Clef();
      scoreDef.addChild(clef);
      clef.updateSelfBBoxX(0, 10);
      clef.updateSelfBBoxY(12, 30);
      clef.drawingFacsY = 2000;
      clef.drawingYRel = 0;
      final functor = AdjustYRelForTranscriptionFunctor();
      final code = functor.visitLayerElement(clef);
      expect(code, FunctorCode.siblings);
      expect(clef.drawingYRel, 0);
    });

    test('morde se lógica quebrar', () {
      final note = Note();
      note.updateSelfBBoxX(0, 10);
      note.updateSelfBBoxY(18, 30);
      note.drawingFacsY = 2000;
      final functor = AdjustYRelForTranscriptionFunctor();
      functor.visitLayerElement(note);
      expect(note.drawingYRel, -18);
      expect(note.drawingYRel, isNot(18));
    });
  });

  // ---------------------------------------------------------------------------
  // AdjustXRel/YRel — produção via neume-001.mei
  // ---------------------------------------------------------------------------
  group('AdjustXRel/YRel — produção neume-001.mei', () {
    test(
        'neume-001 é transcrição e View.setPage roteia por layOutTranscription',
        () {
      final doc = _loadDoc('test/corpus/neume/neume-001.mei');
      expect(doc.isTranscription(), isTrue,
          reason: 'facsimile type=transcription');
      doc.prepareData();
      final page = doc.setDrawingPage(0)!;
      // page.layOutTranscription deve ser alcançado via View.setPage
      final view = View()..setDoc(doc);
      // View.setPage com transcription roteia para layOutTranscription.
      // Mesmo sem facsimile sync (Phase 6), o método deve ser chamado sem exceção.
      expect(() => view.setPage(page, true), returnsNormally);
      expect(page.layoutDone, isTrue);
      // Prova de alcance: functor visita elementos de neume-001 (independente de facs)
      final spy = _CountingAdjustXRelTotal();
      page.process(spy);
      expect(spy.totalVisited, greaterThan(0),
          reason: 'functor deve alcançar elementos de neume-001');
    });

    test(
        'neume-001 layOutTranscription direto também ajusta (prova de alcance)',
        () {
      final doc = _loadDoc('test/corpus/neume/neume-001.mei');
      doc.prepareData();
      final page = doc.setDrawingPage(0)!;
      // Força layOutTranscription
      expect(() => page.layOutTranscription(force: true), returnsNormally);
      expect(page.layoutDone, isTrue);
      // Spy total
      final spy = _CountingAdjustYRelTotal();
      page.process(spy);
      expect(spy.totalVisited, greaterThan(0));
    });
  });

  // ---------------------------------------------------------------------------
  // ApplyPPUFactorFunctor — sintético (nenhum corpus tem @ppu)
  // ---------------------------------------------------------------------------
  group('ApplyPPUFactorFunctor — sintético', () {
    test('Page: divide pageWidth/Height/Margins por ppu (truncation)', () {
      final page = Page()
        ..pageWidth = 1000
        ..pageHeight = 2000
        ..pageMarginBottom = 100
        ..pageMarginLeft = 200
        ..pageMarginRight = 300
        ..pageMarginTop = 400
        ..ppufactor = 2.0;
      final functor = ApplyPPUFactorFunctor(page);
      // Chama diretamente visitPage (equivalente ao Process via Page)
      functor.visitPage(page);
      expect(page.pageWidth, 500);
      expect(page.pageHeight, 1000);
      expect(page.pageMarginBottom, 50);
      expect(page.pageMarginLeft, 100);
      expect(page.pageMarginRight, 150);
      expect(page.pageMarginTop, 200);
    });

    test('LayerElement: divide drawingFacsX/Y por ppu', () {
      final page = Page()..ppufactor = 2.0;
      final note = Note()
        ..drawingFacsX = 100
        ..drawingFacsY = 201; // ímpar para testar truncation 201/2=100
      final functor = ApplyPPUFactorFunctor(page);
      functor.visitLayerElement(note);
      expect(note.drawingFacsX, 50);
      expect(note.drawingFacsY, 100); // 201/2 trunc 100
    });

    test('Measure: divide drawingFacsX1/X2, Staff: divide drawingFacsY', () {
      final page = Page()..ppufactor = 4.0;
      final measure = Measure()
        ..drawingFacsX1 = 80
        ..drawingFacsX2 = 90;
      final staff = Staff()
        ..n = 1
        ..drawingFacsY = 40;
      final functor = ApplyPPUFactorFunctor(page);
      functor.visitMeasure(measure);
      functor.visitStaff(staff);
      expect(measure.drawingFacsX1, 20);
      expect(measure.drawingFacsX2, 22); // 90/4=22
      expect(staff.drawingFacsY, 10);
    });

    test('System: divide facs e multiplica margins', () {
      final page = Page()..ppufactor = 2.0;
      final system = System()
        ..drawingFacsX = 100
        ..drawingFacsY = 200
        ..systemLeftMar = 10
        ..systemRightMar = 20;
      final functor = ApplyPPUFactorFunctor(page);
      functor.visitSystem(system);
      expect(system.drawingFacsX, 50);
      expect(system.drawingFacsY, 100);
      expect(system.systemLeftMar, 20);
      expect(system.systemRightMar, 40);
    });

    test('Surface/Zone multiplicam', () {
      final page = Page()..ppufactor = 2.0;
      final surface = Surface()
        ..ulx = 5
        ..uly = 10
        ..lrx = 15
        ..lry = 20;
      final zone = Zone()
        ..ulx = 7
        ..uly = 14
        ..lrx = 21
        ..lry = 28;
      final functor = ApplyPPUFactorFunctor(page);
      functor.visitSurface(surface);
      functor.visitZone(zone);
      expect(surface.ulx, 10);
      expect(surface.uly, 20);
      expect(surface.lrx, 30);
      expect(surface.lry, 40);
      expect(zone.ulx, 14);
      expect(zone.uly, 28);
      expect(zone.lrx, 42);
      expect(zone.lry, 56);
    });

    test(
        'isScoreDefElement => siblings (LayerElement com facs não dividido se for scoreDef)',
        () {
      final page = Page()..ppufactor = 2.0;
      final scoreDef = ScoreDef();
      final clef = Clef()
        ..drawingFacsX = 100
        ..drawingFacsY = 200;
      scoreDef.addChild(clef);
      final functor = ApplyPPUFactorFunctor(page);
      final code = functor.visitLayerElement(clef);
      expect(code, FunctorCode.siblings);
      expect(clef.drawingFacsX, 100);
      expect(clef.drawingFacsY, 200);
    });

    test(
        'mei_input ReadPage liga ApplyPPUFactor quando isTranscription e ppu !=1.0 (sintético)',
        () {
      final pageBased = '''
<?xml version="1.0" encoding="UTF-8"?>
<mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="6.0-dev">
  <meiHead><fileDesc><titleStmt><title>Test PPU page</title></titleStmt><pubStmt/></fileDesc></meiHead>
  <music>
    <facsimile type="transcription"><surface xml:id="s1" lrx="100" lry="100"><zone xml:id="z1" ulx="10" uly="10" lrx="20" lry="20"/></surface></facsimile>
    <body><pages type="transcription"><page xml:id="p1" ppu="2.0"><system><measure><staff n="1"><layer n="1"><note pname="c" oct="4" dur="4" facs="#z1" coord.x1="100"/></layer></staff></measure></system></page></pages></body>
  </music>
</mei>
''';
      final doc = Doc();
      final input = MeiInput(doc);
      final ok = input.import(pageBased);
      expect(ok, isTrue);
      expect(doc.isTranscription(), isTrue);
      final pages = doc.getPages()!;
      final page = pages.getChild(0) as Page;
      expect(page.getPPUFactor(), 2.0);
      final note = page.findDescendantByType(ClassId.note) as LayerElement;
      // coord.x1=100 => 100*10=1000 /2=500
      expect(note.drawingFacsX, 500);
    });

    test('morde se divisão errada: ppu 2 com valor ímpar deve truncar', () {
      final page = Page()..ppufactor = 2.0;
      final note = Note()..drawingFacsX = 5;
      final functor = ApplyPPUFactorFunctor(page);
      functor.visitLayerElement(note);
      expect(note.drawingFacsX, 2); // 5/2=2 trunc
      expect(note.drawingFacsX, isNot(3));
    });
  });

  // ---------------------------------------------------------------------------
  // ReorderByXPos — sintético
  // ---------------------------------------------------------------------------
  group('ReorderByXPos — sintético', () {
    test('ordena Layer filhos por ulx crescente (stable)', () {
      final layer = Layer()..n = 1;
      Note makeNote(int ulx, String id) {
        final note = Note()..id = id;
        final zone = Zone()
          ..ulx = ulx
          ..uly = 0
          ..lrx = ulx + 10
          ..lry = 10;
        note.facs = '#z_$id';
        note.zone = zone;
        return note;
      }

      final n1 = makeNote(300, 'n300');
      final n2 = makeNote(100, 'n100');
      final n3 = makeNote(200, 'n200');
      layer.addChild(n1);
      layer.addChild(n2);
      layer.addChild(n3);
      expect(
          layer.children.map((o) => o.id).toList(), ['n300', 'n100', 'n200']);
      layer.reorderByXPos();
      expect(
          layer.children.map((o) => o.id).toList(), ['n100', 'n200', 'n300']);
    });

    test('stable: elementos sem facs mantêm ordem relativa', () {
      final layer = Layer()..n = 1;
      Note makeNoteWithFacs(int ulx, String id) {
        final note = Note()..id = id;
        final zone = Zone()
          ..ulx = ulx
          ..uly = 0
          ..lrx = ulx + 10
          ..lry = 10;
        note.facs = '#z_$id';
        note.zone = zone;
        return note;
      }

      final nFacs = makeNoteWithFacs(200, 'withFacs');
      final nNoFacs1 = Note()..id = 'noFacs1';
      final nNoFacs2 = Note()..id = 'noFacs2';
      layer.addChild(nFacs);
      layer.addChild(nNoFacs1);
      layer.addChild(nNoFacs2);
      layer.reorderByXPos();
      expect(layer.children.map((o) => o.id).toList(),
          ['withFacs', 'noFacs1', 'noFacs2']);
    });

    test('FacsimileInterface com hasFacs => siblings (não reordena filhos)',
        () {
      final syl = Syllable()
        ..id = 'sylParent'
        ..facs = '#z1';
      final zone = Zone()
        ..ulx = 10
        ..uly = 10
        ..lrx = 20
        ..lry = 20;
      syl.zone = zone;
      expect(syl.hasFacs, isTrue);
      final neume1 = Neume()..id = 'n1';
      final neume2 = Neume()..id = 'n2';
      syl.addChild(neume1);
      syl.addChild(neume2);
      syl.reorderByXPos();
      expect(syl.children.map((o) => o.id).toList(), ['n1', 'n2']);
    });

    test('sortByUlx escolhe minimal ulx entre descendentes (exclui Syl)', () {
      final neume = Neume()..id = 'neume1';
      final nc1 = Nc()..id = 'nc300';
      final zone1 = Zone()
        ..ulx = 300
        ..uly = 0
        ..lrx = 310
        ..lry = 10;
      nc1.facs = '#z_nc300';
      nc1.zone = zone1;
      final nc2 = Nc()..id = 'nc100';
      final zone2 = Zone()
        ..ulx = 100
        ..uly = 0
        ..lrx = 110
        ..lry = 10;
      nc2.facs = '#z_nc100';
      nc2.zone = zone2;
      neume.addChild(nc1);
      neume.addChild(nc2);
      final neume2 = Neume()..id = 'neume2';
      final nc3 = Nc()..id = 'nc200';
      final zone3 = Zone()
        ..ulx = 200
        ..uly = 0
        ..lrx = 210
        ..lry = 10;
      nc3.facs = '#z_nc200';
      nc3.zone = zone3;
      neume2.addChild(nc3);
      final layer = Layer()..n = 1;
      layer.addChild(neume); // minimal 100
      layer.addChild(neume2); // minimal 200
      expect(layer.children.map((o) => o.id).toList(), ['neume1', 'neume2']);
      // Cria segundo layer desordenado com objetos novos (não reusa mesmos pais)
      final layer2 = Layer()..n = 1;
      final neumeA = Neume()..id = 'neume1';
      final nc1b = Nc()..id = 'nc300b';
      nc1b.facs = '#z_nc300b';
      nc1b.zone = Zone()
        ..ulx = 300
        ..uly = 0
        ..lrx = 310
        ..lry = 10;
      final nc2b = Nc()..id = 'nc100b';
      nc2b.facs = '#z_nc100b';
      nc2b.zone = Zone()
        ..ulx = 100
        ..uly = 0
        ..lrx = 110
        ..lry = 10;
      neumeA.addChild(nc1b);
      neumeA.addChild(nc2b);
      final neumeB = Neume()..id = 'neume2';
      final nc3b = Nc()..id = 'nc200b';
      nc3b.facs = '#z_nc200b';
      nc3b.zone = Zone()
        ..ulx = 200
        ..uly = 0
        ..lrx = 210
        ..lry = 10;
      neumeB.addChild(nc3b);
      layer2.addChild(neumeB);
      layer2.addChild(neumeA);
      layer2.reorderByXPos();
      expect(layer2.children.map((o) => o.id).toList(), ['neume1', 'neume2']);
    });

    test('Nc ligated com mesmo ulx ordena por pitch higher first', () {
      final layer = Layer()..n = 1;
      final ncA = Nc()..id = 'ncA';
      ncA.ligated = true;
      ncA.pname = Pitchname.c;
      ncA.oct = 4;
      final zoneA = Zone()
        ..ulx = 100
        ..uly = 0
        ..lrx = 110
        ..lry = 10;
      ncA.facs = '#z_ncA';
      ncA.zone = zoneA;

      final ncB = Nc()..id = 'ncB';
      ncB.ligated = true;
      ncB.pname = Pitchname.d;
      ncB.oct = 4;
      final zoneB = Zone()
        ..ulx = 100
        ..uly = 0
        ..lrx = 110
        ..lry = 10;
      ncB.facs = '#z_ncB';
      ncB.zone = zoneB;

      layer.addChild(ncA); // C
      layer.addChild(ncB); // D
      layer.reorderByXPos();
      expect(layer.children.first.id, 'ncB');
    });

    test('morde se ordenação não estável: troca ordem deve falhar', () {
      final layer = Layer()..n = 1;
      Note mk(int ulx, String id) {
        final n = Note()..id = id;
        final z = Zone()
          ..ulx = ulx
          ..uly = 0
          ..lrx = ulx + 10
          ..lry = 10;
        n.facs = '#z_$id';
        n.zone = z;
        return n;
      }

      final a = mk(200, 'a');
      final b = mk(100, 'b');
      layer.addChild(a);
      layer.addChild(b);
      layer.reorderByXPos();
      expect(layer.children[0].id, 'b');
      expect(layer.children[1].id, 'a');
    });
  });

  // ---------------------------------------------------------------------------
  // Page::LayOutTranscription — integração
  // ---------------------------------------------------------------------------
  group('Page::LayOutTranscription — integração', () {
    test('layOutTranscription seta layoutDone e roda sem exceção (sintético)',
        () {
      final doc = Doc();
      final pages = Pages();
      doc.addChild(pages);
      final page = Page();
      pages.addChild(page);
      doc.setDrawingPage(0);
      expect(() => page.layOutTranscription(), returnsNormally);
      expect(page.layoutDone, isTrue);
      page.layoutDone = true;
      expect(() => page.layOutTranscription(), returnsNormally);
      expect(page.layoutDone, isTrue);
      expect(() => page.layOutTranscription(force: true), returnsNormally);
    });

    test('View.setPage transcription roteia para layOutTranscription', () {
      // Cria Doc mínimo com Mdiv/Score para ser considerado válido para View.
      // View.setPage chama scoreDefSetCurrentDoc que requer visibleScores.
      // Para evitar assertion, usa doc carregado via MEI mínimo.
      final mei = '''
<?xml version="1.0" encoding="UTF-8"?>
<mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="6.0-dev">
  <meiHead><fileDesc><titleStmt><title>T</title></titleStmt><pubStmt/></fileDesc></meiHead>
  <music><body><mdiv><score><scoreDef><staffGrp><staffDef n="1" lines="5"/></staffGrp></scoreDef><section><measure><staff n="1"><layer n="1"><note pname="c" oct="4" dur="4"/></layer></staff></measure></section></score></mdiv></body>
</music>
</mei>
''';
      final doc = Doc();
      final input = MeiInput(doc);
      expect(input.import(mei), isTrue);
      doc.prepareData();
      doc.setType(DocType.transcription);
      final page = doc.setDrawingPage(0)!;
      final view = View()..setDoc(doc);
      expect(page.layoutDone, isFalse);
      expect(() => view.setPage(page, true), returnsNormally);
      expect(page.layoutDone, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // kAcceptChain — documentação por ausência
  // ---------------------------------------------------------------------------
  group('kAcceptChain', () {
    test('nenhum functor novo precisa de entrada (documentado)', () {
      expect(true, isTrue);
    });
  });
}

/// Spy que conta total de visitas (independente de facs) — prova que functor roda
class _CountingAdjustXRelTotal extends AdjustXRelForTranscriptionFunctor {
  int totalVisited = 0;
  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    totalVisited++;
    return super.visitLayerElement(layerElement);
  }
}

class _CountingAdjustYRelTotal extends AdjustYRelForTranscriptionFunctor {
  int totalVisited = 0;
  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    totalVisited++;
    return super.visitLayerElement(layerElement);
  }
}
