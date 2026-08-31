import 'dart:io';
import 'package:xml/xml.dart';

/// Dumps the element at a comparator path (like svg/svg[0]/g[0]/...) from one
/// or two SVG files, with a few lines of context.
void main(List<String> args) {
  final path = args[0]; // comparator path, e.g. svg/svg[0]/g[2]/g[1]
  for (final file in args.skip(1)) {
    final doc = XmlDocument.parse(File(file).readAsStringSync());
    var el = doc.rootElement;
    final parts = path.split('/')..removeAt(0); // drop leading 'svg' (root)
    for (final part in parts) {
      final m = RegExp(r'^(.+?)\[(\d+)\]$').firstMatch(part)!;
      final name = m.group(1)!;
      final idx = int.parse(m.group(2)!);
      final kids = el.childElements.where((c) => c.name.qualified == name).toList();
      if (idx >= kids.length) {
        stdout.writeln('$file: $name[$idx] not found (only ${kids.length})');
        el = XmlElement(XmlName('MISSING'));
        break;
      }
      el = kids[idx];
    }
    stdout.writeln('=== $file: $path ===');
    _dump(el, 0, depth: 6);
    stdout.writeln();
  }
}

void _dump(XmlElement el, int indent, {required int depth}) {
  if (depth < 0) return;
  final pad = '  ' * indent;
  final attrs = el.attributes.map((a) => '${a.name.qualified}="${_short(a.value)}"').join(' ');
  final kids = el.childElements.toList();
  if (kids.isEmpty) {
    final text = el.innerText.trim().replaceAll('\n', ' ');
    stdout.writeln('$pad<${el.name.qualified} $attrs>${text.isEmpty ? '' : ' TEXT: ${_short(text, 120)}'}</${el.name.qualified}>');
  } else {
    stdout.writeln('$pad<${el.name.qualified} $attrs> [${kids.length} kids]');
    for (final k in kids) {
      _dump(k, indent + 1, depth: depth - 1);
    }
  }
}

String _short(String s, [int n = 60]) =>
    s.length <= n ? s : '${s.substring(0, n)}...';
