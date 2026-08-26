/// Port of the tuning-library subset used by Verovio
/// (`origin/src/include/tuning-library/Tunings.h` / `TuningsImpl.h`):
/// SCL/ASCL parsing and the tuning table computation.
///
/// Only the features reachable from `Tunings::parseASCLData` are ported;
/// KBM file parsing is reduced to the programmatically built mappings.
library;

import 'dart:math' as math;

/// The frequency for MIDI note 0 (mirrors `MIDI_0_FREQ`).
const double midi0Freq = 8.175798915643707;

/// Mirrors `Tunings::TuningError`.
class TuningError implements Exception {
  TuningError(this.message);
  final String message;

  @override
  String toString() => 'TuningError: $message';
}

/// The type of a scale tone (mirrors `Tone::Type`).
enum ToneType { cents, ratio }

/// A single tone in a scale (mirrors `Tunings::Tone`).
class Tone {
  Tone()
      : type = ToneType.ratio,
        cents = 0,
        ratioD = 1,
        ratioN = 1,
        stringRep = '1/1',
        floatValue = 1.0,
        lineno = -1;

  /// Either kToneCents or kToneRatio.
  ToneType type;

  /// If type==kToneCents, the cents value.
  double cents;

  /// If type==kToneRatio, the numerator/denominator.
  int ratioD, ratioN;

  /// The string representation.
  String stringRep;

  /// The cents representation / 1200 + 1.
  double floatValue;

  /// Which line of the SCL does this tone appear on?
  int lineno;
}

/// Given an SCL string like "100.231" or "3/7", set up a tone (mirrors
/// `toneFromString`).
Tone toneFromString(String t, [int lineno = -1]) {
  final tone = Tone();
  tone.stringRep = t;
  tone.lineno = lineno;

  // Allow end-of-line comments, e.g. "555/524 ! c# 138.75 Hz".
  final bang = t.indexOf('!');
  final String line = bang == -1 ? t : t.substring(0, bang);

  if (line.contains('.')) {
    tone.type = ToneType.cents;
    tone.cents = double.parse(line.trim());
  } else {
    tone.type = ToneType.ratio;
    final slashPos = line.indexOf('/');
    if (slashPos == -1) {
      tone.ratioN = int.tryParse(line.trim()) ?? 0;
      tone.ratioD = 1;
    } else {
      tone.ratioN = int.tryParse(line.substring(0, slashPos).trim()) ?? 0;
      tone.ratioD = int.tryParse(line.substring(slashPos + 1).trim()) ?? 0;
    }

    if (tone.ratioN == 0 || tone.ratioD == 0) {
      var msg = 'Invalid tone in SCL file.';
      if (lineno >= 0) msg += 'Line $lineno.';
      msg += " Line is '$line'.";
      throw TuningError(msg);
    }
    // 2^(cents/1200) = n/d => cents = 1200 * log(n/d) / log(2).
    tone.cents = 1200 * math.log(tone.ratioN / tone.ratioD) / math.log(2.0);
  }
  tone.floatValue = tone.cents / 1200.0 + 1.0;
  return tone;
}

/// Positive modulo helper (mirrors `positive_mod`).
int positiveMod(int v, int m) {
  var mod = v % m;
  if (mod < 0) mod += m;
  return mod;
}

/// The Scale representation of an SCL file (mirrors `Tunings::Scale`).
class Scale {
  String name = '';
  String description = '';
  String rawText = '';
  int count = 0;
  final List<Tone> tones = [];
  final List<String> comments = [];
}

/// The KeyboardMapping representation of a KBM file (mirrors
/// `Tunings::KeyboardMapping`).
class KeyboardMapping {
  KeyboardMapping()
      : count = 0,
        firstMidi = 0,
        lastMidi = 127,
        middleNote = 60,
        tuningConstantNote = 60,
        tuningFrequency = midi0Freq * 32.0,
        tuningPitch = 32.0,
        tuningOctave = 4,
        octaveDegrees = 0,
        rawText = '',
        name = '';

  int count;
  int firstMidi, lastMidi;
  int middleNote;
  int tuningConstantNote;
  double tuningFrequency, tuningPitch; // pitch = frequency / MIDI_0_FREQ
  int tuningOctave; // octave of the tuning reference
  int octaveDegrees;
  final List<int> keys = []; // '-1' marks skipped keys

  String rawText;
  String name;
}

/// The list of note names corresponding to the scale tones (mirrors
/// `Tunings::NotationMapping`).
class NotationMapping {
  NotationMapping() : count = 0;
  int count;

  /// Organized in the same order as [Scale.tones].
  final List<String> names = [];
}

/// Ableton's ASCL extension to the SCL file (mirrors `Tunings::AbletonScale`).
///
/// @see https://help.ableton.com/hc/en-us/articles/10998372840220-ASCL-Specification
class AbletonScale {
  AbletonScale()
      : referencePitchOctave = 3,
        referencePitchIndex = 0,
        referencePitchFreq = midi0Freq * 32;

  Scale scale = Scale();
  int referencePitchOctave;
  int referencePitchIndex;
  double referencePitchFreq;
  KeyboardMapping keyboardMapping = KeyboardMapping();
  NotationMapping notationMapping = NotationMapping();
  String source = '';
  String link = '';

  final List<String> rawTexts = [];

  /// Return the MIDI note for the given scale position (mirrors
  /// `midiNoteForScalePosition`).
  int midiNoteForScalePosition(int scalePosition) {
    const middleFreq = midi0Freq * 32;
    final int middleIndex = scalePositionForFrequency(middleFreq);
    return math.max(0, math.min(60 + (scalePosition - middleIndex), 127));
  }

  /// Return the closest scale position for a frequency (mirrors
  /// `scalePositionForFrequency`).
  int scalePositionForFrequency(double freq) {
    var n = 0;
    var r = frequencyForScalePosition(n);
    var o = freq - r;
    final int i = o > 0 ? 1 : -1;
    var s = o.abs();
    var a = n;
    var l = false;
    if (s <= 2.220446049250313e-16) return n;
    while (!l) {
      n += i;
      r = frequencyForScalePosition(n);
      o = (freq - r).abs();
      if (o < s) {
        s = o;
        a = n;
      }
      if (i > 0) {
        l = r > freq;
      } else {
        l = r < freq;
      }
    }
    return a;
  }

  /// Return the frequency of a scale position (mirrors
  /// `frequencyForScalePosition`).
  double frequencyForScalePosition(int scalePosition) {
    return referencePitchFreq *
        math
            .pow(
                2,
                (centsForScalePosition(scalePosition) -
                        centsForScalePosition(referencePitchIndex)) /
                    1200)
            .toDouble();
  }

  /// Return the accumulated cents of a scale position (mirrors
  /// `centsForScalePosition`).
  double centsForScalePosition(int scalePosition) {
    final int n = scale.tones.length;
    final Tone t = scale.tones[positiveMod(scalePosition, n)];
    return t.cents +
        (scalePosition / n).floorToDouble() * scale.tones.last.cents;
  }
}

/// Even temperament 12-note scale starting at C (mirrors
/// `evenTemperament12NoteScale`).
Scale evenTemperament12NoteScale() {
  const data = '''! 12 Tone Equal Temperament.scl
!
12 Tone Equal Temperament | ED2-12 - Equal division of harmonic 2 into 12 parts
 12
!
 100.00000
 200.00000
 300.00000
 400.00000
 500.00000
 600.00000
 700.00000
 800.00000
 900.00000
 1000.00000
 1100.00000
 2/1
''';
  return parseSCLData(data);
}

/// Parse SCL data from its file contents (mirrors `parseSCLData`).
Scale parseSCLData(String sclContents) =>
    readSCLStream(sclContents.split('\n'));

/// Parse an SCL stream given as a list of lines (mirrors `readSCLStream`).
Scale readSCLStream(List<String> lines) {
  const readHeader = 0, readCount = 1, readNote = 2, trailing = 3;
  var state = readHeader;

  final res = Scale();
  final rawBuffer = StringBuffer();
  var lineno = 0;
  var declaredNameSet = false;

  for (var rawLine in lines) {
    // Normalize line endings.
    final line = rawLine.replaceAll('\r', '');
    rawBuffer.write('$line\n');
    lineno++;

    if (!declaredNameSet && line.isNotEmpty && line[0] == '!') {
      var nameCandidate = line.substring(1);
      nameCandidate = nameCandidate.replaceFirst(RegExp(r'^[ \t]+'), '');
      nameCandidate = nameCandidate.replaceFirst(RegExp(r'[ \t]+$'), '');

      if (nameCandidate.isNotEmpty) {
        res.name = nameCandidate;
      }

      declaredNameSet = true;
      res.comments.add(line);
      continue;
    }

    if ((state == readNote && line.isEmpty) || line.startsWith('!')) {
      res.comments.add(line);
      continue;
    }
    switch (state) {
      case readHeader:
        res.description = line;
        state = readCount;
        break;
      case readCount:
        res.count = int.tryParse(line.trim()) ?? 0;
        if (res.count < 1) {
          throw TuningError('Invalid SCL note count.');
        }
        state = readNote;
        break;
      case readNote:
        final t = toneFromString(line, lineno);
        res.tones.add(t);
        if (res.tones.length == res.count) state = trailing;
        break;
      default:
        break;
    }
  }

  if (!(state == readNote || state == trailing)) {
    var msg = 'Incomplete SCL content. Only able to read $lineno lines of '
        'data. Found content up to ';
    switch (state) {
      case readHeader:
        msg += 'reading header.';
        break;
      case readCount:
        msg += 'reading scale count.';
        break;
      default:
        msg += 'unknown state.';
        break;
    }
    throw TuningError(msg);
  }

  if (res.tones.length != res.count) {
    throw TuningError(
        'Read fewer notes than count in file. Count = ${res.count} notes. '
        'Array size = ${res.tones.length}');
  }
  res.rawText = rawBuffer.toString();
  return res;
}

final RegExp _ablCommandRegex = RegExp(r'!\s+@ABL\s+(.*?)\s+(.*?)$');
final RegExp _noteNameRegex = RegExp(r'\s*(?:"(.*?)\s*"|(\S+))\s*');
final RegExp _referencePitchRegex = RegExp(r'\s*(\d+)\s*(\d+)\s*([\d.]+)\s*$');

/// Parse an ASCL stream given as a list of lines (mirrors `readASCLStream`).
AbletonScale readASCLStream(List<String> lines) {
  final as = AbletonScale();

  // Read the scale and create default KBM parameters.
  as.scale = readSCLStream(lines);
  as.keyboardMapping.count = as.scale.count;
  as.keyboardMapping.firstMidi = 0;
  as.keyboardMapping.lastMidi = 127;
  as.keyboardMapping.middleNote = as.midiNoteForScalePosition(0);
  as.keyboardMapping.tuningConstantNote = as.midiNoteForScalePosition(0);
  as.keyboardMapping.octaveDegrees = as.keyboardMapping.count;
  as.keyboardMapping.keys
      .addAll(List<int>.generate(as.keyboardMapping.count, (index) => index));

  // Parse the scale comments to detect @ABL extensions.
  for (final comment in as.scale.comments) {
    final command = _ablCommandRegex.firstMatch(comment);
    if (command == null) continue;
    as.rawTexts.add(comment);
    final key = command.group(1)!;
    final value = command.group(2)!;
    if (key == 'NOTE_NAMES') {
      final rawText = value;
      for (final m in _noteNameRegex.allMatches(rawText)) {
        final quoted = m.group(1) ?? '';
        final bare = m.group(2) ?? '';
        as.notationMapping.names.add(quoted + bare);
      }

      // Move first note to last to correspond to scale.tones.
      if (as.notationMapping.names.isNotEmpty) {
        final firstName = as.notationMapping.names.removeAt(0);
        as.notationMapping.names.add(firstName);
      }

      as.notationMapping.count = as.notationMapping.names.length;
      if (as.notationMapping.count != as.scale.count) {
        throw TuningError("Invalid NOTE_NAMES entry '$rawText': Expecting "
            '${as.scale.count} entries but received '
            '${as.notationMapping.count}');
      }
    } else if (key == 'REFERENCE_PITCH') {
      final rp = value;
      final match = _referencePitchRegex.firstMatch(rp);
      if (match != null) {
        as.referencePitchOctave = int.parse(match.group(1)!);
        as.referencePitchIndex = int.parse(match.group(2)!);
        as.referencePitchFreq = double.parse(match.group(3)!);
        as.keyboardMapping.tuningFrequency = as.referencePitchFreq;
        as.keyboardMapping.tuningPitch =
            as.keyboardMapping.tuningFrequency / midi0Freq;
        as.keyboardMapping.tuningConstantNote =
            as.midiNoteForScalePosition(as.referencePitchIndex);
        as.keyboardMapping.tuningOctave = as.referencePitchOctave;
        as.keyboardMapping.middleNote = as.midiNoteForScalePosition(0);
      } else {
        throw TuningError("Invalid REFERENCE_PITCH entry '$rp'");
      }
    } else if (key == 'NOTE_RANGE_BY_FREQUENCY') {
      // TODO(library)
    } else if (key == 'NOTE_RANGE_BY_INDEX') {
      // TODO(library)
    } else if (key == 'SOURCE') {
      as.source = value;
    } else if (key == 'LINK') {
      as.link = value;
    } else {
      throw TuningError("Unhandled Ableton command '$key'");
    }
  }

  return as;
}

/// Parse ASCL data from its file contents (mirrors `parseASCLData`).
AbletonScale parseASCLData(String asclContents) {
  final res = readASCLStream(asclContents.split('\n'));
  res.scale.name = 'AbletonScale from patch';
  return res;
}

/// The Tuning class computes and stores the tuning tables (mirrors
/// `Tunings::Tuning`).
class Tuning {
  /// The number of notes pre-computed (mirrors `Tuning::N`).
  static const int n = 512;

  /// Construct a tuning with even temperament and standard mapping.
  Tuning() : this.from(evenTemperament12NoteScale(), KeyboardMapping());

  /// Construct a tuning for a particular scale/mapping pair.
  Tuning.from(Scale scale_, KeyboardMapping k_,
      [bool allowTuningCenterOnUnmapped_ = false])
      : allowTuningCenterOnUnmapped = allowTuningCenterOnUnmapped_ {
    scale = Scale()
      ..name = scale_.name
      ..description = scale_.description
      ..rawText = scale_.rawText
      ..count = scale_.count
      ..tones.addAll(scale_.tones)
      ..comments.addAll(scale_.comments);
    keyboardMapping = _copyKbm(k_);
    notationMapping = NotationMapping();

    var s = scale_;
    final k = keyboardMapping;
    var osp = 1;
    if (s.count <= 0) {
      throw TuningError(
          'Unable to tune to a scale with no notes. Your scale provided '
          '${s.count} notes.');
    }

    var useMiddleNote = k.middleNote;
    if (k.count > 0) {
      // Is the KBM not spanning the tuning note?
      var mapStart = useMiddleNote;
      var mapEnd = useMiddleNote + k.count;
      while (mapStart > k.tuningConstantNote) {
        useMiddleNote -= k.count;
        mapStart = useMiddleNote;
        mapEnd = useMiddleNote + k.count;
      }
      while (mapEnd < k.tuningConstantNote) {
        useMiddleNote += k.count;
        mapStart = useMiddleNote;
        mapEnd = useMiddleNote + k.count;
      }
    }

    var kbmRotations = 1;
    for (final kv in k.keys) {
      kbmRotations = math.max(kbmRotations, (1.0 * kv / s.count).ceil());
    }

    if (kbmRotations > 1) {
      // The KBM has mapped note N in a smaller scale: unwrap the scale.
      final newS = Scale()
        ..name = s.name
        ..description = s.description
        ..rawText = s.rawText
        ..count = s.count * kbmRotations
        ..tones.addAll(s.tones)
        ..comments.addAll(s.comments);
      final backCents = s.tones.last.cents;
      var pushOff = backCents;
      for (var i = 1; i < kbmRotations; ++i) {
        for (final t in s.tones) {
          final tCopy = Tone();
          tCopy.type = ToneType.cents;
          tCopy.cents = t.cents + pushOff;
          tCopy.floatValue = tCopy.cents / 1200.0 + 1;
          newS.tones.add(tCopy);
        }
        pushOff += backCents;
      }
      s = newS;
      k.octaveDegrees *= kbmRotations;
      if (k.octaveDegrees == 0) k.octaveDegrees = s.count;
    }

    // From the KBM spec: when not all scale degrees need to be mapped, the
    // size of the map can be smaller than the size of the scale.
    if (k.octaveDegrees > s.count) {
      throw TuningError('Unable to apply mapping of size ${k.octaveDegrees} '
          'to smaller scale of size ${s.count}');
    }

    final posPitch0 = 256 + k.tuningConstantNote;
    final posScale0 = 256 + useMiddleNote;

    final pitchMod = math.log(k.tuningPitch) / math.log(2) - 1;

    var scalePositionOfTuningNote = k.tuningConstantNote - useMiddleNote;
    if (k.count > 0) {
      while (scalePositionOfTuningNote >= k.count) {
        scalePositionOfTuningNote -= k.count;
      }
      while (scalePositionOfTuningNote < 0) {
        scalePositionOfTuningNote += k.count;
      }
      osp = scalePositionOfTuningNote;
      scalePositionOfTuningNote = k.keys[scalePositionOfTuningNote];
      if (scalePositionOfTuningNote == -1 && !allowTuningCenterOnUnmapped) {
        throw TuningError('Keyboard mapping is tuning an unmapped key. '
            'Your tuning mapping is mapping key ${k.tuningConstantNote} as '
            'the tuning constant note, but that is scale note $osp given '
            'your scale root of ${k.middleNote} which your mapping does not '
            'assign. Please set your tuning constant note to a mapped key.');
      }
    }
    double tuningCenterPitchOffset;
    if (scalePositionOfTuningNote == 0) {
      tuningCenterPitchOffset = 0;
    } else {
      if (scalePositionOfTuningNote == -1 && allowTuningCenterOnUnmapped) {
        var low = 1, high = 1;
        var octaveUp = false, octaveDown = false;
        // Find next closest mapped note below.
        for (var i = osp - 1; i != osp; i = (i - 1) % k.count) {
          if (k.keys[i] != -1) {
            low = k.keys[i];
            break;
          }
          if (i > osp) octaveDown = true;
        }
        // Find next closest mapped note above.
        for (var i = osp + 1; i != osp; i = (i + 1) % k.count) {
          if (k.keys[i] != -1) {
            high = k.keys[i];
            break;
          }
          if (i < osp) octaveUp = true;
        }

        // Determine high and low pitches.
        final dt = s.tones[s.count - 1].cents;
        final pitchLow = octaveDown
            ? s.tones[low - 1].cents - dt
            : s.tones[low - 1].floatValue - 1.0;
        final pitchHigh = octaveUp
            ? s.tones[high - 1].cents + dt
            : s.tones[high - 1].floatValue - 1.0;
        tuningCenterPitchOffset = (pitchHigh + pitchLow) / 2.0;
      } else {
        var tshift = 0.0;
        final dt = s.tones[s.count - 1].floatValue - 1.0;
        var sp = scalePositionOfTuningNote;
        while (sp < 0) {
          sp += s.count;
          tshift += dt;
        }
        while (sp > s.count) {
          sp -= s.count;
          tshift -= dt;
        }

        if (sp == 0) {
          tuningCenterPitchOffset = -tshift;
        } else {
          tuningCenterPitchOffset = s.tones[sp - 1].floatValue - 1.0 - tshift;
        }
      }
    }

    final pitches = List<double>.filled(n, 0);

    for (var i = 0; i < n; ++i) {
      final distanceFromPitch0 = i - posPitch0;
      final distanceFromScale0 = i - posScale0;

      if (distanceFromPitch0 == 0) {
        pitches[i] = 1;
        lptable[i] = pitches[i] + pitchMod;
        ptable[i] = math.pow(2.0, lptable[i]).toDouble();

        if (k.count > 0) {
          var mappingKey = distanceFromScale0 % k.count;
          if (mappingKey < 0) mappingKey += k.count;

          final cm = k.keys[mappingKey];
          if (!allowTuningCenterOnUnmapped && cm < 0) {
            throw TuningError('Keyboard mapping is tuning an unmapped key. '
                'Your tuning mapping is mapping key ${posPitch0 - 256} as '
                'the tuning constant note, but that is scale note '
                '$mappingKey given your scale root of ${k.middleNote} which '
                'your mapping does not assign. Please set your tuning '
                'constant note to a mapped key.');
          }
        }
        scalepositiontable[i] = scalePositionOfTuningNote % s.count;
      } else {
        int rounds;
        int thisRound;
        var disable = false;
        if (k.count == 0) {
          rounds = ((distanceFromScale0 - 1) ~/ s.count);
          thisRound = (distanceFromScale0 - 1) % s.count;
        } else {
          var mappingKey = distanceFromScale0 % k.count;
          var rotations = 0;
          if (mappingKey < 0) {
            mappingKey += k.count;
          }
          // Have we gone off the end?
          var dt = distanceFromScale0;
          if (dt > 0) {
            while (dt >= k.count) {
              dt -= k.count;
              rotations++;
            }
          } else {
            while (dt < 0) {
              dt += k.count;
              rotations--;
            }
          }

          final cm = k.keys[mappingKey];

          var push = 0;
          if (cm < 0) {
            disable = true;
          } else {
            if (cm > s.count) {
              throw TuningError(
                  'Mapping KBM note longer than scale; key=$cm scale count=${s.count}');
            }
            push = mappingKey - cm;
          }

          if (k.octaveDegrees > 0 && k.octaveDegrees != k.count) {
            rounds = rotations;
            thisRound = cm - 1;
            if (thisRound < 0) {
              thisRound = k.octaveDegrees - 1;
              rounds--;
            }
          } else {
            rounds = ((distanceFromScale0 - push - 1) ~/ s.count);
            thisRound = (distanceFromScale0 - push - 1) % s.count;
          }
        }

        if (thisRound < 0) {
          thisRound += s.count;
          rounds -= 1;
        }

        if (disable) {
          pitches[i] = 0;
          scalepositiontable[i] = -1;
        } else {
          pitches[i] = s.tones[thisRound].floatValue +
              rounds * (s.tones[s.count - 1].floatValue - 1.0) -
              tuningCenterPitchOffset;
          scalepositiontable[i] = (thisRound + 1) % s.count;
        }

        lptable[i] = pitches[i] + pitchMod;
        ptable[i] = math.pow(2.0, pitches[i] + pitchMod).toDouble();
      }
    }
  }

  /// Construct a tuning from just a scale.
  Tuning.fromScale(Scale s) : this.from(s, KeyboardMapping());

  /// Construct a tuning from just a keyboard mapping.
  Tuning.fromKbm(KeyboardMapping k)
      : this.from(evenTemperament12NoteScale(), k);

  /// Construct an ASCL tuning (mirrors `Tuning(const AbletonScale&)`).
  factory Tuning.fromAbletonScale(AbletonScale as) {
    final tuning = Tuning.from(as.scale, as.keyboardMapping);
    tuning.notationMapping.count = as.notationMapping.count;
    tuning.notationMapping.names.addAll(as.notationMapping.names);
    return tuning;
  }

  // For convenience, the scale and mapping used to construct this are kept
  // as public copies.
  late Scale scale;
  late KeyboardMapping keyboardMapping;
  NotationMapping notationMapping = NotationMapping();

  final List<double> ptable = List<double>.filled(n, 0);
  final List<double> lptable = List<double>.filled(n, 0);
  final List<int> scalepositiontable = List<int>.filled(n, 0);
  final bool allowTuningCenterOnUnmapped;

  /// Return the frequency in Hz for a given midi note (mirrors
  /// `frequencyForMidiNote`).
  double frequencyForMidiNote(int mn) => ptable[_mni(mn)] * midi0Freq;

  /// Return the frequency scaled by the frequency of midi note 0 (mirrors
  /// `frequencyForMidiNoteScaledByMidi0`).
  double frequencyForMidiNoteScaledByMidi0(int mn) => ptable[_mni(mn)];

  /// Return the log base 2 of the scaled frequency (mirrors
  /// `logScaledFrequencyForMidiNote`).
  double logScaledFrequencyForMidiNote(int mn) => lptable[_mni(mn)];

  double retuningFromEqualInCentsForMidiNote(int mn) =>
      retuningFromEqualInSemitonesForMidiNote(mn) * 100.0;

  double retuningFromEqualInSemitonesForMidiNote(int mn) =>
      logScaledFrequencyForMidiNote(mn) * 12 - mn;

  /// Return the space in the logical scale for a midi note (mirrors
  /// `scalePositionForMidiNote`).
  int scalePositionForMidiNote(int mn) => scalepositiontable[_mni(mn)];

  bool isMidiNoteMapped(int mn) => scalepositiontable[_mni(mn)] >= 0;

  /// Return the MIDI note number for a note name and octave (mirrors
  /// `midiNoteForNoteName`).
  int midiNoteForNoteName(String noteName, int octave) {
    final it = notationMapping.names.indexOf(noteName);
    if (it == -1) {
      throw TuningError("Invalid note name '$noteName'");
    }
    final scalePosition = positiveMod(it + 1, notationMapping.count);
    return math.min(
        math.max(
            0,
            scalePosition +
                keyboardMapping.middleNote +
                keyboardMapping.octaveDegrees *
                    (octave - keyboardMapping.tuningOctave)),
        n - 1);
  }

  /// Return the note name for a scale position (mirrors
  /// `noteNameForScalePosition`).
  String noteNameForScalePosition(int scalePosition) {
    if (notationMapping.count == 0) {
      throw TuningError('No note names found in the tuning.');
    }
    return notationMapping
        .names[positiveMod(scalePosition - 1, notationMapping.count)];
  }

  /// Return a tuning with correctly interpolated skipped notes (mirrors
  /// `withSkippedNotesInterpolated`).
  Tuning withSkippedNotesInterpolated() {
    final res = Tuning.from(scale, keyboardMapping);
    for (var i = 1; i < n - 1; ++i) {
      if (scalepositiontable[i] < 0) {
        var nxt = i + 1;
        var prv = i - 1;
        while (prv >= 0 && scalepositiontable[prv] < 0) {
          prv--;
        }
        while (nxt < n && scalepositiontable[nxt] < 0) {
          nxt++;
        }
        final dist = (nxt - prv).toDouble();
        final frac = (i - prv) / dist;
        res.lptable[i] = (1.0 - frac) * lptable[prv] + frac * lptable[nxt];
        res.ptable[i] = math.pow(2.0, res.lptable[i]).toDouble();
      }
    }
    return res;
  }

  int _mni(int mn) => math.min(math.max(0, mn + 256), n - 1);

  static KeyboardMapping _copyKbm(KeyboardMapping source) {
    final copy = KeyboardMapping();
    copy.count = source.count;
    copy.firstMidi = source.firstMidi;
    copy.lastMidi = source.lastMidi;
    copy.middleNote = source.middleNote;
    copy.tuningConstantNote = source.tuningConstantNote;
    copy.tuningFrequency = source.tuningFrequency;
    copy.tuningPitch = source.tuningPitch;
    copy.tuningOctave = source.tuningOctave;
    copy.octaveDegrees = source.octaveDegrees;
    copy.keys.addAll(source.keys);
    copy.rawText = source.rawText;
    copy.name = source.name;
    return copy;
  }
}
