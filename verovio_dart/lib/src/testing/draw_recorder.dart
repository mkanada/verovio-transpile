/// Support code for the port — not a port of any C++ file.
///
/// Mirrors `cpp_probe/patches/05-38.patch` (`SvgDeviceContext` instrumentation):
/// `DrawRecorder` extends [SvgDeviceContext] and emits the same JSON record
/// format as the instrumented C++ binary (`cpp_probe/run.sh 05-38`) — one line
/// per device-context primitive, with `fn`, global sequence `seq`, structural
/// `path` (`probe::Path` / `cppPath`), `id`, and all numeric / glyph-code
/// arguments using the **C++ parameter names** (`00-MESTRE.md` §6-bis).
///
/// Where Dart's signature differs from the C++ (noted below), the C++ name is
/// kept and the deviation is commented, as required by the prompt Part 2.
///
/// Deviations from the C++:
/// - `DrawSmuflCode` / `DrawSmuflString` / `DrawSmuflLine` are not methods of
///   `SvgDeviceContext` in either C++ or Dart — the SMuFL conduit is
///   `DeviceContext::DrawMusicText` (C++ `svgdevicecontext.cpp:1153`,
///   Dart `svg_device_context.dart:1579`). The recorder maps the observed
///   `text` length to `DrawSmuflCode` (single glyph), `DrawSmuflLine` (long
///   repeat of the same code, as in `View::DrawSmuflLine` view_graph.cpp:297),
///   and `DrawSmuflString` otherwise, exactly like the C++ probe does, so the
///   two sides emit the same `fn` for the same call. The parameter names
///   `code` / `text` / `setSmuflGlyph` vs `setBBGlyph` are kept as C++
///   `DrawSmufl*` names, commented at the emission site.
/// - `DrawCurve` is the prompt's generic name for the bezier family. The C++
///   probe emits `fn=DrawCurve` for `DrawQuadBezierPath`,
///   `DrawCubicBezierPath`, `DrawCubicBezierPathFilled`, and
///   `DrawBentParallelogramFilled` (svgdevicecontext.cpp:670,693,717,740);
///   Dart does the same, so `--rank` groups them together.
/// - `meiUnset` (`VRV_UNSET` in C++) is `57005` in Dart (`core/attdef.dart`);
///   the field names are the C++ ones (`x`, `y`, `width`, `height`).
/// - Dart's `drawPolyline` carries points as `List<Point>` rather than
///   `int n, Point points[]`; the field `n` is emitted as `points.length`
///   (C++ `n`) and `points` as a flattened `"x1,y1 x2,y2 "` string, matching
///   the C++ probe's `points` string. Similarly `drawPolygon`.
library;

import 'dart:convert';

import 'package:verovio_dart/src/core/attdef.dart'
    show HorizontalAlignment, meiUnset;
import 'package:verovio_dart/src/core/bounding_box.dart' show BoundingBox;
import 'package:verovio_dart/src/core/point.dart' show Point;
import 'package:verovio_dart/src/core/vrvdef.dart' show ClassId, GraphicID;
import 'package:verovio_dart/src/model/atts/atts_shared.dart'
    show AttNInteger, AttNNumberLike;
import 'package:verovio_dart/src/model/object.dart' as model;
import 'package:verovio_dart/src/rendering/svg_device_context.dart';

/// Recorder for the drawing-probe instrument (05-38).
///
/// Extends [SvgDeviceContext] and overrides the same primitives instrumented
/// in `cpp_probe/patches/05-38.patch`, emitting an identical JSON record
/// stream.
class DrawRecorder extends SvgDeviceContext {
  DrawRecorder({String docId = 'docid'}) : super(docId);

  final List<Map<String, Object?>> _records = [];
  final List<BoundingBox> _objectStack = [];
  int _seq = 0;

  /// All records emitted so far, in call order.
  List<Map<String, Object?>> get records => List.unmodifiable(_records);

  /// One JSON line per record, as the fixture stores it.
  String toJsonl() =>
      _records.map((m) => jsonEncode(m)).join('\n') +
      (_records.isEmpty ? '' : '\n');

  // -------------------------------------------------------------------------
  // path helpers — mirror `vrv::probe::Path` / `test/fixtures/cpp_fixture.dart:cppPath`
  // -------------------------------------------------------------------------

  String _pathFor(BoundingBox? box) {
    if (box == null) return '';
    final obj = box as model.Object;
    return _cppPath(obj);
  }

  String _currentPath() =>
      _objectStack.isEmpty ? '' : _pathFor(_objectStack.last);

  String _currentId() {
    if (_objectStack.isEmpty) return '';
    final obj = _objectStack.last as model.Object;
    return obj.id;
  }

  String _cppPath(model.Object? object) {
    if (object == null) return '';
    final List<String> segments = <String>[];
    model.Object? current = object;
    while (current != null && current.classId != ClassId.doc) {
      segments.add(_cppSegment(current));
      if (current.classId == ClassId.measure) break;
      current = current.parent;
    }
    return segments.reversed.join('/');
  }

  String _cppSegment(model.Object object) =>
      '${object.className}[${_cppSegmentKey(object)}]';

  String _cppSegmentKey(model.Object object) {
    final model.Object? parent = object.parent;
    switch (object.classId) {
      case ClassId.measure:
        final AttNNumberLike m = object as AttNNumberLike;
        final String? n = m.n;
        if (n != null && n.isNotEmpty) return n;
        break;
      case ClassId.staff:
      case ClassId.layer:
        final AttNInteger e = object as AttNInteger;
        if (e.hasN) return '${e.n}';
        break;
      default:
        break;
    }
    if (parent == null) return '1';
    if (parent.classId == ClassId.measure) {
      final dynamic measure = parent;
      try {
        if (identical(object, measure.leftBarLine)) return 'left';
        if (identical(object, measure.rightBarLine)) return 'right';
        // also via getters if available
        final dynamic l = measure.getLeftBarLine != null
            ? (measure.getLeftBarLine() as dynamic)
            : null;
        if (l != null && identical(object, l)) return 'left';
        final dynamic r = measure.getRightBarLine != null
            ? (measure.getRightBarLine() as dynamic)
            : null;
        if (r != null && identical(object, r)) return 'right';
      } catch (_) {}
      // fallback direct field compare already done
      try {
        if (object == measure.leftBarLine) {
          return 'left';
        }
        if (object == measure.rightBarLine) {
          return 'right';
        }
      } catch (_) {}
    } else if (parent.classId == ClassId.layer) {
      final dynamic layer = parent;
      try {
        if (identical(object, layer.staffDefClef) ||
            identical(object, layer.staffDefKeySig) ||
            identical(object, layer.staffDefMensur) ||
            identical(object, layer.staffDefMeterSig) ||
            identical(object, layer.staffDefMeterSigGrp)) {
          return 'staffDef';
        }
        if (identical(object, layer.cautionStaffDefClef) ||
            identical(object, layer.cautionStaffDefKeySig) ||
            identical(object, layer.cautionStaffDefMensur) ||
            identical(object, layer.cautionStaffDefMeterSig)) {
          return 'caution';
        }
        // also try via getters
        try {
          if (identical(object, layer.getStaffDefClef?.call())) {
            return 'staffDef';
          }
          if (identical(object, layer.getStaffDefKeySig?.call())) {
            return 'staffDef';
          }
        } catch (_) {}
      } catch (_) {}
    }
    int index = 0;
    final String className = object.className;
    for (final model.Object child in parent.children) {
      if (child.className != className) continue;
      ++index;
      if (identical(child, object)) return '$index';
    }
    return '?';
  }

  String _hex4(int code) =>
      code.toRadixString(16).toUpperCase().padLeft(4, '0');

  String _u32ToHex(String text) => text.runes.map(_hex4).join(',');

  void _emit(Map<String, Object?> rec) {
    _records.add(rec);
  }

  // -------------------------------------------------------------------------
  // Graphic lifecycle — mirrors svgdevicecontext.cpp:249,418,429,453,466
  // -------------------------------------------------------------------------

  @override
  void startGraphic(BoundingBox object, String gClass, String gId,
      {GraphicID graphicID = GraphicID.primary, bool prepend = false}) {
    final seq = ++_seq;
    final obj = object as model.Object;
    final path = _cppPath(obj);
    // push before emission? C++ pushes then emits with same path; order irrelevant as path is of object itself
    _objectStack.add(object);
    _emit({
      'fn': 'StartGraphic',
      'seq': seq,
      'path': path,
      'id': obj.id,
      'gClass': gClass,
      'gId': gId,
      'graphicID': graphicID.index,
      'prepend': prepend ? 1 : 0,
    });
    super.startGraphic(object, gClass, gId,
        graphicID: graphicID, prepend: prepend);
  }

  @override
  void endGraphic(BoundingBox object) {
    final seq = ++_seq;
    final obj = object as model.Object;
    _emit({
      'fn': 'EndGraphic',
      'seq': seq,
      'path': _cppPath(obj),
      'id': obj.id,
    });
    if (_objectStack.isNotEmpty) _objectStack.removeLast();
    super.endGraphic(object);
  }

  @override
  void resumeGraphic(BoundingBox object, String gId) {
    final seq = ++_seq;
    final obj = object as model.Object;
    final path = _cppPath(obj);
    _objectStack.add(object);
    _emit({
      'fn': 'ResumeGraphic',
      'seq': seq,
      'path': path,
      'id': obj.id,
      'gId': gId,
    });
    super.resumeGraphic(object, gId);
  }

  @override
  void endResumedGraphic(BoundingBox object) {
    final seq = ++_seq;
    final obj = object as model.Object;
    _emit({
      'fn': 'EndResumedGraphic',
      'seq': seq,
      'path': _cppPath(obj),
      'id': obj.id,
    });
    if (_objectStack.isNotEmpty) _objectStack.removeLast();
    super.endResumedGraphic(object);
  }

  @override
  void rotateGraphic(Point orig, double angle) {
    final seq = ++_seq;
    _emit({
      'fn': 'RotateGraphic',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'origX': orig.x,
      'origY': orig.y,
      'angle': angle,
    });
    super.rotateGraphic(orig, angle);
  }

  // -------------------------------------------------------------------------
  // Text lifecycle
  // -------------------------------------------------------------------------

  @override
  void startText(int x, int y,
      [HorizontalAlignment alignment = HorizontalAlignment.left]) {
    final seq = ++_seq;
    _emit({
      'fn': 'StartText',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'x': x,
      'y': y,
      'alignment': alignment.value,
    });
    super.startText(x, y, alignment);
  }

  @override
  void endText() {
    final seq = ++_seq;
    _emit({
      'fn': 'EndText',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
    });
    super.endText();
  }

  // -------------------------------------------------------------------------
  // Drawing primitives
  // -------------------------------------------------------------------------

  @override
  void drawLine(int x1, int y1, int x2, int y2) {
    final seq = ++_seq;
    _emit({
      'fn': 'DrawLine',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
    });
    super.drawLine(x1, y1, x2, y2);
  }

  @override
  void drawPolyline(List<Point> points, {bool close = false}) {
    final seq = ++_seq;
    final pts = points.map((p) => '${p.x},${p.y}').join(' ');
    _emit({
      'fn': 'DrawPolyline',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'n': points.length,
      'close': close ? 1 : 0,
      'points': pts,
    });
    super.drawPolyline(points, close: close);
  }

  @override
  void drawPolygon(List<Point> points) {
    final seq = ++_seq;
    final pts = points.map((p) => '${p.x},${p.y}').join(' ');
    _emit({
      'fn': 'DrawPolygon',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'n': points.length,
      'points': pts,
    });
    super.drawPolygon(points);
  }

  @override
  void drawRectangle(int x, int y, int width, int height) {
    final seq = ++_seq;
    _emit({
      'fn': 'DrawRectangle',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    });
    super.drawRectangle(x, y, width, height);
  }

  @override
  void drawRoundedRectangle(int x, int y, int width, int height, int radius) {
    final seq = ++_seq;
    _emit({
      'fn': 'DrawRoundedRectangle',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'radius': radius,
    });
    super.drawRoundedRectangle(x, y, width, height, radius);
  }

  @override
  void drawText(String text,
      {String? wtext,
      int x = meiUnset,
      int y = meiUnset,
      int width = meiUnset,
      int height = meiUnset}) {
    final seq = ++_seq;
    _emit({
      'fn': 'DrawText',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'text': text,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    });
    super
        .drawText(text, wtext: wtext, x: x, y: y, width: width, height: height);
  }

  @override
  void drawMusicText(String text, int x, int y, {bool setSmuflGlyph = false}) {
    final seq = ++_seq;
    final hex = _u32ToHex(text);
    // C++ maps single-glyph to DrawSmuflCode, long same-glyph repeat to DrawSmuflLine
    String fn = 'DrawSmuflString';
    if (text.runes.length == 1) {
      fn = 'DrawSmuflCode';
    } else if (text.runes.length > 3) {
      final first = text.runes.first;
      bool same = text.runes.every((c) => c == first);
      if (same) fn = 'DrawSmuflLine';
    }
    // Deviation: C++ param names are code/start/fill etc for DrawSmuflLine,
    // but the device conduit only carries text/x/y/setSmuflGlyph; we emit
    // the union (code/text/x/y/setSmuflGlyph) using the DrawSmuflCode names
    // so probe_diff's per-field comparison matches the C++ fixture.
    _emit({
      'fn': fn,
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'x': x,
      'y': y,
      'code': hex,
      'text': hex,
      'setSmuflGlyph': setSmuflGlyph ? 1 : 0,
    });
    super.drawMusicText(text, x, y, setSmuflGlyph: setSmuflGlyph);
  }

  @override
  void drawQuadBezierPath(List<Point> bezier) {
    final seq = ++_seq;
    final b = bezier.map((p) => '${p.x},${p.y}').join(' ');
    _emit({
      'fn': 'DrawCurve',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'bezier': b,
    });
    super.drawQuadBezierPath(bezier);
  }

  @override
  void drawCubicBezierPath(List<Point> bezier) {
    final seq = ++_seq;
    final b = bezier.map((p) => '${p.x},${p.y}').join(' ');
    _emit({
      'fn': 'DrawCurve',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'bezier': b,
    });
    super.drawCubicBezierPath(bezier);
  }

  @override
  void drawCubicBezierPathFilled(List<Point> bezier1, List<Point> bezier2) {
    final seq = ++_seq;
    final b1 = bezier1.map((p) => '${p.x},${p.y}').join(' ');
    final b2 = bezier2.map((p) => '${p.x},${p.y}').join(' ');
    _emit({
      'fn': 'DrawCurve',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'bezier1': b1,
      'bezier2': b2,
    });
    super.drawCubicBezierPathFilled(bezier1, bezier2);
  }

  @override
  void drawBentParallelogramFilled(List<Point> side, int height) {
    final seq = ++_seq;
    final s = side.map((p) => '${p.x},${p.y}').join(' ');
    _emit({
      'fn': 'DrawCurve',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'side': s,
      'height': height,
    });
    super.drawBentParallelogramFilled(side, height);
  }

  @override
  void drawCircle(int x, int y, int radius) {
    final seq = ++_seq;
    _emit({
      'fn': 'DrawCircle',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'x': x,
      'y': y,
      'radius': radius,
    });
    super.drawCircle(x, y, radius);
  }

  @override
  void drawEllipse(int x, int y, int width, int height) {
    final seq = ++_seq;
    _emit({
      'fn': 'DrawEllipse',
      'seq': seq,
      'path': _currentPath(),
      'id': _currentId(),
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    });
    super.drawEllipse(x, y, width, height);
  }
}
