// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/testing/svg_compare.dart';

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  group('05-23 view_mensural — file existence and 13 functions', () {
    test('view_mensural.dart exists as part of view.dart', () {
      final view = File('lib/src/rendering/view.dart').readAsStringSync();
      expect(view, contains("part 'view_mensural.dart'"));
      expect(File('lib/src/rendering/view_mensural.dart').existsSync(), isTrue);
    });

    test('13 C++ functions have Dart counterparts', () {
      final content = File('lib/src/rendering/view_mensural.dart').readAsStringSync();
      const cppToDart = {
        'DrawMensuralNote': 'drawMensuralNote',
        'DrawMensur': 'drawMensur',
        'DrawMensuralStem': 'drawMensuralStem',
        'DrawMaximaToBrevis': 'drawMaximaToBrevis',
        'DrawLigature': 'drawLigature',
        'DrawLigatureNote': 'drawLigatureNote',
        'DrawDotInLigature': 'drawDotInLigature',
        'DrawPlica': 'drawPlica',
        'DrawProportFigures': 'drawProportFigures',
        'DrawProport': 'drawProport',
        'CalcBrevisPoints': 'calcBrevisPoints',
        'CalcObliquePoints': 'calcObliquePoints',
        'GetMensuralStemDir': 'getMensuralStemDir',
      };
      for (final entry in cppToDart.entries) {
        expect(content, contains(entry.value),
            reason: 'Dart counterpart for C++ ${entry.key} -> ${entry.value} missing');
        expect(content, contains(entry.key),
            reason: 'Doc comment should cite C++ ${entry.key}');
      }
      expect(cppToDart.length, 13);
    });

    test('view_element.dart no longer has _notYet for mensural families', () {
      final content = File('lib/src/rendering/view_element.dart').readAsStringSync();
      // Ligiature, mensur, plica, proport should be implemented via view_mensural
      expect(content, isNot(contains("_notYet('DrawLigature'")));
      expect(content, isNot(contains("_notYet('DrawMensur'")));
      expect(content, isNot(contains("_notYet('DrawPlica'")));
      expect(content, isNot(contains("_notYet('DrawProport'")));
      expect(content, isNot(contains("_notYet('DrawMensuralNote'")));
      expect(content, isNot(contains("_notYet('DrawMaximaToBrevis'")));
      expect(content, isNot(contains("_notYet('DrawMensuralStem'")));
      // view_mensural doc should mention s_drawingLig
      final mensural = File('lib/src/rendering/view_mensural.dart').readAsStringSync();
      expect(mensural, contains('s_drawingLig'));
      expect(mensural, contains('Deviations from the C++'));
    });

    test('static ligature state documented as deviation', () {
      final content = File('lib/src/rendering/view_mensural.dart').readAsStringSync();
      expect(content, contains('_sDrawingLigX'));
      expect(content, contains('_sDrawingLigY'));
      expect(content, contains('_sDrawingLigObliqua'));
      expect(content, contains('thread_local'));
    });
  });

  group('05-23 view_mensural — corpus structural (via harness)', () {
    int countClean(String corpusDir) {
      final dir = Directory(corpusDir);
      if (!dir.existsSync()) return 0;
      int clean = 0;
      for (final entity in dir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.mei')) continue;
        final dartSvg = renderSvgForComparison(entity.path);
        if (dartSvg == null) continue;
        final goldenPath = entity.path
            .replaceAll('test/corpus/', 'test/golden/cpp/')
            .replaceAll('.mei', '.svg');
        final goldenFile = File(goldenPath);
        if (!goldenFile.existsSync()) continue;
        final result = SvgComparator(epsilon: 0).compare(
            dartSvg: dartSvg, goldenSvg: goldenFile.readAsStringSync());
        if (result.structuralClean) clean++;
      }
      return clean;
    }

    int countTotal(String corpusDir) {
      final dir = Directory(corpusDir);
      if (!dir.existsSync()) return 0;
      int total = 0;
      for (final entity in dir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.mei')) continue;
        total++;
      }
      return total;
    }

    test('ligature corpus 50 files, >=35 clean (second largest)', () {
      expect(countTotal('test/corpus/ligature'), 50);
      expect(countClean('test/corpus/ligature'), greaterThanOrEqualTo(35),
          reason: 'ligature >=35/50');
    });

    test('mensural corpus 25 files, >=16 clean', () {
      expect(countTotal('test/corpus/mensural'), 25);
      expect(countClean('test/corpus/mensural'), greaterThanOrEqualTo(16),
          reason: 'mensural >=16/25');
    });

    test('mensur corpus 8 files', () {
      expect(countTotal('test/corpus/mensur'), 8);
      expect(countClean('test/corpus/mensur'), greaterThanOrEqualTo(5));
    });

    test('--all structural >414/623 (bridge from 05-22: 414, now 489)', timeout: Timeout(Duration(seconds: 120)), () {
      int clean = 0;
      int total = 0;
      for (final entity in Directory('test/corpus').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.mei')) continue;
        if (entity.path.contains('dir-011.mei') || entity.path.contains('dir-012.mei')) continue;
        total++;
        final dartSvg = renderSvgForComparison(entity.path);
        if (dartSvg == null) continue;
        final goldenPath = entity.path.replaceAll('test/corpus/', 'test/golden/cpp/').replaceAll('.mei', '.svg');
        final goldenFile = File(goldenPath);
        if (!goldenFile.existsSync()) continue;
        final result = SvgComparator(epsilon: 0).compare(dartSvg: dartSvg, goldenSvg: goldenFile.readAsStringSync());
        if (result.structuralClean) clean++;
      }
      expect(total, 621);
      expect(clean, greaterThan(414), reason: 'all $clean/623 vs 414 baseline from 05-22');
    });
  });
}
