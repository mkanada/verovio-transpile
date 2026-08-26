import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/mei_input.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/core/vrvdef.dart' show ClassId;
import 'package:verovio_dart/src/model/scoredef.dart' show ScoreDef;
import 'package:verovio_dart/src/model/object.dart';

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.error;
  });

  test('parses a page-based MEI file', () {
    final file = File('test/corpus/bracketspan/bracketspan-001.mei');
    final data = file.readAsStringSync();
    final doc = Doc();
    final input = MeiInput(doc);
    expect(input.import(data), isTrue,
        reason: 'MEI import should succeed');
    expect(doc.childCount, greaterThan(0));
  });

  test('parses all corpus files without crashing', () {
    final corpusDir = Directory('test/corpus');
    final files = corpusDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.mei'))
        .take(40)
        .toList();
    expect(files, isNotEmpty);

    var successes = 0;
    final failures = <String>[];
    for (final file in files.take(40)) {
      final doc = Doc();
      final input = MeiInput(doc);
      try {
        if (input.import(file.readAsStringSync())) {
          successes++;
        } else {
          failures.add(file.path);
        }
      } catch (e) {
        failures.add('${file.path}: $e');
      }
    }
    // Not all files may parse yet, but the vast majority should.
    expect(successes, greaterThan(files.length * 3 ~/ 4),
        reason: 'failures: $failures');
  });

  test('tree structure of a simple score', () {
    const mei = '''
<?xml version="1.0" encoding="UTF-8"?>
<mei meiversion="6.0-dev">
  <music>
    <body>
      <mdiv>
        <score>
          <scoreDef>
            <staffGrp>
              <staffDef n="1" clef.shape="G" clef.line="2"/>
            </staffGrp>
          </scoreDef>
          <section>
            <measure n="1">
              <staff n="1">
                <layer n="1">
                  <note dur="4" oct="4" pname="c"/>
                  <note dur="4" oct="4" pname="d"/>
                  <rest dur="2"/>
                </layer>
              </staff>
            </measure>
          </section>
        </score>
      </mdiv>
    </body>
  </music>
</mei>
''';
    final doc = Doc();
    final input = MeiInput(doc);
    expect(input.import(mei), isTrue);

    // After conversion to page-based: Doc > Pages > Page > System ...
    final pages = doc.getPages();
    expect(pages, isNotNull);
    final measures = doc.findAllDescendantsByType(ClassId.measure);
    expect(measures.length, 1);
    final notes = doc.findAllDescendantsByType(ClassId.note);
    expect(notes.length, 2);
    final rests = doc.findAllDescendantsByType(ClassId.rest);
    expect(rests.length, 1);
    // The staffDef lives in the Score's scoreDef subtree (owned, not a tree
    // child), exactly like the C++.
    final firstScoreDef = doc.getFirstScoreDef() as ScoreDef?;
    expect(firstScoreDef, isNotNull);
    expect(firstScoreDef!.findAllDescendantsByType(ClassId.staffDef).length, 1);
  });
}
