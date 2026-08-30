/// Instrumento de pinpointing (05-38): compara o fluxo de chamadas de desenho
/// do Dart ([DrawRecorder]) com o fixture C++ instrumentado (`cpp_probe` 05-38).
///
/// Uso (a partir de `verovio_dart/`):
/// ```
/// dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei
/// dart run tool/probe_diff.dart --dir=test/corpus/<fam>
/// dart run tool/probe_diff.dart --dir=test/corpus --rank
/// ```
///
/// Comportamento (§6-bis, §10 do MESTRE):
/// - Renderiza com [DrawRecorder].
/// - Lê o fixture C++ em `test/fixtures/cpp/05-38/<basename>.jsonl`.
///   Se não existir, **reprova com "fixture ausente — gere com
///   `tool/gen_probe_fixtures.sh <fam>`"** (silêncio nunca é aprovação).
/// - Alinha os dois fluxos por `seq` e por `path`.
/// - Reporta a primeira divergência com `fn`, `seq`, `path`, campos
///   `esperado × obtido (Δ)` e `origem provável: View::...`.
/// - Com `--rank`, agrupa as primeiras divergências por `(fn, origem)` e
///   ordena por quantos arquivos cada causa destrava.
library;

import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/rendering/resources.dart';
import 'package:verovio_dart/src/rendering/view.dart';
import 'package:verovio_dart/src/testing/draw_recorder.dart';
import 'package:verovio_dart/src/toolkit.dart' show Toolkit;
import 'package:verovio_dart/src/core/options_shell.dart' show Breaks;

const String _fixtureRoot = 'test/fixtures/cpp/05-38';

// ---------------------------------------------------------------------------
// Origem provável: fn + contexto (último segmento do path) -> método C++
//
// Mapa montado a partir de quem chama a primitiva no C++ (`grep -rn
// DrawSmuflCode origin/src/src/view_*.cpp` etc). Heurística suficiente para
// agrupar `--rank` por causa destravável (fila de 5.6).
// ---------------------------------------------------------------------------

String _origemProvavel(String fn, String path) {
  final leaf = path.split('/').isEmpty ? '' : path.split('/').last;
  final klass =
      leaf.contains('[') ? leaf.substring(0, leaf.indexOf('[')) : leaf;

  // SMuFL
  if (fn == 'DrawSmuflCode' ||
      fn == 'DrawSmuflString' ||
      fn == 'DrawSmuflLine') {
    switch (klass) {
      case 'accid':
        return 'View::DrawAccid (view_element.cpp:652/1204)';
      case 'clef':
        return 'View::DrawClef (view_element.cpp:418)';
      case 'keySig':
        return 'View::DrawKeySig (view_element.cpp:1121)';
      case 'meterSig':
      case 'meterSigGrp':
        return 'View::DrawMeterSig (view_element.cpp:2102)';
      case 'note':
        return 'View::DrawNote (view_element.cpp:1629)';
      case 'rest':
        return 'View::DrawRest (view_element.cpp:1228)';
      case 'barLine':
        return 'View::DrawBarLine (view_element.cpp:733)';
      case 'beam':
        return 'View::DrawBeam (view_beam.cpp)';
      case 'flag':
        return 'View::DrawFlag (view_element.cpp:933)';
      case 'slur':
        return 'View::DrawSlur (view_slur.cpp)';
      case 'tuplet':
        return 'View::DrawTuplet (view_tuplet.cpp)';
      case 'mensur':
        return 'View::DrawMensur (view_mensural.cpp)';
      default:
        return 'View::DrawSmuflCode (view_graph.cpp:279) / DrawSmuflString (view_graph.cpp:334) / DrawSmuflLine (view_graph.cpp:297)';
    }
  }
  if (fn == 'DrawLine') {
    if (klass == 'staff') {
      return 'View::DrawStaff / DrawHorizontalLine (view_graph.cpp:40)';
    }
    if (klass == 'barLine') {
      return 'View::DrawBarLine (view_element.cpp)';
    }
    {
      return 'View::DrawLine (view_graph.cpp) -> SvgDeviceContext::DrawLine (svgdevicecontext.cpp:866)';
    }
  }
  if (fn == 'DrawPolyline' || fn == 'DrawPolygon') {
    return 'View::DrawPolyline/DrawPolygon (view_graph.cpp, view_beam.cpp)';
  }
  if (fn == 'DrawCurve') {
    return 'View::DrawThickBezierCurve (view_graph.cpp:359) / DrawSlur / DrawCurve (svgdevicecontext.cpp:670,693,717)';
  }
  if (fn == 'DrawRectangle' || fn == 'DrawRoundedRectangle') {
    return 'View::DrawFilledRectangle / DrawNotFilledRectangle (view_graph.cpp:104,133)';
  }
  if (fn == 'DrawText') {
    return 'View::DrawText (view_text.cpp) -> SvgDeviceContext::DrawText (svgdevicecontext.cpp:1079)';
  }
  if (fn == 'StartText' || fn == 'EndText') {
    return 'View::DrawTextString / SvgDeviceContext::StartText (svgdevicecontext.cpp:1003)';
  }
  if (fn == 'StartGraphic') {
    return 'SvgDeviceContext::StartGraphic (svgdevicecontext.cpp:249) — View::DrawLayerElement';
  }
  if (fn == 'EndGraphic') {
    return 'SvgDeviceContext::EndGraphic (svgdevicecontext.cpp:429)';
  }
  if (fn == 'ResumeGraphic') {
    return 'SvgDeviceContext::ResumeGraphic (svgdevicecontext.cpp:418)';
  }
  if (fn == 'EndResumedGraphic') {
    return 'SvgDeviceContext::EndResumedGraphic (svgdevicecontext.cpp:453)';
  }
  if (fn == 'RotateGraphic') {
    return 'SvgDeviceContext::RotateGraphic (svgdevicecontext.cpp:466)';
  }
  if (fn == 'DrawCircle' || fn == 'DrawEllipse') {
    return 'View::DrawDot / DrawNotFilledEllipse (view_graph.cpp:86,199)';
  }
  return 'View::$fn';
}

// ---------------------------------------------------------------------------
// Render with DrawRecorder
// ---------------------------------------------------------------------------

List<Map<String, Object?>> _renderDart(String meiPath) {
  Resources.defaultPath = 'assets/data';
  final file = File(meiPath);
  if (!file.existsSync()) {
    throw StateError('arquivo não encontrado: $meiPath');
  }
  final data = file.readAsStringSync();
  final toolkit = Toolkit();
  final ok = toolkit.loadData(data);
  if (!ok) throw StateError('loadData falhou para $meiPath');
  final doc = toolkit.doc;
  doc.getOptions().breaks.setValue(Breaks.auto);
  doc.prepareData();
  doc.setDrawingPage(0);
  doc.getResourcesForModification().initFonts();
  final view = View()..setDoc(doc);
  view.setPage(doc.drawingPage!, true);
  final dc = DrawRecorder(docId: 'docid');
  dc.setResources(doc.getResources());
  dc.width = doc.getOptions().pageWidth.unfactoredValue;
  dc.height = doc.getOptions().pageHeight.unfactoredValue;
  view.drawCurrentPage(dc, false);
  // Return structured records; seq is per-render starting at 1
  return dc.records;
}

// ---------------------------------------------------------------------------
// Load C++ fixture
// ---------------------------------------------------------------------------

const Set<String> _drawingFns = {
  'StartGraphic',
  'EndGraphic',
  'ResumeGraphic',
  'EndResumedGraphic',
  'RotateGraphic',
  'StartText',
  'EndText',
  'DrawLine',
  'DrawPolyline',
  'DrawPolygon',
  'DrawRectangle',
  'DrawRoundedRectangle',
  'DrawText',
  'DrawSmuflCode',
  'DrawSmuflString',
  'DrawSmuflLine',
  'DrawCurve',
  'DrawCircle',
  'DrawEllipse',
};

List<Map<String, Object?>> _loadFixtureFor(String meiPath,
    {bool exitOnMissing = true}) {
  final basename = meiPath.split('/').last; // e.g., note-001.mei
  final rel =
      meiPath.replaceFirst('test/corpus/', ''); // e.g., note/note-001.mei
  final p1 = '$_fixtureRoot/$basename.jsonl';
  final p2 = '$_fixtureRoot/$rel.jsonl';
  final p3 = '$_fixtureRoot/$basename.jsonl'; // same as p1
  final candidates = [p2, p1, p3];
  String? found;
  for (final c in candidates) {
    if (File(c).existsSync()) {
      found = c;
      break;
    }
  }
  if (found == null) {
    if (exitOnMissing) {
      final fam =
          meiPath.split('/').length >= 3 ? meiPath.split('/')[2] : '<fam>';
      stderr.writeln(
          'fixture ausente — gere com `tool/gen_probe_fixtures.sh $fam`');
      stderr.writeln('  procurado em: ${candidates.join(", ")}');
      exit(2);
    }
    return [];
  }
  final content = File(found).readAsStringSync();
  final lines = const LineSplitter()
      .convert(content)
      .where((l) => l.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) return [];
  final out = <Map<String, Object?>>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final decoded = jsonDecode(line) as Map<String, dynamic>;
    if (decoded.containsKey('_meta')) continue;
    // Keep only drawing-probe records (05-38); earlier functor fixtures are ignored here
    final fn = decoded['fn'] as String?;
    if (fn != null && !_drawingFns.contains(fn)) continue;
    out.add(decoded.cast<String, Object?>());
  }
  return out;
}

// ---------------------------------------------------------------------------
// Comparison
// ---------------------------------------------------------------------------

class _Divergence {
  _Divergence(this.seq, this.fn, this.path, this.field, this.expected,
      this.obtained, this.origem);
  final int seq;
  final String fn;
  final String path;
  final String field;
  final Object? expected;
  final Object? obtained;
  final String origem;
}

_Divergence? _firstDivergence(
    List<Map<String, Object?>> cpp, List<Map<String, Object?>> dart) {
  // Mapas id -> path para comparar gId/gClass voláteis por xpath (path estrutural), não por literal de semente
  final Map<String, String> cppIdToPath = {};
  for (final r in cpp) {
    final id = r['id'] as String?;
    final path = r['path'] as String?;
    if (id != null && id.isNotEmpty && path != null) cppIdToPath[id] = path;
  }
  final Map<String, String> dartIdToPath = {};
  for (final r in dart) {
    final id = r['id'] as String?;
    final path = r['path'] as String?;
    if (id != null && id.isNotEmpty && path != null) dartIdToPath[id] = path;
  }

  final n = cpp.length < dart.length ? cpp.length : dart.length;
  for (var i = 0; i < n; i++) {
    final c = cpp[i];
    final d = dart[i];
    final seq = (c['seq'] as num?)?.toInt() ?? i + 1;
    final fnC = c['fn'] as String? ?? '';
    final fnD = d['fn'] as String? ?? '';
    final pathC = c['path'] as String? ?? '';
    final pathD = d['path'] as String? ?? '';
    if (fnC != fnD) {
      return _Divergence(
          seq, fnC, pathC, 'fn', fnC, fnD, _origemProvavel(fnC, pathC));
    }
    if (pathC != pathD) {
      return _Divergence(
          seq, fnC, pathC, 'path', pathC, pathD, _origemProvavel(fnC, pathC));
    }
    for (final key in c.keys) {
      if (key == 'fn' || key == 'seq' || key == 'path' || key == 'id') continue;
      // gId / gClass podem ser @xml:id voláteis — compara por xpath (path) em vez de literal
      if (key == 'gId' || key == 'gClass') {
        final expRaw = c[key] as String? ?? '';
        final obtRaw = d[key] as String? ?? '';
        final expIsId = cppIdToPath.containsKey(expRaw);
        final obtIsId = dartIdToPath.containsKey(obtRaw);
        if (expIsId || obtIsId) {
          // Se um lado é id e o outro não, já diverge; se ambos são ids, compara o path que cada id referencia
          final expPath = expIsId ? cppIdToPath[expRaw]! : expRaw;
          final obtPath = obtIsId ? dartIdToPath[obtRaw]! : obtRaw;
          if (expIsId != obtIsId || expPath != obtPath) {
            return _Divergence(seq, fnC, pathC, key, '$expRaw ($expPath)',
                '$obtRaw ($obtPath)', _origemProvavel(fnC, pathC));
          }
          continue;
        }
        // Ambos são literais (ex.: "note", "clef", "pageMilestone") — compara literal
        if (expRaw != obtRaw) {
          return _Divergence(seq, fnC, pathC, key, expRaw, obtRaw,
              _origemProvavel(fnC, pathC));
        }
        continue;
      }
      final exp = c[key];
      final obt = d[key];
      if (exp is num && obt is num) {
        if ((exp - obt).abs() > 1e-9) {
          return _Divergence(
              seq, fnC, pathC, key, exp, obt, _origemProvavel(fnC, pathC));
        }
      } else if (exp != obt) {
        return _Divergence(
            seq, fnC, pathC, key, exp, obt, _origemProvavel(fnC, pathC));
      }
    }
  }
  if (cpp.length != dart.length) {
    final seq = n + 1;
    final fn = n < cpp.length
        ? (cpp[n]['fn'] as String? ?? '')
        : (dart[n]['fn'] as String? ?? '');
    final path = n < cpp.length
        ? (cpp[n]['path'] as String? ?? '')
        : (dart[n]['path'] as String? ?? '');
    return _Divergence(seq, fn, path, 'count', 'cpp ${cpp.length} registros',
        'dart ${dart.length} registros', _origemProvavel(fn, path));
  }
  return null;
}

void _reportDivergence(String meiPath, _Divergence div,
    List<Map<String, Object?>> cppRec, List<Map<String, Object?>> dartRec) {
  // Find the pair of records for detailed multi-field dump (like example)
  final idx = (div.seq - 1).clamp(0, cppRec.length - 1);
  final c = cppRec[idx];
  final d = dartRec.length > idx ? dartRec[idx] : <String, Object?>{};
  stdout.writeln(meiPath);
  stdout.writeln('  seq ${div.seq}  fn=${div.fn}  path=${div.path}');
  // Mapas para resolver gId/gClass voláteis por xpath
  final Map<String, String> cppIdToPath = {};
  for (final r in cppRec) {
    final id = r['id'] as String?;
    final path = r['path'] as String?;
    if (id != null && id.isNotEmpty && path != null) cppIdToPath[id] = path;
  }
  final Map<String, String> dartIdToPath = {};
  for (final r in dartRec) {
    final id = r['id'] as String?;
    final path = r['path'] as String?;
    if (id != null && id.isNotEmpty && path != null) dartIdToPath[id] = path;
  }
  // Dump all fields of this fn's record, alinhando esperado x obtido
  for (final key in c.keys) {
    if (key == 'fn' || key == 'seq' || key == 'path' || key == 'id') continue;
    final exp = c[key];
    final obt = d[key];
    // gId / gClass voláteis: mostra xpath em vez de literal de semente
    if (key == 'gId' || key == 'gClass') {
      final expRaw = exp as String? ?? '';
      final obtRaw = obt as String? ?? '';
      final expIsId = cppIdToPath.containsKey(expRaw);
      final obtIsId = dartIdToPath.containsKey(obtRaw);
      String expStr, obtStr;
      if (expIsId) {
        expStr = '$expRaw (${cppIdToPath[expRaw]})';
      } else {
        expStr = expRaw;
      }
      if (obtIsId) {
        obtStr = '$obtRaw (${dartIdToPath[obtRaw]})';
      } else {
        obtStr = obt == null ? '<ausente>' : obtRaw;
      }
      // Destaca divergência de xpath quando for o campo da divergência
      final marker = (key == div.field) ? '  <-- diverge (xpath)' : '';
      stdout.writeln('    $key:   esperado $expStr   obtido $obtStr$marker');
      continue;
    }
    String expStr = '$exp';
    String obtStr = obt == null ? '<ausente>' : '$obt';
    String delta = '';
    if (exp is num && obt is num) {
      final diff = (obt - exp).toInt();
      if (diff != 0) delta = '   (Δ $diff)';
      if (exp is double || obt is double) {
        final dd = (obt - exp);
        delta = '   (Δ ${dd.toStringAsFixed(6)})';
      }
      stdout.writeln('    $key:      esperado $expStr   obtido $obtStr$delta');
    } else {
      stdout.writeln('    $key:   esperado $expStr   obtido $obtStr');
    }
  }
  stdout.writeln('  origem provável: ${div.origem}');
}

void _processSingle(String meiPath, {bool verbose = true}) {
  final cpp = _loadFixtureFor(meiPath);
  final dart = _renderDart(meiPath);
  final div = _firstDivergence(cpp, dart);
  if (div == null) {
    if (verbose) stdout.writeln('$meiPath — 0 divergências (limpo)');
    return;
  }
  _reportDivergence(meiPath, div, cpp, dart);
}

void _processDir(String dir, {bool rank = false}) {
  final directory = Directory(dir);
  if (!directory.existsSync()) {
    stderr.writeln('diretório não encontrado: $dir');
    exit(2);
  }
  final files = directory
      .listSync(recursive: dir == 'test/corpus')
      .whereType<File>()
      .where((f) => f.path.endsWith('.mei'))
      .map((f) => f.path)
      .toList()
    ..sort();
  if (files.isEmpty) {
    stderr.writeln('nenhum .mei sob $dir');
    exit(2);
  }

  if (!rank) {
    for (final f in files) {
      _processSingle(f);
    }
    return;
  }

  // rank mode: group first divergences by (fn, origem)
  final Map<String, int> causeCounts = {};
  final Map<String, List<String>> causeFiles = {};
  final Map<String, String> causeOrigem = {};
  int clean = 0;
  int divergent = 0;
  int missingFixture = 0;
  int failures = 0;

  for (final f in files) {
    // Check fixture existence without exiting
    final cpp = _loadFixtureFor(f, exitOnMissing: false);
    if (cpp.isEmpty) {
      // Could be empty because file has no draw calls (unlikely) or missing fixture
      final basename = f.split('/').last;
      final rel = f.replaceFirst('test/corpus/', '');
      final candidates = [
        '$_fixtureRoot/$rel.jsonl',
        '$_fixtureRoot/$basename.jsonl',
      ];
      final exists = candidates.any((c) => File(c).existsSync());
      if (!exists) {
        missingFixture++;
        continue;
      }
    }
    List<Map<String, Object?>> dart;
    try {
      dart = _renderDart(f);
    } catch (e) {
      failures++;
      continue;
    }
    final div = _firstDivergence(cpp, dart);
    if (div == null) {
      clean++;
    } else {
      divergent++;
      final key = '${div.fn} :: ${div.origem}';
      causeCounts[key] = (causeCounts[key] ?? 0) + 1;
      causeFiles.putIfAbsent(key, () => []).add(f);
      causeOrigem[key] = div.origem;
    }
  }

  final sorted = causeCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  stdout.writeln('probe_diff --rank — ${files.length} arquivo(s) sob $dir');
  stdout.writeln(
      '  limpos: $clean, divergentes: $divergent, falhas: $failures, fixture ausente: $missingFixture');
  stdout.writeln(
      '  fila de causas (fn + origem provável) — quantos arquivos cada causa destrava:');
  for (var i = 0; i < sorted.length && i < 30; i++) {
    final e = sorted[i];
    stdout.writeln('  ${e.value.toString().padLeft(4)}  ${e.key}');
    // show up to 2 example files
    final ex = causeFiles[e.key]!.take(2).join(', ');
    if (ex.isNotEmpty) stdout.writeln('         ex.: $ex');
  }
  if (sorted.isEmpty) {
    stdout.writeln('  (nenhuma causa — todos limpos ou sem fixture)');
  }
  if (missingFixture > 0) {
    stdout.writeln(
        '\n  Nota: $missingFixture arquivo(s) sem fixture — gere com `tool/gen_probe_fixtures.sh <fam>`');
  }
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main(List<String> args) {
  String? dir;
  bool rank = false;
  String? single;

  for (final a in args) {
    if (a.startsWith('--dir=')) {
      dir = a.substring('--dir='.length);
    } else if (a == '--rank') {
      rank = true;
    } else if (a.startsWith('--')) {
      stderr.writeln('argumento desconhecido: $a');
      stderr.writeln(
          'uso: dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei');
      stderr.writeln(
          '     dart run tool/probe_diff.dart --dir=test/corpus/<fam>');
      stderr.writeln(
          '     dart run tool/probe_diff.dart --dir=test/corpus --rank');
      exit(2);
    } else {
      single = a;
    }
  }

  if (single != null && dir != null) {
    stderr.writeln('use ou um arquivo posicional ou --dir, não ambos');
    exit(2);
  }

  if (single != null) {
    _processSingle(single);
    return;
  }
  if (dir != null) {
    _processDir(dir, rank: rank);
    return;
  }

  stderr.writeln(
      'uso: dart run tool/probe_diff.dart test/corpus/<fam>/<arq>.mei');
  stderr.writeln('     dart run tool/probe_diff.dart --dir=test/corpus/<fam>');
  stderr.writeln('     dart run tool/probe_diff.dart --dir=test/corpus --rank');
  exit(2);
}
