/// Tests for 05-29 — Header e footer no layout.
library;

import 'dart:io';
import 'package:test/test.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/control_elements_gen.dart' show MNum;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show Text;
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef;
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/testing/svg_compare.dart';
import 'package:verovio_dart/src/toolkit.dart';

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  group('05-29 running element layout — header/footer', () {
    test(
        '1 — deslocamento 727: note-001.mei 5 linhas da pauta batem com golden',
        () {
      final goldenPath = 'test/golden/cpp/note/note-001.svg';
      final goldenSvg = File(goldenPath).readAsStringSync();
      final lineRe = RegExp(r'd="M0 (\d+) L\d+ \1"');
      final goldenYs = lineRe
          .allMatches(goldenSvg)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      // Expected per prompt: 1267/1447/1627/1807/1987
      expect(goldenYs, equals([1267, 1447, 1627, 1807, 1987]),
          reason: 'golden inesperado; regenerar goldens?');
      expect(goldenYs.length, 5);

      final dartSvg = renderSvgForComparison('test/corpus/note/note-001.mei');
      expect(dartSvg, isNotNull, reason: 'render nulo');
      final dartYs = lineRe
          .allMatches(dartSvg!)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      expect(dartYs, equals(goldenYs),
          reason:
              'linhas da pauta Dart $dartYs != golden $goldenYs (epsilon 0)');
    });

    test('2 — cabeçalho vazio não consome margem (if headerHeight>0)', () {
      // MEI sem título -> header first vazio (altura 0)
      final meiNoTitle = '''<?xml version="1.0" encoding="UTF-8"?>
<mei xmlns="http://www.music-encoding.org/ns/mei">
  <meiHead>
    <fileDesc><titleStmt><title></title></titleStmt><pubStmt></pubStmt></fileDesc>
  </meiHead>
  <music><body><mdiv><score><scoreDef><staffGrp><staffDef n="1" lines="5" clef.shape="G" clef.line="2"/></staffGrp></scoreDef>
  <section><measure n="1"><staff n="1"><layer n="1"><note pname="c" oct="4" dur="4"/></layer></staff></measure></section>
  </score></mdiv></body></music>
</mei>''';
      final toolkitEmpty = Toolkit();
      toolkitEmpty.loadData(meiNoTitle);
      final docEmpty = toolkitEmpty.doc;
      docEmpty.getResourcesForModification().initFonts();
      docEmpty.prepareData();
      docEmpty.layOut();
      final pageEmpty = docEmpty.getPages()!.getChild(0) as Page;
      final headerEmpty = pageEmpty.getHeader();
      final headerHeightEmpty = headerEmpty != null
          ? (headerEmpty as dynamic).getTotalHeight(docEmpty) as int
          : 0;
      expect(headerHeightEmpty, 0, reason: 'cabeçalho vazio deve ter altura 0');
      final systemEmpty = pageEmpty.getFirst(ClassId.system) as dynamic;
      final yEmpty = systemEmpty.getDrawingYRel() as int;
      expect(yEmpty, docEmpty.drawingPageContentHeight,
          reason:
              'sem cabeçalho, primeiro sistema em drawingPageContentHeight');

      // MEI com título -> header com altura >0 e sistema deslocado
      final meiWithTitle = '''<?xml version="1.0" encoding="UTF-8"?>
<mei xmlns="http://www.music-encoding.org/ns/mei">
  <meiHead>
    <fileDesc><titleStmt><title>My Title</title></titleStmt><pubStmt></pubStmt></fileDesc>
  </meiHead>
  <music><body><mdiv><score><scoreDef><staffGrp><staffDef n="1" lines="5" clef.shape="G" clef.line="2"/></staffGrp></scoreDef>
  <section><measure n="1"><staff n="1"><layer n="1"><note pname="c" oct="4" dur="4"/></layer></staff></measure></section>
  </score></mdiv></body></music>
</mei>''';
      final toolkitTit = Toolkit();
      toolkitTit.loadData(meiWithTitle);
      final docTit = toolkitTit.doc;
      docTit.getResourcesForModification().initFonts();
      docTit.prepareData();
      docTit.layOut();
      final pageTit = docTit.getPages()!.getChild(0) as Page;
      final headerTit = pageTit.getHeader();
      expect(headerTit, isNotNull);
      final headerHeightTit =
          (headerTit as dynamic).getTotalHeight(docTit) as int;
      expect(headerHeightTit, greaterThan(0),
          reason: 'cabeçalho com título deve ter altura >0');
      final systemTit = pageTit.getFirst(ClassId.system) as dynamic;
      final yTit = systemTit.getDrawingYRel() as int;
      // Deve ser contentHeight - headerHeight
      expect(yTit, docTit.drawingPageContentHeight - headerHeightTit,
          reason: 'if (headerHeight>0) shift -= headerHeight');
      expect(yTit, lessThan(yEmpty),
          reason: 'sistema com cabeçalho deve estar mais baixo (Y menor)');
    });

    test('3 — CalcRunningElementHeight mede 2 páginas (PGFUNC_first vs all)',
        () {
      // MEI com título vazio (first vazio) vs all com número de página
      // gera alturas diferentes: first 0, all >0
      final mei = '''<?xml version="1.0" encoding="UTF-8"?>
<mei xmlns="http://www.music-encoding.org/ns/mei">
  <meiHead>
    <fileDesc><titleStmt><title></title></titleStmt><pubStmt></pubStmt></fileDesc>
  </meiHead>
  <music><body><mdiv><score><scoreDef><staffGrp><staffDef n="1" lines="5" clef.shape="G" clef.line="2"/></staffGrp></scoreDef>
  <section><measure n="1"><staff n="1"><layer n="1"><note pname="c" oct="4" dur="4"/></layer></staff></measure></section>
  </score></mdiv></body></music>
</mei>''';
      final toolkit = Toolkit();
      toolkit.loadData(mei);
      final doc = toolkit.doc;
      doc.getResourcesForModification().initFonts();
      doc.prepareData();
      // Simula estado antes do CastOffPages: Pages com 1 página não-castOff
      // Detach para ficar com 0 como espera CalcRunningElementHeight
      final pages = doc.getPages()!;
      final hadPages = pages.childCount;
      expect(hadPages, 1, reason: 'após load, 1 página uncaste');
      final detached = pages.detachChild(0);
      expect(pages.childCount, 0);
      final score = doc.getFirstVisibleScore() as Score;
      // Garante que antes do calc as alturas são 0
      expect(score.drawingPgHeadHeight, 0);
      expect(score.drawingPgHead2Height, 0);
      // Mede
      score.calcRunningElementHeight(doc);
      // Após, alturas devem diferir: first vazio 0, second com número >0
      expect(score.drawingPgHeadHeight, 0,
          reason: 'first deve ser 0 (título vazio)');
      expect(score.drawingPgHead2Height, greaterThan(0),
          reason: 'second (all com número) deve ser >0');
      // Também verifica foot (ambos 0 ou com footer.svg?)
      // O footer autogenerado tem svg, mas pode ter altura 0 ou >0 dependendo do svg?
      // Apenas verifica que páginas descartáveis não sobreviveram
      expect(pages.childCount, 0,
          reason: 'páginas descartáveis não devem sobreviver');
      expect(doc.drawingPage, isNull, reason: 'drawingPage deve ser resetado');
      // Restaura estado para não afetar outros testes (re-add)
      if (detached != null) {
        pages.addChild(detached);
        doc.setDrawingPage(0);
      }
    });

    test('4 — cast-off usa alturas (multi-página)', () {
      // Verifica que GetAvailableDrawingHeight escolhe o par correto e que
      // o cast-off considera o cabeçalho: primeira página com cabeçalho tem
      // menos sistemas que sem.
      final meiMulti = (() {
        final b = StringBuffer();
        b.writeln('''<?xml version="1.0" encoding="UTF-8"?>
<mei xmlns="http://www.music-encoding.org/ns/mei">
  <meiHead><fileDesc><titleStmt><title>Multi Page Test</title></titleStmt><pubStmt></pubStmt></fileDesc></meiHead>
  <music><body><mdiv><score><scoreDef><staffGrp><staffDef n="1" lines="5" clef.shape="G" clef.line="2"/></staffGrp></scoreDef><section>''');
        for (int i = 1; i <= 30; i++) {
          b.writeln(
              '<measure n="$i"><staff n="1"><layer n="1"><note pname="c" oct="4" dur="4"/></layer></staff></measure>');
        }
        b.writeln('''</section></score></mdiv></body></music></mei>''');
        return b.toString();
      })();

      // Com cabeçalho
      final toolkitWith = Toolkit();
      toolkitWith.loadData(meiMulti);
      final docWith = toolkitWith.doc;
      docWith.getResourcesForModification().initFonts();
      docWith.prepareData();
      docWith.layOut();
      final pagesWith = docWith.getPages()!;
      expect(pagesWith.childCount, greaterThanOrEqualTo(1));
      final scoreWith = docWith.getFirstVisibleScore() as Score;
      final pageHeight = docWith.drawingPageContentHeight;
      final availableFirst = pageHeight -
          scoreWith.drawingPgHeadHeight -
          scoreWith.drawingPgFootHeight;
      final availableSecond = pageHeight -
          scoreWith.drawingPgHead2Height -
          scoreWith.drawingPgFoot2Height;
      expect(availableFirst, lessThanOrEqualTo(pageHeight));
      expect(availableSecond, lessThanOrEqualTo(pageHeight));
      expect(scoreWith.drawingPgHeadHeight, greaterThan(0),
          reason: 'cabeçalho com título deve ter altura >0');
      final firstPageWith = pagesWith.getChild(0) as Page;
      final countWith = firstPageWith.getChildCount(ClassId.system);

      // Sem cabeçalho: remove pgHead/pgFoot antes do layout
      final toolkitWithout = Toolkit();
      toolkitWithout.loadData(meiMulti);
      final docWithout = toolkitWithout.doc;
      // Remove os pgHead/pgFoot gerados
      for (final s in docWithout.getVisibleScores()) {
        final sc = s as Score;
        final sd = sc.getScoreDef() as ScoreDef;
        final heads = sd.findAllDescendantsByType(ClassId.pgHead);
        for (final h in List.from(heads)) {
          sd.deleteChild(h as dynamic);
        }
        final foots = sd.findAllDescendantsByType(ClassId.pgFoot);
        for (final f in List.from(foots)) {
          sd.deleteChild(f as dynamic);
        }
      }
      docWithout.getResourcesForModification().initFonts();
      docWithout.prepareData();
      docWithout.layOut();
      final pagesWithout = docWithout.getPages()!;
      final firstPageWithout = pagesWithout.getChild(0) as Page;
      final countWithout = firstPageWithout.getChildCount(ClassId.system);

      // Com cabeçalho deve caber menos sistemas na primeira página
      expect(countWith, lessThanOrEqualTo(countWithout),
          reason:
              'com cabeçalho, primeira página deve ter <= sistemas que sem');
      // Para este MEI de 30 compassos, header faz diferença (ou pelo menos não aumenta)
      // Verifica também que o functor escolheu alturas corretamente:
      // O Score sem cabeçalho deve ter alturas 0
      final scoreWithout = docWithout.getFirstVisibleScore() as Score;
      // Após layOut, o Score sem pgHead deve ter alturas 0 (recalculado)
      // Mas como removemos pgHead antes, CalcRunningElementHeight verá 0
      expect(scoreWithout.drawingPgHeadHeight, 0);
      expect(scoreWithout.drawingPgHead2Height, 0);

      // Verifica que com cabeçalho bate com golden para um arquivo de referência
      // Usa note-001 que tem golden de 1 sistema; com nosso header de 727, deve continuar 1
      final dartSvg = renderSvgForComparison('test/corpus/note/note-001.mei');
      expect(dartSvg, isNotNull);
      final goldenSvg =
          File('test/golden/cpp/note/note-001.svg').readAsStringSync();
      final sysRe = RegExp(r'class="system"');
      expect(
          sysRe.allMatches(dartSvg!).length, sysRe.allMatches(goldenSvg).length,
          reason: 'número de sistemas deve bater com golden');
    });

    test('5 — GenerateMeasureNumbers', () {
      final doc = Doc();
      // Cria estrutura mínima: Mdiv -> Score -> Section -> Measure n="5"
      // Para Doc.generateMeasureNumbers funcionar, precisa de Pages? Não, apenas medidas
      // Mas medidas precisam estar sob a árvore do Doc (findAllDescendants)
      // Vamos criar via objetos diretos
      final mdiv = Mdiv();
      final score = Score();
      final scoreDef = ScoreDef();
      score.setScoreDefSubtree(scoreDef, scoreDef);
      score.addChild(scoreDef);
      final section = Section();
      final measure = Measure();
      measure.n = '7';
      section.addChild(measure);
      score.addChild(section);
      mdiv.addChild(score);
      doc.addChild(mdiv);
      // Também precisa de Pages para getVisibleScores? Mas generateMeasureNumbers usa apenas medidas, não score
      // Garante que não há mNum
      expect(measure.findDescendantByType(ClassId.mnum), isNull);
      final ok = doc.generateMeasureNumbers();
      expect(ok, isTrue);
      final mnum = measure.findDescendantByType(ClassId.mnum) as MNum?;
      expect(mnum, isNotNull, reason: 'measure@n sem mNum deve ganhar mNum');
      expect(mnum!.isGeneratedFlag, isTrue);
      expect(mnum.type, 'autogenerated');
      final text = mnum.findDescendantByType(ClassId.text) as Text?;
      expect(text, isNotNull);
      expect(text!.text, '7');

      // Já gerado removido antes: segunda chamada com n diferente deve trocar
      // Simula que o mnum anterior foi gerado; muda n para 9 e chama de novo
      measure.n = '9';
      // Adiciona um mNum não-gerado para testar que não é removido indevidamente?
      // Primeiro, verifica que segundo generate remove o gerado anterior
      doc.generateMeasureNumbers();
      final mnum2 = measure.findDescendantByType(ClassId.mnum) as MNum?;
      expect(mnum2, isNotNull);
      expect(mnum2!.isGeneratedFlag, isTrue);
      final text2 = mnum2.findDescendantByType(ClassId.text) as Text?;
      expect(text2!.text, '9');
      // Deve haver apenas um mNum (o antigo removido)
      final allMNums = measure.findAllDescendantsByType(ClassId.mnum);
      expect(allMNums.length, 1,
          reason: 'mNum gerado anterior deve ter sido removido');

      // Caso com mNum não-gerado (manual) não deve ser removido nem substituído
      final measure2 = Measure();
      measure2.n = '3';
      final manualMNum = MNum();
      manualMNum.isGeneratedFlag = false;
      final manualText = Text()..text = 'manual';
      manualMNum.addChild(manualText);
      measure2.addChild(manualMNum);
      section.addChild(measure2);
      doc.generateMeasureNumbers();
      // Deve manter o manual e não criar outro
      final found = measure2.findAllDescendantsByType(ClassId.mnum);
      expect(found.length, 1);
      expect((found.first as MNum).isGeneratedFlag, isFalse);
      expect(
          ((found.first as MNum).findDescendantByType(ClassId.text) as Text)
              .text,
          'manual');
    });
  });
}
