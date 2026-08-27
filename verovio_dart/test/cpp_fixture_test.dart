/// Tests for the C++ reference fixture reader (`test/fixtures/cpp_fixture.dart`)
/// and the end-to-end proof that the mechanism works: the `EXEMPLO` fixture,
/// extracted from an instrumented `AdjustXPosFunctor`, compared value by value
/// against the already-ported `lib/src/layout/adjust_x_pos.dart`.
///
/// See `cpp_probe/README.md` for how the fixtures are produced.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/layout/adjust_x_pos.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/rendering/resources.dart';

import 'fixtures/cpp_fixture.dart';

/// A well-formed two-record fixture, written to a temp file by the tests that
/// exercise the reader itself.
const String _wellFormed = '{"_meta":{"task":"T","source":"test/corpus/x.mei",'
    '"xmlIdSeed":12345,"verovio":"6.2.0","patches":["EXEMPLO","T"],'
    '"generated":"2026-08-27"}}\n'
    '{"fn":"Fn","pass":1,"path":"measure[1]/staff[1]/layer[1]/note[1]",'
    '"id":"n1","xRel_in":10,"xRel_out":20}\n'
    '{"fn":"Fn","pass":1,"path":"measure[1]/staff[1]/layer[1]/note[2]",'
    '"id":"n2","xRel_in":30,"xRel_out":40}\n';

Doc _loadCorpus(String relativePath) {
  final File file = File('test/corpus/$relativePath');
  final Doc doc = Doc();
  final MeiInput input = MeiInput(doc);
  final bool ok = input.import(utf8.decode(file.readAsBytesSync()));
  expect(ok, isTrue, reason: 'MEI import of $relativePath should succeed');
  return doc;
}

/// Records the same before/after values as `cpp_probe/patches/EXEMPLO.patch`
/// does on the C++ side, without touching the ported functor: it wraps
/// [AdjustXPosFunctor.visitLayerElement] instead of editing it.
class _ProbedAdjustXPosFunctor extends AdjustXPosFunctor {
  _ProbedAdjustXPosFunctor(super.doc);

  /// One entry per visited element, keyed by `<path>|<staffN>` — the same
  /// disambiguation the fixture uses, since a barline with `@n="-1"` is
  /// visited once per staff.
  final Map<String, int> xRelOut = <String, int>{};
  final Map<String, int> xRelIn = <String, int>{};

  static String key(String path, int staffN) => '$path|$staffN';

  /// The Dart counterpart of the fixture field [field] for [record].
  int? valueOf(String field, CppRecord record) {
    final String entry = key(record.path, record['staffN'] as int);
    return field == 'xRel_in' ? xRelIn[entry] : xRelOut[entry];
  }

  @override
  FunctorCode visitLayerElement(LayerElement layerElement) {
    final int? before = layerElement.getAlignment()?.getXRel();
    final FunctorCode code = super.visitLayerElement(layerElement);
    final int? after = layerElement.getAlignment()?.getXRel();
    if (before != null && after != null) {
      final String entry = key(cppPath(layerElement), staffN);
      xRelIn[entry] = before;
      xRelOut[entry] = after;
    }
    return code;
  }
}

void main() {
  setUpAll(() {
    registerModelClasses();
    Resources.defaultPath = 'assets/data';
    logLevel = LogLevel.error;
  });

  group('CppFixture — leitura', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cpp_fixture_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    String write(String name, String content) {
      final File file = File('${tempDir.path}/$name');
      file.writeAsStringSync(content);
      return file.path;
    }

    test('arquivo bem formado: cabeçalho _meta e registros', () {
      final CppFixture fixture =
          CppFixture.loadFile(write('ok.jsonl', _wellFormed));

      expect(fixture.meta.task, 'T');
      expect(fixture.meta.source, 'test/corpus/x.mei');
      expect(fixture.meta.xmlIdSeed, 12345);
      expect(fixture.meta.verovio, '6.2.0');
      expect(fixture.meta.patches, <String>['EXEMPLO', 'T']);
      expect(fixture.meta.generated, '2026-08-27');

      expect(fixture.records, hasLength(2));
      expect(fixture.records.first.fn, 'Fn');
      expect(fixture.records.first.pass, 1);
      expect(fixture.records.first.id, 'n1');
      expect(fixture.records.first.number('xRel_out'), 20);
      // O registro cru continua acessível, para campos que o leitor não conhece.
      expect(fixture.records.first['xRel_in'], 10);
    });

    test('fixture ausente: erra alto, e a mensagem diz como regerar', () {
      expect(
        () => CppFixture.load('04a', 'test/corpus/layer/layer-nao-existe.mei'),
        throwsA(isA<CppFixtureError>().having(
            (CppFixtureError e) => e.message,
            'message',
            allOf(contains('fixture ausente'), contains('cpp_probe/run.sh')))),
      );
    });

    test('path inexistente: single() falha em vez de devolver nada', () {
      final CppFixture fixture =
          CppFixture.loadFile(write('ok.jsonl', _wellFormed));

      expect(
          fixture.where(path: 'measure[9]/staff[1]/layer[1]/note[1]'), isEmpty);
      expect(
        () => fixture.single(fn: 'Fn', path: 'measure[9]'),
        throwsA(isA<CppFixtureError>().having((CppFixtureError e) => e.message,
            'message', contains('nenhum registro'))),
      );
    });

    test('single() falha também quando a chave é ambígua', () {
      final CppFixture fixture =
          CppFixture.loadFile(write('ok.jsonl', _wellFormed));
      expect(
        () => fixture.single(fn: 'Fn'),
        throwsA(isA<CppFixtureError>().having((CppFixtureError e) => e.message,
            'message', contains('2 registros'))),
      );
    });

    test('sem cabeçalho _meta: erro', () {
      final String path = write(
          'nometa.jsonl', '{"fn":"Fn","path":"measure[1]","xRel_out":1}\n');
      expect(
        () => CppFixture.loadFile(path),
        throwsA(isA<CppFixtureError>().having(
            (CppFixtureError e) => e.message, 'message', contains('_meta'))),
      );
    });

    test('só o cabeçalho, sem registros: erro (não passa vazio)', () {
      final String path = write(
          'vazio.jsonl', '{"_meta":{"task":"T","source":"x","xmlIdSeed":1}}\n');
      expect(
        () => CppFixture.loadFile(path),
        throwsA(isA<CppFixtureError>().having((CppFixtureError e) => e.message,
            'message', contains('nenhum registro'))),
      );
    });

    test('JSON inválido: erro nomeando a linha', () {
      final String path =
          write('ruim.jsonl', '{"_meta":{"task":"T"}}\n{"fn":"Fn",,}\n');
      expect(
        () => CppFixture.loadFile(path),
        throwsA(isA<CppFixtureError>().having(
            (CppFixtureError e) => e.message, 'message', contains('linha 2'))),
      );
    });

    test('compare() devolve a lista de divergências, com caminho e valores',
        () {
      final CppFixture fixture =
          CppFixture.loadFile(write('ok.jsonl', _wellFormed));

      final Map<String, int> dart = <String, int>{
        'measure[1]/staff[1]/layer[1]/note[1]': 20, // bate
        'measure[1]/staff[1]/layer[1]/note[2]': 41, // diverge por 1
      };
      final List<CppDivergence> divergences = fixture.compare(
        fn: 'Fn',
        field: 'xRel_out',
        actual: (CppRecord record) => dart[record.path],
      );

      expect(divergences, hasLength(1));
      expect(divergences.single.expected, 40);
      expect(divergences.single.actual, 41);
      expect(divergences.single.record.path,
          'measure[1]/staff[1]/layer[1]/note[2]');
      expect(divergences.single.toString(), contains('C++=40'));
      expect(divergences.single.toString(), contains('Dart=41'));
      expect(fixture.summary('xRel_out', divergences, fn: 'Fn'),
          'xRel_out: 2 valores comparados, 1 batem, 1 divergem');
    });

    test('compare() sem nenhum registro casando é erro, não sucesso', () {
      final CppFixture fixture =
          CppFixture.loadFile(write('ok.jsonl', _wellFormed));
      expect(
        () => fixture.compare(
            fn: 'FunctorQueNaoExiste',
            field: 'xRel_out',
            actual: (CppRecord _) => 0),
        throwsA(isA<CppFixtureError>().having((CppFixtureError e) => e.message,
            'message', contains('nenhum registro'))),
      );
    });

    test('campo ausente no registro é erro, não zero', () {
      final CppFixture fixture =
          CppFixture.loadFile(write('ok.jsonl', _wellFormed));
      expect(
        () => fixture.records.first.require('yRel_out'),
        throwsA(isA<CppFixtureError>().having(
            (CppFixtureError e) => e.message, 'message', contains('yRel_out'))),
      );
    });
  });

  group('cppPath — a chave de casamento', () {
    late Doc doc;

    setUpAll(() {
      doc = _loadCorpus('note/note-001.mei');
      doc.prepareData();
    });

    test('enraíza no measure e usa @n de measure/staff/layer', () {
      final List<dynamic> notes = doc.findAllDescendantsByType(ClassId.note);
      expect(notes, isNotEmpty);
      expect(cppPath(notes.first as dynamic),
          'measure[1]/staff[1]/layer[1]/note[1]');
    });

    test('os membros do measure recebem token de papel, não índice', () {
      final List<dynamic> measures =
          doc.findAllDescendantsByType(ClassId.measure);
      expect(measures, isNotEmpty);
      final dynamic measure = measures.first;
      expect(
          cppPath(measure.leftBarLine as dynamic), 'measure[1]/barLine[left]');
      expect(cppPath(measure.rightBarLine as dynamic),
          'measure[1]/barLine[right]');
    });
  });

  group('EXEMPLO — AdjustXPosFunctor contra o C++ instrumentado', () {
    // O fixture cobre 4 passadas de AdjustXPos (duas por
    // Page::LayOutHorizontally, que roda para a página não fatiada e de novo
    // para a fatiada). A comparação usa a passada 1: é a que o teste reproduz
    // na íntegra — resetAligners() + AdjustXPos com `excluded = [tabDurSym]`,
    // exatamente como page.cpp:448-450. note-001.mei tem um compasso só, então
    // a página fatiada e a não fatiada têm o mesmo conteúdo.
    late CppFixture fixture;
    late _ProbedAdjustXPosFunctor probe;

    setUpAll(() {
      fixture = CppFixture.load('EXEMPLO', 'test/corpus/note/note-001.mei');

      final Doc doc = _loadCorpus('note/note-001.mei');
      doc.prepareData();
      final Page page = doc.setDrawingPage(0)!;
      page.resetAligners();

      probe = _ProbedAdjustXPosFunctor(doc);
      probe.setExcluded(<ClassId>[ClassId.tabDurSym]);
      page.process(probe);
    });

    test('o fixture tem a proveniência esperada', () {
      expect(fixture.meta.task, 'EXEMPLO');
      expect(fixture.meta.source, 'test/corpus/note/note-001.mei');
      expect(fixture.meta.xmlIdSeed, 12345,
          reason: 'a semente fixa de cpp_probe/run.sh');
      expect(fixture.meta.patches, contains('EXEMPLO'));
      expect(fixture.where(fn: 'AdjustXPos', pass: 1), hasLength(10));
    });

    test('o Dart visita exatamente os mesmos elementos que o C++ na passada 1',
        () {
      final Set<String> cpp = fixture
          .where(fn: 'AdjustXPos', pass: 1)
          .map((CppRecord r) =>
              _ProbedAdjustXPosFunctor.key(r.path, r['staffN'] as int))
          .toSet();
      expect(probe.xRelOut.keys.toSet(), cpp,
          reason: 'a regra de `path` casa os dois lados elemento a elemento');
    });

    // Os valores numéricos NÃO batem hoje, e isso é um achado medido, não um
    // defeito deste leitor: a fase horizontal do Dart roda sem a passada de
    // bounding box do C++ (`View` + `BBoxDeviceContext`, page.cpp:407-413), que
    // só chega na tarefa 05-12, então AdjustXPos não desloca nada. O relatório
    // `prompts/reports/DADOS-CPP.md` traz os 20 valores e as duas hipóteses de
    // causa. O que se assere aqui é o mecanismo: toda divergência é resolvida
    // até um objeto real do lado Dart e carrega os dois valores. Quando a
    // 05-12 fechar a lacuna, troque estes dois testes por
    // `expect(divergences, isEmpty)`.
    // Contagem medida hoje: só o `clef[staffDef]` entra na passada com
    // `xRel_in` igual dos dois lados (0), então `xRel_in` diverge em 9 dos 10
    // e `xRel_out` nos 10.
    const Map<String, int> known = <String, int>{'xRel_in': 9, 'xRel_out': 10};
    for (final String field in known.keys) {
      test('$field: o comparador resolve todo caminho do fixture no Dart', () {
        final List<CppDivergence> divergences = fixture.compare(
          fn: 'AdjustXPos',
          pass: 1,
          field: field,
          actual: (CppRecord record) => probe.valueOf(field, record),
        );
        for (final CppDivergence divergence in divergences) {
          expect(divergence.actual, isNotNull,
              reason: 'o caminho ${divergence.record.path} não foi encontrado '
                  'na árvore Dart — a regra de `path` saiu de sincronia');
          expect(divergence.toString(), contains('C++='));
        }
        // Divergência conhecida e quantificada (ver o comentário acima). Se
        // este número CAIR, o port melhorou: atualize-o, ou troque por
        // `isEmpty` quando chegar a zero. Se SUBIR, é regressão.
        expect(divergences, hasLength(known[field]));
      });
    }
  });
}
