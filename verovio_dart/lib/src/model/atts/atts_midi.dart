// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_midi.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.Channelized` (mirrors `vrv::AttChannelized`).
mixin AttChannelized {
  /// `midi.channel` — data_MIDICHANNEL.
  int? midiChannel;
  bool get hasMidiChannel => midiChannel != null;

  /// `midi.duty` — data_PERCENT_LIMITED.
  double? midiDuty;
  bool get hasMidiDuty => midiDuty != null;

  /// `midi.port` — data_MIDIVALUE_NAME.
  MidiValueName? midiPort;
  bool get hasMidiPort => midiPort != null;

  /// `midi.track` — int.
  int? midiTrack;
  bool get hasMidiTrack => midiTrack != null;

  /// Mirrors `AttChannelized::ReadChannelized`.
  bool readChannelized(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final midiChannelRaw = element.get('midi.channel');
    if (midiChannelRaw != null) {
      midiChannel = strToInt(midiChannelRaw);
      if (removeAttr) element.remove('midi.channel');
      hasAttribute = true;
    }
    final midiDutyRaw = element.get('midi.duty');
    if (midiDutyRaw != null) {
      midiDuty = strToDbl(midiDutyRaw);
      if (removeAttr) element.remove('midi.duty');
      hasAttribute = true;
    }
    final midiPortRaw = element.get('midi.port');
    if (midiPortRaw != null) {
      midiPort = strToMidivalueName(midiPortRaw);
      if (removeAttr) element.remove('midi.port');
      hasAttribute = true;
    }
    final midiTrackRaw = element.get('midi.track');
    if (midiTrackRaw != null) {
      midiTrack = strToInt(midiTrackRaw);
      if (removeAttr) element.remove('midi.track');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttChannelized::WriteChannelized`.
  void writeChannelized(XmlBuilder element) {
    if (hasMidiChannel) {
      element.attribute('midi.channel', midichannelToStr(midiChannel!));
    }
    if (hasMidiDuty) {
      element.attribute('midi.duty', percentLimitedToStr(midiDuty!));
    }
    if (hasMidiPort) {
      element.attribute('midi.port', midivalueNameToStr(midiPort!));
    }
    if (hasMidiTrack) {
      element.attribute('midi.track', intToStr(midiTrack!));
    }
  }

  /// Copies the `AttChannelized` members from [other].
  void copyAttChannelized(covariant AttChannelized other) {
    midiChannel = other.midiChannel;
    midiDuty = other.midiDuty;
    midiPort = other.midiPort;
    midiTrack = other.midiTrack;
  }
}

/// MEI attribute class for `att.InstrumentIdent` (mirrors `vrv::AttInstrumentIdent`).
mixin AttInstrumentIdent {
  /// `instr` — std::string.
  String? instr;
  bool get hasInstr => instr != null;

  /// Mirrors `AttInstrumentIdent::ReadInstrumentIdent`.
  bool readInstrumentIdent(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final instrRaw = element.get('instr');
    if (instrRaw != null) {
      instr = identityStr(instrRaw);
      if (removeAttr) element.remove('instr');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttInstrumentIdent::WriteInstrumentIdent`.
  void writeInstrumentIdent(XmlBuilder element) {
    if (hasInstr) {
      element.attribute('instr', identityStr(instr!));
    }
  }

  /// Copies the `AttInstrumentIdent` members from [other].
  void copyAttInstrumentIdent(covariant AttInstrumentIdent other) {
    instr = other.instr;
  }
}

/// MEI attribute class for `att.MidiInstrument` (mirrors `vrv::AttMidiInstrument`).
mixin AttMidiInstrument {
  /// `midi.instrnum` — data_MIDIVALUE.
  int? midiInstrnum;
  bool get hasMidiInstrnum => midiInstrnum != null;

  /// `midi.instrname` — data_MIDINAMES.
  Midinames? midiInstrname;
  bool get hasMidiInstrname => midiInstrname != null;

  /// `midi.pan` — data_MIDIVALUE_PAN.
  MidiValuePan? midiPan;
  bool get hasMidiPan => midiPan != null;

  /// `midi.patchname` — std::string.
  String? midiPatchname;
  bool get hasMidiPatchname => midiPatchname != null;

  /// `midi.patchnum` — data_MIDIVALUE.
  int? midiPatchnum;
  bool get hasMidiPatchnum => midiPatchnum != null;

  /// `midi.volume` — data_PERCENT.
  double? midiVolume;
  bool get hasMidiVolume => midiVolume != null;

  /// Mirrors `AttMidiInstrument::ReadMidiInstrument`.
  bool readMidiInstrument(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final midiInstrnumRaw = element.get('midi.instrnum');
    if (midiInstrnumRaw != null) {
      midiInstrnum = strToInt(midiInstrnumRaw);
      if (removeAttr) element.remove('midi.instrnum');
      hasAttribute = true;
    }
    final midiInstrnameRaw = element.get('midi.instrname');
    if (midiInstrnameRaw != null) {
      midiInstrname = strToMidinames(midiInstrnameRaw);
      if (removeAttr) element.remove('midi.instrname');
      hasAttribute = true;
    }
    final midiPanRaw = element.get('midi.pan');
    if (midiPanRaw != null) {
      midiPan = strToMidivaluePan(midiPanRaw);
      if (removeAttr) element.remove('midi.pan');
      hasAttribute = true;
    }
    final midiPatchnameRaw = element.get('midi.patchname');
    if (midiPatchnameRaw != null) {
      midiPatchname = identityStr(midiPatchnameRaw);
      if (removeAttr) element.remove('midi.patchname');
      hasAttribute = true;
    }
    final midiPatchnumRaw = element.get('midi.patchnum');
    if (midiPatchnumRaw != null) {
      midiPatchnum = strToInt(midiPatchnumRaw);
      if (removeAttr) element.remove('midi.patchnum');
      hasAttribute = true;
    }
    final midiVolumeRaw = element.get('midi.volume');
    if (midiVolumeRaw != null) {
      midiVolume = strToDbl(midiVolumeRaw);
      if (removeAttr) element.remove('midi.volume');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMidiInstrument::WriteMidiInstrument`.
  void writeMidiInstrument(XmlBuilder element) {
    if (hasMidiInstrnum) {
      element.attribute('midi.instrnum', midivalueToStr(midiInstrnum!));
    }
    if (hasMidiInstrname) {
      element.attribute('midi.instrname', midinamesToStr(midiInstrname!));
    }
    if (hasMidiPan) {
      element.attribute('midi.pan', midivaluePanToStr(midiPan!));
    }
    if (hasMidiPatchname) {
      element.attribute('midi.patchname', identityStr(midiPatchname!));
    }
    if (hasMidiPatchnum) {
      element.attribute('midi.patchnum', midivalueToStr(midiPatchnum!));
    }
    if (hasMidiVolume) {
      element.attribute('midi.volume', percentToStr(midiVolume!));
    }
  }

  /// Copies the `AttMidiInstrument` members from [other].
  void copyAttMidiInstrument(covariant AttMidiInstrument other) {
    midiInstrnum = other.midiInstrnum;
    midiInstrname = other.midiInstrname;
    midiPan = other.midiPan;
    midiPatchname = other.midiPatchname;
    midiPatchnum = other.midiPatchnum;
    midiVolume = other.midiVolume;
  }
}

/// MEI attribute class for `att.MidiNumber` (mirrors `vrv::AttMidiNumber`).
mixin AttMidiNumber {
  /// `num` — data_MIDIVALUE.
  int? num;
  bool get hasNum => num != null;

  /// Mirrors `AttMidiNumber::ReadMidiNumber`.
  bool readMidiNumber(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final numRaw = element.get('num');
    if (numRaw != null) {
      num = strToInt(numRaw);
      if (removeAttr) element.remove('num');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMidiNumber::WriteMidiNumber`.
  void writeMidiNumber(XmlBuilder element) {
    if (hasNum) {
      element.attribute('num', midivalueToStr(num!));
    }
  }

  /// Copies the `AttMidiNumber` members from [other].
  void copyAttMidiNumber(covariant AttMidiNumber other) {
    num = other.num;
  }
}

/// MEI attribute class for `att.MidiTempo` (mirrors `vrv::AttMidiTempo`).
mixin AttMidiTempo {
  /// `midi.bpm` — double.
  double? midiBpm;
  bool get hasMidiBpm => midiBpm != null;

  /// `midi.mspb` — data_MIDIMSPB.
  int? midiMspb;
  bool get hasMidiMspb => midiMspb != null;

  /// Mirrors `AttMidiTempo::ReadMidiTempo`.
  bool readMidiTempo(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final midiBpmRaw = element.get('midi.bpm');
    if (midiBpmRaw != null) {
      midiBpm = strToDbl(midiBpmRaw);
      if (removeAttr) element.remove('midi.bpm');
      hasAttribute = true;
    }
    final midiMspbRaw = element.get('midi.mspb');
    if (midiMspbRaw != null) {
      midiMspb = strToInt(midiMspbRaw);
      if (removeAttr) element.remove('midi.mspb');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMidiTempo::WriteMidiTempo`.
  void writeMidiTempo(XmlBuilder element) {
    if (hasMidiBpm) {
      element.attribute('midi.bpm', dblToStr(midiBpm!));
    }
    if (hasMidiMspb) {
      element.attribute('midi.mspb', midimspbToStr(midiMspb!));
    }
  }

  /// Copies the `AttMidiTempo` members from [other].
  void copyAttMidiTempo(covariant AttMidiTempo other) {
    midiBpm = other.midiBpm;
    midiMspb = other.midiMspb;
  }
}

/// MEI attribute class for `att.MidiValue` (mirrors `vrv::AttMidiValue`).
mixin AttMidiValue {
  /// `val` — data_MIDIVALUE.
  int? val;
  bool get hasVal => val != null;

  /// Mirrors `AttMidiValue::ReadMidiValue`.
  bool readMidiValue(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final valRaw = element.get('val');
    if (valRaw != null) {
      val = strToInt(valRaw);
      if (removeAttr) element.remove('val');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMidiValue::WriteMidiValue`.
  void writeMidiValue(XmlBuilder element) {
    if (hasVal) {
      element.attribute('val', midivalueToStr(val!));
    }
  }

  /// Copies the `AttMidiValue` members from [other].
  void copyAttMidiValue(covariant AttMidiValue other) {
    val = other.val;
  }
}

/// MEI attribute class for `att.MidiValue2` (mirrors `vrv::AttMidiValue2`).
mixin AttMidiValue2 {
  /// `val2` — data_MIDIVALUE.
  int? val2;
  bool get hasVal2 => val2 != null;

  /// Mirrors `AttMidiValue2::ReadMidiValue2`.
  bool readMidiValue2(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final val2Raw = element.get('val2');
    if (val2Raw != null) {
      val2 = strToInt(val2Raw);
      if (removeAttr) element.remove('val2');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMidiValue2::WriteMidiValue2`.
  void writeMidiValue2(XmlBuilder element) {
    if (hasVal2) {
      element.attribute('val2', midivalueToStr(val2!));
    }
  }

  /// Copies the `AttMidiValue2` members from [other].
  void copyAttMidiValue2(covariant AttMidiValue2 other) {
    val2 = other.val2;
  }
}

/// MEI attribute class for `att.MidiVelocity` (mirrors `vrv::AttMidiVelocity`).
mixin AttMidiVelocity {
  /// `vel` — data_MIDIVALUE.
  int? vel;
  bool get hasVel => vel != null;

  /// Mirrors `AttMidiVelocity::ReadMidiVelocity`.
  bool readMidiVelocity(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final velRaw = element.get('vel');
    if (velRaw != null) {
      vel = strToInt(velRaw);
      if (removeAttr) element.remove('vel');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMidiVelocity::WriteMidiVelocity`.
  void writeMidiVelocity(XmlBuilder element) {
    if (hasVel) {
      element.attribute('vel', midivalueToStr(vel!));
    }
  }

  /// Copies the `AttMidiVelocity` members from [other].
  void copyAttMidiVelocity(covariant AttMidiVelocity other) {
    vel = other.vel;
  }
}

/// MEI attribute class for `att.TimeBase` (mirrors `vrv::AttTimeBase`).
mixin AttTimeBase {
  /// `ppq` — int.
  int? ppq;
  bool get hasPpq => ppq != null;

  /// Mirrors `AttTimeBase::ReadTimeBase`.
  bool readTimeBase(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final ppqRaw = element.get('ppq');
    if (ppqRaw != null) {
      ppq = strToInt(ppqRaw);
      if (removeAttr) element.remove('ppq');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttTimeBase::WriteTimeBase`.
  void writeTimeBase(XmlBuilder element) {
    if (hasPpq) {
      element.attribute('ppq', intToStr(ppq!));
    }
  }

  /// Copies the `AttTimeBase` members from [other].
  void copyAttTimeBase(covariant AttTimeBase other) {
    ppq = other.ppq;
  }
}
