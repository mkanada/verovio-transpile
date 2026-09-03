// Originalmente gerado por tool/gen_elements.py; MANTIDO À MÃO desde 2026-08-26.
// Element leaf classes mirroring the C++ element headers; edit by hand (the
// generator was retired — see prompts/reports/04i.md).

import 'package:verovio_dart/src/model/atts/atts_analytical.dart';
import 'package:verovio_dart/src/model/atts/atts_cmn.dart';
import 'package:verovio_dart/src/model/atts/atts_externalsymbols.dart';
import 'package:verovio_dart/src/model/atts/atts_gestural.dart';
import 'package:verovio_dart/src/model/atts/atts_mensural.dart';
import 'package:verovio_dart/src/model/atts/atts_neumes.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/atts_stringtab.dart';
import 'package:verovio_dart/src/model/atts/atts_visual.dart';
import 'package:verovio_dart/src/core/fraction.dart';
import 'package:verovio_dart/src/core/logging.dart';
import 'package:verovio_dart/src/core/smufl.dart'
    show
        smuflE220Tremolo1,
        smuflE260AccidentalFlat,
        smuflE261AccidentalNatural,
        smuflE262AccidentalSharp,
        smuflE263AccidentalDoubleSharp,
        smuflE264AccidentalDoubleFlat,
        smuflE265AccidentalTripleSharp,
        smuflE266AccidentalTripleFlat,
        smuflE267AccidentalNaturalFlat,
        smuflE268AccidentalNaturalSharp,
        smuflE269AccidentalSharpSharp,
        smuflE270AccidentalQuarterToneFlatArrowUp,
        smuflE271AccidentalThreeQuarterTonesFlatArrowDown,
        smuflE272AccidentalQuarterToneSharpNaturalArrowUp,
        smuflE273AccidentalQuarterToneFlatNaturalArrowDown,
        smuflE274AccidentalThreeQuarterTonesSharpArrowUp,
        smuflE275AccidentalQuarterToneSharpArrowDown,
        smuflE280AccidentalQuarterToneFlatStein,
        smuflE281AccidentalThreeQuarterTonesFlatZimmermann,
        smuflE282AccidentalQuarterToneSharpStein,
        smuflE283AccidentalThreeQuarterTonesSharpStein,
        smuflE440AccidentalBuyukMucennebFlat,
        smuflE441AccidentalKucukMucennebFlat,
        smuflE442AccidentalBakiyeFlat,
        smuflE443AccidentalKomaFlat,
        smuflE444AccidentalKomaSharp,
        smuflE445AccidentalBakiyeSharp,
        smuflE446AccidentalKucukMucennebSharp,
        smuflE447AccidentalBuyukMucennebSharp,
        smuflE460AccidentalKoron,
        smuflE461AccidentalSori;
import 'package:verovio_dart/src/core/attdef.dart'
    show meiUnset, MeiDuration, MeterCountSign;
import 'package:verovio_dart/src/core/devicecontextbase.dart' show FontInfo;
import 'package:verovio_dart/src/model/atts/mei_enums.dart';
import 'package:verovio_dart/src/model/atts/mei_values.dart'
    show KeySignature, MeterCountPair;
import 'package:verovio_dart/src/model/doc.dart' show Doc;
import 'package:verovio_dart/src/model/comparison.dart'
    show InterfaceComparison;
import 'package:verovio_dart/src/model/interfaces/duration_interface.dart';
import 'package:verovio_dart/src/model/interfaces/facsimile_interface.dart';
import 'package:verovio_dart/src/model/interfaces/pitch_interface.dart';
import 'package:verovio_dart/src/model/interfaces/position_interface.dart';
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/drawing_interfaces.dart';
import 'package:verovio_dart/src/model/beam_segment.dart';
import 'package:verovio_dart/src/model/basic_elements.dart'
    show Clef, Layer, Note, Staff;
import 'package:verovio_dart/src/model/misc_elements_gen.dart' show Text;
import 'package:verovio_dart/src/model/layer_element.dart';
import 'package:verovio_dart/src/model/object.dart';
import 'package:verovio_dart/src/model/zone.dart' show Zone;
import 'package:verovio_dart/src/core/vrvdef.dart';
import 'package:verovio_dart/src/layout/floating_positioner.dart'
    show FloatingCurvePositioner;
import 'package:verovio_dart/src/core/point.dart';

/// Mirrors `vrv::Accid`.
class Accid extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttStaffLoc,
        AttStaffLocPitched,
        AttAccidental,
        AttAccidentalGes,
        AttAccidLog,
        AttColor,
        AttEnclosingChars,
        AttExtSymAuth,
        AttExtSymNames,
        AttPlacementOnStaff,
        AttPlacementRelEvent,
        OffsetInterface,
        PositionInterface {
  Accid() : super(ClassId.accid) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.position,
    ]);
    reset();
  }

  /// Whether the accidental is aligned with an element from the same layer
  /// (set by `AdjustAccidXFunctor`; mirrors `m_alignedWithSameLayer`).
  bool alignedWithSameLayer = false;

  /// Mirrors `IsAlignedWithSameLayer(bool)` / `IsAlignedWithSameLayer()`.
  bool isAlignedWithSameLayer() => alignedWithSameLayer;
  void setAlignedWithSameLayer(bool value) => alignedWithSameLayer = value;

  /// The other accidental this one is drawn on top of because they are
  /// unison duplicates (set by `AdjustAccidXFunctor`; mirrors
  /// `m_drawingUnison`).
  Accid? drawingUnisonAccid;

  /// Mirrors `SetDrawingUnisonAccid` / `GetDrawingUnisonAccid`.
  void setDrawingUnisonAccid(Accid? accid) => drawingUnisonAccid = accid;
  Accid? getDrawingUnisonAccid() => drawingUnisonAccid;

  /// Return the SMuFL glyph for an accidental (mirrors the static
  /// `Accid::GetAccidGlyph`).
  static int getAccidGlyph(AccidentalWritten accid) {
    switch (accid) {
      case AccidentalWritten.s:
        return smuflE262AccidentalSharp;
      case AccidentalWritten.f:
        return smuflE260AccidentalFlat;
      case AccidentalWritten.ss:
        return smuflE269AccidentalSharpSharp;
      case AccidentalWritten.x:
        return smuflE263AccidentalDoubleSharp;
      case AccidentalWritten.ff:
        return smuflE264AccidentalDoubleFlat;
      case AccidentalWritten.sx: // Missing in SMuFL.
      case AccidentalWritten.xs:
      case AccidentalWritten.ts:
        return smuflE265AccidentalTripleSharp;
      case AccidentalWritten.tf:
        return smuflE266AccidentalTripleFlat;
      case AccidentalWritten.n:
        return smuflE261AccidentalNatural;
      case AccidentalWritten.nf:
        return smuflE267AccidentalNaturalFlat;
      case AccidentalWritten.ns:
        return smuflE268AccidentalNaturalSharp;
      case AccidentalWritten.su:
        return smuflE274AccidentalThreeQuarterTonesSharpArrowUp;
      case AccidentalWritten.sd:
        return smuflE275AccidentalQuarterToneSharpArrowDown;
      case AccidentalWritten.fu:
        return smuflE270AccidentalQuarterToneFlatArrowUp;
      case AccidentalWritten.fd:
        return smuflE271AccidentalThreeQuarterTonesFlatArrowDown;
      case AccidentalWritten.nu:
        return smuflE272AccidentalQuarterToneSharpNaturalArrowUp;
      case AccidentalWritten.nd:
        return smuflE273AccidentalQuarterToneFlatNaturalArrowDown;
      case AccidentalWritten.n1qf:
        return smuflE280AccidentalQuarterToneFlatStein;
      case AccidentalWritten.n3qf:
        return smuflE281AccidentalThreeQuarterTonesFlatZimmermann;
      case AccidentalWritten.n1qs:
        return smuflE282AccidentalQuarterToneSharpStein;
      case AccidentalWritten.n3qs:
        return smuflE283AccidentalThreeQuarterTonesSharpStein;
      case AccidentalWritten.bms:
        return smuflE447AccidentalBuyukMucennebSharp;
      case AccidentalWritten.kms:
        return smuflE446AccidentalKucukMucennebSharp;
      case AccidentalWritten.bs:
        return smuflE445AccidentalBakiyeSharp;
      case AccidentalWritten.ks:
        return smuflE444AccidentalKomaSharp;
      case AccidentalWritten.kf:
        return smuflE443AccidentalKomaFlat;
      case AccidentalWritten.bf:
        return smuflE442AccidentalBakiyeFlat;
      case AccidentalWritten.kmf:
        return smuflE441AccidentalKucukMucennebFlat;
      case AccidentalWritten.bmf:
        return smuflE440AccidentalBuyukMucennebFlat;
      case AccidentalWritten.koron:
        return smuflE460AccidentalKoron;
      case AccidentalWritten.sori:
        return smuflE461AccidentalSori;
      default:
        break;
    }
    return 0;
  }

  @override
  String get className => 'accid';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Accid();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Accid other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyPositionFrom(other);
    copyAttAccidental(other);
    copyAttAccidentalGes(other);
    copyAttAccidLog(other);
    copyAttColor(other);
    copyAttEnclosingChars(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttPlacementOnStaff(other);
    copyAttPlacementRelEvent(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }
}

/// Mirrors `vrv::Artic`.
class Artic extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttArticulation,
        AttArticulationGes,
        AttColor,
        AttEnclosingChars,
        AttExtSymAuth,
        AttExtSymNames,
        AttPlacementRelEvent,
        OffsetInterface {
  Artic() : super(ClassId.artic) {
    registerInterfaces([
      InterfaceId.offset,
    ]);
    reset();
  }

  /// The drawing place of the articulation (set by the artic calculation;
  /// mirrors `m_drawingPlace`).
  Staffrel drawingPlace = Staffrel.none;

  /// The slur curve positioners starting / ending on this artic's note or
  /// chord that `AdjustArticWithSlursFunctor` shifts the artic away from
  /// (mirrors `m_startSlurPositioners` / `m_endSlurPositioners`).
  ///
  /// Deviation: populated by `Slur::AddPositionerToArticulations`
  /// (`slur.cpp`), which is not ported (out of scope for task 04b — no
  /// corpus file exercised here has a slur); the lists therefore stay
  /// always empty until a slur-focused task wires them.
  final List<FloatingCurvePositioner> startSlurPositioners = [];
  final List<FloatingCurvePositioner> endSlurPositioners = [];

  /// Mirrors `Artic::AddSlurPositioner`.
  void addSlurPositioner(FloatingCurvePositioner positioner, bool start) {
    final List<FloatingCurvePositioner> list =
        start ? startSlurPositioners : endSlurPositioners;
    if (!list.contains(positioner)) list.add(positioner);
  }

  /// Mirrors the static `Artic::s_outStaffArtic` table.
  static const Set<Articulation> _outStaffArtic = {
    Articulation.acc,
    Articulation.accSoft,
    Articulation.dnbow,
    Articulation.marc,
    Articulation.upbow,
    Articulation.harm,
    Articulation.snap,
    Articulation.fingernail,
    Articulation.damp,
    Articulation.dampall,
    Articulation.lhpizz,
    Articulation.open,
    Articulation.stop,
  };

  /// Mirrors `Artic::IsInsideArtic(data_ARTICULATION)`.
  bool isInsideArticOf(Articulation? artic) {
    // Always outside if enclosing brackets are used.
    if (enclose == Enclosure.brack || enclose == Enclosure.paren) {
      return false;
    }
    return !_outStaffArtic.contains(artic);
  }

  /// Mirrors `Artic::IsInsideArtic()`.
  bool isInsideArtic() => isInsideArticOf(getArticFirst());

  /// Mirrors `Artic::IsOutsideArtic()` (artic.h:68) — `!IsInsideArtic()`.
  bool isOutsideArtic() => !isInsideArtic();

  /// Mirrors the static `Artic::s_aboveStaffArtic` table (artic.cpp:34).
  static const Set<Articulation> _aboveStaffArtic = {
    Articulation.dnbow,
    Articulation.marc,
    Articulation.upbow,
    Articulation.harm,
    Articulation.snap,
    Articulation.fingernail,
    Articulation.damp,
    Articulation.dampall,
    Articulation.lhpizz,
    Articulation.open,
    Articulation.stop,
  };

  /// Mirrors `Artic::AlwaysAbove` (artic.cpp:130).
  bool alwaysAbove() => _aboveStaffArtic.contains(getArticFirst());

  /// Mirrors `Artic::GetArticFirst`.
  Articulation? getArticFirst() {
    if (!hasArtic || artic == null || artic!.isEmpty) return null;
    return artic!.first;
  }

  /// Mirrors `Artic::GetAllArtics` (artic.cpp:109): collects the sibling
  /// articulations of the same note/chord with the same drawing place,
  /// either forward from this artic ([forward] true, mirrors
  /// `direction == FORWARD`) or backward from it ([forward] false).
  ///
  /// Deviation: the C++ takes [artics] as an out-parameter
  /// (`std::vector<Artic *> &`); Dart returns the list instead. The C++
  /// asserts the parent note/chord indirectly (`GetFirst()`/`GetLast()` on
  /// the resolved parent); here a detached artic (no note/chord ancestor)
  /// returns an empty list. The range walk (`FindAllBetweenFunctor`) is
  /// inlined: descendants of the parent matching ARTIC between [first] and
  /// [last] inclusive, minus this artic itself (mirrors
  /// `FindAllDescendantsBetween(&children, &matchType, first, last)` plus
  /// the `if (child == this) continue` skip).
  List<Artic> getAllArtics(bool forward) {
    final Object? parentNoteOrChord = getFirstAncestor(ClassId.chord) ??
        getFirstAncestor(ClassId.note, maxChordDepth);
    if (parentNoteOrChord == null) return <Artic>[];
    final Object? first =
        forward ? this : parentNoteOrChord.getFirst();
    final Object? last =
        forward ? parentNoteOrChord.getLast() : this;
    if (first == null || last == null) return <Artic>[];
    // Inclusive range walk in document order (mirrors
    // `FindAllBetweenFunctor::VisitObject`: set the flag at `first`,
    // collect matches, stop at `last`).
    final List<Artic> artics = [];
    bool inRange = false;
    bool stop = false;
    void visit(Object node) {
      if (stop) return;
      if (identical(node, first)) inRange = true;
      if (inRange &&
          node.classId == ClassId.artic &&
          !identical(node, this)) {
        final Artic artic = node as Artic;
        if (artic.drawingPlace == drawingPlace) artics.add(artic);
      }
      if (identical(node, last)) stop = true;
    }
    void walk(Object node) {
      if (stop) return;
      for (final Object child in node.children) {
        if (stop) return;
        visit(child);
        walk(child);
      }
    }
    visit(parentNoteOrChord);
    walk(parentNoteOrChord);
    return artics;
  }

  /// Mirrors `Artic::GetArticGlyph` (artic.cpp:151): resolves the SMuFL code
  /// for [artic] at [place], honoring the `@glyph.num` / `@glyph.name`
  /// overrides first.
  ///
  /// Deviation: the C++ returns `char32_t` (0 when unknown); Dart returns
  /// `int` with the same 0 fallback. The glyph table lookup goes through
  /// [getDocResources] (null when detached from a Doc, also 0).
  int getArticGlyph(Articulation? artic, Staffrel place) {
    final dynamic resources = getDocResources();
    if (resources == null) return 0;
    if (hasGlyphNum) {
      final int code = glyphNum!;
      if (resources.getGlyphByCode(code) != null) return code;
    } else if (hasGlyphName) {
      final int code = resources.getGlyphCode(glyphName!);
      if (resources.getGlyphByCode(code) != null) return code;
    }
    if (place == Staffrel.above) {
      switch (artic) {
        case Articulation.acc:
          return 0xE4A0; // SMUFL_E4A0_articAccentAbove
        case Articulation.accSoft:
          return 0xED40; // SMUFL_ED40_articSoftAccentAbove
        case Articulation.stacc:
          return 0xE4A2; // SMUFL_E4A2_articStaccatoAbove
        case Articulation.ten:
          return 0xE4A4; // SMUFL_E4A4_articTenutoAbove
        case Articulation.stacciss:
          return 0xE4A8; // SMUFL_E4A8_articStaccatissimoWedgeAbove
        case Articulation.marc:
          return 0xE4AC; // SMUFL_E4AC_articMarcatoAbove
        case Articulation.spicc:
          return 0xE4A6; // SMUFL_E4A6_articStaccatissimoAbove
        case Articulation.dnbow:
          return 0xE610; // SMUFL_E610_stringsDownBow
        case Articulation.upbow:
          return 0xE612; // SMUFL_E612_stringsUpBow
        case Articulation.harm:
          return 0xE614; // SMUFL_E614_stringsHarmonic
        case Articulation.snap:
          return 0xE631; // SMUFL_E631_pluckedSnapPizzicatoAbove
        case Articulation.fingernail:
          return 0xE636; // SMUFL_E636_pluckedWithFingernails
        case Articulation.damp:
          return 0xE638; // SMUFL_E638_pluckedDamp
        case Articulation.dampall:
          return 0xE639; // SMUFL_E639_pluckedDampAll
        case Articulation.open:
          return 0xE5E7; // SMUFL_E5E7_brassMuteOpen
        case Articulation.stop:
          return 0xE5E5; // SMUFL_E5E5_brassMuteClosed
        case Articulation.lhpizz:
          return 0xE633; // SMUFL_E633_pluckedLeftHandPizzicato
        case Articulation.dot:
          return 0xE4A2; // SMUFL_E4A2_articStaccatoAbove
        case Articulation.stroke:
          return 0xE4AA; // SMUFL_E4AA_articStaccatissimoStrokeAbove
        default:
          return 0;
      }
    } else if (place == Staffrel.below) {
      switch (artic) {
        case Articulation.acc:
          return 0xE4A1; // SMUFL_E4A1_articAccentBelow
        case Articulation.accSoft:
          return 0xED41; // SMUFL_ED41_articSoftAccentBelow
        case Articulation.stacc:
          return 0xE4A3; // SMUFL_E4A3_articStaccatoBelow
        case Articulation.ten:
          return 0xE4A5; // SMUFL_E4A5_articTenutoBelow
        case Articulation.stacciss:
          return 0xE4A9; // SMUFL_E4A9_articStaccatissimoWedgeBelow
        case Articulation.marc:
          return 0xE4AD; // SMUFL_E4AD_articMarcatoBelow
        case Articulation.spicc:
          return 0xE4A7; // SMUFL_E4A7_articStaccatissimoBelow
        case Articulation.dnbow:
          return 0xE611; // SMUFL_E611_stringsDownBowTurned
        case Articulation.upbow:
          return 0xE613; // SMUFL_E613_stringsUpBowTurned
        case Articulation.harm:
          return 0xE614; // SMUFL_E614_stringsHarmonic
        case Articulation.snap:
          return 0xE630; // SMUFL_E630_pluckedSnapPizzicatoBelow
        case Articulation.fingernail:
          return 0xE636; // SMUFL_E636_pluckedWithFingernails
        case Articulation.damp:
          return 0xE638; // SMUFL_E638_pluckedDamp
        case Articulation.dampall:
          return 0xE639; // SMUFL_E639_pluckedDampAll
        case Articulation.open:
          return 0xE5E7; // SMUFL_E5E7_brassMuteOpen
        case Articulation.stop:
          return 0xE5E5; // SMUFL_E5E5_brassMuteClosed
        case Articulation.lhpizz:
          return 0xE633; // SMUFL_E633_pluckedLeftHandPizzicato
        case Articulation.dot:
          return 0xE4A3; // SMUFL_E4A3_articStaccatoBelow
        case Articulation.stroke:
          return 0xE4AB; // SMUFL_E4AB_articStaccatissimoStrokeBelow
        default:
          return 0;
      }
    }
    return 0;
  }

  @override
  String get className => 'artic';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Artic();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Artic other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyAttArticulation(other);
    copyAttArticulationGes(other);
    copyAttColor(other);
    copyAttEnclosingChars(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttPlacementRelEvent(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    drawingPlace = other.drawingPlace;
  }
}

/// Mirrors `vrv::Beam`.
class Beam extends LayerElement
    with
        AttBeamedWith,
        AttBeamRend,
        AttColor,
        AttCue,
        BeamDrawingInterface,
        ObjectListInterface {
  Beam() : super(ClassId.beam) {
    reset();
  }

  /// The other beam sharing stems with this one (mirrors
  /// `m_stemSameasBeam`).
  Object? stemSameasBeam;

  /// Mirrors `SetStemSameasBeam` / `HasStemSameasBeam`.
  void setStemSameasBeam(Object? beam) => stemSameasBeam = beam;
  bool hasStemSameasBeam() => stemSameasBeam != null;

  @override
  String get className => 'beam';

  @override
  Object clone() {
    final copy = Beam();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Beam other) {
    super.copyFrom(other);
    copyAttBeamedWith(other);
    copyAttBeamRend(other);
    copyAttColor(other);
    copyAttCue(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.beam,
      ClassId.bTrem,
      ClassId.chord,
      ClassId.clef,
      ClassId.fTrem,
      ClassId.graceGrp,
      ClassId.note,
      ClassId.rest,
      ClassId.space,
      ClassId.tabGrp,
      ClassId.tuplet,
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  @override
  void filterList(List<Object> childList) {
    bool firstNoteGrace = false;
    // We want to keep only notes and rests.
    // Eventually, we also need to filter out grace notes properly (e.g.,
    // with sub-beams).
    final bool isTab = isTabBeam();

    // Deviation: `List.removeWhere` cannot express `Beam::FilterList`
    // (beam.cpp:1650) faithfully here. The C++ re-evaluates
    // `childList.begin() == iter` on every loop pass, so "the first element"
    // is whichever survives to the else-branch first — not literally the
    // list's original head, which for a beam is the (duration-interface-less)
    // beam itself and never re-appears once erased. A closure capturing
    // `childList.first` up front therefore compares every candidate against
    // the beam object and never matches, leaving `firstNoteGrace` stuck at
    // false and dropping every grace note in the beam — including the whole
    // beam from `hasEmptyList()`/`View::DrawBeam` when it holds only grace
    // notes. Porting the index-based loop with `i == 0` standing in for
    // `iter == childList.begin()` (index 0 is only reoccupied by erasure,
    // exactly mirroring the iterator) keeps the semantics exact.
    int i = 0;
    while (i < childList.length) {
      final Object object = childList[i];
      if (!object.isLayerElement) {
        // Remove anything that is not a LayerElement (e.g., Verse, Syl…).
        childList.removeAt(i);
        continue;
      }
      if (!object.hasInterface(InterfaceId.duration)) {
        // Remove anything that has not a DurationInterface.
        childList.removeAt(i);
        continue;
      } else if (isTab) {
        if (object.classId != ClassId.tabGrp) {
          childList.removeAt(i);
          continue;
        }
        i++;
        continue;
      } else {
        final LayerElement element = object as LayerElement;
        // If we are at the beginning of the beam and the note is cueSize,
        // assume all the beam is of grace notes.
        if (i == 0) {
          if (element.isGraceNote()) firstNoteGrace = true;
        }
        // If the first note in beam was NOT a grace, we have grace notes
        // embedded in a beam: drop them.
        if (!firstNoteGrace && element.isGraceNote()) {
          childList.removeAt(i);
          continue;
        }
        // Also remove notes within chords.
        if (element.classId == ClassId.note) {
          if ((element as Note).isChordTone() != null) {
            childList.removeAt(i);
            continue;
          }
        }
        i++;
      }
    }
  }

  /// Return true if the beam contains tabGrp elements (mirrors `IsTabBeam`).
  bool isTabBeam() => findDescendantByType(ClassId.tabGrp) != null;

  /// The beam segment with the drawing parameters of each coord (mirrors
  /// `m_beamSegment`, beam.h:388). Only populated headlessly from task 04d's
  /// tests; `BeamSegment::CalcBeam` is a pending task.
  final BeamSegment beamSegment = BeamSegment();

  /// Return the duration of the beam part that is closest to the specified x
  /// position (mirrors `Beam::GetBeamPartDuration(int, bool)`, beam.cpp:2068).
  ///
  /// Deviation: iterates [BeamSegment.beamElementCoordRefs] for both the
  /// search and the fallbacks — the C++ splits owned coords (`m_beamElementCoords`)
  /// from refs, a distinction without `CalcBeam` (see beam_segment.dart).
  int getBeamPartDuration(int x, [bool includeRests = true]) {
    // find element with position closest to the specified coordinate
    final int index = beamSegment.beamElementCoordRefs.indexWhere(
        (BeamElementCoord coord) =>
            x < coord.x &&
            (coord.element?.classId != ClassId.rest || includeRests));
    // handle cases when coordinate is outside of the beam
    if (index == -1) {
      return MeiDuration.dur8.value;
    } else if (index == 0) {
      return beamSegment.beamElementCoordRefs[index].dur.value;
    }
    // Get previous relevant element (skipping over rests if needed)
    for (int i = index - 1; i >= 0; --i) {
      final BeamElementCoord coord = beamSegment.beamElementCoordRefs[i];
      if (coord.element?.classId != ClassId.rest || includeRests) {
        final int previousDur = coord.dur.value;
        final int currentDur =
            beamSegment.beamElementCoordRefs[index].dur.value;
        return previousDur <= currentDur ? previousDur : currentDur;
      }
    }
    return beamSegment.beamElementCoordRefs[index].dur.value;
  }

  /// Return the duration of the beam part closest to [object]'s x position
  /// (mirrors `Beam::GetBeamPartDuration(const Object *, bool)`,
  /// beam.cpp:2090).
  int getBeamPartDurationOf(Object object, [bool includeRests = true]) {
    return getBeamPartDuration(object.getDrawingX(), includeRests);
  }

  /// Mirrors `Beam::GetElementCoords` (beam.cpp:1709): refreshes the filtered
  /// list (which rebuilds `m_beamElementCoords` via `InitCoords` in the
  /// layout passes) and returns the owned coords.
  ///
  /// Deviation: the C++ returns `const ArrayOfBeamElementCoords *`; Dart
  /// returns the live owned list [BeamDrawingInterface.beamElementCoordsOwned].
  List<BeamElementCoord> getElementCoords() {
    getList();
    return beamElementCoordsOwned;
  }

  /// See `BeamDrawingInterface::GetAdditionalBeamCount`
  /// (mirrors `Beam::GetAdditionalBeamCount`, beam.cpp:2052).
  ///
  /// Returns `(above, below)` as duration deltas from an eighth.
  @override
  (int, int) getAdditionalBeamCount() {
    MeiDuration topShortestDur = MeiDuration.dur8;
    MeiDuration bottomShortestDur = MeiDuration.dur8;
    for (final BeamElementCoord coord in beamSegment.beamElementCoordRefs) {
      if (coord.partialFlagPlace == Beamplace.above) {
        topShortestDur = MeiDuration.max(topShortestDur, coord.dur);
      } else if (coord.partialFlagPlace == Beamplace.below) {
        bottomShortestDur = MeiDuration.max(bottomShortestDur, coord.dur);
      }
    }
    return (
      topShortestDur.value - MeiDuration.dur8.value,
      bottomShortestDur.value - MeiDuration.dur8.value,
    );
  }
}

/// Mirrors `vrv::BeatRpt`.
class BeatRpt extends LayerElement with AttColor, AttBeatRptLog, AttBeatRptVis {
  BeatRpt() : super(ClassId.beatRpt) {
    reset();
  }

  /// The score-time onset of the beat repeat in the measure, set by the MIDI
  /// functors (mirrors `m_scoreTimeOnset` / `SetScoreTimeOnset`).
  Fraction scoreTimeOnset = Fraction(0);

  /// Mirrors `SetScoreTimeOnset`.
  void setScoreTimeOnset(Fraction scoreTime) => scoreTimeOnset = scoreTime;

  @override
  String get className => 'beatRpt';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = BeatRpt();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant BeatRpt other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttBeatRptLog(other);
    copyAttBeatRptVis(other);
  }
}

/// Mirrors `vrv::BTrem`.
class BTrem extends LayerElement
    with AttNumbered, AttNumberPlacement, AttTremForm, AttTremMeasured {
  BTrem() : super(ClassId.bTrem) {
    reset();
  }

  @override
  String get className => 'bTrem';

  /// Mirrors `BTrem::GetDrawingStemMod` (btrem.cpp:126): the note/chord's own
  /// `@stem.mod` wins if set, otherwise the slash count is derived from
  /// `@unitdur` vs. the child's actual duration.
  Stemmodifier getDrawingStemMod() {
    Object? child = findDescendantByType(ClassId.chord);
    child ??= findDescendantByType(ClassId.note);
    if (child == null) return Stemmodifier.none;

    Stemmodifier? stemMod;
    MeiDuration? drawingDur;
    if (child is Chord) {
      stemMod = child.stemMod;
      drawingDur = child.getActualDur();
    } else if (child is Note) {
      stemMod = child.stemMod;
      drawingDur = child.getActualDur();
    }
    if (stemMod != null && stemMod != Stemmodifier.none) return stemMod;

    drawingDur ??= MeiDuration.dur4;
    if (!hasUnitdur) {
      if (drawingDur.value < MeiDuration.dur2.value) return Stemmodifier.n3slash;
      return Stemmodifier.none;
    }
    int slashDur = unitdur!.value - drawingDur.value;
    if (drawingDur.value < MeiDuration.dur4.value) {
      slashDur = unitdur!.value - MeiDuration.dur4.value;
    }
    switch (slashDur) {
      case 1:
        return Stemmodifier.n1slash;
      case 2:
        return Stemmodifier.n2slash;
      case 3:
        return Stemmodifier.n3slash;
      case 4:
        return Stemmodifier.n4slash;
      case 5:
        return Stemmodifier.n5slash;
      case 6:
        return Stemmodifier.n6slash;
      default:
        return Stemmodifier.none;
    }
  }

  @override
  Object clone() {
    final copy = BTrem();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant BTrem other) {
    super.copyFrom(other);
    copyAttNumbered(other);
    copyAttNumberPlacement(other);
    copyAttTremForm(other);
    copyAttTremMeasured(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors BTrem::IsSupportedChild.
    const supported = {ClassId.chord, ClassId.clef, ClassId.note};
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Chord`.
class Chord extends LayerElement
    with
        AttAugmentDots,
        AttBeamSecondary,
        AttDurationGes,
        AttDurationLog,
        AttDurationQuality,
        AttDurationRatio,
        AttFermataPresent,
        AttStaffIdent,
        AttArticulation,
        AttChordVis,
        AttColor,
        AttCue,
        AttGraced,
        AttStems,
        AttStemsCmn,
        AttTiePresent,
        AttVisibility,
        ObjectListInterface,
        DrawingListInterface,
        StemmedDrawingInterface,
        DurationInterface {
  Chord() : super(ClassId.chord) {
    registerInterfaces([
      InterfaceId.duration,
    ]);
    reset();
  }

  @override
  String get className => 'chord';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Chord();
    copy.copyFrom(this);
    return copy;
  }

  /// Mirrors `Chord::Reset` (chord.cpp:101): clears the note groups along
  /// with the attribute state (the attribute resets live on the mixins and
  /// the superclass chain).
  @override
  void reset() {
    super.reset();
    clearNoteGroups();
  }

  @override
  void copyFrom(covariant Chord other) {
    super.copyFrom(other);
    copyDurationFrom(other);
    copyAttChordVis(other);
    copyAttColor(other);
    copyAttCue(other);
    copyAttGraced(other);
    copyAttStems(other);
    copyAttStemsCmn(other);
    copyAttTiePresent(other);
    copyAttVisibility(other);
    copyAttAugmentDots(other);
    copyAttBeamSecondary(other);
    copyAttDurationGes(other);
    copyAttDurationLog(other);
    copyAttDurationQuality(other);
    copyAttDurationRatio(other);
    copyAttFermataPresent(other);
    copyAttStaffIdent(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.artic,
      ClassId.dots,
      ClassId.note,
      ClassId.stem,
      ClassId.verse,
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Overwritten method for chord (mirrors `Chord::AddChild`).
  @override
  bool addChild(Object child) {
    if (!isSupportedChild(child.classId) || !addChildAdditionalCheck(child)) {
      logError("Adding '${child.className}' to a '$className'");
      return false;
    }

    final List<Object> children = childrenForModification;

    child.setParent(this);
    // Stems are always added by PrepareLayerElementParts (for now) and we
    // want them to be in the front for the drawing order in the SVG output.
    if (child.classId == ClassId.dots || child.classId == ClassId.stem) {
      children.insert(0, child);
    } else {
      children.add(child);
    }
    modify();

    return true;
  }

  @override
  void filterList(List<Object> childList) {
    // Retain only note children of chords, sorted by diatonic pitch.
    childList.removeWhere((Object object) => object.classId != ClassId.note);
    childList.sort((Object first, Object second) => (first as Note)
        .getDiatonicPitch()
        .compareTo((second as Note).getDiatonicPitch()));
  }

  /// Return the position of the note in the chord: 0 for the middle note,
  /// -1 below and 1 above (mirrors `PositionInChord`).
  int positionInChord(Note note) {
    final int size = getListSize();
    final int position = getListIndex(note);
    assert(position != -1);
    // This is the middle (only if odd).
    if ((size.isOdd) && (position == (size - 1) ~/ 2)) return 0;
    if (position < size ~/ 2) return -1;
    return 1;
  }

  /// Mirrors `Chord::GetAdjacentNotesList` (chord.cpp:511): the chord notes
  /// on [staff] one diatonic step or a third away from [loc] (exclusive).
  ///
  /// No active in-tree caller yet — the C++ caller is `Tie::CalculateTies`
  /// (tie.cpp:293,329), which arrives in a later phase; the method is kept
  /// ready here for parity.
  List<Note> getAdjacentNotesList(Staff staff, int loc) {
    final List<Object> notes = getList();

    final List<Note> adjacentNotes = [];
    for (final Object obj in notes) {
      final Note note = obj as Note;

      final Staff? noteStaff = note.crossStaff ??
          note.getFirstAncestor(ClassId.staff) as Staff?;
      if (!identical(noteStaff, staff)) continue;

      final int locDiff = note.drawingLoc - loc;
      if ((locDiff.abs() <= 2) && (locDiff != 0)) {
        adjacentNotes.add(note);
      }
    }
    return adjacentNotes;
  }

  /// Return the maximum and minimum Y positions of the notes in the chord
  /// (mirrors `GetYExtremes`).
  (int, int) getYExtremes() {
    // The first note is the bottom, the last one the top.
    return (getListBack()!.getDrawingY(), getListFront()!.getDrawingY());
  }

  /// Return the top note of the chord (the last one in the list).
  Note? getTopNote() => getListBack() as Note?;

  /// Return the bottom note of the chord (the first one in the list).
  Note? getBottomNote() => getListFront() as Note?;

  /// The list of chord note groups (mirrors the mutable
  /// `m_noteGroups` in chord.h:224, a `std::list<ChordNoteGroup *>` where
  /// `ChordNoteGroup` is `std::vector<Note *>` — vrvdef.h:362).
  ///
  /// Deviation: Dart owns the groups in a growable list; the C++ deletes
  /// them in `ClearNoteGroups`. Groups and the back-links on [Note] are
  /// rebuilt by [calculateNoteGroups] and cleared by [clearNoteGroups].
  final List<List<Note>> noteGroups = <List<Note>>[];

  /// Mirrors `Chord::ClearNoteGroups` (chord.cpp:119): resets every grouped
  /// note's back-link (`SetNoteGroup(NULL, 0)`) and empties [noteGroups].
  void clearNoteGroups() {
    for (final List<Note> group in noteGroups) {
      for (final Note note in group) {
        note.setNoteGroup(null, 0);
      }
    }
    noteGroups.clear();
  }

  /// Mirrors `Chord::CalculateNoteGroups` (chord.cpp:131): groups notes a
  /// diatonic second (or less) apart that share the same cross-staff into
  /// runs along the pitch-sorted child list.
  ///
  /// Deviation: the C++ asserts non-empty children and non-null notes
  /// (`assert(lastNote)` / `assert(curNote)`); a chord with no note
  /// children simply leaves [noteGroups] empty here.
  void calculateNoteGroups() {
    clearNoteGroups();

    final List<Object> childList = getList();
    if (childList.isEmpty) return;

    Note lastNote = childList.first as Note;
    int lastPitch = lastNote.getDiatonicPitch();
    List<Note>? curGroup;

    for (int i = 1; i < childList.length; ++i) {
      final Note curNote = childList[i] as Note;
      final int curPitch = curNote.getDiatonicPitch();

      final (Staff?, Layer?) curCross = curNote.getCrossStaff();
      final (Staff?, Layer?) lastCross = lastNote.getCrossStaff();
      if ((curPitch - lastPitch < 2) &&
          identical(curCross.$1, lastCross.$1) &&
          identical(curCross.$2, lastCross.$2)) {
        if (lastNote.getNoteGroup() == null) {
          curGroup = <Note>[];
          noteGroups.add(curGroup);
          curGroup.add(lastNote);
          lastNote.setNoteGroup(curGroup, curGroup.length);
        }
        assert(curGroup != null);
        final List<Note> group = curGroup!;
        group.add(curNote);
        curNote.setNoteGroup(group, group.length);
      }

      lastNote = curNote;
      lastPitch = curPitch;
    }
  }

  /// Mirrors `Chord::GetCrossStaffExtremes` (chord.cpp:321): the extreme
  /// staves reached by cross-staff notes of the chord, or nulls when the
  /// chord itself is cross-staffed (no further cross-staffed notes then).
  ///
  /// Deviation: the C++ has mutable/const overloads with `Staff *&` /
  /// `Layer **` out-parameters; Dart returns a record of the four resolved
  /// values instead: `(staffAbove, staffBelow, layerAbove, layerBelow)`.
  /// `staffAbove`/`staffBelow` keep the C++ order (above first).
  (Staff?, Staff?, Layer?, Layer?) getCrossStaffExtremes() {
    Staff? staffAbove;
    Staff? staffBelow;
    Layer? layerAbove;
    Layer? layerBelow;

    // A cross-staff chord cannot have further cross-staffed notes.
    if (crossStaff != null) return (null, null, null, null);

    // The first note is the bottom.
    final Note? bottomNote = getBottomNote();
    assert(bottomNote != null);
    if (bottomNote != null &&
        bottomNote.crossStaff is Staff &&
        bottomNote.crossLayer != null) {
      staffBelow = bottomNote.crossStaff as Staff;
      layerBelow = bottomNote.crossLayer;
    }

    // The last note is the top.
    final Note? topNote = getTopNote();
    assert(topNote != null);
    if (topNote != null &&
        topNote.crossStaff is Staff &&
        topNote.crossLayer != null) {
      staffAbove = topNote.crossStaff as Staff;
      layerAbove = topNote.crossLayer;
    }

    return (staffAbove, staffBelow, layerAbove, layerBelow);
  }

  /// Mirrors `Chord::HasCrossStaff` (chord.cpp:348).
  bool hasCrossStaff() {
    if (crossStaff != null) return true;
    final (Staff?, Staff?, Layer?, Layer?) extremes = getCrossStaffExtremes();
    return extremes.$1 != null || extremes.$2 != null;
  }

  /// Mirrors `Chord::HasNoteWithDots` (chord.cpp:428): true when any note
  /// child carries `@dots > 0`.
  bool hasNoteWithDots() {
    for (final Object object in getList()) {
      final Note note = object as Note;
      if ((note.dots ?? 0) > 0) return true;
    }
    return false;
  }

  int getYTop() => getListBack()!.getDrawingY();

  int getYBottom() => getListFront()!.getDrawingY();

  /// Return the minimum X position of the notes (mirrors `GetXMin`).
  int getXMin() {
    final List<Object> childList = getList();
    assert(childList.isNotEmpty);

    int x = -meiUnset;
    for (final Object child in childList) {
      x = child.getDrawingX() < x ? child.getDrawingX() : x;
    }
    return x;
  }

  /// Return the maximum X position of the notes (mirrors `GetXMax`).
  int getXMax() {
    final List<Object> childList = getList();
    assert(childList.isNotEmpty);

    int x = meiUnset;
    for (final Object child in childList) {
      x = child.getDrawingX() > x ? child.getDrawingX() : x;
    }
    return x;
  }
}

/// Mirrors `vrv::Custos`.
class Custos extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttNoteGes,
        AttOctave,
        AttPitch,
        AttPitchGes,
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        AttExtSymAuth,
        AttExtSymNames,
        OffsetInterface,
        PitchInterface,
        PositionInterface {
  Custos() : super(ClassId.custos) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.pitch,
      InterfaceId.position,
    ]);
    reset();
  }

  @override
  String get className => 'custos';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Custos();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Custos other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyPitchFrom(other);
    copyPositionFrom(other);
    copyAttColor(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttNoteGes(other);
    copyAttOctave(other);
    copyAttPitch(other);
    copyAttPitchGes(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    return false;
  }
}

/// Mirrors `vrv::DivLine`.
class DivLine extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttColor,
        AttDivLineLog,
        AttExtSymAuth,
        AttExtSymNames,
        AttNNumberLike,
        AttVisibility,
        OffsetInterface {
  DivLine() : super(ClassId.divLine) {
    registerInterfaces([
      InterfaceId.offset,
    ]);
    reset();
  }

  @override
  String get className => 'divLine';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = DivLine();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant DivLine other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyAttColor(other);
    copyAttDivLineLog(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttNNumberLike(other);
    copyAttVisibility(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
  }
}

/// Mirrors `vrv::Dot`.
class Dot extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        AttDotLog,
        OffsetInterface,
        PositionInterface {
  Dot() : super(ClassId.dot) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.position,
    ]);
    reset();
  }

  /// The previous / next element pointers used for the dot placement
  /// (set by the layer pointers preparation; mirrors
  /// `m_drawingPreviousElement` / `m_drawingNextElement`).
  Object? drawingPreviousElement;
  Object? drawingNextElement;

  @override
  String get className => 'dot';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Dot();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Dot other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyPositionFrom(other);
    copyAttColor(other);
    copyAttDotLog(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }
}

/// Mirrors `vrv::Dots`.
class Dots extends LayerElement with AttAugmentDots {
  Dots() : super(ClassId.dots) {
    reset();
  }

  /// The map of dot locations per staff (mirrors `m_mapOfDotLocs`):
  /// staff object → set of locs.
  final Map<Object, Set<int>> dotLocs = {};

  /// Whether the dots were already adjusted (mirrors `m_isAdjusted`).
  bool isAdjusted = false;

  /// The shift applied when a flag requires the dots to be moved left
  /// (mirrors `m_flagShift`).
  int flagShift = 0;

  /// Clear the map of dot locations (mirrors `ResetMapOfDotLocs`).
  void resetMapOfDotLocs() => dotLocs.clear();

  /// Set the whole map of dot locations (mirrors `SetMapOfDotLocs`).
  void setMapOfDotLocs(Map<Object, Set<int>> locs) {
    dotLocs
      ..clear()
      ..addAll(locs);
  }

  /// Getter of the map of dot locations (mirrors `GetMapOfDotLocs`).
  Map<Object, Set<int>> getMapOfDotLocs() => dotLocs;

  /// Return the modifiable loc set for [staff], adding it if necessary
  /// (mirrors `ModifyDotLocsForStaff`).
  Set<int> modifyDotLocsForStaff(Object staff) =>
      dotLocs.putIfAbsent(staff, () => <int>{});

  /// Mirrors `IsAdjusted(bool)` / `IsAdjusted()`.
  void setIsAdjusted({bool adjusted = true}) => isAdjusted = adjusted;

  @override
  String get className => 'dots';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Dots();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Dots other) {
    super.copyFrom(other);
    copyAttAugmentDots(other);
    isAdjusted = other.isAdjusted;
    flagShift = other.flagShift;
    setMapOfDotLocs(other.dotLocs);
  }
}

/// Mirrors `vrv::Flag`.
class Flag extends LayerElement {
  Flag() : super(ClassId.flag) {
    reset();
  }

  /// The number of flags to draw (set by the stem calculation; mirrors
  /// `m_drawingNbFlags`).
  int drawingNbFlags = 0;

  /// Return the SE point of the flag when the stem points up (mirrors
  /// `Flag::GetStemUpSE`).
  ///
  /// Deviation: `Doc::GetGlyphTop` needs the SMuFL glyph metrics through
  /// `Doc::GetResources()`, which is not wired on [Doc] in this phase (same
  /// class of gap as `BoundingBox.getCutOutRight`); returns a zero offset
  /// until the resources phase wires it. Unexercised by this task's corpus
  /// (no eighth-or-shorter note has a flag there).
  Point getStemUpSE(dynamic doc, int staffSize, bool graceSize) => Point(0, 0);

  /// Return the NW point of the flag when the stem points down (mirrors
  /// `Flag::GetStemDownNW`); same deviation as [getStemUpSE].
  Point getStemDownNW(dynamic doc, int staffSize, bool graceSize) =>
      Point(0, 0);

  /// Mirrors `Flag::GetFlagGlyph` (elementpart.cpp:84): the SMuFL flag code
  /// for [stemDir] given the current [drawingNbFlags] (0 when unset).
  int getFlagGlyph(Stemdirection stemDir) {
    if (stemDir == Stemdirection.up) {
      switch (drawingNbFlags) {
        case 1:
          return 0xE240; // SMUFL_E240_flag8thUp
        case 2:
          return 0xE242; // SMUFL_E242_flag16thUp
        case 3:
          return 0xE244; // SMUFL_E244_flag32ndUp
        case 4:
          return 0xE246; // SMUFL_E246_flag64thUp
        case 5:
          return 0xE248; // SMUFL_E248_flag128thUp
        case 6:
          return 0xE24A; // SMUFL_E24A_flag256thUp
        case 7:
          return 0xE24C; // SMUFL_E24C_flag512thUp
        case 8:
          return 0xE24E; // SMUFL_E24E_flag1024thUp
        default:
          return 0;
      }
    } else {
      switch (drawingNbFlags) {
        case 1:
          return 0xE241; // SMUFL_E241_flag8thDown
        case 2:
          return 0xE243; // SMUFL_E243_flag16thDown
        case 3:
          return 0xE245; // SMUFL_E245_flag32ndDown
        case 4:
          return 0xE247; // SMUFL_E247_flag64thDown
        case 5:
          return 0xE249; // SMUFL_E249_flag128thDown
        case 6:
          return 0xE24B; // SMUFL_E24B_flag256thDown
        case 7:
          return 0xE24D; // SMUFL_E24D_flag512thDown
        case 8:
          return 0xE24F; // SMUFL_E24F_flag1024thDown
        default:
          return 0;
      }
    }
  }

  @override
  String get className => 'flag';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Flag();
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::TupletBracket`.
class TupletBracket extends LayerElement with AttTupletVis {
  TupletBracket() : super(ClassId.tupletBracket) {
    reset();
  }

  /// The aligned num of the tuplet bracket (set by the layout; mirrors
  /// `m_alignedNum`).
  Object? alignedNum;

  /// The drawing xRel left / right of the bracket (mirrors
  /// `m_drawingXRelLeft` / `m_drawingXRelRight`).
  int drawingXRelLeft = 0;
  int drawingXRelRight = 0;

  /// The drawing yRel left / right of the bracket (mirrors
  /// `m_drawingYRelLeft` / `m_drawingYRelRight`).
  int drawingYRelLeft = 0;
  int drawingYRelRight = 0;

  @override
  String get className => 'tupletBracket';

  @override
  Object clone() {
    final copy = TupletBracket();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant TupletBracket other) {
    super.copyFrom(other);
    copyAttTupletVis(other);
  }
}

/// Mirrors `vrv::TupletNum`.
class TupletNum extends LayerElement with AttNumberPlacement, AttTupletVis {
  TupletNum() : super(ClassId.tupletNum) {
    reset();
  }

  /// The aligned bracket of the tuplet num (set by the layout; mirrors
  /// `m_alignedBracket`).
  Object? alignedBracket;

  @override
  String get className => 'tupletNum';

  @override
  Object clone() {
    final copy = TupletNum();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant TupletNum other) {
    super.copyFrom(other);
    copyAttNumberPlacement(other);
    copyAttTupletVis(other);
  }
}

/// Mirrors `vrv::FTrem`.
class FTrem extends LayerElement
    with AttFTremVis, AttTremMeasured, BeamDrawingInterface, ObjectListInterface {
  FTrem() : super(ClassId.fTrem) {
    reset();
  }

  /// The beam segment with the drawing parameters of each coord (mirrors
  /// `m_beamSegment`, ftrem.h). Only populated headlessly from task 04d's
  /// tests; `BeamSegment::CalcBeam` is a pending task.
  final BeamSegment beamSegment = BeamSegment();

  @override
  String get className => 'fTrem';

  @override
  Object clone() {
    final copy = FTrem();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant FTrem other) {
    super.copyFrom(other);
    copyAttFTremVis(other);
    copyAttTremMeasured(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors FTrem::IsSupportedChild.
    const supported = {
      ClassId.chord,
      ClassId.clef,
      ClassId.note,
      ClassId.bTrem
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Mirrors `FTrem::FilterList` (ftrem.cpp:75): keeps only NOTE/CHORD
  /// children and drops chord tones.
  @override
  void filterList(List<Object> childList) {
    int i = 0;
    while (i < childList.length) {
      final Object object = childList[i];
      if (object.classId != ClassId.note && object.classId != ClassId.chord) {
        childList.removeAt(i);
        continue;
      }
      if (object.classId == ClassId.note &&
          (object as Note).isChordTone() != null) {
        childList.removeAt(i);
        continue;
      }
      i++;
    }
  }

  /// Mirrors `FTrem::GetElementCoords` (ftrem.cpp:70): refreshes the
  /// filtered list and returns the owned coords (same contract as
  /// [Beam.getElementCoords]).
  List<BeamElementCoord> getElementCoords() {
    getList();
    return beamElementCoordsOwned;
  }
}

/// Mirrors `vrv::GraceGrp`.
class GraceGrp extends LayerElement with AttColor, AttGraced, AttGraceGrpLog {
  GraceGrp() : super(ClassId.graceGrp) {
    reset();
  }

  @override
  String get className => 'graceGrp';

  @override
  Object clone() {
    final copy = GraceGrp();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant GraceGrp other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttGraced(other);
    copyAttGraceGrpLog(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.beam,
      ClassId.chord,
      ClassId.note,
      ClassId.rest,
      ClassId.space
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::HalfmRpt`.
class HalfmRpt extends LayerElement
    with AttVisualOffsetHo, AttVisualOffsetVo, AttColor, OffsetInterface {
  HalfmRpt() : super(ClassId.halfmRpt) {
    registerInterfaces([
      InterfaceId.offset,
    ]);
    reset();
  }

  @override
  String get className => 'halfmRpt';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = HalfmRpt();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant HalfmRpt other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyAttColor(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
  }
}

/// Mirrors `vrv::KeyAccid`.
class KeyAccid extends LayerElement
    with
        AttNoteGes,
        AttOctave,
        AttPitch,
        AttPitchGes,
        AttStaffLoc,
        AttStaffLocPitched,
        AttAccidental,
        AttColor,
        AttEnclosingChars,
        AttExtSymAuth,
        AttExtSymNames,
        PitchInterface,
        PositionInterface {
  KeyAccid() : super(ClassId.keyAccid) {
    registerInterfaces([
      InterfaceId.pitch,
      InterfaceId.position,
    ]);
    reset();
  }

  @override
  String get className => 'keyAccid';

  /// Mirrors `KeyAccid::CalcStaffLoc` (keyaccid.cpp:74): `@loc` wins,
  /// otherwise the pitch/octave (with the `KeySig::GetOctave` fallback for
  /// a missing `@oct`) through `PitchInterface::CalcLoc`.
  int calcStaffLoc(Clef clef, int clefLocOffset) {
    if (hasLoc) {
      return loc!;
    } else {
      final AccidentalWritten accidValue = accid ?? AccidentalWritten.none;
      final Pitchname? pnameValue = pname;
      if (pnameValue == null) return 0;
      final int octValue = hasOct ? oct! : KeySig.getOctave(accidValue, pnameValue, clef);
      return PitchInterface.calcLoc(pnameValue, octValue, clefLocOffset);
    }
  }

  @override
  Object clone() {
    final copy = KeyAccid();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant KeyAccid other) {
    super.copyFrom(other);
    copyPitchFrom(other);
    copyPositionFrom(other);
    copyAttAccidental(other);
    copyAttColor(other);
    copyAttEnclosingChars(other);
    copyAttExtSymAuth(other);
    copyAttExtSymNames(other);
    copyAttNoteGes(other);
    copyAttOctave(other);
    copyAttPitch(other);
    copyAttPitchGes(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }
}

/// Mirrors `vrv::KeySig`.
/// Information about a keyAccid child (mirrors `vrv::KeyAccidInfo`).
class KeyAccidInfo {
  KeyAccidInfo(this.accid, this.pname);
  AccidentalWritten accid;
  Pitchname pname;
}

/// Mirrors `vrv::KeySig`.
class KeySig extends LayerElement
    with
        AttColor,
        AttKeySigAnl,
        AttKeySigLog,
        AttKeySigVis,
        AttPitch,
        AttVisibility,
        ObjectListInterface {
  KeySig() : super(ClassId.keysig) {
    reset();
  }

  //----------------//
  // Static members //
  //----------------//

  /// The order of the pitch names for flats (mirrors `s_pnameForFlats`).
  static const List<Pitchname> pnameForFlats = [
    Pitchname.b,
    Pitchname.e,
    Pitchname.a,
    Pitchname.d,
    Pitchname.g,
    Pitchname.c,
    Pitchname.f,
  ];

  /// The order of the pitch names for sharps (mirrors `s_pnameForSharps`).
  static const List<Pitchname> pnameForSharps = [
    Pitchname.f,
    Pitchname.c,
    Pitchname.g,
    Pitchname.d,
    Pitchname.a,
    Pitchname.e,
    Pitchname.b,
  ];

  /// Octave map per clef position (mirrors `octave_map`): [accidSet][keySet]
  /// [pitch] with accidSet 0 = flats, 1 = sharps.
  static const List<List<List<int>>> octaveMap = [
    [
      // Flats
      // C,  D,  E,  F,  G,  A,  B
      [1, 1, 1, 0, 0, 0, 0], // french g = G-1
      [1, 1, 1, 0, 0, 0, 0], // treble = G-2
      [0, 0, 0, 0, 0, 0, 0], // soprano = C-1 (G-3)
      [0, 0, 0, 0, 0, -1, -1], // mezzo = C-2
      [0, 0, 0, -1, -1, -1, -1], // alto = C-3
      [0, 0, 0, -1, -1, -1, -1], // tenor = C-4
      [-1, -1, -1, -1, -1, -1, -1], // bariton = F-3 (C-5)
      [-1, -1, -1, -2, -2, -2, -2], // bass = F-4
      [-1, -1, -1, -1, -1, -2, -2], // sub-bass = F-5
    ],
    [
      // Sharps
      [1, 1, 1, 1, 1, 0, 0], // french g
      [1, 1, 1, 1, 1, 0, 0], // treble
      [0, 0, 0, 0, 0, 0, 0], // soprano
      [0, 0, 0, 0, 0, 0, 0], // mezzo
      [0, 0, 0, 0, 0, -1, -1], // alto
      [0, 0, 0, -1, -1, -1, -1], // tenor
      [-1, -1, -1, -1, -1, -1, -1], // bariton
      [-1, -1, -1, -1, -1, -2, -2], // bass
      [-1, -1, -1, -1, -1, -2, -2], // sub-bass
    ],
  ];

  /// Key change drawing values: skip the cancellation (mirrors
  /// `m_skipCancellation`).
  bool skipCancellation = false;

  /// The drawing cancel accidental type (mirrors
  /// `m_drawingCancelAccidType`).
  AccidentalWritten drawingCancelAccidType = AccidentalWritten.n;

  /// The drawing cancel accidental count (mirrors
  /// `m_drawingCancelAccidCount`).
  int drawingCancelAccidCount = 0;

  /// The drawing clef (optional; mirrors `m_drawingClef`).
  Clef? drawingClef;

  @override
  String get className => 'keySig';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = KeySig();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant KeySig other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttKeySigAnl(other);
    copyAttKeySigLog(other);
    copyAttKeySigVis(other);
    copyAttPitch(other);
    copyAttVisibility(other);
    skipCancellation = other.skipCancellation;
    drawingCancelAccidType = other.drawingCancelAccidType;
    drawingCancelAccidCount = other.drawingCancelAccidCount;
    if (other.drawingClef != null) {
      final copy = other.drawingClef!.clone() as Clef;
      copy.cloneReset();
      drawingClef = copy;
    } else {
      drawingClef = null;
    }
  }

  void resetKeySig() {
    // Key change drawing values.
    skipCancellation = false;
    drawingCancelAccidType = AccidentalWritten.n;
    drawingCancelAccidCount = 0;
    drawingClef = null;
  }

  @override
  void filterList(List<Object> childList) {
    childList
        .removeWhere((Object object) => object.classId != ClassId.keyAccid);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (classId == ClassId.keyAccid) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  @override
  bool addChildAdditionalCheck(Object child) {
    if (isAttribute && !child.isAttribute) {
      logError('Adding a non-attribute child to an attribute is not allowed');
      return false;
    }
    return super.addChildAdditionalCheck(child);
  }

  /// Accid number getter (mirrors `GetAccidCount`).
  int getAccidCount({bool fromAttribute = false}) {
    if (fromAttribute) {
      return hasSig ? sig!.sig : 0;
    } else {
      return getListSize();
    }
  }

  /// Accid type getter (mirrors `GetAccidType`).
  AccidentalWritten getAccidType() {
    if (hasNonAttribKeyAccidChildren() || !hasSig) {
      return AccidentalWritten.none;
    } else {
      return sig!.accid;
    }
  }

  /// Return true if some of the keyAccid children are not attribute-like
  /// (mirrors `HasNonAttribKeyAccidChildren`).
  bool hasNonAttribKeyAccidChildren() {
    final List<Object> childList = getList();
    return childList.any((Object child) => !child.isAttribute);
  }

  /// Generate keyAccid attribute children from the @sig value (mirrors
  /// `GenerateKeyAccidAttribChildren`).
  void generateKeyAccidAttribChildren() {
    deleteChildrenByComparison((Object child) =>
        child.classId == ClassId.keyAccid && child.isAttribute);

    if (hasEmptyList()) {
      for (int i = 0; i < getAccidCount(fromAttribute: true); ++i) {
        final KeyAccidInfo? info = getKeyAccidInfoAt(i);
        if (info != null) {
          final keyAccid = KeyAccid();
          keyAccid.accid = info.accid;
          keyAccid.pname = info.pname;
          keyAccid.isAttribute = true;
          addChild(keyAccid);
        }
      }
    } else if (hasSig) {
      logWarning(
          "Attribute key signature is ignored, since KeySig '$id' contains KeyAccid children.");
    }
  }

  /// Fill the map of modified pitches (mirrors `FillMap`).
  ///
  /// The map is keyed by `pname + oct * 7`.
  Map<int, AccidentalWritten> fillMap() {
    final Map<int, AccidentalWritten> mapOfPitchAccid = {};

    final List<Object> childList = getList(); // make sure it's initialized
    if (childList.isNotEmpty) {
      for (final Object child in childList) {
        final KeyAccid keyAccid = child as KeyAccid;
        for (int oct = 0; oct < 10; ++oct) {
          mapOfPitchAccid[keyAccid.pname!.value + oct * 7] = keyAccid.accid!;
        }
      }
      return mapOfPitchAccid;
    }

    final AccidentalWritten accidType = getAccidType();
    for (int i = 0; i < getAccidCount(fromAttribute: true); ++i) {
      for (int oct = 0; oct < 10; ++oct) {
        mapOfPitchAccid[getAccidPnameAt(accidType, i).value + oct * 7] =
            accidType;
      }
    }
    return mapOfPitchAccid;
  }

  /// Return the keyAccid info at [pos] (null when not a flat/sharp signature;
  /// mirrors `GetKeyAccidInfoAt`).
  KeyAccidInfo? getKeyAccidInfoAt(int pos) {
    if ((pos < 0) || (pos > 12)) return null;

    final AccidentalWritten type = getAccidType();
    if (type == AccidentalWritten.f) {
      return KeyAccidInfo(pos < 7 ? AccidentalWritten.f : AccidentalWritten.ff,
          pnameForFlats[pos % 7]);
    } else if (type == AccidentalWritten.s) {
      return KeyAccidInfo(pos < 7 ? AccidentalWritten.s : AccidentalWritten.ss,
          pnameForSharps[pos % 7]);
    }
    return null;
  }

  /// Return the fifths integer of the key signature (mirrors
  /// `GetFifthsInt`).
  int getFifthsInt() {
    if (sig?.accid == AccidentalWritten.f) {
      return -1 * sig!.sig;
    } else if (sig?.accid == AccidentalWritten.s) {
      return sig!.sig;
    }
    return 0;
  }

  /// Return the drawing clef (mirrors `GetDrawingClef`).
  Clef? getDrawingClef() => drawingClef;

  void resetDrawingClef() {
    drawingClef = null;
  }

  void setDrawingClef(Clef? clef) {
    if (clef != null) {
      drawingClef = clef.clone() as Clef;
      drawingClef!.cloneReset();
    } else {
      drawingClef = null;
    }
  }

  /// Mirrors `KeySig::IsScoreDefElement`: keySigs within a scoreDef /
  /// staffDef are scoreDef elements.
  @override
  bool get isScoreDefElement =>
      parent != null && getFirstAncestor(ClassId.scoreDef) != null;

  /// Try to convert the keySig content to a @sig value (mirrors
  /// `ConvertToSig`). Returns an unset @sig when the content cannot be
  /// converted.
  KeySignature convertToSig() {
    KeySignature sigValue = KeySignature.unset();
    final List<Object> childList = getList();
    if (childList.length > 1) {
      AccidentalWritten accidType = AccidentalWritten.none;
      bool isCommon = true;
      int pos = 0;
      for (final Object child in childList) {
        final KeyAccid keyAccid = child as KeyAccid;
        final AccidentalWritten curType = keyAccid.accid!;
        if (curType == AccidentalWritten.n) {
          // Skip naturals encoded explicitly.
          continue;
        }
        // We have not a key sig type at this stage.
        if (accidType == AccidentalWritten.none) {
          if (curType == AccidentalWritten.s ||
              curType == AccidentalWritten.f) {
            accidType = curType;
          }
        }
        if (accidType != curType) {
          logWarning(
              'All the keySig content cannot be converted to @sig because the accidental type is not a '
              'flat or a sharp, or mixes them');
          break;
        }
        if (accidType == AccidentalWritten.f &&
            pnameForFlats[pos] != keyAccid.pname) {
          isCommon = false;
          break;
        } else if (accidType == AccidentalWritten.s &&
            pnameForSharps[pos] != keyAccid.pname) {
          isCommon = false;
          break;
        }
        pos++;
      }
      if (!isCommon) {
        logWarning(
            'KeySig content cannot be converted to @sig because the accidental series is not standard');
        return sigValue;
      }
      sigValue = KeySignature(pos, accidType);
    }
    return sigValue;
  }

  /// Return the pitch name at [pos] for the accidental type (mirrors
  /// `GetAccidPnameAt` static method).
  static Pitchname getAccidPnameAt(AccidentalWritten accidType, int pos) {
    if (accidType == AccidentalWritten.f) {
      return pnameForFlats[pos % 7];
    } else {
      return pnameForSharps[pos % 7];
    }
  }

  /// Return the octave of the given pitch within the clef (mirrors
  /// `GetOctave` static method).
  static int getOctave(
      AccidentalWritten accidType, Pitchname pitch, Clef clef) {
    final int accidSet = (accidType == AccidentalWritten.s) ? 1 : 0;
    int keySet = 0;

    // Clefshape values: G = 1, GG = 2, F = 3, C = 4 (see mei_enums.dart).
    const int shapeG = 1, shapeGG = 2, shapeF = 3, shapeC = 4;
    final int shapeLine = (clef.shape?.value ?? 0) << 8 | (clef.line ?? 0);

    if (shapeLine == (shapeG << 8 | 1)) {
      keySet = 0;
    } else if (shapeLine == (shapeG << 8 | 2)) {
      keySet = 1;
    } else if (shapeLine == (shapeG << 8 | 3)) {
      keySet = 2;
    } else if (shapeLine == (shapeG << 8 | 4)) {
      keySet = 3;
    } else if (shapeLine == (shapeG << 8 | 5)) {
      keySet = 4;
    } else if (shapeLine == (shapeGG << 8 | 1)) {
      keySet = 0;
    } else if (shapeLine == (shapeGG << 8 | 2)) {
      keySet = 1;
    } else if (shapeLine == (shapeGG << 8 | 3)) {
      keySet = 2;
    } else if (shapeLine == (shapeGG << 8 | 4)) {
      keySet = 3;
    } else if (shapeLine == (shapeGG << 8 | 5)) {
      keySet = 4;
    } else if (shapeLine == (shapeC << 8 | 1)) {
      keySet = 2;
    } else if (shapeLine == (shapeC << 8 | 2)) {
      keySet = 3;
    } else if (shapeLine == (shapeC << 8 | 3)) {
      keySet = 4;
    } else if (shapeLine == (shapeC << 8 | 4)) {
      keySet = 5;
    } else if (shapeLine == (shapeC << 8 | 5)) {
      keySet = 6;
    } else if (shapeLine == (shapeF << 8 | 3)) {
      keySet = 6;
    } else if (shapeLine == (shapeF << 8 | 4)) {
      keySet = 7;
    } else if (shapeLine == (shapeF << 8 | 5)) {
      keySet = 8;
    } else if (shapeLine == (shapeF << 8 | 1)) {
      // Does not really exist but just to make it somehow aligned with the
      // clef.
      keySet = 8;
    } else if (shapeLine == (shapeF << 8 | 2)) {
      keySet = 8;
    } else {
      keySet = 4;
    }

    int octave = octaveMap[accidSet][keySet][pitch.value - 1] + octaveOffset;

    int disPlace = 0;
    if (clef.dis != null && clef.dis != OctaveDis.none) {
      // DIS 22 not supported.
      if (clef.disPlace == StaffrelBasic.above) {
        disPlace = (clef.dis == OctaveDis.n8) ? -1 : -2;
      } else if (clef.disPlace == StaffrelBasic.below) {
        disPlace = (clef.dis == OctaveDis.n8) ? 1 : 2;
      }
    }
    if (clef.shape == Clefshape.gg) disPlace = 1;

    octave -= disPlace;

    return octave;
  }
}

/// Mirrors `vrv::Ligature`.
class Ligature extends LayerElement with AttLigatureVis, ObjectListInterface {
  Ligature() : super(ClassId.ligature) {
    reset();
  }

  /// The drawing shapes of the ligature (mirrors `m_drawingShapes`).
  ///
  /// Bitwise combination of the LIGATURE_* shape flags (see vrvdef.dart).
  final List<int> drawingShapes = [];

  @override
  String get className => 'ligature';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Ligature();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Ligature other) {
    super.copyFrom(other);
    copyAttLigatureVis(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors Ligature::IsSupportedChild.
    const supported = {ClassId.dot, ClassId.note};
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Filter the flat list keeping only the note children (mirrors
  /// `Ligature::FilterList`).
  @override
  void filterList(List<Object> childList) {
    childList.removeWhere((Object object) => object.classId != ClassId.note);
  }

  /// Return shape information about the note ligature (mirrors
  /// `Ligature::GetDrawingNoteShape`); -1 when the note is not part of the
  /// ligature.
  int getDrawingNoteShape(Object note) {
    final int position = getListIndex(note);
    if (position == -1) return -1;

    // No check because drawingShapes will have been filled by then.
    return drawingShapes[position];
  }
}

/// Mirrors `vrv::Liquescent`.
class Liquescent extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttNoteGes,
        AttOctave,
        AttPitch,
        AttPitchGes,
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        OffsetInterface,
        PitchInterface,
        PositionInterface {
  Liquescent() : super(ClassId.liquescent) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.pitch,
      InterfaceId.position,
    ]);
    reset();
  }

  @override
  String get className => 'liquescent';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Liquescent();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Liquescent other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyPitchFrom(other);
    copyPositionFrom(other);
    copyAttColor(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttNoteGes(other);
    copyAttOctave(other);
    copyAttPitch(other);
    copyAttPitchGes(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }
}

/// Mirrors `vrv::MeterSig`.
class MeterSig extends LayerElement
    with
        AttColor,
        AttEnclosingChars,
        AttExtSymNames,
        AttMeterSigLog,
        AttMeterSigVis,
        AttTypography,
        AttVisibility {
  MeterSig() : super(ClassId.meterSig) {
    reset();
  }

  @override
  String get className => 'meterSig';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  /// Mirrors `MeterSig::IsScoreDefElement`: meterSigs within a scoreDef /
  /// staffDef are scoreDef elements.
  @override
  bool get isScoreDefElement =>
      parent != null && getFirstAncestor(ClassId.scoreDef) != null;

  @override
  Object clone() {
    final copy = MeterSig();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant MeterSig other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttEnclosingChars(other);
    copyAttExtSymNames(other);
    copyAttMeterSigLog(other);
    copyAttMeterSigVis(other);
    copyAttTypography(other);
    copyAttVisibility(other);
  }

  /// Return the total count of the meter signature (mirrors `GetTotalCount`).
  int getTotalCount() {
    final (List<int> counts, MeterCountSign sign) = getCountPair();
    // If @count is empty, look at the sym to return a reasonable value.
    if (counts.isEmpty) {
      if (hasSym) {
        return (sym == Metersign.cut) ? 2 : 4;
      } else {
        return 0;
      }
    }
    switch (sign) {
      case MeterCountSign.slash:
        // Make sure that there is no division by zero.
        final List<int> values = [
          for (final int elem in counts) elem == 0 ? 1 : elem,
        ];
        int result = values.reduce((a, b) => a ~/ b);
        if (result == 0) result = 1;
        return result;
      case MeterCountSign.minus:
        int result = counts.skip(1).fold(counts.first, (a, b) => a - b);
        if (result <= 0) result = 1;
        return result;
      case MeterCountSign.asterisk:
        int result = counts.fold(1, (a, b) => a * b);
        if (result == 0) result = 1;
        return result;
      case MeterCountSign.plus:
        return counts.fold(0, (a, b) => a + b);
      case MeterCountSign.none:
        break;
    }
    return counts.first;
  }

  /// Return the implicit unit of the @sym (2 for cut, 4 for common; mirrors
  /// `GetSymImplicitUnit`).
  int getSymImplicitUnit() {
    if (hasSym) {
      return (sym == Metersign.cut) ? 2 : 4;
    } else {
      return 0;
    }
  }

  /// Return the @unit as a data_DURATION value (mirrors `GetUnitAsDur`).
  MeiDuration getUnitAsDur() {
    switch (unit) {
      case 1:
        return MeiDuration.dur1;
      case 2:
        return MeiDuration.dur2;
      case 4:
        return MeiDuration.dur4;
      case 8:
        return MeiDuration.dur8;
      case 16:
        return MeiDuration.dur16;
      case 32:
        return MeiDuration.dur32;
      default:
        return MeiDuration.dur4;
    }
  }

  /// The parsed (@count, sign) pair of the meter signature.
  (List<int>, MeterCountSign) getCountPair() {
    final MeterCountPair? pair = count;
    if (pair == null) return ([], MeterCountSign.none);
    return (pair.counts, pair.sign);
  }

  /// Set the count from a list of values and a sign (mirrors `SetCount`).
  void setCount(List<int> counts, MeterCountSign sign) {
    count = MeterCountPair(counts, sign);
  }
}

/// Mirrors `vrv::MeterSigGrp`.
class MeterSigGrp extends LayerElement
    with AttBasic, AttMeterSigGrpLog, AttVisibility, ObjectListInterface {
  MeterSigGrp() : super(ClassId.meterSigGrp) {
    reset();
  }

  /// The count of measures for alternating meter signatures (mirrors
  /// `m_count`).
  int _count = 0;

  /// The list of alternating measures (mirrors `m_alternatingMeasures`);
  /// populated by the layout.
  final List<Object> _alternatingMeasures = [];

  @override
  String get className => 'meterSigGrp';

  /// Mirrors the scoreDef-element override of MeterSig for the group.
  @override
  bool get isScoreDefElement =>
      parent != null && getFirstAncestor(ClassId.scoreDef) != null;

  @override
  Object clone() {
    final copy = MeterSigGrp();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant MeterSigGrp other) {
    super.copyFrom(other);
    copyAttBasic(other);
    copyAttMeterSigGrpLog(other);
    copyAttVisibility(other);
    _count = other._count;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    return classId == ClassId.meterSig;
  }

  @override
  void filterList(List<Object> childList) {
    // We want to keep only meterSig children.
    childList
        .removeWhere((Object object) => object.classId != ClassId.meterSig);
  }

  /// Add a measure to the vector of alternating measures (mirrors
  /// `AddAlternatingMeasureToVector`).
  void addAlternatingMeasure(Object measure) {
    _alternatingMeasures.add(measure);
  }

  /// Return a simplified meter signature for the group (mirrors
  /// `GetSimplifiedMeterSig`).
  ///
  /// The returned element is a clone; the caller owns it.
  MeterSig? getSimplifiedMeterSig() {
    MeterSig? newMeterSig;
    final List<Object> childList = getList();
    switch (func) {
      // For alternating meterSig group alternate between children
      // sequentially.
      case MetersiggrplogFunc.alternating:
        if (childList.isEmpty) break;
        final int index = _count % childList.length;
        newMeterSig = cloneOf(childList[index] as MeterSig);
        break;
      // For interchanging meterSig group select the largest signature, but
      // make sure to align unit with the shortest.
      case MetersiggrplogFunc.interchanging:
        // Get the element with the highest count/unit ratio.
        MeterSig? maxRatioSig;
        double maxRatio = -1;
        int maxUnit = 0;
        for (final Object obj in childList) {
          final MeterSig meterSig = obj as MeterSig;
          final double ratio = meterSig.getTotalCount() / (meterSig.unit ?? 1);
          if (ratio > maxRatio) {
            maxRatio = ratio;
            maxRatioSig = meterSig;
          }
          if ((meterSig.unit ?? 0) > maxUnit) maxUnit = meterSig.unit!;
        }

        if (maxRatioSig != null) {
          newMeterSig = cloneOf(maxRatioSig);
          if ((newMeterSig.unit ?? 0) < maxUnit) {
            final int ratio = maxUnit ~/ newMeterSig.unit!;
            final (List<int> counts, MeterCountSign sign) =
                newMeterSig.getCountPair();
            newMeterSig
                .setCount([for (final int elem in counts) elem * ratio], sign);
            newMeterSig.unit = maxUnit;
          }
        }
        break;
      // For mixed meterSig group we accumulate the total count of all child
      // meterSigs (and keep the highest unit), since it is what counts for
      // the timestamps.
      case MetersiggrplogFunc.mixed:
        int maxUnit = 0;
        int currentCount = 0;
        for (final Object obj in childList) {
          if (obj.classId != ClassId.meterSig) {
            logWarning("Skipping over non-meterSig child of <meterSigGrp>");
            continue;
          }
          final MeterSig meterSig = obj as MeterSig;
          newMeterSig ??= cloneOf(meterSig);
          final int currentUnit = meterSig.unit ?? 0;
          if (maxUnit == 0) maxUnit = currentUnit;
          if (maxUnit == currentUnit) {
            currentCount += meterSig.getTotalCount();
          } else if (maxUnit > currentUnit) {
            final int ratio = maxUnit ~/ currentUnit;
            currentCount += meterSig.getTotalCount() * ratio;
          } else {
            final int ratio = currentUnit ~/ maxUnit;
            currentCount *= ratio;
            currentCount += meterSig.getTotalCount();
            maxUnit = currentUnit;
          }
        }
        if (newMeterSig != null) {
          newMeterSig.unit = maxUnit;
          newMeterSig.setCount([currentCount], MeterCountSign.none);
        }
        break;
      default:
        break;
    }
    return newMeterSig;
  }

  /// Set the count based on the position of [measure] in the alternating
  /// measures (mirrors `SetMeasureBasedCount`).
  void setMeasureBasedCount(Object measure) {
    final int index =
        _alternatingMeasures.indexWhere((Object m) => identical(m, measure));
    _count = index;
  }

  static MeterSig cloneOf(MeterSig source) {
    final copy = source.clone() as MeterSig;
    copy.cloneReset();
    return copy;
  }
}

/// Mirrors `vrv::MRest`.
class MRest extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        AttCue,
        AttCutout,
        AttFermataPresent,
        AttVisibility,
        OffsetInterface,
        PositionInterface {
  MRest() : super(ClassId.mRest) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.position,
    ]);
    reset();
  }

  @override
  String get className => 'mRest';

  @override
  Object clone() {
    final copy = MRest();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant MRest other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyPositionFrom(other);
    copyAttColor(other);
    copyAttCue(other);
    copyAttCutout(other);
    copyAttFermataPresent(other);
    copyAttVisibility(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }
}

/// Mirrors `vrv::MRpt`.
class MRpt extends LayerElement with AttColor, AttNumbered, AttNumberPlacement {
  MRpt() : super(ClassId.mRpt) {
    reset();
  }

  /// The drawing measure count for multi-number (set by the rpt preparation;
  /// mirrors `m_drawingMeasureCount`).
  int drawingMeasureCount = 0;

  @override
  String get className => 'mRpt';

  @override
  Object clone() {
    final copy = MRpt();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant MRpt other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttNumbered(other);
    copyAttNumberPlacement(other);
  }
}

/// Mirrors `vrv::MRpt2`.
class MRpt2 extends LayerElement with AttColor {
  MRpt2() : super(ClassId.mRpt2) {
    reset();
  }

  @override
  String get className => 'mRpt2';

  @override
  Object clone() {
    final copy = MRpt2();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant MRpt2 other) {
    super.copyFrom(other);
    copyAttColor(other);
  }
}

/// Mirrors `vrv::MSpace`.
class MSpace extends LayerElement {
  MSpace() : super(ClassId.mSpace) {
    reset();
  }

  @override
  String get className => 'mSpace';

  @override
  Object clone() {
    final copy = MSpace();
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::MultiRest`.
class MultiRest extends LayerElement
    with
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        AttMultiRestVis,
        AttNumbered,
        AttNumberPlacement,
        AttWidth,
        PositionInterface {
  MultiRest() : super(ClassId.multiRest) {
    registerInterfaces([
      InterfaceId.position,
    ]);
    reset();
  }

  @override
  String get className => 'multiRest';

  @override
  Object clone() {
    final copy = MultiRest();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant MultiRest other) {
    super.copyFrom(other);
    copyPositionFrom(other);
    copyAttColor(other);
    copyAttMultiRestVis(other);
    copyAttNumbered(other);
    copyAttNumberPlacement(other);
    copyAttWidth(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }
}

/// Mirrors `vrv::MultiRpt`.
class MultiRpt extends LayerElement with AttNumbered {
  MultiRpt() : super(ClassId.multiRpt) {
    reset();
  }

  @override
  String get className => 'multiRpt';

  @override
  Object clone() {
    final copy = MultiRpt();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant MultiRpt other) {
    super.copyFrom(other);
    copyAttNumbered(other);
  }
}

/// A glyph parameter for the nc (mirrors `Nc::DrawingGlyph`).
///
/// One single nc might need more than one glyph (e.g., liquescent).
/// Set in CalcLigatureOrNeumePosFunctor.visitNeume.
class NcDrawingGlyph {
  NcDrawingGlyph([this.fontNo = 0]);

  /// The SMuFL code point of the glyph (mirrors `m_fontNo`).
  int fontNo;

  /// The x / y offsets of the glyph (mirrors `m_xOffset` / `m_yOffset`).
  double xOffset = 0.0;
  double yOffset = 0.0;
}

/// Mirrors `vrv::Nc`.
class Nc extends LayerElement
    with
        AttAugmentDots,
        AttBeamSecondary,
        AttDurationGes,
        AttDurationLog,
        AttDurationQuality,
        AttDurationRatio,
        AttFermataPresent,
        AttStaffIdent,
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttNoteGes,
        AttOctave,
        AttPitch,
        AttPitchGes,
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        AttCurvatureDirection,
        AttIntervalMelodic,
        AttNcForm,
        DurationInterface,
        OffsetInterface,
        PitchInterface,
        PositionInterface {
  Nc() : super(ClassId.nc) {
    registerInterfaces([
      InterfaceId.duration,
      InterfaceId.offset,
      InterfaceId.pitch,
      InterfaceId.position,
    ]);
    reset();
  }

  /// The drawing glyphs of the nc (mirrors `m_drawingGlyphs`).
  final List<NcDrawingGlyph> drawingGlyphs = [];

  @override
  String get className => 'nc';

  @override
  Object clone() {
    final copy = Nc();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Nc other) {
    super.copyFrom(other);
    copyDurationFrom(other);
    copyOffsetFrom(other);
    copyPitchFrom(other);
    copyPositionFrom(other);
    copyAttColor(other);
    copyAttCurvatureDirection(other);
    copyAttIntervalMelodic(other);
    copyAttNcForm(other);
    copyAttAugmentDots(other);
    copyAttBeamSecondary(other);
    copyAttDurationGes(other);
    copyAttDurationLog(other);
    copyAttDurationQuality(other);
    copyAttDurationRatio(other);
    copyAttFermataPresent(other);
    copyAttStaffIdent(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttNoteGes(other);
    copyAttOctave(other);
    copyAttPitch(other);
    copyAttPitchGes(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors Nc::IsSupportedChild.
    const supported = {
      ClassId.epistema,
      ClassId.liquescent,
      ClassId.oriscus,
      ClassId.quilisma,
      ClassId.strophicus
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::NeumeGroup` (neume.h:37).
enum NeumeGroup {
  /// `NEUME_ERROR`
  error,
  /// `PUNCTUM`
  punctum,
  /// `CLIVIS`
  clivis,
  /// `PES`
  pes,
  /// `PRESSUS`
  pressus,
  /// `CLIMACUS`
  climacus,
  /// `PORRECTUS`
  porrectus,
  /// `SCANDICUS`
  scandicus,
  /// `TORCULUS`
  torculus,
  /// `SCANDICUS_FLEXUS`
  scandicusFlexus,
  /// `PORRECTUS_FLEXUS`
  porrectusFlexus,
  /// `TORCULUS_RESUPINUS`
  torculusResupinus,
  /// `CLIMACUS_RESUPINUS`
  climacusResupinus,
  /// `PES_SUBPUNCTIS`
  pesSubpunctis,
  /// `PORRECTUS_SUBPUNCTIS`
  porrectusSubpunctis,
  /// `SCANDICUS_SUBPUNCTIS`
  scandicusSubpunctis,
}

/// Mirrors `Neume::s_neumes` (neume.cpp:35): contour keys (as defined in
/// MEI4) to neume groups.
const Map<String, NeumeGroup> neumeGroups = {
  '': NeumeGroup.punctum,
  'u': NeumeGroup.pes,
  'd': NeumeGroup.clivis,
  'uu': NeumeGroup.scandicus,
  'dd': NeumeGroup.climacus,
  'ud': NeumeGroup.torculus,
  'du': NeumeGroup.porrectus,
  'ddd': NeumeGroup.climacus,
  'ddu': NeumeGroup.climacusResupinus,
  'udu': NeumeGroup.torculusResupinus,
  'dud': NeumeGroup.porrectusFlexus,
  'udd': NeumeGroup.pesSubpunctis,
  'uud': NeumeGroup.scandicusFlexus,
  'uudd': NeumeGroup.scandicusSubpunctis,
  'dudd': NeumeGroup.porrectusSubpunctis,
  'sd': NeumeGroup.pressus,
};

/// Mirrors `vrv::Neume`.
class Neume extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttColor,
        ObjectListInterface,
        OffsetInterface {
  Neume() : super(ClassId.neume) {
    registerInterfaces([
      InterfaceId.offset,
    ]);
    reset();
  }

  @override
  String get className => 'neume';

  @override
  Object clone() {
    final copy = Neume();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Neume other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyAttColor(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors Neume::IsSupportedChild.
    if (classId == ClassId.nc) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Mirrors `Neume::GetPosition` (neume.cpp:75): the index of [element] in
  /// the filtered `nc` list (`-1` when absent).
  int getPosition(LayerElement element) {
    getList();
    return getListIndex(element);
  }

  /// Mirrors `Neume::GetLigatureCount` (neume.cpp:81): counts the `nc`
  /// children with `@ligated` up to and including [position].
  ///
  /// No callers outside neume.cpp in the C++ tree (verified 2026-09-03);
  /// kept for API parity with the internal ligature logic.
  int getLigatureCount(int position) {
    int ligCount = 0;
    getList();
    for (int pos = 0; pos <= position; pos++) {
      final Object? posObj = getChild(pos);
      if (posObj != null) {
        final Nc posNc = posObj as Nc;
        if (posNc.ligated == true) {
          // First part of the ligature.
          ligCount += 1;
        }
      }
    }
    return ligCount;
  }

  /// Mirrors `Neume::IsLastInNeume` (neume.cpp:98).
  ///
  /// No callers outside neume.cpp in the C++ tree (verified 2026-09-03).
  bool isLastInNeume(LayerElement element) {
    final int size = getListSize();
    final int position = getPosition(element);

    // This method should be called only if the note is part of a neume.
    assert(position != -1);
    // This is the last one.
    if (position == (size - 1)) return true;
    return false;
  }

  /// Mirrors `Neume::GetNeumeGroup` (neume.cpp:110): the contour group of
  /// the `nc` children (`u`p / `d`own / `s`ame steps keyed through
  /// [neumeGroups]), or [NeumeGroup.error] when unknown.
  ///
  /// No callers outside neume.cpp in the C++ tree (verified 2026-09-03).
  NeumeGroup getNeumeGroup() {
    final List<Object> children = findAllDescendantsByType(ClassId.nc);

    final it = children.iterator;
    if (!it.moveNext()) return NeumeGroup.error;
    Nc? previous = it.current as Nc?;
    if (previous == null) return NeumeGroup.error;

    String key = '';
    while (it.moveNext()) {
      final Nc current = it.current as Nc;
      final int pitchDifference =
          current.pitchDifferenceTo(previous! as PitchInterface);
      if (pitchDifference > 0) {
        key += 'u';
      } else if (pitchDifference < 0) {
        key += 'd';
      } else {
        key += 's';
      }
      previous = current;
    }

    return neumeGroups[key] ?? NeumeGroup.error;
  }

  /// Mirrors `Neume::GetPitchDifferences` (neume.cpp:146): the successive
  /// `nc` pitch steps.
  ///
  /// No callers outside neume.cpp in the C++ tree (verified 2026-09-03).
  List<int> getPitchDifferences() {
    final List<int> pitchDifferences = [];
    final List<Object> ncChildren = findAllDescendantsByType(ClassId.nc);

    final it = ncChildren.iterator;
    if (!it.moveNext()) return pitchDifferences;
    Nc? previous = it.current as Nc?;
    if (previous == null) return pitchDifferences;

    while (it.moveNext()) {
      final Nc current = it.current as Nc;
      pitchDifferences
          .add(current.pitchDifferenceTo(previous as PitchInterface));
      previous = current;
    }
    return pitchDifferences;
  }

  /// Mirrors `Neume::GenerateChildMelodic` (neume.cpp:168): stamps the
  /// `@intm` (up/down/same) of every `nc` after the head relative to its
  /// predecessor. Entry point of the neume helpers — the only one with an
  /// in-tree caller family (`Nc::AdjustPitchPos`, `Nc::GetJunctureIntervals`
  /// read the `@intm` values it writes).
  bool generateChildMelodic() {
    final List<Object> children = findAllDescendantsByType(ClassId.nc);

    // Get the first neume component of the neume.
    final it = children.iterator;
    if (!it.moveNext()) return false;
    Nc? head = it.current as Nc?;
    if (head == null) return false;

    // Iterate on second to last neume component and add intm value.
    while (it.moveNext()) {
      final Nc current = it.current as Nc;
      String intmValue;

      final int pitchDifference = current.pitchDifferenceTo(head as PitchInterface);
      if (pitchDifference > 0) {
        intmValue = 'u';
      } else if (pitchDifference < 0) {
        intmValue = 'd';
      } else {
        intmValue = 's';
      }

      current.intm = intmValue;
      head = current;
    }

    return true;
  }

  /// Mirrors `Neume::GetHighestPitch` (neume.cpp:202): the pitch interface
  /// child with the greatest pitch, or null when there is none.
  ///
  /// No callers outside neume.cpp in the C++ tree (verified 2026-09-03).
  ///
  /// Deviation: the C++ downcasts through `Object::GetPitchInterface()`;
  /// this port reads the `PitchInterface` mixin directly (`Nc` and its
  /// ornaments implement it).
  PitchInterface? getHighestPitch() {
    final InterfaceComparison ic = InterfaceComparison(InterfaceId.pitch);
    final List<Object> pitchChildren = findAllDescendantsMatching(ic);

    if (pitchChildren.isEmpty) return null;
    PitchInterface? max = pitchChildren.first as PitchInterface?;
    if (max == null) return null;
    for (int i = 1; i < pitchChildren.length; ++i) {
      final PitchInterface pi = pitchChildren[i] as PitchInterface;
      if (pi.pitchDifferenceTo(max as PitchInterface) > 0) {
        max = pi;
      }
    }
    return max;
  }

  /// Mirrors `Neume::GetLowestPitch` (neume.cpp:221): the pitch interface
  /// child with the smallest pitch, or null when there is none.
  ///
  /// No callers outside neume.cpp in the C++ tree (verified 2026-09-03).
  ///
  /// Deviation: same `GetPitchInterface()` downcast note as
  /// [getHighestPitch].
  PitchInterface? getLowestPitch() {
    final InterfaceComparison ic = InterfaceComparison(InterfaceId.pitch);
    final List<Object> pitchChildren = findAllDescendantsMatching(ic);

    if (pitchChildren.isEmpty) return null;
    PitchInterface? min = pitchChildren.first as PitchInterface?;
    if (min == null) return null;
    for (int i = 1; i < pitchChildren.length; ++i) {
      final PitchInterface pi = pitchChildren[i] as PitchInterface;
      if (pi.pitchDifferenceTo(min as PitchInterface) < 0) {
        min = pi;
      }
    }
    return min;
  }
}

/// Mirrors `vrv::Oriscus`.
class Oriscus extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttNoteGes,
        AttOctave,
        AttPitch,
        AttPitchGes,
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        OffsetInterface,
        PitchInterface,
        PositionInterface {
  Oriscus() : super(ClassId.oriscus) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.pitch,
      InterfaceId.position,
    ]);
    reset();
  }

  @override
  String get className => 'oriscus';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Oriscus();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Oriscus other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyPitchFrom(other);
    copyPositionFrom(other);
    copyAttColor(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttNoteGes(other);
    copyAttOctave(other);
    copyAttPitch(other);
    copyAttPitchGes(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }
}

/// Mirrors `vrv::Plica`.
class Plica extends LayerElement with AttPlicaVis {
  Plica() : super(ClassId.plica) {
    reset();
  }

  @override
  String get className => 'plica';

  @override
  Object clone() {
    final copy = Plica();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Plica other) {
    super.copyFrom(other);
    copyAttPlicaVis(other);
  }
}

/// Mirrors `vrv::Proport`.
class Proport extends LayerElement with AttDurationRatio {
  Proport() : super(ClassId.proport) {
    reset();
  }

  /// The cumulated @num of the proportion chain (mirrors `m_cumulatedNum`).
  int _cumulatedNum = meiUnset;

  /// The cumulated @numbase of the proportion chain (mirrors
  /// `m_cumulatedNumbase`).
  int _cumulatedNumbase = meiUnset;

  @override
  String get className => 'proport';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Proport();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Proport other) {
    super.copyFrom(other);
    copyAttDurationRatio(other);
    _cumulatedNum = other._cumulatedNum;
    _cumulatedNumbase = other._cumulatedNumbase;
  }

  void resetProport() {
    _cumulatedNum = meiUnset;
    _cumulatedNumbase = meiUnset;
  }

  int get cumulatedNum =>
      (_cumulatedNum != meiUnset) ? _cumulatedNum : (this.num ?? meiUnset);

  int get cumulatedNumbase => (_cumulatedNumbase != meiUnset)
      ? _cumulatedNumbase
      : (numbase ?? meiUnset);

  /// Cumulate this proportion with [proport] (mirrors `Cumulate`).
  void cumulate(Proport proport) {
    // Reset type proportion - do not cumulate
    if (type == 'reset') return;
    // Potential reset (tempo change) in CMME - do not cumulate
    if (type == 'reset?') return;

    // Unset values are not cumulated
    if (proport.hasNum && hasNum) {
      _cumulatedNum = this.num! * proport.cumulatedNum;
    }
    if (proport.hasNumbase && hasNumbase) {
      _cumulatedNumbase = numbase! * proport.cumulatedNumbase;
    }
    if ((_cumulatedNum != meiUnset) && (_cumulatedNumbase != meiUnset)) {
      final pair = [_cumulatedNum, _cumulatedNumbase];
      Fraction.reducePair(pair);
      _cumulatedNum = pair[0];
      _cumulatedNumbase = pair[1];
    }
  }

  void resetCumulate() {
    _cumulatedNum = meiUnset;
    _cumulatedNumbase = meiUnset;
  }
}

/// Mirrors `vrv::Quilisma`.
class Quilisma extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttNoteGes,
        AttOctave,
        AttPitch,
        AttPitchGes,
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        OffsetInterface,
        PitchInterface,
        PositionInterface {
  Quilisma() : super(ClassId.quilisma) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.pitch,
      InterfaceId.position,
    ]);
    reset();
  }

  @override
  String get className => 'quilisma';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Quilisma();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Quilisma other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyPitchFrom(other);
    copyPositionFrom(other);
    copyAttColor(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttNoteGes(other);
    copyAttOctave(other);
    copyAttPitch(other);
    copyAttPitchGes(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }
}

/// Mirrors `vrv::Space`.
class Space extends LayerElement
    with
        AttAugmentDots,
        AttBeamSecondary,
        AttDurationGes,
        AttDurationLog,
        AttDurationQuality,
        AttDurationRatio,
        AttFermataPresent,
        AttStaffIdent,
        DurationInterface {
  Space() : super(ClassId.space) {
    registerInterfaces([
      InterfaceId.duration,
    ]);
    reset();
  }

  @override
  String get className => 'space';

  @override
  Object clone() {
    final copy = Space();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Space other) {
    super.copyFrom(other);
    copyDurationFrom(other);
    copyAttAugmentDots(other);
    copyAttBeamSecondary(other);
    copyAttDurationGes(other);
    copyAttDurationLog(other);
    copyAttDurationQuality(other);
    copyAttDurationRatio(other);
    copyAttFermataPresent(other);
    copyAttStaffIdent(other);
  }
}

/// Mirrors `vrv::Stem`.
class Stem extends LayerElement with AttGraced, AttStemVis, AttVisibility {
  Stem() : super(ClassId.stem) {
    reset();
  }

  /// The drawing direction of the stem (mirrors `m_drawingStemDir`).
  Stemdirection drawingStemDir = Stemdirection.none;

  /// The drawing length of the stem; negative when pointing up (mirrors
  /// `m_drawingStemLen`).
  int drawingStemLen = 0;

  /// The vertical adjust of the stem end computed by the beam layout
  /// (mirrors `m_drawingStemAdjust`; reset to 0).
  int drawingStemAdjust = 0;

  /// The stem modifier for tremolo rendering (mirrors `m_drawingStemMod`).
  Stemmodifier? drawingStemMod;

  /// The relative Y for stem modifier positioning (mirrors `m_stemModRelY`).
  int stemModRelY = 0;

  /// Virtual stems are not drawn (e.g., whole notes; mirrors `m_isVirtual`).
  bool isVirtual = false;

  /// Mirrors `SetDrawingStemDir` / `GetDrawingStemDir`.
  void setDrawingStemDir(Stemdirection stemDir) => drawingStemDir = stemDir;
  Stemdirection getDrawingStemDir() => drawingStemDir;

  /// Mirrors `SetDrawingStemLen` / `GetDrawingStemLen`.
  void setDrawingStemLen(int len) => drawingStemLen = len;
  int getDrawingStemLen() => drawingStemLen;

  /// Mirrors `SetDrawingStemMod` / `GetDrawingStemMod` (stem.cpp:85-87).
  void setDrawingStemMod(Stemmodifier mod) => drawingStemMod = mod;
  Stemmodifier? getDrawingStemMod() => drawingStemMod;
  bool hasDrawingStemMod() => drawingStemMod != null;

  /// Mirrors `IsVirtual` / `IsVirtual(bool)`.
  void setIsVirtual(bool isVirtual) => this.isVirtual = isVirtual;
  bool getIsVirtual() => isVirtual;

  /// The stem modifier this stem is drawing (mirrors the `bTrem` /
  /// own-`@stem.mod` resolution shared by `CalculateStemModRelY` and
  /// `AdjustSlashes`, stem.cpp:150-153/199-206).
  Stemmodifier _resolveDrawingStemMod() {
    final Object? bTremAncestor = getFirstAncestor(ClassId.bTrem);
    if (bTremAncestor is BTrem) {
      return bTremAncestor.getDrawingStemMod();
    }
    if (hasDrawingStemMod()) return drawingStemMod!;
    return Stemmodifier.none;
  }

  /// Mirrors `Stem::CalculateStemModRelY` (stem.cpp:193): the relative Y
  /// offset (from the note head) at which the tremolo-slash / sprechgesang /
  /// buzz-roll glyph is drawn on the stem, adjusted so it does not collide
  /// with ledger lines.
  void calculateStemModRelY(Doc doc, Staff staff) {
    final int sign = (getDrawingStemDir() == Stemdirection.up) ? 1 : -1;
    final Object? parentObj = parent;
    Note? note;
    if (parentObj is Note) {
      note = parentObj;
    } else if (parentObj is Chord) {
      note = (sign > 0) ? parentObj.getTopNote() : parentObj.getBottomNote();
    }
    if (note == null || note.isGraceNote() || note.drawingCueSize) return;

    final Stemmodifier stemMod = _resolveDrawingStemMod();
    if (stemMod == Stemmodifier.none || stemMod == Stemmodifier.none0) return;

    final int code = stemModToGlyph(stemMod);
    if (code == 0) return;

    final int unit = doc.getDrawingUnit(staff.drawingStaffSize);
    final int glyphHalfHeight =
        doc.getGlyphHeight(code, staff.drawingStaffSize, false) ~/ 2;
    final int noteLoc = note.drawingLoc;
    int height = 2 * unit;
    switch (stemMod) {
      case Stemmodifier.n1slash:
      case Stemmodifier.n2slash:
      case Stemmodifier.n3slash:
      case Stemmodifier.n4slash:
      case Stemmodifier.n5slash:
      case Stemmodifier.n6slash:
        if (noteLoc % 2 == 0) height += unit;
        height += glyphHalfHeight;
        if (stemMod == Stemmodifier.n6slash) {
          height +=
              doc.getGlyphHeight(smuflE220Tremolo1, staff.drawingStaffSize, false) ~/
                  2;
        }
        break;
      case Stemmodifier.sprech:
      case Stemmodifier.z:
        height += unit;
        if (stemMod == Stemmodifier.sprech) height -= sign * glyphHalfHeight;
        break;
      default:
        return;
    }

    // Adjust for stem modifiers that overlap with ledger lines.
    final int position = note.getDrawingY() + sign * height;
    final int staffSize = staff.drawingStaffSize;
    final int doubleUnit = 2 * unit;
    final int margin = (sign > 0)
        ? staff.getDrawingY() - doc.getDrawingStaffSize(staffSize)
        : staff.getDrawingY();
    final int ledgerLineDifference = margin - (position - sign * glyphHalfHeight);
    final int adjust = (sign * ledgerLineDifference > 0)
        ? (ledgerLineDifference ~/ doubleUnit) * doubleUnit
        : 0;

    stemModRelY = sign * height + adjust;
  }

  /// Mirrors `Stem::AdjustSlashes` (stem.cpp:145): the stem-length
  /// adjustment needed so the stem reaches past the stem-modifier glyph
  /// computed by [calculateStemModRelY]. Returns 0 (no adjustment) when the
  /// stem has no modifier or an explicit `@len`.
  int adjustSlashes(Doc doc, Staff staff, int flagOffset) {
    if (hasLen) return 0;

    final int staffSize = staff.drawingStaffSize;
    final int unit = doc.getDrawingUnit(staffSize);
    final Stemmodifier stemMod = _resolveDrawingStemMod();
    if (stemMod == Stemmodifier.none || stemMod == Stemmodifier.none0)
      return 0;

    final int code = stemModToGlyph(stemMod);
    if (code == 0) return 0;

    int lenAdjust = flagOffset;
    final Object? parentObj = parent;
    if (parentObj is Chord) {
      lenAdjust += (parentObj.getTopNote()!.getDrawingY() -
              parentObj.getBottomNote()!.getDrawingY())
          .abs();
    }

    final int glyphHeight = doc.getGlyphHeight(code, staffSize, false);
    final int actualLength = drawingStemLen.abs() - (lenAdjust ~/ unit) * unit;
    int diff;
    if (stemMod == Stemmodifier.sprech &&
        getDrawingStemDir() == Stemdirection.down) {
      diff = (actualLength - stemModRelY.abs()).abs();
    } else {
      // Mirrors the C++'s implicit double->int truncation of
      // `actualLength - abs(m_stemModRelY) - 0.5 * glyphHeight`.
      diff = ((actualLength - stemModRelY.abs()) - 0.5 * glyphHeight).truncate();
    }
    final int halfUnit = (0.5 * unit).truncate();

    int adjust = 0;
    if (diff < halfUnit && diff >= -halfUnit) {
      adjust = halfUnit;
    } else if (diff < -halfUnit) {
      adjust = (diff.abs() ~/ halfUnit + 1) * halfUnit;
      if (stemMod == Stemmodifier.n6slash) {
        adjust += doc.getGlyphHeight(smuflE220Tremolo1, staffSize, false) ~/ 4;
      }
    }
    return (getDrawingStemDir() == Stemdirection.up) ? -adjust : adjust;
  }

  /// Mirrors `Stem::CalculateStemModAdjustment` (stem.cpp:261): calculates
  /// [stemModRelY] then returns the stem-length adjustment from
  /// [adjustSlashes].
  int calculateStemModAdjustment(Doc doc, Staff staff, int flagOffset) {
    calculateStemModRelY(doc, staff);
    return adjustSlashes(doc, staff, flagOffset);
  }

  @override
  String get className => 'stem';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Stem();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Stem other) {
    super.copyFrom(other);
    copyAttGraced(other);
    copyAttStemVis(other);
    copyAttVisibility(other);
    drawingStemDir = other.drawingStemDir;
    drawingStemLen = other.drawingStemLen;
    drawingStemMod = other.drawingStemMod;
    stemModRelY = other.stemModRelY;
    isVirtual = other.isVirtual;
  }

  @override
  void reset() {
    super.reset();
    // AttGraced
    grace = null;
    graceTime = null;
    // AttStemVis
    pos = null;
    len = null;
    form = null;
    dir = null;
    flagPos = null;
    flagForm = null;
    // AttVisibility
    visible = null;
    type = null;
    label = null;

    drawingStemDir = Stemdirection.none;
    drawingStemLen = 0;
    drawingStemMod = null;
    stemModRelY = 0;
    isVirtual = false;
  }

  @override
  bool isSupportedChild(ClassId classId) {
    if (classId == ClassId.flag) return true;
    return false;
  }
}

/// Mirrors `vrv::Strophicus`.
class Strophicus extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttNoteGes,
        AttOctave,
        AttPitch,
        AttPitchGes,
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        OffsetInterface,
        PitchInterface,
        PositionInterface {
  Strophicus() : super(ClassId.strophicus) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.pitch,
      InterfaceId.position,
    ]);
    reset();
  }

  @override
  String get className => 'strophicus';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Strophicus();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Strophicus other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyPitchFrom(other);
    copyPositionFrom(other);
    copyAttColor(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttNoteGes(other);
    copyAttOctave(other);
    copyAttPitch(other);
    copyAttPitchGes(other);
    copyAttStaffLoc(other);
    copyAttStaffLocPitched(other);
  }
}

/// Mirrors `vrv::Syl`.
class Syl extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttPartIdent,
        AttStaffIdent,
        AttStartId,
        AttTimestampLog,
        AttStartEndId,
        AttTimestamp2Log,
        AttLang,
        AttTypography,
        AttSylLog,
        ObjectListInterface,
        TextListInterface,
        OffsetInterface,
        TimePointInterface,
        TimeSpanningInterface {
  Syl() : super(ClassId.syl) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.timePoint,
      InterfaceId.timeSpanning,
    ]);
    reset();
  }

  /// The next syllable of a word connector (mirrors `m_nextWordSyl`).
  Object? nextWordSyl;

  /// Mirrors `Syl::CalcHyphenLength` (syl.cpp:90) — the lyric-font hyphen
  /// width, adjusted to the lyric size.
  int calcHyphenLength(Doc doc, int staffSize) {
    final FontInfo lyricFont = doc.getDrawingLyricFont(staffSize);
    int dashLength = doc.getTextGlyphWidth('-'.codeUnitAt(0), lyricFont, false);
    dashLength = adjustToLyricSize(dashLength, doc);
    return dashLength;
  }

  /// Mirrors `Syl::AdjustToLyricSize` (syl.cpp:150) — the C++ mutates the
  /// `int&` argument; the Dart version returns the adjusted value.
  int adjustToLyricSize(int value, Doc doc) {
    final lyricSize = doc.getOptions().lyricSize;
    return (value * lyricSize.value / lyricSize.defaultValue).toInt();
  }

  /// Mirrors `Syl::CreateDefaultZone` (syl.cpp:180): builds a zone for a
  /// neume-notation syllable from the parent syllable's zone (shifted by
  /// fixed offsets) or from its zone bounds, and attaches it to the
  /// document's facsimile surface.
  ///
  /// Returns false when the syl has no syllable ancestor (only neume
  /// notation is handled) or when no bounds can be generated.
  bool createDefaultZone(Doc doc) {
    const int offsetUly = 100;
    const int offsetLrx = 100;
    const int offsetLry = 200;

    final LayerElement? syllable =
        getFirstAncestor(ClassId.syllable) as LayerElement?;
    if (syllable == null) {
      // Only do this for neume notation.
      return false;
    }

    final Zone zone = Zone();

    if (syllable.hasFacs) {
      final Zone? tempZone = (syllable as FacsimileInterface).zone;
      assert(tempZone != null);
      if (tempZone == null) return false;
      zone.ulx = tempZone.ulx;
      zone.uly = (tempZone.uly ?? 0) + offsetUly;
      zone.lrx = (tempZone.lrx ?? 0) + offsetLrx;
      zone.lry = (tempZone.lry ?? 0) + offsetLry;
    } else {
      final (int, int, int, int)? bounds = syllable.generateZoneBounds();
      if (bounds == null) {
        logWarning('Failed to create zone for $id of type $className');
        return false;
      }
      final (int ulx, int uly, int lrx, int lry) = bounds;
      if (ulx == 0 || uly == 0 || lrx == 0 || lry == 0) {
        logWarning(
            'Zero value when generating bbox from ${syllable.id}: ($ulx, $uly, $lrx, $lry)');
      }
      zone.ulx = ulx;
      zone.uly = uly + offsetUly;
      zone.lrx = lrx + offsetLrx;
      zone.lry = lry + offsetLry;
    }
    final Object? surface =
        doc.getFacsimile()?.findDescendantByType(ClassId.surface);
    assert(surface != null);
    if (surface == null) return false;
    surface.addChild(zone);
    attachZone(zone);
    return true;
  }

  /// The @n of the drawing verse (mirrors `m_drawingVerseN`).
  int drawingVerseN = 0;

  /// The place of the drawing verse (mirrors `m_drawingVersePlace`).
  dynamic drawingVersePlace;

  @override
  String get className => 'syl';

  @override
  Object clone() {
    final copy = Syl();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Syl other) {
    super.copyFrom(other);
    copyOffsetFrom(other);
    copyTimePointFrom(other);
    copyTimeSpanningFrom(other);
    copyAttLang(other);
    copyAttTypography(other);
    copyAttSylLog(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
    copyAttPartIdent(other);
    copyAttStaffIdent(other);
    copyAttStartId(other);
    copyAttTimestampLog(other);
    copyAttStartEndId(other);
    copyAttTimestamp2Log(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors Syl::IsSupportedChild: text children and editorial elements.
    if (Object.isTextElementId(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  @override
  bool get isRelativeToStaff => true;
}

/// Mirrors `vrv::Syllable`.
class Syllable extends LayerElement
    with AttColor, AttSlashCount, ObjectListInterface {
  Syllable() : super(ClassId.syllable) {
    reset();
  }

  @override
  String get className => 'syllable';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Syllable();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Syllable other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttSlashCount(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors Syllable::IsSupportedChild.
    const supported = {
      ClassId.accid,
      ClassId.clef,
      ClassId.divLine,
      ClassId.neume,
      ClassId.syl
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Mirrors `Syllable::MarkupAddSyl` (syllable.cpp:74): when the syllable
  /// carries no `@follows` remnant and holds no `<syl>`, add an empty
  /// `<syl><text/></syl>` and return true, else false.
  ///
  /// Deviation: `Object::GetAttributes` (the C++ `@follows` probe over the
  /// raw attribute array) has no Dart counterpart, so the check reads the
  /// `unsupported` attribute pairs that `MeiInput` preserves for
  /// round-tripping unknown attributes.
  bool markupAddSyl() {
    final Object? obj = findDescendantByType(ClassId.syl);
    final bool noFollows = !unsupported.any((pair) => pair.$1 == 'follows');
    if (noFollows && (obj == null)) {
      final Syl syl = Syl();
      final Text text = Text();
      syl.addChild(text);
      addChild(syl);
      return true;
    }
    return false;
  }
}

/// Mirrors `vrv::TabDurSym`.
class TabDurSym extends LayerElement
    with
        AttNNumberLike,
        AttStringtab,
        AttVisualOffsetVo,
        StemmedDrawingInterface {
  TabDurSym() : super(ClassId.tabDurSym) {
    reset();
  }

  @override
  String get className => 'tabDurSym';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = TabDurSym();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant TabDurSym other) {
    super.copyFrom(other);
    copyAttNNumberLike(other);
    copyAttStringtab(other);
    copyAttVisualOffsetVo(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors TabDurSym::IsSupportedChild.
    if (classId == ClassId.stem) return true;
    return false;
  }

  /// Mirrors `TabDurSym::AdjustDrawingYRel` (tabdursym.cpp:91): anchors the
  /// symbol below the staff by the staff height, plus a margin when stems
  /// are drawn outside the staff (then above the staff is impossible, the
  /// symbol always hangs below).
  ///
  /// Deviation: none in behavior; the sign convention is the same (negative
  /// yRel goes down from the staff origin). [doc] is typed as [Doc] rather
  /// than the C++ `const Doc *`.
  void adjustDrawingYRel(Staff staff, Doc doc) {
    int yRel =
        (staff.drawingLines - 1) * doc.getDrawingDoubleUnit(staff.drawingStaffSize);

    // For stems outside add a margin to the tabDurSym - otherwise attached
    // to the staff line.
    if (staff.isTabWithStemsOutside()) {
      final double spacingRatio =
          (staff.isTabLuteFrench() || staff.isTabLuteGerman()) ? 2.0 : 1.0;
      yRel += (doc.getDrawingUnit(staff.drawingStaffSize) * spacingRatio).toInt();
    }

    setDrawingYRel(-yRel);
  }
}

/// Mirrors `vrv::TabGrp`.
class TabGrp extends LayerElement
    with
        AttAugmentDots,
        AttBeamSecondary,
        AttDurationGes,
        AttDurationLog,
        AttDurationQuality,
        AttDurationRatio,
        AttFermataPresent,
        AttStaffIdent,
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        ObjectListInterface,
        DurationInterface,
        OffsetInterface {
  TabGrp() : super(ClassId.tabGrp) {
    registerInterfaces([
      InterfaceId.duration,
      InterfaceId.offset,
    ]);
    reset();
  }

  @override
  String get className => 'tabGrp';

  @override
  Object clone() {
    final copy = TabGrp();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant TabGrp other) {
    super.copyFrom(other);
    copyDurationFrom(other);
    copyOffsetFrom(other);
    copyAttAugmentDots(other);
    copyAttBeamSecondary(other);
    copyAttDurationGes(other);
    copyAttDurationLog(other);
    copyAttDurationQuality(other);
    copyAttDurationRatio(other);
    copyAttFermataPresent(other);
    copyAttStaffIdent(other);
    copyAttVisualOffsetHo(other);
    copyAttVisualOffsetVo(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors TabGrp::IsSupportedChild.
    const supported = {ClassId.tabDurSym, ClassId.note, ClassId.rest};
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Mirrors `TabGrp::GetTopNote` (tabgrp.cpp:104): the last note of the
  /// (filtered) list.
  Note? getTopNote() => getListBack() as Note?;

  /// Mirrors `TabGrp::GetBottomNote` (tabgrp.cpp:116): the first note of
  /// the (filtered) list.
  Note? getBottomNote() => getListFront() as Note?;
}

/// Mirrors `vrv::TimestampAttr`.
class TimestampAttr extends LayerElement {
  TimestampAttr() : super(ClassId.timestampAttr) {
    reset();
  }

  @override
  String get className => 'timestampAttr';

  /// The actual duration position where 0.0 corresponds to the first beat
  /// and -1.0 the beginning of the measure (mirrors `m_actualDurPos`).
  double actualDurPos = 0.0;

  /// Getter for the timestamp actual duration position (mirrors
  /// `GetActualDurPos`).
  double getActualDurPos() => actualDurPos;

  /// Setter for the timestamp drawing position (mirrors `SetDrawingPos`).
  void setDrawingPos(double pos) => actualDurPos = pos;

  /// Returns the duration (in Fraction) for the Timestamp (mirrors
  /// `GetTimestampAttrAlignmentDuration`).
  Fraction getTimestampAttrAlignmentDuration(MeiDuration meterUnit) {
    final duration = Fraction.fromDuration(meterUnit);
    return duration * Fraction((actualDurPos * durMax).toInt(), durMax);
  }

  @override
  Object clone() {
    final copy = TimestampAttr();
    copy.copyFrom(this);
    return copy;
  }
}

/// Mirrors `vrv::Tuplet`.
/// The melodic direction between the first and last element of a tuplet
/// (mirrors `vrv::MelodicDirection` from tuplet.h).
enum MelodicDirection { none, up, down }

/// Mirrors `vrv::Tuplet`.
class Tuplet extends LayerElement
    with
        AttColor,
        AttDurationRatio,
        AttNumberPlacement,
        AttTupletVis,
        ObjectListInterface {
  Tuplet() : super(ClassId.tuplet) {
    reset();
  }

  /// The leftmost element of the tuplet (set by the layout).
  LayerElement? drawingLeft;

  /// The rightmost element of the tuplet (set by the layout).
  LayerElement? drawingRight;

  /// The bracket position (above or below; set by the layout).
  StaffrelBasic drawingBracketPos = StaffrelBasic.none;

  /// The num position (above or below; set by the layout).
  StaffrelBasic drawingNumPos = StaffrelBasic.none;

  /// The beam the bracket is aligned with, if any (mirrors
  /// `m_bracketAlignedBeam`; set by the AdjustTupletsX functor). Typed as
  /// [Object] to avoid an import cycle with the layout code.
  Object? bracketAlignedBeam;

  /// The beam the num is aligned with, if any (mirrors
  /// `m_numAlignedBeam`; set by the AdjustTupletsX functor).
  Object? numAlignedBeam;

  /// The slurs that run inside this tuplet and adjust it (mirrors
  /// `m_innerSlurs`, a set of `FloatingCurvePositioner`; typed [dynamic] to
  /// avoid an import cycle with the layout code); filled by the slur
  /// collision filter.
  final List<dynamic> innerSlurs = <dynamic>[];

  /// Mirrors `Tuplet::AddInnerSlur`.
  void addInnerSlur(dynamic slurPositioner) {
    if (!innerSlurs.contains(slurPositioner)) innerSlurs.add(slurPositioner);
  }

  /// Mirrors `Tuplet::ResetInnerSlurs`.
  void resetInnerSlurs() => innerSlurs.clear();

  @override
  String get className => 'tuplet';

  @override
  Object clone() {
    final copy = Tuplet();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Tuplet other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttDurationRatio(other);
    copyAttNumberPlacement(other);
    copyAttTupletVis(other);
    drawingLeft = other.drawingLeft;
    drawingRight = other.drawingRight;
    drawingBracketPos = other.drawingBracketPos;
    drawingNumPos = other.drawingNumPos;
    bracketAlignedBeam = other.bracketAlignedBeam;
    numAlignedBeam = other.numAlignedBeam;
    resetInnerSlurs();
    for (final dynamic slur in other.innerSlurs) {
      addInnerSlur(slur);
    }
  }

  @override
  bool isSupportedChild(ClassId classId) {
    const supported = {
      ClassId.beam,
      ClassId.tupletBracket,
      ClassId.bTrem,
      ClassId.chord,
      ClassId.clef,
      ClassId.fTrem,
      ClassId.note,
      ClassId.tupletNum,
      ClassId.rest,
      ClassId.space,
      ClassId.tabGrp,
      ClassId.tuplet,
    };
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }

  /// Overwritten method for tuplet (mirrors `Tuplet::AddChild`).
  @override
  bool addChild(Object child) {
    if (!isSupportedChild(child.classId) || !addChildAdditionalCheck(child)) {
      logError("Adding '${child.className}' to a '$className'");
      return false;
    }

    child.setParent(this);

    final List<Object> children = childrenForModification;

    // Num and bracket are always added by PrepareLayerElementParts (for
    // now) and we want them to be in the front for the drawing order in the
    // SVG output.
    if (child.classId == ClassId.tupletBracket ||
        child.classId == ClassId.tupletNum) {
      children.insert(0, child);
    } else {
      children.add(child);
    }

    modify();

    return true;
  }

  @override
  void filterList(List<Object> childList) {
    // We want to keep only notes and rests.
    // Eventually, we also need to filter out grace notes properly (e.g.,
    // with sub-beams).
    childList.removeWhere((Object object) =>
        !object.isLayerElement || !object.hasInterface(InterfaceId.duration));
  }

  /// Determine the melodic direction (mirrors `GetMelodicDirection`).
  MelodicDirection getMelodicDirection() {
    final LayerElement? leftElement = drawingLeft;
    Note? leftNote;
    if (leftElement != null && leftElement.classId == ClassId.note) {
      leftNote = leftElement as Note;
    }
    if (leftElement != null && leftElement.classId == ClassId.chord) {
      leftNote = (leftElement as Chord).getTopNote();
    }

    final LayerElement? rightElement = drawingRight;
    Note? rightNote;
    if (rightElement != null && rightElement.classId == ClassId.note) {
      rightNote = rightElement as Note;
    }
    if (rightElement != null && rightElement.classId == ClassId.chord) {
      rightNote = (rightElement as Chord).getTopNote();
    }

    if (leftNote != null && rightNote != null) {
      final int leftPitch = leftNote.getDiatonicPitch();
      final int rightPitch = rightNote.getDiatonicPitch();
      if (leftPitch < rightPitch) return MelodicDirection.up;
      if (leftPitch > rightPitch) return MelodicDirection.down;
    }
    return MelodicDirection.none;
  }
}

/// Mirrors `vrv::Verse`.
class Verse extends LayerElement
    with AttColor, AttLang, AttNInteger, AttPlacementRelStaff, AttTypography {
  Verse() : super(ClassId.verse) {
    reset();
  }

  /// The drawing labelAbbr of the verse (mirrors `m_drawingLabelAbbr`).
  Object? drawingLabelAbbr;

  @override
  String get className => 'verse';

  @override
  Object clone() {
    final copy = Verse();
    copy.copyFrom(this);
    return copy;
  }

  @override
  void copyFrom(covariant Verse other) {
    super.copyFrom(other);
    copyAttColor(other);
    copyAttLang(other);
    copyAttNInteger(other);
    copyAttPlacementRelStaff(other);
    copyAttTypography(other);
  }

  @override
  bool isSupportedChild(ClassId classId) {
    // Mirrors Verse::IsSupportedChild.
    const supported = {ClassId.label, ClassId.labelAbbr, ClassId.syl};
    if (supported.contains(classId)) return true;
    if (Object.isEditorialElementId(classId)) return true;
    return false;
  }
}

/// Mirrors `vrv::Episema`.
class Episema extends LayerElement
    with
        AttVisualOffsetHo,
        AttVisualOffsetVo,
        AttNoteGes,
        AttOctave,
        AttPitch,
        AttPitchGes,
        AttStaffLoc,
        AttStaffLocPitched,
        AttColor,
        AttEpisemaVis,
        OffsetInterface,
        PitchInterface,
        PositionInterface {
  Episema() : super(ClassId.epistema) {
    registerInterfaces([
      InterfaceId.offset,
      InterfaceId.pitch,
      InterfaceId.position,
    ]);
    reset();
  }

  @override
  String get className => 'episema';

  /// Mirrors `HasToBeAligned`.
  @override
  bool get hasToBeAligned => true;

  @override
  Object clone() {
    final copy = Episema();
    copy.copyFrom(this);
    return copy;
  }
}
