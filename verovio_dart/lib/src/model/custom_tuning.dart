/// Port of `customtuning.h/cpp` — custom tuning (microtonality) support
/// based on the ASCL/tuning-library port (`core/tunings.dart`).
///
/// The C++ version obtains the SMuFL glyph name table and the resources path
/// through the [Doc]; here they are provided directly (the Doc wiring arrives
/// with the toolkit phase).
library;

import 'dart:convert';

import 'package:verovio_dart/src/core/file_reader.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/smufl.dart';
import 'package:verovio_dart/src/core/tunings.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/model/atts/atts_conversion.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/interfaces/pitch_interface.dart';
import 'package:verovio_dart/src/model/layer_elements_gen.dart';
import 'package:verovio_dart/src/model/object.dart';

/// Mirrors `vrv::CustomTuning`.
class CustomTuning {
  CustomTuning();

  /// Build a custom tuning from an ASCL definition (mirrors the
  /// [tuningDef]/[doc] constructor). [resourcesPath] is the path used to
  /// locate the `tuning-glyphnames.json` resource; [useMusicXmlAccidentals]
  /// selects MusicXML accidental names instead of MEI ones.
  CustomTuning.fromDefinition(
      String tuningDef, String? resourcesPath, bool useMusicXmlAccidentals) {
    // Parse the tuning and create the mappings.
    try {
      tuning = Tuning.fromAbletonScale(parseASCLData(tuningDef));
      createGlyphMapping(resourcesPath);
      createNoteMapping(useMusicXmlAccidentals);
    } on TuningError catch (e) {
      logError('Custom tuning: Invalid tuning definition: ${e.message}');
    }
  }

  /// The underlying tuning (mirrors `m_tuning`).
  Tuning tuning = Tuning();

  /// The map of MEI note names to tuning note names (mirrors `m_noteMap`).
  final Map<String, String> noteMap = {};

  /// Return true when the tuning holds a valid notation mapping (mirrors
  /// `IsValid`).
  bool get isValid => tuning.notationMapping.count > 0;

  /// Get the tuning object (mirrors `GetTuning`).
  Tuning getTuning() => tuning;

  /// Get the note map (mirrors `GetNoteMap`).
  Map<String, String> getNoteMap() => noteMap;

  // -------------------------------------------------------------------------
  // Glyph mapping
  // -------------------------------------------------------------------------

  static final Map<String, int> _glyphNames = {};
  static final Map<int, String> _glyphCodes = {};

  /// Map SMuFL glyph names to codes and vice versa (mirrors
  /// `CreateGlyphMapping`). [resourcesPath] locates
  /// `tuning-glyphnames.json`.
  static void createGlyphMapping(String? resourcesPath) {
    if (_glyphNames.isNotEmpty && _glyphCodes.isNotEmpty) return;

    final json =
        resourceFileReader('${resourcesPath ?? ''}/tuning-glyphnames.json') ??
            '';
    Object? glyphs;
    try {
      glyphs = jsonDecode(json);
    } on FormatException {
      logError('Custom tuning: Invalid or missing file glyphnames.json');
      return;
    }
    if (glyphs is! Map<String, dynamic>) {
      logError('Custom tuning: Invalid or missing file glyphnames.json');
      return;
    }
    (glyphs as Map<String, dynamic>).forEach((name, value) {
      if (value is! String) return;
      final codepoint = value;
      if (!codepoint.startsWith('U+')) {
        logError(
            "Custom tuning: SMuFL glyph '$name' has invalid codepoint in glyph table");
        return;
      }
      final code = int.parse(codepoint.substring(2), radix: 16);
      _glyphNames[name] = code;
      _glyphCodes[code] = name;
    });
  }

  /// Get a SMuFL code given a glyph name (mirrors `GetGlyphCode`).
  static int getGlyphCode(String glyphName, [String? docResourcesPath]) {
    if (_glyphNames.isEmpty) {
      createGlyphMapping(docResourcesPath);
    }
    if (!_glyphNames.containsKey(glyphName)) {
      logDebug(
          "Custom tuning: SMuFL glyph '$glyphName' not found in glyph table");
      return 0;
    }
    return _glyphNames[glyphName]!;
  }

  /// Get a SMuFL glyph name given a code (mirrors `GetGlyphName`).
  static String getGlyphName(int glyphCode, [String? docResourcesPath]) {
    if (_glyphCodes.isEmpty) {
      createGlyphMapping(docResourcesPath);
    }
    if (!_glyphCodes.containsKey(glyphCode)) {
      logError(
          'Custom tuning: SMuFL glyph U+${glyphCode.toRadixString(16).padLeft(4, '0')} not found in glyph table');
      return '';
    }
    return _glyphCodes[glyphCode]!;
  }

  /// Convert an accidental (MEI or MusicXML) to a SMuFL glyph (mirrors
  /// `GetAccidGlyph`).
  static int getAccidGlyph(String accid, bool useMusicXmlAccidentals) {
    if (useMusicXmlAccidentals) {
      final accidental = convertMusicXmlAccidentalToAccid(accid);
      return Accid.getAccidGlyph(accidental);
    }

    final accidental = strToAccidentalWritten(accid);
    return Accid.getAccidGlyph(accidental);
  }

  // -------------------------------------------------------------------------
  // Note mapping
  // -------------------------------------------------------------------------

  static final RegExp _noteNameRegex = RegExp(r'(?:^|\/)([A-G])([^\/\s]*)');
  static final RegExp _accidNameRegex = RegExp(r'([^\+]+)\+?');

  /// Map the tuning note names to MEI notes (mirrors `CreateNoteMapping`):
  ///
  /// - Convert accidentals from MusicXML or MEI to SMuFL.
  /// - Detect enharmonics separated by `/`.
  /// - Detect multiple accidentals separated by `+`.
  /// - Ignore natural accidental.
  void createNoteMapping(bool useMusicXmlAccidentals) {
    noteMap.clear();
    for (final note in tuning.notationMapping.names) {
      for (final match in _noteNameRegex.allMatches(note)) {
        var mei = match.group(1)!;
        final accids = match.group(2) ?? '';

        for (final accidMatch in _accidNameRegex.allMatches(accids)) {
          final accid = accidMatch.group(1)!;
          String glyphName = '';
          var glyph = getGlyphCode(accid);
          if (glyph != 0) {
            glyphName = accid;
          } else {
            glyph = getAccidGlyph(accid, useMusicXmlAccidentals);
            if (glyph != 0) {
              glyphName = getGlyphName(glyph);
            }
          }
          if (glyph == 0) {
            logError('Custom tuning: Tuning accidental "$accid" is neither a '
                '${useMusicXmlAccidentals ? 'MusicXML' : 'MEI'} accidental nor a SMuFL glyph');
          } else if (glyph != smuflE261AccidentalNatural &&
              glyphName.isNotEmpty) {
            mei += '+$glyphName';
          }
        }
        noteMap[mei] = note;
      }
    }
  }

  // -------------------------------------------------------------------------
  // MIDI pitch resolution
  // -------------------------------------------------------------------------

  /// Retrieve the MIDI pitch for a note in the custom tuning (mirrors
  /// `GetMIDIPitch`).
  ///
  /// Uses the constructed note map to look up the tuning note names; falls
  /// back to the standard note MIDI pitch calculation if lookup fails.
  /// [note] must apply [PitchInterface]; [standardMidiPitch] resolves the
  /// fallback (Note::GetMIDIPitch, ported with the MIDI phase).
  int getMidiPitch(Object note, int shift, int octaveShift,
      {required int Function() fallbackMidiPitch}) {
    // Explicit cast required (mixins with `on` constraints are not valid
    // promotion targets).
    if (note is! PitchInterface) {
      return fallbackMidiPitch();
    }
    final PitchInterface pitch = note as PitchInterface;
    // Construct the note name for the tuning lookup.
    var pname = pitch.pname;
    if (pitch.hasPnameGes && pname == null) pname = pitch.pnameGes;
    if (pname == null) return fallbackMidiPitch();
    final letterIndex = (pname.value - 1) % 7;
    const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    var noteName = letters[letterIndex];

    var accs = 0;
    for (final Object object in note.findAllDescendantsByType(ClassId.accid)) {
      final accid = object as Accid;

      var glyph = 0;
      String glyphName = '';
      if (accid.hasGlyphName) {
        glyph = getGlyphCode(accid.glyphName!);
      } else if (accid.hasAccid) {
        glyph = getAccidGlyph(accidentalWrittenToStr(accid.accid!), false);
      } else if (accid.hasAccidGes) {
        glyph = getAccidGlyph(accidentalGesturalToStr(accid.accidGes!), false);
      }
      if (glyph != 0) {
        glyphName = getGlyphName(glyph);
      }
      if (glyph != smuflE261AccidentalNatural && glyphName.isNotEmpty) {
        if (accs++ > 0) noteName += '+';
        noteName += glyphName;
      }
    }
    var oct = pitch.oct ?? 4;
    oct += octaveShift;
    if (pitch.hasOctGes && pitch.octGes != null) oct = pitch.octGes!;

    // Look up the note in the tuning and map it to a MIDI key.
    try {
      final mapped = noteMap[noteName];
      if (mapped == null) {
        throw Exception('$noteName not mapped');
      }
      final it = tuning.notationMapping.names.indexOf(mapped);
      final scalePosition = ((it + 1) % tuning.notationMapping.count);
      // FIXME! Special case: when we encounter a B pitch that's in scale
      // degree 0, increment its oct by 1 otherwise, it would be in the lower
      // octave.
      if (pname == Pitchname.b && scalePosition == 0) oct++;
      return tuning.midiNoteForNoteName(mapped, oct);
    } on TuningError catch (e) {
      logError('Custom tuning: Error mapping note to tuning: ${e.message}');
    } catch (_) {
      logError(
          'Custom tuning: Error mapping note to tuning: $noteName not mapped');
    }
    return fallbackMidiPitch();
  }
}

/// Convert a MusicXML accidental name to data_ACCIDENTAL_WRITTEN (mirrors
/// `MusicXmlInput::ConvertAccidentalToAccid`; full port with IOMusXML).
const Map<String, AccidentalWritten> kMusicXmlAccidental2Accid = {
  'sharp': AccidentalWritten.s,
  'natural': AccidentalWritten.n,
  'flat': AccidentalWritten.f,
  'double-sharp': AccidentalWritten.x,
  'sharp-sharp': AccidentalWritten.ss,
  'flat-flat': AccidentalWritten.ff,
  'natural-sharp': AccidentalWritten.ns,
  'natural-flat': AccidentalWritten.nf,
  'quarter-flat': AccidentalWritten.n1qf,
  'quarter-sharp': AccidentalWritten.n1qs,
  'three-quarters-flat': AccidentalWritten.n3qf,
  'three-quarters-sharp': AccidentalWritten.n3qs,
  'sharp-down': AccidentalWritten.sd,
  'sharp-up': AccidentalWritten.su,
  'natural-down': AccidentalWritten.nd,
  'natural-up': AccidentalWritten.nu,
  'flat-down': AccidentalWritten.fd,
  'flat-up': AccidentalWritten.fu,
  'double-sharp-down': AccidentalWritten.xd,
  'double-sharp-up': AccidentalWritten.xu,
  'flat-flat-down': AccidentalWritten.ffd,
  'flat-flat-up': AccidentalWritten.ffu,
  'triple-sharp': AccidentalWritten.ts,
  'triple-flat': AccidentalWritten.tf,
  'slash-quarter-sharp': AccidentalWritten.bms,
  'slash-sharp': AccidentalWritten.ks,
  'slash-flat': AccidentalWritten.bf,
  'double-slash-flat': AccidentalWritten.bmf,
};

AccidentalWritten convertMusicXmlAccidentalToAccid(String value) {
  return kMusicXmlAccidental2Accid[value] ?? AccidentalWritten.none;
}
