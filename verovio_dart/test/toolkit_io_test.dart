import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:archive/archive.dart';
import 'package:verovio_dart/src/toolkit.dart';
import 'package:verovio_dart/src/io/format.dart';

void main() {
  setUpAll(() {
    logLevel = LogLevel.error;
  });

  group('identifyInputFrom', () {
    test('detects MEI', () {
      expect(identifyInputFrom('<?xml?><mei meiversion="6.0-dev"/>'),
          FileFormat.mei);
      expect(
          identifyInputFrom(
              '<?xml?><music xmlns="http://www.music-encoding.org/ns/mei"/>'),
          FileFormat.mei);
    });
    test('detects MusicXML', () {
      expect(identifyInputFrom('<?xml?><score-partwise version="4.0">'),
          FileFormat.musicxml);
      expect(identifyInputFrom('<!DOCTYPE score-partwise>'),
          FileFormat.musicxml);
      // Note: '<opus/>' is NOT detected (the root regex requires a space or
      // '>' right after the element name) - same as the C++ original. A
      // typical opus file starts with '<opus>' or '<opus ...>'.
      expect(identifyInputFrom('<opus>'), FileFormat.musicxml);
    });
    test('detects ABC and PAE', () {
      expect(identifyInputFrom('X:1\nT:t\n'), FileFormat.abc);
      expect(identifyInputFrom('%abc\nX:1'), FileFormat.abc);
      expect(identifyInputFrom('@{\nCDEF\n}'), FileFormat.pae);
      expect(identifyInputFrom('%pae'), FileFormat.pae);
    });
    test('falls back to MEI', () {
      // Unidentifiable data falls back to MEI like the C++.
      expect(identifyInputFrom('some random text'), FileFormat.mei);
      expect(identifyInputFrom(''), FileFormat.unknown);
    });
  });

  group('Toolkit.loadData', () {
    test('loads MEI by auto-detection', () {
      final tk = Toolkit();
      const mei = '''
<mei meiversion="6.0-dev">
  <music><body><mdiv>
    <score>
      <scoreDef><staffGrp><staffDef n="1"/></staffGrp></scoreDef>
      <section>
        <measure n="1">
          <staff n="1"><layer n="1">
            <note dur="4" oct="4" pname="c"/><note dur="4" oct="4" pname="d"/>
          </layer></staff>
        </measure>
      </section>
    </score>
  </mdiv></body></music>
</mei>
''';
      expect(tk.loadData(mei), isTrue);
      expect(tk.ready, isTrue);
      expect(tk.doc.findAllDescendantsByType(ClassId.note).length, 2);
    });

    test('loads ABC by auto-detection', () {
      final tk = Toolkit();
      const abc = 'X:1\nM:4/4\nL:1/4\nK:C\nCDEF |]\n';
      expect(tk.loadData(abc), isTrue);
      expect(tk.doc.findAllDescendantsByType(ClassId.note).length, 4);
    });
  });

  group('Toolkit zip support', () {
    test('loads a compressed MEI archive', () {
      // Build a zip archive in-memory with META-INF/container.xml.
      final encoder = ZipEncoder();
      final archive = Archive()
        ..addFile(ArchiveFile.string('META-INF/container.xml', '''
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="score.mei"/>
  </rootfiles>
</container>
'''))
        ..addFile(ArchiveFile.string('score.mei', '''
<mei meiversion="6.0-dev">
  <music><body><mdiv>
    <score>
      <scoreDef><staffGrp><staffDef n="1"/></staffGrp></scoreDef>
      <section>
        <measure n="1">
          <staff n="1"><layer n="1"><note dur="4" oct="4" pname="g"/></layer></staff>
        </measure>
      </section>
    </score>
  </mdiv></body></music>
</mei>
'''));
      final bytes = encoder.encode(archive);

      final tk = Toolkit();
      expect(tk.loadZipData(Uint8List.fromList(bytes)), isTrue);
      expect(tk.doc.findAllDescendantsByType(ClassId.note).length, 1);
    });

    test('loads a compressed MEI file from disk', () {
      final encoder = ZipEncoder();
      final archive = Archive()
        ..addFile(ArchiveFile.string('META-INF/container.xml',
            '<container><rootfiles><rootfile full-path="s.mei"/></rootfiles></container>'))
        ..addFile(ArchiveFile.string('s.mei', '''
<mei meiversion="6.0-dev"><music><body>
  <pages><page><system><measure n="1">
    <staff n="1"><layer n="1"><note dur="4" oct="5" pname="a"/></layer></staff>
  </measure></system></page></pages>
</body></music></mei>
'''));
      final tmp = Directory.systemTemp.createTempSync('verovio_dart_test');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final path =
          '${tmp.path}${Platform.pathSeparator}compressed.mei';
      File(path).writeAsBytesSync(ZipEncoder().encode(archive) as Uint8List);
      final tk = Toolkit();
      expect(tk.loadZipFile(path), isTrue);
      expect(tk.doc.findAllDescendantsByType(ClassId.note).length, 1);
    });
  });
}
