// Originalmente gerado por tool/gen_elements.py; MANTIDO À MÃO desde 2026-08-26.
// Element leaf classes mirroring the C++ element headers; edit by hand (the
// generator was retired — see prompts/reports/04i.md).

import 'package:verovio_dart/src/model/atts/atts_externalsymbols.dart';
import 'package:verovio_dart/src/model/atts/atts_facsimile.dart';
import 'package:verovio_dart/src/model/atts/atts_midi.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/interfaces/facsimile_interface.dart';
import 'package:verovio_dart/src/model/interfaces/plist_interface.dart';
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/system_page_elements.dart';
import 'package:verovio_dart/src/model/text_elements.dart';
import 'package:verovio_dart/src/model/zone.dart' show Zone;
import 'dart:math' show min;

import 'package:verovio_dart/src/core/attdef.dart' show meiUnset;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/core/vrvdef.dart';

// The AlignmentReference stub of the generated file is superseded by the
// full port living in the layout library.
export 'package:verovio_dart/src/layout/horizontal_aligner.dart'
    show AlignmentReference;

/// Mirrors `vrv::Course`.
class Course extends Object
    with AttAccidental, AttNNumberLike, AttOctave, AttPitch {
  Course() : super(ClassId.course) {
    reset();
  }

  @override
  String get className => 'course';

  @override
  Object clone() {
    final copy = Course();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Course other) {
    copyAttAccidental(other);
    copyAttNNumberLike(other);
    copyAttOctave(other);
    copyAttPitch(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    return false;
  }
}

/// Mirrors `vrv::Div`.
class Div extends TextLayoutElement {
  Div() : super(ClassId.div) {
    reset();
  }

  /// True when the div is drawn inline (set by the data initialization;
  /// mirrors `m_drawingInline`).
  bool drawingInline = false;

  /// The drawing x/y offsets of the div (mirrors `m_drawingXRel` /
  /// `m_drawingYRel`).
  int drawingXRel = 0;
  int drawingYRel = 0;

  /// Mirrors `SetDrawingInline` / `GetDrawingInline`.
  void setDrawingInline({bool inline = true}) => drawingInline = inline;
  bool getDrawingInline() => drawingInline;

  /// Mirrors `SetDrawingXRel` / `SetDrawingYRel`.
  void setDrawingXRel(int drawingXRel) => this.drawingXRel = drawingXRel;
  void setDrawingYRel(int drawingYRel) => this.drawingYRel = drawingYRel;

  @override
  String get className => 'div';

  @override
  Object clone() {
    final copy = Div();
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::Ending`.
class Ending extends SystemElement
    with
        AttLabelled,
        AttLineRend,
        AttLineRendBase,
        AttNNumberLike,
        SystemMilestoneInterface {
  Ending() : super(ClassId.ending) {
    reset();
  }

  @override
  String get className => 'ending';

  @override
  Object clone() {
    final copy = Ending();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Ending other) {
    super.copyFrom(other);
    copyAttLabelled(other);
    copyAttLineRend(other);
    copyAttLineRendBase(other);
    copyAttNNumberLike(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors EditorialElement-level support for endings (sections content).
    if (classId == ClassId.measure ||
        classId == ClassId.scoreDef ||
        classId == ClassId.div) {
      return true;
    }
    if (Object.isSystemElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Expansion`.
class Expansion extends SystemElement with AttPlist, PlistInterface {
  Expansion() : super(ClassId.expansion) {
    registerInterfaces([
      InterfaceId.plist,
    ]);
    reset();
  }

  @override
  String get className => 'expansion';

  @override
  Object clone() {
    final copy = Expansion();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Expansion other) {
    super.copyFrom(other);
    copyPlistFrom(other);
    copyAttPlist(other);
  }
}

/// Mirrors `vrv::Facsimile`.
class Facsimile extends Object with AttTyped {
  Facsimile() : super(ClassId.facsimile) {
    reset();
  }

  @override
  String get className => 'facsimile';

  @override
  Object clone() {
    final copy = Facsimile();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Facsimile other) {
    copyAttTyped(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    return classId == ClassId.surface;
  }

  /// Mirrors `Facsimile::GetMaxX`: the max surface GetMaxX.
  int getMaxX() {
    int max = 0;
    for (final Object object in findAllDescendantsByType(ClassId.surface)) {
      final Surface surface = object as Surface;
      max = (surface.getMaxX() > max) ? surface.getMaxX() : max;
    }
    return max;
  }

  /// Mirrors `Facsimile::GetMaxY`.
  int getMaxY() {
    int max = 0;
    for (final Object object in findAllDescendantsByType(ClassId.surface)) {
      final Surface surface = object as Surface;
      max = (surface.getMaxY() > max) ? surface.getMaxY() : max;
    }
    return max;
  }
}

/// Mirrors `vrv::Fig`.
class Fig extends TextElement
    with AttHorizontalAlign, AttVerticalAlign, AreaPosInterface {
  Fig() : super(ClassId.fig) {
    registerInterfaces([
      InterfaceId.areaPos,
    ]);
    reset();
  }

  @override
  String get className => 'fig';

  @override
  Object clone() {
    final copy = Fig();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Fig other) {
    super.copyFrom(other);
    copyAreaPosFrom(other);
    copyAttHorizontalAlign(other);
    copyAttVerticalAlign(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    return false;
  }
}

/// Mirrors `vrv::Graphic`.
class Graphic extends Object with AttPointing, AttWidth, AttHeight, AttTyped {
  Graphic() : super(ClassId.graphic) {
    reset();
  }

  @override
  String get className => 'graphic';

  @override
  Object clone() {
    final copy = Graphic();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Graphic other) {
    copyAttPointing(other);
    copyAttWidth(other);
    copyAttHeight(other);
    copyAttTyped(other);
  }
}

/// Mirrors `vrv::GrpSym`.
class GrpSym extends Object
    with
        AttColor,
        AttGrpSymLog,
        AttStaffGroupingSym,
        AttStartId,
        AttStartEndId {
  GrpSym() : super(ClassId.grpSym) {
    reset();
  }

  /// The starting / ending staffDefs of the group symbol (set by the grpSym
  /// preparation; mirrors `m_startDef` / `m_endDef`).
  Object? startDef;
  Object? endDef;

  /// Mirrors `SetStartDef` / `GetStartDef`.
  void setStartDef(Object? startDef) => this.startDef = startDef;
  Object? getStartDef() => startDef;

  /// Mirrors `SetEndDef` / `GetEndDef`.
  void setEndDef(Object? endDef) => this.endDef = endDef;
  Object? getEndDef() => endDef;

  @override
  String get className => 'grpSym';

  @override
  Object clone() {
    final copy = GrpSym();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant GrpSym other) {
    copyAttColor(other);
    copyAttGrpSymLog(other);
    copyAttStaffGroupingSym(other);
    copyAttStartId(other);
    copyAttStartEndId(other);
  }
}

/// Mirrors `vrv::AlignmentReference`.
///
/// The class is ported in `lib/src/layout/horizontal_aligner.dart` and
/// re-exported above (the generated stub was replaced by the full port).

/// Mirrors `vrv::InstrDef`.
class InstrDef extends Object
    with AttChannelized, AttLabelled, AttMidiInstrument, AttNNumberLike {
  InstrDef() : super(ClassId.instrDef) {
    reset();
  }

  @override
  String get className => 'instrDef';

  @override
  Object clone() {
    final copy = InstrDef();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant InstrDef other) {
    copyAttChannelized(other);
    copyAttLabelled(other);
    copyAttMidiInstrument(other);
    copyAttNNumberLike(other);
  }
}

/// Mirrors `vrv::Label`.
class Label extends Object with ObjectListInterface, TextListInterface {
  final bool _allowText = true;
  Label() : super(ClassId.label) {
    reset();
  }

  @override
  String get className => 'label';

  @override
  Object clone() {
    final copy = Label();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (Object.isEditorialElementId(classId)) return true;
    if (_allowText && (Object.isTextElementId(classId))) return true;
    return false;
  }
}

/// Mirrors `vrv::LabelAbbr`.
class LabelAbbr extends Object with ObjectListInterface, TextListInterface {
  LabelAbbr() : super(ClassId.labelAbbr) {
    reset();
  }

  @override
  String get className => 'labelAbbr';

  @override
  Object clone() {
    final copy = LabelAbbr();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (Object.isEditorialElementId(classId)) return true;
    if (Object.isTextElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Lb`.
class Lb extends TextElement {
  Lb() : super(ClassId.lb) {
    reset();
  }

  @override
  String get className => 'lb';

  @override
  Object clone() {
    final copy = Lb();
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::Num`.
class Num extends TextElement {
  Num() : super(ClassId.num) {
    reset();
  }

  /// Current text for templated numbers
  /// (`<num label="page">#</num>`; mirrors `m_currentText`). Filled by
  /// `RunningElement.setCurrentPageNum` and used by the drawing phase.
  final Text currentText = Text();

  @override
  String get className => 'num';

  @override
  Object clone() {
    final copy = Num();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Num other) {
    super.copyFrom(other);
    currentText.copyFrom(other.currentText);
  }

  /// Return the current (resolved) text object.
  Text getCurrentText() => currentText;

  @override
  bool isSupportedChild(ClassId classId) {
    return classId == ClassId.text;
  }
}

/// Mirrors `vrv::Pb`.
class Pb extends SystemElement
    with AttFacsimile, AttNNumberLike, FacsimileInterface {
  Pb() : super(ClassId.pb) {
    registerInterfaces([
      InterfaceId.facsimile,
    ]);
    reset();
  }

  @override
  String get className => 'pb';

  @override
  Object clone() {
    final copy = Pb();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Pb other) {
    super.copyFrom(other);
    copyFacsimileFrom(other);
    copyAttNNumberLike(other);
    copyAttFacsimile(other);
  }
}

/// Mirrors `vrv::PgFoot`.
class PgFoot extends RunningElement {
  PgFoot() : super(ClassId.pgFoot) {
    reset();
  }

  @override
  String get className => 'pgFoot';

  @override
  Object clone() {
    final copy = PgFoot();
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::PgHead`.
class PgHead extends RunningElement {
  PgHead() : super(ClassId.pgHead) {
    reset();
  }

  @override
  String get className => 'pgHead';

  @override
  Object clone() {
    final copy = PgHead();
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::Rend`.
class Rend extends TextElement
    with
        AttHorizontalAlign,
        AttVerticalAlign,
        AttColor,
        AttExtSymAuth,
        AttLang,
        AttNNumberLike,
        AttTextRendition,
        AttTypography,
        AttWhitespace,
        AreaPosInterface {
  Rend() : super(ClassId.rend) {
    registerInterfaces([
      InterfaceId.areaPos,
    ]);
    reset();
  }

  @override
  String get className => 'rend';

  @override
  Object clone() {
    final copy = Rend();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Rend other) {
    super.copyFrom(other);
    copyAreaPosFrom(other);
    copyAttColor(other);
    copyAttExtSymAuth(other);
    copyAttLang(other);
    copyAttNNumberLike(other);
    copyAttTextRendition(other);
    copyAttTypography(other);
    copyAttWhitespace(other);
    copyAttHorizontalAlign(other);
    copyAttVerticalAlign(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.lb,
      ClassId.num,
      ClassId.rend,
      ClassId.symbol,
      ClassId.text,
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Sb`.
class Sb extends SystemElement
    with AttFacsimile, AttNNumberLike, FacsimileInterface {
  Sb() : super(ClassId.sb) {
    registerInterfaces([
      InterfaceId.facsimile,
    ]);
    reset();
  }

  @override
  String get className => 'sb';

  @override
  Object clone() {
    final copy = Sb();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Sb other) {
    super.copyFrom(other);
    copyFacsimileFrom(other);
    copyAttNNumberLike(other);
    copyAttFacsimile(other);
  }
}

/// Mirrors `vrv::Surface`.
class Surface extends Object with AttTyped, AttCoordinated, AttCoordinatedUl {
  Surface() : super(ClassId.surface) {
    reset();
  }

  @override
  String get className => 'surface';

  @override
  Object clone() {
    final copy = Surface();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Surface other) {
    copyAttTyped(other);
    copyAttCoordinated(other);
    copyAttCoordinatedUl(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors Surface::IsSupportedChild.
    return classId == ClassId.graphic || classId == ClassId.zone;
  }

  /// Mirrors `Surface::GetMaxX`: the lrx if given, otherwise the max zone
  /// lrx.
  int getMaxX() {
    if (hasLrx) return lrx!;
    int max = 0;
    for (final Object object in findAllDescendantsByType(ClassId.zone)) {
      final Zone zone = object as Zone;
      max = (zone.lrx ?? 0) > max ? zone.lrx! : max;
    }
    return max;
  }

  /// Mirrors `Surface::GetMaxY`.
  int getMaxY() {
    if (hasLry) return lry!;
    int max = 0;
    for (final Object object in findAllDescendantsByType(ClassId.zone)) {
      final Zone zone = object as Zone;
      max = (zone.lry ?? 0) > max ? zone.lry! : max;
    }
    return max;
  }
}

/// Mirrors `vrv::Svg`.
class Svg extends Object {
  Svg() : super(ClassId.svg) {
    reset();
  }

  /// The serialized svg content (mirrors the `m_svg` node copy in C++).
  String? content;

  @override
  String get className => 'svg';

  @override
  Object clone() {
    final copy = Svg();
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::Symbol`.
class Symbol extends TextElement
    with AttColor, AttExtSymAuth, AttExtSymNames, AttTypography {
  Symbol() : super(ClassId.symbol) {
    reset();
  }

  @override
  String get className => 'symbol';

  @override
  Object clone() {
    final copy = Symbol();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Symbol other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttTypography(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    return false;
  }
}

/// Mirrors `vrv::SymbolDef`.
class SymbolDef extends Object {
  SymbolDef() : super(ClassId.symbolDef) {
    reset();
  }

  /// The original parent for when a temporary parent is set (mirrors
  /// `m_originalParent`).
  Object? _originalParent;

  @override
  String get className => 'symbolDef';

  @override
  Object clone() {
    final copy = SymbolDef();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void reset() {
    super.reset();
    _originalParent = null;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    return classId == ClassId.graphic ||
        classId == ClassId.svg ||
        classId == ClassId.symbol;
  }

  // TODO(model): GetSymbolWidth/GetSymbolHeight/GetSymbolSize arrive with
  // the Doc (drawing unit) and SVG content parsing in the rendering phase.

  /// Set a temporary parent for the symbolDef (mirrors `SetTemporaryParent`).
  ///
  /// The ownership is not changed: the object stays in the children of its
  /// original parent; [resetTemporaryParent] must be called to restore.
  void setTemporaryParent(Object parent) {
    assert(this.parent != null && _originalParent == null);
    _originalParent = this.parent;
    resetParent();
    setParent(parent);
  }

  /// Restore the original parent after a temporary parenting operation
  /// (mirrors `ResetTemporaryParent`).
  void resetTemporaryParent() {
    assert(parent != null && _originalParent != null);
    resetParent();
    setParent(_originalParent!);
    _originalParent = null;
  }
}

/// Mirrors `vrv::SymbolTable`.
class SymbolTable extends Object {
  SymbolTable() : super(ClassId.symbolTable) {
    reset();
  }

  @override
  String get className => 'symbolTable';

  @override
  Object clone() {
    final copy = SymbolTable();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    return classId == ClassId.symbolDef;
  }
}

/// Mirrors `vrv::Text`.
class Text extends TextElement {
  Text() : super(ClassId.text) {
    reset();
  }

  /// The text content (mirrors `m_text`); stored as a Dart String (UTF-16).
  String text = '';

  /// Flag indicating whether the text was generated (mirrors
  /// `m_isGenerated`).
  bool isGenerated = false;

  @override
  String get className => 'text';

  @override
  Object clone() {
    final copy = Text();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Text other) {
    super.copyFrom(other);
    text = other.text;
    isGenerated = other.isGenerated;
  }

  @override
  void reset() {
    super.reset();
    text = '';
    isGenerated = false;
  }
}

/// Mirrors `vrv::Tuning`.
class Tuning extends Object with AttTuningLog {
  Tuning() : super(ClassId.tuning) {
    reset();
  }

  @override
  String get className => 'tuning';

  @override
  Object clone() {
    final copy = Tuning();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Tuning other) {
    super.copyFrom(other);
    copyAttTuningLog(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (classId == ClassId.course) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Calculate the position of a course on the staff (mirrors
  /// `CalcPitchPos`).
  int calcPitchPos(
      int course,
      Notationtype notationType,
      int lines,
      int listSize,
      int index,
      int loc,
      int tabLine,
      int tabAnchorline,
      bool topAlign) {
    switch (notationType) {
      case Notationtype.tabLuteFrench:
        // All courses >= 7 are positioned above line 0.
        return (lines - (course < 7 ? course : 7)) * 2 + 1;
      case Notationtype.tabLuteItalian:
        // All courses >= 7 are positioned on line 7.
        return ((course < 7 ? course : 7) - 1) * 2;
      case Notationtype.tabLuteGerman:
        if (tabLine != 0) {
          // Explicit position, 1st priority.
          return (tabLine - 1) * 2;
        } else if (loc != meiUnset) {
          // Explicit position, 2nd priority.
          return loc;
        } else if (tabAnchorline != 0) {
          // Align bottom note to given anchor line, but don't extend chord
          // above the top line, 3rd priority.
          return (min(tabAnchorline - 1, lines - listSize) + index) * 2;
        } else if (topAlign) {
          // Align top note with top line, joint 4th priority (default).
          return (lines - listSize + index) * 2;
        } else {
          // Align bottom note with bottom line, joint 4th priority.
          return index * 2;
        }
      default:
        return (course - lines).abs() * 2;
    }
  }

  /// Calculate the MIDI note number for course/fret (mirrors
  /// `CalcPitchNumber`).
  int calcPitchNumber(int course, int fret, Notationtype notationType) {
    // Use <tuning><course>s if available, else @tuning.standard, else the
    // @notationtype.

    // Do we have the tuning for this course?
    final List<Object> courses = findAllDescendantsByType(ClassId.course);
    Course? courseTuning;
    for (final Object object in courses) {
      final Course candidate = object as Course;
      if (candidate.n == '$course') {
        courseTuning = candidate;
        break;
      }
    }

    if (courseTuning != null && courseTuning.hasPname && courseTuning.hasOct) {
      // Distance in semitones from the octave's starting C to the note.
      int midiBase = 0;
      switch (courseTuning.pname!) {
        case Pitchname.c:
          midiBase = 0;
          break;
        case Pitchname.d:
          midiBase = 2;
          break;
        case Pitchname.e:
          midiBase = 4;
          break;
        case Pitchname.f:
          midiBase = 5;
          break;
        case Pitchname.g:
          midiBase = 7;
          break;
        case Pitchname.a:
          midiBase = 9;
          break;
        case Pitchname.b:
          midiBase = 11;
          break;
        default:
          break;
      }

      final int octave = courseTuning.oct!;

      // As this does not represent historical notation of any kind the only
      // accidentals we should ever see are "s" and "f".
      int alter = 0;
      if (courseTuning.hasAccid) {
        if (courseTuning.accid == AccidentalWritten.s) {
          alter = 1;
        } else if (courseTuning.accid == AccidentalWritten.f) {
          alter = -1;
        }
      }

      // MIDI note C4 = 60.
      return (octave + 1) * 12 + midiBase + alter + fret;
    }

    // No <tuning><course> specified: fall back to @tuning.standard.

    // modern guitar                           E4  B3  G3  D3  A2  E2
    const guitarStandardPitch = [64, 59, 55, 50, 45, 40];
    // modern guitar drop D                 E4  B3  G3  D3  A2  D2
    const guitarDropDPitch = [64, 59, 55, 50, 45, 38];
    // modern guitar open D                 D4  A3  F#3 D3  A2  D2
    const guitarOpenDPitch = [62, 57, 54, 50, 45, 38];
    // modern guitar open G                 D4  B3  G3  D3  G2  D2
    const guitarOpenGPitch = [62, 59, 55, 50, 43, 38];
    // modern guitar open A                 E4  C#4 A3  E3  A2  E2
    const guitarOpenAPitch = [64, 61, 57, 52, 45, 40];
    // 6 course renaissance lute            G4  D4  A3  F3  C3  G2
    const luteRenaissance6Pitch = [67, 62, 57, 53, 48, 43];
    // baroque lute D major                 F#4 D4  A3  F#3 D3  A2  G2  F#2 E2  D2  C#2 B1  A1
    const luteBaroqueDMajor = [
      66,
      62,
      57,
      54,
      50,
      45,
      43,
      42,
      40,
      38,
      37,
      35,
      33
    ];
    // baroque lute D minor                 F4  D4  A3  F3  D3  A2  G2  F2  E2  D2  C2  B1  A1
    const luteBaroqueDMinor = [
      65,
      62,
      57,
      53,
      50,
      45,
      43,
      41,
      40,
      38,
      36,
      35,
      33
    ];

    List<int> pitch;

    switch (tuningStandard) {
      case Coursetuning.guitarStandard:
        pitch = guitarStandardPitch;
        break;
      case Coursetuning.guitarDropD:
        pitch = guitarDropDPitch;
        break;
      case Coursetuning.guitarOpenD:
        pitch = guitarOpenDPitch;
        break;
      case Coursetuning.guitarOpenG:
        pitch = guitarOpenGPitch;
        break;
      case Coursetuning.guitarOpenA:
        pitch = guitarOpenAPitch;
        break;
      case Coursetuning.luteRenaissance6:
        pitch = luteRenaissance6Pitch;
        break;
      case Coursetuning.luteBaroqueDMajor:
        pitch = luteBaroqueDMajor;
        break;
      case Coursetuning.luteBaroqueDMinor:
        pitch = luteBaroqueDMinor;
        break;
      default:
        // @tuning.standard is not specified: use @notationtype.
        if (notationType == Notationtype.tabLuteFrench ||
            notationType == Notationtype.tabLuteItalian ||
            notationType == Notationtype.tabLuteGerman) {
          // Lute tablature: assume 6 course renaissance lute.
          pitch = luteRenaissance6Pitch;
        } else {
          // Assume modern guitar.
          pitch = guitarStandardPitch;
        }
        break;
    }

    return (course > 0 && course <= pitch.length)
        ? pitch[course - 1] + fret
        : 0;
  }
}

/// Mirrors `vrv::Fb`: the container of a figured-bass span.
class Fb extends Object {
  Fb() : super(ClassId.fb) {
    reset();
  }

  @override
  String get className => 'fb';

  @override
  Object clone() {
    final copy = Fb();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (classId == ClassId.f) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::F`: a figured-bass figure.
class F extends TextElement
    with
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttExtender,
        TimePointInterface,
        TimeSpanningInterface {
  F() : super(ClassId.f) {
    registerInterfaces([
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  @override
  String get className => 'f';

  @override
  Object clone() {
    final copy = F();
    copy.copyFrom(this);
    return copy;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}
