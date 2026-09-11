// Guards the port-only FunctorBase.checkpointHook the state-snapshot tools
// (tool/snapshot.dart, cpp_probe/snapshot.sh) are built on: it must see the
// top-level functor runs and the page draws, and installing it must not change
// a single byte of the SVG — the snapshot is only worth anything if observing
// the pipeline leaves it untouched.
import 'package:test/test.dart';
import 'package:verovio_dart/src/factory_registry.dart'
    show registerModelClasses;
import 'package:verovio_dart/src/layout/functor.dart' show FunctorBase;
import 'package:verovio_dart/src/rendering/resources.dart' show Resources;
import 'package:verovio_dart/src/testing/svg_compare.dart'
    show renderSvgForComparison;

void main() {
  setUpAll(() {
    registerModelClasses();
    Resources.defaultPath = 'assets/data';
  });

  tearDown(() => FunctorBase.checkpointHook = null);

  test('checkpointHook sees functors and page draws without changing the SVG',
      () {
    const String file = 'test/corpus/beam/beam-001.mei';
    final String? clean = renderSvgForComparison(file);
    expect(clean, isNotNull);

    final List<String> labels = [];
    FunctorBase.checkpointHook = (label, object) => labels.add(label);
    final String? hooked = renderSvgForComparison(file);
    FunctorBase.checkpointHook = null;

    expect(hooked, clean);
    expect(labels, contains('AlignHorizontallyFunctor'));
    expect(labels, contains('View::DrawCurrentPage[bbox]'));
    expect(labels.last, 'View::DrawCurrentPage[svg]');
    expect(FunctorBase.processDepth, 0);
  });
}
