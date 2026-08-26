// GENERATED FILE - do not edit. Regenerate with:
//   dart run tool/gen_atts.dart
// Source: origin/src/libmei/dist/atts_mensural.h/.cpp
library;

import 'package:xml/xml.dart';
import 'atts_conversion.dart';
import 'mei_enums.dart';
import 'mei_values.dart';

/// MEI attribute class for `att.DurationQuality` (mirrors `vrv::AttDurationQuality`).
mixin AttDurationQuality {
  /// `dur.quality` — data_DURQUALITY_mensural.
  DurqualityMensural? durQuality;
  bool get hasDurQuality => durQuality != null;

  /// Mirrors `AttDurationQuality::ReadDurationQuality`.
  bool readDurationQuality(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final durQualityRaw = element.get('dur.quality');
    if (durQualityRaw != null) {
      durQuality = strToDurqualityMensural(durQualityRaw);
      if (removeAttr) element.remove('dur.quality');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttDurationQuality::WriteDurationQuality`.
  void writeDurationQuality(XmlBuilder element) {
    if (hasDurQuality) {
      element.attribute('dur.quality', durqualityMensuralToStr(durQuality!));
    }
  }

  /// Copies the `AttDurationQuality` members from [other].
  void copyAttDurationQuality(covariant AttDurationQuality other) {
    durQuality = other.durQuality;
  }
}

/// MEI attribute class for `att.MensuralLog` (mirrors `vrv::AttMensuralLog`).
mixin AttMensuralLog {
  /// `proport.num` — int.
  int? proportNum;
  bool get hasProportNum => proportNum != null;

  /// `proport.numbase` — int.
  int? proportNumbase;
  bool get hasProportNumbase => proportNumbase != null;

  /// Mirrors `AttMensuralLog::ReadMensuralLog`.
  bool readMensuralLog(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final proportNumRaw = element.get('proport.num');
    if (proportNumRaw != null) {
      proportNum = strToInt(proportNumRaw);
      if (removeAttr) element.remove('proport.num');
      hasAttribute = true;
    }
    final proportNumbaseRaw = element.get('proport.numbase');
    if (proportNumbaseRaw != null) {
      proportNumbase = strToInt(proportNumbaseRaw);
      if (removeAttr) element.remove('proport.numbase');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMensuralLog::WriteMensuralLog`.
  void writeMensuralLog(XmlBuilder element) {
    if (hasProportNum) {
      element.attribute('proport.num', intToStr(proportNum!));
    }
    if (hasProportNumbase) {
      element.attribute('proport.numbase', intToStr(proportNumbase!));
    }
  }

  /// Copies the `AttMensuralLog` members from [other].
  void copyAttMensuralLog(covariant AttMensuralLog other) {
    proportNum = other.proportNum;
    proportNumbase = other.proportNumbase;
  }
}

/// MEI attribute class for `att.MensuralShared` (mirrors `vrv::AttMensuralShared`).
mixin AttMensuralShared {
  /// `modusmaior` — data_MODUSMAIOR.
  Modusmaior? modusmaior;
  bool get hasModusmaior => modusmaior != null;

  /// `modusminor` — data_MODUSMINOR.
  Modusminor? modusminor;
  bool get hasModusminor => modusminor != null;

  /// `prolatio` — data_PROLATIO.
  Prolatio? prolatio;
  bool get hasProlatio => prolatio != null;

  /// `tempus` — data_TEMPUS.
  Tempus? tempus;
  bool get hasTempus => tempus != null;

  /// `divisio` — data_DIVISIO.
  Divisio? divisio;
  bool get hasDivisio => divisio != null;

  /// Mirrors `AttMensuralShared::ReadMensuralShared`.
  bool readMensuralShared(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final modusmaiorRaw = element.get('modusmaior');
    if (modusmaiorRaw != null) {
      modusmaior = strToModusmaior(modusmaiorRaw);
      if (removeAttr) element.remove('modusmaior');
      hasAttribute = true;
    }
    final modusminorRaw = element.get('modusminor');
    if (modusminorRaw != null) {
      modusminor = strToModusminor(modusminorRaw);
      if (removeAttr) element.remove('modusminor');
      hasAttribute = true;
    }
    final prolatioRaw = element.get('prolatio');
    if (prolatioRaw != null) {
      prolatio = strToProlatio(prolatioRaw);
      if (removeAttr) element.remove('prolatio');
      hasAttribute = true;
    }
    final tempusRaw = element.get('tempus');
    if (tempusRaw != null) {
      tempus = strToTempus(tempusRaw);
      if (removeAttr) element.remove('tempus');
      hasAttribute = true;
    }
    final divisioRaw = element.get('divisio');
    if (divisioRaw != null) {
      divisio = strToDivisio(divisioRaw);
      if (removeAttr) element.remove('divisio');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttMensuralShared::WriteMensuralShared`.
  void writeMensuralShared(XmlBuilder element) {
    if (hasModusmaior) {
      element.attribute('modusmaior', modusmaiorToStr(modusmaior!));
    }
    if (hasModusminor) {
      element.attribute('modusminor', modusminorToStr(modusminor!));
    }
    if (hasProlatio) {
      element.attribute('prolatio', prolatioToStr(prolatio!));
    }
    if (hasTempus) {
      element.attribute('tempus', tempusToStr(tempus!));
    }
    if (hasDivisio) {
      element.attribute('divisio', divisioToStr(divisio!));
    }
  }

  /// Copies the `AttMensuralShared` members from [other].
  void copyAttMensuralShared(covariant AttMensuralShared other) {
    modusmaior = other.modusmaior;
    modusminor = other.modusminor;
    prolatio = other.prolatio;
    tempus = other.tempus;
    divisio = other.divisio;
  }
}

/// MEI attribute class for `att.NoteVisMensural` (mirrors `vrv::AttNoteVisMensural`).
mixin AttNoteVisMensural {
  /// `lig` — data_LIGATUREFORM.
  Ligatureform? lig;
  bool get hasLig => lig != null;

  /// Mirrors `AttNoteVisMensural::ReadNoteVisMensural`.
  bool readNoteVisMensural(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final ligRaw = element.get('lig');
    if (ligRaw != null) {
      lig = strToLigatureform(ligRaw);
      if (removeAttr) element.remove('lig');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttNoteVisMensural::WriteNoteVisMensural`.
  void writeNoteVisMensural(XmlBuilder element) {
    if (hasLig) {
      element.attribute('lig', ligatureformToStr(lig!));
    }
  }

  /// Copies the `AttNoteVisMensural` members from [other].
  void copyAttNoteVisMensural(covariant AttNoteVisMensural other) {
    lig = other.lig;
  }
}

/// MEI attribute class for `att.RestVisMensural` (mirrors `vrv::AttRestVisMensural`).
mixin AttRestVisMensural {
  /// `spaces` — int.
  int? spaces;
  bool get hasSpaces => spaces != null;

  /// Mirrors `AttRestVisMensural::ReadRestVisMensural`.
  bool readRestVisMensural(MeiAttributeReader element,
      {bool removeAttr = true}) {
    bool hasAttribute = false;
    final spacesRaw = element.get('spaces');
    if (spacesRaw != null) {
      spaces = strToInt(spacesRaw);
      if (removeAttr) element.remove('spaces');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttRestVisMensural::WriteRestVisMensural`.
  void writeRestVisMensural(XmlBuilder element) {
    if (hasSpaces) {
      element.attribute('spaces', intToStr(spaces!));
    }
  }

  /// Copies the `AttRestVisMensural` members from [other].
  void copyAttRestVisMensural(covariant AttRestVisMensural other) {
    spaces = other.spaces;
  }
}

/// MEI attribute class for `att.StemsMensural` (mirrors `vrv::AttStemsMensural`).
mixin AttStemsMensural {
  /// `stem.form` — data_STEMFORM_mensural.
  StemformMensural? stemForm;
  bool get hasStemForm => stemForm != null;

  /// Mirrors `AttStemsMensural::ReadStemsMensural`.
  bool readStemsMensural(MeiAttributeReader element, {bool removeAttr = true}) {
    bool hasAttribute = false;
    final stemFormRaw = element.get('stem.form');
    if (stemFormRaw != null) {
      stemForm = strToStemformMensural(stemFormRaw);
      if (removeAttr) element.remove('stem.form');
      hasAttribute = true;
    }
    return hasAttribute;
  }

  /// Mirrors `AttStemsMensural::WriteStemsMensural`.
  void writeStemsMensural(XmlBuilder element) {
    if (hasStemForm) {
      element.attribute('stem.form', stemformMensuralToStr(stemForm!));
    }
  }

  /// Copies the `AttStemsMensural` members from [other].
  void copyAttStemsMensural(covariant AttStemsMensural other) {
    stemForm = other.stemForm;
  }
}
