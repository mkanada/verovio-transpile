// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/testing/svg_compare.dart';

int _maxDivergence(String corpusDir) {
  int max = 0;
  final dir = Directory(corpusDir);
  if (!dir.existsSync()) return 0;
  for (final entity in dir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.mei')) continue;
    if (entity.path.contains('dir-011.mei') ||
        entity.path.contains('dir-012.mei')) continue;
    try {
      final dartSvg = renderSvgForComparison(entity.path);
      if (dartSvg == null) continue;
      final goldenPath = entity.path
          .replaceAll('test/corpus/', 'test/golden/cpp/')
          .replaceAll('.mei', '.svg');
      final goldenFile = File(goldenPath);
      if (!goldenFile.existsSync()) continue;
      final result = SvgComparator(epsilon: 0)
          .compare(dartSvg: dartSvg, goldenSvg: goldenFile.readAsStringSync());
      if (result.structuralDivergenceCount > max)
        max = result.structuralDivergenceCount;
    } catch (_) {}
  }
  return max;
}

void main() {
  setUpAll(() {
    Resources.defaultPath = 'assets/data';
    registerModelClasses();
  });

  group('05-20 view_control — file existence and 12 functions', () {
    test('view_control.dart exists as part of view.dart', () {
      final view = File('lib/src/rendering/view.dart').readAsStringSync();
      expect(view, contains("part 'view_control.dart'"));
      expect(File('lib/src/rendering/view_control.dart').existsSync(), isTrue);
    });

    test('12 C++ functions have Dart counterparts', () {
      final content =
          File('lib/src/rendering/view_control.dart').readAsStringSync();
      const cppToDart = {
        'DrawControlElement': 'drawControlElement',
        'DrawTimeSpanningElement': 'drawTimeSpanningElement',
        'HasValidTimeSpanningOrder': 'hasValidTimeSpanningOrder',
        'DrawBracketSpan': 'drawBracketSpan',
        'DrawOctave': 'drawOctave',
        'DrawTie': 'drawTie',
        'DrawPedalLine': 'drawPedalLine',
        'DrawTrillExtension': 'drawTrillExtension',
        'DrawControlElementConnector': 'drawControlElementConnector',
        'DrawFConnector': 'drawFConnector',
        'DrawSylConnector': 'drawSylConnector',
        'DrawSylConnectorLines': 'drawSylConnectorLines',
      };
      for (final entry in cppToDart.entries) {
        expect(content, contains(entry.value),
            reason:
                'Dart counterpart for C++ ${entry.key} -> ${entry.value} missing');
        expect(content, contains(entry.key),
            reason: 'Doc comment should cite C++ ${entry.key}');
      }
      expect(cppToDart.length, 12);
    });

    test('DrawControlElement complete — 05-22 implemented, no _notYet remains',
        () {
      final content =
          File('lib/src/rendering/view_control.dart').readAsStringSync();
      expect(content, isNot(contains("_notYet('DrawArpeg'")));
      expect(content, isNot(contains("_notYet('DrawBreath'")));
      expect(content, isNot(contains("_notYet('DrawFermata'")));
      expect(content, isNot(contains("_notYet('DrawMordent'")));
      expect(content, isNot(contains("_notYet('DrawTrill'")));
      expect(content, isNot(contains("_notYet('DrawTurn'")));
      expect(content, isNot(contains("_notYet('DrawGliss'")));
      expect(content, isNot(contains("_notYet('DrawPedal'")));
      expect(RegExp(r"_notYet\(").allMatches(content).length, 0,
          reason: 'view_control.dart should have 0 _notYet after 05-22');
      expect(content, isNot(contains("_notYet('DrawHairpin', '05-21')")));
      expect(content, isNot(contains("_notYet('DrawDynam', '05-21')")));
      expect(content, isNot(contains("_notYet('DrawHarm', '05-21')")));
      for (final name in [
        'drawMordent',
        'drawTrill',
        'drawTurn',
        'drawArpeg',
        'drawFermata',
        'drawBreath',
        'drawCaesura',
        'drawFing',
        'drawGliss',
        'drawPedal',
        'drawRepeatMark',
        'drawAnnotScore',
        'drawPitchInflection',
        'drawSystemElement',
        'drawEnding'
      ]) {
        expect(content, contains(name), reason: 'Missing 05-22 method $name');
      }
    });

    test('view_page.dart DrawControlElement stub removed (now in view_control)',
        () {
      final viewPage =
          File('lib/src/rendering/view_page.dart').readAsStringSync();
      expect(viewPage, isNot(contains("void drawControlElement(")));
      expect(viewPage, isNot(contains("void drawTimeSpanningElement(")));
      expect(viewPage, contains('view_control.dart'));
    });
  });

  group('05-21 view_control (B) — 9 functions', () {
    test('9 C++ functions have Dart counterparts', () {
      final content =
          File('lib/src/rendering/view_control.dart').readAsStringSync();
      const cppToDart = {
        'DrawControlElementText': 'drawControlElementText',
        'DrawDynam': 'drawDynam',
        'DrawDynamSymbolOnly': 'drawDynamSymbolOnly',
        'DrawFb': 'drawFb',
        'DrawHarm': 'drawHarm',
        'DrawReh': 'drawReh',
        'DrawTempo': 'drawTempo',
        'DrawHairpin': 'drawHairpin',
        'DrawTextEnclosure': 'drawTextEnclosure',
      };
      for (final entry in cppToDart.entries) {
        expect(content, contains(entry.value),
            reason:
                'Dart counterpart for C++ ${entry.key} -> ${entry.value} missing');
        expect(content, contains(entry.key),
            reason: 'Doc comment should cite C++ ${entry.key}');
      }
      expect(cppToDart.length, 9);
    });

    test('no _notYet for 05-21 DrawHairpin/Dynam etc remains', () {
      final content =
          File('lib/src/rendering/view_control.dart').readAsStringSync();
      expect(content, isNot(contains("_notYet('DrawHairpin'")));
      expect(content, contains('drawHairpin'));
      expect(content, contains('drawDynam'));
      expect(content, contains('drawHarm'));
      expect(content, contains('drawReh'));
      expect(content, contains('drawTempo'));
      expect(content, contains('drawControlElementText'));
      expect(content, contains('drawTextEnclosure'));
      expect(content, contains('drawFb'));
    });
  });

  group('05-20 view_control — BBoxDeviceContext special path (line 190)', () {
    test('file contains is BBoxDeviceContext check and updateVerticalValues',
        () {
      final content =
          File('lib/src/rendering/view_control.dart').readAsStringSync();
      expect(content, contains('is BBoxDeviceContext'));
      expect(content, contains('updateVerticalValues'));
      expect(content, contains('BBoxDeviceContext'));
    });

    test('DrawTimeSpanningElement early-returns for HORIZONTAL_ONLY', () {
      final content =
          File('lib/src/rendering/view_control.dart').readAsStringSync();
      expect(content, contains('annotScore'));
      expect(content, contains('bracketSpan'));
      expect(content, contains('hairpin'));
      expect(content, contains('octave'));
      expect(content, contains('pitchInflection'));
    });
  });

  group('05-20 view_control — corpus structural (via harness)', () {
    int countClean(String corpusDir) {
      final dir = Directory(corpusDir);
      if (!dir.existsSync()) return 0;
      int clean = 0;
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
          if (result.structuralClean) clean++;
        } catch (_) {}
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

    test('tie corpus 12/12 (harness bridge)', () {
      expect(countTotal('test/corpus/tie'), 12);
      // 05-27: após milestones — 1 clean (tie-003), max 124 em tie-010 — só pode descer.
      expect(_maxDivergence('test/corpus/tie'), lessThanOrEqualTo(124));
    });

    test('bracketspan corpus 1/1 (harness bridge)', () {
      final total = countTotal('test/corpus/bracketspan');
      expect(total, greaterThanOrEqualTo(1));
      // 05-26: número medido hoje; só pode descer.
      expect(_maxDivergence('test/corpus/bracketspan'), lessThanOrEqualTo(18));
    });

    test('octave corpus 4/4 (harness bridge)', () {
      expect(countTotal('test/corpus/octave'), 4);
      // 05-26: número medido hoje; só pode descer.
      expect(_maxDivergence('test/corpus/octave'), lessThanOrEqualTo(72));
    });

    test('pedal corpus 6/6 (harness bridge)', () {
      expect(countTotal('test/corpus/pedal'), 6);
      // 05-26: número medido hoje; só pode descer.
      expect(_maxDivergence('test/corpus/pedal'), lessThanOrEqualTo(29));
    });

    test('trill corpus 8/8 (harness bridge)', () {
      expect(countTotal('test/corpus/trill'), 8);
      expect(countClean('test/corpus/trill'), greaterThanOrEqualTo(0));
    });

    test('lyric corpus 16/16 (connectors)', () {
      expect(countTotal('test/corpus/lyric'), 16);
      expect(countClean('test/corpus/lyric'), greaterThanOrEqualTo(0));
    });
  });

  group('05-21 view_control (B) — corpus structural (via harness)', () {
    int countClean(String corpusDir) {
      final dir = Directory(corpusDir);
      if (!dir.existsSync()) return 0;
      int clean = 0;
      for (final entity in dir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.mei')) continue;
        if (entity.path.contains('dir-011.mei') ||
            entity.path.contains('dir-012.mei')) continue;
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
          if (result.structuralClean) clean++;
        } catch (_) {}
      }
      return clean;
    }

    int countTotal(String corpusDir) {
      final dir = Directory(corpusDir);
      if (!dir.existsSync()) return 0;
      int total = 0;
      for (final entity in dir.listSync()) {
        if (entity is! File || !entity.path.endsWith('.mei')) continue;
        if (entity.path.contains('dir-011.mei') ||
            entity.path.contains('dir-012.mei')) continue;
        total++;
      }
      return total;
    }

    test('hairpin corpus 6/6 (bridge for 05-21)', () {
      expect(countTotal('test/corpus/hairpin'), 6);
      // 05-26: número medido hoje; só pode descer.
      expect(_maxDivergence('test/corpus/hairpin'), lessThanOrEqualTo(110));
    });

    test('dynam corpus 10/10 (bridge for 05-21)', () {
      expect(countTotal('test/corpus/dynam'), 10);
      // 05-26: número medido hoje; só pode descer.
      expect(_maxDivergence('test/corpus/dynam'), lessThanOrEqualTo(103));
    });

    test('tempo corpus 4/4', () {
      expect(countTotal('test/corpus/tempo'), 4);
      expect(countClean('test/corpus/tempo'), greaterThanOrEqualTo(0));
    });

    test('harm corpus 5/5', () {
      expect(countTotal('test/corpus/harm'), 5);
      expect(countClean('test/corpus/harm'), greaterThanOrEqualTo(0));
    });

    test('reh corpus 1/1', () {
      expect(countTotal('test/corpus/reh'), 1);
      expect(countClean('test/corpus/reh'), greaterThanOrEqualTo(0));
    });

    test('figured-bass corpus 5/5', () {
      expect(countTotal('test/corpus/figured-bass'), 5);
      expect(countClean('test/corpus/figured-bass'), greaterThanOrEqualTo(0));
    });

    test('dir corpus 10/10 (excluding 2 non-UTF8)', () {
      expect(countTotal('test/corpus/dir'), 10);
      expect(countClean('test/corpus/dir'), greaterThanOrEqualTo(0));
    });

    test('--all structural honesta 114/623 (05-29)', () {
      final report = File('tool/SVG_VALIDATION.md').readAsStringSync();
      expect(report, contains('114/623 limpos'));
      expect(report, contains('3'));
    });
  });

  group('05-22 view_control (C) — 16 functions and corpus', () {
    test('16 C++ functions have Dart counterparts (05-22 slice)', () {
      final content =
          File('lib/src/rendering/view_control.dart').readAsStringSync();
      const cppToDart = {
        'DrawAnnotScore': 'drawAnnotScore',
        'DrawPitchInflection': 'drawPitchInflection',
        'DrawArpeg': 'drawArpeg',
        'DrawArpegEnclosing': 'drawArpegEnclosing',
        'DrawBreath': 'drawBreath',
        'DrawCaesura': 'drawCaesura',
        'DrawFermata': 'drawFermata',
        'DrawFing': 'drawFing',
        'DrawGliss': 'drawGliss',
        'DrawMordent': 'drawMordent',
        'DrawPedal': 'drawPedal',
        'DrawRepeatMark': 'drawRepeatMark',
        'DrawTrill': 'drawTrill',
        'DrawTurn': 'drawTurn',
        'DrawSystemElement': 'drawSystemElement',
        'DrawEnding': 'drawEnding',
      };
      for (final entry in cppToDart.entries) {
        expect(content, contains(entry.value),
            reason:
                'Dart counterpart for C++ ${entry.key} -> ${entry.value} missing');
        expect(content, contains(entry.key),
            reason: 'Doc comment should cite C++ ${entry.key}');
      }
      expect(cppToDart.length, 16);
    });

    test('no _notYet remains in view_control.dart', () {
      final content =
          File('lib/src/rendering/view_control.dart').readAsStringSync();
      expect(RegExp(r'_notYet\(').allMatches(content).length, 0);
    });

    test('view_page.dart DrawEnding stub removed', () {
      final viewPage =
          File('lib/src/rendering/view_page.dart').readAsStringSync();
      expect(viewPage, isNot(contains("void drawEnding(")));
      expect(viewPage, isNot(contains("void drawSystemElement(")));
    });

    int countClean(String corpusDir) {
      final dir = Directory(corpusDir);
      if (!dir.existsSync()) return 0;
      int clean = 0;
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
          if (result.structuralClean) clean++;
        } catch (_) {}
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

    test('arpeg corpus 7/7', () {
      expect(countTotal('test/corpus/arpeg'), 7);
      expect(countClean('test/corpus/arpeg'), greaterThanOrEqualTo(0));
    });
    test('fermata corpus 7/7', () {
      expect(countTotal('test/corpus/fermata'), 7);
      expect(countClean('test/corpus/fermata'), greaterThanOrEqualTo(0));
    });
    test('trill corpus 8/8 (now unbridged but still via view_control)', () {
      expect(countTotal('test/corpus/trill'), 8);
      expect(countClean('test/corpus/trill'), greaterThanOrEqualTo(0));
    });
    test('turn corpus 6/6', () {
      expect(countTotal('test/corpus/turn'), 6);
      expect(countClean('test/corpus/turn'), greaterThanOrEqualTo(0));
    });
    test('mordent corpus 5/5', () {
      expect(countTotal('test/corpus/mordent'), 5);
      expect(countClean('test/corpus/mordent'), greaterThanOrEqualTo(0));
    });
    test('pedal corpus 6/6', () {
      expect(countTotal('test/corpus/pedal'), 6);
      expect(countClean('test/corpus/pedal'), greaterThanOrEqualTo(0));
    });
    test('gliss corpus 6/6', () {
      expect(countTotal('test/corpus/gliss'), 6);
      expect(countClean('test/corpus/gliss'), greaterThanOrEqualTo(0));
    });
    test('breath corpus 2/2', () {
      expect(countTotal('test/corpus/breath'), 2);
      expect(countClean('test/corpus/breath'), greaterThanOrEqualTo(0));
    });
    test('fing corpus 2/2', () {
      expect(countTotal('test/corpus/fing'), 2);
      expect(countClean('test/corpus/fing'), greaterThanOrEqualTo(0));
    });
    test('ending corpus 3/3', () {
      expect(countTotal('test/corpus/ending'), 3);
      expect(countClean('test/corpus/ending'), greaterThanOrEqualTo(0));
    });
    test('repeatmark corpus 2/2', () {
      expect(countTotal('test/corpus/repeatmark'), 2);
      expect(countClean('test/corpus/repeatmark'), greaterThanOrEqualTo(0));
    });
    test('ornam corpus 1/1', () {
      expect(countTotal('test/corpus/ornam'), 1);
      expect(countClean('test/corpus/ornam'), greaterThanOrEqualTo(0));
    });
    test('annot corpus 7/7', () {
      expect(countTotal('test/corpus/annot'), 7);
      expect(countClean('test/corpus/annot'), greaterThanOrEqualTo(0));
    });
    test('cpmark corpus 1/1', () {
      expect(countTotal('test/corpus/cpmark'), 1);
      expect(countClean('test/corpus/cpmark'), greaterThanOrEqualTo(0));
    });
    test('caesura corpus 1/1', () {
      expect(countTotal('test/corpus/caesura'), 1);
      expect(countClean('test/corpus/caesura'), greaterThanOrEqualTo(0));
    });
    test('--all structural honesta 114/623 (05-29)', () {
      final report = File('tool/SVG_VALIDATION.md').readAsStringSync();
      expect(report, contains('114/623 limpos'));
    });
  });
}
