/// PNG gallery generator (support tooling, not a port of any C++ file).
///
/// Rasterizes both sides of the SVG comparison — the C++ goldens
/// (`test/golden/cpp/**.svg`, produced by `tool/golden.sh`) and the current
/// Dart output (`renderSvgForComparison`, the same hook `tool/compare_svg.dart`
/// uses) — to PNG, and writes one markdown gallery page per corpus family
/// (`test/golden/png/gallery/<family>.md`) plus an index
/// (`test/golden/png/README.md`) so the rendering can be inspected directly
/// on GitHub, without cloning or running anything locally.
///
/// Output is *current state only*: every run overwrites the PNGs and gallery
/// pages in place rather than keeping per-version snapshots — there is
/// deliberately no N-vs-N+1 history here, only "what does the latest Dart
/// output look like next to the C++ reference". The PNG trees are tracked
/// with Git LFS (see `.gitattributes` at the workspace root) so the repeated
/// full-corpus regenerations this implies don't bloat the main git packfile.
///
/// Requires ImageMagick's `convert` on PATH (used to rasterize the SVGs).
///
/// Usage (from verovio_dart/):
/// ```
/// dart run tool/render_png.dart --all           # todo o corpus (621 arquivos)
/// dart run tool/render_png.dart <familia>       # ex: beam, slur, tuplet
/// dart run tool/render_png.dart <arquivo.mei>   # um único arquivo
/// dart run tool/render_png.dart --md-only       # só reescreve as galerias, sem rasterizar
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:verovio_dart/src/testing/svg_compare.dart';

const String corpusRoot = 'test/corpus';
const String cppGoldenRoot = 'test/golden/cpp';
const String pngRoot = 'test/golden/png';
const String cppPngRoot = '$pngRoot/cpp';
const String dartPngRoot = '$pngRoot/dart';
const String galleryRoot = '$pngRoot/gallery';
const String statusPath = '$pngRoot/status.json';

/// GitHub strips `style=`/`bgcolor=` from rendered markdown (verified via
/// `gh api markdown`), so gallery rows can't actually be painted red/yellow
/// — these emoji stand in for that instead, prefixed on the "Arquivo" cell.
/// Clean files stay unmarked ("branco" per the request that introduced
/// this).
const String _statusStructural = '🔴'; // divergência estrutural
const String _statusNumeric = '🟡'; // limpo estrutural, divergência numérica
const String _statusUnknown = '⚪'; // sem golden ou sem render Dart

const String _usage = '''
Uso (a partir de verovio_dart/):
  dart run tool/render_png.dart --all         # todo o corpus
  dart run tool/render_png.dart <familia>     # ex: beam, slur, tuplet
  dart run tool/render_png.dart <arquivo.mei> # um único arquivo
  dart run tool/render_png.dart --md-only     # só reescreve as galerias
''';

void main(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    exit(args.isEmpty ? 2 : 0);
  }

  if (Process.runSync('convert', ['-version']).exitCode != 0) {
    stderr.writeln(
        'ImageMagick (convert) não encontrado no PATH — necessário para rasterizar os SVGs.');
    exit(2);
  }

  final corpusDir = Directory(corpusRoot);
  if (!corpusDir.existsSync()) {
    stderr
        .writeln('Corpus não encontrado: $corpusRoot (rode de verovio_dart/)');
    exit(2);
  }

  if (args.contains('--md-only')) {
    _rebuildAllGalleries();
    return;
  }

  final all = args.contains('--all');
  final relFiles = all ? _listCorpus() : _resolveSelection(args.first);
  if (relFiles.isEmpty) {
    stderr.writeln('Nenhum .mei selecionado.');
    exit(2);
  }

  final families = <String>{};
  var cppOk = 0, cppMissingGolden = 0, cppFail = 0;
  var dartOk = 0, dartNoRender = 0, dartFail = 0;
  var structural = 0, numericOnly = 0, clean = 0, unknown = 0;
  final status = _loadStatus();
  final comparator = SvgComparator(epsilon: 0);

  for (final rel in relFiles) {
    final family = rel.substring(0, rel.indexOf('/'));
    families.add(family);
    final stem = rel.substring(0, rel.length - '.mei'.length);

    final cppSvg = File('$cppGoldenRoot/$stem.svg');
    final cppPng = '$cppPngRoot/$stem.png';
    if (!cppSvg.existsSync()) {
      cppMissingGolden++;
    } else if (_rasterize(cppSvg.path, cppPng)) {
      cppOk++;
    } else {
      cppFail++;
    }

    final dartPng = '$dartPngRoot/$stem.png';
    String? dartSvg;
    try {
      dartSvg = renderSvgForComparison('$corpusRoot/$rel');
    } catch (e) {
      dartFail++;
      dartSvg = null;
    }
    if (dartSvg == null) {
      dartNoRender++;
    } else {
      final tmp = File('${Directory.systemTemp.path}/render_png_${stem.hashCode}.svg');
      tmp.parent.createSync(recursive: true);
      tmp.writeAsStringSync(dartSvg);
      if (_rasterize(tmp.path, dartPng)) {
        dartOk++;
      } else {
        dartFail++;
      }
      tmp.deleteSync();
    }

    if (dartSvg != null && cppSvg.existsSync()) {
      final result = comparator.compare(
          dartSvg: dartSvg, goldenSvg: cppSvg.readAsStringSync());
      final key = !result.structuralClean
          ? _statusStructural
          : (result.numericClean ? '' : _statusNumeric);
      status[stem] = key;
      if (!result.structuralClean) {
        structural++;
      } else if (!result.numericClean) {
        numericOnly++;
      } else {
        clean++;
      }
    } else {
      status[stem] = _statusUnknown;
      unknown++;
    }
  }

  stdout.writeln('C++: $cppOk rasterizado(s), $cppMissingGolden sem golden, '
      '$cppFail falha(s)');
  stdout.writeln('Dart: $dartOk rasterizado(s), $dartNoRender sem render, '
      '$dartFail falha(s)');
  stdout.writeln('Comparação: $clean limpo(s), $structural estrutural(is), '
      '$numericOnly numérico(s), $unknown sem dado');
  _saveStatus(status);

  for (final family in families) {
    _writeFamilyGallery(family, status);
  }
  _writeIndex();
  stdout.writeln('Galeria: $galleryRoot/*.md, índice: $pngRoot/README.md');
}

/// `stem` (`família/arquivo`) → emoji marker, persisted across runs so
/// `--md-only` can rebuild gallery pages without re-rendering/re-comparing.
Map<String, String> _loadStatus() {
  final file = File(statusPath);
  if (!file.existsSync()) return {};
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return decoded.map((k, v) => MapEntry(k, v as String));
}

void _saveStatus(Map<String, String> status) {
  final sorted = Map.fromEntries(
      status.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  File(statusPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(sorted));
}

/// Rebuilds every family gallery page from whatever PNGs already exist under
/// [cppPngRoot]/[dartPngRoot], without re-rasterizing. Used to pick up
/// markdown-only changes (e.g. the image-tag syntax) quickly across the
/// whole corpus.
void _rebuildAllGalleries() {
  final families = <String>{};
  for (final root in [cppPngRoot, dartPngRoot]) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync().whereType<Directory>()) {
      families.add(entity.uri.pathSegments.where((s) => s.isNotEmpty).last);
    }
  }
  final status = _loadStatus();
  for (final family in families) {
    _writeFamilyGallery(family, status);
  }
  _writeIndex();
  stdout.writeln(
      '${families.length} galeria(s) reconstruída(s) a partir dos PNGs existentes.');
}

/// Shells out to ImageMagick to turn one SVG into one PNG at its native
/// document size (see the `width`/`height` attributes Verovio writes on the
/// root `<svg>`).
bool _rasterize(String svgPath, String pngPath) {
  final outFile = File(pngPath);
  outFile.parent.createSync(recursive: true);
  final result = Process.runSync('convert', [svgPath, pngPath]);
  return result.exitCode == 0;
}

List<String> _listCorpus() {
  final files = <String>[];
  for (final entity in Directory(corpusRoot).listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.mei')) {
      files.add(entity.path.replaceAll('\\', '/').substring(corpusRoot.length + 1));
    }
  }
  files.sort();
  return files;
}

/// Resolves the positional argument to a list of corpus-relative `.mei`
/// paths: a bare family name (`beam`), a path under [corpusRoot], or a
/// single `.mei` file.
List<String> _resolveSelection(String arg) {
  final all = _listCorpus();
  if (all.contains(arg)) return [arg]; // already corpus-relative
  final normalized = arg.replaceAll('\\', '/');
  final asFamily = all.where((rel) => rel.startsWith('$normalized/')).toList();
  if (asFamily.isNotEmpty) return asFamily;

  final path = normalized.startsWith('$corpusRoot/')
      ? normalized.substring(corpusRoot.length + 1)
      : normalized;
  if (path.endsWith('.mei') && all.contains(path)) return [path];
  final underPath = all.where((rel) => rel.startsWith('$path/')).toList();
  return underPath;
}

/// Writes `test/golden/png/gallery/<family>.md`: one row per corpus file in
/// that family, C++ golden next to the current Dart render. [status] maps
/// `família/arquivo` to an emoji marker (🔴 estrutural, 🟡 numérico, ⚪ sem
/// dado, '' limpo) — GitHub strips `style`/`bgcolor` from rendered markdown
/// (verified via the `gh api markdown` endpoint), so a real red/yellow row
/// background isn't achievable there; the emoji is the closest equivalent.
void _writeFamilyGallery(String family, Map<String, String> status) {
  final cppDir = Directory('$cppPngRoot/$family');
  final dartDir = Directory('$dartPngRoot/$family');
  final stems = <String>{};
  if (cppDir.existsSync()) {
    for (final f in cppDir.listSync().whereType<File>()) {
      if (f.path.endsWith('.png')) {
        stems.add(f.uri.pathSegments.last.replaceAll('.png', ''));
      }
    }
  }
  if (dartDir.existsSync()) {
    for (final f in dartDir.listSync().whereType<File>()) {
      if (f.path.endsWith('.png')) {
        stems.add(f.uri.pathSegments.last.replaceAll('.png', ''));
      }
    }
  }
  final sorted = stems.toList()..sort();

  final buf = StringBuffer()
    ..writeln('# $family — C++ × Dart')
    ..writeln()
    ..writeln(
        '[← índice](../README.md). Gerado por `dart run tool/render_png.dart`.')
    ..writeln('Estado atual apenas — cada execução sobrescreve as imagens '
        'desta página, não há histórico de versões aqui (ver '
        '`tool/SVG_VALIDATION.md` / `tool/compare_svg.dart` para o placar '
        'numérico). $_statusStructural divergência estrutural, '
        '$_statusNumeric só divergência numérica, sem marcador = limpo '
        '(eps=0), $_statusUnknown sem golden ou sem render Dart.')
    ..writeln()
    ..writeln('| Status | Arquivo | C++ | Dart |')
    ..writeln('|---|---|---|---|');
  for (final stem in sorted) {
    final cppExists = File('$cppPngRoot/$family/$stem.png').existsSync();
    final dartExists = File('$dartPngRoot/$family/$stem.png').existsSync();
    final cppCell = cppExists
        ? '![C++ $stem](../cpp/$family/$stem.png)'
        : '_(sem golden)_';
    final dartCell = dartExists
        ? '![Dart $stem](../dart/$family/$stem.png)'
        : '_(sem render)_';
    final marker = status['$family/$stem'] ?? _statusUnknown;
    buf.writeln('| $marker | $stem | $cppCell | $dartCell |');
  }

  final galleryFile = File('$galleryRoot/$family.md');
  galleryFile.parent.createSync(recursive: true);
  galleryFile.writeAsStringSync(buf.toString());
}

/// Writes `test/golden/png/README.md`: links to every family gallery that
/// currently has a page, with the corpus file count.
void _writeIndex() {
  final galleryDir = Directory(galleryRoot);
  final families = galleryDir.existsSync()
      ? (galleryDir.listSync().whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .map((f) => f.uri.pathSegments.last.replaceAll('.md', ''))
          .toList()
        ..sort())
      : <String>[];

  final buf = StringBuffer()
    ..writeln('# Galeria de renderização — C++ × Dart')
    ..writeln()
    ..writeln('Comparação visual PNG entre o SVG de referência do Verovio '
        '6.2.0 (C++) e a saída atual do port Dart, por família do corpus '
        '(`test/corpus/<família>/`). Regenerada com '
        '`dart run tool/render_png.dart --all`; mostra apenas o estado mais '
        'recente — sem histórico de versões anteriores.')
    ..writeln()
    ..writeln('| Família | Arquivos |')
    ..writeln('|---|---|');
  for (final family in families) {
    final count = Directory('$corpusRoot/$family')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mei'))
        .length;
    buf.writeln('| [$family](gallery/$family.md) | $count |');
  }

  final indexFile = File('$pngRoot/README.md');
  indexFile.parent.createSync(recursive: true);
  indexFile.writeAsStringSync(buf.toString());
}
