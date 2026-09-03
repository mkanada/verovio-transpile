import 'package:verovio_dart/src/testing/svg_compare.dart' as svg_compare;
import 'package:verovio_dart/src/factory_registry.dart' as factory_registry;

void main() {
  factory_registry.registerModelClasses();
  final svg = svg_compare.renderSvgForComparison('test/corpus/ossia/ossia-002.mei');
  print(svg);
}