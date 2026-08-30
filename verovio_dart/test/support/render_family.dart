/// Support code for the port — not a port of any C++ file.
///
/// Helpers to render a corpus family (directory or list of directories) and
/// aggregate structural comparison against `test/golden/cpp/**.svg` goldens.
///
/// Uses the Phase-5 harness hook `renderSvgForComparison` and `SvgComparator`
/// (structural mode, epsilon 0). Aggregates into counts of `limpos`
/// (structuralClean), `divergentes`, and `falhas` (exceptions during rendering).
///
/// Deviations from the C++: none — this is port support code (§4.1).
library;

import 'dart:io';

import 'package:verovio_dart/src/core/attdef.dart';
import 'package:verovio_dart/src/core/bounding_box.dart';
import 'package:verovio_dart/src/core/devicecontextbase.dart';
import 'package:verovio_dart/src/core/point.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/rendering/svg_device_context.dart';
import 'package:verovio_dart/src/testing/svg_compare.dart';

/// Resultado agregado de renderizar uma família de arquivos MEI.
class FamiliaResultado {
  FamiliaResultado({
    required this.corpusDirs,
    required this.total,
    required this.limpos,
    required this.divergentes,
    required this.falhas,
    required this.detalhes,
  });

  /// Diretórios de corpus examinados (ex.: `['test/corpus/beam']`).
  final List<String> corpusDirs;

  /// Arquivos MEI considerados (exclui os sem golden).
  final int total;

  /// Arquivos estruturalmente limpos (`structuralClean == true`).
  final int limpos;

  /// Arquivos divergentes (renderizou mas diverge estruturalmente).
  final int divergentes;

  /// Caminhos (relativos) que lançaram exceção durante `renderSvgForComparison`.
  final List<String> falhas;

  /// Primeiras divergências estruturais por arquivo (para `reason`).
  final List<String> detalhes;


  /// Conveniência: nenhum arquivo lançou exceção (ou todas estão em lista
  /// conhecida quando o chamador filtra).
  bool get falhasIsEmpty => falhas.isEmpty;
}

/// Renderiza todos os `.mei` sob [corpusDir] (não recursivo; um nível) e
/// compara cada um com seu golden em `test/golden/cpp/**.svg`.
///
/// * `falhasConhecidas05_36` é a lista explícita de arquivos que ainda lançam
///   exceção até a tarefa 05-36 — nunca usada para mascarar falhas novas;
///   o chamador deve assertar que `falhas` fora dessa lista é vazia.
FamiliaResultado renderizarFamilia(
  String corpusDir, {
  List<String> falhasConhecidas05_36 = const [],
  double epsilon = 0,
}) {
  return renderizarFamilias([corpusDir],
      falhasConhecidas05_36: falhasConhecidas05_36, epsilon: epsilon);
}

/// Renderiza a união de [corpusDirs] (cada um é um diretório sob
/// `test/corpus/`) e agrega.
FamiliaResultado renderizarFamilias(
  List<String> corpusDirs, {
  List<String> falhasConhecidas05_36 = const [],
  double epsilon = 0,
}) {
  int total = 0;
  int limpos = 0;
  int divergentes = 0;
  final falhas = <String>[];
  final detalhes = <String>[];

  for (final corpusDir in corpusDirs) {
    final dir = Directory(corpusDir);
    if (!dir.existsSync()) continue;
    // Ordena para determinismo.
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mei'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final path = file.path;
      final goldenPath = path
          .replaceAll('test/corpus/', 'test/golden/cpp/')
          .replaceAll('.mei', '.svg');
      final goldenFile = File(goldenPath);
      if (!goldenFile.existsSync()) {
        // Sem golden não conta como falha nem limpo; ignora.
        continue;
      }
      total++;
      try {
        final dartSvg = renderSvgForComparison(path);
        if (dartSvg == null) {
          // Import falhou — trata como divergente com detalhe.
          divergentes++;
          detalhes.add(
              '$path: renderSvgForComparison retornou null (import falhou)');
          continue;
        }
        final goldenSvg = goldenFile.readAsStringSync();
        final result = SvgComparator(epsilon: epsilon)
            .compare(dartSvg: dartSvg, goldenSvg: goldenSvg);
        if (result.structuralClean) {
          limpos++;
        } else {
          divergentes++;
          if (result.structuralDivergences.isNotEmpty) {
            detalhes.add('$path: ${result.structuralDivergences.first}');
          } else {
            detalhes.add(
                '$path: divergente sem detalhe (${result.structuralDivergenceCount})');
          }
        }
      } catch (e, st) {
        final msg = '$path: $e';
        // Se estiver na lista conhecida, ainda registra como falha para o
        // chamador decidir; não silencia.
        falhas.add(msg);
        // Opcional: detalhes também.
        detalhes.add('$path exceção: $e ${st.toString().split('\n').first}');
        // Se a falha era conhecida, não conta como divergente adicional;
        // o total já conta.
      }
    }
  }
  return FamiliaResultado(
    corpusDirs: corpusDirs,
    total: total,
    limpos: limpos,
    divergentes: divergentes,
    falhas: falhas,
    detalhes: detalhes,
  );
}

/// Atalho para renderizar um único arquivo MEI e devolver o SVG de Dart
/// (ou lançar). Usado para asserções sobre a saída (instrumento 2).
String renderizar(String meiPath) {
  final svg = renderSvgForComparison(meiPath);
  if (svg == null) throw StateError('renderizar: import falhou para $meiPath');
  return svg;
}

/// Extrai o conjunto de códigos de glifo em `<defs>` de um SVG (ex.: `E050`).
Set<String> glifosEmDefs(String svg) {
  final re = RegExp(r'<g id="([A-F0-9]+)-[^"]+">');
  return re.allMatches(svg).map((m) => m.group(1)!).toSet();
}

/// Verifica se o SVG contém um elemento com determinada classe (token exato).
bool svgContemClasse(String svg, String klass) {
  // Procura class="... klass ...".
  final re = RegExp(r'class="([^"]*)"');
  for (final m in re.allMatches(svg)) {
    final tokens = m.group(1)!.split(RegExp(r'\s+'));
    if (tokens.contains(klass)) return true;
  }
  return false;
}

/// Recording DeviceContext for instrument 3 — registra chamadas.
///
/// Estende [SvgDeviceContext] (que já implementa todo o contrato de
/// [DeviceContext] gerando SVG) e intercepta as primitivas que `View` chama.
/// A lista [chamadas] contém entradas como `startGraphic:beam:xxx`,
/// `drawMusicText:E050:...`, `endGraphic`, permitindo assertar a sequência
/// `startGraphic → drawSmuflCode → endGraphic`.
class RecordingDeviceContext extends SvgDeviceContext {
  RecordingDeviceContext({String docId = 'docid'}) : super(docId);

  final List<String> chamadas = [];

  @override
  void startGraphic(BoundingBox object, String gClass, String gId,
      {GraphicID graphicID = GraphicID.primary, bool prepend = false}) {
    chamadas.add('startGraphic:$gClass:$gId:${graphicID.name}');
    super.startGraphic(object, gClass, gId,
        graphicID: graphicID, prepend: prepend);
  }

  @override
  void endGraphic(BoundingBox object) {
    chamadas.add('endGraphic');
    super.endGraphic(object);
  }

  @override
  void resumeGraphic(BoundingBox object, String gId) {
    chamadas.add('resumeGraphic:$gId');
    super.resumeGraphic(object, gId);
  }

  @override
  void endResumedGraphic(BoundingBox object) {
    chamadas.add('endResumedGraphic');
    super.endResumedGraphic(object);
  }

  @override
  void startText(int x, int y,
      [HorizontalAlignment alignment = HorizontalAlignment.left]) {
    chamadas.add('startText:$x,$y:${alignment.name}');
    super.startText(x, y, alignment);
  }

  @override
  void endText() {
    chamadas.add('endText');
    super.endText();
  }

  @override
  void drawMusicText(String text, int x, int y, {bool setSmuflGlyph = false}) {
    final codes = text.runes
        .map((r) => r.toRadixString(16).toUpperCase().padLeft(4, '0'))
        .join(',');
    chamadas.add('drawMusicText:$codes:$x,$y:$setSmuflGlyph');
    super.drawMusicText(text, x, y, setSmuflGlyph: setSmuflGlyph);
  }

  @override
  void drawText(String text,
      {String? wtext,
      int x = 57005,
      int y = 57005,
      int width = 57005,
      int height = 57005}) {
    chamadas.add('drawText:$text:$x,$y');
    super
        .drawText(text, wtext: wtext, x: x, y: y, width: width, height: height);
  }

  @override
  void drawEllipse(int x, int y, int width, int height) {
    chamadas.add('drawEllipse:$x,$y,$width,$height');
    super.drawEllipse(x, y, width, height);
  }

  @override
  void drawCircle(int x, int y, int radius) {
    chamadas.add('drawCircle:$x,$y,$radius');
    super.drawCircle(x, y, radius);
  }

  @override
  void drawLine(int x1, int y1, int x2, int y2) {
    chamadas.add('drawLine:$x1,$y1,$x2,$y2');
    super.drawLine(x1, y1, x2, y2);
  }

  @override
  void drawPolygon(List<Point> points) {
    chamadas.add('drawPolygon:${points.length}');
    super.drawPolygon(points);
  }

  @override
  void drawRectangle(int x, int y, int width, int height) {
    chamadas.add('drawRectangle:$x,$y,$width,$height');
    super.drawRectangle(x, y, width, height);
  }

  @override
  void drawPolyline(List<Point> points, {bool close = false}) {
    chamadas.add('drawPolyline:${points.length}:$close');
    super.drawPolyline(points, close: close);
  }

  @override
  void drawRoundedRectangle(int x, int y, int width, int height, int radius) {
    chamadas.add('drawRoundedRectangle:$x,$y,$width,$height,$radius');
    super.drawRoundedRectangle(x, y, width, height, radius);
  }

  @override
  void drawQuadBezierPath(List<Point> bezier) {
    chamadas.add('drawQuadBezierPath:${bezier.length}');
    super.drawQuadBezierPath(bezier);
  }

  @override
  void drawCubicBezierPath(List<Point> bezier) {
    chamadas.add('drawCubicBezierPath:${bezier.length}');
    super.drawCubicBezierPath(bezier);
  }

  @override
  void drawCubicBezierPathFilled(List<Point> bezier1, List<Point> bezier2) {
    chamadas
        .add('drawCubicBezierPathFilled:${bezier1.length}:${bezier2.length}');
    super.drawCubicBezierPathFilled(bezier1, bezier2);
  }

  @override
  void drawBentParallelogramFilled(List<Point> side, int height) {
    chamadas.add('drawBentParallelogramFilled:${side.length}:$height');
    super.drawBentParallelogramFilled(side, height);
  }

  @override
  void setPen(int width, PenStyle style,
      {int dashLength = 0,
      int gapLength = 0,
      LineCapStyle lineCap = LineCapStyle.default_,
      LineJoinStyle lineJoin = LineJoinStyle.default_,
      double opacity = -1.0,
      int color = colorNone}) {
    chamadas.add('setPen:$width:${style.name}');
    super.setPen(width, style,
        dashLength: dashLength,
        gapLength: gapLength,
        lineCap: lineCap,
        lineJoin: lineJoin,
        opacity: opacity,
        color: color);
  }

  @override
  void setBrush(double opacity, [int color = colorNone]) {
    chamadas.add('setBrush:$opacity:$color');
    super.setBrush(opacity, color);
  }

  @override
  void setFont(FontInfo font) {
    chamadas.add('setFont:${font.pointSize}');
    super.setFont(font);
  }
}
