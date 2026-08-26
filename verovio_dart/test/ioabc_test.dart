import 'package:test/test.dart';
import 'package:verovio_dart/src/core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart' show ClassId;
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/ioabc.dart';
import 'package:verovio_dart/src/io/xml_node.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' hide Tie;
import 'package:verovio_dart/src/model/basic_elements.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/misc_elements_gen.dart'
    show Text;

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.error;
  });

  group('AbcInput', () {
    test('imports a simple ABC tune', () {
      const abc = 'X:1\nT:Test\nM:4/4\nL:1/4\nK:C\nCDEF GABc |]\n';
      final doc = Doc();
      final input = AbcInput(doc);
      expect(input.import(abc), isTrue);
    });

    test('produces Pages > Page > System > Measure > Staff > Layer', () {
      const abc = 'X:1\nT:Test\nM:4/4\nL:1/4\nK:C\nCDEF GABc |]\n';
      final doc = Doc();
      final input = AbcInput(doc);
      expect(input.import(abc), isTrue);

      // The document was converted to a page-based document.
      final pages = doc.findDescendantByType(ClassId.pages) as Pages?;
      expect(pages, isNotNull);

      final page = pages!.getFirst(ClassId.page);
      expect(page, isNotNull);

      final system = page!.getFirst(ClassId.system);
      expect(system, isNotNull);

      final measures = system!.findAllDescendantsByType(ClassId.measure);
      expect(measures.length, 1);

      final staves = system.findAllDescendantsByType(ClassId.staff);
      expect(staves.length, 1);

      final layers = system.findAllDescendantsByType(ClassId.layer);
      expect(layers.length, 1);
    });

    test('reads 8 notes with pitch / octave / duration', () {
      const abc = 'X:1\nT:Test\nM:4/4\nL:1/4\nK:C\nCDEF GABc |]\n';
      final doc = Doc();
      final input = AbcInput(doc);
      expect(input.import(abc), isTrue);

      final notes =
          doc.findDescendantByType(ClassId.pages)!
              .findAllDescendantsByType(ClassId.note)
              .cast<Note>()
              .toList();
      // "CDEF GABc" -> 8 notes (the two groups are beamed).
      expect(notes.length, 8);

      expect(
        notes.map((n) => n.pname).toList(),
        [
          Pitchname.c,
          Pitchname.d,
          Pitchname.e,
          Pitchname.f,
          Pitchname.g,
          Pitchname.a,
          Pitchname.b,
          Pitchname.c,
        ],
      );
      // Uppercase letters are octave 4, lowercase are octave 5.
      expect(notes.map((n) => n.oct).toList(),
          [4, 4, 4, 4, 4, 4, 4, 5]);
      // L:1/4 -> quarter notes.
      for (final note in notes) {
        expect(note.dur, MeiDuration.dur4);
      }
      // Quarters cannot be beamed (GetDur() < DURATION_8): they are written
      // directly into the layer.
      final beams = doc
          .findDescendantByType(ClassId.pages)!
          .findAllDescendantsByType(ClassId.beam);
      expect(beams.length, 0);
    });

    test('groups eighth notes into beams', () {
      const abc = 'X:1\nT:B\nM:4/4\nL:1/8\nK:C\nCDEF GABc |]\n';
      final doc = Doc();
      expect(AbcInput(doc).import(abc), isTrue);

      final pages = doc.findDescendantByType(ClassId.pages)!;
      // Each space-terminated group of four eighths becomes one beam.
      expect(pages.findAllDescendantsByType(ClassId.beam).length, 2);
      expect(pages.findAllDescendantsByType(ClassId.note).length, 8);
    });

    test('sets the closing barline of the measure', () {
      const abc = 'X:1\nT:Test\nL:1/4\nK:C\nCDEF |]\n';
      final doc = Doc();
      AbcInput(doc).import(abc);

      final measure = doc
          .findDescendantByType(ClassId.pages)!
          .findDescendantByType(ClassId.measure) as Measure?;
      expect(measure, isNotNull);
      expect(measure!.right, Barrendition.end);
    });

    test('parses rests and invisible spaces', () {
      const abc = 'X:1\nT:R\nL:1/4\nK:C\nz2 x z |]\n';
      final doc = Doc();
      expect(AbcInput(doc).import(abc), isTrue);

      final pages = doc.findDescendantByType(ClassId.pages)!;
      final rests = pages.findAllDescendantsByType(ClassId.rest).cast<Rest>();
      expect(rests.length, 2);
      // z2 is a half rest under L:1/4.
      expect(rests.first.dur, MeiDuration.dur2);
      expect(pages.findAllDescendantsByType(ClassId.space).length, 1);
    });

    test('applies key signature accidentals as gestural accids', () {
      const abc = 'X:1\nT:G\nL:1/4\nK:G\nf f |]\n';
      final doc = Doc();
      expect(AbcInput(doc).import(abc), isTrue);

      final notes = doc
          .findDescendantByType(ClassId.pages)!
          .findAllDescendantsByType(ClassId.note)
          .cast<Note>()
          .toList();
      expect(notes.length, 2);
      // K:G raises F -> the note gets an @accid.ges="s" attribute accid.
      final accids =
          notes.first.findAllDescendantsByType(ClassId.accid).cast<Accid>();
      expect(accids.length, 1);
      expect(accids.first.isAttribute, isTrue);
      expect(accids.first.accidGes, AccidentalGestural.s);
    });

    test('attaches lyrics from w: lines to the previous music line', () {
      const abc = 'X:1\nT:L\nL:1/4\nK:C\nC D |]\nw: sol fa\n';
      final doc = Doc();
      expect(AbcInput(doc).import(abc), isTrue);

      final notes = doc
          .findDescendantByType(ClassId.pages)!
          .findAllDescendantsByType(ClassId.note)
          .cast<Note>()
          .toList();
      expect(notes.length, 2);
      final verse = notes.first.getFirst(ClassId.verse) as Verse?;
      expect(verse, isNotNull);
      final syl = verse!.getFirst(ClassId.syl) as Syl?;
      expect(syl, isNotNull);
      final text = syl!.children.whereType<Text>().firstOrNull;
      expect(text?.text, 'sol');
    });

    test('creates a meiHead with a work entry in doc.header', () {
      const abc = 'X:1\nT:Header\nC:Anon\nL:1/4\nK:C\nC |]\n';
      final doc = Doc();
      expect(AbcInput(doc).import(abc), isTrue);

      final header = doc.header as MeiXmlNode?;
      expect(header, isNotNull);
      expect(header!.name, 'meiHead');
      final workList = header.child('workList');
      expect(workList, isNotNull);
      final work = workList!.child('work');
      expect(work, isNotNull);
      expect(work!.attr('n'), '1');
      final titleNode = work.child('title');
      expect(titleNode, isNotNull);
      expect(titleNode!.textValue(), 'Header');
      expect(work.child('composer')?.textValue(), 'Anon');

      // fileDesc titleStmt exists
      final fileDesc = header.child('fileDesc');
      expect(fileDesc, isNotNull);
      expect(fileDesc!.child('titleStmt')?.child('title'), isNotNull);
    });
  });
}
