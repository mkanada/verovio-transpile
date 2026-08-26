// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_analytical.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.HarmAnl` (mirrors `vrv::AttHarmAnl`).
mixin AttHarmAnl {
  /// `form` — harmAnl_FORM.
  HarmanlForm? form;
  bool get hasForm => form != null;

  /// Mirrors `AttHarmAnl::ReadHarmAnl`.
  bool readHarmAnl(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final formRaw = element.get('form');
    if (formRaw != null) {
      form = strToHarmanlForm(formRaw);
      if (removeAttr) element.remove('form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHarmAnl::WriteHarmAnl`.
  void writeHarmAnl(XmlBuilder element) {
    if (hasForm) {
      element.attribute('form', harmanlFormToStr(form!));
    }
  }

  /// Copies the `AttHarmAnl` members from [other].
  void copyAttHarmAnl(covariant AttHarmAnl other) {
    form = other.form;
  }
}

/// MEI attribute class for `att.HarmonicFunction` (mirrors `vrv::AttHarmonicFunction`).
mixin AttHarmonicFunction {
  /// `deg` — std::string.
  String? deg;
  bool get hasDeg => deg != null;

  /// Mirrors `AttHarmonicFunction::ReadHarmonicFunction`.
  bool readHarmonicFunction(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final degRaw = element.get('deg');
    if (degRaw != null) {
      deg = identityStr(degRaw);
      if (removeAttr) element.remove('deg');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttHarmonicFunction::WriteHarmonicFunction`.
  void writeHarmonicFunction(XmlBuilder element) {
    if (hasDeg) {
      element.attribute('deg', identityStr(deg!));
    }
  }

  /// Copies the `AttHarmonicFunction` members from [other].
  void copyAttHarmonicFunction(covariant AttHarmonicFunction other) {
    deg = other.deg;
  }
}

/// MEI attribute class for `att.IntervalHarmonic` (mirrors `vrv::AttIntervalHarmonic`).
mixin AttIntervalHarmonic {
  /// `inth` — std::string.
  String? inth;
  bool get hasInth => inth != null;

  /// Mirrors `AttIntervalHarmonic::ReadIntervalHarmonic`.
  bool readIntervalHarmonic(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final inthRaw = element.get('inth');
    if (inthRaw != null) {
      inth = identityStr(inthRaw);
      if (removeAttr) element.remove('inth');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttIntervalHarmonic::WriteIntervalHarmonic`.
  void writeIntervalHarmonic(XmlBuilder element) {
    if (hasInth) {
      element.attribute('inth', identityStr(inth!));
    }
  }

  /// Copies the `AttIntervalHarmonic` members from [other].
  void copyAttIntervalHarmonic(covariant AttIntervalHarmonic other) {
    inth = other.inth;
  }
}

/// MEI attribute class for `att.IntervalMelodic` (mirrors `vrv::AttIntervalMelodic`).
mixin AttIntervalMelodic {
  /// `intm` — std::string.
  String? intm;
  bool get hasIntm => intm != null;

  /// Mirrors `AttIntervalMelodic::ReadIntervalMelodic`.
  bool readIntervalMelodic(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final intmRaw = element.get('intm');
    if (intmRaw != null) {
      intm = identityStr(intmRaw);
      if (removeAttr) element.remove('intm');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttIntervalMelodic::WriteIntervalMelodic`.
  void writeIntervalMelodic(XmlBuilder element) {
    if (hasIntm) {
      element.attribute('intm', identityStr(intm!));
    }
  }

  /// Copies the `AttIntervalMelodic` members from [other].
  void copyAttIntervalMelodic(covariant AttIntervalMelodic other) {
    intm = other.intm;
  }
}

/// MEI attribute class for `att.KeySigAnl` (mirrors `vrv::AttKeySigAnl`).
mixin AttKeySigAnl {
  /// `accid` — data_ACCIDENTAL_GESTURAL_basic.
  AccidentalGesturalBasic? accid;
  bool get hasAccid => accid != null;

  /// `mode` — data_MODE.
  Mode? mode;
  bool get hasMode => mode != null;

  /// Mirrors `AttKeySigAnl::ReadKeySigAnl`.
  bool readKeySigAnl(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final accidRaw = element.get('accid');
    if (accidRaw != null) {
      accid = strToAccidentalGesturalBasic(accidRaw);
      if (removeAttr) element.remove('accid');
      hasAttribute = true;
    }
    final modeRaw = element.get('mode');
    if (modeRaw != null) {
      mode = strToMode(modeRaw);
      if (removeAttr) element.remove('mode');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttKeySigAnl::WriteKeySigAnl`.
  void writeKeySigAnl(XmlBuilder element) {
    if (hasAccid) {
      element.attribute('accid', accidentalGesturalBasicToStr(accid!));
    }
    if (hasMode) {
      element.attribute('mode', modeToStr(mode!));
    }
  }

  /// Copies the `AttKeySigAnl` members from [other].
  void copyAttKeySigAnl(covariant AttKeySigAnl other) {
    accid = other.accid;
    mode = other.mode;
  }
}

/// MEI attribute class for `att.KeySigDefaultAnl` (mirrors `vrv::AttKeySigDefaultAnl`).
mixin AttKeySigDefaultAnl {
  /// `key.accid` — data_ACCIDENTAL_GESTURAL_basic.
  AccidentalGesturalBasic? keyAccid;
  bool get hasKeyAccid => keyAccid != null;

  /// `key.mode` — data_MODE.
  Mode? keyMode;
  bool get hasKeyMode => keyMode != null;

  /// `key.pname` — data_PITCHNAME.
  Pitchname? keyPname;
  bool get hasKeyPname => keyPname != null;

  /// Mirrors `AttKeySigDefaultAnl::ReadKeySigDefaultAnl`.
  bool readKeySigDefaultAnl(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final keyAccidRaw = element.get('key.accid');
    if (keyAccidRaw != null) {
      keyAccid = strToAccidentalGesturalBasic(keyAccidRaw);
      if (removeAttr) element.remove('key.accid');
      hasAttribute = true;
    }
    final keyModeRaw = element.get('key.mode');
    if (keyModeRaw != null) {
      keyMode = strToMode(keyModeRaw);
      if (removeAttr) element.remove('key.mode');
      hasAttribute = true;
    }
    final keyPnameRaw = element.get('key.pname');
    if (keyPnameRaw != null) {
      keyPname = strToPitchname(keyPnameRaw);
      if (removeAttr) element.remove('key.pname');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttKeySigDefaultAnl::WriteKeySigDefaultAnl`.
  void writeKeySigDefaultAnl(XmlBuilder element) {
    if (hasKeyAccid) {
      element.attribute('key.accid', accidentalGesturalBasicToStr(keyAccid!));
    }
    if (hasKeyMode) {
      element.attribute('key.mode', modeToStr(keyMode!));
    }
    if (hasKeyPname) {
      element.attribute('key.pname', pitchnameToStr(keyPname!));
    }
  }

  /// Copies the `AttKeySigDefaultAnl` members from [other].
  void copyAttKeySigDefaultAnl(covariant AttKeySigDefaultAnl other) {
    keyAccid = other.keyAccid;
    keyMode = other.keyMode;
    keyPname = other.keyPname;
  }
}

/// MEI attribute class for `att.MelodicFunction` (mirrors `vrv::AttMelodicFunction`).
mixin AttMelodicFunction {
  /// `mfunc` — data_MELODICFUNCTION.
  Melodicfunction? mfunc;
  bool get hasMfunc => mfunc != null;

  /// Mirrors `AttMelodicFunction::ReadMelodicFunction`.
  bool readMelodicFunction(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final mfuncRaw = element.get('mfunc');
    if (mfuncRaw != null) {
      mfunc = strToMelodicfunction(mfuncRaw);
      if (removeAttr) element.remove('mfunc');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMelodicFunction::WriteMelodicFunction`.
  void writeMelodicFunction(XmlBuilder element) {
    if (hasMfunc) {
      element.attribute('mfunc', melodicfunctionToStr(mfunc!));
    }
  }

  /// Copies the `AttMelodicFunction` members from [other].
  void copyAttMelodicFunction(covariant AttMelodicFunction other) {
    mfunc = other.mfunc;
  }
}

/// MEI attribute class for `att.PitchClass` (mirrors `vrv::AttPitchClass`).
mixin AttPitchClass {
  /// `pclass` — int.
  int? pclass;
  bool get hasPclass => pclass != null;

  /// Mirrors `AttPitchClass::ReadPitchClass`.
  bool readPitchClass(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final pclassRaw = element.get('pclass');
    if (pclassRaw != null) {
      pclass = strToInt(pclassRaw);
      if (removeAttr) element.remove('pclass');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttPitchClass::WritePitchClass`.
  void writePitchClass(XmlBuilder element) {
    if (hasPclass) {
      element.attribute('pclass', intToStr(pclass!));
    }
  }

  /// Copies the `AttPitchClass` members from [other].
  void copyAttPitchClass(covariant AttPitchClass other) {
    pclass = other.pclass;
  }
}

/// MEI attribute class for `att.Solfa` (mirrors `vrv::AttSolfa`).
mixin AttSolfa {
  /// `psolfa` — std::string.
  String? psolfa;
  bool get hasPsolfa => psolfa != null;

  /// Mirrors `AttSolfa::ReadSolfa`.
  bool readSolfa(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final psolfaRaw = element.get('psolfa');
    if (psolfaRaw != null) {
      psolfa = identityStr(psolfaRaw);
      if (removeAttr) element.remove('psolfa');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttSolfa::WriteSolfa`.
  void writeSolfa(XmlBuilder element) {
    if (hasPsolfa) {
      element.attribute('psolfa', identityStr(psolfa!));
    }
  }

  /// Copies the `AttSolfa` members from [other].
  void copyAttSolfa(covariant AttSolfa other) {
    psolfa = other.psolfa;
  }
}
