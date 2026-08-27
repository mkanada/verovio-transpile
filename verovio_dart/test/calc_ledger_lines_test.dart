/// Parity of [CalcLedgerLinesFunctor] (`lib/src/layout/calc_ledger_lines.dart`)
/// against the instrumented C++ (`cpp_probe` task `04g`).
///
/// `test/corpus/note/note-009.mei` — notes in octaves 3 and 6, so ledger
/// lines both above and below the staff — is a plain CMN file with no
/// accidentals, ossia or neume notation, so (unlike `AdjustNeumeXFunctor`,
/// see `adjust_ossia_neume_test.dart`) this port's ordinary horizontal/
/// vertical layout already reproduces the C++'s positions closely enough
/// that a full `doc.prepareData()` + `doc.layOut()` run, compared directly
/// against the fixture, is meaningful — no synthetic-per-record
/// reconstruction needed for the note branch.
///
/// `VisitAccid`'s "real work" branch (an accidental far enough from the
/// staff to need ledger lines of its own) is not exercised by any of the
/// three fixed corpus files for this task — verified directly against all
/// three fixtures (`grep VisitAccid` on `ossia-001`/`neume-002`/`note-009`
/// finds nothing). It is covered by a hand-built synthetic test instead,
/// against the C++ algorithm in `calcledgerlinesfunctor.cpp:25-38`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/calc_ledger_lines.dart';
import 'package:verovio_dart/src/layout/horizontal_aligner.dart' show Alignment;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show AccidentalWritten;
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Dash, LedgerLine, Layer, Measure, Note, Staff;
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart'
    show Accid, Chord;
import 'package:verovio_dart/src/rendering/resources.dart';

import 'fixtures/cpp_fixture.dart';

const String task = '04g';

Doc _loadCorpus(String relativePath) {
  final File file = File(relativePath);
  final Doc doc = Doc();
  final MeiInput input = MeiInput(doc);
  final bool ok = input.import(utf8.decode(file.readAsBytesSync()));
  expect(ok, isTrue, reason: 'MEI import of $relativePath should succeed');
  return doc;
}

/// The single staff of a one-measure, one-staff, one-layer document (matches
/// `note-009.mei`'s shape).
Staff _onlyStaff(Doc doc) =>
    doc.findDescendantByType(ClassId.staff) as Staff;

void main() {
  setUpAll(() {
    registerModelClasses();
    Resources.defaultPath = 'assets/data';
    logLevel = LogLevel.error;
  });

  group('proveniência do fixture', () {
    test('test/corpus/note/note-009.mei', () {
      final CppFixture fixture =
          CppFixture.load(task, 'test/corpus/note/note-009.mei');
      expect(fixture.meta.task, task);
      expect(fixture.meta.xmlIdSeed, 12345,
          reason: 'a semente fixa de cpp_probe/run.sh');
      expect(fixture.meta.patches, contains(task));
    });

    test('nenhum dos três arquivos fixados exercita VisitAccid com ledger '
        'lines de verdade', () {
      for (final String name in ['ossia-001', 'neume-002', 'note-009']) {
        final String path = name.startsWith('ossia')
            ? 'ossia/$name.mei'
            : name.startsWith('neume')
                ? 'neume/$name.mei'
                : 'note/$name.mei';
        final CppFixture fixture = CppFixture.load(task, 'test/corpus/$path');
        expect(
            fixture.where(
                fn: 'CalcLedgerLines', test: (r) => r['sub'] == 'VisitAccid'),
            isEmpty,
            reason: name);
      }
    });
  });

  // Reconstructed per record (`_attachToMeasure`-style, see
  // `adjust_ossia_neume_test.dart`) rather than laid out end to end:
  // `note-009.mei`'s horizontal positions carry a small (~9-unit),
  // pre-existing divergence from the C++ unrelated to this functor — this
  // decouples `CalcLedgerLinesFunctor`'s own correctness from that gap by
  // driving it with the fixture's own recorded `drawingLoc` and drawing X
  // (back-computed from `left = drawingX - extension - staffX`), the way
  // `Doc::PrepareData` and horizontal layout would have produced them.
  group('CalcLedgerLinesFunctor — note/note-009.mei (reconstrução por '
      'registro, epsilon 0)', () {
    late CppFixture fixture;
    late Doc doc;
    late Staff staff;
    late List<Note> notes;

    setUpAll(() {
      fixture = CppFixture.load(task, 'test/corpus/note/note-009.mei');
      doc = Doc();
      final Measure measure = Measure();
      staff = Staff();
      measure.addChild(staff);
      final Layer layer = Layer();
      staff.addChild(layer);

      final List<CppRecord> calcRecords = fixture.where(
          fn: 'CalcLedgerLines',
          pass: 1,
          test: (r) => r['sub'] == 'CalcForLayerElement');
      expect(calcRecords.length, 5);

      notes = [];
      for (final CppRecord record in calcRecords) {
        final int extension = record.require('extension').toInt();
        final int staffX = record.require('staffX').toInt();
        final int left = record.require('left').toInt();
        final Note note = Note()..drawingLoc = record.require('drawingLoc').toInt();
        layer.addChild(note);
        note.setAlignment(Alignment()..setXRel(left + extension + staffX));
        notes.add(note);
      }
    });

    test('VisitNote — branch calc para as 5 notas', () {
      final List<CppRecord> records = fixture.where(
          fn: 'CalcLedgerLines',
          pass: 1,
          test: (r) => r['sub'] == 'VisitNote');
      expect(records.length, 5);
      for (final CppRecord record in records) {
        expect(record['branch'], 'calc', reason: record.toString());
      }
    });

    test('visitNote (produção da própria funcao) reproduz linesAbove/'
        'linesBelow/left/right para as 5 notas', () {
      final List<CppRecord> records = fixture.where(
          fn: 'CalcLedgerLines',
          pass: 1,
          test: (r) => r['sub'] == 'CalcForLayerElement');

      final functor = CalcLedgerLinesFunctor(doc);
      final List<String> divergences = [];
      for (int i = 0; i < records.length; i++) {
        final CppRecord record = records[i];
        final Note note = notes[i];
        expect(record['branch'], 'add', reason: record.path);

        final (bool hasLines, int linesAbove, int linesBelow) =
            note.hasLedgerLines(staff);
        expect(hasLines, isTrue, reason: record.path);
        if (linesAbove != record.require('linesAbove').toInt()) {
          divergences.add('${record.path}: linesAbove esperado '
              '${record['linesAbove']}, obtido $linesAbove');
        }
        if (linesBelow != record.require('linesBelow').toInt()) {
          divergences.add('${record.path}: linesBelow esperado '
              '${record['linesBelow']}, obtido $linesBelow');
        }

        functor.visitNote(note);
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));

      functor.visitStaffEnd(staff);

      final List<CppRecord> dashRecords = fixture.where(
          fn: 'CalcLedgerLines',
          pass: 1,
          test: (r) => r['sub'] == 'VisitStaffEnd' && r['summary'] == null);
      final CppRecord summary = fixture.single(
          fn: 'CalcLedgerLines',
          pass: 1,
          test: (r) => r['sub'] == 'VisitStaffEnd' && r['summary'] == 1);

      expect(staff.getLedgerLinesAbove().length, summary.require('nAbove').toInt());
      expect(staff.getLedgerLinesBelow().length, summary.require('nBelow').toInt());
      expect(staff.getLedgerLinesAboveCue().length,
          summary.require('nAboveCue').toInt());
      expect(staff.getLedgerLinesBelowCue().length,
          summary.require('nBelowCue').toInt());

      for (final CppRecord record in dashRecords) {
        final bool above = record['side'] == 'above';
        final bool cue = record['cue'] == 1;
        final List<LedgerLine> lines = above
            ? (cue ? staff.getLedgerLinesAboveCue() : staff.getLedgerLinesAbove())
            : (cue ? staff.getLedgerLinesBelowCue() : staff.getLedgerLinesBelow());
        final int lineIndex = record.require('lineIndex').toInt();
        final int dashIndex = record.require('dashIndex').toInt();
        if (lineIndex >= lines.length) {
          divergences.add(
              '${record['side']}[$lineIndex]: linha ausente (${lines.length} presentes)');
          continue;
        }
        final List<Dash> dashes = lines[lineIndex].dashes;
        if (dashIndex >= dashes.length) {
          divergences.add('${record['side']}[$lineIndex] dash $dashIndex: '
              'dash ausente (${dashes.length} presentes)');
          continue;
        }
        final Dash dash = dashes[dashIndex];
        final int x1Expected = record.require('x1').toInt();
        final int x2Expected = record.require('x2').toInt();
        if (dash.x1 != x1Expected || dash.x2 != x2Expected) {
          divergences.add('${record['side']}[$lineIndex] dash $dashIndex: '
              'esperado ($x1Expected, $x2Expected), obtido (${dash.x1}, ${dash.x2})');
        }
      }
      expect(divergences, isEmpty, reason: divergences.join('\n'));
    });
  });

  group('CalcLedgerLinesFunctor — note/note-009.mei (produção, checagem de '
      'não regressão)', () {
    test('doc.prepareData() + doc.layOut() não lança, e o functor produz '
        'ledger lines não-vazias em ambos os lados', () {
      final Doc doc = _loadCorpus('test/corpus/note/note-009.mei');
      doc.prepareData();
      expect(() => doc.layOut(), returnsNormally);
      final Staff staff = _onlyStaff(doc);
      expect(staff.getLedgerLinesAbove(), isNotEmpty);
      expect(staff.getLedgerLinesBelow(), isNotEmpty);
    });
  });

  group('CalcLedgerLinesFunctor — VisitNote (branches de visibilidade, '
      'sintético)', () {
    test('nota com @visible="false" é siblings sem chamar CalcForLayerElement',
        () {
      final Doc doc = Doc();
      final Note note = Note()..visible = false;
      final functor = CalcLedgerLinesFunctor(doc);
      expect(functor.visitNote(note), FunctorCode.siblings);
    });

    test('nota sem @visible mas dentro de um chord totalmente invisível é '
        'siblings (mirrors Note::IsVisible via Chord::IsVisible)', () {
      final Doc doc = Doc();
      final Chord chord = Chord()..visible = false;
      final Note note = Note();
      chord.addChild(note);
      final functor = CalcLedgerLinesFunctor(doc);
      expect(functor.visitNote(note), FunctorCode.siblings);
    });

    test('nota sem @visible e sem chord é visível (Note::IsVisible default)',
        () {
      final Note note = Note();
      expect(note.isVisible(), isTrue);
    });
  });

  group('CalcLedgerLinesFunctor — VisitAccid (sintético, epsilon 0 contra o '
      'algoritmo)', () {
    test('accid dentro de uma nota é siblings (GetFirstAncestor(NOTE))', () {
      final Doc doc = Doc();
      final Note note = Note();
      final Accid accid = Accid()..accid = AccidentalWritten.s;
      note.addChild(accid);
      final functor = CalcLedgerLinesFunctor(doc);
      expect(functor.visitAccid(accid), FunctorCode.siblings);
    });

    test('accid sem @accid (gestural-only) é siblings (!HasAccid())', () {
      final Doc doc = Doc();
      final Accid accid = Accid();
      final functor = CalcLedgerLinesFunctor(doc);
      expect(functor.visitAccid(accid), FunctorCode.siblings);
    });

    test('accid livre (fora de uma nota) com @accid calcula a largura pelo '
        'glifo e adiciona ledger lines quando fora da pauta', () {
      final Doc doc = Doc();
      final Measure measure = Measure();
      final Staff staff = Staff();
      measure.addChild(staff);
      final Layer layer = Layer();
      staff.addChild(layer);
      final Accid accid = Accid()..accid = AccidentalWritten.s;
      layer.addChild(accid);
      // Two ledger lines above: mirrors PositionInterface::HasLedgerLines
      // with a drawingLoc far above the 5-line staff.
      accid.drawingLoc = 14;

      final functor = CalcLedgerLinesFunctor(doc);
      final FunctorCode code = functor.visitAccid(accid);
      expect(code, FunctorCode.siblings);
      expect(staff.getLedgerLinesAbove(), isNotEmpty,
          reason: 'HasLedgerLines(drawingLoc=14, 5 lines) has linesAbove > 0');
    });
  });
}
