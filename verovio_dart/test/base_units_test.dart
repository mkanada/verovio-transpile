/// Parity of the numeric base of Phase 4 against the instrumented C++
/// (`cpp_probe` task `04-00`): the `Doc::GetDrawingUnit` family and the
/// page-dimension options after the definition factor.
///
/// The fixtures carry one `{"fn":"Units","kind":"doc",...}` record per file
/// (emitted once per document by the instrumented `Doc::GetDrawingUnit`) and
/// one `{"fn":"Units","kind":"staff",...}` record per staff of the document
/// (emitted by the instrumented `CalcAlignmentXPosFunctor::VisitMeasure`).
/// Every number the C++ sees **after** `DEFINITION_FACTOR` must come out of
/// the Dart side with epsilon 0.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';

import 'fixtures/cpp_fixture.dart';

const String task = '04-00';

const List<String> kCorpusFiles = <String>[
  'test/corpus/note/note-001.mei',
  'test/corpus/beam/beam-001.mei',
  'test/corpus/rest/rest-001.mei',
  'test/corpus/dot/dot-001.mei',
  'test/corpus/score/score-002.mei',
];

Doc loadCorpusDoc(String path) {
  final Doc doc = Doc();
  final MeiInput input = MeiInput(doc);
  final String data =
      utf8.decode(File(path).readAsBytesSync(), allowMalformed: true);
  final bool ok = input.import(data);
  if (!ok) throw StateError('MEI import rejected: $path');
  return doc;
}

CppRecord docUnitsRecord(CppFixture fixture) =>
    fixture.single(fn: 'Units', test: (r) => r['kind'] == 'doc');

List<CppRecord> staffUnitsRecords(CppFixture fixture) =>
    fixture.where(fn: 'Units', test: (r) => r['kind'] == 'staff');

void requireEq(num actual, num expected, String what) {
  if ((actual - expected).abs() > 0) {
    fail('$what: esperado $expected, obtido $actual');
  }
}

void main() {
  setUpAll(() {
    registerModelClasses();
  });

  for (final String path in kCorpusFiles) {
    group('base de unidades — ${path.split('/').last}', () {
      late CppFixture fixture;
      late Doc doc;

      setUpAll(() {
        fixture = CppFixture.load(task, path);
        doc = loadCorpusDoc(path);
      });

      test('bloco de unidades do documento bate com o C++ (epsilon 0)', () {
        final CppRecord rec = docUnitsRecord(fixture);

        // `m_options->m_unit.GetValue()` factored.
        requireEq(doc.getOptions().unit.value, rec.require('unit'), 'unit');
        requireEq(doc.getDrawingUnit(100), rec.require('drawingUnit100'),
            'drawingUnit(100)');
        requireEq(doc.getDrawingDoubleUnit(100),
            rec.require('drawingDoubleUnit100'), 'drawingDoubleUnit(100)');
        requireEq(doc.getDrawingStaffSize(100),
            rec.require('drawingStaffSize100'), 'drawingStaffSize(100)');
        requireEq(doc.getOptions().pageWidth.value, rec.require('pageWidth'),
            'pageWidth');
        requireEq(doc.getOptions().pageHeight.value, rec.require('pageHeight'),
            'pageHeight');
        requireEq(doc.getOptions().pageMarginBottom.value,
            rec.require('pageMarginBottom'), 'pageMarginBottom');
        requireEq(doc.getOptions().pageMarginLeft.value,
            rec.require('pageMarginLeft'), 'pageMarginLeft');
        requireEq(doc.getOptions().pageMarginRight.value,
            rec.require('pageMarginRight'), 'pageMarginRight');
        requireEq(doc.getOptions().pageMarginTop.value,
            rec.require('pageMarginTop'), 'pageMarginTop');

        // The unfactored read mirrors GetUnfactoredValue(): the raw stored
        // value, which the definition factor must NOT touch.
        expect(doc.getOptions().unit.unfactoredValue, defaultUnit);
        expect(doc.getOptions().pageWidth.unfactoredValue, 2100);
      });

      test('drawingUnit por pentagrama bate com o C++ (epsilon 0)', () {
        final List<CppRecord> records = staffUnitsRecords(fixture);
        if (records.isEmpty) {
          throw CppFixtureError('${fixture.file}: nenhum registro '
              '"Units/kind=staff"');
        }

        // Resolve the drawing staff sizes the same way the C++ does before
        // the horizontal layout reads them.
        doc.prepareData();
        final List<Object?> staves =
            doc.findAllDescendantsByType(ClassId.staff);
        if (staves.isEmpty) fail('$path: nenhum staff no documento');

        final Map<String, Staff> byN = {};
        for (final Object? object in staves) {
          final Staff staff = object! as Staff;
          final String n = '${staff.n}';
          if (!byN.containsKey(n)) byN[n] = staff;
        }

        int compared = 0;
        final List<String> divergences = [];
        for (final CppRecord rec in records) {
          final String staffN = '${rec.require('staffN')}';
          final Staff? staff = byN[staffN];
          if (staff == null) {
            divergences.add('staff@$staffN: ausente no Dart');
            continue;
          }
          if (staff.drawingStaffSize != rec.require('staffSize')) {
            divergences.add('staff@$staffN: size '
                '${staff.drawingStaffSize} ≠ ${rec.require('staffSize')}');
          }
          requireEq(doc.getDrawingUnit(staff.drawingStaffSize),
              rec.require('drawingUnit'), 'staff@$staffN drawingUnit');
          requireEq(
              doc.getDrawingDoubleUnit(staff.drawingStaffSize),
              rec.require('drawingDoubleUnit'),
              'staff@$staffN drawingDoubleUnit');
          requireEq(
              doc.getDrawingStaffSize(staff.drawingStaffSize),
              rec.require('drawingStaffSize'),
              'staff@$staffN drawingStaffSize');
          compared++;
        }
        stdout.writeln(
            '04-00 unidades [$path]: $compared pentagramas comparados, '
            '${compared - divergences.length} batem');
        expect(divergences, isEmpty, reason: divergences.join('\n'));
      });
    });
  }
}
