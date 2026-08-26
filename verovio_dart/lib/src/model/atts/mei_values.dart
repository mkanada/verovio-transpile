/// Hand-written companions for the generated MEI attribute classes.
///
/// Ports of `libmei/addons/attalternates.h` (special data classes) and the
/// basic converters from `libmei/addons/att.cpp`.
library;

import '../../core/attdef.dart' show meiUnset, MeterCountSign, MeiDuration;

export '../../core/attdef.dart' show MeiDuration;
import 'package:verovio_dart/src/core/logging.dart';
import '../../core/vrvdef.dart' show definitionFactor;
import 'package:verovio_dart/src/model/atts/atts_conversion.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart';

// ---------------------------------------------------------------------------
// Attribute reader abstraction used by the generated Read methods
// ---------------------------------------------------------------------------

/// Provides access to the attributes of an MEI element during reading,
/// mirroring the `pugi::xml_node` usage in the C++ (get + optional removal).
class MeiAttributeReader {
  MeiAttributeReader(this.attributes);

  /// The element attributes; order is preserved for leftover detection.
  final Map<String, String> attributes;

  final Set<String> _removed = {};

  /// Returns the value of attribute [name] or null.
  String? get(String name) => attributes[name];

  /// Marks [name] as consumed (mirrors `element.remove_attribute`).
  void remove(String name) => _removed.add(name);

  /// Attributes not consumed by any Read method (the "unsupported" ones).
  Map<String, String> get unsupported => Map.fromEntries(
      attributes.entries.where((e) => !_removed.contains(e.key)));
}

// ---------------------------------------------------------------------------
// Basic converters (att.cpp)
// ---------------------------------------------------------------------------

String identityStr(String value) => value;

/// Mirrors `Att::IntToStr`.
String intToStr(int data) => '$data';

/// Mirrors `Att::DblToStr`: rounds to 4 decimal places and prints without
/// trailing zeros.
String dblToStr(double data) {
  final v = (data * 10000.0).roundToDouble() / 10000.0;
  if (v == v.truncateToDouble()) return v.truncate().toString();
  var s = v.toString();
  if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
  return s;
}

/// Mirrors `Att::VUToStr`.
String vuToStr(double data) => '${dblToStr(data)}vu';

final RegExp _intPrefix = RegExp(r'^\s*[+-]?\d+');
final RegExp _dblPrefix =
    RegExp(r'^\s*[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?');

/// Mirrors `atoi`: parses the leading integer part or returns 0.
int strToInt(String value) {
  final m = _intPrefix.firstMatch(value);
  return m == null ? 0 : int.tryParse(m.group(0)!.trim()) ?? 0;
}

/// Mirrors `atof`: parses the leading double part or returns 0.
double strToDbl(String value) {
  final m = _dblPrefix.firstMatch(value);
  return m == null ? 0.0 : double.tryParse(m.group(0)!.trim()) ?? 0.0;
}

/// Mirrors `AttConverterBase::StrToBoolean`.
bool? strToBoolean(String value) {
  if (value == 'true') return true;
  if (value == 'false') return false;
  if (value.isNotEmpty) {
    logWarning("Unsupported value '$value' for data.BOOLEAN");
  }
  return null;
}

/// Mirrors `AttConverterBase::BooleanToStr`.
String booleanToStr(bool data) => data ? 'true' : 'false';

/// Mirrors `Att::HexnumToStr` (`U+XXXX` with 4 hex digits).
String hexnumToStr(int data) {
  final hex = data.toRadixString(16).toUpperCase().padLeft(4, '0');
  return 'U+$hex';
}

/// Mirrors `Att::StrToHexnum`: requires a `U+`/`#x` prefix and restricts to
/// the SMuFL private use area.
int strToHexnum(String value) {
  String v = value;
  if (v.startsWith('U+') || v.startsWith('#x')) {
    v = v.substring(2);
  } else {
    logWarning("Unable to parse glyph code '$value'. Unknown prefix value.");
    return 0;
  }
  final wc = int.tryParse(v, radix: 16) ?? 0;
  // Check that the value is in a SMuFL private area range - this does not
  // check that it is an existing SMuFL glyph num or that it is supported by
  // Verovio.
  if (wc >= 0xE000 && wc <= 0xF8FF) {
    return wc;
  }
  logWarning("Value '$v' is not in the SMuFL (private area) range");
  return 0;
}

// ---------------------------------------------------------------------------
// data.DURATION (canonical type: hand-written MeiDuration)
// ---------------------------------------------------------------------------

/// Mirrors `Att::DurationToStr`.
String durationToStr(MeiDuration data) => switch (data) {
      MeiDuration.maxima => 'maxima',
      MeiDuration.longa => 'longa',
      MeiDuration.brevis => 'brevis',
      MeiDuration.semibrevis => 'semibrevis',
      MeiDuration.minima => 'minima',
      MeiDuration.semiminima => 'semiminima',
      MeiDuration.fusa => 'fusa',
      MeiDuration.semifusa => 'semifusa',
      MeiDuration.long => 'long',
      MeiDuration.breve => 'breve',
      MeiDuration.dur1 => '1',
      MeiDuration.dur2 => '2',
      MeiDuration.dur4 => '4',
      MeiDuration.dur8 => '8',
      MeiDuration.dur16 => '16',
      MeiDuration.dur32 => '32',
      MeiDuration.dur64 => '64',
      MeiDuration.dur128 => '128',
      MeiDuration.dur256 => '256',
      MeiDuration.dur512 => '512',
      MeiDuration.dur1024 => '1024',
      _ => '',
    };

/// Mirrors `Att::StrToDuration`.
MeiDuration strToDuration(String value) {
  const values = {
    'maxima': MeiDuration.maxima,
    'longa': MeiDuration.longa,
    'brevis': MeiDuration.brevis,
    'semibrevis': MeiDuration.semibrevis,
    'minima': MeiDuration.minima,
    'semiminima': MeiDuration.semiminima,
    'fusa': MeiDuration.fusa,
    'semifusa': MeiDuration.semifusa,
    'long': MeiDuration.long,
    'breve': MeiDuration.breve,
    '1': MeiDuration.dur1,
    '2': MeiDuration.dur2,
    '4': MeiDuration.dur4,
    '8': MeiDuration.dur8,
    '16': MeiDuration.dur16,
    '32': MeiDuration.dur32,
    '64': MeiDuration.dur64,
    '128': MeiDuration.dur128,
    '256': MeiDuration.dur256,
    '512': MeiDuration.dur512,
    '1024': MeiDuration.dur1024,
  };
  final v = values[value];
  if (v != null) return v;
  logWarning("Unknown dur '$value'");
  return MeiDuration.none;
}

String midibpmToStr(int data) => intToStr(data);
String midichannelToStr(int data) => intToStr(data);
String midimspbToStr(int data) => intToStr(data);
String midivalueToStr(int data) => intToStr(data);
String octaveToStr(int data) => intToStr(data);
String ncnameToStr(String data) => data;

String degreesToStr(double data) => data.toStringAsFixed(6);
String percentToStr(double data) => '${dblToStr(data)}%';
String percentLimitedToStr(double data) => '${dblToStr(data)}%';
String percentLimitedSignedToStr(double data) => '${dblToStr(data)}%';
String fontsizenumericToStr(double data) => '${data.toStringAsFixed(2)}pt';

// ---------------------------------------------------------------------------
// List converters
// ---------------------------------------------------------------------------

/// Mirrors `Att::ArticulationListToStr`.
String articulationListToStr(List<Articulation> data) =>
    data.map(articulationToStr).join(' ');

/// Mirrors `Att::StrToArticulationList`.
List<Articulation> strToArticulationList(String value) =>
    value.split(' ').where((t) => t.isNotEmpty).map(strToArticulation).toList();

/// Mirrors `Att::BulgeToStr`.
String bulgeToStr(List<BulgePair> data) =>
    data.map((pair) => '${dblToStr(pair.$1)} ${dblToStr(pair.$2)}').join(' ');

/// Mirrors `Att::StrToBulge`.
List<BulgePair> strToBulge(String value) {
  final entries = value.split(' ').where((t) => t.isNotEmpty).toList();
  final result = <BulgePair>[];
  for (int i = 0; i + 1 < entries.length; i += 2) {
    final distance = strToDbl(entries[i]);
    final offset = strToDbl(entries[i + 1]);
    if (offset < 0.0 || offset > 100.0) {
      logWarning("Unsupported percentage value '$offset' in bulge");
      continue;
    }
    result.add((distance, offset));
  }
  return result;
}

typedef BulgePair = (double, double);

String xsdAnyURIListToStr(List<String> data) => data.join(' ');
List<String> strToXsdAnyURIList(String value) =>
    value.split(' ').where((t) => t.isNotEmpty).toList();

String xsdPositiveIntegerListToStr(List<int> data) =>
    data.map(intToStr).join(' ');
List<int> strToXsdPositiveIntegerList(String value) =>
    value.split(' ').where((t) => t.isNotEmpty).map(strToInt).toList();

String stringListToStr(List<String> data) => data.join(' ');
List<String> strToStringList(String value) =>
    value.split(' ').where((t) => t.isNotEmpty).toList();

String intListToStr(List<int> data) => data.map(intToStr).join(' ');
List<int> strToIntList(String value) =>
    value.split(' ').where((t) => t.isNotEmpty).map(strToInt).toList();

// ---------------------------------------------------------------------------
// data.FONTSIZE (attalternates.h)
// ---------------------------------------------------------------------------

enum FontSizeType { none, fontSizeNumeric, term, percent }

class FontSize {
  FontSizeType type = FontSizeType.none;
  double fontSizeNumeric = meiUnset.toDouble();
  Fontsizeterm term = Fontsizeterm.none;
  double percent = 0;

  void reset(FontSizeType t) {
    type = t;
    fontSizeNumeric = meiUnset.toDouble();
    term = Fontsizeterm.none;
    percent = 0;
  }

  void setFontSizeNumeric(double value) {
    reset(FontSizeType.fontSizeNumeric);
    fontSizeNumeric = value;
  }

  void setTerm(Fontsizeterm value) {
    reset(FontSizeType.term);
    term = value;
  }

  void setPercent(double value) {
    reset(FontSizeType.percent);
    percent = value;
  }

  /// Mirrors `GetPercentForTerm`.
  int getPercentForTerm() {
    switch (term) {
      case Fontsizeterm.xxLarge:
        return 200;
      case Fontsizeterm.xLarge:
        return 150;
      case Fontsizeterm.large:
        return 110;
      case Fontsizeterm.larger:
        return 110;
      case Fontsizeterm.small:
        return 80;
      case Fontsizeterm.smaller:
        return 80;
      case Fontsizeterm.xSmall:
        return 60;
      case Fontsizeterm.xxSmall:
        return 50;
      default:
        return 100;
    }
  }

  bool hasValue() {
    if (fontSizeNumeric != meiUnset) return true;
    if (term != Fontsizeterm.none) return true;
    if (percent != 0) return true;
    return false;
  }
}

/// Mirrors `Att::FontsizeToStr`.
String fontsizeToStr(FontSize data) {
  switch (data.type) {
    case FontSizeType.fontSizeNumeric:
      return '${data.fontSizeNumeric.toStringAsFixed(6)}pt';
    case FontSizeType.term:
      return fontsizetermToStr(data.term);
    case FontSizeType.percent:
      return percentToStr(data.percent);
    case FontSizeType.none:
      return '';
  }
}

/// Mirrors `Att::StrToFontsize`.
FontSize strToFontsize(String value) {
  final data = FontSize();
  data.setFontSizeNumeric(strToFontsizenumeric(value));
  if (data.hasValue()) return data;
  data.setTerm(strToFontsizeterm(value));
  if (data.hasValue()) return data;
  data.setPercent(strToPercent(value));
  if (data.hasValue()) return data;

  logWarning("Unsupported data.FONTSIZE '$value'");
  return data;
}

double strToFontsizenumeric(String value) {
  if (!RegExp(r'^[0-9]*(\.[0-9]+)?pt$').hasMatch(value)) {
    if (value.isNotEmpty) {
      logWarning("Unsupported data.FONTSIZENUMERIC '$value'");
    }
    return meiUnset.toDouble();
  }
  return strToDbl(value.substring(0, value.indexOf('pt')));
}

double strToPercent(String value) {
  if (!RegExp(r'^[0-9]+(\.?[0-9]*)?%$').hasMatch(value)) {
    logWarning("Unsupported data.PERCENT '$value'");
    return 0;
  }
  return strToDbl(value.substring(0, value.indexOf('%')));
}

// ---------------------------------------------------------------------------
// data.HEADSHAPE (attalternates.h)
// ---------------------------------------------------------------------------

enum HeadShapeType { none, headShapeList, hexnum }

class HeadShape {
  HeadShapeType type = HeadShapeType.none;
  HeadshapeList headShapeList = HeadshapeList.none;
  int hexnum = 0;

  void reset(HeadShapeType t) {
    type = t;
    headShapeList = HeadshapeList.none;
    hexnum = 0;
  }

  void setHeadShapeList(HeadshapeList value) {
    reset(HeadShapeType.headShapeList);
    headShapeList = value;
  }

  void setHexnum(int value) {
    reset(HeadShapeType.hexnum);
    hexnum = value;
  }

  bool hasValue() {
    if (headShapeList != HeadshapeList.none) return true;
    if (hexnum != 0) return true;
    return false;
  }
}

String headshapeToStr(HeadShape data) {
  switch (data.type) {
    case HeadShapeType.headShapeList:
      return headshapeListToStr(data.headShapeList);
    case HeadShapeType.hexnum:
      return hexnumToStr(data.hexnum);
    case HeadShapeType.none:
      return '';
  }
}

HeadShape strToHeadshape(String value) {
  final data = HeadShape();
  data.setHeadShapeList(strToHeadshapeList(value));
  if (data.hasValue()) return data;
  data.setHexnum(strToHexnum(value));
  if (data.hasValue()) return data;
  logWarning("Unsupported data.HEADSHAPE '$value'");
  return data;
}

// ---------------------------------------------------------------------------
// data.MEASUREMENTSIGNED / UNSIGNED (attalternates.h)
// ---------------------------------------------------------------------------

enum MeasurementType { none, vu, px }

class MeasurementSigned {
  MeasurementType type = MeasurementType.none;
  int px = meiUnset;
  double vu = meiUnset.toDouble();

  void reset(MeasurementType t) {
    type = t;
    px = meiUnset;
    vu = meiUnset.toDouble();
  }

  void setPx(int value) {
    reset(MeasurementType.px);
    px = value;
  }

  void setVu(double value) {
    reset(MeasurementType.vu);
    vu = value;
  }

  bool hasValue() {
    if (px != meiUnset) return true;
    if (vu != meiUnset) return true;
    return false;
  }
}

typedef MeasurementUnsigned = MeasurementSigned;

String measurementsignedToStr(MeasurementSigned data) {
  switch (data.type) {
    case MeasurementType.px:
      return '${data.px ~/ definitionFactor}px';
    case MeasurementType.vu:
      return vuToStr(data.vu);
    case MeasurementType.none:
      return '';
  }
}

String measurementunsignedToStr(MeasurementUnsigned data) =>
    measurementsignedToStr(data);

MeasurementSigned strToMeasurementsigned(String value) {
  final data = MeasurementSigned();
  if (RegExp(r'.*px$').hasMatch(value)) {
    data.setPx(
        strToInt(value.substring(0, value.indexOf('px'))) * definitionFactor);
  } else {
    data.setVu(strToDbl(value));
  }
  return data;
}

MeasurementUnsigned strToMeasurementunsigned(String value) =>
    strToMeasurementsigned(value);

// ---------------------------------------------------------------------------
// data.LINEWIDTH (attalternates.h)
// ---------------------------------------------------------------------------

enum LinewidthType { none, lineWidthTerm, measurementunsigned }

class LineWidth {
  LinewidthType type = LinewidthType.none;
  Linewidthterm lineWidthTerm = Linewidthterm.none;
  MeasurementUnsigned measurementunsigned = MeasurementUnsigned();

  void reset(LinewidthType t) {
    type = t;
    lineWidthTerm = Linewidthterm.none;
    measurementunsigned = MeasurementUnsigned();
  }

  void setLineWidthTerm(Linewidthterm value) {
    reset(LinewidthType.lineWidthTerm);
    lineWidthTerm = value;
  }

  void setMeasurementunsigned(MeasurementUnsigned value) {
    reset(LinewidthType.measurementunsigned);
    measurementunsigned = value;
  }

  bool hasValue() {
    if (lineWidthTerm != Linewidthterm.none) return true;
    if (measurementunsigned.hasValue()) return true;
    return false;
  }
}

String linewidthToStr(LineWidth data) {
  switch (data.type) {
    case LinewidthType.lineWidthTerm:
      return linewidthtermToStr(data.lineWidthTerm);
    case LinewidthType.measurementunsigned:
      return measurementunsignedToStr(data.measurementunsigned);
    case LinewidthType.none:
      return '';
  }
}

LineWidth strToLinewidth(String value) {
  final data = LineWidth();
  data.setLineWidthTerm(strToLinewidthterm(value));
  if (data.hasValue()) return data;
  data.setMeasurementunsigned(strToMeasurementunsigned(value));
  if (data.hasValue()) return data;
  logWarning("Unsupported data.LINEWIDTH '$value'");
  return data;
}

// ---------------------------------------------------------------------------
// data.MIDIVALUE.NAME / PAN (attalternates.h)
// ---------------------------------------------------------------------------

enum MidiValueType { none, midivalue, mcname }

class MidiValueName {
  MidiValueType type = MidiValueType.none;
  int midivalue = -1;
  String ncname = '';

  void reset(MidiValueType t) {
    type = t;
    midivalue = -1;
    ncname = '';
  }

  void setMidivalue(int value) {
    reset(MidiValueType.midivalue);
    midivalue = value;
  }

  void setNcname(String value) {
    reset(MidiValueType.mcname);
    ncname = value;
  }

  bool hasValue() => midivalue != -1 || ncname.isNotEmpty;
}

String midivalueNameToStr(MidiValueName data) {
  switch (data.type) {
    case MidiValueType.midivalue:
      return midivalueToStr(data.midivalue);
    case MidiValueType.mcname:
      return ncnameToStr(data.ncname);
    case MidiValueType.none:
      return '';
  }
}

MidiValueName strToMidivalueName(String value) {
  final data = MidiValueName();
  data.setMidivalue(strToInt(value));
  if (data.hasValue()) return data;
  data.setNcname(value);
  if (data.hasValue()) return data;
  logWarning("Unsupported data.MIDIVALUE_NAME '$value'");
  return data;
}

enum MidiValuePanType { none, midivalue, percentLimitedSigned }

class MidiValuePan {
  MidiValuePanType type = MidiValuePanType.none;
  int midivalue = -1;
  double percentLimitedSigned = meiUnset.toDouble();

  void reset(MidiValuePanType t) {
    type = t;
    midivalue = -1;
    percentLimitedSigned = meiUnset.toDouble();
  }

  void setMidivalue(int value) {
    reset(MidiValuePanType.midivalue);
    midivalue = value;
  }

  void setPercentLimitedSigned(double value) {
    reset(MidiValuePanType.percentLimitedSigned);
    percentLimitedSigned = value;
  }

  bool hasValue() => midivalue != -1 || percentLimitedSigned != meiUnset;
}

String midivaluePanToStr(MidiValuePan data) {
  switch (data.type) {
    case MidiValuePanType.midivalue:
      return midivalueToStr(data.midivalue);
    case MidiValuePanType.percentLimitedSigned:
      return percentLimitedSignedToStr(data.percentLimitedSigned);
    case MidiValuePanType.none:
      return '';
  }
}

MidiValuePan strToMidivaluePan(String value) {
  final data = MidiValuePan();
  data.setMidivalue(strToInt(value));
  if (data.hasValue()) return data;
  data.setPercentLimitedSigned(strToDbl(value));
  if (data.hasValue()) return data;
  logWarning("Unsupported data.MIDIVALUE_PAN '$value'");
  return data;
}

// ---------------------------------------------------------------------------
// data.PLACEMENT (attalternates.h)
// ---------------------------------------------------------------------------

enum PlacementType { none, staffRel, nonStaffPlace, nmtoken }

class Placement {
  PlacementType type = PlacementType.none;
  Staffrel staffRel = Staffrel.none;
  Nonstaffplace nonStaffPlace = Nonstaffplace.none;
  String nmtoken = '';

  void reset(PlacementType t) {
    type = t;
    staffRel = Staffrel.none;
    nonStaffPlace = Nonstaffplace.none;
    nmtoken = '';
  }

  void setStaffRel(Staffrel value) {
    reset(PlacementType.staffRel);
    staffRel = value;
  }

  void setNonStaffPlace(Nonstaffplace value) {
    reset(PlacementType.nonStaffPlace);
    nonStaffPlace = value;
  }

  void setNMToken(String value) {
    reset(PlacementType.nmtoken);
    nmtoken = value;
  }

  bool hasValue() {
    if (staffRel != Staffrel.none) return true;
    if (nonStaffPlace != Nonstaffplace.none) return true;
    if (nmtoken.isNotEmpty) return true;
    return false;
  }
}

String placementToStr(Placement data) {
  switch (data.type) {
    case PlacementType.staffRel:
      return staffrelToStr(data.staffRel);
    case PlacementType.nonStaffPlace:
      return nonstaffplaceToStr(data.nonStaffPlace);
    case PlacementType.nmtoken:
      return data.nmtoken;
    case PlacementType.none:
      return '';
  }
}

Placement strToPlacement(String value) {
  final data = Placement();
  data.setStaffRel(strToStaffrel(value));
  if (data.hasValue()) return data;
  data.setNonStaffPlace(strToNonstaffplace(value));
  if (data.hasValue()) return data;
  // Currently allows anything because it is not parsed at all...
  data.setNMToken(value);
  if (data.hasValue()) return data;
  logWarning("Unsupported data.PLACEMENT '$value'");
  return data;
}

// ---------------------------------------------------------------------------
// data.KEYSIGNATURE (pair<int, data_ACCIDENTAL_WRITTEN>)
// ---------------------------------------------------------------------------

class KeySignature {
  KeySignature(this.sig, this.accid);

  /// Number of alterations (-1 unset default; MEI_UNSET for "mixed").
  int sig;

  /// Type of alteration.
  AccidentalWritten accid;

  static KeySignature unset() => KeySignature(-1, AccidentalWritten.none);
}

String keysignatureToStr(KeySignature data) {
  if (data.sig == meiUnset) {
    return 'mixed';
  } else if (data.sig == 0) {
    return '0';
  } else if (data.sig != -1) {
    return '${data.sig}${accidentalWrittenToStr(data.accid)}';
  }
  return '';
}

KeySignature strToKeysignature(String value) {
  if (!RegExp(r'^(mixed|0|([1-9]|1[0-2])[fs])$').hasMatch(value)) {
    logWarning("Unsupported data.KEYSIGNATURE '$value'");
    return KeySignature.unset();
  }

  if (value == 'mixed') {
    return KeySignature(meiUnset, AccidentalWritten.none);
  } else if (value != '0') {
    final alterationNumber = int.parse(value.substring(0, value.length - 1));
    final alterationType = (value.codeUnitAt(value.length - 1) == 0x73 /* s */)
        ? AccidentalWritten.s
        : AccidentalWritten.f;
    return KeySignature(alterationNumber, alterationType);
  } else {
    return KeySignature(0, AccidentalWritten.n);
  }
}

// ---------------------------------------------------------------------------
// data.MEASUREBEAT (pair<int, double>)
// ---------------------------------------------------------------------------

class MeasureBeat {
  MeasureBeat(this.measures, this.beat);
  int measures;
  double beat;
}

String measurebeatToStr(MeasureBeat data) =>
    '${data.measures}m+${dblToStr(data.beat)}';

MeasureBeat strToMeasurebeat(String value) {
  final v = value.replaceAll(RegExp(r'\s'), '');
  int measure = 0;
  double timePoint = 0.0;
  final m = v.indexOf('m');
  final plus = v.lastIndexOf('+');
  if (m != -1) measure = strToInt(v.substring(0, m));
  if (plus != -1) {
    timePoint = strToDbl(v.substring(plus));
  } else {
    timePoint = strToDbl(v);
  }
  return MeasureBeat(measure, timePoint);
}

// ---------------------------------------------------------------------------
// data.METERCOUNT.pair (pair<vector<int>, MeterCountSign>)
// ---------------------------------------------------------------------------

class MeterCountPair {
  MeterCountPair(this.counts, this.sign);
  List<int> counts;
  MeterCountSign sign;
}

String metercountPairToStr(MeterCountPair data) {
  final out = StringBuffer();
  for (int i = 0; i < data.counts.length; ++i) {
    out.write(data.counts[i]);
    if (i != data.counts.length - 1) {
      switch (data.sign) {
        case MeterCountSign.slash:
          out.write(r'\');
          break;
        case MeterCountSign.minus:
          out.write('-');
          break;
        case MeterCountSign.asterisk:
          out.write('*');
          break;
        case MeterCountSign.plus:
          out.write('+');
          break;
        case MeterCountSign.none:
          break;
      }
    }
  }
  return out.toString();
}

MeterCountPair strToMetercountPair(String value) {
  // Only one operation is supported; it is based on the first mathematical
  // operator found in the string.
  var sign = MeterCountSign.none;
  final pos = value.indexOf(RegExp(r'[+\-*/]'));
  if (pos >= 0) {
    switch (value[pos]) {
      case '/':
        sign = MeterCountSign.slash;
      case '*':
        sign = MeterCountSign.asterisk;
      case '+':
        sign = MeterCountSign.plus;
      case '-':
        sign = MeterCountSign.minus;
    }
  }
  final counts = value
      .split(RegExp(r'[*+/-]'))
      .where((t) => t.isNotEmpty)
      .map(strToInt)
      .toList();
  return MeterCountPair(counts, sign);
}
