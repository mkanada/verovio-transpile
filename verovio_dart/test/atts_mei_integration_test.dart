import 'dart:io';

import 'package:test/test.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/atts/mei_values.dart';
import 'package:xml/xml.dart';

/// Test note combining att.noteGes (gestural) and att.stems (visual).
class TestNote with AttDurationLog, AttOctave, AttPitch, AttStems {}

void main() {
  test('reads attributes from a real MEI corpus file', () {
    final mei = File('test/corpus/slur/slur-001.mei').readAsStringSync();
    final doc = XmlDocument.parse(mei);

    final notes = doc.findAllElements('note').toList();
    expect(notes, isNotEmpty);

    final first = notes.first;
    final reader = MeiAttributeReader({
      for (final a in first.attributes) a.name.local: a.value,
    });

    final note = TestNote();
    expect(note.readDurationLog(reader), isTrue);
    expect(note.readOctave(reader), isTrue);
    expect(note.readPitch(reader), isTrue);
    expect(note.readStems(reader), isTrue);

    // slur-001.mei first note: dur="2" oct="4" pname="b" stem.dir="up"
    expect(note.dur, MeiDuration.dur2);
    expect(note.oct, 4);
    expect(note.pname, Pitchname.b);
    expect(note.stemDir, Stemdirection.up);

    // Only attributes handled by other mixins (@accid -> AttAccidental on
    // the child element, xml:id) remain unconsumed:
    expect(reader.unsupported.keys.toSet(), {'id', 'accid'});
  });

  test('round-trips written attributes back through the reader', () {
    final note = TestNote()
      ..dur = MeiDuration.dur4
      ..oct = 5
      ..pname = Pitchname.f
      ..stemDir = Stemdirection.down;

    final b = XmlBuilder();
    b.element('note', nest: () {
      b.attribute('xml:id', 'x1');
      note.writeDurationLog(b);
      note.writeOctave(b);
      note.writePitch(b);
      note.writeStems(b);
    });
    final element = b.buildDocument().rootElement;

    final reader = MeiAttributeReader({
      for (final a in element.attributes) a.name.local: a.value,
    });
    final copy = TestNote();
    copy.readDurationLog(reader);
    copy.readOctave(reader);
    copy.readPitch(reader);
    copy.readStems(reader);

    expect(copy.dur, MeiDuration.dur4);
    expect(copy.oct, 5);
    expect(copy.pname, Pitchname.f);
    expect(copy.stemDir, Stemdirection.down);
    expect(reader.unsupported.keys, ['id']);
  });
}
