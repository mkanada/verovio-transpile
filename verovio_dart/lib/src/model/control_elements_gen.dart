// GENERATED FILE - one-shot migration from origin/src/include/vrv.
// Element leaf classes; regenerate via tool/gen_elements.py when the C++
// source changes. Do not hand-edit lightly.

import 'package:verovio_dart/src/model/atts/atts_cmn.dart';
import 'package:verovio_dart/src/model/atts/atts_cmnornaments.dart';
import 'package:verovio_dart/src/model/atts/atts_externalsymbols.dart';
import 'package:verovio_dart/src/model/atts/atts_midi.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/atts_visual.dart';
import 'package:verovio_dart/src/model/interfaces/plist_interface.dart';
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/control_element.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';

/// Mirrors `vrv::AnchoredText`.
class AnchoredText extends ControlElement
    with AttPlacementRelStaff, TextDirInterface {
  AnchoredText() : super(ClassId.anchoredText) {
    registerInterfaces([
      InterfaceId.textDir,
    ]);
    reset();
  }

  @override
  String get className => 'anchoredText';

  @override
  Object clone() {
    final copy = AnchoredText();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant AnchoredText other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyAttPlacementRelStaff(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::AnnotScore`.
class AnnotScore extends ControlElement
    with
        AttPlist,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        PlistInterface,
        TimePointInterface,
        TimeSpanningInterface {
  AnnotScore() : super(ClassId.annotScore) {
    registerInterfaces([
      InterfaceId.plist,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'annot';

  @override
  Object clone() {
    final copy = AnnotScore();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant AnnotScore other) {
    super.copyFrom(other);
    copyPlistFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttPlist(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors AnnotScore::IsSupportedChild.
    if (classId == ClassId.annotScore) return true;
    if (Object.isTextElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Arpeg`.
class Arpeg extends ControlElement
    with
        AttPlist,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttArpegLog,
        AttArpegVis,
        AttEnclosingChars,
        PlistInterface,
        TimePointInterface {
  Arpeg() : super(ClassId.arpeg) {
    registerInterfaces([
      InterfaceId.plist,
      InterfaceId.timePoint,
    ]);
    reset();
  }

  @override
  String get className => 'arpeg';

  @override
  Object clone() {
    final copy = Arpeg();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Arpeg other) {
    super.copyFrom(other);
    copyPlistFrom(other);
    copyTimePointFrom(other);
    copyAttArpegLog(other);
    copyAttArpegVis(other);
    copyAttEnclosingChars(other);
    copyAttPlist(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }
}

/// Mirrors `vrv::BeamSpan`.
class BeamSpan extends ControlElement
    with
        AttPlist,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttBeamedWith,
        AttBeamRend,
        BeamDrawingInterface,
        PlistInterface,
        TimePointInterface,
        TimeSpanningInterface {
  BeamSpan() : super(ClassId.beamSpan) {
    registerInterfaces([
      InterfaceId.plist,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  /// The beamed elements of the beam span (set by the beamspan preparation;
  /// mirrors `m_beamedElements`).
  final List<Object> beamedElements = [];

  /// Mirrors `SetBeamedElements` / `GetBeamedElements`.
  void setBeamedElements(List<Object> elements) {
    beamedElements
      ..clear()
      ..addAll(elements);
  }

  List<Object> getBeamedElements() => beamedElements;

  /// Reset the beamed elements (mirrors `ResetBeamedElements`).
  void resetBeamedElements() => beamedElements.clear();

  /// Clear the beam segments (mirrors `ClearBeamSegments`); the segment
  /// machinery itself arrives with the layout phase.
  void clearBeamSegments() {}

  /// Initialize the beam segments (mirrors `InitBeamSegments`); deferred to
  /// the layout phase.
  void initBeamSegments() {}

  @override
  String get className => 'beamSpan';

  @override
  Object clone() {
    final copy = BeamSpan();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant BeamSpan other) {
    super.copyFrom(other);
    copyPlistFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttBeamedWith(other);
    copyAttBeamRend(other);
    copyAttPlist(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::BracketSpan`.
class BracketSpan extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttBracketSpanLog,
        AttLineRend,
        AttLineRendBase,
        TimePointInterface,
        TimeSpanningInterface {
  BracketSpan() : super(ClassId.bracketSpan) {
    registerInterfaces([
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'bracketSpan';

  @override
  Object clone() {
    final copy = BracketSpan();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant BracketSpan other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttBracketSpanLog(other);
    copyAttLineRend(other);
    copyAttLineRendBase(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::Breath`.
class Breath extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttPlacementRelStaff,
        TimePointInterface {
  Breath() : super(ClassId.breath) {
    registerInterfaces([
      InterfaceId.timePoint,
    ]);
    reset();
  }

  @override
  String get className => 'breath';

  @override
  Object clone() {
    final copy = Breath();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Breath other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }
}

/// Mirrors `vrv::Caesura`.
class Caesura extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttExtSymAuth,
        AttExtSymNames,
        AttPlacementRelStaff,
        TimePointInterface {
  Caesura() : super(ClassId.caesura) {
    registerInterfaces([
      InterfaceId.timePoint,
    ]);
    reset();
  }

  @override
  String get className => 'caesura';

  @override
  Object clone() {
    final copy = Caesura();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Caesura other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }
}

/// Mirrors `vrv::CpMark`.
class CpMark extends ControlElement
    with
        AttPlacementRelStaff,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        ObjectListInterface,
        TextListInterface,
        TextDirInterface,
        TimePointInterface,
        TimeSpanningInterface {
  CpMark() : super(ClassId.cpMark) {
    registerInterfaces([
      InterfaceId.textDir,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'cpMark';

  @override
  Object clone() {
    final copy = CpMark();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant CpMark other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Dir`.
class Dir extends ControlElement
    with
        AttPlacementRelStaff,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttExtender,
        AttLang,
        AttLineRendBase,
        AttVerticalGroup,
        ObjectListInterface,
        TextListInterface,
        TextDirInterface,
        TimePointInterface,
        TimeSpanningInterface {
  /// Whether this is a `<stageDir>` (mirrors `m_isStageDir`).
  bool isStageDirFlag = false;

  /// Mirrors `IsStageDir` (also used for className).
  bool isStageDir() => isStageDirFlag;

  @override
  String get className => isStageDirFlag ? 'stageDir' : 'dir';

  Dir([bool isStageDir = false]) : super(ClassId.dir) {
    isStageDirFlag = isStageDir;
    registerInterfaces([
      InterfaceId.textDir,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  @override
  Object clone() {
    final copy = Dir();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Dir other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttExtender(other);
    copyAttLang(other);
    copyAttLineRendBase(other);
    copyAttVerticalGroup(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::Dynam`.
class Dynam extends ControlElement
    with
        AttPlacementRelStaff,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttEnclosingChars,
        AttExtender,
        AttLineRendBase,
        AttMidiValue,
        AttMidiValue2,
        AttVerticalGroup,
        ObjectListInterface,
        TextListInterface,
        TextDirInterface,
        TimePointInterface,
        TimeSpanningInterface {
  Dynam() : super(ClassId.dynam) {
    registerInterfaces([
      InterfaceId.textDir,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'dynam';

  @override
  Object clone() {
    final copy = Dynam();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Dynam other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttEnclosingChars(other);
    copyAttExtender(other);
    copyAttLineRendBase(other);
    copyAttMidiValue(other);
    copyAttMidiValue2(other);
    copyAttVerticalGroup(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Fermata`.
class Fermata extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttEnclosingChars,
        AttExtSymAuth,
        AttExtSymNames,
        AttFermataVis,
        AttPlacementRelStaff,
        TimePointInterface {
  Fermata() : super(ClassId.fermata) {
    registerInterfaces([
      InterfaceId.timePoint,
    ]);
    reset();
  }

  @override
  String get className => 'fermata';

  @override
  Object clone() {
    final copy = Fermata();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Fermata other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyAttEnclosingChars(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttFermataVis(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }
}

/// Mirrors `vrv::Fing`.
class Fing extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttPlacementRelStaff,
        AttNNumberLike,
        TimePointInterface,
        TextDirInterface {
  Fing() : super(ClassId.fing) {
    registerInterfaces([
      InterfaceId.timePoint,
      InterfaceId.textDir,
    ]);
    reset();
  }

  @override
  String get className => 'fing';

  @override
  Object clone() {
    final copy = Fing();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Fing other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyTextDirFrom(other);
    copyAttNNumberLike(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttPlacementRelStaff(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Gliss`.
class Gliss extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttLineRend,
        AttLineRendBase,
        AttNNumberLike,
        TimePointInterface,
        TimeSpanningInterface {
  Gliss() : super(ClassId.gliss) {
    registerInterfaces([
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'gliss';

  @override
  Object clone() {
    final copy = Gliss();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Gliss other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttLineRend(other);
    copyAttLineRendBase(other);
    copyAttNNumberLike(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::Hairpin`.
class Hairpin extends ControlElement
    with
        AttVisualOffset2Ho,
        AttVisualOffset2Vo,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttHairpinLog,
        AttHairpinVis,
        AttLineRendBase,
        AttPlacementRelStaff,
        AttVerticalGroup,
        OffsetSpanningInterface,
        TimePointInterface,
        TimeSpanningInterface {
  Hairpin() : super(ClassId.hairpin) {
    registerInterfaces([
      InterfaceId.offsetSpanning,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  /// The left / right linked dynamics or hairpins (mirrors `m_leftLink` /
  /// `m_rightLink`).
  Object? leftLink;
  Object? rightLink;

  /// The drawing length of the hairpin (mirrors `m_drawingLength`).
  int drawingLength = 0;

  /// Mirrors `SetLeftLink` / `GetLeftLink`.
  void setLeftLink(Object? link) => leftLink = link;
  Object? getLeftLink() => leftLink;

  /// Mirrors `SetRightLink` / `GetRightLink`.
  void setRightLink(Object? link) => rightLink = link;
  Object? getRightLink() => rightLink;

  /// Mirrors `SetDrawingLength` / `GetDrawingLength`.
  void setDrawingLength(int length) => drawingLength = length;
  int getDrawingLength() => drawingLength;

  @override
  String get className => 'hairpin';

  @override
  Object clone() {
    final copy = Hairpin();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Hairpin other) {
    super.copyFrom(other);
    copyOffsetSpanningFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttHairpinLog(other);
    copyAttHairpinVis(other);
    copyAttLineRendBase(other);
    copyAttPlacementRelStaff(other);
    copyAttVerticalGroup(other);
    copyAttVisualOffset2Ho(other);
    copyAttVisualOffset2Vo(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::Harm`.
class Harm extends ControlElement
    with
        AttPlacementRelStaff,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttLang,
        AttNNumberLike,
        ObjectListInterface,
        TextListInterface,
        TextDirInterface,
        TimePointInterface,
        TimeSpanningInterface {
  Harm() : super(ClassId.harm) {
    registerInterfaces([
      InterfaceId.textDir,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'harm';

  @override
  Object clone() {
    final copy = Harm();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Harm other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttLang(other);
    copyAttNNumberLike(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors Harm::IsSupportedChild.
    if (Object.isTextElementId(classId)) return true;
    if (classId == ClassId.fb) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::MNum`.
class MNum extends ControlElement
    with
        AttPlacementRelStaff,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttLang,
        AttTypography,
        ObjectListInterface,
        TextListInterface,
        TextDirInterface,
        TimePointInterface {
  /// Whether the measure number was generated (mirrors `m_isGenerated`).
  bool isGeneratedFlag = false;

  MNum() : super(ClassId.mnum) {
    registerInterfaces([
      InterfaceId.textDir,
      InterfaceId.timePoint,
    ]);
    reset();
  }

  @override
  String get className => 'mNum';

  @override
  Object clone() {
    final copy = MNum();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant MNum other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyTimePointFrom(other);
    copyAttLang(other);
    copyAttTypography(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Mordent`.
class Mordent extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttEnclosingChars,
        AttExtSymAuth,
        AttExtSymNames,
        AttOrnamentAccid,
        AttPlacementRelStaff,
        AttMordentLog,
        TimePointInterface {
  Mordent() : super(ClassId.mordent) {
    registerInterfaces([
      InterfaceId.timePoint,
    ]);
    reset();
  }

  @override
  String get className => 'mordent';

  @override
  Object clone() {
    final copy = Mordent();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Mordent other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyAttEnclosingChars(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttOrnamentAccid(other);
    copyAttPlacementRelStaff(other);
    copyAttMordentLog(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }
}

/// Mirrors `vrv::Octave`.
class Octave extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttExtender,
        AttLineRend,
        AttLineRendBase,
        AttNNumberLike,
        AttOctaveDisplacement,
        TimePointInterface,
        TimeSpanningInterface {
  Octave() : super(ClassId.octave) {
    registerInterfaces([
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'octave';

  @override
  Object clone() {
    final copy = Octave();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Octave other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttExtender(other);
    copyAttLineRend(other);
    copyAttLineRendBase(other);
    copyAttNNumberLike(other);
    copyAttOctaveDisplacement(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::Ornam`.
class Ornam extends ControlElement
    with
        AttPlacementRelStaff,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttOrnamentAccid,
        ObjectListInterface,
        TextListInterface,
        TextDirInterface,
        TimePointInterface {
  Ornam() : super(ClassId.ornam) {
    registerInterfaces([
      InterfaceId.textDir,
      InterfaceId.timePoint,
    ]);
    reset();
  }

  @override
  String get className => 'ornam';

  @override
  Object clone() {
    final copy = Ornam();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Ornam other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyTimePointFrom(other);
    copyAttOrnamentAccid(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Pedal`.
class Pedal extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttExtSymAuth,
        AttExtSymNames,
        AttPedalLog,
        AttPedalVis,
        AttPlacementRelStaff,
        AttVerticalGroup,
        TimePointInterface,
        TimeSpanningInterface {
  Pedal() : super(ClassId.pedal) {
    registerInterfaces([
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  /// True when the pedal line ends with a bounce (set by the pedals
  /// preparation; mirrors `m_endsWithBounce`).
  bool endsWithBounce = false;

  /// Mirrors `EndsWithBounce(bool)` / `EndsWithBounce()`.
  void setEndsWithBounce({bool bounce = true}) => endsWithBounce = bounce;
  bool getEndsWithBounce() => endsWithBounce;

  @override
  String get className => 'pedal';

  @override
  Object clone() {
    final copy = Pedal();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Pedal other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttPedalLog(other);
    copyAttPedalVis(other);
    copyAttPlacementRelStaff(other);
    copyAttVerticalGroup(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::PitchInflection`.
class PitchInflection extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        TimePointInterface,
        TimeSpanningInterface {
  PitchInflection() : super(ClassId.pitchInflection) {
    registerInterfaces([
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'pitchInflection';

  @override
  Object clone() {
    final copy = PitchInflection();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant PitchInflection other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::Reh`.
class Reh extends ControlElement
    with
        AttPlacementRelStaff,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttLang,
        AttVerticalGroup,
        TextDirInterface,
        TimePointInterface {
  Reh() : super(ClassId.reh) {
    registerInterfaces([
      InterfaceId.textDir,
      InterfaceId.timePoint,
    ]);
    reset();
  }

  @override
  String get className => 'reh';

  @override
  Object clone() {
    final copy = Reh();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Reh other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyTimePointFrom(other);
    copyAttLang(other);
    copyAttVerticalGroup(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::RepeatMark`.
class RepeatMark extends ControlElement
    with
        AttPlacementRelStaff,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttExtSymAuth,
        AttExtSymNames,
        AttRepeatMarkLog,
        ObjectListInterface,
        TextListInterface,
        TextDirInterface,
        TimePointInterface {
  RepeatMark() : super(ClassId.repeatMark) {
    registerInterfaces([
      InterfaceId.textDir,
      InterfaceId.timePoint,
    ]);
    reset();
  }

  @override
  String get className => 'repeatMark';

  @override
  Object clone() {
    final copy = RepeatMark();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant RepeatMark other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyTimePointFrom(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttRepeatMarkLog(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Slur`.
class Slur extends ControlElement
    with
        AttVisualOffset2Ho,
        AttVisualOffset2Vo,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttCurvature,
        AttLayerIdent,
        AttLineRendBase,
        OffsetSpanningInterface,
        TimePointInterface,
        TimeSpanningInterface {
  Slur() : super(ClassId.slur) {
    registerInterfaces([
      InterfaceId.offsetSpanning,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  /// The drawing curve direction of the slur (mirrors `m_drawingCurveDir`).
  SlurCurveDirection drawingCurveDir = SlurCurveDirection.none;

  /// Mirrors `SetDrawingCurveDir` / `HasDrawingCurveDir`.
  void setDrawingCurveDir(SlurCurveDirection dir) => drawingCurveDir = dir;
  bool hasDrawingCurveDir() => drawingCurveDir != SlurCurveDirection.none;

  @override
  String get className => 'slur';

  @override
  Object clone() {
    final copy = Slur();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Slur other) {
    super.copyFrom(other);
    copyOffsetSpanningFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttCurvature(other);
    copyAttLayerIdent(other);
    copyAttLineRendBase(other);
    copyAttVisualOffset2Ho(other);
    copyAttVisualOffset2Vo(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::Tempo`.
class Tempo extends ControlElement
    with
        AttPlacementRelStaff,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttExtender,
        AttLang,
        AttMidiTempo,
        AttMmTempo,
        TextDirInterface,
        TimePointInterface,
        TimeSpanningInterface {
  Tempo() : super(ClassId.tempo) {
    registerInterfaces([
      InterfaceId.textDir,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  /// The drawing x relative position of the tempo (mirrors
  /// `m_drawingXRelative`).
  int drawingXRelative = 0;

  /// Mirrors `Tempo::ResetDrawingXRelative`.
  void resetDrawingXRelative() => drawingXRelative = 0;

  @override
  String get className => 'tempo';

  @override
  Object clone() {
    final copy = Tempo();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Tempo other) {
    super.copyFrom(other);
    copyTextDirFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttExtender(other);
    copyAttLang(other);
    copyAttMidiTempo(other);
    copyAttMmTempo(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors the C++: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Tie`.
class Tie extends ControlElement
    with
        AttVisualOffset2Ho,
        AttVisualOffset2Vo,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttCurvature,
        AttLineRendBase,
        OffsetSpanningInterface,
        TimePointInterface,
        TimeSpanningInterface {
  Tie() : super(ClassId.tie) {
    registerInterfaces([
      InterfaceId.offsetSpanning,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  /// The drawing curve direction (in the C++ inherited from Slur through
  /// `Tie : public Slur`; mirrors `m_drawingCurveDir`).
  SlurCurveDirection drawingCurveDir = SlurCurveDirection.none;

  /// Mirrors `SetDrawingCurveDir` / `HasDrawingCurveDir`.
  void setDrawingCurveDir(SlurCurveDirection dir) => drawingCurveDir = dir;
  bool hasDrawingCurveDir() => drawingCurveDir != SlurCurveDirection.none;

  @override
  String get className => 'tie';

  @override
  Object clone() {
    final copy = Tie();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Tie other) {
    super.copyFrom(other);
    copyOffsetSpanningFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttCurvature(other);
    copyAttLineRendBase(other);
    copyAttVisualOffset2Ho(other);
    copyAttVisualOffset2Vo(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::Trill`.
class Trill extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttEnclosingChars,
        AttExtender,
        AttExtSymAuth,
        AttExtSymNames,
        AttLineRend,
        AttNNumberLike,
        AttOrnamentAccid,
        AttPlacementRelStaff,
        TimePointInterface,
        TimeSpanningInterface {
  Trill() : super(ClassId.trill) {
    registerInterfaces([
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'trill';

  @override
  Object clone() {
    final copy = Trill();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Trill other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttEnclosingChars(other);
    copyAttExtender(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttLineRend(other);
    copyAttNNumberLike(other);
    copyAttOrnamentAccid(other);
    copyAttPlacementRelStaff(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }
}

/// Mirrors `vrv::Turn`.
class Turn extends ControlElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttEnclosingChars,
        AttExtSymAuth,
        AttExtSymNames,
        AttOrnamentAccid,
        AttPlacementRelStaff,
        AttTurnLog,
        TimePointInterface {
  Turn() : super(ClassId.turn) {
    registerInterfaces([
      InterfaceId.timePoint,
    ]);
    reset();
  }

  /// The drawing end element of a delayed turn (set by the delayed turns
  /// preparation; mirrors `m_drawingEndElement`).
  Object? drawingEndElement;

  @override
  String get className => 'turn';

  @override
  Object clone() {
    final copy = Turn();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Turn other) {
    super.copyFrom(other);
    copyTimePointFrom(other);
    copyAttEnclosingChars(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttOrnamentAccid(other);
    copyAttPlacementRelStaff(other);
    copyAttTurnLog(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
  }
}

/// Mirrors `vrv::Lv`: a tie-like curve between notes of different staves.
class Lv extends Tie {
  Lv() : super() {
    assignClassId(ClassId.lv);
  }

  @override
  String get className => 'lv';

  @override
  Object clone() {
    final copy = Lv();
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::Phrase`: a slur-like phrase mark.
class Phrase extends Slur {
  Phrase() : super() {
    assignClassId(ClassId.phrase);
  }

  @override
  String get className => 'phrase';

  @override
  Object clone() {
    final copy = Phrase();
    copy.copyFrom(this);
    return copy;
  }
}
