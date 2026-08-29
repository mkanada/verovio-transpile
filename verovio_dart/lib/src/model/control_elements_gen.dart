// Originalmente gerado por tool/gen_elements.py; MANTIDO À MÃO desde 2026-08-26.
// Element leaf classes mirroring the C++ element headers; edit by hand (the
// generator was retired — see prompts/reports/04i.md).

import 'package:verovio_dart/src/model/atts/atts_cmn.dart';
import 'package:verovio_dart/src/model/atts/atts_cmnornaments.dart';
import 'package:verovio_dart/src/model/atts/atts_externalsymbols.dart';
import 'package:verovio_dart/src/model/atts/atts_midi.dart';
import 'package:verovio_dart/src/model/atts/atts_shared.dart';
import 'package:verovio_dart/src/model/atts/atts_visual.dart';
import 'package:verovio_dart/src/model/atts/mei_enums.dart' show TurnlogForm;
import 'package:verovio_dart/src/model/interfaces/plist_interface.dart';
import 'package:verovio_dart/src/model/interfaces/simple_interfaces.dart';
import 'package:verovio_dart/src/model/interfaces/time_interface.dart';
import 'package:verovio_dart/src/model/basic_elements.dart' show Layer, Staff;
import 'package:verovio_dart/src/model/beam_segment.dart'
    show BeamElementCoord, BeamSpanSegment;
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

  // Hand-added exception (same reason as `Beam`/`FTrem.beamSegment`, task
  // 04d): `gen_elements.py` does not emit per-class extra fields. In the
  // C++, `Arpeg` re-declares its own `m_drawingXRel`/`m_cachedXRel`
  // (arpeg.h:91-132), shadowing `FloatingObject`'s; here [drawingXRel] is
  // the inherited `FloatingObject.drawingXRel` field (already the one
  // `ResetHorizontalAlignmentFunctor.visitArpeg`, align_horizontally.dart:78,
  // resets — the Dart analog of `Arpeg::SetDrawingXRel(0)`), so no shadow is
  // needed; only the cache slot is new.
  //
  // Deviation: `AdjustArpegFunctor` (task 04-00/04c, out of scope here) only
  // ever writes the horizontal shift to the current `FloatingPositioner`
  // (`adjust_arpeg.dart:172`), never to [drawingXRel] itself — unlike
  // `Arpeg::SetDrawingXRel` (arpeg.cpp:86), which updates both. So
  // `cacheXRel` below is a faithful port of `Arpeg::CacheXRel`, but in
  // today's production pipeline `drawingXRel` never leaves 0 to be cached.
  int _cachedXRel = 0;

  /// Mirrors `Arpeg::CacheXRel` (arpeg.cpp:100): with [restore] set, writes
  /// the cached value back into [drawingXRel]; otherwise stores it.
  void cacheXRel({bool restore = false}) {
    if (restore) {
      drawingXRel = _cachedXRel;
    } else {
      _cachedXRel = drawingXRel;
    }
  }

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
    initBeamSegments();
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

  // Hand-added exception (same reason as `Beam`/`FTrem.beamSegment`, task
  // 04d, and `Arpeg.cacheXRel` above): `gen_elements.py` does not emit
  // per-class extra fields.
  //
  // `beamElementCoords` mirrors `BeamDrawingInterface::m_beamElementCoords`
  // (drawinginterface.h:227) — the *owned* list `InitCoords`
  // (drawinginterface.cpp:140) fills for a beam-like element. `InitCoords`
  // is not ported (same gap task 04d documented for `Beam`/`FTrem`, called
  // from `CalcStemFunctor::VisitBeamSpan` in the C++), so this stays empty
  // in production; `addSpanningSegment` below still performs the coordinate
  // lookup faithfully, and — exactly like the C++ when `m_beamElementCoords`
  // is empty — always takes its `nocoords` early-return branch as a result.
  // See task 04f's report for the verified fixture behaviour.
  final List<BeamElementCoord> beamElementCoords = [];

  /// The per-system segments of the beam span (mirrors `m_beamSegments`,
  /// beamspan.h:127); always has at least one entry after construction (see
  /// [initBeamSegments]).
  final List<BeamSpanSegment> beamSegments = [];

  /// Mirrors `GetSegment`.
  BeamSpanSegment getSegment(int index) => beamSegments[index];

  /// Return the segment of the beam span that belongs to [system], or null
  /// (mirrors `BeamSpan::GetSegmentForSystem`, beamspan.cpp:89).
  BeamSpanSegment? getSegmentForSystem(Object system) {
    for (final BeamSpanSegment segment in beamSegments) {
      // make sure to process only segments for current system
      final Object? segmentMeasure = segment.measure;
      if (segmentMeasure != null &&
          identical(segmentMeasure.getFirstAncestor(ClassId.system), system)) {
        return segment;
      }
    }
    return null;
  }

  /// Mirrors a read-only `m_beamSegments.size()` (no direct C++ getter;
  /// `BeamSpan::AddSpanningSegment`'s caller only needs the count itself).
  int getSegmentCount() => beamSegments.length;

  /// Clear the beam segments (mirrors `ClearBeamSegments`, beamspan.cpp:79).
  void clearBeamSegments() => beamSegments.clear();

  /// Initialize the beam segments (mirrors `InitBeamSegments`,
  /// beamspan.cpp:73): a beamSpan starts with exactly one segment. Called
  /// once, from the constructor, matching the C++ (`BeamSpan::Reset` only
  /// calls `ClearBeamSegments`; `InitBeamSegments` is a separate
  /// constructor-only call) — `reset()` here does not clear or reseed the
  /// segments (pre-existing, out of scope: `BeamSpan`'s `reset()` override
  /// does not touch `m_beamSegments`/`m_beamedElements` at all yet).
  void initBeamSegments() => beamSegments.add(BeamSpanSegment());

  /// Break one big spanning beamSpan into smaller beamSpans (mirrors
  /// `BeamSpan::AddSpanningSegment`, beamspan.cpp:107).
  ///
  /// [elements] is `CalcSpanningBeamSpansFunctor`'s system-grouped index —
  /// each entry is `(startIndex, system)`, [startIndex] indexing into
  /// [beamedElements] where that system-group begins; the sentinel last
  /// entry is `(beamedElements.length, null)`. This is a index-based
  /// translation of the C++'s `SpanIndexVector` (iterator + system pairs) —
  /// Dart has no iterator arithmetic, so the port carries positions instead,
  /// with identical grouping semantics.
  bool addSpanningSegment(dynamic doc, List<(int, Object?)> elements, int index,
      {bool newSegment = true}) {
    final Object firstOfRange = beamedElements[elements[index].$1];
    final Layer? layer = firstOfRange.getFirstAncestor(ClassId.layer) as Layer?;
    final Staff? staff = firstOfRange.getFirstAncestor(ClassId.staff) as Staff?;
    if (layer == null || staff == null) return false;

    final Object lastOfRange = beamedElements[elements[index + 1].$1 - 1];

    final int coordsFirst = beamElementCoords
        .indexWhere((BeamElementCoord c) => identical(c.element, firstOfRange));
    final int coordsLast = beamElementCoords
        .indexWhere((BeamElementCoord c) => identical(c.element, lastOfRange));
    if (coordsFirst == -1 || coordsLast == -1) return false;

    final BeamSpanSegment segment =
        newSegment ? BeamSpanSegment() : beamSegments[0];

    // Deviation: `BeamSegment::CalcBeam` (beam.cpp:89) is not ported (task
    // 04d's documented blocker); the segment's placement fields below are
    // set faithfully, but its drawing geometry (`beamSlope`) is not
    // computed.
    segment
      ..staff = staff
      ..layer = layer
      ..beginCoord = beamElementCoords[coordsFirst]
      ..endCoord = beamElementCoords[coordsLast]
      ..initCoordRefs(beamElementCoords.sublist(coordsFirst, coordsLast + 1))
      ..setSpanningType(index, elements.length - 1);

    final Object? currentSystem = layer.getFirstAncestor(ClassId.system);
    if (segment.spanningType == spanningStart) {
      segment.measure = currentSystem?.getLast(ClassId.measure);
    } else if (segment.spanningType == spanningEnd) {
      segment.measure = currentSystem?.getFirst(ClassId.measure);
    } else {
      segment.measure = firstOfRange.getFirstAncestor(ClassId.measure);
    }

    if (newSegment) beamSegments.add(segment);

    return true;
  }

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

  /// The drawing x relative position of the tempo, per staff @n (mirrors
  /// `m_drawingXRels`).
  final Map<int, int> drawingXRels = {};

  /// Mirrors `Tempo::SetDrawingXRelative`.
  void setDrawingXRelative(int staffN, int drawingX) =>
      drawingXRels[staffN] = drawingX;

  /// Mirrors `Tempo::GetDrawingXRelativeToStaff`.
  int getDrawingXRelativeToStaff(int staffN) =>
      getStart()!.getDrawingX() + (drawingXRels[staffN] ?? 0);

  /// Mirrors `Tempo::ResetDrawingXRelative`.
  void resetDrawingXRelative() => drawingXRels.clear();

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

  /// Mirrors `Turn::GetTurnGlyph` (turn.cpp:68).
  int getTurnGlyph(dynamic doc) {
    if (doc == null) return 0;
    final resources =
        (doc as dynamic).getResources?.call() ?? (doc as dynamic).resources;
    if (resources == null) return 0;
    // If there is glyph.num, prioritize it.
    if (hasGlyphNum) {
      final int code = glyphNum!;
      try {
        final glyph = (resources as dynamic).getGlyph?.call(code) ??
            (resources as dynamic).getGlyphByCode(code);
        if (glyph != null) return code;
      } catch (_) {}
      // Check via getGlyphByCode if the first lookup used getGlyph.
      try {
        final glyph = (resources as dynamic).getGlyphByCode(code);
        if (glyph != null) return code;
      } catch (_) {}
    } else if (hasGlyphName) {
      try {
        final code = (resources as dynamic).getGlyphCode(glyphName!);
        final glyph = (resources as dynamic).getGlyphByCode(code);
        if (glyph != null) return code;
      } catch (_) {}
    }
    // Default: lower form uses inverted turn, otherwise standard turn.
    const int smuflE567 = 0xE567;
    const int smuflE568 = 0xE568;
    return (form == TurnlogForm.lower) ? smuflE568 : smuflE567;
  }

  /// Mirrors `Turn::GetTurnHeight` (turn.cpp:87).
  int getTurnHeight(dynamic doc, int staffSize) {
    assert(doc != null);
    final int originalGlyph = getTurnGlyph(doc);
    int referenceGlyph;
    const int smuflE567 = 0xE567;
    const int smuflE569 = 0xE569;
    const int smuflE56D = 0xE56D;
    const int smuflE56C = 0xE56C;
    switch (originalGlyph) {
      case smuflE569:
        referenceGlyph = smuflE567;
        break;
      case smuflE56D:
        referenceGlyph = smuflE56C;
        break;
      default:
        referenceGlyph = originalGlyph;
        break;
    }
    try {
      return (doc as dynamic).getGlyphHeight(referenceGlyph, staffSize, false)
          as int;
    } catch (_) {
      return 0;
    }
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
