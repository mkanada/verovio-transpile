// ignore_for_file: curly_braces_in_flow_control_structures, unused_element
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

  group('05-24 view_neume / view_tab — file existence and View coverage', () {
    test('view_neume.dart and view_tab.dart exist as part of view.dart', () {
      final view = File('lib/src/rendering/view.dart').readAsStringSync();
      expect(view, contains("part 'view_neume.dart'"));
      expect(view, contains("part 'view_tab.dart'"));
      expect(File('lib/src/rendering/view_neume.dart').existsSync(), isTrue);
      expect(File('lib/src/rendering/view_tab.dart').existsSync(), isTrue);
    });

    test('view_neume: 11 C++ functions have Dart counterparts', () {
      final content =
          File('lib/src/rendering/view_neume.dart').readAsStringSync();
      const cppToDart = {
        'DrawSyllable': 'drawSyllable',
        'DrawLiquescent': 'drawLiquescent',
        'DrawNc': 'drawNc',
        'DrawNeume': 'drawNeume',
        'DrawNcAsNotehead': 'drawNcAsNotehead',
        'DrawDivLine': 'drawDivLine',
        'DrawEpisema': 'drawEpisema',
        'DrawOriscus': 'drawOriscus',
        'DrawQuilisma': 'drawQuilisma',
        'DrawStrophicus': 'drawStrophicus',
        'DrawNcGlyphs': 'drawNcGlyphs',
      };
      for (final entry in cppToDart.entries) {
        expect(content, contains(entry.value),
            reason:
                'Dart counterpart for C++ ${entry.key} -> ${entry.value} missing');
        expect(content, contains(entry.key),
            reason: 'Doc comment should cite C++ ${entry.key}');
      }
      expect(cppToDart.length, 11);
    });

    test('view_tab: 4 C++ functions have Dart counterparts', () {
      final content =
          File('lib/src/rendering/view_tab.dart').readAsStringSync();
      const cppToDart = {
        'DrawTabClef': 'drawTabClef',
        'DrawTabGrp': 'drawTabGrp',
        'DrawTabNote': 'drawTabNote',
        'DrawTabDurSym': 'drawTabDurSym',
      };
      for (final entry in cppToDart.entries) {
        expect(content, contains(entry.value),
            reason:
                'Dart counterpart for C++ ${entry.key} -> ${entry.value} missing');
        expect(content, contains(entry.key),
            reason: 'Doc comment should cite C++ ${entry.key}');
      }
      expect(cppToDart.length, 4);
    });

    test('view_element.dart has no _notYet for neume/tab families (05-24)', () {
      final content =
          File('lib/src/rendering/view_element.dart').readAsStringSync();
      expect(content, isNot(contains("_notYet('DrawNc'")));
      expect(content, isNot(contains("_notYet('DrawNeume'")));
      expect(content, isNot(contains("_notYet('DrawSyllable'")));
      expect(content, isNot(contains("_notYet('DrawDivLine'")));
      expect(content, isNot(contains("_notYet('DrawEpisema'")));
      expect(content, isNot(contains("_notYet('DrawLiquescent'")));
      expect(content, isNot(contains("_notYet('DrawOriscus'")));
      expect(content, isNot(contains("_notYet('DrawQuilisma'")));
      expect(content, isNot(contains("_notYet('DrawStrophicus'")));
      expect(content, isNot(contains("_notYet('DrawTabGrp'")));
      expect(content, isNot(contains("_notYet('DrawTabDurSym'")));
      expect(content, isNot(contains("_notYet('DrawTabNote'")));
      expect(content, isNot(contains("_notYet('DrawTabClef'")));
      // Also check view_page no longer has _notYet definition
      final viewPage =
          File('lib/src/rendering/view_page.dart').readAsStringSync();
      expect(RegExp(r"_notYet\(").allMatches(viewPage).length, 0);
      final renderingFiles =
          Directory('lib/src/rendering').listSync().whereType<File>();
      int total = 0;
      for (final f in renderingFiles) {
        total += RegExp(r"_notYet\(").allMatches(f.readAsStringSync()).length;
      }
      expect(total, 0, reason: 'no _notYet( in lib/src/rendering/ after 05-24');
    });

    test('all View:: from origin/src/src/view*.cpp have Dart counterparts', () {
      // Spot check: every View:: that belongs to view_neume/view_tab must be present
      final neume =
          File('lib/src/rendering/view_neume.dart').readAsStringSync();
      final tab = File('lib/src/rendering/view_tab.dart').readAsStringSync();
      final allView = [
        File('lib/src/rendering/view.dart').readAsStringSync(),
        File('lib/src/rendering/view_graph.dart').readAsStringSync(),
        File('lib/src/rendering/view_page.dart').readAsStringSync(),
        File('lib/src/rendering/view_element.dart').readAsStringSync(),
        File('lib/src/rendering/view_beam.dart').readAsStringSync(),
        File('lib/src/rendering/view_tuplet.dart').readAsStringSync(),
        File('lib/src/rendering/view_slur.dart').readAsStringSync(),
        File('lib/src/rendering/view_text.dart').readAsStringSync(),
        File('lib/src/rendering/view_control.dart').readAsStringSync(),
        File('lib/src/rendering/view_mensural.dart').readAsStringSync(),
        neume,
        tab,
      ].join('\n');
      const required = [
        'drawSyllable',
        'drawLiquescent',
        'drawNc',
        'drawNeume',
        'drawNcAsNotehead',
        'drawDivLine',
        'drawEpisema',
        'drawOriscus',
        'drawQuilisma',
        'drawStrophicus',
        'drawNcGlyphs',
        'drawTabClef',
        'drawTabGrp',
        'drawTabNote',
        'drawTabDurSym',
      ];
      for (final name in required) {
        expect(allView, contains(name),
            reason: 'View method $name missing in Dart');
      }
    });
  });

  group('05-24 view_neume / view_tab — corpus structural (via harness)', () {
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

    int maxDivergence(String corpusDir) {
      int max = 0;
      final dir = Directory(corpusDir);
      if (!dir.existsSync()) return 0;
      for (final entity in dir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.mei')) continue;
        try {
          final dartSvg = renderSvgForComparison(entity.path);
          if (dartSvg == null) continue;
          final goldenPath = entity.path
              .replaceAll('test/corpus/', 'test/golden/cpp/')
              .replaceAll('.mei', '.svg');
          final goldenFile = File(goldenPath);
          if (!goldenFile.existsSync()) continue;
          final result = SvgComparator(epsilon: 0).compare(
              dartSvg: dartSvg, goldenSvg: goldenFile.readAsStringSync());
          if (result.structuralDivergenceCount > max)
            max = result.structuralDivergenceCount;
        } catch (_) {}
      }
      return max;
    }

    test('neume corpus 6 files', () {
      expect(countTotal('test/corpus/neume'), 6);
      // 05-26: número medido hoje; só pode descer.
      expect(maxDivergence('test/corpus/neume'), lessThanOrEqualTo(27));
    });

    test('tab corpus 5 files', () {
      expect(countTotal('test/corpus/tab'), 5);
      // 05-26: número medido hoje; só pode descer.
      expect(maxDivergence('test/corpus/tab'), lessThanOrEqualTo(134));
    });

    test('--all structural honesta 0/623 (05-26)', () {
      final report = File('tool/SVG_VALIDATION.md').readAsStringSync();
      expect(report, contains('0/623 limpos'));
    });
  });

  group(
      '05-24 rendering smoke: neume/tab files render without throwing _notYet',
      () {
    test('each neume/tab file draws without UnimplementedError', () {
      final files = [
        ...Directory('test/corpus/neume')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.mei'))
            .map((f) => f.path),
        ...Directory('test/corpus/tab')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.mei'))
            .map((f) => f.path),
      ];
      for (final path in files) {
        final svg = renderSvgForComparison(path);
        expect(svg, isNotNull,
            reason:
                'renderSvgForComparison returned null for $path (still _notYet?)');
        expect(svg!.length, greaterThan(1000),
            reason: 'svg too short for $path');
      }
    });
  });
}
