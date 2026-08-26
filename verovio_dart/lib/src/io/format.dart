/// Input format identification (mirrors `Toolkit::IdentifyInputFrom` in
/// `toolkit.cpp` and the `FileFormat` enum from `toolkitdef.h`).
library;

import 'package:verovio_dart/src/core/logging.dart';

/// Mirrors `vrv::FileFormat`.
enum FileFormat {
  unknown(0),
  auto(1),
  mei(2),
  // Humdrum formats are excluded from this build (mirrors the
  // NO_HUMDRUM_SUPPORT build); the enum values are kept for parity.
  humdrum(3),
  hummei(4),
  hummidi(5),
  pae(6),
  abc(7),
  gabc(8),
  cmme(9),
  darms(10),
  volpiano(11),
  musicxml(12),
  musicxmlHum(13),
  meiHum(14),
  museDataHum(15),
  esac(16),
  midi(17),
  timemap(18),
  expansionMap(19),
  serialization(20);

  const FileFormat(this.value);
  final int value;
}

final RegExp _verovioSerializationRe = RegExp(r'<(verovio-serialization)[\s>]');
final RegExp _meiRootRe = RegExp(r'<(mei|music|pages)[\s>]');
final RegExp _musicXmlRootRe =
    RegExp(r'<(!DOCTYPE )?(score-partwise|opus|score-timewise)[\s>]');
final RegExp _cmmeRootRe = RegExp(r'<(Piece xmlns="http://www.cmme.org")[\s>]');

/// Detect the input format from the first bytes of [data] (mirrors
/// `Toolkit::IdentifyInputFrom`).
///
/// Humdrum-based formats (MuseData, PAE via Humdrum…) are not returned in
/// this build; PAE and GABC detection is kept since those grammars are plain
/// text formats.
FileFormat identifyInputFrom(String data) {
  const FileFormat musicxmlDefault = FileFormat.musicxml;

  if (data.isEmpty) return FileFormat.unknown;
  if (data.codeUnitAt(0) == 0) return FileFormat.unknown;

  final String excerpt =
      data.substring(0, data.length < 2000 ? data.length : 2000);
  if (excerpt.contains('Group memberships:')) {
    // MuseData may contain '@' as first character, so needs to be checked
    // before PAE identification. MuseData import requires Humdrum support.
    logWarning('MuseData import requires Humdrum support (not built).');
    return FileFormat.unknown;
  }
  switch (data[0]) {
    case '@':
    case '{':
      return FileFormat.pae;
    case '*':
    case '!':
      return FileFormat.humdrum;
    case 'X':
      return FileFormat.abc;
    case '%':
      return (data.length > 1 && data[1] == 'a') ? FileFormat.abc : FileFormat.pae;
    default:
      break;
  }
  final int codeUnit = data.codeUnitAt(0);
  if (codeUnit == 0xff || codeUnit == 0xfe) {
    // Handle UTF-16 content here later.
    logWarning('Cannot yet auto-detect format of UTF-16 data files.');
    return FileFormat.unknown;
  }

  const int searchLimit = 600;
  final String initial =
      data.substring(0, data.length < searchLimit ? data.length : searchLimit);

  if (data[0] == '<') {
    // <mei> == root node for standard organization of MEI data
    // <pages> == root node for pages organization of MEI data
    // <score-partwise> == root node for part-wise organization of MusicXML
    // <score-timewise> == root node for time-wise organization of MusicXML
    // <opus> == root node for multi-movement/work organization of MusicXML

    if (_verovioSerializationRe.hasMatch(initial)) {
      return FileFormat.serialization;
    }
    if (_meiRootRe.hasMatch(initial)) {
      return FileFormat.mei;
    }
    if (_musicXmlRootRe.hasMatch(initial)) {
      return musicxmlDefault;
    }
    if (_cmmeRootRe.hasMatch(initial)) {
      return FileFormat.cmme;
    }
    logWarning('Trying to load unknown XML data which cannot be identified.');
    return FileFormat.unknown;
  }
  if (initial.contains('\n!!') || initial.contains('\n**')) {
    // Empty lines before content in Humdrum files.
    return FileFormat.humdrum;
  }
  if (initial.contains('\nCUT[')) {
    // Title record for a melody in EsAC format.
    return FileFormat.esac;
  }
  if (initial.contains('\n%%') ||
      (initial.length >= 3 && initial.startsWith('%%\n'))) {
    // A GABC file always carries a header block terminated by `%%` on its own
    // line before the body; `%%` cannot legally appear inside MEI or ABC.
    return FileFormat.gabc;
  }

  // Assume that the input is MEI if other input types were not detected.
  // This means that DARMS cannot be auto-detected.
  return FileFormat.mei;
}
