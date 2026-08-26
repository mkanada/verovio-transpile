import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart' show ClassId;
import 'package:verovio_dart/src/model/atts/mei_enums.dart'
    show Barrendition, HairpinlogForm;
import 'package:verovio_dart/src/factory_registry.dart';
import 'package:verovio_dart/src/io/iomusxml.dart';
import 'package:verovio_dart/src/model/doc.dart';
import 'package:verovio_dart/src/model/object.dart';

const String twoPartsScore = '''
<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <work>
    <work-title>Transposition Test</work-title>
  </work>
  <identification>
    <creator type="composer">A Composer</creator>
    <encoding>
      <encoding-date>2020-01-01</encoding-date>
    </encoding>
  </identification>
  <part-list>
    <score-part id="P1">
      <part-name>Flute</part-name>
      <part-abbreviation>Fl.</part-abbreviation>
    </score-part>
    <score-part id="P2">
      <part-name>Cello</part-name>
      <part-abbreviation>Vc.</part-abbreviation>
    </score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>2</divisions>
        <key>
          <fifths>2</fifths>
          <mode>major</mode>
        </key>
        <time>
          <beats>4</beats>
          <beat-type>4</beat-type>
        </time>
        <clef>
          <sign>G</sign>
          <line>2</line>
        </clef>
      </attributes>
      <note>
        <pitch><step>C</step><octave>5</octave></pitch>
        <duration>2</duration>
        <voice>1</voice>
        <type>quarter</type>
      </note>
      <note>
        <pitch><step>E</step><octave>5</octave></pitch>
        <duration>1</duration>
        <voice>1</voice>
        <type>eighth</type>
        <beam number="1">begin</beam>
      </note>
      <note>
        <pitch><step>F</step><alter>1</alter><octave>5</octave></pitch>
        <duration>1</duration>
        <voice>1</voice>
        <type>eighth</type>
        <beam number="1">end</beam>
      </note>
      <note>
        <pitch><step>G</step><octave>5</octave></pitch>
        <duration>2</duration>
        <voice>1</voice>
        <type>quarter</type>
        <notations>
          <slur type="start" number="1"/>
        </notations>
      </note>
      <barline location="right">
        <bar-style>light-heavy</bar-style>
      </barline>
    </measure>
    <measure number="2">
      <note>
        <pitch><step>A</step><octave>5</octave></pitch>
        <duration>2</duration>
        <voice>1</voice>
        <type>quarter</type>
        <notations>
          <slur type="stop" number="1"/>
        </notations>
      </note>
      <note>
        <pitch><step>B</step><octave>5</octave></pitch>
        <duration>6</duration>
        <voice>1</voice>
        <type>half</type>
        <dot/>
      </note>
    </measure>
  </part>
  <part id="P2">
    <measure number="1">
      <attributes>
        <divisions>2</divisions>
        <key>
          <fifths>2</fifths>
        </key>
        <time>
          <beats>4</beats>
          <beat-type>4</beat-type>
        </time>
        <clef>
          <sign>F</sign>
          <line>4</line>
        </clef>
      </attributes>
      <note>
        <pitch><step>C</step><octave>3</octave></pitch>
        <duration>4</duration>
        <voice>1</voice>
        <type>half</type>
      </note>
      <note>
        <pitch><step>G</step><octave>2</octave></pitch>
        <duration>4</duration>
        <voice>1</voice>
        <type>half</type>
      </note>
    </measure>
    <measure number="2">
      <note>
        <rest/>
        <duration>8</duration>
        <voice>1</voice>
      </note>
    </measure>
  </part>
</score-partwise>
''';

void main() {
  setUpAll(() {
    registerModelClasses();
    logLevel = LogLevel.off;
  });

  test('imports a two-part score-partwise document', () {
    final doc = Doc();
    final input = MusicXmlInput(doc);
    expect(input.import(twoPartsScore), isTrue,
        reason: 'MusicXML import should succeed');

    // The doc is converted to a page-based document.
    expect(doc.getPages(), isNotNull);
    expect(doc.getPageCount(), greaterThan(0));

    // Two parts x two measures are merged into two measures.
    final measures = doc.findAllDescendantsByType(ClassId.measure);
    expect(measures.length, 2);

    // Each merged measure holds one staff per part (n=1 and n=2).
    final staves = doc.findAllDescendantsByType(ClassId.staff);
    expect(staves.length, 4);
    final layers = doc.findAllDescendantsByType(ClassId.layer);
    expect(layers.length, 4);

    // Notes: P1/m1: 4 (incl. two beamed eighths), P1/m2: 2, P2/m1: 2,
    // P2/m2: rest -> not a note.
    final notes = doc.findAllDescendantsByType(ClassId.note);
    expect(notes.length, 8);

    // The beam groups the two eighth notes.
    final beams = doc.findAllDescendantsByType(ClassId.beam);
    expect(beams.length, 1);
    expect(beams.first.childCount, 2);

    // The slur was matched to its end.
    final slurs = doc.findAllDescendantsByType(ClassId.slur);
    expect(slurs.length, 1);
    final dynamic slur = slurs.first;
    expect(slur.startid, isNotNull);
    expect(slur.endid, isNotNull);

    // The full-measure rest in P2/m2 becomes an mRest.
    final mRests = doc.findAllDescendantsByType(ClassId.mRest);
    expect(mRests.length, 1);
  });

  test('reads key and time signatures', () {
    final doc = Doc();
    final input = MusicXmlInput(doc);
    expect(input.import(twoPartsScore), isTrue);

    // Key signatures live in the staffDefs of the scoreDef.
    final Object? scoreDef = doc.getFirstScoreDef();
    expect(scoreDef, isNotNull);
    final keys = scoreDef!.findAllDescendantsByType(ClassId.keysig);
    expect(keys.length, 2);
    bool foundTwoSharps = false;
    for (final Object key in keys) {
      final dynamic keySig = key;
      if (keySig.sig != null &&
          keySig.sig.sig == 2 &&
          keySig.sig.accid.value ==
              // AccidentalWritten.s
              1) {
        foundTwoSharps = true;
      }
    }
    expect(foundTwoSharps, isTrue, reason: 'expected a two-sharp keySig');

    final meters = scoreDef.findAllDescendantsByType(ClassId.meterSig);
    expect(meters.length, 2);
    final dynamic meter = meters.first;
    expect(meter.unit, 4);
    expect(meter.count.counts, [4]);
  });

  test('rejects invalid XML', () {
    final doc = Doc();
    final input = MusicXmlInput(doc);
    expect(input.import('<not-xml'), isFalse);
  });

  test('parses MusicXML corpus files without crashing', () {
    final dir = Directory('test/corpus/midi');
    if (!dir.existsSync()) {
      return;
    }
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.musicxml') || f.path.endsWith('.xml'))
        .toList();
    expect(files, isNotEmpty);

    var successes = 0;
    final failures = <String>[];
    for (final file in files) {
      final doc = Doc();
      final input = MusicXmlInput(doc);
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
    expect(successes, greaterThan(0),
        reason: 'at least one corpus file should import; failures: $failures');
  });

  test('imports tuplets, chords, grace notes and directions', () {
    const complexScore = '''<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Piano</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>4</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <direction placement="above">
        <direction-type><words>Andante</words></direction-type>
        <sound tempo="72"/>
      </direction>
      <note>
        <pitch><step>G</step><octave>4</octave></pitch>
        <duration>4</duration>
        <voice>1</voice>
        <type>quarter</type>
        <lyric number="1"><syllabic>single</syllabic><text>la</text></lyric>
      </note>
      <note>
        <pitch><step>C</step><octave>5</octave></pitch>
        <duration>2</duration>
        <voice>1</voice>
        <type>eighth</type>
        <time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification>
        <notations><tuplet type="start" bracket="yes"/></notations>
      </note>
      <note>
        <pitch><step>D</step><octave>5</octave></pitch>
        <duration>2</duration>
        <voice>1</voice>
        <type>eighth</type>
        <time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification>
      </note>
      <note>
        <pitch><step>E</step><octave>5</octave></pitch>
        <duration>2</duration>
        <voice>1</voice>
        <type>eighth</type>
        <time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification>
        <notations><tuplet type="stop"/></notations>
      </note>
    </measure>
    <measure number="2">
      <note>
        <grace slash="yes"/>
        <pitch><step>D</step><octave>5</octave></pitch>
        <voice>1</voice>
        <type>eighth</type>
      </note>
      <note>
        <pitch><step>E</step><octave>5</octave></pitch>
        <duration>6</duration>
        <voice>1</voice>
        <type>quarter</type>
        <dot/>
        <notations>
          <articulations><staccato/></articulations>
          <technical><fingering>3</fingering></technical>
        </notations>
      </note>
      <note>
        <chord/>
        <pitch><step>G</step><octave>5</octave></pitch>
        <duration>6</duration>
        <voice>1</voice>
        <type>quarter</type>
        <dot/>
      </note>
      <direction placement="below">
        <direction-type><dynamics><p/></dynamics></direction-type>
      </direction>
      <direction placement="above">
        <direction-type><wedge type="crescendo" number="1"/></direction-type>
      </direction>
      <note>
        <rest/>
        <duration>8</duration>
        <voice>1</voice>
        <type>quarter</type>
      </note>
      <direction placement="above">
        <direction-type><wedge type="stop" number="1"/></direction-type>
      </direction>
    </measure>
  </part>
</score-partwise>''';
    final doc = Doc();
    final input = MusicXmlInput(doc);
    expect(input.import(complexScore), isTrue);

    final notes = doc.findAllDescendantsByType(ClassId.note);
    expect(notes.length, 7); // 4 (m1) + grace, chord tone and base (m2)

    final chords = doc.findAllDescendantsByType(ClassId.chord);
    expect(chords.length, 1);
    // The chord holds the staccato artic (attached to the chord container as
    // in the C++ reader) plus both notes.
    expect(chords.first.childCount, 3);

    final tuplets = doc.findAllDescendantsByType(ClassId.tuplet);
    expect(tuplets.length, 1);
    final dynamic tuplet = tuplets.first;
    expect(tuplet.num, 3);
    expect(tuplet.numbase, 2);

    // Grace note.
    var graces = 0;
    for (final Object n in notes) {
      if ((n as dynamic).hasGrace) graces++;
    }
    expect(graces, 1);

    // Direction-derived control elements.
    expect(doc.findAllDescendantsByType(ClassId.tempo).length, 1);
    expect(doc.findAllDescendantsByType(ClassId.dynam).length, 1);
    final hairpins = doc.findAllDescendantsByType(ClassId.hairpin);
    expect(hairpins.length, 1);
    expect((hairpins.first as dynamic).form.value,
        HairpinlogForm.cres.value);

    // Lyrics / articulations / fingering.
    expect(doc.findAllDescendantsByType(ClassId.syl).length, 1);
    expect(doc.findAllDescendantsByType(ClassId.artic).length, 1);
    expect(doc.findAllDescendantsByType(ClassId.fing).length, 1);
  });

  test('imports repeats, ties across measures and measure rests', () {
    const repeatScore = '''<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>V</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes><divisions>1</divisions><time><beats>1</beats><beat-type>4</beat-type></time><clef><sign>G</sign><line>2</line></clef></attributes>
      <barline location="left"><bar-style>heavy-light</bar-style><repeat direction="forward"/></barline>
      <note><pitch><step>C</step><octave>5</octave></pitch><duration>1</duration><type>quarter</type><tie type="start"/><notations><tied type="start"/></notations></note>
    </measure>
    <measure number="2">
      <note><pitch><step>C</step><octave>5</octave></pitch><duration>1</duration><type>quarter</type><tie type="stop"/><notations><tied type="stop"/></notations></note>
      <barline location="right"><bar-style>light-heavy</bar-style><repeat direction="backward"/></barline>
    </measure>
    <measure number="3">
      <note><rest measure="yes"/><duration>3</duration><voice>1</voice></note>
    </measure>
  </part>
</score-partwise>''';
    final doc = Doc();
    final input = MusicXmlInput(doc);
    logLevel = LogLevel.off;
    expect(input.import(repeatScore), isTrue);

    expect(doc.findAllDescendantsByType(ClassId.measure).length, 3);

    // The tie was matched across the barline.
    final ties = doc.findAllDescendantsByType(ClassId.tie);
    expect(ties.length, 1);
    final dynamic tie = ties.first;
    expect(tie.startid, isNotNull);
    expect(tie.endid, isNotNull);

    // Repeat barlines.
    final dynamic measure = doc.findAllDescendantsByType(ClassId.measure).first;
    expect(measure.left, Barrendition.rptstart);

    // The whole-measure rest becomes an mRest.
    expect(doc.findAllDescendantsByType(ClassId.mRest).length, 1);
  });
}

